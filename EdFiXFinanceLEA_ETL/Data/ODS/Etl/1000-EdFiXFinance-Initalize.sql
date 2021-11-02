/*
  Infrequent (eg, pre fiscal year) merge processing if EdFiXFinance extension
  Be advised that the collation of the source system is *_BIN, that is case-sensitive binary
  Implementation Note: Before running in your environment, replace the LEA Id (line 15) with your LocalEducationAgency Ed-Fi identifier.
*/

GO

/* Parameters: */

/* Fiscal Year to initialize */
DECLARE @FiscalYear INT = 2021,

/* Ed-Fi Org ID for LEA */
  @MyLocalEducationAgencyId INT = 255901
  ;



SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--BEGIN TRANSACTION;

IF NOT EXISTS (
  SELECT 1 FROM edfi.LocalEducationAgency 
  WHERE LocalEducationAgencyId = @MyLocalEducationAgencyId
  ) BEGIN
  
  RAISERROR ('LocalEducationAgency (%d) does not exist.',17,1,@MyLocalEducationAgencyId);

  END;

/* Merge LocalEducationAgency */
RAISERROR('Loading LocalEducationAgency...',0,0) WITH NOWAIT;

MERGE
  edfi.EducationOrganization AS target
  USING (
    SELECT
	  TRY_CAST(DEPTID AS INT) EducationOrganizationId,
	  DESCR NameOfInstitution
	FROM
	  edfixfinance.PS_DEPT_TBL
	WHERE
	  EFF_STATUS = 'A' /* Active */
	  AND TRY_CAST(DEPTID AS INT) BETWEEN 1 AND 999
	  AND LEN(DEPTID) = 3
	  AND EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_DEPT_TBL _this 
		WHERE _this.DEPTID = PS_DEPT_TBL.DEPTID
		)
  ) source 
  ON source.EducationOrganizationId = target.EducationOrganizationId
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    EducationOrganizationId,
	NameOfInstitution,
	Discriminator
	) VALUES (
	source.EducationOrganizationId,
	source.NameOfInstitution,
	'edfi.LocalEducationAgency'
	);

MERGE
  edfi.LocalEducationAgency AS target
  USING (
    SELECT
	  EducationOrganizationId LocalEducationAgencyId,
	  ParentLocalEducationAgency.LocalEducationAgencyCategoryDescriptorId,
	  ParentLocalEducationAgency.ParentLocalEducationAgencyId
	FROM
	  edfi.EducationOrganization
	  OUTER APPLY (
	    SELECT TOP 1 
		  LocalEducationAgencyCategoryDescriptorId,
		  @MyLocalEducationAgencyId ParentLocalEducationAgencyId
		FROM
		  edfi.LocalEducationAgency
		WHERE
		  LocalEducationAgencyId = @MyLocalEducationAgencyId
		) ParentLocalEducationAgency
	WHERE
	  Discriminator = 'edfi.LocalEducationAgency'
  ) source 
  ON source.LocalEducationAgencyId = target.LocalEducationAgencyId
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    LocalEducationAgencyId,
	LocalEducationAgencyCategoryDescriptorId,
	ParentLocalEducationAgencyId
	) VALUES (
	source.LocalEducationAgencyId,
	source.LocalEducationAgencyCategoryDescriptorId,
	source.ParentLocalEducationAgencyId
	);


