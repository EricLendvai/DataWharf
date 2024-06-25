#include "DataWharf.ch"

#define MAX_TO_DISPLAY_IN_GRID 100

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageErrorExplorer()
local l_cHtml := []

local l_cURLAction
local l_nNumberOfErrors
local l_nNumberOfAutoTrim
local l_iPk
local l_lAutoRefresh
local l_lMyErrors
local l_lCurrentApplicationVersion
local l_lCurrentApplicationBuild
local l_nDatetimeRangeMode
local l_cDatetimeRangeFrom
local l_cDatetimeRangeTo
local l_cDatetimeRangeFromWithMicroSeconds
local l_cDatetimeRangeToWithMicroSeconds
local l_cSitePath := oFcgi:p_cSitePath
local l_cRefreshPath
local l_oDB_ListOfApplicationErrors
local l_oDB_ListOfDataErrors
local l_oDB_ListOfAutoTrimLog
local l_oDB_User
local l_o_Data
local l_cActionOnSubmit
local l_cCurrentDatetimeWithMicroSeconds := oFcgi:p_o_SQLConnection:GetCurrentTimeInTimeZoneAsText(oFcgi:p_cUserTimeZoneName)
local l_cCurrentDatetimeForDisplay
local l_cLastUsedDatetimeWithMicroSeconds

local l_cLastReviewedDatetimeWithMicroSeconds
local l_cLastReviewTime

local l_cQueryParameterInfo := ""

oFcgi:TraceAdd("BuildPageErrorExplorer")

//Improved and new way:
//ErrorExplorer/                      Same as ErrorExplorer/Dashboard/
//ErrorExplorer/ApplicationErrors
//ErrorExplorer/DistinctApplicationErrors
//ErrorExplorer/DataErrors
//ErrorExplorer/DistinctDataErrors
//ErrorExplorer/AutoTrimEvents
//ErrorExplorer/DistinctAutoTrimEvents

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]
else
    l_cURLAction := "Dashboard"
endif

l_cRefreshPath := oFcgi:RequestSettings["QueryString"]
if empty(l_cRefreshPath)
    l_cRefreshPath := oFcgi:p_cSitePath+oFcgi:RequestSettings["Path"]
else
    l_cRefreshPath := oFcgi:p_cSitePath+oFcgi:RequestSettings["Path"]+"?"+l_cRefreshPath
endif

if empty(l_cCurrentDatetimeWithMicroSeconds)
    l_cCurrentDatetimeForDisplay := ""
else
    l_cCurrentDatetimeForDisplay := hb_ttoc(hb_CtoT(left(l_cCurrentDatetimeWithMicroSeconds,19), "yyyy-mm-dd", "hh:mm:ss"),oFcgi:p_LocalisationDateFormat,oFcgi:p_LocalisationTimeFormat)
endif

