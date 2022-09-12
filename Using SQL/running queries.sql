use instacart;

# 1. Which products are most often ordered?
with t1 as 
(select op.product_id, product_name,
	count(distinct order_id) as NumberOrdered
from products p join order_products op on (p.product_id = op.product_id)
group by product_id
order by NumberOrdered desc),
t2 as
(select sum(NumberOrdered) as TotalOrderedProducts
from t1)
select product_id, product_name, NumberOrdered,
	round(100 * (NumberOrdered / TotalOrderedProducts), 2) as Pct
from t1, t2
limit 14;

/**There are 14 products that were ordered over 100 times**/
/**Bananas were by far the largest product ordered (top 2)**/

# 2. Which aisle’s products are most often ordered? 
with t1 as
(select p.aisle_id, aisle,
	count(distinct order_id) as NumberOrdered
from products p join order_products op on (p.product_id = op.product_id)
	join aisles a on (a.aisle_id = p.aisle_id)
group by aisle_id
order by NumberOrdered desc),
t2 as
(select sum(NumberOrdered) as TotalOrderedProducts
from t1)
select aisle_id, aisle, NumberOrdered,
	round(100 * (NumberOrdered / TotalOrderedProducts), 2) as Pct
from t1, t2
limit 3;

/**3 aisles have had products ordered over 1000 times**/
/**fruit aisles are by far the most popular**/

# 3. Which department’s products are most often ordered?
with t1 as
(select p.department_id, department,
	count(distinct order_id) as NumberOrdered
from products p join order_products op on (p.product_id = op.product_id)
	join departments d on (d.department_id = p.department_id)
group by department_id
order by NumberOrdered desc),
t2 as
(select sum(NumberOrdered) as TotalOrderedProducts
from t1)
select department_id, department, NumberOrdered,
	round(100 * (NumberOrdered / TotalOrderedProducts), 2) as Pct
from t1, t2;

/**The top 6 departments had over 1000 products ordered**/
/**produce and dairy eggs each led with over 28% of the products ordered**/

# 4. The top ordered products in each department.
select product_id, product_name, department_id, department,
	max(NumberOrdered) as HighestOrdered
from 
	(select p.product_id, product_name, p.department_id, department, 
		count(distinct order_id) as NumberOrdered
	from products p join order_products op on (p.product_id = op.product_id)
		join departments d on (d.department_id = p.department_id)
	group by product_id
	order by NumberOrdered desc) as TopProducts
group by department_id;

/**every department has at least 3 product that has been ordered**/

# 5. The top ordered product at each aisle.
select product_id, product_name, aisle_id, aisle,
	max(NumberOrdered) as HighestOrdered
from 
	(select p.product_id, product_name, p.aisle_id, aisle, 
		count(distinct order_id) as NumberOrdered
	from products p join order_products op on (p.product_id = op.product_id)
		join aisles a on (a.aisle_id = p.aisle_id)
	group by product_id
	order by NumberOrdered desc) as TopProducts
group by aisle_id;

/**every aisle has at least 1 product that has been ordered**/

# 6. Most frequent customers
select user_id,
	max(order_number) as TimesOrdered
from orders
group by user_id
having max(order_number) > 99
order by TimesOrdered desc;

/**There are 21 users who have 100 orders which is the maximum order amount**/

# 7. From the top customers, who had the most days between placing orders
select user_id, order_number, 
	max(days_since_prior) as MostDaysBetweenOrders
from orders
where user_id in
	(select user_id
	from orders
	group by user_id
	having max(order_number) > 99)
group by user_id
order by MostDaysBetweenOrders desc;

/**only 2 top customers waited more than a week to place another order**/
/** 2 customers placed orders for 100 straight days (Not plausible)**/

#ETHAN WORK

/*** Midnight starts at 0 and is on a 24 hour clock**/
/** Most orders come between 10am and 2pm with 12pm having the most orders**/


# 8. What product is most often put in the shopping cart first
select op.product_id, product_name, count(order_id) as TimesGrabbedFirst
from order_products op join products p on (p.product_id = op.product_id)
where add_to_cart_order = '1'
group by op.product_id
having count(order_id) > 20
order by count(order_id) desc;

# 9. Ratio of Purchased Organic and Non-organic products
with t1 as
(select sum(nonorganic_products) as Total_nonOrganic,
	sum(distinct_nonorganic_products) as Total_distinct_NonOrganic
from
	(select product_name, count(op.product_id) as nonorganic_products,
		count(distinct op.product_id) as distinct_nonorganic_products
	from products p join order_products op on p.product_id = op.product_id
		join orders o on o.order_id = op.order_id
	where product_name not like '%organic%'
	group by product_name
	order by count(product_name) desc) as nonorganic),
