#include "DataWharf.ch"
//=================================================================================================================
function ExportApplicationToHarbour_ORM(par_iApplicationPk,par_nVersion,par_IncludeDescription,par_cBackend)

local l_lContinue := .t.
local l_oDB_Application
local l_oDB_ListOfTables
local l_oDB_ListOfColumns
local l_oDB_ListOfIndexes_OnForeignKey
local l_oDB_ListOfIndexes_Defined
local l_oDB_ListOfIndexes
local l_oDB_ListOfEnumerations
local l_oDB_ListOfEnumValues

local l_iTablePk
local l_iEnumerationPk

local l_cIndent := space(4)
local l_cIndentHashElement
local l_cNamespaceAndTableName

local l_nNumberOfTables
local l_nNumberOfFields
local l_nNumberOfIndexes
local l_nNumberOfEnumerations
local l_nNumberOfEnumValues

local l_cSourceCode := ""
local l_cSourceCodeFields
local l_nMaxNameLength
local l_nMaxExpressionLength
local l_nFieldUsedAs
local l_cFieldUsedBy
local l_cFieldName
local l_cFieldType
local l_cFieldTypeEnumName
local l_nFieldLen
local l_nFieldDec
local l_cFieldDefault        //The Default to export
local l_lFieldNullable
local l_lFieldAutoIncrement
local l_lFieldArray
local l_cFieldAttributes
local l_cFieldDescription
local l_cIndexPrefix
local l_cIndexName
local l_cEnumValueName
local l_cSourceCodeIndexes
local l_cIndexExpression
local l_nIndexRecno
local l_nEnumValueRecno
local lnEnumerationImplementAs
local lnEnumerationImplementLength
local l_lIncludeDescription := nvl(par_IncludeDescription,.f.)
local l_nUsedBy
local l_nTableCounter := 0
local l_nEnumerationCounter := 0
local l_cSchemaIndent := space(4)
local l_oData
local l_lAddForeignKeyIndexORMExport
local l_cSourceCodeEnumValues
local l_cNamespaceAndEnumerationName
local l_nEnumValue_Order
local l_nEnumValue_Number
local l_cImplementAs

oFcgi:p_o_SQLConnection:SetForeignKeyNullAndZeroParity(.f.)  //To ensure we keep the null values

l_oDB_Application        := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfTables       := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfColumns      := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfEnumerations := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfEnumValues   := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case par_cBackend == "PostgreSQL"
    l_nUsedBy := USEDBY_POSTGRESQLONLY
case par_cBackend == "MySQL"
    l_nUsedBy := USEDBY_MYSQLONLY
otherwise
    l_nUsedBy := -1
endcase

with object l_oDB_Application
    :Table("ddda0d32-5f65-4f5c-8025-42239f806aa8","Application")
    :Column("Application.AddForeignKeyIndexORMExport","AddForeignKeyIndexORMExport")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_lAddForeignKeyIndexORMExport := l_oData:AddForeignKeyIndexORMExport
    endif
endwith

