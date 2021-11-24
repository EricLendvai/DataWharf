//Copyright (c) 2021 Eric Lendvai MIT License

#include "hb_fcgi.ch"

request HB_CODEPAGE_UTF8

#include "DataWharf.ch"

memvar v_hPP

memvar v_hPageMapping
// memvar oFcgi  Already declared as memvar in "hb_fcgi.ch"
//=================================================================================================================
Function Main()

public v_hPP
public oFcgi
v_hPP := nil

//The following Hash will have per web page name (url) an array that consists of {Minimum User Access Level,PointerToFunctionToBuildThePage}
//User Access Levels: 0 = public, 1 = logged in, 2 = Admin
public v_hPageMapping := {"home"             => {"Home"           ,1,@BuildPageHome()},;
                          "Info"             => {"Info"           ,0,@BuildPageAppInfo()},;   //Does not require to be logged in.
                          "Applications"     => {"Applications"   ,1,@BuildPageApplications()},;
                          "Application"      => {"Applications"   ,1,@BuildPageApplications()} }

hb_HCaseMatch(v_hPageMapping,.f.)

SendToDebugView("Starting DataWharf FastCGI App")

hb_cdpSelect("UTF8")

set century on

oFcgi := MyFcgi():New()    // Used a subclass of hb_Fcgi
do while oFcgi:Wait()
    oFcgi:OnRequest()
enddo

SendToDebugView("Ending DataWharf FastCGI App")

return nil
//=================================================================================================================
class MyFcgi from hb_Fcgi
    data p_o_SQLConnection
    data p_cHeader          init ""
    data p_cjQueryScript    init ""
    data p_nUserAccessMode  init 0
    
    //In this app the first element of the URL is always a page name. 
    data p_URLPathElements  init ""   READONLY   //Array of URL elements. For example:   /<pagename>/<id>/<ParentName>/<ParentId>  will create a 4 element array.
    data p_PageName         init ""              //Could be altered. The original PageName is in ::p_URLPathElements[1]

    data p_ColumnTypes      init {{  "I","Integer"                                      ,.f.,.f.,.f.,"integer"                    ,"INT"},;      // {Code,Harbour Name,Show Length,Show Scale,Show Enums,PostgreSQL Name, MySQL Name}
                                  { "IB","Integer Big"                                  ,.f.,.f.,.f.,"bigint"                     ,"BIGINT"},;
                                  {  "N","Numeric"                                      ,.t.,.t.,.f.,"numeric"                    ,"DECIMAL"},;
                                  {  "C","Character String"                             ,.t.,.f.,.f.,"character"                  ,"CHAR"},;
                                  { "CV","Character String Varying"                     ,.t.,.f.,.f.,"character varying"          ,"VARCHAR"},;
                                  {  "B","Binary String"                                ,.t.,.f.,.f.,"bit"                        ,"BINARY"},;
                                  { "BV","Binary String Varying"                        ,.t.,.f.,.f.,"bit varying"                ,"VARBINARY"},;
                                  {  "M","Memo / Long Text"                             ,.f.,.f.,.f.,"text"                       ,"LONGTEXT"},;
                                  {  "R","Raw Binary"                                   ,.f.,.f.,.f.,"bytea"                      ,"LONGBLOB"},;
                                  {  "L","Logical"                                      ,.f.,.f.,.f.,"boolean"                    ,"TINYINT(1)"},;
                                  {  "D","Date"                                         ,.f.,.f.,.f.,"date"                       ,"DATE"},;
                                  {"TOZ","Time Only With Time Zone Conversion"          ,.f.,.f.,.f.,"time with time zone"        ,"TIME COMMENT 'with timezone'"},;
                                  { "TO","Time Only Without Time Zone Conversion"       ,.f.,.f.,.f.,"time without time zone"     ,"TIME"},;
                                  {"DTZ","Date and Time With Time Zone Conversion (T)"  ,.f.,.f.,.f.,"timestamp with time zone"   ,"TIMESTAMP"},;
                                  { "DT","Date and Time Without Time Zone Conversion"   ,.f.,.f.,.f.,"timestamp without time zone","DATETIME"},;
                                  {  "Y","Money"                                        ,.f.,.f.,.f.,"money"                      ,"DECIMAL(13,4) COMMENT 'money'"},;
                                  {  "E","Enumeration"                                  ,.f.,.f.,.t.,"enum"                       ,"ENUM"},;
                                  {"UUI","UUID Universally Unique Identifier"           ,.f.,.f.,.f.,"uuid"                       ,"BINARY(16)"},;   // In DBF VarChar 36
                                  {  "?","Other"                                        ,.f.,.f.,.f.,""                           ,""};
                                 }
