#include "DataWharf.ch"

//=================================================================================================================
// function BuildPageSettings()
// local l_cHtml := []
// local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)

// oFcgi:TraceAdd("BuildPageSettings")

// l_cHtml += [<div class="m-3"></div>]   //Spacer

// l_cHtml += [<div class="row justify-content-center">]

//     l_cHtml += [<div>Settings</div>]

// l_cHtml += [</div>]

// return l_cHtml
//=================================================================================================================
function BuildPageChangePassword()
local l_cHtml := []
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("BuildPageChangePassword")


if oFcgi:isGet()
    l_cHtml += BuildPageChangePasswordFormBuild()
else
    l_cHtml += BuildPageChangePasswordFormOnSubmit()
endif

return l_cHtml
//=================================================================================================================
function BuildPageChangePasswordFormBuild(par_cErrorMessage)
local l_cHtml := []
local l_cErrorMessage := hb_DefaultValue(par_cErrorMessage,"")
local l_cCurrentPassword := []
local l_cNewPassword1    := []
local l_cNewPassword2    := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]


l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[DataDictionaries/">Settings - Change Password</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(l_cErrorMessage)
    l_cHtml += [<div class="alert alert-danger" role="alert">]+l_cErrorMessage+[</div>]
endif

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]

    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data" class="form-horizontal">]

        l_cHtml += [<input type="hidden" name="formname" value="ChangePassword">]
        l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

        l_cHtml += [<div class="row">]
            l_cHtml += [<div class="w-50 mx-auto">]
