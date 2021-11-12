#include "DataDictionary.ch"
memvar oFcgi

//=================================================================================================================
function DataDictionaryVisualize(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []
local l_oDB1
local l_oData
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cNodePositions := ""
local l_hNodePositions := {=>}
local l_nLengthDecoded
local l_hCoordinate
local l_iNumberOfNameSpaces
local l_cNodeLabel

// See https://visjs.github.io/vis-network/examples/

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

With Object l_oDB1
    :Table("Application")
    :Column("Application.VisPos","Application_VisPos")
    l_oData := :Get(par_iApplicationPk)
    if :Tally == 1
        l_cNodePositions := l_oData:Application_VisPos
    endif
endwith

l_nLengthDecoded := hb_jsonDecode(l_cNodePositions,@l_hNodePositions)

With Object l_oDB1
    :Table("NameSpace")
    :Distinct(.t.)
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :SQL()
    l_iNumberOfNameSpaces := :Tally

    :Table("Table")
    :Column("Table.pk"         ,"pk")
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Column("Table.Name"       ,"Table_Name")
    :Column("Table.Status"     ,"Table_Status")
    :Column("Table.Description","Table_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Table.Name)","tag2")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :SQL("ListOfTables")

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

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        // l_cHtml += [<input type="button" class="btn btn-primary rounded me-3" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        // l_cHtml += [<input type="button" class="btn btn-primary rounded me-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]

        l_cHtml += [<button class="btn btn-primary rounded ms-3 me-3" onclick="]
        l_cHtml += [$.ajax({]
        l_cHtml += [  type: 'GET',]
        l_cHtml += [  url: ']+l_cSitePath+[ajax/VisualizationPositions',]
        l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&pos='+JSON.stringify(network.getPositions()),]
        l_cHtml += [  cache: false ]
        l_cHtml += [});]
        //Code used to debug the positions.
        // l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
        l_cHtml += [">Save Layout</button>]

        l_cHtml += [<button class="btn btn-primary rounded me-3" onclick="]
        l_cHtml += [$.ajax({]
        l_cHtml += [  type: 'GET',]
        l_cHtml += [  url: ']+l_cSitePath+[ajax/VisualizationPositions',]
        l_cHtml += [  data: 'apppk=]+Trans(par_iApplicationPk)+[&pos=reset',]
        l_cHtml += [  cache: false ]
        l_cHtml += [});]
        //Code used to debug the positions.
        // l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
        l_cHtml += [">Reset Layout</button>]


    l_cHtml += [</div>]
l_cHtml += [</nav>]


l_cHtml += [<div id="mynetwork"></div>]

//Code used to debug the positions.
// l_cHtml += [<div><input type="text" name="TextNodePositions" id="TextNodePositions" size="100" value=""></div>]

l_cHtml += [<script type="text/javascript">]

l_cHtml += [var network;]

l_cHtml += [function MakeVis(){]

// create an array with nodes
l_cHtml += 'var nodes = new vis.DataSet(['
select ListOfTables
scan all
    if l_iNumberOfNameSpaces == 1
        l_cNodeLabel := AllTrim(ListOfTables->Table_Name)
    else
        l_cNodeLabel := AllTrim(ListOfTables->NameSpace_Name)+"\n"+AllTrim(ListOfTables->Table_Name)
    endif
    l_cHtml += [{ id: ]+Trans(ListOfTables->pk)+[, label: "]+l_cNodeLabel+[" ]
    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,Trans(ListOfTables->pk),{=>})
        if len(l_hCoordinate) > 0
            l_cHtml += [, x: ]+Trans(l_hCoordinate["x"])+[, y: ]+Trans(l_hCoordinate["y"])
        endif
    endif
    l_cHtml += [},]
endscan
l_cHtml += ']);'

// create an array with edges
With Object l_oDB1
    :Table("Table")
    :Column("Table.pk"               ,"pkFrom")
    :Column("Column.fk_TableForeign" ,"pkTo")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :Where("Column.fk_TableForeign <> 0")
    :SQL("ListOfLinks")
endwith

l_cHtml += 'var edges = new vis.DataSet(['

select ListOfLinks
scan all
    l_cHtml += [{ from: ]+Trans(ListOfLinks->pkFrom)+[, to: ]+Trans(ListOfLinks->pkTo)+[, arrows: "from" },]  //,physics: false , smooth: { type: "cubicBezier" }
endscan

l_cHtml += ']);'

// create a network
l_cHtml += [  var container = document.getElementById("mynetwork");]
l_cHtml += [  var data = {]
l_cHtml += [    nodes: nodes,]
l_cHtml += [    edges: edges,]
l_cHtml += [  };]
l_cHtml += [  var options = {nodes: {shape: "box",margin: 12,},};]
l_cHtml += [  network = new vis.Network(container, data, options);]  //var


// l_cHtml += [network.on("stabilized", function (params) {]
// l_cHtml += [        document.getElementById("eventSpanHeading").innerText = "Stabilized!";]
// l_cHtml += [        document.getElementById("eventSpanContent").innerText = JSON.stringify(]
// l_cHtml += [          params,]
// l_cHtml += [          null,]
// l_cHtml += [          4]
// l_cHtml += [        );]
// l_cHtml += [        console.log("stabilized!", params);]
// l_cHtml += [      });]



// l_cHtml += [      network.on("startStabilizing", function (params) {]
// l_cHtml += [        document.getElementById("eventSpanHeading").innerText =]
// l_cHtml += [          "Starting Stabilization";]
// l_cHtml += [        document.getElementById("eventSpanContent").innerText = "";]
// l_cHtml += [        console.log("started");]
// l_cHtml += [      });]
// l_cHtml += [      network.on("stabilizationProgress", function (params) {]
// l_cHtml += [        document.getElementById("eventSpanHeading").innerText =]
// l_cHtml += [          "Stabilization progress";]
// l_cHtml += [        document.getElementById("eventSpanContent").innerText = JSON.stringify(]
// l_cHtml += [          params,]
// l_cHtml += [          null,]
// l_cHtml += [          4]
// l_cHtml += [        );]
// l_cHtml += [        console.log("progress:", params);]
// l_cHtml += [      });]
// l_cHtml += [      network.on("stabilizationIterationsDone", function (params) {]
// l_cHtml += [        document.getElementById("eventSpanHeading").innerText =]
// l_cHtml += [          "Stabilization iterations complete";]
// l_cHtml += [        document.getElementById("eventSpanContent").innerText = "";]
// l_cHtml += [        console.log("finished stabilization interations");]
// l_cHtml += [      });]
// l_cHtml += [      network.on("stabilized", function (params) {]
// l_cHtml += [        document.getElementById("eventSpanHeading").innerText = "Stabilized!";]
// l_cHtml += [        document.getElementById("eventSpanContent").innerText = JSON.stringify(]
// l_cHtml += [          params,]
// l_cHtml += [          null,]
// l_cHtml += [          4]
// l_cHtml += [        );]
// l_cHtml += [        console.log("stabilized!", params);]
// l_cHtml += [      });]

// l_cHtml += [      network.stabilize({"iterations": 1});]

l_cHtml += [};]

l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [MakeVis();]

return l_cHtml

//=================================================================================================================
function SaveVisualizationPositions()

local l_iApplicationPk := val(oFcgi:GetQueryString("apppk"))
local l_cNodePositions := Strtran(oFcgi:GetQueryString("pos"),[%22],["])

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

With Object l_oDB1
    :Table("Application")
    :Field("VisPos",l_cNodePositions)
    :Update(l_iApplicationPk)
endwith

//SendToClipboard(oFcgi:GetQueryString("pos"))
// SendToDebugView("Called SaveVisualizationPositions "+l_cNodePositions)

return ""
//=================================================================================================================
