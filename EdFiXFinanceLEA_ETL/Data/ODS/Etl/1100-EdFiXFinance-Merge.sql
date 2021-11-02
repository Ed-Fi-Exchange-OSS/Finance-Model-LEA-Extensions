/*
  Frequent (eg, daily) merge processing if EdFiXFinance extension
*/

GO

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--BEGIN TRANSACTION;

  /* Parameters */
DECLARE
  @FiscalYear INT = 2021;
  

/* Staff. 
  we are only inserting for possible discrepancies not currently in the 
  SIS vendor's integration. We anticipate any records inserted were will 
  be updated by same SIS vendor */
RAISERROR('Loading Staff...',0,0) WITH NOWAIT;

MERGE
  edfi.Staff AS target
  USING (

  SELECT
    RTRIM(SFU_BSR_ROSTER.EMPLID) StaffUniqueId, 
    ISNULL( 
	  SUBSTRING( 
	    RTRIM(MIN(SFU_BSR_ROSTER.[NAME])), 
		CHARINDEX(',',RTRIM(MIN(SFU_BSR_ROSTER.[NAME])))+1
		,75
		),
	  '') FirstName,
	ISNULL(
	  LEFT(
	    RTRIM(MIN(SFU_BSR_ROSTER.[NAME])),
		CHARINDEX(',',RTRIM(MIN(SFU_BSR_ROSTER.[NAME])))-1
		)
	  ,'') LastSurname
  FROM 
    edfixfinance.SFU_BSR_ROSTER
  WHERE
    LEN(SFU_BSR_ROSTER.EMPLID) > 0
  GROUP BY 
    RTRIM(SFU_BSR_ROSTER.EMPLID)

  ) source 
  ON source.StaffUniqueId COLLATE SQL_Latin1_General_CP1_CI_AS = target.StaffUniqueId
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
	StaffUniqueId,
	FirstName,
	LastSurname
	) VALUES (
	source.StaffUniqueId,
	source.FirstName,
	source.LastSurname
	);


/* Local Account */
RAISERROR('Loading LocalAccount...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.LocalAccount AS target
  USING (
    SELECT 
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) AccountIdentifier, 
	  TRY_CAST(DEPTID AS INT) EducationOrganizationId, 
	  @FiscalYear FiscalYear,
	  RTRIM(ACCOUNT) AccountName,
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) ChartOfAccountIdentifier, 
	  TRY_CAST(DEPTID AS INT) ChartOfAccountEducationOrganizationId

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
  source.AccountName COLLATE SQL_Latin1_General_CP1_CI_AS <> target.AccountName
  OR source.AccountName COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.AccountName IS NULL
  OR source.ChartOfAccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS <> target.ChartOfAccountIdentifier
  OR source.ChartOfAccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS IS NOT NULL AND target.ChartOfAccountIdentifier IS NULL
  OR source.ChartOfAccountEducationOrganizationId <> target.ChartOfAccountEducationOrganizationId
  OR source.ChartOfAccountEducationOrganizationId IS NOT NULL AND target.ChartOfAccountEducationOrganizationId IS NULL

  ) THEN
  UPDATE
    SET 
      target.AccountName = source.AccountName,
      target.ChartOfAccountIdentifier = source.ChartOfAccountIdentifier,
      target.ChartOfAccountEducationOrganizationId = source.ChartOfAccountEducationOrganizationId
WHEN NOT MATCHED BY TARGET AND 
  EXISTS (
    SELECT 1 FROM edfixfinance.ChartOfAccount
	WHERE 
	  ChartOfAccount.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = source.AccountIdentifier
	  AND ChartOfAccount.EducationOrganizationId = source.EducationOrganizationId
	  AND ChartOfAccount.FiscalYear = source.FiscalYear
    ) THEN
  INSERT (
    AccountIdentifier,
	EducationOrganizationId,
	FiscalYear,
	AccountName,
	ChartOfAccountIdentifier,
	ChartOfAccountEducationOrganizationId
	) VALUES (
	source.AccountIdentifier,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.AccountName,
	source.ChartOfAccountIdentifier,
	source.ChartOfAccountEducationOrganizationId
	);


