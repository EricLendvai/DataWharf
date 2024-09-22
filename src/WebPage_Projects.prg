#include "DataWharf.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())
//=================================================================================================================
function BuildPageProjects()
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

local l_cProjectElement := "SETTINGS"  //Default Element

local l_aSQLResult := {}

local l_cURLAction      := "ListProjects"
local l_cURLUID     := ""
local l_cURLVersionCode := ""

local l_cSitePath := oFcgi:p_cSitePath
local l_lFoundHeaderInfo := .f.

local l_nAccessLevelML := 1   // None by default
// As per the info in Schema.prg
//     1 - None
//     2 - Read Only
//     3 - Edit Description and Information Entries
//     4 - Edit Description and Information Entries and Diagrams
//     5 - Edit Anything
//     7 - Full Access


oFcgi:TraceAdd("BuildPageProjects")

// Variables
// l_cURLAction
// l_cURLVersionCode

//Improved and new way:
// Projects/                      Same as Projects/ListProjects/
// Projects/NewProject/
// Projects/ProjectSettings/<ProjectUID>/
// Projects/ListPrimitiveTypes/<ProjectUID>/
// Projects/NewPrimitiveType/<ProjectUID>/
// Projects/EditPrimitiveType/<PrimitiveTypeUID>

if len(oFcgi:p_aURLPathElements) >= 2 .and. !empty(oFcgi:p_aURLPathElements[2])
    l_cURLAction := oFcgi:p_aURLPathElements[2]

    if len(oFcgi:p_aURLPathElements) >= 3 .and. !empty(oFcgi:p_aURLPathElements[3])
        l_cURLUID := oFcgi:p_aURLPathElements[3]
    endif

    do case
    case el_IsInlist(l_cURLAction,"ProjectSettings","ListPrimitiveTypes","NewPrimitiveType")
        with object l_oDB1
            :Table("a2907501-52d2-43c2-a711-e72dceb91b2b","Project")
            :Column("Project.UID", "Project_UID")     // Redundant but makes it clearer than to use l_cURLUID
            :Column("Project.pk"     , "Project_pk")
            :Column("Project.Name"   , "Project_Name")
            :Where("Project.UID = ^" , l_cURLUID)
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    case el_IsInlist(l_cURLAction,"EditPrimitiveType")
        with object l_oDB1
            :Table("3cb1f9a9-9324-4f2b-962d-7bcc676ede5d","PrimitiveType")
            :Column("PrimitiveType.UID" , "PrimitiveType_UID")    // Redundant but makes it clearer than to use l_cURLUID
            :Column("PrimitiveType.pk"      , "PrimitiveType_pk")
            :Column("Project.UID"       , "Project_UID")
            :Column("Project.pk"            , "Project_pk")
            :Column("Project.Name"          , "Project_Name")
            :Where("PrimitiveType.UID = ^" , l_cURLUID)
            :Join("inner","Project","","PrimitiveType.fk_Project = Project.pk")
            l_oDataHeader := :SQL()
            l_lFoundHeaderInfo := (:Tally == 1)
        endwith

    endcase


    do case
    case el_IsInlist(l_cURLAction,"ProjectSettings")
        l_cProjectElement := "SETTINGS"

    case el_IsInlist(l_cURLAction,"ListPrimitiveTypes","NewPrimitiveType","EditPrimitiveType")
        l_cProjectElement := "PRIMITIVETYPES"

    otherwise
        l_cProjectElement := "SETTINGS"

    endcase


    if l_lFoundHeaderInfo
        l_cProjectName := l_oDataHeader:Project_Name
        l_iProjectPk   := l_oDataHeader:Project_pk

        l_nAccessLevelML := GetAccessLevelMLForProject(l_iProjectPk)
    endif

else
    l_cURLAction := "ListProjects"
endif

if  oFcgi:p_nUserAccessMode >= 3
    oFcgi:p_nAccessLevelML := 7
else
    oFcgi:p_nAccessLevelML := l_nAccessLevelML
endif


do case
case l_cURLAction == "ListProjects"
    l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
    l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Projects</span></div>]
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<div class="px-3 py-2 align-middle"><a class="btn btn-primary rounded align-middle" href="]+l_cSitePath+[Projects/NewProject">New Project</a></div>]
    endif
    l_cHtml += [</div>]

    l_cHtml += ProjectListFormBuild()

case l_cURLAction == "NewProject"
    if oFcgi:p_nUserAccessMode >= 3
        l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
        l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">New Project</span></div>]
        l_cHtml += [</div>]

        if oFcgi:isGet()
            //Brand new request of add an application.
            l_cHtml += ProjectEditFormBuild("",0,{=>})
        else
            l_cHtml += ProjectEditFormOnSubmit("")
        endif
    endif

