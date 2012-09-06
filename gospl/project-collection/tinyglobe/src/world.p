/*==========================================================================*/
/*  Filename: world.p             Authors: Dave Pugh and Chris Price        */
/*                                                                          */
/*  Purpose of module:                                                      */
/*    The implementation of the TinyGlobe World.                            */
/*                                                                          */
/*  Modifier   Version   Date             Main changes                      */
/* Steve Knight    0.5   02/02/90     Default setup file + declarations     */
/* Chris Price     0.4   04/01/90     Grow more flowers every turn.         */
/* Chris Price     0.3   17/11/89     Nastier monsters.                     */
/* Chris Price     0.2   09/11/89     I wrote some bits of this too.        */
/* David R Pugh    0.1   01/11/89              New module                   */
/*                                                                          */
/*==========================================================================*/

/*==========================================================================*/
/*==========================================================================*/
/* **********           GLOBAL INITS - DON'T TOUCH               ********** */
/*==========================================================================*/
/*==========================================================================*/

;;; Load the flavours library
vars done_initialisations;
if isundef(done_initialisations) then
      uses flavours;         /* Load the flavours library.            */
      vars world_*;          /* Global declaration of WORLD variable. */
      constant boardsize;    /* Size of grid.                         */
      50 -> boardsize;
      true -> done_initialisations;
      vars default_setupfile = '$poplocal/local/lib/tinyglobe/datafile';
endif;


/*==========================================================================*/
/*==========================================================================*/
/* ********* FAIRLY BORING I/O ROUTINES - REUSE THEM IF YOU WISH. ********* */
/*==========================================================================*/
/*==========================================================================*/

define lpr( the_list );

/*==========================================================================*/
/* Print the items in a list. */
lvars the_list, item;
    for item in the_list do
        pr( item );
    endfor;
enddefine; /* lpr */

/*==========================================================================*/

define nlpr( the_list );

/*==========================================================================*/
/* Print the items in a list, followed by a newline character. */
lvars the_list;
    lpr( the_list );
    pr(newline);
enddefine; /* nlpr */

/*==========================================================================*/

define nls( lines );

/*==========================================================================*/
/* Print "lines" newline characters. */
lvars i, lines;
    for i to lines do
        pr(newline);
    endfor;
enddefine; /* nls */

/*==========================================================================*/

define do_get_string( the_prompt ) -> the_response;

/*==========================================================================*/
/* Print the prompt, read a line of reply and turn it into a string. */
lvars the_prompt, the_response = [];

    the_prompt -> pop_readline_prompt;
    readline() -> the_response;

    explode(the_response) >< '' -> the_response;

enddefine; /* do_get_string */


/*==========================================================================*/

define do_get_number( the_prompt ) -> the_response;

/*==========================================================================*/
lvars the_prompt, the_response = [];

    while the_response = [] do
        the_prompt -> pop_readline_prompt;
        readline() -> the_response;
        unless (the_response = []) then
            the_response(1) -> the_response;
            unless (isnumber(the_response)) then
               nlpr( [ 'Sorry, your answer must be a number.' ]);
               [] -> the_response;
            endunless;
        endunless;
    endwhile;

enddefine; /* do_get_number */

/*==========================================================================*/

define do_menu( the_prompt, the_options ) -> option;

/*==========================================================================*/
/* Don't ask questions if menu only had one entry.  */
lvars the_prompt, the_options, option = 0, the_text, i = 0;

    unless (length(the_options) > 1) then
        1 -> option;
    else
        while option = 0 do
            nls(1);
            nlpr([^the_prompt]);
            for the_text in the_options do
                i + 1 -> i;
                nlpr([' ' ^i '. ' ^the_text]);
            endfor;
            do_get_number('Please make a selection: ') -> option;
            if ((option < 1) or (option > i)) then
                nlpr( ['The input must be in the range 1 - ' ^i ' not ' ^option ]);
                0 -> option;
                0 -> i;
            endif;
        endwhile;
        nls(1);
    endunless;
    the_options(option) -> option; /* Return the choce, not the number. */
