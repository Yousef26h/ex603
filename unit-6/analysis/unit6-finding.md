# Unit 6 Finding — Better, Then Flat

## Bottom line

The failure problem improved early in 2023 and then stopped improving. The
quarterly cancellation rate fell from **22.64% in Q1** to **14.58% in Q2**,
then stayed at **15.69% in Q3** and **14.58% in Q4**. Q4 is exactly the Q2
level. The platform finished with **34 cancellations against a 30 target**,
crossing 30 in November. The next quarter should protect the gain, target the
remaining hotspots, and fix the measurement gaps.

## Point 1 — The trend is improvement, then a plateau

- Q1 **22.64%** (12 of 53) → Q2 **14.58%** (7 of 48) → Q3 **15.69%** (8 of 51)
  → Q4 **14.58%** (7 of 48). The Q1-to-Q2 drop is **8.06 points**; Q2-to-Q4 is
  flat. *(q6_3.sql, Part B, quarterly)*
- Monthly data is too noisy to call a trend: rates run from **0.00% in April**
  (0 of 11) to **27.27% in March** (3 of 11). June is **25.00%** (5 of 20).
  The last 30 events are **16.67%** (5 of 30), above the Q4 rate.
  *(q6_3.sql, Part B, monthly; q6_2.sql, Part B context, last-30 rate)*
- Target: **30 cancellations**; actual **34**. The running total crossed 30 in
  November. *(q6_2.sql, Part B, target)*
- Caveat: **10 trips are disputed**. If they are counted as failures, the
  overall rate is **22.00%**, not 17.00%.
  *(q6_1.sql, task 1 context, status mix)*

## Point 2 — The remaining failures are concentrated, and not all are producer-caused

- Producer rates: **11 = 31.25%** (5 of 16), **9 = 28.57%** (4 of 14),
  **2 = 25.00%** (4 of 16), **3 = 23.08%** (3 of 13). Producer 4's 33.33% is
  only 2 of 6; monitor it, don't rank it.
  *(q6_1.sql, task 1, GROUP BY comparison)*
- Reasons: of the 34 cancellations, **20 are rider-side** (12 no-show, 8 rider
  cancelled), **7 are driver unavailable**, and **7 are payment failed**. So
  20 of 34 are not producer performance.
  *(q6_1.sql, task 1 context, cancellation reasons)*
- Where: **Hue** had a **50.0%** Q1 rate (7 of 14), then 10.0% in Q2, 33.3% on
  6 events in Q3, and 10.0% in Q4. Haiphong and Hanoi were 25.0% in Q4 on small
  samples. *(q6_3.sql, Part B context, city-level)*
- Data gaps: producer 9 has a **112-day gap**, then resumes; 61 events from 11
  other producers were recorded during the gap. Producers 14 and 15 have
  **zero events**. These are not 0% failure rates.
  *(q6_2.sql, Part C, gap and context)*

## Point 3 — What to do next quarter

1. **Keep a 15% quarterly ceiling for Q1 2024 and a 12% year-end stretch.**
   Report counts with rates, plus the 30-event rolling rate. Escalate a month
   only if it moves at least 5 points with at least 3 cancellations.
   *(q6_3.sql, Part B)*
2. **Review producers 11, 9, 2, and 3 for eight weeks.** Check their
   cancellation reasons, timing, cities, and dispatch context. Keep producer 4
   on watch. Investigate Hue's Q1 spike and review Haiphong and Hanoi locally.
   *(q6_1.sql, task 1, GROUP BY comparison; q6_3.sql, Part B context, city-level)*
3. **Fix the measurement.** Resolve the 10 disputed trips and publish the rule.
   Check producer 9's gap and the zero-event producers 14 and 15 before setting
   a harder target.
   *(q6_1.sql, task 1 context, status mix; q6_2.sql, Part C, gap and context)*

## What would change this answer

If disputed trips count as failures, the overall rate rises to **22.00%**. If
producer 9's gap or the empty producer records are missing events, the producer
and recent rates could move. The direction of the trend is the main finding;
the exact size is less certain.

## Close

The platform is better than its worst quarter, but not yet better than its
recent plateau. Protect the 15% level, review the named hotspots, separate
rider-side cancellations from producer performance, and close the data gaps
before raising the target.
