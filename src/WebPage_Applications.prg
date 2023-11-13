#include "DataWharf.ch"

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

local l_iDeploymentPk

local l_cApplicationElement := "INFO"  //Default Element

local l_aSQLResult := {}

local l_cURLAction              := "ListApplications"
local l_cURLApplicationLinkCode := ""
local l_cURLVersionCode         := ""
local l_cURLLinkUID             := ""
local l_cSitePath := oFcgi:p_cSitePath

local l_nAccessLevelDD := 1   // None by default
// As per the info in Schema.prg
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything and Import/Export
//     6 - Edit Anything and Sync Schema
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

// Applications/ApplicationInfo/<ApplicationLinkCode>/

// Applications/ListVersions/<ApplicationLinkCode>/
// Applications/NewVersion/<ApplicationLinkCode>/
// Applications/EditVersion/<ApplicationLinkCode>/<VersionCode>/

// Applications/ListDeployments/<ApplicationLinkCode>/
// Applications/NewDeployment/<ApplicationLinkCode>/
// Applications/EditDeployment/<ApplicationLinkCode>/<Deployment.LinkUID>

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLApplicationLinkCode := oFcgi:p_URLPathElements[3]
    endif

    if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
        l_cURLLinkUID := oFcgi:p_URLPathElements[4]
    endif

    if vfp_Inlist(l_cURLAction,"EditVersion")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            l_cURLVersionCode := oFcgi:p_URLPathElements[4]
        endif
    endif

    do case
    case vfp_Inlist(l_cURLAction,"ApplicationInfo")
        l_cApplicationElement := "INFO"

    case vfp_Inlist(l_cURLAction,"ApplicationSettings")
        l_cApplicationElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"ListVersions","NewVersion","EditVersion")
        l_cApplicationElement := "VERSIONS"

    case vfp_Inlist(l_cURLAction,"ListDeployments","NewDeployment","EditDeployment")
        l_cApplicationElement := "DEPLOYMENTS"

    otherwise
        l_cApplicationElement := "INFO"

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
            l_iApplicationPk   := l_aSQLResult[1,1]
            l_cApplicationName := l_aSQLResult[1,2]
        else
            l_iApplicationPk   := -1
            l_cApplicationName := "Unknown"
        endif
    endif

    l_nAccessLevelDD := GetAccessLevelDDForApplication(l_iApplicationPk)

else
    l_cURLAction := "ListApplications"
endif

if  oFcgi:p_nUserAccessMode >= 3
    oFcgi:p_nAccessLevelDD := 7
else
    oFcgi:p_nAccessLevelDD := l_nAccessLevelDD
endif

do case
case l_cURLAction == "ListApplications"
    l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Applications</span></div>]
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Applications/NewApplication">New Application</a></div>]
    endif
    l_cHtml += [</div>]

    l_cHtml += ApplicationListFormBuild()

case l_cURLAction == "NewApplication"
    if oFcgi:p_nUserAccessMode >= 3
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


case l_cURLAction == "ApplicationInfo"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("33728b1f-3db2-4902-b337-d14f91f61b62","public.Application")
        :Column("Application.UseStatus"         , "Application_UseStatus")
        :Column("Application.DocStatus"         , "Application_DocStatus")
        :Column("Application.Description"       , "Application_Description")
        :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
        l_oData := :Get(l_iApplicationPk)
    endwith

    if l_oDB1:Tally == 1
        l_hValues["Name"]              := l_cApplicationName
        l_hValues["LinkCode"]          := l_cURLApplicationLinkCode
        l_hValues["UseStatus"]         := l_oData:Application_UseStatus
        l_hValues["DocStatus"]         := l_oData:Application_DocStatus
        l_hValues["Description"]       := l_oData:Application_Description
        l_hValues["DestructiveDelete"] := l_oData:Application_DestructiveDelete

        CustomFieldsLoad(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk,@l_hValues)

        l_cHtml += ApplicationInfoFormBuild("",l_iApplicationPk,l_hValues)
    endif

case l_cURLAction == "ApplicationSettings"
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("2ce4d4b4-2ee3-42bf-91d1-5fa29a4c9b07","public.Application")
                :Column("Application.UseStatus"         , "Application_UseStatus")
                :Column("Application.DocStatus"         , "Application_DocStatus")
                :Column("Application.Description"       , "Application_Description")
                :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
                l_oData := :Get(l_iApplicationPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]              := l_cApplicationName
                l_hValues["LinkCode"]          := l_cURLApplicationLinkCode
                l_hValues["UseStatus"]         := l_oData:Application_UseStatus
                l_hValues["DocStatus"]         := l_oData:Application_DocStatus
                l_hValues["Description"]       := l_oData:Application_Description
                l_hValues["DestructiveDelete"] := l_oData:Application_DestructiveDelete

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

case l_cURLAction == "ListDeployments"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    l_cHtml += DeploymentListFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode)

case l_cURLAction == "NewDeployment"
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
        
        if oFcgi:isGet()
            l_cHtml += DeploymentEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",0,{=>})
        else
            l_cHtml += DeploymentEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

