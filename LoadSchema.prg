#include "DataWharf.ch"

function LoadSchema(par_SQLHandle,par_iApplicationPk,par_SQLEngineType,par_cDatabase,par_cSyncNameSpaces,par_nSyncSetForeignKey)
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

local l_oDB1
local l_oDB2

local l_oDB_AllTablesAsParentsForForeignKeys
local l_oDB_AllTableColumnsChildrenForForeignKeys

local l_aSQLResult := {}
local l_cErrorMessage := ""

local l_iNewTables       := 0
local l_iNewNameSpace    := 0
local l_iNewColumns      := 0
local l_iNewEnumerations := 0
local l_iNewEnumValues   := 0
local l_iUpdatedColumns  := 0
local l_iNewIndexes      := 0
local l_iUpdatedIndexes  := 0

local l_nPos

local l_hEnumerations := {=>}

//The following is not the most memory efficient, a 3 layer hash array would be better. 
local l_hTables       := {=>}  // The key is <NameSpace>.<TableName>
local l_hColumns      := {=>}  // The key is <NameSpace>.<TableName>.<ColumnName>

local l_iParentTableKey
local l_iChildColumnKey

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL
    //To work around performance issues when querying meta database
    l_cSQLCommand := [SET enable_nestloop = false;]
    SQLExec(par_SQLHandle,l_cSQLCommand)
endcase

// If switching to MySQL to store our own tables, have to deal with variables/fields: IndexUnique, ColumnNullable

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

///////////////////////////////===========================================================================================================

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
    l_cSQLCommandFields  += [SELECT "public"                           AS schema_name,]
    l_cSQLCommandFields  += [       columns.table_name                 AS table_name,]
    l_cSQLCommandFields  += [       columns.ordinal_position           AS field_position,]
    l_cSQLCommandFields  += [       columns.column_name                AS field_name,]
    l_cSQLCommandFields  += [       columns.data_type                  AS field_type,]
    l_cSQLCommandFields  += [       columns.column_comment             AS field_comment,]
    l_cSQLCommandFields  += [       columns.character_maximum_length   AS field_clength,]
    l_cSQLCommandFields  += [       columns.numeric_precision          AS field_nlength,]
    l_cSQLCommandFields  += [       columns.datetime_precision         AS field_tlength,]
    l_cSQLCommandFields  += [       columns.numeric_scale              AS field_decimals,]
    l_cSQLCommandFields  += [       (columns.is_nullable = 'YES')      AS field_nullable,]
    l_cSQLCommandFields  += [       columns.column_default             AS field_default,]
    l_cSQLCommandFields  += [       (columns.extra = 'auto_increment') AS field_is_identity,]
    l_cSQLCommandFields  += [       upper(columns.table_name)          AS tag1]
    l_cSQLCommandFields  += [ FROM information_schema.columns]
    l_cSQLCommandFields  += [ WHERE columns.table_schema = ']+par_cDatabase+[']
    l_cSQLCommandFields  += [ AND   lower(left(columns.table_name,11)) != 'schemacache']
    l_cSQLCommandFields  += [ ORDER BY tag1,field_position]
    
