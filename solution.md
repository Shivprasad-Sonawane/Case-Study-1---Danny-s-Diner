# Questions and Answers
---
### 1. What is the total amount each customer spent at the restaurant?

```sql
select customer_id, sum(price) as total_amount
from sales s join menu m
on s.product_id = m.product_id
group by customer_id 
```
*Result:*
customer_id|total_amount|
-----------|------------|
A          |          76|
B          |          74|
C          |          36|
---
### 2. How many days has each customer visited the restaurant?
```sql
select customer_id, count(distinct order_date) as visited
from sales
group by customer_id
```
*Result:*
customer_id|visited     |
-----------|------------|
A          |          4 |
B          |          6 |
C          |          2 |
---
### 3. What was the first item from the menu purchased by each customer?
```sql
select s.customer_id, m.product_name
from sales s join menu m
on s.product_id = m.product_id
where order_date = (select min(order_date) from sales) 
group by s.customer_id, m.product_name, s.product_id
```
*Result:*
customer_id|product_name|
-----------|------------|
A          |      curry |
A          |       sushi|
B          |      curry |
C          |       ramen|

❗ *Note: Customer A purchased the product curry and sushi on the same day ie 2021-01-01*

---
### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
select top(1) m.product_name, count(s.product_id) as purchase_count
from sales s join menu m
on s.product_id = m.product_id
group by m.product_name
order by purchase_count desc
```
*Result:*
product_name|purchase_count|
------------|--------------|
ramen       |             8|
---
### 5. Which item was the most popular for each customer?
```sql
select customer_id, product_name
from 
(select s.customer_id, m.product_name,
rank() over(partition by customer_id order by count(s.product_id) desc) as purchase_rank
from sales s join menu m
on s.product_id = m.product_id
group by s.customer_id, m.product_name) most_purchase
where purchase_rank = 1
```
*Result:*
customer_id|product_name|
-----------|------------|
A          |      ramen |
B          |      sushi |
B          |      curry |
B          |      ramen |
C          |      ramen |
---
### 6. Which item was purchased first by the customer after they became a member?
```sql
select customer_id, m.product_name
from
(select s.customer_id, s.product_id, s.order_date,
rank() over(partition by s.customer_id order by s.order_date) as order_rank
from sales s join members mem 
on s.customer_id = mem.customer_id
where s.order_date >= mem.join_date) member_list join menu m
on member_list.product_id = m.product_id
where order_rank = 1
```
*Result:*
customer_id|product_name|
-----------|------------|
A          |     curry  |
B          |     sushi  |
---
### 7. Which item was purchased just before the customer became a member?
```sql
select customer_id, m.product_name
from
(select s.customer_id, s.product_id, s.order_date,
rank() over(partition by s.customer_id order by s.order_date desc) as order_rank
from sales s join members mem 
on s.customer_id = mem.customer_id
where s.order_date < mem.join_date) member_list join menu m
on member_list.product_id = m.product_id
where order_rank = 1
```
*Result:*
customer_id|product_name|
-----------|------------|
A          |     sushi  |
A          |     curry  |
B          |     sushi  |
---
### 8. What is the total items and amount spent for each member before they became a member?
```sql
select s.customer_id as customer, count(s.product_id) as total_item, sum(m.price) as total_amount_spent
from sales s join members mem
on s.customer_id = mem.customer_id join menu m
on s.product_id = m.product_id
where s.order_date < mem.join_date
group by s.customer_id
```
*Result:*
customer|total_item|total_amount_spent|
--------|----------|------------------|
A       |        2 |                25|
B       |        3 |                40|
---
### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
select s.customer_id as customer,
sum(case when m.product_name = 'sushi' then (m.price*20) else (m.price*10) end) as customer_points
from sales s join menu m
on s.product_id = m.product_id
group by customer_id
```
*Result:*
customer|customer_points|
--------|---------------|
A       |          860  |
B       |          940  |
C       |          360  |
---
## 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
## not just sushi - how many points do customer A and B have at the end of January?
```sql
select customer, sum(member_points) as member_points
from
(select s.customer_id as customer, count(s.product_id) as total_item,
case when m.product_name = 'sushi' then  count(s.product_id)*m.price*20
	 when m.product_name = 'curry' then  count(s.product_id)*m.price*20
	 when m.product_name = 'ramen' then  count(s.product_id)*m.price*20
	 else 0 end as member_points
from sales s join menu m
on s.product_id = m.product_id join members mem
on s.customer_id = mem.customer_id
where s.order_date >= mem.join_date and order_date <= '2021-01-31'
group by s.customer_id, m.product_name, m.price) mem_jan_points
group by customer
```
*Result:*
customer|member_points|
--------|-------------|
A       |       1020  |
B       |        440  |
