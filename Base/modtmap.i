
/*
** modtmap.i
*/

%typemap(in) LDAPMod **PPANY {
    char *croak;
    PERLARRAY2PPANY($input, (void **)(&($1)), &croak, $*1_descriptor);
    if(croak) SWIG_croak(croak);
}
%typemap(freearg) LDAPMod **PPANY "if ($1) free($1);";

