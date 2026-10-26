# Unit 4 Analysis

## Task 4.1 — Measuring the platform

The metric is a binary failure indicator: a trip with `trip_status = 'cancelled'`
counts as one failure; all other statuses count as zero. With that definition,
the platform has 200 trips and 34 cancellations, for a 17.00% failure rate.
The average indicator is 0.17; its minimum and maximum are 0 and 1. There are
30 distinct riders in the event table. The 10 disputed trips are not included
in the failure numerator because the supplied data does not classify them as
cancellations; they should be reviewed separately before treating them as
successful outcomes.

The per-producer breakdown should be acted on by the **Producer Operations
Manager**, who can coordinate a targeted review with regional operations.
Results vary materially: producer 11 has 5 cancellations in 16 events (31.25%),
producer 9 has 4 in 14 (28.57%), and producer 2 has 4 in 16 (25.00%). The
minimum-volume `HAVING` screen in `q4_1.sql` is 10 events. This is a practical
initial screen that removes very small samples, not a claim that ten events
establish a reliable long-run rate. Producer 4's rate is 33.33%, for example,
but it comes from only 6 events and should not be treated as a stable estimate.

The platform average conceals the distribution of outcomes across producers,
locations, and time; the event count conceals which riders and trip statuses
make up those events. Next, leadership should see the cancelled-trip reasons,
status distribution (especially disputed trips), time trends, and each
producer's event counts alongside rates. A larger observation window would
help distinguish persistent performance differences from random variation.
The two-dimension query uses `pickup_city` as a regional proxy because this
dataset has no separate region field.

## Task 4.2 — Detailed summaries

**Part A — Two numbers in one pass.** The conditional aggregation answers two
questions side by side for every producer: how many total events did they
handle, and how many of those events were cancellations?

**Part B — Subtotals and grand total.** The regional director needs the
per-region subtotals to see where to focus local follow-up. The platform grand
total supports a decision about whether a platform-wide response is warranted;
the region rows alone do not state the overall rate and volume. In the
`q4_2.sql` result, rows labeled `subtotal` are regional subtotals, and the row
labeled `grand total` is the platform-wide total. There are no producer detail
rows in that query.

**Part C — Two-step pipeline.** The CTE answers: among producers with at least
15 events, what is the overall event-weighted cancellation baseline? The
intermediate summary has one row per producer; the outer aggregation combines
the eight qualifying producers. In the supplied data, that is 22 cancellations
across 145 events, or 15.17%.

## Reflection — Conditional aggregation

Conditional aggregation answers multiple questions from the same event rows.
For each producer, one grouped query can count every event and, at the same
time, add one only when the status is cancelled. Two separate filtered queries
would each need to access and group the event data: one for all events and one
for cancellations. At a million rows, repeating that work can mean more table
or index reads, more grouping work, and more database time and I/O. A single
pass can reduce that repeated work while keeping both measures aligned in one
result set, which also avoids accidentally comparing counts produced from
different filters or runs. The exact speedup depends on the database, indexes,
cache, and query plan; an optimizer may make separate queries efficient, and
parallel execution can change the trade-off. The main benefit is that the
conditional query expresses both metrics over the same population explicitly.
It does not remove the need to check definitions: here, the result depends on
whether cancellations alone count as failures and on how disputed events are
eventually classified.
