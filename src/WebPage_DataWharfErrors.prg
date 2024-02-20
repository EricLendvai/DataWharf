#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageDataWharfErrors()
local l_cHtml := []
local l_oDB_ListOfDataErrors  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAutoTrimLog := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cURLAction          := "ListErrors"
// local l_cURLAPITokenLinkUID := ""

local l_cSitePath := oFcgi:p_cSitePath

local l_nNumberOfErrors
local l_nNumberOfAutoTrim

local l_iPk

oFcgi:TraceAdd("BuildPageDataWharfErrors")

//Improved and new way:
// DataWharfErrors/                      Same as DataWharfErrors/ListErrors/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]
else
    l_cURLAction := "ListErrors"
endif

do case
case l_cURLAction == "ListErrors"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[DataWharfErrors/">Recent Errors</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    // l_cHtml += [<h1>UD</h1>]  //APITokenListFormBuild()

    with object l_oDB_ListOfDataErrors
        :Table("891248b7-744d-4879-8077-2142108f6632",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAndDataErrorLog","SchemaAndDataErrorLog")
        :Column("SchemaAndDataErrorLog.pk"            , "pk")
        :Column("SchemaAndDataErrorLog.datetime"      , "SchemaAndDataErrorLog_datetime")
        :Column("SchemaAndDataErrorLog.eventid"       , "SchemaAndDataErrorLog_eventid")
        :Column("SchemaAndDataErrorLog.ip"            , "SchemaAndDataErrorLog_ip")
        :Column("SchemaAndDataErrorLog.NamespaceName" , "SchemaAndDataErrorLog_NamespaceName")
        :Column("SchemaAndDataErrorLog.Tablename"     , "SchemaAndDataErrorLog_Tablename")
        :Column("SchemaAndDataErrorLog.RecordPk"      , "SchemaAndDataErrorLog_RecordPk")
        :Column("SchemaAndDataErrorLog.ErrorMessage"  , "SchemaAndDataErrorLog_ErrorMessage")
        :Limit(100)
        :OrderBy("SchemaAndDataErrorLog_datetime","Desc")
        :SQL("ListOfDataErrors")
        l_nNumberOfErrors := :Tally
    endwith

    with object l_oDB_ListOfAutoTrimLog
        :Table("5a2b1abc-0cba-44be-97e6-815c7a1520d7",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAutoTrimLog","SchemaAutoTrimLog")
        :Column("SchemaAutoTrimLog.pk"            , "pk")
        :Column("SchemaAutoTrimLog.datetime"      , "SchemaAutoTrimLog_datetime")
        :Column("SchemaAutoTrimLog.eventid"       , "SchemaAutoTrimLog_eventid")
        :Column("SchemaAutoTrimLog.ip"            , "SchemaAutoTrimLog_ip")
        :Column("SchemaAutoTrimLog.NamespaceName" , "SchemaAutoTrimLog_NamespaceName")
        :Column("SchemaAutoTrimLog.Tablename"     , "SchemaAutoTrimLog_Tablename")
        :Column("SchemaAutoTrimLog.RecordPk"      , "SchemaAutoTrimLog_RecordPk")
        :Column("SchemaAutoTrimLog.FieldName"     , "SchemaAutoTrimLog_FieldName")
        :Limit(100)
        :OrderBy("SchemaAutoTrimLog_datetime","Desc")
        :SQL("ListOfAutoTrimLog")
        l_nNumberOfAutoTrim := :Tally
    endwith

    l_cHtml += [<div class="m-3">]

        // l_cHtml += [<div class="input-group">]
        l_cHtml += [<div class="mb-3">]
            l_cHtml += [<div>Number of listed Data Errors: ]+trans(l_nNumberOfErrors)+[</div>]
            l_cHtml += [<div>Number of listed Auto Trims events: ]+trans(l_nNumberOfAutoTrim)+[</div>]
        l_cHtml += [</div>]
//--------------------------------------------------------------------------------------------
        if !empty(l_nNumberOfErrors)
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="7">Data Errors (]+Trans(l_nNumberOfErrors)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Time</th>]
                        l_cHtml += [<th class="text-white">Event ID</th>]
                        l_cHtml += [<th class="text-white">IP</th>]
                        l_cHtml += [<th class="text-white">Namespace</th>]
                        l_cHtml += [<th class="text-white">Table</th>]
                        l_cHtml += [<th class="text-white">pk</th>]
                        l_cHtml += [<th class="text-white">Error Message</th>]
                    l_cHtml += [</tr>]

                    select ListOfDataErrors
                    scan all
                        // l_iUserPk := ListOfDataErrors->pk

                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += hb_TtoC(ListOfDataErrors->SchemaAndDataErrorLog_datetime,"MM/DD/YYYY","HH:MM:SS PM")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_eventid,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_ip,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_NamespaceName,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_Tablename,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_iPk := nvl(ListOfDataErrors->SchemaAndDataErrorLog_RecordPk,0)
                                if l_iPk > 0
                                    l_cHtml += trans(l_iPk)
                                endif
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfDataErrors->SchemaAndDataErrorLog_ErrorMessage,""),chr(13),"<br>")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]

        endif
