#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageCustomFields()
local l_cHtml := []
local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iCustomFieldPk
local l_cCustomFieldName
local l_iCustomFieldStatus
local l_cCustomFieldDescription

local l_hValues := {=>}

local l_aSQLResult := {}

local l_cURLAction              := "ListCustomFields"
local l_cURLCustomFieldCode := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("BuildPageCustomFields")

// Variables
// l_cURLAction
// l_cURLCustomFieldCode

//Improved and new way:
// CustomFields/                      Same as CustomFields/ListCustomFields/
// CustomFields/NewCustomField/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLCustomFieldCode := oFcgi:p_URLPathElements[3]
    endif

else
    l_cURLAction := "ListCustomFields"
endif

do case
case l_cURLAction == "ListCustomFields"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[CustomFields/">Custom Fields</a>]
            l_cHtml += [<a class="btn btn-primary rounded" ms-0 href="]+l_cSitePath+[CustomFields/NewCustomField">New Custom Field</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += CustomFieldListFormBuild()

case l_cURLAction == "NewCustomField"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage Custom Fields</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()
        //Brand new request of add an CustomField.
        l_cHtml += CustomFieldEditFormBuild(0,"",{=>})
    else
        l_cHtml += CustomFieldEditFormOnSubmit()
    endif


case l_cURLAction == "EditCustomField"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage Custom Fields</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()

        if !empty(l_cURLCustomFieldCode)

            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("78d95479-e974-4a19-9d9c-1cbaed66c34f","CustomField")
                :Column("CustomField.pk"               ,"pk")                            // 1
                :Column("CustomField.Code"             ,"CustomField_Code")              // 2
                :Column("CustomField.Name"             ,"CustomField_Name")              // 3
                :Column("CustomField.Label"            ,"CustomField_Label")             // 4
                :Column("CustomField.Type"             ,"CustomField_Type")              // 5
                :Column("CustomField.OptionDefinition" ,"CustomField_OptionDefinition")  // 6
                :Column("CustomField.Length"           ,"CustomField_Length")            // 7
                :Column("CustomField.Width"            ,"CustomField_Width")             // 8
                :Column("CustomField.Height"           ,"CustomField_Height")            // 9
                :Column("CustomField.UsedOn"           ,"CustomField_UsedOn")            // 10
                :Column("CustomField.Status"           ,"CustomField_Status")            // 11
                :Column("CustomField.Description"      ,"CustomField_Description")       // 12
                :Where("CustomField.Code = ^" ,l_cURLCustomFieldCode)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally == 1
                l_iCustomFieldPk := l_aSQLResult[1,1]

                l_hValues["Code"]             := l_aSQLResult[1, 2]
                l_hValues["Name"]             := l_aSQLResult[1, 3]
                l_hValues["Label"]            := l_aSQLResult[1, 4]
                l_hValues["Type"]             := l_aSQLResult[1, 5]
                l_hValues["OptionDefinition"] := l_aSQLResult[1, 6]
                l_hValues["Length"]           := l_aSQLResult[1, 7]
                l_hValues["Width"]            := l_aSQLResult[1, 8]
                l_hValues["Height"]           := l_aSQLResult[1, 9]
                l_hValues["UsedOn"]           := l_aSQLResult[1,10]
                l_hValues["Status"]           := l_aSQLResult[1,11]
                l_hValues["Description"]      := l_aSQLResult[1,12]

                with object l_oDB1
                    :Table("6a265223-a5ca-47c5-8469-5e0fc9282cfe","ApplicationCustomField")
                    :Column("ApplicationCustomField.fk_Application","fk_Application")
                    :Where("ApplicationCustomField.fk_CustomField = ^",l_iCustomFieldPk)
                    :SQL("ListOfSelectedApplications")

                    select ListOfSelectedApplications
                    scan all
                        l_hValues["Application"+Trans(ListOfSelectedApplications->fk_Application)] := .t.
                    endscan
                endwith

                l_cHtml += CustomFieldEditFormBuild(l_iCustomFieldPk,"",l_hValues)

            else
                l_cHtml += [<div>Failed to find Custom Field.</div>]
            endif
        endif

    else
        l_cHtml += CustomFieldEditFormOnSubmit()
    endif

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function CustomFieldListFormBuild()
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfCustomFields

oFcgi:TraceAdd("CustomFieldListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("e885ab89-0f99-46d3-a4ea-63c7559ec331","CustomField")
    :Column("CustomField.pk"         ,"pk")
    :Column("CustomField.Name"       ,"CustomField_Name")
    :Column("CustomField.Code"       ,"CustomField_Code")
    :Column("CustomField.Label"      ,"CustomField_Label")
    :Column("CustomField.Type"       ,"CustomField_Type")
    :Column("CustomField.UsedOn"     ,"CustomField_UsedOn")
    :Column("CustomField.Description","CustomField_Description")
    :Column("CustomField.Status"     ,"CustomField_Status")
    :Column("Upper(CustomField.Name)","tag1")
    :OrderBy("CustomField_UsedOn")
    :OrderBy("tag1")
    :SQL("ListOfCustomFields")
    l_nNumberOfCustomFields := :Tally
endwith

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfCustomFields)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Custom Field on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="7">Custom Fields (]+Trans(l_nNumberOfCustomFields)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Code</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Label</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Used On</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Status</th>]
                l_cHtml += [</tr>]

                select ListOfCustomFields
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[CustomFields/EditCustomField/]+AllTrim(ListOfCustomFields->CustomField_Code)+[/">]+Allt(ListOfCustomFields->CustomField_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfCustomFields->CustomField_Code)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfCustomFields->CustomField_Label)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Logical","Multi Choice","String","Text Area","Date"}[iif(vfp_between(ListOfCustomFields->CustomField_Type,1,5),ListOfCustomFields->CustomField_Type,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Application","Name Space","Table","Column"}[iif(vfp_between(ListOfCustomFields->CustomField_UsedOn,1,4),ListOfCustomFields->CustomField_UsedOn,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfCustomFields->CustomField_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Active","Inactive","Hidden"}[iif(vfp_between(ListOfCustomFields->CustomField_Status,1,3),ListOfCustomFields->CustomField_Status,1)]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function CustomFieldEditFormBuild(par_iPk,par_cErrorText,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_iType
local l_iLength
local l_iWidth
local l_iHeight
local l_iUsedOn
local l_iStatus
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_CheckBoxId

oFcgi:TraceAdd("CustomFieldEditFormBuild")

oFcgi:p_cjQueryScript += [$('#TextName').focus();]
// oFcgi:p_cjQueryScript += [$('#TextOptionDefinition').resizable();]    // Since the object can be hidden, due to a bug in jQuery UI resize, will only rely on browsers built in resizing.
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangeType(par_Value) {]

l_cHtml += [switch(par_Value) {]
    l_cHtml += [  case '1':]  // Logical
    l_cHtml += [  $('#SpanOptionDefinition').hide();]
    l_cHtml += [$('#SpanLength').hide();]
    l_cHtml += [$('#SpanWidth').hide();]
    l_cHtml += [$('#SpanHeight').hide();]
    l_cHtml += [    break;]
    l_cHtml += [  case '2':]  // Multi Choice
    l_cHtml += [  $('#SpanOptionDefinition').show();]
    l_cHtml += [$('#SpanLength').hide();]
    l_cHtml += [$('#SpanWidth').hide();]
    l_cHtml += [$('#SpanHeight').hide();]
    l_cHtml += [    break;]
    l_cHtml += [  case '3':]  // String
    l_cHtml += [  $('#SpanOptionDefinition').hide();]
    l_cHtml += [$('#SpanLength').show();]
    l_cHtml += [$('#SpanWidth').hide();]
    l_cHtml += [$('#SpanHeight').hide();]
    l_cHtml += [    break;]
    l_cHtml += [  case '4':]  // Text Area
    l_cHtml += [  $('#SpanOptionDefinition').hide();]
    l_cHtml += [$('#SpanLength').hide();]
    l_cHtml += [$('#SpanWidth').show();]
    l_cHtml += [$('#SpanHeight').show();]
    l_cHtml += [    break;]
l_cHtml += [  default:]
    l_cHtml += [  $('#SpanOptionDefinition').hide();]
    l_cHtml += [$('#SpanLength').hide();]
    l_cHtml += [$('#SpanWidth').hide();]
    l_cHtml += [$('#SpanHeight').hide();]
l_cHtml += [};]

l_cHtml += [};]
l_cHtml += [</script>] 
oFcgi:p_cjQueryScript += [OnChangeType($("#ComboType").val());]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New Custom Field</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update Custom Field</span>]   //navbar-text
        endif
        l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Name",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Link Code</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextCode" id="TextCode" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Code",""))+[" maxlength="10" size="10" style="text-transform: uppercase;"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Label</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLabel" id="TextLabel" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Label",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Type</td>]
            l_cHtml += [<td class="pb-3" valign="top" style="vertical-align: top; ">]

                l_cHtml += [<span class="pe-5">]
                    l_iType := hb_HGetDef(par_hValues,"Type",1)
                    // l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboType" id="ComboType">]
                    l_cHtml += [<select name="ComboType" id="ComboType" onchange="OnChangeType(this.value);$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');">]
                        l_cHtml += [<option value="1"]+iif(l_iType==1,[ selected],[])+[>Logical</option>]
                        l_cHtml += [<option value="2"]+iif(l_iType==2,[ selected],[])+[>Multi Choice</option>]
                        l_cHtml += [<option value="3"]+iif(l_iType==3,[ selected],[])+[>String</option>]
                        l_cHtml += [<option value="4"]+iif(l_iType==4,[ selected],[])+[>Text Area</option>]
                        l_cHtml += [<option value="5"]+iif(l_iType==5,[ selected],[])+[>Date</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanOptionDefinition" style="display: none;">]
                    l_cHtml += [<br><span class="pe-2 mt-2 mb-2">Enter one option value per line  &lt;number&gt; : &lt;Label&gt;</span><br><textarea]+UPDATESAVEBUTTON+[ name="TextOptionDefinition" id="TextOptionDefinition" rows="4" cols="80">]+FcgiPrepFieldForValue(nvl(hb_HGetDef(par_hValues,"OptionDefinition",NIL),""))+[</textarea>]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanLength" style="display: none;">]
                    l_cHtml += [<span class="pe-2">Length</span><input]+UPDATESAVEBUTTON+[ type="text" name="TextLength" id="TextLength" value="]+Trans(nvl(hb_HGetDef(par_hValues,"Length",""),""))+[" size="5" maxlength="5">]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanWidth" style="display: none;">]
                    l_cHtml += [<span class="pe-2">Width</span><input]+UPDATESAVEBUTTON+[ type="text" name="TextWidth" id="TextWidth" value="]+Trans(nvl(hb_HGetDef(par_hValues,"Width",""),""))+[" size="5" maxlength="5">]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanHeight" style="display: none;" >]
                    l_cHtml += [<span class="pe-2">Height</span><input]+UPDATESAVEBUTTON+[ type="text" name="TextHeight" id="TextHeight" value="]+Trans(nvl(hb_HGetDef(par_hValues,"Height",""),""))+[" size="5" maxlength="5">]
                l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Used On</td>]
            l_cHtml += [<td class="pb-3">]
                l_iUsedOn := hb_HGetDef(par_hValues,"UsedOn",1)
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUsedOn" id="ComboUsedOn">]
                    l_cHtml += [<option value="1"]+iif(l_iUsedOn==1,[ selected],[])+[>Application</option>]
                    l_cHtml += [<option value="2"]+iif(l_iUsedOn==2,[ selected],[])+[>Name Space</option>]
                    l_cHtml += [<option value="3"]+iif(l_iUsedOn==3,[ selected],[])+[>Table</option>]
                    l_cHtml += [<option value="4"]+iif(l_iUsedOn==4,[ selected],[])+[>Column</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_iStatus := hb_HGetDef(par_hValues,"Status",1)
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboStatus" id="ComboStatus">]
                    l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Inactive (Read Only)</option>]
                    l_cHtml += [<option value="3"]+iif(l_iStatus==3,[ selected],[])+[>Hidden</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(nvl(hb_HGetDef(par_hValues,"Description",NIL),""))+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

with Object l_oDB1
    :Table("f0da419f-03ed-4b93-b3e2-b33261d3d52e","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAllApplications")

    if :Tally > 0
        l_cHtml += [<div>]
            l_cHtml += [<span class="ms-3">Filter on Application Name</span><input type="text" id="ApplicationSearch" value="" size="40" class="ms-2"><span class="ms-3"> (Press Enter)</span>]
        l_cHtml += [</div>]

        l_cHtml += [<div class="m-3"></div>]

    endif
endwith

//Add a case insensitive contains(), icontains()
oFcgi:p_cjQueryScript += "jQuery.expr[':'].icontains = function(a, i, m) {"
oFcgi:p_cjQueryScript += "  return jQuery(a).text().toUpperCase()"
oFcgi:p_cjQueryScript += "      .indexOf(m[3].toUpperCase()) >= 0;"
oFcgi:p_cjQueryScript += "};"

oFcgi:p_cjQueryScript += [$("#ApplicationSearch").change(function() {]
oFcgi:p_cjQueryScript += [$(".SPANTable:icontains('" + $(this).val() + "')").parent().parent().show();]
oFcgi:p_cjQueryScript += [$(".SPANTable:not(:icontains('" + $(this).val() + "'))").parent().parent().hide();]
oFcgi:p_cjQueryScript += [});]

l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [<table class="ms-5">]
select ListOfAllApplications
scan all
    l_CheckBoxId := "CheckApplication"+Trans(ListOfAllApplications->pk)
    l_cHtml += [<tr><td>]
        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif( hb_HGetDef(par_hValues,"Application"+Trans(ListOfAllApplications->pk),.f.)," checked","")+[ class="form-check-input">]
        l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+["><span class="SPANTable">]+ListOfAllApplications->Application_Name+[</span></label>]
    l_cHtml += [</td></tr>]
endscan
l_cHtml += [</table>]
l_cHtml += [</div>]


l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function CustomFieldEditFormOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit

local l_iCustomFieldPk
local l_cCustomFieldName
local l_cCustomFieldCode
local l_cCustomFieldLabel
local l_iCustomFieldType

local l_cCustomFieldOptionDefinition
local l_cCustomFieldLength
local l_iCustomFieldLength
local l_cCustomFieldWidth
local l_iCustomFieldWidth
local l_cCustomFieldHeight
local l_iCustomFieldHeight

local l_iCustomFieldUsedOn
local l_iCustomFieldStatus
local l_cCustomFieldDescription

local l_hValues := {=>}

local l_cOptionDefinitionEntered
local l_nLineNumber
local l_cLine
local l_nPos
local l_cOptionVal
local l_nOptionVal
local l_cOptionText

local l_lSelected

local l_cErrorMessage := ""
local l_oDB1
local l_oDB2
local l_oDB3

oFcgi:TraceAdd("CustomFieldEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iCustomFieldPk               := Val(oFcgi:GetInputValue("TableKey"))
l_cCustomFieldName             := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cCustomFieldCode             := Upper(Strtran(SanitizeInput(oFcgi:GetInputValue("TextCode"))," ",""))
l_cCustomFieldLabel            := SanitizeInput(oFcgi:GetInputValue("TextLabel"))
l_iCustomFieldType             := Val(oFcgi:GetInputValue("ComboType"))
l_cCustomFieldOptionDefinition := SanitizeInput(oFcgi:GetInputValue("TextOptionDefinition"))
l_cCustomFieldLength           := SanitizeInput(oFcgi:GetInputValue("TextLength"))
l_iCustomFieldLength           := iif(empty(l_cCustomFieldLength),NULL,val(l_cCustomFieldLength))
l_cCustomFieldWidth            := SanitizeInput(oFcgi:GetInputValue("TextWidth"))
l_iCustomFieldWidth            := iif(empty(l_cCustomFieldWidth),NULL,val(l_cCustomFieldWidth))
l_cCustomFieldHeight           := SanitizeInput(oFcgi:GetInputValue("TextHeight"))
l_iCustomFieldHeight           := iif(empty(l_cCustomFieldHeight),NULL,val(l_cCustomFieldHeight))
l_iCustomFieldUsedOn           := Val(oFcgi:GetInputValue("ComboUsedOn"))
l_iCustomFieldStatus           := Val(oFcgi:GetInputValue("ComboStatus"))
l_cCustomFieldDescription      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"

    do case
    case empty(l_cCustomFieldName)
        l_cErrorMessage := "Missing Name"
    case empty(l_cCustomFieldCode)
        l_cErrorMessage := "Missing Code"
    case empty(l_cCustomFieldLabel)
        l_cErrorMessage := "Missing Label"
    case l_iCustomFieldType == 2 .and. empty(l_cCustomFieldOptionDefinition)
        l_cErrorMessage := "Missing Option Definition"
    case l_iCustomFieldType == 3 .and. nvl(l_iCustomFieldLength,0) <= 0
        l_cErrorMessage := "Missing Length"
    case l_iCustomFieldType == 4 .and. nvl(l_iCustomFieldWidth,0) <= 0
        l_cErrorMessage := "Missing Width"
    case l_iCustomFieldType == 4 .and. nvl(l_iCustomFieldHeight,0) <= 0
        l_cErrorMessage := "Missing Height"
    otherwise

        do case
        case l_iCustomFieldType == 1 // Logical
            l_cCustomFieldOptionDefinition := NIL
            l_iCustomFieldLength           := NIL
            l_iCustomFieldWidth            := NIL
            l_iCustomFieldHeight           := NIL

        case l_iCustomFieldType == 2 // Multi Choice
            l_iCustomFieldLength           := NIL
            l_iCustomFieldWidth            := NIL
            l_iCustomFieldHeight           := NIL

            l_cOptionDefinitionEntered := l_cCustomFieldOptionDefinition
            l_cCustomFieldOptionDefinition := ""
            //Reformat as needed.
            for l_nLineNumber := 1 to MLCount(l_cOptionDefinitionEntered,1024)
                l_cLine := MemoLine(l_cOptionDefinitionEntered,1024,l_nLineNumber)
                if !empty(l_cLine)
                    l_nPos := at(":",l_cLine)
                    if !empty(l_nPos)
                        l_cOptionVal  := Alltrim(left(l_cLine,l_nPos-1))
                        l_nOptionVal  := Val(l_cOptionVal)
                        l_cOptionText := Alltrim(Substr(l_cLine,l_nPos+1))
                        if Trans(l_nOptionVal) == l_cOptionVal .and. !empty(l_cOptionText)
                            if !empty(l_cCustomFieldOptionDefinition)
                                l_cCustomFieldOptionDefinition += CRLF
                            endif
                            l_cCustomFieldOptionDefinition += Trans(l_nOptionVal)+" : "+l_cOptionText
                        endif
                    endif
                endif
            endfor
            
        case l_iCustomFieldType == 3 // String
            l_cCustomFieldOptionDefinition := NIL
            l_iCustomFieldWidth            := NIL
            l_iCustomFieldHeight           := NIL

        case l_iCustomFieldType == 4 // Text Area
            l_iCustomFieldLength           := NIL

        case l_iCustomFieldType == 5 // Date
            l_cCustomFieldOptionDefinition := NIL
            l_iCustomFieldLength           := NIL
            l_iCustomFieldWidth            := NIL
            l_iCustomFieldHeight           := NIL
                
        endcase

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("e2b12b57-cc1a-4c5b-888b-89ad920d60be","CustomField")
            :Where([lower(replace(CustomField.Name,' ','')) = ^],lower(StrTran(l_cCustomFieldName," ","")))
            if l_iCustomFieldPk > 0
                :Where([CustomField.pk != ^],l_iCustomFieldPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("619fe53c-2abc-48c2-9e09-4e3ac04e668d","CustomField")
                :Where([upper(replace(CustomField.Code,' ','')) = ^],l_cCustomFieldCode)
                if l_iCustomFieldPk > 0
                    :Where([CustomField.pk != ^],l_iCustomFieldPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Code"
            else
                //Save the CustomField
                with object l_oDB1
                    :Table("bd91c388-04e1-445c-a257-dad456888b75","CustomField")
                    :Field("CustomField.Name"            , l_cCustomFieldName)
                    :Field("CustomField.Code"            , l_cCustomFieldCode)
                    :Field("CustomField.Label"           , l_cCustomFieldLabel)
                    :Field("CustomField.Type"            , l_iCustomFieldType)
                    :Field("CustomField.OptionDefinition", l_cCustomFieldOptionDefinition)
                    :Field("CustomField.Length"          , l_iCustomFieldLength)
                    :Field("CustomField.Width"           , l_iCustomFieldWidth)
                    :Field("CustomField.Height"          , l_iCustomFieldHeight)
                    :Field("CustomField.UsedOn"          , l_iCustomFieldUsedOn)
                    :Field("CustomField.Status"          , l_iCustomFieldStatus)
                    :Field("CustomField.Description"     , iif(empty(l_cCustomFieldDescription),NULL,l_cCustomFieldDescription))
                    if empty(l_iCustomFieldPk)
                        if :Add()
                            l_iCustomFieldPk := :Key()
                        else
                            l_cErrorMessage := "Failed to add CustomField."
                        endif
                    else
                        if !:Update(l_iCustomFieldPk)
                            l_cErrorMessage := "Failed to update CustomField."
                        endif
                    endif

                    if empty(l_cErrorMessage)
                        //Update the list selected Applications
                        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
                        l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)

                        with Object l_oDB2
                            :Table("bd385c1d-35d9-4b1a-9f19-114adad22b51","Application")
                            :Column("Application.pk"         ,"pk")
                            :SQL("ListOfApplications")
                        endwith

                        //Get current list of CustomField Applications
                        with Object l_oDB1
                            :Table("4c5d6934-6291-44ff-b515-9cca05d1441e","ApplicationCustomField")
                            :Distinct(.t.)
                            :Column("Application.pk","pk")
                            :Column("ApplicationCustomField.pk","ApplicationCustomField_pk")
                            :Join("inner","Application","","ApplicationCustomField.fk_Application = Application.pk")
                            :Where("ApplicationCustomField.fk_CustomField = ^" , l_iCustomFieldPk)
                            :SQL("ListOfCurrentApplicationForCustomField")
                            With Object :p_oCursor
                                :Index("pk","pk")
                                :CreateIndexes()
                                :SetOrder("pk")
                            endwith        
                        endwith

                        select ListOfApplications
                        scan all
                            l_lSelected := (oFcgi:GetInputValue("CheckApplication"+Trans(ListOfApplications->pk)) == "1")

                            if VFP_Seek(ListOfApplications->pk,"ListOfCurrentApplicationForCustomField","pk")
                                if !l_lSelected
                                    // Remove the Application
                                    with Object l_oDB3
                                        if !:Delete("37ca7d0d-be50-4b44-9182-51ffca0156c9","ApplicationCustomField",ListOfCurrentApplicationForCustomField->ApplicationCustomField_pk)
                                            l_cErrorMessage := "Failed to Save Application selection."
                                            exit
                                        endif
                                    endwith
                                endif
                            else
                                if l_lSelected
                                    // Add the Application
                                    with Object l_oDB3
                                        :Table("dfa86e89-3f27-4f83-9089-ff2bba6f8321","ApplicationCustomField")
                                        :Field("ApplicationCustomField.fk_Application",ListOfApplications->pk)
                                        :Field("ApplicationCustomField.fk_CustomField",l_iCustomFieldPk)
                                        if !:Add()
                                            l_cErrorMessage := "Failed to Save Application selection."
                                            exit
                                        endif
                                    endwith
                                endif
                            endif
                        endscan
                    endif

                    if empty(l_cErrorMessage)
                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"CustomFields/ListCustomFields/")
                    endif
                endwith
            endif
        endif
    endcase

case l_cActionOnSubmit == "Cancel"
    if empty(l_iCustomFieldPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"CustomFields")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"CustomFields/ListCustomFields/")  // +par_cURLCustomFieldCode+"/"
    endif

case l_cActionOnSubmit == "Delete"   // CustomField
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB1
        :Table("4b3623ff-d0a6-49aa-b304-d8fa7c3b4900","ApplicationCustomField")
        :Where("ApplicationCustomField.fk_CustomField = ^",l_iCustomFieldPk)
        :SQL()
        if :Tally == 0

            :Table("bc249be0-9f7d-40e0-a10a-91f441b05a8c","CustomFieldValue")
            :Where("CustomFieldValue.fk_CustomField = ^",l_iCustomFieldPk)
            :SQL()
            if :Tally == 0
                :Delete("7245a056-83cb-4b8e-aed7-0b3cfa3cb458","CustomField",l_iCustomFieldPk)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"CustomFields/")
            else
                l_cErrorMessage := "Related CustomFieldValue record on file"
            endif
        else
            l_cErrorMessage := "Related ApplicationCustomField record on file"
        endif
    endwith

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]             := l_cCustomFieldName
    l_hValues["Code"]             := l_cCustomFieldCode
    l_hValues["Label"]            := l_cCustomFieldLabel
    l_hValues["Type"]             := l_iCustomFieldType
    l_hValues["OptionDefinition"] := l_cCustomFieldOptionDefinition
    l_hValues["Length"]           := l_iCustomFieldLength
    l_hValues["Width"]            := l_iCustomFieldWidth
    l_hValues["Height"]           := l_iCustomFieldHeight
    l_hValues["UsedOn"]           := l_iCustomFieldUsedOn
    l_hValues["Status"]           := l_iCustomFieldStatus
    l_hValues["Description"]      := l_cCustomFieldDescription

    if !used("ListOfApplications")
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with Object l_oDB2
            :Table("ca27b8d5-605a-4f51-8e60-6eb4470cb94f","Application")
            :Column("Application.pk" ,"pk")
            :SQL("ListOfApplications")
        endwith
    endif

    select ListOfApplications
    scan all
        l_lSelected := (oFcgi:GetInputValue("CheckApplication"+Trans(ListOfApplications->pk)) == "1")
        if l_lSelected  // No need to store the unselect references, since not having a reference will mean "not selected"
            l_hValues["Application"+Trans(ListOfApplications->pk)] := .t.
        endif
    endscan

    l_cHtml += CustomFieldEditFormBuild(l_iCustomFieldPk,l_cErrorMessage,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CustomFieldsLoad(par_iApplicationPk,par_UsedOn,par_iPk,par_hValues)  // Will add to par_hValues
local l_select := iif(used(),select(),0)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cObjectName
local l_lSelected
local l_xValue 

with object l_oDB1
    :Table("9193f840-e45a-448e-8bef-4a5abf94ef57","ApplicationCustomField")
    :Column("CustomField.pk" , "pk")
    :Column("CustomField.Type"            ,"CustomField_Type")
    :Column("CustomFieldValue.pk"         ,"CustomFieldValue_pk")
    :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
    :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
    :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :join("left","CustomFieldValue","","CustomFieldValue.fk_CustomField = CustomField.pk and CustomFieldValue.fk_Entity = ^" , par_iPk)
    :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
    :Where("CustomField.UsedOn = ^" , par_UsedOn)
    :Where("CustomField.Status <= 2")
    :SQL("ListOfCustomFieldsToLoadValues")
// SendToClipboard(:LastSQL())
    if :Tally > 0
        select ListOfCustomFieldsToLoadValues
        scan all
            l_cObjectName := "CustomField"+Trans(ListOfCustomFieldsToLoadValues->pk)

            switch ListOfCustomFieldsToLoadValues->CustomField_Type
            case 1  // Logical
                l_lSelected := !hb_orm_IsNull("ListOfCustomFieldsToLoadValues","CustomFieldValue_pk")
                if l_lSelected
                    par_hValues[l_cObjectName] := .t.
                endif
                exit

            case 2  // Multi Choice
                if !hb_orm_IsNull("ListOfCustomFieldsToLoadValues","CustomFieldValue_ValueI")
                    par_hValues[l_cObjectName] := ListOfCustomFieldsToLoadValues->CustomFieldValue_ValueI
                endif
                exit
                
            case 3  // String
            case 4  // Text Area
                if !hb_orm_IsNull("ListOfCustomFieldsToLoadValues","CustomFieldValue_ValueM")
                    par_hValues[l_cObjectName] := ListOfCustomFieldsToLoadValues->CustomFieldValue_ValueM
                endif
                exit
                
            case 5  // Date
                if !hb_orm_IsNull("ListOfCustomFieldsToLoadValues","CustomFieldValue_ValueD")
                    par_hValues[l_cObjectName] := ListOfCustomFieldsToLoadValues->CustomFieldValue_ValueD
                endif
                exit

            endswitch

        endscan
    endif

endwith

select (l_select)
return Nil
//=================================================================================================================
function CustomFieldsFormToHash(par_iApplicationPk,par_UsedOn,par_hValues)  // Will add to par_hValues

local l_select := iif(used(),select(),0)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cObjectName
local l_lSelected

with object l_oDB1
    :Table("fd49bb5b-f1b1-4a02-b19d-77d00a5cf52c","ApplicationCustomField")
    :Column("CustomField.pk" , "pk")
    :Column("CustomField.Type"            ,"CustomField_Type")
    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
    :Where("CustomField.UsedOn = ^" , par_UsedOn)
    :Where("CustomField.Status <= 2")
    :SQL("ListOfCustomFieldsFormToHash")
// SendToClipboard(:LastSQL())
    if :Tally > 0
        select ListOfCustomFieldsFormToHash
        scan all
            l_cObjectName := "CustomField"+Trans(ListOfCustomFieldsFormToHash->pk)

            switch ListOfCustomFieldsFormToHash->CustomField_Type
            case 1  // Logical
                l_lSelected := (oFcgi:GetInputValue("Check"+l_cObjectName) == "1")
                if l_lSelected
                    par_hValues[l_cObjectName] := .t.
                endif
                exit

            case 2  // Multi Choice
                par_hValues[l_cObjectName] := val(oFcgi:GetInputValue("Combo"+l_cObjectName))
                exit
                
            case 3  // String
            case 4  // Text Area
                par_hValues[l_cObjectName] := SanitizeInput(oFcgi:GetInputValue("Text"+l_cObjectName))
                exit
            case 5  // Date
                par_hValues[l_cObjectName] := ctod(SanitizeInput(oFcgi:GetInputValue("Text"+l_cObjectName)))
                exit

            endswitch

        endscan
    endif

endwith

select (l_select)
return Nil
//=================================================================================================================
function CustomFieldsBuild(par_iApplicationPk,par_UsedOn,par_iPk,par_hValues,par_extra_property)
local l_select := iif(used(),select(),0)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cHtml := []
local l_lSelected
local l_cObjectName
local l_nLength
local l_nWidth
local l_nHeight
local l_cOptionDefinition
local l_nOption
local l_nLineNumber
local l_cLine
local l_nPos
local l_cOptionVal
local l_nOptionVal
local l_cOptionText
local l_xValue

with object l_oDB1
    :Table("800b078f-1b00-48bb-97bb-ffd9deb1b6ab","ApplicationCustomField")
    :Column("CustomField.pk" , "pk")
    :Column("CustomField.Label"           ,"CustomField_Label")
    :Column("CustomField.Type"            ,"CustomField_Type")
    :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
    :Column("CustomField.Length"          ,"CustomField_Length")
    :Column("CustomField.Width"           ,"CustomField_Width")
    :Column("CustomField.Height"          ,"CustomField_Height")
    :Column("CustomField.Status"          ,"CustomField_Status")
    :Column("upper(CustomField.Name)"     ,"tag1")                                   //_M_ use ApplicationCustomField.order later on
    // :Column("CustomFieldValue.pk"         ,"CustomFieldValue_pk")
    // :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
    // :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
    // :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    // :join("left","CustomFieldValue","","CustomFieldValue.fk_CustomField = CustomField.pk and CustomFieldValue.fk_Entity = ^" , par_iPk)
    :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
    :Where("CustomField.UsedOn = ^" , par_UsedOn)
    :Where("CustomField.Status <= 2")
    :OrderBy("tag1")
    :SQL("ListOfCustomFieldsToBuild")

    if :Tally > 0
        select ListOfCustomFieldsToBuild
        scan all
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3" valign="top">]+ListOfCustomFieldsToBuild->CustomField_Label+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cObjectName := "CustomField"+Trans(ListOfCustomFieldsToBuild->pk)

                    do case
                    case ListOfCustomFieldsToBuild->CustomField_Type == 1  // Logical
                        l_cHtml += [<div class="form-check form-switch">]
                            l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="Check]+l_cObjectName+[" id="Check]+l_cObjectName+[" value="1"]+iif(hb_HGetDef(par_hValues,l_cObjectName,.f.)," checked","")+[ class="form-check-input" ]+par_extra_property+[>]
                        l_cHtml += [</div>]

                    case ListOfCustomFieldsToBuild->CustomField_Type == 2  // Multi Choice
                        //_M_
                        l_cOptionDefinition := ListOfCustomFieldsToBuild->CustomField_OptionDefinition
                        l_nOption           := hb_HGetDef(par_hValues,l_cObjectName,0)

                        l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="Combo]+l_cObjectName+[" id="Combo]+l_cObjectName+[" ]+par_extra_property+[>]
                        l_cHtml += [<option value="0"]+iif(l_nOption==0,[ selected],[])+[></option>]
                        for l_nLineNumber := 1 to MLCount(l_cOptionDefinition,1024)
                            l_cLine := MemoLine(l_cOptionDefinition,1024,l_nLineNumber)
                            if !empty(l_cLine)
                                l_nPos := at(":",l_cLine)
                                if !empty(l_nPos)
                                    l_cOptionVal  := Alltrim(left(l_cLine,l_nPos-1))
                                    l_nOptionVal  := Val(l_cOptionVal)
                                    l_cOptionText := Alltrim(Substr(l_cLine,l_nPos+1))
                                    if Trans(l_nOptionVal) == l_cOptionVal .and. !empty(l_cOptionText)
                                        l_cHtml += [<option value="]+l_cOptionVal+["]+iif(l_nOption==l_nOptionVal,[ selected],[])+[>]+l_cOptionText+[</option>]
                                    endif
                                endif
                            endif
                        endfor
                        l_cHtml += [</select>]
                        
                    case ListOfCustomFieldsToBuild->CustomField_Type == 3  // String
                        l_nLength := max(1,nvl(ListOfCustomFieldsToBuild->CustomField_Length,0))
                        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="text" name="Text]+l_cObjectName+[" id="Text]+l_cObjectName+[" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,l_cObjectName,""))+[" maxlength="]+Trans(l_nLength)+[" size="]+Trans(Min(l_nLength,80))+[" ]+par_extra_property+[>]
                        
                    case ListOfCustomFieldsToBuild->CustomField_Type == 4  // Text Area
                        l_nWidth  := max(1,nvl(ListOfCustomFieldsToBuild->CustomField_Width,0))
                        l_nHeight := max(1,nvl(ListOfCustomFieldsToBuild->CustomField_Height,0))
                        l_cHtml += [<textarea]+UPDATESAVEBUTTON+[ name="Text]+l_cObjectName+[" id="Text]+l_cObjectName+[" rows="]+Trans(l_nHeight)+[" cols="]+Trans(l_nWidth)+[" ]+par_extra_property+[>]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,l_cObjectName,""))+[</textarea>]

                    case ListOfCustomFieldsToBuild->CustomField_Type == 5  // Date
                        l_xValue := hb_HGetDef(par_hValues,l_cObjectName,nil)
                        if ValType(l_xValue) == "D"
                            l_xValue := dtoc(l_xValue)
                        else
                            l_xValue := ""
                        endif

                        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="text" name="Text]+l_cObjectName+[" id="Text]+l_cObjectName+[" value="]+FcgiPrepFieldForValue(l_xValue)+[" maxlength="10" size="10" ]+par_extra_property+[>]
                        oFcgi:p_cjQueryScript += [$("#Text]+l_cObjectName+[").datepicker();]

                    endcase


                    // l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus">]
                    //     l_cHtml += [<option value="1"]+iif(l_iDocStatus==1,[ selected],[])+[>Missing</option>]
                    //     l_cHtml += [<option value="2"]+iif(l_iDocStatus==2,[ selected],[])+[>Not Needed</option>]
                    //     l_cHtml += [<option value="3"]+iif(l_iDocStatus==3,[ selected],[])+[>Composing</option>]
                    //     l_cHtml += [<option value="4"]+iif(l_iDocStatus==4,[ selected],[])+[>Completed</option>]
                    // l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]

        endscan
    endif