case l_cURLAction == "ProjectSettings"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += ProjectHeaderBuild(l_iProjectPk,l_cProjectName,l_cProjectElement,l_cSitePath,l_oDataHeader:Project_UID)
        
        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("a11b7e98-4717-40e1-8c81-451656153c5a","public.Project")
                :Column("Project.UseStatus"                     , "Project_UseStatus")
                :Column("Project.Description"                   , "Project_Description")
                :Column("Project.DestructiveDelete"             , "Project_DestructiveDelete")
                :Column("Project.AlternateNameForModel"         , "Project_AlternateNameForModel")
                :Column("Project.AlternateNameForModels"        , "Project_AlternateNameForModels")
                :Column("Project.AlternateNameForEntity"        , "Project_AlternateNameForEntity")
                :Column("Project.AlternateNameForEntities"      , "Project_AlternateNameForEntities")
                :Column("Project.AlternateNameForAssociation"   , "Project_AlternateNameForAssociation")
                :Column("Project.AlternateNameForAssociations"  , "Project_AlternateNameForAssociations")
                :Column("Project.AlternateNameForAttribute"     , "Project_AlternateNameForAttribute")
                :Column("Project.AlternateNameForAttributes"    , "Project_AlternateNameForAttributes")
                :Column("Project.AlternateNameForDataType"      , "Project_AlternateNameForDataType")
                :Column("Project.AlternateNameForDataTypes"     , "Project_AlternateNameForDataTypes")
                :Column("Project.AlternateNameForPackage"       , "Project_AlternateNameForPackage")
                :Column("Project.AlternateNameForPackages"      , "Project_AlternateNameForPackages")
                :Column("Project.AlternateNameForLinkedEntity"  , "Project_AlternateNameForLinkedEntity")
                :Column("Project.AlternateNameForLinkedEntities", "Project_AlternateNameForLinkedEntities")
                :Column("Project.ValidEndpointBoundLowerValues" , "Project_ValidEndpointBoundLowerValues")
                :Column("Project.ValidEndpointBoundUpperValues" , "Project_ValidEndpointBoundUpperValues")

                l_oData := :Get(l_iProjectPk)
            endwith

            if l_oDB1:Tally == 1
                l_hValues["Name"]                          := l_cProjectName
                l_hValues["UseStatus"]                     := l_oData:Project_UseStatus
                l_hValues["Description"]                   := l_oData:Project_Description
                l_hValues["DestructiveDelete"]             := l_oData:Project_DestructiveDelete
                l_hValues["AlternateNameForModel"]         := l_oData:Project_AlternateNameForModel
                l_hValues["AlternateNameForModels"]        := l_oData:Project_AlternateNameForModels
                l_hValues["AlternateNameForEntity"]        := l_oData:Project_AlternateNameForEntity
                l_hValues["AlternateNameForEntities"]      := l_oData:Project_AlternateNameForEntities
                l_hValues["AlternateNameForAssociation"]   := l_oData:Project_AlternateNameForAssociation
                l_hValues["AlternateNameForAssociations"]  := l_oData:Project_AlternateNameForAssociations
                l_hValues["AlternateNameForAttribute"]     := l_oData:Project_AlternateNameForAttribute
                l_hValues["AlternateNameForAttributes"]    := l_oData:Project_AlternateNameForAttributes
                l_hValues["AlternateNameForDataType"]      := l_oData:Project_AlternateNameForDataType
                l_hValues["AlternateNameForDataTypes"]     := l_oData:Project_AlternateNameForDataTypes
                l_hValues["AlternateNameForPackage"]       := l_oData:Project_AlternateNameForPackage
                l_hValues["AlternateNameForPackages"]      := l_oData:Project_AlternateNameForPackages
                l_hValues["AlternateNameForLinkedEntity"]  := l_oData:Project_AlternateNameForLinkedEntity
                l_hValues["AlternateNameForLinkedEntities"]:= l_oData:Project_AlternateNameForLinkedEntities
                l_hValues["ValidEndpointBoundLowerValues"] := l_oData:Project_ValidEndpointBoundLowerValues
                l_hValues["ValidEndpointBoundUpperValues"] := l_oData:Project_ValidEndpointBoundUpperValues

                CustomFieldsLoad(l_iProjectPk,USEDON_PROJECT,l_iProjectPk,@l_hValues)

                l_cHtml += ProjectEditFormBuild("",l_iProjectPk,l_hValues)
            endif
        else
            if l_iProjectPk > 0
                l_cHtml += ProjectEditFormOnSubmit(l_oDataHeader:Project_UID)
            endif
        endif
    endif

case l_cURLAction == "ListPrimitiveTypes"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += ProjectHeaderBuild(l_iProjectPk,l_cProjectName,l_cProjectElement,l_cSitePath,l_oDataHeader:Project_UID)

        if oFcgi:isGet()
            l_cHtml += PrimitiveTypesListFormBuild(l_oDataHeader:Project_pk,l_oDataHeader:Project_UID)
        else
        endif

    endif

case l_cURLAction == "NewPrimitiveType"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += ProjectHeaderBuild(l_iProjectPk,l_cProjectName,l_cProjectElement,l_cSitePath,l_oDataHeader:Project_UID)

        if oFcgi:isGet()
            l_cHtml += PrimitiveTypeEditFormBuild(l_oDataHeader:Project_pk,"",0,{=>})
        else
            l_cHtml += PrimitiveTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_UID)
        endif

    endif

case l_cURLAction == "EditPrimitiveType"
    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += ProjectHeaderBuild(l_iProjectPk,l_cProjectName,l_cProjectElement,l_cSitePath,l_oDataHeader:Project_UID)

        if oFcgi:isGet()
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("837b2a1b-4338-4a75-8eb4-3438a00f7f81","PrimitiveType")
                :Column("PrimitiveType.Name"        , "PrimitiveType_Name")
                :Column("PrimitiveType.Description" , "PrimitiveType_Description")
                l_oData := :Get(l_oDataHeader:PrimitiveType_pk)
            endwith

            l_hValues["Name"]        := l_oData:PrimitiveType_Name
            l_hValues["Description"] := l_oData:PrimitiveType_Description
            l_cHtml += PrimitiveTypeEditFormBuild(l_oDataHeader:Project_pk,"",l_oDataHeader:PrimitiveType_pk,@l_hValues)
        else
            l_cHtml += PrimitiveTypeEditFormOnSubmit(l_oDataHeader:Project_pk,l_oDataHeader:Project_UID)
        endif

    endif

otherwise

endcase

return l_cHtml
//=================================================================================================================
static function ProjectHeaderBuild(par_iProjectPk,par_cProjectName,par_cProjectElement,par_cSitePath,par_cURLProjectUID)
local l_cHtml := ""
local l_oDB1  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aSQLResult := {}
local l_iReccount
local l_cSitePath := oFcgi:p_cSitePath
 
oFcgi:TraceAdd("ProjectHeaderBuild")

// l_cHtml += [<nav class="navbar navbar-default bg-secondary bg-gradient">]
//     l_cHtml += [<div class="input-group">]
//         l_cHtml += [<span class="ps-2 navbar-brand text-white">Manage Project - ]+par_cProjectName+[</span>]
//     l_cHtml += [</div>]
// l_cHtml += [</nav>]

