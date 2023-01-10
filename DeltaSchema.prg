#include "DataWharf.ch"

function DeltaSchema(par_SQLHandle,par_iApplicationPk,par_SQLEngineType,par_cDatabase,par_cSyncNameSpaces,par_nSyncSetForeignKey)
local l_cSQLCommand
local l_cSQLCommandEnums       := []
local l_cSQLCommandFields      := []
local l_cSQLCommandIndexes     := []
local l_cSQLCommandForeignKeys := []
local l_aNameSpaces
local l_iPosition
local l_iFirstNameSpace

local l_cLastNameSpace
local l_cLastTableName
local l_cColumnName
local l_cEnumValueName

local l_cLastEnumerationName
local l_iNameSpacePk
local l_iTablePk
local l_iColumnPk
local l_iEnumerationPk
local l_iIndexPk

local l_LastColumnOrder
local l_LastEnumValueOrder

local l_cColumnType
local l_lColumnArray
local l_nColumnLength
local l_nColumnScale
local l_lColumnNullable
local l_lColumnPrimary
local l_lColumnUnicode
local l_cColumnDefault
local l_cColumnLastNativeType
local l_iFk_Enumeration

local l_cIndexName
local l_cIndexExpression
local l_lIndexUnique
local l_iIndexAlgo

local l_oDB1                              := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnsInTable          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumValuesInEnumeration := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfIndexesInTable          := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_hCurrentListOfEnumerations := {=>}
local l_aEnumerationInfo

local l_hCurrentListOfEnumValues   := {=>}
local l_aEnumValueInfo

local l_hCurrentListOfTables       := {=>}
local l_aTableInfo

local l_hCurrentListOfColumns      := {=>}
local l_aColumnInfo

local l_hCurrentListOfIndexes      := {=>}
local l_aIndexInfo
//---

local l_oDB_AllTablesAsParentsForForeignKeys
local l_oDB_AllTableColumnsChildrenForForeignKeys

local l_aSQLResult := {}
local l_cErrorMessage := ""

local l_iNewTables         := 0
local l_iNewNameSpace      := 0
local l_iNewColumns        := 0
local l_iNewEnumerations   := 0
local l_iNewEnumValues     := 0
local l_iMismatchedColumns := 0
local l_iNewIndexes        := 0
local l_iMismatchedIndexes := 0

local l_nPos

local l_hEnumerations := {=>}

//The following is not the most memory efficient, a 3 layer hash array would be better. 
local l_hTables       := {=>}  // The key is <NameSpace>.<TableName>
local l_hColumns      := {=>}  // The key is <NameSpace>.<TableName>.<ColumnName>

local l_iParentTableKey
local l_iChildColumnKey

local l_aListOfMessages := {}

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL
    //To work around performance issues when querying meta database
    l_cSQLCommand := [SET enable_nestloop = false;]
    SQLExec(par_SQLHandle,l_cSQLCommand)
endcase

hb_HCaseMatch(l_hCurrentListOfEnumerations,.f.)
hb_HKeepOrder(l_hCurrentListOfEnumerations,.t.)

hb_HCaseMatch(l_hCurrentListOfEnumValues,.f.)
hb_HKeepOrder(l_hCurrentListOfEnumValues,.t.)

hb_HCaseMatch(l_hCurrentListOfTables,.f.)
hb_HKeepOrder(l_hCurrentListOfTables,.t.)

hb_HCaseMatch(l_hCurrentListOfIndexes,.f.)
hb_HKeepOrder(l_hCurrentListOfIndexes,.t.)

hb_HCaseMatch(l_hCurrentListOfColumns,.f.)
hb_HKeepOrder(l_hCurrentListOfColumns,.t.)


// If switching to MySQL to store our own tables, have to deal with variables/fields: IndexUnique, ColumnNullable

///////////////////////////////===========================================================================================================

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
    //_M_