//_M_ not as postgresql
    l_cSQLCommandIndexes += [SELECT "public" AS schema_name,]
    l_cSQLCommandIndexes += [       table_name,]
    l_cSQLCommandIndexes += [       index_name,]
    l_cSQLCommandIndexes += [       group_concat(column_name order by seq_in_index) AS index_columns,]
    l_cSQLCommandIndexes += [       index_type,]
    l_cSQLCommandIndexes += [       CASE non_unique]
    l_cSQLCommandIndexes += [            WHEN 1 then 0]
    l_cSQLCommandIndexes += [            ELSE 1]
    l_cSQLCommandIndexes += [            END AS is_unique]
    l_cSQLCommandIndexes += [ FROM information_schema.statistics]
    l_cSQLCommandIndexes += [ WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')]
    l_cSQLCommandIndexes += [ AND   index_schema = ']+par_cDatabase+[']
    l_cSQLCommandIndexes += [ AND   lower(left(table_name,11)) != 'schemacache']
    l_cSQLCommandIndexes += [ GROUP BY table_name,index_name]
    l_cSQLCommandIndexes += [ ORDER BY index_schema,table_name,index_name;]

    // l_cSQLCommandForeignKeys += [SELECT CONCAT('public.',lower(TABLE_NAME))  AS childtablename,]
    // l_cSQLCommandForeignKeys += [       lower(COLUMN_NAME) AS childcolumnname,]
    // l_cSQLCommandForeignKeys += [       CONCAT('public.',lower(REFERENCED_TABLE_NAME)) AS parenttablename]
    // l_cSQLCommandForeignKeys += [ FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE]
    // l_cSQLCommandForeignKeys += [ WHERE REFERENCED_TABLE_SCHEMA = ']+par_cDatabase+[']

    // l_cSQLCommandForeignKeys += [SELECT concat('*public*',lower(TABLE_NAME),'*',lower(COLUMN_NAME),'*')  AS childcolumn,]
    // l_cSQLCommandForeignKeys += [       concat(*public*',lower(REFERENCED_TABLE_NAME),'*') AS parenttable]
    // l_cSQLCommandForeignKeys += [ FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE]
    // l_cSQLCommandForeignKeys += [ WHERE REFERENCED_TABLE_SCHEMA = ']+par_cDatabase+[']

    l_cSQLCommandForeignKeys += [SELECT cast(concat('*public*',lower(TABLE_NAME),'*',lower(COLUMN_NAME),'*') AS CHAR(255)) AS childcolumn,]
    l_cSQLCommandForeignKeys += [       cast(concat('*public*',lower(REFERENCED_TABLE_NAME),'*')             AS CHAR(255)) AS parenttable]
    l_cSQLCommandForeignKeys += [ FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE]
    l_cSQLCommandForeignKeys += [ WHERE REFERENCED_TABLE_SCHEMA = ']+par_cDatabase+[']

//--Load Tables-----------
    if empty(l_cErrorMessage)
        if !SQLExec(par_SQLHandle,l_cSQLCommandFields,"ListOfFieldsForLoads")
            l_cErrorMessage := "Failed to retrieve Fields Meta data."
        else
            // ExportTableToHtmlFile("ListOfFieldsForLoads","d:\MySQL_ListOfFieldsForLoads.html","From MySQL",,200,.t.)

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
                        :Table("857facc8-c771-4829-bf6e-b5458e07fd16","Table")
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
                            :Table("ab2cf649-e4a5-4d3f-9174-f7a78f36b0f4","NameSpace")
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
                                :Table("1b1a174d-4717-4452-b346-fe29ca359c6d","NameSpace")
                                :Field("NameSpace.Name"          ,l_cLastNameSpace)
                                :Field("NameSpace.fk_Application",par_iApplicationPk)
                                :Field("NameSpace.UseStatus"     ,1)
                                if :Add()
                                    l_iNewNameSpace += 1
                                    l_iNameSpacePk := :Key()
                                else
                                    l_cErrorMessage := "Failed to add Name Space record."
                                endif

                            case :Tally == 1
                                l_iNameSpacePk := l_aSQLResult[1,1]
                            otherwise
                                l_cErrorMessage := "Failed to Query Meta database. Error 103."
                            endcase

                            if l_iNameSpacePk > 0
                                :Table("a59d51e5-fd44-44b9-9f0d-61b284fd96ff","Table")
                                :Field("Table.Name"        ,l_cLastTableName)
                                :Field("Table.fk_NameSpace",l_iNameSpacePk)
                                :Field("Table.UseStatus"   ,1)
                                if :Add()
                                    l_iNewTables += 1
                                    l_iTablePk := :Key()
                                    l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk
                                else
                                    l_cErrorMessage := "Failed to add Table record."
                                endif
                            endif

                        case :Tally == 1
                            l_iNameSpacePk   := l_aSQLResult[1,1]
                            l_iTablePk       := l_aSQLResult[1,2]
                            l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk

                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 104."
                        endcase

                    endwith

                    // Load all the tables current columns
                    with object l_oDB2
                        :Table("a2a7bc00-d9d6-48df-90b1-ceb4f43cca28","Column")
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
                        :OrderBy("Column_Order","Desc")
                        :SQL("ListOfColumnsInDataDictionary")
                        // SendToClipboard(:LastSQL())

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data Columns. Error 105."
                        else
                            if :Tally == 0
                                l_LastColumnOrder := 0
                            else
                                l_LastColumnOrder := ListOfColumnsInDataDictionary->Column_Order
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
                    //Get the column Name, Type, Length, Scale, Nullable
                    l_cColumnName           := alltrim(ListOfFieldsForLoads->field_name)
                    l_lColumnNullable       := (ListOfFieldsForLoads->field_nullable == 1)      // Since the information_schema does not follow odbc driver setting to return boolean as logical
                    l_lColumnPrimary        := (ListOfFieldsForLoads->field_is_identity == 1)
                    l_lColumnUnicode        := .f.
                    l_cColumnDefault        := nvl(ListOfFieldsForLoads->field_default,"")
                    l_cColumnLastNativeType := nvl(ListOfFieldsForLoads->field_type,"")

                    // l_cColumnDefault        := strtran(l_cColumnDefault,"::"+l_cColumnLastNativeType,"")  //Remove casting to the same field type. (PostgreSQL specific behavior)
                    // if l_cColumnLastNativeType == "character"
                    //     l_cColumnDefault := strtran(l_cColumnDefault,"::bpchar","")
                    // endif

                    if l_cColumnDefault == "NULL"
                        l_cColumnDefault := ""
                    endif

                    // if ListOfFieldsForLoads->field_type == "USER-DEFINED"
                    //     altd()
                    // endif

                    l_lColumnArray := .f.
                    switch ListOfFieldsForLoads->field_type
                    case "int"
                        l_cColumnType   := "I"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "bigint"
                        l_cColumnType   := "IB"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "decimal"
                        l_cColumnType   := "N"
                        l_nColumnLength := ListOfFieldsForLoads->field_nlength
                        l_nColumnScale  := ListOfFieldsForLoads->field_decimals
                        exit

                    case "char"
                        l_cColumnType     := "C"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // Will default characters fields always support unicode
                        exit

                    case "varchar"
                        l_cColumnType     := "CV"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // Will default characters fields always support unicode
                        exit

                    case "binary"
                        l_cColumnType   := "B"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "varbinary"
                        l_cColumnType   := "BV"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "longtext"
                        l_cColumnType     := "M"
                        l_nColumnLength   := NIL
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.  // Will default characters fields always support unicode
                        exit

                    case "longblob"
                        l_cColumnType   := "R"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "tinyint"
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
                        l_cColumnType   := "TO"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "timestamp"
                        l_cColumnType   := "DTZ"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "datetime"
                        l_cColumnType   := "DT"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
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

                    if vfp_Seek(upper(l_cColumnName)+'*',"ListOfColumnsInDataDictionary","tag1")
                        l_iColumnPk := ListOfColumnsInDataDictionary->Pk
                        l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk

                        if trim(nvl(ListOfColumnsInDataDictionary->Column_Type,""))     == l_cColumnType           .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Array,.f.)         == l_lColumnArray          .and. ;
                           ListOfColumnsInDataDictionary->Column_Length                 == l_nColumnLength         .and. ;
                           ListOfColumnsInDataDictionary->Column_Scale                  == l_nColumnScale          .and. ;
                           ListOfColumnsInDataDictionary->Column_Nullable               == l_lColumnNullable       .and. ;
                           ListOfColumnsInDataDictionary->Column_Primary                == l_lColumnPrimary        .and. ;
                           ListOfColumnsInDataDictionary->Column_Unicode                == l_lColumnUnicode        .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Default,"")        == l_cColumnDefault        .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_LastNativeType,"") == l_cColumnLastNativeType

                        else
                            if ListOfColumnsInDataDictionary->Column_UseStatus >= 3  // Meaning at least marked as "Under Development"
                                //_M_ report data was not updated
                            else
                                if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInDataDictionary","Column_Type") .or. empty(ListOfColumnsInDataDictionary->Column_Type))
                                    with object l_oDB1
                                        l_LastColumnOrder += 1
                                        :Table("b6c0c818-cf30-4f08-aefc-c2c18d5bd35b","Column")
                                        :Field("Column.Type"          ,l_cColumnType)
                                        :Field("Column.Array"         ,l_lColumnArray)
                                        :Field("Column.Length"        ,l_nColumnLength)
                                        :Field("Column.Scale"         ,l_nColumnScale)
                                        :Field("Column.Nullable"      ,l_lColumnNullable)
                                        :Field("Column.Primary"       ,l_lColumnPrimary)
                                        :Field("Column.Unicode"       ,l_lColumnUnicode)
                                        :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                                        :Field("Column.LastNativeType",l_cColumnLastNativeType)
                                        if :Update(l_iColumnPk)
                                            l_iUpdatedColumns += 1
                                        else
                                            l_cErrorMessage := "Failed to update Column record."
                                        endif
                                    endwith
                                endif
                            endif
                        endif

                    else
                        //Missing Field, Add it
                        with object l_oDB1
                            l_LastColumnOrder += 1
                            :Table("f697ccfd-86b3-4b9a-ab4c-acc9d626515e","Column")
                            :Field("Column.Name"          ,l_cColumnName)
                            :Field("Column.Order"         ,l_LastColumnOrder)
                            :Field("Column.fk_Table"      ,l_iTablePk)
                            :Field("Column.UseStatus"     ,1)
                            :Field("Column.Type"          ,l_cColumnType)
                            :Field("Column.Array"         ,l_lColumnArray)
                            :Field("Column.Length"        ,l_nColumnLength)
                            :Field("Column.Scale"         ,l_nColumnScale)
                            :Field("Column.Nullable"      ,l_lColumnNullable)
                            :Field("Column.Primary"       ,l_lColumnPrimary)
                            :Field("Column.Unicode"       ,l_lColumnUnicode)
                            :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                            :Field("Column.LastNativeType",l_cColumnLastNativeType)
                            :Field("Column.UsedBy"        ,1)
                            if :Add()
                                l_iNewColumns += 1
                                l_iColumnPk := :Key()
                                l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk
                            else
                                l_cErrorMessage := "Failed to add Column record."
                            endif
                        endwith

                    endif

                endif

            endscan

        endif

    endif

