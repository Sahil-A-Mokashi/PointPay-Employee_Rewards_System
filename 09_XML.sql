-- =============================================
-- PointPay Database
-- XML Demonstration
-- =============================================

USE PointPay;
GO

/*==========================================================
XML Order Example
==========================================================*/

DECLARE @OrderItems XML =
'
<OrderItems>

    <Item>
        <ProductID>2</ProductID>
        <Quantity>1</Quantity>
    </Item>

    <Item>
        <ProductID>5</ProductID>
        <Quantity>2</Quantity>
    </Item>

    <Item>
        <ProductID>10</ProductID>
        <Quantity>1</Quantity>
    </Item>

</OrderItems>';

EXEC sp_PlaceOrder
    @EmployeeID = 1,
    @PaymentMethod = 'Mixed',
    @CashPaid = 150,
    @PointsUsed = 1000,
    @OrderStatus = 'Pending',
    @OrderItems = @OrderItems;

GO

/*==========================================================
Display Newly Created Order
==========================================================*/

SELECT TOP 1
    OrderID,
    OrderNumber,
    EmployeeID,
    PaymentMethod,
    CashPaid,
    PointsUsed,
    dbo.udf_CalculateOrderTotal(OrderID) AS OrderTotal
FROM Orders
ORDER BY OrderID DESC;

GO

/*==========================================================
Display Order Items
==========================================================*/

SELECT TOP 10
    OrderItemID,
    OrderID,
    ProductID,
    Quantity,
    UnitCashPrice,
    UnitPointsPrice
FROM OrderItems
ORDER BY OrderItemID DESC;

GO