enddefine; /* do_menu */


/*==========================================================================*/
/*==========================================================================*/
/* **********  MORE INTERESTING WORLD ROUTINES - USE THEM TOO.   ********** */
/*==========================================================================*/
/*==========================================================================*/

define sort_edibles( menu, list ) -> newlist;

/*==========================================================================*/
/* Given a list, it returns all items in list whose class is in menu. */
/* The new list is ordered in the same order as menu.                 */
lvars menu, list, newlist, edible, item;
    [% for edible in menu do
           for item in list do
               if (item <- get_name) = edible then
                   item;
               endif;
           endfor;
       endfor; %] -> newlist;

enddefine; /* sort_from_list */


/*==========================================================================*/

define calc_offset( int1, int2 ) -> offset;

/*==========================================================================*/
lvars int1, int2, offset;
    abs( int1 - int2 ) -> offset;
    /* Take into account being near end of board. */
    if boardsize - offset < offset then
        boardsize - offset -> offset;
    endif;

enddefine; /* calc_offset */


/*==========================================================================*/

define distance_away( position1, position2 ) -> distance;

/*==========================================================================*/
lvars position1, position2, distance, xdistance, ydistance;

/*-----------------------------------------------------*/
/* Distance away is defined as x offset plus y offset, */
/* where a position is represented as [x y].           */
/* Made more complicated because board wraps round.    */
/*-----------------------------------------------------*/

    calc_offset(position1(1), position2(1)) -> xdistance;
    calc_offset(position1(2), position2(2)) -> ydistance;

    xdistance + ydistance -> distance;

enddefine; /* distance_away */


/*==========================================================================*/

define death_message;

/*==========================================================================*/
lvars message_list = [ 'Do not go gentle into that good night.'
                       'NO NO NOOOOOOOOOOooooo....'
                       'They\'re tasty, tasty, very very tasty...'
                       'Goodbye cruel world.'
                       'SPLAT.'
                       'I\'ll do better next time.'
                       'Aaaaaaaaaaaaaaarrrrggghh.'
                       'Grobbit, schmobbit, give me beef.'
                       'Owwwww, that\'s my leg.'
                       'I never could get the hang of Thursdays.'
                       'I\'m afraid the grobbit is dead, Jim.'
                       'Every grobbit carries a government health warning.'
                       'Holy cow, Grobbitman, they\'ve got me this time.' ];
    pr( '          ' );
    pr( message_list(random(length(message_list)))); nls(1);
enddefine; /* death_message */


/*==========================================================================*/
/*==========================================================================*/
/* ******** FLAVOUR STUFF - DON'T TOUCH UNLESS I'VE SAID YOU CAN. ********* */
/*==========================================================================*/
/*==========================================================================*/

flavour object_in_world;

