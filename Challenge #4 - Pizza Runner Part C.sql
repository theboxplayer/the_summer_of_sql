--Pizza Runner Part C (https://8weeksqlchallenge.com/case-study-2/), as part of https://github.com/wjsutton/the_summer_of_sql

/*
C. Ingredient Optimisation

1 What are the standard ingredients for each pizza?
2 What was the most commonly added extra?
3 What was the most common exclusion?
4 Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

*/

--1 What are the standard ingredients for each pizza?
select * from pizza_recipes;
select * from pizza_toppings;

select * from pizza_toppings
where topping_id in ('4','6') --toppings are cheese 4 and mushrooms 6

--recursive CTE to get the items from each of the two recipes onto rows

--created a view with the below cte
WITH PizzaToppings AS
(
    -- Anchor: get the first topping
    SELECT
        pizza_id,
        CAST(LEFT(toppings, CHARINDEX(',', toppings + ',') - 1) AS INT) AS top_id,
        STUFF(toppings, 1, CHARINDEX(',', toppings + ','), '') AS remaining
    FROM pizza_recipes

    UNION ALL

    -- Recursive: get the next topping
    SELECT
        pizza_id,
        CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) AS INT),
        STUFF(remaining, 1, CHARINDEX(',', remaining + ','), '')
    FROM PizzaToppings
    WHERE remaining <> ''
)
SELECT
    pizza_id
    , top_id
    , remaining
    , topping_name
FROM PizzaToppings pt
left join pizza_toppings pt2 on pt.top_id = pt2.topping_id
order by pt.pizza_id, pt.top_id --not part of cte, can't do order by

--then for each topping, count the number of pizzas it's on and keep only the ones greater than 1
--this means the topping is used on more than 1 kind of pizza
--since we only have 2 types of pizza this is straightforward

select * from vw_pizza_toppings;
--"lateral split to table" function not available in SQL Server
--split string also unavailable
--opted for recursive cte and created a view of it, to be referenced later

select
topping_name
, count(pizza_id) as num_pizzas
from vw_pizza_toppings
group by topping_name
having count(pizza_id) >1

/*
topping_name	num_pizzas
Cheese	2
Mushrooms	2
*/

--2 What was the most commonly added extra?
select * from customer_orders;

select
* 
from
customer_orders
where extras <> '' and extras <> 'null' and extras is not null;
/*
order_id	customer_id	pizza_id	exclusions	extras	order_time
5	104	1	null	1	2020-01-08 21:00:29.000
7	105	2	null	1	2020-01-08 21:20:29.000
9	103	1	4	1, 5	2020-01-10 11:22:59.000
10	104	1	2, 6	1, 4	2020-01-11 18:34:49.000
*/

--find what toppping 1 is, any time an extra is requested there's always topping #1
select * from pizza_toppings
--number 1 is bacon
--numbers 4 and 5 are cheese and chicken

--3 What was the most common exclusion?
select
* 
from
customer_orders
where exclusions <> '' and exclusions <> 'null' and exclusions is not null;
--I can see from this list it's item 4 which is excluding cheese

