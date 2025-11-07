# Foodie-Fi - Detailed Analysis & Insights

**Prepared for**: Foodie-Fi  
**Prepared by**: Prashant  
**Date**: November 6, 2025

---

## Executive Summary

Foodie-Fi, a subscription-based digital food platform, experienced consistent user acquisition and healthy conversion trends during 2020. Every customer began with a 7-day free trial, reflecting a uniform onboarding funnel.

By the end of 2020, the company had onboarded 1,000 customers, out of which 91% transitioned to a paid plan, demonstrating a strong initial conversion rate. However, 9% of users churned immediately after the trial, and overall churn across all plans reached 30%, indicating opportunities for customer retention improvements.

Among paid users, Pro Monthly (326) and Pro Annual (195) were the most popular plans, while Basic Monthly (224) served as an entry-level option for budget-conscious customers.

A total of 158 customers upgraded to the Pro Annual plan during 2020 (excluding trials), marking a key growth indicator in customer maturity and product loyalty. Across all years, 258 users have upgraded, with an average upgrade time of 105 days—most occurring between 90-180 days of joining, showing that this period is the optimal window for upselling campaigns.

---

## A. Customer Journey Analysis

### Sample Customer Onboarding Journeys

**Query:**
```sql
SELECT
  customer_id, current_plan, next_plan, current_plan_start_date, next_plan_start_date,
  CASE
    WHEN next_plan IS NULL THEN 'Ongoing Plan'
    WHEN next_plan_id = 4 THEN 'Churn'
    WHEN next_plan_id < plan_id THEN 'Downgrade'
    WHEN next_plan_id > plan_id THEN 'Upgrade'
  END as Plan_category,
  CASE
    WHEN next_plan IS NULL THEN DATEDIFF('2021-04-30', current_plan_start_date) + 1
    ELSE DATEDIFF(next_plan_start_date, current_plan_start_date)
  END as Duration
FROM (
  SELECT s.customer_id, s.plan_id,
    LEAD(s.plan_id) OVER (PARTITION BY customer_id ORDER BY s.start_date) as next_plan_id,
    plan_name as current_plan,
    LEAD(plan_name) OVER (PARTITION BY customer_id ORDER BY s.start_date) as next_plan,
    s.start_date as current_plan_start_date,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY s.start_date) as next_plan_start_date
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
) a
WHERE plan_id <> 4;
```

### Customer Journey Insights

| Customer | Journey Summary | Insight | Segment |
|----------|----------------|---------|---------|
| **1** | Trial → Basic Monthly → Stayed | Risk-averse user who prefers stability at a lower tier once comfort is established. | Cautious Adopter |
| **2** | Trial → Pro Annual | Early commitment to an annual premium plan indicates high trust and decisiveness. | Confident/Decisive Adopter |
| **11** | Trial → Churn | Did not upgrade after trial, suggesting a gap between expectations and experienced value. | Churned Customer |
| **13** | Trial → Basic Monthly → Pro Monthly → Stayed | Gradual transition after evaluating value and cost-benefit shows cautious loyalty. | Cautious Adopter |
| **15** | Trial → Pro Monthly → Churn | Tried the premium plan but left early, likely due to mismatch between pricing and perceived benefits. | Churned Customer |
| **16** | Trial → Basic Monthly → Pro Annual → Stayed | Began cautiously and upgraded to annual premium after building trust and satisfaction. | Cautious Adopter |
| **18** | Trial → Pro Monthly → Stayed | Skipped entry-tier plan, reflecting confidence in premium features from the start. | Confident/Decisive Adopter |
| **19** | Trial → Pro Monthly → Pro Annual → Stayed | Positive experience with Pro Monthly led to full-year commitment—strong indicator of product confidence. | Confident/Decisive Adopter |

**Key Takeaways:**
- **Cautious Adopters** (Customers 1, 13, 16) need time and validation before committing to premium plans
- **Confident/Decisive Adopters** (Customers 2, 18, 19) skip entry-level plans and commit early to premium
- **Churned Customers** (Customers 11, 15) represent 25% of the sample—indicating retention challenges

---

## B. Data Exploration

### 1. Total Customer Count

**Query:**
```sql
SELECT COUNT(DISTINCT customer_id) as Customer_count
FROM subscriptions;
```

**Result:**
| Customer_count |
|----------------|
| 1,000          |

---

### 2. Monthly Distribution of Trial Plan Signups

**Query:**
```sql
SELECT month, COUNT(DISTINCT customer_id) as Trial_plan_count
FROM (
  SELECT DATE_FORMAT(start_date, '%Y-%m-01') as month, customer_id
  FROM subscriptions
  WHERE plan_id = 0
) a
GROUP BY month
ORDER BY month;
```

