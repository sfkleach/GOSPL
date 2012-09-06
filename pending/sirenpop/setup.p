;;; Extend the search paths for the SIREN poplog system.

uses plug_archive

extend_searchlist( '$siren/pop/auto', popautolist ) -> popautolist;
extend_searchlist( '$siren/pop/lib', popuseslist ) -> popuseslist;
extend_searchlist( '$siren/pop/auto/xt', popautolist ) -> popautolist;
extend_searchlist( '$siren/pop/auto/hip', popautolist ) -> popautolist;
extend_searchlist( [['$siren/pop/help' help]], vedhelplist ) -> vedhelplist;
extend_searchlist( [['$siren/pop/ref' ref]], vedreflist ) -> vedreflist;
extend_searchlist( [['$siren/pop/teach' teach]], vedteachlist ) -> vedteachlist;
extend_searchlist( [['$siren/pop/doc' doc]], veddoclist ) -> veddoclist;
