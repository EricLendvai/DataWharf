#include "DataWharf.ch"
memvar oFcgi

//=================================================================================================================
function ModelingVisualizeDiagramBuild(par_oDataHeader,par_cErrorText,par_iModelingDiagramPk)
local l_cHtml := []
local l_oDB1
local l_oDB_Project                          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntities                   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelingDiagrams           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAssociationNodes           := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEdgesEntityAssociationNode := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEdgesEntityEntity          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cNodePositions
local l_hNodePositions := {=>}
local l_nLengthDecoded
local l_lAutoLayout := .t.
local l_hCoordinate
local l_cNodeLabel
local l_nNumberOfEntityInModelingDiagram
local l_oDataModelingDiagram
local l_lNodeShowDescription
local l_lAssociationShowName    := .t.
local l_lAssociationEndShowName := .t.
local l_nNodeMinHeight
local l_nNodeMaxWidth
local l_cEntityDescription
local l_cAssociationDescription
local l_cDiagramInfoScale
local l_nDiagramInfoScale
local l_iModelingDiagramPk
local l_cPackage_FullName
local l_lShowPackage

local l_cLabelLower
local l_cLabelUpper

local l_iCanvasWidth                 := val(GetUserSetting("CanvasWidth"))
local l_iCanvasHeight                := val(GetUserSetting("CanvasHeight"))
local l_lNavigationControl           := (GetUserSetting("NavigationControl") == "T")
local l_lNeverShowDescriptionOnHover := (GetUserSetting("NeverShowDescriptionOnHover") == "T")
local l_cModelingDiagram_LinkUID
local l_cURL
local l_cProtocol
local l_nPort

local l_iAssociationPk_Previous
local l_iEntityPk_Previous
local l_iEntityPk_Current
local l_cEndpointBoundLower_Previous
local l_cEndpointBoundUpper_Previous
local l_lEndpointIsContainment_Previous
local l_cEndpointName_Previous
local l_cEndpointDescription_Previous

local l_cLabel
local l_cDescription

local l_lGraphLib := "mxgraph"
local l_cJS

local l_hMultiEdgeCounters := {=>}
local l_cMultiEdgeKeyPrevious
local l_cMultiEdgeKey
local l_nMultiEdgeTotalCount
local l_nMultiEdgeCount

oFcgi:TraceAdd("ModelingVisualizeDiagramBuild")

//See https://github.com/markedjs/marked for the JS library  _M_ Make this generic to be used in other places
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/marked_2022_02_23_001/marked.min.js"></script>]

l_cHtml += [<script type="text/javascript">]
l_cHtml += 'function KeywordSearch(par_cListOfWords, par_cString) {'
l_cHtml += '  const l_aWords_upper = par_cListOfWords.toUpperCase().split(" ").filter(Boolean);'
l_cHtml += '  const l_cString_upper = par_cString.toUpperCase();'
l_cHtml += '  var l_lAllWordsIncluded = true;'
l_cHtml += '  for (var i = 0; i < l_aWords_upper.length; i++) {'
l_cHtml += '    if (!l_cString_upper.includes(l_aWords_upper[i])) {l_lAllWordsIncluded = false;break;};'
l_cHtml += '  }'
l_cHtml += '  return l_lAllWordsIncluded;'
l_cHtml += '}'
l_cHtml += [</script>]

// See https://visjs.github.io/vis-network/examples/

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfModelingDiagrams
    :Table("457beda4-3ff9-4c01-87f9-2a9bb37cf32f","ModelingDiagram")
    :Column("ModelingDiagram.pk"         ,"ModelingDiagram_pk")
    :Column("ModelingDiagram.Name"       ,"ModelingDiagram_Name")
    :Column("Upper(ModelingDiagram.Name)","Tag1")
    :Where("ModelingDiagram.fk_Model = ^" ,par_oDataHeader:Model_pk)
    :OrderBy("Tag1")
    :SQL("ListOfModelingDiagrams")
endwith

with object l_oDB1
    if empty(par_iModelingDiagramPk)
        l_iModelingDiagramPk := ListOfModelingDiagrams->ModelingDiagram_pk
    else
        l_iModelingDiagramPk := par_iModelingDiagramPk
    endif

    :Table("5b855361-eb92-45cd-b4e0-ca6b6bea5dd2"   ,"ModelingDiagram")
    :Column("ModelingDiagram.VisPos"                ,"ModelingDiagram_VisPos")
    :Column("ModelingDiagram.NodeShowDescription"   ,"ModelingDiagram_NodeShowDescription")
    :Column("ModelingDiagram.AssociationShowName"   ,"ModelingDiagram_AssociationShowName")
    :Column("ModelingDiagram.AssociationEndShowName","ModelingDiagram_AssociationEndShowName")
    :Column("ModelingDiagram.NodeMinHeight"         ,"ModelingDiagram_NodeMinHeight")
    :Column("ModelingDiagram.NodeMaxWidth"          ,"ModelingDiagram_NodeMaxWidth")
    :Column("ModelingDiagram.LinkUID"               ,"ModelingDiagram_LinkUID")
    l_oDataModelingDiagram     := :Get(l_iModelingDiagramPk)
    l_cNodePositions           := l_oDataModelingDiagram:ModelingDiagram_VisPos
    l_lNodeShowDescription     := l_oDataModelingDiagram:ModelingDiagram_NodeShowDescription
    l_lAssociationShowName     := l_oDataModelingDiagram:ModelingDiagram_AssociationShowName
    l_lAssociationEndShowName  := l_oDataModelingDiagram:ModelingDiagram_AssociationEndShowName
    l_nNodeMinHeight           := l_oDataModelingDiagram:ModelingDiagram_NodeMinHeight
    l_nNodeMaxWidth            := l_oDataModelingDiagram:ModelingDiagram_NodeMaxWidth
    l_cModelingDiagram_LinkUID := l_oDataModelingDiagram:ModelingDiagram_LinkUID
endwith

