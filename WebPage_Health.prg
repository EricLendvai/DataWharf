#include "DataWharf.ch"

//=================================================================================================================
//=================================================================================================================
function BuildPageHealth()
local l_cHtml := [UNBUFFERED]
local l_hStatus := {=>}

oFcgi:TraceAdd("BuildPageHealth")

l_hStatus["message"]   := "OK"

l_hStatus["zulu_time"] := strtran(hb_TSToStr(hb_TSToUTC(hb_DateTime()))," ","T")+"Z"

l_hStatus["version"] := BUILDVERSION

l_hStatus["build Info"] := {"datawharf"   => hb_buildinfo(),;
                            "harbour_orm" => hb_orm_buildinfo(),;
                            "harbour_vfp" => hb_vfp_buildinfo();
                           }

if !oFcgi:p_o_SQLConnection:SQLExec("select version() as version","VersionInfo")
    l_hStatus["data_server"] := "Failed to connect to data server."
else
    l_hStatus["data_server"] := VersionInfo->version
endif
CloseAlias("VersionInfo")

oFcgi:SetContentType("application/json")

l_cHtml += hb_jsonEncode(l_hStatus,.t.,"UTF8")

return l_cHtml
//=================================================================================================================                      
