#include "DataWharf.ch"
//=================================================================================================================
function DataDictionaryFixAndTest(par_iApplicationPk)

local l_oDB_Application                   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTables                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumns                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTemplateColumns         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_Record                        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesWithWarning       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnsWithWarning      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumerationsWithWarning := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfIndexesWithWarning      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesWithPrimaryKey
local l_oDB_ListOfForeignKeysNotNullableOrWithDefault
local l_oDB_ListOfForeignKeys
local l_oDB_ListOfPrimaryKeys
local l_oDB_ListOfColumnOfTypeEnumeration
local l_oDB_ListOfForeignKeysNotMatchingPrimaryKeys
local l_oDB_CTEForeignKeysNotMatchingPrimaryKeys
local l_oDB_ListOfIssues
local l_oData
local l_cColumnType
local l_cWarningMessage
local l_nTestWarningCount
local l_cTestWarningMessage
local l_hTableWarning := {=>}
local l_hTableColumnCountWarning := {=>}   //To report the number of Column Warnings at the level of the table.
local l_hColumnWarning := {=>}
local l_hTableIndexCountWarning := {=>}   //To report the number of Index Warnings at the level of the table.
local l_hIndexWarning := {=>}
local l_hEnumerationWarning := {=>}
local l_nNumberOfColumnWarnings
local l_nNumberOfIndexWarnings
local l_iTableKey
local l_oDB_ListOfEnumerationsNumeric
local l_oDB_ListOfEnumerationsString
local l_oDB_ListOfEnumerations
local l_oDB_ListEnumerationColumnsWithIssues
local l_oDB_CTEEnumerationColumnsWithIssues
local l_lFixNullable
local l_lFixDefault
// local l_cLastSQL

with object l_oDB_Application
    :Table("d9689368-d768-4058-abb3-0cf4f0a1ddc3","Application")

    :Column("Application.KeyConfig"                            ,"Application_KeyConfig")
    :Column("Application.TestTableHasPrimaryKey"               ,"Application_TestTableHasPrimaryKey")
    :Column("Application.TestForeignKeyTypeMatchPrimaryKey"    ,"Application_TestForeignKeyTypeMatchPrimaryKey")
    :Column("Application.TestForeignKeyIsNullable"             ,"Application_TestForeignKeyIsNullable")
    :Column("Application.TestForeignKeyNoDefault"              ,"Application_TestForeignKeyNoDefault")
    :Column("Application.TestForeignKeyMissingOnDeleteSetting" ,"Application_TestForeignKeyMissingOnDeleteSetting")
    :Column("Application.TestNumericEnumerationWideEnough"     ,"Application_TestNumericEnumerationWideEnough")
    :Column("Application.TestMaxTableNameLength"               ,"Application_TestMaxTableNameLength")
    :Column("Application.TestMaxColumnNameLength"              ,"Application_TestMaxColumnNameLength")
    :Column("Application.TestMaxIndexNameLength"               ,"Application_TestMaxIndexNameLength")
    :Column("Application.TestMissingForeignKeyTable"           ,"Application_TestMissingForeignKeyTable")
    :Column("Application.TestMissingEnumerationValues"         ,"Application_TestMissingEnumerationValues")
    :Column("Application.TestUseOfDiscontinuedEnumeration"     ,"Application_TestUseOfDiscontinuedEnumeration")
    :Column("Application.TestUseOfDiscontinuedForeignTable"    ,"Application_TestUseOfDiscontinuedForeignTable")

    l_oData := :Get(par_iApplicationPk)
endwith

with object l_oDB_ListOfTables
    :Table("d66cac69-15d9-460c-b2af-774b407a9e51","Namespace")
    :Column("Table.Pk"                      , "Table_Pk")
    :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfTables")
endwith

with object l_oDB_ListOfColumns
    :Table("d66cac69-15d9-460c-b2af-774b407a9e52","Namespace")
    :Column("Column.Pk"                      , "Column_Pk")
    :Column("Column.Type"                    , "Column_Type")
    :Column("Column.UsedAs"                  , "Column_UsedAs")
    :Column("Column.Length"                  , "Column_Length")
    :Column("Column.Scale"                   , "Column_Scale")
    :Column("Column.Nullable"                , "Column_Nullable")
    // :Column("Column.LastNativeType"       , "Column_LastNativeType")
    // :Column("Column.TestWarning"          , NULL)
    :Column("Column.DefaultType"             , "Column_DefaultType")
    :Column("Column.DefaultCustom"           , "Column_DefaultCustom")
    :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfColumns")
endwith

with object l_oDB_ListOfTemplateColumns
    :Table("9732bc50-4c90-4154-853e-500dbe7cb757","TemplateTable")
    :Column("TemplateColumn.Pk"            , "TemplateColumn_Pk")
    :Column("TemplateColumn.Type"          , "TemplateColumn_Type")
    :Column("TemplateColumn.UsedAs"        , "TemplateColumn_UsedAs")
    :Column("TemplateColumn.Length"        , "TemplateColumn_Length")
    :Column("TemplateColumn.Scale"         , "TemplateColumn_Scale")
    :Column("TemplateColumn.Nullable"      , "TemplateColumn_Nullable")
    :Column("TemplateColumn.DefaultType"   , "TemplateColumn_DefaultType")
    :Column("TemplateColumn.DefaultCustom" , "TemplateColumn_DefaultCustom")
    :Join("inner","TemplateColumn" ,"","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfTemplateColumns")
    // ExportTableToHtmlFile("ListOfTemplateColumns",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfTemplateColumns.html","From PostgreSQL",,200,.t.)