t2 as
(select sum(organic_products) as Total_Organic,
	sum(distinct_organic_products) as Total_distinct_Organic
from
	(select product_name, count(op.product_id) as organic_products,
		count(distinct op.product_id) as distinct_organic_products
	from products p join order_products op on p.product_id = op.product_id
		join orders o on o.order_id = op.order_id
	where product_name like '%organic%'
	group by product_name
	order by count(product_name) desc) as organic)
select Total_nonOrganic, 
	round(100 * (Total_nonOrganic / (Total_nonOrganic + Total_Organic)), 2) as Pct, 
	Total_Organic,
	round(100 * (Total_Organic / (Total_nonOrganic + Total_Organic)), 2) as Pct,
    Total_distinct_NonOrganic, 
	round(100 * (Total_distinct_NonOrganic / (Total_distinct_NonOrganic + Total_distinct_Organic)), 2) as Pct, 
	Total_distinct_Organic,
	round(100 * (Total_distinct_Organic / (Total_distinct_NonOrganic + Total_distinct_Organic)), 2) as Pct
    from t1, t2;
	
# 10. Which products are reordered the most?
select op.product_id, product_name, sum(reordered)
from order_products op join products p on op.product_id = p.product_id
group by product_id
order by sum(reordered) desc
limit 10;
#This is the top ten reordered products

# 11. What aisle's products are reordered the most?
select product_id, product_name, aisle_id, max(ReOrdered) as Hightest
from	
    (select p.product_name, p.product_id, a.aisle_id, sum(reordered) as ReOrdered
	from order_products op join products p on op.product_id = p.product_id
		join aisles a on a.aisle_id = p.aisle_id
	group by product_id
	order by sum(reordered) desc) as Reordered
group by aisle_id;
#This shows each aisle's most often reordered item

# 12. Which department's products are most often reordered?
select product_id, product_name, department_id, max(Reordered) as Highest
from     
    (select p.product_name, p.product_id, d.department_id, sum(reordered) as Reordered
	from products p join departments d on p.department_id = d.department_id
		join order_products op on p.product_id = op.product_id
	group by product_id
	order by sum(reordered) desc) as Reordered
group by department_id;

# 13. Average day between orders for all users    
select round(avg(days_since_prior),2) as AvgDays
from orders;

# 14. Average day between orders for Top Users
select round(avg(days_since_prior),2) as AvgDays
from 
	(select user_id, days_since_prior
	from orders
	group by user_id
	having max(order_number) > 99) as TopUsers;
 
# 15. Number of Orders by Day-Hour
with t1 as
(select order_dow as Day, order_hour_of_day as Hour,
	count(order_number) as NumberofOrders
from orders
group by order_dow, order_hour_of_day
order by NumberofOrders),
t2 as
(select sum(NumberOfOrders) as TotalOrders
from t1)
select Day, Hour, t1.NumberofOrders,
	round(100 * (NumberofOrders / TotalOrders), 2) as Pct
from t1, t2
group by Day, Hour
order by NumberofOrders desc;

# 16. Comparison between daytime(8am-5pm) and nighttime(6pm-7am)
with t1 as
(select sum(Orders) as Total_Orders_Day
from
	(select order_hour_of_day, 
		count(distinct order_id) Orders
	from orders
	where order_hour_of_day in (8,9,10,11,12,13,14,15,16,17)
	group by order_hour_of_day) as hours),
t2 as    
(select sum(Orders) as Total_Orders_Night
from
	(select order_hour_of_day, 
		count(distinct order_id) Orders
	from orders
	where order_hour_of_day in (0,1,2,3,4,5,6,7,18,19,20,21,22,23)
	group by order_hour_of_day) as hours)
select Total_Orders_Day, 
	round(100 * (Total_Orders_Day / (Total_Orders_Day + Total_Orders_Night)), 2) as Pct, 
	Total_Orders_Night,
	round(100 * (Total_Orders_Night / (Total_Orders_Day + Total_Orders_Night)), 2) as Pct
from t1, t2;

# 17. Weekend vs Weekday
with t1 as
(select sum(weekday_order) as weekday_total
from 
	(select order_dow, count(order_dow) as weekday_order
	from orders
	where order_dow = 6 or order_dow =2 or order_dow =3 or order_dow =4 or order_dow=5
	group by order_dow) as weekday_amount),
t2 as 
(select sum(weekend_order) as weekend_total
from 
	(select order_dow, count(order_dow) as weekend_order
	from orders
	where order_dow = 1 or order_dow =0
	group by order_dow) as weekend_amount)
select weekday_total, round(100 * (weekday_total / (weekday_total + weekend_total)), 2) as Pct,  weekend_total,
	round(100 * (weekend_total / (weekday_total + weekend_total)), 2) as Pct2
from t1,t2;

