;;; Summary: a simple object-oriented programming library


/* A PACKAGE FOR OBJECT ORIENTED PROGRAMMING	-         A.Sloman May 1983
                                                          Modified March 1985

An 'object oriented' system provides a means of defining classes of objects,
and then using these to define new classes, called their sub-classes,
which 'inherit' information from their super-classes. A class can also
be used to create 'instances' sometimes called 'objects', where the
features of the object are determined by the class (and therefore by all
its superclasses).

Such a system may provide, associated with each class, data features and
procedural features, as follows.

Data Features associated with a class:
D1. A set of 'slots' or 'fields' with particular names, to be found in
    each instance of the class.
D2. Default values or 'fillers' for these slots.
D3. A set of data associated globally with the class.

Procedural Features associated with a class:
P1. Actions to be performed when a new subclass is created.
P2. Actions to be performed when a new instance of the class is created.
P3. Actions to be performed when an instance (object) is sent a message.
P4. Actions to be performed when a slot or field in an instance is accessed
    or updated.
P5. Actions to be performed when information associated globally with the
    class is accessed or updated.

All of these features, except perhaps D3 and P5 should be inherited from
superclasses by their sub-classes.

THIS PACKAGE
This package provides a subset of these features.
Special syntax is provided in the form of a CLASS definition, and procedures
are provided for creating instances, sending them messages, etc. The
instances have features determined by the class definitions.

Classes are represented by POP-11 records of type "classtype" each of
which stores information about the relevant class, including pointers
to its superclasses and subclasses, and an updatable class property.

Instances are represented by POP-11 processes, with slots and their fillers
represented by local variables and their values. So feature D1 is provided,
including multiple inheritance.

Each instance has a local variable corresponding to each field name
of its class, and each field name of the immediate superclasses of that
class, and their superclasses, etc. However, if the same name is used in
several superclasses it will just produce ONE field name in the instance.
(Some systems allow the different fields to be kept distinct forming
different 'perspectives' of the same object. This allows greater modularity,
but complicates the implementation. So for now we require different field
names to be used where fields are to be kept distinct.)

Whenever an instance is activated there will be two variables provided,
which can only be done by sending a message, 'self' which will point to
the current instance, and 'message' which will point to the message sent.
For that reason these variables should not be used in user programs or
class definitins.

Feature D2, default slot values, is not (at present) directly provided,
though general mechanisms provided make it very easy to implement.

Feature D3, data associated globally with each class, is provided by the
POP-11 record associated with each class. The fields of these records are used
by the system, except for the 'class_props' field which contains a POP-11
property which may be updated by user programs.

Most of the procedural features mentioned above are implemented.
P1, action to be performed when a subclass is created, is implemented for
the system. When the new subclass has been created the user-definable
procedure called 'user_class_initial' is run with the class record as
argument. It defaults to do nothing.

P2. Actions to be performed when a new instance of the class is created
are specified by the 'START_ACTIONS' field of a class definition. Actions
specified for all superclasses are also run when an instance is created.

P3. Actions to be performed when an instance (object) is sent a message,
are specified by the 'MESSAGE_ACTIONS' field of a class definition,
and also the corresponding fields of all super-classes of the class.
When an object is sent a message, all the relevant message actions are
run, with the message assumed to be held in the variable 'message'. Then
a common default message handler is run, as follows. The message may be a word,
a procedure, or a list. If it is a word its value is returned; if a procedure,
then the procedure is executed, and if it is a list it is assumed that
class message handlers will have processed it. Anything else will cause
an error message.

Class message actions may trap messages and prevent further action by
transferring control immediately to some other object, using the message
operator '|-->' defined below.

Features P4 and P5 are not implemented at present. P4 can be implemented by
means of message handlers which may deal with messages of the form:
	[set_value ^variable ^value]
or
	[get_value ^variable]
by invoking suitable 'demons'.

P5 can be implemented by defining a procedure to update the class_props
of a class, which checks whether there are demons associated with the
class, instead of updating the class_props directly.

MULTIPLE INHERITANCE
If a class definition for class C1 names several superclasses S1 ...  Sn, in
that order, then when an instance of C1 is created, or sent a message, the
start actions and message actions of S1 to Sn are performed in the same order,
before the start action or message action of C1.

[BUG - there will be some duplication if the same superclass is accessed
via different routes. E.g. if S1 and S2 share a superclass.
This will be fixed. ]

DISCLAIMER
This is highly provisional - subject to revision.
In particular, it is not clear whether all the inheritance defaults are
right, nor whether the default message receiving procedures are right.

At present, the package needs an improvement to process mechanism: at present
objects die if you exit from them abnormally - e.g. with setpop. So after an
error an object may fail to run. I have put in bodge to solve this
temporarily, by redefining interrupt in procedure >-->.

*/

