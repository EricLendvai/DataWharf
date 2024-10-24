#include "DataWharf.ch"

//=================================================================================================================
// Example: /api/GetDataWharfInformation
function APIGetDataWharfInformation(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)

local l_cResponse := {=>}

l_cResponse["ApplicationName"]    := oFcgi:p_cThisAppTitle
l_cResponse["ApplicationVersion"] := BUILDVERSION
l_cResponse["SiteBuildInfo"]      :=hb_buildinfo()

// _M_ Should we also return the PostgreSQL host name and database name?

return hb_jsonEncode(l_cResponse)
//=================================================================================================================


//=================================================================================================================
// Example: /api/applications
function APIGetListOfApplications(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)

local l_cResponse := ""
// local l_cApplicationLinkCode  := oFcgi:GetQueryString("application")
local l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfApplications
local l_aListOfApplications := {}
local l_hApplicationInfo    := {=>}

with object l_oDB_ListOfApplications
    :Table("730e57e0-6b4d-44b4-bf30-f4ef93ce4694","Application")
    :Column("Application.pk"         ,"pk")
    :Column("Application.LinkCode"   ,"Application_LinkCode")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Application.UseStatus"  ,"Application_UseStatus")
    :Column("Application.Description","Application_Description")
    :Column("Upper(Application.Name)","tag1")
    // if !empty(l_cApplicationLinkCode)
    //     :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
    // endif
    :OrderBy("tag1")

    :SQL("ListOfApplications")
    l_nNumberOfApplications := :Tally
endwith

if l_nNumberOfApplications < 0
    l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 730e57e0-6b4d-44b4-bf30-f4ef93ce4694"})
     oFcgi:SetHeaderValue("Status","400 Internal Server Error")
else
    select ListOfApplications
    scan all
        hb_HClear(l_hApplicationInfo)
        l_hApplicationInfo["linkcode"]  := ListOfApplications->Application_LinkCode
        l_hApplicationInfo["name"] := ListOfApplications->Application_Name

        AAdd(l_aListOfApplications,hb_hClone(l_hApplicationInfo))   //Have to clone the Hash Array since only references would be added to the top array, and thus would be overwritten during next scan loop.

    endscan
    // if !empty(l_cApplicationLinkCode)
    //     if l_nNumberOfApplications == 0
    //         oFcgi:SetHeaderValue("Status","404 Not found")
    //     elseif l_nNumberOfApplications == 1
    //         l_cResponse := hb_jsonEncode(l_aListOfApplications[1])
    //     else
    //         oFcgi:SetHeaderValue("Status","400 Internal Server Error")
    //         l_cResponse += hb_jsonEncode({"Error"=>"Id is not unique"})
    //     endif
    // else
        l_cResponse := hb_jsonEncode({;
            "@recordsetCount" => l_nNumberOfApplications,;
            "items" => l_aListOfApplications;
        })
    // endif
endif

return l_cResponse
//=================================================================================================================
// Example: /api/application_harbour_schema_export
function APIGetApplicationHarbourConfigurationExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)
local l_cResponse
l_cResponse := APIGetApplicationSchemaExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode,"Harbour")
return l_cResponse
//=================================================================================================================
function APIGetApplicationJSONConfigurationExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)
local l_cResponse
l_cResponse := APIGetApplicationSchemaExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode,"JSON")
return l_cResponse
//=================================================================================================================
// Example: /api/application_harbour_schema_export
static function APIGetApplicationSchemaExport(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode,par_cTarget)

local l_cResponse := ""
local l_cApplicationLinkCode   := oFcgi:GetQueryString("application")
local l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfApplications
local l_cMacro
local l_hWharfConfig

if par_nTokenAccessMode == 1 .and. !APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAccessToken,par_cAPIEndpointName,l_cApplicationLinkCode)
    l_cResponse := "Access Denied"
else
    //par_nTokenAccessMode will be more than 1 (Read Only and Full Access) if is not application accessible.
    if empty(l_cApplicationLinkCode)
        l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Missing LinkCode parameter"})
        oFcgi:SetHeaderValue("Status","500 Internal Server Error")
    else
        with object l_oDB_ListOfApplications
            :Table("750c8b4a-11ad-4cb6-a805-dc6d45f1b1a1","Application")
            :Column("Application.pk" ,"pk")
            if !empty(l_cApplicationLinkCode)
                :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
            endif

            :SQL("ListOfApplications")
            l_nNumberOfApplications := :Tally
        endwith

        if l_nNumberOfApplications != 1
            l_cResponse += hb_jsonEncode({"Error"=>"SQL Error", "Message"=>"Failed SQL 750c8b4a-11ad-4cb6-a805-dc6d45f1b1a1"})
            oFcgi:SetHeaderValue("Status","500 Internal Server Error")
        else
            do case
            case par_cTarget == "Harbour"
                l_cResponse := ExportApplicationToHarbour_ORM(ListOfApplications->pk,.f.,"PostgreSQL")
            case par_cTarget == "JSON"
                l_cMacro := ExportApplicationToHarbour_ORM(ListOfApplications->pk,.f.,"PostgreSQL")
                l_cMacro := Strtran(l_cMacro,chr(13),"")
                l_cMacro := Strtran(l_cMacro,chr(10),"")
                l_cMacro := Strtran(l_cMacro,[;],"")
                l_hWharfConfig := &( l_cMacro )

                l_cResponse += hb_jsonEncode(l_hWharfConfig,.t.)
            endcase
        endif
    endif
endif

return l_cResponse
//=================================================================================================================
// Example: /api/CreateUpdateNamespaces/
function APICreateUpdateNamespaces(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)
local l_cResponse := ""
local l_hResponse := {=>}
local l_cApplicationLinkCode   := oFcgi:GetQueryString("ApplicationLinkCode")
local l_oDB_ListOfNamespaces
local l_oDB_ListOfApplications
local l_nNumberOfApplications
local l_iNamespacePk
local l_iApplicationPk := 0
local l_iExternalId
local l_cNamespaceName
local l_cNamespaceAKA
local l_cNamespaceDescription
local l_cUseStatus
local l_nUseStatus
local l_cDocStatus
local l_nDocStatus
local l_oData

local l_lUsingInputArray
local l_nNamespaceCounter := 0
local l_xInput
local l_aInput := {}
local l_hJsonInput
local l_nAddedRecords := 0
local l_nUpdatedRecords := 0
local l_nWhereNumber

local l_cFatalErrorMessage := ""
local l_aErrorMessages     := {}  // Will include a list of up to one error per Namespace.
local l_cErrorMessage             // To view error message when getting input from JSON

//_M_ Using GetFieldInfo(par_cNamespaceAndTableName,par_cFieldName)  test we will not have an overflow.

if par_nTokenAccessMode == 1 .and. !APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAccessToken,par_cAPIEndpointName,l_cApplicationLinkCode)
    l_cFatalErrorMessage := "Access Denied or Invalid ApplicationLinkCode"
