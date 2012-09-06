uses vedcomplete;

section $-VedComplete => vedcompletions;

constant buffername = '*COMPLETIONS*';

define showcompletions( name, completions ); lvars name, completions;
    if vedvedname = buffername then
        ved_qved( buffername -> vedargument )
    else
        vededitor(
            vedhelpdefaults,
            buffername
        )
    endif;
    ved_clear();
    vedputmessage(
        length( completions ) sys_><
        ' File completions for ' sys_><
        name
    );
    applist(
        completions,
        procedure( c ); lvars c;
            vedinsertstring( name );
            vedinsertstring( c );
            vednextline();
        endprocedure
    );
    vedtopfile();
enddefine;

define global vars procedure vedcompletions();
    dlocal vedargument;
    lvars name = finditem();
    lvars completions = name.filecomplete;
    showcompletions( name, completions );
enddefine;

endsection;