/* Encumbrance */
RAISERROR('Loading Encumbrance...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.Encumbrance AS target
  USING (

    SELECT 
	  RTRIM(PS_KK_ACTIVITY_LOG.FUND_CODE)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD1)+
	    RTRIM(PS_KK_ACTIVITY_LOG.BUDGET_REF)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD2)+
		RTRIM(PS_KK_ACTIVITY_LOG.CLASS_FLD)+RTRIM(PS_KK_ACTIVITY_LOG.DEPTID)+
		RTRIM(PS_KK_TRANS_LOG.ACCOUNT) AccountIdentifier, 
	  TRY_CAST(PS_KK_ACTIVITY_LOG.DEPTID AS INT) EducationOrganizationId, 
	  @FiscalYear FiscalYear,
	  TRY_CAST(PS_KK_ACTIVITY_LOG.ACCOUNTING_PERIOD AS INT) AccountingPeriod,
	  SUM(PS_KK_ACTIVITY_LOG.MONETARY_AMOUNT) Amount

	FROM 
	  edfixfinance.PS_KK_ACTIVITY_LOG

	  INNER JOIN 
	  edfixfinance.PS_KK_TRANS_LOG
	    ON PS_KK_ACTIVITY_LOG.KK_TRAN_ID = PS_KK_TRANS_LOG.KK_TRAN_ID 
		  AND PS_KK_ACTIVITY_LOG.KK_TRAN_DT = PS_KK_TRANS_LOG.KK_TRAN_DT 
		  AND PS_KK_ACTIVITY_LOG.KK_TRAN_LN = PS_KK_TRANS_LOG.KK_TRAN_LN 

	  INNER JOIN (
        SELECT 
		  KK_TRAN_ID,
		  KK_TRAN_DT,
		  KK_TRAN_LN,
	      MAX(SEQNBR) SEQNBR
	    FROM 
	      edfixfinance.PS_KK_TRANS_LOG 
	    GROUP BY
	      KK_TRAN_ID,
		  KK_TRAN_DT,
		  KK_TRAN_LN
	   ) _this ON _this.KK_TRAN_ID = PS_KK_ACTIVITY_LOG.KK_TRAN_ID 
		  AND _this.KK_TRAN_DT = PS_KK_ACTIVITY_LOG.KK_TRAN_DT 
		  AND _this.KK_TRAN_LN = PS_KK_ACTIVITY_LOG.KK_TRAN_LN
	      AND _this.SEQNBR = PS_KK_TRANS_LOG.SEQNBR
			  
	  INNER JOIN 
	  edfixfinance.PS_KK_SOURCE_HDR
	    ON PS_KK_SOURCE_HDR.KK_TRAN_ID = PS_KK_ACTIVITY_LOG.KK_TRAN_ID 
		  AND PS_KK_SOURCE_HDR.KK_TRAN_DT = PS_KK_ACTIVITY_LOG.KK_TRAN_DT 

	  LEFT JOIN 
	  edfixfinance.PS_PO_HDR
	    ON PS_KK_SOURCE_HDR.PO_ID = PS_PO_HDR.PO_ID 

	  LEFT JOIN 
	  edfixfinance.PS_VENDOR
	    ON PS_PO_HDR.VENDOR_ID = PS_VENDOR.VENDOR_ID 

    WHERE 
	  PS_KK_ACTIVITY_LOG.LEDGER = 'PROJ_GR_EN'
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.BUDGET_REF AS INT) = @FiscalYear
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.ACCOUNTING_PERIOD AS INT) <= 12 
	  AND TRY_CAST(PS_KK_TRANS_LOG.ACCOUNT AS INT) < 8000
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.DEPTID AS INT) BETWEEN 1 AND 999
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.FUND_CODE AS INT) BETWEEN 1 AND 99
	  AND LEN(PS_KK_ACTIVITY_LOG.DEPTID) = 3

	GROUP BY
	  RTRIM(PS_KK_ACTIVITY_LOG.FUND_CODE)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD1)+
	    RTRIM(PS_KK_ACTIVITY_LOG.BUDGET_REF)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD2)+
		RTRIM(PS_KK_ACTIVITY_LOG.CLASS_FLD)+RTRIM(PS_KK_ACTIVITY_LOG.DEPTID)+
		RTRIM(PS_KK_TRANS_LOG.ACCOUNT), 
	  TRY_CAST(PS_KK_ACTIVITY_LOG.DEPTID AS INT),
	  TRY_CAST(PS_KK_ACTIVITY_LOG.ACCOUNTING_PERIOD AS INT)

	HAVING
	  SUM(PS_KK_ACTIVITY_LOG.MONETARY_AMOUNT) IS NOT NULL
	  AND RTRIM(PS_KK_ACTIVITY_LOG.FUND_CODE)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD1)+
	    RTRIM(PS_KK_ACTIVITY_LOG.BUDGET_REF)+RTRIM(PS_KK_ACTIVITY_LOG.CHARTFIELD2)+
		RTRIM(PS_KK_ACTIVITY_LOG.CLASS_FLD)+RTRIM(PS_KK_ACTIVITY_LOG.DEPTID)+
		RTRIM(PS_KK_TRANS_LOG.ACCOUNT) IS NOT NULL
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.DEPTID AS INT) IS NOT NULL
	  AND TRY_CAST(PS_KK_ACTIVITY_LOG.ACCOUNTING_PERIOD AS INT) IS NOT NULL

  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.AccountingPeriod = target.AccountingPeriod
    AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.Amount <> target.Amount
  ) THEN
  UPDATE
    SET target.Amount = source.Amount
