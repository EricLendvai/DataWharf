#include "DataWharf.ch"
//=================================================================================================================
function ExportForImports_GetFields(par_oDB_ListOfTables,par_hSchema,par_cTableName)
local l_aTableInfo
local l_aFields
local l_cFieldName

if hb_HHasKey(par_hSchema,"public."+par_cTableName)
    l_aTableInfo := par_hSchema["public."+par_cTableName]
    for each l_aFields in l_aTableInfo[1]
        l_cFieldName := l_aFields:__enumkey
        if !vfp_inlist(l_cFieldName,'sysc','sysm')
            par_oDB_ListOfTables:Column(par_cTableName+"."+l_cFieldName ,l_cFieldName)
        endif
    endfor
endif

return nil
//=================================================================================================================
function ExportForImports_Cursor(par_hSchema,par_cTableName,par_cCursornName)
local l_cBackupCode := ""
local l_cAdditionalCharactersToEscape := "|^"   // | is for NULL, ^ field separator
local l_aTableInfo
local l_aFields
local l_cFieldName
local l_cFieldType
local l_cFieldLen
local l_cFieldDec
local l_xValue

//Instead of using the table schema, will use the list of fields current version of the app is expecting.

if hb_HHasKey(par_hSchema,"public."+par_cTableName)
    l_cBackupCode := "!"+par_cTableName+CRLF
    l_aTableInfo := par_hSchema["public."+par_cTableName]
    for each l_aFields in l_aTableInfo[1]
        l_cFieldName := l_aFields:__enumkey
        if !vfp_inlist(l_cFieldName,'sysc','sysm')
            l_cFieldType  := l_aFields[HB_ORM_SCHEMA_FIELD_TYPE]
            l_cBackupCode += "|"
            l_cBackupCode += l_cFieldName + "|"
            l_cBackupCode += l_cFieldType + "|"
            l_cBackupCode += trans(nvl(l_aFields[HB_ORM_SCHEMA_FIELD_LENGTH],0)) + "|"
            l_cBackupCode += trans(nvl(l_aFields[HB_ORM_SCHEMA_FIELD_DECIMALS],0)) + "|"
            if len(l_aFields) >= HB_ORM_SCHEMA_FIELD_ATTRIBUTES
                l_cBackupCode += nvl(l_aFields[HB_ORM_SCHEMA_FIELD_ATTRIBUTES],"") + "|"
            endif
            if len(l_aFields) >= HB_ORM_SCHEMA_FIELD_DEFAULT
                l_cBackupCode += nvl(l_aFields[HB_ORM_SCHEMA_FIELD_DEFAULT],"") + "|"
            endif
            l_cBackupCode += CRLF
        endif
    endfor

    // l_cBackupCode += CRLF
    select (par_cCursornName)
    scan all
        l_cBackupCode += "^"

        for each l_aFields in l_aTableInfo[1]
            l_cFieldName := l_aFields:__enumkey
            if !vfp_inlist(l_cFieldName,'sysc','sysm')
                l_cFieldType := l_aFields[HB_ORM_SCHEMA_FIELD_TYPE]
                l_xValue     := hb_FieldGet(l_cFieldName)
                do case
                case hb_IsNil(l_xValue)
                    l_cBackupCode += "|"

                case l_cFieldType == "I"
                    l_cBackupCode += trans(l_xValue)

                case vfp_inlist(l_cFieldType,"C","CV","M")
                    if l_cFieldType == "C"
                        l_xValue := trim(l_xValue)
                    endif
                    if len(l_xValue) > 0
                        l_xValue := hb_orm_PostgresqlEncodeUTF8String(l_xValue,l_cAdditionalCharactersToEscape)
                        l_cBackupCode += substr(l_xValue,3,len(l_xValue)-3)
                    endif

               case vfp_inlist(l_cFieldType,"N")
                    l_cFieldLen := l_aFields[HB_ORM_SCHEMA_FIELD_LENGTH]
                    l_cFieldDec := l_aFields[HB_ORM_SCHEMA_FIELD_DECIMALS]
                    if empty(l_cFieldDec)
                        l_cBackupCode += trans(l_xValue)
                    else
                        l_cBackupCode += ltrim(str(l_xValue,l_cFieldLen,l_cFieldDec))
                    endif

                case l_cFieldType == "L"  // Not null by this point
                    l_cBackupCode += iif(l_xValue,"T","F")

                case l_cFieldType == "D"
                    l_cBackupCode += DToS(l_xValue)

                otherwise
                    l_cBackupCode += "???"

                endcase
                l_cBackupCode += "^"
            endif
        endfor
        l_cBackupCode += CRLF

    endscan
    l_cBackupCode += CRLF  // Extra blank line.
