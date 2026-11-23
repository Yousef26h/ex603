# Unit 6 Analysis — Windows, Trends, and Reporting Patterns

The failure metric in this unit is the same one used in Units 4 and 5: a trip
whose `trip_status` is `cancelled` is a failure. The 10 `disputed` trips are
reported separately and are not counted as failures. The event-level 0/1
failure indicator is used as the metric in Task 6.1 because its producer
average is directly the producer's failure rate; a cancelled trip also records
a fare of 0.00, so fare would confound failure with revenue.

## Task 6.1 — Compute across a window without collapsing

### A question that needs each row shown next to its group average

The question is: **which individual cancellations are surprising for the
producer who recorded them?** A cancellation at producer 8, who cancels 5% of
the time, is a stronger signal than a cancellation at producer 11, who cancels
31% of the time. Answering that requires the event and the producer's own
average on the same row.

A `GROUP BY driver_id` query cannot answer it. It collapses 200 events into 13
producer rows, so the result can say that producer 8 has a 5% failure rate but
cannot say which trip was the cancellation, when it happened, which rider or
city was involved, or how far each event sits from that producer's baseline.
The 187 event rows that disappear are not redundant detail; they are the unit
of the question. The same information could be recovered by joining the
grouped result back to `trips`, but that is extra work and an easy place to
introduce a duplicate or a missing match. The window version keeps the rows
and adds the group value beside them.

The queries return **200 rows** from the window version and **13 rows** from
the `GROUP BY` version. What is lost is the event-level record: trip and rider
identity, timestamp, pickup city, status, fare, cancellation reason, the
within-producer distribution, and the ability to rank individual events by how
unusual they are. In this data the most surprising cancellation is trip 120
by producer 8: producer 8's rate is 5.00%, so the deviation is 0.9500. Trips
198 (producer 13, 9.09%), 175 and 181 (producer 12, 11.76%) follow. The
`GROUP BY` output contains producer 8's 5.00% but not the fact that it came
from one specific trip in June. One limitation: the window average includes
the current event, which slightly pulls the average toward a cancellation; a
leave-one-out average would be stricter, but the assignment's
`AVG(...) OVER (PARTITION BY ...)` is the requested measure.

### Ranking is not neutral

The leaderboard feature I would build is a **monthly producer leaderboard in
the driver app**, where position controls visibility and possibly a
performance bonus. Ties decide who is treated as equal, so the function is a
policy choice, not a formatting choice.

`RANK()` is the right function for a published leaderboard. Producers 5 and 7
both have 18 events: `ROW_NUMBER()` gives them positions 4 and 5, `RANK()`
gives both position 4 and skips position 5, and `DENSE_RANK()` gives both
position 4 and the next producer position 5. On a leaderboard, two producers
with identical output should share a position; `ROW_NUMBER()` would silently
promote whichever `driver_id` happens to sort first, which is arbitrary and
can affect pay or visibility. `RANK()` preserves that equality and leaves the
gap that shows two people occupied the positions above. `DENSE_RANK()` is
better when the number is a **tier** rather than a screen position, because it
does not leave gaps; it is not the right label for "4th place." `ROW_NUMBER()`
should be reserved for cases that need exactly N distinct rows, with a
documented tiebreaker such as onboarding date or a random draw.

The full tie pattern in the ranking output is: producers 5 and 7 at 18 events,
producers 2 and 11 at 16, producers 1 and 13 at 11, and producers 14 and 15 at
zero. At 18 events the three columns read 4/5 for `ROW_NUMBER`, 4/4 for
`RANK`, and 4/4 for `DENSE_RANK`; at 17 events the next producer reads 6/6/5,
which is where the methods visibly diverge.

### Four bands with `NTILE(4)`

`NTILE(4)` puts 15 producers into bands of 4, 4, 4, and 3. The boundaries are
decided by row order, not by the event counts themselves, so a tie can be cut
in half. That is exactly what happens at 18 events: producer 5 (18 events) is
in band 1, whose range is 18–21, while producer 7 (18 events) is in band 2,
whose range is 16–18. The `band_min` and `band_max` columns make the overlap
visible: 18 is the minimum of band 1 and the maximum of band 2. Two producers
with identical output receive different quartile labels.

This matters if the bands drive a bonus, a dispatch tier, or an experiment
assignment. If equal producers must be treated equally, do not let `NTILE`
break the tie arbitrarily. Use a deterministic tiebreaker and document it, or
form bands from distinct event counts with `DENSE_RANK()` so tied producers
stay together even though the bands become unequal in size. The other ties in
this result are less exposed: the two producers at 16 are both in band 2, the
two at 11 are both in band 3, and the two at zero are both in band 4.

## Task 6.2 — Compare each row to its neighbors

### Part A: Row to row