/*==========================================================================*/
ivars position, alive = true, realname, spaces_moved=0,
      able_to_climb=false, up_a_tree = false, down_a_hole = false;

    /*----------------------------------------------------------------------*/
    defmethod get_name -> myname;
    /*----------------------------------------------------------------------*/
    /* Return the name of the class when asked. */
    lvars myname;
       (^myflavour <- name) -> myname;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod get_real_name -> myname;
    /*----------------------------------------------------------------------*/
    /* Return the name of the actual object when asked. */
    lvars myname;
       ^realname -> myname;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod printself;
    /*----------------------------------------------------------------------*/
    /* Print the details of ones self. */
        nlpr( [ ^(^get_real_name) ' is at ' ^position '.' ]);
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod dec_nourishment;  /* Does nothing as default. */
    /*----------------------------------------------------------------------*/
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod next_turn;  /* Does nothing as default. */
    /*----------------------------------------------------------------------*/
    enddefmethod; /* next_turn */

    /*----------------------------------------------------------------------*/
    defmethod make_move;
    /*----------------------------------------------------------------------*/
    /* Each object takes it in turn to move */
        0 -> ^spaces_moved; /* Can only move ^speed spaces per turn. */
        if ^alive then
           ^next_turn;
           ^dec_nourishment;
        endif;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod xpos -> xval;
    /*----------------------------------------------------------------------*/
    lvars xval;
        (^position)(1) -> xval;
    enddefmethod; /* xpos */

    /*----------------------------------------------------------------------*/
    defmethod ypos -> yval;
    /*----------------------------------------------------------------------*/
    lvars yval;
        (^position)(2) -> yval;
    enddefmethod; /* ypos */




    /*----------------------------------------------------------------------*/
    /* DUMMY METHODS TO ALLOW PEOPLE TO SEND STUPID MESSAGES IF THEY MUST.  */
    /*----------------------------------------------------------------------*/

    /*----------------------------------------------------------------------*/
    defmethod climb_tree(tree);
    /*----------------------------------------------------------------------*/
    lvars tree;
        nlpr( [ 'Sorry, a ' ^(^get_name) ' does not go up trees.' ]);
    enddefmethod; /* climb_tree */

    /*----------------------------------------------------------------------*/
    defmethod hide_in_hole(hole);
    /*----------------------------------------------------------------------*/
    lvars hole;
        nlpr( [ 'Sorry, a ' ^(^get_name) ' does not go down holes.' ]);
    enddefmethod; /* hide_in_hole */

    /*----------------------------------------------------------------------*/
    defmethod ground_level;
    /*----------------------------------------------------------------------*/
        nlpr( [ 'Sorry, a ' ^(^get_name) ' does not move at all.' ]);
    enddefmethod; /* ground_level */

    /*----------------------------------------------------------------------*/
    defmethod move( dummy );
    /*----------------------------------------------------------------------*/
    lvars dummy;
        nlpr( [ 'Sorry, a ' ^(^get_name) ' cannot move.' ]);
    enddefmethod; /* move */

    /*----------------------------------------------------------------------*/
    defmethod eat_food( dummy );
    /*----------------------------------------------------------------------*/
    lvars dummy;
        nlpr( [ 'Sorry, but ' ^(^get_name) 's do not have appetites.']);
    enddefmethod; /* eat_food */

    /*----------------------------------------------------------------------*/
    defmethod be_eaten(eater) -> food_value;
    /*----------------------------------------------------------------------*/
    lvars food_value = 0, eater;
        nlpr( [ 'Sorry, but ' ^(^get_name) 's cannot be eaten.']);
    enddefmethod; /* be_eaten. */

endflavour; /* object_in_world */


/*==========================================================================*/

flavour creature isa object_in_world;

