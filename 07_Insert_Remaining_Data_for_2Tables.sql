/*==========================================================
Wallet Transactions
Welcome Bonus
==========================================================*/

INSERT INTO WalletTransactions
(
    WalletID,
    EmployeeID,
    OrderID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus
)
SELECT
    WalletID,
    EmployeeID,
    NULL,
    'Credit',
    'Welcome Bonus',
    1000,
    'Completed'
FROM Wallets;

GO

/*==========================================================
Wallet Transactions
Points Redemption
==========================================================*/

INSERT INTO WalletTransactions
(
    WalletID,
    EmployeeID,
    OrderID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus
)
SELECT
    W.WalletID,
    O.EmployeeID,
    O.OrderID,
    'Debit',
    'Order Redemption',
    CAST(O.TotalAmount * 10 AS INT),
    'Completed'
FROM Orders O
JOIN Wallets W
ON O.EmployeeID = W.EmployeeID
WHERE
O.PaymentMethod='Points'
AND O.OrderStatus='Completed';

GO

/*==========================================================
Wallet Transactions
Mixed Payment Redemption
==========================================================*/

INSERT INTO WalletTransactions
(
    WalletID,
    EmployeeID,
    OrderID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus
)
SELECT
    W.WalletID,
    O.EmployeeID,
    O.OrderID,
    'Debit',
    'Order Redemption',
    CAST((O.TotalAmount/2.0)*10 AS INT),
    'Completed'
FROM Orders O
JOIN Wallets W
ON O.EmployeeID=W.EmployeeID
WHERE
O.PaymentMethod='Mixed'
AND O.OrderStatus='Completed';

GO

/*==========================================================
Wallet Transactions
Performance Bonus
==========================================================*/

INSERT INTO WalletTransactions
(
    WalletID,
    EmployeeID,
    OrderID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus
)
SELECT TOP 10
    WalletID,
    EmployeeID,
    NULL,
    'Bonus',
    'Performance Reward',
    500,
    'Completed'
FROM Wallets
ORDER BY EmployeeID;

GO

/*==========================================================
Wallet Transactions
Manual Adjustment
==========================================================*/

INSERT INTO WalletTransactions
(
    WalletID,
    EmployeeID,
    OrderID,
    TransactionType,
    TransactionSource,
    Points,
    TransactionStatus
)
SELECT TOP 5
    WalletID,
    EmployeeID,
    NULL,
    'Adjustment',
    'Administrative Adjustment',
    100,
    'Completed'
FROM Wallets
ORDER BY EmployeeID DESC;

GO
