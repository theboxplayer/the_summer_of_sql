--Pizza Runner Part B (https://8weeksqlchallenge.com/case-study-2/), as part of https://github.com/wjsutton/the_summer_of_sql

/*
Runner and Customer Experience

1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
4 What was the average distance travelled for each customer?
5 What was the difference between the longest and shortest delivery times for all orders?
6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
7 What is the successful delivery percentage for each runner?

*/

--1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select * from runners;

select 
datepart(week, registration_date) as wk_num
, count(runner_id) as num_runners
from runners
group by
datepart(week, registration_date) 
/*
wk_num	num_runners
1	1
2	2
3	1
*/

--2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

with cte as (
select
distinct x.co_orderid
, AVG(timediff) as timediff
from
--subquery to get the difference between the two timestamps
	(
	select
	co.order_id as co_orderid
	, co.order_time as co_ordertime
	, ro.order_id as ro_orderid
	, ro.pickup_time as ro_pickuptime
	, ro.runner_id
	, datediff(minute, try_convert(datetime, co.order_time), try_convert(datetime, ro.pickup_time)) as timediff
	from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
	where ro.pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
) as x
group by x.co_orderid
) --end of cte
select
AVG(timediff)
from cte

/* the below gives us the mins per order, the get the average of this 128/10 = 16mins
co_orderid	timediff
1	10
2	10
3	21
4	30
5	10
7	10
8	21
10	16

(No column name)
16
*/

--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
select * from customer_orders;
select * from runner_orders;


with cte as (
select
co.order_id as co_orderid
, co.order_time as co_ordertime
, ro.order_id as ro_orderid
, ro.pickup_time as ro_pickuptime
, ro.runner_id
, datediff(minute, try_convert(datetime, co.order_time), try_convert(datetime, ro.pickup_time)) as timediff
from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
where ro.pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
)
select
co_orderid
, count(*) as num_pizzas
, min(timediff) as time_to_prepare
from cte
group by
co_orderid
order by count(*) asc;

/* the time increases with the number of pizzas ordered
co_orderid	num_pizzas	time_to_prepare
1	1	10
2	1	10
5	1	10
7	1	10
8	1	21
10	2	16
3	2	21
4	3	30
*/

with cte as(
select 
distinct x.co_orderid
, count(*) as num_pizzas
, min(timediff) as prep_time
from
	(
	select
	co.order_id as co_orderid
	, co.order_time as co_ordertime
	, ro.order_id as ro_orderid
	, ro.pickup_time as ro_pickuptime
	, ro.runner_id
	, datediff(minute, try_convert(datetime, co.order_time), try_convert(datetime, ro.pickup_time)) as timediff
	from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
	where ro.pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
	) as X
group by x.co_orderid
)
select
num_pizzas
, avg(prep_time) as avg_prep_time
from cte
group by num_pizzas

/* could also be summarized like this
num_pizzas	avg_prep_time
1	12
2	18
3	30
*/


--4 What was the average distance travelled for each customer?
select * from customer_orders;
select * from runner_orders;


select
distinct x.co_custid --did this way because the dist is always the same for each customer
, convert(float(1), replace(x.distance, 'km', '')) as distance
from
	(
	select
	co.order_id as co_orderid
	, co.customer_id as co_custid
	, co.order_time as co_ordertime
	, ro.order_id as ro_orderid
	, ro.pickup_time as ro_pickuptime
	, ro.runner_id
	, ro.distance
	, datediff(minute, try_convert(datetime, co.order_time), try_convert(datetime, ro.pickup_time)) as timediff
	from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
	where ro.pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
	) x

/*
co_custid	distance
101	20
102	13.4
102	23.4
103	23.4
104	10
105	25
*/

select
x.co_custid 
, avg(convert(float(1), replace(x.distance, 'km', ''))) as distance --do this way if somehow you had different distances for a given customer, maybe they order from different locations from time to time
from
	(
	select
	co.order_id as co_orderid
	, co.customer_id as co_custid
	, co.order_time as co_ordertime
	, ro.order_id as ro_orderid
	, ro.pickup_time as ro_pickuptime
	, ro.runner_id
	, ro.distance
	, datediff(minute, try_convert(datetime, co.order_time), try_convert(datetime, ro.pickup_time)) as timediff
	from customer_orders co left join runner_orders ro on co.order_id = ro.order_id
	where ro.pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
	) x
group by x.co_custid 
/*
co_custid	distance
101	20
102	16.7333329518636
103	23.3999996185303
104	10
105	25
*/

--5 What was the difference between the longest and shortest delivery times for all orders?

select * from customer_orders;
select * from runner_orders; --there are two that were cancelled... 10 rows but only 8 delivered
select duration from runner_orders; --to test the column on regex 101

select	
duration
, REGEXP_REPLACE(duration,'[^0-9]','') as duration_clean
, convert(float(1), MAX(REGEXP_REPLACE(duration,'[^0-9]',''))) as duration_max
, convert(float(1), MIN(REGEXP_REPLACE(duration,'[^0-9]',''))) as duration_min
, convert(float(1), MAX(REGEXP_REPLACE(duration,'[^0-9]',''))) - convert(float(1), MIN(REGEXP_REPLACE(duration,'[^0-9]','')))
from runner_orders
where pickup_time <> 'null' --to drop the two pizzas that were not picked up / cancelled
group by duration
order by REGEXP_REPLACE(duration,'[^0-9]','')
/*40 minus 10 is 30*/


--6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
select * from customer_orders;
select * from runner_orders;

with cte as (
select 
convert(INT, REGEXP_REPLACE(duration,'[^0-9]','')) as duration_clean
, convert(float(1), replace(distance, 'km', '')) as distance_clean
, * 
from runner_orders
where pickup_time <> 'null'
)
select
runner_id
, order_id
, sum(duration_clean) as total_mins
, sum(distance_clean) as total_km
, sum(distance_clean)/sum(duration_clean) as speed
from cte
group by runner_id, order_id
order by runner_id, order_id;

--as the shift goes on, the runners get faster
/*
runner_id	order_id	total_mins	total_km	speed
1	1	32	20	0.625
1	2	27	20	0.740740740740741
1	3	20	13.3999996185303	0.669999980926514
1	10	10	10	1
2	4	40	23.3999996185303	0.584999990463257
2	7	25	25	1
2	8	15	23.3999996185303	1.55999997456868
3	5	15	10	0.666666666666667
*/

--7 What is the successful delivery percentage for each runner?
--my first thought was to define "success", which isn't clear, so I used Will's suggestion to mark success as whether or not the order was delivered
--I'd suggest that if an order was cancelled, that's not the runner's fault so shouldn't hurt their stat
--but for the sake of getting an answer here goes:

with cte as (
select
case when pickup_time = 'null' then 0 else 1 end as success
, *
from runner_orders
)
select 
runner_id
, sum(success) as successful_orders
, count(*) as all_orders
, round(
		cast(
		sum(success) as decimal(4,2)
			) / count(*), 2
		) as success_rate
from cte
group by runner_id;

/*
runner_id	successful_orders	all_orders	success_rate
1	4	4	1.0000000000000
2	3	4	0.7500000000000
3	1	2	0.5000000000000
*/
