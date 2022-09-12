#Create Database
create database instacart;

#Use instacart to create Tables
use instacart;

#Create Aisles table
create table aisles
(aisle_id int not null,
aisle varchar(100) not null,
primary key (aisle_id));

#Create Departments table
create table departments
(department_id int not null,
department varchar(25) not null,
primary key (department_id));

#Create Orders table
create table orders
(order_id int not null,
user_id int not null,
order_number int not null,
order_dow int not null,
order_hour_of_day int not null,
days_since_prior int not null,
primary key (order_id));

#Create Products table
create table products
(product_id int not null,
product_name varchar(150) not null,
aisle_id int not null,
department_id int not null,
primary key(product_id),
foreign key(aisle_id) references aisles(aisle_id),
foreign key(department_id) references departments(department_id));

#Create Orders_Product table
create table order_products
(order_id int not null,
product_id int not null,
add_to_cart_order int not null,
reordered char(1),
primary key (order_id, product_id),
foreign key (order_id) references orders(order_id),
foreign key (product_id) references products(product_id));