//12345
    method OnFirstRequest()
    method OnRequest()
    method OnShutdown()
    method OnError(par_oError)
    method Self() inline Self
endclass
//=================================================================================================================
method OnFirstRequest() class MyFcgi
SendToDebugView("Called from method OnFirstRequest")

set century on
set delete on

::SetOnErrorDetailLevel(2)
::SetOnErrorProgramInfo(hb_BuildInfo())

::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",,,,;
                                    ::GetAppConfig("POSTGRESID"),;
                                    ::GetAppConfig("POSTGRESPASSWORD"),;
                                    "DataWharf","public";
                                    )
with object ::p_o_SQLConnection
    :PostgreSQLHBORMSchemaName  := "ORM"
    :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
    :SetPrimaryKeyFieldName("pk")

    if :Connect() >= 0
        UpdateSchema(::p_o_SQLConnection)
    else
        ::p_o_SQLConnection := NIL
    endif
endwith

return nil 
//=================================================================================================================
method OnRequest() class MyFcgi
local l_cPageHeaderHtml := []
local l_cBody := []
local l_cHtml := []

local l_cSitePath
local l_cPageName
local l_cSessionID
local l_nPos
local l_lLoggedIn
local l_nLoggedInPk,l_cLoggedInSignature
local l_cFormName
local l_cActionOnSubmit
local l_cID
local l_cPassword
local l_oDB1
local l_cSessionCookie
local l_nUserPk
local l_cUserId
local l_cUserName
local l_nUserAccessMode
local l_nLoginLogsPk
local l_cAction
local l_oData
local l_cSignature
local l_cIP := ::RequestSettings["ClientIP"]
local l_cLastSQL,l_cLastError
local l_nLoginOutUserPk
local l_aWebPageHandle
local l_aPathElements
local l_iLoop
local l_cAjaxAction

//AltD()

SendToDebugView("Request Counter",::RequestCount)

//Since the OnFirstRequest method only runs on first request, on following request have to check if connection is still active, and not terminated by the SQL Server.
if ::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected()
    SendToDebugView("Reconnecting to SQL Server")
    ::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",,,,;
                                        ::GetAppConfig("POSTGRESID"),;
                                        ::GetAppConfig("POSTGRESPASSWORD"),;
                                        "DataWharf","public";
                                        )
    with object ::p_o_SQLConnection
        :PostgreSQLHBORMSchemaName  := "ORM"
        :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
        :SetPrimaryKeyFieldName("pk")

        if :Connect() >= 0
            UpdateSchema(::p_o_SQLConnection)
            SendToDebugView("Reconnected to SQL Server")
        else
            ::p_o_SQLConnection := NIL
        endif
    endwith
endif

// l_cSitePath := ::GetEnvironment("CONTEXT_PREFIX")
// if len(l_cSitePath) == 0
//     l_cSitePath := "/"
// endif

// ::GetQueryString("p")

::p_URLPathElements := {}
l_cSitePath := ::RequestSettings["SitePath"]

l_cPageName := substr(::GetEnvironment("REDIRECT_URL"),len(l_cSitePath)+1)
l_aPathElements := hb_ATokens(l_cPageName,"/",.f.)
if len(l_aPathElements) > 1
    l_cPageName := l_aPathElements[1]
    // ::p_URLPathElements := AClone(l_aPathElements)    Not supported in Harbour
    for l_iLoop := 1 to len(l_aPathElements)
        AAdd(::p_URLPathElements,l_aPathElements[l_iLoop])
    endfor
else
    AAdd(::p_URLPathElements,l_cPageName)
endif

if empty(l_cPageName) .or.(lower(l_cPageName) == "default.html")
    l_cPageName := "home"
endif
::p_PageName := l_cPageName


// AltD()


