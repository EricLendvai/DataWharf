#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"


//=================================================================================================================

// Temp code used during development
// l_cResponse := "Version = "+l_cVersion+CRLF
// l_cResponse += hb_jsonEncode({"FirstName"=>"Eric","LastName"=>"Lendvai"})

//=================================================================================================================
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
// Example: /api/projects/v1
function APIGetListOfProjects()

local l_cResponse := ""
//local l_cVersion  := GetAPIURIElement(2)
local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfProjects
local l_aListOfProjects := {}
local l_hProjectInfo    := {=>}

oFcgi:SetContentType("application/json")

with object l_oDB1
    :Table("493f214c-aa5a-4d63-a465-9d5a4adeaa48","Project")
    :Column("Project.pk"         ,"pk")
    :Column("Project.Name"       ,"Project_Name")
    :Column("Project.LinkUID"    ,"Project_LinkUID")
    :Column("Project.UseStatus"  ,"Project_UseStatus")
    :Column("Project.Description","Project_Description")
    :Column("Upper(Project.Name)","tag1")
    :OrderBy("tag1")

    //_M_ Add access right restrictions
    // if oFcgi:p_nUserAccessMode <= 1
    //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
    //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
    // endif

    :SQL("ListOfProjects")
    
    l_nNumberOfProjects := :Tally

    if l_nNumberOfProjects < 0
        l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
    else
        select ListOfProjects
        scan all
            hb_HClear(l_hProjectInfo)
            l_hProjectInfo["Name"] := ListOfProjects->Project_Name
            l_hProjectInfo["UID"]  := ListOfProjects->Project_LinkUID

            AAdd(l_aListOfProjects,hb_hClone(l_hProjectInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

        endscan
        l_cResponse := hb_jsonEncode({;
                "@recordsetCount" => l_nNumberOfProjects,;
                "items" => l_aListOfProjects;
            })
    endif

endwith

return l_cResponse
//=================================================================================================================

//=================================================================================================================
// Example: GET /api/classes/
function APIGetListOfEntities()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfEntities
    local l_aListOfEntities := {}
    local l_hEntityInfo    := {=>}

    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("9C052CE0-BD88-49B4-B5BD-A85C5A89B549","Entity")
        :Column("Entity.pk"         ,"pk")
        :Column("Entity.Name"       ,"Entity_Name")
        :Column("Entity.LinkUID"    ,"Entity_LinkUID")
        :Column("Entity.Information"  ,"Entity_Information")
        :Column("Entity.Description","Entity_Description")
        :Column("Package.LinkUID"    ,"Package_LinkUID")
        :Column("Model.LinkUID"    ,"Model_LinkUID")
        :Column("Attribute.Name","Attribute_Name")
        :Column("Attribute.BoundLower","Attribute_BoundLower")
        :Column("Attribute.BoundUpper","Attribute_BoundUpper")
        :Column("DataType.Name","DataType_Name")
        :Join("left outer","Package","","Entity.fk_Package = Package.pk")
        :Join("inner","Model","","Entity.fk_Model = Model.pk")
        :Join("left outer","Attribute","","Attribute.fk_Entity = Entity.pk")
        :Join("left outer","DataType","","Attribute.fk_DataType = DataType.pk")
        //:Column("Upper(Project.Name)","tag1")
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfEntities")
        l_nNumberOfEntities := :Tally
    
        if l_nNumberOfEntities < 0
            l_cResponse += hb_jsonEncode({"Error"=>"No Entities"})
            //set error code to 500
        else
            select ListOfEntities
            scan all
                hb_HClear(l_hEntityInfo)
                l_hEntityInfo["id"]  := ListOfEntities->Entity_LinkUID
                l_hEntityInfo["name"] := ListOfEntities->Entity_Name
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
            l_cResponse := hb_jsonEncode(l_aListOfEntities)
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================

       //=================================================================================================================
// Example: /api/models/
function APIGetListOfModels()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfModels
    local l_aListOfModels := {}
    local l_hModelInfo    := {=>}
    
    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("8C65EDB6-C0AB-43F3-A3EB-92F4C04C4B89","Model")
        :Column("Model.pk"         ,"pk")
        :Column("Model.Name"       ,"Model_Name")
        :Column("Model.LinkUID"    ,"Model_LinkUID")
        :Column("Model.Stage"  ,"Model_Stage")
        :Column("Model.Description","Model_Description")
        :Column("Upper(Model.Name)","tag1")        
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfModels")
        
        l_nNumberOfModels := :Tally
    
        if l_nNumberOfModels < 0
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
        else
            select ListOfModels
            scan all
                hb_HClear(l_hModelInfo)
                l_hModelInfo["id"]  := ListOfModels->Model_LinkUID
                l_hModelInfo["name"] := ListOfModels->Model_Name
                l_hModelInfo["stage"] := ListOfModels->Model_Stage
                if !empty(ListOfModels->Model_Description)
                    l_hModelInfo["description"] := ListOfModels->Model_Description
                endif
    
                AAdd(l_aListOfModels,hb_hClone(l_hModelInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.
    
            endscan
            l_cResponse := hb_jsonEncode({;
                        "@recordsetCount" => l_nNumberOfModels,;
                        "items" => l_aListOfModels;
                    })
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================
    //=================================================================================================================
// Example: /api/models/
function APIGetListOfModels()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfModels
    local l_aListOfModels := {}
    local l_hModelInfo    := {=>}
    
    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("8C65EDB6-C0AB-43F3-A3EB-92F4C04C4B89","Model")
        :Column("Model.pk"         ,"pk")
        :Column("Model.Name"       ,"Model_Name")
        :Column("Model.LinkUID"    ,"Model_LinkUID")
        :Column("Model.Stage"  ,"Model_Stage")
        :Column("Model.Description","Model_Description")
        :Column("Upper(Model.Name)","tag1")        
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfModels")
        
        l_nNumberOfModels := :Tally
    
        if l_nNumberOfModels < 0
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
        else
            select ListOfModels
            scan all
                hb_HClear(l_hModelInfo)
                l_hModelInfo["id"]  := ListOfModels->Model_LinkUID
                l_hModelInfo["name"] := ListOfModels->Model_Name
                l_hModelInfo["stage"] := ListOfModels->Model_Stage
                if !empty(ListOfModels->Model_Description)
                    l_hModelInfo["description"] := ListOfModels->Model_Description
                endif
    
                AAdd(l_aListOfModels,hb_hClone(l_hModelInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.
    
            endscan
            l_cResponse := hb_jsonEncode({;
                        "@recordsetCount" => l_nNumberOfModels,;
                        "items" => l_aListOfModels;
                    })
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================
       //=================================================================================================================
// Example: /api/Packages/
function APIGetListOfPackages()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfPackages
    local l_aListOfPackages := {}
    local l_hPackageInfo    := {=>}
    
    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("8C65EDB6-C0AB-43F3-A3EB-92F4C04C4B89","Package")
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
        :Column("Upper(Package.Name)","tag1")
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfPackages")
        
        l_nNumberOfPackages := :Tally
    
        if l_nNumberOfPackages < 0
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
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
            l_cResponse := hb_jsonEncode({;
                        "@recordsetCount" => l_nNumberOfPackages,;
                        "items" => l_aListOfPackages;
                    })
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================

          //=================================================================================================================
// Example: /api/Associations/
function APIGetListOfAssociations()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfAssociations
    local l_aListOfAssociations := {}
    local l_hAssociationInfo    := {=>}
    
    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("8C65EDB6-C0AB-43F3-A3EB-92F4C04C4B89","Association")
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
        :Column("Upper(Association.Name)","tag1")
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfAssociations")
        
        l_nNumberOfAssociations := :Tally
    
        if l_nNumberOfAssociations < 0
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
        else
            select ListOfAssociations
            scan all
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
                //l_hAssociationInfo["description"] := ListOfAssociations->Association_Description
    
                AAdd(l_aListOfAssociations,hb_hClone(l_hAssociationInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.
    
            endscan
            l_cResponse := hb_jsonEncode({;
                        "@recordsetCount" => l_nNumberOfAssociations,;
                        "items" => l_aListOfAssociations;
                    })
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================

             //=================================================================================================================
// Example: /api/datatypes/
function APIGetListOfDataTypes()

    local l_cResponse := ""
    //local l_cVersion  := GetAPIURIElement(2)
    local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
    local l_nNumberOfDataTypes
    local l_aListOfDataTypes := {}
    local l_hDataTypeInfo    := {=>}
    
    oFcgi:SetContentType("application/json")
    
    with object l_oDB1
        :Table("8C65EDB6-C0AB-43F3-A3EB-92F4C04C4B89","DataType")
        :Column("DataType.pk"         ,"pk")
        :Column("DataType.Name"       ,"DataType_Name")
        :Column("DataType.LinkUID"    ,"DataType_LinkUID")
        :Column("DataType.Description"       ,"DataType_Description")
        :Column("PrimitiveType.Name"  ,"PrimitiveType_Name")
        :Column("Model.LinkUID"  ,"Model_LinkUID")
        //:Column("DataType.Description","DataType_Description")
        :Join("left outer","PrimitiveType","","DataType.fk_PrimitiveType = PrimitiveType.pk")
        :Join("inner","Model","","DataType.fk_Model = Model.pk")
        :Column("Upper(DataType.Name)","tag1")
        :OrderBy("tag1")
    
        //_M_ Add access right restrictions
        // if oFcgi:p_nUserAccessMode <= 1
        //     :Join("inner","UserAccessProject","","UserAccessProject.fk_Project = Project.pk")
        //     :Where("UserAccessProject.fk_User = ^",oFcgi:p_iUserPk)
        // endif
    
        :SQL("ListOfDataTypes")
        
        l_nNumberOfDataTypes := :Tally
    
        if l_nNumberOfDataTypes < 0
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error"})
        else
            select ListOfDataTypes
            scan all
                hb_HClear(l_hDataTypeInfo)
                l_hDataTypeInfo["id"]  := ListOfDataTypes->DataType_LinkUID
                l_hDataTypeInfo["name"] := ListOfDataTypes->DataType_Name
                if !empty(ListOfDataTypes->DataType_Description)
                    l_hDataTypeInfo["description"] := ListOfDataTypes->DataType_Description
                endif
                if !empty(ListOfDataTypes->PrimitiveType_Name)
                    l_hDataTypeInfo["primitiveType"] := ListOfDataTypes->PrimitiveType_Name
                endif
                l_hDataTypeInfo["model"] := ListOfDataTypes->Model_LinkUID
                //l_hDataTypeInfo["description"] := ListOfDataTypes->DataType_Description
    
                AAdd(l_aListOfDataTypes,hb_hClone(l_hDataTypeInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.
    
            endscan
            l_cResponse := hb_jsonEncode({;
                        "@recordsetCount" => l_nNumberOfDataTypes,;
                        "items" => l_aListOfDataTypes;
                    })
        endif
    
    endwith
    
    return l_cResponse
    //=================================================================================================================