///////////////////////////////===========================================================================================================






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
                            //Add the NameSpace
                            :Table("1e4d6164-d02d-4590-b143-02ab9e9aac2b","NameSpace")
                            :Field("NameSpace.Name"          ,l_cLastNameSpace)
                            :Field("NameSpace.fk_Application",par_iApplicationPk)
                            :Field("NameSpace.UseStatus"     ,1)
                            if :Add()
                                l_iNewNameSpace += 1
                                l_iNameSpacePk := :Key()
                            else
                                l_cErrorMessage := "Failed to add Name Space record."
                            endif

                        case :Tally == 1
                            l_iNameSpacePk := l_aSQLResult[1,1]
                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 103."
                        endcase

                        if l_iNameSpacePk > 0
                            :Table("4f5a321c-e9fd-4e3f-af6f-9e956b697ed7","Enumeration")
                            :Field("Enumeration.Name"        ,l_cLastEnumerationName)
                            :Field("Enumeration.fk_NameSpace",l_iNameSpacePk)
                            :Field("Enumeration.ImplementAs" ,1)
                            :Field("Enumeration.UseStatus"   ,1)
                            if :Add()
                                l_iNewEnumerations += 1
                                l_iEnumerationPk := :Key()
                                l_hEnumerations[l_cLastNameSpace+"."+l_cLastEnumerationName] := l_iEnumerationPk
                            else
                                l_cErrorMessage := "Failed to add Enumeration record."
                            endif
                        endif

                    case :Tally == 1
                        l_iNameSpacePk   := l_aSQLResult[1,1]
                        l_iEnumerationPk := l_aSQLResult[1,2]
                        l_hEnumerations[l_cLastNameSpace+"."+l_cLastEnumerationName] := l_iEnumerationPk

                    otherwise
                        l_cErrorMessage := "Failed to Query Meta database. Error 104."
                    endcase

                endwith

                // Load all the Enumerations current EnumValues
                with object l_oDB2
                    :Table("d8748388-1484-46cf-bb5d-d990bf9fcfad","EnumValue")
                    :Column("EnumValue.Pk"          , "Pk")
                    :Column("EnumValue.Order"       , "EnumValue_Order")
                    :Column("EnumValue.Name"        , "EnumValue_Name")
                    :Column("upper(EnumValue.Name)" , "tag1")
                    :Where("EnumValue.fk_Enumeration = ^" , l_iEnumerationPk)
                    :OrderBy("EnumValue_Order","Desc")
                    :SQL("ListOfEnumValuesInDataDictionary")

                    if :Tally < 0
                        l_cErrorMessage := "Failed to load Meta Data EnumValue. Error 106."
                    else
                        if :Tally == 0
                            l_LastEnumValueOrder := 0
                        else
                            l_LastEnumValueOrder := ListOfEnumValuesInDataDictionary->EnumValue_Order
                        endif

                        with object :p_oCursor
                            :Index("tag1","tag1+'*'")
                            :CreateIndexes()
                        endwith

                    endif

                endwith

            endif

            if empty(l_cErrorMessage)
                //Check existence of EnumValue and add if needed
                //Get the EnumValue Name
                l_cEnumValueName := alltrim(ListOfEnumsForLoads->enum_value)



                if !vfp_Seek(upper(l_cEnumValueName)+'*',"ListOfEnumValuesInDataDictionary","tag1")
                    //Missing EnumValue, Add it

                    with object l_oDB1
                        l_LastEnumValueOrder += 1
                        :Table("4a1d27a3-e85e-4631-9f75-30534fa6e5d0","EnumValue")
                        :Field("EnumValue.Name"          ,l_cEnumValueName)
                        :Field("EnumValue.Order"         ,l_LastEnumValueOrder)
                        :Field("EnumValue.fk_Enumeration",l_iEnumerationPk)
                        :Field("EnumValue.UseStatus"     ,1)
                        if :Add()
                            l_iNewEnumValues += 1
                        else
                            l_cErrorMessage := "Failed to add EnumValue record."
                        endif
                    endwith

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
                                :Table("1d4e6580-fc99-4002-aa7a-5734e311b947","NameSpace")
                                :Field("NameSpace.Name"          ,l_cLastNameSpace)
                                :Field("NameSpace.fk_Application",par_iApplicationPk)
                                :Field("NameSpace.UseStatus"     ,1)
                                if :Add()
                                    l_iNewNameSpace += 1
                                    l_iNameSpacePk := :Key()
                                else
                                    l_cErrorMessage := "Failed to add Name Space record."
                                endif

                            case :Tally == 1
                                l_iNameSpacePk := l_aSQLResult[1,1]
                            otherwise
                                l_cErrorMessage := "Failed to Query Meta database. Error 103."
                            endcase

                            if l_iNameSpacePk > 0
                                :Table("926f2eb7-276f-4ea9-bef4-e0147d53989e","Table")
                                :Field("Table.Name"        ,l_cLastTableName)
                                :Field("Table.fk_NameSpace",l_iNameSpacePk)
                                :Field("Table.UseStatus"   ,1)
                                if :Add()
                                    l_iNewTables += 1
                                    l_iTablePk := :Key()
                                    l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk
                                else
                                    l_cErrorMessage := "Failed to add Table record."
                                endif
                            endif

                        case :Tally == 1
                            l_iNameSpacePk   := l_aSQLResult[1,1]
                            l_iTablePk       := l_aSQLResult[1,2]
                            l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk

                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 104."
                        endcase

                    endwith


                    // Load all the tables current columns
                    with object l_oDB2
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
                        :OrderBy("Column_Order","Desc")
                        :SQL("ListOfColumnsInDataDictionary")
                        // SendToClipboard(:LastSQL())

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data Columns. Error 205."
                        else
                            if :Tally == 0
                                l_LastColumnOrder := 0
                            else
                                l_LastColumnOrder := ListOfColumnsInDataDictionary->Column_Order
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
                    l_cColumnLastNativeType := l_cColumnLastNativeType+iif(l_lColumnArray,"[]","")

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

                    if vfp_Seek(upper(l_cColumnName)+'*',"ListOfColumnsInDataDictionary","tag1")
                        l_iColumnPk := ListOfColumnsInDataDictionary->Pk
                        l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk

                        if trim(nvl(ListOfColumnsInDataDictionary->Column_Type,""))     == l_cColumnType           .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Array,.f.)         == l_lColumnArray          .and. ;
                           ListOfColumnsInDataDictionary->Column_Length                 == l_nColumnLength         .and. ;
                           ListOfColumnsInDataDictionary->Column_Scale                  == l_nColumnScale          .and. ;
                           ListOfColumnsInDataDictionary->Column_Nullable               == l_lColumnNullable       .and. ;
                           ListOfColumnsInDataDictionary->Column_Primary                == l_lColumnPrimary        .and. ;
                           ListOfColumnsInDataDictionary->Column_Unicode                == l_lColumnUnicode        .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Default,"")        == l_cColumnDefault        .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_LastNativeType,"") == l_cColumnLastNativeType .and. ;
                           ListOfColumnsInDataDictionary->Column_fk_Enumeration         == l_iFk_Enumeration

                        else
