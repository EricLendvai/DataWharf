#include "DataWharf.ch"

//=================================================================================================================
function BuildPageAbout()
local l_cHtml := []
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cDataServer

oFcgi:TraceAdd("BuildPageAbout")

if !oFcgi:p_o_SQLConnection:SQLExec("BuildPageAbout","select version() as version","VersionInfo")
    l_cDataServer := "Failed to connect to data server."
else
    l_cDataServer := VersionInfo->version
endif
CloseAlias("VersionInfo")

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]

    l_cHtml += [<div class="col-auto">]
     
        // l_cHtml += [<div><h3>Info</h3></div>]

        l_cHtml += [<table class="table table-sm table-bordered table-striped">]

        l_cHtml += [<tr><td>Based on and License</td>]+[<td><a href="https://github.com/EricLendvai/DataWharf" target="_blank">https://github.com/EricLendvai/DataWharf</a></td></tr>]
        l_cHtml += [<tr><td>Protocol</td>]            +[<td>]+oFcgi:RequestSettings["Protocol"]   +[</td></tr>]
        l_cHtml += [<tr><td>Port</td>]                +[<td>]+trans(oFcgi:RequestSettings["Port"])+[</td></tr>]
        l_cHtml += [<tr><td>Host</td>]                +[<td>]+oFcgi:RequestSettings["Host"]       +[</td></tr>]
        l_cHtml += [<tr><td>Site Path</td>]           +[<td>]+oFcgi:p_cSitePath   +[</td></tr>]
        l_cHtml += [<tr><td>Path</td>]                +[<td>]+oFcgi:RequestSettings["Path"]       +[</td></tr>]
        l_cHtml += [<tr><td>Page</td>]                +[<td>]+oFcgi:RequestSettings["Page"]       +[</td></tr>]
        l_cHtml += [<tr><td>Query String</td>]        +[<td>]+oFcgi:RequestSettings["QueryString"]+[</td></tr>]
        l_cHtml += [<tr><td>Web Server IP</td>]       +[<td>]+oFcgi:RequestSettings["WebServerIP"]+[</td></tr>]
        l_cHtml += [<tr><td>Client IP</td>]           +[<td>]+oFcgi:RequestSettings["ClientIP"]   +[</td></tr>]

        l_cHtml += [<tr><td>Web Site Version</td>]    +[<td>]+BUILDVERSION                        +[</td></tr>]
        l_cHtml += [<tr><td>Site Build Info</td>]     +[<td>]+hb_buildinfo()                      +[</td></tr>]
        l_cHtml += [<tr><td>ORM Build Info</td>]      +[<td>]+hb_orm_buildinfo()                  +[</td></tr>]
        l_cHtml += [<tr><td>EL Build Info</td>]      +[<td>]+hb_el_buildinfo()                  +[</td></tr>]
        l_cHtml += [<tr><td>Data Server</td>]         +[<td>]+l_cDataServer                       +[</td></tr>]

        l_cHtml += [</table>]

    l_cHtml += [</div>]
l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
