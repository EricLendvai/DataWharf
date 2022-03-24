#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"


//=================================================================================================================

// Temp code used during development
// l_cResponse := "Version = "+l_cVersion+CRLF
// l_cResponse += hb_jsonEncode({"FirstName"=>"Eric","LastName"=>"Lendvai"})

//=================================================================================================================
//=================================================================================================================
// Example: /api/GetApplicationInformation
function GetApplicationInformation()

local l_cResponse := {=>}
local l_cThisAppTitle

l_cThisAppTitle := oFcgi:GetAppConfig("APPLICATION_TITLE")
if empty(l_cThisAppTitle)
    l_cThisAppTitle := APPLICATION_TITLE
endif

l_cResponse["ApplicationName"]    := l_cThisAppTitle
l_cResponse["ApplicationVersion"] := BUILDVERSION
l_cResponse["SiteBuildInfo"]      :=hb_buildinfo()

// _M_ Should we also return the PostgreSQL host name and database name?

return hb_jsonEncode(l_cResponse)
//=================================================================================================================
// Example: /api/GetProjects/v1
function APIGetListOfProjects()

local l_cResponse := ""
//local l_cVersion  := GetAPIURIElement(2)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfProjects
local l_aListOfProjects := {}
local l_hProjectInfo    := {=>}

with object l_oDB1
    :Table("493f214c-aa5a-4d63-a465-9d5a4adeaa48","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Project.LinkUID"    ,"Project_LinkUID")
    :Column("Project.UseStatus"  ,"Project_UseStatus")
    :Column("Project.Description","Project_Description")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfProjects")
    l_nNumberOfProjects := :Tally

    if l_nNumberOfProjects <= 0
        l_cResponse += hb_jsonEncode({"Error"=>"No Projects"})
    else
        select ListOfProjects
        scan all
            hb_HClear(l_hProjectInfo)
            l_hProjectInfo["Name"] := ListOfProjects->Project_Name
            l_hProjectInfo["UID"]  := ListOfProjects->Project_LinkUID

            AAdd(l_aListOfProjects,hb_hClone(l_hProjectInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

        endscan
        l_cResponse := hb_jsonEncode(l_aListOfProjects)
    endif

endwith

return l_cResponse
//=================================================================================================================
