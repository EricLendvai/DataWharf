#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageAPITokens()
local l_cHtml := []
local l_oDB_ListOfSelectedApplications
local l_oDB_ListOfSelectedProjects
local l_oDB_ListOfSelectedAPITokens
local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iAPITokenPk
local l_cAPITokenName
local l_cAPITokenKey
local l_iAPITokenStatus
local l_cAPITokenDescription

local l_hValues := {=>}

local l_aSQLResult := {}

local l_cURLAction          := "ListAPITokens"
local l_cURLAPITokenUID := ""

local l_cSitePath := oFcgi:p_cSitePath

oFcgi:TraceAdd("BuildPageAPITokens")

// Variables
// l_cURLAction
// l_cURLAPITokenUID

//Improved and new way:
// APITokens/                      Same as APITokens/ListAPITokens/
// APITokens/NewAPIToken/

if len(oFcgi:p_aURLPathElements) >= 2 .and. !empty(oFcgi:p_aURLPathElements[2])
    l_cURLAction := oFcgi:p_aURLPathElements[2]

    if len(oFcgi:p_aURLPathElements) >= 3 .and. !empty(oFcgi:p_aURLPathElements[3])
        l_cURLAPITokenUID := oFcgi:p_aURLPathElements[3]
    endif

else
    l_cURLAction := "ListAPITokens"
endif

