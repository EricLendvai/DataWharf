#include "DataWharf.ch"

function DeltaSchema(par_SQLHandle,par_iApplicationPk,par_SQLEngineType,par_cDatabase,par_cSyncNamespaces,par_nSyncSetForeignKey)
local l_cSQLCommand
local l_cSQLCommandEnums       := []
local l_cSQLCommandFields      := []
local l_cSQLCommandIndexes     := []
local l_cSQLCommandForeignKeys := []
local l_aNamespaces
local l_iPosition
local l_iFirstNamespace

local l_cLastNamespace
local l_cLastTableName
local l_cColumnName
local l_cEnumValueName

local l_cLastEnumerationName
local l_iNamespacePk
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
local l_lColumnUnicode
local l_cColumnDefault
local l_cColumnLastNativeTypePostgreSQL
local l_lColumnAutoIncrement
local l_cColumnAttributes
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
local l_iNewNamespace      := 0
local l_iNewColumns        := 0
local l_iNewEnumerations   := 0
local l_iNewEnumValues     := 0
local l_iMismatchedColumns := 0
local l_iNewIndexes        := 0
local l_iMismatchedIndexes := 0

local l_nPos

local l_hEnumerations := {=>}

//The following is not the most memory efficient, a 3 layer hash array would be better. 
local l_hTables       := {=>}  // The key is <Namespace>.<TableName>
local l_hColumns      := {=>}  // The key is <Namespace>.<TableName>.<ColumnName>

local l_iParentTableKey
local l_iChildColumnKey

local l_aListOfMessages := {}
local l_cExpressionNamespaces

local l_lMatchingFieldDefinition
local l_cMismatchType

local l_cCurrentColumnAttributes
local l_cCurrentColumnDefault
local l_lCurrentColumnNullable
local l_lCurrentColumnAutoIncrement

local l_nColumnUsedAs

local l_cColumnCommentType
local l_nColumnCommentLength
local l_cColumnComment
local l_nPos1
local l_nPos2
local l_nPos3

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
    l_cSQLCommandEnums := [SELECT namespaces.nspname as namespace_name,]
    l_cSQLCommandEnums += [       types.typname      as enum_name,]
    l_cSQLCommandEnums += [       enums.enumlabel    as enum_value]
    l_cSQLCommandEnums += [ FROM pg_type types]
    l_cSQLCommandEnums += [ JOIN pg_enum enums on types.oid = enums.enumtypid]
    l_cSQLCommandEnums += [ JOIN pg_catalog.pg_namespace namespaces ON namespaces.oid = types.typnamespace]
