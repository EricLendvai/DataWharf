#include "DataWharf.ch"
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function ExportToHbORM(par_iApplicationPk)

local l_lContinue := .t.
local l_oDB_ListOfTables
local l_oDB_ListOfColumns
local l_oDB_ListOfIndexes

local l_iTablePk := 0

local l_cIndent := space(3)
local l_cSchemaAndTableName

local l_nNumberOfFields
local l_nNumberOfIndexes

local l_cSourceCode := ""
local l_cSourceCodeFields
local l_nMaxNameLength
local l_nMaxExpressionLength
local l_cFieldName
local l_cFieldType
local l_nFieldLen
local l_nFieldDec
local l_cFieldDefault
local l_lFieldAllowNull
local l_lFieldAutoIncrement
local l_lFieldArray
local l_cFieldAttributes
local l_cIndexName
local l_cSourceCodeIndexes
local l_cIndexExpression
local l_nIndexRecno

local lnEnumerationImplementAs
local lnEnumerationImplementLength

l_oDB_ListOfTables  := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfColumns := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB_ListOfIndexes := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfTables
    :Table("299a129d-dab1-4dad-afcf-e85ecde6b2f1","NameSpace")
    // :Distinct(.t.)  // Needed since joining on columns to not use discontinued fields

    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table" ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")

    :Column("max(length(Column.Name))" , "MaxColumnNameLength")

    :Column("NameSpace.Name"        ,"NameSpace_Name")
    :Column("Table.Name"            ,"Table_Name")
    :Column("Table.Pk"              ,"Table_pk")
    :Column("upper(NameSpace.Name)" ,"tag1")
    :Column("upper(Table.Name)"     ,"tag2")

    :GroupBy("NameSpace_Name")
    :GroupBy("Table_Name")
    :GroupBy("Table_pk")
    :GroupBy("tag1")
    :GroupBy("tag2")

    :Where("NameSpace.UseStatus <= 5")
    :Where("Table.UseStatus     <= 5")
    :Where("Column.UseStatus    <= 5")

    :OrderBy("tag1")
    :OrderBy("tag2")

    :SQL("ListOfTables")
    if :Tally < 0
        l_lContinue := .f.
        l_cSourceCode += :LastSQL() + CRLF
    endif
    // l_cSourceCode += :LastSQL() + CRLF   // Used to see how the changes to beautify code is done in the Harbour_ORM
endwith


if l_lContinue
    with object l_oDB_ListOfColumns
        :Table("b5520562-d6dc-48a1-8b11-1daf9255257c","NameSpace")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Join("inner","Table" ,"","Table.fk_NameSpace = NameSpace.pk")
        :Join("inner","Column","","Column.fk_Table = Table.pk")
        :Join("left","Enumeration","","Column.fk_Enumeration = Enumeration.pk")
        :Column("Table.Pk"       ,"Table_Pk")
        :Column("Column.Name"    ,"Column_Name")
        :Column("Column.Order"   ,"Column_Order")
        :Column("Column.Type"    ,"Column_Type")
        :Column("Column.Length"  ,"Column_Length")
        :Column("Column.Scale"   ,"Column_Scale")
        :Column("Column.Nullable","Column_Nullable")
        :Column("Column.Array"   ,"Column_Array")
        :Column("Column.Primary" ,"Column_Primary")
        :Column("Column.Unicode" ,"Column_Unicode")
        :Column("Column.Default" ,"Column_Default")

        :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
        :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")

        :Where("NameSpace.UseStatus <= 5")
        :Where("Table.UseStatus <= 5")
        :Where("Column.UseStatus <= 5")
        :SQL("ListOfColumns")
        if :Tally < 0
            l_lContinue := .f.
        else
            with object :p_oCursor
                :Index("tag1","strtran(str(Table_pk,10)+str(Column_Order,10),' ','0')")   // Fixed length of the numbers with leading '0'
                :CreateIndexes()
            endwith
        endif
    endwith
endif

