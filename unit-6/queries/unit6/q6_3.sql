-- ============================================================================
-- EX 603 — Unit 6, Task 6.3
-- Two reporting patterns: top N per category and period over period.
-- ============================================================================


-- Task 6.3 — Part A: Top N per category.
-- Question: What were the three highest-fare events for each producer, and how
-- do those compare with that producer's best and worst fare?
--
-- Tie handling at third place: RANK() is used, so if two events had exactly the
-- same fare in third place, both would be returned and that producer would have
-- four rows. Keeping both is the honest choice: excluding one would be
-- arbitrary. In this dataset no producer has a tie at third, so every producer
-- returns exactly three rows. If a report absolutely needs three rows, use
-- ROW_NUMBER() with a documented tiebreaker instead.
--
-- LAST_VALUE() needs ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.
-- With the default frame (up to the current row) it would return the current
-- row's fare, not the producer's lowest fare.
WITH ranked_events AS (
    SELECT
        t.driver_id,
        d.driver_name,
        t.trip_id,
        t.requested_at,
        t.fare_amount,
        t.trip_status,
        RANK() OVER (
            PARTITION BY t.driver_id
            ORDER BY t.fare_amount DESC
        ) AS fare_rank,
        FIRST_VALUE(t.fare_amount) OVER (
            PARTITION BY t.driver_id
            ORDER BY t.fare_amount DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS producer_top_fare,
        LAST_VALUE(t.fare_amount) OVER (
            PARTITION BY t.driver_id
            ORDER BY t.fare_amount DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS producer_bottom_fare
    FROM trips AS t
    JOIN drivers AS d
        ON d.driver_id = t.driver_id
)
SELECT
    driver_id,
    driver_name,
    trip_id,
    requested_at,
    fare_amount,
    trip_status,
    fare_rank,
    producer_top_fare,
    producer_bottom_fare
FROM ranked_events
WHERE fare_rank <= 3
ORDER BY driver_id, fare_rank, trip_id;


-- Task 6.3 — Part B: Period over period.
-- Question: Is the platform's monthly failure rate getting better or worse from
-- one month to the next?
-- LAG is computed on the actual monthly rows, not on the filled calendar, so a
-- missing month leaves a two-month gap between a row and its previous_month.
-- The calendar join then shows the missing month as a zero-event row, while the
-- next present month is flagged MISSING MONTH(S) by the continuity check.
-- NULLIF(previous_month_rate, 0) prevents division by zero when the previous
-- month had a 0% rate.
WITH monthly AS (
    SELECT
        date_trunc('month', requested_at)::date AS month,
        COUNT(*) AS events,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellations
    FROM trips
    GROUP BY 1
),
with_lag AS (
    SELECT
        month,
        events,
        cancellations,
        CASE
            WHEN events = 0 THEN NULL
            ELSE ROUND(100.0 * cancellations / events, 2)
        END AS failure_rate_pct,
        LAG(100.0 * cancellations / events) OVER (ORDER BY month) AS previous_month_rate,
        LAG(month) OVER (ORDER BY month) AS previous_month
    FROM monthly
),
calendar AS (
    SELECT generate_series(
        '2023-01-01'::date,
        '2023-12-01'::date,
        INTERVAL '1 month'
    )::date AS month
),
series AS (
    SELECT
        c.month,
        COALESCE(m.events, 0) AS events,
        COALESCE(m.cancellations, 0) AS cancellations,
        m.failure_rate_pct,
        m.previous_month_rate,
        m.previous_month
    FROM calendar AS c
    LEFT JOIN with_lag AS m
        ON m.month = c.month
)
SELECT
    month,
    events,
    cancellations,
    failure_rate_pct,
    ROUND(previous_month_rate, 2) AS previous_month_rate_pct,
    ROUND(
        100.0 * (failure_rate_pct - previous_month_rate)
        / NULLIF(previous_month_rate, 0),
        2
    ) AS pct_change,
    (
        (EXTRACT(YEAR FROM month) * 12 + EXTRACT(MONTH FROM month))
        - (EXTRACT(YEAR FROM previous_month) * 12 + EXTRACT(MONTH FROM previous_month))
    ) AS months_since_previous,
    CASE
        WHEN month = DATE '2023-01-01' THEN 'first month'
        WHEN events = 0 THEN 'NO EVENTS IN THIS MONTH'
        WHEN previous_month IS NULL THEN 'NO EARLIER OBSERVED MONTH'
        WHEN previous_month = (month - INTERVAL '1 month')::date THEN 'adjacent'
        ELSE 'MISSING MONTH(S)'
    END AS continuity_check
FROM series
ORDER BY month;


-- Task 6.3 — Part B: Period over period (quarterly).
-- Question: How does the quarterly failure rate compare with the previous
-- quarter, in percentage points and as a percent change?
WITH quarterly AS (
    SELECT
        date_trunc('quarter', requested_at)::date AS quarter,
        COUNT(*) AS events,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellations
    FROM trips
    GROUP BY 1
),
series AS (
    SELECT
        quarter,
        events,
        cancellations,
        ROUND(100.0 * cancellations / events, 2) AS failure_rate_pct,
        LAG(100.0 * cancellations / events) OVER (ORDER BY quarter) AS previous_rate
    FROM quarterly
)
SELECT
    quarter,
    events,
    cancellations,
    failure_rate_pct,
    ROUND(previous_rate, 2) AS previous_quarter_rate_pct,
    ROUND(failure_rate_pct - previous_rate, 2) AS pp_change,
    ROUND(
        100.0 * (failure_rate_pct - previous_rate) / NULLIF(previous_rate, 0),
        2
    ) AS pct_change
FROM series
ORDER BY quarter;


-- Task 6.3 — Part B: Period over period — supporting context: city-level quarters.
-- Question: Is the quarterly change in failure rate the same in every pickup
-- city, or is the platform trend hiding a local problem?
-- LAG is partitioned by city, so each city is compared with its own previous
-- quarter, not with the platform or another city.
WITH city_quarter AS (
    SELECT
        pickup_city,
        date_trunc('quarter', requested_at)::date AS quarter,
        COUNT(*) AS events,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellations
    FROM trips
    GROUP BY 1, 2
),
series AS (
    SELECT
        pickup_city,
        quarter,
        events,
        cancellations,
        ROUND(100.0 * cancellations / events, 1) AS failure_rate_pct,
        LAG(100.0 * cancellations / events) OVER (
            PARTITION BY pickup_city
            ORDER BY quarter
        ) AS previous_rate
    FROM city_quarter
)
SELECT
    pickup_city,
    quarter,
    events,
    cancellations,
    failure_rate_pct,
    ROUND(previous_rate, 1) AS previous_rate_pct,
    ROUND(failure_rate_pct - previous_rate, 1) AS pp_change
FROM series
ORDER BY pickup_city, quarter;
