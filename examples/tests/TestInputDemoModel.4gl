#+ fglunit suite of the business rules of InputDemoModel.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
IMPORT FGL InputDemoModel

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("InputDemoModel")
   CALL FglUnit.register("testReportPeriodValid", FUNCTION testReportPeriodValid)
   CALL FglUnit.register("testReportPeriodRequired", FUNCTION testReportPeriodRequired)
   CALL FglUnit.register("testReportPeriodReversed", FUNCTION testReportPeriodReversed)
   CALL FglUnit.register("testReportPeriodTooLong", FUNCTION testReportPeriodTooLong)
   CALL FglUnit.register("testComparePeriodOptional", FUNCTION testComparePeriodOptional)
   CALL FglUnit.register("testComparePeriodReversed", FUNCTION testComparePeriodReversed)
   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION testReportPeriodValid() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(1, 1, 2026)
   LET dateRange.endDate = MDY(1, 1, 2027)
   CALL InputDemoModel.validateReportPeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "366 days is the limit")
   CALL Assertions.assertNull(errorText, "no message")
END FUNCTION

PUBLIC FUNCTION testReportPeriodRequired() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   INITIALIZE dateRange.* TO NULL
   CALL InputDemoModel.validateReportPeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "an empty report period is refused")
   CALL Assertions.assertEquals("Enter the report period.", errorText, "message")
END FUNCTION

PUBLIC FUNCTION testReportPeriodReversed() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 30, 2026)
   LET dateRange.endDate = MDY(11, 1, 2026)
   CALL InputDemoModel.validateReportPeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "end before start is refused")
   CALL Assertions.assertEquals("The report period ends before it starts.", errorText, "message")
END FUNCTION

PUBLIC FUNCTION testReportPeriodTooLong() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(1, 1, 2026)
   LET dateRange.endDate = MDY(1, 2, 2027)
   CALL InputDemoModel.validateReportPeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "367 days is refused")
   CALL Assertions.assertContains(errorText, "366 days", "message names the limit")
END FUNCTION

PUBLIC FUNCTION testComparePeriodOptional() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   INITIALIZE dateRange.* TO NULL
   CALL InputDemoModel.validateComparePeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "an empty comparison period is accepted")
END FUNCTION

PUBLIC FUNCTION testComparePeriodReversed() RETURNS ()
   VAR dateRange DateRangeHelper.tDateRange
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET dateRange.startDate = MDY(11, 30, 2026)
   LET dateRange.endDate = MDY(11, 1, 2026)
   CALL InputDemoModel.validateComparePeriod(dateRange) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "end before start is refused")
   CALL Assertions.assertEquals("The comparison period ends before it starts.", errorText, "message")
END FUNCTION
