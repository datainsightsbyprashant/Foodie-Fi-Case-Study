use foodie_fi;

-- -----------------------------------------A. Customer Journey-----------------------------------------------------
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run 
-- some sort of join to make your explanations a bit easier!

Select customer_id,current_plan,next_plan,current_plan_start_date,next_plan_start_date,
Case 
	when next_plan is null then 'Ongoing Plan'
	when next_plan_id = 4 then 'Churn'
	when next_plan_id<plan_id  then 'Downgrade' 
	when next_plan_id>plan_id then 'Upgrade' 
end as Plan_category,
case 
	when next_plan is null then datediff('2021-04-30',current_plan_start_date)+1
	else Datediff(next_plan_start_date,current_plan_start_date)
end as Duration
from
(
Select s.customer_id,s.plan_id,
LEAD(s.plan_id) over (partition by customer_id order by s.start_date) as next_plan_id,
plan_name as current_plan,
LEAD(plan_name) over (partition by customer_id order by s.start_date) as next_plan,
s.start_date as current_plan_start_date,
LEAD(start_date) over (partition by customer_id order by s.start_date) as next_plan_start_date
from subscriptions s
JOIN plans p on s.plan_id=p.plan_id
where s.customer_id in (1,2,11,13,15,16,18,19)
) a
where plan_id<>4;

-- -----------------------------------------------------------------------------------------------------------------

-- -----------------------------------------B. Data Exploration-----------------------------------------------------

-- How many customers has Foodie-Fi ever had?

Select count(distinct customer_id) as Customer_count
from subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - 
-- use the start of the month as the group by value

Select month, count(distinct customer_id) as Trial_plan_count
from
(
	Select date_format(start_date,'%Y-%m-01') as month, customer_id 
	from subscriptions
	where plan_id=0
) a
group by month
order by month;

-- What plan start_date values occur after the year 2020 for our dataset? 
-- Show the breakdown by count of events for each plan_name

Select p.plan_name, count(*) as Total_events
from subscriptions s
join plans p on s.plan_id=p.plan_id
where s.start_date>'2020-12-31'
group by p.plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

Select Total_customer_count,Round(Total_churned/Total_customer_count,1)*100 as Churned_Percentage
from
(
Select count(distinct customer_id) as Total_customer_count,
sum(case when plan_id=4 then 1 else 0 end) as Total_churned
from subscriptions
) a;

-- How many customers have churned straight after their initial free trial - 
-- what percentage is this rounded to the nearest whole number?

With Total_customer
as
(
Select customer_id,plan_id,
lead(plan_id) over (partition by customer_id order by start_date) as next_plan_id
from subscriptions
)

Select count(distinct customer_id) as Total_churned_customer_count,
Round(count(distinct customer_id)*100/(Select count(distinct customer_id) from subscriptions),0) as immediate_churn_percentage
from Total_customer
where plan_id=0
and next_plan_id=4;

-- What is the number and percentage of customer plans after their initial free trial?

with Total_plan_customer
as
(
SELECT customer_id,plan_id,
lead(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id
from subscriptions
)

Select count(distinct customer_id) as Total_plan_customers,
ROUND(COUNT(DISTINCT customer_id)*100/(Select count(distinct customer_id) from subscriptions),0) as 
Plan_customers_percentage
from total_plan_customer
where plan_id=0
and next_plan_id <> 4;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

with current_plan
as
(
Select customer_id, plan_id,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date desc) 
as rn
from subscriptions
where start_date<='2020-12-31'
)

Select p.plan_name,
count(cp.customer_id) as Total_customers,
round(count(cp.customer_id)*100/(Select count(distinct customer_id) from subscriptions where start_date<='2020-12-31'),2) as percentage_customers
from current_plan cp
join plans p on cp.plan_id=p.plan_id
where rn=1
GROUP BY p.plan_name;

-- How many customers have upgraded to an annual plan in 2020?
-- Counting all customers who at any point upgraded to an annual plan in 2020, regardless of later downgrades or churn