case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL
    l_cSQLCommandEnums := [SELECT namespaces.nspname as schema_name,]
    l_cSQLCommandEnums += [       types.typname      as enum_name,]
    l_cSQLCommandEnums += [       enums.enumlabel    as enum_value]
    l_cSQLCommandEnums += [ FROM pg_type types]
    l_cSQLCommandEnums += [ JOIN pg_enum enums on types.oid = enums.enumtypid]
    l_cSQLCommandEnums += [ JOIN pg_catalog.pg_namespace namespaces ON namespaces.oid = types.typnamespace]
    if !empty(par_cSyncNameSpaces)
        l_cSQLCommandFields  += [ AND lower(namespaces.nspname) in (]
        l_aNameSpaces := hb_ATokens(par_cSyncNameSpaces,",",.f.)
        l_iFirstNameSpace := .t.
        for l_iPosition := 1 to len(l_aNameSpaces)
            l_aNameSpaces[l_iPosition] := strtran(l_aNameSpaces[l_iPosition],['],[])
            if !empty(l_aNameSpaces[l_iPosition])
                if l_iFirstNameSpace
                    l_iFirstNameSpace := .f.
                else
                    l_cSQLCommandFields += [,]
                endif
                l_cSQLCommandFields += [']+lower(l_aNameSpaces[l_iPosition])+[']
            endif
        endfor
        l_cSQLCommandFields  += [)]
    endif
    l_cSQLCommandEnums += [ ORDER BY schema_name,enum_name;]


    l_cSQLCommandFields  := [SELECT columns.table_schema             AS schema_name,]
    l_cSQLCommandFields  += [       columns.table_name               AS table_name,]
    l_cSQLCommandFields  += [       columns.ordinal_position         AS field_position,]
    l_cSQLCommandFields  += [       columns.column_name              AS field_name,]

    // l_cSQLCommandFields  += [       columns.data_type                AS field_type,]
    // l_cSQLCommandFields  += [       element_types.data_type          AS field_type_extra,]

    l_cSQLCommandFields  += [      CASE]+CRLF
    l_cSQLCommandFields  += [         WHEN columns.data_type = 'ARRAY' THEN element_types.data_type::text]+CRLF
    l_cSQLCommandFields  += [        ELSE columns.data_type::text]+CRLF
    l_cSQLCommandFields  += [      END AS field_type,]+CRLF
    l_cSQLCommandFields  += [         CASE]+CRLF
    l_cSQLCommandFields  += [         WHEN columns.data_type = 'ARRAY' THEN true]+CRLF
    l_cSQLCommandFields  += [        ELSE false]+CRLF
    l_cSQLCommandFields  += [      END AS field_array,]+CRLF


    l_cSQLCommandFields  += [       columns.character_maximum_length AS field_clength,]
    l_cSQLCommandFields  += [       columns.numeric_precision        AS field_nlength,]
    l_cSQLCommandFields  += [       columns.datetime_precision       AS field_tlength,]
    l_cSQLCommandFields  += [       columns.numeric_scale            AS field_decimals,]
    l_cSQLCommandFields  += [       (columns.is_nullable = 'YES')    AS field_nullable,]
    l_cSQLCommandFields  += [       columns.column_default           AS field_default,]
    l_cSQLCommandFields  += [       (columns.is_identity = 'YES')    AS field_is_identity,]
    l_cSQLCommandFields  += [       columns.udt_name                 AS enumeration_name,]
    l_cSQLCommandFields  += [       upper(columns.table_schema)      AS tag1,]
    l_cSQLCommandFields  += [       upper(columns.table_name)        AS tag2]
    l_cSQLCommandFields  += [ FROM information_schema.columns]
    l_cSQLCommandFields  += [ INNER JOIN information_schema.tables ON columns.table_catalog = columns.table_catalog AND columns.table_schema = tables.table_schema AND columns.table_name = tables.table_name]
    l_cSQLCommandFields  += [ LEFT  JOIN information_schema.element_types ON ((columns.table_catalog, columns.table_schema, columns.table_name, 'TABLE', columns.dtd_identifier) = (element_types.object_catalog, element_types.object_schema, element_types.object_name, element_types.object_type, element_types.collection_type_identifier))]
    l_cSQLCommandFields  += [ WHERE NOT (lower(left(columns.table_name,11)) = 'schemacache' OR lower(columns.table_schema) in ('information_schema','pg_catalog'))]
    l_cSQLCommandFields  += [ AND   tables.table_type = 'BASE TABLE']
    if !empty(par_cSyncNameSpaces)
        l_cSQLCommandFields  += [ AND lower(columns.table_schema) in (]
        l_aNameSpaces := hb_ATokens(par_cSyncNameSpaces,",",.f.)
        l_iFirstNameSpace := .t.
        for l_iPosition := 1 to len(l_aNameSpaces)
            l_aNameSpaces[l_iPosition] := strtran(l_aNameSpaces[l_iPosition],['],[])
            if !empty(l_aNameSpaces[l_iPosition])
                if l_iFirstNameSpace
                    l_iFirstNameSpace := .f.
                else
                    l_cSQLCommandFields += [,]
                endif
                l_cSQLCommandFields += [']+lower(l_aNameSpaces[l_iPosition])+[']
            endif
        endfor
        l_cSQLCommandFields  += [)]
    endif
    l_cSQLCommandFields  += [ ORDER BY tag1,tag2,field_position]

// SendToClipboard(l_cSQLCommandFields)


    l_cSQLCommandIndexes := [SELECT pg_indexes.schemaname        AS schema_name,]
    l_cSQLCommandIndexes += [       pg_indexes.tablename         AS table_name,]
    l_cSQLCommandIndexes += [       pg_indexes.indexname         AS index_name,]
    l_cSQLCommandIndexes += [       pg_indexes.indexdef          AS index_definition,]
    l_cSQLCommandIndexes += [       upper(pg_indexes.schemaname) AS tag1,]
    l_cSQLCommandIndexes += [       upper(pg_indexes.tablename)  AS tag2]
    l_cSQLCommandIndexes += [ FROM pg_indexes]
    l_cSQLCommandIndexes += [ WHERE NOT (lower(left(pg_indexes.tablename,11)) = 'schemacache' OR lower(pg_indexes.schemaname) in ('information_schema','pg_catalog'))]
    l_cSQLCommandIndexes += [ ORDER BY tag1,tag2,index_name]



//--Load Enumerations-----------
    if !SQLExec(par_SQLHandle,l_cSQLCommandEnums,"ListOfEnumsForLoads")
        l_cErrorMessage := "Failed to retrieve Enumeration Meta data."
    else
        // ExportTableToHtmlFile("ListOfEnumsForLoads","d:\PostgreSQL_ListOfEnumsForLoads.html","From PostgreSQL",,200,.t.)

        with object l_oDB1
            :Table("77f9c695-656a-4f08-9f3b-0b9f255cae6d","NameSpace")
            :Column("Enumeration.Pk"          , "Enumeration_Pk")
            :Column("NameSpace.Name"          , "NameSpace_Name")
            :Column("Enumeration.Name"        , "Enumeration_Name")
            :Column("upper(NameSpace.Name)"   , "tag1")
            :Column("upper(Enumeration.Name)" , "tag2")
            :Join("inner","Enumeration","","Enumeration.fk_NameSpace = NameSpace.pk")
            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
            :OrderBy("tag1")
            :OrderBy("tag2")
            :SQL("ListOfEnumerations")
            select ListOfEnumerations
            scan all
                l_hCurrentListOfEnumerations[ListOfEnumerations->NameSpace_Name+"*"+ListOfEnumerations->Enumeration_Name+"*"] := {ListOfEnumerations->Enumeration_Pk,ListOfEnumerations->NameSpace_Name+"."+ListOfEnumerations->Enumeration_Name}
            endscan

            :Table("991803aa-7329-4c7a-bd22-171da990a6a6","NameSpace")
            :Column("Table.Pk"              , "Table_Pk")
            :Column("NameSpace.Name"        , "NameSpace_Name")
            :Column("Table.Name"            , "Table_Name")
            :Column("upper(NameSpace.Name)" , "tag1")
            :Column("upper(Table.Name)"     , "tag2")
            :Join("inner","Table","","Table.fk_NameSpace = NameSpace.pk")
            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
            :OrderBy("tag1")
            :OrderBy("tag2")
            :SQL("ListOfTables")
            select ListOfTables
            scan all
                l_hCurrentListOfTables[ListOfTables->NameSpace_Name+"*"+ListOfTables->Table_Name+"*"] := {ListOfTables->Table_Pk,ListOfTables->NameSpace_Name+"."+ListOfTables->Table_Name}
            endscan

        endwith


        l_cLastNameSpace       := ""
        l_cLastEnumerationName := ""
        l_cEnumValueName       := ""

        select ListOfEnumsForLoads
        scan all while empty(l_cErrorMessage)
            if !(ListOfEnumsForLoads->schema_name == l_cLastNameSpace .and. ListOfEnumsForLoads->enum_name == l_cLastEnumerationName)
                //New Enumeration being defined
                //Check if the Enumeration already on file

                l_cLastNameSpace       := ListOfEnumsForLoads->schema_name
                l_cLastEnumerationName := ListOfEnumsForLoads->enum_name
                l_iNameSpacePk         := -1
                l_iEnumerationPk       := -1

                with object l_oDB1
                    :Table("b9de5e1b-bfd9-4c18-a4af-96ca5873160d","Enumeration")
                    :Column("Enumeration.fk_NameSpace", "fk_NameSpace")
                    :Column("Enumeration.pk"          , "Pk")
                    :Join("inner","NameSpace","","Enumeration.fk_NameSpace = NameSpace.pk")
                    :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
                    :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cLastNameSpace," ","")))
                    :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cLastEnumerationName," ","")))
                    l_aSQLResult := {}
                    :SQL(@l_aSQLResult)

                    do case
                    case :Tally == -1  //Failed to query
                        l_cErrorMessage := "Failed to Query Meta database. Error 101."
                        exit
                    case empty(:Tally)
                        //Enumerations is not in datadic, load it.
                        //Find the Name Space
                        :Table("2e160bfe-dcc3-46dd-b263-cfa86b9ee0b7","NameSpace")
                        :Column("NameSpace.pk"          , "Pk")
                        :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
                        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cLastNameSpace," ","")))
                        l_aSQLResult := {}
                        :SQL(@l_aSQLResult)

                        do case
                        case :Tally == -1  //Failed to query
                            l_cErrorMessage := "Failed to Query Meta database. Error 102."
                        case empty(:Tally)
                            l_iNewNameSpace += 1
                            AAdd(l_aListOfMessages,[New NameSpace "]+l_cLastNameSpace+["])

                        case :Tally == 1
                            l_iNameSpacePk := l_aSQLResult[1,1]
                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 103."
                        endcase

                        l_iNewEnumerations += 1
                        AAdd(l_aListOfMessages,[New Enumeration "]+l_cLastEnumerationName+[" in NameSpace "]+l_cLastNameSpace+["])

                    case :Tally == 1
                        l_iNameSpacePk   := l_aSQLResult[1,1]
                        l_iEnumerationPk := l_aSQLResult[1,2]
                        l_hEnumerations[l_cLastNameSpace+"."+l_cLastEnumerationName] := l_iEnumerationPk   //_M_ is this needed?

