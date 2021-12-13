# DataWharf - Upcoming fixes, changes and enhancements

## Short Term Fixes
- Forbid to change CustomField.UsedOn once related values are present.

## Pending Development
- Setup of User Security Global and Application Restrictions. Currently all users have full access.
- Load in table IndexColumn during structure imports.
- Load/Sync support to MySQL.
- During Load/Sync, only add entries or update entities with and "Usage Status" of "Unknown".
- During Load/Sync, report what changed.
- Allow to compare only data structure during Load/Sync.
- Custom fields for Enumerations and Enum Values.
- After a Search on tables show in a different color what was found in Name and Description fields.
- "Remember" last search criteria and even allow to view past search settings.
- On Load/Sync process pseudo enum fields (Non native SQL Enums)

## Allow for an application to be viewable without user login
- Add support to flag type of information to be publish publicly.
- Implement public viewing.

## Linux Support (Via Ubuntu)
- Update VSCode task and launch to support Linux. Will be tested in Ubuntu.

## Docker Support
- Create docker file and documentation. Probably using Debian or Alpine.

## Documentation
- Installation notes and how to setup initial users.

## Visualization
- When selecting a table in a diagram, if the same table is used in additional diagrams allow to easily open a new tab with that diagram.
- Handle when multiple foreign keys link the same parent and child table (Collapsed Arrows), or bidirectional links (Like last child added.)
- Support for multiple canvas dimension.
- Allow to reposition entire diagram.
- Auto Align tables or multi-select align.
- Color coding for tables and link that are inactive (being implemented).
- At the level of diagrams add settings to set what the table (nodes) and columns (arrows) should display, including on hover.
- At the level of diagrams add settings to specify colors, fonts, spacing and other CSS settings for tables and columns.
- At the level of diagrams add settings to not show certain fields like pk, fk_*, created_by ....
- Free form navigation diagram. Specify a starting table, then navigate throughout the network of tables.
- Store User and Diagram specific preferences (DiagramUser), for example: which tab to display when displaying the node (table) detail.

## Intra Application Mapping
- Allow to map tables and columns across application.
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
- Allow to load/Sync from MSSQL.
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
