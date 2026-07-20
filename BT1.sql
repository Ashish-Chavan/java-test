USE [DataProvider];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS (SELECT * FROM sys.objects nolock WHERE type = 'P' AND name = 'spFTTPModify_ONT')
BEGIN
DROP PROC [spFTTPModify_ONT]
PRINT 'spFTTPModify_ONT has been dropped'
END
GO 

-- ===============================================================================  
-- By Suguna Devi  
-- OR-74359 Validate and update to 2.5GONT if requested to modify to >1G Bandwidth  
-- V1.1 OR-74359 Set Orderbehavior and fixed when request is not for FTTP.  
-- V1.2 ORTECH-4643/ORTECH-4644 FTTP XGSPN Modify rejection scenarios and BOX Swap Acceptnace Scenarios   
-- V1.2.1 ORTECH-4643/ORTECH-4644 To send 7006 rejection for Modify order placed on open modify order for Box swap to Modify XGS bandwidth scenario.
-- V1.3 R6100 Drop 1 ORTECH-18322_ORTECH-18323 - Addition of '5500Mbit/s', '8500Mbit/s' to existing XGSPON bandwdith
-- ===============================================================================  
CREATE PROCEDURE [dbo].[spFTTPModify_ONT] (  
 @pServiceID varchar(20),  
 @pCustomerID varchar(20),  
 @pAddressNadKey varchar(20),  
 @pONTSerialNumber as varchar(20),  
 @pPortNumber as varchar(20),  
 @pOrderNumber as varchar(20),  
 @pSubOrderType as varchar(128),  
 @pONTReference AS VARCHAR(50),  
 @pProductName as varchar(50),  
 @pSiteVisitReason   as varchar(50),  
 @pPreAuthorisedSiteVisitReason as varchar(50),  
 @pDownstreamDataBandwidth as varchar(20),  
 @pUpstreamDataBandwidth as varchar(20)  
)  
AS  
BEGIN  
 --BEGIN TRANSACTION--V1.1 moved below  
  BEGIN TRY  
   DECLARE @OrderRejectionReason varchar(max)  
   DECLARE @OrderRejectionCode varchar(10)  
   DECLARE @L2Smanufacturer Varchar(max)  
   DECLARE @OrderBehaviour varchar(50)  
   DECLARE @Exchangecode varchar(10)=(SELECT ExchangeGroupCode FROM Addresses(nolock)a WHERE AddressNadKey=@pAddressNadKey)  
   SET @OrderBehaviour=(Select Value from orderparams where ordernumber=@pOrderNumber and Name='OrderBehaviour')--V1.1  
   IF ISNULL(@pONTSerialNumber,'')=''  
   BEGIN  
    SET @pONTSerialNumber=(SELECT ONTSerialNumber from FTTPONTs where ReferenceNo=@pONTReference)  
   END  
     
   DECLARE @Portcount int =(SELECT Count(1) FROM FTTPONTPortData(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber)    
   DECLARE @WorkingPortCount int =(SELECT Count(1) FROM FTTPONTPortData(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber and Status='W')  
   DECLARE @FVAService int =(SELECT Count(1) FROM FTTPONTPortData(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber and Status='W' AND ServiceID like 'OFVA%')  
   DECLARE @ONTType varchar(50) =(SELECT ONTType FROM FTTPONTs(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber)  
   DECLARE @ONTmodel varchar(10)=(SELECT VALUE FROM ExchangeParams(nolock)a WHERE ExchangeCode=@Exchangecode and Name='ONTmodel')  
   Declare @InflightOrderNo varchar(50)  
   Declare @MLTLookupKey varchar(30)  
   DECLARE @ONTManufacturer varchar(20)=(SELECT ONTManufacturer FROM FTTPONTs(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber)  
   DECLARE @GLOBAL_2_5G_IL2S_Switch varchar(3)=(SELECT status from Switches where SwitchName='GLOBAL_2_5G_IL2S_Switch')  
     
   ----V1.2 BEGINS                                
            DECLARE  @ONTBANDWIDTH VARCHAR(10)                                
            DECLARE  @pFloor AS varchar(50)                        
            DECLARE  @pRoom AS varchar(50)                                                 
            DECLARE  @pPosition AS varchar(50)                                    
            DECLARE @XGS_ENABLED AS VARCHAR(10)                             
            DECLARE @NewONTReference as varchar(100) =''                                 
             SET @XGS_ENABLED=(SELECT Value FROM ExchangeParams WHERE ExchangeCode=@Exchangecode AND NAME='XGS_Enabled')    
    SET @ONTBANDWIDTH =(SELECT ONTBANDWIDTH FROM  FTTPONTs where ONTSerialNumber=@pONTSerialNumber)   
                             
           IF ISNULL(@ONTManufacturer,'')=''                            
            BEGIN                            
               SET @ONTManufactureR=(SELECT VALUE FROM ExchangeParams WHERE NAME='L2SManufacturer' AND ExchangeCode=@Exchangecode)                            
            END                            
            ----V1.2 ENDS  
     
   IF (ISNULL(@GLOBAL_2_5G_IL2S_Switch,'')='ON' AND ISNULL(@ONTmodel,'')='')  
   BEGIN  
    SET @ONTmodel='2.5G'  
   END  
     
   IF EXISTS(SELECT TOP 1 1 FROM ExchangeParams E INNER JOIN Addresses A ON E.ExchangeCode=A.ExchangeGroupCode  WHERE  A.AddressNadKey = @pAddressNADKey and Name='L2SManufacturer')  
   BEGIN  
    SET @L2Smanufacturer=(SELECT E.Value FROM ExchangeParams E INNER JOIN Addresses A ON E.ExchangeCode=A.ExchangeGroupCode  WHERE  A.AddressNadKey = @pAddressNADKey and Name='L2SManufacturer')  
   END  
     
   IF ISNULL(@pProductName,'')='Generic Ethernet Access - FTTP'  
   BEGIN  
    BEGIN TRANSACTION--V1.1  
    IF ISNULL(@OrderBehaviour,'')='9739-Incompatible infrastructure' and @ONTmodel='2.5G' and @pSubOrderType like '%Modify%'  
    BEGIN  
     SET @OrderRejectionReason='The requested service is not compatible with the network infrastructure serving the end customer premises.'  
     SET @OrderRejectionCode='9739'  
     RAISERROR ('Rejection', 16, 1)  
    END  
    IF ISNULL(@ONTmodel,'')='' and @pSubOrderType like '%Modify%' AND(@pDownstreamDataBandwidth ='1200Mbit/s' OR @pDownstreamDataBandwidth='1800Mbit/s') AND @pUpstreamDataBandwidth ='120Mbit/s'  
    BEGIN  
     SET @OrderRejectionReason='The requested service is not compatible with the network infrastructure serving the end customer premises.'  
     SET @OrderRejectionCode='9739'  
     RAISERROR ('Rejection', 16, 1)  
    END  
      
    IF(@Portcount > 1 and @WorkingPortCount > 1 and @ONTmodel='2.5G' and @pSubOrderType like '%Modify%')  
    BEGIN  
     SET @OrderRejectionReason='Incompatible Installation exists'  
     SET @OrderRejectionCode='113'  
     RAISERROR ('Rejection', 16, 1)  
    END  
  
    IF(@ONTmodel='2.5G' and @pSubOrderType like '%Modify%' AND @FVAService>=1)    
    BEGIN    
     SET @OrderRejectionReason='Incompatible Installation exists'     
     SET @OrderRejectionCode='113'    
     RAISERROR ('Rejection', 16, 1)  
    END  
      
    SET @InflightOrderNo=(Select top 1 InflightOrderNo from FTTPONTPortData where ONTSerialNumber=@pONTSerialNumber and InflightOrderNo<>'')  
    IF EXISTS (SELECT TOP 1 1 FROM OrderParams WHERE  Ordernumber=@InflightOrderNo)  
    BEGIN  
     SET @OrderRejectionReason = 'Order rejected due to conflicting open order'  
     SET @OrderRejectionCode = '7006'  
     RAISERROR ('Rejection', 16, 1)  
    END  
  
    --Box Swap Function  
    --Existing service='Multi Port ONT' and Requested Bandwidth>1G   
    IF(@Portcount > 1 and @ONTmodel='2.5G' AND @WorkingPortCount=1  and @pSubOrderType like '%Modify%' and (@pDownstreamDataBandwidth ='1200Mbit/s' OR @pDownstreamDataBandwidth='1800Mbit/s') AND @pUpstreamDataBandwidth ='120Mbit/s')  
    BEGIN    
     WITH CTE AS(    
     SELECT ROW_NUMBER() OVER(ORDER BY port,[porttype])Rno,* from FTTPONTPortData(nolock)a WHERE ONTSerialNumber=@pONTSerialNumber)  
     DELETE from CTE WHERE Rno>1  
     SET @MLTLookupKey='2.5G_ONTbox-swap'  
    END  
  
    --Existing service is <1G and Requested Bandwidth>1G   
    IF(@ONTType NOT IN ('SDX 611q GPON ONU','G-010G-T') AND @ONTmodel='2.5G' and @WorkingPortCount=1 and @pSubOrderType like '%Modify%' AND (@pDownstreamDataBandwidth ='1200Mbit/s' OR @pDownstreamDataBandwidth='1800Mbit/s') AND @pUpstreamDataBandwidth ='
120Mbit/s') OR @MLTLookupKey='2.5G_ONTbox-swap'  
    BEGIN  
     IF (@L2Smanufacturer='NOKIA')  
      UPDATE FTTPONTs SET ONTType='G-010G-T',InstallationDate=GETDATE() WHERE ReferenceNo=@pONTReference and ONTSerialNumber=@pONTSerialNumber  
     ELSE IF (@L2Smanufacturer='ADTRAN')  
      UPDATE FTTPONTs SET ONTType='SDX 611q GPON ONU',InstallationDate=GETDATE() WHERE ReferenceNo=@pONTReference and ONTSerialNumber=@pONTSerialNumber  
     SET @MLTLookupKey='2.5G_ONTbox-swap'  
    END  
  
    --Remote Activation  
    IF (@pSubOrderType like '%Modify%') AND (@pSiteVisitReason='Standard' OR @pSiteVisitReason='Premium')and ISNULL(@pONTReference,'')<>'' AND ISNULL(@MLTLookupKey,'')='' AND  @pDownstreamDataBandwidth NOT in ('2500Mbit/s','3300Mbit/s','5500Mbit/s', '8500Mbit/s')  --V1.3
    BEGIN  
     SET @OrderRejectionReason = 'The Site Visit Reason of '+@pSiteVisitReason+' is not available for this product.'  
     SET @OrderRejectionCode = '9779'  
     RAISERROR ('Rejection', 16, 1)   
    END  
    ELSE IF (@pSubOrderType like '%Modify%') AND (@pSiteVisitReason='Premium' OR @pSiteVisitReason='Advanced') and ISNULL(@pONTReference,'')<>'' AND ISNULL(@MLTLookupKey,'')='2.5G_ONTbox-swap'  
    BEGIN  
     SET @OrderRejectionReason = 'The Site Visit Reason of '+@pSiteVisitReason+' is not available for this product.'  
     SET @OrderRejectionCode = '9779'  
     RAISERROR ('Rejection', 16, 1)   
    END  
       
    IF  (@pSubOrderType like '%Modify%') and ISNULL(@pONTReference,'')<>'' AND ISNULL(@MLTLookupKey,'')='2.5G_ONTbox-swap' AND @pSiteVisitReason='No site visit'  
    BEGIN  
     SET @OrderRejectionReason = 'The requested service can only be ordered as part of an End Customer Install'  
     SET @OrderRejectionCode = '9764'  
     RAISERROR ('Rejection', 16, 1)   
    END  
      
    ---- V1.2 BEGINS (Rejection scenarios on FTTP Modify Orders)  
                              
           IF (ISNULL(@pProductName,'')='Generic Ethernet Access - FTTP'   AND  @pDownstreamDataBandwidth in ('2500Mbit/s','3300Mbit/s','5500Mbit/s', '8500Mbit/s'))  --V1.3
               BEGIN    
                  IF(ISNULL(@ONTBANDWIDTH,'')<>'XGSPON' AND @pSiteVisitReason='No site visit' AND @WorkingPortCount = 1)  
               BEGIN  
                      SET @OrderRejectionReason = 'The requested service can only be ordered as part of an End Customer Install'                                    
                      SET @OrderRejectionCode = '9764'                                    
                      RAISERROR ('Rejection', 16, 1)                                     
                 END  
             ELSE IF(ISNULL(@ONTBANDWIDTH,'')<>'XGSPON' AND @pSiteVisitReason in('Premium','Advanced') AND @WorkingPortCount = 1 AND  isnull(@ONTType,'')<>'SDX 610s GPON SFP ONU')   
                  BEGIN                      
                      SET @OrderRejectionReason = 'The Site Visit Reason of '+@pSiteVisitReason+' is not available for this product.'                                    
                      SET @OrderRejectionCode = '9779'                                    
                      RAISERROR ('Rejection', 16, 1)                                     
                 END                                 
              ELSE IF(ISNULL(@ONTBANDWIDTH,'')='XGSPON' AND @pSiteVisitReason='Standard')              
                BEGIN                                
                    SET @OrderRejectionReason = 'The Site Visit Reason of '+@pSiteVisitReason+' is not available for this product.'                                    
                    SET @OrderRejectionCode = '9779'                                    
                RAISERROR ('Rejection', 16, 1)                                     
               END                                
              ELSE IF(@pSiteVisitReason IN('Standard','Premium') AND @WorkingPortCount>1)               
           BEGIN      
                SET @OrderRejectionReason='Incompatible Installation exists'                                       
                SET @OrderRejectionCode='113'                                      
                RAISERROR ('Rejection', 16, 1)                                    
             END         
              ELSE IF(@pSiteVisitReason ='Standard' AND @WorkingPortCount=1 and ISNULL(@XGS_ENABLED,'')<>'Y' AND ISNULL(@ONTBANDWIDTH,'')<>'XGSPON' )   
       BEGIN                            
                SET @OrderRejectionReason='Incompatible Installation exists'                                       
                SET @OrderRejectionCode='113'                                      
               RAISERROR ('Rejection', 16, 1)                                    
              END                                 
             ELSE IF(@FVAService>=1 AND  (ISNULL(@ONTmodel,'')='1G' OR ISNULL(@ONTBANDWIDTH,'')='1G'))                            
             BEGIN                            
                SET @OrderRejectionReason='Incompatible Installation exists'                                       
                SET @OrderRejectionCode='113'                                      
                RAISERROR ('Rejection', 16, 1)                                    
             END                  
             ELSE IF((@ONTManufacturer='Huawei' OR @ONTManufacturer='ECI') AND @WorkingPortCount=1 AND @pSiteVisitReason='Standard' AND ISNULL(@ONTBANDWIDTH,'')<>'XGSPON')   
            BEGIN                                  
              SET @OrderRejectionReason='The requested service is not compatible with the network infrastructure serving the end customer premises.'                 
           SET @OrderRejectionCode='9739'                                    
              RAISERROR ('Rejection', 16, 1)                                    
           END                              
             ELSE IF(@ONTType='SDX 610s GPON SFP ONU' AND @WorkingPortCount=1 AND @pSiteVisitReason  IN('Standard','Advanced','Premium'))                            
               BEGIN                             
               SET @OrderRejectionReason='The requested service is not compatible with the network infrastructure serving the end customer premises.'                   
            SET @OrderRejectionCode='9739'                                    
               RAISERROR ('Rejection', 16, 1)                                    
            END
			 ----V1.2.1 BEGINS
           ELSE IF(ISNULL(@ONTBANDWIDTH,'')<>'XGSPON' AND @pSiteVisitReason='Standard' AND @WorkingPortCount = 1 AND ISNULL(@OrderBehaviour,'')='7006-Conflicting open order')--- IVVT tested the scenaio by making status as ICM at SRIMS.Since we are not having SRIMS component stubbing is introduced.
          BEGIN  
              SET @OrderRejectionReason = 'Order rejected due to conflicting open order'  
              SET @OrderRejectionCode = '7006'  
          RAISERROR ('Rejection', 16, 1)  
           END 		 ----V1.2.1 ENDS	
        END  
      ------V1.2 ENDS     
    --The ONT reference in the box swap scenario will remain same, only the ONT serial number will change 2.5G  
    IF @MLTLookupKey='2.5G_ONTbox-swap'  
    BEGIN  
     UPDATE DPData SET  ValueNum = CASE ValueNum WHEN 999 THEN 1 ELSE ValueNum + 1 END,  
     ValueStr2 = CASE  
      WHEN ValueStr2 = 'ZZ' AND ValueNum = 999 THEN 'AA'  
      WHEN RIGHT(ValueStr2, 1) = 'Z' AND ValueNum = 999 THEN Char(ASCII(LEFT(ValueStr2, 1)) +1) + 'A'  
      WHEN RIGHT(ValueStr2, 1) <> 'Z' AND ValueNum = 999 THEN LEFT(ValueStr2, 1) + Char(ASCII(RIGHT(ValueStr2, 1)) +1)  
      ELSE ValueStr2  
      END,  
      ValueStr1 = CASE  
      WHEN ValueStr2 = 'ZZ' AND ValueNum = 999 THEN LEFT(ValueStr1, 6) + Cast(Cast(RIGHT(ValueStr1, 2) as int) +1 as Varchar(2))  
      ELSE ValueStr1  
     END,  
     @pONTSerialNumber = ValueStr1 + ValueStr2 + Right('00' + Cast(ValueNum as varchar(3)), 3)  
     FROM DPData  
     WHERE (KeyName = 'ONTSerialNumber' and ParamName = 'Sequence')  
  
     UPDATE FTTPONTs SET ONTSerialNumber=@pONTSerialNumber,InflightOrderNo=@pOrderNumber,Status='I' WHERE ReferenceNo=@pONTReference  
     UPDATE FTTPONTPortData SET ONTSerialNumber=@pONTSerialNumber,InflightOrderNo=@pOrderNumber,Status='I' WHERE ONTSerialNumber=@pONTSerialNumber  
    END  
   COMMIT TRANSACTION  
   END  
     
------V1.2 BEGINS(BOXSWAP Acceptnace scenario)                                  
IF (@pDownstreamDataBandwidth in ('2500Mbit/s','3300Mbit/s','5500Mbit/s', '8500Mbit/s') AND @pSiteVisitReason='Standard' AND @WorkingPortCount = 1 AND ISNULL(@ONTBANDWIDTH,'')<>'XGSPON' AND ISNULL(@XGS_ENABLED,'')='Y' AND ISNULL(@pProductName,'')='Generic Ethernet Access - FTTP' ) --V1.3
                      
  BEGIN                                    
     SET @pFloor =(SELECT Floor FROM  FTTPONTs where ReferenceNo=@pONTReference)                                    
     SET @pRoom =(SELECT Room FROM  FTTPONTs where ReferenceNo=@pONTReference)                                    
     SET @pPosition =(SELECT Position FROM  FTTPONTs where ReferenceNo=@pONTReference)                                    
                                     
 --   Delete the corresponding row from FTTPONTPortData    
    IF EXISTS(SELECT TOP 1 1 FROM  FTTPONTPortData  WHERE ONTSerialNumber = @pONTSerialNumber)  
    BEGIN  
         DELETE FROM FTTPONTPortData  WHERE ONTSerialNumber = @pONTSerialNumber    
    END       
                                            
  ------Delete the corresponding row from FTTPONTS       
    IF EXISTS(SELECT TOP 1 1 FROM  FTTPONTs  WHERE ONTSerialNumber = @pONTSerialNumber)  
      BEGIN  
           DELETE FROM FTTPONTs WHERE ONTSerialNumber = @pONTSerialNumber    
       END     
                              
                                      
    DECLARE @pReference as varchar(50)                        
    DECLARE @TMPError AS VARCHAR(100)   
 DECLARE @NewONTSerialNumber AS VARCHAR(100)  
                                              
  EXEC  dbo.spAllocateONTEntry                                                  
        @pAddressNadKey = @pAddressNadKey,                                                  
        @pOrderNumber = @pOrderNumber,                        
        @pFloor = @pFloor,                                           
        @pRoom = @pRoom,                                                   
        @pPosition = @pPosition,                                                  
        @pIL2SID = NULL,                                    
        @pONTPorts ='XGSPON_1+0ONT',                      
        @pONTSerialNumber = @pONTSerialNumber OUTPUT,                                                  
        @pReference = @pReference OUTPUT,                                    
        @pError = @TMPError OUTPUT      
  
    IF EXISTS(SELECT TOP 1 1 FROM FTTPONTs WHERE ONTSerialNumber=@pONTSerialNumber)  
      BEGIN   
       UPDATE FTTPONTs SET STATUS='I',InflightOrderNo=@pOrderNumber WHERE ONTSerialNumber=@pONTSerialNumber  
      END  
   
   IF EXISTS(SELECT TOP 1 1 FROM FTTPONTPortData WHERE ONTSerialNumber=@pONTSerialNumber)  
    BEGIN  
      UPDATE FTTPONTPortData SET STATUS='I',ServiceID=@pServiceID,InflightOrderNo=@pOrderNumber WHERE ONTSerialNumber=@pONTSerialNumber  
    END    
  
   SET @NewONTReference = (select ReferenceNo from  FTTPONTS WHERE ONTSerialNumber=@pONTSerialNumber)     
  
   END         
   IF(ISNULL(@NewONTReference,'')='')                        
   BEGIN                        
   SET @NewONTReference=@pONTReference                        
   END    
     
---V1.2 ENDS     
      SELECT  
   @pONTSerialNumber as 'ONTSerialNumber'  
   ,@OrderRejectionReason as 'OrderRejectionReason'  
   ,@OrderRejectionCode as 'OrderRejectionCode'  
   ,@MLTLookupKey as 'MLTLookupKey'
   ,@NewONTReference as 'ONTReference'
  END TRY  
  BEGIN CATCH  
   DECLARE @ErrorMessage as NVARCHAR(2047)  
   SELECT @ErrorMessage = ERROR_MESSAGE()  
   IF @ErrorMessage = 'Rejection'  
   BEGIN  
    ROLLBACK TRANSACTION  
    SELECT  
    @pONTSerialNumber as 'ONTSerialNumber'  
    ,@OrderRejectionReason as 'OrderRejectionReason'  
    ,@OrderRejectionCode as 'OrderRejectionCode'  
    ,@MLTLookupKey as 'MLTLookupKey'  
   END  
  END CATCH  
 END  
GO
PRINT 'spFTTPModify_ONT has been created'	
