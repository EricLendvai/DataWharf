#include "DataWharf.ch"
memvar oFcgi

//This File is STILL UNDER DEVELOPMENT!!!

//=================================================================================================================
function ModelVisualizeDesignBuild(par_iProjectPk,par_cErrorText,par_iModelPk,par_cModelName,par_cModelLinkUID,par_cModelingDiagramLinkUID,par_iModelingDiagramPk)
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
local l_hCoordinate
local l_cNodeLabel
local l_nNumberOfEntityInModelingDiagram
local l_oDataModelingDiagram
local l_lNodeShowDescription
local l_cEntityDescription
local l_cAssociationDescription
local l_cDiagramInfoScale
local l_nDiagramInfoScale
local l_iModelingDiagramPk
local l_cPackage_FullName
local l_lShowPackage

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

local l_cJS

oFcgi:TraceAdd("ModelVisualizeDesignBuild")

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
    :Where("ModelingDiagram.fk_Model = ^" ,par_iModelPk)
    :OrderBy("Tag1")
    :SQL("ListOfModelingDiagrams")
endwith

with object l_oDB1
    if empty(par_iModelingDiagramPk)
        l_iModelingDiagramPk := ListOfModelingDiagrams->ModelingDiagram_pk
    else
        l_iModelingDiagramPk := par_iModelingDiagramPk
    endif

    :Table("5b855361-eb92-45cd-b4e0-ca6b6bea5dd2","ModelingDiagram")
    :Column("ModelingDiagram.VisPos"             ,"ModelingDiagram_VisPos")
    :Column("ModelingDiagram.NodeShowDescription","ModelingDiagram_NodeShowDescription")
    :Column("ModelingDiagram.LinkUID"            ,"ModelingDiagram_LinkUID")
    l_oDataModelingDiagram     := :Get(l_iModelingDiagramPk)
    l_cNodePositions           := l_oDataModelingDiagram:ModelingDiagram_VisPos
    l_lNodeShowDescription     := l_oDataModelingDiagram:ModelingDiagram_NodeShowDescription
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
        :Where("Entity.fk_Model = ^",par_iModelPk)
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
        :Where("Entity.fk_Model = ^",par_iModelPk)
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
        :Join("left","Package","","Entity.fk_Package = Package.pk")
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
        :Column("Endpoint.Description","Endpoint_Description")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Where("Entity.fk_Model = ^",par_iModelPk)
        :Where("Association.NumberOfEndpoints > 2")
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
        :Column("Endpoint.Description","Endpoint_Description")
        :Join("inner","Entity"   ,"","DiagramEntity.fk_Entity = Entity.pk")
        :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
        :Where("Association.NumberOfEndpoints > 2")
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
        :Column("Entity.pk"              ,"Entity_pk")
        :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
        :Join("inner","Entity"  ,"","Endpoint.fk_Entity = Entity.pk")
        :Where("Association.fk_Model = ^",par_iModelPk)
        :Where("Association.NumberOfEndpoints = 2")
        :OrderBy("Association_pk")
        // :OrderBy("Endpoint_pk")
        :SQL("ListOfEdgesEntityEntity")
        //Pairs of records should be created

 //ExportTableToHtmlFile("ListOfEdgesEntityEntity","d:\PostgreSQL_ListOfEdgesEntityEntity.html","From PostgreSQL",,25,.t.)

    else
        //_M_

        // A subset of Entities
        // :Table("DiagramEntity")
        // :Distinct(.t.)
        // :Column("Entity.pk"           ,"Entity_pk")
        // :Column("Association.pk"      ,"Association_pk")
        // :Column("Endpoint.pk"         ,"Endpoint_pk")
        // :Column("Endpoint.Name"       ,"Endpoint_Name")
        // :Column("Endpoint.Description","Endpoint_Description")
        // :Join("inner","Entity"   ,"","DiagramEntity.fk_Entity = Entity.pk")
        // :Join("inner","Endpoint","","Endpoint.fk_Entity = Entity.pk")
        // :Join("inner","Association","","Endpoint.fk_Association = Association.pk")
        // :Where("DiagramEntity.fk_ModelingDiagram = ^" , l_iModelingDiagramPk)
        // :Where("Association.NumberOfEndpoints = 2")
        // :SQL("ListOfEdgesEntityAssociationNode")

    endif
endwith



// l_cHtml += '<script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>'

if l_iCanvasWidth < CANVAS_WIDTH_MIN .or. l_iCanvasWidth > CANVAS_WIDTH_MAX
    l_iCanvasWidth := CANVAS_WIDTH_DEFAULT
endif

if l_iCanvasHeight < CANVAS_HEIGHT_MIN .or. l_iCanvasHeight > CANVAS_HEIGHT_MAX
    l_iCanvasHeight := CANVAS_HEIGHT_DEFAULT
endif

