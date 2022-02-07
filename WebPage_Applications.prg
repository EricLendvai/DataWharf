#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageApplications()
local l_cHtml := []
local l_cHtmlUnderHeader

local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationDescription

local l_hValues := {=>}

local l_cApplicationElement := "SETTINGS"  //Default Element

local l_aSQLResult := {}

local l_cURLAction              := "ListApplications"
local l_cURLApplicationLinkCode := ""
local l_cURLVersionCode         := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]

local l_nAccessLevelDD := 1   // None by default
// As per the info in Schema.txt
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     6 - Edit Anything and Load/Sync Schema
//     7 - Full Access


oFcgi:TraceAdd("BuildPageApplications")

// Variables
// l_cURLAction
// l_cURLApplicationLinkCode
// l_cURLVersionCode

//Improved and new way:
// Applications/                      Same as Applications/ListApplications/
// Applications/NewApplication/
// Applications/ApplicationSettings/<ApplicationLinkCode>/

// Applications/ListVersions/<ApplicationLinkCode>/
// Applications/NewVersion/<ApplicationLinkCode>/
// Applications/EditVersion/<ApplicationLinkCode>/<VersionCode>/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLApplicationLinkCode := oFcgi:p_URLPathElements[3]
    endif
    if vfp_Inlist(l_cURLAction,"EditVersion")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLVersionCode := oFcgi:p_URLPathElements[4]
        endif
    endif

    do case
    case vfp_Inlist(l_cURLAction,"ApplicationSettings")
        l_cApplicationElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"ListVersions","NewVersion","EditVersion")
        l_cApplicationElement := "VERSIONS"

    otherwise
        l_cApplicationElement := "SETTINGS"

    endcase

    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if !empty(l_cURLApplicationLinkCode)
        with object l_oDB1
            :Table("9530febe-ddeb-4b48-b951-058c56685b58","Application")
            :Column("Application.pk"          , "pk")
            :Column("Application.Name"        , "Application_Name")
            :Where("Application.LinkCode = ^" ,l_cURLApplicationLinkCode)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB1:Tally == 1
            l_iApplicationPk          := l_aSQLResult[1,1]
            l_cApplicationName        := l_aSQLResult[1,2]
        else
            l_iApplicationPk   := -1
            l_cApplicationName := "Unknown"
        endif
    endif

    do case
    case oFcgi:p_nUserAccessMode <= 1  // Application access levels
        with object l_oDB1
            :Table("296720ff-9cea-4b71-ba4c-05ba7a4212d0","UserAccessApplication")
            :Column("UserAccessApplication.AccessLevelDD" , "AccessLevelDD")
            :Where("UserAccessApplication.fk_User = ^"    , oFcgi:p_iUserPk)
            :Where("UserAccessApplication.fk_Application = ^" ,l_iApplicationPk)
            :SQL(@l_aSQLResult)
            if l_oDB1:Tally == 1
                l_nAccessLevelDD := l_aSQLResult[1,1]
            else
                l_nAccessLevelDD := 0
            endif
        endwith

    case oFcgi:p_nUserAccessMode  = 2  // All Application Read Only
        l_nAccessLevelDD := 2
    case oFcgi:p_nUserAccessMode  = 3  // All Application Full Access
        l_nAccessLevelDD := 7
    case oFcgi:p_nUserAccessMode  = 4  // Root Admin (User Control)
        l_nAccessLevelDD := 7
    endcase

else
    l_cURLAction := "ListApplications"
endif

oFcgi:p_nAccessLevelDD := l_nAccessLevelDD

do case
case l_cURLAction == "ListApplications"
    // l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    //     l_cHtml += [<div class="input-group">]
    //         l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[Applications/">Applications</a>]
    //         if oFcgi:p_nUserAccessMode >= 3
    //             l_cHtml += [<a class="btn btn-primary rounded" ms-0 href="]+l_cSitePath+[Applications/NewApplication">New Application</a>]
    //         endif
    //     l_cHtml += [</div>]
    // l_cHtml += [</nav>]

    l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Applications</span></div>]
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Applications/NewApplication">New Application</a></div>]
    endif
    l_cHtml += [</div>]

    l_cHtml += ApplicationListFormBuild()

