package OnLDAP;

use 5.008;

our $VERSION = '0.10';

use strict;
use warnings;
require Exporter;
our @ISA=qw(Exporter);

use OnLDAP::Base qw(:const);
our @EXPORT=@{$OnLDAP::Base::EXPORT_TAGS{const}};

package OnLDAP::Client;
our @ISA=qw(OnLDAP::Base::Client);

use strict;
use warnings;

use Carp;


sub _first {
    defined($_) && return $_ for (@_);
    return undef;
}

sub new {
    my $class=shift;
    my $host=shift if @_&1;
    my %opts=(ProtocolVersion => 3, @_);

    $host=_first $host, delete($opts{Host});
    defined $host
	or croak "LDAP server address missing";
    my $port=_first delete($opts{Port}), OnLDAP::LDAP_PORT;
    my $ld=$class->SUPER::new($host, $port);
    while (my ($o, $v)=each %opts) {
	$ld->set_option($o, $v);
    }
    return $ld
}

sub DESTROY {
    my $this=shift;
    # warn "$this->DESTROY";
    $this->SUPER::DESTROY;
    $this->unbind_s; # if $this->valid;
}

package OnLDAP::Base::Client;
use OnLDAP::Base qw(:const);

use warnings;
use strict;

use Carp;

my (@opt, %topt);
{
    my @o=( LDAP_OPT_API_INFO, [qw(APIInfo APIInfo ro)],
	    LDAP_OPT_DEREF, [qw(Deref int rw)],
	    LDAP_OPT_SIZELIMIT, [qw(SizeLimit int rw)],
	    LDAP_OPT_TIMELIMIT, [qw(TimeLimit int rw)],
	    LDAP_OPT_REFERRALS, [qw(Referrals bool rw)],
	    LDAP_OPT_RESTART, [qw(Restart bool rw)],
	    LDAP_OPT_PROTOCOL_VERSION, [qw(ProtocolVersion int rw)],
	    LDAP_OPT_SERVER_CONTROLS, [qw(ServerControls Controls rw)],
	    LDAP_OPT_CLIENT_CONTROLS, [qw(ClientControls Controls rw)],
	    LDAP_OPT_API_FEATURE_INFO, [qw(APIFeatureInfo APIFeatureInfo ro)],
	    LDAP_OPT_HOST_NAME, [qw(Host string ro)],
	    LDAP_OPT_RESULT_CODE, [qw(ResultCode int rw)],
	    LDAP_OPT_ERROR_STRING, [qw(ErrorString string rw)],
	    LDAP_OPT_MATCHED_DN, [qw(MatchedDN string rw)],
	    LDAP_OPT_DEBUG_LEVEL, [qw(DebugLevel int rw)],
	    LDAP_OPT_TIMEOUT, [qw(Timeout int rw)],
	    LDAP_OPT_REFHOPLIMIT, [qw(RefHopLimit int rw)],
	    LDAP_OPT_NETWORK_TIMEOUT, [qw(NetworkTimeout int rw)],
	    LDAP_OPT_URI, [qw(URI string rw)],
	    LDAP_OPT_REFERRAL_URLS, [qw(ReferralURL string rw)],
	    LDAP_OPT_X_TLS, [qw(XTLS unknow rw)],
	    LDAP_OPT_X_TLS_CTX, [qw(XTLSCtx unknow rw)],
	    LDAP_OPT_X_TLS_CACERTFILE, [qw(XTLSCACertFile string rw)],
	    LDAP_OPT_X_TLS_CACERTDIR, [qw(XTLSCACertDir string rw)],
	    LDAP_OPT_X_TLS_CERTFILE, [qw(XTLSCertFile string rw)],
	    LDAP_OPT_X_TLS_KEYFILE, [qw(XTLSKeyFile string rw)],
	    LDAP_OPT_X_TLS_REQUIRE_CERT, [qw(XTLSRequireCert bool rw)],
	    # LDAP_OPT_X_TLS_PROTOCOL, [qw(XTLSProtocol string rw)],
	    LDAP_OPT_X_TLS_CIPHER_SUITE, [qw(XTLSCipherSuite string rw)],
	    LDAP_OPT_X_TLS_RANDOM_FILE, [qw(XTLSRandomFile string rw)],
	    LDAP_OPT_X_TLS_SSL_CTX, [qw(XTLSSSLCtx unknow rw)],
	    LDAP_OPT_X_SASL_MECH, [qw(XSASLMech string rw)],
	    LDAP_OPT_X_SASL_REALM, [qw(XSASLRealm string rw)],
	    LDAP_OPT_X_SASL_AUTHCID, [qw(XSASLAuthCID string rw)],
	    LDAP_OPT_X_SASL_AUTHZID, [qw(XSASLAuthZID string rw)],
	    LDAP_OPT_X_SASL_SSF, [qw(XSASLSSF unknow rw)],
	    LDAP_OPT_X_SASL_SSF_EXTERNAL, [qw(SASLSSFExternal unknow rw)],
	    LDAP_OPT_X_SASL_SECPROPS, [qw(XSASLSecProps unknow rw)],
	    LDAP_OPT_X_SASL_SSF_MIN, [qw(XSASLSSFMin int rw)],
	    LDAP_OPT_X_SASL_SSF_MAX, [qw(XSASLSSFMax int rw)],
	    LDAP_OPT_X_SASL_MAXBUFSIZE, [qw(XSASLMaxBufSize int rw)] );


    while (@o) {
	my $k=shift @o;
	my $v=shift @o;
	$opt[$k]=$v;
	$topt{$v->[0]}=$k;
    }
    # aliases:
    $topt{ErrorNumber}=LDAP_OPT_ERROR_NUMBER;
}