l_cHtml += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/vis_2021_11_11_001/vis-network.min.js"></script>]

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

            l_cHtml += [network.storePositions();]

            l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
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
l_cHtml += [<div id="mynetwork"></div>]
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
l_cHtml += 'var nodes = new vis.DataSet(['
select ListOfEntities
scan all
    if l_lShowPackage
        l_cNodeLabel := nvl(ListOfEntities->Package_FullName,"")
        if !empty(l_cNodeLabel)
            l_cNodeLabel += "\n"
        endif
    else
        l_cNodeLabel := ""
    endif

    l_cNodeLabel += AllTrim(ListOfEntities->Entity_Name)

    if hb_orm_isnull("ListOfEntities","Entity_Description")
        l_cEntityDescription := ""
    else
        l_cEntityDescription := hb_StrReplace(ListOfEntities->Entity_Description,{[\]     => [\\],;
                                                                              chr(10) => [],;
                                                                              chr(13) => [\n],;
                                                                              ["]     => [\"],;
                                                                              [']     => [\']} )
    endif

    if empty(l_cEntityDescription)
        l_cHtml += [{id:"E]+Trans(ListOfEntities->pk)+[",label:"]+l_cNodeLabel+["]
    else
        if l_lNodeShowDescription
            l_cHtml += [{id:"E]+Trans(ListOfEntities->pk)+[",label:"]+l_cNodeLabel+[\n]+l_cEntityDescription+["]
        else
            if l_lNeverShowDescriptionOnHover
                l_cHtml += [{id:"E]+Trans(ListOfEntities->pk)+[",label:"]+l_cNodeLabel+["]
            else
                l_cHtml += [{id:"E]+Trans(ListOfEntities->pk)+[",label:"]+l_cNodeLabel+[",title:"]+l_cEntityDescription+["]
            endif
        endif
    endif

    l_cHtml += [,color:{background:'#]+MODELING_ENTITY_NODE_BACKGROUND+[',highlight:{background:'#]+MODELING_ENTITY_NODE_HIGHLIGHT+[',border:'#]+SELECTED_NODE_BORDER+['}}]

    if l_nLengthDecoded > 0
        l_hCoordinate := hb_HGetDef(l_hNodePositions,"E"+Trans(ListOfEntities->pk),{=>})
        if len(l_hCoordinate) > 0
            l_cHtml += [,x:]+Trans(l_hCoordinate["x"])+[,y:]+Trans(l_hCoordinate["y"])
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
    if l_lShowPackage
        l_cNodeLabel := nvl(ListOfAssociationNodes->Package_FullName,"")
        if !empty(l_cNodeLabel)
            l_cNodeLabel += "\n"
        endif
    else
        l_cNodeLabel := ""
    endif

    l_cNodeLabel += AllTrim(ListOfAssociationNodes->Association_Name)

    if hb_orm_isnull("ListOfAssociationNodes","Association_Description")
        l_cAssociationDescription := ""
    else
        l_cAssociationDescription := hb_StrReplace(ListOfAssociationNodes->Association_Description,{[\]     => [\\],;
                                                                              chr(10) => [],;
                                                                              chr(13) => [\n],;
                                                                              ["]     => [\"],;
                                                                              [']     => [\']} )
    endif

    if empty(l_cAssociationDescription)
        l_cHtml += [{id:"A]+Trans(ListOfAssociationNodes->pk)+[",label:"]+l_cNodeLabel+["]
    else
        if l_lNodeShowDescription
            l_cHtml += [{id:"A]+Trans(ListOfAssociationNodes->pk)+[",label:"]+l_cNodeLabel+[\n]+l_cAssociationDescription+["]
        else
            if l_lNeverShowDescriptionOnHover
                l_cHtml += [{id:"A]+Trans(ListOfAssociationNodes->pk)+[",label:"]+l_cNodeLabel+["]
            else
                l_cHtml += [{id:"A]+Trans(ListOfAssociationNodes->pk)+[",label:"]+l_cNodeLabel+[",title:"]+l_cAssociationDescription+["]
            endif
        endif
    endif

    l_cHtml += [,shape: "diamond",color:{background:'#]+MODELING_ASSOCIATION_NODE_BACKGROUND+[',highlight:{background:'#]+MODELING_ASSOCIATION_NODE_HIGHLIGHT+[',border:'#]+SELECTED_NODE_BORDER+['}}]

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

l_cHtml += ']);'

//SendToClipboard(l_cHtml)

//_M_
// create an array with edges

l_cHtml += 'var edges = new vis.DataSet(['

//_M_
select ListOfEdgesEntityAssociationNode
scan all
    l_cHtml += [{id:"L]+Trans(ListOfEdgesEntityAssociationNode->Endpoint_pk)+[",from:"A]+Trans(ListOfEdgesEntityAssociationNode->Association_pk)+[",to:"E]+Trans(ListOfEdgesEntityAssociationNode->Entity_pk)+["]  // ,arrows:"middle"
    l_cHtml += [,color:{color:'#]+MODELING_EDGE_BACKGROUND+[',highlight:'#]+MODELING_EDGE_HIGHLIGHT+['}]
    // l_cHtml += [, smooth: { type: "diagonalCross" }]
    l_cHtml += [},]  //,physics: false , smooth: { type: "cubicBezier" }
endscan

select ListOfEdgesEntityEntity
//Pairs of records should have been created
l_iAssociationPk_Previous := 0
l_iEntityPk_Previous      := 0
l_iEntityPk_Current       := 0
// Altd()
scan all
    if ListOfEdgesEntityEntity->Association_pk == l_iAssociationPk_Previous
        //Build the edge between 2 entities
        l_iEntityPk_Current := ListOfEdgesEntityEntity->Entity_pk

        l_cHtml += [{id:"D]+Trans(l_iAssociationPk_Previous)+[",from:"E]+Trans(l_iEntityPk_Previous)+[",to:"E]+Trans(l_iEntityPk_Current )+["]  // ,arrows:"middle"
        l_cHtml += [,color:{color:'#]+MODELING_EDGE_BACKGROUND+[',highlight:'#]+MODELING_EDGE_HIGHLIGHT+['}]
        // l_cHtml += [, smooth: { type: "diagonalCross" }]
        l_cHtml += [},]  //,physics: false , smooth: { type: "cubicBezier" }

        l_iAssociationPk_Previous := 0
    else
        l_iAssociationPk_Previous := ListOfEdgesEntityEntity->Association_pk
        l_iEntityPk_Previous      := ListOfEdgesEntityEntity->Entity_pk
    endif
endscan

        // :Table("Association")
        // :Column("Association.pk"         ,"Association_pk")
        // :Column("Association.Name"       ,"Association_Name")
        // :Column("Association.Description","Association_Description")
        // :Column("Endpoint.pk"            ,"Endpoint_pk")
        // :Column("Endpoint.Name"          ,"Endpoint_Name")
        // :Column("Endpoint.Description"   ,"Endpoint_Description")
        // :Column("Endpoint.BoundLower"    ,"Endpoint_BoundLower")
        // :Column("Endpoint.BoundUpper"    ,"Endpoint_BoundUpper")
        // :Column("Entity.pk"              ,"Entity_pk")
        // :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
        // :Join("inner","Entity"  ,"","Endpoint.fk_Entity = Entity.pk")
        // :Where("Association.fk_Model = ^",par_iModelPk)
        // :Where("Association.NumberOfEndpoints = 2")
        // :OrderBy("Association.pk")
        // :SQL("ListOfEdgesEntityEntity")

l_cHtml += ']);'

// create a network
l_cHtml += [  var container = document.getElementById("mynetwork");]

l_cHtml += [  var data = {]
l_cHtml += [    nodes: nodes,]
l_cHtml += [    edges: edges,]
l_cHtml += [  };]

l_cHtml += [  var options = {nodes:{shape:"box",margin:12,physics:false},]
l_cHtml +=                  [edges:{physics:false},]   // ,selectionWidth: 2
if l_lNavigationControl
    l_cHtml +=              [interaction:{navigationButtons:true},]
endif
l_cHtml +=                  [};]

l_cHtml += [  network = new vis.Network(container, data, options);]  //var

l_cHtml += ' network.on("click", function (params) {'
l_cHtml += '   params.event = "[original event]";'

//_M_
// Code to filter Attributes
l_cJS := [$("#AttributeSearch").change(function() {]
l_cJS +=    [var l_keywords =  $(this).val();]
l_cJS +=    [$(".SpanAttributeName").each(function (par_SpanEntity){]+;
                                                           [var l_cApplicationName = $(this).text();]+;
                                                           [if (KeywordSearch(l_keywords,l_cApplicationName)) {$(this).parent().parent().parent().show();} else {$(this).parent().parent().parent().hide();}]+;
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
l_cJS += [$("#ButtonShowAll").click(function(){$("#AttributeSearch").val("");$(".AttributeNotCore").show(),$(".AttributeCore").show();});]
l_cJS += [$("#ButtonShowCoreOnly").click(function(){$("#AttributeSearch").val("");$(".AttributeNotCore").hide(),$(".AttributeCore").show();});]

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
function ModelVisualizeDesignOnSubmit(par_iProjectPk,par_cErrorText,par_iModelPk,par_cModelName,par_cModelLinkUID,par_cModelingDiagramLinkUID)
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

oFcgi:TraceAdd("ModelVisualizeDesignOnSubmit")

l_iModelingDiagram_pk := Val(oFcgi:GetInputValue("TextModelingDiagramPk"))

do case
case l_cActionOnSubmit == "Show"
    l_cHtml += ModelVisualizeDesignBuild(par_iProjectPk,par_cErrorText,par_iModelPk,par_cModelName,par_cModelLinkUID,par_cModelingDiagramLinkUID,l_iModelingDiagram_pk)

// case l_cActionOnSubmit == "DiagramSettings" .and. oFcgi:p_nAccessLevelML >= 4
//     l_cHtml := ModelVisualizeDiagramSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)

// case l_cActionOnSubmit == "MyDiagramSettings" .and. oFcgi:p_nAccessLevelML >= 4
//     l_cHtml := ModelVisualizeMyDiagramSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)

// case l_cActionOnSubmit == "NewDiagram" .and. oFcgi:p_nAccessLevelML >= 4
//     l_cHtml := ModelVisualizeDiagramSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,0)

case ("SaveLayout" $ l_cActionOnSubmit) .and. oFcgi:p_nAccessLevelML >= 4
    l_cNodePositions  := Strtran(SanitizeInput(oFcgi:GetInputValue("TextNodePositions")),[%22],["])
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

    with object l_oDB1
        :Table("52aff222-451d-4726-849f-e17dbf4ab3a3","ModelingDiagram")
        :Field("ModelingDiagram.VisPos",l_cNodePositions)
        if empty(l_iModelingDiagram_pk)
            //Add an initial Diagram File this should not happen, since record was already added
            :Field("ModelingDiagram.fk_Model",par_iModelPk)
            :Field("ModelingDiagram.Name"    ,[All ]+oFcgi:p_ANFEntities)
            :Field("ModelingDiagram.LinkUID" ,oFcgi:p_o_SQLConnection:GetUUIDString())
            if :Add()
                l_iModelingDiagram_pk := :Key()
            endif
        else
            :Update(l_iModelingDiagram_pk)
        endif
    endwith

    // if "UpdateEntitySelection" $ l_cActionOnSubmit
    //     l_cListOfRelatedEntityPks := SanitizeInput(oFcgi:GetInputValue("TextListOfRelatedEntityPks"))
    //     l_aListOfRelatedEntityPks := hb_ATokens(l_cListOfRelatedEntityPks,"*")
    //     if len(l_aListOfRelatedEntityPks) > 0
    //         // Get the current list of Entities

    //         with Object l_oDB1
    //             :Table("DiagramEntity")
    //             :Distinct(.t.)
    //             :Column("Entity.pk","pk")
    //             :Column("DiagramEntity.pk","DiagramEntity_pk")
    //             :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
    //             :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
    //             :Where("DiagramEntity.fk_Diagram = ^" , l_iModelingDiagram_pk)
    //             :SQL("ListOfCurrentEntitiesInModelingDiagram")
    //             l_nNumberOfCurrentEntitiesInDiagram := :Tally
    //             if l_nNumberOfCurrentEntitiesInDiagram > 0
    //                 with object :p_oCursor
    //                     :Index("pk","pk")
    //                     :CreateIndexes()
    //                     :SetOrder("pk")
    //                 endwith        
    //             endif
    //         endwith
    //         if l_nNumberOfCurrentEntitiesInDiagram < 0
    //             //Failed to get current list of Entities in the diagram
    //         else
    //             if empty(l_nNumberOfCurrentEntitiesInDiagram)
    //                 //Implicitly all Entities are in the diagram. So should formally add all of them except the unselected ones.
    //                 l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 with object l_oDB2
    //                     :Table("Diagram")
    //                     :Column("Entity.pk" , "Entity_pk")
    //                     :Where("Diagram.pk = ^" , l_iModelingDiagram_pk)
    //                     :Join("Inner","NameSpace","","NameSpace.fk_Application = Diagram.fk_Application")
    //                     :Join("Inner","Entity","","Entity.fk_NameSpace = NameSpace.pk")
    //                     :SQL("ListOfAllApplicationEntity")
    //                     if :Tally > 0
    //                         select ListOfAllApplicationEntity
    //                         scan all
    //                             if "*"+Trans(ListOfAllApplicationEntity->Entity_pk)+"*" $ "*" +l_cListOfRelatedEntityPks+ "*"  //One of the related Entities
    //                                 // "CheckEntity"
    //                                 l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllApplicationEntity->Entity_pk)) == "1")
    //                             else
    //                                 l_lSelected := .t.
    //                             endif
    //                             if l_lSelected
    //                                 with object l_oDB3
    //                                     :Table("DiagramEntity")
    //                                     :Field("DiagramEntity.fk_Diagram" , l_iModelingDiagram_pk)
    //                                     :Field("DiagramEntity.fk_Entity"   , ListOfAllApplicationEntity->Entity_pk)
    //                                     :Add()
    //                                 endwith
    //                             endif
    //                         endscan
    //                     endif
    //                 endwith

    //             else
    //                 //Add or remove only the related Entities that were listed.
    //                 l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 for each l_cEntityPk in l_aListOfRelatedEntityPks
    //                     l_lSelected := (oFcgi:GetInputValue("CheckEntity"+l_cEntityPk) == "1")

    //                     if l_lSelected
    //                         if !VFP_Seek(val(l_cEntityPk),"ListOfCurrentEntitiesInModelingDiagram","pk")
    //                             //Add if not present
    //                             with object l_oDB3
    //                                 :Table("DiagramEntity")
    //                                 :Field("DiagramEntity.fk_Diagram" , l_iModelingDiagram_pk)
    //                                 :Field("DiagramEntity.fk_Entity"   , val(l_cEntityPk))
    //                                 :Add()
    //                             endwith
    //                         endif
    //                     else
    //                         if VFP_Seek(val(l_cEntityPk),"ListOfCurrentEntitiesInModelingDiagram","pk")
    //                             //Remove if present
    //                             l_oDB3:Delete("DiagramEntity",ListOfCurrentEntitiesInModelingDiagram->ModelingDiagramEntity_pk)
    //                         endif
    //                     endif

    //                 endfor
    //             endif
    //         endif

    //     endif
    // endif

    // if "RemoveEntity" $ l_cActionOnSubmit
    //     l_iEntityPk := val(oFcgi:GetInputValue("TextEntityPkToRemove"))
    //     if l_iEntityPk > 0
    //         // Get the current list of Entities

    //         with Object l_oDB1
    //             :Table("DiagramEntity")
    //             :Distinct(.t.)
    //             :Column("Entity.pk","pk")
    //             :Column("DiagramEntity.pk","DiagramEntity_pk")
    //             :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
    //             :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
    //             :Where("DiagramEntity.fk_Diagram = ^" , l_iModelingDiagram_pk)
    //             :SQL("ListOfCurrentEntitiesInModelingDiagram")
    //             l_nNumberOfCurrentEntitiesInDiagram := :Tally
    //             if l_nNumberOfCurrentEntitiesInDiagram > 0
    //                 with object :p_oCursor
    //                     :Index("pk","pk")
    //                     :CreateIndexes()
    //                     :SetOrder("pk")
    //                 endwith        
    //             endif
    //         endwith
    //         if l_nNumberOfCurrentEntitiesInDiagram < 0
    //             //Failed to get current list of Entities in the diagram
    //         else
    //             if empty(l_nNumberOfCurrentEntitiesInDiagram)
    //                 //Implicitly all Entities are in the diagram. So should formally add all of them except the the current one.
    //                 l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 with object l_oDB2
    //                     :Table("Diagram")
    //                     :Column("Entity.pk" , "Entity_pk")
    //                     :Where("Diagram.pk = ^" , l_iModelingDiagram_pk)
    //                     :Join("Inner","NameSpace","","NameSpace.fk_Application = Diagram.fk_Application")
    //                     :Join("Inner","Entity","","Entity.fk_NameSpace = NameSpace.pk")
    //                     :SQL("ListOfAllApplicationEntity")
    //                     if :Tally > 0
    //                         select ListOfAllApplicationEntity
    //                         scan all
    //                             if ListOfAllApplicationEntity->Entity_pk <> l_iEntityPk
    //                                 with object l_oDB3
    //                                     :Table("DiagramEntity")
    //                                     :Field("DiagramEntity.fk_Diagram" , l_iModelingDiagram_pk)
    //                                     :Field("DiagramEntity.fk_Entity"   , ListOfAllApplicationEntity->Entity_pk)
    //                                     :Add()
    //                                 endwith
    //                             endif
    //                         endscan
    //                     endif
    //                 endwith

    //             else
    //                 //Remove only the current Entities.
    //                 l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //                 if VFP_Seek(l_iEntityPk,"ListOfCurrentEntitiesInModelingDiagram","pk")
    //                     //Remove if still present
    //                     l_oDB3:Delete("DiagramEntity",ListOfCurrentEntitiesInModelingDiagram->ModelingDiagramEntity_pk)
    //                 endif
    //             endif
    //         endif

    //     endif
    // endif

    l_cHtml += ModelVisualizeDesignBuild(par_iProjectPk,;
                                            "",;
                                            par_iModelPk,;
                                            par_cModelName,;
                                            par_cModelLinkUID,;
                                            par_cModelingDiagramLinkUID,;                              //l_oDataHeader:par_cModelingDiagramLinkUID
                                            l_iModelingDiagram_pk)                                //l_oDataHeader:par_iModelingDiagramPk


endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ModelVisualizeDiagramSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,par_iModelingDiagramPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")
local l_hValues      := hb_DefaultValue(par_hValues,{=>})
local l_CheckBoxId
local l_lShowPackage
local l_cNameSpace_Name
local l_lNodeShowDescription

local l_oDB1
local l_oData

oFcgi:TraceAdd("ModelVisualizeDiagramSettingsBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

if pcount() < 6
    if par_iModelingDiagramPk > 0
        // Initial Build, meaning not from a failing editing
        with object l_oDB1
            //Get current Diagram Name
            :Table("a9d0a31d-e5ca-44a4-979f-7c6f1f1cf395","Diagram")
            :Column("Diagram.name"               ,"Diagram_name")
            :Column("Diagram.NodeShowDescription","Diagram_NodeShowDescription")
            l_oData := :Get(par_iModelingDiagramPk)
            if :Tally == 1
                l_hValues["Name"]                := l_oData:Diagram_name
                l_hValues["NodeShowDescription"] := l_oData:Diagram_NodeShowDescription
            endif

            //Get the current list of selected Entities
            :Table("cdd3a770-d3b0-4a00-8531-324ee83accc7","DiagramEntity")
            :Distinct(.t.)
            :Column("Entity.pk","pk")
            :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
            :Where("DiagramEntity.fk_Diagram = ^" , par_iModelingDiagramPk)
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

        l_lNodeShowDescription := hb_HGetDef(l_hValues,"NodeShowDescription",.f.)
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Node Entity Description</td>]
            l_cHtml += [<td class="pb-3"><div class="form-check form-switch">]
                l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="CheckNodeShowDescription" id="CheckNodeShowDescription" value="1"]+iif(l_lNodeShowDescription," checked","")+[ class="form-check-input">]
            l_cHtml += [</div></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]
//List all the Entities

l_lShowPackage := .f.

with Object l_oDB1
    :Table("3b7ac84f-ceef-4a2a-b5a6-1acb2ab480e6","Entity")
    :Column("Entity.pk"         ,"pk")
    :Column("NameSpace.Name"   ,"NameSpace_Name")
    :Column("Entity.Name"       ,"Entity_Name")
    :Column("Entity.Description","Entity_Description")
    :Column("Upper(NameSpace.Name)","tag1")
    :Column("Upper(Entity.Name)","tag2")
    :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfAllEntitiesInApplication")

    if :Tally > 0
        
        l_cHtml += [<div class="ms-3"><span>Filter on Entity Name</span><input type="text" id="EntitySearch" value="" size="40" class="ms-2"><span class="ms-3"> (Press Enter)</span></div>]

        l_cHtml += [<div class="m-3"></div>]

        if :Tally > 1  //Will only display NameSpace names if there are more than 1 name space used
            select ListOfAllEntitiesInApplication
            l_cNameSpace_Name := ListOfAllEntitiesInApplication->NameSpace_Name  //Get name from first record
            locate for ListOfAllEntitiesInApplication->NameSpace_Name <> l_cNameSpace_Name
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
                                                                           [var l_cApplicationName = $(this).text();]+;
                                                                           [if (KeywordSearch(l_keywords,l_cApplicationName)) {$(this).parent().parent().show();} else {$(this).parent().parent().hide();}]+;
                                                                           [});]
oFcgi:p_cjQueryScript += [});]

l_cHtml += [<div class="form-check form-switch">]
l_cHtml += [<table class="ms-5">]
select ListOfAllEntitiesInApplication
scan all
    l_CheckBoxId := "CheckEntity"+Trans(ListOfAllEntitiesInApplication->pk)
    l_cHtml += [<tr><td>]
        l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif( hb_HGetDef(l_hValues,"Entity"+Trans(ListOfAllEntitiesInApplication->pk),.f.)," checked","")+[ class="form-check-input">]
        l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+["><span class="SPANEntity">]+iif(l_lShowPackage,ListOfAllEntitiesInApplication->NameSpace_Name+[.],[])+ListOfAllEntitiesInApplication->Entity_Name
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
function ModelVisualizeDiagramSettingsOnSubmit(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode)
local l_cHtml := []

local l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")
local l_cNodePositions
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB3 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iModelingDiagram_pk
local l_cDiagram_Name
local l_lDiagram_NodeShowDescription
local l_cErrorMessage
local l_lSelected
local l_cValue
local l_hValues := {=>}

oFcgi:TraceAdd("ModelVisualizeDiagramSettingsOnSubmit")

l_iModelingDiagram_pk                  := Val(oFcgi:GetInputValue("TextModelingDiagramPk"))
l_cDiagram_Name                := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_lDiagram_NodeShowDescription := (oFcgi:GetInputValue("CheckNodeShowDescription") == "1")

do case
case l_cActionOnSubmit == "SaveDiagram"
    //Get all the Application Entities to help scan all the selection checkboxes.
    with Object l_oDB2
        :Table("67cfa8ab-7675-451d-9a68-09f7bd3654da","Entity")
        :Column("Entity.pk"         ,"pk")
        :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",par_iApplicationPk)
        :SQL("ListOfAllEntitiesInApplication")
    endwith

    do case
    case empty(l_cDiagram_Name)
        l_cErrorMessage := "Missing Name"
    otherwise
        with object l_oDB1
            :Table("60dafbab-0b7a-48cc-a49f-237ef6f34cee","Diagram")
            :Where([lower(replace(Diagram.Name,' ','')) = ^],lower(StrTran(l_cDiagram_Name," ","")))
            :Where([Diagram.fk_Application = ^],par_iApplicationPk)
            if l_iModelingDiagram_pk > 0
                :Where([Diagram.pk != ^],l_iModelingDiagram_pk)
            endif
            :SQL()
        endwith
        if l_oDB1:Tally <> 0
            l_cErrorMessage := "Duplicate Name"
        endif
    endcase

    if empty(l_cErrorMessage)
        with object l_oDB1
            :Table("78f6236c-9017-4098-8ad1-038e2643f343","Diagram")
            :Field("Diagram.Name"               ,l_cDiagram_Name)
            :Field("Diagram.NodeShowDescription",l_lDiagram_NodeShowDescription)
            if empty(l_iModelingDiagram_pk)
                :Field("Diagram.fk_Application",par_iApplicationPk)
                :Field("Diagram.UseStatus"     , 1)
                :Field("Diagram.DocStatus"     , 1)
                :Field("Diagram.LinkUID"       ,oFcgi:p_o_SQLConnection:GetUUIDString())
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
            :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
            :Where("DiagramEntity.fk_Diagram = ^" , l_iModelingDiagram_pk)
            :SQL("ListOfCurrentEntitiesInModelingDiagram")
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith        
        endwith

        select ListOfAllEntitiesInApplication
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllEntitiesInApplication->pk)) == "1")

            if VFP_Seek(ListOfAllEntitiesInApplication->pk,"ListOfCurrentEntitiesInModelingDiagram","pk")
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
                        :Field("DiagramEntity.fk_Entity"   ,ListOfAllEntitiesInApplication->pk)
                        :Field("DiagramEntity.fk_Diagram" ,l_iModelingDiagram_pk)
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
        l_cHtml += ModelVisualizeDesignBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)
    else
        l_hValues["Name"]                := l_cDiagram_Name
        l_hValues["NodeShowDescription"] := l_lDiagram_NodeShowDescription
        
        select ListOfAllEntitiesInApplication
        scan all
            l_lSelected := (oFcgi:GetInputValue("CheckEntity"+Trans(ListOfAllEntitiesInApplication->pk)) == "1")
            if l_lSelected  // No need to store the unselect references, since not having a reference will mean "not selected"
                l_hValues["Entity"+Trans(ListOfAllEntitiesInApplication->pk)] := .t.
            endif
        endscan
        l_cHtml := ModelVisualizeDiagramSettingsBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk,l_hValues)
    endif

case l_cActionOnSubmit == "Cancel"
    l_cHtml += ModelVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)

case l_cActionOnSubmit == "Delete"
    with object l_oDB1
        //Delete related records in DiagramEntity
        :Table("a317b1a2-0cad-48f9-8f0f-892af023c9d4","DiagramEntity")
        :Column("DiagramEntity.pk","pk")
        :Where("DiagramEntity.fk_Diagram = ^" , l_iModelingDiagram_pk)
        :SQL("ListOfDiagramEntityToDelete")
        select ListOfDiagramEntityToDelete
        scan all
            l_oDB2:Delete("1419a855-311f-410f-8ec1-ed5978b06cd6","DiagramEntity",ListOfDiagramEntityToDelete->pk)
        endscan
        l_oDB2:Delete("739927f0-d2cf-4ae2-99ae-88df9aa72fe2","ModelingDiagram",l_iModelingDiagram_pk)
    endwith
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"DataDictionaries/ApplicationVisualize/"+par_cURLApplicationLinkCode+"/")

case l_cActionOnSubmit == "ResetLayout"
    with object l_oDB1
        :Table("c8ef687c-a39b-4c4d-80e7-fa737a844832","ModelingDiagram")
        :Field("Diagram.VisPos",NIL)
        :Update(l_iModelingDiagram_pk)
    endwith
    l_cHtml += ModelVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
function ModelVisualizeMyDiagramSettingsBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,par_iModelingDiagramPk,par_hValues)
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

oFcgi:TraceAdd("ModelVisualizeMyDiagramSettingsBuild")

if pcount() < 6
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
function ModelVisualizeMyDiagramSettingsOnSubmit(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode)
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

oFcgi:TraceAdd("ModelVisualizeMyDiagramSettingsOnSubmit")

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
        l_cHtml += ModelVisualizeDesignBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)
    else
        l_hValues["DiagramInfoScale"] := l_nDiagramInfoScale

        l_cHtml := ModelVisualizeMyDiagramSettingsBuild(par_iApplicationPk,l_cErrorMessage,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk,l_hValues)
    endif

case l_cActionOnSubmit == "Cancel"
    l_cHtml += ModelVisualizeDesignBuild(par_iApplicationPk,par_cErrorText,par_cApplicationName,par_cURLApplicationLinkCode,l_iModelingDiagram_pk)

endcase

return l_cHtml
//=================================================================================================================
function GetMLInfoDuringVisualization()
return ""
//=================================================================================================================
function UNDER_DEVELOPMENT_GetMLInfoDuringVisualization()
local l_cHtml := []
local l_cInfo := Strtran(oFcgi:GetQueryString("info"),[%22],["])
local l_iModelingDiagram_pk := val(oFcgi:GetQueryString("modelingdiagrampk"))
local l_hOnClickInfo := {=>}
local l_nLengthDecoded
local l_aNodes
local l_aEdges
local l_aItems
local l_iEntityPk
local l_iAttributePk
local l_oDB_Project                      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_InArray                      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfRelatedEntities          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfCurrentEntitiesInModelingDiagram := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAttribute                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfOtherModelingDiagrams          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_EntityCustomFields            := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_UserAccessProject
local l_aSQLResult := {}
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cApplicationLinkCode
local l_cNameSpaceName
local l_cEntityName
local l_cEntityDescription
local l_cEntityInformation
local l_cAttributeName
local l_cAttributeDescription
local l_cFrom_NameSpace_Name
local l_cFrom_Entity_Name
local l_cTo_NameSpace_Name
local l_cTo_Entity_Name
local l_cRelatedEntitiesKey
local l_hRelatedEntities := {=>}
local l_aRelatedEntityInfo
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
local l_cHtml_tr_class
local l_iProjectPk
local l_nAccessLevelML

oFcgi:TraceAdd("GetMLInfoDuringVisualization")

hb_HKeepOrder(l_hRelatedEntities,.f.) // Will order the hash by its key, with will be entered as upper case. For Keys stored as Strings they will need to be the same length

// l_cHtml += [Hello World c2 - ]+hb_TtoS(hb_DateTime())+[  ]+l_cInfo

l_nLengthDecoded := hb_jsonDecode(l_cInfo,@l_hOnClickInfo)

// if l_hOnClickInfo["nodes"]  is an array. if len is 1 we have the Entity.pk
// if l_hOnClickInfo["nodes"] is a 0 size array and l_hOnClickInfo["edges"] array of len 1   will be Attribute.pk

// SendToDebugView("TabCookie = "+oFcgi:GetCookieValue("DiagramDetailTab"))

l_lNeverShowDescriptionOnHover := (GetUserSetting("NeverShowDescriptionOnHover") == "T")

l_aNodes := hb_HGetDef(l_hOnClickInfo,"nodes",{})
if len(l_aNodes) == 1
    l_iEntityPk := l_aNodes[1]

    with object l_oDB_Project
        :Table("aabe8f6a-1c2c-4828-a56b-43c26bd06091","Entity")
        :Column("Project.pk" , "Project_pk")
        :Join("inner","Model","","Entity.fk_Model = Model.pk")
        :Join("inner","Project","","Model.fk_Project = Project.pk")
        l_oData_Project := :Get(l_iEntityPk)
    endwith

    //Get the project l_nAccessLevelML
    l_iProjectPk := l_oData_Project:Project_pk
    do case
    case oFcgi:p_nUserAccessMode <= 1  // Project access levels
        l_oDB_UserAccessProject := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_UserAccessProject
            :Table("UserAccessProject")
            :Column("UserAccessProject.AccessLevelML" , "AccessLevelML")
            :Where("UserAccessProject.fk_User = ^"    , oFcgi:p_iUserPk)
            :Where("UserAccessProject.fk_Project = ^" ,l_iProjectPk)
            :SQL(@l_aSQLResult)
            if :Tally == 1
                l_nAccessLevelML := l_aSQLResult[1,1]
            else
                l_nAccessLevelML := 0
            endif
        endwith
    case oFcgi:p_nUserAccessMode  = 2  // All Project Read Only
        l_nAccessLevelML := 2
    case oFcgi:p_nUserAccessMode  = 3  // All Project Full Access
        l_nAccessLevelML := 7
    case oFcgi:p_nUserAccessMode  = 4  // Root Admin (User Control)
        l_nAccessLevelML := 7
    endcase


    //Clicked on a Entity

    // _M_ Refactor following code once orm supports unions and CTE (common Entity Expressions)

    //Current List of Entities in diagram
    with Object l_oDB_ListOfCurrentEntitiesInModelingDiagram
        :Table("8ce66c2d-e24a-44af-962b-0db5d5fc2f1c","DiagramEntity")
        :Distinct(.t.)
        :Column("Entity.pk","pk")
        :Column("DiagramEntity.pk","DiagramEntity_pk")
        :Join("inner","Entity","","DiagramEntity.fk_Entity = Entity.pk")
        :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
        :Where("DiagramEntity.fk_Diagram = ^" , l_iModelingDiagram_pk)
        :SQL("ListOfCurrentEntitiesInModelingDiagram")
        l_nNumberOfEntitiesInDiagram := :Tally
        if l_nNumberOfEntitiesInDiagram > 0
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
        endif
        // ExportTableToHtmlFile("ListOfCurrentEntitiesInModelingDiagram","d:\PostgreSQL_ListOfCurrentEntitiesInModelingDiagram.html","From PostgreSQL",,25,.t.)
    endwith


    with object l_oDB_ListOfAttribute
        :Table("aaf1a8ab-c0aa-46d7-b691-3448f203ca8c","Attribute")
        :Column("Attribute.pk"             ,"pk")
        :Column("Attribute.Name"           ,"Attribute_Name")
        :Column("Attribute.Description"    ,"Attribute_Description")
        :Column("Attribute.Order"          ,"Attribute_Order")
        :Column("Attribute.fk_DataType"    ,"Attribute_fk_DataType")
        
        :Column("NameSpace.Name"                ,"NameSpace_Name")
        :Column("Entity.Name"                    ,"Entity_Name")
        :Column("DataType.Name"              ,"DataType_Name")
        
        :Join("left","Entity"      ,"","Attribute.fk_EntityForeign = Entity.pk")
        :Join("left","NameSpace"  ,"","Entity.fk_NameSpace = NameSpace.pk")
        :Join("left","Enumeration","","Attribute.fk_Enumeration  = Enumeration.pk")
        :Where("Attribute.fk_Entity = ^",l_iEntityPk)
        :OrderBy("Attribute_Order")
        :SQL("ListOfAttributes")
        l_nNumberOfAttributes := :Tally
    endwith


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
    with object l_oDB_ListOfRelatedEntities
        // Parent Of
        :Table("69cff617-c3c9-4a51-a167-bb9f68cc99f9","Attribute")
        :Distinct(.t.)
        :Column("Entity.pk"       , "Entity_pk")
        :Column("NameSpace.Name" , "NameSpace_Name")
        :Column("Entity.Name"     , "Entity_Name")
        :Column("upper(NameSpace.Name)" , "tag1")
        :Column("upper(Entity.Name)"     , "tag2")
        :Where("Attribute.fk_EntityForeign = ^" , l_iEntityPk)
        :Join("inner","Entity","","Attribute.fk_Entity = Entity.pk")
        :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfRelatedEntities")
        if :Tally > 0
            select ListOfRelatedEntities
            scan all
                l_cRelatedEntitiesKey := padr(ListOfRelatedEntities->tag1,200)+padr(ListOfRelatedEntities->tag2,200)
                l_hRelatedEntities[l_cRelatedEntitiesKey] := {(l_nNumberOfEntitiesInDiagram <= 0) .or. VFP_Seek(ListOfRelatedEntities->Entity_pk,"ListOfCurrentEntitiesInModelingDiagram","pk"),;  // If Entity already included in diagram
                                                          ListOfRelatedEntities->Entity_pk,;
                                                          ListOfRelatedEntities->NameSpace_Name,;
                                                          ListOfRelatedEntities->Entity_Name,;
                                                          .t.,.f.}   // Parent Of, Child Of
            endscan
        endif

        // Child Of
        :Table("e9f08335-df25-47dd-abbc-2bf04f9306f1","Attribute")
        :Distinct(.t.)
        :Column("Entity.pk"       , "Entity_pk")
        :Column("NameSpace.Name" , "NameSpace_Name")
        :Column("Entity.Name"     , "Entity_Name")
        :Column("upper(NameSpace.Name)" , "tag1")
        :Column("upper(Entity.Name)"     , "tag2")
        :Where("Attribute.fk_Entity = ^" , l_iEntityPk)
        :Join("inner","Entity","","Attribute.fk_EntityForeign = Entity.pk")
        :Join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfRelatedEntities")

        if :Tally > 0
            select ListOfRelatedEntities
            scan all
                l_cRelatedEntitiesKey := padr(ListOfRelatedEntities->tag1,200)+padr(ListOfRelatedEntities->tag2,200)
                l_aRelatedEntityInfo := hb_HGetDef(l_hRelatedEntities,l_cRelatedEntitiesKey,{})
                if empty(len(l_aRelatedEntityInfo))
                    //The Entity was not already a "Parent Of"
                    l_hRelatedEntities[l_cRelatedEntitiesKey] := {(l_nNumberOfEntitiesInDiagram <= 0) .or. VFP_Seek(ListOfRelatedEntities->Entity_pk,"ListOfCurrentEntitiesInModelingDiagram","pk"),;  // If Entity already included in diagram
                                                              ListOfRelatedEntities->Entity_pk,;
                                                              ListOfRelatedEntities->NameSpace_Name,;
                                                              ListOfRelatedEntities->Entity_Name,;
                                                              .f.,;    // Parent Of
                                                              .t.  }   // Child Of    8th array element
                else
                    l_hRelatedEntities[l_cRelatedEntitiesKey][8] := .t.
                endif
            endscan
        endif

        l_nNumberOfRelatedEntities := len(l_hRelatedEntities)
        CloseAlias("ListOfRelatedEntities")   // Not really needed since orm will auto-close cursors, but still added this for clarity.
    endwith

    with object l_oDB_EntityCustomFields

        // Get the Entity Custom Fields
        :Table("24d38337-8b1c-4bfe-88e6-869ab00f4b68","CustomFieldValue")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
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
        :Column("Attribute.pk"              ,"fk_entity")
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

    with object l_oDB_InArray
        :Table("eaca66a4-e311-4e3e-a3c4-8ee000f15df4","Entity")
        :Column("Application.LinkCode","Application_LinkCode")  // 1
        :Column("NameSpace.name"      ,"NameSpace_Name")        // 2
        :Column("Entity.Name"          ,"Entity_Name")            // 3
        :Column("Entity.Description"   ,"Entity_Description")     // 5
        :join("inner","NameSpace","","Entity.fk_NameSpace = NameSpace.pk")
        :join("inner","Application","","NameSpace.fk_Application = Application.pk")
        :Where("Entity.pk = ^" , l_iEntityPk)
        :SQL(@l_aSQLResult)

        if :Tally == 1
            l_cApplicationLinkCode := AllTrim(l_aSQLResult[1,1])
            l_cNameSpaceName       := AllTrim(l_aSQLResult[1,2])
            l_cEntityName           := AllTrim(l_aSQLResult[1,3])
            l_cEntityDescription    := nvl(l_aSQLResult[1,5],"")

            l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]
            l_cHtml += MODELING_ENTITY_NODE_HIGHLIGHT
            l_cHtml += [;">]

                l_cHtml += [<div class="input-group">]
                    l_cHtml += [<span class="navbar-brand ms-3">Entity: ]+l_cNameSpaceName+;
                                [<a class="ms-3" target="_blank" href="]+l_cSitePath+[DataDictionaries/EditEntity/]+l_cApplicationLinkCode+"/"+l_cNameSpaceName+"/"+l_cEntityName+[/"><i class="bi bi-pencil-square"></i></a>]+;
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
                                                                [>Attributes (]+Trans(l_nNumberOfAttributes)+[)</a>]
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
                                                                [>Related Entities In App (]+Trans(l_nNumberOfRelatedEntities)+[)</a>]
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
                                                                [>Entity Info</a>]
                l_cHtml += [</li>]
            l_cHtml += [</ul>]

            l_cHtml += [<div class="m-3"></div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------
            l_cHtml += [<div id="DetailType1"]+iif(l_nActiveTabNumber <> 1,[ style="display: none;"],[])+[ class="m-3">]


                if l_nNumberOfAttributes <= 0
                    l_cHtml += [<div class="mb-2">Entity has no Attributes</div>]
                else
                    l_cHtml += [<div class="row">]  //  justify-content-center
                        l_cHtml += [<div class="col-auto">]

                            l_cHtml += [<div>]
                            l_cHtml += [<span>Filter on Attribute Name</span>]
                            l_cHtml += [<input type="text" id="AttributeSearch" value="" size="30" class="ms-2">]
                            l_cHtml += [<span class="ms-1"> (Press Enter)</span>]
                            l_cHtml += [<input type="button" id="ButtonShowAll" class="btn btn-primary rounded ms-3" value="All">]
                            l_cHtml += [<input type="button" id="ButtonShowCoreOnly" class="btn btn-primary rounded ms-3" value="Core Only">]
                            l_cHtml += [</div>]

                            l_cHtml += [<div class="m-3"></div>]

                            l_cHtml += [<table class="Entity Entity-sm Entity-bordered Entity-striped">]

                            l_cHtml += [<tr class="bg-info">]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                                if l_nNumberOfCustomFieldValues > 0
                                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                                endif
                            l_cHtml += [</tr>]

                            select ListOfAttributes
                            scan all
                                l_cHtml += [<tr>]

                                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]+l_cHtml_icon+[</td>]

                                    // Name
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        l_cHtml += [<a target="_blank" href="]+l_cSitePath+[DataDictionaries/EditAttribute/]+l_cApplicationLinkCode+"/"+l_cNameSpaceName+"/"+l_cEntityName+[/]+ListOfAttributes->Attribute_Name+[/"><span class="SpanAttributeName">]+ListOfAttributes->Attribute_Name+[</span></a>]
                                    l_cHtml += [</td>]

                                    // Foreign Key To
                                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                        if !hb_isNil(ListOfAttributes->Entity_Name)
                                            l_cHtml += [<a style="color:#]+COLOR_ON_LINK_NEWPAGE+[ !important;" target="_blank" href="]+l_cSitePath+[DataDictionaries/ListAttributes/]+l_cApplicationLinkCode+"/"+ListOfAttributes->NameSpace_Name+"/"+ListOfAttributes->Entity_Name+[/">]
                                            l_cHtml += ListOfAttributes->NameSpace_Name+[.]+ListOfAttributes->Entity_Name
                                            l_cHtml += [</a>]
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
                    l_cHtml += [<div class="mb-2">Entity has no related Entities</div>]
                else
                    //---------------------------------------------------------------------------
                    if l_nAccessLevelML >= 4
                        l_cHtml += [<div class="mb-3"><button id="ButtonSaveLayoutAndSelectedEntities" class="btn btn-primary rounded" onclick="]
                        l_cHtml += [network.storePositions();]
                        l_cHtml += [$('#TextNodePositions').val( JSON.stringify(network.getPositions()) );]
                        l_cHtml += [$('#ActionOnSubmit').val('UpdateEntitySelectionAndSaveLayout');document.form.submit();]
                        l_cHtml += [">Update Entity selection and Save Layout</button></div>]
                    endif
                    //---------------------------------------------------------------------------

                    // l_cHtml += [<h1>Related Entities</h1>]

                    l_cHtml += [<table class="">]

                    for each l_aRelatedEntityInfo in l_hRelatedEntities
                        l_cHtml += [<tr><td>]
                            l_CheckBoxId := "CheckEntity"+Trans(l_aRelatedEntityInfo[2])
                            if !empty(l_cListOfRelatedEntityPks)
                                l_cListOfRelatedEntityPks += "*"
                            endif
                            l_cListOfRelatedEntityPks += Trans(l_aRelatedEntityInfo[2])

                            // l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif(l_aRelatedEntityInfo[1]," checked","")+[ class="form-check-input">]
                            l_cHtml += [<input type="checkbox" name="]+l_CheckBoxId+[" id="]+l_CheckBoxId+[" value="1"]+iif(l_aRelatedEntityInfo[1]," checked","")+[ class="form-check-input">]

                            l_cHtml += [<label class="form-check-label" for="]+l_CheckBoxId+[">]

                            l_cHtml += l_aRelatedEntityInfo[3]+[.]+l_aRelatedEntityInfo[5]
                            if l_aRelatedEntityInfo[8]
                                l_cHtml += [<span class="bi bi-arrow-left ms-2">]
                            endif
                            if l_aRelatedEntityInfo[7]
                                l_cHtml += [<span class="bi bi-arrow-right ms-2">]
                            endif

                            l_cHtml += [</label>]

                        l_cHtml += [</td></tr>]
                    endfor

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
                l_cHtml += [">Remove Entity and Save Layout</button></div>]
                //---------------------------------------------------------------------------
                l_cHtml += [<input type="hidden" name="TextEntityPkToRemove" value="]+Trans(l_iEntityPk)+[">]

                if !empty(l_cEntityDescription)
                    l_cHtml += [<div class="mt-3"><div class="fs-5">Description:</div>]+TextToHTML(l_cEntityDescription)+[</div>]
                endif

                if !empty(l_cEntityInformation)
                    l_cHtml += [<div class="mt-3"><div class="fs-5">Information:</div>]+TextToHTML(l_cEntityInformation)+[</div>]
                endif


                if !empty(l_cHtml_EntityCustomFields)
                    l_cHtml += [<div class="mt-3">]
                        l_cHtml += l_cHtml_EntityCustomFields
                    l_cHtml += [</div>]
                endif

            l_cHtml += [</div>]

            // -----------------------------------------------------------------------------------------------------------------------------------------

        endif
    endwith

else
    l_aEdges := hb_HGetDef(l_hOnClickInfo,"edges",{})
    if len(l_aEdges) > 0  // If there are multiple edges, meaning like a double arrow, if will only return 1. Have to walk through the "items" instead.
        // l_iAttributePk := l_aEdges[1]

        l_aItems := hb_HGetDef(l_hOnClickInfo,"items",{})
        l_nEdgeNumber := len(l_aItems)

        with object l_oDB_InArray

            for l_nEdgeCounter := 1 to l_nEdgeNumber
                l_iAttributePk := val(hb_HGetDef(l_aItems[l_nEdgeCounter],"edgeId","0"))
                if l_iAttributePk > 0

                    :Table("9410bb49-ad19-458f-9a77-b33b29afcccf","Attribute")

                    :Column("Attribute.Name"       ,"Attribute_Name")          //  1
                    :Column("Attribute.Description","Attribute_Description")   //  5
                    
                    :Column("NameSpace.Name"   ,"From_NameSpace_Name")   //  6
                    :Column("Entity.Name"       ,"From_Entity_Name")       //  7
                    :join("inner","Entity"      ,"","Attribute.fk_Entity = Entity.pk")
                    :join("inner","NameSpace"  ,"","Entity.fk_NameSpace = NameSpace.pk")
                    :join("inner","Application","","NameSpace.fk_Application = Application.pk")

                    :Column("NameSpaceTo.name" , "To_NameSpace_Name")    //  9
                    :Column("EntityTo.name"     , "To_Entity_Name")        // 10
                    :Join("inner","Entity"    ,"EntityTo"    ,"Attribute.fk_EntityForeign = EntityTo.pk")
                    :Join("inner","NameSpace","NameSpaceTo","EntityTo.fk_NameSpace = NameSpaceTo.pk")
                    
                    :Where("Attribute.pk = ^" , l_iAttributePk)
                    :SQL(@l_aSQLResult)

                    if :Tally == 1
                        l_cAttributeName          := Alltrim(l_aSQLResult[1,1])
                        l_cAttributeDescription   := Alltrim(nvl(l_aSQLResult[1,5],""))

                        l_cFrom_NameSpace_Name := Alltrim(l_aSQLResult[1,6])
                        l_cFrom_Entity_Name     := Alltrim(l_aSQLResult[1,7])

                        l_cTo_NameSpace_Name   := Alltrim(l_aSQLResult[1,9])
                        l_cTo_Entity_Name       := Alltrim(l_aSQLResult[1,10])

                        l_cHtml += [<nav class="navbar navbar-light" style="background-color: #]

                        l_cHtml += MODELING_ENTITY_NODE_HIGHLIGHT 
                        l_cHtml += [;">]

                            l_cHtml += [<div class="input-group">]
                                l_cHtml += [<span class="navbar-brand ms-3">From: ]+l_cFrom_NameSpace_Name+[.]+l_cFrom_Entity_Name+[</span>]
                                l_cHtml += [<span class="navbar-brand ms-3">To: ]+l_cTo_NameSpace_Name+[.]+l_cTo_Entity_Name+[</span>]
                                l_cHtml += [<span class="navbar-brand ms-3">Attribute: ]+l_cAttributeName+[</span>]
                            l_cHtml += [</div>]
                        l_cHtml += [</nav>]

                        if !empty(l_cAttributeDescription)
                            l_cHtml += [<div class="m-3"><div class="fs-5">Description:</div>]+TextToHTML(l_cAttributeDescription)+[</div>]
                        endif

                        l_cHtml += [<div class="m-3"></div>]

                    endif
                endif
            endfor
        endwith
    endif
endif

return l_cHtml
//=================================================================================================================