case l_cURLAction == "NewApplication"
    if oFcgi:p_nUserAccessMode >= 3
        // l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        //     l_cHtml += [<div class="input-group">]
        //         l_cHtml += [<span class="navbar-brand text-white ms-3">New Application</span>]
        //     l_cHtml += [</div>]
        // l_cHtml += [</nav>]

        l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
        l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">New Application</span></div>]
        l_cHtml += [</div>]

        if oFcgi:isGet()
            //Brand new request of add an application.
            l_cHtml += ApplicationEditFormBuild("",0,{=>})
        else
            l_cHtml += ApplicationEditFormOnSubmit("")
        endif
    endif

case l_cURLAction == "ApplicationSettings"
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("2ce4d4b4-2ee3-42bf-91d1-5fa29a4c9b07","public.Application")
                :Column("Application.UseStatus"      , "Application_UseStatus")
                :Column("Application.DocStatus"      , "Application_DocStatus")
                :Column("Application.Description"    , "Application_Description")
                l_oData := :Get(l_iApplicationPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]          := l_cApplicationName
                l_hValues["LinkCode"]      := l_cURLApplicationLinkCode
                l_hValues["UseStatus"]     := l_oData:Application_UseStatus
                l_hValues["DocStatus"]     := l_oData:Application_DocStatus
                l_hValues["Description"]   := l_oData:Application_Description

                CustomFieldsLoad(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk,@l_hValues)

                l_cHtml += ApplicationEditFormBuild("",l_iApplicationPk,l_hValues)
            endif
        else
            if l_iApplicationPk > 0
                l_cHtml += ApplicationEditFormOnSubmit(l_cURLApplicationLinkCode)
            endif
        endif
    endif

case l_cURLAction == "ListVersions"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    //_M_

otherwise

endcase

return l_cHtml
//=================================================================================================================
static function ApplicationHeaderBuild(par_iApplicationPk,par_cApplicationName,par_cApplicationElement,par_cSitePath,par_cURLApplicationLinkCode,par_lActiveHeader)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("ApplicationHeaderBuild")

