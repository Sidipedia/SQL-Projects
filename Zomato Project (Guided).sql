-- A guided project done by me to practice my learnings of SQL. Most of the questions have been answered without any help. I have marked the questions that I have
-- struggled with. 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- The schema used for this analysis is given below

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. What is the total amount each customer spent on zomato?

      select userid, sum(product.price) as total_amount from sales
      inner join product on 
      sales.product_id = product.product_id
      group by userid

-- 2. How many days has each customer visited Zomato?

      select userid, count(distinct created_date) as days_visited from sales
      group by userid

-- 3. What was the first product purchased by each customer?

-- First Method - CTE + INNER JOIN

      with cte as (select userid, min(created_date) as first_date from sales
      group by userid)

      select cte.*, sales.product_id from cte
      inner join sales on 
      cte.first_date = sales.created_date

-- Second Method - RANK()

      select * from
      (select userid, created_date, product_id, 
      rank() over (partition by userid order by created_date) as rn from sales) b
      where rn = 1

-- 4.1 What is the most purchased item on the menu?

      select product_id, count(product_id) as sale_count from sales
      group by product_id
      order by sale_count desc

-- 4.2 How many times was it purchased by each user? (Product_id = 2 can be substituted with a subqury as well)

      select userid, count(product_id) as count_purchase from sales
      where product_id = 2
      group by userid

-- 5. Which item was most popular for each customer? (Could not solve)

-- Three step process -- Step 1. Write a query to find the count of products along with user id and product id

      select userid, product_id, count(product_id) as count_products from sales
      group by userid, product_id

-- Step 2. - Give a rank to the count from above query by using the above query as subquery 

      select * , rank() over (partition by userid order by count_products desc) as rank_products
      from
      (select userid, product_id, count(product_id) as count_products from sales
      group by userid, product_id) as a

-- Step 3. Finally filter the above query using a where statement. This is done using another subquery.
-- Remember to give alias to each subquery

      select * from 
      (select * , rank() over (partition by userid order by count_products desc) as rank_products
      from
      (select userid, product_id, count(product_id) as count_products from sales
      group by userid, product_id) as a) b
      where rank_products = 1

-- 6. Which item was purchased first by the customer after they became a gold member

-- Simple question with a twist - The order needs to be purchased AFTER the purchase of gold membership
-- The inital query is a inner join between gold_signup and sales with a where condition satisfying the twist
-- A simple rank() function is used to get the first product

select * from

(select gs.userid, gs.gold_signup_date, sales.created_date, sales.product_id,
rank() over (partition by gs.userid order by sales.created_date) as rn
from goldusers_signup gs
inner join sales
on gs.userid = sales.userid
where sales.created_date >= gs.gold_signup_date) as a

where rn = 1
