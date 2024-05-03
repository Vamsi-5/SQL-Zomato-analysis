-- Create goldusers_signup table
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

-- insert alues into it
INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

-- Create users table
CREATE TABLE users(userid integer,signup_date date); 

-- Insert values into users table
INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

-- Create sales table
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

-- Insert values into sales table
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


-- create product table
CREATE TABLE product(product_id integer,product_name text,price integer); 

-- insert values into product table
INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

-- View the tables
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- What is the total amount each customer spent on Zomato
SELECT S.userid, SUM(P.price) AS sum_of_price FROM sales AS S INNER JOIN product AS P ON S.product_id = P.product_id GROUP BY S.userid;

-- How many days each customer visited zomato
SELECT userid,COUNT(DISTINCT created_date) AS distinct_days FROM sales GROUP BY userid;

-- What was first product purchased by each customer
SELECT * FROM (
SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) AS rank FROM sales) AS A WHERE rank=1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT userid,COUNT(product_id) AS no_of_times_purchased FROM sales WHERE product_id = (
SELECT TOP 1 product_id FROM sales GROUP BY product_id ORDER BY COUNT(product_id) DESC)
GROUP BY userid;

-- Which item was the most popular for each customer?
SELECT * FROM
(SELECT *,RANK() OVER(PARTITION BY userid ORDER BY cnt DESC) AS rank FROM
(SELECT userid,product_id,COUNT(product_id) AS cnt FROM sales GROUP BY userid,product_id)A)B WHERE rank = 1;

-- Which item was first purchased by the customer after they first became user
SELECT * FROM goldusers_signup;
SELECT * FROM sales;

SELECT * FROM
(SELECT * , RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) AS rank FROM
(SELECT U.userid,S.product_id,S.created_date,U.gold_signup_date FROM sales AS S INNER JOIN goldusers_signup AS U ON S.userid = U.userid WHERE S.created_date > U.gold_signup_date)AS A)AS B WHERE rank=1;

-- Which item was purchased just before user became a member
SELECT * FROM 
(SELECT *,RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) AS rank FROM 
(SELECT U2.userid , S.product_id,S.created_date,U1.gold_signup_date FROM Sales AS S INNER JOIN goldusers_signup AS U1 ON S.userid = U1.userid INNER JOIN users AS U2 ON U1.userid = U2.userid WHERE S.created_date > U2.signup_date AND S.created_date < U1.gold_signup_date)AS A)AS B WHERE rank=1;

-- What is the total orders and amount spent for each member before they became member
SELECT U.userid ,COUNT(P.product_id) AS order_purchased,SUM(P.price) AS sum_price FROM goldusers_signup AS U INNER JOIN sales AS S ON U.userid = S.userid INNER JOIN product AS P ON S.product_id = P.product_id WHERE S.created_date <= U.gold_signup_date GROUP BY U.userid; 

-- If buying each product generates points for eg 5rs=2 zomato point and each product has different
-- purchasing points. For eg for p1 5rs = 1 zomato point,for p2 10rs=5 zomato point and p3 5rs=1 zomato point
SELECT * FROM product;
SELECT * FROM sales;

SELECT userid , total_points*2.5 AS total_money_earned FROM
(SELECT userid,SUM(points) AS total_points FROM
(SELECT * ,(sum/zomato_point) AS points FROM 
(SELECT *,zomato_point=
CASE
WHEN product_id=1 THEN 5
WHEN product_id=2 THEN 2
WHEN product_id=3 THEN 5
END 
FROM 
(SELECT S.userid,P.product_id,SUM(P.price) AS sum FROM sales AS S INNER JOIN product AS P ON S.product_id = P.product_id GROUP BY S.userid,P.product_id) AS A) AS B) AS C GROUP BY userid) AS D;

-- Calculate points collected by each customers and for which product most points have been given till now.
SELECT *,RANK() OVER(ORDER BY total_points DESC) AS rnk FROM
(SELECT product_id,SUM(points) AS total_points FROM
(SELECT * ,(sum/zomato_point) AS points FROM 
(SELECT *,zomato_point=
CASE
WHEN product_id=1 THEN 5
WHEN product_id=2 THEN 2
WHEN product_id=3 THEN 5
END 
FROM 
(SELECT S.userid,P.product_id,SUM(P.price) AS sum FROM sales AS S INNER JOIN product AS P ON S.product_id = P.product_id GROUP BY S.userid,P.product_id) AS A) AS B) AS C GROUP BY product_id) AS D;

-- In he first one year after a customer join the gold program including their join date irrespective of what the customer has purchased
-- they earn 5 zomato pointsforevery 10rs spent who earned more 1 or 3. What was their points earnings in their first year?
-- 1 zomato point = 2rs so 1 RS = 0.5 zomato points 
SELECT U.userid,S.created_date,S.product_id,(P.price*0.5) AS total_points,U.gold_signup_date FROM goldusers_signup AS U INNER JOIN sales AS S ON U.userid = S.userid INNER JOIN product AS P ON P.product_id = S.product_id WHERE S.created_date >= U.gold_signup_date AND YEAR(S.created_date) <= YEAR(U.gold_signup_date)+1;

-- Rank all the transactions of the customers
SELECT * , RANK() OVER(PARTITION BY userid ORDER BY created_date ASC) AS rank FROM sales;

-- Rank all the transactions for whenever the user has zomato gold membership and rank as na if they don't have any gold membership.
SELECT *,CASE WHEN rankfunction = 0 THEN 'NA' ELSE rankfunction END AS rnkk FROM
(SELECT *, rankfunction=
CAST((CASE
WHEN gold_signup_date IS NULL THEN 0
ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date ASC)
END) AS VARCHAR)
FROM
(SELECT A.userid,A.created_date,A.product_id,B.gold_signup_date FROM Sales AS A LEFT JOIN
goldusers_signup AS B ON A.userid = B.userid AND created_date >= gold_signup_date) AS A) AS B; 