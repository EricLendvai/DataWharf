#include "DataWharf.ch"
memvar oFcgi
//=================================================================================================================
function BuildPageHome()
local l_cHtml := []
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("BuildPageHome")

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center">]
    l_cHtml += [<div class="col-auto">]
        l_cHtml += [<div><h3>User: ]+oFcgi:p_cUserName+[</h3></div>]

        with object l_oDB1
            :Table("c5f56e48-2b2a-4f06-a951-f72238cfe7d7","LoginLogs")
            :Limit(10)
            :Column("LoginLogs.TimeIn","TimeIn")
            :Column("LoginLogs.IP"    ,"IP")
            :Where("LoginLogs.fk_User = ^",oFcgi:p_iUserPk)
            :OrderBy("TimeIn","desc")
            :SQL("ListOfRecords")
            if :Tally > 0
                select ListOfRecords
                l_cHtml += [<table class="table">]
                    l_cHtml += [<thead class="thead-dark">]
                        l_cHtml += [<tr>]
                            l_cHtml += [<th scope="col" colspan="2" style="text-align: center;">Login Log</th>]
                        l_cHtml += [</tr>]
                        
                        l_cHtml += [<tr>]
                            l_cHtml += [<th scope="col" style="text-align: center;">Login Time</th>]
                            l_cHtml += [<th scope="col" style="text-align: center;">IP</th>]
                        l_cHtml += [</tr>]
                        
                    l_cHtml += [</thead>]

                    l_cHtml += [<tbody>]

                        scan all
                            l_cHtml += [<tr>]
                                l_cHtml += [<td>]+hb_TToC(ListOfRecords->TimeIn,"MM/DD/YYYY","HH:MM:SS PM")+[</td>]
                                l_cHtml += [<td>]+allt(ListOfRecords->IP)+[</td>]
                            l_cHtml += [</tr>]
                        endscan

                    l_cHtml += [</tbody>]
                l_cHtml += [</table>]
            endif
        endwith

    l_cHtml += [</div>]
l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================                      