// altd()
    if !empty(par_cSyncNamespaces)
        l_cSQLCommandEnums  += [ AND lower(namespaces.nspname) in (]
        l_aNamespaces := hb_ATokens(par_cSyncNamespaces,",",.f.)
        l_iFirstNamespace := .t.
        for l_iPosition := 1 to len(l_aNamespaces)
            l_aNamespaces[l_iPosition] := strtran(l_aNamespaces[l_iPosition],['],[])
            if !empty(l_aNamespaces[l_iPosition])
                if l_iFirstNamespace
                    l_iFirstNamespace := .f.
                else
                    l_cSQLCommandEnums += [,]
                endif
                l_cSQLCommandEnums += [']+lower(l_aNamespaces[l_iPosition])+[']
            endif
        endfor
        l_cSQLCommandEnums  += [)]
    endif
    l_cSQLCommandEnums += [ ORDER BY namespace_name,enum_name;]
// hb_orm_SendToDebugView("l_cSQLCommandEnums",l_cSQLCommandEnums)


    l_cSQLCommandFields  := [WITH unlogged_tables as ]+CRLF
    l_cSQLCommandFields  += [(SELECT pg_namespace.nspname as namespace_name,]+CRLF
    l_cSQLCommandFields  += [        pg_class.relname     as table_name]+CRLF
    l_cSQLCommandFields  += [   FROM pg_class]+CRLF
    l_cSQLCommandFields  += [   inner join pg_namespace on pg_namespace.oid = pg_class.relnamespace]+CRLF
    l_cSQLCommandFields  += [   inner join pg_type      on pg_class.reltype = pg_type.oid]+CRLF
    l_cSQLCommandFields  += [   where pg_class.relpersistence = 'u']+CRLF
    l_cSQLCommandFields  += [   and   pg_type.typtype = 'c')]+CRLF

    l_cSQLCommandFields  += [SELECT columns.table_schema             AS namespace_name,]+CRLF
    l_cSQLCommandFields  += [       columns.table_name               AS table_name,]+CRLF
    l_cSQLCommandFields  += [       columns.ordinal_position         AS field_position,]+CRLF
    l_cSQLCommandFields  += [       columns.column_name              AS field_name,]+CRLF

    l_cSQLCommandFields  += [       CASE WHEN unlogged_tables.table_name IS NULL THEN false]+CRLF
    l_cSQLCommandFields  += [            ELSE true]+CRLF
    l_cSQLCommandFields  += [            END AS table_is_unlogged,]+CRLF


    // l_cSQLCommandFields  += [       columns.data_type                AS field_type,]
    // l_cSQLCommandFields  += [       element_types.data_type          AS field_type_extra,]

    l_cSQLCommandFields  += [       CASE]+CRLF
    l_cSQLCommandFields  += [          WHEN columns.data_type = 'ARRAY' THEN element_types.data_type::text]+CRLF
    l_cSQLCommandFields  += [         ELSE columns.data_type::text]+CRLF
    l_cSQLCommandFields  += [       END AS field_type,]+CRLF

    l_cSQLCommandFields  += [       pgd.description                  AS field_comment,]+CRLF

    l_cSQLCommandFields  += [       CASE]+CRLF
    l_cSQLCommandFields  += [          WHEN columns.data_type = 'ARRAY' THEN true]+CRLF
    l_cSQLCommandFields  += [         ELSE false]+CRLF
    l_cSQLCommandFields  += [       END AS field_array,]+CRLF


    l_cSQLCommandFields  += [       columns.character_maximum_length AS field_clength,]+CRLF
    l_cSQLCommandFields  += [       columns.numeric_precision        AS field_nlength,]+CRLF
    l_cSQLCommandFields  += [       columns.datetime_precision       AS field_tlength,]+CRLF
    l_cSQLCommandFields  += [       columns.numeric_scale            AS field_decimals,]+CRLF
    l_cSQLCommandFields  += [       (columns.is_nullable = 'YES')    AS field_nullable,]+CRLF
    l_cSQLCommandFields  += [       columns.Column_Default           AS field_default,]+CRLF
    l_cSQLCommandFields  += [       (columns.is_identity = 'YES')    AS field_is_identity,]+CRLF
    l_cSQLCommandFields  += [       columns.udt_name                 AS enumeration_name,]+CRLF
    l_cSQLCommandFields  += [       upper(columns.table_schema)      AS tag1,]+CRLF
    l_cSQLCommandFields  += [       upper(columns.table_name)        AS tag2]+CRLF
    l_cSQLCommandFields  += [ FROM information_schema.columns]+CRLF
    l_cSQLCommandFields  += [ INNER JOIN pg_catalog.pg_statio_all_tables AS st ON columns.table_schema = st.schemaname AND columns.table_name = st.relname]+CRLF
    l_cSQLCommandFields  += [ INNER JOIN information_schema.tables ON columns.table_catalog = columns.table_catalog AND columns.table_schema = tables.table_schema AND columns.table_name = tables.table_name]+CRLF
    l_cSQLCommandFields  += [ LEFT JOIN pg_catalog.pg_description pgd          ON pgd.objoid=st.relid AND pgd.objsubid=columns.ordinal_position]+CRLF
    l_cSQLCommandFields  += [ LEFT JOIN information_schema.element_types ON ((columns.table_catalog, columns.table_schema, columns.table_name, 'TABLE', columns.dtd_identifier) = (element_types.object_catalog, element_types.object_schema, element_types.object_name, element_types.object_type, element_types.collection_type_identifier))]+CRLF
    l_cSQLCommandFields  += [ LEFT JOIN unlogged_tables                        ON unlogged_tables.namespace_name = tables.table_schema AND unlogged_tables.table_name = tables.table_name]+CRLF
    l_cSQLCommandFields  += [ WHERE NOT (lower(left(columns.table_name,11)) = 'schemacache' OR lower(columns.table_schema) in ('information_schema','pg_catalog'))]+CRLF
    l_cSQLCommandFields  += [ AND   tables.table_type = 'BASE TABLE']+CRLF
    if !empty(par_cSyncNamespaces)
        l_cSQLCommandFields  += [ AND lower(columns.table_schema) in (]
        l_aNamespaces := hb_ATokens(par_cSyncNamespaces,",",.f.)
        l_iFirstNamespace := .t.
        for l_iPosition := 1 to len(l_aNamespaces)
            l_aNamespaces[l_iPosition] := strtran(l_aNamespaces[l_iPosition],['],[])
            if !empty(l_aNamespaces[l_iPosition])
                if l_iFirstNamespace
                    l_iFirstNamespace := .f.
                else
                    l_cSQLCommandFields += [,]
                endif
                l_cSQLCommandFields += [']+lower(l_aNamespaces[l_iPosition])+[']
            endif
        endfor
        l_cSQLCommandFields  += [)]+CRLF
    endif
    l_cSQLCommandFields  += [ ORDER BY tag1,tag2,field_position]

//hb_orm_SendToDebugView("l_cSQLCommandFields",l_cSQLCommandFields)

//SendToClipboard(l_cSQLCommandFields)

    l_cSQLCommandIndexes := [SELECT pg_indexes.schemaname        AS namespace_name,]
    l_cSQLCommandIndexes += [       pg_indexes.tablename         AS table_name,]
    l_cSQLCommandIndexes += [       pg_indexes.indexname         AS index_name,]
    l_cSQLCommandIndexes += [       pg_indexes.indexdef          AS index_definition,]
    l_cSQLCommandIndexes += [       upper(pg_indexes.schemaname) AS tag1,]
    l_cSQLCommandIndexes += [       upper(pg_indexes.tablename)  AS tag2]
    l_cSQLCommandIndexes += [ FROM pg_indexes]
    l_cSQLCommandIndexes += [ WHERE (NOT (lower(left(pg_indexes.tablename,11)) = 'schemacache' OR lower(pg_indexes.schemaname) in ('information_schema','pg_catalog')))]
    l_cSQLCommandIndexes += [ AND pg_indexes.indexname != concat(pg_indexes.tablename,'_pkey')]   // PostgreSQL always creates an index on the primary key named "<TableName>_pkey"
    l_cSQLCommandIndexes += [ ORDER BY tag1,tag2,index_name]

//--Load Enumerations-----------
    if !SQLExec(par_SQLHandle,l_cSQLCommandEnums,"ListOfEnumsForLoads")
        l_cErrorMessage := "Failed to retrieve Enumeration Meta data."
    else
        // ExportTableToHtmlFile("ListOfEnumsForLoads",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfEnumsForLoads.html","From PostgreSQL",,200,.t.)

        l_cExpressionNamespaces := ""
        if !empty(par_cSyncNamespaces)
            l_cExpressionNamespaces := [lower(Namespace.Name) in (]
            l_aNamespaces := hb_ATokens(par_cSyncNamespaces,",",.f.)
            l_iFirstNamespace := .t.
            for l_iPosition := 1 to len(l_aNamespaces)
                l_aNamespaces[l_iPosition] := strtran(l_aNamespaces[l_iPosition],['],[])
                if !empty(l_aNamespaces[l_iPosition])
                    if l_iFirstNamespace
                        l_iFirstNamespace := .f.
                    else
                        l_cExpressionNamespaces += [,]
                    endif
                    l_cExpressionNamespaces += [']+lower(l_aNamespaces[l_iPosition])+[']
                endif
            endfor
            l_cExpressionNamespaces  += [)]
        endif



        with object l_oDB1
            :Table("77f9c695-656a-4f08-9f3b-0b9f255cae6d","Namespace")
            :Column("Enumeration.Pk"          , "Enumeration_Pk")
            :Column("Namespace.Name"          , "Namespace_Name")
            :Column("Enumeration.Name"        , "Enumeration_Name")
            :Column("Enumeration.UseStatus"   , "Enumeration_UseStatus")
            :Column("upper(Namespace.Name)"   , "tag1")
            :Column("upper(Enumeration.Name)" , "tag2")
            :Join("inner","Enumeration","","Enumeration.fk_Namespace = Namespace.pk")
            :Where([Namespace.fk_Application = ^],par_iApplicationPk)
            :Where("Enumeration.ImplementAs = ^", ENUMERATIONIMPLEMENTAS_NATIVESQLENUM)  // Only test on Native SQL Enum
            if !empty(l_cExpressionNamespaces)
                :Where(l_cExpressionNamespaces)
            endif
            :OrderBy("tag1")
            :OrderBy("tag2")

// :Where("Enumeration.UseStatus != ^",USESTATUS_DISCONTINUED)

            :SQL("ListOfEnumerations")
            select ListOfEnumerations
            scan all
                l_hCurrentListOfEnumerations[ListOfEnumerations->Namespace_Name+"*"+ListOfEnumerations->Enumeration_Name+"*"] := {ListOfEnumerations->Enumeration_Pk,;
                                                                                                                                  ListOfEnumerations->Namespace_Name+"."+ListOfEnumerations->Enumeration_Name,;
                                                                                                                                  ListOfEnumerations->Enumeration_UseStatus}
            endscan

            :Table("991803aa-7329-4c7a-bd22-171da990a6a6","Namespace")
            :Column("Table.Pk"              , "Table_Pk")
            :Column("Namespace.Name"        , "Namespace_Name")
            :Column("Table.Name"            , "Table_Name")
            :Column("Table.UseStatus"       , "Table_UseStatus")
            :Column("upper(Namespace.Name)" , "tag1")
            :Column("upper(Table.Name)"     , "tag2")
            :Join("inner","Table","","Table.fk_Namespace = Namespace.pk")
            :Where([Namespace.fk_Application = ^],par_iApplicationPk)
            if !empty(l_cExpressionNamespaces)
                :Where(l_cExpressionNamespaces)
            endif
            :OrderBy("tag1")
            :OrderBy("tag2")

// :Where("Table.UseStatus != ^",USESTATUS_DISCONTINUED)

            :SQL("ListOfTables")
            select ListOfTables
            scan all
                l_hCurrentListOfTables[ListOfTables->Namespace_Name+"*"+ListOfTables->Table_Name+"*"] := {ListOfTables->Table_Pk,;
                                                                                                          ListOfTables->Namespace_Name+"."+ListOfTables->Table_Name,;
                                                                                                          ListOfTables->Table_UseStatus}
            endscan

        endwith


        l_cLastNamespace       := ""
        l_cLastEnumerationName := ""
        l_cEnumValueName       := ""

        select ListOfEnumsForLoads
        scan all while empty(l_cErrorMessage)
            if !(ListOfEnumsForLoads->namespace_name == l_cLastNamespace .and. ListOfEnumsForLoads->enum_name == l_cLastEnumerationName)
                //New Enumeration being defined
                //Check if the Enumeration already on file

                l_cLastNamespace       := ListOfEnumsForLoads->namespace_name
                l_cLastEnumerationName := ListOfEnumsForLoads->enum_name
                l_iNamespacePk         := -1
                l_iEnumerationPk       := -1

                with object l_oDB1
                    :Table("b9de5e1b-bfd9-4c18-a4af-96ca5873160d","Enumeration")
                    :Column("Enumeration.fk_Namespace", "fk_Namespace")
                    :Column("Enumeration.pk"          , "Pk")
                    :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
                    :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                    :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cLastNamespace," ","")))
                    :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cLastEnumerationName," ","")))
                    l_aSQLResult := {}
                    :SQL(@l_aSQLResult)

                    do case
                    case :Tally == -1  //Failed to query
                        l_cErrorMessage := "Failed to Query Meta database. Error 101."
                        exit
                    case empty(:Tally)
                        //Enumerations is not in datadic, load it.
                        //Find the Namespace
                        :Table("2e160bfe-dcc3-46dd-b263-cfa86b9ee0b7","Namespace")
                        :Column("Namespace.pk"          , "Pk")
                        :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                        :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cLastNamespace," ","")))
                        l_aSQLResult := {}
                        :SQL(@l_aSQLResult)

                        do case
                        case :Tally == -1  //Failed to query
                            l_cErrorMessage := "Failed to Query Meta database. Error 102."
                        case empty(:Tally)
                            l_iNewNamespace += 1
                            AAdd(l_aListOfMessages,[New Namespace "]+l_cLastNamespace+["])

                        case :Tally == 1
                            l_iNamespacePk := l_aSQLResult[1,1]
                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 103."
                        endcase

                        l_iNewEnumerations += 1
                        AAdd(l_aListOfMessages,[New Enumeration "]+l_cLastEnumerationName+[" in Namespace "]+l_cLastNamespace+["])

                    case :Tally == 1
                        l_iNamespacePk   := l_aSQLResult[1,1]
                        l_iEnumerationPk := l_aSQLResult[1,2]
                        l_hEnumerations[l_cLastNamespace+"."+l_cLastEnumerationName] := l_iEnumerationPk   //_M_ is this needed?

                        hb_HDel(l_hCurrentListOfEnumerations,l_cLastNamespace+"*"+l_cLastEnumerationName+"*")

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
                        :Column("EnumValue.UseStatus"   , "EnumValue_UseStatus")
                        :Column("upper(EnumValue.Name)" , "tag1")
                        :Where("EnumValue.fk_Enumeration = ^" , l_iEnumerationPk)
                        :OrderBy("EnumValue_Order") //,"Desc"