with object l_oDB_ListOfEntities
    //Check if there is at least one record in DiagramEntity for the current Diagram
    :Table("d9e7a7d3-5f13-4668-be0c-b1d1efb0a66b","DiagramEntity")
    :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
    l_nNumberOfEntityInModelingDiagram := :Count()
    
    if l_nNumberOfEntityInModelingDiagram == 0
        // All Entities in Model
        :Table("32f4e1f2-7c22-4378-bd3c-422076f50633","Entity")
        :Column("Entity.pk"         ,"pk")
        :Column("Package.FullName"  ,"Package_FullName")
        :Column("Entity.Name"       ,"Entity_Name")
        :Column("Entity.Description","Entity_Description")
        :Join("left","Package","","Entity.fk_Package = Package.pk")
        :Where("Entity.fk_Model = ^",par_oDataHeader:Model_pk)
        :SQL("ListOfEntities")

    else
        // A subset of Entities
        :Table("775cb6a5-9c03-4a24-8461-de3cb7f9a539","DiagramEntity")
        :Distinct(.t.)
        :Column("Entity.pk"         ,"pk")
        :Column("Package.FullName"  ,"Package_FullName")
        :Column("Entity.Name"       ,"Entity_Name")
        :Column("Entity.Description","Entity_Description")
        :Join("inner","Entity"   ,"","DiagramEntity.fk_Entity = Entity.pk")
        :Join("left","Package","","Entity.fk_Package = Package.pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
        :SQL("ListOfEntities")

    endif

    select ListOfEntities
    l_cPackage_FullName := nvl(ListOfEntities->Package_FullName," ")
    locate for nvl(ListOfEntities->Package_FullName," ") <> l_cPackage_FullName
    l_lShowPackage := Found()

endwith

with object l_oDB_ListOfAssociationNodes
    if l_nNumberOfEntityInModelingDiagram == 0
        // All Entities in Model
        :Table("f1ba32fa-1576-47e8-8ca1-fe7dfceeec33","Entity")
        :Distinct(.t.)
        :Column("Association.pk"         ,"pk")
        :Column("Package.FullName"       ,"Package_FullName")
        :Column("Association.Name"       ,"Association_Name")
        :Column("Association.Description","Association_Description")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Join("left","Package","","Association.fk_Package = Package.pk")
        :Where("Entity.fk_Model = ^",par_oDataHeader:Model_pk)
        :Where("Association.NumberOfEndpoints > 2")
        :SQL("ListOfAssociationNodes")

    else
        // A subset of Entities
        :Table("fcf7d57f-2285-4e8c-8006-92981c60899a","DiagramEntity")
        :Distinct(.t.)
        :Column("Association.pk"         ,"pk")
        :Column("Package.FullName"       ,"Package_FullName")
        :Column("Association.Name"       ,"Association_Name")
        :Column("Association.Description","Association_Description")
        :Join("inner","Entity"   ,"","DiagramEntity.fk_Entity = Entity.pk")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Join("left","Package","","Association.fk_Package = Package.pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
        :Where("Association.NumberOfEndpoints > 2")
        :SQL("ListOfAssociationNodes")

    endif

    if !l_lShowPackage
        select ListOfAssociationNodes
        l_cPackage_FullName := nvl(ListOfAssociationNodes->Package_FullName," ")
        locate for nvl(ListOfAssociationNodes->Package_FullName," ") <> l_cPackage_FullName
        l_lShowPackage := Found()
    endif

endwith

with object l_oDB_ListOfEdgesEntityAssociationNode
    if l_nNumberOfEntityInModelingDiagram == 0
        // All Entities in Model
        :Table("a039013f-1bb2-42f0-9c42-4c33b3dd667a","Entity")
        :Distinct(.t.)
        :Column("Entity.pk"           ,"Entity_pk")
        :Column("Association.pk"      ,"Association_pk")
        :Column("Endpoint.pk"         ,"Endpoint_pk")
        :Column("Endpoint.Name"       ,"Endpoint_Name")
        :Column("Endpoint.BoundLower" ,"Endpoint_BoundLower")
        :Column("Endpoint.BoundUpper" ,"Endpoint_BoundUpper")
        :Column("Endpoint.IsContainment"   ,"Endpoint_IsContainment")
        :Column("Endpoint.Description","Endpoint_Description")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Where("Entity.fk_Model = ^",par_oDataHeader:Model_pk)
        :Where("Association.NumberOfEndpoints > 2")
        :OrderBy("Association_pk")
        :OrderBy("Endpoint_pk")
        :SQL("ListOfEdgesEntityAssociationNode")

    else
        // A subset of Entities
        :Table("4143b79d-a42b-4270-a69d-e2efce746c2a","DiagramEntity")
        :Distinct(.t.)
        :Column("Entity.pk"           ,"Entity_pk")
        :Column("Association.pk"      ,"Association_pk")
        :Column("Endpoint.pk"         ,"Endpoint_pk")
        :Column("Endpoint.Name"       ,"Endpoint_Name")
        :Column("Endpoint.BoundLower" ,"Endpoint_BoundLower")
        :Column("Endpoint.BoundUpper" ,"Endpoint_BoundUpper")
        :Column("Endpoint.IsContainment"   ,"Endpoint_IsContainment")
        :Column("Endpoint.Description","Endpoint_Description")
        :Join("inner","Entity"   ,"","DiagramEntity.fk_Entity = Entity.pk")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
        :Where("Association.NumberOfEndpoints > 2")
        :OrderBy("Association_pk")
        :OrderBy("Endpoint_pk")
        :SQL("ListOfEdgesEntityAssociationNode")

    endif
endwith

with object l_oDB_ListOfEdgesEntityEntity
    if l_nNumberOfEntityInModelingDiagram == 0
        // All Entities in Model
        :Table("4a726d29-46b4-45e1-9277-a2faee907608","Association")
        :Column("Association.pk"         ,"Association_pk")
        :Column("Association.Name"       ,"Association_Name")
        :Column("Association.Description","Association_Description")
        :Column("Endpoint.pk"            ,"Endpoint_pk")
        :Column("Endpoint.Name"          ,"Endpoint_Name")
        :Column("Endpoint.Description"   ,"Endpoint_Description")
        :Column("Endpoint.BoundLower"    ,"Endpoint_BoundLower")
        :Column("Endpoint.BoundUpper"    ,"Endpoint_BoundUpper")
        :Column("Endpoint.IsContainment"      ,"Endpoint_IsContainment")
        :Column("Entity.pk"              ,"Entity_pk")
        :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
        :Join("inner","Entity"  ,"","Endpoint.fk_Entity = Entity.pk")
        :Where("Association.fk_Model = ^",par_oDataHeader:Model_pk)
        :Where("Association.NumberOfEndpoints = 2")
        :OrderBy("Association_pk")
        :OrderBy("Endpoint_pk")
        :SQL("ListOfEdgesEntityEntity")
        //Pairs of records should be created

 //ExportTableToHtmlFile("ListOfEdgesEntityEntity","d:\PostgreSQL_ListOfEdgesEntityEntity.html","From PostgreSQL",,25,.t.)

    else
        // A subset of Entities
        :Table("1be77b22-bda4-4138-bce0-88ae38bd76c4","DiagramEntity")
        :Distinct(.t.)
        :Column("Association.pk"         ,"Association_pk")
        :Column("Association.Name"       ,"Association_Name")
        :Column("Association.Description","Association_Description")
        :Column("Endpoint.pk"            ,"Endpoint_pk")
        :Column("Endpoint.Name"          ,"Endpoint_Name")
        :Column("Endpoint.Description"   ,"Endpoint_Description")
        :Column("Endpoint.BoundLower"    ,"Endpoint_BoundLower")
        :Column("Endpoint.BoundUpper"    ,"Endpoint_BoundUpper")
        :Column("Endpoint.IsContainment" ,"Endpoint_IsContainment")
        :Column("Entity.pk"              ,"Entity_pk")
        :Join("inner","Entity"     ,"","DiagramEntity.fk_Entity = Entity.pk")
        :Join("inner","Endpoint"   ,"","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^",l_iModelingDiagramPk)
        :Where("Association.NumberOfEndpoints = 2")
        :OrderBy("Association_pk")
        :OrderBy("Endpoint_pk")
        :SQL("ListOfEdgesEntityEntity")
        //It is possible that some non pairs are created.

    endif
endwith

// l_cHtml += '<script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>'

if l_iCanvasWidth < CANVAS_WIDTH_MIN .or. l_iCanvasWidth > CANVAS_WIDTH_MAX
    l_iCanvasWidth := CANVAS_WIDTH_DEFAULT
endif

if l_iCanvasHeight < CANVAS_HEIGHT_MIN .or. l_iCanvasHeight > CANVAS_HEIGHT_MAX
    l_iCanvasHeight := CANVAS_HEIGHT_DEFAULT
endif

oFcgi:p_cHeader += [<script language="javascript" type="text/javascript">mxBasePath = ']+l_cSitePath+[scripts/mxgraph'; mxLoadStylesheets = false; </script>]//not loading style sheets as it will load from wrong path
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/mxgraph/css/common.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/mxgraph/mxClient.js"></script>]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/visualization.js"></script>]

// oFcgi:p_cHeader += [<script type="text/javascript">]
// oFcgi:p_cHeader += 'function htmlTitle(html) {'
// oFcgi:p_cHeader += '    const container = document.createElement("div");'
// oFcgi:p_cHeader += '    container.innerHTML = html;'
// oFcgi:p_cHeader += '    return container;'
// oFcgi:p_cHeader += '}'
// oFcgi:p_cHeader += [</script>]

l_cHtml += [<style type="text/css">]
l_cHtml += [  #mynetwork {]
l_cHtml += [    width: ]+Trans(l_iCanvasWidth)+[px;]
l_cHtml += [    height: ]+Trans(l_iCanvasHeight)+[px;]
l_cHtml += [    border: 1px solid lightgray;]
l_cHtml += [  }]
l_cHtml += [</style>]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Design">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextNodePositions" name="TextNodePositions" value="">]
l_cHtml += [<input type="hidden" id="TextModelingDiagramPk" name="TextModelingDiagramPk" value="]+Trans(l_iModelingDiagramPk)+[">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        //---------------------------------------------------------------------------
        if oFcgi:p_nAccessLevelML >= 4
            l_cHtml += [<input type="button" role="button" value="Save Layout" id="ButtonSaveLayout" class="btn btn-primary rounded ms-3" onclick="]

            //l_cHtml += [network.storePositions();]

            l_cHtml += [$('#TextNodePositions').val( JSON.stringify(getPositions(network)) );]
            l_cHtml += [$('#ActionOnSubmit').val('SaveLayout');document.form.submit();]

            //Code used to debug the positions.
            l_cHtml += [">]
        endif
        //---------------------------------------------------------------------------
        //---------------------------------------------------------------------------
        if oFcgi:p_nAccessLevelML >= 4
             l_cHtml += [<input type="button" role="button" value="Diagram Settings" class="btn btn-primary rounded ms-3" onclick="$('#ActionOnSubmit').val('DiagramSettings');document.form.submit();">]
        endif
        //---------------------------------------------------------------------------
         l_cHtml += [<select id="ComboModelingDiagramPk" name="ComboModelingDiagramPk" onchange="$('#TextModelingDiagramPk').val(this.value);$('#ActionOnSubmit').val('Show');document.form.submit();" class="ms-3">]

            select ListOfModelingDiagrams
            scan all
                l_cHtml += [<option value="]+Trans(ListOfModelingDiagrams->ModelingDiagram_pk)+["]+iif(ListOfModelingDiagrams->ModelingDiagram_Pk == l_iModelingDiagramPk,[ selected],[])+[>]+ListOfModelingDiagrams->ModelingDiagram_Name+[</option>]
            endscan
         l_cHtml += [</select>]
        //---------------------------------------------------------------------------
        if oFcgi:p_nAccessLevelML >= 4
             l_cHtml += [<input type="button" role="button" value="New Diagram" class="btn btn-primary rounded ms-3" onclick="$('#ActionOnSubmit').val('NewDiagram');document.form.submit();">]
        endif
        //---------------------------------------------------------------------------
         l_cHtml += [<input type="button" role="button" value="My Settings" class="btn btn-primary rounded ms-3" onclick="$('#ActionOnSubmit').val('MyDiagramSettings');document.form.submit();">]
        //---------------------------------------------------------------------------
        if !l_lNavigationControl
            l_cHtml += [<input type="button" role="button" value="Fit Diagram" class="btn btn-primary rounded ms-3" onclick="network.fit();return false;">]
        endif
        //---------------------------------------------------------------------------

        //Get the current URL and add a reference to the current modeling diagram LinkUID
        l_cProtocol := oFcgi:RequestSettings["Protocol"]
        l_nPort     := oFcgi:RequestSettings["Port"]
        l_cURL := l_cProtocol+"://"+oFcgi:RequestSettings["Host"]
        if !((l_cProtocol == "http" .and. l_nPort == 80) .or. (l_cProtocol == "https" .and. l_nPort == 443))
            l_cURL += ":"+Trans(l_nPort)
        endif
        l_cURL += oFcgi:RequestSettings["SitePath"]
        // l_cURL += [Modeling/Visualize/]+par_cModelLinkUID+[/]
        l_cURL += oFcgi:RequestSettings["Path"]
        l_cURL += [?InitialDiagram=]+l_cModelingDiagram_LinkUID

        l_cHtml += [<input type="button" role="button" value="Copy Diagram Link To Clipboard" class="btn btn-primary rounded ms-3" id="CopyLink" onclick="]
        
        l_cHtml += [navigator.clipboard.writeText(']+l_cURL+[').then(function() {]
        l_cHtml += [$('#CopyLink').addClass('btn-success').removeClass('btn-primary');]
        l_cHtml += [}, function() {]
        l_cHtml += [$('#CopyLink').addClass('btn-danger').removeClass('btn-primary');]
        l_cHtml += [});]

        l_cHtml += [;return false;">]
        //---------------------------------------------------------------------------

    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_nLengthDecoded := hb_jsonDecode(l_cNodePositions,@l_hNodePositions)

l_cHtml += [<table><tr>]
//-------------------------------------
l_cHtml += [<td valign="top">]
l_cHtml += [<div id="mynetwork" style="overflow:scroll"></div>]
l_cHtml += [</td>]
//-------------------------------------

l_cDiagramInfoScale := GetUserSetting("DiagramInfoScale")
if empty(l_cDiagramInfoScale)
    l_nDiagramInfoScale := 1
else
    l_nDiagramInfoScale := val(l_cDiagramInfoScale)
    if l_nDiagramInfoScale < 0.4 .or. l_nDiagramInfoScale > 1.0
        l_nDiagramInfoScale := 1
    endif
endif

l_cHtml += [<td valign="top">]  // width="100%"
if l_nDiagramInfoScale == 1
    l_cHtml += [<div id="GraphInfo"></div>]
else
    l_cHtml += [<div id="GraphInfo" style="transform: scale(]+Trans(l_nDiagramInfoScale)+[);transform-origin: 0 0;"></div>]
endif
l_cHtml += [</td>]
//-------------------------------------
l_cHtml += [</tr></table>]

l_cHtml += [</form>]

l_cHtml += [<script type="text/javascript">]

l_cHtml += [var network;]

l_cHtml += [function MakeVis(){]

// create an array with nodes
l_cHtml += 'var nodes = ['
select ListOfEntities
scan all
    l_cNodeLabel := '<b>'+AllTrim(ListOfEntities->Entity_Name)+'</b>'
    if l_lShowPackage .and. len(nvl(ListOfEntities->Package_FullName,"")) > 0
        l_cNodeLabel += [\n (]+ListOfEntities->Package_FullName+[)]
    endif

    l_cEntityDescription := EscapeNewlineAndQuotes(ListOfEntities->Entity_Description)
    
    l_cHtml += [{id:"E]+Trans(ListOfEntities->pk)+["]
    
    if empty(l_cEntityDescription)
        l_cHtml += [,font:{multi:"html"}]
        l_cHtml += [,label:"]+l_cNodeLabel+["]
    else
        if l_lNodeShowDescription
            l_cHtml += [,font:{multi:"html",align:"left"}]
            l_cHtml += [,label:"]+l_cNodeLabel+[\n]+l_cEntityDescription+["]
        else
            l_cHtml += [,font:{multi:"html"}]
            l_cHtml += [,label:"]+l_cNodeLabel+["]
            if !l_lNeverShowDescriptionOnHover
                l_cHtml += [,title:"]+l_cEntityDescription+["]
            endif
        endif
    endif

    l_cHtml += [,color:{background:'#]+MODELING_ENTITY_NODE_BACKGROUND+[',highlight:{background:'#]+MODELING_ENTITY_NODE_HIGHLIGHT+[',border:'#]+SELECTED_NODE_BORDER+['}}]

    if l_nNodeMaxWidth > 50
        l_cHtml += [,widthConstraint: {maximum: ]+Trans(l_nNodeMaxWidth)+[}]
    endif
    if l_nNodeMinHeight > 20
        l_cHtml += [,heightConstraint: {minimum: ]+Trans(l_nNodeMinHeight)+[}]
    endif

    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,"E"+Trans(ListOfEntities->pk),{=>})
        if len(l_hCoordinate) > 0
            l_lAutoLayout := .f.
            l_cHtml += [,x:]+Trans(l_hCoordinate["x"])+[,y:]+Trans(l_hCoordinate["y"])
            if hb_HHasKey(l_hCoordinate, "height")
                l_cHtml += [,height:]+Trans(l_hCoordinate["height"])
            endif
            if hb_HHasKey(l_hCoordinate, "width")
                l_cHtml += [,width:]+Trans(l_hCoordinate["width"])
            endif
        endif
    endif

    if oFcgi:p_nAccessLevelML < 4
        l_cHtml += [,fixed: {x:true,y:true}]
    endif

    l_cHtml += [},]
endscan


//All Nodes for all Association with more than 2 Entity
select ListOfAssociationNodes
scan all
    l_cNodeLabel := AllTrim(ListOfAssociationNodes->Association_Name)
    if l_lShowPackage .and. len(nvl(ListOfAssociationNodes->Package_FullName,"")) > 0
        l_cNodeLabel += [\n (]+ListOfAssociationNodes->Package_FullName+[)]
    endif

    // if hb_orm_isnull("ListOfAssociationNodes","Association_Description")
    //     l_cAssociationDescription := ""
    // else
    //     l_cAssociationDescription := hb_StrReplace(ListOfAssociationNodes->Association_Description,{[&]     => [&#38;],;
    //                                                                                                 [\]     => [&#92;],;
    //                                                                                                 chr(10) => [],;
    //                                                                                                 chr(13) => [\n],;
    //                                                                                                 ["]     => [&#34;],;
    //                                                                                                 [']     => [&#39;]} )
    // endif
    
    l_cAssociationDescription := EscapeNewlineAndQuotes(ListOfAssociationNodes->Association_Description)

    //Due to some bugs in the js library, had to setup font before the label.
    l_cHtml += [{id:"A]+Trans(ListOfAssociationNodes->pk)+["]
    l_cHtml += [,font:{multi:"html"}]
    if empty(l_cAssociationDescription)
        l_cHtml += [,label:"]+l_cNodeLabel+["]
    else
        if l_lNodeShowDescription
            l_cHtml += [,label:"]+l_cNodeLabel+[\n]+l_cAssociationDescription+["]
        else
            l_cHtml += [,label:"]+l_cNodeLabel+["]
            if !l_lNeverShowDescriptionOnHover
               l_cHtml += [,title:"]+l_cAssociationDescription+["]
                // l_cHtml += [,title:htmlTitle(marked.parse("]+l_cAssociationDescription+["))]
            endif
        endif
    endif

    l_cHtml += [,shape: "rhombus",color:{background:'#]+MODELING_ASSOCIATION_NODE_BACKGROUND+[',highlight:{background:'#]+MODELING_ASSOCIATION_NODE_HIGHLIGHT+[',border:'#]+SELECTED_NODE_BORDER+['}}]

    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,"A"+Trans(ListOfAssociationNodes->pk),{=>})
        if len(l_hCoordinate) > 0
            l_cHtml += [,x:]+Trans(l_hCoordinate["x"])+[,y:]+Trans(l_hCoordinate["y"])
        endif
    endif

    if oFcgi:p_nAccessLevelML < 4
        l_cHtml += [,fixed: {x:true,y:true}]
    endif

    l_cHtml += [},]
endscan

l_cHtml += '];'

// SendToClipboard(l_cHtml)

// create an array with edges

l_cHtml += 'var edges = ['

// Edges between Association Nodes and Entities

l_cMultiEdgeKeyPrevious   := ""

//Pre-Determine multi-links
select ListOfEdgesEntityAssociationNode
scan all
    l_cMultiEdgeKey := Trans(ListOfEdgesEntityAssociationNode->Association_pk)+"-"+Trans(ListOfEdgesEntityAssociationNode->Entity_pk)
    l_hMultiEdgeCounters[l_cMultiEdgeKey] := hb_HGetDef(l_hMultiEdgeCounters,l_cMultiEdgeKey,0) + 1
endscan

select ListOfEdgesEntityAssociationNode
scan all
    l_cHtml += [{id:"L]+Trans(ListOfEdgesEntityAssociationNode->Endpoint_pk)+[",from:"A]+Trans(ListOfEdgesEntityAssociationNode->Association_pk)+[",to:"E]+Trans(ListOfEdgesEntityAssociationNode->Entity_pk)+["]  // ,arrows:"middle"
    
    l_cHtml += [,color:{color:'#]+MODELING_EDGE_BACKGROUND+[',highlight:'#]+MODELING_EDGE_HIGHLIGHT+['}]
    
    // l_cHtml += [, smooth: { type: "diagonalCross" }]
    l_cLabel := nvl(ListOfEdgesEntityAssociationNode->Endpoint_Name,"")
    if !empty(l_cLabel) .and. l_lAssociationEndShowName
        l_cHtml += [,label:"]+EscapeNewlineAndQuotes(l_cLabel)+["]
    endif

    l_cLabelLower := nvl(ListOfEdgesEntityAssociationNode->Endpoint_BoundLower,"")
    l_cLabelUpper := nvl(ListOfEdgesEntityAssociationNode->Endpoint_BoundUpper,"")
    if !empty(l_cLabelLower) .and. !empty(l_cLabelUpper)
        l_cHtml += [,labelTo:"]+EscapeNewlineAndQuotes(chr(13)+l_cLabelLower+".."+l_cLabelUpper)+["]
    endif

    if !l_lNeverShowDescriptionOnHover
        l_cDescription := nvl(ListOfEdgesEntityAssociationNode->Endpoint_Description,"")
        if !empty(l_cDescription)
            l_cHtml += [,title:"]+EscapeNewlineAndQuotes(l_cDescription)+["]
        endif
    endif

    if ListOfEdgesEntityAssociationNode->Endpoint_IsContainment
        l_cHtml += [,arrows:{to:{enabled: true,type:"diamond"}}]
    endif

    // l_cHtml += [,arrows:{from:{enabled: true,type:"circle"}}]
    // l_cHtml += [,arrows:{from:{enabled: true,type:"image",src: "https://visjs.org/images/visjs_logo.png"}}]
    // https://harbour.wiki/images/harbour.svg

    l_cMultiEdgeKey := Trans(ListOfEdgesEntityAssociationNode->Association_pk)+"-"+Trans(ListOfEdgesEntityAssociationNode->Entity_pk)
    l_nMultiEdgeTotalCount := l_hMultiEdgeCounters[l_cMultiEdgeKey]
    if l_nMultiEdgeTotalCount > 1
        if l_cMultiEdgeKey == l_cMultiEdgeKeyPrevious
            l_nMultiEdgeCount += 1
        else
            l_nMultiEdgeCount := 1
            l_cMultiEdgeKeyPrevious := l_cMultiEdgeKey
        endif
        l_cHtml += GetMultiEdgeCurvatureJSon(l_nMultiEdgeTotalCount,l_nMultiEdgeCount)
    endif

    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,"L"+Trans(ListOfEdgesEntityAssociationNode->Endpoint_pk),{=>})
        if len(l_hCoordinate) > 0
            l_lAutoLayout := .f.
            l_cHtml += [,points:]+hb_jsonEncode(l_hCoordinate["points"])
        endif
    endif

    l_cHtml += [},]  //,physics: false , smooth: { type: "cubicBezier" }
endscan


// Edges between Two Entities

hb_HClear(l_hMultiEdgeCounters)
l_iAssociationPk_Previous := 0
l_iEntityPk_Previous      := 0
l_iEntityPk_Current       := 0
l_cMultiEdgeKeyPrevious   := ""

//Pre-Determine multi-links
select ListOfEdgesEntityEntity
scan all
    if ListOfEdgesEntityEntity->Association_pk == l_iAssociationPk_Previous
        l_iEntityPk_Current := ListOfEdgesEntityEntity->Entity_pk
        l_cMultiEdgeKey := Trans(l_iEntityPk_Current)+"-"+Trans(l_iEntityPk_Previous)
        l_hMultiEdgeCounters[l_cMultiEdgeKey] := hb_HGetDef(l_hMultiEdgeCounters,l_cMultiEdgeKey,0) + 1
    else
        l_iAssociationPk_Previous       := ListOfEdgesEntityEntity->Association_pk
        l_iEntityPk_Previous            := ListOfEdgesEntityEntity->Entity_pk
    endif
endscan

select ListOfEdgesEntityEntity
//Pairs of records should have been created
l_iAssociationPk_Previous         := 0
l_iEntityPk_Previous              := 0
l_iEntityPk_Current               := 0
l_cEndpointBoundLower_Previous    := ""
l_cEndpointBoundUpper_Previous    := ""
l_lEndpointIsContainment_Previous := .f.
l_cEndpointName_Previous          := ""
l_cEndpointDescription_Previous   := ""
// Altd()
scan all
    if ListOfEdgesEntityEntity->Association_pk == l_iAssociationPk_Previous
        //Build the edge between 2 entities
        l_iEntityPk_Current := ListOfEdgesEntityEntity->Entity_pk

        l_cHtml += [{id:"D]+Trans(l_iAssociationPk_Previous)+[",from:"E]+Trans(l_iEntityPk_Previous)+[",to:"E]+Trans(l_iEntityPk_Current )+["]
        l_cHtml += [,color:{color:'#]+MODELING_EDGE_BACKGROUND+[',highlight:'#]+MODELING_EDGE_HIGHLIGHT+['}]
        if l_lAssociationShowName
            l_cHtml += [,label:"]+ListOfEdgesEntityEntity->Association_Name+["]
        endif

        l_cLabel      := nvl(ListOfEdgesEntityEntity->Endpoint_Name,"")
        l_cLabelLower := nvl(ListOfEdgesEntityEntity->Endpoint_BoundLower,"")
        l_cLabelUpper := nvl(ListOfEdgesEntityEntity->Endpoint_BoundUpper,"")
        if (!empty(l_cLabelLower) .and. !empty(l_cLabelUpper))
            if !empty(l_cLabel) .and. l_lAssociationEndShowName
                l_cLabel += chr(13)
            else
                l_cLabel := ""
            endif
            l_cLabel += l_cLabelLower+".."+l_cLabelUpper
        endif
        if !empty(l_cLabel)
            l_cHtml += [,labelTo:"]+EscapeNewlineAndQuotes(l_cLabel)+["]
        endif

        l_cLabel      := nvl(l_cEndpointName_Previous,"")
        l_cLabelLower := nvl(l_cEndpointBoundLower_Previous,"")
        l_cLabelUpper := nvl(l_cEndpointBoundUpper_Previous,"")
        if (!empty(l_cLabelLower) .and. !empty(l_cLabelUpper))
            if !empty(l_cLabel) .and. l_lAssociationEndShowName
                l_cLabel += chr(13)
            else
                l_cLabel := ""
            endif
            l_cLabel += l_cLabelLower+".."+l_cLabelUpper
        endif
        if !empty(l_cLabel)
            l_cHtml += [,labelFrom:"]+EscapeNewlineAndQuotes(l_cLabel)+["]
        endif

        if !l_lNeverShowDescriptionOnHover
            l_cDescription := nvl(ListOfEdgesEntityEntity->Association_Description,"")

            if !empty(nvl(ListOfEdgesEntityEntity->Endpoint_Description,""))
                if !empty(l_cDescription)
                    l_cDescription += chr(13)+chr(13)
                endif
                l_cDescription += ListOfEdgesEntityEntity->Endpoint_Description
            endif

            if !empty(nvl(l_cEndpointDescription_Previous,""))
                if !empty(l_cDescription)
                    l_cDescription += chr(13)+chr(13)
                endif
                l_cDescription += l_cEndpointDescription_Previous
            endif

            if !empty(l_cDescription)
                l_cHtml += [,title:"]+EscapeNewlineAndQuotes(l_cDescription)+["]
            endif
        endif

        do case
        case !l_lEndpointIsContainment_Previous .and. !ListOfEdgesEntityEntity->Endpoint_IsContainment
        case  l_lEndpointIsContainment_Previous .and.  ListOfEdgesEntityEntity->Endpoint_IsContainment
            l_cHtml += [,arrows:{from:{enabled: true,type:"diamond"},to:{enabled: true,type:"diamond"}}]
        case !l_lEndpointIsContainment_Previous .and.  ListOfEdgesEntityEntity->Endpoint_IsContainment
            l_cHtml += [,arrows:{to:{enabled: true,type:"diamond"}}]
        case  l_lEndpointIsContainment_Previous .and. !ListOfEdgesEntityEntity->Endpoint_IsContainment
            l_cHtml += [,arrows:{from:{enabled: true,type:"diamond"}}]
        endcase

        l_cMultiEdgeKey := Trans(l_iEntityPk_Current)+"-"+Trans(l_iEntityPk_Previous)
        l_nMultiEdgeTotalCount := l_hMultiEdgeCounters[l_cMultiEdgeKey]
        if l_nMultiEdgeTotalCount > 1
            if l_cMultiEdgeKey == l_cMultiEdgeKeyPrevious
                l_nMultiEdgeCount += 1
            else
                l_nMultiEdgeCount := 1
                l_cMultiEdgeKeyPrevious := l_cMultiEdgeKey
            endif
            l_cHtml += GetMultiEdgeCurvatureJSon(l_nMultiEdgeTotalCount,l_nMultiEdgeCount)
        endif

        if l_nLengthDecoded > 0
            l_hCoordinate := hb_HGetDef(l_hNodePositions,"D"+Trans(ListOfEdgesEntityEntity->Association_pk),{=>})
            if len(l_hCoordinate) > 0
                l_lAutoLayout := .f.
                l_cHtml += [,points:]+hb_jsonEncode(l_hCoordinate["points"])
            endif
        endif

        l_cHtml += [},]

        l_iAssociationPk_Previous := 0
    else
        l_iAssociationPk_Previous       := ListOfEdgesEntityEntity->Association_pk
        l_iEntityPk_Previous            := ListOfEdgesEntityEntity->Entity_pk
        l_cEndpointBoundLower_Previous  := ListOfEdgesEntityEntity->Endpoint_BoundLower
        l_cEndpointBoundUpper_Previous  := ListOfEdgesEntityEntity->Endpoint_BoundUpper
        l_lEndpointIsContainment_Previous    := ListOfEdgesEntityEntity->Endpoint_IsContainment
        l_cEndpointName_Previous        := ListOfEdgesEntityEntity->Endpoint_Name
        l_cEndpointDescription_Previous := ListOfEdgesEntityEntity->Endpoint_Description
    endif
endscan

l_cHtml += '];'

// create a network
l_cHtml += [  var container = document.getElementById("mynetwork");]

l_cHtml += [  var data = {]
l_cHtml += [    nodes: nodes,]
l_cHtml += [    edges: edges,]
l_cHtml += [  };]

l_cHtml += [ network = createGraph(container, nodes, edges, ]+iif(l_lAutoLayout,"true","false")+[); ]

if l_lGraphLib = "mxgraph"
    l_cHtml += ' network.getSelectionModel().addListener(mxEvent.CHANGE, function (sender, evt) {'
    l_cHtml += '     var cellsAdded = evt.getProperty("removed");'
    l_cHtml += '     var cellAdded = (cellsAdded && cellsAdded.length >0) ? cellsAdded[0] : null;'
    l_cHtml += '     var cellsRemoved = evt.getProperty("added");'
    l_cHtml += '     var cellRemoved = (cellsRemoved && cellsRemoved.length >0) ? cellsRemoved[0] : null;'
    l_cHtml += '     SelectGraphCell(cellsAdded,cellsRemoved,network);'
    l_cHtml += '     var params = {};'
    l_cHtml += '     if (cellAdded != null) {'
    l_cHtml += '         if(cellAdded.id.startsWith("E") || cellAdded.id.startsWith("A")) {'
    l_cHtml += '             params.nodes = [ cellAdded.id ];'
    l_cHtml += '         }'
    l_cHtml += '         else if(cellAdded.id.startsWith("D")) {'
    l_cHtml += '             params.edges = [ cellAdded.id ];'
    l_cHtml += '             params.items = [ { edgeId : cellAdded.id } ];'
    l_cHtml += '         }'
    l_cHtml += '     }'
    l_cHtml += '     evt.consume();'
else
    l_cHtml += ' network.on("click", function (params) {'
    l_cHtml += '   params.event = "[original event]";'
endif


// Code to filter Attributes
l_cJS := [$("#AttributeSearch").change(function() {]
l_cJS +=    [var l_keywords =  $(this).val();]
l_cJS +=    [$(".SpanAttributeName").each(function (par_SpanEntity){]+;
                                                           [var l_cAttributeName = $(this).text();]+;
                                                           [if (KeywordSearch(l_keywords,l_cAttributeName)) {$(this).parent().parent().parent().show();} else {$(this).parent().parent().parent().hide();}]+;
                                                           [});]
l_cJS += [});]

// Code to prevent the enter key from submitting the form but still trigger the .change()
l_cJS += [$("#AttributeSearch").keydown(function(e) {]
l_cJS +=    [var key = e.charCode ? e.charCode : e.keyCode ? e.keyCode : 0;]
l_cJS +=    [if(e.keyCode == 13 && e.target.type !== 'submit') {]
l_cJS +=      [e.preventDefault();]
l_cJS +=      [return $(e.target).blur().focus();]
l_cJS +=    [}]
l_cJS += [});]

// Code to enable the "All" and "Core Only" button
l_cJS += [$("#ButtonShowAll").click(function(){$("#AttributeSearch").val("");});]

l_cHtml += '   $("#GraphInfo" ).load( "'+l_cSitePath+'ajax/GetMLInfo","modelingdiagrampk='+Trans(l_iModelingDiagramPk)+'&info="+JSON.stringify(params) , function(){'+l_cJS+'});'
l_cHtml += '      });'

l_cHtml += ' network.on("dragStart", function (params) {'
l_cHtml += '   params.event = "[original event]";'
// l_cHtml += '   debugger;'
l_cHtml += "   if (params['nodes'].length == 1) {$('#ButtonSaveLayout').addClass('btn-warning').removeClass('btn-primary');};"
l_cHtml += '      });'

l_cHtml += [network.fit();]

l_cHtml += [};]

l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [MakeVis();]

// oFcgi:p_cjQueryScript += [$(document).on("keydown", "form", function(event) { return event.key != "Enter";});] // To prevent enter key from submitting form

return l_cHtml
//=================================================================================================================
function ModelingVisualizeDiagramOnSubmit(par_oDataHeader,par_cErrorText)
local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_cNodePositions
local l_oDB1
local l_oDB2
local l_oDB3
local l_iModelingDiagram_pk
local l_cListOfRelatedEntityPks
local l_aListOfRelatedEntityPks
local l_nNumberOfCurrentEntitiesInDiagram
local l_lSelected
local l_cEntityPk
local l_iEntityPk

oFcgi:TraceAdd("ModelingVisualizeDiagramOnSubmit")

l_iModelingDiagram_pk := Val(oFcgi:GetInputValue("TextModelingDiagramPk"))

do case
case l_cActionOnSubmit == "Show"
    l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)
                                            
//Stopped below.
case l_cActionOnSubmit == "DiagramSettings" .and. oFcgi:p_nAccessLevelML >= 4
    l_cHtml := ModelingVisualizeDiagramSettingsBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)