if l_cURLAction <> "Dashboard"
    l_lMyErrors                  := (oFcgi:GetQueryString("MyErrors") == "T")
    l_lCurrentApplicationVersion := (oFcgi:GetQueryString("CurrentApplicationVersion") == "T")
    l_lCurrentApplicationBuild   := (oFcgi:GetQueryString("CurrentApplicationBuild") == "T")
    l_nDatetimeRangeMode         := val(oFcgi:GetQueryString("DatetimeRangeMode"))
    l_cDatetimeRangeFrom         := alltrim(oFcgi:GetQueryString("DatetimeRangeFrom"))
    l_cDatetimeRangeTo           := alltrim(oFcgi:GetQueryString("DatetimeRangeTo"))

    if empty(l_cDatetimeRangeFrom)
        l_cDatetimeRangeFromWithMicroSeconds := ""
    else
        l_cDatetimeRangeFromWithMicroSeconds := strtran(l_cDatetimeRangeFrom,"T"," ")+":00.0"
    endif

    if empty(l_cDatetimeRangeTo)
        l_cDatetimeRangeToWithMicroSeconds   := ""
    else
        l_cDatetimeRangeToWithMicroSeconds   := strtran(l_cDatetimeRangeTo  ,"T"," ")+":00.0"
    endif

    l_oDB_User := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB_User
        :Table("306536d6-18cb-4b0b-af6d-c6bb3dc2f98b","public.User","User")
        :Column("User.ErrorExplorerLastReviewDatetime","User_ErrorExplorerLastReviewDatetime")
        :Column("(User.ErrorExplorerLastReviewDatetime AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"')::text","LastReview_LocalTimeAsText")
        l_o_Data := :Get(oFcgi:p_iUserPk)
        if :Tally == 1
            l_cLastReviewedDatetimeWithMicroSeconds := l_o_Data:LastReview_LocalTimeAsText
            if !hb_IsNil(l_o_Data:User_ErrorExplorerLastReviewDatetime) .and. !empty(l_o_Data:User_ErrorExplorerLastReviewDatetime)
                l_cLastReviewTime := hb_TtoC(l_o_Data:User_ErrorExplorerLastReviewDatetime,"MM/DD/YYYY","HH:MM:SS PM")
            else
                l_cLastReviewTime := ""
            endif
        else
            l_cLastReviewedDatetimeWithMicroSeconds := ""
            l_cLastReviewTime := ""
        endif
    endwith

    if l_lMyErrors
        l_cQueryParameterInfo += "My Errors Only"
    endif
    if l_lCurrentApplicationVersion
        if !empty(l_cQueryParameterInfo)
            l_cQueryParameterInfo += [, ]
        endif
        l_cQueryParameterInfo += [Current Application Version Only]
    endif
    if l_lCurrentApplicationBuild
        if !empty(l_cQueryParameterInfo)
            l_cQueryParameterInfo += [, ]
        endif
        l_cQueryParameterInfo += [Current Application Build Only]
    endif

    do case
    case l_nDatetimeRangeMode == 1   // Since my last review
        if !empty(l_cQueryParameterInfo)
            l_cQueryParameterInfo += [, ]
        endif
        l_cQueryParameterInfo += [Since My Last Review: ]+l_cLastReviewTime
    case l_nDatetimeRangeMode == 2   // All
    case l_nDatetimeRangeMode == 3   // After
        if !empty(l_cQueryParameterInfo)
            l_cQueryParameterInfo += [, ]
        endif
        l_cQueryParameterInfo += [After: ]+hb_ttoc(hb_CtoT(strtran(l_cDatetimeRangeFrom,"T"," ")+":00", "yyyy-mm-dd", "hh:mm:ss"),oFcgi:p_LocalisationDateFormat,oFcgi:p_LocalisationTimeFormat)

    case l_nDatetimeRangeMode == 4   // Between
        if !empty(l_cQueryParameterInfo)
            l_cQueryParameterInfo += [, ]
        endif
        l_cQueryParameterInfo += [After: ]+hb_ttoc(hb_CtoT(strtran(l_cDatetimeRangeFrom,"T"," ")+":00", "yyyy-mm-dd", "hh:mm:ss"),oFcgi:p_LocalisationDateFormat,oFcgi:p_LocalisationTimeFormat)
        l_cQueryParameterInfo += [, Before: ]+hb_ttoc(hb_CtoT(strtran(l_cDatetimeRangeTo,"T"," ")+":00", "yyyy-mm-dd", "hh:mm:ss"),oFcgi:p_LocalisationDateFormat,oFcgi:p_LocalisationTimeFormat)

    otherwise
    endcase

endif

do case
case l_cURLAction == "ApplicationErrors"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Application Errors</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfApplicationErrors := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfApplicationErrors
        :Table("0e532340-cc3e-4f69-9fc9-f9e75f7f1ffb","public.FastCGIRunLog","FastCGIRunLog")
        :Column("FastCGIRunLog.Datetime"             , "FastCGIRunLog_Datetime")
        :Column("FastCGIRunLog.ErrorDatetime"        , "FastCGIRunLog_ErrorDatetime")
        :Column("FastCGIRunLog.ApplicationVersion"   , "FastCGIRunLog_ApplicationVersion")
        :Column("FastCGIRunLog.ApplicationBuildInfo" , "FastCGIRunLog_ApplicationBuildInfo")
        :Column("FastCGIRunLog.IP"                   , "FastCGIRunLog_IP")
        :Column("FastCGIRunLog.OSInfo"               , "FastCGIRunLog_OSInfo")
        :Column("FastCGIRunLog.HostInfo"             , "FastCGIRunLog_HostInfo")

        :Join("left","public.User","User","FastCGIRunLog.fk_User = User.pk")
        :Column("User.FirstName" , "User_FirstName")
        :Column("User.LastName"  , "User_LastName")
        
        :Join("left","public.FastCGIError","FastCGIError","FastCGIRunLog.fk_FastCGIError = FastCGIError.pk")
        :Column("FastCGIError.ErrorMessage" , "FastCGIError_ErrorMessage")

        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("FastCGIRunLog_ErrorDatetime","Desc")
        :Where("FastCGIRunLog.ErrorDatetime is not null")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfApplicationErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "FastCGIRunLog",;
                                           "ErrorDatetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        :SQL("ListOfApplicationErrors")
        l_nNumberOfErrors := :Tally
        SendToClipboard(:LastSQL())
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfErrors)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="7">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="7">Application Errors (]+Trans(l_nNumberOfErrors)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Error Time</th>]
                        l_cHtml += [<th class="text-white">User</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Version</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Build<br>Info</th>]
                        l_cHtml += [<th class="text-white">IP</th>]
                        // l_cHtml += [<th class="text-white">OS Info</th>]
                        // l_cHtml += [<th class="text-white">Host Info</th>]
                        l_cHtml += [<th class="text-white text-center">Execution<br>Start Time</th>]
                        l_cHtml += [<th class="text-white">Error Message</th>]
                    l_cHtml += [</tr>]

                    select ListOfApplicationErrors
                    scan all
                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += FormatDatetimeInTwoLines(ListOfApplicationErrors->FastCGIRunLog_ErrorDatetime)
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfApplicationErrors->User_FirstName,"")+"<br>"+nvl(ListOfApplicationErrors->User_LastName,"")," ","&nbsp;")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                                l_cHtml += nvl(ListOfApplicationErrors->FastCGIRunLog_ApplicationVersion,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(strtran(alltrim(nvl(ListOfApplicationErrors->FastCGIRunLog_ApplicationBuildInfo,"")),"  "," 0")," ","<br>")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfApplicationErrors->FastCGIRunLog_IP,"")
                            l_cHtml += [</td>]

                            // l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            //     l_cHtml += nvl(ListOfApplicationErrors->FastCGIRunLog_OSInfo,"")
                            // l_cHtml += [</td>]

                            // l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            //     l_cHtml += nvl(ListOfApplicationErrors->FastCGIRunLog_HostInfo,"")
                            // l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += FormatDatetimeInTwoLines(ListOfApplicationErrors->FastCGIRunLog_Datetime)
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfApplicationErrors->FastCGIError_ErrorMessage,""),chr(13),"<br>")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    endif
    //--------------------------------------------------------------------------------------------


case l_cURLAction == "DistinctApplicationErrors"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Distinct Application Errors</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfApplicationErrors := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfApplicationErrors
        :Table("0e532340-cc3e-4f69-9fc9-f9e75f7f1ffc","public.FastCGIRunLog","FastCGIRunLog")
        :Distinct(.t.)
        :Join("left","public.FastCGIError","FastCGIError","FastCGIRunLog.fk_FastCGIError = FastCGIError.pk")
        :Column("FastCGIError.ErrorMessage" , "FastCGIError_ErrorMessage")

        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("FastCGIError_ErrorMessage","Desc")
        :Where("FastCGIRunLog.ErrorDatetime is not null")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfApplicationErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "FastCGIRunLog",;
                                           "ErrorDatetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)


        :SQL("ListOfApplicationErrors")
        l_nNumberOfErrors := :Tally
        // SendToClipboard(:LastSQL())
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfErrors)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="1">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="1">Distinct Application Errors (]+Trans(l_nNumberOfErrors)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Error Message</th>]
                    l_cHtml += [</tr>]

                    select ListOfApplicationErrors
                    scan all
                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfApplicationErrors->FastCGIError_ErrorMessage,""),chr(13),"<br>")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    endif
    //--------------------------------------------------------------------------------------------