// l_cHtml += [<nav class="navbar navbar-default bg-secondary bg-gradient">]
//     l_cHtml += [<div class="input-group">]
//         l_cHtml += [<span class="ps-2 navbar-brand text-white">Manage Application - ]+par_cApplicationName+[</span>]
//     l_cHtml += [</div>]
// l_cHtml += [</nav>]

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Configure Application: ]+par_cApplicationName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Applications/">Other Applications</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ApplicationSettings/]+par_cURLApplicationLinkCode+[/">Application Settings</a>]
        l_cHtml += [</li>]
    endif
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "VERSIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListVersions/]+par_cURLApplicationLinkCode+[/">Versions</a>]
        l_cHtml += [</li>]
    endif
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ApplicationListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfApplications
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("ApplicationListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("70a13bfd-f9b0-4c36-a8d7-af8ed062d781","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Application.LinkCode"   ,"Application_LinkCode")
    :Column("Application.UseStatus"  ,"Application_UseStatus")
    :Column("Application.DocStatus"  ,"Application_DocStatus")
    :Column("Application.Description","Application_Description")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif

    :SQL("ListOfApplications")
    l_nNumberOfApplications := :Tally
endwith


if l_nNumberOfApplications > 0
    with object l_oDB2
        :Table("279f9d90-7b3c-4a5a-8bcc-ced72a2651e4","Application")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Application.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_APPLICATION)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("d7cd59ac-d135-4127-9302-ee3625cafb6e","Application")
        :Column("Application.pk"              ,"fk_entity")
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.Label"           ,"CustomField_Label")
        :Column("CustomField.Type"            ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Application.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_APPLICATION)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfApplications)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Application on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"5","6")+[">Applications (]+Trans(l_nNumberOfApplications)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Link Code</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfApplications
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ApplicationSettings/]+AllTrim(ListOfApplications->Application_LinkCode)+[/">]+Allt(ListOfApplications->Application_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfApplications->Application_LinkCode)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfApplications->Application_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfApplications->Application_UseStatus,1,6),ListOfApplications->Application_UseStatus,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfApplications->Application_DocStatus,1,4),ListOfApplications->Application_DocStatus,1)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfApplications->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function ApplicationEditFormBuild(par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText      := hb_DefaultValue(par_cErrorText,"")

local l_cName           := hb_HGetDef(par_hValues,"Name","")
local l_cLinkCode       := hb_HGetDef(par_hValues,"LinkCode","")
local l_nUseStatus      := hb_HGetDef(par_hValues,"UseStatus",1)
local l_nDocStatus      := hb_HGetDef(par_hValues,"DocStatus",1)
local l_cDescription    := nvl(hb_HGetDef(par_hValues,"Description",""),"")

oFcgi:TraceAdd("ApplicationEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New Application</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update Application Settings</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelDD >= 7
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 7
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Link Code</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLinkCode" id="TextLinkCode" value="]+FcgiPrepFieldForValue(l_cLinkCode)+[" maxlength="10" size="10" style="text-transform: uppercase;"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Doc Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus">]
                    l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        if !empty(par_iPk)
            l_cHtml += CustomFieldsBuild(par_iPk,USEDON_APPLICATION,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))
        endif

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ApplicationEditFormOnSubmit(par_cURLApplicationLinkCode)
local l_cHtml := []
local l_cActionOnSubmit

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationLinkCode
local l_nApplicationUseStatus
local l_nApplicationDocStatus
local l_cApplicationDescription

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("ApplicationEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationPk             := Val(oFcgi:GetInputValue("TableKey"))
l_cApplicationName           := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cApplicationLinkCode       := Upper(Strtran(SanitizeInput(oFcgi:GetInputValue("TextLinkCode"))," ",""))
l_nApplicationUseStatus      := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nApplicationDocStatus      := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cApplicationDescription    := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nUserAccessMode >= 3
        do case
        case empty(l_cApplicationName)
            l_cErrorMessage := "Missing Name"
        case empty(l_cApplicationLinkCode)
            l_cErrorMessage := "Missing Link Code"
        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("11e12796-cf00-4bbb-9069-fd9cf6fefd59","Application")
                :Where([lower(replace(Application.Name,' ','')) = ^],lower(StrTran(l_cApplicationName," ","")))
                if l_iApplicationPk > 0
                    :Where([Application.pk != ^],l_iApplicationPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB1
                    :Table("9bce64bf-0f5a-4465-9fbc-95fad9ae0513","Application")
                    :Where([upper(replace(Application.LinkCode,' ','')) = ^],l_cApplicationLinkCode)
                    if l_iApplicationPk > 0
                        :Where([Application.pk != ^],l_iApplicationPk)
                    endif
                    :SQL()
                endwith

                if l_oDB1:Tally <> 0
                    l_cErrorMessage := "Duplicate Link Code"
                else
                    //Save the Application
                    with object l_oDB1
                        :Table("775d6628-4c99-40d4-8955-50805adf7aa9","Application")
                        :Field("Application.Name"           , l_cApplicationName)
                        :Field("Application.LinkCode"       , l_cApplicationLinkCode)
                        :Field("Application.UseStatus"      , l_nApplicationUseStatus)
                        :Field("Application.DocStatus"      , l_nApplicationDocStatus)
                        :Field("Application.Description"    , iif(empty(l_cApplicationDescription),NULL,l_cApplicationDescription))
                        
                        if empty(l_iApplicationPk)
                            if :Add()
                                l_iApplicationPk := :Key()
                                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListVersions/"+l_cApplicationLinkCode+"/")
                            else
                                l_cErrorMessage := "Failed to add Application."
                            endif
                        else
                            if :Update(l_iApplicationPk)
                                CustomFieldsSave(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk)
                                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListVersions/"+l_cApplicationLinkCode+"/")
                            else
                                l_cErrorMessage := "Failed to update Application."
                            endif
                        endif
                    endwith
                endif
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"
    if empty(l_iApplicationPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ListVersions/"+par_cURLApplicationLinkCode+"/")
    endif

case l_cActionOnSubmit == "Delete"   // Application
    if oFcgi:p_nUserAccessMode >= 3
        if CheckIfAllowDestructiveApplicationDelete(l_iApplicationPk)
            l_cErrorMessage := CascadeDeleteApplication(l_iApplicationPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

            with object l_oDB1
                :Table("f67dd895-a6c9-4082-81d4-19204bf153c8","NameSpace")
                :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
                :SQL()

                if :Tally == 0
                    :Table("2ec589c5-3e9f-4835-81f2-2d595387421f","Version")
                    :Where("Version.fk_Application = ^",l_iApplicationPk)
                    :SQL()

                    if :Tally == 0
                        //Don't Have to test on related Table or DiagramTables since deleting Table would remove DiagramTables records and NameSpaces can no be removed with Tables
                        //But we may have some left over Table less diagrams. Remove them

                        :Table("49de7c69-9e71-4174-9fec-de21b79f0245","Diagram")
                        :Column("Diagram.pk" , "pk")
                        :Where("Diagram.fk_Application = ^",l_iApplicationPk)
                        :SQL("ListOfDiagramRecordsToDelete")
                        if :Tally >= 0
                            if :Tally > 0
                                select ListOfDiagramRecordsToDelete
                                scan
                                    l_oDB2:Delete("5e0d131b-c60c-4c49-bddd-21addd4cac0a","Diagram",ListOfDiagramRecordsToDelete->pk)
                                endscan
                            endif

                            CustomFieldsDelete(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk)
                            :Delete("fe1f5393-2e12-436c-b1b0-924344efc1b9","Application",l_iApplicationPk)
                        else
                            l_cErrorMessage := "Failed to clear related DiagramTable records."
                        endif

                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/")
                    else
                        l_cErrorMessage := "Related Version record on file"
                    endif
                else
                    l_cErrorMessage := "Related Name Space record on file"
                endif
            endwith
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]           := l_cApplicationName
    l_hValues["LinkCode"]       := l_cApplicationLinkCode
    l_hValues["UseStatus"]      := l_nApplicationUseStatus
    l_hValues["DocStatus"]      := l_nApplicationDocStatus
    l_hValues["Description"]    := l_cApplicationDescription

    CustomFieldsFormToHash(l_iApplicationPk,USEDON_APPLICATION,@l_hValues)

    l_cHtml += ApplicationEditFormBuild(l_cErrorMessage,l_iApplicationPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CascadeDeleteApplication(par_iApplicationPk)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)  // Since executing a select at this level, may not pass l_oDB1 for reuse.
local l_cErrorMessage := ""

with object l_oDB1
    :Table("ff898367-8a10-41ac-ad1d-8eaaec72fe0d","NameSpace")
    :Column("NameSpace.pk","pk")
    :Where("NameSpace.fk_Application = ^" , par_iApplicationPk)
    :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
    if :Tally < 0
        l_cErrorMessage := "Failed to delete Application. Error 1."
    else
        select ListOfRecordsToDeleteInCascadeDeleteApplication
        scan all
            l_cErrorMessage := CascadeDeleteNameSpace(par_iApplicationPk,ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
            if !empty(l_cErrorMessage)
                exit
            endif
        endscan
    endif
    
    if empty(l_cErrorMessage)
        :Table("00660757-26a7-4d3b-ac6b-6bfa8b4bfc49","Diagram")
        :Column("Diagram.pk","pk")
        :Where("Diagram.fk_Application = ^" , par_iApplicationPk)
        :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete Application. Error 2."
        else
            select ListOfRecordsToDeleteInCascadeDeleteApplication
            scan all
                if !:Delete("a5dd9e66-3ecb-4780-b5c0-e8a6308eb49a","Diagram",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                    l_cErrorMessage := "Failed to delete Application. Error 3."
                    exit
                endif
            endscan

            if empty(l_cErrorMessage)

                :Table("26f6b1c2-401d-4bb7-aa21-5c7edd97535b","Version")
                :Column("Version.pk","pk")
                :Where("Version.fk_Application = ^" , par_iApplicationPk)
                :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
                if :Tally < 0
                    l_cErrorMessage := "Failed to delete Application. Error 4."
                else
                    select ListOfRecordsToDeleteInCascadeDeleteApplication
                    scan all
                        if !:Delete("3862d009-1f7c-4c4e-b987-14b47560f09c","Version",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                            l_cErrorMessage := "Failed to delete Application. Error 5."
                            exit
                        endif
                    endscan
                    
                    if empty(l_cErrorMessage)

                        :Table("308f0e3b-029d-4104-aad7-6bfece9817f6","ApplicationCustomField")
                        :Column("ApplicationCustomField.pk","pk")
                        :Where("ApplicationCustomField.fk_Application = ^" , par_iApplicationPk)
                        :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
                        if :Tally < 0
                            l_cErrorMessage := "Failed to delete Application. Error 6."
                        else
                            select ListOfRecordsToDeleteInCascadeDeleteApplication
                            scan all
                                if !:Delete("eecb94eb-aa3d-4f58-9fc5-373964ed9aa8","ApplicationCustomField",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                                    l_cErrorMessage := "Failed to delete Application. Error 7."
                                    exit
                                endif
                            endscan
                            
                            if empty(l_cErrorMessage)

                                :Table("df5a5c9b-1c0a-483a-b510-bd8d98b9858d","UserAccessApplication")
                                :Column("UserAccessApplication.pk","pk")
                                :Where("UserAccessApplication.fk_Application = ^" , par_iApplicationPk)
                                :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
                                if :Tally < 0
                                    l_cErrorMessage := "Failed to delete Application. Error 8."
                                else
                                    select ListOfRecordsToDeleteInCascadeDeleteApplication
                                    scan all
                                        if !:Delete("fce416e5-7991-4180-aa1c-b95ed1789cef","UserAccessApplication",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                                            l_cErrorMessage := "Failed to delete Application. Error 9."
                                            exit
                                        endif
                                    endscan

                                    if empty(l_cErrorMessage)

                                        :Table("6c32710b-ab9d-4525-8d9a-af6b0690d45b","Tag")
                                        :Column("Tag.pk","pk")
                                        :Where("Tag.fk_Application = ^" , par_iApplicationPk)
                                        :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
                                        if :Tally < 0
                                            l_cErrorMessage := "Failed to delete Application. Error 8."
                                        else
                                            select ListOfRecordsToDeleteInCascadeDeleteApplication
                                            scan all
                                                if !:Delete("a7c83051-1e7d-44d5-9229-1965656e4370","Tag",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                                                    l_cErrorMessage := "Failed to delete Application. Error 9."
                                                    exit
                                                endif
                                            endscan
                                            
                                            if empty(l_cErrorMessage)
                                                CustomFieldsDelete(par_iApplicationPk,USEDON_APPLICATION,par_iApplicationPk)
                                                if !:Delete("535048f7-4dd6-4043-8bd5-278dd444ec7a","Application",par_iApplicationPk)
                                                    l_cErrorMessage := "Failed to delete Application. Error 10."
                                                endif
                                            endif

                                        endif
                                    endif
                                endif
                            endif
                        endif
                    endif
                endif
            endif
        endif
    endif
endwith
return l_cErrorMessage
//=================================================================================================================
