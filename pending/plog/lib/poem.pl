/* poem.pl								*/

/************************************************************************/
/*									*/
/* Prolog Object-oriented Embedded Manager				*/
/*									*/
/* Externally callable predicates:				 	*/
/*									*/
/*   - poem/0 translates the 'class' structures into Prolog clauses	*/
/*									*/
/*   - new/2 establishes a validated instance of a class		*/
/*									*/
/*   - instance/1 succeeds if its argument is a valid class instance	*/
/*									*/
/*   - ':'/2 (infix operator) handles class predicate accessing		*/
/*									*/
/************************************************************************/


?- op( 255, yfx, body ).
?- op( 255, xfx, checks ).
?- op( 200, xfx, class ).
?- op( 200, fx, class ).
?- op( 150, yfx, -&- ).
?- op( 100, xfx, => ).
?- op( 60, fx, not ).
?- op( 5, xfx, : ).


/* poem/0 is the top-level callable predicate to translate the class	*/
/* patterns into Prolog predicates.					*/

poem :-
	subclass_translations,
	class_translations.
	/* The class patterns (functor 'body') could be retracted now	*/


/* Subclass_translations/0 preprocesses subclass definitions for later	*/
/* processing by class_translations.					*/

/* Subclasses access their superclass predicates by:			*/
/*	subclassname(X) :- superclassname(X).				*/
/* The new subclass predicates are bound into a new class definition	*/
/* along with a check that the subclass object is a valid instance of	*/
/* the superclass, by calling instance(superclassname(arguments)).	*/

subclass_translations :-
	( SubCDesc class SuperCName checks Conds body Body ),
	SubCDesc =.. [ SubCName|Args ],
	SuperCDesc =.. [ SuperCName|Args ],
	SubCCall =.. [ SubCName,X ],
	SuperCCall =.. [ SuperCName,X ],
	assertz( (SubCCall :- SuperCCall) ),
	assertz( (class SubCDesc
		      checks
			  (instance(SuperCDesc), Conds)
		      body Body) ),
	fail.

subclass_translations.


/* class_translations/0 splits the class patterns into Prolog		*/
/* predicates for the defined class operations.				*/

class_translations :- 
	( class Name checks Conds body Preds ),
	assert_checks( Name, Conds ),
	Name =.. [ CName|CArgs ],
	assert_predicates( CName, Preds, [CArgs] ),
	fail.

class_translations.


/* assert_checks/2 translates the initialisation list of a class into	*/
/* a Prolog clause instance/1, which checks that its argument is a 	*/
/* valid instance of its class.						*/

assert_checks( ClassName, Checks ) :-
	assertz( instance(ClassName) :- Checks ).

none.	/* so that classes defined with "checks none" work properly.	*/


/* assert_predicates/3 translates the predicate list of a class into	*/
/* correct Prolog clauses, bound with the class name for uniqueness.	*/
/* To access the owner object variables, they are bound in as a final	*/
/* argument to each predicate.						*/

assert_predicates( _, none, _ ) :-
	!.
  
assert_predicates( CName, P1 -&- P2, Args ) :-
	assert_predicates( CName, P1, Args ),
	assert_predicates( CName, P2, Args ).

assert_predicates( CName, Head => Tail, Args ) :-
	Head =.. [ HFunc|HArgs ],
	append( HArgs, Args, NewArgs ),		/* add object descrn.	*/
	NewHead =.. [ HFunc|NewArgs ],
	UniqueHead =.. [ CName,NewHead ],	/* tag with class name	*/
	assertz( (UniqueHead :- Tail) ).


/* new/2 instantiates a new object and performs any constraint checks	*/
/*   eg new( point(3,4), Point34 ).					*/

new( Classinstance, Classinstance ) :-
	instance( Classinstance ).


/* ':' is an operator to select predicate application according to	*/
/* object class.  For example,						*/
/*   if			PointA = point(1, 2),				*/
/*   then		PointA:distance(PointB, D)			*/
/*   translates to	point( distance(PointB, D, 1, 2) )		*/

ClassInst : Function :-
	ClassInst =.. [ CFunc|CArgs ],
	Function =.. [ FFunc|FArgs ],
	append( FArgs, [CArgs], NewArgs ),
	NewHead =.. [ FFunc|NewArgs ],
	UniqueHead =.. [ CFunc,NewHead ],
	!,		/* no point resatisfying the translation	*/
	call( UniqueHead ).


/* Finally, standard append/3 definition .				*/

append([], X, X).

append([X|L1], L2, [X|L3]) :-
	append(L1, L2, L3).