else
    //par_nTokenAccessMode will be more than 1 (Read Only and Full Access) if is not application accessible.
    if empty(l_cApplicationLinkCode)
        l_cFatalErrorMessage := "Missing Application Code parameter"
    else
        l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfApplications
            :Table("129d8815-e38f-40b0-b54f-21e77b6e01b8","Application")
            :Column("Application.pk"         ,"pk")
            :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
            :SQL("ListOfApplications")
            l_nNumberOfApplications := :Tally
        endwith

        if l_nNumberOfApplications <> 1
            l_cFatalErrorMessage := "Failed to locate application with Code: "+l_cApplicationLinkCode
        else
            l_iApplicationPk := ListOfApplications->pk

            l_xInput := oFcgi:GetJsonInput()

            l_lUsingInputArray := (ValType(l_xInput) == "A")
            if l_lUsingInputArray
                l_aInput := l_xInput
            else
                AAdd(l_aInput,l_xInput)
            endif

            for each l_hJsonInput in l_aInput
                if !empty(l_cFatalErrorMessage)
                    exit
                endif
                l_nNamespaceCounter++
            
                if el_AUnpack(FetchJSonInput(l_hJsonInput,"ExternalId","N",0,.f.,.f.),,@l_iExternalId,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif
                
                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Name","C","",.t.,.f.),,@l_cNamespaceName,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"AKA","C",NULL,.f.,.t.),,@l_cNamespaceAKA,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Description","M",NULL,.f.,.t.),,@l_cNamespaceDescription,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"UseStatus","C","Unknown",.f.,.f.),,@l_cUseStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nUseStatus := GetUseStatusFromText(l_cUseStatus)
                if el_AUnpack(FetchJSonInput(l_hJsonInput,"DocStatus","C","Missing",.f.,.f.),,@l_cDocStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nDocStatus := GetDocStatusFromText(l_cDocStatus)

                do case
                case l_iExternalId < 0
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". ExternalId must be a positive value.")
                    loop
                case empty(l_cNamespaceName)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". Missing Name value.")
                    loop
                case empty(l_nUseStatus)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". Invalid Use Status.")
                    loop
                case empty(l_nDocStatus)
                    AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". Invalid Doc Status.")
                    loop
                otherwise
                    l_oDB_ListOfNamespaces := hb_SQLData(oFcgi:p_o_SQLConnection)
                    //Find if the Namespace with the provided ExternalId already exists.
                    with object l_oDB_ListOfNamespaces
                        :Table("cd06f703-dc07-4ad2-b6da-341fe1db9b4f","Namespace")
                        :Column("Namespace.pk"          ,"Namespace_pk")
                        :Column("Namespace.Name"        ,"Namespace_Name")
                        :Column("Namespace.Aka"         ,"Namespace_Aka")
                        :Column("Namespace.Description" ,"Namespace_Description")
                        :Column("Namespace.UseStatus"   ,"Namespace_UseStatus")
                        :Column("Namespace.DocStatus"   ,"Namespace_DocStatus")
                        :Column("Namespace.ExternalId"  ,"Namespace_ExternalId")
                        :Where("Namespace.fk_Application = ^",l_iApplicationPk)
                        if l_iExternalId > 0
                            l_nWhereNumber := :Where("Namespace.ExternalId = ^" , l_iExternalId)
                        else
                            :Where("lower(replace(Namespace.Name,' ','')) = ^" , lower(StrTran(l_cNamespaceName," ","")))
                        endif
                        l_oData := :SQL()
                        if :Tally < 0
                            l_cFatalErrorMessage := "Failed to query Namespaces."
                            loop
                        endif

                        if :Tally == 0 .and. l_iExternalId > 0
                            //Check if we can find the entry by searching by Name instead.
                            :ReplaceWhere(l_nWhereNumber, "lower(replace(Namespace.Name,' ','')) = ^" , lower(StrTran(l_cNamespaceName," ","")) )
                            l_oData := :SQL()   // Rerun the query
                            if :Tally < 0
                                l_cFatalErrorMessage := "Failed to query Namespaces."
                                loop
                            endif
                        endif

                        do case
                        case :Tally == 0
                            l_iNamespacePk := 0
                        case :Tally == 1
                            l_iNamespacePk := l_oData:Namespace_pk
                        case :Tally > 1
                            AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". More than one Namespace was found.")
                            loop
                        otherwise
                            AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". Failed to query Namespaces.")
                            loop
                        endcase
                        
                        //Test to avoid duplicates.

                        :Table("d1fae57a-7cd8-43be-bc59-95805e03d47a","Namespace")
                        :Where([lower(replace(Namespace.Name,' ','')) = ^],lower(StrTran(l_cNamespaceName," ","")))
                        :Where([Namespace.fk_Application = ^],l_iApplicationPk)
                        if l_iNamespacePk > 0
                            :Where([Namespace.pk != ^],l_iNamespacePk)
                        endif
                        :SQL()
                        if (:Tally <> 0)
                            AAdd(l_aErrorMessages,"Namespace entry "+trans(l_nNamespaceCounter)+". Duplicate Name.")
                            loop
                        endif

                        if l_iExternalId == 0
                            l_iExternalId := NULL
                        endif

                        //Test something changed.
                        if !empty(l_iNamespacePk) .and. l_cNamespaceName        == l_oData:Namespace_Name ;
                                                    .and. l_cNamespaceAKA         == l_oData:Namespace_Aka ;
                                                    .and. CompareDescriptionField(l_cNamespaceDescription,l_oData:Namespace_Description) ;
                                                    .and. l_nUseStatus            == l_oData:Namespace_UseStatus ;
                                                    .and. l_nDocStatus            == l_oData:Namespace_DocStatus ;
                                                    .and. l_iExternalId           == l_oData:Namespace_ExternalId
                            //Nothing Changed
                        else
                            :Table("5b1c224e-aa5a-4e5c-8b6f-8bb3a62379a1","Namespace")
                            :Field("Namespace.Name"            ,l_cNamespaceName)
                            // :Field("Namespace.TrackNameChanges",l_lNamespaceTrackNameChanges)
                            :Field("Namespace.AKA"             ,l_cNamespaceAKA)
                            :Field("Namespace.UseStatus"       ,l_nUseStatus)
                            :Field("Namespace.DocStatus"       ,l_nDocStatus)
                            :Field("Namespace.Description"     ,l_cNamespaceDescription)
                            :Field("Namespace.ExternalId"      ,l_iExternalId)

                            if empty(l_iNamespacePk)
                                :Field("Namespace.fk_Application" ,l_iApplicationPk)
                                :Field("Namespace.UID"            ,oFcgi:p_o_SQLConnection:GetUUIDString())
                                if :Add()
                                    l_nAddedRecords++
                                    l_iNamespacePk := :Key()
                                else
                                    l_cFatalErrorMessage := "Failed to add Namespace."
                                    loop
                                endif
                            else
                                if :Update(l_iNamespacePk)
                                    l_nUpdatedRecords++
                                else
                                    l_cFatalErrorMessage := "Failed to update Namespace."
                                    loop
                                endif
                                // SendToClipboard(:LastSQL())
                            endif
                        endif

                        
                    endwith
                endcase

            endfor

        endif
    endif
endif

return FinalizeCreateUpdateAPIResponse(l_hResponse,l_cFatalErrorMessage,l_aErrorMessages,l_nAddedRecords,l_nUpdatedRecords,l_iApplicationPk)
//=================================================================================================================
// Example: /api/CreateUpdateEnumerations/
function APICreateUpdateEnumerations(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)
local l_cResponse := ""
local l_hResponse := {=>}
local l_cApplicationLinkCode   := oFcgi:GetQueryString("ApplicationLinkCode")
local l_oDB_ListOfApplications
local l_oDB_ListOfNamespaces
local l_oDB_ListOfEnumerations
local l_oDB_ListOfEnumValues
local l_oDB_RecordOfEnumValue
local l_nNumberOfApplications
local l_nNumberOfNamespaces
local l_iNamespacePk
local l_iEnumerationPk
local l_iApplicationPk := 0
local l_cNamespaceName
local l_iExternalId
local l_cEnumerationName
local l_cEnumerationAKA
local l_cEnumerationDescription
local l_cUseStatus
local l_nUseStatus
local l_cDocStatus
local l_nDocStatus
local l_oData
local l_cImplementAs
local l_nImplementAs
local l_nImplementLength

local l_lUsingInputArray
local l_nEnumerationCounter := 0
local l_xInput
local l_aInput := {}
local l_hJsonInput
local l_nAddedRecords := 0
local l_nUpdatedRecords := 0

local l_iEnumValuePk
local l_hValue
local l_nEnumValueOrder
local l_nEnumValueNumber
local l_cEnumValueName
local l_cEnumValueAKA
local l_cEnumValueCode
local l_cEnumValueDescription
local l_nWhereNumber
local l_lFound

local l_cFatalErrorMessage := ""
local l_aErrorMessages     := {}  // Will include a list of up to one error per Namespace.
local l_cErrorMessage             // To view error message when getting input from JSON

//_M_ Using GetFieldInfo(par_cNamespaceAndTableName,par_cFieldName)  test we will not have an overflow.

if par_nTokenAccessMode == 1 .and. !APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAccessToken,par_cAPIEndpointName,l_cApplicationLinkCode)
    l_cFatalErrorMessage := "Access Denied or Invalid ApplicationLinkCode"
