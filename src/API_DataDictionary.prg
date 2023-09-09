#include "DataWharf.ch"

//=================================================================================================================
// // Example: /api/GetApplicationInformation
// function GetApplicationInformation()

// local l_cResponse := {=>}

// l_cResponse["ApplicationName"]    := oFcgi:p_cThisAppTitle
// l_cResponse["ApplicationVersion"] := BUILDVERSION
// l_cResponse["SiteBuildInfo"]      :=hb_buildinfo()

// // _M_ Should we also return the PostgreSQL host name and database name?

// return hb_jsonEncode(l_cResponse)
//=================================================================================================================

//=================================================================================================================
// Example: /api/applications
function APIGetListOfApplications(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)

local l_cResponse := ""
local l_cApplicationLinkCode  := oFcgi:GetQueryString("application")
local l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfApplications
local l_aListOfApplications := {}
local l_hApplicationInfo    := {=>}

with object l_oDB_ListOfApplications
    :Table("730e57e0-6b4d-44b4-bf30-f4ef93ce4694","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.LinkCode"   ,"Application_LinkCode")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Application.UseStatus"  ,"Application_UseStatus")
    :Column("Application.Description","Application_Description")
    :Column("Upper(Application.Name)","tag1")
    if !empty(l_cApplicationLinkCode)
        :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
    endif
    :OrderBy("tag1")

    :SQL("ListOfApplications")
    l_nNumberOfApplications := :Tally
endwith

if l_nNumberOfApplications < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 730e57e0-6b4d-44b4-bf30-f4ef93ce4694"})
     oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfApplications
    scan all
        hb_HClear(l_hApplicationInfo)
        l_hApplicationInfo["linkcode"]  := ListOfApplications->Application_LinkCode
        l_hApplicationInfo["name"] := ListOfApplications->Application_Name

        AAdd(l_aListOfApplications,hb_hClone(l_hApplicationInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cApplicationLinkCode)
        if l_nNumberOfApplications == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfApplications == 1
            l_cResponse := hb_jsonEncode(l_aListOfApplications[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
            "@recordsetCount" => l_nNumberOfApplications,;
            "items" => l_aListOfApplications;
        })
    endif
endif

return l_cResponse
//=================================================================================================================
// Example: /api/application_harbour_schema_export
function APIGetApplicationHarbourSchemaExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)

local l_cResponse := ""
local l_cApplicationLinkCode   := oFcgi:GetQueryString("application")
local l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfApplications

if par_nTokenAccessMode == 1 .and. !APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAccessToken,par_cAPIEndpointName,l_cApplicationLinkCode)
    l_cResponse := "Access Denied"
else
    //par_nTokenAccessMode will be more than 1 (Read Only and Full Access) if is not application accessible.
    if empty(l_cApplicationLinkCode)
        l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Missing LinkCode parameter"})
        oFcgi:SetHeaderValue("Status","500 Internal Server Error")
    else
        with object l_oDB_ListOfApplications
            :Table("750c8b4a-11ad-4cb6-a805-dc6d45f1b1a1","Application")
            :Column("Application.pk" ,"pk")
            if !empty(l_cApplicationLinkCode)
                :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
            endif

            :SQL("ListOfApplications")
            l_nNumberOfApplications := :Tally
        endwith

        if l_nNumberOfApplications != 1
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 750c8b4a-11ad-4cb6-a805-dc6d45f1b1a1"})
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
        else
            l_cResponse := ExportApplicationToHbORM(ListOfApplications->pk)
        endif
    endif
endif

return l_cResponse
//=================================================================================================================
//=================================================================================================================