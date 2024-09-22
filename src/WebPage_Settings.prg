#include "DataWharf.ch"

//=================================================================================================================
function BuildPageChangePassword()
local l_cHtml := []
// local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)

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
local l_cSitePath := oFcgi:p_cSitePath


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
                    l_cHtml += [<label class="control-label" for="TextCurrentPassword">Current Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextCurrentPassword" id="TextCurrentPassword" placeholder="Enter your current password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cCurrentPassword)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="TextNewPassword1">New Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextNewPassword1" id="TextNewPassword1" placeholder="Enter new password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cNewPassword1)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="TextNewPassword2">Re-Enter New Password</label>]
                    l_cHtml += [<input class="form-control mt-2" type="password" autocomplete="off" name="TextNewPassword2" id="TextNewPassword2" placeholder="Re-enter new password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cNewPassword2)+[">]
                l_cHtml += [</div>]

                l_cHtml += [<div class="mt-4">]
                    l_cHtml += [<span><input type="submit" class="btn btn-primary" value="Change Password" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button"></span>]
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

do case
case l_cActionOnSubmit == "Save"

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
        oFcgi:Redirect(oFcgi:p_cSitePath+"Home")
    else
        l_cHtml += BuildPageChangePasswordFormBuild(l_cErrorMessage)
    endif

otherwise
    oFcgi:Redirect(oFcgi:p_cSitePath+"Home")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function BuildPageMySettings()
local l_cHtml := []
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("BuildPageMySettings")

if oFcgi:isGet()
    l_cHtml += BuildPageMySettingsFormBuild()
else
    l_cHtml += BuildPageMySettingsFormOnSubmit()
endif

return l_cHtml
//=================================================================================================================
function BuildPageMySettingsFormBuild(par_cErrorMessage)
local l_cHtml := []
local l_cErrorMessage := hb_DefaultValue(par_cErrorMessage,"")
local l_iFk_TimeZone := 0
local l_cSitePath := oFcgi:p_cSitePath
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_TimeZone := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_json_TimeZones
local l_cObjectName
local l_hTimeZoneNames := {=>}
local l_cTimeZoneInfo
local l_oData

SetSelect2Support()

with object l_oDB1
    :Table("14b6a3b7-3066-414e-aa1f-d0bdd242ad47","User")
    :Column("User.fk_TimeZone" , "User_fk_TimeZone")
    l_oData := :Get(oFcgi:p_iUserPk)
    if :Tally == 1
        l_iFk_TimeZone := l_oData:User_fk_TimeZone
    endif
endwith

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[DataDictionaries/">Settings - My Settings</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(l_cErrorMessage)
    l_cHtml += [<div class="alert alert-danger" role="alert">]+l_cErrorMessage+[</div>]
endif

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]

    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data" class="form-horizontal">]

        l_cHtml += [<input type="hidden" name="formname" value="MySettings">]
        l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

        l_cHtml += [<div class="row">]
            l_cHtml += [<div class="w-50 mx-auto">]


                with object l_oDB_TimeZone
                    :Table("acc16d84-8158-45e7-851c-67dd2fa24cbf","TimeZone")
                    :Column("TimeZone.pk"         ,"pk")
                    :Column("TimeZone.Name"       ,"TimeZone_Name")
                    :Column("upper(TimeZone.Name)","tag1")
                    :OrderBy("tag1")
                    :Where("TimeZone.Status = 1")
                    :SQL("ListOfTimeZone")
                endwith

                l_json_TimeZones := []
                select ListOfTimeZone
                scan all
                    if !empty(l_json_TimeZones)
                        l_json_TimeZones += [,]
                    endif
                    l_cTimeZoneInfo := trim(ListOfTimeZone->TimeZone_Name)
                    l_cTimeZoneInfo := strtran(l_cTimeZoneInfo,"\","-")
                    l_cTimeZoneInfo := strtran(l_cTimeZoneInfo,"'","")

                    l_json_TimeZones += "{id:"+trans(ListOfTimeZone->pk)+",text:'"+l_cTimeZoneInfo+"'}"
                    l_hTimeZoneNames[ListOfTimeZone->pk] := l_cTimeZoneInfo
                endscan
                l_json_TimeZones := "["+l_json_TimeZones+"]"

                

                l_cObjectName := "ComboFk_TimeZone"

                ActivatejQuerySelect2("#"+l_cObjectName,l_json_TimeZones)

                l_cHtml += [<div class="form-group mt-4">]
                    l_cHtml += [<label class="control-label" for="]+l_cObjectName+[">Time Zone</label>]

                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="]+l_cObjectName+[" id="]+l_cObjectName+[" class="SelectEntity ms-2" style="width:600px">]
                        if l_iFk_TimeZone == 0
                            oFcgi:p_cjQueryScript += [$("#]+l_cObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
                        else
                            l_cHtml += [<option value="]+Trans(l_iFk_TimeZone)+[" selected="selected">]+hb_HGetDef(l_hTimeZoneNames,l_iFk_TimeZone,"")+[</option>]
                        endif
                    l_cHtml += [</select>]
                l_cHtml += [</div>]

                l_cHtml += [<div class="mt-4">]
                    l_cHtml += [<span><input type="submit" class="btn btn-primary" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button"></span>]
                    l_cHtml += [<span><input type="submit" class="btn btn-primary ms-4" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button"></span>]
                l_cHtml += [</div>]

            l_cHtml += [</div>]
        l_cHtml += [</div>]

    l_cHtml += [</form>]

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
function BuildPageMySettingsFormOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit

local l_iFk_TimeZone

local l_cErrorMessage := ""
local l_iUserPk
local l_oData
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("BuildPageMySettingsFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iFk_TimeZone    := val(oFcgi:GetInputValue("ComboFk_TimeZone"))

do case
case l_cActionOnSubmit == "Save"

    do case
    case empty(l_iFk_TimeZone)
        l_cErrorMessage := "Missing Time Zone."
    otherwise
        l_iUserPk := oFcgi:p_iUserPk

        with object l_oDB1
            :Table("fc18900e-ed37-4634-a266-52becfee6df1","public.User")
            :Column("User.fk_TimeZone"  ,"User_fk_TimeZone")
            l_oData := :Get(l_iUserPk)
            if :Tally == 1

                if l_oData:User_fk_TimeZone <> l_iFk_TimeZone
                    :Table("cf40153f-3c18-404e-8cf5-4d863c4d73f0","User")
                    :Field("User.fk_TimeZone", l_iFk_TimeZone )
                    :Update(l_iUserPk)
                endif
            else
                l_cErrorMessage := "Failed to find your account."
            endif
        endwith

    endcase
    if empty(l_cErrorMessage)
        oFcgi:Redirect(oFcgi:p_cSitePath+"Home")
    else
        l_cHtml += BuildPageMySettingsFormBuild(l_cErrorMessage)
    endif

otherwise
    oFcgi:Redirect(oFcgi:p_cSitePath+"Home")

endcase

return l_cHtml
//=================================================================================================================

