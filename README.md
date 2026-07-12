# PointPay Database Project
**Project Overview**

PointPay is a SQL Server-based Employee Rewards Management System developed as part of the Advanced Database assignment. The system enables employees to purchase rewards using cash, reward points, or a combination of both, while allowing administrators to manage products, employee wallets, orders, and return requests.

The project demonstrates the design and implementation of a fully relational database by applying database normalisation principles, referential integrity, and business rule enforcement. The database follows Third Normal Form (3NF) to minimise data redundancy by storing only source data and calculating derived values dynamically whenever required.

The system is built using several SQL Server database objects, including:

**Tables** to store employees, wallets, products, orders, order items, wallet transactions and returns.
**Constraints** (Primary Keys, Foreign Keys, Unique, Check and Default Constraints) to maintain data integrity and enforce valid data.
**User Defined Functions (UDFs)** to calculate order totals, wallet balances and product availability.
**Triggers** to automatically update product stock, validate product availability and process refund transactions without manual intervention.
**Stored Procedures** to perform common business operations such as placing orders, approving returns and redeeming reward points while ensuring transactional consistency.
**Views** to simplify reporting by combining information from multiple related tables.
**XML** to demonstrate both importing and exporting structured data, including placing orders using XML input and generating XML reports.
**Innovation** in the form of a Reward Points Redemption System that extends the existing platform without modifying the database schema.

All SQL scripts are organised into separate files and should be executed sequentially. Each subsequent script depends on the successful execution of the previous one. This README describes the purpose of every script, the database objects it creates, and how each component contributes to the overall functionality of the PointPay database.


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


# STEP 3 - Insert Sample Data

FILE - **03_Insert_Data.sql**

What this does:

Populates the PointPay database with realistic sample data for testing
and demonstration purposes.

The data is inserted in the correct dependency order to satisfy all
foreign key constraints.

Tables populated:

1. Employees (50 Records)
   Fictional employee data using common U.S. Census names with SHA2-256
   hashed passwords.

2. Wallets (50 Records)
   One wallet assigned to each employee.

3. Products (50 Records)
   Employee reward catalogue inspired by publicly available reward
   platforms and retail product listings.

4. Orders (100 Records)
   Employee reward redemption orders spread across April–June 2026 with
   Completed, Pending and Cancelled statuses.

5. OrderItems
   Products associated with each order. These records represent the
   source of truth for order totals.

The monetary fields in the Orders table are intentionally initialised
to their default values. The final order totals are calculated
automatically later using a User Defined Function and Trigger.

Data Sources:

- U.S. Census Bureau – Frequently Occurring Surnames
- U.S. Social Security Administration – Popular Baby Names
- Product catalogue inspired by publicly available employee rewards
  platforms and approximate retail prices from Awardco, Reward Gateway,
  Amazon UK, Logitech, Dell, Apple, JBL and Anker.

All data is used for educational purposes only.



# STEP 4 - User Defined Functions

FILE - **04_User_Defined_Functions.sql**

What this does:

Creates reusable SQL Server User Defined Functions (UDFs) used
throughout the PointPay database.

Functions created:

1. udf_CalculateOrderTotal
   Calculates the total monetary value of an order by summing all
   products purchased.

2. udf_GetWalletBalance
   Calculates an employee's wallet balance using wallet transactions.

3. udf_IsProductAvailable
   Checks whether sufficient stock exists before allowing a purchase.

These functions are later used by triggers, stored procedures and
views to reduce code duplication and improve maintainability.

Test Queries:

```sql
SELECT dbo.udf_CalculateOrderTotal(1);

SELECT dbo.udf_GetWalletBalance(1);

SELECT dbo.udf_IsProductAvailable(1,2);
```

All functions were successfully tested after creation.


# STEP 5 - Create Triggers

FILE - **05_Triggers.sql**

What this does:

Creates SQL Server triggers that automatically enforce business rules and maintain data consistency within the PointPay database.

Triggers created:
1. trg_UpdateProductStock

Automatically updates product stock levels whenever order items are inserted, updated or deleted.

2. trg_CheckProductAvailability

Prevents inactive or out-of-stock products from being added to an order.

3. trg_ProcessApprovedReturn

Automatically creates a wallet refund transaction whenever a return request is approved. Refund values are calculated dynamically using the udf_CalculateOrderTotal() function based on the original order details.

These triggers automate inventory management, validate business rules and maintain data consistency without requiring manual intervention.

# STEP 6 - Insert Remaining Data

FILE - **06_Insert_Remaining_Data.sql**

What this does:

Completes the database by inserting the remaining operational data required by the PointPay rewards platform.

Data inserted:
1. Welcome Bonus Transactions

Every employee receives an initial reward points bonus.

2. Order Redemption Transactions

Employees who redeem rewards using Points or Mixed payment methods have reward points deducted automatically. Redemption values are calculated dynamically using the udf_CalculateOrderTotal() function.

3. Performance Bonus Transactions

Selected employees receive additional reward points based on predefined business rules.

