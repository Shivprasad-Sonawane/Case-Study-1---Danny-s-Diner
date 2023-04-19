
-- What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id


-- How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as visited
from sales
group by customer_id


-- What was the first item from the menu purchased by each customer?
select s.customer_id, m.product_name
from sales s join menu m
on s.product_id = m.product_id
where order_date = (select min(order_date) from sales) 
group by s.customer_id, m.product_name, s.product_id


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select top(1) m.product_name, count(s.product_id) as purchase_count
from sales s join menu m
on s.product_id = m.product_id
group by m.product_name
order by purchase_count desc


-- Which item was the most popular for each customer?
select customer_id, product_name
from 
(select s.customer_id, m.product_name,
rank() over(partition by customer_id order by count(s.product_id) desc) as purchase_rank
from sales s join menu m
on s.product_id = m.product_id
group by s.customer_id, m.product_name) most_purchase
where purchase_rank = 1


-- Which item was purchased first by the customer after they became a member?
select customer_id, m.product_name
from
(select s.customer_id, s.product_id, s.order_date,
rank() over(partition by s.customer_id order by s.order_date) as order_rank
from sales s join members mem 
on s.customer_id = mem.customer_id
where s.order_date >= mem.join_date) member_list join menu m
on member_list.product_id = m.product_id
where order_rank = 1


-- Which item was purchased just before the customer became a member?
select customer_id, m.product_name
from
(select s.customer_id, s.product_id, s.order_date,
rank() over(partition by s.customer_id order by s.order_date desc) as order_rank
from sales s join members mem 
on s.customer_id = mem.customer_id
where s.order_date < mem.join_date) member_list join menu m
on member_list.product_id = m.product_id
where order_rank = 1


-- What is the total items and amount spent for each member before they became a member?
select s.customer_id as customer, count(s.product_id) as total_item, sum(m.price) as total_amount_spent
from sales s join members mem
on s.customer_id = mem.customer_id join menu m
on s.product_id = m.product_id
where s.order_date < mem.join_date
group by s.customer_id


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select s.customer_id as customer,
sum(case when m.product_name = 'sushi' then (m.price*20) else (m.price*10) end) as customer_points
from sales s join menu m
on s.product_id = m.product_id
group by customer_id


-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
select m.customer_id as customer,
sum(case when s.order_date < m.join_date then 
		case when mem.product_name = 'sushi' then (mem.price * 20) else (mem.price * 10) end
			when s.order_date > dateadd(day, 6, m.join_date) then 
		case when mem.product_name = 'sushi' then (mem.price * 20) else (mem.price * 10) end
	else (mem.price * 20) end) as member_points
from members as m join sales as s 
on s.customer_id = m.customer_id join menu as mem
on s.product_id = mem.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY m.customer_id


--Bonus Questions

-- Join All The Things
select s.customer_id, s.order_date, m.product_name, m.price,
case when s.customer_id in (mem.customer_id) and s.order_date >= mem.join_date then 'Y' else 'N' end as member
from sales s left join menu m
on s.product_id = m.product_id left join members mem
on s.customer_id = mem.customer_id

-- Rank All The Things
select *,
case when member = 'Y' then rank() over(partition by m.customer, member order by order_date) else null end
from 
(select s.customer_id as customer, s.order_date, m.product_name, m.price,
case when s.customer_id in (mem.customer_id) and s.order_date >= mem.join_date then 'Y' else 'N' end as member
from sales s left join menu m
on s.product_id = m.product_id left join members mem
on s.customer_id = mem.customer_id) m
