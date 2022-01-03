#include "DataWharf.ch"
memvar oFcgi

#include "dbinfo.ch"

// Sample Code to help debug failed SQL
//      SendToClipboard(l_oDB1:LastSQL())

// The following code is still under development.
// Review any _M_ areas, add support to description, integrate access rights restrictions and ensure will not create orphaned records.
// Will also need to refactor WebPage_Applications.prg to ensure data integrity with new tables "TableMapping" and "ColumnMapping"

//=================================================================================================================
function BuildPageInterAppMapping()
local l_cHtml := []
local l_cFormName

oFcgi:TraceAdd("BuildPageInterAppMapping")

if oFcgi:isGet()
    l_cHtml += InterAppMappingSelectApplicationsBuild("",{=>})

else
    l_cFormName := oFcgi:GetInputValue("formname")
    do case
    case l_cFormName == "SelectApplications"
        l_cHtml += InterAppMappingSelectApplicationsOnSubmit()
    case l_cFormName == "MapTables"
        l_cHtml += InterAppMappingMapTablesOnSubmit()
    case l_cFormName == "MapColumns"
        l_cHtml += InterAppMappingMapColumnsOnSubmit()
    endcase

endif

l_cHtml += [<div class="m-5"></div>]

return l_cHtml
//=================================================================================================================
static function InterAppMappingSelectApplicationsBuild(par_cErrorText,par_hValues)
local l_cHtml := []
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_cSitePath := oFcgi:RequestSettings["SitePath"]

local l_nNumberOfApplications
local l_iApplicationFromPk := hb_HGetDef(par_hValues,"ApplicationFromPk",0)
local l_iApplicationToPk   := hb_HGetDef(par_hValues,"ApplicationToPk",0)

local l_oDB1 := hb_SQLData(oFcgi:p_o_SQLConnection)

oFcgi:TraceAdd("InterAppMappingSelectApplicationsBuild")

with object l_oDB1
    :Table("613e8804-ae58-4e2c-a5cf-58774e04c21a","Application")
    :Distinct(.t.)
    :Column("Application.pk"         ,"pk")
    :Column("Application.Name"       ,"Application_Name")
    :Column("Upper(Application.Name)","tag1")
    :OrderBy("tag1")

    if oFcgi:p_nUserAccessMode <= 1
        :Join("inner","UserAccessApplication","","UserAccessApplication.fk_Application = Application.pk")
        :Where("UserAccessApplication.fk_User = ^",oFcgi:p_iUserPk)
    endif

    :SQL("ListOfApplications")
    l_nNumberOfApplications := :Tally
    if l_nNumberOfApplications < 2
        l_cErrorText := [You need access to at least two applications. ]+l_cErrorText
    endif
endwith

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="SelectApplications">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[InterAppMapping/">Inter-App Mapping - Select Applications</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

if !empty(l_cErrorText)
    l_cHtml += [<div class="p-3 mb-2 bg-]+iif(lower(left(l_cErrorText,7)) == "success",[success],[danger])+[ text-white">]+l_cErrorText+[</div>]
endif

l_cHtml += [<div class="m-3">]
    if l_nNumberOfApplications >= 2

        l_cHtml += [<div>]

            l_cHtml += [<span>From</span>]

            l_cHtml += [<span class="ms-1">]
                l_cHtml += [<select name="ComboApplicationFrom" id="ComboApplicationFrom">]
                    select ListOfApplications
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfApplications->pk)+["]+iif(ListOfApplications->pk == l_iApplicationFromPk,[ selected],[])+[>]+ListOfApplications->Application_Name+[</option>]
                    endscan
                l_cHtml += [</select>]
            l_cHtml += [</span>]

            l_cHtml += [<span class="ms-5">To</span>]

            l_cHtml += [<span class="ms-1">]
                l_cHtml += [<select name="ComboApplicationTo" id="ComboApplicationTo">]
                    select ListOfApplications
                    scan all
                        l_cHtml += [<option value="]+Trans(ListOfApplications->pk)+["]+iif(ListOfApplications->pk == l_iApplicationToPk,[ selected],[])+[>]+ListOfApplications->Application_Name+[</option>]
                    endscan
                l_cHtml += [</select>]
            l_cHtml += [</span>]

        l_cHtml += [</div>]

        l_cHtml += [<div class="m-3"></div>]  // Spacer

        l_cHtml += [<div>]
        l_cHtml += [<input type="button" class="btn btn-primary rounded" value="Map Tables" onclick="$('#ActionOnSubmit').val('MapTables');document.form.submit();" role="button">]
        l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
        l_cHtml += [</div>]
    endif
l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function InterAppMappingSelectApplicationsOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit
local l_cErrorMessage := ""
local l_iApplicationFromPk
local l_iApplicationToPk
local l_hValues := {=>}

oFcgi:TraceAdd("InterAppMappingSelectApplicationsBuildOnSubmit")
l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

do case
case l_cActionOnSubmit == "MapTables"
    //_M_ Verify selected 2 Applications and "remember the selection

    l_iApplicationFromPk := Val(oFcgi:GetInputValue("ComboApplicationFrom"))
    l_iApplicationToPk   := Val(oFcgi:GetInputValue("ComboApplicationTo"))

    l_hValues["ApplicationFromPk"] := l_iApplicationFromPk
    l_hValues["ApplicationToPk"]   := l_iApplicationToPk

    if l_iApplicationFromPk == l_iApplicationToPk
        l_cErrorMessage := [You must select different applications.]
    endif

    if empty(l_cErrorMessage)
        InterAppMappingLoadTableMappingInputField(l_iApplicationFromPk,l_iApplicationToPk,@l_hValues)
        l_cHtml := InterAppMappingMapTablesBuild("",l_hValues)
    else
        l_cHtml := InterAppMappingSelectApplicationsBuild(l_cErrorMessage,l_hValues)
    end

case l_cActionOnSubmit == "Cancel"
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"InterAppMapping/")

otherwise
    //Invalid Action. Reset to start of process
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"InterAppMapping/")
endcase