4. Administrative Adjustment Transactions

Manual reward point adjustments are inserted for demonstration purposes.

5. Return Requests

Sample return requests are inserted with an initial Pending status.

6. Return Processing

Selected return requests are approved or rejected using UPDATE statements. When a return request is approved, the trigger trg_ProcessApprovedReturn automatically inserts the corresponding wallet refund transaction.

The PointPay platform uses a unified reward system where €1 = 10 reward points. All wallet transactions, including reward redemptions and refunds, are stored using reward points.

# STEP 7 - Stored Procedures

FILE - **07_Stored_Procedures.sql**

What this does:

Creates reusable SQL Server Stored Procedures used throughout the PointPay database.

Stored Procedures created:
1. sp_PlaceOrder

Creates a new order and inserts multiple order items from an XML document. Product prices are automatically retrieved from the Products table while inventory validation and stock updates are handled by database triggers.

2. sp_ApproveReturn

Approves a pending return request. Once approved, the trg_ProcessApprovedReturn trigger automatically creates the corresponding wallet refund transaction.

3. sp_RedeemPoints

Allows employees to redeem reward points from their wallet after validating that sufficient reward points are available.

These stored procedures centralise business logic, improve maintainability, reduce repetitive SQL code and ensure transactional consistency.

Test Queries
EXEC sp_PlaceOrder
    @EmployeeID = 1,
    @PaymentMethod = 'Mixed',
    @CashPaid = 150,
    @PointsUsed = 1000,
    @OrderStatus = 'Pending',
    @OrderItems = @OrderItems;

EXEC sp_ApproveReturn
    @ReturnID = 11,
    @ApprovedBy = 1;

EXEC sp_RedeemPoints
    @WalletID = 1,
    @Points = 500;

All stored procedures were successfully tested after creation.

# STEP 8 - Create Views

FILE - **08_Views.sql**

What this does:

Creates SQL Server Views that simplify reporting by combining information from multiple related tables.

Views created:
1. vw_EmployeeWalletSummary

Displays employee information together with their current wallet balance.

2. vw_OrderSummary

Displays order information together with dynamically calculated order totals using udf_CalculateOrderTotal().

3. vw_ProductInventory

Displays the product catalogue together with pricing information, stock levels and availability.

4. vw_ReturnSummary

Displays return requests together with employee and order information.

These views simplify reporting, reduce duplicate SQL queries and provide reusable datasets throughout the PointPay database.

Test Queries
SELECT * FROM vw_EmployeeWalletSummary;

SELECT * FROM vw_OrderSummary;

SELECT * FROM vw_ProductInventory;

SELECT * FROM vw_ReturnSummary;

All views were successfully tested after creation.

# STEP 9 - XML Demonstration

FILE - **09_XML.sql**

What this does:

Demonstrates SQL Server XML functionality for both importing and exporting data.

XML demonstrations:
1. XML Input

Creates a new order by passing multiple order items as an XML document to sp_PlaceOrder.

2. Orders as XML

Exports order information using FOR XML PATH.

3. Products as XML

Exports the product catalogue using FOR XML PATH.

4. Wallet Transactions as XML

Exports wallet transaction history using FOR XML PATH.

This demonstrates both XML parsing using SQL Server XML methods and XML generation using SQL Server's native XML functionality.

Test Queries
EXEC sp_PlaceOrder
    @EmployeeID = 1,
    @PaymentMethod = 'Mixed',
    @CashPaid = 150,
    @PointsUsed = 1000,
    @OrderStatus = 'Pending',
    @OrderItems = @OrderItems;

The XML import and export functionality was successfully tested.

# STEP 10 - Innovation

FILE - **10_Innovation.sql**

What this does:

Implements the Reward Points Redemption System as the innovation component of the PointPay database.

Innovation Demonstration:
1. View Wallet Balance

Displays the employee's wallet balance before redemption.

2. Redeem Reward Points

Executes sp_RedeemPoints to redeem reward points from the employee's wallet.

3. View Updated Wallet Balance

Displays the remaining wallet balance after redemption.

4. View Redeem Transaction

Displays the newly created Redeem transaction recorded in WalletTransactions.

5. Validation

Attempts to redeem more points than available to demonstrate business rule validation.

This feature extends the existing reward platform without requiring any modifications to the underlying database schema.

Test Queries
EXEC sp_RedeemPoints
    @WalletID = 1,
    @Points = 500;

The innovation was successfully tested and validated.

# STEP 11 - Testing

FILE - **11_Test_Queries.sql**

What this does:

Provides a comprehensive set of test queries that verify the functionality of all database objects created throughout the project.

Components Tested
Table Row Counts
User Defined Functions
Triggers
Primary Key Constraints
Foreign Key Constraints
Unique Constraints
Check Constraints
Stored Procedures
Views
XML Functionality
Innovation Feature
Final Database Summary

The testing script confirms that all business rules, constraints, stored procedures, views, XML functionality and innovation features operate correctly within the PointPay database.
