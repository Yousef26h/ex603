-- Requirement 4.1.1: Calculate platform-wide failure statistics.
SELECT
    COUNT(*) AS event_count,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count,
    ROUND(
        100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        2
    ) AS failure_rate_pct,
    MIN(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS min_failure_indicator,
    MAX(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS max_failure_indicator,
    COUNT(DISTINCT rider_id) AS distinct_actors
FROM trips;

-- Requirement 4.1.2: Compare event volume and average failure metric by producer.
-- Question: How many events and what failure rate does each producer have?
SELECT
    driver_id AS producer_id,
    COUNT(*) AS event_count,
    ROUND(
        100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        2
    ) AS failure_rate_pct
FROM trips
GROUP BY driver_id
ORDER BY event_count DESC, producer_id;

-- Requirement 4.1.3: Use HAVING to include producers with meaningful volume.
SELECT
    driver_id AS producer_id,
    COUNT(*) AS event_count,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count,
    ROUND(
        100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        2
    ) AS failure_rate_pct
FROM trips
GROUP BY driver_id
HAVING COUNT(*) >= 10
ORDER BY failure_rate_pct DESC, event_count DESC, producer_id;

-- Requirement 4.1.4: Compare performance across two dimensions.
SELECT
    pickup_city AS region,
    driver_id AS producer_id,
    COUNT(*) AS event_count,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count,
    ROUND(
        100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        2
    ) AS failure_rate_pct
FROM trips
GROUP BY pickup_city, driver_id
ORDER BY region, producer_id;
