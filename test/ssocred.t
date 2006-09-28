#!/usr/bin/perl
# vim: set filetype=perl:
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More qw/no_plan/;
use Tivoli::AccessManager::Admin;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin::SSO::Cred' );
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd, resource => 'twiki' );
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");

my ($resp,$web,$user);
# Some prework -- I need a resource before I can do the sso
$resp = Tivoli::AccessManager::Admin::SSO::Web->create( $pd, name => 'fred', 
			    description => 'Test web resource' );
if ( $resp->isok ) {
    $web = $resp->value;
}
else {
    die "Couldn't create a resource: " . $resp->messages . "\n";
}

print "\nTESTING create, delete and new\n";

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd,
				    resource => 'fred',
				    uid  => 'mik',
				    type => 'web',
				    ssouid => 'mikfire',
				    ssopwd => 'pa$$w0rd',
				  ); 
die unless defined $sso;
SKIP : {
    skip("Cred already exists") if $sso->exist;
    $resp = $sso->create;
    is ($resp->isok, 1, "Created a new sso") or diag($resp->messages);
}

$resp = $sso->delete;
is($resp->isok, 1, "Deleted the fred cred");

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new($pd, resource => 'fred');
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");
$resp = $sso->create( uid => 'mik', 
		       type => 'web', 
		       ssouid => 'mikfire',
		       ssopwd => 'pa$$w0rd' );
is($resp->isok, 1, "Created a sso sending everything but the resource name")
    or diag($resp->messages);
$resp = $sso->delete;

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd, 
				    resource => 'fred',
				    uid => 'mik', 
				);
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");
$resp = $sso->create( type => 'web', 
		       ssouid => 'mikfire',
		       ssopwd => 'pa$$w0rd' );
is($resp->isok,1,"Created a sso, sending type, ssouid and ssopwd to create")
  or diag($resp->messages);
$resp = $sso->delete;

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd, 
				    resource => 'fred',
				    uid => 'mik', 
				    type => 'web', 
				);
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");
$resp = $sso->create( 
		       ssouid => 'mikfire',
		       ssopwd => 'pa$$w0rd' );
is($resp->isok,1,"Created a sso, sending ssouid and ssopwd to create");
$resp = $sso->delete;

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd, 
				    resource => 'fred',
				    uid => 'mik', 
				    type => 'web', 
				    ssouid => 'mikfire',
				);
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");
$resp = $sso->create( 
		       ssopwd => 'pa$$w0rd' );
is($resp->isok,1,"Created a sso, sending ssopwd to create");
$resp = $sso->delete;

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new( $pd, 
				    ssopwd => 'pa$$w0rd',
				    uid => 'mik', 
				    type => 'web', 
				    ssouid => 'mikfire',
				);
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");
$resp = $sso->create( resource => $web->name );

is($resp->isok,1,"Created a sso, sending name to create");
$resp = $sso->delete;

$resp = Tivoli::AccessManager::Admin::SSO::Cred->create( $pd,
				    resource => 'fred',
				    uid  => 'mik',
				    type => 'web',
				    ssouid => 'mikfire',
				    ssopwd => 'pa$$w0rd',
				  ); 
is($resp->isok,1,"Used create as a class method");
$sso = $resp->value;
isa_ok($sso, "Tivoli::AccessManager::Admin::SSO::Cred");

print "\nTESTING get/set calls\n";

# NAME
$resp = $sso->resource();
is(scalar($resp->value), "fred", "Got the resource id back");

# SSOPWD
$resp = $sso->ssopwd('derf');
is($resp->isok, 1, "Set the ssopwd");

$resp = $sso->ssopwd();
is(scalar($resp->value), "derf", "Got the new ssopwd back");

$resp = $sso->ssopwd(ssopwd => 'derf');
is($resp->isok, 1, "Set the ssopwd with a named parameter");

$resp = $sso->ssopwd(foobar => 'fred');
is(scalar($resp->value), "derf", "Ignored invalid hash keys");

# SSOUID
$resp = $sso->ssouid('derf');
is($resp->isok, 1, "Set the ssouid");

