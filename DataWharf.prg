//Copyright (c) 2021-2022 Eric Lendvai MIT License

#include "hb_fcgi.ch"

request HB_CODEPAGE_UTF8

#include "DataWharf.ch"

memvar v_hPP
memvar iFastCGIRunLogPk

memvar v_hPageMapping
// memvar oFcgi  Already declared as memvar in "hb_fcgi.ch"
//=================================================================================================================
Function Main()

public v_hPP
public oFcgi
v_hPP := nil

public iFastCGIRunLogPk
iFastCGIRunLogPk := 0


//The following Hash will have per web page name (url) an array that consists of {Page Title,Minimum User Access Level,PointerToFunctionToBuildThePage}
//User Access Levels: 0 = public, 1 = logged in, 2 = Admin
public v_hPageMapping := {"home"             => {"Home"                     ,1,@BuildPageHome()},;
                          "About"            => {"About"                    ,0,@BuildPageAppAbout()},;   //Does not require to be logged in.
                          "ChangePassword"   => {"Change Password"          ,1,@BuildPageChangePassword()},;
                          "Projects"         => {"Projects"                 ,1,@BuildPageProjects()},;
                          "Project"          => {"Projects"                 ,1,@BuildPageProjects()},;
                          "Applications"     => {"Applications"             ,1,@BuildPageApplications()},;
                          "Application"      => {"Applications"             ,1,@BuildPageApplications()},;
                          "Modeling"         => {"Modeling"                 ,1,@BuildPageModeling()},;
                          "DataDictionaries" => {"DataDictionaries"         ,1,@BuildPageDataDictionaries()},;
                          "DataDictionary"   => {"DataDictionaries"         ,1,@BuildPageDataDictionaries()},;
                          "InterAppMapping"  => {"Inter Application Mapping",1,@BuildPageInterAppMapping()},;
                          "CustomFields"     => {"Custom Fields"            ,1,@BuildPageCustomFields()},;
                          "Users"            => {"Users"                    ,1,@BuildPageUsers()} }

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
    data p_iUserPk          init 0   // Current "User.pk"
    data p_cUserName        init ""  // Current logged in User Name
    data p_nUserAccessMode  init 0   // User based access level. Comes from "User.AccessMode"
    data p_nAccessLevelDD   init 0   // Current Application Data Dictionary "UserAccessApplication.AccessLevelDD if ::p_nUserAccessMode == 1 otherwise either 1 or 7
    data p_nAccessLevelML   init 0   // Current Application Modeling        "UserAccessApplication.AccessLevelDD if ::p_nUserAccessMode == 1 otherwise either 1 or 7
    
    //Used in Modeling. ANF stands for "AlternateNameFor"
    data p_ANFModel             init "Model"
    data p_ANFModels            init "Models"
    data p_ANFEntity            init "Entity"
    data p_ANFEntities          init "Entities"
    data p_ANFAssociation       init "Association"
    data p_ANFAssociations      init "Associations"
    data p_ANFAttribute         init "Attribute"
    data p_ANFAttributes        init "Attributes"
    data p_ANFDataType          init "Data Type"
    data p_ANFDataTypes         init "Data Types"
    data p_ANFEnumeration       init "Enumeration"
    data p_ANFEnumerations      init "Enumerations"
    data p_ANFPackage           init "Package"
    data p_ANFPackages          init "Packages"
    data p_ANFLinkedEntity      init "Linked Entity"
    data p_ANFLinkedEntities    init "Linked Entities"


    //In this app the first element of the URL is always a page name. 
    data p_URLPathElements  init ""   READONLY   //Array of URL elements. For example:   /<pagename>/<id>/<ParentName>/<ParentId>  will create a 4 element array.
    data p_PageName         init ""              //Could be altered. The original PageName is in ::p_URLPathElements[1]

    data p_ColumnTypes      init {{  "I","Integer"                                      ,.f.,.f.,.f.,.f.,"integer"                    ,"INT"},;      // {Code,Harbour Name,Show Length,Show Scale,Show Enums,PostgreSQL Name, MySQL Name}
                                  { "IB","Integer Big"                                  ,.f.,.f.,.f.,.f.,"bigint"                     ,"BIGINT"},;
                                  {  "N","Numeric"                                      ,.t.,.t.,.f.,.f.,"numeric"                    ,"DECIMAL"},;
                                  {  "C","Character String"                             ,.t.,.f.,.f.,.t.,"character"                  ,"CHAR"},;
                                  { "CV","Character String Varying"                     ,.t.,.f.,.f.,.t.,"character varying"          ,"VARCHAR"},;
                                  {  "B","Binary String"                                ,.t.,.f.,.f.,.f.,"bit"                        ,"BINARY"},;
                                  { "BV","Binary String Varying"                        ,.t.,.f.,.f.,.f.,"bit varying"                ,"VARBINARY"},;
                                  {  "M","Memo / Long Text"                             ,.f.,.f.,.f.,.t.,"text"                       ,"LONGTEXT"},;
                                  {  "R","Raw Binary"                                   ,.f.,.f.,.f.,.f.,"bytea"                      ,"LONGBLOB"},;
                                  {  "L","Logical"                                      ,.f.,.f.,.f.,.f.,"boolean"                    ,"TINYINT(1)"},;
                                  {  "D","Date"                                         ,.f.,.f.,.f.,.f.,"date"                       ,"DATE"},;
                                  {"TOZ","Time Only With Time Zone Conversion"          ,.f.,.f.,.f.,.f.,"time with time zone"        ,"TIME COMMENT 'with timezone'"},;
                                  { "TO","Time Only Without Time Zone Conversion"       ,.f.,.f.,.f.,.f.,"time without time zone"     ,"TIME"},;
                                  {"DTZ","Date and Time With Time Zone Conversion (T)"  ,.f.,.f.,.f.,.f.,"timestamp with time zone"   ,"TIMESTAMP"},;
                                  { "DT","Date and Time Without Time Zone Conversion"   ,.f.,.f.,.f.,.f.,"timestamp without time zone","DATETIME"},;
                                  {  "Y","Money"                                        ,.f.,.f.,.f.,.f.,"money"                      ,"DECIMAL(13,4) COMMENT 'money'"},;
                                  {  "E","Enumeration"                                  ,.f.,.f.,.t.,.f.,"enum"                       ,"ENUM"},;
                                  {"UUI","UUID Universally Unique Identifier"           ,.f.,.f.,.f.,.f.,"uuid"                       ,"BINARY(16)"},;   // In DBF VarChar 36
                                  {  "?","Other"                                        ,.f.,.f.,.f.,.f.,""                           ,""};
                                 }
    method OnFirstRequest()
    method OnRequest()
    method OnShutdown()
    method OnError(par_oError)
    method Self() inline Self

    #include "api.txt"

