---------------------------------------------------------------------------------------------------
										/*Pizza Metrics*/
---------------------------------------------------------------------------------------------------
--All queries writen on Google's BigQuery
---------------------------------------------------------------------------------------------------
/*How many pizzas were ordered?*/
---------------------------------------------------------------------------------------------------
select
count(*) as pizzas_ordered
from casestudy2.customer_orders

---------------------------------------------------------------------------------------------------
/*How many unique customer orders were made?*/
---------------------------------------------------------------------------------------------------
select 
count(distinct(customer_id)) 
from casestudy2.customer_orders

---------------------------------------------------------------------------------------------------
/*How many successful orders were delivered by each runner?*/
---------------------------------------------------------------------------------------------------
select 
runner_id, 
count(order_id) as successful_deliveries
from casestudy2.runner_orders
where pickup_time <> 'null'
group by runner_id

---------------------------------------------------------------------------------------------------
/*How many of each type of pizza was delivered?*/
---------------------------------------------------------------------------------------------------

select 
co.pizza_id,
count(pizza_id) as delivered_pizza
from casestudy2.customer_orders co
left join casestudy2.runner_orders ro
on co.order_id=ro.order_id
where ro.pickup_time <> 'null'
group by co.pizza_id

---------------------------------------------------------------------------------------------------
/*How many Vegetarian and Meatlovers were ordered by each customer?*/
---------------------------------------------------------------------------------------------------
select 
co.customer_id,
sum(case when pn.pizza_name = 'Meat Lovers' then 1 else 0 end) as Meatlovers,
sum(case when pn.pizza_name = 'Vegetarian' then 1 else 0 end) as Vegetarian
from casestudy2.customer_orders co
left join casestudy2.pizza_names pn on co.pizza_id=pn.pizza_id 
group by co.customer_id

---------------------------------------------------------------------------------------------------
/*What was the maximum number of pizzas delivered in a single order?*/
---------------------------------------------------------------------------------------------------


select
co.order_id,
count(co.order_id) delivered_pizza
from casestudy2.customer_orders co
left join casestudy2.runner_orders ro
on co.order_id=ro.order_id
where ro.pickup_time <> 'null'
group by co.order_id
order by delivered_pizza desc
limit 1

---------------------------------------------------------------------------------------------------
/*For each customer, how many delivered pizzas had at least 1 change and how many had no changes?*/
---------------------------------------------------------------------------------------------------
with delivered_pizza as (
select co.order_id, co.customer_id, co.pizza_id,co.exclusions,co.extras,co.order_time
from casestudy2.customer_orders co
inner join casestudy2.runner_orders ro
on co.order_id=ro.order_id
where ro.pickup_time <> 'null'
)

select 
customer_id,
sum(case when exclusions not in ('null','') or extras not in ('null','') then 1 else 0 end) as at_least_1_change,
sum(case when exclusions not in ('null','') or extras not in ('null','') then 0 else 1 end) as no_change
from delivered_pizza
group by customer_id

---------------------------------------------------------------------------------------------------
/*How many pizzas were delivered that had both exclusions and extras?*/
---------------------------------------------------------------------------------------------------
select 
sum(case when exclusions not in ('null','') and extras not in ('null','') then 1 else 0 end) as pizzas_delivered
from casestudy2.customer_orders co
inner join casestudy2.runner_orders ro
on co.order_id=ro.order_id
where ro.pickup_time <> 'null'

---------------------------------------------------------------------------------------------------
/*What was the total volume of pizzas ordered for each hour of the day?*/
---------------------------------------------------------------------------------------------------
select
extract (hour from order_time) as hour_of_day,
count(order_id) orders
from casestudy2.customer_orders
group by hour_of_day
order by orders desc

---------------------------------------------------------------------------------------------------
/*What was the volume of orders for each day of the week?*/
---------------------------------------------------------------------------------------------------
select
extract (dayofweek from order_time) as day_of_week,
count(distinct(order_id)) orders
from casestudy2.customer_orders
group by day_of_week
order by orders desc