else
    //par_nTokenAccessMode will be more than 1 (Read Only and Full Access) if is not application accessible.
    if empty(l_cApplicationLinkCode)
        l_cFatalErrorMessage := "Missing Application Code parameter"
    else
        l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfApplications
            :Table("8febd906-030b-4330-af0b-4b5eab00b38a","Application")
            :Column("Application.pk"         ,"pk")
            :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
            :SQL("ListOfApplications")
            l_nNumberOfApplications := :Tally
        endwith

        if l_nNumberOfApplications <> 1
            l_cFatalErrorMessage := "Failed to locate application with Code: "+l_cApplicationLinkCode
        else
            l_iApplicationPk := ListOfApplications->pk

            l_oDB_ListOfEnumValues  := hb_SQLData(oFcgi:p_o_SQLConnection)
            l_oDB_RecordOfEnumValue := hb_SQLData(oFcgi:p_o_SQLConnection)

            l_xInput := oFcgi:GetJsonInput()

            l_lUsingInputArray := (ValType(l_xInput) == "A")
            if l_lUsingInputArray
                l_aInput := l_xInput
            else
                AAdd(l_aInput,l_xInput)
            endif

            for each l_hJsonInput in l_aInput
                if !empty(l_cFatalErrorMessage)
                    exit
                endif
                l_nEnumerationCounter++

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"NamespaceName","C","",.t.,.f.),,@l_cNamespaceName,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"ExternalId","N",0,.f.,.f.),,@l_iExternalId,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Name","C","",.t.,.f.),,@l_cEnumerationName,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"AKA","C",NULL,.f.,.t.),,@l_cEnumerationAKA,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Description","M",NULL,.f.,.t.),,@l_cEnumerationDescription,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"UseStatus","C","Unknown",.f.,.f.),,@l_cUseStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nUseStatus := GetUseStatusFromText(l_cUseStatus)
                if el_AUnpack(FetchJSonInput(l_hJsonInput,"DocStatus","C","Missing",.f.,.f.),,@l_cDocStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nDocStatus := GetDocStatusFromText(l_cDocStatus)

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"ImplementAs","C","",.f.,.f.),,@l_cImplementAs,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nImplementAs := GetEnumerationImplementAsFromText(l_cImplementAs)

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"ImplementLength","N",NULL,.f.,.f.),,@l_nImplementLength,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". "+l_cErrorMessage)
                    loop
                endif

                do case
                case empty(l_cNamespaceName)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Missing NamespaceName.")
                    loop
                case l_iExternalId < 0
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". ExternalId must be a positive value.")
                    loop
                case empty(l_cEnumerationName)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Missing Name.")
                    loop
                case empty(l_nUseStatus)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Invalid Use Status.")
                    loop
                case empty(l_nDocStatus)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Invalid Doc Status.")
                    loop
                case empty(l_nImplementAs)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Invalid of missing ImplementAs.")
                    loop
                case (l_nImplementAs == 3 .or. l_nImplementAs == 4) .and. hb_IsNil(l_nImplementLength)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Missing ImplementLength.")
                    loop
                case (l_nImplementAs == 3 .or. l_nImplementAs == 4) .and. (l_nImplementLength <= 0 .or. l_nImplementLength > 99999)
                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Invalid ImplementLength.")
                    loop
                otherwise
                    l_oDB_ListOfNamespaces := hb_SQLData(oFcgi:p_o_SQLConnection)

                    //Find if the Namespace with the provided NamespaceName.
                    with object l_oDB_ListOfNamespaces
                        :Table("4049fc83-c273-4ea5-9aa6-7250c564231b","Namespace")
                        :Column("Namespace.pk" ,"Namespace_pk")
                        :Where("Namespace.fk_Application = ^",l_iApplicationPk)
                        :Where("lower(trim(Namespace.name)) = ^",lower(l_cNamespaceName))
                        :SQL("ListOfNamespaces")
                        l_nNumberOfNamespaces := :Tally
                    endwith

                    if l_nNumberOfNamespaces <> 1
                        AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Failed to find Namespace.")
                        loop
                    else
                        l_oDB_ListOfEnumerations := hb_SQLData(oFcgi:p_o_SQLConnection)
                        l_iNamespacePk := ListOfNamespaces->Namespace_pk

                        //Find if the Enumeration with the provided ExternalId already exists.
                        with object l_oDB_ListOfEnumerations
                            :Table("0f301ee0-58f4-4a25-bfa4-65f5455015c8","Enumeration")
                            :Column("Enumeration.pk"             ,"Enumeration_pk")
                            :Column("Enumeration.Name"           ,"Enumeration_Name")
                            :Column("Enumeration.Aka"            ,"Enumeration_Aka")
                            :Column("Enumeration.Description"    ,"Enumeration_Description")
                            :Column("Enumeration.UseStatus"      ,"Enumeration_UseStatus")
                            :Column("Enumeration.DocStatus"      ,"Enumeration_DocStatus")
                            :Column("Enumeration.ImplementAs"    ,"Enumeration_ImplementAs")
                            :Column("Enumeration.ImplementLength","Enumeration_ImplementLength")
                            :Column("Enumeration.ExternalId"  ,"Enumeration_ExternalId")
                            :Where("Enumeration.fk_Namespace = ^",l_iNamespacePk)
                            if l_iExternalId > 0
                                l_nWhereNumber := :Where("Enumeration.ExternalId = ^" , l_iExternalId)
                            else
                                :Where("lower(replace(Enumeration.Name,' ','')) = ^" , lower(StrTran(l_cEnumerationName," ","")))
                            endif
                            l_oData := :SQL()
                            if :Tally < 0
                                l_cFatalErrorMessage := "Failed to query Enumeration."
                                loop
                            endif

                            if :Tally == 0 .and. l_iExternalId > 0
                                //Check if we can find the entry by searching by Name instead.
                                :ReplaceWhere(l_nWhereNumber, "lower(replace(Enumeration.Name,' ','')) = ^" , lower(StrTran(l_cEnumerationName," ","")) )
                                l_oData := :SQL()   // Rerun the query
                                if :Tally < 0
                                    l_cFatalErrorMessage := "Failed to query Enumeration."
                                    loop
                                endif
                            endif

                            do case
                            case :Tally == 0
                                l_iEnumerationPk := 0
                            case :Tally == 1
                                l_iEnumerationPk := l_oData:Enumeration_pk
                            case :Tally > 1
                                AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". More than one Enumeration was found.")
                                loop
                            otherwise
                                l_cFatalErrorMessage := "Enumeration entry "+trans(l_nEnumerationCounter)+". Failed to query Enumerations"
                                loop
                            endcase

                            //Test to avoid duplicates.
                            :Table("75149c50-10ce-4ee5-81ca-450efc2d2e96","Enumeration")
                            :Where([lower(replace(Enumeration.Name,' ','')) = ^],lower(StrTran(l_cEnumerationName," ","")))
                            :Where([Enumeration.fk_Namespace = ^],l_iNamespacePk)
                            if l_iEnumerationPk > 0
                                :Where([Enumeration.pk != ^],l_iEnumerationPk)
                            endif
                            :SQL()
                            if (:Tally <> 0)
                                AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Duplicate Name.")
                                loop
                            endif

                            if l_iExternalId == 0
                                l_iExternalId := NULL
                            endif

                            //Test something changed.
                            if !empty(l_iEnumerationPk) .and. l_cEnumerationName        == l_oData:Enumeration_Name ;
                                                        .and. l_cEnumerationAKA         == l_oData:Enumeration_Aka ;
                                                        .and. CompareDescriptionField(l_cEnumerationDescription,l_oData:Enumeration_Description) ;
                                                        .and. l_nUseStatus              == l_oData:Enumeration_UseStatus ;
                                                        .and. l_nDocStatus              == l_oData:Enumeration_DocStatus ;
                                                        .and. l_nImplementAs            == l_oData:Enumeration_ImplementAs ;
                                                        .and. l_nImplementLength        == l_oData:Enumeration_ImplementLength ;
                                                        .and. l_iExternalId             == l_oData:Enumeration_ExternalId
                                //Nothing Changed
                            else
                                :Table("5806ac8c-c75b-465b-a017-7d445653a8cc","Enumeration")
                                :Field("Enumeration.Name"            ,l_cEnumerationName)
                                // :Field("Enumeration.TrackNameChanges",l_lEnumerationTrackNameChanges)
                                :Field("Enumeration.AKA"             ,l_cEnumerationAKA)
                                :Field("Enumeration.UseStatus"       ,l_nUseStatus)
                                :Field("Enumeration.DocStatus"       ,l_nDocStatus)
                                :Field("Enumeration.Description"     ,l_cEnumerationDescription)
                                :Field("Enumeration.ImplementAs"     ,l_nImplementAs)
                                :Field("Enumeration.ImplementLength" ,l_nImplementLength)
                                :Field("Enumeration.ExternalId"      ,l_iExternalId)

                                if empty(l_iEnumerationPk)
                                    :Field("Enumeration.fk_Namespace" ,l_iNamespacePk)
                                    // :Field("Enumeration.UID"          ,oFcgi:p_o_SQLConnection:GetUUIDString())     // Will be set via default value instead
                                    if :Add()
                                        l_nAddedRecords++
                                        l_iEnumerationPk := :Key()
                                    else
                                        l_cFatalErrorMessage := "Failed to add Enumeration."
                                        loop
                                    endif
                                else
                                    if :Update(l_iEnumerationPk)
                                        l_nUpdatedRecords++
                                    else
                                        l_cFatalErrorMessage := "Failed to update Enumeration."
                                        loop
                                    endif
                                    // SendToClipboard(:LastSQL())
                                endif
                            endif
                            
                        endif
                    endwith

                    if empty(l_cFatalErrorMessage) .and. l_iEnumerationPk > 0
                        with object l_oDB_ListOfEnumValues
                            :Table("31c87228-8099-400f-a8a1-543b42f1bd19","EnumValue")
                            :Column("EnumValue.pk"               ,"pk")
                            :Column("EnumValue.Order"            ,"EnumValue_Order")
                            :Column("EnumValue.Number"           ,"EnumValue_Number")
                            // :Column("EnumValue.UID"          ,"EnumValue_UID")
                            :Column("EnumValue.Name"             ,"EnumValue_Name")
                            // :Column("EnumValue.TrackNameChanges" ,"EnumValue_TrackNameChanges")
                            :Column("EnumValue.AKA"              ,"EnumValue_AKA")
                            :Column("EnumValue.Code"             ,"EnumValue_Code")
                            :Column("EnumValue.Description"      ,"EnumValue_Description")
                            :Column("EnumValue.UseStatus"        ,"EnumValue_UseStatus")
                            :Column("EnumValue.DocStatus"        ,"EnumValue_DocStatus")
                            :Column("EnumValue.ExternalId"       ,"EnumValue_ExternalId")
                            // :Column("EnumValue.TestWarning"      ,"EnumValue_TestWarning")
                            :Column("0"                          ,"Processed")
                            :Where("EnumValue.fk_Enumeration = ^",l_iEnumerationPk)
                            :OrderBy("EnumValue_Order")
                            :SQL("ListOfEnumValues")
                        endwith
                        if l_oDB_ListOfEnumValues:Tally < 0
                            l_cFatalErrorMessage := "Failed to get list of Enumeration Values."
                            loop
                        else
                            l_nEnumValueOrder := 0
                            for each l_hValue in hb_hGetDef(l_hJsonInput,"Values",{})
                                if !empty(l_cFatalErrorMessage)
                                    exit
                                endif
                                l_nEnumValueOrder++

                                if el_AUnpack(FetchJSonInput(l_hValue,"Number","N",NULL,.f.,.f.),,@l_nEnumValueNumber,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"ExternalId","N",0,.f.,.f.),,@l_iExternalId,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"Name","C","",.t.,.f.),,@l_cEnumValueName,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"AKA","C",NULL,.f.,.t.),,@l_cEnumValueAKA,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"Code","C",NULL,.f.,.t.),,@l_cEnumValueAKA,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"Description","M",NULL,.f.,.t.),,@l_cEnumValueDescription,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hValue,"UseStatus","C","Unknown",.f.,.f.),,@l_cUseStatus,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nUseStatus := GetUseStatusFromText(l_cUseStatus)
                                if el_AUnpack(FetchJSonInput(l_hValue,"DocStatus","C","Missing",.f.,.f.),,@l_cDocStatus,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nDocStatus := GetDocStatusFromText(l_cDocStatus)

                                do case
                                case l_iExternalId < 0
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". ExternalId must be a positive value.")
                                    loop
                                case empty(l_cEnumValueName)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". Missing Name value.")
                                    loop
                                case empty(l_nUseStatus)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". Invalid Use Status.")
                                    loop
                                case empty(l_nDocStatus)
                                    AAdd(l_aErrorMessages,"Enumeration entry "+trans(l_nEnumerationCounter)+". Value entry "+trans(l_nEnumValueOrder)+". Invalid Doc Status.")
                                    loop
                                otherwise
                                    select ListOfEnumValues

                                    if l_iExternalId > 0
                                        locate for nvl(ListOfEnumValues->EnumValue_ExternalId,0) == l_iExternalId
                                        l_lFound := found()
                                    else
                                        l_lFound := .f.
                                    endif
                                    if !l_lFound
                                        locate for lower(strtran(ListOfEnumValues->EnumValue_Name," ","")) == lower(strtran(l_cEnumValueName," ",""))
                                        l_lFound := found()
                                    endif
                                    
                                    if l_lFound
                                        ListOfEnumValues->Processed := 1
                                        l_iEnumValuePk := ListOfEnumValues->Pk
                                    else
                                        l_iEnumValuePk := 0
                                    endif

                                    if l_iExternalId == 0
                                        l_iExternalId := NULL
                                    endif

                                    if !empty(l_iEnumValuePk) .and. l_nEnumValueNumber        == ListOfEnumValues->EnumValue_Number      ;
                                                              .and. l_nEnumValueOrder         == ListOfEnumValues->EnumValue_Order       ;
                                                              .and. l_cEnumValueName          == ListOfEnumValues->EnumValue_Name        ;
                                                              .and. l_cEnumValueAKA           == ListOfEnumValues->EnumValue_AKA         ;
                                                              .and. l_cEnumValueCode          == ListOfEnumValues->EnumValue_Code        ;
                                                              .and. CompareDescriptionField(l_cEnumValueDescription,ListOfEnumValues->EnumValue_Description) ;
                                                              .and. l_nUseStatus              == ListOfEnumValues->EnumValue_UseStatus   ;
                                                              .and. l_nDocStatus              == ListOfEnumValues->EnumValue_DocStatus   ;
                                                              .and. l_iExternalId             == ListOfEnumValues->EnumValue_ExternalId
                                        //Nothing Changed
                                    else
                                        with object l_oDB_RecordOfEnumValue
                                            :Table("a45cfcbb-3ae5-478b-82cb-82535ca6c82c","EnumValue")
                                            :Field("EnumValue.Number"          ,l_nEnumValueNumber)
                                            :Field("EnumValue.Order"           ,l_nEnumValueOrder)
                                            :Field("EnumValue.Name"            ,l_cEnumValueName)
                                            :Field("EnumValue.AKA"             ,l_cEnumValueAKA)
                                            :Field("EnumValue.Code"            ,l_cEnumValueCode)
                                            :Field("EnumValue.Description"     ,l_cEnumValueDescription)
                                            :Field("EnumValue.UseStatus"       ,l_nUseStatus)
                                            :Field("EnumValue.DocStatus"       ,l_nDocStatus)
                                            :Field("EnumValue.ExternalId"      ,l_iExternalId)
                                            if empty(l_iEnumValuePk)
                                                :Field("EnumValue.fk_Enumeration"  ,l_iEnumerationPk)
                                                // :Field("EnumValue.UID"         ,oFcgi:p_o_SQLConnection:GetUUIDString())     // Will be set via default value instead
                                                if :Add()
                                                    l_nAddedRecords++
                                                else
                                                    l_cFatalErrorMessage := "Failed to Add Enumeration Value."
                                                    loop
                                                endif
                                            else
                                                if :Update(l_iEnumValuePk)
                                                    l_nUpdatedRecords++
                                                else
                                                    l_cFatalErrorMessage := "Failed to Update Enumeration Value."
                                                    loop
                                                endif
                                            endif
                                        endwith
                                            
                                    endif
                                endcase

                            endfor

                            if empty(l_cFatalErrorMessage)
                                //Discontinue Values not specified
                                select ListOfEnumValues
                                scan all for ListOfEnumValues->Processed == 0 .and. ListOfEnumValues->EnumValue_UseStatus <> USESTATUS_DISCONTINUED
                                    with object l_oDB_RecordOfEnumValue
                                        :Table("ada61781-9666-4162-90d3-d18da2f99c37","EnumValue")
                                        :Field("EnumValue.UseStatus" ,USESTATUS_DISCONTINUED)
                                        if :Update(ListOfEnumValues->Pk)
                                            l_nUpdatedRecords++
                                        else
                                            l_cFatalErrorMessage := "Failed to Update Enumeration Value."
                                            exit
                                        endif
                                    endwith
                                endscan
                            endif

                        endif

                    endif
                endcase

            endfor
        endif
    endif
