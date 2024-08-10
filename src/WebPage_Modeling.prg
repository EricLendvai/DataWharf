#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageModeling()
local l_cHtml := []

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDataHeader
local l_oData

local l_cFormName

local l_iProjectPk

local l_hValues := {=>}

local l_cModelingElement := "ENTITIES"  //Default to Entities

local l_cURLAction
local l_cURLSubAction
local l_cURLLinkUID := ""
local l_cURLEnumValueName := ""

local l_cSitePath := oFcgi:p_cSitePath
local l_cLinkUID
local l_lFoundHeaderInfo := .f.

local l_cParentPackage := oFcgi:GetQueryString("parentPackage")
local l_cFromEntity    := oFcgi:GetQueryString("fromEntity")
local l_nAccessLevelML := 1
// As per the info in Schema.prg
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
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/marked_]+MARKED_SCRIPT_VERSION+[/marked.min.js"></script>]

oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_cSitePath+[scripts/bstreeview_]+BSTREEVIEW_SCRIPT_VERSION+[/css/bstreeview.min.css">]

//Temp solution of using previous version  _M_
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/bstreeview_]+BSTREEVIEW_SCRIPT_VERSION+[/js/bstreeview.min.js"></script>]
//oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/bstreeview_]+BSTREEVIEW_SCRIPT_VERSION+[/js/bstreeview_1_4_0.js"></script>]

oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/DataWharf_]+DATAWHARF_SCRIPT_VERSION+[/datawharf.js"></script>]

// Variables
// l_cURLAction

// Modeling/                                    Same as SelectProject

// Modeling/ListModels/<Project.LinkUID>/
// Modeling/NewModel/<Project.LinkUID>/
// Modeling/ModelSettings/<Model.LinkUID>/
// Modeling/ModelExport/<Model.LinkUID>/
// Modeling/ModelExportForDataWharfImports/<Model.LinkUID>/
// Modeling/ModelImport/<Model.LinkUID>/

// Modeling/Visualize/<Model.LinkUID>/

// Modeling/ListEntities/Model.LinkUID>/
// Modeling/NewEntity/<Model.LinkUID>/
// Modeling/EditEntity/<Entity.LinkUID>/
// Modeling/EditEntity/<Entity.LinkUID>/ListAttributes
// Modeling/EditEntity/<Entity.LinkUID>/ListAssociations

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

// Modeling/NewLinkedEntity/<Entity(from).LinkUID>/


if len(oFcgi:p_URLPathElements) >= 2 .and. !empty(oFcgi:p_URLPathElements[2])
    l_cURLAction := oFcgi:p_URLPathElements[2]

    if len(oFcgi:p_URLPathElements) >= 3 .and. !empty(oFcgi:p_URLPathElements[3])
        l_cURLLinkUID := oFcgi:p_URLPathElements[3]
    endif

    if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
        l_cURLSubAction := oFcgi:p_URLPathElements[4]
    endif
 
    do case
    case el_IsInlist(l_cURLAction,"ListModels","NewModel")
        with object l_oDB1
            :Table("68dd8f54-924f-47df-9c9a-6bb1a42b1af3","Project")
            :Column("Project.LinkUID", "Project_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Project.LinkUID = ^" , l_cURLLinkUID)
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"ModelSettings","ModelExport","ModelExportForDataWharfImports","ModelImport","ListEntities","ListAssociations","ListPackages","ListDataTypes","ListEnumerations","NewEntity","NewAssociation","NewPackage","NewDataType","NewEnumeration","Visualize")
        with object l_oDB1
            :Table("eaa6b925-b225-4fe2-8eeb-a0afcefc3848","Model")
            :Column("Model.pk"       , "Model_pk")
            :Column("Model.LinkUID"  , "Model_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.Name"     , "Model_Name")
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Column("Project.LinkUID", "Project_LinkUID")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Model.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"ListAttributes","OrderAttributes","NewAttribute","NewLinkedEntity")
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
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            :Where("Entity.LinkUID = ^" , l_cURLLinkUID)
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditEntity")
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
            :Column("Package.LinkUID", "Package_LinkUID")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Entity.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            :Join("left","Package","","Entity.fk_Package = Package.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditAssociation")
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
            :Column("Package.LinkUID"    , "Package_LinkUID")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Association.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model"    ,"","Association.fk_Model = Model.pk")
            :Join("inner","Project"  ,"","Model.fk_Project = Project.pk")
            :Join("left" ,"Package"  ,"","Association.fk_Package = Package.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditPackage")
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
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Package.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model"  ,"","Package.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditDataType")
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
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("DataType.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","DataType.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith
    
    case el_IsInlist(l_cURLAction,"EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        with object l_oDB1
            :Table("B2F2BD9B-1BCC-4E36-AFD5-277EF9E82FC1","ModelEnumeration")
            :Column("ModelEnumeration.pk"     , "Enumeration_pk")
            :Column("ModelEnumeration.Name"     , "Enumeration_Name")
            :Column("ModelEnumeration.LinkUID", "Enumeration_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"        , "Model_pk")
            :Column("Model.LinkUID"   , "Model_LinkUID")
            :Column("Model.Name"      , "Model_Name")
            :Column("Project.pk"      , "Project_pk")
            :Column("Project.Name"    , "Project_Name")
            :Column("Project.LinkUID" , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("ModelEnumeration.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","ModelEnumeration.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith
        if el_IsInlist(l_cURLAction,"EditEnumValue")
            if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
                l_cURLEnumValueName := oFcgi:p_URLPathElements[4]
            endif
        endif

    case el_IsInlist(l_cURLAction,"EditAttribute")
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
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("Attribute.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Entity","","Attribute.fk_Entity = Entity.pk")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditLinkedEntity")
        with object l_oDB1
            :Table("972C942A-5C3D-4CAD-B972-A86CE41F7986","LinkedEntity")
            :Column("LinkedEntity.pk"      , "LinkedEntity_pk")
            :Column("LinkedEntity.LinkUID" , "LinkedEntity_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Entity.pk"         , "Entity_pk")
            :Column("Entity.LinkUID"    , "Entity_LinkUID")
            :Column("Entity.Name"       , "Entity_Name")
            :Column("Model.pk"          , "Model_pk")
            :Column("Model.LinkUID"     , "Model_LinkUID")
            :Column("Model.Name"        , "Model_Name")
            :Column("Project.pk"        , "Project_pk")
            :Column("Project.Name"      , "Project_Name")
            :Column("Project.LinkUID"   , "Project_LinkUID")
            :Column("Project.AlternateNameForModel"         , "ANFModel")
            :Column("Project.AlternateNameForModels"        , "ANFModels")
            :Column("Project.AlternateNameForEntity"        , "ANFEntity")
            :Column("Project.AlternateNameForEntities"      , "ANFEntities")
            :Column("Project.AlternateNameForAssociation"   , "ANFAssociation")
            :Column("Project.AlternateNameForAssociations"  , "ANFAssociations")
            :Column("Project.AlternateNameForAttribute"     , "ANFAttribute")
            :Column("Project.AlternateNameForAttributes"    , "ANFAttributes")
            :Column("Project.AlternateNameForDataType"      , "ANFDataType")
            :Column("Project.AlternateNameForDataTypes"     , "ANFDataTypes")
            :Column("Project.AlternateNameForPackage"       , "ANFPackage")
            :Column("Project.AlternateNameForPackages"      , "ANFPackages")
            :Column("Project.AlternateNameForLinkedEntity"  , "ANFLinkedEntity")
            :Column("Project.AlternateNameForLinkedEntities", "ANFLinkedEntities")
            :Where("LinkedEntity.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Entity","","LinkedEntity.fk_Entity1 = Entity.pk")
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Project","","Model.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    endcase

    do case
    case l_cURLAction == "ListModels"
        l_cModelingElement := ""  // Not needed

    case el_IsInlist(l_cURLAction,"ListEntities","NewEntity","EditEntity","ListAttributes","NewAttribute","EditAttribute","OrderAttributes","NewLinkedEntity","EditLinkedEntity")
        l_cModelingElement := "ENTITIES"

    case el_IsInlist(l_cURLAction,"ListAssociations","NewAssociation","EditAssociation")
        l_cModelingElement := "ASSOCIATIONS"

    case el_IsInlist(l_cURLAction,"ListPackages","NewPackage","EditPackage")
        l_cModelingElement := "PACKAGES"

    case el_IsInlist(l_cURLAction,"ListDataTypes","NewDataType","EditDataType")
        l_cModelingElement := "DATATYPES"

    case el_IsInlist(l_cURLAction,"ModelSettings")
        l_cModelingElement := "SETTINGS"

    case el_IsInlist(l_cURLAction,"ModelExport","ModelExportForDataWharfImports")
        l_cModelingElement := "EXPORT"

    case el_IsInlist(l_cURLAction,"ModelImport")
        l_cModelingElement := "IMPORT"

    case el_IsInlist(l_cURLAction,"Visualize")
        if len(oFcgi:p_URLPathElements) >= 4 .and. !empty(oFcgi:p_URLPathElements[4])
            if el_IsInlist(oFcgi:p_URLPathElements[4],"resources","css","mxgraph")
                return [<div>Bad URL - calling for some css or resources - bug in mxgraph</div>]
            endif
        endif
        l_cModelingElement := "VISUALIZE"

    case el_IsInlist(l_cURLAction,"ListEnumerations","NewEnumeration","EditEnumeration","ListEnumValues","OrderEnumValues","NewEnumValue","EditEnumValue")
        l_cModelingElement := "ENUMERATIONS"

    otherwise
        l_cModelingElement := "ENTITIES"

    endcase

    if l_lFoundHeaderInfo
        //Update the oFCGI.p_ANF properties
        with object oFcgi
            :p_ANFModel              := nvl(l_oDataHeader:ANFModel           ,"Model")
            :p_ANFModels             := nvl(l_oDataHeader:ANFModels          ,"Models")
            :p_ANFEntity             := nvl(l_oDataHeader:ANFEntity          ,"Entity")
            :p_ANFEntities           := nvl(l_oDataHeader:ANFEntities        ,"Entities")
            :p_ANFAssociation        := nvl(l_oDataHeader:ANFAssociation     ,"Association")
            :p_ANFAssociations       := nvl(l_oDataHeader:ANFAssociations    ,"Associations")
            :p_ANFAttribute          := nvl(l_oDataHeader:ANFAttribute       ,"Attribute")
            :p_ANFAttributes         := nvl(l_oDataHeader:ANFAttributes      ,"Attributes")
            :p_ANFDataType           := nvl(l_oDataHeader:ANFDataType        ,"Data Type")
            :p_ANFDataTypes          := nvl(l_oDataHeader:ANFDataTypes       ,"Data Types")
            :p_ANFPackage            := nvl(l_oDataHeader:ANFPackage         ,"Package")
            :p_ANFPackages           := nvl(l_oDataHeader:ANFPackages        ,"Packages")
            :p_ANFLinkedEntity       := nvl(l_oDataHeader:ANFLinkedEntity    ,"Linked Entity")
            :p_ANFLinkedEntities     := nvl(l_oDataHeader:ANFLinkedEntities  ,"Linked Entities")
        endwith

        l_iProjectPk := l_oDataHeader:Project_pk

        l_nAccessLevelML := GetAccessLevelMLForProject(l_iProjectPk)
    endif

else
    l_cURLAction := "SelectProject" // "ListModels"
endif

if  oFcgi:p_nUserAccessMode >= 3
    oFcgi:p_nAccessLevelML := 7
else
    oFcgi:p_nAccessLevelML := l_nAccessLevelML
endif

do case
case !l_lFoundHeaderInfo .and. l_cURLAction <> "SelectProject"
    l_cHtml += [<div>Invalid UID</div>]

case l_cURLAction == "SelectProject"
    l_cHtml += ProjectListFormBuild()
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
            l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_LinkUID)
        endif
    endif
case l_cURLAction == "ListModels"
    l_cHtml += [<div class="d-flex bg-secondary bg-gradient sticky-top shadow">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Project: ]+l_oDataHeader:Project_Name+[</span></div>]
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Modeling/NewModel/]+l_oDataHeader:Project_LinkUID+[/">New ]+oFcgi:p_ANFModel+[</a></div>]
    endif
    l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Modeling/">Other Projects</a></div>]
    l_cHtml += [</div>]

    l_cHtml += ModelListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Project_Name)
otherwise
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Project_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name)
    l_cHtml += [<div class="container-fluid">]
    l_cHtml += [<div class="row">]
        l_cHtml += SideBarBuild(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID,l_oDataHeader:Project_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath,l_oDataHeader:Package_LinkUID,l_oDataHeader:DataType_LinkUID,l_oDataHeader:Association_LinkUID,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Enumeration_LinkUID)
        l_cHtml += [<main class="col-md ms-sm-auto col-lg px-md-4">]

        do case
        case l_cURLAction == "ModelSettings"
            if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
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
                    l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_LinkUID)  //l_oDataHeader:Model_LinkUID
                endif
            endif




        case l_cURLAction == "ModelImport"
            if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
                //par_iModelPk,par_cModelLinkUID,par_cProjectName,par_cModelName,par_lActiveHeader

                if oFcgi:isGet()
                    l_cHtml += ModelImportStep1FormBuild(l_oDataHeader:Model_pk,"")
                else
                    l_cHtml += ModelImportStep1FormOnSubmit(l_oDataHeader:Model_pk,l_oDataHeader:Project_LinkUID,l_oDataHeader:Model_LinkUID)
                endif
            endif

        case l_cURLAction == "ModelExport"
            if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
                if oFcgi:isGet()
                    l_cHtml += [<nav class="navbar navbar-light bg-light">]
                        l_cHtml += [<div class="input-group">]
                            l_cHtml += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[Modeling/ModelExportForDataWharfImports/]+l_oDataHeader:Model_LinkUID+[/]+[">Export For DataWharf Imports</a>]
                        l_cHtml += [</div>]
                    l_cHtml += [</nav>]
                else
                    
                endif
            endif

        case l_cURLAction == "ModelExportForDataWharfImports"
            if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
                if oFcgi:isGet()
                    l_cHtml += [<nav class="navbar navbar-light bg-light">]
                        l_cHtml += [<div class="input-group">]
                            l_cHtml += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[Modeling/ModelExport/]+l_oDataHeader:Model_LinkUID+[/]+[">Other Export</a>]

                            l_cLinkUID := ExportModelForImports(l_oDataHeader:Model_pk)

                            if !empty(l_cLinkUID)
                                l_cHtml += [<a class="btn btn-primary rounded ms-3 align-middle" href="]+l_cSitePath+[streamfile?id=]+l_cLinkUID+[">Download Export File</a>]
                            endif

                        l_cHtml += [</div>]
                    l_cHtml += [</nav>]
                else
                    
                endif
            endif

        case l_cURLAction == "ListEntities"
            if oFcgi:isGet()
                l_cHtml += EntityListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            else
                l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            endif

        case l_cURLAction == "NewEntity"
            if oFcgi:p_nAccessLevelML >= 5
                if oFcgi:isGet()
                    l_cHtml += EntityEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>},l_cParentPackage)
                else
                    l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,l_cParentPackage)
                endif
            endif

        case l_cURLAction == "EditEntity"
            if oFcgi:p_nAccessLevelML >= 2
                l_cHtml += GetEntityEditHeader(l_cSitePath, l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,l_cURLSubAction)
                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("e9c40921-bd84-4c03-bc86-c805f20b78ef","Entity")
                        :Column("Entity.fk_Package"   , "Entity_fk_Package")
                        :Column("Entity.Name"         , "Entity_Name")
                        :Column("Entity.UseStatus"    , "Entity_UseStatus")
                        :Column("Entity.Description"  , "Entity_Description")
                        :Column("Entity.Information"  , "Entity_Information")
                        :Column("Package.LinkUID"     , "Package_LinkUID")
                        :Join("left","Package","","Entity.fk_Package = Package.pk") 
                        l_oData := :Get(l_oDataHeader:Entity_pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["fk_Package"]     := l_oData:Entity_fk_Package
                        l_hValues["Name"]           := l_oData:Entity_Name
                        l_hValues["UseStatus"]      := l_oData:Entity_UseStatus
                        l_hValues["Description"]    := l_oData:Entity_Description
                        l_hValues["Information"]    := l_oData:Entity_Information
                        CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_ENTITY,l_oDataHeader:Entity_pk,@l_hValues)
                        do case
                            case empty(l_cURLSubAction)
                                l_cHtml += EntityEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,"",l_oDataHeader:Entity_pk,l_hValues)
                            case l_cURLSubAction == "ListAssociations"
                                l_cHtml += AssociationListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,l_oData:Package_LinkUID)
                            case l_cURLSubAction == "ListAttributes"
                                l_cHtml += AttributeListFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
                            case l_cURLSubAction == "ListLinkedEntities"
                                l_cHtml += LinkedEntityListFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID)
                        endcase
                    endif
                else
                    do case
                        case empty(l_cURLSubAction)
                            l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
                        case l_cURLSubAction == "ListAssociations"
                            l_cHtml += AssociationListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
                        case l_cURLSubAction == "ListAttributes"
                            l_cHtml += AttributeListFormOnSubmit(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
                    endcase
                endif

            endif

        case l_cURLAction == "ListAttributes"

            if oFcgi:isGet()
                l_cHtml += AttributeListFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
            else
                l_cHtml += AttributeListFormOnSubmit(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name,l_oDataHeader:Model_LinkUID)
            endif

        case l_cURLAction == "OrderAttributes"

            if oFcgi:isGet()
                l_cHtml += AttributeOrderFormBuild(l_oDataHeader:Entity_pk,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Entity_Name)
            else
                l_cHtml += AttributeOrderFormOnSubmit(l_oDataHeader:Entity_LinkUID)
            endif

        case l_cURLAction == "NewAttribute"
            if oFcgi:p_nAccessLevelML >= 5
                
                if oFcgi:isGet()
                    l_cHtml += AttributeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"",0,{=>})
                else
                    l_cHtml += AttributeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
                endif
            endif

        case l_cURLAction == "EditAttribute"
            if oFcgi:p_nAccessLevelML >= 2

                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("974f878e-4772-4a6f-9f62-04b5dd3f276c","Attribute")
                        :Column("Attribute.Name"                 , "Attribute_Name")
                        :Column("Attribute.UseStatus"            , "Attribute_UseStatus")
                        :Column("Attribute.Fk_Attribute"         , "Attribute_fk_Attribute")
                        :Column("Attribute.fk_DataType"          , "Attribute_fk_DataType")
                        :Column("Attribute.fk_ModelEnumeration"  , "Attribute_fk_Enumeration")
                        :Column("Attribute.IsObject"             , "Attribute_IsObject")
                        :Column("Attribute.BoundLower"           , "Attribute_BoundLower")
                        :Column("Attribute.BoundUpper"           , "Attribute_BoundUpper")
                        :Column("Attribute.Description"          , "Attribute_Description")
                        l_oData := :Get(l_oDataHeader:Attribute_pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["Name"]           := l_oData:Attribute_Name
                        l_hValues["UseStatus"]      := l_oData:Attribute_UseStatus
                        l_hValues["fk_Attribute"]   := l_oData:Attribute_fk_Attribute
                        l_hValues["fk_DataType"]    := l_oData:Attribute_fk_DataType
                        l_hValues["fk_Enumeration"] := l_oData:Attribute_fk_Enumeration
                        l_hValues["IsObject"]       := l_oData:Attribute_IsObject
                        l_hValues["BoundLower"]     := l_oData:Attribute_BoundLower
                        l_hValues["BoundUpper"]     := l_oData:Attribute_BoundUpper
                        l_hValues["Description"]    := l_oData:Attribute_Description
                        CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_ATTRIBUTE,l_oDataHeader:Attribute_pk,@l_hValues)

                        l_cHtml += AttributeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"",l_oDataHeader:Attribute_pk,l_hValues)
                    endif
                else
                    l_cHtml += AttributeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Entity_pk,l_oDataHeader:Entity_Name,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
                endif

            endif

        case l_cURLAction == "NewLinkedEntity"
            if oFcgi:p_nAccessLevelML >= 5
                
                if oFcgi:isGet()
                    l_cHtml += LinkedEntityEditFormBuild(l_oDataHeader:Model_Pk,l_oDataHeader:LinkedEntity_pk,l_oDataHeader:LinkedEntity_LinkUID,l_oDataHeader:Entity_LinkUID,"",{=>})
                else
                    l_cHtml += LinkedEntityEditFormOnSubmit(l_oDataHeader:Model_Pk,l_oDataHeader:LinkedEntity_pk,l_oDataHeader:LinkedEntity_LinkUID,l_oDataHeader:Entity_LinkUID)
                endif
            endif

        case l_cURLAction == "EditLinkedEntity"
            if oFcgi:p_nAccessLevelML >= 2
                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("B9993FED-AE78-4AE7-A274-DA4BD34696E2","LinkedEntity")
                        :Column("LinkedEntity.Description" , "LinkedEntity_Description")
                        :Column("LinkedEntity.fk_Entity1"  , "LinkedEntity_fk_Entity1")
                        :Column("LinkedEntity.fk_Entity2"  , "LinkedEntity_fk_Entity2")
                        l_oData := :Get(l_oDataHeader:LinkedEntity_Pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["LinkedEntityFromPk"] := l_oData:LinkedEntity_fk_Entity1
                        l_hValues["LinkedEntityToPk"]   := l_oData:LinkedEntity_fk_Entity2
                        l_hValues["Description"]        := l_oData:LinkedEntity_Description

                        l_cHtml += LinkedEntityEditFormBuild(l_oDataHeader:Model_Pk,l_oDataHeader:LinkedEntity_pk,l_oDataHeader:LinkedEntity_LinkUID,l_oDataHeader:Entity_LinkUID,"",l_hValues)
                    endif
                else
                    l_cHtml += LinkedEntityEditFormOnSubmit(l_oDataHeader:Model_Pk,l_oDataHeader:LinkedEntity_pk,l_oDataHeader:LinkedEntity_LinkUID,l_oDataHeader:Entity_LinkUID)
                endif

            endif
    

        case l_cURLAction == "ListAssociations"
            if oFcgi:isGet()
                l_cHtml += AssociationListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            else
                l_cHtml += AssociationListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            endif

        case l_cURLAction == "NewAssociation"
            if oFcgi:p_nAccessLevelML >= 5
                
                if oFcgi:isGet()
                    l_cHtml += AssociationEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>},l_cParentPackage,l_cFromEntity)
                else
                    l_cHtml += AssociationEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Association_LinkUID,l_cParentPackage,l_cFromEntity)
                endif
            endif

        case l_cURLAction == "EditAssociation"
            if oFcgi:p_nAccessLevelML >= 2

                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("e399d44f-9bd6-451f-8806-d5128fcd09ab","Association")
                        :Column("Association.fk_Package"   , "Association_fk_Package")
                        :Column("Association.Name"         , "Association_Name")
                        :Column("Association.UseStatus"    , "Association_UseStatus")
                        :Column("Association.Description"  , "Association_Description")
                        l_oData := :Get(l_oDataHeader:Association_pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["fk_Package"]     := l_oData:Association_fk_Package
                        l_hValues["Name"]           := l_oData:Association_Name
                        l_hValues["UseStatus"]      := l_oData:Association_UseStatus
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
                            :Column("Endpoint.IsContainment"         , "Endpoint_IsContainment")
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
                                l_hValues["EndpointPk"+l_nCounterC]            := ListOfEndpoints->Endpoint_pk
                                l_hValues["EndpointFk_Entity"+l_nCounterC]     := ListOfEndpoints->Endpoint_fk_Entity
                                l_hValues["EndpointName"+l_nCounterC]          := ListOfEndpoints->Endpoint_Name
                                l_hValues["EndpointBoundLower"+l_nCounterC]    := ListOfEndpoints->Endpoint_BoundLower
                                l_hValues["EndpointBoundUpper"+l_nCounterC]    := ListOfEndpoints->Endpoint_BoundUpper
                                l_hValues["EndpointIsContainment"+l_nCounterC] := ListOfEndpoints->Endpoint_IsContainment
                                l_hValues["EndpointDescription"+l_nCounterC]   := ListOfEndpoints->Endpoint_Description
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

            if oFcgi:isGet()
                l_cHtml += PackageListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            else
                // Nothing for now. All buttons are GET
            endif

        case l_cURLAction == "NewPackage"
            if oFcgi:p_nAccessLevelML >= 5
                
                if oFcgi:isGet()
                    l_cHtml += PackageEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
                else
                    l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
                endif
            endif

        case l_cURLAction == "EditPackage"
            if oFcgi:p_nAccessLevelML >= 2
                l_cHtml += GetPackageEditHeader(l_cSitePath, l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID,l_cURLSubAction)
                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("6689ff9b-9b8a-400c-abf8-d7146b805461","Package")
                        :Column("Package.fk_Package" , "Package_fk_Package")
                        :Column("Package.Name"       , "Package_Name")
                        :Column("Package.UseStatus"  , "Package_UseStatus")
                        l_oData := :Get(l_oDataHeader:Package_pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["fk_Package"] := l_oData:Package_fk_Package
                        l_hValues["Name"]       := l_oData:Package_Name
                        l_hValues["UseStatus"]  := l_oData:Package_UseStatus
                        CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_PACKAGE,l_oDataHeader:Package_pk,@l_hValues)
                        do case
                            case empty(l_cURLSubAction)
                                l_cHtml += PackageEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID,"",l_oDataHeader:Package_pk,l_hValues)
                            case l_cURLSubAction == "ListAssociations"
                                l_cHtml += AssociationListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,l_oDataHeader:Package_LinkUID)
                            case l_cURLSubAction == "ListEntities"
                                l_cHtml += EntityListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
                        endcase

                        
                    endif
                else
                    do case
                        case empty(l_cURLSubAction)
                            l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
                        case l_cURLSubAction == "ListAssociations"
                            l_cHtml += AssociationListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,,l_oDataHeader:Package_LinkUID)
                        case l_cURLSubAction == "ListEntities"
                            l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
                    endcase
                endif

            endif

        case l_cURLAction == "ListDataTypes"

            if oFcgi:isGet()
                l_cHtml += GetDataTypesEditHeader(l_cSitePath, l_oDataHeader:Model_LinkUID, l_cURLAction)
                l_cHtml += DataTypeListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
            else
                // Nothing for now. All buttons are GET
            endif

        case l_cURLAction == "NewDataType"
            if oFcgi:p_nAccessLevelML >= 5
                
                if oFcgi:isGet()
                    l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
                else
                    l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
                endif
            endif

        case l_cURLAction == "EditDataType"
            if oFcgi:p_nAccessLevelML >= 2

                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("5429f4d0-7679-419f-a7b2-c0899fb2d1da","DataType")
                        :Column("DataType.fk_DataType"      , "DataType_fk_DataType")
                        :Column("DataType.fk_PrimitiveType" , "DataType_fk_PrimitiveType")
                        :Column("DataType.Name"             , "DataType_Name")
                        :Column("DataType.UseStatus"        , "DataType_UseStatus")
                        :Column("DataType.Description"      , "DataType_Description")
                        l_oData := :Get(l_oDataHeader:DataType_pk)
                    endwith

                    if l_oDB1:Tally == 1
                        l_hValues["fk_DataType"]      := l_oData:DataType_fk_DataType
                        l_hValues["fk_PrimitiveType"] := l_oData:DataType_fk_PrimitiveType
                        l_hValues["Name"]             := l_oData:DataType_Name
                        l_hValues["UseStatus"]        := l_oData:DataType_UseStatus
                        l_hValues["Description"]      := l_oData:DataType_Description
                        CustomFieldsLoad(l_oDataHeader:Project_pk,USEDON_DATATYPE,l_oDataHeader:DataType_pk,@l_hValues)

                        l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID,"",l_oDataHeader:DataType_pk,l_hValues)
                    endif
                else
                    l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
                endif

            endif
        case l_cURLAction == "ListEnumerations"
            //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
            l_cHtml += GetDataTypesEditHeader(l_cSitePath, l_oDataHeader:Model_LinkUID, l_cURLAction)
            l_cHtml += EnumerationListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
        
        case l_cURLAction == "NewEnumeration"
            if oFcgi:p_nAccessLevelML >= 5
                //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
                
                if oFcgi:isGet()
                    l_cHtml += EnumerationEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
                else
                    l_cHtml += EnumerationEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID)
                endif
            endif
        
        case l_cURLAction == "EditEnumeration"
            //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
            if oFcgi:p_nAccessLevelML >= 2
                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("A1438538-6C53-48B1-8725-EEA249E32D62" ,"ModelEnumeration")
                        :Column("ModelEnumeration.pk"                 , "Enumeration_Pk")
                        :Column("ModelEnumeration.fk_Model"           , "Enumeration_fk_Model")
                        :Column("ModelEnumeration.Name"               , "Enumeration_Name")
                        :Column("ModelEnumeration.UseStatus"          , "Enumeration_UseStatus")
                        :Column("ModelEnumeration.Description"        , "Enumeration_Description")
                        :Column("ModelEnumeration.LinkUID"            , "Enumeration_LinkUID")
                        l_oData := :Get(l_oDataHeader:Enumeration_pk)
                    endwith
                
                    if l_oDB1:Tally == 1           
                        l_hValues["Name"]        := l_oData:Enumeration_Name
                        l_hValues["UseStatus"]   := l_oData:Enumeration_UseStatus
                        l_hValues["Description"] := l_oData:Enumeration_Description
                        l_cHtml += GetEnumerationEditHeader(l_cSitePath, l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,l_cURLSubAction)
                        do case
                            case empty(l_cURLSubAction)
                                l_cHtml += EnumerationEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,"",l_oDataHeader:Enumeration_pk,l_hValues)
                            case l_cURLSubAction == "ListEnumValues"
                                l_cHtml += EnumValueListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_pk,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_Name)
                            case l_cURLSubAction == "OrderEnumValues"
                                l_cHtml += EnumValueOrderFormBuild(l_oDataHeader:Enumeration_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_Name,l_oDataHeader:Enumeration_LinkUID)
                        endcase
                        
                    endif
                else
                    do case
                        case empty(l_cURLSubAction)
                            l_cHtml += EnumerationEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID)
                        case l_cURLSubAction == "OrderEnumValues"
                            l_cHtml += EnumValueOrderFormOnSubmit(l_oDataHeader:Enumeration_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_Name,l_oDataHeader:Enumeration_LinkUID)
                    endcase
                endif
            endif
        
        case l_cURLAction == "ListEnumValues"
            //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)
            l_cHtml += EnumValueListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_pk,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_Name)

        
        case l_cURLAction == "OrderEnumValues"
            if oFcgi:p_nAccessLevelML >= 5
                //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.t.)

                if oFcgi:isGet()
                    l_cHtml += EnumValueOrderFormBuild(l_oDataHeader:Enumeration_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_Name,l_oDataHeader:Enumeration_LinkUID)
                else
                    l_cHtml += EnumValueOrderFormOnSubmit(l_oDataHeader:Enumeration_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_Name,l_oDataHeader:Enumeration_LinkUID)
                endif
            endif
        
        case l_cURLAction == "NewEnumValue"
            if oFcgi:p_nAccessLevelML >= 5
                //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
                if oFcgi:isGet()
                    l_cHtml += EnumValueEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_Name,"",0,{=>})
                else
                    l_cHtml += EnumValueEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_pk,l_oDataHeader:Enumeration_Name)
                endif
            endif
        
        case l_cURLAction == "EditEnumValue"
            //l_cHtml += DataDictionaryHeaderBuild(l_iApplicationPk,l_cApplicationName,l_cApplicationElement,l_cSitePath,l_cURLApplicationLinkCode,.f.)
            if oFcgi:p_nAccessLevelML >= 2
                if oFcgi:isGet()
                    with object l_oDB1
                        :Table("47966C2F-C211-4A52-85F7-221E4ED4A791","ModelEnumValue")
                
                        :Column("ModelEnumValue.pk"         ,"EnumValue_pk")
                        :Column("ModelEnumeration.pk"       ,"Enumeration_pk")

                        :Column("ModelEnumValue.Name"       ,"EnumValue_Name")           
                        :Column("ModelEnumValue.Number"     ,"EnumValue_Number")       
                        :Column("ModelEnumValue.Description","EnumValue_Description") 
                
                        :Join("inner","ModelEnumeration"    ,"","ModelEnumValue.fk_ModelEnumeration = ModelEnumeration.pk")
                        :Where("ModelEnumeration.LinkUID = ^"   ,l_oDataHeader:Enumeration_LinkUID)
                        :Where([lower(replace(ModelEnumValue.Name,' ','')) = ^],lower(StrTran(l_cURLEnumValueName," ","")))
                        l_oData := :SQL()
                    endwith
                    if l_oDB1:Tally == 1
                        l_hValues["Name"]            := l_oData:EnumValue_Name
                        l_hValues["Number"]          := l_oData:EnumValue_Number
                        l_hValues["Description"]     := l_oData:EnumValue_Description
            
                        l_cHtml += EnumValueEditFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_Name,"",l_oData:EnumValue_pk,l_hValues)
                    endif
                else
                    l_cHtml += EnumValueEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Enumeration_LinkUID,l_oDataHeader:Enumeration_pk,l_oDataHeader:Enumeration_Name)
                endif
            endif
        
        case l_cURLAction == "Visualize"
            
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
                        :Field("ModelingDiagram.LinkUID"               ,oFcgi:p_o_SQLConnection:GetUUIDString())
                        :Field("ModelingDiagram.fk_Model"              ,l_oDataHeader:Model_pk)
                        :Field("ModelingDiagram.Name"                  ,"All Entities")
                        :Field("ModelingDiagram.AssociationShowName"   ,.t.)
                        :Field("ModelingDiagram.AssociationEndShowName",.t.)
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

                case l_cFormName == "DuplicateDiagram"
                    l_cHtml += ModelingVisualizeDiagramDuplicateOnSubmit(l_oDataHeader,"")

                endcase
            endif

        otherwise
            l_cHtml += [<div>Bad URL</div>]
            
        endcase
        l_cHtml += [</main>]
        l_cHtml += [</div>]
        l_cHtml += [</div>]
        
    endcase
