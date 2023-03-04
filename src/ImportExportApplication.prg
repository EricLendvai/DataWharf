#include "DataWharf.ch"
//=================================================================================================================
function ExportApplicationToHbORM(par_iApplicationPk)

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
    :Table("299a129d-dab1-4dad-afcf-000000000001","NameSpace")
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
        :Table("299a129d-dab1-4dad-afcf-000000000002","NameSpace")
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
        :Table("299a129d-dab1-4dad-afcf-000000000003","NameSpace")
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
                :Index("tag1","padr(strtran(str(Table_pk,10),' ','0')+Index_Name,240)")   // Fixed length of the number with leading '0'
                :CreateIndexes()
            endwith
        endif
    endwith
endif

if l_lContinue

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
//=================================================================================================================
function ExportApplicationForImports(par_iApplicationPk)
local l_cBackupCode := ""

local l_lContinue := .t.
local l_oDB_ListOfRecords  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_hSchema := Schema()

local l_oDB_ListOfFileStream := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_FileStream       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ApplicationInfo  := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cFilePathPID
local l_cFilePathUser
local l_iKey
local l_cLinkUID
local l_cFileName
local l_oInfo

hb_HCaseMatch(l_hSchema,.f.)  // Case Insensitive search

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000004","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"NameSpace")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"NameSpace","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000005","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table" ,"","Table.fk_NameSpace = NameSpace.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Table")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Table","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000006","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"  ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column" ,"","Column.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Column")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Column","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000007","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Enumeration" ,"","Enumeration.fk_NameSpace = NameSpace.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Enumeration")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Enumeration","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000008","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Enumeration"  ,"","Enumeration.fk_NameSpace = NameSpace.pk")
    :Join("inner","EnumValue" ,"","EnumValue.fk_Enumeration = Enumeration.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"EnumValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"EnumValue","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000009","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"  ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Index" ,"","Index.fk_Table = Table.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Index")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Index","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000010","NameSpace")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Join("inner","Table"       ,"","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Index"       ,"","Index.fk_Table = Table.pk")
    :Join("inner","IndexColumn" ,"","IndexColumn.fk_Index = Index.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"IndexColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"IndexColumn","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000011","Diagram")
    :Where("Diagram.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Diagram")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Diagram","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000012","Diagram")
    :Where("Diagram.fk_Application = ^",par_iApplicationPk)
    :Join("inner","DiagramTable" ,"","DiagramTable.fk_Diagram = Diagram.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"DiagramTable")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"DiagramTable","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000013","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"Tag")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"Tag","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000014","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Join("inner","TagTable" ,"","TagTable.fk_Tag = Tag.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"TagTable")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"TagTable","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000015","Tag")
    :Where("Tag.fk_Application = ^",par_iApplicationPk)
    :Join("inner","TagColumn" ,"","TagColumn.fk_Tag = Tag.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"TagColumn")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"TagColumn","ListOfRecords")
    endif
endwith

// ----- Custom Field Begin ------------------------------------------------------
with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000016","ApplicationCustomField")
    :Distinct(.t.)
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
    :Join("inner","CustomField" ,"","ApplicationCustomField.fk_CustomField = CustomField.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"CustomField")

    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"CustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000016","ApplicationCustomField")
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)

    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"ApplicationCustomField")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"ApplicationCustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("299a129d-dab1-4dad-afcf-000000000017","ApplicationCustomField")
    :Distinct(.t.)
    :Where("ApplicationCustomField.fk_Application = ^",par_iApplicationPk)
    :Join("inner","CustomFieldValue" ,"","CustomFieldValue.fk_CustomField = ApplicationCustomField.fk_CustomField")

    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn <= ^" , USEDON_MODEL)

    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hSchema,"CustomFieldValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hSchema,"CustomFieldValue","ListOfRecords")
    endif
endwith
// ----- Custom Field End ------------------------------------------------------

if l_lContinue
    l_cBackupCode += CRLF

    l_cFilePathPID := GetStreamFileFolderForCurrentProcess()

    vfp_StrToFile(l_cBackupCode,l_cFilePathPID+"Export.txt")

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
function DataDictionaryImportStep1FormBuild(par_iPk,par_cErrorText)

local l_cHtml := ""
local l_cErrorText         := hb_DefaultValue(par_cErrorText,"")

local l_cMessageLine

