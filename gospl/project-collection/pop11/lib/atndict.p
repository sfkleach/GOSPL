
/* LIB ATNDICT                                     Allan Ramsay 9 November 1983
 *
 * Dictionary for use with LIB ATNPARSE
 * Entries must be of the form
 *  <word> [<feature1> <value1> ... <featureN> <valueN>] ;
 * ending with a semi-colon.
 *
 * If you want a word to have more than one sense, simply give it more than
 * one feature set, e.g.
 *
 *      bat     [cat noun animate true] [cat verb trans 0] ;
 *
 * would say that "bat" can be either of type "noun", in which case it has the
 * feature "animate" set to true, or of type "verb",in which case the feature
 * trans is set to 0.
 */

vars hash_dict ; newproperty(nil, 100, false, true) -> hash_dict;

define compress (list) ;
[%  false,
    until   null(list)
    do      conspair(dest(list)->list, dest(list) -> list)
    enduntil
%]
enddefine;

define read_word () ;
vars x name ;
itemread() -> name;
if name == "enddictionary" then return(false) endif;
[% name,
   until   (listread()->>x) == ";"
   do      if x == termin then mishap('Reading end of file', nil) endif,
           compress(x)
   enddo %]
enddefine;

define macro dictionary ;
vars x y w ;
while   read_word() ->> w
do      dest(w) -> w -> x; w -> hash_dict(x);
endwhile;
enddefine;

dictionary
    a           [cat det num sing def false] ;
    apple       [cat noun] ;
    are         [cat verb type be trans 1 aux true] ;
    ball        [cat noun] ;
    bat         [cat noun animate true] [cat verb trans 0] ;
    be          [cat verb type be trans 1 aux true] ;
    big         [cat adj] ;
    block       [cat noun] ;
    blue        [cat adj] ;
    book        [cat noun] ;
    boy         [cat noun] ;
    by          [cat prep] ;
    cake        [cat noun] ;                   
    cat         [cat noun] ;
    dead        [cat adj] ;
    did         [cat verb type did aux true trans 1] ;
    die         [cat verb trans 0] ;
    dog         [cat noun] ;
    downright   [cat adj] ;
    eat         [cat verb trans 1] ;
    for         [cat prep] ;
    girl        [cat noun] ;
    give        [cat verb trans 2] ;
    good        [cat adj] ;
    has         [cat verb type have trans 1 aux true] ;
    have        [cat verb type have trans 1 aux true] ;
    he          [cat pronoun] ;
    hit         [cat verb trans 1] ;
    horse       [cat noun] ;
    I           [cat pronoun] ;
    is          [cat verb type be trans 1 aux true] ;
    it          [cat pronoun] ;
    kill        [cat verb trans 1] ;
    kiss        [cat verb trans 1] ;
    like        [cat verb trans 1] ;
    man         [cat noun] ;
    me          [cat pronoun] ;
    meat        [cat noun] ;
    nose        [cat noun] ;
    nuisance    [cat noun] ;
    old         [cat adj] ;
    on          [cat prep] ;
    put         [cat verb trans 2] ;
    read        [cat verb trans 1] ;
    red         [cat adj] ;
    run         [cat verb trans 0] ;
    stick       [cat noun] ;
    table       [cat noun] ;
    the         [cat det det def] ;
    to          [cat prep] ;
    tragedy     [cat noun] ;
    want        [cat verb trans 1] ;
    was         [cat verb type be trans 1 aux true] ;
    with        [cat prep] ;
enddictionary;

uses atnends;