// ::URLPathElements := {}
//Following is Buggy
// if len(l_aPathElements) > 1
//     ACopy(l_aPathElements,::URLPathElements,2,len(l_aPathElements)-1)
// endif

    // for l_iLoop := 1 to len(l_aPathElements)
    //     AAdd(::URLPathElements,l_aPathElements[l_iLoop])
    // endfor

if l_cPageName <> "ajax"

    l_aWebPageHandle := hb_HGetDef(v_hPageMapping, l_cPageName, {"Home",1,@BuildPageHome()})
    // #define WEBPAGEHANDLE_NAME            1
    // #define WEBPAGEHANDLE_ACCESSLEVEL     2
    // #define WEBPAGEHANDLE_FUNCTIONPOINTER 3

    ::p_cHeader       := ""
    ::p_cjQueryScript := ""


    // l_cPageHeaderHtml += [<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=UTF-8">]

    l_cPageHeaderHtml += [<meta http-equiv="X-UA-Compatible" content="IE=edge">]
    l_cPageHeaderHtml += [<meta http-equiv="Content-Type" content="text/html;charset=utf-8">]
    l_cPageHeaderHtml += [<title>]+APPLICATION_TITLE+[</title>]


    l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_5_0_2/css/bootstrap.min.css">]
    l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/jQueryUI_1_12_1_NoTooltip/Themes/smoothness/jQueryUI.css">]
    l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/FontAwesome_5_3_1/css/all.min.css">]

    l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQuery_3_6_0/jquery.min.js"></script>]
    l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/Bootstrap_5_0_2/js/bootstrap.bundle.min.js"></script>]

    l_cPageHeaderHtml += [<script>$.fn.bootstrapBtn = $.fn.button.noConflict();</script>]
    l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQueryUI_1_12_1_NoTooltip/jquery-ui.min.js"></script>]


    // l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/jQueryUI_1_13_0_NoTooltip/Themes/smoothness/jQueryUI.css">]
    // l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/Bootstrap_4_6_0/js/bootstrap.bundle.min.js"></script>]
    // l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_4_6_0/css/bootstrap.min.css">]
    // l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQueryUI_1_13_0_NoTooltip/jquery-ui.min.js"></script>]



    ::p_cHeader := l_cPageHeaderHtml
endif

l_cPageHeaderHtml := NIL  //To free memory

l_oDB1       := hb_SQLData(::p_o_SQLConnection)
l_cSessionID := ::GetCookieValue("SessionID")
l_cAction    := ::GetQueryString("action")

// Altd()

if l_cAction == "logout"
    if !empty(l_cSessionID)
        l_nPos               := at("-",l_cSessionID)
        l_nLoggedInPk        := val(left(l_cSessionID,l_nPos))
        l_cLoggedInSignature := Trim(substr(l_cSessionID,l_nPos+1))
        if !empty(l_nLoggedInPk)
            l_oDB1:Table("f40ca9ad-ef2c-4628-af82-67c1a8102f11","public.LoginLogs")
            l_oDB1:Column("LoginLogs.Status"   ,"LoginLogs_Status")
            l_oDB1:Column("LoginLogs.Signature","LoginLogs_Signature")
            l_oDB1:Column("LoginLogs.fk_User","User_pk")
            l_oData := l_oDB1:Get(l_nLoggedInPk)

            if l_oDB1:Tally == 1
                l_nLoginOutUserPk := l_oData:User_pk
                if Trim(l_oData:LoginLogs_Signature) == l_cLoggedInSignature .and. l_oData:LoginLogs_Status == 1
                    l_oDB1:Table("241914ab-ab79-43dd-b5dd-8424c38a1e9b","Public.LoginLogs")
                    l_oDB1:Field("LoginLogs.Status",2)
                    l_oDB1:Field("LoginLogs.TimeOut",{"S","now()"})
                    l_oDB1:Update(l_nLoggedInPk)
                endif

                //Logout implicitly any other session for the same user
                l_oDB1:Table("dbe98b47-b5ce-4fbd-aedd-8f59fac60ec3","public.LoginLogs")
                l_oDB1:Column("LoginLogs.pk","pk")
                l_oDB1:Where("LoginLogs.fk_User = ^" , l_nLoginOutUserPk)
                l_oDB1:Where("LoginLogs.Status = 1")
                l_oDB1:SQL("ListOfResults")
                select ListOfResults
                scan all
                    l_oDB1:Table("c03a9f3e-ace3-48e1-9c21-df0d43be5ad2","public.LoginLogs")
                    l_oDB1:Field("LoginLogs.Status",3)
                    l_oDB1:Field("LoginLogs.TimeOut",{"S","now()"})
                    l_oDB1:Update(ListOfResults->pk)