case l_cURLAction == "DataErrors"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Data Errors</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfDataErrors := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfDataErrors
        :Table("0e532340-cc3e-4f69-9fc9-f9e75f7f1ffd",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAndDataErrorLog","SchemaAndDataErrorLog")
        :Column("SchemaAndDataErrorLog.pk"                   , "pk")
        :Column("SchemaAndDataErrorLog.datetime"             , "SchemaAndDataErrorLog_datetime")
        :Column("SchemaAndDataErrorLog.eventid"              , "SchemaAndDataErrorLog_eventid")
        :Column("SchemaAndDataErrorLog.ip"                   , "SchemaAndDataErrorLog_ip")
        :Column("SchemaAndDataErrorLog.NamespaceName"        , "SchemaAndDataErrorLog_NamespaceName")
        :Column("SchemaAndDataErrorLog.Tablename"            , "SchemaAndDataErrorLog_Tablename")
        :Column("SchemaAndDataErrorLog.RecordPk"             , "SchemaAndDataErrorLog_RecordPk")
        :Column("SchemaAndDataErrorLog.ErrorMessage"         , "SchemaAndDataErrorLog_ErrorMessage")
        :Column("SchemaAndDataErrorLog.ApplicationVersion"   , "SchemaAndDataErrorLog_ApplicationVersion")
        :Column("SchemaAndDataErrorLog.ApplicationBuildInfo" , "SchemaAndDataErrorLog_ApplicationBuildInfo")

        :Join("left","public.User","User","SchemaAndDataErrorLog.fk_User = User.pk")
        :Column("User.FirstName" , "User_FirstName")
        :Column("User.LastName"  , "User_LastName")

        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("SchemaAndDataErrorLog_datetime","Desc")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfDataErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAndDataErrorLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        :SQL("ListOfDataErrors")
        l_nNumberOfErrors := :Tally
        // SendToClipboard(:LastSQL())
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfErrors)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="10">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="10">Data Errors (]+Trans(l_nNumberOfErrors)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Error Time</th>]

                        l_cHtml += [<th class="text-white">User</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Version</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Build<br>Info</th>]
                        l_cHtml += [<th class="text-white">Event ID</th>]
                        l_cHtml += [<th class="text-white">IP</th>]
                        l_cHtml += [<th class="text-white">Namespace</th>]
                        l_cHtml += [<th class="text-white">Table</th>]
                        l_cHtml += [<th class="text-white">pk</th>]
                        l_cHtml += [<th class="text-white">Error Message</th>]
                    l_cHtml += [</tr>]

                    select ListOfDataErrors
                    scan all
                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += FormatDatetimeInTwoLines(ListOfDataErrors->SchemaAndDataErrorLog_datetime)
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                // l_cHtml += strtran(nvl(ListOfDataErrors->User_FirstName,"")+" "+nvl(ListOfDataErrors->User_LastName,"")," ","&nbsp;")
                                l_cHtml += strtran(nvl(ListOfDataErrors->User_FirstName,"")+"<br>"+nvl(ListOfDataErrors->User_LastName,"")," ","&nbsp;")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                                l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_ApplicationVersion,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(strtran(alltrim(nvl(ListOfDataErrors->SchemaAndDataErrorLog_ApplicationBuildInfo,"")),"  "," 0")," ","<br>")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                // l_cHtml += nvl(ListOfDataErrors->SchemaAndDataErrorLog_eventid,"")
                                l_cHtml += strtran(nvl(ListOfDataErrors->SchemaAndDataErrorLog_eventid,""),"-","-<br>")
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
        l_cHtml += [</div>]
    endif
    //--------------------------------------------------------------------------------------------

case l_cURLAction == "DistinctDataErrors"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Distinct Data Errors</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfDataErrors := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfDataErrors
        :Table("0e532340-cc3e-4f69-9fc9-f9e75f7f1ffe",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAndDataErrorLog","SchemaAndDataErrorLog")
        :Distinct(.t.)
        :Column("SchemaAndDataErrorLog.ErrorMessage"  , "SchemaAndDataErrorLog_ErrorMessage")
        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("SchemaAndDataErrorLog_ErrorMessage")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfDataErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAndDataErrorLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)


        :SQL("ListOfDataErrors")
        l_nNumberOfErrors := :Tally
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfErrors)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="1">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="1">Distinct Data Errors (]+Trans(l_nNumberOfErrors)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Error Message</th>]
                    l_cHtml += [</tr>]

                    select ListOfDataErrors
                    scan all
                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfDataErrors->SchemaAndDataErrorLog_ErrorMessage,""),chr(13),"<br>")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    endif
    //--------------------------------------------------------------------------------------------

case l_cURLAction == "AutoTrimEvents"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Auto Trim Events</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfAutoTrimLog := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB_ListOfAutoTrimLog
        :Table("5a2b1abc-0cba-44be-97e6-815c7a1520d7",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAutoTrimLog","SchemaAutoTrimLog")
        :Column("SchemaAutoTrimLog.pk"                   , "pk")
        :Column("SchemaAutoTrimLog.datetime"             , "SchemaAutoTrimLog_datetime")
        :Column("SchemaAutoTrimLog.ApplicationVersion"   , "SchemaAutoTrimLog_ApplicationVersion")
        :Column("SchemaAutoTrimLog.ApplicationBuildInfo" , "SchemaAutoTrimLog_ApplicationBuildInfo")
        :Column("SchemaAutoTrimLog.eventid"              , "SchemaAutoTrimLog_eventid")
        :Column("SchemaAutoTrimLog.ip"                   , "SchemaAutoTrimLog_ip")
        :Column("SchemaAutoTrimLog.NamespaceName"        , "SchemaAutoTrimLog_NamespaceName")
        :Column("SchemaAutoTrimLog.Tablename"            , "SchemaAutoTrimLog_Tablename")
        :Column("SchemaAutoTrimLog.RecordPk"             , "SchemaAutoTrimLog_RecordPk")
        :Column("SchemaAutoTrimLog.FieldName"            , "SchemaAutoTrimLog_FieldName")
        :Join("left","public.User","User","SchemaAutoTrimLog.fk_User = User.pk")
        :Column("User.FirstName" , "User_FirstName")
        :Column("User.LastName"  , "User_LastName")
        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("SchemaAutoTrimLog_datetime","Desc")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfAutoTrimLog,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAutoTrimLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        :SQL("ListOfAutoTrimLog")
        l_nNumberOfAutoTrim := :Tally
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfAutoTrim)

        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="10">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="10">Trimmed Data Events (]+Trans(l_nNumberOfAutoTrim)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Event Time</th>]
                        l_cHtml += [<th class="text-white">User</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Version</th>]
                        l_cHtml += [<th class="text-white text-center">Application<br>Build<br>Info</th>]
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
                                l_cHtml += FormatDatetimeInTwoLines(ListOfAutoTrimLog->SchemaAutoTrimLog_datetime)
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(nvl(ListOfAutoTrimLog->User_FirstName,"")+"<br>"+nvl(ListOfAutoTrimLog->User_LastName,"")," ","&nbsp;")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_ApplicationVersion,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += strtran(strtran(strtran(strtran(alltrim(nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_ApplicationBuildInfo,"")),"  "," 0")," ","&nbsp;",,1)," ","<br>",,1),"","&nbsp;",,1)
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
        l_cHtml += [</div>]

    endif
    //--------------------------------------------------------------------------------------------