case l_cActionOnSubmit == "MyDiagramSettings"
    l_cHtml := ModelingVisualizeMyDiagramSettingsBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)

case l_cActionOnSubmit == "NewDiagram" .and. oFcgi:p_nAccessLevelML >= 4
   l_cHtml := ModelingVisualizeDiagramSettingsBuild(par_oDataHeader,par_cErrorText,0)

case ("SaveLayout" $ l_cActionOnSubmit) .and. oFcgi:p_nAccessLevelML >= 4
    l_cNodePositions  := Strtran(SanitizeInput(oFcgi:GetInputValue("TextNodePositions")),[%22],["])
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB1
        :Table("52aff222-451d-4726-849f-e17dbf4ab3a3","ModelingDiagram")
        :Field("ModelingDiagram.VisPos",l_cNodePositions)
        if empty(l_iModelingDiagram_pk)
            //Add an initial Diagram File this should not happen, since record was already added
            :Field("ModelingDiagram.fk_Model",par_oDataHeader:Model_pk)
            :Field("ModelingDiagram.Name"    ,[All ]+oFcgi:p_ANFEntities)
            :Field("ModelingDiagram.LinkUID" ,oFcgi:p_o_SQLConnection:GetUUIDString())
            if :Add()
                l_iModelingDiagram_pk := :Key()
            endif
        else
            :Update(l_iModelingDiagram_pk)
        endif
    endwith

    if "UpdateEntitySelection" $ l_cActionOnSubmit
        l_cListOfRelatedEntityPks := SanitizeInput(oFcgi:GetInputValue("TextListOfRelatedEntityPks"))
        l_aListOfRelatedEntityPks := hb_ATokens(l_cListOfRelatedEntityPks,"*")
        if len(l_aListOfRelatedEntityPks) > 0
            // Get the current list of Entities

            with Object l_oDB1
                :Table("780204b4-f2d0-4981-a6d2-f37d14adf479","DiagramEntity")
                :Distinct(.t.)
                :Column("Entity.pk","pk")
                :Column("DiagramEntity.pk","DiagramEntity_pk")
                :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
                :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagram_pk)
                :SQL("ListOfCurrentEntitiesInModelingDiagram")
                l_nNumberOfCurrentEntitiesInDiagram := :Tally
                if l_nNumberOfCurrentEntitiesInDiagram > 0
                    with object :p_oCursor
                        :Index("pk","pk")
                        :CreateIndexes()
                        :SetOrder("pk")
                    endwith        
                endif
            endwith
            if l_nNumberOfCurrentEntitiesInDiagram < 0
                //Failed to get current list of Entities in the diagram
            else
                if empty(l_nNumberOfCurrentEntitiesInDiagram)
                    //Implicitly all Entities are in the diagram. So should formally add all of them except the unselected ones.
                    l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    with object l_oDB2
                        // :Table("1d6f5c96-a2c3-4623-a91b-60b1243a3a00","ModelingDiagram")
                        // :Column("Entity.pk" , "Entity_pk")
                        // :Join("Inner","Entity","","ModelingDiagram.fk_Entity = Entity.pk")
                        // :Where("ModelingDiagram.pk = ^" , l_iModelingDiagram_pk)
                        // :SQL("ListOfAllModelEntity")

                        :Table("1d6f5c96-a2c3-4623-a91b-60b1243a3a00","Entity")
                        :Column("Entity.pk" , "Entity_pk")
                        :Where("Entity.fk_Model = ^" , par_oDataHeader:Model_pk)
                        :SQL("ListOfAllModelEntity")

                        if :Tally > 0
                            select ListOfAllModelEntity
                            scan all
                                if "*"+Trans(ListOfAllModelEntity->Entity_pk)+"*" $ "*" +l_cListOfRelatedEntityPks+ "*"  //One of the related Entities
                                    // "CheckEntity"
                                    l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllModelEntity->Entity_pk)) == "1")
                                else
                                    l_lSelected := .t.
                                endif
                                if l_lSelected
                                    with object l_oDB3
                                        :Table("5f908e53-e3ec-402e-acb2-973fad4f9888","DiagramEntity")
                                        :Field("DiagramEntity.fk_ModelingDiagram" , l_iModelingDiagram_pk)
                                        :Field("DiagramEntity.fk_Entity"          , ListOfAllModelEntity->Entity_pk)
                                        :Add()
                                    endwith
                                endif
                            endscan
                        endif
                    endwith

                else
                    //Add or remove only the related Entities that were listed.
                    l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    for each l_cEntityPk in l_aListOfRelatedEntityPks
                        l_lSelected := (oFcgi:GetInputValue("CheckEntity"+l_cEntityPk) == "1")

                        if l_lSelected
                            if !VFP_Seek(val(l_cEntityPk),"ListOfCurrentEntitiesInModelingDiagram","pk")
                                //Add if not present
                                with object l_oDB3
                                    :Table("5c2c3a2c-349b-4949-aba7-cb00875263d6","DiagramEntity")
                                    :Field("DiagramEntity.fk_ModelingDiagram" , l_iModelingDiagram_pk)
                                    :Field("DiagramEntity.fk_Entity"          , val(l_cEntityPk))
                                    :Add()
                                endwith
                            endif
                        else
                            if VFP_Seek(val(l_cEntityPk),"ListOfCurrentEntitiesInModelingDiagram","pk")
                                //Remove if present
                                l_oDB3:Delete("8b24f8d0-c79b-43be-aeb3-339bc4b53dc3","DiagramEntity",ListOfCurrentEntitiesInModelingDiagram->DiagramEntity_pk)
                            endif
                        endif

                    endfor
                endif
            endif

        endif
    endif

    if "RemoveEntity" $ l_cActionOnSubmit
        l_iEntityPk := val(oFcgi:GetInputValue("TextEntityPkToRemove"))
        if l_iEntityPk > 0
            // Get the current list of Entities

            with Object l_oDB1
                :Table("75568640-b583-4623-beb8-86fe74d1126f","DiagramEntity")
                :Distinct(.t.)
                :Column("Entity.pk","pk")
                :Column("DiagramEntity.pk","DiagramEntity_pk")
                :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
                :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagram_pk)
                :SQL("ListOfCurrentEntitiesInModelingDiagram")
                l_nNumberOfCurrentEntitiesInDiagram := :Tally
                if l_nNumberOfCurrentEntitiesInDiagram > 0
                    with object :p_oCursor
                        :Index("pk","pk")
                        :CreateIndexes()
                        :SetOrder("pk")
                    endwith        
                endif
            endwith
            if l_nNumberOfCurrentEntitiesInDiagram < 0
                //Failed to get current list of Entities in the diagram
            else
                if empty(l_nNumberOfCurrentEntitiesInDiagram)
                    //Implicitly all Entities are in the diagram. So should formally add all of them except the the current one.
                    l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    with object l_oDB2
                        // :Table("0830f12f-bcdc-4057-8907-d615771e4b4b","ModelingDiagram")
                        // :Column("Entity.pk" , "Entity_pk")
                        // :Where("ModelingDiagram.pk = ^" , l_iModelingDiagram_pk)
                        // :Join("Inner","Entity","","ModelingDiagram.fk_Entity = Entity.pk")
                        // :SQL("ListOfAllModelEntity")

                        :Table("0830f12f-bcdc-4057-8907-d615771e4b4b","Entity")
                        :Column("Entity.pk" , "Entity_pk")
                        :Where("Entity.fk_Model = ^" , par_oDataHeader:Model_pk)
                        :SQL("ListOfAllModelEntity")

                        if :Tally > 0
                            select ListOfAllModelEntity
                            scan all
                                if ListOfAllModelEntity->Entity_pk <> l_iEntityPk
                                    with object l_oDB3
                                        :Table("0ea9ad9d-b3b4-41f1-ac73-e1a9b06002d9","DiagramEntity")
                                        :Field("DiagramEntity.fk_ModelingDiagram" , l_iModelingDiagram_pk)
                                        :Field("DiagramEntity.fk_Entity"          , ListOfAllModelEntity->Entity_pk)
                                        :Add()
                                    endwith
                                endif
                            endscan
                        endif
                    endwith

                else
                    //Remove only the current Entities.
                    l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    if VFP_Seek(l_iEntityPk,"ListOfCurrentEntitiesInModelingDiagram","pk")
                        //Remove if still present
                        l_oDB3:Delete("d17d6980-88a1-46b1-8b64-1d1c93697d94","DiagramEntity",ListOfCurrentEntitiesInModelingDiagram->DiagramEntity_pk)
                    endif
                endif
            endif

        endif
    endif

    l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,"",l_iModelingDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ModelingVisualizeDiagramSettingsBuild(par_oDataHeader,par_cErrorText,par_iModelingDiagramPk,par_hValues)

