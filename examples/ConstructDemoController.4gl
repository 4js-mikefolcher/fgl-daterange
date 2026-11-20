#+ Controller of the CONSTRUCT demo: query by example on the order date with the date range
#+ field, then the matching orders in a DISPLAY ARRAY. In a CONSTRUCT the field is bound to a
#+ DATE, and the runtime itself turns the range the user picks (date1:date2) into the SQL
#+ condition, so the controller never reads JSON here. The SELECT that finds the orders is
#+ the controller's, because the dialog drives it; the data changes are the model's.

IMPORT FGL ConstructDemoModel

#+ The view record: what the table shows, in the order of the screen record srOrders.
PUBLIC TYPE tOrderView RECORD
   orderId   INTEGER,
   customer  VARCHAR(40),
   orderDate DATE,
   amount    DECIMAL(10, 2)
END RECORD

PRIVATE CONSTANT cMaxRows = 500

PRIVATE DEFINE orderList DYNAMIC ARRAY OF tOrderView

PUBLIC FUNCTION constructDemoRun() RETURNS ()
   VAR valid BOOLEAN
   VAR whereText STRING
   VAR errorText STRING
   VAR rowCount INTEGER
   CALL ConstructDemoModel.refreshSampleOrders() RETURNING valid, errorText
   IF NOT valid THEN
      ERROR errorText
      RETURN
   END IF
   OPEN WINDOW wConstructDemo WITH FORM "ConstructDemo"
      ATTRIBUTES(TEXT = "Construct")
   WHILE TRUE
      CLEAR FORM
      CALL constructCriteria() RETURNING valid, whereText
      IF NOT valid THEN
         EXIT WHILE
      END IF
      LET rowCount = loadOrders(whereText)
      DISPLAY whereText TO whereText
      MESSAGE SFMT("%1 orders found.", rowCount)
      IF NOT browseOrders() THEN
         EXIT WHILE
      END IF
   END WHILE
   CLOSE WINDOW wConstructDemo
END FUNCTION

#+ The CONSTRUCT dialog. Returns FALSE when the user cancels, else TRUE and the SQL
#+ condition: " 1=1" when nothing was entered. The ON names are copied into the condition,
#+ so they match the table name used by loadOrders.
PRIVATE FUNCTION constructCriteria() RETURNS (BOOLEAN, STRING)
   VAR whereText STRING
   LET int_flag = FALSE
   CONSTRUCT whereText ON orders.orderdate, orders.customer
      FROM searchDate, searchCustomer
   IF int_flag THEN
      RETURN FALSE, NULL
   END IF
   RETURN TRUE, whereText
END FUNCTION

#+ Fills orderList with the orders that match the condition and returns how many there are.
#+ The SELECT is written for tOrderView: the columns follow its members, in order. The
#+ condition comes from CONSTRUCT, so the statement is dynamic SQL, and the condition is in
#+ parentheses.
PRIVATE FUNCTION loadOrders(whereText STRING) RETURNS INTEGER
   VAR rec tOrderView
   CALL orderList.clear()
   PREPARE stmtOrders FROM
      "SELECT orders.orderid, orders.customer, orders.orderdate, orders.amount"
      || " FROM orders WHERE (" || whereText || ")"
      || " ORDER BY orders.orderdate DESC, orders.orderid"
   DECLARE cursOrders CURSOR FOR stmtOrders
   FOREACH cursOrders INTO rec.*
      LET orderList[orderList.getLength() + 1] = rec
      IF orderList.getLength() >= cMaxRows THEN
         EXIT FOREACH
      END IF
   END FOREACH
   FREE cursOrders
   FREE stmtOrders
   RETURN orderList.getLength()
END FUNCTION

#+ The matching orders. Returns TRUE to start a new search, FALSE to leave the screen.
PRIVATE FUNCTION browseOrders() RETURNS BOOLEAN
   VAR newSearch BOOLEAN = FALSE
   LET int_flag = FALSE
   DISPLAY ARRAY orderList TO srOrders.* ATTRIBUTES(UNBUFFERED)
      ON ACTION newsearch ATTRIBUTES(TEXT = "New search")
         LET newSearch = TRUE
         EXIT DISPLAY
      ON ACTION close
         EXIT DISPLAY
   END DISPLAY
   RETURN newSearch
END FUNCTION
