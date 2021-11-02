/*
  Bootstrap SQL script to create synonyms for the linked server connection strings, referenced in the ETL process scripts.
  For the SFUSD implementation, the connection strings include linked servers in addition to the tables and views that are PeopleSoft-specific. The server references have been removed here.
  Implementation Note: Before running in your environment, replace/modify the connection strings to match those of your local source tables and views.
*/

GO

CREATE SYNONYM edfixfinance.PS_CHARTFIELD1_TBL FOR dbo.PS_CHARTFIELD1_TBL;
CREATE SYNONYM edfixfinance.PS_CHARTFIELD2_TBL FOR dbo.PS_CHARTFIELD2_TBL;
CREATE SYNONYM edfixfinance.PS_CLASS_CF_TBL FOR dbo.PS_CLASS_CF_TBL;
CREATE SYNONYM edfixfinance.PS_DEPT_TBL FOR dbo.PS_DEPT_TBL;
CREATE SYNONYM edfixfinance.PS_FUND_TBL FOR dbo.PS_FUND_TBL;
CREATE SYNONYM edfixfinance.PS_GL_ACCOUNT_TBL FOR dbo.PS_GL_ACCOUNT_TBL;
CREATE SYNONYM edfixfinance.PS_KK_ACTIVITY_LOG FOR dbo.PS_KK_ACTIVITY_LOG;
CREATE SYNONYM edfixfinance.PS_KK_SOURCE_HDR FOR dbo.PS_KK_SOURCE_HDR;
CREATE SYNONYM edfixfinance.PS_KK_TRANS_LOG FOR dbo.PS_KK_TRANS_LOG;
CREATE SYNONYM edfixfinance.PS_LEDGER FOR dbo.PS_LEDGER;
CREATE SYNONYM edfixfinance.PS_LEDGER_BUDG FOR dbo.PS_LEDGER_BUDG;
CREATE SYNONYM edfixfinance.PS_PO_HDR FOR dbo.PS_PO_HDR;
CREATE SYNONYM edfixfinance.PS_VENDOR FOR dbo.PS_VENDOR;
CREATE SYNONYM edfixfinance.SFU_BSR_ROSTER FOR dbo.SFU_BSR_ROSTER;
GO
