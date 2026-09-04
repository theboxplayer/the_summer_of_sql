--Pizza Runner Part A (https://8weeksqlchallenge.com/case-study-2/), as part of https://github.com/wjsutton/the_summer_of_sql

select * from runners;
select * from customer_orders; --exclusions and extras columns to be cleaned up
select * from runner_orders;

------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
/*
A. Pizza Metrics

1 How many pizzas were ordered?
2 How many unique customer orders were made?
3 How many successful orders were delivered by each runner?
4 How many of each type of pizza was delivered?
5 How many Vegetarian and Meatlovers were ordered by each customer?
6 What was the maximum number of pizzas delivered in a single order?
7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8 How many pizzas were delivered that had both exclusions and extras?
9 What was the total volume of pizzas ordered for each hour of the day?
10 What was the volume of orders for each day of the week?
*/

--1 How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM customer_orders; --14 pizzas

--2 How many unique customer orders were made?
SELECT * FROM customer_orders;
SELECT COUNT(DISTINCT order_id) FROM customer_orders; --10 unique orders

--3 How many successful orders were delivered by each runner?

SELECT * 
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
ON co.order_id = ro.order_id
--NULL pickup times are not successful deliveries
WHERE pickup_time <> 'null';
--this shows us all the rows, now aggregate the number of unique orders for each runner

SELECT
runner_id
, COUNT(DISTINCT ro.order_id) as num_orders
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
ON co.order_id = ro.order_id
WHERE pickup_time <> 'null'
GROUP BY runner_id;

/*
runner_id	num_orders
1	4
2	3
3	1
*/

--But it looks like maybe we don't need the customer orders table at all
SELECT
runner_id
, COUNT(DISTINCT order_id) as num_orders
--FROM customer_orders AS co
--LEFT JOIN runner_orders AS ro
FROM runner_orders
--ON co.order_id = ro.order_id
WHERE pickup_time <> 'null'
GROUP BY runner_id;
--we get the same answer


--4 How many of each type of pizza was delivered?
--get successful deliveries first (Q3)
SELECT * 
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
ON co.order_id = ro.order_id
--NULL pickup times are not successful deliveries
WHERE pickup_time <> 'null';

SELECT
x.pizza_id
, COUNT(*) as num_ordered
, pn.pizza_name
FROM
(
SELECT
co.order_id
, customer_id
, pizza_id
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
ON co.order_id = ro.order_id
--NULL pickup times are not successful deliveries
WHERE pickup_time <> 'null'
) X
LEFT JOIN pizza_names pn ON x.pizza_id = pn.pizza_id
GROUP BY
x.pizza_id
, pn.pizza_name;

/*
pizza_id	num_ordered	pizza_name
1	9	Meatlovers
2	3	Vegetarian
*/

--5 How many Vegetarian and Meatlovers were ordered by each customer?
select * from customer_orders;

select customer_id
--, co.pizza_id
, pn.pizza_name
, count(*) as num_pizzas
from customer_orders co left join pizza_names pn on co.pizza_id = pn.pizza_id
group by customer_id, co.pizza_id, pn.pizza_name
order by customer_id, co.pizza_id, pn.pizza_name

/*
customer_id	pizza_name	num_pizzas
101	Meatlovers	2
101	Vegetarian	1
102	Meatlovers	2
102	Vegetarian	1
103	Meatlovers	3
103	Vegetarian	1
104	Meatlovers	3
105	Vegetarian	1
*/

--6 What was the maximum number of pizzas delivered in a single order?

select * from customer_orders; --exclusions and extras columns to be cleaned up
select * from runner_orders;


SELECT
co.order_id
, count(*)
FROM customer_orders AS co
LEFT JOIN runner_orders AS ro
ON co.order_id = ro.order_id
--NULL pickup times are not successful deliveries
WHERE pickup_time <> 'null'
group by co.order_id
order by count(*) desc;
--order number 4 had 3 pizzas delivered successfully, the highest number of pizzas

--7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

with cte as (
select 
co.order_id as co_orderid
, co.customer_id as co_customerid
, exclusions
, case when 
	co.exclusions = 'null' or 
	co.exclusions = '' 
	THEN 'N' ELSE 'Y' end as 'exclusion_YN'
, extras
, case when 
	co.extras IS NULL or 
	co.extras = '' or
	co.extras = 'null'
	THEN 'N' ELSE 'Y' end as 'extras_YN'
, case when
	(co.exclusions = 'null' or 
	co.exclusions = '') 
	and
	(co.extras IS NULL or 
	co.extras = '' or
	co.extras = 'null')
	THEN 'N' ELSE 'Y' end as changes_YN
from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
where pickup_time <> 'null'
)
select 
co_customerid
--, exclusion_YN
--, extras_YN
, changes_YN
, count(*) as num_pizzas
from cte
group by 
co_customerid
--, exclusion_YN
--, extras_YN
, changes_YN;

/*
co_customerid	changes_YN	num_pizzas
101	N	2
102	N	3
103	Y	3
104	N	1
104	Y	2
105	Y	1
*/

--8 How many pizzas were delivered that had both exclusions and extras?

with cte as (
select 
co.order_id as co_orderid
, co.customer_id as co_customerid
, exclusions
, case when 
	co.exclusions = 'null' or 
	co.exclusions = '' 
	THEN 'N' ELSE 'Y' end as 'exclusion_YN'
, extras
, case when 
	co.extras IS NULL or 
	co.extras = '' or
	co.extras = 'null'
	THEN 'N' ELSE 'Y' end as 'extras_YN'
, case when
	(co.exclusions = 'null' or 
	co.exclusions = '') 
	and
	(co.extras IS NULL or 
	co.extras = '' or
	co.extras = 'null')
	THEN 'N' ELSE 'Y' end as changes_YN
from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
where pickup_time <> 'null'
)
select 
co_customerid
, exclusion_YN
, extras_YN
, changes_YN
, count(*) as num_pizzas
from cte
where exclusion_YN = 'Y' and extras_YN = 'Y'
group by 
co_customerid
, exclusion_YN
, extras_YN
, changes_YN;

--there's only 1 pizza that was delievered and had both exclusions and extras!
/*
co_customerid	exclusion_YN	extras_YN	changes_YN	num_pizzas
104	Y	Y	Y	1
*/

--9 What was the total volume of pizzas ordered for each hour of the day?

select * from customer_orders;
select * from runner_orders;

select 
DATEPART(hour, order_time) as hr
, count(*) as num_orders
from customer_orders
group by DATEPART(hour, order_time)
order by DATEPART(hour, order_time)


/* by hour only (no date)
hr	num_orders
11	1
13	3
18	3
19	1
21	3
23	3
*/

--10 What was the volume of orders for each day of the week?
select 
DATENAME(weekday, order_time) as day_of_wk
, DATEPART(weekday, order_time) as day_of_wk_num
, count(*) as num_orders
from customer_orders
group by 
DATENAME(weekday, order_time)
, DATEPART(weekday, order_time)
order by 
DATEPART(weekday, order_time) --sort the days of the week


/*
day_of_wk	day_of_wk_num	num_orders
Wednesday	4	5
Thursday	5	3
Friday	6	1
Saturday	7	5
*/
