//Copyright (c) 2024 Eric Lendvai MIT License
#include "DataWharf.ch"
//=================================================================================================================
class Grid
    hidden:
        data p_abTitle           init {}
        data p_cAlias            init ""
        data p_aGridLayout       init {}
        data p_bRowExtraClasses  init nil
        data p_bOnRowBuild       init nil   // Code to execute before a new row is built
        data p_ShowColumnHeaders init .t.
    exported:
        method SetTitle(par_bTitle)
        method SetAlias(par_cName)
        method AddColumn(par_hGridColumnDefinition)
        method SetRowExtraClasses(par_bLogic)
        method SetOnRowBuild(par_bOnRowBuild)
        method HideColumnHeaders() inline ::p_ShowColumnHeaders := .f.
        method Build()
endclass
//=================================================================================================================
method SetTitle(par_bTitle)
AAdd(::p_abTitle,par_bTitle)
return nil
//=================================================================================================================
method SetAlias(par_cName)
::p_abTitle := {}
::p_cAlias  := par_cName
ASize(::p_aGridLayout,0)
return nil
//=================================================================================================================
method AddColumn(par_hGridColumnDefinition)
AAdd(::p_aGridLayout,par_hGridColumnDefinition)
return nil
//=================================================================================================================
method SetRowExtraClasses(par_bLogic)
::p_bRowExtraClasses := par_bLogic
return nil
//=================================================================================================================
method SetOnRowBuild(par_bOnRowBuild)
::p_bOnRowBuild := par_bOnRowBuild
return nil
//=================================================================================================================
method Build()
local l_cHtml := ""
local l_select := iif(used(),select(),0)
local l_hGridLayout
local l_bTitle
local l_cTitle
local l_nNumberOfActiveColumn := 0
local l_nNumberOfRows
local l_cAlign
local l_bExpressionParameter
local l_xExpressionParameter
local l_bCellExtraClasses
local l_cCellExtraClasses
local l_lShowColumn
local l_alColumnCondition := {}
local l_acColumnRowAlign := {}
local l_nColumnCounter
local l_cThClass
local l_cTrExtraClass

local l_cHtmlHeader := ""
local l_cTableId

select (::p_cAlias)

l_nNumberOfRows := (::p_cAlias)->(reccount())

oFcgi:p_iHtmlObjectIdCounter++
l_cTableId := "Grid_"+trans(oFcgi:p_iHtmlObjectIdCounter)

