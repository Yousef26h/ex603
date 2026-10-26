-- Part one: actors involved in the disputed event

-- subquery using IN or NOT IN
select *
from riders
where rider_id IN
      (select rider_id
       from riders
       where referred_by != 3 or referred_by IS NULL);
-- Common Table Expression
WITH RidersReferredby3 AS (
    select *
    from riders
    where COALESCE(referred_by, -1) != 3
)
select *
from RidersReferredby3;

-- a third way (a different subquery form)
select *
from (
         select *
         from riders
     ) as r
where COALESCE(referred_by, -1) != 3;