return l_cHtml
//=================================================================================================================
static function InterAppMappingMapTablesBuild(par_cErrorText,par_hValues)
local l_cHtml := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_iApplicationFromPk := hb_HGetDef(par_hValues,"ApplicationFromPk",0)
local l_iApplicationToPk   := hb_HGetDef(par_hValues,"ApplicationToPk"  ,0)
local l_oDB1                 := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesFrom := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesTo   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oData
local lcApplicationNameFrom
local lcApplicationNameTo
local l_iNumberOfTablesInList
local l_ScriptFolder
local l_info
local l_json_Categories
local l_cInputObjectName
local l_cInputValue
local l_nNumberOfNameSpacesInTablesFrom
local l_nNumberOfNameSpacesInTablesTo

oFcgi:TraceAdd("InterAppMappingMapTablesBuild")

l_ScriptFolder:= l_cSitePath+[scripts/jQueryAmsify_2020_01_27/]

oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[amsify.suggestags.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[jquery.amsify.suggestags.js"></script>]

l_cHtml += [<style>]
l_cHtml += [ .amsify-suggestags-area {font-family:"Arial";} ]
l_cHtml += [ .amsify-suggestags-input {max-width: 400px;min-width: 300px;} ]
l_cHtml += [ ul.amsify-list {min-height: 400px;} ]
l_cHtml += [</style>]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="MapTables">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<input type="hidden" id="ApplicationFromPk" name="ApplicationFromPk" value="]+Trans(l_iApplicationFromPk)+[">]
l_cHtml += [<input type="hidden" id="ApplicationToPk" name="ApplicationToPk" value="]+Trans(l_iApplicationToPk)+[">]
l_cHtml += [<input type="hidden" id="TableFromPk" name="TableFromPk" value="0">]  // Used to store whitch "Table From" we would like to make the mapping for

with object l_oDB1
    :Table("47786e9b-05fa-4e2f-9394-2923ae388e28","Application")
    :Column("Application.Name" , "Application_Name")
    l_oData := :Get(l_iApplicationFromPk)
    lcApplicationNameFrom := l_oData:Application_Name

    :Table("b9a62e19-a6c5-4462-b185-08de5a975973","Application")
    :Column("Application.Name" , "Application_Name")
    l_oData := :Get(l_iApplicationToPk)
    lcApplicationNameTo := l_oData:Application_Name

endwith

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[InterAppMapping/">Inter-App Mapping - From: ]+lcApplicationNameFrom+[ To: ]+lcApplicationNameTo+[ - Map Tables</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<div>]
    l_cHtml += [<input type="button" class="btn btn-primary rounded ms" value="Save And Stay" onclick="$('#ActionOnSubmit').val('SaveAndStay');document.form.submit();" role="button">]
    l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Save And Return" onclick="$('#ActionOnSubmit').val('SaveAndReturn');document.form.submit();" role="button">]
    l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
    l_cHtml += [</div>]

    With Object l_oDB_ListOfTablesFrom
        //Determine if we have more than 1 name space
        :Table("1a4574df-d0df-4082-9fb6-52785057ade0","Table")
        :Distinct(.t.)
        :Column("NameSpace.pk" , "NameSpace_pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")   // join against table to ensure we only count NameSpaces with at least one table.
        :Where("NameSpace.fk_Application = ^",l_iApplicationFromPk)
        :SQL()
        l_nNumberOfNameSpacesInTablesFrom := :tally


        :Table("c253234c-e44c-4279-a132-5ad3745f4907","Table")
        :Column("Table.pk"         ,"pk")
        :Column("NameSpace.Name"   ,"NameSpace_Name")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.AKA"        ,"Table_AKA")
        :Column("Upper(NameSpace.Name)","tag1")
        :Column("Upper(Table.Name)","tag2")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationFromPk)
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfTablesFrom")
        l_iNumberOfTablesInList := :Tally
    endwith

    with object l_oDB_ListOfTablesTo
        //Determine if we have more than 1 name space
        :Table("40d0b492-60cc-45cc-b5c6-f07c2c4cb4f3","Table")
        :Distinct(.t.)
        :Column("NameSpace.pk" , "NameSpace_pk")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")   // join against table to ensure we only count NameSpaces with at least one table.
        :Where("NameSpace.fk_Application = ^",l_iApplicationToPk)
        :SQL()
        l_nNumberOfNameSpacesInTablesTo := :tally

        :Table("5b5fd2e4-8675-4bfe-b1ff-65933f4f257e","Table")
        :Column("Table.pk"         ,"pk")
        :Column("NameSpace.Name"   ,"NameSpace_Name")
        :Column("Table.Name"       ,"Table_Name")
        :Column("Table.AKA"        ,"Table_AKA")
        :Column("Upper(NameSpace.Name)","tag1")
        :Column("Upper(Table.Name)","tag2")
        :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
        :Where("NameSpace.fk_Application = ^",l_iApplicationToPk)
        :OrderBy("tag1")
        :OrderBy("tag2")
        :SQL("ListOfTablesTo")
    endwith

    l_json_Categories := []
    select ListOfTablesTo
    scan all

        if !empty(l_json_Categories)
            l_json_Categories += [,]
        endif
        if l_nNumberOfNameSpacesInTablesTo > 1
            l_info = strtran(strtran(ListOfTablesTo->NameSpace_Name+"."+ListOfTablesTo->Table_Name+FormatAKAForDisplay(ListOfTablesTo->Table_AKA),["],[ ]),['],[ ])
        else
            l_info = strtran(strtran(ListOfTablesTo->Table_Name+FormatAKAForDisplay(ListOfTablesTo->Table_AKA),["],[ ]),['],[ ])
        endif
        l_json_Categories += "{tag:'"+l_info+"',value:"+trans(ListOfTablesTo->pk)+"}"
    endscan

    if l_iNumberOfTablesInList > 0

        oFcgi:p_cjQueryScript += [$(".TableTos").amsifySuggestags({]+;
                                                                "suggestions :["+l_json_Categories+"],"+;
                                                                "whiteList: true,"+;
                                                                "tagLimit: 10,"+;
                                                                "selectOnHover: true,"+;
                                                                "showAllSuggestions: true,"+;
                                                                "keepLastOnHoverTag: false"+;
                                                                [});]

        l_cHtml += [<div class="row justify-content-center m-3">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+iif(l_nNumberOfNameSpacesInTablesFrom > 1,"2","1")+[">]+lcApplicationNameFrom+[ Tables (]+Trans(l_iNumberOfTablesInList)+[)</th>]
                    l_cHtml += [<th class="GridHeaderRowCells bg-secondary"></th>]  // Extra Column
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">]+lcApplicationNameTo+[ Tables</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Map</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    if l_nNumberOfNameSpacesInTablesFrom > 1
                        l_cHtml += [<th class="GridHeaderRowCells text-white">Name Space</th>]
                    endif
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Table Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells bg-secondary"></th>]  // Extra Column
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Table Names</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">Columns</th>]
                l_cHtml += [</tr>]

                select ListOfTablesFrom
                scan all
                    l_cInputObjectName := "MappedToTables"+Trans(ListOfTablesFrom->pk)
                    l_cInputValue      := hb_HGetDef(par_hValues,l_cInputObjectName,"")

                    l_cHtml += [<tr>]

                        if l_nNumberOfNameSpacesInTablesFrom > 1
                            l_cHtml += [<td class="GridDataControlCells" valign="top">]
                                l_cHtml += Allt(ListOfTablesFrom->NameSpace_Name)
                            l_cHtml += [</td>]
                        endif

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            // l_cHtml += [<a href="]+l_cSitePath+[Applications/EditTable/]+par_cURLApplicationLinkCode+[/]+Allt(ListOfTablesFrom->NameSpace_Name)+[/]+ListOfTablesFrom->Table_Name+[/">]+ListOfTablesFrom->Table_Name+FormatAKAForDisplay(ListOfTablesFrom->Table_AKA)+[</a>]
                            l_cHtml += ListOfTablesFrom->Table_Name+FormatAKAForDisplay(ListOfTablesFrom->Table_AKA)
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells bg-secondary" valign="top"></td>]  // Extra Column

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<input type="text" size="10" name="]+l_cInputObjectName+[" id="]+l_cInputObjectName+[" class="TableTos"  placeholder="Enter one or more table" class="form-control" value="]+l_cInputValue+[">]
//_M_ Test code to see if could show/hide the "Map Columns" buttons
                            // l_cHtml += [<input onchange="console.log('111');" type="text" size="10" name="]+l_cInputObjectName+[" id="]+l_cInputObjectName+[" class="TableTos"  placeholder="Enter one or more table" class="form-control" value="]+l_cInputValue+[">]
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += [<input type="button" class="btn btn-primary rounded" value="Map Columns" onclick="$('#ActionOnSubmit').val('MapColumns');$('#TableFromPk').val(']+Trans(ListOfTablesFrom->pk)+[');document.form.submit();" role="button">]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function InterAppMappingMapTablesOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit
local l_iApplicationFromPk
local l_iApplicationToPk
local l_hValues := {=>}
local l_oDB1                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesFrom    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTableMapping  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnMapping := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_cInputObjectName
local l_nNumberOfMappingsOnFile
local l_cListOfTableToPks
local l_iTableFromPk
local l_iTableToPk
local l_hMappedTableOnFile := {=>}
local l_aTablesTo
local l_cTableTo
local l_iTableMappingPk
local l_iColumnToPk

oFcgi:TraceAdd("InterAppMappingMapTablesOnSubmit")
l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationFromPk := Val(oFcgi:GetInputValue("ApplicationFromPk"))
l_iApplicationToPk   := Val(oFcgi:GetInputValue("ApplicationToPk"))

l_hValues["ApplicationFromPk"] := l_iApplicationFromPk
l_hValues["ApplicationToPk"]   := l_iApplicationToPk

With Object l_oDB_ListOfTablesFrom
    :Table("1b10a823-d84e-48d5-ba77-5d6f87d50385","Table")
    :Column("Table.pk"         ,"pk")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^",l_iApplicationFromPk)
    :SQL("ListOfTablesFrom")
endwith

select ListOfTablesFrom
scan all
    l_cInputObjectName            := "MappedToTables"+Trans(ListOfTablesFrom->pk)
    l_hValues[l_cInputObjectName] := SanitizeInput(oFcgi:GetInputValue(l_cInputObjectName))
endscan

do case
case vfp_inlist(l_cActionOnSubmit,"SaveAndStay","SaveAndReturn","MapColumns")
    // Save Tables mappings

    with object l_oDB_ListOfTableMapping
        :Table("8943fea6-bd44-4425-9c3a-647c23414629","TableMapping")
        :Column("TableMapping.pk"         , "pk")
        :Column("Table_From.pk"           , "fk_TableFrom")
        :Column("TableMapping.fk_TableTo" , "fk_TableTo")
        :Join("inner","Table"    ,"Table_From"    ,"TableMapping.fk_TableFrom = Table_From.pk")
        :Join("inner","NameSpace","NameSpace_From","Table_From.fk_NameSpace = NameSpace_From.pk")
        :Join("inner","Table"    ,"Table_To","TableMapping.fk_TableTo = Table_To.pk")
        :Join("inner","NameSpace","NameSpace_To","Table_To.fk_NameSpace = NameSpace_To.pk")
        :Where("NameSpace_From.fk_Application = ^" , l_iApplicationFromPk)
        :Where("NameSpace_To.fk_Application = ^"   , l_iApplicationToPk)    // To ensure we only get the tables from the Application To list.
        :SQL("ListOfMappingsOnFile")

        l_nNumberOfMappingsOnFile := :Tally
        if l_nNumberOfMappingsOnFile > 0
            hb_HAllocate(l_hMappedTableOnFile,l_nNumberOfMappingsOnFile)
            select ListOfMappingsOnFile
            scan all
                l_hMappedTableOnFile[Trans(ListOfMappingsOnFile->fk_TableFrom)+"_"+Trans(ListOfMappingsOnFile->fk_TableTo)] := ListOfMappingsOnFile->pk
            endscan
        endif
        
    endwith

    select ListOfTablesFrom
    scan all
        l_iTableFromPk      := ListOfTablesFrom->pk
        l_cInputObjectName  := "MappedToTables"+Trans(l_iTableFromPk)
        l_cListOfTableToPks := SanitizeInput(oFcgi:GetInputValue(l_cInputObjectName))
        if !empty(l_cListOfTableToPks)
            l_aTablesTo := hb_aTokens(l_cListOfTableToPks,",",.f.)
            for each l_cTableTo in l_aTablesTo
                l_iTableToPk := val(l_cTableTo)

                l_iTableMappingPk := hb_HGetDef(l_hMappedTableOnFile,Trans(l_iTableFromPk)+"_"+Trans(l_iTableToPk),0)
                if l_iTableMappingPk > 0
                    //Already on file. Remove from l_hMappedTableOnFile
                    hb_HDel(l_hMappedTableOnFile,Trans(l_iTableFromPk)+"_"+Trans(l_iTableToPk))
                    
                else
                    // Not on file yet
                    with object l_oDB1
                        :Table("e0456606-4815-4408-adc4-d506f8ec0687","TableMapping")
                        :Field("TableMapping.fk_TableFrom",l_iTableFromPk)
                        :Field("TableMapping.fk_TableTo"  ,l_iTableToPk)
                        :Add()
                    endwith
                endif

            endfor
        endif
    endscan

    //To through what is left in l_hMappedTableOnFile and remove it
    for each l_iTableMappingPk in l_hMappedTableOnFile
        //_M_ Should not delete if related column mapping on file.
        l_oDB1:Delete("38c8e9e5-95ab-451b-a679-6a2c50e93f3f","TableMapping",l_iTableMappingPk)
    endfor

    do case
    case l_cActionOnSubmit == "MapColumns"
        l_iTableFromPk := val(oFcgi:GetInputValue("TableFromPk"))
        if l_iTableFromPk > 0

            l_hValues["TableFromPk"] := l_iTableFromPk

            // load current list of mapped fields
            with object l_oDB_ListOfColumnMapping
                :Table("549f4f23-f374-48d7-9e51-f93dd6ff1011","ColumnMapping")
                :Column("ColumnMapping.pk"            , "pk")
                :Column("ColumnMapping.fk_ColumnFrom" , "fk_ColumnFrom")
                :Column("ColumnMapping.fk_ColumnTo"   , "fk_ColumnTo")
                :Join("inner","Column"   ,"Column_From" ,"ColumnMapping.fk_ColumnFrom = Column_From.pk")
                :Join("inner","Column"   ,"Column_To"   ,"ColumnMapping.fk_ColumnTo = Column_To.pk")
                :Join("inner","Table"    ,"Table_To"    ,"Column_To.fk_Table = Table_To.pk")
                :Join("inner","NameSpace","NameSpace_To","Table_To.fk_NameSpace = NameSpace_To.pk")
                :Where("Column_From.fk_Table = ^" , l_iTableFromPk)
                :Where("NameSpace_To.fk_Application = ^"   , l_iApplicationToPk)    // To ensure we only get the tables from the Application To list.
                :SQL("ListOfMappingsOnFile")
                
            endwith

            select ListOfMappingsOnFile
            scan all
                l_cInputObjectName  := "MappedToColumn"+Trans(ListOfMappingsOnFile->fk_ColumnFrom)
                l_iColumnToPk       := ListOfMappingsOnFile->fk_ColumnTo
                if l_iColumnToPk > 0
                    l_hValues[l_cInputObjectName] :=  l_iColumnToPk
                endif
            endscan

            l_cHtml := InterAppMappingMapColumnsBuild("",l_hValues)
        endif
    case l_cActionOnSubmit == "SaveAndStay"
        l_cHtml := InterAppMappingMapTablesBuild("",l_hValues)
    otherwise
        l_cHtml := InterAppMappingSelectApplicationsBuild("",l_hValues)
    endcase

case l_cActionOnSubmit == "Cancel"
    l_cHtml := InterAppMappingSelectApplicationsBuild("",l_hValues)

otherwise
    //Invalid Action. Reset to start of process
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"InterAppMapping/")
endcase

return l_cHtml
//=================================================================================================================
//=================================================================================================================
static function InterAppMappingMapColumnsBuild(par_cErrorText,par_hValues)
local l_cHtml := []
local l_cSitePath := oFcgi:RequestSettings["SitePath"]
local l_cErrorText := hb_DefaultValue(par_cErrorText,"")
local l_iApplicationFromPk := hb_HGetDef(par_hValues,"ApplicationFromPk",0)
local l_iApplicationToPk   := hb_HGetDef(par_hValues,"ApplicationToPk"  ,0)
local l_iTableFromPk       := hb_HGetDef(par_hValues,"TableFromPk"      ,0)

local l_oDB1                  := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnsFrom := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfTablesTo    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnsTo   := hb_SQLData(oFcgi:p_o_SQLConnection)

local l_oData
local lcApplicationNameFrom
local lcApplicationNameTo
local lcTableInfoFrom
local l_nNumberOfColumnsFrom
local l_cApplicationSupportColumns
local l_ScriptFolder
local l_cInputObjectName
local l_cInputValue
local l_cColumnsToOptions
local l_nNumberOfTablesTo
local l_iTableToPk
local l_nTableCounter := 0
local l_nColumnCounter
local l_cTableToInfo
local l_iColumnToPk
local l_hColumnToNames := {=>}
local l_cColumnToInfo

oFcgi:TraceAdd("InterAppMappingMapColumnsBuild")

l_ScriptFolder:= l_cSitePath+[scripts/jQuerySelect2_2022_01_01/]

oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[select2.min.css">]
oFcgi:p_cHeader += [<link rel="stylesheet" type="text/css" href="]+l_ScriptFolder+[select2-bootstrap-5-theme.min.css">]
oFcgi:p_cHeader += [<script language="javascript" type="text/javascript" src="]+l_ScriptFolder+[select2.full.min.js"></script>]

l_cHtml += [<form action="" method="post" name="form" enctype="multipart/form-data">] //Since there are text fields entry fields, encode as multipart/form-data
l_cHtml += [<input type="hidden" name="formname" value="MapColumns">]
l_cHtml += [<input type="hidden" id="ActionOnSubmit" name="ActionOnSubmit" value="">]

l_cHtml += [<input type="hidden" id="ApplicationFromPk" name="ApplicationFromPk" value="]+Trans(l_iApplicationFromPk)+[">]
l_cHtml += [<input type="hidden" id="ApplicationToPk" name="ApplicationToPk" value="]+Trans(l_iApplicationToPk)+[">]
l_cHtml += [<input type="hidden" id="TableFromPk" name="TableFromPk" value="]+Trans(l_iTableFromPk)+[">]

with object l_oDB1
    :Table("5bfa6a4b-ce69-46ab-a653-d8dbc111594e","Application")
    :Column("Application.Name" , "Application_Name")
    l_oData := :Get(l_iApplicationFromPk)
    lcApplicationNameFrom := l_oData:Application_Name

    :Table("a8f95e6a-105a-475d-b2ca-f958edc34880","Application")
    :Column("Application.Name" , "Application_Name")
    l_oData := :Get(l_iApplicationToPk)
    lcApplicationNameTo := l_oData:Application_Name

    :Table("6d92b143-0a73-4bfe-b147-23fd801938c0","Table")
    :Column("Table.Name"                 , "Table_Name")
    :Column("Table.AKA"                  , "Table_AKA")
    :Column("NameSpace.Name"             , "NameSpace_Name")
    :Column("NameSpace.AKA"              , "NameSpace_AKA")
    :Column("Application.SupportColumns" , "Application_SupportColumns")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Join("inner","Application","","NameSpace.fk_Application = Application.pk")
    l_oData := :Get(l_iTableFromPk)
    
    lcTableInfoFrom := l_oData:NameSpace_Name+FormatAKAForDisplay(l_oData:NameSpace_AKA)+"."+l_oData:Table_Name+FormatAKAForDisplay(l_oData:Table_AKA)

    l_cApplicationSupportColumns := nvl(l_oData:Application_SupportColumns,"")

endwith

with object l_oDB_ListOfTablesTo
    :Table("322d4d23-4ec6-43d2-9ef3-0010b1b44b67","TableMapping")
    :Column("Table.pk"             , "pk")
    :Column("NameSpace.Name"       , "NameSpace_Name")
    :Column("NameSpace.AKA"        , "NameSpace_AKA")
    :Column("Table.Name"           , "Table_Name")
    :Column("Table.AKA"            , "Table_AKA")
    :Column("Upper(NameSpace.Name)", "tag1")
    :Column("Upper(Table.Name)"    , "tag2")
    :Join("inner","Table","","TableMapping.fk_TableTo = Table.pk")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^" , l_iApplicationToPk)  // Redundant test
    :Where("TableMapping.fk_TableFrom = ^" , l_iTableFromPk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :SQL("ListOfTablesTo")
    l_nNumberOfTablesTo := :Tally

endwith

with object l_oDB_ListOfColumnsTo
    :Table("bb0c5681-6677-4add-b1ae-06cf7e1294d2","TableMapping")
    // :Column("Table.pk"             , "Table_pk")
    :Column("Column.pk"            , "Column_pk")
    :Column("NameSpace.Name"       , "NameSpace_Name")
    :Column("NameSpace.AKA"        , "NameSpace_AKA")
    :Column("Table.Name"           , "Table_Name")
    :Column("Table.AKA"            , "Table_AKA")
    :Column("Column.Name"          , "Column_Name")
    :Column("Column.AKA"           , "Column_AKA")
    :Column("Upper(NameSpace.Name)", "tag1")
    :Column("Upper(Table.Name)"    , "tag2")
    :Column("Column.Order"         , "Column_Order")
    :Join("inner","Table","","TableMapping.fk_TableTo = Table.pk")
    :Join("inner","Column","","Column.fk_Table = Table.pk")
    :Join("inner","NameSpace","","Table.fk_NameSpace = NameSpace.pk")
    :Where("NameSpace.fk_Application = ^" , l_iApplicationToPk)  // Redundant test
    :Where("TableMapping.fk_TableFrom = ^" , l_iTableFromPk)
    :OrderBy("tag1")
    :OrderBy("tag2")
    :OrderBy("Column_Order")
    :SQL("ListOfColumnsTo")

endwith

l_cHtml += [<nav class="navbar navbar-default bg-secondary">]
    l_cHtml += [<div class="input-group">]
        l_cHtml += [<a class="navbar-brand text-white ms-3" href="]+l_cSitePath+[InterAppMapping/">Inter-App Mapping - From: ]+lcApplicationNameFrom+[ To: ]+lcApplicationNameTo+[ - Map Columns for Table: ]+lcTableInfoFrom+[</a>]
    l_cHtml += [</div>]
l_cHtml += [</nav>]

l_cHtml += [<div class="m-3">]
    l_cHtml += [<div>]
    l_cHtml += [<input type="button" class="btn btn-primary rounded" value="Save And Stay" onclick="$('#ActionOnSubmit').val('SaveStay');document.form.submit();" role="button">]
    l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Save And Return To Table List" onclick="$('#ActionOnSubmit').val('SaveReturn');document.form.submit();" role="button">]
    l_cHtml += [<input type="button" class="btn btn-primary rounded ms-3" value="Cancel" onclick="$('#ActionOnSubmit').val('Cancel');document.form.submit();" role="button">]
    l_cHtml += [</div>]

    with object l_oDB_ListOfColumnsFrom
        //_M_ remove some if the unused columns(fields)
        :Table("75f0facf-1614-4e6f-a930-5d3a9d629fab","Column")
        :Column("Column.pk"             ,"pk")
        :Column("Column.Name"           ,"Column_Name")
        :Column("Column.AKA"            ,"Column_AKA")
        :Column("Column.UseStatus"      ,"Column_UseStatus")
        :Column("Column.DocStatus"      ,"Column_DocStatus")
        :Column("Column.Description"    ,"Column_Description")
        :Column("Column.Order"          ,"Column_Order")
        :Column("Column.Type"           ,"Column_Type")
        :Column("Column.Length"         ,"Column_Length")
        :Column("Column.Scale"          ,"Column_Scale")
        :Column("Column.Nullable"       ,"Column_Nullable")
        :Column("Column.Default"        ,"Column_Default")
        :Column("Column.Unicode"        ,"Column_Unicode")
        :Column("Column.Primary"        ,"Column_Primary")
        :Column("Column.UsedBy"         ,"Column_UsedBy")
        :Column("Column.fk_TableForeign","Column_fk_TableForeign")
        :Column("Column.fk_Enumeration" ,"Column_fk_Enumeration")

        :Column("NameSpace.Name"                ,"NameSpace_Name")
        :Column("Table.Name"                    ,"Table_Name")
        :Column("Table.AKA"                     ,"Table_AKA")
        :Column("Enumeration.Name"              ,"Enumeration_Name")
        :Column("Enumeration.AKA"               ,"Enumeration_AKA")
        :Column("Enumeration.ImplementAs"       ,"Enumeration_ImplementAs")
        :Column("Enumeration.ImplementLength"   ,"Enumeration_ImplementLength")
        
        :Join("left","Table"      ,"","Column.fk_TableForeign = Table.pk")
        :Join("left","NameSpace"  ,"","Table.fk_NameSpace = NameSpace.pk")
        :Join("left","Enumeration","","Column.fk_Enumeration  = Enumeration.pk")

        :Where("Column.fk_Table = ^" , l_iTableFromPk)
        :OrderBy("Column_Order")
        :SQL("ListColumnsFrom")

        l_nNumberOfColumnsFrom := :Tally

    endwith

    if l_nNumberOfColumnsFrom > 0

        l_cColumnsToOptions := "["
        if l_nNumberOfTablesTo > 1

            // The following code was done when using groupings. Does not land well if columns have the same name in more than one table.
            // select ListOfTablesTo
            // scan all
            //     l_iTableToPk := ListOfTablesTo->pk
            //     l_cTableToInfo := strtran(ListOfTablesTo->NameSpace_Name+FormatAKAForDisplay(ListOfTablesTo->NameSpace_AKA) +"."+ ListOfTablesTo->Table_Name+FormatAKAForDisplay(ListOfTablesTo->Table_AKA),"&nbsp;"," ")
            //     l_nTableCounter += 1
            //     if l_nTableCounter > 1
            //         l_cColumnsToOptions += ","
            //     endif
            //     l_cColumnsToOptions += [{]
            //         l_cColumnsToOptions += ["text":"Table: ]+l_cTableToInfo+[",]
            //         l_cColumnsToOptions += ["children":]+"["
            //         l_nColumnCounter := 0
            //         select ListOfColumnsTo
            //         scan all for ListOfColumnsTo->Table_pk == l_iTableToPk
            //             l_nColumnCounter += 1
            //             if l_nColumnCounter > 1
            //                 l_cColumnsToOptions += ","
            //             endif
            //             l_cColumnsToOptions += [{id:]+Trans(ListOfColumnsTo->Column_pk)+[,text:"]+ListOfColumnsTo->Column_Name+strtran(FormatAKAForDisplay(ListOfColumnsTo->Column_AKA),[&nbsp;],[ ])+[ (]+l_cTableToInfo+[)"}]
            //         endscan
            //         l_cColumnsToOptions += "]"
            //     l_cColumnsToOptions += [}]
            // endscan

            l_nColumnCounter := 0
            select ListOfColumnsTo
            scan all
                l_nColumnCounter += 1
                if l_nColumnCounter > 1
                    l_cColumnsToOptions += ","
                endif
                l_cTableToInfo  := strtran(ListOfColumnsTo->NameSpace_Name+FormatAKAForDisplay(ListOfColumnsTo->NameSpace_AKA) +"."+ ListOfColumnsTo->Table_Name+FormatAKAForDisplay(ListOfColumnsTo->Table_AKA),"&nbsp;"," ")
                l_cColumnToInfo := ListOfColumnsTo->Column_Name+strtran(FormatAKAForDisplay(ListOfColumnsTo->Column_AKA),[&nbsp;],[ ])+[ (]+l_cTableToInfo+[)]
                l_cColumnsToOptions += [{id:]+Trans(ListOfColumnsTo->Column_pk)+[,text:"]+l_cColumnToInfo+["}]
                l_hColumnToNames[ListOfColumnsTo->Column_pk] := l_cColumnToInfo   // Will be used to assist in setting up default <select> <option>
            endscan

        else
            l_nColumnCounter := 0
            select ListOfColumnsTo
            scan all
                l_nColumnCounter += 1
                if l_nColumnCounter > 1
                    l_cColumnsToOptions += ","
                endif
                l_cColumnToInfo := ListOfColumnsTo->Column_Name+strtran(FormatAKAForDisplay(ListOfColumnsTo->Column_AKA),[&nbsp;],[ ])
                l_cColumnsToOptions += [{id:]+Trans(ListOfColumnsTo->Column_pk)+[,text:"]+l_cColumnToInfo+["}]
                l_hColumnToNames[ListOfColumnsTo->Column_pk] := l_cColumnToInfo   // Will be used to assist in setting up default <select> <option>
            endscan
            
        endif

        l_cColumnsToOptions += "]"

//123456
// SendToClipboard(l_cColumnsToOptions)

        oFcgi:p_cjQueryScript += [$(".ColumnsTos").select2({placeholder: '',allowClear: true,data: ]+l_cColumnsToOptions+[,theme: "bootstrap-5",selectionCssClass: "select2--small",dropdownCssClass: "select2--small"});]

        l_cHtml += [<div class="m-3"></div>]   //Spacer

        l_cHtml += [<div class="row justify-content-center m-3">]
            l_cHtml += [<div class="col-auto">]

                l_cHtml += [<table class="table table-sm table-bordered table-striped">]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="6">]+lcApplicationNameFrom+[</th>]
                    l_cHtml += [<th class="GridHeaderRowCells bg-secondary"></th>]  // Extra Column
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">]+lcApplicationNameTo+[</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="6">]+lcTableInfoFrom+[</th>]
                    l_cHtml += [<th class="GridHeaderRowCells bg-secondary"></th>]  // Extra Column
                    l_cHtml += [<th class="GridHeaderRowCells text-white text-center">]
                        select ListOfTablesTo
                        scan all
                            l_cHtml += strtran(strtran(ListOfTablesTo->NameSpace_Name+"."+ListOfTablesTo->Table_Name+FormatAKAForDisplay(ListOfTablesTo->Table_AKA),["],[ ]),['],[ ]) + [<br>]
                        endscan
                    l_cHtml += [</th>]
                l_cHtml += [</tr>]

                l_cHtml += [<tr class="bg-info">]
                    l_cHtml += [<th class="GridHeaderRowCells text-white"></th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Name</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Type</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Nullable</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Foreign Key To</th>]
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Description</th>]
                    l_cHtml += [<th class="GridHeaderRowCells bg-secondary"></th>]  // Extra Column
                    l_cHtml += [<th class="GridHeaderRowCells text-white">Map To</th>]
                l_cHtml += [</tr>]

                select ListColumnsFrom
                scan all
                    l_cInputObjectName  := "MappedToColumn"+Trans(ListColumnsFrom->pk)

                    l_cHtml += [<tr>]

                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            do case
                            case ListColumnsFrom->Column_Primary
                                l_cHtml += [<i class="bi bi-key"></i>]
                            case " "+ListColumnsFrom->Column_Name+" " $ " "+l_cApplicationSupportColumns+" "
                                l_cHtml += [<i class="bi bi-tools"></i>]
                            case !hb_isNil(ListColumnsFrom->Table_Name)
                                l_cHtml += [<i class="bi-arrow-left"></i>]
                            endcase
                        l_cHtml += [</td>]

                        // Name
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
// l_cHtml += Trans(ListColumnsFrom->pk)  // For debugging
                            l_cHtml += ListColumnsFrom->Column_Name+FormatAKAForDisplay(ListColumnsFrom->Column_AKA)
                        l_cHtml += [</td>]

                        // Type
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += FormatColumnTypeInfo(allt(ListColumnsFrom->Column_Type),;
                                                            ListColumnsFrom->Column_Length,;
                                                            ListColumnsFrom->Column_Scale,;
                                                            ListColumnsFrom->Enumeration_Name,;
                                                            ListColumnsFrom->Enumeration_AKA,;
                                                            ListColumnsFrom->Enumeration_ImplementAs,;
                                                            ListColumnsFrom->Enumeration_ImplementLength,;
                                                            ListColumnsFrom->Column_Unicode,;
                                                            "",;
                                                            "",;
                                                            "")
                        l_cHtml += [</td>]

                        // Nullable
                        l_cHtml += [<td class="GridDataControlCells text-center" valign="top">]
                            l_cHtml += iif(ListColumnsFrom->Column_Nullable,[<i class="bi bi-check-lg"></i>],[&nbsp;])
                        l_cHtml += [</td>]

                        // Foreign Key To
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            if !hb_isNil(ListColumnsFrom->Table_Name)
                                l_cHtml += ListColumnsFrom->NameSpace_Name+[.]+ListColumnsFrom->Table_Name+FormatAKAForDisplay(ListColumnsFrom->Table_AKA)
                            endif
                        l_cHtml += [</td>]

                        // Description
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_cHtml += TextToHtml(hb_DefaultValue(ListColumnsFrom->Column_Description,""))
                        l_cHtml += [</td>]

                        l_cHtml += [<td class="GridDataControlCells bg-secondary" valign="top"></td>]  // Extra Column

                        // Entry fields
                        l_cHtml += [<td class="GridDataControlCells" valign="top">]
                            l_iColumnToPk := hb_HGetDef(par_hValues,l_cInputObjectName,0)
                            l_cHtml += [<select name="]+l_cInputObjectName+[" id="]+l_cInputObjectName+[" class="ColumnsTos" style="width:400px">]
                            if l_iColumnToPk = 0
                                oFcgi:p_cjQueryScript += [$("#]+l_cInputObjectName+[").select2('val','0');]  // trick to not have a blank option bar.
                            else
                                //select2 will place the current selected option at the top of the list of options, overriding the initial order.
                                l_cHtml += [<option value="]+Trans(l_iColumnToPk)+[" selected="selected">]+hb_HGetDef(l_hColumnToNames,l_iColumnToPk,"")+[</option>]
                            endif
                            l_cHtml += [</select>]
                        l_cHtml += [</td>]

                    l_cHtml += [</tr>]
                endscan
                l_cHtml += [</table>]
                
            l_cHtml += [</div>]
        l_cHtml += [</div>]

    endif

l_cHtml += [</div>]

l_cHtml += [</form>]

return l_cHtml
//=================================================================================================================
static function InterAppMappingMapColumnsOnSubmit()
local l_cHtml := []
local l_cActionOnSubmit
local l_iApplicationFromPk
local l_iApplicationToPk
local l_hValues := {=>}
local l_iTableFromPk
local l_oDB1                    := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnMapping := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_oDB_ListOfColumnsFrom   := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_nNumberOfMappingsOnFile
local l_hMappedColumnOnFile := {=>}
local l_cInputObjectName
local l_iColumnFromPk
local l_iColumnToPk
local l_iColumnMappingPk

oFcgi:TraceAdd("InterAppMappingMapColumnsOnSubmit")
l_cActionOnSubmit := oFcgi:GetInputValue("ActionOnSubmit")

l_iApplicationFromPk := Val(oFcgi:GetInputValue("ApplicationFromPk"))
l_iApplicationToPk   := Val(oFcgi:GetInputValue("ApplicationToPk"))
l_iTableFromPk       := Val(oFcgi:GetInputValue("TableFromPk"))

l_hValues["ApplicationFromPk"] := l_iApplicationFromPk
l_hValues["ApplicationToPk"]   := l_iApplicationToPk
l_hValues["TableFromPk"]       := l_iTableFromPk

with object l_oDB_ListOfColumnsFrom
    :Table("46360f54-3acf-4ae3-9b8d-d6039e66d18f","Column")
    :Column("Column.pk"          ,"pk")
    :Where("Column.fk_Table = ^" , l_iTableFromPk)
    :SQL("ListColumnsFrom")
endwith

select ListColumnsFrom
scan all
    l_cInputObjectName  := "MappedToColumn"+Trans(ListColumnsFrom->pk)
    l_iColumnToPk       := Val(oFcgi:GetInputValue(l_cInputObjectName))
    if l_iColumnToPk > 0
        l_hValues[l_cInputObjectName] :=  l_iColumnToPk
    endif
endscan

do case
case vfp_inlist(l_cActionOnSubmit,"SaveStay","SaveReturn")

    with object l_oDB_ListOfColumnMapping
        :Table("49d688b2-fd5c-4f71-8c3d-5a492f6b961b","ColumnMapping")
        :Column("ColumnMapping.pk"            , "pk")
        :Column("ColumnMapping.fk_ColumnFrom" , "fk_ColumnFrom")
        :Column("ColumnMapping.fk_ColumnTo"   , "fk_ColumnTo")
        :Join("inner","Column"   ,"Column_From" ,"ColumnMapping.fk_ColumnFrom = Column_From.pk")
        :Join("inner","Column"   ,"Column_To"   ,"ColumnMapping.fk_ColumnTo = Column_To.pk")
        :Join("inner","Table"    ,"Table_To"    ,"Column_To.fk_Table = Table_To.pk")
        :Join("inner","NameSpace","NameSpace_To","Table_To.fk_NameSpace = NameSpace_To.pk")
        :Where("Column_From.fk_Table = ^" , l_iTableFromPk)
        :Where("NameSpace_To.fk_Application = ^" , l_iApplicationToPk)    // To ensure we only get the tables from the Application To list.
        :SQL("ListOfMappingsOnFile")

        l_nNumberOfMappingsOnFile := :Tally
        if l_nNumberOfMappingsOnFile > 0
            hb_HAllocate(l_hMappedColumnOnFile,l_nNumberOfMappingsOnFile)
            select ListOfMappingsOnFile
            scan all
                l_hMappedColumnOnFile[Trans(ListOfMappingsOnFile->fk_ColumnFrom)+"_"+Trans(ListOfMappingsOnFile->fk_ColumnTo)] := ListOfMappingsOnFile->pk
            endscan
        endif
        
    endwith

    select ListColumnsFrom
    scan all
        l_iColumnFromPk     := ListColumnsFrom->pk
        l_cInputObjectName  := "MappedToColumn"+Trans(l_iColumnFromPk)
        l_iColumnToPk       := Val(oFcgi:GetInputValue(l_cInputObjectName))
        if l_iColumnToPk > 0
            l_iColumnMappingPk := hb_HGetDef(l_hMappedColumnOnFile,Trans(l_iColumnFromPk)+"_"+Trans(l_iColumnToPk),0)

            if l_iColumnMappingPk > 0
                //Already on file. Remove from l_hMappedColumnOnFile
                hb_HDel(l_hMappedColumnOnFile,Trans(l_iColumnFromPk)+"_"+Trans(l_iColumnToPk))
                
            else
                // Not on file yet
                with object l_oDB1
                    :Table("96d6bcfa-2541-46f6-8f75-f1fe419400d8","ColumnMapping")
                    :Field("ColumnMapping.fk_ColumnFrom",l_iColumnFromPk)
                    :Field("ColumnMapping.fk_ColumnTo"  ,l_iColumnToPk)
                    :Add()
                endwith
            endif

        endif

    endscan

    //To through what is left in l_hMappedTableOnFile and remove it
    for each l_iColumnMappingPk in l_hMappedColumnOnFile
        //_M_ Should not delete Unless description is blank
        l_oDB1:Delete("4d7e2675-8d08-4dab-b4b6-16c47e7606ce","ColumnMapping",l_iColumnMappingPk)
    endfor

    if l_cActionOnSubmit == "SaveStay"
        l_cHtml := InterAppMappingMapColumnsBuild("",l_hValues)
    else
        InterAppMappingLoadTableMappingInputField(l_iApplicationFromPk,l_iApplicationToPk,@l_hValues)
        l_cHtml := InterAppMappingMapTablesBuild("",l_hValues)
    endif

case l_cActionOnSubmit == "Cancel"
    InterAppMappingLoadTableMappingInputField(l_iApplicationFromPk,l_iApplicationToPk,@l_hValues)
    l_cHtml := InterAppMappingMapTablesBuild("",l_hValues)

otherwise
    //Invalid Action. Reset to start of process
    oFcgi:Redirect(oFcgi:RequestSettings["SitePath"]+"InterAppMapping/")
endcase

return l_cHtml
//=================================================================================================================
static function InterAppMappingLoadTableMappingInputField(par_iApplicationFromPk,par_iApplicationToPk,par_hValues)
local l_oDB_ListOfTableMapping := hb_SQLData(oFcgi:p_o_SQLConnection)
local l_iLastTableFromPk  := 0
local l_cListOfTableToPks := ""

oFcgi:TraceAdd("InterAppMappingLoadTableMappingInputField")

with object l_oDB_ListOfTableMapping
    :Table("5af91839-ca78-494d-b867-4afc0dcba527","TableMapping")
    :Column("TableFrom.pk"            , "fk_TableFrom")
    :Column("TableMapping.fk_TableTo" , "fk_TableTo")
    :Join("inner","Table"    ,"TableFrom"    ,"TableMapping.fk_TableFrom = TableFrom.pk")
    :Join("inner","NameSpace","NameSpaceFrom","TableFrom.fk_NameSpace = NameSpaceFrom.pk")
    :Join("inner","Table"    ,"TableTo","TableMapping.fk_TableTo = TableTo.pk")
    :Join("inner","NameSpace","NameSpaceTo","TableTo.fk_NameSpace = NameSpaceTo.pk")
    :Where("NameSpaceFrom.fk_Application = ^" , par_iApplicationFromPk)
    :Where("NameSpaceTo.fk_Application = ^"   , par_iApplicationToPk)    // To ensure we only get the tables from the Application To list.
    :OrderBy("fk_TableFrom")
    :SQL("ListOfMappingsOnFile")

    select ListOfMappingsOnFile
    scan all
        if ListOfMappingsOnFile->fk_TableFrom <> l_iLastTableFromPk
            l_cListOfTableToPks := ""
        endif
        l_iLastTableFromPk := ListOfMappingsOnFile->fk_TableFrom
        if !empty(l_cListOfTableToPks)
            l_cListOfTableToPks += ","
        endif
        l_cListOfTableToPks += Trans(ListOfMappingsOnFile->fk_TableTo)
        par_hValues["MappedToTables"+Trans(ListOfMappingsOnFile->fk_TableFrom)] := l_cListOfTableToPks   // A little brute force by potentially updating more than once.
    endscan
    
endwith

return nil
//=================================================================================================================
//=================================================================================================================
