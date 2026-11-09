-- Requirement 5.1.1: Join actors, producers, and events.
-- Question: Which rider and driver are associated with each trip, and when was it requested?
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

-- Requirement 5.1.2: Connect the Assignment 4 high-cancellation producers to catalog badges.
-- Question: Which catalog badges are associated with producers 2, 9, and 11?
SELECT
    d.driver_id AS producer_id,
    d.driver_name AS producer_name,
    b.badge_id,
    b.badge_name,
    a.awarded_on
FROM drivers AS d
INNER JOIN driver_badge_awards AS a
    ON a.driver_id = d.driver_id
INNER JOIN driver_badges AS b
    ON b.badge_id = a.badge_id
WHERE d.driver_id IN (2, 9, 11)
ORDER BY d.driver_id, b.badge_name;

-- Requirement 5.1.3: Self-join producers to compare each high-cancellation producer with same-city peers.
-- Question: Do these producers differ from nearby peers in activity, rating, or trip volume?
WITH producer_activity AS (
    SELECT
        driver_id,
        COUNT(*) AS event_count,
        COUNT(*) FILTER (WHERE trip_status = 'cancelled') AS cancellation_count
    FROM trips
    GROUP BY driver_id
)
SELECT
    focus.driver_id AS focus_producer_id,
    focus.driver_name AS focus_producer_name,
    focus.home_city,
    focus.is_active AS focus_is_active,
    focus.avg_rating AS focus_rating,
    COALESCE(focus_activity.event_count, 0) AS focus_event_count,
    COALESCE(focus_activity.cancellation_count, 0) AS focus_cancellation_count,
    ROUND(
        100.0 * focus_activity.cancellation_count
        / NULLIF(focus_activity.event_count, 0),
        2
    ) AS focus_cancellation_rate_pct,
    peer.driver_id AS peer_producer_id,
    peer.driver_name AS peer_producer_name,
    peer.is_active AS peer_is_active,
    peer.avg_rating AS peer_rating,
    COALESCE(peer_activity.event_count, 0) AS peer_event_count,
    COALESCE(peer_activity.cancellation_count, 0) AS peer_cancellation_count,
    ROUND(
        100.0 * peer_activity.cancellation_count
        / NULLIF(peer_activity.event_count, 0),
        2
    ) AS peer_cancellation_rate_pct
FROM drivers AS focus
LEFT JOIN drivers AS peer
    ON peer.home_city = focus.home_city
   AND peer.driver_id <> focus.driver_id
LEFT JOIN producer_activity AS focus_activity
    ON focus_activity.driver_id = focus.driver_id
LEFT JOIN producer_activity AS peer_activity
    ON peer_activity.driver_id = peer.driver_id
WHERE focus.driver_id IN (2, 9, 11)
ORDER BY focus.driver_id, peer.driver_id;
