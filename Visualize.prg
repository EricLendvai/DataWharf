#include "DataWharf.ch"
memvar oFcgi

//=================================================================================================================
function DataDictionaryVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,par_iDiagramPk)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_oData
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cNodePositions := ""
local l_hNodePositions := {=>}
local l_nLengthDecoded
local l_hCoordinate
local l_cNodeLabel
local l_nNumberOfTableInDiagram
local l_lShowNameSpace := .f.
local l_cNameSpace_Name

oFcgi:TraceAdd("DataDictionaryVisualizeDesignBuild")

// See https://visjs.github.io/vis-network/examples/

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

With Object l_oDB1

    :Table("44eabf03-8b35-4e96-a128-e9c1bc6168f0","Diagram")
    :Column("Diagram.pk"         ,"Diagram_pk")
    :Column("Diagram.Name"       ,"Diagram_Name")
    :Column("Upper(Diagram.Name)","Tag1")
    :Column("Diagram.VisPos" ,"Diagram_VisPos")
    :Where("Diagram.fk_Application = ^" , par_iApplicationPk)
    :OrderBy("Tag1")
    :SQL("ListOfDiagrams")

    l_cNodePositions := ""

endwith

With Object l_oDB2
    //Check if there is at least one record in DiagramTable for the current Diagram
    :Table("66daafd2-9566-43be-85e5-b663682ba88c","DiagramTable")
    :Where("DiagramTable.fk_Diagram = ^" , par_iDiagramPk)
    l_nNumberOfTableInDiagram := :Count()
    
    if l_nNumberOfTableInDiagram == 0
        // All Tables
        :Table("5ad2a893-e8bd-40e5-8eb0-a6e4bafbbf51","Table")
        :Column("Table.pk"         ,"pk")
        :Column("NameSpace.Name"   ,"NameSpace_Name")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.UseStatus"  ,"Table_UseStatus")
        :Column("Table.DocStatus"  ,"Table_DocStatus")
        :Column("Table.Description","Table_Description")
        :Column("Upper(NameSpace.Name)","tag1")
        :Column("Upper(Table.Name)","tag2")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :SQL("ListOfTables")
    else
        // A subset of Tables

        :Table("545ab66b-9384-4e06-abf3-ce8e529aa6e1","DiagramTable")
        :Distinct(.t.)
        :Column("Table.pk"         ,"pk")
        :Column("NameSpace.Name"   ,"NameSpace_Name")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.UseStatus"  ,"Table_UseStatus")
        :Column("Table.DocStatus"  ,"Table_DocStatus")
        :Column("Table.Description","Table_Description")
        :Column("Upper(NameSpace.Name)","tag1")
        :Column("Upper(Table.Name)","tag2")
        :Join("inner","Table","","DiagramTable.fk_Table = Table.pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("DiagramTable.fk_Diagram = ^" , par_iDiagramPk)
        :SQL("ListOfTables")

    endif

    select ListOfTables
    l_cNameSpace_Name := ListOfTables->NameSpace_Name
    locate for ListOfTables->NameSpace_Name <> l_cNameSpace_Name
    l_lShowNameSpace := Found()

endwith

// l_cHtml += '<script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>'

l_cHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/vis_2021_11_11_001/vis-network.min.js"></script>]

l_cHtml += [<style type="text/css">]
l_cHtml += [  #mynetwork {]
l_cHtml += [    width: 1200px;]
l_cHtml += [    height: 800px;]
l_cHtml += [    border: 1px solid lightgray;]
l_cHtml += [  }]
l_cHtml += [</style>]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Design">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextNodePositions" name="TextNodePositions" value="">]
l_cHtml += [<input type="hidden" id="TextDiagramPk" name="TextDiagramPk" value="]+Trans(par_iDiagramPk)+[">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        //---------------------------------------------------------------------------
        l_cHtml += [<button id="ButtonSaveLayout" class="btn btn-primary rounded ms-3" onclick="]

        l_cHtml += [network.storePositions();]

        //Since the redraw() fails to make the edges straight, need to actually submit the entire form.
        // l_cHtml += [$.ajax({]
        // l_cHtml += [  type: 'GET',]
        // l_cHtml += [  url: ']+l_cSitePath+[ajax/VisualizationPositions',]
        // l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&pos='+JSON.stringify(network.getPositions()),]
        // l_cHtml += [  cache: false ]
        // l_cHtml += [});]

        l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
        l_cHtml += [$('#ActionOnSubmit').val('SaveLayout');document.form.submit();]

        //Code used to debug the positions.
        l_cHtml += [">Save Layout</button>]
        //---------------------------------------------------------------------------
        // l_cHtml += [<button class="btn btn-primary rounded me-3" onclick="]
        
        // // l_cHtml += [$.ajax({]
        // // l_cHtml += [  type: 'GET',]
        // // l_cHtml += [  url: ']+l_cSitePath+[ajax/VisualizationPositions',]
        // // l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&pos=reset',]
        // // l_cHtml += [  cache: false ]
        // // l_cHtml += [});]

        // //Code used to debug the positions.
        // l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
        // l_cHtml += [$('#ActionOnSubmit').val('ResetLayout');document.form.submit();]

        // l_cHtml += [">Reset Layout</button>]
        //---------------------------------------------------------------------------
         l_cHtml += [<button class="btn btn-primary rounded ms-3" onclick="$('#ActionOnSubmit').val('Settings');document.form.submit();">Settings</button>]
        //---------------------------------------------------------------------------
         l_cHtml += [<select id="ComboDiagramPk" name="ComboDiagramPk" onchange="$('#TextDiagramPk').val(this.value);$('#ActionOnSubmit').val('Show');document.form.submit();" class="ms-3">]

            select ListOfDiagrams
            scan all
                l_cHtml += [<option value="]+Trans(ListOfDiagrams->Diagram_Pk)+["]+iif(ListOfDiagrams->Diagram_Pk == par_iDiagramPk,[ selected],[])+[>]+ListOfDiagrams->Diagram_Name+[</option>]

                if ListOfDiagrams->Diagram_pk == par_iDiagramPk
                    l_cNodePositions := ListOfDiagrams->Diagram_VisPos
                endif

            endscan
         l_cHtml += [</select>]
        //---------------------------------------------------------------------------
         l_cHtml += [<button class="btn btn-primary rounded ms-3" onclick="$('#ActionOnSubmit').val('NewDiagram');document.form.submit();">New Diagram</button>]
        //---------------------------------------------------------------------------

    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_nLengthDecoded := hb_jsonDecode(l_cNodePositions,@l_hNodePositions)

l_cHtml += [<table><tr>]
//-------------------------------------
l_cHtml += [<td valign="top">]
l_cHtml += [<div id="mynetwork"></div>]
l_cHtml += [</td>]
//-------------------------------------
l_cHtml += [<td valign="top">]
l_cHtml += [<div id="GraphInfo"></div>]
l_cHtml += [</td>]
//-------------------------------------
l_cHtml += [</tr></table>]

//Code used to debug the positions.
// l_cHtml += [<div><input type="text" name="TextNodePositions" id="TextNodePositions" size="100" value=""></div>]

l_cHtml += [</form>]

l_cHtml += [<script type="text/javascript">]

l_cHtml += [var network;]

l_cHtml += [function MakeVis(){]

// create an array with nodes
l_cHtml += 'var nodes = new vis.DataSet(['
select ListOfTables
scan all
    if l_lShowNameSpace
        l_cNodeLabel := AllTrim(ListOfTables->NameSpace_Name)+"\n"+AllTrim(ListOfTables->Table_Name)
    else
        l_cNodeLabel := AllTrim(ListOfTables->Table_Name)
    endif
    l_cHtml += [{id:]+Trans(ListOfTables->pk)+[,label:"]+l_cNodeLabel+["]

    if ListOfTables->Table_UseStatus >= 4
        l_cHtml += [,color:{background:'#ff9696',highlight:{background:'#feb4b4'}}]
    endif

    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,Trans(ListOfTables->pk),{=>})
        if len(l_hCoordinate) > 0
            l_cHtml += [,x:]+Trans(l_hCoordinate["x"])+[,y:]+Trans(l_hCoordinate["y"])
        endif
    endif
    l_cHtml += [},]
endscan
l_cHtml += ']);'

// create an array with edges
With Object l_oDB2
    :Table("8fdc0db2-ac61-4d60-95fc-ce435c6a8bac","Table")
    :Column("Table.pk"              ,"pkFrom")
    :Column("Column.fk_TableForeign","pkTo")
    :Column("Column.UseStatus"      ,"Column_UseStatus")
    :Column("Column.DocStatus"      ,"Column_DocStatus")
    :Column("Column.pk"             ,"Column_Pk")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Where("Column.fk_TableForeign <> 0")
    :SQL("ListOfLinks")
endwith

l_cHtml += 'var edges = new vis.DataSet(['

select ListOfLinks
scan all
    l_cHtml += [{id:"]+Trans(ListOfLinks->Column_Pk)+[",from:]+Trans(ListOfLinks->pkFrom)+[,to:]+Trans(ListOfLinks->pkTo)+[,arrows:"from"]
    if ListOfLinks->Column_UseStatus >= 4
        l_cHtml += [,color:{color:'#ff6b6b',highlight:'#ff3e3e'}]
    endif
    l_cHtml += [},]  //,physics: false , smooth: { type: "cubicBezier" }
endscan

l_cHtml += ']);'

// create a network
l_cHtml += [  var container = document.getElementById("mynetwork");]
l_cHtml += [  var data = {]
l_cHtml += [    nodes: nodes,]
l_cHtml += [    edges: edges,]
l_cHtml += [  };]
l_cHtml += [  var options = {nodes:{shape:"box",margin:12,physics:false},]
l_cHtml +=                  [edges:{physics:false},};]
l_cHtml += [  network = new vis.Network(container, data, options);]  //var

l_cHtml += ' network.on("click", function (params) {'
l_cHtml += '   params.event = "[original event]";'
l_cHtml += '   $("#GraphInfo" ).load( "'+l_cSitePath+'ajax/GetInfo","info="+JSON.stringify(params) );'
l_cHtml += '      });'

l_cHtml += ' network.on("dragStart", function (params) {'
l_cHtml += '   params.event = "[original event]";'
// l_cHtml += '   debugger;'
l_cHtml += "   if (params['nodes'].length == 1) {$('#ButtonSaveLayout').addClass('btn-warning').removeClass('btn-primary');};"
l_cHtml += '      });'

l_cHtml += [};]

l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [MakeVis();]

return l_cHtml
//=================================================================================================================
function DataDictionaryVisualizeDesignOnSubmit(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_cNodePositions
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iDiagram_pk
local l_cErrorMessage

oFcgi:TraceAdd("DataDictionaryVisualizeDesignOnSubmit")

l_iDiagram_pk := Val(oFcgi:GetInputValue("TextDiagramPk"))

do case
case l_cActionOnSubmit == "Show"
    l_cHtml += DataDictionaryVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)

case l_cActionOnSubmit == "Settings"
    l_cHtml := DataDictionaryVisualizeSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)

case l_cActionOnSubmit == "NewDiagram"
    l_cHtml := DataDictionaryVisualizeSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,0)