/*==========================================================================*/
ivars speed=0, seeing_distance=0, nourishment = 100, potential_food = [];


    /*----------------------------------------------------------------------*/
    defmethod climb_tree( the_tree );
    /*----------------------------------------------------------------------*/
    lvars the_tree;
    /* Climb a tree. */
        if not(able_to_climb) then
            nlpr(['Sorry, but ' ^(^get_name) 's cannot climb.']);
        elseif ^down_a_hole then
            nlpr([ ^(^get_real_name) ' cannot climb a tree, it is down a hole.']);
        elseif ^up_a_tree then
            nlpr([ ^(^get_real_name) ' is already up a tree.']);
        elseif distance_away( ^position, (the_tree <- position)) > 0 then
            nlpr([ ^(^get_real_name) ' is not by the tree.' ]);
        else
            true -> up_a_tree;
        endif;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod hide_in_hole(the_hole);
    /*----------------------------------------------------------------------*/
    /* go into a hole */
    lvars the_hole;
        if not(able_to_climb) then
            nlpr(['Sorry, but ' ^(^get_name) 's cannot climb down.']);
        elseif ^up_a_tree then
            nlpr([ ^(^get_real_name) ' cannot go down a hole, it is up a tree.']);
        elseif ^down_a_hole then
            nlpr([ ^(^get_real_name) ' is already down a hole.']);
        elseif distance_away( ^position, (the_hole <- position)) > 0 then
            nlpr([ ^(^get_real_name) ' is not by the hole.' ]);
        else
            true -> down_a_hole;
        endif;

    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod ground_level;
    /*----------------------------------------------------------------------*/
    /* Go back to the ground level.Either from up a tree of from down a hole*/
         unless ^up_a_tree or ^down_a_hole then
             nlpr(['You are already at ground level.']);
         else
             false -> ^up_a_tree;
             false -> ^down_a_hole;
         endunless;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod look -> things_seen; lvars things_seen;
    /*----------------------------------------------------------------------*/
    /* Look to see what objects are within the range specified */
    /*  by the variable 'seeing_distance'.                     */
    /*---------------------------------------------------------*/
    lvars item;

        /* If in range, add item to visible list */
        [% for item in world_* do
               if item <- alive
               and distance_away( ^position, (item <- position) )
                                                  <= ^seeing_distance
               and not(item <- up_a_tree)
               and not(item <- down_a_hole) then
                  item;
               endif;
           endfor;        %] -> things_seen;
        delete( self, things_seen ) -> things_seen;

    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod move( newposition ) -> successful_move;
    /*----------------------------------------------------------------------*/
    /* Move to a new location - return if successful or not. */
    lvars newposition, successful_move = false, distance, spaces_left;

       /* Make sure only first two entries are considered. */
       [^(newposition(1)) ^(newposition(2))] -> newposition;

       /* only move if not up a tree or down a hole */
       if not(^up_a_tree) and not(^down_a_hole) then

           /* Check to see if the entered values are within the world */
           if ( (newposition(1) <= boardsize) and (newposition(1) > 0)) and
              ( (newposition(2) <= boardsize) and (newposition(2) > 0)) then

               /* Check that the move is valid - less than moves left. */
               distance_away( ^position, newposition ) -> distance;
               (^speed - ^spaces_moved) -> spaces_left;
               if distance <= spaces_left then
                  newposition -> ^position;
                  ^spaces_moved + distance -> ^spaces_moved;
                  true -> successful_move;
               else
                  nlpr(['You can only move ' ^spaces_left ' spaces, STUPID!']);
               endif;

           else
               nlpr(['The world only ranges from 1 to ' ^boardsize]);
           endif;

       else
           /* Cannot move when up a tree or in a hole */
           if ^up_a_tree then
              false -> alive;
              nlpr(['You moved, fell out of the tree, and broke your neck']);
           else
              /* you are down a hole */
              false -> alive;
              nlpr(['You moved, the walls of the hole cave in, you suffocate.']);
           endif;

       endif;
   enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod eat_food (thing_to_eat);
    /*----------------------------------------------------------------------*/
    /* Obtain the 'food value' from thing_to_eat. */
    /*--------------------------------------------*/
    lvars thing_to_eat, food_value = 0;

        if member( (thing_to_eat <- get_name), ^potential_food) then
            if distance_away(^position, (thing_to_eat <- position)) = 0 then
                if thing_to_eat <- alive then
                    thing_to_eat <- be_eaten(self) -> food_value;
                    food_value + ^nourishment -> ^nourishment;
                else
                    nlpr(['Sorry, but that ' ^(thing_to_eat<-get_name)
                            ' is not edible' ]);
                endif;
            else
                pr( 'Sorry, but ' );
                ^printself;
                pr( ' and ' );
                thing_to_eat<-printself;
                nls(1);
            endif;
        else
            nlpr(['Sorry, but ' ^(^get_name) 's do not eat '
                    ^(thing_to_eat<-get_name) 's.' ]);
        endif;

    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod be_eaten( eater ) -> food_value; lvars eater;
    /*----------------------------------------------------------------------*/
    /* When a creature is eaten, it gives nourishment AND makes a noise.    */
    lvars food_value, eater;

       false -> ^alive;
       ^nourishment -> food_value;

       nlpr( ['As ' ^(^get_real_name) ' is eaten by '
                ^(eater <- get_real_name) ', it cries ' ] );
       death_message();
       nls(1);
    enddefmethod; /* be_eaten. */

    /*----------------------------------------------------------------------*/
    defmethod dec_nourishment;
    /*----------------------------------------------------------------------*/
    /* If creature does not get enough food then it will die */

    ^nourishment - 1 -> ^nourishment;
    if ^nourishment = 0 then
       false -> ^alive;
    endif;

    enddefmethod; /* dec_nourishment */