endif

return l_cBackupCode
//=================================================================================================================
function GetConfirmationModalFormsImport()
local cHtml

TEXT TO VAR cHtml

<div class="modal fade" id="ConfirmImportModal" tabindex="-1" aria-labelledby="ConfirmImportModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmImportModalLabel">Confirm Import</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        Any missing item will be added. Nothing will be deleted or updated!
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Import');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

return cHtml
//=================================================================================================================
function ImportAddRecordSetField(par_oDBImport,par_cTableName,par_cFieldsToExclude)
local l_aTableInfo
local l_aFields
local l_cFieldName
local l_nListOfImportData := select("ImportSource"+par_cTableName)
local l_xValue
local l_hSchema := oFcgi:p_o_SQLConnection:p_Schema

if hb_HHasKey(l_hSchema,"public."+par_cTableName)
    l_aTableInfo := l_hSchema["public."+par_cTableName]
    for each l_aFields in l_aTableInfo[1]
        l_cFieldName := l_aFields:__enumkey
        if !vfp_inlist(lower(l_cFieldName),'pk','sysc','sysm') .and. !("*"+lower(l_cFieldName)+"*" $ lower(par_cFieldsToExclude))
            if lower(l_cFieldName) == "linkuid" //Always generate a new uuid for these named fields
                par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,oFcgi:p_o_SQLConnection:GetUUIDString())
            else
                l_xValue := (l_nListOfImportData)->(hb_FieldGet(l_cFieldName))

                // do case
                // case hb_IsNil(l_xValue)
                //     par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,nil)
                // case vfp_inlist(l_aFields[2],"C","CV","M")
                //     par_oDBImport:FieldExpression(par_cTableName+"."+l_cFieldName ,"E'"+l_xValue+"'")  //Since value was already encoded.
                // case vfp_inlist(l_aFields[2],"D")
                //     par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,SToD(l_xValue))
                // case vfp_inlist(l_aFields[2],"L")
                //     par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,(l_xValue == "T"))
                // otherwise
                //     par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,l_xValue)
                // endcase

                if !hb_IsNil(l_xValue) .and. vfp_inlist(l_aFields[2],"C","CV","M")
                    par_oDBImport:FieldExpression(par_cTableName+"."+l_cFieldName ,"E'"+l_xValue+"'")  //Since value was already encoded.
                else
                    par_oDBImport:FieldValue(par_cTableName+"."+l_cFieldName ,l_xValue)
                endif

            endif
        endif
    endfor
endif

return nil
//=================================================================================================================
function DebugHashToFile(par_hHash,par_cFileName)  // Used to help debug

local l_cFolder
local l_cFileName
local l_cFileExtension
local l_cText
local l_cFullFileName

if pcount() == 2 .and. !hb_IsNil(par_hHash) .and. !hb_IsNil(par_cFileName) .and. !empty(par_hHash) .and. !empty(par_cFileName)
    hb_FNameSplit(par_cFileName,@l_cFolder,@l_cFileName,@l_cFileExtension)
    if empty(l_cFolder)
        l_cFolder := hb_cwd()
    endif
    if empty(l_cFileExtension)
        l_cFileExtension := ".txt"
    endif
    l_cFullFileName := l_cFolder+l_cFileName+l_cFileExtension
    l_cFullFileName := Strtran(Strtran(l_cFullFileName,[/],hb_ps()),[\],hb_ps())
    if hb_DirExists(l_cFolder)
        vfp_StrToFile(hb_jsonEncode(par_hHash,.t.,"UTF8EX"),l_cFullFileName)
    endif
endif

return nil
//=================================================================================================================
// VFP_StrToFile(:LastSQL(),"d:\LastSQL.txt")
