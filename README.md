# Job Board Applications: Work Sample (Jul–Sep 2026)

## 1. Task

A job board for students has three months of applications (July–September 2026, 1,206 rows, made-up data). Questions from the manager:

1. Which **source** brings the most hires per 100 applications? Does the answer hold for each **role category**?
2. Are applicants who finish **all 4 steps** shortlisted more often than those who do not? By how much?
3. How fast do applicants hear back from **paid vs unpaid** roles, and what share never hear back? Is the gap big enough to act on?

Deliverables: the work (SQL), one chart, and a ~200-word note to the manager.

## 2. What is in this folder

| File | What it is |
|---|---|
| `job-board-applications.csv` | Original dataset, untouched |
|  apps\_clean.csv| Cleaned dataset  | 
| analysis.sql | All queries: audit, cleaning, Q1, Q2, Q3 |
| chat.numbers  | Chart answering Q2 |
| `README.md` | This file: method, findings, note, AI disclosure |

## 3. How to re-run (same numbers every time)

Tool: DBeaver with a SQLite connection.

1. Create a new SQLite connection (e.g. `job_board.db`).
2. Import `job-board-applications.csv` as a table named `job_board_applications` (expect 1,206 rows).
3. Open `analysis.sql` and run it top to bottom. The raw table is never edited; cleaning creates a new table, `apps_clean` (expect 1,200 rows).

## 4. Data checks and cleaning

| Issue found | Count | What I did |
|---|---|---|
| Exact duplicate rows (same `application_id`) | 6 | Removed, 1,206 → 1,200 rows |
| `work_mode` spelled inconsistently (`On-site`, `Hybrid`, `Remote`) | 9 | Standardised to `on_site`, `hybrid`, `remote` |
| Blank `source` | 15 | Labelled `unknown`, left out of the Q1 ranking (kept in other questions) |
| Blank `days_to_first_reply` | 236 (before dedup) | Kept as NULL, meaning "no reply yet", never turned into 0 |

Checks that passed: dates all fall in 2026-07-01 to 2026-09-30; no one is hired without being interviewed, and no one is interviewed without being shortlisted; `steps_done` is always 0–4; stipend 0 is treated as unpaid.

## 5. Findings

### Q1. Hires per 100 applications, by source

| Source | Applications | Hires | Hires per 100 |
|---|---|---|---|
| referral | 121 | 13 | **10.7** |
| email | 160 | 13 | 8.1 |
| search | 439 | 25 | 5.7 |
| college | 208 | 7 | 3.4 |
| social | 257 | 6 | 2.3 |

- Referral is highest, but it rests on only 13 hires. The 95% intervals overlap heavily (referral 6.4–17.5, email 4.8–13.4), and referral vs email is not a significant difference. Honest reading: **referral and email lead; social and college trail.**
- **It does not hold for each role.** Referral is first only in Design (23.1) and Marketing (22.2). Search is first in Data (7.4) and Finance (2.9), email in Software (11.4), college in Operations (20.0). Each role × source group has only 8–146 applications and 0–7 hires, so the role-level ranking is unstable.

### Q2. Finishing all 4 steps vs shortlisting

| Group | Applications | Shortlisted | Shortlist rate |
|---|---|---|---|
| Finished all 4 steps | 403 | 195 | **48.4%** |
| Finished fewer than 4 | 797 | 74 | **9.3%** |

- Gap: **39 points (95% CI 34–44), about 5×.**
- The gap appears in every role (all-4 rate 41–57%, others 7–14%).
- The jump happens only at step 4: 0 steps 8.5%, 1 step 5.6%, 2 steps 8.9%, 3 steps 12.8%, 4 steps 48.4%.
- This is an association. The data cannot show that finishing causes shortlisting (motivated applicants may do both).

### Q3. Paid vs unpaid: reply speed and no-reply share

| | Applications | Median days | Mean days | Never replied |
|---|---|---|---|---|
| Paid | 734 | 3 | 3.2 | **13.1%** |
| Unpaid | 466 | 7 | 7.6 | **29.6%** |

- Unpaid roles take about 4 days longer at the median and are about 16.5 points more likely never to reply (95% CI 12–21).
- The pattern is the same in July, August and September (unpaid no-reply 27–34%, paid 11–15%), so it is not caused by recent applications simply waiting for a reply.
- **Big enough to act on:** yes.

## 6. Chart

`chart_shortlist_by_steps.png` shows the shortlist rate at each number of steps finished (0–4). It answers Q2: the rate is low and flat until step 4, then jumps to 48%.

## 7. Note to manager

**Subject: Job board applications, Jul–Sep 2026**

here are the answers (1,200 applications after cleaning).

**1. Best source.** Referral: 10.7 hires per 100 applications (13 of 121), then email 8.1, search 5.7, college 3.4, social 2.3. Treat it as "referral and email lead", not a clear winner: both have only 13 hires and the gap between them is within noise. It does not hold by role. Referral leads only in Design and Marketing; search leads Data and Finance, email leads Software, college leads Operations (groups of 8–80 applications, 0–5 hires).

**2. Finishing all 4 steps.** Yes. 48.4% of those who finished were shortlisted versus 9.3% of the rest, 39 points higher (about 5×), in every role. This is an association, not proof that finishing causes shortlisting.

**3. Paid vs unpaid replies.** Paid roles: median 3 days, 13.1% never reply. Unpaid: median 7 days, 29.6% never reply. The gap is large and similar every month, so it is worth acting on.

**Recommendation:** next month, send unpaid-role employers an automatic reminder if an application is unanswered after 5 days.

**Not fully trusted:** I removed 6 duplicate rows and standardised work_mode spellings. 15 blank sources were excluded from Q1. A blank reply could mean "not yet" rather than "never". Only 64 hires exist, so small groups are noisy.

## 8. Limits of this analysis

- Only 64 hires in total, so any hire-rate comparison by source, and especially by role × source, is noisy.
- A blank `days_to_first_reply` cannot tell "never" from "not yet"; I treated blank as "no reply yet" and checked it is stable by month.
- Data is made up and observational, so Q2 and Q3 show association, not cause.
- The 15 `unknown` sources are excluded from the Q1 ranking only.

## 9. Use of AI tools

I used an AI assistant (Claude, by Anthropic) while doing this task. To be clear about what it did and what I did:

- **AI-assisted:** a first draft of the SQL in `analysis.sql` (audit, cleaning, Q1–Q3 queries), the draft wording of the manager note, the confidence-interval and significance checks, and guidance on building the chart in Numbers and fixing its layout.
- **What I did myself:** imported the data into DBeaver, ran every query, compared the results with the figures above, built the chart in Numbers, and reviewed and edited the SQL, the note and this README.
- **What I changed:** I entered the correct data into the chart myself and formatted it so it is easy to read (labels, axis titles, legend, bar layout). I also checked the results against my own query output to see where the analysis could be improved, mainly the small-sample limits in Q1 and the blank-reply assumption in Q3.
