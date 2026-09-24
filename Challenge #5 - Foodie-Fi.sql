/*
This challenge comes from https://8weeksqlchallenge.com/case-study-3/ as part of https://github.com/wjsutton/the_summer_of_sql
Parts A and B only
Used PostgreSQL / DBeaver
*/

/*A. Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
*/

select * from foodie_fi.subscriptions;
select * from foodie_fi.plans;

select * from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
order by customer_id, start_date;
/*
 Customer Journey of first 8 customers
 Customer 1 = had 7 days of free trial, downgraded to basic, still on basic
 Customer 2 = had 7 days of free trial, upgraded to pro annual, still on pro annual
 Customer 3 = had 7 days of free trial, downgraded to basic, still on basic
 Customer 4 = had 7 days of free trial, downgraded to basic, then cancelled about 3 mos later
 Customer 5 = had 7 days of free trial, downgraded to basic, still on basic
 Customer 6 = had 7 days of free trial, downgraded to basic, then cancelled about 14 mos later
 Customer 7 = had 7 days of free trial, downgraded to basic, then upgraded to pro monthly 3 mos later, still on pro monthly
 Customer 8 = had 7 days of free trial, downgraded to basic, then upgraded to pro monthly 2 mos later, still on pro monthly
 * */


/*B. Data Analysis Questions

1 How many customers has Foodie-Fi ever had?
2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
6 What is the number and percentage of customer plans after their initial free trial?
7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
8 How many customers have upgraded to an annual plan in 2020?
9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?*/

--1 How many customers has Foodie-Fi ever had?
select count(distinct customer_id) from subscriptions; 
--1,000 customers all-time

--2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select * from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
order by customer_id, start_date;

select
start_date
, to_char(start_date::date, 'Month') as mnth
, extract(year from start_date) as yr
, extract(month from start_date) as month
, concat(
	cast(extract(year from start_date) as text), ' - ', cast(extract(month from start_date) as text)
) as yr_month
from subscriptions;

select 
extract(year from start_date) as yr
, extract(month from start_date) as month
, count(distinct customer_id) as trials_started
from
subscriptions
where plan_id = 0
group by
extract(year from start_date)
, extract(month from start_date);

/*
 yr  |month|trials_started|
----+-----+--------------+
2020|    1|            88|
2020|    2|            68|
2020|    3|            94|
2020|    4|            81|
2020|    5|            88|
2020|    6|            79|
2020|    7|            89|
2020|    8|            88|
2020|    9|            87|
2020|   10|            79|
2020|   11|            75|
2020|   12|            84|
*/

--3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select
p.plan_name
--, extract(year from s.start_date) as year
, count(*) as number_of_events
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
where extract(year from start_date) > 2020
group by
p.plan_name
, extract(year from s.start_date)
order by count(*) desc;

/*Remaining items happened during 2021, so no need to put a year in the group by

plan_name    |number_of_events|
-------------+----------------+
churn        |              71|
pro annual   |              63|
pro monthly  |              60|
basic monthly|               8|

*/

-- 4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

-- This analysis assumes that once the customer churns, they don't return

select 
(select count(distinct customer_id) as num_customers from subscriptions)
, *
from subscriptions;
--get the 1K customers in a column all the way down first using a sub-query


with cte as ( --take the query above and make a CTE so we can select from it
	select 
	(select count(distinct customer_id) as num_customers from subscriptions)
	, *
	from subscriptions
)
select
num_customers
, count(distinct customer_id) as churned_cust
, round((cast(count(distinct customer_id) as decimal) / num_customers) *100, 1)  as churn_rate_percent
from cte
where plan_id = 4 --this is the churn id
group by num_customers;

/*
num_customers|churned_cust|churn_rate_percent|
-------------+------------+------------------+
         1000|         307|              30.7|
*/


-- 5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
select * 
, ROW_NUMBER() OVER(partition by customer_id order by start_date asc) as row_num
, (select count(distinct customer_id) as num_customers from subscriptions) as total_cust
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
order by 
customer_id, 
ROW_NUMBER() OVER(partition by customer_id order by start_date asc);
--put the records in order for each customer by start date earliest to latest
--if row number 2 is a churn then that's who we're interested in

with cte as (
select * 
, ROW_NUMBER() OVER(partition by customer_id order by start_date asc) as row_num
, (select count(distinct customer_id) as num_customers from subscriptions) as total_cust
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
)
select 
total_cust
, count(distinct customer_id) as churned_after_trial
, round((cast(count(distinct customer_id) as decimal) / total_cust) *100, 1)  as churn_after_trial_rate_percent
from cte 
where row_num = 2 and plan_name = 'churn'
group by total_cust;
/*
total_cust|churned_after_trial|churn_after_trial_rate_percent|
----------+-------------------+------------------------------+
      1000|                 92|                           9.2|
*/

-- 6 What is the number and percentage of customer plans after their initial free trial?

-- Said another way, what did customers do after the trial?

-- Confirm that all customers started with the trial plan id = 0
select count(distinct customer_id) from subscriptions where plan_id = 0;
--1K so yes