WHEN NOT MATCHED BY TARGET AND 
  EXISTS (
    SELECT 1 FROM edfixfinance.LocalAccount
	WHERE 
	  LocalAccount.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = source.AccountIdentifier
	  AND LocalAccount.EducationOrganizationId = source.EducationOrganizationId
	  AND LocalAccount.FiscalYear = source.FiscalYear
    ) THEN
  INSERT (
    AccountIdentifier,
	EducationOrganizationId,
	FiscalYear,
	AccountingPeriod,
	Amount
	) VALUES (
	source.AccountIdentifier,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.AccountingPeriod,
	source.Amount
	);
	

/* Local Actual */
RAISERROR('Loading LocalActual...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.LocalActual AS target
  USING (

    SELECT 
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) AccountIdentifier, 
	  TRY_CAST(DEPTID AS INT) EducationOrganizationId, 
	  @FiscalYear FiscalYear,
	  TRY_CAST(ACCOUNTING_PERIOD AS INT) AccountingPeriod,
	  SUM(POSTED_TOTAL_AMT) Amount
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
	GROUP BY
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT), 
	  TRY_CAST(DEPTID AS INT),
	  TRY_CAST(ACCOUNTING_PERIOD AS INT)
    HAVING
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) IS NOT NULL
	  AND TRY_CAST(DEPTID AS INT) IS NOT NULL
	  AND TRY_CAST(ACCOUNTING_PERIOD AS INT) IS NOT NULL

  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.AccountingPeriod = target.AccountingPeriod
    AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.Amount <> target.Amount
  ) THEN
  UPDATE
    SET target.Amount = source.Amount
WHEN NOT MATCHED BY TARGET AND 
  EXISTS (
    SELECT 1 FROM edfixfinance.LocalAccount
	WHERE 
	  LocalAccount.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = source.AccountIdentifier
	  AND LocalAccount.EducationOrganizationId = source.EducationOrganizationId
	  AND LocalAccount.FiscalYear = source.FiscalYear
    ) THEN
  INSERT (
    AccountIdentifier,
	EducationOrganizationId,
	FiscalYear,
	AccountingPeriod,
	Amount
	) VALUES (
	source.AccountIdentifier,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.AccountingPeriod,
	source.Amount
	);