do case
case l_cURLAction == "ListAPITokens"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[APITokens/">APITokens</a>]
            l_cHtml += [<a class="btn btn-primary rounded" ms-0 href="]+l_cSitePath+[APITokens/NewAPIToken">New APIToken</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += APITokenListFormBuild()

case l_cURLAction == "NewAPIToken"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage APITokens</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()
        //Brand new request of add an APIToken.
        l_cHtml += APITokenEditFormBuild(0,"",{=>})
    else
        l_cHtml += APITokenEditFormOnSubmit()
    endif

case l_cURLAction == "EditAPIToken"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage APITokens</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()

        if !empty(l_cURLAPITokenUID)

            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("b5a14bed-b62c-41ed-9a2c-044e2ac54586","APIToken")
                :Column("APIToken.pk"         ,"pk")                    // 1
                :Column("APIToken.UID"    ,"APIToken_UID")      // 2
                :Column("APIToken.Name"       ,"APIToken_Name")         // 3
                :Column("APIToken.Key"        ,"APIToken_Key")          // 4
                :Column("APIToken.AccessMode" ,"APIToken_AccessMode")   // 5
                :Column("APIToken.Status"     ,"APIToken_Status")       // 6
                :Column("APIToken.Description","APIToken_Description")  // 7
                :Where("APIToken.UID = ^" ,l_cURLAPITokenUID)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally == 1
                l_iAPITokenPk := l_aSQLResult[1,1]

                l_hValues["UID"]     := l_aSQLResult[1,2]
                l_hValues["Name"]        := l_aSQLResult[1,3]
                l_hValues["Key"]         := l_aSQLResult[1,4]
                l_hValues["AccessMode"]  := l_aSQLResult[1,5]
                l_hValues["Status"]      := l_aSQLResult[1,6]
                l_hValues["Description"] := l_aSQLResult[1,7]

                l_oDB_ListOfSelectedApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfSelectedApplications
                    :Table("de5610ba-710a-4ecf-b407-9e251c68eecb","APITokenAccessApplication")
                    :Column("APITokenAccessApplication.fk_Application","fk_Application")
                    :Column("APITokenAccessApplication.AccessLevelDD" ,"AccessLevelDD")
                    :Where("APITokenAccessApplication.fk_APIToken = ^",l_iAPITokenPk)
                    :SQL("ListOfSelectedApplications")
                    select ListOfSelectedApplications
                    scan all
                        l_hValues["Application"+Trans(ListOfSelectedApplications->fk_Application)] := ListOfSelectedApplications->AccessLevelDD
                    endscan
                endwith

                l_oDB_ListOfSelectedProjects := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfSelectedProjects
                    :Table("063dff7c-4989-4d34-a249-d1229ae4e0ca","APITokenAccessProject")
                    :Column("APITokenAccessProject.fk_Project","fk_Project")
                    :Column("APITokenAccessProject.AccessLevelML" ,"AccessLevelML")
                    :Where("APITokenAccessProject.fk_APIToken = ^",l_iAPITokenPk)
                    :SQL("ListOfSelectedProjects")
                    select ListOfSelectedProjects
                    scan all
                        l_hValues["Project"+Trans(ListOfSelectedProjects->fk_Project)] := ListOfSelectedProjects->AccessLevelML
                    endscan
                endwith

                l_oDB_ListOfSelectedAPITokens := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfSelectedAPITokens
                    :Table("a08a88f9-0784-47e5-b18d-ac0d0287b48c","APIEndpoint")
                    :Column("APIEndpoint.pk","pk")
                    :Column("APIAccessEndpoint.pk","APIAccessEndpoint_pk")
                    :Join("left","APIAccessEndpoint","","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk and APIAccessEndpoint.fk_APIToken = ^",l_iAPITokenPk)
                    :SQL("ListOfSelectedAPITokens")
                    select ListOfSelectedAPITokens
                    scan all
                        l_hValues["APIEndpoint"+Trans(ListOfSelectedAPITokens->pk)] := (nvl(ListOfSelectedAPITokens->APIAccessEndpoint_pk,0) > 0)
                    endscan
                endwith

                l_cHtml += APITokenEditFormBuild(l_iAPITokenPk,"",l_hValues)

            else
                l_cHtml += [<div>Failed to find APIToken.</div>]
            endif
        endif

    else
        l_cHtml += APITokenEditFormOnSubmit()
    endif

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function APITokenListFormBuild()
local l_cHtml := []
local l_oDB_ListOfAPITokens         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfProjectAccess     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfApplicationAccess := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAPIAccessEndpoint := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfAPITokens
local l_iAPITokenPk

oFcgi:TraceAdd("APITokenListFormBuild")

with object l_oDB_ListOfAPITokens
    :Table("c5e6ecfc-2a8a-4d48-817c-666d8c990269","APIToken")
    :Column("APIToken.pk"         ,"pk")
    :Column("APIToken.UID"    ,"APIToken_UID")
    :Column("APIToken.Name"       ,"APIToken_Name")
    :Column("APIToken.Key"        ,"APIToken_Key")
    :Column("APIToken.AccessMode" ,"APIToken_AccessMode")
    :Column("APIToken.Description","APIToken_Description")
    :Column("APIToken.Status"     ,"APIToken_Status")
    :Column("Upper(APIToken.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAPITokens")
    l_nNumberOfAPITokens := :Tally
endwith

with object l_oDB_ListOfProjectAccess
    :Table("c194795a-b66a-4ec7-98fd-29efddcd5c9c","APIToken")
    :Column("APIToken.pk"                         , "APIToken_Pk")
    :Column("Project.Name"                        , "Project_Name")
    :Column("APITokenAccessProject.AccessLevelML" , "AccessLevel")
    :Column("upper(Project.Name)"                 , "tag1")
    :Join("inner","APITokenAccessProject","","APITokenAccessProject.fk_APIToken = APIToken.pk")
    :Join("inner","Project"              ,"","APITokenAccessProject.fk_Project = Project.pk")
    :OrderBy("APIToken_Pk")
    :OrderBy("tag1")
    :SQL("ListOfProjectAccess")

    with object :p_oCursor
        :Index("APIToken_Pk","APIToken_Pk")
        :CreateIndexes()
        :SetOrder("APIToken_Pk")
    endwith
endwith

with object l_oDB_ListOfApplicationAccess
    :Table("081f2056-09ca-43af-ab0d-3349a8654183","APIToken")
    :Column("APIToken.pk"                             , "APIToken_Pk")
    :Column("Application.Name"                        , "Application_Name")
    :Column("APITokenAccessApplication.AccessLevelDD" , "AccessLevel")
    :Column("upper(Application.Name)"                 , "tag1")
    :Join("inner","APITokenAccessApplication","","APITokenAccessApplication.fk_APIToken = APIToken.pk")
    :Join("inner","Application"              ,"","APITokenAccessApplication.fk_Application = Application.pk")
    :OrderBy("APIToken_Pk")
    :OrderBy("tag1")
    :SQL("ListOfApplicationAccess")

    with object :p_oCursor
        :Index("APIToken_Pk","APIToken_Pk")
        :CreateIndexes()
        :SetOrder("APIToken_Pk")
    endwith
endwith

with object l_oDB_ListOfAPIAccessEndpoint
    :Table("081f2056-09ca-43af-ab0d-3349a8654184","APIToken")
    :Column("APIToken.pk"             , "APIToken_Pk")
    :Column("APIEndpoint.Name"        , "APIEndpoint_Name")
    :Column("upper(APIEndpoint.Name)" , "tag1")
    :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
    :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
    :OrderBy("APIToken_Pk")
    :OrderBy("tag1")
    :SQL("ListOfAPIAccessEndpoint")

    with object :p_oCursor
        :Index("APIToken_Pk","APIToken_Pk")
        :CreateIndexes()
        :SetOrder("APIToken_Pk")
    endwith
endwith
//_M_ display in grid
//Application  APIEndpoint
//APITokenAccessApplication  APIAccessEndpoint


l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfAPITokens)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No APIToken on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="7">APITokens (]+Trans(l_nNumberOfAPITokens)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name</th>]
                    l_cHtml += [<th class="text-white">Access Mode</th>]
                    l_cHtml += [<th class="text-white">Projects</th>]
                    l_cHtml += [<th class="text-white">Applications</th>]
                    l_cHtml += [<th class="text-white">API Endpoints</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Status</th>]
                l_cHtml += [</tr>]

                select ListOfAPITokens
                scan all
                    l_iAPITokenPk := ListOfAPITokens->pk

                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[APITokens/EditAPIToken/]+alltrim(ListOfAPITokens->APIToken_UID)+[/">]+alltrim(ListOfAPITokens->APIToken_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Project And Application Specific","All Projects and Applications Read Only","All Projects and Applications Full Access"}[iif(el_between(ListOfAPITokens->APIToken_AccessMode,1,3),ListOfAPITokens->APIToken_AccessMode,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">] //Projects
                            select ListOfProjectAccess
                            scan all for ListOfProjectAccess->APIToken_Pk == l_iAPITokenPk
                                l_cHtml += [<div>]+ListOfProjectAccess->Project_Name+[ - ]
                                    l_cHtml += {"None","Read Only","Update Description and Information Entries","Update Description and Information Entries and Diagrams","Update Anything"}[iif(el_between(ListOfProjectAccess->AccessLevel,1,5),ListOfProjectAccess->AccessLevel,1)]
                                l_cHtml += [</div>]
                            endscan
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">] //Applications
                            select ListOfApplicationAccess
                            scan all for ListOfApplicationAccess->APIToken_Pk == l_iAPITokenPk
                                l_cHtml += [<div>]+ListOfApplicationAccess->Application_Name+[ - ]
                                    l_cHtml += {"None","Read Only","Update Description and Information Entries","Update Description and Information Entries and Diagrams","Update Anything"}[iif(el_between(ListOfApplicationAccess->AccessLevel,1,5),ListOfApplicationAccess->AccessLevel,1)]
                                l_cHtml += [</div>]
                            endscan
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">] //API Endpoints
                            select ListOfAPIAccessEndpoint
                            scan all for ListOfAPIAccessEndpoint->APIToken_Pk == l_iAPITokenPk
                                l_cHtml += [<div>]+ListOfAPIAccessEndpoint->APIEndpoint_Name+[</div>]
                            endscan
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfAPITokens->APIToken_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Active","Inactive"}[iif(el_between(ListOfAPITokens->APIToken_Status,1,2),ListOfAPITokens->APIToken_Status,1)]
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
static function APITokenEditFormBuild(par_iPk,par_cErrorText,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_nAccessMode
local l_nStatus
local l_oDB_ListOfAllApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAllProjects     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAllAPIEndpoints := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cCheckBoxId
local l_lCheckBoxValue

local l_cObjectMLID
local l_cObjectDDID

local l_nAccessLevelML
local l_nAccessLevelDD

oFcgi:TraceAdd("APITokenEditFormBuild")

oFcgi:p_cjQueryScript += [$('#TextName').focus();]
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangeAccessMode(par_Value) {]

l_cHtml += [switch(par_Value) {]
    l_cHtml += [  case '1':]
    l_cHtml += [  $('#DivApplicationSecurity').show();]
    l_cHtml += [  $('#DivProjectSecurity').show();]
    l_cHtml += [    break;]
l_cHtml += [  default:]
    l_cHtml += [  $('#DivApplicationSecurity').hide();]
    l_cHtml += [  $('#DivProjectSecurity').hide();]
l_cHtml += [};]


l_cHtml += [};]
l_cHtml += [</script>] 
oFcgi:p_cjQueryScript += [OnChangeAccessMode($("#ComboAccessMode").val());]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New APIToken</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update APIToken</span>]   //navbar-text
        endif
        l_cHtml += GetButtonOnEditFormSave()
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            l_cHtml += GetButtonOnEditFormDelete()
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Name",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Key</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextKey" id="TextKey" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Key",""))+[" maxlength="100" size="80"></td>] // style="text-transform: uppercase;"
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Access Mode</td>]
            l_cHtml += [<td class="pb-3" valign="top" style="vertical-align: top; ">]

                l_cHtml += [<span class="pe-5">]
                    l_nAccessMode := hb_HGetDef(par_hValues,"AccessMode",1)
                    // l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboAccessMode" id="ComboAccessMode">]
                    l_cHtml += [<select name="ComboAccessMode" id="ComboAccessMode" onchange=']+UPDATE_ONCOMBOWITHONCHANGE_SAVEBUTTON+[OnChangeAccessMode(this.value);'>]
                        l_cHtml += [<option value="1"]+iif(l_nAccessMode==1,[ selected],[])+[>Project and Application Specific</option>]
                        l_cHtml += [<option value="2"]+iif(l_nAccessMode==2,[ selected],[])+[>All Projects and Applications Read Only</option>]
                        l_cHtml += [<option value="3"]+iif(l_nAccessMode==3,[ selected],[])+[>All Projects and Applications Full Access</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_nStatus := hb_HGetDef(par_hValues,"Status",1)
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboStatus" id="ComboStatus">]
                    l_cHtml += [<option value="1"]+iif(l_nStatus==1,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="2"]+iif(l_nStatus==2,[ selected],[])+[>Inactive</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(nvl(hb_HGetDef(par_hValues,"Description",NIL),""))+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

with Object l_oDB_ListOfAllApplications
    :Table("81f63230-ffe4-43d5-950f-27e4d728230e","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAllApplications")
endwith

with Object l_oDB_ListOfAllProjects
    :Table("be5a00c2-e10d-4bb7-bf1b-b3a1c3fc11cb","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAllProjects")
endwith

with Object l_oDB_ListOfAllAPIEndpoints
    :Table("be5a00c2-e10d-4bb7-bf1b-b3a1c3fc11cc","APIEndpoint")
    :Column("APIEndpoint.pk"         ,"pk")
    :Column("APIEndpoint.Name"       ,"APIEndpoint_Name")
    :Column("Upper(APIEndpoint.Name)","tag1")
    :OrderBy("tag1")
    :Where("APIEndpoint.status = 1")
    :SQL("ListOfAllAPIEndpoints")
endwith


// Projects -------------------------------------------------------------------------
l_cHtml += [<div id="DivProjectSecurity">]
    l_cHtml += [<table class="ms-4 table" style="width:auto;">]   // table-striped
        l_cHtml += [<tr class="table-dark">]
            l_cHtml += [<td class="pb-2">Projects</td>]
            l_cHtml += [<td class="pb-2">Access Rights</td>]
        l_cHtml += [</tr>]

        select ListOfAllProjects
        scan all
            l_cObjectDDID := "ComboProjectSecLevelML"+Trans(ListOfAllProjects->pk)

            l_nAccessLevelML := hb_HGetDef(par_hValues,"Project"+Trans(ListOfAllProjects->pk),1)

            l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]
                l_cHtml += [<td class="pb-2">]+ListOfAllProjects->Project_Name+[</td>]
                
                l_cHtml += [<td class="pb-2"><select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="]+l_cObjectDDID+[" id="]+l_cObjectDDID+[" class="ms-1">]
                    l_cHtml += [<option value="1"]+iif(l_nAccessLevelML == 1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nAccessLevelML == 2,[ selected],[])+[>Read Only</option>]
                    l_cHtml += [<option value="3"]+iif(l_nAccessLevelML == 3,[ selected],[])+[>Update Description and Information Entries</option>]
                    l_cHtml += [<option value="4"]+iif(l_nAccessLevelML == 4,[ selected],[])+[>Update Description and Information Entries and Diagrams</option>]
                    l_cHtml += [<option value="5"]+iif(l_nAccessLevelML == 5,[ selected],[])+[>Update Anything</option>]
                l_cHtml += [</select></td>]

            l_cHtml += [</td></tr>]
        endscan
    l_cHtml += [</table>]

l_cHtml += [</div>]


// Applications -------------------------------------------------------------------------
l_cHtml += [<div id="DivApplicationSecurity">]
    l_cHtml += [<div class="m-5"></div>]

    l_cHtml += [<table class="ms-4 table" style="width:auto;">]   // table-striped
        l_cHtml += [<tr class="table-dark">]
            l_cHtml += [<td class="pb-2">Applications</td>]
            l_cHtml += [<td class="pb-2">Access Rights</td>]
        l_cHtml += [</tr>]

        select ListOfAllApplications
        scan all
            l_cObjectDDID := "ComboApplicationSecLevelDD"+Trans(ListOfAllApplications->pk)

            l_nAccessLevelDD := hb_HGetDef(par_hValues,"Application"+Trans(ListOfAllApplications->pk),1)

            l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]
                l_cHtml += [<td class="pb-2">]+ListOfAllApplications->Application_Name+[</td>]
                
                l_cHtml += [<td class="pb-2"><select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="]+l_cObjectDDID+[" id="]+l_cObjectDDID+[" class="ms-1">]
                    l_cHtml += [<option value="1"]+iif(l_nAccessLevelDD == 1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nAccessLevelDD == 2,[ selected],[])+[>Read Only</option>]
                    l_cHtml += [<option value="3"]+iif(l_nAccessLevelDD == 3,[ selected],[])+[>Update Description and Information Entries</option>]
                    l_cHtml += [<option value="4"]+iif(l_nAccessLevelDD == 4,[ selected],[])+[>Update Description and Information Entries and Diagrams</option>]
                    l_cHtml += [<option value="5"]+iif(l_nAccessLevelDD == 5,[ selected],[])+[>Update Anything</option>]
                l_cHtml += [</select></td>]

            l_cHtml += [</td></tr>]
        endscan
    l_cHtml += [</table>]

