//Todo
// -finish initial page
// -Password Encryption  bcrypt 
// -User Access modes

#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageUsers()
local l_cHtml := []
local l_oDB_ListOfSelectedApplications
local l_oDB_ListOfSelectedProjects
local l_oDB1
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iUserPk
local l_cUserFirstName
local l_cUserLastName
local l_iUserStatus
local l_cUserDescription

local l_hValues := {=>}

local l_aSQLResult := {}

local l_cURLAction := "ListUsers"
local l_cURLUserID := ""

local l_cSitePath := oFcgi:p_cSitePath

oFcgi:TraceAdd("BuildPageUsers")

// Variables
// l_cURLAction
// l_cURLUserID

//Improved and new way:
// Users/                      Same as Users/ListUsers/
// Users/NewUser/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLUserID := oFcgi:p_URLPathElements[3]
    endif

else
    l_cURLAction := "ListUsers"
endif

do case
case l_cURLAction == "ListUsers"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[Users/">Users</a>]
            l_cHtml += [<a class="btn btn-primary rounded" ms-0 href="]+l_cSitePath+[Users/NewUser">New User</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += UserListFormBuild()

case l_cURLAction == "NewUser"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage Users</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()
        //Brand new request of add an User.
        l_cHtml += UserEditFormBuild(0,"",{=>})
    else
        l_cHtml += UserEditFormOnSubmit()
    endif

case l_cURLAction == "EditUser"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand text-white ms-3">Manage Users</span>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    
    if oFcgi:isGet()

        if !empty(l_cURLUserID)

            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("bc88409e-20b9-45ab-8241-a472b4f64507","User")
                :Column("User.pk"         ,"pk")                 // 1
                :Column("User.ID"         ,"User_ID")            // 2
                :Column("User.FirstName"  ,"User_FirstName")     // 3
                :Column("User.LastName"   ,"User_LastName")      // 4
                :Column("User.AccessMode" ,"User_AccessMode")    // 5
                :Column("User.Status"     ,"User_Status")        // 6
                :Column("User.Description","User_Description")   // 7
                :Where("User.ID = ^" ,l_cURLUserID)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally == 1
                l_iUserPk := l_aSQLResult[1,1]

                l_hValues["ID"]          := l_aSQLResult[1,2]
                l_hValues["FirstName"]   := l_aSQLResult[1,3]
                l_hValues["LastName"]    := l_aSQLResult[1,4]
                l_hValues["Password"]    := ""  // Will Not load a password. Only allowed to set one
                l_hValues["AccessMode"]  := l_aSQLResult[1,5]
                l_hValues["Status"]      := l_aSQLResult[1,6]
                l_hValues["Description"] := l_aSQLResult[1,7]

                l_oDB_ListOfSelectedApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfSelectedApplications
                    :Table("64841551-4f11-43cf-bfd8-b742150b8dc2","UserAccessApplication")
                    :Column("UserAccessApplication.fk_Application","fk_Application")
                    :Column("UserAccessApplication.AccessLevelDD" ,"AccessLevelDD")
                    :Where("UserAccessApplication.fk_User = ^",l_iUserPk)
                    :SQL("ListOfSelectedApplications")
                    select ListOfSelectedApplications
                    scan all
                        l_hValues["Application"+Trans(ListOfSelectedApplications->fk_Application)] := ListOfSelectedApplications->AccessLevelDD
                    endscan
                endwith

                l_oDB_ListOfSelectedProjects := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfSelectedProjects
                    :Table("64841551-4f11-43cf-bfd8-b742150b8dc3","UserAccessProject")
                    :Column("UserAccessProject.fk_Project","fk_Project")
                    :Column("UserAccessProject.AccessLevelML" ,"AccessLevelML")
                    :Where("UserAccessProject.fk_User = ^",l_iUserPk)
                    :SQL("ListOfSelectedProjects")
                    select ListOfSelectedProjects
                    scan all
                        l_hValues["Project"+Trans(ListOfSelectedProjects->fk_Project)] := ListOfSelectedProjects->AccessLevelML
                    endscan
                endwith

                l_cHtml += UserEditFormBuild(l_iUserPk,"",l_hValues)

            else
                l_cHtml += [<div>Failed to find User.</div>]
            endif
        endif

    else
        l_cHtml += UserEditFormOnSubmit()
    endif

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function UserListFormBuild()
local l_cHtml := []
local l_oDB_ListOfUsers             := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfProjectAccess     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfApplicationAccess := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfUsers
local l_iUserPk

oFcgi:TraceAdd("UserListFormBuild")

with object l_oDB_ListOfUsers
    :Table("e2bcec92-3db1-4fc3-9650-739bee1d5850","User")
    :Column("User.pk"         ,"pk")
    :Column("User.FirstName"  ,"User_FirstName")
    :Column("User.LastName"   ,"User_LastName")
    :Column("User.ID"         ,"User_ID")
    // :Column("User.Password"   ,"User_Password")
    :Column("User.AccessMode" ,"User_AccessMode")
    :Column("User.Description","User_Description")
    :Column("User.Status"     ,"User_Status")
    :Column("Upper(User.FirstName)","tag1")
    :Column("Upper(User.LastName)" ,"tag2")
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfUsers")
    l_nNumberOfUsers := :Tally
endwith

with object l_oDB_ListOfProjectAccess
    :Table("93f84319-c117-4182-ae76-ce67c3726032","User")
    :Column("User.pk"                         , "User_Pk")
    :Column("Project.Name"                    , "Project_Name")
    :Column("UserAccessProject.AccessLevelML" , "AccessLevel")
    :Column("upper(Project.Name)"             , "tag1")
    :Join("inner","UserAccessProject","","UserAccessProject.fk_User = User.pk")
    :Join("inner","Project"          ,"","UserAccessProject.fk_Project = Project.pk")
    :OrderBy("User_Pk")
    :OrderBy("tag1")
    :SQL("ListOfProjectAccess")

    with object :p_oCursor
        :Index("User_Pk","User_Pk")
        :CreateIndexes()
        :SetOrder("User_Pk")
    endwith
endwith

with object l_oDB_ListOfApplicationAccess
    :Table("3d303af1-8a81-4982-af6a-a5e7605b8124","User")
    :Column("User.pk"                             , "User_Pk")
    :Column("Application.Name"                    , "Application_Name")
    :Column("UserAccessApplication.AccessLevelDD" , "AccessLevel")
    :Column("upper(Application.Name)"             , "tag1")
    :Join("inner","UserAccessApplication","","UserAccessApplication.fk_User = User.pk")
    :Join("inner","Application"          ,"","UserAccessApplication.fk_Application = Application.pk")
    :OrderBy("User_Pk")
    :OrderBy("tag1")
    :SQL("ListOfApplicationAccess")

    with object :p_oCursor
        :Index("User_Pk","User_Pk")
        :CreateIndexes()
        :SetOrder("User_Pk")
    endwith
endwith



l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfUsers)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No User on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="7">Users (]+Trans(l_nNumberOfUsers)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">ID</th>]
                    // l_cHtml += [<th class="GridHeaderRowCells text-white">Password</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Access Mode</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Projects</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Applications</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Status</th>]
                l_cHtml += [</tr>]

                select ListOfUsers
                scan all
                    l_iUserPk := ListOfUsers->pk

                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Users/EditUser/]+AllTrim(ListOfUsers->User_ID)+[/">]+Allt(ListOfUsers->User_FirstName)+" "+Allt(ListOfUsers->User_LastName)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += AllTrim(ListOfUsers->User_ID)
                        l_cHtml += [</td>]

                        // l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        //     l_cHtml += AllTrim(ListOfUsers->User_Password)
                        // l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Project And Application Specific","All Projects and Applications Read Only","All Projects and Applications Full Access","Root Admin (User Control)"}[iif(vfp_between(ListOfUsers->User_AccessMode,1,4),ListOfUsers->User_AccessMode,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">] //Projects
                            select ListOfProjectAccess
                            scan all for ListOfProjectAccess->User_Pk == l_iUserPk
                                l_cHtml += [<div>]+ListOfProjectAccess->Project_Name+[ - ]
                                    l_cHtml += {"None","Read Only","Edit Description and Information Entries","Edit Description and Information Entries and Diagrams","Edit Anything","","Full Access"}[iif(vfp_between(ListOfProjectAccess->AccessLevel,1,7),ListOfProjectAccess->AccessLevel,1)]
                                l_cHtml += [</div>]
                            endscan
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">] //Applications
                            select ListOfApplicationAccess
                            scan all for ListOfApplicationAccess->User_Pk == l_iUserPk
                                l_cHtml += [<div>]+ListOfApplicationAccess->Application_Name+[ - ]
                                    l_cHtml += {"None","Read Only","Edit Description and Information Entries","Edit Description and Information Entries and Diagrams","Edit Anything and Import/Export","Edit Anything and Load Schema","Full Access"}[iif(vfp_between(ListOfApplicationAccess->AccessLevel,1,7),ListOfApplicationAccess->AccessLevel,1)]
                                l_cHtml += [</div>]
                            endscan
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfUsers->User_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"Active","Inactive"}[iif(vfp_between(ListOfUsers->User_Status,1,2),ListOfUsers->User_Status,1)]
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
static function UserEditFormBuild(par_iPk,par_cErrorText,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_nAccessMode
local l_nStatus
local l_oDB_ListOfAllApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAllProjects     := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_CheckBoxId

local l_cObjectMLID
local l_cObjectDDID

local l_nAccessLevelML
local l_nAccessLevelDD

oFcgi:TraceAdd("UserEditFormBuild")

oFcgi:p_cjQueryScript += [$('#TextFirstName').focus();]
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

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New User</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update User</span>]   //navbar-text
        endif
        l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">First Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextFirstName" id="TextFirstName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"FirstName",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Last Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLastName" id="TextLastName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"LastName",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">ID</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextID" id="TextID" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"ID",""))+[" maxlength="100" size="80"></td>] // style="text-transform: uppercase;"
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Password</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextPassword" id="TextPassword" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Password",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Access Mode</td>]
            l_cHtml += [<td class="pb-3" valign="top" style="vertical-align: top; ">]

                l_cHtml += [<span class="pe-5">]
                    l_nAccessMode := hb_HGetDef(par_hValues,"AccessMode",1)
                    // l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboAccessMode" id="ComboAccessMode">]
                    l_cHtml += [<select name="ComboAccessMode" id="ComboAccessMode" onchange=']+UPDATESAVEBUTTON_COMBOWITHONCHANGE+[OnChangeAccessMode(this.value);'>]
                        l_cHtml += [<option value="1"]+iif(l_nAccessMode==1,[ selected],[])+[>Project and Application Specific</option>]
                        l_cHtml += [<option value="2"]+iif(l_nAccessMode==2,[ selected],[])+[>All Projects and Applications Read Only</option>]
                        l_cHtml += [<option value="3"]+iif(l_nAccessMode==3,[ selected],[])+[>All Projects and Applications Full Access</option>]
                        l_cHtml += [<option value="4"]+iif(l_nAccessMode==4,[ selected],[])+[>Root Admin (User Control)</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_nStatus := hb_HGetDef(par_hValues,"Status",1)
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboStatus" id="ComboStatus">]
                    l_cHtml += [<option value="1"]+iif(l_nStatus==1,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="2"]+iif(l_nStatus==2,[ selected],[])+[>Inactive (Read Only)</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(nvl(hb_HGetDef(par_hValues,"Description",NIL),""))+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]

with Object l_oDB_ListOfAllApplications
    :Table("13ffc0a9-0997-4f09-af57-2fb218ab86a9","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAllApplications")
endwith

with Object l_oDB_ListOfAllProjects
    :Table("fa441f82-9c6c-4af7-b1a4-95d36628b2ad","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfAllProjects")
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
                
                l_cHtml += [<td class="pb-2"><select]+UPDATESAVEBUTTON+[ name="]+l_cObjectDDID+[" id="]+l_cObjectDDID+[" class="ms-1">]  // ]+UPDATESAVEBUTTON+[
                    l_cHtml += [<option value="1"]+iif(l_nAccessLevelML == 1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nAccessLevelML == 2,[ selected],[])+[>Read Only</option>]
                    // l_cHtml += [<option value="3"]+iif(l_nAccessLevelML == 3,[ selected],[])+[>Edit Description and Information Entries</option>]
                    // l_cHtml += [<option value="4"]+iif(l_nAccessLevelML == 4,[ selected],[])+[>Edit Description and Information Entries and Diagrams</option>]
                    l_cHtml += [<option value="5"]+iif(l_nAccessLevelML == 5,[ selected],[])+[>Edit Anything and Import/Export</option>]
                    // l_cHtml += [<option value="6"]+iif(l_nAccessLevelML == 6,[ selected],[])+[>Edit Anything and Load Schema</option>]
                    l_cHtml += [<option value="7"]+iif(l_nAccessLevelML == 7,[ selected],[])+[>Full Access</option>]
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
                
                l_cHtml += [<td class="pb-2"><select]+UPDATESAVEBUTTON+[ name="]+l_cObjectDDID+[" id="]+l_cObjectDDID+[" class="ms-1">]  // ]+UPDATESAVEBUTTON+[
                    l_cHtml += [<option value="1"]+iif(l_nAccessLevelDD == 1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nAccessLevelDD == 2,[ selected],[])+[>Read Only</option>]
                    l_cHtml += [<option value="3"]+iif(l_nAccessLevelDD == 3,[ selected],[])+[>Edit Description and Information Entries</option>]
                    l_cHtml += [<option value="4"]+iif(l_nAccessLevelDD == 4,[ selected],[])+[>Edit Description and Information Entries and Diagrams</option>]
                    l_cHtml += [<option value="5"]+iif(l_nAccessLevelDD == 5,[ selected],[])+[>Edit Anything and Import/Export</option>]
                    l_cHtml += [<option value="6"]+iif(l_nAccessLevelDD == 6,[ selected],[])+[>Edit Anything and Load Schema</option>]
                    l_cHtml += [<option value="7"]+iif(l_nAccessLevelDD == 7,[ selected],[])+[>Full Access</option>]
                l_cHtml += [</select></td>]

            l_cHtml += [</td></tr>]
        endscan
    l_cHtml += [</table>]

l_cHtml += [</div>]

// -------------------------------------------------------------------------

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function UserEditFormOnSubmit(par_nCurrentUserPk)
local l_cHtml := []
local l_cActionOnSubmit

local l_iUserPk
local l_cUserFirstName
local l_cUserLastName
local l_cUserID
local l_cUserPassword
local l_iUserAccessMode
local l_iUserStatus
local l_cUserDescription

local l_cSecuritySalt
local l_cSecurityDefaultPassword

local l_hValues := {=>}

local l_nAccessLevelML
local l_nAccessLevelDD

local l_cErrorMessage := ""

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_Delete := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfRelatedToDelete           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfRecordsToDelete           := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfCurrentApplicationForUser := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCurrentProjectForUser     := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDB_ListOfApplications              := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfProjects                  := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cTableName
local l_cTableDescription

oFcgi:TraceAdd("UserEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iUserPk          := Val(oFcgi:GetInputValue("TableKey"))
l_cUserFirstName   := SanitizeInput(oFcgi:GetInputValue("TextFirstName"))
l_cUserLastName    := SanitizeInput(oFcgi:GetInputValue("TextLastName"))
l_cUserID          := SanitizeInputWithValidChars(oFcgi:GetInputValue("TextID"),[.@01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-])
l_cUserPassword    := SanitizeInput(oFcgi:GetInputValue("TextPassword"))
l_iUserAccessMode  := Val(oFcgi:GetInputValue("ComboAccessMode"))
l_iUserStatus      := Val(oFcgi:GetInputValue("ComboStatus"))
l_cUserDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"

    do case
    case empty(l_cUserFirstName)
        l_cErrorMessage := "Missing First Name"
    case empty(l_cUserLastName)
        l_cErrorMessage := "Missing Last Name"
    case empty(l_cUserID)
        l_cErrorMessage := "Missing ID"
    otherwise
        with object l_oDB1
            :Table("85938e4d-553e-4e34-9d3e-0db1f42f6629","User")
            :Where([upper(replace(User.ID,' ','')) = ^],upper(l_cUserID))
            if l_iUserPk > 0
                :Where([User.pk != ^],l_iUserPk)
            endif
            :SQL()
        endwith

        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate ID"
        else
            //Save the User
            if empty(l_iUserPk) .or. !empty(l_cUserPassword)
                l_cSecuritySalt            := oFcgi:GetAppConfig("SECURITY_SALT")
                l_cSecurityDefaultPassword := oFcgi:GetAppConfig("SECURITY_DEFAULT_PASSWORD")
            endif

            with object l_oDB1
                :Table("7f641d75-0e44-49e7-aa3c-cf804e1b3cf9","User")
                :Field("User.FirstName",l_cUserFirstName)
                :Field("User.LastName" ,l_cUserLastName)
                :Field("User.ID"       ,l_cUserID)
                if l_iUserPk <> par_nCurrentUserPk  // May not change owns status or access mode (non admin user).
                    :Field("User.AccessMode",l_iUserAccessMode)
                    :Field("User.Status"    ,l_iUserStatus)
                endif
                :Field("User.Description",iif(empty(l_cUserDescription),NULL,l_cUserDescription))
                if empty(l_iUserPk)
                    if :Add()
                        l_iUserPk := :Key()

                        :Table("4650c039-a57b-4476-abf6-2d2806782c33","User")
                        :Field("User.Password",hb_SHA512(l_cSecuritySalt+iif(empty(l_cUserPassword),l_cSecurityDefaultPassword,l_cUserPassword)+Trans(l_iUserPk)))
                        :Update(l_iUserPk)

                    else
                        l_cErrorMessage := "Failed to add User."
                    endif
                else
                    if !empty(l_cUserPassword)
                        :Field("User.Password" , hb_SHA512(l_cSecuritySalt+l_cUserPassword+Trans(l_iUserPk)))
                    endif
                    if !:Update(l_iUserPk)
                        l_cErrorMessage := "Failed to update User."
                    endif
                endif


                //Update the list selected Applications -----------------------------------------------
                if empty(l_cErrorMessage)
                    with Object l_oDB_ListOfApplications
                        :Table("98477c5c-898b-4a3b-98ab-3429f8153e79","Application")
                        :Column("Application.pk","pk")
                        :SQL("ListOfApplications")
                    endwith

                    //Get current list of User Applications
                    with Object l_oDB_ListOfCurrentApplicationForUser
                        :Table("57992887-3dd6-4fad-b969-700820c5bd19","UserAccessApplication")
                        :Distinct(.t.)
                        :Column("Application.pk"                     ,"pk")
                        :Column("UserAccessApplication.pk"           ,"UserAccessApplication_pk")
                        :Column("UserAccessApplication.AccessLevelDD","UserAccessApplication_AccessLevelDD")
                        :Join("inner","Application","","UserAccessApplication.fk_Application = Application.pk")
                        :Where("UserAccessApplication.fk_User = ^" , l_iUserPk)
                        :SQL("ListOfCurrentApplicationForUser")
                        with object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith        
                    endwith

                    select ListOfApplications
                    scan all
                        l_nAccessLevelDD := max(1,val(oFcgi:GetInputValue("ComboApplicationSecLevelDD"+Trans(ListOfApplications->pk))))
                        if VFP_Seek(ListOfApplications->pk,"ListOfCurrentApplicationForUser","pk")
                            if l_nAccessLevelDD <= 1
                                // Remove the Application
                                with Object l_oDB1
                                    if !l_oDB1:Delete("3a72f1b0-7b6d-4da9-8bf7-91d8080c5ba7","UserAccessApplication",ListOfCurrentApplicationForUser->UserAccessApplication_pk)
                                        l_cErrorMessage := "Failed to Save Application selection."
                                        exit
                                    endif
                                endwith
                            else
                                if ListOfCurrentApplicationForUser->UserAccessApplication_AccessLevelDD <> l_nAccessLevelDD
                                    :Table("d6b0a424-ada8-4efd-a1e5-49821463d334","UserAccessApplication")
                                    :Field("UserAccessApplication.AccessLevelDD",l_nAccessLevelDD)
                                    if !:Update(ListOfCurrentApplicationForUser->UserAccessApplication_pk)
                                        l_cErrorMessage := "Failed to Update Application selection."
                                        exit
                                    endif
                                endif
                            endif
                        else
                            if l_nAccessLevelDD > 1
                                // Add the Application only if more than "None"
                                :Table("b9fe0a47-878e-4122-8c97-da45982e2554","UserAccessApplication")
                                :Field("UserAccessApplication.fk_Application",ListOfApplications->pk)
                                :Field("UserAccessApplication.fk_User"       ,l_iUserPk)
                                :Field("UserAccessApplication.AccessLevelDD" ,l_nAccessLevelDD)
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
                        :Table("2fb5a498-8834-4c79-9a30-c86db2acde0f","Project")
                        :Column("Project.pk","pk")
                        :SQL("ListOfProjects")
                    endwith

                    //Get current list of User Projects
                    with Object l_oDB_ListOfCurrentProjectForUser
                        :Table("22eededf-fa2e-4895-ae1c-820e9f7ae3dd","UserAccessProject")
                        :Distinct(.t.)
                        :Column("Project.pk"                     ,"pk")
                        :Column("UserAccessProject.pk"           ,"UserAccessProject_pk")
                        :Column("UserAccessProject.AccessLevelML","UserAccessProject_AccessLevelML")
                        :Join("inner","Project","","UserAccessProject.fk_Project = Project.pk")
                        :Where("UserAccessProject.fk_User = ^" , l_iUserPk)
                        :SQL("ListOfCurrentProjectForUser")
                        with object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith        
                    endwith

                    select ListOfProjects
                    scan all
                        l_nAccessLevelML := max(1,val(oFcgi:GetInputValue("ComboProjectSecLevelML"+Trans(ListOfProjects->pk))))
                        if VFP_Seek(ListOfProjects->pk,"ListOfCurrentProjectForUser","pk")
                            if l_nAccessLevelML <= 1
                                // Remove the Project
                                with Object l_oDB1
                                    if !:Delete("7ffef7e4-582c-4f30-a7d6-eb46011b963c","UserAccessProject",ListOfCurrentProjectForUser->UserAccessProject_pk)
                                        l_cErrorMessage := "Failed to Save Project selection."
                                        exit
                                    endif
                                endwith
                            else
                                if ListOfCurrentProjectForUser->UserAccessProject_AccessLevelML <> l_nAccessLevelML
                                    :Table("f3d240d2-1df5-4de0-b7e5-f4be79b5f7f5","UserAccessProject")
                                    :Field("UserAccessProject.AccessLevelML",l_nAccessLevelML)
                                    if !:Update(ListOfCurrentProjectForUser->UserAccessProject_pk)
                                        l_cErrorMessage := "Failed to Update Project selection."
                                        exit
                                    endif
                                endif
                            endif
                        else
                            if l_nAccessLevelML > 1
                                // Add the Project only if more than "None"
                                :Table("c4cfc066-0862-43dd-b07c-68948e9b49a3","UserAccessProject")
                                :Field("UserAccessProject.fk_Project"   ,ListOfProjects->pk)
                                :Field("UserAccessProject.fk_User"      ,l_iUserPk)
                                :Field("UserAccessProject.AccessLevelML",l_nAccessLevelML)
                                if !:Add()
                                    l_cErrorMessage := "Failed to Save Project selection."
                                    exit
                                endif
                            endif
                        endif
                    endscan
                endif

                //-----------------------------------------------

                if empty(l_cErrorMessage)
                    oFcgi:Redirect(oFcgi:p_cSitePath+"Users/ListUsers/")
                endif
            endwith
        endif
    endcase

case l_cActionOnSubmit == "Cancel"
    if empty(l_iUserPk)
        oFcgi:Redirect(oFcgi:p_cSitePath+"Users")
    else
        oFcgi:Redirect(oFcgi:p_cSitePath+"Users/ListUsers/")  // +par_cURLUserID+"/"
    endif

case l_cActionOnSubmit == "Delete"   // User
    if l_iUserPk == oFcgi:p_iUserPk
        l_cErrorMessage := "May not delete self."
    else
        // Run Test first if may delete the record
        with object l_oDB_ListOfRelatedToDelete
            if empty(l_cErrorMessage)
                :Table("098bbc02-bf72-4838-b2ed-c3305486d69f","UserAccessApplication")
                :Where("UserAccessApplication.fk_User = ^",l_iUserPk)
                :Where("UserAccessApplication.AccessLevelDD > 1")
                :Join("inner","Application","","UserAccessApplication.fk_Application = Application.pk")  // In case we had an orphan record, it can be ignored.
                :SQL()
                do case
                case :Tally < 0
                    l_cErrorMessage := "Failed to query UserAccessApplication."
                case :Tally > 0
                    l_cErrorMessage := "Related Application security setup records."
                endcase
            endif

            if empty(l_cErrorMessage)
                :Table("a1607f34-05e6-41c8-87b3-4e16aca9400f","UserAccessProject")
                :Where("UserAccessProject.fk_User = ^",l_iUserPk)
                :Where("UserAccessProject.AccessLevelML > 1")
                :Join("inner","Project","","UserAccessProject.fk_Project = Project.pk")  // In case we had an orphan record, it can be ignored.
                :SQL()
                do case
                case :Tally < 0
                    l_cErrorMessage := "Failed to query UserAccessProject."
                case :Tally > 0
                    l_cErrorMessage := "Related Project security setup records."
                endcase
            endif
        endwith


        // Deleted all related records
        if empty(l_cErrorMessage)
            with object l_oDB_ListOfRecordsToDelete
                // for each l_cTableName,l_cTableDescription in {"UserAccessApplication"     ,"UserAccessProject"     ,"LoginLogs" ,"UserSetting"  ,"UserSettingApplication","UserSettingModel"},;
                //                                              {"Application security setup","Project security setup","Login Logs","User Settings","Last Diagrams Used"    ,"Last Modeling Diagrams Used"}
                for each l_cTableName,l_cTableDescription in {"LoginLogs" ,"UserSetting"  ,"UserSettingApplication","UserSettingModel"},;
                                                             {"Login Logs","User Settings","Last Diagrams Used"    ,"Last Modeling Diagrams Used"}
                    if empty(l_cErrorMessage)
                        :Table("1c66ab49-1671-468b-b5e1-788e9b12e5b2",l_cTableName)
                        :Column(l_cTableName+".pk","pk")
                        :Where(l_cTableName+".fk_User = ^",l_iUserPk)
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
            l_oDB_Delete:Delete("7fbbf356-f3db-463b-8c29-cb87d0377b8e","User",l_iUserPk)
            oFcgi:Redirect(oFcgi:p_cSitePath+"Users/")
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["FirstName"]   := l_cUserFirstName
    l_hValues["LastName"]    := l_cUserLastName
    l_hValues["ID"]          := l_cUserID
    l_hValues["Password"]    := l_cUserPassword
    l_hValues["AccessMode"]  := l_iUserAccessMode
    l_hValues["Status"]      := l_iUserStatus
    l_hValues["Description"] := l_cUserDescription

    if !used("ListOfApplications")
        with Object l_oDB_ListOfApplications
            :Table("11ff420c-c516-4a77-8df5-c5223f6e0bf1","Application")
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
            :Table("f576f41c-dcc4-4cd6-932e-871c75e541cd","Project")
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

    l_cHtml += UserEditFormBuild(l_iUserPk,l_cErrorMessage,l_hValues)
endif

return l_cHtml
//=================================================================================================================
