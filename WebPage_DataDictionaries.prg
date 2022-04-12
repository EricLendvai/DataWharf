#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageDataDictionaries()
local l_cHtml := []
local l_cHtmlUnderHeader

local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationDescription

local l_iNameSpacePk
local l_iTagPk
local l_iTablePk
local l_iColumnPk
local l_iEnumerationPk
local l_iEnumValuePk
local l_iDiagramPk
local l_hValues := {=>}

local l_cApplicationElement := "TABLES"  //Default Element

local l_aSQLResult := {}

local l_cURLAction              := "ListDataDictionaries"
local l_cURLApplicationLinkCode := ""
local l_cURLNameSpaceName       := ""
local l_cURLTagCode             := ""
local l_cURLTableName           := ""
local l_cURLEnumerationName     := ""
local l_cURLColumnName          := ""
local l_cURLEnumValueName       := ""

local l_cTableAKA
local l_cEnumerationAKA
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfPrimaryColumns
local l_oDBListOfTagsOnFile
local l_cTags
local l_cLinkUID

local l_nAccessLevelDD := 1   // None by default
// As per the info in Schema.txt
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     6 - Edit Anything and Load/Sync Schema
//     7 - Full Access


oFcgi:TraceAdd("BuildPageDataDictionaries")

// Variables
// l_cURLAction
// l_cURLApplicationLinkCode
// l_cURLNameSpaceName
// l_cURLTagCode
// l_cURLTableName
// l_cURLEnumerationName
// l_cURLColumnName

//Improved and new way:
// DataDictionaries/                      Same as DataDictionaries/ListDataDictionaries/
// DataDictionaries/DataDictionarySettings/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryLoadSchema/<ApplicationLinkCode>/

// DataDictionaries/Visualize/<ApplicationLinkCode>/

// DataDictionaries/ListNameSpaces/<ApplicationLinkCode>/
// DataDictionaries/NewNameSpace/<ApplicationLinkCode>/
// DataDictionaries/EditNameSpace/<ApplicationLinkCode>/<NameSpaceName>/

// DataDictionaries/ListTags/<ApplicationLinkCode>/
// DataDictionaries/NewTag/<ApplicationLinkCode>/
// DataDictionaries/EditTag/<ApplicationLinkCode>/<NameSpaceName>/

// DataDictionaries/ListTables/<ApplicationLinkCode>/
// DataDictionaries/NewTable/<ApplicationLinkCode>/
// DataDictionaries/EditTable/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/

// DataDictionaries/ListColumns/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// DataDictionaries/OrderColumns/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// DataDictionaries/NewColumn/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// DataDictionaries/EditColumn/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/<ColumnName>

// DataDictionaries/ListIndexes/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/


// DataDictionaries/ListEnumerations/<ApplicationLinkCode>/
// DataDictionaries/NewEnumeration/<ApplicationLinkCode>/
// DataDictionaries/EditEnumeration/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/

// DataDictionaries/ListEnumValues/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// DataDictionaries/OrderEnumValues/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// DataDictionaries/NewEnumValue/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/
// DataDictionaries/EditEnumValue/<ApplicationLinkCode>/<NameSpaceName>/<EnumerationName>/<EnumValue>/

// DataDictionaries/ListIndexes/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// DataDictionaries/NewIndex/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/
// DataDictionaries/EditIndex/<ApplicationLinkCode>/<NameSpaceName>/<TableName>/<IndexName>

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLApplicationLinkCode := oFcgi:p_URLPathElements[3]
    endif

    if vfp_Inlist(l_cURLAction,"EditNameSpace","EditTable","EditEnumeration","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLNameSpaceName := oFcgi:p_URLPathElements[4]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditTable","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLTableName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLEnumerationName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if vfp_Inlist(l_cURLAction,"EditTag")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLTagCode := oFcgi:p_URLPathElements[4]
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

    case vfp_Inlist(l_cURLAction,"ListTags","NewTag","EditTag")
        l_cApplicationElement := "TAGS"

    case vfp_Inlist(l_cURLAction,"DataDictionarySettings")
        l_cApplicationElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"DataDictionaryLoadSchema")
        l_cApplicationElement := "LOADSCHEMA"

    case vfp_Inlist(l_cURLAction,"Visualize")
        l_cApplicationElement := "VISUALIZE"

    otherwise
        l_cApplicationElement := "TABLES"

    endcase

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if !empty(l_cURLApplicationLinkCode)
        with object l_oDB1
            :Table("eee95bea-1fc1-4712-a0c4-772b3a416e1e","Application")
            :Column("Application.pk"          , "pk")
            :Column("Application.Name"        , "Application_Name")
            :Where("Application.LinkCode = ^" ,l_cURLApplicationLinkCode)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB1:Tally == 1
            l_iApplicationPk          := l_aSQLResult[1,1]
            l_cApplicationName        := l_aSQLResult[1,2]
        else
            l_iApplicationPk   := -1
            l_cApplicationName := "Unknown"
        endif
    endif

    if l_iApplicationPk <= 0
        l_cHtml += [<div>Bad Application</div>]
        return l_cHtml
    else
        l_nAccessLevelDD := GetAccessLevelDDForApplication(l_iApplicationPk)
    endif

else
    l_cURLAction := "ListDataDictionaries"
endif

if  oFcgi:p_nUserAccessMode >= 3
    oFcgi:p_nAccessLevelDD := 7
else
    oFcgi:p_nAccessLevelDD := l_nAccessLevelDD
endif

do case
case l_cURLAction == "ListDataDictionaries"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        // l_cHtml += [<div class="container-fluid">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[DataDictionaries/">Data Dictionaries - Select an Application</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += ApplicationListFormBuild()

case l_cURLAction == "DataDictionarySettings"
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("62f3e291-c7c0-4da7-8874-c839c7c3938c","public.Application")
                :Column("Application.SupportColumns" , "Application_SupportColumns")
                l_oData := :Get(l_iApplicationPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]          := l_cApplicationName
                l_hValues["LinkCode"]      := l_cURLApplicationLinkCode
                l_hValues["SupportColumns"]:= l_oData:Application_SupportColumns

                l_cHtml += DataDictionaryEditFormBuild("",l_iApplicationPk,l_hValues)
            endif
        else
            if l_iApplicationPk > 0
                l_cHtml += DataDictionaryEditFormOnSubmit(l_cURLApplicationLinkCode)
            endif
        endif
    endif

case l_cURLAction == "DataDictionaryLoadSchema"
    if oFcgi:p_nAccessLevelDD >= 6
        // l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
        //Will Build the header after new entities are created.
        l_cHtmlUnderHeader := []

        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

            with object l_oDB1
                :Table("87efb98c-f94f-4202-b97b-c41d8522e288","public.Application")
                :Column("Application.SyncBackendType"  ,"Application_SyncBackendType")
                :Column("Application.SyncServer"       ,"Application_SyncServer")
                :Column("Application.SyncPort"         ,"Application_SyncPort")
                :Column("Application.SyncUser"         ,"Application_SyncUser")
                :Column("Application.SyncDatabase"     ,"Application_SyncDatabase")
                :Column("Application.SyncNameSpaces"   ,"Application_SyncNameSpaces")
                :Column("Application.SyncSetForeignKey","Application_SyncSetForeignKey")
                l_oData := :Get(l_iApplicationPk)
            endwith

            if l_oDB1:Tally == 1
                l_cHtmlUnderHeader += DataDictionaryLoadSchemaStep1FormBuild(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode,;
                                                            l_oData:Application_SyncBackendType,;
                                                            l_oData:Application_SyncServer,;
                                                            l_oData:Application_SyncPort,;
                                                            l_oData:Application_SyncUser,;
                                                            "",;
                                                            l_oData:Application_SyncDatabase,;
                                                            l_oData:Application_SyncNameSpaces,;
                                                            l_oData:Application_SyncSetForeignKey)
            endif
        else
            if l_iApplicationPk > 0
                l_cHtmlUnderHeader += DataDictionaryLoadSchemaStep1FormOnSubmit(l_iApplicationPk,l_cApplicationName,l_cURLApplicationLinkCode)
            endif
        endif
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
        l_cHtml += l_cHtmlUnderHeader
    endif

case l_cURLAction == "Visualize"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    
    if oFcgi:isGet()
        l_iDiagramPk := 0
        with object l_oDB1
            :Table("4ce05f54-56f4-4141-9d33-634c3a661d66","Diagram")
            :Column("Diagram.pk"         ,"Diagram_pk")
            :Column("Diagram.LinkUID"    ,"Diagram_LinkUID")
            :Column("upper(Diagram.Name)","Tag1")
            :Where("Diagram.fk_Application = ^" , l_iApplicationPk)
            :OrderBy("tag1")
            :SQL("ListOfDiagrams")
            if :Tally > 0
                l_iDiagramPk   := ListOfDiagrams->Diagram_pk

                l_cLinkUID = oFcgi:GetQueryString("InitialDiagram")
                if !empty(l_cLinkUID)
                    select ListOfDiagrams
                    locate for ListOfDiagrams->Diagram_LinkUID == l_cLinkUID
                    if found()
                        l_iDiagramPk := ListOfDiagrams->Diagram_pk
                    endif
                endif

            else
                //Add an initial Diagram File
                :Table("0ee46e84-8a73-4702-ab76-53ed6e33a933","Diagram")
                :Field("Diagram.fk_Application" ,l_iApplicationPk)
                :Field("Diagram.Name"           ,"All Tables")  // l_cDiagramName
                :Field("Diagram.UseStatus"      ,1)
                :Field("Diagram.DocStatus"      ,1)
                if :Add()
                    l_iDiagramPk := :Key()
                endif
            endif
        endwith

        if l_iDiagramPk > 0
            l_cHtml += DataDictionaryVisualizeDiagramBuild(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode,l_iDiagramPk)
        endif
    else
        l_cFormName := oFcgi:GetInputValue("formname")
        do case
        case l_cFormName == "Design"
            l_cHtml += DataDictionaryVisualizeDiagramOnSubmit(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode)
        case l_cFormName == "DiagramSettings"
         l_cHtml += DataDictionaryVisualizeDiagramSettingsOnSubmit(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode)
        case l_cFormName == "MyDiagramSettings"
         l_cHtml += DataDictionaryVisualizeMyDiagramSettingsOnSubmit(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode)
        endcase
    endif

case l_cURLAction == "ListTables"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    if oFcgi:isGet()
        l_cHtml += TableListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)
    else
        l_cHtml += TableListFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

// Table Name                Includes/Starts With
// Table Description        (Word Search)
// Column Name              Includes/Starts With/Does Not dbExists
// Column Description       (Word Search)

//?TableNameText=xxxxxx&TableNameSearchMode=Includes/StartsWith

case l_cURLAction == "NewTable"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_cHtml += TableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        endif
    endif

case l_cURLAction == "EditTable"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    

    //Executing the following even for POST to ensure the record is still present.
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("a6af8449-79c8-488c-be62-507ef4f0696c","Table")
        :Column("Table.pk"          , "Pk")            // 1
        :Column("Table.fk_NameSpace", "fk_NameSpace")  // 2
        :Column("Table.Name"        , "Name")          // 3
        :Column("Table.AKA"         , "AKA")           // 4
        :Column("Table.UseStatus"   , "UseStatus")     // 5
        :Column("Table.DocStatus"   , "DocStatus")     // 6
        :Column("Table.Description" , "Description")   // 7
        :Column("Table.Information" , "Information")   // 8
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iTablePk    := l_aSQLResult[1,1]

            l_hValues["Fk_NameSpace"] := l_aSQLResult[1,2]
            l_hValues["Name"]         := AllTrim(l_aSQLResult[1,3])
            l_hValues["AKA"]          := AllTrim(nvl(l_aSQLResult[1,4],""))
            l_hValues["UseStatus"]    := l_aSQLResult[1,5]
            l_hValues["DocStatus"]    := l_aSQLResult[1,6]
            l_hValues["Description"]  := l_aSQLResult[1,7]
            l_hValues["Information"]  := l_aSQLResult[1,8]
 
            CustomFieldsLoad(l_iApplicationPk,USEDON_TABLE,l_iTablePk,@l_hValues)

            //Load current Tags
            l_cTags := ""
            l_oDBListOfTagsOnFile := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDBListOfTagsOnFile
                :Table("f0a3ce88-c43c-49b0-9f95-8d6978a2db8f","TagTable")
                :Column("TagTable.fk_Tag" , "TagTable_fk_Tag")
                :Where("TagTable.fk_Table = ^" , l_iTablePk)
                :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
                :Where("Tag.fk_Application = ^",l_iApplicationPk)
                :Where("Tag.TableUseStatus = 2")   // Only care about Active Tags
                :SQL("ListOfTagsOnFile")
                select ListOfTagsOnFile
                scan all
                    if !empty(l_cTags)
                        l_cTags += [,]
                    endif
                    l_cTags += Trans(ListOfTagsOnFile->TagTable_fk_Tag)
                endscan
            endwith
            l_hValues["Tags"]  := l_cTags

            l_cHtml += TableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iTablePk,l_hValues)
        else
            l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        endif
    endif

case l_cURLAction == "ListColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("ce52204c-5a31-4d27-8983-2267a1e524af","Table")
        :Column("Table.pk"     ,"TablePk")  // 1
        :Column("Table.AKA"    ,"TableAKA") // 2
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iTablePk  := l_aSQLResult[1,1]
        l_cTableAKA := l_aSQLResult[1,2]

        if oFcgi:isGet()
            l_cHtml += ColumnListFormBuild(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,l_cTableAKA)
        else
            l_cHtml += ColumnListFormOnSubmit(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,l_cTableAKA)
        endif


    endif

case l_cURLAction == "OrderColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("d156c11f-ceb4-4420-9a6c-fdcb4bed54eb","Table")
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
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        //Find the iTablePk and iNameSpacePk (for Enumerations)

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("3c360029-4bda-47b1-bad0-b54c10655e39","Table")
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
                //Check if any other fields is already marked as "Primary"
                with object l_oDB1
                    :Table("87ad5f41-7f5d-46b1-8f3c-cf83dbcf10c1","Column")
                    :Where("Column.fk_Table = ^" , l_iTablePk)
                    :Where("Column.Primary")
                    :SQL()
                    l_nNumberOfPrimaryColumns := :Tally
                endwith

                l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,"",0,iif(empty(l_nNumberOfPrimaryColumns),{"ShowPrimary"=>.t.},{=>}))
            else
                l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
            endif
        endif
    endif

case l_cURLAction == "EditColumn"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("0f8ba8eb-5046-4183-97de-5182a7a0ef2a","Column")

        :Column("Column.pk"              ,"Column_pk")              //  1
        :Column("NameSpace.pk"           ,"NameSpace_pk")           //  2
        :Column("Table.pk"               ,"Table_pk")               //  3

        :Column("Column.Name"            ,"Column_Name")            //  4
        :Column("Column.AKA"             ,"Column_AKA")             //  5
        :Column("Column.UseStatus"       ,"Column_UseStatus")       //  6
        :Column("Column.DocStatus"       ,"Column_DocStatus")       //  7
        :Column("Column.Description"     ,"Column_Description")     //  8

        :Column("Column.Type"            ,"Column_Type")            //  9
        :Column("Column.Length"          ,"Column_Length")          // 10
        :Column("Column.Scale"           ,"Column_Scale")           // 11
        :Column("Column.Nullable"        ,"Column_Nullable")        // 12
        :Column("Column.Required"        ,"Column_Required")        // 13
        :Column("Column.Primary"         ,"Column_Primary")         // 14
        :Column("Column.Unicode"         ,"Column_Unicode")         // 15
        :Column("Column.Default"         ,"Column_Default")         // 16
        :Column("Column.LastNativeType"  ,"Column_LastNativeType")  // 17
        :Column("Column.UsedBy"          ,"Column_UsedBy")          // 18
        :Column("Column.fk_TableForeign" ,"Column_fk_TableForeign") // 19
        :Column("Column.ForeignKeyUse"   ,"Column_ForeignKeyUse")   // 20
        :Column("Column.fk_Enumeration"  ,"Column_fk_Enumeration")  // 21

        :Join("inner","Table"    ,"","Column.fk_Table = Table.pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cURLColumnName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+l_cURLApplicationLinkCode+"/")
    else
        l_iColumnPk    := l_aSQLResult[1,1]
        l_iNameSpacePk := l_aSQLResult[1,2]  //Will be used to help get all the enumerations
        l_iTablePk     := l_aSQLResult[1,3]

        if oFcgi:isGet()
            //Check if any other fields is already marked as "Primary"
            with object l_oDB1
                :Table("6a919fef-8beb-4b57-9d58-17d34c332d11","Column")
                :Where("Column.fk_Table = ^" , l_iTablePk)
                :Where("Column.Primary")
                :Where("Column.pk <> ^" , l_iColumnPk)
                :SQL()
                l_hValues["ShowPrimary"] := empty(:Tally)
            endwith

            l_hValues["Name"]            := AllTrim(l_aSQLResult[1, 4])
            l_hValues["AKA"]             := AllTrim(nvl(l_aSQLResult[1,5],""))
            l_hValues["UseStatus"]       := l_aSQLResult[1, 6]
            l_hValues["DocStatus"]       := l_aSQLResult[1, 7]
            l_hValues["Description"]     := l_aSQLResult[1, 8]
            l_hValues["Type"]            := AllTrim(l_aSQLResult[1, 9])
            l_hValues["Length"]          := l_aSQLResult[1,10]
            l_hValues["Scale"]           := l_aSQLResult[1,11]
            l_hValues["Nullable"]        := l_aSQLResult[1,12]
            l_hValues["Required"]        := l_aSQLResult[1,13]
            l_hValues["Primary"]         := l_aSQLResult[1,14]
            l_hValues["Unicode"]         := l_aSQLResult[1,15]
            l_hValues["Default"]         := l_aSQLResult[1,16]
            l_hValues["LastNativeType"]  := l_aSQLResult[1,17]
            l_hValues["UsedBy"]          := l_aSQLResult[1,18]
            l_hValues["Fk_TableForeign"] := l_aSQLResult[1,19]
            l_hValues["ForeignKeyUse"]   := l_aSQLResult[1,20]
            l_hValues["Fk_Enumeration"]  := l_aSQLResult[1,21]

            CustomFieldsLoad(l_iApplicationPk,USEDON_COLUMN,l_iColumnPk,@l_hValues)

            //Load current Tags
            l_cTags := ""
            l_oDBListOfTagsOnFile := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDBListOfTagsOnFile
                :Table("93cf14e2-b8c0-47fe-993b-e1c8676563b1","TagColumn")
                :Column("TagColumn.fk_Tag" , "TagColumn_fk_Tag")
                :Where("TagColumn.fk_Column = ^" , l_iColumnPk)
                :Join("inner","Tag","","TagColumn.fk_Tag = Tag.pk")
                :Where("Tag.fk_Application = ^",l_iApplicationPk)
                :Where("Tag.ColumnUseStatus = 2")   // Only care about Active Tags
                :SQL("ListOfTagsOnFile")
                select ListOfTagsOnFile
                scan all
                    if !empty(l_cTags)
                        l_cTags += [,]
                    endif
                    l_cTags += Trans(ListOfTagsOnFile->TagColumn_fk_Tag)
                endscan
            endwith
            l_hValues["Tags"]  := l_cTags

            l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,"",l_iColumnPk,l_hValues)
        else
            l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_iNameSpacePk,l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName)
        endif
    endif