// :Where("EnumValue.UseStatus != ^",USESTATUS_DISCONTINUED)

                        :SQL("ListOfEnumValuesInEnumeration")

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data EnumValue. Error 106."
                        else
                            if :Tally == 0
                                l_LastEnumValueOrder := 0
                            else
                                select ListOfEnumValuesInEnumeration
                                scan all
                                    l_hCurrentListOfEnumValues[l_cLastNamespace+"*"+l_cLastEnumerationName+"*"+ListOfEnumValuesInEnumeration->EnumValue_Name+"*"] := {ListOfEnumValuesInEnumeration->Pk,;
                                                                                                                                                                      l_cLastNamespace+"."+l_cLastEnumerationName+"."+ListOfEnumValuesInEnumeration->EnumValue_Name,;
                                                                                                                                                                      ListOfEnumValuesInEnumeration->EnumValue_UseStatus}
                                    l_LastEnumValueOrder := ListOfEnumValuesInEnumeration->EnumValue_Order   // since Ascending now, the last loop will have the biggest value
                                endscan
                            endif

                            with object :p_oCursor
                                :Index("tag1","padr(tag1+'*',240)")
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

                hb_HDel(l_hCurrentListOfEnumValues,l_cLastNamespace+"*"+l_cLastEnumerationName+"*"+l_cEnumValueName+"*")

                if !used("ListOfEnumValuesInEnumeration") .or. !el_seek(upper(l_cEnumValueName)+'*',"ListOfEnumValuesInEnumeration","tag1")
                    //Missing EnumValue, Add it

                    l_iNewEnumValues += 1
                    AAdd(l_aListOfMessages,[New Enumeration Value "]+l_cEnumValueName+[" in "]+l_cLastNamespace+"."+l_cLastEnumerationName+["])

                endif

            endif

        endscan

    endif