endwith

select (l_select)
return l_cHtml
//=================================================================================================================
function CustomFieldsSave(par_iApplicationPk,par_UsedOn,par_iPk)
local l_select := iif(used(),select(),0)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cObjectName
local l_lSelectedOnForm
local l_lOnFile
local l_xValue

with object l_oDB1
    :Table("a88447b8-5ccc-461e-91db-fe6f2323e7f4","ApplicationCustomField")
    :Column("CustomField.pk" , "pk")
    :Column("CustomField.Type"            ,"CustomField_Type")
    :Column("CustomFieldValue.pk"         ,"CustomFieldValue_pk")
    :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
    :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
    :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :join("left","CustomFieldValue","","CustomFieldValue.fk_CustomField = CustomField.pk and CustomFieldValue.fk_Entity = ^" , par_iPk)
    :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
    :Where("CustomField.UsedOn = ^" , par_UsedOn)
    :Where("CustomField.Status <= 2")
    :SQL("ListOfCustomFieldsSave")

    if :Tally > 0
        select ListOfCustomFieldsSave
        scan all
            l_cObjectName := "CustomField"+Trans(ListOfCustomFieldsSave->pk)
            l_lOnFile     := !hb_orm_IsNull("ListOfCustomFieldsSave","CustomFieldValue_pk")

            switch ListOfCustomFieldsSave->CustomField_Type
            case 1  // Logical

                l_lSelectedOnForm := (oFcgi:GetInputValue("Check"+l_cObjectName) == "1")

                if l_lSelectedOnForm <> l_lOnFile
                    if l_lOnFile
                        // Delete record in CustomFieldValue
                        :Delete("e3d306b8-0cc3-45f4-b101-5dcd3602a921","CustomFieldValue",ListOfCustomFieldsSave->CustomFieldValue_pk)
                    else
                        // Add Record in CustomFieldValue
                        with object l_oDB2
                            :Table("50378b3c-3b1c-42db-bbab-0e8b0bd9a67f","CustomFieldValue")
                            :Field("CustomFieldValue.fk_CustomField" , ListOfCustomFieldsSave->pk)
                            :Field("CustomFieldValue.fk_Entity"      , par_iPk)
                            :Add()
                        endwith
                    endif
                endif
                exit

            case 2  // Multi Choice
                l_xValue := SanitizeInput(oFcgi:GetInputValue("Combo"+l_cObjectName))
                if !empty(l_xValue) .and. !empty(val(l_xValue))
                    if l_lOnFile
                        if ListOfCustomFieldsSave->CustomFieldValue_ValueI <> Val(l_xValue)
                            with object l_oDB2
                                :Table("643ae636-41b7-43a3-bdf6-3d24c18db44a","CustomFieldValue")
                                :Field("CustomFieldValue.ValueI"         , Val(l_xValue))
                                :Update(ListOfCustomFieldsSave->CustomFieldValue_pk)
                            endwith
                        endif
                    else
                        with object l_oDB2
                            :Table("ce3e092f-ac7f-4160-bfc0-add5a9b03bf0","CustomFieldValue")
                            :Field("CustomFieldValue.fk_CustomField" , ListOfCustomFieldsSave->pk)
                            :Field("CustomFieldValue.fk_Entity"      , par_iPk)
                            :Field("CustomFieldValue.ValueI"         , Val(l_xValue))
                            :Add()
                        endwith
                    endif
                else
                    //Delete if on file
                    if l_lOnFile
                        l_oDB2:Delete("32ea223f-10a8-434d-a6c1-b42b4d38a6de","CustomFieldValue",ListOfCustomFieldsSave->CustomFieldValue_pk)
                    endif
                endif
                exit

            case 3  // String
            case 4  // Text Area
                l_xValue := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("Text"+l_cObjectName)))
                if empty(l_xValue)
                    if l_lOnFile
                        l_oDB2:Delete("56b34f02-8eed-43e1-8524-e82916c1910b","CustomFieldValue",ListOfCustomFieldsSave->CustomFieldValue_pk)
                    endif
                else
                    with object l_oDB2
                        :Table("25b1c8a9-c807-4ae6-a4a9-22970456ad85","CustomFieldValue")
                        :Field("CustomFieldValue.ValueM"             , l_xValue)
                        if l_lOnFile
                            :Update(ListOfCustomFieldsSave->CustomFieldValue_pk)
                        else
                            :Field("CustomFieldValue.fk_CustomField" , ListOfCustomFieldsSave->pk)
                            :Field("CustomFieldValue.fk_Entity"      , par_iPk)
                            :Add()
                        endif
                    endwith
                endif
                exit
                
            case 5  // Date
                l_xValue := Alltrim(SanitizeInput(oFcgi:GetInputValue("Text"+l_cObjectName)))
                if !empty(l_xValue) .and. !empty(ctod(l_xValue))
                    if l_lOnFile
                        if ListOfCustomFieldsSave->CustomFieldValue_ValueD <> ctod(l_xValue)
                            with object l_oDB2
                                :Table("e51dcbc7-63d5-45ad-8da1-31023513640f","CustomFieldValue")
                                :Field("CustomFieldValue.ValueD"         , ctod(l_xValue))
                                :Update(ListOfCustomFieldsSave->CustomFieldValue_pk)
                            endwith
                        endif
                    else
                        with object l_oDB2
                            :Table("efed91ca-7ad0-462a-9f6d-8f03a3c87404","CustomFieldValue")
                            :Field("CustomFieldValue.fk_CustomField" , ListOfCustomFieldsSave->pk)
                            :Field("CustomFieldValue.fk_Entity"      , par_iPk)
                            :Field("CustomFieldValue.ValueD"         , ctod(l_xValue))
                            :Add()
                        endwith
                    endif
                else
                    //Delete if on file
                    if l_lOnFile
                        l_oDB2:Delete("2e47e24f-bc06-4bb2-aa7a-9cf56166867e","CustomFieldValue",ListOfCustomFieldsSave->CustomFieldValue_pk)
                    endif
                endif
                exit

            endswitch

        endscan
    endif

