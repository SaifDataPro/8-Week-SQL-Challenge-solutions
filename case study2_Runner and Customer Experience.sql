------------------------------------
/*Runner and Customer Experience*/
------------------------------------

---------------------------------------------------------------------------------------------------------------------
/*How many runners signed up for each 1 week period? (i.e. week starts 2024-01-01)*/
---------------------------------------------------------------------------------------------------------------------
select 
extract(isoweek from registration_date) as week,--ISOWEEKs begin on Monday. Return values are in the range [1, 53]
count(*) as registrations
from
casestudy2.runners
group by week
----------------------------------------------------------------------------------------------------------------------
/*What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?*/
----------------------------------------------------------------------------------------------------------------------
with arrival_time as (
select
distinct co.order_id,
ro.runner_id,
timestamp_diff(ro.pickup_time,co.order_time,minute) as arrived_in_minutes
from casestudy2.runner_orders as ro
inner join casestudy2.customer_orders as co
on ro.order_id=co.order_id
where ro.pickup_time is not null
)

select 
runner_id,
avg(arrived_in_minutes) as avg_arrival_time
from arrival_time
group by runner_id

---------------------------------------------------------------------------------------------------------------------
/*Is there any relationship between the number of pizzas and how long the order takes to prepare?*/
---------------------------------------------------------------------------------------------------------------------
--see the time difference between order and pickup for each order_id

with preparation_time as (
select
co.order_id as order_id,
co.pizza_id as pizzas,
timestamp_diff(ro.pickup_time,co.order_time,minute) as prepared_in_minutes
from casestudy2.customer_orders as co
inner join casestudy2.runner_orders as ro
on co.order_id=ro.order_id
where ro.pickup_time is not null
)
select 
order_id,
count(pizzas) as number_of_pizzas,
avg(prepared_in_minutes) as avg_preparation_time,
corr(count(pizzas),avg(prepared_in_minutes)) over() as corr_coeff
from preparation_time
group by order_id
order by number_of_pizzas desc,avg_preparation_time desc

/*returns correlation coeeficient of 0.85 which signifies a strong positive linear relationship. 
It means that as the number of pizzas in an order goes up, the average time it takes to prepare that order also tends to go up*/
---------------------------------------------------------------------------------------------------------------------
/*What was the average distance travelled for each customer?*/
---------------------------------------------------------------------------------------------------------------------
with distance_by_customer as (
select 
distinct ro.order_id,
co.customer_id as customer_id,
cast(replace(replace(ro.distance,' ',''),'km','') as numeric) as distance
from casestudy2.runner_orders ro
inner join casestudy2.customer_orders as co
on co.order_id=ro.order_id
where distance <> 'null'
)
select
customer_id,
round(avg(distance),2) as avg_distance_travelled
from distance_by_customer
group by customer_id
---------------------------------------------------------------------------------------------------------------------
/*What was the difference between the longest and shortest delivery times for all orders?*/
---------------------------------------------------------------------------------------------------------------------
with deliver_times as ( 
select
max(cast(REGEXP_REPLACE(duration, r'( minutes| mins|mins|minutes| minute)', '')as int64)) as longest_delivery_time,
min(cast(REGEXP_REPLACE(duration, r'( minutes| mins|mins|minutes| minute)', '')as int64)) as shortest_delivery_time
from casestudy2.runner_orders
where duration <> 'null'
)
select 
longest_delivery_time - shortest_delivery_time
from deliver_times
---------------------------------------------------------------------------------------------------------------------
/*What was the average speed for each runner for each delivery and do you notice any trend for these values?*/
---------------------------------------------------------------------------------------------------------------------
with travelled_distance as (
select
runner_id,
order_id,
cast(REGEXP_REPLACE(distance, r'(km| km)', '')as numeric) as distance_travelled,
cast(REGEXP_REPLACE(duration, r'( minutes| mins|mins|minutes| minute)', '')as int64) as time_taken
from casestudy2.runner_orders
where duration <> 'null'
)

select
runner_id,
count(order_id) as orders_delivered,
sum(distance_travelled) as total_distance_covered,
round(avg(distance_travelled/(time_taken/60)),2) as avg_speedOfDelivery_kmph
from travelled_distance
group by runner_id

/*Runner 2 achieved the highest average speed (57.4 kmph) despite covering the greatest distance (86.8 km) across four orders. 
Runner 3 had the lowest average speed (41.6 kmph) with the shortest distance (28 km) and fewest orders (2). 
Further analysis is needed to explore potential factors like route efficiency and traffic.*/
---------------------------------------------------------------------------------------------------------------------
/*What is the successful delivery percentage for each runner?*/
---------------------------------------------------------------------------------------------------------------------
with ordersbyrunners as (
select
runner_id,
count(order_id) as total_orders,
countif( duration <> 'null') as succesful_orders,
from casestudy2.runner_orders
group by runner_id
)

select 
runner_id,
round(((succesful_orders)/(total_orders))*100,2) as successful_delivery_perc
from ordersbyrunners
