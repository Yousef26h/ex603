# Unit 6 — Window Functions and the Closing Analysis

This folder is the Unit 6 deliverable for EX603. It answers the question
leadership asked after the failure-rate audit:

> **Is the platform getting better or worse, and what should the team do next
> quarter?**

All queries run against the `ex603_data` PostgreSQL database built from the
Unit 3 reference dataset.

## What is in this folder

| Path | Contents |
|---|---|
| [`queries/unit6/q6_1.sql`](queries/unit6/q6_1.sql) | Window average next to every event, `GROUP BY` comparison, `ROW_NUMBER`/`RANK`/`DENSE_RANK`, `NTILE(4)` |
| [`queries/unit6/q6_2.sql`](queries/unit6/q6_2.sql) | `LAG`/`LEAD` for producer 6, running total against a target, 7-event moving average, 30-event rate, gap detection |
| [`queries/unit6/q6_3.sql`](queries/unit6/q6_3.sql) | Top three events per producer, monthly and quarterly period-over-period, city-level quarters |
| [`analysis/unit6.md`](analysis/unit6.md) | Write-ups for Tasks 6.1–6.3 plus the 188-word reflection |
| [`analysis/unit6-finding.md`](analysis/unit6-finding.md) | The closing memo to leadership |
| [`screenshots/`](screenshots/) | 21 captures of the queries and their result sets |


## The short version of the finding

- The failure rate fell from **22.64% in Q1** to **14.58% in Q2**, then stayed
  between **14.58% and 15.69%** through Q4. The platform improved early and
  then plateaued; it is not still improving.
- The 30-cancellation annual target was crossed in **November** and finished
  at **34**, four over target.
- The remaining producer hotspots are **11 (31.25%)**, **9 (28.57%)**,
  **2 (25.00%)**, and **3 (23.08%)**. Producer 4's 33.33% is only 2 of 6.
- **20 of 34 cancellations are rider-side**; 7 are driver unavailable and 7
  are payment failures. Not every cancellation is a producer-performance
  issue.
- The Q1 peak is concentrated in **Hue pickups (50.0% in Q1)**, which fell to
  10.0% in Q2, rose to 33.3% on 6 events in Q3, and was 10.0% in Q4.
  Haiphong and Hanoi need local review.
- Ten trips are **disputed**, producers 14 and 15 have **zero events**, and
  producer 9 has a **112-day gap**. Those measurement gaps need to be closed
  before the next quarterly target is set.

The full recommendation is in
[`analysis/unit6-finding.md`](analysis/unit6-finding.md).


## Video

> **Video link:** _https://drive.google.com/file/d/1-lEEak9qpKNSnRdoc-Pu_QQXaY0c6Hma/view?usp=sharing_