//--------------------------------------------------------------------------------------------
        if !empty(l_nNumberOfAutoTrim)
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="7">Trimmed Data Content (]+Trans(l_nNumberOfAutoTrim)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Time</th>]
                        l_cHtml += [<th class="text-white">Event ID</th>]
                        l_cHtml += [<th class="text-white">IP</th>]
                        l_cHtml += [<th class="text-white">Namespace</th>]
                        l_cHtml += [<th class="text-white">Table</th>]
                        l_cHtml += [<th class="text-white">pk</th>]
                        l_cHtml += [<th class="text-white">Column</th>]
                    l_cHtml += [</tr>]

                    select ListOfAutoTrimLog
                    scan all
                        // l_iUserPk := ListOfAutoTrimLog->pk

                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += hb_TtoC(ListOfAutoTrimLog->SchemaAutoTrimLog_datetime,"MM/DD/YYYY","HH:MM:SS PM")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_eventid,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_ip,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_NamespaceName,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_Tablename,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_iPk := nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_RecordPk,0)
                                if l_iPk > 0
                                    l_cHtml += trans(l_iPk)
                                endif
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_FieldName,"")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]

        endif
//--------------------------------------------------------------------------------------------



    l_cHtml += [</div>]

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
// static function APITokenListFormBuild()
// local l_cHtml := []
// local l_oDB_ListOfAPITokens         := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_oDB_ListOfProjectAccess     := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_oDB_ListOfApplicationAccess := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_oDB_ListOfAPIAccessEndpoint := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_cSitePath := oFcgi:p_cSitePath
// local l_nNumberOfAPITokens
// local l_iAPITokenPk

// oFcgi:TraceAdd("APITokenListFormBuild")

// with object l_oDB_ListOfAPITokens
//     :Table("c5e6ecfc-2a8a-4d48-817c-666d8c990269","APIToken")
//     :Column("APIToken.pk"         ,"pk")
//     :Column("APIToken.LinkUID"    ,"APIToken_LinkUID")
//     :Column("APIToken.Name"       ,"APIToken_Name")
//     :Column("APIToken.Key"        ,"APIToken_Key")
//     :Column("APIToken.AccessMode" ,"APIToken_AccessMode")
//     :Column("APIToken.Description","APIToken_Description")
//     :Column("APIToken.Status"     ,"APIToken_Status")
//     :Column("Upper(APIToken.Name)","tag1")
//     :OrderBy("tag1")
//     :SQL("ListOfAPITokens")
//     l_nNumberOfAPITokens := :Tally
// endwith

// with object l_oDB_ListOfProjectAccess
//     :Table("c194795a-b66a-4ec7-98fd-29efddcd5c9c","APIToken")
//     :Column("APIToken.pk"                         , "APIToken_Pk")
//     :Column("Project.Name"                        , "Project_Name")
//     :Column("APITokenAccessProject.AccessLevelML" , "AccessLevel")
//     :Column("upper(Project.Name)"                 , "tag1")
//     :Join("inner","APITokenAccessProject","","APITokenAccessProject.fk_APIToken = APIToken.pk")
//     :Join("inner","Project"              ,"","APITokenAccessProject.fk_Project = Project.pk")
//     :OrderBy("APIToken_Pk")
//     :OrderBy("tag1")
//     :SQL("ListOfProjectAccess")

//     with object :p_oCursor
//         :Index("APIToken_Pk","APIToken_Pk")
//         :CreateIndexes()
//         :SetOrder("APIToken_Pk")
//     endwith
// endwith

// with object l_oDB_ListOfApplicationAccess
//     :Table("081f2056-09ca-43af-ab0d-3349a8654183","APIToken")
//     :Column("APIToken.pk"                             , "APIToken_Pk")
//     :Column("Application.Name"                        , "Application_Name")
//     :Column("APITokenAccessApplication.AccessLevelDD" , "AccessLevel")
//     :Column("upper(Application.Name)"                 , "tag1")
//     :Join("inner","APITokenAccessApplication","","APITokenAccessApplication.fk_APIToken = APIToken.pk")
//     :Join("inner","Application"              ,"","APITokenAccessApplication.fk_Application = Application.pk")
//     :OrderBy("APIToken_Pk")
//     :OrderBy("tag1")
//     :SQL("ListOfApplicationAccess")

//     with object :p_oCursor
//         :Index("APIToken_Pk","APIToken_Pk")
//         :CreateIndexes()
//         :SetOrder("APIToken_Pk")
//     endwith
// endwith

