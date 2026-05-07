-- ================================================================
--  FINSIGHT — MySQL Setup + 15 Business Insight Queries
--  Dataset : fraudTrain.csv + fraudTest.csv (1,852,394 rows)
--  Tool    : MySQL Workbench
-- ================================================================
-- HOW TO IMPORT CSVs WITHOUT PYTHON:
--
--  OPTION A (Easiest) — MySQL Workbench Table Import Wizard
--  1. Open MySQL Workbench → connect to your local server
--  2. Right-click your database → "Table Data Import Wizard"
--  3. Browse → select fraudTrain.csv → Next
--  4. Create new table → name it: transactions_train
--  5. Repeat for fraudTest.csv → name it: transactions_test
--  6. Run the MERGE step below to combine both into one table
--
--  OPTION B — LOAD DATA INFILE (faster, bulk load)
--  Make sure local_infile is enabled:
--  SET GLOBAL local_infile = 1;
-- ================================================================


-- ── Step 0: Create database ───────────────────────────────────
CREATE DATABASE IF NOT EXISTS finsight_db;
USE finsight_db;


-- ── Step 1: Create the main table ────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    id                    INT,
    trans_date_trans_time DATETIME,
    cc_num                BIGINT,
    merchant              VARCHAR(255),
    category              VARCHAR(100),
    amt                   DECIMAL(10,2),
    first_name            VARCHAR(100),
    last_name             VARCHAR(100),
    gender                CHAR(1),
    street                VARCHAR(255),
    city                  VARCHAR(100),
    state                 CHAR(2),
    zip                   VARCHAR(10),
    lat                   DECIMAL(10,6),
    lon                   DECIMAL(10,6),
    city_pop              INT,
    job                   VARCHAR(255),
    dob                   DATE,
    trans_num             VARCHAR(100),
    unix_time             BIGINT,
    merch_lat             DECIMAL(10,6),
    merch_long            DECIMAL(10,6),
    is_fraud              TINYINT
);


-- ── Step 2: Load CSVs (OPTION B — LOAD DATA INFILE) ──────────
-- Run this for fraudTrain.csv:
LOAD DATA LOCAL INFILE 'C:/path/to/fraudTrain.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, trans_date_trans_time, cc_num, merchant, category, amt,
 first_name, last_name, gender, street, city, state, zip,
 lat, lon, city_pop, job, dob, trans_num, unix_time,
 merch_lat, merch_long, is_fraud);

-- Run this for fraudTest.csv (same table, just append):
LOAD DATA LOCAL INFILE 'C:/path/to/fraudTest.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, trans_date_trans_time, cc_num, merchant, category, amt,
 first_name, last_name, gender, street, city, state, zip,
 lat, lon, city_pop, job, dob, trans_num, unix_time,
 merch_lat, merch_long, is_fraud);


-- ── Step 3: Add computed columns (run once after import) ─────
ALTER TABLE transactions
    ADD COLUMN trans_year   SMALLINT  AS (YEAR(trans_date_trans_time))  STORED,
    ADD COLUMN trans_month  TINYINT   AS (MONTH(trans_date_trans_time)) STORED,
    ADD COLUMN trans_hour   TINYINT   AS (HOUR(trans_date_trans_time))  STORED,
    ADD COLUMN trans_dow    VARCHAR(10) AS (DAYNAME(trans_date_trans_time)) STORED,
    ADD COLUMN age          TINYINT   AS (TIMESTAMPDIFF(YEAR, dob, trans_date_trans_time)) STORED;

-- ── Step 4: Add indexes for faster queries ───────────────────
CREATE INDEX idx_category  ON transactions(category);
CREATE INDEX idx_is_fraud  ON transactions(is_fraud);
CREATE INDEX idx_cc_num    ON transactions(cc_num);
CREATE INDEX idx_state     ON transactions(state);
CREATE INDEX idx_date      ON transactions(trans_date_trans_time);


-- ================================================================
--  15 BUSINESS INSIGHT QUERIES
-- ================================================================


