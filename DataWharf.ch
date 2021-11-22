#include "hb_orm.ch"
#include "hb_vfp.ch"

#define BUILDVERSION "0.13"

#xtranslate NVL(<vValue1>,<xValue2>) => hb_DefaultValue(<vValue1>,<xValue2>)

#define WEBPAGEHANDLE_NAME            1
#define WEBPAGEHANDLE_ACCESSLEVEL     2
#define WEBPAGEHANDLE_FUNCTIONPOINTER 3

#define COLOR_ON_LINK_NEWPAGE "198754"

#define APPLICATION_TITLE "DataWharf"
#define COLOR_HEADER_BACKGROUND "e3f2fd"

#define UPDATESAVEBUTTON [ onchange="$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');$('.HideOnEdit').hide();"]