//--Load Tables-----------
    if empty(l_cErrorMessage)
        if !SQLExec(par_SQLHandle,l_cSQLCommandFields,"ListOfFieldsForLoads")
            l_cErrorMessage := "Failed to retrieve Fields Meta data."
        else
            // ExportTableToHtmlFile("ListOfFieldsForLoads",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfFieldsForLoads.html","From PostgreSQL",,200,.t.)

            l_cLastNamespace  := ""
            l_cLastTableName  := ""
            l_cColumnName     := ""

            select ListOfFieldsForLoads
            scan all while empty(l_cErrorMessage)
                if !(ListOfFieldsForLoads->namespace_name == l_cLastNamespace .and. ListOfFieldsForLoads->table_name == l_cLastTableName)
                    //New Table being defined
                    //Check if the table already on file

                    l_cLastNamespace := ListOfFieldsForLoads->namespace_name
                    l_cLastTableName := ListOfFieldsForLoads->table_name
                    l_iNamespacePk   := -1
                    l_iTablePk       := -1

                    with object l_oDB1
                        :Table("7c364883-b3ee-4828-953c-69316d5e0e03","Table")
                        :Column("Table.fk_Namespace", "fk_Namespace")
                        :Column("Table.pk"          , "Pk")
                        :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
                        :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                        :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cLastNamespace," ","")))
                        :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cLastTableName," ","")))
                        l_aSQLResult := {}
                        :SQL(@l_aSQLResult)

                        do case
                        case :Tally == -1  //Failed to query
                            l_cErrorMessage := "Failed to Query Meta database. Error 101."
                            exit
                        case empty(:Tally)
                            //Tables is not in datadic, load it.
                            //Find the Namespace
                            :Tabl("0b38bd6e-f72d-4c15-92dc-b6bbacafbbc3","Namespace")
                            :Column("Namespace.pk" , "Pk")
                            :Where([Namespace.fk_Application = ^],par_iApplicationPk)
                            :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cLastNamespace," ","")))
                            l_aSQLResult := {}
                            :SQL(@l_aSQLResult)

                            do case
                            case :Tally == -1  //Failed to query
                                l_cErrorMessage := "Failed to Query Meta database. Error 102."
                            case empty(:Tally)
                                //Add the Namespace

                                l_iNewNamespace += 1
                                AAdd(l_aListOfMessages,[New Namespace "]+l_cLastNamespace+["])

                            case :Tally == 1
                                l_iNamespacePk := l_aSQLResult[1,1]
                            otherwise
                                l_cErrorMessage := "Failed to Query Meta database. Error 103."
                            endcase

                            if l_iNamespacePk > 0

                                l_iNewTables += 1
                                AAdd(l_aListOfMessages,[New Table "]+l_cLastTableName+[" in Namespace "]+l_cLastNamespace+["])

                            endif

                        case :Tally == 1
                            l_iNamespacePk   := l_aSQLResult[1,1]
                            l_iTablePk       := l_aSQLResult[1,2]
                            l_hTables[l_cLastNamespace+"."+l_cLastTableName] := l_iTablePk

                            hb_HDel(l_hCurrentListOfTables,l_cLastNamespace+"*"+l_cLastTableName+"*")

                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 104."
                        endcase

                    endwith

                    // Load all the Table current Columns
                    with object l_oDB_ListOfColumnsInTable
                        :Table("088a71c4-f56d-4b18-8dc9-df25eee291f8","Column")
                        :Column("Column.Pk"                       , "Pk")
                        :Column("Column.Order"                    , "Column_Order")
                        :Column("Column.Name"                     , "Column_Name")
                        :Column("upper(Column.Name)"              , "tag1")
                        :Column("Column.UsedAs"                   , "Column_UsedAs")
                        :Column("Column.Type"                     , "Column_Type")
                        :Column("Column.Array"                    , "Column_Array")
                        :Column("Column.Length"                   , "Column_Length")
                        :Column("Column.Scale"                    , "Column_Scale")
                        :Column("Column.Nullable"                 , "Column_Nullable")
                        :Column("Column.Unicode"                  , "Column_Unicode")
                        :Column("Column.DefaultType"              , "Column_DefaultType")
                        :Column("Column.DefaultCustom"            , "Column_DefaultCustom")
                        :Column("Column.LastNativeTypePostgreSQL" , "Column_LastNativeTypePostgreSQL")
                        :Column("Column.fk_Enumeration"           , "Column_fk_Enumeration")
                        :Column("Column.UseStatus"                , "Column_UseStatus")
                        :Where("Column.fk_Table = ^" , l_iTablePk)
                        :OrderBy("Column_Order") // ,"Desc"

                        :Join("left","Enumeration","","Column.fk_Enumeration = Enumeration.pk")
                        :Column("Enumeration.ImplementAs"     , "Enumeration_ImplementAs")    // 1 = Native SQL Enum, 2 = Integer, 3 = Numeric, 4 = Var Char (EnumValue Name)
                        :Column("Enumeration.ImplementLength" , "Enumeration_ImplementLength")