endflavour; /* creature */



/*==========================================================================*/

flavour hole isa object_in_world;

/*==========================================================================*/
/* boring boring boring. */
endflavour; /* hole */


/*==========================================================================*/

flavour tree isa object_in_world;

/*==========================================================================*/
/* boring boring boring. */
endflavour; /* tree */



/*==========================================================================*/

flavour grobbit isa creature;

/*==========================================================================*/
ivars speed=5, seeing_distance=15, nourishment = 20,
      able_to_climb=true, potential_food = [wiffle_flower];

    /*----------------------------------------------------------------------*/
    defmethod after dec_nourishment();
    /*----------------------------------------------------------------------*/
    /* Grobbits die noisily. Even of starvation. */
    if ^nourishment = 5 then
       nlpr([ ^(^get_real_name) ' is getting very hungry']);
       pr(newline);
    elseif ^nourishment = 2 then
       nlpr([ ^(^get_real_name) ' is starting to hallucinate...']);
       pr(newline);
    elseif ^nourishment = 1 then
       nlpr([ ^(^get_real_name) ' is about to die...']);
       pr(newline);
    elseif ^nourishment = 0 then
       nlpr(['Tough luck. '  ^(^get_real_name) ' has died of starvation.']);
       nlpr(['The wiffle flowers feed on its dead body.']);
       pr(newline);
    endif;
    enddefmethod; /* after dec_nourishment */


endflavour; /* grobbit */


/*==========================================================================*/

flavour aardvark isa creature;

/*==========================================================================*/
ivars speed=6, seeing_distance=6, nourishment = 40,
      potential_food = [dirndl grobbit wiffle_flower];

    /*----------------------------------------------------------------------*/
    defmethod next_turn;
    /*----------------------------------------------------------------------*/
    lvars what_i_see, xmove, ymove, newposition;
        /* Look round and sort out what I can eat.*/
        ^look -> what_i_see;
        sort_edibles( ^potential_food, what_i_see ) -> what_i_see;
        if what_i_see = [] then /* Move somewhere else rapidly */
            random(^speed) -> xmove; /* Calc x offset. */
            ^speed - xmove -> ymove; /* Calc y offset. */
            ((^xpos + xmove - 1) mod boardsize) + 1 -> xmove; /* x abs pos.*/
            ((^ypos + ymove - 1) mod boardsize) + 1 -> ymove; /* y abs pos.*/
            ^move( [ ^xmove ^ymove ] );
        else /* Eat the first thing on the list.         */
             /* Most likely to be a dirndl if any about. */
            ^move(what_i_see(1) <- position);
            ^eat_food(what_i_see(1));
        endif;
    enddefmethod;

endflavour; /* aardvark */


/*==========================================================================*/

flavour bonecrusher isa creature;