// SendToDebugView("1 "+l_oDB1:LastSQL())
                endscan
                CloseAlias("ListOfResults")
            else
                l_cLastSQL   := l_oDB1:LastSQL()
                l_cLastError := l_oDB1:ErrorMessage()
            endif
        endif
        l_cSessionID := ""
        ::DeleteCookie("SessionID")
        ::Redirect("home")
        return nil
    endif
endif

l_lLoggedIn       := .f.
l_cUserId         := ""
l_cUserName       := ""
l_nUserAccessMode := 0

if !empty(l_cSessionID)
    l_nPos               := at("-",l_cSessionID)
    l_nLoggedInPk        := val(left(l_cSessionID,l_nPos))
    l_cLoggedInSignature := Trim(substr(l_cSessionID,l_nPos+1))
    if !empty(l_nLoggedInPk)
        // Verify if valid loggin
        l_oDB1:Table("4edc82f8-f58e-4013-98a3-22732b408319","public.LoginLogs")
        l_oDB1:Column("LoginLogs.Status","LoginLogs_Status")
        l_oDB1:Column("User.pk"         ,"User_pk")
        l_oDB1:Column("User.id"         ,"User_id")
        l_oDB1:Column("User.Name"       ,"User_Name")
        l_oDB1:Column("User.AccessMode" ,"User_AccessMode")
        l_oDB1:Where("LoginLogs.pk = ^",l_nLoggedInPk)
        l_oDB1:Where("Trim(LoginLogs.Signature) = ^",l_cLoggedInSignature)
        l_oDB1:Where("User.Status = 1")
        l_oDB1:Join("inner","User","","LoginLogs.fk_User = User.pk")
        l_oDB1:SQL("ListOfResults")
        if l_oDB1:Tally = 1
            l_lLoggedIn := .t.
            l_nUserPk := ListOfResults->User_pk
            l_cUserId := AllTrim(ListOfResults->User_Id)
            l_cUserName := Alltrim(hb_DefaultValue(ListOfResults->User_Name,"Me"))
            l_nUserAccessMode := ListOfResults->User_AccessMode
        else
            // Clear the cookie
            ::DeleteCookie("SessionID")
        endif
        CloseAlias("ListOfResults")
    endif
endif