l_cHtml += [</div>]


// APIEndpoints -------------------------------------------------------------------------
l_cHtml += [<div id="DivAPIEndpoints">]
    l_cHtml += [<div class="m-5"></div>]

    l_cHtml += [<table class="ms-4 table" style="width:auto;">]   // table-striped
        l_cHtml += [<tr class="table-dark">]
            l_cHtml += [<td class="pb-2"></td>]
            l_cHtml += [<td class="pb-2">API Endpoints</td>]
        l_cHtml += [</tr>]

        select ListOfAllAPIEndpoints
        scan all
            l_cCheckBoxId := "CheckAPIEndpoint"+Trans(ListOfAllAPIEndpoints->pk)
            
            l_lCheckBoxValue := hb_HGetDef(par_hValues,"APIEndpoint"+Trans(ListOfAllAPIEndpoints->pk),.f.)

            //_M_ Will need to check on hb_HGetDef(par_hValues,"APIEndpoint"+Trans(ListOfAllAPIEndpoints->pk),1)

            l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                l_cHtml += [<td class="pb-2">]
                    l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="]+l_cCheckBoxId+[" id="]+l_cCheckBoxId+[" value="1"]+;
                                iif( l_lCheckBoxValue ," checked","");   //_M_
                                +[ class="form-check-input">]
                l_cHtml += [</td>]

                l_cHtml += [<td class="pb-2"><label class="control-label" for="]+l_cCheckBoxId+[">]+ListOfAllAPIEndpoints->APIEndpoint_Name+[</label></td>]
                
            l_cHtml += [</td></tr>]
        endscan
    l_cHtml += [</table>]