$resp = $sso->ssouid();
is(scalar($resp->value), "derf", "Got the new ssouid back");

$resp = $sso->ssouid(ssouid => 'fred');
is($resp->isok, 1, "Set the ssouid with a named parameter");

$resp = $sso->ssouid(foobar => 'derf');
is(scalar($resp->value), "fred", "Ignored invalid hash keys");

# TYPE
$resp = $sso->type();
is(scalar($resp->value), "web", "Got the type back") or
diag($resp->messages);

# USER
$resp = $sso->user();
is(scalar($resp->value), "mik", "Got the user back") or diag($resp->messages);

print "\nTESTING list\n";

$resp = $sso->list();
is( $resp->isok, 1, "Listed the gso resources for mik using instance method") or
diag($resp->messages);

for ( $resp->value ) {
    isa_ok($_, "Tivoli::AccessManager::Admin::SSO::Cred");
}

$resp = Tivoli::AccessManager::Admin::SSO::Cred->list($pd, "mik");
is( $resp->isok, 1, "Listed the gso resources for mik using class method") or
diag($resp->messages);

for ( $resp->value ) {
    isa_ok($_, "Tivoli::AccessManager::Admin::SSO::Cred");
}

$resp = Tivoli::AccessManager::Admin::SSO::Cred->list($pd, uid => "mik");
is( $resp->isok, 1, "Listed the gso resources for mik using hash call") or
diag($resp->messages);

for ( $resp->value ) {
    isa_ok($_, "Tivoli::AccessManager::Admin::SSO::Cred");
}

print "\nTESTING brokeness\n";

$resp = $sso->ssopwd(qw/one two three/);
is($resp->isok, 0, "Could not call ssopwd with an odd number of paramters");

$resp = $sso->ssouid(qw/one two three/);
is($resp->isok, 0, "Could not call ssouid with an odd number of paramters");

$resp = Tivoli::AccessManager::Admin::SSO::Cred->list( $pd );
is($resp->isok, 0, "Could not call list without a uid");

$resp = Tivoli::AccessManager::Admin::SSO::Cred->list( $pd, qw/one two three/ );
is($resp->isok, 0, "Could not call list with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::SSO::Cred->list($pd,foobar => 'derf');
is($resp->isok, 0, "Ignored an invalid hash key");

$resp = $sso->delete;
$resp = $sso->delete;
is($resp->iswarning,1,'Could not delete an already deleted cred');

# new
$sso = Tivoli::AccessManager::Admin::SSO::Cred->new();
is($sso, undef, 'Could not call new with an empty paramter list');

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new(undef);
is($sso, undef, 'Could not call new with an undefined context');

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new(qw/one two three/);
is($sso, undef, 'Could not call new with a non-context ');

$sso = Tivoli::AccessManager::Admin::SSO::Cred->new($pd, qw/one two three/);
is($sso, undef, 'Could not call new with an odd number of parameters');

#create
$resp = Tivoli::AccessManager::Admin::SSO::Cred->create();
is($resp->isok, 0, 'Could not call create with an empty paramter list');

$resp = Tivoli::AccessManager::Admin::SSO::Cred->create($pd, qw/one two three/);
is($resp->isok, 0, 'Could not call create with an odd number of parameters');

$resp = Tivoli::AccessManager::Admin::SSO::Cred->create($pd,
				      resource => 'fred',
				      uid      => 'mik',
				      ssouid   => 'foobar',
				  );
is($resp->isok, 0, 'Could not create with out a ssopwd');

$resp = Tivoli::AccessManager::Admin::SSO::Cred->create($pd,
				      ssopwd   => 'n33wonk',
				      uid      => 'mik',
				      ssouid   => 'foobar',
				  );
is($resp->isok, 0, 'Could not create with out a resource');

$resp = Tivoli::AccessManager::Admin::SSO::Cred->create($pd,
				      resource => 'fred',
				      uid      => 'mik',
				      ssopwd   => 'n33wonk',
				  );
is($resp->isok, 0, 'Could not create with out a ssouid');
