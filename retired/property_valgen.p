compile_mode :pop11 +strict;

section;

define lconstant installer( key, self, gen );
    ;;; highly advisable to check gen returns 1 and only 1 result
    gen( key ) ->> self( key )
enddefine;

define property_valgen( p );
    lvars a = property_active( p );
    unless a.isclosure and pdpart( a ) == installer do
        mishap( 'property\'s active procedure was not created by property_valgen', [^a] )
    endunless;
    frozval( 1, a )
enddefine;

define updaterof property_valgen( procedure g, p );
    installer(% g %) -> property_active( p )
enddefine;

endsection;
