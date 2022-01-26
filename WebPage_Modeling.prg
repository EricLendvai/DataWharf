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

local l_iApplicationPk
local l_cApplicationName
local l_cApplicationDescription

local l_hValues := {=>}

local l_cModelingElement := "ENTITIES"  //Default to Entities

local l_aSQLResult := {}

local l_cURLAction              := "ListModels"
local l_cURLLinkUID             := ""

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cLinkUID
local l_lFoundHeaderInfo := .f.

local l_nAccessLevelML := 7   // None by default
// As per the info in Schema.txt
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     7 - Full Access


oFcgi:TraceAdd("BuildPageModeling")

// Variables
// l_cURLAction

// Modeling/                                    Same as Modeling/ListModels/
// Modeling/NewModel/
// Modeling/ModelSettings/<Model.LinkUID>/

// Modeling/ModelVisualize/<Model.LinkUID>/

// Modeling/ListEntities/Model.LinkUID>/
// Modeling/NewEntity/<Model.LinkUID>/
// Modeling/EditEntity/<Entity.LinkUID>/

// Modeling/ListProperties/<Entity.LinkUID>/
// Modeling/NewProperty/<Entity.LinkUID>/
// Modeling/EditProperty/<Property.LinkUID>/

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
    case vfp_Inlist(l_cURLAction,"ModelSettings","ListEntities","ListAssociations","ListPackages","ListDataTypes","NewEntity","NewAssociation","NewPackage","NewDataType")
        with object l_oDB1
            :Table("eaa6b925-b225-4fe2-8eeb-a0afcefc3848","Model")
            :Column("Model.pk"         , "Model_pk")
            :Column("Model.LinkUID"    , "Model_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.Name"       , "Model_Name")
            :Column("Application.pk"   , "Application_pk")
            :Column("Application.Name" , "Application_Name")
            :Where("Model.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Application","","Model.fk_Application = Application.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditEntity")
        with object l_oDB1
            :Table("08839946-0a7b-4a47-a512-dee69e58e102","Entity")
            :Column("Entity.pk"         , "Entity_pk")
            :Column("Entity.LinkUID"    , "Entity_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"          , "Model_pk")
            :Column("Model.LinkUID"     , "Model_LinkUID")
            :Column("Model.Name"        , "Model_Name")
            :Column("Application.pk"    , "Application_pk")
            :Column("Application.Name"  , "Application_Name")
            :Where("Entity.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Entity.fk_Model = Model.pk")
            :Join("inner","Application","","Model.fk_Application = Application.pk")
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
            :Column("Application.pk"     , "Application_pk")
            :Column("Application.Name"   , "Application_Name")
            :Where("Association.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Association.fk_Model = Model.pk")
            :Join("inner","Application","","Model.fk_Application = Application.pk")
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
            :Column("Application.pk"    , "Application_pk")
            :Column("Application.Name"  , "Application_Name")
            :Where("Package.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","Package.fk_Model = Model.pk")
            :Join("inner","Application","","Model.fk_Application = Application.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case vfp_Inlist(l_cURLAction,"EditDataType")
        with object l_oDB1
            :Table("b4bdf68c-9bc2-43f3-8e7b-9c9a3c278528","DataType")
            :Column("DataType.pk"       , "DataType_pk")
            :Column("DataType.LinkUID"  , "DataType_LinkUID")     // Redundant but makes it clearer than to use l_cURLLinkUID
            :Column("Model.pk"          , "Model_pk")
            :Column("Model.LinkUID"     , "Model_LinkUID")
            :Column("Model.Name"        , "Model_Name")
            :Column("Application.pk"    , "Application_pk")
            :Column("Application.Name"  , "Application_Name")
            :Where("DataType.LinkUID = ^" , l_cURLLinkUID)
            :Join("inner","Model","","DataType.fk_Model = Model.pk")
            :Join("inner","Application","","Model.fk_Application = Application.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    endcase

    do case
    case vfp_Inlist(l_cURLAction,"ListEntities","NewEntity","EditEntity","ListProperties","NewProperty","EditProperty")
        l_cModelingElement := "ENTITIES"

    case vfp_Inlist(l_cURLAction,"ListAssociations","NewAssociation","EditAssociation")
        l_cModelingElement := "ASSOCIATIONS"

    case vfp_Inlist(l_cURLAction,"ListPackages","NewPackage","EditPackage")
        l_cModelingElement := "PACKAGES"

    case vfp_Inlist(l_cURLAction,"ListDataTypes","NewDataType","EditDataType")
        l_cModelingElement := "DATATYPES"

    case vfp_Inlist(l_cURLAction,"ModelSettings")
        l_cModelingElement := "SETTINGS"

    case vfp_Inlist(l_cURLAction,"ModelVisualize")
        l_cModelingElement := "VISUALIZE"

    otherwise
        l_cModelingElement := "ENTITIES"

    endcase

    // l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    // if !empty(l_cURLApplicationLinkCode)
    //     with object l_oDB1
    //         :Table("695859f8-e429-4726-8685-33d13a7f7835","Application")
    //         :Column("Application.pk"          , "pk")
    //         :Column("Application.Name"        , "Application_Name")
    //         :Where("Application.LinkCode = ^" ,l_cURLApplicationLinkCode)
    //         :SQL(@l_aSQLResult)
    //     endwith

    //     if l_oDB1:Tally == 1
    //         l_iApplicationPk          := l_aSQLResult[1,1]
    //         l_cApplicationName        := l_aSQLResult[1,2]
    //     else
    //         l_iApplicationPk   := -1
    //         l_cApplicationName := "Unknown"
    //     endif
    // endif

    // do case
    // case oFcgi:p_nUserAccessMode <= 1  // Application access levels
    //     with object l_oDB1
    //         :Table("UserAccessApplication")
    //         :Column("UserAccessApplication.AccessLevelML" , "AccessLevelML")
    //         :Where("UserAccessApplication.fk_User = ^"        ,oFcgi:p_iUserPk)
    //         :Where("UserAccessApplication.fk_Application = ^" ,l_iApplicationPk)
    //         :SQL(@l_aSQLResult)
    //         if l_oDB1:Tally == 1
    //             l_nAccessLevelML := l_aSQLResult[1,1]
    //         else
    //             l_nAccessLevelML := 0
    //         endif
    //     endwith

    // case oFcgi:p_nUserAccessMode  = 2  // All Application Read Only
    //     l_nAccessLevelML := 2
    // case oFcgi:p_nUserAccessMode  = 3  // All Application Full Access
    //     l_nAccessLevelML := 7
    // case oFcgi:p_nUserAccessMode  = 4  // Root Admin (User Control)
    //     l_nAccessLevelML := 7
    // endcase

else
    l_cURLAction := "ListModels"
endif

oFcgi:p_nAccessLevelML := l_nAccessLevelML

do case
case l_cURLAction == "ListModels"
    l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        // l_cHtml += [<div class="container-fluid">]
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[Models/">Modeling</a>]
            if oFcgi:p_nUserAccessMode >= 3  //_M_
                l_cHtml += [<a class="btn btn-primary rounded" ms-3 href="]+l_cSitePath+[Modeling/NewModel/">New Model</a>]
            endif
        l_cHtml += [</div>]
    l_cHtml += [</nav>]

    l_cHtml += ModelListFormBuild()

case l_cURLAction == "NewModel"
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
        // l_cHtml +=     [<div class="container-fluid">]
            l_cHtml += [<div class="input-group">]
                l_cHtml += [<span class="navbar-brand text-white ms-3">New Model</span>]
            l_cHtml += [</div>]
        l_cHtml += [</nav>]
        
        if oFcgi:isGet()
            //Brand new request of add an application.
            l_cHtml += ModelEditFormBuild(l_oDataHeader:Application_pk,"",0,{=>})
        else
            l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Application_pk,"")
        endif
    endif

case l_cURLAction == "ModelSettings"
    if oFcgi:p_nAccessLevelML >= 7 .and. l_lFoundHeaderInfo
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.f.,l_cSitePath)
        //par_iModelPk,par_cModelLinkUID,par_cApplicationName,par_cModelName,par_lActiveHeader

        if oFcgi:isGet()
            with object l_oDB1
                :Table("d093409c-3fa3-4afb-95e6-ca55d0ba96b6","Model")
                :Column("Model.fk_Application" , "Model_fk_Application")
                :Column("Model.Name"           , "Model_Name")
                :Column("Model.Stage"          , "Model_Stage")
                :Column("Model.Description"    , "Model_Description")
                l_oData := :Get(l_oDataHeader:Model_pk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Fk_Application"] := l_oData:Model_fk_Application
                l_hValues["Name"]           := l_oData:Model_Name
                l_hValues["Stage"]          := l_oData:Model_Stage
                l_hValues["Description"]    := l_oData:Model_Description
                CustomFieldsLoad(l_oDataHeader:Application_pk,USEDON_MODEL,l_oDataHeader:Model_pk,@l_hValues)

                l_cHtml += ModelEditFormBuild(l_oDataHeader:Application_pk,"",l_oDataHeader:Model_pk,l_hValues,l_oDataHeader:Model_LinkUID)
            endif
        else
            l_cHtml += ModelEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_LinkUID)
        endif
    endif

case l_cURLAction == "ListEntities"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += EntityListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    endif

case l_cURLAction == "NewEntity"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += EntityEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
        endif
    endif

case l_cURLAction == "EditEntity"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

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
                CustomFieldsLoad(l_oDataHeader:Application_pk,USEDON_ENTITY,l_oDataHeader:Entity_pk,@l_hValues)

                l_cHtml += EntityEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID,"",l_oDataHeader:Entity_pk,l_hValues)
            endif
        else
            l_cHtml += EntityEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Entity_LinkUID)
        endif

    endif




