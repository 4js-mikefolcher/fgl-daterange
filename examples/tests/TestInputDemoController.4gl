#+ fglunit suite of the conversion function of InputDemoController.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL InputDemoModel
IMPORT FGL InputDemoController

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("InputDemoController")
   CALL FglUnit.register("testToDbAllPopulated", FUNCTION testToDbAllPopulated)
   CALL FglUnit.register("testToDbEmptyAndInvalid", FUNCTION testToDbEmptyAndInvalid)
   EXIT PROGRAM FglUnit.run()
END MAIN

#+ Every crossing member populated: none may come back NULL.
PUBLIC FUNCTION testToDbAllPopulated() RETURNS ()
   VAR viewRec InputDemoController.tReportPeriodsView
   VAR dbRec InputDemoModel.tReportPeriods
   WHENEVER ANY ERROR RAISE
   LET viewRec.reportPeriod = '{"startDate":"2026-11-01","endDate":"2026-11-30"}'
   LET viewRec.comparePeriod = '{"startDate":"2025-11-01","endDate":"2025-11-30"}'
   LET dbRec = InputDemoController.toDbReportPeriods(viewRec)
   CALL Assertions.assertNotNull(dbRec.reportPeriod.startDate, "reportPeriod.startDate")
   CALL Assertions.assertNotNull(dbRec.reportPeriod.endDate, "reportPeriod.endDate")
   CALL Assertions.assertNotNull(dbRec.comparePeriod.startDate, "comparePeriod.startDate")
   CALL Assertions.assertNotNull(dbRec.comparePeriod.endDate, "comparePeriod.endDate")
   CALL Assertions.assertTrue(dbRec.reportPeriod.startDate = MDY(11, 1, 2026), "report start")
   CALL Assertions.assertTrue(dbRec.reportPeriod.endDate = MDY(11, 30, 2026), "report end")
   CALL Assertions.assertTrue(dbRec.comparePeriod.startDate = MDY(11, 1, 2025), "compare start")
   CALL Assertions.assertTrue(dbRec.comparePeriod.endDate = MDY(11, 30, 2025), "compare end")
END FUNCTION

#+ An empty field and a field holding typed text both give a NULL range.
PUBLIC FUNCTION testToDbEmptyAndInvalid() RETURNS ()
   VAR viewRec InputDemoController.tReportPeriodsView
   VAR dbRec InputDemoModel.tReportPeriods
   WHENEVER ANY ERROR RAISE
   LET viewRec.reportPeriod = NULL
   LET viewRec.comparePeriod = "next week"
   LET dbRec = InputDemoController.toDbReportPeriods(viewRec)
   CALL Assertions.assertNull(dbRec.reportPeriod.startDate, "empty field: startDate NULL")
   CALL Assertions.assertNull(dbRec.reportPeriod.endDate, "empty field: endDate NULL")
   CALL Assertions.assertNull(dbRec.comparePeriod.startDate, "typed text: startDate NULL")
   CALL Assertions.assertNull(dbRec.comparePeriod.endDate, "typed text: endDate NULL")
END FUNCTION