/* Local Budget */
RAISERROR('Loading LocalBudget...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.LocalBudget AS target
  USING (
    SELECT 
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) AccountIdentifier, 
	  TRY_CAST(DEPTID AS INT) EducationOrganizationId, 
	  @FiscalYear FiscalYear,
	  TRY_CAST(ACCOUNTING_PERIOD AS INT) AccountingPeriod,
	  SUM(POSTED_TOTAL_AMT) Amount

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
	GROUP BY
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT), 
	  TRY_CAST(DEPTID AS INT),
	  TRY_CAST(ACCOUNTING_PERIOD AS INT)
    HAVING
	  RTRIM(FUND_CODE)+RTRIM(CHARTFIELD1)+RTRIM(BUDGET_REF)+
		RTRIM(CHARTFIELD2)+RTRIM(CLASS_FLD)+RTRIM(DEPTID)+RTRIM(ACCOUNT) IS NOT NULL
	  AND TRY_CAST(DEPTID AS INT) IS NOT NULL
	  AND TRY_CAST(ACCOUNTING_PERIOD AS INT) IS NOT NULL

  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.AccountingPeriod = target.AccountingPeriod
    AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.FiscalYear = target.FiscalYear
WHEN MATCHED AND (
  source.Amount <> target.Amount
  ) THEN
  UPDATE
    SET target.Amount = source.Amount
WHEN NOT MATCHED BY TARGET AND 
  EXISTS (
    SELECT 1 FROM edfixfinance.LocalAccount
	WHERE 
	  LocalAccount.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = source.AccountIdentifier
	  AND LocalAccount.EducationOrganizationId = source.EducationOrganizationId
	  AND LocalAccount.FiscalYear = source.FiscalYear
    ) THEN
  INSERT (
    AccountIdentifier,
	EducationOrganizationId,
	FiscalYear,
	AccountingPeriod,
	Amount
	) VALUES (
	source.AccountIdentifier,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.AccountingPeriod,
	source.Amount
	);


/* Position Managment */
RAISERROR('Loading PositionManagement...',0,0) WITH NOWAIT;

/* Because we are doing this over linked server,
   to provide additional isolation support, we 
   are using a key range (On version of the 
   remote SQL server there isn't certainty around 
   transaction isolation beyond read committed) */
DECLARE @consistent_range TABLE (
  PositionNumber NVARCHAR(16) NOT NULL,
  StaffClassificationDescriptorId INT NOT NULL,
  EducationOrganizationId INT NOT NULL,
  StaffUSI INT NULL
  UNIQUE (
    PositionNumber,
    StaffClassificationDescriptorId,
    EducationOrganizationId,
	StaffUSI
  )
);

INSERT @consistent_range
SELECT
  RTRIM(SFU_BSR_ROSTER.POSITION_NBR), 
  StaffClassificationDescriptor.DescriptorId,
  EducationOrganization.EducationOrganizationId,
  Staff.StaffUSI
FROM 
  edfixfinance.SFU_BSR_ROSTER
  INNER JOIN
  edfi.Descriptor StaffClassificationDescriptor
    ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'
  INNER JOIN
  edfi.EducationOrganization
    ON EducationOrganization.EducationOrganizationId = 
	  TRY_CAST(DEPTID AS INT)
  LEFT OUTER JOIN
  edfi.Staff
    ON Staff.StaffUniqueId = RTRIM(SFU_BSR_ROSTER.EMPLID)
GROUP BY 
  RTRIM(SFU_BSR_ROSTER.POSITION_NBR),
  StaffClassificationDescriptor.DescriptorId,
  EducationOrganization.EducationOrganizationId,
  Staff.StaffUSI
HAVING
  RTRIM(SFU_BSR_ROSTER.POSITION_NBR) IS NOT NULL;

DELETE 
FROM edfixfinance.LocalActualPositionManagementAssociation 
WHERE NOT EXISTS (
  SELECT 1 FROM @consistent_range _range 
  WHERE 
    LocalActualPositionManagementAssociation.PositionNumber = 
	  _range.PositionNumber
	AND LocalActualPositionManagementAssociation.StaffClassificationDescriptorId = 
	  _range.StaffClassificationDescriptorId
	AND LocalActualPositionManagementAssociation.EducationOrganizationId = 
	  _range.EducationOrganizationId
	);

