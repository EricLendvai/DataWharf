# DataWharf - Change Log

## 03/07/2024 v 4.4
* Allow connections to DataWharf's own PostgreSQL database to be retried by refreshing any web page. This makes the application more resilient in case the database was not running at first or the connection is lost.

## 03/06/2024 v 4.3
* Option to duplicate table now also duplicated related indexes.
* Option to duplicate Column, Enumeration and Enumeration Values.
* Table and Enumeration search will also use Previous Names match on any related data.
* Fix bug during duplication with initialization of name if the source included an "_".
* Implemented renaming support for Namespaces, Tables, Columns, Enumerations and Enumeration Values, when generating migration code. This is only supported for PostgreSQL currently.
* Requires Harbour_ORM version 4.5 minimum.

## 02/26/2024 v 4.2
* Unlimited Personal Deployment configurations in every application. Previously only a Custom Configuration was allowed.
* Track Name Changes for Namespaces, Tables, Columns, Enumerations and Enumeration Values (Indexes are deleted and created). This is optional and is not yet used during schema migrations.
* Option to duplicate Namespaces and Tables. Columns, Enumerations and Enumeration Values will be added in future version.
* Incorporated hot fix from V 4.1A and 4.1B on corruption of Table and Enumeration record after edit if Namespace edits were disabled.

## 02/20/2024 v 4.1
* Number of Relationships in Application list screen.
* Fix issue on using link to Table Columns, if a search criteria exists on Tables.

## 02/19/2024 v 4.0
* Enhanced UI when editing applications, new Nex/Previous buttons on most elements.
* Added multiple Count columns and "Referenced by" screens.
* Added the ability to review Diagrams from Tables.
* In Applications, renamed the "Visualize" Tab to "Diagrams" to reduce confusion.
* "Support Column Names" list will be used to display "Implicitly Support" in Column edit screen when applicable.
* Support for extended and Unicode characters in "Namespace","Table","Column","Enumeration","EnumValue","Index" name fields, since allowed in PostgreSQL
* New Integrity test to warn of non Alphanumeric with underscore and non leading numeric identifiers. Even though blanks are allowed in column names for example, many ORM can not handle them.
* Removed for now the "Inter-App Mapping" option. This feature need to be re-designed to be effective.
* Made the Table and Enumeration search options more valuable by adding search modes "Basic", "Standard" and "Advanced".
* Added Code field to Enumeration Values. Optional and can be used for reporting.
* New "Prevent Changing Namespace on Existing Tables and Enumeration" application level setting.
* Several new "Integrity Test" options.
* Changed use of Harbour_VFP to Harbour_EL dependency.

## 01/28/2024 v 3.5
* Requiring Harbour_ORM 4.2
* Internal Refactoring to reduce memory usage.
* Fix on Harbour_ORM and JSon Export to exclude Foreign Key Constraints on discontinued fields.

## 01/28/2024 v 3.4
* Requiring Harbour_ORM 4.1 to ensure Foreign Key Constraint name are always created lower case.
* Renamed "Delta/Load Schema" tab in Dictionary to "Deployment Tools".
* Added an option to "Update Schema" in "Deployment Tools".
* Export to ORM and JSON now include Enumeration list.
* Renamed "TableSchema" Harbour Hash Array and Json Exports to simple "Tables".
* New GenerateMigrateForeignKeyConstraintsScript and MigrateForeignKeyConstraints methods.
* GenerateMigrateSchemaScript and MigrateSchema will now also update Postgresql native Enumerations. Please note, that due to current Postgresql limitations, enumeration values can be added, but never renamed or deleted.
* Removed method GenerateCurrentSchemaHarbourCode, since all Harbour Hash tables are now generated from DataWharf.
* Added "Generated Script" option under the "Deployment Tools".
* New Option "Allow Updates" under Application Deployment setting screen. This will be used by the "Update" option in "Deployment Tools".

## 01/12/2024 v 3.3
* Minor fix in Integrity Test feature, the "Foreign Key missing "On Delete" setting" failed to work sometimes.
* New setting "Set Missing "On Delete" in Foreign Keys To "Protect (Restrict)"" in "Data Dictionary Settings".

