#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
//=================================================================================================================
//Called via Ajax Call
function SaveSearchModeTable()

local l_iApplicationPk := val(oFcgi:GetQueryString("apppk"))
local l_cSearchMode := Strtran(oFcgi:GetQueryString("SearchMode"),[%22],["])

SaveUserSetting("Application_"+Trans(l_iApplicationPk)+"_TableSearch_Mode",l_cSearchMode)

return ""
//=================================================================================================================
//Called via Ajax Call
function SaveSearchModeEnumeration()

local l_iApplicationPk := val(oFcgi:GetQueryString("apppk"))
local l_cSearchMode := Strtran(oFcgi:GetQueryString("SearchMode"),[%22],["])

SaveUserSetting("Application_"+Trans(l_iApplicationPk)+"_EnumerationSearch_Mode",l_cSearchMode)

return ""
//=================================================================================================================
//=================================================================================================================
function TableGetNumberOfReferencedBy(par_iTablePk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("c79d2f1c-5492-4d0d-a1d0-ddb2131e879f","Column")
    :Column("Column.pk" ,"pk")
    :Where("Column.fk_TableForeign = ^",par_iTablePk)
    :Where("Column.UsedAs = 3")
    :join("inner","Table"    ,"","Column.fk_Table = Table.pk")
    :join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================
function TableGetNumberOfDiagrams(par_iTablePk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("2dc14187-6503-478d-a508-66dac4190dde","DiagramTable")
    :Column("DiagramTable.pk" ,"pk")
    :Where("DiagramTable.fk_Table = ^",par_iTablePk)
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================
function TableGetNumberOfColumns(par_iTablePk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("33d82918-bbaa-4443-88a3-6d916d3b2648","Column")
    :Column("Column.pk" ,"pk")
    :Where("Column.fk_Table = ^",par_iTablePk)
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================
function TableGetNumberOfIndexes(par_iTablePk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("33d82918-bbaa-4443-88a3-6d916d3b2649","Index")
    :Column("Index.pk" ,"pk")
    :Where("Index.fk_Table = ^",par_iTablePk)
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================
function EnumerationGetNumberOfValues(par_iEnumerationPk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("5287232c-1423-4bbe-86ca-85b2381196a3","EnumValue")
    :Column("EnumValue.pk" ,"pk")
    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================
function EnumerationGetNumberOfReferencedBy(par_iEnumerationPk)
local l_nCount
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("4ac569b3-de26-4141-b577-8b15deb59481","Column")
    :Column("Column.pk" ,"pk")
    :Where("Column.fk_Enumeration = ^",par_iEnumerationPk)
    :Where("trim(Column.Type) = 'E'")
    l_nCount := :Count()
endwith
return l_nCount
//=================================================================================================================

//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function GetNextPreviousButtonsFromListOfRecords(par_iPk,par_cURLPath,par_nNumberOfTemplateColumns,par_cItem,par_cItems,par_cListAction,par_cEditAction,par_bCode)
local l_cSitePath := oFcgi:p_cSitePath
local l_cHtml := ""
local l_cHtmlPrevious
local l_cHtmlNext
local l_FoundRecord

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Back To "+par_cItems,l_cSitePath+[DataDictionaries/]+par_cListAction+[/]+par_cURLPath+[/])

if par_nNumberOfTemplateColumns > 1
    l_FoundRecord    := .f.
    l_cHtmlPrevious := [<a class="btn btn-primary rounded ms-3 invisible RemoveOnEdit" href="#"><span class="bi-arrow-left"></span>&nbsp;]+par_cItem+[</a>]
    l_cHtmlNext     := [<a class="btn btn-primary rounded ms-3 invisible RemoveOnEdit" href="#"><span class="bi-arrow-right"></span>&nbsp;]+par_cItem+[</a>]
    select ListOfRecords
    scan all
        if l_FoundRecord
            l_cHtmlNext := [<a class="btn btn-primary rounded ms-3 RemoveOnEdit" href="]+l_cSitePath+[DataDictionaries/]+par_cEditAction+[/]+;
                                                                                         par_cURLPath+[/]+;
                                                                                         eval(par_bCode)+;
                                                                                         ["><span class="bi-arrow-right"></span>&nbsp;]+par_cItem+[</a>]
            exit
        else
            if ListOfRecords->pk == par_iPk
                l_FoundRecord := .t.
            else
                l_cHtmlPrevious := [<a class="btn btn-primary rounded ms-3 RemoveOnEdit" href="]+l_cSitePath+[DataDictionaries/]+par_cEditAction+[/]+;
                                                                                                 par_cURLPath+[/]+;
                                                                                                 eval(par_bCode)+;
                                                                                                 ["><span class="bi-arrow-left"></span>&nbsp;]+par_cItem+[</a>]
            endif
        endif
    endscan

    if l_FoundRecord
        l_cHtml += l_cHtmlPrevious+l_cHtmlNext
    endif
endif

return l_cHtml
//=================================================================================================================
function GetNextPreviousTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTablePk,par_cURLAction)
local l_cHtml := ""
local l_oDB_ListOfTables       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_AnyTags            := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_cSitePath := oFcgi:p_cSitePath

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
local l_cSearchColumnTypes
local l_cSearchExtraFilters

// local l_nNumberOfTables := 0
local l_nNumberOfUsedTags

local l_bCode := {||
return PrepareForURLSQLIdentifier("Namespace",ListOfRecords->Namespace_Name,ListOfRecords->Namespace_LinkUID)+[/]+;
       PrepareForURLSQLIdentifier("Table"    ,ListOfRecords->Table_Name    ,ListOfRecords->Table_LinkUID)    +[/]
}

oFcgi:TraceAdd("GetNextPreviousTable")

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
l_cSearchColumnTypes            := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ColumnTypes")
l_cSearchExtraFilters           := GetUserSetting("Application_"+Trans(par_iApplicationPk)+"_TableSearch_ExtraFilters")

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
    :Column("Namespace.Name"   ,"Namespace_Name")
    :Column("Namespace.LinkUID","Namespace_LinkUID")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.LinkUID"    ,"Table_LinkUID")
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
                              l_cSearchColumnTypes,;
                              l_cSearchExtraFilters;
                              )

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfRecords")

    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iTablePk,par_cURLApplicationLinkCode,:Tally,"Table","Tables","ListTables",par_cURLAction,l_bCode)
    // SendToClipboard(:LastSQL())

endwith

return l_cHtml
//=================================================================================================================
function GetNextPreviousColumn(par_iTablePk,par_cURLPath,par_iColumnPk)
local l_cHtml := ""
local l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_bCode := {||
return PrepareForURLSQLIdentifier("Column",ListOfRecords->Column_Name,ListOfRecords->Column_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousColumn")

with object l_oDB_ListOfColumns
    :Table("82c9374b-830e-47b7-8203-244e422ad7ba","Column")
    :Column("Column.pk"     ,"pk")
    :Column("Column.Name"   ,"Column_Name")
    :Column("Column.LinkUID","Column_LinkUID")
    :Column("Column.Order","tag1")
    :Where("Column.fk_Table = ^",par_iTablePk)

    :OrderBy("tag1")
    :SQL("ListOfRecords")

    // l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iColumnPk,par_cURLPath,:Tally,"Column","Columns","ListColumns","EditColumn",l_bCode)
    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iColumnPk,par_cURLPath,:Tally,"Column","Columns","ListColumns","EditColumn",l_bCode)
endwith

return l_cHtml
//=================================================================================================================
function GetNextPreviousTemplateColumn(par_iTemplateTablePk,par_cURLPath,par_iTemplateColumnPk)
local l_cHtml := ""
local l_oDB_ListOfTemplateColumns := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_bCode := {||
return PrepareForURLSQLIdentifier("Column",ListOfRecords->Column_Name,ListOfRecords->Column_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousTemplateColumn")

with object l_oDB_ListOfTemplateColumns
    :Table("4bd5c39d-dba3-4f63-a5f4-5ea56fae3a46","TemplateColumn")
    :Column("TemplateColumn.pk"     ,"pk")
    :Column("TemplateColumn.Name"   ,"Column_Name")
    :Column("TemplateColumn.LinkUID","Column_LinkUID")
    :Column("TemplateColumn.Order","tag1")
    :Where("TemplateColumn.fk_TemplateTable = ^",par_iTemplateTablePk)

    :OrderBy("tag1")
    :SQL("ListOfRecords")

    // l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iTemplateColumnPk,par_cURLPath,:Tally,"Template Column","Template Columns","ListTemplateColumns","EditTemplateColumn",l_bCode)
    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iTemplateColumnPk,par_cURLPath,:Tally,"Column","Columns","ListTemplateColumns","EditTemplateColumn",l_bCode)
endwith

return l_cHtml
//=================================================================================================================
function GetNextPreviousEnumValue(par_iEnumerationPk,par_cURLPath,par_iEnumValuePk)
local l_cHtml := ""
local l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_bCode := {||
return PrepareForURLSQLIdentifier("EnumValue",ListOfRecords->EnumValue_Name,ListOfRecords->EnumValue_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousColumn")

with object l_oDB_ListOfColumns
    :Table("a27cc2ee-8d6f-4db0-9653-77ded3821548","EnumValue")
    :Column("EnumValue.pk"     ,"pk")
    :Column("EnumValue.Name"   ,"EnumValue_Name")
    :Column("EnumValue.LinkUID","EnumValue_LinkUID")
    :Column("EnumValue.Order","tag1")
    :Where("EnumValue.fk_Enumeration = ^",par_iEnumerationPk)

    :OrderBy("tag1")
    :SQL("ListOfRecords")

    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iEnumValuePk,par_cURLPath,:Tally,"Value","Values","ListEnumValues","EditEnumValue",l_bCode)
endwith

return l_cHtml
//=================================================================================================================
function GetNextPreviousIndex(par_iTablePk,par_cURLPath,par_iIndexPk)
local l_cHtml := ""
local l_oDB_ListOfIndexes := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_bCode := {||
return PrepareForURLSQLIdentifier("Index",ListOfRecords->Index_Name,ListOfRecords->Index_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousIndex")

with object l_oDB_ListOfIndexes
    :Table("82c9374b-830e-47b7-8203-244e422ad7ba","Index")
    :Column("Index.pk"     ,"pk")
    :Column("Index.Name"   ,"Index_Name")
    :Column("Index.LinkUID","Index_LinkUID")
    :Column("lower(Index.Name)","tag1")
    :Where("Index.fk_Table = ^",par_iTablePk)

    :OrderBy("tag1")
    :SQL("ListOfRecords")

    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iIndexPk,par_cURLPath,:Tally,"Index","Indexes","ListIndexes","EditIndex",l_bCode)
endwith

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function GetNextPreviousEnumeration(par_iApplicationPk,par_cURLApplicationLinkCode,par_iEnumerationPk,par_cURLAction)
local l_cHtml := ""
local l_oDB_ListOfEnumerations := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_nSearchMode
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

local l_bCode := {||
return PrepareForURLSQLIdentifier("Namespace"  ,ListOfRecords->Namespace_Name  ,ListOfRecords->Namespace_LinkUID)  +[/]+;
       PrepareForURLSQLIdentifier("Enumeration",ListOfRecords->Enumeration_Name,ListOfRecords->Enumeration_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousEnumeration")

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



with object l_oDB_ListOfEnumerations
    :Table("7e3eeb26-19bc-4ca1-8187-3b3298632cc1","Enumeration")
    :Column("Enumeration.pk"     ,"pk")
    :Column("Namespace.Name"     ,"Namespace_Name")
    :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
    :Column("Enumeration.Name"   ,"Enumeration_Name")
    :Column("Enumeration.LinkUID","Enumeration_LinkUID")
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
                                    l_cSearchEnumerationImplementAs;
                                    )

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfRecords")

    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iEnumerationPk,par_cURLApplicationLinkCode,:Tally,"Enumeration","Enumerations","ListEnumerations",par_cURLAction,l_bCode)
    // SendToClipboard(:LastSQL())

endwith

return l_cHtml
//=================================================================================================================
function GetNextPreviousTemplateTable(par_iApplicationPk,par_cURLApplicationLinkCode,par_iTemplateTablePk,par_cURLAction)
local l_cHtml := ""
local l_oDB_ListOfTemplateTable := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_bCode := {||
return PrepareForURLSQLIdentifier("Table",ListOfRecords->TemplateTable_Name,ListOfRecords->TemplateTable_LinkUID)+[/]
}

oFcgi:TraceAdd("GetNextPreviousTemplateTable")

with object l_oDB_ListOfTemplateTable
    :Table("9a09b083-5ee8-46ca-b65a-18497c6c36fc","TemplateTable")
    :Column("TemplateTable.pk"     ,"pk")
    :Column("TemplateTable.Name"   ,"TemplateTable_Name")
    :Column("TemplateTable.LinkUID","TemplateTable_LinkUID")
    :Column("Upper(TemplateTable.Name)","tag1")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)

    :OrderBy("tag1")
    :SQL("ListOfRecords")

    l_cHtml := GetNextPreviousButtonsFromListOfRecords(par_iTemplateTablePk,par_cURLApplicationLinkCode,:Tally,"Template Table","Template Tables","ListTemplateTables",par_cURLAction,l_bCode)
    // SendToClipboard(:LastSQL())

endwith

return l_cHtml
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
                                            :Table("6675a32d-34f0-4f4c-a913-19fbd2b980b2","Column")
                                            :Column("TagColumn.pk","pk")
                                            :Join("inner","TagColumn","","TagColumn.fk_Column = Column.pk")
                                            :Where("Column.fk_Table = ^" , par_iTablePk)
                                            :SQL("ListOfRecordsToDeleteInCascadeDeleteTable")
                                            if :Tally < 0
                                                l_cErrorMessage := "Failed to delete Table. Error 11."
                                            else
                                                select ListOfRecordsToDeleteInCascadeDeleteTable
                                                scan all
                                                    if !:Delete("ed839e1d-2ece-4525-b154-be06afbbc88d","TagColumn",ListOfRecordsToDeleteInCascadeDeleteTable->pk)
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
                                                        l_cErrorMessage := "Failed to delete Table. Error 12."
                                                    else
                                                        select ListOfRecordsToDeleteInCascadeDeleteTable
                                                        scan all
                                                            :Table("978e4c66-259d-4a47-be46-89d7420728e8","Column")
                                                            :Field("Column.fk_TableForeign" , 0)
                                                            :Update(ListOfRecordsToDeleteInCascadeDeleteTable->pk)
                                                        endscan
                                                        
                                                        CustomFieldsDelete(par_iApplicationPk,USEDON_TABLE,par_iTablePk)
                                                        if !:Delete("b7c803fe-9a16-47f6-9f64-981bce0ee66d","Table",par_iTablePk)
                                                            l_cErrorMessage := "Failed to delete Table. Error 13."
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
        endif
    endif
endwith
return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteNamespace(par_iApplicationPk,par_iNamespacePk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)  // Since executing a select at this level, may not pass l_oDB1 for reuse.
local l_cErrorMessage := ""

with object l_oDB1

    :Table("40f4bf76-ffc0-45cd-ba04-f84dad486ea3","Table")
    :Column("Table.pk","pk")
    :Where("Table.fk_Namespace = ^" , par_iNamespacePk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteNamespace")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete Namespace. Error 1."
    else
        select ListOfRecordsToDeleteInCascadeDeleteNamespace
        scan all
            l_cErrorMessage := CascadeDeleteTable(par_iApplicationPk,ListOfRecordsToDeleteInCascadeDeleteNamespace->pk)
            if !empty(l_cErrorMessage)
                exit
            endif
        endscan
    endif
    
    if empty(l_cErrorMessage)
        :Table("6f7e5169-b207-4cf9-be62-d61400b38de4","Enumeration")
        :Column("EnumValue.pk","pk")
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
        :Where("Enumeration.fk_Namespace = ^" , par_iNamespacePk)
        :SQL("ListOfRecordsToDeleteInCascadeDeleteNamespace")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete Namespace. Error 2."
        else
            select ListOfRecordsToDeleteInCascadeDeleteNamespace
            scan all
                if !:Delete("6ebff3a3-99db-40ef-ade6-a6e9c2642423","EnumValue",ListOfRecordsToDeleteInCascadeDeleteNamespace->pk)
                    l_cErrorMessage := "Failed to delete Namespace. Error 3."
                    exit
                endif
            endscan

            if empty(l_cErrorMessage)
                :Table("980a812a-b5c6-4296-96f5-ec8e5ed66947","Enumeration")
                :Column("Enumeration.pk","pk")
                :Where("Enumeration.fk_Namespace = ^" , par_iNamespacePk)
                :SQL("ListOfRecordsToDeleteInCascadeDeleteNamespace")
                if :Tally < 0
                    l_cErrorMessage := "Failed to delete Namespace. Error 4."
                else
                    select ListOfRecordsToDeleteInCascadeDeleteNamespace
                    scan all
                        if !:Delete("4c254a46-f12a-4a03-94d1-5850fa61af22","Enumeration",ListOfRecordsToDeleteInCascadeDeleteNamespace->pk)
                            l_cErrorMessage := "Failed to delete Namespace. Error 5."
                            exit
                        endif
                    endscan

                    if empty(l_cErrorMessage)
                        CustomFieldsDelete(par_iApplicationPk,USEDON_NAMESPACE,par_iNamespacePk)
                        if !:Delete("1e8e8f31-df5d-47bf-9b1b-de3f87a6792a","Namespace",par_iNamespacePk)
                            l_cErrorMessage := "Failed to delete Namespace. Error 6."
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
        if !:Delete("4fbd589c-5121-4041-bf7c-5aad0712ad56","Tag",par_iTagPk)
            l_cErrorMessage := "Failed to delete Tag. Error 5."
        endif
    endif
endwith

return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteTemplateTable(par_iApplicationPk,par_iTemplateTablePk)
local l_cErrorMessage := ""
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("aef55557-d8c9-4224-9366-90e1a981fd3b","TemplateColumn")
    :Column("TemplateColumn.pk","pk")
    :Where("TemplateColumn.fk_TemplateTable = ^" , par_iTemplateTablePk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteTemplateTable")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete Template Table. Error 5."
    else
        select ListOfRecordsToDeleteInCascadeDeleteTemplateTable
        scan all
            if !:Delete("6158924c-7ca6-4a0a-8804-f885c84d3165","TemplateColumn",ListOfRecordsToDeleteInCascadeDeleteTemplateTable->pk)
                l_cErrorMessage := "Failed to delete Template Table. Error 6."
                exit
            endif
        endscan

        if empty(l_cErrorMessage)
            if !:Delete("4969e8ea-8721-4c88-8d6a-95d798851a94","TemplateTable",par_iTemplateTablePk)
                l_cErrorMessage := "Failed to delete Template Table. Error 13."
            endif
        endif
    endif
endwith
return l_cErrorMessage
//=================================================================================================================
function GetColumnDefault(par_lForExport,par_cColumnType,par_nColumnDefaultType,par_cColumnDefaultCustom)
local l_cResult
local l_cColumnType := alltrim(par_cColumnType)

do case
case par_nColumnDefaultType == 0  // No Default
    l_cResult := ""
case par_nColumnDefaultType == 1  // Custom
    l_cResult := nvl(par_cColumnDefaultCustom,"")
case l_cColumnType == "D"
    do case
    case par_nColumnDefaultType == 10
        l_cResult := iif(par_lForExport,"Wharf-","")+"Today()"
    otherwise
        l_cResult := ""
    endcase
case el_IsInlist(l_cColumnType,"TOZ","TO","DTZ","DT")
    do case
    case par_nColumnDefaultType == 11
        l_cResult := iif(par_lForExport,"Wharf-","")+"Now()"
    otherwise
        l_cResult := ""
    endcase
case el_IsInlist(l_cColumnType,"I","IB","IS","N")
    do case
    case par_nColumnDefaultType == 15
        l_cResult := iif(par_lForExport,"Wharf-","")+"AutoIncrement()"
    otherwise
        l_cResult := ""
    endcase
case l_cColumnType == "UUI"
    do case
    case par_nColumnDefaultType == 12
        l_cResult := iif(par_lForExport,"Wharf-","")+"uuid()"
    otherwise
        l_cResult := ""
    endcase
case l_cColumnType == "L"
    do case
    case par_nColumnDefaultType == 13
        l_cResult := iif(par_lForExport,"Wharf-","")+"False"
    case par_nColumnDefaultType == 14
        l_cResult := iif(par_lForExport,"Wharf-","")+"True"
    otherwise
        l_cResult := ""
    endcase
otherwise
    l_cResult := ""
endcase

return l_cResult
//=================================================================================================================
function GetNoRecordsOnFile(par_cMessage)
local l_cHtml
l_cHtml := [<div class="row justify-content-center mt-5"><div class="col-auto">]
    l_cHtml += [<h5>]+par_cMessage+[</h5>]
l_cHtml += [</div></div>]
return l_cHtml
//=================================================================================================================
function GetAboveNavbarHeading(par_cSource,par_cType,par_cInfo)
local l_cHtml
local l_cTableInfo

if hb_IsNil(par_cType)
    l_cHtml := [<div><span class="navbar-brand ms-3 text-primary">]+par_cSource+[</span></div>]
else
    l_cHtml := [<div><span class="navbar-brand ms-3"><span class="text-primary me-5">]+par_cSource+"</span> "+par_cType+": "+par_cInfo+[</span></div>]
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function TableListFormAddFiltering(par_oDB,;
                                          par_nSearchMode,;
                                          par_cSearchNamespaceName,;
                                          par_cSearchNamespaceDescription,;
                                          par_cSearchTableName,;
                                          par_cSearchTableDescription,;
                                          par_cSearchColumnName,;
                                          par_cSearchColumnDescription,;
                                          par_cSearchEnumerationName,;
                                          par_cSearchEnumerationDescription,;
                                          par_cSearchTableTags,;
                                          par_cSearchTableUsageStatus,;
                                          par_cSearchTableDocStatus,;
                                          par_cSearchColumnUsageStatus,;
                                          par_cSearchColumnDocStatus,;
                                          par_cSearchColumnTypes,;
                                          par_cSearchExtraFilters;
                                        )
local l_lJoinColumns     := .f.
local l_lJoinEnumeration := .f.
local l_aColumnTypeCode
local l_cSQLList

//   SendToDebugView(par_cSearchColumnDocStatus)   /// Example:  N,TO

with object par_oDB
    if par_nSearchMode > 1
        if !empty(par_cSearchNamespaceName)
            :KeywordCondition(par_cSearchNamespaceName,"CONCAT(Namespace.Name,' ',Namespace.AKA)")
        endif
        if !empty(par_cSearchNamespaceDescription)
            :KeywordCondition(par_cSearchNamespaceDescription,"Namespace.Description")
        endif
    endif

    if !empty(par_cSearchTableName)
        :KeywordCondition(par_cSearchTableName,"CONCAT(Table.Name,' ',Table.AKA)")
    endif
    if !empty(par_cSearchTableDescription)
        :KeywordCondition(par_cSearchTableDescription,"Table.Description")
    endif

    if par_nSearchMode > 1
        if !empty(par_cSearchColumnName) .or. !empty(par_cSearchColumnDescription)
            l_lJoinColumns := .t.
            if !empty(par_cSearchColumnName)
                :KeywordCondition(par_cSearchColumnName,"CONCAT(Column.Name,' ',Column.AKA)")
            endif
            if !empty(par_cSearchColumnDescription)
                :KeywordCondition(par_cSearchColumnDescription,"Column.Description")
            endif
        endif

        if !empty(par_cSearchEnumerationName) .or. !empty(par_cSearchEnumerationDescription)
            l_lJoinEnumeration := .t.
            if !empty(par_cSearchEnumerationName)
                :KeywordCondition(par_cSearchEnumerationName,"CONCAT(Enumeration.Name,' ',Enumeration.AKA)")
            endif
            if !empty(par_cSearchEnumerationDescription)
                :KeywordCondition(par_cSearchEnumerationDescription,"Enumeration.Description")
            endif
        endif
    endif

    if par_nSearchMode > 2
        if !empty(par_cSearchTableTags)
            :Distinct(.t.)
            :Join("inner","TagTable","","TagTable.fk_Table = Table.pk")
            :Where("TagTable.fk_Tag in ("+par_cSearchTableTags+")")
        endif

        if !empty(par_cSearchTableUsageStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchTableUsageStatus,",123456789")
            if !empty(l_cSQLList)
                :Where("Table.UseStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchTableDocStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchTableDocStatus,",123456789")
            if !empty(l_cSQLList)
                :Where("Table.DocStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchColumnUsageStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchColumnUsageStatus,",123456789")
            if !empty(l_cSQLList)
                l_lJoinColumns := .t.
                :Where("Column.UseStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchColumnDocStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchColumnDocStatus,",123456789")
            if !empty(l_cSQLList)
                l_lJoinColumns := .t.
                :Where("Column.DocStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchColumnTypes)
            l_cSQLList := []
            for each l_aColumnTypeCode in hb_ATokens(  el_StringFilterCharacters(par_cSearchColumnTypes,",ABCDEFGHIJKLMNOPQRSTUVWXYZ")  ,",",.f.)
                if !empty(l_cSQLList)
                    l_cSQLList += [,]
                endif
                l_cSQLList += [']+l_aColumnTypeCode+[']
            endfor
            if !empty(l_cSQLList)
                l_lJoinColumns := .t.
                :Where("Column.Type in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchExtraFilters)
            // l_json_ExtraFilters :=  [{tag:'Warning',value:'WNG'}]
            // l_json_ExtraFilters += [,{tag:'Unlogged Table',value:'ULT'}]
            // l_json_ExtraFilters += [,{tag:'Non Unlogged Table',value:'LGT'}]
            // l_json_ExtraFilters += [,{tag:'Array Type Column',value:'ART'}]
            if 'WNG' $ par_cSearchExtraFilters
                :Where("Table.TestWarning IS NOT NULL")
            endif
            if 'ULT' $ par_cSearchExtraFilters
                :Where("Table.Unlogged")
            endif
            if 'LGT' $ par_cSearchExtraFilters
                :Where("NOT Table.Unlogged")
            endif
            if 'ART' $ par_cSearchExtraFilters
                l_lJoinColumns := .t.
                :Where("Column.Array")
            endif
        endif
    endif

    if l_lJoinEnumeration .or. l_lJoinColumns
        :Distinct(.t.)
        :Join("inner","Column","","Column.fk_Table = Table.pk")
    endif
    if l_lJoinEnumeration
        :Distinct(.t.)
        :Join("inner","Enumeration","","Column.fk_Enumeration = Enumeration.pk")
    endif

endwith

return nil
//=================================================================================================================
function EnumerationListFormAddFiltering(par_oDB,;
                                                par_nSearchMode,;
                                                par_cSearchNamespaceName,;
                                                par_cSearchNamespaceDescription,;
                                                par_cSearchEnumerationName,;
                                                par_cSearchEnumerationDescription,;
                                                par_cSearchValueName,;
                                                par_cSearchValueDescription,;
                                                par_cSearchEnumerationUsageStatus,;
                                                par_cSearchEnumerationDocStatus,;
                                                par_cSearchEnumValueUsageStatus,;
                                                par_cSearchEnumValueDocStatus,;
                                                par_cSearchEnumerationImplementAs;
                                                )
local l_lJoinEnumValues := .f.
local l_cSQLList

with object par_oDB

    if par_nSearchMode > 1
        if !empty(par_cSearchNamespaceName)
            :KeywordCondition(par_cSearchNamespaceName,"CONCAT(Namespace.Name,' ',Namespace.AKA)")
        endif
        if !empty(par_cSearchNamespaceDescription)
            :KeywordCondition(par_cSearchNamespaceDescription,"Namespace.Description")
        endif
    endif

    if !empty(par_cSearchEnumerationName)
        :KeywordCondition(par_cSearchEnumerationName,"CONCAT(Enumeration.Name,' ',Enumeration.AKA)")
    endif
    if !empty(par_cSearchEnumerationDescription)
        :KeywordCondition(par_cSearchEnumerationDescription,"Enumeration.Description")
    endif

    if par_nSearchMode > 1
        if !empty(par_cSearchValueName) .or. !empty(par_cSearchValueDescription)
            l_lJoinEnumValues := .t.
            if !empty(par_cSearchValueName)
                :KeywordCondition(par_cSearchValueName,"CONCAT(EnumValue.Name,' ',EnumValue.AKA)")
            endif
            if !empty(par_cSearchValueDescription)
                :KeywordCondition(par_cSearchValueDescription,"EnumValue.Description")
            endif
        endif
    endif

    if par_nSearchMode > 2
        if !empty(par_cSearchEnumerationUsageStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchEnumerationUsageStatus,",123456789")
            if !empty(l_cSQLList)
                :Where("Enumeration.UseStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchEnumerationDocStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchEnumerationDocStatus,",123456789")
            if !empty(l_cSQLList)
                :Where("Enumeration.DocStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchEnumValueUsageStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchEnumValueUsageStatus,",123456789")
            if !empty(l_cSQLList)
                l_lJoinEnumValues := .t.
                :Where("EnumValue.UseStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchEnumValueDocStatus)
            l_cSQLList := el_StringFilterCharacters(par_cSearchEnumValueDocStatus,",123456789")
            if !empty(l_cSQLList)
                l_lJoinEnumValues := .t.
                :Where("EnumValue.DocStatus in ("+l_cSQLList+")")
            endif
        endif

        if !empty(par_cSearchEnumerationImplementAs)
            l_cSQLList := el_StringFilterCharacters(par_cSearchEnumerationImplementAs,",123456789")
            if !empty(l_cSQLList)
                l_lJoinEnumValues := .t.
                :Where("Enumeration.ImplementAs in ("+l_cSQLList+")")
            endif
        endif

    endif

    if l_lJoinEnumValues
        :Distinct(.t.)
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
    endif
endwith

return nil
//=================================================================================================================
function GetTableExtendedButtonRelatedOnEditForm(par_cCurrentButton,par_iPk,par_cCombinedPath)
local l_cSitePath := oFcgi:p_cSitePath
local l_cHtml := []

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Edit Table" ,l_cSitePath+[DataDictionaries/EditTable/]+par_cCombinedPath,(par_cCurrentButton == "Edit"))

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Columns ("+Trans(TableGetNumberOfColumns(par_iPk))+")"           ,l_cSitePath+[DataDictionaries/ListColumns/]+par_cCombinedPath,(par_cCurrentButton == "Column"))

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Indexes ("+Trans(TableGetNumberOfIndexes(par_iPk))+")"           ,l_cSitePath+[DataDictionaries/ListIndexes/]+par_cCombinedPath,(par_cCurrentButton == "Index"))

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Referenced By ("+Trans(TableGetNumberOfReferencedBy(par_iPk))+")",l_cSitePath+[DataDictionaries/TableReferencedBy/]+par_cCombinedPath,(par_cCurrentButton == "ReferenceBy"))

l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Diagrams ("+Trans(TableGetNumberOfDiagrams(par_iPk))+")",l_cSitePath+[DataDictionaries/TableDiagrams/]+par_cCombinedPath,(par_cCurrentButton == "Diagram"))

if oFcgi:p_nAccessLevelDD >= 5
    // l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Export for DataWharf Imports",l_cSitePath+[DataDictionaries/TableExportForDataWharfImports/]+par_cCombinedPath)
    l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Export",l_cSitePath+[DataDictionaries/TableExportForDataWharfImports/]+par_cCombinedPath,(par_cCurrentButton == "Export"))
endif

return l_cHtml
//=================================================================================================================
function GetTableInfoBasedOnURL(par_iApplicationPk,par_cURLNamespaceName,par_cURLTableName)
local l_oData
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("07af5b82-c5c1-4aa1-b9d3-13d32b8a89d5","Table")
    :Column("Namespace.Pk"     ,"Namespace_Pk")
    :Column("Namespace.Name"   ,"Namespace_Name")
    :Column("Namespace.AKA"    ,"Namespace_AKA")
    :Column("Namespace.LinkUID","Namespace_LinkUID")
    :Column("Table.pk"         ,"Table_Pk")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.AKA"        ,"Table_AKA")
    :Column("Table.LinkUID"    ,"Table_LinkUID")
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Where([Namespace.fk_Application = ^],par_iApplicationPk)

    if left(par_cURLNamespaceName,1) == "~"
        :Where([Namespace.LinkUID = ^],substr(par_cURLNamespaceName,2))
    else
        :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(par_cURLNamespaceName," ","")))
    endif
    if left(par_cURLTableName,1) == "~"
        :Where([Table.LinkUID = ^],substr(par_cURLTableName,2))
    else
        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(par_cURLTableName," ","")))
    endif

    :Limit(1)  // In case we have duplicate pick one of them
    l_oData := :SQL()

    if l_oDB1:Tally != 1
        l_oData := nil
    endif
endwith

return l_oData

//=================================================================================================================
function GetEnumerationInfoBasedOnURL(par_iApplicationPk,par_cURLNamespaceName,par_cURLEnumerationName)
local l_oData
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("8122e1ae-644c-4b30-bfa6-779400a520e0","Enumeration")
    :Column("Namespace.Name"     ,"Namespace_Name")
    :Column("Namespace.AKA"      ,"Namespace_AKA")
    :Column("Namespace.LinkUID"  ,"Namespace_LinkUID")
    :Column("Enumeration.pk"     ,"Enumeration_Pk")
    :Column("Enumeration.Name"   ,"Enumeration_Name")
    :Column("Enumeration.AKA"    ,"Enumeration_AKA")
    :Column("Enumeration.LinkUID","Enumeration_LinkUID")
    :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)

    if left(par_cURLNamespaceName,1) == "~"
        :Where([Namespace.LinkUID = ^],substr(par_cURLNamespaceName,2))
    else
        :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(par_cURLNamespaceName," ","")))
    endif
    if left(par_cURLEnumerationName,1) == "~"
        :Where([Enumeration.LinkUID = ^],substr(par_cURLEnumerationName,2))
    else
        :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(par_cURLEnumerationName," ","")))
    endif
    
    :Limit(1)  // In case we have duplicate pick one of them
    l_oData := :SQL()
    if l_oDB1:Tally != 1
        l_oData := nil
    endif

endwith

return l_oData
//=================================================================================================================




//=================================================================================================================
function GetEnumerationExtendedButtonRelatedOnEditForm(par_cCurrentButton,par_iPk,par_cCombinedPath)
local l_cSitePath := oFcgi:p_cSitePath
local l_cHtml := []

l_cHtml += GetButtonOnListFormCaptionAndRedirect("Edit Enumeration",l_cSitePath+[DataDictionaries/EditEnumeration/]+par_cCombinedPath,(par_cCurrentButton == "Edit"))
l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Values ("+Trans(EnumerationGetNumberOfValues(par_iPk))+")",l_cSitePath+[DataDictionaries/ListEnumValues/]+par_cCombinedPath,(par_cCurrentButton == "Value"))
l_cHtml += GetButtonOnEditFormCaptionAndRedirect("Referenced By ("+Trans(EnumerationGetNumberOfReferencedBy(par_iPk))+")",l_cSitePath+[DataDictionaries/EnumerationReferencedBy/]+par_cCombinedPath,(par_cCurrentButton == "ReferenceBy"))

return l_cHtml
//=================================================================================================================