endif

return FinalizeCreateUpdateAPIResponse(l_hResponse,l_cFatalErrorMessage,l_aErrorMessages,l_nAddedRecords,l_nUpdatedRecords,l_iApplicationPk)
//=================================================================================================================
// Example: /api/CreateUpdateTables/
function APICreateUpdateTables(par_cAccessToken,par_cAPIEndpointName,par_nTokenAccessMode)
local l_cResponse := ""
local l_hResponse := {=>}
local l_cApplicationLinkCode   := oFcgi:GetQueryString("ApplicationLinkCode")
local l_oDB_ListOfApplications
local l_oDB_ListOfNamespaces
local l_oDB_ListOfTables
local l_oDB_ListOfColumns
local l_oDB_ListOfEnumerations
local l_oDB_RecordOfColumn
local l_nNumberOfApplications
local l_nNumberOfNamespaces
local l_iNamespacePk
local l_iTablePk
local l_iApplicationPk := 0
local l_cNamespaceName
local l_iExternalId
local l_cTableName
local l_cTableAKA
local l_cTableDescription
local l_cUseStatus
local l_nUseStatus
local l_cDocStatus
local l_nDocStatus
local l_oData

local l_lUsingInputArray
local l_nTableCounter := 0
local l_xTableInput
local l_aTableInput := {}
local l_hJsonInput
local l_nAddedRecords := 0
local l_nUpdatedRecords := 0

local l_nColumnOrder
local l_hColumn

local l_iColumnPk
local l_cColumnName
local l_cColumnAKA
local l_cColumnDescription
local l_cColumnType
local l_lColumnArray
local l_nColumnLength
local l_nColumnScale
local l_aColumnType
local l_aColumnSpec
local l_cColumnUsedBy
local l_nColumnUsedBy
local l_cColumnUsedAs
local l_nColumnUsedAs
local l_lColumnNullable
local l_cColumnOnDelete
local l_nColumnOnDelete
local l_cColumnForeignKeyUse
local l_cColumnForeignTable
local l_iColumnFk_TableForeign
local l_cColumnEnumeration
local l_iColumnFk_Enumeration
local l_lColumnForeignKeyOptional
local l_cColumnDefaultType
local l_nColumnDefaultType
local l_cColumnDefaultCustom
local l_lColumnUnicode


local l_nWhereNumber
local l_lFound

local l_cFatalErrorMessage := ""
local l_aErrorMessages     := {}  // Will include a list of up to one error per Namespace.
local l_cErrorMessage             // To view error message when getting input from JSON

//_M_ Using GetFieldInfo(par_cNamespaceAndTableName,par_cFieldName)  test we will not have an overflow.

if par_nTokenAccessMode == 1 .and. !APIAccessCheck_Token_EndPoint_Application_ReadRequest(par_cAccessToken,par_cAPIEndpointName,l_cApplicationLinkCode)
    l_cFatalErrorMessage := "Access Denied or Invalid ApplicationLinkCode"