DELETE 
FROM edfixfinance.LocalBudgetPositionManagementAssociation
WHERE NOT EXISTS (
  SELECT 1 FROM @consistent_range _range 
  WHERE 
    LocalBudgetPositionManagementAssociation.PositionNumber = 
	  _range.PositionNumber
	AND LocalBudgetPositionManagementAssociation.StaffClassificationDescriptorId = 
	  _range.StaffClassificationDescriptorId
	AND LocalBudgetPositionManagementAssociation.EducationOrganizationId = 
	  _range.EducationOrganizationId
	);

UPDATE 
  edfixfinance.StaffEducationOrganizationAssignmentAssociationExtension
    SET PositionNumber = NULL,
	  PositionStaffClassificationDescriptorId = NULL,
	  PositionEducationOrganizationId = NULL,
	  FullTimeEquivalency = NULL
WHERE
  NOT EXISTS (
    SELECT 1 FROM @consistent_range _range 
    WHERE 
      StaffEducationOrganizationAssignmentAssociationExtension.PositionNumber = 
	    _range.PositionNumber
	  AND StaffEducationOrganizationAssignmentAssociationExtension.PositionStaffClassificationDescriptorId = 
	  _range.StaffClassificationDescriptorId
	  AND StaffEducationOrganizationAssignmentAssociationExtension.PositionEducationOrganizationId = 
	  _range.EducationOrganizationId
	);

MERGE
  edfixfinance.PositionManagement AS target
  USING (

  SELECT
    RTRIM(SFU_BSR_ROSTER.POSITION_NBR) PositionNumber, 
    StaffClassificationDescriptor.DescriptorId StaffClassificationDescriptorId,
    TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT) EducationOrganizationId, 
    RTRIM(MIN(SFU_BSR_ROSTER.TITLE)) PositionTitle, 
    TRY_CAST( ROUND( SUM(TRY_CAST(SFU_BSR_ROSTER.FTE AS DECIMAL(6,3))) ,3) AS DECIMAL(6,3)) FullTimeEquivalency
  FROM 
    edfixfinance.SFU_BSR_ROSTER
	INNER JOIN
	edfi.Descriptor StaffClassificationDescriptor
	  ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'
    INNER JOIN
	@consistent_range _range 
    ON _range.PositionNumber = RTRIM(SFU_BSR_ROSTER.POSITION_NBR)
	  AND _range.StaffClassificationDescriptorId = 
	    StaffClassificationDescriptor.DescriptorId
	  AND _range.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)

  GROUP BY 
    RTRIM(SFU_BSR_ROSTER.POSITION_NBR),
	TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT),
    StaffClassificationDescriptor.DescriptorId

  ) source 
  ON source.PositionNumber COLLATE SQL_Latin1_General_CP1_CI_AS = target.PositionNumber
    AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
WHEN MATCHED AND (
  source.PositionTitle COLLATE SQL_Latin1_General_CP1_CI_AS <> target.PositionTitle
  OR source.PositionTitle IS NOT NULL AND target.PositionTitle IS NULL
  OR source.FullTimeEquivalency <> target.FullTimeEquivalency
  ) THEN
  UPDATE
    SET 
      target.PositionTitle = source.PositionTitle,
      target.FullTimeEquivalency = source.FullTimeEquivalency,
	  target.LastModifiedDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
	EducationOrganizationId,
	PositionNumber,
	StaffClassificationDescriptorId,
	PositionTitle,
	FullTimeEquivalency
	) VALUES (
	source.EducationOrganizationId,
	source.PositionNumber,
	source.StaffClassificationDescriptorId,
	source.PositionTitle,
	source.FullTimeEquivalency
	)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;


