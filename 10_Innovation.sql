-- =============================================
-- PointPay Database
-- Innovation Demonstration
-- Reward Points Redemption System
-- =============================================

USE PointPay;
GO

/*==========================================================
Innovation

Reward Points Redemption System

This innovation allows an employee to redeem reward
points from their wallet.

Business Rules:
1. Wallet must exist.
2. Redemption points must be greater than zero.
3. Employee must have sufficient wallet balance.
4. A Redeem transaction is automatically recorded.
==========================================================*/


/*==========================================================
STEP 1
View Current Wallet Balance
==========================================================*/

SELECT
    W.WalletID,
    E.FullName,
    dbo.udf_GetWalletBalance(W.WalletID) AS CurrentBalance
FROM Wallets W
INNER JOIN Employees E
    ON W.EmployeeID = E.EmployeeID
WHERE W.WalletID = 1;

GO


/*==========================================================
STEP 2
Redeem 500 Reward Points
==========================================================*/

EXEC sp_RedeemPoints
    @WalletID = 1,
    @Points = 500;

GO


/*==========================================================
STEP 3
View Updated Wallet Balance
==========================================================*/

SELECT
    W.WalletID,
    E.FullName,
    dbo.udf_GetWalletBalance(W.WalletID) AS UpdatedBalance
FROM Wallets W
INNER JOIN Employees E
    ON W.EmployeeID = E.EmployeeID
WHERE W.WalletID = 1;

GO


/*==========================================================
STEP 4
View Newly Created Redeem Transaction
==========================================================*/

SELECT TOP 5
    TransactionID,
    WalletID,
    EmployeeID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus,
    CreatedAt
FROM WalletTransactions
WHERE WalletID = 1
ORDER BY TransactionID DESC;

GO


/*==========================================================
STEP 5
Validation Test

Attempt to redeem more points than available.

Expected Result:
"Insufficient wallet balance."
==========================================================*/

EXEC sp_RedeemPoints
    @WalletID = 1,
    @Points = 999999;

GO


/*==========================================================
STEP 6
Final Wallet Balance

Balance should remain unchanged after the failed
redemption attempt.
==========================================================*/

SELECT
    W.WalletID,
    E.FullName,
    dbo.udf_GetWalletBalance(W.WalletID) AS FinalBalance
FROM Wallets W
INNER JOIN Employees E
    ON W.EmployeeID = E.EmployeeID
WHERE W.WalletID = 1;

GO