endwith

with object l_oDB_ListOfTablesWithWarning
    :Table("d66cac69-15d9-460c-b2af-774b407a9e52","Namespace")
    :Column("Table.Pk"          , "Table_Pk")
    :Column("Table.TestWarning" , "Table_TestWarning")
    :Where("Table.TestWarning IS NOT NULL")
    :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfTablesWithWarning")
    // with object :p_oCursor
    //     :Index("pk","Table_Pk")
    //     :CreateIndexes()
    // endwith
    // ExportTableToHtmlFile("ListOfTablesWithWarning",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfTablesWithWarning.html","From PostgreSQL",,200,.t.)
endwith

with object l_oDB_ListOfColumnsWithWarning
    :Table("d66cac69-15d9-460c-b2af-774b407a9e53","Namespace")
    :Column("Column.Pk"          , "Column_Pk")
    :Column("Column.TestWarning" , "Column_TestWarning")
    :Where("Column.TestWarning IS NOT NULL")
    :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfColumnsWithWarning")
endwith

with object l_oDB_ListOfEnumerationsWithWarning
    :Table("f3f13b91-8adc-45e0-812e-a0c05c96fdf4","Namespace")
    :Column("Enumeration.Pk"          , "Enumeration_Pk")
    :Column("Enumeration.TestWarning" , "Enumeration_TestWarning")
    :Where("Enumeration.TestWarning IS NOT NULL")
    :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfEnumerationsWithWarning")
endwith

with object l_oDB_ListOfIndexesWithWarning
    :Table("ef590ae2-afcb-42e3-b643-5fb28da2f712","Namespace")
    :Column("Index.Pk"          , "Index_Pk")
    :Column("Index.TestWarning" , "Index_TestWarning")
    :Where("Index.TestWarning IS NOT NULL")
    :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index","","Index.fk_Table = Table.pk")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfIndexesWithWarning")
endwith

do case
case l_oData:Application_KeyConfig == 2  // Integer
    l_cColumnType := "I"
case l_oData:Application_KeyConfig == 3  // Integer Big
    l_cColumnType := "IB"
otherwise
    l_cColumnType := ""
endcase

if !empty(l_cColumnType)
    select ListOfColumns
    scan all for ListOfColumns->Column_UsedAs == COLUMN_USEDAS_PRIMARY_KEY
        if !(alltrim(ListOfColumns->Column_Type) == l_cColumnType) .or. ;
           !hb_isNil((ListOfColumns->Column_Length))               .or. ;
           !hb_isNil((ListOfColumns->Column_Scale))                .or. ;
           ListOfColumns->Column_Nullable                          .or. ;
           ListOfColumns->Column_DefaultType <> 15                 .or. ;
           !hb_isNil((ListOfColumns->Column_DefaultCustom))

            with object l_oDB_Record
                :Table("a9a24790-1b94-4c45-97b1-15f2009d74d6","Column")
                :Field("Column.Type"           , l_cColumnType)
                :Field("Column.Length"         , NULL)
                :Field("Column.Scale"          , NULL)
                :Field("Column.Nullable"       , .f.)
                :Field("Column.LastNativeType" , NULL)
                :Field("Column.TestWarning"    , NULL)
                :Field("Column.DefaultType"    , 15)
                :Field("Column.DefaultCustom"  , NULL)
                :Update(ListOfColumns->Column_Pk)
                hb_orm_SendToDebugView("Fixed Primary in Columns",ListOfColumns->Column_Pk)
            endwith
        endif
    endscan

    select ListOfTemplateColumns
    scan all for ListOfTemplateColumns->TemplateColumn_UsedAs == COLUMN_USEDAS_PRIMARY_KEY
        if !(alltrim(ListOfTemplateColumns->TemplateColumn_Type) == l_cColumnType) .or. ;
           !hb_isNil((ListOfTemplateColumns->TemplateColumn_Length))               .or. ;
           !hb_isNil((ListOfTemplateColumns->TemplateColumn_Scale))                .or. ;
           ListOfTemplateColumns->TemplateColumn_Nullable                          .or. ;
           ListOfTemplateColumns->TemplateColumn_DefaultType <> 15                 .or. ;
           !hb_isNil((ListOfTemplateColumns->TemplateColumn_DefaultCustom))

            with object l_oDB_Record
                :Table("a9a24790-1b94-4c45-97b1-15f2009d74d6","TemplateColumn")
                :Field("TemplateColumn.Type"           , l_cColumnType)
                :Field("TemplateColumn.Length"         , NULL)
                :Field("TemplateColumn.Scale"          , NULL)
                :Field("TemplateColumn.Nullable"       , .f.)
                :Field("TemplateColumn.LastNativeType" , NULL)
                :Field("TemplateColumn.TestWarning"    , NULL)
                :Field("TemplateColumn.DefaultType"    , 15)
                :Field("TemplateColumn.DefaultCustom"  , NULL)
                :Update(ListOfTemplateColumns->TemplateColumn_Pk)
                hb_orm_SendToDebugView("Fixed Primary In TemplateColumns",ListOfTemplateColumns->TemplateColumn_Pk)
            endwith
        endif
    endscan

endif

