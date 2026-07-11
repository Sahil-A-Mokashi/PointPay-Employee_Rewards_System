-- =============================================
-- STORED PROCEDURE : Place Order
-- Creates a new order and inserts multiple
-- order items from an XML document.
-- =============================================

CREATE PROCEDURE sp_PlaceOrder
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

        /*==========================================
        Validate Employee
        ==========================================*/

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employees
            WHERE EmployeeID = @EmployeeID
              AND IsActive = 1
        )
        BEGIN
            RAISERROR
            (
                'Employee does not exist or is inactive.',
                16,
                1
            );
        END;

        /*==========================================
        Validate Payment Method
        ==========================================*/

        IF @PaymentMethod NOT IN ('Cash','Points','Mixed')
        BEGIN
            RAISERROR
            (
                'Invalid payment method.',
                16,
                1
            );
        END;

        /*==========================================
        Validate Order Status
        ==========================================*/

        IF @OrderStatus NOT IN ('Pending','Completed','Cancelled')
        BEGIN
            RAISERROR
            (
                'Invalid order status.',
                16,
                1
            );
        END;

        /*==========================================
        Validate XML
        ==========================================*/

        IF @OrderItems IS NULL
        BEGIN
            RAISERROR
            (
                'Order XML cannot be NULL.',
                16,
                1
            );
        END;

        IF @OrderItems.exist('/OrderItems/Item') = 0
        BEGIN
            RAISERROR
            (
                'Order must contain at least one item.',
                16,
                1
            );
        END;

        /*==========================================
        Generate Next Order Number
        ORD000001
        ORD000002
        ==========================================*/

        DECLARE @NextOrderNo INT;

        SELECT
            @NextOrderNo =
            ISNULL
            (
                MAX
                (
                    CAST
                    (
                        SUBSTRING(OrderNumber,4,6)
                        AS INT
                    )
                ),
                0
            ) + 1
        FROM Orders;

        DECLARE @OrderNumber VARCHAR(30);

        SET @OrderNumber =
            'ORD' +
            RIGHT
            (
                '000000' + CAST(@NextOrderNo AS VARCHAR(6)),
                6
            );

        /*==========================================
        Create Order
        ==========================================*/

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

        DECLARE @OrderID INT;

        SET @OrderID = SCOPE_IDENTITY();

        /*==========================================
        Insert Order Items
        ==========================================*/

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

            X.Item.value
            (
                '(ProductID)[1]',
                'INT'
            ),

            X.Item.value
            (
                '(Quantity)[1]',
                'INT'
            ),

            P.CashPrice,

            P.PointsPrice

        FROM
        @OrderItems.nodes('/OrderItems/Item') X(Item)

        INNER JOIN Products P

            ON P.ProductID =
            X.Item.value
            (
                '(ProductID)[1]',
                'INT'
            );

        COMMIT TRANSACTION;

        PRINT 'Order placed successfully.';

        SELECT

            @OrderID AS OrderID,

            @OrderNumber AS OrderNumber,

            dbo.udf_CalculateOrderTotal(@OrderID)
            AS OrderTotal;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;

GO


/*==========================================================
STORED PROCEDURE : Approve Return
Approves a pending return request.
The trigger trg_ProcessApprovedReturn automatically
creates the corresponding wallet refund transaction.
==========================================================*/

CREATE PROCEDURE sp_ApproveReturn
(
    @ReturnID INT,
    @ApprovedBy INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        /*==========================================
        Validate Return Request
        ==========================================*/

        IF NOT EXISTS
        (
            SELECT 1
            FROM Returns
            WHERE ReturnID = @ReturnID
        )
        BEGIN
            RAISERROR
            (
                'Return request does not exist.',
                16,
                1
            );
        END;

        /*==========================================
        Ensure Return is Pending
        ==========================================*/

        IF EXISTS
        (
            SELECT 1
            FROM Returns
            WHERE ReturnID = @ReturnID
              AND ReturnStatus <> 'Pending'
        )
        BEGIN
            RAISERROR
            (
                'Return request has already been processed.',
                16,
                1
            );
        END;

        /*==========================================
        Validate Approver
        ==========================================*/

        IF NOT EXISTS
        (
            SELECT 1
            FROM Employees
            WHERE EmployeeID = @ApprovedBy
              AND IsActive = 1
        )
        BEGIN
            RAISERROR
            (
                'Approver does not exist or is inactive.',
                16,
                1
            );
        END;

        /*==========================================
        Approve Return
        ==========================================*/

        UPDATE Returns
        SET
            ReturnStatus = 'Approved',
            ApprovedBy = @ApprovedBy,
            ApprovalDate = GETDATE()
        WHERE ReturnID = @ReturnID;

        COMMIT TRANSACTION;

        PRINT 'Return approved successfully.';

        /*==========================================
        Display Updated Return
        ==========================================*/

        SELECT
            ReturnID,
            OrderID,
            EmployeeID,
            ApprovedBy,
            ReturnStatus,
            ApprovalDate
        FROM Returns
        WHERE ReturnID = @ReturnID;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;
GO


/*==========================================================
STORED PROCEDURE : Redeem Points
Redeems reward points from an employee wallet.

The procedure validates:
1. Wallet exists.
2. Points requested are greater than zero.
3. Wallet has sufficient balance.

If successful, a Redeem transaction is created.
==========================================================*/

CREATE PROCEDURE sp_RedeemPoints
(
    @WalletID INT,
    @Points INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        DECLARE @EmployeeID INT;
        DECLARE @CurrentBalance INT;

        /*==========================================
        Validate Wallet
        ==========================================*/

        SELECT
            @EmployeeID = EmployeeID
        FROM Wallets
        WHERE WalletID = @WalletID;

        IF @EmployeeID IS NULL
        BEGIN
            RAISERROR
            (
                'Wallet does not exist.',
                16,
                1
            );
        END;

        /*==========================================
        Validate Points Requested
        ==========================================*/

        IF @Points <= 0
        BEGIN
            RAISERROR
            (
                'Points must be greater than zero.',
                16,
                1
            );
        END;

        /*==========================================
        Get Current Wallet Balance
        ==========================================*/

        SET @CurrentBalance =
            dbo.udf_GetWalletBalance(@WalletID);

        /*==========================================
        Check Available Balance
        ==========================================*/

        IF @CurrentBalance < @Points
        BEGIN
            RAISERROR
            (
                'Insufficient wallet balance.',
                16,
                1
            );
        END;

        /*==========================================
        Redeem Points
        ==========================================*/

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
        VALUES
        (
            @WalletID,
            @EmployeeID,
            NULL,
            'Redeem',
            'Reward Redemption',
            @Points,
            'Completed'
        );

        COMMIT TRANSACTION;

        PRINT 'Points redeemed successfully.';

        /*==========================================
        Show Updated Wallet Summary
        ==========================================*/

        SELECT
            @WalletID AS WalletID,
            @EmployeeID AS EmployeeID,
            @CurrentBalance AS BalanceBeforeRedemption,
            @Points AS PointsRedeemed,
            dbo.udf_GetWalletBalance(@WalletID) AS RemainingBalance;

    END TRY

    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH

END;

GO

