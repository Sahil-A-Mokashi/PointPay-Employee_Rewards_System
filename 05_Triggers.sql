-- Use the database
USE PointPay;
GO
/*==========================================================
TRIGGER : Update Product Stock
Automatically maintains product inventory whenever
order items are inserted, updated or deleted.
==========================================================*/

CREATE TRIGGER trg_UpdateProductStock
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Restore stock for deleted rows
    UPDATE P
    SET StockQuantity = StockQuantity + D.Quantity
    FROM Products P
    INNER JOIN deleted D
        ON P.ProductID = D.ProductID;

    -- Deduct stock for inserted rows
    UPDATE P
    SET StockQuantity = StockQuantity - I.Quantity
    FROM Products P
    INNER JOIN inserted I
        ON P.ProductID = I.ProductID;
END;
GO

    
/*==========================================================
TRIGGER : Check Product Availability
==========================================================*/

CREATE OR ALTER TRIGGER trg_CheckProductAvailability
ON OrderItems
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        WHERE dbo.udf_IsProductAvailable(i.ProductID, i.Quantity) = 0
    )
    BEGIN
        RAISERROR(
        'Product is inactive or insufficient stock is available.',
        16,
        1
        );

        RETURN;
    END

    INSERT INTO OrderItems
    (
        OrderID,
        ProductID,
        Quantity,
        UnitCashPrice,
        UnitPointsPrice
    )
    SELECT
        OrderID,
        ProductID,
        Quantity,
        UnitCashPrice,
        UnitPointsPrice
    FROM inserted;
END;
GO


/*==========================================================
TRIGGER : Process Approved Return
Automatically creates a wallet refund transaction when
a return request is approved.
    Refund points are calculated dynamically from the related
order
==========================================================*/

CREATE OR ALTER TRIGGER trg_ProcessApprovedReturn
ON Returns
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

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
        I.EmployeeID,
        I.OrderID,
        'Refund',
        'Return',

        CASE
            WHEN O.PaymentMethod='Cash'
                THEN CAST(dbo.udf_CalculateOrderTotal(O.OrderID) * 10 AS INT)
        
            WHEN O.PaymentMethod='Points'
                THEN CAST(dbo.udf_CalculateOrderTotal(O.OrderID) * 10 AS INT)
        
            WHEN O.PaymentMethod='Mixed'
                THEN CAST((dbo.udf_CalculateOrderTotal(O.OrderID) / 2.0) * 10 AS INT)
        END,

        'Completed'

    FROM inserted I

    INNER JOIN deleted D
        ON I.ReturnID=D.ReturnID

    INNER JOIN Orders O
        ON I.OrderID=O.OrderID

    INNER JOIN Wallets W
        ON I.EmployeeID=W.EmployeeID

    WHERE
        D.ReturnStatus<>'Approved'
        AND I.ReturnStatus='Approved';

END;
GO