else
    //par_nTokenAccessMode will be more than 1 (Read Only and Full Access) if is not application accessible.
    if empty(l_cApplicationLinkCode)
        l_cFatalErrorMessage := "Missing Application Code parameter"
    else
        l_oDB_ListOfApplications := hb_SQLData(oFcgi:p_o_SQLConnection)
        with object l_oDB_ListOfApplications
            :Table("129d8815-e38f-40b0-b54f-21e77b6e01b8","Application")
            :Column("Application.pk"         ,"pk")
            :Where("Application.LinkCode = ^", l_cApplicationLinkCode)
            :SQL("ListOfApplications")
            l_nNumberOfApplications := :Tally
        endwith

        if l_nNumberOfApplications <> 1
            l_cFatalErrorMessage := "Failed to locate application with Code: "+l_cApplicationLinkCode
        else
            l_iApplicationPk := ListOfApplications->pk

            l_oDB_ListOfColumns  := hb_SQLData(oFcgi:p_o_SQLConnection)
            l_oDB_RecordOfColumn := hb_SQLData(oFcgi:p_o_SQLConnection)

            l_xTableInput := oFcgi:GetJsonInput()

            l_lUsingInputArray := (ValType(l_xTableInput) == "A")
            if l_lUsingInputArray
                l_aTableInput := l_xTableInput
            else
                AAdd(l_aTableInput,l_xTableInput)
            endif

            //Process the list of tables without dealing with Columns. This has to be done as a first pass so we can ensure foreign key references can be handled. 
            for each l_hJsonInput in l_aTableInput
                if !empty(l_cFatalErrorMessage)
                    exit
                endif
                l_nTableCounter++

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"NamespaceName","C","",.t.,.f.),,@l_cNamespaceName,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"ExternalId","N",0,.f.,.f.),,@l_iExternalId,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Name","C","",.t.,.f.),,@l_cTableName,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"AKA","C",NULL,.f.,.t.),,@l_cTableAKA,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"Description","M",NULL,.f.,.t.),,@l_cTableDescription,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif

                if el_AUnpack(FetchJSonInput(l_hJsonInput,"UseStatus","C","Unknown",.f.,.f.),,@l_cUseStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nUseStatus := GetUseStatusFromText(l_cUseStatus)
                if el_AUnpack(FetchJSonInput(l_hJsonInput,"DocStatus","C","Missing",.f.,.f.),,@l_cDocStatus,@l_cErrorMessage)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                    loop
                endif
                l_nDocStatus := GetDocStatusFromText(l_cDocStatus)

                do case
                case empty(l_cNamespaceName)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Missing NamespaceName.")
                    loop
                case l_iExternalId < 0
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". ExternalId must be a positive value.")
                    loop
                case empty(l_cTableName)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Missing Name.")
                    loop
                case empty(l_nUseStatus)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Invalid Use Status.")
                    loop
                case empty(l_nDocStatus)
                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Invalid Doc Status.")
                    loop
                otherwise
                    l_oDB_ListOfNamespaces := hb_SQLData(oFcgi:p_o_SQLConnection)

                    //Find if the Namespace with the provided NamespaceName.
                    with object l_oDB_ListOfNamespaces
                        :Table("2a84040e-c8da-49eb-ba87-2bd492ba5a2b","Namespace")
                        :Column("Namespace.pk" ,"Namespace_pk")
                        :Where("Namespace.fk_Application = ^",l_iApplicationPk)
                        :Where("lower(trim(Namespace.Name)) = ^" ,lower(l_cNamespaceName))
                        :SQL("ListOfNamespaces")
                        l_nNumberOfNamespaces := :Tally
                    endwith

                    if l_nNumberOfNamespaces <> 1
                        AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Failed to find Namespace.")
                        loop
                    else
                        l_oDB_ListOfTables := hb_SQLData(oFcgi:p_o_SQLConnection)
                        l_iNamespacePk := ListOfNamespaces->Namespace_pk

                        //Find if the Table with the provided ExternalId already exists.
                        with object l_oDB_ListOfTables
                            :Table("eed40449-c63d-4633-8a15-480ac4b66f6d","Table")
                            :Column("Table.pk"          ,"Table_pk")
                            :Column("Table.Name"        ,"Table_Name")
                            :Column("Table.Aka"         ,"Table_Aka")
                            :Column("Table.Description" ,"Table_Description")
                            :Column("Table.UseStatus"   ,"Table_UseStatus")
                            :Column("Table.DocStatus"   ,"Table_DocStatus")
                            :Column("Table.ExternalId"  ,"Table_ExternalId")
                            :Where("Table.fk_Namespace = ^",l_iNamespacePk)
                            if l_iExternalId > 0
                                l_nWhereNumber := :Where("Table.ExternalId = ^" , l_iExternalId)
                            else
                                :Where("lower(replace(Table.Name,' ','')) = ^" , lower(StrTran(l_cTableName," ","")))
                            endif
                            l_oData := :SQL()
                            if :Tally < 0
                                l_cFatalErrorMessage := "Failed to query Table."
                                loop
                            endif

                            if :Tally == 0 .and. l_iExternalId > 0
                                //Check if we can find the entry by searching by Name instead.
                                :ReplaceWhere(l_nWhereNumber, "lower(replace(Table.Name,' ','')) = ^" , lower(StrTran(l_cTableName," ","")) )
                                l_oData := :SQL()   // Rerun the query
                                if :Tally < 0
                                    l_cFatalErrorMessage := "Failed to query Table."
                                    loop
                                endif
                            endif

                            do case
                            case :Tally == 0
                                l_iTablePk := 0
                            case :Tally == 1
                                l_iTablePk := l_oData:Table_pk
                            case :Tally > 1
                                AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". More than one Table was found.")
                                loop
                            otherwise
                                l_cFatalErrorMessage := "Table entry "+trans(l_nTableCounter)+". Failed to query Tables."
                                loop
                            endcase
                        
                            //Test to avoid duplicates.
                            :Table("d1fae57a-7cd8-43be-bc59-95805e03d47a","Table")
                            :Where([lower(replace(Table.Name,' ','')) = ^],lower(StrTran(l_cTableName," ","")))
                            :Where([Table.fk_Namespace = ^],l_iNamespacePk)
                            if l_iTablePk > 0
                                :Where([Table.pk != ^],l_iTablePk)
                            endif
                            :SQL()
                            if (:Tally <> 0)
                                AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Duplicate Name.")
                                loop
                            endif

                            if l_iExternalId == 0
                                l_iExternalId := NULL
                            endif

                            //Test something changed.
                            if !empty(l_iTablePk) .and. l_cTableName        == l_oData:Table_Name ;
                                                    .and. l_cTableAKA         == l_oData:Table_Aka ;
                                                    .and. CompareDescriptionField(l_cTableDescription,l_oData:Table_Description) ;
                                                    .and. l_nUseStatus        == l_oData:Table_UseStatus ;
                                                    .and. l_nDocStatus        == l_oData:Table_DocStatus ;
                                                    .and. l_iExternalId       == l_oData:Table_ExternalId
                                //Nothing Changed
                            else
                                :Table("5b1c224e-aa5a-4e5c-8b6f-8bb3a62379a1","Table")
                                :Field("Table.Name"            ,l_cTableName)
                                // :Field("Table.TrackNameChanges",l_lTableTrackNameChanges)
                                :Field("Table.AKA"             ,l_cTableAKA)
                                :Field("Table.UseStatus"       ,l_nUseStatus)
                                :Field("Table.DocStatus"       ,l_nDocStatus)
                                :Field("Table.Description"     ,l_cTableDescription)
                                :Field("Table.ExternalId"      ,l_iExternalId)

                                if empty(l_iTablePk)
                                    :Field("Table.fk_Namespace" ,l_iNamespacePk)
                                    // :Field("Table.UID"          ,oFcgi:p_o_SQLConnection:GetUUIDString())     // Will be set via default value instead
                                    if :Add()
                                        l_nAddedRecords++
                                        l_iTablePk := :Key()
                                    else
                                        l_cFatalErrorMessage := "Failed to add Table."
                                    endif
                                else
                                    if :Update(l_iTablePk)
                                        l_nUpdatedRecords++
                                    else
                                        l_cFatalErrorMessage := "Failed to update Table."
                                    endif
                                    // SendToClipboard(:LastSQL())
                                endif
                            endif
                            
                        endif
                    endwith
                endcase

            endfor

            //Get the list of tables in the current application so the foreign keys can be resolved.
            if empty(l_cFatalErrorMessage)
                with object l_oDB_ListOfTables
                    :Table("0536ad9a-3e38-4b23-854b-03ff37e3f856","Table")
                    :Column("Table.pk"      ,"Table_pk")
                    :Column("Table.Name"    ,"Table_Name")
                    :Column("Namespace.Name","Namespace_Name")
                    :Join("inner","Namespace","","Table.fk_Namespace = Namespace.pk")
                    :Where("Namespace.fk_Application = ^",l_iApplicationPk)
                    :SQL("ListOfNamespaceAndTables")
                    if :Tally < 0
                        l_cFatalErrorMessage := "Failed to get ListOfNamespaceAndTables."
                    else
                        with object :p_oCursor
                            :Index("tag1","lower(Namespace_Name)+'.'+lower(Table_Name)+'*'")
                            :CreateIndexes()
                        endwith
                    endif
                endwith
            endif

            //Get the list of enumerations in the current application so the columns of type enumerations can be resolved.
            if empty(l_cFatalErrorMessage)
                l_oDB_ListOfEnumerations := hb_SQLData(oFcgi:p_o_SQLConnection)
                with object l_oDB_ListOfEnumerations
                    :Table("a1d7828a-f345-4613-89c2-16f2e20141ee","Enumeration")
                    :Column("Enumeration.pk"  ,"Enumeration_pk")
                    :Column("Enumeration.Name","Enumeration_Name")
                    :Column("Namespace.Name"  ,"Namespace_Name")
                    :Join("inner","Namespace","","Enumeration.fk_Namespace = Namespace.pk")
                    :Where("Namespace.fk_Application = ^",l_iApplicationPk)
                    :SQL("ListOfNamespaceAndEnumerations")
                    if :Tally < 0
                        l_cFatalErrorMessage := "Failed to get ListOfNamespaceAndEnumerations."
                    else
                        with object :p_oCursor
                            :Index("tag1","lower(Namespace_Name)+'.'+lower(Enumeration_Name)+'*'")
                            :CreateIndexes()
                        endwith
                    endif
                endwith
            endif

            //Process the list of tables again so to add/update Columns.
            if empty(l_cFatalErrorMessage)

                l_nTableCounter := 0
                for each l_hJsonInput in l_aTableInput
                    if !empty(l_cFatalErrorMessage)
                        exit
                    endif
                    l_nTableCounter++

                    if el_AUnpack(FetchJSonInput(l_hJsonInput,"NamespaceName","C","",.t.,.f.),,@l_cNamespaceName,@l_cErrorMessage)
                        // AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                        // No need to report again, since this is a reprocessing of the tables
                        loop
                    endif

                    if el_AUnpack(FetchJSonInput(l_hJsonInput,"Name","C","",.t.,.f.),,@l_cTableName,@l_cErrorMessage)
                        // AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". "+l_cErrorMessage)
                        // No need to report again, since this is a reprocessing of the tables
                        loop
                    endif

                    if el_seek(lower(l_cNamespaceName)+'.'+lower(l_cTableName)+'*',"ListOfNamespaceAndTables","tag1")
                        l_iTablePk := ListOfNamespaceAndTables->Table_pk

                        with object l_oDB_ListOfColumns
                            :Table("21d169d9-9983-4889-b670-e99f30e861c9","Column")
                            :Column("Column.pk"                 ,"pk")
                            :Column("Column.Order"              ,"Column_Order")
                            :Column("Column.Name"               ,"Column_Name")
                            :Column("Column.Aka"                ,"Column_Aka")
                            :Column("Column.Description"        ,"Column_Description")
                            :Column("Column.UseStatus"          ,"Column_UseStatus")
                            :Column("Column.DocStatus"          ,"Column_DocStatus")
                            :Column("Column.Type"               ,"Column_Type")
                            :Column("Column.Array"              ,"Column_Array")
                            :Column("Column.UsedBy"             ,"Column_UsedBy")
                            :Column("Column.UsedAs"             ,"Column_UsedAs")
                            :Column("Column.Length"             ,"Column_Length")
                            :Column("Column.Scale"              ,"Column_Scale")
                            :Column("Column.Nullable"           ,"Column_Nullable")
                            :Column("Column.OnDelete"           ,"Column_OnDelete")
                            :Column("Column.Fk_Enumeration"     ,"Column_Fk_Enumeration")
                            :Column("Column.ForeignKeyUse"      ,"Column_ForeignKeyUse")
                            :Column("Column.Fk_TableForeign"    ,"Column_Fk_TableForeign")
                            :Column("Column.ForeignKeyOptional" ,"Column_ForeignKeyOptional")
                            :Column("Column.DefaultType"        ,"Column_DefaultType")
                            :Column("Column.DefaultCustom"      ,"Column_DefaultCustom")
                            :Column("Column.Unicode"            ,"Column_Unicode")
                            :Column("Column.ExternalId"         ,"Column_ExternalId")
                            :Column("0"                         ,"Processed")
                            :Where("Column.fk_Table = ^",l_iTablePk)
                            :SQL("ListOfColumns")
                        endwith

                        if l_oDB_ListOfColumns:Tally < 0
                            l_cFatalErrorMessage := "Failed to get list of Columns."
                            loop
                        else
                            l_nColumnOrder := 0
                            for each l_hColumn in hb_hGetDef(l_hJsonInput,"Columns",{})
                                l_nColumnOrder++

                                if el_AUnpack(FetchJSonInput(l_hColumn,"ExternalId","N",0,.f.,.f.),,@l_iExternalId,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"UsedBy","C","All",.f.,.f.),,@l_cColumnUsedBy,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nColumnUsedBy := GetColumnUsedByFromText(l_cColumnUsedBy)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"UsedAs","C","Regular",.f.,.f.),,@l_cColumnUsedAs,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nColumnUsedAs := GetColumnUsedAsFromText(l_cColumnUsedAs)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Name","C","",.t.,.f.),,@l_cColumnName,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"AKA","C",NULL,.f.,.t.),,@l_cColumnAKA,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Description","M",NULL,.f.,.t.),,@l_cColumnDescription,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"UseStatus","C","Unknown",.f.,.f.),,@l_cUseStatus,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nUseStatus := GetUseStatusFromText(l_cUseStatus)
                                if el_AUnpack(FetchJSonInput(l_hColumn,"DocStatus","C","Missing",.f.,.f.),,@l_cDocStatus,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nDocStatus := GetDocStatusFromText(l_cDocStatus)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Type","C","",.t.,.f.),,@l_cColumnType,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_cColumnType := upper(l_cColumnType)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Array","L",.f.,.f.,.f.),,@l_lColumnArray,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Length","N",-1,.f.,.f.),,@l_nColumnLength,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                if l_nColumnLength < 0
                                    l_nColumnLength := NULL
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Scale","N",-1,.f.,.f.),,@l_nColumnScale,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                if l_nColumnScale < 0
                                    l_nColumnScale := NULL
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Nullable","L",.t.,.f.,.f.),,@l_lColumnNullable,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"OnDelete","C","NotSet",.f.,.f.),,@l_cColumnOnDelete,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nColumnOnDelete := GetColumnOnDeleteFromText(l_cColumnOnDelete)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"ForeignKeyUse","C",NULL,.f.,.t.),,@l_cColumnForeignKeyUse,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"ForeignTable","C","",.f.,.f.),,@l_cColumnForeignTable,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                if empty(l_cColumnForeignTable)
                                    l_iColumnFk_TableForeign := 0  // Using 0 instead of NULL since the ORM is set to auto-convert NULL to 0
                                else
                                    // ExportTableToHtmlFile("ListOfNamespaceAndTables",el_AddPs(OUTPUT_FOLDER)+"PostgreSQL_ListOfNamespaceAndTables.html","From PostgreSQL",,25,.t.)

                                    if el_seek(lower(l_cColumnForeignTable)+'*',"ListOfNamespaceAndTables","tag1")
                                        l_iColumnFk_TableForeign := ListOfNamespaceAndTables->Table_pk
                                    else
                                        // l_iColumnFk_TableForeign := -1
                                        //_M_ report error in finding Parent Table.
                                        AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Failed to find parent table of Foreign Key.")
                                        loop
                                    endif
                                    
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Enumeration","C","",.f.,.f.),,@l_cColumnEnumeration,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                if empty(l_cColumnEnumeration)
                                    l_iColumnFk_Enumeration := 0  // Using 0 instead of NULL since the ORM is set to auto-convert NULL to 0
                                else
                                    if el_seek(lower(l_cColumnEnumeration)+'*',"ListOfNamespaceAndEnumerations","tag1")
                                        l_iColumnFk_Enumeration := ListOfNamespaceAndEnumerations->Enumeration_pk
                                    else
                                        AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Failed to find Enumeration.")
                                        loop
                                    endif
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"ForeignKeyOptional","L",.t.,.f.,.f.),,@l_lColumnForeignKeyOptional,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                if el_AUnpack(FetchJSonInput(l_hColumn,"DefaultType","C","NotSet",.f.,.f.),,@l_cColumnDefaultType,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif
                                l_nColumnDefaultType := GetColumnDefaultTypeFromText(l_cColumnDefaultType)

                                if el_AUnpack(FetchJSonInput(l_hColumn,"DefaultCustom","M",NULL,.f.,.t.),,@l_cColumnDefaultCustom,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                for each l_aColumnType in oFcgi:p_ColumnTypes
                                    if l_cColumnType == l_aColumnType[COLUMN_TYPES_CODE]
                                        l_aColumnSpec := AClone(l_aColumnType)

                                        if !l_aColumnSpec[COLUMN_TYPES_SHOW_LENGTH]
                                            l_nColumnLength := NIL
                                        endif
                                        if !l_aColumnSpec[COLUMN_TYPES_SHOW_SCALE]
                                            l_nColumnScale := NIL
                                        endif

                                        exit
                                    endif
                                endfor

                                if el_AUnpack(FetchJSonInput(l_hColumn,"Unicode","L",.t.,.f.,.f.),,@l_lColumnUnicode,@l_cErrorMessage)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". "+l_cErrorMessage)
                                    loop
                                endif

                                // //{Code,Name,Show Length,Show Scale,Max Scale,Show Enums,Show Unicode,PostgreSQL Name, MySQL Name}
                                // #define COLUMN_TYPES_CODE          1
                                // #define COLUMN_TYPES_NAME          2
                                // #define COLUMN_TYPES_SHOW_LENGTH   3
                                // #define COLUMN_TYPES_SHOW_SCALE    4
                                // #define COLUMN_TYPES_MAX_SCALE     5
                                // #define COLUMN_TYPES_SHOW_ENUMS    6
                                // #define COLUMN_TYPES_SHOW_UNICODE  7
                                // #define COLUMN_TYPES_POSTGRES_NAME 8
                                // #define COLUMN_TYPES_MYSQL_NAME    9

                                do case
                                case l_iExternalId < 0
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". ExternalId must be a positive value.")
                                    loop
                                case empty(l_cColumnName)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Missing Name.")
                                    loop
                                case empty(l_nColumnUsedBy)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Missing or Invalid UsedBy.")
                                    loop
                                case empty(l_nColumnUsedAs)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Missing or Invalid UsedAs.")
                                    loop
                                case empty(l_nUseStatus)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Invalid Use Status.")
                                    loop
                                case empty(l_nDocStatus)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Invalid Doc Status.")
                                    loop
                                case empty(l_aColumnSpec)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Unknown Colum Type.")
                                    loop
                                case (l_aColumnSpec[COLUMN_TYPES_SHOW_LENGTH]) .and. hb_IsNIL(l_nColumnLength)   // Length should be entered
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Length is required.")
                                    loop
                                case (l_aColumnSpec[COLUMN_TYPES_SHOW_SCALE]) .and. hb_IsNIL(l_nColumnScale)   // Scale should be entered
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Scale is required. Enter at the minimum 0.")
                                    loop
                                case (l_aColumnSpec[COLUMN_TYPES_SHOW_LENGTH]) .and. (l_aColumnSpec[COLUMN_TYPES_SHOW_SCALE]) .and. l_nColumnScale >= l_nColumnLength
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Scale must be smaller than Length.")
                                    loop
                                case !hb_IsNIL(l_aColumnSpec[COLUMN_TYPES_MAX_SCALE]) .and. l_nColumnScale > l_aColumnSpec[COLUMN_TYPES_MAX_SCALE]
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Scale may not exceed "+trans(l_aColumnSpec[COLUMN_TYPES_MAX_SCALE])+".")
                                    loop
                                case empty(l_nColumnOnDelete)
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Invalid OnDelete.")
                                    loop
                                case l_nColumnDefaultType < 0
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Invalid Default Type.")
                                    loop
                                case !empty(l_cColumnDefaultCustom) .and. l_nColumnDefaultType <> 1   // "Custom"
                                    AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". Since DefaultCustom exists, DefaultType must be 'Custom' .")
                                    loop
                                otherwise
                                    select ListOfColumns

                                    if l_iExternalId > 0
                                        locate for nvl(ListOfColumns->Column_ExternalId,0) == l_iExternalId
                                        l_lFound := found()
                                    else
                                        l_lFound := .f.
                                    endif
                                    if !l_lFound
                                        locate for lower(strtran(ListOfColumns->Column_Name," ","")) == lower(strtran(l_cColumnName," ",""))
                                        l_lFound := found()
                                    endif
                                    
                                    if l_lFound
                                        ListOfColumns->Processed := 1
                                        l_iColumnPk := ListOfColumns->Pk
                                    else
                                        l_iColumnPk := 0
                                    endif

                                    if l_iExternalId == 0
                                        l_iExternalId := NULL
                                    endif

                                    //Test something changed.
                                    if !empty(l_iColumnPk) .and. l_nColumnOrder              == ListOfColumns->Column_Order ;
                                                           .and. l_cColumnName               == ListOfColumns->Column_Name ;
                                                           .and. l_cColumnAKA                == ListOfColumns->Column_Aka ;
                                                           .and. CompareDescriptionField(l_cColumnDescription,ListOfColumns->Column_Description) ;
                                                           .and. l_nColumnUsedBy             == ListOfColumns->Column_UsedBy ;
                                                           .and. l_nColumnUsedAs             == ListOfColumns->Column_UsedAs ;
                                                           .and. l_nUseStatus                == ListOfColumns->Column_UseStatus ;
                                                           .and. l_nDocStatus                == ListOfColumns->Column_DocStatus ;
                                                           .and. l_cColumnType               == trim(ListOfColumns->Column_Type) ;
                                                           .and. l_lColumnArray              == ListOfColumns->Column_Array ;
                                                           .and. l_nColumnLength             == ListOfColumns->Column_Length ;
                                                           .and. l_nColumnScale              == ListOfColumns->Column_Scale ;
                                                           .and. l_lColumnNullable           == ListOfColumns->Column_Nullable ;
                                                           .and. l_nColumnOnDelete           == ListOfColumns->Column_OnDelete ;
                                                           .and. l_cColumnForeignKeyUse      == ListOfColumns->Column_ForeignKeyUse ;
                                                           .and. l_iColumnFk_Enumeration     == ListOfColumns->Column_Fk_Enumeration ;
                                                           .and. l_iColumnFk_TableForeign    == ListOfColumns->Column_Fk_TableForeign ;
                                                           .and. l_lColumnForeignKeyOptional == ListOfColumns->Column_ForeignKeyOptional ;
                                                           .and. l_nColumnDefaultType        == ListOfColumns->Column_DefaultType ;
                                                           .and. l_cColumnDefaultCustom      == ListOfColumns->Column_DefaultCustom ;
                                                           .and. l_lColumnUnicode            == ListOfColumns->Column_Unicode ;
                                                           .and. l_iExternalId               == ListOfColumns->Column_ExternalId

                                        //Nothing Changed
                                    else
                                        //Test to avoid creating duplicates.
                                        if !empty(l_iColumnPk)
                                            locate for (lower(strtran(ListOfColumns->Column_Name," ","")) == lower(strtran(l_cColumnName," ",""))) .and. (ListOfColumns->pk <> l_iColumnPk)
                                        else
                                            locate for lower(strtran(ListOfColumns->Column_Name," ","")) == lower(strtran(l_cColumnName," ",""))
                                        endif
                                        if found()
                                            AAdd(l_aErrorMessages,"Table entry "+trans(l_nTableCounter)+". Column entry "+trans(l_nColumnOrder)+". May not create more than one column with the same Name.")
                                            loop
                                        else
                                            with object l_oDB_RecordOfColumn
                                                :Table("69ae4780-eba7-4a94-bdc3-8f65f35cac76","Column")
                                                :Field("Column.Order"              ,l_nColumnOrder)
                                                :Field("Column.Name"               ,l_cColumnName)
                                                // :Field("Column.TrackNameChanges",l_lColumnTrackNameChanges)
                                                :Field("Column.AKA"                ,l_cColumnAKA)
                                                :Field("Column.UsedBy"             ,l_nColumnUsedBy)
                                                :Field("Column.UsedAs"             ,l_nColumnUsedAs)
                                                :Field("Column.UseStatus"          ,l_nUseStatus)
                                                :Field("Column.DocStatus"          ,l_nDocStatus)
                                                :Field("Column.Description"        ,l_cColumnDescription)
                                                :Field("Column.Type"               ,l_cColumnType)
                                                :Field("Column.Array"              ,l_lColumnArray)
                                                :Field("Column.Length"             ,l_nColumnLength)
                                                :Field("Column.Scale"              ,l_nColumnScale)
                                                :Field("Column.Nullable"           ,l_lColumnNullable)
                                                :Field("Column.OnDelete"           ,l_nColumnOnDelete)
                                                :Field("Column.Fk_Enumeration"     ,l_iColumnFk_Enumeration)
                                                :Field("Column.ForeignKeyUse"      ,l_cColumnForeignKeyUse)
                                                :Field("Column.Fk_TableForeign"    ,l_iColumnFk_TableForeign)
                                                :Field("Column.ForeignKeyOptional" ,l_lColumnForeignKeyOptional)
                                                :Field("Column.DefaultType"        ,l_nColumnDefaultType)
                                                :Field("Column.DefaultCustom"      ,l_cColumnDefaultCustom)
                                                :Field("Column.Unicode"            ,l_lColumnUnicode)
                                                :Field("Column.ExternalId"         ,l_iExternalId)

                                                if empty(l_iColumnPk)
                                                    :Field("Column.fk_Table",l_iTablePk)
                                                    :Field("Column.UID"     ,oFcgi:p_o_SQLConnection:GetUUIDString())
                                                    if :Add()
                                                        l_nAddedRecords++
                                                        l_iColumnPk := :Key()
                                                    else
                                                        l_cFatalErrorMessage := "Failed to add Column."
                                                    endif
                                                else
                                                    if :Update(l_iColumnPk)
                                                        l_nUpdatedRecords++
                                                    else
                                                        l_cFatalErrorMessage := "Failed to update Column. "+:ErrorMessage()
                                                    endif
                                                    // SendToClipboard(:LastSQL())
                                                endif
                                            endwith
                                        endif
                                    endif

                                    
                                    
                                endcase

                            endfor

                            if empty(l_cFatalErrorMessage)
                                //Discontinue Columns not specified
                                select ListOfColumns
                                scan all for ListOfColumns->Processed == 0 .and. ListOfColumns->Column_UseStatus <> USESTATUS_DISCONTINUED
                                    with object l_oDB_RecordOfColumn
                                        :Table("b6433cb4-d031-49b1-82d0-a2c1a2cca142","Column")
                                        :Field("Column.UseStatus" ,USESTATUS_DISCONTINUED)
                                        if :Update(ListOfColumns->Pk)
                                            l_nUpdatedRecords++
                                        else
                                            l_cFatalErrorMessage := "Failed to Update Column."
                                            exit
                                        endif
                                    endwith
                                endscan
                            endif

                        endif

                        if empty(l_cFatalErrorMessage)
                            ReSequenceColumns(l_iTablePk)
                        endif
                    else
                        l_cFatalErrorMessage := "Failed to Find table "+l_cNamespaceName+"."+l_cTableName
                        exit
                    endif
                endfor
            endfor
        endif
    endif
