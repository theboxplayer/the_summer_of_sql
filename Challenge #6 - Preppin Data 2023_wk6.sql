/*
Using PostgreSQL

Challenge source: 
https://preppindata.blogspot.com/2023/02/2023-week-6-dsb-customer-ratings.html
*/


select count(*) from pd2023_wk06; --768
select * from pd2023_wk06;
select count(distinct customer_id) from pd2023_wk06; --768 unique customers, 1 row per customer

/*
REQUIREMENTS

- Reshape the data so we have 5 rows for each customer, with responses for the Mobile App and Online Interface being in separate fields on the same row
- Clean the question categories so they don't have the platform in from of them
	- e.g. Mobile App - Ease of Use should be simply Ease of Use
- Exclude the Overall Ratings, these were incorrectly calculated by the system
- Calculate the Average Ratings for each platform for each customer 
- Calculate the difference in Average Rating between Mobile App and Online Interface for each customer
- Catergorise customers as being:
	- Mobile App Superfans if the difference is greater than or equal to 2 in the Mobile App's favour
	- Mobile App Fans if difference >= 1
	- Online Interface Fan
	- Online Interface Superfan
	- Neutral if difference is between 0 and 1
- Calculate the Percent of Total customers in each category, rounded to 1 decimal place
*/

with mobile_app as (
SELECT customer_id,
       'ease_of_use' AS metric_name,
       mobile_app_ease_of_use AS mobile_app
FROM pd2023_wk06
UNION ALL
SELECT customer_id,
       'ease_of_access' AS metric_name, 
       mobile_app_ease_of_access AS mobile_app
FROM pd2023_wk06
union all
select customer_id,
	'navigation' as metric_name,
	mobile_app_navigation as mobile_app
from pd2023_wk06

union all
select customer_id,
	'likelihood_to_recommend' as metric_name,
	mobile_app_likelihood_to_recommend as mobile_app
from pd2023_wk06

union all
select customer_id,
	'overall_rating' as metric_name,
	mobile_app_overall_rating as mobile_app
from pd2023_wk06
order by customer_id
),
----------------------------------
online_interface as (
SELECT customer_id,
       'ease_of_use' AS metric_name,
       online_interface_ease_of_use AS online_interface
FROM pd2023_wk06
UNION ALL
SELECT customer_id,
       'ease_of_access' AS metric_name, 
       online_interface_ease_of_access AS online_interface
FROM pd2023_wk06
union all
select customer_id,
	'navigation' as metric_name,
	online_interface_navigation as online_interface
from pd2023_wk06

union all
select customer_id,
	'likelihood_to_recommend' as metric_name,
	online_interface_likelihood_to_recommend as online_interface
from pd2023_wk06

union all
select customer_id,
	'overall_rating' as metric_name,
	online_interface_overall_rating as online_interface
from pd2023_wk06
order by customer_id
),
----------------------------------
customer_categories as(
select
ma.customer_id
, AVG(mobile_app) as avg_rating_mobile_app
, AVG(online_interface) as avg_rating_online_interface
, (AVG(mobile_app) - AVG(online_interface)) as diff
, case when (AVG(mobile_app) - AVG(online_interface)) >=2 then 'Mobile App Superfans'
	when (AVG(mobile_app) - AVG(online_interface)) >=1 then 'Mobile App Fans'
	when (AVG(mobile_app) - AVG(online_interface)) <=-2 then 'Online Interface Superfans'
	when (AVG(mobile_app) - AVG(online_interface)) <=-1 then 'Online Interface Fans'
	else 'Neutral'
end as in_favor_of
from mobile_app as ma inner join online_interface as oi
on ma.customer_id = oi.customer_id and ma.metric_name = oi.metric_name
where ma.metric_name not like '%overall%'
group by ma.customer_id
order by customer_id
)
select in_favor_of
, count(customer_id) as num_cust
, (select count(customer_id) from customer_categories) as total_cust
, (count(customer_id)::float / (select count(customer_id) from customer_categories)) as percent_of_total_cust
, (count(customer_id)*100.0 / (select count(customer_id) from customer_categories)) as pct_of_total_cust
, round((count(customer_id)*100.0 / (select count(customer_id) from customer_categories)),1) as pct2_of_total_cust
from customer_categories
group by in_favor_of;