WITH plan_map_per_customer AS (
  SELECT 
    customer_id,
    plan_id,
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

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with join_date as
(
SELECT customer_id,start_date as Joining_date
FROM subscriptions
WHERE plan_id=0
)

,annual_updates as
(
SELECT customer_id,MIN(start_date) as Annual_upgrade_date
from subscriptions
where plan_id=3
GROUP BY customer_id
)

,avg_per_customer as
(
SELECT j.customer_id, 
DATEDIFF(au.Annual_upgrade_date,j.joining_date) as Avg_days_to_upgrade
From join_date j
join annual_updates au on j.customer_id=au.customer_id
)

Select round(Avg(avg_days_to_upgrade),0) as Avg_days_to_upgrade
from avg_per_customer;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with join_date as
(
	SELECT customer_id,start_date as Joining_date
	FROM subscriptions
	WHERE plan_id=0
)

,annual_updates as
(
	SELECT customer_id,MIN(start_date) as Annual_upgrade_date
	from subscriptions
	where plan_id=3
	GROUP BY customer_id
)

,avg_per_customer as
(
	SELECT j.customer_id, 
	DATEDIFF(au.Annual_upgrade_date,j.joining_date) as Avg_days_to_upgrade
	From join_date j
	join annual_updates au on j.customer_id=au.customer_id
)

,buckets as
(
	SELECT *, FLOOR(avg_days_to_upgrade/30) as bucket
	from avg_per_customer
)

Select 
CONCAT(bucket*30+1,'-',(bucket+1)*30,' days') as Days_Range,
count(*) AS Total_customers_Annual
from buckets
GROUP BY Bucket
ORDER BY Bucket;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with plan_map_per_customer
as
(
SELECT customer_id,plan_id,
lead(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as next_plan_id,
lead(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) as next_start_date
from subscriptions
)

SELECT * FROM plan_map_per_customer
WHERE plan_id=2 and next_plan_id=1
and next_start_date >= '2020-01-01' and next_start_date<'2021-01-01';

-- -----------------------------------------------------------------------------------------------------------------

-- ------------------------------------------C. Challenge Payment Question------------------------------------------
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 
-- that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- 1) monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- 2) upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and 
--    start immediately

-- 3) upgrades from pro monthly to pro annual are paid at the end of the current billing period 
--    and also starts at the end of the month period
-- 4) once a customer churns they will no longer make payments

WITH RECURSIVE ORDER_SUBS AS
(
	SELECT 
	customer_id, 
	plan_id,
	start_date,
	lag(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) as prev_plan,
	LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) as next_start_date
	FROM subscriptions s
)
,billing_details as 
		-- first billing date for each subscription
(
	SELECT customer_id,
	plan_id, 
	start_date as payment_date,
	prev_plan,
	next_start_date,
	case when plan_id in (1,2) then 1   -- monthly interval for plans 1 and 2
	when plan_id =3 then 12 			-- annual interval for plan 3
    end as billing_interval
	from order_subs
	where plan_id<>4

	UNION ALL
		-- recursive records to add interval per plan
	SELECT customer_id,
	plan_id, 
	date_add(payment_date, interval billing_interval month), -- adding respective intervals
	prev_plan,
	next_start_date,
	billing_interval
	from billing_details
	where date_add(payment_date,interval billing_interval month)<coalesce(next_start_date,'2021-01-01') 
		-- condition to stop the recursion if it finds next plan start date going beyond year 2020
        -- require payment details for 2020 only
)

SELECT b.customer_id,
b.plan_id, 
p.plan_name,
b.payment_date,			
CASE 	
	-- basic → pro upgrades: pay only difference on the upgrade month
	WHEN b.prev_plan=1 and b.payment_date=(SELECT start_date from subscriptions s
										where s.customer_id=b.customer_id and s.plan_id=b.plan_id
                                        LIMIT 1)
	THEN price-(SELECT price from plans where plan_id=1)		-- upgrade from plan 1, differential amount calculation
    else price 													-- Pricing as per billing cycle, for rest of plans
end as amount,
ROW_NUMBER() OVER (PARTITION BY b.CUSTOMER_ID ORDER BY payment_date) as payment_order -- payment sequence generation
from billing_details b
join plans p on b.plan_id=p.plan_id
ORDER BY customer_id, payment_date;