endwith

select (l_select)
return Nil
//=================================================================================================================
function CustomFieldsDelete(par_iApplicationPk,par_UsedOn,par_iPk)
local l_select := iif(used(),select(),0)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("ae52ebe2-6583-4329-a6eb-ee21eefdff23","ApplicationCustomField")
    :Column("CustomField.pk" , "pk")
    :Column("CustomField.Type"            ,"CustomField_Type")
    :Column("CustomFieldValue.pk"         ,"CustomFieldValue_pk")
    :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
    :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
    :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
    :Join("inner","CustomField","","ApplicationCustomField.fk_CustomField = CustomField.pk")
    :join("inner","CustomFieldValue","","CustomFieldValue.fk_CustomField = CustomField.pk and CustomFieldValue.fk_Entity = ^" , par_iPk)
    :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
    :Where("CustomField.UsedOn = ^" , par_UsedOn)
    // :Where("CustomField.Status <= 2")
    :SQL("ListOfCustomFieldsDelete")

    if :Tally > 0
        select ListOfCustomFieldsDelete
        scan all
            l_oDB2:Delete("f635b4d7-2027-4136-ba7e-cf495661c4f8","CustomFieldValue",ListOfCustomFieldsDelete->CustomFieldValue_pk)
        endscan
    endif