l_cHtml += [<div class="d-flex bg-secondary bg-gradient">]
l_cHtml +=    [<div class="px-3 py-2 align-middle mb-2"><span class="fs-5 text-white">Configure Project: ]+par_cProjectName+[</span></div>]
l_cHtml +=    [<div class="px-3 py-2 align-middle ms-auto"><a class="TopTabs btn btn-primary rounded" href="]+l_cSitePath+[Projects/">Other Projects</a></div>]
l_cHtml += [</div>]

l_cHtml += [<div class="m-3"></div>]

l_cHtml += [<ul class="nav nav-tabs">]

    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cProjectElement == "SETTINGS",[ active],[])+[" href="]+par_cSitePath+[Projects/ProjectSettings/]+par_cURLProjectUID+[/">Project Settings</a>]
        l_cHtml += [</li>]
    endif

    if oFcgi:p_nAccessLevelML >= 7
        l_cHtml += [<li class="nav-item">]
            l_cHtml += [<a class="TopTabs nav-link ]+iif(par_cProjectElement == "PRIMITIVETYPES",[ active],[])+[" href="]+par_cSitePath+[Projects/ListPrimitiveTypes/]+par_cURLProjectUID+[/">Primitive Types</a>]
        l_cHtml += [</li>]
    endif

l_cHtml += [</ul>]

l_cHtml += [<div class="m-3"></div>]  // Spacer

return l_cHtml
//=================================================================================================================                      
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
static function ProjectListFormBuild()
local l_cHtml := []
local l_oDB1
local l_oDB2
local l_cSitePath := oFcgi:p_cSitePath
local l_nNumberOfProjects
local l_nNumberOfCustomFieldValues := 0
local l_hOptionValueToDescriptionMapping := {=>}

oFcgi:TraceAdd("ProjectListFormBuild")

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

with object l_oDB1
    :Table("be95fd34-cf27-4c9a-9f59-195f5f3f6bc1","Project")
    :Column("Project.pk"                ,"pk")
    :Column("Project.Name"              ,"Project_Name")
    :Column("Project.UID"           ,"Project_UID")
    :Column("Project.UseStatus"         ,"Project_UseStatus")
    :Column("Project.Description"       ,"Project_Description")
    :Column("Project.DestructiveDelete" ,"Project_DestructiveDelete")
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
        :Table("edc19c4c-8d92-46ea-9754-29475478fe2f","Project")
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

        :Table("94597e1e-1f50-49da-84a3-4799728b8a78","Project")
        :Column("Project.pk"              ,"fk_entity")
        :Column("CustomField.pk"              ,"CustomField_pk")
        :Column("CustomField.Label"           ,"CustomField_Label")
        :Column("CustomField.Type"            ,"CustomField_Type")
        :Column("CustomFieldValue.ValueI"     ,"CustomFieldValue_ValueI")
        :Column("CustomFieldValue.ValueM"     ,"CustomFieldValue_ValueM")
        :Column("CustomFieldValue.ValueD"     ,"CustomFieldValue_ValueD")
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
                    l_cHtml += [<th class="text-white text-center" colspan="]+iif(l_nNumberOfCustomFieldValues <= 0,"4","5")+[">Projects (]+Trans(l_nNumberOfProjects)+[)</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-primary bg-gradient">]
                    l_cHtml += [<th class="text-white">Name/Manage</th>]
                    l_cHtml += [<th class="text-white">Description</th>]
                    l_cHtml += [<th class="text-white text-center">Usage<br>Status</th>]
                    l_cHtml += [<th class="text-white text-center">Destructive<br>Deletes</th>]
                    if l_nNumberOfCustomFieldValues > 0
                        l_cHtml += [<th class="text-white text-center">Other</th>]
                    endif
                l_cHtml += [</tr>]

                select ListOfProjects
                scan all
                    l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),ListOfProjects->Project_UseStatus)+[>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<a href="]+l_cSitePath+[Projects/ProjectSettings/]+alltrim(ListOfProjects->Project_UID)+[/">]+alltrim(ListOfProjects->Project_Name)+[</a>]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListOfProjects->Project_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"","Proposed","Under Development","Active","To Be Discontinued","Discontinued"}[iif(el_between(ListOfProjects->Project_UseStatus,USESTATUS_UNKNOWN,USESTATUS_DISCONTINUED),ListOfProjects->Project_UseStatus,USESTATUS_UNKNOWN)]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += {"None","On Entities/Associations","Can Delete Models"}[iif(el_between(ListOfProjects->Project_DestructiveDelete,PROJECTDESTRUCTIVEDELETE_NONE,PROJECTDESTRUCTIVEDELETE_CANDELETEMODELS),ListOfProjects->Project_DestructiveDelete,PROJECTDESTRUCTIVEDELETE_NONE)]
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
static function ProjectEditFormBuild(par_cErrorText,par_iPk,par_hValues)

local l_cHtml := ""
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")