return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ModelingHeaderBuild(par_cProjectLinkUID,par_cProjectName,par_cModelName)

local l_cHtml := ""
// local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_aSQLResult := {}
// local l_iReccount
local l_cSitePath := oFcgi:p_cSitePath

l_cHtml += [<div class="d-flex bg-secondary bg-gradient sticky-top shadow">]
l_cHtml +=    [<button type="button" id="sidebarCollapse" class="btn btn-secondary"><i class="bi bi-list"></i></button>]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Project / ]+oFcgi:p_ANFModel+[: ]+par_cProjectName
                if !empty(par_cModelName)
                    l_cHtml += [ / ]+par_cModelName
                endif
l_cHtml +=      [</span></div>]
if !empty(par_cModelName)
    l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="btn btn-primary rounded" href="]+l_cSitePath+[Modeling/ListModels/]+par_cProjectLinkUID+[/">Other ]+oFcgi:p_ANFModels+[</a></div>]
endif
l_cHtml += [</div>]

return l_cHtml

//=================================================================================================================
//=================================================================================================================
static function SideBarBuild(par_iModelPk,par_cProjectLinkUID,par_cModelLinkUID,par_cProjectName,par_cModelName,par_cModelElement,par_lActiveHeader,par_cSitePath, par_cSelectedPackageLinkUID, par_cSelectedDataTypeLinkUID, par_cSelectedAssociationLinkUID, par_cSelectedEntityLinkUID, par_cSelectedEnumerationLinkUID)

local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_oDB2  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult2 := {}
local l_iReccount
local l_cSitePath := oFcgi:p_cSitePath
local l_lSideBarMenuOpen := (oFcgi:GetCookieValue("sidebarMenu") == "false")
local l_cInitialDiagram

