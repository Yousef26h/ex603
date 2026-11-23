# Unit 6 Screenshots

Each image shows the SQL and the result set from the same `psql` execution
against `ex603_data`. The images were captured from live `psql` output. Two
images use a display-only `LIMIT`; both are labelled in the image, and the query
files contain the untruncated statements.

## Task 6.1 — task 1: compare each event to its producer's average

| Image | What it shows |
|---|---|
| [`6.1-window-average.png`](6.1-window-average.png) | Every event with its producer's failure rate and deviation (first 20 of 200 rows) |
| [`6.1-unusual-cancellations.png`](6.1-unusual-cancellations.png) | The 15 cancellations with the largest positive deviation |
| [`6.1-groupby.png`](6.1-groupby.png) | The 13-row `GROUP BY` version |
| [`6.1-row-counts.png`](6.1-row-counts.png) | 200 window rows versus 13 grouped rows |
| [`6.1-context-status-mix.png`](6.1-context-status-mix.png) | Supporting context: completed, cancelled, and disputed counts with shares |
| [`6.1-context-reasons.png`](6.1-context-reasons.png) | Supporting context: cancellation reasons and their share of cancellations |

## Task 6.1 — task 2: rank producers three ways

| Image | What it shows |
|---|---|
| [`6.1-ranking-tie.png`](6.1-ranking-tie.png) | `ROW_NUMBER`, `RANK`, `DENSE_RANK` side by side on ties |

## Task 6.1 — task 3: sort producers into four bands

| Image | What it shows |
|---|---|
| [`6.1-ntile.png`](6.1-ntile.png) | `NTILE(4)` with the 18-event tie split across bands |

## Task 6.2 — Part A: row to row

| Image | What it shows |
|---|---|
| [`6.2-A-lag-lead.png`](6.2-A-lag-lead.png) | Producer 6: previous fare, next fare, and delta |

## Task 6.2 — Part B: cumulative and smoothed

| Image | What it shows |
|---|---|
| [`6.2-B-running-total.png`](6.2-B-running-total.png) | Monthly running total against the 30-cancellation target |
| [`6.2-B-moving-average.png`](6.2-B-moving-average.png) | The 7-event moving failure rate (most recent 30 events) |
| [`6.2-B-rows-vs-range.png`](6.2-B-rows-vs-range.png) | `ROWS` versus `RANGE` on a shared month key |
| [`6.2-B-last30.png`](6.2-B-last30.png) | Supporting context: failure rate over the most recent 30 events |

## Task 6.2 — Part C: where the series stops

| Image | What it shows |
|---|---|
| [`6.2-C-gaps.png`](6.2-C-gaps.png) | Gaps longer than 80 days between consecutive events |
| [`6.2-C-producer9.png`](6.2-C-producer9.png) | Producer 9's timeline around the 112-day gap |
| [`6.2-C-other-producers.png`](6.2-C-other-producers.png) | Supporting context: 61 events by 11 other producers during the gap |
| [`6.2-C-roster.png`](6.2-C-roster.png) | Supporting context: roster status for producers 9, 14, and 15 |

## Task 6.3 — Part A: top N per category

| Image | What it shows |
|---|---|
| [`6.3-A-top3.png`](6.3-A-top3.png) | Top three events by fare for every producer |

## Task 6.3 — Part B: period over period

| Image | What it shows |
|---|---|
| [`6.3-B-monthly.png`](6.3-B-monthly.png) | Monthly rate, lagged rate, percent change, continuity check |
| [`6.3-B-quarterly.png`](6.3-B-quarterly.png) | Quarterly rate and quarter-over-quarter change |
| [`6.3-B-city-quarter.png`](6.3-B-city-quarter.png) | Supporting context: city-level quarterly rates and changes |
