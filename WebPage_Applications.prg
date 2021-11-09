#include "DataDictionary.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageApplications(par_cUserName,par_nUserPk)
local l_cHtml := []
local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_iApplicationStatus
local l_cApplicationDescription

local l_iNameSpacePk
local l_iTablePk
local l_iColumnPk
local l_iEnumerationPk
local l_iEnumValuePk

local l_cApplicationElement := "TABLES"  //Default Element

local l_aSQLResult := {}

local l_cURLAction              := "ListApplications"
local l_cURLApplicationLinkCode := ""
local l_cURLNameSpaceName       := ""
local l_cURLTableName           := ""
local l_cURLEnumerationName     := ""
local l_cURLVersionCode         := ""
local l_cURLColumnName          := ""
local l_cURLEnumValueName       := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]

// Variables
// l_cURLAction
// l_cURLApplicationLinkCode
// l_cURLNameSpaceName
// l_cURLTableName
// l_cURLEnumerationName
// l_cURLVersionCode
// l_cURLColumnName

//Improved and new way:
// Applications/                      Same as Applications/ListApplications/
// Applications/NewApplication/
// Applications/ApplicationSettings/<ApplicationLinkCode>/
// Applications/ApplicationLoadSchema/<ApplicationLinkCode>/


// Applications/ListNameSpaces/<ApplicationLinkCode>/
// Applications/NewNameSpace/<ApplicationLinkCode>/
// Applications/EditNameSpace/<ApplicationLinkCode>/<NameSpaceName>/

// Applications/ListTables/<ApplicationLinkCode>/
// Applications/NewTable/<ApplicationLinkCode>/
// Applications/EditTable/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/

// Applications/ListColumns/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// Applications/OrderColumns/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// Applications/NewColumn/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// Applications/EditColumn/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/<ColumnName>

// Applications/ListEnumerations/<ApplicationLinkCode>/
// Applications/NewEnumeration/<ApplicationLinkCode>/
// Applications/EditEnumeration/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/

// Applications/ListEnumValues/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// Applications/OrderEnumValues/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// Applications/NewEnumValue/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// Applications/EditEnumValue/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/<EnumValue>/

// Applications/ListVersions/<ApplicationLinkCode>/
// Applications/NewVersion/<ApplicationLinkCode>/
// Applications/EditVersion/<ApplicationLinkCode>/<VersionCode>/

// Applications/ListIndexes/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// Applications/NewIndex/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// Applications/EditIndex/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/<IndexName>

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLApplicationLinkCode := oFcgi:p_URLPathElements[3]
    endif

    if vfp_Inlist(l_cURLAction,"EditNameSpace","EditTable","EditEnumeration","ListColumns","OrderColumns","NewColumn","EditColumn","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLNameSpaceName := oFcgi:p_URLPathElements[4]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditTable","ListColumns","OrderColumns","NewColumn","EditColumn")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLTableName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLEnumerationName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditVersion")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLVersionCode := oFcgi:p_URLPathElements[4]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditColumn")
        if len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6])
            l_cURLColumnName := oFcgi:p_URLPathElements[6]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6])
            l_cURLEnumValueName := oFcgi:p_URLPathElements[6]
        endif
    endif

    do case
    case vfp_Inlist(l_cURLAction,"ListTables","NewTable","EditTable","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes","NewIndex","EditIndex")
        l_cApplicationElement := "TABLES"

    case vfp_Inlist(l_cURLAction,"ListEnumerations","NewEnumeration","EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        l_cApplicationElement := "ENUMERATIONS"

    case vfp_Inlist(l_cURLAction,"ListNameSpaces","NewNameSpace","EditNameSpace")
        l_cApplicationElement := "NAMESPACES"

    case vfp_Inlist(l_cURLAction,"ListVersions","NewVersion","EditVersion")
        l_cApplicationElement := "VERSIONS"

    case vfp_Inlist(l_cURLAction,"ApplicationSettings")
        l_cApplicationElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"ApplicationLoadSchema")
        l_cApplicationElement := "LOADSCHEMA"

    otherwise
        l_cApplicationElement := "TABLES"

    endcase

    if !empty(l_cURLApplicationLinkCode)

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Application")
            :Column("Application.pk"          , "pk")
            :Column("Application.Name"        , "Application_Name")
            :Column("Application.Status"      , "Application_Status")
            :Column("Application.Description" , "Application_Description")
            :Where("Application.LinkCode = ^" ,l_cURLApplicationLinkCode)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB1:Tally == 1
            l_iApplicationPk          := l_aSQLResult[1,1]
            l_cApplicationName        := l_aSQLResult[1,2]
            l_iApplicationStatus      := l_aSQLResult[1,3]
            l_cApplicationDescription := l_aSQLResult[1,4]
        else
            l_iApplicationPk   := -1
            l_cApplicationName := "Unknown"
        endif
    endif

else
    l_cURLAction := "ListApplications"
endif

do case
case l_cURLAction == "ListApplications"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        // l_cHtml += [<div class="container-fluid">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white mr-3" href="]+l_cSitePath+[Applications/">Applications</a>]
            l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewApplication">New Application</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += ApplicationsListFormBuild()

case l_cURLAction == "NewApplication"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    // l_cHtml +=     [<div class="container-fluid">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white">New Application</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()
        //Brand new request of add an application.
        l_cHtml += ApplicationEditFormBuild(0)
    else
        //Post
        l_cHtml += ApplicationEditFormOnSubmit("")
    endif


case l_cURLAction == "ApplicationSettings"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    if oFcgi:isGet()
        l_cHtml += ApplicationEditFormBuild(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode,l_iApplicationStatus,l_cApplicationDescription)
    else
        if l_iApplicationPk > 0
            l_cHtml += ApplicationEditFormOnSubmit(l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ApplicationLoadSchema"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    
    if oFcgi:isGet()
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

        l_oDB1:Table("public.Application")
        with object l_oDB1
            :Column("Application.SyncBackendType","Application_SyncBackendType")
            :Column("Application.SyncServer"     ,"Application_SyncServer")
            :Column("Application.SyncPort"       ,"Application_SyncPort")
            :Column("Application.SyncUser"       ,"Application_SyncUser")
            :Column("Application.SyncDatabase"   ,"Application_SyncDatabase")
            :Column("Application.SyncNameSpaces" ,"Application_SyncNameSpaces")
            l_oData := :Get(l_iApplicationPk)
        endwith

        if l_oDB1:Tally == 1
            l_cHtml += ApplicationLoadSchemaStep1FormBuild(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode,;
                                                           l_oData:Application_SyncBackendType,;
                                                           l_oData:Application_SyncServer,;
                                                           l_oData:Application_SyncPort,;
                                                           l_oData:Application_SyncUser,;
                                                           "",;
                                                           l_oData:Application_SyncDatabase,;
                                                           l_oData:Application_SyncNameSpaces)
        endif
    else
        if l_iApplicationPk > 0
            l_cHtml += ApplicationLoadSchemaStep1FormOnSubmit(l_iApplicationPk,l_cApplicationName,l_cURLApplicationLinkCode)
        endif
    endif


case l_cURLAction == "ListTables"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    if oFcgi:isGet()
        l_cHtml += TablesListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)
    else
        l_cHtml += TablesListFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

// Table Name                Includes/Starts With
// Table Description        (Word Search)
// Column Name              Includes/Starts With/Does Not dbExists
// Column Description       (Word Search)

//?TableNameText=xxxxxx&TableNameSearchMode=Includes/StartsWith


case l_cURLAction == "NewTable"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    if oFcgi:isGet()
        l_cHtml += TableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,0)
    else
        //Post
        l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

case l_cURLAction == "EditTable"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Table")
        :Column("Table.pk"          , "Pk")
        :Column("Table.fk_NameSpace", "fk_NameSpace")
        :Column("Table.Name"        , "Name")
        :Column("Table.Status"      , "Status")
        :Column("Table.Description" , "Description")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_cHtml += TableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_aSQLResult[1,1],"",l_aSQLResult[1,2],AllTrim(l_aSQLResult[1,3]),l_aSQLResult[1,4],l_aSQLResult[1,5])
            //static function TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,par_cErrorText,par_iNameSpacePk,par_cName,par_iStatus,par_cDescription)
        else
            //Post
            l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif


case l_cURLAction == "ListColumns"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Table")
        :Column("Table.pk"     ,"TablePk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iTablePk := l_aSQLResult[1,1]
        l_cHtml += ColumnListFormBuild(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
    endif


case l_cURLAction == "OrderColumns"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Table")
        :Column("Table.pk"     ,"TablePk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iTablePk := l_aSQLResult[1,1]
        if oFcgi:isGet()
            l_cHtml += ColumnOrderFormBuild(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        else
            l_cHtml += ColumnOrderFormOnSubmit(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        endif
    endif



case l_cURLAction == "NewColumn"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    //Find the iTablePk and iNameSpacePk (for Enumerations)

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Table")
        :Column("NameSpace.pk" ,"NameSpacePk")
        :Column("Table.pk"     ,"TablePk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iNameSpacePk := l_aSQLResult[1,1]  //Will be used to help get all the enumerations
        l_iTablePk     := l_aSQLResult[1,2]

        if oFcgi:isGet()
            l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,0)
        else
            //Post
            l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        endif
    endif

case l_cURLAction == "EditColumn"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Column")

        :Column("Column.pk"              ,"Column_pk")
        :Column("NameSpace.pk"           ,"NameSpace_pk")
        :Column("Table.pk"               ,"Table_pk")

        :Column("Column.Name"            ,"Column_Name")
        :Column("Column.Status"          ,"Column_Status")
        :Column("Column.Description"     ,"Column_Description")

        :Column("Column.Type"            ,"Column_Type")
        :Column("Column.Length"          ,"Column_Length")
        :Column("Column.Scale"           ,"Column_Scale")
        :Column("Column.Nullable"        ,"Column_Nullable")
        :Column("Column.UsedBy"          ,"Column_UsedBy")
        :Column("Column.fk_TableForeign" ,"Column_fk_TableForeign")
        :Column("Column.fk_Enumeration"  ,"Column_fk_Enumeration")

        :Join("inner","Table"    ,"","Column.fk_Table = Table.pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cURLColumnName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iColumnPk    := l_aSQLResult[1,1]
        l_iNameSpacePk := l_aSQLResult[1,2]  //Will be used to help get all the enumerations
        l_iTablePk     := l_aSQLResult[1,3]

        if l_oDB1:Tally != 1
            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListColumns/"+l_cURLApplicationLinkCode+"/")
        else
            if oFcgi:isGet()
                l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,l_iColumnPk,"",;
                                               AllTrim(l_aSQLResult[1, 4]),l_aSQLResult[1, 5],l_aSQLResult[1, 6],;
                                               AllTrim(l_aSQLResult[1, 7]),l_aSQLResult[1, 8],l_aSQLResult[1, 9],(alltrim(l_aSQLResult[1, 10])=="1"),;
                                               l_aSQLResult[1,11],l_aSQLResult[1,12],l_aSQLResult[1,13])
            else
                //Post
                l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
            endif
        endif
    endif



case l_cURLAction == "ListEnumerations"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += EnumerationsListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewEnumeration"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    if oFcgi:isGet()
        l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,0)
    else
        //Post
        l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

case l_cURLAction == "EditEnumeration"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Enumeration")
        :Column("Enumeration.pk"              , "Pk")
        :Column("Enumeration.fk_NameSpace"    , "fk_NameSpace")
        :Column("Enumeration.Name"            , "Name")
        :Column("Enumeration.Status"          , "Status")
        :Column("Enumeration.Description"     , "Description")
        :Column("Enumeration.ImplementAs"     , "ImplementAs")
        :Column("Enumeration.ImplementLength" , "ImplementLength")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumerations/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_aSQLResult[1,1],"",l_aSQLResult[1,2],AllTrim(l_aSQLResult[1,3]),l_aSQLResult[1,4],l_aSQLResult[1,5],l_aSQLResult[1,6],l_aSQLResult[1,7])
        else
            //Post
            l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif




case l_cURLAction == "ListEnumValues"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iEnumerationPk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Enumeration")
        :Column("Enumeration.pk"     ,"EnumerationPk")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iEnumerationPk := l_aSQLResult[1,1]
        l_cHtml += EnumValueListFormBuild(l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
    endif

case l_cURLAction == "OrderEnumValues"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iEnumerationPk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Enumeration")
        :Column("Enumeration.pk"     ,"EnumerationPk")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iEnumerationPk := l_aSQLResult[1,1]
        if oFcgi:isGet()
            l_cHtml += EnumValueOrderFormBuild(l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
        else
            l_cHtml += EnumValueOrderFormOnSubmit(l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
        endif
    endif

case l_cURLAction == "NewEnumValue"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    //Find the iEnumerationPk and iNameSpacePk (for Enumerations)

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Enumeration")
        :Column("NameSpace.pk"  ,"NameSpacePk")
        :Column("Enumeration.pk","EnumerationPk")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iNameSpacePk := l_aSQLResult[1,1]  //Will be used to help get all the enumerations
        l_iEnumerationPk     := l_aSQLResult[1,2]

        if oFcgi:isGet()
            l_cHtml += EnumValueEditFormBuild(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName,0)
        else
            //Post
            l_cHtml += EnumValueEditFormOnSubmit(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
        endif
    endif

case l_cURLAction == "EditEnumValue"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("EnumValue")

        :Column("EnumValue.pk"         ,"EnumValue_pk")
        :Column("NameSpace.pk"         ,"NameSpace_pk")
        :Column("Enumeration.pk"       ,"Enumeration_pk")

        :Column("EnumValue.Name"       ,"EnumValue_Name")
        :Column("EnumValue.Number"     ,"EnumValue_Number")
        :Column("EnumValue.Status"     ,"EnumValue_Status")
        :Column("EnumValue.Description","EnumValue_Description")

        :Join("inner","Enumeration"    ,"","EnumValue.fk_Enumeration = Enumeration.pk")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        :Where([lower(replace(EnumValue.Name,' ','')) = ^],lower(StrTran(l_cURLEnumValueName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iEnumValuePk    := l_aSQLResult[1,1]
        l_iNameSpacePk := l_aSQLResult[1,2]  //Will be used to help get all the enumerations
        l_iEnumerationPk     := l_aSQLResult[1,3]

        if l_oDB1:Tally != 1
            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumValues/"+l_cURLApplicationLinkCode+"/"+l_cURLNameSpaceName+"/"+l_cURLEnumerationName+"/")
        else
            if oFcgi:isGet()
                l_cHtml += EnumValueEditFormBuild(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName,l_iEnumValuePk,"",AllTrim(l_aSQLResult[1,4]),l_aSQLResult[1,5],l_aSQLResult[1,6],l_aSQLResult[1,7])
                //static function EnumValueEditFormBuild(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,par_iPk,par_cErrorText,par_cName,par_iNumber,par_iStatus,par_cDescription)
            else
                //Post
                l_cHtml += EnumValueEditFormOnSubmit(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
            endif
        endif
    endif



case l_cURLAction == "ListNameSpaces"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += NameSpacesListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewNameSpace"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    if oFcgi:isGet()
        l_cHtml += NameSpaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,0)
    else
        //Post
        l_cHtml += NameSpaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

case l_cURLAction == "EditNameSpace"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("NameSpace")
        :Column("NameSpace.pk"          , "Pk")
        :Column("NameSpace.Name"        , "Name")
        :Column("NameSpace.Status"      , "Status")
        :Column("NameSpace.Description" , "Description")
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_cHtml += NameSpaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_aSQLResult[1,1],"",AllTrim(l_aSQLResult[1,2]),l_aSQLResult[1,3],l_aSQLResult[1,4])
        else
            //Post
            l_cHtml += NameSpaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListVersions"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    //_M_

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
static function EnumerationImplementAsInfo(par_ImplementAs,par_ImplementLength)
local l_cResult
do case
case par_ImplementAs == 1
    l_cResult := [SQL Enum]
case par_ImplementAs == 2
    l_cResult := [Integer]
case par_ImplementAs == 3
    l_cResult := [Numeric ]+Trans(par_ImplementLength)+[ digit]+iif(par_ImplementLength > 1,[s],[])
case par_ImplementAs == 4
    l_cResult := [String ]+Trans(par_ImplementLength)+[ character]+iif(par_ImplementLength > 1,[s],[])
otherwise
    l_cResult := ""
endcase
return l_cResult
//=================================================================================================================
static function FormatColumnTypeInfo(par_cColumnType,par_iColumnLength,par_iColumnScale,par_cEnumerationName,par_iEnumerationImplementAs,par_iEnumerationImplementLength,;
                                    par_cSitePath,par_cURLApplicationLinkCode,par_cURLNameSpaceName)
local l_cResult
local l_iTypePos

// Altd()
l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[1] == par_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
if l_iTypePos > 0
    l_cResult := par_cColumnType+" "+oFcgi:p_ColumnTypes[l_iTypePos,2]
    do case
    case oFcgi:p_ColumnTypes[l_iTypePos,4] .and. oFcgi:p_ColumnTypes[l_iTypePos,3]  // Length and Scale
        l_cResult += [ (]+iif(hb_isnil(par_iColumnLength),"",Trans(par_iColumnLength))+[,]+iif(hb_isnil(par_iColumnScale),"",Trans(par_iColumnScale))+[)]

    case oFcgi:p_ColumnTypes[l_iTypePos,4]  // Scale
        l_cResult += [ (Scale: ]+iif(hb_isnil(par_iColumnScale),"",Trans(par_iColumnScale))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,3]  // Length
        l_cResult += [ (]+iif(hb_isnil(par_iColumnLength),"",Trans(par_iColumnLength))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,5]  // Enumeration
        if !hb_isnil(par_cEnumerationName) .and. !hb_isnil(par_iEnumerationImplementAs) //.and. !hb_isnil(par_iEnumerationImplementLength)
            l_cResult += [ (]
            l_cResult += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+par_cSitePath+[Applications/ListEnumValues/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+[/]+par_cEnumerationName+[/">]
            l_cResult += par_cEnumerationName
            l_cResult += [</a>]
            l_cResult += [ - ]

            do case
            case par_iEnumerationImplementAs == 1
                l_cResult += [SQL Enum)]
            case par_iEnumerationImplementAs == 2
                l_cResult += [Integer)]
            case par_iEnumerationImplementAs == 3
                l_cResult += [Numeric ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ digit]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
            case par_iEnumerationImplementAs == 4
                l_cResult += [String ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ character]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
            endcase

        endif
    endcase
else
    l_cResult := ""
endif

return l_cResult
//=================================================================================================================
static function ApplicationHeaderBuild(par_iApplicationPk,par_cApplicationName,par_cApplicationElement,par_cSitePath,par_cURLApplicationLinkCode,par_lActiveHeader)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand text-white">Manage Application - ]+par_cApplicationName+[</span>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-2"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("Table")
            :Column("Count(*)","Total")
            :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cApplicationElement == "TABLES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListTables/]+par_cURLApplicationLinkCode+[/">Tables (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("Enumeration")
            :Column("Count(*)","Total")
            :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "ENUMERATIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Enumerations (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("NameSpace")
            :Column("Count(*)","Total")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "NAMESPACES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListNameSpaces/]+par_cURLApplicationLinkCode+[/">Name Spaces (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "VERSIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListVersions/]+par_cURLApplicationLinkCode+[/">Versions</a>]
    l_cHtml += [</li>]
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ApplicationSettings/]+par_cURLApplicationLinkCode+[/">Application Settings</a>]
    l_cHtml += [</li>]
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "LOADSCHEMA",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ApplicationLoadSchema/]+par_cURLApplicationLinkCode+[/">Load/Sync Schema</a>]
    l_cHtml += [</li>]
l_cHtml += [</ul>]

l_cHtml += [<div class="m-2"></div>]

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ApplicationsListFormBuild()
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Application.LinkCode"   ,"Application_LinkCode")
    :Column("Application.Status"     ,"Application_Status")
    :Column("Application.Description","Application_Description")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfApplications")
endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfApplications

    if eof()
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No application on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name/Manage</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ListTables/]+AllTrim(ListOfApplications->Application_LinkCode)+[/">]+Allt(ListOfApplications->Application_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfApplications->Application_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfApplications->Application_Status,1,4),ListOfApplications->Application_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

CloseAlias("ListOfApplications")

return l_cHtml
//=================================================================================================================
static function ApplicationEditFormBuild(par_iPk,par_cErrorText,par_cName,par_cLinkCode,par_iStatus,par_cDescription)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_cName        := hb_DefaultValue(par_cName,"")
local l_cLinkCode    := hb_DefaultValue(par_cLinkCode,"")
local l_iStatus      := hb_DefaultValue(par_iStatus,1)
local l_cDescription := hb_DefaultValue(par_cDescription,"")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif


l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand mr-3">New Application</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand mr-3">Update Application Settings</span>]   //navbar-text
        endif
        l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-2">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Link Code</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextLinkCode" id="TextLinkCode" value="]+FcgiPrepFieldForValue(l_cLinkCode)+[" maxlength="10" size="10" style="text-transform: uppercase;"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
                l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
                l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ApplicationEditFormOnSubmit(par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationLinkCode
local l_iApplicationStatus
local l_cApplicationDescription

local l_cErrorMessage := ""
local l_oDB1

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationPk             := Val(oFcgi:GetInputValue("TableKey"))
l_cApplicationName           := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cApplicationLinkCode       := Upper(Strtran(SanitizeInput(oFcgi:GetInputValue("TextLinkCode"))," ",""))
l_iApplicationStatus         := Val(oFcgi:GetInputValue("ComboStatus"))
l_cApplicationDescription    := SanitizeInput(oFcgi:GetInputValue("TextDescription"))

do case
case l_cActionOnSubmit == "Save"

    do case
    case empty(l_cApplicationName)
        l_cErrorMessage := "Missing Name"
    case empty(l_cApplicationLinkCode)
        l_cErrorMessage := "Missing Link Code"
    otherwise
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Application")
            :Where([lower(replace(Application.Name,' ','')) = ^],lower(StrTran(l_cApplicationName," ","")))
            if l_iApplicationPk > 0
                :Where([Application.pk != ^],l_iApplicationPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("Application")
                :Where([upper(replace(Application.LinkCode,' ','')) = ^],l_cApplicationLinkCode)
                if l_iApplicationPk > 0
                    :Where([Application.pk != ^],l_iApplicationPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Link Code"
            else
                //Save the Application
                with object l_oDB1
                    :Table("Application")
                    :Field("Name"        , l_cApplicationName)
                    :Field("LinkCode"    , l_cApplicationLinkCode)
                    :Field("Status"      , l_iApplicationStatus)
                    :Field("Description" , iif(empty(l_cApplicationDescription),NULL,l_cApplicationDescription))
                    if empty(l_iApplicationPk)
                        :Add()
                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+l_cApplicationLinkCode+"/")
                    else
                        :Update(l_iApplicationPk)
                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+l_cApplicationLinkCode+"/")
                    endif
                endwith
            endif
        endif
    endcase

case l_cActionOnSubmit == "Cancel"
    if empty(l_iApplicationPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/")
    endif

case l_cActionOnSubmit == "Delete"   // Application
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("NameSpace")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :SQL()
    endwith

    if l_oDB1:Tally == 0
        with object l_oDB1
            :Table("Version")
            :Where("Version.fk_Application = ^",l_iApplicationPk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            l_oDB1:Table("Application")
            l_oDB1:Delete(l_iApplicationPk)

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/")
        else
            l_cErrorMessage := "Related Version record on file"
        endif
    else
        l_cErrorMessage := "Related Name Space record on file"
    endif

endcase

if !empty(l_cErrorMessage)
    l_cHtml += ApplicationEditFormBuild(l_iApplicationPk,l_cErrorMessage,l_cApplicationName,l_cApplicationLinkCode,l_iApplicationStatus,l_cApplicationDescription)
endif

return l_cHtml

return nil
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function NameSpacesListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("NameSpace")
    :Column("NameSpace.pk"         ,"pk")
    :Column("NameSpace.Name"       ,"NameSpace_Name")
    :Column("NameSpace.Status"     ,"NameSpace_Status")
    :Column("NameSpace.Description","NameSpace_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNameSpaces")
endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfNameSpaces
    if eof()
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">No Name Space on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewNameSpace/]+par_cURLApplicationLinkCode+[/">New Name Space</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">List of Name Spaces</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewNameSpace/]+par_cURLApplicationLinkCode+[/">New Name Space</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditNameSpace/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfNameSpaces->NameSpace_Name)+[/">]+Allt(ListOfNameSpaces->NameSpace_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfNameSpaces->NameSpace_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfNameSpaces->NameSpace_Status,1,4),ListOfNameSpaces->NameSpace_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

CloseAlias("ListOfNameSpaces")

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function NameSpaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,par_cErrorText,par_cName,par_iStatus,par_cDescription)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_cName        := hb_DefaultValue(par_cName,"")
local l_iStatus      := hb_DefaultValue(par_iStatus,1)
local l_cDescription := hb_DefaultValue(par_cDescription,"")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Name Space</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div class="m-3"></div>]


l_cHtml += [<div class="m-2">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pr-2 pb-3">Name</td>]
    l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pr-2 pb-3">Status</td>]
    l_cHtml += [<td class="pb-3">]

    l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
    l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
    l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
    l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
    l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
    l_cHtml += [</select>]

    l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
    l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
    l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function NameSpaceEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iNameSpacePk
local l_cNameSpaceName
local l_iNameSpaceStatus
local l_cNameSpaceDescription

local l_cErrorMessage := ""
local l_oDB1

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iNameSpacePk          := Val(oFcgi:GetInputValue("TableKey"))
l_cNameSpaceName        := SanitizeInput(Strtran(oFcgi:GetInputValue("TextName")," ",""))
l_iNameSpaceStatus      := Val(oFcgi:GetInputValue("ComboStatus"))
l_cNameSpaceDescription := SanitizeInput(oFcgi:GetInputValue("TextDescription"))

do case
case l_cActionOnSubmit == "Save"
    if empty(l_cNameSpaceName)
        l_cErrorMessage := "Missing Name"
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("NameSpace")
            :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cNameSpaceName," ","")))
            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
            if l_iNameSpacePk > 0
                :Where([NameSpace.pk != ^],l_iNameSpacePk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            //Save the Name Space
            with object l_oDB1
                :Table("NameSpace")
                :Field("Name"        , l_cNameSpaceName)
                :Field("Status"      , l_iNameSpaceStatus)
                :Field("Description" , iif(empty(l_cNameSpaceDescription),NULL,l_cNameSpaceDescription))
                if empty(l_iNameSpacePk)
                    :Field("fk_Application" , par_iApplicationPk)
                    :Add()
                else
                    :Update(l_iNameSpacePk)
                endif
            endwith

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")  //+l_cNameSpaceName+"/"
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // NameSpace
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Table")
        :Where("table.fk_NameSpace = ^",l_iNameSpacePk)
        :SQL()
    endwith

    if l_oDB1:Tally == 0
        with object l_oDB1
            :Table("Enumeration")
            :Where("Enumeration.fk_NameSpace = ^",l_iNameSpacePk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            l_oDB1:Table("NameSpace")
            l_oDB1:Delete(l_iNameSpacePk)

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")
        else
            l_cErrorMessage := "Related Enumeration record on file"
        endif
    else
        l_cErrorMessage := "Related Table record on file"
    endif

endcase

if !empty(l_cErrorMessage)
    l_cHtml += NameSpaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_iNameSpacePk,l_cErrorMessage,l_cNameSpaceName,l_iNameSpaceStatus,l_cNameSpaceDescription)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TablesListFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_cTableName
local l_cColumnName
local l_cURL

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cTableName  := SanitizeInput(oFcgi:GetInputValue("TextTableName"))
l_cColumnName := SanitizeInput(oFcgi:GetInputValue("TextColumnName"))

l_cURL := oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/"

do case
case l_cActionOnSubmit == "Search"
    l_cURL += [Search?TableName=]+hb_StrToHex(l_cTableName)
    l_cURL += [&ColumnName=]+hb_StrToHex(l_cColumnName)
    
    SendToClipboard(l_cURL)

    oFcgi:Redirect(l_cURL)

case l_cActionOnSubmit == "Reset"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += TablesListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

endcase

return l_cHtml
//=================================================================================================================
static function TablesListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_oDB3
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iColumnCount
local l_iIndexCount

local l_cSearchTableName
local l_cSearchColumnName

l_cSearchTableName  := hb_HexToStr(oFcgi:GetQueryString("TableName"))
l_cSearchColumnName := hb_HexToStr(oFcgi:GetQueryString("ColumnName"))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)

With Object l_oDB1
    :Table("Table")
    :Column("Table.pk"         ,"pk")
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.Status"     ,"Table_Status")
    :Column("Table.Description","Table_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Table.Name)","tag2")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)

    if !empty(l_cSearchTableName)
        :Where("upper(Table.Name) Like '%"+upper(l_cSearchTableName)+"%'")
    endif

    if !empty(l_cSearchColumnName)
        :Distinct(.t.)
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Where("upper(Column.Name) Like '%"+upper(l_cSearchColumnName)+"%'")
    endif

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfTables")
endwith

//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
With Object l_oDB2
    :Table("Table")
    :Column("Table.pk" ,"Table_pk")
    :Column("Count(*)" ,"ColumnCount")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Table.pk")
    :SQL("ListOfTablesColumnCounts")

    With Object :p_oCursor
        :Index("tag1","Table_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

With Object l_oDB3
    :Table("Table")
    :Column("Table.pk" ,"Table_pk")
    :Column("Count(*)" ,"IndexCount")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Index","","Index.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Table.pk")
    :SQL("ListOfTablesIndexCounts")

    With Object :p_oCursor
        :Index("tag1","Table_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfTables

    if eof()
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">No Table on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewTable/]+par_cURLApplicationLinkCode+[/">New Table</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            // l_cHtml += [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">List of Tables</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewTable/]+par_cURLApplicationLinkCode+[/">New Table</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    endif


    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
    l_cHtml += [<input type="hidden" name="formname" value="List">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">Search</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]

            l_cHtml += [<span class="mr-2">Table Name</span><input type="text" name="TextTableName" size="30" maxlength="100" value="]  +FcgiPrepFieldForValue(l_cSearchTableName)+[" class="mr-5">]
            l_cHtml += [<span class="mr-2">Column Name</span><input type="text" name="TextColumnName" size="30" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+[">]

        l_cHtml += [</div>]

        // l_cHtml += [<div class="input-group">]
        //     l_cHtml += [Table Name <input type="text" name="TextTableName" size="30" maxlength="100" value="]  +FcgiPrepFieldForValue(l_cSearchTableName)+["><br>]
        //     l_cHtml += [Column Name <input type="text" name="TextColumnName" size="30" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+["><br>]
        // l_cHtml += [</div>]

    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [</form>]

    if !eof()
        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name Space</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Table Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Columns</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Indexes</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfTables->NameSpace_Name)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditTable/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+Allt(ListOfTables->Table_Name)+[/">]+Allt(ListOfTables->Table_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_iColumnCount := iif( VFP_Seek(ListOfTables->pk,"ListOfTablesColumnCounts","tag1") , ListOfTablesColumnCounts->ColumnCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ListColumns/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+Allt(ListOfTables->Table_Name)+[/">Columns (]+Trans(l_iColumnCount)+[)</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_iIndexCount := iif( VFP_Seek(ListOfTables->pk,"ListOfTablesIndexCounts","tag1") , ListOfTablesIndexCounts->IndexCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ListIndexes/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+Allt(ListOfTables->Table_Name)+[/">Indexes (]+Trans(l_iIndexCount)+[)</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfTables->Table_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfTables->Table_Status,1,4),ListOfTables->Table_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,par_cErrorText,par_iNameSpacePk,par_cName,par_iStatus,par_cDescription)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_iNameSpacePk := hb_DefaultValue(par_iNameSpacePk,0)
local l_cName        := hb_DefaultValue(par_cName,"")
local l_iStatus      := hb_DefaultValue(par_iStatus,1)
local l_cDescription := hb_DefaultValue(par_cDescription,"")

local l_oDB1

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("NameSpace")
    :Column("NameSpace.pk"         ,"pk")
    :Column("NameSpace.Name"       ,"NameSpace_Name")
    :Column("Upper(NameSpace.Name)","tag1")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNameSpaces")
endwith

if l_oDB1:Tally <= 0
    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+[You must setup at least one Name Space first]+[</div>]

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Table</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Ok" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
else

    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    if !empty(l_cErrorText)
        l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Table</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
            if !empty(par_iPk)
                l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-2">]

        l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Name Space</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboNameSpacePk" id="ComboNameSpacePk">]
            select ListOfNameSpaces
            scan all
                l_cHtml += [<option value="]+Trans(ListOfNameSpaces->pk)+["]+iif(ListOfNameSpaces->pk = par_iNameSpacePk,[ selected],[])+[>]+AllTrim(ListOfNameSpaces->NameSpace_Name)+[</option>]
            endscan
            l_cHtml += [</select>]
        l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Table Name</td>]
        l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Status</td>]
        l_cHtml += [<td class="pb-3">]

        l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
        l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
        l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
        l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
        l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
        l_cHtml += [</select>]

        l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [</table>]
        
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextName').focus();]

    oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalForms()
endif

return l_cHtml
//=================================================================================================================
static function TableEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTablePk
local l_iNameSpacePk
local l_cTableName
local l_iTableStatus
local l_cTableDescription

local l_cErrorMessage := ""
local l_oDB1

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTablePk          := Val(oFcgi:GetInputValue("TableKey"))
l_iNameSpacePk      := Val(oFcgi:GetInputValue("ComboNameSpacePk"))
l_cTableName        := SanitizeInput(Strtran(oFcgi:GetInputValue("TextName")," ",""))
l_iTableStatus      := Val(oFcgi:GetInputValue("ComboStatus"))
l_cTableDescription := SanitizeInput(oFcgi:GetInputValue("TextDescription"))

do case
case l_cActionOnSubmit == "Save"
    if empty(l_cTableName)
        l_cErrorMessage := "Missing Name"
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Table")
            :Column("Table.pk","pk")
            :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
            :Where([Table.fk_NameSpace = ^],l_iNameSpacePk)
            :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cTableName," ","")))
            if l_iTablePk > 0
                :Where([Table.pk != ^],l_iTablePk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            //Save the Table
            with object l_oDB1
                :Table("Table")
                :Field("fk_NameSpace", l_iNameSpacePk)
                :Field("Name"        , l_cTableName)
                :Field("Status"      , l_iTableStatus)
                :Field("Description" , iif(empty(l_cTableDescription),NULL,l_cTableDescription))
                if empty(l_iTablePk)
                    :Add()
                else
                    :Update(l_iTablePk)
                endif
            endwith

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/")  //+l_cTableName+"/"
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // Table
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Column")
        :Where("Column.fk_Table = ^",l_iTablePk)
        :SQL()
    endwith

    if l_oDB1:Tally == 0
        with object l_oDB1
            :Table("Column")
            :Where("Column.fk_TableForeign = ^",l_iTablePk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            with object l_oDB1
                :Table("Index")
                :Where("Index.fk_Table = ^",l_iTablePk)
                :SQL()
            endwith

            if l_oDB1:Tally == 0
                l_oDB1:Table("Table")
                l_oDB1:Delete(l_iTablePk)

                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/")
            else
                l_cErrorMessage := "Related Index record on file"
            endif
        else
            l_cErrorMessage := "Related Column record on file (Foreign Key Link)"
        endif
    else
        l_cErrorMessage := "Related Column record on file"
    endif

endcase

if !empty(l_cErrorMessage)
    l_cHtml += TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_iTablePk,l_cErrorMessage,l_iNameSpacePk,l_cTableName,l_iTableStatus,l_cTableDescription)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//123456
static function ColumnListFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("Column")
    :Column("Column.pk"             ,"pk")
    :Column("Column.Name"           ,"Column_Name")
    :Column("Column.Status"         ,"Column_Status")
    :Column("Column.Description"    ,"Column_Description")
    :Column("Column.Order"          ,"Column_Order")
    :Column("Column.Type"           ,"Column_Type")
    :Column("Column.Length"         ,"Column_Length")
    :Column("Column.Scale"          ,"Column_Scale")
    :Column("Column.Nullable"       ,"Column_Nullable")
    :Column("Column.UsedBy"         ,"Column_UsedBy")
    :Column("Column.fk_TableForeign","Column_fk_TableForeign")
    :Column("Column.fk_Enumeration" ,"Column_fk_Enumeration")

    :Column("NameSpace.Name"                ,"NameSpace_Name")
    :Column("Table.Name"                    ,"Table_Name")
    :Column("Enumeration.Name"              ,"Enumeration_Name")
    :Column("Enumeration.ImplementAs"       ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength"   ,"Enumeration_ImplementLength")
    
    :Join("left","Table"      ,"","Column.fk_TableForeign = Table.pk")
    :Join("left","NameSpace"  ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("left","Enumeration","","Column.fk_Enumeration  = Enumeration.pk")
    :Where("Column.fk_Table = ^",par_iTablePk)
    :OrderBy("Column_Order")
    :SQL("ListOfColumns")

    // ExportTableToHtmlFile("ListOfColumns","d:\PostgreSQL_ListOfColumns.html","From PostgreSQL",,25,.t.)

endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfColumns

    if eof()
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">No Column on file for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+[".</span>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/NewColumn/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Column</a>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">List of Columns for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+["</span>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/NewColumn/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Column</a>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/OrderColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Order List of Columns</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Nullable</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Foreign Key To</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Used By</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        // Name
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditColumn/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+[/]+Allt(ListOfColumns->Column_Name)+[/">]+Allt(ListOfColumns->Column_Name)+[</a>]
                        l_cHtml += [</td>]

                        // Type
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += FormatColumnTypeInfo(allt(ListOfColumns->Column_Type),;
                                                            ListOfColumns->Column_Length,;
                                                            ListOfColumns->Column_Scale,;
                                                            ListOfColumns->Enumeration_Name,;
                                                            ListOfColumns->Enumeration_ImplementAs,;
                                                            ListOfColumns->Enumeration_ImplementLength,;
                                                            l_cSitePath,;
                                                            par_cURLApplicationLinkCode,;
                                                            par_cURLNameSpaceName)
                        l_cHtml += [</td>]

                        // Nullable
                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            l_cHtml += iif(alltrim(ListOfColumns->Column_Nullable) == "1",[<i class="fas fa-check"></i>],[&nbsp;])
                        l_cHtml += [</td>]

                        // Foreign Key To
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            if !hb_isNil(ListOfColumns->Table_Name)
                                l_cHtml += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+l_cSitePath+[Applications/ListColumns/]+par_cURLApplicationLinkCode+"/"+ListOfColumns->NameSpace_Name+"/"+ListOfColumns->Table_Name+[/">]
                                l_cHtml += ListOfColumns->NameSpace_Name+[.]+ListOfColumns->Table_Name
                                l_cHtml += [</a>]
                            endif
                        l_cHtml += [</td>]

                        // Used By
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += GetItemInListAtPosition(ListOfColumns->Column_UsedBy,{"All Servers","MySQL Only","PostgreSQL Only"},"")
                        l_cHtml += [</td>]

                        // Description
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfColumns->Column_Description,""))
                        l_cHtml += [</td>]

                        // Status
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfColumns->Column_Status,1,4),ListOfColumns->Column_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

CloseAlias("ListOfColumns")

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnOrderFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iTablePk)+[">]
l_cHtml += [<input type="hidden" name="ColumnOrder" id="ColumnOrder" value="">]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("Column")
    :Column("Column.pk"         ,"pk")
    :Column("Column.Name"       ,"Column_Name")
    :Column("Column.Order"      ,"Column_Order")
    :Where("Column.fk_Table = ^",par_iTablePk)
    :OrderBy("Column_order")
    :SQL("ListOfColumns")
endwith

l_cHtml += [<style>]
l_cHtml += [#sortable { list-style-type: none; margin: 0; padding: 0; }]
// The width: 60%;  will fail due to Bootstrap
l_cHtml += [#sortable li { margin: 3px 5px 3px 5px; padding: 2px 5px 5px 5px; font-size: 1.2em; height: 1.5em; line-height: 1.2em;}]   //display:block;   width:200px;
l_cHtml += [.ui-state-highlight { height: 1.5em; line-height: 1.2em; } ]
l_cHtml += [</style>]


l_cHtml += [<script language="javascript">]
l_cHtml += [function SendOrderList() {]
l_cHtml += [var EnumOrderData = $('#sortable').sortable('serialize', { key: 'sort' });]
l_cHtml += [$('#ColumnOrder').val(EnumOrderData);]
l_cHtml += [$('#ActionOnSubmit').val('Save');]
l_cHtml += [document.form.submit();]
l_cHtml += [}; ]
l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [$( "#sortable" ).sortable({]
oFcgi:p_cjQueryScript +=   [axis: "y",]
oFcgi:p_cjQueryScript +=   [placeholder: "ui-state-highlight"]
oFcgi:p_cjQueryScript += [});]
oFcgi:p_cjQueryScript += [$( "#sortable" ).disableSelection();]
//The following line sets the width of all the "li" to the max width of the same "li"s. This fixes a bug in .sortable with dragging the widest "li"
oFcgi:p_cjQueryScript += [$('#sortable li').width( Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()) );]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfColumns

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">Order Columns for Table "]+par_cURLNameSpaceName+[.]+par_cURLTableName+["</span>]
            l_cHtml += [<input type="button" class="btn btn-primary mr-3" value="Save" onclick="SendOrderList();" role="button">]
            l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/ListColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Cancel</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center">]
        l_cHtml += [<div class="col-auto">]

        l_cHtml += [<ul id="sortable">]
        scan all
            l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfColumns->pk)+["><span class="fas fa-arrows-alt-v"></span><span> ]+Allt(ListOfColumns->Column_Name)+[</span></li>]
        endscan
        l_cHtml += [</ul>]

        l_cHtml += [</div>]
    l_cHtml += [</div>]

l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function ColumnOrderFormOnSubmit(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTablePk
local l_cColumnPkOrder

local l_oDB1
local l_aOrderedPks
local l_Counter

l_cActionOnSubmit   := oFcgi:GetInputValue("ActionOnSubmit")
l_iTablePk    := Val(oFcgi:GetInputValue("TableKey"))
l_cColumnPkOrder := SanitizeInput(Strtran(oFcgi:GetInputValue("ColumnOrder")," ",""))

do case
case l_cActionOnSubmit == "Save"
    l_aOrderedPks := hb_ATokens(Strtran(substr(l_cColumnPkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Column")
        :Column("Column.pk","pk")
        :Column("Column.Order","order")
        :Where([Column.fk_Table = ^],l_iTablePk)
        :SQL("ListOfColumn")
  
        With Object :p_oCursor
            :Index("pk","pk")
            :CreateIndexes()
            :SetOrder("pk")
        endwith
  
    endwith

    for l_Counter := 1 to len(l_aOrderedPks)
        if VFP_Seek(val(l_aOrderedPks[l_Counter]),"ListOfColumn","pk") .and. ListOfColumn->order <> l_Counter
            with object l_oDB1
                :Table("Column")
                :Field("order",l_Counter)
                :Update(val(l_aOrderedPks[l_Counter]))
            endwith
        endif
    endfor

    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnEditFormBuild(par_iApplicationPk,par_iNameSpacePk,par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_iPk,par_cErrorText,;
                                    par_cName,par_iStatus,par_cDescription,;
                                    par_cType,par_iLength,par_iScale,par_iNullable,;
                                    par_iUsedBy,par_iFk_TableForeign,par_iFk_Enumeration)
local l_cHtml := ""
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")
local l_cName            := hb_DefaultValue(par_cName,"")
local l_iStatus          := hb_DefaultValue(par_iStatus,1)
local l_cDescription     := hb_DefaultValue(par_cDescription,"")
local l_cType            := Alltrim(hb_DefaultValue(par_cType,""))
local l_cLength          := iif(pcount() > 7 .and. !hb_IsNil(par_iLength),Trans(par_iLength),"")
local l_cScale           := iif(pcount() > 7 .and. !hb_IsNil(par_iScale) ,Trans(par_iScale),"")
local l_lNullable        := hb_DefaultValue(par_iNullable,.t.)
local l_iUsedBy          := hb_DefaultValue(par_iUsedBy,1)
local l_iFk_TableForeign := hb_DefaultValue(par_iFk_TableForeign,0)
local l_iFk_Enumeration  := hb_DefaultValue(par_iFk_Enumeration,0)

local l_iTypeCount
local l_aSQLResult   := {}

local l_oDBEnumeration := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDBTable := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDBEnumeration
    :Table("Enumeration")
    :Column("Enumeration.pk"              ,"Enumeration_pk")
    :Column("Enumeration.Name"            ,"Enumeration_Name")
    :Column("Enumeration.ImplementAs"     ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength" ,"Enumeration_ImplementLength")
    :Column("upper(Enumeration.Name)" , "tag1")
    :OrderBy("tag1")
    :Where("Enumeration.fk_NameSpace = ^" , par_iNameSpacePk)
    :SQL("ListOfEnumeration")
endwith

with object l_oDBTable
    :Table("Table")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Column("Table.pk"              , "Table_pk")
    :Column("NameSpace.Name"        , "NameSpace_Name")
    :Column("Table.Name"            , "Table_Name")
    :Column("upper(NameSpace.Name)" , "tag1")
    :Column("upper(Table.Name)"     , "tag2")
    :OrderBy("tag1")
    :OrderBy("tag2")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :SQL("ListOfTable")
endwith

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangeType(par_Value) {]

l_cHtml += [switch(par_Value) {]
for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
    l_cHtml += [  case ']+oFcgi:p_ColumnTypes[l_iTypeCount,1]+[':]
    l_cHtml += [  $('#SpanLength').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,3],[show],[hide])+[();$('#SpanScale').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,4],[show],[hide])+[();$('#SpanEnumeration').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,5],[show],[hide])+[();]
    l_cHtml += [    break;]
endfor
l_cHtml += [  default:]
l_cHtml += [  $('#SpanLength').hide();$('#SpanScale').hide();$('#SpanEnumeration').hide();]
l_cHtml += [};]

l_cHtml += [};]
l_cHtml += [</script>] 
oFcgi:p_cjQueryScript += [OnChangeType($("#ComboType").val());]



l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Column in Table "]+par_cURLNameSpaceName+[.]+par_cURLTableName+["</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div class="m-3"></div>]


l_cHtml += [<div class="m-2">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Type</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<span class="pr-5">]
                l_cHtml += [<select name="ComboType" id="ComboType" onchange="OnChangeType(this.value)">]
                for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
                    l_cHtml += [<option value="]+oFcgi:p_ColumnTypes[l_iTypeCount,1]+["]+iif(l_cType==oFcgi:p_ColumnTypes[l_iTypeCount,1],[ selected],[])+[>]+oFcgi:p_ColumnTypes[l_iTypeCount,1]+" - "+oFcgi:p_ColumnTypes[l_iTypeCount,2]+[</option>]
                endfor
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pr-5" id="SpanLength" style="display: none;">]
                l_cHtml += [<span class="pr-2">Length</span><input type="text" name="TextLength" id="TextLength" value="]+FcgiPrepFieldForValue(l_cLength)+[" size="5" maxlength="5">]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pr-5" id="SpanScale" style="display: none;">]
                l_cHtml += [<span class="pr-2">Scale</span><input type="text" name="TextScale" id="TextScale" value="]+FcgiPrepFieldForValue(l_cScale)+[" size="2" maxlength="2">]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pr-5" id="SpanEnumeration" style="display: none;">]
                l_cHtml += [<select name="ComboFk_Enumeration" id="ComboFk_Enumeration">]
                    l_cHtml += [<option value="0"]+iif(l_iFk_Enumeration==0,[ selected],[])+[></option>]
                    select ListOfEnumeration
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfEnumeration->Enumeration_pk)+["]+iif(ListOfEnumeration->Enumeration_pk == l_iFk_Enumeration,[ selected],[])+[>]+Allt(ListOfEnumeration->Enumeration_Name)+[ (]+EnumerationImplementAsInfo(ListOfEnumeration->Enumeration_ImplementAs,ListOfEnumeration->Enumeration_ImplementLength)+[)]+[</option>]
                    endscan
                l_cHtml += [</select>]
            l_cHtml += [</span>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Nullable</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<input type="checkbox" name="CheckNullable" id="CheckNullable" value="1"]+iif(l_lNullable," checked","")+[>]   // class="form-check-input"
        l_cHtml += [</td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Foreign Key To</td>]
        l_cHtml += [<td class="pb-3">]
            //fk_TableForeign
            l_cHtml += [<select name="ComboFk_TableForeign" id="ComboFk_TableForeign">]
                l_cHtml += [<option value="0"]+iif(l_iFk_TableForeign==0,[ selected],[])+[></option>]
                select ListOfTable
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfTable->Table_pk)+["]+iif(ListOfTable->Table_pk == l_iFk_TableForeign,[ selected],[])+[>]+Allt(ListOfTable->NameSpace_Name)+[.]+Allt(ListOfTable->Table_Name)+[</option>]
                endscan
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Used By</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboUsedBy" id="ComboUsedBy">]
            l_cHtml += [<option value="1"]+iif(l_iUsedBy==1,[ selected],[])+[>All Servers</option>]
            l_cHtml += [<option value="2"]+iif(l_iUsedBy==2,[ selected],[])+[>MySQL Only</option>]
            l_cHtml += [<option value="3"]+iif(l_iUsedBy==3,[ selected],[])+[>PostgreSQL Only</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pr-2 pb-3">Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
            l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
            l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
            l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
            l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    

l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [  <input class="form-check-input" type="checkbox" id="flexSwitchCheckDefault">]
l_cHtml += [  <label class="form-check-label" for="flexSwitchCheckDefault">Default switch checkbox input</label>]
l_cHtml += [</div>]
l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [  <input class="form-check-input" type="checkbox" id="flexSwitchCheckChecked" checked>]
l_cHtml += [  <label class="form-check-label" for="flexSwitchCheckChecked">Checked switch checkbox input</label>]
l_cHtml += [</div>]
l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [  <input class="form-check-input" type="checkbox" id="flexSwitchCheckDisabled" disabled>]
l_cHtml += [  <label class="form-check-label" for="flexSwitchCheckDisabled">Disabled switch checkbox input</label>]
l_cHtml += [</div>]
l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [  <input class="form-check-input" type="checkbox" id="flexSwitchCheckCheckedDisabled" checked disabled>]
l_cHtml += [  <label class="form-check-label" for="flexSwitchCheckCheckedDisabled">Disabled checked switch checkbox input</label>]
l_cHtml += [</div>]


l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ColumnEditFormOnSubmit(par_iApplicationPk,par_iNameSpacePk,par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iColumnPk
local l_cColumnName
local l_iColumnStatus
local l_cColumnDescription
local l_cColumnType
local l_cColumnLength
local l_iColumnLength
local l_cColumnScale
local l_iColumnScale
local l_lColumnNullable
local l_iColumnUsedBy
local l_iColumnFk_TableForeign
local l_iColumnFk_Enumeration

local l_iColumnOrder
local l_iTypePos   //The position in the oFcgi:p_ColumnTypes array

local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iColumnPk              := Val(oFcgi:GetInputValue("TableKey"))
l_cColumnName            := SanitizeInput(Strtran(oFcgi:GetInputValue("TextName")," ",""))
l_iColumnStatus          := Val(oFcgi:GetInputValue("ComboStatus"))
l_cColumnDescription     := SanitizeInput(oFcgi:GetInputValue("TextDescription"))


l_cColumnType            := SanitizeInput(Strtran(oFcgi:GetInputValue("ComboType")," ",""))

l_cColumnLength          := SanitizeInput(oFcgi:GetInputValue("TextLength"))
l_iColumnLength          := iif(empty(l_cColumnLength),NULL,val(l_cColumnLength))

l_cColumnScale           := SanitizeInput(oFcgi:GetInputValue("TextScale"))
l_iColumnScale           := iif(empty(l_cColumnScale),NULL,val(l_cColumnScale))

l_lColumnNullable        := (oFcgi:GetInputValue("CheckNullable") == "1")
Altd()

l_iColumnUsedBy          := Val(oFcgi:GetInputValue("ComboUsedBy"))

l_iColumnFk_TableForeign := Val(oFcgi:GetInputValue("ComboFk_TableForeign"))
if empty(l_iColumnFk_TableForeign)
    l_iColumnFk_TableForeign := NIL
endif

l_iColumnFk_Enumeration  := Val(oFcgi:GetInputValue("ComboFk_Enumeration"))
if empty(l_iColumnFk_Enumeration)
    l_iColumnFk_Enumeration := NIL
endif

do case
case l_cActionOnSubmit == "Save"
    if empty(l_cColumnName)
        l_cErrorMessage := "Missing Name"
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Column")
            :Column("Column.pk","pk")
            :Where([Column.fk_Table = ^],par_iTablePk)
            :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cColumnName," ","")))
            if l_iColumnPk > 0
                :Where([Column.pk != ^],l_iColumnPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[1] == l_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
            if l_iTypePos <= 0
                l_cErrorMessage := [Failed to find "Column Type" definition.]
            else
                
                do case
                case (oFcgi:p_ColumnTypes[l_iTypePos,3]) .and. hb_isnil(l_iColumnLength)   // Length should be entered
                    l_cErrorMessage := "Length is required!"
                    
                case (oFcgi:p_ColumnTypes[l_iTypePos,4]) .and. hb_isnil(l_iColumnScale)   // Scale should be entered
                    l_cErrorMessage := "Scale is required! Enter at the minimum 0"
                    
                case (oFcgi:p_ColumnTypes[l_iTypePos,3]) .and. (oFcgi:p_ColumnTypes[l_iTypePos,4]) .and. l_iColumnScale >= l_iColumnLength
                    l_cErrorMessage := "Scale must be smaller than Length!"

                case (oFcgi:p_ColumnTypes[l_iTypePos,5]) .and. hb_isnil(l_iColumnFk_Enumeration)   // Enumeration should be entered
                    l_cErrorMessage := "Select an Enumeration!"

                otherwise
                    //If adding a column, find out what the last order is
                    l_iColumnOrder := 1
                    if empty(l_iColumnPk)
                        with object l_oDB1
                            :Table("Column")
                            :Column("Column.Order","Column_Order")
                            :Where([Column.fk_Table = ^],par_iTablePk)
                            :OrderBy("Column_Order","Desc")
                            :Limit(1)
                            :SQL(@l_aSQLResult)
                        endwith

                        if l_oDB1:Tally > 0
                            l_iColumnOrder := l_aSQLResult[1,1] + 1
                        endif
                    endif

                    //Blank out any unneeded variable values
                    if l_iTypePos > 0  //Should always be the case unless version issue with browser page
                        if !(oFcgi:p_ColumnTypes[l_iTypePos,3])
                            l_iColumnLength := NIL
                        endif
                        if !(oFcgi:p_ColumnTypes[l_iTypePos,4])
                            l_iColumnScale := NIL
                        endif
                        if !(oFcgi:p_ColumnTypes[l_iTypePos,5])
                            l_iColumnFk_Enumeration := NIL
                        endif
                    endif


                    //Save the Column
                    with object l_oDB1
                        :Table("Column")
                        :Field("Name"            , l_cColumnName)
                        :Field("Status"          , l_iColumnStatus)
                        :Field("Description"     , iif(empty(l_cColumnDescription),NULL,l_cColumnDescription))

                        :Field("Type"            , l_cColumnType)
                        :Field("Length"          , l_iColumnLength)
                        :Field("Scale"           , l_iColumnScale)
                        :Field("Nullable"        , l_lColumnNullable)
                        :Field("UsedBy"          , l_iColumnUsedBy)
                        :Field("Fk_TableForeign" , l_iColumnFk_TableForeign)
                        :Field("Fk_Enumeration"  , l_iColumnFk_Enumeration)
                    
                        if empty(l_iColumnPk)
                            :Field("fk_Table" , par_iTablePk)
                            :Field("Order"    ,l_iColumnOrder)
                            :Add()
                        else
                            :Update(l_iColumnPk)
                        endif
                    endwith

                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

                endcase
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

case l_cActionOnSubmit == "Delete"   // Column
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("IndexColumn")
        :Where("IndexColumn.fk_Column = ^",l_iColumnPk)
        :SQL()
    endwith

    if l_oDB1:Tally == 0
        l_oDB1:Table("Column")
        l_oDB1:Delete(l_iColumnPk)

        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

    else
        l_cErrorMessage := "Related Index Expression record on file"

    endif

endcase

if !empty(l_cErrorMessage)
    l_cHtml += ColumnEditFormBuild(par_iApplicationPk,par_iNameSpacePk,par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,l_iColumnPk,l_cErrorMessage,;
                                   l_cColumnName,l_iColumnStatus,l_cColumnDescription,;
                                   l_cColumnType,l_iColumnLength,l_iColumnScale,l_lColumnNullable,;
                                   l_iColumnUsedBy,l_iColumnFk_TableForeign,l_iColumnFk_Enumeration)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumerationsListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_iEnumValueCount

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("Enumeration")
    :Column("Enumeration.pk"             ,"pk")
    :Column("NameSpace.Name"             ,"NameSpace_Name")
    :Column("Enumeration.Name"           ,"Enumeration_Name")
    :Column("Enumeration.Status"         ,"Enumeration_Status")
    :Column("Enumeration.Description"    ,"Enumeration_Description")
    :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Enumeration.Name)","tag2")
    :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfEnumerations")
endwith

With Object l_oDB2
    :Table("Enumeration")
    :Column("Enumeration.pk" ,"Enumeration_pk")
    :Column("Count(*)" ,"EnumValueCount")
    :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
    :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Enumeration.pk")
    :SQL("ListOfEnumerationsEnumValueCounts")

    With Object :p_oCursor
        :Index("tag1","Enumeration_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfEnumerations

    if eof()
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">No Enumeration on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewEnumeration/]+par_cURLApplicationLinkCode+[/">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            // l_cHtml += [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">List of Enumerations</span>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/NewEnumeration/]+par_cURLApplicationLinkCode+[/">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name Space</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Enumeration Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Implemented As</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Values</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfEnumerations->NameSpace_Name)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditEnumeration/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfEnumerations->NameSpace_Name)+[/]+Allt(ListOfEnumerations->Enumeration_Name)+[/">]+Allt(ListOfEnumerations->Enumeration_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]+EnumerationImplementAsInfo(ListOfEnumerations->Enumeration_ImplementAs,ListOfEnumerations->Enumeration_ImplementLength)+[</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_iEnumValueCount := iif( VFP_Seek(ListOfEnumerations->pk,"ListOfEnumerationsEnumValueCounts","tag1") , ListOfEnumerationsEnumValueCounts->EnumValueCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfEnumerations->NameSpace_Name)+[/]+Allt(ListOfEnumerations->Enumeration_Name)+[/">Values (]+Trans(l_iEnumValueCount)+[)</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumerations->Enumeration_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfEnumerations->Enumeration_Status,1,4),ListOfEnumerations->Enumeration_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

CloseAlias("ListOfEnumerations")

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,par_cErrorText,par_iNameSpacePk,par_cName,par_iStatus,par_cDescription,par_iImplementAs,par_iImplementLength)
//12345
local l_cHtml := ""
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")
local l_iNameSpacePk     := hb_DefaultValue(par_iNameSpacePk,0)
local l_cName            := hb_DefaultValue(par_cName,"")
local l_iStatus          := hb_DefaultValue(par_iStatus,1)
local l_cDescription     := hb_DefaultValue(par_cDescription,"")
local l_iImplementAs     := hb_DefaultValue(par_iImplementAs,1)
local l_iImplementLength := hb_DefaultValue(par_iImplementLength,1)

local l_oDB1

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("NameSpace")
    :Column("NameSpace.pk"         ,"pk")
    :Column("NameSpace.Name"       ,"NameSpace_Name")
    :Column("Upper(NameSpace.Name)","tag1")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNameSpaces")
endwith

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangeImplementAs(par_Value) {]
l_cHtml += 'if (["3","4"].indexOf(par_Value) > -1) {$("#ImplementLengthEntry").show();} else {$("#ImplementLengthEntry").hide();};'
l_cHtml += [};]
l_cHtml += [</script>] 

oFcgi:p_cjQueryScript += [OnChangeImplementAs($("#ComboImplementAs").val());]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

if l_oDB1:Tally <= 0
    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+[You must setup at least one Name Space first]+[</div>]

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Enumeration</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Ok" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    if !empty(l_cErrorText)
        l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ Enumeration</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
            if !empty(par_iPk)
                l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-2">]

        l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Name Space</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select name="ComboNameSpacePk" id="ComboNameSpacePk">]
                select ListOfNameSpaces
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfNameSpaces->pk)+["]+iif(ListOfNameSpaces->pk = par_iNameSpacePk,[ selected],[])+[>]+AllTrim(ListOfNameSpaces->NameSpace_Name)+[</option>]
                endscan
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Enumeration Name</td>]
            l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Implement As</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<span class="pr-5">]
                    l_cHtml += [<select name="ComboImplementAs" id="ComboImplementAs" onchange="OnChangeImplementAs(this.value);">]
                        l_cHtml += [<option value="1"]+iif(l_iImplementAs==1,[ selected],[])+[>SQL Enum</option>]
                        l_cHtml += [<option value="2"]+iif(l_iImplementAs==2,[ selected],[])+[>Integer</option>]
                        l_cHtml += [<option value="3"]+iif(l_iImplementAs==3,[ selected],[])+[>Numeric</option>]
                        l_cHtml += [<option value="4"]+iif(l_iImplementAs==4,[ selected],[])+[>String (EnumValue Name)</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

            l_cHtml += [<span class="pr-5" id="ImplementLengthEntry" style="display: none;">]
                l_cHtml += [<span class="pr-2">Length</span><input type="text" size="5" maxlength="5" name="TextImplementLength" id="TextImplementLength" value="]+Trans(l_iImplementLength)+[">]
            l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pr-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
                    l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
                    l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
                l_cHtml += [</select>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [</table>]
        
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextName').focus();]

    oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalForms()
endif

return l_cHtml
//=================================================================================================================
static function EnumerationEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumerationPk
local l_iNameSpacePk
local l_cEnumerationName
local l_iEnumerationStatus
local l_cEnumerationDescription
local l_iEnumerationImplementAs
local l_iEnumerationImplementLength

local l_cErrorMessage := ""
local l_oDB1

// l_cFormName       := oFcgi:GetInputValue("formname")
l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumerationPk                := Val(oFcgi:GetInputValue("EnumerationKey"))
l_iNameSpacePk                  := Val(oFcgi:GetInputValue("ComboNameSpacePk"))
l_cEnumerationName              := SanitizeInput(Strtran(oFcgi:GetInputValue("TextName")," ",""))
l_iEnumerationStatus            := Val(oFcgi:GetInputValue("ComboStatus"))
l_cEnumerationDescription       := SanitizeInput(oFcgi:GetInputValue("TextDescription"))

l_iEnumerationImplementAs       := Val(oFcgi:GetInputValue("ComboImplementAs"))

l_iEnumerationImplementLength   := Val(SanitizeInput(oFcgi:GetInputValue("TextImplementLength")))
if l_iEnumerationImplementLength < 1
    l_iEnumerationImplementLength := 1
else
    if l_iEnumerationImplementLength > 99999
        l_iEnumerationImplementLength := 99999
    endif
endif

do case
case l_cActionOnSubmit == "Save"
    if empty(l_cEnumerationName)
        l_cErrorMessage := "Missing Name"
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Enumeration")
            :Column("Enumeration.pk","pk")
            :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
            :Where([Enumeration.fk_NameSpace = ^],l_iNameSpacePk)
            :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cEnumerationName," ","")))
            if l_iEnumerationPk > 0
                :Where([Enumeration.pk != ^],l_iEnumerationPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            //Save the Enumeration
            with object l_oDB1
                :Table("Enumeration")
                :Field("fk_NameSpace"     , l_iNameSpacePk)
                :Field("Name"             , l_cEnumerationName)
                :Field("Status"           , l_iEnumerationStatus)
                :Field("Description"      , iif(empty(l_cEnumerationDescription),NULL,l_cEnumerationDescription))
                :Field("ImplementAs"    , l_iEnumerationImplementAs)
                :Field("ImplementLength", iif(vfp_Inlist(l_iEnumerationImplementAs,3,4),l_iEnumerationImplementLength,NULL))
                if empty(l_iEnumerationPk)
                    :Add()
                else
                    :Update(l_iEnumerationPk)
                endif
            endwith

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumerations/"+par_cURLApplicationLinkCode+"/")  //+l_cEnumerationName+"/"
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumerations/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // Enumeration
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("Column")
        :Where("Column.fk_Enumeration = ^",l_iEnumerationPk)
        :SQL()
    endwith

    if l_oDB1:Tally == 0
        with object l_oDB1
            :Table("EnumValue")
            :Where("EnumValue.fk_Enumeration = ^",l_iEnumerationPk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            l_oDB1:Table("Enumeration")
            l_oDB1:Delete(l_iEnumerationPk)

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumerations/"+par_cURLApplicationLinkCode+"/")
        else
            l_cErrorMessage := "Related Enumeration Value record on file"
        endif
    else
        l_cErrorMessage := "Related Column record on file"
    endif

endcase

if !empty(l_cErrorMessage)
    l_cHtml += EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_iEnumerationPk,l_cErrorMessage,l_iNameSpacePk,l_cEnumerationName,l_iEnumerationStatus,l_cEnumerationDescription,l_iEnumerationImplementAs,l_iEnumerationImplementLength)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumValueListFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("EnumValue")
    :Column("EnumValue.pk"         ,"pk")
    :Column("EnumValue.Name"       ,"EnumValue_Name")
    :Column("EnumValue.Number"     ,"EnumValue_Number")
    :Column("EnumValue.Status"     ,"EnumValue_Status")
    :Column("EnumValue.Description","EnumValue_Description")
    :Column("EnumValue.Order"      ,"EnumValue_Order")
    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)
    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
endwith

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfEnumValues

    if eof()
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">No Value on file for Enumeration "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLEnumerationName)+[".</span>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/NewEnumValue/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">New Enumeration Value</a>]
                l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[Applications/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Back To Enumerations</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand mr-3">List of Values for Enumeration "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLEnumerationName)+["</span>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/NewEnumValue/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">New Enumeration Value</a>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Back To Enumerations</a>]
                l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/OrderEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Order List of Values</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Number</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-center text-white">Status</th>]
                l_cHtml += [</tr>]

                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditEnumValue/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+[/]+Allt(ListOfEnumValues->EnumValue_Name)+[/">]+Allt(ListOfEnumValues->EnumValue_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            if !hb_orm_isnull("ListOfEnumValues","EnumValue_Number")
                                l_cHtml += trans(ListOfEnumValues->EnumValue_Number)
                            endif
                            l_cHtml += hb_DefaultValue(ListOfEnumValues->EnumValue_Number,"")
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumValues->EnumValue_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Unknown","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfEnumValues->EnumValue_Status,1,4),ListOfEnumValues->EnumValue_Status,1)]
                            // 1 = Unknown, 2 = Active, 3 = Inactive (Read Only), 4 = Archived (Read Only and Hidden)
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

CloseAlias("ListOfEnumValues")

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iEnumerationPk)+[">]
l_cHtml += [<input type="hidden" name="ValueOrder" id="ValueOrder" value="">]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("EnumValue")
    :Column("EnumValue.pk"         ,"pk")
    :Column("EnumValue.Name"       ,"EnumValue_Name")
    :Column("EnumValue.Order"      ,"EnumValue_Order")
    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)
    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
endwith

l_cHtml += [<style>]
l_cHtml += [#sortable { list-style-type: none; margin: 0; padding: 0; }]
// The width: 60%;  will fail due to Bootstrap
l_cHtml += [#sortable li { margin: 3px 5px 3px 5px; padding: 2px 5px 5px 5px; font-size: 1.2em; height: 1.5em; line-height: 1.2em;}]   //display:block;   width:200px;
l_cHtml += [.ui-state-highlight { height: 1.5em; line-height: 1.2em; } ]
l_cHtml += [</style>]


l_cHtml += [<script language="javascript">]
l_cHtml += [function SendOrderList() {]
l_cHtml += [var EnumOrderData = $('#sortable').sortable('serialize', { key: 'sort' });]
// l_cHtml += [alert('hello 3 '+EnumOrderData);]
l_cHtml += [$('#ValueOrder').val(EnumOrderData);]
l_cHtml += [$('#ActionOnSubmit').val('Save');]
l_cHtml += [document.form.submit();]
l_cHtml += [}; ]
l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [$( "#sortable" ).sortable({]
oFcgi:p_cjQueryScript +=   [axis: "y",]
oFcgi:p_cjQueryScript +=   [placeholder: "ui-state-highlight"]
oFcgi:p_cjQueryScript += [});]
oFcgi:p_cjQueryScript += [$( "#sortable" ).disableSelection();]
//The following line sets the width of all the "li" to the max width of the same "li"s. This fixes a bug in .sortable with dragging the widest "li"
oFcgi:p_cjQueryScript += [$('#sortable li').width( Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()) );]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="m-2">]

    select ListOfEnumValues

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">Order Values for Enumeration "]+par_cURLNameSpaceName+[.]+par_cURLEnumerationName+["</span>]
            // l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Back To Enumeration Values</a>]
            l_cHtml += [<input type="button" class="btn btn-primary mr-3" value="Save" onclick="SendOrderList();" role="button">]
            // l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/OrderEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Cancel</a>]
            l_cHtml += [<a class="btn btn-primary mr-3" href="]+l_cSitePath+[Applications/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Cancel</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center">]
        l_cHtml += [<div class="col-auto">]

        l_cHtml += [<ul id="sortable">]
        scan all
            l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfEnumValues->pk)+["><span class="fas fa-arrows-alt-v"></span><span> ]+Allt(ListOfEnumValues->EnumValue_Name)+[</span></li>]
        endscan
        l_cHtml += [</ul>]

        l_cHtml += [</div>]
    l_cHtml += [</div>]

l_cHtml += [</div>]

// l_cHtml += [<button onclick="SendOrderList();">Get List</button>]

// l_cHtml += [<button onclick="var MaxLiWidth = Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()); alert('Max Width = '+MaxLiWidth);">Get List</button>]
// l_cHtml += [<button onclick="var MaxLiWidth = Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()); $('#sortable li').width(MaxLiWidth);return false;">Get List</button>]

//Set the width of all the "li" to the max width of the same "li"s. This fixes a bug in .sortable with dragging the widest "li"
// l_cHtml += [<button onclick="$('#sortable li').width( Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()) );return false;">Freeze Width</button>]

// var MaxLiWidth = Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()); alert('Max Width = '+MaxLiWidth);

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormOnSubmit(par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumerationPk
local l_cEnumValuePkOrder

local l_oDB1
local l_aOrderedPks
local l_Counter

l_cActionOnSubmit   := oFcgi:GetInputValue("ActionOnSubmit")
l_iEnumerationPk    := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValuePkOrder := SanitizeInput(Strtran(oFcgi:GetInputValue("ValueOrder")," ",""))

do case
case l_cActionOnSubmit == "Save"
    l_aOrderedPks := hb_ATokens(Strtran(substr(l_cEnumValuePkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("EnumValue")
        :Column("EnumValue.pk","pk")
        :Column("EnumValue.Order","order")
        :Where([EnumValue.fk_Enumeration = ^],l_iEnumerationPk)
        :SQL("ListOfEnumValue")

        With Object :p_oCursor
            :Index("pk","pk")
            :CreateIndexes()
            :SetOrder("pk")
        endwith

    endwith

    for l_Counter := 1 to len(l_aOrderedPks)
        if VFP_Seek(val(l_aOrderedPks[l_Counter]),"ListOfEnumValue","pk") .and. ListOfEnumValue->order <> l_Counter
            with object l_oDB1
                :Table("EnumValue")
                :Field("order",l_Counter)
                :Update(val(l_aOrderedPks[l_Counter]))
            endwith
        endif
    endfor

    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumValueEditFormBuild(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,par_iPk,par_cErrorText,par_cName,par_iNumber,par_iStatus,par_cDescription)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_cName        := hb_DefaultValue(par_cName,"")
local l_cNumber      := iif(pcount() > 6 .and. !hb_IsNil(par_iNumber),Trans(par_iNumber),"")
local l_iStatus      := hb_DefaultValue(par_iStatus,1)
local l_cDescription := hb_DefaultValue(par_cDescription,"")

local l_aSQLResult   := {}

// local l_ipcount := pcount()
// local l_test
// altd()
// l_test := HB_ISNIL(par_iNumber)
// l_cNumber      := iif(pcount() > 6 .and. !hb_IsNil(par_iNumber),Trans(par_iNumber),"")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand mr-3">]+iif(empty(par_iPk),"New","Edit")+[ EnumValue in Enumeration "]+par_cURLNameSpaceName+[.]+par_cURLEnumerationName+["</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary mr-5" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<input type="button" class="btn btn-primary ml-5" value="Delete" onclick="ConfirmDelete();" role="button">]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div class="m-3"></div>]


l_cHtml += [<div class="m-2">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pr-2 pb-3">Name</td>]
    l_cHtml += [<td class="pb-3"><input type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pr-2 pb-3">Number</td>]
    l_cHtml += [<td class="pb-3"><input type="text" name="TextNumber" id="TextNumber" value="]+FcgiPrepFieldForValue(l_cNumber)+[" maxlength="8" size="8"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pr-2 pb-3">Status</td>]
    l_cHtml += [<td class="pb-3">]

    l_cHtml += [<select name="ComboStatus" id="ComboStatus">]
    l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Unknown</option>]
    l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Active</option>]
    l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Inactive (Read Only)</option>]
    l_cHtml += [<option value="4"]+iif(l_iStatus==4,[ selected],[])+[>Archived (Read Only and Hidden)</option>]
    l_cHtml += [</select>]

    l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
    l_cHtml += [<td valign="top" class="pr-2 pb-3">Description</td>]
    l_cHtml += [<td class="pb-3"><textarea name="TextDescription" id="TextDescription" rows="5" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function EnumValueEditFormOnSubmit(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumValuePk
local l_cEnumValueName
local l_cEnumValueNumber,l_iEnumValueNumber
local l_iEnumValueStatus
local l_cEnumValueDescription
local l_iEnumValueOrder
local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumValuePk          := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValueName        := SanitizeInput(Strtran(oFcgi:GetInputValue("TextName")," ",""))

l_cEnumValueNumber      := SanitizeInput(oFcgi:GetInputValue("TextNumber"))
l_iEnumValueNumber      := iif(empty(l_cEnumValueNumber),NULL,val(l_cEnumValueNumber))

l_iEnumValueStatus      := Val(oFcgi:GetInputValue("ComboStatus"))
l_cEnumValueDescription := SanitizeInput(oFcgi:GetInputValue("TextDescription"))

do case
case l_cActionOnSubmit == "Save"
    if empty(l_cEnumValueName)
        l_cErrorMessage := "Missing Name"
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("EnumValue")
            :Column("EnumValue.pk","pk")
            :Where([EnumValue.fk_Enumeration = ^],par_iEnumerationPk)
            :Where([lower(replace(EnumValue.Name,' ','')) = ^],lower(StrTran(l_cEnumValueName," ","")))
            if l_iEnumValuePk > 0
                :Where([EnumValue.pk != ^],l_iEnumValuePk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"

        else
            //If adding an EnumValue, find out what the last order is
            l_iEnumValueOrder := 1
            if empty(l_iEnumValuePk)
                with object l_oDB1
                    :Table("EnumValue")
                    :Column("EnumValue.Order","EnumValue_Order")
                    :Where([EnumValue.fk_Enumeration = ^],par_iEnumerationPk)
                    :OrderBy("EnumValue_Order","Desc")
                    :Limit(1)
                    :SQL(@l_aSQLResult)
                endwith

                if l_oDB1:Tally > 0
                    l_iEnumValueOrder := l_aSQLResult[1,1] + 1
                endif
            endif

            //Save the Enumeration Value
            with object l_oDB1
                :Table("EnumValue")
                :Field("Name"        , l_cEnumValueName)
                :Field("Number"      , l_iEnumValueNumber)
                :Field("Status"      , l_iEnumValueStatus)
                :Field("Description" , iif(empty(l_cEnumValueDescription),NULL,l_cEnumValueDescription))
                if empty(l_iEnumValuePk)
                    :Field("fk_Enumeration" , par_iEnumerationPk)
                    :Field("Order"          ,l_iEnumValueOrder)
                    :Add()
                else
                    :Update(l_iEnumValuePk)
                endif
            endwith

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")

case l_cActionOnSubmit == "Delete"   // EnumValue
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB1:Table("EnumValue")
    l_oDB1:Delete(l_iEnumValuePk)

    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")

endcase

if !empty(l_cErrorMessage)
    l_cHtml += EnumValueEditFormBuild(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,l_iEnumValuePk,l_cErrorMessage,l_cEnumValueName,l_iEnumValueNumber,l_iEnumValueStatus,l_cEnumValueDescription)
endif

return l_cHtml
//=================================================================================================================











//=================================================================================================================
static function ApplicationLoadSchemaStep1FormBuild(par_iPk,par_cErrorText,par_cApplicationName,par_cLinkCode,;
                                                    par_iSyncBackendType,par_cSyncServer,par_iSyncPort,par_cSyncUser,par_cSyncPassword,par_cSyncDatabase,par_cSyncNameSpaces)

local l_cHtml := ""
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")
local l_cApplicationName := hb_DefaultValue(par_cApplicationName,"")
local l_cLinkCode        := hb_DefaultValue(par_cLinkCode,"")

local l_iSyncBackendType := hb_DefaultValue(par_iSyncBackendType,0)
local l_cSyncServer      := hb_DefaultValue(par_cSyncServer,"")
local l_iSyncPort        := hb_DefaultValue(par_iSyncPort,0)
local l_cSyncUser        := hb_DefaultValue(par_cSyncUser,"")
local l_cSyncPassword    := hb_DefaultValue(par_cSyncPassword,"")
local l_cSyncDatabase    := hb_DefaultValue(par_cSyncDatabase,"")
local l_cSyncNameSpaces  := hb_DefaultValue(par_cSyncNameSpaces,"")



l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Step1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

if !empty(par_iPk)
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand mr-3">Load Schema - Enter Connection Information</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Load" onclick="$('#ActionOnSubmit').val('Load');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary mr-2" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]


    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-2">]
        l_cHtml += [<table>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Server Type</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select name="ComboSyncBackendType" id="ComboSyncBackendType">]
                    l_cHtml += [<option value="0"]+iif(l_iSyncBackendType==0,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="1"]+iif(l_iSyncBackendType==1,[ selected],[])+[>MariaDB</option>]
                    l_cHtml += [<option value="2"]+iif(l_iSyncBackendType==2,[ selected],[])+[>MySQL</option>]
                    l_cHtml += [<option value="3"]+iif(l_iSyncBackendType==3,[ selected],[])+[>PostgreSQL</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Server Address/IP</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncServer" id="TextSyncServer" value="]+FcgiPrepFieldForValue(l_cSyncServer)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Port (If not default)</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="SyncPort" id="SyncPort" value="]+iif(empty(l_iSyncPort),"",Trans(l_iSyncPort))+[" maxlength="10" size="10"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">User Name</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncUser" id="TextSyncUser" value="]+FcgiPrepFieldForValue(l_cSyncUser)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Password</td>]
                l_cHtml += [<td class="pb-3"><input type="password" name="TextSyncPassword" id="TextSyncPassword" value="]+FcgiPrepFieldForValue(l_cSyncPassword)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Database</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncDatabase" id="TextSyncDatabase" value="]+FcgiPrepFieldForValue(l_cSyncDatabase)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pr-2 pb-3">Name Spaces<small><br>("schema" in PostgreSQL)<br>(optional, "," separated)</small></td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncNameSpaces" id="TextSyncNameSpaces" value="]+FcgiPrepFieldForValue(l_cSyncNameSpaces)+[" maxlength="400" size="80"></td>]
            l_cHtml += [</tr>]


        l_cHtml += [</table>]

    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#ComboSyncBackendType').focus();]

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalForms()
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ApplicationLoadSchemaStep1FormOnSubmit(par_iApplicationPk,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_iSyncBackendType
local l_cSyncServer
local l_iSyncPort
local l_cSyncUser
local l_cSyncPassword
local l_cSyncDatabase
local l_cSyncNameSpaces

local l_cErrorMessage := ""
local l_oDB1

local l_cPreviousDefaultRDD
local l_cConnectionString
local l_SQLEngineType
local l_iPort
local l_cDriver
local l_SQLHandle

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iSyncBackendType := Val(oFcgi:GetInputValue("ComboSyncBackendType"))
l_cSyncServer      := SanitizeInput(oFcgi:GetInputValue("TextSyncServer"))
l_iSyncPort        := Val(oFcgi:GetInputValue("SyncPort"))
l_cSyncUser        := SanitizeInput(oFcgi:GetInputValue("TextSyncUser"))
l_cSyncPassword    := SanitizeInput(oFcgi:GetInputValue("TextSyncPassword"))
l_cSyncDatabase    := SanitizeInput(oFcgi:GetInputValue("TextSyncDatabase"))
l_cSyncNameSpaces  := strtran(SanitizeInput(oFcgi:GetInputValue("TextSyncNameSpaces"))," ","")

l_cPreviousDefaultRDD = RDDSETDEFAULT( "SQLMIX" )

do case
case l_cActionOnSubmit == "Load"

    do case
    case empty(l_iSyncBackendType)
        l_cErrorMessage := "Missing Backend Type"

    case empty(l_cSyncServer)
        l_cErrorMessage := "Missing Server Host Address"

    case empty(l_cSyncUser)
        l_cErrorMessage := "Missing User Name"

    case empty(l_cSyncPassword)
        l_cErrorMessage := "Missing Password"

    case empty(l_cSyncDatabase)
        l_cErrorMessage := "Missing Database"

    otherwise
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("Application")
            :Field("SyncBackendType",l_iSyncBackendType)
            :Field("SyncServer"     ,l_cSyncServer)
            :Field("SyncPort"       ,l_iSyncPort)
            :Field("SyncUser"       ,l_cSyncUser)
            :Field("SyncDatabase"   ,l_cSyncDatabase)
            :Field("SyncNameSpaces" ,l_cSyncNameSpaces)
            :Update(par_iApplicationPk)
        endwith


        switch l_iSyncBackendType
        case HB_ORM_BACKENDTYPE_MARIADB
            l_SQLEngineType := HB_ORM_ENGINETYPE_MYSQL
            l_iPort         := iif(empty(l_iSyncPort),3306,l_iSyncPort)
            l_cDriver       := "MySQL ODBC 8.0 Unicode Driver" //"MariaDB ODBC 3.1 Driver"
            exit
        case HB_ORM_BACKENDTYPE_MYSQL
            l_SQLEngineType := HB_ORM_ENGINETYPE_MYSQL
            l_iPort         := iif(empty(l_iSyncPort),3306,l_iSyncPort)
            l_cDriver       := "MySQL ODBC 8.0 Unicode Driver"
            exit
        case HB_ORM_BACKENDTYPE_POSTGRESQL
            l_SQLEngineType := HB_ORM_ENGINETYPE_POSTGRESQL
            l_iPort         := iif(empty(l_iSyncPort),5432,l_iSyncPort)
            l_cDriver       := "PostgreSQL Unicode"
            exit
        otherwise
            l_iPort := -1
        endswitch


        do case
        case l_iPort == -1
            l_cErrorMessage := "Unknown Server Type"

        case l_iSyncBackendType == HB_ORM_BACKENDTYPE_MARIADB .or. l_iSyncBackendType == HB_ORM_BACKENDTYPE_MYSQL   // MySQL or MariaDB
            // To enable multi statements to be executed, meaning multiple SQL commands separated by ";", had to use the OPTION= setting.
            // See: https://dev.mysql.com/doc/connector-odbc/en/connector-odbc-configuration-connection-parameters.html#codbc-dsn-option-flags
            l_cConnectionString := "SERVER="+l_cSyncServer+";Driver={"+l_cDriver+"};USER="+l_cSyncUser+";PASSWORD="+l_cSyncPassword+";DATABASE="+l_cSyncDatabase+";PORT="+AllTrim(str(l_iPort)+";OPTION=67108864;")
        case l_iSyncBackendType == HB_ORM_BACKENDTYPE_POSTGRESQL   // PostgreSQL
            l_cConnectionString := "Server="+l_cSyncServer+";Port="+AllTrim(str(l_iPort))+";Driver={"+l_cDriver+"};Uid="+l_cSyncUser+";Pwd="+l_cSyncPassword+";Database="+l_cSyncDatabase+";"
        otherwise
            l_cErrorMessage := "Invalid 'Backend Type'"
        endcase
        if !empty(l_cConnectionString)
            l_SQLHandle := hb_RDDInfo( RDDI_CONNECT, { "ODBC", l_cConnectionString })

            if l_SQLHandle == 0
                l_SQLHandle := -1
                l_cErrorMessage := "Unable connect to the server!"+Chr(13)+Chr(10)+Str(hb_RDDInfo( RDDI_ERRORNO ))+Chr(13)+Chr(10)+hb_RDDInfo( RDDI_ERROR )

            else
                l_cErrorMessage := LoadSchema(l_SQLHandle,par_iApplicationPk,l_SQLEngineType,l_cSyncDatabase,l_cSyncNameSpaces)

                hb_RDDInfo(RDDI_DISCONNECT,,"SQLMIX",l_SQLHandle)
                // l_cErrorMessage := "Connected OK"
            endif
        endif



        // if l_oDB1:Tally <> 0
        //     l_cErrorMessage := "Duplicate Name"
        // else
        //     l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        //     with object l_oDB1
        //         :Table("Application")
        //         :Where([upper(replace(Application.LinkCode,' ','')) = ^],l_cApplicationLinkCode)
        //         if l_iApplicationPk > 0
        //             :Where([Application.pk != ^],l_iApplicationPk)
        //         endif
        //         :SQL()
        //     endwith

        //     if l_oDB1:Tally <> 0
        //         l_cErrorMessage := "Duplicate Link Code"
        //     else
        //         //Save the Application
        //         with object l_oDB1
        //             :Table("Application")
        //             :Field("Name"        , l_cApplicationName)
        //             :Field("LinkCode"    , l_cApplicationLinkCode)
        //             :Field("Status"      , l_iApplicationStatus)
        //             :Field("Description" , iif(empty(l_cApplicationDescription),NULL,l_cApplicationDescription))
        //             if empty(l_iApplicationPk)
        //                 :Add()
        //                 oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListNameSpaces/"+l_cApplicationLinkCode+"/")
        //             else
        //                 :Update(l_iApplicationPk)
        //                 oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+l_cApplicationLinkCode+"/")
        //             endif
        //         endwith
        //     endif
        // endif
    endcase

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListTables/"+par_cURLApplicationLinkCode+"/")

endcase

if !empty(l_cErrorMessage)
    l_cHtml += ApplicationLoadSchemaStep1FormBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,;
                                                   l_iSyncBackendType,;
                                                   l_cSyncServer,;
                                                   l_iSyncPort,;
                                                   l_cSyncUser,;
                                                   l_cSyncPassword,;
                                                   l_cSyncDatabase,;
                                                   l_cSyncNameSpaces)
endif

return l_cHtml

return nil
//=================================================================================================================
