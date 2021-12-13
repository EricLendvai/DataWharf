//Todo
// -finish initial page
// -Password Encryption  bcrypt 
// -User Access modes

#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageUsers(par_cUserName,par_nUserPk)
local l_cHtml := []
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

local l_cSitePath := oFcgi:RequestSettings["SitePath"]

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
                :Column("User.LastName"  ,"User_LastName")       // 4
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

                with object l_oDB1
                    :Table("64841551-4f11-43cf-bfd8-b742150b8dc2","UserAccessApplication")
                    :Column("UserAccessApplication.fk_Application","fk_Application")
                    :Where("UserAccessApplication.fk_User = ^",l_iUserPk)
                    :SQL("ListOfSelectedApplications")

                    select ListOfSelectedApplications
                    scan all
                        l_hValues["Application"+Trans(ListOfSelectedApplications->fk_Application)] := .t.
                    endscan
                endwith

                l_cHtml += UserEditFormBuild(l_iUserPk,"",l_hValues)

            else
                l_cHtml += [<div>Failed to find User.</div>]
            endif
        endif

    else
        l_cHtml += UserEditFormOnSubmit(par_nUserPk)
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
local l_oDB1
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfUsers

oFcgi:TraceAdd("UserListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
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
    :OrderBy("tag2")
    :OrderBy("tag1")
    :SQL("ListOfUsers")
    l_nNumberOfUsers := :Tally
endwith

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfUsers)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No User on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="5">Users (]+Trans(l_nNumberOfUsers)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">ID</th>]
                    // l_cHtml += [<th class="GridHeaderRowCells text-white">Password</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Access Mode</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Status</th>]
                l_cHtml += [</tr>]

                select ListOfUsers
                scan all
                    l_cHtml += [<tr>]

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
                            l_cHtml += {"Application Specific","All Application Read Only","All Application Admin","Root Admin (User Control)"}[iif(vfp_between(ListOfUsers->User_AccessMode,1,4),ListOfUsers->User_AccessMode,1)]
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
local l_iAccessMode
local l_iStatus
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_CheckBoxId

oFcgi:TraceAdd("UserEditFormBuild")

oFcgi:p_cjQueryScript += [$('#TextFirstName').focus();]
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [<script language="javascript">]
l_cHtml += [function OnChangeAccessMode(par_Value) {]
l_cHtml += [};]
l_cHtml += [</script>] 
oFcgi:p_cjQueryScript += [OnChangeAccessMode($("#ComboAccessMode").val());]

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
            l_cHtml += [<span class="navbar-brand ms-3">New User</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update User</span>]   //navbar-text
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
            l_cHtml += [<td class="pe-2 pb-3">First Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextFirstName" id="TextFirstName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"FirstName",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Last Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextLastName" id="TextLastName" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"LastName",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">ID</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextID" id="TextID" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"ID",""))+[" maxlength="20" size="20"></td>] // style="text-transform: uppercase;"
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Password</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextPassword" id="TextPassword" value="]+FcgiPrepFieldForValue(hb_HGetDef(par_hValues,"Password",""))+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Access Mode</td>]
            l_cHtml += [<td class="pb-3" valign="top" style="vertical-align: top; ">]

                l_cHtml += [<span class="pe-5">]
                    l_iAccessMode := hb_HGetDef(par_hValues,"AccessMode",1)
                    // l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboAccessMode" id="ComboAccessMode">]
                    l_cHtml += [<select name="ComboAccessMode" id="ComboAccessMode" onchange="OnChangeAccessMode(this.value);$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');">]
                        l_cHtml += [<option value="1"]+iif(l_iAccessMode==1,[ selected],[])+[>Application Specific</option>]
                        l_cHtml += [<option value="2"]+iif(l_iAccessMode==2,[ selected],[])+[>All Application Read Only</option>]
                        l_cHtml += [<option value="3"]+iif(l_iAccessMode==3,[ selected],[])+[>All Application Admin</option>]
                        l_cHtml += [<option value="4"]+iif(l_iAccessMode==4,[ selected],[])+[>Root Admin (User Control)</option>]
                    l_cHtml += [</select>]
                l_cHtml += [</span>]


            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_iStatus := hb_HGetDef(par_hValues,"Status",1)
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboStatus" id="ComboStatus">]
                    l_cHtml += [<option value="1"]+iif(l_iStatus==1,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="2"]+iif(l_iStatus==2,[ selected],[])+[>Inactive (Read Only)</option>]
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
    :Table("13ffc0a9-0997-4f09-af57-2fb218ab86a9","Application")
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

local l_lSelected

local l_cErrorMessage := ""
local l_oDB1
local l_oDB2
local l_oDB3