sub _opt_props {
    my $opt=shift;
    unless ($opt=~/^\d+$/) {
	defined $topt{$opt} or croak "unknow option $opt";
	$opt=$topt{$opt}
    }
    defined $opt[$opt] or croak "unknow option $opt";
    return ($opt, @{$opt[$opt]});
}

sub get_option {
    my $this=shift;
    my $opt=shift;
    my ($nopt, undef, $type, $mode )=_opt_props $opt;
    my $method='_get_option__'.$type;
    if (ref $this) {
	return $this->$method($nopt, @_);
    }
    else {
	no strict qw(refs);
	return &$method(undef, $nopt, @_);
    }
}

sub set_option {
    my ($this, $opt, $value)=@_;
    my ($nopt, undef, $type, $mode )=_opt_props $opt;
	$mode eq 'ro' and croak "option $opt is read only";
    my $method='_set_option__'.$type;
    if (ref $this) {
	return $this->$method($nopt, $value);
    }
    else {
	no strict qw(refs);
	&$method(undef, $nopt, $value);
    }
}

sub _set_option__unknow {
    my ($this, $opt)=@_;
    carp "support for option $opt is unimplemented, ignoring";
}

sub _get_option__unknow {
    my ($this, $opt)=@_;
    carp "support for option $opt is unimplemented, ignoring";
    return undef;
}

sub unbind_s {
    my $this=shift;
    my $r=$this->_unbind_s;
    $this->_forget;
    return $r;
}

*unbind=\&unbind_s;

sub unbind_ext {
    my $this=shift;
    my $r=$this->_unbind_ext(@_);
    $this->_forget;
    return $r;
}

sub _forget {
    my $this=shift;
    # warn "forgetting $this...";
    my $ref=ref $this;
    untie $this;
    # warn "blessing to ${ref}::UNBOUND";
    bless $this, "${ref}::UNBOUND";
}


1;
__END__


=head1 NAME

OnLDAP - Perl bindings for OpenLDAP client library

=head1 SYNOPSIS

  use OnLDAP;
  blah blah blah

=head1 ABSTRACT

Perl bindings for OpenLDAP client library.

=head1 DESCRIPTION

This is a work in progress, most functionality on OpenLDAP libldap is
not supported yet.

Contributions welcome!


=head2 EXPORT

LDAP constants as defined in C<ldap.h>.


=head1 SEE ALSO

SourceForge project L<http://sourceforge.net/projects/perl-openldap>.

Alternative LDAP client packages:

L<Net::LDAP>, L<Net::LDAPapi>, L<PerLDAP>

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