// altd()
                            if ListOfColumnsInDataDictionary->Column_UseStatus >= 3  // Meaning at least marked as "Under Development"
                                //_M_ report data was not updated
                            else
                                if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInDataDictionary","Column_Type") .or. empty(ListOfColumnsInDataDictionary->Column_Type))
                                    with object l_oDB1
                                        l_LastColumnOrder += 1
                                        :Table("288eca6a-be39-47cc-a70a-908d6b45059f","Column")
                                        :Field("Column.Type"          ,l_cColumnType)
                                        :Field("Column.Array"         ,l_lColumnArray)
                                        :Field("Column.Length"        ,l_nColumnLength)
                                        :Field("Column.Scale"         ,l_nColumnScale)
                                        :Field("Column.Nullable"      ,l_lColumnNullable)
                                        :Field("Column.Primary"       ,l_lColumnPrimary)
                                        :Field("Column.Unicode"       ,l_lColumnUnicode)
                                        :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                                        :Field("Column.LastNativeType",l_cColumnLastNativeType)
                                        :Field("Column.fk_Enumeration",l_iFk_Enumeration)
                                        if :Update(l_iColumnPk)
                                            l_iUpdatedColumns += 1
                                        else
                                            l_cErrorMessage := "Failed to update Column record."
                                        endif
                                    endwith
                                endif
                            endif
                        endif

                    else
                        //Missing Field, Add it
                        with object l_oDB1
                            l_LastColumnOrder += 1
                            :Table("6c3137a2-395e-488c-bc71-94990c022851","Column")
                            :Field("Column.Name"          ,l_cColumnName)
                            :Field("Column.Order"         ,l_LastColumnOrder)
                            :Field("Column.fk_Table"      ,l_iTablePk)
                            :Field("Column.UseStatus"     ,1)
                            :Field("Column.Type"          ,l_cColumnType)
                            :Field("Column.Array"         ,l_lColumnArray)
                            :Field("Column.Length"        ,l_nColumnLength)
                            :Field("Column.Scale"         ,l_nColumnScale)
                            :Field("Column.Nullable"      ,l_lColumnNullable)
                            :Field("Column.Primary"       ,l_lColumnPrimary)
                            :Field("Column.Unicode"       ,l_lColumnUnicode)
                            :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                            :Field("Column.LastNativeType",l_cColumnLastNativeType)
                            :Field("Column.fk_Enumeration",l_iFk_Enumeration)
                            :Field("Column.UsedBy"        ,1)
                            if :Add()
                                l_iNewColumns += 1
                                l_iColumnPk := :Key()
                                l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk
                            else
                                l_cErrorMessage := "Failed to add Column record."
                            endif
                        endwith

                    endif

                endif

            endscan

        endif

    endif

    //is_identity