-- ────────────────────────────────────────────────────────────────
--  Q1.  EXECUTIVE KPI SUMMARY
--  Business question: What are the top-line numbers for the board?
-- ────────────────────────────────────────────────────────────────
SELECT
    FORMAT(COUNT(*), 0)                                  AS total_transactions,
    CONCAT('$', FORMAT(SUM(amt), 2))                     AS total_revenue,
    FORMAT(COUNT(DISTINCT cc_num), 0)                    AS unique_customers,
    FORMAT(COUNT(DISTINCT merchant), 0)                  AS unique_merchants,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_transaction_value,
    FORMAT(SUM(is_fraud), 0)                             AS total_fraud_transactions,
    CONCAT(ROUND(AVG(is_fraud) * 100, 3), '%')           AS fraud_rate,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 2))          AS total_fraud_amount,
    MIN(DATE(trans_date_trans_time))                     AS data_from,
    MAX(DATE(trans_date_trans_time))                     AS data_to
FROM transactions;


-- ────────────────────────────────────────────────────────────────
--  Q2.  MONTHLY REVENUE & FRAUD TREND
--  Business question: Is revenue growing? Is fraud getting worse?
-- ────────────────────────────────────────────────────────────────
SELECT
    trans_year                                           AS yr,
    trans_month                                          AS mo,
    DATE_FORMAT(trans_date_trans_time, '%Y-%m')          AS year_month,
    COUNT(*)                                             AS total_transactions,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_revenue,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_transaction,
    COUNT(DISTINCT cc_num)                               AS active_customers,
    SUM(is_fraud)                                        AS fraud_count,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate_pct
FROM transactions
GROUP BY trans_year, trans_month, year_month
ORDER BY trans_year, trans_month;


-- ────────────────────────────────────────────────────────────────
--  Q3.  TOP 5 HIGHEST REVENUE CATEGORIES
--  Business question: Where is most of the spend happening?
-- ────────────────────────────────────────────────────────────────
SELECT
    category,
    COUNT(*)                                             AS transactions,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_spend,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_spend,
    CONCAT('$', FORMAT(MAX(amt), 2))                     AS max_single_txn,
    CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM transactions) * 100, 2), '%') AS txn_share,
    RANK() OVER (ORDER BY SUM(amt) DESC)                 AS revenue_rank
FROM transactions
GROUP BY category
ORDER BY SUM(amt) DESC
LIMIT 5;


-- ────────────────────────────────────────────────────────────────
--  Q4.  FRAUD RATE BY CATEGORY (sorted worst first)
--  Business question: Which product categories are highest fraud risk?
-- ────────────────────────────────────────────────────────────────
SELECT
    category,
    COUNT(*)                                              AS total_txns,
    SUM(is_fraud)                                         AS fraud_txns,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate_pct,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 2))           AS fraud_amount_lost,
    CONCAT('$', FORMAT(AVG(CASE WHEN is_fraud=1 THEN amt END), 2)) AS avg_fraud_txn_size
FROM transactions
GROUP BY category
ORDER BY SUM(is_fraud) / COUNT(*) DESC;


-- ────────────────────────────────────────────────────────────────
--  Q5.  CUSTOMER SPENDING TIERS (top 10% vs rest)
--  Business question: How much do our top customers contribute?
-- ────────────────────────────────────────────────────────────────
WITH customer_spend AS (
    SELECT
        cc_num,
        COUNT(*)                                         AS txn_count,
        SUM(amt)                                         AS total_spend,
        NTILE(10) OVER (ORDER BY SUM(amt) DESC)          AS spend_decile
    FROM transactions
    WHERE is_fraud = 0
    GROUP BY cc_num
)
SELECT
    spend_decile,
    COUNT(*)                                             AS customer_count,
    CONCAT('$', FORMAT(SUM(total_spend), 0))             AS segment_revenue,
    CONCAT('$', FORMAT(AVG(total_spend), 2))             AS avg_customer_spend,
    CONCAT(ROUND(SUM(total_spend) /
        (SELECT SUM(amt) FROM transactions WHERE is_fraud=0) * 100, 1), '%') AS revenue_share
FROM customer_spend
GROUP BY spend_decile
ORDER BY spend_decile;


