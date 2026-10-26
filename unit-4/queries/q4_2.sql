-- Requirement 4.2 Part A: Use conditional aggregation for both totals.
SELECT
    driver_id AS producer_id,
    COUNT(*) AS event_count,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count
FROM trips
GROUP BY driver_id
ORDER BY event_count DESC, producer_id;

-- Requirement 4.2 Part B: Return regional subtotals and the platform total.
SELECT
    CASE
        WHEN GROUPING(pickup_city) = 1 THEN 'PLATFORM GRAND TOTAL'
        ELSE pickup_city
    END AS region_or_total,
    CASE WHEN GROUPING(pickup_city) = 1 THEN 'grand total' ELSE 'subtotal' END AS row_type,
    COUNT(*) AS event_count,
    SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count,
    ROUND(
        100.0 * AVG(CASE WHEN trip_status = 'cancelled' THEN 1.0 ELSE 0.0 END),
        2
    ) AS failure_rate_pct
FROM trips
GROUP BY ROLLUP (pickup_city)
ORDER BY GROUPING(pickup_city), pickup_city;

-- Requirement 4.2 Part C: Build a producer summary, then calculate a baseline.
WITH producer_summary AS (
    SELECT
        driver_id AS producer_id,
        COUNT(*) AS event_count,
        SUM(CASE WHEN trip_status = 'cancelled' THEN 1 ELSE 0 END) AS failure_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    COUNT(*) AS high_volume_producer_count,
    SUM(event_count) AS event_count,
    SUM(failure_count) AS failure_count,
    ROUND(
        100.0 * SUM(failure_count) / NULLIF(SUM(event_count), 0),
        2
    ) AS high_volume_failure_rate_pct
FROM producer_summary
WHERE event_count >= 15;
