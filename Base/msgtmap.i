/*
** ldapmsgtmap.i
*/

make_OUTPUT(struct ldapmsg *);

%apply struct ldapmsg **OUTPUT { LDAPMessage **OUTPUT };
