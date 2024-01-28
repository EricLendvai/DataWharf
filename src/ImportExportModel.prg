#include "DataWharf.ch"
//=================================================================================================================
//=================================================================================================================
function ExportModelForImports(par_iModelPk)
local l_cBackupCode := ""

local l_lContinue := .t.
local l_hTableSchema         := oFcgi:p_WharfConfig["Tables"]
local l_oDB_ListOfRecords    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfFileStream := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_FileStream       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ModelInfo        := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cFilePathPID
local l_cFilePathUser
local l_iKey
local l_cLinkUID
local l_cFileName
local l_oModelInfo

oFcgi:p_o_SQLConnection:SetForeignKeyNullAndZeroParity(.f.)  //To ensure we keep the null values

hb_HCaseMatch(l_hTableSchema,.f.)  // Case Insensitive search

with object l_oDB_ModelInfo
    :Table("edb07440-470b-4a37-8467-b81a8e23bf4a","Model")
    :Join("inner","Project","","Model.fk_Project = Project.pk")
    :Column("Project.Name"    ,"Project_Name")
    :Column("Model.Name"      ,"Model_Name")
    :Column("Model.fk_Project","Project_pk")
    l_oModelInfo := :Get(par_iModelPk)
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000001","Entity")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Entity")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Entity","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000002","Package")
    :Where("Package.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Package")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Package","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000003","Association")
    :Where("Association.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Association")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Association","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000004","DataType")
    :Where("DataType.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"DataType")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"DataType","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000005","ModelEnumeration")
    :Where("ModelEnumeration.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ModelEnumeration")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ModelEnumeration","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000006","ModelEnumeration")
    :Where("ModelEnumeration.fk_Model = ^",par_iModelPk)
    :Join("inner","ModelEnumValue" ,"","ModelEnumValue.fk_ModelEnumeration = ModelEnumeration.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ModelEnumValue")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ModelEnumValue","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000007","Entity")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    :Join("inner","Attribute" ,"","Attribute.fk_Entity = Entity.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Attribute")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Attribute","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000008","Entity")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    :Join("inner","Endpoint" ,"","Endpoint.fk_Entity = Entity.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"Endpoint")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"Endpoint","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000009","DataType")
    :Where("DataType.fk_Model = ^",par_iModelPk)
    :Join("inner","PrimitiveType" ,"","DataType.fk_PrimitiveType = PrimitiveType.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"PrimitiveType")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"PrimitiveType","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000010","ModelingDiagram")
    :Where("ModelingDiagram.fk_Model = ^",par_iModelPk)
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ModelingDiagram")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ModelingDiagram","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000011","ModelingDiagram")
    :Where("ModelingDiagram.fk_Model = ^",par_iModelPk)
    :Join("inner","DiagramEntity" ,"","DiagramEntity.fk_ModelingDiagram = ModelingDiagram.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"DiagramEntity")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"DiagramEntity","ListOfRecords")
    endif
endwith

// ----- Custom Field Begin ------------------------------------------------------
with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000012","ProjectCustomField")
    :Distinct(.t.)
    :Where("ProjectCustomField.fk_Project = ^",l_oModelInfo:Project_pk)
    :Join("inner","CustomField" ,"","ProjectCustomField.fk_CustomField = CustomField.pk")
    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"CustomField")

    :Where("CustomField.UsedOn >= ^" , USEDON_ENTITY)
    
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"CustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000013","ProjectCustomField")
    :Where("ProjectCustomField.fk_Project = ^",l_oModelInfo:Project_pk)

    :Join("inner","CustomField","","ProjectCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn >= ^" , USEDON_ENTITY)

    ExportForImports_GetFields(l_oDB_ListOfRecords,l_hTableSchema,"ProjectCustomField")
    :OrderBy("pk")
    :SQL("ListOfRecords")
    if :Tally < 0
        l_lContinue := .f.
    else
        l_cBackupCode += ExportForImports_Cursor(l_hTableSchema,"ProjectCustomField","ListOfRecords")
    endif
endwith

with object l_oDB_ListOfRecords
    :Table("8795599c-bb2a-4f1f-8ee7-000000000014","ProjectCustomField")
    :Distinct(.t.)
    :Where("ProjectCustomField.fk_Project = ^",l_oModelInfo:Project_pk)
    :Join("inner","CustomFieldValue" ,"","CustomFieldValue.fk_CustomField = ProjectCustomField.fk_CustomField")

    :Join("inner","CustomField","","ProjectCustomField.fk_CustomField = CustomField.pk")
    :Where("CustomField.UsedOn >= ^" , USEDON_ENTITY)

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


//Order of Table Export
//======================
// Entity
// Package
// Association
// DataType
// ModelEnumeration
// ModelEnumValue
// Attribute
// Endpoint
// Primitive
// ModelingDiagram
// DiagramEntity