case l_cURLAction == "EditDeployment"
    l_cHtml += ApplicationHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
    
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB1
        :Table("2a79c7c5-bfa4-4cd9-9d5a-842e920f0398","Deployment")
        :Column("Deployment.pk"                 , "Pk")                  // 1
        :Column("Deployment.Name"               , "Name")                // 2
        :Column("Deployment.Status"             , "Status")              // 3
        :Column("Deployment.Description"        , "Description")         // 4
        :Column("Deployment.BackendType"        , "BackendType")         // 5
        :Column("Deployment.Server"             , "Server")              // 6
        :Column("Deployment.Port"               , "Port")                // 7
        :Column("Deployment.User"               , "User")                // 8
        :Column("Deployment.Database"           , "Database")            // 9
        :Column("Deployment.NameSpaces"         , "NameSpaces")          // 10
        :Column("Deployment.SetForeignKey"      , "SetForeignKey")       // 11
        :Column("Deployment.PasswordStorage"    , "PasswordStorage")     // 12
        :Column("Deployment.PasswordConfigKey"  , "PasswordConfigKey")   // 13
        :Column("Deployment.PasswordEnvVarName" , "PasswordEnvVarName")  // 14

        :Where([Deployment.fk_Application = ^],l_iApplicationPk)
        :Where([Deployment.LinkUID = ^]       ,l_cURLLinkUID)
        :SQL(@l_aSQLResult)
    endwith

    if l_oDB1:Tally != 1
        oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ListDeployments/"+l_cURLApplicationLinkCode+"/")
    else
        if oFcgi:isGet()
            l_iDeploymentPk                 := l_aSQLResult[1,1]

            l_hValues["Name"]               := AllTrim(l_aSQLResult[1,2])
            l_hValues["Status"]             := l_aSQLResult[1, 3]
            l_hValues["Description"]        := l_aSQLResult[1, 4]
            l_hValues["BackendType"]        := nvl(l_aSQLResult[1, 5],0)
            l_hValues["Server"]             := AllTrim(nvl(l_aSQLResult[1, 6],""))
            l_hValues["Port"]               := nvl(l_aSQLResult[1, 7],0)
            l_hValues["User"]               := AllTrim(nvl(l_aSQLResult[1, 8],""))
            l_hValues["Database"]           := AllTrim(nvl(l_aSQLResult[1, 9],""))
            l_hValues["NameSpaces"]         := AllTrim(nvl(l_aSQLResult[1,10],""))
            l_hValues["SetForeignKey"]      := nvl(l_aSQLResult[1,11],0)
            l_hValues["PasswordStorage"]    := nvl(l_aSQLResult[1,12],0)
            l_hValues["PasswordConfigKey"]  := AllTrim(nvl(l_aSQLResult[1,13],""))
            l_hValues["PasswordEnvVarName"] := AllTrim(nvl(l_aSQLResult[1,14],""))

            l_cHtml += DeploymentEditFormBuild(l_iApplicationPk,l_cURLApplicationLinkCode,"",l_iDeploymentPk,l_hValues)
        else
            l_cHtml += DeploymentEditFormOnSubmit(l_iApplicationPk,l_cURLApplicationLinkCode)
        endif
    endif

otherwise

endcase

