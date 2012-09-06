
/* LIB WORDENDS                                   Allan Ramsay, 9 December 1983
 *
 * This program simply strips letters off the end of a word until it finds
 * that (a) the letters that have been removed constitute a legitimate
 * English word ending and (b) the letters that remain constitute a word that
 * is in your dictionary. Very simple, fairly effective. The third column in
 * the table of endings is either false or a list of letters which should be
 * added back onto the word before you look it up (the only case where this is
 * actually given a value in the table provided is for coping with the "e"
 * that gets dropped when "change" becomes "changing", "cope" becomes "coping"
 * etc). FIND_ENDING returns the dictionary entry that was found and the
 * suffix which was removed.
 *
 * It is assumed that words in the dictionary have had a list of lists of the form
 *      [ <false> [feature1 . value1] ... [featureN . valueN] ]
 * assigned to them in the property table "hash_dict", where the
 * [feature . value] entries are PAIRS embodying lexical information about
 * the word (e.g. its syntactic category, ... - see LIB ATNDICT for examples).
 *
 * PRE_ANALYSE takes a list of words, finds their dictionary entry and suffix,
 * and replaces them by their [feature . value] lists, with entries for the
 * root and suffix added on the end. This is used by LIB ATNPARSE.
 */

if      identprops("alistval") == "undef"
then    define constant alistval (key,alist) -> val ;
        vars x ;
        false -> val;
        for x in tl(alist)
        do   if front(x) == key then x -> val exit;
        endfor;
        enddefine;

        define updaterof alistval (val,key,alist) ;
        vars x ;
        if      alistval(key,alist) ->> x
        then    val -> back(x)
        else    conspair(key,val) :: tl(alist) -> tl(alist)
        endif;
        enddefine;

endif;
vars ending_table ;

[   [??root]        false       false
    [??root i n g]  ing         false
    [??root e d]    ed          false
    [??root d]      ed          false
    [??root e n]    en          false
    [??root n]      en          false
    [??root e s]    s           false
    [??root s]      s           false
    [??root i n g]  ing         false
    [??root ?x i n g]   ing     false
    [??root ?x e d] ed          false
    [??root i n g]  ing         [e]
] -> ending_table;

define constant find_ending (word,ending_table) -> suffix -> root ;
vars x y l ;
maplist([% explode(word) %],consword(%1%)) -> l;
until   ending_table == []
do      dest(dest(dest(ending_table))) -> ending_table -> y -> suffix -> x;
        if      l matches x
        then    if islist(y) then root <> y -> root endif;
                consword(applist(root,explode),length(root)) -> root;
                if (hash_dict(root) ->> x) and alistval("cat",hd(x)) then exit;
        endif;
enduntil;
mishap('Cannot match word against anything in dictionary', [% word %]);
enddefine;

define constant pre_analyse (text);
vars x r s root ;
[%until text == []
  do    find_ending(dest(text) -> text,ending_table) -> s -> r;
        hash_dict(r) -> root;
        [% for x in root
           do x <> [% conspair("root",r), conspair("ending", s) %]
           endfor %]
enduntil %]
enddefine;
                 
