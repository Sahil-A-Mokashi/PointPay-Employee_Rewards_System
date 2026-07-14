-- =============================================
-- PointPay Database
-- 07_Stored_Procedures.sql
-- Simplified Stored Procedures
-- =============================================

USE PointPay;
GO

/*==========================================================
STORED PROCEDURE : Place Order
==========================================================*/
CREATE OR ALTER PROCEDURE sp_PlaceOrder
(
    @EmployeeID INT,
    @PaymentMethod VARCHAR(20),
    @CashPaid DECIMAL(10,2),
    @PointsUsed INT,
    @OrderStatus VARCHAR(20),
    @OrderItems XML
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employees
            WHERE EmployeeID=@EmployeeID
            AND IsActive=1
        )
        BEGIN
            RAISERROR('Employee does not exist or is inactive.',16,1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        DECLARE @NextOrderNo INT,
                @OrderID INT,
                @OrderNumber VARCHAR(30);

        SELECT @NextOrderNo =
            ISNULL(MAX(CAST(SUBSTRING(OrderNumber,4,6) AS INT)),0)+1
        FROM Orders;

        SET @OrderNumber='ORD'+RIGHT('000000'+CAST(@NextOrderNo AS VARCHAR(6)),6);

        INSERT INTO Orders
        (
            EmployeeID,
            OrderNumber,
            CashPaid,
            PointsUsed,
            PaymentMethod,
            OrderStatus,
            OrderDate
        )
        VALUES
        (
            @EmployeeID,
            @OrderNumber,
            @CashPaid,
            @PointsUsed,
            @PaymentMethod,
            @OrderStatus,
            GETDATE()
        );

        SET @OrderID=SCOPE_IDENTITY();

        INSERT INTO OrderItems
        (
            OrderID,
            ProductID,
            Quantity,
            UnitCashPrice,
            UnitPointsPrice
        )
        SELECT
            @OrderID,
            X.Item.value('(ProductID)[1]','INT'),
            X.Item.value('(Quantity)[1]','INT'),
            P.CashPrice,
            P.PointsPrice
        FROM @OrderItems.nodes('/OrderItems/Item') X(Item)
        JOIN Products P
        ON P.ProductID=X.Item.value('(ProductID)[1]','INT');

        COMMIT TRANSACTION;

        SELECT
            @OrderID AS OrderID,
            @OrderNumber AS OrderNumber,
            dbo.udf_CalculateOrderTotal(@OrderID) AS OrderTotal;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/*==========================================================
STORED PROCEDURE : Approve Return
==========================================================*/
CREATE OR ALTER PROCEDURE sp_ApproveReturn
(
    @ReturnID INT,
    @ApprovedBy INT
)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Returns
    SET
        ReturnStatus='Approved',
        ApprovedBy=@ApprovedBy,
        ApprovalDate=GETDATE()
    WHERE
        ReturnID=@ReturnID
        AND ReturnStatus='Pending';

    SELECT *
    FROM Returns
    WHERE ReturnID=@ReturnID;
END;
GO

/*==========================================================
STORED PROCEDURE : Redeem Points
==========================================================*/
CREATE OR ALTER PROCEDURE sp_RedeemPoints
(
    @WalletID INT,
    @Points INT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF dbo.udf_GetWalletBalance(@WalletID) < @Points
    BEGIN
        RAISERROR('Insufficient wallet balance.',16,1);
        RETURN;
    END;

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
        'Redeem',
        'Reward Redemption',
        @Points,
        'Completed'
    FROM Wallets
    WHERE WalletID=@WalletID;

    SELECT dbo.udf_GetWalletBalance(@WalletID) AS RemainingBalance;
END;
GO