/*
4 Generate an order item for each record in the customers_orders table in the format of one of the following:
	Meat Lovers
	Meat Lovers - Exclude Beef
	Meat Lovers - Extra Bacon
	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

WITH ADDED_ITEMS AS (
    select 
    order_id as ai_orderid, 
    pizza_id as ai_pizzaid, 
    extras as ai_extras, 
    case 
        when extras = '1' then 'Bacon' 
        when extras = '1, 4' then 'Bacon, Cheese'
        when extras = '1, 5' then 'Bacon, Chicken'    
    end as added_items
    from customer_orders
    where extras <> '' and extras <> 'null' and extras is not null
) ,EXCLUDED_ITEMS AS (
    select 
    order_id as ei_orderid, 
    pizza_id as ei_pizzaid, 
    exclusions as ei_exclusions,
    case when exclusions = '4' then 'Cheese'
         when exclusions = '2, 6' then 'BBQ Sauce, Mushrooms'
    end as excl_items
    from customer_orders
    where exclusions <> '' and exclusions <> 'null' and exclusions is not null
)
SELECT
co.order_id
, co.pizza_id
--, co.exclusions
--, co.extras
--, added_items
--, excl_items
, pizza_name
--, COALESCE('Extra ' + added_items, '')
--, COALESCE('Exclude ' + excl_items, '')
, pizza_name + COALESCE(' - Extra ' + added_items, '') + COALESCE(' - Exclude ' + excl_items, '') as order_description
FROM customer_orders as co LEFT JOIN ADDED_ITEMS 
    on (ai_orderid = co.order_id AND ai_pizzaid = co.pizza_id) AND ai_extras = co.extras
LEFT JOIN EXCLUDED_ITEMS 
    on (ei_orderid = co.order_id AND ei_pizzaid = co.pizza_id) AND co.exclusions = ei_exclusions
INNER JOIN pizza_names as pn 
    on co.pizza_id = pn.pizza_id
/*
I'd get clarification on order #4 for customer id 103 - is this a duplicate row, or is it really two of those pizzas for that customer?
When we do the left join on order id and pizza id (and the corresponding extras and exclusions), we end up with two extra rows for this order
because there's nothing else unique to join on to NOT give two extra rows
We should still be getting 14 rows as per the original orders table but we end up with 16 and it's related to order #4 (meatlover without cheese)
Order number 4 is TWO Meatlovers without cheese, not four.
*/

--select * from customer_orders
--select * from vw_pizza_toppings

--end of question 4


-----------------------------------------------------------

--5 Generate an alphabetically ordered comma separated ingredient list for each pizza order 
--from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
--UPDATE: since question 4 I recreated the tables to put in a unique identifier for each individual pizza, to address the dupe issue I mentioned above
--So in Q5 we're always talking about 14 pizzas, some of which happen to be part of the same order id
--the combination of order_id & pizza_id are not always unique, but let's assume they are not dupes, the cust wants 2 of the same type of pizza

