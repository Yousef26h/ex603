-- ============================================================================
-- EX 603 — Unit 6, Task 6.2
-- Compare each row to its neighbors: LAG/LEAD, running totals, moving
-- averages, and gap detection.
-- ============================================================================


-- Task 6.2 — Part A: Row to row.
-- Question: For a producer, is each trip's fare higher or lower than the trip
-- immediately before it, and what fare comes next in time order?
-- The window is partitioned by producer and ordered by requested_at. The final
-- WHERE keeps one producer so the trend is easy to read; LAG and LEAD were
-- computed for every producer before that filter.
WITH event_neighbors AS (
    SELECT
        driver_id,
        trip_id,
        requested_at,
        trip_status,
        fare_amount,
        LAG(fare_amount) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS previous_fare,
        LEAD(fare_amount) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS next_fare
    FROM trips
)
SELECT
    trip_id,
    requested_at,
    trip_status,
    fare_amount,
    previous_fare,
    next_fare,
    ROUND(fare_amount - previous_fare, 2) AS delta_from_previous
FROM event_neighbors
WHERE driver_id = 6
ORDER BY requested_at, trip_id;


-- Task 6.2 — Part B: Cumulative and smoothed.
-- Question: How many cancellations have accumulated by each event, and what is
-- the platform's cancellation rate over the trailing seven events?
-- The SUM frame is explicitly UNBOUNDED PRECEDING to CURRENT ROW so the total
-- grows with time. The AVG frame is 6 PRECEDING to CURRENT ROW, which is seven
-- event rows including the current one. These are rows, not days.
WITH event_window AS (
    SELECT
        trip_id,
        requested_at,
        trip_status,
        CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END AS failure_flag,
        SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) OVER (
            ORDER BY requested_at, trip_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_cancellations,
        ROUND(
            100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END) OVER (
                ORDER BY requested_at, trip_id
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS moving_avg_7_event_pct
    FROM trips
)
SELECT
    trip_id,
    requested_at,
    trip_status,
    failure_flag,
    running_cancellations,
    moving_avg_7_event_pct
FROM event_window
ORDER BY requested_at, trip_id;


-- Task 6.2 — Part B: Cumulative and smoothed (target check).
-- Question: Against a stated annual target of 30 cancellations  15% of the
-- 200 events in 2023, how close is the running total at the end of each month,
-- and when is the target exceeded?
WITH monthly AS (
    SELECT
        date_trunc('month', requested_at)::date AS month,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS monthly_cancellations
    FROM trips
    GROUP BY 1
),
running AS (
    SELECT
        month,
        monthly_cancellations,
        SUM(monthly_cancellations) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_cancellations
    FROM monthly
)
SELECT
    month,
    monthly_cancellations,
    cumulative_cancellations,
    30 AS annual_target_cancellations,
    30 - cumulative_cancellations AS remaining_under_target,
    CASE
        WHEN cumulative_cancellations <= 30 THEN 'within target'
        ELSE 'over target'
    END AS target_status
FROM running
ORDER BY month;


-- Task 6.2 — Part B: Cumulative and smoothed (ROWS versus RANGE).
-- Question: When many rows share the same ORDER BY value, how does a ROWS
-- frame differ from a RANGE frame?
-- Every January event shares the same month key. RANGE treats all January rows
-- as peers and gives each one the full January total; ROWS walks the tied rows
-- one at a time in an arbitrary internal order unless a unique tiebreaker is
-- added. The LIMIT keeps the demonstration to the first eight January events.
SELECT
    requested_at::date AS event_date,
    trip_id,
    requested_at,
    trip_status,
    CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END AS failure_flag,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) OVER (
        ORDER BY date_trunc('month', requested_at)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_rows,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) OVER (
        ORDER BY date_trunc('month', requested_at)
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_range
FROM trips
WHERE date_trunc('month', requested_at) = DATE '2023-01-01'
ORDER BY requested_at, trip_id
LIMIT 8;



-- Task 6.2 — Part C: Where the series stops.
-- Question: Which producers have a gap of more than 80 days between consecutive
-- events, and when did activity resume?
-- The window function is computed in the CTE. A window result cannot be
-- filtered by WHERE in the same query, so the outer WHERE keeps only the gaps.
WITH ordered_events AS (
    SELECT
        driver_id,
        trip_id,
        requested_at,
        LAG(requested_at) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS previous_event_at,
        LEAD(requested_at) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS next_event_at
    FROM trips
)
SELECT
    driver_id,
    previous_event_at,
    requested_at AS resumed_at,
    requested_at - previous_event_at AS gap,
    next_event_at
FROM ordered_events
WHERE previous_event_at IS NOT NULL
  AND requested_at - previous_event_at > INTERVAL '80 days'
ORDER BY gap DESC;


-- Task 6.2 — Part C: Where the series stops (producer 9).
-- Question: What does producer 9's full event timeline look like around the
-- 112-day gap, and what happened immediately after it?
WITH ordered_events AS (
    SELECT
        driver_id,
        trip_id,
        requested_at,
        trip_status,
        LAG(requested_at) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS previous_event_at,
        LEAD(requested_at) OVER (
            PARTITION BY driver_id
            ORDER BY requested_at, trip_id
        ) AS next_event_at
    FROM trips
)
SELECT
    trip_id,
    requested_at,
    trip_status,
    previous_event_at,
    requested_at - previous_event_at AS gap_since_previous,
    next_event_at
FROM ordered_events
WHERE driver_id = 9
ORDER BY requested_at, trip_id;


-- Task 6.2 — Part C: other producers active.
-- Question: Were other producers recording events while producer 9 was silent,
-- which would rule out a platform-wide ingestion outage?
-- The gap boundaries are the ones found in the Part C gap query: after 2023-01-05 14:18 and
-- before producer 9's return on 2023-04-28 04:16.
SELECT
    COUNT(*) AS events_by_other_producers,
    COUNT(DISTINCT driver_id) AS other_producers_active,
    COUNT(DISTINCT pickup_city) AS cities_active,
    MIN(requested_at) AS first_event,
    MAX(requested_at) AS last_event
FROM trips
WHERE driver_id <> 9
  AND requested_at >= '2023-01-05 14:18:00'
  AND requested_at < '2023-04-28 04:16:00';


-- Task 6.2 — Part C: roster status.
-- Question: What does the driver roster say about the producers with a large
-- gap or with no recorded events?
-- This is context for the gap, not proof of its cause: is_active is a current
-- snapshot, not a history of availability during 2023.
SELECT
    d.driver_id,
    d.driver_name,
    d.is_active,
    d.onboard_date,
    d.avg_rating,
    (SELECT COUNT(*) FROM trips AS t WHERE t.driver_id = d.driver_id) AS event_count
FROM drivers AS d
WHERE d.driver_id IN (9, 14, 15)
ORDER BY d.driver_id;
