/*
** mytypemaps.i
*/


/* handle arguments returning strings */
%typemap(in, numinputs=0) char **OUTPUT (char *temp) "temp=NULL; $1=&temp;";
%typemap(argout) char **OUTPUT {
    if(argvi >= items) EXTEND(sp, 1);
    $result = sv_2mortal(newSVpv(*$1, 0));
    argvi++;
}
%typemap(freearg) char **OUTPUT { ldap_memfree($1); }


%define make_in_OUTPUT(type)
%typemap(in, numinputs=0) type * OUTPUT (type temp) "temp=0; $1=&temp;";
%enddef

%define make_OUTPUT(type)
make_in_OUTPUT(type);
%typemap(argout) type * OUTPUT {
    if (argvi >= items) EXTEND(sp, 1);
    $result = sv_newmortal();
    SWIG_MakePtr($result, (void *) *($1),
		 $descriptor(type), SWIG_OWNER|SWIG_SHADOW);
    argvi++;
}
%enddef

%inline %{
typedef char ** PUSHPPchar;
typedef char * STRING;
%}
%typemap(out) PUSHPPchar %{
    if ($1) {
	char **p;
	for (p=$1; *p; p++) {
	    if(argvi >= items) EXTEND(sp, 1);
	    $result = sv_2mortal(newSVpv(*p, 0));
	    argvi++;
	}
    }
%}

%{
static char **PERLARRAY2PPchar(SV *input, char **croak) {
    char **p;
    *croak=NULL;
    if(SvOK(input)) {
	if (SvROK(input)) {
	    AV *av=(AV *)SvRV(input);
	    if (SvTYPE((SV *)av)==SVt_PVAV) {
		int len=av_len(av)+1;
		if(p=calloc(len+1, sizeof(char *))) {
		    int i;
		    for(i=0; i<len; i++) {
			SV **sv=av_fetch(av, i, 0);
			if (!sv) {
			    *croak="Sparse array detected";
			    free(p);
			    return NULL;
			}
			p[i]=SvPV_nolen(*sv);
		    }
		    return p; 
		}
		else *croak="Out of memory";
	    }
	}
	else *croak="Invalid type, ARRAY ref expected";
    }
    return NULL;
}
%}

%{
static void PERLARRAY2PPANY(SV *input, void **output, char **croak,
			    swig_type_info *type) {
    void **p;
    *croak=NULL;
    if(SvOK(input)) {
	if(SvROK(input)) {
	    AV *av=(AV *)SvRV(input);
	    if (SvTYPE((SV *)av)==SVt_PVAV) {
		int len=av_len(av)+1;
		if(p=calloc(len+1, sizeof(void *))) {
		    int i;
		    for(i=0; i<len; i++) {
			SV **sv=av_fetch(av, i, 0);
			if (!sv) {
			    *croak="Sparse array detected";
			    free(p);
			    *output=NULL;
			    return;
			}
			if (SWIG_ConvertPtr(*sv, p+i, type, 0) < 0) {
			    *croak="Array element of invalid type";
			    free(p);
			    *output=NULL;
			    return;
			}
		    }
		    *output=p;
		    return;
		}
		else *croak="Out of memory";
	    }
	}
	else *croak="Invalid type, ARRAY ref expected";
    }
    *output=NULL;
}
%}
%typemap(in) char **PPchar {
    char *croak;
    $1=PERLARRAY2PPchar($input, &croak);
    if(croak) SWIG_croak(croak);
}
%typemap(freearg) char **PPchar "if ($1) free($1);";


%typemap(in, numinputs=0) int ZERO "$1=0;";

// make_in_OUTPUT(LDAPControl **);

%{
static SV *PPANY2PERLARRAY(void **pe1,
			   void (*conversor)(SV *, void *,
					    swig_type_info *, int),
			   swig_type_info *type, int flags,
			   void *freeder) {
    if (pe1) {
	AV *av=newAV();
	SV *output=sv_2mortal(newRV_noinc((SV *)av));
	void **pe;
	for (pe=pe1; *pe; pe++) {
	    SV *sv=newSV(0);
	    (*conversor)(sv, *pe, type, flags);
	    av_push(av, sv);
	}
	if (freeder) { (*((void (*)(void *))freeder))(pe1); }
	return output;
    }
    else return &PL_sv_undef;
}
   
%}
%define make_OUTPUT_ARRAY(type, conversor, flags, freeder)
%typemap(in, numinputs=0) type ** OUTPUT_ARRAY (type *temp) "temp=0; $1=&temp;";
%typemap(argout) type ** OUTPUT_ARRAY {
    if (argvi >= items) EXTEND(sp, 1);
    $result = PPANY2PERLARRAY((void **)(*($1)), conversor,
			      $descriptor(type), flags, freeder);
    argvi++;
}
%enddef

%define make_OUT_ARRAY(type, conversor, flags, freeder)
%typemap(out) type * {
    ST(argvi++)=PPANY2PERLARRAY((void **)($1), conversor,
				$descriptor(type), flags, freeder);
}
%enddef

%{
static void PCHAR2PERL(SV *output, void *input,
		      swig_type_info *type, int flags) {
    sv_setpv(output, (char *)input);
}
%}
/* make_OUTPUT_ARRAY(char *, &PCHAR2PERL, 0, NULL); */
make_OUTPUT_ARRAY(STRING, &PCHAR2PERL, 0, &ldap_value_free);
