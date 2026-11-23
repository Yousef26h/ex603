-- ============================================================================
-- EX 603 — Unit 6, Task 6.1
-- Window functions: compute across a window without collapsing rows.


-- Task 6.1 — task 1: compare each event to its producer's average.
-- Question: For every trip, what is its producer's average failure rate, so I
-- can see which individual cancellations are unusual for that producer?
-- The window keeps all 200 event rows; nothing is collapsed.
WITH event_with_producer_rate AS (
    SELECT
        t.trip_id,
        t.driver_id,
        d.driver_name,
        t.requested_at,
        t.pickup_city,
        t.trip_status,
        CASE WHEN t.trip_status = 'cancelled' THEN 1 ELSE 0 END AS failure_flag,
        AVG(CASE WHEN t.trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END)
            OVER (PARTITION BY t.driver_id) AS producer_failure_rate
    FROM trips AS t
    JOIN drivers AS d
        ON d.driver_id = t.driver_id
)
SELECT
    trip_id,
    driver_id,
    driver_name,
    requested_at,
    pickup_city,
    trip_status,
    failure_flag,
    ROUND(producer_failure_rate, 4) AS producer_failure_rate,
    ROUND(failure_flag - producer_failure_rate, 4) AS deviation_from_producer_rate
FROM event_with_producer_rate
ORDER BY requested_at, trip_id;


-- Task 6.1 — task 1: anomaly view.
-- Question: Which individual cancellations are the most surprising relative to
-- the producer's own failure rate? A cancellation at a producer who almost
-- never cancels is a bigger signal than one at a producer who cancels often.
WITH event_with_producer_rate AS (
    SELECT
        t.trip_id,
        t.driver_id,
        d.driver_name,
        t.requested_at,
        t.trip_status,
        CASE WHEN t.trip_status = 'cancelled' THEN 1 ELSE 0 END AS failure_flag,
        AVG(CASE WHEN t.trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END)
            OVER (PARTITION BY t.driver_id) AS producer_failure_rate
    FROM trips AS t
    JOIN drivers AS d
        ON d.driver_id = t.driver_id
)
SELECT
    trip_id,
    driver_id,
    driver_name,
    requested_at,
    trip_status,
    ROUND(producer_failure_rate, 4) AS producer_failure_rate,
    ROUND(failure_flag - producer_failure_rate, 4) AS deviation_from_producer_rate
FROM event_with_producer_rate
WHERE trip_status = 'cancelled'
ORDER BY deviation_from_producer_rate DESC, requested_at
LIMIT 15;


-- Task 6.1 — task 1: the GROUP BY version.
-- Question: What is each producer's failure rate when the events are collapsed
-- to one row per producer?
SELECT
    t.driver_id,
    d.driver_name,
    COUNT(*) AS event_count,
    SUM(CASE WHEN t.trip_status = 'cancelled' THEN 1 ELSE 0 END) AS cancellation_count,
    ROUND(
        AVG(CASE WHEN t.trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        4
    ) AS producer_failure_rate
FROM trips AS t
JOIN drivers AS d
    ON d.driver_id = t.driver_id
GROUP BY t.driver_id, d.driver_name
ORDER BY event_count DESC, t.driver_id;


-- Task 6.1 — task 1: row-count comparison.
-- Question: How many rows does each version return, and what does the
-- difference represent?
WITH window_version AS (
    SELECT
        t.trip_id,
        AVG(CASE WHEN t.trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END)
            OVER (PARTITION BY t.driver_id) AS producer_failure_rate
    FROM trips AS t
),
group_version AS (
    SELECT
        t.driver_id,
        AVG(CASE WHEN t.trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END)
            AS producer_failure_rate
    FROM trips AS t
    GROUP BY t.driver_id
)
SELECT
    'window: every event keeps its own row' AS version,
    COUNT(*) AS row_count
FROM window_version
UNION ALL
SELECT
    'group by: one row per producer',
    COUNT(*)
FROM group_version;



-- Task 6.1 — task 2: rank producers three ways.
-- Question: If leadership publishes a producer leaderboard by event count, how
-- do ROW_NUMBER(), RANK(), and DENSE_RANK() differ when producers tie?
-- ROW_NUMBER needs a unique tiebreaker; driver_id is used here only to make the
-- output stable. RANK and DENSE_RANK leave ties tied.
WITH producer_counts AS (
    SELECT
        d.driver_id,
        d.driver_name,
        COUNT(t.trip_id) AS event_count
    FROM drivers AS d
    LEFT JOIN trips AS t
        ON t.driver_id = d.driver_id
    GROUP BY d.driver_id, d.driver_name
)
SELECT
    driver_id,
    driver_name,
    event_count,
    ROW_NUMBER() OVER (ORDER BY event_count DESC, driver_id) AS row_number_rank,
    RANK()       OVER (ORDER BY event_count DESC) AS rank_position,
    DENSE_RANK() OVER (ORDER BY event_count DESC) AS dense_rank_position
FROM producer_counts
ORDER BY event_count DESC, driver_id;


-- Task 6.1 — task 3: sort producers into four bands.
-- Question: If producers are split into four equal-size bands by event count,
-- where do tied producers land, and do any ties cross a band boundary?
-- NTILE makes four groups of 4, 4, 4, and 3 producers. The ORDER BY includes
-- driver_id so the assignment is reproducible, but that tiebreak is arbitrary:
-- in this result producers 5 and 7 both have 18 events and land in different
-- quartiles. band_min and band_max make the overlap at 18 visible.
WITH producer_counts AS (
    SELECT
        d.driver_id,
        d.driver_name,
        COUNT(t.trip_id) AS event_count
    FROM drivers AS d
    LEFT JOIN trips AS t
        ON t.driver_id = d.driver_id
    GROUP BY d.driver_id, d.driver_name
),
banded AS (
    SELECT
        driver_id,
        driver_name,
        event_count,
        NTILE(4) OVER (ORDER BY event_count DESC, driver_id) AS quartile,
        COUNT(*) OVER (PARTITION BY event_count) AS producers_with_same_count
    FROM producer_counts
)
SELECT
    driver_id,
    driver_name,
    event_count,
    quartile,
    producers_with_same_count,
    MIN(event_count) OVER (PARTITION BY quartile) AS band_min,
    MAX(event_count) OVER (PARTITION BY quartile) AS band_max
FROM banded
ORDER BY quartile, event_count DESC, driver_id;