## 01/11/2024 v 3.2
* Minor fix on "Recent Errors" listing page.

## 01/06/2024 v 3.1
* Failure on Requiring dependency update. No code change in DataWharf, but YOU MUST update Harbour_FCGI, Harbour_ORM and Harbour_VFP to their latest version:
   * MIN_HARBOUR_ORM_VERSION  "4.0"
   * MIN_HARBOUR_VFP_VERSION  "3.4"
   * MIN_HARBOUR_FCGI_VERSION "1.7"

## 01/06/2024 v 3.1
* New "Recent Errors" page under setting, accessible by "Root Admin" users. This will display up to 100 of the latest Data Errors and Data Trim events (Loss of data,due to too small columns).
* Minor fix in Template Columns.

## 01/05/2023 v 3.0
* WARNING, THE FIRST RUN using the new version may take several minutes to run, since a lot of data cleanup/restructuring will occur.
* Major version change, due to p_Schema structure change and the use of DataWharf to manage its own Schema.
* REQUIRES Harbour_ORM version 4.0 minimum.
* REQUIRES Harbour_FastCGI version 1.7 minimum
* Added support for JSONB PostgreSQL native field types.  STILL UNDER DEVELOPMENT. Bad DEFAULT
* In "Applications/Data Dictionaries" new export option "Export to JSON".
* Added support for API Tokens to be past in the URL additionally from being able to add the token in a header meta data.   
* New APIs "ApplicationHarbourConfigurationExport" and "ApplicationJSONConfigurationExport". You must add the endpoint to an API Token to call it.   
The following is an example for calling the an api:   
```api/ApplicationHarbourConfigurationExport?application=<ApplicationLinkCode>&AccessToken=<Token>```
* Option to add a Scale/Precision to field types including a time component. Max scale set at 6.
* Fixed issue of double rendering diagrams.
* Fix to ignore request to resource files, like the favicon.ico.
* New application settings: "Auto Increment Integer and Big Integer Primary Keys" and "Auto Assign UUID Primary Keys".
* In Columns ability to specify how a primary field can be auto set.
* Removed the "Required" property for columns. This concept to be implemented in WharfSystems, since it is related to UI. The Nullable property is already sufficient. 
* The export of Harbour_ORM changed to match the requirements of Harbour_ORM version 4+.
* Data dictionary integrity test option in "Application Setup". Extra Warning column will appear in Tables, Columns, Enumerations and Indexes list.
* Foreign keys can be marked as "Optional". In Diagram mode the edge will have an "Open" arrow, instead of a solid one.
* DataWharf's own database will not use "0" integer in foreign keys. Nulls are now supported internally. This is due to auto-conversion for 0 and NULL made by the Harbour_ORM.
* New "Default Presets" in Columns and Template Columns. This will simplify setting up defaults in most cases.
* DataWharf's own database has foreign key constraints.


## 11/12/2023 v 2.60
* REQUIRES Harbour_ORM version 3.14 minimum.
* Added in Visualizations (Diagrams) "My Settings" the option to be current diagram (Application and Modeling) specific.
* Fix saving "Right Panel Scale" in "My Settings".
* Added support for PostgreSQL UNLOGGED table setting.
* Change casing and word separation from "Name Space"/"NameSpace" to "Namespace"

## 11/05/2023 v 2.59
* Minor Enhancement to make it easier to select and copy to clipboard table and link names in Application Visualization.
* Enhancements to integrate with WharfSystems.
* Removed the "Version" table, since schema management will be done via WharfSystems Stories.
* Added field UserSetting.ValueType to align with WharfSystems.
* "Export for DataWharf Imports" option at the level of a single table. For now only related Namespace, Columns, Index and Enumerations are exported only. Foreign key links will not be set during imports. 
* Added prefix to Cookies, needed to avoid conflicts with WharfSystems while sharing a host.
* Added filter Name Space in the Tables Advanced mode search.