case l_cActionOnSubmit == "SaveLayout"
    l_cNodePositions  := Strtran(SanitizeInput(oFcgi:GetInputValue("TextNodePositions")),[%22],["])

    With Object l_oDB1
        :Table("617ce583-369e-468b-9227-63bb429564a0","Diagram")
        :Field("Diagram.VisPos",l_cNodePositions)
        if empty(l_iDiagram_pk)
            //Add an initial Diagram File this should not happen, since record was already added
            :Field("Diagram.fk_Application",par_iApplicationPk)
            :Field("Diagram.Name"          ,"All Tables")
            :Field("Diagram.UseStatus"     ,1)
            :Field("Diagram.DocStatus"     ,1)
            if :Add()
                l_iDiagram_pk := :Key()
            endif
        else
            :Update(l_iDiagram_pk)
        endif
    endwith
    l_cHtml += DataDictionaryVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
function DataDictionaryVisualizeSettingsOnSubmit(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_cNodePositions
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iDiagram_pk
local l_cDiagram_Name
local l_cErrorMessage
local l_lSelected
local l_cValue
local l_hValues := {=>}

oFcgi:TraceAdd("DataDictionaryVisualizeSettingsOnSubmit")

l_iDiagram_pk   := Val(oFcgi:GetInputValue("TextDiagramPk"))
l_cDiagram_Name := SanitizeInput(oFcgi:GetInputValue("TextName"))

do case
case l_cActionOnSubmit == "SaveDiagram"
    //Get all the Application Tables to help scan all the selection checkboxes.
    with Object l_oDB2
        :Table("70126bd9-f5b7-49e1-8d65-6aef01ab3368","Table")
        :Column("Table.pk"         ,"pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :SQL("ListOfAllTablesInApplication")
    endwith

    do case
    case empty(l_cDiagram_Name)
        l_cErrorMessage := "Missing Name"
    otherwise
        with object l_oDB1
            :Table("bcc7cf4c-4fb4-41a3-a8d8-88c8c9f3d797","Diagram")
            :Where([lower(replace(Diagram.Name,' ','')) = ^],lower(StrTran(l_cDiagram_Name," ","")))
            :Where([Diagram.fk_Application = ^],par_iApplicationPk)
            if l_iDiagram_pk > 0
                :Where([Diagram.pk != ^],l_iDiagram_pk)
            endif
            :SQL()
        endwith
        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        endif
    endcase

    if empty(l_cErrorMessage)
        With Object l_oDB1
            :Table("d303eed8-944e-4a7c-8314-133eb13fca3d","Diagram")
            :Field("Diagram.Name",l_cDiagram_Name)
            if empty(l_iDiagram_pk)
                :Field("Diagram.fk_Application",par_iApplicationPk)
                :Field("Diagram.UseStatus"     , 1)
                :Field("Diagram.DocStatus"     , 1)
                if :Add()
                    l_iDiagram_pk := :Key()
                else
                    l_iDiagram_pk := 0
                    l_cErrorMessage := "Failed to save changes!"
                endif
            else
                if !:Update(l_iDiagram_pk)
                    l_cErrorMessage := "Failed to save changes!"
                endif

            endif
        endwith
    endif

    if empty(l_cErrorMessage)
        //Update the list selected tables
        //Get current list of diagram tables
        with Object l_oDB1
            :Table("225a41d2-6c7d-4c3d-bdbb-4757f6acc087","DiagramTable")
            :Distinct(.t.)
            :Column("Table.pk","pk")
            :Column("DiagramTable.pk","DiagramTable_pk")
            :Join("inner","Table","","DiagramTable.fk_Table = Table.pk")
            :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
            :Where("DiagramTable.fk_Diagram = ^" , l_iDiagram_pk)
            :SQL("ListOfCurrentTablesInDiagram")
            With Object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith        
        endwith

        select ListOfAllTablesInApplication
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckTable"+Trans(ListOfAllTablesInApplication->pk)) == "1")

            if VFP_Seek(ListOfAllTablesInApplication->pk,"ListOfCurrentTablesInDiagram","pk")
                if !l_lSelected
                    // Remove the table
                    with Object l_oDB3
                        if !:Delete("254d6227-f160-412e-a8b7-9ff4f3cf1dc5","DiagramTable",ListOfCurrentTablesInDiagram->DiagramTable_pk)
                            l_cErrorMessage := "Failed to Save table selection."
                            exit
                        endif
                    endwith
                endif
            else
                if l_lSelected
                    // Add the table
                    with Object l_oDB3
                        :Table("0f252d7a-6656-4ef0-a2be-f85bf84f93fb","DiagramTable")
                        :Field("DiagramTable.fk_Table"   ,ListOfAllTablesInApplication->pk)
                        :Field("DiagramTable.fk_Diagram" ,l_iDiagram_pk)
                        if !:Add()
                            l_cErrorMessage := "Failed to Save table selection."
                            exit
                        endif
                    endwith
                endif
            endif
        endscan
    else
        // Keep current list of selection to be used by Build
    endif

    if empty(l_cErrorMessage)
        l_cHtml += DataDictionaryVisualizeDesignBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)
    else
        l_hValues["Name"] := l_cDiagram_Name
        select ListOfAllTablesInApplication
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckTable"+Trans(ListOfAllTablesInApplication->pk)) == "1")
            if l_lSelected  // No need to store the unselect references, since not having a reference will mean "not selected"
                l_hValues["Table"+Trans(ListOfAllTablesInApplication->pk)] := .t.
            endif
        endscan
        l_cHtml := DataDictionaryVisualizeSettingsBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk,l_hValues)
    endif

case l_cActionOnSubmit == "Cancel"
    l_cHtml += DataDictionaryVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)

case l_cActionOnSubmit == "Delete"
    With Object l_oDB1
        //Delete related records in DiagramTable
        :Table("c4d616b9-9f17-47f2-a536-42ec624b3d46","DiagramTable")
        :Column("DiagramTable.pk","pk")
        :Where("DiagramTable.fk_Diagram = ^" , l_iDiagram_pk)
        :SQL("ListOfDiagramTableToDelete")
        select ListOfDiagramTableToDelete
        scan all
            l_oDB2:Delete("469afb28-2829-4400-9670-a3e6acfd592a","DiagramTable",ListOfDiagramTableToDelete->pk)
        endscan
        l_oDB2:Delete("a9a53831-eceb-4280-ba8d-23decf60c87c","Diagram",l_iDiagram_pk)
    endwith
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/ApplicationVisualize/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "ResetLayout"
    With Object l_oDB1
        :Table("222b379f-8605-40ce-a35f-c57fecd78d08","Diagram")
        :Field("Diagram.VisPos",NIL)
        :Update(l_iDiagram_pk)
    endwith
    l_cHtml += DataDictionaryVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
// The Following function was used by deprecated Ajax Call
// function SaveVisualizationPositions()

// local l_iApplicationPk := val(oFcgi:GetQueryString("apppk"))
// local l_cNodePositions := Strtran(oFcgi:GetQueryString("pos"),[%22],["])

// local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

// With Object l_oDB1
//     :Table("44111d36-963b-42f1-b4e5-4c4e4e5ffd13","Application")
//     :Field("Application.VisPos",l_cNodePositions)
//     :Update(l_iApplicationPk)
// endwith

// return ""
//=================================================================================================================
function GetInfoDuringVisualization()
local l_cHtml := []
local l_cInfo := Strtran(oFcgi:GetQueryString("info"),[%22],["])
local l_hOnClickInfo := {=>}
local l_nLengthDecoded
local l_aNodes
local l_aEdges
local l_iTablePk
local l_iColumnPk
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData
local l_aSQLResult := {}
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cApplicationLinkCode
local l_cNameSpaceName
local l_cTableName
local l_cTableDescription
local l_nTableUseStatus
local l_nTableDocStatus
local l_cColumnName
local l_nColumnUseStatus
local l_nColumnDocStatus
local l_cFrom_NameSpace_Name
local l_cFrom_Table_Name
local l_cTo_NameSpace_Name
local l_cTo_Table_Name

oFcgi:TraceAdd("GetInfoDuringVisualization")

// l_cHtml += [Hello World c2 - ]+hb_TtoS(hb_DateTime())+[  ]+l_cInfo

l_nLengthDecoded := hb_jsonDecode(l_cInfo,@l_hOnClickInfo)
// Altd()

// if l_hOnClickInfo["nodes"]  is an array. if len is 1 we have the table.pk
// if l_hOnClickInfo["nodes"] is a 0 size array and l_hOnClickInfo["edges"] array of len 1   will be column.pk

l_aNodes := hb_HGetDef(l_hOnClickInfo,"nodes",{})
if len(l_aNodes) == 1
    l_iTablePk := l_aNodes[1]

    //Clicked on a table
    with object l_oDB1
        :Table("da9443c6-bffe-4ccd-bded-c3a7221bac9f","Table")
        :Column("Application.LinkCode","Application_LinkCode")
        :Column("NameSpace.name"      ,"NameSpace_Name")
        :Column("Table.Name"          ,"Table_Name")
        :Column("Table.Description"   ,"Table_Description")
        :Column("Table.UseStatus"     ,"Table_UseStatus")
        :Column("Table.DocStatus"     ,"Table_DocStatus")
        :join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :join("inner","Application","","NameSpace.fk_Application = Application.pk")
        :Where("Table.pk = ^" , l_iTablePk)
        :SQL(@l_aSQLResult)

        if :Tally == 1
            l_cApplicationLinkCode := AllTrim(l_aSQLResult[1,1])
            l_cNameSpaceName       := AllTrim(l_aSQLResult[1,2])
            l_cTableName           := AllTrim(l_aSQLResult[1,3])
            l_cTableDescription    := nvl(l_aSQLResult[1,4],"")
            l_nTableUseStatus      := l_aSQLResult[1,5]
            l_nTableDocStatus      := l_aSQLResult[1,6]

            l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]+iif(l_nTableUseStatus>=4,"feb4b4","d2e5ff")+[;">]
                l_cHtml += [<div class="input-group">]
                    l_cHtml += [<span class="navbar-brand ms-3">]+l_cNameSpaceName+[.]+l_cTableName+[</span>]
                    if !empty(l_cTableDescription)
                        l_cHtml += [<div>]+TextToHTML(l_cTableDescription)+[</div>]
                    endif
                l_cHtml += [</div>]
            l_cHtml += [</nav>]

            l_cHtml += [<div class="m-3"></div>]

            :Table("4d84f290-c1f8-42f1-a2b0-e41244ccdfd2","Column")
            :Column("Column.pk"             ,"pk")
            :Column("Column.Name"           ,"Column_Name")
            :Column("Column.UseStatus"      ,"Column_UseStatus")
            :Column("Column.DocStatus"      ,"Column_DocStatus")
            :Column("Column.Description"    ,"Column_Description")
            :Column("Column.Order"          ,"Column_Order")
            :Column("Column.Type"           ,"Column_Type")
            :Column("Column.Length"         ,"Column_Length")
            :Column("Column.Scale"          ,"Column_Scale")
            :Column("Column.Nullable"       ,"Column_Nullable")
            :Column("Column.UsedBy"         ,"Column_UsedBy")
            :Column("Column.fk_TableForeign","Column_fk_TableForeign")
            :Column("Column.fk_Enumeration" ,"Column_fk_Enumeration")

            :Column("NameSpace.Name"                ,"NameSpace_Name")
            :Column("Table.Name"                    ,"Table_Name")
            :Column("Enumeration.Name"              ,"Enumeration_Name")
            :Column("Enumeration.ImplementAs"       ,"Enumeration_ImplementAs")
            :Column("Enumeration.ImplementLength"   ,"Enumeration_ImplementLength")
            
            :Join("left","Table"      ,"","Column.fk_TableForeign = Table.pk")
            :Join("left","NameSpace"  ,"","Table.fk_NameSpace = NameSpace.pk")
            :Join("left","Enumeration","","Column.fk_Enumeration  = Enumeration.pk")
            :Where("Column.fk_Table = ^",l_iTablePk)
            :OrderBy("Column_Order")
            :SQL("ListOfColumns")

            if :Tally > 0
                l_cHtml += [<div class="m-3">]

                    l_cHtml += [<div class="row justify-content-center">]
                        l_cHtml += [<div class="col-auto">]

                            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                            l_cHtml += [<tr class="bg-info">]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Nullable</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Foreign Key To</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Doc<br>Status</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Used By</th>]
                            l_cHtml += [</tr>]

                            select ListOfColumns
                            scan all
                                l_cHtml += [<tr>]

                                    // Name
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += [<a target="_blank" href="]+l_cSitePath+[Applications/EditColumn/]+l_cApplicationLinkCode+"/"+l_cNameSpaceName+"/"+l_cTableName+[/]+Allt(ListOfColumns->Column_Name)+[/">]+Allt(ListOfColumns->Column_Name)+[</a>]
                                    l_cHtml += [</td>]

                                    // Type
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += FormatColumnTypeInfo(allt(ListOfColumns->Column_Type),;
                                                                        ListOfColumns->Column_Length,;
                                                                        ListOfColumns->Column_Scale,;
                                                                        ListOfColumns->Enumeration_Name,;
                                                                        ListOfColumns->Enumeration_ImplementAs,;
                                                                        ListOfColumns->Enumeration_ImplementLength,;
                                                                        l_cSitePath,;
                                                                        l_cApplicationLinkCode,;
                                                                        l_cNameSpaceName)
                                    l_cHtml += [</td>]

                                    // Nullable
                                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                                        l_cHtml += iif(alltrim(ListOfColumns->Column_Nullable) == "1",[<i class="fas fa-check"></i>],[&nbsp;])
                                    l_cHtml += [</td>]

                                    // Foreign Key To
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        if !hb_isNil(ListOfColumns->Table_Name)
                                            l_cHtml += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+l_cSitePath+[Applications/ListColumns/]+l_cApplicationLinkCode+"/"+ListOfColumns->NameSpace_Name+"/"+ListOfColumns->Table_Name+[/">]
                                            l_cHtml += ListOfColumns->NameSpace_Name+[.]+ListOfColumns->Table_Name
                                            l_cHtml += [</a>]
                                        endif
                                    l_cHtml += [</td>]

                                    // Description
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfColumns->Column_Description,""))
                                    l_cHtml += [</td>]

                                    // Use Status
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += {"","Active","Inactive (Read Only)","Archived (Read Only and Hidden)"}[iif(vfp_between(ListOfColumns->Column_UseStatus,1,4),ListOfColumns->Column_UseStatus,1)]
                                    l_cHtml += [</td>]

                                    // Doc Status
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += {"","Not Needed","In Progress","Complete"}[iif(vfp_between(ListOfColumns->Column_DocStatus,1,4),ListOfColumns->Column_DocStatus,1)]
                                    l_cHtml += [</td>]

                                    // Used By
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += GetItemInListAtPosition(ListOfColumns->Column_UsedBy,{"","MySQL Only","PostgreSQL Only"},"")
                                    l_cHtml += [</td>]

                                l_cHtml += [</tr>]
                            endscan
                            l_cHtml += [</table>]
                            
                        l_cHtml += [</div>]
                    l_cHtml += [</div>]

                l_cHtml += [</div>]
            endif

        endif
    endwith

else
    l_aEdges := hb_HGetDef(l_hOnClickInfo,"edges",{})
    if len(l_aEdges) == 1
        l_iColumnPk := l_aEdges[1]

        with object l_oDB1
            :Table("9410bb49-ad19-458f-9a77-b33b29afcccf","Column")

            :Column("Column.Name  "    ,"Column_Name")
            :Column("Column.UseStatus" ,"Column_UseStatus")
            :Column("Column.DocStatus" ,"Column_DocStatus")
            
            :Column("NameSpace.Name"   ,"From_NameSpace_Name")
            :Column("Table.Name"       ,"From_Table_Name")
            :join("inner","Table"      ,"","Column.fk_Table = Table.pk")
            :join("inner","NameSpace"  ,"","Table.fk_NameSpace = NameSpace.pk")
            :join("inner","Application","","NameSpace.fk_Application = Application.pk")

            :Column("NameSpaceTo.name" , "To_NameSpace_Name")
            :Column("TableTo.name"     , "To_Table_Name")
            :Join("inner","Table"    ,"TableTo"    ,"Column.fk_TableForeign = TableTo.pk")
            :Join("inner","NameSpace","NameSpaceTo","TableTo.fk_NameSpace = NameSpaceTo.pk")
            
            :Where("Column.pk = ^" , l_iColumnPk)
            :SQL(@l_aSQLResult)

            if :Tally == 1
                l_cColumnName          := Alltrim(l_aSQLResult[1,1])
                l_nColumnUseStatus     := l_aSQLResult[1,2]
                l_nColumnDocStatus     := l_aSQLResult[1,3]

                l_cFrom_NameSpace_Name := Alltrim(l_aSQLResult[1,4])
                l_cFrom_Table_Name     := Alltrim(l_aSQLResult[1,5])

                l_cTo_NameSpace_Name   := Alltrim(l_aSQLResult[1,6])
                l_cTo_Table_Name       := Alltrim(l_aSQLResult[1,7])

                l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]+iif(l_nColumnUseStatus>=4,"feb4b4","d2e5ff")+[;">]
                    l_cHtml += [<div class="input-group">]
                        l_cHtml += [<span class="navbar-brand ms-3">From: ]+l_cFrom_NameSpace_Name+[.]+l_cFrom_Table_Name+[</span>]
                        l_cHtml += [<span class="navbar-brand ms-3">To: ]+l_cTo_NameSpace_Name+[.]+l_cTo_Table_Name+[</span>]
                        l_cHtml += [<span class="navbar-brand ms-3">Column: ]+l_cColumnName+[</span>]
                    l_cHtml += [</div>]
                l_cHtml += [</nav>]

            endif
        endwith

    else
    endif
endif

return l_cHtml
//=================================================================================================================
function DataDictionaryVisualizeSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,par_iDiagramPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_hValues      := hb_DefaultValue(par_hValues,{=>})
local l_CheckBoxId
local l_lShowNameSpace
local l_cNameSpace_Name

local l_oDB1
local l_oData

oFcgi:TraceAdd("DataDictionaryVisualizeSettingsBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

if pcount() < 6
    if par_iDiagramPk > 0
        // Initial Build, meaning not from a failing editing
        with object l_oDB1
            //Get current Diagram Name
            :Table("cadc1049-56e3-4efa-bb61-dd9396e2c6fe","Diagram")
            :Column("Diagram.name" , "Diagram_name")
            l_oData := :Get(par_iDiagramPk)
            if :Tally == 1
                l_hValues["Name"] := l_oData:Diagram_name
            endif

            //Get the current list of selected tables
            :Table("1f5273de-4ed2-49e3-a82e-580b842025d9","DiagramTable")
            :Distinct(.t.)
            :Column("Table.pk","pk")
            :Join("inner","Table","","DiagramTable.fk_Table = Table.pk")
            :Where("DiagramTable.fk_Diagram = ^" , par_iDiagramPk)
            :SQL("ListOfCurrentTablesInDiagram")            
            if :Tally > 0
                select ListOfCurrentTablesInDiagram
                scan all
                    l_hValues["Table"+Trans(ListOfCurrentTablesInDiagram->pk)] := .t.
                endscan
            endif
        endwith
    endif
endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="Settings">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextDiagramPk" name="TextDiagramPk" value="]+trans(par_iDiagramPk)+[">]

if !empty(par_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+par_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iDiagramPk),"New Diagram","Settings")+[</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" id="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('SaveDiagram');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iDiagramPk)
            l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            l_cHtml += [<input type="button" class="btn btn-primary rounded ms-5" value="Reset" onclick="$('#ActionOnSubmit').val('ResetLayout');document.form.submit();" role="button">]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
    l_cHtml += [<td class="pe-2 pb-3">Diagram Name</td>]
    l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(hb_HGetDef(l_hValues,"Name",""))+[" maxlength="200" size="80"></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]
//List all the tables

l_lShowNameSpace := .f.

with Object l_oDB1
    :Table("ce7c29dc-9396-4fbb-9704-eb121bf139a2","Table")
    :Column("Table.pk"         ,"pk")
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.UseStatus"  ,"Table_UseStatus")
    :Column("Table.DocStatus"  ,"Table_DocStatus")
    :Column("Table.Description","Table_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Table.Name)","tag2")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfAllTablesInApplication")

    if :Tally > 0
        l_cHtml += [<div>]
            l_cHtml += [<span class="ms-3">Filter on Table Name</span><input type="text" id="TableSearch" value="" size="40" class="ms-2"><span class="ms-3"> (Press Enter)</span>]
        l_cHtml += [</div>]

        l_cHtml += [<div class="m-3"></div>]

        if :Tally > 1  //Will only display NameSpace names if there are more than 1 name space used
            select ListOfAllTablesInApplication
            l_cNameSpace_Name := ListOfAllTablesInApplication->NameSpace_Name  //Get name from first record
            locate for ListOfAllTablesInApplication->NameSpace_Name <> l_cNameSpace_Name
            l_lShowNameSpace := Found()
        endif
    endif
endwith

//Add a case insensitive contains(), icontains()
oFcgi:p_cjQueryScript += "jQuery.expr[':'].icontains = function(a, i, m) {"
oFcgi:p_cjQueryScript += "  return jQuery(a).text().toUpperCase()"
oFcgi:p_cjQueryScript += "      .indexOf(m[3].toUpperCase()) >= 0;"
oFcgi:p_cjQueryScript += "};"

oFcgi:p_cjQueryScript += [$("#TableSearch").change(function() {]
oFcgi:p_cjQueryScript += [$(".SPANTable:icontains('" + $(this).val() + "')").parent().parent().show();]
oFcgi:p_cjQueryScript += [$(".SPANTable:not(:icontains('" + $(this).val() + "'))").parent().parent().hide();]
oFcgi:p_cjQueryScript += [});]

l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [<table class="ms-5">]
select ListOfAllTablesInApplication
scan all
    l_CheckBoxId := "CheckTable"+Trans(ListOfAllTablesInApplication->pk)
    l_cHtml += [<tr><td>]
        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif( hb_HGetDef(l_hValues,"Table"+Trans(ListOfAllTablesInApplication->pk),.f.)," checked","")+[ class="form-check-input">]
        l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+["><span class="SPANTable">]+iif(l_lShowNameSpace,ListOfAllTablesInApplication->NameSpace_Name+[.],[])+ListOfAllTablesInApplication->Table_Name+[</span></label>]
    l_cHtml += [</td></tr>]
endscan
l_cHtml += [</table>]
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
//=================================================================================================================
