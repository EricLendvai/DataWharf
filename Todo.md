# DataWharf - Upcoming fixes, changes and enhancements

## Short Term Fixes
- Finish setup of User Security Global and Application Restrictions. Currently all users have full access. In progress.
- Forbid to change CustomField.UsedOn once related values are present.

## Pending Development
- Load in table IndexColumn during structure imports.
- Load/Sync support to MySQL.
- During Load/Sync, only add entries or update entities with and "Usage Status" of "Unknown".
- During Load/Sync, report what changed.
- Allow to compare only data structure during Load/Sync.
- Custom fields for Enumerations and Enum Values.
- After a Search on tables show in a different color what was found in Name and Description fields.
- On Load/Sync process pseudo enum fields (Non native SQL Enums)

## Allow for an application to be viewable without user login
- Add support to flag type of information to be publish publicly.
- Implement public viewing.

## Linux Support (Via Ubuntu)
- Update VSCode task and launch to support Linux. Will be tested in Ubuntu. In progress.

## Docker Support
- Create docker file and documentation. Probably using Debian or Alpine.

## Documentation
- Installation notes and how to setup initial users.

## Visualization
- Auto Align tables or multi-select align.
- At the level of diagrams add settings to not show certain fields like pk, fk_*, created_by ....
- Free form navigation diagram. Specify a starting table, then navigate throughout the network of tables.

## Intra Application Mapping
- Allow to map tables and columns across application. In Progress.
- Add support in Visualization for cross application mapping.

## Harbour Specific
- Generation of Hash Array code to be used by Harbour_ORM.

## Migrations
- Generate Migration scripts again a specific installed database.

## Export / Import
- Export entire application meta data and allow to import in another instance.
- Support for JSON imports/exports. Specifications to be defined.

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
