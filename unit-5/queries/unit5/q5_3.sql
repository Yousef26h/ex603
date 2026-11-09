-- Requirement 5.3 Part A.1: Count rows in the two small source tables.
-- Question: How many producers and catalog badges are available for the Cartesian product?
SELECT 'drivers' AS source_table, COUNT(*) AS source_row_count
FROM drivers
UNION ALL
SELECT 'driver_badges' AS source_table, COUNT(*) AS source_row_count
FROM driver_badges;

-- Requirement 5.3 Part A.2: Show the CROSS JOIN of the two small tables.
-- Question: What producer-badge pairs does a Cartesian product create?
SELECT
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    b.badge_id,
    b.badge_name
FROM drivers AS d
CROSS JOIN driver_badges AS b
ORDER BY d.driver_id, b.badge_id;

-- Requirement 5.3 Part A.3: Compare the cross-join row count with the product of source counts.
-- Question: Does the result count equal producer_count multiplied by badge_count?
SELECT
    (SELECT COUNT(*) FROM drivers) AS producer_count,
    (SELECT COUNT(*) FROM driver_badges) AS badge_count,
    (SELECT COUNT(*) FROM drivers)
        * (SELECT COUNT(*) FROM driver_badges) AS expected_product_count,
    (SELECT COUNT(*) FROM drivers CROSS JOIN driver_badges) AS actual_cross_join_count;

-- Requirement 5.3 Part B: Ask PostgreSQL to plan the three-table join from Task 5.1.1.
-- Question: Which scan and join algorithms does PostgreSQL choose for this event-detail report?
EXPLAIN
SELECT
    t.trip_id,
    r.rider_id AS actor_id,
    r.rider_name AS actor_name,
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    t.requested_at AS event_time
FROM trips AS t
INNER JOIN riders AS r
    ON r.rider_id = t.rider_id
INNER JOIN drivers AS d
    ON d.driver_id = t.driver_id
ORDER BY t.requested_at, t.trip_id;