if l_cPageName <> "ajax"
    //If not a public page and not logged in, then request to log in.
    if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSLEVEL] > 0 .and. !l_lLoggedIn
        if oFcgi:IsGet()
            l_cBody += GetPageHeader(.f.,l_cPageName,"",1)
            l_cBody += BuildPageLoginScreen()
        else
            //Post
            l_cFormName       := oFcgi:GetInputValue("formname")
            l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
            l_cID             := SanitizeInput(oFcgi:GetInputValue("TextID"))
            l_cPassword       := SanitizeInput(oFcgi:GetInputValue("TextPassword"))

            with object l_oDB1
                :Table("6bad4ae5-6bb2-4bdb-97b9-6adacb2a8327","public.User")
                :Column("User.pk"        ,"User_pk")
                :Column("User.Name"      ,"User_Name")
                :Column("User.AccessMode","User_AccessMode")
                :Where("trim(User.id) = ^",l_cID)
                :Where("trim(User.Password) = ^",l_cPassword)
                :Where("User.Status = 1")
                :SQL("ListOfResults")

    // l_cLastSQL   := :LastSQL()
    // l_cLastError := :ErrorMessage()
    // Altd()

                if :Tally == 1
                    l_nUserPk         := ListOfResults->User_Pk
                    l_cUserName       := Trim(ListOfResults->User_Name)
                    l_cSignature      := ::GenerateRandomString(10,"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
                    l_nUserAccessMode := ListOfResults->User_AccessMode

                    :Table("a58f5d2a-929a-4327-8694-9656377638ec","LoginLogs")
                    :Field("LoginLogs.fk_User"  ,l_nUserPk)
                    :Field("LoginLogs.TimeIn"   ,{"S","now()"})
                    :Field("LoginLogs.IP"       ,l_cIP)
                    :Field("LoginLogs.Attempts" ,1)   //_M_ for later use to prevent brute force attacks
                    :Field("LoginLogs.Status"   ,1)
                    :Field("LoginLogs.Signature",l_cSignature)
                    if :Add()
                        l_nLoginLogsPk := :Key()
                        l_cSessionCookie := trans(l_nLoginLogsPk)+"-"+l_cSignature
                        ::SetSessionCookieValue("SessionID",l_cSessionCookie,0)
                        l_lLoggedIn := .t.
                    endif
                else
                    //Invalid Login
                    l_cBody += GetPageHeader(.f.,l_cPageName,"",1)
                    l_cBody += BuildPageLoginScreen(l_cID,"","Invalid ID or Password")
                endif

            endwith

        endif
    endif
endif

if l_lLoggedIn
    ::p_nUserAccessMode := l_nUserAccessMode

    if l_cPageName == "ajax"
        l_cBody := [UNBUFFERED]
        if len(::p_URLPathElements) >= 2 .and. !empty(::p_URLPathElements[2])
            l_cAjaxAction := ::p_URLPathElements[2]

            switch l_cAjaxAction
            // case "VisualizationPositions"
            //     l_cBody += SaveVisualizationPositions()
            //     exit
            case "GetInfo"
                l_cBody += GetInfoDuringVisualization()
                exit
            endswitch

        endif
    else
        l_cBody += GetPageHeader(.t.,l_cPageName,l_cUserName,::p_nUserAccessMode)

        // l_cBody += l_aWebPageHandle[WEBPAGEHANDLE_FUNCTIONPOINTER]:exec(::Self(),l_cUserName,l_nUserPk)
        l_cBody += l_aWebPageHandle[WEBPAGEHANDLE_FUNCTIONPOINTER]:exec(l_cUserName,l_nUserPk)


        if l_cUserName == "Eric"
            l_cBody += [<div class="m-3">]   //Spacer
                if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSLEVEL] > 0  //Logged in page
                    l_cBody += "<div>Web Site Version: " + BUILDVERSION + "</div>"
                endif
                l_cBody += [<div>Site Build Info: ]+hb_buildinfo()+[</div>]
                l_cBody += [<div>ORM Build Info: ]+hb_orm_buildinfo()+[</div>]
                l_cBody += [<div>VFP Build Info: ]+hb_vfp_buildinfo()+[</div>]
                l_cBody += ::TraceList(4)
            l_cBody += [</div>]   //Spacer
        endif
    endif
else
    if l_cPageName == "ajax"
        l_cBody := [UNBUFFERED Not Logged In]
    else
        ::p_nUserAccessMode := 0
        if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSLEVEL] == 0   //public page
            l_cBody += l_aWebPageHandle[WEBPAGEHANDLE_FUNCTIONPOINTER]:exec(::Self(),"",0)
        endif
    endif
endif



if left(l_cBody,10) == [UNBUFFERED]
    l_cHtml := substr(l_cBody,11)
else
    l_cHtml := []
    l_cHtml += [<!DOCTYPE html>]
    l_cHtml += [<html>]
    l_cHtml += [<head>]
    l_cHtml += ::p_cHeader

    if !empty(::p_cjQueryScript)
        l_cHtml += CRLF
        l_cHtml += [<script type="text/javascript" language="Javascript">]+CRLF
        l_cHtml += [$(function() {]+CRLF
        l_cHtml += ::p_cjQueryScript+CRLF
        l_cHtml += [});]+CRLF
        l_cHtml += [</script>]+CRLF
    endif

    l_cHtml += [</head>]
    l_cHtml += [<body>]
    l_cHtml += l_cBody
    l_cHtml += [</body>]
    l_cHtml += [</html>]

endif

// altd()

::Print(l_cHtml)