local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_hValues      := hb_DefaultValue(par_hValues,{=>})
local l_CheckBoxId
local l_lShowPackage
local l_cPackage_FullName
local l_lNodeShowDescription
local l_lAssociationShowName
local l_lAssociationEndShowName
local l_nNodeMinHeight
local l_nNodeMaxWidth

local l_oDB1
local l_oData

oFcgi:TraceAdd("ModelingVisualizeDiagramSettingsBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

if pcount() < 8
    if par_iModelingDiagramPk > 0
        // Initial Build, meaning not from a failing editing
        with object l_oDB1
            //Get current Diagram Name
            :Table("a9d0a31d-e5ca-44a4-979f-7c6f1f1cf395","ModelingDiagram")
            :Column("ModelingDiagram.name"                  ,"ModelingDiagram_name")
            :Column("ModelingDiagram.NodeShowDescription"   ,"ModelingDiagram_NodeShowDescription")
            :Column("ModelingDiagram.AssociationShowName"   ,"ModelingDiagram_AssociationShowName")
            :Column("ModelingDiagram.AssociationEndShowName","ModelingDiagram_AssociationEndShowName")
            :Column("ModelingDiagram.NodeMinHeight"         ,"ModelingDiagram_NodeMinHeight")
            :Column("ModelingDiagram.NodeMaxWidth"          ,"ModelingDiagram_NodeMaxWidth")
            l_oData := :Get(par_iModelingDiagramPk)
            if :Tally == 1
                l_hValues["Name"]                   := l_oData:ModelingDiagram_name
                l_hValues["NodeShowDescription"]    := l_oData:ModelingDiagram_NodeShowDescription
                l_hValues["AssociationShowName"]    := l_oData:ModelingDiagram_AssociationShowName
                l_hValues["AssociationEndShowName"] := l_oData:ModelingDiagram_AssociationEndShowName
                l_hValues["NodeMinHeight"]          := l_oData:ModelingDiagram_NodeMinHeight
                l_hValues["NodeMaxWidth"]           := l_oData:ModelingDiagram_NodeMaxWidth
            endif

            //Get the current list of selected Entities
            :Table("cdd3a770-d3b0-4a00-8531-324ee83accc7","DiagramEntity")
            :Distinct(.t.)
            :Column("Entity.pk","pk")
            :Column("DiagramEntity.pk","DiagramEntity_pk")
            :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")        //Extra Join to filter out possible orphan records
            :Where("DiagramEntity.fk_ModelingDiagram = ^" , par_iModelingDiagramPk)
            :SQL("ListOfCurrentEntitiesInModelingDiagram")            
            if :Tally > 0
                select ListOfCurrentEntitiesInModelingDiagram
                scan all
                    l_hValues["Entity"+Trans(ListOfCurrentEntitiesInModelingDiagram->pk)] := .t.
                endscan
            endif
        endwith
    endif
endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="DiagramSettings">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextModelingDiagramPk" name="TextModelingDiagramPk" value="]+trans(par_iModelingDiagramPk)+[">]

if !empty(par_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+par_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iModelingDiagramPk),"New Diagram","Diagram Settings")+[</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" id="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('SaveDiagram');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iModelingDiagramPk)
            l_cHtml += [<button type="button" class="btn btn-danger rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
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

        l_lNodeShowDescription := hb_HGetDef(l_hValues,"NodeShowDescription",.f.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Node Entity Description</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckNodeShowDescription" id="CheckNodeShowDescription" value="1"]+iif(l_lNodeShowDescription," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]

        l_lAssociationShowName := hb_HGetDef(l_hValues,"AssociationShowName",.t.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Show Association Names</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckAssociationShowName" id="CheckAssociationShowName" value="1"]+iif(l_lAssociationShowName," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]

        l_lAssociationEndShowName := hb_HGetDef(l_hValues,"AssociationEndShowName",.t.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Show Association End Names</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckAssociationEndShowName" id="CheckAssociationEndShowName" value="1"]+iif(l_lAssociationEndShowName," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]

        l_nNodeMinHeight := hb_HGetDef(l_hValues,"NodeMinHeight",50)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Node Minimum Height</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="input" name="TextNodeMinHeight" id="TextNodeMinHeight" value="]+iif(empty(l_nNodeMinHeight),"",Trans(l_nNodeMinHeight))+[" size="4" maxlength="4">]
                l_cHtml += [<span>&nbsp;(In Pixels)&nbsp;(Optional)</span>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_nNodeMaxWidth := hb_HGetDef(l_hValues,"NodeMaxWidth",150)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Node Maximum Width</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="input" name="TextNodeMaxWidth" id="TextNodeMaxWidth" value="]+iif(empty(l_nNodeMaxWidth),"",Trans(l_nNodeMaxWidth))+[" size="4" maxlength="4">]
                l_cHtml += [<span>&nbsp;(In Pixels)&nbsp;(Optional)</span>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]
//List all the Entities

l_lShowPackage := .f.

