
section $-hip ;

;;; Added for "uses" --- YUK.  SFK
global vars hip_custom_menubar = true;

define lconstant popup_action(menubar, menu, option); lvars menubar, menu, option;
    ;;; do nothing
enddefine;

define lconstant menu_action(menubar, menu, option, state);
    lvars menubar, menu, option, state;

    hip_input(procedure(sb, option, state); lvars sb, option, state;
        ;;; the following really ought to be done, but the identifiers
        ;;; may cancelled so that I can't do it:

#_IF DEF sb_window
        sb.sb_window -> the_current_focus_window();
#_ENDIF
        lvars sc = hipStoryboardCurrentScene( sb );
        if sc then
            hip_send(sc, option, state);
        endif;
    endprocedure(%menubar.menupane_client_data, option, state%));
enddefine;

define lconstant storyboard_to_menuspec
    = newproperty([], 4, false, "tmparg");
enddefine;

lconstant MS_CUSTOM_MENUBAR = 1, MS_STANDARD_MENUBAR = 2, MS_MENU = 3;

;;; --- MENUBAR MANAGEMENT

define lconstant custom_menubar_visible(sb); lvars sb;
    lvars menuspec = sb.storyboard_to_menuspec;
    return(menuspec and XtIsManaged(menuspec(MS_CUSTOM_MENUBAR)));
enddefine;

define updaterof custom_menubar_visible(state, sb); lvars state, sb;
    lvars menuspec = sb.storyboard_to_menuspec;

    unless menuspec then
        mishap(menuspec, 1, 'NO CUSTOM MENUBAR');
    endunless;

    lvars
        custom_menubar = menuspec(MS_CUSTOM_MENUBAR),
        standard_menubar = menuspec(MS_STANDARD_MENUBAR),
        main_window = custom_menubar.XtParent,
    ;

    if state then
        XtManageChild(custom_menubar);
        XtVaSetValues(main_window, XtN menuBar, custom_menubar, 2);
        XtUnmanageChild(standard_menubar);
    else
        XtManageChild(standard_menubar);
        XtVaSetValues(main_window, XtN menuBar, standard_menubar, 2);
        XtUnmanageChild(custom_menubar);
    endif;
enddefine;

define lconstant custom_menupane(sb); lvars sb;
    lvars menuspec = sb.storyboard_to_menuspec;
    menuspec and menuspec(MS_CUSTOM_MENUBAR);
enddefine;

define lconstant custom_menubar(sb); lvars sb;
    lvars menuspec = sb.storyboard_to_menuspec;
    menuspec and menuspec(MS_MENU);
enddefine;

define updaterof custom_menubar(menu, sb); lvars menu, sb;
    lvars menuspec = sb.storyboard_to_menuspec;

    if menuspec then
        ;;; must deal with existing custom menubar
        returnif(menuspec(MS_MENU) = menu);
        false -> custom_menubar_visible(sb);
        XtDestroyWidget(menuspec(MS_CUSTOM_MENUBAR));
        false -> sb.storyboard_to_menuspec;
    endif;

    lvars mp;
    compile([menupane_compile ^menu]) -> mp;

    ;;; find the appropriate parent
    lvars main_window = sb;
    until (XtParent(main_window) ->> main_window).XmIsMainWindow do ; enduntil;

    {%
        ;;; make the menubar
        menupane_new_menubar(main_window, popup_action, menu_action, sb, mp),

        ;;; remember the old menubar
        XptValue(main_window, XtN menuBar, TYPESPEC(:XptWidget)),

        ;;; remember the menu specification
        menu,
    %} -> sb.storyboard_to_menuspec;
enddefine;

_hip_add_properties("Storyboard", [
    customMenuBar ^custom_menubar
    customMenuBarVisible ^custom_menubar_visible
    customMenuBarPane ^custom_menupane
]);

endsection;
