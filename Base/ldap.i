
%{
#include <string.h>

#include <lber.h>
#include <ldap.h>
%}


%include "typemaps.i";
%include "croak.i";

%include "ignore.i";

%include "mytmaps.i";
%include "controltmap.i";
%include "bervaluetmap.i";
%include "msgtmap.i"
%include "modtmap.i"

%rename(Client) ldap;
%rename(Message) ldapmsg;
%rename(Control) ldapcontrol;
%rename(APIInfo) ldapapiinfo;
%rename(APIFeatureInfo) ldap_apifeature_info;
%rename(URLDesc) ldap_url_desc;
%rename(Mod) ldapmod;
%rename(AVA) ldap_ava;

struct ldap {};
struct ldapmsg {};

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
    PUSHPPchar extensions() { return self->ldapai_extensions; }
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

%extend LDAPMod {

    make_OUT_ARRAY(BerValue, BerValue2RV, 0, NULL);
    %typemap(freearg) char * "";

    LDAPMod (int op, char *type, SV *array, char **CROAK) {
	LDAPMod *self;
	*CROAK=NULL;
	if (self=malloc(sizeof(struct ldapmod *))) {
	    self->mod_op=op|LDAP_MOD_BVALUES;
	    self->mod_type=strdup(type);
	    self->mod_bvalues=RV2BerValueARRAY(array, 1, CROAK);
	    if (*CROAK) {
		free(self);
		return NULL;
	    }
	}
	return self;
    }

    ~LDAPMod() {
	if (self) {
	    if (self->mod_type) free(self->mod_type);
	    free_BerValueARRAY(self->mod_bvalues, 1);
	    free (self);
	}
    }

    int op() { return self->mod_op; }
    char *type() { return self->mod_type; }
    BerValue **values() { return self->mod_bvalues; }
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

    int _unbind(LDAPControl **serverctrls=NULL,
		LDAPControl **clientctrls=NULL) {
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
    int ldap_parse_reference(LDAP *ld,
			     LDAPMessage *ref,
			     STRING **OUTPUT_ARRAY,
			     LDAPControl ***OUTPUT_ARRAY,
			     int ZERO);

    /* in getentry.c: */
    LDAPMessage *first_entry(LDAPMessage *chain);
    LDAPMessage *next_entry(LDAPMessage *entry);
    int count_entries(LDAPMessage *chain);
    int get_entry_controls(LDAPMessage *entry,
			   LDAPControl ***OUTPUT_ARRAY);
    
    /* in addentry.c */
    /* LDAPMessage *delete_result_entry(LDAPMessage **OUT,
                                        LDAPMessage *e); */

    /* in result.c: */
    int result(int msgid, int all=0,
	       struct timeval *timeout=NULL,
	       LDAPMessage **OUTPUT);

    %rename(search) search_ext;
    int search_ext(char *base=NULL, int scope=0, char *filter=NULL,
		   char **PPchar=NULL, int attrsonly=0,
		   LDAPControl **serverctrls=NULL,
                   LDAPControl **clientctrls=NULL,
		   struct timeval *timeout=0,
		   int sizelimit=0,
		   int *OUTPUT);

    %rename(search_s) search_ext_s;
    int search_ext_s(char *base=NULL, int scope=0, char *filter=NULL,
		      char **PPchar=NULL, int attrsonly=NULL,
		      LDAPControl **serverctrls=NULL,
		      LDAPControl **clientctrls=NULL,
		      struct timeval *timeout=NULL,
		      int sizelimit=0,
		      LDAPMessage **OUTPUT);

    int parse_result(LDAPMessage *res,
		 int *OUTPUT,
		 char **OUTPUT,
		 char **OUTPUT,
		 STRING **OUTPUT_ARRAY,
		 LDAPControl ***OUTPUT_ARRAY,
		 int ZERO);

    /* in extended.c */
    int extended_operation(char *reqoid,
			   struct berval *reqdata,
			   LDAPControl **serverctrls=NULL,
			   LDAPControl **clientctrls=NULL,
			   int *OUTPUT);

    int extended_operation_s(char *reqoid,
			     struct berval *reqdata,
			     LDAPControl **serverctrls=NULL,
			     LDAPControl **clientctrls=NULL,
			     char **OUTPUT,
			     BerValue **OUTPUTSTR);
    
    int parse_extended_result(LDAPMessage *res,
			      char **OUTPUT,
			      BerValue **OUTPUTSTR,
			      int ZERO);
    
    int parse_extended_partial(LDAPMessage *res,
			       char **OUTPUT,
			       BerValue **OUTPUTSTR,
			       LDAPControl ***OUTPUT_ARRAY,
			       int ZERO);
    
    int parse_intermediate_resp_result(LDAPMessage *res,
				       char **OUTPUT,
				       BerValue **OUTPUTSTR,
				       int ZERO);

    /* in abandon.c */
    %rename(abandon) abandon_ext;
    int abandon_ext(int msgid,
		    LDAPControl **serverctrls=NULL,
		    LDAPControl **clientctrls=NULL);

    /* in add.c */
    %rename(add) add_ext;
    int add_ext(char *dn,
		LDAPMod **attrs,
		LDAPControl **serverctrls=NULL,
		LDAPControl **clientctrls=NULL,
		int *OUTPUT);

    %rename(add_s) add_ext_s;
    int add_ext_s(char *dn,
		  LDAPMod **attrs,
		  LDAPControl **serverctrls=NULL,
		  LDAPControl **clientctrls=NULL);

    /* in cancel.c */
    int ldap_cancel(int cancelid,
		    LDAPControl **sctrls=NULL,
		    LDAPControl **cctrls=NULL,
		    int *OUTPUT);

    int ldap_cancel_s(int cancelid,
		      LDAPControl **sctrls=NULL,
		      LDAPControl **cctrls=NULL);

    /* in compare.c */
    %rename(compare) compare_ext;
    int compare_ext(char *dn,
		    char *attr,
		    struct berval *bvalue,
		    LDAPControl **serverctrls,
		    LDAPControl **clientctrls,
		    int *OUTPUT);
    
    %rename(compare_s) compare_ext_s;
    int compare_ext_s(char *dn,
		      char *attr,
		      struct berval *bvalue,
		      LDAPControl **serverctrls,
		      LDAPControl **clientctrls);

    /* in delete.c */
    %rename(delete) delete_ext;
    int delete_ext(char *dn,
		   LDAPControl **sctrls=NULL,
		   LDAPControl **cctrls=NULL,
		   int *OUTPUT);

    %rename(delete_s) delete_ext_s;
    int delete_ext_s(char *dn,
		     LDAPControl **sctrls=NULL,
		     LDAPControl **cctrls=NULL);

    /* in error.c */
    /* ldap_err2sting(...) */

    /* in modify.c */
    %rename(modify) modify_ext;
    int modify_ext(char *dn,
		   LDAPMod **mods,
		   LDAPControl **sctrls=NULL,
		   LDAPControl **cctrls=NULL,
		   int *OUTPUT);

    %rename(modify_s) modify_ext_s;
    int modify_ext_s(char *dn,
		     LDAPMod **mods,
		     LDAPControl **sctrls=NULL,
		     LDAPControl **cctrls=NULL);
    
    /* in modrdn.c */
    int rename(char *dn,
	       char *new_rdn,
	       char *new_superior,
	       int delete_old_rdn,
	       LDAPControl **sctrls=NULL,
	       LDAPControl **cctrls=NULL,
	       int *OUTPUT);
    
    int rename_s(char *dn,
		 char *new_rdn,
		 char *new_superior,
		 int delete_old_rdn,
		 LDAPControl **sctrls=NULL,
		 LDAPControl **cctrls=NULL);

    /* in getdn.c */
    char *get_dn(LDAPMessage *entry);

}

%extend ldapmsg {
    ldapmsg(char **CROAK) {
	SETCROAK("ldapmsg->new access forbidden");
    }
    ~ldapmsg() { ldap_msgfree(self); }
    int type() { return ldap_msgtype(self); }
    int id() { return ldap_msgid(self); }
}

%extend LDAPAVA {
}


%insert(pm) %{

package OnLDAP::Base;

%EXPORT_TAGS = (const => [grep /^LDAP_/, keys %OnLDAP::Base::]);
@EXPORT_OK=@{$EXPORT_TAGS{const}};

%}