with Object l_oDB1
    :Table("3b7ac84f-ceef-4a2a-b5a6-1acb2ab480e6","Entity")
    :Column("Entity.pk"         ,"pk")
    :Column("Package.FullName"  ,"Package_FullName")
    :Column("Entity.Name"       ,"Entity_Name")
    :Column("Entity.Description","Entity_Description")
    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
    :Column("upper(Entity.Name)"             , "tag2")
    :Join("left","Package","","Entity.fk_Package = Package.pk")
    :Where("Entity.fk_Model = ^",par_oDataHeader:Model_pk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfAllEntitiesInModel")

    if :Tally > 0
        
        l_cHtml += [<div class="ms-3"><span>Filter on Entity Name</span><input type="text" id="EntitySearch" value="" size="40" class="ms-2"><span class="ms-3"> (Press Enter)</span></div>]

        l_cHtml += [<div class="m-3"></div>]

        if :Tally > 1  //Will only display Package FullName if there are more than 1 name space used
            select ListOfAllEntitiesInModel
            l_cPackage_FullName := ListOfAllEntitiesInModel->Package_FullName
            locate for ListOfAllEntitiesInModel->Package_FullName <> l_cPackage_FullName
            l_lShowPackage := Found()
        endif
    endif
endwith

oFcgi:p_cjQueryScript += 'function KeywordSearch(par_cListOfWords, par_cString) {'
oFcgi:p_cjQueryScript += '  const l_aWords_upper = par_cListOfWords.toUpperCase().split(" ").filter(Boolean);'
oFcgi:p_cjQueryScript += '  const l_cString_upper = par_cString.toUpperCase();'
oFcgi:p_cjQueryScript += '  var l_lAllWordsIncluded = true;'
oFcgi:p_cjQueryScript += '  for (var i = 0; i < l_aWords_upper.length; i++) {'
oFcgi:p_cjQueryScript += '    if (!l_cString_upper.includes(l_aWords_upper[i])) {l_lAllWordsIncluded = false;break;};'
oFcgi:p_cjQueryScript += '  }'
oFcgi:p_cjQueryScript += '  return l_lAllWordsIncluded;'
oFcgi:p_cjQueryScript += '}'

oFcgi:p_cjQueryScript += [$("#EntitySearch").change(function() {]
oFcgi:p_cjQueryScript +=    [var l_keywords =  $(this).val();]
oFcgi:p_cjQueryScript +=    [$(".SPANEntity").each(function (par_SpanEntity){]+;
                                                                           [var l_cProjectName = $(this).text();]+;
                                                                           [if (KeywordSearch(l_keywords,l_cProjectName)) {$(this).parent().parent().show();} else {$(this).parent().parent().hide();}]+;
                                                                           [});]
oFcgi:p_cjQueryScript += [});]

l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [<table class="ms-5">]
select ListOfAllEntitiesInModel
scan all
    l_CheckBoxId := "CheckEntity"+Trans(ListOfAllEntitiesInModel->pk)
    l_cHtml += [<tr><td>]
        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif( hb_HGetDef(l_hValues,"Entity"+Trans(ListOfAllEntitiesInModel->pk),.f.)," checked","")+[ class="form-check-input">]
        l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+["><span class="SPANEntity">]+ListOfAllEntitiesInModel->Entity_Name+iif(l_lShowPackage .and. !hb_IsNil(ListOfAllEntitiesInModel->Package_FullName),[ (]+ListOfAllEntitiesInModel->Package_FullName+[)],[])
        l_cHtml += [</span></label>]
    l_cHtml += [</td></tr>]
endscan
l_cHtml += [</table>]
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
function ModelingVisualizeDiagramSettingsOnSubmit(par_oDataHeader,par_cErrorText)
local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_cNodePositions
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iModelingDiagram_pk
local l_cModelingDiagram_Name
local l_lModelingDiagram_NodeShowDescription
local l_lModelingDiagram_AssociationShowName
local l_lModelingDiagram_AssociationEndShowName
local l_lModelingDiagram_NodeMinHeight
local l_lModelingDiagram_NodeMaxWidth
local l_cErrorMessage
local l_lSelected
local l_cValue
local l_hValues := {=>}

oFcgi:TraceAdd("ModelingVisualizeDiagramSettingsOnSubmit")

l_iModelingDiagram_pk                     := Val(oFcgi:GetInputValue("TextModelingDiagramPk"))
l_cModelingDiagram_Name                   := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_lModelingDiagram_NodeShowDescription    := (oFcgi:GetInputValue("CheckNodeShowDescription") == "1")
l_lModelingDiagram_AssociationShowName    := (oFcgi:GetInputValue("CheckAssociationShowName") == "1")
l_lModelingDiagram_AssociationEndShowName := (oFcgi:GetInputValue("CheckAssociationEndShowName") == "1")
l_lModelingDiagram_NodeMinHeight          := min(9999,max(0,Val(SanitizeInput(oFcgi:GetInputValue("TextNodeMinHeight")))))
l_lModelingDiagram_NodeMaxWidth           := min(9999,max(0,Val(SanitizeInput(oFcgi:GetInputValue("TextNodeMaxWidth")))))

do case
case l_cActionOnSubmit == "SaveDiagram"
    //Get all the Application Entities to help scan all the selection checkboxes.
    with Object l_oDB2
        :Table("67cfa8ab-7675-451d-9a68-09f7bd3654da","Entity")
        :Column("Entity.pk"         ,"pk")
        :Where("Entity.fk_Model = ^",par_oDataHeader:Model_pk)
        :SQL("ListOfAllEntitiesInModel")
    endwith

    do case
    case empty(l_cModelingDiagram_Name)
        l_cErrorMessage := "Missing Name"
    otherwise
        with object l_oDB1
            :Table("60dafbab-0b7a-48cc-a49f-237ef6f34cee","ModelingDiagram")
            :Where([lower(replace(ModelingDiagram.Name,' ','')) = ^],lower(StrTran(l_cModelingDiagram_Name," ","")))
            :Where([ModelingDiagram.fk_Model = ^],par_oDataHeader:Model_pk)
            if l_iModelingDiagram_pk > 0
                :Where([ModelingDiagram.pk != ^],l_iModelingDiagram_pk)
            endif
            :SQL()
        endwith
        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        endif
    endcase

    if empty(l_cErrorMessage)
        with object l_oDB1
            :Table("78f6236c-9017-4098-8ad1-038e2643f343","ModelingDiagram")
            :Field("ModelingDiagram.Name"                  ,l_cModelingDiagram_Name)
            :Field("ModelingDiagram.NodeShowDescription"   ,l_lModelingDiagram_NodeShowDescription)
            :Field("ModelingDiagram.AssociationShowName"   ,l_lModelingDiagram_AssociationShowName)
            :Field("ModelingDiagram.AssociationEndShowName",l_lModelingDiagram_AssociationEndShowName)
            :Field("ModelingDiagram.NodeMinHeight"         ,l_lModelingDiagram_NodeMinHeight)
            :Field("ModelingDiagram.NodeMaxWidth"          ,l_lModelingDiagram_NodeMaxWidth)
            
            if empty(l_iModelingDiagram_pk)
                :Field("ModelingDiagram.fk_Model",par_oDataHeader:Model_pk)
                :Field("ModelingDiagram.UseStatus"     , 1)
                :Field("ModelingDiagram.DocStatus"     , 1)
                :Field("ModelingDiagram.LinkUID"       ,oFcgi:p_o_SQLConnection:GetUUIDString())
                if :Add()
                    l_iModelingDiagram_pk := :Key()
                else
                    l_iModelingDiagram_pk := 0
                    l_cErrorMessage := "Failed to save changes!"
                endif
            else
                if !:Update(l_iModelingDiagram_pk)
                    l_cErrorMessage := "Failed to save changes!"
                endif

            endif
        endwith
    endif

    if empty(l_cErrorMessage)
        //Update the list selected Entities
        //Get current list of diagram Entities
        with Object l_oDB1
            :Table("0c882ae5-56fc-4a23-a617-3fce7ce3174b","DiagramEntity")
            :Distinct(.t.)
            :Column("Entity.pk","pk")
            :Column("DiagramEntity.pk","DiagramEntity_pk")
            :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
            :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagram_pk)
            :SQL("ListOfCurrentEntitiesInModelingDiagram")
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith        
        endwith

        select ListOfAllEntitiesInModel
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllEntitiesInModel->pk)) == "1")

            if VFP_Seek(ListOfAllEntitiesInModel->pk,"ListOfCurrentEntitiesInModelingDiagram","pk")
                if !l_lSelected
                    // Remove the Entity
                    with Object l_oDB3
                        if !:Delete("ebadaa57-b9d7-49ec-ae1e-f37314825017","DiagramEntity",ListOfCurrentEntitiesInModelingDiagram->DiagramEntity_pk)
                            l_cErrorMessage := "Failed to Save Entity selection."
                            exit
                        endif
                    endwith
                endif
            else
                if l_lSelected
                    // Add the Entity
                    with Object l_oDB3
                        :Table("af4e7487-6a13-4fa2-b1ea-14f5a0651039","DiagramEntity")
                        :Field("DiagramEntity.fk_Entity"          , ListOfAllEntitiesInModel->pk)
                        :Field("DiagramEntity.fk_ModelingDiagram" , l_iModelingDiagram_pk)
                        if !:Add()
                            l_cErrorMessage := "Failed to Save Entity selection."
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
        l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,l_cErrorMessage,l_iModelingDiagram_pk)

    else
        l_hValues["Name"]                   := l_cModelingDiagram_Name
        l_hValues["NodeShowDescription"]    := l_lModelingDiagram_NodeShowDescription
        l_hValues["AssociationShowName"]    := l_lModelingDiagram_AssociationShowName
        l_hValues["AssociationEndShowName"] := l_lModelingDiagram_AssociationEndShowName
        l_hValues["NodeMinHeight"]          := l_lModelingDiagram_NodeMinHeight
        l_hValues["NodeMaxWidth"]           := l_lModelingDiagram_NodeMaxWidth
                
        select ListOfAllEntitiesInModel
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllEntitiesInModel->pk)) == "1")
            if l_lSelected  // No need to store the unselect references, since not having a reference will mean "not selected"
                l_hValues["Entity"+Trans(ListOfAllEntitiesInModel->pk)] := .t.
            endif
        endscan
        l_cHtml := ModelingVisualizeDiagramSettingsBuild(par_oDataHeader,l_cErrorMessage,l_iModelingDiagram_pk,l_hValues)
        
    endif

case l_cActionOnSubmit == "Cancel"
    l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)