## 09/24/2023 v 2.58
* On delete of Application, Projects, API Tokens, also test or cleanup on related tables.
* Manual Edit pages of Indexes.
* Update hb_orm to allow to search on "_" characters, instead of being a wildcard character.

## 09/09/2023 v 2.57
* Fix to Docker file relative to dependency paths.
* Minor tweak to API code.

## 09/09/2023 v 2.56
* Requirement: Get New Harbour_ORM and Harbour_FastCGI first.
* New Settings / API Tokens menu option to configure API Tokens and specify their access rights.
* New API "Applications" and "ApplicationHarbourConfigurationExport", aware of API Tokens access rights.   
   You must set AccessToken in the request header.   
   Example of API Call: {{base_url}}api/applications   
   Example of API Call: {{base_url}}api/ApplicationHarbourConfigurationExport?application=WF   
* API names, used in API calls, are now case-insensitive.
* New Template Tables in Data Dictionaries. They can be used when adding a new table to initialize a list of columns.
* Updated Main Menu UI for consistency and color highlight.
* Changed search options on Data Dictionary Tables to have an "Advanced" flag and search on Enumerations.
* Search options on the Data Dictionary Enumeration List.
* Under PostgreSQL, Load of Schema will not import indexes on Primary keys and Foreign keys of type "I","IB","UUI" (previously defined in DataWharf).
* Only define indexes that are not used on Primary and Foreign Keys, of type Integer, Integer Big or UUID. The export to HB_ORM will automatically add them.   
    Since there is no manual edit of indexes, as they get created via the "Load Schema", and fewer are needed, you may want to purge the following 2 tables and re-run "Load Schema":   
    truncate table "Index";   
    truncate table "IndexColumn";   

## 06/12/2023 v 2.55
* Display of "Usage Status" in headings on right panels in Diagrams.
* In Application management, moved Visualize Tab to leftmost position.
* Fix connection to MSSQL 2022
* Added to Dockerfiles loading of MariaDB, MySQL and MSSQL odbc drivers. The docker base image is ready for all supported backend while under Ubuntu 22:04.

## 04/21/2023 v 2.54
* Fix issue on edit of Enumerations, due to incomplete data loads.

## 04/08/2023 v 2.53
* Changed Dockerfile of devcontainer to work around git install failure introduced around April 2023

## 03/29/2023 v 2.53
* Added new logo and favicon images for LOGO_THEME_NAME: Earth_001, Blocks_001, Blocks_002, Blocks_003. 

## 03/29/2023 v 2.52
* Added support to LOGO_THEME_NAME in config.txt, name of image files in "images" folder.
* Added support to COLOR_HEADER_TEXT_WHITE in config.txt to use values "No" and "Yes" instead of ".t./.f."

## 03/12/2023 v 2.51
* Updated Dockerfiles and update README.md demo installation instructions.
* Completed GitHub Action Workflow for CI/CD of docker base image.

## 03/11/2023 v 2.51
* New build_dockerhub_image_ubuntu_22_04 workflow.

## 03/11/2023 v 2.51
* Update Dockerfiles and create one to be used as Base Image by a GitHub Action Workflow. (Not complete)

## 03/06/2023 v 2.51
* No Application change. Updated README.md to assist in running a demo of DataWharf using Docker. New Dockerfile_* and config_demo.txt files.

## 03/04/2023 v 2.51
* Update DataWharf Self-Documentation Import. Meaning can import the entire data dictionary of DataWharf itself.
* New option on Applications and Projects settings to set "Destructive Delete" levels. 
* "Destructive Delete" settings enables the following features: 
  * Purge a data dictionary and keep access rights settings
  * Depending of "Destructive Delete" setting: Delete a table, name space, entity, association, model, without the need to remove dependencies first.

## 03/03/2023 v 2.50
* Fix crash on editing of custom field settings.
* Added support to oid data types.
* New application logo in nav bar and About page.
* On manual add of new enumeration, go to add enumeration values.

