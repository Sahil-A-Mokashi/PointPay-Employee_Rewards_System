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
