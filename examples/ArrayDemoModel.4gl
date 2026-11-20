#+ Model of the array demo: marketing campaigns, each with a name and the period it runs. The
#+ campaigns live in memory for the life of the program, standing in for a table. The model
#+ owns the data changes and the rules; no UI.

IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper

#+ The model record: a campaign as it is stored, with its period as two dates.
PUBLIC TYPE tCampaign RECORD
   campaignName VARCHAR(40),
   startDate    DATE,
   endDate      DATE
END RECORD

PRIVATE DEFINE campaigns DYNAMIC ARRAY OF tCampaign
PRIVATE DEFINE seeded BOOLEAN

#+ Fills result with a copy of the campaigns, replacing what it held. The first call creates
#+ the sample campaigns around today.
PUBLIC FUNCTION loadCampaigns(result DYNAMIC ARRAY OF tCampaign) RETURNS ()
   IF NOT seeded THEN
      CALL seedCampaigns()
      LET seeded = TRUE
   END IF
   # LET would share the array, not copy it
   CALL campaigns.copyTo(result)
END FUNCTION

#+ A campaign needs a name and a period that does not end before it starts.
#+ Returns TRUE, or FALSE with a message for the user.
PUBLIC FUNCTION validateCampaign(rec tCampaign) RETURNS (BOOLEAN, STRING)
   VAR period DateRangeHelper.tDateRange
   IF rec.campaignName IS NULL THEN
      RETURN FALSE, "Enter the campaign name."
   END IF
   LET period.startDate = rec.startDate
   LET period.endDate = rec.endDate
   IF NOT period.isComplete() THEN
      RETURN FALSE, SFMT("Enter the period of %1.", rec.campaignName)
   END IF
   IF rec.endDate < rec.startDate THEN
      RETURN FALSE, SFMT("%1 ends before it starts.", rec.campaignName)
   END IF
   RETURN TRUE, NULL
END FUNCTION

#+ Every campaign is valid and no two campaigns run on the same day.
#+ Returns TRUE, or FALSE with a message for the user.
PUBLIC FUNCTION validateCampaigns(list DYNAMIC ARRAY OF tCampaign) RETURNS (BOOLEAN, STRING)
   VAR valid BOOLEAN
   VAR errorText STRING
   VAR firstRange DateRangeHelper.tDateRange
   VAR secondRange DateRangeHelper.tDateRange
   VAR i INTEGER
   VAR j INTEGER
   FOR i = 1 TO list.getLength()
      CALL validateCampaign(list[i]) RETURNING valid, errorText
      IF NOT valid THEN
         RETURN FALSE, errorText
      END IF
   END FOR
   FOR i = 1 TO list.getLength() - 1
      LET firstRange.startDate = list[i].startDate
      LET firstRange.endDate = list[i].endDate
      FOR j = i + 1 TO list.getLength()
         LET secondRange.startDate = list[j].startDate
         LET secondRange.endDate = list[j].endDate
         IF firstRange.overlaps(secondRange) THEN
            RETURN FALSE, SFMT("%1 and %2 overlap.", list[i].campaignName, list[j].campaignName)
         END IF
      END FOR
   END FOR
   RETURN TRUE, NULL
END FUNCTION

#+ Replaces the campaigns with the list, when the list is valid.
#+ Returns TRUE, or FALSE with a message for the user.
PUBLIC FUNCTION saveCampaigns(list DYNAMIC ARRAY OF tCampaign) RETURNS (BOOLEAN, STRING)
   VAR valid BOOLEAN
   VAR errorText STRING
   CALL validateCampaigns(list) RETURNING valid, errorText
   IF NOT valid THEN
      RETURN FALSE, errorText
   END IF
   CALL list.copyTo(campaigns)
   RETURN TRUE, NULL
END FUNCTION

PRIVATE FUNCTION seedCampaigns() RETURNS ()
   CALL addCampaign("Welcome series", TODAY - 45, TODAY - 16)
   CALL addCampaign("Autumn sale", TODAY - 15, TODAY + 14)
   CALL addCampaign("Black Friday", TODAY + 15, TODAY + 18)
   CALL addCampaign("Holiday mailing", TODAY + 19, TODAY + 45)
   CALL addCampaign("New year launch", TODAY + 46, TODAY + 75)
END FUNCTION

PRIVATE FUNCTION addCampaign(campaignName STRING, startDate DATE, endDate DATE) RETURNS ()
   VAR rowNumber INTEGER = campaigns.getLength() + 1
   LET campaigns[rowNumber].campaignName = campaignName
   LET campaigns[rowNumber].startDate = startDate
   LET campaigns[rowNumber].endDate = endDate
END FUNCTION
