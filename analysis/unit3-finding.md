# Unit 3 Finding — Ride-Sharing Failure-Rate Dashboard


The trip dashboard reported that roughly half of all trips end in
a rider no-show the figure that led leadership to freeze the quarterly driver
bonus payout. That number is not correct. The trips table holds 30 trips. The
dashboard's query returned 21 as "no-shows" and reported the failure rate from
those 21 rows. When the query is corrected, the true no-show count is 27 not
the 21 the dashboard showed, and not the ~50% headline it implied.

The error has two parts, and both are silent. First, the query filtered on a
field using a "not equal to" comparison. In SQL, a record with a missing value
in that field is neither equal to the value nor not equal to it, it fails every
comparison and is quietly excluded from the result. In our data, 6 of the 30
riders have no referral recorded, so they vanished from the count. The
dashboard's failure filter almost certainly suffers the identical flaw: any trip
whose failure-status field is blank is silently left out of the failure rate,
which skews the reported percentage. Second, an earlier version of the query
referred to a calculated column before it had been defined, which SQL does not
allow. The workaround that let the query run is what introduced the
missing-value problem rather than fixing it. The query ran cleanly and returned
plausible-looking numbers, which is exactly why no one caught it.

**Recommendation:** the frozen driver-bonus payout should be released and the
dashboard rebuilt on the corrected query (provided separately in `q3_3.sql`).
The corrected referral count is 27 of 30 riders — the 21 the dashboard counted,
plus the 6 it dropped. All three rewritten query forms return the same rows, so
the dashboard team can adopt whichever fits their pipeline. Because the same
missing-value pattern could affect any dashboard filtering on a nullable field,
I recommend the data team audit other queries on the trips and riders tables for
the identical issue before the next payout cycle.