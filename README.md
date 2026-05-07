# 💳 FinSight — Credit Card Transaction Analytics & Forecasting

> End-to-end financial data analytics project covering EDA, customer segmentation, fraud pattern analysis, and time-series forecasting on 1.85M real-world credit card transactions.

## 📌 Project Overview

FinSight is a portfolio-grade financial analytics project that simulates the work of a data analyst at a credit card company. Starting from raw transaction CSVs, the project builds a complete analytics pipeline — from data cleaning and SQL querying to RFM customer segmentation, fraud pattern analysis, and 90-day spend forecasting using Meta's Prophet.

**Dataset:** [Credit Card Transactions Fraud Detection — Kaggle (kartik2112)](https://www.kaggle.com/datasets/kartik2112/fraud-detection)

| Metric | Value |
|---|---|
| Total transactions | 1,852,394 |
| Date range | Jan 2019 — Dec 2020 |
| Unique customers | ~950+ |
| Unique merchants | ~693 |
| Merchant categories | 14 |
| Fraud rate | 0.57% |
| Total revenue | ~$130M |

---

## 🎯 Business Questions Answered

| # | Question | Module |
|---|---|---|
| 1 | How is monthly revenue and transaction volume trending? | EDA |
| 2 | Which merchant categories drive the most revenue? | EDA |
| 3 | When do customers spend the most (hour × day)? | EDA |
| 4 | Which categories have the highest fraud rate? | EDA |
| 5 | How does spending differ across age groups and genders? | EDA |
| 6 | Who are our Champions, Loyal, At-Risk, and Lost customers? | RFM |
| 7 | What % of revenue comes from top customer segments? | RFM |
| 8 | What will spend look like over the next 90 days? | Prophet |
| 9 | How do Champions vs At-Risk segments forecast differently? | Prophet |
| 10 | What are the key SQL-level KPIs for business reporting? | MySQL |

---

## 🔑 Key Findings

### Revenue & Volume
- **December spikes**: Holiday season drives ~2.5× normal daily spend — Dec 2019 and Dec 2020 both hit ~$450K/day peak vs ~$150K average
- **Grocery dominates**: `grocery_pos` alone accounts for **$20.6M** (15.8% of total spend), followed by `shopping_pos` ($13.1M) and `shopping_net` ($12.1M)
- **Upward trend**: Prophet baseline trend grew from $159K/day (Jan 2019) to $178K/day (Dec 2020), indicating consistent business growth
- **January dip**: Revenue drops ~40% every January — strong post-holiday seasonality confirmed by Prophet's yearly component

### Spending Patterns
- **Peak hours**: Spending is highest between **12pm–11pm**, with Monday and Sunday evenings (10pm–11pm) being the absolute peak — ideal for promotional targeting
- **Wednesday is the weakest day**: Prophet's weekly component shows Wednesday spend is **~40% below baseline**, while Sunday/Monday are +30–40%
- **Bimodal spending distribution**: Log-transformed amounts show two distinct customer spending behaviours — micro transactions (log~2.5, ~$12) and regular purchases (log~4.3, ~$74)
- **25–35 age group spends most**: Average transaction of **$75**, vs $64 for under-25s
- **Female customers outspend males** in grocery, shopping, and personal care; males lead in travel

### Fraud Intelligence
- **shopping_net has the highest fraud rate at 1.59%**, followed by misc_net (1.30%) and grocery_pos (1.26%) — online channels are significantly riskier
- **Fraud correlates with amount (r=0.21)**: Higher-value transactions are meaningfully more likely to be fraudulent — the strongest predictor in the correlation matrix
- **Seniors (65+) face the highest fraud rate (0.67%)** vs 35–50 age group which has the lowest (0.43%) — elder financial vulnerability is a clear pattern
- **misc_pos fraud transactions are unusually large** — the fraud box plot shows the widest distribution for this category, suggesting large-amount fraud attempts

### Customer Segments (RFM)
- **Champions (16.8%) + Loyal Customers (22.4%) = 56.9% of all revenue** ($73.9M combined) from ~39% of the customer base
- **At-Risk segment (10.7% of customers) contributes $23.2M (17.8%)** — highest priority for retention campaigns
- **RFM heatmap shows At-Risk customers have excellent F=4.56 and M=4.36 but R=1.80** — they were highly valuable but stopped purchasing recently
- **Lost segment (20.8%)** has uniformly low R, F, M scores (~1.3 each) — least likely to respond to reactivation
- **New Customers (12%)** have high recency (R=4.49) but very low frequency and spend — nurturing pipeline opportunity

### Forecast (Prophet)
- **Next 30 days: $3.9M** | Next 60 days: $7.8M | **Next 90 days: $12.6M**
- Champions segment daily spend forecast: **$40K–$80K/day** with holiday potential of $130K/day
- At-Risk segment daily spend: **$20K–$50K/day** — retaining these customers could protect ~$23M annually
- The model captures weekly seasonality (Sunday/Monday peaks, Wednesday trough) and the strong December holiday effect with high confidence

---

## 🗂️ Repository Structure

```
finsight/
│
├── README.md                        ← This file
│
├── notebooks/
│   ├── step1_load_data.py           ← Load & clean CSVs, feature engineering
│   ├── step2_eda.py                 ← 9 EDA charts (matplotlib + seaborn)
│   ├── step3_rfm_segmentation.py    ← RFM scoring + customer segments
│   ├── step5_prophet_forecast.py    ← 3 Prophet models (spend, volume, segment)
│   └── export_for_powerbi.py        ← Export 8 aggregated CSVs for Power BI
│
├── sql/
│   └── mysql_queries.sql            ← 15 business KPI queries + table setup
│
├── outputs/
│   ├── plots/
│   │   ├── plot1_monthly_trend.png
│   │   ├── plot2_amount_dist.png
│   │   ├── plot3_category_spend.png
│   │   ├── plot4_heatmap_dow_hour.png
│   │   ├── plot5_fraud_boxplot.png
│   │   ├── plot6_fraud_rate_by_category.png
│   │   ├── plot7_age_group.png
│   │   ├── plot8_gender_category.png
│   │   ├── plot9_correlation.png
│   │   ├── prophet_A1_forecast.png
│   │   ├── prophet_A2_components.png
│   │   ├── prophet_B1_count_forecast.png
│   │   ├── prophet_C1_segment_forecast.png
│   │   ├── rfm_plot1_donut.png
│   │   ├── rfm_plot2_heatmap.png
│   │   ├── rfm_plot3_revenue.png
│   │   └── rfm_plot4_scatter.png
│   ├── rfm_table.csv
│   └── forecast_daily_spend.csv
│
├── powerbi/
│   └── FinSight_Dashboard.pbix      ← Power BI dashboard (5 pages)
│
├── data/
│   └── README.md                    ← Dataset download instructions
│
└── requirements.txt
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Python 3.10+ | Core language |
| pandas, numpy | Data manipulation |
| matplotlib, seaborn | Visualisation |
| Prophet (Meta) | Time-series forecasting |
| MySQL 8.0 | SQL analytics & KPI queries |
| Power BI Desktop | Interactive dashboard |

---

## 💼 Business Applicability

This project directly maps to real-world work at:
- **American Express, Barclays, HDFC, ICICI** — fraud analytics, RFM, spend forecasting
- **TCS, Infosys, Cognizant, Wipro** — BFSI domain client delivery
- **Razorpay, PhonePe, PayPal** — transaction analytics pipelines
- **Fractal Analytics, Mu Sigma, EXL** — decision science & analytics consulting

---

## 👤 Author

**Ashwin** · Data Analyst  
📍 Kerala, India  
🔗 [LinkedIn](https://linkedin.com) · [GitHub](https://github.com)

---

## 📄 License

This project uses the Kaggle public dataset under its respective license. All code in this repository is MIT licensed.
