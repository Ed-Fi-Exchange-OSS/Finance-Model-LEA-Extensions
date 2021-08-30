/*
  Bootstrap SQL script to create synonyms for the linked server connection strings, referenced in the ETL process scripts.
  The connection strings reference linked servers (e.g., [NOC-FSTDA01].[FMS91TST]) that are SFUSD-specific and tables and views (e.g., dbo.PS_CHARTFIELD1_TBL) that are PeopleSoft-specific.
  Implementation Note: Before running in your environment, replace SFUSD connection strings to match those of your local source tables and views.
*/

GO

CREATE SYNONYM edfixfinance.PS_CHARTFIELD1_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_CHARTFIELD1_TBL;
CREATE SYNONYM edfixfinance.PS_CHARTFIELD2_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_CHARTFIELD2_TBL;
CREATE SYNONYM edfixfinance.PS_CLASS_CF_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_CLASS_CF_TBL;
CREATE SYNONYM edfixfinance.PS_DEPT_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_DEPT_TBL;
CREATE SYNONYM edfixfinance.PS_FUND_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_FUND_TBL;
CREATE SYNONYM edfixfinance.PS_GL_ACCOUNT_TBL FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_GL_ACCOUNT_TBL;
CREATE SYNONYM edfixfinance.PS_KK_ACTIVITY_LOG FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_KK_ACTIVITY_LOG;
CREATE SYNONYM edfixfinance.PS_KK_SOURCE_HDR FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_KK_SOURCE_HDR;
CREATE SYNONYM edfixfinance.PS_KK_TRANS_LOG FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_KK_TRANS_LOG;
CREATE SYNONYM edfixfinance.PS_LEDGER FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_LEDGER;
CREATE SYNONYM edfixfinance.PS_LEDGER_BUDG FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_LEDGER_BUDG;
CREATE SYNONYM edfixfinance.PS_PO_HDR FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_PO_HDR;
CREATE SYNONYM edfixfinance.PS_VENDOR FOR [NOC-FSTDA01].[FMS91TST].dbo.PS_VENDOR;
CREATE SYNONYM edfixfinance.SFU_BSR_ROSTER FOR [NOC-SSRSPA02].DODM.dbo.SFU_BSR_ROSTER;
GO