l_cHtml += [</div>]


// -------------------------------------------------------------------------

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function APITokenEditFormOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit

local l_iAPITokenPk
local l_cAPITokenUID
local l_cAPITokenName
local l_cAPITokenKey
local l_iAPITokenAccessMode
local l_iAPITokenStatus
local l_cAPITokenDescription

local l_hValues := {=>}

local l_nAccessLevelML
local l_nAccessLevelDD
local l_lSelected

local l_cErrorMessage := ""

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_Delete := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfRelatedToDelete               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfRecordsToDelete               := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfCurrentApplicationForAPIToken := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCurrentProjectForAPIToken     := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfApplications                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfProjects                      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAPIEndpoints                  := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfCurrentAPIAccessEndpoint      := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cTableName
local l_cTableDescription
local l_oData

oFcgi:TraceAdd("APITokenEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iAPITokenPk          := Val(oFcgi:GetInputValue("TableKey"))
l_cAPITokenName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cAPITokenKey         := SanitizeInputWithValidChars(oFcgi:GetInputValue("TextKey"),[.@01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-])
l_iAPITokenAccessMode  := Val(oFcgi:GetInputValue("ComboAccessMode"))
l_iAPITokenStatus      := Val(oFcgi:GetInputValue("ComboStatus"))
l_cAPITokenDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"

    do case
    case empty(l_cAPITokenName)
        l_cErrorMessage := "Missing Name"
    case empty(l_cAPITokenKey)
        l_cErrorMessage := "Missing Key"
    otherwise
        with object l_oDB1
            :Table("9a448586-ef8a-4e32-bf20-e5ef7ed5d5aa","APIToken")
            :Where([upper(replace(APIToken.Key,' ','')) = ^],upper(l_cAPITokenKey))
            if l_iAPITokenPk > 0
                :Where([APIToken.pk != ^],l_iAPITokenPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Key"
        else
            //Save the APIToken
            with object l_oDB1
                :Table("38b228be-f8fd-4431-8513-33e772beda8c","APIToken")
                :Field("APIToken.Name"       ,l_cAPITokenName)
                :Field("APIToken.Key"        ,l_cAPITokenKey)
                :Field("APIToken.AccessMode" ,l_iAPITokenAccessMode)
                :Field("APIToken.Status"     ,l_iAPITokenStatus)
                :Field("APIToken.Description",iif(empty(l_cAPITokenDescription),NULL,l_cAPITokenDescription))
                if empty(l_iAPITokenPk)
                    :Field("APIToken.UID",oFcgi:p_o_SQLConnection:GetUUIDString())
                    if :Add()
                        l_iAPITokenPk := :Key()
                    else
                        l_cErrorMessage := "Failed to add APIToken."
                    endif
                else
                    if !:Update(l_iAPITokenPk)
                        l_cErrorMessage := "Failed to update APIToken."
                    endif
                endif


                //Update the list selected Applications -----------------------------------------------
                if empty(l_cErrorMessage)
                    with Object l_oDB_ListOfApplications
                        :Table("bb3e08af-fa8a-4d3c-8f00-edd9144f956e","Application")
                        :Column("Application.pk","pk")
                        :SQL("ListOfApplications")
                    endwith

                    //Get current list of APIToken Applications
                    with Object l_oDB_ListOfCurrentApplicationForAPIToken
                        :Table("05f3338b-53a3-4eb5-aabe-a347f21ed210","APITokenAccessApplication")
                        :Distinct(.t.)
                        :Column("Application.pk"                     ,"pk")
                        :Column("APITokenAccessApplication.pk"           ,"APITokenAccessApplication_pk")
                        :Column("APITokenAccessApplication.AccessLevelDD","APITokenAccessApplication_AccessLevelDD")
                        :Join("inner","Application","","APITokenAccessApplication.fk_Application = Application.pk")
                        :Where("APITokenAccessApplication.fk_APIToken = ^" , l_iAPITokenPk)
                        :SQL("ListOfCurrentApplicationForAPIToken")
                        with object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith
                    endwith

                    select ListOfApplications
                    scan all
                        l_nAccessLevelDD := max(1,val(oFcgi:GetInputValue("ComboApplicationSecLevelDD"+Trans(ListOfApplications->pk))))
                        if el_seek(ListOfApplications->pk,"ListOfCurrentApplicationForAPIToken","pk")
                            if l_nAccessLevelDD <= 1
                                // Remove the Application
                                with Object l_oDB1
                                    if !:Delete("3a72f1b0-7b6d-4da9-8bf7-91d8080c5ba7","APITokenAccessApplication",ListOfCurrentApplicationForAPIToken->APITokenAccessApplication_pk)
                                        l_cErrorMessage := "Failed to delete application access setting."
                                        exit
                                    endif
                                endwith
                            else
                                if ListOfCurrentApplicationForAPIToken->APITokenAccessApplication_AccessLevelDD <> l_nAccessLevelDD
                                    :Table("ef6e8d13-e02f-4e6c-b499-cceed76b42d2","APITokenAccessApplication")
                                    :Field("APITokenAccessApplication.AccessLevelDD",l_nAccessLevelDD)
                                    if !:Update(ListOfCurrentApplicationForAPIToken->APITokenAccessApplication_pk)
                                        l_cErrorMessage := "Failed to Update Application selection."
                                        exit
                                    endif
                                endif
                            endif
                        else
                            if l_nAccessLevelDD > 1
                                // Add the Application only if more than "None"
                                :Table("8f1897f9-1ae7-48ca-b59c-825c53a97342","APITokenAccessApplication")
                                :Field("APITokenAccessApplication.fk_Application",ListOfApplications->pk)
                                :Field("APITokenAccessApplication.fk_APIToken"   ,l_iAPITokenPk)
                                :Field("APITokenAccessApplication.AccessLevelDD" ,l_nAccessLevelDD)
                                if !:Add()
                                    l_cErrorMessage := "Failed to Save Application selection."
                                    exit
                                endif
                            endif
                        endif
                    endscan
                endif

                //Update the list selected Projects -----------------------------------------------
                if empty(l_cErrorMessage)
                    with Object l_oDB_ListOfProjects
                        :Table("a2375ede-3892-43a0-8b03-9b74eb806e5c","Project")
                        :Column("Project.pk","pk")
                        :SQL("ListOfProjects")
                    endwith

                    //Get current list of APIToken Projects
                    with Object l_oDB_ListOfCurrentProjectForAPIToken
                        :Table("429cb509-354c-4daa-b8c1-32de2a55458b","APITokenAccessProject")
                        :Distinct(.t.)
                        :Column("Project.pk"                         ,"pk")
                        :Column("APITokenAccessProject.pk"           ,"APITokenAccessProject_pk")
                        :Column("APITokenAccessProject.AccessLevelML","APITokenAccessProject_AccessLevelML")
                        :Join("inner","Project","","APITokenAccessProject.fk_Project = Project.pk")
                        :Where("APITokenAccessProject.fk_APIToken = ^" , l_iAPITokenPk)
                        :SQL("ListOfCurrentProjectForAPIToken")
                        with object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith
                    endwith

                    select ListOfProjects
                    scan all
                        l_nAccessLevelML := max(1,val(oFcgi:GetInputValue("ComboProjectSecLevelML"+Trans(ListOfProjects->pk))))
                        if el_seek(ListOfProjects->pk,"ListOfCurrentProjectForAPIToken","pk")
                            if l_nAccessLevelML <= 1
                                // Remove the Project
                                with Object l_oDB1
                                    if !:Delete("7ffef7e4-582c-4f30-a7d6-eb46011b963c","APITokenAccessProject",ListOfCurrentProjectForAPIToken->APITokenAccessProject_pk)
                                        l_cErrorMessage := "Failed to Save Project selection."
                                        exit
                                    endif
                                endwith
                            else
                                if ListOfCurrentProjectForAPIToken->APITokenAccessProject_AccessLevelML <> l_nAccessLevelML
                                    :Table("0654494e-9c70-4496-adbc-c9fc0102abe5","APITokenAccessProject")
                                    :Field("APITokenAccessProject.AccessLevelML",l_nAccessLevelML)
                                    if !:Update(ListOfCurrentProjectForAPIToken->APITokenAccessProject_pk)
                                        l_cErrorMessage := "Failed to Update Project selection."
                                        exit
                                    endif
                                endif
                            endif
                        else
                            if l_nAccessLevelML > 1
                                // Add the Project only if more than "None"
                                :Table("db510dd8-331c-4498-9d14-4e3b320a426a","APITokenAccessProject")
                                :Field("APITokenAccessProject.fk_Project"   ,ListOfProjects->pk)
                                :Field("APITokenAccessProject.fk_APIToken"      ,l_iAPITokenPk)
                                :Field("APITokenAccessProject.AccessLevelML",l_nAccessLevelML)
                                if !:Add()
                                    l_cErrorMessage := "Failed to Save Project selection."
                                    exit
                                endif
                            endif
                        endif
                    endscan
                endif

                //Update the list selected APIEndpoints -----------------------------------------------
                if empty(l_cErrorMessage)
                    with Object l_oDB_ListOfAPIEndpoints
                        :Table("b99bf003-acab-462d-a9e5-6dc6af9e655b","APIEndpoint")
                        :Column("APIEndpoint.pk","pk")
                        :SQL("ListOfAPIEndpoints")
                    endwith

                    //Get current list of APIToken APIEndpoints
                    with Object l_oDB_ListOfCurrentAPIAccessEndpoint
                        :Table("429cb509-354c-4daa-b8c1-32de2a55458c","APIAccessEndpoint")
                        :Distinct(.t.)
                        :Column("APIEndpoint.pk"       ,"pk")
                        :Column("APIAccessEndpoint.pk" ,"APIAccessEndpoint_pk")
                        :Join("inner","APIEndpoint","","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
                        :Where("APIAccessEndpoint.fk_APIToken = ^" , l_iAPITokenPk)
                        :SQL("ListOfCurrentAPIAccessEndpoint")
                        with object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith
                    endwith

                    select ListOfAPIEndpoints
                    scan all
                        l_lSelected := (oFcgi:GetInputValue("CheckAPIEndpoint"+Trans(ListOfAPIEndpoints->pk)) == "1")

                        if el_seek(ListOfAPIEndpoints->pk,"ListOfCurrentAPIAccessEndpoint","pk")
                            if !l_lSelected
                                // Remove the APIEndpoint
                                with Object l_oDB1
                                    if !:Delete("7ffef7e4-582c-4f30-a7d6-eb46011b963d","APIAccessEndpoint",ListOfCurrentAPIAccessEndpoint->APIAccessEndpoint_pk)
                                        l_cErrorMessage := "Failed to Save APIEndpoint selection."
                                        exit
                                    endif
                                endwith
                            endif
                        else
                            if l_lSelected
                                // Add the APIEndpoint only if more than "None"
                                :Table("db510dd8-331c-4498-9d14-4e3b320a426b","APIAccessEndpoint")
                                :Field("APIAccessEndpoint.fk_APIEndpoint" ,ListOfAPIEndpoints->pk)
                                :Field("APIAccessEndpoint.fk_APIToken"    ,l_iAPITokenPk)
                                if !:Add()
                                    l_cErrorMessage := "Failed to Save APIEndpoint selection."
                                    exit
                                endif
                            endif
                        endif
                    endscan
                endif

                //-----------------------------------------------

            endwith
        endif
    endcase

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iAPITokenPk := 0

case l_cActionOnSubmit == "Delete"   // APIToken
    // Run Test first if may delete the record
    with object l_oDB_ListOfRelatedToDelete
        if empty(l_cErrorMessage)
            :Table("49c80d3d-db3d-4afc-8822-32833164e408","APITokenAccessApplication")
            :Where("APITokenAccessApplication.fk_APIToken = ^",l_iAPITokenPk)
            :Where("APITokenAccessApplication.AccessLevelDD > 1")
            :Join("inner","Application","","APITokenAccessApplication.fk_Application = Application.pk")  // In case we had an orphan record, it can be ignored.
            :SQL()
            do case
            case :Tally < 0
                l_cErrorMessage := "Failed to query APITokenAccessApplication."
            case :Tally > 0
                l_cErrorMessage := "Related Application security setup records."
            endcase
        endif

        if empty(l_cErrorMessage)
            :Table("30fa0d1c-d893-4374-a414-1f07b34713f6","APITokenAccessProject")
            :Where("APITokenAccessProject.fk_APIToken = ^",l_iAPITokenPk)
            :Where("APITokenAccessProject.AccessLevelML > 1")
            :Join("inner","Project","","APITokenAccessProject.fk_Project = Project.pk")  // In case we had an orphan record, it can be ignored.
            :SQL()
            do case
            case :Tally < 0
                l_cErrorMessage := "Failed to query APITokenAccessProject."
            case :Tally > 0
                l_cErrorMessage := "Related Project security setup records."
            endcase
        endif
    endwith


    // Deleted all related records
    if empty(l_cErrorMessage)
        with object l_oDB_ListOfRecordsToDelete
            // for each l_cTableName,l_cTableDescription in {"APITokenAccessApplication"     ,"APITokenAccessProject" ,"APIAccessEndpoint"   },;
            //                                              {"Application security setup"    ,"Project security setup","API Access Endpoints"}
            for each l_cTableName,l_cTableDescription in {"APIAccessEndpoint"   },;
                                                         {"API Access Endpoints"}
                if empty(l_cErrorMessage)
                    :Table("3c3bdcb1-1eb0-43e0-af81-ea978e7eecf4",l_cTableName)
                    :Column(l_cTableName+".pk","pk")
                    :Where(l_cTableName+".fk_APIToken = ^",l_iAPITokenPk)
                    :SQL("ListOfRecordsToDelete")
                    do case
                    case :Tally < 0
                        l_cErrorMessage := "Failed to query "+l_cTableName+"."
                    case :Tally > 0
                        select ListOfRecordsToDelete
                        scan all
                            if !l_oDB_Delete:Delete("093c524f-478e-4460-9525-19c5703aba6e",l_cTableName,ListOfRecordsToDelete->pk)
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
        l_oDB_Delete:Delete("7fbbf356-f3db-463b-8c29-cb87d0377b8e","APIToken",l_iAPITokenPk)
        l_iAPITokenPk := 0
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]        := l_cAPITokenName
    l_hValues["Key"]         := l_cAPITokenKey
    l_hValues["AccessMode"]  := l_iAPITokenAccessMode
    l_hValues["Status"]      := l_iAPITokenStatus
    l_hValues["Description"] := l_cAPITokenDescription

    if !used("ListOfApplications")
        with Object l_oDB_ListOfApplications
            :Table("abfe4555-49cc-409d-a38b-ac61fe302a18","Application")
            :Column("Application.pk" ,"pk")
            :SQL("ListOfApplications")
        endwith
    endif
    select ListOfApplications
    scan all
        l_nAccessLevelDD := val(oFcgi:GetInputValue("ComboApplicationSecLevelDD"+Trans(ListOfApplications->pk)))
        if l_nAccessLevelDD > 1 // No need to store the none, since not having a selection will mean "None"
            l_hValues["Application"+Trans(ListOfApplications->pk)] := l_nAccessLevelDD
        endif
    endscan

    if !used("ListOfProjects")
        with Object l_oDB_ListOfProjects
            :Table("e34d0f7d-99ac-457f-9799-c5a31389aae2","Project")
            :Column("Project.pk" ,"pk")
            :SQL("ListOfProjects")
        endwith
    endif
    select ListOfProjects
    scan all
        l_nAccessLevelML := val(oFcgi:GetInputValue("ComboProjectSecLevelML"+Trans(ListOfProjects->pk)))
        if l_nAccessLevelML > 1 // No need to store the none, since not having a selection will mean "None"
            l_hValues["Project"+Trans(ListOfProjects->pk)] := l_nAccessLevelML
        endif
    endscan

    l_cHtml += APITokenEditFormBuild(l_iAPITokenPk,l_cErrorMessage,l_hValues)

case empty(l_iAPITokenPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"APITokens/")

otherwise
    with object l_oDB1
        :Table("4eb191cc-610f-41b2-9fb6-8b9933679dfc","APIToken")
        :Column("APIToken.UID","APIToken_UID")
        l_oData := :Get(l_iAPITokenPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"APITokens/EditAPIToken/"+alltrim(l_oData:APIToken_UID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"APITokens")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
