;;; Summary: returns a list of all the keys of a property.
;;; Version: 1.0

compile_mode :pop11 +strict;

section;

define property_keys_list( prop );
    [% fast_appproperty( prop, erase ) %]
enddefine;

endsection;