/*
To make this package available do LIB NEWOBJ;
To test it use marked range and CTRL-D on the examples in this comment.

Classes can be defined using
	CLASS .... ENDCLASS.

Instances are created using
	new([<classname> <initial value specs>])

(or more generally with the procedure new_instance).

A message is sent to an instance using '>-->' (or '<--<' or 'with').

If control is to be transferred permanently to another instance use
	'|-->' or '<--|'

EXAMPLES
--------
The following top level class definition is provided by LIB OBJ
	CLASS thing
	SUBCLASS_OF undef
	CLASS_FIELDS
		name
		class_printer
	START_ACTIONS
		default_printer -> class_printer;
	MESSAGE_ACTIONS
	ENDCLASS;

Now we can define a class called "person", a subclass of "thing", thus:

	CLASS person
	SUBCLASS_OF thing
	CLASS_FIELDS
		age sex spouse children
		;;; inherits fields "name" and "class_printer" from class thing
	START_ACTIONS
		;;; these are run when a new instance is created
		[new person born - name ^name] =>
		false -> spouse; [] -> children;
	MESSAGE_ACTIONS
		;;; An instance is run by sending it a message with >--> or |-->
		vars temp ;
		if message matches [birthday] then
			age + 1 -> age;
			[happy birthday! ^name is now ^age years old] =>
		elseif message matches [marry ?temp] then
			if temp = spouse then
				;;; already married to this one - do nothing
			elseif isword(spouse) and spouse /= temp then
				mishap('BIGAMY', [^name ^temp ^spouse])
			else
				temp -> spouse;		;;; will be remembered as new slot filler
				[^name marrying ^spouse] =>
					[marry ^name] |--> spouse;
			endif
		elseif message matches [divorce ?temp] then
				if spouse = temp then
					[^name divorcing ^spouse] =>
					with valof(spouse) do false -> spouse endwith;
					false -> spouse;
				else
					mishap('Cannot divorce, not married to ' >< temp,
								[spouse ^spouse])
				endif
		endif
	ENDCLASS;

A class defines a type of object which has a set of classfields,
	a set of actions to be run when an instance is created
	a mechanism for responding to messages.

If there is nothing after MESSAGE_ACTIONS then only the procedure
default_response (defined below) will be called. If there is a message
action, then the procedure is called anyway. It will do nothing if
message is FALSE, or if it is a list. Otherwise if the message is a word
it is assumed to be a field name, and the value is left on the stack.
If the message is a procedure it is run. If its a list, then the
relevant message_actions should interpret the list.

NB: If local variables are defined in the MESSAGE_ACTION, using
VARS, as 'temp' is in CLASS PERSON above, then this will be local to
each invocation of the instance. The value will not be remembered from
one invocation to another. If you want a value to be remembered then
it must be declared as a class field.

A class inherits classfields and other information from its super-class.

Instances may be defined using 'new_instance', defined below.
However, it is generally more convenient to use the procedure new,
e.g.


	vars mary john;
	new([person name mary age 34 sex female]) -> mary;
	** [new person born - name mary]
	new([person name john age 33 sex male]) -> john;
	** [new person born - name john]

The latter is roughly equivalent to
	new_instance("person",
					procedure;
						"john" -> name; 33 -> age; "male" -> sex
					endprocedure)
	-> john;

So new_instance is more general than 'new'.

NB as the above example shows, if you use 'new' to create an instance
and give its fields certain vaules, then the START_ACTIONS are run AFTER
the values have been assigned. Thus start actions cannot be used to
assign default values. A modified definition of 'new', using new_instance,
could overcome this by assigning the instance values after new_instance
has run, instead of doing it in the second argument of new_instance.

An instance is a process which can be sent messages using one of

	message >--> object;

	object  <--< message;

	with object do actions endwith;
		(which is equivalent to: procedure; actions endprocedure >--> object)

All of these are defined in terms of >--> which has 'message' and 'self'
as local variables whose values are available when the instance runs.

One instance can send a message to another without re-gaining control, i.e.
using RESUME, not RUNPROC, by means of the following:
	message 	  |--> other_object;

or, equivalently:

	other_object  <--| message;

A message is either a field name, in which case the value is returned e.g.
find john's age:

	"age" >--> john	 =>
	** 33


or a procedure to be executed e.g.
	procedure;
		"mary" -> spouse
	endprocedure
		>--> john;

  or
	with john do "mary" -> spouse endwith;

or a list, which will be interpreted by the message_action of the object, e.g.

	[ marry mary] >--> john;
	** [john marrying mary]
	** [mary marrying john]

	"spouse" >--> john =>
	** mary
	"spouse" >--> mary =>
	** john

	[birthday] >--> mary;
	** [happy birthday ! mary is now 35 years old]

There is a default printing procedure.

	with mary do class_printer () endwith;
	<person mary>

This can be changed:
	with mary do
		procedure; [person ^name age ^age spouse ^spouse] =>
		endprocedure -> class_printer;
	endwith;

Now the previous command will produce different print out:

	with mary do class_printer () endwith;
	** [person mary age 35 spouse john]

We can check that bigamy is not allowed:
	vars fred;
	new([person name fred age 43 sex male]) -> fred;
	** [new person born - name fred]

Try an illegal marriage.

	[marry fred ] >--> mary;

	;;; MISHAP - BIGAMY
	;;; INVOLVING:  mary fred john
	;;; DOING    :  messages_person person runproc >-->

	[divorce john] >--> mary;
	** [mary divorcing john]

Now the marriage is no longer illegal:

	[marry fred ] >--> mary;
	** [mary marrying fred]
	** [fred marrying mary]


The following illustrates the fact that messages run in different
environments, and that |--> prevents the return of control to the
sender:
	with fred do
		[in ^name] =>
		procedure;
			[now in ^name] =>
		endprocedure; |--> spouse;
		[in ^name] =>	;;; this shouldn't run because of |--> above
	endwith;
	** [in fred]
	** [now in mary]


If the message to be sent is a procedure P which takes N arguments, then use
the syntax

	a1, a2, a3,..aN, P, N >--> instance;

or
	P(%a1,a21,a3....aN%) >--> instance

Every instance of whatever type is given a default field called 'class_key'
which points to a record for the class type for the instance.
	"class_key" >--> mary =>
	** <classtype person, super thing, 0 subclasses>

The super_class of the class_key of mary is the "thing" class:
	superclasses("class_key" >--> mary) =>
	** <classtype thing, super <false>, 3 subclasses>


A type is a record of type 'classtype' with the following classfields
(subject to change):

		classname superclasses subclasses classfields startactions
		message_actions class_procedure clss_props;

A default top-level class called "thing" is provided, with a default
fields called 'name' and 'class_printer'. By making all classes descendants of
this class, they are guaranteed to have these classfields. But a class can have
false as its superclasses. This is achieved by using the name 'undef' in the
class declaration, as in the definition of CLASS thing, above.

-----------------------------------------------------------------------------
MULTIPLE SUPERCLASSES

We define class worker as a subclass of THING, then define teacher has having
WORKER and PERSON as SUPERCLASSES but with some extra fields.

	CLASS worker
	SUBCLASS_OF thing
	CLASS_FIELDS
		name employer salary jobtype
		;;; inherits fields "name" and "class_printer" from class thing
	START_ACTIONS
		;;; these are run when a new instance is created
		unless isinteger(salary) then 100 -> salary endunless;
		[new worker- ^name working for ^employer for ^salary] =>
		unless isinteger(salary) then 100 -> salary endunless;
	MESSAGE_ACTIONS
		;;; An instance is run by sending it a message with >--> or |-->
		if message matches [promotion] then
			salary + 10 -> salary;
			[Congratulations! ^name now earns ^salary] =>
		elseif message matches [sacked] then
			undef -> employer; 0 -> salary;
				;;; already married to this one - do nothing
		endif
	ENDCLASS;

;;; A class with TWO super-classes

	CLASS teacher
	SUBCLASS_OF person worker
	CLASS_FIELDS
		subject school
	START_ACTIONS
		;;; these are run when a new instance is created
		[^name starting to teach ^subject at ^school] =>
	MESSAGE_ACTIONS
		;;; An instance is run by sending it a message with >--> or |-->
		vars temp ;
		if message matches [teach] then
			[^subject is very very interesting] =>
		endif
	ENDCLASS;

vars harry;
new([teacher name harry employer lea salary 150 school eton subject maths])
	-> harry;
** [new person born - name harry]
** [new worker - harry working for lea for 150]
** [harry starting to teach maths at eton]

;;; send a message to harry as worker
[promotion] >--> harry;
** [Congratulations ! harry now earns 160]

;;; send a message to harry as teacher
[teach] >--> harry;
** [maths is very very interesting]

*/

