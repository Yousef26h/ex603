-- Part A: The rows that vanished

select *
from riders
where referred_by != 3; -- counts 21

select *
from riders
where referred_by = 3;
-- counts 3

-- fixed first query
select *
from riders
where COALESCE(referred_by, -1) != 3;
-- now returns 27


-- Part B: The alias that did not exist yet

select distance_km * 1000 AS distance_m
from trips
where distance_m > 2500;

-- repeating same expression
select distance_km * 1000 AS distance_m
from trips
where distance_km * 1000 > 2500;


-- using CTE
WITH CalculateDistanceMeter AS (select distance_km * 1000 AS distance_m
                                from trips)
select *
from CalculateDistanceMeter
where distance_m > 2500;


-- using subquery
select *
from (select distance_km * 1000 AS distance_m
      from trips) as tdm
where distance_m > 2500;