case par_SQLEngineType == HB_ORM_ENGINETYPE_MSSQL

    //MS SQL Does not support Enumeration
    l_cSQLCommandEnums := []

    // l_cSQLCommandFields  := [SELECT columns.TABLE_SCHEMA             AS schema_name,]
    // l_cSQLCommandFields  += [       columns.TABLE_NAME               AS table_name,]
    // l_cSQLCommandFields  += [       columns.ORDINAL_POSITION         AS field_position,]
    // l_cSQLCommandFields  += [       columns.COLUMN_NAME              AS field_name,]
    // l_cSQLCommandFields  += [       columns.DATA_TYPE                AS field_type,]
    // l_cSQLCommandFields  += [       columns.CHARACTER_MAXIMUM_LENGTH AS field_clength,]
    // l_cSQLCommandFields  += [       columns.NUMERIC_PRECISION        AS field_nlength,]
    // l_cSQLCommandFields  += [       columns.DATETIME_PRECISION       AS field_tlength,]
    // l_cSQLCommandFields  += [       columns.NUMERIC_SCALE            AS field_decimals,]
    // l_cSQLCommandFields  += [	   CASE WHEN columns.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END AS field_nullable,]
    // l_cSQLCommandFields  += [       columns.COLUMN_DEFAULT           AS field_default,]
    // l_cSQLCommandFields  += [       columnproperty(object_id(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME),columns.COLUMN_NAME,'IsIdentity') AS field_is_identity,]
    // l_cSQLCommandFields  += [       upper(columns.TABLE_SCHEMA)      AS tag1,]
    // l_cSQLCommandFields  += [       upper(columns.TABLE_NAME)        AS tag2]
    // l_cSQLCommandFields  += [ FROM INFORMATION_SCHEMA.COLUMNS as columns]

    // used cast( as Varchar(254)) to deal with odbc bug on Linux (Ubuntu)
    l_cSQLCommandFields  := [SELECT cast(columns.TABLE_SCHEMA as Varchar(254))              AS schema_name,]
    l_cSQLCommandFields  += [       cast(columns.TABLE_NAME as Varchar(254))                AS table_name,]
    l_cSQLCommandFields  += [       columns.ORDINAL_POSITION                                AS field_position,]
    l_cSQLCommandFields  += [       cast(columns.COLUMN_NAME as Varchar(254))               AS field_name,]
    l_cSQLCommandFields  += [       cast(columns.DATA_TYPE as Varchar(254))                 AS field_type,]
    l_cSQLCommandFields  += [       columns.CHARACTER_MAXIMUM_LENGTH                        AS field_clength,]
    l_cSQLCommandFields  += [       columns.NUMERIC_PRECISION                               AS field_nlength,]
    l_cSQLCommandFields  += [       columns.DATETIME_PRECISION                              AS field_tlength,]
    l_cSQLCommandFields  += [       columns.NUMERIC_SCALE                                   AS field_decimals,]
    l_cSQLCommandFields  += [       CASE WHEN columns.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END AS field_nullable,]
    l_cSQLCommandFields  += [       cast(columns.COLUMN_DEFAULT as Varchar(254))            AS field_default,]
    l_cSQLCommandFields  += [       columnproperty(object_id(columns.TABLE_SCHEMA+'.'+columns.TABLE_NAME),columns.COLUMN_NAME,'IsIdentity') AS field_is_identity,]
    l_cSQLCommandFields  += [       cast(upper(columns.TABLE_SCHEMA) as Varchar(254))       AS tag1,]
    l_cSQLCommandFields  += [       cast(upper(columns.TABLE_NAME) as Varchar(254))         AS tag2]
    l_cSQLCommandFields  += [ FROM INFORMATION_SCHEMA.COLUMNS as columns]

    if !empty(par_cSyncNameSpaces)
        l_cSQLCommandFields  += [ WHERE lower(columns.TABLE_SCHEMA) in (]
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

    l_cSQLCommandIndexes := [] // for now
    // l_cSQLCommandIndexes := [SELECT pg_indexes.schemaname        AS schema_name,]
    // l_cSQLCommandIndexes += [       pg_indexes.tablename         AS table_name,]
    // l_cSQLCommandIndexes += [       pg_indexes.indexname         AS index_name,]
    // l_cSQLCommandIndexes += [       pg_indexes.indexdef          AS index_definition,]
    // l_cSQLCommandIndexes += [       upper(pg_indexes.schemaname) AS tag1,]
    // l_cSQLCommandIndexes += [       upper(pg_indexes.tablename)  AS tag2]
    // l_cSQLCommandIndexes += [ FROM pg_indexes]
    // l_cSQLCommandIndexes += [ WHERE NOT (lower(left(pg_indexes.tablename,11)) = 'schemacache' OR lower(pg_indexes.schemaname) in ('information_schema','pg_catalog'))]
    // l_cSQLCommandIndexes += [ ORDER BY tag1,tag2,index_name]



//--Load Enumerations-----------
    //No supported in MSSQL



//--Load Tables-----------
    if empty(l_cErrorMessage)
        if !SQLExec(par_SQLHandle,l_cSQLCommandFields,"ListOfFieldsForLoads")
            l_cErrorMessage := "Failed to retrieve Fields Meta data."
        else
            // ExportTableToHtmlFile("ListOfFieldsForLoads","d:\MSSQL_ListOfFieldsForLoads.html","From MSSQL",,200,.t.)

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
                        :Table("9a89874c-c096-4f4a-8bf8-19ae756638eb","Table")
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
                            l_cErrorMessage := "Failed to Query Meta database. Error 401."
                            exit
                        case empty(:Tally)
                            //Tables is not in datadic, load it.
                            //Find the Name Space
                            :Table("c7d6ed0f-edc0-4206-8e58-9688b8b4c518","NameSpace")
                            :Column("NameSpace.pk" , "Pk")
                            :Where([NameSpace.fk_Application = ^],par_iApplicationPk)
                            :Where([lower(replace(NameSpace.Name,' ','')) = ^],lower(StrTran(l_cLastNameSpace," ","")))
                            l_aSQLResult := {}
                            :SQL(@l_aSQLResult)

                            do case
                            case :Tally == -1  //Failed to query
                                l_cErrorMessage := "Failed to Query Meta database. Error 402."
                            case empty(:Tally)
                                //Add the NameSpace
                                :Table("8874a9cb-ceba-4fa2-9f4c-ef0f72e06567","NameSpace")
                                :Field("NameSpace.Name"          ,l_cLastNameSpace)
                                :Field("NameSpace.fk_Application",par_iApplicationPk)
                                :Field("NameSpace.UseStatus"     ,1)
                                if :Add()
                                    l_iNewNameSpace += 1
                                    l_iNameSpacePk := :Key()
                                else
                                    l_cErrorMessage := "Failed to add Name Space record."
                                endif

                            case :Tally == 1
                                l_iNameSpacePk := l_aSQLResult[1,1]
                            otherwise
                                l_cErrorMessage := "Failed to Query Meta database. Error 403."
                            endcase

                            if l_iNameSpacePk > 0
                                :Table("8921c96e-9bc6-443a-b6bb-56cb73efce0e","Table")
                                :Field("Table.Name"        ,l_cLastTableName)
                                :Field("Table.fk_NameSpace",l_iNameSpacePk)
                                :Field("Table.UseStatus"   ,1)
                                if :Add()
                                    l_iNewTables += 1
                                    l_iTablePk := :Key()
                                    l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk
                                else
                                    l_cErrorMessage := "Failed to add Table record."
                                endif
                            endif

                        case :Tally == 1
                            l_iNameSpacePk   := l_aSQLResult[1,1]
                            l_iTablePk       := l_aSQLResult[1,2]
                            l_hTables[l_cLastNameSpace+"."+l_cLastTableName] := l_iTablePk

                        otherwise
                            l_cErrorMessage := "Failed to Query Meta database. Error 404."
                        endcase

                    endwith

                    // Load all the tables current columns
                    with object l_oDB2
                        :Table("a36ed01d-69c5-403a-bdc4-6f0835fbb4cc","Column")
                        :Column("Column.Pk"             , "Pk")
                        :Column("Column.Order"          , "Column_Order")
                        :Column("Column.Name"           , "Column_Name")
                        :Column("upper(Column.Name)"    , "tag1")
                        :Column("Column.Type"           , "Column_Type")
                        :Column("Column.Array"          , "Column_Array")
                        :Column("Column.Length"         , "Column_Length")
                        :Column("Column.Scale"          , "Column_Scale")
                        :Column("Column.Nullable"       , "Column_Nullable")
                        :Column("Column.Primary"        , "Column_Primary")
                        :Column("Column.Unicode"        , "Column_Unicode")
                        :Column("Column.Default"        , "Column_Default")
                        :Column("Column.LastNativeType" , "Column_LastNativeType")
                        :Column("Column.fk_Enumeration" , "Column_fk_Enumeration")
                        :Column("Column.UseStatus"      , "Column_UseStatus")
                        :Where("Column.fk_Table = ^" , l_iTablePk)
                        :OrderBy("Column_Order","Desc")
                        :SQL("ListOfColumnsInDataDictionary")
                        // SendToClipboard(:LastSQL())

                        if :Tally < 0
                            l_cErrorMessage := "Failed to load Meta Data Columns. Error 305."
                        else
                            if :Tally == 0
                                l_LastColumnOrder := 0
                            else
                                l_LastColumnOrder := ListOfColumnsInDataDictionary->Column_Order
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
                    l_lColumnNullable       := (ListOfFieldsForLoads->field_nullable == 1)
                    l_lColumnPrimary        := (ListOfFieldsForLoads->field_is_identity == 1)
                    l_lColumnUnicode        := .f.
                    l_cColumnDefault        := nvl(ListOfFieldsForLoads->field_default,"")
                    l_cColumnLastNativeType := nvl(ListOfFieldsForLoads->field_type,"")
                    l_iFk_Enumeration       := 0

                    if l_cColumnDefault == "NULL"
                        l_cColumnDefault := ""
                    endif

                    l_lColumnArray := .f.
                    switch ListOfFieldsForLoads->field_type
                    case "int"
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

                    case "char"
                        l_cColumnType   := "C"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "nchar"
                        l_cColumnType     := "C"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.
                        //_M_ mark as Unicode
                        exit

                    case "varchar"
                        l_cColumnType   := "CV"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "nvarchar"
                        l_cColumnType     := "CV"
                        l_nColumnLength   := ListOfFieldsForLoads->field_clength
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.
                        //_M_ mark as Unicode
                        exit

                    case "binary"
                        l_cColumnType   := "B"
                        l_nColumnLength := ListOfFieldsForLoads->field_clength
                        l_nColumnScale  := NIL
                        exit

                    case "varbinary"
                        if ListOfFieldsForLoads->field_clength == -1
                            l_cColumnType   := "R"
                            l_nColumnLength := NIL
                            l_nColumnScale  := NIL
                        else
                            l_cColumnType   := "BV"
                            l_nColumnLength := ListOfFieldsForLoads->field_clength
                            l_nColumnScale  := NIL
                        endif
                        exit

                    case "text"
                        l_cColumnType   := "M"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "ntext"
                        l_cColumnType     := "M"
                        l_nColumnLength   := NIL
                        l_nColumnScale    := NIL
                        l_lColumnUnicode  := .t.
                        exit

                    case "bit"
                        l_cColumnType   := "L"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit


                    // See https://docs.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver15
                    case "date"
                        l_cColumnType   := "D"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "datetime"   //timestamp without time zone
                        l_cColumnType   := "DT"
                        l_nColumnLength := NIL
                        l_nColumnScale  := 3
                        exit

                    case "datetime2"   //timestamp without time zone and some precision
                        l_cColumnType   := "DT"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "datetimeoffset"   //timestamp with time zone
                        l_cColumnType   := "DTZ"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    case "smalldatetime"  //timestamp without time zone and no precision
                        l_cColumnType   := "DT"
                        l_nColumnLength := NIL
                        l_nColumnScale  := 0
                        exit

                    case "time"   // time without time zone
                        l_cColumnType   := "TO"
                        l_nColumnLength := NIL
                        l_nColumnScale  := ListOfFieldsForLoads->field_tlength
                        exit

                    // It seems there is no time with time zone in MSSQL?

                    case "money"
                        l_cColumnType   := "Y"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    case "uniqueidentifier"
                        l_cColumnType   := "UUI"
                        l_nColumnLength := NIL
                        l_nColumnScale  := NIL
                        exit

                    // case "USER-DEFINED"
                    //     l_cColumnType   := "E"
                    //     l_nColumnLength := NIL
                    //     l_nColumnScale  := NIL

                    //     l_iFk_Enumeration := hb_HGetDef(l_hEnumerations,l_cLastNameSpace+"."+alltrim(ListOfFieldsForLoads->enumeration_name),0)
                    //     exit

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


                    if vfp_Seek(upper(l_cColumnName)+'*',"ListOfColumnsInDataDictionary","tag1")
                        l_iColumnPk := ListOfColumnsInDataDictionary->Pk
                        l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk

                        if trim(nvl(ListOfColumnsInDataDictionary->Column_Type,""))     == l_cColumnType     .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Array,.f.)         == l_lColumnArray    .and. ;
                           ListOfColumnsInDataDictionary->Column_Length                 == l_nColumnLength   .and. ;
                           ListOfColumnsInDataDictionary->Column_Scale                  == l_nColumnScale    .and. ;
                           ListOfColumnsInDataDictionary->Column_Nullable               == l_lColumnNullable .and. ;
                           ListOfColumnsInDataDictionary->Column_Primary                == l_lColumnPrimary  .and. ;
                           ListOfColumnsInDataDictionary->Column_Unicode                == l_lColumnUnicode  .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_Default,"")        == l_cColumnDefault  .and. ;
                           nvl(ListOfColumnsInDataDictionary->Column_LastNativeType,"") == l_cColumnLastNativeType

                        else
                            if ListOfColumnsInDataDictionary->Column_UseStatus >= 3  // Meaning at least marked as "Under Development"
                                //_M_ report data was not updated
                            else
                                if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInDataDictionary","Column_Type") .or. empty(ListOfColumnsInDataDictionary->Column_Type))
                                    with object l_oDB1
                                        l_LastColumnOrder += 1
                                        :Table("9b7db810-3732-4f16-bd3d-05516388e5a2","Column")
                                        :Field("Column.Type"          ,l_cColumnType)
                                        :Field("Column.Array"         ,l_lColumnArray)
                                        :Field("Column.Length"        ,l_nColumnLength)
                                        :Field("Column.Scale"         ,l_nColumnScale)
                                        :Field("Column.Nullable"      ,l_lColumnNullable)
                                        :Field("Column.Primary"       ,l_lColumnPrimary)
                                        :Field("Column.Unicode"       ,l_lColumnUnicode)
                                        :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                                        :Field("Column.LastNativeType",l_cColumnLastNativeType)
                                        if :Update(l_iColumnPk)
                                            l_iUpdatedColumns += 1
                                        else
                                            l_cErrorMessage := "Failed to update Column record."
                                        endif
                                    endwith
                                endif
                            endif
                        endif

                    else
                        //Missing Field, Add it
                        with object l_oDB1
                            l_LastColumnOrder += 1
                            :Table("26aaff95-0863-4762-9153-a47bd8979677","Column")
                            :Field("Column.Name"          ,l_cColumnName)
                            :Field("Column.Order"         ,l_LastColumnOrder)
                            :Field("Column.fk_Table"      ,l_iTablePk)
                            :Field("Column.UseStatus"     ,1)
                            :Field("Column.Type"          ,l_cColumnType)
                            :Field("Column.Array"         ,l_lColumnArray)
                            :Field("Column.Length"        ,l_nColumnLength)
                            :Field("Column.Scale"         ,l_nColumnScale)
                            :Field("Column.Nullable"      ,l_lColumnNullable)
                            :Field("Column.Primary"       ,l_lColumnPrimary)
                            :Field("Column.Unicode"       ,l_lColumnUnicode)
                            :Field("Column.Default"       ,iif(empty(l_cColumnDefault),NIL,l_cColumnDefault))
                            :Field("Column.LastNativeType",l_cColumnLastNativeType)
                            :Field("Column.UsedBy"        ,1)
                            if :Add()
                                l_iNewColumns += 1
                                l_iColumnPk := :Key()
                                l_hColumns[l_cLastNameSpace+"."+l_cLastTableName+"."+l_cColumnName] := l_iColumnPk
                            else
                                l_cErrorMessage := "Failed to add Column record."
                            endif
                        endwith

                    endif

                endif

            endscan

        endif

    endif



