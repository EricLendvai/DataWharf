#include "DataWharf.ch"
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function FixNonNormalizeFieldsInPackage(par_iModelPk)
local l_oCursor1 := hb_Cursor()
local l_oDB_ListOfCurrentRecords := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

CreateCursorTreeStructureForPackage(l_oCursor1,par_iModelPk)
// ExportTableToHtmlFile("CursorTreeStructureForPackage",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_CursorTreeStructureForPackage.html","From PostgreSQL",,,.t.)

with object l_oCursor1
    select CursorTreeStructureForPackage
    :Index("pk","pk")
    :CreateIndexes()
endwith

with object l_oDB_ListOfCurrentRecords
    :Table("c1237c5e-b0b9-40cc-b006-a62cc90cb3e1","Package")
    :Column("Package.pk"         , "pk"               )
    :Column("Package.FullName"   , "Package_FullName"  )
    :Column("Package.FullPk"     , "Package_FullPk"   )
    :Column("Package.TreeOrder1" , "Package_TreeOrder1")
    :Column("Package.TreeLevel"  , "Package_TreeLevel" )
    :Where("Package.fk_Model = ^",par_iModelPk)
    :SQL("ListOfPackage_Current")
endwith

with object l_oDB1
    select ListOfPackage_Current
    scan all
        if el_seek(ListOfPackage_Current->pk,"CursorTreeStructureForPackage","pk")
            if ListOfPackage_Current->Package_FullName   <> CursorTreeStructureForPackage->FullName .or. ;
               ListOfPackage_Current->Package_FullPk     <> CursorTreeStructureForPackage->FullPk   .or. ;
               ListOfPackage_Current->Package_TreeOrder1 <> CursorTreeStructureForPackage->recno    .or. ;
               ListOfPackage_Current->Package_TreeLevel  <> CursorTreeStructureForPackage->Level

                :Table("302ab98c-48a8-460e-adc2-adf371b665f7","Package")
                :Field("Package.FullName"   , CursorTreeStructureForPackage->FullName)
                :Field("Package.FullPk"     , CursorTreeStructureForPackage->FullPk)
                :Field("Package.TreeOrder1" , CursorTreeStructureForPackage->recno)
                :Field("Package.TreeLevel"  , CursorTreeStructureForPackage->Level)
                :Update(ListOfPackage_Current->pk)

            endif
        else
            // Part of a looped structure
            if !(" (In a Loop)" $ ListOfPackage_Current->Package_FullName)
                :Table("3bf93baa-4ec1-4eaf-aad3-e923111fb50a","Package")
                :Field("Package.FullName"   , ListOfPackage_Current->Package_FullName + " (In a Loop)")
                :Update(ListOfPackage_Current->pk)
            endif
        endif
    endscan
endwith

