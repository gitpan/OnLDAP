
%{
#include <string.h>

#include <lber.h>
#include <ldap.h>
%}


%include "typemaps.i";

%ignore ber_memalloc;
%ignore ber_memrealloc;
%ignore ber_memcalloc;
%ignore ber_memfree;
%ignore ber_memvfree;
%ignore ber_bvfree;
%ignore ber_bvecfree;
%ignore ber_bvecadd;

%ignore ber_dupbv;
%ignore ber_bvdup;
%ignore ber_str2bv;
%ignore ber_mem2bv;
%ignore ber_strdup;
%ignore ber_bvarray_free;

%ignore ldap_sasl_bind;
%ignore ldap_sasl_bind_s;
%ignore ldap_parse_sasl_bind_result;
%ignore ldap_simple_bind;
%ignore ldap_simple_bind_s;

%ignore ldap_init;
%ignore ldap_first_reference;
%ignore ldap_next_reference;

%ignore ldap_count_references;
%ignore ldap_first_entry;
%ignore ldap_next_entry;
%ignore ldap_count_entries;

%ignore ldap_first_message;
%ignore ldap_next_message;
%ignore ldap_count_messages;

%ignore ldap_result;

%ignore ldap_create_control;
%ignore ldap_control_free;
%ignore ldap_controls_free;

%ignore ldap_get_option;
%ignore ldap_set_option;

%ignore ldap_search_ext;
%ignore ldap_search_ext_s;
%ignore ldap_search;
%ignore ldap_search_s;
%ignore ldap_search_st;

%ignore ldap_parse_result;

%ignore ldapcontrol::ldctl_oid;
%ignore ldapcontrol::ldctl_value;
%ignore ldapcontrol::ldctl_iscritical;

%ignore ber_sockbuf_io_tcp;
%ignore ber_sockbuf_io_readahead;
%ignore ber_sockbuf_io_fd;
%ignore ber_sockbuf_io_debug;
%ignore ber_sockbuf_io_udp;

%ignore lber_memory_fns;
%ignore sockbuf_io_desc;
%ignore sockbuf_io;