hb_HDel(l_hCurrentListOfEnumerations,l_cLastNameSpace+"*"+l_cLastEnumerationName+"*")

                    otherwise
                        l_cErrorMessage := "Failed to Query Meta database. Error 104."
                    endcase

                endwith

                // Load all the Enumerations current EnumValues if 
                if l_iEnumerationPk > 0
                    with object l_oDB_ListOfEnumValuesInEnumeration
                        :Table("d8748388-1484-46cf-bb5d-d990bf9fcfad","EnumValue")
                        :Column("EnumValue.Pk"          , "Pk")
                        :Column("EnumValue.Order"       , "EnumValue_Order")
                        :Column("EnumValue.Name"        , "EnumValue_Name")
                        :Column("upper(EnumValue.Name)" , "tag1")
                        :Where("EnumValue.fk_Enumeration = ^" , l_iEnumerationPk)
                        :OrderBy("EnumValue_Order") //,"Desc"
                        :SQL("ListOfEnumValuesInEnumeration")

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data EnumValue. Error 106."
                        else
                            if :Tally == 0
                                l_LastEnumValueOrder := 0
                            else
                                select ListOfEnumValuesInEnumeration
                                scan all
                                    l_hCurrentListOfEnumValues[l_cLastNameSpace+"*"+l_cLastEnumerationName+"*"+ListOfEnumValuesInEnumeration->EnumValue_Name+"*"] := {ListOfEnumValuesInEnumeration->Pk,l_cLastNameSpace+"."+l_cLastEnumerationName+"."+ListOfEnumValuesInEnumeration->EnumValue_Name}
                                    l_LastEnumValueOrder := ListOfEnumValuesInEnumeration->EnumValue_Order   // since Ascending now, the last loop will have the biggest value
                                endscan
                            endif

                            with object :p_oCursor
                                :Index("tag1","tag1+'*'")
                                :CreateIndexes()
                            endwith

                        endif

                    endwith
                else
                    CloseAlias("ListOfEnumValuesInEnumeration")
                endif

            endif

            if empty(l_cErrorMessage)
                //Check existence of EnumValue and add if needed
                //Get the EnumValue Name
                l_cEnumValueName := alltrim(ListOfEnumsForLoads->enum_value)