case l_cURLAction == "DistinctAutoTrimEvents"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Distinct Auto Trim Events</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Back To Dashboard</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cRefreshPath+[">Refresh</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_oDB_ListOfAutoTrimLog := hb_SQLData(oFcgi:p_o_SQLConnection)
    with object l_oDB_ListOfAutoTrimLog
        :Table("5a2b1abc-0cba-44be-97e6-815c7a1520d7",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAutoTrimLog","SchemaAutoTrimLog")
        :Distinct(.t.)
        // :Column("SchemaAutoTrimLog.pk"            , "pk")
        :Column("SchemaAutoTrimLog.eventid"       , "SchemaAutoTrimLog_eventid")
        :Column("SchemaAutoTrimLog.NamespaceName" , "SchemaAutoTrimLog_NamespaceName")
        :Column("SchemaAutoTrimLog.Tablename"     , "SchemaAutoTrimLog_Tablename")
        :Column("SchemaAutoTrimLog.FieldName"     , "SchemaAutoTrimLog_FieldName")
        :Limit(MAX_TO_DISPLAY_IN_GRID)
        :OrderBy("SchemaAutoTrimLog_NamespaceName","Asc")
        :OrderBy("SchemaAutoTrimLog_Tablename"    ,"Asc")
        :OrderBy("SchemaAutoTrimLog_FieldName"    ,"Asc")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfAutoTrimLog,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAutoTrimLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           l_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)


        :SQL("ListOfAutoTrimLog")
        l_nNumberOfAutoTrim := :Tally
    endwith

    //--------------------------------------------------------------------------------------------
    if !empty(l_nNumberOfAutoTrim)
        l_cHtml += [<div class="m-3">]
            l_cHtml += [<div class="row justify-content-center mb-3">]
                l_cHtml += [<div class="col-auto">]

                    if !empty(l_cQueryParameterInfo)
                        l_cHtml += [<div class="mb-2">]+l_cQueryParameterInfo+[</div>]
                    endif

                    l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                    //Column Header
                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="4">Query Time: ]+l_cCurrentDatetimeForDisplay+[</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white text-center" colspan="4">Trimmed Data Content (]+Trans(l_nNumberOfAutoTrim)+[)</th>]
                    l_cHtml += [</tr>]

                    l_cHtml += [<tr class="bg-primary bg-gradient">]
                        l_cHtml += [<th class="text-white">Event ID</th>]
                        l_cHtml += [<th class="text-white">Namespace</th>]
                        l_cHtml += [<th class="text-white">Table</th>]
                        l_cHtml += [<th class="text-white">Column</th>]
                    l_cHtml += [</tr>]

                    select ListOfAutoTrimLog
                    scan all
                        // l_iUserPk := ListOfAutoTrimLog->pk

                        l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_eventid,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_NamespaceName,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_Tablename,"")
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfAutoTrimLog->SchemaAutoTrimLog_FieldName,"")
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                
                l_cHtml += [</div>]
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif
    //--------------------------------------------------------------------------------------------

case l_cURLAction == "Dashboard"
    if oFcgi:isGet()
        l_lAutoRefresh               := (GetUserSetting("ErrorExplorer_AutoRefresh") == "T")
        l_lMyErrors                  := (GetUserSetting("ErrorExplorer_MyErrorsOnly") == "T")
        l_lCurrentApplicationVersion := (GetUserSetting("ErrorExplorer_CurrentApplicationVersion") == "T")
        l_lCurrentApplicationBuild   := (GetUserSetting("ErrorExplorer_CurrentApplicationBuild") == "T")
        l_nDatetimeRangeMode         := val(GetUserSetting("ErrorExplorer_DatetimeRangeMode"))
        l_cDatetimeRangeFrom         := allt(GetUserSetting("ErrorExplorer_DatetimeRangeFrom"))
        l_cDatetimeRangeTo           := allt(GetUserSetting("ErrorExplorer_DatetimeRangeTo"))

        l_cHtml += ErrorExplorerDashboardBuild(l_lAutoRefresh,;
                                               l_lMyErrors,;
                                               l_lCurrentApplicationVersion,;
                                               l_lCurrentApplicationBuild,;
                                               l_nDatetimeRangeMode,;
                                               l_cDatetimeRangeFrom,;
                                               l_cDatetimeRangeTo,;
                                               l_cCurrentDatetimeWithMicroSeconds,;
                                               l_cCurrentDatetimeForDisplay)

    else
        l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

        l_lAutoRefresh                      := (oFcgi:GetInputValue("CheckAutoRefresh") == "1")
        l_lMyErrors                         := (oFcgi:GetInputValue("CheckMyErrorsOnly") == "1")
        l_lCurrentApplicationVersion        := (oFcgi:GetInputValue("CheckCurrentApplicationVersion") == "1")
        l_lCurrentApplicationBuild          := (oFcgi:GetInputValue("CheckCurrentApplicationBuild") == "1")
        l_nDatetimeRangeMode                := min(4,max(1,Val(oFcgi:GetInputValue("ComboDatetimeRangeMode"))))
        l_cDatetimeRangeFrom                := alltrim(oFcgi:GetInputValue("TextDatetimeRangeFrom"))
        l_cDatetimeRangeTo                  := alltrim(oFcgi:GetInputValue("TextDatetimeRangeTo"))
        l_cLastUsedDatetimeWithMicroSeconds := oFcgi:GetInputValue("TextCurrentDatetime")     // Retrieving the last display CurrentDateTime, since it is the one that should be stored if action was MarkAsReviewed

        SaveUserSetting("ErrorExplorer_AutoRefresh"               ,iif(l_lAutoRefresh,"T","F"))
        SaveUserSetting("ErrorExplorer_MyErrorsOnly"              ,iif(l_lMyErrors,"T","F"))
        SaveUserSetting("ErrorExplorer_CurrentApplicationVersion" ,iif(l_lCurrentApplicationVersion,"T","F"))
        SaveUserSetting("ErrorExplorer_CurrentApplicationBuild"   ,iif(l_lCurrentApplicationBuild,"T","F"))
        SaveUserSetting("ErrorExplorer_DatetimeRangeMode"         ,trans(l_nDatetimeRangeMode))
        SaveUserSetting("ErrorExplorer_DatetimeRangeFrom"         ,l_cDatetimeRangeFrom)
        SaveUserSetting("ErrorExplorer_DatetimeRangeTo"           ,l_cDatetimeRangeTo)

        if l_cActionOnSubmit == "MarkAsReviewed" .and. !empty(l_cLastUsedDatetimeWithMicroSeconds)
            l_oDB_User := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB_User
                :Table("306536d6-18cb-4b0b-af6d-c6bb3dc2f98b","public.User","User")
                :Field("User.ErrorExplorerLastReviewDatetime",:GetArrayForFieldValueOfTimestampWithTimeZoneAsText(l_cLastUsedDatetimeWithMicroSeconds,oFcgi:p_cUserTimeZoneName))
                if :Update(oFcgi:p_iUserPk)
                    // SendToClipboard(:LastSQL())
                    l_nDatetimeRangeMode := 1
                endif
            endwith
        endif

        l_cHtml += ErrorExplorerDashboardBuild(l_lAutoRefresh,;
                                               l_lMyErrors,;
                                               l_lCurrentApplicationVersion,;
                                               l_lCurrentApplicationBuild,;
                                               l_nDatetimeRangeMode,;
                                               l_cDatetimeRangeFrom,;
                                               l_cDatetimeRangeTo,;
                                               l_cCurrentDatetimeWithMicroSeconds,;
                                               l_cCurrentDatetimeForDisplay)

    endif