return nil
//=================================================================================================================
method OnShutdown() class MyFcgi
    SendToDebugView("Called from method OnShutdown")
    if !IsNull(::p_o_SQLConnection)
        ::p_o_SQLConnection:Disconnect()
    endif
return nil 
//=================================================================================================================
method OnError(par_oError) class MyFcgi
    try
        SendToDebugView("Called from MyFcgi OnError")
        ::ClearOutputBuffer()
        ::Print("<h1>Error Occurred</h1>")
        ::Print("<h2>"+hb_buildinfo()+" - Current Time: "+hb_DToC(hb_DateTime())+"</h2>")
        ::Print("<div>"+FcgiGetErrorInfo(par_oError)+"</div>")
        //  ::hb_Fcgi:OnError(par_oError)
        ::Finish()
    catch
    endtry
    
    BREAK
return nil
//=================================================================================================================
function UpdateSchema(par_o_SQLConnection)
local l_LastError := ""
local l_Schema

#include "Schema.txt"

if el_AUnpack(par_o_SQLConnection:MigrateSchema(l_Schema),,,@l_LastError) > 0
else
    if !empty(l_LastError)
        SendToDebugView("PostgreSQL - Failed Migrate")
    endif
endif

return nil
//=================================================================================================================
function GetPageHeader(par_LoggedIn,par_cCurrentPage,par_cUserName,par_nUserAccessMode)
local l_cHtml := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

local l_cExtraClass := iif(COLOR_HEADER_TEXT_WHITE," text-white","")

