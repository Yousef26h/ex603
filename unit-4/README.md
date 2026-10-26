Unit 4 defines failure as `trip_status = 'cancelled'`. The event-level
`pickup_city` is used as a regional proxy. See the
[`Unit 4 analysis`](analysis/unit4.md) and
[`leadership finding`](analysis/unit4-finding.md) for
definitions, results, and interpretation. The screenshots folder contains
instructions for adding genuine execution screenshots.

These queries continue the Unit 3 ride-sharing analysis. Run them against the
database containing the existing `trips`, `drivers`, and `riders` tables. No
driver or rider names are selected in the Unit 4 producer analyses.

| Query | Business question |
|---|---|
| [`q4_1.sql`](queries/q4_1.sql) | What is the platform's failure rate; how does it vary by producer; which producers have a minimum volume; and how does it vary by producer and pickup location? |
| [`q4_2.sql`](queries/q4_2.sql) | How many total and failed events did each producer handle; what are the regional subtotals and platform total; and what is the baseline among high-volume producers? |

The analysis defines a failure as a trip whose `trip_status` is `cancelled`.
Disputed trips are reported as a separate status in the dataset and are not
counted as failures in these queries. The event-level `pickup_city` field is
used as a regional proxy because the supplied schema has no separate region
column.

Written findings are in [`analysis/unit4.md`](analysis/unit4.md) and
[`analysis/unit4-finding.md`](analysis/unit4-finding.md). The
[`screenshots`](screenshots/) folder is reserved for screenshots of the
executed queries and their results.