l_cHtml += [<nav id="sidebarMenu" class="col-md-3 col-lg-2 d-md-block bg-light sidebar]+iif(l_lSideBarMenuOpen,[],[ active])+[">]
l_cHtml += [<div class="position-sticky pt-3">]
l_cHtml += [<ul class="nav flex-column">]
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cModelElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelSettings/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-gear"></i>]+oFcgi:p_ANFModel+[ Settings</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cModelElement == "IMPORT",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelImport/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-gear"></i>]+oFcgi:p_ANFModel+[ Import</a>]
        l_cHtml += [</li>]

        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cModelElement == "EXPORT",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelExport/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-gear"></i>]+oFcgi:p_ANFModel+[ Export</a>]
        l_cHtml += [</li>]


    // if oFcgi:p_nAccessLevelDD >= 6
    //     l_cHtml += [<li class="nav-item">]
    //         l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "IMPORT",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryImport/]+par_cURLApplicationLinkCode+[/">Import</a>]
    //     l_cHtml += [</li>]
    //     l_cHtml += [<li class="nav-item">]
    //         l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cApplicationElement == "EXPORT",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[DataDictionaries/DataDictionaryExport/]+par_cURLApplicationLinkCode+[/">Export</a>]
    //     l_cHtml += [</li>]
    // endif



    endif
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]

        with object l_oDB1
            :Table("b879207d-9a3d-4a54-9563-2db4de482a3c","UserSettingModel")
            :Column("UserSettingModel.pk"    ,"pk")
            :Column("ModelingDiagram.LinkUID","ModelingDiagram_LinkUID")
            :Join("inner","ModelingDiagram","","UserSettingModel.fk_ModelingDiagram = ModelingDiagram.pk")
            :Where("UserSettingModel.fk_User = ^" ,oFcgi:p_iUserPk)
            :Where("UserSettingModel.fk_Model = ^",par_iModelPk)
            :SQL("ListOfUserSettingModel")
            // hb_orm_SendToDebugView(:GetLastEventId(),:LastSQL())
            if :Tally == 1
                l_cInitialDiagram := "?InitialDiagram="+ListOfUserSettingModel->ModelingDiagram_LinkUID
            else
                l_cInitialDiagram := ""
            endif
        endwith
        
        l_cHtml += [<a class="nav-link ]+iif(par_cModelElement == "VISUALIZE",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/Visualize/]+par_cModelLinkUID+[/]+l_cInitialDiagram+["><i class="item-icon bi bi-diagram-3"></i>Visualize</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("43e2e6a8-0228-4c99-bf52-4e9841ac2e40","Entity")
            :Column("Count(*)","Total")
            :Where("Entity.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) 
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ENTITIES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-boxes"></i>All ]+oFcgi:p_ANFEntities+[ (]+Trans(l_iReccount)+[)</a>]
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
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ASSOCIATIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListAssociations/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-box-arrow-in-up-right"></i>All ]+oFcgi:p_ANFAssociations+[ (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        with object l_oDB1
            :Table("a0d49d4d-5a86-48d5-a1a7-c970cbf4d118","DataType")
            :Column("Count(*)","Total")
            :Where("DataType.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult)
        endwith

        with object l_oDB2
            :Table("E0490159-0568-44E2-98B7-D212A675CCDC","ModelEnumeration")
            :Column("Count(*)","Total")
            :Where("ModelEnumeration.fk_Model = ^" , par_iModelPk)
            :SQL(@l_aSQLResult2)
        endwith

        l_iReccount := iif(l_oDB1:Tally == 1,l_aSQLResult[1,1],0) + iif(l_oDB2:Tally == 1,l_aSQLResult2[1,1],0) 
        l_cHtml += [<div class="d-flex justify-content-between align-items-center">]
        l_cHtml +=   [<a class="nav-link]+iif(par_cModelElement == "DATATYPES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-code-slash"></i>]+oFcgi:p_ANFDataTypes+[ (]+Trans(l_iReccount)+[)</a>]
        l_cHtml +=   [<a data-bs-toggle="collapse" data-bs-target="#dataTypesTree" class="link-secondary" href="#"><i class="bi bi-list-nested"></i></a>]
        l_cHtml += [</div>]
        if l_iReccount > 0
            l_cHtml += DataTypeTreeBuild(par_iModelPk, par_cModelLinkUID, par_cSelectedDataTypeLinkUID, par_cSelectedEnumerationLinkUID)
        endif
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
        l_cHtml += [<div class="d-flex justify-content-between align-items-center">]
        l_cHtml +=    [<a class="nav-link]+iif(par_cModelElement == "PACKAGES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListPackages/]+par_cModelLinkUID+[/"><i class="item-icon bi bi-folder"></i>]+oFcgi:p_ANFPackages+[ (]+Trans(l_iReccount)+[)</a>]
        l_cHtml +=    [<a data-bs-toggle="collapse" data-bs-target="#packagesTree"  class="link-secondary" href="#"><i class="bi bi-list-nested"></i></a>]
        l_cHtml += [</div>]
        l_cHtml += PackageTreeBuild(par_iModelPk, par_cSelectedPackageLinkUID, par_cSelectedAssociationLinkUID, par_cSelectedEntityLinkUID)
    l_cHtml += [</li>]


l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

l_cHtml += [</nav>]

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ProjectListFormBuild()
local l_cHtml := []
local l_oDB_ListOfProjects    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfProjects
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nCount

oFcgi:TraceAdd("ProjectListFormBuild")

with object l_oDB_ListOfProjects
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

    with object l_oDB_ListOfModelCounts
        :Table("f5b17e37-226b-444a-ad25-f2f1e06ea585","Project")
        :Column("Project.pk" ,"Project_pk")
        :Column("Count(*)" ,"ModelCount")
        :Join("inner","Model","","Model.fk_Project = Project.pk")
        :GroupBy("Project_pk")
        if oFcgi:p_nUserAccessMode <= 1
            :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
            :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        endif
        :SQL("ListOfModelCounts")
        with object :p_oCursor
            :Index("tag1","Project_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_CustomFields
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

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"4","5")+[">Modeling / Projects (]+Trans(l_nNumberOfProjects)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFModels+[</th>]
                    l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfProjects
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfProjects->Project_UseStatus)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListModels/]+alltrim(ListOfProjects->Project_LinkUID)+[/">]+alltrim(ListOfProjects->Project_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfProjects->Project_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            l_nCount := iif( el_seek(ListOfProjects->pk,"ListOfModelCounts","tag1") , ListOfModelCounts->ModelCount , 0)
                            if !empty(l_nCount)
                                l_cHtml += Trans(l_nCount)
                            endif
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfProjects->Project_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfProjects->Project_UseStatus,USESTATUS_UNKNOWN)]
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
local l_oDB_CustomFields                                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsPackageCounts                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsEntityCounts                     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsAttributeCounts                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsAssociationCounts                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsDataTypeCounts                   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsEnumerationCounts                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsLinkedModelCounts1               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsLinkedModelCounts2               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsModelingDiagramCounts            := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfUserSettingModelDefaultModelingDiagram := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfModels
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

local l_iModelPk
local l_nPackageCount
local l_nEntityCount
local l_nAttributeCount
local l_nAssociationCount
local l_nDataTypeCount
local l_nEnumerationCount
local l_nLinkedModelCount
local l_nModelingDiagramCount
local l_cInitialDiagram

oFcgi:TraceAdd("ModelListFormBuild")

oFcgi:SetCookieValue("sidebarMenu","false",,"/")  // To re-open the sidebar menu in case was left closed.

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

    //For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a el_seek technic will not be needed.

    with object l_oDB_ListOfModelsEntityCounts
        :Table("ec7bdbd8-db8f-48ee-a277-75ddc70ee531","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"EntityCount")
        :Join("inner","Entity","","Entity.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsEntityCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsAttributeCounts
        :Table("5d01ab7f-ef35-4f49-bb30-39e6dfa067f4","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"AttributeCount")
        :Join("inner","Entity","","Entity.fk_Model = Model.pk")
        :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsAttributeCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsAssociationCounts
        :Table("49945b95-d779-4794-ad8d-b9509149474f","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"AssociationCount")
        :Join("inner","Association","","Association.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsAssociationCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsPackageCounts
        :Table("ffae46b3-74a4-43f4-9d11-dae80e0bcba5","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"PackageCount")
        :Join("inner","Package","","Package.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsPackageCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsDataTypeCounts
        :Table("6bdc7220-0980-4288-9dd0-621cc3baba60","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"DataTypeCount")
        :Join("inner","DataType","","DataType.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsDataTypeCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsEnumerationCounts
        :Table("a27a822e-2e7c-47fb-bca2-2f5ddab21725","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"EnumerationCount")
        :Join("inner","ModelEnumeration","","ModelEnumeration.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsEnumerationCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

    with object l_oDB_ListOfModelsLinkedModelCounts1
        :Table("c7f308dc-4cd3-44c5-a26a-f15938b035a5","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"LinkedModelCount")
        :Join("inner","LinkedModel","","LinkedModel.fk_Model1 = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsLinkedModelCounts1")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith
// ExportTableToHtmlFile("ListOfModelsLinkedModelCounts1",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfModelsLinkedModelCounts1.html","From PostgreSQL",,25,.t.)


//     with object l_oDB_ListOfModelsLinkedModelCounts2
//         :Table("cddfeb45-7d28-4e07-8016-7137ab611a81","Model")
//         :Column("Model.pk" ,"Model_pk")
//         :Column("Count(*)" ,"LinkedModelCount")
//         :Join("inner","LinkedModel","","LinkedModel.fk_Model2 = Model.pk")
//         :Where("Model.fk_Project = ^",par_Project_pk)
//         :GroupBy("Model_pk")
//         :SQL("ListOfModelsLinkedModelCounts2")
//         with object :p_oCursor
//             :Index("tag1","Model_pk")
//             :CreateIndexes()
//         endwith
//     endwith
// ExportTableToHtmlFile("ListOfModelsLinkedModelCounts2",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfModelsLinkedModelCounts2.html","From PostgreSQL",,25,.t.)


    with object l_oDB_ListOfModelsModelingDiagramCounts
        :Table("0f4987c4-c0f7-4e7f-abda-bb07d7fd6bdb","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"ModelingDiagramCount")
        :Join("inner","ModelingDiagram","","ModelingDiagram.fk_Model = Model.pk")
        :Where("Model.fk_Project = ^",par_Project_pk)
        :GroupBy("Model_pk")
        :SQL("ListOfModelsModelingDiagramCounts")
        with object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
        endwith
    endwith

endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfModels)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Model on file.</span>]
        l_cHtml += [</div>]

    else
        //Will check if we have a previously accessed ModelingDiagram.
        with object l_oDB_ListOfUserSettingModelDefaultModelingDiagram
            :Table("ed410689-7946-4597-aa12-f7727255fc74","UserSettingModel")
            :Column("UserSettingModel.fk_Model","ModelPk")
            :Column("ModelingDiagram.LinkUID"  ,"ModelingDiagram_LinkUID")
            :Join("inner","ModelingDiagram","","UserSettingModel.fk_ModelingDiagram = ModelingDiagram.pk")
            :Where("UserSettingModel.fk_User = ^",oFcgi:p_iUserPk)
            :SQL("ListOfUserSettingModelDefaultModelingDiagram")
            with object :p_oCursor
                :Index("ModelPk","ModelPk")
                :CreateIndexes()
            endwith
        endwith

        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered">] // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"12","13")+[">]+oFcgi:p_ANFModels+[ (]+Trans(l_nNumberOfModels)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Project</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFModel+[ Name</th>]
                    l_cHtml += [<th class="text-white">Stage</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFPackages+[</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFEntities+[</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFAttributes+[</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFAssociations+[</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFDataTypes+[</th>]
                    l_cHtml += [<th class="text-white">]+oFcgi:p_ANFModelEnumerations+[</th>]
                    l_cHtml += [<th class="text-white">Linked ]+oFcgi:p_ANFModel+[</th>]
                    // l_cHtml += [<th class="text-white text-center">Settings</th>]
                    l_cHtml += [<th class="text-white">Visualize</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfModels
                scan all
                    l_iModelPk := ListOfModels->pk

                    // l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorStage(recno(),ListOfModels->Model_Stage)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Project
                            l_cHtml += par_Project_Name
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Model Name
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+alltrim(ListOfModels->Model_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Stage
                            l_cHtml += {"Proposed","Draft","Beta","Stable","In Use","Discontinued"}[iif(el_between(ListOfModels->Model_Stage,1,6),ListOfModels->Model_Stage,1)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Description
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfModels->Model_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">] //Packages
                            l_nPackageCount := iif( el_seek(l_iModelPk,"ListOfModelsPackageCounts","tag1") , ListOfModelsPackageCounts->PackageCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListPackages/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nPackageCount)+[</a>]
                        l_cHtml += [</td>]
                        
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Entities
                            l_nEntityCount := iif( el_seek(l_iModelPk,"ListOfModelsEntityCounts","tag1") , ListOfModelsEntityCounts->EntityCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nEntityCount)+[</a>]
                        l_cHtml += [</td>]
                        
                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Attributes
                            l_nAttributeCount := iif( el_seek(l_iModelPk,"ListOfModelsAttributeCounts","tag1") , ListOfModelsAttributeCounts->AttributeCount , 0)
                            // l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nAttributeCount)+[</a>]
                            l_cHtml += Trans(l_nAttributeCount)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Associations
                            l_nAssociationCount := iif( el_seek(l_iModelPk,"ListOfModelsAssociationCounts","tag1") , ListOfModelsAssociationCounts->AssociationCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListAssociations/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nAssociationCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Data Types
                            l_nDataTypeCount := iif( el_seek(l_iModelPk,"ListOfModelsDataTypeCounts","tag1") , ListOfModelsDataTypeCounts->DataTypeCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListDataTypes/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nDataTypeCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Enumerations
                            l_nEnumerationCount := iif( el_seek(l_iModelPk,"ListOfModelsEnumerationCounts","tag1") , ListOfModelsEnumerationCounts->EnumerationCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEnumerations/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nEnumerationCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">] //Linked Models
                            l_nLinkedModelCount := iif( el_seek(l_iModelPk,"ListOfModelsLinkedModelCounts1","tag1") , ListOfModelsLinkedModelCounts1->LinkedModelCount , 0)
                            // l_nLinkedModelCount += iif( el_seek(l_iModelPk,"ListOfModelsLinkedModelCounts2","tag1") , ListOfModelsLinkedModelCounts2->LinkedModelCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ModelSettings/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nLinkedModelCount)+[</a>]
                        l_cHtml += [</td>]
                        
                        // l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Settings
                        //     l_cHtml += []
                        // l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]  //Visualize
                            l_nModelingDiagramCount := iif( el_seek(l_iModelPk,"ListOfModelsModelingDiagramCounts","tag1") , ListOfModelsModelingDiagramCounts->ModelingDiagramCount , 0)
                            // l_cHtml += [<a href="]+l_cSitePath+[Modeling/Visualize/]+alltrim(ListOfModels->Model_LinkUID)+[/">]+Trans(l_nModelingDiagramCount)+[</a>]

                            //Will check if we have a previously accessed ModelingDiagram.
                            if el_seek(l_iModelPk,"ListOfUserSettingModelDefaultModelingDiagram","ModelPk")
                                l_cInitialDiagram := "?InitialDiagram="+ListOfUserSettingModelDefaultModelingDiagram->ModelingDiagram_LinkUID
                            else
                                l_cInitialDiagram := ""
                            endif
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/Visualize/]+alltrim(ListOfModels->Model_LinkUID)+[/]+l_cInitialDiagram+[">]+Trans(l_nModelingDiagramCount)+[</a>]

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
local l_cSitePath      := oFcgi:p_cSitePath

local l_ScriptFolder

local l_iProjectPk     := nvl(hb_HGetDef(par_hValues,"Fk_Project",0),0)
local l_cName          := hb_HGetDef(par_hValues,"Name","")
local l_nStage         := hb_HGetDef(par_hValues,"Stage",1)
local l_cDescription   := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cLinkedModels  := ""

local l_oDB_ListOfProjects := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_LinkedModels   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModels   := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_nNumberOfModels
local l_json_Models := []
local l_cModelInfo

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

with object l_oDB_LinkedModels
    :Table("6608FC78-A544-4EA3-B6F5-C6583E2F968E","LinkedModel")
    :Column("LinkedModel.pk"    ,"pk")
    :Column("Model1.Name"       ,"Model1_Name")
    :Column("Model2.Name"       ,"Model2_Name")
    :Column("Model1.pk"         ,"Model1_pk")
    :Column("Model2.pk"         ,"Model2_pk")
    :Join("inner","Model"       ,"Model1"    ,"LinkedModel.fk_Model1 = Model1.pk")
    :Join("inner","Model"       ,"Model2"    ,"LinkedModel.fk_Model2 = Model2.pk")
    :Where("LinkedModel.fk_Model1 = ^", par_iPk) //only select outgoing linked models for now
    :SQL("LinkedModels")
    select LinkedModels
    scan all //this can also handle incoming but for now only outgoing will be in the list
        if !empty(l_cLinkedModels)
            l_cLinkedModels += [,]
        endif
        if LinkedModels->Model1_pk = par_iPk
            l_cLinkedModels += trans(LinkedModels->Model2_pk)
        //else
        //    l_cLinkedModels += trans(LinkedModels->Model1_pk)
        endif
    endscan
endwith

l_ScriptFolder := l_cSitePath+[scripts/jQueryAmsify_]+JQUERYAMSIFY_SCRIPT_VERSION+[/]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

with object l_oDB_ListOfModels
    :Table("5151E2E4-64BE-4C5D-85B1-99247F04A5C5","Model")
    :Column("Model.pk"         ,"pk")
    :Column("Model.Name"       ,"Model_Name")
    :Column("Model.Stage"      ,"Model_Stage")
    :Column("Model.Description","Model_Description")
    :Column("Model.LinkUID"    ,"Model_LinkUID")
    :Column("Upper(Model.Name)","tag1")
    :Column("Project.Name"     ,"Project_Name")
    :OrderBy("tag1")
    :Join("inner","Project","","Project.pk = Model.fk_Project")
    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    endif
    :Where("Model.pk <> ^",par_iPk)
    :SQL("ListOfModels")
    l_nNumberOfModels := :Tally
    // _M_  Access rights restrictions

    if l_nNumberOfModels > 0
        select ListOfModels
        scan all
            if !empty(l_json_Models)
                l_json_Models += [,]
            endif
            l_cModelInfo := ListOfModels->Model_Name + [ (]+ListOfModels->Project_Name+[)]
            l_json_Models += "{tag:'"+l_cModelInfo+"',value:"+trans(ListOfModels->pk)+"}"
        endscan
    endif
endwith

oFcgi:p_cjQueryScript += [$("#LinkedModels").amsifySuggestags({]+;
    "suggestions :["+l_json_Models+"],"+;
    "whiteList: true,"+;
    "tagLimit: 10,"+;
    "selectOnHover: true,"+;
    "showAllSuggestions: true,"+;
    "keepLastOnHoverTag: false,"+;
    "afterAdd: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }},"+;
    "afterRemove: function(value) { if ($('#PageLoaded').val() == '1') { "+GOINEDITMODE+" }}"+;
    [});]

oFcgi:p_cjQueryScript += "$('#PageLoaded').val('1');"

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 150px;} ]
l_cHtml += [ ul.amsify-list {min-height: 150px;} ]
l_cHtml += [</style>]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="PageLoaded" id="PageLoaded" value="0">]

l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="ModelKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iPk)
            l_cHtml += [<span class="navbar-brand ms-3">New ]+oFcgi:p_ANFModel+[</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update ]+oFcgi:p_ANFModel+[ Settings</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelML >= 7
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 7
                l_cHtml += GetButtonOnEditFormDelete()
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
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboProjectPk" id="ComboProjectPk" class="form-select">]
                else
                    l_cHtml += [<input type="hidden" name="ComboProjectPk" value="]+Trans(l_iProjectPk)+[">]
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ disabled class="form-select">]
                endif
                select ListOfProjects
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfProjects->pk)+["]+iif(ListOfProjects->pk = l_iProjectPk,[ selected],[])+[>]+alltrim(ListOfProjects->Project_Name)+[</option>]
                endscan
                l_cHtml += [</select>]
                if oFcgi:p_nAccessLevelML >= 5 .and. !empty(par_iPk)
                    l_cHtml += [<span>(Can be used to reassign ]+oFcgi:p_ANFModel+[ to a different Project)</span>]
                endif
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Stage</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboStage" id="ComboStage">]
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
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Linked ]+oFcgi:p_ANFModels+[</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="LinkedModels" id="LinkedModels" size="25" maxlength="10000" value="]+FcgiPrepFieldForValue(l_cLinkedModels)+[" class="form-control TextSearchTag" placeholder=""</td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_MODEL,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function ModelEditFormOnSubmit(par_iProjectPk,par_cProjectLinkUID)  // par_cModelLinkUID
local l_cHtml := []
local l_cActionOnSubmit

local l_iModelPk
local l_iModelPkForEntities := 0
local l_iProjectPk
local l_cModelName
local l_nModelStage
local l_cModelDescription

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB_LinkedModels 
local l_nNumberOfLinkedModelsOnFile
local l_hLinkedModelsOnFile := {=>}
local l_cListOfLinkedModelsPks
local l_aLinkedModelsSelected
local l_aLinkedModelsToAdd := {}
local l_cLinkedModelsSelected
local l_iLinkedModelsSelectedPk
local l_iLinkedModelsPk
local l_iLinkedModelsFk
local l_oData

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
                        :Field("Model.LinkUID" , oFcgi:p_o_SQLConnection:GetUUIDString())
                        if :Add()
                            l_iModelPk := :Key()
                        else
                            l_cErrorMessage := "Failed to add Model."
                        endif
                    else
                        if !:Update(l_iModelPk)
                            l_cErrorMessage := "Failed to update Project."
                        endif
                    endif
                    if empty(l_cErrorMessage)
                        CustomFieldsSave(par_iProjectPk,USEDON_MODEL,l_iModelPk)

                        //Save Linked models - Begin

                        //Get current list of models assign to table
                        l_oDB_LinkedModels := hb_SQLData(oFcgi:p_o_SQLConnection)
                        with object l_oDB_LinkedModels
                            :Table("A9FBDEE9-1C9B-4849-BC17-2C4464C0DE5A","LinkedModel")
                            :Column("LinkedModel.pk"             , "LinkedModel_pk")
                            :Column("LinkedModel.fk_Model1"      , "LinkedModel_fk_Model1")
                            :Column("LinkedModel.fk_Model2"      , "LinkedModel_fk_Model2")
                            :Where("LinkedModel.fk_Model1 = ^ OR LinkedModel.fk_Model2 = ^", l_iModelPk, l_iModelPk)
                            :SQL("ListOfLinkedModelsOnFile")

                            l_nNumberOfLinkedModelsOnFile := :Tally
                            if l_nNumberOfLinkedModelsOnFile > 0
                                hb_HAllocate(l_hLinkedModelsOnFile,l_nNumberOfLinkedModelsOnFile)
                                select ListOfLinkedModelsOnFile
                                scan all
                                    if ListOfLinkedModelsOnFile->LinkedModel_fk_Model1 = l_iModelPk
                                        l_hLinkedModelsOnFile[Trans(ListOfLinkedModelsOnFile->LinkedModel_fk_Model2)] := ListOfLinkedModelsOnFile->LinkedModel_pk
                                    //else       //for now linked models are unidirectional
                                    //    l_hLinkedModelsOnFile[Trans(ListOfLinkedModelsOnFile->LinkedModel_fk_Model1)] := ListOfLinkedModelsOnFile->LinkedModel_pk
                                    endif
                                endscan
                            endif

                        endwith
                        
                        l_cListOfLinkedModelsPks := SanitizeInput(oFcgi:GetInputValue("LinkedModels"))
                        if !empty(l_cListOfLinkedModelsPks)
                            l_aLinkedModelsSelected := hb_aTokens(l_cListOfLinkedModelsPks,",",.f.)
                            for each l_cLinkedModelsSelected in l_aLinkedModelsSelected
                                l_iLinkedModelsSelectedPk := val(l_cLinkedModelsSelected)

                                l_iLinkedModelsPk := hb_HGetDef(l_hLinkedModelsOnFile,Trans(l_iLinkedModelsSelectedPk),0)
                                if l_iLinkedModelsPk > 0
                                    //Already on file. Remove from l_hLinkedModelsOnFile
                                    hb_HDel(l_hLinkedModelsOnFile,Trans(l_iLinkedModelsSelectedPk))
                                    
                                else
                                    // Not on file yet
                                    AAdd(l_aLinkedModelsToAdd, l_iLinkedModelsSelectedPk)
                                endif

                            endfor
                        endif
                        
                        //go through list and check if there are still LinkedEntities. Error if there are still
                        for each l_iLinkedModelsFk in l_hLinkedModelsOnFile
                            with object l_oDB_LinkedModels
                                :Table("042CDA5B-ACE4-4867-BFC5-875059959ABC","LinkedEntity")
                                :Column("LinkedEntity.pk"    ,"pk")
                                :Join("inner","Entity"       ,"ToEntity"    ,"LinkedEntity.fk_Entity2 = ToEntity.pk")
                                :Join("inner","LinkedModel"  ,"LinkedModel" ,"LinkedModel.fk_Model2 = ToEntity.fk_Model")
                                :Where("LinkedModel.pk = ^", l_iLinkedModelsFk) //only select outgoing linked models for now
                                :SQL()
                                if  :Tally <> 0
                                    l_cErrorMessage := oFcgi:p_ANFLinkedEntities + " exist. Cannot remove linked " + oFcgi:p_ANFModel + "."
                                endif
                            endwith
                        endfor

                        if empty(l_cErrorMessage)
                            if !empty(l_aLinkedModelsToAdd)
                                for each l_iLinkedModelsSelectedPk in l_aLinkedModelsToAdd
                                    with object l_oDB1
                                        :Table("FE7D2622-9278-4B64-BFB8-113B9F14471E","LinkedModel")
                                        :Field("LinkedModel.fk_Model1"  ,l_iModelPk)
                                        :Field("LinkedModel.fk_Model2" ,l_iLinkedModelsSelectedPk)
                                        :Add()
                                    endwith
                                endfor
                            endif

                            //Go through what is left in l_hLinkedModelsOnFile and remove it, since was not keep as selected linked model
                            for each l_iLinkedModelsFk in l_hLinkedModelsOnFile
                                :Delete("CD306E98-E1C7-4954-A226-C045F29731BB","LinkedModel",l_iLinkedModelsFk)
                            endfor
                        endif
                        //Save Linked Models - End
                    endif
                endwith
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iModelPkForEntities := l_iModelPk
    l_iModelPk := 0
    //Go to list of entities in the current model

case l_cActionOnSubmit == "Delete"   // Model
    if oFcgi:p_nAccessLevelML >= 7
        if CheckIfAllowDestructiveModelDelete(par_iProjectPk)
            l_cErrorMessage := CascadeDeleteModel(par_iProjectPk,l_iModelPk)
            if empty(l_cErrorMessage)
                l_iModelPk := 0
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
                                // Will Allow to delete even if diagram exists, they will be removed.
                                l_cErrorMessage := CascadeDeleteModel(par_iProjectPk,l_iModelPk)

                                if empty(l_cErrorMessage)
                                    l_iModelPk := 0
                                endif

                                // :Table("3d533d32-9518-4de8-be2a-92a227a7a5f5","ModelingDiagram")
                                // :Where("ModelingDiagram.fk_Model = ^",l_iModelPk)
                                // :SQL()

                                // if :Tally == 0
                                //     CustomFieldsDelete(par_iProjectPk,USEDON_MODEL,l_iModelPk)
                                //     :Delete("8c45bacb-78dd-46e5-ab34-38b0ff7c30b8","Model",l_iModelPk)

                                //     oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
                                // else
                                //     l_cErrorMessage := [Related Diagrams record on file.]
                                // endif
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

do case
case !empty(l_cErrorMessage)
    l_hValues["Fk_Project"] := l_iProjectPk
    l_hValues["Name"]       := l_cModelName
    l_hValues["Stage"]      := l_nModelStage
    l_hValues["Description"]:= l_cModelDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_MODEL,@l_hValues)

    l_cHtml += ModelEditFormBuild(l_iProjectPk,l_cErrorMessage,l_iModelPk,l_hValues)

case !empty(l_iModelPkForEntities)
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("d8518b7a-3f06-4dcb-881b-5f8309a0c6f7","Model")
        :Column("Model.LinkUID" , "Model_LinkUID")
        l_oData := :Get(l_iModelPkForEntities)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListEntities/"+alltrim(l_oData:Model_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
        endif
    endwith

case !empty(l_iModelPk)
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("d8518b7a-3f06-4dcb-881b-5f8309a0c6f7","Model")
        :Column("Model.LinkUID" , "Model_LinkUID")
        l_oData := :Get(l_iModelPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ModelSettings/"+alltrim(l_oData:Model_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListModels/"+par_cProjectLinkUID+"/")
        endif
    endwith

otherwise
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListModels/"+par_cProjectLinkUID+"/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)
local l_cHtml := []
local l_oDB_ListOfEntities                := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntitiesAttributeCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_iEntityPk
local l_nAttributeCount

local l_cSearchEntityName
local l_cSearchEntityDescription

local l_cSearchAttributeName
local l_cSearchAttributeDescription

local l_nNumberOfEntities
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cAttributeSearchParameters
local l_nColspan
local l_cObjectId

oFcgi:TraceAdd("EntityListFormBuild")

//Left code below in case would like to make this a user optional feature 
    //See https://github.com/markedjs/marked for the JS library  _M_ Make this generic to be used in other places
    //Left code below in case would like to make this a user optional feature oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_cSitePath+[scripts/marked_]+MARKED_SCRIPT_VERSION+[/marked.min.js"></script>]

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
    :Column("Entity.UseStatus"  ,"Entity_UseStatus")
    :Column("Entity.Description","Entity_Description")
    :Column("Entity.Information","Entity_Information")
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
    if !empty(par_cPackageLinkUID)
        :Where("Package.LinkUID = ^",par_cPackageLinkUID)
    endif

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


//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a el_seek technic will not be needed.
with object l_oDB_ListOfEntitiesAttributeCounts
    :Table("bc2e9531-aab8-4c57-bd71-7bddca894b61","Entity")
    :Column("Entity.pk","Entity_pk")
    :Column("Count(*)" ,"AttributeCount")
    :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    :GroupBy("Entity_pk")
    :SQL("ListOfEntitiesAttributeCounts")

    with object :p_oCursor
        :Index("tag1","Entity_pk")
        :CreateIndexes()
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewEntity/]+par_cModelLinkUID+iif(!empty(par_cPackageLinkUID),[?parentPackage=]+par_cPackageLinkUID,"")+[">New ]+oFcgi:p_ANFEntity+[</a>]
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

if !empty(oFcgi:GetAppConfig("SyncToStoplight_Command"))
    l_cHtml += [<div>]  // class="m-3"
    l_cHtml += [<input type="submit" class="btn btn-primary rounded me-3 mt-3" value="Sync to Stoplight" onclick="$('#ActionOnSubmit').val('SyncToStoplight');document.form.submit();" role="button">]
    l_cHtml += [</div>]
endif

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [</form>]

if !empty(l_nNumberOfEntities)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-left">]
        l_cHtml += [<div class="col">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_nColspan := 6
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan += 1
            endif

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+Trans(l_nColspan)+[">]+oFcgi:p_ANFEntities+[ (]+Trans(l_nNumberOfEntities)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFPackage+[</th>]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFEntity+[ Name</th>]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFAttributes+[</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white">Information</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfEntities
            scan all
                l_iEntityPk := ListOfEntities->pk

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfEntities->Entity_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += alltrim(nvl(ListOfEntities->Package_FullName,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEntity/]+ListOfEntities->Entity_LinkUID+[/">]+ListOfEntities->Entity_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        l_nAttributeCount := iif( el_seek(l_iEntityPk,"ListOfEntitiesAttributeCounts","tag1") , ListOfEntitiesAttributeCounts->AttributeCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListAttributes/]+ListOfEntities->Entity_LinkUID+[/]+l_cAttributeSearchParameters+[">]+Trans(l_nAttributeCount)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEntities->Entity_Description,""))
                    l_cHtml += [</td>]

                    l_cObjectId := "entity-description"+Trans(l_iEntityPk)
                    l_cHtml += [<td class="GridDataControlCells" valign="top" id="]+l_cObjectId+[">]
                        //Left code below in case would like to make this a user optional feature 
                        // if !hb_orm_isnull("ListOfEntities","Entity_Information")
                        //     l_cHtml += [<script> document.getElementById(']+l_cObjectId+[').innerHTML = marked.parse(']+EscapeNewlineAndQuotes(ListOfEntities->Entity_Information)+[');</script>]
                        // endif
                        l_cHtml += iif(len(nvl(ListOfEntities->Entity_Information,"")) > 0,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfEntities->Entity_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfEntities->Entity_UseStatus,USESTATUS_UNKNOWN)]
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
static function EntityListFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_cEntityName
local l_cEntityDescription
local l_cAttributeName
local l_cAttributeDescription
local l_cURL
local l_cSyncToStoplight_Command

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

    l_cHtml += EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName"        ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription" ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeName"       ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_AttributeDescription","")

    if !empty(par_cPackageLinkUID)
        l_cURL := oFcgi:p_cSitePath+"Modeling/EditPackage/"+par_cPackageLinkUID+"/ListEntities/"
    else
        l_cURL := oFcgi:p_cSitePath+"Modeling/ListEntities/"+par_cModelLinkUID+"/"
    endif
        
    oFcgi:Redirect(l_cURL)

case l_cActionOnSubmit == "SyncToStoplight"
    l_cSyncToStoplight_Command := oFcgi:GetAppConfig("SyncToStoplight_Command")
    if !empty(l_cSyncToStoplight_Command)
        // hb_ProcessRun(l_cSyncToStoplight_Command,,,,.t.)
        // hb_ProcessRun(l_cSyncToStoplight_Command)
        hb_run(l_cSyncToStoplight_Command+" "+par_cModelLinkUID)
    endif
    
    l_cHtml += EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

otherwise
    l_cHtml += EntityListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
static function GetEntityEditHeader(par_cSitePath, par_cModelLinkUID, par_cEntityLinkUID, par_cEntityElement)
local l_cHtml := ""
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oEntity

with object l_oDB1
    :Table("A84ED358-9173-4C27-88A7-EBB4D2118BAF","Entity")
    :Column("Entity.pk"        ,"Entity_pk")
    :Column("Entity.Name"      ,"Entity_Name")
    :Column("Package.FullName" ,"Package_FullName")
    :Column("Package.LinkUID"  ,"Package_LinkUID")
    :Join("left","Package","","Entity.fk_Package = Package.pk")
    :Where("Entity.LinkUID = ^",par_cEntityLinkUID)
    l_oEntity := :SQL()
endwith

l_cHtml += [<nav aria-label="breadcrumb">]
    l_cHtml += [<ol class="breadcrumb">]
        l_cHtml += [<li class="breadcrumb-item"><a href="]+par_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">Home</a></li>]
        if !empty(l_oEntity:Package_LinkUID)
            l_cHtml += [<li class="breadcrumb-item"><a href="]+par_cSitePath+[Modeling/EditPackage/]+l_oEntity:Package_LinkUID+[/">]+l_oEntity:Package_FullName+[</a></li>]
        endif
        l_cHtml += [<li class="breadcrumb-item active" aria-current="page">]+l_oEntity:Entity_Name+[</li>]
    l_cHtml += [</ol>]
l_cHtml += [</nav>]

l_cHtml += [<ul class="nav nav-tabs">]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(empty(par_cEntityElement),[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/">Edit ]+oFcgi:p_ANFEntity+[</a>]
    l_cHtml += [</li>]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cEntityElement == "ListAttributes",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/ListAttributes">]+oFcgi:p_ANFAttributes+[</a>]
    l_cHtml += [</li>]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cEntityElement == "ListAssociations",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/ListAssociations">]+oFcgi:p_ANFAssociations+[</a>]
    l_cHtml += [</li>]

//LINKED_ENTITIES _M_
    l_cHtml += [<li class="nav-item">]
    l_cHtml += [<a class="nav-link ]+iif(par_cEntityElement == "ListLinkedEntities",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/ListLinkedEntities">]+oFcgi:p_ANFLinkedEntities+[</a>]
    l_cHtml += [</li>]

l_cHtml += [</ul>]
return l_cHtml
//=================================================================================================================
static function EntityEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cErrorText,par_iPk,par_hValues,par_cPackageLinkUID)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_ifk_Package  := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_cInformation := nvl(hb_HGetDef(par_hValues,"Information",""),"")

local l_cSitePath    := oFcgi:p_cSitePath

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
    :Column("Package.LinkUID"    , "Package_LinkUID")
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

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar nav-tabs bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFEntity+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3 card-group">]

    l_cHtml += [<div class="card">]

        l_cHtml += [<div class="m-3" class="card-body">]

            l_cHtml += [<table>]

                if l_nNumberOfPackages > 0
                    l_cHtml += [<tr class="pb-5">]
                        l_cHtml += [<td class="pe-2 pb-3">Parent ]+oFcgi:p_ANFPackage+[</td>]
                        l_cHtml += [<td class="pb-3">]
                            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                            l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                            select ListOfPackages
                            scan all
                                if !empty(par_cPackageLinkUID)
                                    l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->Package_LinkUID = par_cPackageLinkUID,[ selected],[])+[>]+alltrim(ListOfPackages->Package_FullName)+[</option>]
                                else
                                    l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->pk = l_ifk_Package,[ selected],[])+[>]+alltrim(ListOfPackages->Package_FullName)+[</option>]
                                endif                                
                            endscan
                            l_cHtml += [</select>]
                        l_cHtml += [</td>]
                    l_cHtml += [</tr>]
                endif

                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">]+oFcgi:p_ANFEntity+[ Name</td>]
                    l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="pb-5">]
                    l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
                    l_cHtml += [<td class="pb-3">]
                        l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                            l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                            l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                            l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                            l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                            l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                            l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                        l_cHtml += [</select>]
                    l_cHtml += [</td>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr>]
                    l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
                    l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr>]
                    l_cHtml += [<td valign="top" class="pe-2 pb-3">Information<br>]
                    l_cHtml += [<a href="https://www.markdownguide.org/basic-syntax/" target="_blank"><span class="small">Markdown</span></a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextInformation" id="TextInformation" rows="10" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cInformation)+[</textarea></td>]
                l_cHtml += [</tr>]

                l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ENTITY,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

            l_cHtml += [</table>]
        
        l_cHtml += [</div>]
    l_cHtml += [</div>]
    l_cHtml += [<div class="card">]
    
        l_cHtml += [<div class="m-3" class="card-body">]
            l_cHtml += [<span class="navbar-brand ms-3">Preview</span>]
                l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Preview MarkDown" onclick="document.getElementById('preview-right-content').innerHTML = marked.parse(document.getElementById('TextInformation').value);" role="button">]
                l_cHtml += [<div id="preview-right-content" class="card-text overflow-scroll"></div>]
                l_cHtml += [<script> document.getElementById('preview-right-content').innerHTML = marked.parse(document.getElementById('TextInformation').value);</script>] 
            l_cHtml += [</div>]
        l_cHtml += [</div>]
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextInformation').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function EntityEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cPackageLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iEntityPk
local l_iEntityFk_Package
local l_cEntityName
local l_nEntityUseStatus
local l_cEntityDescription
local l_cEntityInformation
local l_cErrorMessage := ""
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

local l_hValues := {=>}

oFcgi:TraceAdd("EntityEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEntityPk          := Val(oFcgi:GetInputValue("EntityKey"))

l_iEntityFk_Package  := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cEntityName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nEntityUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cEntityDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_cEntityInformation := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextInformation")))

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
                :Field("Entity.UseStatus" ,l_nEntityUseStatus)
            endif
            :Field("Entity.Description" ,iif(empty(l_cEntityDescription),NULL,l_cEntityDescription))
            :Field("Entity.Information" ,iif(empty(l_cEntityInformation),NULL,l_cEntityInformation))
            if empty(l_iEntityPk)
                :Field("Entity.LinkUID"  , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("Entity.fk_Model" , par_iModelPk)
                if :Add()
                    l_iEntityPk := :Key()
                else
                    l_cErrorMessage := "Failed to add Entity."
                endif
            else
                if !:Update(l_iEntityPk)
                    l_cErrorMessage := "Failed to update Entity."
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelML >= 5
                CustomFieldsSave(par_iProjectPk,USEDON_ENTITY,l_iEntityPk)
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iEntityPk := 0

case l_cActionOnSubmit == "Delete"   // Entity
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveEntityAssociationDelete(par_iProjectPk)
            l_cErrorMessage := CascadeDeleteEntity(par_iProjectPk,l_iEntityPk)
            if empty(l_cErrorMessage)
                l_iEntityPk := 0
            endif
        else
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
                                    :Delete("a29d2506-9044-497e-8de3-06a08120e9bf","DiagramEntity",ListOfDiagramEntityRecordsToDelete->pk)
                                endscan
                            endif

                            CustomFieldsDelete(par_iProjectPk,USEDON_ENTITY,l_iEntityPk)
                            if :Delete("6818930c-2486-49b9-a2b6-df7d50dd020f","Entity",l_iEntityPk)
                                l_iEntityPk := 0
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
case !empty(l_cErrorMessage)
    l_hValues["fk_package"]  := l_iEntityFk_Package
    l_hValues["Name"]        := l_cEntityName
    l_hValues["UseStatus"]   := l_nEntityUseStatus
    l_hValues["Description"] := l_cEntityDescription
    l_hValues["Information"] := l_cEntityInformation
    CustomFieldsFormToHash(par_iProjectPk,USEDON_ENTITY,@l_hValues)

    l_cHtml += EntityEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,l_cErrorMessage,l_iEntityPk,l_hValues)

case empty(l_iEntityPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListEntities/"+par_cModelLinkUID+"/")

otherwise
    with object l_oDB1
        :Table("81c56314-d438-4bf2-b972-2d84e1bc89e1","Entity")
        :Column("Entity.LinkUID" , "Entity_LinkUID")
        l_oData := :Get(l_iEntityPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+alltrim(l_oData:Entity_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================


//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function PackageTreeBuild(par_iModelPk, par_cSelectedPackageLinkUID, par_cSelectedAssociationLinkUID, par_cSelectedEntityLinkUID)
local l_cHtml := []
local l_oDB_ListOfPackages := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntities := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAssociations := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:p_cSitePath
local l_cSelectedPackageFullPk := []
local l_cSelectedPackagePk
local l_cSelectedEntityPk
local l_cSelectedAssociationPk

local l_nNumberOfPackages
local l_nNumberOfEntities

local l_cTreeIdPrefix := [packagesTree-]

oFcgi:TraceAdd("PackageTreeBuild")

with object l_oDB_ListOfPackages
    :Table("e0c3c824-5ab0-4fce-8234-1c646e8ac803","Package")
    :Column("Package.pk"        ,"pk")
    :Column("Package.LinkUID"   ,"Package_LinkUID")
    :Column("Package.Name"      ,"Package_Name")
    :Column("Package.FullName"  ,"Package_FullName")
    :Column("Package.FullPk"    ,"Package_FullPk")
    :Column("Package.TreeOrder1","tag1")
    :Column("Package.fk_Package","Package_Parent")
    :Where("Package.fk_Model = ^",par_iModelPk)
    :OrderBy("tag1")
    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith


with object l_oDB_ListOfEntities
    :Table("1FB3D5FB-B8F3-4515-B091-55ED9CB4AB3B","Entity")
    :Column("Entity.pk"        ,"pk")
    :Column("Entity.LinkUID"   ,"Entity_LinkUID")
    :Column("Entity.Name"  ,"Entity_Name")
    :Column("Entity.fk_Package","Entity_Parent")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    //:Join("left outer","Package","","Entity.fk_Package = Package.pk")
    :OrderBy("Entity_Name")
    :SQL("ListOfEntities")
    l_nNumberOfEntities := :Tally
endwith

with object l_oDB_ListOfAssociations
    :Table("0C757B19-C062-4B1B-B97A-AF70A1974BDE","Association")
    :Column("Association.pk"        ,"pk")
    :Column("Association.LinkUID"   ,"Association_LinkUID")
    :Column("Association.Name"  ,"Association_Name")
    :Column("Association.fk_Package","Association_Parent")
    :Where("Association.fk_Model = ^",par_iModelPk)
    //:Join("left outer","Package","","Association.fk_Package = Package.pk")
    :OrderBy("Association_Name")
    :SQL("ListOfAssociations")
endwith

//This is using https://github.com/chrisv2/bs5treeview
if !empty(l_nNumberOfPackages)
    
    l_cHtml += [<div id="packagesTree" class="collapse hide"></div>]
    l_cHtml += [<script>]        
    l_cHtml += [function getTree() {]
    l_cHtml += '  var data = ['
    l_cHtml += [{id:"]+l_cTreeIdPrefix+[0",text:"Uncontained ]+oFcgi:p_ANFEntities+[", icon: "bi bi-boxes",]+'nodes:['
    l_cHtml += [{id:"]+l_cTreeIdPrefix+[A",text:"]+oFcgi:p_ANFAssociations+[", icon: "bi bi-box-arrow-in-up-right",]+'nodes:[]} ]},'
    select ListOfPackages
    scan all
        l_cHtml += [{id:"]+l_cTreeIdPrefix+trans(ListOfPackages->pk)+[",]
        if !empty(ListOfPackages->Package_Parent)
            l_cHtml += [parentId:"]+l_cTreeIdPrefix+trans(ListOfPackages->Package_Parent)+[",]
        endif
        if !empty(par_cSelectedPackageLinkUID) .and. par_cSelectedPackageLinkUID == ListOfPackages->Package_LinkUID
            l_cSelectedPackageFullPk = ListOfPackages->Package_FullPk
            l_cSelectedPackagePk = ListOfPackages->pk
            l_cHtml += [expanded: true,]
        endif
        l_cHtml += [href:"]+l_cSitePath+[Modeling/EditPackage/]+ListOfPackages->Package_LinkUID+[/", text:"]+ListOfPackages->Package_Name+[", icon: "bi bi-folder",]
        l_cHtml += 'nodes: [ {id:"'+l_cTreeIdPrefix+trans(ListOfPackages->pk)+'-A",text:"'+oFcgi:p_ANFAssociations+'", icon: "bi bi-box-arrow-in-up-right", nodes: []'
        if !empty(par_cSelectedAssociationLinkUID)
            l_cHtml += [,expanded: true]
        endif
        l_cHtml += '} ]'
        l_cHtml += [},]
    endscan
    select ListOfEntities
    scan all
        l_cHtml += [{id:"]+l_cTreeIdPrefix+[E]+trans(ListOfEntities->pk)+[",]
        if !empty(ListOfEntities->Entity_Parent)
            l_cHtml += [parentId:"]+l_cTreeIdPrefix+trans(ListOfEntities->Entity_Parent)+[",]
        else
            l_cHtml += [parentId:"]+l_cTreeIdPrefix+[0",]
        endif
        l_cHtml += [href:"]+l_cSitePath+[Modeling/EditEntity/]+ListOfEntities->Entity_LinkUID+[/", text:"]+ListOfEntities->Entity_Name+[", icon: "bi bi-box",]
        l_cHtml += [},]
        if !empty(par_cSelectedEntityLinkUID) .and. par_cSelectedEntityLinkUID == ListOfEntities->Entity_LinkUID
            l_cSelectedEntityPk = ListOfEntities->pk
        endif
    endscan
    select ListOfAssociations
    scan all
        l_cHtml += [{id:"]+l_cTreeIdPrefix+[A]+trans(ListOfAssociations->pk)+[",]
        if !empty(ListOfAssociations->Association_Parent)
            l_cHtml += [parentId:"]+l_cTreeIdPrefix+trans(ListOfAssociations->Association_Parent)+[-A",]
        else
            l_cHtml += [parentId:"]+l_cTreeIdPrefix +[A",]
        endif
        l_cHtml += [href:"]+l_cSitePath+[Modeling/EditAssociation/]+ListOfAssociations->Association_LinkUID+[/", text:"]+ListOfAssociations->Association_Name+[", icon: "bi bi-box-arrow-in-up-right",]
        l_cHtml += [},]
        if !empty(par_cSelectedAssociationLinkUID) .and. par_cSelectedAssociationLinkUID == ListOfAssociations->Association_LinkUID
            l_cSelectedAssociationPk = ListOfAssociations->pk
        endif
    endscan
    l_cHtml += '  ];'
    if !empty(l_cSelectedPackageFullPk) .and. !empty(par_cSelectedAssociationLinkUID)
        l_cHtml += 'var isAssocSelected = true;'
    else
        l_cHtml += 'var isAssocSelected = false;'
    endif
    l_cHtml += 'var selectedPKs = "'+l_cSelectedPackageFullPk+'";'
    if !empty(par_cSelectedEntityLinkUID) .or. !empty(par_cSelectedAssociationLinkUID)
        l_cHtml += 'if(selectedPKs == "") {'
        l_cHtml += '    selectedPKs = "0"'
        l_cHtml += '}'
    endif
    l_cHtml += 'var splitSelectedPKs = selectedPKs.split("*");'
    l_cHtml += 'for (var i=0; i<data.length; i++) { '
    l_cHtml += '    if(splitSelectedPKs.includes(data[i].id.substring("'+l_cTreeIdPrefix+'".length))) {'
    l_cHtml += '       data[i].expanded = true;'
    l_cHtml += '       if(isAssocSelected && splitSelectedPKs[splitSelectedPKs.length-1] == data[i].id.substring("'+l_cTreeIdPrefix+'".length)) {'
    l_cHtml += '           data[i].nodes[0].expanded = true;'
    l_cHtml += '       }'
    l_cHtml += '    }'
    l_cHtml += '}'
    l_cHtml += 'buildTree(data);'
    l_cHtml += 'modifyLeafNodes(data);'
    l_cHtml += [  return data;]
    l_cHtml += [}]
    l_cHtml += [$("#packagesTree").bstreeview({data: getTree(),  expandIcon: 'bi bi-caret-down', collapseIcon: 'bi bi-caret-right', openNodeLinkOnNewTab: false});]
    if !empty(l_cSelectedEntityPk)
        l_cHtml += [$("#]+l_cTreeIdPrefix+[E]+trans(l_cSelectedEntityPk)+[").toggleClass("active");]
    else
        if !empty(l_cSelectedAssociationPk)
            l_cHtml += [$("#]+l_cTreeIdPrefix+[A]+trans(l_cSelectedAssociationPk)+[").toggleClass("active");]
        else
            if !empty(l_cSelectedPackagePk)
                l_cHtml += [$("#]+l_cTreeIdPrefix+trans(l_cSelectedPackagePk)+[").toggleClass("active");]
            endif
        endif
    endif
    l_cHtml += [</script>]
endif

return l_cHtml

//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function DataTypeTreeBuild(par_iModelPk, par_cModelLinkUID, par_cSelectedDataTypeLinkUID, par_cSelectedEnumerationLinkUID)
local l_cHtml := []
local l_oDB_ListOfDataTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumerations := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:p_cSitePath
local l_cTreeIdPrefix := "dataTypesTree"
local l_cSelectedDataTypeFullPk := []
local l_cSelectedDataTypePk
local l_cSelectedEnumerationPk

local l_nNumberOfEnumerations

oFcgi:TraceAdd("DataTypeTreeBuild")

with object l_oDB_ListOfDataTypes
    :Table("FDD6607E-63E7-4328-81AB-B85BFDBF6040","DataType")
    :Column("DataType.pk"        ,"pk")
    :Column("DataType.LinkUID"   ,"DataType_LinkUID")
    :Column("DataType.Name"  ,"DataType_Name")
    :Column("DataType.fk_DataType","DataType_Parent")
    :Column("DataType.FullPk"  ,"DataType_FullPk")
    :Where("DataType.fk_Model = ^",par_iModelPk)
    //:Join("left outer","Package","","DataType.fk_Package = Package.pk")
    :OrderBy("DataType_Name")
    :SQL("ListOfDataTypes")
    // l_nNumberOfDataTypes := :Tally
endwith

with object l_oDB_ListOfEnumerations
    :Table("9A99267C-B249-44EB-B59A-166B7E5964FA","ModelEnumeration")
    :Column("ModelEnumeration.pk"        ,"pk")
    :Column("ModelEnumeration.LinkUID"   ,"Enumeration_LinkUID")
    :Column("ModelEnumeration.Name"  ,"Enumeration_Name")
    :Where("ModelEnumeration.fk_Model = ^",par_iModelPk)
    :OrderBy("Enumeration_Name")
    :SQL("ListOfEnumerations")
    l_nNumberOfEnumerations := :Tally
endwith


//This is using https://github.com/chrisv2/bs5treeview

    
l_cHtml += [<div id="dataTypesTree" class="collapse hide"></div>]
l_cHtml += [<script>]
l_cHtml += [function getDTTree() {]
l_cHtml += '  var dataDT = ['
l_cHtml += [{id:"]+l_cTreeIdPrefix+[0",text:"]+oFcgi:p_ANFDataTypes+[", icon: "bi bi-code-slash",]
l_cHtml += [href:"]+l_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+'",nodes:[],'
if !empty(par_cSelectedDataTypeLinkUID)
    l_cHtml += [expanded: true,]
endif
l_cHtml += '},'
select ListOfDataTypes
scan all
    l_cHtml += [{id:"]+l_cTreeIdPrefix+trans(ListOfDataTypes->pk)+[",]
    if !empty(ListOfDataTypes->DataType_Parent)
        l_cHtml += [parentId:"]+l_cTreeIdPrefix+trans(ListOfDataTypes->DataType_Parent)+[",]
    else
        l_cHtml += [parentId:"]+l_cTreeIdPrefix+[0",]
    endif
    if !empty(par_cSelectedDataTypeLinkUID) .and. par_cSelectedDataTypeLinkUID == ListOfDataTypes->DataType_LinkUID
        l_cSelectedDataTypePk := ListOfDataTypes->pk
        l_cSelectedDataTypeFullPk := ListOfDataTypes->DataType_FullPk
        l_cHtml += [expanded: true,]
    endif
    l_cHtml += [href:"]+l_cSitePath+[Modeling/EditDataType/]+ListOfDataTypes->DataType_LinkUID+[/", text:"]+ListOfDataTypes->DataType_Name+[", icon: "bi bi-code",]
    l_cHtml += 'nodes: [ ]'
    l_cHtml += [},]
endscan
l_cHtml += [{id:"]+l_cTreeIdPrefix+[E0",text:"Enumerations", icon: "bi bi-card-list",]
l_cHtml += [href:"]+l_cSitePath+[Modeling/ListEnumerations/]+par_cModelLinkUID+'",nodes:[],'
if !empty(par_cSelectedEnumerationLinkUID)
    l_cHtml += [expanded: true,]
endif
l_cHtml += '},'
select ListOfEnumerations
scan all
    l_cHtml += [{id:"]+l_cTreeIdPrefix+[E]+trans(ListOfEnumerations->pk)+[",]
    l_cHtml += [parentId:"]+l_cTreeIdPrefix+[E0",]
    if !empty(par_cSelectedEnumerationLinkUID) .and. par_cSelectedEnumerationLinkUID == ListOfEnumerations->Enumeration_LinkUID
        l_cSelectedEnumerationPk := ListOfEnumerations->pk
    endif
    l_cHtml += [href:"]+l_cSitePath+[Modeling/EditEnumeration/]+ListOfEnumerations->Enumeration_LinkUID+[/", text:"]+ListOfEnumerations->Enumeration_Name+[", icon: "bi bi-card-list"]
    l_cHtml += [},]
endscan
l_cHtml += '  ];'
l_cHtml += 'var selectedPKs = "'+l_cSelectedDataTypeFullPk+'";'
if !empty(par_cSelectedDataTypeLinkUID) .or. !empty(par_cSelectedEnumerationLinkUID)
    l_cHtml += 'if(selectedPKs == "") {'
    l_cHtml += '    selectedPKs = "0"'
    l_cHtml += '}'
endif
l_cHtml += 'var splitSelectedPKs = selectedPKs.split("*");'
l_cHtml += 'for (var i=0; i<dataDT.length; i++) { '
l_cHtml += '    if(splitSelectedPKs.includes(dataDT[i].id.substring("'+l_cTreeIdPrefix+'".length))) {'
l_cHtml += '       dataDT[i].expanded = true;'
l_cHtml += '    }'
l_cHtml += '}'
l_cHtml += 'buildDTTree(dataDT);'
l_cHtml += 'modifyLeafNodes(dataDT);'
l_cHtml += [  return dataDT;]
l_cHtml += [}]
l_cHtml += [$("#dataTypesTree").bstreeview({data: getDTTree(),  expandIcon: 'bi bi-caret-down', collapseIcon: 'bi bi-caret-right', openNodeLinkOnNewTab: false});]
if !empty(l_cSelectedDataTypePk)
    l_cHtml += [$("#]+l_cTreeIdPrefix+trans(l_cSelectedDataTypePk)+[").toggleClass("active");]
else
    if !empty(l_cSelectedEnumerationPk)
        l_cHtml += [$("#]+l_cTreeIdPrefix+[E]+trans(l_cSelectedEnumerationPk)+[").toggleClass("active");]
    endif
endif
l_cHtml += [</script>]


return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function PackageListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfPackages := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath

local l_nNumberOfPackages
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("PackageListFormBuild")

with object l_oDB_ListOfPackages
    :Table("e0c3c824-5ab0-4fce-8234-1c646e8ac803","Package")
    :Column("Package.pk"        ,"pk")
    :Column("Package.LinkUID"   ,"Package_LinkUID")
    :Column("Package.Name"      ,"Package_Name")
    :Column("Package.UseStatus" ,"Package_UseStatus")
    :Column("Package.FullName"  ,"Package_FullName")
    :Column("Package.TreeOrder1","tag1")
    :Column("Package.fk_Package","Package_Parent")
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewPackage/]+par_cModelLinkUID+[/]+[">New ]+oFcgi:p_ANFPackage+[</a>]
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

    l_cHtml += [<div class="row justify-content-left">]
        l_cHtml += [<div class="col">]
            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped
            
            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"2","3")+[">]+oFcgi:p_ANFPackages+[ (]+Trans(l_nNumberOfPackages)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Full Name</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfPackages
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfPackages->Package_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditPackage/]+ListOfPackages->Package_LinkUID+[/">]+ListOfPackages->Package_FullName+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfPackages->Package_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfPackages->Package_UseStatus,USESTATUS_UNKNOWN)]
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
local l_nUseStatus  := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_ifk_Package := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_oDB1        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfOtherPackages

oFcgi:TraceAdd("PackageEditFormBuild")

FixNonNormalizeFieldsInPackage(par_iModelPk)    // Just in case data got corrupted.

with object l_oDB1
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

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFPackage+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
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
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                    select ListOfOtherPackages
                    scan all
                        if !("*"+Trans(par_iPk)+"*" $ "*"+ListOfOtherPackages->Package_FullPk+"*")
                            l_cHtml += [<option value="]+Trans(ListOfOtherPackages->pk)+["]+iif(ListOfOtherPackages->pk = l_ifk_Package,[ selected],[])+[>]+alltrim(ListOfOtherPackages->Package_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_PACKAGE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()


return l_cHtml
//=================================================================================================================
static function PackageEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iPackagePk
local l_iPackageFk_Package
local l_cPackageName
local l_nPackageUseStatus
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

oFcgi:TraceAdd("PackageEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iPackagePk         := Val(oFcgi:GetInputValue("PackageKey"))

l_iPackageFk_Package := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cPackageName       := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nPackageUseStatus  := Val(oFcgi:GetInputValue("ComboUseStatus"))

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
                :Where("Package.fk_Package = ^",l_iPackageFk_Package)
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
                :Field("Package.UseStatus" ,l_nPackageUseStatus)
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

// case el_IsInlist(l_cActionOnSubmit,"Cancel","Done")
case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iPackagePk := 0

case l_cActionOnSubmit == "Delete"   // Package
    if oFcgi:p_nAccessLevelML >= 5
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
                            FixNonNormalizeFieldsInPackage(par_iModelPk)
                            l_iPackagePk := 0
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
case !empty(l_cErrorMessage)
    l_hValues["fk_package"] := l_iPackageFk_Package
    l_hValues["Name"]       := l_cPackageName
    l_hValues["UseStatus"]  := l_nPackageUseStatus
    CustomFieldsFormToHash(par_iProjectPk,USEDON_PACKAGE,@l_hValues)

    l_cHtml += PackageEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID,l_cErrorMessage,l_iPackagePk,l_hValues)

case empty(l_iPackagePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListPackages/"+par_cModelLinkUID+"/")

otherwise
    with object l_oDB1
        :Table("b0c312b6-8233-44b8-b46c-27076cff714a","Package")
        :Column("Package.LinkUID" , "Package_LinkUID")
        l_oData := :Get(l_iPackagePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditPackage/"+alltrim(l_oData:Package_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListPackages/"+par_cModelLinkUID+"/")
        endif
    endwith
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function GetDataTypesEditHeader(par_cSitePath, par_cModelLinkUID, par_cDataTypeElement)
    local l_cHtml := ""
    l_cHtml += [<ul class="nav nav-tabs">]
    
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cDataTypeElement == "ListDataTypes",[ active],[])+[" href="]+par_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+[/">List ]+oFcgi:p_ANFDataTypes+[</a>]
        l_cHtml += [</li>]
    
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cDataTypeElement == "ListEnumerations",[ active],[])+[" href="]+par_cSitePath+[Modeling/ListEnumerations/]+par_cModelLinkUID+[/">List ]+oFcgi:p_ANFModelEnumerations+[</a>]
        l_cHtml += [</li>]
    
    l_cHtml += [</ul>]
    return l_cHtml

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function DataTypeListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfPrimitiveTypesWithMissingDataType := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDataTypes                         := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                            := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB1

local l_cSitePath := oFcgi:p_cSitePath

local l_nNumberOfDataTypes
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nNumberOfPrimitiveTypesWithMissingDataType
local l_lShowActionButton := .f.

local l_cAction := oFcgi:GetQueryString("action")

oFcgi:TraceAdd("DataTypeListFormBuild")

with object l_oDB_ListOfPrimitiveTypesWithMissingDataType
    :Table("f7dd3558-0c7a-46f6-aae5-f2a2ba476d9e","PrimitiveType")
    :Column("PrimitiveType.pk"  , "PrimitiveType_pk")
    :Column("DataType.pk"       , "datatype_pk")
    :Column("PrimitiveType.Name", "PrimitiveType_Name")
    :Join("left","DataType","","DataType.fk_PrimitiveType = PrimitiveType.pk and DataType.fk_Model = ^ and DataType.Name = PrimitiveType.Name" , par_iModelPk)
    :Where("PrimitiveType.fk_Project = ^" , par_iProjectPk)
    // :Having("datatype_pk is null")  PostgreSQL does not support Having on result field names.
    :SQL("ListOfPrimitiveTypesWithMissingDataType")
    l_nNumberOfPrimitiveTypesWithMissingDataType := :Tally

endwith


if l_cAction == "LoadAllPrimitives"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

    if l_nNumberOfPrimitiveTypesWithMissingDataType > 0
        select ListOfPrimitiveTypesWithMissingDataType

        scan all for hb_orm_isnull("ListOfPrimitiveTypesWithMissingDataType","datatype_pk")
            with object l_oDB1
                :Table("08400f2e-4f92-4bd4-8029-e282642aeef2","DataType")
                :Column("DataType.pk" , "DataType_pk")
                :Where("DataType.fk_Model = ^",par_iModelPk)
                :Where([lower(replace(DataType.Name,' ','')) = ^],lower(StrTran(ListOfPrimitiveTypesWithMissingDataType->PrimitiveType_Name," ","")))
                :SQL("ListOfDataTypeWithMatchingPrimitiveName")
                do case
                case :Tally < 0
                    //Ignore Error
                case :Tally == 0
                    //Add the Primitive Type as a new DataType
                    :Table("a584ae40-ded9-4848-aee6-3aecd314aec5","DataType")
                    :Field("DataType.LinkUID"          , oFcgi:p_o_SQLConnection:GetUUIDString())
                    :Field("DataType.fk_Model"         , par_iModelPk)
                    :Field("DataType.fk_PrimitiveType" , ListOfPrimitiveTypesWithMissingDataType->PrimitiveType_pk)
                    :Field("DataType.name"             , ListOfPrimitiveTypesWithMissingDataType->PrimitiveType_Name)
                    :Add()
                otherwise  // Only update the first record, show should be the only one
                    :Table("3796b625-e83f-4717-a2c3-43503d394e83","DataType")
                    :Field("DataType.fk_PrimitiveType" , ListOfPrimitiveTypesWithMissingDataType->PrimitiveType_pk)
                    :Update(ListOfDataTypeWithMatchingPrimitiveName->datatype_pk)
                endcase
            endwith
            // SendToDebugView("Will Add "+ListOfPrimitiveTypesWithMissingDataType->PrimitiveType_Name)
        endscan

        FixNonNormalizeFieldsInDataType(par_iModelPk)

    endif
else
    if l_nNumberOfPrimitiveTypesWithMissingDataType > 0
        select ListOfPrimitiveTypesWithMissingDataType
        scan all for hb_orm_isnull("ListOfPrimitiveTypesWithMissingDataType","datatype_pk")
            l_lShowActionButton := .t.
            exit
        endscan
    endif

endif

with object l_oDB_ListOfDataTypes
    :Table("96013fec-eb2d-4a2c-ad59-080501e21fd2","DataType")
    :Column("DataType.pk"         ,"pk")
    :Column("DataType.LinkUID"    ,"DataType_LinkUID")
    :Column("DataType.FullName"   ,"DataType_FullName")
    :Column("DataType.UseStatus"  ,"DataType_UseStatus")
    :Column("DataType.Description","DataType_Description")
    :Column("PrimitiveType.Name"  ,"PrimitiveType_Name")
    :Column("DataType.TreeOrder1","tag1")
    :Join("left","PrimitiveType","","DataType.fk_PrimitiveType = PrimitiveType.pk")
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewDataType/]+par_cModelLinkUID+[/]+[">New ]+oFcgi:p_ANFDataType+[</a>]
                        if l_lShowActionButton
                            l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+[/?action=LoadAllPrimitives]+[">Load All Primitives</a>]
                        endif
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

    l_cHtml += [<div class="row justify-content-left">]
        l_cHtml += [<div class="col">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped
            
            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"4","5")+[">]+oFcgi:p_ANFDataTypes+[ (]+Trans(l_nNumberOfDataTypes)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Full Name</th>]
                l_cHtml += [<th class="text-white">Primitive Type</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfDataTypes
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfDataTypes->DataType_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditDataType/]+ListOfDataTypes->DataType_LinkUID+[/">]+ListOfDataTypes->DataType_FullName+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += nvl(ListOfDataTypes->PrimitiveType_Name,"")
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfDataTypes->DataType_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfDataTypes->DataType_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfDataTypes->DataType_UseStatus,USESTATUS_UNKNOWN)]
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

local l_ifk_DataType      := nvl(hb_HGetDef(par_hValues,"fk_DataType",0),0)
local l_ifk_PrimitiveType := nvl(hb_HGetDef(par_hValues,"fk_PrimitiveType",0),0)
local l_cName             := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus        := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_cDescription      := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfOtherDataTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfPrimitiveTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfOtherDataTypes
local l_nNumberOfPrimitiveTypes

oFcgi:TraceAdd("DataTypeEditFormBuild")

FixNonNormalizeFieldsInDataType(par_iModelPk)    // Just in case data got corrupted.

with object l_oDB_ListOfOtherDataTypes
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
endwith

with object l_oDB_ListOfPrimitiveTypes
    //Build the list of Other DataTypes
    :Table("0dcb51f1-0606-4e9b-8426-e1d9e55969d6","PrimitiveType")
    :Column("PrimitiveType.pk"          , "pk")
    :Column("PrimitiveType.Name"        , "PrimitiveType_Name")
    :Column("upper(PrimitiveType.Name)" , "tag1")
    :Where("PrimitiveType.fk_Project = ^" , par_iProjectPk)
    :OrderBy("tag1")
    :SQL("ListOfPrimitiveTypes")
    l_nNumberOfPrimitiveTypes := :Tally
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="DataTypeKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFDataType+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
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
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDataTypePk" id="ComboDataTypePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_DataType,[ selected],[])+[></option>]
                    select ListOfOtherDataTypes
                    scan all
                        if !("*"+Trans(par_iPk)+"*" $ "*"+ListOfOtherDataTypes->DataType_FullPk+"*")
                            l_cHtml += [<option value="]+Trans(ListOfOtherDataTypes->pk)+["]+iif(ListOfOtherDataTypes->pk = l_ifk_DataType,[ selected],[])+[>]+alltrim(ListOfOtherDataTypes->DataType_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        if l_nNumberOfPrimitiveTypes > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Primitive Type</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboPrimitiveTypePk" id="ComboPrimitiveTypePk"]+iif(oFcgi:p_nAccessLevelML >= 7,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_PrimitiveType,[ selected],[])+[></option>]
                    select ListOfPrimitiveTypes
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfPrimitiveTypes->pk)+["]+iif(ListOfPrimitiveTypes->pk = l_ifk_PrimitiveType,[ selected],[])+[>]+alltrim(ListOfPrimitiveTypes->PrimitiveType_Name)+[</option>]
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_DATATYPE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function DataTypeEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iDataTypePk
local l_iDataTypeFk_DataType
local l_iDataTypeFk_PrimitiveType
local l_cDataTypeName
local l_nDataTypeUseStatus
local l_cDataTypeDescription
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

oFcgi:TraceAdd("DataTypeEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iDataTypePk := Val(oFcgi:GetInputValue("DataTypeKey"))

l_iDataTypeFk_DataType      := Val(oFcgi:GetInputValue("ComboDataTypePk"))
l_iDataTypeFk_PrimitiveType := Val(oFcgi:GetInputValue("ComboPrimitiveTypePk"))
l_cDataTypeName             := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nDataTypeUseStatus        := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cDataTypeDescription      := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

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
                :Where("DataType.fk_DataType = ^",l_iDataTypeFk_DataType)
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
                :Field("DataType.fk_DataType"     ,l_iDataTypeFk_DataType)
                :Field("DataType.fk_PrimitiveType",l_iDataTypeFk_PrimitiveType)
                :Field("DataType.Name"            ,l_cDataTypeName)
                :Field("DataType.UseStatus"       ,l_nDataTypeUseStatus)
                :Field("DataType.Description"     ,iif(empty(l_cDataTypeDescription),NULL,l_cDataTypeDescription))
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

case l_cActionOnSubmit == "Done"
    l_iDataTypePk := 0

case l_cActionOnSubmit == "Delete"   // DataType
    if oFcgi:p_nAccessLevelML >= 5
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
                        FixNonNormalizeFieldsInDataType(par_iModelPk)
                        l_iDataTypePk := 0
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
case !empty(l_cErrorMessage)
    l_hValues["fk_DataType"]      := l_iDataTypeFk_DataType
    l_hValues["fk_PrimitiveType"] := l_iDataTypeFk_PrimitiveType
    l_hValues["Name"]             := l_cDataTypeName
    l_hValues["UseStatus"]        := l_nDataTypeUseStatus
    l_hValues["Description"]      := l_cDataTypeDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_DATATYPE,@l_hValues)

    l_cHtml += DataTypeEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID,l_cErrorMessage,l_iDataTypePk,l_hValues)

case empty(l_iDataTypePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("858553f2-260a-4306-88c7-e8e4ce3c68f2","DataType")
        :Column("DataType.LinkUID" , "DataType_LinkUID")
        l_oData := :Get(l_iDataTypePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditDataType/"+alltrim(l_oData:DataType_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
static function GetEnumerationEditHeader(par_cSitePath, par_cModelLinkUID, par_cEnumerationLinkUID, par_cEnumerationElement)
local l_cHtml := ""
l_cHtml += [<ul class="nav nav-tabs">]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(empty(par_cEnumerationElement),[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEnumeration/]+par_cEnumerationLinkUID+[/">Edit Enumeration</a>]
    l_cHtml += [</li>]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cEnumerationElement == "ListEnumValues",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEnumeration/]+par_cEnumerationLinkUID+[/ListEnumValues">Values</a>]
    l_cHtml += [</li>]

    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cEnumerationElement == "OrderEnumValues",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditEnumeration/]+par_cEnumerationLinkUID+[/OrderEnumValues">Order Values</a>]
    l_cHtml += [</li>]


l_cHtml += [</ul>]
return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumerationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:p_cSitePath
local l_iEnumValueCount
local l_nNumberOfEnumerations

oFcgi:TraceAdd("EnumerationListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("F10B068C-09D9-42BA-8769-1212C91DFF24","ModelEnumeration")
    :Column("ModelEnumeration.pk"                ,"pk")
    :Column("ModelEnumeration.fk_Model"          ,"Enumeration_fk_Model")
    :Column("ModelEnumeration.Name"              ,"Enumeration_Name")
    :Column("ModelEnumeration.UseStatus"         ,"Enumeration_UseStatus")
    :Column("ModelEnumeration.LinkUID"           ,"Enumeration_LinkUID")
    :Column("ModelEnumeration.Description"       ,"Enumeration_Description")
    :Column("Upper(ModelEnumeration.Name)","tag1")
    :Where("ModelEnumeration.fk_Model = ^",par_iModelPk)
    :OrderBy("tag1")
    :SQL("ListOfEnumerations")
    l_nNumberOfEnumerations := :Tally
endwith

with object l_oDB2
    :Table("1261797F-A24B-4808-AE11-322BF2078CF7","ModelEnumeration")
    :Column("ModelEnumeration.pk" ,"ModelEnumeration_pk")
    :Column("Count(*)" ,"ModelEnumValueCount")
    :Join("inner","ModelEnumValue","","ModelEnumValue.fk_ModelEnumeration = ModelEnumeration.pk")
    :Where("ModelEnumeration.fk_Model = ^",par_iModelPk)
    :GroupBy("ModelEnumeration_pk")
    :SQL("ListOfEnumerationsEnumValueCounts")

    with object :p_oCursor
        :Index("tag1","ModelEnumeration_pk")
        :CreateIndexes()
    endwith
endwith


if l_nNumberOfEnumerations <= 0
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No Enumeration on file for current model.</span>]
                l_cHtml += [<a class="btn btn-primary rounded ms-0" href="]+l_cSitePath+[Modeling/NewEnumeration/]+par_cModelLinkUID+[/">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
    endif

else
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            // l_cHtml += [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/NewEnumeration/]+par_cModelLinkUID+[/]+[">New Enumeration</a>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

        l_cHtml += [<div class="m-3"></div>]   //Spacer
    endif

    l_cHtml += [<div class="m-3">]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col">]

                l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="4">Enumerations (]+Trans(l_nNumberOfEnumerations)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Enumeration Name</th>]
                    l_cHtml += [<th class="text-white">Values</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                l_cHtml += [</tr>]

                select ListOfEnumerations
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfEnumerations->Enumeration_UseStatus)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEnumeration/]+ListOfEnumerations->Enumeration_LinkUID+[/">]+ListOfEnumerations->Enumeration_Name+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                            l_iEnumValueCount := iif( el_seek(ListOfEnumerations->pk,"ListOfEnumerationsEnumValueCounts","tag1") , ListOfEnumerationsEnumValueCounts->ModelEnumValueCount , 0)
                            l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEnumValues/]+ListOfEnumerations->Enumeration_LinkUID+[/">]+Trans(l_iEnumValueCount)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumerations->Enumeration_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfEnumerations->Enumeration_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfEnumerations->Enumeration_UseStatus,USESTATUS_UNKNOWN)]
                        l_cHtml += [</td>]
                    
                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]
    l_cHtml += [</div>]
endif

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumerationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cSitePath := oFcgi:p_cSitePath
local l_cErrorText       := hb_DefaultValue(par_cErrorText,"")

local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDataTableInfo

oFcgi:TraceAdd("EnumerationEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Enumeration</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif

        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Enumeration Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
        l_cHtml += [<td class="pb-3">]
            l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
            l_cHtml += [</select>]
        l_cHtml += [</td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
    l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
    l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function EnumerationEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumerationPk
local l_cEnumerationName
local l_nEnumerationUseStatus
local l_cEnumerationDescription
local l_cEnumerationLinkUID
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData

oFcgi:TraceAdd("EnumerationEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumerationPk          := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumerationName        := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))
l_nEnumerationUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cEnumerationDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cEnumerationName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("E95A6597-49A1-401F-857A-EFC1F1DEA671","ModelEnumeration")
                :Column("ModelEnumeration.pk","pk")
                :Where([ModelEnumeration.fk_Model = ^],par_iModelPk)
                :Where([lower(replace(ModelEnumeration.Name,' ','')) = ^],lower(StrTran(l_cEnumerationName," ","")))
                if l_iEnumerationPk > 0
                    :Where([ModelEnumeration.pk != ^],l_iEnumerationPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif
        endif
    endif

    if empty(l_cErrorMessage)
        //Save the Enumeration
        with object l_oDB1
            :Table("1C138E95-5E3F-4C63-BA26-EFBFDD020D5B"   ,"ModelEnumeration")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("ModelEnumeration.fk_Model"       , par_iModelPk)
                :Field("ModelEnumeration.Name"           , l_cEnumerationName)
                :Field("ModelEnumeration.UseStatus"      , l_nEnumerationUseStatus)
            endif
            :Field("ModelEnumeration.Description"    , iif(empty(l_cEnumerationDescription),NULL,l_cEnumerationDescription))
            if empty(l_iEnumerationPk)
                l_cEnumerationLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Field("ModelEnumeration.LinkUID" , l_cEnumerationLinkUID)
                if :Add()
                    l_iEnumerationPk := :Key()
                else
                    l_cErrorMessage := "Failed to add Enumeration."
                endif
            else
                if !:Update(l_iEnumerationPk)
                    l_cErrorMessage := "Failed to update Enumeration."
                endif
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iEnumerationPk := 0

case l_cActionOnSubmit == "Delete"   // Enumeration
    if oFcgi:p_nAccessLevelML >= 5
        with object l_oDB1
            :Table("D2BA23E6-1CDE-4976-A01F-C7855C2FEB43","Attribute")
            :Where("Attribute.fk_ModelEnumeration = ^",l_iEnumerationPk)
            :SQL()

            if :Tally == 0
                :Table("12AD9032-FC12-48C2-BDAC-9B3B641FB0E3","ModelEnumValue")
                :Where("ModelEnumValue.fk_ModelEnumeration = ^",l_iEnumerationPk)
                :SQL()

                if :Tally == 0
                    if :Delete("478DE490-9954-49DB-9F19-ED05C2AEFFB4","ModelEnumeration",l_iEnumerationPk)
                        l_iEnumerationPk := 0
                    else
                        l_cErrorMessage := "Failed to delete Enumeration"
                    endif
                else
                    l_cErrorMessage := "Related Enumeration Value record on file"
                endif
            else
                l_cErrorMessage := "Related Attribute record on file"
            endif
        endwith
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]        := l_cEnumerationName
    l_hValues["UseStatus"]   := l_nEnumerationUseStatus
    l_hValues["Description"] := l_cEnumerationDescription

    l_cHtml += EnumerationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID,l_cErrorMessage,l_iEnumerationPk,l_hValues)

case empty(l_iEnumerationPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListEnumerations/"+par_cModelLinkUID+"/")

otherwise
    with object l_oDB1
        :Table("e028335b-b589-4f05-a6c8-9b6155765773","ModelEnumeration")
        :Column("ModelEnumeration.LinkUID","Enumeration_LinkUID")
        l_oData := :Get(l_iEnumerationPk)

        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEnumeration/"+alltrim(l_oData:Enumeration_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListEnumerations/"+par_cModelLinkUID+"/")
        endif

    endswitch

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function EnumValueListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_iEnumerationPk,par_cEnumerationLinkUID,par_cEnumerationName)
local l_cHtml := []
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfEnumValues
local l_oDB1

oFcgi:TraceAdd("EnumValueListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("D9D30FA6-D8A6-4069-A737-0FC60F508371","ModelEnumValue")
    :Column("ModelEnumValue.pk"         ,"pk")
    :Column("ModelEnumValue.Name"       ,"EnumValue_Name")
    :Column("ModelEnumValue.Number"     ,"EnumValue_Number")
    :Column("ModelEnumValue.Description","EnumValue_Description")
    :Column("ModelEnumValue.Order"      ,"EnumValue_Order")
    :Where("ModelEnumValue.fk_ModelEnumeration = ^",par_iEnumerationPk)
    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
    l_nNumberOfEnumValues := :Tally
endwith

if l_nNumberOfEnumValues <= 0
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span class="navbar-brand ms-3">No Value on file for Enumeration "]+alltrim(par_cEnumerationName)+[".</span>]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-0" href="]+l_cSitePath+[Modeling/NewEnumValue/]+par_cEnumerationLinkUID+[/">New Enumeration Value</a>]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/NewEnumValue/]+par_cEnumerationLinkUID+[/]+[">New Enumeration Value</a>]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="3">Values (]+Trans(l_nNumberOfEnumValues)+[) for Enumeration "]+alltrim(par_cEnumerationName)+["</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Number</th>]
                l_cHtml += [<th class="text-white">Description</th>]
            l_cHtml += [</tr>]

            select ListOfEnumValues
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEnumValue/]+par_cEnumerationLinkUID+[/]+ListOfEnumValues->EnumValue_Name+[/">]+ListOfEnumValues->EnumValue_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                        if !hb_orm_isnull("ListOfEnumValues","EnumValue_Number")
                            l_cHtml += trans(ListOfEnumValues->EnumValue_Number)
                        endif
                        l_cHtml += hb_DefaultValue(ListOfEnumValues->EnumValue_Number,"")
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEnumValues->EnumValue_Description,""))
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif

// l_cHtml += [<div class="m-3">]
// l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormBuild(par_iEnumerationPk,par_cModelLinkUID,par_cEnumerationName,par_cEnumerationLinkUID)
local l_cHtml := []
local l_oDB1
local l_cSitePath := oFcgi:p_cSitePath

oFcgi:TraceAdd("EnumValueOrderFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Order">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iEnumerationPk)+[">]
l_cHtml += [<input type="hidden" name="ValueOrder" id="ValueOrder" value="">]

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
with object l_oDB1
    :Table("692088EC-09EC-40C7-9950-3CB70674509D","ModelEnumValue")
    :Column("ModelEnumValue.pk"         ,"pk")
    :Column("ModelEnumValue.Name"       ,"EnumValue_Name")
    :Column("ModelEnumValue.Order"      ,"EnumValue_Order")
    :Where("ModelEnumValue.fk_ModelEnumeration = ^",par_iEnumerationPk)
    :OrderBy("EnumValue_order")
    :SQL("ListOfEnumValues")
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
// l_cHtml += [alert('hello 3 '+EnumOrderData);]
l_cHtml += [$('#ValueOrder').val(EnumOrderData);]
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

// l_cHtml += [<div class="m-3">]
// l_cHtml += [</div>]

select ListOfEnumValues

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">Order Values for Enumeration "]+par_cEnumerationName+["</span>]
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnOrderListFormSave()
        endif
        l_cHtml += GetButtonCancelAndRedirect(l_cSitePath+[Modeling/ListEnumValues/]+par_cEnumerationLinkUID+[/])
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]   //Spacer

l_cHtml += [<div class="row justify-content-center m-3">]
    l_cHtml += [<div class="col-auto">]

    l_cHtml += [<ul id="sortable">]
    scan all
        l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfEnumValues->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+ListOfEnumValues->EnumValue_Name+[</span></li>]
    endscan
    l_cHtml += [</ul>]

    l_cHtml += [</div>]
l_cHtml += [</div>]


//Set the width of all the "li" to the max width of the same "li"s. This fixes a bug in .sortable with dragging the widest "li"
// l_cHtml += [<button onclick="$('#sortable li').width( Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()) );return false;">Freeze Width</button>]

// var MaxLiWidth = Math.max.apply(Math, $('#sortable li').map(function(){ return $(this).width(); }).get()); alert('Max Width = '+MaxLiWidth);

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function EnumValueOrderFormOnSubmit(par_iEnumerationPk,par_cModelLinkUID,par_cEnumerationName,par_cEnumerationLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumerationPk
local l_cEnumValuePkOrder

local l_oDB1
local l_aOrderedPks
local l_Counter

oFcgi:TraceAdd("EnumValueOrderFormOnSubmit")

l_cActionOnSubmit   := oFcgi:GetInputValue("ActionOnSubmit")
l_iEnumerationPk    := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValuePkOrder := SanitizeInput(oFcgi:GetInputValue("ValueOrder"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cEnumValuePkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB1
            :Table("C6E55B64-A15D-4812-8D2B-2E34FCE1CED1","ModelEnumValue")
            :Column("ModelEnumValue.pk","pk")
            :Column("ModelEnumValue.Order","order")
            :Where([ModelEnumValue.fk_ModelEnumeration = ^],l_iEnumerationPk)
            :SQL("ListOfEnumValue")

            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if el_seek(val(l_aOrderedPks[l_Counter]),"ListOfEnumValue","pk") .and. ListOfEnumValue->order <> l_Counter
                with object l_oDB1
                    :Table("2DC5DB7B-F029-4161-AEAB-AD162E494EC0","ModelEnumValue")
                    :Field("ModelEnumValue.order",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEnumeration/"+par_cEnumerationLinkUID+"/ListEnumValues/")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function EnumValueEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID,par_cEnumerationName,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cName            := hb_HGetDef(par_hValues,"Name","")
local l_xNumber          := hb_HGetDef(par_hValues,"Number",nil)
local l_cNumber
local l_cDescription     := nvl(hb_HGetDef(par_hValues,"Description",""),"")

if hb_IsNil(l_xNumber)
    l_cNumber := ""
else
    l_cNumber := Trans(l_xNumber)
endif

oFcgi:TraceAdd("EnumValueEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="EnumerationKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ EnumValue in Enumeration "]+par_cEnumerationName+["</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Name</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr class="pb-5">]
        l_cHtml += [<td class="pe-2 pb-3">Number</td>]
        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextNumber" id="TextNumber" value="]+FcgiPrepFieldForValue(l_cNumber)+[" maxlength="8" size="8"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
    l_cHtml += [</tr>]

    l_cHtml += [<tr>]
        l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
        l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
    l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function EnumValueEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID,par_iEnumerationPk,par_cEnumerationName)
local l_cHtml := []

local l_cActionOnSubmit
local l_iEnumValuePk
local l_cEnumValueName
local l_cEnumValueNumber,l_iEnumValueNumber
local l_cEnumValueDescription
local l_iEnumValueOrder
local l_aSQLResult   := {}
local l_hValues := {=>}
local l_cErrorMessage := ""
local l_oDB1
local l_oData

oFcgi:TraceAdd("EnumValueEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iEnumValuePk          := Val(oFcgi:GetInputValue("EnumerationKey"))
l_cEnumValueName        := SanitizeInputAlphaNumeric(oFcgi:GetInputValue("TextName"))
l_cEnumValueNumber      := SanitizeInput(oFcgi:GetInputValue("TextNumber"))
l_iEnumValueNumber      := iif(empty(l_cEnumValueNumber),NULL,val(l_cEnumValueNumber))
l_cEnumValueDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cEnumValueName)
            l_cErrorMessage := "Missing Name"
        else
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("06BDF36F-225B-4452-84F5-CE5F723BE9F7","ModelEnumValue")
                :Column("ModelEnumValue.pk","pk")
                :Where([ModelEnumValue.fk_ModelEnumeration = ^],par_iEnumerationPk)
                :Where([lower(replace(ModelEnumValue.Name,' ','')) = ^],lower(StrTran(l_cEnumValueName," ","")))
                if l_iEnumValuePk > 0
                    :Where([ModelEnumValue.pk != ^],l_iEnumValuePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif
        endif
    endif

    if empty(l_cErrorMessage)
        //If adding an EnumValue, find out what the last order is
        l_iEnumValueOrder := 1
        if empty(l_iEnumValuePk)
            with object l_oDB1
                :Table("140D8B9D-1AC6-4719-BD4E-A1D39588094C","ModelEnumValue")
                :Column("ModelEnumValue.Order","EnumValue_Order")
                :Where([ModelEnumValue.fk_ModelEnumeration = ^],par_iEnumerationPk)
                :OrderBy("EnumValue_Order","Desc")
                :Limit(1)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally > 0
                l_iEnumValueOrder := l_aSQLResult[1,1] + 1
            endif
        endif

        //Save the Enumeration Value
        with object l_oDB1
            :Table("A47CAE9C-A15D-42A4-BBA9-1D1BE2C0C1AD","ModelEnumValue")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("ModelEnumValue.Name"       ,l_cEnumValueName)
                :Field("ModelEnumValue.Number"     ,l_iEnumValueNumber)
            endif
            if empty(l_iEnumValuePk)
                :Field("ModelEnumValue.fk_ModelEnumeration" , par_iEnumerationPk)
                :Field("ModelEnumValue.Order"          ,l_iEnumValueOrder)
                if :Add()
                    l_iEnumValuePk := :Key()
                else
                    l_cErrorMessage := "Failed to add Enumeration Value."
                endif

            else
                :Update(l_iEnumValuePk)
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iEnumValuePk := 0

case l_cActionOnSubmit == "Delete"   // EnumValue
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB1:Delete("04DF0A61-DEF8-44AB-9866-54BA2BB315CA","ModelEnumValue",l_iEnumValuePk)
        l_iEnumValuePk := 0
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]            := l_cEnumValueName
    l_hValues["Number"]          := l_iEnumValueNumber
    l_hValues["Description"]     := l_cEnumValueDescription

    l_cHtml += EnumValueEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEnumerationLinkUID,par_cEnumerationName,l_cErrorMessage,l_iEnumValuePk,l_hValues)

case empty(l_iEnumValuePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEnumeration/"+par_cEnumerationLinkUID+"/ListEnumValues/")

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("0fe8904c-a8cd-4a57-898a-3cb94718e44b","ModelEnumValue")
        :Column("ModelEnumValue.Name" , "ModelEnumValue_Name")
        l_oData := :Get(l_iEnumValuePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEnumValue/"+par_cEnumerationLinkUID+"/"+strtran(l_oData:ModelEnumValue_Name," ","")+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEnumeration/"+par_cEnumerationLinkUID+"/ListEnumValues/")
        endif
    endwith
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociatedEntityLinkUID,par_cPackageLinkUID)
local l_cHtml := []
local l_oDB_ListOfAssociations               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAssociationsEndpoints      := hb_SQLData(oFcgi:p_o_SQLConnection)
// local l_oDB_ListOfAssociationsEndpointCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                     := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_iAssociationPk

local l_cSearchAssociationName
local l_cSearchAssociationDescription

local l_cSearchEndpointName
local l_cSearchEndpointDescription

local l_nNumberOfAssociations
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_nColspan

oFcgi:TraceAdd("AssociationListFormBuild")

l_cSearchAssociationName           := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationName")
l_cSearchAssociationDescription    := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationDescription")

l_cSearchEndpointName        := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointName")
l_cSearchEndpointDescription := GetUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointDescription")

with object l_oDB_ListOfAssociations
    :Table("32746fc3-3116-497f-becc-f51b1213849c","Association")
    :Column("Association.pk"         ,"pk")
    :Column("Association.LinkUID"    ,"Association_LinkUID")
    :Column("Association.Name"       ,"Association_Name")
    :Column("Association.UseStatus"  ,"Association_UseStatus")
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
    else
        if !empty(par_cAssociatedEntityLinkUID)
            :Distinct(.t.)
            :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
            :Join("inner","Entity"  ,"","Endpoint.fk_Entity = Entity.pk")
            :Where("Entity.LinkUID = ^" , par_cAssociatedEntityLinkUID)
        endif
    endif

    :Join("left","Package","","Association.fk_Package = Package.pk")
    :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")
    :Column("Package.FullName"               , "Package_FullName")
    if !empty(par_cPackageLinkUID)
        :Where("Package.LinkUID = ^" , par_cPackageLinkUID)
    endif

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
        :Column("Association.pk"         ,"fk_Association")
        :Column("Association.pk"         ,"fk_Entity") //this is required as CustomFieldsBuildGridOther relies on this key to exist

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
                    l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewAssociation/]+par_cModelLinkUID
                    if (!empty(par_cPackageLinkUID) .or. !empty(par_cAssociatedEntityLinkUID))
                        l_cHtml += "?"
                        if !empty(par_cPackageLinkUID)
                            l_cHtml += [parentPackage=]+par_cPackageLinkUID
                            if !empty(par_cAssociatedEntityLinkUID)
                                l_cHtml += [&fromEntity=]+par_cAssociatedEntityLinkUID
                            endif
                        else
                            if !empty(par_cAssociatedEntityLinkUID)
                                l_cHtml += [fromEntity=]+par_cAssociatedEntityLinkUID
                            endif
                        endif
                    endif
                    l_cHtml += [">New ]+oFcgi:p_ANFAssociation+[</a>]
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

if !empty(l_nNumberOfAssociations) .and. l_nNumberOfAssociations > 0
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-left">]
        l_cHtml += [<div class="col">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_nColspan := 6
            if l_nNumberOfCustomFieldValues > 0
                l_nColspan += 1
            endif

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="]+Trans(l_nColspan)+[">]+oFcgi:p_ANFAssociations+[ (]+Trans(l_nNumberOfAssociations)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFPackage+[</th>]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFAssociation+[ Name</th>]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFEntities+[</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfAssociations
            scan all
                l_iAssociationPk := ListOfAssociations->pk

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfAssociations->Association_UseStatus)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += alltrim(nvl(ListOfAssociations->Package_FullName,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditAssociation/]+ListOfAssociations->Association_LinkUID+[/">]+ListOfAssociations->Association_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top" align="center">]
                        select ListOfAssociationsEndpoints
                        scan all for ListOfAssociationsEndpoints->Association_pk == l_iAssociationPk
                            l_cHtml += [<div>]+ListOfAssociationsEndpoints->Entity_name+[</div>]
                        endscan
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfAssociations->Association_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfAssociations->Association_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfAssociations->Association_UseStatus,USESTATUS_UNKNOWN)]
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
static function AssociationListFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cPackageLinkUID)
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

    l_cHtml += AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cPackageLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationName"        ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_AssociationDescription" ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointName"       ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_AssociationSearch_EndpointDescription","")
    if !empty(par_cEntityLinkUID)
        l_cURL := oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListAssociations/"
    elseif !empty(par_cPackageLinkUID)
        l_cURL := oFcgi:p_cSitePath+"Modeling/EditPackage/"+par_cPackageLinkUID+"/ListAssociations/"
    else
        l_cURL := oFcgi:p_cSitePath+"Modeling/ListAssociations/"+par_cModelLinkUID+"/"
    endif
    
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += AssociationListFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cPackageLinkUID)

endcase
return l_cHtml

static function GetPackageEditHeader(par_cSitePath, par_cModelLinkUID, par_cPackageLinkUID, par_cPackageElement)
    local l_cHtml := ""
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_oPackage

    with object l_oDB1
        :Table("D25D3152-D05C-4EAB-8CAE-12F8E15AC143","Package")
        :Column("Package.pk","Package_pk")
        :Column("Package.Name" ,"Package_Name")
        :Column("PackageParent.FullName" ,"PackageParent_FullName")
        :Column("PackageParent.LinkUID" ,"PackageParent_LinkUID")
        :Join("left","Package","PackageParent","Package.fk_Package = PackageParent.pk")
        :Where("Package.LinkUID = ^",par_cPackageLinkUID)
        l_oPackage := :SQL()
    endwith

    l_cHtml += [<nav aria-label="breadcrumb">]
        l_cHtml += [<ol class="breadcrumb">]
            l_cHtml += [<li class="breadcrumb-item"><a href="]+par_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">Home</a></li>]
            l_cHtml += [<li class="breadcrumb-item"><a href="]+par_cSitePath+[Modeling/ListPackages/]+par_cModelLinkUID+[/">Packages</a></li>]
            if !empty(l_oPackage:PackageParent_LinkUID)
                l_cHtml += [<li class="breadcrumb-item"><a href="]+par_cSitePath+[Modeling/EditPackage/]+l_oPackage:PackageParent_LinkUID+[/">]+l_oPackage:PackageParent_FullName+[</a></li>]
            endif
            l_cHtml += [<li class="breadcrumb-item active" aria-current="page">]+l_oPackage:Package_Name+[</li>]
        l_cHtml += [</ol>]
    l_cHtml += [</nav>]

    l_cHtml += [<ul class="nav nav-tabs">]    
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(empty(par_cPackageElement),[ active],[])+[" href="]+par_cSitePath+[Modeling/EditPackage/]+par_cPackageLinkUID+[/">Edit ]+oFcgi:p_ANFPackage+[</a>]
        l_cHtml += [</li>]
    
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cPackageElement == "ListEntities",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditPackage/]+par_cPackageLinkUID+[/ListEntities">]+oFcgi:p_ANFEntities+[</a>]
        l_cHtml += [</li>]
    
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cPackageElement == "ListAssociations",[ active],[])+[" href="]+par_cSitePath+[Modeling/EditPackage/]+par_cPackageLinkUID+[/ListAssociations">]+oFcgi:p_ANFAssociations+[</a>]
        l_cHtml += [</li>]
    
    l_cHtml += [</ul>]
    return l_cHtml

return l_cHtml

//=================================================================================================================
static function AssociationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID,par_cErrorText,par_iPk,par_hValues,par_cPackageLinkUID,par_cFromEntityLinkUID)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_ifk_Package  := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus   := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfPackages    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAllEntities := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_nNumberOfPackages

local l_nCounter
local l_nCounterC

local l_json_Entities
local l_hEntityNames := {=>}
local l_cInfo
local l_cObjectName

local l_iEndpoint_pk
local l_iEndpoint_Fk_Entity
local l_cEndpoint_Name
local l_cEndpoint_BoundLower
local l_cEndpoint_BoundUpper
local l_lEndpoint_IsContainment
local l_cEndpoint_Description

local l_iPreselected_Entity_Pk
local l_cPreselected_Entity_Name


oFcgi:TraceAdd("AssociationEditFormBuild")

with object l_oDB_ListOfPackages
    //Build the list of Packages
    :Table("2b19ee5b-91ec-4d24-9934-80ef27c3d11d","Package")
    :Column("Package.pk"         , "pk")
    :Column("Package.FullName"   , "Package_FullName")
    :Column("Package.FullPk"     , "Package_FullPk")
    :Column("Package.LinkUID"    , "Package_LinkUID")
    :Column("Package.TreeOrder1" , "Tag1")
    :Where("Package.fk_Model = ^" , par_iModelPk)
    :OrderBy("Tag1")
    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="AssociationKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFAssociation+[</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
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
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboPackagePk" id="ComboPackagePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Package,[ selected],[])+[></option>]
                    select ListOfPackages
                    scan all
                        if !empty(par_cPackageLinkUID)
                            l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->Package_LinkUID = par_cPackageLinkUID,[ selected],[])+[>]+alltrim(ListOfPackages->Package_FullName)+[</option>]
                        else
                            l_cHtml += [<option value="]+Trans(ListOfPackages->pk)+["]+iif(ListOfPackages->pk = l_ifk_Package,[ selected],[])+[>]+alltrim(ListOfPackages->Package_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Association Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ASSOCIATION,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

    SetSelect2Support()

    with object l_oDB_ListOfAllEntities
        :Table("8c4054d1-6f50-427e-aa41-2b53f8ebad2b","Entity")
        :Column("Entity.pk"                      , "pk")
        :Column("Package.FullName"               , "Package_FullName")
        :Column("Entity.Name"                    , "Entity_Name")
        :Column("Entity.LinkUID"                 , "Entity_LinkUID")
        :Column("COALESCE(Package.TreeOrder1,0)" , "tag1")           // _M_ Cast as integer
        :Column("Upper(Entity.Name)"             , "tag2")
        :Where("Entity.fk_Model = ^" , par_iModelPk)
        :join("left","Package","","Entity.fk_Package = Package.pk")
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfAllEntities")

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
        l_cInfo := el_StrReplace(l_cInfo,{;
                                        [\] => [\\] ,;
                                        ["] => [ ] ,;
                                        ['] => [ ] ;
                                     },,1)
        l_json_Entities += "{id:"+trans(ListOfAllEntities->pk)+",text:'"+l_cInfo+"'}"
        l_hEntityNames[ListOfAllEntities->pk] := l_cInfo   // Will be used to assist in setting up default <select> <option>
        if ListOfAllEntities->Entity_LinkUID = par_cFromEntityLinkUID
            l_iPreselected_Entity_Pk   := ListOfAllEntities->Pk
            l_cPreselected_Entity_Name := ListOfAllEntities->Entity_Name
        endif
    endscan
    l_json_Entities := "["+l_json_Entities+"]"

    //Call the jQuery code even before the for loop, since it will be used after html is loaded anyway.
    // oFcgi:p_cjQueryScript += [$(".SelectEntity").select2({placeholder: '',allowClear: true,data: ]+l_json_Entities+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]
    ActivatejQuerySelect2(".SelectEntity",l_json_Entities)

    l_cHtml += [<div>]
        // l_cHtml += [<table class="ms-0 table" style="width:auto;">]  //table-striped
        l_cHtml += [<table style="width:auto;">]  //table-striped

            for l_nCounter := 1 to hb_HGetDef(par_hValues,"NumberOfPossibleEndpoints",3)
                l_nCounterC := Trans(l_nCounter)

                l_iEndpoint_pk            := nvl(hb_HGetDef(par_hValues,"EndpointPk"+l_nCounterC,0),0)
                l_iEndpoint_Fk_Entity     := nvl(hb_HGetDef(par_hValues,"EndpointFk_Entity"+l_nCounterC,0),0)
                l_cEndpoint_Name          := nvl(hb_HGetDef(par_hValues,"EndpointName"+l_nCounterC,""),"")
                l_cEndpoint_BoundLower    := nvl(hb_HGetDef(par_hValues,"EndpointBoundLower"+l_nCounterC,""),"")
                l_cEndpoint_BoundUpper    := nvl(hb_HGetDef(par_hValues,"EndpointBoundUpper"+l_nCounterC,""),"")
                l_lEndpoint_IsContainment := nvl(hb_HGetDef(par_hValues,"EndpointIsContainment"+l_nCounterC,.f.),.f.)
                l_cEndpoint_Description   := nvl(hb_HGetDef(par_hValues,"EndpointDescription"+l_nCounterC,""),"")

                l_cHtml += [<tr class="bg-secondary">]
                // l_cHtml += [<tr class="table-dark">]
                    l_cHtml += [<td class="ps-2 text-white">]+oFcgi:p_ANFEntity
                        l_cObjectName := "TextEndpoint_pk"+l_nCounterC
                        l_cHtml += [<input type="hidden" name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="]+Trans(l_iEndpoint_pk)+[">]
                    l_cHtml += [</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Bound<br>Lower</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Bound<br>Upper</td>]
                    l_cHtml += [<td class="ps-2 text-white text-center">Is<br>Containment</td>]
                    l_cHtml += [<td class="ps-2 text-white">Name (of ]+oFcgi:p_ANFAssociation+[ to the ]+oFcgi:p_ANFEntity+[)</td>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="pb-5">]
                    // l_cHtml += [<td class="pe-2 pb-3">]+oFcgi:p_ANFEntity+[</td>]

                    //Entity
                    l_cHtml += [<td class="pt-2" valign="top">]
                    
                        l_cObjectName := "ComboEndpoint_Fk_Entity"+l_nCounterC
                        l_cHtml += [<select name="]+l_cObjectName+[" id="]+l_cObjectName+[" class="SelectEntity" style="width:600px">]
                        if l_iEndpoint_Fk_Entity != 0
                            //select2 will place the current selected option at the top of the list of options, overriding the initial order.
                            l_cHtml += [<option value="]+Trans(l_iEndpoint_Fk_Entity)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iEndpoint_Fk_Entity,"")+[</option>]
                        elseif !empty(par_cFromEntityLinkUID) .and. l_nCounter = 1
                            //we are coming from an entity so pereselct it as first end but only do this for the first Association End
                            l_cHtml += [<option value="]+Trans(l_iPreselected_Entity_Pk)+[" selected="selected">]+l_cPreselected_Entity_Name+[</option>]
                        else
                            oFcgi:p_cjQueryScript += [$("#]+l_cObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
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

                    //IsContainment
                    l_cHtml += [<td class="ps-2 pt-2" valign="top">]
                        l_cObjectName := "CheckIsContainment"+l_nCounterC
                        l_cHtml += [<div class="form-check form-switch">]
                            l_cHtml += [<input]+UPDATE_ONCHECKBOXINPUT_SAVEBUTTON+[name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="1"]+iif(l_lEndpoint_IsContainment," checked","")+[ class="form-check-input"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[>]
                        l_cHtml += [</div>]
                    l_cHtml += [</td>]

                    //Name
                    l_cObjectName := "TextName"+l_nCounterC
                    l_cHtml += [<td class="ps-2 pt-2"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="]+l_cObjectName+[" id="]+l_cObjectName+[" value="]+FcgiPrepFieldForValue(l_cEndpoint_Name)+[" maxlength="200" size="40"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-control"></td>]

                l_cHtml += [</tr>]


                l_cHtml += [<tr class="pb-5">]
                    //Description
                    l_cObjectName := "TextDescription"+l_nCounterC
                    l_cHtml += [<td colspan="5" class="pt-1 pb-3">Description <textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="]+l_cObjectName+[" id="]+l_cObjectName+[" rows="2" cols="40"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[ class="form-control">]+FcgiPrepFieldForValue(l_cEndpoint_Description)+[</textarea></td>]

                l_cHtml += [</tr>]

            enddo

        l_cHtml += [</table>]

        l_cHtml += [<input type="hidden" name="NumberOfPossibleEndpoints" value="]+l_nCounterC+[">]

    l_cHtml += [</div>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function AssociationEditFormOnSubmit(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID,par_cPackageLinkUID)

local l_cHtml := []

local l_cActionOnSubmit
local l_iAssociationPk
local l_iAssociationFk_Package
local l_cAssociationName
local l_nAssociationUseStatus
local l_cAssociationDescription
local l_oData
local l_cErrorMessage := ""

local l_cProjectValidEndpointBoundLowerValues
local l_cProjectValidEndpointBoundUpperValues

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
local l_lEndpoint_IsContainment
local l_cEndpoint_Description
local l_nEndpoint_NumberOfEndpoints
local l_nEndpoint_NumberOfEndpoints_OnFile
local l_lChanged := .f.

oFcgi:TraceAdd("AssociationEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iAssociationPk          := Val(oFcgi:GetInputValue("AssociationKey"))

l_iAssociationFk_Package  := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cAssociationName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nAssociationUseStatus   := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cAssociationDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        if empty(l_cAssociationName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("0a40d5d8-0ec9-462d-a863-7bc961a8dfca","Project")
                :Column("Project.ValidEndpointBoundLowerValues" , "Project_ValidEndpointBoundLowerValues")
                :Column("Project.ValidEndpointBoundUpperValues" , "Project_ValidEndpointBoundUpperValues")
                l_oData := :Get(par_iProjectPk)
                l_cProjectValidEndpointBoundLowerValues := nvl(l_oData:Project_ValidEndpointBoundLowerValues,"")
                l_cProjectValidEndpointBoundUpperValues := nvl(l_oData:Project_ValidEndpointBoundUpperValues,"")

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

    if empty(l_cErrorMessage) .and. (!empty(l_cProjectValidEndpointBoundLowerValues) .or. !empty(l_cProjectValidEndpointBoundUpperValues))
        for l_nCounter := 1 to Val(oFcgi:GetInputValue("NumberOfPossibleEndpoints"))
            l_nCounterC := Trans(l_nCounter)

            l_iEndpoint_fk_Entity   := Val(oFcgi:GetInputValue("ComboEndpoint_Fk_Entity"+l_nCounterC))
            if l_iEndpoint_fk_Entity > 0
                if !empty(l_cProjectValidEndpointBoundLowerValues)
                    l_cEndpoint_BoundLower  := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"+l_nCounterC))
                    if !(","+l_cEndpoint_BoundLower+"," $ ","+l_cProjectValidEndpointBoundLowerValues+",")
                        l_cErrorMessage := [Bound Lower must be in "]+l_cProjectValidEndpointBoundLowerValues+["]
                        exit
                    endif
                endif

                if !empty(l_cProjectValidEndpointBoundUpperValues)
                    l_cEndpoint_BoundUpper  := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"+l_nCounterC))
                    if !(","+l_cEndpoint_BoundUpper+"," $ ","+l_cProjectValidEndpointBoundUpperValues+",")
                        l_cErrorMessage := [Bound Upper must be in "]+l_cProjectValidEndpointBoundUpperValues+["]
                        exit
                    endif
                endif

            endif

        endfor
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
                :Column("Association.UseStatus"        ,"Association_UseStatus")
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

                if empty(l_iAssociationPk) .or. l_oData:Association_seStatus <> l_nAssociationUseStatus
                    l_lChanged := .t.
                    :Field("Association.UseStatus" ,l_nAssociationUseStatus)
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
                else
                    l_cErrorMessage := "Failed to add Association."
                endif
            else
                if l_lChanged
                    if !:Update(l_iAssociationPk)
                        l_cErrorMessage := "Failed to update Association."
                    endif
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
                :Column("Endpoint.pk"            , "pk")
                :Column("Endpoint.Fk_Entity"     , "Endpoint_Fk_Entity")
                :Column("Endpoint.Name"          , "Endpoint_Name")
                :Column("Endpoint.BoundLower"    , "Endpoint_BoundLower")
                :Column("Endpoint.BoundUpper"    , "Endpoint_BoundUpper")
                :Column("Endpoint.IsContainment" , "Endpoint_IsContainment")
                :Column("Endpoint.Description"   , "Endpoint_Description")
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

                    l_iEndpoint_pk            := Val(oFcgi:GetInputValue("TextEndpoint_pk"+l_nCounterC))
                    l_iEndpoint_fk_Entity     := Val(oFcgi:GetInputValue("ComboEndpoint_Fk_Entity"+l_nCounterC))
                    l_cEndpoint_Name          := SanitizeInput(oFcgi:GetInputValue("TextName"+l_nCounterC))
                    l_cEndpoint_BoundLower    := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"+l_nCounterC))
                    l_cEndpoint_BoundUpper    := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"+l_nCounterC))
                    l_lEndpoint_IsContainment := (oFcgi:GetInputValue("CheckIsContainment"+l_nCounterC) == "1")
                    l_cEndpoint_Description   := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription"+l_nCounterC)))

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
                                :Field("Endpoint.IsContainment"  , l_lEndpoint_IsContainment)
                                :Field("Endpoint.Description"    , iif(empty(l_cEndpoint_Description),NULL,l_cEndpoint_Description))
                                :Add()
                            endwith
                        endif

                    else
                        if l_iEndpoint_fk_Entity > 0
                            l_nEndpoint_NumberOfEndpoints += 1
                            // Check in ListOfEndpoints if should record update.

                            if !( el_seek(l_iEndpoint_pk,"ListOfEndpoints","pk") ;
                                   .and. ListOfEndpoints->Endpoint_Fk_Entity           == l_iEndpoint_fk_Entity ;
                                   .and. nvl(ListOfEndpoints->Endpoint_Name,"")        == nvl(l_cEndpoint_Name,"") ;
                                   .and. nvl(ListOfEndpoints->Endpoint_BoundLower,"")  == nvl(l_cEndpoint_BoundLower,"") ;
                                   .and. nvl(ListOfEndpoints->Endpoint_BoundUpper,"")  == nvl(l_cEndpoint_BoundUpper,"") ;
                                   .and. ListOfEndpoints->Endpoint_IsContainment       == l_lEndpoint_IsContainment ;
                                   .and. nvl(ListOfEndpoints->Endpoint_Description,"") == nvl(l_cEndpoint_Description,"") )

                                with object l_oDB2
                                    :Table("6b749ef9-b9e4-4d29-ba51-e6c7ccd5754e","Endpoint")
                                    :Field("Endpoint.fk_Entity"     , l_iEndpoint_fk_Entity)
                                    :Field("Endpoint.Name"          , iif(empty(l_cEndpoint_Name)       ,NULL,l_cEndpoint_Name))
                                    :Field("Endpoint.BoundLower"    , iif(empty(l_cEndpoint_BoundLower) ,NULL,l_cEndpoint_BoundLower))
                                    :Field("Endpoint.BoundUpper"    , iif(empty(l_cEndpoint_BoundUpper) ,NULL,l_cEndpoint_BoundUpper))
                                    :Field("Endpoint.IsContainment" , l_lEndpoint_IsContainment)
                                    :Field("Endpoint.Description"   , iif(empty(l_cEndpoint_Description),NULL,l_cEndpoint_Description))
                                    :Update(l_iEndpoint_pk)

                                endwith
                            endif

                        else
                            :Delete("9f70d7d5-7464-4fb9-87d3-94af7b0b65ba","Endpoint",l_iEndpoint_pk)
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

case l_cActionOnSubmit == "Done"
    l_iAssociationPk := 0

case l_cActionOnSubmit == "Delete"   // Association
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveEntityAssociationDelete(par_iProjectPk)
            l_cErrorMessage := CascadeDeleteAssociation(par_iProjectPk,l_iAssociationPk)
            if empty(l_cErrorMessage)
                l_iAssociationPk := 0
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
                        l_iAssociationPk := 0
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
case !empty(l_cErrorMessage)
    l_hValues["fk_package"]  := l_iAssociationFk_Package
    l_hValues["Name"]        := l_cAssociationName
    l_hValues["UseStatus"]   := l_nAssociationUseStatus
    l_hValues["Description"] := l_cAssociationDescription
    CustomFieldsFormToHash(par_iProjectPk,USEDON_ASSOCIATION,@l_hValues)

    l_hValues["NumberOfPossibleEndpoints"] := Val(oFcgi:GetInputValue("NumberOfPossibleEndpoints"))
    for l_nCounter := 1 to l_hValues["NumberOfPossibleEndpoints"]
        l_nCounterC := Trans(l_nCounter)

        l_hValues["EndpointPk"+l_nCounterC]            := Val(oFcgi:GetInputValue("TextEndpoint_pk"+l_nCounterC))
        l_hValues["EndpointFk_Entity"+l_nCounterC]     := Val(oFcgi:GetInputValue("ComboEndpoint_Fk_Entity"+l_nCounterC))
        l_hValues["EndpointName"+l_nCounterC]          := SanitizeInput(oFcgi:GetInputValue("TextName"+l_nCounterC))
        l_hValues["EndpointBoundLower"+l_nCounterC]    := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"+l_nCounterC))
        l_hValues["EndpointBoundUpper"+l_nCounterC]    := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"+l_nCounterC))
        l_hValues["EndpointIsContainment"+l_nCounterC] := (oFcgi:GetInputValue("CheckIsContainment"+l_nCounterC) == "1")
        l_hValues["EndpointDescription"+l_nCounterC]   := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription"+l_nCounterC)))

    endfor

    l_cHtml += AssociationEditFormBuild(par_iProjectPk,par_iModelPk,par_cModelLinkUID,par_cAssociationLinkUID,l_cErrorMessage,l_iAssociationPk,l_hValues)

case empty(l_iAssociationPk)
    if !empty(par_cPackageLinkUID)
        oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditPackage/"+par_cPackageLinkUID+"/ListAssociations")
    else
        oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")
    endif

otherwise
    with object l_oDB1
        :Table("458ca82d-5009-496e-9f3f-d904def7be9c","Association")
        :Column("Association.LinkUID" , "Association_LinkUID")
        l_oData := :Get(l_iAssociationPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditAssociation/"+alltrim(l_oData:Association_LinkUID)+"/")
        else
            if !empty(par_cPackageLinkUID)
                oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditPackage/"+par_cPackageLinkUID+"/ListAssociations")
            else
                oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/ListAssociations/"+par_cModelLinkUID+"/")
            endif
        endif
    endwith

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
local l_oDB_ListOfAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomField      := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfAttributes
local l_nNumberOfAttributesInSearch
local l_nNumberOfCustomFieldValues  := 0

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
    :Column("ModelEnumeration.Name"    ,"Enumeration_Name")
    :Column("Attribute.LinkUID"        ,"Attribute_LinkUID")
    :Column("Attribute.FullName"       ,"Attribute_FullName")
    :Column("Attribute.TreeOrder1"     ,"tag1")
    :Column("Attribute.IsObject"       ,"Attribute_IsObject")
    :Column("Attribute.BoundLower"     ,"Attribute_BoundLower")
    :Column("Attribute.BoundUpper"     ,"Attribute_BoundUpper")
    :Column("Attribute.Description"    ,"Attribute_Description")
    :Column("Attribute.UseStatus"      ,"Attribute_UseStatus")
    
    :Join("left","DataType","","Attribute.fk_DataType = DataType.pk")
    :Join("left","ModelEnumeration","","Attribute.fk_ModelEnumeration = ModelEnumeration.pk")
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
    :OrderBy("tag1")
    :SQL("ListOfAttributes")
    l_nNumberOfAttributesInSearch := :Tally
    // SendToClipboard(:LastSQL())
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
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

else
    l_cHtml += [<nav class="navbar navbar-light bg-light">]
        l_cHtml += [<div class="input-group">]
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/NewAttribute/]+par_cEntityLinkUID+[/]+[">New ]+oFcgi:p_ANFAttribute+[</a>]
            endif
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/OrderAttributes/]+par_cEntityLinkUID+[/]+[">Order ]+oFcgi:p_ANFAttributes+[</a>]
            endif
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

    l_cHtml += [<div class="row justify-content-left">]
        l_cHtml += [<div class="col">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-center text-white" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"6","7")+[">]
                    if l_nNumberOfAttributes == l_nNumberOfAttributesInSearch
                        l_cHtml += oFcgi:p_ANFAttributes+[ (]+Trans(l_nNumberOfAttributes)+[) for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityInfo+["]
                    else
                        l_cHtml += oFcgi:p_ANFAttributes+[ (]+Trans(l_nNumberOfAttributesInSearch)+[ out of ]+Trans(l_nNumberOfAttributes)+[) for ]+oFcgi:p_ANFEntity+[ "]+par_cEntityInfo+["]
                    endif
                l_cHtml += [</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Full Name</th>]
                l_cHtml += [<th class="text-white">]+oFcgi:p_ANFDataType+[</th>]
                l_cHtml += [<th class="text-white text-center">Bound<br>Lower</th>]
                l_cHtml += [<th class="text-white text-center">Bound<br>Upper</th>]
                l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [<th class="text-white text-center">Use<br>Status</th>]
                if l_nNumberOfCustomFieldValues > 0
                    l_cHtml += [<th class="text-white text-center">Other</th>]
                endif
            l_cHtml += [</tr>]

            select ListOfAttributes
            scan all
                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfAttributes->Attribute_UseStatus)+[>]

                    // Full Name
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditAttribute/]+ListOfAttributes->Attribute_LinkUID+[/">]+ListOfAttributes->Attribute_FullName+[</a>]
                    l_cHtml += [</td>]

                    // Data Type
                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        if !empty(ListOfAttributes->DataType_FullName)
                            l_cHtml += [<i class="bi bi-code"></i>&nbsp;]+ListOfAttributes->DataType_FullName
                        elseif !empty(ListOfAttributes->Enumeration_Name)
                            l_cHtml += [<i class="bi bi-card-list"></i>&nbsp;]+ListOfAttributes->Enumeration_Name
                        elseif ListOfAttributes->Attribute_IsObject
                            l_cHtml += [<i class="bi bi-code-square"></i>&nbsp;Object]
                        endif
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

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfAttributes->Attribute_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfAttributes->Attribute_UseStatus,USESTATUS_UNKNOWN)]
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

    l_cURL := oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListAttributes/"+par_cEntityLinkUID+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += AttributeListFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityName,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function AttributeEditFormBuild(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText      := hb_DefaultValue(par_cErrorText,"")
local l_cName           := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus      := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_ifk_Attribute   := hb_HGetDef(par_hValues,"fk_Attribute",0)
local l_ifk_DataType    := hb_HGetDef(par_hValues,"fk_DataType",0)
local l_ifk_Enumeration := hb_HGetDef(par_hValues,"fk_Enumeration",0)
local l_lIsObject       := hb_HGetDef(par_hValues,"IsObject",.f.)
local l_cBoundLower     := nvl(hb_HGetDef(par_hValues,"BoundLower",""),"")
local l_cBoundUpper     := nvl(hb_HGetDef(par_hValues,"BoundUpper",""),"")
local l_cDescription    := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfOtherAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfDataType        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEnumeration     := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_json_DataTypes
local l_cInfo
local l_hDataTypes := {=>}
local l_nNumberOfOtherAttributes

oFcgi:TraceAdd("AttributeEditFormBuild")

FixNonNormalizeFieldsInAttribute(par_iEntityPk)    // Just in case data got corrupted.

with object l_oDB_ListOfOtherAttributes
    //Build the list of Other Attributes
    :Table("73ed32bb-8ca7-4df9-8464-8a8113e995a2","Attribute")
    :Column("Attribute.pk"         , "pk")
    :Column("Attribute.FullName"   , "Attribute_FullName")
    :Column("Attribute.FullPk"     , "Attribute_FullPk")
    :Column("Attribute.TreeOrder1" , "Tag1")
    :Where("Attribute.fk_Entity = ^" , par_iEntityPk)
    if !empty(par_iPk)
        :Where("Attribute.pk <> ^" , par_iPk)
    endif
    :Where("Attribute.isObject = ^", .t.) //only show non-primitive typed Attributes
    :OrderBy("Tag1")
    :SQL("ListOfOtherAttributes")
    l_nNumberOfOtherAttributes := :Tally
endwith

with object l_oDB_ListOfDataType
    :Table("b773e79e-d29f-4545-8e1f-fd92a2b6f195","DataType")
    :Column("DataType.pk"         , "pk")
    :Column("DataType.FullName"   , "DataType_FullName")
    :Column("DataType.TreeOrder1" , "tag1")
    :OrderBy("tag1")
    :Where("DataType.fk_Model = ^" , par_iModelPk)
    :Where("DataType.TreeLevel = 1")
    :SQL("ListOfDataTypes")
endwith

with object l_oDB_ListOfEnumeration
    :Table("4C3C4545-EAC3-4558-ADA6-91BCA0FD50D6","ModelEnumeration")
    :Column("ModelEnumeration.pk"         , "pk")
    :Column("ModelEnumeration.Name"   , "Enumeration_Name")
    :Column("ModelEnumeration.Name" , "tag1")
    :OrderBy("tag1")
    :Where("ModelEnumeration.fk_Model = ^" , par_iModelPk)
    :SQL("ListOfEnumerations")
endwith

SetSelect2Support()

l_json_DataTypes := [{id:'OBJECT',text:'Object'}]
select ListOfDataTypes
scan all
    if !empty(l_json_DataTypes)
        l_json_DataTypes += [,]
    endif
    l_cInfo := el_StrReplace(ListOfDataTypes->DataType_FullName,{;
                                    [\] => [\\] ,;
                                    ["] => [ ] ,;
                                    ['] => [ ] ;
                                    },,1)
    l_json_DataTypes += "{id:'D"+trans(ListOfDataTypes->pk)+"',text:'"+l_cInfo+"'}"
    l_hDataTypes["D"+trans(ListOfDataTypes->pk)] := l_cInfo   // Will be used to assist in setting up default <select> <option>
endscan
select ListOfEnumerations
scan all
    if !empty(l_json_DataTypes)
        l_json_DataTypes += [,]
    endif
    l_cInfo := el_StrReplace(ListOfEnumerations->Enumeration_Name,{;
                                    [\] => [\\] ,;
                                    ["] => [ ] ,;
                                    ['] => [ ] ;
                                    },,1)
    l_json_DataTypes += "{id:'E"+trans(ListOfEnumerations->pk)+"',text:'"+l_cInfo+"'}"
    l_hDataTypes["E"+trans(ListOfEnumerations->pk)] := l_cInfo 
endscan
l_json_DataTypes := "["+l_json_DataTypes+"]"



//Call the jQuery code even before the for loop, since it will be used after html is loaded anyway.
oFcgi:p_cjQueryScript += [function iformat(state) {]
oFcgi:p_cjQueryScript += [    if(!state.id) { return state.text; }]
oFcgi:p_cjQueryScript += [    var icon;]
oFcgi:p_cjQueryScript += [    if(state.id.startsWith('D')) { icon = 'bi-code'; }]
oFcgi:p_cjQueryScript += [    else if(state.id.startsWith('E')) { icon = 'bi-card-list'; }]
oFcgi:p_cjQueryScript += [    else if(state.id == 'OBJECT') { icon = 'bi-code-square'; }]
oFcgi:p_cjQueryScript += [    return $('<i class="bi '+icon+'"></i> ' + state.text + '</span>');]
oFcgi:p_cjQueryScript += [}]

// oFcgi:p_cjQueryScript += [$(".SelectDataType").select2({placeholder: 'none',allowClear: true, allowHtml: true, templateResult: iformat, data: ]+l_json_DataTypes+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]
ActivatejQuerySelect2(".SelectDataType",l_json_DataTypes)

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="AttributeKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]

        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ ]+oFcgi:p_ANFAttribute+[ in ]+oFcgi:p_ANFEntity+[ "]+par_cEntityName+["</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfOtherAttributes > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Parent ]+oFcgi:p_ANFAttribute+[</td>]
                l_cHtml += [<td class="pb-3">]
                    l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboAttributePk" id="ComboAttributePk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                    l_cHtml += [<option value="0"]+iif(0 = l_ifk_Attribute,[ selected],[])+[></option>]
                    select ListOfOtherAttributes
                    scan all
                        if !("*"+Trans(par_iPk)+"*" $ "*"+ListOfOtherAttributes->Attribute_FullPk+"*")
                            l_cHtml += [<option value="]+Trans(ListOfOtherAttributes->pk)+["]+iif(ListOfOtherAttributes->pk = l_ifk_Attribute,[ selected],[])+[>]+alltrim(ListOfOtherAttributes->Attribute_FullName)+[</option>]
                        endif
                    endscan
                    l_cHtml += [</select>]
                l_cHtml += [</td>]
            l_cHtml += [</tr>]
        endif

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus" class="form-select">]
                    l_cHtml += [<option value="1"]+iif(l_nUseStatus==1,[ selected],[])+[>Unknown</option>]
                    l_cHtml += [<option value="2"]+iif(l_nUseStatus==2,[ selected],[])+[>Proposed</option>]
                    l_cHtml += [<option value="3"]+iif(l_nUseStatus==3,[ selected],[])+[>Under Development</option>]
                    l_cHtml += [<option value="4"]+iif(l_nUseStatus==4,[ selected],[])+[>Active</option>]
                    l_cHtml += [<option value="5"]+iif(l_nUseStatus==5,[ selected],[])+[>To Be Discontinued</option>]
                    l_cHtml += [<option value="6"]+iif(l_nUseStatus==6,[ selected],[])+[>Discontinued</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Data Type</td>]
            l_cHtml += [<td class="pb-3">]

                l_cHtml += [<select name="ComboFk_DataType" id="ComboFk_DataType" class="SelectDataType" style="width:700px"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[>]
                //if no datatype and no enumeration are selected it means its an Object DataType
                if l_lIsObject
                    l_cHtml += [<option value="OBJECT" selected="selected">Object</option>]
                elseif l_ifk_DataType != 0
                    l_cHtml += [<option value="D]+Trans(l_ifk_DataType)+[" selected="selected">]+hb_HGetDef(l_hDataTypes,"D"+Trans(l_ifk_DataType),"")+[</option>]
                elseif l_ifk_Enumeration != 0
                    l_cHtml += [<option value="E]+Trans(l_ifk_Enumeration)+[" selected="selected">]+hb_HGetDef(l_hDataTypes,"E"+Trans(l_ifk_Enumeration),"")+[</option>]
                endif
                    
                
                l_cHtml += [</select>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        //Bound Lower
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Bound Lower</td>]
            l_cHtml += [<td class="pb-3"><input type="text" value="]+FcgiPrepFieldForValue(l_cBoundLower)+[" id="TextBoundLower" name="TextBoundLower" maxlength="4" size="2"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        //Bound Upper
        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Bound Upper</td>]
            l_cHtml += [<td class="pb-3"><input type="text" value="]+FcgiPrepFieldForValue(l_cBoundUpper)+[" id="TextBoundUpper" name="TextBoundUpper" maxlength="4" size="2"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3" valign="top">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

        l_cHtml += CustomFieldsBuild(par_iProjectPk,USEDON_ATTRIBUTE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function AttributeEditFormOnSubmit(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iAttributePk
local l_iAttributeFk_Attribute
local l_cAttributeName
local l_nAttributeUseStatus
local l_cAttributeFk_DataType
local l_iAttributeFk_DataType := 0
local l_iAttributeFk_Enumeration := 0
local l_cAttributeBoundLower
local l_cAttributeBoundUpper
local l_lAttributeIsObject := .f.
local l_cAttributeDescription
local l_cAttributeLinkUID
local l_iAttributeTreeOrder1

local l_hValues := {=>}

local l_aSQLResult   := {}

local l_cErrorMessage := ""
local l_oDB1
local l_oData

oFcgi:TraceAdd("AttributeEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iAttributePk           := Val(oFcgi:GetInputValue("AttributeKey"))
l_iAttributeFk_Attribute := Val(oFcgi:GetInputValue("ComboAttributePk"))
l_cAttributeName         := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nAttributeUseStatus    := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cAttributeFk_DataType  := oFcgi:GetInputValue("ComboFk_DataType")
if left(l_cAttributeFk_DataType,1) == "D"
    l_iAttributeFk_DataType  := val(substr(l_cAttributeFk_DataType,2))
elseif left(l_cAttributeFk_DataType,1) == "E"
    l_iAttributeFk_Enumeration  := val(substr(l_cAttributeFk_DataType,2))
elseif l_cAttributeFk_DataType == "OBJECT"
    l_lAttributeIsObject := .t.
endif
l_cAttributeBoundLower   := SanitizeInput(oFcgi:GetInputValue("TextBoundLower"))
l_cAttributeBoundUpper   := SanitizeInput(oFcgi:GetInputValue("TextBoundUpper"))
l_cAttributeDescription  := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    if oFcgi:p_nAccessLevelML >= 5
        do case
        case empty(l_cAttributeName)
            l_cErrorMessage := "Missing Name"

        case empty(l_cAttributeFk_DataType)
            l_cErrorMessage := "Missing Data Type"

        otherwise
            with object l_oDB1
                :Table("da91571c-c2c1-42aa-b947-553006648be0","Attribute")
                :Column("Attribute.pk","pk")
                :Where([Attribute.fk_Entity = ^],par_iEntityPk)
                :Where([lower(replace(Attribute.Name,' ','')) = ^],lower(StrTran(l_cAttributeName," ","")))
                :Where("Attribute.fk_Attribute = ^",l_iAttributeFk_Attribute)
                if l_iAttributePk > 0
                    :Where([Attribute.pk != ^],l_iAttributePk)
                endif
                :SQL()
            endwith
            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

            if l_iAttributePk <> 0
                with object l_oDB1
                    :Table("94899BCE-16AA-4166-A670-FD4CDBD9A18C","Attribute")
                    :Where("Attribute.fk_Attribute = ^",l_iAttributePk)
                    :SQL()
                    if :Tally != 0 .and. !l_lAttributeIsObject
                        l_cErrorMessage := oFcgi:p_ANFAttribute+[ with nested ]+oFcgi:p_ANFAttributes+[ can only have Object as type!]
                    endif
                endwith
            endif

        endcase
    endif

    if empty(l_cErrorMessage)
        //If adding a Attribute, find out what the last order is. When dealing with entries with a parent pointer, it is going to be fixed later by FixNonNormalizeFieldsInAttribute(par_iEntityPk)
        l_iAttributeTreeOrder1 := 1
        if empty(l_iAttributePk)
            with object l_oDB1
                :Table("42e1af2e-547c-4012-9407-23854801859e","Attribute")
                :Column("Attribute.TreeOrder1","Attribute_TreeOrder1")
                :Where([Attribute.fk_Entity = ^],par_iEntityPk)
                :OrderBy("Attribute_TreeOrder1","Desc")
                :Limit(1)
                :SQL(@l_aSQLResult)
            endwith

            if l_oDB1:Tally > 0
                l_iAttributeTreeOrder1 := l_aSQLResult[1,1] + 1
            endif
        endif

        //Save the Attribute
        with object l_oDB1
            :Table("f1109e34-247d-49e8-9a7a-7ffd32e1a914","Attribute")
            if oFcgi:p_nAccessLevelML >= 5
                :Field("Attribute.fk_Attribute",l_iAttributeFk_Attribute)
                :Field("Attribute.Name"        , l_cAttributeName)
                :Field("Attribute.UseStatus"   ,l_nAttributeUseStatus)
                if l_iAttributeFk_DataType != 0
                    :Field("Attribute.fk_DataType" , l_iAttributeFk_DataType)
                    :Field("Attribute.fk_ModelEnumeration" , 0)
                elseif l_iAttributeFk_Enumeration != 0
                    :Field("Attribute.fk_ModelEnumeration" , l_iAttributeFk_Enumeration)
                    :Field("Attribute.fk_DataType" , 0)
                elseif l_lAttributeIsObject
                    :Field("Attribute.isObject" , .t.)
                    :Field("Attribute.fk_DataType" , 0)
                    :Field("Attribute.fk_ModelEnumeration" , 0)
                endif
                :Field("Attribute.BoundLower"  , iif(empty(l_cAttributeBoundLower),NULL,l_cAttributeBoundLower))
                :Field("Attribute.BoundUpper"  , iif(empty(l_cAttributeBoundUpper),NULL,l_cAttributeBoundUpper))
            endif
            :Field("Attribute.Description" , iif(empty(l_cAttributeDescription),NULL,l_cAttributeDescription))
        
            if empty(l_iAttributePk)
                :Field("Attribute.fk_Entity"  , par_iEntityPk)
                :Field("Attribute.TreeOrder1" , l_iAttributeTreeOrder1)
                l_cAttributeLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                :Field("Attribute.LinkUID"   , l_cAttributeLinkUID)
                if :Add()
                    l_iAttributePk := :Key()
                    FixNonNormalizeFieldsInAttribute(par_iEntityPk)
                else
                    l_cErrorMessage := [Failed to add ]+oFcgi:p_ANFAttribute+[.]
                endif
            else
                if :Update(l_iAttributePk)
                    FixNonNormalizeFieldsInAttribute(par_iEntityPk)
                else
                    l_cErrorMessage := [Failed to update ]+oFcgi:p_ANFAttribute+[.]
                endif
            endif

            if empty(l_cErrorMessage) .and. oFcgi:p_nAccessLevelML >= 5
                CustomFieldsSave(par_iProjectPk,USEDON_ATTRIBUTE,l_iAttributePk)
            endif
        endwith

    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iAttributePk := 0

case l_cActionOnSubmit == "Delete"   // Attribute
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("409521e2-0e58-48b4-ab4a-242b7a8287a7","Attribute")
            :Where("Attribute.fk_Attribute = ^",l_iAttributePk)
            :SQL()
            if :Tally == 0
                CustomFieldsDelete(par_iProjectPk,USEDON_ATTRIBUTE,l_iAttributePk)
                :Delete("f47695cf-ff12-4c3f-8e12-3b4a17bc306b","Attribute",l_iAttributePk)
                FixNonNormalizeFieldsInAttribute(par_iEntityPk)
                l_iAttributePk := 0
            else
                l_cErrorMessage := [Related ]+oFcgi:p_ANFAttribute+[ record on file.]
            endif
        endwith
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["fk_Attribute"]    := l_iAttributeFk_Attribute
    l_hValues["fk_DataType"]     := l_iAttributeFk_DataType
    l_hValues["fk_Enumeration"]  := l_iAttributeFk_Enumeration
    l_hValues["IsObject"]        := l_lAttributeIsObject
    l_hValues["Name"]            := l_cAttributeName
    l_hValues["UseStatus"]       := l_nAttributeUseStatus
    l_hValues["BoundLower"]      := l_cAttributeBoundLower
    l_hValues["BoundUpper"]      := l_cAttributeBoundUpper
    l_hValues["Description"]     := l_cAttributeDescription

    CustomFieldsFormToHash(par_iProjectPk,USEDON_ATTRIBUTE,@l_hValues)

    l_cHtml += AttributeEditFormBuild(par_iProjectPk,par_iEntityPk,par_cEntityName,par_cEntityLinkUID,par_iModelPk,par_cModelLinkUID,l_cErrorMessage,l_iAttributePk,l_hValues)

case empty(l_iAttributePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListAttributes")

otherwise
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("b0aab7ef-b7b9-45a2-8cf7-dcc2447f2091","Attribute")
        :Column("Attribute.LinkUID" , "Attribute_LinkUID")
        l_oData := :Get(l_iAttributePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditAttribute/"+alltrim(l_oData:Attribute_LinkUID)+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListAttributes")
        endif
    endwith

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function AttributeOrderFormBuild(par_iEntityPk,par_cEntityLinkUID,par_cEntityName)
local l_cHtml := []
local l_oDB_ListOfAttributes
local l_cSitePath := oFcgi:p_cSitePath

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
    :Column("Attribute.FullName"       ,"Attribute_FullName")
    :Column("Attribute.TreeOrder1"     ,"Attribute_TreeOrder1")

    :Where("Attribute.fk_Entity = ^",par_iEntityPk)
    :OrderBy("Attribute_TreeOrder1")
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
                l_cHtml += GetButtonOnOrderListFormSave()
            endif
            l_cHtml += GetButtonCancelAndRedirect(l_cSitePath+[Modeling/EditEntity/]+par_cEntityLinkUID+[/ListAttributes])
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center">]
        l_cHtml += [<div class="col">]

        l_cHtml += [<ul id="sortable">]
        scan all
            l_cHtml += [<li class="ui-state-default" id="EnumList_]+trans(ListOfAttributes->pk)+["><span class="bi bi-arrow-down-up"></span><span> ]+strtran(ListOfAttributes->Attribute_FullName," ","&nbsp;")+[</span></li>]
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
l_cAttributePkOrder  := SanitizeInput(oFcgi:GetInputValue("AttributeOrder"))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 5
        l_aOrderedPks := hb_ATokens(Strtran(substr(l_cAttributePkOrder,6),"&",""),"sort=")     // The Substr(..,6) is used to skip the first "sort="

        l_oDB_ListOfAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfAttributes
            :Table("b6be9d37-f4c8-4e69-8963-1ce395d06039","Attribute")
            :Column("Attribute.pk","pk")
            :Column("Attribute.TreeOrder1","TreeOrder1")
            :Where([Attribute.fk_Entity = ^],l_iEntityPk)
            :SQL("ListOfAttribute")
    
            with object :p_oCursor
                :Index("pk","pk")
                :CreateIndexes()
                :SetOrder("pk")
            endwith
    
        endwith

        for l_Counter := 1 to len(l_aOrderedPks)
            if el_seek(val(l_aOrderedPks[l_Counter]),"ListOfAttribute","pk") .and. ListOfAttribute->TreeOrder1 <> l_Counter
                with object l_oDB_ListOfAttributes
                    :Table("41e21aee-a559-4a2a-ab9b-968e41424be9","Attribute")
                    :Field("Attribute.TreeOrder1",l_Counter)
                    :Update(val(l_aOrderedPks[l_Counter]))
                endwith
            endif
        endfor
    endif

    FixNonNormalizeFieldsInAttribute(l_iEntityPk)

    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListAttributes")

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function LinkedEntityListFormBuild(par_iEntityPk,par_cEntityLinkUID)
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfLinkedEntities
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("LinkedEntityListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("B9DC8B16-0CF7-4B9B-B17D-9B69CAC8779C","LinkedEntity")
    :Column("LinkedEntity.pk"                    ,"pk")
    :Column("LinkedEntity.LinkUID"               ,"LinkedEntity_LinkUID")
    :Column("LinkedEntity.Description"           ,"LinkedEntity_Description")
    :Column("LinkedEntity.fk_Entity1"            ,"LinkedEntity_fk_Entity1")
    :Column("LinkedEntity.fk_Entity2"            ,"LinkedEntity_fk_Entity2")
    :Column("Entity1.Name"                       ,"Entity1_Name")
    :Column("Entity2.Name"                       ,"Entity2_Name")
    :Column("Entity1.LinkUID"                    ,"Entity1_LinkUID")
    :Column("Entity2.LinkUID"                    ,"Entity2_LinkUID")
    :Column("Model1.Name"                        ,"Model1_Name")
    :Column("Model2.Name"                        ,"Model2_Name")
    :Column("Model1.LinkUID"                     ,"Model1_LinkUID")
    :Column("Model2.LinkUID"                     ,"Model2_LinkUID")
    :Join("inner","Entity"       ,"Entity1"      ,"LinkedEntity.fk_Entity1 = Entity1.pk")
    :Join("inner","Entity"       ,"Entity2"      ,"LinkedEntity.fk_Entity2 = Entity2.pk")
    :Join("inner","Model"        ,"Model1"       ,"Entity1.fk_Model = Model1.pk")
    :Join("inner","Model"        ,"Model2"       ,"Entity2.fk_Model = Model2.pk")
    :Where("LinkedEntity.fk_Entity1 = ^ OR LinkedEntity.fk_Entity2 = ^", par_iEntityPk, par_iEntityPk)
// altd()
    :SQL("ListOfLinkedEntities")
    l_nNumberOfLinkedEntities := :Tally
endwith

//l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfLinkedEntities)
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand ms-3">No ]+oFcgi:p_ANFLinkedEntities+[ linked.</span>]
                if oFcgi:p_nAccessLevelML >= 5
                    l_cHtml += [<a class="btn btn-primary rounded ms_0" href="]+l_cSitePath+[Modeling/NewLinkedEntity/]+par_cEntityLinkUID+[/]+[">New ]+oFcgi:p_ANFLinkedEntity+[</a>]
                endif
            l_cHtml += [</div>]
        l_cHtml += [</nav>]

    else
        l_cHtml += [<nav class="navbar navbar-light bg-light">]
            l_cHtml += [<div class="input-group">]
                if oFcgi:p_nAccessLevelML >= 5
                    l_cHtml += [<a class="btn btn-primary rounded ms-3" href="]+l_cSitePath+[Modeling/NewLinkedEntity/]+par_cEntityLinkUID+[/]+[">New ]+oFcgi:p_ANFLinkedEntity+[</a>]
                endif
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white text-center" colspan="5">]+oFcgi:p_ANFLinkedEntities+[</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white" ></th>]
                    l_cHtml += [<th class="text-white" >From/To</th>]
                    l_cHtml += [<th class="text-white" >]+oFcgi:p_ANFModel+[</th>]
                    l_cHtml += [<th class="text-white" >]+oFcgi:p_ANFEntity+[</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                l_cHtml += [</tr>]

                select ListOfLinkedEntities
                scan all
                    if ListOfLinkedEntities->LinkedEntity_fk_Entity1 = par_iEntityPk
                        l_cHtml += [<tr>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditLinkedEntity/]+alltrim(ListOfLinkedEntities->LinkedEntity_LinkUID)+[/">Edit ]+oFcgi:p_ANFLinkedEntity+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [To]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+alltrim(ListOfLinkedEntities->Model2_LinkUID)+[/">]+alltrim(ListOfLinkedEntities->Model2_Name)+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEntity/]+alltrim(ListOfLinkedEntities->Entity2_LinkUID)+[/">]+alltrim(ListOfLinkedEntities->Entity2_Name)+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += TextToHtml(hb_DefaultValue(ListOfLinkedEntities->LinkedEntity_Description,""))
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endif 
                endscan

                select ListOfLinkedEntities
                scan all
                    if ListOfLinkedEntities->LinkedEntity_fk_Entity2 = par_iEntityPk
                        l_cHtml += [<tr>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditLinkedEntity/]+alltrim(ListOfLinkedEntities->LinkedEntity_LinkUID)+[/">Edit ]+oFcgi:p_ANFLinkedEntity+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [From]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListEntities/]+alltrim(ListOfLinkedEntities->Model1_LinkUID)+[/">]+alltrim(ListOfLinkedEntities->Model1_Name)+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += [<a href="]+l_cSitePath+[Modeling/EditEntity/]+alltrim(ListOfLinkedEntities->Entity1_LinkUID)+[/">]+alltrim(ListOfLinkedEntities->Entity1_Name)+[</a>]
                            l_cHtml += [</td>]

                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += TextToHtml(hb_DefaultValue(ListOfLinkedEntities->LinkedEntity_Description,""))
                            l_cHtml += [</td>]

                        l_cHtml += [</tr>]
                    endif 
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

//l_cHtml += [</div>]

return l_cHtml
//=================================================================================================================
static function LinkedEntityEditFormBuild(par_iModelPk,par_iLinkedEntityPk,par_cLinkedEntityLinkUID,par_cEntityLinkUID,par_cErrorText,par_hValues)

// l_oDataHeader:Model_Pk
// l_oDataHeader:LinkedEntity_pk
// l_oDataHeader:LinkedEntity_LinkUID
// l_oDataHeader:Entity_LinkUID
// ""
// {=>}

// Parameters Info
//  Model.pk
//  LinkedEntity.pk        (The many to many table)
//  LinkedEntity.LinkUID   (Of the many to many table)
//  Entity.LinkUID         (From or To we are at)
//  Last Error Message
//  Values in the Many to Many table (LinkedEntity), like the description and the other entity
// PLEASE NOTE. The related Entity could belong to a linked Model. And it could be in either fk_Entity1 or fk_Entity2.

local l_cHtml := ""
local l_cErrorText     := hb_DefaultValue(par_cErrorText,"")
local l_cSitePath := oFcgi:p_cSitePath

local l_ScriptFolder

local l_iLinkedEntityFromEntityPk := nvl(hb_HGetDef(par_hValues,"LinkedEntityFomPk",0),0)
local l_iLinkedEntityToEntityPk   := nvl(hb_HGetDef(par_hValues,"LinkedEntityToPk",0),0)
local l_cDescription              := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfEntities := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_nNumberOfModels
local l_json_Entities := []
local l_hEntityNames := {=>}
local l_iPreselected_Entity_Pk
local l_cPreselected_Entity_Name
local l_cInfo

oFcgi:TraceAdd("LinkedEntityEditFormBuild")

with object l_oDB_ListOfEntities
    :Table("B436F5AB-75A0-47B2-8AEB-5C3C63C61394","Entity")
    :Column("Entity.pk"         ,"pk")
    :Column("Entity.Name"       ,"Entity_Name")
    :Column("Entity.LinkUID"    ,"Entity_LinkUID")
    :Column("Model.Name"        ,"Model_Name")
    :Column("Upper(Entity.Name)","tag1")
    :Join("inner","Model"       ,"Model"        ,"Entity.fk_Model = Model.pk")
    :Join("left","LinkedModel"  ,"LinkedModel"  ,"Model.pk = LinkedModel.fk_Model2")
    :Where("Model.pk = ^ OR LinkedModel.fk_Model1 = ^",par_iModelPk,par_iModelPk)
    :Where("Entity.pk != ^",par_iLinkedEntityPk)   // To not link to oneself. 
    :Distinct(.t.)
    :OrderBy("tag1")
    :SQL("ListOfEntities")

// _M_  Access rights restrictions

endwith

SetSelect2Support()

select ListOfEntities
scan all
    if !empty(l_json_Entities)
        l_json_Entities += [,]
    endif
    l_cInfo = ListOfEntities->Entity_Name + [ (] + ListOfEntities->Model_Name + [)]
    l_cInfo := el_StrReplace(l_cInfo,{;
                                    [\] => [\\] ,;
                                    ["] => [ ] ,;
                                    ['] => [ ] ;
                                },,1)
    l_json_Entities += "{id:"+trans(ListOfEntities->pk)+",text:'"+l_cInfo+"'}"
    l_hEntityNames[ListOfEntities->pk] := l_cInfo   // Will be used to assist in setting up default <select> <option>
    if ListOfEntities->Entity_LinkUID = par_cEntityLinkUID
        l_iPreselected_Entity_Pk   := ListOfEntities->Pk
        l_cPreselected_Entity_Name := ListOfEntities->Entity_Name + [ (] + ListOfEntities->Model_Name + [)]
    endif
endscan
l_json_Entities := "["+l_json_Entities+"]"

//Call the jQuery code even before the for loop, since it will be used after html is loaded anyway.
// oFcgi:p_cjQueryScript += [$(".SelectEntity").select2({placeholder: '',allowClear: true,data: ]+l_json_Entities+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]
ActivatejQuerySelect2(".SelectEntity",l_json_Entities)

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
// altd()
l_cHtml += [<input type="hidden" name="LinkedEntityKey" value="]+trans(par_iLinkedEntityPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        if empty(par_iLinkedEntityPk)
            l_cHtml += [<span class="navbar-brand ms-3">New ]+oFcgi:p_ANFLinkedEntity+[</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update ]+oFcgi:p_ANFLinkedEntity+[</span>]   //navbar-text
        endif
        if oFcgi:p_nAccessLevelML >= 5
            l_cHtml += GetButtonOnEditFormSave()
        endif
        l_cHtml += GetButtonOnEditFormDoneCancel()
        if !empty(par_iLinkedEntityPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += GetButtonOnEditFormDelete()
            endif
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<table>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">From ]+oFcgi:p_ANFEntity+[</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="LinkedEntityFromPk" id="LinkedEntityFromPk" class="SelectEntity" style="width:600px"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[>]
                if l_iLinkedEntityFromEntityPk != 0
                    //select2 will place the current selected option at the top of the list of options, overriding the initial order.
                    l_cHtml += [<option value="]+Trans(l_iLinkedEntityFromEntityPk)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iLinkedEntityFromEntityPk,"")+[</option>]
                elseif !empty(par_cEntityLinkUID)
                    //we are coming from an entity so preselect it as first end but only do this for the first Association End
                    l_cHtml += [<option value="]+Trans(l_iPreselected_Entity_Pk)+[" selected="selected">]+l_cPreselected_Entity_Name+[</option>]
                else
                    oFcgi:p_cjQueryScript += [$("#LinkedEntityFromPk").select2('val','0');]  // trick to not have a blank option bar.
                endif
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">To ]+oFcgi:p_ANFEntity+[</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="LinkedEntityToPk" id="LinkedEntityToPk" class="SelectEntity" style="width:600px"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[>]
                if l_iLinkedEntityToEntityPk != 0
                    //select2 will place the current selected option at the top of the list of options, overriding the initial order.
                    l_cHtml += [<option value="]+Trans(l_iLinkedEntityToEntityPk)+[" selected="selected">]+hb_HGetDef(l_hEntityNames,l_iLinkedEntityToEntityPk,"")+[</option>]
                else
                    oFcgi:p_cjQueryScript += [$("#LinkedEntityToPk").select2('val','0');]  // trick to not have a blank option bar.
                endif
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]


        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80"]+iif(oFcgi:p_nAccessLevelML >= 3,[],[ disabled])+[>]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]

l_cHtml += [</div>]
    
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function LinkedEntityEditFormOnSubmit(par_iModelPk,par_iLinkedEntityPk,par_cLinkedEntityLinkUID,par_cEntityLinkUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_iLinkedEntityPk
local l_cLinkedEntityDescription
local l_iLinkedEntityFromEntityPk
local l_iLinkedEntityToEntityPk
local l_cLinkedEntityLinkUID

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("LinkedEntityEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iLinkedEntityFromEntityPk := Val(oFcgi:GetInputValue("LinkedEntityFromPk"))
l_iLinkedEntityToEntityPk   := Val(oFcgi:GetInputValue("LinkedEntityToPk"))
l_cLinkedEntityDescription  := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))


do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 7
        do case
        case empty(l_iLinkedEntityFromEntityPk) .or. empty(l_iLinkedEntityToEntityPk)
            l_cErrorMessage := oFcgi:p_ANFLinkedEntity+[ needs to have both links set.]
        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

            //Save the Model
            with object l_oDB1
                :Table("CA6D54DF-D040-4A65-8A93-13C7E9831638","LinkedEntity")
                :Field("LinkedEntity.Description",iif(empty(l_cLinkedEntityDescription),NULL,l_cLinkedEntityDescription))
                :Field("LinkedEntity.fk_Entity1" ,l_iLinkedEntityFromEntityPk)
                :Field("LinkedEntity.fk_Entity2" ,l_iLinkedEntityToEntityPk)
                
                if empty(par_iLinkedEntityPk)
                    l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
                    with object l_oDB2
                        :Table("DE792BD4-8C30-4356-8859-CD5BA7B88D92","LinkedEntity")
                        :Where("LinkedEntity.fk_Entity1 = ^ AND LinkedEntity.fk_Entity2 = ^" , l_iLinkedEntityFromEntityPk, l_iLinkedEntityToEntityPk)
                        :SQL()
                    endwith
        
                    if l_oDB2:Tally <> 0 
                        l_cErrorMessage := [Duplicate ]+oFcgi:p_ANFLinkedEntity+[ link!]
                    elseif l_iLinkedEntityToEntityPk = l_iLinkedEntityFromEntityPk
                        l_cErrorMessage := [Cannot link ]+oFcgi:p_ANFLinkedEntity+[ to itself!]
                    else
                        l_cLinkedEntityLinkUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                        :Field("LinkedEntity.LinkUID" , l_cLinkedEntityLinkUID)
                        if :Add()
                            l_iLinkedEntityPk := :Key()
                            oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListLinkedEntities")
                        else
                            l_cErrorMessage := [Failed to add ]+oFcgi:p_ANFLinkedEntity+[.]
                        endif
                    endif
                else
                    if :Update(par_iLinkedEntityPk)
                        oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListLinkedEntities")
                    else
                        l_cErrorMessage := [Failed to update ]+oFcgi:p_ANFLinkedEntity+[.]
                    endif
                endif
            endwith
        endcase
    endif

case el_IsInlist(l_cActionOnSubmit,"Cancel","Done")
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListLinkedEntities")

case l_cActionOnSubmit == "Delete"   // Model
    if oFcgi:p_nAccessLevelML >= 5
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB1:Delete("E184F683-C71F-4AAB-9227-3576C17AC4BA","LinkedEntity",par_iLinkedEntityPk)
    endif
    oFcgi:Redirect(oFcgi:p_cSitePath+"Modeling/EditEntity/"+par_cEntityLinkUID+"/ListLinkedEntities")
endcase

if !empty(l_cErrorMessage)
    l_hValues["LinkedEntityFomPk"] := l_iLinkedEntityFromEntityPk
    l_hValues["LinkedEntityToPk"]  := l_iLinkedEntityToEntityPk
    l_hValues["Description"]       := l_cLinkedEntityDescription

    l_cHtml += LinkedEntityEditFormBuild(par_iModelPk,l_iLinkedEntityPk,l_cLinkedEntityLinkUID,par_cEntityLinkUID,l_cErrorMessage,l_hValues)
endif

return l_cHtml

//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function CascadeDeleteAssociation(par_iProjectPk,par_iAssociationPk)
local l_cErrorMessage := ""
local l_oDB_ListOfEndpointRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)

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
            :Delete("35929f02-bfa8-41b1-bbad-8dbcb50c1de2","Endpoint",ListOfEndpointRecordsToDelete->pk)
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
local l_oDB_ListOfLinkedEntityRecordsToDelete := hb_SQLData(oFcgi:p_o_SQLConnection)

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
            :Delete("83256a1d-a0a0-4682-bdcd-a7b14c40034d","Endpoint",ListOfEndpointRecordsToDelete->pk)
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
                :Delete("c10bfea1-5496-4990-8b71-7e4f8479aa1b","Attribute",ListOfAttributeRecordsToDelete->pk)
            endscan

            //Delete the related custom fields
            CustomFieldsDelete(par_iProjectPk,USEDON_ENTITY,par_iEntityPk)
            if !:Delete("3bb80f26-43b0-418d-ab3b-33d23b02cdad","Entity",par_iEntityPk)
                l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFEntity+[ record.]
            endif
        endif
    endif
endwith

with object l_oDB_ListOfLinkedEntityRecordsToDelete
    //Delete any LinkedEntity related records
    :Table("D5C62E48-5A83-49C9-A260-CB3DE7280C8A","LinkedEntity")
    :Column("LinkedEntity.pk" , "pk")
    :Where("LinkedEntity.fk_Entity1 = ^ OR LinkedEntity.fk_Entity2 = ^",par_iEntityPk,par_iEntityPk)
    :SQL("ListOfLinkedEntityRecordsToDelete")
    if :Tally < 0
        l_cErrorMessage := [Failed to query for related ]+oFcgi:p_ANFEntity+[ link records.]
    else
        select ListOfLinkedEntityRecordsToDelete
        scan
            :Delete("04E9FDAB-7D37-4C47-B3AD-C5F4D139997C","LinkedEntity",ListOfLinkedEntityRecordsToDelete->pk)
        endscan
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
// Step 6 - Delete all LinkedModel relationships
// Step 7 - Delete Model

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

    //Delete the indirectly linked UserSetting records
    :Table("34bc4f62-e088-4900-8997-804c5f1e8e08","ModelingDiagram")
    :Column("UserSetting.pk" , "pk")
    :Where("ModelingDiagram.fk_Model = ^" , par_iModelPk)
    :Join("inner","UserSetting","","UserSetting.fk_ModelingDiagram = ModelingDiagram.pk")
    :SQL("CascadeDeleteModelListOfRecordsToDelete")
    select CascadeDeleteModelListOfRecordsToDelete
    scan all while empty(l_cErrorMessage)
        if !l_oDB_RecordToDelete:Delete("0fabbf02-25e5-4821-b46c-0a7c47cf8956","UserSetting",CascadeDeleteModelListOfRecordsToDelete->pk)
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

// Step 6 - Delete all LinkedModel relationships
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("7D17932D-E4E1-418D-9FC4-2E8D4C0D3E65","LinkedModel")
        :Column("LinkedModel.pk" , "pk")
        :Where("LinkedModel.fk_Model1 = ^ OR LinkedModel.fk_Model2 = ^" , par_iModelPk, par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            if !l_oDB_RecordToDelete:Delete("B5C46101-4BD0-444D-8C2A-38230162EB53","LinkedModel",CascadeDeleteModelListOfRecordsToDelete->pk)
                l_cErrorMessage := [Failed to delete LinkedModel.]
            endif
        endscan
    endwith
endif

// Step 7 - Delete all UserSettingModel relationships
if empty(l_cErrorMessage)
    with object l_oDB_ListOfRecordsToDelete
        :Table("7D17932D-E4E1-418D-9FC4-2E8D4C0D3E66","UserSettingModel")
        :Column("UserSettingModel.pk" , "pk")
        :Where("UserSettingModel.fk_Model = ^" , par_iModelPk)
        :SQL("CascadeDeleteModelListOfRecordsToDelete")
        select CascadeDeleteModelListOfRecordsToDelete
        scan all while empty(l_cErrorMessage)
            if !l_oDB_RecordToDelete:Delete("B5C46101-4BD0-444D-8C2A-38230162EB54","UserSettingModel",CascadeDeleteModelListOfRecordsToDelete->pk)
                l_cErrorMessage := [Failed to delete UserSettingModel.]
            endif
        endscan
    endwith
endif

// Step 8 - Delete Model
if empty(l_cErrorMessage)
    CustomFieldsDelete(par_iProjectPk,USEDON_MODEL,par_iModelPk)
    if !l_oDB_RecordToDelete:Delete("5cfe314f-1303-4e14-865c-0330955850d5","Model",par_iModelPk)
        l_cErrorMessage := [Failed to delete ]+oFcgi:p_ANFModel+[.]
    endif
endif

return l_cErrorMessage
//=================================================================================================================