case l_cURLAction == "ListPackages"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += PackageListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        // Nothing for now. All buttons are GET
    endif

case l_cURLAction == "NewPackage"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += PackageEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
        endif
    endif

case l_cURLAction == "EditPackage"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

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
                CustomFieldsLoad(l_oDataHeader:Application_pk,USEDON_PACKAGE,l_oDataHeader:Package_pk,@l_hValues)

                l_cHtml += PackageEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID,"",l_oDataHeader:Package_pk,l_hValues)
            endif
        else
            l_cHtml += PackageEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Package_LinkUID)
        endif

    endif





case l_cURLAction == "ListDataTypes"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        l_cHtml += DataTypeListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        // Nothing for now. All buttons are GET
    endif

case l_cURLAction == "NewDataType"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)
        
        if oFcgi:isGet()
            l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,"","",0,{=>})
        else
            l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
        endif
    endif

case l_cURLAction == "EditDataType"
    if oFcgi:p_nAccessLevelML >= 5
        l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

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
                CustomFieldsLoad(l_oDataHeader:Application_pk,USEDON_DATATYPE,l_oDataHeader:DataType_pk,@l_hValues)

                l_cHtml += DataTypeEditFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID,"",l_oDataHeader:DataType_pk,l_hValues)
            endif
        else
            l_cHtml += DataTypeEditFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:DataType_LinkUID)
        endif

    endif




