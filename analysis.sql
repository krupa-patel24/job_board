-- duplicate ids
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT application_id) AS distinct_ids FROM job;

-- work_mode spellings
SELECT work_mode, COUNT(*) FROM job GROUP BY 1;

-- blank source / blank reply
SELECT SUM(NULLIF(TRIM(source),'') IS NULL) AS blank_source,
       SUM(NULLIF(TRIM(days_to_first_reply),'') IS NULL) AS blank_reply
FROM job;

-- funnel logic (all should be 0)
SELECT SUM(hired='yes' AND interviewed<>'yes') AS hired_not_interviewed,
       SUM(interviewed='yes' AND shortlisted<>'yes') AS interviewed_not_shortlisted
FROM job;


-- 1. CLEAN TABLE
---------------------------------------------------------------
DROP TABLE IF EXISTS apps_clean;

CREATE TABLE apps_clean AS
SELECT DISTINCT                                   -- removes the 6 exact duplicate rows
       TRIM(application_id)                                   AS application_id,
       applied_on,
       role_category,
       LOWER(REPLACE(TRIM(work_mode),'-','_'))                AS work_mode,   -- On-site -> on_site
       CAST(stipend_inr_month AS INTEGER)                     AS stipend_inr_month,
       CASE WHEN CAST(stipend_inr_month AS INTEGER) > 0 THEN 'paid' ELSE 'unpaid' END AS pay_type,
       COALESCE(NULLIF(TRIM(source),''),'unknown')            AS source,      -- blank -> unknown
       CAST(steps_done AS INTEGER)                            AS steps_done,
       CASE WHEN shortlisted='yes' THEN 1 ELSE 0 END          AS shortlisted,
       CASE WHEN interviewed='yes' THEN 1 ELSE 0 END          AS interviewed,
       CASE WHEN hired='yes'       THEN 1 ELSE 0 END          AS hired,
       CAST(NULLIF(TRIM(days_to_first_reply),'') AS INTEGER)  AS days_to_first_reply -- NULL = no reply
FROM job;

 
-- check: expect 1200 rows, 1200 distinct ids
SELECT COUNT(*) AS n, COUNT(DISTINCT application_id) AS ids FROM apps_clean;



-- Q1a. Hires per 100 applications, by source
---------------------------------------------------------------
SELECT source, COUNT(*) AS applications, SUM(hired) AS hires,
       ROUND(100.0*SUM(hired)/COUNT(*),1) AS hires_per_100
FROM apps_clean
GROUP BY source
ORDER BY hires_per_100 DESC;
 
---------------------------------------------------------------
-- Q1b. Same, by role_category x source (does it hold?)
---------------------------------------------------------------
SELECT role_category, source, COUNT(*) AS applications, SUM(hired) AS hires,
       ROUND(100.0*SUM(hired)/COUNT(*),1) AS hires_per_100
FROM apps_clean
WHERE source <> 'unknown'
GROUP BY role_category, source
ORDER BY role_category, hires_per_100 DESC;




-- Q2. Shortlist rate: all 4 steps vs fewer
---------------------------------------------------------------
SELECT CASE WHEN steps_done=4 THEN 'all 4 steps' ELSE 'fewer than 4' END AS grp,
       COUNT(*) AS applications, SUM(shortlisted) AS shortlisted,
       ROUND(100.0*SUM(shortlisted)/COUNT(*),1) AS shortlist_pct
FROM apps_clean
GROUP BY 1;
 
-- Q2 chart data: shortlist rate at each step count
SELECT steps_done, COUNT(*) AS applications, SUM(shortlisted) AS shortlisted,
       ROUND(100.0*SUM(shortlisted)/COUNT(*),1) AS shortlist_pct
FROM apps_clean
GROUP BY steps_done ORDER BY steps_done;
 
-- Q2 robustness: same gap inside each role
SELECT role_category,
       ROUND(100.0*SUM(CASE WHEN steps_done=4 THEN shortlisted END)/SUM(steps_done=4),1)  AS pct_all4,
       ROUND(100.0*SUM(CASE WHEN steps_done<4  THEN shortlisted END)/SUM(steps_done<4),1) AS pct_fewer
FROM apps_clean GROUP BY role_category;



-- Q3a. Reply speed + no-reply share, paid vs unpaid
---------------------------------------------------------------
SELECT pay_type, COUNT(*) AS applications,
       COUNT(days_to_first_reply) AS replied,
       ROUND(100.0*(COUNT(*)-COUNT(days_to_first_reply))/COUNT(*),1) AS no_reply_pct,
       ROUND(AVG(days_to_first_reply),1) AS mean_days
FROM apps_clean GROUP BY pay_type;
 
-- Q3b. Median (SQLite has no MEDIAN) among those who replied
WITH r AS (
  SELECT pay_type, days_to_first_reply d,
         ROW_NUMBER() OVER (PARTITION BY pay_type ORDER BY days_to_first_reply) rn,
         COUNT(*)     OVER (PARTITION BY pay_type) cnt
  FROM apps_clean WHERE days_to_first_reply IS NOT NULL)
SELECT pay_type, AVG(d) AS median_days
FROM r WHERE rn IN ((cnt+1)/2, (cnt+2)/2)
GROUP BY pay_type;
 
-- Q3c. Is it stable by month? 
SELECT SUBSTR(applied_on,1,7) AS month, pay_type, COUNT(*) AS n,
       ROUND(100.0*(COUNT(*)-COUNT(days_to_first_reply))/COUNT(*),1) AS no_reply_pct
FROM apps_clean GROUP BY 1,2 ORDER BY 1,2;



 