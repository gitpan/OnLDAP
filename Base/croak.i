/*
**  croak.i
**
** typemaps to throw exceptions from wrapped functions without
** leaking memory
*/


%typemap(in, numinputs=0) char **CROAK (char *err) "err=NULL; $1=&err;";

%typemap(argout, numinputs=0) char **CROAK "if (*($1)) SWIG_croak(*($1));";

#define SETCROAK(e) (*CROAK=(e))