// BUG in browsers.  autocomplete="off"  does not work in password input
                // l_cHtml += [<br>]

                // l_cHtml += [<div class="form-group has-success">]
                //     l_cHtml += [<label class="control-label" for="TextID">User ID</label>]
                //     l_cHtml += [<div class="mt-2">]
                //         l_cHtml += [<input class="form-control" type="text" name="TextID" id="TextID" placeholder="Enter your User ID" maxlength="100" size="30" value="]+FcgiPrepFieldForValue(l_cID)+[" autocomplete="off">]
                //     l_cHtml += [</div>]
                // l_cHtml += [</div>]

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="TextPassword">Current Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextCurrentPassword" id="TextCurrentPassword" placeholder="Enter your current password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cCurrentPassword)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="TextPassword">New Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextNewPassword1" id="TextNewPassword1" placeholder="Enter new password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cNewPassword1)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="TextPassword">Re-Enter New Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextNewPassword2" id="TextNewPassword2" placeholder="Re-enter new password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cNewPassword2)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="mt-4">]
                    l_cHtml += [<span><input type="submit" class="btn btn-primary" value="Change Password" onclick="$('#ActionOnSubmit').val('Change');document.form.submit();" role="button"></span>]
                    l_cHtml += [<span><input type="submit" class="btn btn-primary ms-4" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button"></span>]
                l_cHtml += [</div>]

            l_cHtml += [</div>]
        l_cHtml += [</div>]

        // oFcgi:p_cjQueryScript += [ $('#TextCurrentPassword').attr("autocomplete", "off");]
        // oFcgi:p_cjQueryScript += [ $('#TextCurrentPassword').attr("type", "password");]

        // oFcgi:p_cjQueryScript += [ $('input').attr('autocomplete','off');]
        //.setAttribute("type", "password");

        oFcgi:p_cjQueryScript += [ $('#TextCurrentPassword').focus();]
        
    l_cHtml += [</form>]



l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
function BuildPageChangePasswordFormOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit

local l_cCurrentPassword
local l_cNewPassword1
local l_cNewPassword2

local l_cErrorMessage := ""
local l_iUserPk
local l_oData
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSecuritySalt

oFcgi:TraceAdd("BuildPageChangePasswordFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cCurrentPassword    := SanitizeInput(oFcgi:GetInputValue("TextCurrentPassword"))
l_cNewPassword1       := SanitizeInput(oFcgi:GetInputValue("TextNewPassword1"))
l_cNewPassword2       := SanitizeInput(oFcgi:GetInputValue("TextNewPassword2"))

// altd()

do case
case l_cActionOnSubmit == "Change"

    do case
    case empty(l_cCurrentPassword)
        l_cErrorMessage := "Missing Current Password."
    case empty(l_cNewPassword1)
        l_cErrorMessage := "Missing New Password."
    case empty(l_cNewPassword2)
        l_cErrorMessage := "Missing New Password Re-Enter."
    case l_cNewPassword1 <> l_cNewPassword2
        l_cErrorMessage := "New Password entries don't match."
    case len(l_cNewPassword1) < 4
        l_cErrorMessage := "New password must be at least 4 character long."
    otherwise
        l_iUserPk := oFcgi:p_iUserPk

        with object l_oDB1
            :Table("aa3e6809-4122-47e5-b6cf-65c712fe052a","public.User")
            :Column("User.Password"  ,"User_Password")
            l_oData := :Get(l_iUserPk)
            if :Tally == 1

                //Check if valid Password
                l_cSecuritySalt := oFcgi:GetAppConfig("SECURITY_SALT")

                if Trim(l_oData:User_Password) == hb_SHA512(l_cSecuritySalt+l_cCurrentPassword+Trans(l_iUserPk))
                    :Table("cf40153f-3c18-404e-8cf5-4d863c4d73f0","User")
                    :Field("User.Password", hb_SHA512(l_cSecuritySalt+l_cNewPassword1+Trans(l_iUserPk)) )
                    :Update(l_iUserPk)

                else
                    l_cErrorMessage := "Current password is not valid."
                endif
            else
                l_cErrorMessage := "Failed to find your account."
            endif
        endwith


    endcase
    if empty(l_cErrorMessage)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Home")
    else
        l_cHtml += BuildPageChangePasswordFormBuild(l_cErrorMessage)
    endif

otherwise
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Home")

endcase

// if !empty(l_cErrorMessage)
//     l_hValues["FirstName"]   := l_cUserFirstName
//     l_hValues["LastName"]    := l_cUserLastName
//     l_hValues["ID"]          := l_cUserID
//     l_hValues["Password"]    := l_cUserPassword
//     l_hValues["AccessMode"]  := l_iUserAccessMode
//     l_hValues["Status"]      := l_iUserStatus
//     l_hValues["Description"] := l_cUserDescription

//     if !used("ListOfApplications")
//         with Object l_oDB_ListOfApplications
//             :Table("11ff420c-c516-4a77-8df5-c5223f6e0bf1","Application")
//             :Column("Application.pk" ,"pk")
//             :SQL("ListOfApplications")
//         endwith
//     endif
//     select ListOfApplications
//     scan all
//         l_nAccessLevelDD := val(oFcgi:GetInputValue("ComboApplicationSecLevelDD"+Trans(ListOfApplications->pk)))
//         if l_nAccessLevelDD > 1 // No need to store the none, since not having a selection will mean "None"
//             l_hValues["Application"+Trans(ListOfApplications->pk)] := l_nAccessLevelDD
//         endif
//     endscan

//     if !used("ListOfProjects")
//         with Object l_oDB_ListOfProjects
//             :Table("f576f41c-dcc4-4cd6-932e-871c75e541cd","Project")
//             :Column("Project.pk" ,"pk")
//             :SQL("ListOfProjects")
//         endwith
//     endif
//     select ListOfProjects
//     scan all
//         l_nAccessLevelML := val(oFcgi:GetInputValue("ComboProjectSecLevelML"+Trans(ListOfProjects->pk)))
//         if l_nAccessLevelML > 1 // No need to store the none, since not having a selection will mean "None"
//             l_hValues["Project"+Trans(ListOfProjects->pk)] := l_nAccessLevelML
//         endif
//     endscan

//     l_cHtml += UserEditFormBuild(l_iUserPk,l_cErrorMessage,l_hValues)
// endif

return l_cHtml
//=================================================================================================================
