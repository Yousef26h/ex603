# Unit 4 Finding — Platform Failure Rate

The corrected event-level failure rate is **17.00%**: 34 of 200 trips were
cancelled. This calculation counts only `cancelled` trips as failures.
Another 10 trips are marked `disputed`; they are not in the failure numerator
and should be resolved or separately classified before leadership treats the
rate as a complete picture of unsuccessful trips.

Rates differ substantially across producers. I recommend that Producer
Operations investigate **producer 11** first (5 cancellations in 16 events,
31.25%), followed by **producer 9** (4 of 14, 28.57%) and **producer 2** (4 of
16, 25.00%). These producers combine elevated rates with more than ten events,
so they are more informative starting points than the smallest samples.
Producer 4 has the highest observed rate, 2 of 6 (33.33%), but that small
volume makes the percentage unstable; include it in monitoring rather than
ranking it ahead of the larger samples. By comparison, producer 10 had no
cancellations in 19 events, and producer 8 had 1 in 20 (5.00%).

These results identify leads for review, not proof that any producer caused
the cancellations. The next review should compare cancellation reasons, trip
timing, region, and disputed outcomes, then reassess rates over a longer period.
The supplied event data records pickup city rather than a separate region, so
regional comparisons use that location as a proxy.