/* Local Actual Position Management Association */
RAISERROR('Loading LocalActualPositionManagementAssociation...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.LocalActualPositionManagementAssociation AS target
  USING (

  SELECT
    LocalActual.AccountIdentifier,
	LocalActual.AccountingPeriod,
	LocalActual.EducationOrganizationId,
	LocalActual.FiscalYear,
    PositionManagement.PositionNumber, 
    PositionManagement.StaffClassificationDescriptorId,
    TRY_CAST( 
	  ROUND( SUM(TRY_CAST(FTE AS DECIMAL(6,3))) ,3) 
	    AS DECIMAL(6,3)) FullTimeEquivalency
  FROM 
    edfixfinance.SFU_BSR_ROSTER
	INNER JOIN
	edfi.Descriptor StaffClassificationDescriptor
	  ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'
	INNER JOIN
	edfixfinance.LocalActual
	  ON LocalActual.AccountIdentifier = SFU_BSR_ROSTER.AccountIdentifier
	    AND LocalActual.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)
		
	INNER JOIN
	edfixfinance.PositionManagement
	  ON PositionManagement.PositionNumber = RTRIM(SFU_BSR_ROSTER.POSITION_NBR)
	  AND PositionManagement.StaffClassificationDescriptorId = 
	    StaffClassificationDescriptor.DescriptorId
	  AND PositionManagement.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)

    WHERE
	  LocalActual.FiscalYear = @FiscalYear

  GROUP BY 
    LocalActual.AccountIdentifier,
	LocalActual.AccountingPeriod,
	LocalActual.EducationOrganizationId,
	LocalActual.FiscalYear,
    PositionManagement.PositionNumber, 
    PositionManagement.StaffClassificationDescriptorId

  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.AccountingPeriod = target.AccountingPeriod
	AND source.EducationOrganizationId = target.EducationOrganizationId
	AND source.FiscalYear = target.FiscalYear
	AND source.PositionNumber COLLATE SQL_Latin1_General_CP1_CI_AS = target.PositionNumber
    AND source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
WHEN MATCHED AND (
  source.FullTimeEquivalency <> target.FullTimeEquivalency
  OR (source.FullTimeEquivalency IS NOT NULL AND target.FullTimeEquivalency IS NULL)
  ) THEN
  UPDATE
    SET
	  target.FullTimeEquivalency = source.FullTimeEquivalency,
	  target.LastModifiedDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    AccountIdentifier,
	AccountingPeriod,
	EducationOrganizationId,
	FiscalYear,
	PositionNumber,
	StaffClassificationDescriptorId,
	FullTimeEquivalency
	) VALUES (
	source.AccountIdentifier,
	source.AccountingPeriod,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.PositionNumber,
	source.StaffClassificationDescriptorId,
	source.FullTimeEquivalency
	)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;


/* Local Budget Position Management Association */
RAISERROR('Loading LocalBudgetPositionManagementAssociation...',0,0) WITH NOWAIT;

MERGE
  edfixfinance.LocalBudgetPositionManagementAssociation AS target
  USING (

  SELECT
    LocalBudget.AccountIdentifier,
	LocalBudget.AccountingPeriod,
	LocalBudget.EducationOrganizationId,
	LocalBudget.FiscalYear,
    PositionManagement.PositionNumber, 
    PositionManagement.StaffClassificationDescriptorId,
    TRY_CAST( 
	  ROUND( SUM(TRY_CAST(SFU_BSR_ROSTER.FTE AS DECIMAL(6,3))) ,3) 
	    AS DECIMAL(6,3)) FullTimeEquivalency
  FROM 
    edfixfinance.SFU_BSR_ROSTER
	INNER JOIN
	edfi.Descriptor StaffClassificationDescriptor
	  ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'
	INNER JOIN
	edfixfinance.LocalBudget
	  ON LocalBudget.AccountIdentifier = RTRIM(SFU_BSR_ROSTER.AccountIdentifier)
	    AND LocalBudget.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)
		
	INNER JOIN
	edfixfinance.PositionManagement
	  ON PositionManagement.PositionNumber = RTRIM(POSITION_NBR)
	  AND PositionManagement.StaffClassificationDescriptorId = 
	    StaffClassificationDescriptor.DescriptorId
	  AND PositionManagement.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)
  WHERE
   LocalBudget.FiscalYear = @FiscalYear

  GROUP BY 
    LocalBudget.AccountIdentifier,
	LocalBudget.AccountingPeriod,
	LocalBudget.EducationOrganizationId,
	LocalBudget.FiscalYear,
    PositionManagement.PositionNumber, 
    PositionManagement.StaffClassificationDescriptorId

  ) source 
  ON source.AccountIdentifier COLLATE SQL_Latin1_General_CP1_CI_AS = target.AccountIdentifier
    AND source.AccountingPeriod = target.AccountingPeriod
	AND source.EducationOrganizationId = target.EducationOrganizationId
	AND source.FiscalYear = target.FiscalYear
	AND source.PositionNumber COLLATE SQL_Latin1_General_CP1_CI_AS = target.PositionNumber
    AND source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
