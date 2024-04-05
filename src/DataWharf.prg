//Copyright (c) 2024 Eric Lendvai MIT License

#include "DataWharf.ch"

request HB_CODEPAGE_UTF8

memvar v_iFastCGIRunLogPk
memvar v_hPageMapping

//=================================================================================================================
Function Main()

private oFcgi

private v_iFastCGIRunLogPk := 0    // Will be the FastCGIRunLog.pk of the current executing exe.

//The following Hash will have per web page name (url) an array that consists of {Page Title,Minimum User Access Level,IncludeHeader,PointerToFunctionToBuildThePage}
//User Access Levels: 0 = public, 1 = logged in, 2 = Admin
private v_hPageMapping := {"home"             => {"Home"                     ,1,.t.,@BuildPageHome()},;
                           "About"            => {"About"                    ,0,.t.,@BuildPageAbout()},;   //Does not require to be logged in.
                           "ChangePassword"   => {"Change Password"          ,1,.t.,@BuildPageChangePassword()},;
                           "Projects"         => {"Projects"                 ,1,.t.,@BuildPageProjects()},;
                           "Project"          => {"Projects"                 ,1,.t.,@BuildPageProjects()},;
                           "Applications"     => {"Applications"             ,1,.t.,@BuildPageApplications()},;
                           "Application"      => {"Applications"             ,1,.t.,@BuildPageApplications()},;
                           "Modeling"         => {"Modeling"                 ,1,.t.,@BuildPageModeling()},;
                           "DataDictionaries" => {"DataDictionaries"         ,1,.t.,@BuildPageDataDictionaries()},;
                           "DataDictionary"   => {"DataDictionaries"         ,1,.t.,@BuildPageDataDictionaries()},;
                           "InterAppMapping"  => {"Inter Application Mapping",1,.t.,@BuildPageInterAppMapping()},;
                           "CustomFields"     => {"Custom Fields"            ,1,.t.,@BuildPageCustomFields()},;
                           "Users"            => {"Users"                    ,1,.t.,@BuildPageUsers()},;
                           "APITokens"        => {"API Tokens"               ,1,.t.,@BuildPageAPITokens()},;
                           "DataWharfErrors"  => {"Recent Errors"            ,1,.t.,@BuildPageDataWharfErrors()},;
                           "Health"           => {"Health"                   ,0,.f.,@BuildPageHealth()} }   //Does not require to be logged in.

hb_HCaseMatch(v_hPageMapping,.f.)

SendToDebugView("Starting DataWharf FastCGI App")

hb_cdpSelect("UTF8")

set century on

hb_DirCreate(el_AddPs(OUTPUT_FOLDER))

oFcgi := MyFcgi():New()    // Used a subclass of hb_Fcgi

hb_HCaseMatch(oFcgi:p_APIs,.f.)

do while oFcgi:Wait()
    if !oFcgi:SkipRequest
        oFcgi:OnRequest()
    endif
enddo

SendToDebugView("Ending DataWharf FastCGI App")

return nil
//=================================================================================================================
class MyFcgi from hb_Fcgi
    data p_o_SQLConnection
    data p_cHeader              init ""
    data p_cjQueryScript        init ""
    data p_iUserPk              init 0   // Current "User.pk"
    data p_cUserName            init ""  // Current logged in User Name
    data p_nUserAccessMode      init 0   // User based access level. Comes from "User.AccessMode"
    data p_nAccessLevelDD       init 0   // Current Application Data Dictionary "UserAccessApplication.AccessLevelDD if ::p_nUserAccessMode == 1 otherwise either 1 or 7
    data p_nAccessLevelML       init 0   // Current Application Modeling        "UserAccessApplication.AccessLevelDD if ::p_nUserAccessMode == 1 otherwise either 1 or 7
    data p_cSitePath            init ""  // Used to help with site relative path
    
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
    data p_ANFModelEnumeration  init "Enumeration"
    data p_ANFModelEnumerations init "Enumerations"
    data p_ANFPackage           init "Package"
    data p_ANFPackages          init "Packages"
    data p_ANFLinkedEntity      init "Linked Entity"
    data p_ANFLinkedEntities    init "Linked Entities"


    //In this app the first element of the URL is always a page name. 
    data p_URLPathElements  init ""   READONLY   //Array of URL elements. For example:   /<pagename>/<id>/<ParentName>/<ParentId>  will create a 4 element array.
    data p_PageName         init ""              //Could be altered. The original PageName is in ::p_URLPathElements[1]

    //                            {Code,Name,Show Length,Show Scale,Max Scale,Show Enums,Show Unicode,PostgreSQL Name, MySQL Name}
    data p_ColumnTypes      init {{  "I","Integer (4 bytes)"                            ,.f.,.f.,nil,.f.,.f.,"integer"                    ,"INT"                           },;
                                  { "IB","Integer Big (8 bytes)"                        ,.f.,.f.,nil,.f.,.f.,"bigint"                     ,"BIGINT"                        },;
                                  { "IS","Integer Small (2 bytes)"                      ,.f.,.f.,nil,.f.,.f.,"smallint"                   ,"SMALLINT"                      },;
                                  {  "N","Numeric"                                      ,.t.,.t.,nil,.f.,.f.,"numeric"                    ,"DECIMAL"                       },;
                                  {  "C","Character String"                             ,.t.,.f.,nil,.f.,.t.,"character"                  ,"CHAR"                          },;
                                  { "CV","Character String Varying"                     ,.t.,.f.,nil,.f.,.t.,"character varying"          ,"VARCHAR"                       },;
                                  {  "B","Binary String"                                ,.t.,.f.,nil,.f.,.f.,"bit"                        ,"BINARY"                        },;
                                  { "BV","Binary String Varying"                        ,.t.,.f.,nil,.f.,.f.,"bit varying"                ,"VARBINARY"                     },;
                                  {  "M","Memo / Long Text"                             ,.f.,.f.,nil,.f.,.t.,"text"                       ,"LONGTEXT"                      },;
                                  {  "R","Raw Binary"                                   ,.f.,.f.,nil,.f.,.f.,"bytea"                      ,"LONGBLOB"                      },;
                                  {  "L","Logical"                                      ,.f.,.f.,nil,.f.,.f.,"boolean"                    ,"TINYINT(1)"                    },;
                                  {  "D","Date"                                         ,.f.,.f.,nil,.f.,.f.,"date"                       ,"DATE"                          },;
                                  {"TOZ","Time Only With Time Zone Conversion"          ,.f.,.t.,  6,.f.,.f.,"time with time zone"        ,"TIME COMMENT 'Type=TOZ'"       },;
                                  { "TO","Time Only Without Time Zone Conversion"       ,.f.,.t.,  6,.f.,.f.,"time without time zone"     ,"TIME"                          },;
                                  {"DTZ","Date and Time With Time Zone Conversion (T)"  ,.f.,.t.,  6,.f.,.f.,"timestamp with time zone"   ,"TIMESTAMP"                     },;
                                  { "DT","Date and Time Without Time Zone Conversion"   ,.f.,.t.,  6,.f.,.f.,"timestamp without time zone","DATETIME"                      },;
                                  {  "Y","Money"                                        ,.f.,.f.,nil,.f.,.f.,"money"                      ,"DECIMAL(13,4) COMMENT 'Type=Y'"},;
                                  {  "E","Enumeration"                                  ,.f.,.f.,nil,.t.,.f.,"enum"                       ,"ENUM"                          },;
                                  {"UUI","UUID Universally Unique Identifier"           ,.f.,.f.,nil,.f.,.f.,"uuid"                       ,"VARCHAR(36)"                   },;   // In DBF VarChar 36
                                  { "JS","JSON"                                         ,.f.,.f.,nil,.f.,.f.,"json"                       ,"LONGTEXT COMMENT 'Type=JS'"    },;
                                  {"JSB","JSONB"                                        ,.f.,.f.,nil,.f.,.f.,"jsonb"                      ,"LONGTEXT COMMENT 'Type=JSB"    },;      // Enhanced version used natively in PostgreSQL
                                  {"OID","Object Identifier"                            ,.f.,.f.,nil,.f.,.f.,"oid"                        ,"BIGINT COMMENT 'Type=OID'"     },;
                                  {  "?","Other"                                        ,.f.,.f.,nil,.f.,.f.,""                           ,""                              };
                                 }
    
    data p_cThisAppTitle                 init ""
    data p_cThisAppColorHeaderBackground init ""
    data p_cThisAppColorHeaderTextWhite  init ""
    data p_lThisAppColorHeaderTextWhite  init .f.
    data p_cThisAppLogoThemeName         init ""

    method OnFirstRequest()
    method OnRequest()
    method OnShutdown()
    method OnError(par_oError)
#ifdef __PLATFORM__LINUX
    method isOauth()
    method OnCallback(par_code)
#endif
    method Self() inline Self

    method Redirect(par_cURL)

    #include "api.txt"

endclass
//=================================================================================================================
method Redirect(par_cURL) class MyFcgi
// SendToDebugView("Redirecting to",par_cURL)
::Super:Redirect(par_cURL)
return nil
//=================================================================================================================

method OnFirstRequest() class MyFcgi

SendToDebugView("Called from method OnFirstRequest")

set century on
set delete on

::SetOnErrorDetailLevel(2)
::SetOnErrorProgramInfo(hb_BuildInfo())

::p_o_SQLConnection := nil  // Will be set during OnRequest

return nil 
//=================================================================================================================
method OnRequest() class MyFcgi
local l_cPageHeaderHtml := []
local l_cBody := []
local l_cHtml := []

local l_oDB1
local l_oDB2
local l_cSecuritySalt
local l_cSecurityDefaultPassword
local l_iCurrentDataVersion

