uses vedcompletions;
uses vedusecompletion;

section $-VedComplete => ved_complete;

define global vars procedure ved_complete();
    if vedvedname = buffername then
        ;;; We are in the completions buffer -- so treat as completer
        vedusecompletion();
    else
        ;;; Try to complete
        lvars name = finditem();
        lvars completions = name.filecomplete;
        if completions.null then
            vedscreenbell()
        elseif completions.tl.null then
            vedinsertstring( completions.hd )
        else
            partcomplete( completions );
            showcompletions( name, completions );
        endif
    endif
enddefine;

endsection;
