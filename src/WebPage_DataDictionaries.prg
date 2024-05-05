#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageDataDictionaries()
local l_cHtml := []
local l_cHtmlUnderHeader

local l_oDB1
local l_oData
local l_oDB_ListOfAllColumns

local l_cFormName
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationDescription

local l_iNamespacePk
local l_iTagPk
local l_iTablePk
local l_iColumnPk
local l_iIndexPk
local l_iEnumerationPk
local l_iEnumValuePk
local l_iDiagramPk
local l_iTemplateTablePk
local l_iTemplateColumnPk
local l_iDeploymentPk
local l_hValues := {=>}

local l_cApplicationElement := "TABLES"  //Default Element

local l_aSQLResult := {}

local l_cURLAction               := "ListDataDictionaries"
local l_cURLApplicationLinkCode  := ""
local l_cURLNamespaceName        := ""
local l_cURLTagCode              := ""
local l_cURLTableName            := ""
local l_cURLEnumerationName      := ""
local l_cURLColumnName           := ""
local l_nURLColumnUsedBy         := 0
local l_cURLEnumValueName        := ""
local l_cURLTemplateTableName    := ""
local l_cURLTemplateColumnName   := ""
local l_nURLTemplateColumnUsedBy := 0
local l_cURLIndexName            := ""
local l_nURLIndexUsedBy          := 0

// local l_cLinkUIDNamespace   := ""
// local l_cLinkUIDTable       := ""
// local l_cLinkUIDColumn      := ""
// local l_cLinkUIDIndex       := ""
// local l_cLinkUIDEnumeration := ""
// local l_cLinkUIDEnumValue   := ""
local l_cLinkUIDDeployment  := ""

local l_cTableAKA
local l_cEnumerationAKA
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfPrimaryColumns
local l_oDBListOfTagsOnFile
local l_cTags
local l_cLinkUID
local l_cJavaScript

local l_nFk_Deployment

local l_cPrefix
local l_cMacro
local l_hWharfConfig
local l_cCombinedPath

local l_nAccessLevelDD := 1   // None by default
// As per the info in Schema.prg
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything and Import/Export
//     6 - Edit Anything and Load Schema
//     7 - Full Access

local l_cMode

local l_nPos

oFcgi:TraceAdd("BuildPageDataDictionaries")

// Variables
// l_cURLAction
// l_cURLApplicationLinkCode
// l_cURLNamespaceName
// l_cURLTagCode
// l_cURLTableName
// l_cURLEnumerationName
// l_cURLColumnName + l_nURLColumnUsedBy
// l_cURLTemplateTableName
// l_cURLTemplateColumnName
// l_cURLIndexName


//Improved and new way:
// DataDictionaries/                      Same as DataDictionaries/ListDataDictionaries/
// DataDictionaries/DataDictionarySettings/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryImport/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryExport/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryDeploymentTools/<ApplicationLinkCode>/

// DataDictionaries/ListMyDeployments/<ApplicationLinkCode>/
// DataDictionaries/NewMyDeployment/<ApplicationLinkCode>/
// DataDictionaries/EditMyDeployment/<ApplicationLinkCode>/

// DataDictionaries/Visualize/<ApplicationLinkCode>/

// DataDictionaries/TableExportForDataWharfImports/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/TableReferencedBy/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/TableDiagrams/<ApplicationLinkCode>/<NamespaceName>/<TableName>/

// DataDictionaries/ListNamespaces/<ApplicationLinkCode>/
// DataDictionaries/NewNamespace/<ApplicationLinkCode>/
// DataDictionaries/EditNamespace/<ApplicationLinkCode>/<NamespaceName>/

// DataDictionaries/ListTags/<ApplicationLinkCode>/
// DataDictionaries/NewTag/<ApplicationLinkCode>/
// DataDictionaries/EditTag/<ApplicationLinkCode>/<NamespaceName>/

// DataDictionaries/ListTables/<ApplicationLinkCode>/
// DataDictionaries/NewTable/<ApplicationLinkCode>/
// DataDictionaries/EditTable/<ApplicationLinkCode>/<NamespaceName>/<TableName>/

// DataDictionaries/ListColumns/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/OrderColumns/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/NewColumn/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/EditColumn/<ApplicationLinkCode>/<NamespaceName>/<TableName>/<ColumnName>

// DataDictionaries/ListIndexes/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/NewIndex/<ApplicationLinkCode>/<NamespaceName>/<TableName>/
// DataDictionaries/EditIndex/<ApplicationLinkCode>/<NamespaceName>/<TableName>/<IndexName>

// DataDictionaries/ListEnumerations/<ApplicationLinkCode>/
// DataDictionaries/NewEnumeration/<ApplicationLinkCode>/
// DataDictionaries/EditEnumeration/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/

// DataDictionaries/ListEnumValues/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/
// DataDictionaries/OrderEnumValues/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/
// DataDictionaries/NewEnumValue/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/
// DataDictionaries/EditEnumValue/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/<EnumValue>/
// DataDictionaries/EnumerationReferencedBy/<ApplicationLinkCode>/<NamespaceName>/<EnumerationName>/


// DataDictionaries/DataDictionaryExport/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryExportToHarbourORM/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryExportToJSON/<ApplicationLinkCode>/
// DataDictionaries/DataDictionaryExportForDataWharfImports/<ApplicationLinkCode>/

// DataDictionaries/ListTemplateTables/<ApplicationLinkCode>/
// DataDictionaries/NewTemplateTable/<ApplicationLinkCode>/
// DataDictionaries/EditTemplateTable/<ApplicationLinkCode>/<TableName>/

// DataDictionaries/ListTemplateColumns/<ApplicationLinkCode>/<TableName>/
// DataDictionaries/OrderTemplateColumns/<ApplicationLinkCode>/<TableName>/
// DataDictionaries/NewTemplateColumn/<ApplicationLinkCode>/<TableName>/
// DataDictionaries/EditTemplateColumn/<ApplicationLinkCode>/<TableName>/<ColumnName>

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLApplicationLinkCode := oFcgi:p_URLPathElements[3]
    endif

    if el_IsInlist(l_cURLAction,"EditNamespace","EditTable","EditEnumeration","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes","NewIndex","EditIndex","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue","TableExportForDataWharfImports","TableReferencedBy","TableDiagrams","EnumerationReferencedBy")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLNamespaceName := oFcgi:p_URLPathElements[4]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditTable","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes","NewIndex","EditIndex","TableExportForDataWharfImports","TableReferencedBy","TableDiagrams")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLTableName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue","EnumerationReferencedBy")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLEnumerationName := oFcgi:p_URLPathElements[5]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditTag")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLTagCode := oFcgi:p_URLPathElements[4]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditColumn")
        if len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6])
            l_cURLColumnName := oFcgi:p_URLPathElements[6]
            l_nPos := at(":",l_cURLColumnName)
            if empty(l_nPos)
                l_nURLColumnUsedBy := 0
            else
                l_nURLColumnUsedBy := val(substr(l_cURLColumnName,l_nPos+1))
                l_cURLColumnName   := left(l_cURLColumnName,l_nPos-1)
            endif
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditIndex")
        if len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6])
            l_cURLIndexName := oFcgi:p_URLPathElements[6]
            l_nPos := at(":",l_cURLIndexName)
            if empty(l_nPos)
                l_nURLIndexUsedBy := 0
            else
                l_nURLIndexUsedBy := val(substr(l_cURLIndexName,l_nPos+1))
                l_cURLIndexName   := left(l_cURLIndexName,l_nPos-1)
            endif
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditEnumValue")
        if len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6])
            l_cURLEnumValueName := oFcgi:p_URLPathElements[6]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditTemplateTable","ListTemplateColumns","OrderTemplateColumns","NewTemplateColumn","EditTemplateColumn")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLTemplateTableName := oFcgi:p_URLPathElements[4]
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditTemplateColumn")
        if len(oFcgi:p_URLPathElements) >= 5 .and. !empty(oFcgi:p_URLPathElements[5])
            l_cURLTemplateColumnName := oFcgi:p_URLPathElements[5]
            l_nPos := at(":",l_cURLTemplateColumnName)
            if empty(l_nPos)
                l_nURLTemplateColumnUsedBy := 0
            else
                l_nURLColumnUsedBy       := val(substr(l_cURLTemplateColumnName,l_nPos+1))
                l_cURLTemplateColumnName := left(l_cURLTemplateColumnName,l_nPos-1)
            endif
        endif
    endif

    if el_IsInlist(l_cURLAction,"EditMyDeployment")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cLinkUIDDeployment := oFcgi:p_URLPathElements[4]
        endif
    endif

    do case
    case el_IsInlist(l_cURLAction,"ListTables","NewTable","EditTable","ListColumns","OrderColumns","NewColumn","EditColumn","ListIndexes","NewIndex","EditIndex","TableExportForDataWharfImports","TableReferencedBy","TableDiagrams")
        l_cApplicationElement := "TABLES"

    case el_IsInlist(l_cURLAction,"ListTemplateTables","NewTemplateTable","EditTemplateTable","ListTemplateColumns","OrderTemplateColumns","NewTemplateColumn","EditTemplateColumn")
        l_cApplicationElement := "TEMPLATETABLES"

    case el_IsInlist(l_cURLAction,"ListEnumerations","NewEnumeration","EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue","EnumerationReferencedBy")
        l_cApplicationElement := "ENUMERATIONS"

    case el_IsInlist(l_cURLAction,"ListNamespaces","NewNamespace","EditNamespace")
        l_cApplicationElement := "NAMESPACES"

    case el_IsInlist(l_cURLAction,"ListTags","NewTag","EditTag")
        l_cApplicationElement := "TAGS"

    case el_IsInlist(l_cURLAction,"DataDictionarySettings")
        l_cApplicationElement := "SETTINGS"

    case el_IsInlist(l_cURLAction,"DataDictionaryImport")
        l_cApplicationElement := "IMPORT"

    case el_IsInlist(l_cURLAction,"DataDictionaryExport","DataDictionaryExportToHarbourORM","DataDictionaryExportToJSON","DataDictionaryExportForDataWharfImports")
        l_cApplicationElement := "EXPORT"

    case el_IsInlist(l_cURLAction,"DataDictionaryDeploymentTools","ListMyDeployments","NewMyDeployment","EditMyDeployment")
        l_cApplicationElement := "DEVELOPMENTTOOLS"

    case el_IsInlist(l_cURLAction,"Visualize")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            if el_IsInlist(oFcgi:p_URLPathElements[4],"resources","css","mxgraph")
                return [<div>Bad URL - calling for some css or resources - bug in mxgraph</div>]
            endif
        endif
        l_cApplicationElement := "VISUALIZE"

    otherwise
        l_cApplicationElement := "TABLES"

    endcase

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if empty(l_cURLApplicationLinkCode)
        l_iApplicationPk := -1
    else
        with object l_oDB1
            :Table("eee95bea-1fc1-4712-a0c4-772b3a416e1e","Application")
            :Column("Application.pk"          , "pk")
            :Column("Application.Name"        , "Application_Name")
            :Where("Application.LinkCode = ^" ,l_cURLApplicationLinkCode)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB1:Tally == 1
            l_iApplicationPk   := l_aSQLResult[1,1]
            l_cApplicationName := l_aSQLResult[1,2]
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
    // l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    //     l_cHtml += [<div class="input-group">]
    //         l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[DataDictionaries/">Data Dictionaries - Select an Application</a>]
    //     l_cHtml += [</div>]
    // l_cHtml += [</nav>]

    l_cHtml += ApplicationListFormBuild()

case l_cURLAction == "DataDictionarySettings"
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("62f3e291-c7c0-4da7-8874-c839c7c3938c","public.Application")
                :Column("Application.SupportColumns"                                       ,"Application_SupportColumns")
                :Column("Application.AddForeignKeyIndexORMExport"                          ,"Application_AddForeignKeyIndexORMExport")
                :Column("Application.SetMissingOnDeleteToProtect"                          ,"Application_SetMissingOnDeleteToProtect")
                :Column("Application.NoNamespaceChangeOnTablesAndEnumerations"             ,"Application_NoNamespaceChangeOnTablesAndEnumerations")
                :Column("Application.PreventLoadFromDeployments"                           ,"Application_PreventLoadFromDeployments")
                :Column("Application.KeyConfig"                                            ,"Application_KeyConfig")
                :Column("Application.TestTableHasPrimaryKey"                               ,"Application_TestTableHasPrimaryKey")
                :Column("Application.TestForeignKeyTypeMatchPrimaryKey"                    ,"Application_TestForeignKeyTypeMatchPrimaryKey")
                :Column("Application.TestForeignKeyIsNullable"                             ,"Application_TestForeignKeyIsNullable")
                :Column("Application.TestForeignKeyNoDefault"                              ,"Application_TestForeignKeyNoDefault")
                :Column("Application.TestForeignKeyMissingOnDeleteSetting"                 ,"Application_TestForeignKeyMissingOnDeleteSetting")
                :Column("Application.TestEnumerationHasAtLeastOnePresentValue"             ,"Application_TestEnumerationHasAtLeastOnePresentValue")
                :Column("Application.TestEnumerationValueNumberUniqueness"                 ,"Application_TestEnumerationValueNumberUniqueness")
                :Column("Application.TestNumericEnumerationWideEnough"                     ,"Application_TestNumericEnumerationWideEnough")
                :Column("Application.TestMissingForeignKeyTable"                           ,"Application_TestMissingForeignKeyTable")
                :Column("Application.TestMissingEnumerationValues"                         ,"Application_TestMissingEnumerationValues")
                :Column("Application.TestUseOfDiscontinuedEnumeration"                     ,"Application_TestUseOfDiscontinuedEnumeration")
                :Column("Application.TestUseOfDiscontinuedForeignTable"                    ,"Application_TestUseOfDiscontinuedForeignTable")
                :Column("Application.TestIdentifierMaxLengthAsPostgres"                    ,"Application_TestIdentifierMaxLengthAsPostgres")
                :Column("Application.TestValidColumnLengthAndScale"                        ,"Application_TestValidColumnLengthAndScale")
                :Column("Application.TestNoLeadingOrTrainingBlanksInIdentifiers"           ,"Application_TestNoLeadingOrTrainingBlanksInIdentifiers")
                :Column("Application.TestValidNonEnumValueIdentifierAsVariableName"        ,"Application_TestValidNonEnumValueIdentifierAsVariableName")
                :Column("Application.TestValidSQLEnumValueIdentifierAsVariableName"        ,"Application_TestValidSQLEnumValueIdentifierAsVariableName")
                :Column("Application.TestValidSQLEnumValueIdentifierAsAlphaNumericExtended","Application_TestValidSQLEnumValueIdentifierAsAlphaNumericExtended")
                :Column("Application.TestIndexOnPrimaryAndForeignKeys"                     ,"Application_TestIndexOnPrimaryAndForeignKeys")
                :Column("Application.TestUniquenessCaseInsensitiveIdentifiers"             ,"Application_TestUniquenessCaseInsensitiveIdentifiers")
                :Column("Application.TestUniquenessTableSQLEnumerationIdentifiers"         ,"Application_TestUniquenessTableSQLEnumerationIdentifiers")

                l_oData := :Get(l_iApplicationPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]                                                  := l_cApplicationName
                l_hValues["LinkCode"]                                              := l_cURLApplicationLinkCode
                l_hValues["SupportColumns"]                                        := l_oData:Application_SupportColumns
                l_hValues["AddForeignKeyIndexORMExport"]                           := l_oData:Application_AddForeignKeyIndexORMExport
                l_hValues["SetMissingOnDeleteToProtect"]                           := l_oData:Application_SetMissingOnDeleteToProtect
                l_hValues["NoNamespaceChangeOnTablesAndEnumerations"]              := l_oData:Application_NoNamespaceChangeOnTablesAndEnumerations
                l_hValues["PreventLoadFromDeployments"]                            := l_oData:Application_PreventLoadFromDeployments
                l_hValues["KeyConfig"]                                             := l_oData:Application_KeyConfig
                l_hValues["TestTableHasPrimaryKey"]                                := l_oData:Application_TestTableHasPrimaryKey
                l_hValues["TestForeignKeyTypeMatchPrimaryKey"]                     := l_oData:Application_TestForeignKeyTypeMatchPrimaryKey
                l_hValues["TestForeignKeyIsNullable"]                              := l_oData:Application_TestForeignKeyIsNullable
                l_hValues["TestForeignKeyNoDefault"]                               := l_oData:Application_TestForeignKeyNoDefault
                l_hValues["TestForeignKeyMissingOnDeleteSetting"]                  := l_oData:Application_TestForeignKeyMissingOnDeleteSetting
                l_hValues["TestEnumerationHasAtLeastOnePresentValue"]              := l_oData:Application_TestEnumerationHasAtLeastOnePresentValue
                l_hValues["TestEnumerationValueNumberUniqueness"]                  := l_oData:Application_TestEnumerationValueNumberUniqueness
                l_hValues["TestNumericEnumerationWideEnough"]                      := l_oData:Application_TestNumericEnumerationWideEnough
                l_hValues["TestIdentifierMaxLengthAsPostgres"]                     := l_oData:Application_TestIdentifierMaxLengthAsPostgres
                l_hValues["TestMissingForeignKeyTable"]                            := l_oData:Application_TestMissingForeignKeyTable
                l_hValues["TestMissingEnumerationValues"]                          := l_oData:Application_TestMissingEnumerationValues
                l_hValues["TestUseOfDiscontinuedEnumeration"]                      := l_oData:Application_TestUseOfDiscontinuedEnumeration
                l_hValues["TestUseOfDiscontinuedForeignTable"]                     := l_oData:Application_TestUseOfDiscontinuedForeignTable
                l_hValues["TestValidColumnLengthAndScale"]                         := l_oData:Application_TestValidColumnLengthAndScale
                l_hValues["TestNoLeadingOrTrainingBlanksInIdentifiers"]            := l_oData:Application_TestNoLeadingOrTrainingBlanksInIdentifiers
                l_hValues["TestValidNonEnumValueIdentifierAsVariableName"]         := l_oData:Application_TestValidNonEnumValueIdentifierAsVariableName
                l_hValues["TestValidSQLEnumValueIdentifierAsVariableName"]         := l_oData:Application_TestValidSQLEnumValueIdentifierAsVariableName
                l_hValues["TestValidSQLEnumValueIdentifierAsAlphaNumericExtended"] := l_oData:Application_TestValidSQLEnumValueIdentifierAsAlphaNumericExtended
                l_hValues["TestIndexOnPrimaryAndForeignKeys"]                      := l_oData:Application_TestIndexOnPrimaryAndForeignKeys
                l_hValues["TestUniquenessCaseInsensitiveIdentifiers"]              := l_oData:Application_TestUniquenessCaseInsensitiveIdentifiers
                l_hValues["TestUniquenessTableSQLEnumerationIdentifiers"]          := l_oData:Application_TestUniquenessTableSQLEnumerationIdentifiers

                l_cHtml += DataDictionaryEditFormBuild("",l_iApplicationPk,l_hValues)
            endif
        else
            if l_iApplicationPk > 0
                l_cHtml += DataDictionaryEditFormOnSubmit(l_cURLApplicationLinkCode)
            endif
        endif
    endif

case l_cURLAction == "DataDictionaryImport"
    if oFcgi:p_nAccessLevelDD >= 6
        l_cHtmlUnderHeader := []

        if oFcgi:isGet()
            l_cHtmlUnderHeader += DataDictionaryImportStep1FormBuild(l_iApplicationPk,"")
        else
            if l_iApplicationPk > 0
                l_cHtmlUnderHeader += DataDictionaryImportStep1FormOnSubmit(l_iApplicationPk,l_cApplicationName,l_cURLApplicationLinkCode)
            endif
        endif
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        l_cHtml += l_cHtmlUnderHeader
    endif


case l_cURLAction == "DataDictionaryExport"
    if oFcgi:p_nAccessLevelDD >= 6 .and. l_iApplicationPk > 0
        
        l_cHtmlUnderHeader := []

        if oFcgi:isGet()
            l_cHtmlUnderHeader += DataDictionaryExportFormBuild(l_iApplicationPk,"")
        else
            l_cHtmlUnderHeader += DataDictionaryExportFormOnSubmit(l_iApplicationPk,l_cApplicationName,l_cURLApplicationLinkCode)
        endif
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        l_cHtml += l_cHtmlUnderHeader
    
    endif

case el_IsInlist(l_cURLAction,"DataDictionaryExportToHarbourORM","DataDictionaryExportToJSON")
    if oFcgi:p_nAccessLevelDD >= 5
        do case
        case l_cURLAction == "DataDictionaryExportToHarbourORM"
            l_cPrefix := "Harbour"
            l_cHtmlUnderHeader := GetAboveNavbarHeading("Export to Harbour_ORM (WharfConfig) ("+oFcgi:GetQueryString("Backend")+")")
        case l_cURLAction == "DataDictionaryExportToJSON"
            l_cPrefix := "JSON"
            l_cHtmlUnderHeader := GetAboveNavbarHeading("Export to JSON")
        endcase

        l_cHtmlUnderHeader += [<nav class="navbar navbar-light bg-light">]
            l_cHtmlUnderHeader += [<div class="input-group">]
                l_cHtmlUnderHeader += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[DataDictionaries/DataDictionaryExport/]+l_cURLApplicationLinkCode+[/]+[">Other Export</a>]

                l_cHtmlUnderHeader += [<input type="button" role="button" value="Copy To Clipboard" class="btn btn-primary rounded ms-3" id="CopySourceCode" onclick="]
                l_cHtmlUnderHeader += [copyToClip(document.getElementById(']+l_cPrefix+[Code').innerText);return false;">]

            l_cHtmlUnderHeader += [</div>]
        l_cHtmlUnderHeader += [</nav>]

        l_cHtml += GetCopyToClipboardJavaScript("CopySourceCode")

        if oFcgi:isGet()
            l_cHtmlUnderHeader += [<pre id="]+l_cPrefix+[Code" class="ms-3">]
            do case
            case l_cURLAction == "DataDictionaryExportToHarbourORM"
                l_cHtmlUnderHeader += ExportApplicationToHarbour_ORM(l_iApplicationPk,.t.,oFcgi:GetQueryString("Backend"))
            case l_cURLAction == "DataDictionaryExportToJSON"
                l_cMacro := ExportApplicationToHarbour_ORM(l_iApplicationPk,.f.,oFcgi:GetQueryString("Backend"))
                l_cMacro := Strtran(l_cMacro,chr(13),"")
                l_cMacro := Strtran(l_cMacro,chr(10),"")
                l_cMacro := Strtran(l_cMacro,[;],"")
                l_hWharfConfig := &( l_cMacro )

                l_cHtmlUnderHeader += hb_jsonEncode(l_hWharfConfig,.t.)
            endcase
            
            l_cHtmlUnderHeader += [</pre>]
        endif
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        l_cHtml += l_cHtmlUnderHeader
    endif

case l_cURLAction == "DataDictionaryExportForDataWharfImports"
    if oFcgi:p_nAccessLevelDD >= 5

        l_cHtmlUnderHeader := GetAboveNavbarHeading("Export For DataWharf Import")

        l_cHtmlUnderHeader += [<nav class="navbar navbar-light bg-light">]
            l_cHtmlUnderHeader += [<div class="input-group">]
                l_cHtmlUnderHeader += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[DataDictionaries/DataDictionaryExport/]+l_cURLApplicationLinkCode+[/]+[">Other Export</a>]

                if oFcgi:isGet()
                    l_cLinkUID := ExportApplicationForImports(l_iApplicationPk)

                    if !empty(l_cLinkUID)
                        l_cHtmlUnderHeader += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[streamfile?id=]+l_cLinkUID+["]+[>Download Export File</a>]
                    endif
                else
                    l_cLinkUID := ""
                endif

            l_cHtmlUnderHeader += [</div>]
        l_cHtmlUnderHeader += [</nav>]

        if empty(l_cLinkUID)
            l_cHtmlUnderHeader += [<p class="ms-3">Failed to create an Export file.</p>]
        else
            l_cHtmlUnderHeader += [<p class="ms-3">The Export file was created as a ZIP file. Use the "Download Export File" button.</p>]
        endif

        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        l_cHtml += l_cHtmlUnderHeader
    endif

case el_IsInlist(l_cURLAction,"DataDictionaryDeploymentTools")
    l_cMode := iif(l_cURLAction == "DataDictionaryDeploymentTools","DeltaLoadGenScriptUpdate","")

    //Will Build the header after new entities are created.
    l_cHtmlUnderHeader := []

    if oFcgi:isGet()
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("87efb98c-f94f-4202-b97b-c41d8522e288","public.UserSettingApplication")
            :Column("UserSettingApplication.fk_Deployment"    ,"fk_Deployment")
            :Where("UserSettingApplication.fk_Application = ^",l_iApplicationPk)
            :Where("UserSettingApplication.fk_User = ^",oFcgi:p_iUserPk)
            :SQL("ListOfUserSettingApplication")

            do case
            case :Tally == 0 .or. :Tally > 1
                if :Tally > 1  //Some bad data, simply delete all records. The next time will select  diagram it will be saved properly.
                    //More than one setting on file, delete them all
                    select ListOfUserSettingApplication
                    scan all
                        :Delete("f6e73639-7ab3-4a10-bb96-50c60cc7bd14","UserSettingApplication",ListOfUserSettingApplication->pk)
                    endscan
                endif

                //No settings on file
                l_nFk_Deployment     := 0

            case :Tally == 1
                //settings on file
                l_nFk_Deployment     := ListOfUserSettingApplication->Fk_Deployment

            endcase

        endwith

        l_cHtmlUnderHeader += DataDictionaryDeploymentToolsFormBuild(l_cMode,;
                                                    l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode,;
                                                    l_nFk_Deployment,;
                                                    {},"","")


    else
        if l_iApplicationPk > 0
            l_cHtmlUnderHeader += DataDictionaryDeploymentToolsFormOnSubmit(l_cMode,l_iApplicationPk,l_cApplicationName,l_cURLApplicationLinkCode)
        endif
    endif
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += l_cHtmlUnderHeader

case l_cURLAction = "ListMyDeployments"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += DeploymentListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,.t.)

case l_cURLAction = "NewMyDeployment"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    if oFcgi:isGet()
        l_cHtml += DeploymentEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>},.t.)
    else
        l_cHtml += DeploymentEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,.t.)
    endif

case l_cURLAction = "EditMyDeployment"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB1
        :Table("2a79c7c5-bfa4-4cd9-9d5a-842e920f0398","Deployment")
        :Column("Deployment.pk"                 , "Deployment_Pk")
        :Column("Deployment.Name"               , "Deployment_Name")
        :Column("Deployment.Status"             , "Deployment_Status")
        :Column("Deployment.Description"        , "Deployment_Description")
        :Column("Deployment.BackendType"        , "Deployment_BackendType")
        :Column("Deployment.Server"             , "Deployment_Server")
        :Column("Deployment.Port"               , "Deployment_Port")
        :Column("Deployment.User"               , "Deployment_User")
        :Column("Deployment.Database"           , "Deployment_Database")
        :Column("Deployment.Namespaces"         , "Deployment_Namespaces")
        :Column("Deployment.SetForeignKey"      , "Deployment_SetForeignKey")
        :Column("Deployment.PasswordStorage"    , "Deployment_PasswordStorage")
        :Column("Deployment.PasswordConfigKey"  , "Deployment_PasswordConfigKey")
        :Column("Deployment.PasswordEnvVarName" , "Deployment_PasswordEnvVarName")
        :Column("Deployment.AllowUpdates"       , "Deployment_AllowUpdates")

        :Where("Deployment.fk_Application = ^",l_iApplicationPk)
        :Where("Deployment.LinkUID = ^"       ,l_cLinkUIDDeployment)
        :Where("Deployment.fk_User = ^"       ,oFcgi:p_iUserPk)
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListMyDeployments/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iDeploymentPk                 := l_oData:Deployment_Pk

            l_hValues["Name"]               := alltrim(l_oData:Deployment_Name)
            l_hValues["Status"]             := l_oData:Deployment_Status
            l_hValues["Description"]        := l_oData:Deployment_Description
            l_hValues["BackendType"]        := nvl(l_oData:Deployment_BackendType,0)
            l_hValues["Server"]             := alltrim(nvl(l_oData:Deployment_Server,""))
            l_hValues["Port"]               := nvl(l_oData:Deployment_Port,0)
            l_hValues["User"]               := alltrim(nvl(l_oData:Deployment_User,""))
            l_hValues["Database"]           := alltrim(nvl(l_oData:Deployment_Database,""))
            l_hValues["Namespaces"]         := alltrim(nvl(l_oData:Deployment_Namespaces,""))
            l_hValues["SetForeignKey"]      := nvl(l_oData:Deployment_SetForeignKey,0)
            l_hValues["PasswordStorage"]    := nvl(l_oData:Deployment_PasswordStorage,0)
            l_hValues["PasswordConfigKey"]  := alltrim(nvl(l_oData:Deployment_PasswordConfigKey,""))
            l_hValues["PasswordEnvVarName"] := alltrim(nvl(l_oData:Deployment_PasswordEnvVarName,""))
            l_hValues["AllowUpdates"]       := l_oData:Deployment_AllowUpdates

            l_cHtml += DeploymentEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iDeploymentPk,l_hValues,.t.)
        else
            l_cHtml += DeploymentEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,.t.)
        endif
    endif

case l_cURLAction == "Visualize"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
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
                :Field("Diagram.UseStatus"      ,USESTATUS_UNKNOWN)
                :Field("Diagram.DocStatus"      ,DOCTATUS_MISSING)
                :Field("Diagram.RenderMode"     ,RENDERMODE_MXGRAPH)
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
        case l_cFormName == "DuplicateDiagram"
            l_cHtml += DataDictionaryVisualizeDiagramDuplicateOnSubmit(l_iApplicationPk,"",l_cApplicationName,l_cURLApplicationLinkCode)
        endcase
    endif

case l_cURLAction == "ListTables"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    if oFcgi:isGet()
        l_cHtml += TableListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)
    else
        l_cHtml += TableListFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

// Table Name                Includes/Starts With
// Table Description        (Word Search)
// Column Name              Includes/Starts With/Does Not dbExists
// Column Description       (Word Search)

case l_cURLAction == "NewTable"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            oFcgi:p_cjQueryScript += GOINEDITMODE
            l_cHtml += TableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditTable"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    //Executing the following even for POST to ensure the record is still present.
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("a6af8449-79c8-488c-be62-507ef4f0696c","Table")
        :Column("Table.pk"              ,"Table_Pk")
        :Column("Table.fk_Namespace"    ,"Table_fk_Namespace")
        :Column("Table.Name"            ,"Table_Name")
        :Column("Table.TrackNameChanges","Table_TrackNameChanges")
        :Column("Table.AKA"             ,"Table_AKA")
        :Column("Table.UseStatus"       ,"Table_UseStatus")
        :Column("Table.DocStatus"       ,"Table_DocStatus")
        :Column("Table.Description"     ,"Table_Description")
        :Column("Table.Information"     ,"Table_Information")
        :Column("Table.Unlogged"        ,"Table_Unlogged")
        :Column("Table.ExternalId"      ,"Table_ExternalId")
        :Column("Table.TestWarning"     ,"Table_TestWarning")
        
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif
        if left(l_cURLTableName,1) == "~"
            :Where([Table.LinkUID = ^],substr(l_cURLTableName,2))
        else
            :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iTablePk := l_oData:Table_Pk

            l_hValues["Fk_Namespace"]     := l_oData:Table_fk_Namespace
            l_hValues["Name"]             := alltrim(l_oData:Table_Name)
            l_hValues["TrackNameChanges"] := l_oData:Table_TrackNameChanges
            l_hValues["AKA"]              := alltrim(nvl(l_oData:Table_AKA,""))
            l_hValues["UseStatus"]        := l_oData:Table_UseStatus
            l_hValues["DocStatus"]        := l_oData:Table_DocStatus
            l_hValues["Description"]      := l_oData:Table_Description
            l_hValues["Information"]      := l_oData:Table_Information
            l_hValues["Unlogged"]         := l_oData:Table_Unlogged
            l_hValues["TestWarning"]      := l_oData:Table_TestWarning
            l_hValues["ExternalId"]       := l_oData:Table_ExternalId            

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
            l_cHtml += TableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    l_oData := GetTableInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLTableName)
    if !hb_IsNil(l_oData)
        if oFcgi:isGet()
            l_cHtml += ColumnListFormBuild(l_iApplicationPk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
        else
            l_cHtml += ColumnListFormOnSubmit(l_iApplicationPk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "OrderColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    l_oData := GetTableInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLTableName)
    if !hb_IsNil(l_oData)
        if oFcgi:isGet()
            l_cHtml += ColumnOrderFormBuild(l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
        else
            l_cHtml += ColumnOrderFormOnSubmit(l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "NewColumn"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        l_oData := GetTableInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLTableName)
        if !hb_IsNil(l_oData)

            if oFcgi:isGet()
                //Check if any other fields is already marked as "Primary"
                with object l_oDB1
                    :Table("87ad5f41-7f5d-46b1-8f3c-cf83dbcf10c1","Column")
                    :Where("Column.fk_Table = ^" , l_oData:Table_Pk)
                    :Where("Column.UsedAs = 2")
                    :SQL()
                    l_nNumberOfPrimaryColumns := :Tally
                endwith

                oFcgi:p_cjQueryScript += GOINEDITMODE
                l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_oData:Namespace_Pk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData,"",0,iif(empty(l_nNumberOfPrimaryColumns),{"ShowPrimary"=>.t.},{=>}))

            else
                l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_oData:Namespace_Pk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
            endif
        endif
    endif

case l_cURLAction == "EditColumn"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("0f8ba8eb-5046-4183-97de-5182a7a0ef2a","Column")

        :Column("Column.pk"                 ,"Column_pk")
        :Column("Namespace.pk"              ,"Namespace_pk")
        :Column("Table.pk"                  ,"Table_pk")
        :Column("Namespace.Name"            ,"Namespace_Name")
        :Column("Namespace.AKA"             ,"Namespace_AKA")
        :Column("Namespace.LinkUID"         ,"Namespace_LinkUID")
        :Column("Table.Name"                ,"Table_Name")
        :Column("Table.AKA"                 ,"Table_AKA")
        :Column("Table.LinkUID"             ,"Table_LinkUID")
        :Column("Column.Name"               ,"Column_Name")
        :Column("Column.TrackNameChanges"   ,"Column_TrackNameChanges")
        :Column("Column.AKA"                ,"Column_AKA")
        :Column("Column.LinkUID"            ,"Column_LinkUID")
        :Column("Column.StaticUID"          ,"Column_StaticUID")
        :Column("Column.UsedAs"             ,"Column_UsedAs")
        :Column("Column.UsedBy"             ,"Column_UsedBy")
        :Column("Column.UseStatus"          ,"Column_UseStatus")
        :Column("Column.DocStatus"          ,"Column_DocStatus")
        :Column("Column.Description"        ,"Column_Description")
        :Column("Column.Type"               ,"Column_Type")
        :Column("Column.Array"              ,"Column_Array")
        :Column("Column.Length"             ,"Column_Length")
        :Column("Column.Scale"              ,"Column_Scale")
        :Column("Column.Nullable"           ,"Column_Nullable")
        :Column("Column.Unicode"            ,"Column_Unicode")
        :Column("Column.DefaultType"        ,"Column_DefaultType")
        :Column("Column.DefaultCustom"      ,"Column_DefaultCustom")
        :Column("Column.LastNativeType"     ,"Column_LastNativeType")
        :Column("Column.fk_TableForeign"    ,"Column_fk_TableForeign")
        :Column("Column.ForeignKeyUse"      ,"Column_ForeignKeyUse")
        :Column("Column.ForeignKeyOptional" ,"Column_ForeignKeyOptional")
        :Column("Column.OnDelete"           ,"Column_OnDelete")
        :Column("Column.fk_Enumeration"     ,"Column_fk_Enumeration")
        :Column("Column.TestWarning"        ,"Column_TestWarning")
        :Column("Column.ExternalId"         ,"Column_ExternalId")

        :Join("inner","Table"    ,"","Column.fk_Table = Table.pk")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")

        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif
        if left(l_cURLTableName,1) == "~"
            :Where([Table.LinkUID = ^],substr(l_cURLTableName,2))
        else
            :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        endif

        if left(l_cURLColumnName,1) == "~"
            :Where([Column.LinkUID = ^],substr(l_cURLColumnName,2))
        else
            :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cURLColumnName," ","")))
        endif

        if l_nURLColumnUsedBy > 0
            :Where("Column.UsedBy = ^",l_nURLColumnUsedBy)
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
        // SendToClipboard(:LastSQL())
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+l_cURLApplicationLinkCode+"/")
    else
        l_iColumnPk    := l_oData:Column_pk
        l_iNamespacePk := l_oData:Namespace_pk  //Will be used to help get all the enumerations
        l_iTablePk     := l_oData:Table_pk

        if oFcgi:isGet()
            //Check if any other fields is already marked as "Primary"
            with object l_oDB1
                :Table("6a919fef-8beb-4b57-9d58-17d34c332d11","Column")
                :Where("Column.fk_Table = ^" , l_iTablePk)
                :Where("Column.UsedAs = 2")
                :Where("Column.pk <> ^" , l_iColumnPk)
                :SQL()
                l_hValues["ShowPrimary"] := empty(:Tally)
            endwith

            l_hValues["Name"]               := alltrim(l_oData:Column_Name)
            l_hValues["TrackNameChanges"]   := l_oData:Column_TrackNameChanges
            l_hValues["AKA"]                := alltrim(nvl(l_oData:Column_AKA,""))
            l_hValues["StaticUID"]          := l_oData:Column_StaticUID
            l_hValues["UsedAs"]             := l_oData:Column_UsedAs
            l_hValues["UsedBy"]             := l_oData:Column_UsedBy
            l_hValues["UseStatus"]          := l_oData:Column_UseStatus
            l_hValues["DocStatus"]          := l_oData:Column_DocStatus
            l_hValues["Description"]        := l_oData:Column_Description
            l_hValues["Type"]               := alltrim(l_oData:Column_Type)
            l_hValues["Array"]              := l_oData:Column_Array
            l_hValues["Length"]             := l_oData:Column_Length
            l_hValues["Scale"]              := l_oData:Column_Scale
            l_hValues["Nullable"]           := l_oData:Column_Nullable
            l_hValues["Unicode"]            := l_oData:Column_Unicode
            l_hValues["DefaultType"]        := l_oData:Column_DefaultType
            l_hValues["DefaultCustom"]      := l_oData:Column_DefaultCustom
            l_hValues["LastNativeType"]     := l_oData:Column_LastNativeType
            l_hValues["Fk_TableForeign"]    := l_oData:Column_fk_TableForeign
            l_hValues["ForeignKeyUse"]      := l_oData:Column_ForeignKeyUse
            l_hValues["ForeignKeyOptional"] := l_oData:Column_ForeignKeyOptional
            l_hValues["OnDelete"]           := l_oData:Column_OnDelete
            l_hValues["Fk_Enumeration"]     := l_oData:Column_fk_Enumeration
            l_hValues["TestWarning"]        := l_oData:Column_TestWarning
            l_hValues["ExternalId"]         := l_oData:Column_ExternalId
            
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
            l_cHtml += ColumnEditFormBuild(l_iApplicationPk,l_iNamespacePk,l_iTablePk,l_cURLApplicationLinkCode,l_oData,"",l_iColumnPk,l_hValues)
        else
            l_cHtml += ColumnEditFormOnSubmit(l_iApplicationPk,l_iNamespacePk,l_iTablePk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "ListIndexes"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    l_oData := GetTableInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLTableName)
    if !hb_IsNil(l_oData)
        l_cHtml += IndexListFormBuild(l_iApplicationPk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
    endif

case l_cURLAction == "NewIndex"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        l_oData := GetTableInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLTableName)
        if !hb_IsNil(l_oData)
            if oFcgi:isGet()
                oFcgi:p_cjQueryScript += GOINEDITMODE
                l_cHtml += IndexEditFormBuild(l_iApplicationPk,l_oData:Namespace_Pk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData,"",0,{=>})
            else
                l_cHtml += IndexEditFormOnSubmit(l_iApplicationPk,l_oData:Namespace_Pk,l_oData:Table_Pk,l_cURLApplicationLinkCode,l_oData)
            endif
        endif
    endif

case l_cURLAction == "EditIndex"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("1e379604-714d-4cfc-98d7-4a2dad9a210f","Index")

        :Column("Index.pk"          ,"Index_pk")
        :Column("Namespace.pk"      ,"Namespace_pk")
        :Column("Table.pk"          ,"Table_pk")

        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.AKA"        ,"Table_AKA")
        :Column("Table.LinkUID"    ,"Table_LinkUID")
        :Column("Namespace.Name"   ,"Namespace_Name")
        :Column("Namespace.AKA"    ,"Namespace_AKA")
        :Column("Namespace.LinkUID","Namespace_LinkUID")

        :Column("Index.Name"        ,"Index_Name")
        :Column("Index.UsedBy"      ,"Index_UsedBy")
        :Column("Index.UseStatus"   ,"Index_UseStatus")
        :Column("Index.DocStatus"   ,"Index_DocStatus")
        :Column("Index.Description" ,"Index_Description")
        :Column("Index.Unique"      ,"Index_Unique")
        :Column("Index.Expression"  ,"Index_Expression")
        :Column("Index.Algo"        ,"Index_Algo")

        :Column("Index.TestWarning" ,"Index_TestWarning")

        :Join("inner","Table"    ,"","Index.fk_Table = Table.pk")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif
        if left(l_cURLTableName,1) == "~"
            :Where([Table.LinkUID = ^],substr(l_cURLTableName,2))
        else
            :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
        endif

        if left(l_cURLIndexName,1) == "~"
            :Where([Index.LinkUID = ^],substr(l_cURLIndexName,2))
        else
            :Where([lower(replace(Index.Name,' ','')) = ^],lower(StrTran(l_cURLIndexName," ","")))
        endif

        if l_nURLIndexUsedBy > 0
            :Where("Index.UsedBy = ^",l_nURLIndexUsedBy)
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+l_cURLApplicationLinkCode+"/")
    else
        l_iIndexPk     := l_oData:Index_pk
        l_iNamespacePk := l_oData:Namespace_pk
        l_iTablePk     := l_oData:Table_pk

        if oFcgi:isGet()
            l_hValues["Name"]        := alltrim(l_oData:Index_Name)
            l_hValues["UsedBy"]      := l_oData:Index_UsedBy
            l_hValues["UseStatus"]   := l_oData:Index_UseStatus
            l_hValues["DocStatus"]   := l_oData:Index_DocStatus
            l_hValues["Description"] := l_oData:Index_Description
            l_hValues["Unique"]      := l_oData:Index_Unique
            l_hValues["Expression"]  := l_oData:Index_Expression
            l_hValues["Algo"]        := l_oData:Index_Algo
            l_hValues["TestWarning"] := l_oData:Index_TestWarning

            l_oDB_ListOfAllColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB_ListOfAllColumns
                :Table("e5556ad0-dffa-4a8b-a708-60b05c64cdd3","IndexColumn")
                :Column("IndexColumn.fk_Column" , "pk")
                :Where("IndexColumn.fk_Index = ^",l_iIndexPk)
                :SQL("ListOfAllColumns")
                select ListOfAllColumns
                scan all
                    l_hValues["Column"+Trans(ListOfAllColumns->pk)] := .t.
                endscan
            endwith

            l_cHtml += IndexEditFormBuild(l_iApplicationPk,l_iNamespacePk,l_iTablePk,l_cURLApplicationLinkCode,l_oData,"",l_iIndexPk,l_hValues)
        else
            l_cHtml += IndexEditFormOnSubmit(l_iApplicationPk,l_iNamespacePk,l_iTablePk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "ListEnumerations"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    if oFcgi:isGet()
        l_cHtml += EnumerationListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)
    else
        l_cHtml += EnumerationListFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

case l_cURLAction == "NewEnumeration"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            oFcgi:p_cjQueryScript += GOINEDITMODE
            l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditEnumeration"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("1c9e2373-6ded-4456-b4d2-bc63991fd0db","Enumeration")
        :Column("Enumeration.pk"              ,"Enumeration_Pk")
        :Column("Enumeration.fk_Namespace"    ,"Enumeration_fk_Namespace")
        :Column("Enumeration.Name"            ,"Enumeration_Name")
        :Column("Enumeration.TrackNameChanges","Enumeration_TrackNameChanges")
        :Column("Enumeration.AKA"             ,"Enumeration_AKA")
        :Column("Enumeration.UseStatus"       ,"Enumeration_UseStatus")
        :Column("Enumeration.DocStatus"       ,"Enumeration_DocStatus")
        :Column("Enumeration.Description"     ,"Enumeration_Description")
        :Column("Enumeration.ImplementAs"     ,"Enumeration_ImplementAs")
        :Column("Enumeration.ImplementLength" ,"Enumeration_ImplementLength")
        :Column("Enumeration.TestWarning"     ,"Enumeration_TestWarning")
        :Column("Enumeration.ExternalId"      ,"Enumeration_ExternalId")
        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif
        
        if left(l_cURLEnumerationName,1) == "~"
            :Where([Enumeration.LinkUID = ^],substr(l_cURLEnumerationName,2))
        else
            :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iEnumerationPk    := l_oData:Enumeration_Pk

            l_hValues["Fk_Namespace"]     := l_oData:Enumeration_fk_Namespace
            l_hValues["Name"]             := alltrim(l_oData:Enumeration_Name)
            l_hValues["TrackNameChanges"] := l_oData:Enumeration_TrackNameChanges
            l_hValues["AKA"]              := alltrim(nvl(l_oData:Enumeration_AKA,""))
            l_hValues["UseStatus"]        := l_oData:Enumeration_UseStatus
            l_hValues["DocStatus"]        := l_oData:Enumeration_DocStatus
            l_hValues["Description"]      := l_oData:Enumeration_Description
            l_hValues["ImplementAs"]      := l_oData:Enumeration_ImplementAs
            l_hValues["ImplementLength"]  := l_oData:Enumeration_ImplementLength
            l_hValues["TestWarning"]      := l_oData:Enumeration_TestWarning
            l_hValues["ExternalId"]       := l_oData:Enumeration_ExternalId

            l_cHtml += EnumerationEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iEnumerationPk,l_hValues)
        else
            l_cHtml += EnumerationEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListEnumValues"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    l_oData := GetEnumerationInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLEnumerationName)
    if !hb_IsNil(l_oData)

        l_cHtml += EnumValueListFormBuild(l_iApplicationPk,l_oData:Enumeration_Pk,l_cURLApplicationLinkCode,l_oData)
    endif


case l_cURLAction == "EnumerationReferencedBy"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    l_oData := GetEnumerationInfoBasedOnURL(l_iApplicationPk,l_cURLNamespaceName,l_cURLEnumerationName)
    if !hb_IsNil(l_oData)
        l_cHtml += EnumerationReferenceByFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_cURLNamespaceName,l_cURLEnumerationName)
    endif

case l_cURLAction == "OrderEnumValues"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

        //Find the iEnumerationPk
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("0d12fc1c-3b02-4e00-ace2-21eb385eff84","Enumeration")
            :Column("Namespace.Name"     ,"Namespace_Name")
            :Column("Namespace.AKA"      ,"Namespace_AKA")
            :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
            :Column("Enumeration.pk"     ,"Enumeration_Pk")
            :Column("Enumeration.Name"   ,"Enumeration_Name")
            :Column("Enumeration.AKA"    ,"Enumeration_AKA")
            :Column("Enumeration.LinkUID","Enumeration_LinkUID")
            :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
            :Where("Namespace.fk_Application = ^",l_iApplicationPk)

            if left(l_cURLNamespaceName,1) == "~"
                :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
            else
                :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
            endif
            if left(l_cURLEnumerationName,1) == "~"
                :Where([Enumeration.LinkUID = ^],substr(l_cURLEnumerationName,2))
            else
                :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
            endif

            :Limit(1)  // In case we have duplicate pick one of them
            l_oData := :SQL()
        endwith

        if l_oDB1:Tally == 1
            if oFcgi:isGet()
                l_cHtml += EnumValueOrderFormBuild(l_oData:Enumeration_Pk,l_cURLApplicationLinkCode,l_oData)
            else
                l_cHtml += EnumValueOrderFormOnSubmit(l_oData:Enumeration_Pk,l_cURLApplicationLinkCode,l_oData)
            endif
        endif
    endif

case l_cURLAction == "NewEnumValue"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        //Find the iEnumerationPk and iNamespacePk (for Enumerations)

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("9a9489dd-bcf1-4688-b03e-6c706960e140","Enumeration")
            :Column("Namespace.Pk"       ,"Namespace_Pk")
            :Column("Namespace.Name"     ,"Namespace_Name")
            :Column("Namespace.AKA"      ,"Namespace_AKA")
            :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
            :Column("Enumeration.Pk"     ,"Enumeration_Pk")
            :Column("Enumeration.Name"   ,"Enumeration_Name")
            :Column("Enumeration.AKA"    ,"Enumeration_AKA")
            :Column("Enumeration.LinkUID","Enumeration_LinkUID")
            :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
            :Where("Namespace.fk_Application = ^",l_iApplicationPk)

            if left(l_cURLNamespaceName,1) == "~"
                :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
            else
                :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
            endif

            if left(l_cURLEnumerationName,1) == "~"
                :Where([Enumeration.LinkUID = ^],substr(l_cURLEnumerationName,2))
            else
                :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
            endif

            :Limit(1)  // In case we have duplicate pick one of them
            l_oData := :SQL()
        endwith

        if l_oDB1:Tally == 1
            if oFcgi:isGet()
                oFcgi:p_cjQueryScript += GOINEDITMODE
                l_cHtml += EnumValueEditFormBuild(l_oData:Enumeration_Pk,l_cURLApplicationLinkCode,l_oData,"",0,{=>})
            else
                l_cHtml += EnumValueEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,l_oData:Enumeration_Pk,l_oData)
            endif
        endif
    endif

case l_cURLAction == "EditEnumValue"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("b96a6a89-c1b6-4629-8d00-3ebf37e93845","EnumValue")

        :Column("EnumValue.pk"              ,"EnumValue_pk")
        :Column("Namespace.pk"              ,"Namespace_pk")
        :Column("Enumeration.pk"            ,"Enumeration_pk")
        :Column("Namespace.Name"            ,"Namespace_Name")
        :Column("Namespace.AKA"             ,"Namespace_AKA")
        :Column("Namespace.LinkUID"         ,"Namespace_LinkUID")
        :Column("Enumeration.Name"          ,"Enumeration_Name")
        :Column("Enumeration.AKA"           ,"Enumeration_AKA")
        :Column("Enumeration.LinkUID"       ,"Enumeration_LinkUID")
        :Column("EnumValue.Name"            ,"EnumValue_Name")
        :Column("EnumValue.TrackNameChanges","EnumValue_TrackNameChanges")
        :Column("EnumValue.AKA"             ,"EnumValue_AKA")
        :Column("EnumValue.LinkUID"         ,"EnumValue_LinkUID")
        :Column("EnumValue.Number"          ,"EnumValue_Number")
        :Column("EnumValue.Code"            ,"EnumValue_Code")
        :Column("EnumValue.UseStatus"       ,"EnumValue_UseStatus")
        :Column("EnumValue.DocStatus"       ,"EnumValue_DocStatus")
        :Column("EnumValue.Description"     ,"EnumValue_Description")
        :Column("EnumValue.ExternalId"      ,"EnumValue_ExternalId")
        :Column("EnumValue.TestWarning"     ,"EnumValue_TestWarning")

        :Join("inner","Enumeration"    ,"","EnumValue.fk_Enumeration = Enumeration.pk")
        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif
        if left(l_cURLEnumerationName,1) == "~"
            :Where([Enumeration.LinkUID = ^],substr(l_cURLEnumerationName,2))
        else
            :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cURLEnumerationName," ","")))
        endif
        if left(l_cURLEnumValueName,1) == "~"
            :Where([EnumValue.LinkUID = ^],substr(l_cURLEnumValueName,2))
        else
            :Where([lower(replace(EnumValue.Name,' ','')) = ^],lower(StrTran(l_cURLEnumValueName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
// SendToClipboard(:LastSQL())
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()

            l_hValues["Name"]             := alltrim(l_oData:EnumValue_Name)
            l_hValues["TrackNameChanges"] := l_oData:EnumValue_TrackNameChanges
            l_hValues["AKA"]              := alltrim(nvl(l_oData:EnumValue_AKA,""))
            if hb_IsNil(l_oData:EnumValue_Number)
                l_hValues["Number"] := ""
            else
                l_hValues["Number"] := Trans(l_oData:EnumValue_Number)
            endif
            l_hValues["Code"]             := nvl(l_oData:EnumValue_Code,"")
            l_hValues["UseStatus"]        := l_oData:EnumValue_UseStatus
            l_hValues["DocStatus"]        := l_oData:EnumValue_DocStatus
            l_hValues["Description"]      := l_oData:EnumValue_Description
            l_hValues["TestWarning"]      := l_oData:EnumValue_TestWarning
            l_hValues["ExternalId"]       := l_oData:EnumValue_ExternalId

            l_cHtml += EnumValueEditFormBuild(l_oData:Enumeration_pk,l_cURLApplicationLinkCode,l_oData,"",l_oData:EnumValue_pk,l_hValues)
        else
            l_cHtml += EnumValueEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode,l_oData:Enumeration_Pk,l_oData)
        endif
    endif

case l_cURLAction == "ListNamespaces"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += NamespaceListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewNamespace"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            oFcgi:p_cjQueryScript += GOINEDITMODE
            l_cHtml += NamespaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += NamespaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditNamespace"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("f0f2eaea-8306-49c9-afef-d72afb41601c","Namespace")
        :Column("Namespace.pk"              ,"Namespace_Pk")
        :Column("Namespace.Name"            ,"Namespace_Name")
        :Column("Namespace.TrackNameChanges","Namespace_TrackNameChanges")
        :Column("Namespace.AKA"             ,"Namespace_AKA")
        :Column("Namespace.UseStatus"       ,"Namespace_UseStatus")
        :Column("Namespace.DocStatus"       ,"Namespace_DocStatus")
        :Column("Namespace.Description"     ,"Namespace_Description")
        :Column("Namespace.TestWarning"     ,"Namespace_TestWarning")
        :Column("Namespace.ExternalId"      ,"Namespace_ExternalId")

        if left(l_cURLNamespaceName,1) == "~"
            :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
        else
            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
        endif

        :Where([Namespace.fk_Application = ^],l_iApplicationPk)

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListNamespaces/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iNamespacePk    := l_oData:Namespace_Pk

            l_hValues["Name"]             := alltrim(l_oData:Namespace_Name)
            l_hValues["TrackNameChanges"] := l_oData:Namespace_TrackNameChanges
            l_hValues["AKA"]              := alltrim(nvl(l_oData:Namespace_AKA,""))
            l_hValues["UseStatus"]        := l_oData:Namespace_UseStatus
            l_hValues["DocStatus"]        := l_oData:Namespace_DocStatus
            l_hValues["Description"]      := l_oData:Namespace_Description
            l_hValues["TestWarning"]      := l_oData:Namespace_TestWarning
            l_hValues["ExternalId"]       := nvl(l_oData:Namespace_ExternalId,0)

            CustomFieldsLoad(l_iApplicationPk,USEDON_NAMESPACE,l_iNamespacePk,@l_hValues)

            l_cHtml += NamespaceEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iNamespacePk,l_hValues)
        else
            l_cHtml += NamespaceEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListTags"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += TagListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewTag"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            oFcgi:p_cjQueryScript += GOINEDITMODE
            l_cHtml += TagEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += TagEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditTag"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("a5a2cd08-7783-4151-905d-da7c3cb3a2af","Tag")
        :Column("Tag.pk"             , "Tag_Pk")
        :Column("Tag.Name"           , "Tag_Name")
        :Column("Tag.LinkUID"        , "Tag_LinkUID")
        :Column("Tag.Code"           , "Tag_Code")
        :Column("Tag.TableUseStatus" , "Tag_TableUseStatus")
        :Column("Tag.ColumnUseStatus", "Tag_ColumnUseStatus")
        :Column("Tag.Description"    , "Tag_Description")
        :Where([lower(replace(Tag.Code,' ','')) = ^],lower(StrTran(l_cURLTagCode," ","")))
        :Where([Tag.fk_Application = ^],l_iApplicationPk)
        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTags/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iTagPk := l_oData:Tag_Pk

            l_hValues["Name"]            := alltrim(l_oData:Tag_Name)
            l_hValues["Code"]            := alltrim(l_oData:Tag_Code)
            l_hValues["TableUseStatus"]  := l_oData:Tag_TableUseStatus
            l_hValues["ColumnUseStatus"] := l_oData:Tag_ColumnUseStatus
            l_hValues["Description"]     := l_oData:Tag_Description

            l_cHtml += TagEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iTagPk,l_hValues)
        else
            l_cHtml += TagEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListTemplateTables"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    if oFcgi:isGet()
        l_cHtml += TemplateTableListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)
    else
        l_cHtml += TemplateTableListFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
    endif

case l_cURLAction == "NewTemplateTable"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        if oFcgi:isGet()
            oFcgi:p_cjQueryScript += GOINEDITMODE
            l_cHtml += TemplateTableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += TemplateTableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditTemplateTable"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    //Executing the following even for POST to ensure the record is still present.
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("9de1a987-56bf-4965-8fac-dbfdcb2f8183","TemplateTable")
        :Column("TemplateTable.pk"     ,"TemplateTable_Pk")
        :Column("TemplateTable.Name"   ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
        :Where([TemplateTable.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLTemplateTableName,1) == "~"
            :Where([TemplateTable.LinkUID = ^],substr(l_cURLTemplateTableName,2))
        else
            :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateTableName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateTables/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iTemplateTablePk := l_oData:TemplateTable_Pk
            l_hValues["Name"]  := alltrim(l_oData:TemplateTable_Name)

            l_cHtml += TemplateTableEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iTemplateTablePk,l_hValues)
        else
            l_cHtml += TemplateTableEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "ListTemplateColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    //Find the iTemplateTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("61820e1b-b440-4c71-8e1a-a34b90062fa9","TemplateTable")
        :Column("TemplateTable.pk"     ,"TemplateTable_Pk")
        :Column("TemplateTable.Name"   ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
        :Where("TemplateTable.fk_Application = ^",l_iApplicationPk)

        if left(l_cURLTemplateTableName,1) == "~"
            :Where([TemplateTable.LinkUID = ^],substr(l_cURLTemplateTableName,2))
        else
            :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateTableName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally == 1
        if oFcgi:isGet()
            l_cHtml += TemplateColumnListFormBuild(l_iApplicationPk,l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData)
        else
            l_cHtml += TemplateColumnListFormOnSubmit(l_iApplicationPk,l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData)
        endif

    endif

case l_cURLAction == "OrderTemplateColumns"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

    //Find the iTemplateTablePk
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("31de69df-b5ea-4d10-9787-f7e0ab490da6","TemplateTable")
        :Column("TemplateTable.pk"     ,"TemplateTable_Pk")
        :Column("TemplateTable.Name"   ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
        :Where("TemplateTable.fk_Application = ^",l_iApplicationPk)

        if left(l_cURLTemplateTableName,1) == "~"
            :Where([TemplateTable.LinkUID = ^],substr(l_cURLTemplateTableName,2))
        else
            :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateTableName," ","")))
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally == 1
        if oFcgi:isGet()
            l_cHtml += TemplateColumnOrderFormBuild(l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData)
        else
            l_cHtml += TemplateColumnOrderFormOnSubmit(l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "NewTemplateColumn"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
        
        //Find the iTemplateTablePk

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("f0f14f13-3c12-40b5-b45f-db93c25d651c","TemplateTable")
            :Column("TemplateTable.pk"     ,"TemplateTable_Pk")
            :Column("TemplateTable.Name"   ,"TemplateTable_Name")
            :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
            :Where("TemplateTable.fk_Application = ^",l_iApplicationPk)

            if left(l_cURLTemplateTableName,1) == "~"
                :Where([TemplateTable.LinkUID = ^],substr(l_cURLTemplateTableName,2))
            else
                :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateTableName," ","")))
            endif

            :Limit(1)  // In case we have duplicate pick one of them
            l_oData := :SQL()
        endwith

        if l_oDB1:Tally == 1
            if oFcgi:isGet()
                //Check if any other fields is already marked as "Primary"
                with object l_oDB1
                    :Table("2e78008d-dcae-4401-a519-a2825ff39bc4","TemplateColumn")
                    :Where("TemplateColumn.fk_TemplateTable = ^" , l_oData:TemplateTable_Pk)
                    :Where("TemplateColumn.UsedAs = 2")
                    :SQL()
                    l_nNumberOfPrimaryColumns := :Tally
                endwith

                oFcgi:p_cjQueryScript += GOINEDITMODE
                l_cHtml += TemplateColumnEditFormBuild(l_iApplicationPk,l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData,"",0,iif(empty(l_nNumberOfPrimaryColumns),{"ShowPrimary"=>.t.},{=>}))
            else
                l_cHtml += TemplateColumnEditFormOnSubmit(l_iApplicationPk,l_oData:TemplateTable_Pk,l_cURLApplicationLinkCode,l_oData)
            endif
        endif
    endif

case l_cURLAction == "EditTemplateColumn"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("c653b363-86d2-483e-8745-e0e75437191f","TemplateColumn")

        :Column("TemplateColumn.pk"           ,"TemplateColumn_pk")
        :Column("TemplateTable.pk"            ,"TemplateTable_pk")
        :Column("TemplateTable.Name"          ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID"       ,"TemplateTable_LinkUID")
        :Column("TemplateColumn.Name"         ,"TemplateColumn_Name")
        :Column("TemplateColumn.AKA"          ,"TemplateColumn_AKA")
        :Column("TemplateColumn.UsedAs"       ,"TemplateColumn_UsedAs")
        :Column("TemplateColumn.UsedBy"       ,"TemplateColumn_UsedBy")
        :Column("TemplateColumn.UseStatus"    ,"TemplateColumn_UseStatus")
        :Column("TemplateColumn.DocStatus"    ,"TemplateColumn_DocStatus")
        :Column("TemplateColumn.Description"  ,"TemplateColumn_Description")
        :Column("TemplateColumn.Type"         ,"TemplateColumn_Type")
        :Column("TemplateColumn.Array"        ,"TemplateColumn_Array")
        :Column("TemplateColumn.Length"       ,"TemplateColumn_Length")
        :Column("TemplateColumn.Scale"        ,"TemplateColumn_Scale")
        :Column("TemplateColumn.Nullable"     ,"TemplateColumn_Nullable")
        :Column("TemplateColumn.Unicode"      ,"TemplateColumn_Unicode")
        :Column("TemplateColumn.DefaultType"  ,"TemplateColumn_DefaultType")
        :Column("TemplateColumn.DefaultCustom","TemplateColumn_DefaultCustom")

        :Join("inner","TemplateTable"    ,"","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
        :Where([TemplateTable.fk_Application = ^],l_iApplicationPk)

        if left(l_cURLTemplateTableName,1) == "~"
            :Where([TemplateTable.LinkUID = ^],substr(l_cURLTemplateTableName,2))
        else
            :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateTableName," ","")))
        endif

        if left(l_cURLTemplateColumnName,1) == "~"
            :Where([TemplateColumn.LinkUID = ^],substr(l_cURLTemplateColumnName,2))
        else
            :Where([lower(replace(TemplateColumn.Name,' ','')) = ^],lower(StrTran(l_cURLTemplateColumnName," ","")))
        endif

        if l_nURLTemplateColumnUsedBy > 0
            :Where("TemplateColumn.UsedBy = ^",l_nURLTemplateColumnUsedBy)
        endif

        :Limit(1)  // In case we have duplicate pick one of them
        l_oData := :SQL()
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateTables/"+l_cURLApplicationLinkCode+"/")
    else
        l_iTemplateColumnPk := l_oData:TemplateColumn_pk
        l_iTemplateTablePk  := l_oData:TemplateTable_pk

        if oFcgi:isGet()
            //Check if any other fields is already marked as "Primary"
            with object l_oDB1
                :Table("3d15f220-c78b-4d98-81ad-c11ef9cd9e77","TemplateColumn")
                :Where("TemplateColumn.fk_TemplateTable = ^" , l_iTemplateTablePk)
                :Where("TemplateColumn.UsedAs = 2")
                :Where("TemplateColumn.pk <> ^" , l_iTemplateColumnPk)
                :SQL()
                l_hValues["ShowPrimary"] := empty(:Tally)
            endwith

            l_hValues["Name"]          := alltrim(l_oData:TemplateColumn_Name)
            l_hValues["AKA"]           := alltrim(nvl(l_oData:TemplateColumn_AKA,""))
            l_hValues["UsedAs"]        := l_oData:TemplateColumn_UsedAs
            l_hValues["UsedBy"]        := l_oData:TemplateColumn_UsedBy
            l_hValues["UseStatus"]     := l_oData:TemplateColumn_UseStatus
            l_hValues["DocStatus"]     := l_oData:TemplateColumn_DocStatus
            l_hValues["Description"]   := l_oData:TemplateColumn_Description
            l_hValues["Type"]          := alltrim(l_oData:TemplateColumn_Type)
            l_hValues["Array"]         := l_oData:TemplateColumn_Array
            l_hValues["Length"]        := l_oData:TemplateColumn_Length
            l_hValues["Scale"]         := l_oData:TemplateColumn_Scale
            l_hValues["Nullable"]      := l_oData:TemplateColumn_Nullable
            l_hValues["Unicode"]       := l_oData:TemplateColumn_Unicode
            l_hValues["DefaultType"]   := l_oData:TemplateColumn_DefaultType
            l_hValues["DefaultCustom"] := l_oData:TemplateColumn_DefaultCustom

            l_cHtml += TemplateColumnEditFormBuild(l_iApplicationPk,l_iTemplateTablePk,l_cURLApplicationLinkCode,l_oData,"",l_iTemplateColumnPk,l_hValues)
        else
            l_cHtml += TemplateColumnEditFormOnSubmit(l_iApplicationPk,l_iTemplateTablePk,l_cURLApplicationLinkCode,l_oData)
        endif
    endif

case l_cURLAction == "TableExportForDataWharfImports"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)

        //Executing the following even for POST to ensure the record is still present.
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("d3d94c58-d8eb-44e6-b014-762c372ca0fc","Table")
            :Column("Table.pk"         ,"Table_Pk")
            :Column("Namespace.Name"   ,"Namespace_Name")
            :Column("Namespace.AKA"    ,"Namespace_AKA")
            :Column("Namespace.LinkUID","Namespace_LinkUID")
            :Column("Table.Name"       ,"Table_Name")
            :Column("Table.AKA"        ,"Table_AKA")
            :Column("Table.LinkUID"    ,"Table_LinkUID")
            :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
            :Where([Namespace.fk_Application = ^],l_iApplicationPk)

            if left(l_cURLNamespaceName,1) == "~"
                :Where([Namespace.LinkUID = ^],substr(l_cURLNamespaceName,2))
            else
                :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cURLNamespaceName," ","")))
            endif
            if left(l_cURLTableName,1) == "~"
                :Where([Table.LinkUID = ^],substr(l_cURLTableName,2))
            else
                :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cURLTableName," ","")))
            endif

            :Limit(1)  // In case we have duplicate pick one of them
            l_oData := :SQL()
        endwith

        if l_oDB1:Tally != 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+l_cURLApplicationLinkCode+"/")
        else

            l_iTablePk := l_oData:Table_Pk
            if !empty(l_iTablePk)
                AssembleNavbarInfo("Add",{"Namespace",l_oData:Namespace_Name,l_oData:Namespace_AKA,l_oData:Namespace_LinkUID})
                AssembleNavbarInfo("Add",{"Table"    ,l_oData:Table_Name    ,l_oData:Table_AKA    ,l_oData:Table_LinkUID}    )

                l_cHtml += GetAboveNavbarHeading("Export for DataWharf Imports","Table",AssembleNavbarInfo("Build"))

                l_cCombinedPath := l_cURLApplicationLinkCode+[/]+;
                                   PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+[/]+;
                                   PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +[/]

                l_cHtml += [<nav class="navbar navbar-light bg-light">]
                    l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
                        l_cHtml += GetNextPreviousTable(l_iApplicationPk,l_cURLApplicationLinkCode,l_iTablePk,"TableExportForDataWharfImports")
                        l_cHtml += GetTableExtendedButtonRelatedOnEditForm("Export",l_iTablePk,l_cCombinedPath)
                    l_cHtml += [</div><div class="input-group">]
                        if oFcgi:isGet()
                            l_cLinkUID := ExportTableForImports(l_iTablePk)
                            if !empty(l_cLinkUID)
                                l_cHtml += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[streamfile?id=]+l_cLinkUID+["]+[>Download Export File</a>]
                            endif
                        else
                            l_cLinkUID := ""
                        endif
                    l_cHtml += [</div>]
                l_cHtml += [</nav>]

                if empty(l_cLinkUID)
                    l_cHtml += [<p class="ms-3">Failed to create an Export file.</p>]
                else
                    l_cHtml += [<p class="ms-3">The Export file was created as a ZIP file. Use the "Download Export File" button.</p>]
                endif

            endif


        endif
    endif

case l_cURLAction == "TableReferencedBy"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += TableReferenceByFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_cURLNamespaceName,l_cURLTableName)

case l_cURLAction == "TableDiagrams"
    l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode)
    l_cHtml += TableDiagramsFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,l_cURLNamespaceName,l_cURLTableName)

otherwise
    l_cHtml += [<div>Bad URL</div>]

endcase

return l_cHtml
//=================================================================================================================
static function EnumerationImplementAsInfo(par_ImplementAs,par_ImplementLength)
local l_cResult
do case
case par_ImplementAs == ENUMERATIONIMPLEMENTAS_NATIVESQLENUM
    l_cResult := [SQL Enum]
case par_ImplementAs == ENUMERATIONIMPLEMENTAS_INTEGER
    l_cResult := [Integer]
case par_ImplementAs == ENUMERATIONIMPLEMENTAS_NUMERIC
    l_cResult := [Numeric ]+Trans(par_ImplementLength)+[ digit]+iif(par_ImplementLength > 1,[s],[])
case par_ImplementAs == ENUMERATIONIMPLEMENTAS_VARCHAR
    l_cResult := [String ]+Trans(par_ImplementLength)+[ character]+iif(par_ImplementLength > 1,[s],[])
otherwise
    l_cResult := ""
endcase
return l_cResult
//=================================================================================================================
function FormatColumnTypeInfo(par_cColumnType,;
                              par_iColumnLength,;
                              par_iColumnScale,;
                              par_iColumnUnicode,;
                              par_cTableNamespaceName,;
                              par_cEnumerationNamespaceName,;
                              par_cEnumerationNamespaceAKA,;
                              par_cEnumerationNamespaceLinkUID,;
                              par_cEnumerationName,;
                              par_cEnumerationAKA,;
                              par_cEnumerationLinkUID,;
                              par_iEnumerationImplementAs,;
                              par_iEnumerationImplementLength,;
                              par_cSitePath,;
                              par_cURLApplicationLinkCode,;
                              par_cTooltipEnumValues;
                              )
local l_cResult
local l_iTypePos

l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[COLUMN_TYPES_CODE] == par_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
if l_iTypePos > 0
    l_cResult := par_cColumnType+" "+oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_NAME]
    do case
    case oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE] .and. oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]  // Length and Scale
        l_cResult += [&nbsp;(]+iif(hb_IsNIL(par_iColumnLength),"",Trans(par_iColumnLength))+[,]+iif(hb_IsNIL(par_iColumnScale),"",Trans(par_iColumnScale))+[)]

    case oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE]  // Scale
        l_cResult += [ (Scale: ]+iif(hb_IsNIL(par_iColumnScale),"",Trans(par_iColumnScale))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]
        l_cResult += [&nbsp;(]+iif(hb_IsNIL(par_iColumnLength),"",Trans(par_iColumnLength))+[)]
        
    case oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_ENUMS]  // Enumeration
        if !hb_IsNIL(par_cEnumerationName) .and. !hb_IsNIL(par_iEnumerationImplementAs) //.and. !hb_IsNIL(par_iEnumerationImplementLength)
            l_cResult += [&nbsp;(]
            l_cResult += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+;
                                    par_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+"/"+;
                                                                                     PrepareForURLSQLIdentifier("Namespace",par_cEnumerationNamespaceName,par_cEnumerationNamespaceLinkUID)+[/]+;
                                                                                     PrepareForURLSQLIdentifier("Namespace",par_cEnumerationName         ,par_cEnumerationLinkUID)         +[/"]
            if empty(par_cTooltipEnumValues)
                l_cResult += [>]
            else
                l_cResult += [data-toggle="tooltip" data-html="true" title="]+par_cTooltipEnumValues+[" class="DisplayEnum">]
            endif

            // l_cResult += par_cEnumerationName+iif(!empty(par_cEnumerationAKA),[&nbsp;(]+Strtran(par_cEnumerationAKA,[&nbsp;],[])+[)],[])
            if par_cEnumerationNamespaceName != par_cTableNamespaceName
                l_cResult += TextToHTML(par_cEnumerationNamespaceName+FormatAKAForDisplay(par_cEnumerationNamespaceAKA))+"."
            endif
            l_cResult += TextToHTML(par_cEnumerationName+FormatAKAForDisplay(par_cEnumerationAKA))

            l_cResult += [</a>]
            l_cResult += [ - ]

            do case
            case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NATIVESQLENUM
                l_cResult += [SQL Enum)]
            case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_INTEGER
                l_cResult += [Integer)]
            case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NUMERIC
                l_cResult += [Numeric ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ digit]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
            case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_VARCHAR
                l_cResult += [String ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ character]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
            endcase

        endif
    endcase

    // // Not a native Enumeration but has a link to an enumeration - Following was a test to see if should allow to link to an enum without forcing it. Decided not to allow.
    // if !oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_ENUMS] .and. !hb_IsNIL(par_cEnumerationName)
    //     l_cResult += [&nbsp;(]
    //     l_cResult += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+par_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+"/"+par_cURLNamespaceName+[/]+par_cEnumerationName+[/">]
    //     l_cResult += par_cEnumerationName+iif(!empty(par_cEnumerationAKA),[&nbsp;(]+Strtran(par_cEnumerationAKA,[&nbsp;],[])+[)],[])
    //     l_cResult += [</a>]
    //     l_cResult += [)]

    //     // do case
    //     // case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NATIVESQLENUM
    //     //     l_cResult += [SQL Enum)]
    //     // case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_INTEGER
    //     //     l_cResult += [Integer)]
    //     // case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NUMERIC
    //     //     l_cResult += [Numeric ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ digit]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
    //     // case par_iEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_VARCHAR
    //     //     l_cResult += [String ]+Trans(nvl(par_iEnumerationImplementLength,0))+[ character]+iif(nvl(par_iEnumerationImplementLength,0) > 1,[s],[])+[)]
    //     // endcase
    // endif

    if par_iColumnUnicode .and. oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_UNICODE]
        l_cResult += " Unicode"
    endif

else
    l_cResult := ""
endif

return l_cResult
//=================================================================================================================
static function DataDictionaryHeaderBuild(par_iApplicationPk,par_cApplicationName,par_cApplicationElement,par_cSitePath,par_cURLApplicationLinkCode)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:p_cSitePath
local l_cInitialDiagram
local l_iNumberOfNameSpace

oFcgi:TraceAdd("DataDictionaryHeaderBuild")

with object l_oDB1
    :Table("757edb64-9f3a-4f63-ada7-dbedf3e09fa7","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    l_iNumberOfNameSpace  := :Count()
endwith

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Application: ]+par_cApplicationName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[DataDictionaries/">Other Applications</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    //--------------------------------------------------------------------------------------
    if l_iNumberOfNameSpace > 0
        l_cHtml += [<li class="nav-item">]

            with object l_oDB1
                :Table("fa9ced84-f14e-4ef0-9047-ca77a564b327","Diagram")
                :Column("Count(*)","Total")
                :Where("Diagram.fk_Application = ^" , par_iApplicationPk)
                :SQL(@l_aSQLResult)
                l_iReccount := iif(:Tally == 1,l_aSQLResult[1,1],0) 
            endwith

            //Will check if we have a previously accessed diagram.
            with object l_oDB1
                :Table("34c5c34f-87fb-46ed-ac62-8a374d5cf668","UserSettingApplication")
                :Column("UserSettingApplication.pk","pk")
                :Column("Diagram.LinkUID"          ,"Diagram_LinkUID")
                :Join("inner","Diagram","","UserSettingApplication.fk_Diagram = Diagram.pk")   // Since UserSettingApplication.fk_Diagram could not be set, must use inner join.
                :Where("UserSettingApplication.fk_User = ^",oFcgi:p_iUserPk)
                :Where("UserSettingApplication.fk_Application = ^",par_iApplicationPk)
                :SQL("ListOfUserSettingApplication")
                // hb_orm_SendToDebugView(:GetLastEventId(),:LastSQL())
                if :Tally == 1
                    l_cInitialDiagram := "?InitialDiagram="+ListOfUserSettingApplication->Diagram_LinkUID
                else
                    l_cInitialDiagram := ""
                endif
            endwith
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "VISUALIZE",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/Visualize/]+par_cURLApplicationLinkCode+[/]+l_cInitialDiagram+[">Diagrams (]+Trans(l_iReccount)+[)</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    if l_iNumberOfNameSpace > 0
        l_cHtml += [<li class="nav-item">]
            with object l_oDB1
                :Table("72e2bd5d-4bd3-41a0-92e4-cf1a33c58489","Table")
                :Column("Count(*)","Total")
                :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
                :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
                :SQL(@l_aSQLResult)
                l_iReccount := iif(:Tally == 1,l_aSQLResult[1,1],0) 
            endwith
            l_cHtml += [<a class="TopTabs nav-link]+iif(par_cApplicationElement == "TABLES",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/ListTables/]+par_cURLApplicationLinkCode+[/">Tables (]+Trans(l_iReccount)+[)</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    if l_iNumberOfNameSpace > 0
        l_cHtml += [<li class="nav-item">]
            with object l_oDB1
                :Table("a5b4d022-f670-4063-ba57-c5e0ae2c07c5","Enumeration")
                :Column("Count(*)","Total")
                :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
                :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
                :SQL(@l_aSQLResult)
                l_iReccount := iif(:Tally == 1,l_aSQLResult[1,1],0) 
            endwith
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "ENUMERATIONS",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/ListEnumerations/]+par_cURLApplicationLinkCode+[/">Enumerations (]+Trans(l_iReccount)+[)</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        l_iReccount := l_iNumberOfNameSpace
        l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "NAMESPACES",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/ListNamespaces/]+par_cURLApplicationLinkCode+[/">Namespaces (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("65755ca3-5143-4556-8f3b-72912b2df865","Tag")
            :Where("Tag.fk_Application = ^" , par_iApplicationPk)
            l_iReccount := :Count()
        endwith
        l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "TAGS",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/ListTags/]+par_cURLApplicationLinkCode+[/">Tags (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "SETTINGS",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionarySettings/]+par_cURLApplicationLinkCode+[/">Data Dictionary Settings</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelDD >= 6
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "IMPORT",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryImport/]+par_cURLApplicationLinkCode+[/">Import</a>]
        l_cHtml += [</li>]
        if l_iNumberOfNameSpace > 0
            l_cHtml += [<li class="nav-item">]
                l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "EXPORT",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryExport/]+par_cURLApplicationLinkCode+[/">Export</a>]
            l_cHtml += [</li>]
        endif
    endif
    //--------------------------------------------------------------------------------------
    // if l_iNumberOfNameSpace > 0
    //Deployment tools should be available to load a database
        l_cHtml += [<li class="nav-item">]
            with object l_oDB1
                :Table("fa9ced84-f14e-4ef0-9047-ca77a564b327","Deployment")
                :Column("Count(*)","Total")
                :Where("Deployment.fk_Application = ^"                    ,par_iApplicationPk)
                :Where("Deployment.fk_User = ^ or Deployment.fk_User = 0" ,oFcgi:p_iUserPk)
                :SQL(@l_aSQLResult)
                l_iReccount := iif(:Tally == 1,l_aSQLResult[1,1],0) 

            endwith
            l_cHtml += [<a class="TopTabs nav-link]+iif(par_cApplicationElement == "DEVELOPMENTTOOLS",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryDeploymentTools/]+par_cURLApplicationLinkCode+[/">Deployment Tools (]+Trans(l_iReccount)+[)</a>]
        l_cHtml += [</li>]
    // endif
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("72e2bd5d-4bd3-41a0-92e4-cf1a33c58490","TemplateTable")
            :Column("Count(*)","Total")
            :Where("TemplateTable.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
            l_iReccount := iif(:Tally == 1,l_aSQLResult[1,1],0) 
        endwith
        l_cHtml += [<a class="TopTabs nav-link]+iif(par_cApplicationElement == "TEMPLATETABLES",[ active],[])+[" href="]+par_cSitePath+[DataDictionaries/ListTemplateTables/]+par_cURLApplicationLinkCode+[/">Templates (]+Trans(l_iReccount)+[)</a>]
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
local l_oDB_ListOfDataDictionaries                     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCustomFieldValues                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfNamespaceCounts                      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTableCounts                          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfRelationshipCounts                   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnCounts                         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumerationCounts                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfIndexCounts                          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDiagramCounts                        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfUserSettingApplicationDefaultDiagram := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfDataDictionaries
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nCountProposed
local l_nCount
local l_nCountDiscontinued
local l_cInitialDiagram

oFcgi:TraceAdd("ApplicationListFormBuild")

with object l_oDB_ListOfDataDictionaries
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
    with object l_oDB_ListOfCustomFieldValues
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

with object l_oDB_ListOfNamespaceCounts
    :Table("9ba4289c-c846-4a4f-aec5-81d08072866a","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Namespace.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Namespace.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Namespace.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace","","Namespace.fk_Application = Application.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfNamespaceCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfTableCounts
    :Table("9ba4289c-c846-4a4f-aec5-81d08072866a","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Table.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Table.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Table.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace","","Namespace.fk_Application = Application.pk")
    :Join("inner","Table"    ,"","Table.fk_Namespace = Namespace.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfTableCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfRelationshipCounts
    :Table("5599c14a-b4e3-4407-b462-5b334bd42adc","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Column.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace","","Namespace.fk_Application = Application.pk")
    :Join("inner","Table"    ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column"   ,"","Column.fk_Table = Table.pk")
    :Where("Column.UsedAs = ^",COLUMN_USEDAS_FOREIGN_KEY)
    :Where("Column.fk_TableForeign IS NOT NULL")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfRelationshipCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfColumnCounts
    :Table("97ea0070-3ca0-4bf9-9634-aa2ae6913fd1","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Column.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace","","Namespace.fk_Application = Application.pk")
    :Join("inner","Table"    ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column"   ,"","Column.fk_Table = Table.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfColumnCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfEnumerationCounts
    :Table("5d6d5a9f-5f0f-4c24-b112-d5faeed06a94","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Enumeration.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Enumeration.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Enumeration.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace"  ,"","Namespace.fk_Application = Application.pk")
    :Join("inner","Enumeration","","Enumeration.fk_Namespace = Namespace.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfEnumerationCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfIndexCounts
    :Table("0e2d5bee-76be-4b99-a898-7d9e26296c96","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("SUM(CASE WHEN Index.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
    :Column("SUM(CASE WHEN Index.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
    :Column("SUM(CASE WHEN Index.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
    :Join("inner","Namespace","","Namespace.fk_Application = Application.pk")
    :Join("inner","Table"    ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index"   ,"","Index.fk_Table = Table.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfIndexCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

with object l_oDB_ListOfDiagramCounts
    :Table("f6b9021e-f835-4ea3-aebb-a1ecc81be807","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("Count(*)" ,"Count")
    :Join("inner","Diagram","","Diagram.fk_Application = Application.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfDiagramCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfDataDictionaries)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Application on file.</span>]
        l_cHtml += [</div>]

    else
        //Will check if we have a previously accessed diagram.
        with object l_oDB_ListOfUserSettingApplicationDefaultDiagram
            :Table("620799a2-adb9-40dc-8136-5a6007fead0f","UserSettingApplication")
            :Column("UserSettingApplication.fk_Application","ApplicationPk")
            :Column("Diagram.LinkUID"                      ,"Diagram_LinkUID")
            :Join("inner","Diagram","","UserSettingApplication.fk_Diagram = Diagram.pk")   // Since UserSettingApplication.fk_Diagram could not be set, must use inner join.
            :Where("UserSettingApplication.fk_User = ^",oFcgi:p_iUserPk)
            :SQL("ListOfUserSettingApplicationDefaultDiagram")
            with object :p_oCursor
                :Index("ApplicationPk","ApplicationPk")
                :CreateIndexes()
            endwith
        endwith

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"11","12")+[">Applications / Data Dictionaries (]+Trans(l_nNumberOfDataDictionaries)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Name-<br>spaces</th>]
                    l_cHtml += [<th class="text-white text-center">Tables</th>]
                    l_cHtml += [<th class="text-white text-center">Columns</th>]
                    l_cHtml += [<th class="text-white text-center">Relationships</th>]
                    l_cHtml += [<th class="text-white text-center">Enumerations</th>]
                    l_cHtml += [<th class="text-white text-center">Indexes</th>]
                    l_cHtml += [<th class="text-white text-center">Diagrams</th>]
                    l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfDataDictionaries
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfDataDictionaries->Application_UseStatus)+[>]

                        if el_seek(ListOfDataDictionaries->pk,"ListOfNamespaceCounts","tag1")
                            l_nCountProposed     := ListOfNamespaceCounts->CountProposed
                            l_nCount             := ListOfNamespaceCounts->Count
                            l_nCountDiscontinued := ListOfNamespaceCounts->CountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]   // Application Name
                            if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListTables/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+alltrim(ListOfDataDictionaries->Application_Name)+[</a>]
                            else
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListNamespaces/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+alltrim(ListOfDataDictionaries->Application_Name)+[</a>]
                            endif
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]   // Application Description
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfDataDictionaries->Application_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Namespace

                            if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListNamespaces/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                            endif

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Tables

                            if el_seek(ListOfDataDictionaries->pk,"ListOfTableCounts","tag1")
                                l_nCountProposed     := ListOfTableCounts->CountProposed
                                l_nCount             := ListOfTableCounts->Count
                                l_nCountDiscontinued := ListOfTableCounts->CountDiscontinued
                            else
                                l_nCountProposed     := 0
                                l_nCount             := 0
                                l_nCountDiscontinued := 0
                            endif
                            if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListTables/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                            endif

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Columns

                            if el_seek(ListOfDataDictionaries->pk,"ListOfColumnCounts","tag1")
                                l_nCountProposed     := ListOfColumnCounts->CountProposed
                                l_nCount             := ListOfColumnCounts->Count
                                l_nCountDiscontinued := ListOfColumnCounts->CountDiscontinued
                            else
                                l_nCountProposed     := 0
                                l_nCount             := 0
                                l_nCountDiscontinued := 0
                            endif
                            l_cHtml += GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Relationships

                            if el_seek(ListOfDataDictionaries->pk,"ListOfRelationshipCounts","tag1")
                                l_nCountProposed     := ListOfRelationshipCounts->CountProposed
                                l_nCount             := ListOfRelationshipCounts->Count
                                l_nCountDiscontinued := ListOfRelationshipCounts->CountDiscontinued
                            else
                                l_nCountProposed     := 0
                                l_nCount             := 0
                                l_nCountDiscontinued := 0
                            endif
                            l_cHtml += GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Enumerations

                            if el_seek(ListOfDataDictionaries->pk,"ListOfEnumerationCounts","tag1")
                                l_nCountProposed     := ListOfEnumerationCounts->CountProposed
                                l_nCount             := ListOfEnumerationCounts->Count
                                l_nCountDiscontinued := ListOfEnumerationCounts->CountDiscontinued
                            else
                                l_nCountProposed     := 0
                                l_nCount             := 0
                                l_nCountDiscontinued := 0
                            endif
                            if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListEnumerations/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                            endif

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Indexes

                            if el_seek(ListOfDataDictionaries->pk,"ListOfIndexCounts","tag1")
                                l_nCountProposed     := ListOfIndexCounts->CountProposed
                                l_nCount             := ListOfIndexCounts->Count
                                l_nCountDiscontinued := ListOfIndexCounts->CountDiscontinued
                            else
                                l_nCountProposed     := 0
                                l_nCount             := 0
                                l_nCountDiscontinued := 0
                            endif
                            l_cHtml += GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)
                            
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]   // Diagrams
                            l_nCount := iif( el_seek(ListOfDataDictionaries->pk,"ListOfDiagramCounts","tag1") , ListOfDiagramCounts->Count , 0)
                            if !empty(l_nCount)
                                //Will check if we have a previously accessed diagram.
                                if el_seek(ListOfDataDictionaries->pk,"ListOfUserSettingApplicationDefaultDiagram","ApplicationPk")
                                    l_cInitialDiagram := "?InitialDiagram="+ListOfUserSettingApplicationDefaultDiagram->Diagram_LinkUID
                                else
                                    l_cInitialDiagram := ""
                                endif
                                l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/Visualize/]+alltrim(ListOfDataDictionaries->Application_LinkCode)+[/]+l_cInitialDiagram+[">]+Trans(l_nCount)+[</a>]
                            endif
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]   // Usage Status
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfDataDictionaries->Application_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfDataDictionaries->Application_UseStatus,USESTATUS_UNKNOWN)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]   // Doc Status
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfDataDictionaries->Application_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfDataDictionaries->Application_DocStatus,DOCTATUS_MISSING)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]   // Custom Fields
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
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cSupportColumns                                        := nvl(hb_HGetDef(par_hValues,"SupportColumns",""),"")
local l_lAddForeignKeyIndexORMExport                           := hb_HGetDef(par_hValues,"AddForeignKeyIndexORMExport"                          ,.f.)
local l_lSetMissingOnDeleteToProtect                           := hb_HGetDef(par_hValues,"SetMissingOnDeleteToProtect"                          ,.f.)
local l_lNoNamespaceChangeOnTablesAndEnumerations              := hb_HGetDef(par_hValues,"NoNamespaceChangeOnTablesAndEnumerations"             ,.f.)
local l_lPreventLoadFromDeployments                            := hb_HGetDef(par_hValues,"PreventLoadFromDeployments"                           ,.f.)
local l_nKeyConfig                                             := hb_HGetDef(par_hValues,"KeyConfig"                                            ,1)
local l_lTestTableHasPrimaryKey                                := hb_HGetDef(par_hValues,"TestTableHasPrimaryKey"                               ,.f.)
local l_lTestForeignKeyTypeMatchPrimaryKey                     := hb_HGetDef(par_hValues,"TestForeignKeyTypeMatchPrimaryKey"                    ,.f.)
local l_lTestForeignKeyIsNullable                              := hb_HGetDef(par_hValues,"TestForeignKeyIsNullable"                             ,.f.)
local l_lTestForeignKeyNoDefault                               := hb_HGetDef(par_hValues,"TestForeignKeyNoDefault"                              ,.f.)
local l_lTestForeignKeyMissingOnDeleteSetting                  := hb_HGetDef(par_hValues,"TestForeignKeyMissingOnDeleteSetting"                 ,.f.)
local l_lTestEnumerationHasAtLeastOnePresentValue              := hb_HGetDef(par_hValues,"TestEnumerationHasAtLeastOnePresentValue"             ,.f.)
local l_lTestEnumerationValueNumberUniqueness                  := hb_HGetDef(par_hValues,"TestEnumerationValueNumberUniqueness"                 ,.f.)
local l_lTestNumericEnumerationWideEnough                      := hb_HGetDef(par_hValues,"TestNumericEnumerationWideEnough"                     ,.f.)
local l_lTestIdentifierMaxLengthAsPostgres                     := hb_HGetDef(par_hValues,"TestIdentifierMaxLengthAsPostgres"                    ,.f.)
local l_lTestMissingForeignKeyTable                            := hb_HGetDef(par_hValues,"TestMissingForeignKeyTable"                           ,.f.)
local l_lTestMissingEnumerationValues                          := hb_HGetDef(par_hValues,"TestMissingEnumerationValues"                         ,.f.)
local l_lTestUseOfDiscontinuedEnumeration                      := hb_HGetDef(par_hValues,"TestUseOfDiscontinuedEnumeration"                     ,.f.)
local l_lTestUseOfDiscontinuedForeignTable                     := hb_HGetDef(par_hValues,"TestUseOfDiscontinuedForeignTable"                    ,.f.)
local l_lTestValidColumnLengthAndScale                         := hb_HGetDef(par_hValues,"TestValidColumnLengthAndScale"                        ,.f.)
local l_lTestNoLeadingOrTrainingBlanksInIdentifiers            := hb_HGetDef(par_hValues,"TestNoLeadingOrTrainingBlanksInIdentifiers"           ,.f.)
local l_lTestValidNonEnumValueIdentifierAsVariableName         := hb_HGetDef(par_hValues,"TestValidNonEnumValueIdentifierAsVariableName"        ,.f.)
local l_lTestValidSQLEnumValueIdentifierAsVariableName         := hb_HGetDef(par_hValues,"TestValidSQLEnumValueIdentifierAsVariableName"        ,.f.)
local l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended := hb_HGetDef(par_hValues,"TestValidSQLEnumValueIdentifierAsAlphaNumericExtended",.f.)
local l_lTestIndexOnPrimaryAndForeignKeys                      := hb_HGetDef(par_hValues,"TestIndexOnPrimaryAndForeignKeys"                     ,.f.)
local l_lTestUniquenessCaseInsensitiveIdentifiers              := hb_HGetDef(par_hValues,"TestUniquenessCaseInsensitiveIdentifiers"             ,.f.)
local l_lTestUniquenessTableSQLEnumerationIdentifiers          := hb_HGetDef(par_hValues,"TestUniquenessTableSQLEnumerationIdentifiers"         ,.f.)

local l_cObjectId

oFcgi:TraceAdd("DataDictionaryEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading("Update Data Dictionary Settings")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 7
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Support Column Names</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextSupportColumns" id="TextSupportColumns" value="]+FcgiPrepFieldForValue(l_cSupportColumns)+[" size="80">]
                l_cHtml += [<br><span class="small">Blank separated list of column names.<br>If the "Used As" property of columns is not set, but its name is in the list above, it will be displayed as "Implicit Support".</span>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cObjectId := "CheckAddForeignKeyIndexORMExport"
        l_cHtml += [<tr class="pb-3">]
            l_cHtml += [<td class="pe-2 pb-3"></td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += GetCheckboxOnEditForm(l_cObjectId,l_lAddForeignKeyIndexORMExport,[Automatically Add Indexes on Integer and Big Integer Foreign Keys during "Export to Harbour_ORM"])
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-3">]
            l_cHtml += [<td class="pe-2 pb-3">Key Configuration</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboKeyConfig" id="ComboKeyConfig">]
                    l_cHtml += [<option value="1"]+iif(l_nKeyConfig==1,[ selected],[])+[>Primary and Foreign Keys can be of any types, any default.</option>]
                    l_cHtml += [<option value="2"]+iif(l_nKeyConfig==2,[ selected],[])+[>All keys are Integer. Primary keys are not nullable and auto-increment. Foreign keys are nullable with no default values.</option>]
                    l_cHtml += [<option value="3"]+iif(l_nKeyConfig==3,[ selected],[])+[>All keys are Integer Big. Primary keys are not nullable and auto-increment. Foreign keys are nullable with no default values.</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cObjectId := "CheckSetMissingOnDeleteToProtect"
        l_cHtml += [<tr class="pb-1">]
            l_cHtml += [<td class="pe-2 pb-1"></td>]
            l_cHtml += [<td class="pb-1">]
                l_cHtml += GetCheckboxOnEditForm(l_cObjectId,l_lSetMissingOnDeleteToProtect,[Set Missing "On Delete" in Foreign Keys To "Protect (Restrict)"])
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cObjectId := "CheckNoNamespaceChangeOnTablesAndEnumerations"
        l_cHtml += [<tr class="pb-3">]
            l_cHtml += [<td class="pe-2 pb-1"></td>]
            l_cHtml += [<td class="pb-1">]
                l_cHtml += GetCheckboxOnEditForm(l_cObjectId,l_lNoNamespaceChangeOnTablesAndEnumerations,[Prevent Changing Namespace on Existing Tables and Enumeration])
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cObjectId := "CheckPreventLoadFromDeployments"
        l_cHtml += [<tr class="pb-3">]
            l_cHtml += [<td class="pe-2 pb-3"></td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += GetCheckboxOnEditForm(l_cObjectId,l_lPreventLoadFromDeployments,[Prevent Load From Deployments])
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td colspan="2"><hr></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Integrity Test<br>(Warnings)</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestTableHasPrimaryKey"                               ,l_lTestTableHasPrimaryKey                               ,"Table must have a Primary Key")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestForeignKeyTypeMatchPrimaryKey"                    ,l_lTestForeignKeyTypeMatchPrimaryKey                    ,"Foreign Key Type must match Primary Key Type")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestForeignKeyIsNullable"                             ,l_lTestForeignKeyIsNullable                             ,"Foreign Key must be Nullable")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestForeignKeyNoDefault"                              ,l_lTestForeignKeyNoDefault                              ,"Foreign Key may not have a default value")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestForeignKeyMissingOnDeleteSetting"                 ,l_lTestForeignKeyMissingOnDeleteSetting                 ,[Foreign Key missing "On Delete" setting])
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestEnumerationHasAtLeastOnePresentValue"             ,l_lTestEnumerationHasAtLeastOnePresentValue             ,"Enumerations must have at least one present value")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestEnumerationValueNumberUniqueness"                 ,l_lTestEnumerationValueNumberUniqueness                 ,[Uniqueness of "Number" in Enumeration Values field in each Enumerations])
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestNumericEnumerationWideEnough"                     ,l_lTestNumericEnumerationWideEnough                     ,"Numeric Enumerations must be large enough to handle largest Value")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestMissingForeignKeyTable"                           ,l_lTestMissingForeignKeyTable                           ,"All Foreign Keys must point to a table")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestMissingEnumerationValues"                         ,l_lTestMissingEnumerationValues                         ,"All Enumeration Fields must point to a enumeration")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestUseOfDiscontinuedEnumeration"                     ,l_lTestUseOfDiscontinuedEnumeration                     ,"Non Discontinued Fields may not point to a Discontinued Enumeration")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestUseOfDiscontinuedForeignTable"                    ,l_lTestUseOfDiscontinuedForeignTable                    ,"Non Discontinued Foreign Keys may not point to a Discontinued Table")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestIdentifierMaxLengthAsPostgres"                    ,l_lTestIdentifierMaxLengthAsPostgres                    ,"Maximum Identifier Length when used for PostgreSQL (63 bytes) (Namespace, Table, Column, Enumeration, Enumeration Values)")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestValidColumnLengthAndScale"                        ,l_lTestValidColumnLengthAndScale                        ,"Validity of Column Length and Scale")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestNoLeadingOrTrainingBlanksInIdentifiers"           ,l_lTestNoLeadingOrTrainingBlanksInIdentifiers           ,"Check any Identifiers for leading or trailing blank characters")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestValidNonEnumValueIdentifierAsVariableName"        ,l_lTestValidNonEnumValueIdentifierAsVariableName        ,"Check Validity of Namespace, Table, Column, Index and Enumeration Identifiers to Match Variable Name Requirements")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestValidSQLEnumValueIdentifierAsVariableName"        ,l_lTestValidSQLEnumValueIdentifierAsVariableName        ,"Check Validity of Enumeration values used as SQL Enum Identifiers to Match Variable Name Requirements")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestValidSQLEnumValueIdentifierAsAlphaNumericExtended",l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended,"Check Validity of Enumeration values not used as SQL Enum Identifiers to be Alpha Numeric, blank, dash or underscore")
                l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestIndexOnPrimaryAndForeignKeys"                     ,l_lTestIndexOnPrimaryAndForeignKeys                     ,"Check Existance of Indexes on Primary and Foreign Keys")
                // l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestUniquenessCaseInsensitiveIdentifiers"             ,l_lTestUniquenessCaseInsensitiveIdentifiers             ,"Check uniqueness of case insensitive identifiers")
                // l_cHtml += DataDictionaryEditFormBuildGroupCheckboxes("TestUniquenessTableSQLEnumerationIdentifiers"         ,l_lTestUniquenessTableSQLEnumerationIdentifiers         ,"Check uniqueness between Table and SQL Enum Enumeration names in same Namespace")

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextSupportColumns').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function DataDictionaryEditFormBuildGroupCheckboxes(par_cCheckBoxName,par_lValue,par_cCheckBoxLabel)
local l_cObjectId := "Check"+par_cCheckBoxName
local l_cHtml
l_cHtml := [<div class="pb-1">]
        l_cHtml += GetCheckboxOnEditForm(l_cObjectId,par_lValue,par_cCheckBoxLabel)
l_cHtml += [</div>]
return l_cHtml
//=================================================================================================================
static function DataDictionaryEditFormOnSubmit(par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationSupportColumns
local l_lAddForeignKeyIndexORMExport
local l_lSetMissingOnDeleteToProtect
local l_lNoNamespaceChangeOnTablesAndEnumerations
local l_lPreventLoadFromDeployments
local l_nKeyConfig
local l_lTestTableHasPrimaryKey
local l_lTestForeignKeyTypeMatchPrimaryKey
local l_lTestForeignKeyIsNullable
local l_lTestForeignKeyNoDefault
local l_lTestForeignKeyMissingOnDeleteSetting
local l_lTestEnumerationHasAtLeastOnePresentValue
local l_lTestEnumerationValueNumberUniqueness
local l_lTestNumericEnumerationWideEnough
local l_lTestIdentifierMaxLengthAsPostgres
local l_lTestMissingForeignKeyTable
local l_lTestMissingEnumerationValues
local l_lTestUseOfDiscontinuedEnumeration
local l_lTestUseOfDiscontinuedForeignTable
local l_lTestValidColumnLengthAndScale
local l_lTestNoLeadingOrTrainingBlanksInIdentifiers
local l_lTestValidNonEnumValueIdentifierAsVariableName
local l_lTestValidSQLEnumValueIdentifierAsVariableName
local l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended
local l_lTestIndexOnPrimaryAndForeignKeys
local l_lTestUniquenessCaseInsensitiveIdentifiers
local l_lTestUniquenessTableSQLEnumerationIdentifiers

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("DataDictionaryEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationPk                                         := Val(oFcgi:GetInputValue("TableKey"))
l_cApplicationSupportColumns                             := SanitizeInput(oFcgi:GetInputValue("TextSupportColumns"))
l_lAddForeignKeyIndexORMExport                           := (oFcgi:GetInputValue("CheckAddForeignKeyIndexORMExport")                           == "1")
l_lSetMissingOnDeleteToProtect                           := (oFcgi:GetInputValue("CheckSetMissingOnDeleteToProtect")                           == "1")
l_lNoNamespaceChangeOnTablesAndEnumerations              := (oFcgi:GetInputValue("CheckNoNamespaceChangeOnTablesAndEnumerations")              == "1")
l_lPreventLoadFromDeployments                            := (oFcgi:GetInputValue("CheckPreventLoadFromDeployments")                            == "1")
l_nKeyConfig                                             := Val(oFcgi:GetInputValue("ComboKeyConfig"))
l_lTestTableHasPrimaryKey                                := (oFcgi:GetInputValue("CheckTestTableHasPrimaryKey")                                == "1")
l_lTestForeignKeyTypeMatchPrimaryKey                     := (oFcgi:GetInputValue("CheckTestForeignKeyTypeMatchPrimaryKey")                     == "1")
l_lTestForeignKeyIsNullable                              := (oFcgi:GetInputValue("CheckTestForeignKeyIsNullable")                              == "1")
l_lTestForeignKeyNoDefault                               := (oFcgi:GetInputValue("CheckTestForeignKeyNoDefault")                               == "1")
l_lTestForeignKeyMissingOnDeleteSetting                  := (oFcgi:GetInputValue("CheckTestForeignKeyMissingOnDeleteSetting")                  == "1")
l_lTestEnumerationHasAtLeastOnePresentValue              := (oFcgi:GetInputValue("CheckTestEnumerationHasAtLeastOnePresentValue")              == "1")
l_lTestEnumerationValueNumberUniqueness                  := (oFcgi:GetInputValue("CheckTestEnumerationValueNumberUniqueness")                  == "1")
l_lTestNumericEnumerationWideEnough                      := (oFcgi:GetInputValue("CheckTestNumericEnumerationWideEnough")                      == "1")
l_lTestIdentifierMaxLengthAsPostgres                     := (oFcgi:GetInputValue("CheckTestIdentifierMaxLengthAsPostgres")                     == "1")
l_lTestMissingForeignKeyTable                            := (oFcgi:GetInputValue("CheckTestMissingForeignKeyTable")                            == "1")
l_lTestMissingEnumerationValues                          := (oFcgi:GetInputValue("CheckTestMissingEnumerationValues")                          == "1")
l_lTestUseOfDiscontinuedEnumeration                      := (oFcgi:GetInputValue("CheckTestUseOfDiscontinuedEnumeration")                      == "1")
l_lTestUseOfDiscontinuedForeignTable                     := (oFcgi:GetInputValue("CheckTestUseOfDiscontinuedForeignTable")                     == "1")
l_lTestValidColumnLengthAndScale                         := (oFcgi:GetInputValue("CheckTestValidColumnLengthAndScale")                         == "1")
l_lTestNoLeadingOrTrainingBlanksInIdentifiers            := (oFcgi:GetInputValue("CheckTestNoLeadingOrTrainingBlanksInIdentifiers")            == "1")
l_lTestValidNonEnumValueIdentifierAsVariableName         := (oFcgi:GetInputValue("CheckTestValidNonEnumValueIdentifierAsVariableName")         == "1")
l_lTestValidSQLEnumValueIdentifierAsVariableName         := (oFcgi:GetInputValue("CheckTestValidSQLEnumValueIdentifierAsVariableName")         == "1")
l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended := (oFcgi:GetInputValue("CheckTestValidSQLEnumValueIdentifierAsAlphaNumericExtended") == "1")
l_lTestIndexOnPrimaryAndForeignKeys                      := (oFcgi:GetInputValue("CheckTestIndexOnPrimaryAndForeignKeys")                      == "1")
l_lTestUniquenessCaseInsensitiveIdentifiers              := (oFcgi:GetInputValue("CheckTestUniquenessCaseInsensitiveIdentifiers")              == "1")
l_lTestUniquenessTableSQLEnumerationIdentifiers          := (oFcgi:GetInputValue("CheckTestUniquenessTableSQLEnumerationIdentifiers")          == "1")


l_cApplicationSupportColumns := alltrim(strtran(l_cApplicationSupportColumns,[,],[ ]))
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
            :Field("Application.SupportColumns"                                       ,iif(empty(l_cApplicationSupportColumns),NULL,l_cApplicationSupportColumns))
            :Field("Application.AddForeignKeyIndexORMExport"                          ,l_lAddForeignKeyIndexORMExport)
            :Field("Application.SetMissingOnDeleteToProtect"                          ,l_lSetMissingOnDeleteToProtect)
            :Field("Application.NoNamespaceChangeOnTablesAndEnumerations"             ,l_lNoNamespaceChangeOnTablesAndEnumerations)
            :Field("Application.PreventLoadFromDeployments"                           ,l_lPreventLoadFromDeployments)
            :Field("Application.KeyConfig"                                            ,l_nKeyConfig)
            :Field("Application.TestTableHasPrimaryKey"                               ,l_lTestTableHasPrimaryKey)
            :Field("Application.TestForeignKeyTypeMatchPrimaryKey"                    ,l_lTestForeignKeyTypeMatchPrimaryKey)
            :Field("Application.TestForeignKeyIsNullable"                             ,l_lTestForeignKeyIsNullable)
            :Field("Application.TestForeignKeyNoDefault"                              ,l_lTestForeignKeyNoDefault)
            :Field("Application.TestForeignKeyMissingOnDeleteSetting"                 ,l_lTestForeignKeyMissingOnDeleteSetting)
            :Field("Application.TestEnumerationHasAtLeastOnePresentValue"             ,l_lTestEnumerationHasAtLeastOnePresentValue)
            :Field("Application.TestEnumerationValueNumberUniqueness"                 ,l_lTestEnumerationValueNumberUniqueness)
            :Field("Application.TestNumericEnumerationWideEnough"                     ,l_lTestNumericEnumerationWideEnough)
            :Field("Application.TestIdentifierMaxLengthAsPostgres"                    ,l_lTestIdentifierMaxLengthAsPostgres)
            :Field("Application.TestMissingForeignKeyTable"                           ,l_lTestMissingForeignKeyTable)
            :Field("Application.TestMissingEnumerationValues"                         ,l_lTestMissingEnumerationValues)
            :Field("Application.TestUseOfDiscontinuedEnumeration"                     ,l_lTestUseOfDiscontinuedEnumeration)
            :Field("Application.TestUseOfDiscontinuedForeignTable"                    ,l_lTestUseOfDiscontinuedForeignTable)
            :Field("Application.TestValidColumnLengthAndScale"                        ,l_lTestValidColumnLengthAndScale)
            :Field("Application.TestNoLeadingOrTrainingBlanksInIdentifiers"           ,l_lTestNoLeadingOrTrainingBlanksInIdentifiers)
            :Field("Application.TestValidNonEnumValueIdentifierAsVariableName"        ,l_lTestValidNonEnumValueIdentifierAsVariableName)
            :Field("Application.TestValidSQLEnumValueIdentifierAsVariableName"        ,l_lTestValidSQLEnumValueIdentifierAsVariableName)
            :Field("Application.TestValidSQLEnumValueIdentifierAsAlphaNumericExtended",l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended)
            :Field("Application.TestIndexOnPrimaryAndForeignKeys"                     ,l_lTestIndexOnPrimaryAndForeignKeys)
            :Field("Application.TestUniquenessCaseInsensitiveIdentifiers"             ,l_lTestUniquenessCaseInsensitiveIdentifiers)
            :Field("Application.TestUniquenessTableSQLEnumerationIdentifiers"         ,l_lTestUniquenessTableSQLEnumerationIdentifiers)

            if empty(l_iApplicationPk)
                //Should never happen
            else
                if :Update(l_iApplicationPk)
                    DataDictionaryFixAndTest(l_iApplicationPk)
                else
                    l_cErrorMessage := "Failed to update Application."
                endif
            endif
        endwith
    endif

endcase

do case
// case el_IsInlist(l_cActionOnSubmit,"Cancel","Done")

case !empty(l_cErrorMessage)
    l_hValues["SupportColumns"]                                        := l_cApplicationSupportColumns
    l_hValues["AddForeignKeyIndexORMExport"]                           := l_lAddForeignKeyIndexORMExport
    l_hValues["SetMissingOnDeleteToProtect"]                           := l_lSetMissingOnDeleteToProtect
    l_hValues["NoNamespaceChangeOnTablesAndEnumerations"]              := l_lNoNamespaceChangeOnTablesAndEnumerations
    l_hValues["PreventLoadFromDeployments"]                            := l_lPreventLoadFromDeployments
    l_hValues["KeyConfig"]                                             := l_nKeyConfig
    l_hValues["TestTableHasPrimaryKey"]                                := l_lTestTableHasPrimaryKey
    l_hValues["TestForeignKeyTypeMatchPrimaryKey"]                     := l_lTestForeignKeyTypeMatchPrimaryKey
    l_hValues["TestForeignKeyIsNullable"]                              := l_lTestForeignKeyIsNullable
    l_hValues["TestForeignKeyNoDefault"]                               := l_lTestForeignKeyNoDefault
    l_hValues["TestForeignKeyMissingOnDeleteSetting"]                  := l_lTestForeignKeyMissingOnDeleteSetting
    l_hValues["TestEnumerationHasAtLeastOnePresentValue"]              := l_lTestEnumerationHasAtLeastOnePresentValue
    l_hValues["TestEnumerationValueNumberUniqueness"]                  := l_lTestEnumerationValueNumberUniqueness
    l_hValues["TestNumericEnumerationWideEnough"]                      := l_lTestNumericEnumerationWideEnough
    l_hValues["TestIdentifierMaxLengthAsPostgres"]                     := l_lTestIdentifierMaxLengthAsPostgres
    l_hValues["TestMissingForeignKeyTable"]                            := l_lTestMissingForeignKeyTable
    l_hValues["TestMissingEnumerationValues"]                          := l_lTestMissingEnumerationValues
    l_hValues["TestUseOfDiscontinuedEnumeration"]                      := l_lTestUseOfDiscontinuedEnumeration
    l_hValues["TestUseOfDiscontinuedForeignTable"]                     := l_lTestUseOfDiscontinuedForeignTable
    l_hValues["TestValidColumnLengthAndScale"]                         := l_lTestValidColumnLengthAndScale
    l_hValues["TestNoLeadingOrTrainingBlanksInIdentifiers"]            := l_lTestNoLeadingOrTrainingBlanksInIdentifiers
    l_hValues["TestValidNonEnumValueIdentifierAsVariableName"]         := l_lTestValidNonEnumValueIdentifierAsVariableName
    l_hValues["TestValidSQLEnumValueIdentifierAsVariableName"]         := l_lTestValidSQLEnumValueIdentifierAsVariableName
    l_hValues["TestValidSQLEnumValueIdentifierAsAlphaNumericExtended"] := l_lTestValidSQLEnumValueIdentifierAsAlphaNumericExtended
    l_hValues["TestIndexOnPrimaryAndForeignKeys"]                      := l_lTestIndexOnPrimaryAndForeignKeys
    l_hValues["TestUniquenessCaseInsensitiveIdentifiers"]              := l_lTestUniquenessCaseInsensitiveIdentifiers
    l_hValues["TestUniquenessTableSQLEnumerationIdentifiers"]          := l_lTestUniquenessTableSQLEnumerationIdentifiers

    l_cHtml += DataDictionaryEditFormBuild(l_cErrorMessage,l_iApplicationPk,l_hValues)

case empty(l_cErrorMessage)
    if empty(l_iApplicationPk)
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries")
    else
        oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionarySettings/"+par_cURLApplicationLinkCode+"/")
    endif

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function NamespaceListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB_ListOfNamespaces   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPreviousName := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCustomFields := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfNamespaces
local l_nNumberOfCustomFieldValues := 0
local l_lWarnings := .f.
local l_nColspan
local l_lHasExternalId :=.f.

local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("NamespaceListFormBuild")

with object l_oDB_ListOfNamespaces
    :Table("27c7cda8-7433-4416-a18a-74b38bb8bd6e","Namespace")
    :Column("Namespace.pk"              ,"pk")
    :Column("Namespace.LinkUID"         ,"Namespace_LinkUID")
    :Column("Namespace.Name"            ,"Namespace_Name")
    :Column("Namespace.TrackNameChanges","Namespace_TrackNameChanges")
    :Column("Namespace.AKA"             ,"Namespace_AKA")
    :Column("Namespace.UseStatus"       ,"Namespace_UseStatus")
    :Column("Namespace.DocStatus"       ,"Namespace_DocStatus")
    :Column("Namespace.Description"     ,"Namespace_Description")
    :Column("Namespace.TestWarning"     ,"Namespace_TestWarning")
    :Column("Namespace.ExternalId"      ,"Namespace_ExternalId")
    :Column("Upper(Namespace.Name)"     ,"tag1")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNamespaces")
    l_nNumberOfNamespaces := :Tally
endwith

with object l_oDB_ListOfPreviousName
    :Table("162aaf74-05b9-4606-8ba7-e7dd65f3bc8e","Namespace")
    :Column("Namespace.pk"              ,"pk")
    :Column("NamespacePreviousName.pk"  ,"PreviousName_pk")   //Will use the pk to order, since it is incremental
    :Column("NamespacePreviousName.Name","PreviousName_Name")
    :Join("inner","NamespacePreviousName","","NamespacePreviousName.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfPreviousName")
    with object :p_oCursor
        :Index("tag1","alltrim(str(pk))+'*'+str(9999999999-PreviousName_pk,10)")
        :CreateIndexes()
    endwith
endwith

if l_nNumberOfNamespaces > 0

    select ListOfNamespaces
    scan all while !l_lWarnings .or. !l_lHasExternalId
        if !empty(nvl(ListOfNamespaces->Namespace_TestWarning,""))
            l_lWarnings := .t.
        endif
        if nvl(ListOfNamespaces->Namespace_ExternalId,0) > 0
            l_lHasExternalId := .t.
        endif
    endscan

    with object l_oDB_ListOfCustomFields
        :Table("713be6a6-ff44-4b10-893c-aa80400864bf","Namespace")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Namespace.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_NAMESPACE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("8e9d02fa-3cfe-41f2-b426-dbe222d62db2","Namespace")
        :Column("Namespace.pk"           ,"fk_entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Namespace.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_NAMESPACE)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

endif

if empty(l_nNumberOfNamespaces)
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetButtonOnEditFormNew("New Namespace",l_cSitePath+[DataDictionaries/NewNamespace/]+par_cURLApplicationLinkCode+[/])
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif
    l_cHtml += GetNoRecordsOnFile("No Namespace on file.")

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetButtonOnEditFormNew("New Namespace",l_cSitePath+[DataDictionaries/NewNamespace/]+par_cURLApplicationLinkCode+[/])
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_nColspan := 4
    if l_lHasExternalId
        l_nColspan++
    endif
    if l_nNumberOfCustomFieldValues > 0
        l_nColspan++
    endif
    if l_lWarnings
        l_nColspan++
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="]+Trans(l_nColspan)+[">Namespaces (]+Trans(l_nNumberOfNamespaces)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                    if l_lHasExternalId
                        l_cHtml += [<th class="text-white">External Id</th>]
                    endif
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="text-white text-center">Other</th>]
                    endif
                    if l_lWarnings
                        l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfNamespaces
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfNamespaces->Namespace_UseStatus)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditNamespace/]+par_cURLApplicationLinkCode+[/]+;
                                                                PrepareForURLSQLIdentifier("Namespace",ListOfNamespaces->Namespace_Name,ListOfNamespaces->Namespace_LinkUID)+;
                                                                [/">]+TextToHtml(ListOfNamespaces->Namespace_Name+FormatAKAForDisplay(ListOfNamespaces->Namespace_AKA))+[</a>]
                        
                            if el_seek(trans(ListOfNamespaces->pk)+'*',"ListOfPreviousName","tag1")
                                select ListOfPreviousName
                                scan while ListOfPreviousName->pk == ListOfNamespaces->pk
                                    l_cHtml += [<div class="ps-1 small">Previously: ]+TextToHtml(ListOfPreviousName->PreviousName_Name)+[</div>]
                                endscan
                            endif
                        
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfNamespaces->Namespace_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfNamespaces->Namespace_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfNamespaces->Namespace_UseStatus,USESTATUS_UNKNOWN)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfNamespaces->Namespace_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfNamespaces->Namespace_DocStatus,DOCTATUS_MISSING)]
                        l_cHtml += [</td>]

                        if l_lHasExternalId
                            l_cHtml += [<td class="GridDataControlCells" valign="top" align="right">]
                                if nvl(ListOfNamespaces->Namespace_ExternalId,0) > 0
                                    l_cHtml += trans(ListOfNamespaces->Namespace_ExternalId)
                                endif
                            l_cHtml += [</td>]
                        endif
                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfNamespaces->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif
                        if l_lWarnings
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += TextToHtml(hb_DefaultValue(ListOfNamespaces->Namespace_TestWarning,""))
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
static function NamespaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName             := hb_HGetDef(par_hValues,"Name","")
local l_lTrackNameChanges := nvl(hb_HGetDef(par_hValues,"TrackNameChanges",.t.),.t.)
local l_cAKA              := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_nUseStatus        := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus        := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription      := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_iExternalId       := nvl(hb_HGetDef(par_hValues,"ExternalId",0),0)

oFcgi:TraceAdd("NamespaceEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Namespace")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormDelete()
                l_cHtml += GetConfirmationModalFormsDelete()

                l_cHtml += GetButtonOnEditFormDuplicate()
                l_cHtml += GetConfirmationModalFormsDuplicate("Only the Namespace definition will be duplicated.")

            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]
if !empty(par_iPk)
    l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr>]   // class="pb-5"
        l_cHtml += [<td class="pe-2 pb-2">Name</td>]
        l_cHtml += [<td class="pb-2">]
            l_cHtml += [<input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80">]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += GetTrackNameChangesAndPreviousNamesEditFormBuild(l_lTrackNameChanges,"Namespace",par_iPk)

    l_cHtml += [<tr>]   // class="pb-5"
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]   // class="pb-5"
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]   // class="pb-5"
        l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus">]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    if !empty(l_iExternalId)
        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">External Id</td>]
            l_cHtml += [<td class="pb-3">]+trans(l_iExternalId)+[ (Created via API call)</td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_NAMESPACE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

    l_cHtml += [</table>]

    l_cHtml += [<input type="hidden" name="TextExternalId" id="TextExternalId" value="]+trans(l_iExternalId)+[">]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function NamespaceEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iNamespacePk
local l_cNamespaceName
local l_lNamespaceTrackNameChanges
local l_cNamespaceAKA
local l_iNamespaceUseStatus
local l_iNamespaceDocStatus
local l_cNamespaceDescription
local l_iNamespaceExternalId

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oData
local l_cLinkUID
local l_cName
local l_nPos
local l_lDuplicate

oFcgi:TraceAdd("NamespaceEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iNamespacePk               := Val(oFcgi:GetInputValue("TableKey"))

l_cNamespaceName             := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_lNamespaceTrackNameChanges := (oFcgi:GetInputValue("CheckTrackNameChanges") == "1")
l_cNamespaceAKA              := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cNamespaceAKA)
    l_cNamespaceAKA := NIL
endif
l_iNamespaceUseStatus        := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_iNamespaceDocStatus        := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cNamespaceDescription      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_iNamespaceExternalId       := Val(oFcgi:GetInputValue("TextExternalId"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 3
        if empty(l_cNamespaceName)
            l_cErrorMessage := "Missing Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("ff18156d-1501-4629-b1ca-a3db929d95ea","Namespace")
                :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cNamespaceName," ","")))
                :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                if l_iNamespacePk > 0
                    :Where([Namespace.pk != ^],l_iNamespacePk)
                endif
                :SQL()
                l_lDuplicate := (:Tally <> 0)

                if !l_lDuplicate
                    //Also test on the Previous Names
                    :Table("9c02ea5d-c9e7-46e3-8ea7-a111d9c3b3fa","Namespace")
                    :Where([lower(replace(NamespacePreviousName.Name,' ','')) = ^],lower(StrTran(l_cNamespaceName," ","")))
                    :Join("inner","NamespacePreviousName","","NamespacePreviousName.fk_Namespace = Namespace.pk")
                    :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                    if l_iNamespacePk > 0
                        :Where([Namespace.pk != ^],l_iNamespacePk)
                    endif
                    :SQL()
                    l_lDuplicate := (:Tally <> 0)
                endif
            endwith

            if l_lDuplicate
                l_cErrorMessage := "Duplicate Name"
            else
                //Save the Namespace
                with object l_oDB1
                    l_cErrorMessage := TrackNameChange(l_oDB1,"Namespace",l_iNamespacePk,l_cNamespaceName,l_lNamespaceTrackNameChanges)
                    if empty(l_cErrorMessage)
                        RemovePreviousNameIfSelectedEditFormOnSubmit("Namespace",l_iNamespacePk)

                        :Table("baf7af76-6013-4b53-ba26-4006e22f52cb","Namespace")
                        if oFcgi:p_nAccessLevelDD >= 5
                            :Field("Namespace.Name"            ,l_cNamespaceName)
                            :Field("Namespace.TrackNameChanges",l_lNamespaceTrackNameChanges)
                            :Field("Namespace.AKA"             ,l_cNamespaceAKA)
                            :Field("Namespace.UseStatus"       ,l_iNamespaceUseStatus)
                        endif
                        :Field("Namespace.DocStatus"           ,l_iNamespaceDocStatus)
                        :Field("Namespace.Description"         ,iif(empty(l_cNamespaceDescription),NULL,l_cNamespaceDescription))
                        if empty(l_iNamespacePk)
                            :Field("Namespace.fk_Application"  ,par_iApplicationPk)
                            :Field("Namespace.LinkUID"         ,oFcgi:p_o_SQLConnection:GetUUIDString())
                            if :Add()
                                l_iNamespacePk := :Key()
                            else
                                l_cErrorMessage := "Failed to add Namespace."
                            endif
                        else
                            if !:Update(l_iNamespacePk)
                                l_cErrorMessage := "Failed to update Namespace."
                            endif
                            // SendToClipboard(:LastSQL())
                        endif
                    endif

                    if empty(l_cErrorMessage)
                        CustomFieldsSave(par_iApplicationPk,USEDON_NAMESPACE,l_iNamespacePk)
                        l_iNamespacePk := 0
                    endif
                endwith

                DataDictionaryFixAndTest(par_iApplicationPk)
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iNamespacePk := 0

case l_cActionOnSubmit == "Delete"   // Namespace
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveNamespaceDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteNamespace(par_iApplicationPk,l_iNamespacePk)
            if empty(l_cErrorMessage)
                l_iNamespacePk := 0
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("910d6dd3-4bcb-4d96-a092-61730e83380c","Table")
                :Where("table.fk_Namespace = ^",l_iNamespacePk)
                :SQL()

                if :Tally == 0
                    :Table("1228e164-50b6-447a-81c3-e2e0430983fc","Enumeration")
                    :Where("Enumeration.fk_Namespace = ^",l_iNamespacePk)
                    :SQL()

                    if :Tally == 0
                        CustomFieldsDelete(par_iApplicationPk,USEDON_NAMESPACE,l_iNamespacePk)
                        :Delete("08e836c0-5ee8-4732-b76f-a303a4c5bf91","Namespace",l_iNamespacePk)
                        l_iNamespacePk := 0
                    else
                        l_cErrorMessage := "Related Enumeration record on file"
                    endif
                else
                    l_cErrorMessage := "Related Table record on file"
                endif
            endwith
        endif
    endif

case l_cActionOnSubmit == "Duplicate"   // Namespace
    if oFcgi:p_nAccessLevelDD >= 5 .and. l_iNamespacePk > 0

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("e4baa6fb-b62d-49ef-8e88-d68552f9e460","Namespace")
            :Column("Namespace.LinkUID"         ,"Namespace_LinkUID")
            :Column("Namespace.Name"            ,"Namespace_Name")
            :Column("Namespace.TrackNameChanges","Namespace_TrackNameChanges")
            :Column("Namespace.UseStatus"       ,"Namespace_UseStatus")
            :Column("Namespace.DocStatus"       ,"Namespace_DocStatus")
            :Column("Namespace.Description"     ,"Namespace_Description")
            l_oData := :Get(l_iNamespacePk)

            if !hb_IsNil(l_oData)
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                l_cName := OnDuplicateSanitizeName(l_oData:Namespace_Name,l_cLinkUID,l_oData:Namespace_LinkUID)
                
                :Table("b9552326-f36e-4f9a-a353-087f54f4ee08","Namespace")
                :Field("Namespace.LinkUID"         ,l_cLinkUID)
                :Field("Namespace.Name"            ,l_cName)
                :Field("Namespace.TrackNameChanges",l_oData:Namespace_TrackNameChanges)
                :Field("Namespace.UseStatus"       ,l_oData:Namespace_UseStatus)
                :Field("Namespace.DocStatus"       ,l_oData:Namespace_DocStatus)
                :Field("Namespace.Description"     ,l_oData:Namespace_Description)
                :Field("Namespace.fk_Application"  ,par_iApplicationPk)
                if :Add()
                    l_iNamespacePk := :Key()
                else
                    l_cErrorMessage := "Failed to add Namespace."
                endif
            endif

        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    else
        l_cErrorMessage := "No Access to Duplicate"
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]             := l_cNamespaceName
    l_hValues["TrackNameChanges"] := l_lNamespaceTrackNameChanges
    l_hValues["AKA"]              := l_cNamespaceAKA
    l_hValues["UseStatus"]        := l_iNamespaceUseStatus
    l_hValues["DocStatus"]        := l_iNamespaceDocStatus
    l_hValues["Description"]      := l_cNamespaceDescription
    l_hValues["ExternalId"]       := l_iNamespaceExternalId

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_NAMESPACE,@l_hValues)

    l_cHtml += NamespaceEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iNamespacePk,l_hValues)

case l_iNamespacePk = 0
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListNamespaces/"+par_cURLApplicationLinkCode+"/")

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("4fc421b6-82b8-4998-b3f6-704e911037c3","Namespace")
        :Column("Namespace.Name"   ,"Namespace_Name")
        :Column("Namespace.LinkUID","Namespace_LinkUID")
        l_oData := l_oDB1:Get(l_iNamespacePk)
        if l_oDB1:Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditNamespace/"+par_cURLApplicationLinkCode+"/"+;
                                              PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+"/";
                                              )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListNamespaces/"+par_cURLApplicationLinkCode+"/")
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableListFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_nSearchMode
local l_cSearchNamespaceName
local l_cSearchNamespaceDescription
local l_cSearchTableName
local l_cSearchTableDescription
local l_cSearchTableTags
local l_cSearchColumnName
local l_cSearchColumnDescription
local l_cSearchEnumerationName
local l_cSearchEnumerationDescription
local l_cSearchTableUsageStatus
local l_cSearchTableDocStatus
local l_cSearchColumnUsageStatus
local l_cSearchColumnDocStatus
local l_cSearchColumnStaticUID
local l_cSearchColumnTypes
local l_cSearchExtraFilters
local l_cURL

oFcgi:TraceAdd("TableListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_nSearchMode                   := min(3,max(1,val(oFcgi:GetInputValue("RadioSearchMode"))))

l_cSearchNamespaceName          := SanitizeInput(oFcgi:GetInputValue("TextSearchNamespaceName"))
l_cSearchNamespaceDescription   := SanitizeInput(oFcgi:GetInputValue("TextSearchNamespaceDescription"))

l_cSearchTableName              := SanitizeInput(oFcgi:GetInputValue("TextSearchTableName"))
l_cSearchTableDescription       := SanitizeInput(oFcgi:GetInputValue("TextSearchTableDescription"))

l_cSearchColumnName             := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnName"))
l_cSearchColumnDescription      := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnDescription"))

l_cSearchEnumerationName        := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationName"))
l_cSearchEnumerationDescription := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationDescription"))

l_cSearchTableTags              := SanitizeInput(oFcgi:GetInputValue("TextSearchTableTags"))

l_cSearchTableUsageStatus       := SanitizeInput(oFcgi:GetInputValue("TextSearchTableUsageStatus"))
l_cSearchTableDocStatus         := SanitizeInput(oFcgi:GetInputValue("TextSearchTableDocStatus"))
l_cSearchColumnUsageStatus      := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnUsageStatus"))
l_cSearchColumnDocStatus        := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnDocStatus"))
l_cSearchColumnStaticUID        := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnStaticUID"))
l_cSearchColumnTypes            := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnTypes"))
l_cSearchExtraFilters           := SanitizeInput(oFcgi:GetInputValue("TextSearchExtraFilters"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_Mode"                  ,trans(l_nSearchMode))

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceName"         ,l_cSearchNamespaceName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceDescription"  ,l_cSearchNamespaceDescription)

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName"             ,l_cSearchTableName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription"      ,l_cSearchTableDescription)

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName"            ,l_cSearchColumnName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription"     ,l_cSearchColumnDescription)

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationName"       ,l_cSearchEnumerationName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationDescription",l_cSearchEnumerationDescription)

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags"             ,l_cSearchTableTags)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags"            ,"")   // _M_

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableUsageStatus"      ,l_cSearchTableUsageStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDocStatus"        ,l_cSearchTableDocStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnUsageStatus"     ,l_cSearchColumnUsageStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDocStatus"       ,l_cSearchColumnDocStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnStaticUID"       ,l_cSearchColumnStaticUID)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTypes"           ,l_cSearchColumnTypes)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ExtraFilters"          ,l_cSearchExtraFilters)

    l_cHtml += TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

case l_cActionOnSubmit == "Reset"
    // SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_Mode"                  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceName"         ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceDescription"  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName"             ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription"      ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName"            ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription"     ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationName"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationDescription","")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags"             ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags"            ,"")

    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableUsageStatus"      ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDocStatus"        ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnUsageStatus"     ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDocStatus"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnStaticUID"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTypes"           ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ExtraFilters"          ,"")

    l_cURL := oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

endcase

return l_cHtml
//=================================================================================================================
static function TableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB_ListOfTables               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnCounts         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfIndexCounts          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_TableTags                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_AnyTags                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfReferencedByCounts   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDiagramsCounts       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_DiagramsWithAllTablesCount := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPreviousName         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_oCursor
local l_iTablePk
local l_nCountProposed
local l_nCount
local l_nCountDiscontinued
local l_nSearchMode

local l_cSearchNamespaceName
local l_cSearchNamespaceDescription

local l_cSearchTableName
local l_cSearchTableDescription

local l_cSearchColumnName
local l_cSearchColumnDescription

local l_cSearchEnumerationName
local l_cSearchEnumerationDescription

local l_cSearchTableTags
local l_cSearchColumnTags

local l_cSearchTableUsageStatus
local l_cSearchTableDocStatus
local l_cSearchColumnUsageStatus
local l_cSearchColumnDocStatus
local l_cSearchColumnStaticUID
local l_cSearchColumnTypes
local l_cSearchExtraFilters

local l_nNumberOfTables := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cColumnSearchParameters
local l_nNumberOfTags
local l_nColspan
local l_cTagsInfo
local l_nNumberOfUsedTags
local l_json_TableTags
local l_json_ColumnTypes
local l_json_ExtraFilters
local l_cTagInfo
local l_ScriptFolder
local l_lHasExternalId :=.f.
local l_lWarnings := .f.
local l_aColumnTypes
local l_cCombinedPath
local l_nNumberOfDiagramsWithAllTables

local l_cLine
local l_nMaxWidth
local l_lExtraInfo

oFcgi:TraceAdd("TableListFormBuild")

l_nSearchMode                   := min(3,max(1,val(GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_Mode"))))

l_cSearchNamespaceName          := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceName")
l_cSearchNamespaceDescription   := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_NamespaceDescription")

l_cSearchTableName              := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableName")
l_cSearchTableDescription       := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDescription")

l_cSearchColumnName             := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnName")
l_cSearchColumnDescription      := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDescription")

l_cSearchEnumerationName        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationName")
l_cSearchEnumerationDescription := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_EnumerationDescription")

l_cSearchTableTags              := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableTags")
l_cSearchColumnTags             := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTags")

l_cSearchTableUsageStatus       := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableUsageStatus")
l_cSearchTableDocStatus         := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_TableDocStatus")
l_cSearchColumnUsageStatus      := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnUsageStatus")
l_cSearchColumnDocStatus        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnDocStatus")
l_cSearchColumnStaticUID        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnStaticUID")
l_cSearchColumnTypes            := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTypes")
l_cSearchExtraFilters           := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ExtraFilters")

if empty(l_cSearchColumnName) .and. empty(l_cSearchColumnStaticUID) .and. empty(l_cSearchColumnDescription)  //_M_ on Column Tags
    l_cColumnSearchParameters := ""
else
    l_cColumnSearchParameters := [Search?ColumnName=]+hb_StrToHex(l_cSearchColumnName)+[&ColumnStaticUID=]+hb_StrToHex(l_cSearchColumnStaticUID)+[&ColumnDescription=]+hb_StrToHex(l_cSearchColumnDescription)   //strtolhex
endif

//Find out if any tags are linked to any tables, regardless of filter
with object l_oDB_AnyTags
    :Table("1f510c4e-d637-4803-814b-6bae91676385","TagTable")
    :Join("inner","Table","","TagTable.fk_Table = Table.pk")
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Where("Tag.TableUseStatus = ^",TAGUSESTATUS_ACTIVE)
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
    :Column("Namespace.LinkUID","Namespace_LinkUID")
    :Column("Namespace.Name"   ,"Namespace_Name")
    :Column("Namespace.AKA"    ,"Namespace_AKA")
    :Column("Table.LinkUID"    ,"Table_LinkUID")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.AKA"        ,"Table_AKA")
    :Column("Table.Unlogged"   ,"Table_Unlogged")
    :Column("Table.UseStatus"  ,"Table_UseStatus")
    :Column("Table.DocStatus"  ,"Table_DocStatus")
    :Column("Table.Description","Table_Description")
    :Column("Table.Information","Table_Information")
    :Column("Table.TestWarning","Table_TestWarning")
    :Column("Table.ExternalId" ,"Table_ExternalId")
    :Column("Upper(Namespace.Name)","tag1")
    :Column("Upper(Table.Name)","tag2")
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)

    TableListFormAddFiltering(l_oDB_ListOfTables,;
                              l_nSearchMode,;
                              l_cSearchNamespaceName,;
                              l_cSearchNamespaceDescription,;
                              l_cSearchTableName,;
                              l_cSearchTableDescription,;
                              l_cSearchColumnName,;
                              l_cSearchColumnDescription,;
                              l_cSearchEnumerationName,;
                              l_cSearchEnumerationDescription,;
                              l_cSearchTableTags,;
                              l_cSearchTableUsageStatus,;
                              l_cSearchTableDocStatus,;
                              l_cSearchColumnUsageStatus,;
                              l_cSearchColumnDocStatus,;
                              l_cSearchColumnStaticUID,;
                              l_cSearchColumnTypes,;
                              l_cSearchExtraFilters;
                              )

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfTables")
    l_nNumberOfTables := :Tally

    // SendToClipboard(:LastSQL())

endwith

if l_nNumberOfTables > 0

    with object l_oDB_ListOfPreviousName
        //Not adding the extra conditions since in any case el_seek will be used.
        :Table("01813641-5555-4be0-b867-683c2746f6b2","Table")
        :Column("Table.pk"              ,"pk")
        :Column("TablePreviousName.pk"  ,"PreviousName_pk")   //Will use the pk to order, since it is incremental
        :Column("TablePreviousName.Name","PreviousName_Name")
        :Join("inner","TablePreviousName","","TablePreviousName.fk_Table = Table.pk")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :SQL("ListOfPreviousName")
        with object :p_oCursor
            :Index("tag1","alltrim(str(pk))+'*'+str(9999999999-PreviousName_pk,10)")
            :CreateIndexes()
        endwith
    endwith

    select ListOfTables
    scan all while !l_lWarnings .or. !l_lHasExternalId
        if !empty(nvl(ListOfTables->Table_TestWarning,""))
            l_lWarnings := .t.
        endif
        if nvl(ListOfTables->Table_ExternalId,0) > 0
            l_lHasExternalId := .t.
        endif
    endscan

    with object l_oDB_CustomField
        :Table("9002a459-657d-428b-b5e2-665851c7f853","Table")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Table.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Namespace.fk_Application = ^",par_iApplicationPk)

        :Where("CustomField.UsedOn = ^",USEDON_TABLE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice

        TableListFormAddFiltering(l_oDB_CustomField,;
                                  l_nSearchMode,;
                                  l_cSearchNamespaceName,;
                                  l_cSearchNamespaceDescription,;
                                  l_cSearchTableName,;
                                  l_cSearchTableDescription,;
                                  l_cSearchColumnName,;
                                  l_cSearchColumnDescription,;
                                  l_cSearchEnumerationName,;
                                  l_cSearchEnumerationDescription,;
                                  l_cSearchTableTags,;
                                  l_cSearchTableUsageStatus,;
                                  l_cSearchTableDocStatus,;
                                  l_cSearchColumnUsageStatus,;
                                  l_cSearchColumnDocStatus,;
                                  l_cSearchColumnStaticUID,;
                                  l_cSearchColumnTypes,;
                                  l_cSearchExtraFilters;
                                  )

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

        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Table.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Where("CustomField.UsedOn = ^",USEDON_TABLE)
        :Where("CustomField.Status <= 2")

        TableListFormAddFiltering(l_oDB_CustomField,;
                                  l_nSearchMode,;
                                  l_cSearchNamespaceName,;
                                  l_cSearchNamespaceDescription,;
                                  l_cSearchTableName,;
                                  l_cSearchTableDescription,;
                                  l_cSearchColumnName,;
                                  l_cSearchColumnDescription,;
                                  l_cSearchEnumerationName,;
                                  l_cSearchEnumerationDescription,;
                                  l_cSearchTableTags,;
                                  l_cSearchTableUsageStatus,;
                                  l_cSearchTableDocStatus,;
                                  l_cSearchColumnUsageStatus,;
                                  l_cSearchColumnDocStatus,;
                                  l_cSearchColumnStaticUID,;
                                  l_cSearchColumnTypes,;
                                  l_cSearchExtraFilters;
                                  )

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
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Join("inner","TagTable","","TagTable.fk_Table = Table.pk")
        :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Where("Tag.fk_Application = ^",par_iApplicationPk)
        :Where("Tag.TableUseStatus = ^",TAGUSESTATUS_ACTIVE)
        :OrderBy("tag1")
        :SQL("ListOfTagTables")
        l_nNumberOfTags := :Tally
    endif

    //For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a el_seek technic will not be needed.
    with object l_oDB_ListOfColumnCounts
        :Table("30c4a441-523c-40ca-85eb-e4b30f6358cc","Table")
        :Column("Table.pk" ,"Table_pk")
        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
        :Column("SUM(CASE WHEN Column.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Table_pk")
        :SQL("ListOfColumnCounts")
        with object :p_oCursor
            :Index("tag1","Table_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfIndexCounts
        :Table("8ed29bff-8f51-4140-a889-d22dcca7c313","Table")
        :Column("Table.pk" ,"Table_pk")
        :Column("SUM(CASE WHEN Index.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )" ,"CountProposed")
        :Column("SUM(CASE WHEN Index.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
        :Column("SUM(CASE WHEN Index.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )" ,"CountDiscontinued")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Index","","Index.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Table_pk")
        :SQL("ListOfIndexCounts")
        with object :p_oCursor
            :Index("tag1","Table_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfReferencedByCounts
        :Table("50f61f99-86cd-437b-9e0f-8d949a67525d","Namespace")
        :Column("Table.pk" ,"Table_pk")
        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )"                                          ,"CountProposed")
        :Column("SUM(CASE WHEN Column.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"Count")
        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )"                                      ,"CountDiscontinued")
        :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_TableForeign = Table.pk and Column.UsedAs = 3")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Table_pk")
        :SQL("ListOfReferencedByCounts")
        with object :p_oCursor
            :Index("tag1","Table_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfDiagramsCounts
        :Table("789d62b0-bec2-4fe8-b7d0-896e70b7495e","Namespace")
        :Column("Table.pk" ,"Table_pk")
        :Column("Count(*)" ,"Count")
        :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
        :Join("inner","DiagramTable","","DiagramTable.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Table_pk")
        :SQL("ListOfDiagramsCounts")
        with object :p_oCursor
            :Index("tag1","Table_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_DiagramsWithAllTablesCount
        :Table("b9b89abc-8493-4e80-afae-6601f6d4a364","Diagram")
        :Where("Diagram.fk_Application = ^",par_iApplicationPk)
        :Join("left","DiagramTable","","DiagramTable.fk_Diagram = Diagram.pk")
        :Where("DiagramTable.Pk IS NULL")
        l_nNumberOfDiagramsWithAllTables := :Count()
        SendToDebugView("Number Of Diagrams With All Tables = "+Trans(l_nNumberOfDiagramsWithAllTables))
    endwith

else
    l_lWarnings := .f.
endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="PageLoaded" id="PageLoaded" value="0">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_ScriptFolder := l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

l_json_TableTags := []
if l_nNumberOfUsedTags > 0
    //Multi Select Support for tags

    with object l_oDB_ListOfTags
        :Table("9af99d6b-dd79-4bfb-904d-08d48f687cb3","Tag")
        :Column("Tag.pk"   , "pk")
        :Column("Tag.Name" , "Tag_Name")
        :Column("upper(Tag.Name)" , "tag1")
        :Column("Tag.Code" , "Tag_Code")
        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
        :Where("Tag.TableUseStatus = ^",TAGUSESTATUS_ACTIVE)
        :OrderBy("Tag1")
        :SQL("ListOfTags")
        l_nNumberOfTags := :Tally

        if l_nNumberOfTags > 0
            select ListOfTags
            scan all
                if !empty(l_json_TableTags)
                    l_json_TableTags += [,]
                endif
                l_cTagInfo := ListOfTags->Tag_Name+[ (]+ListOfTags->Tag_Code+[)]
                l_json_TableTags += "{tag:'"+TextToHTML(l_cTagInfo)+"',value:"+trans(ListOfTags->pk)+"}"
            endscan
        endif
    endwith

endif

l_json_ColumnTypes := []
for each l_aColumnTypes in oFcgi:p_ColumnTypes
    if !empty(l_json_ColumnTypes)
        l_json_ColumnTypes += [,]
    endif
    l_json_ColumnTypes += "{tag:'"+TextToHTML(l_aColumnTypes[COLUMN_TYPES_NAME])+"',value:'"+l_aColumnTypes[COLUMN_TYPES_CODE]+"'}"
endfor

l_json_ExtraFilters :=  [{tag:'Warning',value:'WNG'}]
l_json_ExtraFilters += [,{tag:'Unlogged Table',value:'ULT'}]
l_json_ExtraFilters += [,{tag:'Non Unlogged Table',value:'LGT'}]
l_json_ExtraFilters += [,{tag:'Array Type Column',value:'ART'}]
// l_json_ExtraFilters += [,{tag:'',value:''}]

oFcgi:p_cjQueryScript += "$('#PageLoaded').val('1');"

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 150px;} ]
l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
l_cHtml += [</style>]

l_cHtml += [<script type="text/javascript">]

l_cHtml += [function SearchModeChanged(par_nSearchMode)]
l_cHtml += [{]
    l_cHtml += [switch (par_nSearchMode) {]
    l_cHtml += [case 1:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").hide();$(".SearchMode3").hide();]
    l_cHtml += [   break;]
    l_cHtml += [case 2:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").show();$(".SearchMode3").hide();]
    l_cHtml += [   break;]
    l_cHtml += [case 3:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").show();$(".SearchMode3").show();]
    l_cHtml += [   break;]
    l_cHtml += [default:]
    l_cHtml += [   console.log(`Sorry, we are out of ${expr}.`);]
    l_cHtml += [};return true;]
l_cHtml += [}]

l_cHtml += [function SaveSearchMode(par_nSearchMode)]
l_cHtml += [{]
    l_cHtml += [$.ajax({]
    l_cHtml += [  type: 'GET',]
    l_cHtml += [  url: ']+l_cSitePath+[ajax/SaveSearchModeTable',]
    l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&SearchMode='+par_nSearchMode,]
    l_cHtml += [  cache: false ]
    l_cHtml += [});]
    l_cHtml += [return true;]
l_cHtml += [}]

l_cHtml += [</script>]

l_cHtml += GetCopyToClipboardJavaScript("CopyRoster")

l_cHtml += [<pre id="PreTablesToClipboard" style="display:none;">]
    select ListOfTables
    l_nMaxWidth  := 0
    l_lExtraInfo := .f.

    scan all
        l_nMaxWidth := max(l_nMaxWidth,len(ListOfTables->Table_Name))
        if ListOfTables->Table_UseStatus = USESTATUS_PROPOSED .or. ;
           ListOfTables->Table_UseStatus = USESTATUS_DISCONTINUED
            l_lExtraInfo := .t.
        endif
    endscan

    scan all
        if !l_lExtraInfo
            l_cLine := ListOfTables->Table_Name

        else
            l_cLine := padr(ListOfTables->Table_Name,l_nMaxWidth)

            do case
            case ListOfTables->Table_UseStatus = USESTATUS_PROPOSED
                l_cLine += [ (Proposed)]
            case ListOfTables->Table_UseStatus = USESTATUS_DISCONTINUED
                l_cLine += [ (Discontinued)]
            endcase

        endif

        l_cHtml += l_cLine+CRLF
    endscan

l_cHtml += [</pre>]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group mb-3">]

        if oFcgi:p_nAccessLevelDD >= 5
            l_cHtml += GetButtonOnEditFormNew("New Table",l_cSitePath+[DataDictionaries/NewTable/]+par_cURLApplicationLinkCode+[/])
        endif

        l_cHtml += [<input type="button" role="button" value="Copy Table List To Clipboard" class="btn btn-primary rounded ms-3" id="CopyRoster" onclick="]
        l_cHtml += [copyToClip(document.getElementById('PreTablesToClipboard').innerText);return false;">]

    l_cHtml += [</div><div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<span class="ms-3"></span>]  //To make some spacing
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td valign="top">]
                    l_cHtml += [<table>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td></td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr class="SearchMode2">]
                            l_cHtml += [<td><span class="me-2">Namespace</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchNamespaceName" id="TextSearchNamespaceName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchNamespaceName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchNamespaceDescription" id="TextSearchNamespaceDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchNamespaceDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr class="SearchMode1">]
                            l_cHtml += [<td><span class="me-2">Table</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchTableName" id="TextSearchTableName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchTableName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchTableDescription" id="TextSearchTableDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchTableDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr class="SearchMode2">]
                            l_cHtml += [<td><span class="me-2">Column</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchColumnName" id="TextSearchColumnName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchColumnDescription" id="TextSearchColumnDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr class="SearchMode2">]
                            l_cHtml += [<td><span class="me-2">Enumeration</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumerationName" id="TextSearchEnumerationName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEnumerationName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumerationDescription" id="TextSearchEnumerationDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEnumerationDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]

                        if !empty(l_json_TableTags)
                            l_cHtml += [<tr class="SearchMode3">]
                                l_cHtml += [<td><span class="me-2">Table Tags</span></td>]
                                l_cHtml += [<td class="AdvancedSearch" colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchTableTags",l_json_TableTags,l_cSearchTableTags,25)
                                l_cHtml += [</td>]
                            l_cHtml += [</tr>]
                        endif
       
                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Table Usage Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchTableUsageStatus",;
                                                                   "{tag:'Unknown',value:1},{tag:'Proposed',value:2},{tag:'Under Development',value:3},{tag:'Active',value:4},{tag:'To Be Discontinued',value:5},{tag:'Discontinued',value:6}",;
                                                                   l_cSearchTableUsageStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Table Doc Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchTableDocStatus",;
                                                                   "{tag:'Missing',value:1},{tag:'Not Needed',value:2},{tag:'Composing',value:3},{tag:'Completed',value:4}",;
                                                                   l_cSearchTableDocStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Column Usage Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchColumnUsageStatus",;
                                                                   "{tag:'Unknown',value:1},{tag:'Proposed',value:2},{tag:'Under Development',value:3},{tag:'Active',value:4},{tag:'To Be Discontinued',value:5},{tag:'Discontinued',value:6}",;
                                                                   l_cSearchColumnUsageStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Column Doc Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchColumnDocStatus",;
                                                                   "{tag:'Missing',value:1},{tag:'Not Needed',value:2},{tag:'Composing',value:3},{tag:'Completed',value:4}",;
                                                                   l_cSearchColumnDocStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Column Static UID</span></td>]
                            //Made maxlength larger to work around trailing blank and tabs
                            l_cHtml += [<td colspan="2"><input type="text" name="TextSearchColumnStaticUID" id="TextSearchColumnStaticUID" size="36" maxlength="50" value="]+FcgiPrepFieldForValue(l_cSearchColumnStaticUID)+[" class="form-control">]
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Column Types</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchColumnTypes",;
                                                                   l_json_ColumnTypes,;
                                                                   l_cSearchColumnTypes,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Extra Filters</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchExtraFilters",;
                                                                   l_json_ExtraFilters,;
                                                                   l_cSearchExtraFilters,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        oFcgi:p_cjQueryScript += [SearchModeChanged(]+trans(l_nSearchMode)+[);]   // Calling the Javascript function needs to be done after the amsifySuggestags objects are activated.

                    l_cHtml += [</table>]

                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<div class="ms-3">]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio1" value="1" onchange="SearchModeChanged(1);SaveSearchMode(1);"]+iif(l_nSearchMode==1,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio1">Basic</label>]
                        l_cHtml += [</div>]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio2" value="2" onchange="SearchModeChanged(2);SaveSearchMode(2);"]+iif(l_nSearchMode==2,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio2">Standard</label>]
                        l_cHtml += [</div>]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio3" value="3" onchange="SearchModeChanged(3);SaveSearchMode(3);"]+iif(l_nSearchMode==3,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio3">Advanced</label>]
                        l_cHtml += [</div>]
                    l_cHtml += [</div>]
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<div align="center" class="ms-3 me-5">]
                        l_cHtml += [<div><input type="submit" class="btn btn-primary rounded mb-2" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button"></div>]
                        l_cHtml += [<div><input type="button" class="btn btn-primary rounded" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button"></div>]
                    l_cHtml += [</div>]
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

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_nColspan := 11
            if l_lHasExternalId
                l_nColspan++
            endif
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan++
            endif
            if l_nNumberOfTags > 0
                l_nColspan++
            endif
            if l_lWarnings
                l_nColspan++
            endif

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+Trans(l_nColspan)+[">Tables (]+Trans(l_nNumberOfTables)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Namespace</th>]
                l_cHtml += [<th class="text-white">Table Name</th>]
                l_cHtml += [<th class="text-white">Columns</th>]
                l_cHtml += [<th class="text-white">Indexes</th>]
                if l_nNumberOfTags > 0
                    l_cHtml += [<th class="text-white text-center">Tags</th>]
                endif
                l_cHtml += [<th class="text-white">Unlogged</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white">Info</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Referenced<br>By</th>]
                l_cHtml += [<th class="text-white text-center">Diagrams</th>]

                if l_lHasExternalId
                    l_cHtml += [<th class="text-white">External Id</th>]
                endif
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
                if l_lWarnings
                    l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                endif

            l_cHtml += [</tr>]

            select ListOfTables
            scan all
                l_iTablePk := ListOfTables->pk

                l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                                   PrepareForURLSQLIdentifier("Namespace",ListOfTables->Namespace_Name,ListOfTables->Namespace_LinkUID)+[/]+;
                                   PrepareForURLSQLIdentifier("Table"    ,ListOfTables->Table_Name    ,ListOfTables->Table_LinkUID)    +[/]

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfTables->Table_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(ListOfTables->Namespace_Name+FormatAKAForDisplay(ListOfTables->Namespace_AKA))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditTable/]+l_cCombinedPath+[/">]+TextToHtml(ListOfTables->Table_Name+FormatAKAForDisplay(ListOfTables->Table_AKA))+[</a>]

                        if el_seek(trans(ListOfTables->pk)+'*',"ListOfPreviousName","tag1")
                            select ListOfPreviousName
                            scan while ListOfPreviousName->pk == ListOfTables->pk
                                l_cHtml += [<div class="ps-1 small">Previously: ]+TextToHtml(ListOfPreviousName->PreviousName_Name)+[</div>]
                            endscan
                        endif

                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]

                        if el_seek(l_iTablePk,"ListOfColumnCounts","tag1")
                            l_nCountProposed     := ListOfColumnCounts->CountProposed
                            l_nCount             := ListOfColumnCounts->Count
                            l_nCountDiscontinued := ListOfColumnCounts->CountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif

                        if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListColumns/]+l_cCombinedPath+;
                                                                                            l_cColumnSearchParameters+[]+;
                                                                                            [">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                        endif

                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        if el_seek(l_iTablePk,"ListOfIndexCounts","tag1")
                            l_nCountProposed     := ListOfIndexCounts->CountProposed
                            l_nCount             := ListOfIndexCounts->Count
                            l_nCountDiscontinued := ListOfIndexCounts->CountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListIndexes/]+l_cCombinedPath+[">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                    l_cHtml += [</td>]

                    if l_nNumberOfTags > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cTagsInfo := []
                            select ListOfTagTables
                            scan all for ListOfTagTables->fk_entity = l_iTablePk
                                if !empty(l_cTagsInfo)
                                    l_cTagsInfo += [<br>]
                                endif
                                l_cTagsInfo += [<span style="white-space:nowrap;">]+TextToHtml(ListOfTagTables->Tag_Name+[ (]+ListOfTagTables->Tag_Code+[)])+[</span>]
                            endscan
                            l_cHtml += l_cTagsInfo
                        l_cHtml += [</td>]
                    endif

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(ListOfTables->Table_Unlogged,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfTables->Table_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(len(nvl(ListOfTables->Table_Information,"")) > 0,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfTables->Table_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfTables->Table_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfTables->Table_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfTables->Table_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        if el_seek(l_iTablePk,"ListOfReferencedByCounts","tag1")
                            l_nCountProposed     := ListOfReferencedByCounts->CountProposed
                            l_nCount             := ListOfReferencedByCounts->Count
                            l_nCountDiscontinued := ListOfReferencedByCounts->CountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/TableReferencedBy/]+l_cCombinedPath+l_cColumnSearchParameters+[">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_nCount := iif( el_seek(l_iTablePk,"ListOfDiagramsCounts","tag1") , ListOfDiagramsCounts->Count , 0)
                        l_nCount += l_nNumberOfDiagramsWithAllTables
                        if l_nCount > 0
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/TableDiagrams/]+l_cCombinedPath+l_cColumnSearchParameters+[">]+Trans(l_nCount)+[</a>]
                        endif
                    l_cHtml += [</td>]

                    if l_lHasExternalId
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="right">]
                            if nvl(ListOfTables->Table_ExternalId,0) > 0
                                l_cHtml += trans(ListOfTables->Table_ExternalId)
                            endif
                        l_cHtml += [</td>]
                    endif

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(l_iTablePk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif

                    if l_lWarnings
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfTables->Table_TestWarning,""))
                        l_cHtml += [</td>]
                    endif

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

// el_StrToFile(hb_jsonEncode(hb_orm_UsedWorkAreas(),.t.),el_AddPs(OUTPUT_FOLDER)+"WorkAreas_"+GetZuluTimeStampForFileNameSuffix()+"_TableListFormBuild.txt")

return l_cHtml
//=================================================================================================================
static function TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_iTemplateTablePk  := nvl(hb_HGetDef(par_hValues,"TemplateTablePk",0),0)
local l_iNamespacePk      := hb_HGetDef(par_hValues,"Fk_Namespace",0)
local l_cName             := hb_HGetDef(par_hValues,"Name","")
local l_lTrackNameChanges := nvl(hb_HGetDef(par_hValues,"TrackNameChanges",.t.),.t.)
local l_cAKA              := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cTags             := nvl(hb_HGetDef(par_hValues,"Tags",""),"")
local l_lUnlogged         := hb_HGetDef(par_hValues,"Unlogged",.f.)
local l_nUseStatus        := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus        := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription      := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cInformation      := nvl(hb_HGetDef(par_hValues,"Information",""),"")
local l_iExternalId       := nvl(hb_HGetDef(par_hValues,"ExternalId",0),0)

local l_cSitePath        := oFcgi:p_cSitePath

local l_oDB1                     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTemplateTables := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDataTableInfo
local l_ScriptFolder
local l_json_Tags
local l_cTagInfo
local l_nNumberOfTags
local l_nNumberOfTemplateTables
local l_cCombinedPath
local l_oDataApplication
local l_lDisabled

oFcgi:TraceAdd("TableEditFormBuild")

l_ScriptFolder:= l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]

oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

with object l_oDB1
    :Table("44acedf3-e37d-4c57-abbc-249e9f2382d7","Application")
    :Column("Application.NoNamespaceChangeOnTablesAndEnumerations","Application_NoNamespaceChangeOnTablesAndEnumerations")
    l_oDataApplication := :Get(par_iApplicationPk)
endwith

with object l_oDB_ListOfTemplateTables
    :Table("db61f74a-6945-4758-bdb9-5299956cce40","TemplateTable")
    :Column("TemplateTable.pk"  ,"pk")
    :Column("TemplateTable.Name","TemplateTable_Name")
    :Column("upper(TemplateTable.Name)","tag1")
    :OrderBy("tag1")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfTemplateTables")
    l_nNumberOfTemplateTables := :Tally
endwith

l_json_Tags := []
with object l_oDB_ListOfTags
    :Table("baf9f132-b515-41be-b809-def45b61f7d0","Tag")
    :Column("Tag.pk"   , "pk")
    :Column("Tag.Name" , "Tag_Name")
    :Column("upper(Tag.Name)" , "tag1")
    :Column("Tag.Code" , "Tag_Code")
    :Where("Tag.fk_Application = ^" , par_iApplicationPk)
    :Where("Tag.TableUseStatus = ^",TAGUSESTATUS_ACTIVE)
    :OrderBy("Tag1")
    :SQL("ListOfTags")
    l_nNumberOfTags := :Tally

    if l_nNumberOfTags > 0
        select ListOfTags
        scan all
            if !empty(l_json_Tags)
                l_json_Tags += [,]
            endif
            l_cTagInfo := ListOfTags->Tag_Name+[ (]+ListOfTags->Tag_Code+[)]
            l_json_Tags += "{tag:'"+TextToHTML(l_cTagInfo)+"',value:"+trans(ListOfTags->pk)+"}"
        endscan

        oFcgi:p_cjQueryScript += [$("#TextTags").amsifySuggestags({]+;
                                                                "suggestions :["+l_json_Tags+"],"+;
                                                                "whiteList: true,"+;
                                                                "tagLimit: 10,"+;
                                                                "selectOnHover: true,"+;
                                                                "showAllSuggestions: true,"+;
                                                                "keepLastOnHoverTag: false,"+;
                                                                "afterAdd: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }},"+;
                                                                "afterRemove: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }}"+;
                                                                [});]

    endif
endwith

oFcgi:p_cjQueryScript += "$('#PageLoaded').val('1');"

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 300px;} ]
l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
l_cHtml += [</style>]

with object l_oDB1
    if !empty(par_iPk)
        :Table("96de9645-1c36-4414-bd84-1b94e600927d","Table")
        :Column("Namespace.Name"   ,"Namespace_Name")
        :Column("Namespace.AKA"    ,"Namespace_AKA")
        :Column("Namespace.LinkUID","Namespace_LinkUID")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.AKA"        ,"Table_AKA")
        :Column("Table.LinkUID"    ,"Table_LinkUID")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        l_oDataTableInfo := :Get(par_iPk)
    endif

    :Table("46e97041-1a30-466a-93ed-2172c7dcfedd","Namespace")
    :Column("Namespace.pk"         ,"pk")
    :Column("Namespace.Name"       ,"Namespace_Name")
    :Column("Namespace.AKA"        ,"Namespace_AKA")
    :Column("Namespace.LinkUID"    ,"Namespace_LinkUID")
    :Column("Upper(Namespace.Name)","tag1")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNamespaces")

endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="PageLoaded" id="PageLoaded" value="0">]

if l_oDB1:Tally <= 0
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    l_cHtml += DisplayErrorMessageOnEditForm("You must setup at least one Namespace first")

    l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Table")
    
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += GetButtonOnEditForm("ButtonOk","Ok","Cancel")
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [</form>]

else
    l_cHtml += [<input type="hidden" name="formname" value="Edit">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

    l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

    if empty(par_iPk)
        l_cHtml += GetAboveNavbarHeading("New Table")
    else
        AssembleNavbarInfo("Add",{"Namespace",l_oDataTableInfo:Namespace_Name,l_oDataTableInfo:Namespace_AKA,l_oDataTableInfo:Namespace_LinkUID})
        AssembleNavbarInfo("Add",{"Table"    ,l_oDataTableInfo:Table_Name    ,l_oDataTableInfo:Table_AKA    ,l_oDataTableInfo:Table_LinkUID}    )

        l_cHtml += GetAboveNavbarHeading("Edit","Table",AssembleNavbarInfo("Build"))

        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                           PrepareForURLSQLIdentifier("Namespace",l_oDataTableInfo:Namespace_Name,l_oDataTableInfo:Namespace_LinkUID)+[/]+;
                           PrepareForURLSQLIdentifier("Table"    ,l_oDataTableInfo:Table_Name    ,l_oDataTableInfo:Table_LinkUID)    +[/]

    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
            l_cHtml += GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,"EditTable")
            if !empty(par_iPk)
                l_cHtml += GetTableExtendedButtonRelatedOnEditForm("Edit",par_iPk,l_cCombinedPath)
            endif
        l_cHtml += [</div><div class="input-group">]
            if oFcgi:p_nAccessLevelDD >= 3
                l_cHtml += GetButtonOnEditFormSave()
            endif
            l_cHtml += GetButtonOnEditFormDoneCancel()
            if !empty(par_iPk)
                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += GetButtonOnEditFormDelete()
                    l_cHtml += GetConfirmationModalFormsDelete()

                    l_cHtml += GetButtonOnEditFormDuplicate()
                    l_cHtml += GetConfirmationModalFormsDuplicate("Every Columns and Indexes will also be duplicated")

                endif
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    if !empty(par_iPk)
        l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
    endif

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]

        l_cHtml += [<table>]

            if !empty(par_iPk) .and. l_oDataApplication:Application_NoNamespaceChangeOnTablesAndEnumerations
                l_lDisabled := .t.
            else
                l_lDisabled := oFcgi:p_nAccessLevelDD < 5
            endif
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Namespace</td>]
                l_cHtml += [<td class="pb-3">]
                    //Disabled Combo will not pass their selected item during a Post
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+iif(l_lDisabled,[ disabled],[ name="ComboNamespacePk" id="ComboNamespacePk"])+[ class="form-select">]
                    select ListOfNamespaces
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfNamespaces->pk)+["]+iif(ListOfNamespaces->pk = l_iNamespacePk,[ selected],[])+[>]+FcgiPrepFieldForValue(ListOfNamespaces->Namespace_Name+FormatAKAForDisplay(ListOfNamespaces->Namespace_AKA))+[</option>]
                    endscan
                    l_cHtml += [</select>]
                    if l_lDisabled
                        l_cHtml += [<input type="hidden" name="ComboNamespacePk" id="ComboNamespacePk" value="]+Trans(l_iNamespacePk)+[">]
                    endif
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Table Name</td>]
                l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control"></td>]
            l_cHtml += [</tr>]

            l_cHtml += GetTrackNameChangesAndPreviousNamesEditFormBuild(l_lTrackNameChanges,"Table",par_iPk)

            if par_iPk == 0 .and. l_nNumberOfTemplateTables > 0
                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Template Table</td>]
                    l_cHtml += [<td class="pb-3">]
                        l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboTemplateTablePk" id="ComboTemplateTablePk"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-select">]
                            l_cHtml += [<option value="0"]+iif(l_iTemplateTablePk==0,[ selected],[])+[></option>]
                            // l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                            // l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                            // l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                            select ListOfTemplateTables
                            scan all
                                l_cHtml += [<option value="]+trans(ListOfTemplateTables->pk)+["]+iif(l_iTemplateTablePk==ListOfTemplateTables->pk,[ selected],[])+[>]+FcgiPrepFieldForValue(ListOfTemplateTables->TemplateTable_Name)+[</option>]
                            endscan
                        l_cHtml += [</select>]
                    l_cHtml += [</td>]
                l_cHtml += [</tr>]
            endif

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
                l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control"></td>]
            l_cHtml += [</tr>]

            if l_nNumberOfTags > 0
                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Tags</td>]
                    l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextTags" id="TextTags" value="]+FcgiPrepFieldForValue(l_cTags)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control" placeholder=""></td>]
                l_cHtml += [</tr>]
            endif

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Unlogged</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += GetCheckboxOnEditForm("CheckUnlogged",l_lUnlogged,"(PostgreSQL Only)",,(oFcgi:p_nAccessLevelDD < 5))
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-select">]
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
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-select">]
                        l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                        l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                        l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                        l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr>]
                l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
                l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr>]
                l_cHtml += [<td valign="top" class="pe-2 pb-3">Information<br><span class="small">Engineering Notes</span><br>]
                l_cHtml += [<a href="https://marked.js.org/" target="_blank"><span class="small">Markdown</span></a>]
                l_cHtml += [</td>]
                l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextInformation" id="TextInformation" rows="10" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cInformation)+[</textarea></td>]
            l_cHtml += [</tr>]

            if !empty(l_iExternalId)
                l_cHtml += [<tr>]
                    l_cHtml += [<td valign="top" class="pe-2 pb-3">External Id</td>]
                    l_cHtml += [<td class="pb-3">]+trans(l_iExternalId)+[ (Created via API call)</td>]
                l_cHtml += [</tr>]
            endif

            l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_TABLE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

        l_cHtml += [</table>]

        l_cHtml += [<input type="hidden" name="TextExternalId" id="TextExternalId" value="]+trans(l_iExternalId)+[">]
        
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextName').focus();]

    oFcgi:p_cjQueryScript += [$('#TextInformation').resizable();]

    l_cHtml += [</form>]

endif

return l_cHtml
//=================================================================================================================
static function TableEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTablePk
local l_iTemplateTablePk
local l_iNamespacePk
local l_cTableName
local l_lTableTrackNameChanges
local l_cTableAKA
local l_lUnlogged
local l_nTableUseStatus
local l_nTableDocStatus
local l_cTableDescription
local l_cTableInformation
local l_iTableExternalId
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDBListOfTemplateColumns

local l_oDBListOfTagsOnFile
local l_cListOfTagPks
local l_nNumberOfTagTableOnFile
local l_hTagTableOnFile := {=>}
local l_aTagsSelected
local l_cTagSelected
local l_iTagSelectedPk
local l_iTagTablePk
local l_cLinkUID
local l_cName
local l_nPos
local l_oDB_ListOfColumns
local l_oDB_ListOfIndexes
local l_oDB_ListOfIndexColumns
local l_lDuplicate

local l_hMappingIndex  := {=>}
local l_hMappingColumn := {=>}

oFcgi:TraceAdd("TableEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTablePk          := Val(oFcgi:GetInputValue("TableKey"))

l_iTemplateTablePk  := Val(oFcgi:GetInputValue("ComboTemplateTablePk"))
l_iNamespacePk      := Val(oFcgi:GetInputValue("ComboNamespacePk"))

l_cTableName             := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_lTableTrackNameChanges := (oFcgi:GetInputValue("CheckTrackNameChanges") == "1")
l_cTableAKA              := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cTableAKA)
    l_cTableAKA := NIL
endif
l_lUnlogged              := (oFcgi:GetInputValue("CheckUnlogged") == "1")
l_nTableUseStatus        := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nTableDocStatus        := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cTableDescription      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_cTableInformation      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextInformation")))
l_iTableExternalId       := Val(oFcgi:GetInputValue("TextExternalId"))

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
                :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
                :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                :Where([Table.fk_Namespace = ^],l_iNamespacePk)
                :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cTableName," ","")))
                if l_iTablePk > 0
                    :Where([Table.pk != ^],l_iTablePk)
                endif
                :SQL()
                l_lDuplicate := (:Tally <> 0)

                if !l_lDuplicate
                    :Table("06dd1b61-b456-413c-ad02-7b62133d05a9","Table")
                    :Column("Table.pk","pk")
                    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
                    :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                    :Where([Table.fk_Namespace = ^],l_iNamespacePk)
                    :Where([lower(replace(TablePreviousName.Name,' ','')) = ^],lower(StrTran(l_cTableName," ","")))
                    :Join("inner","TablePreviousName","","TablePreviousName.fk_Table = Table.pk")
                    if l_iTablePk > 0
                        :Where([Table.pk != ^],l_iTablePk)
                    endif
                    :SQL()
                    // SendToClipboard(:LastSQL())
                    l_lDuplicate := (:Tally <> 0)
                endif
            endwith

            if l_lDuplicate
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Table
        with object l_oDB1
            l_cErrorMessage := TrackNameChange(l_oDB1,"Table",l_iTablePk,l_cTableName,l_lTableTrackNameChanges)
            if empty(l_cErrorMessage)
                RemovePreviousNameIfSelectedEditFormOnSubmit("Table",l_iTablePk)

                :Table("895da8f1-8cdb-4792-a5b9-3d3b6e646430","Table")
                if oFcgi:p_nAccessLevelDD >= 5
                    if l_iNamespacePk > 0   // Needed in case of disabled Namespace dropdown
                        :Field("Table.fk_Namespace",l_iNamespacePk)
                    endif
                    :Field("Table.Name"            ,l_cTableName)
                    :Field("Table.TrackNameChanges",l_lTableTrackNameChanges)
                    :Field("Table.AKA"             ,l_cTableAKA)
                    :Field("Table.UseStatus"       ,l_nTableUseStatus)
                    :Field("Table.Unlogged"        ,l_lUnlogged)
                endif
                :Field("Table.DocStatus"   ,l_nTableDocStatus)
                :Field("Table.Description" ,iif(empty(l_cTableDescription),NULL,l_cTableDescription))
                :Field("Table.Information" ,iif(empty(l_cTableInformation),NULL,l_cTableInformation))
                if empty(l_iTablePk)
                    :Field("Table.LinkUID",oFcgi:p_o_SQLConnection:GetUUIDString())
                    if :Add()
                        l_iTablePk := :Key()
                    else
                        l_cErrorMessage := "Failed to add Table."
                    endif
                else
                    if !:Update(l_iTablePk)
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
                        :Column("TagTable.fk_Tag"  , "TagTable_fk_Tag")
                        :Where("TagTable.fk_Table = ^" , l_iTablePk)

                        :Join("inner","Tag","","TagTable.fk_Tag = Tag.pk")
                        :Where("Tag.fk_Application = ^",par_iApplicationPk)
                        :Where("Tag.TableUseStatus = ^",TAGUSESTATUS_ACTIVE)
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
                                    :Field("TagTable.fk_Tag"   ,l_iTagSelectedPk)
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

                    if l_iTemplateTablePk > 0  // Use a TemplateTable to add initial columns
                        l_oDBListOfTemplateColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
                        with object l_oDBListOfTemplateColumns
                            :Table("f2d217df-edfa-452b-850b-f555a401a570","TemplateColumn")

                            :Column("TemplateColumn.Order"              , "TemplateColumn_Order")
                            :Column("TemplateColumn.Name"               , "TemplateColumn_Name")
                            :Column("TemplateColumn.AKA"                , "TemplateColumn_AKA")
                            :Column("TemplateColumn.UsedAs"             , "TemplateColumn_UsedAs")
                            :Column("TemplateColumn.UsedBy"             , "TemplateColumn_UsedBy")
                            :Column("TemplateColumn.UseStatus"          , "TemplateColumn_UseStatus")
                            :Column("TemplateColumn.DocStatus"          , "TemplateColumn_DocStatus")
                            :Column("TemplateColumn.Type"               , "TemplateColumn_Type")
                            :Column("TemplateColumn.Array"              , "TemplateColumn_Array")
                            :Column("TemplateColumn.Length"             , "TemplateColumn_Length")
                            :Column("TemplateColumn.Scale"              , "TemplateColumn_Scale")
                            :Column("TemplateColumn.Nullable"           , "TemplateColumn_Nullable")
                            :Column("TemplateColumn.DefaultType"        , "TemplateColumn_DefaultType")
                            :Column("TemplateColumn.DefaultCustom"      , "TemplateColumn_DefaultCustom")
                            :Column("TemplateColumn.Unicode"            , "TemplateColumn_Unicode")
                            :Column("TemplateColumn.Description"        , "TemplateColumn_Description")

                            :Where("TemplateColumn.fk_TemplateTable = ^" , l_iTemplateTablePk)
                            :OrderBy("TemplateColumn_Order")
                            :SQL("ListOfTemplateColumns")

                            if :Tally > 0
                                with object l_oDB1
                                    select ListOfTemplateColumns
                                    scan all
                                        :Table("ab1b0120-bb64-4cfb-b6bc-e6a740594915","Column")
                                        :Field("Column.fk_Table"     ,l_iTablePk)
                                        :Field("Column.LinkUID"      ,oFcgi:p_o_SQLConnection:GetUUIDString())
                                        :Field("Column.Order"        ,ListOfTemplateColumns->TemplateColumn_Order)
                                        :Field("Column.Name"         ,ListOfTemplateColumns->TemplateColumn_Name)
                                        :Field("Column.AKA"          ,ListOfTemplateColumns->TemplateColumn_AKA)
                                        :Field("Column.UsedAs"       ,ListOfTemplateColumns->TemplateColumn_UsedAs)
                                        :Field("Column.UsedBy"       ,ListOfTemplateColumns->TemplateColumn_UsedBy)
                                        :Field("Column.UseStatus"    ,ListOfTemplateColumns->TemplateColumn_UseStatus)
                                        :Field("Column.DocStatus"    ,ListOfTemplateColumns->TemplateColumn_DocStatus)
                                        :Field("Column.Type"         ,ListOfTemplateColumns->TemplateColumn_Type)
                                        :Field("Column.Array"        ,ListOfTemplateColumns->TemplateColumn_Array)
                                        :Field("Column.Length"       ,ListOfTemplateColumns->TemplateColumn_Length)
                                        :Field("Column.Scale"        ,ListOfTemplateColumns->TemplateColumn_Scale)
                                        :Field("Column.Nullable"     ,ListOfTemplateColumns->TemplateColumn_Nullable)
                                        :Field("Column.DefaultType"  ,ListOfTemplateColumns->TemplateColumn_DefaultType)
                                        :Field("Column.DefaultCustom",ListOfTemplateColumns->TemplateColumn_DefaultCustom)
                                        :Field("Column.Unicode"      ,ListOfTemplateColumns->TemplateColumn_Unicode)
                                        :Field("Column.Description"  ,iif(empty(ListOfTemplateColumns->TemplateColumn_Description),NULL,ListOfTemplateColumns->TemplateColumn_Description))
                                        :Add()
                                    endscan
                                endwith
                            endif
                        endwith
                    endif

                endif
            endif
        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iTablePk := 0

case l_cActionOnSubmit == "Delete"   // Table
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveTableDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteTable(par_iApplicationPk,l_iTablePk)
            if empty(l_cErrorMessage)
                l_iTablePk := 0
            endif
        else
            with object l_oDB1
                :Table("c0dabef1-454d-4665-8cac-cc42192cdc6c","Column")
                :Where("Column.fk_Table = ^",l_iTablePk)
                :SQL()

                if :Tally == 0
                    :Table("9a98d575-76ce-4da4-8b8b-13a0e6f67f6b","Column")
                    :Where("Column.fk_TableForeign = ^",l_iTablePk)
                    :SQL()

                    if :Tally == 0
                        
                        //Delete IndexColumn related records 
                        :Table("129123ac-08bb-459b-b946-88fb92f67d32","Index")
                        :Column("IndexColumn.pk","pk")
                        :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
                        :Where("Index.fk_Table = ^",l_iTablePk)
                        :SQL("ListOfRecordsToDelete")
                        if :Tally > 0
                            select ListOfRecordsToDelete
                            scan all
                                if !:Delete("629ff66c-ea5e-4737-9d5a-ee70317dbc4a","IndexColumn",ListOfRecordsToDelete->pk)
                                    l_cErrorMessage := "Failed to delete IndexColumn."
                                    exit
                                endif
                            endscan
                        endif

                        :Table("c928f496-9e84-43f6-a1fb-99d2191f528e","Index")
                        :Column("Index.pk","pk")
                        :Where("Index.fk_Table = ^" , l_iTablePk)
                        :SQL("ListOfRecordsToDelete")
                        if :Tally < 0
                            l_cErrorMessage := "Failed to delete Table. Error 3."
                        else
                            select ListOfRecordsToDelete
                            scan all
                                if !:Delete("a6d54bb0-fd92-4ac4-b466-24780cacd93e","Index",ListOfRecordsToDelete->pk)
                                    l_cErrorMessage := "Failed to delete Index."
                                    exit
                                endif
                            endscan
                        endif

                        if empty(l_cErrorMessage)
                            //Delete any DiagramTable related records
                            :Table("3c006261-26e5-4e1a-9164-278f5bd4e31a","DiagramTable")
                            :Column("DiagramTable.pk" , "pk")
                            :Where("DiagramTable.fk_Table = ^",l_iTablePk)
                            :SQL("ListOfDiagramTableRecordsToDelete")
                            if :Tally >= 0
                                if :Tally > 0
                                    select ListOfDiagramTableRecordsToDelete
                                    scan
                                        :Delete("e1d662cd-cbad-4402-96f6-c387aaf6077b","DiagramTable",ListOfDiagramTableRecordsToDelete->pk)
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
                                            :Delete("a9c2e2d2-e7ec-4345-9307-4033d7bb4fb3","TagTable",ListOfTagTableRecordsToDelete->pk)
                                        endscan
                                    endif

                                    CustomFieldsDelete(par_iApplicationPk,USEDON_TABLE,l_iTablePk)
                                    if :Delete("dd06ea56-67f7-4175-ad06-4b0f302c402a","Table",l_iTablePk)
                                        DataDictionaryFixAndTest(par_iApplicationPk)
                                        l_iTablePk := 0
                                    else
                                        l_cErrorMessage := "Failed to delete Table"
                                    endif

                                else
                                    l_cErrorMessage := "Failed to clear related TagTable records."
                                endif

                            else
                                l_cErrorMessage := "Failed to clear related DiagramTable records."
                            endif
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
    if empty(l_cErrorMessage)
        l_iTablePk := 0
    endif

case l_cActionOnSubmit == "Duplicate"   // Table
    if oFcgi:p_nAccessLevelDD >= 5 .and. l_iTablePk > 0

        l_oDB_ListOfColumns      := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB_ListOfIndexes      := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB_ListOfIndexColumns := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB_ListOfColumns
            :Table("8491ca8a-33cf-487c-9c1b-77ff9b9affef","Column")
            :Where("Column.fk_Table = ^",l_iTablePk)

            :Column("Column.Pk"                ,"Pk")
            :Column("Column.fk_TableForeign"   ,"Column_fk_TableForeign")
            :Column("Column.fk_Enumeration"    ,"Column_fk_Enumeration")
            :Column("Column.Order"             ,"Column_Order")
            // :Column("Column.LinkUID"           ,"Column_LinkUID")
            :Column("Column.Name"              ,"Column_Name")
            :Column("Column.TrackNameChanges"  ,"Column_TrackNameChanges")
            :Column("Column.AKA"               ,"Column_AKA")
            :Column("Column.UsedAs"            ,"Column_UsedAs")
            :Column("Column.UsedBy"            ,"Column_UsedBy")
            :Column("Column.UseStatus"         ,"Column_UseStatus")
            :Column("Column.DocStatus"         ,"Column_DocStatus")
            :Column("Column.Type"              ,"Column_Type")
            :Column("Column.Array"             ,"Column_Array")
            :Column("Column.Length"            ,"Column_Length")
            :Column("Column.Scale"             ,"Column_Scale")
            :Column("Column.Nullable"          ,"Column_Nullable")
            :Column("Column.DefaultType"       ,"Column_DefaultType")
            :Column("Column.DefaultCustom"     ,"Column_DefaultCustom")
            :Column("Column.ForeignKeyUse"     ,"Column_ForeignKeyUse")
            :Column("Column.ForeignKeyOptional","Column_ForeignKeyOptional")
            :Column("Column.OnDelete"          ,"Column_OnDelete")
            :Column("Column.Unicode"           ,"Column_Unicode")
            :Column("Column.Description"       ,"Column_Description")
            // :Column("Column.TestWarning"       ,"Column_TestWarning")
            // :Column("Column.LastNativeType"    ,"Column_LastNativeType")

            :SQL("ListOfColumns")
        endwith

        with object l_oDB_ListOfIndexes
            :Table("5d7ddbdb-8eda-4bbb-9a61-90b23a270a82","Index")
            :Where("Index.fk_Table = ^",l_iTablePk)

            // :Column("Index.LinkUID"    ,"Index_LinkUID")
            :Column("Index.Pk"         ,"Pk")
            :Column("Index.Name"       ,"Index_Name")
            :Column("Index.Unique"     ,"Index_Unique")
            :Column("Index.Expression" ,"Index_Expression")
            :Column("Index.Description","Index_Description")
            :Column("Index.Algo"       ,"Index_Algo")
            :Column("Index.UsedBy"     ,"Index_UsedBy")
            :Column("Index.UseStatus"  ,"Index_UseStatus")
            :Column("Index.DocStatus"  ,"Index_DocStatus")
            // :Column("Index.TestWarning","Index_TestWarning")

            :SQL("ListOfIndexes")
        endwith

        with object l_oDB_ListOfIndexColumns
            :Table("5d7ddbdb-8eda-4bbb-9a61-90b23a270a83","Index")
            :Where("Index.fk_Table = ^",l_iTablePk)
            :Column("Index.Pk"              ,"Index_Pk")
            :Column("IndexColumn.fk_Column" ,"Column_Pk")
            :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
            :SQL("ListOfIndexColumns")
        endwith

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("3608cda1-4f7b-4230-ba03-68352d791fa5","Table")
            :Column("Table.fk_Namespace"    ,"Table_fk_Namespace")
            :Column("Table.LinkUID"         ,"Table_LinkUID")
            :Column("Table.Name"            ,"Table_Name")
            :Column("Table.TrackNameChanges","Table_TrackNameChanges")
            :Column("Table.UseStatus"       ,"Table_UseStatus")
            :Column("Table.DocStatus"       ,"Table_DocStatus")
            :Column("Table.Description"     ,"Table_Description")
            :Column("Table.Information"     ,"Table_Information")
            :Column("Table.Unlogged"        ,"Table_Unlogged")
            l_oData := :Get(l_iTablePk)

            if !hb_IsNil(l_oData)
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                l_cName := OnDuplicateSanitizeName(l_oData:Table_Name,l_cLinkUID,l_oData:Table_LinkUID)
                
                :Table("00b39c52-09d8-4132-9c17-2402267cfd1e","Table")
                :Field("Table.fk_Namespace"    ,l_oData:Table_fk_Namespace)
                :Field("Table.Name"            ,l_cName)
                :Field("Table.LinkUID"         ,l_cLinkUID)
                :Field("Table.TrackNameChanges",l_oData:Table_TrackNameChanges)
                :Field("Table.UseStatus"       ,l_oData:Table_UseStatus)
                :Field("Table.DocStatus"       ,l_oData:Table_DocStatus)
                :Field("Table.Description"     ,l_oData:Table_Description)
                :Field("Table.Information"     ,l_oData:Table_Information)
                :Field("Table.Unlogged"        ,l_oData:Table_Unlogged)
                if :Add()
                    l_iTablePk := :Key()

                    // Duplicate Column
                    select ListOfColumns
                    scan all
                        :Table("e8ca18b3-e4a3-4c4c-bc12-dff9fa9b3f84","Column")
                        :Field("Column.fk_Table"           ,l_iTablePk)
                        :Field("Column.LinkUID"            ,oFcgi:p_o_SQLConnection:GetUUIDString())
                        :Field("Column.fk_TableForeign"   ,ListOfColumns->Column_fk_TableForeign)
                        :Field("Column.fk_Enumeration"    ,ListOfColumns->Column_fk_Enumeration)
                        :Field("Column.Order"             ,ListOfColumns->Column_Order)
                        :Field("Column.Name"              ,ListOfColumns->Column_Name)
                        :Field("Column.TrackNameChanges"  ,ListOfColumns->Column_TrackNameChanges)
                        :Field("Column.AKA"               ,ListOfColumns->Column_AKA)
                        :Field("Column.UsedAs"            ,ListOfColumns->Column_UsedAs)
                        :Field("Column.UsedBy"            ,ListOfColumns->Column_UsedBy)
                        :Field("Column.UseStatus"         ,ListOfColumns->Column_UseStatus)
                        :Field("Column.DocStatus"         ,ListOfColumns->Column_DocStatus)
                        :Field("Column.Type"              ,ListOfColumns->Column_Type)
                        :Field("Column.Array"             ,ListOfColumns->Column_Array)
                        :Field("Column.Length"            ,ListOfColumns->Column_Length)
                        :Field("Column.Scale"             ,ListOfColumns->Column_Scale)
                        :Field("Column.Nullable"          ,ListOfColumns->Column_Nullable)
                        :Field("Column.DefaultType"       ,ListOfColumns->Column_DefaultType)
                        :Field("Column.DefaultCustom"     ,ListOfColumns->Column_DefaultCustom)
                        :Field("Column.ForeignKeyUse"     ,ListOfColumns->Column_ForeignKeyUse)
                        :Field("Column.ForeignKeyOptional",ListOfColumns->Column_ForeignKeyOptional)
                        :Field("Column.OnDelete"          ,ListOfColumns->Column_OnDelete)
                        :Field("Column.Unicode"           ,ListOfColumns->Column_Unicode)
                        :Field("Column.Description"       ,ListOfColumns->Column_Description)
                        if :Add()
                            l_hMappingColumn[ListOfColumns->Pk] := :Key()
                        else
                            l_cErrorMessage := "Failed to add Column in Table."
                            exit
                        endif
                    endscan

                    // Duplicate Indexes
                    select ListOfIndexes
                    scan all
                        :Table("e8ca18b3-e4a3-4c4c-bc12-dff9fa9b3f84","Index")
                        :Field("Index.fk_Table"   ,l_iTablePk)
                        :Field("Index.LinkUID"    ,oFcgi:p_o_SQLConnection:GetUUIDString())
                        :Field("Index.Name"       ,ListOfIndexes->Index_Name)
                        :Field("Index.Unique"     ,ListOfIndexes->Index_Unique)
                        :Field("Index.Expression" ,ListOfIndexes->Index_Expression)
                        :Field("Index.Description",ListOfIndexes->Index_Description)
                        :Field("Index.Algo"       ,ListOfIndexes->Index_Algo)
                        :Field("Index.UsedBy"     ,ListOfIndexes->Index_UsedBy)
                        :Field("Index.UseStatus"  ,ListOfIndexes->Index_UseStatus)
                        :Field("Index.DocStatus"  ,ListOfIndexes->Index_DocStatus)
                        if :Add()
                            l_hMappingIndex[ListOfIndexes->Pk] := :Key()
                        else
                            l_cErrorMessage := "Failed to add Index in Table."
                            exit
                        endif
                    endscan

                    // Duplicate IndexColumn
                    select ListOfIndexColumns
                    scan all
                        :Table("abed2f11-7b99-42f5-aff6-43ff8409c4a9","IndexColumn")
                        :Field("IndexColumn.fk_Index"  , l_hMappingIndex[ListOfIndexColumns->Index_Pk])
                        :Field("IndexColumn.fk_Column" , l_hMappingColumn[ListOfIndexColumns->Column_Pk])
                        if !:Add()
                            l_cErrorMessage := "Failed to add IndexColumn in Index."
                            exit
                        endif
                    endscan

                else
                    l_cErrorMessage := "Failed to add Table."
                endif
            endif

        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    else
        l_cErrorMessage := "No Access to Duplicate"
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["TemplateTablePk"] := l_iTemplateTablePk
    l_hValues["Fk_Namespace"]    := l_iNamespacePk
    l_hValues["Name"]            := l_cTableName
    l_hValues["AKA"]             := l_cTableAKA
    l_hValues["UseStatus"]       := l_nTableUseStatus
    l_hValues["DocStatus"]       := l_nTableDocStatus
    l_hValues["Description"]     := l_cTableDescription
    l_hValues["Information"]     := l_cTableInformation
    l_hValues["ExternalId"]      := l_iTableExternalId

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_TABLE,@l_hValues)

    l_cHtml += TableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iTablePk,l_hValues)

case empty(l_iTablePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")

otherwise
    with object l_oDB1
        :Table("95c1f7a1-500d-4451-95bd-2c4d9df9114a","Table")
        :Column("Namespace.Name"   ,"Namespace_Name")
        :Column("Namespace.LinkUID","Namespace_LinkUID")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.LinkUID"    ,"Table_LinkUID")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        l_oData := :Get(l_iTablePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditTable/"+par_cURLApplicationLinkCode+"/"+;
                           PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+"/"+;
                           PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +"/";
                           )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ColumnListFormBuild(par_iApplicationPk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB_Application        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumns      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumValues   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPreviousName := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfColumns := 0
local l_nNumberOfColumnsInSearch := 0
local l_nNumberOfCustomFieldValues := 0
local l_iColumnPk
local l_oData_Application
local l_cApplicationSupportColumns

local l_hOptionValueToDescriptionMapping := {=>}

local l_cSearchColumnName
local l_cSearchColumnDescription
local l_cSearchColumnStaticUID

local l_cTooltipEnumValues
local l_cURL
local l_cName
local l_nColspan

local l_lHasExternalId :=.f.
local l_lWarnings := .f.

local l_cCombinedPath

local l_cLine
local l_nMaxWidth
local l_lExtraInfo


oFcgi:TraceAdd("ColumnListFormBuild")

if oFcgi:isGet() //.and. (len(oFcgi:p_URLPathElements) >= 6 .and. !empty(oFcgi:p_URLPathElements[6]) .and. lower(oFcgi:p_URLPathElements[6]) == "search")  //First access to column list coming from list of tables where the last search included column criteria.
                 //Decided to always start the search with whatever the table list last search was.
    l_cSearchColumnName        := hb_HexToStr(oFcgi:GetQueryString("ColumnName"))
    l_cSearchColumnDescription := hb_HexToStr(oFcgi:GetQueryString("ColumnDescription"))
    l_cSearchColumnStaticUID   := hb_HexToStr(oFcgi:GetQueryString("ColumnStaticUID"))
else
    l_cSearchColumnName        := GetUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName")
    l_cSearchColumnDescription := GetUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription")
    l_cSearchColumnStaticUID   := GetUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnStaticUID")
endif

with object l_oDB_Application
    :Table("526421bf-2c80-465b-b858-8b485d1a20d0","Application")
    :Column("Application.SupportColumns" , "Application_SupportColumns")
    l_oData_Application := :Get(par_iApplicationPk)
    l_cApplicationSupportColumns := nvl(l_oData_Application:Application_SupportColumns,"")
endwith

with object l_oDB_ListOfColumns
    :Table("ff3cdf85-7085-4999-a2ea-c4c33e8a5520","Column")
    :Where("Column.fk_Table = ^",par_iTablePk)
    l_nNumberOfColumns := :Count()

    :Table("27682ad7-bafd-409f-b6ab-1057770ec119","Column")
    :Column("Column.pk"                  ,"pk")
    :Column("Column.Name"                ,"Column_Name")
    :Column("Column.StaticUID"           ,"Column_StaticUID")
    :Column("Column.AKA"                 ,"Column_AKA")
    :Column("Column.LinkUID"             ,"Column_LinkUID")
    :Column("Column.UsedAs"              ,"Column_UsedAs")
    :Column("Column.UsedBy"              ,"Column_UsedBy")
    :Column("Column.UseStatus"           ,"Column_UseStatus")
    :Column("Column.DocStatus"           ,"Column_DocStatus")
    :Column("Column.Description"         ,"Column_Description")
    :Column("Column.Order"               ,"Column_Order")
    :Column("Column.Type"                ,"Column_Type")
    :Column("Column.Array"               ,"Column_Array")
    :Column("Column.Length"              ,"Column_Length")
    :Column("Column.Scale"               ,"Column_Scale")
    :Column("Column.Nullable"            ,"Column_Nullable")
    :Column("Column.OnDelete"            ,"Column_OnDelete")
    :Column("Column.DefaultType"         ,"Column_DefaultType")
    :Column("Column.DefaultCustom"       ,"Column_DefaultCustom")
    :Column("Column.Unicode"             ,"Column_Unicode")
    :Column("Column.fk_TableForeign"     ,"Column_fk_TableForeign")
    :Column("Column.ForeignKeyUse"       ,"Column_ForeignKeyUse")
    :Column("Column.ForeignKeyOptional"  ,"Column_ForeignKeyOptional")
    :Column("Column.fk_Enumeration"      ,"Column_fk_Enumeration")
    :Column("Column.TestWarning"         ,"Column_TestWarning")
    :Column("Column.ExternalId"          ,"Column_ExternalId")
    :Column("Namespace.Name"             ,"Namespace_Name")
    :Column("Namespace.AKA"              ,"Namespace_AKA")
    :Column("Namespace.LinkUID"          ,"Namespace_LinkUID")
    :Column("Table.Name"                 ,"Table_Name")
    :Column("Table.AKA"                  ,"Table_AKA")
    :Column("Table.LinkUID"              ,"Table_LinkUID")
    :Column("Enumeration.Pk"             ,"Enumeration_Pk")
    :Column("Enumeration.Name"           ,"Enumeration_Name")
    :Column("Enumeration.AKA"            ,"Enumeration_AKA")
    :Column("Enumeration.LinkUID"        ,"Enumeration_LinkUID")
    :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")

    :Join("inner","Table"      ,"","Column.fk_Table = Table.pk")
    :Join("inner","Namespace"  ,"","Table.fk_Namespace = Namespace.pk")

    :Join("left","Table"      ,"ForeignTable"    ,"Column.fk_TableForeign = ForeignTable.pk")
    :Join("left","Namespace"  ,"ForeignNameSpace","ForeignTable.fk_Namespace = ForeignNameSpace.pk")

    :Join("left","Enumeration",""                    ,"Column.fk_Enumeration  = Enumeration.pk")
    :Join("left","Namespace"  ,"EnumerationNamespace","Enumeration.fk_Namespace = EnumerationNamespace.pk")

    :Column("ForeignNameSpace.Name"          ,"ForeignNameSpace_Name")
    :Column("ForeignNameSpace.AKA"           ,"ForeignNameSpace_AKA")
    :Column("ForeignNameSpace.LinkUID"       ,"ForeignNameSpace_LinkUID")

    :Column("ForeignTable.Name"              ,"ForeignTable_Name")
    :Column("ForeignTable.AKA"               ,"ForeignTable_AKA")
    :Column("ForeignTable.LinkUID"           ,"ForeignTable_LinkUID")

    :Column("EnumerationNamespace.Name"      ,"EnumerationNamespace_Name")
    :Column("EnumerationNamespace.AKA"       ,"EnumerationNamespace_AKA")
    :Column("EnumerationNamespace.LinkUID"   ,"EnumerationNamespace_LinkUID")

    :Where("Column.fk_Table = ^",par_iTablePk)

    if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnStaticUID) .or. !empty(l_cSearchColumnDescription)
        :Distinct(.t.)
        if !empty(l_cSearchColumnName)
            :Join("left","ColumnPreviousName","","ColumnPreviousName.fk_Column = Column.pk")
            :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA,' ',ColumnPreviousName.Name)")
        endif
        if !empty(l_cSearchColumnStaticUID)
            :Where("Column.StaticUID = ^",l_cSearchColumnStaticUID)
        endif
        if !empty(l_cSearchColumnDescription)
            :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
        endif
    endif
    :OrderBy("Column_Order")
    :SQL("ListOfColumns")
    l_nNumberOfColumnsInSearch := :Tally

// ExportTableToHtmlFile("ListOfColumns",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfColumns"+".html","From PostgreSQL",,,.t.)

endwith

if l_nNumberOfColumns > 0

    with object l_oDB_ListOfPreviousName
        :Table("708ff41e-877c-4218-9a9d-e4a809edf465","Column")
        :Column("Column.pk"  ,"pk")
        :Column("ColumnPreviousName.pk"  ,"PreviousName_pk")   //Will use the pk to order, since it is incremental
        :Column("ColumnPreviousName.Name","PreviousName_Name")
        :Join("inner","ColumnPreviousName","","ColumnPreviousName.fk_Column = Column.pk")
        :Where("Column.fk_Table = ^",par_iTablePk)
        :SQL("ListOfPreviousName")
        with object :p_oCursor
            :Index("tag1","alltrim(str(pk))+'*'+str(9999999999-PreviousName_pk,10)")
            :CreateIndexes()
        endwith
    endwith

    select ListOfColumns
    scan all while !l_lWarnings .or. !l_lHasExternalId
        if !empty(nvl(ListOfColumns->Column_TestWarning,""))
            l_lWarnings := .t.
        endif
        if nvl(ListOfColumns->Column_ExternalId,0) > 0
            l_lHasExternalId := .t.
        endif
    endscan

    with object l_oDB_ListOfEnumValues
        :Table("3784d627-8099-4966-b66e-d177304a3309","Column")
        :Column("Column.pk"            ,"Column_pk")

        :Column("EnumValue.Order"      ,"EnumValue_Order")
        :Column("EnumValue.Number"     ,"EnumValue_Number")
        :Column("EnumValue.Name"       ,"EnumValue_Name")
        :Column("EnumValue.AKA"        ,"EnumValue_AKA")
        :Column("EnumValue.Description","EnumValue_Description")
        :Column("EnumValue.UseStatus"  ,"EnumValue_UseStatus")
        
        :Join("inner","EnumValue","","Column.fk_Enumeration > 0 and Column.fk_Enumeration = EnumValue.fk_Enumeration")
        :Where("Column.fk_Table = ^",par_iTablePk)

        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnStaticUID) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnStaticUID)
                :Where("Column.StaticUID = ^",l_cSearchColumnStaticUID)
            endif
            if !empty(l_cSearchColumnDescription)
                :KeywordCondition(l_cSearchColumnDescription,"Column.Description")
            endif
        endif
        :OrderBy("Column_pk")
        :OrderBy("EnumValue_Order")
        :SQL("ListOfEnumValues")
        with object :p_oCursor
            :Index("tag1","alltrim(str(Column_pk))+'*'+str(EnumValue_Order,10)")
            :CreateIndexes()
        endwith
        // ExportTableToHtmlFile("ListOfEnumValues",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfEnumValues.html","From PostgreSQL",,25,.t.)

    endwith

    with object l_oDB_CustomField
        :Table("8f1aab3d-5f57-44c6-b58b-e2756afef2ed","Column")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Column.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Column.fk_Table = ^",par_iTablePk)
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnStaticUID) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnStaticUID)
                :Where("Column.StaticUID = ^",l_cSearchColumnStaticUID)
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
        if !empty(l_cSearchColumnName) .or. !empty(l_cSearchColumnStaticUID) .or. !empty(l_cSearchColumnDescription)
            :Distinct(.t.)
            if !empty(l_cSearchColumnName)
                :KeywordCondition(l_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(l_cSearchColumnStaticUID)
                :Where("Column.StaticUID = ^",l_cSearchColumnStaticUID)
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

l_cHtml += [<style>]
l_cHtml += [ .tooltip-inner {max-width: 700px;opacity: 1.0;background-color: #198754;} ]
l_cHtml += [ .tooltip.show {opacity:1.0} ]
l_cHtml += [</style>]

l_cHtml += GetCopyToClipboardJavaScript("CopyRoster")

l_cHtml += [<pre id="PreColumnsToClipboard" style="display:none;">]
    select ListOfColumns
    l_nMaxWidth  := 0
    l_lExtraInfo := .f.

    scan all
        l_nMaxWidth := max(l_nMaxWidth,len(ListOfColumns->Column_Name))
        if ListOfColumns->Column_UseStatus = USESTATUS_PROPOSED .or. ;
           ListOfColumns->Column_UseStatus = USESTATUS_DISCONTINUED
            l_lExtraInfo := .t.
        endif
    endscan

    scan all
        if !l_lExtraInfo
            l_cLine := ListOfColumns->Column_Name

        else
            l_cLine := padr(ListOfColumns->Column_Name,l_nMaxWidth)

            do case
            case ListOfColumns->Column_UseStatus = USESTATUS_PROPOSED
                l_cLine += [ (Proposed)]
            case ListOfColumns->Column_UseStatus = USESTATUS_DISCONTINUED
                l_cLine += [ (Discontinued)]
            endcase

        endif

        l_cHtml += l_cLine+CRLF
    endscan
l_cHtml += [</pre>]

// ExportTableToHtmlFile("ListOfCustomFieldValues",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfCustomFieldValues.html","From PostgreSQL",,25,.t.)

AssembleNavbarInfo("Add",{"Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_AKA,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_AKA    ,par_oNavData:Table_LinkUID})

l_cHtml += GetAboveNavbarHeading("Columns","Table",AssembleNavbarInfo("Build"))

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+[/]+;
                   PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +[/]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
        l_cHtml += GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTablePk,"ListColumns")
        l_cHtml += GetTableExtendedButtonRelatedOnEditForm("Column",par_iTablePk,l_cCombinedPath)
    l_cHtml += [</div><div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 5
            l_cHtml += GetButtonOnEditFormNew("New Column",l_cSitePath+[DataDictionaries/NewColumn/]+l_cCombinedPath)
            if l_nNumberOfColumns > 1
                l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Order Columns",l_cSitePath+[DataDictionaries/OrderColumns/]+l_cCombinedPath)
            endif
        endif
        
        l_cHtml += [<input type="button" role="button" value="Copy Column List To Clipboard" class="btn btn-primary rounded ms-3" id="CopyRoster" onclick="]
        l_cHtml += [copyToClip(document.getElementById('PreColumnsToClipboard').innerText);return false;">]

    l_cHtml += [</div>]
l_cHtml += [</nav>]

if l_nNumberOfColumns <= 0
    l_cHtml += GetNoRecordsOnFile("No Column on file.")

else
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
                                l_cHtml += [<td><input type="text" name="TextSearchColumnName" id="TextSearchColumnName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnName)+["></td>]
                                l_cHtml += [<td><input type="text" name="TextSearchColumnDescription" id="TextSearchColumnDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchColumnDescription)+["></td>]
                            l_cHtml += [</tr>]
                            l_cHtml += [<tr>]
                                l_cHtml += [<td><span class="me-2 ms-3">Static UID</span></td>]
                                //Made maxlength larger to work around trailing blank and tabs
                                l_cHtml += [<td colspan="2"><input type="text" name="TextSearchColumnStaticUID" id="TextSearchColumnStaticUID" size="36" maxlength="50" value="]+FcgiPrepFieldForValue(l_cSearchColumnStaticUID)+["></td>]
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

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_nColspan := 10
            if l_lHasExternalId
                l_nColspan++
            endif
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan++
            endif
            if l_lWarnings
                l_nColspan++
            endif

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-center text-white" colspan="]+trans(l_nColspan)+[">]
                    if l_nNumberOfColumns == l_nNumberOfColumnsInSearch
                        l_cHtml += [Columns (]+Trans(l_nNumberOfColumns)+[) for Table "]+TextToHtml(par_oNavData:Namespace_Name+FormatAKAForDisplay(par_oNavData:Namespace_AKA)+[.]+alltrim(par_oNavData:Table_Name)+FormatAKAForDisplay(par_oNavData:Table_AKA))+["]
                    else
                        l_cHtml += [Columns (]+Trans(l_nNumberOfColumnsInSearch)+[ out of ]+Trans(l_nNumberOfColumns)+[) for Table "]+TextToHtml(par_oNavData:Namespace_Name+FormatAKAForDisplay(par_oNavData:Namespace_AKA)+[.]+par_oNavData:Table_Name+FormatAKAForDisplay(par_oNavData:Table_AKA))+["]
                    endif
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]

                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += [<th class="text-center"><a href="]+l_cSitePath+[DataDictionaries/NewColumn/]+l_cCombinedPath+[/]+["><span class="text-white bi-plus-lg"></span></a></th>]
                else
                    l_cHtml += [<th class="text-white"></th>]
                endif

                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Type</th>]
                l_cHtml += [<th class="text-white">Nullable</th>]
                l_cHtml += [<th class="text-white">Default</th>]
                l_cHtml += [<th class="text-white">Foreign Key<br>To/Use/Optional</th>]
                l_cHtml += [<th class="text-white text-center">On Delete</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                if l_lHasExternalId
                    l_cHtml += [<th class="text-white">External Id</th>]
                endif
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
                if l_lWarnings
                    l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfColumns
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfColumns->Column_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        do case
                        case ListOfColumns->Column_UsedAs = 2
                            l_cHtml += [<i class="bi bi-key"></i>]
                        case ListOfColumns->Column_UsedAs = 3   // !hb_IsNIL(ListOfColumns->Table_Name)
                            if ListOfColumns->Column_ForeignKeyOptional
                                l_cHtml += [<i class="bi-arrow-bar-right"></i>]
                            else
                                l_cHtml += [<i class="bi-arrow-right"></i>]
                            endi
                        case (ListOfColumns->Column_UsedAs = 4) .or. (ListOfColumns->Column_UsedAs = 1 .and. " "+lower(ListOfColumns->Column_Name)+" " $ " "+lower(l_cApplicationSupportColumns)+" ")
                            l_cHtml += [<i class="bi bi-tools"></i>]
                        endcase
                    l_cHtml += [</td>]

                    // Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cURL  := l_cSitePath+[DataDictionaries/EditColumn/]+l_cCombinedPath+;
                                                                              PrepareForURLSQLIdentifier("Column",ListOfColumns->Column_Name,ListOfColumns->Column_LinkUID)+[/]
                        l_cName := ListOfColumns->Column_Name+FormatAKAForDisplay(ListOfColumns->Column_AKA)
                        if ListOfColumns->Column_UsedBy <> USEDBY_ALLSERVERS
                            l_cURL  += [:]+trans(ListOfColumns->Column_UsedBy)
                            l_cName += [ (]+GetItemInListAtPosition(ListOfColumns->Column_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
                        endif
                        l_cHtml += [<a href="]+l_cURL+[">]+TextToHtml(l_cName)+[</a>]

                        if el_seek(trans(ListOfColumns->pk)+'*',"ListOfPreviousName","tag1")
                            select ListOfPreviousName
                            scan while ListOfPreviousName->pk == ListOfColumns->pk
                                l_cHtml += [<div class="ps-1 small">Previously: ]+TextToHtml(ListOfPreviousName->PreviousName_Name)+[</div>]
                            endscan
                        endif

                    l_cHtml += [</td>]

                    // Type
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]

                        // Prepare the tooltip text for enumeration type fields
                        if alltrim(ListOfColumns->Column_Type) == "E" .and. el_seek(trans(ListOfColumns->pk)+'*',"ListOfEnumValues","tag1")
                            l_cTooltipEnumValues := [<table>]
                            select ListOfEnumValues
                            scan while ListOfEnumValues->Column_pk == ListOfColumns->pk
                                l_cTooltipEnumValues += [<tr]+strtran(GetTRStyleBackgroundColorUseStatus(0,ListOfEnumValues->EnumValue_UseStatus,"1.0"),["],['])+[>]
                                l_cTooltipEnumValues += [<td style='text-align:left'>]+hb_StrReplace(ListOfEnumValues->EnumValue_Name+FormatAKAForDisplay(ListOfEnumValues->EnumValue_AKA),;
                                            {[ ]=>[&nbsp;],;
                                             ["]=>[&#34;],;
                                             [']=>[&#39;],;
                                             [<]=>[&lt;],;
                                             [>]=>[&gt;]})+[</td>]
                                l_cTooltipEnumValues += [<td>]+iif(hb_orm_isnull("ListOfEnumValues","EnumValue_Number"),"","&nbsp;"+trans(ListOfEnumValues->EnumValue_Number))+[</td>]
                                if !hb_orm_isnull("ListOfEnumValues","EnumValue_Description") .and. !empty(ListOfEnumValues->EnumValue_Description)
                                    l_cTooltipEnumValues += [<td>&nbsp;...&nbsp;</td>]
                                else
                                    l_cTooltipEnumValues += [<td></td>]
                                endif
                                l_cTooltipEnumValues += [</tr>]
                            endscan
                            l_cTooltipEnumValues += [</table>]
                        else
                            l_cTooltipEnumValues := ""
                        endif

                        l_cHtml += FormatColumnTypeInfo(alltrim(ListOfColumns->Column_Type),;
                                                        ListOfColumns->Column_Length,;
                                                        ListOfColumns->Column_Scale,;
                                                        ListOfColumns->Column_Unicode,;
                                                        ListOfColumns->Namespace_Name,;
                                                        ListOfColumns->EnumerationNamespace_Name,;
                                                        ListOfColumns->EnumerationNamespace_AKA,;
                                                        ListOfColumns->EnumerationNamespace_LinkUID,;
                                                        ListOfColumns->Enumeration_Name,;
                                                        ListOfColumns->Enumeration_AKA,;
                                                        ListOfColumns->Enumeration_LinkUID,;
                                                        ListOfColumns->Enumeration_ImplementAs,;
                                                        ListOfColumns->Enumeration_ImplementLength,;
                                                        l_cSitePath,;
                                                        par_cURLApplicationLinkCode,;
                                                        l_cTooltipEnumValues)

                        if ListOfColumns->Column_Array
                            l_cHtml += " [Array]"
                        endif
                    l_cHtml += [</td>]

                    // Nullable
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(ListOfColumns->Column_Nullable,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    // Default
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += GetColumnDefault(.f.,ListOfColumns->Column_Type,ListOfColumns->Column_DefaultType,ListOfColumns->Column_DefaultCustom)
                    l_cHtml += [</td>]

                    // Foreign Key To/Use/Optional
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        if !hb_IsNIL(ListOfColumns->ForeignTable_Name)
                            l_cHtml += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+;
                                                l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+"/"+;
                                                                                            PrepareForURLSQLIdentifier("Namespace",ListOfColumns->ForeignNamespace_Name,ListOfColumns->ForeignNamespace_LinkUID)+"/"+;
                                                                                            PrepareForURLSQLIdentifier("Table"    ,ListOfColumns->ForeignTable_Name    ,ListOfColumns->ForeignTable_LinkUID)    +[/]+;
                                                                                            [">]

                            if ListOfColumns->Namespace_Name == ListOfColumns->ForeignNamespace_Name
                                l_cHtml += TextToHTML(ListOfColumns->ForeignTable_Name+FormatAKAForDisplay(ListOfColumns->ForeignTable_AKA))
                            else
                                // l_cHtml += ListOfColumns->ForeignNamespace_Name+[.]+ListOfColumns->ForeignTable_Name+FormatAKAForDisplay(ListOfColumns->ForeignTable_AKA)  //_M_ To Enhance
                                l_cHtml += TextToHTML(ListOfColumns->ForeignNamespace_Name+FormatAKAForDisplay(ListOfColumns->ForeignNamespace_AKA))
                                l_cHtml += [.]
                                l_cHtml += TextToHTML(ListOfColumns->ForeignTable_Name+FormatAKAForDisplay(ListOfColumns->ForeignTable_AKA))
                            endif

                            l_cHtml += [</a>]
                            if !hb_IsNIL(ListOfColumns->Column_ForeignKeyUse)
                                l_cHtml += [<br>]+TextToHTML(ListOfColumns->Column_ForeignKeyUse)
                            endif
                            if ListOfColumns->Column_ForeignKeyOptional
                                l_cHtml += [<br>Optional]
                            endif
                        endif
                    l_cHtml += [</td>]

                    // OnDelete
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        if ListOfColumns->Column_UsedAs = 3
                            l_cHtml += {"","Protect","Cascade","Break Link"}[iif(el_between(ListOfColumns->Column_OnDelete,1,4),ListOfColumns->Column_OnDelete,1)]
                        endif
                    l_cHtml += [</td>]

                    // Description
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfColumns->Column_Description,""))
                    l_cHtml += [</td>]

                    // Usage Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfColumns->Column_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfColumns->Column_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    // Doc Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfColumns->Column_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfColumns->Column_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                    if l_lHasExternalId
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="right">]
                            if nvl(ListOfColumns->Column_ExternalId,0) > 0
                                l_cHtml += trans(ListOfColumns->Column_ExternalId)
                            endif
                        l_cHtml += [</td>]
                    endif

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(ListOfColumns->pk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif

                    if l_lWarnings
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfColumns->Column_TestWarning,""))
                        l_cHtml += [</td>]
                    endif

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('.DisplayEnum').tooltip({html: true,sanitize: false});]

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnListFormOnSubmit(par_iApplicationPk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_cTableName
local l_cTableDescription
local l_cColumnName
local l_cColumnDescription
local l_cColumnStaticUID
local l_cURL

oFcgi:TraceAdd("ColumnListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cColumnName        := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnName"))
l_cColumnDescription := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnDescription"))
l_cColumnStaticUID   := SanitizeInput(oFcgi:GetInputValue("TextSearchColumnStaticUID"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName"       ,l_cColumnName)
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription",l_cColumnDescription)
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnStaticUID"  ,l_cColumnStaticUID)

    l_cHtml += ColumnListFormBuild(par_iApplicationPk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnName"       ,"")
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnDescription","")
    SaveUserSetting("Table_"+Trans(par_iTablePk)+"_ColumnSearch_ColumnStaticUID"  ,"")

    l_cURL := oFcgi:p_cSitePath+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)+[/]+;
                                                                PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name      ,par_oNavData:Table_LinkUID)    +[/]
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += ColumnListFormBuild(par_iApplicationPk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnOrderFormBuild(par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB_ListOfColumns
local l_cSitePath := oFcgi:p_cSitePath
local l_cName

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
    :Column("Column.UsedAs"     ,"Column_UsedAs")
    :Column("Column.UsedBy"     ,"Column_UsedBy")
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

AssembleNavbarInfo("Add",{"Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_AKA,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_AKA    ,par_oNavData:Table_LinkUID})

l_cHtml += GetAboveNavbarHeading("Order Columns","Table",AssembleNavbarInfo("Build"))

select ListOfColumns
l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnOrderListFormSave()
        endif
        l_cHtml += GetButtonCancelAndRedirect(l_cSitePath+[DataDictionaries/ListColumns/]+par_cURLApplicationLinkCode+[/]+;
                                                                                          PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+[/]+;
                                                                                          PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +[/];
                                                                                          )
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]
    l_cHtml += [<div class="col-auto">]

    l_cHtml += [<ul id="sortable">]
    scan all
        l_cName := TextToHTML(ListOfColumns->Column_Name+FormatAKAForDisplay(ListOfColumns->Column_AKA))
        if ListOfColumns->Column_UsedBy <> USEDBY_ALLSERVERS
            l_cName += [ (]+GetItemInListAtPosition(ListOfColumns->Column_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
        endif
        l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfColumns->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+l_cName+[</span></li>]
    endscan
    l_cHtml += [</ul>]

    l_cHtml += [</div>]
l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function ColumnOrderFormOnSubmit(par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
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
l_cColumnPkOrder    := SanitizeInput(oFcgi:GetInputValue("ColumnOrder"))

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
            :SQL("ListOfColumns")
    
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
    
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if el_seek(val(l_aOrderedPks[l_Counter]),"ListOfColumns","pk") .and. ListOfColumns->order <> l_Counter
                with object l_oDB_ListOfColumns
                    :Table("ae13b924-6f6c-4241-bbaf-f840225b7057","Column")
                    :Field("Column.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                     PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+"/"+;
                                                                     PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +"/";
                                                                     )

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ColumnEditFormBuild(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText          := hb_DefaultValue(par_cErrorText,"")
local l_cName               := hb_HGetDef(par_hValues,"Name","")
local l_lTrackNameChanges   := nvl(hb_HGetDef(par_hValues,"TrackNameChanges",.t.),.t.)
local l_cAKA                := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cStaticUID          := nvl(hb_HGetDef(par_hValues,"StaticUID",""),"")
local l_nUsedAs             := hb_HGetDef(par_hValues,"UsedAs",1)
local l_nUsedBy             := hb_HGetDef(par_hValues,"UsedBy",USEDBY_ALLSERVERS)
local l_cTags               := nvl(hb_HGetDef(par_hValues,"Tags",""),"")
local l_nUseStatus          := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus          := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription        := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cType               := alltrim(hb_HGetDef(par_hValues,"Type",""))
local l_lArray              := hb_HGetDef(par_hValues,"Array",.f.)
local l_cLength             := Trans(nvl(hb_HGetDef(par_hValues,"Length",0),0))
local l_cScale              := Trans(nvl(hb_HGetDef(par_hValues,"Scale",0),0))
local l_lNullable           := hb_HGetDef(par_hValues,"Nullable",.t.)
local l_lForeignKeyOptional := hb_HGetDef(par_hValues,"ForeignKeyOptional",.f.)
local l_nOnDelete           := max(1,hb_HGetDef(par_hValues,"OnDelete",2))
local l_nDefaultType        := nvl(hb_HGetDef(par_hValues,"DefaultType",0),0)
local l_cDefaultCustom      := nvl(hb_HGetDef(par_hValues,"DefaultCustom",""),"")
local l_lUnicode            := hb_HGetDef(par_hValues,"Unicode",.t.)
local l_iFk_TableForeign    := nvl(hb_HGetDef(par_hValues,"Fk_TableForeign",0),0)
local l_cForeignKeyUse      := nvl(hb_HGetDef(par_hValues,"ForeignKeyUse",""),"")
local l_iFk_Enumeration     := nvl(hb_HGetDef(par_hValues,"Fk_Enumeration",0),0)
local l_cLastNativeType     := hb_HGetDef(par_hValues,"LastNativeType","")
local l_lShowPrimary        := hb_HGetDef(par_hValues,"ShowPrimary",.f.)
local l_iExternalId         := nvl(hb_HGetDef(par_hValues,"ExternalId",0),0)

local l_iTypeCount

local l_oDB_Application := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_Enumeration := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_Table       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTags  := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:p_cSitePath
local l_ScriptFolder
local l_json_Tags
local l_cTagInfo
local l_nNumberOfTags

local l_json_Entities
local l_hEntityNames := {=>}
local l_cEntityInfo
local l_cObjectName

local l_nOptionNumber
local l_cCallOnChangeSettings := [OnChangeSettings($("#ComboUsedAs").val(),$("#ComboType").val(),$("#ComboDefaultType").val())]

local l_oData_Application
local l_lUseApplicationSettingsForKeys
local l_cKeyType

local l_cListOfColumnsForArray
local l_cSupportColumnName

local l_cCombinedPath

oFcgi:TraceAdd("ColumnEditFormBuild")

with object l_oDB_Application
    :Table("8c4bfb41-a22c-4534-8a6c-5d96323c8e7e","Application")
    :Column("Application.KeyConfig"      ,"Application_KeyConfig")
    :Column("Application.SupportColumns" ,"Application_SupportColumns")
    l_oData_Application := :Get(par_iApplicationPk)
endwith

do case
case l_oData_Application:Application_KeyConfig == 2
    l_lUseApplicationSettingsForKeys := .t.
    l_cKeyType := "I"
case l_oData_Application:Application_KeyConfig == 3
    l_lUseApplicationSettingsForKeys := .t.
    l_cKeyType := "IB"
otherwise
    l_lUseApplicationSettingsForKeys := .f.
    l_cKeyType := "?"
endcase

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
            l_cTagInfo := ListOfTags->Tag_Name+[ (]+ListOfTags->Tag_Code+[)]
            l_json_Tags += "{tag:'"+TextToHTML(l_cTagInfo)+"',value:"+trans(ListOfTags->pk)+"}"
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
                                                                "keepLastOnHoverTag: false,"+;
                                                                "afterAdd: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }},"+;
                                                                "afterRemove: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }}"+;
                                                                [});]

        
    endif
endwith

oFcgi:p_cjQueryScript += "$('#PageLoaded').val('1');"

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 300px;} ]
l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
l_cHtml += [</style>]

with object l_oDB_Enumeration
    :Table("6a8f483d-5d48-40ed-a293-e54add5f1790","Enumeration")
    :Column("Enumeration.pk"              ,"Enumeration_pk")
    :Column("Enumeration.Name"            ,"Enumeration_Name")
    :Column("Enumeration.ImplementAs"     ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength" ,"Enumeration_ImplementLength")
    :Column("upper(Enumeration.Name)" , "tag1")
    :OrderBy("tag1")
    :Where("Enumeration.fk_Namespace = ^" , par_iNamespacePk)
    :SQL("ListOfEnumeration")
endwith

with object l_oDB_Table
    :Table("3889c7c9-38c5-4ba5-a023-839bde5e07fd","Table")
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Column("Table.pk"             ,"Table_pk")
    :Column("Namespace.Name"       ,"Namespace_Name")
    :Column("Namespace.AKA"        ,"Namespace_AKA")
    :Column("Table.Name"           ,"Table_Name")
    :Column("Table.AKA"            ,"Table_AKA")
    :Column("upper(Namespace.Name)","tag1")
    :Column("upper(Table.Name)"    ,"tag2")
    :OrderBy("tag1")
    :OrderBy("tag2")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :SQL("ListOfTable")
endwith

l_cHtml += [<script language="javascript">]
//----------------------------------------------------------------------------
l_cHtml += [function OnChangeSettings(par_cUsedAs,par_cType,par_cDefaultType) {]

    l_cHtml += [switch(par_cUsedAs) {]

    l_cHtml += [  case '2': ]  // PrimaryKey
    l_cHtml +=   [$('#EntryNullable').hide();]
    l_cHtml +=   [$('#CheckNullable').prop('checked', false);]

    l_cHtml +=   [$('#EntryArray').hide();]
    l_cHtml +=   [$('#CheckArray').prop('checked', false);]

    l_cHtml +=   [$('#EntryFk_TableForeign').hide();]
    l_cHtml +=   [$('#ComboFk_TableForeign').val('0');]

    l_cHtml +=   [$('#EntryForeignKeyUse').hide();]
    l_cHtml +=   [$('#TextForeignKeyUse').val('');]

    l_cHtml +=   [$('#EntryOnDelete').hide();]
    // l_cHtml +=   [$('#ComboOnDelete').val('1');]

    if l_lUseApplicationSettingsForKeys
        l_cHtml +=   [$('#EntryType').hide();]
        l_cHtml +=   [par_cType = ']+l_cKeyType+[';]
        l_cHtml +=   [$('#EntryType').val(']+l_cKeyType+[');]

        l_cHtml +=   [$('#EntryDefaultType').hide();]
        l_cHtml +=   [par_cDefaultType = '15';]
        l_cHtml +=   [$('#EntryDefaultType').val('15');]
    else
        l_cHtml +=   [$('#EntryType').show();]
        l_cHtml +=   [$('#EntryDefaultType').show();]
    endif
    l_cHtml += [    break;]

    l_cHtml += [  case '3': ]  // ForeignKey
    if l_lUseApplicationSettingsForKeys
        l_cHtml +=   [$('#EntryNullable').hide();]
        l_cHtml +=   [$('#CheckNullable').prop('checked', true);]

        l_cHtml +=   [$('#EntryType').hide();]
        l_cHtml +=   [par_cType = ']+l_cKeyType+[';]
        l_cHtml +=   [$('#EntryType').val(']+l_cKeyType+[');]

        l_cHtml +=   [$('#EntryDefaultType').hide();]
        l_cHtml +=   [par_cDefaultType = '0';]
        l_cHtml +=   [$('#EntryDefaultType').val('0');]
    else
        l_cHtml +=   [$('#EntryNullable').show();]
        l_cHtml +=   [$('#EntryType').show();]
        l_cHtml +=   [$('#EntryDefaultType').show();]
    endif
    
    l_cHtml +=   [$('#EntryArray').hide();]
    l_cHtml +=   [$('#CheckArray').prop('checked', false);]

    l_cHtml +=   [$('#EntryFk_TableForeign').show();]
    l_cHtml +=   [$('#EntryForeignKeyUse').show();]
    l_cHtml +=   [$('#EntryOnDelete').show();]
    l_cHtml += [    break;]

    l_cHtml += [  default:]  //Regular or Support
    l_cHtml +=   [$('#EntryNullable').show();]
    l_cHtml +=   [$('#EntryType').show();]
    l_cHtml +=   [$('#EntryArray').show();]

    l_cHtml +=   [$('#EntryFk_TableForeign').hide();]
    l_cHtml +=   [$('#ComboFk_TableForeign').val('0');]

    l_cHtml +=   [$('#EntryForeignKeyUse').hide();]
    l_cHtml +=   [$('#TextForeignKeyUse').val('');]

    l_cHtml +=   [$('#EntryOnDelete').hide();]
    // l_cHtml +=   [$('#ComboOnDelete').val('1');]

    l_cHtml +=   [$('#EntryDefaultType').show();]
    l_cHtml += [};]

    l_cHtml += [switch(par_cType) {]
    for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
        l_cHtml += [  case ']+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+[':]
        l_cHtml += [  $('#SpanLength').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_LENGTH],[show],[hide])+[();]
        l_cHtml +=   [$('#SpanScale').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_SCALE],[show],[hide])+[();]
        l_cHtml +=   [$('#SpanEnumeration').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_ENUMS],[show],[hide])+[();]
        l_cHtml +=   [$('#EntryUnicode').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_UNICODE],[show],[hide])+[();]
        l_cHtml += [    break;]
    endfor
    l_cHtml += [  default:]
    l_cHtml += [  $('#SpanLength').hide();$('#SpanScale').hide();$('#SpanEnumeration').hide();]
    l_cHtml += [};]

    l_cHtml += [switch(par_cType) {]
    l_cHtml += [  case 'L':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="13">False</option>')]
        l_cHtml += [.append('<option value="14">True</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'D':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="10">Today</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'TOZ':]
    l_cHtml += [  case 'TO':]
    l_cHtml += [  case 'DTZ':]
    l_cHtml += [  case 'DT':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="11">Now</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'I':]
    l_cHtml += [  case 'IB':]
    l_cHtml += [  case 'IS':]
    l_cHtml += [  case 'N':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="15">Auto Increment</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'UUI':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="12">Random uuid</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  default:]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [;]
    l_cHtml += [};]

    l_cHtml += [$('#ComboDefaultType').val(par_cDefaultType);]  // Since we called .remove().end() we need to reset the value

    l_cHtml += [switch(par_cDefaultType) {]
    l_cHtml += [  case '1':]  // Custom Default
    l_cHtml +=   [ $('#EntryDefaultCustom').show();]
    l_cHtml +=   [ break;]

    l_cHtml += [  default:]
    l_cHtml +=   [ $('#EntryDefaultCustom').hide();]
    l_cHtml +=   [ break;]
    l_cHtml += [};]

l_cHtml += [};]
//----------------------------------------------------------------------------
l_cHtml += [</script>] 

oFcgi:p_cjQueryScript += l_cCallOnChangeSettings+[;]

SetSelect2Support()

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="PageLoaded" id="PageLoaded" value="0">]

l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += [<input type="hidden" name="CheckShowPrimary" value="]+iif(l_lShowPrimary,"1","0")+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+[/]+;
                   PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +[/]

AssembleNavbarInfo("Add",{"Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_AKA,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_AKA    ,par_oNavData:Table_LinkUID})

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Column","Table",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += GetNextPreviousColumn(par_iTablePk,l_cCombinedPath,par_iPk)
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Column",l_cSitePath+[DataDictionaries/NewColumn/]+l_cCombinedPath)

                l_cHtml += GetButtonOnEditFormDelete()
                l_cHtml += GetConfirmationModalFormsDelete()

                if l_nUsedAs <> COLUMN_USEDAS_PRIMARY_KEY
                    l_cHtml += GetButtonOnEditFormDuplicate()
                    l_cHtml += GetConfirmationModalFormsDuplicate("Only the Column definition will be duplicated.")
                endif

            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(par_iPk)
    l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
endif

l_cHtml += [<div class="m-3"></div>]

// Code to dynamically show/hide "Implicit Support"
l_cHtml += [<script type="text/javascript">]
l_cHtml += [function UpdateImplicitSupportNotice()]
l_cHtml += [{]
l_cListOfColumnsForArray := ""
for each l_cSupportColumnName in hb_ATokens( nvl(l_oData_Application:Application_SupportColumns,"") , " " ,.f.)
    if !empty(l_cListOfColumnsForArray)
        l_cListOfColumnsForArray += ","
    endif
    l_cListOfColumnsForArray += ["]+l_cSupportColumnName+["]
endfor
l_cHtml += 'const j_PossibleValues = ['+l_cListOfColumnsForArray+'];'
l_cHtml += [if( ($("#TextName").val()) && j_PossibleValues.includes( $("#TextName").val() ))]
l_cHtml += [ $("#TextImplicitSupport").show();]
l_cHtml += [else]
l_cHtml += [ $("#TextImplicitSupport").hide();]
l_cHtml += [}]
l_cHtml += [</script>]
oFcgi:p_cjQueryScript += [UpdateImplicitSupportNotice();]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" onchange="UpdateImplicitSupportNotice();" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += GetTrackNameChangesAndPreviousNamesEditFormBuild(l_lTrackNameChanges,"Column",par_iPk)

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    if !empty(l_cStaticUID)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Static UID</td>]
            l_cHtml += [<td class="pb-3"><span>]+l_cStaticUID+[</span>]
            l_cHtml += [<input type="hidden" name="TextStaticUID" id="TextStaticUID" value="]+FcgiPrepFieldForValue(l_cStaticUID)+[">]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used As</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboUsedAs" id="ComboUsedAs" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedAs==1,[ selected],[])+[></option>]
            if l_lShowPrimary
                l_cHtml += [<option value="2"]+iif(l_nUsedAs==2,[ selected],[])+[>Primary Key</option>]
            endif
            l_cHtml += [<option value="3"]+iif(l_nUsedAs==3,[ selected],[])+[>Foreign Key</option>]
            l_cHtml += [<option value="4"]+iif(l_nUsedAs==4,[ selected],[])+[>Support</option>]
            l_cHtml += [</select>]

            l_cHtml += [<span class="ms-5" id="TextImplicitSupport">Implicitly "Support"</span>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    // if l_lShowPrimary
    // endif

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used By</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUsedBy" id="ComboUsedBy"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedBy==1,[ selected],[])+[>All Servers</option>]
            l_cHtml += [<option value="2"]+iif(l_nUsedBy==2,[ selected],[])+[>MySQL Only</option>]
            l_cHtml += [<option value="3"]+iif(l_nUsedBy==3,[ selected],[])+[>PostgreSQL Only</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    if l_nNumberOfTags > 0
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Tags</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextTags" id="TextTags" value="]+FcgiPrepFieldForValue(l_cTags)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control" placeholder=""></td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += [<tr class="pb-5" id="EntryType">]
        l_cHtml += [<td class="pe-2 pb-3">Type</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<span class="pe-5">]
                l_cHtml += [<select name="ComboType" id="ComboType" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
                    l_cHtml += [<option value="]+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+["]+iif(l_cType==oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE],[ selected],[])+[>]+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+" - "+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_NAME]+[</option>]
                endfor
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanLength" style="display: none;">]
                l_cHtml += [<span class="pe-2">Length</span><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextLength" id="TextLength" value="]+FcgiPrepFieldForValue(l_cLength)+[" size="5" maxlength="5"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanScale" style="display: none;">]
                l_cHtml += [<span class="pe-2">Scale</span><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextScale" id="TextScale" value="]+FcgiPrepFieldForValue(l_cScale)+[" size="2" maxlength="2"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanEnumeration" style="display: none;">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboFk_Enumeration" id="ComboFk_Enumeration"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                    l_cHtml += [<option value="0"]+iif(l_iFk_Enumeration==0,[ selected],[])+[></option>]
                    select ListOfEnumeration
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfEnumeration->Enumeration_pk)+["]+iif(ListOfEnumeration->Enumeration_pk == l_iFk_Enumeration,[ selected],[])+[>]+FcgiPrepFieldForValue(alltrim(ListOfEnumeration->Enumeration_Name))+[&nbsp;(]+EnumerationImplementAsInfo(ListOfEnumeration->Enumeration_ImplementAs,ListOfEnumeration->Enumeration_ImplementLength)+[)]+[</option>]
                    endscan
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            if !empty(nvl(l_cLastNativeType,""))
                l_cHtml += [<span class="pe-5" id="SpanLastNativeType">Last Sync/Log Type: ] + l_cLastNativeType + [</span>]
                l_cHtml += [<input type="hidden" name="TextLastNativeType" value="]+FcgiPrepFieldForValue(l_cLastNativeType)+[">]
            endif

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryNullable">]
        l_cHtml += [<td class="pe-2 pb-3">Nullable</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += GetCheckboxOnEditForm("CheckNullable",l_lNullable,,(oFcgi:p_nAccessLevelDD < 5))
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryArray">]
        l_cHtml += [<td class="pe-2 pb-3">Array</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += GetCheckboxOnEditForm("CheckArray",l_lArray,"(PostgreSQL Only)",,(oFcgi:p_nAccessLevelDD < 5))
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryDefaultType">]
        l_cHtml += [<td class="pe-2 pb-3">Default Options</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboDefaultType" id="ComboDefaultType" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="0"]+iif(l_nDefaultType==0,[ selected],[])+[></option>]
            l_cHtml += [<option value="1"]+iif(l_nDefaultType==1,[ selected],[])+[></option>]
            for l_nOptionNumber := 10 to 30   //Originally have to list all possible values, so that the initial OnChangeDefaultType() will position on the correct option.
                l_cHtml += [<option value="]+trans(l_nOptionNumber)+["]+iif(l_nDefaultType==l_nOptionNumber,[ selected],[])+[></option>]
            endfor
            
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryDefaultCustom">]
        l_cHtml += [<td class="pe-2 pb-3">Default</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextDefaultCustom" id="TextDefaultCustom" value="]+FcgiPrepFieldForValue(l_cDefaultCustom)+[" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryUnicode">]
        l_cHtml += [<td class="pe-2 pb-3">Unicode</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckUnicode" id="CheckUnicode" value="1"]+iif(l_lUnicode," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]

    l_json_Entities := []
    select ListOfTable
    scan all
        if !empty(l_json_Entities)
            l_json_Entities += [,]
        endif

        l_cEntityInfo := ""
        if par_oNavData:Namespace_Name <> ListOfTable->Namespace_Name
            l_cEntityInfo += ListOfTable->Namespace_Name+FormatAKAForDisplay(ListOfTable->Namespace_AKA)
            l_cEntityInfo += [.]
        endif
        l_cEntityInfo += ListOfTable->Table_Name+FormatAKAForDisplay(ListOfTable->Table_AKA)

        //JSON encoding   See https://www.w3schools.com/charsets/ref_utf_basic_latin.asp
        l_cEntityInfo := hb_StrReplace(l_cEntityInfo,{chr( 1)=>[],;
                                                      chr( 2)=>[],;
                                                      chr(10)=>[],;
                                                      [&nbsp;]=>[ ],;    //To deal with some previous c Encoding
                                                      [\u]=>chr(1),;
                                                      [\]=>chr(2),;
                                                      "["=>[\u005B],;
                                                      "]"=>[\u005D],;
                                                      [ ]=>[\u0020],;
                                                      [<]=>[\u003C],;
                                                      [>]=>[\u003E],;
                                                      [~]=>[\u007E],;
                                                      [']=>[\u0027],;
                                                      ["]=>[\u0022],;
                                                      chr( 1)=>[\u],;
                                                      chr( 2)=>[\\],;
                                                      chr(13)=>[\n]})

        l_json_Entities += "{id:"+trans(ListOfTable->Table_pk)+",text:'"+l_cEntityInfo+"'}"

        //Tweak the encoding to deal with issues in jQuery Select2
        l_cEntityInfo := hb_StrReplace(l_cEntityInfo,{[\u0020]=>[ ],;
                                                      [\u003C]=>[&lt;],;
                                                      [\u003E]=>[&gt;]})

        l_hEntityNames[ListOfTable->Table_pk] := l_cEntityInfo

    endscan
    l_json_Entities := "["+l_json_Entities+"]"

    l_cObjectName := "ComboFk_TableForeign"

    ActivatejQuerySelect2("#"+l_cObjectName,l_json_Entities)

    l_cHtml += [<tr class="pb-5" id="EntryFk_TableForeign">]
        l_cHtml += [<td class="pe-2 pb-3">Foreign Key To</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<table><tr>]
                l_cHtml += [<td class="me-3">]
                    l_cHtml += [<select name="]+l_cObjectName+[" id="]+l_cObjectName+[" class="SelectEntity" style="width:600px">]
                        if l_iFk_TableForeign == 0
                            oFcgi:p_cjQueryScript += [$("#]+l_cObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
                        else
                            l_cHtml += [<option value="]+Trans(l_iFk_TableForeign)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iFk_TableForeign,"")+[</option>]
                        endif
                    l_cHtml += [</select>]
                l_cHtml += [</td>]

                // l_cHtml += [<td class="ps-4 pe-2">Optional</td>] // class="pe-2 pb-3"
                // l_cHtml += [<td><div class="form-check form-switch">]  // class="pb-3"
                //     l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckForeignKeyOptional" id="CheckForeignKeyOptional" value="1"]+iif(l_lForeignKeyOptional," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                // l_cHtml += [</div></td>]
                l_cHtml += [<td>]+replicate([&nbsp;],4)+[</td>]
                l_cHtml += [<td>]
                    l_cHtml += GetCheckboxOnEditForm("CheckForeignKeyOptional",l_lForeignKeyOptional,"Optional",,(oFcgi:p_nAccessLevelDD < 5))
                l_cHtml += [</td>]

            l_cHtml += [</tr></table>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryForeignKeyUse">]
        l_cHtml += [<td class="pe-2 pb-3">Foreign Key Use</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextForeignKeyUse" id="TextForeignKeyUse" value="]+FcgiPrepFieldForValue(l_cForeignKeyUse)+[" maxlength="120" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryOnDelete">]
        l_cHtml += [<td class="pe-2 pb-3">On Delete</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboOnDelete" id="ComboOnDelete"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nOnDelete==1,[ selected],[])+[></option>]
            l_cHtml += [<option value="2"]+iif(l_nOnDelete==2,[ selected],[])+[>Protect (Restrict)</option>]
            l_cHtml += [<option value="3"]+iif(l_nOnDelete==3,[ selected],[])+[>Cascade</option>]
            l_cHtml += [<option value="4"]+iif(l_nOnDelete==4,[ selected],[])+[>Break Link</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
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
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    if !empty(l_iExternalId)
        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">External Id</td>]
            l_cHtml += [<td class="pb-3">]+trans(l_iExternalId)+[ (Created via API call)</td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_COLUMN,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))

    l_cHtml += [</table>]

    l_cHtml += [<input type="hidden" name="TextExternalId" id="TextExternalId" value="]+trans(l_iExternalId)+[">]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function ColumnEditFormOnSubmit(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_iColumnPk
local l_cColumnName
local l_lColumnTrackNameChanges
local l_cColumnAKA
local l_nColumnUsedAs
local l_nColumnUsedBy
local l_nColumnUseStatus
local l_nColumnDocStatus
local l_cColumnDescription
local l_cColumnType
local l_lColumnArray
local l_cColumnLength
local l_nColumnLength
local l_cColumnScale
local l_nColumnScale
local l_cColumnLastNativeType
local l_lColumnNullable
local l_lColumnForeignKeyOptional
local l_nColumnOnDelete
local l_nColumnDefaultType
local l_cColumnDefaultCustom
local l_lColumnUnicode
local l_iColumnFk_TableForeign
local l_cColumnForeignKeyUse
local l_iColumnFk_Enumeration
local l_lShowPrimary
local l_iColumnExternalId

local l_iColumnOrder
local l_iTypePos   //The position in the oFcgi:p_ColumnTypes array

local l_hValues := {=>}

local l_aSQLResult := {}

local l_cErrorMessage := ""
local l_oDB1
local l_oData

local l_oDBListOfTagsOnFile
local l_cListOfTagPks
local l_nNumberOfTagColumnOnFile
local l_hTagColumnOnFile := {=>}
local l_aTagsSelected
local l_cTagSelected
local l_iTagSelectedPk
local l_iTagColumnPk

local l_cLinkUID
local l_cName
local l_nPos

local l_iTablePk := 0

oFcgi:TraceAdd("ColumnEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iColumnPk                 := Val(oFcgi:GetInputValue("TableKey"))

l_lShowPrimary              := (oFcgi:GetInputValue("CheckShowPrimary") == "1")

l_cColumnName               := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_lColumnTrackNameChanges   := (oFcgi:GetInputValue("CheckTrackNameChanges") == "1")
l_cColumnAKA                := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cColumnAKA)
    l_cColumnAKA := NIL
endif

l_nColumnUsedAs             := Val(oFcgi:GetInputValue("ComboUsedAs"))

l_nColumnUsedBy             := Val(oFcgi:GetInputValue("ComboUsedBy"))

l_nColumnUseStatus          := Val(oFcgi:GetInputValue("ComboUseStatus"))

l_cColumnType               := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("ComboType"))
l_lColumnArray              := (oFcgi:GetInputValue("CheckArray") == "1")

l_cColumnLength             := SanitizeInput(oFcgi:GetInputValue("TextLength"))
l_nColumnLength             := iif(empty(l_cColumnLength),NULL,val(l_cColumnLength))

l_cColumnScale              := SanitizeInput(oFcgi:GetInputValue("TextScale"))
l_nColumnScale              := iif(empty(l_cColumnScale),NULL,val(l_cColumnScale))

l_cColumnLastNativeType     := SanitizeInput(oFcgi:GetInputValue("TextLastNativeType"))

l_lColumnNullable           := (oFcgi:GetInputValue("CheckNullable") == "1")

l_lColumnForeignKeyOptional := (oFcgi:GetInputValue("CheckForeignKeyOptional") == "1")

l_nColumnOnDelete           := Val(oFcgi:GetInputValue("ComboOnDelete"))

l_nColumnDefaultType        := Val(oFcgi:GetInputValue("ComboDefaultType"))

l_cColumnDefaultCustom      := SanitizeInput(oFcgi:GetInputValue("TextDefaultCustom"))
if empty(l_cColumnDefaultCustom)
    l_cColumnDefaultCustom := NIL
endif

l_lColumnUnicode            := (oFcgi:GetInputValue("CheckUnicode") == "1")

l_iColumnFk_TableForeign    := Val(oFcgi:GetInputValue("ComboFk_TableForeign"))

l_cColumnForeignKeyUse      := SanitizeInput(oFcgi:GetInputValue("TextForeignKeyUse"))

l_iColumnFk_Enumeration     := Val(oFcgi:GetInputValue("ComboFk_Enumeration"))

l_nColumnDocStatus          := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cColumnDescription        := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

l_iColumnExternalId         := Val(oFcgi:GetInputValue("TextExternalId"))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cColumnName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                if l_nColumnUsedBy > USEDBY_ALLSERVERS
                    :Table("1af13732-e24c-462f-9bd1-c7d282c176fe","Column")
                    :Column("Column.pk","pk")
                    :Column("Column.pk","UsedBy")
                    :Where([Column.fk_Table = ^],par_iTablePk)
                    :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cColumnName," ","")))
                    :Where([Column.UsedBy = ^],l_nColumnUsedBy)
                    if l_iColumnPk > 0
                        :Where([Column.pk != ^],l_iColumnPk)
                    endif
                    :SQL()
                    if :Tally <> 0
                        l_cErrorMessage := "Duplicate Name/Used By"
                    endif

                    if empty(l_cErrorMessage)
                        :Table("57cf9d71-0354-4a9b-9071-f1a95144f87a","Column")
                        :Column("Column.pk","pk")
                        :Column("Column.pk","UsedBy")
                        :Where([Column.fk_Table = ^],par_iTablePk)
                        :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cColumnName," ","")))
                        :Where([Column.UsedBy = ^],USEDBY_ALLSERVERS)
                        if l_iColumnPk > 0
                            :Where([Column.pk != ^],l_iColumnPk)
                        endif
                        :SQL()
                        if :Tally <> 0
                            l_cErrorMessage := [Duplicate Name and "Used By" marked as "All Servers"]
                        endif
                    endif
                else
                    //Only 1 record should exists for the same name
                    :Table("810f0a78-58e8-46d2-87a2-5e29b484d274","Column")
                    :Column("Column.pk","pk")
                    :Column("Column.pk","UsedBy")
                    :Where([Column.fk_Table = ^],par_iTablePk)
                    :Where([lower(replace(Column.Name,' ','')) = ^],lower(StrTran(l_cColumnName," ","")))
                    if l_iColumnPk > 0
                        :Where([Column.pk != ^],l_iColumnPk)
                    endif
                    :SQL()
                    if :Tally <> 0
                        l_cErrorMessage := "Duplicate Name"
                    endif
                endif
            endwith

            if empty(l_cErrorMessage)
                l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[COLUMN_TYPES_CODE] == l_cColumnType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
                if l_iTypePos <= 0
                    l_cErrorMessage := [Failed to find "Column Type" definition.]
                else
                    
                    do case
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]) .and. hb_IsNIL(l_nColumnLength)   // Length should be entered
                        l_cErrorMessage := "Length is required!"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE]) .and. hb_IsNIL(l_nColumnScale)   // Scale should be entered
                        l_cErrorMessage := "Scale is required! Enter at the minimum 0"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]) .and. (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE]) .and. l_nColumnScale >= l_nColumnLength
                        l_cErrorMessage := "Scale must be smaller than Length!"

                    case !hb_IsNIL(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE]) .and. l_nColumnScale > oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE]
                        l_cErrorMessage := "Scale may not exceed "+trans(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE])+"!"

                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_ENUMS]) .and. empty(l_iColumnFk_Enumeration)   // Enumeration should be entered
                        l_cErrorMessage := "Select an Enumeration!"

                    otherwise

                    endcase
                endif
            endif

            if empty(l_cErrorMessage)
                //Test that will not mark more than 1 field as Primary
                if l_nColumnUsedAs = 2
                    with object l_oDB1
                        :Table("6f19ee39-637d-4995-b157-c4f35a6cb4e3","Column")
                        :Column("Column.pk","pk")
                        :Where([Column.fk_Table = ^],par_iTablePk)
                        :Where("Column.UsedAs = 2")
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
                if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH])
                    l_nColumnLength := NIL
                endif
                if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE])
                    l_nColumnScale := NIL
                endif
                if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_ENUMS])
                    l_iColumnFk_Enumeration := 0
                endif
                // if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_UNICODE])    // Will not turn of the Unicode flag, in case column type is switched back to a char ...
                //     l_lColumnUnicode := .f.
                // endif
            endif
        endif

        //Save the Column
        with object l_oDB1
            l_cErrorMessage := TrackNameChange(l_oDB1,"Column",l_iColumnPk,l_cColumnName,l_lColumnTrackNameChanges)
             if empty(l_cErrorMessage)
                RemovePreviousNameIfSelectedEditFormOnSubmit("Column",l_iColumnPk)

                :Table("1a6da9a6-6812-4129-979c-c8b8f848f351","Column")
                if oFcgi:p_nAccessLevelDD >= 5
                    :Field("Column.Name"              ,l_cColumnName)
                    :Field("Column.TrackNameChanges"  ,l_lColumnTrackNameChanges)
                    :Field("Column.AKA"               ,l_cColumnAKA)
                    :Field("Column.UsedAs"            ,l_nColumnUsedAs)
                    :Field("Column.UsedBy"            ,l_nColumnUsedBy)
                    :Field("Column.UseStatus"         ,l_nColumnUseStatus)
                    :Field("Column.Type"              ,l_cColumnType)
                    :Field("Column.Array"             ,l_lColumnArray)
                    :Field("Column.Length"            ,l_nColumnLength)
                    :Field("Column.Scale"             ,l_nColumnScale)
                    :Field("Column.Nullable"          ,l_lColumnNullable)
                    :Field("Column.ForeignKeyOptional",l_lColumnForeignKeyOptional)
                    :Field("Column.OnDelete"          ,l_nColumnOnDelete)
                    :Field("Column.DefaultType"       ,l_nColumnDefaultType)
                    :Field("Column.DefaultCustom"     ,l_cColumnDefaultCustom)
                    :Field("Column.Unicode"           ,l_lColumnUnicode)
                    :Field("Column.Fk_TableForeign"   ,l_iColumnFk_TableForeign)
                    :Field("Column.ForeignKeyUse"     ,iif(empty(l_cColumnForeignKeyUse),NULL,l_cColumnForeignKeyUse))
                    :Field("Column.Fk_Enumeration"    ,l_iColumnFk_Enumeration)
                endif
                :Field("Column.DocStatus"  ,l_nColumnDocStatus)
                :Field("Column.Description",iif(empty(l_cColumnDescription),NULL,l_cColumnDescription))
            
                if empty(l_iColumnPk)
                    :Field("Column.fk_Table",par_iTablePk)
                    :Field("Column.Order"   ,l_iColumnOrder)
                    :Field("Column.LinkUID" ,oFcgi:p_o_SQLConnection:GetUUIDString())
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
                                    :Field("TagColumn.fk_Column",l_iColumnPk)
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

                // if empty(l_cErrorMessage)
                    DataDictionaryFixAndTest(par_iApplicationPk)
                // endif
            endif
        endwith
        // if empty(l_cErrorMessage)
        //     l_iColumnPk := 0
        // endif

    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iColumnPk := 0

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

            DataDictionaryFixAndTest(par_iApplicationPk)
            l_iColumnPk := 0
            

        else
            l_cErrorMessage := "Related Index Expression record on file"

        endif
    endif

case l_cActionOnSubmit == "Duplicate"   // Column
    if oFcgi:p_nAccessLevelDD >= 5 .and. l_iColumnPk > 0

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("6048be43-4909-40db-9157-796c765d7ac7","Column")
            :Column("Column.fk_Table"          ,"Column_fk_Table")
            :Column("Column.fk_TableForeign"   ,"Column_fk_TableForeign")
            :Column("Column.fk_Enumeration"    ,"Column_fk_Enumeration")
            :Column("Column.Order"             ,"Column_Order")
            :Column("Column.LinkUID"           ,"Column_LinkUID")
            :Column("Column.Name"              ,"Column_Name")
            :Column("Column.TrackNameChanges"  ,"Column_TrackNameChanges")
            :Column("Column.AKA"               ,"Column_AKA")
            :Column("Column.UsedAs"            ,"Column_UsedAs")
            :Column("Column.UsedBy"            ,"Column_UsedBy")
            :Column("Column.UseStatus"         ,"Column_UseStatus")
            :Column("Column.DocStatus"         ,"Column_DocStatus")
            :Column("Column.Type"              ,"Column_Type")
            :Column("Column.Array"             ,"Column_Array")
            :Column("Column.Length"            ,"Column_Length")
            :Column("Column.Scale"             ,"Column_Scale")
            :Column("Column.Nullable"          ,"Column_Nullable")
            :Column("Column.DefaultType"       ,"Column_DefaultType")
            :Column("Column.DefaultCustom"     ,"Column_DefaultCustom")
            :Column("Column.ForeignKeyUse"     ,"Column_ForeignKeyUse")
            :Column("Column.ForeignKeyOptional","Column_ForeignKeyOptional")
            :Column("Column.OnDelete"          ,"Column_OnDelete")
            :Column("Column.Unicode"           ,"Column_Unicode")
            :Column("Column.Description"       ,"Column_Description")
            // :Column("Column.TestWarning"       ,"Column_TestWarning")
            // :Column("Column.LastNativeType"    ,"Column_LastNativeType")
            l_oData := :Get(l_iColumnPk)

            if !hb_IsNil(l_oData)

                if l_oData:Column_UsedAs == COLUMN_USEDAS_PRIMARY_KEY
                    //This should not happen since the Duplicate button should not be visible on a primary key.
                    //l_cErrorMessage := "May not dupicate the Primary key."
                    l_iColumnPk := 0

                else
                    l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                    l_cName := OnDuplicateSanitizeName(l_oData:Column_Name,l_cLinkUID,l_oData:Column_LinkUID)
                    
                    l_iTablePk := l_oData:Column_fk_Table

                    :Table("c90aba01-148b-470c-b4af-a223992a2fe3","Column")
                    :Field("Column.fk_Table"          ,l_iTablePk)
                    :Field("Column.LinkUID"           ,l_cLinkUID)
                    :Field("Column.Name"              ,l_cName)

                    :Field("Column.fk_TableForeign"   ,l_oData:Column_fk_TableForeign)
                    :Field("Column.fk_Enumeration"    ,l_oData:Column_fk_Enumeration)
                    :Field("Column.Order"             ,l_oData:Column_Order)
                    :Field("Column.TrackNameChanges"  ,l_oData:Column_TrackNameChanges)
                    :Field("Column.AKA"               ,l_oData:Column_AKA)
                    :Field("Column.UsedAs"            ,l_oData:Column_UsedAs)
                    :Field("Column.UsedBy"            ,l_oData:Column_UsedBy)
                    :Field("Column.UseStatus"         ,l_oData:Column_UseStatus)
                    :Field("Column.DocStatus"         ,l_oData:Column_DocStatus)
                    :Field("Column.Type"              ,l_oData:Column_Type)
                    :Field("Column.Array"             ,l_oData:Column_Array)
                    :Field("Column.Length"            ,l_oData:Column_Length)
                    :Field("Column.Scale"             ,l_oData:Column_Scale)
                    :Field("Column.Nullable"          ,l_oData:Column_Nullable)
                    :Field("Column.DefaultType"       ,l_oData:Column_DefaultType)
                    :Field("Column.DefaultCustom"     ,l_oData:Column_DefaultCustom)
                    :Field("Column.ForeignKeyUse"     ,l_oData:Column_ForeignKeyUse)
                    :Field("Column.ForeignKeyOptional",l_oData:Column_ForeignKeyOptional)
                    :Field("Column.OnDelete"          ,l_oData:Column_OnDelete)
                    :Field("Column.Unicode"           ,l_oData:Column_Unicode)
                    :Field("Column.Description"       ,l_oData:Column_Description)
                    // :Field("Column.TestWarning"       ,l_oData:Column_TestWarning)
                    // :Field("Column.LastNativeType"    ,l_oData:Column_LastNativeType)

                    if :Add()
                        l_iColumnPk := :Key()
                    else
                        l_cErrorMessage := "Failed to add Column."
                    endif
                endif
            endif

        endwith
        if l_iTablePk > 0
            ReSequenceColumns(l_iTablePk)
        endif
        DataDictionaryFixAndTest(par_iApplicationPk)
    else
        l_cErrorMessage := "No Access to Duplicate"
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]               := l_cColumnName
    l_hValues["AKA"]                := l_cColumnAKA
    l_hValues["UsedAs"]             := l_nColumnUsedAs
    l_hValues["UsedBy"]             := l_nColumnUsedBy
    l_hValues["UseStatus"]          := l_nColumnUseStatus
    l_hValues["DocStatus"]          := l_nColumnDocStatus
    l_hValues["Description"]        := l_cColumnDescription
    l_hValues["Type"]               := l_cColumnType
    l_hValues["Array"]              := l_lColumnArray
    l_hValues["Length"]             := l_nColumnLength
    l_hValues["Scale"]              := l_nColumnScale
    l_hValues["LastNativeType"]     := l_cColumnLastNativeType
    l_hValues["Nullable"]           := l_lColumnNullable
    l_hValues["ForeignKeyOptional"] := l_lColumnForeignKeyOptional
    l_hValues["OnDelete"]           := l_nColumnOnDelete
    l_hValues["DefaultType"]        := l_nColumnDefaultType
    l_hValues["DefaultCustom"]      := l_cColumnDefaultCustom
    l_hValues["Unicode"]            := l_lColumnUnicode
    l_hValues["ShowPrimary"]        := l_lShowPrimary
    l_hValues["Fk_TableForeign"]    := l_iColumnFk_TableForeign
    l_hValues["ForeignKeyUse"]      := l_cColumnForeignKeyUse
    l_hValues["Fk_Enumeration"]     := l_iColumnFk_Enumeration
    l_hValues["ExternalId"]         := l_iColumnExternalId

    CustomFieldsFormToHash(par_iApplicationPk,USEDON_COLUMN,@l_hValues)

    l_cHtml += ColumnEditFormBuild(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData,l_cErrorMessage,l_iColumnPk,l_hValues)

case empty(l_iColumnPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                     PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+"/"+;
                                                                     PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +"/";
                                                                     )

otherwise

    //Since the Name could have change the redirect URL has to be re-evaluated.
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("b74fe317-938c-4ca8-8172-f69e73efd40b","Column")
        :Column("Namespace.Name"    ,"Namespace_Name")
        :Column("Namespace.AKA"     ,"Namespace_AKA")
        :Column("Namespace.LinkUID" ,"Namespace_LinkUID")
        :Column("Table.Name"        ,"Table_Name")
        :Column("Table.AKA"         ,"Table_AKA")
        :Column("Table.LinkUID"     ,"Table_LinkUID")
        :Column("Column.Name"       ,"Column_Name")
        :Column("Column.AKA"        ,"Column_AKA")
        :Column("Column.LinkUID"    ,"Column_LinkUID")
        :Join("inner","Table"    ,"","Column.fk_Table = Table.pk")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        l_oData := l_oDB1:Get(l_iColumnPk)
        if l_oDB1:Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+[DataDictionaries/EditColumn/]+par_cURLApplicationLinkCode+"/"+;
                                                                            PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+"/"+;
                                                                            PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +"/"+;
                                                                            PrepareForURLSQLIdentifier("Column"   ,l_oData:Column_Name   ,l_oData:Column_LinkUID)   +"/";
                                                                            )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                             PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+"/"+;
                                                                             PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +"/";
                                                                             )
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function IndexListFormBuild(par_iApplicationPk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfIndexes
local l_oDB_ListOfColumns
local l_cURL
local l_cName
local l_nColspan
local l_lWarnings := .f.
local l_cCombinedPath

oFcgi:TraceAdd("IndexListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("0154af03-a45d-4a8a-811f-c45d09da73f7","Index")
    :Column("Index.pk"             ,"pk")
    :Column("Index.Name"           ,"Index_Name")
    :Column("Index.LinkUID"        ,"Index_LinkUID")
    :Column("Index.UsedBy"         ,"Index_UsedBy")
    :Column("Index.Expression"     ,"Index_Expression")
    :Column("Index.Unique"         ,"Index_Unique")
    :Column("Index.Algo"           ,"Index_Algo")
    :Column("Index.UseStatus"      ,"Index_UseStatus")
    :Column("Index.DocStatus"      ,"Index_DocStatus")
    :Column("Index.Description"    ,"Index_Description")
    :Column("Index.TestWarning"    ,"Index_TestWarning")
    :Column("upper(Index.Name)"    ,"tag1")
    :Where("Index.fk_Table = ^",par_iTablePk)
    :OrderBy("tag1")
    :SQL("ListOfIndexes")
    l_nNumberOfIndexes := :Tally

    // ExportTableToHtmlFile("ListOfIndexes",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfIndexes.html","From PostgreSQL",,25,.t.)

endwith

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+[/]+;
                   PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +[/]

AssembleNavbarInfo("Add",{"Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_AKA,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_AKA    ,par_oNavData:Table_LinkUID}    )

if l_nNumberOfIndexes > 0
    select ListOfIndexes
    scan all while !l_lWarnings
        if !empty(nvl(ListOfIndexes->Index_TestWarning,""))
            l_lWarnings := .t.
        endif
    endscan

    l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB_ListOfColumns
        :Table("0c885ec3-553e-438a-846f-59fc8906d149","Index")
        :Where("Index.fk_Table = ^",par_iTablePk)
        :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
        :Join("inner","Column"     ,"","IndexColumn.fk_Column = Column.pk")
        :Column("Index.pk"     , "Index_pk")
        :Column("Column.Name"  , "Column_Name")
        :Column("Column.AKA"   , "Column_AKA")
        :Column("Column.Order" , "Column_Order")
        :OrderBy("Index_pk")
        :OrderBy("Column_Order")
        :SQL("ListOfColumns")
    endwith

endif

l_cHtml += GetAboveNavbarHeading("Indexes","Table",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
        l_cHtml += GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTablePk,"ListIndexes")
        l_cHtml += GetTableExtendedButtonRelatedOnEditForm("Index",par_iTablePk,l_cCombinedPath)
    l_cHtml += [</div><div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 5
            l_cHtml += GetButtonOnEditFormNew("New Index",l_cSitePath+[DataDictionaries/NewIndex/]+l_cCombinedPath)
        endif

    l_cHtml += [</div>]
l_cHtml += [</nav>]


if l_nNumberOfIndexes <= 0
    l_cHtml += GetNoRecordsOnFile("No Index on file.")

else
    l_cHtml += [<div class="alert alert-warning">Only define indexes that are not used on Primary and Foreign Keys, of type Integer, Integer Big or UUID.</div>]   //Spacer

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_nColspan := 8
            if l_lWarnings
                l_nColspan++
            endif

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-center text-white" colspan="]+trans(l_nColspan)+[">]
                    l_cHtml += [Indexes (]+Trans(l_nNumberOfIndexes)+[) for Table "]+TextToHtml(par_oNavData:Namespace_Name+FormatAKAForDisplay(par_oNavData:Namespace_AKA)+[.]+par_oNavData:Table_Name+FormatAKAForDisplay(par_oNavData:Table_AKA))+["]
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Expression</th>]
                l_cHtml += [<th class="text-white">Unique</th>]
                l_cHtml += [<th class="text-white">Algo</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                // l_cHtml += [<th class="text-white text-center">Used By</th>]
                l_cHtml += [<th class="text-white text-center">Columns</th>]
                if l_lWarnings
                    l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfIndexes
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfIndexes->Index_UseStatus)+[>]

                    // Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cURL  := l_cSitePath+[DataDictionaries/EditIndex/]+l_cCombinedPath+PrepareForURLSQLIdentifier("Index",alltrim(ListOfIndexes->Index_Name),ListOfIndexes->Index_LinkUID)
                        l_cName := alltrim(ListOfIndexes->Index_Name)
                        if ListOfIndexes->Index_UsedBy <> USEDBY_ALLSERVERS
                            l_cURL  += [:]+trans(ListOfIndexes->Index_UsedBy)
                            l_cName += [ (]+GetItemInListAtPosition(ListOfIndexes->Index_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
                        endif
                        l_cHtml += [<a href="]+l_cURL+[/">]+l_cName+[</a>]
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
                        l_cHtml += {"BTREE"}[iif(el_between(ListOfIndexes->Index_Algo,1,1),ListOfIndexes->Index_Algo,1)]
                        // 1 = BTREE
                    l_cHtml += [</td>]

                    // Description
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfIndexes->Index_Description,""))
                    l_cHtml += [</td>]

                    // Usage Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfIndexes->Index_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfIndexes->Index_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    // Doc Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfIndexes->Index_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfIndexes->Index_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                    // Columns
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        select ListOfColumns
                        scan all for ListOfColumns->Index_pk = ListOfIndexes->pk
                            l_cHtml += [<div>]+TextToHTML(ListOfColumns->Column_Name+FormatAKAForDisplay(ListOfColumns->Column_AKA))+[</div>]
                        endscan
                    l_cHtml += [</td>]

                    if l_lWarnings
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfIndexes->Index_TestWarning,""))
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
static function IndexEditFormBuild(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_nUsedBy      := hb_HGetDef(par_hValues,"UsedBy",USEDBY_ALLSERVERS)
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus   := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_lUnique      := hb_HGetDef(par_hValues,"Unique",.f.)
local l_cExpression  := nvl(hb_HGetDef(par_hValues,"Expression",""),"")
local l_nAlgo        := hb_HGetDef(par_hValues,"Algo",0)
local l_CheckBoxId
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cCombinedPath
local l_cSitePath := oFcgi:p_cSitePath

oFcgi:TraceAdd("IndexEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+[/]+;
                   PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +[/]

AssembleNavbarInfo("Add",{"Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_AKA,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_AKA    ,par_oNavData:Table_LinkUID})

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Index","Table",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += GetNextPreviousIndex(par_iTablePk,l_cCombinedPath,par_iPk)

        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Index",l_cSitePath+[DataDictionaries/NewIndex/]+l_cCombinedPath)
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(par_iPk)
    l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used By</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUsedBy" id="ComboUsedBy"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedBy==1,[ selected],[])+[>All Servers</option>]
            l_cHtml += [<option value="2"]+iif(l_nUsedBy==2,[ selected],[])+[>MySQL Only</option>]
            l_cHtml += [<option value="3"]+iif(l_nUsedBy==3,[ selected],[])+[>PostgreSQL Only</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Expression</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextExpression" id="TextExpression" value="]+FcgiPrepFieldForValue(l_cExpression)+[" maxlength="2704" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Unique</td>]
        l_cHtml += [<td class="pb-3">]
            // l_cHtml += [<div class="form-check form-switch">]
            // l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckUnique" id="CheckUnique" value="1"]+iif(l_lUnique," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            // l_cHtml += [</div>]

            l_cHtml += GetCheckboxOnEditForm("CheckUnique",l_lUnique,,(oFcgi:p_nAccessLevelDD < 5))

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Algo</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboAlgo" id="ComboAlgo"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nAlgo==1,[ selected],[])+[>BTREE</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
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
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

with Object l_oDB1
    :Table("ff07a071-c32f-48fb-98cc-a49b13e73239","Column")
    :Column("Column.pk"    ,"pk")
    :Column("Column.Name"  ,"Column_Name")
    :Column("Column.AKA"   ,"Column_AKA")
    :Column("Column.Order" ,"Column_Order")
    :Where("Column.fk_Table = ^",par_iTablePk)
    :OrderBy("Column_Order")
    :SQL("ListOfAllColumns")
    if :Tally > 0
        
        l_cHtml += [<div class="m-3"></div>]

        l_cHtml += [<div class="ms-3"><span>Filter on Column Name</span><input type="text" id="ColumnSearch" value="" size="40" class="ms-2"><span class="ms-3"> (Press Enter)</span></div>]

        l_cHtml += [<div class="m-3"></div>]

        oFcgi:p_cjQueryScript += 'function KeywordSearch(par_cListOfWords, par_cString) {'
        oFcgi:p_cjQueryScript += '  const l_aWords_upper = par_cListOfWords.toUpperCase().split(" ").filter(Boolean);'
        oFcgi:p_cjQueryScript += '  const l_cString_upper = par_cString.toUpperCase();'
        oFcgi:p_cjQueryScript += '  var l_lAllWordsIncluded = true;'
        oFcgi:p_cjQueryScript += '  for (var i = 0; i < l_aWords_upper.length; i++) {'
        oFcgi:p_cjQueryScript += '    if (!l_cString_upper.includes(l_aWords_upper[i])) {l_lAllWordsIncluded = false;break;};'
        oFcgi:p_cjQueryScript += '  }'
        oFcgi:p_cjQueryScript += '  return l_lAllWordsIncluded;'
        oFcgi:p_cjQueryScript += '}'

        oFcgi:p_cjQueryScript += [$("#ColumnSearch").change(function() {]
        oFcgi:p_cjQueryScript +=    [var l_keywords =  $(this).val();]
        oFcgi:p_cjQueryScript +=    [$(".SPANTable").each(function (par_SpanTable){]+;
                                                                                [var l_cColumnName = $(this).text();]+;
                                                                                [if (KeywordSearch(l_keywords,l_cColumnName)) {$(this).parent().parent().show();} else {$(this).parent().parent().hide();}]+;
                                                                                [});]
        oFcgi:p_cjQueryScript += [});]

        l_cHtml += [<div class="form-check form-switch">]
        l_cHtml += [<table class="ms-5">]
        select ListOfAllColumns
        scan all
            l_CheckBoxId := "CheckColumn"+Trans(ListOfAllColumns->pk)
            l_cHtml += [<tr><td>]
                l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif( hb_HGetDef(par_hValues,"Column"+Trans(ListOfAllColumns->pk),.f.)," checked","")+[ class="form-check-input">]
                l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+["><span class="SPANTable">]+TextToHtml(ListOfAllColumns->Column_Name+FormatAKAForDisplay(ListOfAllColumns->Column_AKA))
                l_cHtml += [</span></label>]
            l_cHtml += [</td></tr>]
        endscan
        l_cHtml += [</table>]
        l_cHtml += [</div>]

    endif
endwith

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function IndexEditFormOnSubmit(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_iIndexPk
local l_cName
local l_nUsedBy
local l_nUseStatus
local l_nDocStatus
local l_cDescription
local l_cExpression
local l_lUnique
local l_nAlgo
local l_hValues := {=>}

local l_cErrorMessage := ""
local l_oDB1
local l_oDB_ListOfAllColumns
local l_oData

oFcgi:TraceAdd("IndexEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iIndexPk     := Val(oFcgi:GetInputValue("TableKey"))

// l_cName        := SanitizeInputSQLIdentifier("Index",oFcgi:GetInputValue("TextName"))
l_cName        := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))

l_nUsedBy      := Val(oFcgi:GetInputValue("ComboUsedBy"))
l_nUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nDocStatus   := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_lUnique      := (oFcgi:GetInputValue("CheckUnique") == "1")
l_cExpression  := SanitizeInput(oFcgi:GetInputValue("TextExpression"))
l_nAlgo        := Val(oFcgi:GetInputValue("ComboAlgo"))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelDD >= 5
        do case
        case empty(l_cName)
            l_cErrorMessage := "Missing Name"
        case empty(l_cExpression)
            l_cErrorMessage := "Missing Expression"
        otherwise
            with object l_oDB1
                :Table("75c5e6db-efdb-4273-b35b-8ea1bfcf31e3","Index")
                :Column("Index.pk","pk")
                :Where([Index.fk_Table = ^],par_iTablePk)
                :Where([lower(replace(Index.Name,' ','')) = ^],lower(StrTran(l_cName," ","")))
                if l_iIndexPk > 0
                    :Where([Index.pk != ^],l_iIndexPk)
                endif
                :SQL()
//SendToClipboard(:LastSQL())
            endwith
            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endcase
    endif

    if empty(l_cErrorMessage)
        //Save the Index
        with object l_oDB1
            :Table("96801344-ac57-4b74-87e7-fd50ffab7c01","Index")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("Index.Name"      ,l_cName)
                :Field("Index.UsedBy"    ,l_nUsedBy)
                :Field("Index.UseStatus" ,l_nUseStatus)
                :Field("Index.Unique"    ,l_lUnique)
                :Field("Index.Expression",iif(empty(l_cExpression),NULL,l_cExpression))
                :Field("Index.Algo"      ,l_nAlgo)
            endif
            :Field("Index.DocStatus"     ,l_nDocStatus)
            :Field("Index.Description"   ,iif(empty(l_cDescription),NULL,l_cDescription))
        
            if empty(l_iIndexPk)
                :Field("Index.fk_Table",par_iTablePk)
                :Field("Index.LinkUID" ,oFcgi:p_o_SQLConnection:GetUUIDString())
                if :Add()
                    l_iIndexPk := :Key()
                else
                    l_cErrorMessage := "Failed to add Index."
                endif
            else
                if !:Update(l_iIndexPk)
                    l_cErrorMessage := "Failed to update Index."
                endif
            endif

            if empty(l_cErrorMessage)
                l_oDB_ListOfAllColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
                with Object l_oDB_ListOfAllColumns
                    :Table("f2fcfdfc-672f-4bd3-8830-1a2764048dd5","Column")
                    :Column("Column.pk"    ,"pk")
                    :Column("Column.Name"  ,"Column_Name")
                    :Where("Column.fk_Table = ^",par_iTablePk)
                    :Join("left","IndexColumn","","IndexColumn.fk_Column = Column.pk and IndexColumn.fk_Index = ^" , l_iIndexPk)
                    :Column("IndexColumn.pk" , "IndexColumn_pk")
                    :SQL("ListOfAllColumns")
                    select ListOfAllColumns
                    scan all
                        if (oFcgi:GetInputValue("CheckColumn"+Trans(ListOfAllColumns->pk)) == "1")  // No need to store the unselect references, since not having a reference will mean "not selected"
                            if hb_IsNil(ListOfAllColumns->IndexColumn_pk)
                                //Add record
                                with object l_oDB1
                                    :Table("020be7d2-9315-4c82-a6ee-e5d2f6b3468d","IndexColumn")
                                    :Field("IndexColumn.fk_Column",ListOfAllColumns->pk)
                                    :Field("IndexColumn.fk_Index" ,l_iIndexPk)
                                    :Add()
                                endwith
                            endif
                        else
                            if !hb_IsNil(ListOfAllColumns->IndexColumn_pk)
                                //Delete record
                                l_oDB1:Delete("6fce5aa4-fd44-4760-8baa-30f92495a42e","IndexColumn",ListOfAllColumns->IndexColumn_pk)
                            endif
                        endif
                    endscan
                endwith
            endif

            // if empty(l_cErrorMessage)
            //     l_iIndexPk := 0
            // endif

        endwith

        DataDictionaryFixAndTest(par_iApplicationPk)

    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iIndexPk := 0

case l_cActionOnSubmit == "Delete"   // Index
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("5bc09f54-4a06-4a1a-b2ee-b1be81275856","IndexColumn")
            :Column("IndexColumn.pk","pk")
            :Where("IndexColumn.fk_Index = ^",l_iIndexPk)
            :SQL("ListOfRecordsToDelete")

            if l_oDB1:Tally >= 0
                select ListOfRecordsToDelete
                scan all
                    :Delete("8b6d4b8e-5800-482e-87d4-a00246e2c7e5","IndexColumn",ListOfRecordsToDelete->pk)
                endscan

                :Delete("3ae994e1-b216-4869-b884-b372e5e24c2f","Index",l_iIndexPk)

                DataDictionaryFixAndTest(par_iApplicationPk)
                l_iIndexPk := 0

            else
                l_cErrorMessage := "Unable to find related columns."

            endif
        endwith
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cName
    l_hValues["UsedBy"]          := l_nUsedBy
    l_hValues["UseStatus"]       := l_nUseStatus
    l_hValues["DocStatus"]       := l_nDocStatus
    l_hValues["Description"]     := l_cDescription
    l_hValues["Expression"]      := l_cExpression
    l_hValues["Algo"]            := l_nAlgo
    l_hValues["Unique"]          := l_lUnique

    l_oDB_ListOfAllColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
    with Object l_oDB_ListOfAllColumns
        :Table("31a72c88-f5a5-4612-89d6-fbb407bf3ba3","Column")
        :Column("Column.pk"    ,"pk")
        :Column("Column.Name"  ,"Column_Name")
        :Where("Column.fk_Table = ^",par_iTablePk)
        :SQL("ListOfAllColumns")
        select ListOfAllColumns
        scan all
            if (oFcgi:GetInputValue("CheckColumn"+Trans(ListOfAllColumns->pk)) == "1")  // No need to store the unselect references, since not having a reference will mean "not selected"
                l_hValues["Column"+Trans(ListOfAllColumns->pk)] := .t.
            endif
        endscan
    endwith

    l_cHtml += IndexEditFormBuild(par_iApplicationPk,par_iNamespacePk,par_iTablePk,par_cURLApplicationLinkCode,par_oNavData,l_cErrorMessage,l_iIndexPk,l_hValues)

case empty(l_iIndexPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListIndexes/"+par_cURLApplicationLinkCode+"/"+;
                                                                     PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+"/"+;
                                                                     PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +"/";
                                                                     )

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("c4b21f9e-b53d-4c50-b9f6-869e30fb6c2e","Index")
        :Column("Namespace.Name"    ,"Namespace_Name")
        :Column("Namespace.AKA"     ,"Namespace_AKA")
        :Column("Namespace.LinkUID" ,"Namespace_LinkUID")
        :Column("Table.Name"        ,"Table_Name")
        :Column("Table.AKA"         ,"Table_AKA")
        :Column("Table.LinkUID"     ,"Table_LinkUID")
        :Column("Index.Name"        ,"Index_Name")
        :Column("Index.LinkUID"     ,"Index_LinkUID")
        :Join("inner","Table"    ,"","Index.fk_Table = Table.pk")
        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
        l_oData := l_oDB1:Get(l_iIndexPk)
        if l_oDB1:Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditIndex/"+par_cURLApplicationLinkCode+"/"+;
                                                                           PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+"/"+;
                                                                           PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +"/"+;
                                                                           PrepareForURLSQLIdentifier("Index"    ,l_oData:Index_Name    ,l_oData:Index_LinkUID)    +"/";
                                                                           )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListIndexes/"+par_cURLApplicationLinkCode+"/"+;
                                                                             PrepareForURLSQLIdentifier("Namespace",par_oNavData:Namespace_Name,par_oNavData:Namespace_LinkUID)+"/"+;
                                                                             PrepareForURLSQLIdentifier("Table"    ,par_oNavData:Table_Name    ,par_oNavData:Table_LinkUID)    +"/";
                                                                             )
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumerationListFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_nSearchMode
local l_cSearchEnumerationName
local l_cSearchEnumerationDescription
local l_cSearchEnumValueName
local l_cSearchEnumValueDescription
local l_cSearchNamespaceName
local l_cSearchNamespaceDescription
local l_cSearchEnumerationUsageStatus
local l_cSearchEnumerationDocStatus
local l_cSearchEnumValueUsageStatus
local l_cSearchEnumValueDocStatus
local l_cSearchEnumerationImplementAs
local l_cSearchExtraFilters
local l_cURL

oFcgi:TraceAdd("EnumerationListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_nSearchMode                   := min(3,max(1,val(oFcgi:GetInputValue("RadioSearchMode"))))
l_cSearchNamespaceName          := SanitizeInput(oFcgi:GetInputValue("TextSearchNamespaceName"))
l_cSearchNamespaceDescription   := SanitizeInput(oFcgi:GetInputValue("TextSearchNamespaceDescription"))
l_cSearchEnumerationName        := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationName"))
l_cSearchEnumerationDescription := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationDescription"))
l_cSearchEnumValueName          := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumValueName"))
l_cSearchEnumValueDescription   := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumValueDescription"))
l_cSearchEnumerationUsageStatus := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationUsageStatus"))
l_cSearchEnumerationDocStatus   := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationDocStatus"))
l_cSearchEnumValueUsageStatus   := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumValueUsageStatus"))
l_cSearchEnumValueDocStatus     := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumValueDocStatus"))
l_cSearchEnumerationImplementAs := SanitizeInput(oFcgi:GetInputValue("TextSearchEnumerationImplementAs"))
l_cSearchExtraFilters           := SanitizeInput(oFcgi:GetInputValue("TextSearchExtraFilters"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_Mode"                  ,trans(l_nSearchMode))
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceName"         ,l_cSearchNamespaceName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceDescription"  ,l_cSearchNamespaceDescription)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationName"       ,l_cSearchEnumerationName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDescription",l_cSearchEnumerationDescription)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueName"         ,l_cSearchEnumValueName)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDescription"  ,l_cSearchEnumValueDescription)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationUsageStatus",l_cSearchEnumerationUsageStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDocStatus"  ,l_cSearchEnumerationDocStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueUsageStatus"  ,l_cSearchEnumValueUsageStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDocStatus"    ,l_cSearchEnumValueDocStatus)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationImplementAs",l_cSearchEnumerationImplementAs)
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_ExtraFilters"          ,l_cSearchExtraFilters)

    l_cHtml += EnumerationListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

case l_cActionOnSubmit == "Reset"
    // SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_Mode"                ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceName"         ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceDescription"  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationName"       ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDescription","")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueName"         ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDescription"  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationUsageStatus","")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDocStatus"  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueUsageStatus"  ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDocStatus"    ,"")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationImplementAs","")
    SaveUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_ExtraFilters"          ,"")

    l_cURL := oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += EnumerationListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

endcase

return l_cHtml
//=================================================================================================================
static function EnumerationListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB_ListOfEnumerations                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumerationsEnumValueCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfReferencedByCounts          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPreviousName                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nCountProposed
local l_nCount
local l_nCountDiscontinued
local l_nNumberOfEnumerations

local l_nSearchMode
local l_ScriptFolder

local l_cSearchNamespaceName
local l_cSearchNamespaceDescription
local l_cSearchEnumerationName
local l_cSearchEnumerationDescription
local l_cSearchValueName
local l_cSearchValueDescription

local l_cSearchEnumerationUsageStatus
local l_cSearchEnumerationDocStatus
local l_cSearchEnumValueUsageStatus
local l_cSearchEnumValueDocStatus
local l_cSearchEnumerationImplementAs

local l_cSearchExtraFilters
local l_json_ExtraFilters

local l_lWarnings := .f.
local l_lHasExternalId :=.f.

local l_cLine
local l_nMaxWidth
local l_lExtraInfo

local l_nColspan

oFcgi:TraceAdd("EnumerationListFormBuild")

l_nSearchMode                   := min(3,max(1,val(GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_Mode"))))

l_cSearchNamespaceName          := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceName")
l_cSearchNamespaceDescription   := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_NamespaceDescription")
l_cSearchEnumerationName        := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationName")
l_cSearchEnumerationDescription := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDescription")
l_cSearchValueName              := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueName")
l_cSearchValueDescription       := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDescription")
l_cSearchEnumerationUsageStatus := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationUsageStatus")
l_cSearchEnumerationDocStatus   := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationDocStatus")
l_cSearchEnumValueUsageStatus   := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueUsageStatus")
l_cSearchEnumValueDocStatus     := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumValueDocStatus")
l_cSearchEnumerationImplementAs := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_EnumerationImplementAs")
l_cSearchExtraFilters           := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_EnumerationSearch_ExtraFilters")

with object l_oDB_ListOfEnumerations
    :Table("a969a3ec-01a9-4aa5-b9f8-d9bd7b1005e7","Enumeration")
    :Column("Enumeration.pk"             ,"pk")
    :Column("Namespace.Name"             ,"Namespace_Name")
    :Column("Namespace.AKA"              ,"Namespace_AKA")
    :Column("Namespace.LinkUID"          ,"Namespace_LinkUID")
    :Column("Enumeration.Name"           ,"Enumeration_Name")
    :Column("Enumeration.AKA"            ,"Enumeration_AKA")
    :Column("Enumeration.LinkUID"        ,"Enumeration_LinkUID")
    :Column("Enumeration.UseStatus"      ,"Enumeration_UseStatus")
    :Column("Enumeration.DocStatus"      ,"Enumeration_DocStatus")
    :Column("Enumeration.Description"    ,"Enumeration_Description")
    :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
    :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")
    :Column("Enumeration.TestWarning"    ,"Enumeration_TestWarning")
    :Column("Enumeration.ExternalId"     ,"Enumeration_ExternalId")
    :Column("Upper(Namespace.Name)","tag1")
    :Column("Upper(Enumeration.Name)","tag2")
    :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)

    EnumerationListFormAddFiltering(l_oDB_ListOfEnumerations,;
                                    l_nSearchMode,;
                                    l_cSearchNamespaceName,;
                                    l_cSearchNamespaceDescription,;
                                    l_cSearchEnumerationName,;
                                    l_cSearchEnumerationDescription,;
                                    l_cSearchValueName,;
                                    l_cSearchValueDescription,;
                                    l_cSearchEnumerationUsageStatus,;
                                    l_cSearchEnumerationDocStatus,;
                                    l_cSearchEnumValueUsageStatus,;
                                    l_cSearchEnumValueDocStatus,;
                                    l_cSearchEnumerationImplementAs,;
                                    l_cSearchExtraFilters;
                                    )

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfEnumerations")
    l_nNumberOfEnumerations := :Tally
endwith

if l_nNumberOfEnumerations > 0
    select ListOfEnumerations
    scan all while !l_lWarnings .or. !l_lHasExternalId
        if !empty(nvl(ListOfEnumerations->Enumeration_TestWarning,""))
            l_lWarnings := .t.
        endif
        if nvl(ListOfEnumerations->Enumeration_ExternalId,0) > 0
            l_lHasExternalId := .t.
        endif
    endscan

    with object l_oDB_ListOfPreviousName
        :Table("f84b2474-5a3f-49e9-8f7a-bdcb559a2730","Enumeration")
        :Column("Enumeration.pk"                  ,"pk")
        :Column("EnumerationPreviousName.pk"      ,"PreviousName_pk")   //Will use the pk to order, since it is incremental
        :Column("EnumerationPreviousName.Name"    ,"PreviousName_Name")
        :Join("inner","EnumerationPreviousName","","EnumerationPreviousName.fk_Enumeration = Enumeration.pk")
        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :SQL("ListOfPreviousName")
        with object :p_oCursor
            :Index("tag1","alltrim(str(pk))+'*'+str(9999999999-PreviousName_pk,10)")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfEnumerationsEnumValueCounts
        :Table("0a20a86a-a519-451c-a01b-388f16a4c909","Enumeration")
        :Column("Enumeration.pk" ,"Enumeration_pk")
        // :Column("Count(*)" ,"EnumValueCount")

        :Column("SUM(CASE WHEN EnumValue.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )"                                          ,"EnumValueCountProposed")
        :Column("SUM(CASE WHEN EnumValue.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"EnumValueCount")
        :Column("SUM(CASE WHEN EnumValue.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )"                                      ,"EnumValueCountDiscontinued")

        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Enumeration_pk")
        :SQL("ListOfEnumerationsEnumValueCounts")
        with object :p_oCursor
            :Index("tag1","Enumeration_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfReferencedByCounts
        :Table("5322e123-b074-4173-a59d-ef848e3e30fc","Enumeration")
        :Column("Enumeration.pk" ,"Enumeration_pk")
        // :Column("Count(*)" ,"ColumnCount")

        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_PROPOSED)+" THEN 1 ELSE 0 END )"                                          ,"ColumnCountProposed")
        :Column("SUM(CASE WHEN Column.UseStatus NOT IN ("+trans(USESTATUS_PROPOSED)+","+trans(USESTATUS_DISCONTINUED)+") THEN 1 ELSE 0 END )" ,"ColumnCount")
        :Column("SUM(CASE WHEN Column.UseStatus = "+trans(USESTATUS_DISCONTINUED)+" THEN 1 ELSE 0 END )"                                      ,"ColumnCountDiscontinued")

        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_Enumeration = Enumeration.pk and trim(Column.type) = 'E'")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :GroupBy("Enumeration_pk")
        :SQL("ListOfReferencedByCounts")
        with object :p_oCursor
            :Index("tag1","Enumeration_pk")
            :CreateIndexes()
        endwith
    endwith

endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="PageLoaded" id="PageLoaded" value="0">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_ScriptFolder := l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

l_json_ExtraFilters :=  [{tag:'Warning',value:'WNG'}]

oFcgi:p_cjQueryScript += "$('#PageLoaded').val('1');"

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 150px;} ]
l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
l_cHtml += [</style>]

l_cHtml += [<script type="text/javascript">]
l_cHtml += [function SearchModeChanged(par_nSearchMode)]
l_cHtml += [{]
    l_cHtml += [switch (par_nSearchMode) {]
    l_cHtml += [case 1:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").hide();$(".SearchMode3").hide();]
    l_cHtml += [   break;]
    l_cHtml += [case 2:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").show();$(".SearchMode3").hide();]
    l_cHtml += [   break;]
    l_cHtml += [case 3:]
    l_cHtml += [   $(".SearchMode1").show();$(".SearchMode2").show();$(".SearchMode3").show();]
    l_cHtml += [   break;]
    l_cHtml += [default:]
    l_cHtml += [   console.log(`Sorry, we are out of ${expr}.`);]
    l_cHtml += [};return true;]
l_cHtml += [}]

l_cHtml += [function SaveSearchMode(par_nSearchMode)]
l_cHtml += [{]
    l_cHtml += [$.ajax({]
    l_cHtml += [  type: 'GET',]
    l_cHtml += [  url: ']+l_cSitePath+[ajax/SaveSearchModeEnumeration',]
    l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&SearchMode='+par_nSearchMode,]
    l_cHtml += [  cache: false ]
    l_cHtml += [});]
    l_cHtml += [return true;]
l_cHtml += [}]
l_cHtml += [</script>]

l_cHtml += GetCopyToClipboardJavaScript("CopyRoster")

l_cHtml += [<pre id="PreEnumerationsToClipboard" style="display:none;">]
    select ListOfEnumerations
    l_nMaxWidth  := 0
    l_lExtraInfo := .f.

    scan all
        l_nMaxWidth := max(l_nMaxWidth,len(ListOfEnumerations->Enumeration_Name))
        if ListOfEnumerations->Enumeration_UseStatus = USESTATUS_PROPOSED .or. ;
           ListOfEnumerations->Enumeration_UseStatus = USESTATUS_DISCONTINUED
            l_lExtraInfo := .t.
        endif
    endscan

    scan all
        if !l_lExtraInfo
            l_cLine := ListOfEnumerations->Enumeration_Name

        else
            l_cLine := padr(ListOfEnumerations->Enumeration_Name,l_nMaxWidth)

            do case
            case ListOfEnumerations->Enumeration_UseStatus = USESTATUS_PROPOSED
                l_cLine += [ (Proposed)]
            case ListOfEnumerations->Enumeration_UseStatus = USESTATUS_DISCONTINUED
                l_cLine += [ (Discontinued)]
            endcase

        endif

        l_cHtml += l_cLine+CRLF
    endscan

l_cHtml += [</pre>]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group mb-3">]

        if oFcgi:p_nAccessLevelDD >= 5
            l_cHtml += GetButtonOnEditFormNew("New Enumeration",l_cSitePath+[DataDictionaries/NewEnumeration/]+par_cURLApplicationLinkCode+[/])
        endif

        l_cHtml += [<input type="button" role="button" value="Copy Enumeration List To Clipboard" class="btn btn-primary rounded ms-3" id="CopyRoster" onclick="]
        l_cHtml += [copyToClip(document.getElementById('PreEnumerationsToClipboard').innerText);return false;">]

    l_cHtml += [</div><div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<span class="ms-3"></span>]  //To make some spacing
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td valign="top">]
                    l_cHtml += [<table>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td></td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode2">]
                            l_cHtml += [<td><span class="me-2">Namespace</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchNamespaceName" id="TextSearchNamespaceName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchNamespaceName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchNamespaceDescription" id="TextSearchNamespaceDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchNamespaceDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode1">]
                            l_cHtml += [<td><span class="me-2">Enumeration</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumerationName" id="TextSearchEnumerationName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEnumerationName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumerationDescription" id="TextSearchEnumerationDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEnumerationDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode2">]
                            l_cHtml += [<td><span class="me-2">Value</span></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumValueName" id="TextSearchEnumValueName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchValueName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextSearchEnumValueDescription" id="TextSearchEnumValueDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchValueDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Enumeration Usage Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchEnumerationUsageStatus",;
                                                                   "{tag:'Unknown',value:1},{tag:'Proposed',value:2},{tag:'Under Development',value:3},{tag:'Active',value:4},{tag:'To Be Discontinued',value:5},{tag:'Discontinued',value:6}",;
                                                                   l_cSearchEnumerationUsageStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Enumeration Doc Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchEnumerationDocStatus",;
                                                                   "{tag:'Missing',value:1},{tag:'Not Needed',value:2},{tag:'Composing',value:3},{tag:'Completed',value:4}",;
                                                                   l_cSearchEnumerationDocStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Implemented As</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchEnumerationImplementAs",;
                                                                   "{tag:'SQL Enum',value:1},{tag:'Integer',value:2},{tag:'Numeric',value:3},{tag:'String',value:4}",;
                                                                   l_cSearchEnumerationImplementAs,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Value Usage Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchEnumValueUsageStatus",;
                                                                   "{tag:'Unknown',value:1},{tag:'Proposed',value:2},{tag:'Under Development',value:3},{tag:'Active',value:4},{tag:'To Be Discontinued',value:5},{tag:'Discontinued',value:6}",;
                                                                   l_cSearchEnumValueUsageStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Value Doc Status</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchEnumValueDocStatus",;
                                                                   "{tag:'Missing',value:1},{tag:'Not Needed',value:2},{tag:'Composing',value:3},{tag:'Completed',value:4}",;
                                                                   l_cSearchEnumValueDocStatus,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr class="SearchMode3">]
                            l_cHtml += [<td><span class="me-2">Extra Filters</span></td>]
                            l_cHtml += [<td colspan="2">]
                                l_cHtml += GetMultiFlagSearchInput("TextSearchExtraFilters",;
                                                                   l_json_ExtraFilters,;
                                                                   l_cSearchExtraFilters,25)
                            l_cHtml += [</td>]
                        l_cHtml += [</tr>]

                    l_cHtml += [</table>]
                l_cHtml += [</td>]

                oFcgi:p_cjQueryScript += [SearchModeChanged(]+trans(l_nSearchMode)+[);]   // Calling the Javascript function needs to be done after the amsifySuggestags objects are activated.

                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<div class="ms-3">]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio1" value="1" onchange="SearchModeChanged(1);SaveSearchMode(1);"]+iif(l_nSearchMode==1,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio1">Basic</label>]
                        l_cHtml += [</div>]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio2" value="2" onchange="SearchModeChanged(2);SaveSearchMode(2);"]+iif(l_nSearchMode==2,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio2">Standard</label>]
                        l_cHtml += [</div>]
                        l_cHtml += [<div class="form-check">]   // form-check-inline
                        l_cHtml +=    [<input class="form-check-input" type="radio" name="RadioSearchMode" id="SearchModeRadio3" value="3" onchange="SearchModeChanged(3);SaveSearchMode(3);"]+iif(l_nSearchMode==3,[ checked],[])+[>]
                        l_cHtml +=    [<label class="form-check-label" for="SearchModeRadio3">Advanced</label>]
                        l_cHtml += [</div>]
                    l_cHtml += [</div>]
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<div align="center" class="ms-3 me-5">]
                        l_cHtml += [<div><input type="submit" class="btn btn-primary rounded mb-2" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button"></div>]
                        l_cHtml += [<div><input type="button" class="btn btn-primary rounded" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button"></div>]
                    l_cHtml += [</div>]
                l_cHtml += [</td>]
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [</form>]

if !empty(l_nNumberOfEnumerations)
    l_nColspan := 8
    if l_lHasExternalId
        l_nColspan++
    endif
    if l_lWarnings
        l_nColspan++
    endif

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">] //  table-striped
            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+trans(l_nColspan)+[">Enumerations (]+Trans(l_nNumberOfEnumerations)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Namespace</th>]
                l_cHtml += [<th class="text-white">Enumeration Name</th>]
                l_cHtml += [<th class="text-white">Implemented As</th>]
                l_cHtml += [<th class="text-white">Values</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Referenced<br>By</th>]
                // l_cHtml += [<th class="text-white text-center">Warnings</th>]
                if l_lHasExternalId
                    l_cHtml += [<th class="text-white">External Id</th>]
                endif
                if l_lWarnings
                    // l_cHtml += [<th class="text-center ]+iif(l_lWarnings,"bg-warning text-danger","text-white")+[">Warning</th>]
                    l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                endif
            l_cHtml += [</tr>]
            select ListOfEnumerations
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfEnumerations->Enumeration_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(ListOfEnumerations->Namespace_Name+FormatAKAForDisplay(ListOfEnumerations->Namespace_AKA))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditEnumeration/]+par_cURLApplicationLinkCode+[/]+;
                                                                                               PrepareForURLSQLIdentifier("Namespace",ListOfEnumerations->Namespace_Name,ListOfEnumerations->Namespace_LinkUID)+[/]+;
                                                                                               PrepareForURLSQLIdentifier("Enumeration",ListOfEnumerations->Enumeration_Name,ListOfEnumerations->Enumeration_LinkUID)+[/]+;
                                                                                               [">]+ListOfEnumerations->Enumeration_Name+FormatAKAForDisplay(ListOfEnumerations->Enumeration_AKA)+[</a>]
                    
                        if el_seek(trans(ListOfEnumerations->pk)+'*',"ListOfPreviousName","tag1")
                            select ListOfPreviousName
                            scan while ListOfPreviousName->pk == ListOfEnumerations->pk
                                l_cHtml += [<div class="ps-1 small">Previously: ]+TextToHtml(ListOfPreviousName->PreviousName_Name)+[</div>]
                            endscan
                        endif
                    
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]+EnumerationImplementAsInfo(ListOfEnumerations->Enumeration_ImplementAs,ListOfEnumerations->Enumeration_ImplementLength)+[</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        // l_nCount := iif( el_seek(ListOfEnumerations->pk,"ListOfEnumerationsEnumValueCounts","tag1") , ListOfEnumerationsEnumValueCounts->EnumValueCount , 0)
                        // if l_nCount > 0
                        //     l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+;
                        //                                                                         PrepareForURLSQLIdentifier("Namespace",ListOfEnumerations->Namespace_Name,ListOfEnumerations->Namespace_LinkUID)+[/]+;
                        //                                                                         PrepareForURLSQLIdentifier("Enumeration",ListOfEnumerations->Enumeration_Name,ListOfEnumerations->Enumeration_LinkUID)+[/]+;
                        //                                                                         [">]+Trans(l_nCount)+[</a>]
                        // endif

                        if el_seek(ListOfEnumerations->pk,"ListOfEnumerationsEnumValueCounts","tag1")
                            l_nCountProposed     := ListOfEnumerationsEnumValueCounts->EnumValueCountProposed
                            l_nCount             := ListOfEnumerationsEnumValueCounts->EnumValueCount
                            l_nCountDiscontinued := ListOfEnumerationsEnumValueCounts->EnumValueCountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif
                        if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                PrepareForURLSQLIdentifier("Namespace",ListOfEnumerations->Namespace_Name,ListOfEnumerations->Namespace_LinkUID)+[/]+;
                                                                                                PrepareForURLSQLIdentifier("Enumeration",ListOfEnumerations->Enumeration_Name,ListOfEnumerations->Enumeration_LinkUID)+[/]+;
                                                                                                [">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                        endif

                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumerations->Enumeration_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfEnumerations->Enumeration_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfEnumerations->Enumeration_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfEnumerations->Enumeration_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfEnumerations->Enumeration_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  // Referenced By
                        // l_nCount := iif( el_seek(ListOfEnumerations->pk,"ListOfReferencedByCounts","tag1") , ListOfReferencedByCounts->ColumnCount , 0)
                        // if l_nCount > 0
                        //     l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EnumerationReferencedBy/]+par_cURLApplicationLinkCode+[/]+;
                        //                                                                                 PrepareForURLSQLIdentifier("Namespace",ListOfEnumerations->Namespace_Name,ListOfEnumerations->Namespace_LinkUID)+[/]+;
                        //                                                                                 PrepareForURLSQLIdentifier("Enumeration",ListOfEnumerations->Enumeration_Name,ListOfEnumerations->Enumeration_LinkUID)+[/]+;
                        //                                                                                 [">]+Trans(l_nCount)+[</a>]
                        // endif

                        if el_seek(ListOfEnumerations->pk,"ListOfReferencedByCounts","tag1")
                            l_nCountProposed     := ListOfReferencedByCounts->ColumnCountProposed
                            l_nCount             := ListOfReferencedByCounts->ColumnCount
                            l_nCountDiscontinued := ListOfReferencedByCounts->ColumnCountDiscontinued
                        else
                            l_nCountProposed     := 0
                            l_nCount             := 0
                            l_nCountDiscontinued := 0
                        endif
                        if l_nCountProposed+l_nCount+l_nCountDiscontinued > 0
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EnumerationReferencedBy/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                        PrepareForURLSQLIdentifier("Namespace",ListOfEnumerations->Namespace_Name,ListOfEnumerations->Namespace_LinkUID)+[/]+;
                                                                                                        PrepareForURLSQLIdentifier("Enumeration",ListOfEnumerations->Enumeration_Name,ListOfEnumerations->Enumeration_LinkUID)+[/]+;
                                                                                                        [">]+GetFormattedUseStatusCounts(l_nCountProposed,l_nCount,l_nCountDiscontinued)+[</a>]
                        endif

                    l_cHtml += [</td>]

                    if l_lHasExternalId
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="right">]
                            if nvl(ListOfEnumerations->Enumeration_ExternalId,0) > 0
                                l_cHtml += trans(ListOfEnumerations->Enumeration_ExternalId)
                            endif
                        l_cHtml += [</td>]
                    endif

                    if l_lWarnings
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumerations->Enumeration_TestWarning,""))
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
static function EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cSitePath := oFcgi:p_cSitePath
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_iNamespacePk      := hb_HGetDef(par_hValues,"Fk_Namespace",0)
local l_cName             := hb_HGetDef(par_hValues,"Name","")
local l_lTrackNameChanges := nvl(hb_HGetDef(par_hValues,"TrackNameChanges",.t.),.t.)
local l_cAKA              := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_nUseStatus        := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus        := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription      := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_iImplementAs      := nvl(hb_HGetDef(par_hValues,"ImplementAs",ENUMERATIONIMPLEMENTAS_NATIVESQLENUM),ENUMERATIONIMPLEMENTAS_NATIVESQLENUM)
local l_iImplementLength  := nvl(hb_HGetDef(par_hValues,"ImplementLength",1),1)
local l_iExternalId       := nvl(hb_HGetDef(par_hValues,"ExternalId",0),0)
local l_cCombinedPath

local l_oDataTableInfo
local l_oDataApplication
local l_oDB1
local l_lDisabled

oFcgi:TraceAdd("EnumerationEditFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1

    if !empty(par_iPk)
        :Table("fe972943-4a6c-4e04-b03a-5969abc9a8c6","Enumeration")
        :Column("Namespace.Name"     ,"Namespace_Name")
        :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
        :Column("Enumeration.Name"   ,"Enumeration_Name")
        :Column("Enumeration.LinkUID","Enumeration_LinkUID")
        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        l_oDataTableInfo := :Get(par_iPk)
    endif

    :Table("94c90d46-8456-40f3-95f8-eeff8481e1e3","Application")
    :Column("Application.NoNamespaceChangeOnTablesAndEnumerations","Application_NoNamespaceChangeOnTablesAndEnumerations")
    l_oDataApplication := :Get(par_iApplicationPk)

    :Table("e40fee2e-6e7e-4160-a6a8-c828ba3cf3ea","Namespace")
    :Column("Namespace.pk"         ,"pk")
    :Column("Namespace.Name"       ,"Namespace_Name")
    :Column("Namespace.AKA"        ,"Namespace_AKA")
    :Column("Upper(Namespace.Name)","tag1")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfNamespaces")

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
    l_cHtml += DisplayErrorMessageOnEditForm([You must setup at least one Namespace first]) //l_cErrorText

    l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Enumeration")

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += GetButtonOnEditForm("ButtonOk","Ok","Cancel")
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [</form>]

else
    l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

    l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Enumeration")

    if !empty(par_iPk)
        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                           PrepareForURLSQLIdentifier("Namespace"  ,l_oDataTableInfo:Namespace_Name  ,l_oDataTableInfo:Namespace_LinkUID)  +[/]+;
                           PrepareForURLSQLIdentifier("Enumeration",l_oDataTableInfo:Enumeration_Name,l_oDataTableInfo:Enumeration_LinkUID)+[/]
    endif

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
            l_cHtml += GetNextPreviousEnumeration(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,"EditEnumeration")
            if !empty(par_iPk)
                l_cHtml += GetEnumerationExtendedButtonRelatedOnEditForm("Edit",par_iPk,l_cCombinedPath)
            endif
        l_cHtml += [</div><div class="input-group">]
            if oFcgi:p_nAccessLevelDD >= 3
                l_cHtml += GetButtonOnEditFormSave()
            endif
            l_cHtml += GetButtonOnEditFormDoneCancel()
            if !empty(par_iPk)
                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += GetButtonOnEditFormDelete()
                    l_cHtml += GetConfirmationModalFormsDelete()

                    l_cHtml += GetButtonOnEditFormDuplicate()
                    l_cHtml += GetConfirmationModalFormsDuplicate("Values will also be duplicated.")
                endif
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    if !empty(par_iPk)
        l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
    endif

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]

        l_cHtml += [<table>]

        if !empty(par_iPk) .and. l_oDataApplication:Application_NoNamespaceChangeOnTablesAndEnumerations
            l_lDisabled := .t.
        else
            l_lDisabled := oFcgi:p_nAccessLevelDD < 5
        endif
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Namespace</td>]
            l_cHtml += [<td class="pb-3">]
                //Disabled Combo will not pass their selected item during a Post
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+iif(l_lDisabled,[ disabled],[ name="ComboNamespacePk" id="ComboNamespacePk"])+[>]
                select ListOfNamespaces
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfNamespaces->pk)+["]+iif(ListOfNamespaces->pk = l_iNamespacePk,[ selected],[])+[>]+FcgiPrepFieldForValue(ListOfNamespaces->Namespace_Name+FormatAKAForDisplay(ListOfNamespaces->Namespace_AKA))+[</option>]
                endscan
                l_cHtml += [</select>]
                if l_lDisabled
                    l_cHtml += [<input type="hidden" name="ComboNamespacePk" id="ComboNamespacePk" value="]+Trans(l_iNamespacePk)+[">]
                endif
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Enumeration Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += GetTrackNameChangesAndPreviousNamesEditFormBuild(l_lTrackNameChanges,"Enumeration",par_iPk)

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Implement As</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<span class="pe-5">]
                    l_cHtml += [<select name="ComboImplementAs" id="ComboImplementAs" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+[OnChangeImplementAs(this.value);']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                        l_cHtml += [<option value="1"]+iif(l_iImplementAs==1,[ selected],[])+[>SQL Enum</option>]
                        l_cHtml += [<option value="2"]+iif(l_iImplementAs==2,[ selected],[])+[>Integer</option>]
                        l_cHtml += [<option value="3"]+iif(l_iImplementAs==3,[ selected],[])+[>Numeric</option>]
                        l_cHtml += [<option value="4"]+iif(l_iImplementAs==4,[ selected],[])+[>String (EnumValue Name)</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="ImplementLengthEntry" style="display: none;">]
                l_cHtml += [<span class="pe-2">Length</span><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[size="5" maxlength="5" name="TextImplementLength" id="TextImplementLength" value="]+Trans(l_iImplementLength)+["]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
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
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                    l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        if !empty(l_iExternalId)
            l_cHtml += [<tr>]
                l_cHtml += [<td valign="top" class="pe-2 pb-3">External Id</td>]
                l_cHtml += [<td class="pb-3">]+trans(l_iExternalId)+[ (Created via API call)</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [</table>]

        l_cHtml += [<input type="hidden" name="TextExternalId" id="TextExternalId" value="]+trans(l_iExternalId)+[">]
        
    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextName').focus();]

    oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

    l_cHtml += [</form>]

endif

return l_cHtml
//=================================================================================================================
static function EnumerationEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumerationPk
local l_iNamespacePk
local l_cEnumerationName
local l_lEnumerationTrackNameChanges
local l_cEnumerationAKA
local l_iEnumerationUseStatus
local l_iEnumerationDocStatus
local l_cEnumerationDescription
local l_iEnumerationImplementAs
local l_iEnumerationImplementLength
local l_iEnumerationExternalId
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1
local l_oData
local l_lDuplicate
local l_cLinkUID
local l_cName
local l_nPos
local l_oDB_ListOfEnumValues

oFcgi:TraceAdd("EnumerationEditFormOnSubmit")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumerationPk                := Val(oFcgi:GetInputValue("EnumerationKey"))
l_iNamespacePk                  := Val(oFcgi:GetInputValue("ComboNamespacePk"))

l_cEnumerationName              := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_lEnumerationTrackNameChanges  := (oFcgi:GetInputValue("CheckTrackNameChanges") == "1")
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

l_iEnumerationExternalId := Val(oFcgi:GetInputValue("TextExternalId"))

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
                :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
                :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                :Where([Enumeration.fk_Namespace = ^],l_iNamespacePk)
                :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cEnumerationName," ","")))
                if l_iEnumerationPk > 0
                    :Where([Enumeration.pk != ^],l_iEnumerationPk)
                endif
                :SQL()
                l_lDuplicate := (:Tally <> 0)

                if !l_lDuplicate
                    :Table("c52ae692-4a7c-4a2a-90b0-b43d7ae5d403","Enumeration")
                    :Column("Enumeration.pk","pk")
                    :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
                    :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                    :Where([Enumeration.fk_Namespace = ^],l_iNamespacePk)
                    :Where([lower(replace(EnumerationPreviousName.Name,' ','')) = ^],lower(StrTran(l_cEnumerationName," ","")))
                    :Join("inner","EnumerationPreviousName","","EnumerationPreviousName.fk_Enumeration = Enumeration.pk")
                    if l_iEnumerationPk > 0
                        :Where([Enumeration.pk != ^],l_iEnumerationPk)
                    endif
                    :SQL()
                    l_lDuplicate := (:Tally <> 0)
                endif
            endwith

            if l_lDuplicate
                l_cErrorMessage := "Duplicate Name"
            endif
        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Enumeration
        with object l_oDB1
            l_cErrorMessage := TrackNameChange(l_oDB1,"Enumeration",l_iEnumerationPk,l_cEnumerationName,l_lEnumerationTrackNameChanges)
            if empty(l_cErrorMessage)
                RemovePreviousNameIfSelectedEditFormOnSubmit("Enumeration",l_iEnumerationPk)

                :Table("92372d16-01ca-41d7-8f45-d145a2ce3cdc","Enumeration")
                if oFcgi:p_nAccessLevelDD >= 5
                    if l_iNamespacePk > 0   // Needed in case of disabled Namespace dropdown
                        :Field("Enumeration.fk_Namespace",l_iNamespacePk)
                    endif
                    :Field("Enumeration.Name"            ,l_cEnumerationName)
                    :Field("Enumeration.TrackNameChanges",l_lEnumerationTrackNameChanges)
                    :Field("Enumeration.AKA"             ,l_cEnumerationAKA)
                    :Field("Enumeration.UseStatus"       ,l_iEnumerationUseStatus)
                    :Field("Enumeration.ImplementAs"     ,l_iEnumerationImplementAs)
                    :Field("Enumeration.ImplementLength" ,iif(el_IsInlist(l_iEnumerationImplementAs,ENUMERATIONIMPLEMENTAS_NUMERIC,ENUMERATIONIMPLEMENTAS_VARCHAR),l_iEnumerationImplementLength,NULL))
                endif
                :Field("Enumeration.DocStatus"  ,l_iEnumerationDocStatus)
                :Field("Enumeration.Description",iif(empty(l_cEnumerationDescription),NULL,l_cEnumerationDescription))
                if empty(l_iEnumerationPk)
                    :Field("Enumeration.LinkUID",oFcgi:p_o_SQLConnection:GetUUIDString())
                    if :Add()
                        l_iEnumerationPk := :Key()
                    else
                        l_cErrorMessage := "Failed to add Enumeration."
                    endif
                else
                    if !:Update(l_iEnumerationPk)
                        l_cErrorMessage := "Failed to update Enumeration."
                    endif
                endif
            endif
        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    endif

case l_cActionOnSubmit == "Cancel"
case l_cActionOnSubmit == "Done"
    l_iEnumerationPk := 0

case l_cActionOnSubmit == "Delete"   // Enumeration
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveEnumerationDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteEnumeration(l_iEnumerationPk)
            if empty(l_cErrorMessage)
                l_iEnumerationPk := 0
            endif
        else
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
                        DataDictionaryFixAndTest(par_iApplicationPk)
                        l_iEnumerationPk := 0  // Will force to go back to the list of enumerations
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
    endif

case l_cActionOnSubmit == "Duplicate"   // Enumeration
    if oFcgi:p_nAccessLevelDD >= 5 .and. l_iEnumerationPk > 0

        l_oDB_ListOfEnumValues := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfEnumValues
            :Table("3ef1f126-003f-42f5-af2f-5e826940f7cf","EnumValue")
            :Where("EnumValue.fk_Enumeration = ^",l_iEnumerationPk)

            :Column("EnumValue.Number"            ,"EnumValue_Number")
            :Column("EnumValue.Order"             ,"EnumValue_Order")
            // :Column("EnumValue.LinkUID"           ,"EnumValue_LinkUID")
            :Column("EnumValue.Name"              ,"EnumValue_Name")
            :Column("EnumValue.TrackNameChanges"  ,"EnumValue_TrackNameChanges")
            :Column("EnumValue.AKA"               ,"EnumValue_AKA")
            :Column("EnumValue.Code"              ,"EnumValue_Code")
            :Column("EnumValue.Description"       ,"EnumValue_Description")
            :Column("EnumValue.UseStatus"         ,"EnumValue_UseStatus")
            :Column("EnumValue.DocStatus"         ,"EnumValue_DocStatus")
            // :Column("EnumValue.TestWarning"       ,"EnumValue_TestWarning")
            :SQL("ListOfEnumValues")
        endwith

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("6e30d9b3-ac94-4a89-9df7-17083e62949b","Enumeration")
            :Column("Enumeration.fk_Namespace"    ,"Enumeration_fk_Namespace")
            :Column("Enumeration.Name"            ,"Enumeration_Name")
            :Column("Enumeration.LinkUID"         ,"Enumeration_LinkUID")
            :Column("Enumeration.TrackNameChanges","Enumeration_TrackNameChanges")
            :Column("Enumeration.ImplementAs"     ,"Enumeration_ImplementAs")
            :Column("Enumeration.ImplementLength" ,"Enumeration_ImplementLength")
            :Column("Enumeration.Description"     ,"Enumeration_Description")
            :Column("Enumeration.UseStatus"       ,"Enumeration_UseStatus")
            :Column("Enumeration.DocStatus"       ,"Enumeration_DocStatus")
            // :Column("Enumeration.TestWarning"       ,"Enumeration_TestWarning")
            l_oData := :Get(l_iEnumerationPk)

            if !hb_IsNil(l_oData)
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                l_cName := OnDuplicateSanitizeName(l_oData:Enumeration_Name,l_cLinkUID,l_oData:Enumeration_LinkUID)
                
                :Table("c7deaef4-1e08-4ea7-b1d7-2fa30a858be8","Enumeration")
                :Field("Enumeration.fk_Namespace"    ,l_oData:Enumeration_fk_Namespace)
                :Field("Enumeration.Name"            ,l_cName)
                :Field("Enumeration.LinkUID"         ,l_cLinkUID)

                :Field("Enumeration.TrackNameChanges",l_oData:Enumeration_TrackNameChanges)
                :Field("Enumeration.ImplementAs"     ,l_oData:Enumeration_ImplementAs)
                :Field("Enumeration.ImplementLength" ,l_oData:Enumeration_ImplementLength)
                :Field("Enumeration.Description"     ,l_oData:Enumeration_Description)
                :Field("Enumeration.UseStatus"       ,l_oData:Enumeration_UseStatus)
                :Field("Enumeration.DocStatus"       ,l_oData:Enumeration_DocStatus)
                if :Add()
                    l_iEnumerationPk := :Key()

                    // Duplicate EnumValues
                    select ListOfEnumValues
                    scan all
                        :Table("11b1eb0a-0e1c-4a3d-b816-a3ea802c4816","EnumValue")
                        :Field("EnumValue.fk_Enumeration"     ,l_iEnumerationPk)
                        :Field("EnumValue.LinkUID"            ,oFcgi:p_o_SQLConnection:GetUUIDString())

                        :Field("EnumValue.Number"            ,ListOfEnumValues->EnumValue_Number)
                        :Field("EnumValue.Order"             ,ListOfEnumValues->EnumValue_Order)
                        // :Field("EnumValue.LinkUID"           ,"EnumValue_LinkUID")
                        :Field("EnumValue.Name"              ,ListOfEnumValues->EnumValue_Name)
                        :Field("EnumValue.TrackNameChanges"  ,ListOfEnumValues->EnumValue_TrackNameChanges)
                        :Field("EnumValue.AKA"               ,ListOfEnumValues->EnumValue_AKA)
                        :Field("EnumValue.Code"              ,ListOfEnumValues->EnumValue_Code)
                        :Field("EnumValue.Description"       ,ListOfEnumValues->EnumValue_Description)
                        :Field("EnumValue.UseStatus"         ,ListOfEnumValues->EnumValue_UseStatus)
                        :Field("EnumValue.DocStatus"         ,ListOfEnumValues->EnumValue_DocStatus)
                        // :Field("EnumValue.TestWarning"       ,ListOfEnumValues->EnumValue_TestWarning)

                        if !:Add()
                            l_cErrorMessage := "Failed to add Values in Enumeration."
                            exit
                        endif
                    endscan

                else
                    l_cErrorMessage := "Failed to add Enumeration."
                endif
            endif

        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    else
        l_cErrorMessage := "No Access to Duplicate"
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Fk_Namespace"]    := l_iNamespacePk
    l_hValues["Name"]            := l_cEnumerationName
    l_hValues["AKA"]             := l_cEnumerationAKA
    l_hValues["UseStatus"]       := l_iEnumerationUseStatus
    l_hValues["DocStatus"]       := l_iEnumerationDocStatus
    l_hValues["Description"]     := l_cEnumerationDescription
    l_hValues["ImplementAs"]     := l_iEnumerationImplementAs
    l_hValues["ImplementLength"] := l_iEnumerationImplementLength
    l_hValues["ExternalId"]      := l_iEnumerationExternalId

    l_cHtml += EnumerationEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iEnumerationPk,l_hValues)

case empty(l_iEnumerationPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("da356f83-c733-465e-a73c-e0af9e06d192","Enumeration")
        :Column("Namespace.Name"     ,"Namespace_Name")
        :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
        :Column("Enumeration.Name"   ,"Enumeration_Name")
        :Column("Enumeration.LinkUID","Enumeration_LinkUID")
        :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
        l_oData := :Get(l_iEnumerationPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditEnumeration/"+par_cURLApplicationLinkCode+"/"+;
                                                                                 PrepareForURLSQLIdentifier("Namespace"  ,l_oData:Namespace_Name  ,l_oData:Namespace_LinkUID)  +"/"+;
                                                                                 PrepareForURLSQLIdentifier("Enumeration",l_oData:Enumeration_Name,l_oData:Enumeration_LinkUID)+"/";
                                                                                 )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumValueListFormBuild(par_iApplicationPk,par_iEnumerationPk,par_cURLApplicationLinkCode,par_oNavData)

local l_cHtml := []
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfEnumValues
local l_oDB_ListOfEnumValues   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPreviousName := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_lHasExternalId :=.f.
local l_lWarnings := .f.
local l_nColspan
local l_cCombinedPath

local l_cLine
local l_nMaxWidth
local l_lExtraInfo

oFcgi:TraceAdd("EnumValueListFormBuild")

with object l_oDB_ListOfEnumValues
    :Table("6e36b50f-9e7c-43d6-bba3-00d402a649d0","EnumValue")
    :Column("EnumValue.pk"         ,"pk")
    :Column("EnumValue.LinkUID"    ,"EnumValue_LinkUID")
    :Column("EnumValue.Name"       ,"EnumValue_Name")
    :Column("EnumValue.AKA"        ,"EnumValue_AKA")
    :Column("EnumValue.Number"     ,"EnumValue_Number")
    :Column("EnumValue.Code"       ,"EnumValue_Code")
    :Column("EnumValue.UseStatus"  ,"EnumValue_UseStatus")
    :Column("EnumValue.DocStatus"  ,"EnumValue_DocStatus")
    :Column("EnumValue.Description","EnumValue_Description")
    :Column("EnumValue.Order"      ,"EnumValue_Order")
    :Column("EnumValue.ExternalId" ,"EnumValue_ExternalId")
    :Column("EnumValue.TestWarning","EnumValue_TestWarning")

    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)

    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
    l_nNumberOfEnumValues := :Tally
endwith

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +[/]+;
                   PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+[/]

l_cHtml += GetCopyToClipboardJavaScript("CopyRoster")

l_cHtml += [<pre id="PreEnumValuesToClipboard" style="display:none;">]
    select ListOfEnumValues
    l_nMaxWidth  := 0
    l_lExtraInfo := .f.

    scan all
        l_nMaxWidth := max(l_nMaxWidth,len(ListOfEnumValues->EnumValue_Name))
        if ListOfEnumValues->EnumValue_UseStatus = USESTATUS_PROPOSED .or. ;
           ListOfEnumValues->EnumValue_UseStatus = USESTATUS_DISCONTINUED .or. ;
           !hb_IsNil(ListOfEnumValues->EnumValue_Number) .or. ;
           (!hb_IsNil(ListOfEnumValues->EnumValue_Code) .and. !empty(ListOfEnumValues->EnumValue_Code))
            l_lExtraInfo := .t.
        endif
    endscan

    scan all
        if !l_lExtraInfo
            l_cLine := ListOfEnumValues->EnumValue_Name

        else
            l_cLine := padr(ListOfEnumValues->EnumValue_Name,l_nMaxWidth)

            if !hb_IsNil(ListOfEnumValues->EnumValue_Number)
                l_cLine += [ - Number: ]+trans(ListOfEnumValues->EnumValue_Number)
            endif

            if !hb_IsNil(ListOfEnumValues->EnumValue_Code) .and. !empty(ListOfEnumValues->EnumValue_Code)
                l_cLine += [ - Code: ]+alltrim(ListOfEnumValues->EnumValue_Code)
            endif

            do case
            case ListOfEnumValues->EnumValue_UseStatus = USESTATUS_PROPOSED
                l_cLine += [ (Proposed)]
            case ListOfEnumValues->EnumValue_UseStatus = USESTATUS_DISCONTINUED
                l_cLine += [ (Discontinued)]
            endcase

        endif

        l_cHtml += l_cLine+CRLF
    endscan
l_cHtml += [</pre>]

AssembleNavbarInfo("Add",{"Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_AKA  ,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_AKA,par_oNavData:Enumeration_LinkUID})

l_cHtml += GetAboveNavbarHeading("Values","Enumeration",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group RemoveOnEdit mb-3">]
        l_cHtml += GetNextPreviousEnumeration(par_iApplicationPk,par_cURLApplicationLinkCode,par_iEnumerationPk,"ListEnumValues")
        l_cHtml += GetEnumerationExtendedButtonRelatedOnEditForm("Value",par_iEnumerationPk,l_cCombinedPath)
    l_cHtml += [</div><div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 5
            l_cHtml += GetButtonOnEditFormNew("New Value",l_cSitePath+[DataDictionaries/NewEnumValue/]+l_cCombinedPath)
            if l_nNumberOfEnumValues > 1
                l_cHtml += GetButtonOnListFormCaptionAndRedirect("Order Values",l_cSitePath+[DataDictionaries/OrderEnumValues/]+l_cCombinedPath)
            endif

            l_cHtml += [<input type="button" role="button" value="Copy Values List To Clipboard" class="btn btn-primary rounded ms-3" id="CopyRoster" onclick="]
            l_cHtml += [copyToClip(document.getElementById('PreEnumValuesToClipboard').innerText);return false;">]

        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if l_nNumberOfEnumValues <= 0
    l_cHtml += GetNoRecordsOnFile("No Value on file.")

else
    with object l_oDB_ListOfPreviousName
        :Table("bebcfc45-551f-4a76-aee7-8e521c64682d","EnumValue")
        :Column("EnumValue.pk"                  ,"pk")
        :Column("EnumValuePreviousName.pk"      ,"PreviousName_pk")   //Will use the pk to order, since it is incremental
        :Column("EnumValuePreviousName.Name"    ,"PreviousName_Name")
        :Join("inner","EnumValuePreviousName","","EnumValuePreviousName.fk_EnumValue = EnumValue.pk")
        :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)
        :SQL("ListOfPreviousName")
        with object :p_oCursor
            :Index("tag1","alltrim(str(pk))+'*'+str(9999999999-PreviousName_pk,10)")
            :CreateIndexes()
        endwith
    endwith

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    select ListOfEnumValues
    scan all while !l_lWarnings .or. !l_lHasExternalId
        if !empty(nvl(ListOfEnumValues->EnumValue_TestWarning,""))
            l_lWarnings := .t.
        endif
        if nvl(ListOfEnumValues->EnumValue_ExternalId,0) > 0
            l_lHasExternalId := .t.
        endif
    endscan

    l_nColspan := 6
    if l_lHasExternalId
        l_nColspan++
    endif
    if l_lWarnings
        l_nColspan++
    endif

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+trans(l_nColspan)+[">Values (]+Trans(l_nNumberOfEnumValues)+[) for Enumeration "]+TextToHtml(par_oNavData:Namespace_Name+FormatAKAForDisplay(par_oNavData:Namespace_AKA)+[.]+par_oNavData:Enumeration_Name+FormatAKAForDisplay(par_oNavData:Enumeration_AKA))+["</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Number</th>]
                l_cHtml += [<th class="text-white">Code</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                if l_lHasExternalId
                    l_cHtml += [<th class="text-white">External Id</th>]
                endif
                if l_lWarnings
                    l_cHtml += [<th class="text-center bg-warning text-danger">Warning</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfEnumValues
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfEnumValues->EnumValue_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditEnumValue/]+l_cCombinedPath+;
                                                                                             PrepareForURLSQLIdentifier("EnumValue"  ,ListOfEnumValues->EnumValue_Name  ,ListOfEnumValues->EnumValue_LinkUID)+[/]+;
                                                                                             [">]+FcgiPrepFieldForValue(ListOfEnumValues->EnumValue_Name+FormatAKAForDisplay(ListOfEnumValues->EnumValue_AKA))+[</a>]

                        if el_seek(trans(ListOfEnumValues->pk)+'*',"ListOfPreviousName","tag1")
                            select ListOfPreviousName
                            scan while ListOfPreviousName->pk == ListOfEnumValues->pk
                                l_cHtml += [<div class="ps-1 small">Previously: ]+TextToHtml(ListOfPreviousName->PreviousName_Name)+[</div>]
                            endscan
                        endif

                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        if !hb_orm_isnull("ListOfEnumValues","EnumValue_Number")
                            l_cHtml += trans(ListOfEnumValues->EnumValue_Number)
                        endif
                        l_cHtml += hb_DefaultValue(ListOfEnumValues->EnumValue_Number,"")
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += hb_DefaultValue(ListOfEnumValues->EnumValue_Code,"")
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumValues->EnumValue_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfEnumValues->EnumValue_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfEnumValues->EnumValue_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfEnumValues->EnumValue_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfEnumValues->EnumValue_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                    if l_lHasExternalId
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="right">]
                            if nvl(ListOfEnumValues->EnumValue_ExternalId,0) > 0
                                l_cHtml += trans(ListOfEnumValues->EnumValue_ExternalId)
                            endif
                        l_cHtml += [</td>]
                    endif

                    if l_lWarnings
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumValues->EnumValue_TestWarning,""))
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
static function EnumValueOrderFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:p_cSitePath

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

select ListOfEnumValues

AssembleNavbarInfo("Add",{"Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_AKA  ,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_AKA,par_oNavData:Enumeration_LinkUID})

l_cHtml += GetAboveNavbarHeading("Order Values","Enumeration",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnOrderListFormSave()
        endif
        l_cHtml += GetButtonCancelAndRedirect(l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cURLApplicationLinkCode+[/]+;
                                                                                             PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +[/]+;
                                                                                             PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+[/];
                                                                                            )
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center m-3">]
    l_cHtml += [<div class="col-auto">]

    l_cHtml += [<ul id="sortable">]
    scan all
        l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfEnumValues->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+FcgiPrepFieldForValue(ListOfEnumValues->EnumValue_Name+FormatAKAForDisplay(ListOfEnumValues->EnumValue_AKA))+[</span></li>]
    endscan
    l_cHtml += [</ul>]

    l_cHtml += [</div>]
l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormOnSubmit(par_iEnumerationPk,par_cURLApplicationLinkCode,par_oNavData)
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
l_cEnumValuePkOrder := SanitizeInput(oFcgi:GetInputValue("ValueOrder"))

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
            if el_seek(val(l_aOrderedPks[l_Counter]),"ListOfEnumValue","pk") .and. ListOfEnumValue->order <> l_Counter
                with object l_oDB1
                    :Table("b2b226c3-c799-4147-8158-d601709cb9a0","EnumValue")
                    :Field("EnumValue.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+;
                                                                        PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +"/"+;
                                                                        PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+"/";
                                                                        )

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumValueEditFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_oNavData,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

// local l_oDB1
// local l_oNavData

local l_cName             := hb_HGetDef(par_hValues,"Name","")
local l_lTrackNameChanges := nvl(hb_HGetDef(par_hValues,"TrackNameChanges",.t.),.t.)
local l_cAKA              := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_cNumber           := nvl(hb_HGetDef(par_hValues,"Number",""),"")
local l_cCode             := nvl(hb_HGetDef(par_hValues,"Code",""),"")
local l_nUseStatus        := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus        := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription      := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_iExternalId       := nvl(hb_HGetDef(par_hValues,"ExternalId",0),0)
local l_cCombinedPath
local l_cSitePath := oFcgi:p_cSitePath

oFcgi:TraceAdd("EnumValueEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +[/]+;
                   PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+[/]

AssembleNavbarInfo("Add",{"Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_AKA  ,par_oNavData:Namespace_LinkUID})
AssembleNavbarInfo("Add",{"Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_AKA,par_oNavData:Enumeration_LinkUID})

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Value","Enumeration",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += GetNextPreviousEnumValue(par_iEnumerationPk,l_cCombinedPath,par_iPk)
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Value",l_cSitePath+[DataDictionaries/NewEnumValue/]+l_cCombinedPath)

                l_cHtml += GetButtonOnEditFormDelete()
                l_cHtml += GetConfirmationModalFormsDelete()

                l_cHtml += GetButtonOnEditFormDuplicate()
                l_cHtml += GetConfirmationModalFormsDuplicate("Only the Value definition will be duplicated.")
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(par_iPk)
    l_cHtml += DisplayTestWarningMessageOnEditForm(hb_HGetDef(par_hValues,"TestWarning",""))
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += GetTrackNameChangesAndPreviousNamesEditFormBuild(l_lTrackNameChanges,"EnumValue",par_iPk)

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Number</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextNumber" id="TextNumber" value="]+FcgiPrepFieldForValue(l_cNumber)+[" maxlength="8" size="8"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Code</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextCode" id="TextCode" value="]+FcgiPrepFieldForValue(l_cCode)+[" maxlength="10" size="10"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
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
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    if !empty(l_iExternalId)
        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">External Id</td>]
            l_cHtml += [<td class="pb-3">]+trans(l_iExternalId)+[ (Created via API call)</td>]
        l_cHtml += [</tr>]
    endif

    l_cHtml += [</table>]
    
    l_cHtml += [<input type="hidden" name="TextExternalId" id="TextExternalId" value="]+trans(l_iExternalId)+[">]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function EnumValueEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode,par_iEnumerationPk,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumValuePk
local l_cEnumValueName
local l_lEnumValueTrackNameChanges
local l_cEnumValueAKA
local l_cEnumValueNumber,l_iEnumValueNumber
local l_cEnumValueCode
local l_nEnumValueUseStatus
local l_nEnumValueDocStatus
local l_cEnumValueDescription
local l_iEnumValueOrder
local l_iEnumValueExternalId
local l_aSQLResult   := {}
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1
local l_oData
local l_lDuplicate
local l_cLinkUID
local l_cName
local l_nPos
local l_iEnumerationPk := 0

oFcgi:TraceAdd("EnumValueEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumValuePk               := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValueName             := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_lEnumValueTrackNameChanges := (oFcgi:GetInputValue("CheckTrackNameChanges") == "1")
l_cEnumValueAKA              := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cEnumValueAKA)
    l_cEnumValueAKA := NIL
endif
l_cEnumValueNumber           := SanitizeInput(oFcgi:GetInputValue("TextNumber"))
l_iEnumValueNumber           := iif(empty(l_cEnumValueNumber),NULL,val(l_cEnumValueNumber))
l_cEnumValueCode             := SanitizeInput(oFcgi:GetInputValue("TextCode"))
l_nEnumValueUseStatus        := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nEnumValueDocStatus        := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cEnumValueDescription      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_iEnumValueExternalId       := Val(oFcgi:GetInputValue("TextExternalId"))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cEnumValueName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("b36fab5b-9f56-432e-a1b5-64b884df1960","EnumValue")
                :Column("EnumValue.pk","pk")
                :Where([EnumValue.fk_Enumeration = ^],par_iEnumerationPk)
                :Where([lower(replace(EnumValue.Name,' ','')) = ^],lower(StrTran(l_cEnumValueName," ","")))
                if l_iEnumValuePk > 0
                    :Where([EnumValue.pk != ^],l_iEnumValuePk)
                endif
                :SQL()
                l_lDuplicate := (:Tally <> 0)

                if !l_lDuplicate
                    :Table("39dee039-bc90-4842-b124-0454bd794cf4","EnumValue")
                    :Column("EnumValue.pk","pk")
                    :Where([EnumValue.fk_Enumeration = ^],par_iEnumerationPk)
                    :Where([lower(replace(EnumValuePreviousName.Name,' ','')) = ^],lower(StrTran(l_cEnumValueName," ","")))
                    :Join("inner","EnumValuePreviousName","","EnumValuePreviousName.fk_EnumValue = EnumValue.pk")
                    if l_iEnumValuePk > 0
                        :Where([EnumValue.pk != ^],l_iEnumValuePk)
                    endif
                    :SQL()
                    l_lDuplicate := (:Tally <> 0)
                endif
            endwith

            if l_lDuplicate
                l_cErrorMessage := "Duplicate Name"
            endif
        endif

        if !empty(l_cEnumValueCode)
            with object l_oDB1
                :Table("b36fab5b-9f56-432e-a1b5-64b884df1961","EnumValue")
                :Column("EnumValue.pk","pk")
                :Where([EnumValue.fk_Enumeration = ^],par_iEnumerationPk)
                :Where([EnumValue.Code IS NOT NULL])
                :Where([lower(replace(EnumValue.Code,' ','')) = ^],lower(StrTran(l_cEnumValueCode," ","")))
                if l_iEnumValuePk > 0
                    :Where([EnumValue.pk != ^],l_iEnumValuePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Code"
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
            l_cErrorMessage := TrackNameChange(l_oDB1,"EnumValue",l_iEnumValuePk,l_cEnumValueName,l_lEnumValueTrackNameChanges)
            if empty(l_cErrorMessage)
                RemovePreviousNameIfSelectedEditFormOnSubmit("EnumValue",l_iEnumValuePk)

                :Table("1ed0fff1-f702-4c77-b66e-55a468ad8ad2","EnumValue")
                if oFcgi:p_nAccessLevelDD >= 5
                    :Field("EnumValue.Name"            ,l_cEnumValueName)
                    :Field("EnumValue.TrackNameChanges",l_lEnumValueTrackNameChanges)
                    :Field("EnumValue.AKA"             ,l_cEnumValueAKA)
                    :Field("EnumValue.Number"          ,l_iEnumValueNumber)
                    :Field("EnumValue.Code"            ,iif(empty(l_cEnumValueCode),nil,l_cEnumValueCode))
                    :Field("EnumValue.UseStatus"       ,l_nEnumValueUseStatus)
                endif
                :Field("EnumValue.DocStatus"  ,l_nEnumValueDocStatus)
                :Field("EnumValue.Description",iif(empty(l_cEnumValueDescription),NULL,l_cEnumValueDescription))
                if empty(l_iEnumValuePk)
                    :Field("EnumValue.fk_Enumeration",par_iEnumerationPk)
                    :Field("EnumValue.Order"         ,l_iEnumValueOrder)
                    :Field("EnumValue.LinkUID"       ,oFcgi:p_o_SQLConnection:GetUUIDString())
                    if :Add()
                        l_iEnumValuePk := :Key()
                    else
                        l_cErrorMessage := "Failed to add Enumeration Value."
                    endif

                else
                    if !:Update(l_iEnumValuePk)
                        l_cErrorMessage := "Failed to update Enumeration Value."
                    endif
                endif
            endif
        endwith
        DataDictionaryFixAndTest(par_iApplicationPk)
    endif

case l_cActionOnSubmit == "Cancel"
case l_cActionOnSubmit == "Done"
    l_iEnumValuePk := 0

case l_cActionOnSubmit == "Delete"   // EnumValue
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

        if l_oDB1:Delete("7f3486e6-6bbc-4307-b617-5ff00f0ac3ad","EnumValue",l_iEnumValuePk)
            l_iEnumValuePk := 0
            DataDictionaryFixAndTest(par_iApplicationPk)
        else
            l_cErrorMessage := "Failed to delete value."
        endif
    endif

case l_cActionOnSubmit == "Duplicate"   // EnumValue
    if oFcgi:p_nAccessLevelDD >= 5 .and. l_iEnumValuePk > 0

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("508f5c4d-7db2-45cd-b432-67919235804a","EnumValue")
            :Column("EnumValue.fk_Enumeration"    ,"EnumValue_fk_Enumeration")
            :Column("EnumValue.Number"            ,"EnumValue_Number")
            :Column("EnumValue.Order"             ,"EnumValue_Order")
            :Column("EnumValue.LinkUID"           ,"EnumValue_LinkUID")
            :Column("EnumValue.Name"              ,"EnumValue_Name")
            :Column("EnumValue.TrackNameChanges"  ,"EnumValue_TrackNameChanges")
            :Column("EnumValue.AKA"               ,"EnumValue_AKA")
            :Column("EnumValue.Code"              ,"EnumValue_Code")
            :Column("EnumValue.Description"       ,"EnumValue_Description")
            :Column("EnumValue.UseStatus"         ,"EnumValue_UseStatus")
            :Column("EnumValue.DocStatus"         ,"EnumValue_DocStatus")
            // :Column("EnumValue.TestWarning"       ,"EnumValue_TestWarning")
            l_oData := :Get(l_iEnumValuePk)

            if !hb_IsNil(l_oData)
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                l_cName := OnDuplicateSanitizeName(l_oData:EnumValue_Name,l_cLinkUID,l_oData:EnumValue_LinkUID)
                
                l_iEnumerationPk := l_oData:EnumValue_fk_Enumeration

                :Table("c0560ac0-6569-42b0-8372-d18463d0f2a2","EnumValue")
                :Field("EnumValue.fk_Enumeration"    ,l_iEnumerationPk)
                :Field("EnumValue.LinkUID"           ,l_cLinkUID)
                :Field("EnumValue.Name"              ,l_cName)

                :Field("EnumValue.Number"            ,l_oData:EnumValue_Number)
                :Field("EnumValue.Order"             ,l_oData:EnumValue_Order)
                :Field("EnumValue.TrackNameChanges"  ,l_oData:EnumValue_TrackNameChanges)
                :Field("EnumValue.AKA"               ,l_oData:EnumValue_AKA)
                :Field("EnumValue.Code"              ,l_oData:EnumValue_Code)
                :Field("EnumValue.Description"       ,l_oData:EnumValue_Description)
                :Field("EnumValue.UseStatus"         ,l_oData:EnumValue_UseStatus)
                :Field("EnumValue.DocStatus"         ,l_oData:EnumValue_DocStatus)
                // :Field("EnumValue.TestWarning"       ,l_oData:EnumValue_TestWarning)

                if :Add()
                    l_iEnumValuePk := :Key()
                else
                    l_cErrorMessage := "Failed to add Enumeration Value."
                endif
            endif

        endwith
        if l_iEnumerationPk > 0
            ReSequenceEnumValues(l_iEnumerationPk)
        endif
        DataDictionaryFixAndTest(par_iApplicationPk)
    else
        l_cErrorMessage := "No Access to Duplicate"
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]        := l_cEnumValueName
    l_hValues["AKA"]         := l_cEnumValueAKA
    l_hValues["Number"]      := l_cEnumValueNumber
    l_hValues["Code"]        := l_cEnumValueCode
    l_hValues["UseStatus"]   := l_nEnumValueUseStatus
    l_hValues["DocStatus"]   := l_nEnumValueDocStatus
    l_hValues["Description"] := l_cEnumValueDescription
    l_hValues["ExternalId"]  := l_iEnumValueExternalId

    l_cHtml += EnumValueEditFormBuild(par_iEnumerationPk,par_cURLApplicationLinkCode,par_oNavData,l_cErrorMessage,l_iEnumValuePk,l_hValues)

case empty(l_iEnumValuePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+;
                                                                        PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +[/]+;
                                                                        PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+[/];
                                                                        )

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("0565a26a-b9c7-4fd0-ad1e-0e1ff08e64f0","EnumValue")
        :Column("Namespace.Name"     ,"Namespace_Name")
        :Column("Namespace.AKA"      ,"Namespace_AKA")
        :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
        :Column("Enumeration.Name"   ,"Enumeration_Name")
        :Column("Enumeration.AKA"    ,"Enumeration_AKA")
        :Column("Enumeration.LinkUID","Enumeration_LinkUID")
        :Column("EnumValue.Name"     ,"EnumValue_Name")
        :Column("EnumValue.LinkUID"  ,"EnumValue_LinkUID")
        :Join("inner","Enumeration","","EnumValue.fk_Enumeration = Enumeration.pk")
        :Join("inner","Namespace"  ,"","Enumeration.fk_Namespace = Namespace.pk")
        l_oData := :Get(l_iEnumValuePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditEnumValue/"+par_cURLApplicationLinkCode+"/"+;
                                                                               PrepareForURLSQLIdentifier("Namespace"  ,l_oData:Namespace_Name  ,l_oData:Namespace_LinkUID)  +[/]+;
                                                                               PrepareForURLSQLIdentifier("Enumeration",l_oData:Enumeration_Name,l_oData:Enumeration_LinkUID)+[/]+;
                                                                               PrepareForURLSQLIdentifier("EnumValue"  ,l_oData:EnumValue_Name  ,l_oData:EnumValue_LinkUID);
                                                                               )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumValues/"+par_cURLApplicationLinkCode+"/"+;
                                                                                PrepareForURLSQLIdentifier("Namespace"  ,par_oNavData:Namespace_Name  ,par_oNavData:Namespace_LinkUID)  +[/]+;
                                                                                PrepareForURLSQLIdentifier("Enumeration",par_oNavData:Enumeration_Name,par_oNavData:Enumeration_LinkUID)+[/];
                                                                                )
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
static function DataDictionaryDeploymentToolsFormBuild(par_cMode,par_iPk,par_cErrorText,par_cApplicationName,par_cLinkCode,;
                                                       par_nFk_Deployment,;
                                                       par_aDeltaMessages,par_cErrorDetail,par_cScript)

local l_cHtml := ""
local l_cErrorText         := hb_DefaultValue(par_cErrorText,"")
local l_cApplicationName   := hb_DefaultValue(par_cApplicationName,"")
local l_cLinkCode          := hb_DefaultValue(par_cLinkCode,"")

local l_nFk_Deployment     := hb_DefaultValue(par_nFk_Deployment,0)

local l_cMessageLine

local l_oDB_ListOfDeployments := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfDeployments
local l_cNamespaces
local l_cJavaScript

oFcgi:TraceAdd("DataDictionaryDeploymentToolsFormBuild")

with object l_oDB_ListOfDeployments
    :Table("622f65ec-3a70-4f96-9bd2-a55386c9e2b8","Deployment")
    :Where("Deployment.fk_Application = ^",par_iPk)
    :Where("Deployment.fk_User = ^ or Deployment.fk_User = 0" ,oFcgi:p_iUserPk)
    :Where("Deployment.Status = 1")
    :Column("Deployment.pk"         ,"Pk")
    :Column("Deployment.fk_User"    ,"Deployment_fk_User")
    :Column("Deployment.Name"       ,"Deployment_Name")
    :Column("Deployment.Namespaces" ,"Deployment_Namespaces")
    :Column("Upper(Deployment.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfDeployments")
    l_nNumberOfDeployments := :Tally
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Step1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnViewForm(l_cErrorText)

if empty(par_iPk)
    l_cHtml += [</form>]

else
    l_cHtml += GetAboveNavbarHeading("Deployments")

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
        // l_cHtml += [<div class="form-group">]
        
            if "Delta" $ par_cMode
                l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Delta" onclick="$('#ActionOnSubmit').val('Delta');document.form.submit();" role="button">]
            endif

            if "Load" $ par_cMode
                if oFcgi:p_nAccessLevelDD >= 6
                    l_cHtml += [<button type="button" class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmLoadModal">Load</button>]
                endif
            endif

            if "GenScript" $ par_cMode
                l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Generate Script" onclick="$('#ActionOnSubmit').val('GenerateScript');document.form.submit();" role="button">]
            endif

            if "Update" $ par_cMode
                if oFcgi:p_nAccessLevelDD >= 6
                    l_cHtml += [<button type="button" class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmUpdateSchemaModal">Update</button>]
                endif
            endif

            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-5 me-3" value="Configure Personal Deployments" onclick="$('#ActionOnSubmit').val('ListMyDeployments');document.form.submit();" role="button">]

            // l_cHtml += GetButtonOnEditFormDoneCancel()
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]

        if l_nNumberOfDeployments > 0

            // l_cHtml += [<script language="javascript">]
            // l_cHtml += [function OnChangeDeployment(par_Value) {]

            // l_cHtml += [switch(par_Value) {]
            // l_cHtml += [  case '0':]
            // l_cHtml += [  $('#TableCustomDeployment').show();]
            // l_cHtml += [    break;]
            // l_cHtml += [  default:]
            // l_cHtml += [  $('#TableCustomDeployment').hide();]
            // l_cHtml += [};]

            // l_cHtml += [};]
            // l_cHtml += [</script>] 
            // oFcgi:p_cjQueryScript += [OnChangeDeployment($("#ComboFk_Deployment").val());]

            l_cHtml += [<table>]
                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Deployment</td>]
                    l_cHtml += [<td class="pb-3">]
                        // l_cHtml += [<select name="ComboFk_Deployment" id="ComboFk_Deployment" onchange="OnChangeDeployment(this.value);">]
                        // l_cHtml += [<option value="0"]+iif(0 == l_nFk_Deployment,[ selected],[])+[>My Custom Settings</option>]
                        l_cHtml += [<select name="ComboFk_Deployment" id="ComboFk_Deployment">]
                        select ListOfDeployments
                        scan all
                            l_cHtml += [<option value="]+trans(ListOfDeployments->pk)+["]+iif(ListOfDeployments->pk == l_nFk_Deployment,[ selected],[])+[>]+alltrim(ListOfDeployments->Deployment_Name)
                            if ListOfDeployments->Deployment_fk_User > 0
                                l_cHtml+= [ (Personal)]
                            endif

                            l_cNamespaces := nvl(ListOfDeployments->Deployment_Namespaces,"")
                            if !empty(l_cNamespaces)
                                l_cHtml += " - Namespace"+iif("," $ l_cNamespaces,"s","")+[: ]+nvl(ListOfDeployments->Deployment_Namespaces,"")
                            endif
                            
                            l_cHtml += [</option>]
                        endscan
                        l_cHtml += [</select>]
                    l_cHtml += [</td>]
            l_cHtml += [</tr>]
            l_cHtml += [</table>]
        else
            l_cHtml += [<input type="hidden" name="ComboFk_Deployment" value="0">]
        endif

    l_cHtml += [</div>]

    // oFcgi:p_cjQueryScript += [$('#ComboSyncBackendType').focus();]

    if !empty(par_aDeltaMessages)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="fs-4">Delta Result:</div>]
            for each l_cMessageLine in par_aDeltaMessages
                l_cHtml += [<div>]+l_cMessageLine+[</div>]
            endfor
            l_cHtml += [<div class="m-5"></div>]
        l_cHtml += [</div>]
    endif

    if !empty(par_cErrorDetail)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="fs-4">Error Detail:</div>]
                l_cHtml += [<div>]+par_cErrorDetail+[</div>]
            l_cHtml += [<div class="m-5"></div>]
        l_cHtml += [</div>]
    endif

    if !empty(par_cScript)

        l_cHtml += GetCopyToClipboardJavaScript("CopySourceCode")

        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="fs-4">]
                l_cHtml += [Generated Script:]
                l_cHtml += [<input type="button" role="button" value="Copy To Clipboard" class="btn btn-primary rounded ms-3" id="CopySourceCode" onclick="]
                l_cHtml += [copyToClip(document.getElementById('GeneratedCode').innerText);return false;">]
            l_cHtml += [</div>]

            l_cHtml += [<pre id="GeneratedCode" class="ms-3">]
            l_cHtml += par_cScript
            l_cHtml += [</pre>]

            l_cHtml += [<div class="m-5"></div>]
        l_cHtml += [</div>]
    endif

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalFormsLoad()
    l_cHtml += GetConfirmationModalFormsUpdateSchema()
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function DataDictionaryDeploymentToolsFormOnSubmit(par_cMode,par_iApplicationPk,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_nFk_Deployment

local l_nConnectBackendType
local l_cConnectBackendType
local l_cConnectServer
local l_nConnectPort
local l_cConnectUser
local l_cConnectPassword
local l_cConnectDatabase
local l_cConnectNamespaces
local l_nConnectSetForeignKey
local l_nConnectPasswordStorage
local l_cConnectPasswordConfigKey
local l_cConnectPasswordEnvVarName

local l_cErrorMessage := ""
local l_oDB1
local l_oDB_ListOfDeployments
local l_oDB_Application

local l_cPreviousDefaultRDD
local l_cConnectionString
local l_cSQLEngineType
local l_cBackendType
local l_iPort
local l_cDriver
local l_iSQLHandle
local l_aDeltaMessages := {}
local l_oData
local l_cErrorDetail := ""
local l_cScript      := ""
local l_o_SQLConnection
local l_cMacro
local l_hWharfConfig

local l_cLastError := ""
local l_nMigrateResult := 0
//local l_lCyanAuditAware
local l_cUpdateScript := ""
local l_cSQLScript
local l_aInstructions
local l_cStatement
local l_nPos
local l_lAllowUpdates
local l_oData_Application
local l_lApplicationPreventLoadFromDeployments

oFcgi:TraceAdd("DataDictionaryDeploymentToolsFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_nFk_Deployment     := Val(oFcgi:GetInputValue("ComboFk_Deployment"))

l_cPreviousDefaultRDD = RDDSETDEFAULT( "SQLMIX" )

do case
case l_cActionOnSubmit == "ListMyDeployments"
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListMyDeployments/"+par_cURLApplicationLinkCode+"/")

case el_IsInlist(l_cActionOnSubmit,"Load","Delta","Update","GenerateScript")
    l_lAllowUpdates := .f.

    if l_cActionOnSubmit == "Load"
        l_oDB_Application := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_Application
            :Table("dbd47323-ebf2-4ffe-8db6-d12c1edfa48a","Application")
            :Column("Application.PreventLoadFromDeployments" , "Application_PreventLoadFromDeployments")
            l_oData_Application := :Get(par_iApplicationPk)
            l_lApplicationPreventLoadFromDeployments := nvl(l_oData_Application:Application_PreventLoadFromDeployments,.t.)
            if l_lApplicationPreventLoadFromDeployments
                l_cErrorMessage := ["Prevent Load From Deployments" is currently set under the "Data Dictionary Settings".]
            endif
        endwith
    endif

    do case
    case !empty(l_cErrorMessage)
    case empty(l_nFk_Deployment)
        l_cErrorMessage := "Select a Deployment"

    otherwise
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("ed077f50-c5c2-4ed0-bb97-5b9aedc081c5","UserSettingApplication")
            :Column("UserSettingApplication.pk"            ,"pk")
            :Column("UserSettingApplication.fk_Deployment" ,"fk_Deployment")
            :Where("UserSettingApplication.fk_User = ^",oFcgi:p_iUserPk)
            :Where("UserSettingApplication.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfUserSettingApplication")

            do case
            case :Tally == 0 .or. :Tally > 1
                if :Tally > 1  //Some bad data, simply delete all records.
                    select ListOfUserSettingApplication
                    scan all
                        :Delete("ed077f50-c5c2-4ed0-bb97-5b9aedc081c8","UserSettingApplication",ListOfUserSettingApplication->pk)
                    endscan
                endif

                //Add a new record
                :Table("ed077f50-c5c2-4ed0-bb97-5b9aedc081c6","UserSettingApplication")
                :Field("UserSettingApplication.fk_Deployment" ,l_nFk_Deployment)
                :Field("UserSettingApplication.fk_User"       ,oFcgi:p_iUserPk)
                :Field("UserSettingApplication.fk_Application",par_iApplicationPk)
                :Add()

            case :Tally == 1
                if ListOfUserSettingApplication->fk_Deployment <> l_nFk_Deployment
                    :Table("ed077f50-c5c2-4ed0-bb97-5b9aedc081c7","UserSettingApplication")
                    :Field("UserSettingApplication.fk_Deployment",l_nFk_Deployment)
                    :Update(ListOfUserSettingApplication->pk)
                endif

            endcase
        endwith

        l_oDB_ListOfDeployments := hb_SQLData(oFcgi:p_o_SQLConnection)
        
        with object l_oDB_ListOfDeployments
            :Table("d4e737d0-d8a3-4f5e-b05a-aa87e17522b1","public.Deployment")

            :Column("Deployment.BackendType"        , "BackendType")
            :Column("Deployment.Server"             , "Server")
            :Column("Deployment.Port"               , "Port")
            :Column("Deployment.User"               , "User")
            :Column("Deployment.Database"           , "Database")
            :Column("Deployment.Namespaces"         , "Namespaces")
            :Column("Deployment.SetForeignKey"      , "SetForeignKey")
            :Column("Deployment.PasswordStorage"    , "PasswordStorage")
            // :Column("Deployment.PasswordCrypt"      , "PasswordCrypt")
            :Column("Deployment.PasswordConfigKey"  , "PasswordConfigKey")
            :Column("Deployment.PasswordEnvVarName" , "PasswordEnvVarName")
            :Column("Deployment.AllowUpdates"       , "AllowUpdates")

            l_oData := :Get(l_nFk_Deployment)
            if :Tally == 1
                l_nConnectBackendType     := nvl(l_oData:BackendType,0)
                l_cConnectServer          := nvl(l_oData:Server,"")
                l_nConnectPort            := nvl(l_oData:Port,0)
                l_cConnectUser            := nvl(l_oData:User,"")
                l_cConnectDatabase        := nvl(l_oData:Database,"")
                l_cConnectNamespaces      := nvl(l_oData:Namespaces,"")
                l_nConnectSetForeignKey   := nvl(l_oData:SetForeignKey,0)
                l_nConnectPasswordStorage := nvl(l_oData:PasswordStorage,0)  //1 = Encrypted, 2 = In config.txt, 3 = In Environment Variable, 4 = User is AWS iam account. (Coming Soon)
                l_lAllowUpdates           := l_oData:AllowUpdates

                do case
                case empty(l_nConnectBackendType)
                    l_cErrorMessage := "Missing Backend Type"

                case empty(l_cConnectServer)
                    l_cErrorMessage := "Missing Server Host Address"

                case empty(l_cConnectUser)
                    l_cErrorMessage := "Missing User Name"

                // case empty(l_cSyncPassword)
                //     l_cErrorMessage := "Missing Password"

                case empty(l_cConnectDatabase)
                    l_cErrorMessage := "Missing Database"

                endcase

                if empty(l_cErrorMessage)
                    do case
                    case l_nConnectPasswordStorage == 1 // Encrypted
                        :Table("d4e737d0-d8a3-4f5e-b05a-aa87e17522b2","public.Deployment")
                        :Column([pgp_sym_decrypt(Deployment.PasswordCrypt,']+oFcgi:GetAppConfig("DEPLOYMENT_CRYPT_KEY")+[','compress-algo=0, cipher-algo=aes256')],"Password")
                        l_oData := :Get(l_nFk_Deployment)
                        if :Tally == 1
                            l_cConnectPassword := nvl(l_oData:Password,"")
                        else
                            // l_cErrorMessage := :ErrorMessage()
                            l_cErrorMessage := :LastSQL()
                        endif

                    case l_nConnectPasswordStorage == 2 // In config.txt
                        l_cConnectPasswordConfigKey := nvl(l_oData:PasswordConfigKey,"")
                        if empty(l_cConnectPasswordConfigKey)
                            l_cErrorMessage := "Missing configuration file key name."
                        else
                            l_cConnectPassword := oFcgi:GetAppConfig(l_cConnectPasswordConfigKey)
                            if empty(l_cConnectPassword)
                                l_cErrorMessage := "Missing password in config.txt file."
                            endif
                        endif
                        
                    case l_nConnectPasswordStorage == 3 // In Environment Variable
                        l_cConnectPasswordEnvVarName := nvl(l_oData:PasswordEnvVarName,"")
                        if empty(l_cConnectPasswordEnvVarName)
                            l_cErrorMessage := "Missing environment variable name."
                        else
                            l_cConnectPassword := oFcgi:GetEnvironment(l_cConnectPasswordEnvVarName)
                            if empty(l_cConnectPassword)
                                l_cErrorMessage := "Missing password in environment variable."
                            endif
                        endif

                    case l_nConnectPasswordStorage == 4 // User is AWS iam account
                        l_cErrorMessage := "AWS iam authentication not yet supported."

                    endcase
//Finish the coding to set the l_cConnectPassword
                //l_cConnectPassword      := l_cSyncPassword
                endif

            endif
            
        endwith



        if empty(l_cErrorMessage)
            switch l_nConnectBackendType
            case HB_ORM_BACKENDTYPE_MARIADB
                l_cConnectBackendType := "MARIADB"
                l_cSQLEngineType      := HB_ORM_ENGINETYPE_MYSQL
                l_iPort               := iif(empty(l_nConnectPort),3306,l_nConnectPort)
                l_cDriver             := oFcgi:GetAppConfig("ODBC_DRIVER_MARIADB")
                if empty(l_cDriver)
                    l_cDriver := "MariaDB ODBC 3.1 Driver"
                endif
                exit
            case HB_ORM_BACKENDTYPE_MYSQL
                l_cConnectBackendType := "MYSQL"
                l_cSQLEngineType      := HB_ORM_ENGINETYPE_MYSQL
                l_iPort               := iif(empty(l_nConnectPort),3306,l_nConnectPort)
                l_cDriver             := oFcgi:GetAppConfig("ODBC_DRIVER_MYSQL")
                if empty(l_cDriver)
                    l_cDriver := "MySQL ODBC 8.0 Unicode Driver"
                endif
                exit
            case HB_ORM_BACKENDTYPE_POSTGRESQL
                l_cConnectBackendType := "POSTGRESQL"
                l_cSQLEngineType      := HB_ORM_ENGINETYPE_POSTGRESQL
                l_iPort               := iif(empty(l_nConnectPort),5432,l_nConnectPort)
                l_cDriver             := oFcgi:GetAppConfig("ODBC_DRIVER_POSTGRESQL")
                if empty(l_cDriver)
                    l_cDriver := "PostgreSQL Unicode"
                endif
                exit
            case HB_ORM_BACKENDTYPE_MSSQL
                l_cConnectBackendType := "MSSQL"
                l_cSQLEngineType      := HB_ORM_ENGINETYPE_MSSQL
                l_iPort               := iif(empty(l_nConnectPort),1433,l_nConnectPort)
                l_cDriver             := oFcgi:GetAppConfig("ODBC_DRIVER_MSSQL")
                if empty(l_cDriver)
                    l_cDriver := "SQL Server"
                endif
                exit
            otherwise
                l_iPort := -1
            endswitch


            if el_IsInlist(l_cActionOnSubmit,"Update","GenerateScript")
//:SetHarbourORMNamespace("Harbour_ORM")

                l_o_SQLConnection := hb_SQLConnect()
                with object l_o_SQLConnection
                    :SetBackendType(l_cConnectBackendType)
                    :SetDriver(l_cDriver)
                    :SetServer(l_cConnectServer)
                    :SetPort(l_iPort)
                    :SetUser(l_cConnectUser)
                    :SetPassword(l_cConnectPassword)
                    :SetDatabase(l_cConnectDatabase)
                    :SetCurrentNamespaceName("public")

                    :LoadWharfConfiguration()


//_M_ refine options to use depending of Engine Type
                    :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
                    :MySQLEngineConvertIdentifierToLowerCase := .f.

                    :SetApplicationName("DataWharf")

                    :SetHarbourORMNamespace("nohborm")

                    l_iSQLHandle := :Connect()
                    do case
                    case l_iSQLHandle == 0
                        l_cErrorMessage := "Already Connected"
                    case l_iSQLHandle < 0
                        l_cErrorMessage := :GetErrorMessage()
                    otherwise

                        do case
                        case l_cActionOnSubmit == "Update"
                            if !l_lAllowUpdates
                                l_cErrorMessage := "Deployment is not configured to allow updates."
                            else
                                l_cMacro := ExportApplicationToHarbour_ORM(par_iApplicationPk,.f.,l_cConnectBackendType)
                                l_cMacro := Strtran(l_cMacro,chr(13),"")
                                l_cMacro := Strtran(l_cMacro,chr(10),"")
                                l_cMacro := Strtran(l_cMacro,[;],"")
                                l_hWharfConfig := &( l_cMacro )

                                //MigrateSchema return values: 0 = Nothing Migrated, 1 = Migrated, -1 = Error Migrating
                                if el_AUnpack(l_o_SQLConnection:MigrateSchema(l_hWharfConfig),@l_nMigrateResult,@l_cUpdateScript,@l_cLastError) > 0
                                    l_cErrorMessage := "Success - Migrated Structure"

                                    // if el_AUnpack(l_o_SQLConnection:MigrateForeignKeyConstraints(nvl(hb_hGetDef(l_hWharfConfig,"Tables",{=>}),{=>})),@l_nMigrateResult,@l_cUpdateScript,@l_cLastError) > 0
                                    //     l_cErrorMessage := "Success - Structure and Foreign Key Constraints Migrated"
                                    // else
                                    //     if empty(l_cLastError)
                                    //         l_cErrorMessage := "Success - Structure Migrated and Foreign Key Constraints did not change."
                                    //     else
                                    //         l_cErrorMessage := "Structure Migrated but Failed To Migrate Foreign Key Constraints"
                                    //         l_cErrorDetail := l_cLastError+[<br>Script Generated to Migrate Foreign Keys:<br><br>]+strtran(l_cUpdateScript,chr(13),[<br>])
                                    //         SendToDebugView("PostgreSQL - Failed Update")
                                    //     endif
                                    // endif

                                else
                                    if l_nMigrateResult == 0
                                        l_cErrorMessage := "Success - Nothing Changed."
                                    else
                                        if empty(l_cLastError)
                                            l_cErrorMessage := "Unknown Error Occurred."
                                        else
                                            l_cErrorMessage := "Failed to Update Structure."
                                            l_cErrorDetail := l_cLastError+[<br>Script Generated to Migrate Foreign Keys:<br><br>]+strtran(l_cUpdateScript,chr(13),[<br>])
                                            SendToDebugView("PostgreSQL - Failed Update")
                                        endif
                                    endif

                                    // if empty(l_cLastError)
                                    //     if el_AUnpack(l_o_SQLConnection:MigrateForeignKeyConstraints(nvl(hb_hGetDef(l_hWharfConfig,"Tables",{=>}),{=>})),@l_nMigrateResult,@l_cUpdateScript,@l_cLastError) > 0
                                    //         l_cErrorMessage := "Success - Structure did not change and Foreign Key Constraints Migrated"
                                    //     else
                                    //         if empty(l_cLastError)
                                    //             l_cErrorMessage := "Success - Structure and Foreign Key Constraints did not change."
                                    //         else
                                    //             l_cErrorMessage := "Structure did not change but Failed To Migrate Foreign Key Constraints"
                                    //             l_cErrorDetail := l_cLastError+[<br>Script Generated to Migrate Foreign Keys:<br><br>]+strtran(l_cUpdateScript,chr(13),[<br>])
                                    //             SendToDebugView("PostgreSQL - Failed Update")
                                    //         endif
                                    //     endif
                                    // else
                                    //     l_cErrorMessage := "Failed To Migrate Structure"
                                    //     l_cErrorDetail := l_cLastError+[<br>Script Generated to migrate structure:<br><br>]+strtran(l_cUpdateScript,chr(13),[<br>])
                                    //     SendToDebugView("PostgreSQL - Failed Update")
                                    // endif
                                endif

                            endif
                            l_cScript := ""

                        case l_cActionOnSubmit == "GenerateScript"
                            l_cMacro := ExportApplicationToHarbour_ORM(par_iApplicationPk,.f.,l_cConnectBackendType)
                            l_cMacro := Strtran(l_cMacro,chr(13),"")
                            l_cMacro := Strtran(l_cMacro,chr(10),"")
                            l_cMacro := Strtran(l_cMacro,[;],"")
                            l_hWharfConfig := &( l_cMacro )

                            // l_cSQLScript := ""
                            // l_cScript := l_o_SQLConnection:GenerateMigrateSchemaScript(l_hWharfConfig)
                            // if !empty(l_cScript)
                            //     l_cSQLScript := "--Structure Changes"+CRLF+l_cScript
                            // endif
                            // l_cScript := l_o_SQLConnection:GenerateMigrateForeignKeyConstraintsScript( nvl(hb_hGetDef(l_hWharfConfig,"Tables",{=>}),{=>}) )
                            // if !empty(l_cScript)
                            //     if !empty(l_cSQLScript)
                            //         l_cSQLScript += CRLF
                            //     endif
                            //     l_cSQLScript += "--Foreign Key Constraint Changes"+CRLF+l_cScript
                            // endif

                            l_cSQLScript := l_o_SQLConnection:GenerateMigrateSchemaScript(l_hWharfConfig)
                            l_cScript := ""
                            l_aInstructions := hb_ATokens(l_cSQLScript,.t.)
                            for each l_cStatement in l_aInstructions
                                if !empty(l_cStatement)
                                    l_nPos = at("/*OnFailMessage",l_cStatement)
                                    if l_nPos > 0
                                        l_cStatement := trim(left(l_cStatement,l_nPos-1))
                                    endif
                                    l_cScript += l_cStatement + CRLF
                                else
                                    l_cScript += CRLF
                                endif
                            endfor

                            if empty(l_cScript)
                                l_cErrorMessage := "Success - Nothing is different, no Generated Script"
                            else
                                l_cErrorMessage := "Success - Generated Script"
                            endif

                        endcase


                        :Disconnect()
                    endcase

                endwith

            else
                //Will connect without using the ORM

                do case
                case l_iPort == -1
                    l_cConnectionString := ""
                    l_cErrorMessage := "Unknown Server Type"
                case l_nConnectBackendType == HB_ORM_BACKENDTYPE_MARIADB .or. l_nConnectBackendType == HB_ORM_BACKENDTYPE_MYSQL   // MySQL or MariaDB
                    // To enable multi statements to be executed, meaning multiple SQL commands separated by ";", had to use the OPTION= setting.
                    // See: https://dev.mysql.com/doc/connector-odbc/en/connector-odbc-configuration-connection-parameters.html#codbc-dsn-option-flags
                    l_cConnectionString := "SERVER="+l_cConnectServer+";Driver={"+l_cDriver+"};USER="+l_cConnectUser+";PASSWORD="+l_cConnectPassword+";DATABASE="+l_cConnectDatabase+";PORT="+alltrim(str(l_iPort)+";OPTION=67108864;")
                case l_nConnectBackendType == HB_ORM_BACKENDTYPE_POSTGRESQL   // PostgreSQL
                    l_cConnectionString := "Server="+l_cConnectServer+";Port="+alltrim(str(l_iPort))+";Driver={"+l_cDriver+"};Uid="+l_cConnectUser+";Pwd="+l_cConnectPassword+";Database="+l_cConnectDatabase+";BoolsAsChar=0;"
                case l_nConnectBackendType == HB_ORM_BACKENDTYPE_MSSQL        // MSSQL
                    l_cConnectionString := "Driver={"+l_cDriver+"};Server="+l_cConnectServer+","+alltrim(str(l_iPort))+";Database="+l_cConnectDatabase+";Uid="+l_cConnectUser+";Pwd="+l_cConnectPassword+";Encrypt=no;Trusted_Connection=no;TrustServerCertificate=yes"  // Due to an issue with certificates had to turn off Encrypt and Trusted_Connection had to set to "no" since not using Windows Account.
                    //"Driver=ODBC Driver 17 for SQL Server;Server=192.168.4.105;Uid=sa;PWD=rndrnd;Encrypt=no;Database=test001;Trusted_Connection=no;TrustServerCertificate=yes"
                otherwise
                    l_cConnectionString := ""
                    l_cErrorMessage := "Invalid 'Backend Type'"
                endcase

                if !empty(l_cConnectionString)
                    l_iSQLHandle := hb_RDDInfo( RDDI_CONNECT, { "ODBC", l_cConnectionString })

                    if l_iSQLHandle == 0
                        l_iSQLHandle := -1
                        l_cErrorMessage := "Unable connect to the server!"+Chr(13)+Chr(10)+Str(hb_RDDInfo( RDDI_ERRORNO ))+Chr(13)+Chr(10)+hb_RDDInfo( RDDI_ERROR )
                        // l_cErrorMessage += Chr(13)+Chr(10)+l_cConnectionString

                    else
                        // SendToDebugView(l_cConnectionString)
                        do case
                        case l_cActionOnSubmit == "Load"
                            if oFcgi:p_nAccessLevelDD >= 6
                                l_cErrorMessage := LoadSchema(l_iSQLHandle,par_iApplicationPk,l_cSQLEngineType,l_cConnectDatabase,l_cConnectNamespaces,l_nConnectSetForeignKey)
                            else
                                l_cErrorMessage := "No Access."
                            endif
                            
                        case l_cActionOnSubmit == "Delta"
                            el_AUnpack( DeltaSchema(l_iSQLHandle,par_iApplicationPk,l_cSQLEngineType,l_cConnectDatabase,l_cConnectNamespaces,l_nConnectSetForeignKey) ,@l_cErrorMessage,@l_aDeltaMessages)

                        endcase

                        hb_RDDInfo(RDDI_DISCONNECT,,"SQLMIX",l_iSQLHandle)
                        // l_cErrorMessage := "Connected OK"
                    endif
                endif

            endif
        endif

    endcase

endcase

if !empty(l_cErrorMessage)
    l_cHtml += DataDictionaryDeploymentToolsFormBuild(par_cMode,par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,;
                                                      l_nFk_Deployment,;
                                                      l_aDeltaMessages,;
                                                      l_cErrorDetail,;
                                                      l_cScript)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TagListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:p_cSitePath
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
                l_cHtml += GetButtonOnEditFormNew("New Tag",l_cSitePath+[DataDictionaries/NewTag/]+par_cURLApplicationLinkCode+[/])
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif
    l_cHtml += GetNoRecordsOnFile("No Tag on file.")

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetButtonOnEditFormNew("New Tag",l_cSitePath+[DataDictionaries/NewTag/]+par_cURLApplicationLinkCode+[/])
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="5">Tags (]+Trans(l_nNumberOfTags)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name</th>]
                    l_cHtml += [<th class="text-white">Code</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Table<br>Use<br>Status</th>]
                    l_cHtml += [<th class="text-white text-center">Column<br>Use<br>Status</th>]
                l_cHtml += [</tr>]

                select ListOfTags
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditTag/]+par_cURLApplicationLinkCode+[/]+;
                                                                                           PrepareForURLSQLIdentifier("Tag",ListOfTags->Tag_Code,ListOfTags->pk)+[/]+;
                                                                                           [">]+TextToHtml(ListOfTags->Tag_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += ListOfTags->Tag_Code
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfTags->Tag_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Do Not Use","Active","Discontinued"}[iif(el_between(ListOfTags->Tag_TableUseStatus,TAGUSESTATUS_DONOTUSE,TAGUSESTATUS_DISCONTINUED),ListOfTags->Tag_TableUseStatus,TAGUSESTATUS_DONOTUSE)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Do Not Use","Active","Discontinued"}[iif(el_between(ListOfTags->Tag_ColumnUseStatus,TAGUSESTATUS_DONOTUSE,TAGUSESTATUS_DISCONTINUED),ListOfTags->Tag_ColumnUseStatus,TAGUSESTATUS_DONOTUSE)]
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

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Tag")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="100" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Code</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextCode" id="TextCode" value="]+FcgiPrepFieldForValue(l_cCode)+[" maxlength="10" size="10"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Table Use</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboTableUseStatus" id="ComboTableUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nTableUseStatus==1,[ selected],[])+[>Do Not Use</option>]
                l_cHtml += [<option value="2"]+iif(l_nTableUseStatus==2,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="3"]+iif(l_nTableUseStatus==3,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Column Use</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboColumnUseStatus" id="ComboColumnUseStatus">]
                l_cHtml += [<option value="1"]+iif(l_nColumnUseStatus==1,[ selected],[])+[>Do Not Use</option>]
                l_cHtml += [<option value="2"]+iif(l_nColumnUseStatus==2,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="3"]+iif(l_nColumnUseStatus==3,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

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
local l_oData

oFcgi:TraceAdd("TagEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTagPk              := Val(oFcgi:GetInputValue("TableKey"))
l_cTagName            := alltrim(SanitizeInput(oFcgi:GetInputValue("TextName")))
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

                            if empty(l_cErrorMessage)
                                l_iTagPk := 0
                            endif

                        endwith

                    endif
                endif
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iTagPk := 0

case l_cActionOnSubmit == "Delete"   // Tag
    if oFcgi:p_nAccessLevelDD >= 5
        if CheckIfAllowDestructiveTableDelete(par_iApplicationPk)
            l_cErrorMessage := CascadeDeleteTag(l_iTagPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("cff1bf6d-698a-4497-891e-4f435abca65c","TagTable")
                :Where("TagTable.fk_Tag = ^",l_iTagPk)
                :SQL()

                if :Tally == 0
                    :Table("cff1bf6d-698a-4497-891e-4f435abca65c","TagColumn")
                    :Where("TagColumn.fk_Tag = ^",l_iTagPk)
                    :SQL()

                    if :Tally == 0
                        :Delete("8b98caf8-3c1e-47f9-8f2e-975f2c5757a4","Tag",l_iTagPk)
                        l_iTagPk := 0

                    else
                        l_cErrorMessage := "Related Column Tag record on file"
                    endif
                else
                    l_cErrorMessage := "Related Table Tag record on file"
                endif
            endwith
        endif
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cTagName
    l_hValues["Code"]            := l_cTagCode
    l_hValues["TableUseStatus"]  := l_iTagTableUseStatus
    l_hValues["ColumnUseStatus"] := l_iTagColumnUseStatus
    l_hValues["Description"]     := l_cTagDescription

    l_cHtml += TagEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iTagPk,l_hValues)

case l_iTagPk = 0
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("74f631ed-169f-47be-b06a-e1a727cd3ff2","Tag")
        :Column("Tag.Name"   ,"Tag_Name")
        :Column("Tag.LinkUID","Tag_LinkUID")
        l_oData := l_oDB1:Get(l_iTagPk)
        if l_oDB1:Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditTag/"+par_cURLApplicationLinkCode+"/"+;
                                                                         PrepareForURLSQLIdentifier("Table",l_oData:Tag_Name,l_oData:Tag_LinkUID)+"/";
                                                                         )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTags/"+par_cURLApplicationLinkCode+"/")
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
static function TemplateTableListFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

oFcgi:TraceAdd("TemplateTableListFormOnSubmit")

l_cHtml += TemplateTableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)

return l_cHtml
//=================================================================================================================
static function TemplateTableListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB_ListOfTemplateTables       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTemplateColumnCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_oCursor
local l_iTemplateTablePk
local l_nTemplateColumnCount

local l_nNumberOfTemplateTables := 0
local l_ScriptFolder

oFcgi:TraceAdd("TemplateTableListFormBuild")

with object l_oDB_ListOfTemplateTables
    :Table("f99ba155-3bcd-48f8-bfde-0e9807fd029d","TemplateTable")
    :Column("TemplateTable.pk"         ,"pk")
    :Column("TemplateTable.Name"       ,"TemplateTable_Name")
    :Column("TemplateTable.LinkUID"    ,"TemplateTable_LinkUID")
    :Column("Upper(TemplateTable.Name)","tag1")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)

    :OrderBy("tag1")
    :SQL("ListOfTemplateTables")

    l_nNumberOfTemplateTables := :Tally

    // SendToClipboard(:LastSQL())

endwith

//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a el_seek technic will not be needed.
with object l_oDB_ListOfTemplateColumnCounts
    :Table("9ec6de51-00f8-4cb3-8b00-06b1bdad9f98","TemplateTable")
    :Column("TemplateTable.pk" ,"TemplateTable_pk")
    :Column("Count(*)" ,"TemplateColumnCount")
    :Join("inner","TemplateColumn","","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)
    :GroupBy("TemplateTable_pk")
    :SQL("ListOfTemplateColumnCounts")
    with object :p_oCursor
        :Index("tag1","TemplateTable_pk")
        :CreateIndexes()
    endwith
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

if oFcgi:p_nAccessLevelDD >= 5
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<table>]
                l_cHtml += [<tr>]
                    // ----------------------------------------
                    l_cHtml += [<td>]  // valign="top"
                        l_cHtml += GetButtonOnEditFormNew("New Template Table",l_cSitePath+[DataDictionaries/NewTemplateTable/]+par_cURLApplicationLinkCode+[/])
                    l_cHtml += [</td>]
                    // ----------------------------------------
                l_cHtml += [</tr>]
            l_cHtml += [</table>]

        l_cHtml += [</div>]
    l_cHtml += [</nav>]
else
    l_cHtml += GetAboveNavbarHeading("Template Tables")
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if empty(l_nNumberOfTemplateTables)
    l_cHtml += GetNoRecordsOnFile("No Template Table on file.")
else
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="2">Template Tables (]+Trans(l_nNumberOfTemplateTables)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Template Table Name</th>]
                l_cHtml += [<th class="text-white">Columns</th>]
            l_cHtml += [</tr>]

            select ListOfTemplateTables
            scan all
                l_iTemplateTablePk := ListOfTemplateTables->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/EditTemplateTable/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                 PrepareForURLSQLIdentifier("Table",ListOfTemplateTables->TemplateTable_Name,ListOfTemplateTables->TemplateTable_LinkUID)+[/]+;
                                                                                                 [">]+TextToHtml(ListOfTemplateTables->TemplateTable_Name)+[</a>]


                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_nTemplateColumnCount := iif( el_seek(l_iTemplateTablePk,"ListOfTemplateColumnCounts","tag1") , ListOfTemplateColumnCounts->TemplateColumnCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[DataDictionaries/ListTemplateColumns/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                   PrepareForURLSQLIdentifier("Table",ListOfTemplateTables->TemplateTable_Name,ListOfTemplateTables->TemplateTable_LinkUID)+[/]+;
                                                                                                   [">]+Trans(l_nTemplateColumnCount)+[</a>]
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function TemplateTableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cSitePath    := oFcgi:p_cSitePath

local l_oDB1         := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDataTemplateTableInfo

oFcgi:TraceAdd("TemplateTableEditFormBuild")

with object l_oDB1
    if !empty(par_iPk)
        :Table("48312a8d-fb40-4ba4-bd36-10a7fd1fb2e1","TemplateTable")
        :Column("TemplateTable.Name"    ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID" ,"TemplateTable_LinkUID")
        l_oDataTemplateTableInfo := :Get(par_iPk)
    endif
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TemplateTableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Template Table")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]

        // l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Back To Table Templates",l_cSitePath+[DataDictionaries/ListTemplateTables/]+par_cURLApplicationLinkCode+[/])
        l_cHtml += GetNextPreviousTemplateTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iPk,"EditTemplateTable")

        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
            l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Columns",l_cSitePath+[DataDictionaries/ListTemplateColumns/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                                          PrepareForURLSQLIdentifier("Table",l_oDataTemplateTableInfo:TemplateTable_Name,l_oDataTemplateTableInfo:TemplateTable_LinkUID)+[/];
                                                                                                                          )
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Template Table Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function TemplateTableEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTemplateTablePk
local l_cTemplateTableName
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("TemplateTableEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iTemplateTablePk   := Val(oFcgi:GetInputValue("TemplateTableKey"))

// l_cTemplateTableName := SanitizeInputSQLIdentifier("Table",oFcgi:GetInputValue("TextName"))
l_cTemplateTableName := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cTemplateTableName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("ad8423f4-99a7-4114-87fb-c60c7691e1d7","TemplateTable")
                :Column("TemplateTable.pk","pk")
                :Where([TemplateTable.fk_Application = ^],par_iApplicationPk)
                :Where([lower(replace(TemplateTable.Name,' ','')) = ^],lower(StrTran(l_cTemplateTableName," ","")))
                if l_iTemplateTablePk > 0
                    :Where([TemplateTable.pk != ^],l_iTemplateTablePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Template Table
        with object l_oDB1
            :Table("ef689ed2-670f-4560-a5d2-5e1981e4ab33","TemplateTable")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("TemplateTable.Name",l_cTemplateTableName)
            endif
            if empty(l_iTemplateTablePk)
                :Field("TemplateTable.fk_Application",par_iApplicationPk)
                :Field("TemplateTable.LinkUID"       ,oFcgi:p_o_SQLConnection:GetUUIDString())
                if :Add()
                    l_iTemplateTablePk := :Key()
                else
                    l_cErrorMessage := "Failed to add Template Table."
                endif
            else
                if !:Update(l_iTemplateTablePk)
                    l_cErrorMessage := "Failed to update Template Table."
                endif
            endif

        endwith
    endif

    // if empty(l_cErrorMessage)
    //     l_iTemplateTablePk := 0
    // endif

case l_cActionOnSubmit == "Cancel"
case l_cActionOnSubmit == "Done"
    l_iTemplateTablePk := 0
    
case l_cActionOnSubmit == "Delete"   // Table
    if oFcgi:p_nAccessLevelDD >= 5
        l_cErrorMessage := CascadeDeleteTemplateTable(l_iTemplateTablePk)
        if empty(l_cErrorMessage)
            l_iTemplateTablePk := 0
        endif
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"] := l_cTemplateTableName

    l_cHtml += TemplateTableEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iTemplateTablePk,l_hValues)

case empty(l_iTemplateTablePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateTables/"+par_cURLApplicationLinkCode+"/")

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    with object l_oDB1
        :Table("bf3fd002-455f-4ddd-a2a8-4d930f91f4f1","TemplateTable")
        :Column("TemplateTable.Name"   ,"TemplateTable_Name")
        :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
        l_oData := :Get(l_iTemplateTablePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditTemplateTable/"+par_cURLApplicationLinkCode+"/"+;
                                                                                   PrepareForURLSQLIdentifier("Table",l_oData:TemplateTable_Name,l_oData:TemplateTable_LinkUID)+"/";
                                                                                   )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateTables/"+par_cURLApplicationLinkCode+"/")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
static function TemplateColumnListFormBuild(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB_Application           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTemplateColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfTemplateColumns := 0
local l_iTemplateColumnPk
local l_oData_Application
local l_cApplicationSupportColumns
local l_cURL
local l_cName
local l_cCombinedPath

local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("TemplateColumnListFormBuild")

with object l_oDB_Application
    :Table("21f206fb-4bb4-4061-8be1-72246ceebc1f","Application")
    :Column("Application.SupportColumns" , "Application_SupportColumns")
    l_oData_Application := :Get(par_iApplicationPk)
    l_cApplicationSupportColumns := nvl(l_oData_Application:Application_SupportColumns,"")
endwith

with object l_oDB_ListOfTemplateColumns
    :Table("0e2533d1-317f-4953-80ce-e6bae8ed2542","TemplateColumn")
    :Where("TemplateColumn.fk_TemplateTable = ^",par_iTemplateTablePk)
    l_nNumberOfTemplateColumns := :Count()

    :Table("9a0ac423-cfe4-48f8-a6da-36211dae310e","TemplateColumn")
    :Column("TemplateColumn.pk"                 ,"pk")
    :Column("TemplateColumn.Name"               ,"TemplateColumn_Name")
    :Column("TemplateColumn.AKA"                ,"TemplateColumn_AKA")
    :Column("TemplateColumn.LinkUID"            ,"TemplateColumn_LinkUID")
    :Column("TemplateColumn.UsedAs"             ,"TemplateColumn_UsedAs")
    :Column("TemplateColumn.UsedBy"             ,"TemplateColumn_UsedBy")
    :Column("TemplateColumn.UseStatus"          ,"TemplateColumn_UseStatus")
    :Column("TemplateColumn.DocStatus"          ,"TemplateColumn_DocStatus")
    :Column("TemplateColumn.Description"        ,"TemplateColumn_Description")
    :Column("TemplateColumn.Order"              ,"TemplateColumn_Order")
    :Column("TemplateColumn.Type"               ,"TemplateColumn_Type")
    :Column("TemplateColumn.Array"              ,"TemplateColumn_Array")
    :Column("TemplateColumn.Length"             ,"TemplateColumn_Length")
    :Column("TemplateColumn.Scale"              ,"TemplateColumn_Scale")
    :Column("TemplateColumn.Nullable"           ,"TemplateColumn_Nullable")
    :Column("TemplateColumn.DefaultType"        ,"TemplateColumn_DefaultType")
    :Column("TemplateColumn.DefaultCustom"      ,"TemplateColumn_DefaultCustom")
    :Column("TemplateColumn.Unicode"            ,"TemplateColumn_Unicode")

    :Where("TemplateColumn.fk_TemplateTable = ^",par_iTemplateTablePk)

    :OrderBy("TemplateColumn_Order")
    :SQL("ListOfTemplateColumns")

endwith

l_cHtml += [<style>]
l_cHtml += [ .tooltip-inner {max-width: 700px;opacity: 1.0;background-color: #198754;} ]
l_cHtml += [ .tooltip.show {opacity:1.0} ]
l_cHtml += [</style>]

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Table" ,par_oNavData:TemplateTable_Name ,par_oNavData:TemplateTable_LinkUID) +[/]

AssembleNavbarInfo("Add",{"Table" ,par_oNavData:TemplateTable_Name , ,par_oNavData:TemplateTable_LinkUID})

l_cHtml += GetAboveNavbarHeading("Columns","Template Table",AssembleNavbarInfo("Build"))

if l_nNumberOfTemplateColumns <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += GetNextPreviousTemplateTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTemplateTablePk,"ListTemplateColumns")

            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Column",l_cSitePath+[DataDictionaries/NewTemplateColumn/]+l_cCombinedPath)
            endif

            l_cHtml += GetButtonOnListFormCaptionAndRedirect("Edit Template Table"    ,l_cSitePath+[DataDictionaries/EditTemplateTable/]+l_cCombinedPath)
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    l_cHtml += GetNoRecordsOnFile("No Column on file.")

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += GetNextPreviousTemplateTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTemplateTablePk,"ListTemplateColumns")

            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Column",l_cSitePath+[DataDictionaries/NewTemplateColumn/]+l_cCombinedPath)
                if l_nNumberOfTemplateColumns > 1
                    l_cHtml += GetButtonOnListFormCaptionAndRedirect("Order Columns",l_cSitePath+[DataDictionaries/OrderTemplateColumns/]+l_cCombinedPath)
                endif
            endif
            l_cHtml += GetButtonOnListFormCaptionAndRedirect("Edit Template Table",l_cSitePath+[DataDictionaries/EditTemplateTable/]+l_cCombinedPath)
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer


    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-center text-white" colspan="8">]
                    l_cHtml += [Columns (]+Trans(l_nNumberOfTemplateColumns)+[) for Table "]+TextToHtml(par_oNavData:TemplateTable_Name+FormatAKAForDisplay(par_oNavData:TemplateTable_AKA))+["]
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                if oFcgi:p_nAccessLevelDD >= 5
                    l_cHtml += [<th class="text-center"><a href="]+l_cSitePath+[DataDictionaries/NewTemplateColumn/]+l_cCombinedPath+["><span class="text-white bi-plus-lg"></span></a></th>]
                else
                    l_cHtml += [<th class="text-white"></th>]
                endif
                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Type</th>]
                l_cHtml += [<th class="text-white">Nullable</th>]
                l_cHtml += [<th class="text-white">Default</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [<th class="text-white text-center">Doc<br>Status</th>]
                // l_cHtml += [<th class="text-white text-center">Used By</th>]
            l_cHtml += [</tr>]

            select ListOfTemplateColumns
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfTemplateColumns->TemplateColumn_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        do case
                        case ListOfTemplateColumns->TemplateColumn_UsedAs = 2
                            l_cHtml += [<i class="bi bi-key"></i>]
                        case ListOfTemplateColumns->TemplateColumn_UsedAs = 3
                            l_cHtml += [<i class="bi-arrow-right"></i>]
                        case (ListOfTemplateColumns->TemplateColumn_UsedAs = 4) .or. (ListOfTemplateColumns->TemplateColumn_UsedAs = 1 .and. " "+lower(ListOfTemplateColumns->TemplateColumn_Name)+" " $ " "+lower(l_cApplicationSupportColumns)+" ")
                            l_cHtml += [<i class="bi bi-tools"></i>]
                        endcase
                    l_cHtml += [</td>]

                    // Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cURL  := l_cSitePath+[DataDictionaries/EditTemplateColumn/]+l_cCombinedPath+;
                                                                                      PrepareForURLSQLIdentifier("Column",ListOfTemplateColumns->TemplateColumn_Name,ListOfTemplateColumns->TemplateColumn_LinkUID)
                        l_cName := TextToHTML(ListOfTemplateColumns->TemplateColumn_Name+FormatAKAForDisplay(ListOfTemplateColumns->TemplateColumn_AKA))
                        if ListOfTemplateColumns->TemplateColumn_UsedBy <> USEDBY_ALLSERVERS
                            l_cURL  += [:]+trans(ListOfTemplateColumns->TemplateColumn_UsedBy)
                            l_cName += [ (]+GetItemInListAtPosition(ListOfTemplateColumns->TemplateColumn_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
                        endif
                        l_cHtml += [<a href="]+l_cURL+[/">]+l_cName+[</a>]
                    l_cHtml += [</td>]

                    // Type
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]

                        l_cHtml += FormatColumnTypeInfo(alltrim(ListOfTemplateColumns->TemplateColumn_Type),;
                                                        ListOfTemplateColumns->TemplateColumn_Length,;
                                                        ListOfTemplateColumns->TemplateColumn_Scale,;
                                                        ListOfTemplateColumns->TemplateColumn_Unicode,;
                                                        "",;                                                    // ListOfTemplateColumns->Namespace_Name   (Used to decide if should display Namespace info)
                                                        ,;                                                      // ListOfTemplateColumns->EnumerationNamespace_Name
                                                        ,;                                                      // ListOfTemplateColumns->EnumerationNamespace_AKA
                                                        ,;                                                      // ListOfTemplateColumns->EnumerationNamespace_LinkUID
                                                        ,;                                                      // ListOfTemplateColumns->Enumeration_Name
                                                        ,;                                                      // ListOfTemplateColumns->Enumeration_AKA
                                                        ,;                                                      // ListOfTemplateColumns->Enumeration_LinkUID
                                                        ,;                                                      // ListOfTemplateColumns->Enumeration_ImplementAs
                                                        ,;                                                      // ListOfTemplateColumns->Enumeration_ImplementLength
                                                        l_cSitePath,;
                                                        par_cURLApplicationLinkCode,;
                                                        "")                                                     // l_cTooltipEnumValues

                        if ListOfTemplateColumns->TemplateColumn_Array
                            l_cHtml += " [Array]"
                        endif
                    l_cHtml += [</td>]

                    // Nullable
                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        l_cHtml += iif(ListOfTemplateColumns->TemplateColumn_Nullable,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    // Default
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += GetColumnDefault(.f.,ListOfTemplateColumns->TemplateColumn_Type,ListOfTemplateColumns->TemplateColumn_DefaultType,ListOfTemplateColumns->TemplateColumn_DefaultCustom)
                        // l_cHtml += nvl(ListOfTemplateColumns->TemplateColumn_DefaultCustom,"")
                    l_cHtml += [</td>]

                    // Description
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfTemplateColumns->TemplateColumn_Description,""))
                    l_cHtml += [</td>]

                    // Usage Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfTemplateColumns->TemplateColumn_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfTemplateColumns->TemplateColumn_UseStatus,USESTATUS_UNKNOWN)]
                    l_cHtml += [</td>]

                    // Doc Status
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Not Needed","Composing","Completed"}[iif(el_between(ListOfTemplateColumns->TemplateColumn_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfTemplateColumns->TemplateColumn_DocStatus,DOCTATUS_MISSING)]
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function TemplateColumnListFormOnSubmit(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

oFcgi:TraceAdd("TemplateColumnListFormOnSubmit")

l_cHtml += TemplateColumnListFormBuild(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)

return l_cHtml
//=================================================================================================================
static function TemplateColumnOrderFormBuild(par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []
local l_oDB_ListOfTemplateColumns
local l_cSitePath := oFcgi:p_cSitePath
local l_cName

oFcgi:TraceAdd("TemplateColumnOrderFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iTemplateTablePk)+[">]
l_cHtml += [<input type="hidden" name="ColumnOrder" id="ColumnOrder" value="">]

l_oDB_ListOfTemplateColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_ListOfTemplateColumns
    :Table("801a200e-03cd-4a32-9898-8736f1a289ab","TemplateColumn")
    :Column("TemplateColumn.pk"    ,"pk")
    :Column("TemplateColumn.Name"  ,"TemplateColumn_Name")
    :Column("TemplateColumn.AKA"   ,"TemplateColumn_AKA")
    :Column("TemplateColumn.UsedAs","TemplateColumn_UsedAs")
    :Column("TemplateColumn.UsedBy","TemplateColumn_UsedBy")
    :Column("TemplateColumn.Order" ,"TemplateColumn_Order")
    :Where("TemplateColumn.fk_TemplateTable = ^",par_iTemplateTablePk)
    :OrderBy("TemplateColumn_order")
    :SQL("ListOfTemplateColumns")
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

select ListOfTemplateColumns

AssembleNavbarInfo("Add",{"Table" ,par_oNavData:TemplateTable_Name , ,par_oNavData:TemplateTable_LinkUID})

l_cHtml += GetAboveNavbarHeading("Order Columns","Template Table",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnOrderListFormSave()
        endif
        l_cHtml += GetButtonCancelAndRedirect(l_cSitePath+[DataDictionaries/ListTemplateColumns/]+par_cURLApplicationLinkCode+[/]+;
                                                                                                  PrepareForURLSQLIdentifier("Template Table",par_oNavData:TemplateTable_Name,par_oNavData:TemplateTable_LinkUID)+[/];
                                                                                                  )

    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]
    l_cHtml += [<div class="col-auto">]

    l_cHtml += [<ul id="sortable">]
    scan all
        l_cName := TextToHTML(ListOfTemplateColumns->TemplateColumn_Name+FormatAKAForDisplay(ListOfTemplateColumns->TemplateColumn_AKA))
        if ListOfTemplateColumns->TemplateColumn_UsedBy <> USEDBY_ALLSERVERS
            l_cName += [ (]+GetItemInListAtPosition(ListOfTemplateColumns->TemplateColumn_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
        endif
        l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfTemplateColumns->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+l_cName+[</span></li>]
    endscan
    l_cHtml += [</ul>]

    l_cHtml += [</div>]
l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function TemplateColumnOrderFormOnSubmit(par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_iTemplateTablePk
local l_cTemplateColumnPkOrder

local l_oDB_ListOfTemplateColumns
local l_aOrderedPks
local l_Counter

oFcgi:TraceAdd("TemplateColumnOrderFormOnSubmit")

l_cActionOnSubmit        := oFcgi:GetInputValue("ActionOnSubmit")
l_iTemplateTablePk       := Val(oFcgi:GetInputValue("TableKey"))
l_cTemplateColumnPkOrder := SanitizeInput(oFcgi:GetInputValue("ColumnOrder"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cTemplateColumnPkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB_ListOfTemplateColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfTemplateColumns
            :Table("d2c91b8e-25c6-4272-a7ae-ab3558c3dc7a","TemplateColumn")
            :Column("TemplateColumn.pk"   ,"pk")
            :Column("TemplateColumn.Order","order")
            :Where([TemplateColumn.fk_TemplateTable = ^],l_iTemplateTablePk)
            :SQL("ListOfTemplateColumn")
    
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
    
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if el_seek(val(l_aOrderedPks[l_Counter]),"ListOfTemplateColumn","pk") .and. ListOfTemplateColumn->order <> l_Counter
                with object l_oDB_ListOfTemplateColumns
                    :Table("6b5afb31-c1f8-469f-b21c-e98b13eef91d","TemplateColumn")
                    :Field("TemplateColumn.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                             PrepareForURLSQLIdentifier("Table",par_oNavData:TemplateTable_Name,par_oNavData:TemplateTable_LinkUID)+"/";
                                                                             )

endcase

return l_cHtml
//=================================================================================================================
static function TemplateColumnEditFormBuild(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText          := hb_DefaultValue(par_cErrorText,"")
local l_cName               := hb_HGetDef(par_hValues,"Name","")
local l_cAKA                := nvl(hb_HGetDef(par_hValues,"AKA",""),"")
local l_nUsedAs             := hb_HGetDef(par_hValues,"UsedAs",1)
local l_nUsedBy             := hb_HGetDef(par_hValues,"UsedBy",USEDBY_ALLSERVERS)
local l_nUseStatus          := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus          := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription        := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cType               := alltrim(hb_HGetDef(par_hValues,"Type",""))
local l_lArray              := hb_HGetDef(par_hValues,"Array",.f.)
local l_cLength             := Trans(nvl(hb_HGetDef(par_hValues,"Length",0),0))
local l_cScale              := Trans(nvl(hb_HGetDef(par_hValues,"Scale",0),0))
local l_lNullable           := hb_HGetDef(par_hValues,"Nullable",.t.)
local l_nDefaultType        := nvl(hb_HGetDef(par_hValues,"DefaultType",0),0)
local l_cDefaultCustom      := nvl(hb_HGetDef(par_hValues,"DefaultCustom",""),"")
local l_lUnicode            := hb_HGetDef(par_hValues,"Unicode",.t.)
local l_lShowPrimary        := hb_HGetDef(par_hValues,"ShowPrimary",.f.)

local l_iTypeCount

local l_oDB_Application   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_TemplateTable := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:p_cSitePath
local l_ScriptFolder

local l_json_Entities
local l_hEntityNames := {=>}
local l_cEntityInfo
local l_cObjectName

local l_nOptionNumber
local l_cCallOnChangeSettings := [OnChangeSettings($("#ComboUsedAs").val(),$("#ComboType").val(),$("#ComboDefaultType").val())]

local l_oData_Application
local l_lUseApplicationSettingsForKeys
local l_cKeyType

local l_cListOfColumnsForArray
local l_cSupportColumnName

local l_cCombinedPath

oFcgi:TraceAdd("TemplateColumnEditFormBuild")

with object l_oDB_Application
    :Table("98ab94cf-0bd7-4099-ab74-6389f9f4b57a","Application")
    :Column("Application.KeyConfig"      ,"Application_KeyConfig")
    :Column("Application.SupportColumns" ,"Application_SupportColumns")
    l_oData_Application := :Get(par_iApplicationPk)
endwith

do case
case l_oData_Application:Application_KeyConfig == 2
    l_lUseApplicationSettingsForKeys := .t.
    l_cKeyType := "I"
case l_oData_Application:Application_KeyConfig == 3
    l_lUseApplicationSettingsForKeys := .t.
    l_cKeyType := "IB"
otherwise
    l_lUseApplicationSettingsForKeys := .f.
    l_cKeyType := "?"
endcase

with object l_oDB_TemplateTable
    :Table("3d374987-3ef7-4f1c-91de-02341340b015","TemplateTable")
    :Column("TemplateTable.pk"          , "TemplateTable_pk")
    :Column("TemplateTable.Name"        , "TemplateTable_Name")
    :Column("upper(TemplateTable.Name)" , "tag1")
    :OrderBy("tag1")
    :Where("TemplateTable.fk_Application = ^" , par_iApplicationPk)
    :SQL("ListOfTemplateTable")
endwith

l_cHtml += [<script language="javascript">]
//----------------------------------------------------------------------------
l_cHtml += [function OnChangeSettings(par_cUsedAs,par_cType,par_cDefaultType) {]

    l_cHtml += [switch(par_cUsedAs) {]

    l_cHtml += [  case '2': ]  // PrimaryKey
    l_cHtml +=   [$('#EntryNullable').hide();]
    l_cHtml +=   [$('#CheckNullable').prop('checked', false);]

    l_cHtml +=   [$('#EntryArray').hide();]
    l_cHtml +=   [$('#CheckArray').prop('checked', false);]

    if l_lUseApplicationSettingsForKeys
        l_cHtml +=   [$('#EntryType').hide();]
        l_cHtml +=   [par_cType = ']+l_cKeyType+[';]
        l_cHtml +=   [$('#EntryType').val(']+l_cKeyType+[');]

        l_cHtml +=   [$('#EntryDefaultType').hide();]
        l_cHtml +=   [par_cDefaultType = '15';]
        l_cHtml +=   [$('#EntryDefaultType').val('15');]
    else
        l_cHtml +=   [$('#EntryType').show();]
        l_cHtml +=   [$('#EntryDefaultType').show();]
    endif
    l_cHtml += [    break;]

    l_cHtml += [  case '3': ]  // ForeignKey
    if l_lUseApplicationSettingsForKeys
        l_cHtml +=   [$('#EntryNullable').hide();]
        l_cHtml +=   [$('#CheckNullable').prop('checked', true);]

        l_cHtml +=   [$('#EntryType').hide();]
        l_cHtml +=   [par_cType = ']+l_cKeyType+[';]
        l_cHtml +=   [$('#EntryType').val(']+l_cKeyType+[');]

        l_cHtml +=   [$('#EntryDefaultType').hide();]
        l_cHtml +=   [par_cDefaultType = '0';]
        l_cHtml +=   [$('#EntryDefaultType').val('0');]
    else
        l_cHtml +=   [$('#EntryNullable').show();]
        l_cHtml +=   [$('#EntryType').show();]
        l_cHtml +=   [$('#EntryDefaultType').show();]
    endif
    
    l_cHtml +=   [$('#EntryArray').hide();]
    l_cHtml +=   [$('#CheckArray').prop('checked', false);]

    l_cHtml += [    break;]

    l_cHtml += [  default:]  //Regular or Support
    l_cHtml +=   [$('#EntryNullable').show();]
    l_cHtml +=   [$('#EntryType').show();]
    l_cHtml +=   [$('#EntryArray').show();]

    l_cHtml +=   [$('#EntryDefaultType').show();]
    l_cHtml += [};]

    l_cHtml += [switch(par_cType) {]
    for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
        l_cHtml += [  case ']+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+[':]
        l_cHtml += [  $('#SpanLength').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_LENGTH],[show],[hide])+[();]
        l_cHtml +=   [$('#SpanScale').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_SCALE],[show],[hide])+[();]
        // l_cHtml +=   [$('#SpanEnumeration').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_ENUMS],[show],[hide])+[();]
        l_cHtml +=   [$('#EntryUnicode').]+iif(oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_SHOW_UNICODE],[show],[hide])+[();]
        l_cHtml += [    break;]
    endfor
    l_cHtml += [  default:]
    l_cHtml += [  $('#SpanLength').hide();$('#SpanScale').hide();$('#SpanEnumeration').hide();]
    l_cHtml += [};]

    l_cHtml += [switch(par_cType) {]
    l_cHtml += [  case 'L':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="13">False</option>')]
        l_cHtml += [.append('<option value="14">True</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'D':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="10">Today</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'TOZ':]
    l_cHtml += [  case 'TO':]
    l_cHtml += [  case 'DTZ':]
    l_cHtml += [  case 'DT':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="11">Now</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'I':]
    l_cHtml += [  case 'IB':]
    l_cHtml += [  case 'IS':]
    l_cHtml += [  case 'N':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="15">Auto Increment</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  case 'UUI':]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [.append('<option value="12">Random uuid</option>')]
        l_cHtml += [;break;]
    l_cHtml += [  default:]
        l_cHtml += [  $('#ComboDefaultType').find("option").remove().end()]
        l_cHtml += [.append('<option value="0"></option>')]
        l_cHtml += [.append('<option value="1">Custom</option>')]
        l_cHtml += [;]
    l_cHtml += [};]

    l_cHtml += [$('#ComboDefaultType').val(par_cDefaultType);]  // Since we called .remove().end() we need to reset the value

    l_cHtml += [switch(par_cDefaultType) {]
    l_cHtml += [  case '1':]  // Custom Default
    l_cHtml +=   [ $('#EntryDefaultCustom').show();]
    l_cHtml +=   [ break;]

    l_cHtml += [  default:]
    l_cHtml +=   [ $('#EntryDefaultCustom').hide();]
    l_cHtml +=   [ break;]
    l_cHtml += [};]

l_cHtml += [};]
//----------------------------------------------------------------------------
l_cHtml += [</script>] 

oFcgi:p_cjQueryScript += l_cCallOnChangeSettings+[;]

SetSelect2Support()

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += [<input type="hidden" name="CheckShowPrimary" value="]+iif(l_lShowPrimary,"1","0")+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                   PrepareForURLSQLIdentifier("Table" ,par_oNavData:TemplateTable_Name ,par_oNavData:TemplateTable_LinkUID) +[/]

AssembleNavbarInfo("Add",{"Table" ,par_oNavData:TemplateTable_Name , ,par_oNavData:TemplateTable_LinkUID})

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+" Column","Template Table",AssembleNavbarInfo("Build"))

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += GetNextPreviousTemplateColumn(par_iTemplateTablePk,l_cCombinedPath,par_iPk)
        if oFcgi:p_nAccessLevelDD >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 5
                l_cHtml += GetButtonOnEditFormNew("New Column",l_cSitePath+[DataDictionaries/NewTemplateColumn/]+l_cCombinedPath)
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

// Code to dynamically show/hide "Implicit Support"
l_cHtml += [<script type="text/javascript">]
l_cHtml += [function UpdateImplicitSupportNotice()]
l_cHtml += [{]
l_cListOfColumnsForArray := ""
for each l_cSupportColumnName in hb_ATokens( nvl(l_oData_Application:Application_SupportColumns,"") , " " ,.f.)
    if !empty(l_cListOfColumnsForArray)
        l_cListOfColumnsForArray += ","
    endif
    l_cListOfColumnsForArray += ["]+l_cSupportColumnName+["]
endfor
l_cHtml += 'const j_PossibleValues = ['+l_cListOfColumnsForArray+'];'
l_cHtml += [if( ($("#TextName").val()) && j_PossibleValues.includes( $("#TextName").val() ))]
l_cHtml += [ $("#TextImplicitSupport").show();]
l_cHtml += [else]
l_cHtml += [ $("#TextImplicitSupport").hide();]
l_cHtml += [}]
l_cHtml += [</script>]
oFcgi:p_cjQueryScript += [UpdateImplicitSupportNotice();]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" onchange="UpdateImplicitSupportNotice();" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">AKA</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAKA" id="TextAKA" value="]+FcgiPrepFieldForValue(l_cAKA)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used As</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboUsedAs" id="ComboUsedAs" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedAs==1,[ selected],[])+[></option>]
            if l_lShowPrimary
                l_cHtml += [<option value="2"]+iif(l_nUsedAs==2,[ selected],[])+[>Primary Key</option>]
            endif
            l_cHtml += [<option value="3"]+iif(l_nUsedAs==3,[ selected],[])+[>Foreign Key</option>]
            l_cHtml += [<option value="4"]+iif(l_nUsedAs==4,[ selected],[])+[>Support</option>]
            l_cHtml += [</select>]

            l_cHtml += [<span class="ms-5" id="TextImplicitSupport">Implicitly "Support"</span>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Used By</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUsedBy" id="ComboUsedBy"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="1"]+iif(l_nUsedBy==1,[ selected],[])+[>All Servers</option>]
            l_cHtml += [<option value="2"]+iif(l_nUsedBy==2,[ selected],[])+[>MySQL Only</option>]
            l_cHtml += [<option value="3"]+iif(l_nUsedBy==3,[ selected],[])+[>PostgreSQL Only</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryType">]
        l_cHtml += [<td class="pe-2 pb-3">Type</td>]
        l_cHtml += [<td class="pb-3">]

            l_cHtml += [<span class="pe-5">]
                l_cHtml += [<select name="ComboType" id="ComboType" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
                for l_iTypeCount := 1 to len(oFcgi:p_ColumnTypes)
                    l_cHtml += [<option value="]+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+["]+iif(l_cType==oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE],[ selected],[])+[>]+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_CODE]+" - "+oFcgi:p_ColumnTypes[l_iTypeCount,COLUMN_TYPES_NAME]+[</option>]
                endfor
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanLength" style="display: none;">]
                l_cHtml += [<span class="pe-2">Length</span><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextLength" id="TextLength" value="]+FcgiPrepFieldForValue(l_cLength)+[" size="5" maxlength="5"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="pe-5" id="SpanScale" style="display: none;">]
                l_cHtml += [<span class="pe-2">Scale</span><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextScale" id="TextScale" value="]+FcgiPrepFieldForValue(l_cScale)+[" size="2" maxlength="2"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [</span>]

        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryNullable">]
        l_cHtml += [<td class="pe-2 pb-3">Nullable</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckNullable" id="CheckNullable" value="1"]+iif(l_lNullable," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryArray">]
        l_cHtml += [<td class="pe-2 pb-3">Array</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckArray" id="CheckArray" value="1"]+iif(l_lArray," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<span class="ps-3">(PostgreSQL Only)</span>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]

   l_cHtml += [<tr class="pb-5" id="EntryDefaultType">]
        l_cHtml += [<td class="pe-2 pb-3">Default Options</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select name="ComboDefaultType" id="ComboDefaultType" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+l_cCallOnChangeSettings+[;']+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
            l_cHtml += [<option value="0"]+iif(l_nDefaultType==0,[ selected],[])+[></option>]
            l_cHtml += [<option value="1"]+iif(l_nDefaultType==1,[ selected],[])+[></option>]
            for l_nOptionNumber := 10 to 30   //Originally have to list all possible values, so that the initial OnChangeDefaultType() will position on the correct option.
                l_cHtml += [<option value="]+trans(l_nOptionNumber)+["]+iif(l_nDefaultType==l_nOptionNumber,[ selected],[])+[></option>]
            endfor
            
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryDefaultCustom">]
        l_cHtml += [<td class="pe-2 pb-3">Default</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextDefaultCustom" id="TextDefaultCustom" value="]+FcgiPrepFieldForValue(l_cDefaultCustom)+[" size="80"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5" id="EntryUnicode">]
        l_cHtml += [<td class="pe-2 pb-3">Unicode</td>]
        l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
            l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="CheckUnicode" id="CheckUnicode" value="1"]+iif(l_lUnicode," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
        l_cHtml += [</div></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus"]+iif(oFcgi:p_nAccessLevelDD >= 5,[],[ disabled])+[>]
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
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]
                l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelDD >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function TemplateColumnEditFormOnSubmit(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData)
local l_cHtml := []

local l_cActionOnSubmit
local l_iPk
local l_cName
local l_cAKA
local l_nUsedAs
local l_nUsedBy
local l_nUseStatus
local l_nDocStatus
local l_cDescription
local l_cType
local l_lArray
local l_cLength
local l_nLength
local l_cScale
local l_nScale
local l_lNullable
local l_nDefaultType
local l_cDefaultCustom
local l_lUnicode
local l_lShowPrimary

local l_iColumnOrder
local l_iTypePos   //The position in the oFcgi:p_ColumnTypes array

local l_hValues := {=>}

local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1
local l_oData

oFcgi:TraceAdd("TemplateColumnEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iPk                 := Val(oFcgi:GetInputValue("TableKey"))

l_lShowPrimary        := (oFcgi:GetInputValue("CheckShowPrimary") == "1")

// l_cName               := SanitizeInputSQLIdentifier("Column",oFcgi:GetInputValue("TextName"))
l_cName               := SanitizeNameIdentifier(oFcgi:GetInputValue("TextName"))
l_cAKA                := SanitizeInput(oFcgi:GetInputValue("TextAKA"))
if empty(l_cAKA)
    l_cAKA := NIL
endif

l_nUsedAs             := Val(oFcgi:GetInputValue("ComboUsedAs"))

l_nUsedBy             := Val(oFcgi:GetInputValue("ComboUsedBy"))

l_nUseStatus          := Val(oFcgi:GetInputValue("ComboUseStatus"))

l_cType               := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("ComboType"))
l_lArray              := (oFcgi:GetInputValue("CheckArray") == "1")

l_cLength             := SanitizeInput(oFcgi:GetInputValue("TextLength"))
l_nLength             := iif(empty(l_cLength),NULL,val(l_cLength))

l_cScale              := SanitizeInput(oFcgi:GetInputValue("TextScale"))
l_nScale              := iif(empty(l_cScale),NULL,val(l_cScale))

l_lNullable           := (oFcgi:GetInputValue("CheckNullable") == "1")

l_nDefaultType        := Val(oFcgi:GetInputValue("ComboDefaultType"))

l_cDefaultCustom      := SanitizeInput(oFcgi:GetInputValue("TextDefaultCustom"))
if empty(l_cDefaultCustom)
    l_cDefaultCustom := NIL
endif

l_lUnicode            := (oFcgi:GetInputValue("CheckUnicode") == "1")

l_nDocStatus          := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cDescription        := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelDD >= 5
        if empty(l_cName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("a383c3f2-7ee1-45e2-aa62-2c51a25a461a","TemplateColumn")
                :Column("TemplateColumn.pk","pk")
                :Where([TemplateColumn.fk_TemplateTable = ^],par_iTemplateTablePk)
                :Where([lower(replace(TemplateColumn.Name,' ','')) = ^],lower(StrTran(l_cName," ","")))
                if l_iPk > 0
                    :Where([TemplateColumn.pk != ^],l_iPk)
                endif
                :SQL()
            endwith
            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                l_iTypePos := hb_Ascan(oFcgi:p_ColumnTypes,{|aSettings| aSettings[COLUMN_TYPES_CODE] == l_cType},,,.t.)   // Exact Match Search on the first column of the 2 dimension array.
                if l_iTypePos <= 0
                    l_cErrorMessage := [Failed to find "Column Type" definition.]
                else
                    
                    do case
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]) .and. hb_IsNIL(l_nLength)   // Length should be entered
                        l_cErrorMessage := "Length is required!"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE]) .and. hb_IsNIL(l_nScale)   // Scale should be entered
                        l_cErrorMessage := "Scale is required! Enter at the minimum 0"
                        
                    case (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH]) .and. (oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE]) .and. l_nScale >= l_nLength
                        l_cErrorMessage := "Scale must be smaller than Length!"

                    case !hb_IsNIL(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE]) .and. l_nScale > oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE]
                        l_cErrorMessage := "Scale may not exceed "+trans(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_MAX_SCALE])+"!"

                    otherwise

                    endcase
                endif
            endif

            if empty(l_cErrorMessage)
                //Test that will not mark more than 1 field as Primary
                if l_nUsedAs = 2
                    with object l_oDB1
                        :Table("c2cd33e5-28e3-43b8-b387-26a86783273e","TemplateColumn")
                        :Column("TemplateColumn.pk","pk")
                        :Where([TemplateColumn.fk_TemplateTable = ^],par_iTemplateTablePk)
                        :Where("TemplateColumn.UsedAs = 2")
                        if l_iPk > 0
                            :Where([TemplateColumn.pk != ^],l_iPk)
                        endif
                        :SQL()
                        if :tally <> 0
                            l_cErrorMessage := [Another column is already marked as "Primary".]
                        endif
                    endwith
                endif
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //If adding a column, find out what the last order is
        l_iColumnOrder := 1
        if empty(l_iPk)
            with object l_oDB1
                :Table("b3288675-a8c0-46db-9ed8-fea94b0b4585","TemplateColumn")
                :Column("TemplateColumn.Order","TemplateColumn_Order")
                :Where([TemplateColumn.fk_TemplateTable = ^],par_iTemplateTablePk)
                :OrderBy("TemplateColumn_Order","Desc")
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
                if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_LENGTH])
                    l_nLength := NIL
                endif
                if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_SCALE])
                    l_nScale := NIL
                endif
                // if !(oFcgi:p_ColumnTypes[l_iTypePos,COLUMN_TYPES_SHOW_UNICODE])    // Will not turn of the Unicode flag, in case column type is switched back to a char ...
                //     l_lUnicode := .f.
                // endif
            endif
        endif

        //Save the Column
        with object l_oDB1
            :Table("75d96e40-1f4f-44bf-9177-04d81d10e933","TemplateColumn")
            if oFcgi:p_nAccessLevelDD >= 5
                :Field("TemplateColumn.Name"         ,l_cName)
                :Field("TemplateColumn.AKA"          ,l_cAKA)
                :Field("TemplateColumn.UsedAs"       ,l_nUsedAs)
                :Field("TemplateColumn.UsedBy"       ,l_nUsedBy)
                :Field("TemplateColumn.UseStatus"    ,l_nUseStatus)
                :Field("TemplateColumn.Type"         ,l_cType)
                :Field("TemplateColumn.Array"        ,l_lArray)
                :Field("TemplateColumn.Length"       ,l_nLength)
                :Field("TemplateColumn.Scale"        ,l_nScale)
                :Field("TemplateColumn.Nullable"     ,l_lNullable)
                :Field("TemplateColumn.DefaultType"  ,l_nDefaultType)
                :Field("TemplateColumn.DefaultCustom",l_cDefaultCustom)
                :Field("TemplateColumn.Unicode"      ,l_lUnicode)
            endif
            :Field("TemplateColumn.DocStatus"  ,l_nDocStatus)
            :Field("TemplateColumn.Description",iif(empty(l_cDescription),NULL,l_cDescription))
        
            if empty(l_iPk)
                :Field("TemplateColumn.fk_TemplateTable",par_iTemplateTablePk)
                :Field("TemplateColumn.Order"           ,l_iColumnOrder)
                :Field("TemplateColumn.LinkUID"         ,oFcgi:p_o_SQLConnection:GetUUIDString())
                if :Add()
                    l_iPk := :Key()
                else
                    l_cErrorMessage := "Failed to add Column."
                endif
            else
                if !:Update(l_iPk)
                    l_cErrorMessage := "Failed to update Column."
                endif
            endif

        endwith

        DataDictionaryFixAndTest(par_iApplicationPk)

    endif

case l_cActionOnSubmit == "Cancel"
case l_cActionOnSubmit == "Done"
    l_iPk := 0

case l_cActionOnSubmit == "Delete"   // Column
    if oFcgi:p_nAccessLevelDD >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB1:Delete("a25f2685-e8d4-4f66-90b6-ee8684ca6a51","TemplateColumn",l_iPk)
        l_iPk := 0
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]          := l_cName
    l_hValues["AKA"]           := l_cAKA
    l_hValues["UsedAs"]        := l_nUsedAs
    l_hValues["UsedBy"]        := l_nUsedBy
    l_hValues["UseStatus"]     := l_nUseStatus
    l_hValues["DocStatus"]     := l_nDocStatus
    l_hValues["Description"]   := l_cDescription
    l_hValues["Type"]          := l_cType
    l_hValues["Array"]         := l_lArray
    l_hValues["Length"]        := l_nLength
    l_hValues["Scale"]         := l_nScale
    l_hValues["Nullable"]      := l_lNullable
    l_hValues["DefaultType"]   := l_nDefaultType
    l_hValues["DefaultCustom"] := l_cDefaultCustom
    l_hValues["Unicode"]       := l_lUnicode
    l_hValues["ShowPrimary"]   := l_lShowPrimary

    l_cHtml += TemplateColumnEditFormBuild(par_iApplicationPk,par_iTemplateTablePk,par_cURLApplicationLinkCode,par_oNavData,l_cErrorMessage,l_iPk,l_hValues)

case empty(l_iPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                             PrepareForURLSQLIdentifier("Table" ,par_oNavData:TemplateTable_Name ,par_oNavData:TemplateTable_LinkUID)+"/";
                                                                             )

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("4cee721e-6260-4b54-ba33-4e24098f8c40","TemplateColumn")
        :Column("TemplateTable.Name"     , "TemplateTable_Name")
        :Column("TemplateTable.LinkUID"  , "TemplateTable_LinkUID")
        :Column("TemplateColumn.Name"    , "TemplateColumn_Name")
        :Column("TemplateColumn.LinkUID" , "TemplateColumn_LinkUID")
        :Join("inner","TemplateTable","","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
        l_oData := :Get(l_iPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/EditTemplateColumn/"+par_cURLApplicationLinkCode+"/"+;
                                                                                    PrepareForURLSQLIdentifier("Table" ,l_oData:TemplateTable_Name ,l_oData:TemplateTable_LinkUID) +"/"+;
                                                                                    PrepareForURLSQLIdentifier("Column",l_oData:TemplateColumn_Name,l_oData:TemplateColumn_LinkUID)+"/";
                                                                                    )
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTemplateColumns/"+par_cURLApplicationLinkCode+"/"+;
                                                                                     PrepareForURLSQLIdentifier("Table" ,par_oNavData:TemplateTable_Name ,par_oNavData:TemplateTable_LinkUID)+"/";
                                                                                     )
        endif

    endwith

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableReferenceByFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cURLNamespaceName,par_cURLTableName)
local l_cHtml := []
local l_oData
local l_iTablePk
local l_cCombinedPath
local l_cSitePath := oFcgi:p_cSitePath
local l_oDB_ListOfReferenceTableAndColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cURL
local l_cName
local l_nNumberOfReference

oFcgi:TraceAdd("TableReferenceByFormBuild")

l_oData := GetTableInfoBasedOnURL(par_iApplicationPk,par_cURLNamespaceName,par_cURLTableName)
if hb_IsNil(l_oData)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")

else
    l_iTablePk := l_oData:Table_Pk
    if !empty(l_iTablePk)

        AssembleNavbarInfo("Add",{"Namespace",l_oData:Namespace_Name,l_oData:Namespace_AKA,l_oData:Namespace_LinkUID})
        AssembleNavbarInfo("Add",{"Table"    ,l_oData:Table_Name    ,l_oData:Table_AKA    ,l_oData:Table_LinkUID}    )

        l_cHtml += GetAboveNavbarHeading("Referenced By","Table",AssembleNavbarInfo("Build"))

        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                           PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+[/]+;
                           PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +[/]

        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,l_iTablePk,"TableReferencedBy")
                l_cHtml += GetTableExtendedButtonRelatedOnEditForm("ReferenceBy",l_iTablePk,l_cCombinedPath)
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]

        with object l_oDB_ListOfReferenceTableAndColumns
            :Table("0b7fc2ce-3c31-4294-a8af-1c8624e24e22","Column")
            :Column("Namespace.Name"           ,"Namespace_Name")
            :Column("Namespace.AKA"            ,"Namespace_AKA")
            :Column("Namespace.LinkUID"        ,"Namespace_LinkUID")
            :Column("Namespace.UseStatus"      ,"Namespace_UseStatus")
            :Column("Table.Name"               ,"Table_Name")
            :Column("Table.AKA"                ,"Table_AKA")
            :Column("Table.LinkUID"            ,"Table_LinkUID")
            :Column("Table.UseStatus"          ,"Table_UseStatus")
            :Column("Column.Name"              ,"Column_Name")
            :Column("Column.AKA"               ,"Column_AKA")
            :Column("Column.LinkUID"           ,"Column_LinkUID")
            :Column("Column.UseStatus"         ,"Column_UseStatus")
            :Column("Column.OnDelete"          ,"Column_OnDelete")
            :Column("Column.ForeignKeyUse"     ,"Column_ForeignKeyUse")
            :Column("Column.ForeignKeyOptional","Column_ForeignKeyOptional")
            :Column("Column.UsedBy"            ,"Column_UsedBy")

            :Where("Column.fk_TableForeign = ^",l_iTablePk)
            :Where("Column.UsedAs = 3")
            :join("inner","Table"    ,"","Column.fk_Table = Table.pk")
            :join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")

            :Column("lower(Namespace.Name)","tag1")
            :Column("lower(Table.Name)"    ,"tag2")
            :Column("lower(Column.Name)"   ,"tag3")
            :OrderBy("tag1")
            :OrderBy("tag2")
            :OrderBy("tag3")

            :SQL("ListOfReferenceTableAndColumns")

            l_nNumberOfReference := :Tally

            if l_nNumberOfReference <= 0
                l_cHtml += GetNoRecordsOnFile("No Referenced By on file.")

            else
                l_cHtml += [<div class="row justify-content-center m-3">]
                    l_cHtml += [<div class="col-auto">]

                        l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                            l_cHtml += [<tr class="bg-primary bg-gradient">]
                                l_cHtml += [<th class="text-center text-white" colspan="6">]
                                    l_cHtml += [Referenced By (]+Trans(l_nNumberOfReference)+[) for Table "]+;
                                            TextToHtml(l_oData:Namespace_Name+FormatAKAForDisplay(l_oData:Namespace_AKA)+[.]+alltrim(l_oData:Table_Name)+FormatAKAForDisplay(l_oData:Table_AKA))+;
                                            ["]
                                l_cHtml += [</th>]
                            l_cHtml += [</tr>]

                            l_cHtml += [<tr class="bg-primary bg-gradient">]
                                l_cHtml += [<th class="text-white">Namespace</th>]
                                l_cHtml += [<th class="text-white">Table</th>]
                                l_cHtml += [<th class="text-white">Column</th>]
                                l_cHtml += [<th class="text-white text-center">Foreign Key<br>Use</th>]
                                l_cHtml += [<th class="text-white text-center">Optional</th>]
                                l_cHtml += [<th class="text-white text-center">On Delete</th>]
                                
                            l_cHtml += [</tr>]

                            select ListOfReferenceTableAndColumns
                            scan all
                                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                                    //Namespace
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Namespace_UseStatus)+[>]
                                        l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Namespace_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Namespace_AKA))
                                    l_cHtml += [</td>]
                                    
                                    //Table
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Table_UseStatus)+[>]
                                        l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Table_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Table_AKA))
                                    l_cHtml += [</td>]
                                    
                                    //Column
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Column_UseStatus)+[>]
                                        // l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Column_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Column_AKA))

                                        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                                                           PrepareForURLSQLIdentifier("Namespace",ListOfReferenceTableAndColumns->Namespace_Name,ListOfReferenceTableAndColumns->Namespace_LinkUID)+[/]+;
                                                           PrepareForURLSQLIdentifier("Table"    ,ListOfReferenceTableAndColumns->Table_Name    ,ListOfReferenceTableAndColumns->Table_LinkUID)    +[/]

                                        l_cURL  := l_cSitePath+[DataDictionaries/EditColumn/]+l_cCombinedPath+;
                                                                                            PrepareForURLSQLIdentifier("Column",ListOfReferenceTableAndColumns->Column_Name,ListOfReferenceTableAndColumns->Column_LinkUID)+[/]
                                        l_cName := ListOfReferenceTableAndColumns->Column_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Column_AKA)
                                        if ListOfReferenceTableAndColumns->Column_UsedBy <> USEDBY_ALLSERVERS
                                            l_cURL  += [:]+trans(ListOfReferenceTableAndColumns->Column_UsedBy)
                                            l_cName += [ (]+GetItemInListAtPosition(ListOfReferenceTableAndColumns->Column_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
                                        endif
                                        l_cHtml += [<a target="_blank" href="]+l_cURL+[">]+TextToHtml(l_cName)+[</a>]


                                    l_cHtml += [</td>]

                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Foreign Key Use
                                        if !hb_IsNIL(ListOfReferenceTableAndColumns->Column_ForeignKeyUse)
                                            l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Column_ForeignKeyUse)
                                        endif
                                    l_cHtml += [</td>]

                                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]  //Optional
                                        if ListOfReferenceTableAndColumns->Column_ForeignKeyOptional
                                            l_cHtml += [<i class="bi bi-check-lg"></i>]
                                        endif
                                    l_cHtml += [</td>]

                                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]  //On Delete
                                        l_cHtml += {"","Protect","Cascade","Break Link"}[iif(el_between(ListOfReferenceTableAndColumns->Column_OnDelete,1,4),ListOfReferenceTableAndColumns->Column_OnDelete,1)]
                                    l_cHtml += [</td>]

                                l_cHtml += [</tr>]
                            endscan

                        l_cHtml += [</table>]
                        
                    l_cHtml += [</div>]
                l_cHtml += [</div>]
            endif

        endwith

    endif

endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function TableDiagramsFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cURLNamespaceName,par_cURLTableName)
local l_cHtml := []
local l_oData
local l_iTablePk
local l_cCombinedPath
local l_cSitePath := oFcgi:p_cSitePath
local l_oDB_ListOfDiagramsWithTables    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDiagramsWithAllTables := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDiagrams              := hb_SQLCompoundQuery(oFcgi:p_o_SQLConnection)
local l_cName
local l_cURL
local l_nNumberOfDiagrams

oFcgi:TraceAdd("TableDiagramsFormBuild")

l_oData := GetTableInfoBasedOnURL(par_iApplicationPk,par_cURLNamespaceName,par_cURLTableName)
if hb_IsNil(l_oData)
    // SendToClipboard(l_oDB1:LastSQL())
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListTables/"+par_cURLApplicationLinkCode+"/")

else
    l_iTablePk := l_oData:Table_Pk
    if !empty(l_iTablePk)

        AssembleNavbarInfo("Add",{"Namespace",l_oData:Namespace_Name,l_oData:Namespace_AKA,l_oData:Namespace_LinkUID})
        AssembleNavbarInfo("Add",{"Table"    ,l_oData:Table_Name    ,l_oData:Table_AKA    ,l_oData:Table_LinkUID}    )

        l_cHtml += GetAboveNavbarHeading("Referenced By","Table",AssembleNavbarInfo("Build"))

        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                           PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+[/]+;
                           PrepareForURLSQLIdentifier("Table"    ,l_oData:Table_Name    ,l_oData:Table_LinkUID)    +[/]

        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,l_iTablePk,"TableDiagrams")
                l_cHtml += GetTableExtendedButtonRelatedOnEditForm("Diagram",l_iTablePk,l_cCombinedPath)
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]

        with object l_oDB_ListOfDiagramsWithAllTables

            :Table("0d7201c8-3476-4007-bd17-5587efa3b144","Diagram")
            :Column("Diagram.Name"       ,"Diagram_Name")
            :Column("Diagram.LinkUID"    ,"Diagram_LinkUID")
            :Column("lower(Diagram.Name)","tag1")

            :Where("Diagram.fk_Application = ^",par_iApplicationPk)
            :Join("left","DiagramTable","","DiagramTable.fk_Diagram = Diagram.pk")
            :Where("DiagramTable.Pk IS NULL")
            
        endwith

        with object l_oDB_ListOfDiagramsWithTables
            :Table("18838cb1-061f-4fef-b01e-46f80878952e","DiagramTable")
            :Column("Diagram.Name"       ,"Diagram_Name")
            :Column("Diagram.LinkUID"    ,"Diagram_LinkUID")
            :Column("lower(Diagram.Name)","tag1")

            :Where("DiagramTable.fk_Table = ^",l_iTablePk)
            :join("inner","Diagram"    ,"","DiagramTable.fk_Diagram = Diagram.pk")
            :OrderBy("tag1","asc")   // Only the last Select should have an OrderBy
        endwith

        with object l_oDB_ListOfDiagrams
            :AnchorAlias("d486c27c-dcaa-4193-8ffd-fd5528b7a1df","ListOfDiagrams")
            :AddSQLDataQuery("ListOfDiagramsWithAllTables",l_oDB_ListOfDiagramsWithAllTables)
            :AddSQLDataQuery("ListOfDiagramsWithTables"   ,l_oDB_ListOfDiagramsWithTables)
            :CombineQueries(COMBINE_ACTION_UNION,"ListOfDiagrams",.t.,"ListOfDiagramsWithAllTables","ListOfDiagramsWithTables")
            :SQL("ListOfDiagrams")

            l_nNumberOfDiagrams := :Tally

            if l_nNumberOfDiagrams <= 0
                l_cHtml += GetNoRecordsOnFile("No Diagrams including Table.")

            else
                l_cHtml += [<div class="row justify-content-center m-3">]
                    l_cHtml += [<div class="col-auto">]

                        l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                            l_cHtml += [<tr class="bg-primary bg-gradient">]
                                l_cHtml += [<th class="text-center text-white" colspan="1">]
                                    l_cHtml += [Diagrams (]+Trans(l_nNumberOfDiagrams)+[) for Table "]+;
                                            TextToHtml(l_oData:Namespace_Name+FormatAKAForDisplay(l_oData:Namespace_AKA)+[.]+alltrim(l_oData:Table_Name)+FormatAKAForDisplay(l_oData:Table_AKA))+;
                                            ["]
                                l_cHtml += [</th>]
                            l_cHtml += [</tr>]

                            // l_cHtml += [<tr class="bg-primary bg-gradient">]
                            //     l_cHtml += [<th class="text-white text-center">Name</th>]
                            // l_cHtml += [</tr>]

                            select ListOfDiagrams
                            scan all
                                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]
                                    l_cName := ListOfDiagrams->Diagram_Name
                                    l_cURL  := l_cSitePath+[DataDictionaries/Visualize/]+par_cURLApplicationLinkCode+[/?InitialDiagram=]+ListOfDiagrams->Diagram_LinkUID

                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += [<a target="_blank" href="]+l_cURL+[">]+TextToHtml(l_cName)+[</a>]
                                    l_cHtml += [</td>]
                                    
                                l_cHtml += [</tr>]
                            endscan

                        l_cHtml += [</table>]
                        
                    l_cHtml += [</div>]
                l_cHtml += [</div>]
            endif

        endwith

    endif

endif

return l_cHtml
//=================================================================================================================





//=================================================================================================================
//=================================================================================================================
static function EnumerationReferenceByFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cURLNamespaceName,par_cURLEnumerationName)
local l_cHtml := []
local l_oData
local l_iEnumerationPk
local l_cCombinedPath
local l_cSitePath := oFcgi:p_cSitePath
local l_oDB_ListOfReferenceTableAndColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cURL
local l_cName
local l_nNumberOfReference

oFcgi:TraceAdd("EnumerationReferenceByFormBuild")

l_oData := GetEnumerationInfoBasedOnURL(par_iApplicationPk,par_cURLNamespaceName,par_cURLEnumerationName)
if hb_IsNil(l_oData)
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/ListEnumerations/"+par_cURLApplicationLinkCode+"/")

else
    l_iEnumerationPk := l_oData:Enumeration_Pk
    if !empty(l_iEnumerationPk)

        AssembleNavbarInfo("Add",{"Namespace",l_oData:Namespace_Name,l_oData:Namespace_AKA,l_oData:Namespace_LinkUID})
        AssembleNavbarInfo("Add",{"Enumeration"    ,l_oData:Enumeration_Name    ,l_oData:Enumeration_AKA    ,l_oData:Enumeration_LinkUID}    )

        l_cHtml += GetAboveNavbarHeading("Referenced By","Enumeration",AssembleNavbarInfo("Build"))

        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                           PrepareForURLSQLIdentifier("Namespace",l_oData:Namespace_Name,l_oData:Namespace_LinkUID)+[/]+;
                           PrepareForURLSQLIdentifier("Enumeration"    ,l_oData:Enumeration_Name    ,l_oData:Enumeration_LinkUID)    +[/]

        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += GetNextPreviousEnumeration(par_iApplicationPk,par_cURLApplicationLinkCode,l_iEnumerationPk,"EnumerationReferencedBy")
                l_cHtml += GetEnumerationExtendedButtonRelatedOnEditForm("ReferenceBy",l_iEnumerationPk,l_cCombinedPath)
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]

        with object l_oDB_ListOfReferenceTableAndColumns
            :Table("4630f00d-dc28-4960-bd0f-d93c3c247146","Column")
            :Column("Namespace.Name"           ,"Namespace_Name")
            :Column("Namespace.AKA"            ,"Namespace_AKA")
            :Column("Namespace.LinkUID"        ,"Namespace_LinkUID")
            :Column("Namespace.UseStatus"      ,"Namespace_UseStatus")
            :Column("Table.Name"               ,"Table_Name")
            :Column("Table.AKA"                ,"Table_AKA")
            :Column("Table.LinkUID"            ,"Table_LinkUID")
            :Column("Table.UseStatus"          ,"Table_UseStatus")
            :Column("Column.Name"              ,"Column_Name")
            :Column("Column.AKA"               ,"Column_AKA")
            :Column("Column.LinkUID"           ,"Column_LinkUID")
            :Column("Column.UseStatus"         ,"Column_UseStatus")
            :Column("Column.UsedBy"            ,"Column_UsedBy")

            :Where("Column.fk_Enumeration = ^",l_iEnumerationPk)
            :Where("trim(Column.Type) = 'E'")
            :join("inner","Table"    ,"","Column.fk_Table = Table.pk")
            :join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")

            :Column("lower(Namespace.Name)","tag1")
            :Column("lower(Table.Name)"    ,"tag2")
            :Column("lower(Column.Name)"   ,"tag3")
            :OrderBy("tag1")
            :OrderBy("tag2")
            :OrderBy("tag3")

            :SQL("ListOfReferenceTableAndColumns")

            l_nNumberOfReference := :Tally

            if l_nNumberOfReference <= 0
                l_cHtml += GetNoRecordsOnFile("No Referenced By on file.")

            else
                l_cHtml += [<div class="row justify-content-center m-3">]
                    l_cHtml += [<div class="col-auto">]

                        l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                            l_cHtml += [<tr class="bg-primary bg-gradient">]
                                l_cHtml += [<th class="text-center text-white" colspan="6">]
                                    l_cHtml += [Referenced By (]+Trans(l_nNumberOfReference)+[) for Enumeration "]+;
                                            TextToHtml(l_oData:Namespace_Name+FormatAKAForDisplay(l_oData:Namespace_AKA)+[.]+alltrim(l_oData:Enumeration_Name)+FormatAKAForDisplay(l_oData:Enumeration_AKA))+;
                                            ["]
                                l_cHtml += [</th>]
                            l_cHtml += [</tr>]

                            l_cHtml += [<tr class="bg-primary bg-gradient">]
                                l_cHtml += [<th class="text-white">Namespace</th>]
                                l_cHtml += [<th class="text-white">Table</th>]
                                l_cHtml += [<th class="text-white">Column</th>]
                            l_cHtml += [</tr>]

                            select ListOfReferenceTableAndColumns
                            scan all
                                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                                    //Namespace
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Namespace_UseStatus)+[>]
                                        l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Namespace_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Namespace_AKA))
                                    l_cHtml += [</td>]
                                    
                                    //Table
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Table_UseStatus)+[>]
                                        l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Table_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Table_AKA))
                                    l_cHtml += [</td>]
                                    
                                    //Column
                                    l_cHtml += [<td class="GridDataControlCells" valign="top"]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfReferenceTableAndColumns->Column_UseStatus)+[>]
                                        // l_cHtml += TextToHtml(ListOfReferenceTableAndColumns->Column_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Column_AKA))

                                        l_cCombinedPath := par_cURLApplicationLinkCode+[/]+;
                                                           PrepareForURLSQLIdentifier("Namespace",ListOfReferenceTableAndColumns->Namespace_Name,ListOfReferenceTableAndColumns->Namespace_LinkUID)+[/]+;
                                                           PrepareForURLSQLIdentifier("Table"    ,ListOfReferenceTableAndColumns->Table_Name    ,ListOfReferenceTableAndColumns->Table_LinkUID)    +[/]

                                        l_cURL  := l_cSitePath+[DataDictionaries/EditColumn/]+l_cCombinedPath+;
                                                                                            PrepareForURLSQLIdentifier("Column",ListOfReferenceTableAndColumns->Column_Name,ListOfReferenceTableAndColumns->Column_LinkUID)+[/]
                                        l_cName := ListOfReferenceTableAndColumns->Column_Name+FormatAKAForDisplay(ListOfReferenceTableAndColumns->Column_AKA)
                                        if ListOfReferenceTableAndColumns->Column_UsedBy <> USEDBY_ALLSERVERS
                                            l_cURL  += [:]+trans(ListOfReferenceTableAndColumns->Column_UsedBy)
                                            l_cName += [ (]+GetItemInListAtPosition(ListOfReferenceTableAndColumns->Column_UsedBy,{"","MySQL","PostgreSQL"},"")+[)]
                                        endif
                                        l_cHtml += [<a target="_blank" href="]+l_cURL+[">]+TextToHtml(l_cName)+[</a>]


                                    l_cHtml += [</td>]

                                l_cHtml += [</tr>]
                            endscan

                        l_cHtml += [</table>]
                        
                    l_cHtml += [</div>]
                l_cHtml += [</div>]
            endif

        endwith

    endif

endif

return l_cHtml
//=================================================================================================================
function TrackNameChange(par_oDB1,par_cTableName,par_iPk,par_cNewName,par_lTrackNameChanges)
local l_cErrorMessage := ""
local l_oData
local l_cSuffix
local l_aSQLResult := {}
local l_aRecord
// local l_cBogus1
// local l_cBogus2

if !empty(par_iPk)
    with object par_oDB1
        //Get the current Namespace
        :Table("91c2de20-83fa-4698-803a-23d0de8e5e96",par_cTableName)
        :Column(par_cTableName+".Name"   ,"Name")
        :Column(par_cTableName+".LinkUID","LinkUID")
        l_oData := :Get(par_iPk)
        if hb_IsNil(l_oData)
            l_cErrorMessage := "Failed to get current Name."
        else
            l_cSuffix := "_"+strtran(l_oData:LinkUID,"-","")

            //Will only try to record the Previous name, of TrackNameChanges is on and name is not from a Duplicate operation.
            if par_lTrackNameChanges .and.;
               !(lower(right(par_cNewName,len(l_cSuffix))) == lower(l_cSuffix)) .and.;
               !(lower(right(l_oData:Name,len(l_cSuffix))) == lower(l_cSuffix))
                
                if lower(l_oData:Name) <> lower(par_cNewName)  // Case Independent compare
                    //Check the Name is not already on file
                    :Table("f56f23f9-4dcc-41c1-9bb3-5c66f50db92e",par_cTableName+"PreviousName")
                    :Where(par_cTableName+"PreviousName.fk_"+par_cTableName+" = ^",par_iPk)
                    :Where("lower("+par_cTableName+"PreviousName.Name) = ^",lower(l_oData:Name))
                    if :Count() = 0
                        :Table("9375d5e9-e794-40be-81bc-705430c1c3a9",par_cTableName+"PreviousName")
                        :Field(par_cTableName+"PreviousName.fk_"+par_cTableName,par_iPk)
                        :Field(par_cTableName+"PreviousName.Name",l_oData:Name)
                        if !:Add()
                            l_cErrorMessage := "Failed to add previous Name."
                        endif
                    // else
                    //     SendToClipboard(:LastSQL())
                    endif
                endif

                //In case we reverted to a previous version, delete it from the Tracked Previous Name
                :Table("f56f23f9-4dcc-41c1-9bb3-5c66f50db92f",par_cTableName+"PreviousName")
                :Column(par_cTableName+"PreviousName.Pk","Pk")
                :Where(par_cTableName+"PreviousName.fk_"+par_cTableName+" = ^",par_iPk)
                :Where("lower("+par_cTableName+"PreviousName.Name) = ^",lower(par_cNewName))
                :SQL(@l_aSQLResult)
                if :Tally > 0
                    for each l_aRecord in l_aSQLResult
                        :Delete("330d56aa-a67a-4b0a-b684-09989fab12f9",par_cTableName+"PreviousName",l_aRecord[1])
                    endfor
                endif

            endif
        endif
    endwith
endif
return l_cErrorMessage
//=================================================================================================================
