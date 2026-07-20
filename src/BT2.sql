USE [DataProvider];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS (SELECT * FROM sys.objects nolock WHERE type = 'P' AND name = 'spSetKSUDelayDetails')
BEGIN
DROP PROC [spSetKSUDelayDetails]
PRINT 'spSetKSUDelayDetails has been dropped'
END
GO 

-- ================================================
-- By Alan Cunningham
-- V1.0 Initial GeSS release
-- V1.1 R900 GeSS release
-- V1.2 R1000 GeSS release
-- V1.3 R1011 GeSS release
-- V1.31 R1011 GeSS release for CR118
-- V1.4 R1027 GeSS release
-- V1.5 R1203 GeSS release
-- V1.6 R1300 GeSS release
-- V1.7 R1509 GeSS release
-- V1.8 R1800 Drop 2 GeSS release
-- V1.9 R1900 Drop 1 - removed Y option and replaced S with Y. Added Z and V options
-- V2.0 R2000 - Ensured AmendRequired was maintained during multi delay sequences if set to Y
-- V2.1 R2100 - (OR-10119) to get the Delay details for SIM2
-- V2.2 R2150 - (OR-10119) Remove 625 delay code since it is not a part of SIM2 #3 Dec 2012
-- V2.2 R2150 - (OR-10119) Update LO_DelayReasoon to NULL once delay is sent #5 Dec 2012
-- V2.3 R2150 - (OR-10119) Add subsequent delay reason 9544 for 577 delay on MPF #10 Dec 2012
-- V2.4 R2150 - (OR-10119) To remove the duplicate delay on MPF\FTTC #19 Dec 2012
-- V2.5 R2150 - (OR-10119) Update OrderNoteText and OrderNoteType for 9544 delay #20 Dec 2012
-- V2.6 R2150 - (OR-10119) Changes for SIM2 Migrate order #22 Dec 2012
-- V2.7 R2150 - (OR-10119) Changes for SIM2 for ReAppointmentReq W and A1 #22 Dec 2012
-- V2.8 R2350 - (QC#17912) Changes for Normal MPF/SMPF orders with delay only(569 - Delay Faulty Tie Pair Amend )
---V2.9 R2350Drop2 Changes for PSTN+FTTC/PSTN+SMPF SIM2 delay Scenarios (OR-14192)
-- V2.10 R2350Drop2 -(OR14968) Including validation for 569 delay on SMPF and setting values for delay 9580 on PSTN
-- V2.11 R2350Drop2 -(OR14968)- To set 9494 delay on SMPF if 5197 delay triggered on PSTN.
-- V2.11.1 R2350Drop2 -(OR14968)-Setting Reappointment as N for 9494 delay
-- V2.12 R2400 - (ORC2M - 31641) Update the 5463 - NGA Delay Notes.
-- V2.13 QC 22582 - Send 9404 delay in Note Tag for NGA
-- V3.0 f0r R2450 CR-18700 to set note code,Note text for delay 9520   --V3.1 QC23469 -Not to send 9544 if delaycode is 577 and FTTP Order
-- V3.2 QC26067 -Not to send 9544 if delaycode is 577 and FVA Order #17-02-2014
-- V4.0 for R2500 ORC2M-33803 for sending 9544 in case of FTTC PCP only sim2 Orders
-- V4.1 R2550 - QC27811 - FTTC + PSTN SIM2,If the delay is 5197 then confirmation required and amendrequired are set to N
-- V4.2 R2600 - (OR-19298) changes of V2.3 made more specific as it for MPF SIM2 order and setting apptreqd as N for delays 577 and 5468
-- V4.3  HotFix (OR -17521) Changes made to accomodate 9494 for SBS
-- V4.4 R2800 OR-21808, To add AdditionalNotesXML to send extra code for LLU and NGA EU and OR missed delays
-- V4.5 R2800 OR-25378 To send 5742,561 and 9650 delay codes
-- V4.6 R2800 OR-21808, To send 9600 after 9544 when 5466 delay is stubbed on FTTC in PSTN/MPF+FTTC SIM2 scenario
-- V4.7 QC-43494, To Send Proper DelatNoteText for 5742.
-- V4.8 QC44509 , Blanking 5197 Additional Notes in KCI2 for 565 Delay in LLU journey.
-- V4.9 R2900 OR-25745, Setting Customer first KCI delay dates and changing date format for 5742 and 561
-- V5.0 R2900 OR- 23656, Implementing SPLIT scenario for codes 567 for MPF and 597 for PSTN
-- V5.1 R2950 OR-25752 Sending Planning Delay and Complex design codes
-- V5.2 R3000 OR-29178  Setting Customer first KCI delay for SIM2 orders
-- V5.3 R3000 OR-16805 Commenting setting of reappointment required as CA10 for MPF Split scenario
-- V5.4 R3050 OR-26059 to set the reach value for EAD orders when 9709 delay is stubbed
-- V5.5 QC52468-BTW SIM2 Requirement ,PSTN+FTTC SIM2 ,9494 to be sent for PSTN if KCIdelayreason is 9494 - Linked order delayed.(coded for scenario 16 and 7)
-- V5.6 QC52468-BTW SIM2 Requirement ,PSTN(SOSL/WLTO) + FTTC SIM2 , if 566 stubbed on FTTC then 9544 should be send as subsequent delay
-- V5.7 R3100 OR-31562 ORCE-89513 Sending 572 followed by 9544 for SMPF in SIM2
-- V5.8 QC56084 - To store the AbortiveVisitReqd flag in orderparams when 565 delay is triggered for MPF, SMPF BET, FTTC and FTTP orders.
-- Utility SP to set appropriate KCI-Delay params using the passed details
-- V5.9 R3200 OR-29967 - Unhappy path for SOGEA L2C. Adding new param EUConfirmedDelay
-- V6.0 R3200 OR-29967 - Unhappy path for SOGEA Raising abortive visit charges if it is an EU missed delay
-- V6.1 R3200 OR-26697 - Adding changes to send 9708 cancellation after 578 delay
-- V6.2 R3400 OR-29181 - To set %2 in case of 9743 delay in WLR and LLU.
-- V6.3 R3450 OR-38319 - To store 578 POST KCI-2 behaviour for Generic Ethernet Access.
-- V6.4 R3500 OR-31566 - Setting @delayNoteText in case of 9775 delay
-- V6.5 QC78041 - To set include the EUOrOpenreachMissed flag as Y for 566 delay for solving the date issue
-- V6.6 R3550 OR-40208 - To allow 9279 before KCI2 for FTTPOrderStage1 and after KCI2 for FTTPOrderStage2
-- v6.7 R3550 ORCE-111120 to send new KSU message 8016
-- V6.8 QC96400 To set include the EUOrOpenreachMissed flag as Y for 565 delay for solving the date issue
-- V6.8.1 Hotfix for 9775 delay- changing the delay text
-- V6.9 OR-41199 to set orderbehavior when 9808 delay happens
-- V6.9.1 OR-41199 sending OrderItemNoteText & OrderItemNoteType in case of 9808
-- V6.9.2 Avoid overwriting of availabledate received from siebel when there is no 8016 delay
-- V7.0 R3600 OR-33892 EAD Sending New KCI 9790 9791 9792
-- V7.1 R3650 ORCE-122409 To store KCI delay retention reason, to enable 9798 along with 572
-- V7.2 R3700 OR-37908/ORCE-110929 To set date incase of 9743 & 9818 KCIdelay for SOGEA
-- V7.2.1 R3700 OR-37908/ORCE-110929 changing delay date for sogea in case of 9668 & 9669 (new site delays) delay
-- V7.3 R3750  OR-44937 EU Confirmed added for Generic Ethernet Access
-- V7.3.1 R3750 OR-44937 To set ReappointmentReqd="N" in case of MPF 9494 delay
-- V7.4 R3750 OR-42750/ORCE-127929 To set send 9275 delay code in case of V35 and above.
-- V7.5 16-05-2018 Parvesh OR-43379 Adding Copper Route Verification Details
-- V7.5.1 23-05-2018 Fixing issue where Amend OSU is not going after Order is Amended
-- V7.6 OR-44563 To sent delay codes(5464,5462) based on ServingNetworkNotes and Architecture
-- v7.7 12-06-2018 Parvesh OR-43379 To Save EUConfirmed Delay in Order Params
-- v7.8 25-09-2018 Parvesh ORCE-130582 To Make changes to send 8020 There is Planned Engineering Work
-- V7.9 20181127 QC-155695 as per OR-21808(R2800) 9600 has to be sent only for OR missed appointment and the list of delays mentioned in it.
-- V8.0 OR-41679 changes made to send 9816 in OrderItemNoteText so value goes in Notes tag
-- V8.1 OR50281 Drop 1 setting correct Orderitemnotes text & type for delays '588','9562','9831','9561','5750'
-- V8.2 OR-46085 adding 9709 closure validation so that Delaynotetext wont be blanked and send the value same as the once in KCIdelayreasons
-- V8.3 R4000 OR-46085/ORCE-145641 To Set ECCBehaviour if parallel delay containing 5751 is stubbed.
-- V8.4 R4100 OR-50426/ORCE-149629 To Change text & add delaydate format for FTTP,FOD & FVA when 5750 KCI delay is being sent
-- V8.5 R4100 OR-48316 To change the length of orderStage  and set delay code as 0001
-- V8.6 R4150 OR-50978 Realigning the parameter which has been commented.
-- V8.7 R4150 OR-48771 To set delay code as 0002 and 0003 instead of 2 & 3 and store the Current delay reason in case of PIA
-- V8.8 R4150 OR-52294 To make Scale Architecture as exchange specific and changes are removed while adding this version
-- V8.9 R4200 OR-54839 To Set AppointmentFailed substatus for SOGEA 593 CP Delay.
-- V9.0 R4200 OR-55058 to Send 9494 linked order delayed on SMPF order when 5867 OR delay is sent on PSTN order.
-- V9.1 R4250 OR-54546 to set isTOPdelay flag for 572 - Order delayed due to issue in TOP stubbing
-- V9.2 R4250 OR-52277 Adding validation for SOTAP
-- V9.3 R4300 OR-56989 For Supplementary Process sending Nextupdate date
-- V9.3.1 Correction to send date in proper format
-- V9.4 R4300 OR-56324 To Send EAOS and NADT When SendEAOS='Y'
-- V9.4.1 To set Correct SendEAOS value.
-- V9.4.2 To set Correct Date for SendEAOS value.
-- V9.5 R4300 | Drop2 | OR-54661 | Parvesh | Adding changes for new delay codes
-- V9.6 OR-50870 | Parvesh | Sending Correct Text in DFX 5787 delay
-- V9.7 Hotfix - PSTN order to accept for CP amend when Links has been severed after 5197 delay
-- V9.8 Hotfix for updating delay notes and response code text for 9847,9848,9849 delays.
-- V9.9 R4500 Drop 2 OR-63817 to set apptreqd to Y when 9816 is stubbed.
-- V10.1 22/02/2021 R4600 Drop 2 agile story, to update the value for IsPinchPointValidation to Y when 593-Pinch point delay is stubbed
-- V10.2 R4700 OR-68107/ORCE-191806 To set EAOS and NADT for SOTAP.
-- V10.3 R4700 OXY001-1649/OXY001-1650 To send engineernotes in 5480.
-- V10.4 R4750 OR-62813/ORCE-184141 to set 9818 delay code for SOTAP
-- V10.5 CVFSR000779- Hotfix to send NADT tag only in case of Customer Delay
-- V10.6 OR-69092 To set delay reason for 9601 code
-- V10.7 R4850 OR-70386, Setting order cancelling date and Required Site Visit Reason for 9877 delay.
-- V10.8 R5000 OR-74688, setting SOTAP product for 9775 delay.
-- V10.9 R5050 OR-74715 setting order cancelling date and Required Site Visit Reason(advanced) for 9877 delay and adding delay notes.
-- V10.9.1 R5050 OR-74715 changing delaynotes to delay notes .
-- V10.9.2 R5050 OR-74715 commeenting to change to 15 calender days and added new calander date logic
-- V11.1 R5050 OR-70298 ORCE 197923 - SOGEA- Required Site Visit Reason(advanced) for 9877 +9700 delay and adding delay notes.
-- V11.1.1 R5050 OR-70298 ORCE 197923 - adding of @SVR in @pAdditionalNotesXML in order to send NotesText  as advanced or premium 
-- V12.0 R5100 OR-46548 ORCE-177914 - Fix to set EUConfirmedDelay based on new KCIdelayreason for LLU
-- V14.0 Nov 2022 NGA Improvements
--V14.1 Added EUConfirmedDelay Flag for FTTP
--V14.2 CVFSR001721 Adding abortivevisit required flag for SOTAP
-- V14.3 R5400 OR 83553 ORCE 230843 SOGEA - adding respective engineernotes for 9902,9903 and 9904 delay
-- V14.3.1 R5400 OR 83553 ORCE 230843 Update EUOrOpenreachMissed as Y for sending 5818 auto cancel KCI
-- V14.4 R5450 OR-80566 ORCE-224013 To skip 9544 KCI if it is 569 delay and migration from sotap
-- V14.5 R5550 Drop 1 ORTECH-9150 - ORTECH-8903 - To set abortive visit charges for EU delay for SOGEA Cease 
-- V14.6 R5650 ORTECH-11438 ORTECH-11439 FTTP - adding respective engineernotes for 9928 delay
-- V14.7 R5650 DROP1 ORTECH-11246 SOGEA - Adding engineernotes and delay notes for 9928 delay KCI.
-- V14.7.1 R5650 DROP1 ORTECH-11246 Update EUOrOpenreachMissed as Y for sending 5818 auto cancel KCI for 9928 delay.
-- V14.7.2 R5650 DROP1 ORTECH-11246 SOGEA - Adding engineernotes for five more delay resons for 600 Note text.
---V14.7.3 R5650 DROP1 ORTECH-11246 Adding valid Engineer notes for 600 Notecode.
 -- V14.8 R5650 - Drop 1 - ORTECH-10244 - Included 9877 pre KCI 2 delay 
-- V14.9 R5700 ORTECH-5657 ORTECH-6652 FTTP - adding respective engineernotes for 9931 delay and To set %1, %3 in case of 9931 delay.
-- V15.0 R5750 ORTECH-10591 ORTECH-10592 - @pKCIDelayReason='Excess Construction Charge with Ruggedised' sending new delaynotecode and delaynotetext
-- V15.1 R5750 ORTECH-5677 SOGEA - adding respective DelatNoteText for 9932 delay and To set %1, %2 in case of 9932 delay.
-- V15.2 R5750 ORTECH 9109 SOGEA for invalid OGHP setting SendAmendKSU as Y
-- V15.3 R5750 - Drop 2 - ORTECH-10328 - Included 9877 pre KCI 2 delay FOR Sogea
-- V15.4 CVFIM026943 - Adding the list of notes block for pre KCI 2 9877 scenarios 
-- V15.5 CVFSR002177  Setting AbortiveVisitChargesApplied to Y for 5197 Delay for FTTP
-- V15.6 CVFIM027051  Adding the list of notes block for pre KCI 2 9877 scenarios for SOGEA
-- V15.7 R5900 ORTECH-6350-7076 AbortiveVisitChargesApplied to Y for KCI9743, KCI5480 for SOTAP
-- Outputs are:-
-- AdditionalNotesXML Will be updated with new notes for KSU2 if ReappointmentReqd = "Y"
-- AppointmentReqd  we will update if the delay msg indicates an appointment is required
-- delayNoteCode  one or more codes | separated
-- delayNotes   other notes which doesnt appear in some examples.....great!!
-- delayNoteText  one or more notes | separated
-- delayNoteType  one or more types | separated
-- KCIDelayReason  blank or another reason code for subsequent msg
-- AmendRequired  Can be Y if a CP amend is required after the delay (no need to set if Appt Flag indicates this)
-- AmendReason   Can be set if a specific Amend reason is required (no need to set if standard Appt Flag used)
-- ConfirmationRequired Can be set if a specific confirmation value is needed (again can be Appt Flag controlled)
-- DeemedConsent  Can be used to control Deemed Consent logic. currently not implimented
-- DelayNoteFormat Can be used to control the format of the note if not the default. eg for GEA you can have ReasonCode/Notes (default so blank value) or Notes format (so set to NOTES)
-- EngineerNotes  Can be used to output Engineer Notes that might relate to the delay
-- ReappointmentReqd can be :-   -- N = no appointment impact
-- Y = OR rebooks appointment one working day ahead before the delay is sent
-- Z = OR rebooks appointment one working day ahead but without any note
-- V*  as Y/Z above but preceeded with a V = Send a revised KSU2 after the delay and appointment booking eg: VZ sends delay then books appt and sends revised KSU2
-- CP = Amend Required from CP with new appointment "In Response to customer delay"
-- CPBT = Amend Required from CP with new appointment "In Response to BT delay"
-- For some flows such as GEA/LLU the following complex logic also applies:-
-- A0 = OR rebooks appointment for existing CCD AFTER the delay and sends details in an OSU
-- A1 = OR rebooks appointment 1 working day ahead AFTER the delay and sends details in an OSU
-- A3 = as per A1 but 3 working days later
-- A10 = as per A1 but 10 working days later
-- C* as A* above but preceeded with a C = as per A1, A3, A10, etc but CP needs to confirm with amend "In Response to customer delay". eg CA3
-- P* as A* above but preceeded with a P = as per A1, A3, A10, etc but OR only proposes new date (CCD unchanged) GEA ONLY. CP needs to confirm with amend "In Response to customer delay". eg PA10
-- R* as A* above but preceeded with a R = as per A1, A3, A10, etc but OR sets CRD after amend OSU sent and CP needs to confirm with amend "In Response to customer delay". eg RA10
-- N1 = Update CCD to 1 working day but don't send the amend KSU 540
-- *BT as A*, CA*, PA* above but suffixed with BT = as per A,CA, etc but CP needs to confirm with amend "In Response to BT delay". eg CA10BT
-- For now we only have details on a single delay msg but the | separated value definitions are there
-- for expansion as more info becomes available. Potentially we might need to add this note to all delays
--  Informational
--  5183
--  Order Delay
-- so if needed we can just prepend the values & |'s
-- KSUDelayTrigger has the following values:
-- (blank/null/empty) : no implied override trigger, execute delay as normal
-- "N" : delay must not be invoked for this order stage
-- ValidOrderStages  Can be set for a delay entry in the table to ensure delay is only fired when the order stage matches. Entries in the table can be comma separated if required
-- Stages can be any of the valid stages set by the actions SET_STAGE_* in the flows
-- spSetKSUDelayDetails 'N','569 - Delay Faulty Tie Pair Amend Appointment','R1600','KSU2','OS011-60871534012','','',''
-- EXEC [dbo].[spSetKSUDelayDetails] 'Y','8016','R2200','KSU1','OR011-21801001609','','','N'
-- EXEC [dbo].[spSetKSUDelayDetails]  'N','HAZ - Hazard','R4300','KSU2','OS011-23783693629','','','N'

-- =============================================
CREATE PROCEDURE [dbo].[spSetKSUDelayDetails]
	(@pAppointmentReqd    AS VARCHAR(1), --AppointmentReqd  amended if required and returned
	@pKCIDelayReason     AS VARCHAR(200),--DelayReason  replaced with subsequent reason
	@pRelease  AS VARCHAR(10), --RELEASE  used for lookup as different releases return different msgs or msg text
	@pOrderStage    AS VARCHAR(100), --OrderStage  used to determin if we are at the correct order stage for reappointment delays  --V8.5
	@pOrderNumber  AS VARCHAR(20), --OrderNumber   used to record the delay and datetime as an order param
	@pAdditionalNotesXML AS VARCHAR(max),--AdditionalNotesXML amended and returned
	@pKSUDelayTrigger    AS VARCHAR(20),-- overrided trigger value for CR118
	@pAmendRequired AS VARCHAR(1)
)
-- Y/N or blank if not set
AS
BEGIN
	DECLARE @ReleaseNumber INT
	DECLARE @temp VARCHAR(255)
	DECLARE @delayNoteType VARCHAR(50)
	DECLARE @delayNoteText VARCHAR(max)
	DECLARE @delayNoteCode VARCHAR(max)
	DECLARE @delayNotes VARCHAR(max)
	DECLARE @ReAppointmentReqd VARCHAR(max)
	DECLARE @SubsequentReason VARCHAR(200)
	DECLARE @AmendRequired VARCHAR(10)
	DECLARE @AmendReason VARCHAR(50)
	DECLARE @ConfirmationRequired VARCHAR(50)
	DECLARE @DeemedConsent VARCHAR(255)
	DECLARE @ValidOrderStages VARCHAR(255)
	DECLARE @EngineerNotes VARCHAR(255)
	DECLARE @DelayNoteFormat VARCHAR(10)
	DECLARE @Valid VARCHAR(1)
	DECLARE @SequenceNo INT
	-- V2.1 Begin
	DECLARE @SIM2Marker VARCHAR(2)
	DECLARE @Product1Name VARCHAR(max)
	DECLARE @KCI VARCHAR(5)
	DECLARE @OrderItemNoteType VARCHAR (max)
	DECLARE @OrderItemNoteText VARCHAR (max)
	DECLARE @LORN VARCHAR(max)
	DECLARE @Order2Number VARCHAR(25)
	DECLARE @RefId VARCHAR(max)
	DECLARE @MPFReappointmentReqd VARCHAR(8)
	DECLARE @NoteCode VARCHAR(max)
	DECLARE @NoteText VARCHAR(max)
	DECLARE @NoteType VARCHAR(max)
	DECLARE @LOAmendReason VARCHAR(max)
	DECLARE @IsSuccessionalProvide VARCHAR(1) --V6.6
	-- V2.1 End
	DECLARE @Consumerfirstdelay NVARCHAR(100) -- V5.2   -- V2.2 Begin
	DECLARE @LO_DelayReason VARCHAR(max)
	-- V2.2 End
	-- V2.3 Begin
	DECLARE @TempDelayCode VARCHAR(10)
	-- V2.3 End
	-- V2.6 Begin
	DECLARE @SIM2Migrate VARCHAR(max)
	-- V2.6 End
	DECLARE @Product2Name VARCHAR(max)--V2.11
	--V5.6 Starts
	DECLARE @TargetLineServiceID VARCHAR(max)   DECLARE @TargetAccessLineId VARCHAR(max)
	DECLARE @TargetDNavailable VARCHAR(1)
	DECLARE @TRCBand int  --V7.2
	DECLARE  @pos int
	DECLARE @KCIDelaycodes VARCHAR(max)
	DECLARE @CommitmentDate VARCHAR(10)    --V7.2.1
	DECLARE @CommitmentDate2 VARCHAR (20)  --V10.6
	SET @TargetLineServiceID = ''
	SET @TargetAccessLineId = ''
	SET @TargetDNavailable='N'
	--V5.6 Ends
	DECLARE @Nextupdatedate VARCHAR(20) =NULL--V9.3
	--V4.0 Starts
	DECLARE @SIM2PCPOnly VARCHAR(2) 

	SET @SIM2PCPOnly = 'N'
	--V4.0 Ends
	SET @Valid = 'Y'
	SET @SequenceNo = 0
	SET @SIM2Marker = 'N'
	-- V2.6 Begin
	SET @SIM2Migrate = 'N'

	-- V2.6 End
	-- V2.12 Begin
	DECLARE @OrderDate AS DATETIME
	DECLARE @OrderDateNvarchar AS VARCHAR(20)
	DECLARE @WK VARCHAR(30)
	DECLARE @CalculatedDate AS VARCHAR(20)
	DECLARE @externalNotes AS VARCHAR(max)

	SET @externalNotes=''
	SET @delayNotes=''

	-- V2.12 End
	DECLARE @Activitycompletiondate NVARCHAR(30)
	-- V4.9
	-- V2.1 Begin
	DECLARE @EUConfirmedDelay VARCHAR (2) = '' --V5.9
	DECLARE @EUOrOpenreachMissed VARCHAR(2) = '' --V5.9
	DECLARE @9708Requested VARCHAR(2) = 'N'
	--V6.1
	DECLARE @AppointmentFailed VARCHAR(2) = 'N'   --V8.9
	SELECT @Product1Name = value 
	FROM   orderparams
	WHERE  ( ordernumber = @porderNumber )
	AND ( NAME = 'ProductName' )

	DECLARE @SendEAOS AS VARCHAR (2) = '' -- V9.4
	SET @SendEAOS=(SELECT Top 1 SendEAOS from KCIdelayreasons WHERE KCIDelayReason=@pKCIDelayReason) --V9.4.1
	 --V10.5 Starts
    DECLARE @DelayType VARCHAR(20)='' 
    SET @DelayType =(SELECT TOP 1 DelayType FROM KCIDelayReasons WHERE KCIDelayReason=@pKCIDelayReason)
     --V10.5 Ends
	--V9.1 Starts 
	DECLARE @Res Varchar(20)
	DECLARE @isTOPdelay as varchar(5)
	SET @isTOPdelay ='N'
	IF @pKCIDelayReason='572 - Order delayed due to issue in TOP'
		SET @isTOPdelay ='Y'

	--V9.1 Ends
	-- V6.4 starts
	DECLARE @Arrivalslot as varchar (50)
	DECLARE @pRingAhead as varchar (200)
	DECLARE @pTaskClosureReason as varchar (200)
	DECLARE @BundleId as varchar(20)
	SET  @Arrivalslot=''
	SET @pRingAhead=''
	SET @pTaskClosureReason=''

	DECLARE @Addressnadkey varchar(20) -- V7.6
	DECLARE @FTTPOrderStages Varchar(2);  -- V7.6
	DECLARE @DelayRefNo  varchar(20) --V8.1
	--V7.4 Starts
	IF(@Product1Name='EAD' and @pKCIDelayReason='9275 - Unable to Gain Access')
	BEGIN
		INSERT INTO OrderParams values(@pOrderNumber,'Is9275','Y')
	END
	--V7.4 Ends
	--V10.1 Starts
	IF(@Product1Name='EAD' and @pKCIDelayReason='593-Pinch point delay')
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='IsPinchPointValidation')
			UPDATE ORDERPARAMS SET VALUE='Y' where name='IsPinchPointValidation' and ordernumber=@pOrderNumber
		IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='IsPinchPointValidation')
			INSERT INTO OrderParams values(@pOrderNumber,'IsPinchPointValidation','Y') 
	END
	--V10.1 Ends

	IF (@Product1Name='WLR3 PSTN Single Line' or @Product1Name='WLR3 PSTN Multiline Aux' or @Product1Name='MPF' or  @Product1Name='WLR3 ISDN 2e Standard' or @Product1Name='WLR3 ISDN 2e System' or @Product1Name='SOTAP' and @pKCIDelayReason like'%9775%') -- V10.8
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='Arrivalslot')
			SELECT @Arrivalslot = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'Arrivalslot' )
		IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='RingAhead')
			SELECT @pRingAhead = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'RingAhead' )
		IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='TaskClosureReason')
			SELECT @pTaskClosureReason = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'TaskClosureReason' )
	END
	-- V6.4 ends
	-- V6.4 start
	IF (@Arrivalslot='' and  @Product1Name='MPF' )
	BEGIN
		select @BundleId=ISNULL(value,'') FROM orderparams WHERE Name = 'BundleId' and Ordernumber=@pOrderNumber
		IF (@BundleId<>'')
		BEGIN
			SELECT TOP 1 @Arrivalslot=ISNULL(Value,'') FROM orderparams WHERE ordernumber in (
			SELECT OrderNumber FROM orderparams WHERE Name = 'BundleId' and Value =@BundleId) and Name = 'Arrivalslot' and Value != '' SELECT TOP 1 @pRingAhead=ISNULL(Value,'') FROM orderparams WHERE ordernumber in (

			SELECT OrderNumber FROM orderparams WHERE Name = 'BundleId' and Value =@BundleId) and Name = 'RingAhead' and Value != ''
			SELECT TOP 1 @pTaskClosureReason=ISNULL(Value,'') FROM orderparams WHERE ordernumber in (
			SELECT OrderNumber FROM orderparams WHERE Name = 'BundleId' and Value =@BundleId) and Name = 'TaskClosureReason' and Value != ''
		END
	END
	-- V6.4 ends
	--V6.3 starts(To store the PostKCI2Waiters 578 delay in a dummy variable to send 540(EU Confirmed) or 9600(EU Unconfirmed))--
	IF @Product1Name = 'Generic Ethernet Access' AND @pKCIDelayReason = 'POSTKCI2WAITERS_578_EU_Confirmed' OR @pKCIDelayReason = 'POSTKCI2WAITERS_578_EU_UnConfirmed'
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM orderparams WHERE orderparams.NAME = '578_PostKCIWAITERS_Delayreason' AND orderparams.ordernumber = @pOrderNumber)
		BEGIN
			UPDATE dataprovider.dbo.orderparams SET value = @pKCIDelayReason WHERE NAME = '578_PostKCIWAITERS_Delayreason' AND ordernumber = @pOrderNumber
		END
		ELSE
		BEGIN
			INSERT INTO [DataProvider].[dbo].[orderparams] ([ordernumber],[name],[value])  VALUES (@pOrderNumber, '578_PostKCIWAITERS_Delayreason',  @pKCIDelayReason)
		END
	END
	--V6.3 ends--
	--V7.1 starts (To store 572 retention delay reason in a dummy variable to send 9798)
	IF (@Product1Name = 'Generic Ethernet Access - FTTP' OR @Product1Name = 'FVA') AND @pKCIDelayReason = 'GEA 572 - Delayed in Processing with Retention'
	BEGIN
		UPDATE OrderParams SET Value = @pKCIDelayReason WHERE NAME = '572_DelayWithRetention_Reason' AND OrderNumber = @pOrderNumber
		IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO OrderParams (OrderNumber, [Name], [Value]) VALUES (@pOrderNumber, '572_DelayWithRetention_Reason', @pKCIDelayReason)
		END
	END
	--V7.1 ends
	--v4.3 BEGINS
	IF @Product1Name = 'SBS' AND @pKCIDelayReason = '9494 - Linked order delayed'
	BEGIN
		SELECT @delayNotes = '',
		@delayNoteType = 'Warning',
		@delayNoteText = 'Linked order delayed.',
		@delayNoteCode = 9494,
		@ReAppointmentReqd = 'N',
		@SubsequentReason = @pKCIDelayReason,
		@AmendRequired = NULL,
		@AmendReason = NULL,
		@ConfirmationRequired = @MPFReappointmentReqd,
		@DeemedConsent = NULL,
		@ValidOrderStages = 'KSU2',
		@EngineerNotes = NULL,
		@DelayNoteFormat = NULL,
		@NoteCode = '9494',
		@NoteText = 'Linked order delayed.',
		@NoteType = 'Warning'
	END
	--v4.3 ENDS
	IF @Product1Name = 'Generic Ethernet Access'
	BEGIN
		SELECT @SIM2Marker = value FROM orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'SIM2Marker' )
		-- V2.6 Begin ## Getting the SIM2Migrate Value for GEA
		SELECT @RefId = value FROM orderparams WHERE (ordernumber = @porderNumber) AND (NAME = 'GeSSLoggingRef' )
		SET @SIM2Migrate = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE TypePro.[key] = @RefId AND TypePro.NAME = 'SubType')
		
		--V14.0 NGA Improvement Begins
			IF ISNULL(@SIM2Migrate,'')='' SELECT @SIM2Migrate=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'SubType')
		--V14.0 NGA Improvement Ends
		-- V2.6 End
		-- V4.0 Starts
		SET @SIM2PCPOnly = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE TypePro.[key] = @RefId AND TypePro.NAME = 'SIM2PCPOnly')
		--V4.0 Ends
		--V14.0 NGA Improvement Begins
			IF ISNULL(@SIM2PCPOnly,'')='' SELECT @SIM2PCPOnly=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'SIM2PCPOnly')
		--V14.0 NGA Improvement Ends
		
		IF @SIM2Marker = 'Y'
		BEGIN
			SELECT @LORN = value FROM orderparams WHERE ( ordernumber = @porderNumber ) AND ( NAME = 'LinkedOrderReference' )
		END
		IF Isnull(@LORN, '') <> ''
		BEGIN
			SELECT @Order2Number = C.ordernumber FROM   orderparams A  INNER JOIN orderparams B  ON A.value = B.value   --V2.6
			INNER JOIN orderparams C ON C.ordernumber = A.ordernumber
			WHERE  A.ordernumber <> B.ordernumber AND ( A.NAME = 'LinkedOrderReference'  OR A.NAME = 'SMPFLinkOrdRef' )
			AND B.NAME = 'LinkedOrderReference'  --V2.9
			AND A.value = @LORN
			AND B.ordernumber = @pOrderNumber
			AND C.NAME = 'ProductName'
			AND ( C.value = 'MPF'
			OR C.value = 'WLR3 PSTN Single Line' )
			--V2.9
		END
		IF Isnull(@Order2Number, '') <> ''
		BEGIN
			SELECT @RefId = value FROM orderparams WHERE  ( ordernumber = @Order2Number ) AND ( NAME = 'GeSSLoggingRef' )
			--V5.6 Starts
			SELECT @Product2Name = value FROM orderparams WHERE (ordernumber = @Order2Number ) AND ( NAME = 'ProductName' )
			SELECT @TargetLineServiceID = value  FROM orderparams WHERE (ordernumber = @Order2Number) AND ( NAME = 'TargetLineServiceID' ) 
			SELECT @TargetAccessLineId = value FROM orderparams WHERE (ordernumber = @Order2Number) AND ( NAME = 'TargetAccessLineId' )
			IF ( Isnull(@TargetLineServiceID, '') <> '' OR Isnull(@TargetAccessLineId, '') <> '' )
			BEGIN
				SET @TargetDNavailable='Y'
			END
			--V5.6 Ends
		END
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @MPFReappointmentReqd = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'ReappointmentReqd')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@MPFReappointmentReqd,'')='' SELECT @MPFReappointmentReqd=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'ReappointmentReqd')
			--V14.0 NGA Improvement Ends
		END
		-- V2.3 Begin
		SET @TempDelayCode = (SELECT TypePro.value FROM  typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'delayNoteCode')
		  
		  --V14.0 NGA Improvement Begins
				IF ISNULL(@TempDelayCode,'')='' SELECT @TempDelayCode=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'delayNoteCode')
			--V14.0 NGA Improvement Ends
		
		-- V2.3 End
	END
	--V5.9 STARTS

	IF( (@Product1Name = 'SOGEA'  OR @Product1Name='Generic Ethernet Access'OR @Product1Name = 'Generic Ethernet Access - FTTP')  AND @pKCIDelayReason LIKE '%EU Confirmed%' ) OR @pKCIDelayReason = '566 - OR Missed Appt (EU Confirmed LLU)'--7.3 -- 7.5  -- V12.0  
	--V14.1
		SET @EUConfirmedDelay = 'Y'
	ELSE
		SET @EUConfirmedDelay = 'N'

	IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE OrderNumber = @pOrderNumber AND Name = 'EUConfirmedDelay') --V7.7 starts
		INSERT INTO OrderParams VALUES (@pOrderNumber , 'EUConfirmedDelay', @EUConfirmedDelay)
	ELSE
		UPDATE OrderParams SET [Value] = @EUConfirmedDelay WHERE OrderNumber = @pOrderNumber AND Name = 'EUConfirmedDelay' --v7.7 ends
	--V6.1 STARTS
	IF @Product1Name = 'SOGEA' AND @pKCIDelayReason LIKE '%9708%'
		SET @9708Requested = 'Y'
	ELSE
		SET @9708Requested = 'N'
	--V6.1ENDS
	--V5.9 ENDS
	IF @Product1Name = 'MPF'
	BEGIN
		SELECT @SIM2Marker = value FROM orderparams WHERE (ordernumber = @porderNumber) AND ( NAME = 'SIM2Marker' )
		-- V2.6 Begin ## Getting the SIM2Migrate Value for LLU
		SELECT @RefId = value  FROM orderparams  WHERE (ordernumber = @porderNumber ) AND ( NAME = 'GeSSLoggingRef' )
		SET @SIM2Migrate = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'SubType')
		
		--V14.0 NGA Improvement Begins
				IF ISNULL(@SIM2Migrate,'')='' SELECT @SIM2Migrate=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'SubType')
		--V14.0 NGA Improvement Ends
		-- V2.6 End
		IF @SIM2Marker = 'Y' 
		BEGIN
			SELECT @LORN = value FROM orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'LinkedOrderReference' )
		END
		IF Isnull(@LORN, '') <> ''
		BEGIN
			SELECT @Order2Number = C.ordernumber  FROM   orderparams A  INNER JOIN orderparams B  ON A.NAME = B.NAME AND A.value = B.value
			INNER JOIN orderparams C ON C.ordernumber = A.ordernumber
			WHERE  A.ordernumber <> B.ordernumber 
			AND A.NAME = 'LinkedOrderReference'
			AND B.NAME = 'LinkedOrderReference'    AND A.value = @LORN 
			AND B.ordernumber = @porderNumber
			AND C.NAME = 'ProductName'
			AND C.value = 'Generic Ethernet Access'
		END
		IF Isnull(@Order2Number, '') <> ''
		BEGIN
			SELECT @RefId = value FROM orderparams WHERE  ( ordernumber = @Order2Number ) AND ( NAME = 'GeSSLoggingRef' )
		END
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @MPFReappointmentReqd = (SELECT TypePro.value  FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'ReappointmentReqd')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@MPFReappointmentReqd,'')='' SELECT @MPFReappointmentReqd=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'ReappointmentReqd')
			--V14.0 NGA Improvement Ends
		END

		--V4.0 Starts
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @SIM2PCPOnly = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE TypePro.[key] = @RefId AND TypePro.NAME = 'SIM2PCPOnly')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@SIM2PCPOnly,'')='' SELECT @SIM2PCPOnly=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'SIM2PCPOnly')
			--V14.0 NGA Improvement Ends
			
		END
		--V4.0 Ends
	END

	---V2.9 starts
	IF @Product1Name = 'WLR3 PSTN Single Line'
	BEGIN
		SELECT @SIM2Marker = value FROM   orderparams  WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'SIM2Marker' )
		SELECT @RefId = value FROM orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'GeSSLoggingRef' )
		SET @SIM2Migrate = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE TypePro.[key] = @RefId AND TypePro.NAME = 'SubType')
		
		--V14.0 NGA Improvement Begins
				IF ISNULL(@SIM2Migrate,'')='' SELECT @SIM2Migrate=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'SubType')
		--V14.0 NGA Improvement Ends
		--V2.11 Starts
		DECLARE @LASTDelayNote AS VARCHAR(10)
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @LASTDelayNote = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME ='LastDelayNoteCode')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@LASTDelayNote,'')='' SELECT @LASTDelayNote=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'LastDelayNoteCode')
			--V14.0 NGA Improvement Ends
		END
		--V2.11 Ends
		IF @SIM2Marker = 'Y'
		BEGIN
			SELECT @LORN = value FROM   orderparams WHERE (ordernumber = @porderNumber ) AND ( NAME = 'SMPFLinkOrdRef' )
		END
		IF Isnull(@LORN, '') <> ''
		BEGIN
			SELECT @Order2Number = C.ordernumber FROM orderparams A  INNER JOIN orderparams B  ON A.value = B.value 
			INNER JOIN orderparams C ON C.ordernumber = A.ordernumber 
			WHERE  A.ordernumber <> B.ordernumber 
			AND A.NAME = 'LinkedOrderReference' 
			AND B.NAME = 'SMPFLinkOrdRef' 
			AND A.value = @LORN 
			AND B.ordernumber = @pOrderNumber 
			AND C.NAME = 'ProductName' 
			AND ((C.value = 'Generic Ethernet Access') OR (C.value = 'SMPF')) 
		END
		IF Isnull(@Order2Number, '') <> ''
		BEGIN
			SELECT @RefId = value FROM orderparams WHERE  ( ordernumber = @Order2Number ) AND ( NAME = 'GeSSLoggingRef' )
			SELECT @Product2Name = value FROM orderparams WHERE (ordernumber = @Order2Number ) AND ( NAME = 'ProductName' )   --V4.1
		END
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @MPFReappointmentReqd = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'ReappointmentReqd')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@MPFReappointmentReqd,'')='' SELECT @MPFReappointmentReqd=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'ReappointmentReqd')
			--V14.0 NGA Improvement Ends
		END

		--V4.0 Starts 
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @SIM2PCPOnly = (SELECT TypePro.value FROM   typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'SIM2PCPOnly')
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@SIM2PCPOnly,'')='' SELECT @SIM2PCPOnly=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'SIM2PCPOnly')
			--V14.0 NGA Improvement Ends
		END
		--V4.0 Ends
	END
	---V2.9 Ends
	--V2.10 Starts
	IF @Product1Name = 'SMPF' 
	BEGIN
		SELECT @SIM2Marker = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'SIM2Marker' )
		SELECT @RefId = value  FROM orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'GeSSLoggingRef' )
		SET @SIM2Migrate = (SELECT TypePro.value FROM   typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'SubType')
		
		--V14.0 NGA Improvement Begins
				IF ISNULL(@SIM2Migrate,'')='' SELECT @SIM2Migrate=dbo.fnGetInprogressDataParamValue(@pOrderNumber,@RefId,'SubType')
			--V14.0 NGA Improvement Ends



		IF @SIM2Marker = 'Y'
		BEGIN
			SELECT @LORN = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'LinkedOrderReference' )
		END
		IF Isnull(@LORN, '') <> ''
		BEGIN
			SELECT @Order2Number = C.ordernumber FROM   orderparams A  INNER JOIN orderparams B  ON A.value = B.value 
			INNER JOIN orderparams C ON C.ordernumber = A.ordernumber
			WHERE  A.ordernumber <> B.ordernumber
			AND A.NAME = 'SMPFLinkOrdRef'
			AND B.NAME = 'LinkedOrderReference'
			AND A.value = @LORN
			AND B.ordernumber = @pOrderNumber
			AND C.NAME = 'ProductName'
			AND ( C.value = 'WLR3 PSTN Single Line' )
		END
		IF Isnull(@Order2Number, '') <> ''
		BEGIN
			SELECT @RefId = value FROM orderparams WHERE (ordernumber = @Order2Number ) AND ( NAME = 'GeSSLoggingRef' )
			SELECT @Product2Name = value FROM orderparams WHERE ( ordernumber = @Order2Number ) AND ( NAME = 'ProductName' )
			--V2.11
		END
		IF Isnull(@RefId, '') <> ''
		BEGIN
			SET @MPFReappointmentReqd = (SELECT TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'ReappointmentReqd')   --V2.11 starts
			SET @TempDelayCode = (SELECT TypePro.value FROM   typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME ='delayNoteCode')
			SET @Consumerfirstdelay = (SELECT TOP 1 TypePro.value FROM typeprocessor.dbo.inprogressdata TypePro WHERE  TypePro.[key] = @RefId AND TypePro.NAME = 'KCI9652Notes')    -- V5.2
			
			
			--V14.0 NGA Improvement Begins
				IF ISNULL(@MPFReappointmentReqd,'')='' SELECT @MPFReappointmentReqd=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'ReappointmentReqd')
				IF ISNULL(@TempDelayCode,'')='' SELECT @TempDelayCode=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'delayNoteCode')
				IF ISNULL(@Consumerfirstdelay,'')='' SELECT @Consumerfirstdelay=dbo.fnGetInprogressDataParamValue(@Order2Number,@RefId,'KCI9652Notes')
			--V14.0 NGA Improvement Ends
			--V2.11 ends
		END
	END

	--V2.10 Ends
	SET @KCI = LEFT(@pKCIDelayReason, 4)
	-- V2.1 End

	--V2.10 starts
	IF Isnull(@SIM2Marker, '') = 'Y'AND @KCI = '9580'
	BEGIN
		-- skip the delay for now and let it fire later in the flow
		IF @pKSUDelayTrigger = 'N'
		BEGIN
			SET @Valid = 'N'
		END
		IF @Valid = 'Y'
		BEGIN
			SET @Temp = Substring(@prelease, 2, 5)
			-- get the numerical part
			IF Isnumeric(@temp) = 1
				SET @ReleaseNumber = @temp
			ELSE
				SET @ReleaseNumber = 99999
			-- default to max for now as release should always be set
			IF @Product1Name = 'WLR3 PSTN Single Line'
			BEGIN
				SELECT @delayNotes = '', 
				@delayNoteType = 'Informational',
				@delayNoteText ='Links between the orders have been severed. This order is now proceeding as a stand-alone order due to tie pair / frames issues on the SMPF order',
				@delayNoteCode = '9580',
				@ReAppointmentReqd = 'N',
				@SubsequentReason = '',
				@AmendRequired = 'N',
				@AmendReason = '',
				@ConfirmationRequired = 'N',
				@DeemedConsent = NULL,
				@ValidOrderStages = 'KSU2',
				@EngineerNotes = NULL,
				@DelayNoteFormat = NULL,
				@OrderItemNoteType = 'Informational',
				@OrderItemNoteText =
				'9580;Links between the orders have been severed. This order is now proceeding as a stand-alone order due to tie pair / frames issues on the SMPF order' 
			END

			IF @ReAppointmentReqd = 'N'
				SET @pAppointmentReqd='N'
			-- ensure the calling flow knows we dont have an appointment to handle
			-- generate a unique number and log the KSU in the order params table
			SET TRANSACTION isolation level READ committed
			BEGIN TRANSACTION
			BEGIN try
				UPDATE dpdata SET valuenum = valuenum + 1, @SequenceNo = valuenum + 1  FROM dpdata  WHERE  ( keyname = 'DelaySequenceNumber' AND paramname = 'BaseID' )
				-- insert an OrderParam with the date and delay details for future tracking
				INSERT INTO orderparams (ordernumber,NAME,value) VALUES (@pOrderNumber,'KSUDelay-'+ Cast(@SequenceNo AS VARCHAR(50)), CONVERT(VARCHAR(19), Getdate(), 127) + '|' + @delayNoteCode + '|' + @delayNoteText)
				COMMIT TRANSACTION
			END try
			BEGIN catch
				ROLLBACK TRANSACTION 
			END catch 
		END
		SELECT @pAdditionalNotesXML  AS AdditionalNotesXML,
		@pAppointmentReqd     AS AppointmentReqd,
		@delayNoteCode   AS delayNoteCode,
		@delayNotes AS delayNotes,
		@delayNoteText   AS delayNoteText,
		@delayNoteType   AS delayNoteType,
		@SubsequentReason     AS KCIDelayReason,
		-- return the follow on reason (will be blank if no further delays required)
		@ReappointmentReqd    AS ReappointmentReqd,
		@AmendReason     AS delayAmendReason,
		@AmendRequired   AS AmendRequired,
		@ConfirmationRequired AS delayConfirmationRequired,
		@DeemedConsent   AS DeemedConsent,
		@EngineerNotes   AS EngineerNotes,
		@DelayNoteFormat AS DelayNoteFormat,
		@SequenceNo AS DelaySequenceNumber,
		@OrderItemNoteType    AS OrderItemNoteType,
		@OrderItemNoteText    AS OrderItemNoteText,
		@NoteCode   AS NoteCode,
		@NoteText   AS NoteText,
		@NoteType   AS NoteType
	END
	--V2.10 ends
	-- V2.1 Begin
	-- V7.6 Starts
	-- Conditions for OR-44563: Order have to be an 2-stage order, SSN should be one of the one configured for scale and  Legacy Architecture
	IF @pKCIDelayReason in ('Waiting for Permission (FTTP)','5464 and 5462 FTTP','5462 Survey Task','5464 - Underground Network Delay')
	BEGIN
		DECLARE @ServingNetworkNotes Varchar(50)
		Select  @Addressnadkey=Addressnadkey from orders where ordernumber =@pOrderNumber
		IF EXISTS(SELECT TOP 1 1 from OrderParams where ordernumber=@pOrderNumber AND Name='FTTPOrderStages')
		BEGIN
			Select  @FTTPOrderStages=Value from OrderParams where ordernumber=@pOrderNumber AND Name='FTTPOrderStages'
		END
		IF EXISTS(SELECT TOP 1 1 FROM AddressParams WHERE AddressNadKey=@Addressnadkey AND Name='ServingNetworkNotes')
		BEGIN
			SET @ServingNetworkNotes=(SELECT Value FROM AddressParams WHERE AddressNadKey=@Addressnadkey AND Name='ServingNetworkNotes')
		END
		DECLARE @IsScaleFTTP VARCHAR(10)='N'
		--V8.8 Starts
		IF EXISTS(SELECT TOP 1 1 FROM AddressParams WHERE AddressNadKey=@Addressnadkey AND Name='HybridScaleFTTP')
		BEGIN
			SET @IsScaleFTTP=(SELECT VALUE  FROM Addressparams WHERE Name='HybridScaleFTTP' and AddressNadkey=@Addressnadkey) 
		END

		IF EXISTS(select TOP 1 1 from Dataprovider.dbo.ExchangeParams where Exchangecode=(Select ExchangeGroupcode from addresses where addressnadkey=@Addressnadkey) and Name='ScaleEnabled')
		BEGIN
			SET @IsScaleFTTP=(select Value from Dataprovider.dbo.ExchangeParams where Exchangecode=(Select ExchangeGroupcode from addresses where addressnadkey=@Addressnadkey) and Name='ScaleEnabled')
		END
		--V8.8 Ends
		IF(@IsScaleFTTP='Y' AND @ServingNetworkNotes IN ('UG congested duct','UG Potential Wayleave Issues','UG partial Direct In Ground','UG Feed Not Evaluated') AND @FTTPOrderStages='2')
		BEGIN
			SET @Valid='Y'
		END
		ELSE IF(@IsScaleFTTP='N' AND @ServingNetworkNotes IN ('UG congested duct','UG Potential Wayleave Issues','UG partial Direct In Ground','UG Part proven','UG navigable with camera','UG Linked duct','OH Potential Wayleave issues') AND @FTTPOrderStages='2')
		BEGIN
			SET @Valid='Y'
		END
		ELSE
			SET @Valid='N'
		END
		-- V7.6 Ends
		IF Isnull(@SIM2Marker, '') = 'Y' AND @KCI = '9494'
		BEGIN
			-- skip the delay for now and let it fire later in the flow
			IF @pKSUDelayTrigger = 'N'
			BEGIN
				SET @Valid = 'N'
			END
			IF @Valid = 'Y'
			BEGIN
				SET @Temp = Substring(@prelease, 2, 5)
				-- get the numerical part
				IF Isnumeric(@temp) = 1
					SET @ReleaseNumber = @temp
				ELSE
					SET @ReleaseNumber = 99999
				-- default to max for now as release should always be set
				-- select the values for New Delay Code 9494. This is a warning message.
				IF @Product1Name = 'Generic Ethernet Access'  
				BEGIN
				-- V2.2 Begin
				--   SELECT  @delayNotes='', @delayNoteType='Warning', @delayNoteText='Openreach has been advised of a potential delay on the associated order, which may impact on delivery of broadband.
				--If a delay is confirmed, a message will be sent to update you of the revised CCD.',
				--   @delayNoteCode=625, @ReAppointmentReqd=@MPFReappointmentReqd, @SubsequentReason='',@AmendRequired=NULL,@AmendReason=NULL, 
				-- @ConfirmationRequired=@MPFReappointmentReqd,@DeemedConsent=NULL,@ValidOrderStages='KSU2', @EngineerNotes=NULL,@DelayNoteFormat=NULL,
				--   @OrderItemNoteType = 'Warning', @OrderItemNoteText='9494;Linked order delayed.',@AmendReason = 'Re-synchronisation'
					IF @pOrderStage = 'KSU2'
					--V2.9 starts
					--V4.0 Starts
					BEGIN
						IF @SIM2PCPOnly = 'N'
						BEGIN
							SELECT  @delayNotes = '',
							@delayNoteType = 'Warning',
							@delayNoteText = 'Linked order delayed.',
							@delayNoteCode = 9494,
							@ReAppointmentReqd = @MPFReappointmentReqd,
							@SubsequentReason = '',
							@AmendRequired = NULL,
							@AmendReason = 'Re-synchronisation',
							@ConfirmationRequired = @MPFReappointmentReqd,
							@DeemedConsent = NULL,
							@ValidOrderStages = 'KSU2',
							@EngineerNotes = NULL,
							@DelayNoteFormat = NULL,
							@OrderItemNoteType = 'Warning',
							@OrderItemNoteText = '9494;Linked order delayed.'
						END
						--V4.0 Ends
						ELSE
						BEGIN
							SELECT @delayNotes = '',
							@delayNoteType = 'Warning',
							@delayNoteText = 'Linked order delayed.',
							@delayNoteCode = 9494,
							@ReAppointmentReqd = 'N',
							@SubsequentReason = '',
							@AmendRequired = NULL,
							@AmendReason = 'Re-synchronisation',
							@ConfirmationRequired = @MPFReappointmentReqd,
							@DeemedConsent = NULL,
							@ValidOrderStages = 'KSU2',
							@EngineerNotes = NULL,
							@DelayNoteFormat = NULL,
							@OrderItemNoteType = 'Warning',
							@OrderItemNoteText = '9494;Linked order delayed.'
						END
					END
					ELSE IF ( @pOrderStage = 'KSU1.5' )
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Warning',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = 9494,
						@ReAppointmentReqd = @MPFReappointmentReqd,
						@SubsequentReason = '',
						@AmendRequired = NULL, 
						@AmendReason = 'Re-synchronisation',
						@ConfirmationRequired = @MPFReappointmentReqd,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU1.5',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@OrderItemNoteType = 'Warning',
						@OrderItemNoteText = '9494;Linked order delayed.'
					END
					-- V2.2 End
					-- V2.7 Begin
					IF @MPFReappointmentReqd = 'W' OR @MPFReappointmentReqd = 'A1'
					BEGIN
						SET @ConfirmationRequired = 'N'
					END
					-- V2.7 End
					-- V2.3 Begin
					IF @TempDelayCode = 577  OR @TempDelayCode = 9544
					BEGIN
						SET @ReAppointmentReqd = 'N'
						SET @ConfirmationRequired = 'N'
						SET @AmendReason=''
					END
					-- V2.3 End
					-- V2.6 Begin ## Update ReAppointmentReqd and ConfirmationRequired If @SIM2Migrate = Y
					IF @SIM2Migrate LIKE 'Migration from%'
					BEGIN
						SET @ReAppointmentReqd = 'N'
						SET @ConfirmationRequired = 'N'
					END
					-- V2.6 End
				END

				IF @Product1Name = 'MPF'
				BEGIN
					SELECT @delayNotes = '',
					@delayNoteType = 'Warning',
					@delayNoteText = 'Linked order delayed.',
					@delayNoteCode = 9494,
					@ReAppointmentReqd = 'N',  --V7.3.1 set to N
					@SubsequentReason = '',
					@AmendRequired = NULL,
					@AmendReason = NULL,
					@ConfirmationRequired = @MPFReappointmentReqd,
					@DeemedConsent = NULL,
					@ValidOrderStages = 'KSU2',
					@EngineerNotes = NULL,
					@DelayNoteFormat = NULL,
					@NoteCode = '9494',
					@NoteText = 'Linked order delayed.',
					@NoteType = 'Warning'
				END
				--V2.10 Starts
				IF @Product1Name = 'SMPF'
				BEGIN
					--V2.11 starts
					IF( @TempDelayCode in  (5197,5867) AND @Product2Name = 'WLR3 PSTN Single Line' AND @SIM2Marker = 'Y' AND @pOrderStage = 'KSU2' ) -- V9.0
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Delayed',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = '9494', @ReAppointmentReqd = 'N',
						@SubsequentReason = '',
						@AmendRequired = NULL,
						@AmendReason = NULL,
						--V2.11.1
						@ConfirmationRequired = NULL,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU2',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@NoteCode = '9494',
						@NoteText = 'Linked order delayed.',
						@NoteType = 'Warning'
					END
					--V2.11 ends
					-- V5.2 begins
					ELSE IF ( @Consumerfirstdelay <> 'N' AND @Product2Name LIKE 'WLR3 PSTN%' AND @SIM2Marker = 'Y' AND @pOrderStage = 'KSU2' )
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Warning',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = 9494,
						@ReAppointmentReqd = @MPFReappointmentReqd,
						@SubsequentReason = '',
						@AmendRequired = NULL,
						@AmendReason = NULL,
						@ConfirmationRequired = @MPFReappointmentReqd,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU2',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@NoteCode = '9494',
						@NoteText = 'Linked order delayed.',
						@NoteType = 'Warning'
					END
					---- V5.2 Ends
					ELSE
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Warning',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = 9494,
						@ReAppointmentReqd = @MPFReappointmentReqd,
						@SubsequentReason = '',
						@AmendRequired = NULL,
						@AmendReason = NULL,
						@ConfirmationRequired = @MPFReappointmentReqd,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU1.5',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@NoteCode = '9494',
						@NoteText = 'Linked order delayed.',
						@NoteType = 'Warning'
					END
				END
				IF @Product1Name = 'WLR3 PSTN Single Line'
				BEGIN
					--V5.5 Starts
					IF @pOrderStage = 'KSU2' AND @SIM2Marker = 'Y' AND @Product2Name = 'Generic Ethernet Access' AND @SIM2PCPOnly = 'N'  AND @pKCIDelayReason = '9494 - Linked order delayed.'
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Warning',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = 9494,
						@ReAppointmentReqd = 'N',
						@SubsequentReason = '',
						@AmendRequired = NULL,
						@AmendReason = 'Re-synchronisation',
						@ConfirmationRequired = @MPFReappointmentReqd,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU2',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@OrderItemNoteType = 'Warning',
						@OrderItemNoteText = '9494;Linked order delayed.',
						@NoteCode = '9494',
						@NoteText = 'Linked order delayed.',
						@NoteType = 'Warning'
					END
					--V5.5 Ends
					ELSE
					BEGIN
						SELECT @delayNotes = '',
						@delayNoteType = 'Warning',
						@delayNoteText = 'Linked order delayed.',
						@delayNoteCode = 9494,
						@ReAppointmentReqd = @MPFReappointmentReqd,
						@SubsequentReason = '',
						@AmendRequired = NULL,
						@AmendReason = NULL,
						@ConfirmationRequired = @MPFReappointmentReqd,
						@DeemedConsent = NULL,
						@ValidOrderStages = 'KSU1.5',
						@EngineerNotes = NULL,
						@DelayNoteFormat = NULL,
						@NoteCode = '9494',
						@NoteText = 'Linked order delayed.',
						@NoteType = 'Warning'
					END
				END
				--V2.10 Ends
				/***************** Hotfix for 9494 delay after refering to IVVT xmls *************/
				-- delay might not be valid so check against listed stages
				IF @Valid = 'Y' AND Isnull(@ValidOrderStages, '') <> ''
				BEGIN
					IF ',' + @ValidOrderStages + ',' NOT LIKE  '%,' + @pOrderStage + ',%'
						SET @Valid = 'N'
				END

				IF @Valid = 'N' 
				-- delay not valid yet so skip this time
				BEGIN
					SET @delayNotes=''
					SET @delayNoteType=''
					SET @delayNoteText=''
					SET @delayNoteCode=''
					SET @ReAppointmentReqd=''
					SET @SubsequentReason=''
					SET @AmendRequired =''
					SET @AmendReason =''
					SET @ConfirmationRequired =''
					SET @DeemedConsent =''
					SET @ValidOrderStages =''
					SET @EngineerNotes =''
					SET @DelayNoteFormat =''
					SET @SubsequentReason=@pKCIDelayReason
				END
			END
			ELSE
			BEGIN
				IF @ReAppointmentReqd <> 'N'
					SET @pAppointmentReqd = 'Y'
					-- ensure the calling flow knows we now have an appointment to handle
					-- generate a unique number and log the KSU in the order params table
					SET TRANSACTION isolation level READ committed
					BEGIN TRANSACTION
					BEGIN try
						UPDATE dpdata SET valuenum = valuenum + 1, @SequenceNo = valuenum + 1 FROM   dpdata WHERE  ( keyname = 'DelaySequenceNumber'  AND paramname = 'BaseID' )
						-- insert an OrderParam with the date and delay details for future tracking
						INSERT INTO orderparams (ordernumber, NAME, value) VALUES (@pOrderNumber, 'KSUDelay-' + Cast(@SequenceNo AS VARCHAR(50)), CONVERT(VARCHAR(19), Getdate(), 127) + '|'  + @delayNoteCode + '|' + @delayNoteText)
						COMMIT TRANSACTION
					END try
					BEGIN catch
						ROLLBACK TRANSACTION
					END catch
			END
			-- ensure we maintain the amend required flag if set during any sequence of delays as it wont be looped on until the end
			SET @AmendRequired = 'N'

			-- now return the params. note deemed consent not fully supported yet
			SELECT  @pAdditionalNotesXML  AS AdditionalNotesXML,
			@pAppointmentReqd     AS AppointmentReqd,
			@delayNoteCode   AS delayNoteCode,
			@delayNotes AS delayNotes,
			@delayNoteText   AS delayNoteText,
			@delayNoteType   AS delayNoteType,
			@SubsequentReason     AS KCIDelayReason,
			-- return the follow on reason (will be blank if no further delays required)
			@ReappointmentReqd    AS ReappointmentReqd,
			@AmendReason     AS delayAmendReason,
			@AmendRequired AS AmendRequired,
			@ConfirmationRequired AS delayConfirmationRequired,
			@DeemedConsent   AS DeemedConsent,
			@EngineerNotes   AS EngineerNotes,
			@DelayNoteFormat AS DelayNoteFormat,
			@SequenceNo AS DelaySequenceNumber,
			@OrderItemNoteType    AS OrderItemNoteType,
			@OrderItemNoteText    AS OrderItemNoteText,
			@NoteCode   AS NoteCode,
			@NoteText   AS NoteText,
			@NoteType   AS NoteType
		END
		ELSE
		-- V2.1 End
		BEGIN
			-- skip the delay for now and let it fire later in the flow
			IF @pKSUDelayTrigger = 'N'
			BEGIN
				SET @Valid = 'N'
			END

			IF @Valid = 'Y'
			BEGIN
				SET @Temp = Substring(@prelease, 2, 5)
				-- get the numerical part
				IF Isnumeric(@temp) = 1
					SET @ReleaseNumber = @temp
				ELSE
					SET @ReleaseNumber = 99999
					-- default to max for now as release should always be set
					-- select the values from the lookup

				SELECT @delayNotes = delaynotes,
				@delayNoteType = delaynotetype,
				@delayNoteText = delaynotetext,
				@delayNoteCode = delaynotecode,
				@ReAppointmentReqd = reappointmentreqd,
				@SubsequentReason = subsequentreason,
				@AmendRequired = amendrequired,
				@AmendReason = amendreason,
				@ConfirmationRequired = confirmationrequired,
				@DeemedConsent = deemedconsent,
				@ValidOrderStages = validorderstages,
				@EngineerNotes = engineernotes,
				@DelayNoteFormat = delaynoteformat /*V2.2 Begin*/,
				@LO_DelayReason = subsequentreason,
				@pAdditionalNotesXML = additionalnotesxml /*V2.2 End*/
				-- V2.4 Begin  ---  --V4.4 changes
				/* @OrderItemNoteType = delayNoteType,@OrderItemNoteText = CAST(delayNoteCode as varchar(max)) + ';' + delayNoteText /*V2.2 Begin*/  ,@LO_DelayReason = SubsequentReason /*V2.2 End*/ */
				-- V2.4 End
				FROM   kcidelayreasons
				WHERE  ( mincpversion <= @releasenumber )  AND ( maxcpversion >= @releasenumber )  AND ( kcidelayreason = @pKCIDelayReason )
			END

			--v9.6 starts
			IF (@delayNoteCode = '5787' AND @pKCIDelayReason = '5787_Unknown_Parallel' AND @Product1Name = 'Dark Fibre Access')
			BEGIN
				DECLARE @ReqTRC INT = 4
				DECLARE @SuppliedTRC INT
				IF EXISTS (SELECT TOP 1 1 FROM OrderParams WHERE OrderNumber = @pOrderNumber AND NAME  = 'TRCBand')
					SELECT @SuppliedTRC = Value FROM OrderParams WHERE OrderNumber = @pOrderNumber AND NAME  = 'TRCBand'

				IF @SuppliedTRC IS NOT NULL
				BEGIN
					SET @ReqTRC = @SuppliedTRC + 1
					SET @delayNoteText = REPLACE(@delayNoteText, '{RequiredTRCBand}', @ReqTRC)
				END
			END
			--v9.6 ends
				--V15.1 Start
			IF (@pKCIDelayReason = '9932 - Site Visit Reason and site contact details amend required' AND @Product1Name = 'SOGEA')
			BEGIN
				    DECLARE @SiteVisitRes VARCHAR (Max)
					DECLARE @ResponseDate VARCHAR (Max) 
			
					SET @delayNoteText=(Select delayNoteText from Dataprovider.dbo.KCIDelayReasons where delayNoteCode='9932')
					
					SET @SiteVisitRes = (Select Value from Dataprovider.dbo.orderparams where Name='RecommendMinSvrExistingLine' and OrderNumber=@pOrderNumber)
                    
                    SET @ResponseDate =(SELECT FORMAT (DATEADD(DAY,15,GETDATE()) ,'dd/MM/yyyy') AS SysDatePlus15)
					

				IF @SiteVisitRes IS NOT NULL
				BEGIN
					SET @delayNoteText = Replace(@delayNoteText,'[%1]',@SiteVisitRes)
					
					SET @delayNoteText=Replace(@delayNoteText,'[%2]',@ResponseDate)
					print(@delayNoteText +'   @delayNoteText')
					
				END
			END
			--V15.1 END
			
			
			--v7.0 starts
			-- if we are sending KCI 9790, 9791, 9792 then we don't have change the values for Confirmation Required Or Reaapointment Required
			IF (@SubsequentReason IN ('9790-ORDelayUpdated','9791-ORDelayUpdated','9792-ORDelayUpdated'))
			BEGIN
				--save the configured Delay in Orderparams
				IF NOT EXISTS (SELECT TOP 1 1 FROM Dataprovider.dbo.OrderParams WHERE OrderNumber = @pOrderNumber AND Name = 'ConfiguredKCIDelayReason')
				BEGIN
					INSERT INTO Dataprovider.dbo.OrderParams(OrderNumber, Name, Value) VALUES (@pOrderNumber, 'ConfiguredKCIDelayReason', @pKCIDelayReason)
				END
				ELSE
					UPDATE Dataprovider.dbo.OrderParams SET Value = @pKCIDelayReason WHERE OrderNumber = @pOrderNumber AND Name = 'ConfiguredKCIDelayReason'
			END
			IF (@pKCIDelayReason IN ('9790-ORDelayUpdated','9791-ORDelayUpdated','9792-ORDelayUpdated'))
			BEGIN
				DECLARE @ConfiguredKCIDelayReason VARCHAR(127) = ''
				SELECT @ConfiguredKCIDelayReason = ISNULL(Value, '') FROM Dataprovider.dbo.OrderParams WHERE OrderNumber = @pOrderNumber AND Name = 'ConfiguredKCIDelayReason'
				--now get the flag values from ConfiguredKCIDelayReason
				SELECT @ReAppointmentReqd = ReAppointmentReqd,
				@AmendRequired = AmendRequired,
				@ConfirmationRequired = ConfirmationRequired,
				@DeemedConsent = DeemedConsent
				FROM Dataprovider.dbo.KCIDelayReasons WHERE KCIDelayReason = @ConfiguredKCIDelayReason
			END
			--v7.0 ends
			-- V6.9 starts
			IF (@delayNoteCode='9808') --V6.9.1
			BEGIN
				IF (@pKCIDelayReason ='9808 - Provide valid Handover Port Service ID(9543)')
				BEGIN
					--DECLARE @Addressnadkey varchar(20) -- Declared on top V7.6
					DECLARE @Exchangecode varchar(20)
					DECLARE @Districtcode varchar(20)
					DECLARE @MDFSiteid varchar(20)
					DECLARE @iL2SIdCableLink varchar(20)
					Select  @Addressnadkey=Addressnadkey from orders where ordernumber =@pOrderNumber
					Select @Exchangecode=ExchangeGroupcode from addresses where addressnadkey=@Addressnadkey
					select @Districtcode=cssdatabasecode from exchanges where exchangecode=@Exchangecode
					SET @MDFSiteid=@Districtcode+@Exchangecode
					SELECT  @iL2SIdCableLink =(SELECT Data FROM dbo.fnPipeArrayToNumberedRowTable(Value) WHERE ID = 2)
					FROM ExchangeParams  WHERE ExchangeCode = substring(@MDFSiteid,3,5)  AND Name = 'L2Sid'
					IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='iL2SIdONT')
						INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('iL2SIdONT',@iL2SIdCableLink,@pOrderNumber) 
					ELSE
						UPDATE OrderParams SET [Value]=@iL2SIdCableLink WHERE Ordernumber=@pOrderNumber and Name='iL2SIdONT'

					IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='iL2SIdCableLink')
						INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('iL2SIdCableLink',@iL2SIdCableLink,@pOrderNumber) 
					ELSE
						UPDATE OrderParams SET [Value]=@iL2SIdCableLink WHERE Ordernumber=@pOrderNumber and Name='iL2SIdCableLink'

					IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='iL2SIdModified')
						INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('iL2SIdModified','Y',@pOrderNumber)
					ELSE
						UPDATE OrderParams SET [Value]='Y' WHERE Ordernumber=@pOrderNumber and Name='iL2SIdModified'

					IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='OrderBehaviour')
						INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('OrderBehaviour','9543 Valid OHP (SIM2)',@pOrderNumber)
					ELSE
						UPDATE OrderParams SET [Value]='9543 Valid OHP (SIM2)' WHERE Ordernumber=@pOrderNumber and Name='OrderBehaviour'
				END
				--V6.9.1 starts
				IF (@pOrderNumber LIKE 'OR%'  ) --it means it is a FLOW Order else it is on AIB
				BEGIN
					SET @OrderItemNoteType = @delayNoteType
					SET @OrderItemNoteText = '9808; ' + @delayNoteText
				END
			--V6.9.1 ends
			END
			-- V6.9 Ends
			--v6.7 starts
			--V6.6 Begins
			SET @FTTPOrderStages=1
			SET @IsSuccessionalProvide='N'
			SET @FTTPOrderStages=(SELECT Value FROM OrderParams WHERE Name='FTTPOrderStages' and OrderNumber=@pOrderNumber)
			IF EXISTS(Select top 1 1 from orderparams where Name='IsSubsequentProvide' and OrderNumber=@pOrderNumber)
			Begin
				SET @IsSuccessionalProvide=(SELECT Value FROM OrderParams WHERE Name='IsSubsequentProvide' and OrderNumber=@pOrderNumber)
			end
			IF(@pKCIDelayReason='GEA - Awaiting Network Build Activity')
			BEGIN
				IF(@Product1Name='Generic Ethernet Access - FTTP' and @FTTPOrderStages=2 and @IsSuccessionalProvide<>'Y')
				BEGIN
					SET @ValidOrderStages='KSU1'
					SET @ReAppointmentReqd='N'
				END
				ELSE
				BEGIN
					SET @ValidOrderStages='KSU2'
				END
			END
			--V6.6 Ends
			-- V6.4 Start
			IF (@pKCIDelayReason like'%9775%' and @delayNoteText like '%2%')
			BEGIN
				Set @delayNoteText=REPLACE ( @delayNoteText , '%1' , @pRingAhead )   --V6.8.1 interchanged the %1 and %2 values according to the response text
				Set @delayNoteText=REPLACE ( @delayNoteText , '%2' , @Arrivalslot )  --V 6.8.1
				Set @delayNoteText=REPLACE ( @delayNoteText , '%3' , @pTaskClosureReason )
			END
			-- V6.4 Ends
			-- V14.9 Starts
			IF (@pKCIDelayReason like '%9931%')
			BEGIN
				DECLARE @PTWvalue VARCHAR(50)
				SET @PTWvalue=''
				IF EXISTS(SELECT TOP 1 1 FROM orderparams WHERE ordernumber = @pOrderNumber AND NAME = 'PTW9931_541Flag' AND VALUE='Y')
				SET @PTWvalue='is not received'
				ELSE
				SET @PTWvalue='is required'
				
				Set @delayNoteText=REPLACE ( @delayNoteText , '%1' , @PTWvalue )   
				Set @delayNoteText=REPLACE ( @delayNoteText , '%3' , CONVERT(VARCHAR(10), GETDATE() + 1 , 105 ) )
			END
			-- V14.9 Ends

			--v7.8 starts
			IF (@pKCIDelayReason = '8020 - Planned Work Will Delay Order')
			BEGIN
				SET @delayNoteText = REPLACE(@delayNoteText, '[MigrationDate]', CONVERT(VARCHAR(10), GETDATE() + 2 , 105))
			END
			ELSE IF (@pKCIDelayReason = '8020 - Planned Work Will Delay Order Twice')
			BEGIN
				SET @delayNoteText = REPLACE(@delayNoteText, '[MigrationDate]', CONVERT(VARCHAR(10), GETDATE() + 1 , 105))
			END
			--v7.8 ends
			DECLARE @AvailableDate VARCHAR(10) = CONVERT(VARCHAR(10), DATEADD(DAY, 30, GETDATE()), 127)  --V6.9.2
			IF(@delayNoteCode = '8016')
			BEGIN
				IF(@pKCIDelayReason <> '8016-OrderIsOnHold2nd')
				BEGIN
					DECLARE @AvailableDate_DDMMYYYY VARCHAR(10)  = SUBSTRING(@AvailableDate, 9, 2)+'/'+SUBSTRING(@AvailableDate, 6, 2)+'/'+ SUBSTRING(@AvailableDate, 1, 4)
					SET @delayNoteText = REPLACE (@delayNoteText , '{AvailableDate_DDMMYYYY}' , @AvailableDate_DDMMYYYY)
				END
				ELSE
				BEGIN
					SET @AvailableDate = CONVERT(VARCHAR(10), DATEADD(DAY, 10, @AvailableDate), 127)
					SET @AvailableDate_DDMMYYYY = SUBSTRING(@AvailableDate, 9, 2)+'/'+SUBSTRING(@AvailableDate, 6, 2)+'/'+ SUBSTRING(@AvailableDate, 1, 4)
					SET @delayNoteText = REPLACE (@delayNoteText , '{AvailableDate_DDMMYYYY2}' , @AvailableDate_DDMMYYYY)
				END
				IF (@pOrderNumber LIKE 'OR%') --it means it is a FLOW Order else it is on AIB
				BEGIN
					SET @OrderItemNoteType = @delayNoteType
					SET @OrderItemNoteText = '8016; ' + @delayNoteText
				END
			END
			--6.7 ends

			--V5.9 START
			IF( @Product1Name = 'SOGEA' ) 
			BEGIN
				IF( @delayNoteCode IN ( '9687', '9689', '9691', '9693',  '9695', '9696', '9698', '9701','9702', '9703', '9447', '9686',    '9688', '9690', '9692', '9694',    '9697', '9699', '9685', '568',
				'9227', '9705', '5464', '9602',   '581', '9707', '577', '578',    '9706', '9600', '585', '579','582', '584','566','565','9902','9903','9904','9928' ) )  --V6.5 --V6.8 --V14.3.1 --V14.7.1
				BEGIN
					SET @EUOrOpenreachMissed = 'Y'
				END
				--v6.0 starts

				IF( @delayNoteCode IN ( '9687', '9689', '9691', '9693',  '9695', '9696', '9698', '9701','9702', '9703', '9447' )
					OR (@delayNoteCode = '9700' AND EXISTS (SELECT TOP 1 1 FROM DataProvider.dbo.Orders WHERE OrderNumber = @pOrderNumber
						AND OrderType='Cease' AND SubOrderType='Cease' )
						)
				  ) --- V14.5 Added OR condt for SOGEA Cease
				BEGIN
					IF NOT EXISTS(SELECT TOP 1 1 FROM   orderparams WHERE  ordernumber = @pOrderNumber AND NAME = 'OrderBehaviour')
					BEGIN
						INSERT INTO orderparams VALUES (@pOrderNumber,'OrderBehaviour', 'Abortive Vist')
					END
				END
				--v6.0 ends
			END

			--V5.9 END
			--V4.8 Start
			IF @delayNoteCode = 565 AND @pOrderStage <> 'KSU2' AND @pOrderStage <> 'KSU3' AND ( @Product1Name LIKE '%MPF%' OR @Product1Name LIKE '%SMPF%' ) AND @pAdditionalNotesXML LIKE '%5197%'
			BEGIN
				EXEC dbo.Spadditionalnotesxmlbuilder
				@OriginalNotesXML = @pAdditionalNotesXML,
				@NoteCode = '5197',
				@NoteType = 'Warning',
				@NoteText =   'Order is delayed as the End User has missed the Appointment.',
				@Action ='DELETE',
				@UpdatedNotesXML = @pAdditionalNotesXML output
			END

			--V4.8 End
			--V5.8 Starts Insert abortivevisit required flag in Orderparams in order to send it in KCI3 responses of SMPF BET, MPF,FTTP		
			IF (@delayNoteCode = 565  AND @pOrderStage = 'KSU2' AND ( @Product1Name LIKE '%MPF%' OR @Product1Name LIKE '%SMPF%'  OR @Product1Name LIKE '%GENERIC ETHERNET ACCESS%' OR @Product1Name LIKE '%SOTAP%' )) OR (@delayNoteCode IN(9743,5480)  AND @pOrderStage = 'KSU2' AND  @Product1Name LIKE '%SOTAP%' )--V14.2 --V15.7
				IF EXISTS(SELECT TOP 1 1 FROM   orderparams WHERE  ordernumber = '@porderNumber' AND NAME = 'AbortiveVisitReqd')
			BEGIN
				UPDATE orderparams  SET    [value] = 'Y' WHERE  ordernumber = '@porderNumber'  AND NAME = 'AbortiveVisitReqd'
			END
			ELSE
			BEGIN
				INSERT INTO orderparams  VALUES(@porderNumber,'AbortiveVisitReqd','Y') 
			END
			
			--V15.5 Begins
			IF @delayNoteCode = 5197   AND ( @Product1Name LIKE '%FTTP%' )--V14.2
				IF EXISTS(SELECT TOP 1 1 FROM   orderparams WHERE  ordernumber = '@porderNumber' AND NAME = 'AbortiveVisitReqd')
			BEGIN
				UPDATE orderparams  SET    [value] = 'Y' WHERE  ordernumber = '@porderNumber'  AND NAME = 'AbortiveVisitReqd'
			END
			ELSE
			BEGIN
				INSERT INTO orderparams  VALUES(@porderNumber,'AbortiveVisitReqd','Y') 
			END
			
			--V15.5 Ends
			--V5.8 ends
			--V4.1 Starts
			IF @delayNoteCode = 5197 AND @SIM2Marker = 'Y'  AND @Product2Name = 'Generic Ethernet Access'    AND @Product1Name = 'WLR3 PSTN Single Line'   AND @pKCIDelayReason = '5197 - EU Missed Appt' 
			BEGIN
				SET @AmendRequired = 'N'
				SET @ConfirmationRequired = 'N'
				SET @ReAppointmentReqd = 'PA10BT'
			END

			--V4.1 Ends
			-- V2.3 Begin
			IF @delayNoteCode = 577  AND @product1name <> 'Generic Ethernet Access - FTTP' AND @product1name <> 'FVA' AND @Product1Name = 'MPF' AND @SIM2Marker = 'Y'
			--V3.1 added product1name condition --V3.2 added productname condition for FVA
			--V4.2 delay577 Specific for MPF -SIM2
			BEGIN
				SET @SubsequentReason = '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
			END

			-- V2.3 End
			--  V5.0 Begins  
			IF ( @delayNoteCode = 597 )   AND ( @Product1Name = 'WLR3 PSTN Single Line' )   AND @SIM2Marker = 'Y'
			--V3.1 added product1name condition --V3.2 added productname condition for FVA   --V4.2 delay 577 Specific for MPF -SIM2
			BEGIN
				SET @SubsequentReason =    '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order' 
			END

			IF @delayNoteCode = 567 AND @Product1Name = 'MPF'  AND @SIM2Marker = 'Y'  AND @ReAppointmentReqd = 'CPBT' 
			BEGIN
				SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
			END

			-- V5.0 Ends
			-- V2.5 Begin
			IF @delayNoteCode = 9544 
			BEGIN
				SET @OrderItemNoteType = @delayNoteType
				SET @OrderItemNoteText = Cast(@delayNoteCode AS VARCHAR(max)) + ';' + @delayNoteText
			END

			-- V2.5 End    --V5.6 Starts
			IF @delayNoteCode = 566  AND @Product1Name = 'Generic Ethernet Access'  AND @Product2Name = 'WLR3 PSTN Single Line' AND @SIM2Marker = 'Y' AND @TargetDNavailable = 'Y'  AND @pKCIDelayReason = '566 - OR Missed Appt (EU Confirmed)'
			BEGIN
				SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
				SELECT @RefId = value  FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'GeSSLoggingRef' )
				
				--V14.0 NGA Improvement Begins
				IF EXISTS (SELECT TOP 1 1 FROM typeprocessor.dbo.inprogressdata NOLOCK WHERE  [key] = @RefId )
				BEGIN
					IF NOT EXISTS(SELECT value  FROM   typeprocessor.dbo.inprogressdata WHERE  NAME = 'KCI566Flag' AND [key] = @RefId)
					BEGIN
						INSERT INTO typeprocessor.dbo.inprogressdata     VALUES     ('',   'KCI566Flag',    'N',    @RefId,    Getdate())
					END
					ELSE
					BEGIN
						UPDATE typeprocessor.dbo.inprogressdata  SET    value = 'N' WHERE  [key] = @RefId  AND NAME = 'KCI566Flag'
					END
				
				END
				ELSE IF NOT EXISTS (SELECT TOP 1 1 FROM TypeProcessor.DBO.InProgressData NOLOCK WHERE [KEY] = @RefId )                                          
				   BEGIN
						
							
					EXEC spInsertorUpdateInprogressDataParamValue @pInputOrderRef  =  @pOrderNumber ,@pInputGeSSRef=  @RefId,@pInputName='KCI566Flag',@pInputValue= 'N',@Result=@Res                         
						
				   END
				   
			--V14.0 NGA Improvement Begins
				
			END
			--V5.6 Ends
			--V5.6 Starts
			IF @delayNoteCode = 566 AND @Product1Name = 'Generic Ethernet Access'  AND @Product2Name = 'WLR3 PSTN Single Line'  AND @SIM2Marker = 'Y' AND @TargetDNavailable = 'N'  AND @pKCIDelayReason = '566 - OR Missed Appt (EU Confirmed)'
			BEGIN
				SELECT @RefId = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'GeSSLoggingRef' )
			/*	IF NOT EXISTS(SELECT value FROM   typeprocessor.dbo.inprogressdata  WHERE  NAME = 'KCI566Flag'   AND [key] = @RefId)
				BEGIN
					INSERT INTO typeprocessor.dbo.inprogressdata  VALUES ('',   'KCI566Flag',     'Y',     @RefId,     Getdate())
				END
				ELSE
				BEGIN
					UPDATE typeprocessor.dbo.inprogressdata   SET    value = 'Y'    WHERE  [key] = @RefId    AND NAME = 'KCI566Flag'
				END*/
				
				
				--V14.0 NGA Improvement Begins
				IF EXISTS (SELECT TOP 1 1 FROM typeprocessor.dbo.inprogressdata NOLOCK WHERE  [key] = @RefId )
				BEGIN
					IF NOT EXISTS(SELECT value  FROM   typeprocessor.dbo.inprogressdata WHERE  NAME = 'KCI566Flag' AND [key] = @RefId)
					BEGIN
						INSERT INTO typeprocessor.dbo.inprogressdata     VALUES     ('',   'KCI566Flag',    'Y',    @RefId,    Getdate())
					END
					ELSE
					BEGIN
						UPDATE typeprocessor.dbo.inprogressdata  SET    value = 'Y' WHERE  [key] = @RefId  AND NAME = 'KCI566Flag'
					END
				
				END
				ELSE IF NOT EXISTS (SELECT TOP 1 1 FROM TypeProcessor.DBO.InProgressData NOLOCK WHERE [KEY] = @RefId )                                          
				   BEGIN
						
							
					EXEC spInsertorUpdateInprogressDataParamValue @pInputOrderRef  =  @pOrderNumber ,@pInputGeSSRef=  @RefId,@pInputName='KCI566Flag',@pInputValue= 'Y',@Result=@Res                         
						
				   END
				   
			--V14.0 NGA Improvement Begins
			END

			--V5.6 Ends
			--V2.6 Begin
			IF @delayNoteCode = 569 AND @SIM2Migrate LIKE 'Migration from%' AND @SIM2Migrate <> 'Migration from SOTAP'  -- V14.4
			BEGIN
				SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
			END -- V2.8 starts
			ELSE IF @delayNoteCode = 569 AND @SIM2Marker = 'N' AND ( @Product1Name = 'MPF' OR @Product1Name = 'SMPF' ) AND @pKCIDelayReason = '569 - Delay Faulty Tie Pair Amend'
			BEGIN
				SET @ConfirmationRequired = 'N'
			END
			-- V2.8 complete
			--V2.10 starts
			ELSE IF @delayNoteCode = 569 AND @SIM2Marker = 'Y' AND @Product1Name = 'SMPF' AND @pKCIDelayReason = '569 - Delay Faulty Tie Pair Amend'
			BEGIN
				SET @ConfirmationRequired = 'CP'
			END
			--v2.10 ends
			IF @delayNoteCode = 9544 AND @SIM2Migrate LIKE 'Migration from%'
			BEGIN
				SET @ReAppointmentReqd = 'CP'
				SET @AmendRequired = 'Y'
				SET @ConfirmationRequired = 'Customer Delay'
			END

			--V2.6 end
			--V2.9 Starts
			--V2.11 Starts
			IF @SIM2Marker = 'Y'
			BEGIN
				--V7.9 Starts
				DECLARE @IsORMissDelay CHAR
				DECLARE @KSUDelayTriggeredonOrder Table(
				Name Varchar(50),
				DelayCode Varchar(10))
				INSERT INTO @KSUDelayTriggeredonOrder(Name,DelayCode) SELECT Name,SUBSTRING(Value,CHARINDEX('|',Value)+1, Len(Value)-CHARINDEX('|',Value)-CHARINDEX('|',REVERSE(Value))) FROM OrderParams NOLOCK Where OrderNumber = @pOrderNumber AND Name like 'KSUDelay-%'
				IF EXISTS(SELECT TOP 1 1  FROM @KSUDelayTriggeredonOrder WHERE DelayCode in ('566','568','577','578','579','581','585','596','5462','5464','5466')) 
					SET @IsORMissDelay ='Y'
				ELSE
					SET @IsORMissDelay ='N'
				--V7.9 End
				IF ( @delayNoteCode = 5463 AND @pOrderstage = 'KSU2' )
				BEGIN
					SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
				END
				ELSE IF ( @delayNoteCode = 5466 )
				BEGIN
					SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
				END
				-- V4.6 starts--
				ELSE IF ( @delayNoteCode = 9544 ) AND ( @Product1Name = 'Generic Ethernet Access' ) AND (@IsORMissDelay = 'Y') --V7.9
				BEGIN
					SET @SubsequentReason = '9600 - OR Missed Appointment'
				END

				-- V4.6 ends--
				--V5.7 Starts
				IF( @delayNoteCode = 572  AND @pOrderStage = 'KSU2' AND @Product1Name = 'SMPF' )
				BEGIN
					SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
				END
				-- V5.7 Ends
			END

			-- V5.6 starts--
			IF ( @delayNoteCode = 9544  AND @Product1Name = 'Generic Ethernet Access'  AND @Product2Name = 'WLR3 PSTN Single Line' AND @SIM2Marker = 'Y' AND @TargetDNavailable = 'Y' )
			BEGIN
				SET @SubsequentReason = ''
				SELECT @RefId = value  FROM   orderparams  WHERE  ( ordernumber = @porderNumber )  AND ( NAME = 'GeSSLoggingRef' )
			/*	IF EXISTS(SELECT value FROM   typeprocessor.dbo.inprogressdata  WHERE  NAME = 'KCI566Flag' AND [key] = @RefId)
				BEGIN
					UPDATE typeprocessor.dbo.inprogressdata  SET value = 'Y' WHERE  [key] = @RefId AND NAME = 'KCI566Flag'
				END*/
				
				
				
				--V14.0 NGA Improvement Begins
				IF EXISTS (SELECT TOP 1 1 FROM typeprocessor.dbo.inprogressdata NOLOCK  WHERE  [key] = @RefId )
				BEGIN
					IF NOT EXISTS(SELECT value  FROM   typeprocessor.dbo.inprogressdata WHERE  NAME = 'KCI566Flag' AND [key] = @RefId)
					BEGIN
						INSERT INTO typeprocessor.dbo.inprogressdata     VALUES     ('',   'KCI566Flag',    'Y',    @RefId,    Getdate())
					END
					ELSE
					BEGIN
						UPDATE typeprocessor.dbo.inprogressdata  SET    value = 'Y' WHERE  [key] = @RefId  AND NAME = 'KCI566Flag'
					END
				
				END
				ELSE IF NOT EXISTS (SELECT TOP 1 1 FROM TypeProcessor.DBO.InProgressData NOLOCK WHERE [KEY] = @RefId )                                          
				   BEGIN
						
							
					EXEC spInsertorUpdateInprogressDataParamValue @pInputOrderRef  =  @pOrderNumber ,@pInputGeSSRef=  @RefId,@pInputName='KCI566Flag',@pInputValue= 'Y',@Result=@Res                         
						
				   END
				   
			--V14.0 NGA Improvement Begins
				
				
			END
			-- V5.6 ends--
			IF ( @KCI = '9544' AND @LASTDelayNote = 5463 )
			BEGIN
				SET @ReAppointmentReqd = 'VZ'
			END
			--V2.11 Ends
			--V2.9 Ends
			-- V2.12 Starts
			IF ( @delayNoteCode = 5463 AND @pKCIDelayReason = 'GEA - Planning or Network Survey Delay' ) 
			BEGIN
				SELECT @OrderDate = value, @OrderDateNvarchar = value FROM   dbo.orderparams WHERE  ordernumber = @pOrderNumber AND NAME LIKE '%OrderPlacedDate%'
				IF Isnull(@OrderDate, '') <> ''
				BEGIN
					IF @OrderDateNvarchar LIKE '%T%'
					BEGIN
						EXEC @WK =[dbo].[Fn_weekday] @OrderDate
						IF ( @WK = 'SAT' )
							SELECT @OrderDate = Dateadd(dd, 3, @OrderDate)
						ELSE IF ( @WK = 'MON' OR @WK = 'TUE' OR @WK = 'WED' OR @WK = 'SUN' )
							SELECT @OrderDate = Dateadd(dd, 2, @OrderDate)
						ELSE IF ( @WK = 'THU'OR @WK = 'FRI' )
							SELECT @OrderDate = Dateadd(dd, 4, @OrderDate)

						--Below to convert GEA to UK DD/mm/yyyy
						SET @CalculatedDate = Replace(CONVERT(VARCHAR(20),CONVERT(DATETIME, @OrderDate,126),103),'/','-') 
					END
					ELSE
						SET @CalculatedDate =@OrderDate
				END
				SET @delayNotes =  '600;Unfortunately due to high product demand we cannot process your FTTP on Demand order until after ' + @CalculatedDate  + '. We will progress the order after this date and send an order status update containing the survey appointment booking date. The Order Tracker will have the latest update thereafter.'
				SET @externalNotes =  '600;Others. Unfortunately due to high product demand we cannot process your FTTP on Demand order until after '+ @CalculatedDate + '. We will progress the order after this date and send an order status update containing the survey appointment booking date. The Order Tracker will have the latest update thereafter.'
			END

			-- V2.12 Ends
			-- V2.13 Begin
			IF @Product1Name = 'Generic Ethernet Access'  AND @delayNoteCode = '9404'
			BEGIN
				SET @NoteCode = @delayNoteCode
				SET @NoteText = @delayNoteText
				SET @NoteType = @delayNoteType
				SET @OrderItemNoteText = Cast(@delayNoteCode AS VARCHAR(max)) + ';' + @delayNoteText
				SET @OrderItemNoteType = @delayNoteType
			END

			-- V2.13 End
			--V3.0 starts
			IF @Product1Name = 'SBS' AND @delayNoteCode = '9520'
			BEGIN
				SET @NoteCode = @delayNoteCode
				SET @NoteText = @delayNoteText
				SET @NoteType = @delayNoteType
			END

			--V3.0 ends
			--V4.0 Starts
			IF @SIM2PCPOnly = 'Y'
			BEGIN
				IF ( @delayNoteCode = '5197' OR @delayNoteCode = '565' )
				BEGIN
					SET @SubsequentReason =  '9544 - Links between the orders have been severed. This order is now proceeding as a stand-alone order'
					SET @ReAppointmentReqd='CP' -- V9.7 --5197 set on PSTN after task completion in FTTC , then links are severed and so PSTN should acccept CP amend 
				END
			END

			IF @KCI = '9544' AND ( @Product1Name = 'MPF' ) --- V5.0
			BEGIN
				SET @AmendRequired='Y'
				--SET @ReAppointmentReqd='CA10'    --V5.3
			END

			IF @KCI = '9544' AND ( @Product1Name = 'WLR3 PSTN Single Line' )
			--V5.0
			BEGIN
				SET @AmendRequired='Y'
			END

			--V4.0 Ends
			-- delay might not be valid so check against listed stages
			IF @Valid = 'Y' AND Isnull(@ValidOrderStages, '') <> ''
			BEGIN
				IF ',' + @ValidOrderStages + ',' NOT LIKE '%,' + @pOrderStage + ',%'
					SET @Valid = 'N'
			END

			IF @Valid = 'N'
			-- delay not valid yet so skip this time
			BEGIN
				SET @delayNotes=''
				SET @delayNoteType=''
				SET @delayNoteText=''
				SET @delayNoteCode=''
				SET @ReAppointmentReqd=''
				SET @SubsequentReason=''
				SET @AmendRequired =''
				SET @AmendReason =''
				SET @ConfirmationRequired =''
				SET @DeemedConsent =''
				SET @ValidOrderStages =''
				SET @EngineerNotes =''
				SET @DelayNoteFormat =''
				SET @SubsequentReason=@pKCIDelayReason
				-- V2.2 Begin
				SET @LO_DelayReason = ''
				-- V2.2 End
			END
			ELSE
			BEGIN
				IF @ReAppointmentReqd <> 'N' AND ( @pKCIDelayReason <> 'LLU_Out OF Time' AND @pKCIDelayReason <> 'LLU_Health and Safety Issue' )
				--V4.2 ApptReqd need not reseted for these delays
					SET @pAppointmentReqd = 'Y'
					-- ensure the calling flow knows we now have an appointment to handle
					-- generate a unique number and log the KSU in the order params table
				SET TRANSACTION isolation level READ committed
				BEGIN TRANSACTION
				BEGIN try
					UPDATE dpdata  SET    valuenum = valuenum + 1, @SequenceNo = valuenum + 1 FROM   dpdata  WHERE  ( keyname = 'DelaySequenceNumber' AND paramname = 'BaseID' )

				-- insert an OrderParam with the date and delay details for future tracking
				INSERT INTO orderparams  (ordernumber, NAME, value) VALUES (@pOrderNumber, 'KSUDelay-' + Cast(@SequenceNo AS VARCHAR(50)), CONVERT(VARCHAR(19), Getdate(), 127) + '|' + @delayNoteCode + '|' + @delayNoteText)
				COMMIT TRANSACTION 
				END try 
				BEGIN catch
					ROLLBACK TRANSACTION
				END catch 
			END

			-- ensure we maintain the amend required flag if set during any sequence of delays as it wont be looped on until the end
			IF @pAmendRequired = 'Y'
				SET @AmendRequired = @pAmendRequired

			-- V4.9 Starts
			IF @delayNoteCode = '9670' OR @delayNoteCode = '9662' OR @delayNoteCode = '9671'
			BEGIN
				SET @Activitycompletiondate=(SELECT  CONVERT(VARCHAR(30),dbo.Fncalculatedates(CONVERT(VARCHAR(10),CONVERT(DATETIME, Getdate(), 120), 120), 14), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%1',@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')
			END

			IF @delayNoteCode = '9666'
			BEGIN
				SET @Activitycompletiondate=(SELECT CONVERT(VARCHAR(30),dbo.Fncalculatedates(CONVERT(VARCHAR(10),CONVERT(DATETIME, Getdate(), 120), 120), 3), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%2',@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')

				--V5.2 starts
				--Set the Linked order delay for PSTN SIM2 orders
				IF @SIM2Marker = 'Y' AND Isnull(@Order2Number, '') <> '' AND @Product1Name LIKE 'WLR3 PSTN%'
				BEGIN
					IF EXISTS (SELECT TOP 1 1  FROM   orderparams WHERE  ordernumber = @Order2Number AND NAME = 'KCIDelayReason')
					BEGIN
						UPDATE orderparams
						SET value = '9494 - Linked order delayed'
						WHERE  ordernumber = @Order2Number
						AND NAME = 'KCIDelayReason'
					END
					ELSE
					BEGIN
						INSERT INTO orderparams
						VALUES     (@Order2Number,
						'KCIDelayReason',
						'9494 - Linked order delayed')
					END
				END
				--V5.2 Ends
			END

			IF @delayNoteCode = '9648' OR @delayNoteCode = '9651'
			BEGIN
				SET @Activitycompletiondate=(SELECT
				CONVERT(VARCHAR(30),
				dbo.Fncalculatedates(
				CONVERT(VARCHAR(10),
				CONVERT(DATETIME, Getdate(), 120), 120), 15), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%2',
				@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')

				--V5.2 starts
				--Set the Linked order delay for PSTN SIM2 orders
				IF @delayNoteCode = '9651' AND @SIM2Marker = 'Y'  AND Isnull(@Order2Number, '') <> '' AND @Product1Name LIKE 'WLR3 PSTN%'
				BEGIN
					IF EXISTS (SELECT TOP 1 1  FROM orderparams  WHERE  ordernumber = @Order2Number AND NAME = 'KCIDelayReason')
					BEGIN
						UPDATE orderparams 
						SET    value = '9494 - Linked order delayed'
						WHERE  ordernumber = @Order2Number
						AND NAME = 'KCIDelayReason'
					END
					ELSE
					BEGIN
						INSERT INTO orderparams 
						VALUES     (@Order2Number, 
						'KCIDelayReason',
						'9494 - Linked order delayed')
					END
				END
			--V5.2 Ends
			END

			IF ((@delayNoteCode = '9668'  OR @delayNoteCode = '9669') and @Product1Name <> 'SOGEA')   --V7.2.1
			BEGIN
				SET @Activitycompletiondate=(SELECT  CONVERT(VARCHAR(30), dbo.Fncalculatedates( CONVERT(VARCHAR(10),  CONVERT(DATETIME, Getdate(), 120), 120), 1), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%2', @Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')
			END
			--V7.2.1 Start

			IF (@Product1Name = 'SOGEA' and @delayNoteCode = '9668')
			BEGIN
				SET @Activitycompletiondate=(SELECT  CONVERT(VARCHAR(30), dbo.Fncalculatedates( CONVERT(VARCHAR(10),  CONVERT(DATETIME, Getdate(), 120), 120), 16), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%2', @Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')
			END
			IF (@Product1Name = 'SOGEA' and @delayNoteCode = '9669')
			BEGIN
				SET @Activitycompletiondate=(SELECT CONVERT(VARCHAR(30),dbo.Fncalculatedates(CONVERT(VARCHAR(10),CONVERT(DATETIME, Getdate(), 120), 120), 17), 103))
				SELECT @CommitmentDate = Value from OrderParams where OrderNumber = @pOrderNumber AND Name = 'RequiredByDate'
				IF datediff(d,convert(datetime,CONVERT(VARCHAR(30),@CommitmentDate,113),103),convert(datetime,CONVERT(VARCHAR(30),@Activitycompletiondate,113),103))>0
				BEGIN
					--SET @Activitycompletiondate = @Activitycompletiondate + ' 00:00:00'
					IF EXISTS (SELECT top 1 1 from Orderparams WHERE Ordernumber=@pOrderNumber and name='NewSiteDelays')
						UPDATE  OrderParams SET Value = 'Y' where OrderNumber = @pOrderNumber AND OrderParams.Name = N'NewSiteDelays'
					ELSE
						INSERT INTO OrderParams  (OrderNumber, Name, Value) VALUES (@pOrderNumber, N'NewSiteDelays','Y')
				END
			END
			--V7.2.1 End
			IF @delayNoteCode = '9667' 
			BEGIN
				DECLARE @newsiteactivities NVARCHAR(200)
				SET @newsiteactivities=(SELECT Isnull(value, '')
				FROM   orderparams
				WHERE  ordernumber = @pOrderNumber 
				AND NAME = 'Newsitesactivities') 
				SET @delayNoteText= Replace(@delayNoteText, '%1', @newsiteactivities) 
			END

			-- V4.9 Ends
			-- V5.1 Starts
			IF @delayNoteCode = '9652'
			BEGIN
				SET @Activitycompletiondate=(SELECT 
				CONVERT(VARCHAR(30),
				dbo.Fncalculatedates(
				CONVERT(VARCHAR(10),
				CONVERT(DATETIME, Getdate(), 120), 120), 4), 105))
				SET @delayNoteText= Replace(@delayNoteText, '%2',
				@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')
			END

			IF @delayNoteCode = '9663'
			BEGIN
				SET @Activitycompletiondate=(SELECT 
				CONVERT(VARCHAR(30),
				dbo.Fncalculatedates( 
				CONVERT(VARCHAR(10), 
				CONVERT(DATETIME, Getdate(), 120), 120), 3), 105)) 
				SET @delayNoteText= Replace(@delayNoteText, '%2', 
				@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '') 
			END

			IF @delayNoteCode = '9681'
			BEGIN
				DECLARE @Complexplanningactivities NVARCHAR(200)
				SET @Activitycompletiondate=(SELECT 
				CONVERT(VARCHAR(30), 
				dbo.Fncalculatedates( 
				CONVERT(VARCHAR(10), 
				CONVERT(DATETIME, Getdate(), 120), 120), 5), 105)) 
				SET @Complexplanningactivities=(SELECT Isnull(value, '') 
				FROM   orderparams 
				WHERE
				ordernumber = @pOrderNumber 
				AND NAME = 'Complexplanningactivities')
				SET @delayNoteText= Replace(@delayNoteText, '%1',
				@Complexplanningactivities 
				)
				SET @delayNoteText= Replace(@delayNoteText, '%3',
				@Activitycompletiondate)
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')

				--V5.2 starts
				--Set the Linked order delay for PSTN SIM2 orders
				IF @SIM2Marker = 'Y'
				AND Isnull(@Order2Number, '') <> ''
				AND @Product1Name LIKE 'WLR3 PSTN%'
				BEGIN
					IF EXISTS (SELECT TOP 1 1 
					FROM   orderparams 
					WHERE  ordernumber = @Order2Number 
					AND NAME = 'KCIDelayReason') 
					BEGIN 
						UPDATE orderparams 
						SET    value = '9494 - Linked order delayed'    WHERE  ordernumber = @Order2Number AND NAME = 'KCIDelayReason'
					END
					ELSE
					BEGIN
						INSERT INTO orderparams    VALUES     (@Order2Number,     'KCIDelayReason','9494 - Linked order delayed')
					END
				END
				--V5.2 Ends
			END

			-- V5.1 Ends
			-- V4.5 Starts
			IF ( @pKCIDelayReason IN ( '5742 - Address Matching Delay',   '561 - Address Matching Delay' ) OR ( @pKCIDelayReason LIKE ( '9650%' ) ) )
			BEGIN
				DECLARE @orderplaceddate DATETIME
				DECLARE @adddays BIGINT

				SET @adddays=2 --this for 5742 and 561
				IF ( @pKCIDelayReason LIKE ( '9650%' ) )  SET @adddays=15 --this for 9650
					SET @orderplaceddate=(SELECT CONVERT(DATETIME, value, 126)
					FROM   dataprovider.dbo.orderparams
					WHERE  ordernumber = @pOrderNumber
					AND NAME = 'OrderPlacedDate')
					--SET @Activitycompletiondate=(SELECT CONVERT(varchar(30),dbo.fnCalculateDates(CONVERT(VARCHAR(10),CONVERT(DATETIME,@orderplaceddate,120),120),@adddays),120))
				SET @Activitycompletiondate=(SELECT CONVERT(VARCHAR(30), 
				dbo.Fncalculatedates(
				CONVERT(VARCHAR(10),
				CONVERT(DATETIME, Getdate(), 120), 120), @adddays), 105))
				--V4.9  changed the date format to dd-mm-yyyy
				SET @delayNoteText= Replace(@delayNoteText, '%1',
				@Activitycompletiondate)
				--V4.7
				SET @delayNoteText= Replace(@delayNoteText, '%2',
				@Activitycompletiondate)
				--SET @delayNotes= REPLACE(@delayNotes,'[','')
				--SET @delayNotes= REPLACE(@delayNotes,']','')
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')
				SET @NoteType = 'Warning'

				--V5.2 starts
				--Set the Linked order delay for PSTN SIM2 orders
				IF @delayNoteCode = '9650' AND @SIM2Marker = 'Y' AND Isnull(@Order2Number, '') <> '' AND @Product1Name LIKE 'WLR3 PSTN%'
				BEGIN
					IF EXISTS (SELECT TOP 1 1  FROM   orderparams  WHERE  ordernumber = @Order2Number AND NAME = 'KCIDelayReason')
					BEGIN
						UPDATE orderparams 
						SET    value = '9494 - Linked order delayed'
						WHERE  ordernumber = @Order2Number
						AND NAME = 'KCIDelayReason'
					END
					ELSE
					BEGIN
						INSERT INTO orderparams    VALUES     (@Order2Number,'KCIDelayReason',  '9494 - Linked order delayed')
					END
				END
				--V5.2 Ends
			END

			-- V4.5 Ends
			--v5.4 starts
			DECLARE @9709Reach VARCHAR(50)
			DECLARE @Reach VARCHAR(50)
			DECLARE @DelayReach VARCHAR(50)
			DECLARE @TMP VARCHAR(20)

			IF Isnull(@delayNoteCode, '') = '9709' and   @pKCIDelayReason<>'9709_DELAY_CLOSURE'  -- V8.2
			BEGIN
				SET @Reach=(SELECT value 
				FROM   orderparams 
				WHERE  ordernumber = @pOrderNumber  
				AND NAME = 'Reach') 
				SET @9709Reach=(SELECT value 
				FROM   orderparams 
				WHERE  ordernumber = @pOrderNumber 
				AND NAME = 'EADSet9709DelayReach')

				SELECT @TMP = value 
				FROM  orderparams  
				WHERE  ordernumber = @pOrderNumber    AND NAME = N'EADOldReach' 

				IF @@ROWCOUNT = 1 --update existing
				BEGIN
					UPDATE orderparams SET    value = @Reach    WHERE  ordernumber = @pOrderNumber AND orderparams.NAME = N'EADOldReach'
				END
				ELSE
				BEGIN
					INSERT INTO orderparams (ordernumber,  NAME, [Value])  VALUES (@pOrderNumber,  N'EADOldReach',  @Reach)
				END
				IF @Reach = 'Standard'
				BEGIN
					SET @DelayReach='Local Access'
				END
				ELSE IF @Reach = 'Extended Reach'    AND @9709Reach = 'Standard'
				BEGIN
					SET @DelayReach='Standard' 
				END
				ELSE IF @Reach = 'Extended Reach'
				BEGIN
					SET @DelayReach='Local Access'
				END
				SET @delayNoteText= 'The Reach value on your order has been changed during planning. The new Reach value is now ' + @DelayReach + '. Please amend your order to reflect the new Reach value.'
			END
			--v5.4 ends
			--V6.2 starts
			IF Isnull(@delayNoteCode, '') = '9743'
			BEGIN
				IF @Product1Name = 'WLR3 PSTN Single Line' 
					SET @Activitycompletiondate=(SELECT CONVERT(VARCHAR(30), dbo.Fncalculatedates(CONVERT(VARCHAR(10), CONVERT(DATETIME, Getdate(), 120), 120), 15), 105)) 

				IF @Product1Name = 'MPF' or  @Product1Name = 'SOGEA'   or @Product1Name = 'SOTAP'  --V7.2  --V9.2
					SET @Activitycompletiondate=(SELECT 
					CONVERT(VARCHAR(30), 
					dbo.Fncalculatedates( 
					CONVERT(VARCHAR(10),
					CONVERT(DATETIME, Getdate(), 120), 120), 10), 105)) 

				SET @delayNoteText= Replace(@delayNoteText, '%2', @Activitycompletiondate) 
				SET @delayNoteText= Replace(@delayNoteText, ' 00:00:00', '')

				IF @pKCIDelayReason =  '9743-delayed with SQ and then cancelling due to no response from CP or EU'
				BEGIN
					IF NOT EXISTS (SELECT TOP 1 1  FROM   orderparams WHERE  ordernumber = @pOrderNumber AND NAME = '9743Cancellation')
						INSERT INTO orderparams   VALUES (@pOrderNumber,'9743Cancellation','Y') 
					ELSE 
						UPDATE orderparams   SET    value = 'Y'     WHERE  ordernumber = @pOrderNumber  AND NAME = '9743Cancellation' 
				END
			END
			-- V7.2 Starts
			IF Isnull(@delayNoteCode, '') = '9818' and (@Product1Name = 'SOGEA')
			BEGIN
				Select @TRCBand=ISNULL(value,'') from orderparams where ordernumber=@pOrderNumber and name='TRCChargeBand'
				set @TRCBand=@TRCBand+1
				SET @delayNoteText= Replace(@delayNoteText, '%1', @TRCBand)
				-- SET @EngineerNotes= Replace(@EngineerNotes, 'X', @TRCBand) 
			END

			IF Isnull(@delayNoteCode, '') = '9649' and @Product1Name = 'SOGEA'
			BEGIN
				SET @orderplaceddate=(Select CONVERT(DATETIME,value,126) from Dataprovider.dbo.orderparams where ordernumber=@pOrderNumber and Name='OrderPlacedDate')
				SET @Activitycompletiondate=(SELECT CONVERT(varchar(30),dbo.fnCalculateDates(CONVERT(VARCHAR(10),CONVERT(DATETIME,getdate(),120),120),3),105))   --V1.2  changed the date format to dd-mm-yyyy
				SET @Activitycompletiondate= REPLACE(@Activitycompletiondate,' 00:00:00','')
				SET @delayNoteText= Replace(@delayNoteText, '%1', 'by Openreach')
				SET @delayNoteText= Replace(@delayNoteText, '%2', @Activitycompletiondate)

--IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='KCIDelaycodes')
-- SELECT @KCIDelaycodes = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'KCIDelaycodes' )
			END
			IF EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='KCIDelaycodes')
				SELECT @KCIDelaycodes = value FROM   orderparams WHERE  ( ordernumber = @porderNumber ) AND ( NAME = 'KCIDelaycodes' )
			IF ((Isnull(@KCIDelaycodes, '') like '%9650%' or Isnull(@KCIDelaycodes, '') like '%9667%' or Isnull(@KCIDelaycodes, '') like '%9668%'or Isnull(@KCIDelaycodes, '') like '%9669%')and @Product1Name = 'SOGEA')  
			BEGIN
				SET @pos=charindex('|',@KCIDelaycodes)
				IF @pos>0
				BEGIN
					SET @pKCIDelayReason=substring(@KCIDelaycodes,0, @pos)
					SET   @KCIDelaycodes  =substring(@KCIDelaycodes,@pos+1,len(@KCIDelaycodes))
					Update OrderParams SET value=@pKCIDelayReason WHERE OrderNumber=@pOrderNumber AND Name='KCIDelayReason'
					Update OrderParams SET value=@KCIDelaycodes WHERE OrderNumber=@pOrderNumber AND Name='KCIDelaycodes'
					set @SubsequentReason=@pKCIDelayReason
				END
			END
			-- V7.2 Ends
			--v7.5 starts
			IF (@pKCIDelayReason LIKE '%Copper Route Verification%')
			BEGIN
				SET @EUConfirmedDelay = 'N'
			END
			--v7.5 ends
			--v7.5.1 starts  
			DECLARE @OrderBehaviour VARCHAR(255) = ''
			SELECT @OrderBehaviour =  ISNULL([VALUE], '') FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='OrderBehaviour'

			IF ((@OrderBehaviour = '578_Invalid_OGHP' OR @OrderBehaviour = '578_CapacityWaiterListAndInvalidOGHP'
			OR @OrderBehaviour = '578_Without9644CapacityWaiterListAndInvalidOGHP'
			OR @OrderBehaviour = '578_InvalidOGHPAndCapacityWaiterlist'
			OR @OrderBehaviour = '578_without9644InvalidOGHPAndCapacityWaiterlist')--V15.2
			AND @ReAppointmentReqd = 'A1')
			BEGIN
				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='SendAmendKSU')
					INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('SendAmendKSU','Y',@pOrderNumber)
				ELSE
					UPDATE OrderParams SET [Value]='Y' WHERE Ordernumber=@pOrderNumber and Name='SendAmendKSU'
			END
			--v7.5.1 ends
			--V6.2 Ends
			--V8.0 starts
			IF @Product1Name='Generic Ethernet Access - FTTP' AND @pKCIDelayReason='9816 Sitevisit changed'
			BEGIN
				SET @OrderItemNoteText = Cast(@delayNoteCode AS VARCHAR(max)) + ';' + @delayNoteText
				SET @OrderItemNoteType = @delayNoteType
				SET @pAppointmentReqd='Y'--V9.9
			END
			--V8.0 ends
			--V10.3 starts
			IF @Product1Name='Generic Ethernet Access - FTTP' AND @pKCIDelayReason='5480 - FTTP EU Different Instructions'
			BEGIN
				DECLARE @CRD varchar(20)  
				Declare @RCRD Varchar(20)  
				Declare @LCRD Varchar(20)  
				Declare @Arrivaltime Varchar(20)
				set @CRD=(Select Value from dbo.orderparams where ordernumber= @pOrderNumber and Name='RequiredByDate')  
				set @LCRD=(select left(@CRD,10))  
				set @RCRD=(select right(@CRD,8))  
				set @Arrivaltime=replace(@LCRD+' '+ left(@RCRD,5),'-','/')  
				SET @OrderItemNoteText='600;Notes:Unable to contact EU after 2 attempts. Need to send KCID on this order so that CP can action|3511;Engineer arrival time onsite,'+@Arrivaltime+'|3512;IRC,ASQ'
				SET @OrderItemNoteType='Engineer Notes|Engineer Notes|Engineer Notes'
			END
			--V10.3 ends
			--V8.1 starts
			IF @Product1Name='Generic Ethernet Access - FTTP' AND @delayNoteCode in('588','9562','9831','9561','5750', '9849', '9847', '9848') --v9.5
			BEGIN
				IF exists (SELECT top 1 1  FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='FTTPOnDemand' and VALUE='Y')
				BEGIN
					SET @DelayRefNo=@SequenceNo
					IF (@delayNoteCode='9561')
					BEGIN
						SET @OrderItemNoteType='Delayed'
						SET @OrderItemNoteText='600;Delay Reference is '+@DelayRefNo+'. The Estimated Clear Date is  '+(convert(varchar(20),convert(datetime,getdate(),126),103))+'.'
						IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561')
							INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('DelayRef9561',@SequenceNo,@pOrderNumber) 
						ELSE
							UPDATE OrderParams SET [Value]=@SequenceNo WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561'
					END
					ELSE IF (@delayNoteCode='588')
					BEGIN
						SET @OrderItemNoteType='Delayed'
						SET @OrderItemNoteText='600;Delay Reference is '+@DelayRefNo+'. The Estimated Clear Date is  '+(convert(varchar(20),convert(datetime,getdate(),126),103))+'.'
						IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588')
							INSERT INTO OrderParams ([Name],[Value],OrderNumber) Values ('DelayRef588',@SequenceNo,@pOrderNumber)
						ELSE
							UPDATE OrderParams SET [Value]=@SequenceNo WHERE Ordernumber=@pOrderNumber and Name='DelayRef588'
					END
					ELSE IF (@delayNoteCode='9562')
					BEGIN
						IF exists (SELECT top 1 1  FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561')
							SELECT @DelayRefNo=ISNULL(Value,'') from OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561'
						ELSE IF exists (SELECT top 1 1  FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588')
							SELECT @DelayRefNo=ISNULL(Value,'') from OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588'

						SET @OrderItemNoteType='Update'
						SET @OrderItemNoteText='600;Delay Reference '+@DelayRefNo+'. The updated Estimated Clear Date is '+(convert(varchar(20),convert(datetime,getdate(),126),103))+'.'

						IF  EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561')
							Delete FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef9561'
					END
					ELSE IF (@delayNoteCode='9831')
					BEGIN
						IF exists (SELECT top 1 1  FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588')
							SELECT @DelayRefNo=ISNULL(Value,'') from OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588'
						SET @OrderItemNoteType='Delayed'
						SET @OrderItemNoteText='600;Delay Reference is '+@DelayRefNo+'. The Estimated Clear Date is  '+(convert(varchar(20),convert(datetime,getdate(),126),103))+'.'
						IF  EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588')
							Delete FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='DelayRef588'
					END
					ELSE IF (@delayNoteCode='5750')
					BEGIN
						SET @OrderItemNoteType='Update'
						SET @OrderItemNoteText='600;This is the first delay sent for ECC Authorisation. Kindly place ECC Amend to confirm the ECC Band entered by Mobile Planners during ECC Authorisation'
					END
					/*OR-54661*/ --v9.5 starts
					ELSE IF (@delayNoteCode = '9849')
					BEGIN
						SET @OrderItemNoteType = 'Delay Notes'
						--V9.8 starts
						SET @OrderItemNoteText = 'DELAY REASON:End User details incorrect Sub-Fundamental Reason:Site Visit Notes Invalid,NOTES BY PLANNER:LAST CP/END USER SPOKEN TO:(name, contact detail and date/time)ACTION AGREED OR TAKEN:ACTIVITY DELAYED UNTIL:(review or estimated resolve date)EXPECTED CP ACTION: Could we please have confirmation from the End User that service is still required please. Reasons. Ethernet service exists and visiting engineers have advised that customer had no knowledge of this order.Planning action still pending as this enquiry goes through.This delay may change your CCD.'
						SET @delayNoteText = REPLACE(@delayNoteText, '%1',CONVERT(VARCHAR(10), DATEADD(day, 31, GETDATE()) , 103))
						--V9.8 ends
					END
					ELSE IF (@delayNoteCode = '9847')
					BEGIN
						SET @OrderItemNoteType = 'Delay Notes'
						--v9.8 starts
						SET @OrderItemNoteText = 'DELAY REASON:End User not contactableNOTES BY PLANNER:LAST CP/END USER SPOKEN TO:(name, contact detail and date/time)ACTION AGREED OR TAKEN:ACTIVITY DELAYED UNTIL:(review or estimated resolve date)EXPECTED CP ACTION: This delay may change your CCD.'
						SET @delayNoteText = REPLACE(@delayNoteText, '%1',CONVERT(VARCHAR(10), DATEADD(day, 31, GETDATE()) , 103))
						--V9.8 ends
					END
					ELSE IF (@delayNoteCode = '9848')
					BEGIN
						SET @OrderItemNoteType = 'Delay Notes'
						--V9.8 starts
						SET @OrderItemNoteText = 'DELAY REASON:Hazards, Health and Safety issueNOTES BY PLANNER:.LAST CP/END USER SPOKEN TO:(name, contact detail and date/time)ACTION AGREED OR TAKEN:ACTIVITY DELAYED UNTIL:(review or estimated resolve date)EXPECTED CP ACTION: This delay may change your CCD.'
						SET @delayNoteText = REPLACE(@delayNoteText, '%1',CONVERT(VARCHAR(10), DATEADD(day, 31, GETDATE()) , 103))
						--V9.8 ends
					END
					--v9.5 ends
					IF  EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE Ordernumber=@pOrderNumber and Name='SetECCRe_planning' and value='Y' )
					BEGIN
						SET @OrderItemNoteType='Update'
						SET @OrderItemNoteText='600;This is the second delay sent for ECC AUthorisation. Kindly place ECC Amend to re-confirm the ECC Band entered by Mobile Planners during ECC Re-Authorisation'
					END
				END
			END
			--V8.1 ends
			--V8.4 starts 
			IF @Product1Name in ('Generic Ethernet Access - FTTP','FVA') AND  Isnull(@LORN, '') = ''  and @delayNoteCode ='5750' 
			BEGIN
				SET @delayNoteText ='Excess construction charge band supplied value {ECChargeBand} is not within the OR derived charge band value {ECCBand}. Please provide authorisation for the required ECChargeBand, if you do not reply before {Delaydate} the order will be cancelled.'
				SET @delayNoteText = REPLACE(@delayNoteText, '{Delaydate}',CONVERT(VARCHAR(10), DATEADD(day, 31, GETDATE()) , 103))
			END
			--V8.4 ends
			--V8.3 starts
			IF @pKCIDelayReason='9398_Unknown_5751_Unknown_9350_Unknown'
			BEGIN
				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams where OrderNumber=@pOrderNumber and Name='ECCBehaviour')
					INSERT INTO OrderParams Values(@pOrderNumber,'ECCBehaviour','outside CP authorised value')
				ELSE
					Update OrderParams SET value='outside CP authorised value' where Name='ECCBehaviour' and OrderNumber=@pOrderNumber
			END

			IF @pKCIDelayReason='9797_529_Unknown_5787_Unknown'
			BEGIN
				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams where OrderNumber=@pOrderNumber and Name='OrderBehaviour')
					INSERT INTO OrderParams Values(@pOrderNumber,'OrderBehaviour','E2E cross connect outsourcing')
				ELSE
					Update OrderParams SET value='E2E cross connect outsourcing' where Name='OrderBehaviour' and OrderNumber=@pOrderNumber
			END
			--V8.3 ends
			--V8.5 Begins
			IF (@Product1Name='PIA' and ISNULL(@delayNoteCode,'')<>'')
			BEGIN
				IF @pKCIDelayReason in ('Delay_ResponseToKCINotice','Delay_InsufficientInformation_Coop','Delay_InsufficientInformation_NA')--V8.6
					SET @delayNoteCode='000'+@delayNoteCode

				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE OrderNumber=@pOrderNumber and Name='CurrentKCIDelayReason')
					INSERT INTO OrderParams values(@pOrderNumber,'CurrentKCIDelayReason',@pKCIDelayReason) 
				ELSE
					Update OrderParams SET Value=@pKCIDelayReason WHERE OrderNumber=@pOrderNumber and name='CurrentKCIDelayReason'
			END
			--v8.5 Ends
			--V8.9 starts
			IF (@pKCIDelayReason='593-CPDelay(SupplementaryKSU)' and @Product1Name = 'SOGEA')
			BEGIN
				SET @AppointmentFailed='Y'
				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE OrderNumber = @pOrderNumber AND Name = 'AppointmentFailed')
					INSERT INTO OrderParams VALUES (@pOrderNumber,'AppointmentFailed',@AppointmentFailed)
				ELSE
					UPDATE OrderParams SET [Value] = @AppointmentFailed WHERE OrderNumber = @pOrderNumber AND Name = 'AppointmentFailed'

				SET @EUConfirmedDelay = 'Y'

				IF NOT EXISTS(SELECT TOP 1 1 FROM OrderParams WHERE OrderNumber = @pOrderNumber AND Name = 	'EUConfirmedDelay')
					INSERT INTO OrderParams VALUES (@pOrderNumber , 'EUConfirmedDelay', @EUConfirmedDelay)
				ELSE
					UPDATE OrderParams SET [Value] = @EUConfirmedDelay WHERE OrderNumber = @pOrderNumber AND Name = 'EUConfirmedDelay'
			END
			--v8.9 Ends
			-- V9.4 Begins
			DECLARE @AppointmentRef AS VARCHAR(200)
			DECLARE @SendEAOSSwitch AS VARCHAR (10) = ''
			DECLARE @EngineerArrivalOnSite AS VARCHAR(200)
			DECLARE @NoAccessDateTime AS VARCHAR(200)
			--V10.2 Starts
			DECLARE @SOTAPEASwitch AS VARCHAR(3)
			DECLARE @ProductName AS VARCHAR(20)
			SET @SOTAPEASwitch=(SELECT Status FROM Switches WHERE SwitchName='SOTAP_Earliest_Appointment_Details')
			SET @ProductName=(Select value from orderparams where ordernumber=@pOrdernumber and Name='ProductName')
			--V10.2 Ends
			SET @SendEAOSSwitch=(SELECT [Status] from Switches WHERE SwitchName='SendEAOS_Switch')
			IF ( @SendEAOS='Y' AND @SendEAOSSwitch='ON' )OR(@SendEAOS='Y' AND @SOTAPEASwitch='ON' AND ISNULL(@ProductName,'')='SOTAP')  --V10.2 Added for SOTAP
			BEGIN
				SET @AppointmentRef =(SELECT [Value] FROM OrderParams WHERE OrderNumber = @pOrderNumber and [Name] = 'BESAppointmentID' )
				IF (@AppointmentRef <> '')
				BEGIN
					EXEC [dbo].[spUpdateEAOSandNADT] @AppointmentRef, @pOrderNumber,  -- V9.4.2
					@EngineerArrivalOnSite= @EngineerArrivalOnSite OUTPUT,
					@NoAccessDateTime= @NoAccessDateTime OUTPUT
				END
				--V10.5 Begins
				IF ISNULL(@DelayType,'')='OpenReach'
	            BEGIN
	            SET @NoAccessDateTime = ''
	            END
				--V10.5 Ends
			END
			ELSE
			BEGIN
				SET @SendEAOS='N'
			END
			-- V9.4 Ends
			-- V10.4 START
			IF (@Product1Name='SOTAP' and @pKCIDelayReason='565+9818 - Delay + insufficient TRC')
			BEGIN
				Select @TRCBand=ISNULL(value,'') from orderparams where ordernumber=@pOrderNumber and name='TRCChargeBand'
				set @TRCBand=@TRCBand+1
				SET @pAdditionalNotesXML= Replace(@pAdditionalNotesXML, '%1', @TRCBand)
				-- SET @EngineerNotes= Replace(@EngineerNotes, 'X', @TRCBand) 
			END
			-- V10.4 ends
			--V9.3
			IF (@pKCIDelayReason IN ('1610 - Test capacity not available_SuppPro','563 - Removal of DACS_SuppPro','574 - Delayed During Test_SuppPro','592 - Delay due to Tie pair in Use_SuppPro','SOTAP_Health and Safety_SuppPro') and @Product1Name = 'SOTAP')
			BEGIN
				DECLARE @day VARCHAR(50)=''
				SET @Nextupdatedate  = LEFT(CONVERT(VARCHAR(64), GETDATE(), 127), 19)
				SET @day=''
				WHILE (@day <> 'NotAHoliday')
				BEGIN
					SET @Nextupdatedate =LEFT(CONVERT(VARCHAR(64), DATEADD(day,1,@Nextupdatedate ), 127), 19)
					SET @day=(Select DayOftheWeek from fnCheckforHoliday(@Nextupdatedate ))
				END
				SET @Nextupdatedate = convert(varchar(20),convert(datetime,@Nextupdatedate,126),103) --v9.3.1
				SET @Nextupdatedate =  @Nextupdatedate+ ' 00:00:00'--v9.3.1
			END
			--V9.3
			
			--V10.6 Starts
			IF ( @delayNoteCode = '9601' AND @pKCIDelayReason = '9601 - Additional build works required' )   
			BEGIN  
				SELECT @CommitmentDate2 = value, @OrderDateNvarchar = value FROM   dbo.orderparams WHERE  ordernumber = @pOrderNumber AND NAME = 'CommitmentDate'  
				IF Isnull(@CommitmentDate2, '') <> ''  
				BEGIN  
					IF @OrderDateNvarchar LIKE '%T%'  
					BEGIN  
						EXEC @WK =[dbo].[Fn_weekday] @CommitmentDate2  
						IF ( @WK = 'SAT' )  
						SELECT @CommitmentDate2 = Dateadd(dd, 2, @CommitmentDate2)  
						ELSE IF ( @WK = 'MON' OR @WK = 'TUE' OR @WK = 'WED' OR @WK='THU' OR @WK = 'SUN' )  
						SELECT @CommitmentDate2 = Dateadd(dd, 1, @CommitmentDate2)  
						ELSE IF ( @WK = 'FRI' )  
						SELECT @CommitmentDate2 = Dateadd(dd, 3, @CommitmentDate2)  
						--Below to convert GEA to UK DD/mm/yyyy  
						SET @CalculatedDate = Replace(CONVERT(VARCHAR(20),CONVERT(DATETIME, @CommitmentDate2,126),103),'/','-')
					END  
					ELSE  
						SET @CalculatedDate =@CommitmentDate2  
				END  
				SET @delayNoteText =  'Additional build works are required to fulfil the order. The Earliest Available Date is ' + @CalculatedDate  + '.' 
			END 
			--V10.6 Ends
			-- now return the params. note deemed consent not fully supported yet
			
			
--V10.9, V10.10	starts
       IF Isnull(@delayNoteCode, '') = '9877' and @Product1Name in ( 'Generic Ethernet Access - FTTP','SOGEA') and @pKCIDelayReason in ('9877-Required advanced SVR','9877-Required premium SVR','9877+9700 - Required Advanced SVR','9877+9700 - Required Premium SVR','9877 - Required premium SVR(pre KCI2)','9877 - Required advanced SVR(pre KCI2)','9877 - Required premium SVR SOGEA(pre KCI2)','9877 - Required advanced SVR SOGEA(pre KCI2)')--15.4  --Adding pre KCI 2 9877 KCI Delay Reasons in condition send list of notes --V15.6 Added SOGEA pre KCI2 scenarios
			   BEGIN
				DECLARE @temp_table table (productname varchar(50), answertext varchar(max), flag varchar(1), dense_value varchar(20),svr varchar(20))
				DECLARE @temp_table1 table (productname varchar(50), Answerid varchar(20), answertext varchar(max), svr varchar(10),flag varchar(1),dense_value varchar(1))
				insert into @temp_table1 select *, dense_rank() over ( order by svr,flag,productname) dense_svr from QBF_L2C_details order by 6
					BEGIN
					INSERT INTO @temp_table SELECT p1.productname,( SELECT ANSWERTEXT +';'FROM @temp_table1 p2 
					WHERE p2.productname = p1.productname and p1.dense_value=p2.dense_value ORDER BY dense_value
					FOR XML PATH('') ) AS Answertext,p1.flag,dense_value,p1.svr FROM @temp_table1 p1 GROUP BY dense_value, p1.productname,p1.flag,p1.svr
					order by 1;
					END
				END
			
--V10.9, V10.10	ends

			declare @answertextvalue varchar(max)--V10.9
			declare @SVR varchar(10)-- V10.9 
			
			-- V10.7 STARTS
			-- V10.9 STARTS
			IF Isnull(@delayNoteCode, '') = '9877' and (@Product1Name = 'Generic Ethernet Access - FTTP' or @Product1Name = 'SOGEA') and (@pKCIDelayReason='9877-Required premium SVR' or  @pKCIDelayReason='9877-Required advanced SVR' or @pKCIDelayReason='9877+9700 - Required Premium SVR' or @pKCIDelayReason='9877+9700 - Required Advanced SVR'
					OR @pKCIDelayReason='9877 - Required premium SVR(pre KCI2)' OR @pKCIDelayReason='9877 - Required advanced SVR(pre KCI2)'
					OR @pKCIDelayReason='9877 - Required premium SVR SOGEA(pre KCI2)' OR @pKCIDelayReason='9877 - Required advanced SVR SOGEA(pre KCI2)')--V11.1 --V14.8
			BEGIN  
				IF (@pKCIDelayReason='9877-Required premium SVR' or @pKCIDelayReason='9877+9700 - Required Premium SVR' OR @pKCIDelayReason='9877 - Required premium SVR(pre KCI2)'
				OR @pKCIDelayReason='9877 - Required premium SVR SOGEA(pre KCI2)')--V11.1 --V14.8 V15.3
				    SET @SVR='Premium'
				---V14.8 STARTS	
				--intentionally not setting the SVR to advanced in the else block
				--Incase of 9877 adv pre KCI2 delay (ie. when RecommendMinSvrNLP = Advanced) is set then only set SVR to advanced
				ELSE IF (@pKCIDelayReason='9877 - Required advanced SVR(pre KCI2)'OR @pKCIDelayReason='9877 - Required advanced SVR SOGEA(pre KCI2)')  --V15.3
					SET @SVR='Advanced'
				---V14.8 ENDS
				ELSE
				    SET @SVR='Advanced'

				SET @orderplaceddate=(Select CONVERT(DATETIME,value,126) from Dataprovider.dbo.orderparams where ordernumber=@pOrderNumber and Name='OrderPlacedDate')  
                --SET @Activitycompletiondate=(SELECT CONVERT(varchar(30),dbo.fnCalculateDates(CONVERT(VARCHAR(10),CONVERT(DATETIME,getdate(),120),120),15),105)) --commeenting to change to 15 calender days
				SET @Activitycompletiondate= (SELECT CONVERT(varchar(30),getdate()+15,105))--V10.9.2
				
				SET @AvailableDate_DDMMYYYY = SUBSTRING(@Activitycompletiondate, 1, 2)+'/'+SUBSTRING(@Activitycompletiondate, 4, 2)+'/'+ SUBSTRING(@Activitycompletiondate, 7, 4)
				SET @AvailableDate_DDMMYYYY= REPLACE(@AvailableDate_DDMMYYYY,' 00:00:00','')  
				SET @delayNoteText= Replace(@delayNoteText, '[%1]', @SVR)  
				SET @delayNoteText= Replace(@delayNoteText, '[%2]', @AvailableDate_DDMMYYYY)  
		      
				SET @answertextvalue= (select left(answertext, len(answertext)-1) as answertextvalue  from @temp_table where productname=@Product1Name and SVR=@SVR and flag='Y')
		
		        SET @OrderItemNoteType='Delay Notes'--V10.9.1
		        SET @OrderItemNoteText='600;'+ @answertextvalue +''
				
				--V11.1 starts
				IF (@pKCIDelayReason='9877+9700 - Required Premium SVR' or @pKCIDelayReason='9877+9700 - Required Advanced SVR')
				Begin 
				SET @pAdditionalNotesXML= @pAdditionalNotesXML +'<Note><NoteId>600</NoteId><NoteType>Delay Notes</NoteType><NoteText>'+ @SVR +'</NoteText></Note>'  ---- V11.1.1 
				SET @pAdditionalNotesXML= @pAdditionalNotesXML +'<Note><NoteId>600</NoteId><NoteType>Delay Notes</NoteType><NoteText>'+ @answertextvalue +'</NoteText></Note>'
				END
				--V11.1 ends
				
	-- V10.9 ends			
			END 
			-- V10.7 ENDS
			-- V14.3 START
			IF(@Product1Name='SOGEA' AND 
			(@pKCIDelayReason='9902+9700_VRI Faceplate or extension kit is missing' OR
			@pKCIDelayReason='9903+9700_IP voice is not working' OR
			@pKCIDelayReason='9904+9700_Telecare device was found without Prove Telecare SVR'))
			BEGIN
				DECLARE @keyword VARCHAR(100)
				IF (@pKCIDelayReason='9902+9700_VRI Faceplate or extension kit is missing') SET @keyword='TKNP'
				ELSE IF(@pKCIDelayReason='9903+9700_IP voice is not working') SET @keyword='DVNW'
				ELSE IF(@pKCIDelayReason='9904+9700_Telecare device was found without Prove Telecare SVR')SET @keyword='TDP'
				
				SET @pAdditionalNotesXML='<Note>
                            <NoteId>3511</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'</NoteText>
                        </Note>
						<Note>
                            <NoteId>3512</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>IRC, '+@keyword+'</NoteText>
                        </Note>
                        <Note>
                            <NoteId>600</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>Notes '+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'  Some Notes</NoteText>
                        </Note>'
						+@pAdditionalNotesXML
			END
			--V14.3 END
			--V14.6 STARTS
			IF(@Product1Name='Generic Ethernet Access - FTTP' AND (@pKCIDelayReason='9928_600-Telecare present,working on arrival,Personal Alarm' OR
			@pKCIDelayReason='9928_600-Telecare present,not working on arrival,Personal Alarm' OR
			@pKCIDelayReason='9928_600-Telecare present,working on arrival,not Personal Alarm' OR
			@pKCIDelayReason='9928_600-Telecare present,not working on arrival,not Personal Alarm' OR
			@pKCIDelayReason='9928_600-Telecare not present,not working post-migration,Personal Alarm' OR
			@pKCIDelayReason='9928_600-Telecare not present,not working post-migration,not Personal Alarm'))
			BEGIN
				
				SET @pAdditionalNotesXML='<notes>
							<noteType>Engineer Notes</noteType>
							<text>600;Notes:'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'  ---------------------- Engineer details Engineer name: Shaw ---------------------- #Incomplete task summary# CP action is required to complete the job. ---------------------- #Work done# No work completed.  ---------------------- Notes from engineer: Tele care system ONT installation - INCOMPLETE CBTCSP connectivity - COMPLETE CSP installation - COMPLETE </text>
						</notes>
						<notes>
							<noteType>Engineer Notes</noteType>
							<text>3511;Engineer arrival time onsite,'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'</text>
						</notes>
						<notes>
							<noteType>Engineer Notes</noteType>
							<text>3512;IRC,TSNW</text>
						</notes>'
						+@pAdditionalNotesXML
			END
			-- V14.6 ENDS
			--V14.9 STARTS
			IF(@Product1Name='Generic Ethernet Access - FTTP' AND (@pKCIDelayReason like '%9931%'))
			BEGIN
				SET @pAdditionalNotesXML='<notes>
							<noteType>Engineer Notes</noteType>
							<text>600;Notes:'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'  ---------------------- Engineer details Engineer name: Arron,Brown ---------------------- Ring ahead information Primary customer name:NAZISH AMIN Contact no:07912629209 Call outcome:No answer (VM left if available) Call outcome to secondary contact no: Not able to ring ahead due to unusable contact details (missing / incorrect / faulty line) ------------------------------- #Incomplete task summary# Access to skills or support is required to complete the job. ---------------------- #More details# Civils support : duct required after the CBT. Customers impacted : 1 ---------------------- #Work done# No work completed. ---------------------- Notes from engineer: Duct required for customer lead in Perm to work signed from customer and a55 submitted A55 ref: K7GMR ---- A55 Please follow this link to access A55 details. https://openreach-planning.intra.bt.com:61035/wfmt/controller?swAction=152A55Reference=K7GMR CBTCSP connectivity - INCOMPLETE CSP installation - INCOMPLETE </text>
						</notes>
						<notes>
							<noteType>Engineer Notes</noteType>
							<text>3511;Engineer arrival time onsite,'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'</text>
						</notes>
						<notes>
							<noteType>Engineer Notes</noteType>
							<text>3512;IRC,XDIG</text>
						</notes>'
			END
			--V14.9 ENDS
			
				-- V14.7 STARTS
			IF(@Product1Name='SOGEA' AND (
			@pKCIDelayReason='9928+9700_Telecare is not working after service activation'  OR  --V14.7.2  STARTS
			@pKCIDelayReason='9928+9700-Telecare present,working on arrival,Personal Alarm' OR  
			@pKCIDelayReason='9928+9700-Telecare present,not working on arrival,Personal Alarm' OR
			@pKCIDelayReason='9928+9700-Telecare present,not working on arrival,not Personal Alarm' OR
			@pKCIDelayReason='9928+9700-Telecare not present,not working post-migration,Personal Alarm' OR
			@pKCIDelayReason='9928+9700-Telecare not present,not working post-migration,not Personal Alarm'))--V14.7.2  ENDS

			BEGIN
				SET @pAdditionalNotesXML='<Note>
                            <NoteId>3511</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>'+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+'</NoteText>
                        </Note>
						<Note>
                            <NoteId>3512</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>IRC, TSNW</NoteText>
                        </Note>
                        <Note>
                            <NoteId>600</NoteId>
                            <NoteType>Engineer Notes</NoteType>
                            <NoteText>Notes '+CONVERT(VARCHAR(10), GETDATE(), 103) + ' '  + convert(VARCHAR(8), GETDATE(), 14)+ '---------------------- Engineer details Engineer name: James,Robinson ---------------------- #Incomplete task summary# CP action is required to complete the job.</NoteText>   
                        </Note>' -----V14.7.3
						+@pAdditionalNotesXML
			END
			--V14.7 ENDS
			
			--V15.0 STARTS
			IF (@pKCIDelayReason='Excess Construction Charge with Ruggedised')
				BEGIN
				IF NOT EXISTS(select top 1 1 from OrderParams where OrderNumber=@pOrderNumber and Name='ECC_CheckFor5750' and value ='Y')
				BEGIN
					INSERT INTO Dataprovider.dbo.OrderParams(OrderNumber, Name, Value) VALUES (@pOrderNumber,'ECC_CheckFor5750','Y');
				END
				ELSE
				BEGIN
				 UPDATE OrderParams SET Name='ECC_CheckFor5750', VALUE='Y' WHERE ORDERNUMBER = @pOrderNumber
				END
					SET @delayNoteCode = '5750|9925'
					SET @delayNoteText = 'Excess construction charge band supplied value {ECChargeBand} is not within the OR derived charge band value {ECCBand}. Please provide authorisation for the required ECChargeBand, if you do not reply before {Delaydate} the order will be cancelled.|Order is delayed as Ruggedised ONT and 12V DC power supply is required for this location.'
					SET @delayNoteText = REPLACE(@delayNoteText, '{Delaydate}',CONVERT(VARCHAR(10), DATEADD(day, 5, GETDATE()) , 103))
				END
			--V15.0 ENDS
			
			
			SELECT @pAdditionalNotesXML  AS AdditionalNotesXML,
			@pAppointmentReqd     AS AppointmentReqd,
			@delayNoteCode   AS delayNoteCode,
			@delayNotes AS delayNotes,
			@delayNoteText   AS delayNoteText,
			@delayNoteType   AS delayNoteType,
			@SubsequentReason     AS KCIDelayReason,
			-- return the follow on reason (will be blank if no further delays required)
			@ReappointmentReqd    AS ReappointmentReqd,
			@AmendReason     AS delayAmendReason,
			@AmendRequired   AS AmendRequired,
			@ConfirmationRequired AS delayConfirmationRequired,
			@DeemedConsent   AS DeemedConsent,
			@EngineerNotes   AS EngineerNotes,
			@DelayNoteFormat AS DelayNoteFormat,
			@SequenceNo AS DelaySequenceNumber,
			@OrderItemNoteType    AS OrderItemNoteType,
			@OrderItemNoteText    AS OrderItemNoteText,
			@NoteCode   AS NoteCode,
			@NoteText   AS NoteText,
			@NoteType   AS NoteType,
			-- V2.2 Begin
			@LO_DelayReason  AS LO_DelayReason,
			-- V2.2 End
			--V2.12 Begin
			@externalNotes   AS externalNotes,
			-- V2.12 End
			@SIM2PCPOnly     AS SIM2PCPOnly,--V4.0
			@EUConfirmedDelay     AS EUConfirmedDelay,--v5.9 
			@EUOrOpenreachMissed  AS EUOrOpenreachMissed,--V5.9 
			@9708Requested  AS '9708Requested', --V6.1  --V8.6 Realigned
			@AvailableDate   AS 'AvailableDate2', --V6.7     --V6.9.2
			@AppointmentFailed AS   'AppointmentFailed',  --V8.9
			@isTOPdelay AS 'isTOPdelay',
			@Nextupdatedate as 'Nextupdatedate',  -- V9.3 
			@SendEAOS AS SendEAOS,   -- V9.4
			@EngineerArrivalOnSite AS EngineerArrivalOnSite,  -- V9.4
			@NoAccessDateTime AS NoAccessDateTime  -- V9.4
		END
	END  
     
  
GO
PRINT 'spSetKSUDelayDetails has been created'