if l_lContinue
    with object l_oDB_ListOfIndexes
        :Table("b2c17764-e2e0-485a-a780-68f4997b38ee","NameSpace")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :Join("inner","Table"      ,"","Table.fk_NameSpace = NameSpace.pk")
        :Join("inner","Index"      ,"","Index.fk_Table = Table.pk")
        :Join("inner","IndexColumn","","IndexColumn.fk_Index = Index.pk")
        :Join("inner","Column"     ,"","IndexColumn.fk_Column = Column.pk")

        // :Column("max(length(Index.Name))" , "MaxIndexNameLength")

        :Column("Table.Pk"         ,"Table_Pk")
        :Column("Index.Name"       ,"Index_Name")
        :Column("Index.Expression" ,"Index_Expression")
        :Column("Index.Unique"     ,"Index_Unique")
        :Column("Index.Algo"       ,"Index_Algo")
        :Column("upper(Index.Name)","tag1")

        :Where("NameSpace.UseStatus <= 5")
        :Where("Table.UseStatus <= 5")
        :Where("Index.UseStatus <= 5")
        :Where("Column.UseStatus <= 5")
        
        :SQL("ListOfIndexes")
        if :Tally < 0
            l_lContinue := .f.
        else
            with object :p_oCursor
                :Index("tag1","strtran(str(Table_pk,10),' ','0')+Index_Name")   // Fixed length of the number with leading '0'
                :CreateIndexes()
            endwith
        endif
    endwith
endif


if l_lContinue

    // select ListOfTables
    // scan all
    //     l_iTablePk := ListOfTables->Table_Pk

    //     l_nNumberOfFields := 0
    //     if vfp_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfColumns","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
    //         select ListOfColumns
    //         scan while ListOfColumns->Table_Pk = l_iTablePk
    //             l_nNumberOfFields++  //Just to test if the following code works
    //         endscan
    //     endif

    //     l_nNumberOfIndexes := 0
    //     if vfp_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfIndexes","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
    //         select ListOfIndexes
    //         scan while ListOfIndexes->Table_Pk = l_iTablePk
    //             l_nNumberOfIndexes++  //Just to test if the following code works
    //         endscan
    //     endif

    //     l_cSourceCode += "Table "+ListOfTables->Table_Name+" has "+trans(l_nNumberOfFields)+" fields and has "+trans(l_nNumberOfIndexes)+" indexes."+CRLF

    // endscan


    select ListOfTables
    scan all
        l_iTablePk := ListOfTables->Table_Pk

        l_cSchemaAndTableName := alltrim(ListOfTables->NameSpace_Name)+"."+alltrim(ListOfTables->Table_Name)


        l_cSourceCode += iif(empty(l_cSourceCode),"{",",")
        l_cSourceCode += '"'+l_cSchemaAndTableName+'"'+"=>{;   /"+"/Field Definition"
        
        //Get Field Definitions
        l_cSourceCodeFields := ""
        l_nMaxNameLength := ListOfTables->MaxColumnNameLength







        l_nNumberOfFields := 0
        if vfp_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfColumns","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
            select ListOfColumns
            scan while ListOfColumns->Table_Pk = l_iTablePk
                l_nNumberOfFields++  //Just to test if the following code works

                l_cFieldName        := ListOfColumns->Column_Name
                l_cSourceCodeFields += iif(empty(l_cSourceCodeFields) , CRLF+l_cIndent+"{" , ";"+CRLF+l_cIndent+"," )
            
                l_cFieldType          := allt(ListOfColumns->Column_Type)
                l_nFieldLen           := nvl(ListOfColumns->Column_Length,0)
                l_nFieldDec           := nvl(ListOfColumns->Column_Scale,0)
                l_cFieldDefault       := nvl(ListOfColumns->Column_Default,"")
                l_lFieldAllowNull     := ListOfColumns->Column_Nullable
                l_lFieldAutoIncrement := ListOfColumns->Column_Primary
                l_lFieldArray         := ListOfColumns->Column_Array
                l_cFieldAttributes    := iif(l_lFieldAllowNull,"N","")+iif(l_lFieldAutoIncrement,"+","")+iif(l_lFieldArray,"A","")