local l_cName                          := hb_HGetDef(par_hValues,"Name","")
local l_nUseStatus                     := hb_HGetDef(par_hValues,"UseStatus",USESTATUS_UNKNOWN)
local l_cDescription                   := nvl(hb_HGetDef(par_hValues,"Description",""),"")
local l_nDestructiveDelete             := hb_HGetDef(par_hValues,"DestructiveDelete",PROJECTDESTRUCTIVEDELETE_NONE)
local l_cAlternateNameForModel         := nvl(hb_HGetDef(par_hValues,"AlternateNameForModel"         ,""),"")
local l_cAlternateNameForModels        := nvl(hb_HGetDef(par_hValues,"AlternateNameForModels"        ,""),"")
local l_cAlternateNameForEntity        := nvl(hb_HGetDef(par_hValues,"AlternateNameForEntity"        ,""),"")
local l_cAlternateNameForEntities      := nvl(hb_HGetDef(par_hValues,"AlternateNameForEntities"      ,""),"")
local l_cAlternateNameForAssociation   := nvl(hb_HGetDef(par_hValues,"AlternateNameForAssociation"   ,""),"")
local l_cAlternateNameForAssociations  := nvl(hb_HGetDef(par_hValues,"AlternateNameForAssociations"  ,""),"")
local l_cAlternateNameForAttribute     := nvl(hb_HGetDef(par_hValues,"AlternateNameForAttribute"     ,""),"")
local l_cAlternateNameForAttributes    := nvl(hb_HGetDef(par_hValues,"AlternateNameForAttributes"    ,""),"")
local l_cAlternateNameForDataType      := nvl(hb_HGetDef(par_hValues,"AlternateNameForDataType"      ,""),"")
local l_cAlternateNameForDataTypes     := nvl(hb_HGetDef(par_hValues,"AlternateNameForDataTypes"     ,""),"")
local l_cAlternateNameForPackage       := nvl(hb_HGetDef(par_hValues,"AlternateNameForPackage"       ,""),"")
local l_cAlternateNameForPackages      := nvl(hb_HGetDef(par_hValues,"AlternateNameForPackages"      ,""),"")
local l_cAlternateNameForLinkedEntity  := nvl(hb_HGetDef(par_hValues,"AlternateNameForLinkedEntity"  ,""),"")
local l_cAlternateNameForLinkedEntities:= nvl(hb_HGetDef(par_hValues,"AlternateNameForLinkedEntities",""),"")
local l_cValidEndpointBoundLowerValues := nvl(hb_HGetDef(par_hValues,"ValidEndpointBoundLowerValues" ,""),"")
local l_cValidEndpointBoundUpperValues := nvl(hb_HGetDef(par_hValues,"ValidEndpointBoundUpperValues" ,""),"")