// :Where("Column.UseStatus != ^"     ,USESTATUS_DISCONTINUED)
// :Where("Enumeration.UseStatus != ^",USESTATUS_DISCONTINUED)
//123456
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
                                    if ListOfColumnsInTable->Column_UseStatus != USESTATUS_DISCONTINUED
                                        l_hCurrentListOfColumns[l_cLastNamespace+"*"+l_cLastTableName+"*"+ListOfColumnsInTable->Column_Name+"*"] := {ListOfColumnsInTable->Pk,;
                                                                                                                                                     l_cLastNamespace+"."+l_cLastTableName+"."+ListOfColumnsInTable->Column_Name,;
                                                                                                                                                     ListOfColumnsInTable->Column_UseStatus}
                                        l_LastColumnOrder := ListOfColumnsInTable->Column_Order   // since Ascending now, the last loop will have the biggest value
                                    endif
                                endscan
                            endif

                            with object :p_oCursor
                                :Index("tag1","padr(tag1+'*',240)")
                                :CreateIndexes()
                            endwith

                        endif

                    endwith

                endif

                if empty(l_cErrorMessage)
                    //Check existence of Column and add if needed
                    //Get the column Name, Type, Length, Scale, Nullable and fk_Enumeration
                    l_cColumnName           := alltrim(ListOfFieldsForLoads->field_name)
                    hb_HDel(l_hCurrentListOfColumns,l_cLastNamespace+"*"+l_cLastTableName+"*"+l_cColumnName+"*")

                    l_lColumnNullable                 := ListOfFieldsForLoads->field_nullable      // Since the information_schema does not follow odbc driver setting to return boolean as logical
                    l_lColumnUnicode                  := .f.
                    l_cColumnDefault                  := nvl(ListOfFieldsForLoads->field_default,"")
                    l_lColumnArray                    := ListOfFieldsForLoads->field_array
                    l_cColumnLastNativeTypePostgreSQL := nvl(ListOfFieldsForLoads->field_type,"")
                    if l_cColumnDefault == "NULL"
                        l_cColumnDefault := ""
                    endif
                    l_cColumnDefault  := strtran(l_cColumnDefault,"::"+l_cColumnLastNativeTypePostgreSQL,"")  //Remove casting to the same field type. (PostgreSQL specific behavior)
                    l_cColumnLastNativeTypePostgreSQL := l_cColumnLastNativeTypePostgreSQL + iif(l_lColumnArray,"[]","")
                    
                    if l_cColumnLastNativeTypePostgreSQL == "character"
                        l_cColumnDefault := strtran(l_cColumnDefault,"::bpchar","")
                    endif
                    if !hb_orm_isnull("ListOfFieldsForLoads","enumeration_name")
                        l_cColumnDefault := strtran(l_cColumnDefault,[::"]+ListOfFieldsForLoads->enumeration_name+["],"")
                        l_cColumnDefault := strtran(l_cColumnDefault,[::]+ListOfFieldsForLoads->enumeration_name,"")   // Some previous versions of Postgresql will or will not have double quotes around the entity name.
                    endif

                    l_iFk_Enumeration := 0