case l_cURLAction == "ListAssociations"
    l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

    if oFcgi:isGet()
        // l_cHtml += EntityListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    else
        // l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
    endif

// case l_cURLAction == "ListDataTypes"
//     l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

//     if oFcgi:isGet()
//         // l_cHtml += EntityListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
//     else
//         // l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
//     endif

// case l_cURLAction == "ListPackages"
//     l_cHtml += ModelingHeaderBuild(l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID,l_oDataHeader:Application_Name,l_oDataHeader:Model_Name,l_cModelingElement,.t.,l_cSitePath)

//     if oFcgi:isGet()
//         // l_cHtml += EntityListFormBuild(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
//     else
//         // l_cHtml += EntityListFormOnSubmit(l_oDataHeader:Application_pk,l_oDataHeader:Model_pk,l_oDataHeader:Model_LinkUID)
//     endif

otherwise

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function ModelingHeaderBuild(par_iModelPk,par_cModelLinkUID,par_cApplicationName,par_cModelName,par_cModelElement,par_lActiveHeader,par_cSitePath)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
 
oFcgi:TraceAdd("ModelingHeaderBuild")

l_cHtml += [<nav class="navbar navbar-default bg-secondary bg-gradient">]
    l_cHtml += [<div class="input-group">]
//_M_
        l_cHtml += [<span class="ps-2 navbar-brand text-white">Application / Model: ]+par_cApplicationName+[ / ]+par_cModelName+[</span>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

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
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ENTITIES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListEntities/]+par_cModelLinkUID+[/">Entities (]+Trans(l_iReccount)+[)</a>]
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
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "ASSOCIATIONS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListAssociations/]+par_cModelLinkUID+[/">Associations (]+Trans(l_iReccount)+[)</a>]
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
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "DATATYPES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListDataTypes/]+par_cModelLinkUID+[/">Data Types (]+Trans(l_iReccount)+[)</a>]
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
        l_cHtml += [<a class="nav-link]+iif(par_cModelElement == "PACKAGES",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ListPackages/]+par_cModelLinkUID+[/">Packages (]+Trans(l_iReccount)+[)</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="nav-link ]+iif(par_cModelElement == "SETTINGS",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelSettings/]+par_cModelLinkUID+[/">Model Settings</a>]
        l_cHtml += [</li>]
    endif
    //--------------------------------------------------------------------------------------
    //--------------------------------------------------------------------------------------
    l_cHtml += [<li class="nav-item">]
        l_cHtml += [<a class="nav-link ]+iif(par_cModelElement == "VISUALIZE",[ active],[])+iif(par_lActiveHeader,[],[ disabled])+[" href="]+par_cSitePath+[Modeling/ModelVisualize/]+par_cModelLinkUID+[/">Visualize</a>]
    l_cHtml += [</li>]
    //--------------------------------------------------------------------------------------
l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ModelListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_oDB_CustomFields               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsEntityCounts   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsPackageCounts  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfModelsDataTypeCounts := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_nNumberOfModels
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

local l_iModelPk
local l_nEntityCount
local l_nPackageCount
local l_nDataTypeCount