//             if lower(l_cFieldName) == lower(::p_PrimaryKeyFieldName)
//                 l_lFieldAutoIncrement := .t.
//             endif

                if l_cFieldType == "E"
                    lnEnumerationImplementAs     := nvl(ListOfColumns->Enumeration_ImplementAs,0)
                    lnEnumerationImplementLength := nvl(ListOfColumns->Enumeration_ImplementLength,0)

                    // EnumerationImplementAs   1 = Native SQL Enum, 2 = Integer, 3 = Numeric, 4 = Var Char (EnumValue Name)
                    do case
                    case lnEnumerationImplementAs == 2
                        l_cFieldType := "I"
                        l_nFieldLen  := nil
                        l_nFieldDec  := nil
                    case lnEnumerationImplementAs == 3
                        l_cFieldType := "N"
                        l_nFieldLen  := lnEnumerationImplementLength
                        l_nFieldDec  := 0
                    endcase
                endif

                if l_lFieldAutoIncrement .and. empty(el_inlist(l_cFieldType,"I","IB","IS"))  //Only those fields types may be flagged as Auto-Increment
                    l_lFieldAutoIncrement := .f.
                endif
                if l_lFieldAutoIncrement .and. l_lFieldAllowNull  //Auto-Increment fields may not be null (and not have a default)
                    l_lFieldAllowNull := .f.
                endif


                l_cSourceCodeFields += padr('"'+l_cFieldName+'"',l_nMaxNameLength+2)+"=>{"
                l_cSourceCodeFields += ","  // Null Value for the HB_ORM_SCHEMA_INDEX_BACKEND_TYPES 
                l_cSourceCodeFields += padl('"'+l_cFieldType+'"',5)+","+;
                                    str(nvl(l_nFieldLen,0),4)+","+;
                                    str(nvl(l_nFieldDec,0),3)+","+;
                                    iif(empty(l_cFieldAttributes),"",'"'+l_cFieldAttributes+'"')
                if !empty(l_cFieldDefault)
                    l_cSourceCodeFields += ',"'+strtran(l_cFieldDefault,["],["+'"'+"])+'"'
                endif
                l_cSourceCodeFields += "}"

            endscan

            l_cSourceCodeFields += "}"
            l_cSourceCode += l_cSourceCodeFields+";"+CRLF+l_cIndent+",;   /"+"/Index Definition"


        endif

        l_nNumberOfIndexes := 0
        if vfp_seek(strtran(str(l_iTablePk,10),' ','0'),"ListOfIndexes","tag1")   // Takes advantage of only doing a seek on the first 10 character of the index.
            l_cSourceCodeIndexes   := ""
            l_nMaxNameLength       := 0
            l_nMaxExpressionLength := 0

            select ListOfIndexes
            l_nIndexRecno := Recno()
            scan while ListOfIndexes->Table_Pk = l_iTablePk  // Pre scan the index to help determine the l_nMaxNameLength
                l_nMaxNameLength       := max(l_nMaxNameLength      ,len(ListOfIndexes->Index_Name))

                l_cIndexExpression     := ListOfIndexes->Index_Expression
                l_cIndexExpression     := strtran(l_cIndexExpression,["],[]) // remove PostgreSQL token delimiter. Will be added as needed when creating indexes.
                l_cIndexExpression     := strtran(l_cIndexExpression,['],[]) // remove MySQL token delimiter. Will be added as needed when creating indexes.
                l_nMaxExpressionLength := max(l_nMaxExpressionLength,len(l_cIndexExpression))
            endscan
            dbGoTo(l_nIndexRecno)

            scan while ListOfIndexes->Table_Pk = l_iTablePk
                l_nNumberOfIndexes++  //Just to test if the following code works

                l_cIndexName       := ListOfIndexes->Index_Name

                l_cIndexExpression := ListOfIndexes->Index_Expression
                l_cIndexExpression := strtran(l_cIndexExpression,["],[]) // remove PostgreSQL token delimiter. Will be added as needed when creating indexes.
                l_cIndexExpression := strtran(l_cIndexExpression,['],[]) // remove MySQL token delimiter. Will be added as needed when creating indexes.
                
                l_cSourceCodeIndexes += iif(empty(l_cSourceCodeIndexes) , CRLF+l_cIndent+"{" , ";"+CRLF+l_cIndent+",")

                l_cSourceCodeIndexes += padr('"'+l_cIndexName+'"',l_nMaxNameLength+2)+"=>{"
                l_cSourceCodeIndexes += "," // HB_ORM_SCHEMA_FIELD_BACKEND_TYPES
                l_cSourceCodeIndexes += '"'+l_cIndexExpression+'"'+space(l_nMaxExpressionLength-len(l_cIndexExpression))+','+;
                                    iif(ListOfIndexes->Index_Unique,".t.",".f.")+","+;
                                    '"'+"BTREE"+'"'    //Later make this aware of ListOfIndexes->Index_Algo
                l_cSourceCodeIndexes += "}"

            endscan
            l_cSourceCode += l_cSourceCodeIndexes+"}};"+CRLF
        else
            l_cSourceCode += CRLF+l_cIndent+"NIL};"+CRLF
        endif

        // l_cSourceCode += "Table "+ListOfTables->Table_Name+" has "+trans(l_nNumberOfFields)+" fields and has "+trans(l_nNumberOfIndexes)+" indexes. MaxColumnNameLength = "+trans(ListOfTables->MaxColumnNameLength)+CRLF

    endscan

    if !empty(l_cSourceCode)
        l_cSourceCode += "}"
    endif

endif


if !l_lContinue
    l_cSourceCode += [/]+[/ error]
endif

return l_cSourceCode
//=================================================================================================================