/* Merge FunctionDimension */
RAISERROR('Loading FunctionDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.FunctionDimension AS target
  USING (
    SELECT
	  CLASS_FLD Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_CLASS_CF_TBL
	WHERE
	  EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_CLASS_CF_TBL _this 
		WHERE _this.CLASS_FLD = PS_CLASS_CF_TBL.CLASS_FLD
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);


/* Merge FundDimension */
RAISERROR('Loading FundDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.FundDimension AS target
  USING (
    SELECT
	  FUND_CODE Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_FUND_TBL
	WHERE
	  TRY_CAST(FUND_CODE AS INT) BETWEEN 1 AND 99
	  AND EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_FUND_TBL _this 
		WHERE _this.FUND_CODE = PS_FUND_TBL.FUND_CODE
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);
	

/* Merge ObjectDimension */
RAISERROR('Loading ObjectDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.ObjectDimension AS target
  USING (
    SELECT
	  ACCOUNT Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_GL_ACCOUNT_TBL
	WHERE
	  TRY_CAST(ACCOUNT AS INT) BETWEEN 0 AND 9999
	  AND EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_GL_ACCOUNT_TBL _this 
		WHERE _this.ACCOUNT = PS_GL_ACCOUNT_TBL.ACCOUNT
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);
	

/* Merge OperationalUnitDimension */
RAISERROR('Loading OperationalUnitDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.OperationalUnitDimension AS target
  USING (
    SELECT
	  DEPTID Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS COLLATE SQL_Latin1_General_CP1_CI_AS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_DEPT_TBL
	WHERE
	  TRY_CAST(DEPTID AS INT) BETWEEN 1 AND 999
	  AND EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_DEPT_TBL _this 
		WHERE _this.DEPTID = PS_DEPT_TBL.DEPTID
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS<> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);

	
/* Merge ProgramDimension */
RAISERROR('Loading ProgramDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.ProgramDimension AS target
  USING (
    SELECT
	  CHARTFIELD2 Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_CHARTFIELD2_TBL
	WHERE
	  EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_CHARTFIELD2_TBL _this 
		WHERE _this.CHARTFIELD2 = PS_CHARTFIELD2_TBL.CHARTFIELD2
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);


/* Merge SourceDimension */
RAISERROR('Loading SourceDimension...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.SourceDimension AS target
  USING (
    SELECT
	  CHARTFIELD1 Code,
	  @FiscalYear FiscalYear,
	  DESCR CodeName,
	  CASE EFF_STATUS WHEN 'A' THEN 0 WHEN 'I' THEN 1 ELSE NULL END IsObsolete 
	FROM
	  edfixfinance.PS_CHARTFIELD1_TBL
	WHERE
	  EFFDT = (
		SELECT MAX(_this.EFFDT) FROM edfixfinance.PS_CHARTFIELD1_TBL _this 
		WHERE _this.CHARTFIELD1 = PS_CHARTFIELD1_TBL.CHARTFIELD1
		)
  ) source 
  ON source.Code COLLATE SQL_Latin1_General_CP1_CI_AS = target.Code
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.CodeName 
  OR source.CodeName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.CodeName IS NULL
  OR source.IsObsolete <> target.IsObsolete
  OR source.IsObsolete IS NOT NULL AND target.IsObsolete IS NULL
  ) THEN
  UPDATE
    SET target.CodeName = source.CodeName,
	  target.IsObsolete = source.IsObsolete
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    Code,
	FiscalYear,
	CodeName,
	IsObsolete
	) VALUES (
	source.Code,
	source.FiscalYear,
	source.CodeName,
	source.IsObsolete
	);


/* Merge ChartOfAccount */
RAISERROR('Loading ChartOfAccount...',0,0) WITH NOWAIT;

/* Note: ACOUNT - 1000-7999 is Expenditure, 8000-8999 is Revenue, 9000-9999 is Balance Sheet */
DECLARE @ExpenditureAccountTypeDescriptorId INT = (
	SELECT DescriptorId
	FROM edfi.Descriptor
	WHERE [Namespace]='uri://sfusd.edu/AccountTypeDescriptor' AND CodeValue='Expenditure'
	);

MERGE
  edfixfinance.ChartOfAccount AS target
  USING (
  
    SELECT 
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) AccountIdentifier, 
	  TRY_CAST(DEPTID AS INT) EducationOrganizationId, 
	  @FiscalYear FiscalYear,
	  @ExpenditureAccountTypeDescriptorId AccountTypeDescriptorId,
	  ACCOUNT AccountName,
	  NULL BalanceSheetCode,
	  CLASS_FLD FunctionCode,
	  FUND_CODE FundCode,
	  ACCOUNT ObjectCode,
	  DEPTID OperationalUnitCode,
	  CHARTFIELD2 ProgramCode,
	  NULL ProjectCode,
	  CHARTFIELD1 SourceCode
	FROM (
	  SELECT 
		ACCOUNT,
		CLASS_FLD,
		FUND_CODE,
		DEPTID,
		CHARTFIELD2,
		CHARTFIELD1,
		BUDGET_REF
	  FROM 
	    edfixfinance.PS_LEDGER_BUDG
	  WHERE 
	    LEDGER = 'STD_BUDG'
	    AND TRY_CAST(FISCAL_YEAR AS INT) = @FiscalYear 
	    AND TRY_CAST(ACCOUNTING_PERIOD AS INT) <= 12 
	    AND TRY_CAST(ACCOUNT AS INT) < 8000
	    AND TRY_CAST(DEPTID AS INT) BETWEEN 1 AND 999
		AND TRY_CAST(FUND_CODE AS INT) BETWEEN 1 AND 99
	    AND LEN(DEPTID) = 3
		
	  UNION 
	  SELECT 
	    ACCOUNT,
	    CLASS_FLD,
	    FUND_CODE,
	    DEPTID,
	    CHARTFIELD2,
	    CHARTFIELD1,
		BUDGET_REF
	  FROM 
	    edfixfinance.PS_LEDGER
	  WHERE 
	    LEDGER = 'ACTUALS' 
	    AND TRY_CAST(FISCAL_YEAR AS INT) = @FiscalYear 
	    AND TRY_CAST(ACCOUNTING_PERIOD AS INT) <= 12 
	    AND TRY_CAST(ACCOUNT AS INT) < 8000
	    AND TRY_CAST(DEPTID AS INT) BETWEEN 1 AND 999
		AND TRY_CAST(FUND_CODE AS INT) BETWEEN 1 AND 99
	    AND LEN(DEPTID) = 3
	) _pre
	  
  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.AccountTypeDescriptorId <> target.AccountTypeDescriptorId 
  OR source.AccountName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.AccountName
  OR source.AccountName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.AccountName IS NULL
  OR source.FunctionCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.FunctionCode
  OR source.FunctionCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.FunctionCode IS NULL
  OR source.FundCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.FundCode
  OR source.FundCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.FundCode IS NULL
  OR source.ObjectCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.ObjectCode
  OR source.ObjectCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.ObjectCode IS NULL
  OR source.OperationalUnitCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.OperationalUnitCode
  OR source.OperationalUnitCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.OperationalUnitCode IS NULL
  OR source.ProgramCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.ProgramCode
  OR source.ProgramCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.ProgramCode IS NULL
  OR source.SourceCode COLLATE SQL_Latin1_General_CP1_CI_AS <> target.SourceCode
  OR source.SourceCode COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.SourceCode IS NULL
  ) THEN
  UPDATE
    SET target.AccountTypeDescriptorId = source.AccountTypeDescriptorId,
      target.AccountName = source.AccountName,
      target.FunctionCode = source.FunctionCode,
      target.FundCode = source.FundCode,
      target.ObjectCode = source.ObjectCode,
      target.OperationalUnitCode = source.OperationalUnitCode,
      target.ProgramCode = source.ProgramCode,
      target.SourceCode = source.SourceCode
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    AccountIdentifier,
	EducationOrganizationId,
	FiscalYear,
	AccountTypeDescriptorId,
	AccountName,
	BalanceSheetCode,
	FunctionCode,
	FundCode,
	ObjectCode,
	OperationalUnitCode,
	ProgramCode,
	ProjectCode,
	SourceCode
	) VALUES (
	source.AccountIdentifier,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.AccountTypeDescriptorId,
	source.AccountName,
	source.BalanceSheetCode,
	source.FunctionCode,
	source.FundCode,
	source.ObjectCode,
	source.OperationalUnitCode,
	source.ProgramCode,
	source.ProjectCode,
	source.SourceCode
	);

--COMMIT TRANSACTION;
GO
