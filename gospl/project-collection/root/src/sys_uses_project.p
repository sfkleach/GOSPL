compile_mode :pop11 +strict;

section;


;;; This ought to be part of a user-accessible interface, but I
;;; don't have the time to design something long-lasting :-(
lvars projects_loaded = [];

define sys_uses_project( name );
    lvars f = (
        syssearchpath(
            pop_project_search_list,
            name
        )
    );
    unless f do
        mishap( name, 1, 'Project cannot be found' )
    endunless;
    unless member( f, projects_loaded ) do
        sys_load_project( f );
        conspair( f, projects_loaded ) -> projects_loaded
    endunless
enddefine;



endsection;