case l_cURLAction == "ListIndexes"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("18dd5d01-b702-4b96-8c48-44b8323ffc69","Table")
        :Column("Table.pk"     ,"TablePk")   // 1
        :Column("Table.AKA"    ,"TableAKA")  // 2
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iTablePk  := l_aSQLResult[1,1]
        l_cTableAKA := l_aSQLResult[1,2]
        l_cHtml += IndexListFormBuild(l_iTablePk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLTableName,l_cTableAKA)
    endif

case l_cURLAction == "ListEnumerations"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += EnumerationListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewEnumeration"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditEnumeration"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("1c9e2373-6ded-4456-b4d2-bc63991fd0db","Enumeration")
        :Column("Enumeration.pk"              , "Enumeration_Pk")                //  1
        :Column("Enumeration.fk_NameSpace"    , "Enumeration_fk_NameSpace")      //  2
        :Column("Enumeration.Name"            , "Enumeration_Name")              //  3
        :Column("Enumeration.AKA"             , "Enumeration_AKA")               //  4
        :Column("Enumeration.UseStatus"       , "Enumeration_UseStatus")         //  5
        :Column("Enumeration.DocStatus"       , "Enumeration_DocStatus")         //  6
        :Column("Enumeration.Description"     , "Enumeration_Description")       //  7
        :Column("Enumeration.ImplementAs"     , "Enumeration_ImplementAs")       //  8
        :Column("Enumeration.ImplementLength" , "Enumeration_ImplementLength")   //  9
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumerations/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iEnumerationPk    := l_aSQLResult[1,1]

            l_hValues["Fk_NameSpace"]    := l_aSQLResult[1,2]
            l_hValues["Name"]            := AllTrim(l_aSQLResult[1,3])
            l_hValues["AKA"]             := AllTrim(nvl(l_aSQLResult[1,4],""))
            l_hValues["UseStatus"]       := l_aSQLResult[1,5]
            l_hValues["DocStatus"]       := l_aSQLResult[1,6]
            l_hValues["Description"]     := l_aSQLResult[1,7]
            l_hValues["ImplementAs"]     := l_aSQLResult[1,8]
            l_hValues["ImplementLength"] := l_aSQLResult[1,9]

            l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iEnumerationPk,l_hValues)
        else
            l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListEnumValues"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

    //Find the iEnumerationPk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("8122e1ae-644c-4b30-bfa6-779400a520e0","Enumeration")
        :Column("Enumeration.pk"     ,"EnumerationPk")   // 1
        :Column("Enumeration.AKA"    ,"EnumerationAKA")  // 2
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally == 1
        l_iEnumerationPk  := l_aSQLResult[1,1]
        l_cEnumerationAKA := l_aSQLResult[1,2]
        l_cHtml += EnumValueListFormBuild(l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName,l_cEnumerationAKA)
    endif

case l_cURLAction == "OrderEnumValues"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

        //Find the iEnumerationPk
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("0d12fc1c-3b02-4e00-ace2-21eb385eff84","Enumeration")
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
    endif

case l_cURLAction == "NewEnumValue"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        //Find the iEnumerationPk and iNameSpacePk (for Enumerations)

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("9a9489dd-bcf1-4688-b03e-6c706960e140","Enumeration")
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
                l_cHtml += EnumValueEditFormBuild(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName,"",0,{=>})
            else
                l_cHtml += EnumValueEditFormOnSubmit(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
            endif
        endif
    endif

case l_cURLAction == "EditEnumValue"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("b96a6a89-c1b6-4629-8d00-3ebf37e93845","EnumValue")

        :Column("EnumValue.pk"         ,"EnumValue_pk")             //  1
        :Column("NameSpace.pk"         ,"NameSpace_pk")             //  2
        :Column("Enumeration.pk"       ,"Enumeration_pk")           //  3

        :Column("EnumValue.Name"       ,"EnumValue_Name")           //  4
        :Column("EnumValue.AKA"        ,"EnumValue_AKA")            //  5
        :Column("EnumValue.Number"     ,"EnumValue_Number")         //  6
        :Column("EnumValue.UseStatus"  ,"EnumValue_UseStatus")      //  7
        :Column("EnumValue.DocStatus"  ,"EnumValue_DocStatus")      //  8
        :Column("EnumValue.Description","EnumValue_Description")    //  9

        :Join("inner","Enumeration"    ,"","EnumValue.fk_Enumeration = Enumeration.pk")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        :Where([lower(replace(EnumValue.Name,' ','')) = ^],lower(StrTran(l_cURLEnumValueName," ","")))
        l_aSQLResult := {}
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+l_cURLApplicationLinkCode+"/"+l_cURLNameSpaceName+"/"+l_cURLEnumerationName+"/")
    else
        l_iEnumValuePk    := l_aSQLResult[1,1]
        l_iNameSpacePk    := l_aSQLResult[1,2]  //Will be used to help get all the enumerations
        l_iEnumerationPk  := l_aSQLResult[1,3]

        if oFcgi:isGet()

            l_hValues["Name"]            := AllTrim(l_aSQLResult[1,4])
            l_hValues["AKA"]             := AllTrim(nvl(l_aSQLResult[1,5],""))
            l_hValues["Number"]          := l_aSQLResult[1,6]
            l_hValues["UseStatus"]       := l_aSQLResult[1,7]
            l_hValues["DocStatus"]       := l_aSQLResult[1,8]
            l_hValues["Description"]     := l_aSQLResult[1,9]

            l_cHtml += EnumValueEditFormBuild(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName,"",l_iEnumValuePk,l_hValues)
        else
            l_cHtml += EnumValueEditFormOnSubmit(l_iNameSpacePk,l_iEnumerationPk,l_cURLApplicationLinkCode,l_cURLNameSpaceName,l_cURLEnumerationName)
        endif
    endif

case l_cURLAction == "ListNameSpaces"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += NameSpaceListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewNameSpace"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_cHtml += NameSpaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += NameSpaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditNameSpace"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("f0f2eaea-8306-49c9-afef-d72afb41601c","NameSpace")
        :Column("NameSpace.pk"          , "Pk")           // 1
        :Column("NameSpace.Name"        , "Name")         // 2
        :Column("NameSpace.AKA"         , "AKA")          // 3
        :Column("NameSpace.UseStatus"   , "UseStatus")    // 4
        :Column("NameSpace.DocStatus"   , "DocStatus")    // 5
        :Column("NameSpace.Description" , "Description")  // 6
        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cURLNameSpaceName," ","")))
        :Where([NameSpace.fk_Application = ^],l_iApplicationPk)
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListNameSpaces/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iNameSpacePk    := l_aSQLResult[1,1]

            l_hValues["Name"]         := AllTrim(l_aSQLResult[1,2])
            l_hValues["AKA"]          := AllTrim(nvl(l_aSQLResult[1,3],""))
            l_hValues["UseStatus"]    := l_aSQLResult[1,4]
            l_hValues["DocStatus"]    := l_aSQLResult[1,5]
            l_hValues["Description"]  := l_aSQLResult[1,6]

            CustomFieldsLoad(l_iApplicationPk,USEDON_NAMESPACE,l_iNameSpacePk,@l_hValues)

            l_cHtml += NameSpaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iNameSpacePk,l_hValues)
        else
            l_cHtml += NameSpaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListTags"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += TagListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewTag"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_cHtml += TagEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += TagEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditTag"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("a5a2cd08-7783-4151-905d-da7c3cb3a2af","Tag")
        :Column("Tag.pk"             , "Pk")                // 1
        :Column("Tag.Name"           , "Name")              // 2
        :Column("Tag.Code"           , "Code")              // 3
        :Column("Tag.TableUseStatus" , "TableUseStatus")    // 4
        :Column("Tag.ColumnUseStatus", "ColumnUseStatus")   // 5
        :Column("Tag.Description"    , "Description")       // 6
        :Where([upper(replace(Tag.Code,' ','')) = ^],upper(StrTran(l_cURLTagCode," ","")))
        :Where([Tag.fk_Application = ^],l_iApplicationPk)
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTags/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iTagPk    := l_aSQLResult[1,1]

            l_hValues["Name"]            := AllTrim(l_aSQLResult[1,2])
            l_hValues["Code"]            := AllTrim(l_aSQLResult[1,3])
            l_hValues["TableUseStatus"]  := l_aSQLResult[1,4]
            l_hValues["ColumnUseStatus"] := l_aSQLResult[1,5]
            l_hValues["Description"]     := l_aSQLResult[1,6]

            l_cHtml += TagEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iTagPk,l_hValues)
        else
            l_cHtml += TagEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

otherwise
    l_cHtml += [<div>Bad URL</div>]

endcase

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
function FormatColumnTypeInfo(par_cColumnType,par_iColumnLength,par_iColumnScale,par_cEnumerationName,par_cEnumerationAKA,par_iEnumerationImplementAs,par_iEnumerationImplementLength,par_iColumnUnicode,;
                                    par_cSitePath,par_cURLApplicationLinkCode,par_cURLNameSpaceName)
local l_cResult
local l_iTypePos