if vfp_inlist(l_oData:Application_KeyConfig,2,3) .or. ;
    l_oData:Application_TestForeignKeyTypeMatchPrimaryKey

    l_oDB_ListOfForeignKeys                       := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB_ListOfPrimaryKeys                       := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB_ListOfForeignKeysNotMatchingPrimaryKeys := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB_CTEForeignKeysNotMatchingPrimaryKeys    := hb_SQLCompoundQuery(oFcgi:p_o_SQLConnection)

    //CTE
    with object l_oDB_ListOfForeignKeys
        :Table("d10b0a4e-2fbc-41ed-a7c3-1aae089cc2b4","Namespace")
        :Column("Table.Pk"              ,"Table_Pk")
        :Column("Column.Pk"             ,"Column_Pk")
        :Column("Column.fk_TableForeign","Column_fk_TableForeign")
        :Column("Column.Type"           ,"Column_Type")
        :Column("Column.Length"         ,"Column_Length")
        :Column("Column.Scale"          ,"Column_Scale")
        :Where("Column.UsedAs = ^" , COLUMN_USEDAS_FOREIGN_KEY)
        :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    endwith

    with object l_oDB_ListOfPrimaryKeys
        :Table("d10b0a4e-2fbc-41ed-a7c3-1aae089cc2b4","Namespace")
        :Column("Table.Pk"              ,"Table_Pk")
        :Column("Column.Type"           ,"Column_Type")
        :Column("Column.Length"         ,"Column_Length")
        :Column("Column.Scale"          ,"Column_Scale")
        :Where("Column.UsedAs = ^" , COLUMN_USEDAS_PRIMARY_KEY)
        :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    endwith

    with object l_oDB_ListOfForeignKeysNotMatchingPrimaryKeys
        :AddNonTableAliases("ListOfPrimaryKeys")
        :AddNonTableAliases("ListOfForeignKeys")
        :Table("edb77980-6c82-4fe5-a595-2ac02ee7ac7c","ListOfForeignKeys")
        :Column("ListOfForeignKeys.Table_Pk  "     , "Table_Pk")
        :Column("ListOfForeignKeys.Column_Pk"      , "Column_Pk")
        :Column("ListOfPrimaryKeys.Column_Type"    , "Column_Type")
        :Column("ListOfPrimaryKeys.Column_Length"  , "Column_Length")
        :Column("ListOfPrimaryKeys.Column_Scale"   , "Column_Scale")
        :Join("inner","ListOfPrimaryKeys","","ListOfForeignKeys.Column_fk_TableForeign = ListOfPrimaryKeys.Table_Pk")
        :Where("(ListOfPrimaryKeys.Column_Type <> ListOfForeignKeys.Column_Type ) or "+;
                "(ListOfPrimaryKeys.Column_Length IS DISTINCT FROM ListOfForeignKeys.Column_Length ) or "+;   //Had to use "IS DISTINCT FROM" to deal with comparing nulls.
                "(ListOfPrimaryKeys.Column_Scale IS DISTINCT FROM ListOfForeignKeys.Column_Scale )")
    endwith

    with object l_oDB_CTEForeignKeysNotMatchingPrimaryKeys
        :AnchorAlias("5a8e9dfa-6592-4318-8145-477a175665d0","QueryToComparePrimaryToForeign")
        :AddSQLCTEQuery("ListOfPrimaryKeys",l_oDB_ListOfPrimaryKeys)
        :AddSQLCTEQuery("ListOfForeignKeys",l_oDB_ListOfForeignKeys)
        :AddSQLDataQuery("QueryToComparePrimaryToForeign" ,l_oDB_ListOfForeignKeysNotMatchingPrimaryKeys)
    endwith

    if vfp_inlist(l_oData:Application_KeyConfig,2,3)
        l_oDB_CTEForeignKeysNotMatchingPrimaryKeys:SQL("ListOfForeignKeysNotMatchingPrimaryKeys")
        // SendToClipboard(l_oDB_CTEForeignKeysNotMatchingPrimaryKeys:LastSQL())

        select ListOfForeignKeysNotMatchingPrimaryKeys
        scan all
            with object l_oDB_Record
                :Table("07d63048-affd-4f36-b8df-97c5b878b118","Column")
                :Field("Column.Type"           , ListOfForeignKeysNotMatchingPrimaryKeys->Column_Type)
                :Field("Column.Length"         , ListOfForeignKeysNotMatchingPrimaryKeys->Column_Length)
                :Field("Column.Scale"          , ListOfForeignKeysNotMatchingPrimaryKeys->Column_Scale)
                :Field("Column.LastNativeType" , NULL)
                :Field("Column.TestWarning"    , NULL)
                :Update(ListOfForeignKeysNotMatchingPrimaryKeys->Column_Pk)
            endwith
        endscan
    endif

endif

if vfp_inlist(l_oData:Application_KeyConfig,2,3)

    l_oDB_ListOfForeignKeysNotNullableOrWithDefault := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfForeignKeysNotNullableOrWithDefault
        :Table("59316c76-28e6-4662-9a5c-967fe2d80265","Namespace")
        :Column("Column.Pk"           ,"Column_Pk")
        :Column("Column.Type"         ,"Column_Type")
        :Column("Column.Nullable"     ,"Column_Nullable")
        :Column("Column.DefaultType"  ,"Column_DefaultType")
        :Column("Column.DefaultCustom","Column_DefaultCustom")
        :Where("Column.UsedAs = ^" , COLUMN_USEDAS_FOREIGN_KEY)
        :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Where("NOT Column.Nullable OR Column.DefaultType > 0")   // Will reduce to potential list of foreign keys with issues
        :SQL("ListOfForeignKeysNotNullableOrWithDefault")
    endwith

    select ListOfForeignKeysNotNullableOrWithDefault
    scan all
        l_lFixNullable := .f.
        l_lFixDefault  := .f.

        if !ListOfForeignKeysNotNullableOrWithDefault->Column_Nullable
            l_lFixNullable := .t.
        endif
        if !empty(GetColumnDefault(.f.,ListOfForeignKeysNotNullableOrWithDefault->Column_Type,ListOfForeignKeysNotNullableOrWithDefault->Column_DefaultType,ListOfForeignKeysNotNullableOrWithDefault->Column_DefaultCustom))
            l_lFixDefault := .t.
        endif

        if l_lFixNullable .or. l_lFixDefault
            with object l_oDB_Record
                :Table("bb655a3a-d4cc-4d6e-82ff-b4739f890227","Column")
                if l_lFixNullable
                    :Field("Column.Nullable"      , .t.)
                endif
                if l_lFixDefault
                    :Field("Column.DefaultType"   , 0)
                    :Field("Column.DefaultCustom" , NULL)
                endif
                :Update(ListOfForeignKeysNotNullableOrWithDefault->Column_Pk)
            endwith

        endif
    endscan