hb_HDel(l_hCurrentListOfEnumValues,l_cLastNameSpace+"*"+l_cLastEnumerationName+"*"+l_cEnumValueName+"*")

                if !used("ListOfEnumValuesInEnumeration") .or. !vfp_Seek(upper(l_cEnumValueName)+'*',"ListOfEnumValuesInEnumeration","tag1")
                    //Missing EnumValue, Add it

                    l_iNewEnumValues += 1
                    AAdd(l_aListOfMessages,[New Enumeration Value "]+l_cEnumValueName+[" in "]+l_cLastNameSpace+"."+l_cLastEnumerationName+["])

                endif

            endif

        endscan

    endif


//--Load Tables-----------
    if empty(l_cErrorMessage)
        if !SQLExec(par_SQLHandle,l_cSQLCommandFields,"ListOfFieldsForLoads")
            l_cErrorMessage := "Failed to retrieve Fields Meta data."
        else
            // ExportTableToHtmlFile("ListOfFieldsForLoads","d:\PostgreSQL_ListOfFieldsForLoads.html","From PostgreSQL",,200,.t.)

            l_cLastNameSpace  := ""
            l_cLastTableName  := ""
            l_cColumnName     := ""

            select ListOfFieldsForLoads
            scan all while empty(l_cErrorMessage)
                if !(ListOfFieldsForLoads->schema_name == l_cLastNameSpace .and. ListOfFieldsForLoads->table_name == l_cLastTableName)
                    //New Table being defined
                    //Check if the table already on file

                    l_cLastNameSpace := ListOfFieldsForLoads->schema_name
                    l_cLastTableName := ListOfFieldsForLoads->table_name
                    l_iNameSpacePk   := -1
                    l_iTablePk       := -1

                    with object l_oDB1
                        :Table("7c364883-b3ee-4828-953c-69316d5e0e03","Table")
                        :Column("Table.fk_NameSpace", "fk_NameSpace")
                        :Column("Table.pk"          , "Pk")
                        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
                        :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
                        :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cLastNameSpace," ","")))
                        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cLastTableName," ","")))
                        l_aSQLResult := {}
                        :SQL(@l_aSQLResult)

                        do case
                        case :Tally == -1  //Failed to query
                            l_cErrorMessage := "Failed to Query Meta database. Error 101."
                            exit
                        case empty(:Tally)
                            //Tables is not in datadic, load it.
                            //Find the Name Space
                            :Table("0b38bd6e-f72d-4c15-92dc-b6bbacafbbc3","NameSpace")
                            :Column("NameSpace.pk" , "Pk")
                            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
                            :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cLastNameSpace," ","")))
                            l_aSQLResult := {}
                            :SQL(@l_aSQLResult)

                            do case
                            case :Tally == -1  //Failed to query
                                l_cErrorMessage := "Failed to Query Meta database. Error 102."
                            case empty(:Tally)
                                //Add the NameSpace

                                l_iNewNameSpace += 1
                                AAdd(l_aListOfMessages,[New NameSpace "]+l_cLastNameSpace+["])

                            case :Tally == 1
                                l_iNameSpacePk := l_aSQLResult[1,1]
                            otherwise
                                l_cErrorMessage := "Failed to Query Meta database. Error 103."
                            endcase

                            if l_iNameSpacePk > 0

                                l_iNewTables += 1
                                AAdd(l_aListOfMessages,[New Table "]+l_cLastTableName+[" in NameSpace "]+l_cLastNameSpace+["])

                            endif

                        case :Tally == 1
                            l_iNameSpacePk   := l_aSQLResult[1,1]
                            l_iTablePk       := l_aSQLResult[1,2]
                            l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk

hb_HDel(l_hCurrentListOfTables,l_cLastNameSpace+"*"+l_cLastTableName+"*")

                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 104."
                        endcase

                    endwith

                    // Load all the Table current Columns
                    with object l_oDB_ListOfColumnsInTable
                        :Table("088a71c4-f56d-4b18-8dc9-df25eee291f8","Column")
                        :Column("Column.Pk"             , "Pk")
                        :Column("Column.Order"          , "Column_Order")
                        :Column("Column.Name"           , "Column_Name")
                        :Column("upper(Column.Name)"    , "tag1")
                        :Column("Column.Type"           , "Column_Type")
                        :Column("Column.Array"          , "Column_Array")
                        :Column("Column.Length"         , "Column_Length")
                        :Column("Column.Scale"          , "Column_Scale")
                        :Column("Column.Nullable"       , "Column_Nullable")
                        :Column("Column.Primary"        , "Column_Primary")              // field_is_identity
                        :Column("Column.Unicode"        , "Column_Unicode")
                        :Column("Column.Default"        , "Column_Default")
                        :Column("Column.LastNativeType" , "Column_LastNativeType")
                        :Column("Column.fk_Enumeration" , "Column_fk_Enumeration")
                        :Column("Column.UseStatus"      , "Column_UseStatus")
                        :Where("Column.fk_Table = ^" , l_iTablePk)
                        :OrderBy("Column_Order") // ,"Desc"
                        :SQL("ListOfColumnsInTable")
                        // SendToClipboard(:LastSQL())

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data Columns. Error 105."
                        else
                            if :Tally == 0
                                l_LastColumnOrder := 0
                            else
                                select ListOfColumnsInTable
                                scan all
l_hCurrentListOfColumns[l_cLastNameSpace+"*"+l_cLastTableName+"*"+ListOfColumnsInTable->Column_Name+"*"] := {ListOfColumnsInTable->Pk,l_cLastNameSpace+"."+l_cLastTableName+"."+ListOfColumnsInTable->Column_Name}
                                    l_LastColumnOrder := ListOfColumnsInTable->Column_Order   // since Ascending now, the last loop will have the biggest value
                                endscan
                            endif

                            with object :p_oCursor
                                :Index("tag1","tag1+'*'")
                                :CreateIndexes()
                            endwith

                        endif

                    endwith

                endif

                if empty(l_cErrorMessage)
                    //Check existence of Column and add if needed
                    //Get the column Name, Type, Length, Scale, Nullable and fk_Enumeration
                    l_cColumnName           := alltrim(ListOfFieldsForLoads->field_name)