otherwise

endcase

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
function ErrorExplorerDashboardBuild(par_lAutoRefresh,;
                                     par_lMyErrors,;
                                     par_lCurrentApplicationVersion,;
                                     par_lCurrentApplicationBuild,;
                                     par_nDatetimeRangeMode,;
                                     par_cDatetimeRangeFrom,;
                                     par_cDatetimeRangeTo,;
                                     par_cCurrentDatetimeWithMicroSeconds,;
                                     par_cCurrentDatetimeForDisplay)

local l_cHtml
local l_cSitePath := oFcgi:p_cSitePath
local l_lAutoRefresh               := par_lAutoRefresh
local l_lMyErrors                  := par_lMyErrors
local l_lCurrentApplicationVersion := par_lCurrentApplicationVersion
local l_lCurrentApplicationBuild   := par_lCurrentApplicationBuild
local l_nDatetimeRangeMode         := par_nDatetimeRangeMode
local l_cDatetimeRangeFrom         := par_cDatetimeRangeFrom
local l_cDatetimeRangeTo           := par_cDatetimeRangeTo

local l_cCallOnChangeSettings

local l_cJS
local l_cErrorMessage := ""

local l_oDB_ListOfApplicationErrors
local l_oDB_ListOfDataErrors
local l_oDB_ListOfAutoTrimLog

local l_nTotalNumberOfDataErrors
local l_nDistinctNumberOfDataErrors

local l_nTotalNumberOfAutoTrimEvents
local l_nDistinctNumberOfAutoTrimEvents

local l_nTotalNumberOfApplicationErrors
local l_nDistinctNumberOfApplicationErrors

local l_oDB_User
local l_o_Data
local l_cLastReviewTime

local l_cMode
local l_cLastReviewedDatetimeWithMicroSeconds
local l_cDatetimeRangeFromWithMicroSeconds
local l_cDatetimeRangeToWithMicroSeconds

if empty(l_cDatetimeRangeFrom)
    l_cDatetimeRangeFromWithMicroSeconds := ""
else
    l_cDatetimeRangeFromWithMicroSeconds := strtran(l_cDatetimeRangeFrom,"T"," ")+":00.0"
endif

if empty(l_cDatetimeRangeTo)
    l_cDatetimeRangeToWithMicroSeconds   := ""
else
    l_cDatetimeRangeToWithMicroSeconds   := strtran(l_cDatetimeRangeTo  ,"T"," ")+":00.0"
endif

