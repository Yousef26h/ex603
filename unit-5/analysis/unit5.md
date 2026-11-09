# Unit 5 — Joins and Platform Activity

## Task 5.1 — Connect producers to their data

### Three-table join

The rider-trip-driver join in [`q5_1.sql`](../queries/unit5/q5_1.sql) could
power an event-history report for customer support or operations. For each
trip, it shows the trip ID and request time together with the rider (actor)
and driver (producer) IDs and names. An inner join is suitable for this
event-centered report because each trip is expected to reference both records.

### Producer badges and the junction table

The `driver_badge_awards` table connects `drivers` to `driver_badges`. It is
necessary because the relationship is many-to-many: a driver can earn multiple
badges, and each badge can belong to multiple drivers. Without the junction,
the query would have no reliable way to associate a producer with each badge
and award date; storing repeated badge fields in `drivers` would also make
adding or changing credentials awkward.

Among the Assignment 4 high-cancellation producers, producer 2 has Safe
Driving, Night Owl, and Airport Pro; producer 9 has Safe Driving; and producer
11 has Night Owl and Five Star. No one badge is shared by all three. Night Owl
is shared by producers 2 and 11, while Safe Driving is shared by producers 2
and 9. These are associations in the catalog, not evidence that a badge caused
or explains a cancellation rate.

### Self join

The self join compares each high-cancellation producer with other producers
from the same home city, alongside their activity counts and ratings.
Producer 9 (Hue) has same-city peers 1, 13, and 15; producer 11 (Haiphong) has
peers 3 and 6. Producer 2 (Danang) has no other producer in that city, so its
peer columns are null. A lack of same-city peers is not evidence that location
caused producer 2's rate. The event counts and cancellation rates provide
context; comparisons are descriptive and the sample sizes remain limited.

## Task 5.2 — Records omitted by joins

### INNER JOIN versus LEFT JOIN

The supplied dataset has 15 driver records and trips for 13 distinct drivers.
The LEFT JOIN returns all 15 producers; the INNER JOIN returns only producers
with matching trips. It therefore excludes **2 producers: IDs 14 and 15**.
Both are marked active in the producer table (ratings 3.63 and 4.00,
respectively), but the dataset contains no trips for them. The SQL reports the
excluded count and IDs directly.

### RIGHT JOIN and FULL OUTER JOIN

Reversing the table order makes the RIGHT JOIN equivalent to the LEFT JOIN:
both preserve every producer and attach the matching event summary when one
exists. The verification query checks the result sets in both directions;
the expected difference count for these two queries is zero. The FULL OUTER
JOIN shows both matched event-producer rows and either side without a match.
Here, the foreign key from trips to drivers prevents an event from having a
missing producer, so the unmatched rows are the producers with no trips.
Without that constraint (or in an imported, unvalidated data set), a full
outer join could reveal orphan events as well.

### NOT EXISTS and EXCEPT

Both approaches identify producers **14 and 15**. `NOT EXISTS` tests each
producer for the absence of a matching trip, while `EXCEPT` subtracts the set
of driver IDs appearing in trips from the set of all driver IDs. The included
comparison query checks for differences; the expected count is zero.

### Interpretation and leadership action

No events means no trips for that producer appear in this dataset and
observation period. It does not establish why. Possible explanations include
incomplete onboarding, a producer who never became available, an intentional
pause, or an incomplete event feed. An inner-join-only report would omit these
producers and make the producer roster look more active and complete than it
is. Leadership may want to identify them to resolve onboarding gaps, validate
roster status, or understand capacity that is listed but not being used.

The data establishes that IDs 14 and 15 have no recorded trips and are marked
active; it does not explain the discrepancy. Operations should first confirm
their onboarding and availability status and check that their events are
reaching the database. If they are genuinely available but not receiving work,
review dispatch coverage before taking any performance action.

## Task 5.3 — Cartesian product and execution plan

### CROSS JOIN

The selected source tables are small: `drivers` has 15 rows and
`driver_badges` has 5. Their CROSS JOIN produces **75 rows** (15 × 5), which
the count query compares with the actual joined count. Such a Cartesian
product could be useful to generate every possible producer-badge combination
for a coverage checklist. It would be a likely mistake if a report intended
to show only badges actually awarded, because the CROSS JOIN includes
unawarded combinations.

### EXPLAIN plan

**The plan has not been captured.** The current environment has no `psql`,
nothing is listening on local port 5432, and the Docker daemon is unavailable.
Consequently, I cannot honestly report the selected join algorithm or include
a full execution-plan output. Run the final `EXPLAIN` statement in
[`q5_3.sql`](../queries/unit5/q5_3.sql) against `ex603_data` and replace this
note with its exact output and observations. PostgreSQL's choice depends on
the server version, statistics, indexes, and settings; an expected plan is
not a substitute for the captured plan.

Understanding the selected algorithm helps explain where the work is spent
and whether a query is likely to scale. A plan with sequential scans can be
reasonable for small tables; estimates, scan types, sort nodes, and join
conditions help identify when row growth or poor statistics may change that
trade-off. Use `EXPLAIN ANALYZE` on this read-only SELECT when a live database
is available to compare estimated rows and costs with actual rows and timings.

### Reflection (150–250 words)

The current three-table report joins trips to riders and drivers by their
identifiers. The supplied data is small (200 trips, 30 riders, and 15
drivers), so PostgreSQL may find it cheaper to scan the tables and build hash
tables than to perform many index lookups. That is a prediction, not an
observation: I could not capture this database's plan because PostgreSQL was
not reachable in the current environment. The actual plan should be recorded
before drawing conclusions.

As trips grow, the best algorithm can change with both table size and the
number of matching rows. If a query becomes selective and indexes exist on
the event foreign keys, nested-loop joins can be efficient by looking up only
the matching rows. If both inputs are large and already ordered on their join
keys, a merge join may avoid building a large hash table. A hash join can
remain effective for large, unsorted inputs when enough memory is available;
memory pressure or inaccurate row estimates can instead cause extra work,
including disk spills. PostgreSQL does not automatically index referencing
foreign-key columns, so adding suitable indexes may enable different plans.
After data growth, index changes, or bulk loads, refreshed statistics help
the planner estimate cardinalities. Comparing `EXPLAIN ANALYZE` estimates and
actual timings is essential: a different algorithm is not automatically
faster, and the captured plan—not table size alone—should guide tuning.