oFcgi:TraceAdd("ModelListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("ea43381a-8ba0-4bbf-aaa1-43768780351d","Application")
    :Column("Model.pk"          ,"pk")
    :Column("Application.Name"  ,"Application_Name")
    :Column("Model.Name"        ,"Model_Name")
    :Column("Model.Stage"       ,"Model_Stage")
    :Column("Model.Description" ,"Model_Description")
    :Column("Model.LinkUID"     ,"Model_LinkUID")
    :Column("Upper(Application.Name)","tag1")
    :Column("Upper(Model.Name)"      ,"tag2")
    :Join("inner","Model","","Model.fk_Application = Application.pk")
    :OrderBy("tag1")
    :OrderBy("tag2")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif

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
        :Where("CustomField.UsedOn = ^",USEDON_MODEL)
        :Where("CustomField.Status <= 2")
        :Where("CustomField.Type = 2")   // Multi Choice
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("3172b746-2c76-4f04-959d-bcf7436f7eac","Model")
        :Column("Model.pk"                ,"fk_entity")
        :Column("CustomField.pk"          ,"CustomField_pk")
        :Column("CustomField.Label"       ,"CustomField_Label")
        :Column("CustomField.Type"        ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI" ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM" ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD" ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
        :Join("inner","CustomFieldValue","","CustomFieldValue.fk_Entity = Model.pk")
        :Join("inner","CustomField"     ,"","CustomFieldValue.fk_CustomField = CustomField.pk")
        :Where("CustomField.UsedOn = ^",USEDON_MODEL)
        :Where("CustomField.Status <= 2")
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

    //For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
    With Object l_oDB_ListOfModelsEntityCounts
        :Table("ec7bdbd8-db8f-48ee-a277-75ddc70ee531","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"EntityCount")
        :Join("inner","Entity","","Entity.fk_Model = Model.pk")
        :GroupBy("Model.pk")
        :SQL("ListOfModelsEntityCounts")
        With Object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

    With Object l_oDB_ListOfModelsPackageCounts
        :Table("ffae46b3-74a4-43f4-9d11-dae80e0bcba5","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"PackageCount")
        :Join("inner","Package","","Package.fk_Model = Model.pk")
        :GroupBy("Model.pk")
        :SQL("ListOfModelsPackageCounts")
        With Object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

    With Object l_oDB_ListOfModelsDataTypeCounts
        :Table("6bdc7220-0980-4288-9dd0-621cc3baba60","Model")
        :Column("Model.pk" ,"Model_pk")
        :Column("Count(*)" ,"DataTypeCount")
        :Join("inner","DataType","","DataType.fk_Model = Model.pk")
        :GroupBy("Model.pk")
        :SQL("ListOfModelsDataTypeCounts")
        With Object :p_oCursor
            :Index("tag1","Model_pk")
            :CreateIndexes()
            :SetOrder("tag1")
        endwith
    endwith

endif

l_cHtml += [<div class="m-3">]

    if empty(l_nNumberOfModels)
        l_cHtml += [<div class="input-group">]
            l_cHtml += [<span>No Application Model on file.</span>]
        l_cHtml += [</div>]

    else
        l_cHtml += [<div class="row justify-content-center">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"9","10")+[">Application Models (]+Trans(l_nNumberOfModels)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Application</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Model Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Stage</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Entities</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Associations</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Data Types</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Packages</th>]
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

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]  //Application
                            l_cHtml += Allt(ListOfModels->Application_Name)
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
                            l_cHtml += []
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
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================





//=================================================================================================================
static function ModelEditFormBuild(par_iApplicationPk,par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText      := hb_DefaultValue(par_cErrorText,"")

local l_iApplicationPk := hb_HGetDef(par_hValues,"Fk_Application",0)
local l_cName          := hb_HGetDef(par_hValues,"Name","")
local l_nStage         := hb_HGetDef(par_hValues,"Stage",1)
local l_cDescription   := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("ModelEditFormBuild")


with object l_oDB_ListOfApplications
    :Table("0743cc77-e97e-4e18-8193-700f560abf1f","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")
    :SQL("ListOfApplications")

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
            l_cHtml += [<span class="navbar-brand ms-3">New Model</span>]   //navbar-text
        else
            l_cHtml += [<span class="navbar-brand ms-3">Update Model Settings</span>]   //navbar-text
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


        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Application</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATESAVEBUTTON+[ name="ComboApplicationPk" id="ComboApplicationPk"]+iif(oFcgi:p_nAccessLevelML >= 5,[],[ disabled])+[ class="form-select">]
                select ListOfApplications
                scan all
                    l_cHtml += [<option value="]+Trans(ListOfApplications->pk)+["]+iif(ListOfApplications->pk = l_iApplicationPk,[ selected],[])+[>]+AllTrim(ListOfApplications->Application_Name)+[</option>]
                endscan
                l_cHtml += [</select>]
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

        l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_MODEL,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()

return l_cHtml
//=================================================================================================================
static function ModelEditFormOnSubmit(par_iApplicationPk,par_cModelLinkUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_iModelPk
local l_iApplicationPk
local l_cModelName
local l_nModelStage
local l_cModelDescription

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_oDB1
local l_oDB2

oFcgi:TraceAdd("ModelEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iModelPk          := Val(oFcgi:GetInputValue("ModelKey"))
l_iApplicationPk    := Val(oFcgi:GetInputValue("ComboApplicationPk"))
l_cModelName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nModelStage       := Val(oFcgi:GetInputValue("ComboStage"))
l_cModelDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nUserAccessMode >= 3
        do case
        case empty(l_cModelName)
            l_cErrorMessage := "Missing Name"
        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("6f26318e-0a76-4e5b-a894-adae0c00a876","Model")
                :Where([lower(replace(Model.Name,' ','')) = ^],lower(StrTran(l_cModelName," ","")))
                :Where("Model.fk_Application = ^" , l_iApplicationPk)
                if l_iModelPk > 0
                    :Where([Model.pk != ^],l_iModelPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Model Name in Application"
            else
                //Save the Model
                with object l_oDB1
                    :Table("e65406e9-c51f-43f5-ab50-73904d9986a8","Model")
                    :Field("Model.Name"           , l_cModelName)
                    :Field("Model.fk_Application" , l_iApplicationPk)
                    :Field("Model.Stage"          , l_nModelStage)
                    :Field("Model.Description"    , iif(empty(l_cModelDescription),NULL,l_cModelDescription))
                    
                    if empty(l_iModelPk)
                        :Field("Model.LinkUID" , oFcgi:p_o_SQLConnection:GetUUIDString())
                        if :Add()
                            l_iModelPk := :Key()
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/")
                        else
                            l_cErrorMessage := "Failed to add Model."
                        endif
                    else
                        if :Update(l_iModelPk)
                            // CustomFieldsSave(l_iModelPk,USEDON_APPLICATION,l_iModelPk)
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/")
                        else
                            l_cErrorMessage := "Failed to update Application."
                        endif
                    endif
                    if empty(l_cErrorMessage)
                        CustomFieldsSave(par_iApplicationPk,USEDON_MODEL,l_iModelPk)
                    endif
                endwith
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"
    if empty(par_cModelLinkUID)
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling")
    else
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
    endif

case l_cActionOnSubmit == "Delete"   // Model

//_M_ Deletion of Model

    // if oFcgi:p_nUserAccessMode >= 3
    //     if CheckIfAllowDestructiveModelDelete(l_iModelPk)
    //         l_cErrorMessage := CascadeDeleteApplication(l_iModelPk)
    //         if empty(l_cErrorMessage)
    //             oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/")
    //         endif
    //     else
    //         l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    //         l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

    //         with object l_oDB1
    //             :Table("NameSpace")
    //             :Where("NameSpace.fk_Application = ^",l_iModelPk)
    //             :SQL()

    //             if :Tally == 0
    //                 :Table("Version")
    //                 :Where("Version.fk_Application = ^",l_iModelPk)
    //                 :SQL()

    //                 if :Tally == 0
    //                     //Don't Have to test on related Table or DiagramTables since deleting Table would remove DiagramTables records and NameSpaces can no be removed with Tables
    //                     //But we may have some left over Table less diagrams. Remove them

    //                     :Table("Diagram")
    //                     :Column("Diagram.pk" , "pk")
    //                     :Where("Diagram.fk_Application = ^",l_iModelPk)
    //                     :SQL("ListOfDiagramRecordsToDelete")
    //                     if :Tally >= 0
    //                         if :Tally > 0
    //                             select ListOfDiagramRecordsToDelete
    //                             scan
    //                                 l_oDB2:Delete("Diagram",ListOfDiagramRecordsToDelete->pk)
    //                             endscan
    //                         endif

    //                         CustomFieldsDelete(l_iModelPk,USEDON_MODEL,l_iModelPk)
    //                         :Delete("Application",l_iModelPk)
    //                     else
    //                         l_cErrorMessage := "Failed to clear related DiagramTable records."
    //                     endif

    //                     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Applications/")
    //                 else
    //                     l_cErrorMessage := "Related Version record on file"
    //                 endif
    //             else
    //                 l_cErrorMessage := "Related Name Space record on file"
    //             endif
    //         endwith
    //     endif
    // endif

endcase

if !empty(l_cErrorMessage)
    l_hValues["Fk_Application"] := l_iApplicationPk
    l_hValues["Name"]           := l_cModelName
    l_hValues["Stage"]          := l_nModelStage
    l_hValues["Description"]    := l_cModelDescription
    CustomFieldsFormToHash(par_iApplicationPk,USEDON_MODEL,@l_hValues)

    l_cHtml += ModelEditFormBuild(l_cErrorMessage,l_iModelPk,l_hValues)
endif

return l_cHtml
//=================================================================================================================
static function EntityListFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []
local l_oDB_ListOfEntities               := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntitiesPropertyCounts := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_CustomFields                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_oCursor
local l_iEntityPk
local l_nPropertyCount

local l_cSearchEntityName
local l_cSearchEntityDescription

local l_cSearchPropertyName
local l_cSearchPropertyDescription

local l_nNumberOfEntities := 0
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}
local l_cPropertiesearchParameters
local l_nColspan
local l_ScriptFolder

oFcgi:TraceAdd("EntityListFormBuild")

l_cSearchEntityName          := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName")
l_cSearchEntityDescription   := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription")

l_cSearchPropertyName        := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyName")
l_cSearchPropertyDescription := GetUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyDescription")

if empty(l_cSearchPropertyName) .and. empty(l_cSearchPropertyDescription)
    l_cPropertiesearchParameters := ""
else
    l_cPropertiesearchParameters := [Search?PropertyName=]+hb_StrToHex(l_cSearchPropertyName)+[&PropertyDescription=]+hb_StrToHex(l_cSearchPropertyDescription)   //strtolhex
endif

With Object l_oDB_ListOfEntities
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
    if !empty(l_cSearchPropertyName) .or. !empty(l_cSearchPropertyDescription)
        :Distinct(.t.)
        :Join("inner","Property","","Property.fk_Entity = Entity.pk")
        if !empty(l_cSearchPropertyName)
            :KeywordCondition(l_cSearchPropertyName,"Property.Name")
        endif
        if !empty(l_cSearchPropertyDescription)
            :KeywordCondition(l_cSearchPropertyDescription,"Property.Description")
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
    With Object l_oDB_CustomFields
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
        if !empty(l_cSearchPropertyName) .or. !empty(l_cSearchPropertyDescription)
            :Distinct(.t.)
            :Join("inner","Property","","Property.fk_Entity = Entity.pk")
            if !empty(l_cSearchPropertyName)
                :KeywordCondition(l_cSearchPropertyName,"Property.Name")
            endif
            if !empty(l_cSearchPropertyDescription)
                :KeywordCondition(l_cSearchPropertyDescription,"Property.Description")
            endif
        endif
        :SQL("ListOfCustomFieldOptionDefinition")
        if :Tally > 0
            CustomFieldLoad_hOptionValueToDescriptionMapping(@l_hOptionValueToDescriptionMapping)
        endif

        :Table("de1a82dd-16e0-4246-afc8-d75df62fc4e0","Entity")
        :Column("Entity.pk"               ,"fk_entity")

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
        if !empty(l_cSearchPropertyName) .or. !empty(l_cSearchPropertyDescription)
            :Distinct(.t.)
            :Join("inner","Property","","Property.fk_Entity = Entity.pk")
            if !empty(l_cSearchPropertyName)
                :KeywordCondition(l_cSearchPropertyName,"Property.Name")
            endif
            if !empty(l_cSearchPropertyDescription)
                :KeywordCondition(l_cSearchPropertyDescription,"Property.Description")
            endif
        endif
        :OrderBy("tag1")
        :SQL("ListOfCustomFieldValues")
        l_nNumberOfCustomFieldValues := :Tally

    endwith

endif


//For now will issue a separate SQL to get totals, later once ORM can handle WITH (Common Table Expressions), using a vfp_seek technic will not be needed.
With Object l_oDB_ListOfEntitiesPropertyCounts
    :Table("bc2e9531-aab8-4c57-bd71-7bddca894b61","Entity")
    :Column("Entity.pk","Entity_pk")
    :Column("Count(*)" ,"PropertyCount")
    :Join("inner","Property","","Property.fk_Entity = Entity.pk")
    :Where("Entity.fk_Model = ^",par_iModelPk)
    :GroupBy("Entity.pk")
    :SQL("ListOfEntitiesPropertyCounts")

    With Object :p_oCursor
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewEntity/]+par_cModelLinkUID+[/">New Entity</a>]
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
                            l_cHtml += [<td><span class="me-2">Entity</span></td>]
                            l_cHtml += [<td><input type="text" name="TextEntityName" id="TextEntityName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEntityName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextEntityDescription" id="TextEntityDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchEntityDescription)+[" class="form-control"></td>]
                        l_cHtml += [</tr>]
                        l_cHtml += [<tr>]
                            l_cHtml += [<td><span class="me-2">Property</span></td>]
                            l_cHtml += [<td><input type="text" name="TextPropertyName" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchPropertyName)+[" class="form-control"></td>]
                            l_cHtml += [<td><input type="text" name="TextPropertyDescription" size="25" maxlength="100" value="]+FcgiPrepFieldForValue(l_cSearchPropertyDescription)+[" class="form-control"></td>]
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
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+Trans(l_nColspan)+[">Entities (]+Trans(l_nNumberOfEntities)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-info">]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Package</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Entity Name</th>]
                l_cHtml += [<th class="GridHeaderRowCells text-white">Properties</th>]
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
                        l_nPropertyCount := iif( VFP_Seek(l_iEntityPk,"ListOfEntitiesPropertyCounts","tag1") , ListOfEntitiesPropertyCounts->PropertyCount , 0)
                        l_cHtml += [<a href="]+l_cSitePath+[Modeling/ListProperties/]+ListOfEntities->Entity_LinkUID+[/]+l_cPropertiesearchParameters+[">]+Trans(l_nPropertyCount)+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfEntities->Entity_Description,""))
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
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
static function EntityListFormOnSubmit(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_cEntityName
local l_cEntityDescription
local l_cPropertyName
local l_cPropertyDescription
local l_cURL

oFcgi:TraceAdd("EntityListFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_cEntityName         := SanitizeInput(oFcgi:GetInputValue("TextEntityName"))
l_cEntityDescription  := SanitizeInput(oFcgi:GetInputValue("TextEntityDescription"))

l_cPropertyName        := SanitizeInput(oFcgi:GetInputValue("TextPropertyName"))
l_cPropertyDescription := SanitizeInput(oFcgi:GetInputValue("TextPropertyDescription"))

do case
case l_cActionOnSubmit == "Search"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName"        ,l_cEntityName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription" ,l_cEntityDescription)

    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyName"       ,l_cPropertyName)
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyDescription",l_cPropertyDescription)

    l_cHtml += EntityListFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)

case l_cActionOnSubmit == "Reset"
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityName"        ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_EntityDescription" ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyName"       ,"")
    SaveUserSetting("Model_"+Trans(par_iModelPk)+"_EntitySearch_PropertyDescription","")

    l_cURL := oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/"
    oFcgi:Redirect(l_cURL)

otherwise
    l_cHtml += EntityListFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)

endcase

return l_cHtml
//=================================================================================================================
static function EntityEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,par_cErrorText,par_iPk,par_hValues)
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
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Entity</span>]   //navbar-text
        if oFcgi:p_nAccessLevelML >= 3
            l_cHtml += [<input type="submit" class="btn btn-primary rounded ms-0" id="ButtonSave" name="ButtonSave" value="Save" onclick="$('#ActionOnSubmit').val('Save');document.form.submit();" role="button">]
        endif
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        if !empty(par_iPk)
            if oFcgi:p_nAccessLevelML >= 5
                l_cHtml += [<button type="button" class="btn btn-primary rounded ms-5" data-bs-toggle="modal" data-bs-target="#ConfirmDeleteModal">Delete</button>]
            endif
            l_cHtml += [<a class="btn btn-primary rounded ms-5 HideOnEdit" href="]+l_cSitePath+[Modeling/ListProperties/]+l_oDataEntityInfo:Entity_LinkUID+[/">Properties</a>]
        endif
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<div class="m-3">]

    l_cHtml += [<table>]

        if l_nNumberOfPackages > 0
            l_cHtml += [<tr class="pb-5">]
                l_cHtml += [<td class="pe-2 pb-3">Parent Package</td>]
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
            l_cHtml += [<td class="pe-2 pb-3">Entity Name</td>]
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

        l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_ENTITY,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextScope').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function EntityEditFormOnSubmit(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID)

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
                CustomFieldsSave(par_iApplicationPk,USEDON_ENTITY,l_iEntityPk)
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"
    l_cFrom := oFcgi:GetQueryString('From')
    //_M_

    // switch l_cFrom
    // case 'Properties'
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListProperties/"+par_cURLApplicationLinkCode+"/"+par_cURLNameSpaceName+"/"+par_cURLEntityName+"/")
    //     exit
    // otherwise
    //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cURLApplicationLinkCode+"/")
    // endswitch

case l_cActionOnSubmit == "Delete"   // Entity
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveModelDelete(par_iModelPk)
            // l_cErrorMessage := CascadeDeleteEntity(par_iModelPk,l_iEntityPk)
            // if empty(l_cErrorMessage)
            //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cURLApplicationLinkCode+"/")
            //     l_cFrom := "Redirect"
            // endif
        else
            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("d8f4ccf0-5cd0-410e-9137-ba452d10904c","Property")
                :Where("Property.fk_Entity = ^",l_iEntityPk)
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

                        CustomFieldsDelete(par_iApplicationPk,USEDON_ENTITY,l_iEntityPk)
                        if :Delete("6818930c-2486-49b9-a2b6-df7d50dd020f","Entity",l_iEntityPk)
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListEntities/"+par_cModelLinkUID+"/")
                            l_cFrom := "Redirect"
                        else
                            l_cErrorMessage := "Failed to delete Entity"
                        endif

                    else
                        l_cErrorMessage := "Failed to clear related DiagramEntity records."
                    endif
                else
                    l_cErrorMessage := "Related Column record on file"
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
    CustomFieldsFormToHash(par_iApplicationPk,USEDON_ENTITY,@l_hValues)

    l_cHtml += EntityEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cEntityLinkUID,l_cErrorMessage,l_iEntityPk,l_hValues)

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
    case 'Properties'
        oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListProperties/"+par_cEntityLinkUID+"/")
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
static function PackageListFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)
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