%typemap(in, numinputs=0) char **CROAK (char *err) "err=NULL; $1=&err;";
%typemap(argout, numinputs=0) char **CROAK "if (*($1)) SWIG_croak(*($1));";
#define SETCROAK(e) (*CROAK=(e))

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
typedef char ** INLINEPPCHAR;
typedef char * VALUE;
%}
%typemap(out) INLINEPPCHAR %{
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
static char **PERLARRAY2PPCHAR(SV *input, char **croak) {
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
%typemap(in) char **PPCHAR {
    char *croak;
    $1=PERLARRAY2PPCHAR($input, &croak);
    if(croak) SWIG_croak(croak);
}
%typemap(freearg) char **PPCHAR "if ($1) free($1);";

%typemap(in) LDAPControl **PPANY {
    char *croak;
    PERLARRAY2PPANY($input, (void **)(&($1)), &croak, $*1_descriptor);
    if(croak) SWIG_croak(croak);
}
%typemap(freearg) LDAPControl **PPANY "if ($1) free($1);";

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

%{
static void PCHAR2PERL(SV *output, void *input,
		      swig_type_info *type, int flags) {
    sv_setpv(output, (char *)input);
}
%}
/* make_OUTPUT_ARRAY(char *, &PCHAR2PERL, 0, NULL); */
make_OUTPUT_ARRAY(VALUE, &PCHAR2PERL, 0, &ldap_value_free);

make_in_OUTPUT(BerValue *);
%typemap(argout) BerValue ** OUTPUTSTR {
    if (argvi >= items) EXTEND(sp, 1);
    if (*($1) && (*($1))->bv_val) {
	$result = sv_2mortal(newSVpvn((*($1))->bv_val, (*($1))->bv_len));
	ber_bvfree(*($1));
    }
    else
	$result = &PL_sv_undef;
    argvi++;
}

%typemap(out) BerValue {
    if (($1).bv_val)
	ST(argvi) = sv_2mortal(newSVpvn(($1).bv_val, ($1).bv_len));
    else
	ST(argvi) = &PL_sv_undef;
    argvi++;
}

%typemap(in, numinputs=0) BerValue ** OUTPUTSTR (BerValue *temp) "temp=0; $1=&temp;";
%typemap(in) BerValue * (BerValue temp) %{
    if (SvROK((SV *)($input))) {
	if (SWIG_ConvertPtr($input, (void **) &$1, $1_descriptor,0) < 0) {
            SWIG_croak("Type error in argument $argnum of $symname. Expected $1_mangle or string");
        }
    }
    else if (SvOK((SV *)($input))) {
	int n;
	$1=&temp;
	temp.bv_val=SvPV((SV *)($input), n);
	temp.bv_len=n;
    }
    else {
	$1=NULL;
    }
%}


make_OUTPUT(struct ldapmsg *);

%rename(Client) ldap;
%rename(Message) ldapmsg;
%rename(Control) ldapcontrol;
%rename(APIInfo) ldapapiinfo;
%rename(APIFeatureInfo) ldap_apifeature_info;

struct ldap {};
struct ldapmsg {};

%apply struct ldapmsg **OUTPUT { LDAPMessage **OUTPUT };


%include "mycdefs.h"
%include "lber.h"
%include "ldap.h";

#ifndef LDAP_OPT_RESULT_CODE
#define LDAP_OPT_RESULT_CODE LDAP_OPT_ERROR_NUMBER
#endif

%extend BerValue {
    %ignore bv_len;
    %ignore bv_val;
    int lenght() { return self->bv_len; }
    char * string() { return self->bv_val; }
    ~BerValue() { ber_bvfree(self); }
}

%extend ldapapiinfo {
    %ignore ldapai_info_version;
    %ignore ldapai_api_version;
    %ignore ldapai_protocol_version;
    %ignore ldapai_extensions;
    %ignore ldapai_vendor_name;
    %ignore ldapai_vendor_version;

    int info_version() { return self->ldapai_info_version; }
    int api_version() { return self->ldapai_api_version; }
    int protocol_version() { return self->ldapai_protocol_version; }
    INLINEPPCHAR extensions() { return self->ldapai_extensions; }
    char *vendor_name() { return self->ldapai_vendor_name; }
    int vendor_version() { return self->ldapai_vendor_version; }
}

%extend ldap_apifeature_info {
    %ignore ldapaif_info_version;
    %ignore ldapaif_name;
    %ignore ldapaif_version;

    int info_version() { return self->ldapaif_info_version; }
    char *name() { return self->ldapaif_name; }
    int version() { return self->ldapaif_version; }

    ~ldap_apifeature_info() {
	if (self->ldapaif_name) free(self->ldapaif_name);
	free (self);
    }
}
%extend LDAPControl {


    LDAPControl(char *oid, BerValue *bv, int critical) {
	return new_control(oid, bv, critical);
    }

    ~LDAPControl() { free_control(self); }

    char *oid() { return self->ldctl_oid; }
    BerValue value() { return self->ldctl_value; }
    int critical() { return self->ldctl_iscritical; }
}

%extend ldap {

    %typemap(newfree) char * "if ($1) ldap_memfree($1);";

    /* in sasl.c: */
    int sasl_bind(LDAP_CONST char *dn,
		  LDAP_CONST char *mechanism,
		  BerValue *cred=NULL,
		  LDAPControl **serverctrls=NULL,
		  LDAPControl **clientctrls=NULL,
		  int *OUTPUT);

    /* int sasl_interactive_bind_s(LDAP_CONST char *dn, *//* usually NULL *//*
				   LDAP_CONST char *saslMechanism,
				   LDAPControl **OUT *//* serverControls *//*,
                                   LDAPControl **OUT *//* clientControls *//*,
				   unsigned flags,
				   LDAP_SASL_INTERACT_PROC *proc,
				   void *defaults); */

    int sasl_bind_s(LDAP_CONST char *dn,
		    LDAP_CONST char *mechanism,
		    BerValue *cred=NULL,
		    LDAPControl **serverctrls=NULL,
		    LDAPControl **clientctrls=NULL,
		    BerValue **OUTPUTSTR);

    int parse_sasl_bind_result(LDAPMessage *res,
			       BerValue **OUTPUTSTR,
			       int ZERO);

    /* in sbind.c: */
    int simple_bind(LDAP_CONST char *who,
		    LDAP_CONST char *passwd);
    int simple_bind_s(LDAP_CONST char *who,
		      LDAP_CONST char *passwd);

    /* in open.c: */

    /* static struct ldap * init(char *host, int port=LDAP_PORT); */

    /*
    %newobject _init;
    struct ldap *_init(char *host, int port=LDAP_PORT) {
	return ldap_init(host, port);
    }
    */

    ldap(char *host, int port=LDAP_PORT) {
	return ldap_init(host, port);
    }
    ~ldap() {}

    /* static struct ldap * open(char *host, int port=LDAP_PORT); */

    int _unbind() {
	if (!self) return -1;
	return ldap_unbind(self);
    }
    int _unbind_s() {
	if (!self) return -1;
	return ldap_unbind(self);
    }
    int _unbind_ext(LDAPControl **serverctrls,
		    LDAPControl **clientctrls) {
	if (!self) return -1;
	return ldap_unbind_ext(self, serverctrls, clientctrls);
    }
    

    /* in options.c: */
    /* int get_option(int option,
       void *outvalue); */

    /* int set_option(int option,
       LDAP_CONST void *invalue); */

    int _get_option__bool(int option, char **CROAK) {
	void *v;
	if (ldap_get_option(self, option, &v)!=-1)
	    return (v==LDAP_OPT_OFF)?0:1;
	SETCROAK("ldap_get_option failed");
	return 0;
    }

    int _get_option__int(int option, char **CROAK) {
	int v;
	if(ldap_get_option(self, option, &v)!=-1)
	    return v;
	SETCROAK("ldap_get_option failed");
	return 0;
    }

    %newobject _get_option__string;
    char *_get_option__string(int option, char **CROAK) {
	char *v;
	if(ldap_get_option(self, option, &v)!=-1)
	    return v;
	SETCROAK("ldap_get_option failed");
	return NULL;
    }

    %newobject _get_option__APIInfo;
    LDAPAPIInfo *_get_option__APIInfo(int option, char **CROAK) {
	LDAPAPIInfo *v;
	if (v=(LDAPAPIInfo *) malloc(sizeof(*v))) {
	    v->ldapai_info_version=LDAP_API_INFO_VERSION;
	    if (ldap_get_option(self, option, v)!=-1)
		return v;
	    free(v);
	}
	SETCROAK("ldap_get_option failed [APIInfo]");
	return NULL;
    }

    %newobject _get_option__APIFeatureInfo;
    LDAPAPIFeatureInfo *_get_option__APIFeatureInfo(int option, char *name, char **CROAK) {
	LDAPAPIFeatureInfo *v;
	if (v=(LDAPAPIFeatureInfo *)malloc(sizeof(*v))) {
	    v->ldapaif_info_version=LDAP_FEATURE_INFO_VERSION;
	    v->ldapaif_name=strdup(name);
	    if (ldap_get_option(self, option, v)!=-1)
		return v;
	    free(v);
	}
	SETCROAK("ldap_get_option failed [APIFeatureInfo]");
	return NULL;
    }

    %newobject _get_option__Controls;
    LDAPControl **_get_option__Controls(int option,
					char **CROAK) {
	LDAPControl **v;
	if (ldap_get_option(self, option, &v)!=-1) {
	    return v;
	}
	SETCROAK("ldap_get_option failed [Controls]");
	return NULL;
    }
    

    void _set_option__bool(int option, int value, char **CROAK) {
	if (ldap_set_option(self, option,
			    value ? LDAP_OPT_ON : LDAP_OPT_OFF)==-1)
	    SETCROAK("ldap_set_option failed");
    }

    void _set_option__int(int option, int value, char **CROAK) {
	int v=value;
	if (ldap_set_option(self, option, &v)==-1)
	    SETCROAK("ldap_set_option failed");
    }

    void _set_option__string(int option, char *value, char **CROAK) {
	if (ldap_set_option(self, option, value)==-1)
	    SETCROAK("ldap_set_option failed");
    }

    void _set_option__Controls(int option, LDAPControl **PPANY, char **CROAK) {
	if (ldap_set_option(self, option, PPANY)==-1)
	    SETCROAK("ldap_set_option failed");
    }


    /* in messages.c: */
    LDAPMessage *first_message(LDAPMessage *chain);
    LDAPMessage *next_message(LDAPMessage *msg);
    int count_messages(LDAPMessage *chain);

    /* in references.c: */
    LDAPMessage *first_reference(LDAPMessage *chain);
    LDAPMessage *next_reference(LDAPMessage *ref);
    int count_references(LDAPMessage *chain);
    /* int ldap_parse_reference(LDAP *ld,
			     LDAPMessage *ref,
			     char ***OUT,
			     LDAPControl ***OUT,
			     int ZERO); */

    /* in getentry.c: */
    LDAPMessage *first_entry(LDAPMessage *chain);
    LDAPMessage *next_entry(LDAPMessage *entry);
    int count_entries(LDAPMessage *chain);
    /* int get_entry_controls(LDAPMessage *entry,
                              LDAPControl ***serverctrls); */
    
    /* in addentry.c */
    /* LDAPMessage *delete_result_entry(LDAPMessage **OUT,
                                        LDAPMessage *e); */

    /* in result.c: */
    int result(int msgid, int all=0,
	       struct timeval *timeout=NULL,
	       LDAPMessage **OUTPUT);

    int search_ext(char *base=NULL, int scope=0, char *filter=NULL,
		   char **PPCHAR=NULL, int attrsonly=0,
		   LDAPControl **serverctrls=NULL,
                   LDAPControl **clientctrls=NULL,
		   struct timeval *timeout=0,
		   int sizelimit=0,
		   int *OUTPUT);

    int search_ext_s(char *base=NULL, int scope=0, char *filter=NULL,
		      char **PPCHAR=NULL, int attrsonly=NULL,
		      LDAPControl **serverctrls=NULL,
		      LDAPControl **clientctrls=NULL,
		      struct timeval *timeout=NULL,
		      int sizelimit=0,
		      LDAPMessage **OUTPUT);

    int parse_result(LDAPMessage *res,
		 int *OUTPUT,
		 char **OUTPUT,
		 char **OUTPUT,
		 VALUE **OUTPUT_ARRAY,
		 LDAPControl ***OUTPUT_ARRAY,
		 int ZERO);

}

%extend ldapmsg {

    ldapmsg(char **CROAK) {
	SETCROAK("ldapmsg->new access forbidden");
    }

    ~ldapmsg() { ldap_msgfree(self); }

    int type() {
	return ldap_msgtype(self);
    }
    int id() {
	return ldap_msgid(self);
    }
}


%insert(pm) %{

package OnLDAP::Base;

%EXPORT_TAGS = (const => [grep /^LDAP_/, keys %OnLDAP::Base::]);
@EXPORT_OK=@{$EXPORT_TAGS{const}};

%}