// Altd()
l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[1] == par_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
if l_iTypePos > 0
    l_cResult := par_cColumnType+" "+oFcgi:p_ColumnTypes[l_iTypePos,2]
    do case
    case oFcgi:p_ColumnTypes[l_iTypePos,4] .and. oFcgi:p_ColumnTypes[l_iTypePos,3]  // Length and Scale
        l_cResult += [&nbsp;(]+iif(hb_IsNIL(par_iColumnLength),"",Trans(par_iColumnLength))+[,]+iif(hb_IsNIL(par_iColumnScale),"",Trans(par_iColumnScale))+[)]

    case oFcgi:p_ColumnTypes[l_iTypePos,4]  // Scale
        l_cResult += [ (Scale: ]+iif(hb_IsNIL(par_iColumnScale),"",Trans(par_iColumnScale))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,3]  // Length
        l_cResult += [&nbsp;(]+iif(hb_IsNIL(par_iColumnLength),"",Trans(par_iColumnLength))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,5]  // Enumeration
        if !hb_IsNIL(par_cEnumerationName) .and. !hb_IsNIL(par_iEnumerationImplementAs) //.and. !hb_IsNIL(par_iEnumerationImplementLength)
            l_cResult += [&nbsp;(]
            l_cResult += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+par_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+[/]+par_cEnumerationName+[/">]
            l_cResult += par_cEnumerationName+iif(!empty(par_cEnumerationAKA),[&nbsp;(]+Strtran(par_cEnumerationAKA,[&nbsp;],[])+[)],[])
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

    if par_iColumnUnicode .and. oFcgi:p_ColumnTypes[l_iTypePos,6]
        l_cResult += " Unicode"
    endif

else
    l_cResult := ""
endif

return l_cResult
//=================================================================================================================
static function DataDictionaryHeaderBuild(par_iApplicationPk,par_cApplicationName,par_cApplicationElement,par_cSitePath,par_cURLApplicationLinkCode,par_lActiveHeader)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
 
oFcgi:TraceAdd("DataDictionaryHeaderBuild")

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Application: ]+par_cApplicationName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[DataDictionaries/">Other Applications</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("72e2bd5d-4bd3-41a0-92e4-cf1a33c58489","Table")
            :Column("Count(*)","Total")
            :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cApplicationElement == "TABLES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Tables (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("a5b4d022-f670-4063-ba57-c5e0ae2c07c5","Enumeration")
            :Column("Count(*)","Total")
            :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "ENUMERATIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Enumerations (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("757edb64-9f3a-4f63-ada7-dbedf3e09fa7","NameSpace")
            :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
            l_iReccount := :Count()
        endwith
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "NAMESPACES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/ListNameSpaces/]+par_cURLApplicationLinkCode+[/">Name Spaces (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("65755ca3-5143-4556-8f3b-72912b2df865","Tag")
            :Where("Tag.fk_Application = ^" , par_iApplicationPk)
            l_iReccount := :Count()
        endwith
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "TAGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/ListTags/]+par_cURLApplicationLinkCode+[/">Tags (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionarySettings/]+par_cURLApplicationLinkCode+[/">Data Dictionary Settings</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelDD >= 6
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "LOADSCHEMA",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryLoadSchema/]+par_cURLApplicationLinkCode+[/">Load/Sync Schema</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "VISUALIZE",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/Visualize/]+par_cURLApplicationLinkCode+[/">Visualize</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ApplicationListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfDataDictionaries
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("ApplicationListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("d5b0a13d-7048-457c-a826-a80a09384464","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Application.LinkCode"   ,"Application_LinkCode")
    :Column("Application.UseStatus"  ,"Application_UseStatus")
    :Column("Application.DocStatus"  ,"Application_DocStatus")
    :Column("Application.Description","Application_Description")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif

    :SQL("ListOfDataDictionaries")
    l_nNumberOfDataDictionaries := :Tally
endwith


if l_nNumberOfDataDictionaries > 0
    with object l_oDB2
        :Table("3deb9b62-0c79-4c9c-a7af-b4e1d47dfed8","Application")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Application.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_APPLICATION)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("6b6ca0e1-6883-490c-9dd7-89e50b7df8d8","Application")
        :Column("Application.pk"         ,"fk_entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Application.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_APPLICATION)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfDataDictionaries)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Application on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"4","5")+[">Applications / Data Dictionaries (]+Trans(l_nNumberOfDataDictionaries)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfDataDictionaries
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListTables/]+AllTrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+Allt(ListOfDataDictionaries->Application_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfDataDictionaries->Application_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfDataDictionaries->Application_UseStatus,1,6),ListOfDataDictionaries->Application_UseStatus,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfDataDictionaries->Application_DocStatus,1,4),ListOfDataDictionaries->Application_DocStatus,1)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfDataDictionaries->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function DataDictionaryEditFormBuild(par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText      := hb_DefaultValue(par_cErrorText,"")

local l_cSupportColumns := nvl(hb_HGetDef(par_hValues,"SupportColumns",""),"")

oFcgi:TraceAdd("DataDictionaryEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            // Should never happen
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update Data Dictionary Settings</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelDD >= 7
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Support Column Names</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextSupportColumns" id="TextSupportColumns" value="]+FcgiPrepFieldForValue(l_cSupportColumns)+[" size="80"></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextSupportColumns').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function DataDictionaryEditFormOnSubmit(par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationSupportColumns

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("DataDictionaryEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationPk             := Val(oFcgi:GetInputValue("TableKey"))
l_cApplicationSupportColumns := SanitizeInput(oFcgi:GetInputValue("TextSupportColumns"))

l_cApplicationSupportColumns := Alltrim(strtran(l_cApplicationSupportColumns,[,],[ ]))
do while space(2) $ l_cApplicationSupportColumns
    l_cApplicationSupportColumns := strtran(l_cApplicationSupportColumns,space(2),space(1))
enddo

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 7
        //Save the Application
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("3cbf7dbb-cdec-483d-9660-a9043820b170","Application")
            :Field("Application.SupportColumns" , iif(empty(l_cApplicationSupportColumns),NULL,l_cApplicationSupportColumns))
            
            if empty(l_iApplicationPk)
                //Should never happen
            else
                if :Update(l_iApplicationPk)
                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
                else
                    l_cErrorMessage := "Failed to update Application."
                endif
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    if empty(l_iApplicationPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
    endif
endcase

if !empty(l_cErrorMessage)
    l_hValues["SupportColumns"] := l_cApplicationSupportColumns

    l_cHtml += DataDictionaryEditFormBuild(l_cErrorMessage,l_iApplicationPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function NameSpaceListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfNameSpaces
local l_nNumberOfCustomFieldValues := 0

local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("NameSpaceListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("27c7cda8-7433-4416-a18a-74b38bb8bd6e","NameSpace")
    :Column("NameSpace.pk"         ,"pk")
    :Column("NameSpace.Name"       ,"NameSpace_Name")
    :Column("NameSpace.AKA"        ,"NameSpace_AKA")
    :Column("NameSpace.UseStatus"  ,"NameSpace_UseStatus")
    :Column("NameSpace.DocStatus"  ,"NameSpace_DocStatus")
    :Column("NameSpace.Description","NameSpace_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNameSpaces")
    l_nNumberOfNameSpaces := :Tally
endwith

if l_nNumberOfNameSpaces > 0
    with object l_oDB2
        :Table("713be6a6-ff44-4b10-893c-aa80400864bf","NameSpace")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = NameSpace.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_NAMESPACE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("8e9d02fa-3cfe-41f2-b426-dbe222d62db2","NameSpace")
        :Column("NameSpace.pk"           ,"fk_entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = NameSpace.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_NAMESPACE)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

endif

if empty(l_nNumberOfNameSpaces)
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No Name Space on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary rounded" href="]+l_cSitePath+[DataDictionaries/NewNameSpace/]+par_cURLApplicationLinkCode+[/">New Name Space</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewNameSpace/]+par_cURLApplicationLinkCode+[/">New Name Space</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"4","5")+[">Name Spaces (]+Trans(l_nNumberOfNameSpaces)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfNameSpaces
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditNameSpace/]+par_cURLApplicationLinkCode+[/]+ListOfNameSpaces->NameSpace_Name+[/">]+ListOfNameSpaces->NameSpace_Name+FormatAKAForDisplay(ListOfNameSpaces->NameSpace_AKA)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfNameSpaces->NameSpace_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfNameSpaces->NameSpace_UseStatus,1,6),ListOfNameSpaces->NameSpace_UseStatus,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfNameSpaces->NameSpace_DocStatus,1,4),ListOfNameSpaces->NameSpace_DocStatus,1)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfNameSpaces->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function NameSpaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cAKA         := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus   := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

oFcgi:TraceAdd("NameSpaceEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Name Space</span>]   //navbar-text
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus">]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_NAMESPACE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

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
local l_cNameSpaceAKA
local l_iNameSpaceUseStatus
local l_iNameSpaceDocStatus
local l_cNameSpaceDescription

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("NameSpaceEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iNameSpacePk          := Val(oFcgi:GetInputValue("TableKey"))
l_cNameSpaceName        := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))
l_cNameSpaceAKA         := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cNameSpaceAKA)
    l_cNameSpaceAKA := NIL
endif
l_iNameSpaceUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_iNameSpaceDocStatus   := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cNameSpaceDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 3
        if empty(l_cNameSpaceName)
            l_cErrorMessage := "Missing Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("ff18156d-1501-4629-b1ca-a3db929d95ea","NameSpace")
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
                    :Table("baf7af76-6013-4b53-ba26-4006e22f52cb","NameSpace")
                    if oFcgi:p_nAccessLevelDD >= 5
                        :Field("NameSpace.Name"       ,l_cNameSpaceName)
                        :Field("NameSpace.AKA"        ,l_cNameSpaceAKA)
                        :Field("NameSpace.UseStatus"  ,l_iNameSpaceUseStatus)
                    endif
                    :Field("NameSpace.DocStatus"  ,l_iNameSpaceDocStatus)
                    :Field("NameSpace.Description",iif(empty(l_cNameSpaceDescription),NULL,l_cNameSpaceDescription))
                    if empty(l_iNameSpacePk)
                        :Field("NameSpace.fk_Application" , par_iApplicationPk)
                        if :Add()
                            l_iNameSpacePk := :Key()
                        else
                            l_cErrorMessage := "Failed to add NameSpace."
                        endif
                    else
                        if !:Update(l_iNameSpacePk)
                            l_cErrorMessage := "Failed to update NameSpace."
                        endif
                        // SendToClipboard(:LastSQL())
                    endif

                    if empty(l_cErrorMessage)
                        CustomFieldsSave(par_iApplicationPk,USEDON_NAMESPACE,l_iNameSpacePk)
                    endif
                endwith

                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")  //+l_cNameSpaceName+"/"
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // NameSpace
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveApplicationDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteNameSpace(par_iApplicationPk,l_iNameSpacePk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("910d6dd3-4bcb-4d96-a092-61730e83380c","Table")
                :Where("table.fk_NameSpace = ^",l_iNameSpacePk)
                :SQL()
            endwith

            if l_oDB1:Tally == 0
                with object l_oDB1
                    :Table("1228e164-50b6-447a-81c3-e2e0430983fc","Enumeration")
                    :Where("Enumeration.fk_NameSpace = ^",l_iNameSpacePk)
                    :SQL()
                endwith

                if l_oDB1:Tally == 0
                    CustomFieldsDelete(par_iApplicationPk,USEDON_NAMESPACE,l_iNameSpacePk)
                    l_oDB1:Delete("08e836c0-5ee8-4732-b76f-a303a4c5bf91","NameSpace",l_iNameSpacePk)

                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListNameSpaces/"+par_cURLApplicationLinkCode+"/")
                else
                    l_cErrorMessage := "Related Enumeration record on file"
                endif
            else
                l_cErrorMessage := "Related Table record on file"
            endif
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cNameSpaceName
    l_hValues["AKA"]             := l_cNameSpaceAKA
    l_hValues["UseStatus"]       := l_iNameSpaceUseStatus
    l_hValues["DocStatus"]       := l_iNameSpaceDocStatus
    l_hValues["Description"]     := l_cNameSpaceDescription

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_NAMESPACE,@l_hValues)

    l_cHtml += NameSpaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iNameSpacePk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableListFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_cTableName
local l_cTableDescription
local l_cTableTags
local l_cColumnName
local l_cColumnDescription
local l_cURL

oFcgi:TraceAdd("TableListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cTableName         := SanitizeInput(oFcgi:GetInputValue("TextTableName"))
l_cTableDescription  := SanitizeInput(oFcgi:GetInputValue("TextTableDescription"))
l_cTableTags        := SanitizeInput(oFcgi:GetInputValue("TextTableTags"))

l_cColumnName        := SanitizeInput(oFcgi:GetInputValue("TextColumnName"))
l_cColumnDescription := SanitizeInput(oFcgi:GetInputValue("TextColumnDescription"))
//_M_

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName"        ,l_cTableName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription" ,l_cTableDescription)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags"       ,l_cTableTags)

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName"       ,l_cColumnName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription",l_cColumnDescription)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags"      ,"")   // _M_

    // l_cURL += [Search?TableName=]+hb_StrToHex(l_cTableName)
    // l_cURL += [&TableDescription=]+hb_StrToHex(l_cTableDescription)
    // l_cURL += [&ColumnName=]+hb_StrToHex(l_cColumnName)
    // l_cURL += [&ColumnDescription=]+hb_StrToHex(l_cColumnDescription)
    // //SendToClipboard(l_cURL)
    // oFcgi:Redirect(l_cURL)

    l_cHtml += TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName"        ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription" ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription","")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags"      ,"")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

endcase

return l_cHtml
//=================================================================================================================
static function TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB_ListOfTables             := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesColumnCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesIndexCounts  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField              := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags              := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_TableTags               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_AnyTags                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iTablePk
local l_nColumnCount
local l_iIndexCount

local l_cSearchTableName
local l_cSearchTableDescription
local l_cSearchTableTags

local l_cSearchColumnName
local l_cSearchColumnDescription
local l_cSearchColumnTags

local l_nNumberOfTables := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cColumnSearchParameters
local l_nNumberOfTags
local l_nColspan
local l_cTagsInfo
local l_nNumberOfUsedTags
local l_json_Tags
local l_cTagInfo
local l_ScriptFolder

oFcgi:TraceAdd("TableListFormBuild")

l_cSearchTableName         := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName")
l_cSearchTableDescription  := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription")
l_cSearchTableTags         := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags")

l_cSearchColumnName        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName")
l_cSearchColumnDescription := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription")
l_cSearchColumnTags        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags")

if empty(l_cSearchColumnName) .and. empty(l_cSearchColumnDescription)  //_M_ on Column Tags
    l_cColumnSearchParameters := ""
else
    l_cColumnSearchParameters := [Search?ColumnName=]+hb_StrToHex(l_cSearchColumnName)+[&ColumnDescription=]+hb_StrToHex(l_cSearchColumnDescription)   //strtolhex
endif

//Find out if any tags are linked to any tables, regardless of filter
with object l_oDB_AnyTags
    :Table("1f510c4e-d637-4803-814b-6bae91676385","TagTable")
    :Join("inner","Table","","TagTable.fk_Table = Table.pk")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Where("Tag.TableUseStatus = 2")   // Only care about Active Tags
    l_nNumberOfUsedTags := :Count()

    if empty(l_nNumberOfUsedTags)
        l_cSearchTableTags  := []
        l_cSearchColumnTags := []
    else
        //_M_ add extra code to ensure have ",0123456789" characters. in l_cSearchTableTags and l_cSearchColumnTags
    endif

endwith

with object l_oDB_ListOfTables
    :Table("d72bc32f-57f1-4e1e-b782-dc5b339bbe52","Table")
    :Column("Table.pk"         ,"pk")
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.AKA"        ,"Table_AKA")
    :Column("Table.UseStatus"  ,"Table_UseStatus")
    :Column("Table.DocStatus"  ,"Table_DocStatus")
    :Column("Table.Description","Table_Description")
    :Column("Table.Information","Table_Information")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Table.Name)","tag2")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)

    if !empty(l_cSearchTableName)
        :KeywordCondition(l_cSearchTableName,"CONCAT(Table.Name,' ',Table.AKA)")
    endif
    if !empty(l_cSearchTableDescription)
        :KeywordCondition(l_cSearchTableDescription,"Table.Description")
    endif
    if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
        :Distinct(.t.)
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        if !empty(l_cSearchColumnName)
            :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
        endif
        if !empty(l_cSearchColumnDescription)
            :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
        endif
    endif

    if !empty(l_cSearchTableTags)
        :Distinct(.t.)
        :Join("inner","TagTable","","TagTable.fk_Table = Table.pk")
        :Where("TagTable.fk_Tag in ("+l_cSearchTableTags+")")
    endif

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfTables")
    l_nNumberOfTables := :Tally

    // SendToClipboard(:LastSQL())

endwith

if l_nNumberOfTables > 0
    with object l_oDB_CustomField
        :Table("9002a459-657d-428b-b5e2-665851c7f853","Table")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Table.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)

        :Where("CustomField.UsedOn = ^",USEDON_TABLE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice

        if !empty(l_cSearchTableName)
            :KeywordCondition(l_cSearchTableName,"CONCAT(Table.Name,' ',Table.AKA)")
        endif
        if !empty(l_cSearchTableDescription)
            :KeywordCondition(l_cSearchTableDescription,"Table.Description")
        endif
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnDescription)
                :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
            endif
        endif
        if !empty(l_cSearchTableTags)
            :Distinct(.t.)
            :Join("inner","TagTable","","TagTable.fk_Table = Table.pk")
            :Where("TagTable.fk_Tag in ("+l_cSearchTableTags+")")
        endif
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("0fef6f2f-e47c-4472-931a-84b5c23b52b4","Table")
        :Column("Table.pk"               ,"fk_entity")

        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")

        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Table.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_TABLE)
        :Where("CustomField.Status <= 2")

        if !empty(l_cSearchTableName)
            :KeywordCondition(l_cSearchTableName,"CONCAT(Table.Name,' ',Table.AKA)")
        endif
        if !empty(l_cSearchTableDescription)
            :KeywordCondition(l_cSearchTableDescription,"Table.Description")
        endif
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnDescription)
                :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
            endif
        endif
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

    with object l_oDB_TableTags
        :Table("232681c2-68f1-4977-81dc-b96fb5779a13","Table")
        :Column("Table.pk" ,"fk_entity")
        :Column("Tag.Name","Tag_Name")
        :Column("Tag.Code","Tag_Code")
        :Column("upper(Tag.Name)","tag1")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Join("inner","TagTable","","TagTable.fk_Table = Table.pk")
        :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Where("Tag.fk_Application = ^",par_iApplicationPk)
        :Where("Tag.TableUseStatus = 2")   // Only care about Active Tags
        :OrderBy("tag1")
        :SQL("ListOfTagTables")
        l_nNumberOfTags := :Tally
    endif

endif

//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
with object l_oDB_ListOfTablesColumnCounts
    :Table("30c4a441-523c-40ca-85eb-e4b30f6358cc","Table")
    :Column("Table.pk" ,"Table_pk")
    :Column("Count(*)" ,"ColumnCount")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Table.pk")
    :SQL("ListOfTablesColumnCounts")

    with object :p_oCursor
        :Index("tag1","Table_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

with object l_oDB_ListOfTablesIndexCounts
    :Table("8ed29bff-8f51-4140-a889-d22dcca7c313","Table")
    :Column("Table.pk" ,"Table_pk")
    :Column("Count(*)" ,"IndexCount")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Index","","Index.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Table.pk")
    :SQL("ListOfTablesIndexCounts")

    with object :p_oCursor
        :Index("tag1","Table_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

if l_nNumberOfUsedTags > 0
    //Multi Select Support for tags

    l_ScriptFolder := l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]
    oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
    oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

    with object l_oDB_ListOfTags
        :Table("9af99d6b-dd79-4bfb-904d-08d48f687cb3","Tag")
        :Column("Tag.pk"   , "pk")
        :Column("Tag.Name" , "Tag_Name")
        :Column("upper(Tag.Name)" , "tag1")
        :Column("Tag.Code" , "Tag_Code")
        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
        :Where("Tag.TableUseStatus = 2")
        :OrderBy("Tag1")
        :SQL("ListOfTags")
        l_nNumberOfTags := :Tally

        if l_nNumberOfTags > 0
            l_json_Tags := []
            select ListOfTags
            scan all
                if !empty(l_json_Tags)
                    l_json_Tags += [,]
                endif
                l_cTagInfo := ListOfTags->Tag_Name + [ (]+ListOfTags->Tag_Code+[)]
                l_json_Tags += "{tag:'"+l_cTagInfo+"',value:"+trans(ListOfTags->pk)+"}"
            endscan
        endif
    endwith

    oFcgi:p_cjQueryScript += [$(".TextSearchTag").amsifySuggestags({]+;
                                                                    "suggestions :["+l_json_Tags+"],"+;
                                                                    "whiteList: true,"+;
                                                                    "tagLimit: 10,"+;
                                                                    "selectOnHover: true,"+;
                                                                    "showAllSuggestions: true,"+;
                                                                    "keepLastOnHoverTag: false"+;
                                                                    [});]

    l_cHtml += [<style>]
    l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
    l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 150px;} ]
    l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
    l_cHtml += [</style>]

endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    if oFcgi:p_nAccessLevelDD >= 5
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[DataDictionaries/NewTable/]+par_cURLApplicationLinkCode+[/">New Table</a>]
                    else
                        l_cHtml += [<span class="ms-3"> </a>]  //To make some spacing
                    endif
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td valign="top">]
                    l_cHtml += [<table>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td></td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                            if l_nNumberOfUsedTags > 0
                                l_cHtml += [<td class="justify-content-center" align="center">Tags</td>]
                            endif
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">Table</span></td>]
                            l_cHtml += [<td><input type="text" name="TextTableName" id="TextTableName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchTableName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextTableDescription" id="TextTableDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchTableDescription)+[" class="form-control"></td>]
                            if l_nNumberOfUsedTags > 0
                                l_cHtml += [<td><input type="text" name="TextTableTags" id="TextTableTags" size="25" maxlength="10000" value="]+FcgiPrepFieldForValue(l_cSearchTableTags)+[" class="form-control TextSearchTag" placeholder=""></td>]   //  style="width:100px;"
                            endif
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">Column</span></td>]
                            l_cHtml += [<td><input type="text" name="TextColumnName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextColumnDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnDescription)+[" class="form-control"></td>]
                            if l_nNumberOfUsedTags > 0
                                l_cHtml += [<td></td>]  //_M_
                            endif
                        l_cHtml += [</tr>]
                    l_cHtml += [</table>]

                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-5 me-3" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
                    l_cHtml += [<input type="button" class="btn btn-primary rounded me-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]
                l_cHtml += [</td>]
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]



    l_cHtml += [</div>]

l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfTables)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_nColspan := 8
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan += 1
            endif
            if l_nNumberOfTags > 0
                l_nColspan += 1
            endif

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+Trans(l_nColspan)+[">Tables (]+Trans(l_nNumberOfTables)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Name Space</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Table Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Columns</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Indexes</th>]
                if l_nNumberOfTags > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Tags</th>]
                endif
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Info</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfTables
            scan all
                l_iTablePk := ListOfTables->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += Allt(ListOfTables->NameSpace_Name)
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditTable/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+ListOfTables->Table_Name+[/">]+ListOfTables->Table_Name+FormatAKAForDisplay(ListOfTables->Table_AKA)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_nColumnCount := iif( VFP_Seek(l_iTablePk,"ListOfTablesColumnCounts","tag1") , ListOfTablesColumnCounts->ColumnCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+Allt(ListOfTables->Table_Name)+[/]+l_cColumnSearchParameters+[">]+Trans(l_nColumnCount)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_iIndexCount := iif( VFP_Seek(l_iTablePk,"ListOfTablesIndexCounts","tag1") , ListOfTablesIndexCounts->IndexCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListIndexes/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTables->NameSpace_Name)+[/]+Allt(ListOfTables->Table_Name)+[/">]+Trans(l_iIndexCount)+[</a>]
                    l_cHtml += [</td>]

                    if l_nNumberOfTags > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cTagsInfo := []
                            select ListOfTagTables
                            scan all for ListOfTagTables->fk_entity = l_iTablePk
                                if !empty(l_cTagsInfo)
                                    l_cTagsInfo += [<br>]
                                endif
                                l_cTagsInfo += [<span style="white-space:nowrap;">]+ListOfTagTables->Tag_Name+[ (]+ListOfTagTables->Tag_Code+[)]+[</span>]
                            endscan
                            l_cHtml += l_cTagsInfo
                        l_cHtml += [</td>]
                    endif

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfTables->Table_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        //l_cHtml += iif(len(nvl(ListOfTables->Table_Information,"")) > 0,[<i class="bi bi-check-lg fa-2x"></i>],[&nbsp;])
                        l_cHtml += iif(len(nvl(ListOfTables->Table_Information,"")) > 0,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfTables->Table_UseStatus,1,6),ListOfTables->Table_UseStatus,1)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfTables->Table_DocStatus,1,4),ListOfTables->Table_DocStatus,1)]
                    l_cHtml += [</td>]

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(l_iTablePk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif
                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_iNameSpacePk := hb_HGetDef(par_hValues,"Fk_NameSpace",0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cAKA         := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cTags        := nvl(hb_HGetDef(par_hValues,"Tags",""),"")
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus   := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cInformation := nvl(hb_HGetDef(par_hValues,"Information",""),"")

local l_cSitePath    := oFcgi:RequestSettings["SitePath"]

local l_oDB1           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDataTableInfo
local l_ScriptFolder
local l_json_Tags
local l_cTagInfo
local l_nNumberOfTags

oFcgi:TraceAdd("TableEditFormBuild")

l_ScriptFolder:= l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]

oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

with object l_oDB_ListOfTags
    :Table("baf9f132-b515-41be-b809-def45b61f7d0","Tag")
    :Column("Tag.pk"   , "pk")
    :Column("Tag.Name" , "Tag_Name")
    :Column("upper(Tag.Name)" , "tag1")
    :Column("Tag.Code" , "Tag_Code")
    :Where("Tag.fk_Application = ^" , par_iApplicationPk)
    :Where("Tag.TableUseStatus = 2")
    :OrderBy("Tag1")
    :SQL("ListOfTags")
    l_nNumberOfTags := :Tally

    if l_nNumberOfTags > 0
        l_json_Tags := []
        select ListOfTags
        scan all
            if !empty(l_json_Tags)
                l_json_Tags += [,]
            endif
            l_cTagInfo := ListOfTags->Tag_Name + [ (]+ListOfTags->Tag_Code+[)]
            l_json_Tags += "{tag:'"+l_cTagInfo+"',value:"+trans(ListOfTags->pk)+"}"
        endscan

        oFcgi:p_cjQueryScript += [$("#TextTags").amsifySuggestags({]+;
                                                                "suggestions :["+l_json_Tags+"],"+;
                                                                "whiteList: true,"+;
                                                                "tagLimit: 10,"+;
                                                                "selectOnHover: true,"+;
                                                                "showAllSuggestions: true,"+;
                                                                "keepLastOnHoverTag: false"+;
                                                                [});]

        l_cHtml += [<style>]
        l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
        l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 300px;} ]
        l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
        l_cHtml += [</style>]
        
    endif
endwith

with object l_oDB1
    if !empty(par_iPk)
        :Table("96de9645-1c36-4414-bd84-1b94e600927d","Table")
        :Column("NameSpace.Name"     ,"NameSpace_Name")
        :Column("Table.Name"         ,"Table_Name")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        l_oDataTableInfo := :Get(par_iPk)
    endif

    :Table("46e97041-1a30-466a-93ed-2172c7dcfedd","NameSpace")
    :Column("NameSpace.pk"         ,"pk")
    :Column("NameSpace.Name"       ,"NameSpace_Name")
    :Column("Upper(NameSpace.Name)","tag1")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNameSpaces")

endwith

if l_oDB1:Tally <= 0
    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+[You must setup at least one Name Space first]+[</div>]

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Table</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" value="Ok" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
else

    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    if !empty(l_cErrorText)
        l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Table</span>]   //navbar-text
            if oFcgi:p_nAccessLevelDD >= 3
                l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
            endif
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
            if !empty(par_iPk)
                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
                endif
                l_cHtml += [<a class="btn btn-primary rounded ms-5 HideOnEdit" href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+l_oDataTableInfo:NameSpace_Name+[/]+l_oDataTableInfo:Table_Name+[/">Columns</a>]
                l_cHtml += [<a class="btn btn-primary rounded ms-3 HideOnEdit" href="]+l_cSitePath+[DataDictionaries/ListIndexes/]+par_cURLApplicationLinkCode+[/]+l_oDataTableInfo:NameSpace_Name+[/]+l_oDataTableInfo:Table_Name+[/">Indexes</a>]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]

        l_cHtml += [<table>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Name Space</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboNameSpacePk" id="ComboNameSpacePk"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-select">]
                    select ListOfNameSpaces
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfNameSpaces->pk)+["]+iif(ListOfNameSpaces->pk = l_iNameSpacePk,[ selected],[])+[>]+AllTrim(ListOfNameSpaces->NameSpace_Name)+[</option>]
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Table Name</td>]
                l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
                l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control"></td>]
            l_cHtml += [</tr>]

            if l_nNumberOfTags > 0
                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Tags</td>]
                    l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextTags" id="TextTags" value="]+FcgiPrepFieldForValue(l_cTags)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control" placeholder=""></td>]
                l_cHtml += [</tr>]
            endif

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-select">]
                        l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                        l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                        l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                        l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                        l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                        l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-select">]
                        l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                        l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                        l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                        l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr>]
                l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
                l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr>]
                l_cHtml += [<td valign="top" class="pe-2 pb-3">Information<br><span class="small">Engineering Notes</span><br>]
                l_cHtml += [<a href="https://marked.js.org/" target="_blank"><span class="small">Markdown</span></a>]
                l_cHtml += [</td>]
                l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextInformation" id="TextInformation" rows="10" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cInformation)+[</textarea></td>]
            l_cHtml += [</tr>]

            l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_TABLE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

        l_cHtml += [</table>]
        
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextName').focus();]

    // oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]
    oFcgi:p_cjQueryScript += [$('#TextInformation').resizable();]

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalForms()
endif