/*==========================================================================*/
ivars speed=15, seeing_distance=25, nourishment = 60,
      potential_food = [dirndl grobbit];

    /*----------------------------------------------------------------------*/
    defmethod thing_in_range( my_food ) -> result;
    /*----------------------------------------------------------------------*/
    /* Bonecrushers move in straight lines, so food is only within range if */
    /* it can get there this turn and it is in a horizontal or vertical line.*/
    lvars my_food, result=false, item;
        for item in my_food do
            if distance_away( ^position, (item <- position) ) <= speed
            and ( (^xpos = (item <- xpos))
               or (^ypos = (item <- ypos))) then
                 item -> result;
                 return; /* Aargh! A jump-out-of-proc instruction.*/
            endif;
        endfor;
    enddefmethod; /* thing_in_range */

    /*----------------------------------------------------------------------*/
    defmethod calculate_nearest( object_list ) -> nearest;
    /*----------------------------------------------------------------------*/
    /* Returns object to which bonecrusher is nearest.     */
    lvars object_list, nearest, item, least_distance = 99, xoff, yoff, offset;
        for item in object_list do
           distance_away( ^position, (item <- position) ) -> offset;
           if offset < least_distance then
               offset -> least_distance;
               item -> nearest;
           endif;
        endfor;
        calc_offset(^xpos, (nearest<-xpos)) -> xoff;
        calc_offset(^ypos, (nearest<-ypos)) -> yoff;
        if xoff < yoff then
            [% (nearest<-xpos); ^ypos %]
        else
            [% ^xpos; (nearest<-ypos) %]
        endif -> nearest;

    enddefmethod; /* calculate_nearest */

    /*----------------------------------------------------------------------*/
    defmethod next_turn;
    /*----------------------------------------------------------------------*/
    lvars what_i_see, jump, xmove=0, ymove=0, choice, newposition, dinner;
        /* Look round and sort out what I can eat.*/
        ^look -> what_i_see;
        sort_edibles( ^potential_food, what_i_see ) -> what_i_see;
        if not(what_i_see = []) then
            ^thing_in_range(what_i_see) -> dinner;
            if dinner then
                /* Found someone I can eat now - do it! */
                ^move(dinner <- position);
                ^eat_food(dinner);
            else /* Can see food but not reach it now. Move nearer. */
                ^calculate_nearest( what_i_see ) -> newposition;
                ^move(newposition);
            endif;
        else /* Move somewhere else slowly or fast (random decision) */
            if random(2) = 1 then 1 else ^speed endif -> jump;
            if random(2) = 1 then /* Up or across (random decision) */
                jump -> xmove;
            else
                jump -> ymove;
            endif;
            ((^xpos + xmove - 1) mod boardsize) + 1 -> xmove; /* x abs pos.*/
            ((^ypos + ymove - 1) mod boardsize) + 1 -> ymove; /* y abs pos.*/
            ^move( [ ^xmove ^ymove ] );
        endif;
    enddefmethod;

endflavour; /* bonecrusher */


/*==========================================================================*/

flavour ceepee isa creature;

