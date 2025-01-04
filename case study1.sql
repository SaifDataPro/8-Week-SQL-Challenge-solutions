---------------------------
/*Case Study Questions*/
-------------------------
----------------------------------------------------------------------
/*1. What is the total amount each customer spent at the restaurant?*/
----------------------------------------------------------------------
select 
s.customer_id as customer,
sum(m.price) as spend
from `8weeksql.sales` as s
inner join `8weeksql.menu` as m
on s.product_id=m.product_id
group by customer
order by spend desc

-------------------------------------------------------------------
/* 2. How many days has each customer visited the restaurant?*/
-------------------------------------------------------------------
  
select 
customer_id as customer,
count(distinct(order_date)) as days_visited
from `8weeksql.sales`
group by customer
order by days_visited desc

------------------------------------------------------------------------
/*3. What was the first item from the menu purchased by each customer?*/
------------------------------------------------------------------------

with ranked_orders as 
(
select 
customer_id as customer,
order_date,
product_id,
row_number() over(partition by customer_id order by order_date asc) as order_instance
from `8weeksql.sales`
)

select r.customer, m.product_name from ranked_orders as r
left join `8weeksql.menu` m
on r.product_id=m.product_id
where order_instance =1
order by r.customer asc

---------------------------------------------------------------------------------------------------------
/* 4. What is the most purchased item on the menu and how many times was it purchased by all customers?*/
---------------------------------------------------------------------------------------------------------
  
select 
m.product_name,
count(s.product_id) as total_sold
from `8weeksql.sales` as s
left join `8weeksql.menu` m
on s.product_id=m.product_id
group by m.product_name
order by total_sold desc

-----------------------------------------------------------
/* 5. Which item was the most popular for each customer?*/
-----------------------------------------------------------
with ranked_orders as
(
select 
s.customer_id as customer,
mu.product_name as product,
count(s.product_id) as total_sold,
rank() over(partition by s.customer_id order by count(s.product_id) desc) as popularity
from `8weeksql.sales` as s
left join `8weeksql.menu` mu
on s.product_id=mu.product_id
group by customer, mu.product_name
order by customer, popularity
)

select customer, product from ranked_orders
where popularity =1

---------------------------------------------------------------------------------
/*6. Which item was purchased first by the customer after they became a member?*/
---------------------------------------------------------------------------------

with active_members as 
(
select
s.customer_id as customer,
me.product_name as product,
ms.join_date as joined_on,
s.order_date,
case when s.order_date>ms.join_date then 'Yes' else 'No'
end as Purchashed_after_membership,
rank() over(partition by s.customer_id,(case when s.order_date>ms.join_date then 'Yes' else 'No'end) order by s.order_date asc) as instance
from `8weeksql.sales` as s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id 
where join_date is not null
qualify instance =1
)

select
customer,
product
from active_members
where Purchashed_after_membership = 'Yes'
order by customer

-------------------------------------------------------------------------
/*7. Which item was purchased just before the customer became a member?*/
-------------------------------------------------------------------------

with active_members as 
(
select
s.customer_id as customer,
me.product_name as product,
ms.join_date as joined_on,
s.order_date,
case when s.order_date<ms.join_date then 'Yes' else 'No'
end as Purchashed_before_membership,
rank() over(partition by s.customer_id,(case when s.order_date<ms.join_date then 'Yes' else 'No'end) order by s.order_date desc) as instance
from `8weeksql.sales` as s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id 
where join_date is not null
qualify instance =1
)

select
customer,
product
from active_members
where Purchashed_before_membership = 'Yes'
order by customer

--------------------------------------------------------------------------------------------
/*8. What is the total items and amount spent for each member before they became a member?*/
--------------------------------------------------------------------------------------------
  
with active_members as 
(
select
s.customer_id as customer,
s.product_id as items,
me.price as amount_spent,
ms.join_date as joined_on,
s.order_date,
case when s.order_date<ms.join_date then 'Yes' else 'No'
end as Purchashed_before_membership,
rank() over(partition by s.customer_id,(case when s.order_date<ms.join_date then 'Yes' else 'No'end) order by s.order_date desc) as instance
from `8weeksql.sales` as s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id 
where join_date is not null
qualify instance =1
)

select
customer,
count(items) as items,
sum(amount_spent) as amount_spent
from active_members
where Purchashed_before_membership = 'Yes'
group by customer
order by customer

------------------------------------------------------------------------------------------------------------------------------
/*9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/
------------------------------------------------------------------------------------------------------------------------------
  
with points_table as (
select
s.customer_id as customer,
10*(case when s.product_id = 1 then me.price * 2 else me.price end) as points,
from `8weeksql.sales` s
left join `8weeksql.menu` me on s.product_id=me.product_id 
)

select
customer,
sum(points) as points
from points_table
group by customer
order by points desc

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  
with first_week_points as (
select
s.customer_id as customer,
10*(case when (extract (week from s.order_date)=extract (week from ms.join_date)) or s.product_id = 1 then me.price * 2 else me.price end) as points,
from `8weeksql.sales` s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id
where s.order_date>=ms.join_date
and extract (week from s.order_date)=extract (week from ms.join_date)
)

select 
customer,
sum(points) as points
from first_week_points
group by customer
order by points desc

------------------
--Bonus question--
------------------
  
--Join all the tables 

select 
s.customer_id,
s.order_date,
me.product_name,
me.price,
case when ms.join_date is not null then 'Y' else 'N' end as member
from `8weeksql.sales` as s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id 

--Top Produt by each customer

select 
s.customer_id as customer,
me.product_name,
sum(me.price) as sales
from `8weeksql.sales` as s
left join `8weeksql.members` ms on s.customer_id=ms.customer_id
left join `8weeksql.menu` me on s.product_id=me.product_id 
group by 1,2
qualify rank() over (partition by s.customer_id order by sum(me.price) desc)=1
order by customer
