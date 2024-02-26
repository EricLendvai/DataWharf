#define BUILDVERSION "4.2"

#include "hb_fcgi.ch"
#include "hb_orm.ch"
#include "hb_el.ch"
#include "dbinfo.ch"

#ifdef __PLATFORM__LINUX
#include "hbcurl.ch"
#endif

#define COOKIE_PREFIX "DataWharf_"   // Cookies Prefix needed in case running other website on same host while using a virtual folder

// #ifdef __PLATFORM__WINDOWS
// #endif

#define MIN_HARBOUR_ORM_VERSION  "4.4"
#define MIN_HARBOUR_EL_VERSION   "4.1"
#define MIN_HARBOUR_FCGI_VERSION "1.8"

#define DATAWHARF_SCRIPT_VERSION     "2023_01_23"
#define VISJS_SCRIPT_VERSION         "2022_02_15_001"
#define MXGRAPH_SCRIPT_VERSION       "18_0_1"
#define BOOTSTRAP_SCRIPT_VERSION     "5_0_2"
// #define BOOTSTRAP_SCRIPT_VERSION     "5_3_2"
#define JQUERYUI_SCRIPT_VERSION      "1_12_1_NoTooltip"
#define JQUERY_SCRIPT_VERSION        "3_6_0"
#define JQUERYSELECT2_SCRIPT_VERSION "2022_01_01"
#define MARKED_SCRIPT_VERSION        "2022_02_23_001"
#define BSTREEVIEW_SCRIPT_VERSION    "1_2_0"
#define JQUERYAMSIFY_SCRIPT_VERSION  "2020_01_27"

#define WEBPAGEHANDLE_NAME            1
#define WEBPAGEHANDLE_ACCESSMODE      2
#define WEBPAGEHANDLE_BUILDHEADER     3
#define WEBPAGEHANDLE_FUNCTIONPOINTER 4

#define COLOR_ON_LINK_NEWPAGE "198754"

#define APPLICATION_TITLE "DataWharf"           // Default Value, Can be overwritten in config.txt
#define COLOR_HEADER_BACKGROUND "E3F2FD"        // Default Value, Can be overwritten in config.txt
#define COLOR_HEADER_TEXT_WHITE .f.             // Default Value, Can be overwritten in config.txt

//#define LOGO_THEME_NAME "RainierSailBoat"
#define LOGO_THEME_NAME "RainierKayak"        // Default Value, Can be overwritten in config.txt

#define GOINEDITMODE "$('.TopTabs').addClass('disabled');$('.RemoveOnEdit').remove();$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary').removeClass('disabled');$('#ButtonDoneCancel').val('Cancel');"

//Following to be removed
#define UPDATE_ONSELECT_SAVEBUTTON            [ onchange="ToggleEditFormMode();" ]
#define UPDATE_ONTEXTAREA_SAVEBUTTON          [ onKeyPress="ToggleEditFormMode();" onchange="ToggleEditFormMode();" ]
#define UPDATE_ONCHECKBOXINPUT_SAVEBUTTON     [ type="checkbox" onchange="ToggleEditFormMode(); " ]
#define UPDATE_ONTEXTINPUT_SAVEBUTTON         [ type="text" onKeyPress="ToggleEditFormMode();" onchange="ToggleEditFormMode();" ]
#define UPDATE_ONPASSWORDINPUT_SAVEBUTTON     [ type="password" onKeyPress="ToggleEditFormMode();" onchange="ToggleEditFormMode();" autocomplete="new-password" ]
#define UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON [ToggleEditFormMode();]

#define USEDON_APPLICATION 1
#define USEDON_NAMESPACE   2
#define USEDON_TABLE       3
#define USEDON_COLUMN      4
#define USEDON_MODEL       5
#define USEDON_ENTITY      6
#define USEDON_ASSOCIATION 7
#define USEDON_PACKAGE     8
#define USEDON_DATATYPE    9
#define USEDON_ATTRIBUTE  10
#define USEDON_PROJECT    11

#define GRAPH_LIB_ML "mxgraph"
//#define GRAPH_LIB_DD "visjs"
// #define GRAPH_LIB_DD "mxgraph"   // Not used anymore. Each Diagram can be set to use either rendering javascript library.

#define CANVAS_WIDTH_MIN      300
#define CANVAS_WIDTH_MAX      3000
#define CANVAS_WIDTH_DEFAULT  1200

#define CANVAS_HEIGHT_MIN     200
#define CANVAS_HEIGHT_MAX     2000
#define CANVAS_HEIGHT_DEFAULT 800

#define USESTATUS_1_NODE_BACKGROUND "cccccc"  // Unknown
#define USESTATUS_1_NODE_HIGHLIGHT  "eeeeee"

#define USESTATUS_2_NODE_BACKGROUND    "92d050"       // Proposed
#define USESTATUS_2_NODE_TR_BACKGROUND "146,208,80"   // Proposed
#define USESTATUS_2_NODE_HIGHLIGHT     "aef75f"

#define USESTATUS_3_NODE_BACKGROUND    "00b050"       // Under Development
#define USESTATUS_3_NODE_TR_BACKGROUND "0,176,80"     // Under Development
#define USESTATUS_3_NODE_HIGHLIGHT     "44df89"

