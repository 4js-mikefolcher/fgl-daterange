#+ fglunit suite of ArrayDemoModel: the rules on the campaigns, and the in-memory storage.

IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL com.fourjs.fglunit.CliArgs
IMPORT FGL ArrayDemoModel

MAIN
   CALL CliArgs.parse()
   CALL FglUnit.suite("ArrayDemoModel")
   CALL FglUnit.register("testSampleCampaignsAreValid", FUNCTION testSampleCampaignsAreValid)
   CALL FglUnit.register("testLoadReturnsACopy", FUNCTION testLoadReturnsACopy)
   CALL FglUnit.register("testCampaignNeedsName", FUNCTION testCampaignNeedsName)
   CALL FglUnit.register("testCampaignNeedsPeriod", FUNCTION testCampaignNeedsPeriod)
   CALL FglUnit.register("testCampaignEndsBeforeItStarts", FUNCTION testCampaignEndsBeforeItStarts)
   CALL FglUnit.register("testOverlappingCampaignsAreRefused", FUNCTION testOverlappingCampaignsAreRefused)
   CALL FglUnit.register("testSaveKeepsValidList", FUNCTION testSaveKeepsValidList)
   CALL FglUnit.register("testSaveRefusesInvalidList", FUNCTION testSaveRefusesInvalidList)
   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE FUNCTION newCampaign(campaignName STRING, startDate DATE, endDate DATE) RETURNS ArrayDemoModel.tCampaign
   VAR rec ArrayDemoModel.tCampaign
   LET rec.campaignName = campaignName
   LET rec.startDate = startDate
   LET rec.endDate = endDate
   RETURN rec
END FUNCTION

PUBLIC FUNCTION testSampleCampaignsAreValid() RETURNS ()
   VAR list DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.loadCampaigns(list)
   CALL Assertions.assertTrue(list.getLength() > 0, "there are campaigns")
   CALL ArrayDemoModel.validateCampaigns(list) RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "the campaigns are valid")
   CALL Assertions.assertNull(errorText, "no message")
END FUNCTION

#+ The array a caller gets is its own: changing it does not change the stored campaigns.
PUBLIC FUNCTION testLoadReturnsACopy() RETURNS ()
   VAR firstLoad DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR secondLoad DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR storedName STRING
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.loadCampaigns(firstLoad)
   LET storedName = firstLoad[1].campaignName
   LET firstLoad[1].campaignName = "changed by the caller"
   CALL ArrayDemoModel.loadCampaigns(secondLoad)
   CALL Assertions.assertEquals(storedName, secondLoad[1].campaignName, "the stored name is unchanged")
END FUNCTION

PUBLIC FUNCTION testCampaignNeedsName() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.validateCampaign(newCampaign(NULL, MDY(11, 1, 2026), MDY(11, 30, 2026)))
      RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "a campaign without a name is refused")
   CALL Assertions.assertEquals("Enter the campaign name.", errorText, "message")
END FUNCTION

PUBLIC FUNCTION testCampaignNeedsPeriod() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.validateCampaign(newCampaign("Autumn sale", MDY(11, 1, 2026), NULL))
      RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "a campaign without a complete period is refused")
   CALL Assertions.assertEquals("Enter the period of Autumn sale.", errorText, "message")
END FUNCTION

PUBLIC FUNCTION testCampaignEndsBeforeItStarts() RETURNS ()
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.validateCampaign(newCampaign("Autumn sale", MDY(11, 30, 2026), MDY(11, 1, 2026)))
      RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "end before start is refused")
   CALL Assertions.assertEquals("Autumn sale ends before it starts.", errorText, "message")
END FUNCTION

PUBLIC FUNCTION testOverlappingCampaignsAreRefused() RETURNS ()
   VAR list DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET list[1] = newCampaign("Autumn sale", MDY(11, 1, 2026), MDY(11, 30, 2026))
   LET list[2] = newCampaign("Black Friday", MDY(11, 30, 2026), MDY(12, 2, 2026))
   CALL ArrayDemoModel.validateCampaigns(list) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "campaigns sharing a day are refused")
   CALL Assertions.assertEquals("Autumn sale and Black Friday overlap.", errorText, "message")
   LET list[2].startDate = MDY(12, 1, 2026)
   CALL ArrayDemoModel.validateCampaigns(list) RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "back to back campaigns are accepted")
END FUNCTION

PUBLIC FUNCTION testSaveKeepsValidList() RETURNS ()
   VAR list DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR reloaded DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR valid BOOLEAN
   VAR errorText STRING
   WHENEVER ANY ERROR RAISE
   LET list[1] = newCampaign("Spring launch", MDY(3, 1, 2027), MDY(3, 31, 2027))
   CALL ArrayDemoModel.saveCampaigns(list) RETURNING valid, errorText
   CALL Assertions.assertTrue(valid, "a valid list is saved")
   CALL ArrayDemoModel.loadCampaigns(reloaded)
   CALL Assertions.assertEqualsInt(1, reloaded.getLength(), "one campaign stored")
   CALL Assertions.assertEquals("Spring launch", reloaded[1].campaignName, "the saved name")
   CALL Assertions.assertNotNull(reloaded[1].startDate, "startDate stored")
   CALL Assertions.assertNotNull(reloaded[1].endDate, "endDate stored")
   CALL Assertions.assertTrue(reloaded[1].startDate = MDY(3, 1, 2027), "the saved start")
   CALL Assertions.assertTrue(reloaded[1].endDate = MDY(3, 31, 2027), "the saved end")
END FUNCTION

PUBLIC FUNCTION testSaveRefusesInvalidList() RETURNS ()
   VAR list DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR reloaded DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR storedCount INTEGER
   WHENEVER ANY ERROR RAISE
   CALL ArrayDemoModel.loadCampaigns(reloaded)
   LET storedCount = reloaded.getLength()
   LET list[1] = newCampaign(NULL, MDY(3, 1, 2027), MDY(3, 31, 2027))
   CALL ArrayDemoModel.saveCampaigns(list) RETURNING valid, errorText
   CALL Assertions.assertFalse(valid, "an invalid list is refused")
   CALL ArrayDemoModel.loadCampaigns(reloaded)
   CALL Assertions.assertEqualsInt(storedCount, reloaded.getLength(), "the stored campaigns are unchanged")
END FUNCTION