with cte as(
select * 
, ROW_NUMBER() OVER(partition by customer_id order by start_date asc) as row_num
, (select count(distinct customer_id) as num_customers from subscriptions) as total_cust
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
)
select 
plan_name
, count(*) as num_rec
, count(distinct customer_id) as num_cust
, (select count(distinct customer_id) from cte) as total_cust
, round((cast(count(distinct customer_id) as decimal) / (select count(distinct customer_id) from cte)) *100, 1)  as plan_after_trial_percent
from cte 
where row_num = 2
group by plan_name
order by count(*) desc;
/*
plan_name    |num_rec|num_cust|total_cust|plan_after_trial_percent|
-------------+-------+--------+----------+------------------------+
basic monthly|    546|     546|      1000|                    54.6|
pro monthly  |    325|     325|      1000|                    32.5|
churn        |     92|      92|      1000|                     9.2|
pro annual   |     37|      37|      1000|                     3.7|
*/

--7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cte as (
select * 
, ROW_NUMBER() OVER(partition by customer_id order by start_date desc) as row_num --note the change to descending order, then keep the 1s so we have most recent activity
, (select count(distinct customer_id) as num_customers from subscriptions) as total_cust
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
where extract(year from start_date) < 2021
)
select
plan_name
, count(*) as num_rec
, count(distinct customer_id) as num_cust
, (select count(distinct customer_id) from cte) as total_cust
, round((cast(count(distinct customer_id) as decimal) / (select count(distinct customer_id) from cte)) *100, 1)  as percent_of_cust_end2020
from cte
where row_num = 1
group by plan_name
order by count(*) desc;
/*
plan_name    |num_rec|num_cust|total_cust|percent_of_cust_end2020|
-------------+-------+--------+----------+-----------------------+
pro monthly  |    326|     326|      1000|                   32.6|
churn        |    236|     236|      1000|                   23.6|
basic monthly|    224|     224|      1000|                   22.4|
pro annual   |    195|     195|      1000|                   19.5|
trial        |     19|      19|      1000|                    1.9|
*/

--8 How many customers have upgraded to an annual plan in 2020?

with cte as (
select * 
from foodie_fi.subscriptions as s left join foodie_fi.plans as p
on s.plan_id = p.plan_id
where extract(year from start_date) = 2020
)
select
count(distinct customer_id) as cust_upgraded
from
cte
where plan_name = 'pro annual';
/*
 * cust_upgraded|
-------------+
          195|
*/

--9 How many days on average does it take for a customer to [go from their trial to] an annual plan from the day they join Foodie-Fi?

with trial_start as (
select
customer_id as trial_custid
, plan_id as trial_planid
, start_date as trial_start
from subscriptions
where plan_id = 0
group by 
customer_id
, plan_id
, start_date
),
pro_annual as (
select
customer_id as pro_custid
, plan_id as pro_planid
, start_date as annual_start
from subscriptions
where plan_id = 3
)
select
--trial_custid as custid
--, trial_start
--, annual_start
--, (annual_start-trial_start) as day_diff
round(avg(annual_start-trial_start)) as avg_days_trial_to_annual
from 
trial_start inner join pro_annual on trial_custid = pro_custid;
/*
avg_days_trial_to_annual|
------------------------+
                     105|
*/

--10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with trial_start as (
select
customer_id as trial_custid
, plan_id as trial_planid
, start_date as trial_start
from subscriptions
where plan_id = 0
group by 
customer_id
, plan_id
, start_date
),
pro_annual as (
select
customer_id as pro_custid
, plan_id as pro_planid
, start_date as annual_start
from subscriptions
where plan_id = 3
)
select
--trial_custid as custid
--, trial_start
--, annual_start
--, (annual_start-trial_start) as day_diff
case
		when (annual_start-trial_start) <=30 then '0-30'
		when (annual_start-trial_start) <=60 then '31-60'
		when (annual_start-trial_start) <=90 then '61-90'
		when (annual_start-trial_start) <=120 then '91-120'
		when (annual_start-trial_start) <=150 then '121-150'
		when (annual_start-trial_start) <=180 then '151-180'
		when (annual_start-trial_start) <=210 then '181-210'
		when (annual_start-trial_start) <=240 then '211-240'
		when (annual_start-trial_start) <=270 then '241-270'
		when (annual_start-trial_start) <=300 then '271-300'
		when (annual_start-trial_start) <=330 then '301-330'
		when (annual_start-trial_start) <=360 then '331-360'
		when (annual_start-trial_start) <=390 then '361-390'
		--assuming 390 is sufficient
end as bin
, count(trial_custid) as customer_count
from 
trial_start inner join pro_annual on trial_custid = pro_custid
group by 1;

/*
bin    |customer_count|
-------+--------------+
0-30   |            49|
121-150|            42|
151-180|            36|
181-210|            26|
211-240|             4|
241-270|             5|
271-300|             1|
301-330|             1|
31-60  |            24|
331-360|             1|
61-90  |            34|
91-120 |            35|
*/



--11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with pro_monthly as (
select
customer_id as pm_custid
, start_date as pm_startdate
, plan_id as pm_planid
from
subscriptions
where plan_id = 2
),
basic_monthly as (
select
customer_id as bm_custid
, start_date as bm_startdate
, plan_id as bm_planid
from
subscriptions
where plan_id = 1
)
select 
*
from pro_monthly inner join basic_monthly on pm_custid = bm_custid
where pm_startdate < bm_startdate -- pro monthly happening BEFORE basic would give us the records that downgraded
--at this point we get the answer that there was no one who downgraded, but the question asks about "during 2020"
and date_part('year', bm_startdate) = 2020;

--no results, meaning nobody downgraded from PM to Basic during 2020.