hb_HDel(l_hCurrentListOfColumns,l_cLastNameSpace+"*"+l_cLastTableName+"*"+l_cColumnName+"*")

                    l_lColumnNullable       := ListOfFieldsForLoads->field_nullable      // Since the information_schema does not follow odbc driver setting to return boolean as logical
                    l_lColumnPrimary        := ListOfFieldsForLoads->field_is_identity
                    l_lColumnUnicode        := .f.
                    l_cColumnDefault        := nvl(ListOfFieldsForLoads->field_default,"")
                    l_lColumnArray          := ListOfFieldsForLoads->field_array
                    l_cColumnLastNativeType := nvl(ListOfFieldsForLoads->field_type,"")
                    if l_cColumnDefault == "NULL"
                        l_cColumnDefault := ""
                    endif
                    l_cColumnDefault        := strtran(l_cColumnDefault,"::"+l_cColumnLastNativeType,"")  //Remove casting to the same field type. (PostgreSQL specific behavior)
                    l_cColumnLastNativeType := l_cColumnLastNativeType + iif(l_lColumnArray,"[]","")
                    
                    if l_cColumnLastNativeType == "character"
                        l_cColumnDefault := strtran(l_cColumnDefault,"::bpchar","")
                    endif
                    if !hb_orm_isnull("ListOfFieldsForLoads","enumeration_name")
                        l_cColumnDefault := strtran(l_cColumnDefault,[::"]+ListOfFieldsForLoads->enumeration_name+["],"")
                        l_cColumnDefault := strtran(l_cColumnDefault,[::]+ListOfFieldsForLoads->enumeration_name,"")   // Some previous versions of Postgresql will or will not have double quotes around the entity name.
                    endif

                    l_iFk_Enumeration := 0

                    // if ListOfFieldsForLoads->field_type == "USER-DEFINED"
                    //     altd()
                    // endif

                    // l_lColumnArray := (ListOfFieldsForLoads->field_type == "ARRAY")
                    // switch iif(ListOfFieldsForLoads->field_type == "ARRAY",nvl(ListOfFieldsForLoads->field_type_extra,"unknown"),ListOfFieldsForLoads->field_type)

                    switch ListOfFieldsForLoads->field_type
                    case "integer"
                        l_cColumnType   := "I"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "bigint"
                        l_cColumnType   := "IB"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "numeric"
                        l_cColumnType   := "N"
                        l_nColumnLength := ListOfFieldsForLoads->field_nlength
                        l_nColumnScale  := ListOfFieldsForLoads->field_decimals
                        exit

                    case "character"
                        l_cColumnType     := "C"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // In PostgreSQL character fields always support unicode
                        exit

                    case "character varying"
                        l_cColumnType     := "CV"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // In PostgreSQL character fields always support unicode
                        exit

                    case "bit"
                        l_cColumnType   := "B"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "bit varying"
                        l_cColumnType   := "BV"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "text"
                        l_cColumnType     := "M"
                        l_nColumnLength   := NIL
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // In PostgreSQL character fields always support unicode
                        exit

                    case "bytea"
                        l_cColumnType   := "R"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "boolean"
                        l_cColumnType   := "L"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "date"
                        l_cColumnType   := "D"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "time"
                    case "time with time zone"
                        l_cColumnType   := "TOZ"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "time without time zone"
                        l_cColumnType   := "TO"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "timestamp"
                    case "timestamp with time zone"
                        l_cColumnType   := "DTZ"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "timestamp without time zone"
                        l_cColumnType   := "DT"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "money"
                        l_cColumnType   := "Y"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "uuid"
                        l_cColumnType   := "UUI"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "json"
                    case "jsonb"
                        l_cColumnType   := "JS"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "USER-DEFINED"
                        l_cColumnType   := "E"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL

                        l_iFk_Enumeration := hb_HGetDef(l_hEnumerations,l_cLastNameSpace+"."+alltrim(ListOfFieldsForLoads->enumeration_name),0)
                        exit

                    // case "xxxxxx"
                    //     l_cColumnType   := "xxx"
                    //     l_nColumnLength := 0
                    //     l_nColumnScale  := 0
                    //     exit

                    otherwise
                        l_cColumnType   := "?"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        // Altd()
                    endcase