l_oDB_User := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_User
    :Table("306536d6-18cb-4b0b-af6d-c6bb3dc2f98b","public.User","User")
    :Column("User.ErrorExplorerLastReviewDatetime","User_ErrorExplorerLastReviewDatetime")
    :Column("(User.ErrorExplorerLastReviewDatetime AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"')::text","LastReview_LocalTimeAsText")
    l_o_Data := :Get(oFcgi:p_iUserPk)
    if :Tally == 1
        l_cLastReviewedDatetimeWithMicroSeconds := l_o_Data:LastReview_LocalTimeAsText
        if !hb_IsNil(l_o_Data:User_ErrorExplorerLastReviewDatetime) .and. !empty(l_o_Data:User_ErrorExplorerLastReviewDatetime)
            l_cLastReviewTime := hb_TtoC(l_o_Data:User_ErrorExplorerLastReviewDatetime,"MM/DD/YYYY","HH:MM:SS PM")
        else
            l_cLastReviewTime := ""
        endif
    else
        l_cLastReviewedDatetimeWithMicroSeconds := ""
        l_cLastReviewTime := ""
    endif
endwith

// SendToClipboard(par_cCurrentDatetimeWithMicroSeconds+" - "+l_cLastReviewedDatetimeWithMicroSeconds+" - "+oFcgi:p_cUserTimeZoneName+" - "+l_cDatetimeRangeFromWithMicroSeconds+" - "+l_cDatetimeRangeToWithMicroSeconds)

do case
case l_nDatetimeRangeMode == 1   // Since my last review
case l_nDatetimeRangeMode == 2   // All
case l_nDatetimeRangeMode == 3   // After
    if empty(l_cDatetimeRangeFrom)
        l_cErrorMessage := [Missing of invalid Date and Time.]
    else
    endif
case l_nDatetimeRangeMode == 4   // Between
    do case
    case empty(l_cDatetimeRangeFrom)
        l_cErrorMessage := [Missing of invalid "From" Date and Time.]
    case empty(l_cDatetimeRangeTo)
        l_cErrorMessage := [Missing of invalid "To" Date and Time.]
    endcase
otherwise
endcase

// To avoid a blinking the TextDatetimeRangeFrom , TextDatetimeRangeTo, ButtonApplyFilter were initially hidden (display:none).

l_cJS := [<script type="text/javascript" language="Javascript">]+CRLF

    l_cJS += 'function ToggleEditFormMode() {'
    l_cJS += 'return true;}'+CRLF

    l_cJS += [function OnChangeSettings(par_cDatetimeRangeMode) {]

        l_cJS += [switch(par_cDatetimeRangeMode) {]

        l_cJS +=    [case '1': ]  // Since my last review
        l_cJS +=        [$('#TextDatetimeRangeFrom').hide();]
        l_cJS +=        [$('#TextDatetimeRangeTo').hide();]
        l_cJS +=        [break;]

        l_cJS +=    [case '2': ]  // All
        l_cJS +=        [$('#TextDatetimeRangeFrom').hide();]
        l_cJS +=        [$('#TextDatetimeRangeTo').hide();]
        l_cJS +=        [break;]

        l_cJS +=    [case '3': ]  // After
        l_cJS +=        [$('#TextDatetimeRangeFrom').show();]
        l_cJS +=        [$('#TextDatetimeRangeTo').hide();]
        l_cJS +=        [break;]

        l_cJS +=    [case '4': ]  // After
        l_cJS +=        [$('#TextDatetimeRangeFrom').show();]
        l_cJS +=        [$('#TextDatetimeRangeTo').show();]
        l_cJS +=        [break;]

        l_cJS +=    [default:]  // Between
        l_cJS +=        [$('#TextDatetimeRangeFrom').hide();]
        l_cJS +=        [$('#TextDatetimeRangeTo').hide();]
        l_cJS +=        [break;]
        l_cJS += [};]+CRLF

    l_cJS += [};]+CRLF

    l_cJS += [var nRefreshInterval = 60;]+CRLF
    l_cJS += [var nCountDownSeconds = nRefreshInterval;]+CRLF

    l_cJS += [var oCountTimer = setInterval(function(){]
    l_cJS +=    [if ($('#CheckAutoRefresh').is(":checked")){]
        l_cJS +=    [if (nCountDownSeconds <= 0){]
        l_cJS +=        [nCountDownSeconds = nRefreshInterval;]
        l_cJS +=        [clearInterval(oCountTimer);]
        // l_cJS +=        [window.location.reload();]
        l_cJS +=        [$('#ActionOnSubmit').val('ApplyFilter');document.getElementById('ErrorExplorer').submit();]
        l_cJS +=    [} else {]
        l_cJS +=        [document.getElementById("CountDown").innerHTML = nCountDownSeconds + " seconds";]
        l_cJS +=        [nCountDownSeconds -= 1;]
        l_cJS +=    [}]
    l_cJS +=    [}]
    l_cJS += [},1000);]+CRLF

    // l_cJS += [function SetCountDownTimer() {]
    // l_cJS += [;}]+CRLF

l_cJS += [</script>]

oFcgi:p_cHeader += CRLF + l_cJS + CRLF

l_cHtml := [<form action="" method="post" name="ErrorExplorer" id="ErrorExplorer" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextCurrentDatetime" name="TextCurrentDatetime" value="]+par_cCurrentDatetimeWithMicroSeconds+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorMessage)

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[ErrorExplorer">Error Explorer - Dashboard</a>]
        l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer">Refresh</a>]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Mark as Reviewed" onclick="$('#ActionOnSubmit').val('MarkAsReviewed');document.getElementById('ErrorExplorer').submit();" role="button">]
        l_cHtml += [<span class="ms-5 mt-2">]+GetCheckboxOnEditForm("CheckAutoRefresh",l_lAutoRefresh,"Auto Refresh",.f.)+[</span>]
        l_cHtml += [<span class="ms-5 mt-2" id="CountDown"></span>]
        // _M_ JavaScript Code needed
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]


l_cCallOnChangeSettings := [OnChangeSettings($('#ComboDatetimeRangeMode').val());$('#ButtonApplyFilter').show();]
l_cCallOnChangeSettings += [$('#CheckAutoRefresh').change(]
l_cCallOnChangeSettings +=      [function(){]
l_cCallOnChangeSettings +=          [if ($(this).is(':checked')) {]
l_cCallOnChangeSettings +=              [nCountDownSeconds = nRefreshInterval;]
l_cCallOnChangeSettings +=          [} else {]
l_cCallOnChangeSettings +=              [document.getElementById("CountDown").innerHTML = '';]
l_cCallOnChangeSettings +=          [}]
l_cCallOnChangeSettings +=     [});]