;;; Perhaps not all of these should be exported.

section class =>
				with endwith >--> <--< |--> <--|
				CLASS ENDCLASS SUBCLASS_OF CLASS_FIELDS START_ACTIONS
				MESSAGE_ACTIONS
				message, self, class_key, classtype_pr,
				classname,superclasses,subclasses,classfields,startactions,
				message_actions, class_procedure,
				class_props, consclasstype, isclasstype
				class_of_name	;;; mapping from names to classes
				class_warning	;;; procedure run when a class is redefined
				user_class_initial	;;; run when a new class is created
				new_instance new
				default_response	;;; default response procedure
				Classkey_of_instance
				allfields listallfields
;

vars class_procedure;
global vars self class_key Classkey_of_instance ;

vars name;	;;; local to every object

;;; Message sending procedures
define global 9 message >--> obj;
	lvars obj;
	vars arg_num OLDinterrupt self;
	if obj.isword then valof(obj) -> obj endif;
	unless isprocess(obj) and isliveprocess(obj) then
		mishap(message,obj,2,'MESSAGE SENT TO NON(LIVE)-PROCESS')
	endunless;
	if obj == self then
		;;; already running
		if isword(message) then valof(message)
		elseif isprocedure(message) then chain(message)
		else mishap(name,message,2,'OBJECT SENDING MESSAGE TO ITSELF');
		endif
	else
		obj -> self;		;;; make sure environment is set up
		interrupt -> OLDinterrupt;
		define interrupt;
			;;; prevent abnormal exit, which would kill the process
			;;; exit from this call, by resuming a process which will
			;;; re-run this process in such a way as to get it ready to
			;;; run normally next time
			consproc(0,OLDinterrupt) -> message;	;;; will cause a resume
			OLDinterrupt -> interrupt;
			exitto(class_procedure(class_key));
		enddefine;

		if isinteger(message) then
			message -> arg_num; -> message
		else
			0 -> arg_num;
		endif;
		runproc(arg_num,self)	;;; after running come back, unlike |-->
	endif
