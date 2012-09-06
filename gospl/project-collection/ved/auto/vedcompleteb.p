uses vedcomplete;
uses browserslib;
uses prwrappers;

section $-VedComplete => vedcompleteb;

define global vars procedure vedcompleteb();
    lvars name = finditem(), sel;
    lvars onstatus = vedonstatus;
    if onstatus then
        vedswitchstatus()
    endif;
    popupbuffer(
        vedlineoffset + 2, 10,
        maplist(
            name.filecomplete,
            procedure( x ); lvars x;
                consItem( {^name ^x} )
            endprocedure
        ),
        consItem( { 'Files completing ' ^name } ),
        procedure( offset, item, ch );
            lvars offset, item, ch;
            if ch == SELECTCHAR then
                item.itemThings; false
            elseif ch == QUITCHAR then
                false; false
            elseif ch == OPTIONSCHAR then
                popupstdhelp(); true
            elseif ch then
                popupapology( 'Sorry?' ); true
            else
                false; false
            endif
        endprocedure
    ) -> sel;
    if onstatus then
        vedswitchstatus()
    endif;
    if sel then vedinsertstring( sel(2) ) endif;
enddefine;

endsection;