return l_cHtml
//=================================================================================================================
static function TableEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTablePk
local l_iNameSpacePk
local l_cTableName
local l_cTableAKA
local l_nTableUseStatus
local l_nTableDocStatus
local l_cTableDescription
local l_cTableInformation
local l_cFrom := ""
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDB2

local l_oDBListOfTagsOnFile
local l_cListOfTagPks
local l_nNumberOfTagTableOnFile
local l_hTagTableOnFile := {=>}
local l_aTagsSelected
local l_cTagSelected
local l_iTagSelectedPk
local l_iTagTablePk

oFcgi:TraceAdd("TableEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTablePk          := Val(oFcgi:GetInputValue("TableKey"))

l_iNameSpacePk      := Val(oFcgi:GetInputValue("ComboNameSpacePk"))
l_cTableName        := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))
l_cTableAKA         := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cTableAKA)
    l_cTableAKA := NIL
endif
l_nTableUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))

l_nTableDocStatus   := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cTableDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_cTableInformation := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextInformation")))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cTableName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("51c9a533-665a-4533-82f3-847bd84bed74","Table")
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
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Table
        with object l_oDB1
            :Table("895da8f1-8cdb-4792-a5b9-3d3b6e646430","Table")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("Table.fk_NameSpace",l_iNameSpacePk)
                :Field("Table.Name"        ,l_cTableName)
                :Field("Table.AKA"         ,l_cTableAKA)
                :Field("Table.UseStatus"   ,l_nTableUseStatus)
            endif
            :Field("Table.DocStatus"   ,l_nTableDocStatus)
            :Field("Table.Description" ,iif(empty(l_cTableDescription),NULL,l_cTableDescription))
            :Field("Table.Information" ,iif(empty(l_cTableInformation),NULL,l_cTableInformation))
            if empty(l_iTablePk)
                if :Add()
                    l_iTablePk := :Key()
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to add Table."
                endif
            else
                if :Update(l_iTablePk)
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to update Table."
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelDD >= 5
                CustomFieldsSave(par_iApplicationPk,USEDON_TABLE,l_iTablePk)

                //Save Tags - Begin

                //Get current list of tags assign to table
                l_oDBListOfTagsOnFile := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDBListOfTagsOnFile
                    :Table("65c615ce-9262-4f7c-b286-7730f44f8ce4","TagTable")
                    :Column("TagTable.pk"      , "TagTable_pk")
                    :Column("TagTable.fk_Tag" , "TagTable_fk_Tag")
                    :Where("TagTable.fk_Table = ^" , l_iTablePk)

                    :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
                    :Where("Tag.fk_Application = ^",par_iApplicationPk)
                    :Where("Tag.TableUseStatus = 2")   // Only care about Active Tags
                    :SQL("ListOfTagsOnFile")

                    l_nNumberOfTagTableOnFile := :Tally
                    if l_nNumberOfTagTableOnFile > 0
                        hb_HAllocate(l_hTagTableOnFile,l_nNumberOfTagTableOnFile)
                        select ListOfTagsOnFile
                        scan all
                            l_hTagTableOnFile[Trans(ListOfTagsOnFile->TagTable_fk_Tag)] := ListOfTagsOnFile->TagTable_pk
                        endscan
                    endif

                endwith

                l_cListOfTagPks := SanitizeInput(oFcgi:GetInputValue("TextTags"))
                if !empty(l_cListOfTagPks)
                    l_aTagsSelected := hb_aTokens(l_cListOfTagPks,",",.f.)
                    for each l_cTagSelected in l_aTagsSelected
                        l_iTagSelectedPk := val(l_cTagSelected)

                        l_iTagTablePk := hb_HGetDef(l_hTagTableOnFile,Trans(l_iTagSelectedPk),0)
                        if l_iTagTablePk > 0
                            //Already on file. Remove from l_hTagTableOnFile
                            hb_HDel(l_hTagTableOnFile,Trans(l_iTagSelectedPk))
                            
                        else
                            // Not on file yet
                            with object l_oDB1
                                :Table("0fb176ac-4e6b-4a0e-9953-bd127f1c0065","TagTable")
                                :Field("TagTable.fk_Tag"  ,l_iTagSelectedPk)
                                :Field("TagTable.fk_Table" ,l_iTablePk)
                                :Add()
                            endwith
                        endif

                    endfor
                endif

                //To through what is left in l_hTagTableOnFile and remove it, since was not keep as selected tag
                for each l_iTagTablePk in l_hTagTableOnFile
                    l_oDB1:Delete("dc72217d-50d8-4b80-84dd-59250678859b","TagTable",l_iTagTablePk)
                endfor

                //Save Tags - End

            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    l_cFrom := oFcgi:GetQueryString('From')
    // switch l_cFrom
    // case 'Columns'
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")
    //     exit
    // case 'Indexes'
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListIndexes/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")
    //     exit
    // otherwise
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
    // endswitch

case l_cActionOnSubmit == "Delete"   // Table
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveApplicationDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteTable(par_iApplicationPk,l_iTablePk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
                l_cFrom := "Redirect"
            endif
        else
            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("c0dabef1-454d-4665-8cac-cc42192cdc6c","Column")
                :Where("Column.fk_Table = ^",l_iTablePk)
                :SQL()

                if :Tally == 0
                    :Table("9a98d575-76ce-4da4-8b8b-13a0e6f67f6b","Column")
                    :Where("Column.fk_TableForeign = ^",l_iTablePk)
                    :SQL()

                    if :Tally == 0
                        :Table("8c926070-36da-4c35-9f63-1db6322e7bdb","Index")
                        :Where("Index.fk_Table = ^",l_iTablePk)
                        :SQL()

                        if :Tally == 0
                            //Delete any DiagramTable related records
                            :Table("3c006261-26e5-4e1a-9164-278f5bd4e31a","DiagramTable")
                            :Column("DiagramTable.pk" , "pk")
                            :Where("DiagramTable.fk_Table = ^",l_iTablePk)
                            :SQL("ListOfDiagramTableRecordsToDelete")
                            if :Tally >= 0
                                if :Tally > 0
                                    select ListOfDiagramTableRecordsToDelete
                                    scan
                                        l_oDB2:Delete("e1d662cd-cbad-4402-96f6-c387aaf6077b","DiagramTable",ListOfDiagramTableRecordsToDelete->pk)
                                    endscan
                                endif

                                //Delete any TagTable related records
                                :Table("daaa1d69-f529-47aa-87bb-0ab2233bc886","TagTable")
                                :Column("TagTable.pk" , "pk")
                                :Where("TagTable.fk_Table = ^",l_iTablePk)
                                :SQL("ListOfTagTableRecordsToDelete")
                                if :Tally >= 0
                                    if :Tally > 0
                                        select ListOfTagTableRecordsToDelete
                                        scan
                                            l_oDB2:Delete("a9c2e2d2-e7ec-4345-9307-4033d7bb4fb3","TagTable",ListOfTagTableRecordsToDelete->pk)
                                        endscan
                                    endif

                                    CustomFieldsDelete(par_iApplicationPk,USEDON_TABLE,l_iTablePk)
                                    if :Delete("dd06ea56-67f7-4175-ad06-4b0f302c402a","Table",l_iTablePk)
                                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
                                        l_cFrom := "Redirect"
                                    else
                                        l_cErrorMessage := "Failed to delete Table"
                                    endif

                                else
                                    l_cErrorMessage := "Failed to clear related TagTable records."
                                endif

                            else
                                l_cErrorMessage := "Failed to clear related DiagramTable records."
                            endif
                        else
                            l_cErrorMessage := "Related Index record on file"
                        endif
                    else
                        l_cErrorMessage := "Related Column record on file (Foreign Key Link)"
                    endif
                else
                    l_cErrorMessage := "Related Column record on file"
                endif
            endwith
        endif
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"
case !empty(l_cErrorMessage)
    l_hValues["Fk_NameSpace"]    := l_iNameSpacePk
    l_hValues["Name"]            := l_cTableName
    l_hValues["AKA"]             := l_cTableAKA
    l_hValues["UseStatus"]       := l_nTableUseStatus
    l_hValues["DocStatus"]       := l_nTableDocStatus
    l_hValues["Description"]     := l_cTableDescription
    l_hValues["Information"]     := l_cTableInformation

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_TABLE,@l_hValues)

    l_cHtml += TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iTablePk,l_hValues)

case empty(l_cFrom) .or. empty(l_iTablePk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")

otherwise
    with object l_oDB1
        :Table("95c1f7a1-500d-4451-95bd-2c4d9df9114a","Table")
        :Column("NameSpace.Name","NameSpace_Name")
        :Column("Table.Name"    ,"Table_Name")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        l_oData := :Get(l_iTablePk)
        if :Tally <> 1
            l_cFrom := ""
        endif
    endwith
    switch l_cFrom
    case 'Columns'
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+l_oData:NameSpace_Name+"/"+l_oData:Table_Name+"/")
        exit
    case 'Indexes'
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListIndexes/"+par_cURLApplicationLinkCode+"/"+l_oData:NameSpace_Name+"/"+l_oData:Table_Name+"/")
        exit
    otherwise
        //Should not happen. Failed :Get.
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
    endswitch
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ColumnListFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cTableAKA)
local l_cHtml := []
local l_oDB_Application   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfColumns := 0
local l_nNumberOfColumnsInSearch := 0
local l_nNumberOfCustomFieldValues := 0
local l_iColumnPk
local l_oData_Application
local l_cApplicationSupportColumns

local l_hOptionValueToDescriptionMapping := {=>}

local l_cSearchColumnName
local l_cSearchColumnDescription

oFcgi:TraceAdd("ColumnListFormBuild")

if oFcgi:isGet() //.and. (len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6]) .and. lower(oFcgi:p_URLPathElements[6]) == "search")  //First access to column list coming from list of tables where the last search included column criteria.
                 //Decided to always start the search with whatever the table list last search was.
    l_cSearchColumnName        := hb_HexToStr(oFcgi:GetQueryString("ColumnName"))
    l_cSearchColumnDescription := hb_HexToStr(oFcgi:GetQueryString("ColumnDescription"))
else
    l_cSearchColumnName        := GetUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName")
    l_cSearchColumnDescription := GetUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription")
endif

with object l_oDB_Application
    :Table("526421bf-2c80-465b-b858-8b485d1a20d0","Table")
    :Column("Application.SupportColumns" , "Application_SupportColumns")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Application","","NameSpace.fk_Application = Application.pk")
    l_oData_Application := :Get(par_iTablePk)
    l_cApplicationSupportColumns := nvl(l_oData_Application:Application_SupportColumns,"")
endwith

with object l_oDB_ListOfColumns
    :Table("ff3cdf85-7085-4999-a2ea-c4c33e8a5520","Column")
    :Where("Column.fk_Table = ^",par_iTablePk)
    l_nNumberOfColumns := :Count()

    :Table("27682ad7-bafd-409f-b6ab-1057770ec119","Column")
    :Column("Column.pk"             ,"pk")
    :Column("Column.Name"           ,"Column_Name")
    :Column("Column.AKA"            ,"Column_AKA")
    :Column("Column.UseStatus"      ,"Column_UseStatus")
    :Column("Column.DocStatus"      ,"Column_DocStatus")
    :Column("Column.Description"    ,"Column_Description")
    :Column("Column.Order"          ,"Column_Order")
    :Column("Column.Type"           ,"Column_Type")
    :Column("Column.Length"         ,"Column_Length")
    :Column("Column.Scale"          ,"Column_Scale")
    :Column("Column.Nullable"       ,"Column_Nullable")
    :Column("Column.Required"       ,"Column_Required")
    :Column("Column.Default"        ,"Column_Default")
    :Column("Column.Unicode"        ,"Column_Unicode")
    :Column("Column.Primary"        ,"Column_Primary")
    :Column("Column.UsedBy"         ,"Column_UsedBy")
    :Column("Column.fk_TableForeign","Column_fk_TableForeign")
    :Column("Column.ForeignKeyUse"  ,"Column_ForeignKeyUse")
    :Column("Column.fk_Enumeration" ,"Column_fk_Enumeration")

    :Column("NameSpace.Name"                ,"NameSpace_Name")
    :Column("Table.Name"                    ,"Table_Name")
    :Column("Table.AKA"                     ,"Table_AKA")
    :Column("Enumeration.Name"              ,"Enumeration_Name")
    :Column("Enumeration.AKA"               ,"Enumeration_AKA")
    :Column("Enumeration.ImplementAs"       ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength"   ,"Enumeration_ImplementLength")
    
    :Join("left","Table"      ,"","Column.fk_TableForeign = Table.pk")
    :Join("left","NameSpace"  ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("left","Enumeration","","Column.fk_Enumeration  = Enumeration.pk")
    :Where("Column.fk_Table = ^",par_iTablePk)

    if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
        :Distinct(.t.)
        if !empty(l_cSearchColumnName)
            :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
        endif
        if !empty(l_cSearchColumnDescription)
            :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
        endif
    endif
    :OrderBy("Column_Order")
    :SQL("ListOfColumns")
    l_nNumberOfColumnsInSearch := :Tally

endwith

if l_nNumberOfColumns > 0
    with object l_oDB_CustomField
        :Table("8f1aab3d-5f57-44c6-b58b-e2756afef2ed","Column")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Column.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Column.fk_Table = ^",par_iTablePk)
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnDescription)
                :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
            endif
        endif
        :Where("CustomField.UsedOn = ^",USEDON_COLUMN)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("6462bd89-41a5-4427-996b-853f9773341f","Column")
        :Column("Column.pk"              ,"fk_entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Column.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Column.fk_Table = ^",par_iTablePk)
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnDescription)
                :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
            endif
        endif
        :Where("CustomField.UsedOn = ^",USEDON_COLUMN)
        :Where("CustomField.Status <= 2")
        // :OrderBy("Column_pk")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

// ExportTableToHtmlFile("ListOfCustomFieldValues","d:\PostgreSQL_ListOfCustomFieldValues.html","From PostgreSQL",,25,.t.)