**Results:**
| Month | Trial_plan_count |
|-------|------------------|
| 2020-01 | 88 |
| 2020-02 | 68 |
| 2020-03 | 94 |
| 2020-04 | 81 |
| 2020-05 | 88 |
| 2020-06 | 79 |
| 2020-07 | 89 |
| 2020-08 | 88 |
| 2020-09 | 87 |
| 2020-10 | 79 |
| 2020-11 | 75 |
| 2020-12 | 84 |

**Insight:** Consistent monthly acquisition with slight dip in Q4, suggesting stable marketing efforts.

---

### 3. Plan Distribution After 2020

**Query:**
```sql
SELECT p.plan_name, COUNT(*) as Total_events
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY p.plan_name;
```

**Results:**
| plan_name | Total_events |
|-----------|--------------|
| basic monthly | 8 |
| churn | 71 |
| pro annual | 63 |
| pro monthly | 60 |

**Insight:** Post-2020 activity shows continued upgrades but also significant churn, indicating need for retention focus.

---

### 4. Overall Churn Rate

**Query:**
```sql
SELECT
  Total_customer_count,
  ROUND(Total_churned / Total_customer_count, 1) * 100 as Churned_Percentage
FROM (
  SELECT COUNT(DISTINCT customer_id) as Total_customer_count,
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) as Total_churned
  FROM subscriptions
) a;
```

**Results:**
| Total_customer_count | Churned_Percentage |
|----------------------|--------------------|
| 1,000 | 30.0% |

**Insight:** 30% churn rate indicates retention challenges, particularly among lower-tier plans.

---

### 5. Immediate Post-Trial Churn

**Query:**
```sql
WITH Total_customer AS (
  SELECT customer_id, plan_id,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id
  FROM subscriptions
)
SELECT COUNT(DISTINCT customer_id) as Total_churned_customer_count,
  ROUND(COUNT(DISTINCT customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) as immediate_churn_percentage
FROM Total_customer
WHERE plan_id = 0 AND next_plan_id = 4;
```

**Results:**
| Total_churned_customer_count | immediate_churn_percentage |
|------------------------------|----------------------------|
| 92 | 9% |

**Insight:** 9% of users churn immediately after trial—indicates onboarding or value communication issues.

---

### 6. Trial-to-Paid Conversion Rate

**Query:**
```sql
WITH Total_plan_customer AS (
  SELECT customer_id, plan_id,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id
  FROM subscriptions
)
SELECT COUNT(DISTINCT customer_id) as Total_plan_customers,
  ROUND(COUNT(DISTINCT customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) as Plan_customers_percentage
FROM total_plan_customer
WHERE plan_id = 0 AND next_plan_id <> 4;
```

**Results:**
| Total_plan_customers | Plan_customers_percentage |
|----------------------|---------------------------|
| 908 | 91% |

**Insight:** Strong 91% conversion rate from trial to paid plans demonstrates product-market fit.

---

### 7. Plan Distribution at End of 2020

**Query:**
```sql
WITH current_plan AS (
  SELECT customer_id, plan_id,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) as rn
  FROM subscriptions
  WHERE start_date <= '2020-12-31'
)
SELECT p.plan_name,
  COUNT(cp.customer_id) as Total_customers,
  ROUND(COUNT(cp.customer_id) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE start_date <= '2020-12-31'), 2) as percentage_customers
FROM current_plan cp
JOIN plans p ON cp.plan_id = p.plan_id
WHERE rn = 1
GROUP BY p.plan_name;
```

**Results:**
| plan_name | Total_customers | percentage_customers |
|-----------|-----------------|----------------------|
| basic monthly | 224 | 22.40% |
| churn | 236 | 23.60% |
| pro annual | 195 | 19.50% |
| pro monthly | 326 | 32.60% |
| trial | 19 | 1.90% |

**Insight:** Pro Monthly is the most popular plan, but significant churn (23.6%) suggests retention needs attention.

---

### 8. Annual Plan Upgrades in 2020

**Query:**
```sql
WITH plan_map_per_customer AS (
  SELECT customer_id, plan_id,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date
  FROM subscriptions
)
SELECT COUNT(DISTINCT customer_id) AS total_upgrades
FROM plan_map_per_customer
WHERE plan_id NOT IN (0,4)
  AND next_plan_id = 3
  AND next_start_date >= '2020-01-01'
  AND next_start_date < '2021-01-01';
```

**Results:**
| total_upgrades |
|----------------|
| 158 |

**Insight:** 158 customers upgraded to annual plan in 2020—strong indicator of customer satisfaction and commitment.

---

### 9. Average Time to Annual Plan Upgrade