/*==========================================================================*/
ivars speed=7, seeing_distance=boardsize, nourishment = 40,
      potential_food = [];

    /*----------------------------------------------------------------------*/
    defmethod sort_out_a_prey( grobbits ) -> dinner;
    /*----------------------------------------------------------------------*/
    lvars grobbits, dinner=[], index;
        if (^potential_food = []) then
            /* No grobbit in mind. Any take my random fancy? */
            random(3*length(grobbits)) -> index;
            if index <= length(grobbits) then
                [% grobbits(index) %] -> ^potential_food;
            endif;
        else /* I am chasing a grobbit - is he visible. */
            unless member( hd(^potential_food), grobbits ) then
                [] -> ^potential_food;
            endunless
        endif;
        ^potential_food -> dinner;
    enddefmethod; /* sort_out_a_prey */

    /*----------------------------------------------------------------------*/
    defmethod calc_new( num1, num2, move ) -> result;
    /*----------------------------------------------------------------------*/
    lvars num1, num2, move, result, posmove, negmove;
    /* Complex calculation to decide whether best to move neg or pos. */
        ((num1 + move - 1) mod boardsize) + 1 -> posmove;
        ((num1 - move + boardsize - 1) mod boardsize) + 1 -> negmove;
        if calc_offset(num2, posmove) < calc_offset(num2,negmove) then
            posmove
        else
            negmove
        endif -> result;
    enddefmethod; /* calc_new */
    /*----------------------------------------------------------------------*/


    /*----------------------------------------------------------------------*/
    defmethod nearest_place( food ) -> place;
    /*----------------------------------------------------------------------*/
    lvars food, place, xdist, ydist, xoff, yoff;
        calc_offset(^xpos, (food<-xpos)) -> xoff;
        if xoff > ^speed then
            ^speed -> xdist;
            0 -> ydist;
        else
            xoff -> xdist;
            ^speed - xoff -> ydist;
        endif;
        /* Need to decide to move pos or neg in each case. */
        [% ^calc_new(^xpos,(food<-xpos),xdist);
           ^calc_new(^ypos,(food<-ypos),ydist); %] -> place;

    enddefmethod; /* nearest_place */
    /*----------------------------------------------------------------------*/


    /*----------------------------------------------------------------------*/
    defmethod next_turn;
    /*----------------------------------------------------------------------*/
    lvars what_i_see, my_dinner=[];
        /* This guy is weird. Instead of potential food being a class, */
        /* he selects a particular grobbit at random and chases it.    */
        /* Only way to lose it is to hide for a turn.                  */
        ^look -> what_i_see;
        sort_edibles( [grobbit], what_i_see ) -> what_i_see;
        unless what_i_see = [] then
            ^sort_out_a_prey( what_i_see ) -> my_dinner;
        endunless;
        unless my_dinner = [] then
            hd(my_dinner) -> my_dinner;
            if distance_away(^position, (my_dinner<-position)) <= speed then
                /* I don't believe it - the grobbit is dead meat! */
                ^move(my_dinner <- position);
                [grobbit] -> ^potential_food;
                ^eat_food(my_dinner);
                [] -> ^potential_food;
            else /* Move as close as possible */
                ^move( ^nearest_place( my_dinner ) ) ;
            endif;
        endunless;
    enddefmethod;

endflavour; /* ceepee */


/*==========================================================================*/

flavour dirndl isa creature;

/*==========================================================================*/
ivars speed=4, seeing_distance=4, nourishment = 100,
      potential_food = [grobbit];

    /*----------------------------------------------------------------------*/
    defmethod next_turn;
    /*----------------------------------------------------------------------*/
    lvars what_i_see, item, xmove, ymove, newposition;
        /* Look round and sort out what I can eat.*/
        ^look -> what_i_see;
        sort_edibles( ^potential_food, what_i_see ) -> what_i_see;
        if what_i_see = [] then /* Move somewhere else rapidly */
            random(^speed) -> xmove; /* Calc x offset. */
            ^speed - xmove -> ymove; /* Calc y offset. */
            (((^position)(1) + xmove - 1) mod boardsize) + 1 -> xmove; /* x abs pos.*/
            (((^position)(2) + ymove - 1) mod boardsize) + 1 -> ymove; /* y abs pos.*/
            ^move( [ ^xmove ^ymove ] );
        else /* Eat the first thing on the list. */
            ^move(what_i_see(1) <- position);
            ^eat_food(what_i_see(1));
        endif;
    enddefmethod;

endflavour; /* dirndl */


/*==========================================================================*/

flavour wiffle_flower isa object_in_world;

