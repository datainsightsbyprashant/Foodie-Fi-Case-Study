# Foodie-Fi - Subscription Analytics Case Study

A comprehensive SQL analysis of subscription patterns, customer behavior, and revenue optimization for Foodie-Fi, a streaming service dedicated to food content.

## Project Overview

Foodie-Fi is a subscription-based streaming platform launched in 2020, offering unlimited on-demand access to exclusive food videos from around the world. This analysis examines customer journey patterns, plan transitions, churn behavior, and payment calculations to inform data-driven business decisions.

**Key Business Questions:**
- How do customers progress through subscription tiers?
- What drives upgrades to annual plans?
- When and why do customers churn?
- How can we optimize the trial-to-paid conversion?

## Key Findings

### Conversion & Retention Metrics
- **91% trial-to-paid conversion rate** - Strong initial product-market fit
- **30% overall churn rate** - Key opportunity for retention improvement
- **9% immediate post-trial churn** - 92 customers churned right after free trial
- **Zero downgrades** from Pro Monthly to Basic Monthly - High satisfaction with premium tiers

### Customer Behavior Patterns
- **Three distinct segments identified**: Cautious Adopters, Confident/Decisive Adopters, and Churned Customers
- **Average upgrade time to annual plan: 105 days** - Optimal window for upselling campaigns
- **Peak upgrade period: 90-180 days** - 75 customers upgraded during this window
- **158 customers upgraded to Pro Annual in 2020** - Strong indicator of product loyalty

### Plan Distribution (End of 2020)
- Pro Monthly: 326 customers (32.6%)
- Pro Annual: 195 customers (19.5%)
- Basic Monthly: 224 customers (22.4%)
- Churned: 307 customers (30.7%)

## Tech Stack

- **Database**: MySQL
- **Analysis Tool**: SQL (Window Functions, CTEs, Recursive CTEs, LEAD/LAG)
- **Key Techniques**: Customer journey mapping, cohort analysis, payment calculations

## Repository Structure

```
foodie-fi-subscription-analysis/
├── README.md                          # Project overview (you are here)
├── ANALYSIS.md                        # Detailed findings and recommendations
├── queries.sql                        # All SQL queries for the case study
└── schema.sql                         # Database schema and table definitions
```

## Sample Queries

### Customer Journey Tracking
```sql
SELECT customer_id, plan_id,
  LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id,
  LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_date
FROM subscriptions
WHERE customer_id IN (1,2,11,13,15,16,18,19);
```

### Churn Analysis
```sql
WITH customer_plans AS (
  SELECT customer_id, plan_id,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id
  FROM subscriptions
)
SELECT COUNT(DISTINCT customer_id) as immediate_churn_count
FROM customer_plans
WHERE plan_id = 0 AND next_plan_id = 4;
```

**See full query collection in [queries.sql](queries.sql) or detailed analysis in [ANALYSIS.md](ANALYSIS.md)**

## Business Recommendations

1. **Retention Focus**: Target Basic Monthly users with engagement campaigns before they churn
2. **Optimal Upselling Window**: Launch upgrade campaigns at 90-150 days post-signup
3. **Trial Enhancement**: Improve onboarding experience to reduce 9% immediate post-trial churn
4. **Annual Plan Incentives**: Offer limited-time discounts during the 3-6 month engagement peak

## Learning Outcomes

This case study demonstrates:
- Recursive CTEs for payment schedule generation
- Window functions (`LEAD`, `LAG`, `ROW_NUMBER`) for customer journey analysis
- Cohort analysis and customer segmentation
- Complex business logic implementation (prorated payments, billing cycles)
- Subscription metrics calculation (MRR, churn rate, upgrade patterns)

## Data Schema

**Tables:**
- `subscriptions`: Customer subscription history (customer_id, plan_id, start_date)
- `plans`: Available subscription plans (plan_id, plan_name, price)

**Plans Available:**
- Trial (7 days free)
- Basic Monthly ($9.90)
- Pro Monthly ($19.90)
- Pro Annual ($199.00)
- Churn (cancellation)

## Full Analysis

For detailed customer journey insights, complete query breakdowns, and comprehensive business recommendations, see **[ANALYSIS.md](ANALYSIS.md)**.

## Author

**Prashant**  
*Date: November 6, 2025*

---

*This case study is part of the [8 Week SQL Challenge](https://8weeksqlchallenge.com/) by Danny Ma*
