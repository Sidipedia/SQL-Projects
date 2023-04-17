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

      SELECT userid ,SUM(product.price) AS total_amount
      FROM sales
      INNER JOIN product ON sales.product_id = product.product_id
      GROUP BY userid

-- 2. How many days has each customer visited Zomato?

      SELECT userid ,COUNT(DISTINCT created_date) AS days_visited
      FROM sales
      GROUP BY userid

-- 3. What was the first product purchased by each customer?

    -- First Method - CTE + INNER JOIN

      WITH cte AS 
      (SELECT userid ,MIN(created_date) AS first_date
      FROM sales GROUP BY userid)
      
      SELECT cte.*, sales.product_id FROM cte
      INNER JOIN sales ON cte.first_date = sales.created_date

    -- Second Method - RANK()

      SELECT * FROM
      (SELECT userid, created_date, product_id, 
      RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rn FROM sales) b
      WHERE rn = 1

-- 4.1 What is the most purchased item ON the menu?

      SELECT product_id, count(product_id) AS sale_count FROM sales
      GROUP BY product_id
      ORDER BY sale_count DESC

-- 4.2 How many times was it purchased BY each user? (Product_id = 2 can be substituted with a subqury AS well)

      SELECT userid, count(product_id) AS count_purchase FROM sales
      WHERE product_id = 2
      GROUP BY userid

-- 5. Which item was most popular for each customer? (Could not solve)

    -- Three step process -- Step 1. Write a query to find the count of products along with user id and product id

      SELECT userid, product_id, count(product_id) AS count_products FROM sales
      GROUP BY userid, product_id

    -- Step 2. - Give a RANK to the count FROM above query BY using the above query AS subquery 

      SELECT * , RANK() OVER (PARTITION BY userid ORDER BY count_products DESC) AS rank_products
      FROM
      (SELECT userid, product_id, count(product_id) AS count_products FROM sales
      GROUP BY userid, product_id) AS a

    -- Step 3. Finally filter the above query using a WHERE statement. This is done using another subquery.
    -- Remember to give alias to each subquery

      SELECT * FROM 
      (SELECT * , RANK() OVER (PARTITION BY userid ORDER BY count_products DESC) AS rank_products
      FROM
      (SELECT userid, product_id, count(product_id) AS count_products FROM sales
      GROUP BY userid, product_id) AS a) b
      WHERE rank_products = 1

-- 6. Which item was purchased first BY the customer after they became a gold member?

    -- Simple question with a twist - The ORDER needs to be purchased AFTER the purchase of gold membership
    -- The inital query is a INNER JOIN between gold_signup and sales with a WHERE condition satisfying the twist
    -- A simple RANK() function is used to get the first product

      SELECT * FROM

      (SELECT gs.userid, gs.gold_signup_date, sales.created_date, sales.product_id,
      RANK() OVER (PARTITION BY gs.userid ORDER BY sales.created_date) AS rn
      FROM goldusers_signup gs
      INNER JOIN sales
      ON gs.userid = sales.userid
      WHERE sales.created_date >= gs.gold_signup_date) AS a

      WHERE rn = 1

-- 7. Which item was purchased just before the customer became a gold member?

    -- Similar to last question. The created_date should be <= gold_signup_date 
    -- Order of RANK needs to be changed to DESC

      SELECT * FROM 

      (SELECT gs.userid, gs.gold_signup_date, sales.created_date, sales.product_id,
      RANK() OVER (PARTITION BY gs.userid ORDER BY sales.created_date DESC) AS rn
      FROM goldusers_signup gs
      INNER JOIN sales
      ON gs.userid = sales.userid
      WHERE sales.created_date <= gs.gold_signup_date) AS a

      WHERE rn = 1

-- 8. What is the total orders and amount spent for each member before they became a gold member?

    -- I have opted for join method to solve the question. 
    -- To get the amount for the members before joining, the created_date needs to be less than the gold_signup_date

      SELECT sales.userid, COUNT(sales.product_id) as total_products, SUM(product.price) as total_price
      FROM sales
      LEFT JOIN product ON sales.product_id = product.product_id
      INNER JOIN goldusers_signup gs ON gs.userid = sales.userid
      WHERE sales.created_date < gs.gold_signup_date
      GROUP BY sales.userid

-- 9. If buying each product generates points (For Ex - Rs 5 = 2 zomato points) and each product has different points 
--    (P1 - Rs 5 = 1 point | P2 - Rs 10 = 5 points | P3 - Rs 5 = 1 point) Calculate:
--    a. Points collected by each customer
--    b. The product which generated the maximum points. 

    -- Part A
    -- The first part requires us to calculate the points as per the formula given in the question
    -- I have done the calculation on the product table itself using a simple CASE WHEN statement 
    -- This calcualtion is stored in a CTE expression and later used to derive the required answer

      WITH product_cte AS
      (SELECT *, CASE 
      WHEN product_name LIKE 'p1' THEN price/5 
      WHEN product_name LIKE 'p2' THEN (price/10)*5
      WHEN product_name LIKE 'p3' THEN price/5 
      END AS points FROM product)

      SELECT sales.userid, SUM(product_cte.points) as total_points FROM sales
      INNER JOIN product_cte ON sales.product_id = product_cte.product_id
      GROUP BY sales.userid
      
    -- Part B
    -- To solve this, simple replace sales.userid from the last query to sales.product_id
    -- TOP function is used as the queries were generated on SSMS. LIMIT can be used for other versions of SQL
    
      WITH product_cte AS
      (SELECT *, CASE 
      WHEN product_name LIKE 'p1' THEN price/5 
      WHEN product_name LIKE 'p2' THEN (price/10)*5
      WHEN product_name LIKE 'p3' THEN price/5 
      END AS points FROM product)

      SELECT TOP 1 sales.product_id, SUM(product_cte.points) as total_points FROM sales
      INNER JOIN product_cte ON sales.product_id = product_cte.product_id
      GROUP BY sales.product_id
      ORDER BY total_points DESC

-- 10. 