/*==========================================================================*/
ivars nourishment = 10;

    /*----------------------------------------------------------------------*/
    defmethod dec_nourishment;
    /*----------------------------------------------------------------------*/
    /* Slowly kill off wiffle flower... */

        ^nourishment - 1 -> ^nourishment;
        if ^nourishment = 0 then
           false -> ^alive;
        endif;
    enddefmethod;

    /*----------------------------------------------------------------------*/
    defmethod be_eaten( eater ) -> food_value;
    /*----------------------------------------------------------------------*/
    /* When a wiffleflower is eaten, it gives nourishment depending on age. */
    lvars food_value;
       false -> ^alive;
       ^nourishment -> food_value;
       /* Following code is BAD oops practice. I plead special case. */
       if (eater <- get_name) = "grobbit" then
           if food_value > 7 then
              nlpr([^(eater<-get_real_name)
                        ' says "WOW - that was tasty!"']);
           elseif food_value < 3 then
               nlpr([^(eater<-get_real_name)
                        ' says "YUCK - that was horrible!"']);
           else
               nlpr([^(eater<-get_real_name)
                    ' says "Well, that tasted a bit bland."']);
           endif;
       endif;
    enddefmethod; /* be_eaten. */

endflavour; /* wiffle_flower */


/*==========================================================================*/
/*==========================================================================*/
/* ********** WORLD SHATTERING STUFF - LEAVE WELL ALONE!!!!!!!!! ********** */
/*==========================================================================*/
/*==========================================================================*/

define make_an_object_at_random ( the_class ) -> the_object;

/*==========================================================================*/
lvars pos1, pos2, the_class, the_object;

    /*------------------------------*/
    /* Define two random positions. */
    /*------------------------------*/
    random(boardsize) -> pos1;
    random(boardsize) -> pos2;

    make_instance( [^the_class position [^pos1 ^pos2]
                    realname ^(gensym(the_class)) ] ) -> the_object;

enddefine;

/*==========================================================================*/

define set_up( setupfile );

/*==========================================================================*/

/*-------------------------------------------------------------*/
/* Set up the particular instances of the objects in the world */
/*-------------------------------------------------------------*/
lvars setupfile, setuplist, item, i;

    /* Turn the file into an internal list */
    datafile( setupfile or default_setupfile ) -> setuplist;
    [% for item in setuplist do
           for i to item(2) do
               make_an_object_at_random ( item(1) );
           endfor;
       endfor;                      %] -> world_*;


enddefine; /* set_up */


/*==========================================================================*/

define exists( thing_to_find ) -> result;

/*==========================================================================*/
lvars thing_to_find, item, result = false;

    for item in world_* do
        if item <- get_name = thing_to_find then
            true -> result;
        endif;
    endfor;
enddefine;


/*==========================================================================*/

define run( players );

/*==========================================================================*/
lvars players, moves = 0, item;

    /* Load world details from file players. */
    set_up( players );  /* Initialise the board. */

    /* Welcome message */
    nls(3);
    pr('WELCOME TO THE LAND OF TINYGLOBE.');
    nls(2);
    nlpr(['The object of the game is to keep your Grobbit safe and ']);
    nlpr(['well fed in the fairly hostile world of Tinyglobe.']);
    nls(2);

    /*-------------------------------------------------*/
    /* Only play until the grobbit dies - no fun then. */
    /*-------------------------------------------------*/
    while exists("grobbit") and moves < 100 do

        /* Give everyone a turn */
        for item in world_* do
           item <- make_move;
        endfor;

        /* Delete anybody who is dead now. */
        [% for item in world_* do
              if item <- alive  then
                item;
              endif;
           endfor;  %] -> world_*;

        moves + 1 -> moves;

        /* Grow new flowers - they keep getting eaten. */
        make_an_object_at_random("wiffle_flower") :: world_* -> world_*;

        /* Occasionally replenish the dirndls. */
        if (moves mod 4) = (random(6) - 1) then
            make_an_object_at_random("dirndl") :: world_* -> world_*;
        endif;

    endwhile;

    if moves = 100 then
        nlpr(['Simulation finished after a hundred moves.\n'
               'State of world was:\n\n' ^(world_*) ]);
    else
        nlpr(['Simulation terminated after ' ^moves ' turns as no grobbits left.']);
    endif;

enddefine; /* run */