oFcgi:TraceAdd("ProjectEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="TableKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading("Project Settings")

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
        // if empty(par_iPk)
        //     l_cHtml += [<span class="navbar-brand ms-3">New Project</span>]   //navbar-text
        // else
        //     l_cHtml += [<span class="navbar-brand ms-3">Update Project Settings</span>]   //navbar-text
        // endif
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

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Usage Status</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboUseStatus" id="ComboUseStatus">]
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

        l_cHtml += [<tr>]
            l_cHtml += [<td class="pe-2 pb-3">Destructive Deletes</td>]
            l_cHtml += [<td class="pb-3">]
                l_cHtml += [<select]+UPDATE_ONSELECT_SAVEBUTTON+[ name="ComboDestructiveDelete" id="ComboDestructiveDelete">]
                    l_cHtml += [<option value="1"]+iif(l_nDestructiveDelete==1,[ selected],[])+[>None</option>]
                    l_cHtml += [<option value="2"]+iif(l_nDestructiveDelete==2,[ selected],[])+[>On Entities/Associations</option>]
                    l_cHtml += [<option value="3"]+iif(l_nDestructiveDelete==3,[ selected],[])+[>Can Delete Model</option>]
                l_cHtml += [</select>]
            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td colspan="2">]
                l_cHtml += [<div class="pb-3">Alternate Name For</div>]
                l_cHtml += [<div class="ps-3">]
                    l_cHtml += [<table>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3"></td>]
                            l_cHtml += [<td class="pb-3">Singular</td>]
                            l_cHtml += [<td class="pb-3">Plural</td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Model</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForModel"  id="TextAlternateNameForModel"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForModel) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForModels" id="TextAlternateNameForModels" value="]+FcgiPrepFieldForValue(l_cAlternateNameForModels)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Entity</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForEntity"   id="TextAlternateNameForEntity"   value="]+FcgiPrepFieldForValue(l_cAlternateNameForEntity)  +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForEntities" id="TextAlternateNameForEntities" value="]+FcgiPrepFieldForValue(l_cAlternateNameForEntities)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Association</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForAssociation"  id="TextAlternateNameForAssociation"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForAssociation) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForAssociations" id="TextAlternateNameForAssociations" value="]+FcgiPrepFieldForValue(l_cAlternateNameForAssociations)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Attribute</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForAttribute"  id="TextAlternateNameForAttribute"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForAttribute) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForAttributes" id="TextAlternateNameForAttributes" value="]+FcgiPrepFieldForValue(l_cAlternateNameForAttributes)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Data Type</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForDataType"  id="TextAlternateNameForDataType"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForDataType) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForDataTypes" id="TextAlternateNameForDataTypes" value="]+FcgiPrepFieldForValue(l_cAlternateNameForDataTypes)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                            l_cHtml += [<td class="pe-2 pb-3">Package</td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForPackage"  id="TextAlternateNameForPackage"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForPackage) +[" maxlength="80" size="32"></td>]
                            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForPackages" id="TextAlternateNameForPackages" value="]+FcgiPrepFieldForValue(l_cAlternateNameForPackages)+[" maxlength="80" size="32"></td>]
                        l_cHtml += [</tr>]

                        l_cHtml += [<tr>]
                        l_cHtml += [<td class="pe-2 pb-3">Linked Entity</td>]
                        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForLinkedEntity"  id="TextAlternateNameForLinkedEntity"  value="]+FcgiPrepFieldForValue(l_cAlternateNameForLinkedEntity) +[" maxlength="80" size="32"></td>]
                        l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextAlternateNameForLinkedEntities" id="TextAlternateNameForLinkedEntities" value="]+FcgiPrepFieldForValue(l_cAlternateNameForLinkedEntities)+[" maxlength="80" size="32"></td>]
                    l_cHtml += [</tr>]

                    l_cHtml += [</table>]
                l_cHtml += [</div>]

            l_cHtml += [</td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Association End<br><span class="small">Lower Bound Values</span><br><span class="small">Comma-Separated</span></td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextValidEndpointBoundLowerValues" id="TextValidEndpointBoundLowerValues" value="]+FcgiPrepFieldForValue(l_cValidEndpointBoundLowerValues)+[" maxlength="500" size="80"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Association End<br><span class="small">Upper Bound Values</span><br><span class="small">Comma-Separated</span></td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextValidEndpointBoundUpperValues" id="TextValidEndpointBoundUpperValues" value="]+FcgiPrepFieldForValue(l_cValidEndpointBoundUpperValues)+[" maxlength="500" size="80"></td>]
        l_cHtml += [</tr>]

        if !empty(par_iPk)
            l_cHtml += CustomFieldsBuild(par_iPk,USEDON_PROJECT,par_iPk,par_hValues,iif(oFcgi:p_nAccessLevelML >= 5,[],[disabled]))
        endif

    l_cHtml += [</table>]

l_cHtml += [</div>]
 
oFcgi:p_cjQueryScript += [$('#TextName').focus();]

oFcgi:p_cjQueryScript += [$('#TextDescription').resizable();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()

return l_cHtml
//=================================================================================================================
static function ProjectEditFormOnSubmit(par_cURLProjectUID)
local l_cHtml := []
local l_cActionOnSubmit

local l_iProjectPk
local l_cProjectName
local l_cProjectUID := par_cURLProjectUID  //It will be overridden in case of add  - Not used for now since only 1 tab
local l_nProjectUseStatus
local l_cProjectDescription
local l_nProjectDestructiveDelete

local l_cProjectAlternateNameForModel
local l_cProjectAlternateNameForModels
local l_cProjectAlternateNameForEntity
local l_cProjectAlternateNameForEntities
local l_cProjectAlternateNameForAssociation
local l_cProjectAlternateNameForAssociations
local l_cProjectAlternateNameForAttribute
local l_cProjectAlternateNameForAttributes
local l_cProjectAlternateNameForDataType
local l_cProjectAlternateNameForDataTypes
local l_cProjectAlternateNameForPackage
local l_cProjectAlternateNameForPackages
local l_cProjectAlternateNameForLinkedEntity
local l_cProjectAlternateNameForLinkedEntities
local l_cProjectValidEndpointBoundLowerValues
local l_cProjectValidEndpointBoundUpperValues

local l_cProjectValidEndpointBoundLowerValuesFixed
local l_cProjectValidEndpointBoundUpperValuesFixed

local l_cErrorMessage := ""
local l_hValues := {=>}

local l_nAccessLevelML

local l_oDB1
local l_oDB2
local l_oData

oFcgi:TraceAdd("ProjectEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iProjectPk                            := Val(oFcgi:GetInputValue("TableKey"))
l_cProjectName                          := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_nProjectUseStatus                     := Val(oFcgi:GetInputValue("ComboUseStatus"))
l_cProjectDescription                   := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))
l_nProjectDestructiveDelete             := Val(oFcgi:GetInputValue("ComboDestructiveDelete"))
l_cProjectAlternateNameForModel         := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForModel"))
l_cProjectAlternateNameForModels        := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForModels"))
l_cProjectAlternateNameForEntity        := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForEntity"))
l_cProjectAlternateNameForEntities      := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForEntities"))
l_cProjectAlternateNameForAssociation   := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAssociation"))
l_cProjectAlternateNameForAssociations  := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAssociations"))
l_cProjectAlternateNameForAttribute     := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAttribute"))
l_cProjectAlternateNameForAttributes    := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForAttributes"))
l_cProjectAlternateNameForDataType      := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForDataType"))
l_cProjectAlternateNameForDataTypes     := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForDataTypes"))
l_cProjectAlternateNameForPackage       := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForPackage"))
l_cProjectAlternateNameForPackages      := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForPackages"))
l_cProjectAlternateNameForLinkedEntity  := SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForLinkedEntity"))
l_cProjectAlternateNameForLinkedEntities:= SanitizeInput(oFCGI:GetInputValue("TextAlternateNameForLinkedEntities"))
l_cProjectValidEndpointBoundLowerValues := SanitizeInput(oFCGI:GetInputValue("TextValidEndpointBoundLowerValues"))
l_cProjectValidEndpointBoundUpperValues := SanitizeInput(oFCGI:GetInputValue("TextValidEndpointBoundUpperValues"))

l_cProjectValidEndpointBoundLowerValuesFixed := CleanUpBoundValues(l_cProjectValidEndpointBoundLowerValues)
l_cProjectValidEndpointBoundUpperValuesFixed := CleanUpBoundValues(l_cProjectValidEndpointBoundUpperValues)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 7
        do case
        case empty(l_cProjectName)
            l_cErrorMessage := "Missing Name"
        
        case (l_cProjectValidEndpointBoundLowerValuesFixed <> l_cProjectValidEndpointBoundLowerValues) .or. (l_cProjectValidEndpointBoundUpperValuesFixed <> l_cProjectValidEndpointBoundUpperValues)
            l_cErrorMessage := "Fixed Bound Values, please review first."

        otherwise
            l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
            with object l_oDB1
                :Table("b1403658-d289-4af8-b061-a242c93fdfa8","Project")
                :Where([lower(replace(Project.Name,' ','')) = ^],lower(StrTran(l_cProjectName," ","")))
                if l_iProjectPk > 0
                    :Where([Project.pk != ^],l_iProjectPk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            else
                //Save the Project
                with object l_oDB1
                    :Table("b953d374-34e6-40d4-9972-df00d392c54a","Project")
                    :Field("Project.Name"                          , l_cProjectName)
                    :Field("Project.UseStatus"                     , l_nProjectUseStatus)
                    :Field("Project.Description"                   , iif(empty(l_cProjectDescription),NULL,l_cProjectDescription))
                    :Field("Project.DestructiveDelete"             , l_nProjectDestructiveDelete)
                    :Field("Project.AlternateNameForModel"         , iif(empty(l_cProjectAlternateNameForModel)             ,NULL,l_cProjectAlternateNameForModel))
                    :Field("Project.AlternateNameForModels"        , iif(empty(l_cProjectAlternateNameForModels)            ,NULL,l_cProjectAlternateNameForModels))
                    :Field("Project.AlternateNameForEntity"        , iif(empty(l_cProjectAlternateNameForEntity)            ,NULL,l_cProjectAlternateNameForEntity))
                    :Field("Project.AlternateNameForEntities"      , iif(empty(l_cProjectAlternateNameForEntities)          ,NULL,l_cProjectAlternateNameForEntities))
                    :Field("Project.AlternateNameForAssociation"   , iif(empty(l_cProjectAlternateNameForAssociation)       ,NULL,l_cProjectAlternateNameForAssociation))
                    :Field("Project.AlternateNameForAssociations"  , iif(empty(l_cProjectAlternateNameForAssociations)      ,NULL,l_cProjectAlternateNameForAssociations))
                    :Field("Project.AlternateNameForAttribute"     , iif(empty(l_cProjectAlternateNameForAttribute)         ,NULL,l_cProjectAlternateNameForAttribute))
                    :Field("Project.AlternateNameForAttributes"    , iif(empty(l_cProjectAlternateNameForAttributes)        ,NULL,l_cProjectAlternateNameForAttributes))
                    :Field("Project.AlternateNameForDataType"      , iif(empty(l_cProjectAlternateNameForDataType)          ,NULL,l_cProjectAlternateNameForDataType))
                    :Field("Project.AlternateNameForDataTypes"     , iif(empty(l_cProjectAlternateNameForDataTypes)         ,NULL,l_cProjectAlternateNameForDataTypes))
                    :Field("Project.AlternateNameForPackage"       , iif(empty(l_cProjectAlternateNameForPackage)           ,NULL,l_cProjectAlternateNameForPackage))
                    :Field("Project.AlternateNameForPackages"      , iif(empty(l_cProjectAlternateNameForPackages)          ,NULL,l_cProjectAlternateNameForPackages))
                    :Field("Project.AlternateNameForLinkedEntity"  , iif(empty(l_cProjectAlternateNameForLinkedEntity)      ,NULL,l_cProjectAlternateNameForLinkedEntity))
                    :Field("Project.AlternateNameForLinkedEntities", iif(empty(l_cProjectAlternateNameForLinkedEntities)    ,NULL,l_cProjectAlternateNameForLinkedEntities))
                    :Field("Project.ValidEndpointBoundLowerValues" , iif(empty(l_cProjectValidEndpointBoundLowerValuesFixed),NULL,l_cProjectValidEndpointBoundLowerValuesFixed))
                    :Field("Project.ValidEndpointBoundUpperValues" , iif(empty(l_cProjectValidEndpointBoundUpperValuesFixed),NULL,l_cProjectValidEndpointBoundUpperValuesFixed))

                    if empty(l_iProjectPk)
                        l_cProjectUID := oFcgi:p_o_SQLConnection:GetUUIDString()
                        :Field("Project.UID" , l_cProjectUID)
                        if :Add()
                            l_iProjectPk := :Key()
                        else
                            l_cErrorMessage := "Failed to add Project."
                        endif
                    else
                        if :Update(l_iProjectPk)
                            CustomFieldsSave(l_iProjectPk,USEDON_PROJECT,l_iProjectPk)
                            // l_iProjectPk := 0
                        else
                            l_cErrorMessage := "Failed to update Project."
                        endif
                    endif
                endwith
            endif
        endcase
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iProjectPk := 0

case l_cActionOnSubmit == "Delete"   // Project
    if oFcgi:p_nUserAccessMode >= 3
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
        l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)

        with object l_oDB1
            :Table("f0d7e892-f938-48b2-9da5-58ac40b1e3e6","Model")
            :Where("Model.fk_Project = ^",l_iProjectPk)
            :SQL()
            if :Tally != 0
                l_cErrorMessage := "Related Model record on file"
            else

                :Table("f9d28e3f-2f8d-409f-8711-1d0a4715c77d","PrimitiveType")
                :Where("PrimitiveType.fk_Project = ^",l_iProjectPk)
                :SQL()
                if :Tally != 0
                    l_cErrorMessage := "Related Primitive Type record on file"
                else

                    :Table("f9d28e3f-2f8d-409f-8711-1d0a4715c77e","UserAccessProject")
                    :Where("UserAccessProject.fk_Project = ^",l_iProjectPk)
                    :SQL()
                    if :Tally != 0
                        l_cErrorMessage := "Related UserAccessProject record on file"
                    else
                    
                        :Table("f9d28e3f-2f8d-409f-8711-1d0a4715c77f","APITokenAccessProject")
                        :Where("APITokenAccessProject.fk_Project = ^",l_iProjectPk)
                        :SQL()
                        if :Tally != 0
                            l_cErrorMessage := "Related APITokenAccessProject record on file"
                        else
                        
                            CustomFieldsDelete(l_iProjectPk,USEDON_PROJECT,l_iProjectPk)
                            :Delete("853346d3-ece1-4f23-b189-5c70e37a9c6a","Project",l_iProjectPk)
                            l_iProjectPk := 0
                            
                        endif
                    endif
                endif
            endif
        endwith
    endif

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]                          := l_cProjectName
    l_hValues["UseStatus"]                     := l_nProjectUseStatus
    l_hValues["Description"]                   := l_cProjectDescription
    l_hValues["AlternateNameForModel"]         := l_cProjectAlternateNameForModel
    l_hValues["AlternateNameForModels"]        := l_cProjectAlternateNameForModels
    l_hValues["AlternateNameForEntity"]        := l_cProjectAlternateNameForEntity
    l_hValues["AlternateNameForEntities"]      := l_cProjectAlternateNameForEntities
    l_hValues["AlternateNameForAssociation"]   := l_cProjectAlternateNameForAssociation
    l_hValues["AlternateNameForAssociations"]  := l_cProjectAlternateNameForAssociations
    l_hValues["AlternateNameForAttribute"]     := l_cProjectAlternateNameForAttribute
    l_hValues["AlternateNameForAttributes"]    := l_cProjectAlternateNameForAttributes
    l_hValues["AlternateNameForDataType"]      := l_cProjectAlternateNameForDataType
    l_hValues["AlternateNameForDataTypes"]     := l_cProjectAlternateNameForDataTypes
    l_hValues["AlternateNameForPackage"]       := l_cProjectAlternateNameForPackage
    l_hValues["AlternateNameForPackages"]      := l_cProjectAlternateNameForPackages
    l_hValues["AlternateNameForLinkedEntity"]  := l_cProjectAlternateNameForLinkedEntity
    l_hValues["AlternateNameForLinkedEntities"]:= l_cProjectAlternateNameForLinkedEntities
    l_hValues["ValidEndpointBoundLowerValues"] := l_cProjectValidEndpointBoundLowerValuesFixed
    l_hValues["ValidEndpointBoundUpperValues"] := l_cProjectValidEndpointBoundUpperValuesFixed

    CustomFieldsFormToHash(l_iProjectPk,USEDON_PROJECT,@l_hValues)

    l_cHtml += ProjectEditFormBuild(l_cErrorMessage,l_iProjectPk,l_hValues)