-- ────────────────────────────────────────────────────────────────
--  Q6.  PEAK TRANSACTION HOURS
--  Business question: When are customers most active? Plan server capacity.
-- ────────────────────────────────────────────────────────────────
SELECT
    trans_hour                                           AS hour_of_day,
    COUNT(*)                                             AS total_transactions,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_spend,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_spend,
    SUM(is_fraud)                                        AS fraud_count,
    CASE
        WHEN trans_hour BETWEEN 9 AND 17 THEN 'Business hours'
        WHEN trans_hour BETWEEN 18 AND 22 THEN 'Evening'
        ELSE 'Off-hours (fraud risk)'
    END                                                  AS time_segment
FROM transactions
GROUP BY trans_hour
ORDER BY trans_hour;


-- ────────────────────────────────────────────────────────────────
--  Q7.  GENDER & AGE GROUP SPENDING BEHAVIOUR
--  Business question: How do demographics drive spending differences?
-- ────────────────────────────────────────────────────────────────
SELECT
    gender,
    CASE
        WHEN age < 25  THEN 'Under 25'
        WHEN age < 35  THEN '25–34'
        WHEN age < 50  THEN '35–49'
        WHEN age < 65  THEN '50–64'
        ELSE '65+'
    END                                                  AS age_group,
    COUNT(*)                                             AS transactions,
    COUNT(DISTINCT cc_num)                               AS customers,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_spend,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_spend,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate
FROM transactions
GROUP BY gender, age_group
ORDER BY gender, MIN(age);


-- ────────────────────────────────────────────────────────────────
--  Q8.  TOP 10 STATES BY REVENUE AND FRAUD EXPOSURE
--  Business question: Where is the most business and risk concentrated?
-- ────────────────────────────────────────────────────────────────
SELECT
    state,
    COUNT(*)                                             AS total_transactions,
    COUNT(DISTINCT cc_num)                               AS unique_customers,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_revenue,
    SUM(is_fraud)                                        AS fraud_count,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate_pct,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 0))          AS fraud_amount
FROM transactions
GROUP BY state
ORDER BY SUM(amt) DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────────
--  Q9.  HIGH-VALUE TRANSACTION ANALYSIS (above $500)
--  Business question: What share of revenue comes from large transactions?
-- ────────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN amt < 10    THEN 'Micro (< $10)'
        WHEN amt < 50    THEN 'Small ($10–$49)'
        WHEN amt < 100   THEN 'Medium ($50–$99)'
        WHEN amt < 500   THEN 'Large ($100–$499)'
        ELSE                  'High-value ($500+)'
    END                                                  AS transaction_band,
    COUNT(*)                                             AS txn_count,
    CONCAT(ROUND(COUNT(*) / (SELECT COUNT(*) FROM transactions) * 100, 2), '%') AS txn_share,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_spend,
    CONCAT(ROUND(SUM(amt) / (SELECT SUM(amt) FROM transactions) * 100, 2), '%') AS revenue_share,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate
FROM transactions
GROUP BY transaction_band
ORDER BY MIN(amt);


-- ────────────────────────────────────────────────────────────────
--  Q10.  CUSTOMER RFM SEED TABLE
--  Business question: Who are our most valuable / most at-risk customers?
-- ────────────────────────────────────────────────────────────────
SELECT
    cc_num,
    DATEDIFF(
        (SELECT MAX(DATE(trans_date_trans_time)) FROM transactions),
        MAX(DATE(trans_date_trans_time))
    )                                                    AS recency_days,
    COUNT(*)                                             AS frequency,
    CONCAT('$', FORMAT(SUM(amt), 2))                     AS monetary,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_txn,
    MIN(DATE(trans_date_trans_time))                     AS first_transaction,
    MAX(DATE(trans_date_trans_time))                     AS last_transaction,
    COUNT(DISTINCT category)                             AS categories_used,
    DATEDIFF(
        MAX(trans_date_trans_time),
        MIN(trans_date_trans_time)
    )                                                    AS customer_lifespan_days
FROM transactions
WHERE is_fraud = 0
GROUP BY cc_num
ORDER BY SUM(amt) DESC
LIMIT 20;


