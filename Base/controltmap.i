/*
** controltmap.i
**
** controls are passed by value and copied when required.
*/

%typemap(in) LDAPControl **PPANY {
    char *croak;
    PERLARRAY2PPANY($input, (void **)(&($1)), &croak, $*1_descriptor);
    if(croak) SWIG_croak(croak);
}
%typemap(freearg) LDAPControl **PPANY "if ($1) free($1);";

%{

static LDAPControl *new_control(char *oid, BerValue *bv, int critical) {
    LDAPControl *c;
    if (c=malloc(sizeof(*c))) {
	c->ldctl_oid=oid ? strdup(oid) : NULL;
	if (bv) {
	    c->ldctl_value.bv_len=bv->bv_len;
	    if (bv->bv_val) {
		char *mem=(char *)malloc(bv->bv_len+1);
		memcpy(mem, bv->bv_val, bv->bv_len);
		mem[bv->bv_len]='\0';
		c->ldctl_value.bv_val=mem;
	    }
	    else c->ldctl_value.bv_val=NULL;
	}
	else {
	    c->ldctl_value.bv_val=NULL;
	    c->ldctl_value.bv_len=0;
	}
	c->ldctl_iscritical=critical;
    }
    return c;
}

static LDAPControl *dup_control(LDAPControl *s) {
    return new_control(s->ldctl_oid,
		       &(s->ldctl_value), 
		       s->ldctl_iscritical);
}

static void free_control(LDAPControl *s) {
    if (s) {
	if (s->ldctl_oid) free(s->ldctl_oid);
	if (s->ldctl_value.bv_val) free(s->ldctl_value.bv_val);
	free(s);
    }
}

static void LDAPControl2PERL_COPY(SV *output, void *input,
				 swig_type_info *type, int flags) {
    LDAPControl *copy=dup_control((LDAPControl *) input);
    return SWIG_MakePtr(output, (void *) copy,
			type, flags|SWIG_OWNER);
}
%}

make_OUT_ARRAY(LDAPControl *, &LDAPControl2PERL_COPY,
	       SWIG_SHADOW, &ldap_controls_free );
make_OUTPUT_ARRAY(LDAPControl *, &LDAPControl2PERL_COPY,
		  SWIG_SHADOW, &ldap_controls_free );
%typemap(out) LDAPControl * %{
    LDAPControl2PERL_COPY(ST(argvi++), (void *)($1),
			  $1_descriptor, SWIG_SHADOW|SWIG_OWNER);
%}