endif

return FinalizeCreateUpdateAPIResponse(l_hResponse,l_cFatalErrorMessage,l_aErrorMessages,l_nAddedRecords,l_nUpdatedRecords,l_iApplicationPk)
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
function GetUseStatusFromText(par_cUseStatus)
local l_nUseStatus

do case
case par_cUseStatus == "Unknown"
    l_nUseStatus :=  1
case par_cUseStatus == "Proposed"
    l_nUseStatus := 2
case par_cUseStatus == "UnderDevelopment"
    l_nUseStatus := 3
case par_cUseStatus == "Active"
    l_nUseStatus := 4
case par_cUseStatus == "ToBeDiscontinued"
    l_nUseStatus := 5
case par_cUseStatus == "Discontinued"
    l_nUseStatus := 6
otherwise
    l_nUseStatus := 0
endcase

return l_nUseStatus
//=================================================================================================================
function GetDocStatusFromText(par_cDocStatus)
local l_nDocStatus

do case
case par_cDocStatus == "Missing"
    l_nDocStatus := 1
case par_cDocStatus == "NotNeeded"
    l_nDocStatus := 2
case par_cDocStatus == "Composing"
    l_nDocStatus := 3
case par_cDocStatus == "Complete"
    l_nDocStatus := 4
otherwise
    l_nDocStatus := 0