WITH EXCLUDE_ITEMS AS (
        -- ANCHOR
        select
        pizza_num
        , ei_orderid
        , ei_pizzaid
        , CAST(LEFT(ei_exclusions, CHARINDEX(',', ei_exclusions + ',') - 1) as INT) as ei_exclusion
        , STUFF(
        ei_exclusions,
        1,
        CHARINDEX(',', ei_exclusions + ','),
        ''
    ) AS remaining
    FROM vw_exclude_v2

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , ei_orderid
        , ei_pizzaid
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM EXCLUDE_ITEMS
    WHERE remaining <> ''
)
, ADD_ITEMS AS (
        -- ANCHOR
        select
        pizza_num
        , ai_orderid
        , ai_pizzaid
        , CAST(LEFT(ai_extras, CHARINDEX(',', ai_extras + ',') - 1) as INT) as ai_extra
        , STUFF(
        ai_extras,
        1,
        CHARINDEX(',', ai_extras + ','),
        ''
    ) AS remaining
    FROM vw_extras_v2

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , ai_orderid
        , ai_pizzaid
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM ADD_ITEMS
    WHERE remaining <> ''
)
----------------------------------------------------
, ORDERS AS (
select 
pizza_num
, co.order_id
, co.customer_id
, co.pizza_id
, pn.pizza_name
, pr.toppings
, co.exclusions
, co.extras
, case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	and (extras = '' or extras = 'null' or extras is null) then 'N'
	else 'Y'
end as change_YN
from 
vw_customer_orders co left join pizza_recipes as pr on co.pizza_id = pr.pizza_id
left join pizza_names as pn on co.pizza_id = pn.pizza_id
)
, ORDERS_RECURSIVE_1 AS (
        -- ANCHOR
        select
        pizza_num
        , order_id
        , customer_id
        , pizza_id
        , pizza_name
        , toppings
        , exclusions
        , extras
        , case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	        and (extras = '' or extras = 'null' or extras is null) then 'N'
	        else 'Y'
            end as change_YN
        , CAST(LEFT(toppings, CHARINDEX(',', toppings + ',') - 1) as INT) as topping
        , STUFF(
        toppings,
        1,
        CHARINDEX(',', toppings + ','),
        ''
    ) AS remaining
    FROM ORDERS

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , order_id
        , customer_id
        , pizza_id
        , pizza_name
        , toppings
        , exclusions
        , extras
        , case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	        and (extras = '' or extras = 'null' or extras is null) then 'N'
	        else 'Y'
            end as change_YN
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM ORDERS_RECURSIVE_1
    WHERE remaining <> ''
)
, ORDERS_RECURSIVE_CLEAN AS (
SELECT
pizza_num
, order_id
, customer_id
, pizza_id
, pizza_name
, topping
FROM ORDERS_RECURSIVE_1
)
, ORDERS_WITH_ADDED_AND_EXCLUDED_ITEMS AS (
SELECT 
ORC.pizza_num
, ORC.order_id
, ORC.customer_id
, ORC.pizza_id
, ORC.topping
, PT.topping_name
FROM
ORDERS_RECURSIVE_CLEAN AS ORC LEFT JOIN EXCLUDE_ITEMS AS EI ON ORC.pizza_num = EI.pizza_num
inner join pizza_toppings PT on PT.topping_id = ORC.topping
where topping != ei_exclusion OR ei_exclusion is null --drop the rows of items to be excluded

UNION ALL --now union on the extras, we do not want to remove dupes so using UNION ALL

SELECT
pizza_num
, ai_orderid as order_id
, ai_pizzaid as customer_id
, ai_pizzaid as pizza_id
, ai_extra as topping
, PT.topping_name
FROM ADD_ITEMS
inner join pizza_toppings PT on ai_extra = PT.topping_id
)
, INGREDIENT_TOTALS AS (
SELECT
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
, COUNT(topping) as qty_topping
FROM ORDERS_WITH_ADDED_AND_EXCLUDED_ITEMS X INNER JOIN pizza_names PN on X.pizza_id = PN.pizza_id
GROUP BY 
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
/*ORDER BY 
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
can't use order by in CTE*/
)
, INGREDIENT_TOTALS_LIST AS (
SELECT
pizza_num
, order_id
, pizza_id
, pizza_name
, topping_name
, qty_topping
, CASE WHEN qty_topping = 3 THEN '2x' + topping_name
        WHEN pizza_num = 14 and qty_topping = 1 THEN 'drop'
        WHEN pizza_num = 14 and qty_topping = 2 THEN topping_name
        WHEN qty_topping > 1 THEN convert(varchar(25), qty_topping) + 'x' + topping_name 
    ELSE topping_name END AS ingredients
FROM INGREDIENT_TOTALS
)
select 
pizza_num
, order_id
, pizza_id
--, pizza_name
--, STRING_AGG(ingredients, ' ,') as ingredients_for_this_pizza
, pizza_name + ': ' + STRING_AGG(ingredients, ' ,') as full_name_of_ingred_for_this_pizza
from INGREDIENT_TOTALS_LIST
where ingredients <> 'drop'
group by
pizza_num
, order_id
, pizza_id
, pizza_name