if l_nNumberOfColumns <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">No Column on file for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+FormatAKAForDisplay(par_cTableAKA)+[".</span>]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms_0" href="]+l_cSitePath+[DataDictionaries/NewColumn/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Column</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditTable/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/?From=Columns">Edit Table</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListIndexes/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Indexes</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewColumn/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Column</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/OrderColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Order Columns</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditTable/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/?From=Columns">Edit Table</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListIndexes/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Indexes</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]


    //Search Bar
    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
    l_cHtml += [<input type="hidden" name="formname" value="List">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<table>]
                l_cHtml += [<tr>]
                    // ----------------------------------------
                    l_cHtml += [<td valign="top">]
                        l_cHtml += [<table>]
                            l_cHtml += [<tr>]
                                l_cHtml += [<td></td>]
                                l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                                l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                            l_cHtml += [</tr>]
                            l_cHtml += [<tr>]
                                l_cHtml += [<td><span class="me-2 ms-3">Column</span></td>]
                                l_cHtml += [<td><input type="text" name="TextColumnName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+["></td>]
                                l_cHtml += [<td><input type="text" name="TextColumnDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnDescription)+["></td>]
                            l_cHtml += [</tr>]
                        l_cHtml += [</table>]
                    l_cHtml += [</td>]
                    // ----------------------------------------
                    l_cHtml += [<td>]  // valign="top"
                        l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-5 me-3" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
                        l_cHtml += [<input type="button" class="btn btn-primary rounded me-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]
                    l_cHtml += [</td>]
                    // ----------------------------------------
                l_cHtml += [</tr>]
            l_cHtml += [</table>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    l_cHtml += [</form>]



    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-center text-white" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"11","12")+[">]
                    if l_nNumberOfColumns == l_nNumberOfColumnsInSearch
                        l_cHtml += [Columns (]+Trans(l_nNumberOfColumns)+[) for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+FormatAKAForDisplay(par_cTableAKA)+["]
                    else
                        l_cHtml += [Columns (]+Trans(l_nNumberOfColumnsInSearch)+[ out of ]+Trans(l_nNumberOfColumns)+[) for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+FormatAKAForDisplay(par_cTableAKA)+["]
                    endif
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white"></th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Nullable</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Required</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Default</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Foreign Key To<br>And Use</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Used By</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfColumns
            scan all
                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        do case
                        case ListOfColumns->Column_Primary
                            l_cHtml += [<i class="bi bi-key"></i>]
                        case " "+lower(ListOfColumns->Column_Name)+" " $ " "+lower(l_cApplicationSupportColumns)+" "
                            l_cHtml += [<i class="bi bi-tools"></i>]
                        case !hb_IsNIL(ListOfColumns->Table_Name)
                            l_cHtml += [<i class="bi-arrow-left"></i>]
                        endcase
                    l_cHtml += [</td>]

                    // Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
// l_cHtml += Trans(ListOfColumns->pk)
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditColumn/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+[/]+ListOfColumns->Column_Name+[/">]+ListOfColumns->Column_Name+FormatAKAForDisplay(ListOfColumns->Column_AKA)+[</a>]
                    l_cHtml += [</td>]

                    // Type
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += FormatColumnTypeInfo(allt(ListOfColumns->Column_Type),;
                                                        ListOfColumns->Column_Length,;
                                                        ListOfColumns->Column_Scale,;
                                                        ListOfColumns->Enumeration_Name,;
                                                        ListOfColumns->Enumeration_AKA,;
                                                        ListOfColumns->Enumeration_ImplementAs,;
                                                        ListOfColumns->Enumeration_ImplementLength,;
                                                        ListOfColumns->Column_Unicode,;
                                                        l_cSitePath,;
                                                        par_cURLApplicationLinkCode,;
                                                        par_cURLNameSpaceName)
                    l_cHtml += [</td>]

                    // Nullable
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(ListOfColumns->Column_Nullable,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    // Required
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += {"","Yes","No"}[iif(vfp_between(ListOfColumns->Column_Required,1,3),ListOfColumns->Column_Required,1)]
                    l_cHtml += [</td>]

                    // Default
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += nvl(ListOfColumns->Column_Default,"")
                    l_cHtml += [</td>]

                    // Foreign Key To and Use
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        if !hb_IsNIL(ListOfColumns->Table_Name)
                            l_cHtml += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+"/"+ListOfColumns->NameSpace_Name+"/"+ListOfColumns->Table_Name+[/">]
                            l_cHtml += ListOfColumns->NameSpace_Name+[.]+ListOfColumns->Table_Name+FormatAKAForDisplay(ListOfColumns->Table_AKA)
                            l_cHtml += [</a>]
                            if !hb_IsNIL(ListOfColumns->Column_ForeignKeyUse)
                                l_cHtml += [<br>]+ListOfColumns->Column_ForeignKeyUse
                            endif
                        endif
                    l_cHtml += [</td>]

                    // Description
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfColumns->Column_Description,""))
                    l_cHtml += [</td>]

                    // Usage Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfColumns->Column_UseStatus,1,6),ListOfColumns->Column_UseStatus,1)]
                    l_cHtml += [</td>]

                    // Doc Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfColumns->Column_DocStatus,1,4),ListOfColumns->Column_DocStatus,1)]
                    l_cHtml += [</td>]

                    // Used By
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += GetItemInListAtPosition(ListOfColumns->Column_UsedBy,{"","MySQL Only","PostgreSQL Only"},"")
                    l_cHtml += [</td>]

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(ListOfColumns->pk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnListFormOnSubmit(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cTableAKA)
local l_cHtml := []

local l_cActionOnSubmit
local l_cTableName
local l_cTableDescription
local l_cColumnName
local l_cColumnDescription
local l_cURL

oFcgi:TraceAdd("ColumnListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cColumnName        := SanitizeInput(oFcgi:GetInputValue("TextColumnName"))
l_cColumnDescription := SanitizeInput(oFcgi:GetInputValue("TextColumnDescription"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName"       ,l_cColumnName)
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription",l_cColumnDescription)

    l_cHtml += ColumnListFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cTableAKA)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName"       ,"")
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription","")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += ColumnListFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cTableAKA)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnOrderFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName)
local l_cHtml := []
local l_oDB_ListOfColumns
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("ColumnOrderFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iTablePk)+[">]
l_cHtml += [<input type="hidden" name="ColumnOrder" id="ColumnOrder" value="">]

l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_ListOfColumns
    :Table("db41b4bd-7cb6-4918-b949-e0e806f959f4","Column")
    :Column("Column.pk"         ,"pk")
    :Column("Column.Name"       ,"Column_Name")
    :Column("Column.AKA"        ,"Column_AKA")
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

l_cHtml += [<div class="m-3">]

    select ListOfColumns

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">Order Columns for Table "]+par_cURLNameSpaceName+[.]+par_cURLTableName+["</span>]
            if oFcgi:p_nAccessLevelDD >= 3
                l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="SendOrderList();" role="button">]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Cancel</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center">]
        l_cHtml += [<div class="col-auto">]

        l_cHtml += [<ul id="sortable">]
        scan all
            l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfColumns->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+ListOfColumns->Column_Name+FormatAKAForDisplay(ListOfColumns->Column_AKA)+[</span></li>]
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

local l_oDB_ListOfColumns
local l_aOrderedPks
local l_Counter

oFcgi:TraceAdd("ColumnOrderFormOnSubmit")

l_cActionOnSubmit   := oFcgi:GetInputValue("ActionOnSubmit")
l_iTablePk          := Val(oFcgi:GetInputValue("TableKey"))
l_cColumnPkOrder    := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("ColumnOrder"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cColumnPkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfColumns
            :Table("70ccaef7-e3bd-4034-9b32-f87c51b7955a","Column")
            :Column("Column.pk","pk")
            :Column("Column.Order","order")
            :Where([Column.fk_Table = ^],l_iTablePk)
            :SQL("ListOfColumn")
    
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
    
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if VFP_Seek(val(l_aOrderedPks[l_Counter]),"ListOfColumn","pk") .and. ListOfColumn->order <> l_Counter
                with object l_oDB_ListOfColumns
                    :Table("ae13b924-6f6c-4241-bbaf-f840225b7057","Column")
                    :Field("Column.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnEditFormBuild(par_iApplicationPk,par_iNameSpacePk,par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")
local l_cName            := hb_HGetDef(par_hValues,"Name","")
local l_cAKA             := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cTags            := nvl(hb_HGetDef(par_hValues,"Tags",""),"")
local l_nUseStatus       := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus       := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription     := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cType            := Alltrim(hb_HGetDef(par_hValues,"Type",""))
local l_cLength          := Trans(hb_HGetDef(par_hValues,"Length",""))
local l_cScale           := Trans(hb_HGetDef(par_hValues,"Scale",""))
local l_lNullable        := hb_HGetDef(par_hValues,"Nullable",.t.)
local l_nRequired        := max(1,hb_HGetDef(par_hValues,"Required",1))
local l_cDefault         := nvl(hb_HGetDef(par_hValues,"Default",""),"")
local l_lUnicode         := hb_HGetDef(par_hValues,"Unicode",.t.)
local l_lPrimary         := hb_HGetDef(par_hValues,"Primary",.f.)
local l_nUsedBy          := hb_HGetDef(par_hValues,"UsedBy",1)
local l_iFk_TableForeign := nvl(hb_HGetDef(par_hValues,"Fk_TableForeign",0),0)
local l_cForeignKeyUse   := nvl(hb_HGetDef(par_hValues,"ForeignKeyUse",""),"")
local l_iFk_Enumeration  := nvl(hb_HGetDef(par_hValues,"Fk_Enumeration",0),0)
local l_cLastNativeType  := hb_HGetDef(par_hValues,"LastNativeType","")
local l_lShowPrimary     := hb_HGetDef(par_hValues,"ShowPrimary",.f.)

local l_iTypeCount
local l_aSQLResult   := {}

local l_oDBEnumeration  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDBTable        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_ScriptFolder
local l_json_Tags
local l_cTagInfo
local l_nNumberOfTags

local l_json_Entities
local l_hEntityNames := {=>}
local l_cEntityInfo
local l_cObjectName

oFcgi:TraceAdd("ColumnEditFormBuild")

with object l_oDB_ListOfTags
    :Table("21c76ae7-77cb-4fc3-8438-b6226711a6f9","Tag")
    :Column("Tag.pk"   , "pk")
    :Column("Tag.Name" , "Tag_Name")
    :Column("upper(Tag.Name)" , "tag1")
    :Column("Tag.Code" , "Tag_Code")
    :Where("Tag.fk_Application = ^" , par_iApplicationPk)
    :Where("Tag.ColumnUseStatus = 2")
    :OrderBy("Tag1")
    :SQL("ListOfTags")
    l_nNumberOfTags := :Tally

    if l_nNumberOfTags > 0
        l_json_Tags := []
        select ListOfTags
        scan all
            if !empty(l_json_Tags)
                l_json_Tags += [,]
            endif
            l_cTagInfo := ListOfTags->Tag_Name + [ (]+ListOfTags->Tag_Code+[)]
            l_json_Tags += "{tag:'"+l_cTagInfo+"',value:"+trans(ListOfTags->pk)+"}"
        endscan

        l_ScriptFolder:= l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]
        oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
        oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

        oFcgi:p_cjQueryScript += [$("#TextTags").amsifySuggestags({]+;
                                                                "suggestions :["+l_json_Tags+"],"+;
                                                                "whiteList: true,"+;
                                                                "tagLimit: 10,"+;
                                                                "selectOnHover: true,"+;
                                                                "showAllSuggestions: true,"+;
                                                                "keepLastOnHoverTag: false"+;
                                                                [});]

        l_cHtml += [<style>]
        l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
        l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 300px;} ]
        l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
        l_cHtml += [</style>]
        
    endif
endwith

with object l_oDBEnumeration
    :Table("6a8f483d-5d48-40ed-a293-e54add5f1790","Enumeration")
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
    :Table("3889c7c9-38c5-4ba5-a023-839bde5e07fd","Table")
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
    l_cHtml += [  $('#SpanLength').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,3],[show],[hide])+[();]
    l_cHtml +=   [$('#SpanScale').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,4],[show],[hide])+[();]
    l_cHtml +=   [$('#SpanEnumeration').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,5],[show],[hide])+[();]
    l_cHtml +=   [$('#TRUnicode').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,6],[show],[hide])+[();]
    l_cHtml += [    break;]
endfor
l_cHtml += [  default:]
l_cHtml += [  $('#SpanLength').hide();$('#SpanScale').hide();$('#SpanEnumeration').hide();]
l_cHtml += [};]

l_cHtml += [};]
l_cHtml += [</script>] 
oFcgi:p_cjQueryScript += [OnChangeType($("#ComboType").val());]

SetSelect2Support()

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += [<input type="hidden" name="CheckShowPrimary" value="]+iif(l_lShowPrimary,"1","0")+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Column in Table "]+par_cURLNameSpaceName+[.]+par_cURLTableName+["</span>]   //navbar-text
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div class="m-3"></div>]


l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    if l_nNumberOfTags > 0
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Tags</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextTags" id="TextTags" value="]+FcgiPrepFieldForValue(l_cTags)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control" placeholder=""></td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Type</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<span class="pe-5">]
                l_cHtml += [<select name="ComboType" id="ComboType" onchange="OnChangeType(this.value);$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]  // ]+UPDATESAVEBUTTON+[
                for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
                    l_cHtml += [<option value="]+oFcgi:p_ColumnTypes[l_iTypeCount,1]+["]+iif(l_cType==oFcgi:p_ColumnTypes[l_iTypeCount,1],[ selected],[])+[>]+oFcgi:p_ColumnTypes[l_iTypeCount,1]+" - "+oFcgi:p_ColumnTypes[l_iTypeCount,2]+[</option>]
                endfor
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanLength" style="display: none;">]
                l_cHtml += [<span class="pe-2">Length</span><input]+UPDATESAVEBUTTON+[ type="text" name="TextLength" id="TextLength" value="]+FcgiPrepFieldForValue(l_cLength)+[" size="5" maxlength="5"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanScale" style="display: none;">]
                l_cHtml += [<span class="pe-2">Scale</span><input]+UPDATESAVEBUTTON+[ type="text" name="TextScale" id="TextScale" value="]+FcgiPrepFieldForValue(l_cScale)+[" size="2" maxlength="2"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanEnumeration" style="display: none;">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboFk_Enumeration" id="ComboFk_Enumeration"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                    l_cHtml += [<option value="0"]+iif(l_iFk_Enumeration==0,[ selected],[])+[></option>]
                    select ListOfEnumeration
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfEnumeration->Enumeration_pk)+["]+iif(ListOfEnumeration->Enumeration_pk == l_iFk_Enumeration,[ selected],[])+[>]+Allt(ListOfEnumeration->Enumeration_Name)+[&nbsp;(]+EnumerationImplementAsInfo(ListOfEnumeration->Enumeration_ImplementAs,ListOfEnumeration->Enumeration_ImplementLength)+[)]+[</option>]
                    endscan
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            if !empty(nvl(l_cLastNativeType,""))
                l_cHtml += [<span class="pe-5" id="SpanLastNativeType">Last Sync/Log Type: ] + l_cLastNativeType + [</span>]
                l_cHtml += [<input type="hidden" name="TextLastNativeType" value="]+FcgiPrepFieldForValue(l_cLastNativeType)+[">]
            endif

        l_cHtml += [</td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Nullable</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckNullable" id="CheckNullable" value="1"]+iif(l_lNullable," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Required</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboRequired" id="ComboRequired"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nRequired==1,[ selected],[])+[>Unknown</option>]
            l_cHtml += [<option value="2"]+iif(l_nRequired==2,[ selected],[])+[>Yes</option>]
            l_cHtml += [<option value="3"]+iif(l_nRequired==3,[ selected],[])+[>No</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]


    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Default</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextDefault" id="TextDefault" value="]+FcgiPrepFieldForValue(l_cDefault)+[" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="TRUnicode">]
        l_cHtml += [<td class="pe-2 pb-3">Unicode</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckUnicode" id="CheckUnicode" value="1"]+iif(l_lUnicode," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]

    if l_lShowPrimary
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Primary</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckPrimary" id="CheckPrimary" value="1"]+iif(l_lPrimary," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]
    endif




    // l_cHtml += [<tr class="pb-5">]
    //     l_cHtml += [<td class="pe-2 pb-3">Foreign Key To</td>]
    //     l_cHtml += [<td class="pb-3">]
    //         //fk_TableForeign
    //         l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboFk_TableForeign" id="ComboFk_TableForeign"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
    //             l_cHtml += [<option value="0"]+iif(l_iFk_TableForeign==0,[ selected],[])+[></option>]
    //             select ListOfTable
    //             scan all
    //                 l_cHtml += [<option value="]+Trans(ListOfTable->Table_pk)+["]+iif(ListOfTable->Table_pk == l_iFk_TableForeign,[ selected],[])+[>]+Allt(ListOfTable->NameSpace_Name)+[.]+Allt(ListOfTable->Table_Name)+[</option>]
    //             endscan
    //         l_cHtml += [</select>]
    //     l_cHtml += [</td>]
    // l_cHtml += [</tr>]





    l_json_Entities := []
    select ListOfTable
    scan all
        if !empty(l_json_Entities)
            l_json_Entities += [,]
        endif
        l_cEntityInfo := Allt(ListOfTable->NameSpace_Name)+[.]+Allt(ListOfTable->Table_Name)
        l_json_Entities += "{id:"+trans(ListOfTable->Table_pk)+",text:'"+l_cEntityInfo+"'}"
        l_hEntityNames[ListOfTable->Table_pk] := l_cEntityInfo
    endscan
    l_json_Entities := "["+l_json_Entities+"]"
    oFcgi:p_cjQueryScript += [$(".SelectEntity").select2({placeholder: '',allowClear: true,data: ]+l_json_Entities+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]


    l_cObjectName := "ComboFk_TableForeign"
    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Foreign Key To</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<select name="]+l_cObjectName+[" id="]+l_cObjectName+[" class="SelectEntity" style="width:600px">]
                if l_iFk_TableForeign == 0
                    oFcgi:p_cjQueryScript += [$("#]+l_cObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
                else
                    l_cHtml += [<option value="]+Trans(l_iFk_TableForeign)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iFk_TableForeign,"")+[</option>]
                endif
            l_cHtml += [</select>]

            //fk_TableForeign
            // l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="]+l_cObjectName+[" id="]+l_cObjectName+["]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                // l_cHtml += [<option value="0"]+iif(l_iFk_TableForeign==0,[ selected],[])+[></option>]
                // select ListOfTable
                // scan all
                //     l_cHtml += [<option value="]+Trans(ListOfTable->Table_pk)+["]+iif(ListOfTable->Table_pk == l_iFk_TableForeign,[ selected],[])+[>]+Allt(ListOfTable->NameSpace_Name)+[.]+Allt(ListOfTable->Table_Name)+[</option>]
                // endscan
            // l_cHtml += [</select>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]







    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Foreign Key Use</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextForeignKeyUse" id="TextForeignKeyUse" value="]+FcgiPrepFieldForValue(l_cForeignKeyUse)+[" maxlength="120" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used By</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUsedBy" id="ComboUsedBy"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedBy==1,[ selected],[])+[>All Servers</option>]
            l_cHtml += [<option value="2"]+iif(l_nUsedBy==2,[ selected],[])+[>MySQL Only</option>]
            l_cHtml += [<option value="3"]+iif(l_nUsedBy==3,[ selected],[])+[>PostgreSQL Only</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_COLUMN,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

    l_cHtml += [</table>]
    

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
local l_cColumnAKA
local l_nColumnUseStatus
local l_nColumnDocStatus
local l_cColumnDescription
local l_cColumnType
local l_cColumnLength
local l_nColumnLength
local l_cColumnScale
local l_nColumnScale
local l_cColumnLastNativeType
local l_lColumnNullable
local l_nColumnRequired
local l_cColumnDefault
local l_lColumnUnicode
local l_lColumnPrimary
local l_nColumnUsedBy
local l_iColumnFk_TableForeign
local l_cColumnForeignKeyUse
local l_iColumnFk_Enumeration
local l_lShowPrimary

local l_iColumnOrder
local l_iTypePos   //The position in the oFcgi:p_ColumnTypes array

local l_hValues := {=>}

local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1

local l_oDBListOfTagsOnFile
local l_cListOfTagPks
local l_nNumberOfTagColumnOnFile
local l_hTagColumnOnFile := {=>}
local l_aTagsSelected
local l_cTagSelected
local l_iTagSelectedPk
local l_iTagColumnPk

oFcgi:TraceAdd("ColumnEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iColumnPk              := Val(oFcgi:GetInputValue("TableKey"))

l_lShowPrimary           := (oFcgi:GetInputValue("CheckShowPrimary") == "1")

l_cColumnName            := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))

l_cColumnAKA             := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cColumnAKA)
    l_cColumnAKA := NIL
endif

l_nColumnUseStatus       := Val(oFcgi:GetInputValue("ComboUseStatus"))

l_cColumnType            := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("ComboType"))

l_cColumnLength          := SanitizeInput(oFcgi:GetInputValue("TextLength"))
l_nColumnLength          := iif(empty(l_cColumnLength),NULL,val(l_cColumnLength))

l_cColumnScale           := SanitizeInput(oFcgi:GetInputValue("TextScale"))
l_nColumnScale           := iif(empty(l_cColumnScale),NULL,val(l_cColumnScale))

l_cColumnLastNativeType  := SanitizeInput(oFcgi:GetInputValue("TextLastNativeType"))

l_lColumnNullable        := (oFcgi:GetInputValue("CheckNullable") == "1")

l_nColumnRequired        := Val(oFcgi:GetInputValue("ComboRequired"))

l_cColumnDefault             := SanitizeInput(oFcgi:GetInputValue("TextDefault"))
if empty(l_cColumnDefault)
    l_cColumnDefault := NIL
endif

l_lColumnUnicode         := (oFcgi:GetInputValue("CheckUnicode") == "1")

if l_lShowPrimary
    l_lColumnPrimary := (oFcgi:GetInputValue("CheckPrimary") == "1")
else
    l_lColumnPrimary := .f.
endif

l_nColumnUsedBy          := Val(oFcgi:GetInputValue("ComboUsedBy"))

l_iColumnFk_TableForeign := Val(oFcgi:GetInputValue("ComboFk_TableForeign"))

l_cColumnForeignKeyUse  := SanitizeInput(oFcgi:GetInputValue("TextForeignKeyUse"))

l_iColumnFk_Enumeration  := Val(oFcgi:GetInputValue("ComboFk_Enumeration"))

l_nColumnDocStatus       := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cColumnDescription     := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cColumnName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("810f0a78-58e8-46d2-87a2-5e29b484d274","Column")
                :Column("Column.pk","pk")
                :Where([Column.fk_Table = ^],par_iTablePk)
                :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cColumnName," ","")))
                if l_iColumnPk > 0
                    :Where([Column.pk != ^],l_iColumnPk)
                endif
                :SQL()