With Object l_oDB_ListOfPackages
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
        :Column("Package.pk"              ,"fk_entity")
        :Column("CustomField.pk"          ,"CustomField_pk")
        :Column("CustomField.Label"       ,"CustomField_Label")
        :Column("CustomField.Type"        ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI" ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM" ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD" ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewPackage/]+par_cModelLinkUID+[/">New Package</a>]
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
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"1","2")+[">Packages (]+Trans(l_nNumberOfPackages)+[)</th>]
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
static function PackageEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_ifk_Package  := nvl(hb_HGetDef(par_hValues,"fk_Package",0),0)
local l_cSitePath    := oFcgi:RequestSettings["SitePath"]
local l_oDB1         := hb_SQLData(oFcgi:p_o_SQLConnection)
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
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Package</span>]   //navbar-text
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
                l_cHtml += [<td class="pe-2 pb-3">Parent Package</td>]
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

        l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_PACKAGE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function PackageEditFormOnSubmit(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID)

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

l_iPackagePk   := Val(oFcgi:GetInputValue("PackageKey"))

l_iPackageFk_Package  := Val(oFcgi:GetInputValue("ComboPackagePk"))
l_cPackageName        := SanitizeInput(oFcgi:GetInputValue("TextName"))

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
                CustomFieldsSave(par_iApplicationPk,USEDON_PACKAGE,l_iPackagePk)
            endif
        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Delete"   // Package
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveModelDelete(par_iModelPk)
            //_M_
            // l_cErrorMessage := CascadeDeletePackage(par_iModelPk,l_iPackagePk)
            // if empty(l_cErrorMessage)
            //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListPackages/"+par_cURLApplicationLinkCode+"/")
            //     l_cFrom := "Redirect"
            // endif
        else
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
                            CustomFieldsDelete(par_iApplicationPk,USEDON_PACKAGE,l_iPackagePk)
                            if :Delete("118f7bd4-c4fe-4057-8f3f-cd1808808f81","Package",l_iPackagePk)
                                oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListPackages/"+par_cModelLinkUID+"/")
                                l_cFrom := "Redirect"
                            else
                                l_cErrorMessage := "Failed to delete Package"
                            endif
                        else
                            l_cErrorMessage := "Related Package record on file"
                        endif
                    else
                        l_cErrorMessage := "Related Association record on file"
                    endif
                else
                    l_cErrorMessage := "Related Entity record on file"
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
    l_hValues["fk_package"] := l_iPackageFk_Package
    l_hValues["Name"]       := l_cPackageName
    CustomFieldsFormToHash(par_iApplicationPk,USEDON_PACKAGE,@l_hValues)

    l_cHtml += PackageEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cPackageLinkUID,l_cErrorMessage,l_iPackagePk,l_hValues)

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
static function DataTypeListFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID)
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

