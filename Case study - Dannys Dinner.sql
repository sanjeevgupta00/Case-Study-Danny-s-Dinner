CREATE TABLE menu (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(5),
  price INTEGER
);


CREATE TABLE members (
  customer_id VARCHAR(1) PRIMARY KEY,
  join_date DATE
);


CREATE TABLE sales (
  customer_id VARCHAR(1) ,
  order_date DATE,
  product_id INT
);


INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

--Display tables
select* From members

Select * From menu

Select * From Sales


--Solutions
--1.Total amount spend by each customer

select s.customer_id,sum(m.price)
from sales as s 
join menu as m 
on s.product_id=m.product_id
group by s.customer_id
order by s.customer_id;


--2. ow many days has each customer visited the restaurant?

select customer_id, count(distinct order_date)
from sales
group by customer_id;


--3. What was the first item from the menu purchased by each customer?

with purchase_rank as 
	(select s.customer_id, m.product_name, 
	 rank() over (partition by s.customer_id order by s.order_date) as P_rank
	 from sales as s
	 join menu as m 
	 on s.product_id=m.product_id
	 order by s.order_date)

select customer_id, product_name 
from purchase_rank 
where P_rank=1
group by customer_id, product_name, p_rank;


--4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(s.product_id) as purchase_count
from menu as m
join sales as s
on m.product_id=s.product_id
group by m.product_name
order by count(s.product_id) desc
limit 1;


--5.Which item was the most popular for each customer?

with purchase_rank as 
	(select s.customer_id, m.product_name , 
	dense_rank() over (partition by s.customer_id order by count(s.product_id) DESC) as p_rank
	from sales as s 
	join menu as m
	on m.product_id=s.product_id
	group by s.customer_id, m.product_name)
select customer_id, product_name 
from purchase_rank
where p_rank=1


--6. Which item was purchased first by the customer after they became a member?

with membership_customers as 
	(select me.customer_id, m.product_name,
	dense_rank() over (partition by me.customer_id order by s.order_date) as order_series
	from members as me
	left join sales as s 
	 on me.customer_id=s.customer_id
	join menu as m 
	 on s.product_id=m.product_id
	where s.order_date>= me.join_date
	group by me.customer_id, m.product_name, s.order_date)
	
select customer_id, product_name
from membership_customers
where order_series=1


--7. Which item was purchased just before the customer became a member?

with membership_customers as 
	(select me.customer_id, m.product_name,
	rank() over (partition by me.customer_id order by s.order_date DESC) as order_series
	from members as me
	left join sales as s 
	 on me.customer_id=s.customer_id
	join menu as m 
	 on s.product_id=m.product_id
	where s.order_date<me.join_date
	group by me.customer_id, m.product_name, s.order_date)
	
select customer_id, product_name
from membership_customers
where order_series=1


--8. What is the total items and amount spent for each member before they became a member?

select me.customer_id, count(s.product_id) as item_count,sum(m.price) as amount_spent
from members as me
left join sales as s 
on me.customer_id=s.customer_id
join menu as m 
on s.product_id=m.product_id
where s.order_date<= me.join_date
group by me.customer_id


--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
with points as
	(select product_name,product_id,
	 case
	 when product_name='sushi' then price*10*2
	 else price*10
	 end as point
	 from menu
	)
select s.customer_id, sum(p.point)
from sales as s
join points as p
on s.product_id=p.product_id
group by s.customer_id
order by s.customer_id
	

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
with points as 
	(select me.customer_id, m.product_name,m.product_id,s.order_date,
	 case
	 when m.product_name='sushi' then m.price*10*2
	 else 
	 	case 
	 	when s.order_date between me.join_date and me.join_date + INTERVAL '7 days' then m.price*10*2
	 	else m.price*10
	 	end
	 end as point
	 from members as me
	left join sales as s on me.customer_id=s.customer_id
	join menu as m on m.product_id=s.product_id
	)
select p.customer_id, sum(p.point)
from points as p
where p.order_date<='2021-01-31'
group by p.customer_id
order by p.customer_id
	
	