oFcgi:p_cjQueryScript += l_cCallOnChangeSettings+[;]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Filter</td>]

            l_cHtml += [<td class="ms-2 pb-3">]
                l_cHtml += [<div>] + GetCheckboxOnEditForm("CheckMyErrorsOnly",l_lMyErrors,"My Errors Only",.f.) + [</div>]
                l_cHtml += [<div>] + GetCheckboxOnEditForm("CheckCurrentApplicationVersion",l_lCurrentApplicationVersion,"Current Application Version Only",.f.) + [</div>]
                l_cHtml += [<div>] + GetCheckboxOnEditForm("CheckCurrentApplicationBuild",l_lCurrentApplicationBuild,"Current Application Build Only",.f.) + [</div>]

                l_cHtml += [<table>]
                    l_cHtml += [<tr>]
                        l_cHtml += [<td>]
                            l_cHtml += [Date and Time Range]
                        l_cHtml += [</td>]
                        l_cHtml += [<td>]
                            l_cHtml += [<select name="ComboDatetimeRangeMode" id="ComboDatetimeRangeMode" class="ms-2" onchange="OnChangeSettings($('#ComboDatetimeRangeMode').val());">]
                            if !empty(l_cLastReviewTime)
                                l_cHtml += [<option value="1"]+iif(l_nDatetimeRangeMode==1,[ selected],[])+[>Since My Last Review ]+l_cLastReviewTime+[</option>]
                            endif
                            l_cHtml += [<option value="2"]+iif(l_nDatetimeRangeMode==2,[ selected],[])+[>All</option>]
                            l_cHtml += [<option value="3"]+iif(l_nDatetimeRangeMode==3,[ selected],[])+[>After</option>]
                            l_cHtml += [<option value="4"]+iif(l_nDatetimeRangeMode==4,[ selected],[])+[>Between</option>]
                            l_cHtml += [</select>]
                        l_cHtml += [</td>]
                        l_cHtml += [<td>]
                            l_cHtml += [<input type="datetime-local" id="TextDatetimeRangeFrom" name="TextDatetimeRangeFrom" class="ms-2" value="]+FcgiPrepFieldForValue(l_cDatetimeRangeFrom)+[" style="display: none;">]
                            l_cHtml += [<input type="datetime-local" id="TextDatetimeRangeTo" name="TextDatetimeRangeTo" class="ms-2" value="]+FcgiPrepFieldForValue(l_cDatetimeRangeTo)+[" style="display: none;">]
                        l_cHtml += [</td>]
                    l_cHtml += [</tr>]
                l_cHtml += [</table>]

            l_cHtml += [</td>]

            l_cHtml += [<td class="pe-2 pb-3" valign="top">]
                l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Apply Filter" onclick="$('#ActionOnSubmit').val('ApplyFilter');document.getElementById('ErrorExplorer').submit();" role="button" style="display: none;" id="ButtonApplyFilter">]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]
    l_cHtml += [</table>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

if empty(l_cErrorMessage)
    l_oDB_ListOfApplicationErrors := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB_ListOfDataErrors        := hb_SQLData(oFcgi:p_o_SQLConnection)
    l_oDB_ListOfAutoTrimLog       := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB_ListOfApplicationErrors
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("829784ef-06fa-4c09-ac94-fbbf409c56a7","public.FastCGIRunLog","FastCGIRunLog")
        :Where("FastCGIRunLog.fk_FastCGIError <> 0")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfApplicationErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "FastCGIRunLog",;
                                           "ErrorDatetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        l_nTotalNumberOfApplicationErrors := :Count()
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("829784ef-06fa-4c09-ac94-fbbf409c56a7","public.FastCGIRunLog","FastCGIRunLog")
        :Column("FastCGIRunLog.fk_FastCGIError" , "FastCGIRunLog_fk_FastCGIError")
        :Where("FastCGIRunLog.fk_FastCGIError <> 0")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfApplicationErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "FastCGIRunLog",;
                                           "ErrorDatetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        :Distinct(.t.)
        :SQL()
        l_nDistinctNumberOfApplicationErrors := :Tally
        //------------------------------------------------------------------------------------------------------------------------------
    endwith

    with object l_oDB_ListOfDataErrors
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("891248b7-744d-4879-8077-2142108f6632",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAndDataErrorLog","SchemaAndDataErrorLog")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfDataErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAndDataErrorLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        l_nTotalNumberOfDataErrors := :Count()
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("891248b7-744d-4879-8077-2142108f6633",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAndDataErrorLog","SchemaAndDataErrorLog")
        :Column("SchemaAndDataErrorLog.ErrorMessage" , "SchemaAndDataErrorLog_ErrorMessage")
        :Distinct(.t.)

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfDataErrors,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAndDataErrorLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        :SQL()
        l_nDistinctNumberOfDataErrors := :Tally
        // SendToClipboard(:LastSQL())
        //------------------------------------------------------------------------------------------------------------------------------

    endwith

    with object l_oDB_ListOfAutoTrimLog
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("1b0e1e1d-6939-4fc7-90af-c906f46b8cc4",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAutoTrimLog","SchemaAutoTrimLog")

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfAutoTrimLog,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAutoTrimLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)

        l_nTotalNumberOfAutoTrimEvents := :Count()
        //------------------------------------------------------------------------------------------------------------------------------
        :Table("dc22c6c0-254b-4eeb-8b29-b5d3a9497185",oFcgi:p_o_SQLConnection:GetHarbourORMNamespace()+".SchemaAutoTrimLog","SchemaAutoTrimLog")
        :Column("SchemaAutoTrimLog.eventid"       , "SchemaAutoTrimLog_eventid")
        :Column("SchemaAutoTrimLog.NamespaceName" , "SchemaAutoTrimLog_NamespaceName")
        :Column("SchemaAutoTrimLog.Tablename"     , "SchemaAutoTrimLog_Tablename")
        :Column("SchemaAutoTrimLog.FieldName"     , "SchemaAutoTrimLog_FieldName")
        :Distinct(.t.)

        AddLogFilteringOnDatetimeRangeMore(l_oDB_ListOfAutoTrimLog,;
                                           l_lMyErrors,l_lCurrentApplicationVersion,l_lCurrentApplicationBuild,;
                                           "SchemaAutoTrimLog",;
                                           "datetime",;
                                           l_nDatetimeRangeMode,;
                                           l_cLastReviewedDatetimeWithMicroSeconds,;
                                           par_cCurrentDatetimeWithMicroSeconds,;
                                           l_cDatetimeRangeFromWithMicroSeconds,;
                                           l_cDatetimeRangeToWithMicroSeconds)
                                           
        :SQL()
        l_nDistinctNumberOfAutoTrimEvents := :Tally
        //------------------------------------------------------------------------------------------------------------------------------
    endwith

    l_cMode := "MyErrors="+iif(l_lMyErrors,"T","F")
    l_cMode += "&"+"CurrentApplicationVersion="+iif(l_lCurrentApplicationVersion,"T","F")
    l_cMode += "&"+"CurrentApplicationBuild="+iif(l_lCurrentApplicationBuild,"T","F")
    l_cMode += "&"+"DatetimeRangeMode="+trans(l_nDatetimeRangeMode)
    l_cMode += "&"+"DatetimeRangeFrom="+l_cDatetimeRangeFrom
    l_cMode += "&"+"DatetimeRangeTo="+l_cDatetimeRangeTo

    l_cHtml += [<div class="row justify-content-center mb-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                //Column Header
                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="4">Query Time: ]+par_cCurrentDatetimeForDisplay+[</th>]
                l_cHtml += [</tr>]

                //Column Header
                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white"></th>]
                    l_cHtml += [<th class="text-white">Application Fatal Errors</th>]
                    l_cHtml += [<th class="text-white">Data Errors</th>]
                    l_cHtml += [<th class="text-white">Auto Trims Events</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(1,0)+[>]
                    l_cHtml += [<td class="bg-primary bg-gradient text-white">Total Count</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nTotalNumberOfApplicationErrors)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/ApplicationErrors/?]+l_cMode+[">]+trans(l_nTotalNumberOfApplicationErrors)+[</a>]
                        endif
                    l_cHtml += [</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nTotalNumberOfDataErrors)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/DataErrors/?]+l_cMode+[">]+trans(l_nTotalNumberOfDataErrors)+[</a>]
                        endif
                    l_cHtml += [</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nTotalNumberOfAutoTrimEvents)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/AutoTrimEvents/?]+l_cMode+[">]+trans(l_nTotalNumberOfAutoTrimEvents)+[</a>]
                        endif
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(2,0)+[>]
                    l_cHtml += [<td class="bg-primary bg-gradient text-white">Distinct Count</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nDistinctNumberOfApplicationErrors)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/DistinctApplicationErrors/?]+l_cMode+[">]+trans(l_nDistinctNumberOfApplicationErrors)+[</a>]
                        endif
                    l_cHtml += [</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nDistinctNumberOfDataErrors)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/DistinctDataErrors/?]+l_cMode+[">]+trans(l_nDistinctNumberOfDataErrors)+[</a>]
                        endif
                    l_cHtml += [</td>]

                    l_cHtml += [<td align="center">]
                        if !empty(l_nDistinctNumberOfAutoTrimEvents)
                            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[ErrorExplorer/DistinctAutoTrimEvents/?]+l_cMode+[">]+trans(l_nDistinctNumberOfAutoTrimEvents)+[</a>]
                        endif
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]

                // l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(3,0)+[>]
                //     l_cHtml += [<td class="bg-primary bg-gradient text-white">Latest Error</td>]
                //     l_cHtml += [<td>?</td>]
                //     l_cHtml += [<td>?</td>]
                //     l_cHtml += [<td>?</td>]
                // l_cHtml += [</tr>]

            l_cHtml += [</table>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]
endif

// l_cHtml += oFcgi:ListEnvironment()
l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function FormatDatetimeInTwoLines(par_tDatetime)
local l_cHtml
if !hb_IsNil(par_tDatetime) .and. !empty(par_tDatetime)
    l_cHtml := strtran(strtran(strtran(hb_TtoC(par_tDatetime,"MM/DD/YYYY","HH:MM:SS PM"),"  "," 0")," ","<br>",,1)," ","&nbsp;")
else
    l_cHtml := ""
endif
return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function AddLogFilteringOnDatetimeRangeMore(par_oDB_ListOfApplicationErrors,;
                                            par_lMyErrors,par_lCurrentApplicationVersion,par_lCurrentApplicationBuild,;
                                            par_cTableName,;
                                            par_cDatetimeColumnName,;
                                            par_nDatetimeRangeMode,;
                                            par_cLastReviewedDatetimeWithMicroSeconds,;
                                            par_cCurrentDatetimeWithMicroSeconds,;
                                            par_cDatetimeRangeFromWithMicroSeconds,;
                                            par_cDatetimeRangeToWithMicroSeconds)

if par_lMyErrors
    par_oDB_ListOfApplicationErrors:Where(par_cTableName+".fk_User = ^",oFcgi:p_iUserPk)
endif
if par_lCurrentApplicationVersion
    par_oDB_ListOfApplicationErrors:Where(par_cTableName+".ApplicationVersion = ^",BUILDVERSION)
endif
if par_lCurrentApplicationBuild
    par_oDB_ListOfApplicationErrors:Where(par_cTableName+".ApplicationBuildInfo = ^",hb_buildinfo())
endif

if !empty(par_cCurrentDatetimeWithMicroSeconds)
    par_oDB_ListOfApplicationErrors:Where(par_cTableName+"."+par_cDatetimeColumnName+" <= TO_TIMESTAMP('"+par_cCurrentDatetimeWithMicroSeconds+"','YYYY-MM-DD HH24:MI:SS.US')::timestamp AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"'")
endif

do case
case par_nDatetimeRangeMode == 1   // Since my last review
    if !empty(par_cLastReviewedDatetimeWithMicroSeconds)
        par_oDB_ListOfApplicationErrors:Where(par_cTableName+"."+par_cDatetimeColumnName+" > TO_TIMESTAMP('"+par_cLastReviewedDatetimeWithMicroSeconds+"','YYYY-MM-DD HH24:MI:SS.US')::timestamp AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"'")
    endif

case par_nDatetimeRangeMode == 2   // All

case par_nDatetimeRangeMode == 3   // After
    if !empty(par_cDatetimeRangeFromWithMicroSeconds)
        par_oDB_ListOfApplicationErrors:Where(par_cTableName+"."+par_cDatetimeColumnName+" >= TO_TIMESTAMP('"+par_cDatetimeRangeFromWithMicroSeconds+"','YYYY-MM-DD HH24:MI:SS.US')::timestamp AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"'")
    endif

case par_nDatetimeRangeMode == 4   // Between
    if !empty(par_cDatetimeRangeFromWithMicroSeconds)
        par_oDB_ListOfApplicationErrors:Where(par_cTableName+"."+par_cDatetimeColumnName+" >= TO_TIMESTAMP('"+par_cDatetimeRangeFromWithMicroSeconds+"','YYYY-MM-DD HH24:MI:SS.US')::timestamp AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"'")
    endif
    if !empty(par_cDatetimeRangeToWithMicroSeconds)
        par_oDB_ListOfApplicationErrors:Where(par_cTableName+"."+par_cDatetimeColumnName+" <= TO_TIMESTAMP('"+par_cDatetimeRangeToWithMicroSeconds+"','YYYY-MM-DD HH24:MI:SS.US')::timestamp AT TIME ZONE '"+oFcgi:p_cUserTimeZoneName+"'")
    endif

endcase
return nil
//=================================================================================================================