Producer 6 has the most events (21) and is a readable example. The `LAG` and
`LEAD` columns put the previous and next fare beside each trip, and
`delta_from_previous` is the current fare minus the previous fare. The series
does not show a steady upward or downward trend; it alternates between short
cheap trips and long expensive ones. The largest drop is **-44.08** (trip 71:
50.25 to 6.17), and the largest rise is **+33.79** (trip 78: 16.46 to 50.25).
Four of the 21 events record 0.00 because they are cancellations, and those
zeros produce large negative deltas such as -42.02 after trip 66.

A large delta tells an operations reader that something changed between two
consecutive trips: a cancellation, a long or short route, a surge price, a
fare correction, or a data-entry problem. The right response is not to react
to the number alone but to check the status and the trip context. A drop to
0.00 should open a cancellation review; a large positive jump should be
checked against distance and surge to see whether it is a legitimate
high-value trip or a fare anomaly. Averaging producer 6's fares would hide
all of this. The event-level delta is what makes the change visible.

### Part B: Cumulative and smoothed

The stated target is **30 cancellations in 2023**, which is 15% of the 200
events observed. This is a deliberate operating target, not a law of the
domain: it says that a 15% annual failure rate is the level leadership is
willing to tolerate while the team works on the causes.

The running total reaches 34 by the end of December, so the platform finishes
**4 cancellations over target**. The monthly snapshot shows the path: 12 by
the end of Q1, 19 by the end of Q2, 27 by the end of Q3, 29 by the end of
October, 31 in November, and 34 in December. The target is crossed in
November. This is a more useful answer than a plain `SUM`, which would return
only the number 34. The `SUM` says how many; the running total says when the
platform got there, whether the early months were already expensive, and how
much room was left at each point. A running total turns a total into a pace.

For the recent average I chose a **7-event moving window** (6 preceding rows
plus the current row). With 11–21 events per month in this dataset, seven
events is roughly ten days to three weeks of activity: short enough to react
to a run of cancellations, long enough that one event does not dominate. The
trade-off is visible in the data. At 2023-12-17 the 7-event rate is 42.86%
because three of the previous seven events were cancellations; by 2023-12-28
it is 0.00% because the last seven events were all completed. The 30-event
rate at the end of the year is 16.67%, a steadier view. A 3-event window would
swing even more wildly and would be almost useless for a monthly review; a
30-event window would smooth over the month-to-month swings, but it reacts
more slowly to a new run of cancellations. It currently reads 16.67%, above
the Q2–Q4 quarterly range of 14.58–15.69%, which is exactly the kind of
signal a short window can miss and a longer window can reveal. The window
size is an editorial choice about how much history the reader should see.

`ROWS` counts **physical rows**, while `RANGE` includes **all peer rows that
share the same `ORDER BY` value**. Every January event shares the same month
key in the demonstration. `RANGE` gives every January row the full January
total (5), because all 21 January rows are peers. `ROWS` walks the tied rows
one at a time in an arbitrary internal order, so the first displayed row
shows 1 and a later row shows 4 even though the January total has not
changed. That is not a bug in the data; it is a warning that a time series
should order by `requested_at, trip_id`, not by a key with duplicates. Also,
`ROWS` counts rows, not days: seven rows can cover more than seven days when
activity is sparse, which is exactly the situation here.

### Part C: Where the series stops

The gap query finds **seven gaps of more than 80 days** between consecutive
events. The largest is producer 9: no event between **2023-01-05 14:18** and
**2023-04-28 04:16**, a gap of **112 days 13:58**. Producer 9 then resumes,
records another event seven days later, and continues through December. This
is the "stops for a while and starts again" case the task asks for. The gap
has to be computed in a CTE: `WHERE` is evaluated before window functions, so
filtering on `LAG(...)` in the same `SELECT` would fail.

What kind of gap is it? It is most consistent with a **real pause in recorded
activity**, not a platform-wide ingestion failure. During the same interval,
**61 events by 11 other producers across all five cities** were recorded, so
the event feed was working. The same `driver_id` returns after the gap and
keeps producing events, so the producer record was not deleted or replaced.
Producer 9 is also marked `is_active = false` in the current driver snapshot,
which fits a producer who was not continuously available and later left the
active roster. But a single-producer ingestion gap cannot be ruled out from
the event table alone, and `is_active` is a snapshot, not a history. To
distinguish the remaining possibilities, check the driver app's login/online
history and the dispatch offer log for Jan 5–Apr 28. No logins or offers
would confirm a real stop; logins with no trips would point to dispatch or
availability; trips present in the source feed but missing here would confirm
data loss. The current data supports "real pause" with medium confidence, not
certainty.

## Task 6.3 — Reporting patterns

### Part A: Top N per category

