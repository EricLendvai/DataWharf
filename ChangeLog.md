# DataWharf - Change Log

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