WHEN MATCHED AND (
  source.FullTimeEquivalency <> target.FullTimeEquivalency
  OR (source.FullTimeEquivalency IS NOT NULL AND target.FullTimeEquivalency IS NULL)
  ) THEN
  UPDATE
    SET
	  target.FullTimeEquivalency = source.FullTimeEquivalency,
	  target.LastModifiedDate = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    AccountIdentifier,
	AccountingPeriod,
	EducationOrganizationId,
	FiscalYear,
	PositionNumber,
	StaffClassificationDescriptorId,
	FullTimeEquivalency
	) VALUES (
	source.AccountIdentifier,
	source.AccountingPeriod,
	source.EducationOrganizationId,
	source.FiscalYear,
	source.PositionNumber,
	source.StaffClassificationDescriptorId,
	source.FullTimeEquivalency
	)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;


/* Staff Education OrganizationA ssignment Association */
RAISERROR('Loading StaffEducationOrganizationAssignmentAssociation...',0,0) WITH NOWAIT;

MERGE
  edfi.StaffEducationOrganizationAssignmentAssociation AS target
  USING (

  SELECT
    TRY_CAST(SFU_BSR_ROSTER.EFFDT AS DATE) BeginDate,
    PositionManagement.EducationOrganizationId,
    PositionManagement.StaffClassificationDescriptorId,
    Staff.StaffUSI

  FROM 
    edfixfinance.SFU_BSR_ROSTER

	INNER JOIN
	edfi.Descriptor StaffClassificationDescriptor
	  ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'

	INNER JOIN
	edfi.Staff
	  ON Staff.StaffUniqueId = RTRIM(SFU_BSR_ROSTER.EMPLID)
		
	INNER JOIN
	edfixfinance.PositionManagement
	  ON PositionManagement.PositionNumber = RTRIM(POSITION_NBR)
	  AND PositionManagement.StaffClassificationDescriptorId = 
	    StaffClassificationDescriptor.DescriptorId
	  AND PositionManagement.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)

  WHERE
    TRY_CAST(SFU_BSR_ROSTER.EFFDT AS DATE) IS NOT NULL
	AND EXISTS (
      SELECT 1 FROM @consistent_range _range 
      WHERE 
        PositionManagement.StaffClassificationDescriptorId = 
	      _range.StaffClassificationDescriptorId
	    AND PositionManagement.EducationOrganizationId = 
	     _range.EducationOrganizationId
		AND Staff.StaffUSI = 
	      _range.StaffUSI
	  )

  GROUP BY 
    TRY_CAST(SFU_BSR_ROSTER.EFFDT AS DATE),
    PositionManagement.EducationOrganizationId,
    PositionManagement.StaffClassificationDescriptorId,
    Staff.StaffUSI

  ) source 
  ON source.BeginDate = target.BeginDate
	AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
	AND source.StaffUSI = target.StaffUSI

WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    BeginDate,
	EducationOrganizationId,
	StaffClassificationDescriptorId,
	StaffUSI
	) VALUES (
	source.BeginDate,
	source.EducationOrganizationId,
	source.StaffClassificationDescriptorId,
	source.StaffUSI
	);

MERGE
  edfixfinance.StaffEducationOrganizationAssignmentAssociationExtension AS target
  USING edfi.StaffEducationOrganizationAssignmentAssociation source 
  ON source.BeginDate = target.BeginDate
	AND source.EducationOrganizationId = target.EducationOrganizationId
    AND source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
	AND source.StaffUSI = target.StaffUSI

WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    BeginDate,
	EducationOrganizationId,
	StaffClassificationDescriptorId,
	StaffUSI
	) VALUES (
	source.BeginDate,
	source.EducationOrganizationId,
	source.StaffClassificationDescriptorId,
	source.StaffUSI
	);

UPDATE
  edfixfinance.StaffEducationOrganizationAssignmentAssociationExtension
  SET PositionNumber = _rollup.PositionNumber,
    PositionEducationOrganizationId = _rollup.EducationOrganizationId,
	PositionStaffClassificationDescriptorId = _rollup.StaffClassificationDescriptorId,
	FullTimeEquivalency = _rollup.FullTimeEquivalency
FROM
  edfixfinance.StaffEducationOrganizationAssignmentAssociationExtension
  INNER JOIN (

  SELECT
    StaffEducationOrganizationAssignmentAssociation.BeginDate,
    StaffEducationOrganizationAssignmentAssociation.EducationOrganizationId,
    StaffEducationOrganizationAssignmentAssociation.StaffClassificationDescriptorId,
    StaffEducationOrganizationAssignmentAssociation.StaffUSI,
	PositionManagement.PositionNumber,
    TRY_CAST( 
	  ROUND( SUM(TRY_CAST(SFU_BSR_ROSTER.FTE AS DECIMAL(6,3))) ,3) 
	    AS DECIMAL(6,3)) FullTimeEquivalency
  FROM 
    edfixfinance.SFU_BSR_ROSTER

	INNER JOIN
	edfi.Descriptor StaffClassificationDescriptor
	  ON StaffClassificationDescriptor.CodeValue = RTRIM(SFU_BSR_ROSTER.JOBCODE)
	  AND StaffClassificationDescriptor.[Namespace] = 
	    'uri://sfusd.edu/StaffClassificationDescriptor'

	INNER JOIN
	edfi.Staff
	  ON Staff.StaffUniqueId = RTRIM(SFU_BSR_ROSTER.EMPLID)

	INNER JOIN
	edfixfinance.PositionManagement
	  ON PositionManagement.PositionNumber = RTRIM(POSITION_NBR)
	  AND PositionManagement.StaffClassificationDescriptorId = 
	    StaffClassificationDescriptor.DescriptorId
	  AND PositionManagement.EducationOrganizationId = TRY_CAST(SFU_BSR_ROSTER.DEPTID AS INT)

	INNER JOIN
	edfi.StaffEducationOrganizationAssignmentAssociation
	  ON StaffEducationOrganizationAssignmentAssociation.BeginDate = TRY_CAST(SFU_BSR_ROSTER.EFFDT AS DATE)
	    AND StaffEducationOrganizationAssignmentAssociation.EducationOrganizationId = PositionManagement.EducationOrganizationId
		AND StaffEducationOrganizationAssignmentAssociation.StaffClassificationDescriptorId = PositionManagement.StaffClassificationDescriptorId
	    AND StaffEducationOrganizationAssignmentAssociation.StaffUSI = Staff.StaffUSI

  GROUP BY 
    StaffEducationOrganizationAssignmentAssociation.BeginDate,
    StaffEducationOrganizationAssignmentAssociation.EducationOrganizationId,
    StaffEducationOrganizationAssignmentAssociation.StaffClassificationDescriptorId,
    StaffEducationOrganizationAssignmentAssociation.StaffUSI,
	PositionManagement.PositionNumber

  ) _rollup
  ON _rollup.BeginDate = StaffEducationOrganizationAssignmentAssociationExtension.BeginDate
	AND _rollup.EducationOrganizationId = 
	  StaffEducationOrganizationAssignmentAssociationExtension.EducationOrganizationId
    AND _rollup.StaffClassificationDescriptorId = 
	  StaffEducationOrganizationAssignmentAssociationExtension.StaffClassificationDescriptorId
	AND _rollup.StaffUSI = StaffEducationOrganizationAssignmentAssociationExtension.StaffUSI


--COMMIT TRANSACTION;
GO