endcase


//--Try to setup Foreign Links----------------
if par_nSyncSetForeignKey > 1
    with object l_oDB1
        if par_nSyncSetForeignKey == 2
            //l_cSQLCommandForeignKeys

    // l_cSQLCommandForeignKeys += [SELECT cast(concat('*public*',lower(TABLE_NAME),'*',lower(COLUMN_NAME),'*') AS CHAR(255)) AS childcolumn,]
    // l_cSQLCommandForeignKeys += [       cast(concat('*public*',lower(REFERENCED_TABLE_NAME),'*')             AS CHAR(255)) AS parenttable]
    // l_cSQLCommandForeignKeys += [ FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE]
    // l_cSQLCommandForeignKeys += [ WHERE REFERENCED_TABLE_SCHEMA = ']+par_cDatabase+[']

            if !SQLExec(par_SQLHandle,l_cSQLCommandForeignKeys,"ListOfFieldsForeignKeys")
                l_cErrorMessage := "Failed to retrieve Fields Meta data."
            else
                l_oDB_AllTablesAsParentsForForeignKeys      := hb_SQLData(oFcgi:p_o_SQLConnection)
                l_oDB_AllTableColumnsChildrenForForeignKeys := hb_SQLData(oFcgi:p_o_SQLConnection)

                with object l_oDB_AllTablesAsParentsForForeignKeys
                    :Table("8c90e531-cac1-4ee8-9d9c-722eec3fa47e","Table")
                    :Column("Table.pk" , "Pk")
                    :Column("cast(concat('*',lower(NameSpace.Name),'*',lower(Table.Name),'*') as char(255))", "tag1")
                    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
                    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
                    :SQL("AllTablesAsParentsForForeignKeys")

                    with object :p_oCursor
                        :Index("tag1","tag1")
                        :CreateIndexes()
                        // :SetOrder("tag1")
                    endwith

                endwith