endclass
//=================================================================================================================
method OnFirstRequest() class MyFcgi
local l_oDB1
local l_oDB2
// local l_oDB3
local l_cSecuritySalt
local l_cSecurityDefaultPassword
local l_iCurrentDataVersion

SendToDebugView("Called from method OnFirstRequest")

set century on
set delete on

::SetOnErrorDetailLevel(2)
::SetOnErrorProgramInfo(hb_BuildInfo())

::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",;
                                    ,;
                                    ::GetAppConfig("POSTGRESHOST"),;
                                    val(::GetAppConfig("POSTGRESPORT")),;
                                    ::GetAppConfig("POSTGRESID"),;
                                    ::GetAppConfig("POSTGRESPASSWORD"),;
                                    ::GetAppConfig("POSTGRESDATABASE"),;
                                    "public";
                                    )
with object ::p_o_SQLConnection
    :PostgreSQLHBORMSchemaName  := "ORM"
    :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
    :SetPrimaryKeyFieldName("pk")

    if :Connect() >= 0
        UpdateSchema(::p_o_SQLConnection)

        l_oDB1 := hb_SQLData(::p_o_SQLConnection)
        l_oDB2 := hb_SQLData(::p_o_SQLConnection)
        // l_oDB3 := hb_SQLData(::p_o_SQLConnection)

        l_iCurrentDataVersion := :GetSchemaDefinitionVersion("Core")

        with object l_oDB1
            :Table("cf798fea-198b-4831-aafa-55d6135dfed1","FastCGIRunLog")
            :Field("FastCGIRunLog.dati"              ,{"S","now()"})
            :Field("FastCGIRunLog.ApplicationVersion",BUILDVERSION)
            :Field("FastCGIRunLog.IP"                ,::RequestSettings["ClientIP"])
            :Field("FastCGIRunLog.OSInfo"            ,OS())
            :Field("FastCGIRunLog.HostInfo"          ,hb_osCPU())
            if :Add()
                iFastCGIRunLogPk := :Key()
            endif
        endwith

        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 1
            with object l_oDB1
                :Table("58b648b9-ec53-40ba-8e29-a8b4e99beb36","Diagram")
                :Column("Diagram.pk" , "pk")
                :Where([Length(Trim(Diagram.LinkUID)) = 0])
                :SQL("ListOfDiagramToUpdate")
                select ListOfDiagramToUpdate
                scan all
                    with object l_oDB2
                        :Table("c8e52a98-8b65-4632-8241-efc426025ca6","Diagram")
                        :Field("Diagram.LinkUID" , ::p_o_SQLConnection:GetUUIDString())
                        :Update(ListOfDiagramToUpdate->pk)
                    endwith
                endscan
            endwith
            l_iCurrentDataVersion := 1
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 4
            if ::p_o_SQLConnection:TableExists("public.Property")
                ::p_o_SQLConnection:DeleteTable("public.Property")
            endif

            if ::p_o_SQLConnection:TableExists("public.PropertyColumnMapping")
                ::p_o_SQLConnection:DeleteTable("public.PropertyColumnMapping")
            endif

            if ::p_o_SQLConnection:FieldExists("public.Model","fk_Application")
                ::p_o_SQLConnection:DeleteField("public.Model","fk_Application")
            endif

            if ::p_o_SQLConnection:FieldExists("public.UserAccessApplication","AccessLevelML")
                ::p_o_SQLConnection:DeleteField("public.UserAccessApplication","AccessLevelML")
            endif

            if ::p_o_SQLConnection:FieldExists("public.UserAccessApplication","AccessLevel")
                with object l_oDB1
                    :Table("bcc58496-5077-47ee-a955-fa5d071dd576","UserAccessApplication")
                    :Column("UserAccessApplication.pk"         ,"pk")
                    :Column("UserAccessApplication.AccessLevel","UserAccessApplication_AccessLevel")
                    :SQL("ListOfRecordsToFix")
                    select ListOfRecordsToFix
                    scan all for ListOfRecordsToFix->UserAccessApplication_AccessLevel > 0
                        with object l_oDB2
                            :Table("d4a5eada-fd4c-4d6c-ae2e-446f45be2f19","UserAccessApplication")
                            :Field("UserAccessApplication.AccessLevelDD" , ListOfRecordsToFix->UserAccessApplication_AccessLevel)
                            :Field("UserAccessApplication.AccessLevel"   , 0)
                            :Update(ListOfRecordsToFix->pk)
                        endwith
                    endscan
                endwith

                ::p_o_SQLConnection:DeleteField("public.UserAccessApplication","AccessLevel")
            endif

            l_iCurrentDataVersion := 4
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 5
            if ::p_o_SQLConnection:FieldExists("public.UserAccessApplication","AccessLevel")
                ::p_o_SQLConnection:DeleteField("public.UserAccessApplication","AccessLevel")
            endif
            l_iCurrentDataVersion := 5
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 6
            if ::p_o_SQLConnection:TableExists("public.AssociationEnd")
                ::p_o_SQLConnection:DeleteTable("public.AssociationEnd")
            endif
            l_iCurrentDataVersion := 6
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 7
            if ::p_o_SQLConnection:FieldExists("public.Attribute","fk_Association")
                ::p_o_SQLConnection:DeleteField("public.Attribute","fk_Association")
            endif

            if ::p_o_SQLConnection:FieldExists("public.Attribute","fk_Association")
                ::p_o_SQLConnection:DeleteField("public.Attribute","fk_Association")
            endif

            l_iCurrentDataVersion := 7
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 8
            if ::p_o_SQLConnection:TableExists("public.ConceptualDiagram")
                ::p_o_SQLConnection:DeleteTable("public.ConceptualDiagram")
            endif
            if ::p_o_SQLConnection:FieldExists("public.DiagramEntity","fk_ConceptualDiagram")
                ::p_o_SQLConnection:DeleteField("public.DiagramEntity","fk_ConceptualDiagram")
            endif
            l_iCurrentDataVersion := 8
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 9
            with object l_oDB1
                :Table("dcbb495b-7a14-4ba0-9d2b-eefc5a41fac3","ModelingDiagram")
                :Column("ModelingDiagram.pk" , "pk")
                :Where([Length(Trim(ModelingDiagram.LinkUID)) = 0])
                :SQL("ListOfModelingDiagramToUpdate")
                select ListOfModelingDiagramToUpdate
                scan all
                    with object l_oDB2
                        :Table("214e97ca-df84-4b5a-bf7d-f4a1ba22b24e","ModelingDiagram")
                        :Field("ModelingDiagram.LinkUID" , ::p_o_SQLConnection:GetUUIDString())
                        :Update(ListOfModelingDiagramToUpdate->pk)
                    endwith
                endscan
            endwith
            l_iCurrentDataVersion := 9
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 10
            if ::p_o_SQLConnection:FieldExists("public.Entity","Scope") .and. ::p_o_SQLConnection:FieldExists("public.Entity","Information")

                with object l_oDB1

                    :Table("bcc58496-5077-47ee-a955-fa5d071dd576","Entity")
                    :Column("Entity.pk"   ,"pk")
                    :Column("Entity.Scope","Entity_Scope")
                    :SQL("ListOfRecordsToFix")
                    select ListOfRecordsToFix
                    scan all for len(nvl(ListOfRecordsToFix->Entity_Scope,"")) > 0
                        with object l_oDB2
                            :Table("12140112-62ef-49c7-84db-c79c859d31f8","Entity")
                            :Field("Entity.Information" , ListOfRecordsToFix->Entity_Scope)
                            :Update(ListOfRecordsToFix->pk)
                        endwith
                    endscan

                endwith

                ::p_o_SQLConnection:DeleteField("public.Entity","Scope")
            endif
            l_iCurrentDataVersion := 10
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion <= 11
            if ::p_o_SQLConnection:FieldExists("public.Attribute","Order") .and. ::p_o_SQLConnection:FieldExists("public.Attribute","TreeOrder1")

                with object l_oDB1

                    :Table("405e7421-717f-45cf-b108-3f758b5d05b3","Attribute")
                    :Column("Attribute.pk"   ,"pk")
                    :Column("Attribute.Order","Attribute_Order")
                    :SQL("ListOfRecordsToFix")
                    select ListOfRecordsToFix
                    scan all
                        with object l_oDB2
                            :Table("dcbff351-7f65-416c-854e-94028fc5c67e","Attribute")
                            :Field("Attribute.TreeOrder1" , ListOfRecordsToFix->Attribute_Order)
                            :Update(ListOfRecordsToFix->pk)
                        endwith
                    endscan

                endwith

                ::p_o_SQLConnection:DeleteField("public.Attribute","Order")
            endif
            l_iCurrentDataVersion := 11
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        //-----------------------------------------------------------------------------------
        

        l_cSecuritySalt            := ::GetAppConfig("SECURITY_SALT")
        l_cSecurityDefaultPassword := ::GetAppConfig("SECURITY_DEFAULT_PASSWORD")

        //Setup first User if none exists
        
        with object l_oDB1
            :Table("994ff6fd-0f5f-48eb-a882-2bab357885a1","User")
            :Where("User.Status = 1")
            if :Count() == 0
                :Table("09f376b4-8c89-4c7a-8e59-8a59f8f32402","User")
                :Field("User.id"         , "main")
                :Field("User.FirstName"  , "main")
                :Field("User.LastName"   , "account")
                :Field("User.AccessMode" , 4)
                :Field("User.Status"     , 1)
                :Add()
            endif

            :Table("eabc5786-5394-4961-aa00-2563c2494c38","User")
            :Column("User.pk","pk")
            :Where("User.Password is null")
            :SQL("ListOfPasswordsToReset")
            if :Tally > 0
                with object l_oDB2
                    select ListOfPasswordsToReset
                    scan all
                        :Table("7d6e5721-ec9b-46c1-9c5a-e8239a406e32","User")
                        :Field("User.Password" , hb_SHA512(l_cSecuritySalt+l_cSecurityDefaultPassword+Trans(ListOfPasswordsToReset->pk)))
                        :Update(ListOfPasswordsToReset->pk)
                    endscan
                endwith
            endif

        endwith
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
local l_cID
local l_cPassword
local l_oDB1
local l_cSessionCookie
local l_iUserPk
local l_cUserName
local l_nUserAccessMode
local l_nLoginLogsPk
local l_cAction
local l_oData
local l_cSignature
local l_cIP := ::RequestSettings["ClientIP"]
local l_nLoginOutUserPk
local l_aWebPageHandle
local l_aPathElements
local l_iLoop
local l_cAjaxAction
local l_cThisAppTitle
local l_cSecuritySalt
local l_lCyanAuditAware         := (upper(left(::GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
local l_cPostgresHost           := ::GetAppConfig("POSTGRESHOST")
local l_iPostgresPort           := val(::GetAppConfig("POSTGRESPORT"))
local l_cPostgresDatabase       := ::GetAppConfig("POSTGRESDATABASE")
local l_cPostgresId             := ::GetAppConfig("POSTGRESID")
local l_lPostgresLostConnection
local l_TimeStamp1 := hb_DateTime()
local l_TimeStamp2
local l_lShowDevelopmentInfo := .f.
static l_lGetUUIDSupported := .f.  // Used to ensure the PostgreSQL database has the "pgcrypto" extension installed.
local l_cAccessToken
local l_sAPIFunction

SendToDebugView("Request Counter",::RequestCount)

::SetHeaderValue("X-Frame-Options","DENY")  // To help prevent clickhacking, meaning to place the web site into an frame of another site.

//Reset transient properties

::p_iUserPk         := 0
::p_cUserName       := ""
::p_nUserAccessMode := 0
::p_nAccessLevelDD  := 0

//Since the OnFirstRequest method only runs on first request, on following request have to check if connection is still active, and not terminated by the SQL Server.
l_lPostgresLostConnection := (::p_o_SQLConnection == NIL) .or. (::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected())
if l_lPostgresLostConnection                                    .or.;
   (::p_o_SQLConnection:GetServer()   <> l_cPostgresHost)     .or.;
   (::p_o_SQLConnection:GetPort()     <> l_iPostgresPort)     .or.;
   (::p_o_SQLConnection:GetDatabase() <> l_cPostgresDatabase) .or.;
   (::p_o_SQLConnection:GetUser()     <> l_cPostgresId)

    if !l_lPostgresLostConnection
        ::p_o_SQLConnection:Disconnect()
    endif

////    SendToDebugView("Reconnecting to SQL Server")
    ::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",;
                                        ,;
                                        l_cPostgresHost,;
                                        l_iPostgresPort,;
                                        l_cPostgresId,;
                                        ::GetAppConfig("POSTGRESPASSWORD"),;
                                        l_cPostgresDatabase,;
                                        "public";
                                        )
    with object ::p_o_SQLConnection
        :PostgreSQLHBORMSchemaName  := "ORM"
        :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
        :SetPrimaryKeyFieldName("pk")

        if :Connect() >= 0
            UpdateSchema(::p_o_SQLConnection)
////            SendToDebugView("Reconnected to SQL Server")
        else
            ::p_o_SQLConnection := NIL
        endif
    endwith
endif

if ::p_o_SQLConnection == NIL
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Failed to connect to Data Server</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

else
    //Test GetUUIDString is Supported
    if !l_lGetUUIDSupported
        if !empty(::p_o_SQLConnection:GetUUIDString())
            l_lGetUUIDSupported := .t.
        endif
    endif

    if !l_lGetUUIDSupported
        l_cHtml := [<html>]
        l_cHtml += [<body>]
        l_cHtml += [<h1>Data Server is missing the "pgcrypto" extension</h1>]
        l_cHtml += [<p>Execute the "CREATE EXTENSION pgcrypto;" command on the database.</p>]
        l_cHtml += [</body>]
        l_cHtml += [</html>]

    else

        if l_lCyanAuditAware
            //Ensure no user specific cyanaudit is being identified
            ::p_o_SQLConnection:SQLExec("SELECT cyanaudit.fn_set_current_uid( 0 );")
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

        // ::URLPathElements := {}
        //Following is Buggy
        // if len(l_aPathElements) > 1
        //     ACopy(l_aPathElements,::URLPathElements,2,len(l_aPathElements)-1)
        // endif

        // for l_iLoop := 1 to len(l_aPathElements)
        //     AAdd(::URLPathElements,l_aPathElements[l_iLoop])
        // endfor

        // if l_cPageName <> "ajax"
        if !VFP_Inlist(lower(l_cPageName),"ajax","api")

            l_aWebPageHandle := hb_HGetDef(v_hPageMapping, l_cPageName, {"Home",1,@BuildPageHome()})
            // #define WEBPAGEHANDLE_NAME            1
            // #define WEBPAGEHANDLE_ACCESSMODE      2
            // #define WEBPAGEHANDLE_FUNCTIONPOINTER 3

            ::p_cHeader       := ""
            ::p_cjQueryScript := ""


            // l_cPageHeaderHtml += [<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=UTF-8">]

            l_cThisAppTitle := ::GetAppConfig("APPLICATION_TITLE")
            if empty(l_cThisAppTitle)
                l_cThisAppTitle := APPLICATION_TITLE
            endif

            l_cPageHeaderHtml += [<meta http-equiv="X-UA-Compatible" content="IE=edge">]
            l_cPageHeaderHtml += [<meta http-equiv="Content-Type" content="text/html;charset=utf-8">]
            l_cPageHeaderHtml += [<title>]+l_cThisAppTitle+[</title>]

            l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_5_0_2/css/bootstrap.min.css">]

            l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_5_0_2/icons/font/bootstrap-icons.css">]

            l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/jQueryUI_1_12_1_NoTooltip/Themes/smoothness/jQueryUI.css">]
            l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[datawharf.css">]

            l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQuery_3_6_0/jquery.min.js"></script>]
            l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/Bootstrap_5_0_2/js/bootstrap.bundle.min.js"></script>]

            // l_cPageHeaderHtml += [<script>$.fn.bootstrapBtn = $.fn.button.noConflict();</script>]
            l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQueryUI_1_12_1_NoTooltip/jquery-ui.min.js"></script>]

            ::p_cHeader := l_cPageHeaderHtml
        endif

        l_cPageHeaderHtml := NIL  //To free memory

        l_oDB1       := hb_SQLData(::p_o_SQLConnection)
        l_cSessionID := ::GetCookieValue("SessionID")
        l_cAction    := ::GetQueryString("action")

        with object l_oDB1
            :Table("ea9c6e26-008e-4cad-ae70-28257020c27e","FastCGIRunLog")
            :Field("FastCGIRunLog.RequestCount"      ,{"S",'"RequestCount" + 1'})
            :Update(iFastCGIRunLogPk)
        endwith

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
                        endscan
                        CloseAlias("ListOfResults")
                    // else
                    endif
                endif
                ::DeleteCookie("SessionID")
                ::Redirect(::RequestSettings["SitePath"]+"home")
                return nil
            endif
        endif

        l_lLoggedIn       := .f.
        l_cUserName       := ""
        l_nUserAccessMode := 0

        if !empty(l_cSessionID) .and. !VFP_Inlist(lower(l_cPageName),"api")
            l_nPos               := at("-",l_cSessionID)
            l_nLoggedInPk        := val(left(l_cSessionID,l_nPos))
            l_cLoggedInSignature := Trim(substr(l_cSessionID,l_nPos+1))
            if !empty(l_nLoggedInPk)
                // Verify if valid loggin
                l_oDB1:Table("4edc82f8-f58e-4013-98a3-22732b408319","public.LoginLogs")
                l_oDB1:Column("LoginLogs.Status","LoginLogs_Status")
                l_oDB1:Column("User.pk"         ,"User_pk")
                l_oDB1:Column("User.FirstName"  ,"User_FirstName")
                l_oDB1:Column("User.LastName"   ,"User_LastName")
                l_oDB1:Column("User.AccessMode" ,"User_AccessMode")
                l_oDB1:Where("LoginLogs.pk = ^",l_nLoggedInPk)
                l_oDB1:Where("Trim(LoginLogs.Signature) = ^",l_cLoggedInSignature)
                l_oDB1:Where("User.Status = 1")
                l_oDB1:Join("inner","User","","LoginLogs.fk_User = User.pk")
                l_oDB1:SQL("ListOfResults")
                if l_oDB1:Tally = 1
                    l_lLoggedIn       := .t.
                    l_iUserPk         := ListOfResults->User_pk
                    l_cUserName       := AllTrim(ListOfResults->User_FirstName)+" "+AllTrim(ListOfResults->User_LastName)
                    l_nUserAccessMode := ListOfResults->User_AccessMode
                else
                    // Clear the cookie
                    ::DeleteCookie("SessionID")
                endif
                CloseAlias("ListOfResults")
            endif
        endif
        
        // if l_cPageName <> "ajax"
        if !VFP_Inlist(lower(l_cPageName),"ajax","api")
            //If not a public page and not logged in, then request to log in.
            if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSMODE] > 0 .and. !l_lLoggedIn
                if oFcgi:IsGet()
                    l_cBody += GetPageHeader(.f.,l_cPageName)
                    l_cBody += BuildPageLoginScreen()
                else
                    //Post
                    l_cID             := SanitizeInput(oFcgi:GetInputValue("TextID"))
                    l_cPassword       := SanitizeInput(oFcgi:GetInputValue("TextPassword"))

                    with object l_oDB1
                        :Table("6bad4ae5-6bb2-4bdb-97b9-6adacb2a8327","public.User")
                        :Column("User.pk"        ,"User_pk")
                        :Column("User.FirstName" ,"User_FirstName")
                        :Column("User.LastName"  ,"User_LastName")
                        :Column("User.Password"  ,"User_Password")
                        :Column("User.AccessMode","User_AccessMode")
                        :Where("trim(User.id) = ^",l_cID)
                        // :Where("trim(User.Password) = ^",l_cPassword)
                        :Where("User.Status = 1")
                        :SQL("ListOfResults")

                        if :Tally == 1
                            l_iUserPk := ListOfResults->User_Pk

                            //Check if valid Password
                            l_cSecuritySalt := oFcgi:GetAppConfig("SECURITY_SALT")

                            if Trim(ListOfResults->User_Password) == hb_SHA512(l_cSecuritySalt+l_cPassword+Trans(l_iUserPk))
                                l_cUserName       := AllTrim(ListOfResults->User_FirstName)+" "+AllTrim(ListOfResults->User_LastName)
                                l_cSignature      := ::GenerateRandomString(10,"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
                                l_nUserAccessMode := ListOfResults->User_AccessMode

                                :Table("a58f5d2a-929a-4327-8694-9656377638ec","LoginLogs")
                                :Field("LoginLogs.fk_User"  ,l_iUserPk)
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
                                //Invalid Password
                                l_cBody += GetPageHeader(.f.,l_cPageName)
                                l_cBody += BuildPageLoginScreen(l_cID,"","Invalid ID or Password.1")
                            endif
                        else
                            //Invalid Active ID
                            l_cBody += GetPageHeader(.f.,l_cPageName)
                            l_cBody += BuildPageLoginScreen(l_cID,"","Invalid ID or Password.2")
                        endif

                    endwith

                endif
            endif
        endif

        if l_lLoggedIn
            ::p_iUserPk         := l_iUserPk
            ::p_cUserName       := l_cUserName
            ::p_nUserAccessMode := l_nUserAccessMode

            //Since we now know the current user access mode, will check if this would be an invalid access right.
            if ((::p_nUserAccessMode < 4) .and. lower(l_cPageName) == "users")         .or. ;  // block from going to "Users" web page, unless "Root Admin" access right.
            ((::p_nUserAccessMode < 3) .and. lower(l_cPageName) == "customfields")          // block from going to "CustomFields" web page, unless "All Application Full Access access right.
                ::Redirect(::RequestSettings["SitePath"]+"home")
                return nil
            endif

            if l_lCyanAuditAware
                //Tell Cyanaudit to log future entries as the current user.
                ::p_o_SQLConnection:SQLExec("SELECT cyanaudit.fn_set_current_uid( "+Trans(::p_iUserPk)+" );")
            endif
            
            if l_cPageName == "ajax"
                l_cBody := [UNBUFFERED]
                if len(::p_URLPathElements) >= 2 .and. !empty(::p_URLPathElements[2])
                    l_cAjaxAction := ::p_URLPathElements[2]

                    switch l_cAjaxAction
                    // case "VisualizationPositions"
                    //     l_cBody += SaveVisualizationPositions()
                    //     exit
                    case "GetDDInfo"
                        l_cBody += GetDDInfoDuringVisualization()
                        exit
                    case "GetMLInfo"
                        l_cBody += GetMLInfoDuringVisualization()
                        exit
                    endswitch

                endif
            else
                l_cBody += GetPageHeader(.t.,l_cPageName)

                l_cBody += l_aWebPageHandle[WEBPAGEHANDLE_FUNCTIONPOINTER]:exec()

                l_lShowDevelopmentInfo := (upper(left(oFcgi:GetAppConfig("ShowDevelopmentInfo"),1)) == "Y")
                if l_lShowDevelopmentInfo
                    l_cBody += [<div class="m-3">]   //Spacer
                        if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSMODE] > 0  //Logged in page
                            l_cBody += "<div>Web Site Version: " + BUILDVERSION + "</div>"
                        endif
                        l_cBody += [<div>Site Build Info: ]+hb_buildinfo()+[</div>]
                        l_cBody += [<div>ORM Build Info: ]+hb_orm_buildinfo()+[</div>]
                        l_cBody += [<div>VFP Build Info: ]+hb_vfp_buildinfo()+[</div>]
                        l_cBody += [<div>PostgreSQL Host: ]+oFcgi:GetAppConfig("POSTGRESHOST")+[</div>]
                        l_cBody += [<div>PostgreSQL Database: ]+oFcgi:GetAppConfig("POSTGRESDATABASE")+[</div>]
                        l_cBody += ::TraceList(4)
                    l_cBody += [</div>]   //Spacer
                endif
            endif
        else
            //Not Logged In
            if l_cPageName == "ajax"
                l_cBody := [UNBUFFERED Not Logged In]
            elseif l_cPageName == "api"
                // Check for tocken
                l_cAccessToken := oFcgi:GetHeaderValue("AccessToken")
                l_cBody := [UNBUFFERED]

                if l_cAccessToken <> "0123456789"
                    l_cBody += [Invalid Access Token]

                else
                    l_sAPIFunction := hb_HGetDef(oFcgi:p_APIs,GetAPIURIElement(1),NIL)   // Use the first URL element after /api/
                    if hb_IsNIL(l_sAPIFunction)
                        l_cBody += [Invalid API Call]
                    else
                        oFcgi:SetContentType("application/json")
                        l_cBody += l_sAPIFunction:exec()
                    endif

                endif
            else
                ::p_nUserAccessMode := 0
                if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSMODE] == 0   //public page
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

            if l_lShowDevelopmentInfo
                l_TimeStamp2  := hb_DateTime()
                l_cHtml += [<div class="m-3">Run Time = ]+trans(int((l_TimeStamp2-l_TimeStamp1)*(24*3600*1000)))+[ (ms)</div>]
            endif

            l_cHtml += [</body>]
            l_cHtml += [</html>]

        endif
    endif
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
local l_oDB1
local l_lPostgresLostConnection
local l_cErrorInfo

    try
////        SendToDebugView("Called from MyFcgi OnError")
        ::ClearOutputBuffer()
        ::Print("<h1>Error Occurred</h1>")
        ::Print("<h2>"+hb_buildinfo()+" - Current Time: "+hb_DToC(hb_DateTime())+"</h2>")
        l_cErrorInfo := FcgiGetErrorInfo(par_oError)
        ::Print("<div>"+l_cErrorInfo+"</div>")
        ::Print("<div>FastCGIRunLog.pk = "+Trans(nvl(iFastCGIRunLogPk,0))+"</div>")
        ::Print("<div>"+::TraceList(4)+"</div>")

        //  ::hb_Fcgi:OnError(par_oError)
        ::Finish()

        if !empty(l_cErrorInfo)
            l_lPostgresLostConnection := (::p_o_SQLConnection == NIL) .or. (::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected())
            if !l_lPostgresLostConnection
                l_oDB1 := hb_SQLData(::p_o_SQLConnection)
                with object l_oDB1
                    :Table("94c6f301-f0db-4cce-b0b7-15fd49ad29ba","FastCGIRunLog")
                    :Field("FastCGIRunLog.ErrorInfo",l_cErrorInfo)
                    :Update(iFastCGIRunLogPk)
                endwith
            endif
        endif

    catch
    endtry
    
    BREAK
return nil
//=================================================================================================================
function UpdateSchema(par_o_SQLConnection)
local l_LastError := ""
local l_Schema
local l_nMigrateSchemaResult := 0
local l_lCyanAuditAware

#include "Schema.txt"

if el_AUnpack(par_o_SQLConnection:MigrateSchema(l_Schema),@l_nMigrateSchemaResult,,@l_LastError) > 0
    if l_nMigrateSchemaResult == 1
        l_lCyanAuditAware := (upper(left(oFcgi:GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
        if l_lCyanAuditAware
            //Ensure Cyanaudit is up to date
            oFcgi:p_o_SQLConnection:SQLExec("SELECT cyanaudit.fn_update_audit_fields('public');")
////            SendToDebugView("PostgreSQL - Updated Cyanaudit triggers")
        endif
    endif
else
    if !empty(l_LastError)
////        SendToDebugView("PostgreSQL - Failed Migrate")
    endif
endif

return nil
//=================================================================================================================
function GetPageHeader(par_LoggedIn,par_cCurrentPage)
local l_cHtml := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

local l_cThisAppTitle                 := oFcgi:GetAppConfig("APPLICATION_TITLE")
local l_cThisAppColorHeaderBackground := oFcgi:GetAppConfig("COLOR_HEADER_BACKGROUND")
local l_cThisAppColorHeaderTextWhite  := oFcgi:GetAppConfig("COLOR_HEADER_TEXT_WHITE")
local l_lThisAppColorHeaderTextWhite

local l_lShowMenuProjects         := par_LoggedIn .and. (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
local l_lShowMenuApplications     := par_LoggedIn .and. (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
local l_lShowMenuModeling         := l_lShowMenuProjects
local l_lShowMenuDataDictionaries := l_lShowMenuApplications

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

local l_cExtraClass

if empty(l_cThisAppTitle)
    l_cThisAppTitle := APPLICATION_TITLE
endif
if empty(l_cThisAppColorHeaderBackground)
    l_cThisAppColorHeaderBackground := COLOR_HEADER_BACKGROUND
endif
if empty(l_cThisAppColorHeaderTextWhite)
    l_lThisAppColorHeaderTextWhite := COLOR_HEADER_TEXT_WHITE
else
    l_lThisAppColorHeaderTextWhite := ("T" $ upper(l_cThisAppColorHeaderTextWhite))
endif

if par_LoggedIn
    if !l_lShowMenuProjects
        with object l_oDB1
            :Table("859d058d-4207-41d2-840c-7e294326f84e","UserAccessProject")
            :Column("SUM(CASE WHEN (UserAccessProject.AccessLevelML >= 7) THEN 1 ELSE 0 END)" , "NumberOfFullAccess")
            :Column("SUM(CASE WHEN (UserAccessProject.AccessLevelML >= 1) THEN 1 ELSE 0 END)" , "NumberOfAnyAccess")
            :Where("UserAccessProject.fk_User = ^" , oFcgi:p_iUserPk)
            l_oData := :SQL()
            if :Tally == 1
                l_lShowMenuProjects := (nvl(l_oData:NumberOfFullAccess,0) > 0)
                l_lShowMenuModeling := (nvl(l_oData:NumberOfAnyAccess,0)  > 0)
            endif
        endwith
    endif

    if !l_lShowMenuApplications
        with object l_oDB1
            :Table("6de8102c-3f35-45bd-9a29-6b4875edd24a","UserAccessApplication")
            :Column("SUM(CASE WHEN (UserAccessApplication.AccessLevelDD >= 7) THEN 1 ELSE 0 END)" , "NumberOfFullAccess")
            :Column("SUM(CASE WHEN (UserAccessApplication.AccessLevelDD >= 1) THEN 1 ELSE 0 END)" , "NumberOfAnyAccess")
            :Where("UserAccessApplication.fk_User = ^" , oFcgi:p_iUserPk)
            l_oData := :SQL()
            if :Tally == 1
                l_lShowMenuApplications     := (nvl(l_oData:NumberOfFullAccess,0) > 0)
                l_lShowMenuDataDictionaries := (nvl(l_oData:NumberOfAnyAccess,0)  > 0)
            endif
        endwith
    endif
endif

l_cExtraClass := iif(l_lThisAppColorHeaderTextWhite," text-white","")


l_cHtml += [<header class="d-flex flex-wrap align-items-center justify-content-center justify-content-md-between py-3 navbar-light navbar" style="background-color: #]+l_cThisAppColorHeaderBackground+[;">]
    l_cHtml += [<div id="app" class="container" >]
        l_cHtml += [<a class="d-flex align-items-center mb-2 mb-md-0]+l_cExtraClass+[ navbar-brand" href="#">]+l_cThisAppTitle+[</a>]
        if par_LoggedIn
            //l_cHtml += [<div class="collapse navbar-collapse" id="navbarNav">]
                l_cHtml += [<ul class="nav col-12 col-md-auto mb-2 justify-content-center mb-md-0">]
                    l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "home"               ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Home">Home</a></li>]

                    if l_lShowMenuModeling
                        l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "modeling"           ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Modeling">Modeling</a></li>]
                    endif

                    if l_lShowMenuDataDictionaries
                        l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "datadictionaries"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[DataDictionaries">Data Dictionaries</a></li>]
                    endif

                    if (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
                        l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "interappmapping"    ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[InterAppMapping">Inter-App Mapping</a></li>]
                    endif

                    l_cHtml += [<li class="nav-item dropdown "><a class="nav-link link-dark dropdown-toggle" href="#" id="navbarDropdownMenuLinkAdmin" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Settings</a>]
                    l_cHtml += [<ul class="dropdown-menu" style="z-index: 1030;" aria-labelledby="navbarDropdownMenuLinkAdmin">]
                        if l_lShowMenuProjects
                            l_cHtml += [<li><a class="dropdown-item]+l_cExtraClass+iif(lower(par_cCurrentPage) == "projects"       ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Projects">Projects</a></li>]
                        endif

                        if l_lShowMenuApplications
                            l_cHtml += [<li><a class="dropdown-item]+l_cExtraClass+iif(lower(par_cCurrentPage) == "applications"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Applications">Applications</a></li>]
                        endif

                        if (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
                            l_cHtml += [<li><a class="dropdown-item]+l_cExtraClass+iif(lower(par_cCurrentPage) == "customfields"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[CustomFields">Custom Fields</a></li>]
                        endif

                        if (oFcgi:p_nUserAccessMode >= 4) // "Root Admin" access right.
                            l_cHtml += [<li><a class="dropdown-item]+l_cExtraClass+iif(lower(par_cCurrentPage) == "users"          ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Users">Users</a></li>]
                        endif
                        l_cHtml += [<li><a class="dropdown-item]+l_cExtraClass+iif(lower(par_cCurrentPage) == "changepassword"     ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[ChangePassword">Change Password</a></li>]
                        
                    l_cHtml += [</ul>]
                    l_cHtml += [</li>]

                    l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "about"               ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[About">About</a></li>]

                l_cHtml += [</ul>]
                l_cHtml += [<div class="text-end">]
                    l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[home?action=logout">Logout (]+oFcgi:p_cUserName+iif(oFcgi:p_nUserAccessMode < 1," / View Only","")+[)</a>]
                l_cHtml += [</div>]
            //l_cHtml += [</div>]
        endif
    l_cHtml += [</div>]    
l_cHtml += [</header>]


// l_cHtml += [<div class="m-3"></div>]   //Spacer

return l_cHtml
//=================================================================================================================
function hb_buildinfo()
#include "BuildInfo.txt"
return l_cBuildInfo
//=================================================================================================================
function SanitizeInput(par_text)
local l_result := AllTrim(vfp_StrReplace(par_text,{chr(9)=>" "}))
l_result = vfp_StrReplace(l_result,{"<"="",">"=""})
return l_result
//=================================================================================================================
function SanitizeInputAlphaNumeric(par_cText)
return SanitizeInputWithValidChars(par_cText,[_01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ])
//=================================================================================================================
function SanitizeInputWithValidChars(par_text,par_cValidChars)
local l_result := []
local l_nPos
local l_cChar
for l_nPos := 1 to len(par_text)
    l_cChar := substr(par_text,l_nPos,1)
    if l_cChar $ par_cValidChars
        l_result += l_cChar
    endif
endfor
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

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data" class="form-horizontal">]

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
                    l_cHtml += [<input class="form-control" type="text" name="TextID" id="TextID" placeholder="Enter your User ID" maxlength="100" size="30" value="]+FcgiPrepFieldForValue(l_cID)+[" autocomplete="off">]
                l_cHtml += [</div>]
            l_cHtml += [</div>]

            l_cHtml += [<div class="form-group has-success mt-4">]
                l_cHtml += [<label class="control-label" for="TextPassword">Password</label>]
                l_cHtml += [<div class="mt-2">]
                    l_cHtml += [<input class="form-control" type="password" name="TextPassword" id="TextPassword" placeholder="Enter your password" maxlength="200" size="30" value="]+FcgiPrepFieldForValue(l_cPassword)+[" autocomplete="off">]
                l_cHtml += [</div>]
            l_cHtml += [</div>]

            l_cHtml += [<div class="mt-4">]
                l_cHtml += [<span><input type="submit" class="btn btn-primary" value="Login" onclick="$('#ActionOnSubmit').val('Login');document.form.submit();" role="button"></span>]
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
return iif(!hb_IsNIL(par_iPos) .and. par_iPos > 0 .and. par_iPos <= Len(par_aValues), par_aValues[par_iPos], par_xDefault)
//=================================================================================================================
function MultiLineTrim(par_cText)
local l_nPos := len(par_cText)

do while l_nPos > 0 .and. vfp_inlist(Substr(par_cText,l_nPos,1),chr(13),chr(10),chr(9),chr(32))
    l_nPos -= 1
enddo

return left(par_cText,l_nPos)
//=================================================================================================================
function FormatAKAForDisplay(par_cAKA)
return iif(!hb_IsNIL(par_cAKA) .and. !empty(par_cAKA),[&nbsp;(]+Strtran(par_cAKA,[ ],[&nbsp;])+[)],[])
//=================================================================================================================
function SaveUserSetting(par_cName,par_cValue)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}

with object l_oDB1
    :Table("0afe8937-b79b-4359-b630-dc58ef6aed78","UserSetting")
    :Column("UserSetting.pk" , "pk")
    :Column("UserSetting.ValueC" , "ValueC")
    :Where("UserSetting.fk_User = ^" , oFcgi:p_iUserPk)
    :Where("UserSetting.KeyC = ^" , par_cName)
    :SQL(@l_aSQLResult)
    
    if empty(par_cValue)
        //To delete the Setting
        if :Tally == 1
            :Delete("808518b2-81c6-460b-96ae-27c7cd550447","UserSetting",l_aSQLResult[1,1])
        endif
    else
        do case
        case :Tally  < 0
        case :Tally == 0
            :Table("cc66e1c9-cc6d-4442-812e-0711e02a5811","UserSetting")
            :Field("UserSetting.fk_User",oFcgi:p_iUserPk)
            :Field("UserSetting.KeyC"   ,par_cName)
            :Field("UserSetting.ValueC" ,par_cValue)
            :Add()
        case :Tally == 1
            if l_aSQLResult[1,2] <> par_cValue
                :Table("a33aeb73-8c9c-42a4-aa1f-3584547f4ba8","UserSetting")
                :Field("UserSetting.ValueC" , par_cValue)
                :Update(l_aSQLResult[1,1])
            endif
        otherwise
            // Bad data, more than 1 record.
        endcase
    endif
endwith

return NIL
//=================================================================================================================
function GetUserSetting(par_cName)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_cValue := ""

with object l_oDB1
    :Table("fbfc0172-e47a-4bce-b798-9eff0344c3a5","UserSetting")
    :Column("UserSetting.ValueC" , "ValueC")
    :Where("UserSetting.fk_User = ^" , oFcgi:p_iUserPk)
    :Where("UserSetting.KeyC = ^" , par_cName)
    :SQL(@l_aSQLResult)
    
    do case
    case :Tally  < 0
    case :Tally == 0
    case :Tally == 1
        l_cValue := l_aSQLResult[1,1]
    otherwise
        // Bad data, more than 1 record.
    endcase
endwith

return l_cValue
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CheckIfAllowDestructiveApplicationDelete(par_iApplicationPk)
local l_AllowDestructiveDelete := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData
//Check if the application as AllowDestructiveDelete set to true
with object l_oDB1
    :Table("599b29b4-8bd9-4380-bd51-8ad5a6c35c91","Application")
    :Column("Application.AllowDestructiveDelete" , "Application_AllowDestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_AllowDestructiveDelete := l_oData:Application_AllowDestructiveDelete
    endif
endwith
return l_AllowDestructiveDelete
//=================================================================================================================
function CheckIfAllowDestructiveModelDelete(par_iModelPk)
local l_AllowDestructiveDelete := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData
//Check if the model as AllowDestructiveDelete set to true
with object l_oDB1
    :Table("4c418c2f-79a1-40cf-ac79-21d17a0edc57","Model")
    :Column("Model.AllowDestructiveDelete" , "Model_AllowDestructiveDelete")
    l_oData := :Get(par_iModelPk)
    if :Tally == 1
        l_AllowDestructiveDelete := l_oData:Model_AllowDestructiveDelete
    endif
endwith
return l_AllowDestructiveDelete
//=================================================================================================================
function SetSelect2Support()

//Code in progress see WebPage_InterAppMapping.prg

local l_cSitePath    := oFcgi:RequestSettings["SitePath"]
local l_ScriptFolder

l_ScriptFolder := l_cSitePath+[scripts/jQuerySelect2_2022_01_01/]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[select2.min.css">]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[select2-bootstrap-5-theme.min.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[select2.full.min.js"></script>]

// See https://stackoverflow.com/questions/25882999/set-focus-to-search-text-field-when-we-click-on-select-2-drop-down
oFcgi:p_cjQueryScript += [$(document).on('select2:open', () => { document.querySelector('.select2-search__field').focus();  });]

return NIL
//=================================================================================================================
function EscapeNewlineAndQuotes(par_cText)
local l_cText
if hb_IsNIL(par_cText)
    l_cText := ""
else
    l_cText := hb_StrReplace(par_cText,{[\]=>[\\],["]=>[\"],[']=>[\'],chr(10)=>[],chr(13)=>[\n]})
endif
return l_cText
//=================================================================================================================
function GetMultiEdgeCurvatureJSon(par_nMultiEdgeTotalCount,par_nMultiEdgeCount)
local l_cJSon := ""
do case
case par_nMultiEdgeTotalCount == 2
    do case
    case par_nMultiEdgeCount == 1
        l_cJSon += [,smooth: {type: 'curvedCW', roundness: 0.15}]
    case par_nMultiEdgeCount == 2
        l_cJSon += [,smooth: {type: 'curvedCCW', roundness: 0.15}]
    endcase
case par_nMultiEdgeTotalCount == 3
    do case
    case par_nMultiEdgeCount == 1
    case par_nMultiEdgeCount == 2
        l_cJSon += [,smooth: {type: 'curvedCW', roundness: 0.2}]
    case par_nMultiEdgeCount == 3
        l_cJSon += [,smooth: {type: 'curvedCCW', roundness: 0.2}]
    endcase
case par_nMultiEdgeTotalCount == 4
    do case
    case par_nMultiEdgeCount == 1
        l_cJSon += [,smooth: {type: 'curvedCW', roundness: 0.11}]
    case par_nMultiEdgeCount == 2
        l_cJSon += [,smooth: {type: 'curvedCW', roundness: 0.3}]
    case par_nMultiEdgeCount == 3
        l_cJSon += [,smooth: {type: 'curvedCCW', roundness: 0.11}]
    case par_nMultiEdgeCount == 4
        l_cJSon += [,smooth: {type: 'curvedCCW', roundness: 0.3}]
    endcase
endcase
return l_cJSon
//=================================================================================================================
function GetAccessLevelMLForProject(par_iProjectPk)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_nAccessLevelML := 0
do case
case oFcgi:p_nUserAccessMode <= 1  // Project access levels
    with object l_oDB1
        :Table("b64f780e-dd6a-4409-878a-dd3de257a440","UserAccessProject")
        :Column("UserAccessProject.AccessLevelML" , "AccessLevelML")
        :Where("UserAccessProject.fk_User = ^"    ,oFcgi:p_iUserPk)
        :Where("UserAccessProject.fk_Project = ^" ,par_iProjectPk)
        :SQL(@l_aSQLResult)
        if l_oDB1:Tally == 1
            l_nAccessLevelML := l_aSQLResult[1,1]
        else
            l_nAccessLevelML := 0
        endif
    endwith
case oFcgi:p_nUserAccessMode  = 2  // All Project Read Only
    l_nAccessLevelML := 2
case oFcgi:p_nUserAccessMode  = 3  // All Project Full Access
    l_nAccessLevelML := 7
case oFcgi:p_nUserAccessMode  = 4  // Root Admin (User Control)
    l_nAccessLevelML := 7
endcase
return l_nAccessLevelML
//=================================================================================================================
function GetAccessLevelDDForApplication(par_iApplicationPk)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_nAccessLevelDD := 0
do case
case oFcgi:p_nUserAccessMode <= 1  // Application access levels
    with object l_oDB1
        :Table("b5c9e3b7-9363-40d6-9831-d98a010425af","UserAccessApplication")
        :Column("UserAccessApplication.AccessLevelDD" , "AccessLevelDD")
        :Where("UserAccessApplication.fk_User = ^"        ,oFcgi:p_iUserPk)
        :Where("UserAccessApplication.fk_Application = ^" ,par_iApplicationPk)
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
return l_nAccessLevelDD
//=================================================================================================================
function GetAPIURIElement(par_nElementNumber) // After the API Name
// Example:  /api/GetProjects
local l_cResult
if len(oFcgi:p_URLPathElements) >= 1 + par_nElementNumber
    l_cResult := oFcgi:p_URLPathElements[1 + par_nElementNumber]
else
    l_cResult := ""
endif
return l_cResult
//=================================================================================================================

