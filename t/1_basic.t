#!/usr/local/bin/perl

BEGIN {delete $ENV{PERL_DL_NONLAZY}}

use Test::More tests => 2;

use strict;
use warnings;

BEGIN { use_ok('OnLDAP') };


my $host=$ENV{LDAPSERVER}||'localhost';
my $ld;
ok($ld=OnLDAP::Client->new($host), "new");



