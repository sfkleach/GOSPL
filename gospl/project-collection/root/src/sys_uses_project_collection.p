compile_mode :pop11 +strict;

section;

vars pop_project_search_list = [];

define sys_uses_project_collection( dir );
    unless sys_file_exists( dir ) then
        mishap( 'Project collection directory does not exist', [ ^dir ] )
    endunless;
    extend_searchlist( dir, pop_project_search_list ) -> pop_project_search_list;
enddefine;

endsection;
