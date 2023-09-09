# DataWharf - Upcoming fixes, changes and enhancements

## Short Term Fixes and todos
- Refactor Project APIs to use API Token access rights settings. Already validates a Token to the Endpoint exists.
- Setup and use table "IndexColumn".
- Forbid to change CustomField.Used once related values are present.
- Implement AWS iam authentication method for Data Dictionary Deployments.

## Pending Development
- See MIGRATIONSCRIPT in source code
- In Table Search, if Tags are available add "And/Or" option to be used in case of multiple tags.
- Load in table IndexColumn during structure imports.
- Load/Sync support to MySQL. In progress.
- During Load/Sync, only add entries or update entities with and "Usage Status" of "Unknown".
- During Load/Sync, report what changed.
- Allow to compare only data structure during Load/Sync.
- Custom fields for Enumerations and Enum Values.
- After a Search on tables show in a different color what was found in Name and Description fields.
- On Load/Sync process pseudo enum fields (Non native SQL Enums).
- Add support to Flags at the level of Columns.
- Progress Bar for documentation level of completion.
- In Data dictionaries have total counts of tables, name spaces, columns ...

## Conceptual Modeling
- Mapping of Model Entities, Properties and Associations to actual Tables and Columns

## Allow for an application to be viewable without user login
- Add support to flag type of information to be publish publicly.
- Implement public viewing.

## Documentation
- Installation notes and how to setup initial users.

## Visualization
- Auto Align tables or multi-select align.
- At the level of diagrams add settings to not show certain fields like pk, fk_*, created_by ....
- Free form navigation diagram. Specify a starting table, then navigate throughout the network of tables.

## Intra Application Mapping
- Allow to map tables and columns across application. In Progress.
- Add support in Visualization for cross application mapping.
- Auto-Predict option on Table and Column name matching, with "Soundex" or "Edit Distance" logic. Option will require user approval.

## Migrations
- Generate Migration scripts again a specific installed database.

## Export / Import
- Export entire application meta data and allow to import in another instance.
- Support for JSON imports/exports. Specifications to be defined.
- During Data migrations, (hb_orm) also setup constraints on foreign keys

## Management of Indexes
- Complete management of indexes.

## Management of Versions
- Allow to register new structure versions and link schema changes.

## Request for Schema Change Management
- Allow logged in users to request a schema change. 
- Map to change logs if the request was implemented.

## Support for MSSQL
- Allow to load/Sync from MSSQL. In progress.
- Find out if any additional field types are needed for MSSQL.

## Support for other database servers/engines
- Research if other database like Snowflake, Apache Sparks should be implemented and required changes.

## Security
- Currently using SHA-512 with Salt. Add support to bcrypt (Pending Harbour_ORM).
- Single Sign On like SAML, Okta.
- 2FA with google authenticator.

## Data Integrity Management
- Allow to define business rules for data integrity.
- Management of data test runs.
- Integrity Testing Agents.
