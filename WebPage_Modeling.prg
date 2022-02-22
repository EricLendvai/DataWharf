#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageModeling()
local l_cHtml := []
local l_cHtmlUnderHeader

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDataHeader
local l_oData

local l_cFormName
local l_cActionOnSubmit

local l_iProjectPk
local l_cProjectName
local l_cProjectDescription

local l_hValues := {=>}

local l_cModelingElement := "ENTITIES"  //Default to Entities

local l_cURLAction  := "SelectProject"
local l_cURLLinkUID := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cLinkUID
local l_lFoundHeaderInfo := .f.

local l_nAccessLevelML := 1
// As per the info in Schema.txt
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     7 - Full Access

local l_nCounter
local l_nCounterC

local l_iModelingDiagramPk

oFcgi:TraceAdd("BuildPageModeling")

// Variables
// l_cURLAction

// Modeling/                                    Same as SelectProject

// Modeling/ListModels/<Project.LinkUID>/
// Modeling/NewModel/<Project.LinkUID>/
// Modeling/ModelSettings/<Model.LinkUID>/

// Modeling/Visualize/<Model.LinkUID>/

// Modeling/ListEntities/Model.LinkUID>/
// Modeling/NewEntity/<Model.LinkUID>/
// Modeling/EditEntity/<Entity.LinkUID>/

// Modeling/ListAttributes/<Entity.LinkUID>/
// Modeling/NewAttribute/<Entity.LinkUID>/
// Modeling/EditAttribute/<Attribute.LinkUID>/

// Modeling/ListAssociations/Model.LinkUID>/
// Modeling/NewAssociation/<Model.LinkUID>/
// Modeling/EditAssociation/<Association.LinkUID>/

// Modeling/ListPackages/Model.LinkUID>/
// Modeling/NewPackage/<Model.LinkUID>/
// Modeling/EditPackage/<Package.LinkUID>/

// Modeling/ListDataTypes/Model.LinkUID>/
// Modeling/NewDataType/<Model.LinkUID>/
// Modeling/EditDataType/<DataType.LinkUID>/

if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLLinkUID := oFcgi:p_URLPathElements[3]
    endif

    do case
    case vfp_Inlist(l_cURLAction,"ListModels","NewModel")
        with object l_oDB1
            :Table("68dd8f54-924f-47df-9c9a-6bb1a42b1af3","Project")
            :Column("Project.LinkUID", "Project_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Project.LinkUID = ^" , l_cURLLinkUID)
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"ModelSettings","ListEntities","ListAssociations","ListPackages","ListDataTypes","NewEntity","NewAssociation","NewPackage","NewDataType","Visualize")
        with object l_oDB1
            :Table("eaa6b925-b225-4fe2-8eeb-a0afcefc3848","Model")
            :Column("Model.pk"       , "Model_pk")
            :Column("Model.LinkUID"  , "Model_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.Name"     , "Model_Name")
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.LinkUID", "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Model.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"ListAttributes","OrderAttributes","NewAttribute")
        with object l_oDB1
            :Table("62211568-2341-4405-bff7-93ba323b529f","Entity")
            :Column("Entity.pk"      , "Entity_pk")
            :Column("Entity.LinkUID" , "Entity_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Entity.Name"    , "Entity_Name")
            :Column("Model.pk"       , "Model_pk")
            :Column("Model.LinkUID"  , "Model_LinkUID")
            :Column("Model.Name"     , "Model_Name")
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.LinkUID", "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            :Where("Entity.LinkUID = ^" , l_cURLLinkUID)
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditEntity")
        with object l_oDB1
            :Table("08839946-0a7b-4a47-a512-dee69e58e102","Entity")
            :Column("Entity.pk"      , "Entity_pk")
            :Column("Entity.LinkUID" , "Entity_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Entity.Name"    , "Entity_Name")
            :Column("Model.pk"       , "Model_pk")
            :Column("Model.LinkUID"  , "Model_LinkUID")
            :Column("Model.Name"     , "Model_Name")
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.LinkUID", "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Entity.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditAssociation")
        with object l_oDB1
            :Table("e65fdb08-1f34-4013-b1d0-169e2c811805","Association")
            :Column("Association.pk"     , "Association_pk")
            :Column("Association.LinkUID", "Association_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"           , "Model_pk")
            :Column("Model.LinkUID"      , "Model_LinkUID")
            :Column("Model.Name"         , "Model_Name")
            :Column("Project.pk"         , "Project_pk")
            :Column("Project.Name"       , "Project_Name")
            :Column("Project.LinkUID"    , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Association.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Association.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditPackage")
        with object l_oDB1
            :Table("b63c5a26-e670-465f-a064-99650edfa9c0","Package")
            :Column("Package.pk"        , "Package_pk")
            :Column("Package.LinkUID"   , "Package_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"          , "Model_pk")
            :Column("Model.LinkUID"     , "Model_LinkUID")
            :Column("Model.Name"        , "Model_Name")
            :Column("Project.pk"        , "Project_pk")
            :Column("Project.Name"      , "Project_Name")
            :Column("Project.LinkUID"   , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Package.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model"  ,"","Package.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditDataType")
        with object l_oDB1
            :Table("b4bdf68c-9bc2-43f3-8e7b-9c9a3c278528","DataType")
            :Column("DataType.pk"     , "DataType_pk")
            :Column("DataType.LinkUID", "DataType_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"        , "Model_pk")
            :Column("Model.LinkUID"   , "Model_LinkUID")
            :Column("Model.Name"      , "Model_Name")
            :Column("Project.pk"      , "Project_pk")
            :Column("Project.Name"    , "Project_Name")
            :Column("Project.LinkUID" , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("DataType.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","DataType.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditAttribute")
        with object l_oDB1
            :Table("4e93c422-387b-4cb9-a178-50a29250a158","Attribute")
            :Column("Attribute.pk"      , "Attribute_pk")
            :Column("Attribute.LinkUID" , "Attribute_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Entity.pk"         , "Entity_pk")
            :Column("Entity.LinkUID"    , "Entity_LinkUID")
            :Column("Entity.Name"       , "Entity_Name")
            :Column("Model.pk"          , "Model_pk")
            :Column("Model.LinkUID"     , "Model_LinkUID")
            :Column("Model.Name"        , "Model_Name")
            :Column("Project.pk"        , "Project_pk")
            :Column("Project.Name"      , "Project_Name")
            :Column("Project.LinkUID"   , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"        , "ANFModel")
            :Column("Project.AlternateNameForModels"       , "ANFModels")
            :Column("Project.AlternateNameForEntity"       , "ANFEntity")
            :Column("Project.AlternateNameForEntities"     , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"  , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations" , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"    , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"   , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"     , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"    , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"      , "ANFPackage")
            :Column("Project.AlternateNameForPackages"     , "ANFPackages")
            :Where("Attribute.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Entity","","Attribute.fk_Entity = Entity.pk")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    endcase

    do case
    case l_cURLAction == "ListModels"
        l_cModelingElement := ""  // Not needed

    case vfp_Inlist(l_cURLAction,"ListEntities","NewEntity","EditEntity","ListAttributes","NewAttribute","EditAttribute","OrderAttributes")
        l_cModelingElement := "ENTITIES"

    case vfp_Inlist(l_cURLAction,"ListAssociations","NewAssociation","EditAssociation")
        l_cModelingElement := "ASSOCIATIONS"

    case vfp_Inlist(l_cURLAction,"ListPackages","NewPackage","EditPackage")
        l_cModelingElement := "PACKAGES"

    case vfp_Inlist(l_cURLAction,"ListDataTypes","NewDataType","EditDataType")
        l_cModelingElement := "DATATYPES"

    case vfp_Inlist(l_cURLAction,"ModelSettings")
        l_cModelingElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"Visualize")
        l_cModelingElement := "VISUALIZE"

    otherwise
        l_cModelingElement := "ENTITIES"

    endcase

    if l_lFoundHeaderInfo
        //Update the oFCGI.p_ANF properties
        with object oFcgi
            :p_ANFModel        := nvl(l_oDataHeader:ANFModel       ,"Model")
            :p_ANFModels       := nvl(l_oDataHeader:ANFModels      ,"Models")
            :p_ANFEntity       := nvl(l_oDataHeader:ANFEntity      ,"Entity")
            :p_ANFEntities     := nvl(l_oDataHeader:ANFEntities    ,"Entities")
            :p_ANFAssociation  := nvl(l_oDataHeader:ANFAssociation ,"Association")
            :p_ANFAssociations := nvl(l_oDataHeader:ANFAssociations,"Associations")
            :p_ANFAttribute    := nvl(l_oDataHeader:ANFAttribute   ,"Attribute")
            :p_ANFAttributes   := nvl(l_oDataHeader:ANFAttributes  ,"Attributes")
            :p_ANFDataType     := nvl(l_oDataHeader:ANFDataType    ,"Data Type")
            :p_ANFDataTypes    := nvl(l_oDataHeader:ANFDataTypes   ,"Data Types")
            :p_ANFPackage      := nvl(l_oDataHeader:ANFPackage     ,"Package")
            :p_ANFPackages     := nvl(l_oDataHeader:ANFPackages    ,"Packages")

        endwith

        l_cProjectName := l_oDataHeader:Project_Name
        l_iProjectPk   := l_oDataHeader:Project_pk

        l_nAccessLevelML := GetAccessLevelMLForProject(l_iProjectPk)
    endif

else
    l_cURLAction := "SelectProject" // "ListModels"
endif

oFcgi:p_nAccessLevelML := l_nAccessLevelML

do case
case !l_lFoundHeaderInfo .and. l_cURLAction <> "SelectProject"
    l_cHtml += [<div>Invalid UID</div>]

case l_cURLAction == "SelectProject"
    l_cHtml += ProjectListFormBuild()

case l_cURLAction == "ListModels"
    l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Project: ]+l_oDataHeader:Project_Name+[</span></div>]
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Modeling/NewModel/]+l_oDataHeader:Project_LinkUID+[/">New ]+oFcgi:p_ANFModel+[</a></div>]
    endif
    l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Modeling/">Other Projects</a></div>]
    l_cHtml += [</div>]

    l_cHtml += ModelListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Project_Name)

case l_cURLAction == "NewModel"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        // l_cHtml +=     [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand text-white ms-3">New ]+oFcgi:p_ANFModel+[</span>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
        
        if oFcgi:isGet()
            //Brand new request of add a project.
            l_hValues["Fk_Project"]  := l_oDataHeader:Project_pk
            l_cHtml += ModelEditFormBuild(l_oDataHeader:Project_pk,"",0,@l_hValues)
        else
            l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_LinkUID,"")
        endif
    endif

case l_cURLAction == "ModelSettings"
    if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.f.,l_cSitePath)
        //par_iModelPk,par_cModelLinkUID,par_cProjectName,par_cModelName,par_lActiveHeader

        if oFcgi:isGet()
            with object l_oDB1
                :Table("d093409c-3fa3-4afb-95e6-ca55d0ba96b6","Model")
                :Column("Model.fk_Project"  , "Model_fk_Project")
                :Column("Model.Name"        , "Model_Name")
                :Column("Model.Stage"       , "Model_Stage")
                :Column("Model.Description" , "Model_Description")
                l_oData := :Get(l_oDataHeader:Model_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Fk_Project"]  := l_oData:Model_fk_Project
                l_hValues["Name"]        := l_oData:Model_Name
                l_hValues["Stage"]       := l_oData:Model_Stage
                l_hValues["Description"] := l_oData:Model_Description
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_MODEL,l_oDataHeader:Model_pk,@l_hValues)

                l_cHtml += ModelEditFormBuild(l_oDataHeader:Project_pk,"",l_oDataHeader:Model_pk,l_hValues,l_oDataHeader:Model_LinkUID)
            endif
        else
            l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID)
        endif
    endif

case l_cURLAction == "ListEntities"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += EntityListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    endif

case l_cURLAction == "NewEntity"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += EntityEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
        endif
    endif

case l_cURLAction == "EditEntity"
    if oFcgi:p_nAccessLevelML >= 2
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

        if oFcgi:isGet()
            with object l_oDB1
                :Table("e9c40921-bd84-4c03-bc86-c805f20b78ef","Entity")
                :Column("Entity.fk_Package"   , "Entity_fk_Package")
                :Column("Entity.Name"         , "Entity_Name")
                :Column("Entity.Description"  , "Entity_Description")
                :Column("Entity.Scope"        , "Entity_Scope")
                l_oData := :Get(l_oDataHeader:Entity_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["fk_Package"]     := l_oData:Entity_fk_Package
                l_hValues["Name"]           := l_oData:Entity_Name
                l_hValues["Description"]    := l_oData:Entity_Description
                l_hValues["Scope"]          := l_oData:Entity_Scope
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_ENTITY,l_oDataHeader:Entity_pk,@l_hValues)

                l_cHtml += EntityEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,"",l_oDataHeader:Entity_pk,l_hValues)
            endif
        else
            l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
        endif

    endif

case l_cURLAction == "ListAttributes"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += AttributeListFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
    else
        l_cHtml += AttributeListFormOnSubmit(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
    endif

case l_cURLAction == "OrderAttributes"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += AttributeOrderFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name)
    else
        l_cHtml += AttributeOrderFormOnSubmit(l_oDataHeader:Entity_LinkUID)
    endif

case l_cURLAction == "NewAttribute"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += AttributeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"",0,{=>})
        else
            l_cHtml += AttributeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
        endif
    endif

case l_cURLAction == "EditAttribute"
    if oFcgi:p_nAccessLevelML >= 2
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

        if oFcgi:isGet()
            with object l_oDB1
                :Table("974f878e-4772-4a6f-9f62-04b5dd3f276c","Attribute")
                :Column("Attribute.Name"        , "Attribute_Name")
                :Column("Attribute.fk_DataType" , "Attribute_fk_DataType")
                :Column("Attribute.BoundLower"  , "Attribute_BoundLower")
                :Column("Attribute.BoundUpper"  , "Attribute_BoundUpper")
                :Column("Attribute.Description" , "Attribute_Description")
                l_oData := :Get(l_oDataHeader:Attribute_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]        := l_oData:Attribute_Name
                l_hValues["fk_DataType"] := l_oData:Attribute_fk_DataType
                l_hValues["BoundLower"]  := l_oData:Attribute_BoundLower
                l_hValues["BoundUpper"]  := l_oData:Attribute_BoundUpper
                l_hValues["Description"] := l_oData:Attribute_Description
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_ATTRIBUTE,l_oDataHeader:Attribute_pk,@l_hValues)

                l_cHtml += AttributeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"",l_oDataHeader:Attribute_pk,l_hValues)
            endif
        else
            l_cHtml += AttributeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
        endif

    endif

case l_cURLAction == "ListAssociations"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += AssociationListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        l_cHtml += AssociationListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    endif


case l_cURLAction == "NewAssociation"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += AssociationEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += AssociationEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Association_LinkUID)
        endif
    endif

