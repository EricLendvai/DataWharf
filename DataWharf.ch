#include "hb_orm.ch"
#include "hb_vfp.ch"

#define BUILDVERSION "0.14"

#define WEBPAGEHANDLE_NAME            1
#define WEBPAGEHANDLE_ACCESSLEVEL     2
#define WEBPAGEHANDLE_FUNCTIONPOINTER 3

#define COLOR_ON_LINK_NEWPAGE "198754"

#define APPLICATION_TITLE "DataWharf"
#define COLOR_HEADER_BACKGROUND "E3F2FD"
#define COLOR_HEADER_TEXT_WHITE .f.

#define UPDATESAVEBUTTON [ onchange="$('#ButtonSave').addClass('btn-warning').removeClass('btn-primary');$('.HideOnEdit').hide();"]

#define USEDON_APPLICATION 1
#define USEDON_NAMESPACE   2
#define USEDON_TABLE       3
#define USEDON_COLUMN      4