// ExportTableToHtmlFile("AllTablesAsParentsForForeignKeys","d:\AllTablesAsParentsForForeignKeys.html","From PostgreSQL",,25,.t.)

                with object l_oDB_AllTableColumnsChildrenForForeignKeys
                    :Table("0a3abf33-c882-4909-babf-8f917e326bca","Column")
                    :Column("Column.pk"              , "Pk")
                    :Column("Column.fk_TableForeign" , "Column_fk_TableForeign")
                    :Column("Column.UseStatus"       , "Column_UseStatus")
                    :Column("cast(concat('*',lower(NameSpace.Name),'*',lower(Table.Name),'*',lower(Column.Name),'*') as char(255))", "tag1")
                    :Join("inner","Table","","Column.fk_Table = Table.pk")
                    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
                    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
                    :SQL("AllTableColumnsChildrenForForeignKeys")

                    with object :p_oCursor
                        :Index("tag1","tag1")
                        :CreateIndexes()
                        // :SetOrder("tag1")
                    endwith

                endwith
// ExportTableToHtmlFile("AllTableColumnsChildrenForForeignKeys","d:\AllTableColumnsChildrenForForeignKeys.html","From PostgreSQL",,25,.t.)


                select ListOfFieldsForeignKeys
                scan all
                    // l_cTableName := ListOfFieldsForeignKeys->childtablename
                    // l_cTableName := ListOfFieldsForeignKeys->childcolumnname

                    l_iParentTableKey := iif( VFP_Seek(ListOfFieldsForeignKeys->parenttable,"AllTablesAsParentsForForeignKeys"     ,"tag1") , AllTablesAsParentsForForeignKeys->pk      , 0)
                    l_iChildColumnKey := iif( VFP_Seek(ListOfFieldsForeignKeys->childcolumn,"AllTableColumnsChildrenForForeignKeys","tag1") , AllTableColumnsChildrenForForeignKeys->pk , 0)

                    if l_iParentTableKey > 0 .and. l_iChildColumnKey > 0
                        if AllTableColumnsChildrenForForeignKeys->Column_fk_TableForeign <> l_iParentTableKey
                            if AllTableColumnsChildrenForForeignKeys->Column_UseStatus <= 2  // Only  1 = Unknown and 2 = Proposed" can be auto linked
                                :Table("088fd706-ec0f-445f-9c06-bfd6fe20a80d","Column")
                                :Field("Column.fk_TableForeign",l_iParentTableKey)
                                if :Update(l_iChildColumnKey)
                                    l_iUpdatedColumns += 1
                                else
                                    //_M_ report error
                                endif
                            endif
                        endif
                    endif

                endscan
            endif

        else
            :Table("5e32612b-fcf7-4f16-84f2-583df8673e3a","Column")
            :Column("Column.pk"       ,"Column_pk")
            :Column("Table.pk"        ,"Table_pk")
            :Column("Column.UseStatus","Column_UseStatus")

            //Ensure we only check on the columns in the current application
            :Join("inner","Table"    ,"TableOfColumn"    ,"Column.fk_Table = TableOfColumn.pk")
            :Join("inner","NameSpace","NameSpaceOfColumn","TableOfColumn.fk_NameSpace = NameSpaceOfColumn.pk")
            :Where("NameSpaceOfColumn.fk_Application = ^",par_iApplicationPk)

            do case
            case par_nSyncSetForeignKey == 3
                :Where("left(Column.Name,2) = ^" , "p_")
                :Join("inner","Table","","lower(Column.Name) = lower(concat('p_',Table.Name))")
            case par_nSyncSetForeignKey == 4
                :Where("left(Column.Name,3) = ^" , "fk_")
                :Join("inner","Table","","lower(Column.Name) = lower(concat('fk_',Table.Name))")
            case par_nSyncSetForeignKey == 5
                :Where("right(Column.Name,3) = ^" , "_id")
                :Where("Column.Default is null")
                :Join("inner","Table","","lower(Column.Name) = lower(concat(Table.Name,'_id'))")
            endcase
                
            :Where("Column.Type = ^ or Column.Type = ^ " , "I","IB")
            :Where("Column.DocStatus <= 1")

            :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
            :Where("NameSpace.fk_Application = ^",par_iApplicationPk)

            :Where("Column.fk_TableForeign = 0")
            :SQL("FieldToMarkAsForeignKeys")

            // SendToClipboard(:LastSQL())
            // ExportTableToHtmlFile("FieldToMarkAsForeignKeys","d:\PostgreSQL_FieldToMarkAsForeignKeys.html","From PostgreSQL",,25,.t.)

            if :Tally > 0
                with object l_oDB2
                    select FieldToMarkAsForeignKeys
                    scan for FieldToMarkAsForeignKeys->Column_UseStatus <= 2  // Only  1 = Unknown and 2 = Proposed" can be auto linked
                        :Table("606f3256-52c4-4e12-ada1-33a7f48d327c","Column")
                        :Field("Column.fk_TableForeign" , FieldToMarkAsForeignKeys->Table_pk)
                        if :Update(FieldToMarkAsForeignKeys->Column_pk)
                            l_iUpdatedColumns += 1
                        else
                            l_cErrorMessage := "Failed to update Column fk_TableForeign."
                            exit
                        endif
                    endscan
                endwith
            endif
        endif
    endwith