oFcgi:TraceAdd("UserEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iUserPk          := Val(oFcgi:GetInputValue("TableKey"))
l_cUserFirstName   := SanitizeInput(oFcgi:GetInputValue("TextFirstName"))
l_cUserLastName    := SanitizeInput(oFcgi:GetInputValue("TextLastName"))
l_cUserID          := Strtran(SanitizeInput(oFcgi:GetInputValue("TextID"))," ","")
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
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("85938e4d-553e-4e34-9d3e-0db1f42f6629","User")
            :Where([upper(replace(User.ID,' ','')) = ^],l_cUserID)
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
                :Field("User.FirstName"   , l_cUserFirstName)
                :Field("User.LastName"    , l_cUserLastName)
                :Field("User.ID"          , l_cUserID)
                if l_iUserPk <> par_nCurrentUserPk  // May not change owns status or access mode (non admin user).
                    :Field("User.AccessMode"  , l_iUserAccessMode)
                    :Field("User.Status"      , l_iUserStatus)
                endif
                :Field("User.Description" , iif(empty(l_cUserDescription),NULL,l_cUserDescription))
                if empty(l_iUserPk)
                    if :Add()
                        l_iUserPk := :Key()

                        :Table("4650c039-a57b-4476-abf6-2d2806782c33","User")
                        :Field("User.Password" , hb_SHA512(l_cSecuritySalt+iif(empty(l_cUserPassword),l_cSecurityDefaultPassword,l_cUserPassword)+Trans(l_iUserPk)))
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

                if empty(l_cErrorMessage)
                    //Update the list selected Applications
                    l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)

                    with Object l_oDB2
                        :Table("98477c5c-898b-4a3b-98ab-3429f8153e79","Application")
                        :Column("Application.pk","pk")
                        :SQL("ListOfApplications")
                    endwith

                    //Get current list of User Applications
                    with Object l_oDB1
                        :Table("57992887-3dd6-4fad-b969-700820c5bd19","UserAccessApplication")
                        :Distinct(.t.)
                        :Column("Application.pk","pk")
                        :Column("UserAccessApplication.pk","UserAccessApplication_pk")
                        :Join("inner","Application","","UserAccessApplication.fk_Application = Application.pk")
                        :Where("UserAccessApplication.fk_User = ^" , l_iUserPk)
                        :SQL("ListOfCurrentApplicationForUser")
                        With Object :p_oCursor
                            :Index("pk","pk")
                            :CreateIndexes()
                            :SetOrder("pk")
                        endwith        
                    endwith

                    select ListOfApplications
                    scan all
                        l_lSelected := (oFcgi:GetInputValue("CheckApplication"+Trans(ListOfApplications->pk)) == "1")

                        if VFP_Seek(ListOfApplications->pk,"ListOfCurrentApplicationForUser","pk")
                            if !l_lSelected
                                // Remove the Application
                                with Object l_oDB3
                                    if !:Delete("3a72f1b0-7b6d-4da9-8bf7-91d8080c5ba7","UserAccessApplication",ListOfCurrentApplicationForUser->UserAccessApplication_pk)
                                        l_cErrorMessage := "Failed to Save Application selection."
                                        exit
                                    endif
                                endwith
                            endif
                        else
                            if l_lSelected
                                // Add the Application
                                with Object l_oDB3
                                    :Table("b9fe0a47-878e-4122-8c97-da45982e2554","UserAccessApplication")
                                    :Field("UserAccessApplication.fk_Application",ListOfApplications->pk)
                                    :Field("UserAccessApplication.fk_User",l_iUserPk)
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
                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Users/ListUsers/")
                endif
            endwith
        endif
    endcase

case l_cActionOnSubmit == "Cancel"
    if empty(l_iUserPk)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Users")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Users/ListUsers/")  // +par_cURLUserID+"/"
    endif

case l_cActionOnSubmit == "Delete"   // User
    if l_iUserPk == par_nCurrentUserPk
        l_cErrorMessage := "May not delete self."
    else
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
    
        with object l_oDB1
            :Table("839b7414-c220-49a4-ab7b-b3ca82373a14","UserAccessApplication")
            :Where("UserAccessApplication.fk_User = ^",l_iUserPk)
            :SQL()
            if :Tally == 0
                :Delete("7fbbf356-f3db-463b-8c29-cb87d0377b8e","User",l_iUserPk)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Users/")
            else
                l_cErrorMessage := "Related UserAccessApplication record on file"
            endif
        endwith
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
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with Object l_oDB2
            :Table("11ff420c-c516-4a77-8df5-c5223f6e0bf1","Application")
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

    l_cHtml += UserEditFormBuild(l_iUserPk,l_cErrorMessage,l_hValues)
endif

return l_cHtml
//=================================================================================================================
