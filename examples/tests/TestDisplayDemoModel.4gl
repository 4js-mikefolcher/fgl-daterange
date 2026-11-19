#+ fglunit suite of DisplayDemoModel: the calendar periods of the DISPLAY demo.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
IMPORT FGL DisplayDemoModel

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("DisplayDemoModel")
   CALL FglUnit.register("testMonthPeriod", FUNCTION testMonthPeriod)
   CALL FglUnit.register("testMonthPeriodAcrossYears", FUNCTION testMonthPeriodAcrossYears)
   CALL FglUnit.register("testMonthPeriodLeapYear", FUNCTION testMonthPeriodLeapYear)
   CALL FglUnit.register("testLastDaysPeriod", FUNCTION testLastDaysPeriod)
   CALL FglUnit.register("testQuarterPeriod", FUNCTION testQuarterPeriod)
   CALL FglUnit.register("testYearPeriod", FUNCTION testYearPeriod)
   EXIT PROGRAM FglUnit.run()
END MAIN

#+ Both dates must be there before they are compared: a comparison with NULL is NULL.
PRIVATE FUNCTION assertRange(actual DateRangeHelper.tDateRange, expectedStart DATE, expectedEnd DATE, label STRING) RETURNS ()
   CALL Assertions.assertNotNull(actual.startDate, SFMT("%1: startDate", label))
   CALL Assertions.assertNotNull(actual.endDate, SFMT("%1: endDate", label))
   CALL Assertions.assertTrue(actual.startDate = expectedStart, SFMT("%1: starts on the expected day", label))
   CALL Assertions.assertTrue(actual.endDate = expectedEnd, SFMT("%1: ends on the expected day", label))
END FUNCTION

PUBLIC FUNCTION testMonthPeriod() RETURNS ()
   VAR refDate DATE
   WHENEVER ANY ERROR RAISE
   LET refDate = MDY(11, 19, 2026)
   CALL assertRange(DisplayDemoModel.monthPeriod(refDate, 0), MDY(11, 1, 2026), MDY(11, 30, 2026), "this month")
   CALL assertRange(DisplayDemoModel.monthPeriod(refDate, -1), MDY(10, 1, 2026), MDY(10, 31, 2026), "last month")
   CALL assertRange(DisplayDemoModel.monthPeriod(refDate, 1), MDY(12, 1, 2026), MDY(12, 31, 2026), "next month")
END FUNCTION

PUBLIC FUNCTION testMonthPeriodAcrossYears() RETURNS ()
   VAR refDate DATE
   WHENEVER ANY ERROR RAISE
   LET refDate = MDY(11, 19, 2026)
   CALL assertRange(DisplayDemoModel.monthPeriod(refDate, 2), MDY(1, 1, 2027), MDY(1, 31, 2027), "two months on")
   CALL assertRange(DisplayDemoModel.monthPeriod(refDate, -11), MDY(12, 1, 2025), MDY(12, 31, 2025), "eleven months back")
END FUNCTION

PUBLIC FUNCTION testMonthPeriodLeapYear() RETURNS ()
   WHENEVER ANY ERROR RAISE
   CALL assertRange(DisplayDemoModel.monthPeriod(MDY(2, 10, 2028), 0), MDY(2, 1, 2028), MDY(2, 29, 2028), "leap February")
   CALL assertRange(DisplayDemoModel.monthPeriod(MDY(2, 10, 2027), 0), MDY(2, 1, 2027), MDY(2, 28, 2027), "February")
END FUNCTION

PUBLIC FUNCTION testLastDaysPeriod() RETURNS ()
   VAR period DateRangeHelper.tDateRange
   WHENEVER ANY ERROR RAISE
   LET period = DisplayDemoModel.lastDaysPeriod(MDY(11, 19, 2026), 30)
   CALL assertRange(period, MDY(10, 21, 2026), MDY(11, 19, 2026), "last 30 days")
   CALL Assertions.assertEqualsInt(30, period.days(), "30 days, both ends included")
END FUNCTION

PUBLIC FUNCTION testQuarterPeriod() RETURNS ()
   WHENEVER ANY ERROR RAISE
   CALL assertRange(DisplayDemoModel.quarterPeriod(MDY(11, 19, 2026)), MDY(10, 1, 2026), MDY(12, 31, 2026), "fourth quarter")
   CALL assertRange(DisplayDemoModel.quarterPeriod(MDY(2, 1, 2026)), MDY(1, 1, 2026), MDY(3, 31, 2026), "first quarter")
   CALL assertRange(DisplayDemoModel.quarterPeriod(MDY(6, 30, 2026)), MDY(4, 1, 2026), MDY(6, 30, 2026), "second quarter")
   CALL assertRange(DisplayDemoModel.quarterPeriod(MDY(7, 1, 2026)), MDY(7, 1, 2026), MDY(9, 30, 2026), "third quarter")
END FUNCTION

PUBLIC FUNCTION testYearPeriod() RETURNS ()
   WHENEVER ANY ERROR RAISE
   CALL assertRange(DisplayDemoModel.yearPeriod(MDY(11, 19, 2026)), MDY(1, 1, 2026), MDY(12, 31, 2026), "year")
END FUNCTION
