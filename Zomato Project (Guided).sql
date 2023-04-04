-- A guided project done by me to practice my learnings of SQL. Most of the questions have been answered without any help. I have marked the questions that I have
-- struggled with. 

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