case l_cActionOnSubmit == "Delete"
    with object l_oDB1
        //Delete related records in DiagramEntity
        :Table("a317b1a2-0cad-48f9-8f0f-892af023c9d4","DiagramEntity")
        :Column("DiagramEntity.pk","pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagram_pk)
        :SQL("ListOfDiagramEntityToDelete")
        select ListOfDiagramEntityToDelete
        scan all
            l_oDB2:Delete("1419a855-311f-410f-8ec1-ed5978b06cd6","DiagramEntity",ListOfDiagramEntityToDelete->pk)
        endscan
        l_oDB2:Delete("739927f0-d2cf-4ae2-99ae-88df9aa72fe2","ModelingDiagram",l_iModelingDiagram_pk)
    endwith
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/Visualize/"+par_oDataHeader:Model_LinkUID+"/")

case l_cActionOnSubmit == "ResetLayout"
    with object l_oDB1
        :Table("c8ef687c-a39b-4c4d-80e7-fa737a844832","ModelingDiagram")
        :Field("ModelingDiagram.VisPos",NIL)
        :Update(l_iModelingDiagram_pk)
    endwith
    l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ModelingVisualizeMyDiagramSettingsBuild(par_oDataHeader,par_cErrorText,par_iModelingDiagramPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_hValues      := hb_DefaultValue(par_hValues,{=>})
local l_cDiagramInfoScale
local l_nDiagramInfoScale

local l_nSize
local l_iCanvasWidth
local l_iCanvasHeight

local l_lNavigationControl
local l_lNeverShowDescriptionOnHover

oFcgi:TraceAdd("ModelingVisualizeMyDiagramSettingsBuild")

if pcount() < 4
    if par_iModelingDiagramPk > 0

        l_cDiagramInfoScale := GetUserSetting("DiagramInfoScale")
        if empty(l_cDiagramInfoScale)
            l_nDiagramInfoScale := 1
        else
            l_nDiagramInfoScale := val(l_cDiagramInfoScale)
            if l_nDiagramInfoScale < 0.4 .or. l_nDiagramInfoScale > 1.0
                l_nDiagramInfoScale := 1
            endif
        endif
        l_hValues["DiagramInfoScale"]  := l_nDiagramInfoScale   // 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4

        l_iCanvasWidth  := val(GetUserSetting("CanvasWidth"))
        if l_iCanvasWidth < CANVAS_WIDTH_MIN .or. l_iCanvasWidth > CANVAS_WIDTH_MAX
            l_iCanvasWidth := CANVAS_WIDTH_DEFAULT
        endif
        l_hValues["CanvasWidth"]  := l_iCanvasWidth

        l_iCanvasHeight := val(GetUserSetting("CanvasHeight"))
        if l_iCanvasHeight < CANVAS_HEIGHT_MIN .or. l_iCanvasHeight > CANVAS_HEIGHT_MAX
            l_iCanvasHeight := CANVAS_HEIGHT_DEFAULT
        endif
        l_hValues["CanvasHeight"]  := l_iCanvasHeight

        l_lNavigationControl := (GetUserSetting("NavigationControl") == "T")
        l_hValues["NavigationControl"]  := l_lNavigationControl

        l_lNeverShowDescriptionOnHover := (GetUserSetting("NeverShowDescriptionOnHover") == "T")
        l_hValues["NeverShowDescriptionOnHover"]  := l_lNeverShowDescriptionOnHover

    endif
endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="MyDiagramSettings">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" id="TextModelingDiagramPk" name="TextModelingDiagramPk" value="]+trans(par_iModelingDiagramPk)+[">]

if !empty(par_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-danger text-white">]+par_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">My Settings</span>]   //navbar-text
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-0" id="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('SaveMySettings');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        l_nDiagramInfoScale := hb_HGetDef(l_hValues,"DiagramInfoScale",1)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Right Panel Scale</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDiagramInfoScale" id="ComboDiagramInfoScale">]
                    l_cHtml += [<option value="1"]  +iif(l_nDiagramInfoScale==1  ,[ selected],[])+[>1.0</option>]
                    l_cHtml += [<option value="0.9"]+iif(l_nDiagramInfoScale==0.9,[ selected],[])+[>0.9</option>]
                    l_cHtml += [<option value="0.8"]+iif(l_nDiagramInfoScale==0.8,[ selected],[])+[>0.8</option>]
                    l_cHtml += [<option value="0.7"]+iif(l_nDiagramInfoScale==0.7,[ selected],[])+[>0.7</option>]
                    l_cHtml += [<option value="0.6"]+iif(l_nDiagramInfoScale==0.6,[ selected],[])+[>0.6</option>]
                    l_cHtml += [<option value="0.5"]+iif(l_nDiagramInfoScale==0.5,[ selected],[])+[>0.5</option>]
                    l_cHtml += [<option value="0.4"]+iif(l_nDiagramInfoScale==0.4,[ selected],[])+[>0.4</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_iCanvasWidth := hb_HGetDef(l_hValues,"CanvasWidth",CANVAS_WIDTH_DEFAULT)
        if l_iCanvasWidth < CANVAS_WIDTH_MIN .or. l_iCanvasWidth > CANVAS_WIDTH_MAX
            l_iCanvasWidth := CANVAS_WIDTH_DEFAULT
        endif
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Canvas Width</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboCanvasWidth" id="ComboCanvasWidth">]
                    for l_nSize := CANVAS_WIDTH_MIN to CANVAS_WIDTH_MAX step 100
                        l_cHtml += [<option value="]+Trans(l_nSize)+["]+iif(l_iCanvasWidth==l_nSize,[ selected],[])+[>]+Trans(l_nSize)+[</option>]
                    endfor
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_iCanvasHeight := hb_HGetDef(l_hValues,"CanvasHeight",CANVAS_HEIGHT_DEFAULT)
        if l_iCanvasHeight < CANVAS_HEIGHT_MIN .or. l_iCanvasHeight > CANVAS_HEIGHT_MAX
            l_iCanvasHeight := CANVAS_HEIGHT_DEFAULT
        endif
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Canvas Height</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboCanvasHeight" id="ComboCanvasHeight">]
                    for l_nSize := CANVAS_HEIGHT_MIN to CANVAS_HEIGHT_MAX step 100
                        l_cHtml += [<option value="]+Trans(l_nSize)+["]+iif(l_iCanvasHeight==l_nSize,[ selected],[])+[>]+Trans(l_nSize)+[</option>]
                    endfor
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_lNavigationControl := hb_HGetDef(l_hValues,"NavigationControl",.f.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Display Navigation Controls</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckNavigationControl" id="CheckNavigationControl" value="1"]+iif(l_lNavigationControl," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]


        l_lNeverShowDescriptionOnHover := hb_HGetDef(l_hValues,"NeverShowDescriptionOnHover",.f.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Never Show Description On Hover</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckNeverShowDescriptionOnHover" id="CheckNeverShowDescriptionOnHover" value="1"]+iif(l_lNeverShowDescriptionOnHover," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]


    l_cHtml += [</table>]
    
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

oFcgi:p_cjQueryScript += [$('#ComboDiagramInfoScale').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
function ModelingVisualizeMyDiagramSettingsOnSubmit(par_oDataHeader,par_cErrorText)

local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_iModelingDiagram_pk

local l_nDiagramInfoScale
local l_iCanvasWidth
local l_iCanvasHeight
local l_lNavigationControl
local l_lNeverShowDescriptionOnHover

local l_cErrorMessage := ""
local l_lSelected
local l_hValues := {=>}

oFcgi:TraceAdd("ModelingVisualizeMyDiagramSettingsOnSubmit")

l_iModelingDiagram_pk       := Val(oFcgi:GetInputValue("TextModelingDiagramPk"))
l_nDiagramInfoScale := val(oFcgi:GetInputValue("ComboDiagramInfoScale"))
if l_nDiagramInfoScale < 0.4 .or. l_nDiagramInfoScale > 1.0
    l_nDiagramInfoScale := 1
endif

l_iCanvasWidth := val(oFcgi:GetInputValue("ComboCanvasWidth"))
if l_iCanvasWidth < CANVAS_WIDTH_MIN .or. l_iCanvasWidth > CANVAS_WIDTH_MAX
    l_iCanvasWidth := CANVAS_WIDTH_DEFAULT
endif

l_iCanvasHeight := val(oFcgi:GetInputValue("ComboCanvasHeight"))
if l_iCanvasHeight < CANVAS_HEIGHT_MIN .or. l_iCanvasHeight > CANVAS_HEIGHT_MAX
    l_iCanvasHeight := CANVAS_HEIGHT_DEFAULT
endif

l_lNavigationControl           := (oFcgi:GetInputValue("CheckNavigationControl") == "1")
l_lNeverShowDescriptionOnHover := (oFcgi:GetInputValue("CheckNeverShowDescriptionOnHover") == "1")

do case
case l_cActionOnSubmit == "SaveMySettings"

    if l_nDiagramInfoScale == 1
        SaveUserSetting("DiagramInfoScale","")  // No need to save the default value
    else
        SaveUserSetting("DiagramInfoScale",Trans(l_nDiagramInfoScale))
    endif

    if l_iCanvasWidth == CANVAS_WIDTH_DEFAULT
        SaveUserSetting("CanvasWidth","")  // No need to save the default value
    else
        SaveUserSetting("CanvasWidth",Trans(l_iCanvasWidth))
    endif

    if l_iCanvasHeight == CANVAS_HEIGHT_DEFAULT
        SaveUserSetting("CanvasHeight","")  // No need to save the default value
    else
        SaveUserSetting("CanvasHeight",Trans(l_iCanvasHeight))
    endif

    if l_lNavigationControl
        SaveUserSetting("NavigationControl","T")
    else
        SaveUserSetting("NavigationControl","")
    endif

    if l_lNeverShowDescriptionOnHover
        SaveUserSetting("NeverShowDescriptionOnHover","T")
    else
        SaveUserSetting("NeverShowDescriptionOnHover","")
    endif

    if empty(l_cErrorMessage)
        l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,l_cErrorMessage,l_iModelingDiagram_pk)
    else
        l_hValues["DiagramInfoScale"] := l_nDiagramInfoScale
        l_cHtml := ModelingVisualizeMyDiagramSettingsBuild(par_oDataHeader,l_cErrorMessage,l_iModelingDiagram_pk,l_hValues)
    endif

case l_cActionOnSubmit == "Cancel"
    l_cHtml += ModelingVisualizeDiagramBuild(par_oDataHeader,par_cErrorText,l_iModelingDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
function GetMLInfoDuringVisualization()
local l_cHtml := []
local l_cInfo := Strtran(oFcgi:GetQueryString("info"),[%22],["])
local l_iModelingDiagram_pk := val(oFcgi:GetQueryString("modelingdiagrampk"))
local l_hOnClickInfo := {=>}
local l_nLengthDecoded
local l_aNodes
local l_aEdges
local l_aItems
local l_cNode
local l_cGraphItemType      // "E" = Entity, "A" = Association as a Node, "L" = Edge Entity - Association, "D" = Edge Entity - Entity
local l_iEntityPk
local l_iAssociationPk
local l_iEndpointPk
local l_oDB_Project := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_InArray
local l_oDB_ListOfRelatedEntities
local l_oDB_ListOfCurrentEntitiesInModelingDiagram
local l_oDB_ListOfAttribute
local l_oDB_ListOfOtherModelingDiagrams
local l_oDB_EntityCustomFields
local l_oDB_UserAccessProject
local l_aSQLResult := {}
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cEntityLinkUID
local l_cPackageFullName

local l_cEntityName
local l_cEntityDescription
local l_cEntityInformation

local l_cAttributeName
local l_cAttributeDescription
local l_cFrom_NameSpace_Name
local l_cFrom_Entity_Name
local l_cTo_NameSpace_Name
local l_cTo_Entity_Name
local l_CheckBoxId
local l_nNumberOfEntitiesInDiagram
local l_cListOfRelatedEntityPks := ""
local l_nActiveTabNumber := max(1,min(4,val(oFcgi:GetCookieValue("DiagramDetailTab"))))
local l_nEdgeNumber
local l_nEdgeCounter
local l_nNumberOfAttributes
local l_nNumberOfOtherModelingDiagram
local l_nNumberOfRelatedEntities
local l_cUseStatus
local l_cDocStatus
local l_nNumberOfCustomFieldValues
local l_hOptionValueToDescriptionMapping := {=>}
local l_cHtml_EntityCustomFields := ""
local l_lNeverShowDescriptionOnHover
local l_oData_Project
local l_cApplicationSupportAttributes
local l_cHtml_icon
local l_nAccessLevelML
local l_cZoomInfo
local l_cObjectId

oFcgi:TraceAdd("GetMLInfoDuringVisualization")

l_nLengthDecoded := hb_jsonDecode(l_cInfo,@l_hOnClickInfo)

l_lNeverShowDescriptionOnHover := (GetUserSetting("NeverShowDescriptionOnHover") == "T")

l_aNodes := hb_HGetDef(l_hOnClickInfo,"nodes",{})
if len(l_aNodes) == 1
    l_cNode := l_aNodes[1]

    switch left(l_cNode,1)
    case "E"
        l_cGraphItemType := "E"
        l_iEntityPk      := val(substr(l_cNode,2))

        with object l_oDB_Project
            :Table("aabe8f6a-1c2c-4828-a56b-43c26bd06091","Entity")
            :Column("Project.pk" , "Project_pk")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oData_Project := :Get(l_iEntityPk)
            if :Tally <> 1
                l_cGraphItemType := ""
            endif
        endwith

        exit

    case "A"
        l_cGraphItemType := "A"
        l_iAssociationPk := val(substr(l_cNode,2))

        with object l_oDB_Project
            :Table("ea57507d-b56f-43a6-a808-e820ce14794d","Association")
            :Column("Project.pk" , "Project_pk")
            :Join("inner","Model","","Association.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oData_Project := :Get(l_iAssociationPk)
            if :Tally <> 1
                l_cGraphItemType := ""
            endif
        endwith
        
        exit

    otherwise
        l_cGraphItemType := ""

    endcase

    do case
    case l_cGraphItemType == "E"
        //Clicked on a Entity

        //Get the project l_nAccessLevelML
        l_nAccessLevelML := GetAccessLevelMLForProject(l_oData_Project:Project_pk)

        //Current List of Entities in diagram
        l_oDB_ListOfCurrentEntitiesInModelingDiagram := hb_SQLData(oFcgi:p_o_SQLConnection)
        with Object l_oDB_ListOfCurrentEntitiesInModelingDiagram
            :Table("8ce66c2d-e24a-44af-962b-0db5d5fc2f1c","DiagramEntity")
            :Distinct(.t.)
            :Column("Entity.pk","pk")
            :Column("DiagramEntity.pk","DiagramEntity_pk")
            :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")    // Extra inner join to ensure we don't pick up orphan records
            :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagram_pk)
            :SQL("ListOfCurrentEntitiesInModelingDiagram")
            l_nNumberOfEntitiesInDiagram := :Tally
            if l_nNumberOfEntitiesInDiagram > 0
                with object :p_oCursor
                    :Index("pk","pk")
                    :CreateIndexes()
                    :SetOrder("pk")
                endwith
            endif
        endwith

        l_oDB_ListOfAttribute := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfAttribute
            :Table("aaf1a8ab-c0aa-46d7-b691-3448f203ca8c","Attribute")
            :Column("Attribute.pk"             ,"pk")
            :Column("Attribute.fk_DataType"    ,"Attribute_fk_DataType")
            :Column("DataType.FullName"        ,"DataType_FullName")
            :Column("Attribute.Order"          ,"Attribute_Order")
            :Column("Attribute.LinkUID"        ,"Attribute_LinkUID")
            :Column("Attribute.Name"           ,"Attribute_Name")
            :Column("Attribute.BoundLower"     ,"Attribute_BoundLower")
            :Column("Attribute.BoundUpper"     ,"Attribute_BoundUpper")
            :Column("Attribute.Description"    ,"Attribute_Description")
            :Join("inner","DataType","","Attribute.fk_DataType = DataType.pk")
            :Where("Attribute.fk_Entity = ^",l_iEntityPk)
            :OrderBy("Attribute_Order")
            :SQL("ListOfAttributes")
            l_nNumberOfAttributes := :Tally
        endwith

        l_oDB_ListOfOtherModelingDiagrams := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfOtherModelingDiagrams
            :Table("6205145d-e049-434f-8fbe-8b900873e196","DiagramEntity")
            :Column("ModelingDiagram.pk"         ,"ModelingDiagram_pk")
            :Column("ModelingDiagram.Name"       ,"ModelingDiagram_Name")
            :Column("ModelingDiagram.LinkUID"    ,"ModelingDiagram_LinkUID")
            :Column("upper(ModelingDiagram.Name)","tag1")
            :Join("inner","ModelingDiagram","","DiagramEntity.fk_ModelingDiagram = ModelingDiagram.pk")
            :Where("DiagramEntity.fk_Entity = ^",l_iEntityPk)
            :Where("ModelingDiagram.pk <> ^",l_iModelingDiagram_pk)
            :OrderBy("tag1")
            :SQL("ListOfOtherModelingDiagram")
            l_nNumberOfOtherModelingDiagram := :Tally
        endwith


        //Get the list of related Entities
        l_oDB_ListOfRelatedEntities := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfRelatedEntities
            :Table("69cff617-c3c9-4a51-a167-bb9f68cc99f9","Endpoint")
            :Distinct(.t.)
            :Column("Entity.pk"        , "Entity_pk")
            :Column("Package.FullName" , "Package_FullName")
            :Column("Entity.Name"      , "Entity_Name")
            :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
            :Column("upper(Entity.Name)"             , "tag2")
            :Where("Endpoint.fk_Entity  = ^" , l_iEntityPk)
            :Where("Entity.pk != ^" , l_iEntityPk)
            :Join("inner","Association",""         ,"Endpoint.fk_Association = Association.pk")
            :Join("inner","Endpoint"   ,"Endpoint2","Endpoint2.fk_Association = Association.pk AND Endpoint.pk != Endpoint2.pk")
            :Join("inner","Entity"     ,"","Endpoint2.fk_Entity = Entity.pk")
            :Join("left","Package","","Entity.fk_Package = Package.pk") 
            :OrderBy("tag1")
            :OrderBy("tag2")
            :SQL("ListOfRelatedEntities")
            l_nNumberOfRelatedEntities := :Tally

        endwith

        l_oDB_EntityCustomFields := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_EntityCustomFields
            // Get the Entity Custom Fields
            :Table("24d38337-8b1c-4bfe-88e6-869ab00f4b68","CustomFieldValue")
            :Distinct(.t.)
            :Column("CustomField.pk"              ,"CustomField_pk")
            :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
            :Join("inner","CustomField","","CustomFieldValue.fk_CustomField = CustomField.pk")
            :Where("CustomFieldValue.fk_Entity = ^",l_iEntityPk)
            :Where("CustomField.UsedOn = ^",USEDON_ENTITY)
            :Where("CustomField.Status <= 2")
            :Where("CustomField.Type = 2")   // Multi Choice
            :SQL("ListOfCustomFieldOptionDefinition")
            if :Tally > 0
                CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
            endif

            :Table("21bed905-bcae-4c80-a6a5-56897cdc3fba","CustomFieldValue")
            :Column("CustomFieldValue.fk_Entity","fk_entity")
            :Column("CustomField.pk"            ,"CustomField_pk")
            :Column("CustomField.Label"         ,"CustomField_Label")
            :Column("CustomField.Type"          ,"CustomField_Type")
            :Column("CustomFieldValue.ValueI"   ,"CustomFieldValue_ValueI")
            :Column("CustomFieldValue.ValueM"   ,"CustomFieldValue_ValueM")
            :Column("CustomFieldValue.ValueD"   ,"CustomFieldValue_ValueD")
            :Column("upper(CustomField.Name)"   ,"tag1")
            :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
            :Where("CustomFieldValue.fk_Entity = ^",l_iEntityPk)
            :Where("CustomField.UsedOn = ^",USEDON_ENTITY)
            :Where("CustomField.Status <= 2")
            :OrderBy("tag1")
            :SQL("ListOfCustomFieldValues")
            l_nNumberOfCustomFieldValues := :Tally
            
            if l_nNumberOfCustomFieldValues > 0
                l_cHtml_EntityCustomFields := CustomFieldsBuildGridOther(l_iEntityPk,l_hOptionValueToDescriptionMapping)
            endif

            // Get the Attribute Custom Fields
            // l_hOptionValueToDescriptionMapping := {=>}
            hb_HClear(l_hOptionValueToDescriptionMapping)

            :Table("55b6deaa-26ce-4434-9119-a76a634bf337","Attribute")
            :Distinct(.t.)
            :Column("CustomField.pk"              ,"CustomField_pk")
            :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
            :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Attribute.pk")
            :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
            :Where("Attribute.fk_Entity = ^",l_iEntityPk)
            :Where("CustomField.UsedOn = ^",USEDON_ATTRIBUTE)
            :Where("CustomField.Status <= 2")
            :Where("CustomField.Type = 2")   // Multi Choice
            :SQL("ListOfCustomFieldOptionDefinition")
            if :Tally > 0
                CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
            endif

            :Table("4472cd37-4212-4075-92ea-ea868cb79339","Attribute")
            :Column("Attribute.pk"           ,"fk_entity")
            :Column("CustomField.pk"         ,"CustomField_pk")
            :Column("CustomField.Label"      ,"CustomField_Label")
            :Column("CustomField.Type"       ,"CustomField_Type")
            :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
            :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
            :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
            :Column("upper(CustomField.Name)","tag1")
            :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Attribute.pk")
            :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
            :Where("Attribute.fk_Entity = ^",l_iEntityPk)
            :Where("CustomField.UsedOn = ^",USEDON_ATTRIBUTE)
            :Where("CustomField.Status <= 2")
            // :OrderBy("Attribute_pk")
            :OrderBy("tag1")
            :SQL("ListOfCustomFieldValues")
            l_nNumberOfCustomFieldValues := :Tally

        endwith

        l_oDB_InArray := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_InArray
            :Table("eaca66a4-e311-4e3e-a3c4-8ee000f15df4","Entity")
            :Column("Entity.LinkUID"       ,"Entity_LinkUID")         // 1
            :Column("Package.FullName"     ,"Package_FullName")       // 2
            :Column("Entity.Name"          ,"Entity_Name")            // 3
            :Column("Entity.Description"   ,"Entity_Description")     // 4
            :Column("Entity.Information"   ,"Entity_Information")     // 5
            // :join("inner","Model"  ,"","Entity.fk_Model = Model.pk")
            // :join("inner","Project","","Model.fk_Project = Project.pk")
            :Join("left" ,"Package","","Entity.fk_Package = Package.pk") 
            :Where("Entity.pk = ^" , l_iEntityPk)
            :SQL(@l_aSQLResult)
        endwith

        if l_oDB_InArray:Tally == 1
            l_cEntityLinkUID        := AllTrim(l_aSQLResult[1,1])
            l_cPackageFullName      := nvl(l_aSQLResult[1,2],"")
            l_cEntityName           := l_aSQLResult[1,3]
            l_cEntityDescription    := nvl(l_aSQLResult[1,4],"")
            l_cEntityInformation    := nvl(l_aSQLResult[1,5],"")

            if !empty(l_cPackageFullName)
                l_cZoomInfo := l_cPackageFullName+" / "+l_cEntityName
            else
                l_cZoomInfo := l_cEntityName
            endif

            l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]
            l_cHtml += MODELING_ENTITY_NODE_BACKGROUND
            l_cHtml += [;">]

                l_cHtml += [<div class="input-group">]
                    l_cHtml += [<span class="navbar-brand ms-3">]+oFcgi:p_ANFEntity+[: ]+l_cZoomInfo+;
                                   [<a class="ms-3" target="_blank" href="]+l_cSitePath+[Modeling/EditEntity/]+l_cEntityLinkUID+[/"><i class="bi bi-pencil-square"></i></a>]+;
                               [</span>]
                l_cHtml += [</div>]

            l_cHtml += [</nav>]

            l_cHtml += [<div class="m-3"></div>]

            l_cHtml += [<ul class="nav nav-tabs">]
                l_cHtml += [<li class="nav-item">]
                    l_cHtml += [<a id="TabDetail1" class="nav-link]+iif(l_nActiveTabNumber == 1,[ active],[])+["]+;
                                [ onclick="document.cookie = 'DiagramDetailTab=1; path=/';]+;
                                                                [$('#DetailType1').show();]+;
                                                                [$('#DetailType2').hide();]+;
                                                                [$('#DetailType3').hide();]+;
                                                                [$('#DetailType4').hide();]+;
                                                                [$('#TabDetail1').addClass('active');]+;
                                                                [$('#TabDetail2').removeClass('active');]+;
                                                                [$('#TabDetail3').removeClass('active');]+;
                                                                [$('#TabDetail4').removeClass('active');"]+;
                                                                [>]+oFcgi:p_ANFAttributes+[ (]+Trans(l_nNumberOfAttributes)+[)</a>]
                l_cHtml += [</li>]
                l_cHtml += [<li class="nav-item">]
                    l_cHtml += [<a id="TabDetail2" class="nav-link]+iif(l_nActiveTabNumber == 2,[ active],[])+["]+;
                                    [ onclick="document.cookie = 'DiagramDetailTab=2; path=/';]+;
                                                                [$('#DetailType1').hide();]+;
                                                                [$('#DetailType2').show();]+;
                                                                [$('#DetailType3').hide();]+;
                                                                [$('#DetailType4').hide();]+;
                                                                [$('#TabDetail1').removeClass('active');]+;
                                                                [$('#TabDetail2').addClass('active');]+;
                                                                [$('#TabDetail3').removeClass('active');]+;
                                                                [$('#TabDetail4').removeClass('active');"]+;
                                                                [>Related ]+oFcgi:p_ANFEntities+[ In App (]+Trans(l_nNumberOfRelatedEntities)+[)</a>]
                l_cHtml += [</li>]
                l_cHtml += [<li class="nav-item">]
                    l_cHtml += [<a id="TabDetail3" class="nav-link]+iif(l_nActiveTabNumber == 3,[ active],[])+["]+;
                                [ onclick="document.cookie = 'DiagramDetailTab=3; path=/';]+;
                                                                [$('#DetailType1').hide();]+;
                                                                [$('#DetailType2').hide();]+;
                                                                [$('#DetailType3').show();]+;
                                                                [$('#DetailType4').hide();]+;
                                                                [$('#TabDetail1').removeClass('active');]+;
                                                                [$('#TabDetail2').removeClass('active');]+;
                                                                [$('#TabDetail3').addClass('active');]+;
                                                                [$('#TabDetail4').removeClass('active');"]+;
                                                                [>Other Diagrams (]+Trans(l_nNumberOfOtherModelingDiagram)+[)</a>]
                l_cHtml += [</li>]
                l_cHtml += [<li class="nav-item">]
                    l_cHtml += [<a id="TabDetail4" class="nav-link]+iif(l_nActiveTabNumber == 4,[ active],[])+["]+;
                                [ onclick="document.cookie = 'DiagramDetailTab=4; path=/';]+;
                                                                [$('#DetailType1').hide();]+;
                                                                [$('#DetailType2').hide();]+;
                                                                [$('#DetailType3').hide();]+;
                                                                [$('#DetailType4').show();]+;
                                                                [$('#TabDetail1').removeClass('active');]+;
                                                                [$('#TabDetail2').removeClass('active');]+;
                                                                [$('#TabDetail3').removeClass('active');]+;
                                                                [$('#TabDetail4').addClass('active');"]+;
                                                                [>]+oFcgi:p_ANFEntity+[ Info</a>]
                l_cHtml += [</li>]
            l_cHtml += [</ul>]

            l_cHtml += [<div class="m-3"></div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

            l_cHtml += [<div id="DetailType1"]+iif(l_nActiveTabNumber <> 1,[ style="display: none;"],[])+[ class="m-3">]

                if l_nNumberOfAttributes <= 0
                    l_cHtml += [<div class="mb-2">]+oFcgi:p_ANFEntity+[ has no ]+oFcgi:p_ANFAttributes+[</div>]
                else
                    l_cHtml += [<div class="row">]  //  justify-content-center
                        l_cHtml += [<div class="col-auto">]

                            l_cHtml += [<div>]
                            l_cHtml += [<span>Filter on ]+oFcgi:p_ANFAttributes+[ Name</span>]
                            l_cHtml += [<input type="text" id="AttributeSearch" value="" size="30" class="ms-2">]
                            l_cHtml += [<span class="ms-1"> (Press Enter)</span>]
                            l_cHtml += [<input type="button" id="ButtonShowAll" class="btn btn-primary rounded ms-3" value="All">]
                            l_cHtml += [</div>]

                            l_cHtml += [<div class="m-3"></div>]

                            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                            l_cHtml += [<tr class="bg-info">]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFDataType+[</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Bound<br>Lower</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Bound<br>Upper</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                                if l_nNumberOfCustomFieldValues > 0
                                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                                endif
                            l_cHtml += [</tr>]

                            select ListOfAttributes
                            scan all
                                l_cHtml += [<tr>]

                                    // Name
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditAttribute/]+ListOfAttributes->Attribute_LinkUID+[/"><span class="SpanAttributeName">]+ListOfAttributes->Attribute_Name+[</span></a>]
                                    l_cHtml += [</td>]

                                    // Data Type
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += ListOfAttributes->DataType_FullName
                                    l_cHtml += [</td>]

                                    // Bound<br>Lower
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        if !hb_orm_isnull("ListOfAttributes","Attribute_BoundLower")
                                            l_cHtml += ListOfAttributes->Attribute_BoundLower
                                        endif
                                    l_cHtml += [</td>]

                                    // Bound<br>Upper
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        if !hb_orm_isnull("ListOfAttributes","Attribute_BoundUpper")
                                            l_cHtml += ListOfAttributes->Attribute_BoundUpper
                                        endif
                                    l_cHtml += [</td>]

                                    // Description
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfAttributes->Attribute_Description,""))
                                    l_cHtml += [</td>]

                                    if l_nNumberOfCustomFieldValues > 0
                                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                            l_cHtml += CustomFieldsBuildGridOther(ListOfAttributes->pk,l_hOptionValueToDescriptionMapping)
                                        l_cHtml += [</td>]
                                    endif

                                l_cHtml += [</tr>]
                            endscan
                            l_cHtml += [</table>]
                            
                        l_cHtml += [</div>]
                    l_cHtml += [</div>]

                endif

            l_cHtml += [</div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

            l_cHtml += [<div id="DetailType2"]+iif(l_nActiveTabNumber <> 2,[ style="display: none;"],[])+[ class="m-3]+iif(l_nNumberOfRelatedEntities > 0,[ form-check form-switch],[])+[">]
                if l_nNumberOfRelatedEntities <= 0
                    l_cHtml += [<div class="mb-2">]+oFcgi:p_ANFEntity+[ has no related ]+oFcgi:p_ANFEntities+[</div>]
                else
                    //---------------------------------------------------------------------------
                    if l_nAccessLevelML >= 4
                        l_cHtml += [<div class="mb-3"><button id="ButtonSaveLayoutAndSelectedEntities" class="btn btn-primary rounded" onclick="]
                        l_cHtml += [$('#TextNodePositions').val( JSON.stringify(getPositions(network) );]
                        l_cHtml += [$('#ActionOnSubmit').val('UpdateEntitySelectionAndSaveLayout');document.form.submit();]
                        l_cHtml += [">Update ]+oFcgi:p_ANFEntity+[ selection and Save Layout</button></div>]
                    endif

                    //---------------------------------------------------------------------------
                    l_cHtml += [<table class="">]
                    select ListOfRelatedEntities
                    scan all
                        l_cHtml += [<tr><td>]
                            l_CheckBoxId := "CheckEntity"+Trans(ListOfRelatedEntities->Entity_pk)
                            if !empty(l_cListOfRelatedEntityPks)
                                l_cListOfRelatedEntityPks += "*"
                            endif
                            l_cListOfRelatedEntityPks += Trans(ListOfRelatedEntities->Entity_pk)

                            l_cHtml += [<input type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+;
                                      iif( ((l_nNumberOfEntitiesInDiagram <= 0) .or. VFP_Seek(ListOfRelatedEntities->Entity_pk,"ListOfCurrentEntitiesInModelingDiagram","pk")) ," checked","");
                                      +[ class="form-check-input">]

                            l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+[">]

                            l_cPackageFullName := ListOfRelatedEntities->Package_FullName
                            l_cEntityName      := ListOfRelatedEntities->Entity_Name
                            if !empty(l_cPackageFullName)
                                l_cHtml += l_cPackageFullName+" / "+l_cEntityName
                            else
                                l_cHtml += l_cEntityName
                            endif

                            l_cHtml += [</label>]

                        l_cHtml += [</td></tr>]
                    endscan

                    l_cHtml += [</table>]

                    l_cHtml += [<input type="hidden" name="TextListOfRelatedEntityPks" value="]+l_cListOfRelatedEntityPks+[">]
                endif
            l_cHtml += [</div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

            l_cHtml += [<div id="DetailType3"]+iif(l_nActiveTabNumber <> 3,[ style="display: none;"],[])+[ class="m-3">]
                if l_nNumberOfOtherModelingDiagram <= 0
                    l_cHtml += [<div class="mb-2">Entity is not used in other diagrams</div>]
                else
                    select ListOfOtherModelingDiagram
                    scan all
                        l_cHtml += [<div class="mb-2"><a class="link-primary" href="?InitialDiagram=]+ListOfOtherModelingDiagram->ModelingDiagram_LinkUID+[" onclick="$('#TextModelingDiagramPk').val(]+Trans(ListOfOtherModelingDiagram->ModelingDiagram_pk)+[);$('#ActionOnSubmit').val('Show');document.form.submit();">]+ListOfOtherModelingDiagram->ModelingDiagram_Name+[</a></div>]
                    endscan
                endif
            l_cHtml += [</div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

            l_cHtml += [<div id="DetailType4"]+iif(l_nActiveTabNumber <> 4,[ style="display: none;"],[])+[ class="m-3">]
                //---------------------------------------------------------------------------
                l_cHtml += [<div class="mb-3"><button id="ButtonSaveLayoutAndDeleteEntity" class="btn btn-primary rounded" onclick="]
                l_cHtml += [network.storePositions();]
                l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
                l_cHtml += [$('#ActionOnSubmit').val('RemoveEntityAndSaveLayout');document.form.submit();]
                l_cHtml += [">Remove ]+oFcgi:p_ANFEntity+[ and Save Layout</button></div>]
                //---------------------------------------------------------------------------
                l_cHtml += [<input type="hidden" name="TextEntityPkToRemove" value="]+Trans(l_iEntityPk)+[">]

                if !empty(l_cEntityDescription)
                    l_cHtml += [<div class="mt-3"><div class="fs-5">Description:</div>]+TextToHTML(l_cEntityDescription)+[</div>]
                endif

                if !empty(l_cEntityInformation)
                    l_cHtml += [<div class="mt-3">]
                        l_cHtml += [<div class="fs-5">Information:</div>]

                        l_cObjectId := "entity-description"+Trans(l_iEntityPk)
                        l_cHtml += [<div id="]+l_cObjectId+[">]
                        l_cHtml += [<script> document.getElementById(']+l_cObjectId+[').innerHTML = marked.parse(']+EscapeNewlineAndQuotes(l_cEntityInformation)+[');</script>]
                        l_cHtml += [</div>]
                    l_cHtml += [</div>]
                endif

                if !empty(l_cHtml_EntityCustomFields)
                    l_cHtml += [<div class="mt-3">]
                        l_cHtml += l_cHtml_EntityCustomFields
                    l_cHtml += [</div>]
                endif

            l_cHtml += [</div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

        endif

    case l_cGraphItemType == "A"
        //Clicked on an Association
        l_cHtml += GetMLInfoDuringVisualization_AssociationInfo(l_iAssociationPk,0)

    otherwise
        l_cHtml += [<div  class="alert alert-danger" role="alert m-3">Could not find information.</div>]

    endcase

else
    l_aEdges := hb_HGetDef(l_hOnClickInfo,"edges",{})
    if len(l_aEdges) > 0  // If there are multiple edges, meaning like a double arrow, if will only return 1. Have to walk through the "items" instead.
        // l_iAttributePk := l_aEdges[1]

        l_aItems := hb_HGetDef(l_hOnClickInfo,"items",{})
        l_nEdgeNumber := len(l_aItems)

        l_oDB_InArray := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_InArray

            for l_nEdgeCounter := 1 to l_nEdgeNumber

                l_cNode := hb_HGetDef(l_aItems[l_nEdgeCounter],"edgeId","")

                switch left(l_cNode,1)
                case "L"  // (Endpoint Key) with more than 2 Endpoints
                    l_cGraphItemType := "L"
                    l_iEndpointPk    := val(substr(l_cNode,2))

                    with object l_oDB_Project
                        :Table("12c4ced7-4057-43df-b829-f66235d80dfa","Endpoint")
                        :Column("Project.pk"              , "Project_pk")
                        :Column("Endpoint.fk_Association" , "Association_pk")
                        :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
                        :Join("inner","Model","","Entity.fk_Model = Model.pk")
                        :Join("inner","Project","","Model.fk_Project = Project.pk")
                        l_oData_Project := :Get(l_iEndpointPk)
                        if :Tally == 1
                            l_iAssociationPk := l_oData_Project:Association_pk

                            l_cHtml += GetMLInfoDuringVisualization_AssociationInfo(l_iAssociationPk,l_iEndpointPk)
                        else
                            l_cHtml += [<div  class="alert alert-danger" role="alert m-3">Could not find association.</div>]
                        endif
                        l_cHtml += [<div class="m-3"></div>]
                    endwith
                    exit

                case "D"  // (Association Key) Build the edge between 2 entities
                    l_cGraphItemType := "D"
                    l_iEndpointPk    := 0
                    l_iAssociationPk := val(substr(l_cNode,2))

                    with object l_oDB_Project
                        :Table("b3161e35-02b4-4298-a214-4cc5a8bf121a","Association")
                        :Column("Project.pk" , "Project_pk")
                        :Join("inner","Model","","Association.fk_Model = Model.pk")
                        :Join("inner","Project","","Model.fk_Project = Project.pk")
                        l_oData_Project := :Get(l_iAssociationPk)
                        if :Tally == 1
                            l_cHtml += GetMLInfoDuringVisualization_AssociationInfo(l_iAssociationPk,l_iEndpointPk)
                        else
                            l_cHtml += [<div  class="alert alert-danger" role="alert m-3">Could not find association.</div>]
                        endif
                        l_cHtml += [<div class="m-3"></div>]
                    endwith
                    exit

                endcase

            endfor
        endwith
    endif
endif

return l_cHtml
//=================================================================================================================
static function GetMLInfoDuringVisualization_AssociationInfo(par_iAssociationPk,par_iEndpointPk)
local l_cHtml := []
local l_nNumberOfEndpoints

local l_cAssociationLinkUID
local l_cAssociationName
local l_cAssociationDescription
local l_nAssociationNumberOfEndpoints

local l_nNumberOfCustomFieldValues
local l_hOptionValueToDescriptionMapping := {=>}
local l_cHtml_AssociationCustomFields := ""
local l_aSQLResult := {}

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cPackageFullName
local l_cZoomInfo

local l_oDB_ListOfEndpoints
local l_oDB_AssociationCustomFields
local l_oDB_InArray

//Get the list of Endpoints
l_oDB_ListOfEndpoints := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_ListOfEndpoints
    :Table("775ba9b5-c96e-457f-bd74-b1c67a4d2ab8","Endpoint")
    :Column("Endpoint.pk"                    , "Endpoint_pk")
    :Column("Endpoint.Fk_Entity"             , "Endpoint_fk_Entity")
    :Column("Endpoint.Name"                  , "Endpoint_Name")
    :Column("Endpoint.BoundLower"            , "Endpoint_BoundLower")
    :Column("Endpoint.BoundUpper"            , "Endpoint_BoundUpper")
    :Column("Endpoint.IsContainment"         , "Endpoint_IsContainment")
    :Column("Endpoint.Description"           , "Endpoint_Description")
    :Column("Package.FullName"               , "Package_FullName")
    :Column("Entity.Name"                    , "Entity_Name")
    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
    :Column("upper(Entity.Name)"             , "tag2")
    :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
    :Join("left","Package","","Entity.fk_Package = Package.pk") 
    :Where("Endpoint.fk_Association = ^" , par_iAssociationPk)
    if !empty(par_iEndpointPk)
        :Where("Endpoint.pk = ^" , par_iEndpointPk)
    endif
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfEndpoints")
    l_nNumberOfEndpoints := :Tally

endwith

l_oDB_AssociationCustomFields := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_AssociationCustomFields
    // Get the Association Custom Fields
    :Table("808c060e-bc43-4533-bb87-a989d272e93b","CustomFieldValue")
    :Distinct(.t.)
    :Column("CustomField.pk"              ,"CustomField_pk")
    :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
    :Join("inner","CustomField","","CustomFieldValue.fk_CustomField = CustomField.pk")
    :Where("CustomFieldValue.fk_Entity = ^",par_iAssociationPk)
    :Where("CustomField.UsedOn = ^",USEDON_ASSOCIATION)
    :Where("CustomField.Status <= 2")
    :Where("CustomField.Type = 2")   // Multi Choice
    :SQL("ListOfCustomFieldOptionDefinition")
    if :Tally > 0
        CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
    endif

    :Table("821df2b3-d34c-42a4-af27-1afd25959614","CustomFieldValue")
    :Column("CustomFieldValue.fk_Entity","fk_entity")
    :Column("CustomField.pk"            ,"CustomField_pk")
    :Column("CustomField.Label"         ,"CustomField_Label")
    :Column("CustomField.Type"          ,"CustomField_Type")
    :Column("CustomFieldValue.ValueI"   ,"CustomFieldValue_ValueI")
    :Column("CustomFieldValue.ValueM"   ,"CustomFieldValue_ValueM")
    :Column("CustomFieldValue.ValueD"   ,"CustomFieldValue_ValueD")
    :Column("upper(CustomField.Name)"   ,"tag1")
    :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
    :Where("CustomFieldValue.fk_Entity = ^",par_iAssociationPk)
    :Where("CustomField.UsedOn = ^",USEDON_ASSOCIATION)
    :Where("CustomField.Status <= 2")
    :OrderBy("tag1")
    :SQL("ListOfCustomFieldValues")
    l_nNumberOfCustomFieldValues := :Tally
    
    if l_nNumberOfCustomFieldValues > 0
        l_cHtml_AssociationCustomFields := CustomFieldsBuildGridOther(par_iAssociationPk,l_hOptionValueToDescriptionMapping)
    endif

endwith

l_oDB_InArray := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_InArray
    :Table("82763b38-3f40-43f2-aa32-72939f867a95","Association")
    :Column("Association.LinkUID"           ,"Association_LinkUID")             // 1
    :Column("Package.FullName"              ,"Package_FullName")                // 2
    :Column("Association.Name"              ,"Association_Name")                // 3
    :Column("Association.Description"       ,"Association_Description")         // 4
    :Column("Association.NumberOfEndpoints" ,"Association_NumberOfEndpoints")   // 5
    // :join("inner","Model"  ,"","Association.fk_Model = Model.pk")
    // :join("inner","Project","","Model.fk_Project = Project.pk")
    :Join("left" ,"Package","","Association.fk_Package = Package.pk") 
    :Where("Association.pk = ^" , par_iAssociationPk)
    :SQL(@l_aSQLResult)
endwith

if l_oDB_InArray:Tally == 1
    l_cAssociationLinkUID           := AllTrim(l_aSQLResult[1,1])
    l_cPackageFullName              := nvl(l_aSQLResult[1,2],"")
    l_cAssociationName              := nvl(l_aSQLResult[1,3],"")
    l_cAssociationDescription       := nvl(l_aSQLResult[1,4],"")
    l_nAssociationNumberOfEndpoints := l_aSQLResult[1,5]

    if !empty(l_cPackageFullName)
        l_cZoomInfo := l_cPackageFullName+" / "+l_cAssociationName
    else
        l_cZoomInfo := l_cAssociationName
    endif

    l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]
    l_cHtml += MODELING_ASSOCIATION_NODE_BACKGROUND
    l_cHtml += [;">]

        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">]+oFcgi:p_ANFAssociation+[: ]+l_cZoomInfo+;
                            [<a class="ms-3" target="_blank" href="]+l_cSitePath+[Modeling/EditAssociation/]+l_cAssociationLinkUID+[/"><i class="bi bi-pencil-square"></i></a>]+;
                        [</span>]
        l_cHtml += [</div>]

    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]

    // -----------------------------------------------------------------------------------------------------------------------------------------

    l_cHtml += [<div class="m-3">]

        if !empty(l_cAssociationDescription)
            l_cHtml += [<div class="mt-3"><div class="fs-5">Description:</div>]+TextToHTML(l_cAssociationDescription)+[</div>]
        endif

        if !empty(l_cHtml_AssociationCustomFields)
            l_cHtml += [<div class="mt-3">]
                l_cHtml += l_cHtml_AssociationCustomFields
            l_cHtml += [</div>]
        endif

    l_cHtml += [</div>]

    // -----------------------------------------------------------------------------------------------------------------------------------------
    l_cHtml += [<div class="m-3"></div>]
    // -----------------------------------------------------------------------------------------------------------------------------------------
    l_cHtml += [<div class="m-3">]

        if l_nNumberOfEndpoints > 0 // Should always be the case since the node is visible.
            l_cHtml += [<div class="row">]  //  justify-content-center
                l_cHtml += [<div class="col-auto">]

                    l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                    l_cHtml += [<tr class="bg-info">]
                        l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFEntity+[</th>]
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Bound<br>Lower</th>]
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Bound<br>Upper</th>]
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Aspect<br>Of</th>]
                        l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                        l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [</tr>]

                    select ListOfEndpoints
                    scan all
                        l_cHtml += [<tr>]
                            // Entity
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += ListOfEndpoints->Entity_Name
                            l_cHtml += [</td>]

                            // Bound<br>Lower
                            l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                                l_cHtml += nvl(ListOfEndpoints->Endpoint_BoundLower,"")
                            l_cHtml += [</td>]

                            // Bound<br>Upper
                            l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                                l_cHtml += nvl(ListOfEndpoints->Endpoint_BoundUpper,"")
                            l_cHtml += [</td>]

                            // Aspect Of
                            l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                                l_cHtml += iif(ListOfEndpoints->Endpoint_IsContainment,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                            l_cHtml += [</td>]

                            // Name
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += nvl(ListOfEndpoints->Endpoint_Name,"")
                            l_cHtml += [</td>]

                            // Description
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += TextToHtml(hb_DefaultValue(ListOfEndpoints->Endpoint_Description,""))
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endscan
                    l_cHtml += [</table>]
                    
                l_cHtml += [</div>]
            l_cHtml += [</div>]

        endif

    l_cHtml += [</div>]

    // -----------------------------------------------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------------------------------

endif

return l_cHtml
//=================================================================================================================