endwith

select (l_select)
return Nil
//=================================================================================================================
function CustomFieldLoad_hOptionValueToDescriptionMapping(par_hOptionValueToDescriptionMapping)   // par_hOptionValueToDescriptionMapping passed by reference
local l_nLineNumber
local l_cLine
local l_nPos
local l_cOptionVal
local l_cOptionText

select ListOfCustomFieldOptionDefinition
scan all
    for l_nLineNumber := 1 to MLCount(ListOfCustomFieldOptionDefinition->CustomField_OptionDefinition,1024)
        l_cLine := MemoLine(ListOfCustomFieldOptionDefinition->CustomField_OptionDefinition,1024,l_nLineNumber)
        if !empty(l_cLine)
            l_nPos := at(":",l_cLine)
            if !empty(l_nPos)
                l_cOptionVal  := Alltrim(left(l_cLine,l_nPos-1))
                l_cOptionText := Alltrim(Substr(l_cLine,l_nPos+1))
                par_hOptionValueToDescriptionMapping[Trans(ListOfCustomFieldOptionDefinition->CustomField_pk)+"_"+l_cOptionVal] := l_cOptionText
            endif
        endif
    endfor
endscan
return nil
//=================================================================================================================
function CustomFieldsBuildGridOther(par_iPk,par_hOptionValueToDescriptionMapping)  // Requires alias ListOfCustomFieldValues
local l_cHtml := ""

