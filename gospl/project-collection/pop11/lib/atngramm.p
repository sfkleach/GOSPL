
/* LIB ATNGRAMM                                   Allan Ramsay 11 January 1984
 * ATN grammar for use with LIB ATNPARSE
 */

registers Mods Aux Mood Rel Trans MV Subj DO IO Det Num Yesno Ques ;

clear_grammar;

network NP [a]
    a b det     <<< #det -> Det; if #num then #num -> Num endif >>>
    a c pronoun
                <<< if #num then #num -> Num endif;
                    if #rel then #rel -> Rel endif >>>
    a c proper ;
    a e pop     <<< test(Hold /== nil and hd(Hold)@Cat == "NP");
                    hd(Hold)@Tree -> Tree; tl(Hold) -> Hold >>>
    b c noun    <<< if      #ending == "s" or #num == "plural"
                    then    test(Num /== "sing");
                            "plural" -> Num;
                    elseif  #num /== "either"
                    then    test(Num /== "plural");
                            "sing" -> Num;
                    endif >>>
    b b adj ;
    c d pop ;
    c c PP ;
    c c S_p ;
endnetwork;

network PP [a]
    a b prep ;
    b c NP ;
    c d pop     <<< #Rel -> Rel >>>
    a c j       <<< test(Hold /== nil and hd(Hold)@Cat == "PP");
                hd(Hold)@Tree -> Tree; tl(Hold) -> Hold >>>
endnetwork;

network S [a p q x]
    a b NP      <<< nil -> Mods;
                    if #Rel then "true" -> Ques endif; #Tree -> Subj >>>
    x y "for"   <<< nil -> Mods >>>
    y z NP ;
    z c "to";
    p q NP      <<< test(#Rel == "true"); "true" -> Ques;
                    Child :: Hold -> Hold; nil -> Tree >>>
    q a verb    <<< test(#aux == "true"); nil -> Mods;
                Child :: Hold -> Hold; "true" ->> Yesno -> Ques >>>
    b c verb    <<< test( (#ending == "false" and Aux == "undef")
                                or
                          (#ending /== "false" and Aux /== "undef"));
                    Child -> MV; #trans -> Trans >>>
    b b j       <<< test(Hold /== nil and hd(Hold)@cat == "verb");
                tl(Tree) -> Tree;
                hd(Hold) :: Text -> Text; tl(Hold) -> Hold >>>
    c c verb    <<< test(MV @ aux == "true");
                MV -> Aux; Child -> MV; #trans -> Trans;
                if #ending=="en" and Aux @ type == "be"
                                    then "passive" -> Mood endif >>>
    c d j       <<< test( Mood == "passive" or Trans == 0) >>>
    c d NP      <<< #Tree -> DO >>>
    d e j       <<< test( Mood == "passive" or Trans < 2 ) >>>
    d e NP      <<< DO -> IO; #Tree -> DO >>>
    e e PP      <<< test(Mood == "passive");
                if DO == "undef" then Subj -> DO else Subj -> IO endif;
                #Tree -> Subj >>>
    e e PP      <<< #Tree :: Mods -> Mods >>>
    e f pop     <<< test(Text == nil);
                    test( (Trans == 0 and DO == "undef")
                            or
                          (Trans == 1 and DO /=="undef" and IO == "undef")
                            or
                          (Trans == 2 and DO /== "undef" and IO /== "undef"));
                    if      Trans == 0
                    then    [MV [% MV @ root, MV @ cat %] Subj ^(Subj)
                                Mods ^(Mods)]
                    elseif  Trans == 1
                    then    [MV [% MV @ root, MV @ cat %]
                                Subj ^(Subj) DO ^(DO) Mods ^(Mods)]
                    else    [MV [% MV @ root, MV @ cat %]
                                Subj ^(Subj) DO ^(DO) IO ^(IO) Mods ^(Mods)]
                    endif -> Tree;>>>
endnetwork;

network S_p [i]
    i S j       <<< test( not(!Cat == "S_r" and !Text == Text)) >>>
    S p branch ;
endnetwork;

set_grammar;