local l_cSitePath
local l_cPageName
local l_cSessionID
local l_nPos
local l_lLoggedIn
local l_nLoggedInPk,l_cLoggedInSignature
local l_cUserID
local l_cPassword
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
local l_lCyanAuditAware         := (upper(left(::GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
local l_cPostgresDriver         := ::GetAppConfig("POSTGRESDRIVER")
local l_cPostgresHost           := ::GetAppConfig("POSTGRESHOST")
local l_iPostgresPort           := val(::GetAppConfig("POSTGRESPORT"))
local l_cPostgresDatabase       := ::GetAppConfig("POSTGRESDATABASE")
local l_cPostgresId             := ::GetAppConfig("POSTGRESID")
local l_lNoPostgresConnection
local l_TimeStamp1 := hb_DateTime()
local l_TimeStamp2
local l_lShowDevelopmentInfo := .f.
static l_lGetUUIDSupported := .f.  // Used to ensure the PostgreSQL database has the "pgcrypto" extension installed.
local l_cAccessToken
local l_cAPIEndpointName
local l_sAPIFunction
local l_cLinkUID
local l_oDB_ListOfFileStream
local l_oDB_FileStream
local l_cFilePath
local l_cFileName
local l_oJWT
local l_nTokenAccessMode
local l_cConnectionErrorMessage := ""
local l_cSQLCommand
local l_nWharfConfigAppliedStatus
local l_nContentSize

SendToDebugView("Request Counter",::RequestCount)
SendToDebugView("Requested URL",::GetEnvironment("REDIRECT_URL"))

// el_StrToFile(hb_jsonEncode(hb_orm_UsedWorkAreas(),.t.),el_AddPs(OUTPUT_FOLDER)+"WorkAreas_"+GetZuluTimeStampForFileNameSuffix()+"_OnRequestStart.txt")

::p_cThisAppTitle := ::GetAppConfig("APPLICATION_TITLE")
if empty(::p_cThisAppTitle)
    ::p_cThisAppTitle := APPLICATION_TITLE
endif
::p_cThisAppColorHeaderBackground := ::GetAppConfig("COLOR_HEADER_BACKGROUND")
if empty(::p_cThisAppColorHeaderBackground)
    ::p_cThisAppColorHeaderBackground := COLOR_HEADER_BACKGROUND
endif
::p_cThisAppColorHeaderTextWhite := ::GetAppConfig("COLOR_HEADER_TEXT_WHITE")
if empty(::p_cThisAppColorHeaderTextWhite)
    ::p_lThisAppColorHeaderTextWhite := COLOR_HEADER_TEXT_WHITE
else
    ::p_lThisAppColorHeaderTextWhite := ("T" $ upper(::p_cThisAppColorHeaderTextWhite)) .or. ("Y" $ upper(::p_cThisAppColorHeaderTextWhite)) 
endif
::p_cThisAppLogoThemeName := ::GetAppConfig("LOGO_THEME_NAME")
if empty(::p_cThisAppLogoThemeName)
    ::p_cThisAppLogoThemeName := LOGO_THEME_NAME
endif

::SetHeaderValue("X-Frame-Options","DENY")  // To help prevent clickhacking, meaning to place the web site into an frame of another site.

//Reset transient properties

::p_iUserPk         := 0
::p_cUserName       := ""
::p_nUserAccessMode := 0
::p_nAccessLevelDD  := 0
::p_cSitePath       := ::RequestSettings["SitePath"]

l_cSitePath := ::p_cSitePath

//Since the OnFirstRequest method only runs on first request, on following request have to check if connection is still active, and not terminated by the SQL Server.
l_lNoPostgresConnection := (::p_o_SQLConnection == NIL) .or. (::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected())

if !l_lNoPostgresConnection
    if (::p_o_SQLConnection:GetServer() <> l_cPostgresHost)     .or.;
    (::p_o_SQLConnection:GetPort()      <> l_iPostgresPort)     .or.;
    (::p_o_SQLConnection:GetDatabase()  <> l_cPostgresDatabase) .or.;
    (::p_o_SQLConnection:GetUser()      <> l_cPostgresId)
        l_lNoPostgresConnection := .t.
    endif
endif

if !l_lNoPostgresConnection  //If still possibly connected, test if the ORM schema is present
    if ::p_o_SQLConnection:SQLExec("a37e465d-1a15-48bb-aa4f-c2542b76effa","select exists (select nspname from pg_catalog.pg_namespace where nspname = 'ORM');","ListOfNamespaces")
        if !ListOfNamespaces->exists
            l_lNoPostgresConnection := .t.
        endif
    else
        l_lNoPostgresConnection := .t.
    endif
    CloseAlias("ListOfNamespaces")
endif

if l_lNoPostgresConnection
    if !(::p_o_SQLConnection == NIL)
        ::p_o_SQLConnection:Disconnect()  //Just in case a connection still existed
        ::p_o_SQLConnection := NIL
    endif

    // SendToDebugView("Reconnecting to SQL Server")
    ::p_o_SQLConnection := hb_SQLConnect()
    with object ::p_o_SQLConnection
        :SetBackendType("PostgreSQL")
        :SetDriver(l_cPostgresDriver)
        :SetServer(l_cPostgresHost)
        :SetPort(l_iPostgresPort)
        :SetUser(l_cPostgresId)
        :SetPassword(::GetAppConfig("POSTGRESPASSWORD"))
        :SetDatabase(l_cPostgresDatabase)
        :SetCurrentNamespaceName("public")

        :LoadWharfConfiguration(Config())
        
        :SetForeignKeyNullAndZeroParity(.t.)

        :SetHarbourORMNamespace("ORM")
        :PostgreSQLIdentifierCasing := HB_ORM_POSTGRESQL_CASE_SENSITIVE
        :SetPrimaryKeyFieldName("pk")
        // :SetApplicationName("DataWharf")   Can only be set once connected.

        if :Connect() < 0
            // ::p_o_SQLConnection := NIL
            l_cConnectionErrorMessage := :GetErrorMessage()

        else
            if v_iFastCGIRunLogPk <= 0 .and. !::p_o_SQLConnection:TableExists("public.FastCGIRunLog")   //Test if the minimum table is missing
                UpdateSchema(::p_o_SQLConnection)
            endif

            :SetApplicationName("DataWharf - 0")  // Temporary name until we have a FastCGIRunLog record.

            l_nWharfConfigAppliedStatus := :GetWharfConfigAppliedStatus()

            do case
            case l_nWharfConfigAppliedStatus < 0
                l_cConnectionErrorMessage := "Failed to get WharfConfig Applied Information."
            case l_nWharfConfigAppliedStatus == 3
                l_cConnectionErrorMessage := "Future Schema. Use a newer Application version."
            otherwise

                l_oDB1 := hb_SQLData(::p_o_SQLConnection)
                l_oDB2 := hb_SQLData(::p_o_SQLConnection)

                // Get the number of DataWharf connections
                l_cSQLCommand := [SELECT pg_advisory_lock(123456) as result]
                if ::p_o_SQLConnection:SQLExec("Lock",l_cSQLCommand)
                    ::p_o_SQLConnection:SQLExec("ce2607d5-a3d7-492e-b8c0-0769a8ccf5d0","SELECT application_name FROM pg_stat_activity where datname = '"+l_cPostgresDatabase+"' and application_name ilike 'DataWharf - %';","ListOfDataWharfConnections")

                    if ("ListOfDataWharfConnections")->(reccount()) == 1
                        // Only the current EXE is connected.

                        //== Log current FastCGI Executable ====================
                        if v_iFastCGIRunLogPk <= 0
                            with object l_oDB1
                                :Table("cf798fea-198b-4831-aafa-55d6135dfed1","FastCGIRunLog")
                                :Field("FastCGIRunLog.dati"              ,{"S","now()"})
                                :Field("FastCGIRunLog.ApplicationVersion",BUILDVERSION)
                                :Field("FastCGIRunLog.IP"                ,::RequestSettings["ClientIP"])
                                :Field("FastCGIRunLog.OSInfo"            ,OS())
                                :Field("FastCGIRunLog.HostInfo"          ,hb_osCPU())
                                if :Add()
                                    v_iFastCGIRunLogPk := :Key()
                                    oFcgi:p_o_SQLConnection:SetApplicationName("DataWharf - "+trans(v_iFastCGIRunLogPk))
                                else
                                    v_iFastCGIRunLogPk := -1
                                endif
                            endwith
                        endif
                        //== Clean up any StreamFile folders and Volatile files.
                        PurgeStreamFileFolders()
                        PurgeVolatileFiles()

                        //== Update Schema and data version ====================

                        UpdateSchema(::p_o_SQLConnection)

                        l_iCurrentDataVersion := SelfDataMigration()



                    else
                        //Not the first concurrent connection
                        l_iCurrentDataVersion := :GetSchemaDefinitionVersion("Core")

                        if v_iFastCGIRunLogPk <= 0
                            with object l_oDB1
                                :Table("cf798fea-198b-4831-aafa-55d6135dfed1","FastCGIRunLog")
                                :Field("FastCGIRunLog.dati"              ,{"S","now()"})
                                :Field("FastCGIRunLog.ApplicationVersion",BUILDVERSION)
                                :Field("FastCGIRunLog.IP"                ,::RequestSettings["ClientIP"])
                                :Field("FastCGIRunLog.OSInfo"            ,OS())
                                :Field("FastCGIRunLog.HostInfo"          ,hb_osCPU())
                                if :Add()
                                    v_iFastCGIRunLogPk := :Key()
                                    oFcgi:p_o_SQLConnection:SetApplicationName("DataWharf - "+trans(v_iFastCGIRunLogPk))
                                else
                                    v_iFastCGIRunLogPk := -1
                                endif
                            endwith
                        endif
                    endif

                    CloseAlias("ListOfDataWharfConnections")
                    
                    l_cSQLCommand := [SELECT pg_advisory_unlock(123456) as result]
                    ::p_o_SQLConnection:SQLExec("UnLock",l_cSQLCommand)

                endif

                l_nWharfConfigAppliedStatus := :GetWharfConfigAppliedStatus()

                do case
                case hb_IsNil(l_iCurrentDataVersion) .or. l_iCurrentDataVersion < GetLatestDataVersionNumber()
                    l_cConnectionErrorMessage := "Maintenance in Progress, try later."
                case l_nWharfConfigAppliedStatus < 0
                    l_cConnectionErrorMessage := "Failed to get WharfConfig Applied Information."
                case l_nWharfConfigAppliedStatus == 1
                    l_cConnectionErrorMessage := "No WharfConfig Applied Information."
                case l_nWharfConfigAppliedStatus == 2
                    l_cConnectionErrorMessage := "Schema needs to be updated."
                case l_nWharfConfigAppliedStatus == 3
                    l_cConnectionErrorMessage := "Future Schema. Use a newer Application version."
                otherwise
                    l_cConnectionErrorMessage := ""
                    
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

                    UpdateAPIEndpoint()
                endcase

            endcase

            if !empty(l_cConnectionErrorMessage)
                ::p_o_SQLConnection:Disconnect()
                // ::p_o_SQLConnection := NIL
            endif
        endif
    endwith
else
    if ::p_o_SQLConnection:CheckIfSchemaCacheShouldBeUpdated()
        UpdateSchema(::p_o_SQLConnection)   //_M_ Why here
    endif
endif


// local l_cPostgresDriver         := ::GetAppConfig("POSTGRESDRIVER")
// local l_cPostgresHost           := ::GetAppConfig("POSTGRESHOST")
// local l_iPostgresPort           := val(::GetAppConfig("POSTGRESPORT"))
// local l_cPostgresDatabase       := ::GetAppConfig("POSTGRESDATABASE")
// local l_cPostgresId             := ::GetAppConfig("POSTGRESID")


do case
case hb_IsNil(::p_o_SQLConnection) .or. !::p_o_SQLConnection:Connected
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Failed to connect to Data Server</h1>]

    if !empty(l_cConnectionErrorMessage) .and. len(l_cConnectionErrorMessage) < 200   // The length condition will remove any excessive message.
        l_cHtml += [<h1>]+l_cConnectionErrorMessage+[</h1>]
    endif

    l_cHtml += [<h2>Config File: ]+::PathBackend+"config.txt"+[</h2>]
    l_cHtml += [<h2>Driver: ]+l_cPostgresDriver+[</h2>]
    l_cHtml += [<h2>Host: ]+l_cPostgresHost+[</h2>]
    l_cHtml += [<h2>Port: ]+trans(l_iPostgresPort)+[</h2>]
    l_cHtml += [<h2>User ID: ]+l_cPostgresId+[</h2>]
    // l_cHtml += [<h2>Password: ]+::GetAppConfig("POSTGRESPASSWORD")+[</h2>]
    l_cHtml += [<h2>Database: ]+l_cPostgresDatabase+[</h>]
    
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( val(::p_o_SQLConnection:p_hb_orm_version) , val(MIN_HARBOUR_ORM_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour ORM must be version ]+MIN_HARBOUR_ORM_VERSION+[ or higher.</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( el_GetVersion() , val(MIN_HARBOUR_EL_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour EL must be version ]+MIN_HARBOUR_EL_VERSION+[ or higher.</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( vaL(::p_hb_fcgi_version) , val(MIN_HARBOUR_FCGI_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour FastCGI must be version ]+MIN_HARBOUR_FCGI_VERSION+[ or higher.</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

otherwise
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
            ::p_o_SQLConnection:SQLExec("6d20b707-04df-47c1-85b1-2f3e73570680","SELECT cyanaudit.fn_set_current_uid( 0 );")
        endif

        // l_cSitePath := ::GetEnvironment("CONTEXT_PREFIX")
        // if len(l_cSitePath) == 0
        //     l_cSitePath := "/"
        // endif
        // ::GetQueryString("p")

        ::p_URLPathElements := {}

        l_cPageName := substr(::GetEnvironment("REDIRECT_URL"),len(l_cSitePath)+1)

        if el_IsInlist(lower(right(l_cPageName,4)),".ico",".txt",".css") .or. el_IsInlist(lower(right(l_cPageName,3)),".js")
            //Should not happen in FastCGI 1.7+
            SendToDebugView("Code should not happen ico,txt,css,js",::RequestCount)
            return nil
        endif

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
        
        // if l_cPageName == "favicon.ico" .or. l_cPageName == "scripts"
        if l_cPageName == "scripts"
            return nil
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
        if !el_IsInlist(lower(l_cPageName),"ajax","api","streamfile") // ,"health"

            l_aWebPageHandle := hb_HGetDef(v_hPageMapping, l_cPageName, {"Home",1,.t.,@BuildPageHome()})
            // #define WEBPAGEHANDLE_NAME            1
            // #define WEBPAGEHANDLE_ACCESSMODE      2
            // #define WEBPAGEHANDLE_BUILDHEADER     3
            // #define WEBPAGEHANDLE_FUNCTIONPOINTER 4

            ::p_cHeader       := ""
            ::p_cjQueryScript := ""

            if l_aWebPageHandle[WEBPAGEHANDLE_BUILDHEADER]

                // l_cPageHeaderHtml += [<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=UTF-8">]

                l_cPageHeaderHtml += [<meta http-equiv="X-UA-Compatible" content="IE=edge">]
                l_cPageHeaderHtml += [<meta http-equiv="Content-Type" content="text/html;charset=utf-8">]
                l_cPageHeaderHtml += [<title>]+oFcgi:p_cThisAppTitle+[</title>]

                l_cPageHeaderHtml += [<link rel="icon" href="images/favicon_]+::p_cThisAppLogoThemeName+[.ico" type="image/x-icon">]

                l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/css/bootstrap.min.css">]

                l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/icons/font/bootstrap-icons.css">]

                l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/jQueryUI_]+JQUERYUI_SCRIPT_VERSION+[/Themes/smoothness/jQueryUI.css">]
                l_cPageHeaderHtml += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[datawharf.css">]

                l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQuery_]+JQUERY_SCRIPT_VERSION+[/jquery.min.js"></script>]
                l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/Bootstrap_]+BOOTSTRAP_SCRIPT_VERSION+[/js/bootstrap.bundle.min.js"></script>]

                // l_cPageHeaderHtml += [<script>$.fn.bootstrapBtn = $.fn.button.noConflict();</script>]
                l_cPageHeaderHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/jQueryUI_]+JQUERYUI_SCRIPT_VERSION+[/jquery-ui.min.js"></script>]

                ::p_cHeader := l_cPageHeaderHtml
            endif
        endif

        l_cPageHeaderHtml := NIL  //To free memory

#ifdef __PLATFORM__LINUX
        if ::isOAuth()
            l_cSessionID := ::GetCookieValue(COOKIE_PREFIX+"SessionJWT")
        else
            l_cSessionID := ::GetCookieValue(COOKIE_PREFIX+"SessionID")
        endif
#else
    l_cSessionID := ::GetCookieValue(COOKIE_PREFIX+"SessionID")
#endif

        l_cAction    := ::GetQueryString("action")

        l_oDB1 := hb_SQLData(::p_o_SQLConnection)
        with object l_oDB1
            :Table("ea9c6e26-008e-4cad-ae70-28257020c27e","FastCGIRunLog")
            :Field("FastCGIRunLog.RequestCount"      ,{"S",'"RequestCount" + 1'})
// altd()
            :Update(v_iFastCGIRunLogPk)
        endwith

        if l_cAction == "logout"
            if !empty(l_cSessionID)

#ifdef __PLATFORM__LINUX
                if ::isOAuth()
                    ::DeleteCookie(COOKIE_PREFIX+"SessionJWT")
                    //::Redirect(l_cSitePath+"home")
                    ::Redirect(oFcgi:GetAppConfig("OAUTH_LOGOUT_URL"))
                    return nil
                else
#endif

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
                    ::DeleteCookie(COOKIE_PREFIX+"SessionID")
                    ::Redirect(l_cSitePath+"home")
                    return nil
#ifdef __PLATFORM__LINUX
                endif
#endif
            endif
        endif

        l_lLoggedIn       := .f.
        l_cUserName       := ""
        l_cUserID         := ""
        l_nUserAccessMode := 0

        if !empty(l_cSessionID) .and. !el_IsInlist(lower(l_cPageName),"api") // ,"health"
#ifdef __PLATFORM__LINUX
            if ::isOAuth()
                //validate session JWT
                l_oJWT := JWT():new()
                l_oJWT:Decode(l_cSessionID)
                if !empty(l_oJWT:GetError())
                    ::OnError(l_oJWT:GetError())
                endif

                //check if token is still valid:
                if getLinuxEpochTime() - l_oJWT:GetExpration() < 0 .and. ValidateToken(l_oJWT)
                    l_lLoggedIn := .t.
                    l_cUserID := l_oJWT:GetPayloadData('preferred_username')
                    l_cUserName := alltrim(l_oJWT:GetPayloadData('given_name'))+" "+l_oJWT:GetPayloadData('family_name')
                    //check if user is already in local DB
                    with object l_oDB1
                        :Table("0405BFDF-8347-46DA-9C4C-BFF6E883CC94","public.User")
                        :Column("User.pk"        ,"User_pk")
                        :Column("User.AccessMode" ,"User_AccessMode")
                        :Where("trim(User.id) = ^",l_cUserID)
                        :SQL("ListOfResults")

                        if :Tally == 1
                            l_iUserPk := ListOfResults->User_Pk
                            l_nUserAccessMode := ListOfResults->User_AccessMode
                        else
                            //first time user login, create with default access rights
                            AutoProvisionUser(l_cUserID, l_oJWT:GetPayloadData('given_name'), l_oJWT:GetPayloadData('family_name'))
                            :SQL("ListOfResults")
                            if :Tally == 1
                                l_iUserPk := ListOfResults->User_Pk
                                l_nUserAccessMode := ListOfResults->User_AccessMode
                            endif
                        endif

                    endwith
                else
                    ::DeleteCookie(COOKIE_PREFIX+"SessionJWT")
                endif
            else
#endif
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
                        l_cUserName       := alltrim(ListOfResults->User_FirstName)+" "+alltrim(ListOfResults->User_LastName)
                        l_nUserAccessMode := ListOfResults->User_AccessMode
                    else
                        // Clear the cookie
                        ::DeleteCookie(COOKIE_PREFIX+"SessionID")
                    endif
                    CloseAlias("ListOfResults")
                endif
#ifdef __PLATFORM__LINUX
            endif
#endif
        endif
        
        // if l_cPageName <> "ajax"
        if !el_IsInlist(lower(l_cPageName),"ajax","api","streamfile")
            //If not a public page and not logged in, then request to log in.
            if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSMODE] > 0 .and. !l_lLoggedIn
#ifdef __PLATFORM__LINUX
                if ::isOAuth()
                    if ::RequestSettings["Path"] == [login/]
                        if ::RequestSettings["Page"] == [callback]
                            ::OnCallback(::GetQueryString("code"))
                        endif
                    else
                        // altd()
                        ::Redirect(oFcgi:GetAppConfig("OAUTH_AUTH_URL") + [?] + [response_type=code&client_id=] + oFcgi:GetAppConfig("OAUTH_CLIENT_ID"))
                    endif
                else
#endif
                    if oFcgi:IsGet()
                        l_cBody += GetPageHeader(.f.,l_cPageName)
                        l_cBody += BuildPageLoginScreen()
                    else
                        //Post
                        l_cUserID   := SanitizeInput(oFcgi:GetInputValue("TextID"))
                        l_cPassword := SanitizeInput(oFcgi:GetInputValue("TextPassword"))

                        with object l_oDB1
                            :Table("6bad4ae5-6bb2-4bdb-97b9-6adacb2a8327","public.User")
                            :Column("User.pk"        ,"User_pk")
                            :Column("User.FirstName" ,"User_FirstName")
                            :Column("User.LastName"  ,"User_LastName")
                            :Column("User.Password"  ,"User_Password")
                            :Column("User.AccessMode","User_AccessMode")
                            :Where("trim(User.id) = ^",l_cUserID)
                            // :Where("trim(User.Password) = ^",l_cPassword)
                            :Where("User.Status = 1")
                            :SQL("ListOfResults")

                            if :Tally == 1
                                l_iUserPk := ListOfResults->User_Pk

                                //Check if valid Password
                                l_cSecuritySalt := oFcgi:GetAppConfig("SECURITY_SALT")

                                if Trim(ListOfResults->User_Password) == hb_SHA512(l_cSecuritySalt+l_cPassword+Trans(l_iUserPk))
                                    l_cUserName       := alltrim(ListOfResults->User_FirstName)+" "+alltrim(ListOfResults->User_LastName)
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
                                        ::SetSessionCookieValue(COOKIE_PREFIX+"SessionID",l_cSessionCookie,0)
                                        l_lLoggedIn := .t.
                                    endif
                                else
                                    //Invalid Password
                                    l_cBody += GetPageHeader(.f.,l_cPageName)
                                    l_cBody += BuildPageLoginScreen(l_cUserID,"","Invalid ID or Password.1")
                                endif
                            else
                                //Invalid Active ID
                                l_cBody += GetPageHeader(.f.,l_cPageName)
                                l_cBody += BuildPageLoginScreen(l_cUserID,"","Invalid ID or Password.2")
                            endif

                        endwith
                    
                    endif
#ifdef __PLATFORM__LINUX
                endif
#endif
            endif
        endif

        if l_lLoggedIn
            ::p_iUserPk         := l_iUserPk
            ::p_cUserName       := l_cUserName
            ::p_nUserAccessMode := l_nUserAccessMode

            //Since we now know the current user access mode, will check if this would be an invalid access right.
            if ((::p_nUserAccessMode < 4) .and. lower(l_cPageName) == "users")         .or. ;  // block from going to "Users" web page, unless "Root Admin" access right.
            ((::p_nUserAccessMode < 3) .and. lower(l_cPageName) == "customfields")          // block from going to "CustomFields" web page, unless "All Application Full Access access right.
                ::Redirect(l_cSitePath+"home")
                return nil
            endif

            if l_lCyanAuditAware
                //Tell Cyanaudit to log future entries as the current user.
                ::p_o_SQLConnection:SQLExec("6b78107a-1717-4366-9000-bb7d2e5fafd0","SELECT cyanaudit.fn_set_current_uid( "+Trans(::p_iUserPk)+" );")
            endif
            
            if l_cPageName == "ajax"
                l_cBody := [UNBUFFERED]
                if len(::p_URLPathElements) >= 2 .and. !empty(::p_URLPathElements[2])
                    l_cAjaxAction := ::p_URLPathElements[2]

                    switch l_cAjaxAction
                    case "SaveSearchModeTable"
                        l_cBody += SaveSearchModeTable()
                        exit
                    case "SaveSearchModeEnumeration"
                        l_cBody += SaveSearchModeEnumeration()
                        exit
                    case "GetDDInfo"
                        l_cBody += GetDDInfoDuringVisualization()
                        exit
                    case "GetMLInfo"
                        l_cBody += GetMLInfoDuringVisualization()
                        exit
                    endswitch

                endif
            elseif l_cPageName == "streamfile"
                // l_cBody := [UNBUFFERED]+hb_MemoRead("d:\LastExport.zip")

                l_oDB_ListOfFileStream := hb_SQLData(oFcgi:p_o_SQLConnection)
                l_oDB_FileStream       := hb_SQLData(oFcgi:p_o_SQLConnection)

                l_cLinkUID := oFcgi:GetQueryString("id")
                if empty(l_cLinkUID)
                    l_cBody := [UNBUFFEREDBad Link]
                else
                    with object l_oDB_ListOfFileStream

                        :Table("d85a01ec-6a9d-436f-a643-3623839a5de6","volatile.FileStream","FileStream")
                        :Column("FileStream.pk"      ,"pk")
                        :Column("FileStream.FileName","FileName")
                        :Column("FileStream.type"    ,"Type")
                        :Where("FileStream.fk_User = ^" , oFCgi:p_iUserPk)
                        :Where("FileStream.LinkUID = ^" , l_cLinkUID)
                        :SQL("ListOfFileStream")

                        if :Tally == 1
                            l_cFilePath := GetStreamFileFolderForCurrentProcess()
                            l_oDB_FileStream:GetFile("d94f5984-7ed8-41df-8b81-0d5267bec552","volatile.FileStream",ListOfFileStream->pk,"oid",l_cFilePath+"Export.zip")
                            if file(l_cFilePath+"Export.zip")
                                l_cBody := [UNBUFFERED]+hb_MemoRead(l_cFilePath+"Export.zip")
                                DeleteFile(l_cFilePath+"Export.zip")
                            else
                                l_cFilePath := GetStreamFileFolderForCurrentUser()
                                l_cBody := [UNBUFFERED]+hb_MemoRead(l_cFilePath+"Export"+trans(ListOfFileStream->pk)+".zip")
                            endif

                            ::SetContentType("application/octet-stream")

                            l_cFileName := nvl((ListOfFileStream->FileName),"Export.zip")
                            
                            ::SetHeaderValue("content-disposition",'attachment; filename="'+l_cFileName+'"')
                        else
                            l_cBody := [UNBUFFEREDBad FileStream Link]
                        endif

                        CloseAlias("ListOfFileStream")
                    endwith
                endif

            else
                if l_aWebPageHandle[WEBPAGEHANDLE_BUILDHEADER]
                    l_cBody += GetPageHeader(.t.,l_cPageName)
                endif
                l_cBody += l_aWebPageHandle[WEBPAGEHANDLE_FUNCTIONPOINTER]:exec()

                if left(l_cBody,10) <> [UNBUFFERED]
                    l_lShowDevelopmentInfo :=  (upper(left(oFcgi:GetAppConfig("ShowDevelopmentInfo"),1)) == "Y")
                    if l_lShowDevelopmentInfo
                        l_cBody += [<div class="m-3">]   //Spacer
                            if l_aWebPageHandle[WEBPAGEHANDLE_ACCESSMODE] > 0  //Logged in page
                                l_cBody += "<div>Web Site Version: " + BUILDVERSION + "</div>"
                            endif
                            l_cBody += [<div>Site Build Info: ]+hb_buildinfo()+[</div>]
                            l_cBody += [<div>ORM Build Info: ]+hb_orm_buildinfo()+[</div>]
                            l_cBody += [<div>EL Build Info: ]+hb_el_buildinfo()+[</div>]
                            l_cBody += [<div>PostgreSQL Host: ]+oFcgi:GetAppConfig("POSTGRESHOST")+[</div>]
                            l_cBody += [<div>PostgreSQL Database: ]+oFcgi:GetAppConfig("POSTGRESDATABASE")+[</div>]
                            l_cBody += ::TraceList(4)
                        l_cBody += [</div>]   //Spacer
                    endif
                endif

            endif
        else
            //Not Logged In
            if l_cPageName == "ajax"
                l_cBody := [UNBUFFERED Not Logged In]
            elseif l_cPageName == "api"
                // Check for tocken
                l_cAccessToken := oFcgi:GetHeaderValue("AccessToken")
                if empty(l_cAccessToken)
                    l_cAccessToken := oFcgi:GetQueryString("AccessToken")
                endif
                l_cAPIEndpointName := GetAPIURIElement(1)
                l_cBody := [UNBUFFERED]
                l_nTokenAccessMode := APIAccessCheck_Token_EndPoint(l_cAccessToken,l_cAPIEndpointName)
                if l_nTokenAccessMode <= 0
                    oFcgi:SetHeaderValue("Status","403 Forbidden")
                    oFcgi:SetContentType("text/html")
                    l_cBody += [Access Denied]

                else
                    l_sAPIFunction := hb_HGetDef(oFcgi:p_APIs,l_cAPIEndpointName,NIL)   // Use the first URL element after /api/
                    if hb_IsNIL(l_sAPIFunction)
                        oFcgi:SetHeaderValue("Status","403 Forbidden")
                        oFcgi:SetContentType("text/html")
                        l_cBody += [Invalid API Call]  //This should never happen in the list of p_APIs values are used to build the list of APIEndpoint(s)
                    else
                        oFcgi:SetContentType("application/json")
                        oFcgi:SetHeaderValue("Status","403 Forbidden")
                        l_cBody += l_sAPIFunction:exec(l_cAccessToken,l_cAPIEndpointName,l_nTokenAccessMode)
                        if upper(right(l_cBody,len("ACCESS DENIED"))) == "ACCESS DENIED"
                            oFcgi:SetHeaderValue("Status","403 Forbidden")
                            oFcgi:SetContentType("text/html")
                        endif
                    endif
                endif

            elseif l_cPageName == "streamfile"
                //_M_ Should it be allowed to stream a file while not logged in ?
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
                l_nContentSize = len(l_cHtml+[</body></html>])

                l_TimeStamp2  := hb_DateTime()
                l_cHtml += [<div class="mt-3 mx-3 mb-0">Run Time: ]+trans(int((l_TimeStamp2-l_TimeStamp1)*(24*3600*1000)))+[ (ms)</div>]
                l_cHtml += [<div class="mt-0 mx-3 mb-3">Content Size: ]+ trim(Transform( l_nContentSize, "@b 999,999,999,999" ))+[ Bytes =  ]+trim(Transform( l_nContentSize/1024, "@b 999,999,999,999" ))+[ Kb] +[</div>]
            endif

            l_cHtml += [</body>]
            l_cHtml += [</html>]

        endif
    endif
endcase

::Print(l_cHtml)

// el_StrToFile(hb_jsonEncode(hb_orm_UsedWorkAreas(),.t.),el_AddPs(OUTPUT_FOLDER)+"WorkAreas_"+GetZuluTimeStampForFileNameSuffix()+"_OnRequestEnd.txt")

return nil
//=================================================================================================================
method OnShutdown() class MyFcgi
SendToDebugView("Called from method OnShutdown")
if !hb_IsNil(::p_o_SQLConnection)
    ::p_o_SQLConnection:Disconnect()
    ::p_o_SQLConnection := NIL
endif
return nil 
//=================================================================================================================
method OnError(par_oError) class MyFcgi
local l_oDB1
local l_lNoPostgresConnection
local l_cErrorInfo

    try
////        SendToDebugView("Called from MyFcgi OnError")
        ::ClearOutputBuffer()
        ::Print("<h1>Error Occurred</h1>")
        ::Print("<h2>"+hb_buildinfo()+" - Current Time: "+hb_DToC(hb_DateTime())+"</h2>")
        l_cErrorInfo := FcgiGetErrorInfo(par_oError)
        ::Print("<div>"+l_cErrorInfo+"</div>")
        ::Print("<div>FastCGIRunLog.pk = "+Trans(nvl(v_iFastCGIRunLogPk,0))+"</div>")
        ::Print("<div>"+::TraceList(4)+"</div>")

        //  ::hb_Fcgi:OnError(par_oError)
        ::Finish()

        if !empty(l_cErrorInfo)
            l_lNoPostgresConnection := (::p_o_SQLConnection == NIL) .or. (::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected())
            if !l_lNoPostgresConnection
                l_oDB1 := hb_SQLData(::p_o_SQLConnection)
                with object l_oDB1
                    :Table("94c6f301-f0db-4cce-b0b7-15fd49ad29ba","FastCGIRunLog")
                    :Field("FastCGIRunLog.ErrorInfo",l_cErrorInfo)
                    :Update(v_iFastCGIRunLogPk)
                endwith
            endif
        endif

    catch
    endtry
    
    BREAK
return nil
//=================================================================================================================
//=================================================================================================================
#ifdef __PLATFORM__LINUX
    method isOAuth() class MyFcgi
    return oFcgi:GetAppConfig("AUTH_METHOD") == "oauth"

    //=================================================================================================================
    method OnCallback(p_code) class MyFcgi
        local l_tokenURL := ::GetAppConfig("OAUTH_TOKEN_URL")
        local l_aHeaderParameter := {}
        local l_cPostFields
        local l_cResult

        local l_cURL
        local l_oAPIReturn
        local l_oToken

        local l_oJWT

        /*
        We want to do this:
        curl --location --request POST 'http://localhost:8080/realms/avabase/protocol/openid-connect/token' \
                --header 'Content-Type: application/x-www-form-urlencoded' \
                --data-urlencode 'grant_type=authorization_code' \
                --data-urlencode 'client_id=avabase' \
                --data-urlencode 'client_secret=vdmHpu0pQbOvZIjbIUmD1m6Mo4TLONrJ' \
                --data-urlencode 'code=15aaa4f3-74b5-413e-b750-ace0e032d16a.7fbe83da-b765-4a5f-8bd9-6bec36e596b5.95e224a4-9ca5-4b24-b46c-94cb92fa8114' \
                --data-urlencode 'redirect_uri=http://localhost:8081/callback'
        */
        
        AAdd(l_aHeaderParameter,"Content-Type: application/x-www-form-urlencoded")
        l_cPostFields =  "grant_type=" + "authorization_code" +;
            "&client_id=" + ::GetAppConfig("OAUTH_CLIENT_ID") +;
            "&client_secret=" + ::GetAppConfig("OAUTH_CLIENT_SECRET") +;
            "&code=" + p_code

        l_cResult := CurlUrl(l_tokenURL, "POST", l_aHeaderParameter, l_cPostFields)
        hb_jsonDecode(l_cResult,@l_oAPIReturn)
        l_oToken := l_oAPIReturn["access_token"]


        // Object
        l_oJWT := JWT():new()
        
        //Verify will not yet work as RS256 is currently not supported
        //oJWT:Verify(l_oToken)
        l_oJWT:Decode(l_oToken)
        if !empty(l_oJWT:GetError())
            ::OnError(l_oJWT:GetError())
        else
            //succcesfull login
            ::SetSessionCookieValue(COOKIE_PREFIX+"SessionJWT",l_oToken,0)
        endif
        ::Redirect(::p_cSitePath+"home")
    return nil

    //=================================================================================================================
    function ValidateToken(l_oJWT)
        local l_bIsValid := .t.
        //oJWT:SetSecret(publicKey)
        //Verify will not yet work as RS256 is currently not supported in JWT.prg
        //needs support for RSA verification which is not yet implemented in hbSSL library.
        //oJWT:Verify(l_oToken)
    return l_bIsValid
#endif

//=================================================================================================================
function UpdateSchema(par_o_SQLConnection)
local l_cLastError := ""
local l_nMigrateSchemaResult := 0
local l_lCyanAuditAware
local l_cUpdateScript := ""

SendToDebugView("In UpdateSchema")

if el_AUnpack(par_o_SQLConnection:MigrateSchema(oFcgi:p_o_SQLConnection:p_hWharfConfig),@l_nMigrateSchemaResult,@l_cUpdateScript,@l_cLastError) > 0
    if l_nMigrateSchemaResult >= 0
        par_o_SQLConnection:RecordCurrentAppliedWharfConfig()
    endif

    if l_nMigrateSchemaResult == 1
        l_lCyanAuditAware := (upper(left(oFcgi:GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
        if l_lCyanAuditAware
            //Ensure Cyanaudit is up to date
            oFcgi:p_o_SQLConnection:SQLExec("a1bf5168-18e2-42ee-b0bd-6bfd252fa7a8","SELECT cyanaudit.fn_update_audit_fields('public');")
            //SendToDebugView("PostgreSQL - Updated Cyanaudit triggers")
        endif
    endif
else
    if empty(l_cLastError)
        //No migration was needed but still ensure the WharfConfig stamp is up to date.
        par_o_SQLConnection:RecordCurrentAppliedWharfConfig()
    else
        SendToDebugView("PostgreSQL - Failed Migrate")
    endif
endif

if !empty(l_cUpdateScript) .and. (upper(left(oFcgi:GetAppConfig("ShowDevelopmentInfo"),1)) == "Y")
    el_StrToFile(l_cUpdateScript,el_AddPs(OUTPUT_FOLDER)+"UpdateScript_"+GetZuluTimeStampForFileNameSuffix()+".txt")
endif

return nil
//=================================================================================================================
function GetPageHeader(par_LoggedIn,par_cCurrentPage)
local l_cHtml := []
local l_cSitePath := oFcgi:p_cSitePath

local l_lShowMenuProjects         := par_LoggedIn .and. (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
local l_lShowMenuApplications     := par_LoggedIn .and. (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
local l_lShowMenuModeling         := l_lShowMenuProjects
local l_lShowMenuDataDictionaries := l_lShowMenuApplications

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

local l_cExtraClass

local l_lShowChangePassword

local l_cBootstrapCurrentPageClasses := [ active border border-2 border-white" aria-current="page]

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

l_cExtraClass := iif(oFcgi:p_lThisAppColorHeaderTextWhite," text-white","")

// hb_orm_SendToDebugView("Called GetPageHeader",l_cExtraClass)

l_cHtml += [<header class="d-flex flex-wrap align-items-center justify-content-center justify-content-md-between py-3 navbar-light navbar" style="background-color: #]+oFcgi:p_cThisAppColorHeaderBackground+[;">]

    l_cHtml += [<div id="app" class="container">]
        l_cHtml += [<a class="d-flex align-items-center mb-2 mb-md-0]+l_cExtraClass+[ navbar-brand" href="#">]
        l_cHtml += [<img src="]+l_cSitePath+[images/Logo_]+oFcgi:p_cThisAppLogoThemeName+[.png" alt="" height="60" class="d-inline-block" style="vertical-align: middle;">&nbsp;]
        l_cHtml += oFcgi:p_cThisAppTitle+[</a>]

        if par_LoggedIn

#ifdef __PLATFORM__LINUX
    l_lShowChangePassword := !oFcgi:isOAuth()
#endif
#ifdef __PLATFORM__WINDOWS
    l_lShowChangePassword := .t.
#endif

            //l_cHtml += [<div class="collapse navbar-collapse" id="navbarNav">]
                l_cHtml += [<ul class="nav col-12 col-md-auto mb-2 justify-content-center mb-md-0">]
                    l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "home"               ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[Home">Home</a></li>]

                    if l_lShowMenuModeling
                        l_cHtml += [<li class="nav-item"><a class="text-center nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "modeling"           ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[Modeling">Modeling<br>Projects</a></li>]
                    endif

                    if l_lShowMenuDataDictionaries
                        l_cHtml += [<li class="nav-item"><a class="text-center nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "datadictionaries"   ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[DataDictionaries">Applications<br>Data Dictionaries</a></li>]
                    endif

// Removed for now the "Inter-App Mapping" option. This feature need to be re-designed to be effective.
            // if (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
            //     l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "interappmapping"    ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[InterAppMapping">Inter-App Mapping</a></li>]
            // endif

                    if l_lShowMenuProjects .or. l_lShowMenuApplications .or.  (oFcgi:p_nUserAccessMode >= 3) .or. (oFcgi:p_nUserAccessMode >= 4) .or. l_lShowChangePassword
// l_cHtml += [<li class="nav-item dropdown"><a class="nav-link link-dark dropdown-toggle]+l_cExtraClass+[" href="#" id="navbarDropdownMenuLinkAdmin" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Settings</a>]
                        l_cHtml += [<li class="nav-item dropdown"><a class="nav-link link-dark dropdown-toggle]+l_cExtraClass+iif(el_IsInlist(lower(par_cCurrentPage),"projects","applications","customfields","apitokens","users","changepassword","datawharferrors")    ,l_cBootstrapCurrentPageClasses,[])+[" href="#" id="navbarDropdownMenuLinkAdmin" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Settings</a>]

                        l_cHtml += [<ul class="dropdown-menu" style="z-index: 1030;top: 70%;left: -50%;" aria-labelledby="navbarDropdownMenuLinkAdmin">]
                            if l_lShowMenuProjects
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "projects"       ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Projects">Modeling / Projects</a></li>]
                            endif

                            if l_lShowMenuApplications
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "applications"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Applications">Applications / Data Dictionaries</a></li>]
                            endif

                            if (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "customfields"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[CustomFields">Custom Fields</a></li>]
                            endif

                            if (oFcgi:p_nUserAccessMode >= 4) // "Root Admin" access right.
                                if APIUSE
                                    l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "apitokens"  ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[APITokens">API Tokens</a></li>]
                                endif
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "recenterrors"   ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[DataWharfErrors">Recent Errors</a></li>]
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "users"          ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[Users">Users</a></li>]
                            endif
                            if l_lShowChangePassword
                                l_cHtml += [<li><a class="dropdown-item]+iif(lower(par_cCurrentPage) == "changepassword"     ,[ active border" aria-current="page],[])+[" href="]+l_cSitePath+[ChangePassword">Change Password</a></li>]
                            endif

                        l_cHtml += [</ul>]
                        l_cHtml += [</li>]
                    endif

                    l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "about"               ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[About">About</a></li>]

                l_cHtml += [</ul>]
                l_cHtml += [<div class="text-end">]
                    l_cHtml += [<a class="btn btn-primary" href="]+l_cSitePath+[home?action=logout">Logout (]+oFcgi:p_cUserName+iif(oFcgi:p_nUserAccessMode < 1," / View Only","")+[)</a>]
                l_cHtml += [</div>]
            //l_cHtml += [</div>]
        endif
    l_cHtml += [</div>]    
l_cHtml += [</header>]

return l_cHtml
//=================================================================================================================
function hb_buildinfo()
#include "BuildInfo.txt"
return l_cBuildInfo
//=================================================================================================================
function SanitizeNameIdentifier(par_text)
local l_result := alltrim(el_StrReplace(par_text,{chr(9)=>" "}))
l_result = el_StrReplace(l_result,{"<"=>"",;
                                   ">"=>"",;
                                   "."=>""})
return l_result
//=================================================================================================================
function SanitizeInput(par_text)
local l_result := alltrim(el_StrReplace(par_text,{chr(9)=>" "}))
l_result = el_StrReplace(l_result,{"<"=>"",;
                                   ">"=>""})
return l_result
//=================================================================================================================
function SanitizeInputAlphaNumeric(par_cText)
return SanitizeInputWithValidChars(par_cText,[_01234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ])
//=================================================================================================================
// function SanitizeInputSQLIdentifier(par_cSource,par_cText)
// return SanitizeInputWithValidChars(alltrim(par_cText),"_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ !#$#%'()*+,-./:;<=>?@[\]^`{|}")   // ~
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
function GetConfirmationModalFormsLoad()
local cHtml

TEXT TO VAR cHtml

<div class="modal fade" id="ConfirmLoadModal" tabindex="-1" aria-labelledby="ConfirmLoadModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmLoadModalLabel">Confirm Load</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        Any missing tables, columns, enumerations and indexes will be added. Nothing will be deleted, even if not physically present anymore!
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Load');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

return cHtml
//=================================================================================================================
function GetConfirmationModalFormsUpdateSchema()
local cHtml

TEXT TO VAR cHtml

<div class="modal fade" id="ConfirmUpdateSchemaModal" tabindex="-1" aria-labelledby="ConfirmUpdateSchemaModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmUpdateSchemaModalLabel">Confirm Update Schema</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        Any missing tables, columns, enumerations and indexes will be added. Nothing will be deleted!
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Update');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

return cHtml
//=================================================================================================================
function GetConfirmationModalFormsDelete()
local l_cHtml

TEXT TO VAR l_cHtml

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

return l_cHtml
//=================================================================================================================
function GetConfirmationModalFormsDuplicate(par_cMessage)
local l_cHtml

TEXT TO VAR l_cHtml

<div class="modal fade" id="ConfirmDuplicateModal" tabindex="-1" aria-labelledby="ConfirmDuplicateModal" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmDuplicateModal">Confirm Duplication</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        xxxxxx
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Duplicate');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

l_cHtml = strtran(l_cHtml,"xxxxxx",par_cMessage)

return l_cHtml
//=================================================================================================================
function GetConfirmationModalFormsPurge()
local l_cHtml

TEXT TO VAR l_cHtml

<div class="modal fade" id="ConfirmPurgeModal" tabindex="-1" aria-labelledby="ConfirmPurgeModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="ConfirmPurgeModalLabel">Confirm Purge</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        This action cannot be undone
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-danger" onclick="$('#ActionOnSubmit').val('Purge');document.form.submit();">Yes</button>
        <button type="button" class="btn btn-primary" data-bs-dismiss="modal">No</button>
      </div>
    </div>
  </div>
</div>

ENDTEXT

return l_cHtml
//=================================================================================================================
function BuildPageLoginScreen(par_cUserID,par_cPassword,par_cErrorMessage)
local l_cHtml := ""
local l_cUserID       := hb_DefaultValue(par_cUserID,"")
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
                    l_cHtml += [<input class="form-control" type="text" name="TextID" id="TextID" placeholder="Enter your User ID" maxlength="100" size="30" value="]+FcgiPrepFieldForValue(l_cUserID)+[" autocomplete="off">]
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

    l_Text := el_StrTran(l_Text,[&amp;] ,[&] ,-1,-1,1)
    l_Text := el_StrTran(l_Text,[&nbsp;],[ ] ,-1,-1,1)
    l_Text := el_StrTran(l_Text,[&lt;]  ,[<] ,-1,-1,1)
    l_Text := el_StrTran(l_Text,[&gt;]  ,[>] ,-1,-1,1)

    l_Text := el_StrTran(l_Text,[&]     ,[&amp;]  )
    l_Text := el_StrTran(l_Text,[<]     ,[&lt;]   )
    l_Text := el_StrTran(l_Text,[>]     ,[&gt;]   )
    l_Text := el_StrTran(l_Text,[  ]    ,[ &nbsp;])
    l_Text := el_StrTran(l_Text,chr(10) ,[]       )
    l_Text := el_StrTran(l_Text,chr(13) ,[<br>]   )
endif

return l_Text
//=================================================================================================================
function GetItemInListAtPosition(par_iPos,par_aValues,par_xDefault)
return iif(!hb_IsNIL(par_iPos) .and. par_iPos > 0 .and. par_iPos <= Len(par_aValues), par_aValues[par_iPos], par_xDefault)
//=================================================================================================================
function MultiLineTrim(par_cText)
local l_nPos := len(par_cText)

do while l_nPos > 0 .and. el_IsInlist(Substr(par_cText,l_nPos,1),chr(13),chr(10),chr(9),chr(32))
    l_nPos -= 1
enddo

return left(par_cText,l_nPos)
//=================================================================================================================
function FormatAKAForDisplay(par_cAKA)
return iif(!hb_IsNIL(par_cAKA) .and. !empty(par_cAKA),[&nbsp;(]+Strtran(par_cAKA,[ ],[&nbsp;])+[)],[])
//=================================================================================================================
function SaveUserSetting(par_cName,par_cValue,par_iFk_Diagram,par_iFk_ModelingDiagram)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iFk_Diagram         := nvl(par_iFk_Diagram,0)
local l_iFk_ModelingDiagram := nvl(par_iFk_ModelingDiagram,0)
local l_nCounter
local l_nTally

with object l_oDB1
    :Table("0afe8937-b79b-4359-b630-dc58ef6aed78","UserSetting")
    :Column("UserSetting.pk" , "pk")
    :Column("UserSetting.ValueC" , "ValueC")
    :Where("UserSetting.fk_User = ^"            , oFcgi:p_iUserPk)
    :Where("UserSetting.KeyC = ^"               , par_cName)
    :Where("UserSetting.fk_Diagram = ^"         , l_iFk_Diagram)
    :Where("UserSetting.fk_ModelingDiagram = ^" , l_iFk_ModelingDiagram)
    :SQL(@l_aSQLResult)
    // SendToClipboard(:LastSQL())

    if :Tally > 1  //Bad data, more than 1 record, will delete all records first.
        l_nTally := :Tally
        for l_nCounter := 1 to l_nTally
            :Delete("808518b2-81c6-460b-96ae-27c7cd550446","UserSetting",l_aSQLResult[l_nCounter,1])
        endfor
        :SQL(@l_aSQLResult) // Rerun query on l_oDB1
    endif

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
            :Field("UserSetting.fk_User"           ,oFcgi:p_iUserPk)
            :Field("UserSetting.fk_Diagram"        ,l_iFk_Diagram)
            :Field("UserSetting.fk_ModelingDiagram",l_iFk_ModelingDiagram)
            :Field("UserSetting.KeyC"              ,par_cName)
            :Field("UserSetting.ValueC"            ,par_cValue)
            :Field("UserSetting.ValueType"         ,1)
            :Add()
        case :Tally == 1
            if l_aSQLResult[1,2] <> par_cValue
                :Table("a33aeb73-8c9c-42a4-aa1f-3584547f4ba8","UserSetting")
                :Field("UserSetting.ValueC" , par_cValue)
                :Update(l_aSQLResult[1,1])
            endif
        otherwise
            // Bad data, more than 1 record. This should not happen since duplicate records just got removed.
        endcase
    endif
endwith

return NIL
//=================================================================================================================
function GetUserSetting(par_cName,par_iFk_Diagram,par_iFk_ModelingDiagram)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_cValue := ""
local l_iFk_Diagram         := nvl(par_iFk_Diagram,0)
local l_iFk_ModelingDiagram := nvl(par_iFk_ModelingDiagram,0)

with object l_oDB1
    :Table("fbfc0172-e47a-4bce-b798-9eff0344c3a5","UserSetting")
    :Column("UserSetting.ValueC" , "ValueC")
    :Where("UserSetting.KeyC = ^"               , par_cName)
    :Where("UserSetting.fk_User = ^"            , oFcgi:p_iUserPk)
    :Where("UserSetting.fk_Diagram = ^"         , l_iFk_Diagram)
    :Where("UserSetting.fk_ModelingDiagram = ^" , l_iFk_ModelingDiagram)
    :SQL(@l_aSQLResult)
// SendToClipboard(:LastSQL())
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
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("599b29b4-8bd9-4380-bd51-8ad5a6c35c91","Application")
    :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_lResult := (l_oData:Application_DestructiveDelete >= APPLICATIONDESTRUCTIVEDELETE_CANDELETEAPPLICATION)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructiveNamespaceDelete(par_iApplicationPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("599b29b4-8bd9-4380-bd51-8ad5a6c35c92","Application")
    :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_lResult := (l_oData:Application_DestructiveDelete >= APPLICATIONDESTRUCTIVEDELETE_ONNAMESPACES)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructiveTableDelete(par_iApplicationPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("599b29b4-8bd9-4380-bd51-8ad5a6c35c93","Application")
    :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_lResult := (l_oData:Application_DestructiveDelete >= APPLICATIONDESTRUCTIVEDELETE_ONTABLESTAGS)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructiveEnumerationDelete(par_iApplicationPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("1ae29fc6-aa97-4471-962c-964f53664dc2","Application")
    :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        //For now will assume if it is allowed to delete Tables, so it is for enumerations
        l_lResult := (l_oData:Application_DestructiveDelete >= APPLICATIONDESTRUCTIVEDELETE_ONTABLESTAGS)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructivePurgeApplication(par_iApplicationPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("599b29b4-8bd9-4380-bd51-8ad5a6c35c94","Application")
    :Column("Application.DestructiveDelete" , "Application_DestructiveDelete")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_lResult := (l_oData:Application_DestructiveDelete >= APPLICATIONDESTRUCTIVEDELETE_ENTIREAPPLICATIONCONTENT)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructiveModelDelete(par_iProjectPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("4c418c2f-79a1-40cf-ac79-21d17a0edc52","Project")
    :Column("Project.DestructiveDelete" , "Project_DestructiveDelete")
    l_oData := :Get(par_iProjectPk)
    if :Tally == 1
        l_lResult := (l_oData:Project_DestructiveDelete >= PROJECTDESTRUCTIVEDELETE_CANDELETEMODELS)
    endif
endwith

return l_lResult
//=================================================================================================================
function CheckIfAllowDestructiveEntityAssociationDelete(par_iProjectPk)
local l_lResult := .f.
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

with object l_oDB1
    :Table("4c418c2f-79a1-40cf-ac79-21d17a0edc53","Project")
    :Column("Project.DestructiveDelete" , "Project_DestructiveDelete")
    l_oData := :Get(par_iProjectPk)
    if :Tally == 1
        l_lResult := (l_oData:Project_DestructiveDelete >= PROJECTDESTRUCTIVEDELETE_ONENTITIESASSOCIATIONS)
    endif
endwith

return l_lResult
//=================================================================================================================
function SetSelect2Support()

//Code in progress see WebPage_InterAppMapping.prg

local l_ScriptFolder

l_ScriptFolder := oFcgi:p_cSitePath+[scripts/jQuerySelect2_]+JQUERYSELECT2_SCRIPT_VERSION+[/]
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
function SQLExec(par_SQLHandle,par_Command,par_cCursorName)
local l_cPreviousDefaultRDD := RDDSETDEFAULT("SQLMIX")
local l_lSQLExecResult := .f.
local l_oError
local l_select := iif(used(),select(),0)
local cErrorInfo
local l_cSQLExecErrorMessage

l_cSQLExecErrorMessage:= ""
if par_SQLHandle > 0
    try
        if pcount() == 3
            CloseAlias(par_cCursorName)
            select 0  //Ensure we don't overwrite any other work area
            l_lSQLExecResult := DBUseArea(.t.,"SQLMIX",par_Command,par_cCursorName,.t.,.t.,"UTF8",par_SQLHandle)
            if l_lSQLExecResult
                //There is a bug with reccount() when using SQLMIX. So to force loading all the data, using goto bottom+goto top
                dbGoBottom()
                dbGoTop()
            endif
        else
            l_lSQLExecResult := hb_RDDInfo(RDDI_EXECUTE,par_Command,"SQLMIX",par_SQLHandle)
        endif

        if !l_lSQLExecResult
            l_cSQLExecErrorMessage := "SQLExec Error Code: "+Trans(hb_RDDInfo(RDDI_ERRORNO))+" - Error description: "+alltrim(hb_RDDInfo(RDDI_ERROR))
        endif
    catch l_oError
        l_lSQLExecResult := .f.  //Just in case the catch occurs after DBUserArea / hb_RDDInfo
        l_cSQLExecErrorMessage := "SQLExec Error Code: "+Trans(l_oError:oscode)+" - Error description: "+alltrim(l_oError:description)+" - Operation: "+l_oError:operation
        // Idea for later  ::SQLSendToLogFileAndMonitoringSystem(0,1,l_cSQLCommand+[ -> ]+l_cSQLExecErrorMessage)  _M_
    endtry

    if !empty(l_cSQLExecErrorMessage)
        cErrorInfo := hb_StrReplace(l_cSQLExecErrorMessage+" - Command: "+par_Command+iif(pcount() < 3,""," - Cursor Name: "+par_cCursorName),{chr(13)=>" ",chr(10)=>""})
        hb_orm_SendToDebugView(cErrorInfo)
    endif

endif

RDDSETDEFAULT(l_cPreviousDefaultRDD)
select (l_select)
    
return l_lSQLExecResult
//=================================================================================================================
#ifdef __PLATFORM__LINUX
    function CurlUrl(p_cUrl, p_cMethod, p_aHeaders, p_cFormContent)
    local l_pCurlHandle
    local l_nResult
    local l_cResult

    if empty(Curl_Global_Init())
        l_pCurlHandle := curl_easy_init()
        if !hb_IsNil(l_pCurlHandle)

            if !empty(p_aHeaders)
                Curl_Easy_SetOpt(l_pCurlHandle, HB_CURLOPT_HTTPHEADER,p_aHeaders)
            endif

            if !empty(p_cFormContent)
                CURL_EASY_SETOPT( l_pCurlHandle, HB_CURLOPT_COPYPOSTFIELDS,  p_cFormContent)
            endif

            Curl_Easy_SetOpt(l_pCurlHandle, HB_CURLOPT_URL, p_cUrl)
            if p_cMethod == "POST"
                Curl_Easy_SetOpt(l_pCurlHandle, HB_CURLOPT_POST, .t.)
            endif
            
            Curl_Easy_SetOpt(l_pCurlHandle, HB_CURLOPT_DL_BUFF_SETUP , 100*1024)  // Max Buffer download size set to 100 Kb

            l_nResult := Curl_Easy_Perform(l_pCurlHandle)

            if empty(l_nResult)
                l_cResult := curl_easy_dl_buff_get( l_pCurlHandle )
            else
                l_cResult := alltrim(Str( l_nResult, 5 )) + " " + curl_easy_strerror( l_nResult )
            endif

            curl_easy_cleanup(l_pCurlHandle)
        endif
        Curl_Global_Cleanup()
    endif

    return l_cResult

    function getLinuxEpochTime()
    return (hb_datetime() - hb_ctot("1970-01-01","YYYY-MM-DD"))*24*60*60
    //===========================================================================================================================
    function AutoProvisionUser(p_cUserId, p_cUserGivenName, p_cUserFamilyName, l_pUserDescription)
        local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        local l_iUserPk
        local l_cErrorMessage

        local l_nAccessLevelML := 2 //default access level for projects
        local l_nAccessLevelDD := 2 //default access level for applications
    
        local l_oDB_ListOfCurrentApplicationForUser := hb_SQLData(oFcgi:p_o_SQLConnection)
        local l_oDB_ListOfCurrentProjectForUser     := hb_SQLData(oFcgi:p_o_SQLConnection)

        local l_oDB_ListOfApplications              := hb_SQLData(oFcgi:p_o_SQLConnection)
        local l_oDB_ListOfProjects                  := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("CFEFD791-A60C-48A8-9904-2CCEBCDB7D96","User")
            :Field("User.FirstName",  p_cUserGivenName)
            :Field("User.LastName" ,  p_cUserFamilyName)
            :Field("User.ID"       ,  p_cUserId)
            :Field("User.AccessMode", 2) //default is read access to everything
            :Field("User.Status"    , 1)
            :Field("User.Description",iif(empty(l_pUserDescription),NULL,l_pUserDescription))
            if :Add()
                l_iUserPk := :Key()
            else
                l_cErrorMessage := "Failed to add User."
            endif


            //Update the list selected Applications -----------------------------------------------
            if empty(l_cErrorMessage)
                with Object l_oDB_ListOfApplications
                    :Table("1B2B5269-2B57-4D9F-926A-D10A99B6CAE4","Application")
                    :Column("Application.pk","pk")
                    :SQL("ListOfApplications")
                endwith

                if l_nAccessLevelDD > 1
                    // Add the Application only if more than "None"
                    :Table("46911A55-4267-4A1E-B267-FEEFA750B98C","UserAccessApplication")
                    :Field("UserAccessApplication.fk_Application",ListOfApplications->pk)
                    :Field("UserAccessApplication.fk_User"       ,l_iUserPk)
                    :Field("UserAccessApplication.AccessLevelDD" ,l_nAccessLevelDD)
                    if !:Add()
                        l_cErrorMessage := "Failed to Save Application access rights."
                    endif
                endif
            endif

            //Update the list selected Projects -----------------------------------------------
            if empty(l_cErrorMessage)
                with Object l_oDB_ListOfProjects
                    :Table("2B38794D-9960-498C-8B9E-B9A8C80EC26C","Project")
                    :Column("Project.pk","pk")
                    :SQL("ListOfProjects")
                endwith

                if l_nAccessLevelML > 1
                    // Add the Project only if more than "None"
                    :Table("3F775AF0-784F-46AF-BE5C-B19512AB91DD","UserAccessProject")
                    :Field("UserAccessProject.fk_Project"   ,ListOfProjects->pk)
                    :Field("UserAccessProject.fk_User"      ,l_iUserPk)
                    :Field("UserAccessProject.AccessLevelML",l_nAccessLevelML)
                    if !:Add()
                        l_cErrorMessage := "Failed to Save Project access rights."
                    endif
                endif
            endif
        endwith
    return l_iUserPk
#endif
//=================================================================================================================
function GetTRStyleBackgroundColorUseStatus(par_iRecno,par_nUseStatus,par_cOpacity)
local l_cHtml
local l_cOpacity := hb_DefaultValue(par_cOpacity,"0.3")
do case
case par_nUseStatus == USESTATUS_PROPOSED
    // l_cHtml := [ style="background-color:#]+USESTATUS_2_NODE_BACKGROUND+[;"]
    l_cHtml := [ style="background-color:rgb(]+USESTATUS_2_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
case par_nUseStatus == USESTATUS_UNDERDEVELOPMENT
    // l_cHtml := [ style="background-color:#]+USESTATUS_3_NODE_BACKGROUND+[;"]
    l_cHtml := [ style="background-color:rgb(]+USESTATUS_3_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
case par_nUseStatus == USESTATUS_TOBEDISCONTINUED
    // l_cHtml := [ style="background-color:#]+USESTATUS_5_NODE_BACKGROUND+[;"]
    l_cHtml := [ style="background-color:rgb(]+USESTATUS_5_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
case par_nUseStatus == USESTATUS_DISCONTINUED
    // l_cHtml := [ style="background-color:#]+USESTATUS_6_NODE_BACKGROUND+[;"]
    l_cHtml := [ style="background-color:rgb(]+USESTATUS_6_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
otherwise
    if par_iRecno > 0 .and. mod(par_iRecno,2) == 0
        l_cHtml := [ style="background-color:#f2f2f2;"]
    else
        l_cHtml := ""
    endif
endcase
return l_cHtml
//=================================================================================================================
function GetTRStyleBackgroundColorDeploymentStatus(par_iRecno,par_nUseStatus,par_cOpacity)
local l_cHtml
local l_cOpacity := hb_DefaultValue(par_cOpacity,"0.3")
do case
case par_nUseStatus == 2  // On Hold
    l_cHtml := [ style="background-color:rgb(]+USESTATUS_6_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
otherwise
    if par_iRecno > 0 .and. mod(par_iRecno,2) == 0
        l_cHtml := [ style="background-color:#f2f2f2;"]
    else
        l_cHtml := ""
    endif
endcase
return l_cHtml
//=================================================================================================================
function GetTRStyleBackgroundColorStage(par_iRecno,par_nStage,par_cOpacity)
local l_cHtml
local l_cOpacity := hb_DefaultValue(par_cOpacity,"0.3")

//1 = Proposed, 2 = Draft, 3 = Beta, 4 = Stable, 5 = In Use, 6 = Discontinued

do case
case par_nStage == 6  // To be Discontinued
    l_cHtml := [ style="background-color:rgb(]+STAGE_6_NODE_TR_BACKGROUND+[,]+l_cOpacity+[);"]
otherwise
    if par_iRecno > 0 .and. mod(par_iRecno,2) == 0
        l_cHtml := [ style="background-color:#f2f2f2;"]
    else
        l_cHtml := ""
    endif
endcase

return l_cHtml
//=================================================================================================================
function CompareVersionsWithDecimals(par_nVal1,par_nVal2)  // return 0 if same, -1 if par_nVal1 < par_nVal2, 1 otherwise
local l_nResult
local l_nDecimal1
local l_nDecimal2

if par_nVal1 == par_nVal2
    l_nResult := 0
else
    if int(par_nVal1) == int(par_nVal2)
        //Compare decimals
        l_nDecimal1 := val(substr(alltrim(str(par_nVal1-int(par_nVal1))),3))
        l_nDecimal2 := val(substr(alltrim(str(par_nVal2-int(par_nVal2))),3))
        l_nResult := iif(l_nDecimal1 < l_nDecimal2,-1,1)
    else
        l_nResult := iif(int(par_nVal1) < int(par_nVal2),-1,1)
    endif
endif

return l_nResult
//=================================================================================================================
function GetStreamFileFolderForCurrentProcess()
local l_iPID := el_GetProcessId()
local l_cFilePath

l_cFilePath := el_AddPs(oFCgi:PathBackend)+"StreamFile"
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()+trans(l_iPID)
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()

return l_cFilePath
//=================================================================================================================
function GetStreamFileFolderForCurrentUser()
local l_cFilePath

l_cFilePath := el_AddPs(oFCgi:PathBackend)+"UserStreamFile"
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()+trans(oFcgi:p_iUserPk)
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()

return l_cFilePath
//=================================================================================================================
function PurgeStreamFileFolders()
local l_cFilePath

l_cFilePath := el_AddPs(oFCgi:PathBackend)+"UserStreamFile"+hb_ps()
hb_DirRemoveAll(l_cFilePath)
hb_DirCreate(l_cFilePath)

l_cFilePath := el_AddPs(oFCgi:PathBackend)+"StreamFile"+hb_ps()
hb_DirRemoveAll(l_cFilePath)
hb_DirCreate(l_cFilePath)

return nil
//=================================================================================================================
function PurgeVolatileFiles()
local l_cSQLCommand

with object oFcgi:p_o_SQLConnection
    l_cSQLCommand := [SELECT lo_unlink(largeobjects.oid) FROM pg_largeobject_metadata AS largeobjects]
    :SQLExec("PurgeVolatileFilesStep1",l_cSQLCommand)

    l_cSQLCommand := [TRUNCATE TABLE "volatile"."FileStream"]
    :SQLExec("PurgeVolatileFilesStep2",l_cSQLCommand)

endwith

return nil
//=================================================================================================================
function GetZuluTimeStampForFileNameSuffix()
local l_cTimeStamp := hb_TSToStr(hb_TSToUTC(hb_DateTime()))
l_cTimeStamp := left(l_cTimeStamp,len(l_cTimeStamp)-4)
return hb_StrReplace( l_cTimeStamp , {" "=>"-",":"=>"-"})+"-Zulu"
//=================================================================================================================
function UpdateAPIEndpoint()
local l_oDB_ListOfAPIEndpoint := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_APIEndpoint       := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_pAPITokens
local l_cAPITokenName
local l_cAPITokenNameOnFile

with object l_oDB_ListOfAPIEndpoint
    :Table("319b73ad-958b-4a27-b331-2556059ec31b","APIEndpoint")
    :Column("APIEndpoint.pk"    ,"pk")
    :Column("APIEndpoint.Name"  ,"APIEndpoint_Name")
    :Column("APIEndpoint.Status","APIEndpoint_Status")
    :Column("Upper(APIEndpoint.Name)","tag1")
    :OrderBy("tag1")

    :SQL("ListOfAPIEndpoint")
    if :Tally >= 0
        with object :p_oCursor
            :Index("tag1","padr(tag1+'*',240)")
            :CreateIndexes()
        endwith

        for each l_pAPITokens in oFcgi:p_APIs
            l_cAPITokenName := l_pAPITokens:__enumkey

            // if el_seek(padr(upper(l_cAPITokenName)+'*',240),"ListOfAPIEndpoint","tag1")
            if el_seek(upper(l_cAPITokenName)+'*',"ListOfAPIEndpoint","tag1")
                l_cAPITokenNameOnFile := alltrim(ListOfAPIEndpoint->APIEndpoint_Name)
                if !(l_cAPITokenNameOnFile == l_cAPITokenName) .or. ListOfAPIEndpoint->APIEndpoint_Status != 1
                    //Casing or Status changed
                    :Table("ba56a297-8097-4414-81b7-7d796f42ebfe","APIEndpoint")
                    :Field("APIEndpoint.Name"   , l_cAPITokenName)
                    :Field("APIEndpoint.Status" , 1)
                    :Update(ListOfAPIEndpoint->Pk)
                endif
                l_oDB_ListOfAPIEndpoint:p_oCursor:SetFieldValue("APIEndpoint_Status",0)  //To mark as processed
            else
                with object l_oDB_APIEndpoint
                    :Table("ba56a297-8097-4414-81b7-7d796f42ebfd","APIEndpoint")
                    :Field("APIEndpoint.Name"   , l_cAPITokenName)
                    :Field("APIEndpoint.Status" , 1)
                    :Add()
                endwith
            endif
        endfor

        //Disable any no longer defined Endpoints
        select ListOfAPIEndpoint
        scan all for ListOfAPIEndpoint->APIEndpoint_Status != 0
            :Table("ba56a297-8097-4414-81b7-7d796f42ebfb","APIEndpoint")
            :Field("APIEndpoint.Status" , 2)
            :Update(ListOfAPIEndpoint->Pk)
        endscan

    endif
endwith

return nil
//=================================================================================================================
//=================================================================================================================
function DisplayErrorMessageOnEditForm(par_cErrorText)
local l_cHtml
if empty(par_cErrorText)
    l_cHtml := ""
else
    l_cHtml := [<div class="p-3 mb-2 bg-]+iif(lower(left(par_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+TextToHtml(par_cErrorText)+[</div>]
    oFcgi:p_cjQueryScript += GOINEDITMODE
endif
return l_cHtml
//=================================================================================================================
function DisplayTestWarningMessageOnEditForm(par_cWarningText)
local l_cHtml
if empty(par_cWarningText)
    l_cHtml := ""
else
    l_cHtml := [<div class="p-3 mb-2 bg-warning text-danger">]+TextToHtml(par_cWarningText)+[</div>]
endif
return l_cHtml
//=================================================================================================================
function DisplayErrorMessageOnViewForm(par_cErrorText)
local l_cHtml
if empty(par_cErrorText)
    l_cHtml := ""
else
    l_cHtml := [<div class="p-3 mb-2 bg-]+iif(lower(left(par_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+par_cErrorText+[</div>]
endif
return l_cHtml
//=================================================================================================================
function GetButtonOnEditFormSave()


                // l_cHtml += CRLF
                // l_cHtml += 
                // l_cHtml += [$(function() {]+CRLF
                // l_cHtml += ::p_cjQueryScript+CRLF
                // l_cHtml += [});]+CRLF
                // l_cHtml += [</script>]+CRLF


oFcgi:p_cHeader += CRLF
oFcgi:p_cHeader += [<script type="text/javascript" language="Javascript">]+CRLF
oFcgi:p_cHeader += 'var v_EditFormNotInEditMode = true;'
oFcgi:p_cHeader += 'function ToggleEditFormMode() {'
oFcgi:p_cHeader += 'if (v_EditFormNotInEditMode){'
oFcgi:p_cHeader += 'v_EditFormNotInEditMode = false;'
oFcgi:p_cHeader += GOINEDITMODE
oFcgi:p_cHeader += '};return true;}'+CRLF
oFcgi:p_cHeader += [</script>]+CRLF

return [<input type="submit" class="btn btn-primary rounded ms-3 disabled" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
//=================================================================================================================
function GetButtonOnEditFormDoneCancel()
return [<input type="button" class="btn btn-primary rounded ms-3" id="ButtonDoneCancel" name="ButtonDoneCancel" value="Done" onclick="$('#ActionOnSubmit').val( $(this).val() );document.form.submit();" role="button">]
//=================================================================================================================
function GetButtonOnEditFormDelete()
return [<button type="button" class="btn btn-danger rounded ms-3 RemoveOnEdit" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
//=================================================================================================================
function GetButtonOnEditFormDuplicate()
return [<button type="button" class="btn btn-primary rounded ms-3 RemoveOnEdit" data-bs-toggle="modal" data-bs-target="#ConfirmDuplicateModal">Duplicate</button>]
//=================================================================================================================
function GetButtonOnEditFormNew(par_cCaption,par_cURL)
return [<a class="btn btn-primary rounded ms-3 RemoveOnEdit" href="]+par_cURL+["><span class="text-white bi-plus-lg"></span>&nbsp;]+par_cCaption+[</a>]
//=================================================================================================================
function GetButtonOnOrderListFormSave()
return [<input type="submit" class="btn btn-primary rounded ms-3" id="ButtonSave" name="ButtonSave" value="Save" onclick="SendOrderList();" role="button">]
//=================================================================================================================
function GetButtonCancelAndRedirect(par_cURL)
return [<a class="btn btn-primary rounded ms-3" href="]+par_cURL+[">Cancel</a>]
//=================================================================================================================
function GetButtonOnEditFormCaptionAndRedirect(par_cCaption,par_cURL,par_lDisabled)
local l_lDisabled := nvl(par_lDisabled,.f.)
return [<a class="btn btn-primary rounded ms-3 RemoveOnEdit]+iif(l_lDisabled,[ disabled],[])+[" href="]+par_cURL+[">]+par_cCaption+[</a>]
//=================================================================================================================
function GetButtonOnListFormCaptionAndRedirect(par_cCaption,par_cURL,par_lDisabled)
local l_lDisabled := nvl(par_lDisabled,.f.)
return [<a class="btn btn-primary rounded ms-3]+iif(l_lDisabled,[ disabled],[])+[" href="]+par_cURL+[">]+par_cCaption+[</a>]
//=================================================================================================================
function GetButtonOnEditForm(par_cName,par_cCaption,par_cAction)
return [<input type="button" class="btn btn-primary rounded ms-3" id="]+par_cName+[" name="]+par_cName+[" value="]+par_cCaption+[" onclick="$('#ActionOnSubmit').val(']+par_cAction+[');document.form.submit();" role="button">]
//=================================================================================================================
function GetCheckboxOnEditForm(par_cObjectName,par_lValue,par_cLabel,par_lDisabled)
local l_cHtml
l_cHtml := [<span class="form-check form-switch">]
l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="]+par_cObjectName+[" id="]+par_cObjectName+[" value="1"]+iif(par_lValue," checked","")+[ class="form-check-input"]+iif(nvl(par_lDisabled,.f.),[ disabled],[])+[>]
if !hb_IsNil(par_cLabel) .and. !empty(par_cLabel)
    l_cHtml += [<label class="form-check-label" for="]+par_cObjectName+[">&nbsp;]+par_cLabel+[</label>]
endif
l_cHtml += [</span>]
return l_cHtml
//=================================================================================================================
function ActivatejQuerySelect2(par_cObjectRef,par_cJSON)
oFcgi:p_cjQueryScript += [$("]+par_cObjectRef+[").select2({placeholder: '',]+;
                                                        [allowClear: true,]+;
                                                        [data: ]+par_cJSON+[,]+;
                                                        [theme: "bootstrap-5",]+;
                                                        [selectionCssClass: "select2--small",]+;
                                                        [dropdownCssClass: "select2--small"}]+;
                                                        [);]

//Could not use the "change" event below, since it is trigger when the select is being populated
oFcgi:p_cjQueryScript += [$("]+par_cObjectRef+[").on("select2:select", function (e) {]+GOINEDITMODE+[});]
oFcgi:p_cjQueryScript += [$("]+par_cObjectRef+[").on("select2:unselect", function (e) {]+GOINEDITMODE+[});]
return nil
//=================================================================================================================
//=================================================================================================================

//=================================================================================================================
function el_StringFilterCharacters(par_cText,par_cValidCharacters)
local l_cResult := ""
local l_cChar

for each l_cChar in @par_cText
    if l_cChar $ par_cValidCharacters
        l_cResult += l_cChar
    endif
endfor

return l_cResult
//=================================================================================================================
function EncodeStringForHashText(par_cString)

local l_cEncodedText := []
local l_cUTFEncoding
local l_nPos
local l_nUTF8Value := 0
local l_nNumberOfBytesOfTheCharacter := 0
// local l_cAdditionalCharactersToEscape := hb_DefaultValue(par_cAdditionalCharactersToEscape,"")

if !empty(par_cString)

    l_nPos := 1
    do while (l_nPos <= len(par_cString)) 
        if hb_UTF8FastPeek(par_cString,l_nPos,@l_nUTF8Value,@l_nNumberOfBytesOfTheCharacter)
            if l_nNumberOfBytesOfTheCharacter > 0  // UTF Character
                l_nPos += l_nNumberOfBytesOfTheCharacter
            else
                l_nPos++
            endif

            // 92 = \, 39 = ', 34 = ", 63 = ?

            // if l_nUTF8Value < 31 .or. l_nUTF8Value > 126 .or. l_nUTF8Value == 92 .or. l_nUTF8Value == 39 .or. l_nUTF8Value == 34 .or. l_nUTF8Value == 63 ;
            //    .or. (l_nUTF8Value < 127 .and. !empty(l_cAdditionalCharactersToEscape) .and. (chr(l_nUTF8Value) $ l_cAdditionalCharactersToEscape))

            if l_nUTF8Value < 31 .or. l_nUTF8Value > 126 .or. l_nUTF8Value == 92 .or. l_nUTF8Value == 39 .or. l_nUTF8Value == 34 .or. l_nUTF8Value == 63
                do case
                case l_nUTF8Value == 92  // \
                    l_cEncodedText += [\\]
                case l_nUTF8Value == 39  // '
                    l_cEncodedText += [\']
                case l_nUTF8Value == 34  // "
                    l_cEncodedText += [\"]
                case l_nUTF8Value == 63  // ?
                    l_cEncodedText += [\?]
                otherwise
                    l_cUTFEncoding := hb_NumToHex(l_nUTF8Value,8)
                    do case
                    case l_cUTFEncoding == [00000000]
                        //To clean up bad data
                        exit
                    case left(l_cUTFEncoding,4) == [0000]
                        l_cEncodedText += [\u]+right(l_cUTFEncoding,4)
                    otherwise
                        l_cEncodedText += [\U]+l_cUTFEncoding
                    endcase
                endcase

            else
                l_cEncodedText += chr(l_nUTF8Value)
            endif

        else
            //Skip the bad character
            l_nPos++
        endif
    enddo

    if l_cEncodedText != par_cString
        l_cEncodedText := [E']+l_cEncodedText+[']
    endif

endif

return l_cEncodedText
//=================================================================================================================
function PrepareForURLSQLIdentifier(par_cOrigin,par_cName,par_xVal)   // Will keep the name or sub for pk with prefix if identifier is not alphanumeric
local l_cResult

if par_cOrigin == "EnumValue"
    if par_cName == el_StringFilterCharacters(par_cName,"_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-()+")
        l_cResult := par_cName
    else
        if valtype(par_xVal) == "C"
            l_cResult := "~"+par_xVal
        else
            l_cResult := "~"+trans(par_xVal)
        endif
    endif
else
    if par_cName == el_StringFilterCharacters(par_cName,"_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        l_cResult := par_cName
    else
        if valtype(par_xVal) == "C"
            l_cResult := "~"+par_xVal
        else
            l_cResult := "~"+trans(par_xVal)
        endif
    endif
endif

return l_cResult
//=================================================================================================================
function AssembleNavbarInfo(par_cAction,par_aInfo)   // par_aInfo = {Source,Name,AKA,LinkUID}
static s_aInfo := {}
local l_aInfo
local l_cResult

do case
case par_cAction == "Add"
    l_cResult := nil
    AAdd(s_aInfo,par_aInfo)
case par_cAction == "Build"
    l_cResult := ""
    for each l_aInfo in s_aInfo
        if !empty(l_cResult)
            l_cResult += "."
        endif
        l_cResult += FcgiPrepFieldForValue(l_aInfo[2])
        if !hb_IsNil(l_aInfo[3])
            l_cResult += FcgiPrepFieldForValue(FormatAKAForDisplay(l_aInfo[3]))
        endif
    endfor
    s_aInfo := {}
endcase

return l_cResult
//=================================================================================================================
function GetMultiFlagSearchInput(par_cObjectName,pac_cJSON,par_cCurrentValue,par_nSize)
local l_cHtml

// oFcgi:p_cjQueryScript += [$("#]+par_cObjectName+[").amsifySuggestags({]+;
//                                                                 "suggestions :["+pac_cJSON+"],"+;
//                                                                 "whiteList: true,"+;
//                                                                 "tagLimit: 10,"+;
//                                                                 "selectOnHover: true,"+;
//                                                                 "showAllSuggestions: true,"+;
//                                                                 "keepLastOnHoverTag: false,"+;
//                                                                 "afterAdd: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }},"+;
//                                                                 "afterRemove: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }}"+;
//                                                                 [});]

oFcgi:p_cjQueryScript += [$("#]+par_cObjectName+[").amsifySuggestags({]+;
                                                                "suggestions :["+pac_cJSON+"],"+;
                                                                "whiteList: true,"+;
                                                                "tagLimit: 20,"+;
                                                                "selectOnHover: true,"+;
                                                                "showAllSuggestions: true,"+;
                                                                "keepLastOnHoverTag: false"+;
                                                                [});]


l_cHtml := [<input type="text" name="]+par_cObjectName+[" id="]+par_cObjectName+[" size="]+Trans(par_nSize)+[" maxlength="10000" value="]+FcgiPrepFieldForValue(par_cCurrentValue)+[" class="form-control TextSearchTag" placeholder="">]
   //  style="width:100px;"     TextSearchTag
return l_cHtml
//=================================================================================================================
function GetFormattedUseStatusCounts(par_nCountProposed,par_nCount,par_nCountDiscontinued)
local l_cHtml := ""

if par_nCountProposed+par_nCount+par_nCountDiscontinued > 0
    if par_nCountProposed > 0
        l_cHtml += [<span class="text-info">]+trans(par_nCountProposed)+[</span>&nbsp;&nbsp;]
    endif
    l_cHtml += Trans(par_nCount)
    if par_nCountDiscontinued > 0
        l_cHtml += [&nbsp;&nbsp;<span class="text-danger">]+trans(par_nCountDiscontinued)+[<span>]
    endif
endif

return l_cHtml
//=================================================================================================================
function GetCopyToClipboardJavaScript(par_cButtonId)
local l_cJavaScript
local l_cHtml

l_cJavaScript := [function copyToClip(str) {]
l_cJavaScript +=   [function listener(e) {]
l_cJavaScript +=     [e.clipboardData.setData("text/html", str);]
l_cJavaScript +=     [e.clipboardData.setData("text/plain", str);]
l_cJavaScript +=     [e.preventDefault();]
l_cJavaScript +=   [}]
l_cJavaScript +=   [document.addEventListener("copy", listener);]
l_cJavaScript +=   [document.execCommand("copy");]
l_cJavaScript +=   [document.removeEventListener("copy", listener);]
l_cJavaScript +=   [$('#]+par_cButtonId+[').addClass('btn-success').removeClass('btn-primary');]
l_cJavaScript += [};]

l_cHtml := [<script type="text/javascript" language="Javascript">]+CRLF
l_cHtml += l_cJavaScript+CRLF
l_cHtml += [</script>]+CRLF

return l_cHtml
//=================================================================================================================