// local l_cColumnCommentType
// local l_nColumnCommentLength
// local l_cColumnComment
// local l_nPos1
// local l_nPos2
// local l_nPos3






        //Parse the comment field to see if recorded the field type and its length
        l_cColumnCommentType   := ""
        l_nColumnCommentLength := 0
        l_cColumnComment := nvl(ListOfFieldsForLoads->field_comment,"")
        l_cColumnComment := upper(MemoLine(l_cColumnComment,1000,1))  // Extract first line of comment, max 1000 char length.   example:  Type=BV|Length=5  or Type=TOZ
        if !empty(l_cColumnComment) 
            l_nPos1 := at("|",l_cColumnComment)
            l_nPos2 := at("TYPE=",l_cColumnComment)
            l_nPos3 := at("LENGTH=",l_cColumnComment)
            if l_nPos1 > 0 .and. l_nPos2 > 0 .and. l_nPos3 > 0
                l_cColumnCommentType   := Alltrim(substr(l_cColumnComment,l_nPos2+len("TYPE="),l_nPos1-(l_nPos2+len("TYPE="))))
                l_nColumnCommentLength := Val(substr(l_cColumnComment,l_nPos3+len("LENGTH=")))
            elseif l_nPos2 > 0
                l_cColumnCommentType   := Alltrim(substr(l_cColumnComment,l_nPos2+len("TYPE=")))
                l_nColumnCommentLength := 0
            endif
        endif