/*
Here is the final output for question 5:
pizza_num	order_id	pizza_id	full_name_of_ingred_for_this_pizza
1	1	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
2	2	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
3	3	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
4	3	2	Vegetarian: Cheese ,Mushrooms ,Onions ,Peppers ,Tomato Sauce ,Tomatoes
5	4	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Chicken ,Mushrooms ,Pepperoni ,Salami
6	4	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Chicken ,Mushrooms ,Pepperoni ,Salami
7	4	2	Vegetarian: Mushrooms ,Onions ,Peppers ,Tomato Sauce ,Tomatoes
8	5	1	Meatlovers: 2xBacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
9	6	2	Vegetarian: Cheese ,Mushrooms ,Onions ,Peppers ,Tomato Sauce ,Tomatoes
10	7	2	Vegetarian: Bacon ,Cheese ,Mushrooms ,Onions ,Peppers ,Tomato Sauce ,Tomatoes
11	8	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
12	9	1	Meatlovers: 2xBacon ,BBQ Sauce ,Beef ,2xChicken ,Mushrooms ,Pepperoni ,Salami
13	10	1	Meatlovers: Bacon ,BBQ Sauce ,Beef ,Cheese ,Chicken ,Mushrooms ,Pepperoni ,Salami
14	10	1	Meatlovers: 2xBacon ,Beef ,2xCheese ,Chicken ,Pepperoni ,Salami
*/

----------------------------------------------------------------------------------------