endif


do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL

case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL

    //--Load Indexes----------------
    if empty(l_cErrorMessage)
        if !SQLExec(par_SQLHandle,l_cSQLCommandIndexes,"ListOfIndexesForLoads")
            l_cErrorMessage := "Failed to retrieve Fields Meta data."
        else
            // ExportTableToHtmlFile("ListOfIndexesForLoads","d:\PostgreSQL_ListOfIndexesForLoads.html","From PostgreSQL",,200,.t.)

            l_cLastNameSpace  := ""
            l_cLastTableName  := ""
            l_cIndexName      := ""

            select ListOfIndexesForLoads
            scan all while empty(l_cErrorMessage)
                if !(ListOfIndexesForLoads->schema_name == l_cLastNameSpace .and. ListOfIndexesForLoads->table_name == l_cLastTableName)
                    l_cLastNameSpace := ListOfIndexesForLoads->schema_name
                    l_cLastTableName := ListOfIndexesForLoads->table_name
                    l_iTablePk       := hb_HGetDef(l_hTables,l_cLastNameSpace+"."+l_cLastTableName,0)

                    with object l_oDB2
                        :Table("9888318c-7195-4f75-9fbb-c102440aacd3","Index")
                        :Column("Index.Pk"         ,"Pk")
                        :Column("Index.Name"       ,"Index_Name")
                        :Column("Index.Unique"     ,"Index_Unique")
                        :Column("Index.Algo"       ,"Index_Algo")
                        :Column("Index.Expression" ,"Index_Expression")
                        :Column("upper(Index.Name)","tag1")
                        :Where("Index.fk_Table = ^", l_iTablePk)
                        :SQL("ListOfIndexesInDataDictionary")
                        if :Tally < 0
                            l_cErrorMessage := [Failed to Get index info.]
                        else
                            with object :p_oCursor
                                :Index("tag1","tag1+'*'")
                                :CreateIndexes()
                            endwith
                        endif
                    endwith

                endif

                if empty(l_cErrorMessage) .and. l_iTablePk > 0
                    l_cIndexName       := ListOfIndexesForLoads->index_name
                    l_cIndexExpression := ListOfIndexesForLoads->index_definition

                    l_lIndexUnique := ("CREATE UNIQUE INDEX" $ l_cIndexExpression)
                    if "USING btree" $ l_cIndexExpression
                        l_iIndexAlgo := 1
                    else
                        l_iIndexAlgo := 0
                    endif

                    l_nPos := at("(",l_cIndexExpression)
                    if l_nPos > 0
                        l_cIndexExpression := SubStr(l_cIndexExpression,l_nPos+1)
                        l_nPos := rat(")",l_cIndexExpression)
                        if l_nPos > 0
                            l_cIndexExpression := left(l_cIndexExpression,l_nPos-1)
                        endif
                    endif
                    
                    if vfp_Seek(upper(l_cIndexName)+'*',"ListOfIndexesInDataDictionary","tag1")
                        l_iIndexPk := ListOfIndexesInDataDictionary->Pk

                        if !(trim(nvl(ListOfIndexesInDataDictionary->Index_Name,"")) == l_cIndexName) .or. ;
                            ListOfIndexesInDataDictionary->Index_Unique <> l_lIndexUnique             .or. ;
                            ListOfIndexesInDataDictionary->Index_Algo <> l_iIndexAlgo                 .or. ;
                            ListOfIndexesInDataDictionary->Index_Expression <> l_cIndexExpression

                            with object l_oDB1
                                :Table("200c26df-5127-4d07-b381-0d44ccd7aee7","Index")
                                :Field("Index.Name"       ,l_cIndexName)
                                :Field("Index.Unique"     ,l_lIndexUnique)
                                :Field("Index.Algo"       ,l_iIndexAlgo)
                                :Field("Index.Expression" ,l_cIndexExpression)
                                if :Update(l_iIndexPk)
                                    l_iUpdatedIndexes += 1
                                else
                                    l_cErrorMessage := [Failed to update Index Name.]
                                endif
                            endwith

                        else

                        endif

                    else
                        //Missing Index
                        with object l_oDB1
                            :Table("a785c331-8a68-4f1e-b86a-2df09140d1a6","Index")
                            :Field("Index.Name"      ,l_cIndexName)
                            :Field("Index.fk_Table"  ,l_iTablePk)
                            :Field("Index.UseStatus" ,1)
                            :Field("Index.UsedBy"    ,1)
                            :Field("Index.Unique"    ,l_lIndexUnique)
                            :Field("Index.Algo"      ,l_iIndexAlgo)
                            :Field("Index.Expression",l_cIndexExpression)
                            if :Add()
                                l_iNewIndexes += 1
                                l_iIndexPk := :Key()
                            else
                                l_cErrorMessage := "Failed to add Index record."
                            endif
                        endwith

                    endif
                endif
            endscan
        endif
    endif

case par_SQLEngineType == HB_ORM_ENGINETYPE_MSSQL

endcase

//--Final Return Info-----------

if empty(l_cErrorMessage)
    l_cErrorMessage := "Success"

    if !empty(l_iNewTables)       .or. ;
       !empty(l_iNewNameSpace)    .or. ;
       !empty(l_iNewColumns)      .or. ;
       !empty(l_iUpdatedColumns)  .or. ;
       !empty(l_iNewEnumerations) .or. ;
       !empty(l_iNewEnumValues)   .or. ;
       !empty(l_iNewIndexes)      .or. ;
       !empty(l_iUpdatedIndexes)

        if !empty(l_iNewTables)
            l_cErrorMessage += [  New Tables: ]+trans(l_iNewTables)
        endif
        if !empty(l_iNewNameSpace)
            l_cErrorMessage += [  New Name Spaces: ]+trans(l_iNewNameSpace)
        endif
        if !empty(l_iNewColumns)
            l_cErrorMessage += [  New Columns: ]+trans(l_iNewColumns)
        endif
        if !empty(l_iUpdatedColumns)
            l_cErrorMessage += [  Updated Columns: ]+trans(l_iUpdatedColumns)
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
        if !empty(l_iUpdatedIndexes)
            l_cErrorMessage += [  Updated Indexes: ]+trans(l_iUpdatedIndexes)
        endif
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

return l_cErrorMessage
//-----------------------------------------------------------------------------------------------------------------