enddefine;


define global 9 self <--< message;
	lvars message, self;
	chain(message, self, nonop >-->);
enddefine;


define global 9 Message |--> other;
	lvars Message other;
	if other.isword then valof(other) -> other endif;
	unless other.isprocess then
		mishap(other,1,'TARGET FOR |--> and <--| MUST BE PROCESS')
	endunless;
	Message;	;;; left on stack - will be transferred by resume
	other -> message;	;;; if message is a process, it will be resumed
	exitto(class_procedure(class_key));
enddefine;

define global 9 other <--| Message;
	lvars Message, other;
	chain(Message, other, nonop |-->)
enddefine;

/*
Syntax to enable one to write

	WITH object DO actions ENDWITH;

where the object is a class instance, and the actions define a procedure
to be evaluated in the environment of the instance.

*/

global vars syntax endwith;

define global syntax with;
    erase(systxcomp("do"));
	sysPROCEDURE([], 0);
    erase(systxsqcomp("endwith"));
	sysPUSHQ(sysENDPROCEDURE());
	sysCALL("<--<");
enddefine;


;;; A class has a key with various classfields
global vars procedure (classname,superclasses,subclasses,classfields,
					startactions, message_actions, class_procedure,
					class_props, consclasstype, isclasstype);

recordclass classtype
		classname superclasses subclasses classfields startactions
		message_actions class_procedure class_props ;