select ListOfCustomFieldValues
scan all for ListOfCustomFieldValues->fk_entity = par_iPk
    if !empty(l_cHtml)
        l_cHtml += [<hr>]
    endif

    switch ListOfCustomFieldValues->CustomField_Type
    case 1  // Logical
        l_cHtml += [<b>]+ListOfCustomFieldValues->CustomField_Label+[</b>]
        exit
    case 2  // Multi Choice
        l_cHtml += [<span><b>]+ListOfCustomFieldValues->CustomField_Label+[</b></span>]
        l_cHtml += [<span class="ms-1">]+hb_HGetDef(par_hOptionValueToDescriptionMapping, Trans(ListOfCustomFieldValues->CustomField_pk)+"_"+Trans(ListOfCustomFieldValues->CustomFieldValue_ValueI) ,"")+[</span>]
        exit
    case 3  // String
        l_cHtml += [<div><b>]+ListOfCustomFieldValues->CustomField_Label+[</b></div>]
        l_cHtml += [<div>]+ListOfCustomFieldValues->CustomFieldValue_ValueM+[</div>]
        exit
    case 4  // Text Area
        l_cHtml += [<div><b>]+ListOfCustomFieldValues->CustomField_Label+[</b></div>]
        l_cHtml += [<div>]+TextToHtml(ListOfCustomFieldValues->CustomFieldValue_ValueM)+[</div>]
        exit
    case 5  // Date                                    
        l_cHtml += [<span><b>]+ListOfCustomFieldValues->CustomField_Label+[</b></span>]
        l_cHtml += [<span class="ms-1">]+dtoc(ListOfCustomFieldValues->CustomFieldValue_ValueD)+[</span>]
        exit
    endcase

endscan

return l_cHtml
//=================================================================================================================