endcase

return l_nDocStatus
//=================================================================================================================
// function CheckColumnType(par_cType)
// local l_lOk := .t.

// //p_ColumnTypes

// return l_lOk
//=================================================================================================================
function GetColumnUsedAsFromText(par_cUsedAs)
local l_nUsedAs

// Regular    - Number: 1
// PrimaryKey - Number: 2
// ForeignKey - Number: 3
// Support    - Number: 4

do case
case lower(par_cUsedAs) == "regular"
    l_nUsedAs := 1
case lower(left(par_cUsedAs,7)) == "primary"
    l_nUsedAs := 2
case lower(left(par_cUsedAs,7)) == "foreign"
    l_nUsedAs := 3
case lower(par_cUsedAs) == "support"
    l_nUsedAs := 4
otherwise
    l_nUsedAs := 0
endcase

return l_nUsedAs
//=================================================================================================================
function GetColumnOnDeleteFromText(par_cOnDelete)
local l_nOnDelete

// NotSet    - Number: 1
// Protect   - Number: 2
// Cascade   - Number: 3
// BreakLink - Number: 4

do case
case lower(left(par_cOnDelete,3)) == "not"
    l_nOnDelete := 1
case lower(left(par_cOnDelete,7)) == "protect"
    l_nOnDelete := 2