//SendToClipboard(:LastSQL())
            endwith
            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[1] == l_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
                if l_iTypePos <= 0
                    l_cErrorMessage := [Failed to find "Column Type" definition.]
                else
                    
                    do case
                    case (oFcgi:p_ColumnTypes[l_iTypePos,3]) .and. hb_IsNIL(l_nColumnLength)   // Length should be entered
                        l_cErrorMessage := "Length is required!"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,4]) .and. hb_IsNIL(l_nColumnScale)   // Scale should be entered
                        l_cErrorMessage := "Scale is required! Enter at the minimum 0"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,3]) .and. (oFcgi:p_ColumnTypes[l_iTypePos,4]) .and. l_nColumnScale >= l_nColumnLength
                        l_cErrorMessage := "Scale must be smaller than Length!"

                    case (oFcgi:p_ColumnTypes[l_iTypePos,5]) .and. empty(l_iColumnFk_Enumeration)   // Enumeration should be entered
                        l_cErrorMessage := "Select an Enumeration!"

                    otherwise

                    endcase
                endif
            endif

            if empty(l_cErrorMessage)
                //Test that will not mark more than 1 field as Primary
                if l_lColumnPrimary
                    with object l_oDB1
                        :Table("6f19ee39-637d-4995-b157-c4f35a6cb4e3","Column")
                        :Column("Column.pk","pk")
                        :Where([Column.fk_Table = ^],par_iTablePk)
                        :Where("Column.Primary")
                        if l_iColumnPk > 0
                            :Where([Column.pk != ^],l_iColumnPk)
                        endif
                        :SQL()
                        if :tally <> 0
                            l_cErrorMessage := [Another column is already marked as "Primary".]
                        endif
        //SendToClipboard(:LastSQL())
                    endwith
                endif
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //If adding a column, find out what the last order is
        l_iColumnOrder := 1
        if empty(l_iColumnPk)
            with object l_oDB1
                :Table("0efc99c4-ae89-44b7-b1ac-437f48b7b60f","Column")
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

        if oFcgi:p_nAccessLevelDD >= 5
            //Blank out any unneeded variable values
            if l_iTypePos > 0  //Should always be the case unless version issue with browser page
                if !(oFcgi:p_ColumnTypes[l_iTypePos,3])
                    l_nColumnLength := NIL
                endif
                if !(oFcgi:p_ColumnTypes[l_iTypePos,4])
                    l_nColumnScale := NIL
                endif
                if !(oFcgi:p_ColumnTypes[l_iTypePos,5])
                    l_iColumnFk_Enumeration := 0
                endif
                // if !(oFcgi:p_ColumnTypes[l_iTypePos,6])    // Will not turn of the Unicode flag, in case column type is switched back to a char ...
                //     l_lColumnUnicode := .f.
                // endif
            endif
        endif

        //Save the Column
        with object l_oDB1
            :Table("1a6da9a6-6812-4129-979c-c8b8f848f351","Column")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("Column.Name"            , l_cColumnName)
                :Field("Column.AKA"             , l_cColumnAKA)
                :Field("Column.UseStatus"       , l_nColumnUseStatus)
                :Field("Column.Type"            , l_cColumnType)
                :Field("Column.Length"          , l_nColumnLength)
                :Field("Column.Scale"           , l_nColumnScale)
                :Field("Column.Nullable"        , l_lColumnNullable)
                :Field("Column.Required"        , l_nColumnRequired)
                :Field("Column.Default"         , l_cColumnDefault)
                :Field("Column.Unicode"         , l_lColumnUnicode)
                :Field("Column.Primary"         , l_lColumnPrimary)
                :Field("Column.UsedBy"          , l_nColumnUsedBy)
                :Field("Column.Fk_TableForeign" , l_iColumnFk_TableForeign)
                :Field("Column.ForeignKeyUse"   , iif(empty(l_cColumnForeignKeyUse),NULL,l_cColumnForeignKeyUse))
                :Field("Column.Fk_Enumeration"  , l_iColumnFk_Enumeration)
            endif
            :Field("Column.DocStatus"       , l_nColumnDocStatus)
            :Field("Column.Description"     , iif(empty(l_cColumnDescription),NULL,l_cColumnDescription))
        
            if empty(l_iColumnPk)
                :Field("Column.fk_Table" , par_iTablePk)
                :Field("Column.Order"    ,l_iColumnOrder)
                if :Add()
                    l_iColumnPk := :Key()
                else
                    l_cErrorMessage := "Failed to add Column."
                endif
            else
                if !:Update(l_iColumnPk)
                    l_cErrorMessage := "Failed to update Column."
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelDD >= 5
                CustomFieldsSave(par_iApplicationPk,USEDON_COLUMN,l_iColumnPk)



                //Save Tags - Begin

                //Get current list of tags assign to column
                l_oDBListOfTagsOnFile := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDBListOfTagsOnFile
                    :Table("eb820aa5-53b1-47b5-b13c-8460d6cd3e85","TagColumn")
                    :Column("TagColumn.pk"      , "TagColumn_pk")
                    :Column("TagColumn.fk_Tag" , "TagColumn_fk_Tag")
                    :Where("TagColumn.fk_Column = ^" , l_iColumnPk)

                    :Join("inner","Tag","","TagColumn.fk_Tag = Tag.pk")
                    :Where("Tag.fk_Application = ^",par_iApplicationPk)
                    :Where("Tag.ColumnUseStatus = 2")   // Only care about Active Tags
                    :SQL("ListOfTagsOnFile")

                    l_nNumberOfTagColumnOnFile := :Tally
                    if l_nNumberOfTagColumnOnFile > 0
                        hb_HAllocate(l_hTagColumnOnFile,l_nNumberOfTagColumnOnFile)
                        select ListOfTagsOnFile
                        scan all
                            l_hTagColumnOnFile[Trans(ListOfTagsOnFile->TagColumn_fk_Tag)] := ListOfTagsOnFile->TagColumn_pk
                        endscan
                    endif

                endwith

                l_cListOfTagPks := SanitizeInput(oFcgi:GetInputValue("TextTags"))
                if !empty(l_cListOfTagPks)
                    l_aTagsSelected := hb_aTokens(l_cListOfTagPks,",",.f.)
                    for each l_cTagSelected in l_aTagsSelected
                        l_iTagSelectedPk := val(l_cTagSelected)

                        l_iTagColumnPk := hb_HGetDef(l_hTagColumnOnFile,Trans(l_iTagSelectedPk),0)
                        if l_iTagColumnPk > 0
                            //Already on file. Remove from l_hTagColumnOnFile
                            hb_HDel(l_hTagColumnOnFile,Trans(l_iTagSelectedPk))
                            
                        else
                            // Not on file yet
                            with object l_oDB1
                                :Table("f8b01e24-aac8-438c-9f2c-470dc7bdc46d","TagColumn")
                                :Field("TagColumn.fk_Tag"   ,l_iTagSelectedPk)
                                :Field("TagColumn.fk_Column" ,l_iColumnPk)
                                :Add()
                            endwith
                        endif

                    endfor
                endif

                //To through what is left in l_hTagColumnOnFile and remove it, since was not keep as selected tag
                for each l_iTagColumnPk in l_hTagColumnOnFile
                    l_oDB1:Delete("f38d1def-8ccd-444c-a710-bca48bb1f9e6","TagColumn",l_iTagColumnPk)
                endfor

                //Save Tags - End

            endif
        endwith

        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")
    endif


case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

case l_cActionOnSubmit == "Delete"   // Column
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("76bb226a-b9fc-4709-b21a-2d8565d547fb","IndexColumn")
            :Where("IndexColumn.fk_Column = ^",l_iColumnPk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            CustomFieldsDelete(par_iApplicationPk,USEDON_COLUMN,l_iColumnPk)
            l_oDB1:Delete("57e4ebae-00bf-4438-9c47-18e21601260a","Column",l_iColumnPk)

            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+"/")

        else
            l_cErrorMessage := "Related Index Expression record on file"

        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cColumnName
    l_hValues["AKA"]             := l_cColumnAKA
    l_hValues["UseStatus"]       := l_nColumnUseStatus
    l_hValues["DocStatus"]       := l_nColumnDocStatus
    l_hValues["Description"]     := l_cColumnDescription
    l_hValues["Type"]            := l_cColumnType
    l_hValues["Length"]          := l_nColumnLength
    l_hValues["Scale"]           := l_nColumnScale
    l_hValues["LastNativeType"]  := l_cColumnLastNativeType
    l_hValues["Nullable"]        := l_lColumnNullable
    l_hValues["Required"]        := l_nColumnRequired
    l_hValues["Default"]         := l_cColumnDefault
    l_hValues["Unicode"]         := l_lColumnUnicode
    l_hValues["ShowPrimary"]     := l_lShowPrimary
    l_hValues["Primary"]         := l_lColumnPrimary
    l_hValues["UsedBy"]          := l_nColumnUsedBy
    l_hValues["Fk_TableForeign"] := l_iColumnFk_TableForeign
    l_hValues["ForeignKeyUse"]   := l_cColumnForeignKeyUse
    l_hValues["Fk_Enumeration"]  := l_iColumnFk_Enumeration

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_COLUMN,@l_hValues)

    l_cHtml += ColumnEditFormBuild(par_iApplicationPk,par_iNameSpacePk,par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,l_cErrorMessage,l_iColumnPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function IndexListFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLTableName,par_cTableAKA)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfIndexes

oFcgi:TraceAdd("IndexListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("0154af03-a45d-4a8a-811f-c45d09da73f7","Index")
    :Column("Index.pk"             ,"pk")
    :Column("Index.Name"           ,"Index_Name")
    :Column("Index.Expression"     ,"Index_Expression")
    :Column("Index.Unique"         ,"Index_Unique")
    :Column("Index.Algo"           ,"Index_Algo")
    :Column("Index.UseStatus"      ,"Index_UseStatus")
    :Column("Index.DocStatus"      ,"Index_DocStatus")
    :Column("Index.Description"    ,"Index_Description")
    :Column("Index.UsedBy"         ,"Index_UsedBy")
    :Column("upper(Index.Name)"    ,"tag1")
    
    :Where("Index.fk_Table = ^",par_iTablePk)
    :OrderBy("tag1")
    :SQL("ListOfIndexes")
    l_nNumberOfIndexes := :Tally

    // ExportTableToHtmlFile("ListOfIndexes","d:\PostgreSQL_ListOfIndexes.html","From PostgreSQL",,25,.t.)

endwith

// l_cHtml += [<div class="m-3">]
// l_cHtml += [</div>]

if l_nNumberOfIndexes <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">No Index on file for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+FormatAKAForDisplay(par_cTableAKA)+[".</span>]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-0" href="]+l_cSitePath+[DataDictionaries/NewIndex/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Index</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditTable/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/?From=Indexes">Edit Table</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Columns</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewIndex/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">New Index</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Back To Tables</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditTable/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/?From=Indexes">Edit Table</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLTableName+[/">Columns</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]


            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-center text-white" colspan="8">]
                    l_cHtml += [Indexes (]+Trans(l_nNumberOfIndexes)+[) for Table "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLTableName)+FormatAKAForDisplay(par_cTableAKA)+["]
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Expression</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Unique</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Algo</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Used By</th>]
            l_cHtml += [</tr>]

            select ListOfIndexes
            scan all
                l_cHtml += [<tr>]

                    // Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditIndex/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLTableName+[/]+Allt(ListOfIndexes->Index_Name)+[/">]+Allt(ListOfIndexes->Index_Name)+[</a>]
                    l_cHtml += [</td>]

                    // Expression
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += hb_DefaultValue(ListOfIndexes->Index_Expression,"")
                    l_cHtml += [</td>]

                    // Unique
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(ListOfIndexes->Index_Unique,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    // Algo
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"BTREE"}[iif(vfp_between(ListOfIndexes->Index_Algo,1,1),ListOfIndexes->Index_Algo,1)]
                        // 1 = BTREE
                    l_cHtml += [</td>]

                    // Description
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfIndexes->Index_Description,""))
                    l_cHtml += [</td>]

                    // Usage Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfIndexes->Index_UseStatus,1,6),ListOfIndexes->Index_UseStatus,1)]
                    l_cHtml += [</td>]

                    // Doc Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfIndexes->Index_DocStatus,1,4),ListOfIndexes->Index_DocStatus,1)]
                    l_cHtml += [</td>]

                    // Used By
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += GetItemInListAtPosition(ListOfIndexes->Index_UsedBy,{"","MySQL Only","PostgreSQL Only"},"")
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumerationListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_iEnumValueCount
local l_nNumberOfEnumerations

oFcgi:TraceAdd("EnumerationListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("a969a3ec-01a9-4aa5-b9f8-d9bd7b1005e7","Enumeration")
    :Column("Enumeration.pk"             ,"pk")
    :Column("NameSpace.Name"             ,"NameSpace_Name")
    :Column("Enumeration.Name"           ,"Enumeration_Name")
    :Column("Enumeration.AKA"            ,"Enumeration_AKA")
    :Column("Enumeration.UseStatus"      ,"Enumeration_UseStatus")
    :Column("Enumeration.DocStatus"      ,"Enumeration_DocStatus")
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
    l_nNumberOfEnumerations := :Tally
endwith

with object l_oDB2
    :Table("0a20a86a-a519-451c-a01b-388f16a4c909","Enumeration")
    :Column("Enumeration.pk" ,"Enumeration_pk")
    :Column("Count(*)" ,"EnumValueCount")
    :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
    :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :GroupBy("Enumeration.pk")
    :SQL("ListOfEnumerationsEnumValueCounts")

    with object :p_oCursor
        :Index("tag1","Enumeration_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith


if l_nNumberOfEnumerations <= 0
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No Enumeration on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary rounded ms-0" href="]+l_cSitePath+[DataDictionaries/NewEnumeration/]+par_cURLApplicationLinkCode+[/">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            // l_cHtml += [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewEnumeration/]+par_cURLApplicationLinkCode+[/">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="7">Enumerations (]+Trans(l_nNumberOfEnumerations)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name Space</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Enumeration Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Implemented As</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Values</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                l_cHtml += [</tr>]

                select ListOfEnumerations
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfEnumerations->NameSpace_Name)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditEnumeration/]+par_cURLApplicationLinkCode+[/]+ListOfEnumerations->NameSpace_Name+[/]+ListOfEnumerations->Enumeration_Name+[/">]+ListOfEnumerations->Enumeration_Name+FormatAKAForDisplay(ListOfEnumerations->Enumeration_AKA)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]+EnumerationImplementAsInfo(ListOfEnumerations->Enumeration_ImplementAs,ListOfEnumerations->Enumeration_ImplementLength)+[</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                            l_iEnumValueCount := iif( VFP_Seek(ListOfEnumerations->pk,"ListOfEnumerationsEnumValueCounts","tag1") , ListOfEnumerationsEnumValueCounts->EnumValueCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfEnumerations->NameSpace_Name)+[/]+Allt(ListOfEnumerations->Enumeration_Name)+[/">]+Trans(l_iEnumValueCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumerations->Enumeration_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfEnumerations->Enumeration_UseStatus,1,6),ListOfEnumerations->Enumeration_UseStatus,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfEnumerations->Enumeration_DocStatus,1,4),ListOfEnumerations->Enumeration_DocStatus,1)]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")

local l_iNameSpacePk     := hb_HGetDef(par_hValues,"Fk_NameSpace",0)
local l_cName            := hb_HGetDef(par_hValues,"Name","")
local l_cAKA             := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_nUseStatus       := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus       := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription     := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_iImplementAs     := hb_HGetDef(par_hValues,"par_iImplementAs",1)
local l_iImplementLength := hb_HGetDef(par_hValues,"par_iImplementLength",1)

local l_oDataTableInfo
local l_oDB1

oFcgi:TraceAdd("EnumerationEditFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1

    :Table("fe972943-4a6c-4e04-b03a-5969abc9a8c6","Enumeration")
    :Column("NameSpace.Name"     ,"NameSpace_Name")
    :Column("Enumeration.Name"   ,"Enumeration_Name")
    :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
    l_oDataTableInfo := :Get(par_iPk)

    :Table("e40fee2e-6e7e-4160-a6a8-c828ba3cf3ea","NameSpace")
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

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

if l_oDB1:Tally <= 0
    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+[You must setup at least one Name Space first]+[</div>]

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Enumeration</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" value="Ok" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    if !empty(l_cErrorText)
        l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Enumeration</span>]   //navbar-text
            if oFcgi:p_nAccessLevelDD >= 3
                l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
            endif
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
            if !empty(par_iPk)
                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
                endif
                l_cHtml += [<a class="btn btn-primary rounded ms-5 HideOnEdit" href="]+l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+l_oDataTableInfo:NameSpace_Name+[/]+l_oDataTableInfo:Enumeration_Name+[/">Values</a>]

            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]

        l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name Space</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboNameSpacePk" id="ComboNameSpacePk"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                select ListOfNameSpaces
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfNameSpaces->pk)+["]+iif(ListOfNameSpaces->pk = l_iNameSpacePk,[ selected],[])+[>]+AllTrim(ListOfNameSpaces->NameSpace_Name)+[</option>]
                endscan
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Enumeration Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Implement As</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<span class="pe-5">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboImplementAs" id="ComboImplementAs" onchange="OnChangeImplementAs(this.value);"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                        l_cHtml += [<option value="1"]+iif(l_iImplementAs==1,[ selected],[])+[>SQL Enum</option>]
                        l_cHtml += [<option value="2"]+iif(l_iImplementAs==2,[ selected],[])+[>Integer</option>]
                        l_cHtml += [<option value="3"]+iif(l_iImplementAs==3,[ selected],[])+[>Numeric</option>]
                        l_cHtml += [<option value="4"]+iif(l_iImplementAs==4,[ selected],[])+[>String (EnumValue Name)</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="ImplementLengthEntry" style="display: none;">]
                l_cHtml += [<span class="pe-2">Length</span><input]+UPDATESAVEBUTTON+[ type="text" size="5" maxlength="5" name="TextImplementLength" id="TextImplementLength" value="]+Trans(l_iImplementLength)+["]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                    l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
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
local l_cEnumerationAKA
local l_iEnumerationUseStatus
local l_iEnumerationDocStatus
local l_cEnumerationDescription
local l_iEnumerationImplementAs
local l_iEnumerationImplementLength
local l_cFrom := ""
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1
local l_oData

oFcgi:TraceAdd("EnumerationEditFormOnSubmit")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

// l_cFormName       := oFcgi:GetInputValue("formname")
l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumerationPk                := Val(oFcgi:GetInputValue("EnumerationKey"))
l_iNameSpacePk                  := Val(oFcgi:GetInputValue("ComboNameSpacePk"))
l_cEnumerationName              := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))

l_cEnumerationAKA               := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cEnumerationAKA)
    l_cEnumerationAKA := NIL
endif

l_iEnumerationUseStatus         := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_iEnumerationDocStatus         := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cEnumerationDescription       := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

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
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cEnumerationName)
            l_cErrorMessage := "Missing Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("5459a2e5-0194-4efb-b051-469e203e3af1","Enumeration")
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
            endif
        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Enumeration
        with object l_oDB1
            :Table("92372d16-01ca-41d7-8f45-d145a2ce3cdc","Enumeration")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("Enumeration.fk_NameSpace"   , l_iNameSpacePk)
                :Field("Enumeration.Name"           , l_cEnumerationName)
                :Field("Enumeration.AKA"            , l_cEnumerationAKA)
                :Field("Enumeration.UseStatus"      , l_iEnumerationUseStatus)
            :Field("Enumeration.ImplementAs"    , l_iEnumerationImplementAs)
            :Field("Enumeration.ImplementLength", iif(vfp_Inlist(l_iEnumerationImplementAs,3,4),l_iEnumerationImplementLength,NULL))
            endif
            :Field("Enumeration.DocStatus"      , l_iEnumerationDocStatus)
            :Field("Enumeration.Description"    , iif(empty(l_cEnumerationDescription),NULL,l_cEnumerationDescription))
            if empty(l_iEnumerationPk)
                if :Add()
                    l_iEnumerationPk := :Key()
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to add Enumeration."
                endif
            else
                if :Update(l_iEnumerationPk)
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to update Enumeration."
                endif
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    l_cFrom := oFcgi:GetQueryString('From')