l_cHtml += [<table class="table table-sm table-bordered wf-grid" id="]+l_cTableId+[" style="width: auto;">]+[<thead>]

    l_cHtmlHeader += [<tr class="bg-primary bg-gradient">]
        for each l_hGridLayout in ::p_aGridLayout
            l_lShowColumn := eval(hb_HGetDef(l_hGridLayout,"Condition",{||.t.}))
            AAdd(l_alColumnCondition,l_lShowColumn)
            if l_lShowColumn
                l_nNumberOfActiveColumn++
                l_cAlign   := lower(hb_HGetDef(l_hGridLayout["Header"],"Align","left"))
                l_cThClass := hb_HGetDef(l_hGridLayout["Header"],"Class","GridHeaderRowCells text-white")
                l_cHtmlHeader += [<th class="]+l_cThClass+iif((l_cAlign=="center"),[ text-center],iif((l_cAlign=="right"),[ text-end],[]))+[">]+l_hGridLayout["Header"]["Caption"]+[</th>]

                l_cAlign  := lower(hb_HGetDef(l_hGridLayout["Rows"],"Align","left"))
                AAdd(l_acColumnRowAlign,iif((l_cAlign=="center"),[ text-center],iif((l_cAlign=="right"),[ text-end],[])))
            else
                AAdd(l_acColumnRowAlign,"")
            endif

        endfor
    l_cHtmlHeader += [</tr>]

    for each l_bTitle in ::p_abTitle
        l_cTitle := eval(l_bTitle,l_nNumberOfRows)
        if !empty(l_cTitle)
            l_cHtml += [<tr class="bg-primary bg-gradient">]   //  bg-opacity-10
                l_cHtml += [<th class="GridHeaderRowCells text-white text-center" colspan="]+trans(l_nNumberOfActiveColumn)+[">]+l_cTitle+[</th>]
            l_cHtml += [</tr>]
        endif
    endfor

    if ::p_ShowColumnHeaders
        l_cHtml += l_cHtmlHeader
    endif

    l_cHtml += [</thead>]

    scan all
        if !hb_IsNil(::p_bOnRowBuild)
            eval(::p_bOnRowBuild)
        endif
        if hb_IsNil(::p_bRowExtraClasses)

            if mod(recno(),2) == 0
                l_cTrExtraClass := "GridRowEven"
            else
                l_cTrExtraClass := "GridRowOdd"
            endif

        else
            l_cTrExtraClass := eval(::p_bRowExtraClasses)
        endif
        l_cHtml += [<tr class="GridRow ]+l_cTrExtraClass+[">]
            l_nColumnCounter := 0
            for each l_hGridLayout in ::p_aGridLayout
                l_nColumnCounter++
                if l_alColumnCondition[l_nColumnCounter]

                    l_bExpressionParameter := hb_HGetDef(l_hGridLayout["Rows"],"ExpressionParameter",nil)
                    if hb_IsNil(l_bExpressionParameter)
                        l_xExpressionParameter := nil
                    else
                        l_xExpressionParameter := eval(l_bExpressionParameter)
                    endif

                    l_bCellExtraClasses := hb_HGetDef(l_hGridLayout["Rows"],"CellExtraClasses",nil)
                    if hb_IsNil(l_bCellExtraClasses)
                        l_cCellExtraClasses := ""
                    else
                        l_cCellExtraClasses := eval(l_bCellExtraClasses)
                        if !empty(l_cCellExtraClasses)
                            l_cCellExtraClasses := " "+l_cCellExtraClasses
                        endif
                    endif

                    l_cHtml += [<td class="GridDataControlCells]+l_acColumnRowAlign[l_nColumnCounter]+l_cCellExtraClasses+[" valign="top">]
                        l_cHtml += eval(l_hGridLayout["Rows"]["Expression"],l_xExpressionParameter)
                    l_cHtml += [</td>]
                endif
            endfor
        l_cHtml += [</tr>]
    endscan

l_cHtml += [</table>]

//Set behavior to go to the link on a cell click
oFcgi:p_cjQueryScript +=[$('.wf-grid td:has(.GridLinkNewPage)')]+;
                            [.bind("click",function(e) {e.stopPropagation();let cHref = $(this).find('a').attr('href');if (typeof cHref !== 'undefined') {window.open(cHref,'_blank');}})]+;
                            [.hover(function() {$(this).css('background-color','rgba(0, 0, 0, 0.2)').css('cursor','pointer');},function() {$(this).css('background-color','').css('cursor','');})]+;
                            [;]

//Set behavior to go to the link in new window on a cell click
oFcgi:p_cjQueryScript +=[$('.wf-grid td:has(.GridLinkNormal)')]+;
                            [.bind("click",function(e) {e.stopPropagation();let cHref = $(this).find('a').attr('href');if (typeof cHref !== 'undefined') {window.location.href=cHref;}})]+;
                            [.hover(function() {$(this).css('background-color','rgba(0, 0, 0, 0.2)').css('cursor','pointer');},function() {$(this).css('background-color','').css('cursor','');})]+;
                            [;]

//Set behavior to go to the default link on a row click
oFcgi:p_cjQueryScript += [$('.wf-grid tr').bind("click",function(e) {let cHref = $(this).find('.DefaultLink:first').attr('href');if (typeof cHref !== 'undefined') {window.location.href=cHref;}});]

if oFcgi:SetupJavaScriptjQueryFloatTableHeader()
    // oFcgi:p_cjQueryScript += [$('#]+l_cTableId+[').floatThead({position: 'fixed'});]
    oFcgi:p_cjQueryScript += [$('#]+l_cTableId+[').floatThead({position: 'auto'});]
endif

select (l_select)
return l_cHtml
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
//=================================================================================================================
