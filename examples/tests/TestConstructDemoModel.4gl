#+ fglunit suite of ConstructDemoModel: the sample orders table of the CONSTRUCT demo. It
#+ connects to the demo database through FGLPROFILE (examples/fglprofile) and checks that
#+ a date range finds the rows that the CONSTRUCT condition would.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL ConstructDemoModel

MAIN
   CALL CliArgs.parse()
   CONNECT TO "daterangedemo"
   CALL FglUnit.suite("ConstructDemoModel")
   CALL FglUnit.register("testRefreshCreatesSampleOrders", FUNCTION testRefreshCreatesSampleOrders)
   CALL FglUnit.register("testRefreshReplacesTheRows", FUNCTION testRefreshReplacesTheRows)
   CALL FglUnit.register("testDateRangeFindsOrders", FUNCTION testDateRangeFindsOrders)
   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION testRefreshCreatesSampleOrders() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR rowCount INTEGER
   WHENEVER ANY ERROR RAISE
   CALL ConstructDemoModel.refreshSampleOrders() RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "the refresh succeeds")
   CALL Assertions.assertNull(errorText, "no message")
   SELECT COUNT(*) INTO rowCount FROM orders
   CALL Assertions.assertEqualsInt(60, rowCount, "sixty sample orders")
END FUNCTION

#+ A second refresh replaces the rows: it neither fails on the existing table nor doubles them.
PUBLIC FUNCTION testRefreshReplacesTheRows() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR rowCount INTEGER
   WHENEVER ANY ERROR RAISE
   CALL ConstructDemoModel.refreshSampleOrders() RETURNING valid, errorText
   CALL ConstructDemoModel.refreshSampleOrders() RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "the second refresh succeeds")
   SELECT COUNT(*) INTO rowCount FROM orders
   CALL Assertions.assertEqualsInt(60, rowCount, "still sixty orders")
END FUNCTION

#+ The orders go back from today, one every two days: a range of the last 30 days holds the
#+ orders 2, 4, ... 28 days old.
PUBLIC FUNCTION testDateRangeFindsOrders() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR rangeStart DATE
   VAR rangeEnd DATE
   VAR matches INTEGER
   WHENEVER ANY ERROR RAISE
   CALL ConstructDemoModel.refreshSampleOrders() RETURNING valid, errorText
   LET rangeStart = TODAY - 29
   LET rangeEnd = TODAY
   SELECT COUNT(*) INTO matches FROM orders
      WHERE orders.orderdate BETWEEN rangeStart AND rangeEnd
   CALL Assertions.assertEqualsInt(14, matches, "orders in the last 30 days")
END FUNCTION
