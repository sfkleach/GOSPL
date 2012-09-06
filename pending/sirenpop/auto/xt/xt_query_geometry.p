;;; The following code is adapted from LIB PROPSHEET.

compile_mode :pop11 +strict;

section;

XptLoadProcedures 'propsheet_utils'
lconstant
    XtQueryGeometry,        ;;; find a widgets preferred size
;

;;; Returns the widgets preferred size
define global xt_query_geometry( w ); lvars w;
    ;;; See <X11/Intrinsic.h>
    l_typespec XtWidgetGeometry {
        mask    : uint, /* XtGeometryMask */
        x       : XptPosition,
        y       : XptPosition,
        width   : XptDimension,
        height  : XptDimension,
        sibling : XptWidget,
        stack_mode :int,
      },
        preferred : XtWidgetGeometry,
    ;
    lconstant preferred = EXPTRINITSTR(:XtWidgetGeometry);
    ;;; this should probably do more checking
    exacc [fast] (3) raw_XtQueryGeometry(w, null_external_ptr, preferred);
    exacc [fast] preferred.x;
    exacc [fast] preferred.y;
    exacc [fast] preferred.width;
    exacc [fast] preferred.height;
enddefine;

endsection
