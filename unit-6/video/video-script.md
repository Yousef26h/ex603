# Five-Minute Video Walkthrough — Script and Shot List

**Goal:** introduce the platform and the business question, demonstrate two
or three representative queries (including a Unit 6 window-function query),
present the key findings and a next-quarter recommendation, discuss one
technical challenge or limitation, and point viewers to the repository. Do not
re-explain the ERD or DDL from Unit 3; the database design is the starting
point, not the subject of the presentation.

**Target length:** 5 minutes (4:45–5:15 is fine).

**Format:** screen recording with voiceover. Record at 1080p or higher. Keep
the SQL window and the result set readable; zoom the terminal or use the
prepared screenshots for the result tables.

**Before recording:**

- [ ] Start the `my-postgres` container and confirm `ex603_data` is loaded.
- [ ] From the repository root, open
  `unit3-assigment/unit-4/queries/q4_1.sql`,
  `unit3-assigment/unit-6/queries/unit6/q6_1.sql`, and
  `unit3-assigment/unit-6/queries/unit6/q6_3.sql` in tabs.
- [ ] Open the key result screenshots in `unit3-assigment/unit-6/screenshots/`:
  `6.1-window-average.png`, `6.1-ranking-tie.png`,
  `6.3-B-monthly.png`, and `6.2-B-running-total.png`.
- [ ] Open `unit3-assigment/unit-6/analysis/unit6-finding.md` for the
  recommendation.
- [ ] Run the three demonstration queries once so the outputs are warm.
- [ ] Silence notifications and close unrelated windows.
- [ ] Replace the placeholder video URL in the two READMEs after uploading.

## Timing overview

| Section | Duration | What to cover |
|---|---|---|
| 1. Introduction | 0:30 | Platform theme and the main business question |
| 2. SQL Demonstration | 2:00 | Two or three representative queries, including a Unit 6 window function |
| 3. Key Findings and Recommendations | 1:00 | One or two findings, what they mean, and a next-quarter action |
| 4. Technical Challenge or Limitation | 1:00 | One challenge and how it was handled, or one limitation and how to improve it |
| 5. Close | 0:30 | Summary and a pointer to the GitHub repository |

---

## 1. Introduction — 0:00–0:30

**On screen:** the repository README, then the `trips` table or
`6.1-context-status-mix.png`.

**Say:**

> Hi, I'm Yousef. This is my EX603 ride-sharing analytics portfolio. The data
> covers 200 trips in 2023 across 30 riders and 15 drivers. The business
> question is whether the platform's failure problem is getting better or
> worse, and what the team should do next quarter. I define a failure as a
> cancelled trip: 34 of 200, or 17%. Ten disputed trips are reported
> separately. I'll show three queries, the findings, one challenge, and the
> repository.

**Why this opening works:** it states the platform, the data, the definition,
and the stakeholder question in under 30 seconds.

---

## 2. SQL Demonstration — 0:30–2:30


> First, the baseline from Unit 4. One pass over the trip table counts every
> event and counts failures with conditional aggregation. I used conditional aggregation instead of two separate queries
> because both numbers come from the same rows and the same filter, so they
> cannot drift apart. This is the baseline the window queries refine.


### 2b. The Unit 6 window query: event next to its producer average (1:00–1:45)

**On screen:** `q6_1.sql`, task 1, and `6.1-window-average.png`. Then
`6.1-ranking-tie.png` for five seconds.

**Say:**

> Second, Unit 6.1. The question is which individual cancellations are
> surprising for the producer who recorded them. `AVG(...) OVER (PARTITION BY
> driver_id)` keeps all 200 event rows and puts the producer's own failure
> rate on each row. The window version returns 200 rows; the `GROUP BY`
> version returns 13. The 187 missing rows are the event-level detail: trip,
> date, city, reason, and the deviation. The most surprising cancellation is
> trip 120 by producer 8: producer 8's rate is 5%, so the deviation is 0.95.
> A `GROUP BY` can tell me producer 8 has a 5% rate, but not which trip
> produced it. The same file ranks producers three ways; `RANK` gives tied
> producers 5 and 7 the same fourth place, while `ROW_NUMBER` would split them
> arbitrarily.

**Technique to name:** `AVG(...) OVER (PARTITION BY ...)`, `ROW_NUMBER`,
`RANK`, `DENSE_RANK`.
**Why:** the window keeps the row-level context; the ranking functions make
the tie policy explicit.

### 2c. Period over period: LAG on the monthly series (1:45–2:30)

**On screen:** `q6_3.sql`, Part B, and `6.3-B-monthly.png`.