define procedure class_sub_print(class_key);
	lvars temp,class_key;
	define procedure class_sub_print(class_key);
		lvars class_key;
		;;; recursive calls should just print the name
		pr(classname(class_key));
	enddefine;
	superclasses(class_key) -> temp;
	printf(length(subclasses(class_key)), temp, classname(class_key),
				'<classtype %p, super %p, %p subclasses>')
enddefine;

define global procedure classtype_pr(class_key);
	;;; to print out a class type record, print name and information
	;;; about super and sub-classes
	lvars class_key;
	class_sub_print(class_key);
enddefine;

;;; Make this the printer for class type records
classtype_pr -> class_print(datakey(consclasstype(0,0,0,0,0,0,0,0)));


;;; Define mapping from class name to class key

global vars procedure class_of_name;

newproperty([],100,false,true) -> class_of_name;

define global procedure class_warning(Name);
	lvars Name;
	printf(Name,'\n;;; WARNING: CLASS %p BEING REDEFINED\n')
enddefine;


;;; Mechanisms for constructing classes and instances


define global new_instance(classname_or_class, new_instance_initialiser)
								->self;
	;;; create a new instance corresponding to the class
	;;; after the classinitialiser has run, this new_instance_initialiser will run
	lvars classname_or_class, new_instance_initialiser;
	vars Classkey_of_instance message;
	if isword(classname_or_class) then
		class_of_name(classname_or_class)
	else
		classname_or_class
	endif -> Classkey_of_instance;
	unless isclasstype(Classkey_of_instance) then
		mishap(classname_or_class,0,'CLASS OR CLASS NAME REQUIRED')
	endunless;
	consproc(0,class_procedure(Classkey_of_instance)) -> self;
	false -> message;
	runproc(new_instance_initialiser,1,self);
enddefine;

define set_field_value(list) -> list;
	lvars wd,list;
	destpair(list) -> list -> wd;
	destpair(list) -> list -> valof(wd)
enddefine;

define new(new_instance_info);
	;;; the argument may be of the form e.g.
	;;;		[person name john age 33 sex male]
	lvars class_of_New_instance;
	destpair(new_instance_info) -> new_instance_info ->class_of_New_instance;
	new_instance(class_of_New_instance,
				procedure;
					until null(new_instance_info) do
						set_field_value(new_instance_info) -> new_instance_info;
					enduntil;
				endprocedure);
enddefine;


define global 9 default_response;
	if isword(message) then valof(message)
	elseif isprocedure(message) then message();
	elseunless islist(message) or isprocess(message) then
		mishap(message,1,'BAD MESSAGE')
	endif;
enddefine;

;;; A user definable procedure to be run whenever a new class
;;; record is created.
global vars procedure user_class_initial;
	erase -> user_class_initial;		;;; user assignable