case l_cActionOnSubmit == "Delete"   // Enumeration
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("1bf31cf6-bbff-48de-95ff-5bbeaa82b77b","Column")
            :Where("Column.fk_Enumeration = ^",l_iEnumerationPk)
            :SQL()
        endwith

        if l_oDB1:Tally == 0
            with object l_oDB1
                :Table("7f34c282-3118-4ebd-84ad-ee8f3110cd3b","EnumValue")
                :Where("EnumValue.fk_Enumeration = ^",l_iEnumerationPk)
                :SQL()
            endwith

            if l_oDB1:Tally == 0
                if l_oDB1:Delete("8f1c66fc-38df-4b14-a43d-5cb8049944e3","Enumeration",l_iEnumerationPk)
                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")
                    l_cFrom := "Redirect"
                else
                    l_cErrorMessage := "Failed to delete Enumeration"
                endif
            else
                l_cErrorMessage := "Related Enumeration Value record on file"
            endif
        else
            l_cErrorMessage := "Related Column record on file"
        endif
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"

case !empty(l_cErrorMessage)
    l_hValues["Fk_NameSpace"]    := l_iNameSpacePk
    l_hValues["Name"]            := l_cEnumerationName
    l_hValues["AKA"]             := l_cEnumerationAKA
    l_hValues["UseStatus"]       := l_iEnumerationUseStatus
    l_hValues["DocStatus"]       := l_iEnumerationDocStatus
    l_hValues["Description"]     := l_cEnumerationDescription
    l_hValues["ImplementAs"]     := l_iEnumerationImplementAs
    l_hValues["ImplementLength"] := l_iEnumerationImplementLength

    l_cHtml += EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iEnumerationPk,l_hValues)

case empty(l_cFrom) .or. empty(l_iEnumerationPk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")
otherwise
    with object l_oDB1
        :Table("da356f83-c733-465e-a73c-e0af9e06d192","Enumeration")
        :Column("NameSpace.Name"  ,"NameSpace_Name")
        :Column("Enumeration.Name","Enumeration_Name")
        :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
        l_oData := :Get(l_iEnumerationPk)
        if :Tally <> 1
            l_cFrom := ""
        endif
    endwith
    switch l_cFrom
    case 'Values'
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+l_oData:NameSpace_Name+"/"+l_oData:Enumeration_Name+"/")
        exit
    otherwise
        //Should not happen. Failed :Get.
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")
    endswitch
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumValueListFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,par_cEnumerationAKA)
local l_cHtml := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfEnumValues
local l_oDB1

oFcgi:TraceAdd("EnumValueListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("6e36b50f-9e7c-43d6-bba3-00d402a649d0","EnumValue")
    :Column("EnumValue.pk"         ,"pk")
    :Column("EnumValue.Name"       ,"EnumValue_Name")
    :Column("EnumValue.AKA"        ,"EnumValue_AKA")
    :Column("EnumValue.Number"     ,"EnumValue_Number")
    :Column("EnumValue.UseStatus"  ,"EnumValue_UseStatus")
    :Column("EnumValue.DocStatus"  ,"EnumValue_DocStatus")
    :Column("EnumValue.Description","EnumValue_Description")
    :Column("EnumValue.Order"      ,"EnumValue_Order")
    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)
    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
    l_nNumberOfEnumValues := :Tally
endwith

if l_nNumberOfEnumValues <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">No Value on file for Enumeration "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLEnumerationName)+FormatAKAForDisplay(par_cEnumerationAKA)+[".</span>]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-0" href="]+l_cSitePath+[DataDictionaries/NewEnumValue/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">New Enumeration Value</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Back To Enumerations</a>]
            l_cHtml += [<a  class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditEnumeration/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/?From=Values">Edit Enumeration</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewEnumValue/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">New Enumeration Value</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Back To Enumerations</a>]
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/OrderEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Order Values</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/EditEnumeration/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/?From=Values">Edit Enumeration</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="5">Values (]+Trans(l_nNumberOfEnumValues)+[) for Enumeration "]+AllTrim(par_cURLNameSpaceName)+[.]+AllTrim(par_cURLEnumerationName)+FormatAKAForDisplay(par_cEnumerationAKA)+["</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Number</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
            l_cHtml += [</tr>]

            select ListOfEnumValues
            scan all
                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditEnumValue/]+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+[/]+ListOfEnumValues->EnumValue_Name+[/">]+ListOfEnumValues->EnumValue_Name+FormatAKAForDisplay(ListOfEnumValues->EnumValue_AKA)+[</a>]
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
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfEnumValues->EnumValue_UseStatus,1,6),ListOfEnumValues->EnumValue_UseStatus,1)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfEnumValues->EnumValue_DocStatus,1,4),ListOfEnumValues->EnumValue_DocStatus,1)]
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

// l_cHtml += [<div class="m-3">]
// l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("EnumValueOrderFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iEnumerationPk)+[">]
l_cHtml += [<input type="hidden" name="ValueOrder" id="ValueOrder" value="">]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("a24b374e-ad17-4af1-a2a3-9c97633f7770","EnumValue")
    :Column("EnumValue.pk"         ,"pk")
    :Column("EnumValue.Name"       ,"EnumValue_Name")
    :Column("EnumValue.AKA"        ,"EnumValue_AKA")
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

// l_cHtml += [<div class="m-3">]
// l_cHtml += [</div>]

select ListOfEnumValues

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Order Values for Enumeration "]+par_cURLNameSpaceName+[.]+par_cURLEnumerationName+["</span>]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="SendOrderList();" role="button">]
        endif
        l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+par_cURLNameSpaceName+[/]+par_cURLEnumerationName+[/">Cancel</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center m-3">]
    l_cHtml += [<div class="col-auto">]

    l_cHtml += [<ul id="sortable">]
    scan all
        l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfEnumValues->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+ListOfEnumValues->EnumValue_Name+FormatAKAForDisplay(ListOfEnumValues->EnumValue_AKA)+[</span></li>]
    endscan
    l_cHtml += [</ul>]

    l_cHtml += [</div>]
l_cHtml += [</div>]


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

oFcgi:TraceAdd("EnumValueOrderFormOnSubmit")