case l_cURLAction == "EditAssociation"
    if oFcgi:p_nAccessLevelML >= 2
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

        if oFcgi:isGet()
            with object l_oDB1
                :Table("e399d44f-9bd6-451f-8806-d5128fcd09ab","Association")
                :Column("Association.fk_Package"   , "Association_fk_Package")
                :Column("Association.Name"         , "Association_Name")
                :Column("Association.Description"  , "Association_Description")
                l_oData := :Get(l_oDataHeader:Association_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["fk_Package"]     := l_oData:Association_fk_Package
                l_hValues["Name"]           := l_oData:Association_Name
                l_hValues["Description"]    := l_oData:Association_Description
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_ASSOCIATION,l_oDataHeader:Association_pk,@l_hValues)

                //Load the endpoints
                with object l_oDB1
                    :Table("f0688b5a-5cec-4262-9cda-9b66747ae5a8","Endpoint")
                    :Column("Endpoint.pk"                    , "Endpoint_pk")
                    :Column("Endpoint.Fk_Entity"             , "Endpoint_fk_Entity")
                    :Column("Endpoint.Name"                  , "Endpoint_Name")
                    :Column("Endpoint.BoundLower"            , "Endpoint_BoundLower")
                    :Column("Endpoint.BoundUpper"            , "Endpoint_BoundUpper")
                    :Column("Endpoint.AspectOf"              , "Endpoint_AspectOf")
                    :Column("Endpoint.Description"           , "Endpoint_Description")
                    :Column("Package.FullName"               , "Package_FullName")
                    :Column("Entity.Name"                    , "Entity_Name")
                    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
                    :Column("upper(Entity.Name)"             , "tag2")
                    :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
                    :Join("left","Package","","Entity.fk_Package = Package.pk") 
                    :Where("Endpoint.fk_Association = ^" , l_oDataHeader:Association_pk)
                    :OrderBy("tag1")
                    :OrderBy("tag2")
                    :SQL("ListOfEndpoints")

                    select ListOfEndpoints
                    l_nCounter := 0
                    scan all
                        l_nCounter += 1
                        l_nCounterC := Trans(l_nCounter)
                        l_hValues["EndpointPk"+l_nCounterC]          := ListOfEndpoints->Endpoint_pk
                        l_hValues["EndpointFk_Entity"+l_nCounterC]   := ListOfEndpoints->Endpoint_fk_Entity
                        l_hValues["EndpointName"+l_nCounterC]        := ListOfEndpoints->Endpoint_Name
                        l_hValues["EndpointBoundLower"+l_nCounterC]  := ListOfEndpoints->Endpoint_BoundLower
                        l_hValues["EndpointBoundUpper"+l_nCounterC]  := ListOfEndpoints->Endpoint_BoundUpper
                        l_hValues["EndpointAspectOf"+l_nCounterC]    := ListOfEndpoints->Endpoint_AspectOf
                        l_hValues["EndpointDescription"+l_nCounterC] := ListOfEndpoints->Endpoint_Description
                    endscan
                    l_hValues["NumberOfPossibleEndpoints"] := max(3,l_nCounter+1)
                endwith

                l_cHtml += AssociationEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Association_LinkUID,"",l_oDataHeader:Association_pk,l_hValues)
            endif
        else
            l_cHtml += AssociationEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Association_LinkUID)
        endif

    endif

case l_cURLAction == "ListPackages"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += PackageListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        // Nothing for now. All buttons are GET
    endif

case l_cURLAction == "NewPackage"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += PackageEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
        endif
    endif

case l_cURLAction == "EditPackage"
    if oFcgi:p_nAccessLevelML >= 2
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

        if oFcgi:isGet()
            with object l_oDB1
                :Table("6689ff9b-9b8a-400c-abf8-d7146b805461","Package")
                :Column("Package.fk_Package" , "Package_fk_Package")
                :Column("Package.Name"       , "Package_Name")
                l_oData := :Get(l_oDataHeader:Package_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["fk_Package"] := l_oData:Package_fk_Package
                l_hValues["Name"]       := l_oData:Package_Name
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_PACKAGE,l_oDataHeader:Package_pk,@l_hValues)

                l_cHtml += PackageEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID,"",l_oDataHeader:Package_pk,l_hValues)
            endif
        else
            l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
        endif

    endif

case l_cURLAction == "ListDataTypes"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += DataTypeListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        // Nothing for now. All buttons are GET
    endif

case l_cURLAction == "NewDataType"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
        endif
    endif

case l_cURLAction == "EditDataType"
    if oFcgi:p_nAccessLevelML >= 2
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

        if oFcgi:isGet()
            with object l_oDB1
                :Table("5429f4d0-7679-419f-a7b2-c0899fb2d1da","DataType")
                :Column("DataType.fk_DataType" , "DataType_fk_DataType")
                :Column("DataType.Name"        , "DataType_Name")
                :Column("DataType.Description" , "DataType_Description")
                l_oData := :Get(l_oDataHeader:DataType_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["fk_DataType"] := l_oData:DataType_fk_DataType
                l_hValues["Name"]        := l_oData:DataType_Name
                l_hValues["Description"] := l_oData:DataType_Description
                CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_DATATYPE,l_oDataHeader:DataType_pk,@l_hValues)

                l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID,"",l_oDataHeader:DataType_pk,l_hValues)
            endif
        else
            l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
        endif

    endif