return NIL
//=================================================================================================================
//=================================================================================================================
function CreateCursorTreeStructureForPackage(p_oCursor1,par_iModelPk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_Counter
local l_NumberOfOptions
local l_Package_pk
local l_Package_name
local l_select := iif(used(),select(),0)
local l_aSQLResult := {}

with object p_oCursor1
    :Field("pk"          ,"I",  0,0)
    :Field("fk_pk"       ,"I",  0,0)
    :Field("Level"       ,"I",  0,0)
    :Field("Package_name","C",200,0)
    :Field("recno"       ,"I",  0,0)
    :Field("p_recno"     ,"I",  0,0)
    :Field("FullName"    ,"M",  0,0)
    :Field("FullPk"      ,"M",  0,0)
    :CreateCursor("CursorTreeStructureForPackage")
endwith

with object l_oDB1
    :Table("ff644726-248e-441a-81a5-affb9a4705cc","Package")
    :Column("Package.pk"         ,"pk")
    :Column("Package.Name"       ,"name")
    :Column("upper(Package.Name)","tag1")
    :Where("Package.fk_Model = ^",par_iModelPk)
    // :Where("Package.fk_Package IS NULL")
    :Where("Package.fk_Package = 0")
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions := :Tally
    // SendToClipboard(l_oDB1:LastSQL())
endwith

if l_NumberOfOptions > 0
    for l_Counter = 1 to l_NumberOfOptions
        l_Package_pk   := l_aSQLResult[l_Counter,1]
        l_Package_name := alltrim(l_aSQLResult[l_Counter,2])
        CreateCursorTreeStructureForPackage_Branch(p_oCursor1,1,0,alltrim(l_Package_name),trans(l_Package_pk),l_Package_pk,0,l_Package_name)
    endfor
endif

select (l_select)
return NIL
//=================================================================================================================
function CreateCursorTreeStructureForPackage_Branch(par_oCursor1,par_Level,par_p_recno,par_FullName,par_FullPk,par_Package_pk,par_Package_Fk_Package,par_Package_name)

local l_Counter
local l_NumberOfOptions
local l_recno
local l_Package_pk
local l_Package_name
local l_aSQLResult := {}
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object par_oCursor1
    select CursorTreeStructureForPackage
    :AppendBlank()
    l_recno = recno()
    :SetFieldValue("recno"        , l_recno)
    :SetFieldValue("p_recno"      , par_p_recno)
    :SetFieldValue("pk"           , par_Package_pk)
    :SetFieldValue("fk_pk"        , par_Package_Fk_Package)
    :SetFieldValue("level"        , par_Level)
    :SetFieldValue("Package_name" , par_Package_name)
    :SetFieldValue("FullName"     , par_FullName)
    :SetFieldValue("FullPk"       , par_FullPk)
endwith

with object l_oDB1
    :Table("5092f60f-ac0d-4b9c-826d-1c483de0acb2","Package")
    :Column("Package.pk"         ,"pk")
    :Column("Package.name"       ,"name")
    :Column("upper(Package.name)","tag1")
    :Where("Package.fk_Package = ^",par_Package_pk)
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions = l_oDB1:Tally
endwith

if l_NumberOfOptions > 0
    
    for l_Counter = 1 to l_NumberOfOptions
        l_Package_pk   := l_aSQLResult[l_Counter,1]
        l_Package_Name := alltrim(l_aSQLResult[l_Counter,2])

        if ("*"+Trans(l_Package_pk)+"*" $ "*"+par_FullPk+"*")
            SendToDebugView("Looping on "+l_Package_Name)   // Should not happen but this is preventative code in case of corrupted data
        else
            CreateCursorTreeStructureForPackage_Branch(par_oCursor1,par_Level+1,l_recno,par_FullName+" / "+alltrim(l_Package_name),par_FullPk+"*"+trans(l_Package_pk),l_Package_pk,par_Package_pk,l_Package_name)
        endif

    endfor
    
endif

return NIL
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function FixNonNormalizeFieldsInDataType(par_iModelPk)
local l_oCursor1 := hb_Cursor()
local l_oDB_ListOfCurrentRecords := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

CreateCursorTreeStructureForDataType(l_oCursor1,par_iModelPk)
// ExportTableToHtmlFile("CursorTreeStructureForDataType",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_CursorTreeStructureForDataType.html","From PostgreSQL",,,.t.)

with object l_oCursor1
    select CursorTreeStructureForDataType
    :Index("pk","pk")
    :CreateIndexes()
endwith

with object l_oDB_ListOfCurrentRecords
    :Table("9b4185e4-19e9-4b60-b83d-1303353994ba","DataType")
    :Column("DataType.pk"         , "pk"               )
    :Column("DataType.FullName"   , "DataType_FullName"  )
    :Column("DataType.FullPk"     , "DataType_FullPk"   )
    :Column("DataType.TreeOrder1" , "DataType_TreeOrder1")
    :Column("DataType.TreeLevel"  , "DataType_TreeLevel" )
    :Where("DataType.fk_Model = ^",par_iModelPk)
    :SQL("ListOfDataType_Current")
endwith

with object l_oDB1
    select ListOfDataType_Current
    scan all
        if el_seek(ListOfDataType_Current->pk,"CursorTreeStructureForDataType","pk")
            if ListOfDataType_Current->DataType_FullName   <> CursorTreeStructureForDataType->FullName .or. ;
               ListOfDataType_Current->DataType_FullPk     <> CursorTreeStructureForDataType->FullPk   .or. ;
               ListOfDataType_Current->DataType_TreeOrder1 <> CursorTreeStructureForDataType->recno    .or. ;
               ListOfDataType_Current->DataType_TreeLevel  <> CursorTreeStructureForDataType->Level

                :Table("50f6300e-0a7a-4089-9487-1755d72334d8","DataType")
                :Field("DataType.FullName"   , CursorTreeStructureForDataType->FullName)
                :Field("DataType.FullPk"     , CursorTreeStructureForDataType->FullPk)
                :Field("DataType.TreeOrder1" , CursorTreeStructureForDataType->recno)
                :Field("DataType.TreeLevel"  , CursorTreeStructureForDataType->Level)
                :Update(ListOfDataType_Current->pk)

            endif
        else
            // Part of a looped structure
            if !(" (In a Loop)" $ ListOfDataType_Current->DataType_FullName)
                :Table("3df322f5-6fb6-4aa5-9840-d430216fb41c","DataType")
                :Field("DataType.FullName"   , ListOfDataType_Current->DataType_FullName + " (In a Loop)")
                :Update(ListOfDataType_Current->pk)
            endif
        endif
    endscan
endwith

return NIL
//=================================================================================================================
//=================================================================================================================
function CreateCursorTreeStructureForDataType(p_oCursor1,par_iModelPk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_Counter
local l_NumberOfOptions
local l_DataType_pk
local l_DataType_name
local l_select := iif(used(),select(),0)
local l_aSQLResult := {}

with object p_oCursor1
    :Field("pk"          ,"I",  0,0)
    :Field("fk_pk"       ,"I",  0,0)
    :Field("Level"       ,"I",  0,0)
    :Field("DataType_name","C",200,0)
    :Field("recno"       ,"I",  0,0)
    :Field("p_recno"     ,"I",  0,0)
    :Field("FullName"    ,"M",  0,0)
    :Field("FullPk"      ,"M",  0,0)
    :CreateCursor("CursorTreeStructureForDataType")
endwith

with object l_oDB1
    :Table("b01645ef-3068-485c-9889-59ee7151ee60","DataType")
    :Column("DataType.pk"         ,"pk")
    :Column("DataType.Name"       ,"name")
    :Column("upper(DataType.Name)","tag1")
    :Where("DataType.fk_Model = ^",par_iModelPk)
    // :Where("DataType.fk_DataType IS NULL")
    :Where("DataType.fk_DataType = 0")
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions := :Tally
    // SendToClipboard(l_oDB1:LastSQL())
endwith

if l_NumberOfOptions > 0
    for l_Counter = 1 to l_NumberOfOptions
        l_DataType_pk   := l_aSQLResult[l_Counter,1]
        l_DataType_name := alltrim(l_aSQLResult[l_Counter,2])
        CreateCursorTreeStructureForDataType_Branch(p_oCursor1,1,0,alltrim(l_DataType_name),trans(l_DataType_pk),l_DataType_pk,0,l_DataType_name)
    endfor
endif

select (l_select)
return NIL
//=================================================================================================================
function CreateCursorTreeStructureForDataType_Branch(par_oCursor1,par_Level,par_p_recno,par_FullName,par_FullPk,par_DataType_pk,par_DataType_Fk_DataType,par_DataType_name)

local l_Counter
local l_NumberOfOptions
local l_recno
local l_DataType_pk
local l_DataType_name
local l_aSQLResult := {}
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object par_oCursor1
    select CursorTreeStructureForDataType
    :AppendBlank()
    l_recno = recno()
    :SetFieldValue("recno"         , l_recno)
    :SetFieldValue("p_recno"       , par_p_recno)
    :SetFieldValue("pk"            , par_DataType_pk)
    :SetFieldValue("fk_pk"         , par_DataType_Fk_DataType)
    :SetFieldValue("level"         , par_Level)
    :SetFieldValue("DataType_name" , par_DataType_name)
    :SetFieldValue("FullName"      , par_FullName)
    :SetFieldValue("FullPk"        , par_FullPk)
endwith

with object l_oDB1
    :Table("c58e17a5-d053-4ae8-b3b5-fecfdc910545","DataType")
    :Column("DataType.pk"         ,"pk")
    :Column("DataType.name"       ,"name")
    :Column("upper(DataType.name)","tag1")
    :Where("DataType.fk_DataType = ^",par_DataType_pk)
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions = l_oDB1:Tally
endwith

if l_NumberOfOptions > 0
    
    for l_Counter = 1 to l_NumberOfOptions
        l_DataType_pk   := l_aSQLResult[l_Counter,1]
        l_DataType_Name := alltrim(l_aSQLResult[l_Counter,2])

        if ("*"+Trans(l_DataType_pk)+"*" $ "*"+par_FullPk+"*")
            SendToDebugView("Looping on "+l_DataType_Name)   // Should not happen but this is preventative code in case of corrupted data
        else
            CreateCursorTreeStructureForDataType_Branch(par_oCursor1,par_Level+1,l_recno,par_FullName+" / "+alltrim(l_DataType_name),par_FullPk+"*"+trans(l_DataType_pk),l_DataType_pk,par_DataType_pk,l_DataType_name)
        endif

    endfor
    
endif

return NIL
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function FixNonNormalizeFieldsInAttribute(par_iEntityPk)
local l_oCursor1 := hb_Cursor()
local l_oDB_ListOfCurrentRecords := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

CreateCursorTreeStructureForAttribute(l_oCursor1,par_iEntityPk)
// ExportTableToHtmlFile("CursorTreeStructureForAttribute",OUTPUT_FOLDER+hb_ps()+"PostgreSQL_CursorTreeStructureForAttribute.html","From PostgreSQL",,,.t.)

with object l_oCursor1
    select CursorTreeStructureForAttribute
    :Index("pk","pk")
    :CreateIndexes()
endwith

with object l_oDB_ListOfCurrentRecords
    :Table("29784d2c-a891-4853-a1f2-531074015724","Attribute")
    :Column("Attribute.pk"         , "pk"               )
    :Column("Attribute.FullName"   , "Attribute_FullName"  )
    :Column("Attribute.FullPk"     , "Attribute_FullPk"   )
    :Column("Attribute.TreeOrder1" , "Attribute_TreeOrder1")
    :Column("Attribute.TreeLevel"  , "Attribute_TreeLevel" )
    :Where("Attribute.fk_Entity = ^",par_iEntityPk)
    :SQL("ListOfAttribute_Current")
endwith

with object l_oDB1
    select ListOfAttribute_Current
    scan all
        if el_seek(ListOfAttribute_Current->pk,"CursorTreeStructureForAttribute","pk")
            if ListOfAttribute_Current->Attribute_FullName   <> CursorTreeStructureForAttribute->FullName .or. ;
               ListOfAttribute_Current->Attribute_FullPk     <> CursorTreeStructureForAttribute->FullPk   .or. ;
               ListOfAttribute_Current->Attribute_TreeOrder1 <> CursorTreeStructureForAttribute->recno    .or. ;
               ListOfAttribute_Current->Attribute_TreeLevel  <> CursorTreeStructureForAttribute->Level

                :Table("ed27a712-16c1-4030-94f3-82ecdc6cb240","Attribute")
                :Field("Attribute.FullName"   , CursorTreeStructureForAttribute->FullName)
                :Field("Attribute.FullPk"     , CursorTreeStructureForAttribute->FullPk)
                :Field("Attribute.TreeOrder1" , CursorTreeStructureForAttribute->recno)
                :Field("Attribute.TreeLevel"  , CursorTreeStructureForAttribute->Level)
                :Update(ListOfAttribute_Current->pk)

            endif
        else
            // Part of a looped structure
            if !(" (In a Loop)" $ ListOfAttribute_Current->Attribute_FullName)
                :Table("77fa6670-307e-4840-993a-f8c2e473833e","Attribute")
                :Field("Attribute.FullName"   , ListOfAttribute_Current->Attribute_FullName + " (In a Loop)")
                :Update(ListOfAttribute_Current->pk)
            endif
        endif
    endscan
endwith

return NIL
//=================================================================================================================
//=================================================================================================================
function CreateCursorTreeStructureForAttribute(p_oCursor1,par_iEntityPk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_Counter
local l_NumberOfOptions
local l_Attribute_pk
local l_Attribute_name
local l_select := iif(used(),select(),0)
local l_aSQLResult := {}

with object p_oCursor1
    :Field("pk"            ,"I",  0,0)
    :Field("fk_pk"         ,"I",  0,0)
    :Field("Level"         ,"I",  0,0)
    :Field("Attribute_name","C",200,0)
    :Field("recno"         ,"I",  0,0)
    :Field("p_recno"       ,"I",  0,0)
    :Field("FullName"      ,"M",  0,0)
    :Field("FullPk"        ,"M",  0,0)
    :CreateCursor("CursorTreeStructureForAttribute")
endwith

with object l_oDB1
    :Table("28cef911-d2db-4ff9-a193-4a9640287c37","Attribute")
    :Column("Attribute.pk"         ,"pk")
    :Column("Attribute.Name"       ,"name")
    // :Column("upper(Attribute.Name)","tag1")
    :Column("Attribute.Treeorder1","tag1")
    :Where("Attribute.fk_Entity = ^",par_iEntityPk)
    // :Where("Attribute.fk_Attribute IS NULL")
    :Where("Attribute.fk_Attribute = 0")
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions := :Tally
    // SendToClipboard(l_oDB1:LastSQL())
endwith

if l_NumberOfOptions > 0
    for l_Counter = 1 to l_NumberOfOptions
        l_Attribute_pk   := l_aSQLResult[l_Counter,1]
        l_Attribute_name := alltrim(l_aSQLResult[l_Counter,2])
        CreateCursorTreeStructureForAttribute_Branch(p_oCursor1,1,0,alltrim(l_Attribute_name),trans(l_Attribute_pk),l_Attribute_pk,0,l_Attribute_name)
    endfor
endif

select (l_select)
return NIL
//=================================================================================================================
function CreateCursorTreeStructureForAttribute_Branch(par_oCursor1,par_Level,par_p_recno,par_FullName,par_FullPk,par_Attribute_pk,par_Attribute_Fk_Attribute,par_Attribute_name)

local l_Counter
local l_NumberOfOptions
local l_recno
local l_Attribute_pk
local l_Attribute_name
local l_aSQLResult := {}
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object par_oCursor1
    select CursorTreeStructureForAttribute
    :AppendBlank()
    l_recno = recno()
    :SetFieldValue("recno"          , l_recno)
    :SetFieldValue("p_recno"        , par_p_recno)
    :SetFieldValue("pk"             , par_Attribute_pk)
    :SetFieldValue("fk_pk"          , par_Attribute_Fk_Attribute)
    :SetFieldValue("level"          , par_Level)
    :SetFieldValue("Attribute_name" , par_Attribute_name)
    :SetFieldValue("FullName"       , par_FullName)
    :SetFieldValue("FullPk"         , par_FullPk)
endwith

with object l_oDB1
    :Table("18e5cb21-075f-46f1-bb40-238ec2da4b33","Attribute")
    :Column("Attribute.pk"         ,"pk")
    :Column("Attribute.name"       ,"name")
//    :Column("upper(Attribute.name)","tag1")
    :Column("Attribute.Treeorder1","tag1")
    :Where("Attribute.fk_Attribute = ^",par_Attribute_pk)
    :OrderBy("tag1")
    :SQL(@l_aSQLResult)
    l_NumberOfOptions = l_oDB1:Tally
endwith

if l_NumberOfOptions > 0
    
    for l_Counter = 1 to l_NumberOfOptions
        l_Attribute_pk   := l_aSQLResult[l_Counter,1]
        l_Attribute_Name := alltrim(l_aSQLResult[l_Counter,2])

        if ("*"+Trans(l_Attribute_pk)+"*" $ "*"+par_FullPk+"*")
            SendToDebugView("Looping on "+l_Attribute_Name)   // Should not happen but this is preventative code in case of corrupted data
        else
            CreateCursorTreeStructureForAttribute_Branch(par_oCursor1,par_Level+1,l_recno,par_FullName+" / "+alltrim(l_Attribute_name),par_FullPk+"*"+trans(l_Attribute_pk),l_Attribute_pk,par_Attribute_pk,l_Attribute_name)
        endif

    endfor
    
endif

return NIL
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