// with object l_oDB_ListOfAPIAccessEndpoint
//     :Table("081f2056-09ca-43af-ab0d-3349a8654184","APIToken")
//     :Column("APIToken.pk"             , "APIToken_Pk")
//     :Column("APIEndpoint.Name"        , "APIEndpoint_Name")
//     :Column("upper(APIEndpoint.Name)" , "tag1")
//     :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
//     :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
//     :OrderBy("APIToken_Pk")
//     :OrderBy("tag1")
//     :SQL("ListOfAPIAccessEndpoint")

//     with object :p_oCursor
//         :Index("APIToken_Pk","APIToken_Pk")
//         :CreateIndexes()
//         :SetOrder("APIToken_Pk")
//     endwith
// endwith
// //_M_ display in grid
// //Application  APIEndpoint
// //APITokenAccessApplication  APIAccessEndpoint


// l_cHtml += [<div class="m-3">]

//     if empty(l_nNumberOfAPITokens)
//         l_cHtml += [<div class="input-group">]
//             l_cHtml += [<span>No APIToken on file.</span>]
//         l_cHtml += [</div>]

//     else
//         l_cHtml += [<div class="row justify-content-center">]
//             l_cHtml += [<div class="col-auto">]

//                 l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

//                 l_cHtml += [<tr class="bg-primary bg-gradient">]
//                     l_cHtml += [<th class="text-white text-center" colspan="7">APITokens (]+Trans(l_nNumberOfAPITokens)+[)</th>]
//                 l_cHtml += [</tr>]

//                 l_cHtml += [<tr class="bg-primary bg-gradient">]
//                     l_cHtml += [<th class="text-white">Name</th>]
//                     l_cHtml += [<th class="text-white">Access Mode</th>]
//                     l_cHtml += [<th class="text-white">Projects</th>]
//                     l_cHtml += [<th class="text-white">Applications</th>]
//                     l_cHtml += [<th class="text-white">API Endpoints</th>]
//                     l_cHtml += [<th class="text-white">Description</th>]
//                     l_cHtml += [<th class="text-white text-center">Status</th>]
//                 l_cHtml += [</tr>]

//                 select ListOfAPITokens
//                 scan all
//                     l_iAPITokenPk := ListOfAPITokens->pk

//                     l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">]
//                             l_cHtml += [<a href="]+l_cSitePath+[APITokens/EditAPIToken/]+alltrim(ListOfAPITokens->APIToken_LinkUID)+[/">]+alltrim(ListOfAPITokens->APIToken_Name)+[</a>]
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">]
//                             l_cHtml += {"Project And Application Specific","All Projects and Applications Read Only","All Projects and Applications Full Access"}[iif(el_between(ListOfAPITokens->APIToken_AccessMode,1,3),ListOfAPITokens->APIToken_AccessMode,1)]
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">] //Projects
//                             select ListOfProjectAccess
//                             scan all for ListOfProjectAccess->APIToken_Pk == l_iAPITokenPk
//                                 l_cHtml += [<div>]+ListOfProjectAccess->Project_Name+[ - ]
//                                     l_cHtml += {"None","Read Only","Update Description and Information Entries","Update Description and Information Entries and Diagrams","Update Anything"}[iif(el_between(ListOfProjectAccess->AccessLevel,1,5),ListOfProjectAccess->AccessLevel,1)]
//                                 l_cHtml += [</div>]
//                             endscan
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">] //Applications
//                             select ListOfApplicationAccess
//                             scan all for ListOfApplicationAccess->APIToken_Pk == l_iAPITokenPk
//                                 l_cHtml += [<div>]+ListOfApplicationAccess->Application_Name+[ - ]
//                                     l_cHtml += {"None","Read Only","Update Description and Information Entries","Update Description and Information Entries and Diagrams","Update Anything"}[iif(el_between(ListOfApplicationAccess->AccessLevel,1,5),ListOfApplicationAccess->AccessLevel,1)]
//                                 l_cHtml += [</div>]
//                             endscan
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">] //API Endpoints
//                             select ListOfAPIAccessEndpoint
//                             scan all for ListOfAPIAccessEndpoint->APIToken_Pk == l_iAPITokenPk
//                                 l_cHtml += [<div>]+ListOfAPIAccessEndpoint->APIEndpoint_Name+[</div>]
//                             endscan
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">]
//                             l_cHtml += TextToHtml(hb_DefaultValue(ListOfAPITokens->APIToken_Description,""))
//                         l_cHtml += [</td>]

//                         l_cHtml += [<td class="GridDataControlCells" valign="top">]
//                             l_cHtml += {"Active","Inactive"}[iif(el_between(ListOfAPITokens->APIToken_Status,1,2),ListOfAPITokens->APIToken_Status,1)]
//                         l_cHtml += [</td>]

//                     l_cHtml += [</tr>]
//                 endscan
//                 l_cHtml += [</table>]
                
//             l_cHtml += [</div>]
//         l_cHtml += [</div>]

//     endif

// l_cHtml += [</div>]

// return l_cHtml
//=================================================================================================================
//=================================================================================================================
