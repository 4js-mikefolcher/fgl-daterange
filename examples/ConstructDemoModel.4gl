#+ Model of the CONSTRUCT demo: a small orders table in the demo database, created on the
#+ first run and refilled with orders around today, so that a date range such as "last
#+ 30 days" finds rows. It owns the data changes; no UI.

#+ The database record: one row of the orders table.
PUBLIC TYPE tOrder RECORD
   orderId   INTEGER,
   customer  VARCHAR(40),
   orderDate DATE,
   amount    DECIMAL(10, 2)
END RECORD

#+ One sample order every two days, going back from today.
PRIVATE CONSTANT cSampleOrders = 60

#+ Create the orders table when it is missing and replace its rows with the sample orders,
#+ in one transaction. Returns TRUE, or FALSE with the SQL message.
PUBLIC FUNCTION refreshSampleOrders() RETURNS (BOOLEAN, STRING)
   VAR rec tOrder
   VAR rowCount INTEGER
   VAR errorText STRING
   VAR i INTEGER
   TRY
      SELECT COUNT(*) INTO rowCount FROM orders
   CATCH
      LET rowCount = -1
   END TRY
   BEGIN WORK
   TRY
      IF rowCount < 0 THEN
         CREATE TABLE orders (
            orderid INTEGER NOT NULL,
            customer VARCHAR(40) NOT NULL,
            orderdate DATE NOT NULL,
            amount DECIMAL(10, 2) NOT NULL,
            PRIMARY KEY (orderid)
         )
      ELSE
         DELETE FROM orders
      END IF
      FOR i = 1 TO cSampleOrders
         LET rec.orderId = i
         LET rec.customer = sampleCustomer(i)
         LET rec.orderDate = TODAY - (i * 2)
         LET rec.amount = 25.50 + ((i * 37) MOD 400)
         INSERT INTO orders (orderid, customer, orderdate, amount)
            VALUES (rec.orderId, rec.customer, rec.orderDate, rec.amount)
      END FOR
      COMMIT WORK
   CATCH
      LET errorText = SQLERRMESSAGE
      ROLLBACK WORK
      RETURN FALSE, errorText
   END TRY
   RETURN TRUE, NULL
END FUNCTION

PRIVATE FUNCTION sampleCustomer(orderNumber INTEGER) RETURNS STRING
   CASE orderNumber MOD 5
      WHEN 0
         RETURN "Northwind Traders"
      WHEN 1
         RETURN "Contoso Ltd"
      WHEN 2
         RETURN "Fabrikam Inc"
      WHEN 3
         RETURN "Adventure Works"
      OTHERWISE
         RETURN "Tailspin Toys"
   END CASE
END FUNCTION