case lower(left(par_cOnDelete,7)) == "cascade"
    l_nOnDelete := 3
case lower(left(par_cOnDelete,5)) == "break"
    l_nOnDelete := 4
otherwise
    l_nOnDelete := 0
endcase

return l_nOnDelete
//=================================================================================================================
function GetEnumerationImplementAsFromText(par_cImplementAs)
local l_nImplementAs

// NativeSQLEnum - Number: 1
// Integer       - Number: 2
// Numeric       - Number: 3
// VarChar       - Number: 4

do case
case lower(par_cImplementAs) == "nativesqlenum"
    l_nImplementAs := 1
case lower(par_cImplementAs) == "integer"
    l_nImplementAs := 2
case lower(par_cImplementAs) == "numeric"
    l_nImplementAs := 3
case lower(par_cImplementAs) == "varchar"
    l_nImplementAs := 4
otherwise
    l_nImplementAs := 0
endcase

return l_nImplementAs
//=================================================================================================================
function GetColumnDefaultTypeFromText(par_cDefaultType)
local l_nDefaultType

//DefaultType
//   NotSet        - Number: 0
//   Custom        - Number: 1
//   Today         - Number: 10
//   Now           - Number: 11
//   RandomUuid    - Number: 12
//   False         - Number: 13
//   True          - Number: 14
//   AutoIncrement - Number: 15

do case
case lower(par_cDefaultType) == "notset" .or. empty(par_cDefaultType)
    l_nDefaultType := 0
case lower(par_cDefaultType) == "custom"
    l_nDefaultType := 1
case lower(par_cDefaultType) == "today"
    l_nDefaultType := 10
case lower(par_cDefaultType) == "now"
    l_nDefaultType := 11
case lower(par_cDefaultType) == "randomuuid"
    l_nDefaultType := 12
case lower(par_cDefaultType) == "false"
    l_nDefaultType := 13
case lower(par_cDefaultType) == "true"
    l_nDefaultType := 14
case lower(par_cDefaultType) == "autoincrement"
    l_nDefaultType := 15
otherwise
    l_nDefaultType := -1
endcase

return l_nDefaultType
//=================================================================================================================
function GetColumnUsedByFromText(par_cUsedBy)
local l_nUsedBy

do case
case (lower(left(par_cUsedBy,3)) == "all") .or. empty(par_cUsedBy)
    l_nUsedBy := 1
case lower(left(par_cUsedBy,5)) == "mysql"
    l_nUsedBy := 2
case lower(left(par_cUsedBy,6)) == "oracle"
    l_nUsedBy := 4
case lower(left(par_cUsedBy,8)) == "postgres"
    l_nUsedBy := 3
otherwise
    l_nUsedBy := 0
endcase

return l_nUsedBy
//=================================================================================================================
static function CompareDescriptionField(par_xValue1,par_xValue2)
//To deal with CRLF or LF use
local l_lEqual
if !hb_Isnil(par_xValue1) .and. !hb_IsNil(par_xValue2)
    l_lEqual := (strtran(par_xValue1,chr(13)+chr(10),chr(10)) == strtran(par_xValue2,chr(13)+chr(10),chr(10)) )
else
    l_lEqual := (par_xValue1 == par_xValue2)
endif
return l_lEqual
//=================================================================================================================
//=================================================================================================================
function FetchJSonInput(par_hInput,par_cName,par_cType,par_xDefaultValue,par_lRequired,par_lNullOnEmpty)
local l_cErrorMessage := ""
local l_xValue        := hb_hGetDef(par_hInput,par_cName,NULL)
local l_cValType
local l_cType         := par_cType

if hb_IsNil(l_xValue)
    if par_lRequired
        l_cErrorMessage := "Missing entry "+par_cName+"."
    else
        l_xValue := par_xDefaultValue
    endif
else
    l_cValType := ValType(l_xValue)
    if l_cValType == "M"
        l_cValType := "C"
    endif
    if l_cType == "M"
        l_cType := "C"
    endif
    if l_cValType <> l_cType  //"C","N","L","M"
        l_cErrorMessage := "Invalid value type for "+par_cName+"."
    else
        if l_cType == "C"
            l_xValue := alltrim(l_xValue)
            if empty(l_xValue) .and. par_lNullOnEmpty
                l_xValue := NULL
            endif
        endif
    endif
endif

return {!empty(l_cErrorMessage),l_xValue,l_cErrorMessage}
//=================================================================================================================
function FinalizeCreateUpdateAPIResponse(par_hResponse,par_cFatalErrorMessage,par_aErrorMessages,par_nAddedRecords,par_nUpdatedRecords,par_iApplicationPk)
local l_cResponseMessage
local l_cErrorMessage     // Used to build the final list of Error Messages

if (par_nAddedRecords > 0 .or. par_nUpdatedRecords > 0) .and. (par_iApplicationPk > 0)
    DataDictionaryFixAndTest(par_iApplicationPk)
endif

l_cResponseMessage := par_cFatalErrorMessage
for each l_cErrorMessage in par_aErrorMessages
    if !empty(l_cResponseMessage)
        l_cResponseMessage += LF // "\n"
    endif
    l_cResponseMessage += l_cErrorMessage
endfor

if empty(l_cResponseMessage)
    oFcgi:SetHeaderValue("Status","200")
    par_hResponse["Message"] := "No Errors"
else
    oFcgi:SetHeaderValue("Status","400 See Message")
    par_hResponse["Message"] := l_cResponseMessage
endif
par_hResponse["RecordsAdded"]      := par_nAddedRecords
par_hResponse["RecordsUpdated"]    := par_nUpdatedRecords
par_hResponse["ErrorMessageCount"] := iif(!empty(par_cFatalErrorMessage),1,0)+len(par_aErrorMessages)

return hb_jsonEncode(par_hResponse)
//=================================================================================================================