With Object l_oDB_ListOfDataTypes
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
        :Column("DataType.pk"              ,"fk_entity")
        :Column("CustomField.pk"          ,"CustomField_pk")
        :Column("CustomField.Label"       ,"CustomField_Label")
        :Column("CustomField.Type"        ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI" ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM" ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD" ,"CustomFieldValue_ValueD")
        :Column("upper(CustomField.Name)" ,"tag1")
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
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Modeling/NewDataType/]+par_cModelLinkUID+[/">New Data Type</a>]
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
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"2","3")+[">Data Types (]+Trans(l_nNumberOfDataTypes)+[)</th>]
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
static function DataTypeEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID,par_cErrorText,par_iPk,par_hValues)
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
        l_cHtml += [<span class="navbar-brand ms-3">]+iif(empty(par_iPk),"New","Edit")+[ Data Type</span>]   //navbar-text
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
                l_cHtml += [<td class="pe-2 pb-3">Parent Data Type</td>]
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

        l_cHtml += CustomFieldsBuild(par_iApplicationPk,USEDON_DATATYPE,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]
oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalForms()


return l_cHtml
//=================================================================================================================
static function DataTypeEditFormOnSubmit(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID)

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
                    l_cErrorMessage := "Failed to add Data Type."
                endif
            else
                if :Update(l_iDataTypePk)
                    FixNonNormalizeFieldsInDataType(par_iModelPk)
                else
                    l_cErrorMessage := "Failed to update Data Type."
                endif
            endif

            if empty(l_cErrorMessage)
                CustomFieldsSave(par_iApplicationPk,USEDON_DATATYPE,l_iDataTypePk)
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Delete"   // DataType
    if oFcgi:p_nAccessLevelML >= 5
        if CheckIfAllowDestructiveModelDelete(par_iModelPk)
            //_M_
            // l_cErrorMessage := CascadeDeleteDataType(par_iModelPk,l_iDataTypePk)
            // if empty(l_cErrorMessage)
            //     oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListDataTypes/"+par_cURLApplicationLinkCode+"/")
            //     l_cFrom := "Redirect"
            // endif
        else
            l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("7bd8406b-6477-47ef-b7f9-8a3712c87950","Property")
                :Where("Property.fk_DataType = ^",l_iDataTypePk)
                :SQL()
                if :Tally == 0
                    :Table("e4cca446-b95b-4bb7-85a6-c888ff3a884c","DataType")
                    :Where("DataType.fk_DataType = ^",l_iDataTypePk)
                    :SQL()
                    if :Tally == 0
                        CustomFieldsDelete(par_iApplicationPk,USEDON_DATATYPE,l_iDataTypePk)
                        if :Delete("d95ff462-fd11-4ea8-abde-368ad8c0abd2","DataType",l_iDataTypePk)
                            oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")
                            l_cFrom := "Redirect"
                        else
                            l_cErrorMessage := "Failed to delete Data Type"
                        endif
                    else
                        l_cErrorMessage := "Related Data Type record on file"
                    endif
                else
                    l_cErrorMessage := "Related Property record on file"
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
    l_hValues["fk_DataType"] := l_iDataTypeFk_DataType
    l_hValues["Name"]        := l_cDataTypeName
    l_hValues["Description"] := l_cDataTypeDescription
    CustomFieldsFormToHash(par_iApplicationPk,USEDON_DATATYPE,@l_hValues)

    l_cHtml += DataTypeEditFormBuild(par_iApplicationPk,par_iModelPk,par_cModelLinkUID,par_cDataTypeLinkUID,l_cErrorMessage,l_iDataTypePk,l_hValues)

case empty(l_cFrom) .or. empty(l_iDataTypePk)
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"Modeling/ListDataTypes/"+par_cModelLinkUID+"/")

otherwise
    //Should not happen. Failed :Get.
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================





