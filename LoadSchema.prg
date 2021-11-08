#include "DataDictionary.ch"
memvar oFcgi

#include "dbinfo.ch"
#include "hb_orm.ch"

function LoadSchema(par_SQLHandle,par_iApplicationPk,par_SQLEngineType,par_cDatabase,par_cSyncNameSpaces)
local l_SQLCommandFields := []
local l_SQLCommandIndexes := []
local l_aNameSpaces
local l_iPosition
local l_iFirstNameSpace := .t.

local l_cLastNameSpace
local l_cLastTableName
local l_cColumnName
local l_iNameSpacePk
local l_iTablePk
local l_iColumnPk
local l_LastColumnOrder

local l_cColumnType
local l_iColumnLength
local l_iColumnScale

local l_oDB1
local l_oDB2
local l_aSQLResult := {}
local l_cErrorMessage := ""

local l_iNewTables      := 0
local l_iNewNameSpace   := 0
local l_iNewColumns     := 0
local l_iUpdatedColumns := 0

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case par_SQLEngineType == HB_ORM_ENGINETYPE_MYSQL
    l_SQLCommandFields  += [SELECT columns.table_name                 AS table_name,]
    l_SQLCommandFields  += [       columns.ordinal_position           AS field_position,]
    l_SQLCommandFields  += [       columns.column_name                AS field_name,]
    l_SQLCommandFields  += [       columns.data_type                  AS field_type,]
    l_SQLCommandFields  += [       columns.column_comment             AS field_comment,]
    l_SQLCommandFields  += [       columns.character_maximum_length   AS field_clength,]
    l_SQLCommandFields  += [       columns.numeric_precision          AS field_nlength,]
    l_SQLCommandFields  += [       columns.datetime_precision         AS field_tlength,]
    l_SQLCommandFields  += [       columns.numeric_scale              AS field_decimals,]
    l_SQLCommandFields  += [       (columns.is_nullable = 'YES')      AS field_nullable,]
    l_SQLCommandFields  += [       columns.column_default             AS field_default,]
    l_SQLCommandFields  += [       (columns.extra = 'auto_increment') AS field_identity_is,]
    l_SQLCommandFields  += [       upper(columns.table_name)          AS tag1]
    l_SQLCommandFields  += [ FROM information_schema.columns]
    l_SQLCommandFields  += [ WHERE columns.table_schema = ']+par_cDatabase+[']
    l_SQLCommandFields  += [ AND   lower(left(columns.table_name,11)) != 'schemacache']
    l_SQLCommandFields  += [ ORDER BY tag1,field_position]


    l_SQLCommandIndexes += [SELECT table_name,]
    l_SQLCommandIndexes += [       index_name,]
    l_SQLCommandIndexes += [       group_concat(column_name order by seq_in_index) AS index_columns,]
    l_SQLCommandIndexes += [       index_type,]
    l_SQLCommandIndexes += [       CASE non_unique]
    l_SQLCommandIndexes += [            WHEN 1 then 0]
    l_SQLCommandIndexes += [            ELSE 1]
    l_SQLCommandIndexes += [            END AS is_unique]
    l_SQLCommandIndexes += [ FROM information_schema.statistics]
    l_SQLCommandIndexes += [ WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys')]
    l_SQLCommandIndexes += [ AND   index_schema = ']+par_cDatabase+[']
    l_SQLCommandIndexes += [ AND   lower(left(table_name,11)) != 'schemacache']
    l_SQLCommandIndexes += [ GROUP BY table_name,index_name]
    l_SQLCommandIndexes += [ ORDER BY index_schema,table_name,index_name;]

case par_SQLEngineType == HB_ORM_ENGINETYPE_POSTGRESQL
    l_SQLCommandFields  := [SELECT columns.table_schema             AS schema_name,]
    l_SQLCommandFields  += [       columns.table_name               AS table_name,]
    l_SQLCommandFields  += [       columns.ordinal_position         AS field_position,]
    l_SQLCommandFields  += [       columns.column_name              AS field_name,]
    l_SQLCommandFields  += [       columns.data_type                AS field_type,]
    l_SQLCommandFields  += [       columns.character_maximum_length AS field_clength,]
    l_SQLCommandFields  += [       columns.numeric_precision        AS field_nlength,]
    l_SQLCommandFields  += [       columns.datetime_precision       AS field_tlength,]
    l_SQLCommandFields  += [       columns.numeric_scale            AS field_decimals,]
    l_SQLCommandFields  += [       (columns.is_nullable = 'YES')    AS field_nullable,]
    l_SQLCommandFields  += [       columns.column_default           AS field_default,]
    l_SQLCommandFields  += [       (columns.is_identity = 'YES')    AS field_identity_is,]
    l_SQLCommandFields  += [       upper(columns.table_schema)      AS tag1,]
    l_SQLCommandFields  += [       upper(columns.table_name)        AS tag2]
    l_SQLCommandFields  += [ FROM information_schema.columns]
    l_SQLCommandFields  += [ WHERE NOT (lower(left(columns.table_name,11)) = 'schemacache' OR lower(columns.table_schema) in ('information_schema','pg_catalog'))]

    if !empty(par_cSyncNameSpaces)
        l_SQLCommandFields  += [ AND lower(columns.table_schema) in (]
        l_aNameSpaces := hb_ATokens(par_cSyncNameSpaces,",",.f.)
        for l_iPosition := 1 to len(l_aNameSpaces)
            l_aNameSpaces[l_iPosition] := strtran(l_aNameSpaces[l_iPosition],['],[])
            if !empty(l_aNameSpaces[l_iPosition])
                if l_iFirstNameSpace
                    l_iFirstNameSpace := .f.
                else
                    l_SQLCommandFields += [,]
                endif
                l_SQLCommandFields += [']+lower(l_aNameSpaces[l_iPosition])+[']
            endif
        endfor
        l_SQLCommandFields  += [)]
    endif

    l_SQLCommandFields  += [ ORDER BY tag1,tag2,field_position]

// SendToClipboard(l_SQLCommandFields)


    l_SQLCommandIndexes := [SELECT pg_indexes.schemaname        AS schema_name,]
    l_SQLCommandIndexes += [       pg_indexes.tablename         AS table_name,]
    l_SQLCommandIndexes += [       pg_indexes.indexname         AS index_name,]
    l_SQLCommandIndexes += [       pg_indexes.indexdef          AS index_definition,]
    l_SQLCommandIndexes += [       upper(pg_indexes.schemaname) AS tag1,]
    l_SQLCommandIndexes += [       upper(pg_indexes.tablename)  AS tag2]
    l_SQLCommandIndexes += [ FROM pg_indexes]
    l_SQLCommandIndexes += [ WHERE NOT (lower(left(pg_indexes.tablename,11)) = 'schemacache' OR lower(pg_indexes.schemaname) in ('information_schema','pg_catalog'))]
    l_SQLCommandIndexes += [ ORDER BY tag1,tag2,index_name]


    if SQLExec(par_SQLHandle,l_SQLCommandFields,"ListOfFieldsForLoads")
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
                    :Table("Table")
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
                        :Table("NameSpace")
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
                            :Table("NameSpace")
                            :Field("Name" , l_cLastNameSpace)
                            :Field("fk_Application" , par_iApplicationPk)
                            :Field("Status" , 1)
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
                            :Table("Table")
                            :Field("Name"         , l_cLastTableName)
                            :Field("fk_NameSpace" , l_iNameSpacePk)
                            :Field("Status"       , 1)
                            if :Add()
                                l_iNewTables += 1
                                l_iTablePk := :Key()
                            else
                                l_cErrorMessage := "Failed to add Table record."
                            endif
                        endif

                    case :Tally == 1
                        l_iNameSpacePk   := l_aSQLResult[1,1]
                        l_iTablePk       := l_aSQLResult[1,2]

                    otherwise
                        l_cErrorMessage := "Failed to Query Meta database. Error 104."
                    endcase

                endwith

                // Load all the tables current columns
                with object l_oDB2
                    :Table("Column")
                    :Column("Column.Pk"             , "Pk")
                    :Column("Column.Order"          , "Column_Order")
                    :Column("Column.Name"           , "Column_Name")
                    :Column("upper(Column.Name)"    , "tag1")
                    :Column("Column.Type"           , "Column_Type")
                    :Column("Column.Length"         , "Column_Length")
                    :Column("Column.Scale"          , "Column_Scale")
                    :Column("Column.fk_Enumeration" , "Column_fk_Enumeration")
                    :Where("Column.fk_Table = ^" , l_iTablePk)
                    :OrderBy("Column_Order","Desc")
                    :SQL("ListOfColumnsInDataDictionary")

                    if :Tally < 0
                        l_cErrorMessage := "Failed to load Meta Data Columns. Error 105."
                    else
                        if :Tally == 0
                            l_LastColumnOrder := 0
                        else
                            l_LastColumnOrder := ListOfColumnsInDataDictionary->Column_Order
                        endif

                        With Object :p_oCursor
                            :Index("tag1","tag1")
                            :CreateIndexes()
                            // :SetOrder("tag1")
                        endwith

                    endif

                endwith

            endif

            if empty(l_cErrorMessage)
                //Check existence of Column and add if needed
                //Get the column Name, Type, Length, Scale and fk_Enumeration
                l_cColumnName := alltrim(ListOfFieldsForLoads->field_name)

                switch ListOfFieldsForLoads->field_type
                case "integer"
                    l_cColumnType   := "I"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "bigint"
                    l_cColumnType   := "IB"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "numeric"
                    l_cColumnType   := "N"
                    l_iColumnLength := ListOfFieldsForLoads->field_nlength
                    l_iColumnScale  := ListOfFieldsForLoads->field_decimals
                    exit

                case "character"
                    l_cColumnType   := "C"
                    l_iColumnLength := field->field_clength
                    l_iColumnScale  := 0
                    exit

                case "character varying"
                    l_cColumnType   := "CV"
                    l_iColumnLength := field->field_clength
                    l_iColumnScale  := 0
                    exit

                case "bit"
                    l_cColumnType   := "B"
                    l_iColumnLength := field->field_clength
                    l_iColumnScale  := 0
                    exit

                case "bit varying"
                    l_cColumnType   := "BV"
                    l_iColumnLength := field->field_clength
                    l_iColumnScale  := 0
                    exit

                case "text"
                    l_cColumnType   := "M"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "bytea"
                    l_cColumnType   := "R"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "boolean"
                    l_cColumnType   := "L"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "date"
                    l_cColumnType   := "D"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "time"
                case "time with time zone"
                    l_cColumnType   := "TOZ"
                    l_iColumnLength := 0
                    l_iColumnScale  := field->field_tlength
                    exit

                case "time without time zone"
                    l_cColumnType   := "TO"
                    l_iColumnLength := 0
                    l_iColumnScale  := field->field_tlength
                    exit

                case "timestamp"
                case "timestamp with time zone"
                    l_cColumnType   := "DTZ"
                    l_iColumnLength := 0
                    l_iColumnScale  := field->field_tlength
                    exit

                case "timestamp without time zone"
                    l_cColumnType   := "DT"
                    l_iColumnLength := 0
                    l_iColumnScale  := field->field_tlength
                    exit

                case "money"
                    l_cColumnType   := "Y"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                case "uuid"
                    l_cColumnType   := "UUI"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    exit

                // case "xxxxxx"
                //     l_cColumnType   := "xxx"
                //     l_iColumnLength := 0
                //     l_iColumnScale  := 0
                //     exit

                otherwise
                    l_cColumnType   := "?"
                    l_iColumnLength := 0
                    l_iColumnScale  := 0
                    // Altd()
                endcase


                if vfp_Seek(upper(l_cColumnName),"ListOfColumnsInDataDictionary","tag1")
                    l_iColumnPk := ListOfColumnsInDataDictionary->Pk
                    if trim(nvl(ListOfColumnsInDataDictionary->Column_Type,"")) == l_cColumnType   .and. ;
                       nvl(ListOfColumnsInDataDictionary->Column_Length,0)      == l_iColumnLength .and. ;
                       nvl(ListOfColumnsInDataDictionary->Column_Scale,0)       == l_iColumnScale

                    else

                        if l_cColumnType <> "?" .or. (hb_orm_isnull("ListOfColumnsInDataDictionary","Column_Type") .or. empty(ListOfColumnsInDataDictionary->Column_Type))
                            with object l_oDB1
                                l_LastColumnOrder += 1
                                :Table("Column")
                                :Field("Type"  ,l_cColumnType)
                                :Field("Length",l_iColumnLength)
                                :Field("Scale" ,l_iColumnScale)
                                if :Update(l_iColumnPk)
                                    l_iUpdatedColumns += 1
                                else
                                    l_cErrorMessage := "Failed to update Column record."
                                endif
                            endwith
                        endif

                    endif

                else
                    //Missing Field, Add it
                    with object l_oDB1
                        l_LastColumnOrder += 1
                        :Table("Column")
                        :Field("Name"    ,l_cColumnName)
                        :Field("Order"   ,l_LastColumnOrder)
                        :Field("fk_Table",l_iTablePk)
                        :Field("Status"  ,1)
                        :Field("Type"    ,l_cColumnType)
                        :Field("Length"  ,l_iColumnLength)
                        :Field("Scale"   ,l_iColumnScale)
                        :Field("UsedBy"  ,1)
                        if :Add()
                            l_iNewColumns += 1
                            l_iColumnPk := :Key()
                        else
                            l_cErrorMessage := "Failed to add Column record."
                        endif
                    endwith

                endif

            endif

        endscan

    endif

endcase

if empty(l_cErrorMessage)
    l_cErrorMessage := "Success"
    if !empty(l_iNewTables) .or. !empty(l_iNewNameSpace) .or. !empty(l_iNewColumns) .or. !empty(l_iUpdatedColumns)
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
    endif
endif

return l_cErrorMessage












//-----------------------------------------------------------------------------------------------------------------
static function SQLExec(par_SQLHandle,par_Command,par_cCursorName)
local l_cPreviousDefaultRDD := RDDSETDEFAULT("SQLMIX")
local l_lSQLExecResult := .f.
local l_oError
local l_select := iif(used(),select(),0)
local cErrorInfo
local l_cSQLExecErrorMessage

l_cSQLExecErrorMessage:= ""
if par_SQLHandle > 0
    try
        if pcount() == 3
            CloseAlias(par_cCursorName)
            select 0  //Ensure we don't overwrite any other work area
            l_lSQLExecResult := DBUseArea(.t.,"SQLMIX",par_Command,par_cCursorName,.t.,.t.,"UTF8",par_SQLHandle)
            if l_lSQLExecResult
                //There is a bug with reccount() when using SQLMIX. So to force loading all the data, using goto bottom+goto top
                dbGoBottom()
                dbGoTop()
            endif
        else
            l_lSQLExecResult := hb_RDDInfo(RDDI_EXECUTE,par_Command,"SQLMIX",par_SQLHandle)
        endif

        if !l_lSQLExecResult
            l_cSQLExecErrorMessage := "SQLExec Error Code: "+Trans(hb_RDDInfo(RDDI_ERRORNO))+" - Error description: "+alltrim(hb_RDDInfo(RDDI_ERROR))
        endif
    catch l_oError
        l_lSQLExecResult := .f.  //Just in case the catch occurs after DBUserArea / hb_RDDInfo
        l_cSQLExecErrorMessage := "SQLExec Error Code: "+Trans(l_oError:oscode)+" - Error description: "+alltrim(l_oError:description)+" - Operation: "+l_oError:operation
        // Idea for later  ::SQLSendToLogFileAndMonitoringSystem(0,1,l_SQLCommand+[ -> ]+l_cSQLExecErrorMessage)  _M_
    endtry

    if !empty(l_cSQLExecErrorMessage)
        cErrorInfo := hb_StrReplace(l_cSQLExecErrorMessage+" - Command: "+par_Command+iif(pcount() < 3,""," - Cursor Name: "+par_cCursorName),{chr(13)=>" ",chr(10)=>""})
        hb_orm_SendToDebugView(cErrorInfo)
    endif

endif

RDDSETDEFAULT(l_cPreviousDefaultRDD)
select (l_select)
    
return l_lSQLExecResult
//-----------------------------------------------------------------------------------------------------------------