//_M_ l_lColumnPrimary vs AutoIncrement
                    l_cColumnDefault := oFcgi:p_o_SQLConnection:SanitizeFieldDefaultFromDefaultBehavior(par_SQLEngineType,;
                                                                                                        l_cColumnType,;
                                                                                                        iif(l_lColumnNullable,"N","")+iif(l_lColumnPrimary,"+","")+iif(l_lColumnArray,"A",""),;
                                                                                                        l_cColumnDefault)
                    if hb_IsNil(l_cColumnDefault)
                        l_cColumnDefault := ""
                    endif
                    
                    if vfp_Seek(upper(l_cColumnName)+'*',"ListOfColumnsInTable","tag1")
                        l_iColumnPk := ListOfColumnsInTable->Pk
                        l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk

                        if trim(nvl(ListOfColumnsInTable->Column_Type,""))    == l_cColumnType           .and. ;
                           nvl(ListOfColumnsInTable->Column_Array,.f.)        == l_lColumnArray          .and. ;
                           ListOfColumnsInTable->Column_Length                == l_nColumnLength         .and. ;
                           ListOfColumnsInTable->Column_Scale                 == l_nColumnScale          .and. ;
                           ListOfColumnsInTable->Column_Nullable              == l_lColumnNullable       .and. ;
                           ListOfColumnsInTable->Column_Primary               == l_lColumnPrimary        .and. ;
                           ListOfColumnsInTable->Column_Unicode               == l_lColumnUnicode        .and. ;
                           nvl(ListOfColumnsInTable->Column_Default,"")       == l_cColumnDefault        .and. ;
                           ListOfColumnsInTable->Column_LastNativeType        == l_cColumnLastNativeType .and. ;
                           ListOfColumnsInTable->Column_fk_Enumeration        == l_iFk_Enumeration

                        else
                            if ListOfColumnsInTable->Column_UseStatus >= 3  // Meaning at least marked as "Under Development"
                                //_M_ report data was not updated
                            else
                                if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInTable","Column_Type") .or. empty(ListOfColumnsInTable->Column_Type))

                                    l_iMismatchedColumns += 1
                                    AAdd(l_aListOfMessages,[Different Column Definition "]+l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName+["])

                                endif
                            endif
                        endif

                    else
                        //Missing Field, Add it
                        l_LastColumnOrder += 1

                        l_iNewColumns += 1
                        AAdd(l_aListOfMessages,[New Column "]+l_cColumnName+[" in "]+l_cLastNameSpace+"."+l_cLastTableName+["])

                    endif

                endif

            endscan

        endif

    endif

    //is_identity

case par_SQLEngineType == HB_ORM_ENGINETYPE_MSSQL
endcase





do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL

case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL

    // //--Load Indexes----------------
    // if empty(l_cErrorMessage)
    //     if !SQLExec(par_SQLHandle,l_cSQLCommandIndexes,"ListOfIndexesForLoads")
    //         l_cErrorMessage := "Failed to retrieve Fields Meta data."
    //     else
    //         // ExportTableToHtmlFile("ListOfIndexesForLoads","d:\PostgreSQL_ListOfIndexesForLoads.html","From PostgreSQL",,200,.t.)

    //         l_cLastNameSpace  := ""
    //         l_cLastTableName  := ""
    //         l_cIndexName      := ""

    //         select ListOfIndexesForLoads
    //         scan all while empty(l_cErrorMessage)
    //             if !(ListOfIndexesForLoads->schema_name == l_cLastNameSpace .and. ListOfIndexesForLoads->table_name == l_cLastTableName)
    //                 l_cLastNameSpace := ListOfIndexesForLoads->schema_name
    //                 l_cLastTableName := ListOfIndexesForLoads->table_name
    //                 l_iTablePk       := hb_HGetDef(l_hTables,l_cLastNameSpace+"."+l_cLastTableName,0)

    //                 with object l_oDB_ListOfIndexesInTable
    //                     :Table("9888318c-7195-4f75-9fbb-c102440aacd3","Index")
    //                     :Column("Index.Pk"         ,"Pk")
    //                     :Column("Index.Name"       ,"Index_Name")
    //                     :Column("Index.Unique"     ,"Index_Unique")
    //                     :Column("Index.Algo"       ,"Index_Algo")
    //                     :Column("Index.Expression" ,"Index_Expression")
    //                     :Column("upper(Index.Name)","tag1")
    //                     :Where("Index.fk_Table = ^", l_iTablePk)
    //                     :SQL("ListOfIndexesInTable")
    //                     if :Tally < 0
    //                         l_cErrorMessage := [Failed to Get index info.]
    //                     else
    //                         with object :p_oCursor
    //                             :Index("tag1","tag1+'*'")
    //                             :CreateIndexes()
    //                         endwith
    //                     endif
    //                 endwith

    //             endif

    //             if empty(l_cErrorMessage) .and. l_iTablePk > 0
    //                 l_cIndexName       := ListOfIndexesForLoads->index_name
    //                 l_cIndexExpression := ListOfIndexesForLoads->index_definition

    //                 l_lIndexUnique := ("CREATE UNIQUE INDEX" $ l_cIndexExpression)
    //                 if "USING btree" $ l_cIndexExpression
    //                     l_iIndexAlgo := 1
    //                 else
    //                     l_iIndexAlgo := 0
    //                 endif

    //                 l_nPos := at("(",l_cIndexExpression)
    //                 if l_nPos > 0
    //                     l_cIndexExpression := SubStr(l_cIndexExpression,l_nPos+1)
    //                     l_nPos := rat(")",l_cIndexExpression)
    //                     if l_nPos > 0
    //                         l_cIndexExpression := left(l_cIndexExpression,l_nPos-1)
    //                     endif
    //                 endif
                    
    //                 if vfp_Seek(upper(l_cIndexName)+'*',"ListOfIndexesInTable","tag1")
    //                     l_iIndexPk := ListOfIndexesInTable->Pk

    //                     if !(trim(nvl(ListOfIndexesInTable->Index_Name,"")) == l_cIndexName) .or. ;
    //                         ListOfIndexesInTable->Index_Unique <> l_lIndexUnique             .or. ;
    //                         ListOfIndexesInTable->Index_Algo <> l_iIndexAlgo                 .or. ;
    //                         ListOfIndexesInTable->Index_Expression <> l_cIndexExpression

    //                         l_iMismatchedIndexes += 1
    //                         AAdd(l_aListOfMessages,[Updated Index "]+l_cLastNameSpace+"."+l_cLastTableName+" "+l_cIndexName+["])

    //                     else

    //                     endif

    //                 else
    //                     //Missing Index

    //                     l_iNewIndexes += 1
    //                     AAdd(l_aListOfMessages,[Missing Index "]+l_cLastNameSpace+"."+l_cLastTableName+" "+l_cIndexName+["])

    //                 endif
    //             endif
    //         endscan
    //     endif
    // endif

