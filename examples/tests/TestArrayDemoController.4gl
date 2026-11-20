#+ fglunit suite of the conversion functions of ArrayDemoController: the JSON bridge, and the
#+ special case between the period and the two dates.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL ArrayDemoModel
IMPORT FGL ArrayDemoController

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("ArrayDemoController")
   CALL FglUnit.register("testToDbAllPopulated", FUNCTION testToDbAllPopulated)
   CALL FglUnit.register("testToDbEmptyAndInvalid", FUNCTION testToDbEmptyAndInvalid)
   CALL FglUnit.register("testToViewAllPopulated", FUNCTION testToViewAllPopulated)
   CALL FglUnit.register("testToViewIncompleteRange", FUNCTION testToViewIncompleteRange)
   EXIT PROGRAM FglUnit.run()
END MAIN

#+ Every crossing member populated: none may come back NULL.
PUBLIC FUNCTION testToDbAllPopulated() RETURNS ()
   VAR viewRec ArrayDemoController.tCampaignView
   VAR dbRec ArrayDemoModel.tCampaign
   WHENEVER ANY ERROR RAISE
   LET viewRec.campaignName = "Autumn sale"
   LET viewRec.period = '{"startDate":"2026-11-01","endDate":"2026-11-30"}'
   LET viewRec.days = 30
   LET dbRec = ArrayDemoController.toDbCampaign(viewRec)
   CALL Assertions.assertNotNull(dbRec.campaignName, "campaignName")
   CALL Assertions.assertNotNull(dbRec.startDate, "startDate")
   CALL Assertions.assertNotNull(dbRec.endDate, "endDate")
   CALL Assertions.assertEquals("Autumn sale", dbRec.campaignName, "the name crosses the bridge")
   CALL Assertions.assertTrue(dbRec.startDate = MDY(11, 1, 2026), "start")
   CALL Assertions.assertTrue(dbRec.endDate = MDY(11, 30, 2026), "end")
END FUNCTION

#+ An empty period and a period holding typed text both give NULL dates, not 1899-12-31.
PUBLIC FUNCTION testToDbEmptyAndInvalid() RETURNS ()
   VAR viewRec ArrayDemoController.tCampaignView
   VAR dbRec ArrayDemoModel.tCampaign
   WHENEVER ANY ERROR RAISE
   LET viewRec.campaignName = "Autumn sale"
   LET viewRec.period = NULL
   LET dbRec = ArrayDemoController.toDbCampaign(viewRec)
   CALL Assertions.assertNull(dbRec.startDate, "empty period: startDate NULL")
   CALL Assertions.assertNull(dbRec.endDate, "empty period: endDate NULL")
   LET viewRec.period = "next week"
   LET dbRec = ArrayDemoController.toDbCampaign(viewRec)
   CALL Assertions.assertNull(dbRec.startDate, "typed text: startDate NULL")
   CALL Assertions.assertNull(dbRec.endDate, "typed text: endDate NULL")
END FUNCTION

PUBLIC FUNCTION testToViewAllPopulated() RETURNS ()
   VAR dbRec ArrayDemoModel.tCampaign
   VAR viewRec ArrayDemoController.tCampaignView
   WHENEVER ANY ERROR RAISE
   LET dbRec.campaignName = "Autumn sale"
   LET dbRec.startDate = MDY(11, 1, 2026)
   LET dbRec.endDate = MDY(11, 30, 2026)
   LET viewRec = ArrayDemoController.toViewCampaign(dbRec)
   CALL Assertions.assertNotNull(viewRec.campaignName, "campaignName")
   CALL Assertions.assertNotNull(viewRec.period, "period")
   CALL Assertions.assertNotNull(viewRec.days, "days")
   CALL Assertions.assertEquals("Autumn sale", viewRec.campaignName, "the name crosses the bridge")
   CALL Assertions.assertEquals('{"startDate":"2026-11-01","endDate":"2026-11-30"}', viewRec.period, "the JSON the widget reads")
   CALL Assertions.assertEqualsInt(30, viewRec.days, "days")
END FUNCTION

PUBLIC FUNCTION testToViewIncompleteRange() RETURNS ()
   VAR dbRec ArrayDemoModel.tCampaign
   VAR viewRec ArrayDemoController.tCampaignView
   WHENEVER ANY ERROR RAISE
   LET dbRec.campaignName = "Autumn sale"
   LET dbRec.startDate = MDY(11, 1, 2026)
   LET dbRec.endDate = NULL
   LET viewRec = ArrayDemoController.toViewCampaign(dbRec)
   CALL Assertions.assertNull(viewRec.period, "a half range empties the field")
   CALL Assertions.assertNull(viewRec.days, "no days for a half range")
END FUNCTION