if l_lContinue
    l_cBackupCode += CRLF

    l_cFilePathPID := GetStreamFileFolderForCurrentProcess()

    vfp_StrToFile(l_cBackupCode,l_cFilePathPID+"Export.txt")

    hb_ZipFile(l_cFilePathPID+"Export.zip",l_cFilePathPID+"Export.txt",9,,.t.)
    DeleteFile(l_cFilePathPID+"Export.txt")

    //_M_ Add a Sanitizing function for l_oModelInfo:Application_Name
    l_cFileName := "ExportModel_"+strtran(l_oModelInfo:Project_Name+"-"+l_oModelInfo:Model_Name," ","_")+"_"+GetZuluTimeStampForFileNameSuffix()+".zip"

    //Try to find if we already have a streamfile
    with object l_oDB_ListOfFileStream
        :Table("36b191e4-39b5-4ee3-bd58-4cf39da5d882","volatile.FileStream","FileStream")
        :Column("FileStream.pk"     ,"pk")
        :Column("FileStream.LinkUID","LinkUID")
        :Where("FileStream.fk_User = ^"  , oFCgi:p_iUserPk)
        :Where("FileStream.fk_Model = ^" , par_iModelPk)
        :Where("FileStream.type = 3")
        :SQL("ListOfFileStream")
        do case
        case :Tally < 0
            //Error
            l_iKey := 0
        case :Tally == 1
            l_iKey     := ListOfFileStream->pk
            l_cLinkUID := ListOfFileStream->LinkUID
            if !l_oDB_FileStream:SaveFile("f50e774d-d353-4834-8b88-5619fdb086b9","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
                l_cFilePathUser := GetStreamFileFolderForCurrentUser()
                hb_vfMoveFile(l_cFilePathPID+"Export.zip",l_cFilePathUser+"Export"+trans(l_iKey)+".zip")
            endif
            with object l_oDB_FileStream
                :Table("d3c44e42-08d1-441c-a1ba-22be051aff7b","volatile.FileStream","FileStream")
                :Field("FileName" , l_cFileName)
                if :Update(l_iKey)
                endif
            endwith
        otherwise
            if :Tally > 1 //Bad data.
                select ListOfFileStream
                scan all
                    l_oDB_FileStream:Delete("d301991b-2c4a-42c9-bab5-3c1f9d4dddc5","volatile.FileStream",ListOfFileStream->pk)
                endscan
            endif

            with object l_oDB_FileStream
                l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Table("0d0d09af-1080-4f87-a1ab-d345060730f4","volatile.FileStream","FileStream")
                :Field("fk_User"        , oFCgi:p_iUserPk)
                :Field("fk_Model"       , par_iModelPk)
                :Field("type"           , 3)
                :Field("LinkUID"        , l_cLinkUID)
                :Field("FileName"       , l_cFileName)
                if :Add()
                    l_iKey := :Key()
                    if !l_oDB_FileStream:SaveFile("f8a1facb-a2fa-4ed8-85c6-5bb61989ab83","volatile.FileStream",l_iKey,"oid",l_cFilePathPID+"Export.zip")
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
function ModelImportStep1FormBuild(par_iPk,par_cErrorText)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

oFcgi:TraceAdd("ModelImportStep1FormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Steo1">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="ModelKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

if !empty(par_iPk)
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">Import</span>]   //navbar-text
            if oFcgi:p_nAccessLevelML >= 7
                // l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-3" data-bs-toggle="modal" data-bs-target="#ConfirmImportModal">Import</button>]
            endif
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

        l_cHtml += [<div class="m-3">]
            l_cHtml += [<table>]

                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Export File</td>]
                    l_cHtml += [<td class="pb-3"><input type="file" name="TextExportFile" id="TextExportFile" value="" maxlength="200" size="80" style="width:800px"></td>]
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
function ModelImportStep1FormOnSubmit(par_iModelPk,par_cProjectLinkUID,par_cModelLinkUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_cErrorMessage := ""

local l_cInputFileName
local l_cFilePathPID
local l_iHandleUnzip
local l_xRes
local l_cImportContent

oFcgi:TraceAdd("ModelImportStep1FormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

do case
case vfp_inlist(l_cActionOnSubmit,"Import")

    l_cInputFileName := oFcgi:GetInputFileName("TextExportFile")
    if empty(l_cInputFileName)
        l_cErrorMessage := [Missing File.]
    else

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

            ImportModelFile(par_iModelPk,@l_cImportContent)

        endif

    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ModelImport/"+par_cModelLinkUID+"/")

endcase

if empty(l_cErrorMessage)
    //To force the tallies to be refreshed
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ModelImport/"+par_cModelLinkUID+"/")
else
    l_cHtml += ModelImportStep1FormBuild(par_iModelPk,l_cErrorMessage)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ImportModelFile(par_iModelPk,par_cImportContent)

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

local l_oDB_ModelInfo            := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oModelInfo

        
local l_hPackagePkOldToNew          := {=>}
local l_hPackageFkToSelf            := {=>}

local l_hPrimitiveTypePkOldToNew    := {=>}

local l_hDataTypePkOldToNew         := {=>}
local l_hDataTypeFkToSelf           := {=>}

local l_hModelEnumerationPkOldToNew := {=>}

local l_hEntityPkOldToNew           := {=>}

local l_hAssociationPkOldToNew      := {=>}

local l_hEndpointPkOldToNew         := {=>}

local l_hAttributePkOldToNew        := {=>}
local l_hAttributeFkToSelf          := {=>}
local l_hAttributeFkToEntity        := {=>}   //Will be used as a collection of objects

local l_hModelingDiagramPkOldToNew     := {=>}

local l_hCustomFieldPkOldToNew := {=>}
        
local l_iParentKeyCurrent  // In Current database
local l_iParentKeyImport   // In data used for import

local l_ifk_PrimitiveTypeImport
local l_ifk_PrimitiveTypeCurrent

local l_ifk_EntityImport
local l_ifk_EntityCurrent

local l_iSelfReference
local l_iPackagePk
local l_iDataTypePk
local l_iAttributePk
local l_iEntityPk

local l_ifk_PackageImport
local l_ifk_PackageCurrent

local l_ifk_ModelEnumerationImport
local l_ifk_ModelEnumerationCurrent

local l_ifk_DataTypeImport
local l_ifk_DataTypeCurrent

local l_ifk_AssociationImport
local l_ifk_AssociationCurrent

local l_ifk_EndpointImport
local l_ifk_EndpointCurrent

local l_ifk_CustomFieldImport
local l_ifk_CustomFieldCurrent

local l_cJSONVisPos

local l_hImportSourceCustomFieldUsedOn := {=>}
local lnUsedOn
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
            //ExportTableToHtmlFile("ImportSource"+l_cTableName,OUTPUT_FOLDER+hb_ps()+"PostgreSQL_ImportSource"+l_cTableName+".html","From PostgreSQL",,,.t.)
        endwith

    endif

enddo

with object l_oDB_ModelInfo
    :Table("44773d20-4c9d-4da5-8985-16271fb88507","Model")
    :Column("Model.fk_Project" , "Model_fk_Project")
    l_oModelInfo := :Get(par_iModelPk)
endwith

//-------------------------------------------------------------------------------------------------------------------------
// Import Packages
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000001","Package")
    :Where("Package.fk_Model = ^" , par_iModelPk)
    :Column("Package.Pk"        ,"pk")
    :Column("Package.FullName"  ,"FullName")
    :Column("Package.fk_Package","fk_Package")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(FullName,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith
        
select ImportSourcePackage
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Package")
scan all
    if vfp_seek( upper(strtran(ImportSourcePackage->FullName,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: Package Already on file",ListOfCurrentRecords->Name)
        l_hPackagePkOldToNew[ImportSourcePackage->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000002","Package")
            :Field("fk_Model",par_iModelPk)
            :Field("fk_Package"      ,-ImportSourcePackage->fk_Package)   // To Flag it should be rekeyed. Had to be deferred due to self-reference-pointer.
            ImportAddRecordSetField(l_oDBImport,"Package","*fk_Model*fk_Package*",l_aColumns)
            if :Add()
                l_hPackagePkOldToNew[ImportSourcePackage->pk] := :Key()
                if ImportSourcePackage->fk_Package > 0
                    l_hPackageFkToSelf[:Key()] := ImportSourcePackage->fk_Package
                endif
            endif
        endwith
    endif
endscan

//Fix the self reference keys (If > 0)
for each l_iSelfReference in l_hPackageFkToSelf //l_hPackagePkOldToNew
    l_iPackagePk        := l_iSelfReference:__enumkey
    l_iParentKeyImport  := l_iSelfReference
    l_iParentKeyCurrent := hb_HGetDef(l_hPackagePkOldToNew,l_iParentKeyImport,0)
    with object l_oDBImport
        :Table("c8459f40-9026-4718-b3d6-000000000003","Package")
        :Field("fk_Package",l_iParentKeyCurrent)
        :Update(l_iPackagePk)
    endwith
endfor

FixNonNormalizeFieldsInPackage(par_iModelPk)

//-------------------------------------------------------------------------------------------------------------------------
// Import PrimitiveType
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000003","DataType")
    :Distinct(.t.)
    :Where("DataType.fk_Model = ^" , par_iModelPk)
    :Join("inner","PrimitiveType","","DataType.fk_PrimitiveType = PrimitiveType.pk")
    :Column("PrimitiveType.Pk"   ,"pk")
    :Column("PrimitiveType.Name" ,"Name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourcePrimitiveType
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.PrimitiveType")
scan all
    if vfp_seek( upper(strtran(ImportSourcePrimitiveType->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        l_hPrimitiveTypePkOldToNew[ImportSourcePrimitiveType->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000005","PrimitiveType")
            :Field("fk_Project",l_oModelInfo:Model_fk_Project)
            ImportAddRecordSetField(l_oDBImport,"PrimitiveType","*fk_Model*",l_aColumns)
            if :Add()
                l_hPrimitiveTypePkOldToNew[ImportSourcePrimitiveType->pk] := :Key()
            endif
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import DataTypes
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000006","DataType")
    :Where("DataType.fk_Model = ^" , par_iModelPk)
    :Column("DataType.Pk"               ,"pk")
    :Column("DataType.FullName"         ,"FullName")     // Since it is a tree will use the denormalize FullName Field.
    :Column("DataType.fk_DataType"      ,"fk_DataType")
    :Column("DataType.fk_PrimitiveType" ,"fk_PrimitiveType")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(FullName,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceDataType
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.DataType")
scan all
    l_ifk_PrimitiveTypeImport := ImportSourceDataType->fk_PrimitiveType
    if hb_IsNil(l_ifk_PrimitiveTypeImport) .or. hb_IsNil(l_ifk_PrimitiveTypeImport)
        l_ifk_PrimitiveTypeCurrent := 0
    else
        l_ifk_PrimitiveTypeCurrent := hb_HGetDef(l_hPrimitiveTypePkOldToNew,l_ifk_PrimitiveTypeImport,0)
    endif

    if vfp_seek( upper(strtran(ImportSourceDataType->FullName,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: DataType Already on file",ListOfCurrentRecords->FullName)
        l_hDataTypePkOldToNew[ImportSourceDataType->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000007","DataType")
            :Field("fk_Model"         ,par_iModelPk)
            :Field("fk_PrimitiveType" ,l_ifk_PrimitiveTypeCurrent)
            :Field("fk_DataType"      ,-ImportSourceDataType->fk_DataType)   // To Flag it should be rekeyed. Had to be deferred due to self-reference-pointer.
            ImportAddRecordSetField(l_oDBImport,"DataType","*fk_Model*fk_DataType*fk_PrimitiveType*",l_aColumns)
            if :Add()
                l_hDataTypePkOldToNew[ImportSourceDataType->pk] := :Key()
                if ImportSourceDataType->fk_DataType > 0
                    // l_hDataTypePkOldToNew[:Key()] := ImportSourceDataType->fk_DataType
                    l_hDataTypeFkToSelf[:Key()] := ImportSourceDataType->fk_DataType
                    
                endif
            endif
        endwith
    endif
endscan

//Fix the self reference keys (If > 0)
for each l_iSelfReference in l_hDataTypeFkToSelf //l_hDataTypePkOldToNew
    l_iDataTypePk      := l_iSelfReference:__enumkey
    l_iParentKeyImport := l_iSelfReference
    l_iParentKeyCurrent := hb_HGetDef(l_hDataTypePkOldToNew,l_iParentKeyImport,0)
    with object l_oDBImport
        :Table("c8459f40-9026-4718-b3d6-000000000008","DataType")
        :Field("fk_DataType",l_iParentKeyCurrent)
        :Update(l_iDataTypePk)
    endwith
endfor

FixNonNormalizeFieldsInDataType(par_iModelPk)

//-------------------------------------------------------------------------------------------------------------------------
// Import ModelEnumerations
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000005","ModelEnumeration")
    :Where("ModelEnumeration.fk_Model = ^" , par_iModelPk)
    :Column("ModelEnumeration.Pk"  ,"pk")
    :Column("ModelEnumeration.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith
        
select ImportSourceModelEnumeration
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ModelEnumeration")
scan all
    if vfp_seek( upper(strtran(ImportSourceModelEnumeration->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: ModelEnumeration Already on file",ListOfCurrentRecords->Name)
        l_hModelEnumerationPkOldToNew[ImportSourceModelEnumeration->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000006","ModelEnumeration")
            :Field("fk_Model",par_iModelPk)
            ImportAddRecordSetField(l_oDBImport,"ModelEnumeration","*fk_Model*",l_aColumns)
            if :Add()
                l_hModelEnumerationPkOldToNew[ImportSourceModelEnumeration->pk] := :Key()
            endif
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Entities
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000007","Entity")
    :Where("Entity.fk_Model = ^" , par_iModelPk)
    :Column("Entity.Pk"        ,"pk")
    :Column("Entity.fk_Package","fk_Package")
    :Column("Entity.Name"      ,"Name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Package))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceEntity
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Entity")
scan all
    l_ifk_PackageImport := ImportSourceEntity->fk_Package
    if hb_IsNil(l_ifk_PackageImport) .or. hb_IsNil(l_ifk_PackageImport)
        l_ifk_PackageCurrent := 0
    else
        l_ifk_PackageCurrent := hb_HGetDef(l_hPackagePkOldToNew,l_ifk_PackageImport,0)
    endif

    if vfp_seek( alltrim(str(l_ifk_PackageCurrent))+'*'+upper(strtran(ImportSourceEntity->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: Entity Already on file",ListOfCurrentRecords->Name)
        l_hEntityPkOldToNew[ImportSourceEntity->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000008","Entity")
            :Field("fk_Model"   ,par_iModelPk)
            :Field("fk_Package" ,l_ifk_PackageCurrent)
            ImportAddRecordSetField(l_oDBImport,"Entity","*fk_Model*fk_package*",l_aColumns)
            if :Add()
                l_hEntityPkOldToNew[ImportSourceEntity->pk] := :Key()
            endif
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Associations
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000009","Association")
    :Where("Association.fk_Model = ^" , par_iModelPk)
    :Column("Association.Pk"        ,"pk")
    :Column("Association.fk_Package","fk_Package")
    :Column("Association.Name"      ,"Name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Package))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith
        
select ImportSourceAssociation
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Association")
scan all
    l_ifk_PackageImport := ImportSourceAssociation->fk_Package
    if hb_IsNil(l_ifk_PackageImport) .or. hb_IsNil(l_ifk_PackageImport)
        l_ifk_PackageCurrent := 0
    else
        l_ifk_PackageCurrent := hb_HGetDef(l_hPackagePkOldToNew,l_ifk_PackageImport,0)
    endif

    if vfp_seek( alltrim(str(l_ifk_PackageCurrent))+'*'+upper(strtran(ImportSourceAssociation->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: Association Already on file",ListOfCurrentRecords->Name)
        l_hAssociationPkOldToNew[ImportSourceAssociation->pk] := ListOfCurrentRecords->pk
    else
        with object l_oDBImport
            :Table("c8459f40-9026-4718-b3d6-000000000010","Association")
            :Field("fk_Model"   ,par_iModelPk)
            :Field("fk_Package" ,l_ifk_PackageCurrent)
            ImportAddRecordSetField(l_oDBImport,"Association","*fk_Model*fk_package",l_aColumns)
            if :Add()
                l_hAssociationPkOldToNew[ImportSourceAssociation->pk] := :Key()
            endif
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import ModelEnumValue
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000011","ModelEnumeration")
    :Where("ModelEnumeration.fk_Model = ^" , par_iModelPk)
    :Join("inner","ModelEnumValue"  ,"","ModelEnumValue.fk_ModelEnumeration = ModelEnumeration.pk")
    :Column("ModelEnumValue.fk_ModelEnumeration","fk_ModelEnumeration")
    :Column("ModelEnumValue.Pk"  ,"pk")
    :Column("ModelEnumValue.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_ModelEnumeration))+'*'+upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceModelEnumValue
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ModelEnumValue")
scan all
    l_iParentKeyImport  := ImportSourceModelEnumValue->fk_ModelEnumeration
    l_iParentKeyCurrent := hb_HGetDef(l_hModelEnumerationPkOldToNew,l_iParentKeyImport,0)

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find ModelEnumeration Parent Key on ModelEnumValue Import" ,l_iParentKeyImport)
    else
        if vfp_seek( alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceModelEnumValue->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: ModelEnumValue Already on file in ModelEnumeration (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
        else
            with object l_oDBImport
                :Table("c8459f40-9026-4718-b3d6-000000000012","ModelEnumValue")
                :Field("fk_ModelEnumeration" ,l_iParentKeyCurrent)
                ImportAddRecordSetField(l_oDBImport,"ModelEnumValue","*fk_ModelEnumeration*",l_aColumns)
                if :Add()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import Attributes
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000013","Entity")
    :Where("Entity.fk_Model = ^" , par_iModelPk)
    :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
    :Column("Attribute.fk_Entity"           ,"fk_Entity")
    :Column("Attribute.Pk"                  ,"pk")
    :Column("Attribute.FullName"            ,"FullName")
    :Column("Attribute.fk_Attribute"        ,"fk_Attribute")
    :Column("Attribute.fk_ModelEnumeration" ,"fk_ModelEnumeration")
    :Column("Attribute.fk_DataType"         ,"fk_DataType")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Entity))+'*'+upper(strtran(FullName,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith
        
select ImportSourceAttribute
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Attribute")
scan all
    l_iParentKeyImport  := ImportSourceAttribute->fk_Entity
    l_iParentKeyCurrent := hb_HGetDef(l_hEntityPkOldToNew,l_iParentKeyImport,0)

    l_ifk_ModelEnumerationImport  := ImportSourceAttribute->fk_ModelEnumeration
    l_ifk_ModelEnumerationCurrent := hb_HGetDef(l_hModelEnumerationPkOldToNew,l_ifk_ModelEnumerationImport,0)

    l_ifk_DataTypeImport  := ImportSourceAttribute->fk_DataType
    l_ifk_DataTypeCurrent := hb_HGetDef(l_hDataTypePkOldToNew,l_ifk_DataTypeImport,0)

    if empty(l_iParentKeyCurrent)
        // SendToDebugView("Failure to find Entity Parent Key on Attribute Import" ,l_iParentKeyImport)
    else
        if vfp_seek( alltrim(str(l_iParentKeyCurrent))+'*'+upper(strtran(ImportSourceAttribute->FullName,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Attribute Already on file",ListOfCurrentRecords->Name)
            l_hAttributePkOldToNew[ImportSourceAttribute->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("c8459f40-9026-4718-b3d6-000000000014","Attribute")
                :Field("fk_Entity"           ,l_iParentKeyCurrent)
                :Field("fk_Attribute"        ,-ImportSourceAttribute->fk_Attribute)   // To Flag it should be rekeyed. Had to be deferred due to self-reference-pointer.
                :Field("fk_ModelEnumeration" ,l_ifk_ModelEnumerationCurrent)
                :Field("fk_DataType"         ,l_ifk_DataTypeCurrent)
                ImportAddRecordSetField(l_oDBImport,"Attribute","*fk_Entity*fk_Attribute*fk_ModelEnumeration*fk_DataType*",l_aColumns)
                if :Add()
                    l_hAttributePkOldToNew[ImportSourceAttribute->pk] := :Key()
                    if ImportSourceAttribute->fk_Attribute > 0
                        l_hAttributeFkToSelf[:Key()] := ImportSourceAttribute->fk_Attribute
                    endif
                    l_hAttributeFkToEntity[l_iParentKeyCurrent] := 1   // fake value just used to be able to add an element to the hash array
                endif
            endwith
        endif
    endif
endscan

//Fix the self reference keys (If > 0)
for each l_iSelfReference in l_hAttributeFkToSelf
    l_iAttributePk      := l_iSelfReference:__enumkey
    l_iParentKeyImport  := l_iSelfReference
    l_iParentKeyCurrent := hb_HGetDef(l_hAttributePkOldToNew,l_iParentKeyImport,0)
    with object l_oDBImport
        :Table("c8459f40-9026-4718-b3d6-000000000015","Attribute")
        :Field("fk_Attribute",l_iParentKeyCurrent)
        :Update(l_iAttributePk)
    endwith
endfor

for each l_iEntityPk in l_hAttributeFkToEntity
    FixNonNormalizeFieldsInAttribute(l_iEntityPk:__enumkey)
endfor

//-------------------------------------------------------------------------------------------------------------------------
// Import Endpoint
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000016","Entity")
    :Where("Entity.fk_Model = ^" , par_iModelPk)
    :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
    :Distinct(.t.)
    :Column("Endpoint.pk"            ,"pk")
    :Column("Endpoint.fk_Entity"     ,"fk_Entity")
    :Column("Endpoint.fk_Association","fk_Association")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_Entity))+'*'+alltrim(str(fk_Association))+'*',40)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceEndpoint
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.Endpoint")
scan all
    l_iParentKeyImport  := ImportSourceEndpoint->fk_Entity
    l_iParentKeyCurrent := hb_HGetDef(l_hEntityPkOldToNew,l_iParentKeyImport,0)

    l_ifk_AssociationImport:= ImportSourceEndpoint->fk_Association
    if hb_IsNil(l_ifk_AssociationImport) .or. hb_IsNil(l_ifk_AssociationImport)
        l_ifk_AssociationCurrent := 0
    else
        l_ifk_AssociationCurrent := hb_HGetDef(l_hAssociationPkOldToNew,l_ifk_AssociationImport,0)
    endif

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find Entity Parent Key on Endpoint Import" ,l_iParentKeyImport)
    else
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_AssociationCurrent))+'*' ,"ListOfCurrentRecords","tag1")
            // SendToDebugView("Import: Endpoint Already on file in Entity (pk="+trans(l_iParentKeyCurrent)+")",ListOfCurrentRecords->Name)
            l_hEndpointPkOldToNew[ImportSourceEndpoint->pk] := ListOfCurrentRecords->pk
        else
            with object l_oDBImport
                :Table("c8459f40-9026-4718-b3d6-000000000017","Endpoint")
                :Field("fk_Entity"      ,l_iParentKeyCurrent)
                :Field("fk_Association" ,l_ifk_AssociationCurrent)
                ImportAddRecordSetField(l_oDBImport,"Endpoint","*fk_Entity*fk_Association*AspectOf*",l_aColumns)   //AspectOf was an old field
                if :Add()
                    l_hEndpointPkOldToNew[ImportSourceEndpoint->pk] := :Key()
                endif
            endwith
        endif
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import ModelingDiagrams
with object l_oDB_ListOfCurrentRecords
    :Table("c8459f40-9026-4718-b3d6-000000000018","ModelingDiagram")
    :Where("ModelingDiagram.fk_Model = ^" , par_iModelPk)
    :Column("ModelingDiagram.Pk"  ,"pk")
    :Column("ModelingDiagram.Name","name")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(upper(strtran(Name,' ',''))+'*',240)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceModelingDiagram
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ModelingDiagram")
scan all
    if vfp_seek( upper(strtran(ImportSourceModelingDiagram->Name,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
        // SendToDebugView("Import: ModelingDiagram Already on file",ListOfCurrentRecords->Name)
        l_hModelingDiagramPkOldToNew[ImportSourceModelingDiagram->pk] := ListOfCurrentRecords->pk
    else

        //Fix Graph JSON content
        l_cJSONVisPos := ImportSourceModelingDiagram->VisPos

        if !hb_IsNil(l_cJSONVisPos)
            //Loop on all possible source Entity, regardless if Entity is included or not in the ModelingDiagram. A little brute force, but works.
            for each l_ifk_EntityCurrent in l_hEntityPkOldToNew
                l_ifk_EntityImport := l_ifk_EntityCurrent:__enumkey
                l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022E"+trans(l_ifk_EntityImport)+"\u0022","\u0022E"+trans(l_ifk_EntityCurrent)+"\u0022")
            endfor

            //Loop on all possible source Association, regardless if Association is included or not in the ModelingDiagram. A little brute force, but works.
            for each l_ifk_AssociationCurrent in l_hAssociationPkOldToNew
                l_ifk_AssociationImport := l_ifk_AssociationCurrent:__enumkey
                l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022A"+trans(l_ifk_AssociationImport)+"\u0022","\u0022A"+trans(l_ifk_AssociationCurrent)+"\u0022")
                l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022D"+trans(l_ifk_AssociationImport)+"\u0022","\u0022D"+trans(l_ifk_AssociationCurrent)+"\u0022")
            endfor

            //Loop on all possible source Endpoint, regardless if Endpoint is included or not in the ModelingDiagram. A little brute force, but works.
            for each l_ifk_EndpointCurrent in l_hEndpointPkOldToNew
                l_ifk_EndpointImport := l_ifk_EndpointCurrent:__enumkey
                l_cJSONVisPos := strtran(l_cJSONVisPos,"\u0022L"+trans(l_ifk_EndpointImport)+"\u0022","\u0022L"+trans(l_ifk_EndpointCurrent)+"\u0022")
            endfor

        endif

        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000016","ModelingDiagram")
            :Field("ModelingDiagram.fk_Model" , par_iModelPk)
            if !hb_IsNil(l_cJSONVisPos)
                :FieldExpression("VisPos","E'"+l_cJSONVisPos+"'")
            endif
            ImportAddRecordSetField(l_oDBImport,"ModelingDiagram","*fk_Model*VisPos*",l_aColumns)
            if :Add()
                //Log the old key, new key
                l_hModelingDiagramPkOldToNew[ImportSourceModelingDiagram->pk] := :Key()
            endif
            
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import DiagramEntity
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000017","ModelingDiagram")
    :Where("ModelingDiagram.fk_Model = ^" , par_iModelPk)
    :Join("inner","DiagramEntity","","DiagramEntity.fk_ModelingDiagram = ModelingDiagram.pk")
    :Column("DiagramEntity.fk_ModelingDiagram" ,"fk_ModelingDiagram")
    :Column("DiagramEntity.Pk"                 ,"pk")
    :Column("DiagramEntity.Fk_Entity"          ,"Fk_Entity")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","padr(alltrim(str(fk_ModelingDiagram))+'*'+alltrim(str(Fk_Entity))+'*',40)")
        :CreateIndexes()
    endwith
endwith

select ImportSourceDiagramEntity
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ModelingDiagram")
scan all
    l_iParentKeyImport  := ImportSourceDiagramEntity->fk_ModelingDiagram
    l_iParentKeyCurrent := hb_HGetDef(l_hModelingDiagramPkOldToNew,l_iParentKeyImport,0)

    l_ifk_EntityImport:= ImportSourceDiagramEntity->fk_Entity
    if hb_IsNil(l_ifk_EntityImport) .or. hb_IsNil(l_ifk_EntityImport)
        l_ifk_EntityCurrent := 0
    else
        l_ifk_EntityCurrent := hb_HGetDef(l_hEntityPkOldToNew,l_ifk_EntityImport,0)
    endif

    if empty(l_iParentKeyCurrent)
        SendToDebugView("Failure to find ModelingDiagram Parent Key on DiagramEntity Import" ,l_iParentKeyImport)
    else
        if vfp_seek(alltrim(str(l_iParentKeyCurrent))+'*'+alltrim(str(l_ifk_EntityCurrent))+'*' ,"ListOfCurrentRecords","tag1")
        else
            with object l_oDBImport
                :Table("df873645-94d3-4ba5-85cf-000000000018","DiagramEntity")
                :Field("fk_ModelingDiagram",l_iParentKeyCurrent)
                :Field("fk_Entity"         ,l_ifk_EntityCurrent)
                ImportAddRecordSetField(l_oDBImport,"ModelingDiagram","*fk_ModelingDiagram*fk_Entity*",l_aColumns)   // No other field exists but leaving this in case we add some.
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
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.CustomField")
scan all
    l_hImportSourceCustomFieldUsedOn[ImportSourceCustomField->pk] := ImportSourceCustomField->UsedOn

    if vfp_seek( upper(strtran(ImportSourceCustomField->Code,' ',''))+'*' ,"ListOfCurrentRecords","tag1")
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
// Import ProjectCustomField
with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000026","ProjectCustomField")
    :Where("ProjectCustomField.fk_Project = ^" , l_oModelInfo:Model_fk_Project)
    :Column("ProjectCustomField.Pk"            ,"pk")
    :Column("ProjectCustomField.Fk_CustomField","Fk_CustomField")
    :SQL("ListOfCurrentRecords")
    with object :p_oCursor
        :Index("tag1","Fk_CustomField")
        :CreateIndexes()
    endwith
endwith

select ImportSourceProjectCustomField
l_aColumns := oFcgi:p_o_SQLConnection:GetColumnsConfiguration("public.ProjectCustomField")
scan all
    l_ifk_CustomFieldImport:= ImportSourceProjectCustomField->fk_CustomField
    if hb_IsNil(l_ifk_CustomFieldImport) .or. hb_IsNil(l_ifk_CustomFieldImport)
        l_ifk_CustomFieldCurrent := 0
    else
        l_ifk_CustomFieldCurrent := hb_HGetDef(l_hCustomFieldPkOldToNew,l_ifk_CustomFieldImport,0)
    endif

    if vfp_seek(l_ifk_CustomFieldCurrent ,"ListOfCurrentRecords","tag1")
        // Record already on file
    else
        with object l_oDBImport
            :Table("df873645-94d3-4ba5-85cf-000000000027","ProjectCustomField")
            :Field("fk_Project" ,l_oModelInfo:Model_fk_Project)
            :Field("fk_CustomField" ,l_ifk_CustomFieldCurrent)
            ImportAddRecordSetField(l_oDBImport,"ProjectCustomField","*fk_Project*fk_CustomField*",l_aColumns)   // No other field exists but leaving this in case we add some.
            if :Add()
            endif
        endwith
    endif
endscan

//-------------------------------------------------------------------------------------------------------------------------
// Import CustomFieldValues

with object l_oDB_ListOfCurrentRecords
    :Table("df873645-94d3-4ba5-85cf-000000000028","ProjectCustomField")
    :Where("ProjectCustomField.fk_Project = ^" , l_oModelInfo:Model_fk_Project)
    :Join("inner","CustomField"      ,"","ProjectCustomField.fk_CustomField = CustomField.pk")
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
        case lnUsedOn == USEDON_MODEL            // 5
            l_ifk_EntityCurrent := par_iModelPk
        case lnUsedOn == USEDON_ENTITY           // 6
            l_ifk_EntityCurrent := hb_HGetDef(l_hEntityPkOldToNew,l_ifk_EntityImport,0)
        case lnUsedOn == USEDON_ASSOCIATION      // 7
            l_ifk_EntityCurrent := hb_HGetDef(l_hAssociationPkOldToNew    ,l_ifk_EntityImport,0)
        case lnUsedOn == USEDON_PACKAGE         // 8
            l_ifk_EntityCurrent := hb_HGetDef(l_hPackagePkOldToNew   ,l_ifk_EntityImport,0)
        case lnUsedOn == USEDON_DATATYPE        // 9
            l_ifk_EntityCurrent := hb_HGetDef(l_hDataTypePkOldToNew   ,l_ifk_EntityImport,0)
        case lnUsedOn == USEDON_ATTRIBUTE       // 10
            l_ifk_EntityCurrent := hb_HGetDef(l_hAttributePkOldToNew   ,l_ifk_EntityImport,0)
        case lnUsedOn == USEDON_PROJECT         // 11
            l_ifk_EntityCurrent := l_oModelInfo:Model_fk_Project
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
                ImportAddRecordSetField(l_oDBImport,"CustomFieldValue","*fk_CustomField*fk_Entity*",l_aColumns)
                if :Add()
                endif
            endwith
        endif
    endif
endscan

return nil
//=================================================================================================================