endif

if l_oData:Application_TestTableHasPrimaryKey               .or. ;
   l_oData:Application_TestForeignKeyTypeMatchPrimaryKey    .or. ;
   l_oData:Application_TestForeignKeyIsNullable             .or. ;
   l_oData:Application_TestForeignKeyNoDefault              .or. ;
   l_oData:Application_TestForeignKeyMissingOnDeleteSetting .or. ;
   l_oData:Application_TestNumericEnumerationWideEnough     .or. ;
   l_oData:Application_TestMaxTableNameLength               .or. ;
   l_oData:Application_TestMaxColumnNameLength              .or. ;
   l_oData:Application_TestMaxIndexNameLength               .or. ;
   l_oData:Application_TestMissingForeignKeyTable           .or. ;
   l_oData:Application_TestMissingEnumerationValues         .or. ;
   l_oData:Application_TestUseOfDiscontinuedEnumeration     .or. ;
   l_oData:Application_TestUseOfDiscontinuedForeignTable

    // -- Test: Table must have a Primary Key --------------------------------------------------------------------------------
    if l_oData:Application_TestTableHasPrimaryKey
        l_oDB_ListOfTablesWithPrimaryKey := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB_ListOfTablesWithPrimaryKey
            :Table("1fa6541c-ba10-4c28-a070-62c2cf065e29","Namespace")
            :Distinct(.t.)
            :Column("Table.Pk" , "Table_Pk")
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("Column.UsedAs = ^"           ,COLUMN_USEDAS_PRIMARY_KEY)
            :SQL("ListOfTablesWithPrimaryKey")
            with object :p_oCursor
                :Index("pk","Table_Pk")
                :CreateIndexes()
            endwith
        endwith

        select ListOfTables
        scan all
            if !vfp_Seek(ListOfTables->Table_Pk,"ListOfTablesWithPrimaryKey","pk")
                l_cWarningMessage := hb_HGetDef(l_hTableWarning,ListOfTables->Table_Pk,"")
                l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Table missing Primary Key."
                l_hTableWarning[ListOfTables->Table_Pk] := l_cWarningMessage
            endif
        endscan

    endif

    // -- Test: Foreign Key Type must match Primary Key Type --------------------------------------------------------------------------------
    if l_oData:Application_TestForeignKeyTypeMatchPrimaryKey
        l_oDB_CTEForeignKeysNotMatchingPrimaryKeys:SQL("ListOfForeignKeysNotMatchingPrimaryKeys")   //Rerun SQL Since could have fixed issue before.()
        // SendToClipboard(l_oDB_CTEForeignKeysNotMatchingPrimaryKeys:LastSQL())

        select ListOfForeignKeysNotMatchingPrimaryKeys
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfForeignKeysNotMatchingPrimaryKeys->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Type does not match Primary Key."
            l_hColumnWarning[ListOfForeignKeysNotMatchingPrimaryKeys->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfForeignKeysNotMatchingPrimaryKeys->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfForeignKeysNotMatchingPrimaryKeys->Table_Pk,0)+1
        endscan
        
    endif

    // -- Test: Foreign Key may not have a default value --------------------------------------------------------------------------------
    // -- Test: Foreign Key must be Nullable --------------------------------------------------------------------------------
    // -- Test: Missing "On Delete" setting for Foreign Keys. --------------------------------------------------------------------------------
    if l_oData:Application_TestForeignKeyNoDefault  .or. ;
       l_oData:Application_TestForeignKeyIsNullable .or. ;
       l_oData:Application_TestForeignKeyMissingOnDeleteSetting
        if hb_IsNil(l_oDB_ListOfForeignKeys)
            l_oDB_ListOfForeignKeys := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif

        with object l_oDB_ListOfForeignKeys
            :Table("5839cf1b-ce17-478d-bec9-cdb9205ef5cb","Namespace")
            :Column("Table.Pk"            ,"Table_Pk")
            :Column("Column.Pk"           ,"Column_Pk")
            :Column("Column.Type"         ,"Column_Type")
            :Column("Column.Nullable"     ,"Column_Nullable")
            :Column("Column.DefaultType"  ,"Column_DefaultType")
            :Column("Column.DefaultCustom","Column_DefaultCustom")
            :Column("Column.OnDelete"     ,"Column_OnDelete")
            :Where("Column.UsedAs = ^" , COLUMN_USEDAS_FOREIGN_KEY)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("NOT Column.Nullable OR Column.DefaultType > 0")   // Will reduce to potential list of foreign keys with issues
            :SQL("ListOfForeignKeys")
        endwith

        select ListOfForeignKeys
        scan all
            l_nTestWarningCount   := 0
            l_cTestWarningMessage := ""

            if l_oData:Application_TestForeignKeyIsNullable
                if !ListOfForeignKeys->Column_Nullable
                    l_cTestWarningMessage := "Foreign Key is not Nullable."
                    l_nTestWarningCount++
                endif
            endif
            if l_oData:Application_TestForeignKeyNoDefault
                if !empty(GetColumnDefault(.f.,ListOfForeignKeys->Column_Type,ListOfForeignKeys->Column_DefaultType,ListOfForeignKeys->Column_DefaultCustom))
                    if !empty(l_cTestWarningMessage)
                        l_cTestWarningMessage += CRLF
                    endif
                    l_cTestWarningMessage += "Foreign Key has a default value."
                    l_nTestWarningCount++
                endif
            endif
            if l_oData:Application_TestForeignKeyMissingOnDeleteSetting
                if ListOfForeignKeys->Column_OnDelete <= 1
                    if !empty(l_cTestWarningMessage)
                        l_cTestWarningMessage += CRLF
                    endif
                    l_cTestWarningMessage += [Missing "On Delete" Foreign Key setting.]
                    l_nTestWarningCount++
                endif
            endif

            if l_nTestWarningCount > 0
                l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfForeignKeys->Column_Pk,"")

                l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+l_cTestWarningMessage
                l_hColumnWarning[ListOfForeignKeys->Column_Pk] := l_cWarningMessage

                l_hTableColumnCountWarning[ListOfForeignKeys->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfForeignKeys->Table_Pk,0)+l_nTestWarningCount
            endif
        endscan

    endif

    // -- Test: Numeric Enumerations must be large enough to handle largest Value --------------------------------------------------------------------------------
    if l_oData:Application_TestNumericEnumerationWideEnough

        l_oDB_ListOfColumnOfTypeEnumeration := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfColumnOfTypeEnumeration
            :Table("4f0a3fb1-0070-48cd-89f4-669973fd89e7","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            :Column("Column.fk_Enumeration" ,"Column_fk_Enumeration")
            :Where("Column.UsedAs != ^" , COLUMN_USEDAS_PRIMARY_KEY)
            :Where("Column.UsedAs != ^" , COLUMN_USEDAS_FOREIGN_KEY)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            // :Where("Column.fk_Enumeration IS NOT NULL AND Column.fk_Enumeration > 0")
            :Where("Column.fk_Enumeration > 0")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        endwith

        l_oDB_ListOfEnumerationsNumeric := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfEnumerationsNumeric
            :Table("56a4de54-6fca-4506-abb1-9e6f3527d49b","Namespace")
            :Column("Enumeration.Pk"                      ,"Enumeration_Pk")
            :Column("Enumeration.ImplementAs"             ,"Enumeration_ImplementAs")
            :Column("Enumeration.ImplementLength"         ,"Enumeration_ImplementLength")
            :Column("length(max(EnumValue.Number)::text)" ,"max_EnumValue_length")
            :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
            :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("Enumeration.ImplementAs = ^",ENUMERATIONIMPLEMENTAS_NUMERIC)
            :GroupBy("Enumeration_Pk")
            :GroupBy("Enumeration_ImplementAs")
            :GroupBy("Enumeration_ImplementLength")
            :Having("length(max(EnumValue.Number)::text) > Enumeration.ImplementLength")
            :OrderBy("Enumeration_Pk")
        endwith
    
        l_oDB_ListOfEnumerationsString := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfEnumerationsString
            :Table("56a4de54-6fca-4506-abb1-9e6f3527d49c","Namespace")
            :Column("Enumeration.Pk"                      ,"Enumeration_Pk")
            :Column("Enumeration.ImplementAs"             ,"Enumeration_ImplementAs")
            :Column("Enumeration.ImplementLength"         ,"Enumeration_ImplementLength")
            :Column("max(length(EnumValue.Name))"         ,"max_EnumValue_length")
            :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
            :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("Enumeration.ImplementAs = ^",ENUMERATIONIMPLEMENTAS_VARCHAR)
            :GroupBy("Enumeration_Pk")
            :GroupBy("Enumeration_ImplementAs")
            :GroupBy("Enumeration_ImplementLength")
            :Having("max(length(EnumValue.Name)) > Enumeration.ImplementLength")
            :OrderBy("Enumeration_Pk")
        endwith

        // Create a union of Enumerations
        l_oDB_ListOfEnumerations := hb_SQLCompoundQuery(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfEnumerations
            :AnchorAlias("5d832863-3fb9-45e2-b8ba-e7534ecb1219","ListOfEnumerations")  // In Combined, the Alias need to be the result of the First combine
            :AddSQLDataQuery("ListOfEnumerationsNumeric",l_oDB_ListOfEnumerationsNumeric)
            :AddSQLDataQuery("ListOfEnumerationsString",l_oDB_ListOfEnumerationsString)
            :CombineQueries(COMBINE_ACTION_UNION,"ListOfEnumerations",.t.,"ListOfEnumerationsNumeric","ListOfEnumerationsString")
            :SQL("ListOfEnumerations")
        endwith

        select ListOfEnumerations
        scan all
            l_cWarningMessage := hb_HGetDef(l_hEnumerationWarning,ListOfEnumerations->Enumeration_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Enumeration is not wide enough."
            l_hEnumerationWarning[ListOfEnumerations->Enumeration_Pk] := l_cWarningMessage
        endscan

        l_oDB_ListEnumerationColumnsWithIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListEnumerationColumnsWithIssues
            :AddNonTableAliases("ListOfColumnOfTypeEnumeration")
            :AddNonTableAliases("ListOfEnumerations")
            :Table("ead746ab-75c2-4a2e-9c8f-cec89c9211d2","ListOfColumnOfTypeEnumeration")
            :Join("inner","ListOfEnumerations","","ListOfColumnOfTypeEnumeration.Column_fk_Enumeration = ListOfEnumerations.Enumeration_Pk")
            :Column("ListOfColumnOfTypeEnumeration.Table_Pk"  , "Table_Pk")
            :Column("ListOfColumnOfTypeEnumeration.Column_Pk" , "Column_Pk")
        endwith
        
        l_oDB_CTEEnumerationColumnsWithIssues := hb_SQLCompoundQuery(oFcgi:p_o_SQLConnection)
        with object l_oDB_CTEEnumerationColumnsWithIssues
            :AnchorAlias("5d832863-3fb9-45e2-b8ba-e7534ecb1219","ListEnumerationColumnsWithIssues")  // In Combined, the Alias need to be the result of the First combine
            :AddSQLCTEQuery("ListOfEnumerations",l_oDB_ListOfEnumerations)
            :AddSQLCTEQuery("ListOfColumnOfTypeEnumeration",l_oDB_ListOfColumnOfTypeEnumeration)
            :AddSQLDataQuery("ListEnumerationColumnsWithIssues" ,l_oDB_ListEnumerationColumnsWithIssues)
            :SQL("ListEnumerationColumnsWithIssues")
            // SendToClipboard(:LastSQL())
        endwith

        select ListEnumerationColumnsWithIssues
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListEnumerationColumnsWithIssues->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Enumeration is not wide enough."
            l_hColumnWarning[ListEnumerationColumnsWithIssues->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListEnumerationColumnsWithIssues->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListEnumerationColumnsWithIssues->Table_Pk,0)+1
        endscan

    endif

    // -- Test: Maximum Table Name length is 63 characters --------------------------------------------------------------------------------
    if l_oData:Application_TestMaxTableNameLength
        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("09cd3b1e-e68a-47e5-a76a-60140bf44847","Namespace")
            :Column("Table.Pk" ,"Table_Pk")
            :Where("Length(Table.Name) > ^",63)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfTablesMaxNameLength")
        endwith

        select ListOfTablesMaxNameLength
        scan all
            l_cWarningMessage := hb_HGetDef(l_hTableWarning,ListOfTablesMaxNameLength->Table_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Table Name is too long."
            l_hTableWarning[ListOfTablesMaxNameLength->Table_Pk] := l_cWarningMessage
        endscan
    endif

    // -- Test: Maximum Column Name length is 59 characters (Postgres) --------------------------------------------------------------------------------
    if l_oData:Application_TestMaxColumnNameLength
        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("38554238-90c0-437f-8737-470f5381c9da","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            :Where("Length(Column.Name) > ^",59)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfColumnMaxNameLength")
        endwith

        select ListOfColumnMaxNameLength
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfColumnMaxNameLength->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Column Name is too long."
            l_hColumnWarning[ListOfColumnMaxNameLength->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfColumnMaxNameLength->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfColumnMaxNameLength->Table_Pk,0)+1
        endscan
    endif

    // -- Test: Maximum Index Name (After adding Table Names and suffix) 63 characters (Postgresql) --------------------------------------------------------------------------------
    if l_oData:Application_TestMaxIndexNameLength

        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("5597e75d-a64b-43f5-96ea-737174f95a21","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Index.Pk"             ,"Index_Pk")
            :Column("lower(concat(Table.Name,'_',Index.Name,'_idx'))" , "PostgreSQLIndexName")
            :Where("Length(concat(Table.Name,'_',Index.Name,'_idx')) > ^",63)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Index","","Index.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfIndexMaxNameLength")
        endwith

        select ListOfIndexMaxNameLength
        scan all
            l_cWarningMessage := hb_HGetDef(l_hIndexWarning,ListOfIndexMaxNameLength->Index_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+[Index Name as "]+ListOfIndexMaxNameLength->PostgreSQLIndexName+[" implementation is too long.]
            l_hIndexWarning[ListOfIndexMaxNameLength->Index_Pk] := l_cWarningMessage

            l_hTableIndexCountWarning[ListOfIndexMaxNameLength->Table_Pk] := hb_HGetDef(l_hTableIndexCountWarning,ListOfIndexMaxNameLength->Table_Pk,0)+1
        endscan

    endif

    // -- Test: All Foreign Keys must point to a table --------------------------------------------------------------------------------
    if l_oData:Application_TestMissingForeignKeyTable
        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("03f33a4f-90a6-4cae-a9e4-8d054e8d698d","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            :Where("Column.UsedAs = ^" , COLUMN_USEDAS_FOREIGN_KEY)
            // :Where("Column.fk_TableForeign IS NULL")
            :Where("Column.fk_TableForeign = 0")
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfIssues")
        endwith

        select ListOfIssues
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfIssues->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Missing Foreign Key Table Name."
            l_hColumnWarning[ListOfIssues->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfIssues->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfIssues->Table_Pk,0)+1
        endscan
    endif

    // -- Test: All Enumeration Fields must point to a enumeration --------------------------------------------------------------------------------
    if l_oData:Application_TestMissingEnumerationValues
        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("72aa23ad-f502-43b6-aa0a-6628ce578158","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            :Where("Column.UsedAs != ^" , COLUMN_USEDAS_PRIMARY_KEY)
            :Where("Column.UsedAs != ^" , COLUMN_USEDAS_FOREIGN_KEY)
            // :Where("Column.fk_Enumeration IS NULL OR Column.fk_Enumeration = 0")
            // :Where("Column.fk_Enumeration IS NULL")
            :Where("Column.fk_Enumeration = 0")
            :Where("Column.Type = ^","E")
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :SQL("ListOfIssues")
//123456
// SendToClipboard(:LastSQL())
// altd()
        endwith

        select ListOfIssues
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfIssues->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Missing Enumeration Name."
            l_hColumnWarning[ListOfIssues->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfIssues->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfIssues->Table_Pk,0)+1
        endscan
    endif

    // -- Test: Non Discontinued Fields may not point to a Discontinued Enumeration --------------------------------------------------------------------------------
    if l_oData:Application_TestUseOfDiscontinuedEnumeration

        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("02020bf4-49b7-430c-843a-262e75b9d13a","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            // :Where("Column.UsedAs != ^" , COLUMN_USEDAS_PRIMARY_KEY)
            // :Where("Column.UsedAs != ^" , COLUMN_USEDAS_FOREIGN_KEY)
            :Where("Column.Type = ^","E")
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Join("inner","Enumeration","","Column.fk_Enumeration = Enumeration.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("Column.UseStatus != ^",USESTATUS_DISCONTINUED)
            :Where("Enumeration.UseStatus = ^",USESTATUS_DISCONTINUED)
            :SQL("ListOfIssues")
        endwith

        select ListOfIssues
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfIssues->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Non discontinued Column of discontinued Enumeration."
            l_hColumnWarning[ListOfIssues->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfIssues->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfIssues->Table_Pk,0)+1
        endscan

    endif

    // -- Test: Non Discontinued Foreign Keys may not point to a Discontinued Table --------------------------------------------------------------------------------
    if l_oData:Application_TestUseOfDiscontinuedForeignTable

        if hb_IsNil(l_oDB_ListOfIssues)
            l_oDB_ListOfIssues := hb_SQLData(oFcgi:p_o_SQLConnection)
        endif
        with object l_oDB_ListOfIssues
            :Table("14c0d88b-4fa7-4981-892d-5732e013e67d","Namespace")
            :Column("Table.Pk"              ,"Table_Pk")
            :Column("Column.Pk"             ,"Column_Pk")
            // :Where("Column.UsedAs != ^" , COLUMN_USEDAS_PRIMARY_KEY)
            // :Where("Column.UsedAs != ^" , COLUMN_USEDAS_FOREIGN_KEY)
            :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Column","","Column.fk_Table = Table.pk")
            :Join("inner","Table","TableForeign","Column.fk_TableForeign = TableForeign.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Where("Column.UseStatus != ^",USESTATUS_DISCONTINUED)
            :Where("TableForeign.UseStatus = ^",USESTATUS_DISCONTINUED)
            :SQL("ListOfIssues")
            // SendToClipboard(:LastSQL())
        endwith

        select ListOfIssues
        scan all
            l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfIssues->Column_Pk,"")
            l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+"Non discontinued Column of discontinued Parent Table."
            l_hColumnWarning[ListOfIssues->Column_Pk] := l_cWarningMessage

            l_hTableColumnCountWarning[ListOfIssues->Table_Pk] := hb_HGetDef(l_hTableColumnCountWarning,ListOfIssues->Table_Pk,0)+1
        endscan

    endif

endif


// Finalize: Add all the l_hTableColumnCountWarning to l_hTableWarning ----------------------------------------------
for each l_nNumberOfColumnWarnings in l_hTableColumnCountWarning
    if l_nNumberOfColumnWarnings > 0
        l_iTableKey := l_nNumberOfColumnWarnings:__enumkey

        l_cWarningMessage := hb_HGetDef(l_hTableWarning,l_iTableKey,"")
        l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+trans(l_nNumberOfColumnWarnings)+" Column Warning"+iif(l_nNumberOfColumnWarnings>1,"s","")
        l_hTableWarning[l_iTableKey] := l_cWarningMessage
    endif
endfor
hb_HClear(l_hTableColumnCountWarning)

// Finalize: Add all the l_hTableIndexCountWarning to l_hTableWarning ----------------------------------------------
for each l_nNumberOfIndexWarnings in l_hTableIndexCountWarning
    if l_nNumberOfIndexWarnings > 0
        l_iTableKey := l_nNumberOfIndexWarnings:__enumkey

        l_cWarningMessage := hb_HGetDef(l_hTableWarning,l_iTableKey,"")
        l_cWarningMessage += iif(empty(l_cWarningMessage),"",CRLF)+trans(l_nNumberOfIndexWarnings)+" Index Warning"+iif(l_nNumberOfIndexWarnings>1,"s","")
        l_hTableWarning[l_iTableKey] := l_cWarningMessage
    endif
endfor
hb_HClear(l_hTableIndexCountWarning)

// Finalize: Update the Table.TestWarning ----------------------------------------------
select ListOfTablesWithWarning
scan all
    l_cWarningMessage := hb_HGetDef(l_hTableWarning,ListOfTablesWithWarning->Table_Pk,"")

    if empty(l_cWarningMessage)
        //No more warning
        with object l_oDB_Record
            :Table("18237ea3-f5d5-4a47-b7fa-57f0606b8d42","Table")
            :Field("Table.TestWarning" , NULL)
            :Update(ListOfTablesWithWarning->Table_Pk)
        endwith
    else
        if !(ListOfTablesWithWarning->Table_TestWarning == l_cWarningMessage)  //Warning Changed
            with object l_oDB_Record
                :Table("18237ea3-f5d5-4a47-b7fa-57f0606b8d43","Table")
                :Field("Table.TestWarning" , l_cWarningMessage)
                :Update(ListOfTablesWithWarning->Table_Pk)
            endwith
        endif
        hb_HDel(l_hTableWarning,ListOfTablesWithWarning->Table_Pk)  //To ensure we don't readd a Warning
    endif
endscan
for each l_cWarningMessage in l_hTableWarning   //Process the remaining Table Warnings
    with object l_oDB_Record
        :Table("18237ea3-f5d5-4a47-b7fa-57f0606b8d44","Table")
        :Field("Table.TestWarning" , l_cWarningMessage)
        :Update(l_cWarningMessage:__enumkey)
    endwith
endfor
hb_HClear(l_hTableWarning)

// Finalize: Update the Column.TestWarning ----------------------------------------------
select ListOfColumnsWithWarning
scan all
    l_cWarningMessage := hb_HGetDef(l_hColumnWarning,ListOfColumnsWithWarning->Column_Pk,"")
    if empty(l_cWarningMessage)
        //No more warning
        with object l_oDB_Record
            :Table("b1d59cd8-ba6d-4a32-b18e-413dbb51f0f9","Column")
            :Field("Column.TestWarning" , NULL)
            :Update(ListOfColumnsWithWarning->Column_Pk)
        endwith
    else
        if !(ListOfColumnsWithWarning->Column_TestWarning == l_cWarningMessage)  //Warning Changed
            with object l_oDB_Record
                :Table("e830edc0-fb41-4702-bda0-f90baab7ec77","Column")
                :Field("Column.TestWarning" , l_cWarningMessage)
                :Update(ListOfColumnsWithWarning->Column_Pk)
            endwith
        endif
        hb_HDel(l_hColumnWarning,ListOfColumnsWithWarning->Column_Pk)  //To ensure we don't readd a Warning
    endif
endscan
for each l_cWarningMessage in l_hColumnWarning   //Process the remaining Column Warnings
    with object l_oDB_Record
        :Table("99f8bbe8-6a84-439e-a63f-df70ff59f108","Column")
        :Field("Column.TestWarning" , l_cWarningMessage)
        :Update(l_cWarningMessage:__enumkey)
    endwith
endfor
hb_HClear(l_hColumnWarning)

// Finalize: Update the Index.TestWarning ----------------------------------------------
select ListOfIndexesWithWarning
scan all
    l_cWarningMessage := hb_HGetDef(l_hIndexWarning,ListOfIndexesWithWarning->Index_Pk,"")
    if empty(l_cWarningMessage)
        //No more warning
        with object l_oDB_Record
            :Table("b16776c0-99fa-4bb5-b154-5665a03dd487","Index")
            :Field("Index.TestWarning" , NULL)
            :Update(ListOfIndexesWithWarning->Index_Pk)
        endwith
    else
        if !(ListOfIndexesWithWarning->Index_TestWarning == l_cWarningMessage)  //Warning Changed
            with object l_oDB_Record
                :Table("7d445ed7-18c8-4b49-995d-7debf0b55203","Index")
                :Field("Index.TestWarning" , l_cWarningMessage)
                :Update(ListOfIndexesWithWarning->Index_Pk)
            endwith
        endif
        hb_HDel(l_hIndexWarning,ListOfIndexesWithWarning->Index_Pk)  //To ensure we don't readd a Warning
    endif
endscan
for each l_cWarningMessage in l_hIndexWarning   //Process the remaining Index Warnings
    with object l_oDB_Record
        :Table("f435ecac-a8a8-449d-944f-a053afba96e1","Index")
        :Field("Index.TestWarning" , l_cWarningMessage)
        :Update(l_cWarningMessage:__enumkey)
    endwith
endfor
hb_HClear(l_hIndexWarning)

// Finalize: Update the Enumeration.TestWarning ----------------------------------------------
select ListOfEnumerationsWithWarning
scan all
    l_cWarningMessage := hb_HGetDef(l_hEnumerationWarning,ListOfEnumerationsWithWarning->Enumeration_Pk,"")

    if empty(l_cWarningMessage)
        //No more warning
        with object l_oDB_Record
            :Table("9dc041e7-d810-46d8-affb-62f34fed700a","Enumeration")
            :Field("Enumeration.TestWarning" , NULL)
            :Update(ListOfEnumerationsWithWarning->Enumeration_Pk)
        endwith
    else
        if !(ListOfEnumerationsWithWarning->Enumeration_TestWarning == l_cWarningMessage)  //Warning Changed
            with object l_oDB_Record
                :Table("fec703e3-4ebf-4baf-9177-9a2a72c30c16","Enumeration")
                :Field("Enumeration.TestWarning" , l_cWarningMessage)
                :Update(ListOfEnumerationsWithWarning->Enumeration_Pk)
            endwith
        endif
        hb_HDel(l_hEnumerationWarning,ListOfEnumerationsWithWarning->Enumeration_Pk)  //To ensure we don't readd a Warning
    endif
endscan
for each l_cWarningMessage in l_hEnumerationWarning   //Process the remaining Enumeration Warnings
    with object l_oDB_Record
        :Table("58c2547d-da2e-4193-99b0-3d03bda8b1af","Enumeration")
        :Field("Enumeration.TestWarning" , l_cWarningMessage)
        :Update(l_cWarningMessage:__enumkey)
    endwith
endfor
hb_HClear(l_hEnumerationWarning)

return nil
//=================================================================================================================