case l_cURLAction == "Visualize"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
    
    if oFcgi:isGet()
        l_iModelingDiagramPk := 0
        with object l_oDB1
            :Table("87305d69-4c9f-4569-81e6-a96b075181f6","ModelingDiagram")
            :Column("ModelingDiagram.pk"         ,"ModelingDiagram_pk")
            :Column("ModelingDiagram.LinkUID"    ,"ModelingDiagram_LinkUID")
            :Column("upper(ModelingDiagram.Name)","Tag1")
            :Where("ModelingDiagram.fk_Model = ^" ,l_oDataHeader:Model_pk)
            :OrderBy("tag1")
            :SQL("ListOfModelingDiagrams")
            if :Tally > 0
                l_iModelingDiagramPk   := ListOfModelingDiagrams->ModelingDiagram_pk

                l_cLinkUID = oFcgi:GetQueryString("InitialDiagram")
                if !empty(l_cLinkUID)
                    select ListOfModelingDiagrams
                    locate for ListOfModelingDiagrams->ModelingDiagram_LinkUID == l_cLinkUID
                    if found()
                        l_iModelingDiagramPk := ListOfModelingDiagrams->ModelingDiagram_pk
                    endif
                endif

            else
                //Add an initial Diagram File
                :Table("bca28e8c-564b-4af2-9045-fd9845e6eedf","ModelingDiagram")
                :Field("ModelingDiagram.LinkUID" ,oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("ModelingDiagram.fk_Model",l_oDataHeader:Model_pk)
                :Field("ModelingDiagram.Name","All Entities")
                if :Add()
                    l_iModelingDiagramPk := :Key()
                endif
            endif
        endwith

        if l_iModelingDiagramPk > 0
            l_cHtml += ModelingVisualizeDiagramBuild(l_oDataHeader,"",l_iModelingDiagramPk)

        endif
    else
        l_cFormName := oFcgi:GetInputValue("formname")
        do case
        case l_cFormName == "Design"
            l_cHtml += ModelingVisualizeDiagramOnSubmit(l_oDataHeader,"")

        case l_cFormName == "DiagramSettings"
            l_cHtml += ModelingVisualizeDiagramSettingsOnSubmit(l_oDataHeader,"")

        case l_cFormName == "MyDiagramSettings"
            l_cHtml += ModelingVisualizeMyDiagramSettingsOnSubmit(l_oDataHeader,"")

        endcase
    endif

otherwise
    l_cHtml += [<div>Bad URL</div>]
    
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ModelingHeaderBuild(par_iModelPk,par_cProjectLinkUID,par_cModelLinkUID,par_cProjectName,par_cModelName,par_cModelElement,par_lActiveHeader,par_cSitePath)

local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("ModelingHeaderBuild")

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Project / ]+oFcgi:p_ANFModel+[: ]+par_cProjectName+[ / ]+par_cModelName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Modeling/ListModels/]+par_cProjectLinkUID+[/">Other ]+oFcgi:p_ANFModels+[</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("43e2e6a8-0228-4c99-bf52-4e9841ac2e40","Entity")
            :Column("Count(*)","Total")
            :Where("Entity.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ENTITIES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">]+oFcgi:p_ANFEntities+[ (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("8d6384d8-683d-4ba8-8c88-8371373c8a05","Association")
            :Column("Count(*)","Total")
            :Where("Association.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ASSOCIATIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListAssociations/]+par_cModelLinkUID+[/">]+oFcgi:p_ANFAssociations+[ (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("a0d49d4d-5a86-48d5-a1a7-c970cbf4d118","DataType")
            :Column("Count(*)","Total")
            :Where("DataType.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "DATATYPES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+[/">]+oFcgi:p_ANFDataTypes+[ (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("102048fd-0d4e-4926-b1be-992b1b4b2ce2","Package")
            :Column("Count(*)","Total")
            :Where("Package.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "PACKAGES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListPackages/]+par_cModelLinkUID+[/">]+oFcgi:p_ANFPackages+[ (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cModelElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelSettings/]+par_cModelLinkUID+[/">]+oFcgi:p_ANFModel+[ Settings</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cModelElement == "VISUALIZE",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/Visualize/]+par_cModelLinkUID+[/">Visualize</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ProjectListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfProjects
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("ProjectListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("ef540265-9ca9-4045-835c-65772402ca0d","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Project.LinkUID"    ,"Project_LinkUID")
    :Column("Project.UseStatus"  ,"Project_UseStatus")
    :Column("Project.Description","Project_Description")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    endif

    :SQL("ListOfProjects")
    l_nNumberOfProjects := :Tally
endwith


if l_nNumberOfProjects > 0
    with object l_oDB2
        :Table("42747915-4e1c-4151-8094-691f7305b82d","Project")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Project.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_PROJECT)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("d7cd59ac-d135-4127-9302-ee3625cafb6e","Project")
        :Column("Project.pk"              ,"fk_Entity")
        :Column("CustomField.pk"          ,"CustomField_pk")
        :Column("CustomField.Label"       ,"CustomField_Label")
        :Column("CustomField.Type"        ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI" ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM" ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD" ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Project.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_PROJECT)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfProjects)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Project on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"3","4")+[">Projects (]+Trans(l_nNumberOfProjects)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Usage<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfProjects
                scan all
                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListModels/]+AllTrim(ListOfProjects->Project_LinkUID)+[/">]+Allt(ListOfProjects->Project_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfProjects->Project_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(vfp_between(ListOfProjects->Project_UseStatus,1,6),ListOfProjects->Project_UseStatus,1)]
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(ListOfProjects->pk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ModelListFormBuild(par_Project_pk,par_Project_Name)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_oDB_CustomFields                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsEntityCounts      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsAssociationCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsPackageCounts     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsDataTypeCounts    := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfModels
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

local l_iModelPk
local l_nEntityCount
local l_nAssociationCount
local l_nPackageCount
local l_nDataTypeCount

oFcgi:TraceAdd("ModelListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("ea43381a-8ba0-4bbf-aaa1-43768780351d","Model")
    :Column("Model.pk"         ,"pk")
    :Column("Model.Name"       ,"Model_Name")
    :Column("Model.Stage"      ,"Model_Stage")
    :Column("Model.Description","Model_Description")
    :Column("Model.LinkUID"    ,"Model_LinkUID")
    :Column("Upper(Model.Name)","tag1")
    :OrderBy("tag1")
    :Where("Model.fk_Project = ^",par_Project_pk)
    :SQL("ListOfModels")
    l_nNumberOfModels := :Tally
endwith


//_M_ Add support to custom fields
if l_nNumberOfModels > 0
    with object l_oDB_CustomFields
        :Table("6135dc5d-fbeb-49f6-8158-1e77f27d52fc","Model")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Model.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :Where("CustomField.UsedOn = ^",USEDON_MODEL)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("3172b746-2c76-4f04-959d-bcf7436f7eac","Model")
        :Column("Model.pk"               ,"fk_Entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Model.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :Where("CustomField.UsedOn = ^",USEDON_MODEL)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

    //For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.

    with object l_oDB_ListOfModelsEntityCounts
        :Table("ec7bdbd8-db8f-48ee-a277-75ddc70ee531","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"EntityCount")
        :Join("inner","Entity","","Entity.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model.pk")
        :SQL("ListOfModelsEntityCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

    with object l_oDB_ListOfModelsAssociationCounts
        :Table("49945b95-d779-4794-ad8d-b9509149474f","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"AssociationCount")
        :Join("inner","Association","","Association.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model.pk")
        :SQL("ListOfModelsAssociationCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

    with object l_oDB_ListOfModelsPackageCounts
        :Table("ffae46b3-74a4-43f4-9d11-dae80e0bcba5","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"PackageCount")
        :Join("inner","Package","","Package.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model.pk")
        :SQL("ListOfModelsPackageCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

    with object l_oDB_ListOfModelsDataTypeCounts
        :Table("6bdc7220-0980-4288-9dd0-621cc3baba60","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"DataTypeCount")
        :Join("inner","DataType","","DataType.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model.pk")
        :SQL("ListOfModelsDataTypeCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfModels)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Model on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"9","10")+[">]+oFcgi:p_ANFModels+[ (]+Trans(l_nNumberOfModels)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Project</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFModel+[ Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Stage</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFEntities+[</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFAssociations+[</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFDataTypes+[</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFPackages+[</th>]
                    // l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Settings</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Visualize</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfModels
                scan all
                    l_iModelPk := ListOfModels->pk

                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Project
                            l_cHtml += par_Project_Name
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Model Name
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+AllTrim(ListOfModels->Model_LinkUID)+[/">]+Allt(ListOfModels->Model_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Stage
                            l_cHtml += {"Proposed","Draft","Beta","Stable","In Use","Discontinued"}[iif(vfp_between(ListOfModels->Model_Stage,1,6),ListOfModels->Model_Stage,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Description
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfModels->Model_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Entities
                            l_nEntityCount := iif( VFP_Seek(l_iModelPk,"ListOfModelsEntityCounts","tag1") , ListOfModelsEntityCounts->EntityCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+AllTrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nEntityCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Associations
                            l_nAssociationCount := iif( VFP_Seek(l_iModelPk,"ListOfModelsAssociationCounts","tag1") , ListOfModelsAssociationCounts->AssociationCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListAssociations/]+AllTrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nAssociationCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Data Types
                            l_nDataTypeCount := iif( VFP_Seek(l_iModelPk,"ListOfModelsDataTypeCounts","tag1") , ListOfModelsDataTypeCounts->DataTypeCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListDataTypes/]+AllTrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nDataTypeCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">] //Packages
                            l_nPackageCount := iif( VFP_Seek(l_iModelPk,"ListOfModelsPackageCounts","tag1") , ListOfModelsPackageCounts->PackageCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListPackages/]+AllTrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nPackageCount)+[</a>]
                        l_cHtml += [</td>]
                        
                        // l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Settings
                        //     l_cHtml += []
                        // l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Visualize
                            l_cHtml += []
                        l_cHtml += [</td>]

                        if l_nNumberOfCustomFieldValues > 0
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += CustomFieldsBuildGridOther(l_iModelPk,l_hOptionValueToDescriptionMapping)
                            l_cHtml += [</td>]
                        endif

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function ModelEditFormBuild(par_iProjectPk,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText     := hb_DefaultValue(par_cErrorText,"")

local l_iProjectPk     := nvl(hb_HGetDef(par_hValues,"Fk_Project",0),0)
local l_cName          := hb_HGetDef(par_hValues,"Name","")
local l_nStage         := hb_HGetDef(par_hValues,"Stage",1)
local l_cDescription   := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfProjects := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_lSelectableProject

oFcgi:TraceAdd("ModelEditFormBuild")

with object l_oDB_ListOfProjects
    :Table("0743cc77-e97e-4e18-8193-700f560abf1f","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfProjects")

// _M_  Access rights restrictions

endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="ModelKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New ]+oFcgi:p_ANFModel+[</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update ]+oFcgi:p_ANFModel+[ Settings</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelML >= 7
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 7
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_lSelectableProject := (oFcgi:p_nAccessLevelML >= 5 .and. !empty(par_iPk))

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Project</td>]
            l_cHtml += [<td class="pb-3">]
                if l_lSelectableProject
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboProjectPk" id="ComboProjectPk" class="form-select">]
                else
                    l_cHtml += [<input type="hidden" name="ComboProjectPk" value="]+Trans(l_iProjectPk)+[">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ disabled class="form-select">]
                endif
                select ListOfProjects
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfProjects->pk)+["]+iif(ListOfProjects->pk = l_iProjectPk,[ selected],[])+[>]+AllTrim(ListOfProjects->Project_Name)+[</option>]
                endscan
                l_cHtml += [</select>]
                if oFcgi:p_nAccessLevelML >= 5 .and. !empty(par_iPk)
                    l_cHtml += [<span>(Can be used to reassign ]+oFcgi:p_ANFModel+[ to a different Project)</span>]
                endif
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Stage</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboStage" id="ComboStage">]
                    l_cHtml += [<option value="1"]+iif(l_nStage==1,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="2"]+iif(l_nStage==2,[ selected],[])+[>Draft</option>]
                    l_cHtml += [<option value="3"]+iif(l_nStage==3,[ selected],[])+[>Beta</option>]
                    l_cHtml += [<option value="4"]+iif(l_nStage==4,[ selected],[])+[>Stable</option>]
                    l_cHtml += [<option value="5"]+iif(l_nStage==5,[ selected],[])+[>In Use</option>]
                    l_cHtml += [<option value="6"]+iif(l_nStage==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_MODEL,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ModelEditFormOnSubmit(par_iProjectPk,par_cProjectLinkUID,par_cModelLinkUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_iModelPk
local l_iProjectPk
local l_cModelName
local l_nModelStage
local l_cModelDescription
local l_cModelLinkUID

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("ModelEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iModelPk          := Val(oFcgi:GetInputValue("ModelKey"))
l_iProjectPk        := Val(oFcgi:GetInputValue("ComboProjectPk"))
l_cModelName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nModelStage       := Val(oFcgi:GetInputValue("ComboStage"))
l_cModelDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))


do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 7
        do case
        case empty(l_cModelName)
            l_cErrorMessage := "Missing Name"
        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("6f26318e-0a76-4e5b-a894-adae0c00a876","Model")
                :Where([lower(replace(Model.Name,' ','')) = ^],lower(StrTran(l_cModelName," ","")))
                :Where("Model.fk_Project = ^" , l_iProjectPk)
                if l_iModelPk > 0
                    :Where([Model.pk != ^],l_iModelPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Model Name in Project"
            else
                //Save the Model
                with object l_oDB1
                    :Table("e65406e9-c51f-43f5-ab50-73904d9986a8","Model")
                    :Field("Model.Name"       ,l_cModelName)
                    :Field("Model.fk_Project" ,l_iProjectPk)
                    :Field("Model.Stage"      ,l_nModelStage)
                    :Field("Model.Description",iif(empty(l_cModelDescription),NULL,l_cModelDescription))
                    
                    if empty(l_iModelPk)
                        l_cModelLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                        :Field("Model.LinkUID" , l_cModelLinkUID)
                        if :Add()
                            l_iModelPk := :Key()
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+l_cModelLinkUID+"/")
                        else
                            l_cErrorMessage := "Failed to add Model."
                        endif
                    else
                        if :Update(l_iModelPk)
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
                        else
                            l_cErrorMessage := "Failed to update Project."
                        endif
                    endif
                    if empty(l_cErrorMessage)
                        CustomFieldsSave(par_iProjectPk,USEDON_MODEL,l_iModelPk)
                    endif
                endwith
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"
    if empty(par_cModelLinkUID)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
    endif

case l_cActionOnSubmit == "Delete"   // Model
    if oFcgi:p_nAccessLevelML >= 7
        if CheckIfAllowDestructiveModelDelete(l_iModelPk)
            l_cErrorMessage := CascadeDeleteModel(par_iProjectPk,l_iModelPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
            endif
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

            with object l_oDB1
                :Table("41917f59-c1d2-4c1f-8bb4-1524695b6de7","Package")
                :Where("Package.fk_Model = ^",l_iModelPk)
                :SQL()

                if :Tally == 0
                    :Table("27a04256-11ac-47db-8c27-e32016fd13df","Entity")
                    :Where("Entity.fk_Model = ^",l_iModelPk)
                    :SQL()

                    if :Tally == 0
                        :Table("5ecf0c79-9444-4d71-bc7f-e746d63406f8","Association")
                        :Where("Association.fk_Model = ^",l_iModelPk)
                        :SQL()

                        if :Tally == 0
                            :Table("3d533d32-9518-4de8-be2a-92a227a7a5f5","DataType")
                            :Where("DataType.fk_Model = ^",l_iModelPk)
                            :SQL()

                            if :Tally == 0
                                :Table("3d533d32-9518-4de8-be2a-92a227a7a5f5","ModelingDiagram")
                                :Where("ModelingDiagram.fk_Model = ^",l_iModelPk)
                                :SQL()

                                if :Tally == 0
                                    CustomFieldsDelete(par_iProjectPk,USEDON_MODEL,l_iModelPk)
                                    :Delete("8c45bacb-78dd-46e5-ab34-38b0ff7c30b8","Model",l_iModelPk)

                                    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
                                else
                                    l_cErrorMessage := [Related Diagrams record on file.]
                                endif
                            else
                                l_cErrorMessage := [Related ]+oFcgi:p_ANFDataType+[ record on file.]
                            endif
                        else
                            l_cErrorMessage := [Related ]+oFcgi:p_ANFAssociation+[ record on file.]
                        endif
                    else
                        l_cErrorMessage := [Related ]+oFcgi:p_ANFEntity+[ record on file.]
                    endif
                else
                    l_cErrorMessage := [Related ]+oFcgi:p_ANFPackage+[ record on file.]
                endif
            endwith
        endif
    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Fk_Project"] := l_iProjectPk
    l_hValues["Name"]       := l_cModelName
    l_hValues["Stage"]      := l_nModelStage
    l_hValues["Description"]:= l_cModelDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_MODEL,@l_hValues)

    l_cHtml += ModelEditFormBuild(l_iProjectPk,l_cErrorMessage,l_iModelPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfEntities               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntitiesAttributeCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iEntityPk
local l_nAttributeCount

local l_cSearchEntityName
local l_cSearchEntityDescription

local l_cSearchAttributeName
local l_cSearchAttributeDescription

local l_nNumberOfEntities := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cAttributeSearchParameters
local l_nColspan
local l_ScriptFolder

oFcgi:TraceAdd("EntityListFormBuild")

l_cSearchEntityName           := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName")
l_cSearchEntityDescription    := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription")

l_cSearchAttributeName        := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeName")
l_cSearchAttributeDescription := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeDescription")

if empty(l_cSearchAttributeName) .and. empty(l_cSearchAttributeDescription)
    l_cAttributeSearchParameters := ""
else
    l_cAttributeSearchParameters := [Search?AttributeName=]+hb_StrToHex(l_cSearchAttributeName)+[&AttributeDescription=]+hb_StrToHex(l_cSearchAttributeDescription)   //strtolhex
endif

with object l_oDB_ListOfEntities
    :Table("e345fe62-2fb5-48f6-a987-ff75b6ee10af","Entity")
    :Column("Entity.pk"         ,"pk")
    :Column("Entity.LinkUID"    ,"Entity_LinkUID")
    :Column("Entity.Name"       ,"Entity_Name")
    :Column("Entity.Description","Entity_Description")
    :Column("Entity.Scope"      ,"Entity_Scope")
    :Column("Upper(Entity.Name)","tag2")
    :Where("Entity.fk_Model = ^",par_iModelPk)

    if !empty(l_cSearchEntityName)
        :KeywordCondition(l_cSearchEntityName,"Entity.Name")
    endif
    if !empty(l_cSearchEntityDescription)
        :KeywordCondition(l_cSearchEntityDescription,"Entity.Description")
    endif
    if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
        :Distinct(.t.)
        :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
        if !empty(l_cSearchAttributeName)
            :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
        endif
        if !empty(l_cSearchAttributeDescription)
            :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
        endif
    endif

    :Join("left","Package","","Entity.fk_Package = Package.pk")
    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
    :Column("Package.FullName"               , "Package_FullName")

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfEntities")
    l_nNumberOfEntities := :Tally

    // SendToClipboard(:LastSQL())

endwith

if l_nNumberOfEntities > 0
    with object l_oDB_CustomFields
        :Table("dec87c17-33bf-4526-82f3-dd6c7014648d","Entity")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Entity.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Entity.fk_Model = ^",par_iModelPk)

        :Where("CustomField.UsedOn = ^",USEDON_ENTITY)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice

        if !empty(l_cSearchEntityName)
            :KeywordCondition(l_cSearchEntityName,"Entity.Name")
        endif
        if !empty(l_cSearchEntityDescription)
            :KeywordCondition(l_cSearchEntityDescription,"Entity.Description")
        endif
        if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
            :Distinct(.t.)
            :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
            if !empty(l_cSearchAttributeName)
                :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
            endif
            if !empty(l_cSearchAttributeDescription)
                :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
            endif
        endif
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("de1a82dd-16e0-4246-afc8-d75df62fc4e0","Entity")
        :Column("Entity.pk"              ,"fk_Entity")

        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Entity.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Entity.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_ENTITY)
        :Where("CustomField.Status <= 2")

        if !empty(l_cSearchEntityName)
            :KeywordCondition(l_cSearchEntityName,"Entity.Name")
        endif
        if !empty(l_cSearchEntityDescription)
            :KeywordCondition(l_cSearchEntityDescription,"Entity.Description")
        endif
        if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
            :Distinct(.t.)
            :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
            if !empty(l_cSearchAttributeName)
                :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
            endif
            if !empty(l_cSearchAttributeDescription)
                :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
            endif
        endif
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

endif


//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
with object l_oDB_ListOfEntitiesAttributeCounts
    :Table("bc2e9531-aab8-4c57-bd71-7bddca894b61","Entity")
    :Column("Entity.pk","Entity_pk")
    :Column("Count(*)" ,"AttributeCount")
    :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    :GroupBy("Entity.pk")
    :SQL("ListOfEntitiesAttributeCounts")

    with object :p_oCursor
        :Index("tag1","Entity_pk")
        :CreateIndexes()
        :SetOrder("tag1")
    endwith

endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    if oFcgi:p_nAccessLevelML >= 5
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewEntity/]+par_cModelLinkUID+[/">New ]+oFcgi:p_ANFEntity+[</a>]
                    else
                        l_cHtml += [<span class="ms-3"> </a>]  //To make some spacing
                    endif
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td valign="top">]
                    l_cHtml += [<table>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td></td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">]+oFcgi:p_ANFEntity+[</span></td>]
                            l_cHtml += [<td><input type="text" name="TextEntityName" id="TextEntityName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEntityName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextEntityDescription" id="TextEntityDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEntityDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">]+oFcgi:p_ANFAttribute+[</span></td>]
                            l_cHtml += [<td><input type="text" name="TextAttributeName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAttributeName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextAttributeDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAttributeDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                    l_cHtml += [</table>]

                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-5 me-3" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
                    l_cHtml += [<input type="button" class="btn btn-primary rounded me-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]
                l_cHtml += [</td>]
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]



    l_cHtml += [</div>]

l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfEntities)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_nColspan := 5
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan += 1
            endif

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+Trans(l_nColspan)+[">]+oFcgi:p_ANFEntities+[ (]+Trans(l_nNumberOfEntities)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFPackage+[</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFEntity+[ Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFAttributes+[</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Scope</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfEntities
            scan all
                l_iEntityPk := ListOfEntities->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += Allt(nvl(ListOfEntities->Package_FullName,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEntity/]+ListOfEntities->Entity_LinkUID+[/">]+ListOfEntities->Entity_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_nAttributeCount := iif( VFP_Seek(l_iEntityPk,"ListOfEntitiesAttributeCounts","tag1") , ListOfEntitiesAttributeCounts->AttributeCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListAttributes/]+ListOfEntities->Entity_LinkUID+[/]+l_cAttributeSearchParameters+[">]+Trans(l_nAttributeCount)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEntities->Entity_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEntities->Entity_Scope,""))
                    l_cHtml += [</td>]

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(l_iEntityPk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif
                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function EntityListFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_cEntityName
local l_cEntityDescription
local l_cAttributeName
local l_cAttributeDescription
local l_cURL

oFcgi:TraceAdd("EntityListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cEntityName           := SanitizeInput(oFcgi:GetInputValue("TextEntityName"))
l_cEntityDescription    := SanitizeInput(oFcgi:GetInputValue("TextEntityDescription"))

l_cAttributeName        := SanitizeInput(oFcgi:GetInputValue("TextAttributeName"))
l_cAttributeDescription := SanitizeInput(oFcgi:GetInputValue("TextAttributeDescription"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName"        ,l_cEntityName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription" ,l_cEntityDescription)

    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeName"       ,l_cAttributeName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeDescription",l_cAttributeDescription)

    l_cHtml += EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName"        ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription" ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeName"       ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeDescription","")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
static function EntityEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_ifk_Package  := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cScope       := nvl(hb_HGetDef(par_hValues,"Scope",""),"")

local l_cSitePath    := oFcgi:RequestSettings["SitePath"]

local l_oDB_ListOfPackages := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1               := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oDataEntityInfo
local l_nNumberOfPackages

oFcgi:TraceAdd("EntityEditFormBuild")

with object l_oDB_ListOfPackages
    //Build the list of Packages
    :Table("49dcc5f0-0264-4ee7-94a8-2f9a10567338","Package")
    :Column("Package.pk"         , "pk")
    :Column("Package.FullName"   , "Package_FullName")
    :Column("Package.FullPk"     , "Package_FullPk")
    :Column("Package.TreeOrder1" , "Tag1")
    :Where("Package.fk_Model = ^" , par_iModelPk)
    :OrderBy("Tag1")
    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith

with object l_oDB1
    if !empty(par_iPk)
        :Table("a05dcef9-e334-4b36-9243-850205947fcd","Entity")
        :Column("Entity.LinkUID","Entity_LinkUID")
        l_oDataEntityInfo := :Get(par_iPk)
    endif
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EntityKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFEntity+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-5 HideOnEdit" href="]+l_cSitePath+[Modeling/ListAttributes/]+l_oDataEntityInfo:Entity_LinkUID+[/">]+oFcgi:p_ANFAttributes+[</a>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfPackages > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Parent ]+oFcgi:p_ANFPackage+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                    select ListOfPackages
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->pk = l_ifk_Package,[ selected],[])+[>]+AllTrim(ListOfPackages->Package_FullName)+[</option>]
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">]+oFcgi:p_ANFEntity+[ Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Scope</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextScope" id="TextScope" rows="10" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cScope)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ENTITY,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextScope').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function EntityEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iEntityPk
local l_iEntityFk_Package
local l_cEntityName
local l_cEntityDescription
local l_cEntityScope
local l_cFrom := ""
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("EntityEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEntityPk          := Val(oFcgi:GetInputValue("EntityKey"))

l_iEntityFk_Package  := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cEntityName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cEntityDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_cEntityScope       := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextScope")))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cEntityName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("1cebbf7a-1015-456b-bc5d-6f457871afe0","Entity")
                :Column("Entity.pk","pk")
                :Where([Entity.fk_Model = ^],par_iModelPk)
                :Where([lower(replace(Entity.Name,' ','')) = ^],lower(StrTran(l_cEntityName," ","")))
                if l_iEntityPk > 0
                    :Where([Entity.pk != ^],l_iEntityPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Entity
        with object l_oDB1
            :Table("65439d45-fe73-4598-8f46-d3a2b53ab520","Entity")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("Entity.fk_package",l_iEntityFk_Package)
                :Field("Entity.Name"      ,l_cEntityName)
            endif
            :Field("Entity.Description" ,iif(empty(l_cEntityDescription),NULL,l_cEntityDescription))
            :Field("Entity.Scope" ,iif(empty(l_cEntityScope),NULL,l_cEntityScope))
            if empty(l_iEntityPk)
                :Field("Entity.LinkUID"  , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("Entity.fk_Model" , par_iModelPk)
                if :Add()
                    l_iEntityPk := :Key()
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to add Entity."
                endif
            else
                if :Update(l_iEntityPk)
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to update Entity."
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelML >= 5
                CustomFieldsSave(par_iProjectPk,USEDON_ENTITY,l_iEntityPk)
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    l_cFrom := oFcgi:GetQueryString('From')
    //_M_

    // switch l_cFrom
    // case 'Attributes'
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cURLProjectLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEntityName+"/")
    //     exit
    // otherwise
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cURLProjectLinkCode+"/")
    // endswitch

case l_cActionOnSubmit == "Delete"   // Entity
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveModelDelete(par_iModelPk)
            l_cErrorMessage := CascadeDeleteEntity(par_iProjectPk,l_iEntityPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
                l_cFrom := "Redirect"
            endif
        else
            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("d8f4ccf0-5cd0-410e-9137-ba452d10904c","Attribute")
                :Where("Attribute.fk_Entity = ^",l_iEntityPk)
                :SQL()

                if :Tally == 0
                    :Table("a7ca6a00-0329-46e3-bedb-431f9610dde2","Endpoint")
                    :Where("Endpoint.fk_Entity = ^",l_iEntityPk)
                    :SQL()

                    if :Tally == 0
                        //Delete any DiagramEntity related records
                        :Table("0a20ae4a-cb63-47d5-a6fa-90f3c927e281","DiagramEntity")
                        :Column("DiagramEntity.pk" , "pk")
                        :Where("DiagramEntity.fk_Entity = ^",l_iEntityPk)
                        :SQL("ListOfDiagramEntityRecordsToDelete")
                        if :Tally >= 0
                            if :Tally > 0
                                select ListOfDiagramEntityRecordsToDelete
                                scan
                                    l_oDB2:Delete("a29d2506-9044-497e-8de3-06a08120e9bf","DiagramEntity",ListOfDiagramEntityRecordsToDelete->pk)
                                endscan
                            endif

                            CustomFieldsDelete(par_iProjectPk,USEDON_ENTITY,l_iEntityPk)
                            if :Delete("6818930c-2486-49b9-a2b6-df7d50dd020f","Entity",l_iEntityPk)
                                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
                                l_cFrom := "Redirect"
                            else
                                l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFEntity+[.]
                            endif
                        else
                            l_cErrorMessage := [Failed to clear related Diagram ]+oFcgi:p_ANFEntity+[ records.]
                        endif
                    else
                        l_cErrorMessage := [Related ]+oFcgi:p_ANFAssociation+[ record on file.]
                    endif
                else
                    l_cErrorMessage := [Related ]+oFcgi:p_ANFAttribute+[ record on file.]
                endif
            endwith
        endif
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"
case !empty(l_cErrorMessage)
    l_hValues["fk_package"]  := l_iEntityFk_Package
    l_hValues["Name"]        := l_cEntityName
    l_hValues["Description"] := l_cEntityDescription
    l_hValues["Scope"]       := l_cEntityScope
    CustomFieldsFormToHash(par_iProjectPk,USEDON_ENTITY,@l_hValues)

    l_cHtml += EntityEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,l_cErrorMessage,l_iEntityPk,l_hValues)

case empty(l_cFrom) .or. empty(l_iEntityPk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")

otherwise
    with object l_oDB1
        :Table("830269a7-e544-4527-b8ee-151990def7ce","Entity")
        :Column("Entity.Name","Entity_Name")
        l_oData := :Get(l_iEntityPk)
        if :Tally <> 1
            l_cFrom := ""
        endif
    endwith
    switch l_cFrom
    case 'Attributes'
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/")
        exit
    otherwise
        //Should not happen. Failed :Get.
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
    endswitch
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================


//xxxxxxxxxxxxxxxxxxxxxxxxxxxxx


//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function PackageListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfPackages := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iPackagePk

local l_nNumberOfPackages := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nColspan
local l_ScriptFolder

oFcgi:TraceAdd("PackageListFormBuild")

with object l_oDB_ListOfPackages
    :Table("e0c3c824-5ab0-4fce-8234-1c646e8ac803","Package")
    :Column("Package.pk"        ,"pk")
    :Column("Package.LinkUID"   ,"Package_LinkUID")
    :Column("Package.FullName"  ,"Package_FullName")
    :Column("Package.TreeOrder1","tag1")
    :Where("Package.fk_Model = ^",par_iModelPk)
    :OrderBy("tag1")
    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith

if l_nNumberOfPackages > 0
    with object l_oDB_CustomFields
        :Table("38d8d1fe-689e-42d2-b175-675c1595ef92","Package")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Package.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Package.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_PACKAGE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("bb5fb954-25b9-47be-bb8e-16aa81142221","Package")
        :Column("Package.pk"             ,"fk_Entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Package.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Package.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_PACKAGE)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally
    endwith

endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    if oFcgi:p_nAccessLevelML >= 5
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewPackage/]+par_cModelLinkUID+[/">New ]+oFcgi:p_ANFPackage+[</a>]
                    else
                        l_cHtml += [<span class="ms-3"> </a>]  //To make some spacing
                    endif
                l_cHtml += [</td>]
                // ----------------------------------------
                // ----------------------------------------
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfPackages)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]
            
            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"1","2")+[">]+oFcgi:p_ANFPackages+[ (]+Trans(l_nNumberOfPackages)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Full Name</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfPackages
            scan all
                l_iPackagePk := ListOfPackages->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditPackage/]+ListOfPackages->Package_LinkUID+[/">]+ListOfPackages->Package_FullName+[</a>]
                    l_cHtml += [</td>]

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(ListOfPackages->pk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function PackageEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName       := hb_HGetDef(par_hValues,"Name","")
local l_ifk_Package := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cSitePath   := oFcgi:RequestSettings["SitePath"]
local l_oDB1        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDataPackageInfo
local l_nNumberOfOtherPackages

oFcgi:TraceAdd("PackageEditFormBuild")

with object l_oDB1
    if !empty(par_iPk)
        :Table("e65933a7-df13-4922-a3ca-c5b04569f131","Package")
        :Column("Package.LinkUID","Package_LinkUID")
        l_oDataPackageInfo := :Get(par_iPk)
    endif

    //Build the list of Other Packages
    :Table("95cf41eb-a959-4330-803c-eb08af66425d","Package")
    :Column("Package.pk"         , "pk")
    :Column("Package.FullName"   , "Package_FullName")
    :Column("Package.FullPk"     , "Package_FullPk")
    :Column("Package.TreeOrder1" , "Tag1")
    :Where("Package.fk_Model = ^" , par_iModelPk)
    if !empty(par_iPk)
        :Where("Package.pk <> ^" , par_iPk)
    endif
    :OrderBy("Tag1")
    :SQL("ListOfOtherPackages")
    l_nNumberOfOtherPackages := :Tally

endwith


l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="PackageKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFPackage+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfOtherPackages > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Parent ]+oFcgi:p_ANFPackage+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                    select ListOfOtherPackages
                    scan all
                        if !("*"+Trans(par_iPk)+"*" $ "*"+ListOfOtherPackages->Package_FullPk+"*")
                            l_cHtml += [<option value="]+Trans(ListOfOtherPackages->pk)+["]+iif(ListOfOtherPackages->pk = l_ifk_Package,[ selected],[])+[>]+AllTrim(ListOfOtherPackages->Package_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_PACKAGE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function PackageEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iPackagePk
local l_iPackageFk_Package
local l_cPackageName
local l_cFrom := ""
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("PackageEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iPackagePk         := Val(oFcgi:GetInputValue("PackageKey"))

l_iPackageFk_Package := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cPackageName       := SanitizeInput(oFcgi:GetInputValue("TextName"))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cPackageName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("7ae562f7-ab34-4b8b-9a68-9eabde0a201f","Package")
                :Column("Package.pk","pk")
                :Where([Package.fk_Model = ^],par_iModelPk)
                :Where([lower(replace(Package.Name,' ','')) = ^],lower(StrTran(l_cPackageName," ","")))
                if l_iPackagePk > 0
                    :Where([Package.pk != ^],l_iPackagePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Package
        with object l_oDB1
            :Table("9f3ba3e8-ce98-4539-8ef1-9dcfa9effc51","Package")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("Package.fk_package",l_iPackageFk_Package)
                :Field("Package.Name"      ,l_cPackageName)
            endif
            if empty(l_iPackagePk)
                :Field("Package.LinkUID"  , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("Package.fk_Model" , par_iModelPk)
                if :Add()
                    l_iPackagePk := :Key()
                    FixNonNormalizeFieldsInPackage(par_iModelPk)
                else
                    l_cErrorMessage := "Failed to add Package."
                endif
            else
                if :Update(l_iPackagePk)
                    FixNonNormalizeFieldsInPackage(par_iModelPk)
                else
                    l_cErrorMessage := "Failed to update Package."
                endif
            endif

            if empty(l_cErrorMessage)
                CustomFieldsSave(par_iProjectPk,USEDON_PACKAGE,l_iPackagePk)
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Delete"   // Package
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("e27542d9-44ab-43df-8738-2e2d61fc87cd","Entity")
            :Where("Entity.fk_Package = ^",l_iPackagePk)
            :SQL()
            if :Tally == 0
                :Table("589d6f0c-1c69-4bad-89c9-29c1e2091140","Association")
                :Where("Association.fk_Package = ^",l_iPackagePk)
                :SQL()
                if :Tally == 0
                    :Table("b69dbcba-d160-4a4b-89cf-1a1e9bc15ae5","Package")
                    :Where("Package.fk_Package = ^",l_iPackagePk)
                    :SQL()
                    if :Tally == 0
                        CustomFieldsDelete(par_iProjectPk,USEDON_PACKAGE,l_iPackagePk)
                        if :Delete("118f7bd4-c4fe-4057-8f3f-cd1808808f81","Package",l_iPackagePk)
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListPackages/"+par_cModelLinkUID+"/")
                            l_cFrom := "Redirect"
                        else
                            l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFPackage+[.]
                        endif
                    else
                        l_cErrorMessage := [Related ]+oFcgi:p_ANFPackage+[ record on file.]
                    endif
                else
                    l_cErrorMessage := [Related ]+oFcgi:p_ANFAssociation+[ record on file.]
                endif
            else
                l_cErrorMessage := [Related ]+oFcgi:p_ANFEntity+[ record on file.]
            endif
        endwith
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"
case !empty(l_cErrorMessage)
    l_hValues["fk_package"] := l_iPackageFk_Package
    l_hValues["Name"]       := l_cPackageName
    CustomFieldsFormToHash(par_iProjectPk,USEDON_PACKAGE,@l_hValues)

    l_cHtml += PackageEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID,l_cErrorMessage,l_iPackagePk,l_hValues)

case empty(l_cFrom) .or. empty(l_iPackagePk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListPackages/"+par_cModelLinkUID+"/")

otherwise
    //Should not happen. Failed :Get.
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function DataTypeListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfDataTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields    := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iDataTypePk

local l_nNumberOfDataTypes := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nColspan
local l_ScriptFolder

oFcgi:TraceAdd("DataTypeListFormBuild")

with object l_oDB_ListOfDataTypes
    :Table("96013fec-eb2d-4a2c-ad59-080501e21fd2","DataType")
    :Column("DataType.pk"         ,"pk")
    :Column("DataType.LinkUID"    ,"DataType_LinkUID")
    :Column("DataType.FullName"   ,"DataType_FullName")
    :Column("DataType.Description","DataType_Description")
    :Column("DataType.TreeOrder1","tag1")
    :Where("DataType.fk_Model = ^",par_iModelPk)
    :OrderBy("tag1")
    :SQL("ListOfDataTypes")
    l_nNumberOfDataTypes := :Tally
endwith

if l_nNumberOfDataTypes > 0
    with object l_oDB_CustomFields
        :Table("d38a3f38-a8ba-4985-9e31-a184a1a4db44","DataType")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = DataType.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("DataType.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_DATATYPE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("d27b9075-1914-40e5-80a6-e443005ddd6e","DataType")
        :Column("DataType.pk"            ,"fk_Entity")
        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = DataType.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("DataType.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_DATATYPE)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally
    endwith

endif

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    if oFcgi:p_nAccessLevelML >= 5
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewDataType/]+par_cModelLinkUID+[/">New ]+oFcgi:p_ANFDataType+[</a>]
                    else
                        l_cHtml += [<span class="ms-3"> </a>]  //To make some spacing
                    endif
                l_cHtml += [</td>]
                // ----------------------------------------
                // ----------------------------------------
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfDataTypes)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]
            
            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"2","3")+[">]+oFcgi:p_ANFDataTypes+[ (]+Trans(l_nNumberOfDataTypes)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Full Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfDataTypes
            scan all
                l_iDataTypePk := ListOfDataTypes->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditDataType/]+ListOfDataTypes->DataType_LinkUID+[/">]+ListOfDataTypes->DataType_FullName+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfDataTypes->DataType_Description,""))
                    l_cHtml += [</td>]

                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(ListOfDataTypes->pk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function DataTypeEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText    := hb_DefaultValue(par_cErrorText,"")

local l_ifk_DataType := nvl(hb_HGetDef(par_hValues,"fk_DataType",0),0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_cSitePath     := oFcgi:RequestSettings["SitePath"]
local l_oDB1          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDataDataTypeInfo
local l_nNumberOfOtherDataTypes

oFcgi:TraceAdd("DataTypeEditFormBuild")

with object l_oDB1
    if !empty(par_iPk)
        :Table("ca3eddb8-ac0e-4051-afd0-28e6bca92fa2","DataType")
        :Column("DataType.LinkUID","DataType_LinkUID")
        l_oDataDataTypeInfo := :Get(par_iPk)
    endif

    //Build the list of Other DataTypes
    :Table("c6c1c8e3-b91c-4660-b4be-10ee25a6124e","DataType")
    :Column("DataType.pk"         , "pk")
    :Column("DataType.FullName"   , "DataType_FullName")
    :Column("DataType.FullPk"     , "DataType_FullPk")
    :Column("DataType.TreeOrder1" , "Tag1")
    :Where("DataType.fk_Model = ^" , par_iModelPk)
    if !empty(par_iPk)
        :Where("DataType.pk <> ^" , par_iPk)
    endif
    :OrderBy("Tag1")
    :SQL("ListOfOtherDataTypes")
    l_nNumberOfOtherDataTypes := :Tally
    // SendToClipboard(l_oDB1:LastSQL())

endwith


l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="DataTypeKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFDataType+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfOtherDataTypes > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Parent ]+oFcgi:p_ANFDataType+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboDataTypePk" id="ComboDataTypePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_DataType,[ selected],[])+[></option>]
                    select ListOfOtherDataTypes
                    scan all
                        if !("*"+Trans(par_iPk)+"*" $ "*"+ListOfOtherDataTypes->DataType_FullPk+"*")
                            l_cHtml += [<option value="]+Trans(ListOfOtherDataTypes->pk)+["]+iif(ListOfOtherDataTypes->pk = l_ifk_DataType,[ selected],[])+[>]+AllTrim(ListOfOtherDataTypes->DataType_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_DATATYPE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function DataTypeEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iDataTypePk
local l_iDataTypeFk_DataType
local l_cDataTypeName
local l_cDataTypeDescription
local l_cFrom := ""
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("DataTypeEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iDataTypePk   := Val(oFcgi:GetInputValue("DataTypeKey"))

l_iDataTypeFk_DataType := Val(oFcgi:GetInputValue("ComboDataTypePk"))
l_cDataTypeName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cDataTypeDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cDataTypeName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("8172f003-918e-4279-b043-e22e9ab29850","DataType")
                :Column("DataType.pk","pk")
                :Where([DataType.fk_Model = ^],par_iModelPk)
                :Where([lower(replace(DataType.Name,' ','')) = ^],lower(StrTran(l_cDataTypeName," ","")))
                if l_iDataTypePk > 0
                    :Where([DataType.pk != ^],l_iDataTypePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the DataType
        with object l_oDB1
            :Table("14c5f95d-d6d9-4382-98b2-788de3f9d2b5","DataType")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("DataType.fk_DataType",l_iDataTypeFk_DataType)
                :Field("DataType.Name"       ,l_cDataTypeName)
                :Field("DataType.Description",iif(empty(l_cDataTypeDescription),NULL,l_cDataTypeDescription))
            endif
            if empty(l_iDataTypePk)
                :Field("DataType.LinkUID"  , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("DataType.fk_Model" , par_iModelPk)
                if :Add()
                    l_iDataTypePk := :Key()
                    FixNonNormalizeFieldsInDataType(par_iModelPk)
                else
                    l_cErrorMessage := [Failed to add ]+oFcgi:p_ANFDataType+[.]
                endif
            else
                if :Update(l_iDataTypePk)
                    FixNonNormalizeFieldsInDataType(par_iModelPk)
                else
                    l_cErrorMessage := [Failed to update ]+oFcgi:p_ANF+[DataType.]
                endif
            endif

            if empty(l_cErrorMessage)
                CustomFieldsSave(par_iProjectPk,USEDON_DATATYPE,l_iDataTypePk)
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Delete"   // DataType
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("7bd8406b-6477-47ef-b7f9-8a3712c87950","Attribute")
            :Where("Attribute.fk_DataType = ^",l_iDataTypePk)
            :SQL()
            if :Tally == 0
                :Table("e4cca446-b95b-4bb7-85a6-c888ff3a884c","DataType")
                :Where("DataType.fk_DataType = ^",l_iDataTypePk)
                :SQL()
                if :Tally == 0
                    CustomFieldsDelete(par_iProjectPk,USEDON_DATATYPE,l_iDataTypePk)
                    if :Delete("d95ff462-fd11-4ea8-abde-368ad8c0abd2","DataType",l_iDataTypePk)
                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")
                        l_cFrom := "Redirect"
                    else
                        l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFDataType+[.]
                    endif
                else
                    l_cErrorMessage := [Related ]+oFcgi:p_ANFDataType+[ record on file.]
                endif
            else
                l_cErrorMessage := [Related ]+oFcgi:p_ANFAttribute+[ record on file.]
            endif
        endwith
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"
case !empty(l_cErrorMessage)
    l_hValues["fk_DataType"] := l_iDataTypeFk_DataType
    l_hValues["Name"]        := l_cDataTypeName
    l_hValues["Description"] := l_cDataTypeDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_DATATYPE,@l_hValues)

    l_cHtml += DataTypeEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID,l_cErrorMessage,l_iDataTypePk,l_hValues)

case empty(l_cFrom) .or. empty(l_iDataTypePk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")

otherwise
    //Should not happen. Failed :Get.
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfAssociations               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAssociationsEndpoints      := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_oDB_ListOfAssociationsEndpointCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iAssociationPk
local l_nEndpointCount

local l_cSearchAssociationName
local l_cSearchAssociationDescription

local l_cSearchEndpointName
local l_cSearchEndpointDescription

local l_nNumberOfAssociations := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cEndpointSearchParameters
local l_nColspan
local l_ScriptFolder

oFcgi:TraceAdd("AssociationListFormBuild")

l_cSearchAssociationName           := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationName")
l_cSearchAssociationDescription    := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationDescription")

l_cSearchEndpointName        := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointName")
l_cSearchEndpointDescription := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointDescription")

if empty(l_cSearchEndpointName) .and. empty(l_cSearchEndpointDescription)
    l_cEndpointSearchParameters := ""
else
    l_cEndpointSearchParameters := [Search?EndpointName=]+hb_StrToHex(l_cSearchEndpointName)+[&EndpointDescription=]+hb_StrToHex(l_cSearchEndpointDescription)   //strtolhex
endif

with object l_oDB_ListOfAssociations
    :Table("32746fc3-3116-497f-becc-f51b1213849c","Association")
    :Column("Association.pk"         ,"pk")
    :Column("Association.LinkUID"    ,"Association_LinkUID")
    :Column("Association.Name"       ,"Association_Name")
    :Column("Association.Description","Association_Description")
    :Column("Upper(Association.Name)","tag2")
    :Where("Association.fk_Model = ^",par_iModelPk)

    if !empty(l_cSearchAssociationName)
        :KeywordCondition(l_cSearchAssociationName,"Association.Name")
    endif
    if !empty(l_cSearchAssociationDescription)
        :KeywordCondition(l_cSearchAssociationDescription,"Association.Description")
    endif
    if !empty(l_cSearchEndpointName) .or. !empty(l_cSearchEndpointDescription)
        :Distinct(.t.)
        :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
        :Join("inner","Entity"  ,"","Endpoint.fk_Entity = Entity.pk")
        if !empty(l_cSearchEndpointName)
            // :KeywordCondition(l_cSearchEndpointName,"Endpoint.Name")
            :KeywordCondition(l_cSearchEndpointName,"CONCAT(Entity.Name,' ',Endpoint.Name)")
        endif
        if !empty(l_cSearchEndpointDescription)
            :KeywordCondition(l_cSearchEndpointDescription,"Endpoint.Description")
        endif
    endif

    :Join("left","Package","","Association.fk_Package = Package.pk")
    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
    :Column("Package.FullName"               , "Package_FullName")

    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfAssociations")
    l_nNumberOfAssociations := :Tally

    // SendToClipboard(:LastSQL())

endwith

if l_nNumberOfAssociations > 0
    with object l_oDB_CustomFields
        :Table("ee57e7eb-50a9-4207-8b4c-a9a786513707","Association")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Association.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Association.fk_Model = ^",par_iModelPk)

        :Where("CustomField.UsedOn = ^",USEDON_ASSOCIATION)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice

        if !empty(l_cSearchAssociationName)
            :KeywordCondition(l_cSearchAssociationName,"Association.Name")
        endif
        if !empty(l_cSearchAssociationDescription)
            :KeywordCondition(l_cSearchAssociationDescription,"Association.Description")
        endif
        if !empty(l_cSearchEndpointName) .or. !empty(l_cSearchEndpointDescription)
            :Distinct(.t.)
            :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
            :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
            if !empty(l_cSearchEndpointName)
                // :KeywordCondition(l_cSearchEndpointName,"Endpoint.Name")
                :KeywordCondition(l_cSearchEndpointName,"CONCAT(Entity.Name,' ',Endpoint.Name)")
            endif
            if !empty(l_cSearchEndpointDescription)
                :KeywordCondition(l_cSearchEndpointDescription,"Endpoint.Description")
            endif
        endif
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("199bf026-c30e-4ab7-89f5-52b651fdd33f","Association")
        :Column("Association.pk"              ,"fk_Association")

        :Column("CustomField.pk"         ,"CustomField_pk")
        :Column("CustomField.Label"      ,"CustomField_Label")
        :Column("CustomField.Type"       ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI","CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM","CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD","CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)","tag1")

        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Association.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")

        :Where("Association.fk_Model = ^",par_iModelPk)
        :Where("CustomField.UsedOn = ^",USEDON_ASSOCIATION)
        :Where("CustomField.Status <= 2")

        if !empty(l_cSearchAssociationName)
            :KeywordCondition(l_cSearchAssociationName,"Association.Name")
        endif
        if !empty(l_cSearchAssociationDescription)
            :KeywordCondition(l_cSearchAssociationDescription,"Association.Description")
        endif
        if !empty(l_cSearchEndpointName) .or. !empty(l_cSearchEndpointDescription)
            :Distinct(.t.)
            :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
            :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
            if !empty(l_cSearchEndpointName)
                // :KeywordCondition(l_cSearchEndpointName,"Endpoint.Name")
                :KeywordCondition(l_cSearchEndpointName,"CONCAT(Entity.Name,' ',Endpoint.Name)")
            endif
            if !empty(l_cSearchEndpointDescription)
                :KeywordCondition(l_cSearchEndpointDescription,"Endpoint.Description")
            endif
        endif
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

endif


//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
// with object l_oDB_ListOfAssociationsEndpointCounts
//     :Table("db818131-6cee-43a8-81a3-2ff610842a2f","Association")
//     :Column("Association.pk","Association_pk")
//     :Column("Count(*)" ,"EndpointCount")
//     :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
//     :Where("Association.fk_Model = ^",par_iModelPk)
//     :GroupBy("Association.pk")
//     :SQL("ListOfAssociationsEndpointCounts")

//     with object :p_oCursor
//         :Index("tag1","Association_pk")
//         :CreateIndexes()
//         :SetOrder("tag1")
//     endwith

// endwith

with object l_oDB_ListOfAssociationsEndpoints
    :Table("ac8cb457-53ec-41f2-aa9d-8e68ce3efd92","Association")
    :Column("Association.pk","Association_pk")
    :Column("Entity.name" ,"Entity_name")
    :Column("upper(Entity.name)" ,"tag2")
    :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
    :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
    :Where("Association.fk_Model = ^",par_iModelPk)
    :OrderBy("Association_pk")
    :OrderBy("tag2")
    :SQL("ListOfAssociationsEndpoints")

    with object :p_oCursor
        :Index("tag1","Association_pk")
        :CreateIndexes()
        // :SetOrder("tag1")
    endwith
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="List">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<table>]
            l_cHtml += [<tr>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    if oFcgi:p_nAccessLevelML >= 5
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewAssociation/]+par_cModelLinkUID+[/">New ]+oFcgi:p_ANFAssociation+[</a>]
                    else
                        l_cHtml += [<span class="ms-3"> </a>]  //To make some spacing
                    endif
                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td valign="top">]
                    l_cHtml += [<table>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td></td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                            l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">]+oFcgi:p_ANFAssociation+[</span></td>]
                            l_cHtml += [<td><input type="text" name="TextAssociationName" id="TextAssociationName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAssociationName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextAssociationDescription" id="TextAssociationDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAssociationDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">]+oFcgi:p_ANFEntity+[</span></td>]
                            l_cHtml += [<td><input type="text" name="TextEndpointName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEndpointName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextEndpointDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEndpointDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                    l_cHtml += [</table>]

                l_cHtml += [</td>]
                // ----------------------------------------
                l_cHtml += [<td>]  // valign="top"
                    l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-5 me-3" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
                    l_cHtml += [<input type="button" class="btn btn-primary rounded me-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]
                l_cHtml += [</td>]
                // ----------------------------------------
            l_cHtml += [</tr>]
        l_cHtml += [</table>]



    l_cHtml += [</div>]

l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfAssociations)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_nColspan := 5
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan += 1
            endif

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+Trans(l_nColspan)+[">]+oFcgi:p_ANFAssociations+[ (]+Trans(l_nNumberOfAssociations)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFPackage+[</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFAssociation+[ Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">]+oFcgi:p_ANFEntities+[</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfAssociations
            scan all
                l_iAssociationPk := ListOfAssociations->pk

                l_cHtml += [<tr>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += Allt(nvl(ListOfAssociations->Package_FullName,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditAssociation/]+ListOfAssociations->Association_LinkUID+[/">]+ListOfAssociations->Association_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        // l_nEndpointCount := iif( VFP_Seek(l_iAssociationPk,"ListOfAssociationsEndpointCounts","tag1") , ListOfAssociationsEndpointCounts->EndpointCount , 0)
                        // l_cHtml += Trans(l_nEndpointCount)
                        select ListOfAssociationsEndpoints
                        scan all for ListOfAssociationsEndpoints->Association_pk == l_iAssociationPk
                            l_cHtml += [<div>]+ListOfAssociationsEndpoints->Entity_name+[</div>]
                        endscan
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfAssociations->Association_Description,""))
                    l_cHtml += [</td>]


                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += CustomFieldsBuildGridOther(l_iAssociationPk,l_hOptionValueToDescriptionMapping)
                        l_cHtml += [</td>]
                    endif
                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

return l_cHtml
//=================================================================================================================
static function AssociationListFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_cAssociationName
local l_cAssociationDescription
local l_cEndpointName
local l_cEndpointDescription
local l_cURL

oFcgi:TraceAdd("AssociationListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cAssociationName           := SanitizeInput(oFcgi:GetInputValue("TextAssociationName"))
l_cAssociationDescription    := SanitizeInput(oFcgi:GetInputValue("TextAssociationDescription"))

l_cEndpointName        := SanitizeInput(oFcgi:GetInputValue("TextEndpointName"))
l_cEndpointDescription := SanitizeInput(oFcgi:GetInputValue("TextEndpointDescription"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationName"        ,l_cAssociationName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationDescription" ,l_cAssociationDescription)

    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointName"       ,l_cEndpointName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointDescription",l_cEndpointDescription)

    l_cHtml += AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationName"        ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationDescription" ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointName"       ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointDescription","")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"Modeling/ListAssociations/"+par_cModelLinkUID+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
static function AssociationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_ifk_Package  := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_cSitePath    := oFcgi:RequestSettings["SitePath"]

local l_oDB_ListOfPackages    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAllEntities := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_nNumberOfAllEntities
local l_oDataAssociationInfo
local l_nNumberOfPackages

local l_nCounter
local l_nCounterC

local l_json_Entities
local l_iEntityPk
local l_hEntityNames := {=>}
local l_cInfo
local l_cObjectName

local l_iEndpoint_pk
local l_iEndpoint_Fk_Entity
local l_cEndpoint_Name
local l_cEndpoint_BoundLower
local l_cEndpoint_BoundUpper
local l_lEndpoint_AspectOf
local l_cEndpoint_Description

oFcgi:TraceAdd("AssociationEditFormBuild")

with object l_oDB_ListOfPackages
    //Build the list of Packages
    :Table("2b19ee5b-91ec-4d24-9934-80ef27c3d11d","Package")
    :Column("Package.pk"         , "pk")
    :Column("Package.FullName"   , "Package_FullName")
    :Column("Package.FullPk"     , "Package_FullPk")
    :Column("Package.TreeOrder1" , "Tag1")
    :Where("Package.fk_Model = ^" , par_iModelPk)
    :OrderBy("Tag1")
    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith

with object l_oDB1
    if !empty(par_iPk)
        :Table("feaecfcd-74c9-4a86-8354-fb487ecae2aa","Association")
        :Column("Association.LinkUID","Association_LinkUID")
        l_oDataAssociationInfo := :Get(par_iPk)
    endif
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="AssociationKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFAssociation+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
            // l_cHtml += [<a class="btn btn-primary rounded ms-5 HideOnEdit" href="]+l_cSitePath+[Modeling/ListEndpoints/]+l_oDataAssociationInfo:Association_LinkUID+[/">Endpoints</a>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfPackages > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">]+oFcgi:p_ANFPackage+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                    select ListOfPackages
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->pk = l_ifk_Package,[ selected],[])+[>]+AllTrim(ListOfPackages->Package_FullName)+[</option>]
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Association Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ASSOCIATION,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

    SetSelect2Support()

    with object l_oDB_ListOfAllEntities
        :Table("8c4054d1-6f50-427e-aa41-2b53f8ebad2b","Entity")
        :Column("Entity.pk"                      , "pk")
        :Column("Package.FullName"               , "Package_FullName")
        :Column("Entity.Name"                    , "Entity_Name")
        :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")           // _M_ Cast as integer
        :Column("Upper(Entity.Name)"             , "tag2")
        :Where("Entity.fk_Model = ^" , par_iModelPk)
        :join("left","Package","","Entity.fk_Package = Package.pk")
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfAllEntities")
        l_nNumberOfAllEntities := :Tally

    endwith

    // Packages info
    l_json_Entities := []
    select ListOfAllEntities
    scan all

        if !empty(l_json_Entities)
            l_json_Entities += [,]
        endif
        if !hb_orm_isnull("ListOfAllEntities","Package_FullName")
            l_cInfo = ListOfAllEntities->Package_FullName+" / "+ListOfAllEntities->Entity_Name
        else
            l_cInfo = ListOfAllEntities->Entity_Name
        endif
        l_cInfo := vfp_StrReplace(l_cInfo,{;
                                        [\] => [\\] ,;
                                        ["] => [ ] ,;
                                        ['] => [ ] ;
                                     },,1)
        l_json_Entities += "{id:"+trans(ListOfAllEntities->pk)+",text:'"+l_cInfo+"'}"
        l_hEntityNames[ListOfAllEntities->pk] := l_cInfo   // Will be used to assist in setting up default <select> <option>
    endscan
    l_json_Entities := "["+l_json_Entities+"]"

    //Call the jQuery code even before the for loop, since it will be used after html is loaded anyway.
    oFcgi:p_cjQueryScript += [$(".SelectEntity").select2({placeholder: '',allowClear: true,data: ]+l_json_Entities+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]


// oFcgi:p_cjQueryScript += [$(document).on('select2:open', () => { document.querySelector('.select2-search__field').focus();  });]



    l_cHtml += [<div>]
        // l_cHtml += [<table class="ms-0 table" style="width:auto;">]  //table-striped
        l_cHtml += [<table style="width:auto;">]  //table-striped

            for l_nCounter := 1 to hb_HGetDef(par_hValues,"NumberOfPossibleEndpoints",3)
                l_nCounterC := Trans(l_nCounter)

                l_iEndpoint_pk          := nvl(hb_HGetDef(par_hValues,"EndpointPk"+l_nCounterC,0),0)
                l_iEndpoint_Fk_Entity   := nvl(hb_HGetDef(par_hValues,"EndpointFk_Entity"+l_nCounterC,0),0)
                l_cEndpoint_Name        := nvl(hb_HGetDef(par_hValues,"EndpointName"+l_nCounterC,""),"")
                l_cEndpoint_BoundLower  := nvl(hb_HGetDef(par_hValues,"EndpointBoundLower"+l_nCounterC,""),"")
                l_cEndpoint_BoundUpper  := nvl(hb_HGetDef(par_hValues,"EndpointBoundUpper"+l_nCounterC,""),"")
                l_lEndpoint_AspectOf    := nvl(hb_HGetDef(par_hValues,"EndpointAspectOf"+l_nCounterC,.f.),.f.)
                l_cEndpoint_Description := nvl(hb_HGetDef(par_hValues,"EndpointDescription"+l_nCounterC,""),"")

                l_cHtml += [<tr class="bg-secondary">]
                // l_cHtml += [<tr class="table-dark">]
                    l_cHtml += [<td class="ps-2 text-white">]+oFcgi:p_ANFEntity
                        l_cObjectName := "TextEndpoint_pk"+l_nCounterC
                        l_cHtml += [<input type="hidden" name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="]+Trans(l_iEndpoint_pk)+[">]
                    l_cHtml += [</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Bound<br>Lower</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Bound<br>Upper</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Aspect<br>Of</td>]
                    l_cHtml += [<td class="ps-2 text-white">Name (of ]+oFcgi:p_ANFAssociation+[ to the ]+oFcgi:p_ANFEntity+[)</td>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="pb-5">]
                    // l_cHtml += [<td class="pe-2 pb-3">]+oFcgi:p_ANFEntity+[</td>]

                    //Entity
                    l_cHtml += [<td class="pt-2" valign="top">]
                    
                        l_cObjectName := "ComboEndpoint_Fk_Entity"+l_nCounterC
                        l_cHtml += [<select name="]+l_cObjectName+[" id="]+l_cObjectName+[" class="SelectEntity" style="width:600px">]
                        if l_iEndpoint_Fk_Entity == 0
                            oFcgi:p_cjQueryScript += [$("#]+l_cObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
                        else
                            //select2 will place the current selected option at the top of the list of options, overriding the initial order.
                            l_cHtml += [<option value="]+Trans(l_iEndpoint_Fk_Entity)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iEndpoint_Fk_Entity,"")+[</option>]
                        endif
                        l_cHtml += [</select>]
                    l_cHtml += [</td>]

                    //Bound Lower
                    l_cHtml += [<td class="ps-2 pt-2" valign="top">]
                        l_cObjectName := "TextBoundLower"+l_nCounterC
                        l_cHtml += [<input type="text" value="]+FcgiPrepFieldForValue(l_cEndpoint_BoundLower)+[" id="]+l_cObjectName+[" name="]+l_cObjectName+[" maxlength="4" size="2">]
                    l_cHtml += [</td>]

                    //Bound Upper
                    l_cHtml += [<td class="ps-2 pt-2" valign="top">]
                        l_cObjectName := "TextBoundUpper"+l_nCounterC
                        l_cHtml += [<input type="text" value="]+FcgiPrepFieldForValue(l_cEndpoint_BoundUpper)+[" id="]+l_cObjectName+[" name="]+l_cObjectName+[" maxlength="4" size="2">]
                    l_cHtml += [</td>]

                    //Aspect Of
                    l_cHtml += [<td class="ps-2 pt-2" valign="top">]
                        l_cObjectName := "CheckAspectOf"+l_nCounterC
                        l_cHtml += [<div class="form-check form-switch">]
                            l_cHtml += [<input]+UPDATESAVEBUTTON+[ type="checkbox" name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="1"]+iif(l_lEndpoint_AspectOf," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[>]
                        l_cHtml += [</div>]
                    l_cHtml += [</td>]

                    //Name
                    l_cObjectName := "TextName"+l_nCounterC
                    l_cHtml += [<td class="ps-2 pt-2"><input]+UPDATESAVEBUTTON+[ type="text" name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="]+FcgiPrepFieldForValue(l_cEndpoint_Name)+[" maxlength="200" size="40"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]

                l_cHtml += [</tr>]


                l_cHtml += [<tr class="pb-5">]
                    //Description
                    l_cObjectName := "TextDescription"+l_nCounterC
                    l_cHtml += [<td colspan="5" class="pt-1 pb-3">Description <textarea]+UPDATESAVEBUTTON+[ name="]+l_cObjectName+[" id="]+l_cObjectName+[" rows="2" cols="40"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cEndpoint_Description)+[</textarea></td>]

                l_cHtml += [</tr>]

            enddo

        l_cHtml += [</table>]

        l_cHtml += [<input type="hidden" name="NumberOfPossibleEndpoints" value="]+l_nCounterC+[">]

    l_cHtml += [</div>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function AssociationEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iAssociationPk
local l_iAssociationFk_Package
local l_cAssociationName
local l_cAssociationDescription
local l_cFrom := ""
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2
local l_oDB_ListOfEndpoints

local l_nCounter
local l_nCounterC

local l_iEndpoint_pk
local l_iEndpoint_fk_Entity
local l_cEndpoint_Name
local l_cEndpoint_BoundLower
local l_cEndpoint_BoundUpper
local l_lEndpoint_AspectOf
local l_cEndpoint_Description
local l_nEndpoint_NumberOfEndpoints
local l_nEndpoint_NumberOfEndpoints_OnFile
local l_xValue
local l_lChanged := .f.

oFcgi:TraceAdd("AssociationEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iAssociationPk          := Val(oFcgi:GetInputValue("AssociationKey"))

l_iAssociationFk_Package  := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cAssociationName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cAssociationDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cAssociationName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("0d2e0837-c4c3-47a5-ba92-6f3ee856bb5e","Association")
                :Column("Association.pk","pk")
                :Where([Association.fk_Model = ^],par_iModelPk)
                :Where([lower(replace(Association.Name,' ','')) = ^],lower(StrTran(l_cAssociationName," ","")))
                if l_iAssociationPk > 0
                    :Where([Association.pk != ^],l_iAssociationPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Association
        with object l_oDB1
            if empty(l_iAssociationPk)
                l_nEndpoint_NumberOfEndpoints_OnFile := 0
            else
                :Table("f81f332a-f00f-475b-b37b-aed5c25d69a7","Association")
                :Column("Association.fk_package"       ,"Association_fk_package")
                :Column("Association.Name"             ,"Association_Name")
                :Column("Association.NumberOfEndpoints","Association_NumberOfEndpoints")
                :Column("Association.Description"      ,"Association_Description")
                l_oData := :Get(l_iAssociationPk)
                l_nEndpoint_NumberOfEndpoints_OnFile := l_oData:Association_NumberOfEndpoints
            endif


            :Table("036f8da5-853a-4e7f-ab12-14cc406e83f3","Association")
            if oFcgi:p_nAccessLevelML >= 5

                if empty(l_iAssociationPk) .or. l_oData:Association_fk_package <> l_iAssociationFk_Package
                    l_lChanged := .t.
                    :Field("Association.fk_package",l_iAssociationFk_Package)
                endif

                if empty(l_iAssociationPk) .or. l_oData:Association_Name <> l_cAssociationName
                    l_lChanged := .t.
                    :Field("Association.Name"      ,iif(empty(l_cAssociationName),NULL,l_cAssociationName))
                endif
            endif

            if empty(l_iAssociationPk) .or. nvl(l_oData:Association_Description,"") <> nvl(l_cAssociationDescription,"")
                l_lChanged := .t.
                :Field("Association.Description" ,iif(empty(l_cAssociationDescription),NULL,l_cAssociationDescription))
            endif

            if empty(l_iAssociationPk)
                :Field("Association.LinkUID"  , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("Association.fk_Model" , par_iModelPk)
                if :Add()
                    l_iAssociationPk := :Key()
                    l_cFrom := oFcgi:GetQueryString('From')
                else
                    l_cErrorMessage := "Failed to add Association."
                endif
            else
                if l_lChanged
                    if :Update(l_iAssociationPk)
                        l_cFrom := oFcgi:GetQueryString('From')
                    else
                        l_cErrorMessage := "Failed to update Association."
                    endif
                else
                    l_cFrom := oFcgi:GetQueryString('From')
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelML >= 5
                CustomFieldsSave(par_iProjectPk,USEDON_ASSOCIATION,l_iAssociationPk)
            endif

            //Save all the endpoints
            l_nEndpoint_NumberOfEndpoints := 0

            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
            l_oDB_ListOfEndpoints := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB_ListOfEndpoints
                :Table("b9503dbd-9230-4f13-be08-6da4c637d2f1","Endpoint")
                :Column("Endpoint.pk"          , "pk")
                :Column("Endpoint.Fk_Entity"   , "Endpoint_Fk_Entity")
                :Column("Endpoint.Name"        , "Endpoint_Name")
                :Column("Endpoint.BoundLower"  , "Endpoint_BoundLower")
                :Column("Endpoint.BoundUpper"  , "Endpoint_BoundUpper")
                :Column("Endpoint.AspectOf"    , "Endpoint_AspectOf")
                :Column("Endpoint.Description" , "Endpoint_Description")
                :Where("Endpoint.fk_Association = ^" , l_iAssociationPk)
                :SQL("ListOfEndpoints")
                // l_nEndpoint_NumberOfEndpoints_OnFile := :Tally  // Original method to get the number of endpoints, but since it is a non normalized fields, did actually load its value.
                with object :p_oCursor
                    :Index("pk","pk")
                    :CreateIndexes()
                    :SetOrder("pk")
                endwith

                for l_nCounter := 1 to Val(oFcgi:GetInputValue("NumberOfPossibleEndpoints"))
                    l_nCounterC := Trans(l_nCounter)

                    l_iEndpoint_pk          := Val(oFcgi:GetInputValue("TextEndpoint_pk"+l_nCounterC))
                    l_iEndpoint_fk_Entity   := Val(oFcgi:GetInputValue("ComboEndpoint_Fk_Entity"+l_nCounterC))
                    l_cEndpoint_Name        := SanitizeInput(oFcgi:GetInputValue("TextName"+l_nCounterC))
                    l_cEndpoint_BoundLower  := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"+l_nCounterC))
                    l_cEndpoint_BoundUpper  := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"+l_nCounterC))
                    l_lEndpoint_AspectOf    := (oFcgi:GetInputValue("CheckAspectOf"+l_nCounterC) == "1")
                    l_cEndpoint_Description := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription"+l_nCounterC)))

                    if empty(l_iEndpoint_pk)
                        if l_iEndpoint_fk_Entity > 0
                            l_nEndpoint_NumberOfEndpoints += 1
                            with object l_oDB2
                                :Table("a9759c27-199b-41b4-82db-b4c8cafc525b","Endpoint")
                                :Field("Endpoint.fk_Association" , l_iAssociationPk)
                                :Field("Endpoint.fk_Entity"      , l_iEndpoint_fk_Entity)
                                :Field("Endpoint.Name"           , iif(empty(l_cEndpoint_Name)       ,NULL,l_cEndpoint_Name))
                                :Field("Endpoint.BoundLower"     , iif(empty(l_cEndpoint_BoundLower) ,NULL,l_cEndpoint_BoundLower))
                                :Field("Endpoint.BoundUpper"     , iif(empty(l_cEndpoint_BoundUpper) ,NULL,l_cEndpoint_BoundUpper))
                                :Field("Endpoint.AspectOf"       , l_lEndpoint_AspectOf)
                                :Field("Endpoint.Description"    , iif(empty(l_cEndpoint_Description),NULL,l_cEndpoint_Description))
                                :Add()
                            endwith
                        endif

                    else
                        if l_iEndpoint_fk_Entity > 0
                            l_nEndpoint_NumberOfEndpoints += 1
                            // Check in ListOfEndpoints if should record update.

                            if !( VFP_Seek(l_iEndpoint_pk,"ListOfEndpoints","pk") ;
                                   .and. ListOfEndpoints->Endpoint_Fk_Entity           == l_iEndpoint_fk_Entity ;
                                   .and. nvl(ListOfEndpoints->Endpoint_Name,"")        == nvl(l_cEndpoint_Name,"") ;
                                   .and. nvl(ListOfEndpoints->Endpoint_BoundLower,"")  == nvl(l_cEndpoint_BoundLower,"") ;
                                   .and. nvl(ListOfEndpoints->Endpoint_BoundUpper,"")  == nvl(l_cEndpoint_BoundUpper,"") ;
                                   .and. ListOfEndpoints->Endpoint_AspectOf            == l_lEndpoint_AspectOf ;
                                   .and. nvl(ListOfEndpoints->Endpoint_Description,"") == nvl(l_cEndpoint_Description,"") )

                                with object l_oDB2
                                    :Table("6b749ef9-b9e4-4d29-ba51-e6c7ccd5754e","Endpoint")
                                    :Field("Endpoint.fk_Entity"   , l_iEndpoint_fk_Entity)
                                    :Field("Endpoint.Name"        , iif(empty(l_cEndpoint_Name)       ,NULL,l_cEndpoint_Name))
                                    :Field("Endpoint.BoundLower"  , iif(empty(l_cEndpoint_BoundLower) ,NULL,l_cEndpoint_BoundLower))
                                    :Field("Endpoint.BoundUpper"  , iif(empty(l_cEndpoint_BoundUpper) ,NULL,l_cEndpoint_BoundUpper))
                                    :Field("Endpoint.AspectOf"    , l_lEndpoint_AspectOf)
                                    :Field("Endpoint.Description" , iif(empty(l_cEndpoint_Description),NULL,l_cEndpoint_Description))
                                    :Update(l_iEndpoint_pk)
// SendToClipboard(l_oDB1:LastSQL())
// altd()
//12345

                                endwith
                            endif

                        else
                            l_oDB2:Delete("9f70d7d5-7464-4fb9-87d3-94af7b0b65ba","Endpoint",l_iEndpoint_pk)
                        endif

                    endif

                endfor

            endwith

            if l_nEndpoint_NumberOfEndpoints <> l_nEndpoint_NumberOfEndpoints_OnFile
                :Table("fd740dea-02ab-41aa-8e1e-dadcb193e2ba","Association")
                :Field("Association.NumberOfEndpoints",l_nEndpoint_NumberOfEndpoints)
                :Update(l_iAssociationPk)
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    l_cFrom := oFcgi:GetQueryString('From')

case l_cActionOnSubmit == "Delete"   // Association
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveModelDelete(par_iModelPk)
            l_cErrorMessage := CascadeDeleteAssociation(par_iProjectPk,l_iAssociationPk)
            if empty(l_cErrorMessage)
                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")
                l_cFrom := "Redirect"
            endif
        else
            with object l_oDB1
                //Check there are no endpoints
                :Table("1a77e0a2-db7a-4c8b-94bf-6eedb22d12eb","Endpoint")
                :Where("Endpoint.fk_Association = ^",l_iAssociationPk)
                :SQL()
                if :Tally == 0
                    CustomFieldsDelete(par_iProjectPk,USEDON_ASSOCIATION,l_iAssociationPk)
                    if :Delete("357adb48-e4ab-4f96-9b37-d738806cefc9","Association",l_iAssociationPk)
                        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")
                        l_cFrom := "Redirect"
                    else
                        l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFAssociation+[.]
                    endif
                else
                    l_cErrorMessage := [Related ]+oFcgi:p_ANFEntity+[ links on file.]
                endif
            endwith
        endif
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case l_cFrom == "Redirect"
case !empty(l_cErrorMessage)
    l_hValues["fk_package"]  := l_iAssociationFk_Package
    l_hValues["Name"]        := l_cAssociationName
    l_hValues["Description"] := l_cAssociationDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_ASSOCIATION,@l_hValues)

    l_hValues["NumberOfPossibleEndpoints"] := Val(oFcgi:GetInputValue("NumberOfPossibleEndpoints"))
    for l_nCounter := 1 to l_hValues["NumberOfPossibleEndpoints"]
        l_nCounterC := Trans(l_nCounter)

        l_hValues["EndpointPk"+l_nCounterC]          := Val(oFcgi:GetInputValue("TextEndpoint_pk"+l_nCounterC))
        l_hValues["EndpointFk_Entity"+l_nCounterC]   := Val(oFcgi:GetInputValue("ComboEndpoint_Fk_Entity"+l_nCounterC))
        l_hValues["EndpointName"+l_nCounterC]        := SanitizeInput(oFcgi:GetInputValue("TextName"+l_nCounterC))
        l_hValues["EndpointBoundLower"+l_nCounterC]  := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"+l_nCounterC))
        l_hValues["EndpointBoundUpper"+l_nCounterC]  := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"+l_nCounterC))
        l_hValues["EndpointAspectOf"+l_nCounterC]    := (oFcgi:GetInputValue("CheckAspectOf"+l_nCounterC) == "1")
        l_hValues["EndpointDescription"+l_nCounterC] := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription"+l_nCounterC)))

    endfor

    l_cHtml += AssociationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID,l_cErrorMessage,l_iAssociationPk,l_hValues)

case empty(l_cFrom) .or. empty(l_iAssociationPk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")

otherwise
    with object l_oDB1
        :Table("21e12705-83fa-4196-9bdf-0ed82dfb84c5","Association")
        :Column("Association.Name","Association_Name")
        l_oData := :Get(l_iAssociationPk)
        if :Tally <> 1
            l_cFrom := ""
        endif
    endwith

    switch l_cFrom
    otherwise
        //Should not happen. Failed :Get.
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")
    endswitch
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function AttributeListFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityInfo,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_Project          := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfAttributes := 0
local l_nNumberOfAttributesInSearch := 0
local l_nNumberOfCustomFieldValues := 0
local l_iAttributePk
local l_oData_Project

local l_hOptionValueToDescriptionMapping := {=>}

local l_cSearchAttributeName
local l_cSearchAttributeDescription

oFcgi:TraceAdd("AttributeListFormBuild")

if oFcgi:isGet()
    l_cSearchAttributeName        := hb_HexToStr(oFcgi:GetQueryString("AttributeName"))
    l_cSearchAttributeDescription := hb_HexToStr(oFcgi:GetQueryString("AttributeDescription"))
else
    l_cSearchAttributeName        := GetUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeName")
    l_cSearchAttributeDescription := GetUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeDescription")
endif

with object l_oDB_ListOfAttributes
    :Table("ddee7810-3754-4b72-9678-2d346045b1c4","Attribute")
    :Where("Attribute.fk_Entity = ^",par_iEntityPk)
    l_nNumberOfAttributes := :Count()

    :Table("a7d5f81b-ec4f-4a55-8b82-2b346c3450f5","Attribute")
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
    :Where("Attribute.fk_Entity = ^",par_iEntityPk)

    if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
        :Distinct(.t.)
        if !empty(l_cSearchAttributeName)
            :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
        endif
        if !empty(l_cSearchAttributeDescription)
            :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
        endif
    endif
    :OrderBy("Attribute_Order")
    :SQL("ListOfAttributes")
    l_nNumberOfAttributesInSearch := :Tally

endwith

if l_nNumberOfAttributes > 0
    with object l_oDB_CustomField
        :Table("f7b39a86-3777-4b5f-92f9-70e67406cee7","Attribute")
        :Distinct(.t.)
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.OptionDefinition","CustomField_OptionDefinition")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Attribute.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("Attribute.fk_Entity = ^",par_iEntityPk)
        if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
            :Distinct(.t.)
            if !empty(l_cSearchAttributeName)
                :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
            endif
            if !empty(l_cSearchAttributeDescription)
                :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
            endif
        endif
        :Where("CustomField.UsedOn = ^",USEDON_ATTRIBUTE)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("6d5a52b6-788e-4580-861a-a725b0e9fff9","Attribute")
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
        :Where("Attribute.fk_Entity = ^",par_iEntityPk)
        if !empty(l_cSearchAttributeName) .or. !empty(l_cSearchAttributeDescription)
            :Distinct(.t.)
            if !empty(l_cSearchAttributeName)
                :KeywordCondition(l_cSearchAttributeName,"Attribute.Name")
            endif
            if !empty(l_cSearchAttributeDescription)
                :KeywordCondition(l_cSearchAttributeDescription,"Attribute.Description")
            endif
        endif
        :Where("CustomField.UsedOn = ^",USEDON_ATTRIBUTE)
        :Where("CustomField.Status <= 2")
        // :OrderBy("Attribute_pk")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith
endif

if l_nNumberOfAttributes <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">No ]+oFcgi:p_ANFAttribute+[ on file for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityInfo+[".</span>]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms_0" href="]+l_cSitePath+[Modeling/NewAttribute/]+par_cEntityLinkUID+[/">New ]+oFcgi:p_ANFAttribute+[</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">Back To ]+oFcgi:p_ANFEntities+[</a>]
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/?From=Attributes">Edit ]+oFcgi:p_ANFEntity+[</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/NewAttribute/]+par_cEntityLinkUID+[/">New ]+oFcgi:p_ANFAttribute+[</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">Back To ]+oFcgi:p_ANFEntities+[</a>]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/OrderAttributes/]+par_cEntityLinkUID+[/">Order ]+oFcgi:p_ANFAttributes+[</a>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/?From=Attributes">Edit ]+oFcgi:p_ANFEntity+[</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    //Search Bar
    l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
    l_cHtml += [<input type="hidden" name="formname" value="List">]
    l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<table>]
                l_cHtml += [<tr>]
                    // ----------------------------------------
                    l_cHtml += [<td valign="top">]
                        l_cHtml += [<table>]
                            l_cHtml += [<tr>]
                                l_cHtml += [<td></td>]
                                l_cHtml += [<td class="justify-content-center" align="center">Name</td>]
                                l_cHtml += [<td class="justify-content-center" align="center">Description</td>]
                            l_cHtml += [</tr>]
                            l_cHtml += [<tr>]
                                l_cHtml += [<td><span class="me-2 ms-3">]+oFcgi:p_ANFAttribute+[</span></td>]
                                l_cHtml += [<td><input type="text" name="TextAttributeName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAttributeName)+["></td>]
                                l_cHtml += [<td><input type="text" name="TextAttributeDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchAttributeDescription)+["></td>]
                            l_cHtml += [</tr>]
                        l_cHtml += [</table>]
                    l_cHtml += [</td>]
                    // ----------------------------------------
                    l_cHtml += [<td>]  // valign="top"
                        l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-5 me-3" value="Search" onclick="$('#ActionOnSubmit').val('Search');document.form.submit();" role="button">]
                        l_cHtml += [<input type="button" class="btn btn-primary rounded me-5" value="Reset" onclick="$('#ActionOnSubmit').val('Reset');document.form.submit();" role="button">]
                    l_cHtml += [</td>]
                    // ----------------------------------------
                l_cHtml += [</tr>]
            l_cHtml += [</table>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]
    l_cHtml += [</form>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered table-striped">]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-center text-white" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"5","6")+[">]
                    if l_nNumberOfAttributes == l_nNumberOfAttributesInSearch
                        l_cHtml += oFcgi:p_ANFAttributes+[ (]+Trans(l_nNumberOfAttributes)+[) for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityInfo+["]
                    else
                        l_cHtml += oFcgi:p_ANFAttributes+[ (]+Trans(l_nNumberOfAttributesInSearch)+[ out of ]+Trans(l_nNumberOfAttributes)+[) for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityInfo+["]
                    endif
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

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
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditAttribute/]+ListOfAttributes->Attribute_LinkUID+[/">]+ListOfAttributes->Attribute_Name+[</a>]
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

return l_cHtml
//=================================================================================================================
static function AttributeListFormOnSubmit(par_iEntityPk,par_cEntityLinkUID,par_cEntityName,par_cModelLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_cEntityName
local l_cEntityDescription
local l_cAttributeName
local l_cAttributeDescription
local l_cURL

oFcgi:TraceAdd("AttributeListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cAttributeName        := SanitizeInput(oFcgi:GetInputValue("TextAttributeName"))
l_cAttributeDescription := SanitizeInput(oFcgi:GetInputValue("TextAttributeDescription"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeName"       ,l_cAttributeName)
    SaveUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeDescription",l_cAttributeDescription)

    l_cHtml += AttributeListFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityName,par_cModelLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeName"       ,"")
    SaveUserSetting("Entity_"+Trans(par_iEntityPk)+"_AttributeSearch_AttributeDescription","")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += AttributeListFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityName,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function AttributeEditFormBuild(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText    := hb_DefaultValue(par_cErrorText,"")
local l_cName         := hb_HGetDef(par_hValues,"Name","")
local l_ifk_DataType  := hb_HGetDef(par_hValues,"fk_DataType",0)
local l_cBoundLower   := nvl(hb_HGetDef(par_hValues,"BoundLower",""),"")
local l_cBoundUpper   := nvl(hb_HGetDef(par_hValues,"BoundUpper",""),"")
local l_cDescription  := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_iTypeCount

local l_oDB_ListOfDataType := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1               := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfAllDataTypes
local l_json_DataTypes
local l_cInfo
local l_hDataTypes := {=>}

oFcgi:TraceAdd("AttributeEditFormBuild")

with object l_oDB_ListOfDataType
    :Table("b773e79e-d29f-4545-8e1f-fd92a2b6f195","DataType")
    :Column("DataType.pk"         , "pk")
    :Column("DataType.FullName"   , "DataType_FullName")
    :Column("DataType.TreeOrder1" , "tag1")
    :OrderBy("tag1")
    :Where("DataType.fk_Model = ^" , par_iModelPk)
    :Where("DataType.TreeLevel = 1")
    :SQL("ListOfDataTypes")
    l_nNumberOfAllDataTypes := :Tally
endwith

SetSelect2Support()

l_json_DataTypes := []
select ListOfDataTypes
scan all
    if !empty(l_json_DataTypes)
        l_json_DataTypes += [,]
    endif
    l_cInfo := vfp_StrReplace(ListOfDataTypes->DataType_FullName,{;
                                    [\] => [\\] ,;
                                    ["] => [ ] ,;
                                    ['] => [ ] ;
                                    },,1)
    l_json_DataTypes += "{id:"+trans(ListOfDataTypes->pk)+",text:'"+l_cInfo+"'}"
    l_hDataTypes[ListOfDataTypes->pk] := l_cInfo   // Will be used to assist in setting up default <select> <option>
endscan
l_json_DataTypes := "["+l_json_DataTypes+"]"

//Call the jQuery code even before the for loop, since it will be used after html is loaded anyway.
oFcgi:p_cjQueryScript += [$(".SelectDataType").select2({placeholder: '',allowClear: true,data: ]+l_json_DataTypes+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="AttributeKey" value="]+trans(par_iPk)+[">]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]

        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFAttribute+[ in ]+oFcgi:p_ANFEntity+[ "]+par_cEntityName+["</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATESAVEBUTTON+[ type="text" name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Data Type</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<select name="ComboFk_DataType" id="ComboFk_DataType" class="SelectDataType" style="width:700px">]
                if l_ifk_DataType == 0
                    oFcgi:p_cjQueryScript += [$("#ComboFk_DataType").select2('val','0');]  // trick to not have a blank option bar.
                else
                    l_cHtml += [<option value="]+Trans(l_ifk_DataType)+[" selected="selected">]+hb_HGetDef(l_hDataTypes,l_ifk_DataType,"")+[</option>]
                endif
                l_cHtml += [</select>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        //Bound Lower
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Bound Lower</td>]
            l_cHtml += [<td class="pb-3"><input type="text" value="]+FcgiPrepFieldForValue(l_cBoundLower)+[" id="TextBoundLower" name="TextBoundLower" maxlength="4" size="2"></td>]
        l_cHtml += [</tr>]

        //Bound Upper
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Bound Upper</td>]
            l_cHtml += [<td class="pb-3"><input type="text" value="]+FcgiPrepFieldForValue(l_cBoundUpper)+[" id="TextBoundUpper" name="TextBoundUpper" maxlength="4" size="2"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATESAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ATTRIBUTE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function AttributeEditFormOnSubmit(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iAttributePk
local l_cAttributeName
local l_iAttributeFk_DataType
local l_cAttributeBoundLower
local l_cAttributeBoundUpper
local l_cAttributeDescription
local l_cAttributeLinkUID

local l_iAttributeOrder

local l_hValues := {=>}

local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1

oFcgi:TraceAdd("AttributeEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iAttributePk          := Val(oFcgi:GetInputValue("AttributeKey"))

l_cAttributeName        := SanitizeInput(oFcgi:GetInputValue("TextName"))

l_iAttributeFk_DataType := Val(oFcgi:GetInputValue("ComboFk_DataType"))

l_cAttributeBoundLower  := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"))
l_cAttributeBoundUpper  := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"))

l_cAttributeDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelML >= 5
        do case
        case empty(l_cAttributeName)
            l_cErrorMessage := "Missing Name"

        case empty(l_iAttributeFk_DataType)
            l_cErrorMessage := "Missing Data Type"

        otherwise
            with object l_oDB1
                :Table("da91571c-c2c1-42aa-b947-553006648be0","Attribute")
                :Column("Attribute.pk","pk")
                :Where([Attribute.fk_Entity = ^],par_iEntityPk)
                :Where([lower(replace(Attribute.Name,' ','')) = ^],lower(StrTran(l_cAttributeName," ","")))
                if l_iAttributePk > 0
                    :Where([Attribute.pk != ^],l_iAttributePk)
                endif
                :SQL()
            endwith
            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endcase
    endif

    if empty(l_cErrorMessage)
        //If adding a Attribute, find out what the last order is
        l_iAttributeOrder := 1
        if empty(l_iAttributePk)
            with object l_oDB1
                :Table("42e1af2e-547c-4012-9407-23854801859e","Attribute")
                :Column("Attribute.Order","Attribute_Order")
                :Where([Attribute.fk_Entity = ^],par_iEntityPk)
                :OrderBy("Attribute_Order","Desc")
                :Limit(1)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally > 0
                l_iAttributeOrder := l_aSQLResult[1,1] + 1
            endif
        endif

        //Save the Attribute
        with object l_oDB1
            :Table("f1109e34-247d-49e8-9a7a-7ffd32e1a914","Attribute")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("Attribute.Name"        , l_cAttributeName)
                :Field("Attribute.fk_DataType" , l_iAttributeFk_DataType)
                :Field("Attribute.BoundLower"  , iif(empty(l_cAttributeBoundLower),NULL,l_cAttributeBoundLower))
                :Field("Attribute.BoundUpper"  , iif(empty(l_cAttributeBoundUpper),NULL,l_cAttributeBoundUpper))
            endif
            :Field("Attribute.Description" , iif(empty(l_cAttributeDescription),NULL,l_cAttributeDescription))
        
            if empty(l_iAttributePk)
                :Field("Attribute.fk_Entity" , par_iEntityPk)
                :Field("Attribute.Order"     , l_iAttributeOrder)
                l_cAttributeLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Field("Attribute.LinkUID"   , l_cAttributeLinkUID)
                if :Add()
                    l_iAttributePk := :Key()
                else
                    l_cErrorMessage := [Failed to add ]+oFcgi:p_ANFAttribute+[.]
                endif
            else
                if !:Update(l_iAttributePk)
                    l_cErrorMessage := [Failed to update ]+oFcgi:p_ANFAttribute+[.]
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelML >= 5
                CustomFieldsSave(par_iProjectPk,USEDON_ATTRIBUTE,l_iAttributePk)
            endif
        endwith

        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/")
    endif

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/")

case l_cActionOnSubmit == "Delete"   // Attribute
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        CustomFieldsDelete(par_iProjectPk,USEDON_ATTRIBUTE,l_iAttributePk)
        l_oDB1:Delete("f47695cf-ff12-4c3f-8e12-3b4a17bc306b","Attribute",l_iAttributePk)

        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/")

    endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["fk_DataType"] := l_iAttributeFk_DataType
    l_hValues["Name"]        := l_cAttributeName
    l_hValues["BoundLower"]  := l_cAttributeBoundLower
    l_hValues["BoundUpper"]  := l_cAttributeBoundUpper
    l_hValues["Description"] := l_cAttributeDescription

    CustomFieldsFormToHash(par_iProjectPk,USEDON_ATTRIBUTE,@l_hValues)

    l_cHtml += AttributeEditFormBuild(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID,l_cErrorMessage,l_iAttributePk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function AttributeOrderFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityName)
local l_cHtml := []
local l_oDB_ListOfAttributes
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

oFcgi:TraceAdd("AttributeOrderFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EntityKey" value="]+trans(par_iEntityPk)+[">]
l_cHtml += [<input type="hidden" name="AttributeOrder" id="AttributeOrder" value="">]

l_oDB_ListOfAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB_ListOfAttributes
    :Table("f5feb43e-cc16-4ecb-81f1-5d78d78c3081","Attribute")
    :Column("Attribute.pk"         ,"pk")
    :Column("Attribute.Name"       ,"Attribute_Name")
    :Column("Attribute.Order"      ,"Attribute_Order")
    :Where("Attribute.fk_Entity = ^",par_iEntityPk)
    :OrderBy("Attribute_order")
    :SQL("ListOfAttributes")
endwith

l_cHtml += [<style>]
l_cHtml += [#sortable { list-style-type: none; margin: 0; padding: 0; }]
// The width: 60%;  will fail due to Bootstrap
l_cHtml += [#sortable li { margin: 3px 5px 3px 5px; padding: 2px 5px 5px 5px; font-size: 1.2em; height: 1.5em; line-height: 1.2em;}]   //display:block;   width:200px;
l_cHtml += [.ui-state-highlight { height: 1.5em; line-height: 1.2em; } ]
l_cHtml += [</style>]


l_cHtml += [<script language="javascript">]
l_cHtml += [function SendOrderList() {]
l_cHtml += [var EnumOrderData = $('#sortable').sortable('serialize', { key: 'sort' });]
l_cHtml += [$('#AttributeOrder').val(EnumOrderData);]
l_cHtml += [$('#ActionOnSubmit').val('Save');]
l_cHtml += [document.form.submit();]
l_cHtml += [}; ]
l_cHtml += [</script>]

oFcgi:p_cjQueryScript += [$( "#sortable" ).sortable({]
oFcgi:p_cjQueryScript +=   [axis: "y",]
oFcgi:p_cjQueryScript +=   [placeholder: "ui-state-highlight"]
oFcgi:p_cjQueryScript += [});]
oFcgi:p_cjQueryScript += [$( "#sortable" ).disableSelection();]
//The following line sets the width of all the "li" to the max width of the same "li"s. This fixes a bug in .sortable with dragging the widest "li"
oFcgi:p_cjQueryScript += [$('#sortable li').width( Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()) );]

l_cHtml += [<div class="m-3">]

    select ListOfAttributes

    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">Order ]+oFcgi:p_ANFAttributes+[ for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityName+["</span>]
            if oFcgi:p_nAccessLevelML >= 3
                l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="SendOrderList();" role="button">]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/ListAttributes/]+par_cEntityLinkUID+[/">Cancel</a>]
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center">]
        l_cHtml += [<div class="col-auto">]

        l_cHtml += [<ul id="sortable">]
        scan all
            l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfAttributes->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+strtran(ListOfAttributes->Attribute_Name," ","&nbsp;")+[</span></li>]
        endscan
        l_cHtml += [</ul>]

        l_cHtml += [</div>]
    l_cHtml += [</div>]

l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function AttributeOrderFormOnSubmit(par_cEntityLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEntityPk
local l_cAttributePkOrder

local l_oDB_ListOfAttributes
local l_aOrderedPks
local l_Counter

oFcgi:TraceAdd("AttributeOrderFormOnSubmit")

l_cActionOnSubmit    := oFcgi:GetInputValue("ActionOnSubmit")
l_iEntityPk          := Val(oFcgi:GetInputValue("EntityKey"))
l_cAttributePkOrder  := SanitizeInput(Strtran(oFcgi:GetInputValue("AttributeOrder")," ",""))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cAttributePkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB_ListOfAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfAttributes
            :Table("b6be9d37-f4c8-4e69-8963-1ce395d06039","Attribute")
            :Column("Attribute.pk","pk")
            :Column("Attribute.Order","order")
            :Where([Attribute.fk_Entity = ^],l_iEntityPk)
            :SQL("ListOfAttribute")
    
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
    
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if VFP_Seek(val(l_aOrderedPks[l_Counter]),"ListOfAttribute","pk") .and. ListOfAttribute->order <> l_Counter
                with object l_oDB_ListOfAttributes
                    :Table("41e21aee-a559-4a2a-ab9b-968e41424be9","Attribute")
                    :Field("Attribute.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListAttributes/"+par_cEntityLinkUID+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CascadeDeleteAssociation(par_iProjectPk,par_iAssociationPk)
local l_cErrorMessage := ""
local l_oDB_ListOfEndpointRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfEndpointRecordsToDelete
    //Delete any Endpoint related records
    :Table("93415488-4d7c-408f-8f12-9f0813914d47","Endpoint")
    :Column("Endpoint.pk" , "pk")
    :Where("Endpoint.fk_Association = ^",par_iAssociationPk)
    :SQL("ListOfEndpointRecordsToDelete")
    if :Tally < 0
        l_cErrorMessage := [Failed to query for related ]+oFcgi:p_ANFEntity+[ link records.]
    else
        select ListOfEndpointRecordsToDelete
        scan
            l_oDB1:Delete("35929f02-bfa8-41b1-bbad-8dbcb50c1de2","Endpoint",ListOfEndpointRecordsToDelete->pk)
        endscan

        //Delete the related custom fields
        CustomFieldsDelete(par_iProjectPk,USEDON_ASSOCIATION,par_iAssociationPk)
        if !:Delete("58fb1132-83a2-4ddb-b97d-092ca6fc03d9","Association",par_iAssociationPk)
            l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFAssociation+[ record.]
        endif

    endif
endwith

return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteEntity(par_iProjectPk,par_iEntityPk)
local l_cErrorMessage := ""
local l_oDB_ListOfEndpointRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB_ListOfEndpointRecordsToDelete
    //Delete any Endpoint related records
    :Table("47c2860e-13aa-415c-81d3-c3dd30c3ca68","Endpoint")
    :Column("Endpoint.pk" , "pk")
    :Where("Endpoint.fk_Entity = ^",par_iEntityPk)
    :SQL("ListOfEndpointRecordsToDelete")
    if :Tally < 0
        l_cErrorMessage := [Failed to query for related ]+oFcgi:p_ANFEntity+[ link records.]
    else
        select ListOfEndpointRecordsToDelete
        scan
            l_oDB1:Delete("83256a1d-a0a0-4682-bdcd-a7b14c40034d","Endpoint",ListOfEndpointRecordsToDelete->pk)
        endscan

        //Delete any Attribute related records
        :Table("f61ded14-540d-4e2d-b268-ad6f582822b6","Attribute")
        :Column("Attribute.pk" , "pk")
        :Where("Attribute.fk_Entity = ^",par_iEntityPk)
        :SQL("ListOfAttributeRecordsToDelete")
        if :Tally < 0
            l_cErrorMessage := [Failed to query for related ]+oFcgi:p_ANFEntity+[ link records.]
        else
            select ListOfAttributeRecordsToDelete
            scan
                l_oDB1:Delete("c10bfea1-5496-4990-8b71-7e4f8479aa1b","Attribute",ListOfAttributeRecordsToDelete->pk)
            endscan

            //Delete the related custom fields
            CustomFieldsDelete(par_iProjectPk,USEDON_ENTITY,par_iEntityPk)
            if !:Delete("3bb80f26-43b0-418d-ab3b-33d23b02cdad","Entity",par_iEntityPk)
                l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFEntity+[ record.]
            endif
        endif
    endif
endwith

return l_cErrorMessage
//=================================================================================================================
function CascadeDeleteModel(par_iProjectPk,par_iModelPk)
local l_cErrorMessage := ""
local l_oDB_ListOfRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_RecordToDelete        := hb_SQLData(oFcgi:p_o_SQLConnection)

// Step 1 - Delete All ModelingDiagram
// Step 2 - Delete all Associations
// Step 3 - Delete all Entities
// Step 4 - Delete all DataTypes
// Step 5 - Delete all Packages
// Step 6 - Delete Model

// Step 1 - Delete All ModelingDiagram, DiagramEntity records first, then the ModelingDiagram records
with object l_oDB_ListOfRecordsToDelete
    //Since the Diagram tables have no custom fields, we don't need the par_iProjectPk
    :Table("34bc4f62-e088-4900-8997-804c5f1e8e07","ModelingDiagram")
    :Column("DiagramEntity.pk" , "pk")
    :Where("ModelingDiagram.fk_Model = ^" , par_iModelPk)
    :Join("inner","DiagramEntity","","DiagramEntity.fk_ModelingDiagram = ModelingDiagram.pk")
    :SQL("CascadeDeleteModelListOfRecordsToDelete")
    select CascadeDeleteModelListOfRecordsToDelete
    scan all while empty(l_cErrorMessage)
        if !l_oDB_RecordToDelete:Delete("0fabbf02-25e5-4821-b46c-0a7c47cf8956","DiagramEntity",CascadeDeleteModelListOfRecordsToDelete->pk)
            l_cErrorMessage := [Failed to delete Diagram ]+oFcgi:p_ANFEntity+[.]
        endif
    endscan

    if empty(l_cErrorMessage)
        :Table("2ff2a1bf-b3e3-4646-b9c2-c6fbd2d6069b","ModelingDiagram")
        :Column("ModelingDiagram.pk" , "pk")
        :Where("ModelingDiagram.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            if !l_oDB_RecordToDelete:Delete("867c943e-714a-48ea-bdde-f1add818d2ef","ModelingDiagram",CascadeDeleteModelListOfRecordsToDelete->pk)
                l_cErrorMessage := [Failed to delete Modeling Diagram.]
            endif
        endscan
    endif
endwith

// Step 2 - Delete all Associations
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("79b7c8fc-acd1-4f72-8da0-afa6e8923a7c","Association")
        :Column("Association.pk" , "pk")
        :Where("Association.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            l_cErrorMessage := CascadeDeleteAssociation(par_iProjectPk,CascadeDeleteModelListOfRecordsToDelete->pk)
        endscan
    endwith
endif

// Step 3 - Delete all Entities
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("5d060c4e-3f42-4526-96ba-c3dd842c901b","Entity")
        :Column("Entity.pk" , "pk")
        :Where("Entity.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            l_cErrorMessage := CascadeDeleteEntity(par_iProjectPk,CascadeDeleteModelListOfRecordsToDelete->pk)
        endscan
    endwith
endif

// Step 4 - Delete all DataTypes
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("c581dea4-1028-4f1b-ab9a-177353d3585d","DataType")
        :Column("DataType.pk" , "pk")
        :Where("DataType.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            if !l_oDB_RecordToDelete:Delete("d43f98c0-073e-4c42-873e-8eddac52a452","DataType",CascadeDeleteModelListOfRecordsToDelete->pk)
                l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFDataTypes+[.]
            endif
        endscan
    endwith
endif

// Step 5 - Delete all Packages
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("63cb4b94-1759-4a00-9a3d-38ee4869e2ac","Package")
        :Column("Package.pk" , "pk")
        :Where("Package.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            if !l_oDB_RecordToDelete:Delete("c67cc62c-50fe-426d-86e8-f7cbe56a4f8e","Package",CascadeDeleteModelListOfRecordsToDelete->pk)
                l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFPackages+[.]
            endif
        endscan
    endwith
endif

// Step 6 - Delete Model
if empty(l_cErrorMessage)
    CustomFieldsDelete(par_iProjectPk,USEDON_MODEL,par_iModelPk)
    if !l_oDB_RecordToDelete:Delete("5cfe314f-1303-4e14-865c-0330955850d5","Model",par_iModelPk)
        l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFModel+[.]
    endif
endif

return l_cErrorMessage
//=================================================================================================================
function GetAccessLevelMLForProject(par_iProjectPk)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_nAccessLevelML := 0

do case
case oFcgi:p_nUserAccessMode <= 1  // Project access levels
    with object l_oDB1
        :Table("b64f780e-dd6a-4409-878a-dd3de257a440","UserAccessProject")
        :Column("UserAccessProject.AccessLevelML" , "AccessLevelML")
        :Where("UserAccessProject.fk_User = ^"    ,oFcgi:p_iUserPk)
        :Where("UserAccessProject.fk_Project = ^" ,par_iProjectPk)
        :SQL(@l_aSQLResult)
        if l_oDB1:Tally == 1
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

return l_nAccessLevelML
//=================================================================================================================
