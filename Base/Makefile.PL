use ExtUtils::MakeMaker;

WriteMakefile( NAME => 'OnLDAP::Base',
	       LIBS => ['-lldap'],
	       PM => {'Base.pm' => '$(INST_LIBDIR)/Base.pm'},
	       OBJECT => "ldap_wrap.o" );

sub MY::postamble {
    return <<"MAKE_FRAG"
ldap_wrap.c: ldap.i
\tswig -perl -proxy -const -I/usr/include -module OnLDAP::Base \$<

Base.pm: ldap_wrap\$(OBJ_EXT)

MAKE_FRAG
}