l_cActionOnSubmit   := oFcgi:GetInputValue("ActionOnSubmit")
l_iEnumerationPk    := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValuePkOrder := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("ValueOrder"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cEnumValuePkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("f6a8ddc1-7660-4b39-8e34-db0f197b825b","EnumValue")
            :Column("EnumValue.pk","pk")
            :Column("EnumValue.Order","order")
            :Where([EnumValue.fk_Enumeration = ^],l_iEnumerationPk)
            :SQL("ListOfEnumValue")

            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith

        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if VFP_Seek(val(l_aOrderedPks[l_Counter]),"ListOfEnumValue","pk") .and. ListOfEnumValue->order <> l_Counter
                with object l_oDB1
                    :Table("b2b226c3-c799-4147-8158-d601709cb9a0","EnumValue")
                    :Field("EnumValue.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumValueEditFormBuild(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,par_cErrorText,par_iPk,par_hValues)

//par_cName,par_iNumber,par_nUseStatus,par_nDocStatus,par_cDescription

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cName            := hb_HGetDef(par_hValues,"Name","")
local l_cAKA             := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cNumber          := Trans(hb_HGetDef(par_hValues,"Number",""))
local l_nUseStatus       := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus       := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription     := nvl(hb_HGetDef(par_hValues,"Description",""),"")

oFcgi:TraceAdd("EnumValueEditFormBuild")

// local l_ipcount := pcount()
// local l_test
// altd()
// l_test := hb_IsNIL(par_iNumber)
// l_cNumber      := iif(pcount() > 6 .and. !hb_IsNIL(par_iNumber),Trans(par_iNumber),"")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ EnumValue in Enumeration "]+par_cURLNameSpaceName+[.]+par_cURLEnumerationName+["</span>]   //navbar-text
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Number</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextNumber" id="TextNumber" value="]+FcgiPrepFieldForValue(l_cNumber)+[" maxlength="8" size="8"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
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
local l_cEnumValueAKA
local l_cEnumValueNumber,l_iEnumValueNumber
local l_nEnumValueUseStatus
local l_nEnumValueDocStatus
local l_cEnumValueDescription
local l_iEnumValueOrder
local l_aSQLResult   := {}
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1

oFcgi:TraceAdd("EnumValueEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumValuePk          := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValueName        := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))

l_cEnumValueAKA         := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cEnumValueAKA)
    l_cEnumValueAKA := NIL
endif

//oFcgi:GetInputValue("TextAKA")

l_cEnumValueNumber      := SanitizeInput(oFcgi:GetInputValue("TextNumber"))
l_iEnumValueNumber      := iif(empty(l_cEnumValueNumber),NULL,val(l_cEnumValueNumber))

l_nEnumValueUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nEnumValueDocStatus   := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cEnumValueDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cEnumValueName)
            l_cErrorMessage := "Missing Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("b36fab5b-9f56-432e-a1b5-64b884df1960","EnumValue")
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
            endif
        endif
    endif

    if empty(l_cErrorMessage)
        //If adding an EnumValue, find out what the last order is
        l_iEnumValueOrder := 1
        if empty(l_iEnumValuePk)
            with object l_oDB1
                :Table("576e6f74-c198-4b19-a9bd-b61448a664db","EnumValue")
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
            :Table("1ed0fff1-f702-4c77-b66e-55a468ad8ad2","EnumValue")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("EnumValue.Name"       ,l_cEnumValueName)
                :Field("EnumValue.AKA"        ,l_cEnumValueAKA)
                :Field("EnumValue.Number"     ,l_iEnumValueNumber)
                :Field("EnumValue.UseStatus"  ,l_nEnumValueUseStatus)
            endif
            :Field("EnumValue.DocStatus"  ,l_nEnumValueDocStatus)
            :Field("EnumValue.Description",iif(empty(l_cEnumValueDescription),NULL,l_cEnumValueDescription))
            if empty(l_iEnumValuePk)
                :Field("EnumValue.fk_Enumeration" , par_iEnumerationPk)
                :Field("EnumValue.Order"          ,l_iEnumValueOrder)
                if :Add()
                    l_iEnumValuePk := :Key()
                else
                    l_cErrorMessage := "Failed to add Column."
                endif

            else
                :Update(l_iEnumValuePk)
            endif
        endwith

        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")
    endif


case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")

case l_cActionOnSubmit == "Delete"   // EnumValue
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB1:Delete("7f3486e6-6bbc-4307-b617-5ff00f0ac3ad","EnumValue",l_iEnumValuePk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEnumerationName+"/")
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cEnumValueName
    l_hValues["AKA"]             := l_cEnumValueAKA
    l_hValues["Number"]          := l_iEnumValueNumber
    l_hValues["UseStatus"]       := l_nEnumValueUseStatus
    l_hValues["DocStatus"]       := l_nEnumValueDocStatus
    l_hValues["Description"]     := l_cEnumValueDescription

    l_cHtml += EnumValueEditFormBuild(par_iNameSpacePk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_cURLNameSpaceName,par_cURLEnumerationName,l_cErrorMessage,l_iEnumValuePk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
static function DataDictionaryLoadSchemaStep1FormBuild(par_iPk,par_cErrorText,par_cApplicationName,par_cLinkCode,;
                                                    par_nSyncBackendType,par_cSyncServer,par_nSyncPort,par_cSyncUser,par_cSyncPassword,par_cSyncDatabase,par_cSyncNameSpaces,par_nSyncSetForeignKey)

local l_cHtml := ""
local l_cErrorText         := hb_DefaultValue(par_cErrorText,"")
local l_cApplicationName   := hb_DefaultValue(par_cApplicationName,"")
local l_cLinkCode          := hb_DefaultValue(par_cLinkCode,"")

local l_nSyncBackendType   := hb_DefaultValue(par_nSyncBackendType,0)
local l_cSyncServer        := hb_DefaultValue(par_cSyncServer,"")
local l_nSyncPort          := hb_DefaultValue(par_nSyncPort,0)
local l_cSyncUser          := hb_DefaultValue(par_cSyncUser,"")
local l_cSyncPassword      := hb_DefaultValue(par_cSyncPassword,"")
local l_cSyncDatabase      := hb_DefaultValue(par_cSyncDatabase,"")
local l_cSyncNameSpaces    := hb_DefaultValue(par_cSyncNameSpaces,"")
local l_nSyncSetForeignKey := hb_DefaultValue(par_nSyncSetForeignKey,1)

oFcgi:TraceAdd("DataDictionaryLoadSchemaStep1FormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Step1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

if !empty(par_iPk)
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">Load Schema - Enter Connection Information</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" value="Load" onclick="$('#ActionOnSubmit').val('Load');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]


    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<table>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Server Type</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select name="ComboSyncBackendType" id="ComboSyncBackendType">]
                    l_cHtml += [<option value="0"]+iif(l_nSyncBackendType==0,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="1"]+iif(l_nSyncBackendType==1,[ selected],[])+[>MariaDB</option>]
                    l_cHtml += [<option value="2"]+iif(l_nSyncBackendType==2,[ selected],[])+[>MySQL</option>]
                    l_cHtml += [<option value="3"]+iif(l_nSyncBackendType==3,[ selected],[])+[>PostgreSQL</option>]
                    l_cHtml += [<option value="4"]+iif(l_nSyncBackendType==4,[ selected],[])+[>MS SQL</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Server Address/IP</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncServer" id="TextSyncServer" value="]+FcgiPrepFieldForValue(l_cSyncServer)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Port (If not default)</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="SyncPort" id="SyncPort" value="]+iif(empty(l_nSyncPort),"",Trans(l_nSyncPort))+[" maxlength="10" size="10"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">User Name</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncUser" id="TextSyncUser" value="]+FcgiPrepFieldForValue(l_cSyncUser)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Password</td>]
                l_cHtml += [<td class="pb-3"><input type="password" name="TextSyncPassword" id="TextSyncPassword" value="]+FcgiPrepFieldForValue(l_cSyncPassword)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Database</td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncDatabase" id="TextSyncDatabase" value="]+FcgiPrepFieldForValue(l_cSyncDatabase)+[" maxlength="200" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Name Spaces<small><br>("schema" in PostgreSQL)<br>(optional, "," separated)</small></td>]
                l_cHtml += [<td class="pb-3"><input type="text" name="TextSyncNameSpaces" id="TextSyncNameSpaces" value="]+FcgiPrepFieldForValue(l_cSyncNameSpaces)+[" maxlength="400" size="80"></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Set Foreign Key</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select name="ComboSyncSetForeignKey" id="ComboSyncSetForeignKey">]
                    l_cHtml += [<option value="1"]+iif(l_nSyncSetForeignKey==1,[ selected],[])+[>Not</option>]
                    l_cHtml += [<option value="2"]+iif(l_nSyncSetForeignKey==2,[ selected],[])+[>Foreign Key Restrictions</option>]
                    l_cHtml += [<option value="3"]+iif(l_nSyncSetForeignKey==3,[ selected],[])+[>On p_&lt;TableName&gt;</option>]
                    l_cHtml += [<option value="4"]+iif(l_nSyncSetForeignKey==4,[ selected],[])+[>On fk_&lt;TableName&gt;</option>]
                    l_cHtml += [<option value="5"]+iif(l_nSyncSetForeignKey==5,[ selected],[])+[>On &lt;TableName&gt;_id</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
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
static function DataDictionaryLoadSchemaStep1FormOnSubmit(par_iApplicationPk,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_nSyncBackendType
local l_cSyncServer
local l_nSyncPort
local l_cSyncUser
local l_cSyncPassword
local l_cSyncDatabase
local l_cSyncNameSpaces
local l_nSyncSetForeignKey


local l_cErrorMessage := ""
local l_oDB1

local l_cPreviousDefaultRDD
local l_cConnectionString
local l_SQLEngineType
local l_iPort
local l_cDriver
local l_SQLHandle

oFcgi:TraceAdd("DataDictionaryLoadSchemaStep1FormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_nSyncBackendType   := Val(oFcgi:GetInputValue("ComboSyncBackendType"))
l_cSyncServer        := SanitizeInput(oFcgi:GetInputValue("TextSyncServer"))
l_nSyncPort          := Val(oFcgi:GetInputValue("SyncPort"))
l_cSyncUser          := SanitizeInput(oFcgi:GetInputValue("TextSyncUser"))
l_cSyncPassword      := SanitizeInput(oFcgi:GetInputValue("TextSyncPassword"))
l_cSyncDatabase      := SanitizeInput(oFcgi:GetInputValue("TextSyncDatabase"))
l_cSyncNameSpaces    := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextSyncNameSpaces"))
l_nSyncSetForeignKey := Val(oFcgi:GetInputValue("ComboSyncSetForeignKey"))

l_cPreviousDefaultRDD = RDDSETDEFAULT( "SQLMIX" )

do case
case l_cActionOnSubmit == "Load"

    do case
    case empty(l_nSyncBackendType)
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
            :Table("ed077f50-c5c2-4ed0-bb97-5b9aedc081c5","Application")
            :Field("Application.SyncBackendType"  ,l_nSyncBackendType)
            :Field("Application.SyncServer"       ,l_cSyncServer)
            :Field("Application.SyncPort"         ,l_nSyncPort)
            :Field("Application.SyncUser"         ,l_cSyncUser)
            :Field("Application.SyncDatabase"     ,l_cSyncDatabase)
            :Field("Application.SyncNameSpaces"   ,l_cSyncNameSpaces)
            :Field("Application.SyncSetForeignKey",l_nSyncSetForeignKey)
            :Update(par_iApplicationPk)
        endwith


        switch l_nSyncBackendType
        case HB_ORM_BACKENDTYPE_MARIADB
            l_SQLEngineType := HB_ORM_ENGINETYPE_MYSQL
            l_iPort         := iif(empty(l_nSyncPort),3306,l_nSyncPort)
            // l_cDriver       := "MySQL ODBC 8.0 Unicode Driver" //"MariaDB ODBC 3.1 Driver"
            l_cDriver       := "MariaDB ODBC 3.1 Driver"
            exit
        case HB_ORM_BACKENDTYPE_MYSQL
            l_SQLEngineType := HB_ORM_ENGINETYPE_MYSQL
            l_iPort         := iif(empty(l_nSyncPort),3306,l_nSyncPort)
            l_cDriver       := "MySQL ODBC 8.0 Unicode Driver"
            exit
        case HB_ORM_BACKENDTYPE_POSTGRESQL
            l_SQLEngineType := HB_ORM_ENGINETYPE_POSTGRESQL
            l_iPort         := iif(empty(l_nSyncPort),5432,l_nSyncPort)
            l_cDriver       := "PostgreSQL Unicode"
            exit
        case HB_ORM_BACKENDTYPE_MSSQL
            l_SQLEngineType := HB_ORM_ENGINETYPE_MSSQL
            l_iPort         := iif(empty(l_nSyncPort),1433,l_nSyncPort)
            l_cDriver       := "SQL Server"
            exit
        otherwise
            l_iPort := -1
        endswitch


        do case
        case l_iPort == -1
            l_cErrorMessage := "Unknown Server Type"

        case l_nSyncBackendType == HB_ORM_BACKENDTYPE_MARIADB .or. l_nSyncBackendType == HB_ORM_BACKENDTYPE_MYSQL   // MySQL or MariaDB
            // To enable multi statements to be executed, meaning multiple SQL commands separated by ";", had to use the OPTION= setting.
            // See: https://dev.mysql.com/doc/connector-odbc/en/connector-odbc-configuration-connection-parameters.html#codbc-dsn-option-flags
            l_cConnectionString := "SERVER="+l_cSyncServer+";Driver={"+l_cDriver+"};USER="+l_cSyncUser+";PASSWORD="+l_cSyncPassword+";DATABASE="+l_cSyncDatabase+";PORT="+AllTrim(str(l_iPort)+";OPTION=67108864;")
        case l_nSyncBackendType == HB_ORM_BACKENDTYPE_POSTGRESQL   // PostgreSQL
            l_cConnectionString := "Server="+l_cSyncServer+";Port="+AllTrim(str(l_iPort))+";Driver={"+l_cDriver+"};Uid="+l_cSyncUser+";Pwd="+l_cSyncPassword+";Database="+l_cSyncDatabase+";"
        case l_nSyncBackendType == HB_ORM_BACKENDTYPE_MSSQL        // MSSQL
            l_cConnectionString := "Driver={"+l_cDriver+"};Server="+l_cSyncServer+","+AllTrim(str(l_iPort))+";Database="+l_cSyncDatabase+";Uid="+l_cSyncUser+";Pwd="+l_cSyncPassword+";"
        otherwise
            l_cErrorMessage := "Invalid 'Backend Type'"
        endcase
        if !empty(l_cConnectionString)
            l_SQLHandle := hb_RDDInfo( RDDI_CONNECT, { "ODBC", l_cConnectionString })

            if l_SQLHandle == 0
                l_SQLHandle := -1
                l_cErrorMessage := "Unable connect to the server!"+Chr(13)+Chr(10)+Str(hb_RDDInfo( RDDI_ERRORNO ))+Chr(13)+Chr(10)+hb_RDDInfo( RDDI_ERROR )

            else
// SendToDebugView(l_cConnectionString)
               l_cErrorMessage := LoadSchema(l_SQLHandle,par_iApplicationPk,l_SQLEngineType,l_cSyncDatabase,l_cSyncNameSpaces,l_nSyncSetForeignKey)

                hb_RDDInfo(RDDI_DISCONNECT,,"SQLMIX",l_SQLHandle)
                // l_cErrorMessage := "Connected OK"
            endif
        endif

    endcase

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")

endcase

if !empty(l_cErrorMessage)
    l_cHtml += DataDictionaryLoadSchemaStep1FormBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,;
                                                   l_nSyncBackendType,;
                                                   l_cSyncServer,;
                                                   l_nSyncPort,;
                                                   l_cSyncUser,;
                                                   l_cSyncPassword,;
                                                   l_cSyncDatabase,;
                                                   l_cSyncNameSpaces,;
                                                   l_nSyncSetForeignKey)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TagListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfTags

local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("TagListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("9b589450-e9b1-4ef7-adab-86f73e9cb35e","Tag")
    :Column("Tag.pk"             ,"pk")
    :Column("Tag.Name"           ,"Tag_Name")
    :Column("Tag.Code"           ,"Tag_Code")
    :Column("Tag.TableUseStatus" ,"Tag_TableUseStatus")
    :Column("Tag.ColumnUseStatus","Tag_ColumnUseStatus")
    :Column("Tag.Description","Tag_Description")
    :Column("Upper(Tag.Name)","tag1")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfTags")
    l_nNumberOfTags := :Tally
endwith

if empty(l_nNumberOfTags)
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No Tag on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary rounded" href="]+l_cSitePath+[DataDictionaries/NewTag/]+par_cURLApplicationLinkCode+[/">New Tag</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[DataDictionaries/NewTag/]+par_cURLApplicationLinkCode+[/">New Tag</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="5">Tags (]+Trans(l_nNumberOfTags)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Code</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Table<br>Use<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Column<br>Use<br>Status</th>]
                l_cHtml += [</tr>]

                select ListOfTags
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditTag/]+par_cURLApplicationLinkCode+[/]+ListOfTags->Tag_Code+[/">]+ListOfTags->Tag_Name+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += ListOfTags->Tag_Code
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfTags->Tag_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Do Not Use","Active","Discontinued"}[iif(vfp_between(ListOfTags->Tag_TableUseStatus,1,3),ListOfTags->Tag_TableUseStatus,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Do Not Use","Active","Discontinued"}[iif(vfp_between(ListOfTags->Tag_ColumnUseStatus,1,3),ListOfTags->Tag_ColumnUseStatus,1)]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TagEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName            := hb_HGetDef(par_hValues,"Name","")
local l_cCode            := hb_HGetDef(par_hValues,"Code","")
local l_nTableUseStatus  := hb_HGetDef(par_hValues,"TableUseStatus",1)
local l_nColumnUseStatus := hb_HGetDef(par_hValues,"ColumnUseStatus",1)
local l_cDescription     := nvl(hb_HGetDef(par_hValues,"Description",""),"")

oFcgi:TraceAdd("TagEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Tag</span>]   //navbar-text
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="100" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Code</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextCode" id="TextCode" value="]+FcgiPrepFieldForValue(l_cCode)+[" maxlength="10" size="10"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Table Use</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboTableUseStatus" id="ComboTableUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nTableUseStatus==1,[ selected],[])+[>Do Not Use</option>]
                l_cHtml += [<option value="2"]+iif(l_nTableUseStatus==2,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="3"]+iif(l_nTableUseStatus==3,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Column Use</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboColumnUseStatus" id="ComboColumnUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nColumnUseStatus==1,[ selected],[])+[>Do Not Use</option>]
                l_cHtml += [<option value="2"]+iif(l_nColumnUseStatus==2,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="3"]+iif(l_nColumnUseStatus==3,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function TagEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTagPk
local l_cTagName
local l_cTagCode
local l_iTagTableUseStatus
local l_iTagColumnUseStatus
local l_cTagDescription

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("TagEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTagPk              := Val(oFcgi:GetInputValue("TableKey"))
l_cTagName            := Alltrim(SanitizeInput(oFcgi:GetInputValue("TextName")))
l_cTagCode            := upper(SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextCode")))
l_iTagTableUseStatus  := Val(oFcgi:GetInputValue("ComboTableUseStatus"))
l_iTagColumnUseStatus := Val(oFcgi:GetInputValue("ComboColumnUseStatus"))
l_cTagDescription     := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cTagName)
            l_cErrorMessage := "Missing Name"
        else
            if empty(l_cTagCode)
                l_cErrorMessage := "Missing Code"
            else
                l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB1
                    :Table("c671f7b2-b560-45da-a656-29cf252f508a","Tag")
                    :Where([lower(replace(Tag.Name,' ','')) = ^],lower(StrTran(l_cTagName," ","")))
                    :Where([Tag.fk_Application = ^],par_iApplicationPk)
                    if l_iTagPk > 0
                        :Where([Tag.pk != ^],l_iTagPk)
                    endif
                    :SQL()
                endwith

                if l_oDB1:Tally <> 0
                    l_cErrorMessage := "Duplicate Name"
                else


                    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    with object l_oDB1
                        :Table("cda585d1-a34b-4fcb-b595-bed6b9d6cf7b","Tag")
                        :Where([lower(replace(Tag.Code,' ','')) = ^],lower(StrTran(l_cTagCode," ","")))
                        :Where([Tag.fk_Application = ^],par_iApplicationPk)
                        if l_iTagPk > 0
                            :Where([Tag.pk != ^],l_iTagPk)
                        endif
                        :SQL()
                    endwith
                    
                    if l_oDB1:Tally <> 0
                        l_cErrorMessage := "Duplicate Code"
                    else

                        //Save the Tag
                        with object l_oDB1
                            :Table("5a937a3e-c0e9-4b59-a678-c927419cd31f","Tag")
                            :Field("Tag.Code"           ,l_cTagCode)
                            :Field("Tag.Name"           ,l_cTagName)
                            :Field("Tag.TableUseStatus" ,l_iTagTableUseStatus)
                            :Field("Tag.ColumnUseStatus",l_iTagColumnUseStatus)
                            :Field("Tag.Description"    ,iif(empty(l_cTagDescription),NULL,l_cTagDescription))
                            if empty(l_iTagPk)
                                :Field("Tag.fk_Application" , par_iApplicationPk)
                                if :Add()
                                    l_iTagPk := :Key()
                                else
                                    l_cErrorMessage := "Failed to add Tag."
                                endif
                            else
                                if !:Update(l_iTagPk)
                                    l_cErrorMessage := "Failed to update Tag."
                                endif
                                // SendToClipboard(:LastSQL())
                            endif

                        endwith

                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")  //+l_cTagName+"/"
                    endif
                endif
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // Tag
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveApplicationDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteTag(par_iApplicationPk,l_iTagPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("cff1bf6d-698a-4497-891e-4f435abca65c","TagTable")
                :Where("TagTable.fk_Tag = ^",l_iTagPk)
                :SQL()
            endwith

            if l_oDB1:Tally == 0
                with object l_oDB1
                    :Table("cff1bf6d-698a-4497-891e-4f435abca65c","TagColumn")
                    :Where("TagColumn.fk_Tag = ^",l_iTagPk)
                    :SQL()
                endwith

                if l_oDB1:Tally == 0

                    l_oDB1:Delete("8b98caf8-3c1e-47f9-8f2e-975f2c5757a4","Tag",l_iTagPk)
                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")

                else
                    l_cErrorMessage := "Related Column Tag record on file"
                endif
            else
                l_cErrorMessage := "Related Table Tag record on file"
            endif
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cTagName
    l_hValues["Code"]            := l_cTagCode
    l_hValues["TableUseStatus"]  := l_iTagTableUseStatus
    l_hValues["ColumnUseStatus"] := l_iTagColumnUseStatus
    l_hValues["Description"]     := l_cTagDescription

    l_cHtml += TagEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iTagPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CascadeDeleteTable(par_iApplicationPk,par_iTablePk)
local l_cErrorMessage := ""
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("8dea28f8-9666-4d76-a2a0-6797a22c1042","Index")
    :Column("IndexColumn.pk","pk")
    :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
    :Where("Index.fk_Table = ^" , par_iTablePk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete Table. Error 1."
    else
        select ListOfRecordsToDeleteInCascadeDeleteTable
        scan all
            if !:Delete("983c83f7-48dd-4388-be20-43db08a03777","IndexColumn",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                l_cErrorMessage := "Failed to delete Table. Error 2."
                exit
            endif
        endscan

        if empty(l_cErrorMessage)
            :Table("770e1c6b-7997-4003-87ec-d6305a11027a","Index")
            :Column("Index.pk","pk")
            :Where("Index.fk_Table = ^" , par_iTablePk)
            :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
            if :Tally < 0
                l_cErrorMessage := "Failed to delete Table. Error 3."
            else
                select ListOfRecordsToDeleteInCascadeDeleteTable
                scan all
                    if !:Delete("3bd0abf8-44e9-4380-8082-f20521dfe84a","Index",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                        l_cErrorMessage := "Failed to delete Table. Error 4."
                        exit
                    endif
                endscan

                if empty(l_cErrorMessage)

                    :Table("38e49098-14af-4ff8-a09f-71de2bad430b","Column")
                    :Column("Column.pk","pk")
                    :Where("Column.fk_Table = ^" , par_iTablePk)
                    :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
                    if :Tally < 0
                        l_cErrorMessage := "Failed to delete Table. Error 5."
                    else
                        select ListOfRecordsToDeleteInCascadeDeleteTable
                        scan all
                            CustomFieldsDelete(par_iApplicationPk,USEDON_COLUMN,ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                            if !:Delete("03fece13-f350-456d-badc-1a989702e79f","Column",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                                l_cErrorMessage := "Failed to delete Table. Error 6."
                                exit
                            endif
                        endscan
                        if empty(l_cErrorMessage)

                            :Table("08bc2a9b-86fa-4b9d-8b03-67a0e3fdf56e","DiagramTable")
                            :Column("DiagramTable.pk","pk")
                            :Where("DiagramTable.fk_Table = ^" , par_iTablePk)
                            :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
                            if :Tally < 0
                                l_cErrorMessage := "Failed to delete Table. Error 7."
                            else
                                select ListOfRecordsToDeleteInCascadeDeleteTable
                                scan all
                                    if !:Delete("665dad21-e904-404a-8bd4-7aa57025c81b","DiagramTable",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                                        l_cErrorMessage := "Failed to delete Table. Error 8."
                                        exit
                                    endif
                                endscan

                                if empty(l_cErrorMessage)

                                    :Table("6675a32d-34f0-4f4c-a913-19fbd2b980b1","TagTable")
                                    :Column("TagTable.pk","pk")
                                    :Where("TagTable.fk_Table = ^" , par_iTablePk)
                                    :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
                                    if :Tally < 0
                                        l_cErrorMessage := "Failed to delete Table. Error 9."
                                    else
                                        select ListOfRecordsToDeleteInCascadeDeleteTable
                                        scan all
                                            if !:Delete("ed839e1d-2ece-4525-b154-be06afbbc88d","TagTable",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                                                l_cErrorMessage := "Failed to delete Table. Error 10."
                                                exit
                                            endif
                                        endscan

                                        if empty(l_cErrorMessage)

                                            // Clear our Column.fk_TableForeign   par_iTablePk
                                            :Table("15a91705-fad2-42b9-8116-327b39b0d355","Column")
                                            :Column("Column.pk","pk")
                                            :Where("Column.fk_TableForeign = ^" , par_iTablePk)
                                            :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
                                            if :Tally < 0
                                                l_cErrorMessage := "Failed to delete Table. Error 11."
                                            else
                                                select ListOfRecordsToDeleteInCascadeDeleteTable
                                                scan all
                                                    :Table("978e4c66-259d-4a47-be46-89d7420728e8","Column")
                                                    :Field("Column.fk_TableForeign" , 0)
                                                    :Update(ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                                                endscan
                                                
                                                CustomFieldsDelete(par_iApplicationPk,USEDON_TABLE,par_iTablePk)
                                                if !:Delete("b7c803fe-9a16-47f6-9f64-981bce0ee66d","Table",par_iTablePk)
                                                    l_cErrorMessage := "Failed to delete Table. Error 12."
                                                endif
                                            endif
                                        endif
                                    endif
                                endif
                            endif
                        endif
                    endif
                endif
            endif
        endif
    endif
endwith
return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteNameSpace(par_iApplicationPk,par_iNameSpacePk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)  // Since executing a select at this level, may not pass l_oDB1 for reuse.
local l_cErrorMessage := ""

with object l_oDB1

    :Table("40f4bf76-ffc0-45cd-ba04-f84dad486ea3","Table")
    :Column("Table.pk","pk")
    :Where("Table.fk_NameSpace = ^" , par_iNameSpacePk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteNameSpace")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete NameSpace. Error 1."
    else
        select ListOfRecordsToDeleteInCascadeDeleteNameSpace
        scan all
            l_cErrorMessage := CascadeDeleteTable(par_iApplicationPk,ListOfRecordsToDeleteInCascadeDeleteNameSpace->pk)
            if !empty(l_cErrorMessage)
                exit
            endif
        endscan
    endif
    
    if empty(l_cErrorMessage)
        :Table("6f7e5169-b207-4cf9-be62-d61400b38de4","Enumeration")
        :Column("EnumValue.pk","pk")
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
        :Where("Enumeration.fk_NameSpace = ^" , par_iNameSpacePk)
        :SQL("ListOfRecordsToDeleteInCascadeDeleteNameSpace")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete NameSpace. Error 2."
        else
            select ListOfRecordsToDeleteInCascadeDeleteNameSpace
            scan all
                if !:Delete("6ebff3a3-99db-40ef-ade6-a6e9c2642423","EnumValue",ListOfRecordsToDeleteInCascadeDeleteNameSpace->pk)
                    l_cErrorMessage := "Failed to delete NameSpace. Error 3."
                    exit
                endif
            endscan

            if empty(l_cErrorMessage)
                :Table("980a812a-b5c6-4296-96f5-ec8e5ed66947","Enumeration")
                :Column("Enumeration.pk","pk")
                :Where("Enumeration.fk_NameSpace = ^" , par_iNameSpacePk)
                :SQL("ListOfRecordsToDeleteInCascadeDeleteNameSpace")
                if :Tally < 0
                    l_cErrorMessage := "Failed to delete NameSpace. Error 4."
                else
                    select ListOfRecordsToDeleteInCascadeDeleteNameSpace
                    scan all
                        if !:Delete("4c254a46-f12a-4a03-94d1-5850fa61af22","Enumeration",ListOfRecordsToDeleteInCascadeDeleteNameSpace->pk)
                            l_cErrorMessage := "Failed to delete NameSpace. Error 5."
                            exit
                        endif
                    endscan

                    if empty(l_cErrorMessage)
                        CustomFieldsDelete(par_iApplicationPk,USEDON_NAMESPACE,par_iNameSpacePk)
                        if !:Delete("1e8e8f31-df5d-47bf-9b1b-de3f87a6792a","NameSpace",par_iNameSpacePk)
                            l_cErrorMessage := "Failed to delete NameSpace. Error 6."
                        endif
                    endif
                endif
            endif
        endif
    endif
endwith

return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteTag(par_iApplicationPk,par_iTagPk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)  // Since executing a select at this level, may not pass l_oDB1 for reuse.
local l_cErrorMessage := ""

with object l_oDB1
    :Table("fc2f2aa6-527a-49c5-b834-28b4dca1a474","TagTable")
    :Column("TagTable.pk","pk")
    :Where("TagTable.fk_Tag = ^" , par_iTagPk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteTag")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete Tag. Error 1."
    else
        select ListOfRecordsToDeleteInCascadeDeleteTag
        scan all
            if !:Delete("782c27b6-2502-4707-a571-1c714614347f","TagTable",ListOfRecordsToDeleteInCascadeDeleteTag->pk)
                l_cErrorMessage := "Failed to delete Tag. Error 2."
                exit
            endif
        endscan
    endif

    if empty(l_cErrorMessage)
        :Table("4c4c70a7-8915-4485-884d-32c2ea580802","TagColumn")
        :Column("TagColumn.pk","pk")
        :Where("TagColumn.fk_Tag = ^" , par_iTagPk)
        :SQL("ListOfRecordsToDeleteInCascadeDeleteTag")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete Tag. Error 3."
        else
            select ListOfRecordsToDeleteInCascadeDeleteTag
            scan all
                if !:Delete("8add12bf-862a-45a7-acd5-463ba1f2aa96","TagColumn",ListOfRecordsToDeleteInCascadeDeleteTag->pk)
                    l_cErrorMessage := "Failed to delete Tag. Error 4."
                    exit
                endif
            endscan
        endif
    endif

    if empty(l_cErrorMessage)
        if !:Delete("Tag",par_iTagPk)
            l_cErrorMessage := "Failed to delete Tag. Error 5."
        endif
    endif
endwith

return l_cErrorMessage
//=================================================================================================================