oFcgi:TraceAdd("DataDictionaryImportStep1FormBuild")

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
            l_cHtml += [<span class="navbar-brand ms-3">Import</span>]   //navbar-text
            // l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" value="Delta" onclick="$('#ActionOnSubmit').val('Delta');document.form.submit();" role="button">]
            l_cHtml += [<button type="button" class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmImportModal">Import</button>]

            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
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
case vfp_inlist(l_cActionOnSubmit,"Import")

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

        endif

    endif

case l_cActionOnSubmit == "Cancel"
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

local l_hNameSpacePkOldToNew   := {=>}
local l_hTablePkOldToNew       := {=>}
local l_hColumnPkOldToNew      := {=>}
local l_hEnumerationPkOldToNew := {=>}
local l_hIndexPkOldToNew       := {=>}
local l_hDiagramPkOldToNew     := {=>}
local l_hTagPkOldToNew         := {=>}
local l_hCustomFieldPkOldToNew := {=>}

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
                if vfp_inlist(l_cCursorFieldType,"C","CV","M")
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
// NameSpace
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
// Import NameSpaces
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000001","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Column("NameSpace.Pk"  ,"pk")
    :Column("NameSpace.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceNameSpace
scan all
    if vfp_seek( upper(strtran(ImportSourceNameSpace->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: NameSpace Already on file",ListOfCurrentRecords->Name)
        l_hNameSpacePkOldToNew[ImportSourceNameSpace->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000002","NameSpace")
            :Field("fk_Application",par_iApplicationPk)
            ImportAddRecordSetField(l_oDBImport,"NameSpace","*fk_Application*")
            if :Add()
                //Log the old key, new key
                l_hNameSpacePkOldToNew[ImportSourceNameSpace->pk] := :Key()
            endif
            // VFP_StrToFile(:LastSQL(),"d:\LastSQL.txt")
            
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Tables
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000003","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table","","Table.fk_NameSpace = NameSpace.pk")
    :Column("Table.fk_NameSpace","fk_NameSpace")
    :Column("Table.Pk"          ,"pk")
    :Column("Table.Name"        ,"name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_NameSpace))+'*'+upper(strtran(Name,' ',''))+'*',240)")  // IMPORTANT - Had to Pad the index expression otherwise the searcher would only work on the shortest string. Also could not use trans(), had to use Harbour native functions.
        :CreateIndexes()
    endwith
endwith

// ExportTableToHtmlFile("ListOfCurrentRecords",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ListOfCurrentRecords.html","From PostgreSQL",,,.t.)

select ImportSourceTable
scan all
    l_iParentKeyImport  := ImportSourceTable->fk_NameSpace
    l_iParentKeyCurrent := hb_HGetDef(l_hNameSpacePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find NameSpace Parent Key on Table Import" ,l_iParentKeyImport)
    else
        //In the index search could not use trans() for some reason it left leading blanks
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceTable->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Table Already on file in NameSpace (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hTablePkOldToNew[ImportSourceTable->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000004","Table")
                :Field("fk_NameSpace",l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Table","*fk_NameSpace*")
                if :Add()
                    //Log the old key, new key
                    l_hTablePkOldToNew[ImportSourceTable->pk] := :Key()
                endif
                // VFP_StrToFile(:LastSQL(),"d:\LastSQL.txt")
                
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Enumerations
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000005","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Enumeration","","Enumeration.fk_NameSpace = NameSpace.pk")
    :Column("Enumeration.fk_NameSpace","fk_NameSpace")
    :Column("Enumeration.Pk"  ,"pk")
    :Column("Enumeration.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_NameSpace))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceEnumeration
scan all
    l_iParentKeyImport  := ImportSourceEnumeration->fk_NameSpace
    l_iParentKeyCurrent := hb_HGetDef(l_hNameSpacePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find NameSpace Parent Key on Enumeration Import" ,l_iParentKeyImport)
    else
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceEnumeration->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Enumeration Already on file in NameSpace (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hEnumerationPkOldToNew[ImportSourceEnumeration->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000006","Enumeration")
                :Field("fk_NameSpace",l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Enumeration","*fk_NameSpace*")
                if :Add()
                    //Log the old key, new key
                    l_hEnumerationPkOldToNew[ImportSourceEnumeration->pk] := :Key()
                endif
                // VFP_StrToFile(:LastSQL(),"d:\LastSQL.txt")
                
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Columns

with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000007","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table" ,"" ,"Table.fk_NameSpace = NameSpace.pk")
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceColumn->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Column Already on file in Table (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hColumnPkOldToNew[ImportSourceColumn->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000008","Column")
                :Field("fk_Table"       ,l_iParentKeyCurrent)
                :Field("fk_TableForeign",l_ifk_TableForeignCurrent)
                :Field("fk_Enumeration" ,l_ifk_EnumerationCurrent)
                ImportAddRecordSetField(l_oDBImport,"Column","*fk_Table*fk_TableForeign*fk_Enumeration*")
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
    :Table("df873645-94d3-4ba5-85cf-000000000009","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Enumeration","","Enumeration.fk_NameSpace = NameSpace.pk")
    :Join("inner","EnumValue"  ,"","EnumValue.fk_Enumeration = Enumeration.pk")
    :Column("EnumValue.fk_Enumeration","fk_Enumeration")
    :Column("EnumValue.Pk"  ,"pk")
    :Column("EnumValue.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Enumeration))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceEnumValue
scan all
    l_iParentKeyImport  := ImportSourceEnumValue->fk_Enumeration
    l_iParentKeyCurrent := hb_HGetDef(l_hEnumerationPkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Enumeration Parent Key on EnumValue Import" ,l_iParentKeyImport)
    else
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceEnumValue->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: EnumValue Already on file in Enumeration (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000010","EnumValue")
                :Field("fk_Enumeration"       ,l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"EnumValue","*fk_Enumeration*")
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Index
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000011","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table","","Table.fk_NameSpace = NameSpace.pk")
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
scan all
    l_iParentKeyImport  := ImportSourceIndex->fk_Table
    l_iParentKeyCurrent := hb_HGetDef(l_hTablePkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Table Parent Key on Index Import" ,l_iParentKeyImport)
    else
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceIndex->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Index Already on file in Table (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hIndexPkOldToNew[ImportSourceIndex->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000012","Index")
                :Field("fk_Table"       ,l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"Index","*fk_Table*")
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
    :Table("df873645-94d3-4ba5-85cf-000000000013","NameSpace")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :Join("inner","Table"      ,"","Table.fk_NameSpace = NameSpace.pk")
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_ColumnCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Column Already on file in Index (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000014","IndexColumn")
                :Field("fk_Index"  ,l_iParentKeyCurrent)
                :Field("fk_Column" ,l_ifk_ColumnCurrent)
                ImportAddRecordSetField(l_oDBImport,"IndexColumn","*fk_Index*fk_Column*")   // No other field exists but leaving this in case we add some.
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Diagrams
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
scan all
    if vfp_seek( upper(strtran(ImportSourceDiagram->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
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
            ImportAddRecordSetField(l_oDBImport,"Diagram","*fk_Application*VisPos*MxgPos*")
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_TableCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Table Already on file in Diagram (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000018","DiagramTable")
                :Field("fk_Diagram",l_iParentKeyCurrent)
                :Field("fk_Table"  ,l_ifk_TableCurrent)
                ImportAddRecordSetField(l_oDBImport,"DiagramTable","*fk_Diagram*fk_Table*")   // No other field exists but leaving this in case we add some.
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Tags
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
scan all
    if vfp_seek( upper(strtran(ImportSourceTag->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        l_hTagPkOldToNew[ImportSourceTag->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000020","Tag")
            :Field("fk_Application",par_iApplicationPk)
            ImportAddRecordSetField(l_oDBImport,"Tag","*fk_Application*")
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_TableCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Table Already on file in Tag (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000022","TagTable")
                :Field("fk_Tag"    ,l_iParentKeyCurrent)
                :Field("fk_Table"  ,l_ifk_TableCurrent)
                ImportAddRecordSetField(l_oDBImport,"TagTable","*fk_Tag*fk_Table*")   // No other field exists but leaving this in case we add some.
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_ColumnCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Column Already on file in Tag (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000024","TagColumn")
                :Field("fk_Tag"    ,l_iParentKeyCurrent)
                :Field("fk_Column" ,l_ifk_ColumnCurrent)
                ImportAddRecordSetField(l_oDBImport,"TagColumn","*fk_Tag*fk_Column*")   // No other field exists but leaving this in case we add some.
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Custom Fields

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
scan all

    l_hImportSourceCustomFieldUsedOn[ImportSourceCustomField->pk] := ImportSourceCustomField->UsedOn

    if vfp_seek( upper(strtran(ImportSourceCustomField->Code,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        l_hCustomFieldPkOldToNew[ImportSourceCustomField->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000026","CustomField")
            ImportAddRecordSetField(l_oDBImport,"CustomField","")
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
scan all

    l_ifk_CustomFieldImport:= ImportSourceApplicationCustomField->fk_CustomField
    if hb_IsNil(l_ifk_CustomFieldImport) .or. hb_IsNil(l_ifk_CustomFieldImport)
        l_ifk_CustomFieldCurrent := 0
    else
        l_ifk_CustomFieldCurrent := hb_HGetDef(l_hCustomFieldPkOldToNew,l_ifk_CustomFieldImport,0)
    endif

    if vfp_seek(l_ifk_CustomFieldCurrent ,"ListOfCurrentRecords","tag1")
        // Record already on file
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000027","ApplicationCustomField")
            :Field("fk_Application" ,par_iApplicationPk)
            :Field("fk_CustomField" ,l_ifk_CustomFieldCurrent)
            ImportAddRecordSetField(l_oDBImport,"ApplicationCustomField","*fk_Application*fk_CustomField*")   // No other field exists but leaving this in case we add some.
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
            l_ifk_EntityCurrent := hb_HGetDef(l_hNameSpacePkOldToNew,l_ifk_EntityImport,0)
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
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_EntityCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: CustomFieldValue Already on file in CustomField (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000029","CustomFieldValue")
                :Field("fk_CustomField" ,l_iParentKeyCurrent)
                :Field("fk_Entity"      ,l_ifk_EntityCurrent)
                ImportAddRecordSetField(l_oDBImport,"CustomFieldValue","*fk_CustomField*fk_Entity*")
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------

return nil
//=================================================================================================================