return l_cHtml
//=================================================================================================================
static function ApplicationHeaderBuild(par_iApplicationPk,par_cApplicationName,par_cApplicationElement,par_cSitePath,par_cURLApplicationLinkCode,par_lActiveHeader)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:p_cSitePath

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
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "INFO",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ApplicationInfo/]+par_cURLApplicationLinkCode+[/">Application Info</a>]
    l_cHtml += [</li>]
    if oFcgi:p_nAccessLevelDD >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ApplicationSettings/]+par_cURLApplicationLinkCode+[/">Application Settings</a>]
        l_cHtml += [</li>]
    endif
    // if oFcgi:p_nAccessLevelDD >= 7
    //     l_cHtml += [<li class="nav-item">]
    //         l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "VERSIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListVersions/]+par_cURLApplicationLinkCode+[/">Versions</a>]
    //     l_cHtml += [</li>]
    // endif
    if oFcgi:p_nAccessLevelDD >= 7

        with object l_oDB1
            :Table("94025849-b8ea-4c95-8859-29b65774c84e","Deployment")
            :Column("Count(*)","Total")
            :Where("Deployment.fk_Application = ^" , par_iApplicationPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cApplicationElement == "DEPLOYMENTS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Applications/ListDeployments/]+par_cURLApplicationLinkCode+[/">Deployments (]+Trans(l_iReccount)+[)</a>]
        l_cHtml += [</li>]
    endif
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ApplicationInfoFormBuild(par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cName              := hb_HGetDef(par_hValues,"Name","")
local l_cLinkCode          := hb_HGetDef(par_hValues,"LinkCode","")
local l_nUseStatus         := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus         := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription       := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_nDestructiveDelete := hb_HGetDef(par_hValues,"DestructiveDelete",APPLICATIONDESTRUCTIVEDELETE_NONE)

oFcgi:TraceAdd("ApplicationInfoFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"disabled></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Link Code</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLinkCode" id="TextLinkCode" value="]+FcgiPrepFieldForValue(l_cLinkCode)+[" maxlength="20" size="20" style="text-transform: uppercase;" disabled></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" disabled>]
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
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDocStatus" id="ComboDocStatus" disabled>]
                    l_cHtml += [<option value="1"]+iif(l_nDocStatus==1,[ selected],[])+[>Missing</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDocStatus==2,[ selected],[])+[>Not Needed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDocStatus==3,[ selected],[])+[>Composing</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDocStatus==4,[ selected],[])+[>Completed</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80" disabled>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td class="pe-2 pb-3">Destructive Deletes</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDestructiveDelete" id="ComboDestructiveDelete" disabled>]
                    l_cHtml += [<option value="1"]+iif(l_nDestructiveDelete==1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDestructiveDelete==2,[ selected],[])+[>On Tables/Tags</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDestructiveDelete==3,[ selected],[])+[>On NameSpaces</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDestructiveDelete==4,[ selected],[])+[>Entire Application Content (Needed to PURGE)</option>]
                    l_cHtml += [<option value="5"]+iif(l_nDestructiveDelete==5,[ selected],[])+[>Can Delete Application</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        if !empty(par_iPk)
            l_cHtml += CustomFieldsBuild(par_iPk,USEDON_APPLICATION,par_iPk,par_hValues,[disabled])
        endif

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
// oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ApplicationListFormBuild()
local l_cHtml := []
local l_oDB_ListOfApplications      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCustomFieldValues := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTableCounts       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfApplications
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nCount

oFcgi:TraceAdd("ApplicationListFormBuild")

with object l_oDB_ListOfApplications
    :Table("70a13bfd-f9b0-4c36-a8d7-af8ed062d781","Application")
    :Column("Application.pk"               ,"pk")
    :Column("Application.Name"             ,"Application_Name")
    :Column("Application.LinkCode"         ,"Application_LinkCode")
    :Column("Application.UseStatus"        ,"Application_UseStatus")
    :Column("Application.DocStatus"        ,"Application_DocStatus")
    :Column("Application.Description"      ,"Application_Description")
    :Column("Application.DestructiveDelete","Application_DestructiveDelete")
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
    with object l_oDB_ListOfCustomFieldValues
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
        :Column("upper(CustomField.Name)"     ,"tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Application.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_APPLICATION)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

with object l_oDB_ListOfTableCounts
    :Table("9ba4289c-c846-4a4f-aec5-81d08072866a","Application")
    :Column("Application.pk" ,"Application_pk")
    :Column("Count(*)" ,"TableCount")
    :Join("inner","NameSpace","","NameSpace.fk_Application = Application.pk")
    :Join("inner","Table"    ,"","Table.fk_NameSpace = NameSpace.pk")
    :GroupBy("Application_pk")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :SQL("ListOfTableCounts")
    with object :p_oCursor
        :Index("tag1","Application_pk")
        :CreateIndexes()
    endwith
endwith


l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfApplications)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Application on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"7","8")+[">Applications (]+Trans(l_nNumberOfApplications)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Link Code</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Tables</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Destructive<br>Deletes</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfApplications
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfApplications->Application_UseStatus)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            // l_cHtml += [<a href="]+l_cSitePath+[Applications/ApplicationSettings/]+AllTrim(ListOfApplications->Application_LinkCode)+[/">]+Allt(ListOfApplications->Application_Name)+[</a>]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/ApplicationInfo/]+AllTrim(ListOfApplications->Application_LinkCode)+[/">]+Allt(ListOfApplications->Application_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += Allt(ListOfApplications->Application_LinkCode)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfApplications->Application_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            l_nCount := iif( VFP_Seek(ListOfApplications->pk,"ListOfTableCounts","tag1") , ListOfTableCounts->TableCount , 0)
                            if !empty(l_nCount)
                                l_cHtml += Trans(l_nCount)
                            endif
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfApplications->Application_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfApplications->Application_UseStatus,USESTATUS_UNKNOWN)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not Needed","Composing","Completed"}[iif(vfp_between(ListOfApplications->Application_DocStatus,DOCTATUS_MISSING,DOCTATUS_COMPLETE),ListOfApplications->Application_DocStatus,DOCTATUS_MISSING)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"None","On Tables/Tags","On NameSpaces","Entire Application Content","Can Delete Application"}[iif(vfp_between(ListOfApplications->Application_DestructiveDelete,APPLICATIONDESTRUCTIVEDELETE_NONE,APPLICATIONDESTRUCTIVEDELETE_CANDELETEAPPLICATION),ListOfApplications->Application_DestructiveDelete,APPLICATIONDESTRUCTIVEDELETE_NONE)]
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
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cName              := hb_HGetDef(par_hValues,"Name","")
local l_cLinkCode          := hb_HGetDef(par_hValues,"LinkCode","")
local l_nUseStatus         := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_nDocStatus         := hb_HGetDef(par_hValues,"DocStatus",DOCTATUS_MISSING)
local l_cDescription       := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_nDestructiveDelete := hb_HGetDef(par_hValues,"DestructiveDelete",APPLICATIONDESTRUCTIVEDELETE_NONE)

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
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmPurgeModal">Purge All Content (Keep Access Rights)</button>]
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
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
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLinkCode" id="TextLinkCode" value="]+FcgiPrepFieldForValue(l_cLinkCode)+[" maxlength="20" size="20" style="text-transform: uppercase;"></td>]
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

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td class="pe-2 pb-3">Destructive Deletes</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDestructiveDelete" id="ComboDestructiveDelete">]
                    l_cHtml += [<option value="1"]+iif(l_nDestructiveDelete==1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDestructiveDelete==2,[ selected],[])+[>On Tables/Tags</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDestructiveDelete==3,[ selected],[])+[>On NameSpaces</option>]
                    l_cHtml += [<option value="4"]+iif(l_nDestructiveDelete==4,[ selected],[])+[>Entire Application Content (Needed to PURGE)</option>]
                    l_cHtml += [<option value="5"]+iif(l_nDestructiveDelete==5,[ selected],[])+[>Can Delete Application</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        if !empty(par_iPk)
            l_cHtml += CustomFieldsBuild(par_iPk,USEDON_APPLICATION,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelDD >= 5,[],[disabled]))
        endif

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()
l_cHtml += GetConfirmationModalFormsPurge()

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
local l_nApplicationDestructiveDelete

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("ApplicationEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationPk                := Val(oFcgi:GetInputValue("TableKey"))
l_cApplicationName              := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cApplicationLinkCode          := Upper(SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextLinkCode")))
l_nApplicationUseStatus         := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_nApplicationDocStatus         := Val(oFcgi:GetInputValue("ComboDocStatus"))
l_cApplicationDescription       := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_nApplicationDestructiveDelete := Val(oFcgi:GetInputValue("ComboDestructiveDelete"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 7
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
                        :Field("Application.Name"              , l_cApplicationName)
                        :Field("Application.LinkCode"          , l_cApplicationLinkCode)
                        :Field("Application.UseStatus"         , l_nApplicationUseStatus)
                        :Field("Application.DocStatus"         , l_nApplicationDocStatus)
                        :Field("Application.Description"       , iif(empty(l_cApplicationDescription),NULL,l_cApplicationDescription))
                        :Field("Application.DestructiveDelete" , l_nApplicationDestructiveDelete)
                                                
                        if empty(l_iApplicationPk)
                            if :Add()
                                l_iApplicationPk := :Key()
                                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ApplicationInfo/"+l_cApplicationLinkCode+"/")
                            else
                                l_cErrorMessage := "Failed to add Application."
                            endif
                        else
                            if :Update(l_iApplicationPk)
                                CustomFieldsSave(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk)
                                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ApplicationInfo/"+l_cApplicationLinkCode+"/")
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
        oFcgi:Redirect(oFcgi:p_cSitePath+"Applications")
    else
        oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ApplicationInfo/"+par_cURLApplicationLinkCode+"/")
    endif

case l_cActionOnSubmit == "Delete"   // Application
    if oFcgi:p_nUserAccessMode >= 3
        if CheckIfAllowDestructiveApplicationDelete(l_iApplicationPk)
            l_cErrorMessage := CascadeDeleteApplication(l_iApplicationPk,.f.)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

            with object l_oDB1
                :Table("f67dd895-a6c9-4082-81d4-19204bf153c8","NameSpace")
                :Where("NameSpace.fk_Application = ^",l_iApplicationPk)
                :SQL()
                if :Tally != 0
                    l_cErrorMessage := "Related Name Space record on file"
                else

                    :Table("72419462-2523-45a3-8f86-4cdca0da52c0","Deployment")
                    :Where("Deployment.fk_Application = ^",l_iApplicationPk)
                    :SQL()
                    if :Tally != 0
                        l_cErrorMessage := "Related Deployment record on file"
                    else

                        :Table("72419462-2523-45a3-8f86-4cdca0da52c1","UserSettingApplication")
                        :Where("UserSettingApplication.fk_Application = ^",l_iApplicationPk)
                        :SQL()
                        if :Tally != 0
                            l_cErrorMessage := "Related UserSettingApplication record on file"
                        else

                            :Table("72419462-2523-45a3-8f86-4cdca0da52c2","APITokenAccessApplication")
                            :Where("APITokenAccessApplication.fk_Application = ^",l_iApplicationPk)
                            :SQL()
                            if :Tally != 0
                                l_cErrorMessage := "Related APITokenAccessApplication record on file"
                            else

                                :Table("72419462-2523-45a3-8f86-4cdca0da52c2","TemplateTable")
                                :Where("TemplateTable.fk_Application = ^",l_iApplicationPk)
                                :SQL()
                                if :Tally != 0
                                    l_cErrorMessage := "Related TemplateTable record on file"
                                else

                                    :Table("72419462-2523-45a3-8f86-4cdca0da52c3","Tag")
                                    :Where("Tag.fk_Application = ^",l_iApplicationPk)
                                    :SQL()
                                    if :Tally != 0
                                        l_cErrorMessage := "Related Tag record on file"
                                    else

                                        //Don't Have to test on related Table or DiagramTables since deleting Table would remove DiagramTables records and NameSpaces can no be removed with Tables
                                        //But we may have some left over Table less diagrams. Remove them

//_M_123 Delete related UserSetting records
                                        :Table("49de7c69-9e71-4174-9fec-de21b79f0244","Diagram")
                                        :Column("UserSetting.pk" , "pk")
                                        :Where("Diagram.fk_Application = ^",l_iApplicationPk)
                                        :Join("inner","UserSetting","","UserSetting.fk_Diagram = Diagram.pk")
                                        :SQL("ListOfUserSettingRecordsToDelete")
                                        if :Tally > 0
                                            select ListOfUserSettingRecordsToDelete
                                            scan
                                                :Delete("5e0d131b-c60c-4c49-bddd-21addd4cac0b","UserSetting",ListOfUserSettingRecordsToDelete->pk)
                                            endscan
                                        endif

                                        :Table("49de7c69-9e71-4174-9fec-de21b79f0245","Diagram")
                                        :Column("Diagram.pk" , "pk")
                                        :Where("Diagram.fk_Application = ^",l_iApplicationPk)
                                        :SQL("ListOfDiagramRecordsToDelete")
                                        if :Tally >= 0
                                            if :Tally > 0
                                                select ListOfDiagramRecordsToDelete
                                                scan
                                                    :Delete("5e0d131b-c60c-4c49-bddd-21addd4cac0a","Diagram",ListOfDiagramRecordsToDelete->pk)
                                                endscan
                                            endif

                                            CustomFieldsDelete(l_iApplicationPk,USEDON_APPLICATION,l_iApplicationPk)
                                            :Delete("fe1f5393-2e12-436c-b1b0-924344efc1b9","Application",l_iApplicationPk)
                                        else
                                            l_cErrorMessage := "Failed to clear related DiagramTable records."
                                        endif

                                        oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/")
                                    endif
                                endif
                            endif
                        endif
                    endif
                endif
            endwith
        endif
    endif

case l_cActionOnSubmit == "Purge"   // Application
    if oFcgi:p_nUserAccessMode >= 3
        if CheckIfAllowDestructivePurgeApplication(l_iApplicationPk) .or. CheckIfAllowDestructiveApplicationDelete(l_iApplicationPk)
            l_cErrorMessage := CascadeDeleteApplication(l_iApplicationPk,.t.)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/")
            endif
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]              := l_cApplicationName
    l_hValues["LinkCode"]          := l_cApplicationLinkCode
    l_hValues["UseStatus"]         := l_nApplicationUseStatus
    l_hValues["DocStatus"]         := l_nApplicationDocStatus
    l_hValues["Description"]       := l_cApplicationDescription
    l_hValues["DestructiveDelete"] := l_nApplicationDestructiveDelete

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
function CascadeDeleteApplication(par_iApplicationPk,par_lPurgeOnly)

local l_oDB1                      := hb_SQLData(oFcgi:p_o_SQLConnection)  // Since executing a select at this level, may not pass l_oDB1 for reuse.
local l_oDB_ListOfRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cTableName
local l_cTableDescription

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
            //This will also delete all the tables, column, index, tags ...
            if !empty(l_cErrorMessage)
                exit
            endif
        endscan
    endif
    
    if empty(l_cErrorMessage)
        //Since TemplateTable+TemplateColumn are not NameSpace specific, delete the related TemplateColumn record, then we can delete the TemplateTable records
        :Table("7d901c55-377c-4899-bb9c-b4942eb910e3","TemplateTable")
        :Join("inner","TemplateColumn","","TemplateColumn.fk_TemplateTable = TemplateTable.pk")
        :Column("TemplateColumn.pk","pk")
        :Where("TemplateTable.fk_Application = ^" , par_iApplicationPk)
        :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete Application. Error 2."
        else
            select ListOfRecordsToDeleteInCascadeDeleteApplication
            scan all
                if !:Delete("ad507bad-d68b-41ce-b119-cb0174629aeb","TemplateColumn",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                    l_cErrorMessage := "Failed to delete Application. Error 3."
                    exit
                endif
            endscan
        endif
    endif

//_M_123 Delete related UserSetting records
    if empty(l_cErrorMessage)
        :Table("49de7c69-9e71-4174-9fec-de21b79f0243","Diagram")
        :Column("UserSetting.pk" , "pk")
        :Where("Diagram.fk_Application = ^",par_iApplicationPk)
        :Join("inner","UserSetting","","UserSetting.fk_Diagram = Diagram.pk")
        :SQL("ListOfRecordsToDeleteInCascadeDeleteApplication")
        if :Tally < 0
            l_cErrorMessage := "Failed to delete Application. Error 2."
        else
            select ListOfRecordsToDeleteInCascadeDeleteApplication
            scan
                if !:Delete("5e0d131b-c60c-4c49-bddd-21addd4cac0a","UserSetting",ListOfRecordsToDeleteInCascadeDeleteApplication->pk)
                    l_cErrorMessage := "Failed to delete Application. Error 3."
                    exit
                endif
            endscan
        endif
    endif

    if empty(l_cErrorMessage)
        //Due to the deleting all Deployment, only a few directly related tables need to be cleared
        // Deleted all directly related records
        with object l_oDB_ListOfRecordsToDelete
            for each l_cTableName,l_cTableDescription in {"Diagram" ,"ApplicationCustomField"   ,"Tag" ,"TemplateTable"  ,"UserAccessApplication"   ,"APITokenAccessApplication"   ,"UserSettingApplication"     ,"Deployment" },;
                                                         {"Diagrams","Application Custom Fields","Tags","Template Tables","User Access Application ","API Token Access Application","Last Diagrams Used by Users","Deployments"}
                if empty(l_cErrorMessage)
                    :Table("1c66ab49-1671-468b-b5e1-788e9b12e5b3",l_cTableName)
                    :Column(l_cTableName+".pk","pk")
                    :Where(l_cTableName+".fk_Application = ^",par_iApplicationPk)
                    :SQL("ListOfRecordsToDelete")
                    do case
                    case :Tally < 0
                        l_cErrorMessage := "Failed to query "+l_cTableName+"."
                    case :Tally > 0
                        select ListOfRecordsToDelete
                        scan all
                            if !:Delete("093c524f-478e-4460-9525-19c5703aba6f",l_cTableName,ListOfRecordsToDelete->pk)
                                l_cErrorMessage := "Failed to delete related record in "+l_cTableName+" ("+l_cTableDescription+")."
                                exit
                            endif
                        endscan
                    endcase
                else
                    exit
                endif

            endfor
        endwith
    endif

    if empty(l_cErrorMessage)
        CustomFieldsDelete(par_iApplicationPk,USEDON_APPLICATION,par_iApplicationPk)
        if !par_lPurgeOnly
            if !:Delete("535048f7-4dd6-4043-8bd5-278dd444ec7a","Application",par_iApplicationPk)
                l_cErrorMessage := "Failed to delete Application. Error 14."
            endif
        endif
    endif

endwith
return l_cErrorMessage
//=================================================================================================================




//=================================================================================================================
//=================================================================================================================
static function DeploymentListFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfDeployments

local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("DeploymentListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("78ba7e1c-581f-4f3e-b193-a7bf7a8c84e7","Deployment")
    :Column("Deployment.pk"                 ,"pk")
    :Column("Deployment.LinkUID"            ,"Deployment_LinkUID")
    :Column("Deployment.Name"               ,"Deployment_Name")
    :Column("Deployment.Status"             ,"Deployment_Status")
    :Column("Deployment.Description"        ,"Deployment_Description")

    :Column("Deployment.BackendType"        ,"Deployment_BackendType")
    :Column("Deployment.Server"             ,"Deployment_Server")
    :Column("Deployment.Port"               ,"Deployment_Port")
    :Column("Deployment.User"               ,"Deployment_User")
    :Column("Deployment.PasswordStorage"    ,"Deployment_PasswordStorage")
    :Column("Deployment.PasswordConfigKey"  ,"Deployment_PasswordConfigKey")
    :Column("Deployment.PasswordEnvVarName" ,"Deployment_PasswordEnvVarName")
    :Column("Deployment.Database"           ,"Deployment_Database")
    :Column("Deployment.NameSpaces"         ,"Deployment_NameSpaces")
    :Column("Deployment.SetForeignKey"      ,"Deployment_SetForeignKey")

    :Column("Upper(Deployment.Name)","tag1")
    :Where("Deployment.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :SQL("ListOfDeployments")
    l_nNumberOfDeployments := :Tally
endwith

if empty(l_nNumberOfDeployments)
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No Deployment on file for current application.</span>]
                l_cHtml += [<a class="btn btn-primary rounded" href="]+l_cSitePath+[Applications/NewDeployment/]+par_cURLApplicationLinkCode+[/">New Deployment</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif

else
    if oFcgi:p_nAccessLevelDD >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Applications/NewDeployment/]+par_cURLApplicationLinkCode+[/">New Deployment</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="11">Deployment (]+Trans(l_nNumberOfDeployments)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Status</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Server<br>Type</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Server<br>Address/IP</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Server<br>Port</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">User<br>Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Password<br>Mode</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Database</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Name Spaces</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Set Foreign Key</th>]
                l_cHtml += [</tr>]

                select ListOfDeployments
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorDeploymentStatus(recno(),ListOfDeployments->Deployment_Status)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Applications/EditDeployment/]+par_cURLApplicationLinkCode+[/]+ListOfDeployments->Deployment_LinkUID+[/">]+ListOfDeployments->Deployment_Name+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfDeployments->Deployment_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Active","On Hold"}[iif(vfp_between(ListOfDeployments->Deployment_Status,1,2),ListOfDeployments->Deployment_Status,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","MariaDB","MySQL","PostgreSQL","MSSQL"}[iif(vfp_between(ListOfDeployments->Deployment_BackendType,1,4),ListOfDeployments->Deployment_BackendType+1,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += nvl(ListOfDeployments->Deployment_Server,"")
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += iif(nvl(ListOfDeployments->Deployment_Port,0) <= 0,"",trans(ListOfDeployments->Deployment_Port))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += nvl(ListOfDeployments->Deployment_User,"")
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Encrypted","In config.txt:","In Environment Variable:","User is AWS iam account"}[iif(vfp_between(nvl(ListOfDeployments->Deployment_PasswordStorage,0),1,4),ListOfDeployments->Deployment_PasswordStorage+1,1)]

                            switch nvl(ListOfDeployments->Deployment_PasswordStorage,0)
                            case 2
                                l_cHtml += [ ]+nvl(ListOfDeployments->Deployment_PasswordConfigKey,"")
                                exit
                            case 3
                                l_cHtml += [ ]+nvl(ListOfDeployments->Deployment_PasswordEnvVarName,"")
                                exit
                            endswitch

                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += nvl(ListOfDeployments->Deployment_Database,"")
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += nvl(ListOfDeployments->Deployment_NameSpaces,"")
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Not","Foreign Key Restrictions","On p_&lt;TableName&gt;","On fk_&lt;TableName&gt;","On &lt;TableName&gt;_id"}[iif(vfp_between(nvl(ListOfDeployments->Deployment_SetForeignKey,0),1,5),ListOfDeployments->Deployment_SetForeignKey+1,1)]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function DeploymentEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName              := hb_HGetDef(par_hValues,"Name","")
local l_nStatus            := hb_HGetDef(par_hValues,"Status",1)
local l_cDescription       := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_nBackendType       := hb_HGetDef(par_hValues,"BackendType",0)
local l_cServer            := hb_HGetDef(par_hValues,"Server","")
local l_nPort              := hb_HGetDef(par_hValues,"Port",0)
local l_cUser              := hb_HGetDef(par_hValues,"User","")
local l_nPasswordStorage   := hb_HGetDef(par_hValues,"PasswordStorage",0)
local l_cPasswordConfigKey := hb_HGetDef(par_hValues,"PasswordConfigKey","")
local l_cPasswordEnvVarName:= hb_HGetDef(par_hValues,"PasswordEnvVarName","")
local l_cDatabase          := hb_HGetDef(par_hValues,"Database","")
local l_cNameSpaces        := hb_HGetDef(par_hValues,"NameSpaces","")
local l_nSetForeignKey     := hb_HGetDef(par_hValues,"SetForeignKey",0)

oFcgi:TraceAdd("DeploymentEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Deployment</span>]   //navbar-text
        if oFcgi:p_nAccessLevelDD >= 7
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelDD >= 7
                l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
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
        l_cHtml += [<td class="pe-2 pb-3">Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboStatus" id="ComboStatus">]
                l_cHtml += [<option value="1"]+iif(l_nStatus==1,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="2"]+iif(l_nStatus==2,[ selected],[])+[>On Hold</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Server Type</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboBackendType" id="ComboBackendType">]
                l_cHtml += [<option value="0"]+iif(l_nBackendType==0,[ selected],[])+[></option>]
                l_cHtml += [<option value="1"]+iif(l_nBackendType==1,[ selected],[])+[>MariaDB</option>]
                l_cHtml += [<option value="2"]+iif(l_nBackendType==2,[ selected],[])+[>MySQL</option>]
                l_cHtml += [<option value="3"]+iif(l_nBackendType==3,[ selected],[])+[>PostgreSQL</option>]
                l_cHtml += [<option value="4"]+iif(l_nBackendType==4,[ selected],[])+[>MSSQL</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Server Address/IP</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextServer" id="TextServer" value="]+FcgiPrepFieldForValue(l_cServer)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Port (If not default)</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextPort" id="TextPort" value="]+iif(empty(l_nPort),"",Trans(l_nPort))+[" maxlength="10" size="10"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">User Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextUser" id="TextUser" value="]+FcgiPrepFieldForValue(l_cUser)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Password</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<span class="pe-5">]
                    l_cHtml += [<select name="ComboPasswordStorage" id="ComboPasswordStorage" onchange=']+UPDATESAVEBUTTON_COMBOWITHONCHANGE+[OnChangePasswordStorage(this.value);'>]
                    l_cHtml += [<option value="0"]+iif(l_nPasswordStorage==0,[ selected],[])+[></option>]
                    l_cHtml += [<option value="1"]+iif(l_nPasswordStorage==1,[ selected],[])+[>Encrypted</option>]
                    l_cHtml += [<option value="2"]+iif(l_nPasswordStorage==2,[ selected],[])+[>In config.txt</option>]
                    l_cHtml += [<option value="3"]+iif(l_nPasswordStorage==3,[ selected],[])+[>In Environment Variable</option>]
                    l_cHtml += [<option value="4"]+iif(l_nPasswordStorage==4,[ selected],[])+[>User is AWS iam account</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanPasswordCrypt" style="display: none;">]
                    l_cHtml += [<span class="pe-1">New Password</span>]
                    l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="password" name="TextPasswordCrypt" id="TextPasswordCrypt" value="" size="20" maxlength="200">]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanPasswordConfigKey" style="display: none;">]
                    l_cHtml += [<span class="pe-1">Config Key</span>]
                    l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="text" name="TextPasswordConfigKey" id="TextPasswordConfigKey" value="]+FcgiPrepFieldForValue(l_cPasswordConfigKey)+[" size="20" maxlength="200">]
                l_cHtml += [</span>]

                l_cHtml += [<span class="pe-5" id="SpanPasswordEnvVarName" style="display: none;">]
                    l_cHtml += [<span class="pe-1">Environment Variable</span>]
                    l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="text" name="TextPasswordEnvVarName" id="TextPasswordEnvVarName" value="]+FcgiPrepFieldForValue(l_cPasswordEnvVarName)+[" size="20" maxlength="200">]
                l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        // l_cHtml += [<tr class="pb-5">]
        //     l_cHtml += [<td class="pe-2 pb-3">Password</td>]
        //     l_cHtml += [<td class="pb-3"><input type="password" name="TextPassword" id="TextPassword" value="]+FcgiPrepFieldForValue(l_cPassword)+[" maxlength="200" size="80"></td>]
        // l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Database</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextDatabase" id="TextDatabase" value="]+FcgiPrepFieldForValue(l_cDatabase)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name Spaces<small><br>("schema" in PostgreSQL)<br>(optional, "," separated)</small></td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextNameSpaces" id="TextNameSpaces" value="]+FcgiPrepFieldForValue(l_cNameSpaces)+[" maxlength="400" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Set Foreign Key</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboSetForeignKey" id="ComboSetForeignKey">]
                l_cHtml += [<option value="0"]+iif(l_nSetForeignKey==0,[ selected],[])+[></option>]
                l_cHtml += [<option value="1"]+iif(l_nSetForeignKey==1,[ selected],[])+[>Not</option>]
                l_cHtml += [<option value="2"]+iif(l_nSetForeignKey==2,[ selected],[])+[>Foreign Key Restrictions</option>]
                l_cHtml += [<option value="3"]+iif(l_nSetForeignKey==3,[ selected],[])+[>On p_&lt;TableName&gt;</option>]
                l_cHtml += [<option value="4"]+iif(l_nSetForeignKey==4,[ selected],[])+[>On fk_&lt;TableName&gt;</option>]
                l_cHtml += [<option value="5"]+iif(l_nSetForeignKey==5,[ selected],[])+[>On &lt;TableName&gt;_id</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]


    l_cHtml += [<script language="javascript">]
    l_cHtml += [function OnChangePasswordStorage(par_Value) {]
    
    // l_cHtml += [alert('value = '+par_Value);]

    l_cHtml += [switch(par_Value) {]
    l_cHtml += [  case '1':]
    l_cHtml += [  $('#SpanPasswordCrypt').show();]
    l_cHtml += [  $('#SpanPasswordConfigKey').hide();]
    l_cHtml += [  $('#SpanPasswordEnvVarName').hide();]
    l_cHtml += [    break;]
    l_cHtml += [  case '2':]
    l_cHtml += [  $('#SpanPasswordCrypt').hide();]
    l_cHtml += [  $('#SpanPasswordConfigKey').show();]
    l_cHtml += [  $('#SpanPasswordEnvVarName').hide();]
    l_cHtml += [    break;]
    l_cHtml += [  case '3':]
    l_cHtml += [  $('#SpanPasswordCrypt').hide();]
    l_cHtml += [  $('#SpanPasswordConfigKey').hide();]
    l_cHtml += [  $('#SpanPasswordEnvVarName').show();]
    l_cHtml += [    break;]
    l_cHtml += [  default:]
    l_cHtml += [  $('#SpanPasswordCrypt').hide();]
    l_cHtml += [  $('#SpanPasswordConfigKey').hide();]
    l_cHtml += [  $('#SpanPasswordEnvVarName').hide();]
    l_cHtml += [};]

    l_cHtml += [};]
    l_cHtml += [</script>] 
    oFcgi:p_cjQueryScript += [OnChangePasswordStorage($("#ComboPasswordStorage").val());]


l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function DeploymentEditFormOnSubmit(par_iApplicationPk,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit
local l_iDeploymentPk
local l_cDeploymentName
local l_iDeploymentStatus
local l_cDeploymentDescription
local l_nDeploymentBackendType
local l_cDeploymentServer
local l_nDeploymentPort
local l_cDeploymentUser
local l_cDeploymentDatabase
local l_cDeploymentNameSpaces
local l_nDeploymentSetForeignKey
local l_nDeploymentPasswordStorage
local l_cDeploymentPasswordCrypt
local l_cDeploymentPasswordConfigKey
local l_cDeploymentPasswordEnvVarName

local l_cLinkUID

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("DeploymentEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iDeploymentPk                 := Val(oFcgi:GetInputValue("TableKey"))
l_cDeploymentName               := alltrim(oFcgi:GetInputValue("TextName"))
l_iDeploymentStatus             := Val(oFcgi:GetInputValue("ComboStatus"))
l_cDeploymentDescription        := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_nDeploymentBackendType        := Val(oFcgi:GetInputValue("ComboBackendType"))
l_cDeploymentServer             := SanitizeInput(oFcgi:GetInputValue("TextServer"))
l_nDeploymentPort               := Val(oFcgi:GetInputValue("TextPort"))
l_cDeploymentUser               := SanitizeInput(oFcgi:GetInputValue("TextUser"))
l_nDeploymentPasswordStorage    := Val(oFcgi:GetInputValue("ComboPasswordStorage"))
l_cDeploymentDatabase           := SanitizeInput(oFcgi:GetInputValue("TextDatabase"))
l_cDeploymentNameSpaces         := SanitizeInputWithValidChars(oFcgi:GetInputValue("TextNameSpaces"),[,_01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ])
l_nDeploymentSetForeignKey      := Val(oFcgi:GetInputValue("ComboSetForeignKey"))
l_cDeploymentPasswordCrypt      := SanitizeInput(oFcgi:GetInputValue("TextPasswordCrypt"))
l_cDeploymentPasswordConfigKey  := SanitizeInput(oFcgi:GetInputValue("TextPasswordConfigKey"))
l_cDeploymentPasswordEnvVarName := SanitizeInput(oFcgi:GetInputValue("TextPasswordEnvVarName"))

// l_cDeploymentPasswordCrypt      := strtran(l_cDeploymentPasswordCrypt     ," ","")
// l_cDeploymentPasswordCrypt      := strtran(l_cDeploymentPasswordCrypt     ,"'","")
l_cDeploymentPasswordConfigKey  := strtran(l_cDeploymentPasswordConfigKey ," ","")
l_cDeploymentPasswordEnvVarName := strtran(l_cDeploymentPasswordEnvVarName," ","")

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelDD >= 7
        do case
        case empty(l_cDeploymentName)
            l_cErrorMessage := "Missing Name"
        case l_nDeploymentPasswordStorage == 1 .and. " " $ l_cDeploymentPasswordCrypt
            l_cErrorMessage := [Password may not include blanks]
        case l_nDeploymentPasswordStorage == 1 .and. "'" $ l_cDeploymentPasswordCrypt
            l_cErrorMessage := [Password may not include quotes]
        case l_nDeploymentPasswordStorage == 1 .and. '"' $ l_cDeploymentPasswordCrypt
            l_cErrorMessage := [Password may not include double quotes]
        case l_nDeploymentPasswordStorage == 1 .and. empty(oFcgi:GetAppConfig("DEPLOYMENT_CRYPT_KEY"))
            l_cErrorMessage := [Missing DEPLOYMENT_CRYPT_KEY entry on config.txt on web server.]
        endcase

        if empty(l_cErrorMessage)
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("08715c80-532b-4b45-b9a7-68a004c564cd","Deployment")
                :Where([lower(replace(Deployment.Name,' ','')) = ^],lower(StrTran(l_cDeploymentName," ","")))
                :Where([Deployment.fk_Application = ^],par_iApplicationPk)
                if l_iDeploymentPk > 0
                    :Where([Deployment.pk != ^],l_iDeploymentPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                //Save the Deployment
                with object l_oDB1
                    :Table("b73e9496-b5bb-41ed-a590-b3737919b850","Deployment")
                    :Field("Deployment.Name"               ,l_cDeploymentName)
                    :Field("Deployment.Status"             ,l_iDeploymentStatus)
                    :Field("Deployment.Description"        ,iif(empty(l_cDeploymentDescription)       ,NULL,l_cDeploymentDescription))
                    :Field("Deployment.BackendType"        ,iif(l_nDeploymentBackendType == 0         ,NULL,l_nDeploymentBackendType))
                    :Field("Deployment.Server"             ,iif(empty(l_cDeploymentServer)            ,NULL,l_cDeploymentServer))
                    :Field("Deployment.Port"               ,iif(l_nDeploymentPort == 0                ,NULL,l_nDeploymentPort))
                    :Field("Deployment.User"               ,iif(empty(l_cDeploymentUser)              ,NULL,l_cDeploymentUser))
                    :Field("Deployment.PasswordStorage"    ,iif(l_nDeploymentPasswordStorage == 0     ,NULL,l_nDeploymentPasswordStorage))
                    :Field("Deployment.PasswordConfigKey"  ,iif(empty(l_cDeploymentPasswordConfigKey) ,NULL,l_cDeploymentPasswordConfigKey))
                    :Field("Deployment.PasswordEnvVarName" ,iif(empty(l_cDeploymentPasswordEnvVarName),NULL,l_cDeploymentPasswordEnvVarName))
                    :Field("Deployment.Database"           ,iif(empty(l_cDeploymentDatabase)          ,NULL,l_cDeploymentDatabase))
                    :Field("Deployment.NameSpaces"         ,iif(empty(l_cDeploymentNameSpaces)        ,NULL,l_cDeploymentNameSpaces))
                    :Field("Deployment.SetForeignKey"      ,iif(l_nDeploymentSetForeignKey == 0       ,NULL,l_nDeploymentSetForeignKey))
                    if nvl(l_nDeploymentPasswordStorage,0) == 1 .and. !empty(nvl(l_cDeploymentPasswordCrypt,""))
                        :FieldExpression("Deployment.PasswordCrypt","pgp_sym_encrypt('"+l_cDeploymentPasswordCrypt+"','"+oFcgi:GetAppConfig("DEPLOYMENT_CRYPT_KEY")+"','compress-algo=0, cipher-algo=aes256')")
                    endif

                    if empty(l_iDeploymentPk)
                        l_cLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                        :Field("Deployment.fk_Application" , par_iApplicationPk)
                        :Field("Deployment.LinkUID"        , l_cLinkUID)
                        if :Add()
                            l_iDeploymentPk := :Key()
                        else
                            l_cErrorMessage := "Failed to add Deployment."
                        endif
                    else
                        if !:Update(l_iDeploymentPk)
                            l_cErrorMessage := "Failed to update Deployment."
                        endif
                        // SendToClipboard(:LastSQL())
                    endif

                endwith

                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ListDeployments/"+par_cURLApplicationLinkCode+"/")  //+l_cDeploymentName+"/"
            endif
        endif
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ListDeployments/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "Delete"   // Deployment
    if oFcgi:p_nAccessLevelDD >= 7
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            //Clear all related pointers in UserSettingApplication
            :Table("5971e8c9-769d-43f4-9168-7263e4541c06","public.UserSettingApplication")
            :Column("UserSettingApplication.pk" , "pk")
            :Where("UserSettingApplication.fk_Deployment = ^" , l_iDeploymentPk)
            :SQL("ListOfUserSettingApplication")
            if :Tally > 0
                select ListOfUserSettingApplication
                scan all
                    with object l_oDB2
                        :Table("8535fa71-ff0d-4a06-9a97-eb7886662e21","public.UserSettingApplication")
                        :Field("UserSettingApplication.fk_Deployment" , 0)
                        :Update(ListOfUserSettingApplication->pk)
                    endwith
                endscan
            endif

            if :Delete("08e836c0-5ee8-4732-b76f-a303a4c5bf91","Deployment",l_iDeploymentPk)
                oFcgi:Redirect(oFcgi:p_cSitePath+"Applications/ListDeployments/"+par_cURLApplicationLinkCode+"/")
            else
                l_cErrorMessage := "Unable to delete deployment."
            endif

        endwith
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Name"]               := l_cDeploymentName
    l_hValues["Status"]             := l_iDeploymentStatus
    l_hValues["Description"]        := l_cDeploymentDescription
    l_hValues["BackendType"]        := l_nDeploymentBackendType
    l_hValues["Server"]             := l_cDeploymentServer
    l_hValues["Port"]               := l_nDeploymentPort
    l_hValues["User"]               := l_cDeploymentUser
    l_hValues["PasswordStorage"]    := l_nDeploymentPasswordStorage
    l_hValues["PasswordConfigKey"]  := l_cDeploymentPasswordConfigKey
    l_hValues["PasswordEnvVarName"] := l_cDeploymentPasswordEnvVarName
    l_hValues["Database"]           := l_cDeploymentDatabase
    l_hValues["NameSpaces"]         := l_cDeploymentNameSpaces
    l_hValues["SetForeignKey"]      := l_nDeploymentSetForeignKey

    l_cHtml += DeploymentEditFormBuild(par_iApplicationPk,par_cURLApplicationLinkCode,l_cErrorMessage,l_iDeploymentPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
