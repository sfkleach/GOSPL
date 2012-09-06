;;; Summary: example for use with lib eprospect

;;; An example expert system fragment adapted by JLC from ALX for use
;;; with LIB EPROSPECT (Feb 1983) - this file is not referred to by
;;; any of the teach files, because TEACH EXPERTS is not a "Local" file

 [
   [ [carburettor mix too weak] => 15 0.05 [carburettor adjusted weak] ]
   [ [car difficult to start] => 4.5 0.3 [carburettor mix too weak] ]
   [ [difficult to rev engine] => 10 0.5 [carburettor mix too weak] ]
   [ [spark plugs grey] => 20 0.1 [carburettor mix too weak] ]
   [ [engine overheats] => 10 0.5 [carburettor mix too weak] ]
   [ [there is lack of power] => 4.5 0.5 [carburettor mix too weak] ]
   [ [carburettor mix too rich] => 10 0.05 [fuel jets enlarged] ]
   [ [car done very high mileage] => 50 1 [vhm_or_wc] ]
   [ [jets cleaned with wire] => 50 1 [vhm_or_wc] ]
   [ [vhm_or_wc] => 20 0.05 [fuel jets enlarged] ]
   [ [there is lack of power] => 3 0.3 [carburettor mix too rich] ]
   [ [heavy fuel consumption] => 20 0.1 [carburettor mix too rich] ]
   [ [exhaust smoky] => 20 0.3 [carburettor mix too rich] ]
   [ [car backfiring] => 20 0.7 [carburettor mix too rich] ]
   [ [carburettor mix too rich] => 15 0.05 [carburettor adjusted rich] ]
   [ [carburettor mix too weak] => 20 0.5 [fuel pump faulty] ]
   [ [carburettor mix too weak] => 10 0.5 [needle valve faulty] ]
   [ [high float level] => 20 0.5 [needle valve faulty] ]
   [ [carburettor mix too rich] => 10 0.05 [high float level] ]
   [ [car difficult to start]
     [carburettor mix too weak] => 15 0.3 [start jet blocked] ]
   [ [difficult to rev engine]
     [carburettor mix too weak] => 30 0.07 [main jet blocked] ]
 ] -> system;

vars priors;
[ [[jets cleaned with wire] 0.005]
  [[carburettor mix too rich] 0.3]
  [[carburettor adjusted weak] 0.17]
  [[car difficult to start] 0.1]
  [[difficult to rev engine] 0.025]
  [[spark plugs grey] 0.17]
  [[engine overheats] 0.025]
  [[there is lack of power] 0.17]
  [[carburettor mix too weak] 0.3]
  [[needle valve faulty] 0.05]
  [[fuel pump faulty] 0.05]
  [[fuel jets enlarged] 0.01]
  [[main jet blocked] 0.02]
  [[car done very high mileage] 0.01]
  [[vhm_or_wc] 0.01]
  [[jets cleaned with wire] 0.005]
  [[there is lack of power] 0.17]
  [[heavy fuel consumption] 0.17]
  [[exhaust smoky] 0.05]
  [[car backfiring] 0.025]
  [[carburettor adjusted rich] 0.17]
  [[high float level] 0.025]
  [[start jet blocked] 0.02]
] -> priors;

vars go; [eprospect(system,priors);] -> go; vars macro go;

;;; eprospect(system,priors);
;;; -2
;;; -5
;;; 0
;;; -5
;;; 3
;;; 4.5
;;; 4
;;; -4
;;; -5
;;; -5