**Say:**

> Third, Unit 6.3 period-over-period. `DATE_TRUNC('month', requested_at)`
> groups events into months. `LAG` compares each month with the previous one,
> and `NULLIF` prevents division by zero when the previous rate is 0%. The
> output shows the monthly rate and the percent change. This is why one month
> is not a decision unit: April is 0% on 11 events, June is 25% on 20. The
> quarterly view is the real signal: 22.64% in Q1, 14.58% in Q2, 15.69% in Q3,
> and 14.58% in Q4. The platform improved early and then plateaued.

**Technique to name:** `DATE_TRUNC`, `LAG`, `NULLIF`, and the calendar
continuity check.
**Why:** it turns a monthly list into a comparison while guarding against
missing months and division by zero.

---

## 3. Key Findings and Recommendations — 2:30–3:30

**On screen:** `6.3-B-quarterly.png`, `6.1-groupby.png`, and
`analysis/unit6-finding.md`.

**Say:**

> Two findings. First, the direction: the failure problem is better than its
> worst quarter, but it is no longer improving. The rate fell from 22.64% in
> Q1 to 14.58% in Q2, then stayed between 14.58% and 15.69% through Q4. That
> is a real early improvement, not a continuing decline.
>
> Second, the remaining problem is concentrated. Producers 11, 9, 2, and 3
> have rates above 23%. But 20 of the 34 cancellations are rider-side, 7 are
> payment failures, and 7 are driver unavailable, so not every cancellation is
> producer performance. The platform also finished at 34 cancellations against
> a 30 target, crossing the line in November.
>
> For next quarter, I recommend keeping a 15% ceiling with a 12% year-end
> stretch target, putting those four producers on an eight-week review,
> investigating Hue's 50% Q1 spike, and resolving the 10 disputed trips and
> the producer 9 gap before setting a harder target.

**Keep it to:** one trend finding, one concentration finding, and one
recommendation. The memo has the full action list.

---

## 4. Technical Challenge or Limitation — 3:30–4:30

**On screen:** `q6_3.sql` Part B, then `q6_2.sql` Part C and
`6.2-C-producer9.png`.

**Say:**

> One technical challenge was making month-over-month comparisons safe.
> `LAG` counts rows, not calendar months: if a month were missing, March would
> compare with January and look valid while being wrong. I fixed this by
> computing `LAG` on the actual monthly rows, then left-joining a generated
> calendar. A missing month appears as a zero-event row, and the next present
> month is flagged `MISSING MONTH(S)`. `NULLIF` also prevents division by zero
> when the previous rate is 0%.
>
> A limitation is the producer 9 gap: 112 days of silence, then activity
> resumes. The event table cannot tell whether the producer stopped or the
> feed lost them. I would add login, availability, dispatch-offer, and
> ingestion logs: no logins means a real stop; logins but no trips means a
> dispatch issue; trips in the source but not here means data loss.

**Why this section works:** it names a concrete technical trap, shows the fix,
and states one limitation with a specific next step.

---

## 5. Close — 4:30–5:00

**On screen:** the repository README with the deliverables table.

**Say:**

> To summarize: I built a reproducible SQL portfolio that moves from a
> data-quality audit to conditional aggregation, joins, and window functions.
> The analysis shows the failure rate improved early and then plateaued,
> identifies the producer and reason hotspots, and recommends a focused
> next-quarter review. The repository contains the queries, write-ups, memo,
> and screenshots. The complete project is in my GitHub repository; the link
> is in the README and in the video description. Thanks for watching.

---

## If you need to cut to four minutes

Keep the introduction, the Unit 6 window query, the two findings, and the
challenge. Cut the Unit 4 baseline to one sentence, the monthly query to one
sentence, and the producer ranking mention. Do not cut the failure definition
or the limitation; without them the numbers are not interpretable.

## If you have an extra minute

Show `6.1-ranking-tie.png` and explain the tie policy in more detail, or show
`6.2-B-running-total.png` and explain the November target crossing. Both are
strong portfolio moments.

## After recording

1. Upload to YouTube (unlisted is fine) or Loom.
2. Copy the public URL.
3. Replace the placeholder in:
   - `README.md` → the "Video walkthrough" section.
   - `unit3-assigment/unit-6/README.md` → the "Video" section.
4. Optional: embed the video in the root README with:

```html
<video src="YOUR_VIDEO_URL" controls width="100%"></video>
```

or link it with:

```markdown
[Watch the five-minute walkthrough](https://youtu.be/XXXXXXXXXXX)
```
