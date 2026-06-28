# STEP 1 - Create Database

FILE  - **01_Create_Database.sql**

What this does :

### CREATE DATABASE PointPay;
### USE PointPay;

Creates the PointPay Database and switches to the current database.

Every table, view, trigger, function and procedure created afterwards will belong to PointPay instead of master which is SQL Server's default database.


# STEP 2 - Create Tables

FILE - **02_Create_Tables.sql**

What this does :

### CREATE TABLE Employees
Creates the Employees table to store employee account, login, and profile information.

### CREATE TABLE Wallets
Creates the Wallets table and establishes a one-to-one relationship between each employee and their wallet.

### CREATE TABLE Products
Creates the Products table to store the product catalogue, pricing, stock quantity, and availability.

### CREATE TABLE Orders
Creates the Orders table to store purchase information, payment details, order status, and order history.

### CREATE TABLE WalletTransactions
Creates the WalletTransactions table to record all wallet credits, debits, refunds, and point transactions.

### CREATE TABLE OrderItems
Creates the OrderItems table to store individual products associated with each order, including quantity and purchase prices.

### CREATE TABLE Returns
Creates the Returns table to manage return requests, approvals, and refund information.

### Constraints Implemented
- Primary Keys (PK)
- Foreign Keys (FK)
- Unique Constraints
- Check Constraints
- Default Constraints

This script also establishes the relationships between all seven tables and enforces referential integrity using primary keys, foreign keys, and additional constraints.
