#include "DataWharf.ch"

//=================================================================================================================
// Example: /api/GetApplicationInformation
function GetApplicationInformation()

local l_cResponse := {=>}
local l_cThisAppTitle

l_cThisAppTitle := oFcgi:GetAppConfig("APPLICATION_TITLE")
if empty(l_cThisAppTitle)
    l_cThisAppTitle := APPLICATION_TITLE
endif

l_cResponse["ApplicationName"]    := l_cThisAppTitle
l_cResponse["ApplicationVersion"] := BUILDVERSION
l_cResponse["SiteBuildInfo"]      :=hb_buildinfo()

// _M_ Should we also return the PostgreSQL host name and database name?

return hb_jsonEncode(l_cResponse)
//=================================================================================================================

//=================================================================================================================
// Example: /api/projects/v1
function APIGetListOfProjects()

local l_cResponse := ""
local l_cProjectId  := GetAPIURIElement(2)
local l_oDB_ListOfProjects := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfProjects
local l_aListOfProjects := {}
local l_hProjectInfo    := {=>}

with object l_oDB_ListOfProjects
    :Table("493f214c-aa5a-4d63-a465-9d5a4adeaa48","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Project.LinkUID"    ,"Project_LinkUID")
    :Column("Project.UseStatus"  ,"Project_UseStatus")
    :Column("Project.Description","Project_Description")
    :Column("Upper(Project.Name)","tag1")
    if !empty(l_cProjectId)
        :Where("Project.LinkUID = ^", l_cProjectId)
    endif
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfProjects")
    l_nNumberOfProjects := :Tally
endwith

