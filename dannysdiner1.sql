use dannys_diner;
/*1. What is the total amount each customer spent at the restaurant?*/
SELECT s.customer_id, SUM(m.price) as total_amount 
FROM sales AS s 
JOIN menu AS m ON s.product_id = m.product_id 
GROUP BY s.customer_id;

/*2. How many days has each customer visited the restaurant?*/
SELECT customer_id,
COUNT(DISTINCT order_date) AS no_visits
FROM sales
GROUP BY customer_id;

/*3. What was the first item from the menu purchased by each customer?*/
WITH sale_rankings AS (
          SELECT s.customer_id,
           m.product_id AS menu_product_id,
           s.order_date,
           FIRST_VALUE(m.product_name) OVER (PARTITION BY s.customer_id ORDER BY s.order_date) 
           AS first_item
		   FROM sales s
		   JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, first_item
FROM sale_rankings
GROUP BY customer_id, first_item;

/*4. What is the most purchased item on the menu and how many times was it purchased by all customers?  */

SELECT m.product_name,count(s.product_id) as count
from sales s 
join menu m on s.product_id = m.product_id
group by m.product_name
order by count desc
limit 1;

/*5. Which item was the most popular for each customer?*/
with pdt_rank as (
select s.customer_id,m.product_id,m.product_name,count(s.product_id) no_order, 
dense_rank() over (partition by s.customer_id order by count(s.product_id) desc) rank_order
from  sales s join 
menu m on s.product_id=m.product_id
group by 1,2) 

select customer_id,product_name,no_order
from pdt_rank 
where rank_order=1;

/*6. Which item was purchased first by the customer after they became a member?*/
with ct as (SELECT members.customer_id, 
    sales.product_id,
    sales.order_date,
    members.join_date,
    ROW_NUMBER() OVER (
      PARTITION BY members.customer_id
      ORDER BY sales.order_date) AS row_num FROM members
      INNER JOIN sales ON members.customer_id = sales.customer_id
      AND sales.order_date >= members.join_date)
select customer_id as customer,
product_name from
ct join menu on ct.product_id = menu.product_id
where row_num = 1
order by customer;

/* 7. Which item was purchased just before the customer became a member?*/

with cte as(
SELECT s.customer_id as customer,mem.join_date,s.order_date,m.product_name,
dense_rank() over(partition by s.customer_id order by s.order_date desc) as rnk
from sales s ,members mem,menu m 
where s.customer_id=mem.customer_id
and s.product_id = m.product_id
and s.order_date  < mem.join_date)
select customer,product_name 
from cte
where rnk= 1
order by customer;

/*8. What is the total items and amount spent for each member before they became a member?*/

SELECT s.customer_id as customer, 
       COUNT(s.product_id) as no_item,
       SUM(m.price) as amount_spent
FROM sales s, menu m, members me
WHERE s.customer_id = me.customer_id
AND s.product_id = m.product_id
AND s.order_date < me.join_date
GROUP BY s.customer_id;

/*9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/
SELECT s.customer_id as Customer,
SUM(CASE WHEN m.product_name = 'sushi' THEN (20*m.price) 
ELSE (m.price*10) END) AS Points
from SALES s JOIN MENU m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

/*10 In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

select s.customer_id ,
SUM(CASE WHEN m.product_name = 'sushi' 
         OR (s.order_date between me.join_date and (me.join_date+6)) THEN (2*10*m.price)
         ELSE (10*m.price) END ) AS points
FROM sales s INNER join members me on s.customer_id = me.customer_id
JOIN menu m on s.product_id = m.product_id
WHERE MONTH(s.order_date)=1 
group by s.customer_id;

/*11.  JOIN ALL THE THINGS */
WITH ct as(
SELECT s.customer_id,s.order_date,m.product_name,m.price
FROM sales s join menu m on
s.product_id = m.product_id)
SELECT ct.customer_id,ct.order_date,ct.product_name,ct.price,
(CASE WHEN ISNULL(me.join_date)  THEN 'N'
      WHEN ct.order_date < me.join_date THEN 'N'
      ELSE 'Y'
	  END) as member 
FROM ct LEFT JOIN members me 
ON ct.customer_id = me.customer_id;

/*12.  Rank All The Things*/
WITH ct as(
SELECT s.customer_id,s.order_date,m.product_name,m.price
FROM sales s join menu m on
s.product_id = m.product_id),
newt as(
SELECT ct.customer_id,ct.order_date,ct.product_name,ct.price,
(CASE WHEN ISNULL(me.join_date)  THEN 'N'
      WHEN ct.order_date < me.join_date THEN 'N'
      ELSE 'Y'
	  END) as member 
FROM ct LEFT JOIN members me 
ON ct.customer_id = me.customer_id)
SELECT *, 
  CASE WHEN member = 'N' then NULL
       ELSE RANK () OVER(
       PARTITION BY customer_id,member
        ORDER BY order_date) END AS ranking
FROM newt;