The top-three query returns **39 rows**: exactly three for each of the 13
producers with events. The highest fare in the platform is **70.86** (producer
4, trip 43, 2023-10-15), followed by 59.14 (producer 8) and 50.25 (producer
6). The `FIRST_VALUE` and `LAST_VALUE` columns put each producer's best and
worst fare beside the top three, so a reader can see whether the third-place
event is close to the producer's best or already far below it. For most
producers `producer_bottom_fare` is 0.00 because their worst event is a
cancellation; producer 10, who has no cancellations, has a bottom fare of
4.88. A "top trips" report that shows only the top three would therefore make
earnings look better than the full event history does.

The feature this pattern would power is a **driver earnings recap** ("your
top three trips this month") and an operations digest that shows the top three
trips per producer for route and pricing review. **Three** is the right number
for that surface: it fits on one card without scrolling, it is enough to show
a pattern (a repeated airport run, a late-night surge, a long-distance trip)
rather than a single anecdote, and it stays short enough that an operations
reader will actually check all three. One event hides variation and invites
over-generalizing; ten events turn the card into a table, include marginal
trips that are not meaningfully "top," and increase the number of ties that
have to be adjudicated.

Ties at third are handled with `RANK()`, so if two events had exactly the same
fare in third place, both would be returned and the producer would have four
rows. Keeping both is honest: dropping one would require an arbitrary
tiebreaker that could change the report. In this dataset no producer has a tie
at third, so the output is three rows each. If the business requires exactly
three rows, use `ROW_NUMBER()` with an explicit, documented tiebreaker instead
of pretending the tie does not exist.

### Part B: Period over period

The monthly series is volatile, but the quarterly view is clear. The failure
rate was **22.64% in Q1** (12 of 53), fell to **14.58% in Q2** (7 of 48),
edged up to **15.69% in Q3** (8 of 51), and returned to **14.58% in Q4**
(7 of 48). The Q1-to-Q2 change is **-8.06 percentage points** (**-35.61%**);
Q2-to-Q4 is flat. The platform improved early in the year and then held at a
new, lower plateau.

The monthly view explains why a single month is a poor decision unit. Rates
range from **0.00% in April** to **27.27% in March**, and the month-over-month
percent changes are extreme: March **+43.17%**, April **-100.00%**, June
**+112.50%**, July **-52.96%**. These are not evidence of a platform lurching
between crisis and recovery; they are what happens when a month contains only
11–21 events, so one or two cancellations move the rate by roughly 5–9
percentage points. April's 0.00% is 0 of 11, not proof that the problem was
solved. June's 25.00% is 5 of 20, not proof of a new crisis.

A large month-over-month change should trigger a **count check and a segment
check before a policy response**: how many cancellations, in how many events,
for which producers and cities, and with what reasons? In this data the Q1
peak is concentrated in Hue pickups: Hue's Q1 rate is **50.0%** (7 of 14),
then 10.0% in Q2, 33.3% in Q3 (2 of 6), and 10.0% in Q4. The platform average
hides that local story. Haiphong also drifts upward, from 0.0% in Q2 to 18.2%
in Q3 and 25.0% in Q4 on only 8 events, and Hanoi's Q4 is 25.0% on only 4
events. Those are leads for local review, not conclusions. A useful rule is:
investigate when a month moves by at least 5 percentage points **and**
contains at least three cancellations, then confirm the signal with the
30-event rolling rate and the next month's data.

The missing-month check is part of the query, not an afterthought. Without
a check, `LAG` counts rows, so a missing month makes the next present month
compare against a non-adjacent month — March against January, for example —
while still calling it "month over month." This query computes `LAG` on the
actual monthly rows, then left joins them to a calendar. A missing month
appears as a zero-event row with a null rate and the label
`NO EVENTS IN THIS MONTH`; the next present month has
`months_since_previous = 2` and `continuity_check = 'MISSING MONTH(S)'`. All
twelve months are present here, so every row reads `adjacent`. If one were
missing, the flag would identify the wrong comparison, which is the point at
which the analyst must stop and fix the series rather than interpret the
change.

## Reflection

Window functions answer a different kind of question from `GROUP BY`. In this
ride-sharing data I can ask which individual trips are unusual for the
producer who performed them — for example, which cancellation is most
surprising given producer 8's 5% cancellation rate. A window function keeps
all 200 trip rows and adds the producer's average rate to each one, so the
event, its date, its fare, and its deviation stay together. `GROUP BY`
collapses the same data to 13 producer rows. It can tell me that producer 8
has a 5% rate, but it cannot tell me which trip produced that rate, when it
happened, or how far each event sits from the producer's baseline. I could
rejoin the grouped result to the events, but that is extra work and easy to
get wrong. The same distinction matters for the running total and the
`LAG` comparisons: a plain `SUM` returns one number, while the window returns
the path that produced it. The reader can see not just that 34 cancellations
occurred, but when the 30-cancellation target was crossed. Window functions
preserve context; aggregates preserve only the summary.