case par_SQLEngineType == HB_ORM_ENGINETYPE_MSSQL

endcase


//--Report any non existing elements-----------

for each l_aEnumerationInfo in l_hCurrentListOfEnumerations
    AAdd(l_aListOfMessages,[Physical Database does not have the enumeration: "]+l_aEnumerationInfo[2]+["])
endfor

for each l_aEnumValueInfo in l_hCurrentListOfEnumValues
    AAdd(l_aListOfMessages,[Physical Database does not have the enumeration value: "]+l_aEnumValueInfo[2]+["])
endfor

for each l_aTableInfo in l_hCurrentListOfTables
    AAdd(l_aListOfMessages,[Physical Database does not have the table: "]+l_aTableInfo[2]+["])
endfor

for each l_aColumnInfo in l_hCurrentListOfColumns
    AAdd(l_aListOfMessages,[Physical Database does not have the column: "]+l_aColumnInfo[2]+["])
endfor

//--Final Return Info-----------

if empty(l_cErrorMessage)

    if !empty(l_iNewTables)         .or. ;
       !empty(l_iNewNameSpace)      .or. ;
       !empty(l_iNewColumns)        .or. ;
       !empty(l_iMismatchedColumns) .or. ;
       !empty(l_iNewEnumerations)   .or. ;
       !empty(l_iNewEnumValues)     .or. ;
       !empty(l_iNewIndexes)        .or. ;
       !empty(l_iMismatchedIndexes)

        l_cErrorMessage := "Success - Delta Result - "
        if !empty(l_iNewTables)
            l_cErrorMessage += [  New Tables: ]+trans(l_iNewTables)
        endif
        if !empty(l_iNewNameSpace)
            l_cErrorMessage += [  New Name Spaces: ]+trans(l_iNewNameSpace)
        endif
        if !empty(l_iNewColumns)
            l_cErrorMessage += [  New Columns: ]+trans(l_iNewColumns)
        endif
        if !empty(l_iMismatchedColumns)
            l_cErrorMessage += [  Mismatched Columns: ]+trans(l_iMismatchedColumns)
        endif
        if !empty(l_iNewEnumerations)
            l_cErrorMessage += [  New Enumeration: ]+trans(l_iNewEnumerations)
        endif
        if !empty(l_iNewEnumValues)
            l_cErrorMessage += [  New Enumeration Value: ]+trans(l_iNewEnumValues)
        endif
        if !empty(l_iNewIndexes)
            l_cErrorMessage += [  New Indexes: ]+trans(l_iNewIndexes)
        endif
        if !empty(l_iMismatchedIndexes)
            l_cErrorMessage += [  Mismatched Indexes: ]+trans(l_iMismatchedIndexes)
        endif
    else
        l_cErrorMessage := "Success - Delta Result"
    endif
endif

CloseAlias("ListOfFieldsForLoads")
CloseAlias("ListOfEnumsForLoads")
CloseAlias("ListOfIndexesForLoads")
CloseAlias("ListOfFieldsForeignKeys")
CloseAlias("AllTablesAsParentsForForeignKeys")
CloseAlias("AllTableColumnsChildrenForForeignKeys")

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL
    //To stop work around performance issues when querying meta database
    l_cSQLCommand := [SET enable_nestloop = true;]
    SQLExec(par_SQLHandle,l_cSQLCommand)
endcase

return {l_cErrorMessage,l_aListOfMessages}
//-----------------------------------------------------------------------------------------------------------------