with object l_oDB_ListOfTables
    :Table("299a129d-dab1-4dad-0001-000000000001","Namespace")
    // :Distinct(.t.)  // Needed since joining on columns to not use discontinued fields

    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")

    :Column("max(length(Column.Name))" , "MaxColumnNameLength")

    :Column("Namespace.Name"        ,"Namespace_Name")
    :Column("Table.Name"            ,"Table_Name")
    :Column("Table.Pk"              ,"Table_pk")
    :Column("upper(Namespace.Name)" ,"tag1")
    :Column("upper(Table.Name)"     ,"tag2")
    :Column("Table.Unlogged"        ,"Table_Unlogged")
    :GroupBy("Namespace_Name")
    :GroupBy("Table_Name")
    :GroupBy("Table_pk")
    :GroupBy("tag1")
    :GroupBy("tag2")

    :Where("Namespace.UseStatus <= ^",USESTATUS_TOBEDISCONTINUED)
    :Where("Table.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)
    :Where("Column.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)

    :OrderBy("tag1")
    :OrderBy("tag2")

    :Where("Column.UsedBy = ^ OR Column.UsedBy = ^",USEDBY_ALLSERVERS,l_nUsedBy)

    :SQL("ListOfTables")
    l_nNumberOfTables := :Tally
    if l_nNumberOfTables < 0
        l_lContinue := .f.
        l_cSourceCode += :LastSQL() + CRLF
    endif
    // l_cSourceCode += :LastSQL() + CRLF   // Used to see how the changes to beautify code is done in the Harbour_ORM
endwith

if l_lContinue
    with object l_oDB_ListOfColumns
        :Table("299a129d-dab1-4dad-0001-000000000002","Namespace")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Join("inner","Table"      ,""               ,"Table.fk_Namespace = Namespace.pk")
        :Join("inner","Column"     ,""               ,"Column.fk_Table = Table.pk")
        :Join("left", "Enumeration",""               ,"Column.fk_Enumeration = Enumeration.pk")
        :Join("left", "Table"      ,"ParentTable"    ,"Column.fk_TableForeign = ParentTable.pk")
        :Join("left", "Namespace"  ,"ParentNamespace","ParentTable.fk_Namespace = ParentNamespace.pk")
        :Column("Table.Pk"             ,"Table_Pk")
        :Column("Column.Name"          ,"Column_Name")
        :Column("Column.Order"         ,"Column_Order")
        :Column("Column.Type"          ,"Column_Type")
        :Column("Column.Length"        ,"Column_Length")
        :Column("Column.Scale"         ,"Column_Scale")
        :Column("Column.Nullable"      ,"Column_Nullable")
        :Column("Column.Array"         ,"Column_Array")
        :Column("Column.Unicode"       ,"Column_Unicode")
        :Column("Column.DefaultType"   ,"Column_DefaultType")
        :Column("Column.DefaultCustom" ,"Column_DefaultCustom")
        :Column("Column.fk_Enumeration","pk_Enumeration")
        if l_lIncludeDescription
            :Column("Column.Description" ,"Column_Description")
        endif
        :Column("Column.UsedAs"        ,"Column_UsedAs")
        :Column("Column.UsedBy"        ,"Column_UsedBy")
        :Column("Column.OnDelete"      ,"Column_OnDelete")
        :Column("Enumeration.Name"           ,"Enumeration_Name")
        :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
        :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")

        :Column("ParentNamespace.Name","ParentNamespace_Name")
        :Column("ParentTable.Name"    ,"ParentTable_Name")
        
        :Column("Column.ForeignKeyOptional","Column_ForeignKeyOptional")

        :Where("Namespace.UseStatus <= ^",USESTATUS_TOBEDISCONTINUED)
        :Where("Table.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)
        :Where("Column.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        :Where("Column.UsedBy = ^ OR Column.UsedBy = ^",USEDBY_ALLSERVERS,l_nUsedBy)
        :SQL("ListOfColumns")
        if :Tally < 0
            l_lContinue := .f.
        else
            with object :p_oCursor
                :Index("tag1","strtran(str(Table_pk,10)+str(Column_Order,10),' ','0')")   // Fixed length of the numbers with leading '0'
                :CreateIndexes()
            endwith
// ExportTableToHtmlFile("ListOfColumns",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfColumns_ForHarbourToORM.html","From PostgreSQL",,200,.t.)
        endif
    endwith
endif

if l_lContinue
    with object l_oDB_ListOfEnumerations
        :Table("e83505ef-d915-40e9-b3f3-a98aed191676","Namespace")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")  //Will still join on EnumValue to ensure we only export enumerations with at least one active value.
        :Column("Enumeration.Pk"             ,"Enumeration_Pk")
        :Column("Namespace.Name"             ,"Namespace_Name")
        :Column("Enumeration.Name"           ,"Enumeration_Name")
        :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
        :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")
        :Column("upper(Namespace.Name)"      ,"tag1")
        :Column("upper(Enumeration.Name)"    ,"tag2")
        // :Column("EnumValue.Name"       ,"EnumValue_Name")
        // :Column("EnumValue.Order"      ,"EnumValue_Order")
        // :Column("EnumValue.Number"     ,"EnumValue_Number")
        :Where("Namespace.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        :Where("Enumeration.UseStatus <= ^" ,USESTATUS_TOBEDISCONTINUED)
        :Where("EnumValue.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        :OrderBy("tag1")
        :OrderBy("tag2")
        :Distinct(.t.)
        // :OrderBy("EnumValue_Order")
        :SQL("ListOfEnumerations")
        l_nNumberOfEnumerations := :Tally
        if l_nNumberOfEnumerations < 0
            l_lContinue := .f.
        endif
    endwith
endif

if l_lContinue
    with object l_oDB_ListOfEnumValues
        :Table("299a129d-dab1-4dad-0001-000000000003","Namespace")
        :Where("Namespace.fk_Application = ^",par_iApplicationPk)
        :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
        :Join("inner","EnumValue","","EnumValue.fk_Enumeration = Enumeration.pk")
        :Column("Enumeration.Pk"       ,"Enumeration_Pk")
        :Column("EnumValue.Name"       ,"EnumValue_Name")
        :Column("EnumValue.Order"      ,"EnumValue_Order")
        :Column("EnumValue.Number"     ,"EnumValue_Number")
        :Column("EnumValue.UseStatus"  ,"EnumValue_UseStatus")
        :Column("EnumValue.Description","EnumValue_Description")

        :Where("Namespace.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        :Where("Enumeration.UseStatus <= ^" ,USESTATUS_TOBEDISCONTINUED)
        :Where("EnumValue.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        :OrderBy("Enumeration_Pk")
        :OrderBy("EnumValue_Order")
        :SQL("ListOfEnumValues")
        if :Tally < 0
            l_lContinue := .f.
        else
            with object :p_oCursor
                :Index("tag1","strtran(str(Enumeration_Pk,10)+str(EnumValue_Order,10),' ','0')")   // Fixed length of the numbers with leading '0'
                :CreateIndexes()
            endwith
        endif
    endwith
endif


if l_lContinue

    if l_lAddForeignKeyIndexORMExport
        // Automatically add indexes on Foreign Keys

        l_oDB_ListOfIndexes_OnForeignKey := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB_ListOfIndexes_Defined      := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB_ListOfIndexes              := hb_SQLCompoundQuery(oFcgi:p_o_SQLConnection)

        with object l_oDB_ListOfIndexes_Defined
            :Table("c5450b4d-8d2a-418e-8d56-75ac97d57ceb","Namespace")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Join("inner","Table"      ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Index"      ,"","Index.fk_Table = Table.pk")
            //Future Use        :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
            //Future Use        :Join("inner","Column"     ,"","IndexColumn.fk_Column = Column.pk")

            :Column("Table.Pk"         ,"Table_Pk")
            :Column("Index.Name"       ,"Index_Name")
            :Column("Index.Expression" ,"Index_Expression")
            :Column("Index.Unique"     ,"Index_Unique")
            :Column("Index.Algo"       ,"Index_Algo")

            :Where("Namespace.UseStatus <= ^",USESTATUS_TOBEDISCONTINUED)
            :Where("Table.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)
            :Where("Index.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)

            :Where("Index.UsedBy = ^ OR Index.UsedBy = ^",USEDBY_ALLSERVERS,l_nUsedBy)

            //Future Use        :Where("Column.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        endwith

        with object l_oDB_ListOfIndexes_OnForeignKey
            :Table("90dd4f9c-8910-4cd7-913d-dacff9f5c115","Column")

            :Column("Table.Pk"           ,"Table_Pk")
            :Column("lower(Column.Name)" ,"Index_Name")
            :Column("Column.Name"        ,"Index_Expression")
            :Column("false"              ,"Index_Unique")
            :Column("1"                  ,"Index_Algo")

            :Join("inner","Table","","Column.fk_Table = Table.pk")
            :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            // :Where("Column.fk_TableForeign IS NOT NULL")             // Only needing the foreign key fields.
            :Where("Column.fk_TableForeign > 0")             // Only needing the foreign key fields.
            :Where("Column.UsedBy = ^ OR Column.UsedBy = ^",USEDBY_ALLSERVERS,l_nUsedBy)

            :Where("Namespace.UseStatus <= ^",USESTATUS_TOBEDISCONTINUED)
            :Where("Table.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)
            :Where("Column.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)
        endwith

        with object l_oDB_ListOfIndexes
            :AnchorAlias("26cfaf58-cc3a-4456-a707-2379863acdf8","CombinedListOfIndexes")
            :AddSQLDataQuery("ListOfIndexesDefined"                  ,l_oDB_ListOfIndexes_Defined)
            :AddSQLDataQuery("AllTableColumnsChildrenForForeignKeys" ,l_oDB_ListOfIndexes_OnForeignKey)
            :CombineQueries(COMBINE_ACTION_UNION,"CombinedListOfIndexes",.t.,"ListOfIndexesDefined","AllTableColumnsChildrenForForeignKeys")
            :SQL("ListOfIndexes")

            // SendToClipboard(:LastSQL())

            if :Tally < 0
                l_lContinue := .f.
            else
            // ExportTableToHtmlFile("ListOfIndexes",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfIndexes.html","From PostgreSQL",,200,.t.)
                with object :p_oCursor
                    :Index("tag1","padr(strtran(str(Table_pk,10),' ','0')+Index_Name,240)")   // Fixed length of the number with leading '0'
                    :CreateIndexes()
                endwith
            endif
        endwith

    else
        //Only create index defined in the data dictionary.

        l_oDB_ListOfIndexes := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB_ListOfIndexes
            :Table("18a48ce3-6117-4a35-808c-5782a3038e36","Namespace")
            :Where("Namespace.fk_Application = ^",par_iApplicationPk)
            :Join("inner","Table"      ,"","Table.fk_Namespace = Namespace.pk")
            :Join("inner","Index"      ,"","Index.fk_Table = Table.pk")
            //Future Use        :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
            //Future Use        :Join("inner","Column"     ,"","IndexColumn.fk_Column = Column.pk")

            :Column("Table.Pk"         ,"Table_Pk")
            :Column("Index.Name"       ,"Index_Name")
            :Column("Index.Expression" ,"Index_Expression")
            :Column("Index.Unique"     ,"Index_Unique")
            :Column("Index.Algo"       ,"Index_Algo")

            :Where("Namespace.UseStatus <= ^",USESTATUS_TOBEDISCONTINUED)
            :Where("Table.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)
            :Where("Index.UseStatus <= ^"    ,USESTATUS_TOBEDISCONTINUED)

            :Where("Index.UsedBy = ^ OR Index.UsedBy = ^",USEDBY_ALLSERVERS,l_nUsedBy)
            
            //Future Use        :Where("Column.UseStatus <= ^"   ,USESTATUS_TOBEDISCONTINUED)

            :SQL("ListOfIndexes")
            // SendToClipboard(:LastSQL())

            if :Tally < 0
                l_lContinue := .f.
            else
            // ExportTableToHtmlFile("ListOfIndexes",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfIndexes.html","From PostgreSQL",,200,.t.)
                with object :p_oCursor
                    :Index("tag1","padr(strtran(str(Table_pk,10),' ','0')+Index_Name,240)")   // Fixed length of the number with leading '0'
                    :CreateIndexes()
                endwith
            endif

        endwith

    endif
endif

if l_lContinue
    if par_nVersion == 3
        l_cSchemaIndent := space(4)
        l_cSourceCode := [{"HarbourORMVersion"=>]+HB_ORM_BUILDVERSION+[,;]+CRLF
        l_cSourceCode += [ "DataWharfVersion"=>]+BUILDVERSION+[,;]+CRLF
        l_cSourceCode += [ "Backend"=>"]+par_cBackend+[",;]+CRLF
        l_cSourceCode += [ "GenerationTime"=>"]+strtran(hb_TSToStr(hb_TSToUTC(hb_DateTime()))," ","T")+"Z"+[",;]+CRLF
        l_cSourceCode += [ "GenerationSignature"=>"]+oFcgi:p_o_SQLConnection:GetUUIDString()+["]
    else
        l_cSchemaIndent := ""
    endif
    
    if l_nNumberOfTables > 0
        if par_nVersion == 3
            l_cSourceCode += [,;]+CRLF
            l_cSourceCode += [ "Tables"=>;]+CRLF
        else
            // l_cSourceCode += [{]+CRLF
        endif

        select ListOfTables
        scan all
            l_nTableCounter++
            l_iTablePk := ListOfTables->Table_Pk

            l_cNamespaceAndTableName := alltrim(ListOfTables->Namespace_Name)+"."+alltrim(ListOfTables->Table_Name)
//l_cNamespaceAndTableName := el_StringFilterCharacters(l_cNamespaceAndTableName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.")

            if par_nVersion >= 2
                l_cIndentHashElement := space(len([{"]+l_cNamespaceAndTableName+["=>]))
            endif

            l_cSourceCode += l_cSchemaIndent+iif(l_nTableCounter==1,"{",",")  // Start the next table hash element
            
            //Get Field Definitions
            l_cSourceCodeFields := ""
            l_nNumberOfFields   := 0

            l_nMaxNameLength := ListOfTables->MaxColumnNameLength

            if el_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfColumns","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
                //At lease one field could exists
                l_cFieldDescription := ""
                select ListOfColumns
                scan while ListOfColumns->Table_Pk = l_iTablePk
                    l_nNumberOfFields++

                    l_nFieldUsedAs      := ListOfColumns->Column_UsedAs
                    l_cFieldUsedBy      := ListOfColumns->Column_UsedBy
                    l_cFieldName        := ListOfColumns->Column_Name
// l_cFieldName := el_StringFilterCharacters(l_cFieldName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

                    l_cSourceCodeFields += iif(empty(l_cSourceCodeFields) , CRLF+l_cSchemaIndent+l_cIndent+"{" , ";"+l_cFieldDescription+CRLF+l_cSchemaIndent+l_cIndent+"," )
                
                    l_cFieldType            := alltrim(ListOfColumns->Column_Type)
                    l_cFieldTypeEnumName := ""
                    l_nFieldLen             := nvl(ListOfColumns->Column_Length,0)
                    l_nFieldDec             := nvl(ListOfColumns->Column_Scale,0)
                    // l_nFieldDefaultType   := ListOfColumns->Column_DefaultType
                    // l_cFieldDefaultCustom := ListOfColumns->Column_DefaultCustom
                    l_cFieldDefault         := GetColumnDefault(.t.,ListOfColumns->Column_Type,ListOfColumns->Column_DefaultType,ListOfColumns->Column_DefaultCustom)
                    l_lFieldNullable        := ListOfColumns->Column_Nullable
                    l_lFieldAutoIncrement   := (l_nFieldUsedAs = 2)
                    l_lFieldArray           := ListOfColumns->Column_Array
                    l_cFieldAttributes      := iif(l_lFieldNullable,"N","")+iif(l_lFieldAutoIncrement,"+","")+iif(l_lFieldArray,"A","")

                    l_cFieldDescription := ""
                    if l_lIncludeDescription
                        l_iEnumerationPk := nvl(ListOfColumns->pk_Enumeration,0)
                        if l_iEnumerationPk > 0
                            if el_seek(strtran(str(l_iEnumerationPk,10),' ','0'),"ListOfEnumValues","tag1")
                                select ListOfEnumValues
                                scan while ListOfEnumValues->Enumeration_Pk == l_iEnumerationPk
                                    if !empty(l_cFieldDescription)
                                        l_cFieldDescription += [, ]
                                    endif
                                    l_cFieldDescription += trans(nvl(ListOfEnumValues->EnumValue_Number,0))+[="]+alltrim(ListOfEnumValues->EnumValue_Name)+["]
                                endscan
                            endif
                        endif
                        if !empty(l_cFieldDescription)
                            l_cFieldDescription += space(3)
                        endif
                        l_cFieldDescription += hb_StrReplace(nvl(ListOfColumns->Column_Description,""),{chr(10)=>[],chr(13)=>[ ]})
                        if !empty(l_cFieldDescription)
                            l_cFieldDescription := space(3)+[/]+[/]+l_cFieldDescription
                        endif
                    endif
                    // if lower(l_cFieldName) == lower(::p_PrimaryKeyFieldName)
                    //     l_lFieldAutoIncrement := .t.
                    // endif

                    //Overwrite Enumeration field type when the are not "NativeSQLEnum"
                    if l_cFieldType == "E"
                        lnEnumerationImplementAs     := nvl(ListOfColumns->Enumeration_ImplementAs,0)
                        lnEnumerationImplementLength := nvl(ListOfColumns->Enumeration_ImplementLength,0)

                        // EnumerationImplementAs   1 = Native SQL Enum, 2 = Integer, 3 = Numeric, 4 = Var Char (EnumValue Name)
                        do case
                        case lnEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NATIVESQLENUM
//_M_ Drop the field unless we are migrating inside Postgresql
                            l_cFieldType := "E"  
                            l_nFieldLen  := nil
                            l_nFieldDec  := nil
                            l_cFieldTypeEnumName := nvl(ListOfColumns->Enumeration_Name,"")

                        case lnEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_INTEGER
                            l_cFieldType := "I"
                            l_nFieldLen  := nil
                            l_nFieldDec  := nil
                        case lnEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_NUMERIC
                            l_cFieldType := "N"
                            l_nFieldLen  := lnEnumerationImplementLength
                            l_nFieldDec  := 0
                        case lnEnumerationImplementAs == ENUMERATIONIMPLEMENTAS_VARCHAR
                            l_cFieldType := "CV"
                            l_nFieldLen  := lnEnumerationImplementLength
                            l_nFieldDec  := 0
                        endcase
                    endif

                    if l_lFieldAutoIncrement .and. empty(el_InlistPos(l_cFieldType,"I","IB","IS"))  //Only those fields types may be flagged as Auto-Increment
                        l_lFieldAutoIncrement := .f.
                    endif
                    if l_lFieldAutoIncrement .and. l_lFieldNullable  //Auto-Increment fields may not be null (and not have a default)
                        l_lFieldNullable := .f.
                    endif

                    l_cSourceCodeFields += padr('"'+l_cFieldName+'"',l_nMaxNameLength+2)+"=>{"
                    if par_nVersion == 3
                        // do case
                        // case l_cFieldUsedBy == USEDBY_MYSQLONLY
                        //     l_cSourceCodeFields += '"BackendType"=>"MySQL",'
                        // case l_cFieldUsedBy == USEDBY_POSTGRESQLONLY
                        //     l_cSourceCodeFields += '"BackendType"=>"PostgreSQL",'
                        // endcase

// hb_orm_SendToDebugView(l_cSourceCodeFields)
// hb_orm_SendToDebugView('"'+HB_ORM_SCHEMA_FIELD_TYPE+'"=>"'+l_cFieldType+'"')

                        if el_IsInlist(l_nFieldUsedAs,2,3,4)
                            l_cSourceCodeFields += '"'+HB_ORM_SCHEMA_FIELD_USEDAS+'"=>"'+{"","Primary","Foreign","Support"}[l_nFieldUsedAs]+'"'
                            if l_nFieldUsedAs == 3  // Foreign
                                if !hb_orm_isnull("ListOfColumns","ParentNamespace_Name") .and. !hb_orm_isnull("ListOfColumns","ParentTable_Name")
                                    l_cSourceCodeFields += ',"ParentTable"=>"'+ListOfColumns->ParentNamespace_Name+"."+ListOfColumns->ParentTable_Name+'"'
                                endif
                                if ListOfColumns->Column_ForeignKeyOptional
                                    l_cSourceCodeFields += ',"ForeignKeyOptional"=>.t.'
                                endif
                            endif
                            l_cSourceCodeFields += ','
                        endif
                        l_cSourceCodeFields += '"'+HB_ORM_SCHEMA_FIELD_TYPE+'"=>"'+l_cFieldType+'"'
                        if !empty(l_cFieldTypeEnumName)
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_ENUMNAME+'"=>"'+l_cFieldTypeEnumName+'"'
                        endif
                        if nvl(l_nFieldLen,0) > 0
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_LENGTH+'"=>'+trans(nvl(l_nFieldLen,0))
                        endif
                        if nvl(l_nFieldDec,0) > 0
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_DECIMALS+'"=>'+trans(nvl(l_nFieldDec,0))
                        endif
                        if !empty(l_cFieldDefault)
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_DEFAULT+'"=>"'+strtran(l_cFieldDefault,["],["+'"'+"])+'"'
                        endif
                        if l_lFieldNullable
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_NULLABLE+'"=>.t.'
                        endif
                        if l_lFieldAutoIncrement
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_AUTOINCREMENT+'"=>.t.'
                        endif
                        if l_lFieldArray
                            l_cSourceCodeFields += ',"'+HB_ORM_SCHEMA_FIELD_ARRAY+'"=>.t.'
                        endif
                        if el_IsInlist(ListOfColumns->Column_OnDelete,2,3,4)
                            l_cSourceCodeFields += ',"OnDelete"=>"'+{"","Protect","Cascade","BreakLink"}[ListOfColumns->Column_OnDelete]+'"'
                        endif

//_M_ What about Unicode and other field attributes?
                    else
                        l_cSourceCodeFields += ","  // Null Value for the HB_ORM_SCHEMA_INDEX_BACKEND_TYPES 
                        l_cSourceCodeFields += padl('"'+l_cFieldType+'"',5)+","+;
                                            str(nvl(l_nFieldLen,0),4)+","+;
                                            str(nvl(l_nFieldDec,0),3)+","+;
                                            iif(empty(l_cFieldAttributes),"",'"'+l_cFieldAttributes+'"')
                        if !empty(l_cFieldDefault)
                            l_cSourceCodeFields += ',"'+strtran(l_cFieldDefault,["],["+'"'+"])+'"'
                        endif
                    endif
                    l_cSourceCodeFields += "}"

                endscan

            endif
            if l_nNumberOfFields == 0
                l_cSourceCodeFields := "NIL"
            else
                l_cSourceCodeFields += "}"
            endif

            //Get Index Definitions
            l_cSourceCodeIndexes := ""
            l_nNumberOfIndexes   := 0

            if el_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfIndexes","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
                l_nMaxNameLength       := 0
                l_nMaxExpressionLength := 0

                select ListOfIndexes
                l_nIndexRecno := Recno()
                scan while ListOfIndexes->Table_Pk = l_iTablePk  // Pre scan the index to help determine the l_nMaxNameLength

                    l_cIndexName := ListOfIndexes->Index_Name
// l_cIndexName := el_StringFilterCharacters(l_cIndexName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    // Clean up index name
                    if right(l_cIndexName,4) == "_idx"
                        l_cIndexName := left(l_cIndexName,len(l_cIndexName)-4)
                        l_cIndexPrefix     := lower(strtran(l_cNamespaceAndTableName,".","_"))+"_"
                        if left(l_cIndexName,len(l_cIndexPrefix)) == l_cIndexPrefix
                            l_cIndexName := substr(l_cIndexName,len(l_cIndexPrefix)+1)
                        endif
                    endif
                    l_nMaxNameLength := max(l_nMaxNameLength,len(l_cIndexName))

                    l_cIndexExpression     := ListOfIndexes->Index_Expression
                    l_cIndexExpression     := strtran(l_cIndexExpression,["],[]) // remove PostgreSQL token delimiter. Will be added as needed when creating indexes.
                    l_cIndexExpression     := strtran(l_cIndexExpression,['],[]) // remove MySQL token delimiter. Will be added as needed when creating indexes.

                    l_nMaxExpressionLength := max(l_nMaxExpressionLength,len(l_cIndexExpression))
                endscan
                dbGoTo(l_nIndexRecno)

                scan while ListOfIndexes->Table_Pk = l_iTablePk
                    l_nNumberOfIndexes++

                    l_cIndexName := ListOfIndexes->Index_Name
// l_cIndexName := el_StringFilterCharacters(l_cIndexName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    // Clean up index name
                    if right(l_cIndexName,4) == "_idx"
                        l_cIndexName := left(l_cIndexName,len(l_cIndexName)-4)
                        l_cIndexPrefix     := lower(strtran(l_cNamespaceAndTableName,".","_"))+"_"
                        if left(l_cIndexName,len(l_cIndexPrefix)) == l_cIndexPrefix
                            l_cIndexName := substr(l_cIndexName,len(l_cIndexPrefix)+1)
                        endif
                    endif

                    l_cIndexExpression := ListOfIndexes->Index_Expression
                    l_cIndexExpression := strtran(l_cIndexExpression,["],[]) // remove PostgreSQL token delimiter. Will be added as needed when creating indexes.
                    l_cIndexExpression := strtran(l_cIndexExpression,['],[]) // remove MySQL token delimiter. Will be added as needed when creating indexes.
// l_cIndexExpression := el_StringFilterCharacters(l_cIndexExpression,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-+ ()")
                    
                    l_cSourceCodeIndexes += iif(empty(l_cSourceCodeIndexes) , l_cSchemaIndent+l_cIndent+"{" , ";"+CRLF+l_cSchemaIndent+l_cIndent+",")

                    l_cSourceCodeIndexes += padr('"'+l_cIndexName+'"',l_nMaxNameLength+2)+"=>{"


                    if par_nVersion <= 2
                        l_cSourceCodeIndexes += "," // HB_ORM_SCHEMA_FIELD_BACKEND_TYPES
                        l_cSourceCodeIndexes += '"'+l_cIndexExpression+'"'+space(l_nMaxExpressionLength-len(l_cIndexExpression))+','+;
                                            iif(ListOfIndexes->Index_Unique,".t.",".f.")+","+;
                                            '"'+"BTREE"+'"'    //Later make this aware of ListOfIndexes->Index_Algo
                    else
                        l_cSourceCodeIndexes += '"'+HB_ORM_SCHEMA_INDEX_EXPRESSION+'"=>"'+l_cIndexExpression+'"'
                        if ListOfIndexes->Index_Unique
                            l_cSourceCodeIndexes += ',"'+HB_ORM_SCHEMA_INDEX_UNIQUE+'"=>.t.'
                        endif
                    endif
                    
                    l_cSourceCodeIndexes += "}"

                endscan

            endif
            if l_nNumberOfIndexes == 0
                l_cSourceCodeIndexes := l_cIndent+"NIL"
            else
                l_cSourceCodeIndexes += "}"
            endif

            do case
            case par_nVersion == 1
                l_cSourceCode += '"'+l_cNamespaceAndTableName+'"'+"=>{;   /"+"/Field Definition"
                l_cSourceCode += l_cSourceCodeFields+";"+l_cFieldDescription+CRLF+l_cIndent+",;   /"+"/Index Definition"+CRLF
                l_cSourceCode += l_cSourceCodeIndexes+"};"+CRLF

            case par_nVersion == 2
                l_cSourceCode += '"'+l_cNamespaceAndTableName+'"=>{"Fields"=>;'
                if l_cSourceCodeIndexes == l_cIndent+"NIL"
                    l_cSourceCode += l_cSourceCodeFields+";"+l_cFieldDescription+CRLF+l_cIndentHashElement+',"Indexes"=>NIL'+iif(ListOfTables->Table_Unlogged,[,"Unlogged"=>.T.],[])
                else
                    l_cSourceCode += l_cSourceCodeFields+";"+l_cFieldDescription+CRLF+l_cIndentHashElement+',"Indexes"=>;'+CRLF
                    l_cSourceCode += l_cSourceCodeIndexes
                    l_cSourceCode += iif(ListOfTables->Table_Unlogged,[;]+CRLF+l_cIndentHashElement+[,"Unlogged"=>.T.],[])
                endif
                l_cSourceCode += '};'+CRLF
                
            case par_nVersion == 3
                l_cSourceCode += '"'+l_cNamespaceAndTableName+'"=>{"Fields"=>;'
                if l_cSourceCodeIndexes == l_cIndent+"NIL"
                    l_cSourceCode += l_cSourceCodeFields+";"+l_cFieldDescription+CRLF+l_cSchemaIndent+l_cIndentHashElement+iif(ListOfTables->Table_Unlogged,[,"Unlogged"=>.T.],[])
                else
                    l_cSourceCode += l_cSourceCodeFields+";"+l_cFieldDescription+CRLF+l_cSchemaIndent+l_cIndentHashElement+',"Indexes"=>;'+CRLF
                    l_cSourceCode += l_cSourceCodeIndexes
                    l_cSourceCode += iif(ListOfTables->Table_Unlogged,[;]+CRLF+l_cSchemaIndent+l_cIndentHashElement+[,"Unlogged"=>.T.],[])
                endif
                l_cSourceCode += '};'+CRLF
                
            endcase

        endscan
        if par_nVersion == 3
            l_cSourceCode += l_cSchemaIndent+"}"+iif(l_nNumberOfEnumerations > 0,",","")+";"+CRLF
        endif
    endif

    if l_nNumberOfEnumerations > 0 .and. par_nVersion >= 3
        l_cSourceCode += ["Enumerations"=>;]+CRLF

        select ListOfEnumerations
        scan all
            l_nEnumerationCounter++
            l_iEnumerationPk := ListOfEnumerations->Enumeration_Pk

            l_cNamespaceAndEnumerationName := alltrim(ListOfEnumerations->Namespace_Name)+"."+alltrim(ListOfEnumerations->Enumeration_Name)
// l_cNamespaceAndEnumerationName := el_StringFilterCharacters(l_cNamespaceAndEnumerationName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.")

            l_cIndentHashElement := space(len([{"]+l_cNamespaceAndEnumerationName+["=>]))

            l_cSourceCode += l_cSchemaIndent+iif(l_nEnumerationCounter==1,"{",",")  // Start the next enumeration hash element
            
            //Get EnumValues Definitions
            l_cSourceCodeEnumValues := ""
            l_nNumberOfEnumValues   := 0

            if el_seek(strtran(str(l_iEnumerationPk,10),' ','0'),"ListOfEnumValues","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
                l_nMaxNameLength       := 0

                select ListOfEnumValues
                l_nEnumValueRecno := Recno()
                scan while ListOfEnumValues->Enumeration_Pk = l_iEnumerationPk  // Pre scan the enumvalues to help determine the l_nMaxNameLength
                    l_cEnumValueName := ListOfEnumValues->EnumValue_Name
// l_cEnumValueName := el_StringFilterCharacters(l_cEnumValueName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    l_nMaxNameLength := max(l_nMaxNameLength,len(l_cEnumValueName))
                endscan
                dbGoTo(l_nEnumValueRecno)

                scan while ListOfEnumValues->Enumeration_Pk = l_iEnumerationPk
                    l_nNumberOfEnumValues++

                    l_cEnumValueName := ListOfEnumValues->EnumValue_Name
// l_cEnumValueName := el_StringFilterCharacters(l_cEnumValueName,"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    
                    l_nEnumValue_Order     := ListOfEnumValues->EnumValue_Order
                    l_nEnumValue_Number    := ListOfEnumValues->EnumValue_Number
                    
                    l_cSourceCodeEnumValues += iif(empty(l_cSourceCodeEnumValues) , l_cSchemaIndent+l_cIndent+l_cIndent+"{" , ";"+CRLF+l_cSchemaIndent+l_cIndent+l_cIndent+",")

                    l_cSourceCodeEnumValues += padr('"'+l_cEnumValueName+'"',l_nMaxNameLength+2)+"=>{"

                    l_cSourceCodeEnumValues += '"Order"=>'+Trans(l_nEnumValue_Order)
                    if !hb_IsNil(l_nEnumValue_Number)
                        l_cSourceCodeEnumValues += ',"Number"=>'+Trans(l_nEnumValue_Number)
                    endif
                    
                    l_cSourceCodeEnumValues += "}"

                endscan

            endif

            l_cSourceCode += '"'+l_cNamespaceAndEnumerationName+'"=>{;'+CRLF

            if el_between(ListOfEnumerations->Enumeration_ImplementAs,1,4)
                l_cImplementAs := {"NativeSQLEnum","Integer","Numeric","VarChar"}[ListOfEnumerations->Enumeration_ImplementAs]
                l_cSourceCode += l_cSchemaIndent+l_cIndent+'"ImplementAs"=>"'+l_cImplementAs+'",;'+CRLF
            endif

            if nvl(ListOfEnumerations->Enumeration_ImplementLength,0) > 0
                l_cSourceCode += l_cSchemaIndent+l_cIndent+'"ImplementLength"=>'+Trans(ListOfEnumerations->Enumeration_ImplementLength)+',;'+CRLF
            endif

            l_cSourceCode += l_cSchemaIndent+l_cIndent+'"Values"=>;'+CRLF

            l_cSourceCode += l_cSourceCodeEnumValues

            l_cSourceCode += '}};'+CRLF

        endscan
        l_cSourceCode += l_cSchemaIndent+"};"+CRLF
    endif

    l_cSourceCode += [}]
endif

if !l_lContinue
    l_cSourceCode += [/]+[/ error]
endif

oFcgi:p_o_SQLConnection:SetForeignKeyNullAndZeroParity(.t.)

return l_cSourceCode
//=================================================================================================================
//=================================================================================================================
function ExportApplicationForImports(par_iApplicationPk)
local l_cBackupCode := ""

local l_lContinue := .t.
local l_oDB_ListOfRecords    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_hTableSchema         := oFcgi:p_o_SQLConnection:p_WharfConfig["Tables"]

local l_oDB_ListOfFileStream := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_FileStream       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ApplicationInfo  := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cFilePathPID
local l_cFilePathUser
local l_iKey
local l_cLinkUID
local l_cFileName
local l_oInfo

oFcgi:p_o_SQLConnection:SetForeignKeyNullAndZeroParity(.f.)  //To ensure we keep the null values

hb_HCaseMatch(l_hTableSchema,.f.)  // Case Insensitive search

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000004","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Namespace")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Namespace","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000005","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table" ,"","Table.fk_Namespace = Namespace.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Table")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Table","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000006","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"  ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column" ,"","Column.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Column")
    :OrderBy("pk")
    :SQL("ListOfRecords")
// SendToClipboard(:LastSQL())
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Column","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000007","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Enumeration" ,"","Enumeration.fk_Namespace = Namespace.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Enumeration")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Enumeration","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000008","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Enumeration"  ,"","Enumeration.fk_Namespace = Namespace.pk")
    :Join("inner","EnumValue" ,"","EnumValue.fk_Enumeration = Enumeration.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"EnumValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"EnumValue","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000009","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"  ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index" ,"","Index.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Index")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Index","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000010","Namespace")
    :Where("Namespace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"       ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index"       ,"","Index.fk_Table = Table.pk")
    :Join("inner","IndexColumn" ,"","IndexColumn.fk_Index = Index.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"IndexColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"IndexColumn","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000011","Diagram")
    :Where("Diagram.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Diagram")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Diagram","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000012","Diagram")
    :Where("Diagram.fk_Application = ^",par_iApplicationPk)
    :Join("inner","DiagramTable" ,"","DiagramTable.fk_Diagram = Diagram.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"DiagramTable")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"DiagramTable","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000013","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Tag")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Tag","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000014","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Join("inner","TagTable" ,"","TagTable.fk_Tag = Tag.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"TagTable")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"TagTable","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000015","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Join("inner","TagColumn" ,"","TagColumn.fk_Tag = Tag.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"TagColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"TagColumn","ListOfRecords")
    endif
endwith


with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000016","TemplateTable")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"TemplateTable")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"TemplateTable","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000017","TemplateTable")
    :Where("TemplateTable.fk_Application = ^",par_iApplicationPk)
    :Join("inner","TemplateColumn" ,"","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"TemplateColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"TemplateColumn","ListOfRecords")
    endif
endwith

// ----- Custom Field Begin ------------------------------------------------------
with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000018","ApplicationCustomField")
    :Distinct(.t.)
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
    :Join("inner","CustomField" ,"","ApplicationCustomField.fk_CustomField = CustomField.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"CustomField")

    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"CustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000019","ApplicationCustomField")
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)

    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ApplicationCustomField")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ApplicationCustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0001-000000000020","ApplicationCustomField")
    :Distinct(.t.)
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
    :Join("inner","CustomFieldValue" ,"","CustomFieldValue.fk_CustomField = ApplicationCustomField.fk_CustomField")

    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"CustomFieldValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"CustomFieldValue","ListOfRecords")
    endif
endwith
// ----- Custom Field End ------------------------------------------------------
oFcgi:p_o_SQLConnection:SetForeignKeyNullAndZeroParity(.t.)

if l_lContinue
    l_cBackupCode += CRLF

    l_cFilePathPID := GetStreamFileFolderForCurrentProcess()

    el_StrToFile(l_cBackupCode,l_cFilePathPID+"Export.txt")

    hb_ZipFile(l_cFilePathPID+"Export.zip",l_cFilePathPID+"Export.txt",9,,.t.)
    DeleteFile(l_cFilePathPID+"Export.txt")

    with object l_oDB_ApplicationInfo
        :Table("f639a7b0-41da-4b49-b812-9db23bc52f9e","Application")
        :Column("Application.Name","Application_Name")
        l_oInfo := :Get(par_iApplicationPk)
    endwith

    //_M_ Add a Sanitizing function for l_oInfo:Application_Name
    l_cFileName := "ExportDataDictionary_"+strtran(l_oInfo:Application_Name," ","_")+"_"+GetZuluTimeStampForFileNameSuffix()+".zip"

    //Try to find if we already have a streamfile
    with object l_oDB_ListOfFileStream
        :Table("2abb88ca-7317-484b-8fbf-df596fd15403","volatile.FileStream","FileStream")
        :Column("FileStream.pk"     ,"pk")
        :Column("FileStream.LinkUID","LinkUID")
        :Where("FileStream.fk_User = ^"        , oFCgi:p_iUserPk)
        :Where("FileStream.fk_Application = ^" , par_iApplicationPk)
        :Where("FileStream.type = 1")
        :SQL("ListOfFileStream")
        do case
        case :Tally < 0
            //Error
            l_iKey := 0
        case :Tally == 1
            l_iKey     := ListOfFileStream->pk
            l_cLinkUID := ListOfFileStream->LinkUID
            if !l_oDB_FileStream:SaveFile("456e02d9-c305-4504-a391-7692c51f0ec0","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
                l_cFilePathUser := GetStreamFileFolderForCurrentUser()
                hb_vfMoveFile(l_cFilePathPID+"Export.zip",l_cFilePathUser+"Export"+trans(l_iKey)+".zip")
            endif
            with object l_oDB_FileStream
                :Table("2c5183d2-9aad-4f72-8cfe-f4ad411e6c74","volatile.FileStream","FileStream")
                :Field("FileName" , l_cFileName)
                if :Update(l_iKey)
                endif
            endwith
        otherwise
            if :Tally > 1 //Bad data.
                select ListOfFileStream
                scan all
                    l_oDB_FileStream:Delete("f2e5e618-11b4-4117-b7e9-84b8f8208a91","volatile.FileStream",ListOfFileStream->pk)
                endscan
            endif

            with object l_oDB_FileStream
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Table("197496b6-14c0-42aa-b7af-7b05f7c77187","volatile.FileStream","FileStream")
                :Field("fk_User"        , oFCgi:p_iUserPk)
                :Field("fk_Application" , par_iApplicationPk)
                :Field("type"           , 1)
                :Field("LinkUID"        , l_cLinkUID)
                :Field("FileName"       , l_cFileName)
                if :Add()
                    l_iKey := :Key()
                    if !l_oDB_FileStream:SaveFile("456e02d9-c305-4504-a391-7692c51f0ec1","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
                        l_cFilePathUser := GetStreamFileFolderForCurrentUser()
                        hb_vfMoveFile(l_cFilePathPID+"Export.zip",l_cFilePathUser+"Export"+trans(l_iKey)+".zip")
                    endif
                else
                    l_iKey := 0
                endif
            endwith
        endcase
    endwith
    DeleteFile(l_cFilePathPID+"Export.zip")
else
    l_iKey := 0
endif

if l_iKey == 0
    //Report error
    l_cLinkUID    := ""
    l_cBackupCode := "Export Failed"
endif

return l_cLinkUID
//=================================================================================================================
function DataDictionaryImportStep1FormBuild(par_iApplicationPk,par_cErrorText)

local l_cHtml := ""
local l_cErrorText         := hb_DefaultValue(par_cErrorText,"")

local l_cMessageLine

oFcgi:TraceAdd("DataDictionaryImportStep1FormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Step1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
// l_cHtml += [<input type="hidden" name="ApplicationKey" value="]+trans(par_iApplicationPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

if !empty(par_iApplicationPk)

    l_cHtml += GetAboveNavbarHeading("Import")

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            // l_cHtml += [<span class="navbar-brand ms-3">Import</span>]   //navbar-text
            // l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" value="Delta" onclick="$('#ActionOnSubmit').val('Delta');document.form.submit();" role="button">]
            l_cHtml += [<button type="button" class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmImportModal">Import</button>]

            l_cHtml += GetButtonOnEditFormDoneCancel()
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<table>]

            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Export File</td>]
                l_cHtml += [<td class="pb-3"><input type="file" name="TextExportFile" id="TextExportFile" value="" maxlength="200" size="80" style="width:800px;"></td>]
            l_cHtml += [</tr>]

        l_cHtml += [</table>]

    l_cHtml += [</div>]

    oFcgi:p_cjQueryScript += [$('#TextExportFile').focus();]

    l_cHtml += [</form>]

    l_cHtml += GetConfirmationModalFormsImport()
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function DataDictionaryImportStep1FormOnSubmit(par_iApplicationPk,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_cErrorMessage := ""

local l_cInputFileName
local l_cFilePathPID
local l_iHandleUnzip
local l_xRes
local l_cImportContent

oFcgi:TraceAdd("DataDictionaryImportStep1FormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

do case
case el_IsInlist(l_cActionOnSubmit,"Import")

    l_cInputFileName := oFcgi:GetInputFileName("TextExportFile")
    if empty(l_cInputFileName)
        l_cErrorMessage := [Missing File.]
    else
        // l_cInputFileContentType := oFcgi:GetInputFileContentType("TextExportFile")

        l_cFilePathPID := GetStreamFileFolderForCurrentProcess()
        oFcgi:SaveInputFileContent("TextExportFile",l_cFilePathPID+"Export.zip")

        l_iHandleUnzip := hb_unzipOpen(l_cFilePathPID+"Export.zip")
        if empty(l_iHandleUnzip)
            l_xRes := -1
        else
            l_xRes := hb_unzipFileFirst(l_iHandleUnzip)
            if empty(l_xRes)
                l_xRes := hb_unzipExtractCurrentFile(l_iHandleUnzip,l_cFilePathPID+"Export.txt")
            endif
            if empty(l_xRes)
                l_xRes := hb_unzipClose( l_iHandleUnzip )
            endif
        endif
        if empty(l_xRes)
            DeleteFile(l_cFilePathPID+"Export.zip")

            l_cImportContent := hb_MemoRead(l_cFilePathPID+"Export.txt")
            DeleteFile(l_cFilePathPID+"Export.txt")

            ImportApplicationFile(par_iApplicationPk,@l_cImportContent)
            DataDictionaryFixAndTest(par_iApplicationPk)

        endif

    endif

case el_IsInlist(l_cActionOnSubmit,"Cancel","Done")
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionaryImport/"+par_cURLApplicationLinkCode+"/")

endcase

if !empty(l_cErrorMessage)
    l_cHtml += DataDictionaryImportStep1FormBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ImportApplicationFile(par_iApplicationPk,par_cImportContent)

local l_aLines
local l_nNumberOfLines
local l_nLineCounter := 0
local l_cLine
local l_nMode := 0   // 1=Building Table, 2=Loading data
local l_cTableName
local l_aListOfCursors := {}
local l_aFieldValues   := {}
local l_oCursor
local l_aFieldStructure
local l_aTableStructure
local l_nNumberOfFields
local l_nFieldCounter
local l_xValue
local l_cCursorFieldType
local l_cCursorFieldLen
local l_cCursorFieldDec

local l_oDB_ListOfCurrentRecords := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDBImport                := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_hNamespacePkOldToNew     := {=>}
local l_hTablePkOldToNew         := {=>}
local l_hColumnPkOldToNew        := {=>}
local l_hEnumerationPkOldToNew   := {=>}
local l_hIndexPkOldToNew         := {=>}
local l_hDiagramPkOldToNew       := {=>}
local l_hTagPkOldToNew           := {=>}
local l_hTemplateTablePkOldToNew := {=>}
local l_hCustomFieldPkOldToNew   := {=>}

local l_iParentKeyCurrent  // In Current database
local l_iParentKeyImport   // In data used for import

local l_ifk_TableForeignImport
local l_ifk_TableForeignCurrent

local l_ifk_ColumImport
local l_ifk_ColumCurrent

local l_ifk_EnumerationImport
local l_ifk_EnumerationCurrent

local l_ifk_ColumnImport
local l_ifk_ColumnCurrent

local l_ifk_TableImport
local l_ifk_TableCurrent

local l_ifk_CustomFieldImport
local l_ifk_CustomFieldCurrent

local l_ifk_EntityImport
local l_ifk_EntityCurrent

local l_cJSONVisPos
local l_cJSONMxgPos

local l_hImportSourceCustomFieldUsedOn := {=>}
local lnUsedOn

local l_cValidNameChars
local l_aColumns

// Parse the file line by line

l_aLines := hb_ATokens(par_cImportContent,.t.,.f.,.f.) 
par_cImportContent := ""  // To regain some memory, since passed by reference.

l_nNumberOfLines := len(l_aLines)

do while l_nLineCounter < l_nNumberOfLines
    l_nLineCounter++
    l_cLine := l_aLines[l_nLineCounter]

    if left(l_cLine,1) == "!"  //Table
        l_nMode := 1
        l_cTableName := substr(l_cLine,2)
        l_oCursor := hb_Cursor()
        AAdd(l_aListOfCursors,l_oCursor)

        l_aTableStructure := {}
        
        l_nNumberOfFields := 0
        l_nLineCounter++
        l_cLine := l_aLines[l_nLineCounter]
        with object l_oCursor
            do while left(l_cLine,1) == "|"
                l_nNumberOfFields++
                l_aFieldStructure = hb_ATokens(l_cLine,"|")

                AAdd(l_aTableStructure,{l_aFieldStructure[2],l_aFieldStructure[3],val(l_aFieldStructure[4]),val(l_aFieldStructure[5]),strtran(l_aFieldStructure[6],"+","")})

                l_cCursorFieldType := l_aFieldStructure[3]
                if el_IsInlist(l_cCursorFieldType,"C","CV","M")
                    l_cCursorFieldType := "M"  //overwrite to ensure will have enough space to store encoded field value
                    l_cCursorFieldLen  := 0
                    l_cCursorFieldDec  := 0
                else
                    l_cCursorFieldLen  := val(l_aFieldStructure[4])
                    l_cCursorFieldDec  := val(l_aFieldStructure[5])
                endif
                :Field(l_aFieldStructure[2],l_cCursorFieldType,l_cCursorFieldLen,l_cCursorFieldDec,strtran(l_aFieldStructure[6],"+",""))

                l_nLineCounter++
                l_cLine := l_aLines[l_nLineCounter]
            enddo
            :CreateCursor("ImportSource"+l_cTableName)

            do while left(l_cLine,1) == "^"
                l_nLineCounter++
                l_aFieldValues = hb_ATokens(l_cLine,"^") 
                :AppendBlank()
                for l_nFieldCounter := 1 to l_nNumberOfFields
                    if l_aFieldValues[l_nFieldCounter+1] == "|"
                        l_xValue := nil
                    else
                        switch l_aTableStructure[l_nFieldCounter,2]
                        case "I"
                        case "N"
                            l_xValue := val(l_aFieldValues[l_nFieldCounter+1])
                            exit
                        case "C"
                        case "CV"
                        case "M"
                             l_xValue := l_aFieldValues[l_nFieldCounter+1]   //Will keep it encoded, since it will be sent to PostgreSQL later.
                             exit
                        case "L"
                            l_xValue := iif(l_aFieldValues[l_nFieldCounter+1] == "T",.t.,.f.)
                            exit
                        case "D"
                            l_xValue := SToD(l_aFieldValues[l_nFieldCounter+1])
                            exit
                        otherwise
                            l_xValue := l_aFieldValues[l_nFieldCounter+1]
                        endswitch
                    endif
                    :SetFieldValue(l_aTableStructure[l_nFieldCounter,1] , l_xValue )
                endfor

                l_cLine := l_aLines[l_nLineCounter]
            enddo
            // ExportTableToHtmlFile("ImportSource"+l_cTableName,OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ImportSource"+l_cTableName+".html","From PostgreSQL",,,.t.)
        endwith

    endif

enddo

//Order of Table Imports
//======================
// Namespace
// Table
// Enumeration
// Column
// EnumValue
// Index
// IndexColumn
// Diagram
// DiagramTable
// Tag
// TagTable
// TagColumn
// Custom Fields

//-------------------------------------------------------------------------------------------------------------------------
// Import Namespaces
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000001","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Column("Namespace.Pk"  ,"pk")
    :Column("Namespace.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceNamespace
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Namespace")
scan all
    if el_seek( upper(strtran(ImportSourceNamespace->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: Namespace Already on file",ListOfCurrentRecords->Name)
        l_hNamespacePkOldToNew[ImportSourceNamespace->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000002","Namespace")
            :Field("fk_Application",par_iApplicationPk)
            ImportAddRecordSetField(l_oDBImport,"Namespace","*fk_Application*",l_aColumns)
            if :Add()
                //Log the old key, new key
                l_hNamespacePkOldToNew[ImportSourceNamespace->pk] := :Key()
            endif
            // el_StrToFile(:LastSQL(),"d:\LastSQL.txt")
            
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Tables
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000003","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
    :Column("Table.fk_Namespace","fk_Namespace")
    :Column("Table.Pk"          ,"pk")
    :Column("Table.Name"        ,"name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Namespace))+'*'+upper(strtran(Name,' ',''))+'*',240)")  // IMPORTANT - Had to Pad the index expression otherwise the searcher would only work on the shortest string. Also could not use trans(), had to use Harbour native functions.
        :CreateIndexes()
    endwith
endwith

// ExportTableToHtmlFile("ListOfCurrentRecords",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfCurrentRecords.html","From PostgreSQL",,,.t.)

select ImportSourceTable
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Table")
scan all
    l_iParentKeyImport  := ImportSourceTable->fk_Namespace
    l_iParentKeyCurrent := hb_HGetDef(l_hNamespacePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Namespace Parent Key on Table Import" ,l_iParentKeyImport)
    else
        //In the index search could not use trans() for some reason it left leading blanks
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceTable->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Table Already on file in Namespace (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hTablePkOldToNew[ImportSourceTable->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000004","Table")
                :Field("fk_Namespace",l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Table","*fk_Namespace*",l_aColumns)
                if :Add()
                    //Log the old key, new key
                    l_hTablePkOldToNew[ImportSourceTable->pk] := :Key()
                endif
                // el_StrToFile(:LastSQL(),"d:\LastSQL.txt")
                
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Enumerations
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000005","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Enumeration","","Enumeration.fk_Namespace = Namespace.pk")
    :Column("Enumeration.fk_Namespace","fk_Namespace")
    :Column("Enumeration.Pk"  ,"pk")
    :Column("Enumeration.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Namespace))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceEnumeration
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Enumeration")
scan all
    l_iParentKeyImport  := ImportSourceEnumeration->fk_Namespace
    l_iParentKeyCurrent := hb_HGetDef(l_hNamespacePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Namespace Parent Key on Enumeration Import" ,l_iParentKeyImport)
    else
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceEnumeration->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Enumeration Already on file in Namespace (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hEnumerationPkOldToNew[ImportSourceEnumeration->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000006","Enumeration")
                :Field("fk_Namespace",l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Enumeration","*fk_Namespace*",l_aColumns)
                if :Add()
                    //Log the old key, new key
                    l_hEnumerationPkOldToNew[ImportSourceEnumeration->pk] := :Key()
                endif
                // el_StrToFile(:LastSQL(),"d:\LastSQL.txt")
                
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Columns

with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000007","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table" ,"" ,"Table.fk_Namespace = Namespace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Column("Column.fk_Table","fk_Table")
    :Column("Column.Pk"      ,"pk")
    :Column("Column.Name"    ,"name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Table))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceColumn
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Column")
scan all
    l_iParentKeyImport  := ImportSourceColumn->fk_Table
    l_iParentKeyCurrent := hb_HGetDef(l_hTablePkOldToNew,l_iParentKeyImport,0)

    l_ifk_TableForeignImport:= ImportSourceColumn->fk_TableForeign
    if hb_IsNil(l_ifk_TableForeignImport) .or. empty(l_ifk_TableForeignImport)
        l_ifk_TableForeignCurrent := 0
    else
        l_ifk_TableForeignCurrent := hb_HGetDef(l_hTablePkOldToNew,l_ifk_TableForeignImport,0)
    endif

    l_ifk_EnumerationImport:= ImportSourceColumn->fk_Enumeration
    if hb_IsNil(l_ifk_EnumerationImport) .or. hb_IsNil(l_ifk_EnumerationImport)
        l_ifk_EnumerationCurrent := 0
    else
        l_ifk_EnumerationCurrent := hb_HGetDef(l_hEnumerationPkOldToNew,l_ifk_EnumerationImport,0)
    endif

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Table Parent Key on Column Import" ,l_iParentKeyImport)
    else
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceColumn->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Column Already on file in Table (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hColumnPkOldToNew[ImportSourceColumn->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000008","Column")
                :Field("fk_Table"       ,l_iParentKeyCurrent)
                :Field("fk_TableForeign",l_ifk_TableForeignCurrent)
                :Field("fk_Enumeration" ,l_ifk_EnumerationCurrent)
                ImportAddRecordSetField(l_oDBImport,"Column","*fk_Table*fk_TableForeign*fk_Enumeration*",l_aColumns)
                if :Add()
                    l_hColumnPkOldToNew[ImportSourceColumn->pk] := :Key()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import EnumValues
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000009","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Enumeration","","Enumeration.fk_Namespace = Namespace.pk")
    :Join("inner","EnumValue"  ,"","EnumValue.fk_Enumeration = Enumeration.pk")
    :Column("EnumValue.fk_Enumeration","fk_Enumeration")
    :Column("EnumValue.Pk"  ,"pk")
    :Column("EnumValue.Name","name")
    :Column( e"upper(regexp_replace(\"enumvalue\".\"Name\", '[^a-zA-Z0-9_]+', '', 'g'))" , "name_for_index" )
    :SQL("ListOfCurrentRecords")
    // SendToClipboard(:LastSQL())
    with object :p_oCursor
    //clipboard
        // :Index("tag1","padr(alltrim(str(fk_Enumeration))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :Index("tag1","padr(alltrim(str(fk_Enumeration))+'*'+name_for_index+'*',240)")
        :CreateIndexes()
    endwith
endwith

l_cValidNameChars := [01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_']

select ImportSourceEnumValue
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.EnumValue")
scan all
    l_iParentKeyImport  := ImportSourceEnumValue->fk_Enumeration
    l_iParentKeyCurrent := hb_HGetDef(l_hEnumerationPkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Enumeration Parent Key on EnumValue Import" ,l_iParentKeyImport)
    else
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(hb_StrReplace(ImportSourceEnumValue->Name,hb_StrReplace(ImportSourceEnumValue->Name,l_cValidNameChars,'') ,''))+'*' ,"ListOfCurrentRecords","tag1")
            SendToDebugView("Import: EnumValue Already on file in Enumeration (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000010","EnumValue")
                :Field("fk_Enumeration"       ,l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"EnumValue","*fk_Enumeration*",l_aColumns)
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Index
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000011","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index","","Index.fk_Table = Table.pk")
    :Column("Index.fk_Table","fk_Table")
    :Column("Index.Pk"  ,"pk")
    :Column("Index.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Table))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceIndex
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Index")
scan all
    l_iParentKeyImport  := ImportSourceIndex->fk_Table
    l_iParentKeyCurrent := hb_HGetDef(l_hTablePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Table Parent Key on Index Import" ,l_iParentKeyImport)
    else
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceIndex->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Index Already on file in Table (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hIndexPkOldToNew[ImportSourceIndex->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000012","Index")
                :Field("fk_Table"       ,l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Index","*fk_Table*",l_aColumns)
                if :Add()
                    l_hIndexPkOldToNew[ImportSourceIndex->pk] := :Key()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import IndexColumn
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000013","Namespace")
    :Where("Namespace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table"      ,"","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Index"      ,"","Index.fk_Table = Table.pk")
    :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
    :Column("IndexColumn.fk_Index" ,"fk_Index")
    :Column("IndexColumn.Pk"       ,"pk")
    :Column("IndexColumn.Fk_Column","Fk_Column")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Index))+'*'+alltrim(str(Fk_Column))+'*',40)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceIndexColumn
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.IndexColumn")
scan all
    l_iParentKeyImport  := ImportSourceIndexColumn->fk_Index
    l_iParentKeyCurrent := hb_HGetDef(l_hIndexPkOldToNew,l_iParentKeyImport,0)

    l_ifk_ColumnImport:= ImportSourceIndexColumn->fk_Column
    if hb_IsNil(l_ifk_ColumnImport) .or. hb_IsNil(l_ifk_ColumnImport)
        l_ifk_ColumnCurrent := 0
    else
        l_ifk_ColumnCurrent := hb_HGetDef(l_hColumnPkOldToNew,l_ifk_ColumnImport,0)
    endif

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Index Parent Key on IndexColumn Import" ,l_iParentKeyImport)
    else
        if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_ColumnCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Column Already on file in Index (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000014","IndexColumn")
                :Field("fk_Index"  ,l_iParentKeyCurrent)
                :Field("fk_Column" ,l_ifk_ColumnCurrent)
                ImportAddRecordSetField(l_oDBImport,"IndexColumn","*fk_Index*fk_Column*",l_aColumns)   // No other field exists but leaving this in case we add some.
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Diagrams
if used("ImportSourceDiagram")   // Should skip this in case this is a Table Import
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000015","Diagram")
        :Where("Diagram.fk_Application = ^" , par_iApplicationPk)
        :Column("Diagram.Pk"    ,"pk")
        :Column("Diagram.Name"  ,"name")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceDiagram
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Diagram")
    scan all
        if el_seek( upper(strtran(ImportSourceDiagram->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Diagram Already on file",ListOfCurrentRecords->Name)
            l_hDiagramPkOldToNew[ImportSourceDiagram->pk] := ListOfCurrentRecords->pk
        else

            //Fix Graph JSON content
            l_cJSONVisPos := ImportSourceDiagram->VisPos
            l_cJSONMxgPos := ImportSourceDiagram->MxgPos

            //Loop on all possible source table, regardless if table is included or not in the diagram. A little brute force, but works.
            for each l_ifk_TableCurrent in l_hTablePkOldToNew
                l_ifk_TableImport := l_ifk_TableCurrent:__enumkey
                
                if !hb_IsNil(l_cJSONVisPos)
                    l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022T"+trans(l_ifk_TableImport)+"\u0022","\u0022T"+trans(l_ifk_TableCurrent)+"\u0022")
                endif
                if !hb_IsNil(l_cJSONMxgPos)
                    l_cJSONMxgPos := strtran(l_cJSONMxgPos,"\u0022T"+trans(l_ifk_TableImport)+"\u0022","\u0022T"+trans(l_ifk_TableCurrent)+"\u0022")
                endif
            endfor


            //Loop on all possible source foreign key columns, regardless if table is included or not in the diagram. A little brute force, but works.
            for each l_ifk_ColumCurrent in l_hColumnPkOldToNew
                l_ifk_ColumImport := l_ifk_ColumCurrent:__enumkey
                
                if !hb_IsNil(l_cJSONVisPos)
                    l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022C"+trans(l_ifk_ColumImport)+"\u0022","\u0022C"+trans(l_ifk_ColumCurrent)+"\u0022")
                endif
                if !hb_IsNil(l_cJSONMxgPos)
                    l_cJSONMxgPos := strtran(l_cJSONMxgPos,"\u0022C"+trans(l_ifk_ColumImport)+"\u0022","\u0022C"+trans(l_ifk_ColumCurrent)+"\u0022")
                endif
            endfor

            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000016","Diagram")
                :Field("fk_Application",par_iApplicationPk)
                if !hb_IsNil(l_cJSONVisPos)
                    :FieldExpression("VisPos","E'"+l_cJSONVisPos+"'")
                endif
                if !hb_IsNil(l_cJSONMxgPos)
                    :FieldExpression("MxgPos","E'"+l_cJSONMxgPos+"'")
                endif
                ImportAddRecordSetField(l_oDBImport,"Diagram","*fk_Application*VisPos*MxgPos*",l_aColumns)
                if :Add()
                    //Log the old key, new key
                    l_hDiagramPkOldToNew[ImportSourceDiagram->pk] := :Key()
                endif
                
            endwith
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import DiagramTable
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000017","Diagram")
        :Where("Diagram.fk_Application = ^" , par_iApplicationPk)
        :Join("inner","DiagramTable","","DiagramTable.fk_Diagram = Diagram.pk")
        :Column("DiagramTable.fk_Diagram" ,"fk_Diagram")
        :Column("DiagramTable.Pk"       ,"pk")
        :Column("DiagramTable.Fk_Table","Fk_Table")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(alltrim(str(fk_Diagram))+'*'+alltrim(str(Fk_Table))+'*',40)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceDiagramTable
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.DiagramTable")
    scan all
        l_iParentKeyImport  := ImportSourceDiagramTable->fk_Diagram
        l_iParentKeyCurrent := hb_HGetDef(l_hDiagramPkOldToNew,l_iParentKeyImport,0)

        l_ifk_TableImport:= ImportSourceDiagramTable->fk_Table
        if hb_IsNil(l_ifk_TableImport) .or. hb_IsNil(l_ifk_TableImport)
            l_ifk_TableCurrent := 0
        else
            l_ifk_TableCurrent := hb_HGetDef(l_hTablePkOldToNew,l_ifk_TableImport,0)
        endif

        if empty(l_iParentKeyCurrent)
            SendToDebugView("Failure to find Diagram Parent Key on DiagramTable Import" ,l_iParentKeyImport)
        else
            if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_TableCurrent))+'*' ,"ListOfCurrentRecords","tag1")
                // SendToDebugView("Import: Table Already on file in Diagram (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            else
                with object l_oDBImport
                    :Table("df873645-94d3-4ba5-85cf-000000000018","DiagramTable")
                    :Field("fk_Diagram",l_iParentKeyCurrent)
                    :Field("fk_Table"  ,l_ifk_TableCurrent)
                    ImportAddRecordSetField(l_oDBImport,"DiagramTable","*fk_Diagram*fk_Table*",l_aColumns)   // No other field exists but leaving this in case we add some.
                    if :Add()
                    endif
                endwith
            endif
        endif
    endscan
endif
//-------------------------------------------------------------------------------------------------------------------------
// Import Tags
if used("ImportSourceTag")   // Should skip this in case this is a Table Import
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000019","Tag")
        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
        :Column("Tag.Pk"    ,"pk")
        :Column("Tag.Name"  ,"name")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceTag
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Tag")
    scan all
        if el_seek( upper(strtran(ImportSourceTag->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            l_hTagPkOldToNew[ImportSourceTag->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000020","Tag")
                :Field("fk_Application",par_iApplicationPk)
                ImportAddRecordSetField(l_oDBImport,"Tag","*fk_Application*",l_aColumns)
                if :Add()
                    l_hTagPkOldToNew[ImportSourceTag->pk] := :Key()
                endif
                
            endwith
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import TagTable
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000021","Tag")
        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
        :Join("inner","TagTable","","TagTable.fk_Tag = Tag.pk")
        :Column("TagTable.fk_Tag"  ,"fk_Tag")
        :Column("TagTable.Pk"      ,"pk")
        :Column("TagTable.Fk_Table","Fk_Table")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(alltrim(str(fk_Tag))+'*'+alltrim(str(Fk_Table))+'*',40)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceTagTable
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.TagTable")
    scan all
        l_iParentKeyImport  := ImportSourceTagTable->fk_Tag
        l_iParentKeyCurrent := hb_HGetDef(l_hTagPkOldToNew,l_iParentKeyImport,0)

        l_ifk_TableImport:= ImportSourceTagTable->fk_Table
        if hb_IsNil(l_ifk_TableImport) .or. hb_IsNil(l_ifk_TableImport)
            l_ifk_TableCurrent := 0
        else
            l_ifk_TableCurrent := hb_HGetDef(l_hTablePkOldToNew,l_ifk_TableImport,0)
        endif

        if empty(l_iParentKeyCurrent)
            SendToDebugView("Failure to find Tag Parent Key on TagTable Import" ,l_iParentKeyImport)
        else
            if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_TableCurrent))+'*' ,"ListOfCurrentRecords","tag1")
                // SendToDebugView("Import: Table Already on file in Tag (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            else
                with object l_oDBImport
                    :Table("df873645-94d3-4ba5-85cf-000000000022","TagTable")
                    :Field("fk_Tag"    ,l_iParentKeyCurrent)
                    :Field("fk_Table"  ,l_ifk_TableCurrent)
                    ImportAddRecordSetField(l_oDBImport,"TagTable","*fk_Tag*fk_Table*",l_aColumns)   // No other field exists but leaving this in case we add some.
                    if :Add()
                    endif
                endwith
            endif
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import TagColumn
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000023","Tag")
        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
        :Join("inner","TagColumn","","TagColumn.fk_Tag = Tag.pk")
        :Column("TagColumn.fk_Tag" ,"fk_Tag")
        :Column("TagColumn.Pk"       ,"pk")
        :Column("TagColumn.Fk_Column","Fk_Column")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(alltrim(str(fk_Tag))+'*'+alltrim(str(Fk_Column))+'*',40)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceTagColumn
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.TagColumn")
    scan all
        l_iParentKeyImport  := ImportSourceTagColumn->fk_Tag
        l_iParentKeyCurrent := hb_HGetDef(l_hTagPkOldToNew,l_iParentKeyImport,0)

        l_ifk_ColumnImport:= ImportSourceTagColumn->fk_Column
        if hb_IsNil(l_ifk_ColumnImport) .or. hb_IsNil(l_ifk_ColumnImport)
            l_ifk_ColumnCurrent := 0
        else
            l_ifk_ColumnCurrent := hb_HGetDef(l_hColumnPkOldToNew,l_ifk_ColumnImport,0)
        endif

        if empty(l_iParentKeyCurrent)
            SendToDebugView("Failure to find Tag Parent Key on TagColumn Import" ,l_iParentKeyImport)
        else
            if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_ColumnCurrent))+'*' ,"ListOfCurrentRecords","tag1")
                // SendToDebugView("Import: Column Already on file in Tag (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            else
                with object l_oDBImport
                    :Table("df873645-94d3-4ba5-85cf-000000000024","TagColumn")
                    :Field("fk_Tag"    ,l_iParentKeyCurrent)
                    :Field("fk_Column" ,l_ifk_ColumnCurrent)
                    ImportAddRecordSetField(l_oDBImport,"TagColumn","*fk_Tag*fk_Column*",l_aColumns)   // No other field exists but leaving this in case we add some.
                    if :Add()
                    endif
                endwith
            endif
        endif
    endscan
endif
//-------------------------------------------------------------------------------------------------------------------------
// Import Custom Fields
if used("ImportSourceCustomField")   // Should skip this in case this is a Table Import

    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000025","CustomField")
        :Column("CustomField.Pk"    ,"pk")
        :Column("CustomField.Code"  ,"Code")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(upper(strtran(Code,' ',''))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceCustomField
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.CustomField")
    scan all

        l_hImportSourceCustomFieldUsedOn[ImportSourceCustomField->pk] := ImportSourceCustomField->UsedOn

        if el_seek( upper(strtran(ImportSourceCustomField->Code,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            l_hCustomFieldPkOldToNew[ImportSourceCustomField->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000026","CustomField")
                ImportAddRecordSetField(l_oDBImport,"CustomField","",l_aColumns)
                if :Add()
                    l_hCustomFieldPkOldToNew[ImportSourceCustomField->pk] := :Key()
                endif
                
            endwith
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import ApplicationCustomField
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000026","ApplicationCustomField")
        :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
        :Column("ApplicationCustomField.Pk"            ,"pk")
        :Column("ApplicationCustomField.Fk_CustomField","Fk_CustomField")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","Fk_CustomField")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceApplicationCustomField
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ApplicationCustomField")
    scan all

        l_ifk_CustomFieldImport:= ImportSourceApplicationCustomField->fk_CustomField
        if hb_IsNil(l_ifk_CustomFieldImport) .or. hb_IsNil(l_ifk_CustomFieldImport)
            l_ifk_CustomFieldCurrent := 0
        else
            l_ifk_CustomFieldCurrent := hb_HGetDef(l_hCustomFieldPkOldToNew,l_ifk_CustomFieldImport,0)
        endif

        if el_seek(l_ifk_CustomFieldCurrent ,"ListOfCurrentRecords","tag1")
            // Record already on file
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000027","ApplicationCustomField")
                :Field("fk_Application" ,par_iApplicationPk)
                :Field("fk_CustomField" ,l_ifk_CustomFieldCurrent)
                ImportAddRecordSetField(l_oDBImport,"ApplicationCustomField","*fk_Application*fk_CustomField*",l_aColumns)   // No other field exists but leaving this in case we add some.
                if :Add()
                endif
            endwith
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import CustomFieldValues

    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000028","ApplicationCustomField")
        :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
        :Join("inner","CustomField"      ,"","ApplicationCustomField.fk_CustomField = CustomField.pk")
        :Join("inner","CustomFieldValue" ,"" ,"CustomFieldValue.fk_CustomField = CustomField.pk")

        :Column("CustomFieldValue.fk_CustomField","fk_CustomField")
        // :Column("CustomField.UsedOn"             ,"CustomField_UsedOn")
        :Column("CustomFieldValue.fk_Entity"     ,"fk_Entity")
        :Column("CustomFieldValue.Pk"            ,"pk")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("tag1","padr(alltrim(str(fk_CustomField))+'*'+alltrim(str(fk_Entity))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceCustomFieldValue
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.CustomFieldValue")
    scan all
        l_iParentKeyImport  := ImportSourceCustomFieldValue->fk_CustomField
        l_iParentKeyCurrent := hb_HGetDef(l_hCustomFieldPkOldToNew,l_iParentKeyImport,0)

        l_ifk_EntityImport:= ImportSourceCustomFieldValue->fk_Entity
        if hb_IsNil(l_ifk_EntityImport) .or. hb_IsNil(l_ifk_EntityImport)
            l_ifk_EntityCurrent := 0
        else
            lnUsedOn := hb_HGetDef(l_hImportSourceCustomFieldUsedOn,l_iParentKeyImport,0)
            do case
            case lnUsedOn == USEDON_APPLICATION  // 1
                l_ifk_EntityCurrent := par_iApplicationPk
            case lnUsedOn == USEDON_NAMESPACE    // 2
                l_ifk_EntityCurrent := hb_HGetDef(l_hNamespacePkOldToNew,l_ifk_EntityImport,0)
            case lnUsedOn == USEDON_TABLE        // 3
                l_ifk_EntityCurrent := hb_HGetDef(l_hTablePkOldToNew    ,l_ifk_EntityImport,0)
            case lnUsedOn == USEDON_COLUMN       // 4
                l_ifk_EntityCurrent := hb_HGetDef(l_hColumnPkOldToNew   ,l_ifk_EntityImport,0)
            otherwise
                loop // Do not import the custom field value
            endcase
        endif

        if empty(l_iParentKeyCurrent)
            SendToDebugView("Failure to find CustomField Parent Key on CustomFieldValue Import" ,l_iParentKeyImport)
        else
            if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_EntityCurrent))+'*' ,"ListOfCurrentRecords","tag1")
                // SendToDebugView("Import: CustomFieldValue Already on file in CustomField (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            else
                with object l_oDBImport
                    :Table("df873645-94d3-4ba5-85cf-000000000029","CustomFieldValue")
                    :Field("fk_CustomField" ,l_iParentKeyCurrent)
                    :Field("fk_Entity"      ,l_ifk_EntityCurrent)
                    ImportAddRecordSetField(l_oDBImport,"CustomFieldValue","*fk_CustomField*fk_Entity*",l_aColumns)
                    if :Add()
                    endif
                endwith
            endif
        endif
    endscan

endif

//-------------------------------------------------------------------------------------------------------------------------
if used("ImportSourceTemplateTable")   // Should skip this in case this is a Table Import

    // Import TemplateTables
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000030","TemplateTable")
        :Where("TemplateTable.fk_Application = ^" , par_iApplicationPk)
        :Column("TemplateTable.Pk"    ,"pk")
        :Column("TemplateTable.Name"  ,"name")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("TemplateTable1","padr(upper(strtran(Name,' ',''))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceTemplateTable
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.TemplateTable")
    scan all
        if el_seek( upper(strtran(ImportSourceTemplateTable->Name,' ',''))+'*' ,"ListOfCurrentRecords","TemplateTable1")
            l_hTemplateTablePkOldToNew[ImportSourceTemplateTable->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000031","TemplateTable")
                :Field("fk_Application",par_iApplicationPk)
                ImportAddRecordSetField(l_oDBImport,"TemplateTable","*fk_Application*",l_aColumns)
                if :Add()
                    l_hTemplateTablePkOldToNew[ImportSourceTemplateTable->pk] := :Key()
                endif
                
            endwith
        endif
    endscan

    //-------------------------------------------------------------------------------------------------------------------------
    // Import TemplateColumn
    with object l_oDB_ListOfCurrentRecords
        :Table("df873645-94d3-4ba5-85cf-000000000032","TemplateTable")
        :Where("TemplateTable.fk_Application = ^" , par_iApplicationPk)
        :Join("inner","TemplateColumn","","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
        :Column("TemplateColumn.fk_TemplateTable"  ,"fk_TemplateTable")
        :Column("TemplateColumn.Pk"                ,"pk")
        :Column("TemplateColumn.Name"              ,"name")
        :SQL("ListOfCurrentRecords")
        with object :p_oCursor
            :Index("TemplateTable1","padr(alltrim(str(fk_TemplateTable))+'*'+upper(strtran(Name,' ',''))+'*',240)")
            :CreateIndexes()
        endwith
    endwith

    select ImportSourceTemplateColumn
    l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.TemplateColumn")
    scan all
        l_iParentKeyImport  := ImportSourceTemplateColumn->fk_TemplateTable
        l_iParentKeyCurrent := hb_HGetDef(l_hTemplateTablePkOldToNew,l_iParentKeyImport,0)

        if empty(l_iParentKeyCurrent)
            SendToDebugView("Failure to find TemplateTable Parent Key on TemplateColumn Import" ,l_iParentKeyImport)
        else
            if el_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceTemplateColumn->Name,' ',''))+'*' ,"ListOfCurrentRecords","TemplateTable1")
                // SendToDebugView("Import: Table Already on file in TemplateTable (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            else
                with object l_oDBImport
                    :Table("df873645-94d3-4ba5-85cf-000000000033","TemplateColumn")
                    :Field("fk_TemplateTable"    ,l_iParentKeyCurrent)
                    ImportAddRecordSetField(l_oDBImport,"TemplateColumn","*fk_TemplateTable*",l_aColumns)
                    if :Add()
                    endif
                endwith
            endif
        endif
    endscan
endif

//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------

return nil
//=================================================================================================================



//=================================================================================================================
function ExportTableForImports(par_iTablePk)
local l_cBackupCode := ""

local l_lContinue := .t.
local l_oDB_ListOfRecords    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_hTableSchema         := oFcgi:p_o_SQLConnection:p_WharfConfig["Tables"]

local l_oDB_ListOfFileStream := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_FileStream       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_TableInfo        := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cFilePathPID
local l_cFilePathUser
local l_iKey
local l_cLinkUID
local l_cFileName
local l_oInfo

local l_iNamespacePk
local l_iApplicationPk


hb_HCaseMatch(l_hTableSchema,.f.)  // Case Insensitive search

with object l_oDB_TableInfo
    :Table("c2d4720b-d8fe-4540-b43a-ac60bc55f601","Table")
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Application","","Namespace.fk_Application = Application.pk")
    :Column("Application.Pk"  ,"Application_Pk")
    :Column("Application.Name","Application_Name")
    :Column("Namespace.Pk"    ,"Namespace_Pk")
    :Column("Namespace.Name"  ,"Namespace_Name")
    :Column("Table.Name"      ,"Table_Name")
    l_oInfo := :Get(par_iTablePk)
endwith

//l_oInfo:Application_Pk

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000004","Table")
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
    :Join("inner","Application","","Namespace.fk_Application = Application.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Namespace")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Namespace","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000005","Table")
    :Where("Table.pk = ^",par_iTablePk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Table")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Table","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000006","Table")
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Column" ,"","Column.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Column")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Column","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000007","Table")
    :Distinct(.t.)
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Column" ,"","Column.fk_Table = Table.pk")
    :Join("inner","Enumeration" ,"","Column.fk_Enumeration = Enumeration.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Enumeration")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Enumeration","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000008","Table")
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Column" ,"","Column.fk_Table = Table.pk")
    :Join("inner","Enumeration" ,"","Column.fk_Enumeration = Enumeration.pk")
    :Join("inner","EnumValue" ,"","EnumValue.fk_Enumeration = Enumeration.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"EnumValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"EnumValue","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000009","Table")
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Index" ,"","Index.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Index")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Index","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-0002-000000000010","Table")
    :Where("Table.pk = ^",par_iTablePk)
    :Join("inner","Index" ,"","Index.fk_Table = Table.pk")
    :Join("inner","IndexColumn" ,"","IndexColumn.fk_Index = Index.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"IndexColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"IndexColumn","ListOfRecords")
    endif
endwith

//For now don't export custom fields
//----- Custom Field Begin ------------------------------------------------------
// with object l_oDB_ListOfRecords
//     :Table("299a129d-dab1-4dad-0002-000000000018","ApplicationCustomField")
//     :Distinct(.t.)
//     :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
//     :Join("inner","CustomField" ,"","ApplicationCustomField.fk_CustomField = CustomField.pk")
//     ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"CustomField")

//     :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

//     :OrderBy("pk")
//     :SQL("ListOfRecords")
//     if :Tally < 0
//         l_lContinue := .f.
//     else
//         l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"CustomField","ListOfRecords")
//     endif
// endwith

// with object l_oDB_ListOfRecords
//     :Table("299a129d-dab1-4dad-0002-000000000019","ApplicationCustomField")
//     :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)

//     :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
//     :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

//     ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ApplicationCustomField")
//     :OrderBy("pk")
//     :SQL("ListOfRecords")
//     if :Tally < 0
//         l_lContinue := .f.
//     else
//         l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ApplicationCustomField","ListOfRecords")
//     endif
// endwith

// with object l_oDB_ListOfRecords
//     :Table("299a129d-dab1-4dad-0002-000000000020","ApplicationCustomField")
//     :Distinct(.t.)
//     :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
//     :Join("inner","CustomFieldValue" ,"","CustomFieldValue.fk_CustomField = ApplicationCustomField.fk_CustomField")

//     :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
//     :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

//     ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"CustomFieldValue")
//     :OrderBy("pk")
//     :SQL("ListOfRecords")
//     if :Tally < 0
//         l_lContinue := .f.
//     else
//         l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"CustomFieldValue","ListOfRecords")
//     endif
// endwith
// ----- Custom Field End ------------------------------------------------------

if l_lContinue
    l_cBackupCode += CRLF

    l_cFilePathPID := GetStreamFileFolderForCurrentProcess()

    el_StrToFile(l_cBackupCode,l_cFilePathPID+"Export.txt")

    hb_ZipFile(l_cFilePathPID+"Export.zip",l_cFilePathPID+"Export.txt",9,,.t.)
    DeleteFile(l_cFilePathPID+"Export.txt")

    //_M_ Add a Sanitizing function for l_oInfo:Application_Name
    l_cFileName := "ExportTable_"+strtran(l_oInfo:Namespace_Name," ","_")+"_"+strtran(l_oInfo:Table_Name," ","_")+"_"+GetZuluTimeStampForFileNameSuffix()+".zip"

    //Try to find if we already have a streamfile
    with object l_oDB_ListOfFileStream
        :Table("299a129d-dab1-4dad-0002-000000000200","volatile.FileStream","FileStream")
        :Column("FileStream.pk"     ,"pk")
        :Column("FileStream.LinkUID","LinkUID")
        :Where("FileStream.fk_User = ^"  , oFCgi:p_iUserPk)
        :Where("FileStream.fk_Table = ^" , par_iTablePk)
        :Where("FileStream.type = 5")
        :SQL("ListOfFileStream")
        do case
        case :Tally < 0
            //Error
            l_iKey := 0
        case :Tally == 1
            l_iKey     := ListOfFileStream->pk
            l_cLinkUID := ListOfFileStream->LinkUID
            if !l_oDB_FileStream:SaveFile("299a129d-dab1-4dad-0002-000000000201","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
                l_cFilePathUser := GetStreamFileFolderForCurrentUser()
                hb_vfMoveFile(l_cFilePathPID+"Export.zip",l_cFilePathUser+"Export"+trans(l_iKey)+".zip")
            endif
            with object l_oDB_FileStream
                :Table("2c5183d2-9aad-4f72-8cfe-f4ad411e6c74","volatile.FileStream","FileStream")
                :Field("FileName" , l_cFileName)
                if :Update(l_iKey)
                endif
            endwith
        otherwise
            if :Tally > 1 //Bad data.
                select ListOfFileStream
                scan all
                    l_oDB_FileStream:Delete("299a129d-dab1-4dad-0002-000000000202","volatile.FileStream",ListOfFileStream->pk)
                endscan
            endif

            with object l_oDB_FileStream
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Table("299a129d-dab1-4dad-0002-000000000203","volatile.FileStream","FileStream")
                :Field("fk_User"        , oFCgi:p_iUserPk)
                :Field("fk_Table"       , par_iTablePk)
                :Field("type"           , 5)
                :Field("LinkUID"        , l_cLinkUID)
                :Field("FileName"       , l_cFileName)
                if :Add()
                    l_iKey := :Key()
                    if !l_oDB_FileStream:SaveFile("299a129d-dab1-4dad-0002-000000000204","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
                        l_cFilePathUser := GetStreamFileFolderForCurrentUser()
                        hb_vfMoveFile(l_cFilePathPID+"Export.zip",l_cFilePathUser+"Export"+trans(l_iKey)+".zip")
                    endif
                else
                    l_iKey := 0
                endif
            endwith
        endcase
    endwith
    DeleteFile(l_cFilePathPID+"Export.zip")
else
    l_iKey := 0
endif

if l_iKey == 0
    //Report error
    l_cLinkUID    := ""
    l_cBackupCode := "Export Failed"
endif

return l_cLinkUID
//=================================================================================================================


//=================================================================================================================
function DataDictionaryExportFormBuild(par_iApplicationPk,par_cErrorText)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_cSitePath  := oFcgi:p_cSitePath
local l_nBackendType

local l_cMessageLine

oFcgi:TraceAdd("DataDictionaryExportOptions")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Step1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
// l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

if !empty(par_iApplicationPk)

    l_nBackendType := val(GetUserSetting("DataDictionaryExportBackendType"))

    l_cHtml += GetAboveNavbarHeading("Export")

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            // l_cHtml += [<span class="navbar-brand ms-3">Export Options</span>]   //navbar-text
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3 me-5" value="Export For DataWharf Imports" onclick="$('#ActionOnSubmit').val('ExportForDataWharfImports');document.form.submit();" role="button">]

            l_cHtml += [<select name="ComboBackendType" id="ComboBackendType" class="ms-5">]
            l_cHtml += [<option value="2"]+iif(l_nBackendType==2,[ selected],[])+[>MySQL/MariaDB</option>]
            l_cHtml += [<option value="3"]+iif(l_nBackendType==3,[ selected],[])+[>PostgreSQL</option>]
            // l_cHtml += [<option value="4"]+iif(l_nBackendType==4,[ selected],[])+[>MSSQL</option>]
            l_cHtml += [</select>]

            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Export to Harbour_ORM" onclick="$('#ActionOnSubmit').val('ExportToHarbourORM');document.form.submit();" role="button">]
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Export to JSON" onclick="$('#ActionOnSubmit').val('ExportToJSON');document.form.submit();" role="button">]

        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    l_cHtml += [</form>]
endif

return l_cHtml
//=================================================================================================================
function DataDictionaryExportFormOnSubmit(par_iApplicationPk,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit
local l_nBackendType
local l_cBackendType

local l_cErrorMessage := ""

oFcgi:TraceAdd("DataDictionaryExportFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
l_nBackendType    := val(oFcgi:GetInputValue("ComboBackendType"))
SaveUserSetting("DataDictionaryExportBackendType",trans(l_nBackendType))

do case
case l_nBackendType == 2
    l_cBackendType := "MySQL"
case l_nBackendType == 3
    l_cBackendType := "PostgreSQL"
// case l_nBackendType == 4
otherwise
    l_cBackendType := ""
endcase

do case
case empty(l_cBackendType)
    l_cErrorMessage := "Missing Backend Type"

case l_cActionOnSubmit == "ExportForDataWharfImports"
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionaryExportForDataWharfImports/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "ExportToHarbourORM"
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionaryExportToHarbourORM/"+par_cURLApplicationLinkCode+"/?Backend="+l_cBackendType)

case l_cActionOnSubmit == "ExportToJSON"
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionaryExportToJSON/"+par_cURLApplicationLinkCode+"/?Backend="+l_cBackendType)

case el_IsInlist(l_cActionOnSubmit,"Cancel","Done")
    oFcgi:Redirect(oFcgi:p_cSitePath+"DataDictionaries/DataDictionaryImport/"+par_cURLApplicationLinkCode+"/")

endcase

if !empty(l_cErrorMessage)
    // l_cHtml += DataDictionaryExportFormBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode)
    l_cHtml += DataDictionaryExportFormBuild(par_iApplicationPk,l_cErrorMessage)
endif

return l_cHtml
//=================================================================================================================
