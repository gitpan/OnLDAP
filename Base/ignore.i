/*
** ignore.i
**
** functions and data structs that should not be wrapped
*/

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

%ignore ldapmod::mod_op;
%ignore ldapmod::mod_type;
%ignore ldapmod::mod_vals;


