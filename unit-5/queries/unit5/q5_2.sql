-- Requirement 5.2 Part A.1: LEFT JOIN every producer to its event summary.
-- Question: How many events and cancellations are recorded for every producer, including those with none?
WITH producer_activity AS (
    SELECT
        driver_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellation_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    COALESCE(a.event_count, 0) AS event_count,
    COALESCE(a.cancellation_count, 0) AS cancellation_count
FROM drivers AS d
LEFT JOIN producer_activity AS a
    ON a.driver_id = d.driver_id
ORDER BY d.driver_id;

-- Requirement 5.2 Part A.2: INNER JOIN the same producer summary.
-- Question: Which producers remain when only producers with events are returned?
WITH producer_activity AS (
    SELECT
        driver_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellation_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    a.event_count,
    a.cancellation_count
FROM drivers AS d
INNER JOIN producer_activity AS a
    ON a.driver_id = d.driver_id
ORDER BY d.driver_id;

-- Requirement 5.2 Part A.3: Count unique producers omitted by the INNER JOIN.
-- Question: How many producers have no events, and which producer IDs are they?
WITH producer_activity AS (
    SELECT driver_id, COUNT(*) AS event_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    COUNT(*) AS excluded_producer_count,
    ARRAY_AGG(d.driver_id ORDER BY d.driver_id) AS excluded_producer_ids
FROM drivers AS d
LEFT JOIN producer_activity AS a
    ON a.driver_id = d.driver_id
WHERE a.driver_id IS NULL;

-- Requirement 5.2 Part B.1: Reverse the LEFT JOIN using RIGHT JOIN.
-- Question: Does a RIGHT JOIN retain the same producer rows and counts as the LEFT JOIN?
WITH producer_activity AS (
    SELECT
        driver_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellation_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    COALESCE(a.event_count, 0) AS event_count,
    COALESCE(a.cancellation_count, 0) AS cancellation_count
FROM producer_activity AS a
RIGHT JOIN drivers AS d
    ON d.driver_id = a.driver_id
ORDER BY d.driver_id;

-- Requirement 5.2 Part B.2: Verify LEFT JOIN and RIGHT JOIN results in both directions.
-- Question: Are there any producer rows returned by one outer join but not the other?
WITH producer_activity AS (
    SELECT
        driver_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellation_count
    FROM trips
    GROUP BY driver_id
),
left_result AS (
    SELECT
        d.driver_id AS producer_id,
        d.driver_name AS producer_name,
        COALESCE(a.event_count, 0) AS event_count,
        COALESCE(a.cancellation_count, 0) AS cancellation_count
    FROM drivers AS d
    LEFT JOIN producer_activity AS a
        ON a.driver_id = d.driver_id
),
right_result AS (
    SELECT
        d.driver_id AS producer_id,
        d.driver_name AS producer_name,
        COALESCE(a.event_count, 0) AS event_count,
        COALESCE(a.cancellation_count, 0) AS cancellation_count
    FROM producer_activity AS a
    RIGHT JOIN drivers AS d
        ON d.driver_id = a.driver_id
),
differences AS (
    (SELECT * FROM left_result EXCEPT SELECT * FROM right_result)
    UNION ALL
    (SELECT * FROM right_result EXCEPT SELECT * FROM left_result)
)
SELECT COUNT(*) AS differing_rows
FROM differences;

-- Requirement 5.2 Part B.3: FULL OUTER JOIN producers and individual events.
-- Question: Which producer-event pairs match, and are there producers or events missing their counterpart?
SELECT
    COALESCE(d.driver_id, t.driver_id) AS producer_id,
    d.driver_name AS producer_name,
    t.trip_id AS event_id,
    t.requested_at AS event_time,
    CASE
        WHEN d.driver_id IS NULL THEN 'event without producer'
        WHEN t.trip_id IS NULL THEN 'producer without events'
        ELSE 'matched'
    END AS match_status
FROM drivers AS d
FULL OUTER JOIN trips AS t
    ON t.driver_id = d.driver_id
ORDER BY COALESCE(d.driver_id, t.driver_id), t.trip_id;

-- Requirement 5.2 Part C.1: Use NOT EXISTS to find producers with no events.
-- Question: Which producer IDs have no matching trip?
SELECT d.driver_id AS producer_id
FROM drivers AS d
WHERE NOT EXISTS (
    SELECT 1
    FROM trips AS t
    WHERE t.driver_id = d.driver_id
)
ORDER BY d.driver_id;

-- Requirement 5.2 Part C.2: Use EXCEPT to find producers with no events.
-- Question: Which driver IDs are absent from the set of trip producer IDs?
SELECT driver_id AS producer_id
FROM drivers
EXCEPT
SELECT driver_id AS producer_id
FROM trips
ORDER BY producer_id;

-- Requirement 5.2 Part C.3: Compare the two unmatched-producer sets.
-- Question: Do NOT EXISTS and EXCEPT return exactly the same producer IDs?
WITH not_exists_result AS (
    SELECT d.driver_id AS producer_id
    FROM drivers AS d
    WHERE NOT EXISTS (
        SELECT 1
        FROM trips AS t
        WHERE t.driver_id = d.driver_id
    )
),
except_result AS (
    SELECT driver_id AS producer_id FROM drivers
    EXCEPT
    SELECT driver_id AS producer_id FROM trips
),
differences AS (
    (SELECT * FROM not_exists_result EXCEPT SELECT * FROM except_result)
    UNION ALL
    (SELECT * FROM except_result EXCEPT SELECT * FROM not_exists_result)
)
SELECT COUNT(*) AS differing_ids
FROM differences;