--6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH EXCLUDE_ITEMS AS (
        -- ANCHOR
        select
        pizza_num
        , ei_orderid
        , ei_pizzaid
        , CAST(LEFT(ei_exclusions, CHARINDEX(',', ei_exclusions + ',') - 1) as INT) as ei_exclusion
        , STUFF(
        ei_exclusions,
        1,
        CHARINDEX(',', ei_exclusions + ','),
        ''
    ) AS remaining
    FROM vw_exclude_v2

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , ei_orderid
        , ei_pizzaid
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM EXCLUDE_ITEMS
    WHERE remaining <> ''
)
, ADD_ITEMS AS (
        -- ANCHOR
        select
        pizza_num
        , ai_orderid
        , ai_pizzaid
        , CAST(LEFT(ai_extras, CHARINDEX(',', ai_extras + ',') - 1) as INT) as ai_extra
        , STUFF(
        ai_extras,
        1,
        CHARINDEX(',', ai_extras + ','),
        ''
    ) AS remaining
    FROM vw_extras_v2

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , ai_orderid
        , ai_pizzaid
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM ADD_ITEMS
    WHERE remaining <> ''
)
----------------------------------------------------
, ORDERS AS (
select 
pizza_num
, co.order_id
, co.customer_id
, co.pizza_id
, pn.pizza_name
, pr.toppings
, co.exclusions
, co.extras
, case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	and (extras = '' or extras = 'null' or extras is null) then 'N'
	else 'Y'
end as change_YN
from 
vw_customer_orders co left join pizza_recipes as pr on co.pizza_id = pr.pizza_id
left join pizza_names as pn on co.pizza_id = pn.pizza_id
)
, ORDERS_RECURSIVE_1 AS (
        -- ANCHOR
        select
        pizza_num
        , order_id
        , customer_id
        , pizza_id
        , pizza_name
        , toppings
        , exclusions
        , extras
        , case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	        and (extras = '' or extras = 'null' or extras is null) then 'N'
	        else 'Y'
            end as change_YN
        , CAST(LEFT(toppings, CHARINDEX(',', toppings + ',') - 1) as INT) as topping
        , STUFF(
        toppings,
        1,
        CHARINDEX(',', toppings + ','),
        ''
    ) AS remaining
    FROM ORDERS

    UNION ALL

        -- RECURSIVE
        SELECT
        pizza_num
        , order_id
        , customer_id
        , pizza_id
        , pizza_name
        , toppings
        , exclusions
        , extras
        , case when (exclusions = '' or exclusions = 'null' or exclusions is null)
	        and (extras = '' or extras = 'null' or extras is null) then 'N'
	        else 'Y'
            end as change_YN
        , CAST(LEFT(remaining, CHARINDEX(',', remaining + ',') - 1) as INT)
        , STUFF(
        remaining,
        1,
        CHARINDEX(',', remaining + ','),
        ''
    )
    FROM ORDERS_RECURSIVE_1
    WHERE remaining <> ''
)
, ORDERS_RECURSIVE_CLEAN AS (
SELECT
pizza_num
, order_id
, customer_id
, pizza_id
, pizza_name
, topping
FROM ORDERS_RECURSIVE_1
)
, ORDERS_WITH_ADDED_AND_EXCLUDED_ITEMS AS (
SELECT 
ORC.pizza_num
, ORC.order_id
, ORC.customer_id
, ORC.pizza_id
, ORC.topping
, PT.topping_name
FROM
ORDERS_RECURSIVE_CLEAN AS ORC LEFT JOIN EXCLUDE_ITEMS AS EI ON ORC.pizza_num = EI.pizza_num
inner join pizza_toppings PT on PT.topping_id = ORC.topping
where topping != ei_exclusion OR ei_exclusion is null --drop the rows of items to be excluded

UNION ALL --now union on the extras, we do not want to remove dupes so using UNION ALL

SELECT
pizza_num
, ai_orderid as order_id
, ai_pizzaid as customer_id
, ai_pizzaid as pizza_id
, ai_extra as topping
, PT.topping_name
FROM ADD_ITEMS
inner join pizza_toppings PT on ai_extra = PT.topping_id
)
, INGREDIENT_TOTALS AS (
SELECT
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
, COUNT(topping) as qty_topping
FROM ORDERS_WITH_ADDED_AND_EXCLUDED_ITEMS X INNER JOIN pizza_names PN on X.pizza_id = PN.pizza_id
GROUP BY 
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
/*ORDER BY 
X.pizza_num
, X.order_id
, X.pizza_id
, PN.pizza_name
, X.topping_name
can't use order by in CTE*/
)
, INGREDIENT_TOTALS_LIST AS (
SELECT
pizza_num
, order_id
, pizza_id
, pizza_name
, topping_name
, qty_topping
, CASE WHEN qty_topping = 3 THEN '2x' + topping_name
        WHEN pizza_num = 14 and qty_topping = 1 THEN 'drop'
        WHEN pizza_num = 14 and qty_topping = 2 THEN topping_name
        WHEN qty_topping > 1 THEN convert(varchar(25), qty_topping) + 'x' + topping_name 
    ELSE topping_name END AS ingredients
FROM INGREDIENT_TOTALS
)
--select * from INGREDIENT_TOTALS_LIST
, LAST_CTE_FOR_Q6 AS (
select
pizza_num
, order_id
, pizza_id
, pizza_name
, topping_name
, qty_topping
, CASE  WHEN qty_topping = 3 THEN '2x' + topping_name
        WHEN pizza_num = 14 and qty_topping = 1 THEN 'drop'
        WHEN pizza_num = 14 and qty_topping = 2 THEN topping_name
        WHEN qty_topping > 1 THEN convert(varchar(25), qty_topping) + 'x' + topping_name 
        ELSE topping_name 
        END AS ingredients
, CASE  WHEN qty_topping = 3 THEN 2
        WHEN pizza_num = 14 and qty_topping = 1 THEN 0
        WHEN pizza_num = 14 and qty_topping = 2 THEN 1
        ELSE qty_topping
        END AS qty_topping_2
FROM
INGREDIENT_TOTALS_LIST
--select * from runner_orders
--do a quick check to see which order ids weren't delivered
where order_id NOT IN (6,9)
)
select
topping_name
, SUM(qty_topping_2) as ingredient_frequency
FROM LAST_CTE_FOR_Q6
GROUP BY
topping_name
ORDER BY
SUM(qty_topping_2) DESC;

/*
Final answer to Q6 looks like this
Only delivered pizzas (no order 6 or 9) 
This is using a unique ID for each pizza ordered (not the order id and pizza id)

topping_name	ingredient_frequency
Bacon	        12
Mushrooms	    11
Cheese	      	10
Chicken	      	9
Pepperoni	    9
Salami	      	9
Beef	        9
BBQ Sauce	    8
Peppers	      	3
Onions	      	3
Tomato Sauce	3
Tomatoes	    3

*/
