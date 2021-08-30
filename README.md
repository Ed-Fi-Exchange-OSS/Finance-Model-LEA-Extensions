# Finance-Model-LEA-Extensions

The SFUSD Finance extension model is based on the Ed-Fi X Finance extension model (https://techdocs.ed-fi.org/display/EFDSRFC/ED-FI+RFC+18+-+FINANCE+API).  SFUSD has taken this as a starting point and expanded the extension model to allow for LEA-specific use cases.

Included artifacts:
  Documentation of use cases, UML diagrams, and a glossary of terms
  MetaEd extension files
  ETL scripts used by SFUSD to move data from their finance source system, PeopleSoft, into the new Ed-Fi Finance extension model

An additional README is provided for the ETL scripts to give additional context and suggest modifications for local implementation.

Directions to deploy the extension model follow the same process as defined in Ed-Fi techdocs: https://techdocs.ed-fi.org/pages/viewpage.action?pageId=83798983.

Notes on Ed-Fi Versions:
For the SFUSD deployment, the Ed-Fi model did not include FullTimeEquivalency on StaffEducationOrganizationAssignmentAssociation.  As of Ed-Fi Data Standard v3.3-b and Ed-Fi ODS/API v5.3, this is now included in the core model.  For implementations running on this version or later, remove the FullTimeEquivalency extension on SEOAA before deploying.
The link provided above to deploy the extension model is for the latest (as of publication of this document) Ed-Fi ODS/API release.  Each active version of the Ed-Fi ODS/API will contain the same or similar documentation for extensions.  The Ed-Fi Technology Version Matrix provides links to these: https://techdocs.ed-fi.org/display/ETKB/Ed-Fi+Technology+Version+Index.


## Legal Information

Copyright (c) 2021 Ed-Fi Alliance, LLC and contributors.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

See [NOTICES](NOTICES.md) for additional copyright and license notifications.

