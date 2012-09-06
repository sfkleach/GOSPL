/*==========================================================================*/
/* Filename: grobbit.p      Author: Chris Price     Date: 09/11/89          */
/*                                                                          */
/*  Purpose of module:                                                      */
/*    The implementation of the bits of grobbit that you can change.        */
/*                                                                          */
/*  Modifier   Version   Date             Main changes                      */
/* Chris Price     0.1   09/11/89              New module                   */
/*                                                                          */
/*==========================================================================*/


/*==========================================================================*/

flavour grobbit isa creature;

/*==========================================================================*/
    
    
    /*----------------------------------------------------------------------*/
    defmethod same_square( thing, list ) -> real_thing;
    /*----------------------------------------------------------------------*/
    /* Finds the THING in the list on the same square as me (if it exists). */
    lvars thing, list, real_thing=false, item;
        for item in list do
            if (item <- get_name) = thing
            and (item <- position) = ^position then
                item -> real_thing;
            endif;
        endfor;
        
    enddefmethod; /* same_square */
    /*----------------------------------------------------------------------*/
    
    
    /*----------------------------------------------------------------------*/
    defmethod next_turn;
    /*----------------------------------------------------------------------*/
    /* Define what the grobbit does each turn. */
    lvars newxandy = [], what_i_see, accepted, spaces_left, choice=[], to_what;
        
        ^speed -> spaces_left;
        
        while not(choice = "Finish") and ^alive do
        
            /*---------------------------------------------------------------*/
            /* Look round to see what is threatening me (or what I can eat!).*/
            /*---------------------------------------------------------------*/
            nlpr( ['What can ' ^(^get_real_name) '  see?']);
            ^look -> what_i_see;
            nlpr( [ ^what_i_see ] );

            /*--------------------------------------------------------*/
            /* Keep asking for a new position until a valid position  */
            /* been entered.                                          */
            /*--------------------------------------------------------*/
            nlpr( [ ^(^get_real_name) ' can move ' 
                         ^spaces_left ' spaces more this turn.']);
            nlpr( [ 'It is in position ' ^position ] );
            do_menu('What would it like to do? ', 
                       [Move Climb Ground Eat Delve Finish] ) -> choice;
            switchon choice =
                case "Move" then
                    'Input new position as " x y ": ' -> pop_readline_prompt;
                    readline() -> newxandy;
                    nls(1);
                    if length(newxandy) >= 2
                    and isinteger(newxandy(1))
                    and isinteger(newxandy(2)) then
                        ^move(newxandy) -> accepted;
                    endif;
                    nls(2);
                case "Climb" then 
                    ^same_square( "tree", what_i_see ) -> to_what;
                    if (to_what) then
                        ^climb_tree( to_what );
                    else nlpr(['Nothing to climb here!!']);
                    endif;
                case "Ground" then ^ground_level;
                case "Eat" then 
                    ^same_square( "wiffle_flower", what_i_see ) -> to_what;
                    if (to_what) then
                        ^eat_food( to_what );
                    else nlpr(['Nothing to eat here!!']);
                    endif;
                case "Delve" then 
                    ^same_square( "hole", what_i_see ) -> to_what;
                    if (to_what) then
                        ^hide_in_hole( to_what );
                    else nlpr(['No hole to go down here!!']);
                    endif;
                case "Finish" then nlpr(['Ending turn for ' ^(^get_real_name)]);
            endswitchon;
            
            ^speed - ^spaces_moved -> spaces_left;
        endwhile;
    enddefmethod;

endflavour; /* grobbit */

define macro tryout;
    cons_with erase {% run( false ); %}
enddefine