#define USESTATUS_4_NODE_BACKGROUND "97c2fc"          // Active
#define USESTATUS_4_NODE_HIGHLIGHT  "d2e5ff"

#define USESTATUS_5_NODE_BACKGROUND    "ffc000"       // To be Discontinued
#define USESTATUS_5_NODE_TR_BACKGROUND "255,192,0"    // To be Discontinued
#define USESTATUS_5_NODE_HIGHLIGHT     "ffe083"

#define USESTATUS_6_NODE_BACKGROUND    "ff9696"       // Discontinued
#define USESTATUS_6_NODE_TR_BACKGROUND "255,150,150"  // Discontinued
#define USESTATUS_6_NODE_HIGHLIGHT  "feb4b4"

#define STAGE_6_NODE_TR_BACKGROUND "255,150,150"  // Discontinued
#define STAGE_6_NODE_HIGHLIGHT  "feb4b4"

#define MODELING_ENTITY_NODE_BACKGROUND "99fdfc"
#define MODELING_ENTITY_NODE_HIGHLIGHT  "c5e789"

#define MODELING_ASSOCIATION_NODE_BACKGROUND "fdc5ba"
#define MODELING_ASSOCIATION_NODE_HIGHLIGHT  "c5e789"

#define MODELING_EDGE_BACKGROUND "000000"
#define MODELING_EDGE_HIGHLIGHT  "0000FF"

#define SELECTED_NODE_BORDER "666666"

#define USESTATUS_1_EDGE_BACKGROUND "bbbbbb"
#define USESTATUS_1_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_2_EDGE_BACKGROUND "92d050"
#define USESTATUS_2_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_3_EDGE_BACKGROUND "00b050"
#define USESTATUS_3_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_4_EDGE_BACKGROUND "609ef2"   //97c2fc
#define USESTATUS_4_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_5_EDGE_BACKGROUND "ffc000"
#define USESTATUS_5_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_6_EDGE_BACKGROUND "ff9696"
#define USESTATUS_6_EDGE_HIGHLIGHT  SELECTED_NODE_BORDER

#define USESTATUS_UNKNOWN          1
#define USESTATUS_PROPOSED         2
#define USESTATUS_UNDERDEVELOPMENT 3
#define USESTATUS_ACTIVE           4
#define USESTATUS_TOBEDISCONTINUED 5
#define USESTATUS_DISCONTINUED     6

#define DOCTATUS_MISSING    1
#define DOCTATUS_NOTNEEDED  2
#define DOCTATUS_INPROGRESS 3
#define DOCTATUS_COMPLETE   4

#define USEDBY_ALLSERVERS     1
#define USEDBY_MYSQLONLY      2
#define USEDBY_POSTGRESQLONLY 3

#define ENUMERATIONIMPLEMENTAS_NATIVESQLENUM 1
#define ENUMERATIONIMPLEMENTAS_INTEGER       2
#define ENUMERATIONIMPLEMENTAS_NUMERIC       3
#define ENUMERATIONIMPLEMENTAS_VARCHAR       4

#define PROJECTDESTRUCTIVEDELETE_NONE                   1
#define PROJECTDESTRUCTIVEDELETE_ONENTITIESASSOCIATIONS 2
#define PROJECTDESTRUCTIVEDELETE_CANDELETEMODELS        3

#define APPLICATIONDESTRUCTIVEDELETE_NONE                     1
#define APPLICATIONDESTRUCTIVEDELETE_ONTABLESTAGS             2
#define APPLICATIONDESTRUCTIVEDELETE_ONNAMESPACES             3
#define APPLICATIONDESTRUCTIVEDELETE_ENTIREAPPLICATIONCONTENT 4
#define APPLICATIONDESTRUCTIVEDELETE_CANDELETEAPPLICATION     5

#define TAGUSESTATUS_DONOTUSE     1
#define TAGUSESTATUS_ACTIVE       2
#define TAGUSESTATUS_DISCONTINUED 3

#define RENDERMODE_VISJS   1
#define RENDERMODE_MXGRAPH 2

#define APIENDPOINT_STATUS_ACTIVE 1
#define APITOKEN_STATUS_ACTIVE 1

#define OUTPUT_FOLDER "Output"  //Folder will be relative to the Backend Folder where the FastCGI EXE in placed.

#define APIUSE .t.    // To enable or not the management and use of APIs

//{Code,Name,Show Length,Show Scale,Max Scale,Show Enums,Show Unicode,PostgreSQL Name, MySQL Name}
#define COLUMN_TYPES_CODE          1
#define COLUMN_TYPES_NAME          2
#define COLUMN_TYPES_SHOW_LENGTH   3
#define COLUMN_TYPES_SHOW_SCALE    4
#define COLUMN_TYPES_MAX_SCALE     5
#define COLUMN_TYPES_SHOW_ENUMS    6
#define COLUMN_TYPES_SHOW_UNICODE  7
#define COLUMN_TYPES_POSTGRES_NAME 8
#define COLUMN_TYPES_MYSQL_NAME    9

#define COLUMN_USEDAS_PRIMARY_KEY 2
#define COLUMN_USEDAS_FOREIGN_KEY 3
#define COLUMN_USEDAS_SUPPORT     4
