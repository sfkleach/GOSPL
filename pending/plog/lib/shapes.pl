/* shapes.pl				                                */

/************************************************************************/
/*                                  					*/
/* This file contains a sample set of class definitions which set up    */
/* and manipulate shapes on a 2-dimensional Cartesian grid.  There is   */
/* no actual drawing done, so you'll just have to imagine that bit.	*/
/*                                 					*/
/************************************************************************/


?- [-'poem.pl'].      /* Establish the operators          		*/


/* Points are going to be the fundamental quantity.         		*/
/* These will be defined in Cartesian co-ordinates.             	*/

class point(X, Y)
    checks
        /* test that the co-ordinates are numeric.          		*/
        ( numeric(X),
          numeric(Y) ) 
    body
        identical(point(X1, Y1)) =>
            /* succeeds if the argument and owner points are the same.  */
            ( X1 = X, Y1 = Y )
     -&-
        distance(point(X1, Y1), Dist) =>
            /* finds the distance between argument and owner points.    */
            Dist is sqrt( (X1-X)*(X1-X)+(Y1-Y)*(Y1-Y) ).


/* Ellipses are defined by centre and semi-axes             		*/

class ellipse(Centre, A, B)
    checks
        /* typecheck the descriptor arguments               		*/
        ( functor(Centre, point, 2),
          instance(Centre),
          numeric(A), A>0,
          numeric(B), B>0 )
    body
        area(Area) =>
            ( pi(Pi),
              Area is Pi*A*B ).


/* A line is defined by its end points.                 		*/
/* This class shows examples of calling its own and other class     	*/
/* predicates.                              				*/

class line(P1, P2)
    checks
        /* check the line is of non-zero length.            		*/
        not P1:identical(P2)
    body
        length(Len) =>
            /* sets Len to the length of the owner line         	*/
            P1:distance(P2, Len)
     -&-
    intersects(Line2) =>  
            /* succeeds if Line2 intersects the owner line.     	*/
            /* this isn't necessarily a good method, but shows how to   */
            /* call class procedures from within the class definition.  */
            ( Line1 = line(P1, P2),
              Line2 = line(P3, P4),
              Line2:signed_distance(P1, D1),
              Line2:signed_distance(P2, D2),
              opposite_signs(D1, D2),
              Line1:signed_distance(P3, D3),
              Line1:signed_distance(P4, D4),
              opposite_signs(D3, D4) )
     -&-
        signed_distance(Point, Dist) =>
            /* finds the perpendicular distance from point to line. 	*/
            /* the sign of the answer depends on which side of the  	*/
            /* line the point is on.                    		*/
            ( P1 = point(X1, Y1),
              P2 = point(X2, Y2),
              Point = point(X3, Y3),
              A is X2-X1,
              B is Y1-Y2,
              C is X1*Y2-X2*Y1,
              Dist is (A*Y3+B*X3+C)/sqrt(A*A+B*B) )
     -&-
        distance(Point, Dist) =>
            /* as 'signed_distance', but Dist always >= 0       	*/
            ( line(P1, P2):signed_distance(Point, Temp),
              Dist is abs(Temp) ).


/* Circle is a special form of ellipse                  		*/
/* Subclasses ('circle' here) must have the same number of arguments    */
/* as their superclass ('ellipse') for the superclass predicates to 	*/
/* be applicable.  The arguments may be renamed for clarity.        	*/

circle( C, R, R ) class ellipse
    checks
        /* All checks defined on 'ellipse' class automatically apply    */
        none
    body
        /* All predicates defined for 'ellipse' are also available  	*/
        circumference(Circ) =>
            ( pi(Pi),
              Circ is 2*Pi*R ).



/************************************************************************/
/*                                  					*/
/* These auxiliary routines effect some mathematics ...         	*/
/*                                  					*/
/************************************************************************/

/* pi/1 stores the value of pi                      			*/

?- prolog_eval(valof(pi), Pi),
   assertz( pi(Pi) ).


/* 'opposite_signs' succeeds if its arguments are of opposite signs.    */
/* It has a feature in that 'opposite_signs(0,0)' succeeds: this is 	*/
/* because 0 is treated as having optional sign.            		*/

opposite_signs(A, B) :-
    o_s_aux(A, B).

opposite_signs(A, B) :-
    o_s_aux(B, A).

o_s_aux(A, B) :-
    A >= 0,
    B =< 0.


/* numeric/1 succeeds if its argument is a valid number			*/

numeric(X) :-
    integer(X).

numeric(_).		/* test for real numbers ?			*/



/************************************************************************/
/*                                                                      */
/* Now some examples of using the above definitions ...                 */
/*                                                                      */
/************************************************************************/


setup_points( P45, P66, AnotherP45, Pm4m3, P00 ) :-
    new(point(4,5), P45),
    new(point(6,6), P66),
    AnotherP45 = P45,
    new(point(-4, -3), Pm4m3),
    new(point(0,0), P00).

setup_lines( L1, L2, L3, L4 ) :-
    setup_points( P45, P66, _, Pm4m3, P00 ),
    new(line(P00, P45), L1),
    new(line(Pm4m3, P66), L2),
    new(line(Pm4m3, P45), L3),
    new(line(P00, P66), L4).

banner :-
    nl,
    write('POEM demonstration file.'), nl, nl,
    write('The example output that follows is produced by Prolog code'), nl,
    write('using the object language enhancement POEM.  Please look'), nl,
    write('through the code file "shapes.pl" provided to understand how'), nl,
    write('the class facilities are being used.'), nl.

points :-
    nl,
    write('(1) point manipulation:'), nl, 
    setup_points( P45, P66, AnotherP45, Pm4m3, P00 ),
    write('distance from (4,5) to (6,6) is '),
    P45:distance(P66, D),
    write(D), nl,
    P45:identical(AnotherP45),
    write('P45 and AnotherP45 are identical points'), nl,
    not P00:identical(P66),
    write('P00 and P66 are different points'), nl.


ellipse :-
    nl,
    write('(2) ellipse manipulation:'), nl,
    new(point(5,6), P56),
    new(ellipse(P56,3,5), E),
    write('Area of ellipse of semi-axes 3 and 5 is '),
    E:area(A),
    write(A), nl.


lines :-
    nl,
    write('(3) line manipulation:'), nl,
    setup_lines( L1, L2, L3, L4 ),
    new(point(3,3), P33),
    write('distance from '),write(L2),write(' to '),write(P33),write(' is '),
    L2:distance(P33, D),
    write(D), nl,
    L1:intersects(L2),
    write(L1), write(' intesects '), write(L2), nl,
    not L3:intersects(L4),
    write(L3), write(' does not intersect '), write(L4), nl.


circle :-
    nl,
    write('(4) circle manipulation:'), nl,
    write('  Circles are subsets of ellipses, so the "area" function'), nl,
    write('  is available, and a new "circumference" function.'), nl,
    new(point(2,2), P22),
    new(circle(P22, 3, 3), C),
    write('Area of circle radius 3 is '), 
    C:area(A),
    write(A), nl,
    write('Circumference of circle radius 3 is '),
    C:circumference(Circ),
    write(Circ), nl, nl.


?- poem.        /* do the class transformations         		*/

?- banner,
   points,
   ellipse,
   lines,
   circle.
