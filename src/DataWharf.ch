#include "hb_fcgi.ch"
#include "hb_orm.ch"
#include "hb_vfp.ch"
#include "dbinfo.ch"

#ifdef __PLATFORM__LINUX
#include "hbcurl.ch"
#endif

#define BUILDVERSION "2.44"

// #ifdef __PLATFORM__WINDOWS
// #endif


#define MIN_HARBOUR_ORM_VERSION  "3.5"
#define MIN_HARBOUR_VFP_VERSION  "3.3"
#define MIN_HARBOUR_FCGI_VERSION "1.3"

#define DATAWHARF_SCRIPT_VERSION     "2023_01_23"
#define VISJS_SCRIPT_VERSION         "2022_02_15_001"
#define MXGRAPH_SCRIPT_VERSION       "18_0_1"
#define BOOTSTRAP_SCRIPT_VERSION     "5_0_2"
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

#define APPLICATION_TITLE "DataWharf"
#define COLOR_HEADER_BACKGROUND "E3F2FD"
#define COLOR_HEADER_TEXT_WHITE .f.

#define UPDATESAVEBUTTON [ onchange="$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');$('.HideOnEdit').hide();"]

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

#define OUTPUT_FOLDER "Output"  //Folder will be relative to the Backend Folder where the FastCGI EXE in placed.
