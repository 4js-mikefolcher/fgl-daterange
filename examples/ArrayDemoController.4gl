#+ Controller of the array demo: the date range in a table column, shown with DISPLAY ARRAY
#+ and edited with INPUT ARRAY. Both dialogs run on the same form and the same campaigns. The
#+ column holds the JSON value; the model's record holds two DATEs, and the conversion
#+ functions move between them. Validation and saving are the model's.

IMPORT util
IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper
IMPORT FGL ArrayDemoModel

#+ The view record: one table row, in the order of the screen record srCampaigns. The
#+ period member holds the JSON value of the date range column; days is derived from it.
PUBLIC TYPE tCampaignView RECORD
   campaignName VARCHAR(40),
   period       STRING,
   days         INTEGER
END RECORD

PRIVATE DEFINE campaignList DYNAMIC ARRAY OF tCampaignView

#+ View record to model record. The JSON bridge copies the name, and ignores the members
#+ the model does not have. Special case after it: the period is one JSON value on the screen
#+ and two DATEs in the model.
PUBLIC FUNCTION toDbCampaign(viewRec tCampaignView) RETURNS ArrayDemoModel.tCampaign
   VAR dbRec ArrayDemoModel.tCampaign
   VAR period DateRangeHelper.tDateRange
   CALL util.JSONObject.fromFGL(viewRec).toFGL(dbRec)
   LET period = DateRangeHelper.parseDateRange(viewRec.period)
   LET dbRec.startDate = period.startDate
   LET dbRec.endDate = period.endDate
   RETURN dbRec
END FUNCTION

#+ Model record to view record: the same bridge, then the special case the other way.
PUBLIC FUNCTION toViewCampaign(dbRec ArrayDemoModel.tCampaign) RETURNS tCampaignView
   VAR viewRec tCampaignView
   VAR period DateRangeHelper.tDateRange
   CALL util.JSONObject.fromFGL(dbRec).toFGL(viewRec)
   LET period.startDate = dbRec.startDate
   LET period.endDate = dbRec.endDate
   LET viewRec.period = period.serialize()
   LET viewRec.days = period.days()
   RETURN viewRec
END FUNCTION

#+ DISPLAY ARRAY: the campaigns are read-only, and the date range column is a Label in the
#+ browser. The details action reads the JSON of the current row back into two dates.
PUBLIC FUNCTION displayArrayRun() RETURNS ()
   VAR period DateRangeHelper.tDateRange
   OPEN WINDOW wDisplayArray WITH FORM "ArrayDemo"
      ATTRIBUTES(TEXT = "Display array")
   CALL loadCampaignList()
   LET int_flag = FALSE
   DISPLAY ARRAY campaignList TO srCampaigns.* ATTRIBUTES(UNBUFFERED)
      ON ACTION details ATTRIBUTES(TEXT = "Details")
         LET period = DateRangeHelper.parseDateRange(campaignList[arr_curr()].period)
         MESSAGE SFMT("%1 runs from %2 to %3 (%4 days).",
               campaignList[arr_curr()].campaignName, period.startDate, period.endDate,
               period.days())
      ON ACTION close
         EXIT DISPLAY
   END DISPLAY
   CLOSE WINDOW wDisplayArray
END FUNCTION

#+ INPUT ARRAY: the user types or picks a period in any row, and the days follow. Accept
#+ saves through the model, which refuses a row without a name or period, a period that
#+ ends before it starts, and campaigns that overlap.
PUBLIC FUNCTION inputArrayRun() RETURNS ()
   VAR dbList DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR saved BOOLEAN = FALSE
   OPEN WINDOW wInputArray WITH FORM "ArrayDemo"
      ATTRIBUTES(TEXT = "Input array")
   CALL loadCampaignList()
   LET int_flag = FALSE
   INPUT ARRAY campaignList FROM srCampaigns.* ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
      ON CHANGE period
         CALL showDays(arr_curr())
      AFTER INPUT
         IF NOT int_flag THEN
            CALL toDbCampaigns(dbList)
            CALL ArrayDemoModel.saveCampaigns(dbList) RETURNING valid, errorText
            IF NOT valid THEN
               ERROR errorText
               CONTINUE INPUT
            END IF
            LET saved = TRUE
         END IF
   END INPUT
   CLOSE WINDOW wInputArray
   # After CLOSE WINDOW: a message shown just before it would die with the window
   IF saved THEN
      MESSAGE "Campaigns saved."
   END IF
END FUNCTION

#+ Fills campaignList from the model, converting each record.
PRIVATE FUNCTION loadCampaignList() RETURNS ()
   VAR dbList DYNAMIC ARRAY OF ArrayDemoModel.tCampaign
   VAR i INTEGER
   CALL ArrayDemoModel.loadCampaigns(dbList)
   CALL campaignList.clear()
   FOR i = 1 TO dbList.getLength()
      LET campaignList[i] = toViewCampaign(dbList[i])
   END FOR
END FUNCTION

#+ Converts the rows the user filled in. A row with neither name nor period is a blank row.
PRIVATE FUNCTION toDbCampaigns(dbList DYNAMIC ARRAY OF ArrayDemoModel.tCampaign) RETURNS ()
   VAR i INTEGER
   CALL dbList.clear()
   FOR i = 1 TO campaignList.getLength()
      IF campaignList[i].campaignName IS NOT NULL OR campaignList[i].period IS NOT NULL THEN
         LET dbList[dbList.getLength() + 1] = toDbCampaign(campaignList[i])
      END IF
   END FOR
END FUNCTION

#+ The days column of a row follows its period.
PRIVATE FUNCTION showDays(row INTEGER) RETURNS ()
   VAR period DateRangeHelper.tDateRange
   LET period = DateRangeHelper.parseDateRange(campaignList[row].period)
   LET campaignList[row].days = period.days()
END FUNCTION