## 02/22/2023 v 2.49
* Fix on Delta when selecting a Deployment.
* Fix on manual delete of column.

## 02/21/2023 v 2.48
* Added Application Deployment settings. Also available in Delta/Load Data Dictionary feature.

## 02/17/2023 v 2.47
* Single Sign On support (Release after successful test).
* Update the Harbour_FastCGI v 1.4 to fix "scan all" commands.

## 02/15/2023 v 2.46
* Simplified linking of libraries hb_el and hb_orm. Update those related libraries.

## 02/12/2023 v 2.45
* Fixed bug in load schema.
* Fixed bug on editing enumerations.
* Delta and Load in Applications are Integer and Numeric Enumeration aware.
* DataWharf Schema definition available for import in DataWharf itself. Removed DataWharfSchema.vsd since will not be maintained.
* Fix stripped list background colors when Use Status is used.

## 02/11/2023 v 2.44
* Moved source code files to "src" folder.
* Support for Single Sign On, only in Linux. Using code from tgold, Thank you!.
* Requires Harbour_FastCGI 1.3

## 02/10/2023 v 2.43
* Fix of Import/Export when deploying on AWS RDS. The issue is related to RDS blocking use of PostgreSQL Large Objects. If using RDS and using multiple web servers, a balancer needs to be used to route all traffic to the same server for a logged in user. This requirement is only needed for import/exports.

## 02/07/2023 v 2.42
* Additional clean up of tasks.json to be smaller and fix "Del Build Cache" under powershell.
* Import and Export feature for Applications (Data Dictionary) and Models. Currently Highest access right is required.

## 01/24/2023 v 2.41
* Clean up of tasks.json to be smaller and remove "Soft Task Kill"
* Added support for smallint data types.

## 01/23/2023 v 2.40
* Fix on version of DataWharf JS library to use.
* Fix to devcontainer and Dockerfile to use local host install in PostgreSQL server. This is the preferred method when developing in and out the container.
* Added "fake" instruction in Dockerfile to force rebuilding image from that location.   
  See line "ARG FakeOptionToForceDockerImageRebuildFromThisPointOn_ChangeTheFollowingValue 4".   
  Simply increment the number every time you would like to rebuild without cache from that point on.   
  This is needed to force a re-copy of host files in the container.   
  "docker build" will not detect local files being modified in the folder "FilesForPublishedWebsites" for example.   

## 01/23/2023 v 2.39
* Please pull latest version of Harbour_ORM and Harbour_FastCGI.
* Fix of "Copy To Clipboard" for "Export To Harbour_ORM". Issue of => notation formatting.
* In Data Dictionary list of columns, when hovering the mouse over an enumeration, the possible values are displayed.
* In Data Dictionary Main Menu added direct links to several components.
* Changes in Data Dictionary Visualize: Increase rendering speed, Display total number of tables and links, remembers the last diagram accessed by each user and application, when hovering the mouse over an enumeration the possible values are displayed.
* Changes in Model Visualize: Display total number of Entities, Association Nodes and links, remembers the last diagram accessed by each user and model.
* In Modeling, will remember if the sidebar menu is open or not. Will still reset to open when going to the list of models screen. This makes for a better user experience in visualize.

## 01/15/2023 v 2.38
* In Mxgrap visualization, fix dragging many nodes without loosing edges in Modeling.
* Changed color of lists heading to a darker blue to help readability of white text.
* Added models count on projects list.
* Added more counts on list of models.
* Added "Use Status" in the following modeling items: Entities, Associations, Attributes, Data Types, Enumerations, Packages
* Using background colors in lists when "Use Status" is one of the following: Proposed, Under Development, To Be Discontinued, Discontinued
* In Model Visualization, the "Use Status" is used to display the heading color of Entity and Association information panels. 

## 01/13/2023 v 2.37
* Using different background colors in application grids to reflect the Use Status.
* In Mxgrap visualization, fix dragging many nodes without loosing edges in Applications.

## 01/12/2023 v 2.36
* New "/health" web page returning status info to be used to monitor deployment of DataWharf.
* New Export option in data dictionaries. Currently only with export for Harbour ORM.