//FieldComment



                    // if ListOfFieldsForLoads->field_type == "USER-DEFINED"
                    //     altd()
                    // endif

                    // l_lColumnArray := (ListOfFieldsForLoads->field_type == "ARRAY")
                    // switch iif(ListOfFieldsForLoads->field_type == "ARRAY",nvl(ListOfFieldsForLoads->field_type_extra,"unknown"),ListOfFieldsForLoads->field_type)

                    switch lower(ListOfFieldsForLoads->field_type)
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

                    case "smallint"
                        l_cColumnType   := "IS"
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
                        do case
                        case l_cColumnCommentType == "B"  .and. l_nColumnCommentLength > 0    // Binary fixed length
                            l_cColumnType   := "B"
                            l_nColumnLength := l_nColumnCommentLength
                            l_nColumnScale  := 0
                        case l_cColumnCommentType == "BV" .and. l_nColumnCommentLength > 0    // Binary variable length
                            l_cColumnType   := "BV"
                            l_nColumnLength := l_nColumnCommentLength
                            l_nColumnScale  := 0
                        otherwise 
                            l_cColumnType   := "R"
                            l_nColumnLength := NIL
                            l_nColumnScale  := NIL
                        endcase
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

                    case "jsonb"
                        l_cColumnType   := "JSB"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "json"
                        l_cColumnType   := "JS"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "oid"
                        l_cColumnType   := "OID"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "user-defined"
                        l_cColumnType   := "E"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL

                        l_iFk_Enumeration := hb_HGetDef(l_hEnumerations,l_cLastNamespace+"."+alltrim(ListOfFieldsForLoads->enumeration_name),0)
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

                    // _M_ for now will assume identity fields are Primary Keys and are auto-increment.
                    if ListOfFieldsForLoads->field_is_identity
                        l_nColumnUsedAs = 2
                    else
                        l_nColumnUsedAs = 1
                    endif

                    l_cColumnDefault := oFcgi:p_o_SQLConnection:NormalizeFieldDefaultForCurrentEngineType(l_cColumnDefault,l_cColumnType,l_nColumnScale)
                    l_cColumnDefault := oFcgi:p_o_SQLConnection:SanitizeFieldDefaultFromDefaultBehavior(par_SQLEngineType,;
                                                                                                              l_cColumnType,;
                                                                                                              l_lColumnNullable,;
                                                                                                              l_cColumnDefault)
                    if hb_IsNil(l_cColumnDefault)
                        l_cColumnDefault := ""
                    endif
                    
                    if el_seek(upper(l_cColumnName)+'*',"ListOfColumnsInTable","tag1")
                        if ListOfColumnsInTable->Column_UseStatus == USESTATUS_DISCONTINUED
                            //Ignore the field. Still had to be aware of it, so not to try to re-add it
                        else
                            l_iColumnPk := ListOfColumnsInTable->Pk
                            l_hColumns[l_cLastNamespace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk

                            // In case the field is marked as an Enumeration, but is actually stored as an integer or numeric
                            if alltrim(nvl(ListOfColumnsInTable->Column_Type,"")) == "E"
                                do case
                                case nvl(ListOfColumnsInTable->Enumeration_ImplementAs,0) == ENUMERATIONIMPLEMENTAS_INTEGER
                                    ListOfColumnsInTable->Column_Type           := "I"
                                    ListOfColumnsInTable->Column_Length         := nil
                                    ListOfColumnsInTable->Column_Scale          := nil
                                    ListOfColumnsInTable->Column_fk_Enumeration := 0
                                case nvl(ListOfColumnsInTable->Enumeration_ImplementAs,0) == ENUMERATIONIMPLEMENTAS_NUMERIC
                                    ListOfColumnsInTable->Column_Type           := "N"
                                    ListOfColumnsInTable->Column_Length         := nvl(ListOfColumnsInTable->Enumeration_ImplementLength,0)
                                    ListOfColumnsInTable->Column_Scale          := 0
                                    ListOfColumnsInTable->Column_fk_Enumeration := 0
                                endcase
                            endif

                            //---------------------------------------------------
                            l_lColumnAutoIncrement := (l_nColumnUsedAs = 2) // _M_ ("+" $ l_cCurrentColumnAttributes)
                            if l_lColumnAutoIncrement .and. empty(el_InlistPos(l_cColumnType,"I","IB","IS"))  //Only those fields types may be flagged as Auto-Increment
                                l_lColumnAutoIncrement := .f.
                            endif
                            if l_lColumnAutoIncrement .and. l_lColumnNullable  //Auto-Increment fields may not be null (and not have a default)
                                l_lColumnNullable := .f.
                            endif
                            l_cColumnAttributes := iif(l_lColumnNullable,"N","")+iif(l_lColumnAutoIncrement,"+","")+iif(l_lColumnArray,"A","")
                            //---------------------------------------------------

                            l_cCurrentColumnDefault := GetColumnDefault(.f.,ListOfColumnsInTable->Column_Type,ListOfColumnsInTable->Column_DefaultType,ListOfColumnsInTable->Column_DefaultCustom)
                            l_cCurrentColumnDefault := oFcgi:p_o_SQLConnection:NormalizeFieldDefaultForCurrentEngineType(l_cCurrentColumnDefault,alltrim(ListOfColumnsInTable->Column_Type),ListOfColumnsInTable->Column_Scale)
                            l_cCurrentColumnDefault := oFcgi:p_o_SQLConnection:SanitizeFieldDefaultFromDefaultBehavior(par_SQLEngineType,;
                                                                                                                    alltrim(ListOfColumnsInTable->Column_Type),;
                                                                                                                    ListOfColumnsInTable->Column_Nullable,;
                                                                                                                    l_cCurrentColumnDefault)
                            if hb_IsNil(l_cCurrentColumnDefault)
                                l_cCurrentColumnDefault := ""
                            endif

                            l_lCurrentColumnNullable      := ListOfColumnsInTable->Column_Nullable
                            l_lCurrentColumnAutoIncrement := (ListOfColumnsInTable->Column_UsedAs = 2) // _M_ ("+" $ l_cCurrentColumnAttributes)
                            if l_lCurrentColumnAutoIncrement .and. empty(el_InlistPos(alltrim(ListOfColumnsInTable->Column_Type),"I","IB","IS"))  //Only those fields types may be flagged as Auto-Increment
                                l_lCurrentColumnAutoIncrement := .f.
                            endif
                            if l_lCurrentColumnAutoIncrement .and. l_lCurrentColumnNullable  //Auto-Increment fields may not be null (and not have a default)
                                l_lCurrentColumnNullable := .f.
                            endif
                            l_cCurrentColumnAttributes := iif(l_lCurrentColumnNullable,"N","")+iif(l_lCurrentColumnAutoIncrement,"+","")+iif(ListOfColumnsInTable->Column_Array,"A","")
                            //---------------------------------------------------

                            l_lMatchingFieldDefinition := .t.
                            l_cMismatchType := ""

                            do case
                            case !(l_cColumnType == alltrim(ListOfColumnsInTable->Column_Type))   // Field Type is always defined.  !(==) is a method to deal with SET EXACT being OFF by default.
                                l_lMatchingFieldDefinition := .f.
                                l_cMismatchType := "Field Type"
                            case l_lColumnArray != ListOfColumnsInTable->Column_Array
                                l_lMatchingFieldDefinition := .f.
                                l_cMismatchType := "Field Array"
                            case el_IsInlist(l_cColumnType,"I","IB","IS","M","R","L","D","Y","UUI","JS","JSB","OID")   //Field type with no length
                            case empty(el_InlistPos(l_cColumnType,"TOZ","TO","DTZ","DT")) .and. l_nColumnLength <> ListOfColumnsInTable->Column_Length   //Ignore Length matching for datetime and time fields
                                l_lMatchingFieldDefinition := .f.
                                l_cMismatchType := "Field Length"
                            case el_IsInlist(l_cColumnType,"C","CV","B","BV")   //Field type with a length but no decimal
                            case nvl(l_nColumnScale,0)  <> nvl(ListOfColumnsInTable->Column_Scale,0)
                                l_lMatchingFieldDefinition := .f.
                                l_cMismatchType := "Field Decimal"
                            endcase

                            if l_lMatchingFieldDefinition  // _M_ Should still test on nullable and incremental

                                if l_lColumnAutoIncrement .and. el_IsInlist(l_cCurrentColumnDefault,"Wharf-AutoIncrement()","AutoIncrement()")
                                    l_cCurrentColumnDefault := ""
                                endif

                                do case
                                case !(l_cColumnAttributes == l_cCurrentColumnAttributes)
                                    l_lMatchingFieldDefinition := .f.
                                    l_cMismatchType := "Field Attribute"
                                case !(l_cColumnDefault == l_cCurrentColumnDefault)
// altd()
                                    l_lMatchingFieldDefinition := .f.
                                    l_cMismatchType := "Field Default Value"
                                endcase
                            endif

                            if !empty(l_cMismatchType)
                                if ListOfColumnsInTable->Column_UseStatus >= USESTATUS_UNDERDEVELOPMENT  // Meaning at least marked as "Under Development"
                                    //_M_ report data was not updated
                                else
                                    if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInTable","Column_Type") .or. empty(alltrim(ListOfColumnsInTable->Column_Type)))
                                        l_iMismatchedColumns += 1
                                        AAdd(l_aListOfMessages,[Different Column Definition "]+l_cLastNamespace+"."+l_cLastTableName+"."+l_cColumnName+[" - ]+l_cMismatchType)

                                    endif
                                endif
                            endif
                        endif

                    else
                        //Missing Field, Add it
                        l_LastColumnOrder += 1

                        l_iNewColumns += 1
                        AAdd(l_aListOfMessages,[New Column "]+l_cColumnName+[" in "]+l_cLastNamespace+"."+l_cLastTableName+["])

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
    //         // ExportTableToHtmlFile("ListOfIndexesForLoads",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfIndexesForLoads.html","From PostgreSQL",,200,.t.)

    //         l_cLastNamespace  := ""
    //         l_cLastTableName  := ""
    //         l_cIndexName      := ""

    //         select ListOfIndexesForLoads
    //         scan all while empty(l_cErrorMessage)
    //             if !(ListOfIndexesForLoads->namespace_name == l_cLastNamespace .and. ListOfIndexesForLoads->table_name == l_cLastTableName)
    //                 l_cLastNamespace := ListOfIndexesForLoads->namespace_name
    //                 l_cLastTableName := ListOfIndexesForLoads->table_name
    //                 l_iTablePk       := hb_HGetDef(l_hTables,l_cLastNamespace+"."+l_cLastTableName,0)

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
    //                             :Index("tag1","padr(tag1+'*',240)")
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
                    
    //                 if el_seek(upper(l_cIndexName)+'*',"ListOfIndexesInTable","tag1")
    //                     l_iIndexPk := ListOfIndexesInTable->Pk

    //                     if !(trim(nvl(ListOfIndexesInTable->Index_Name,"")) == l_cIndexName) .or. ;
    //                         ListOfIndexesInTable->Index_Unique <> l_lIndexUnique             .or. ;
    //                         ListOfIndexesInTable->Index_Algo <> l_iIndexAlgo                 .or. ;
    //                         ListOfIndexesInTable->Index_Expression <> l_cIndexExpression

    //                         l_iMismatchedIndexes += 1
    //                         AAdd(l_aListOfMessages,[Updated Index "]+l_cLastNamespace+"."+l_cLastTableName+" "+l_cIndexName+["])

    //                     else

    //                     endif

    //                 else
    //                     //Missing Index

    //                     l_iNewIndexes += 1
    //                     AAdd(l_aListOfMessages,[Missing Index "]+l_cLastNamespace+"."+l_cLastTableName+" "+l_cIndexName+["])

    //                 endif
    //             endif
    //         endscan
    //     endif
    // endif

case par_SQLEngineType == HB_ORM_ENGINETYPE_MSSQL

endcase


//--Report any non existing elements-----------
if empty(l_cErrorMessage)
    for each l_aEnumerationInfo in l_hCurrentListOfEnumerations
        if !(l_aEnumerationInfo[3] == USESTATUS_PROPOSED .or. l_aEnumerationInfo[3] == USESTATUS_DISCONTINUED)
            AAdd(l_aListOfMessages,[Physical Database does not have the enumeration: "]+l_aEnumerationInfo[2]+["])
        endif
    endfor

    for each l_aEnumValueInfo in l_hCurrentListOfEnumValues
        if !(l_aEnumValueInfo[3] == USESTATUS_PROPOSED .or. l_aEnumValueInfo[3] == USESTATUS_DISCONTINUED)
            AAdd(l_aListOfMessages,[Physical Database does not have the enumeration value: "]+l_aEnumValueInfo[2]+["])
        endif
    endfor

    for each l_aTableInfo in l_hCurrentListOfTables
        if !(l_aTableInfo[3] == USESTATUS_PROPOSED .or. l_aTableInfo[3] == USESTATUS_DISCONTINUED)
            AAdd(l_aListOfMessages,[Physical Database does not have the table: "]+l_aTableInfo[2]+["])
        endif
    endfor

    for each l_aColumnInfo in l_hCurrentListOfColumns
        if !(l_aColumnInfo[3] == USESTATUS_PROPOSED .or. l_aColumnInfo[3] == USESTATUS_DISCONTINUED)
            AAdd(l_aListOfMessages,[Physical Database does not have the column: "]+l_aColumnInfo[2]+["])
        endif
    endfor
endif

//--Final Return Info-----------

if empty(l_cErrorMessage)

    if !empty(l_iNewTables)         .or. ;
       !empty(l_iNewNamespace)      .or. ;
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
        if !empty(l_iNewNamespace)
            l_cErrorMessage += [  New Namespaces: ]+trans(l_iNewNamespace)
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
