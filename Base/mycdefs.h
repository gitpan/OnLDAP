#define _LDAP_CDEFS_H

#define LDAP_BEGIN_DECL	extern "C" {
#define LDAP_END_DECL	}

 /* ANSI C or C++ */
#define LDAP_P(protos)	protos
#define LDAP_CONCAT1(x,y)	x ## y
#define LDAP_CONCAT(x,y)	LDAP_CONCAT1(x,y)
#define LDAP_STRING(x)	#x /* stringify without expanding x */
#define LDAP_XSTRING(x)	LDAP_STRING(x) /* expand x, then stringify */

#ifndef LDAP_CONST
#define LDAP_CONST	const
#endif

#define LDAP_GCCATTR(attrs)

#	define LBER_F(type)		extern type
#	define LBER_V(type)		extern type
#	define LDAP_F(type)		extern type
#	define LDAP_V(type)		extern type
#	define LDAP_AVL_F(type)		extern type
#	define LDAP_AVL_V(type)		extern type
#	define LDAP_LDBM_F(type)	extern type
#	define LDAP_LDBM_V(type)	extern type
#	define LDAP_LDIF_F(type)	extern type
#	define LDAP_LDIF_V(type)	extern type
#	define LDAP_LUNICODE_F(type)	extern type
#	define LDAP_LUNICODE_V(type)	extern type
#	define LDAP_LUTIL_F(type)	extern type
#	define LDAP_LUTIL_V(type)	extern type
#	define LDAP_REWRITE_F(type)	extern type
#	define LDAP_REWRITE_V(type)	extern type
#	define LDAP_SLAPD_F(type)	extern type
#	define LDAP_SLAPD_V(type)	extern type
#	define LDAP_LIBC_F(type)	extern type
#	define LDAP_LIBC_V(type)	extern type

