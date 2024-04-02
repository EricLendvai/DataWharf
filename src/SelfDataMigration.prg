#include "DataWharf.ch"
//=================================================================================================================
//Code used to apply data versioning to DataWharf's own database
function SelfDataMigration()

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB2 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iCurrentDataVersion := oFcgi:p_o_SQLConnection:GetSchemaDefinitionVersion("Core")
local l_cVisPos
local l_cTableName
local l_cName
local l_cColumnName

with object oFcgi:p_o_SQLConnection
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 1
        with object l_oDB1
            :Table("58b648b9-ec53-40ba-8e29-a8b4e99beb36","Diagram")
            :Column("Diagram.pk" , "pk")
            :Where([Length(Trim(Diagram.LinkUID)) = 0])
            :SQL("ListOfDiagramToUpdate")
            select ListOfDiagramToUpdate
            scan all
                with object l_oDB2
                    :Table("c8e52a98-8b65-4632-8241-efc426025ca6","Diagram")
                    :Field("Diagram.LinkUID" , oFcgi:p_o_SQLConnection:GetUUIDString())
                    :Update(ListOfDiagramToUpdate->pk)
                endwith
            endscan
        endwith
        l_iCurrentDataVersion := 1
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 4
        if :TableExists("public.Property")
            :DeleteTable("public.Property")
        endif

        if :TableExists("public.PropertyColumnMapping")
            :DeleteTable("public.PropertyColumnMapping")
        endif

        if :FieldExists("public.Model","fk_Application")
            :DeleteField("public.Model","fk_Application")
        endif

        if :FieldExists("public.UserAccessApplication","AccessLevelML")
            :DeleteField("public.UserAccessApplication","AccessLevelML")
        endif

        if :FieldExists("public.UserAccessApplication","AccessLevel")
            with object l_oDB1
                :Table("bcc58496-5077-47ee-a955-fa5d071dd576","UserAccessApplication")
                :Column("UserAccessApplication.pk"         ,"pk")
                :Column("UserAccessApplication.AccessLevel","UserAccessApplication_AccessLevel")
                :SQL("ListOfRecordsToFix")
                select ListOfRecordsToFix
                scan all for ListOfRecordsToFix->UserAccessApplication_AccessLevel > 0
                    with object l_oDB2
                        :Table("d4a5eada-fd4c-4d6c-ae2e-446f45be2f19","UserAccessApplication")
                        :Field("UserAccessApplication.AccessLevelDD" , ListOfRecordsToFix->UserAccessApplication_AccessLevel)
                        :Field("UserAccessApplication.AccessLevel"   , 0)
                        :Update(ListOfRecordsToFix->pk)
                    endwith
                endscan
            endwith

            :DeleteField("public.UserAccessApplication","AccessLevel")
        endif

        l_iCurrentDataVersion := 4
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 5
        if :FieldExists("public.UserAccessApplication","AccessLevel")
            :DeleteField("public.UserAccessApplication","AccessLevel")
        endif
        l_iCurrentDataVersion := 5
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 6
        if :TableExists("public.AssociationEnd")
            :DeleteTable("public.AssociationEnd")
        endif
        l_iCurrentDataVersion := 6
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 7
        if :FieldExists("public.Attribute","fk_Association")
            :DeleteField("public.Attribute","fk_Association")
        endif

        l_iCurrentDataVersion := 7
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 8
        if :TableExists("public.ConceptualDiagram")
            :DeleteTable("public.ConceptualDiagram")
        endif
        if :FieldExists("public.DiagramEntity","fk_ConceptualDiagram")
            :DeleteField("public.DiagramEntity","fk_ConceptualDiagram")
        endif
        l_iCurrentDataVersion := 8
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 9
        with object l_oDB1
            :Table("dcbb495b-7a14-4ba0-9d2b-eefc5a41fac3","ModelingDiagram")
            :Column("ModelingDiagram.pk" , "pk")
            :Where([Length(Trim(ModelingDiagram.LinkUID)) = 0])
            :SQL("ListOfModelingDiagramToUpdate")
            select ListOfModelingDiagramToUpdate
            scan all
                with object l_oDB2
                    :Table("214e97ca-df84-4b5a-bf7d-f4a1ba22b24e","ModelingDiagram")
                    :Field("ModelingDiagram.LinkUID" , oFcgi:p_o_SQLConnection:GetUUIDString())
                    :Update(ListOfModelingDiagramToUpdate->pk)
                endwith
            endscan
        endwith
        l_iCurrentDataVersion := 9
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 10
        if :FieldExists("public.Entity","Scope") .and. :FieldExists("public.Entity","Information")

            with object l_oDB1

                :Table("bcc58496-5077-47ee-a955-fa5d071dd576","Entity")
                :Column("Entity.pk"   ,"pk")
                :Column("Entity.Scope","Entity_Scope")
                :SQL("ListOfRecordsToFix")
                select ListOfRecordsToFix
                scan all for len(nvl(ListOfRecordsToFix->Entity_Scope,"")) > 0
                    with object l_oDB2
                        :Table("12140112-62ef-49c7-84db-c79c859d31f8","Entity")
                        :Field("Entity.Information" , ListOfRecordsToFix->Entity_Scope)
                        :Update(ListOfRecordsToFix->pk)
                    endwith
                endscan

            endwith

            :DeleteField("public.Entity","Scope")
        endif
        l_iCurrentDataVersion := 10
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 11
        if :FieldExists("public.Attribute","Order") .and. :FieldExists("public.Attribute","TreeOrder1")

            with object l_oDB1

                :Table("405e7421-717f-45cf-b108-3f758b5d05b3","Attribute")
                :Column("Attribute.pk"   ,"pk")
                :Column("Attribute.Order","Attribute_Order")
                :SQL("ListOfRecordsToFix")
                select ListOfRecordsToFix
                scan all
                    with object l_oDB2
                        :Table("dcbff351-7f65-416c-854e-94028fc5c67e","Attribute")
                        :Field("Attribute.TreeOrder1" , ListOfRecordsToFix->Attribute_Order)
                        :Update(ListOfRecordsToFix->pk)
                    endwith
                endscan

            endwith

            :DeleteField("public.Attribute","Order")
        endif
        l_iCurrentDataVersion := 11
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 14
        with object l_oDB1
            :Table("bb6ceea9-72f0-471f-b555-0affd9359cb3","Diagram")
            :Column("Diagram.pk"     , "pk")
            :Column("Diagram.VisPos" , "Diagram_VisPos")
            :Where([Diagram.VisPos is not null])
            :Where([Diagram.VisPos not like '%T%'])
            :SQL("ListOfDiagramToUpdate")
            select ListOfDiagramToUpdate
            scan all
                l_cVisPos := Strtran(ListOfDiagramToUpdate->Diagram_VisPos,[{"x],chr(1))
                l_cVisPos := Strtran(l_cVisPos,[,"y],chr(2))
                l_cVisPos := Strtran(l_cVisPos,[{"],[{"T])
                l_cVisPos := Strtran(l_cVisPos,[,"],[,"T])
                l_cVisPos := Strtran(l_cVisPos,chr(1),[{"x])
                l_cVisPos := Strtran(l_cVisPos,chr(2),[,"y])

                with object l_oDB2
                    :Table("ed4bed4f-30d0-4dd7-9639-4314e80c0cd5","Diagram")
                    :Field("Diagram.VisPos" , l_cVisPos)
                    :Update(ListOfDiagramToUpdate->pk)
                endwith
            endscan
        endwith

        l_iCurrentDataVersion := 14
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 15
        with object l_oDB1
            :Table("6a473090-8c14-47f7-a1dc-95f79a4e45b4","Diagram")
            :Column("Diagram.pk" , "pk")
            :Where([Diagram.RenderMode = 0])
            :SQL("ListOfDiagramToUpdate")
            select ListOfDiagramToUpdate
            scan all
                with object l_oDB2
                    :Table("ed08301f-15d4-4ae4-b7b1-838974333135","Diagram")
                    :Field("Diagram.RenderMode" , RENDERMODE_VISJS)
                    :Update(ListOfDiagramToUpdate->pk)
                endwith
            endscan
        endwith

        l_iCurrentDataVersion := 15
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 16
        with object l_oDB1
            For each l_cTableName in {"Application","Column","Diagram","Enumeration","EnumValue","Index","Namespace","Project","Table","Association","Attribute","DataType","Entity","ModelEnumeration","ModelingDiagram","Package"}
                :Table("28f6f015-c468-4199-a5d2-c25dee474fff",l_cTableName)
                :Column(l_cTableName+".pk" , "pk")

                :Where(l_cTableName+[.UseStatus = 0])
                :SQL("ListOfRecordsToUpdate")
                select ListOfRecordsToUpdate
                scan all
                    with object l_oDB2
                        :Table("091cf769-4ced-4276-be6b-cf7dc50dd546",l_cTableName)
                        :Field(l_cTableName+".UseStatus" , USESTATUS_UNKNOWN)
                        :Update(ListOfRecordsToUpdate->pk)
                    endwith
                endscan
            endfor
        endwith

        l_iCurrentDataVersion := 17
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    // Skipped version 17 since changed logic from "l_iCurrentDataVersion <=" to "l_iCurrentDataVersion <"
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 18
        with object l_oDB1
            :Table("5de9d15e-1af2-4f12-9762-ffdfc779a750","EnumValue")
            :Column("EnumValue.Pk"   , "Pk")
            :Column("EnumValue.Name" , "EnumValue_Name")
            :SQL("ListOfRecordsToUpdate")
            select ListOfRecordsToUpdate
            scan all
                l_cName := SanitizeInputAlphaNumeric(ListOfRecordsToUpdate->EnumValue_Name)
                if !(ListOfRecordsToUpdate->EnumValue_Name == l_cName)
                    with object l_oDB2
                        :Table("1b2715fd-fad5-4c0d-a24a-f8b5c4b21be6","EnumValue")
                        :Field("EnumValue.Name" , l_cName)
                        :Update(ListOfRecordsToUpdate->pk)
                    endwith
                endif
            endscan
        endwith

        l_iCurrentDataVersion := 18
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 19
        if :FieldExists("public.Application","AllowDestructiveDelete")
            :DeleteField("public.Application","AllowDestructiveDelete")
        endif

        l_iCurrentDataVersion := 19
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 20
        if :FieldExists("public.Model","AllowDestructiveDelete")
            :DeleteField("public.Model","AllowDestructiveDelete")
        endif

        l_iCurrentDataVersion := 20
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 21
        if :TableExists("public.Version")
            :DeleteTable("public.Version")
        endif

        l_iCurrentDataVersion := 21
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 22
        with object l_oDB1
            :Table("6dd31de7-15fb-4388-ae7b-9578fb8407b2","UserSetting")
            :Column("UserSetting.pk" , "pk")
            :Where([UserSetting.ValueType = 0])
            :SQL("ListOfUserSettingToUpdate")
            select ListOfUserSettingToUpdate
            scan all
                with object l_oDB2
                    :Table("c35a9c9b-eced-4121-aabe-3adf4fa73678","UserSetting")
                    :Field("UserSetting.ValueType" , 1)
                    :Update(ListOfUserSettingToUpdate->pk)
                endwith
            endscan
        endwith

        l_iCurrentDataVersion := 22
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 23
        with object l_oDB1
            For each l_cTableName in {"Column","Index","TemplateColumn"}
                :Table("288ea878-51a6-48b7-9fb0-1c417ff28276",l_cTableName)
                :Column(l_cTableName+".pk" , "pk")

                :Where(l_cTableName+[.UsedBy = 0])
                :SQL("ListOfRecordsToUpdate")
                select ListOfRecordsToUpdate
                scan all
                    with object l_oDB2
                        :Table("8f7f9c0d-b9db-42c7-ac9f-ee08085e59ea",l_cTableName)
                        :Field(l_cTableName+".UsedBy" , USEDBY_ALLSERVERS)
                        :Update(ListOfRecordsToUpdate->pk)
                    endwith
                endscan
            endfor
        endwith

        l_iCurrentDataVersion := 23
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    // Skipped Version 24 During Coding
    if l_iCurrentDataVersion < 25
        for each l_cTableName in {"Column","TemplateColumn"}
            if :FieldExists("public."+l_cTableName,"Primary") .and. :FieldExists("public."+l_cTableName,"UsedAs")

                with object l_oDB1

                    :Table("6b7d02de-44b0-43a8-8830-2d51481c984f",l_cTableName)
                    :Column(l_cTableName+".pk"     ,"pk")
                    :Column(l_cTableName+".Primary","Primary")
                    if l_cTableName == "Column"
                        :Column(l_cTableName+".fk_TableForeign" ,"fk_TableForeign")
                    endif
                    :Column(l_cTableName+".UsedAs"     ,"UsedAs")
                    :SQL("ListOfRecordsToFix")
                    select ListOfRecordsToFix
                    scan all for ListOfRecordsToFix->UsedAs = 0
                        with object l_oDB2
                            :Table("aa892b84-4e5d-44b3-aa8b-3295b845b79b",l_cTableName)

                            if (l_cTableName == "Column") .and. nvl(ListOfRecordsToFix->fk_TableForeign,0) > 0
                                :Field(l_cTableName+".UsedAs" , 3)
                            else
                                :Field(l_cTableName+".UsedAs" , iif(ListOfRecordsToFix->Primary,2,1))
                            endif
                            
                            :Update(ListOfRecordsToFix->pk)
                        endwith
                    endscan

                endwith

                :DeleteField("public."+l_cTableName,"Primary")
            endif
        endfor
        l_iCurrentDataVersion := 25
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 26
        for each l_cTableName in {"Column","TemplateColumn"}
            if :FieldExists("public."+l_cTableName,"Default")       .and. ;
            :FieldExists("public."+l_cTableName,"DefaultPreset") .and. ;
            :FieldExists("public."+l_cTableName,"DefaultType")   .and. ;
            :FieldExists("public."+l_cTableName,"DefaultCustom")

                with object l_oDB1

                    :Table("c0032c60-0265-4d75-949b-769b5a77d140",l_cTableName)
                    :Column(l_cTableName+".pk"           ,"pk")
                    :Column(l_cTableName+".Type"         ,"Type")
                    :Column(l_cTableName+".Default"      ,"Default")
                    :Column(l_cTableName+".UsedAs"       ,"UsedAs")
                    :SQL("ListOfRecordsToFix")
                    select ListOfRecordsToFix
                    scan all
                        with object l_oDB2
                            :Table("5454c915-b133-4f11-92d3-cc8c847ad2e4",l_cTableName)

                            if !empty(nvl(ListOfRecordsToFix->Default,""))
                                :Field(l_cTableName+".DefaultType"   , 1)
                                :Field(l_cTableName+".DefaultCustom" , ListOfRecordsToFix->Default)
                            else
                                :Field(l_cTableName+".DefaultType" , 0)
                            endif
                            
                            :Update(ListOfRecordsToFix->pk)
                        endwith
                    endscan

                endwith

                :DeleteField("public."+l_cTableName,"DefaultPreset")
                :DeleteField("public."+l_cTableName,"Default")
            endif
        endfor
        l_iCurrentDataVersion := 26
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 27
        for each l_cTableName in {"TemplateColumn"}
            for each l_cColumnName in {"ForeignKeyUse","ForeignKeyOptional","OnDelete","Required","Primary"}
                if :FieldExists("public."+l_cTableName,l_cColumnName)
                    :DeleteField("public."+l_cTableName,l_cColumnName)
                endif
            endfor
        endfor
        l_iCurrentDataVersion := 27
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    // if l_iCurrentDataVersion < 28
    //     l_iCurrentDataVersion := 28
    //     :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    // endif
    //Skipped Version 28 and merged all actions in Version 29
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 29

        :ForeignKeyConvertAllZeroToNull(oFcgi:p_o_SQLConnection:p_hWharfConfig["Tables"])
        :DeleteAllOrphanRecords( oFcgi:p_o_SQLConnection:p_hWharfConfig["Tables"] )

        for each l_cTableName in {"Application"}
            for each l_cColumnName in {"PrimaryKeyDefaultInteger",;
                                    "PrimaryKeyDefaultUUID",;
                                    "PrimaryKeyType",;
                                    "ForeignKeyTypeMatchPrimaryKey",;
                                    "ForeignKeyIsNullable",;
                                    "ForeignKeyNoDefault",;
                                    "TestIdentifierMaxLengthAsPostgres",;
                                    "TestMaxEnumerationNameLength",;
                                    "TestMaxColumnNameLength",;
                                    "TestMaxIndexNameLength"}
                if :FieldExists("public."+l_cTableName,l_cColumnName)
                    :DeleteField("public."+l_cTableName,l_cColumnName)
                endif
            endfor
        endfor

        if :FieldExists("public.Column","PrimaryMode")
            :DeleteField("public.Column","PrimaryMode")
        endif

        if :FieldExists("public.TemplateColumn","PrimaryMode")
            :DeleteField("public.TemplateColumn","PrimaryMode")
        endif

        l_iCurrentDataVersion := 29
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 30
        with object l_oDB1
            For each l_cTableName in {"Namespace","Table","Column","Enumeration","EnumValue","Index","TemplateTable","TemplateColumn","Tag"}
                :Table("f9be0f0b-1a63-4442-a7e4-89cf2ce1745a",l_cTableName)
                :Column(l_cTableName+".pk" , "pk")

                :Where([Length(Trim(]+l_cTableName+[.LinkUID)) = 0])
                :SQL("ListOfRecordsToUpdate")
                select ListOfRecordsToUpdate
                scan all
                    with object l_oDB2
                        :Table("6480d156-77ad-43b1-880e-4f5a3aaa9c8f",l_cTableName)
                        :Field(l_cTableName+".LinkUID" , :GetUUIDString())
                        :Update(ListOfRecordsToUpdate->pk)
                    endwith
                endscan
            endfor
        endwith
        l_iCurrentDataVersion := 30
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    if l_iCurrentDataVersion < 31
        For each l_cTableName in {"NamespacePreviousName","TablePreviousName","ColumnPreviousName","EnumerationPreviousName","EnumValuePreviousName"}
            if :TableExists(l_cTableName+".DateTime")
                :DeleteTable(l_cTableName+".DateTime")
            endif
        endfor

        l_iCurrentDataVersion := 31   // UPDATE THE CODE BELOW AS WELL GetLatestDataVersionNumber()
        :SetSchemaDefinitionVersion("Core",l_iCurrentDataVersion)
    endif
    //-----------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------
    //:RemoveWharfForeignKeyConstraints( oFcgi:p_o_SQLConnection:p_hWharfConfig["Tables"] )
    :MigrateForeignKeyConstraints( oFcgi:p_o_SQLConnection:p_hWharfConfig["Tables"] )
    //-----------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------

endwith

return l_iCurrentDataVersion
//=================================================================================================================
function GetLatestDataVersionNumber()
return 31
//=================================================================================================================
