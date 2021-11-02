Finance Extension SQL-based ETL Deployment Recommendations
----------------------------------------------------------

There are four (4) SQL scripts under source control which comprise the Finance LEA extension extract transform, load (ETL) processing.  

These are Bootstrap of SQL database object synonyms creation:
    Ed-Fi-ODS-Implementation\Application\EdFi.Ods.Extensions.EdFiXFinance\Artifacts\MsSql\Structure\Ods\Etl\1010-EXTENSION-EdFiXFinance-Synonyms.sql
and synonym dependant,
    descriptors ETL:  Ed-Fi-ODS-Implementation\Application\EdFi.Ods.Extensions.EdFiXFinance\Artifacts\MsSql\Data\Ods\Etl\0010-Descriptors.sql
    fiscal year initialization ETL:  Ed-Fi-ODS-Implementation\Application\EdFi.Ods.Extensions.EdFiXFinance\Artifacts\MsSql\Data\Ods\Etl\1000-EdFiXFinance-Initalize.sql
    and regular ETL:  Ed-Fi-ODS-Implementation\Application\EdFi.Ods.Extensions.EdFiXFinance\Artifacts\MsSql\Data\Ods\Etl\1100-EdFiXFinance-Merge.sql

The processing of the above scripts can be assumed to comprise 3 modes of operation, namely:
    *Bootstrap* - run once, initially, for each Ed-Fi ODS instance
    *Infrequent* - run periodically, for each Ed-Fi ODS instance (e.g., once per fiscal year and/or new job codes are defined in the source system)
    *Frequent* - run at the period of acceptable latency of data (e.g., daily)

To achieve the desired effect, it is recommended to create 3 jobs in the ODS local SQL Server Agent which correspond to each of the 3 modes mentioned above. This will allow the scheduling of each to be configured accordingly.

For the *Bootstrap* job an execution step for logic of the "SQL database object synonyms creation" script should be inlined.  This job should not be scheduled.
For the *Infrequent* job an execution step for logic of the "descriptors ETL" script should be inlined. A follow-on execution step for logic of the "fiscal year initialization ETL" script should be inlined.
For the *Frequent* job an execution step for logic of the "regular ETL" script should be inlined.  This job should be scheduled, perhaps to run daily.


Implementation Notes Outside of SFUSD:
For community members that would like to implement this ETL process, a few modifications are required. The following is a breakdown of modification recommendations per script:

1010-EXTENSION-EdFiXFinance-Synonyms.sql
This script creates synonyms to act as symbolic names for SFUSD's linked server connection strings. These are entirely implementation-specific and will need to be modified before use to match connection strings to local source tables and views in PeopleSoft.

0010-Descriptors.sql
This script loads locally-defined StaffCharacteristicDescriptors from SFUSD's staff roster. Two modifications are required here: 
    1. The source table should be modified to match the local source table for such values.
    2. The Namespace should be modified to match the local Namespace value.

1000-EdFiXFinance-Initalize.sql
This script initializes the fiscal year and Local Education Agency information. Before running locally, modify the FiscalYear (line 12) to match your desired fiscal year and the LEA Id (line 15) to match your organization's Local Education Agency identifier in Ed-Fi.

1100-EdFiXFinance-Merge.sql
This script pulls in and updates the remaining financial data from the PeopleSoft source system. All source tables and views should be confirmed to follow the same structure used in SFUSD's implementation. Where there are discrepancies, the code will need to be modified.