if l_nNumberOfProjects < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 493f214c-aa5a-4d63-a465-9d5a4adeaa48"})
     oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfProjects
    scan all
        hb_HClear(l_hProjectInfo)
        l_hProjectInfo["id"]  := ListOfProjects->Project_LinkUID
        l_hProjectInfo["name"] := ListOfProjects->Project_Name

        AAdd(l_aListOfProjects,hb_hClone(l_hProjectInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cProjectId)
        if l_nNumberOfProjects == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfProjects == 1
            l_cResponse := hb_jsonEncode(l_aListOfProjects[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
            "@recordsetCount" => l_nNumberOfProjects,;
            "items" => l_aListOfProjects;
        })
    endif
endif

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: GET /api/classes/
function APIGetListOfEntities()

local l_cResponse := ""
local l_cEntityId  := GetAPIURIElement(2)
local l_oDB_ListOfEntities              := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfEntitiesAndAttributes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfEntities
local l_aListOfEntities   := {}
local l_hEntityInfo       := {=>}
local l_aListOfAttributes := {}
local l_hAttributesInfo   := {=>}
local l_cModelId         := oFcgi:GetQueryString("model")

with object l_oDB_ListOfEntities
    :Table("9C052CE0-BD88-49B4-B5BD-A85C5A89B549","Entity")
    :Column("Entity.pk"         ,"pk")
    :Column("Entity.Name"       ,"Entity_Name")
    :Column("Entity.LinkUID"    ,"Entity_LinkUID")
    :Column("Entity.Information","Entity_Information")
    :Column("Entity.Description","Entity_Description")
    :Column("Package.LinkUID"    ,"Package_LinkUID")
    :Column("Model.LinkUID"    ,"Model_LinkUID")
    :Column("Upper(Entity.Name)","tag1")
    :Join("left outer","Package","","Entity.fk_Package = Package.pk")
    :Join("inner","Model","","Entity.fk_Model = Model.pk")
    if !empty(l_cEntityId)
        :Where("Entity.LinkUID = ^", l_cEntityId)
    else
        if !empty(l_cModelId)
            :Where("Model.LinkUID = ^", l_cModelId)
        endif
    endif
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfEntities")
    l_nNumberOfEntities := :Tally
endwith

with object l_oDB_ListOfEntitiesAndAttributes
    :Table("9909c890-9078-419e-a6a8-71c778cea5f6","Entity")
    :Column("Attribute.pk"         ,"pk")
    :Column("Entity.pk"            ,"Entity_pk")
    :Column("Attribute.TreeOrder1" ,"tag1")
    :Column("Attribute.Name"       ,"Attribute_Name")
    :Column("Attribute.Description","Attribute_Description")
    :Column("Attribute.BoundLower" ,"Attribute_BoundLower")
    :Column("Attribute.BoundUpper" ,"Attribute_BoundUpper")
    :Column("DataType.Name"        ,"DataType_Name")
    :Join("inner","Attribute","","Attribute.fk_Entity = Entity.pk")
    :Join("inner","DataType","","Attribute.fk_DataType = DataType.pk")
    if !empty(l_cEntityId)
        :Where("Entity.LinkUID = ^", l_cEntityId)
    endif
    :OrderBy("Entity_pk")
    :OrderBy("tag1")
    :SQL("ListOfEntitiesAndAttributes")
endwith

if l_nNumberOfEntities < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 9909c890-9078-419e-a6a8-71c778cea5f6"})
    //set error code to 500
    oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfEntities
    scan all
        l_aListOfAttributes := {}
        select ListOfEntitiesAndAttributes
        scan all for ListOfEntitiesAndAttributes->Entity_pk == ListOfEntities->pk
            hb_HClear(l_hAttributesInfo)
            l_hAttributesInfo["name"] := ListOfEntitiesAndAttributes->Attribute_Name
            l_hAttributesInfo["type"] := ListOfEntitiesAndAttributes->DataType_Name
            if !empty(ListOfEntitiesAndAttributes->Attribute_Description)
                l_hAttributesInfo["description"] := ListOfEntitiesAndAttributes->Attribute_Description
            endif
            if !empty(ListOfEntitiesAndAttributes->Attribute_BoundLower)
                l_hAttributesInfo["lower"] := ListOfEntitiesAndAttributes->Attribute_BoundLower
            endif
            if !empty(ListOfEntitiesAndAttributes->Attribute_BoundUpper)
                l_hAttributesInfo["upper"] := ListOfEntitiesAndAttributes->Attribute_BoundUpper
            endif
            AAdd(l_aListOfAttributes,hb_hClone(l_hAttributesInfo))
        endscan

        hb_HClear(l_hEntityInfo)
        l_hEntityInfo["id"]          := ListOfEntities->Entity_LinkUID
        l_hEntityInfo["name"]        := ListOfEntities->Entity_Name
        if !empty(ListOfEntities->Entity_Description)
            l_hEntityInfo["description"] := ListOfEntities->Entity_Description
        endif
        if !empty(ListOfEntities->Entity_Information)
            l_hEntityInfo["information"] := ListOfEntities->Entity_Information
        endif
        if !empty(ListOfEntities->Package_LinkUID)
            l_hEntityInfo["package"]  := ListOfEntities->Package_LinkUID
        endif
        l_hEntityInfo["model"]  := ListOfEntities->Model_LinkUID
        l_hEntityInfo["properties"]  := l_aListOfAttributes
        
        //add attributes as inner array:
        /*
        {
            "name": "test 2",
            "description": "Lets add some more dexcription jere\r\ndo we also have\r\nmulutple line support?",
            "information": "# Marksodn\r\n- with \r\n- a lost\r\n**for me**\r\nand some\r\n```\r\ncod blocll\r\nthat is here\r\n```",
            "properties": [
                {
                    "name":"property1",
                    "dataType":"string"
                }
            ]
        }
        */
        AAdd(l_aListOfEntities,hb_hClone(l_hEntityInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cEntityId)
        if l_nNumberOfEntities == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfEntities == 1
            l_cResponse := hb_jsonEncode(l_aListOfEntities[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
            "@recordsetCount" => l_nNumberOfEntities,;
            "items" => l_aListOfEntities;
        })
    endif

endif

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: /api/models/
function APIGetListOfModels()

local l_cResponse := ""
local l_cModelId  := GetAPIURIElement(2)
local l_oDB_ListOfModels := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfModels
local l_aListOfModels := {}
local l_hModelInfo    := {=>}

with object l_oDB_ListOfModels
    :Table("d498c464-b815-43eb-8649-5b609219fdba","Model")
    :Column("Model.pk"         ,"pk")
    :Column("Model.Name"       ,"Model_Name")
    :Column("Model.LinkUID"    ,"Model_LinkUID")
    :Column("Model.Stage"  ,"Model_Stage")
    :Column("Model.Description","Model_Description")
    :Column("Upper(Model.Name)","tag1")        
    :OrderBy("tag1")
    if !empty(l_cModelId)
        :Where("Model.LinkUID = ^", l_cModelId)
    endif

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfModels")
    l_nNumberOfModels := :Tally
endwith

if l_nNumberOfModels < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL d498c464-b815-43eb-8649-5b609219fdba"})
    oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfModels
    scan all
        hb_HClear(l_hModelInfo)
        l_hModelInfo["id"]    := ListOfModels->Model_LinkUID
        l_hModelInfo["name"]  := ListOfModels->Model_Name
        l_hModelInfo["stage"] := ListOfModels->Model_Stage
        if !empty(ListOfModels->Model_Description)
            l_hModelInfo["description"] := ListOfModels->Model_Description
        endif

        AAdd(l_aListOfModels,hb_hClone(l_hModelInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cModelId)
        if l_nNumberOfModels == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfModels == 1
            l_cResponse := hb_jsonEncode(l_aListOfModels[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
                "@recordsetCount" => l_nNumberOfModels,;
                "items" => l_aListOfModels;
            })
    endif
endif

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: /api/Packages/
function APIGetListOfPackages()

local l_cResponse := ""
local l_cPackageId  := GetAPIURIElement(2)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfPackages
local l_aListOfPackages := {}
local l_hPackageInfo    := {=>}
local l_cModelId         := oFcgi:GetQueryString("model")

with object l_oDB1
    :Table("8c65edb6-c0ab-43f3-a3eb-92f4c04c4b89","Package")
    :Column("Package.pk"         ,"pk")
    :Column("Package.Name"       ,"Package_Name")
    :Column("Package.LinkUID"    ,"Package_LinkUID")
    :Column("Package.fk_Package"  ,"Package_Parent")
    :Column("Package.fk_Model"  ,"Package_Model")
    :Column("parent.LinkUID"  ,"ParentPackage_LinkUID")
    :Column("Model.LinkUID"  ,"Model_LinkUID")
    //:Column("Package.Description","Package_Description")
    :Join("left outer","Package","parent","Package.fk_Package = parent.pk")
    :Join("inner","Model","","Package.fk_Model = Model.pk")
    if !empty(l_cPackageId)
        :Where("Package.LinkUID = ^", l_cPackageId)
    else
        if !empty(l_cModelId)
            :Where("Model.LinkUID = ^", l_cModelId)
        endif
    endif
    :Column("Upper(Package.Name)","tag1")
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfPackages")
    l_nNumberOfPackages := :Tally
endwith

if l_nNumberOfPackages < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 8c65edb6-c0ab-43f3-a3eb-92f4c04c4b89"})
    oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfPackages
    scan all
        hb_HClear(l_hPackageInfo)
        l_hPackageInfo["id"]  := ListOfPackages->Package_LinkUID
        l_hPackageInfo["name"] := ListOfPackages->Package_Name
        if !empty(ListOfPackages->ParentPackage_LinkUID)
            l_hPackageInfo["parentPackage"] := ListOfPackages->ParentPackage_LinkUID
        endif
        l_hPackageInfo["model"] := ListOfPackages->Model_LinkUID
        //l_hPackageInfo["description"] := ListOfPackages->Package_Description

        AAdd(l_aListOfPackages,hb_hClone(l_hPackageInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cPackageId)
        if l_nNumberOfPackages == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfPackages == 1
            l_cResponse := hb_jsonEncode(l_aListOfPackages[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
                "@recordsetCount" => l_nNumberOfPackages,;
                "items" => l_aListOfPackages;
            })
    endif
endif

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: /api/Associations/
function APIGetListOfAssociations()

local l_cResponse := ""
local l_cAssociationId  := GetAPIURIElement(2)
local l_oDB_ListOfAssociations        := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfAssociationsAndEnds := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfAssociations
local l_nNumberOfAssociationEnds
local l_aListOfAssociations := {}
local l_aListOfAssociationEnds := {}
local l_hAssociationInfo    := {=>}
local l_hAssociationEndsInfo    := {=>}
local l_cModelId         := oFcgi:GetQueryString("model")

with object l_oDB_ListOfAssociations
    :Table("9909c890-9078-419e-a6a8-71c778cea5f6","Association")
    :Column("Association.pk"         ,"pk")
    :Column("Association.Name"       ,"Association_Name")
    :Column("Association.LinkUID"    ,"Association_LinkUID")
    :Column("Association.Description"       ,"Association_Description")
    :Column("Association.fk_Model"  ,"Association_Model")
    :Column("Package.LinkUID"  ,"Package_LinkUID")
    :Column("Model.LinkUID"  ,"Model_LinkUID")
    //:Column("Association.Description","Association_Description")
    :Join("left outer","Package","","Association.fk_Package = Package.pk")
    :Join("inner","Model","","Association.fk_Model = Model.pk")
    if !empty(l_cAssociationId)
        :Where("Association.LinkUID = ^", l_cAssociationId)
    else
        if !empty(l_cModelId)
            :Where("Model.LinkUID = ^", l_cModelId)
        endif
    endif
    :Column("Upper(Association.Name)","tag1")
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfAssociations")
    l_nNumberOfAssociations := :Tally
endwith

if l_nNumberOfAssociations >= 0
    with object l_oDB_ListOfAssociationsAndEnds
        :Table("9909c890-9078-419e-a6a8-71c778cea5f7","Association")
        :Column("Endpoint.pk"            ,"pk")
        :Column("Association.pk"         ,"Association_pk")
        :Column("Endpoint.IsContainment" ,"Endpoint_IsContainment")
        :Column("Endpoint.Name"          ,"Endpoint_Name")
        :Column("Endpoint.Description"   ,"Endpoint_Description")
        :Column("Endpoint.BoundLower"    ,"Endpoint_BoundLower")
        :Column("Endpoint.BoundUpper"    ,"Endpoint_BoundUpper")
        :Column("Entity.LinkUID","Entity_LinkUID")
        :Join("inner","Endpoint","","Endpoint.fk_Association = Association.pk")
        :Join("inner","Entity","","Endpoint.fk_Entity = Entity.pk")
        :OrderBy("Endpoint.pk")
        :OrderBy("tag1")
        :SQL("ListOfAssociationsAndEnds")
        if :Tally < 0
            l_nNumberOfAssociationEnds := :Tally
        endif
    endwith
endif

if l_nNumberOfAssociations < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error","Message"=>"SQL Error in query 9909c890-9078-419e-a6a8-71c778cea5f6"})
    oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfAssociations
    scan all
        l_aListOfAssociationEnds := {}
        select ListOfAssociationsAndEnds
        scan all for ListOfAssociationsAndEnds->Association_pk == ListOfAssociations->pk
            hb_HClear(l_hAssociationEndsInfo)
            if !empty(ListOfAssociationsAndEnds->Endpoint_Name)
                l_hAssociationEndsInfo["name"] := ListOfAssociationsAndEnds->Endpoint_Name
            endif
            l_hAssociationEndsInfo["type"] := ListOfAssociationsAndEnds->Entity_LinkUID
            if !empty(ListOfAssociationsAndEnds->Endpoint_Description)
                l_hAssociationEndsInfo["description"] := ListOfAssociationsAndEnds->Endpoint_Description
            endif
            if !empty(ListOfAssociationsAndEnds->Endpoint_BoundLower)
                l_hAssociationEndsInfo["lower"] := ListOfAssociationsAndEnds->Endpoint_BoundLower
            endif
            if !empty(ListOfAssociationsAndEnds->Endpoint_BoundUpper)
                l_hAssociationEndsInfo["upper"] := ListOfAssociationsAndEnds->Endpoint_BoundUpper
            endif
            AAdd(l_aListOfAssociationEnds,hb_hClone(l_hAssociationEndsInfo))
        endscan
        hb_HClear(l_hAssociationInfo)
        l_hAssociationInfo["id"]  := ListOfAssociations->Association_LinkUID
        l_hAssociationInfo["name"] := ListOfAssociations->Association_Name
        if !empty(ListOfAssociations->Association_Description)
            l_hAssociationInfo["description"] := ListOfAssociations->Association_Description
        endif
        if !empty(ListOfAssociations->Package_LinkUID)
            l_hAssociationInfo["package"] := ListOfAssociations->Package_LinkUID
        endif
        l_hAssociationInfo["model"] := ListOfAssociations->Model_LinkUID
        l_hAssociationInfo["associationEnds"]  := l_aListOfAssociationEnds
        if !empty(ListOfAssociations->Association_Description)
            l_hAssociationInfo["description"] := ListOfAssociations->Association_Description
        endif

        AAdd(l_aListOfAssociations,hb_hClone(l_hAssociationInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cAssociationId)
        if l_nNumberOfAssociations == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfAssociations == 1
            l_cResponse := hb_jsonEncode(l_aListOfAssociations[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
                "@recordsetCount" => l_nNumberOfAssociations,;
                "items" => l_aListOfAssociations;
            })
    endif
endif

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: /api/datatypes/
function APIGetListOfDataTypes()

local l_cResponse := ""
local l_cDataTypeId  := GetAPIURIElement(2)
local l_oDB_ListOfTopDataTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfDataTypes
local l_aListOfDataTypes := {}
local l_hDataTypeInfo    := {=>}
local l_cModelId         := oFcgi:GetQueryString("model")
local l_xSubDataTypes

with object l_oDB_ListOfTopDataTypes
    :Table("8c65edb6-c0ab-43f3-a3eb-92f4c04c4b89","DataType")
    :Column("DataType.pk"         ,"pk")
    :Column("DataType.Name"       ,"DataType_Name")
    :Column("DataType.LinkUID"    ,"DataType_LinkUID")
    :Column("DataType.Description","DataType_Description")
    :Column("PrimitiveType.Name"  ,"PrimitiveType_Name")
    :Column("Model.LinkUID"       ,"Model_LinkUID")
    :Column("DataType.TreeOrder1" ,"tag1")
    //:Column("DataType.Description","DataType_Description")
    :Join("left outer","PrimitiveType","","DataType.fk_PrimitiveType = PrimitiveType.pk")
    :Join("inner","Model","","DataType.fk_Model = Model.pk")
    // :Column("Upper(DataType.Name)","tag1")
    if !empty(l_cDataTypeId)
        :Where("DataType.LinkUID = ^", l_cDataTypeId)
    else
        if !empty(l_cModelId)
            :Where("Model.LinkUID = ^", l_cModelId)
        endif
    endif
    :Where("DataType.TreeLevel = 1")
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfTopDataTypes")
    l_nNumberOfDataTypes := :Tally
endwith

if l_nNumberOfDataTypes < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 8c65edb6-c0ab-43f3-a3eb-92f4c04c4b89"})
    oFcgi:SetHeaderValue("Status","500 Internal Server Error")
else
    select ListOfTopDataTypes
    scan all
        hb_HClear(l_hDataTypeInfo)
        l_hDataTypeInfo["id"]  := ListOfTopDataTypes->DataType_LinkUID
        l_hDataTypeInfo["name"] := ListOfTopDataTypes->DataType_Name
        if !empty(ListOfTopDataTypes->DataType_Description)
            l_hDataTypeInfo["description"] := ListOfTopDataTypes->DataType_Description
        endif
        if !empty(ListOfTopDataTypes->PrimitiveType_Name)
            l_hDataTypeInfo["primitiveType"] := ListOfTopDataTypes->PrimitiveType_Name
        endif
        l_hDataTypeInfo["model"] := ListOfTopDataTypes->Model_LinkUID

        l_xSubDataTypes := BuildDataTypeInfo(ListOfTopDataTypes->pk)
        if !hb_IsNil(l_xSubDataTypes)
            l_hDataTypeInfo["properties"] := l_xSubDataTypes
        endif

        AAdd(l_aListOfDataTypes,hb_hClone(l_hDataTypeInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    if !empty(l_cDataTypeId)
        if l_nNumberOfDataTypes == 0
            oFcgi:SetHeaderValue("Status","404 Not found")
        elseif l_nNumberOfDataTypes == 1
            l_cResponse := hb_jsonEncode(l_aListOfDataTypes[1])
        else
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
            l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
        endif
    else
        l_cResponse := hb_jsonEncode({;
                "@recordsetCount" => l_nNumberOfDataTypes,;
                "items" => l_aListOfDataTypes;
            })
    endif
endif

return l_cResponse
//=================================================================================================================
static function BuildDataTypeInfo(par_DataType_pk)
local l_aInfo
local l_oDB_ListOfAllOtherDataTypes := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_aArray := {}
local l_hDataTypeInfo := {=>}
local l_nLoop
local l_xSubDataTypes
local l_nNumberOfSubDataTypes

with object l_oDB_ListOfAllOtherDataTypes
    :Table("f47732c4-f3e5-4e24-bc0d-ed9ca7114885","DataType")
    :Column("DataType.pk"         ,"pk")                     // 1
    :Column("DataType.Name"       ,"DataType_Name")          // 2
    :Column("DataType.Description","DataType_Description")   // 3
    :Column("PrimitiveType.Name"  ,"PrimitiveType_Name")     // 4
    :Column("DataType.TreeOrder1" ,"tag1")
    :Join("left outer","PrimitiveType","","DataType.fk_PrimitiveType = PrimitiveType.pk")
    :Where("DataType.fk_DataType = ^" , par_DataType_pk)
    :OrderBy("tag1")

    :SQL(@l_aArray)
    l_nNumberOfSubDataTypes := :Tally
    if l_nNumberOfSubDataTypes > 0
        l_aInfo := {}
        ASize(l_aInfo,l_nNumberOfSubDataTypes)

        for l_nLoop = 1 to l_nNumberOfSubDataTypes
            hb_HClear(l_hDataTypeInfo)
            l_hDataTypeInfo["name"] := l_aArray[l_nLoop,2]
            if !empty(l_aArray[l_nLoop,3])
                l_hDataTypeInfo["description"] := l_aArray[l_nLoop,3]
            endif
            if !empty(l_aArray[l_nLoop,4])
                l_hDataTypeInfo["primitiveType"] := l_aArray[l_nLoop,4]
            endif
            l_xSubDataTypes := BuildDataTypeInfo(l_aArray[l_nLoop,1])
            if !hb_IsNil(l_xSubDataTypes)
                l_hDataTypeInfo["properties"] := l_xSubDataTypes
            endif

            l_aInfo[l_nLoop] := hb_hClone(l_hDataTypeInfo)
        endfor

    else
        l_aInfo := NIL
    endif
endwith

return iif(hb_IsNil(l_aInfo),NIL,AClone(l_aInfo)) 
//=================================================================================================================
