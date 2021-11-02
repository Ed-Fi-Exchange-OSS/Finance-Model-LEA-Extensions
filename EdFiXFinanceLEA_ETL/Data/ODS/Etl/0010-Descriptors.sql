/*
  Infrequent processing to load custom SFUSD descriptors for the modified, Ed-Fi Finance extension model for LEA's.
  Implementation Notes: Before running in your environment, 
    - replace 'uri://sfusd.edu/' in all descriptor Namespace values to match your local Namespace definition
	- replace the source edfixfinance.SFU_BSR_ROSTER for staff job classification data to your local data source.
    
*/

GO

/* Merge StaffClassificationDescriptor */
BEGIN TRANSACTION;

DECLARE @Namespace NVARCHAR(255) = 'uri://sfusd.edu/StaffClassificationDescriptor';

MERGE
  edfi.Descriptor AS target
USING (
  
  SELECT
    @Namespace [Namespace],
    RTRIM(JOBCODE) CodeValue,
    ISNULL(RTRIM(MIN(TITLE)),'') ShortDescription,
	RTRIM(MIN(TITLE)) [Description]
  FROM 
    edfixfinance.SFU_BSR_ROSTER
  WHERE
    LEN(JOBCODE) > 0
  GROUP BY 
    JOBCODE
  
  ) source 
  ON source.[Namespace] = target.[Namespace]
    AND source.CodeValue = target.CodeValue
WHEN MATCHED THEN
  UPDATE 
    SET target.ShortDescription = source.ShortDescription,
	  target.[Description] = source.[Description]
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    [Namespace],
	CodeValue,
	ShortDescription,
	[Description]
	) VALUES (
	source.[Namespace],
	source.CodeValue,
	source.ShortDescription,
	source.[Description]
	);

MERGE
  edfi.StaffClassificationDescriptor AS target
  USING (
    SELECT
	  DescriptorId StaffClassificationDescriptorId
	FROM
	  edfi.Descriptor
	WHERE
	  [Namespace] = @Namespace
  ) source 
  ON source.StaffClassificationDescriptorId = target.StaffClassificationDescriptorId
WHEN NOT MATCHED BY TARGET THEN
  INSERT (
    StaffClassificationDescriptorId
	) VALUES (
	source.StaffClassificationDescriptorId
	);

COMMIT TRANSACTION;

PRINT @Namespace + ' added.';
GO