**Query:**
```sql
WITH join_date AS (
  SELECT customer_id, start_date as Joining_date
  FROM subscriptions
  WHERE plan_id = 0
),
annual_updates AS (
  SELECT customer_id, MIN(start_date) as Annual_upgrade_date
  FROM subscriptions
  WHERE plan_id = 3
  GROUP BY customer_id
),
avg_per_customer AS (
  SELECT j.customer_id,
    DATEDIFF(au.Annual_upgrade_date, j.joining_date) as Avg_days_to_upgrade
  FROM join_date j
  JOIN annual_updates au ON j.customer_id = au.customer_id
)
SELECT ROUND(AVG(avg_days_to_upgrade), 0) as avg_days
FROM avg_per_customer;
```

**Results:**
| avg_days |
|----------|
| 105 |

**Insight:** Average of 105 days (3.5 months) to upgrade to annual plan—indicates optimal window for upselling.

---

### 10. Annual Upgrade Timeline Breakdown

**Query:**
```sql
WITH join_date AS (
  SELECT customer_id, start_date as Joining_date
  FROM subscriptions
  WHERE plan_id = 0
),
annual_updates AS (
  SELECT customer_id, MIN(start_date) as Annual_upgrade_date
  FROM subscriptions
  WHERE plan_id = 3
  GROUP BY customer_id
),
avg_per_customer AS (
  SELECT j.customer_id,
    DATEDIFF(au.Annual_upgrade_date, j.joining_date) as Avg_days_to_upgrade
  FROM join_date j
  JOIN annual_updates au ON j.customer_id = au.customer_id
),
buckets AS (
  SELECT *, FLOOR(avg_days_to_upgrade / 30) as bucket
  FROM avg_per_customer
)
SELECT
  CONCAT(bucket * 30 + 1, '-', (bucket + 1) * 30, ' days') as Days_Range,
  COUNT(*) AS Total_customers_Annual
FROM buckets
GROUP BY Bucket
ORDER BY Bucket;
```

**Results:**
| Days_Range | Total_customers_Annual |
|------------|------------------------|
| 1-30 days | 49 |
| 31-60 days | 24 |
| 61-90 days | 34 |
| 91-120 days | 35 |
| 121-150 days | 42 |
| 151-180 days | 36 |
| 181-210 days | 26 |
| 211-240 days | 4 |
| 241-270 days | 5 |
| 271-300 days | 1 |
| 301-330 days | 1 |
| 331-360 days | 1 |

**Insight:** Peak upgrade period is 90-180 days (113 customers)—this is the optimal window for targeted campaigns.

---

### 11. Pro Monthly to Basic Monthly Downgrades

**Query:**
```sql
WITH plan_map_per_customer AS (
  SELECT customer_id, plan_id,
    LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) as next_start_date
  FROM subscriptions
)
SELECT * FROM plan_map_per_customer
WHERE plan_id = 2 AND next_plan_id = 1
  AND next_start_date >= '2020-01-01' AND next_start_date < '2021-01-01';
```

**Results:** 
No results returned.

**Insight:** Zero downgrades from Pro Monthly to Basic Monthly indicates high satisfaction with premium tier—customers either stay or churn.

---

## C. Challenge Payment Question

### Payment Schedule Generation for 2020

**Requirements:**
1. Monthly payments occur on the same day of month as original start_date
2. Upgrades from basic to monthly/pro plans are prorated (reduced by current paid amount)
3. Upgrades from pro monthly to pro annual are paid at end of current billing period
4. Churned customers stop making payments

**Query:**
```sql
WITH RECURSIVE ORDER_SUBS AS (
  SELECT
    customer_id, plan_id, start_date,
    LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as prev_plan,
    LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) as next_start_date
  FROM subscriptions s
),
billing_details AS (
  -- First billing date for each subscription
  SELECT customer_id, plan_id,
    start_date as payment_date,
    prev_plan,
    next_start_date,
    CASE 
      WHEN plan_id IN (1,2) THEN 1  -- monthly interval
      WHEN plan_id = 3 THEN 12      -- annual interval
    END as billing_interval
  FROM order_subs
  WHERE plan_id <> 4
  
  UNION ALL
  
  -- Recursive records to add billing intervals
  SELECT customer_id, plan_id,
    DATE_ADD(payment_date, INTERVAL billing_interval MONTH),
    prev_plan,
    next_start_date,
    billing_interval
  FROM billing_details
  WHERE DATE_ADD(payment_date, INTERVAL billing_interval MONTH) < COALESCE(next_start_date, '2021-01-01')
)
SELECT b.customer_id,
  b.plan_id,
  p.plan_name,
  b.payment_date,
  CASE
    -- Basic → Pro upgrades: pay only difference on upgrade month
    WHEN b.prev_plan = 1
      AND b.payment_date = (SELECT start_date FROM subscriptions s 
                            WHERE s.customer_id = b.customer_id 
                            AND s.plan_id = b.plan_id LIMIT 1)
    THEN price - (SELECT price FROM plans WHERE plan_id = 1)
    ELSE price
  END as amount,
  ROW_NUMBER() OVER (PARTITION BY b.customer_id ORDER BY payment_date) as payment_order
FROM billing_details b
JOIN plans p ON b.plan_id = p.plan_id
ORDER BY customer_id, payment_date;
```

