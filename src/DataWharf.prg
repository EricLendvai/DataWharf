//Copyright (c) 2023 Eric Lendvai MIT License

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
                           "Health"           => {"Health"                   ,0,.f.,@BuildPageHealth()} }   //Does not require to be logged in.

hb_HCaseMatch(v_hPageMapping,.f.)

SendToDebugView("Starting DataWharf FastCGI App")

hb_cdpSelect("UTF8")

set century on

hb_DirCreate(OUTPUT_FOLDER+hb_ps())

oFcgi := MyFcgi():New()    // Used a subclass of hb_Fcgi

hb_HCaseMatch(oFcgi:p_APIs,.f.)

do while oFcgi:Wait()
    oFcgi:OnRequest()
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

    data p_ColumnTypes      init {{  "I","Integer (4 bytes)"                            ,.f.,.f.,.f.,.f.,"integer"                    ,"INT"},;      // {Code,Harbour Name,Show Length,Show Scale,Show Enums,PostgreSQL Name, MySQL Name}
                                  { "IB","Integer Big (8 bytes)"                        ,.f.,.f.,.f.,.f.,"bigint"                     ,"BIGINT"},;
                                  { "IS","Integer Small (2 bytes)"                      ,.f.,.f.,.f.,.f.,"smallint"                   ,"SMALLINT"},;
                                  {  "N","Numeric"                                      ,.t.,.t.,.f.,.f.,"numeric"                    ,"DECIMAL"},;
                                  {  "C","Character String"                             ,.t.,.f.,.f.,.t.,"character"                  ,"CHAR"},;
                                  { "CV","Character String Varying"                     ,.t.,.f.,.f.,.t.,"character varying"          ,"VARCHAR"},;
                                  {  "B","Binary String"                                ,.t.,.f.,.f.,.f.,"bit"                        ,"BINARY"},;
                                  { "BV","Binary String Varying"                        ,.t.,.f.,.f.,.f.,"bit varying"                ,"VARBINARY"},;
                                  {  "M","Memo / Long Text"                             ,.f.,.f.,.f.,.t.,"text"                       ,"LONGTEXT"},;
                                  {  "R","Raw Binary"                                   ,.f.,.f.,.f.,.f.,"bytea"                      ,"LONGBLOB"},;
                                  {  "L","Logical"                                      ,.f.,.f.,.f.,.f.,"boolean"                    ,"TINYINT(1)"},;
                                  {  "D","Date"                                         ,.f.,.f.,.f.,.f.,"date"                       ,"DATE"},;
                                  {"TOZ","Time Only With Time Zone Conversion"          ,.f.,.f.,.f.,.f.,"time with time zone"        ,"TIME COMMENT 'Type=TOZ'"},;
                                  { "TO","Time Only Without Time Zone Conversion"       ,.f.,.f.,.f.,.f.,"time without time zone"     ,"TIME"},;
                                  {"DTZ","Date and Time With Time Zone Conversion (T)"  ,.f.,.f.,.f.,.f.,"timestamp with time zone"   ,"TIMESTAMP"},;
                                  { "DT","Date and Time Without Time Zone Conversion"   ,.f.,.f.,.f.,.f.,"timestamp without time zone","DATETIME"},;
                                  {  "Y","Money"                                        ,.f.,.f.,.f.,.f.,"money"                      ,"DECIMAL(13,4) COMMENT 'Type=Y'"},;
                                  {  "E","Enumeration"                                  ,.f.,.f.,.t.,.f.,"enum"                       ,"ENUM"},;
                                  {"UUI","UUID Universally Unique Identifier"           ,.f.,.f.,.f.,.f.,"uuid"                       ,"VARCHAR(36)"},;   // In DBF VarChar 36
                                  { "JS","JSON"                                         ,.f.,.f.,.f.,.f.,"json"                       ,"LONGTEXT"},;
                                  {"OID","Object Identifier"                            ,.f.,.f.,.f.,.f.,"oid"                        ,"BIGINT COMMENT 'Type=OID'"},;
                                  {  "?","Other"                                        ,.f.,.f.,.f.,.f.,""                           ,""};
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
local l_oDB1
local l_oDB2
// local l_oDB3
local l_cSecuritySalt
local l_cSecurityDefaultPassword
local l_iCurrentDataVersion
local l_cVisPos
local l_cTableName
local l_cName
local l_cLastSQL

// altd()

SendToDebugView("Called from method OnFirstRequest")

set century on
set delete on

::SetOnErrorDetailLevel(2)
::SetOnErrorProgramInfo(hb_BuildInfo())

::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",;
                                    ::GetAppConfig("POSTGRESDRIVER"),;
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
                v_iFastCGIRunLogPk := :Key()
            endif
        endwith

        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 1
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
        if l_iCurrentDataVersion < 4
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
        if l_iCurrentDataVersion < 5
            if ::p_o_SQLConnection:FieldExists("public.UserAccessApplication","AccessLevel")
                ::p_o_SQLConnection:DeleteField("public.UserAccessApplication","AccessLevel")
            endif
            l_iCurrentDataVersion := 5
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 6
            if ::p_o_SQLConnection:TableExists("public.AssociationEnd")
                ::p_o_SQLConnection:DeleteTable("public.AssociationEnd")
            endif
            l_iCurrentDataVersion := 6
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 7
            if ::p_o_SQLConnection:FieldExists("public.Attribute","fk_Association")
                ::p_o_SQLConnection:DeleteField("public.Attribute","fk_Association")
            endif

            l_iCurrentDataVersion := 7
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 8
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
        if l_iCurrentDataVersion < 9
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
        if l_iCurrentDataVersion < 10
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
        if l_iCurrentDataVersion < 11
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
        if l_iCurrentDataVersion < 14
            with object l_oDB1
                :Table("bb6ceea9-72f0-471f-b555-0affd9359cb3","Diagram")
                :Column("Diagram.pk"     , "pk")
                :Column("Diagram.VisPos" , "Diagram_VisPos")
                :Where([Diagram.VisPos is not null])
                :Where([Diagram.VisPos not like '%T%'])
                :SQL("ListOfDiagramToUpdate")
                select ListOfDiagramToUpdate
                scan all
                    l_cVisPos := Strtran(ListOfDiagramToUpdate->Diagram_VisPos,[{"x],chr(1))
                    l_cVisPos := Strtran(l_cVisPos,[,"y],chr(2))
                    l_cVisPos := Strtran(l_cVisPos,[{"],[{"T])
                    l_cVisPos := Strtran(l_cVisPos,[,"],[,"T])
                    l_cVisPos := Strtran(l_cVisPos,chr(1),[{"x])
                    l_cVisPos := Strtran(l_cVisPos,chr(2),[,"y])

                    with object l_oDB2
                        :Table("ed4bed4f-30d0-4dd7-9639-4314e80c0cd5","Diagram")
                        :Field("Diagram.VisPos" , l_cVisPos)
                        :Update(ListOfDiagramToUpdate->pk)
                    endwith
                endscan
            endwith

            l_iCurrentDataVersion := 14
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 15
            with object l_oDB1
                :Table("6a473090-8c14-47f7-a1dc-95f79a4e45b4","Diagram")
                :Column("Diagram.pk" , "pk")
                :Where([Diagram.RenderMode = 0])
                :SQL("ListOfDiagramToUpdate")
                select ListOfDiagramToUpdate
                scan all
                    with object l_oDB2
                        :Table("ed08301f-15d4-4ae4-b7b1-838974333135","Diagram")
                        :Field("Diagram.RenderMode" , RENDERMODE_VISJS)
                        :Update(ListOfDiagramToUpdate->pk)
                    endwith
                endscan
            endwith

            l_iCurrentDataVersion := 15
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 16
            with object l_oDB1
                For each l_cTableName in {"Application","Column","Diagram","Enumeration","EnumValue","Index","NameSpace","Project","Table","Association","Attribute","DataType","Entity","ModelEnumeration","ModelingDiagram","Package"}
                    :Table("28f6f015-c468-4199-a5d2-c25dee474fff",l_cTableName)
                    :Column(l_cTableName+".pk" , "pk")

                    :Where(l_cTableName+[.UseStatus = 0])
                    :SQL("ListOfRecordsToUpdate")
                    select ListOfRecordsToUpdate
                    scan all
                        with object l_oDB2
                            :Table("091cf769-4ced-4276-be6b-cf7dc50dd546",l_cTableName)
                            :Field(l_cTableName+".UseStatus" , USESTATUS_UNKNOWN)
                            :Update(ListOfRecordsToUpdate->pk)
                        endwith
                    endscan
                endfor
            endwith

            l_iCurrentDataVersion := 17
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        // Skipped version 17 since changed logic from "l_iCurrentDataVersion <=" to "l_iCurrentDataVersion <"
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 18
            with object l_oDB1
                :Table("5de9d15e-1af2-4f12-9762-ffdfc779a750","EnumValue")
                :Column("EnumValue.Pk"   , "Pk")
                :Column("EnumValue.Name" , "EnumValue_Name")
                :SQL("ListOfRecordsToUpdate")
                select ListOfRecordsToUpdate
                scan all
                    l_cName := SanitizeInputAlphaNumeric(ListOfRecordsToUpdate->EnumValue_Name)
                    if !(ListOfRecordsToUpdate->EnumValue_Name == l_cName)
                        with object l_oDB2
                            :Table("1b2715fd-fad5-4c0d-a24a-f8b5c4b21be6","EnumValue")
                            :Field("EnumValue.Name" , l_cName)
                            :Update(ListOfRecordsToUpdate->pk)
                        endwith
                    endif
                endscan
            endwith

            l_iCurrentDataVersion := 18
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 19
            if ::p_o_SQLConnection:FieldExists("public.Application","AllowDestructiveDelete")
                ::p_o_SQLConnection:DeleteField("public.Application","AllowDestructiveDelete")
            endif

            l_iCurrentDataVersion := 19
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 20
            if ::p_o_SQLConnection:FieldExists("public.Model","AllowDestructiveDelete")
                ::p_o_SQLConnection:DeleteField("public.Model","AllowDestructiveDelete")
            endif

            l_iCurrentDataVersion := 20
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 21
            if ::p_o_SQLConnection:TableExists("public.Version")
                ::p_o_SQLConnection:DeleteTable("public.Version")
            endif

            l_iCurrentDataVersion := 21
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
        //-----------------------------------------------------------------------------------
        if l_iCurrentDataVersion < 22
            with object l_oDB1
                :Table("6dd31de7-15fb-4388-ae7b-9578fb8407b2","UserSetting")
                :Column("UserSetting.pk" , "pk")
                :Where([UserSetting.ValueType = 0])
                :SQL("ListOfUserSettingToUpdate")
                select ListOfUserSettingToUpdate
                scan all
                    with object l_oDB2
                        :Table("c35a9c9b-eced-4121-aabe-3adf4fa73678","UserSetting")
                        :Field("UserSetting.ValueType" , 1)
                        :Update(ListOfUserSettingToUpdate->pk)
                    endwith
                endscan
            endwith

            l_iCurrentDataVersion := 22
            :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
        endif
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

        UpdateAPIEndpoint()

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
local l_cUserID
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
local l_cSecuritySalt
local l_lCyanAuditAware         := (upper(left(::GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
local l_cPostgresDriver         := ::GetAppConfig("POSTGRESDRIVER")
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
local l_cAPIEndpointName
local l_sAPIFunction
local l_cLinkUID
local l_oDB_ListOfFileStream
local l_oDB_FileStream
local l_cFilePath
local l_cFileName
local l_oJWT
local l_nTokenAccessMode

SendToDebugView("Request Counter",::RequestCount)
SendToDebugView("Requested URL",::GetEnvironment("REDIRECT_URL"))

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
l_lPostgresLostConnection := (::p_o_SQLConnection == NIL) .or. (::RequestCount > 1 .and. !::p_o_SQLConnection:CheckIfStillConnected())
if l_lPostgresLostConnection                                    .or.;
   (::p_o_SQLConnection:GetServer()   <> l_cPostgresHost)     .or.;
   (::p_o_SQLConnection:GetPort()     <> l_iPostgresPort)     .or.;
   (::p_o_SQLConnection:GetDatabase() <> l_cPostgresDatabase) .or.;
   (::p_o_SQLConnection:GetUser()     <> l_cPostgresId)

    if !l_lPostgresLostConnection
        ::p_o_SQLConnection:Disconnect()
    endif

// l_cPostgresDriver := "PostgreSQL Unicode"

////    SendToDebugView("Reconnecting to SQL Server")
    ::p_o_SQLConnection := hb_SQLConnect("PostgreSQL",;
                                        l_cPostgresDriver,;
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
else
    if ::p_o_SQLConnection:CheckIfSchemaCacheShouldBeUpdated()
        UpdateSchema(::p_o_SQLConnection)
    endif
endif

// l_1 := val(::p_o_SQLConnection:p_hb_orm_version)
// l_2 := val(MIN_HARBOUR_ORM_VERSION)
// altd()

do case
case ::p_o_SQLConnection == NIL
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Failed to connect to Data Server</h1>]

    l_cHtml += [<h2>Config File: ]+::PathBackend+"config.txt"+[</h2>]
    l_cHtml += [<h2>Driver: ]+l_cPostgresDriver+[</h2>]
    l_cHtml += [<h2>Host: ]+l_cPostgresHost+[</h2>]
    l_cHtml += [<h2>Port: ]+trans(l_iPostgresPort)+[</h2>]
    l_cHtml += [<h2>User ID: ]+l_cPostgresId+[</h2>]
    l_cHtml += [<h2>Password: ]+::GetAppConfig("POSTGRESPASSWORD")+[</h2>]
    l_cHtml += [<h2>Database: ]+l_cPostgresDatabase+[</h>]
    
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( val(::p_o_SQLConnection:p_hb_orm_version) , val(MIN_HARBOUR_ORM_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour ORM must be version ]+MIN_HARBOUR_ORM_VERSION+[ at the minimum.</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( VFP_GetCompatibilityPackVersion() , val(MIN_HARBOUR_VFP_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour VFP must be version ]+MIN_HARBOUR_VFP_VERSION+[ at the minimum.</h1>]
    l_cHtml += [</body>]
    l_cHtml += [</html>]

case CompareVersionsWithDecimals( vaL(::p_hb_fcgi_version) , val(MIN_HARBOUR_FCGI_VERSION) ) < 0
    l_cHtml := [<html>]
    l_cHtml += [<body>]
    l_cHtml += [<h1>Harbour FastCGI must be version ]+MIN_HARBOUR_FCGI_VERSION+[ at the minimum.</h1>]
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
            ::p_o_SQLConnection:SQLExec("SELECT cyanaudit.fn_set_current_uid( 0 );")
        endif

        // l_cSitePath := ::GetEnvironment("CONTEXT_PREFIX")
        // if len(l_cSitePath) == 0
        //     l_cSitePath := "/"
        // endif
        // ::GetQueryString("p")

        ::p_URLPathElements := {}

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
        
        if l_cPageName == "favicon.ico" .or. l_cPageName == "scripts"
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
        if !VFP_Inlist(lower(l_cPageName),"ajax","api","streamfile") // ,"health"

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

        if !empty(l_cSessionID) .and. !VFP_Inlist(lower(l_cPageName),"api") // ,"health"
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
                    l_cUserName := AllTrim(l_oJWT:GetPayloadData('given_name'))+" "+l_oJWT:GetPayloadData('family_name')
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
                        l_cUserName       := AllTrim(ListOfResults->User_FirstName)+" "+AllTrim(ListOfResults->User_LastName)
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
        if !VFP_Inlist(lower(l_cPageName),"ajax","api","streamfile")
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
                            l_cBody += [<div>VFP Build Info: ]+hb_vfp_buildinfo()+[</div>]
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
                l_cAPIEndpointName := GetAPIURIElement(1)
//123456
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
                l_TimeStamp2  := hb_DateTime()
                l_cHtml += [<div class="m-3">Run Time = ]+trans(int((l_TimeStamp2-l_TimeStamp1)*(24*3600*1000)))+[ (ms)</div>]
            endif

            l_cHtml += [</body>]
            l_cHtml += [</html>]

        endif
    endif
endcase

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
        ::Print("<div>FastCGIRunLog.pk = "+Trans(nvl(v_iFastCGIRunLogPk,0))+"</div>")
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
local l_LastError := ""
local l_hSchema
local l_nMigrateSchemaResult := 0
local l_lCyanAuditAware

l_hSchema := Schema()

if el_AUnpack(par_o_SQLConnection:MigrateSchema(l_hSchema),@l_nMigrateSchemaResult,,@l_LastError) > 0
    if l_nMigrateSchemaResult == 1
        l_lCyanAuditAware := (upper(left(oFcgi:GetAppConfig("CYANAUDIT_TRAC_USER"),1)) == "Y")
        if l_lCyanAuditAware
            //Ensure Cyanaudit is up to date
            oFcgi:p_o_SQLConnection:SQLExec("SELECT cyanaudit.fn_update_audit_fields('public');")
            //SendToDebugView("PostgreSQL - Updated Cyanaudit triggers")
        endif
    endif
else
    if !empty(l_LastError)
        SendToDebugView("PostgreSQL - Failed Migrate")
    endif
endif

// VFP_StrToFile(l_cUpdateScript,OUTPUT_FOLDER+hb_ps()+"UpdateScript.txt")

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

                    if (oFcgi:p_nUserAccessMode >= 3) // "All Project and Application Full Access" access right.
                        l_cHtml += [<li class="nav-item"><a class="nav-link link-dark]+l_cExtraClass+iif(lower(par_cCurrentPage) == "interappmapping"    ,l_cBootstrapCurrentPageClasses,[])+[" href="]+l_cSitePath+[InterAppMapping">Inter-App Mapping</a></li>]
                    endif

                    if l_lShowMenuProjects .or. l_lShowMenuApplications .or.  (oFcgi:p_nUserAccessMode >= 3) .or. (oFcgi:p_nUserAccessMode >= 4) .or. l_lShowChangePassword
//                        l_cHtml += [<li class="nav-item dropdown"><a class="nav-link link-dark dropdown-toggle]+l_cExtraClass+[" href="#" id="navbarDropdownMenuLinkAdmin" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Settings</a>]
                        l_cHtml += [<li class="nav-item dropdown"><a class="nav-link link-dark dropdown-toggle]+l_cExtraClass+iif(vfp_inlist(lower(par_cCurrentPage),"projects","applications","customfields","apitokens","users","changepassword")    ,l_cBootstrapCurrentPageClasses,[])+[" href="#" id="navbarDropdownMenuLinkAdmin" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Settings</a>]



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
function GetConfirmationModalFormsDelete()
local cHtml

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
function GetConfirmationModalFormsPurge()
local cHtml

TEXT TO VAR cHtml

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

return cHtml
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
            :Field("UserSetting.fk_User"   ,oFcgi:p_iUserPk)
            :Field("UserSetting.KeyC"      ,par_cName)
            :Field("UserSetting.ValueC"    ,par_cValue)
            :Field("UserSetting.ValueType" ,1)
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
function CheckIfAllowDestructiveNameSpaceDelete(par_iApplicationPk)
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
                l_cResult := Alltrim(Str( l_nResult, 5 )) + " " + curl_easy_strerror( l_nResult )
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
local l_cFilePath := ""

l_cFilePath := oFCgi:PathBackend+hb_ps()+"StreamFile"
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()+trans(l_iPID)
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()

return l_cFilePath
//=================================================================================================================
function GetStreamFileFolderForCurrentUser()
local l_cFilePath := ""

l_cFilePath := oFCgi:PathBackend+hb_ps()+"UserStreamFile"
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()+trans(oFcgi:p_iUserPk)
hb_DirCreate(l_cFilePath)
l_cFilePath += hb_ps()

return l_cFilePath
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

            // if vfp_Seek(padr(upper(l_cAPITokenName)+'*',240),"ListOfAPIEndpoint","tag1")
            if vfp_Seek(upper(l_cAPITokenName)+'*',"ListOfAPIEndpoint","tag1")
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