case empty(l_iProjectPk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/")

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    if hb_IsNil(l_oDB1)
        l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    endif
    with object l_oDB1
        :Table("48ef14b8-2ded-4f9e-8075-70b2c9ae47a9","Project")
        :Column("Project.UID","Project_UID")
        l_oData := :Get(l_iProjectPk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/ProjectSettings/"+l_oData:Project_UID+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/")
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function PrimitiveTypesListFormBuild(par_iProjectPk,par_Project_UID)
local l_cHtml := []
local l_oDB_ListOfPrimitiveTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cSitePath := oFcgi:p_cSitePath
// local l_oCursor
local l_nNumberOfPrimitiveTypes
local l_iPrimitiveTypePk

oFcgi:TraceAdd("PrimitiveTypesListFormBuild")

with object l_oDB_ListOfPrimitiveTypes
    :Table("ade06ccd-1925-4c3c-bf48-dbbd33ede375","PrimitiveType")
    :Column("PrimitiveType.pk"         ,"pk")
    :Column("PrimitiveType.UID"    ,"PrimitiveType_UID")
    :Column("PrimitiveType.Name"       ,"PrimitiveType_Name")
    :Column("PrimitiveType.Description","PrimitiveType_Description")
    :Column("upper(PrimitiveType.Name)","tag1")
    :Where("PrimitiveType.fk_Project = ^",par_iProjectPk)
    :OrderBy("tag1")
    :SQL("ListOfPrimitiveTypes")
    l_nNumberOfPrimitiveTypes := :Tally
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
                    if oFcgi:p_nAccessLevelML >= 7
                        l_cHtml += [<a class="btn btn-primary rounded ms-3 me-5" href="]+l_cSitePath+[Projects/NewPrimitiveType/]+par_Project_UID+[/]+[">New Primitive Type</a>]
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

if !empty(l_nNumberOfPrimitiveTypes)
    l_cHtml += [<div class="m-3"></div>]   //Spacer

    l_cHtml += [<div class="row justify-content-center m-3">]
        l_cHtml += [<div class="col-auto">]

            l_cHtml += [<table class="table table-sm table-bordered">]   // table-striped
            
            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white text-center" colspan="2">Primitive Types (]+Trans(l_nNumberOfPrimitiveTypes)+[)</th>]
            l_cHtml += [</tr>]

            l_cHtml += [<tr class="bg-primary bg-gradient">]
                l_cHtml += [<th class="text-white">Name</th>]
                l_cHtml += [<th class="text-white">Description</th>]
            l_cHtml += [</tr>]

            select ListOfPrimitiveTypes
            scan all
                l_iPrimitiveTypePk := ListOfPrimitiveTypes->pk

                l_cHtml += [<tr]+GetTRStyleBackgroundColorUseStatus(recno(),0)+[>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += [<a href="]+l_cSitePath+[Projects/EditPrimitiveType/]+ListOfPrimitiveTypes->PrimitiveType_UID+[/">]+ListOfPrimitiveTypes->PrimitiveType_Name+[</a>]
                    l_cHtml += [</td>]

                    l_cHtml += [<td class="GridDataControlCells" valign="top">]
                        l_cHtml += TextToHtml(hb_DefaultValue(ListOfPrimitiveTypes->PrimitiveType_Description,""))
                    l_cHtml += [</td>]

                l_cHtml += [</tr>]
            endscan
            l_cHtml += [</table>]
            
        l_cHtml += [</div>]
    l_cHtml += [</div>]

endif
return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function PrimitiveTypeEditFormBuild(par_iProjectPk,par_cErrorText,par_iPk,par_hValues)
local l_cHtml := ""
local l_cErrorText   := hb_DefaultValue(par_cErrorText,"")

local l_cName        := hb_HGetDef(par_hValues,"Name","")
local l_cDescription := nvl(hb_HGetDef(par_hValues,"Description",""),"")

local l_cSitePath   := oFcgi:p_cSitePath
local l_oDB1        := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("PrimitiveTypeEditFormBuild")

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">]
l_cHtml += [<input type="hidden" name="formname" value="Edit">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]
l_cHtml += [<input type="hidden" name="PrimitiveTypeKey" value="]+trans(par_iPk)+[">]

l_cHtml += DisplayErrorMessageOnEditForm(l_cErrorText)

l_cHtml += GetAboveNavbarHeading(iif(empty(par_iPk),"New","Edit")+[ Primitive Type])

l_cHtml += [<nav class="navbar navbar-light bg-light">]
    l_cHtml += [<div class="input-group">]
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

        l_cHtml += [<tr class="pb-5">]
            l_cHtml += [<td class="pe-2 pb-3">Name</td>]
            l_cHtml += [<td class="pb-3"><input]+UPDATE_ONTEXTINPUT_SAVEBUTTON+[name="TextName" id="TextName" value="]+FcgiPrepFieldForValue(l_cName)+[" maxlength="200" size="80"]+iif(oFcgi:p_nAccessLevelML >= 7,[],[ disabled])+[ class="form-control"></td>]
        l_cHtml += [</tr>]

        l_cHtml += [<tr>]
            l_cHtml += [<td valign="top" class="pe-2 pb-3">Description</td>]
            l_cHtml += [<td class="pb-3"><textarea]+UPDATE_ONTEXTAREA_SAVEBUTTON+[ name="TextDescription" id="TextDescription" rows="4" cols="80">]+FcgiPrepFieldForValue(l_cDescription)+[</textarea></td>]
        l_cHtml += [</tr>]

    l_cHtml += [</table>]
    
l_cHtml += [</div>]

oFcgi:p_cjQueryScript += [$('#TextName').focus();]

l_cHtml += [</form>]

l_cHtml += GetConfirmationModalFormsDelete()


return l_cHtml
//=================================================================================================================
static function PrimitiveTypeEditFormOnSubmit(par_iProjectPk,par_cProjectUID)
local l_cHtml := []

local l_cActionOnSubmit
local l_iPrimitiveTypePk
local l_cPrimitiveTypeName
local l_cPrimitiveTypeDescription
local l_oData
local l_cErrorMessage := ""

local l_hValues := {=>}

local l_oDB1

oFcgi:TraceAdd("PrimitiveTypeEditFormOnSubmit")

l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iPrimitiveTypePk          := Val(oFcgi:GetInputValue("PrimitiveTypeKey"))
l_cPrimitiveTypeName        := SanitizeInput(oFcgi:GetInputValue("TextName"))
l_cPrimitiveTypeDescription := MultiLineTrim(SanitizeInput(oFcgi:GetInputValue("TextDescription")))

l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

do case
case l_cActionOnSubmit == "Save"
    if oFcgi:p_nAccessLevelML >= 7
        if empty(l_cPrimitiveTypeName)
            l_cErrorMessage := "Missing Name"
        else
            with object l_oDB1
                :Table("047eea6b-c1e7-4b50-9e44-56df466cc239","PrimitiveType")
                :Column("PrimitiveType.pk","pk")
                :Where([PrimitiveType.fk_Project = ^],par_iProjectPk)
                :Where([lower(replace(PrimitiveType.Name,' ','')) = ^],lower(StrTran(l_cPrimitiveTypeName," ","")))
                if l_iPrimitiveTypePk > 0
                    :Where([PrimitiveType.pk != ^],l_iPrimitiveTypePk)
                endif
                :SQL()
            endwith

            if l_oDB1:Tally <> 0
                l_cErrorMessage := "Duplicate Name"
            endif

        endif
    endif

    if empty(l_cErrorMessage)
        //Save the PrimitiveType
        with object l_oDB1
            :Table("26d3ff97-f5c5-4b34-9c15-01f34d11d320","PrimitiveType")
            :Field("PrimitiveType.Name"        , l_cPrimitiveTypeName)
            :Field("PrimitiveType.Description" , iif(empty(l_cPrimitiveTypeDescription),NULL,l_cPrimitiveTypeDescription))
            if empty(l_iPrimitiveTypePk)
                :Field("PrimitiveType.UID"    , oFcgi:p_o_SQLConnection:GetUUIDString())
                :Field("PrimitiveType.fk_Project" , par_iProjectPk)
                if :Add()
                    l_iPrimitiveTypePk := :Key()
                else
                    l_cErrorMessage := "Failed to add PrimitiveType."
                endif
            else
                if !:Update(l_iPrimitiveTypePk)
                    l_cErrorMessage := "Failed to update Primitive Type."
                endif
            endif

        endwith
    endif

case l_cActionOnSubmit == "Cancel"

case l_cActionOnSubmit == "Done"
    l_iPrimitiveTypePk := 0

case l_cActionOnSubmit == "Delete"   // PrimitiveType
    if oFcgi:p_nAccessLevelML >= 7
        with object l_oDB1
            :Table("6eac4014-651f-43cc-af7e-976a77a89e75","DataType")
            :Where("DataType.fk_PrimitiveType = ^",l_iPrimitiveTypePk)
            :SQL()

            if :Tally == 0
                :Delete("04faf037-bff8-461a-9d57-c3317b4e10b9","PrimitiveType",l_iPrimitiveTypePk)
                l_iPrimitiveTypePk := 0
                
            else
                l_cErrorMessage := "Related Data Type record on file"
            endif

        endwith
    endif

otherwise
    l_cErrorMessage := "Unknown Option"

endcase

do case
case !empty(l_cErrorMessage)
    l_hValues["Name"]        := l_cPrimitiveTypeName
    l_hValues["Description"] := l_cPrimitiveTypeDescription

    l_cHtml += PrimitiveTypeEditFormBuild(par_iProjectPk,l_cErrorMessage,l_iPrimitiveTypePk,l_hValues)

case empty(l_iPrimitiveTypePk)
    oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/ListPrimitiveTypes/"+par_cProjectUID+"/")

otherwise
    //Since the Name could have change the redirect URL has to be re-evaluated.
    with object l_oDB1
        :Table("6223983f-81d6-4804-8de5-834bc0e38098","PrimitiveType")
        :Column("PrimitiveType.UID","PrimitiveType_UID")
        l_oData := :Get(l_iPrimitiveTypePk)
        if :Tally == 1
            oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/EditPrimitiveType/"+l_oData:PrimitiveType_UID+"/")
            // oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/ListPrimitiveTypes/"+par_cProjectUID+"/")
        else
            oFcgi:Redirect(oFcgi:p_cSitePath+"Projects/ListPrimitiveTypes/"+par_cProjectUID+"/")
        endif
    endif

endcase

return l_cHtml
//=================================================================================================================
static function CleanUpBoundValues(par_cValues)
local l_cResult := ""
local l_cValue
local l_aValues := hb_ATokens(alltrim(nvl(par_cValues,"")),",")

for each l_cValue in l_aValues
    l_cValue := left(alltrim(l_cValue),4)
    if !empty(l_cValue)
        if !empty(l_cResult)
            l_cResult += ","
        endif
        l_cResult += l_cValue
    endif
endfor

return l_cResult
//=================================================================================================================