**Insight:** This recursive CTE generates payment schedules accounting for:
- Monthly billing cycles
- Prorated upgrade charges
- Plan transitions
- Churn cutoffs

---

## Strategic Recommendations

### 1. Retention Enhancement

**Priority: High**

**For Basic Monthly Users (22.4% of base):**
- Implement engagement scoring to identify at-risk customers
- Launch "premium feature preview" campaigns at 60-day mark
- Offer limited-time upgrade discounts before expected churn window

**For Pro Monthly Users (32.6% of base):**
- Create exclusive content drops to maintain engagement
- Highlight cost savings of annual plan at 90-day mark
- Build community features to increase stickiness

### 2. Optimal Upselling Window (Day 90-180)

**Priority: High**

**Tactics:**
- Automated email campaigns at day 90, 120, 150 with upgrade incentives
- In-app notifications highlighting annual plan savings
- Limited-time offers: "Upgrade to Pro Annual and save 20%"
- Success stories from annual plan users

### 3. Trial Experience Optimization

**Priority: Medium**

**Address 9% Immediate Churn:**
- Enhanced onboarding flow highlighting key features
- Personalized content recommendations during trial
- Day 3 and Day 6 engagement emails
- Exit surveys for trial churners to identify friction points

### 4. Customer Segmentation Strategy

**Cautious Adopters (40% of active users):**
- Gradual feature unlocks and education
- "Upgrade path" visualization showing progression benefits
- Monthly webinars or Q&A sessions

**Confident/Decisive Adopters (30% of active users):**
- Premium onboarding experience
- Early access to new features
- Referral program incentives

### 5. Predictive Analytics Implementation

**Priority: Medium-High**

**Build Models For:**
- Churn prediction (60-90 days before likely churn)
- Upgrade propensity scoring
- Content engagement patterns
- Lifetime value forecasting

### 6. Pricing Strategy Review

**Considerations:**
- Basic Monthly may be too low-priced (creating low-value customer segment)
- Pro Annual shows strong uptake—consider adding mid-tier annual option
- Test promotional pricing for annual plans during peak upgrade window

---

## Success Metrics to Track

### Primary KPIs
1. **Trial-to-Paid Conversion Rate** (Target: Maintain >90%)
2. **Churn Rate by Plan** (Target: Reduce overall to <25%)
3. **Time to Annual Upgrade** (Target: Reduce from 105 to 90 days)
4. **Monthly Recurring Revenue (MRR)** Growth
5. **Customer Lifetime Value (CLV)** by Segment

### Secondary Metrics
6. **90-Day Retention Rate** (Early engagement indicator)
7. **Annual Plan Conversion Rate** (From monthly plans)
8. **Reactivation Rate** (Churned customers returning)
9. **Net Promoter Score (NPS)** by Plan Type
10. **Content Engagement Scores** (Correlation with retention)

---

## Conclusion

Foodie-Fi demonstrates a healthy subscription foundation with strong conversion from free trials and steady acquisition momentum. Customers show high satisfaction with premium tiers, evidenced by **zero downgrades from Pro to Basic**, and most upgrades occurring between **3-6 months** after joining.

However, a **30% overall churn rate** suggests that while the product attracts interest, sustained engagement post-conversion remains a challenge. The **Basic Monthly segment** likely contributes the most to this churn, as these customers are more price-sensitive and less committed.

The **upgrade momentum** within 90-180 days highlights a natural engagement window where customers perceive maximum value, beyond which upgrade intent and engagement taper off.

### Next Steps

1. **Retention Deep Dive**: Conduct churn analysis segmented by plan and tenure to pinpoint disengagement triggers
2. **Mid-Lifecycle Engagement**: Launch personalized campaigns during the 90-150 day high-conversion window
3. **Trial Optimization**: Enhance onboarding experience to reduce 9% immediate post-trial churn
4. **Predictive Analytics**: Use historical behavior to predict and prevent churn proactively
5. **Sustained Growth**: Maintain steady acquisition while improving retention to compound recurring revenue

By focusing on these strategic priorities, Foodie-Fi can reduce churn, accelerate upgrades, and build a more sustainable subscription business model.

---

*For questions or additional analysis, please contact Prashant*