## 01/11/2023 v 2.35
* New "Duplicate" option of Application and Project Visualize (Diagrams).

## 01/09/2023 v 2.34
* Fix for Load and Delta feature on PostgreSQL for jsonb native field types.

## 01/04/2023 v 2.33
* WARNING: You must pull recent version of Harbour_VFP, Harbour_ORM and Harbour_FastCGI repos!
* Added support to UUID and JSON in PostgreSQL and MySQL/MariaDB
* Added support to array field types in PostgreSQL
* Updated devcontainer to not git pull Harbour_VFP, Harbour_ORM and Harbour_FastCGI. Instead clone them on your local host and mount statements will handle them in the DataWharf devcontainer.

## 07/08/2022 v 2.32
* Fix of Load/Sync Schema of MSSQL under Ubuntu

## 07/08/2022 v 2.31
* Mouse Wheel Zooming support in Visualizations now requires to also press the CTRL key per https://github.com/EricLendvai/DataWharf/pull/29
* Code refactoring to centralize JavaScript library versions in DataWharf.ch

## 07/08/2022 v 2.30
* Multiple Visualization Enhancement as per  https://github.com/EricLendvai/DataWharf/pull/28
* Support for Mouse Wheel Zooming support in Visualizations.

## 07/05/2022 v 2.29
* Multiple Visualization Enhancement ( https://github.com/EricLendvai/DataWharf/pull/27 )
* Added setting in Application Visualization to select VisJs or MxGraph, making it easier to convert to new mxgraph rendering mode.

## 07/04/2022 v 2.28
* Unabled mxgraph for modeling visualization.
* New APIs, see api.txt.
* Now allowing "-" for user ids, since email address also allow "-".

## 06/15/2022 v 2.27
* Partial fixes for preview option of mxgraph method to visualize, see DataWharf.ch.

## 06/14/2022 v 2.26
* Deleting a table will also delete its related indexes, once the table has no more columns.
* Preview option of mxgraph method to visualize, see DataWharf.ch.
* On add of new table, redirect to options to add columns instead of list of tables.
* New Delta option in Load/Sync of datadictionary to report difference between the data in DataWharf and the physical implementation. Only functional for PostgreSQL and to test existence of enumerations, enumerations values, tables and columns (not if matching or indexes yet).

## 06/02/2022 v 2.25
* Fix list of attributes being displayed in Visualize models.
* Removed xhb.hbc

## 05/26/2022 v 2.24
* Code refactor to remove public variables and simplify header files by combining them in datawharf.ch

## 05/18/2022 v 2.23
* Fix on Pull down menu when using COLOR_HEADER_TEXT_WHITE in config.txt

## 05/17/2022 v 2.22
* Settings pull down main menu.
* New "Object" data type for entity attributes.

## 05/14/2022 v 2.21
* New Model Enumerations.
* New Linking of Models and Entities.
* New total counts of tables,columns and other items on list of data dictionaries.
* Allow to create tree structure like for attributes (in Entities).
* Discontinued the field Attribute.Order, using instead Attribute.TreeOrder1.
* Allow to have the same name in Packages, Datatypes and Attributes, as long as using a different parent record.
* Change Password menu option.

## 05/07/2022 v 2.20
* To allow to use email addresses for login id, expanded the user.id field to 100 characters long.
* Renamed environment variable from FastCGIRootPath to HB_FASTCGI_ROOT to be consistent with other variables.
* Fix bug in Sync/Load to add elements with similar root name. Re-Run load sync.
* Fix bug in Application Visualize displaying nodes with table and schema names.
* New config.txt files settings to specify alternate ODBC drivers to be used during "Load/Sync Schema":
  * ODBC_DRIVER_MARIADB
  * ODBC_DRIVER_MYSQL
  * ODBC_DRIVER_POSTGRESQL
  * ODBC_DRIVER_MSSQL

## 04/12/2022 v 2.19
* Fix error in "Settings" in "Diagrams" where some entities have packages and some don't.

## 04/12/2022 v 2.18
* Fix load/sync for PostgreSQL to skip views.
* Fix load/sync on multiple schemas separated with comma.
* Fix re-orders not being saved.

## 04/11/2022 v 2.17
* Fix cleanup of invalid characters during entry of name space/table/column/enum ... fields. Only Alpha Numeric and "_" are allowed now.

## 04/09/2022 v 2.16
* Integrated API endpoints provided mainly during Hackathon
* Fixed to ignore Unicode flag on non Character based column types.
* Added support to iOS (Mac) Builds by allowing linux behavior to also apply to Mac.

## 03/24/2022 v 2.15
* Basic API Support for modeling (Under Development).

## 03/23/2022 v 2.14
* Modeling entities edition page now has tabs for easy access to properties and associations. (From GitHub Merge)
* Initial support to /api/ framework.  (set AccessToken = 0123456789 in request header, temporary solution until formal Authorization system.)

## 03/14/2022 v 2.13
* Modeling Treeview Enhancements. (From GitHub Merge)

## 03/13/2022 v 2.12
* New option to detect foreign keys where the column name is formatted as <TableName>_id
* For consistency made all foreign keys default to 0 instead of null. YOU MUST GET LATEST version of the Harbour_ORM repo.
* Fixed issue when editing Modeling Associations not belonging to a Package.

## 03/12/2022 v 2.11
* Made all delete buttons red.

## 03/11/2022 v 2.10
* Incorporated treeview in modeling. (From GitHub Merge)
* Min CSS fixes for treeview.
* Fixed Access issues for "Root Admin" user.
## 03/09/2022 v 2.09
* Markdown preview for modeling entities. (From GitHub Merge)
* Fixed label in Association from "Aspect Of" to "Is Containment"

## 03/01/2022  v 2.08
* Fix bug in Modelling Visualize when displaying a node including a package name.
* New "Load All Primitives" button in modeling / Data Types. Will only be present if at least one Primitive Type does not have a matching Data Type.

## 02/28/2022  v 2.07
* Modeling Entity grid will only show a check mark in case the entity as some information. The entire content of the information will not be displayed on the grid.

## 02/26/2022
* Added support to markdown to the Table and Entity Information field, in grids and right panel in Visualize.
* New "Node Minimum Height" and "Node Maximum Width" options in diagram setups.
* Added "Markdown" documentation link where markdown entry is supported.
* Added Project level definition of Primitive Types.
* Data Types can be mapped to a Primitive Type.
* In Project Setups, new Bound Lower and Upper list of valid values. If has values Will be used during validation of Association Ends entry.
* Full Access Users on a particular Project or Application can edit their settings.
* Grid on Users admin page now displays projects and Applications access level.

## 02/24/2022
* Renamed AspectOf to IsContainment
* Fix renaming of labels of tabs of right panel in visualization
* Made Label of Entities and Associations in Project Visualization bold, except for additional descriptions.
* New PrimitiveType table (Under Development)
* Renamed Entity.Scope to Entity.Information. Will be adding an option at the level of the project to rename Description and Information Fields.
* Using merged code by tgold, added support to markdown to the Entity.Information field (In the grid only). Will also be added to Visualization and Applications features.

## 02/22/2022
* Modeling Visualization now will display multiple association edges separately.
* Self Test and notification in case of failure for the presence of the "pgcrypto" extension.

## 02/20/2022
* Data Dictionaries Visualization now will display multiple foreign keys to the same table as multiple edges (arrows).
* New "Foreign Key Use" entry field for columns, when used as foreign key. This is being used in the visualize feature.
* Enhanced selecting of tables in Foreign Key columns.
* All Enhanced Selections drop downs will now auto focus keyboard entries.

## 02/17/2022
* New "Aspect Of" in modeling.

## 02/15/2022
* Modeling Visualization.

## 02/08/2022
* Fixed read only mode in visualization.

## 02/07/2022
* Completed the Create/Update/Delete functionalities in Modeling
* Renamed ConceptualDiagram table to ModelingDiagram
* First version of Modeling Visualization. Does not include text on the edges yet. Only an "All Entities" Diagram can be created.

## 01/26/2022
* New "Copy Diagram Link To Clipboard" to allow to provide a direct link to a particular diagram.
* Added a "Data Dictionaries" top menu option and moved most of the "Applications" menu functionality to it.
* Extended the Security setup for access rights of Users to deal with new "Modeling" feature.
* New "Modeling" Menu with partial functionality
  * Allow Models to be defined, with support to Custom Fields.
  * Have a tree structure of Packages under Models, with support to Custom Fields.
  * Have a tree structure of Data Types under Models, with support to Custom Fields.
  * Basic Management of Entities (not properties yet), with support to Custom Fields.
* Discontinued field Model.UseStatus and added Model.Stage.
* Renamed field UserAccessApplication->AccessLevel to UserAccessApplication->AccessLevelDD

## 01/14/2022
* When using load/sync against MariaDB/MySQL, can auto-set foreign keys from actual foreign key restrictions in the database.

## 01/11/2022
* Updated Conceptual Modeling supporting files.

## 01/10/2022
* Fix missing edit table icon in visualize right panel (with access right)
* New "Required" field for columns.
* Load/Sync will not override column properties if the "Use Status" is "Under Development" or more.
* If the database to use in config.txt is changed while the server running, it will automatically reconnect and most likely prompt for used login.
* Added tables ConceptualDiagram, DiagramEntity (Under Development)

## 01/09/2022
* Fix issue on load/sync failing to get default values on initial load.
* Intial table setup for upcoming Conceptual Modeling feature.

## 01/08/2022
* Added the use of additional config settings in backend/config.txt file: POSTGRESHOST,POSTGRESPORT,POSTGRESDATABASE

## 01/07/2022
* Initial support to load MariaDB/MySQL schema. Only Tables and Columns. Index in future update.

## 01/05/2022
* Rename the concept of Flags to Tags
* Initial support of Tag for columns

## 01/04/2022
* New Flags options at the levels of Applications. All Application can have their own flags and applied to Tables. (To Columns coming soon.
* Table Search option now includes searches on flags, as long as at least one table has a linked flag.)

## 01/02/2022
* New Inter-App Mapping option. Still under development, see notes at the top of the file WebPage_InterAppMapping.prg

## 12/28/2021
* Added Filter options on List of Columns being displayed when selecting a node in Visualize.

## 12/27/2021
* On Table List screen, will remember search criteria, until "Reset" button is used.
* On Table List screen, if the last search criteria included settings used on columns, those will be defaulted in the search criteria when viewing columns.
* Using Bootstrap icons instead of fontawesome. Makes it easier to deal with license.
* Added "Support Column Names" on "Application Settings". User may list column names, blank separated, of fields like: creation or last modified time, added by, last modified by ...
* Added Primary, Unicode, Default and LastNativeType in Column
* Added new "icon" column when listing a table's columns.

## 12/23/2021
* On Table and Column Name searches will also look into the AKA fields.

## 12/22/2021
* Support to Load MS SQL databases (except for indexes).

## 12/19/2021
* Change "Usage Status" to have 6 possible values.
* Enhancements in Diagrams: 
  * New "My Settings" button with option to change Canvas dimension, level of zoom for info area, and color of Unknown items.
  * Selectable content to display in Node/Table.
  * Support for on-hover to display Table description if not already visible.
  * More color coding based on "Usage Status".
  * Completed "Other Diagrams" tab.
* Security: 
  * Functional Read Only mode (Except in Diagrams).
  * Integration with Cyanaudit (Add "CYANAUDIT_TRAC_USER=Yes" in config file to enable recording of User.pk).

## 12/12/2021
* New AKA (Also Known As) for Name Space, Table, Column, Enumeration and Enumeration Values.
* New Information field for tables. Can be used as long description/Engineering notes. Will be enhanced to allow Markdown language.
* Added easy selection/deselection of related tables when selecting a table from the Visualize/Diagram feature.