define startclass(Name,super,fieldlist,initial,mess_actions,class_proc);
	lvars item, Name,super,fieldlist,initial,mess_actions,class_proc,
		sup new_classkey;

	if class_of_name(Name) then
		class_warning(Name)
	endif;
	if super==undef or super = [undef] then
		false
	elseif islist(super) then
		[%for item in super do
			if class_of_name(item)->> sup then
			   sup
			else
				mishap(item,1,'NON CLASS NAME GIVEN:')
			endif
			endfor
		%]
	else
		mishap(super,1,'NON CLASS NAME GIVEN:')
	endif -> super;

	consclasstype(Name,super,[],fieldlist,initial,
					mess_actions,class_proc,
					newproperty([],10,undef,true)) -> new_classkey;
	new_classkey ->  class_of_name(Name);
	if super then
		for item in super do
			new_classkey::subclasses(item) -> subclasses(item)
		endfor;
	endif;
	user_class_initial(new_classkey);
enddefine;

define checkread(closer) -> item;
	lvars closer, item;
	readitem() -> item;
	if identprops(item) == "syntax" and item /== closer then
		mishap(item,' EXPECTING ', closer, 3,'MISPLACED SYNTAX WORD: ')
	endif;
enddefine;

define check_readlist(closer) -> list;
	lvars closer item list;
	[% while nextitem() /= closer do checkread(closer) endwhile %] -> list;
enddefine;

vars syntax (ENDCLASS, SUBCLASS_OF, CLASS_FIELDS, START_ACTIONS,
		MESSAGE_ACTIONS);

define constant sysCALLQ_?(proc);
	lvars proc;
	if proc then sysCALLQ(proc) endif
enddefine;

define constant sysSETLOCALS(list);
	;;; make sure all the words in list are declared, and make them
	;;; local to current procedure
	;;; If an element is a list do the same recursively
	lvars item, list;
	for item in list do
		if islist(item) then sysSETLOCALS(item)			;;; ??? needed?
		else sysSYNTAX(item,0,false); sysLOCAL(item)
		endif
	endfor;
enddefine;

define constant sysSETSUPERLOCALS(sup);
	;;; sup is a superclass or list of superclasses of current class
	;;; climb up all chains of superclasses, setting declarations
	;;; of local variables
	lvars sup list;
	while sup do
		if islist(sup) then applist(sup,sysSETSUPERLOCALS); return()
		else
			sysSETLOCALS(classfields(sup));
			superclasses(sup) -> sup
		endif
	endwhile;
enddefine;



define constant run_other_process();
	;;; the value of message is a process to be run.
	;;; there may or may not be something on the stack to be sent as
	;;; a message
	lvars other_process;
	message -> other_process;
	if stacklength() == 0 then
		false
	endif -> message;
;;;message =>
;;;"name" >--> other_process =>
	resume(stacklength(), other_process)
enddefine;

;;; utilities for getting at field names corresponding to a class or object
define global procedure allfields (class);
    ;;; return all the field names corresponding to the class
    ;;; including the fields of all super classes
    lvars class sup;
	if isprocess(class) then "class_key" >--> class
    elseif isword(class) then class_of_name(class)
	else class
	endif -> class;
    dl(classfields(class));
    superclasses(class)-> sup;
    if sup then applist(sup,allfields) endif
enddefine;

define global procedure listallfields(class);
    [%allfields(class) %]
enddefine;


constant CLASS;
define global syntax CLASS ;
	lvars Name super sup fieldlist
		 init_actions mess_actions item start run resuming class_proc;
	;;; read in class Name
	itemread() -> Name;
	erase(sysneed("SUBCLASS_OF"));

	;;; then names of super classes
	check_readlist("CLASS_FIELDS") -> super;

	if super==[] or super = [undef] then false
	else
		[% for item in super do
			class_of_name(item) ->> item;
;;;;;[super ^item] =>
			unless item then mishap(item,1,'NON CLASS NAME GIVEN:') endunless;
		  endfor
		%]
	endif -> sup;

