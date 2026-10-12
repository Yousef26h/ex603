-- 3.1
-- anchor the audit. Requirement: SELECT, WHERE, ORDER BY, LIMIT.
-- Active, highly rated drivers — the producers whose records
SELECT driver_id, driver_name, avg_rating
FROM drivers
WHERE is_active = TRUE
  AND avg_rating >= 4.5
ORDER BY avg_rating DESC
    LIMIT 10;

-- all possible event statuses
select DISTINCT trip_status
from trips;


-- Filter the events in two different ways

select *
from trips
where fare_amount between 10.00 and 20.00;

select *
from trips
where driver_id in (select drivers.driver_id
                    from drivers
                    where drivers.avg_rating >= 3.0);

-- Work with text and missing values

select *
from drivers
where driver_name ilike '%driver%';


select trip_id, coalesce(cancellation_reason, 'No reason provided.')
from trips;


-- Make the results easier to understand

select driver_name,
       avg_rating,
       CASE
           WHEN avg_rating < 2.0 THEN 'low'
           WHEN avg_rating between 2.0 and 4.5 THEN 'mid'
           WHEN avg_rating > 4.5 THEN 'high'
           ELSE 'not-rated'
           END AS rating_bracket
from drivers;
