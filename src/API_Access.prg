#include "DataWharf.ch"

//=================================================================================================================
function APIAccessCheck_Token_EndPoint(par_cAPITokenKey,par_cAPIEndpointName)
local l_nTokenAccessMode := 0
local l_oDB_ListOfAPIToken := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfAPIToken
    :Table("5964f5b9-b6f2-4d38-aeb0-a3396c55ca27","APIToken")
    :Column("APIToken.AccessMode" , "APIToken_AccessMode")
    :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
    :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
    :Where("APIToken.Key = ^"       , par_cAPITokenKey)
    :Where("APIToken.Status = ^"    , APITOKEN_STATUS_ACTIVE)
    :Where("APIEndpoint.Status = ^" , APIENDPOINT_STATUS_ACTIVE)
    :Where("LOWER(APIEndpoint.Name) = ^"   , lower(par_cAPIEndpointName))
    :SQL("ListOfAPIToken")

    if :Tally == 1
        l_nTokenAccessMode := ListOfAPIToken->APIToken_AccessMode
    endif
    // SendToClipboard(:LastSQL())
endwith

return l_nTokenAccessMode
//=================================================================================================================
function APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAPITokenKey,par_cAPIEndpointName,par_cApplicationLinkCode)
local l_lResult := .f.
local l_oDB_ListOfAPIToken := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfAPIToken
    :Table("5964f5b9-b6f2-4d38-aeb0-a3396c55ca28","APIToken")
    :Column("APIToken.AccessMode" , "APIToken_AccessMode")
    :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
    :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
    :Where("APIToken.Key = ^"       , par_cAPITokenKey)
    :Where("APIToken.Status = ^"    , APITOKEN_STATUS_ACTIVE)
    :Where("APIEndpoint.Status = ^" , APIENDPOINT_STATUS_ACTIVE)
    :Where("LOWER(APIEndpoint.Name) = ^"   , lower(par_cAPIEndpointName))

    :Join("inner","APITokenAccessApplication","","APITokenAccessApplication.fk_APIToken = APIToken.pk")
    :Join("inner","Application"              ,"","APITokenAccessApplication.fk_Application = Application.pk")
    :Where("Application.LinkCode = ^",par_cApplicationLinkCode)
    :Where("APITokenAccessApplication.AccessLevelDD >= ^",2)   //ReadOnly and Above

    :SQL("ListOfAPIToken")
    SendToClipboard(:LastSQL())
    l_lResult := (:Tally > 0)
endwith

return l_lResult
//=================================================================================================================
function APIAccessCheck_Token_EndPoint_Project_ReadRequest(par_cAPITokenKey,par_cAPIEndpointName,par_cProjectLinkUID)
local l_lResult := .f.
local l_oDB_ListOfAPIToken := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfAPIToken
    :Table("5964f5b9-b6f2-4d38-aeb0-a3396c55ca29","APIToken")
    :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
    :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
    :Where("APIToken.Key = ^"       , par_cAPITokenKey)
    :Where("APIToken.Status = ^"    , APITOKEN_STATUS_ACTIVE)
    :Where("APIEndpoint.Status = ^" , APIENDPOINT_STATUS_ACTIVE)
    :Where("LOWER(APIEndpoint.Name) = ^"   , lower(par_cAPIEndpointName))

    :Join("inner","APITokenAccessProject","","APITokenAccessProject.fk_APIToken = APIToken.pk")
    :Join("inner","Project"              ,"","APITokenAccessProject.fk_Project = Project.pk")
    :Where("Project.LinkUID = ^",par_cProjectLinkUID)
    :Where("APITokenAccessProject.AccessLevelML >= ^",2)   //ReadOnly and Above

    :SQL("ListOfAPIToken")
    SendToClipboard(:LastSQL())
    l_lResult := (:Tally > 0)
endwith

return l_lResult
//=================================================================================================================
function APIAccessCheck_Token_EndPoint_Model_ReadRequest(par_cAPITokenKey,par_cAPIEndpointName,par_cModelLinkUID)
local l_lResult := .f.
local l_oDB_ListOfAPIToken := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfAPIToken
    :Table("5964f5b9-b6f2-4d38-aeb0-a3396c55ca30","APIToken")
    :Join("inner","APIAccessEndpoint","","APIAccessEndpoint.fk_APIToken = APIToken.pk")
    :Join("inner","APIEndpoint"      ,"","APIAccessEndpoint.fk_APIEndpoint = APIEndpoint.pk")
    :Where("APIToken.Key = ^"       , par_cAPITokenKey)
    :Where("APIToken.Status = ^"    , APITOKEN_STATUS_ACTIVE)
    :Where("APIEndpoint.Status = ^" , APIENDPOINT_STATUS_ACTIVE)
    :Where("LOWER(APIEndpoint.Name) = ^"   , lower(par_cAPIEndpointName))

    :Join("inner","APITokenAccessProject","","APITokenAccessProject.fk_APIToken = APIToken.pk")
    :Join("inner","Project"              ,"","APITokenAccessProject.fk_Project = Project.pk")
    :Join("inner","Model"                ,"","Model.fk_Project = Project.pk")
    :Where("Model.LinkUID = ^"  ,par_cModelLinkUID)
    :Where("APITokenAccessProject.AccessLevelML >= ^",2)   //ReadOnly and Above

    :SQL("ListOfAPIToken")
    SendToClipboard(:LastSQL())
    l_lResult := (:Tally > 0)
endwith

return l_lResult
//=================================================================================================================
//=================================================================================================================