-- ────────────────────────────────────────────────────────────────
--  Q11.  DAY-OF-WEEK SPENDING PATTERN
--  Business question: Which days drive the most revenue?
-- ────────────────────────────────────────────────────────────────
SELECT
    trans_dow                                            AS day_of_week,
    COUNT(*)                                             AS transactions,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_spend,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_spend,
    SUM(is_fraud)                                        AS fraud_count,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate
FROM transactions
GROUP BY trans_dow
ORDER BY
    FIELD(trans_dow, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');


-- ────────────────────────────────────────────────────────────────
--  Q12.  REPEAT FRAUD VICTIMS (customers with 2+ fraud hits)
--  Business question: Are the same customers being targeted repeatedly?
-- ────────────────────────────────────────────────────────────────
SELECT
    cc_num,
    CONCAT(MIN(first_name), ' ', MIN(last_name))         AS customer_name,
    MIN(state)                                           AS state,
    COUNT(*)                                             AS total_transactions,
    SUM(is_fraud)                                        AS fraud_hits,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 1), '%') AS personal_fraud_rate,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 2))          AS total_fraud_loss,
    MIN(CASE WHEN is_fraud=1
        THEN DATE(trans_date_trans_time) END)            AS first_fraud_date,
    MAX(CASE WHEN is_fraud=1
        THEN DATE(trans_date_trans_time) END)            AS last_fraud_date
FROM transactions
GROUP BY cc_num
HAVING SUM(is_fraud) >= 2
ORDER BY SUM(is_fraud) DESC, SUM(amt * is_fraud) DESC
LIMIT 15;


-- ────────────────────────────────────────────────────────────────
--  Q13.  TOP 10 MERCHANTS BY VOLUME AND FRAUD RATE
--  Business question: Which merchants have the highest fraud exposure?
-- ────────────────────────────────────────────────────────────────
SELECT
    merchant,
    category,
    COUNT(*)                                             AS total_txns,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_volume,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_txn,
    SUM(is_fraud)                                        AS fraud_txns,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate_pct,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 2))          AS fraud_amount
FROM transactions
GROUP BY merchant, category
HAVING COUNT(*) >= 50
ORDER BY SUM(amt * is_fraud) DESC
LIMIT 10;


-- ────────────────────────────────────────────────────────────────
--  Q14.  LATE NIGHT FRAUD PATTERN
--  Business question: Are off-hours transactions significantly riskier?
-- ────────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN trans_hour BETWEEN 0  AND 5  THEN 'Late night (12am–5am)'
        WHEN trans_hour BETWEEN 6  AND 11 THEN 'Morning (6am–11am)'
        WHEN trans_hour BETWEEN 12 AND 17 THEN 'Afternoon (12pm–5pm)'
        WHEN trans_hour BETWEEN 18 AND 22 THEN 'Evening (6pm–10pm)'
        ELSE                                   'Night (11pm)'
    END                                                  AS time_window,
    COUNT(*)                                             AS total_txns,
    SUM(is_fraud)                                        AS fraud_count,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate_pct,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_txn_size,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 0))          AS fraud_amount_lost
FROM transactions
GROUP BY time_window
ORDER BY SUM(is_fraud) / COUNT(*) DESC;


-- ────────────────────────────────────────────────────────────────
--  Q15.  YEAR-OVER-YEAR GROWTH COMPARISON
--  Business question: How did 2020 compare to 2019 across all KPIs?
-- ────────────────────────────────────────────────────────────────
SELECT
    trans_year                                           AS year,
    COUNT(*)                                             AS total_transactions,
    COUNT(DISTINCT cc_num)                               AS unique_customers,
    COUNT(DISTINCT merchant)                             AS unique_merchants,
    CONCAT('$', FORMAT(SUM(amt), 0))                     AS total_revenue,
    CONCAT('$', FORMAT(AVG(amt), 2))                     AS avg_transaction,
    CONCAT('$', FORMAT(MAX(amt), 2))                     AS largest_transaction,
    SUM(is_fraud)                                        AS fraud_count,
    CONCAT(ROUND(SUM(is_fraud) / COUNT(*) * 100, 3), '%') AS fraud_rate,
    CONCAT('$', FORMAT(SUM(amt * is_fraud), 0))          AS fraud_amount_lost
FROM transactions
GROUP BY trans_year
ORDER BY trans_year;