l_cHtml += [<nav class="navbar navbar-expand-md navbar-light" style="background-color: #]+COLOR_HEADER_BACKGROUND+[;">]
    l_cHtml += [<div id="app" class="container">]
        l_cHtml += [<a class="navbar-brand]+l_cExtraClass+[" href="#">]+APPLICATION_TITLE+[</a>]
        if par_LoggedIn
            l_cHtml += [<div class="collapse navbar-collapse" id="navbarNav">]
                l_cHtml += [<ul class="navbar-nav mr-auto">]
                    l_cHtml += [<li class="nav-item"><a class="nav-link]+l_cExtraClass+iif(lower(par_cCurrentPage) == "home"        ,[ active" aria-current="page],[])+[" href="]+l_cSitePath+[Home">Home</a></li>]
                    l_cHtml += [<li class="nav-item"><a class="nav-link]+l_cExtraClass+iif(lower(par_cCurrentPage) == "applications",[ active" aria-current="page],[])+[" href="]+l_cSitePath+[Applications">Applications</a></li>]
                    l_cHtml += [<li class="nav-item"><a class="nav-link]+l_cExtraClass+iif(lower(par_cCurrentPage) == "info"        ,[ active" aria-current="page],[])+[" href="]+l_cSitePath+[Info">Info</a></li>]
                l_cHtml += [</ul>]
                l_cHtml += [<ul class="navbar-nav">]
                    l_cHtml += [<li class="nav-item"><a class="btn btn-primary" href="]+l_cSitePath+[home?action=logout">Logout (]+par_cUserName+iif(par_nUserAccessMode < 1," / View Only","")+[)</a></li>]
                l_cHtml += [</ul>]
            l_cHtml += [</div>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

// l_cHtml += [<div class="m-3"></div>]   //Spacer

return l_cHtml
//=================================================================================================================
function hb_buildinfo()
#include "BuildInfo.txt"
return l_cBuildInfo
//=================================================================================================================
function SanitizeInput(par_text)
local l_result := AllTrim(par_text)
l_result = vfp_StrReplace(l_result,{"<"="",">"=""})
return l_result
//=================================================================================================================
function GetConfirmationModalForms()
local cHtml

// Following Method failed once upgrated to bootstrap 5.
// TEXT TO VAR cHtml
// <script>
   
// function ConfirmDelete(par_Action) {
//     $('#modal').find('.modal-title').text('Confirm Delete?');
//     $('#modal-btn-yes').click(function(){$('#ActionOnSubmit').val('Delete');document.form.submit(); });
//     $('#modal').modal({show:true});
// } ;
   
// </script>

// <div class="modal fade" id="modal">
//     <div class="modal-dialog">
//         <div class="modal-content">
//             <div class="modal-header">
//                 <h4 class="modal-title">Are You Sure?</h4>
//                 <button type="button" class="close" data-dismiss="modal">&times;</button>
//             </div>
//             <div class="modal-body">
//                 This action cannot be undone.
//             </div>
//             <div class="modal-footer">
//                 <a id="modal-btn-yes" class="btn btn-danger" >Yes</a>
//                 <button type="button" class="btn btn-primary" data-dismiss="modal">No</button>
//             </div>
//         </div>
//     </div>
// </div>
// ENDTEXT


TEXT TO VAR cHtml

<div class="modal fade" id="ConfirmDeleteModal" tabindex="-1" aria-labelledby="ConfirmDeleteModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmDeleteModalLabel">Confirm Delete</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        This action cannot be undone
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Delete');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

return cHtml
//=================================================================================================================
function BuildPageLoginScreen(par_cId,par_cPassword,par_cErrorMessage)
local l_cHtml := ""
local l_cID           := hb_DefaultValue(par_cId,"")
local l_cPassword     := hb_DefaultValue(par_cPassword,"")
local l_cErrorMessage := hb_DefaultValue(par_cErrorMessage,"")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data" class="form-horizontal">]   //Since there are text fields entry fields, encode as multipart/form-data

    if !empty(l_cErrorMessage)
        l_cHtml += [<div class="alert alert-danger" role="alert">]+l_cErrorMessage+[</div>]
    endif

    l_cHtml += [<input type="hidden" name="formname" value="LoginScreen">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

    l_cHtml += [<div class="row">]
        l_cHtml += [<div class="w-50 mx-auto">]

            l_cHtml += [<br>]

            l_cHtml += [<div class="form-group has-success">]
                l_cHtml += [<label class="control-label" for="TextID">User ID</label>]
                l_cHtml += [<div class="mt-2">]
                    l_cHtml += [<input class="form-control" type="text" name="TextID" id="TextID" placeholder="Enter your User ID" maxlength="50" size="30" value="]+FcgiPrepFieldForValue(l_cID)+[" autocomplete="off">]
                l_cHtml += [</div>]
            l_cHtml += [</div>]

            l_cHtml += [<div class="form-group has-success mt-4">]
                l_cHtml += [<label class="control-label" for="TextPassword">Password</label>]
                l_cHtml += [<div class="mt-2">]
                    l_cHtml += [<input class="form-control" type="text" name="TextPassword" id="TextPassword" placeholder="Enter your password" maxlength="50" size="30" value="]+FcgiPrepFieldForValue(l_cPassword)+[" autocomplete="off">]
                l_cHtml += [</div>]
            l_cHtml += [</div>]

            l_cHtml += [<div class="m-3">]
                l_cHtml += [<span><input type="button" class="btn btn-primary" value="Login" onclick="$('#ActionOnSubmit').val('Login');document.form.submit();" role="button"></span>]
            l_cHtml += [</div>]

        l_cHtml += [</div>]
    l_cHtml += [</div>]

    // l_cHtml += [<script>]+CRLF
    //     l_cHtml += [$('#TextID').focus();"]+CRLF
    // l_cHtml += [</script>]+CRLF

    oFcgi:p_cjQueryScript += [ $('#TextID').focus();]
    
l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function TextToHTML(par_SourceText)
local l_Text

if hb_IsNull(par_SourceText)
    l_Text := ""
else
    l_Text := par_SourceText

    l_Text := vfp_strtran(l_Text,[&amp;],[&],-1,-1,1)
    l_Text := vfp_strtran(l_Text,[&],[&amp;])
    l_Text := vfp_strtran(l_Text,[<],[&lt;])
    l_Text := vfp_strtran(l_Text,[>],[&gt;])
    l_Text := vfp_strtran(l_Text,[  ],[ &nbsp;])
    l_Text := vfp_strtran(l_Text,chr(10),[])
    l_Text := vfp_strtran(l_Text,chr(13),[<br>])
endif

return l_Text
//=================================================================================================================
function GetItemInListAtPosition(par_iPos,par_aValues,par_xDefault)
return iif(!hb_isnil(par_iPos) .and. par_iPos > 0 .and. par_iPos <= Len(par_aValues), par_aValues[par_iPos], par_xDefault)
//=================================================================================================================
//=================================================================================================================
 