;;;;; [supers ^sup] =>

	erase(sysneed("CLASS_FIELDS"));

	;;; read in field names and declare them globally as variables
	[%until (checkread("START_ACTIONS") ->> item) == "START_ACTIONS" do
		unless item == "," then
			item;
			;;; make sure it is declared as a variable
			sysSYNTAX(item,0,false);
		endunless;
	enduntil%] -> fieldlist;

	;;; Compile an instance initialisation procedure, if necessary
	if (nextitem()->> item) == "MESSAGE_ACTIONS" then
		erase(readitem());
		false
	else
		;;; now compile initialisation procedure
		sysPROCEDURE('initialise_'><Name,0);
			if sup then
				for item in sup do
;;;;; [initialiser ^item] =>
					;;; run the initialisers for the super class
	 				sysCALLQ_?(startactions(item));
				endfor
			endif;
		    erase(systxsqcomp("MESSAGE_ACTIONS"));
		sysENDPROCEDURE()
	endif
	 -> init_actions;

	;;; compile procedure to deal with messages, if necessary
	if nextitem() == "ENDCLASS" then
		false;
		erase(readitem())
	else
		;;; compile procedure to deal with messages
		sysPROCEDURE('messages_'><Name,0);
			if sup then
				for item in sup do
					;;; run the message actions for the super class
;;;;;[mess actions ^(message_actions(item))] =>
					sysCALLQ_?(message_actions(item));
				endfor
			endif;
		    erase(systxsqcomp("ENDCLASS"));
		sysENDPROCEDURE()
	endif -> mess_actions;

	;;; Now create the main procedure for the class;

	sysPROCEDURE(Name,0);
		;;; make all the field names, plus the default names, local
		sysVARS("class_key",0);
		sysSETLOCALS(fieldlist);

		;;; declare field names inherited from superclasses
		sysSETSUPERLOCALS(sup);

		;;; give each instance default value for: class_key
		sysPUSH("Classkey_of_instance");	;;; will have a value at initialisation time
		sysPOP("class_key");
		sysCALLQ(apply);		;;; call instance initialiser - on stack
		sysCALLQ_?(init_actions);	;;; run class initialiser

		;;; initialisation ends here

		;;; start a loop - forever read in message and process then suspend
		;;; except that if the value of the message is a process, then
		;;; resume that process. use whatever is on the stack.
		sysnlabel() -> start;
		sysnlabel() -> run;
		sysnlabel() -> resuming;
		sysLABEL(start);
		sysPUSH("message");
		sysCALLQ(isprocess);
		sysIFSO(resuming);
		sysCALLQ(stacklength);
		sysCALLQ(suspend);
		sysGOTO(run);
		sysLABEL(resuming);
		;;; resume process in value of message. The message to be sent it
		;;; may be on the top of the stack.
		sysCALLQ(run_other_process);

		sysLABEL(run);

		;;; note since process is run in context of >-->, "message"
		;;; and "self" will always have values.
		;;; see if super_classes have anything to say about the action
		;;; then the procedure for this class
		sysCALLQ_?(mess_actions);
		;;; default action
		sysCALLQ(nonop default_response);
		sysGOTO(start);
	sysENDPROCEDURE()
		-> class_proc;

	startclass(Name,super,fieldlist,init_actions,mess_actions,class_proc);
enddefine;

unless member("CLASS", vedopeners) then
	[^^vedopeners with CLASS] -> vedopeners;
	[^^vedclosers endwith  ENDCLASS] -> vedclosers;
	[^^vedbackers SUBCLASS_OF SUBCLASS_OF, CLASS_FIELDS, START_ACTIONS,
		MESSAGE_ACTIONS] -> vedbackers;
endunless;

section_cancel(current_section);
endsection;

section;

global vars name;

define global default_printer;
	pr('<' >< classname(class_key) >< space >< name >< '>')
enddefine;


CLASS thing
SUBCLASS_OF undef
CLASS_FIELDS
	name
	class_printer
START_ACTIONS
	default_printer -> class_printer
MESSAGE_ACTIONS
ENDCLASS;

endsection;
