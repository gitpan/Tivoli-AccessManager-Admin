#!/usr/bin/perl
# vim: set filetype=perl:
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

# Testing the SVN module
use Test::More tests => 156;

BEGIN {
    use_ok( 'Tivoli::AccessManager::Admin' );
}

my $user;

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd = Tivoli::AccessManager::Admin->new( password => $pswd);
my $resp;

print "\nTESTING create, import and delete\n";
$resp = Tivoli::AccessManager::Admin::User->create( $pd, 
				   name     => 'luser01',
				   dn       => "cn=luser01,ou=people,o=me,c=us",
				   password => "Pa\$\$w0rd",
				   cn       => 'luser',
				   sn       => "01");
is($resp->isok, 1, "Created luser01") or diag( $resp->messages );
$user = $resp->value;

is($user->exist, 1, "User does exist");

$resp = $user->delete( registry => 1 );
is( $resp->isok, 1, "Deleted user from registry") or diag( $resp->messages);

$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       cn  => 'luser',
			       sn  => '01'
			     );
$resp = $user->create( password => 'foo|34r1' );
is( $resp->isok, 1, "luser01 recreated using new and create") or diag( $resp->messages );

$resp = $user->delete();
is( $resp->isok, 1, "Deleted user -- kept registry") or diag($resp->messages);

$resp = $user->userimport();
is( $resp->isok, 1, "luser01 imported" ) or diag($resp->messages);

$resp = $user->accountvalid;
is($resp->isok,1,"Current accountvalid is " . $resp->value);

$resp = $user->accountvalid(1);
is( $resp->value, 1, "Set account valid" ) or diag( $resp->messages );

$resp = $user->accountvalid( valid => 0 );
is( $resp->value, 0, "Set account invalid" ) or diag( $resp->messages );

$resp = $user->accountvalid( silly => 1 );
is( $resp->value, 0, "Silly key ignored" ) or diag( $resp->messages );

$resp = $user->passwordvalid;
is($resp->isok,1,"Current passwordvalid is " . $resp->value);

$resp = $user->passwordvalid(0);
is( $resp->value, 0, "Set password invalid" ) or diag( $resp->messages );

$resp = $user->passwordvalid(valid => 1);
is( $resp->value, 1, "Set password valid" ) or diag( $resp->messages );

$resp = $user->passwordvalid(silly => 0);
is( $resp->value, 1, "Ignored a silly hash key" ) or diag( $resp->messages );

$resp = $user->delete();
$resp = Tivoli::AccessManager::Admin::User->userimport( $pd,
				      name => 'luser01',
				      dn   => 'cn=luser01,ou=people,o=me,c=us',
				      sso  => 1,
				      groups => [qw/iv-admin/],
				  );
is($resp->isok, 1, "Imported user as a class method");
$user = $resp->value;

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       cn  => 'luser',
			       sn  => '01'
			     );
$resp = $user->create( password => 'foo|34r1' );
is( $resp->isok, 0, "Couldn't create a user without a name") or diag( $resp->messages );

$resp = $user->create( name => 'luser01', password => 'foo|34r1' );
is( $resp->isok, 1, "Created a user by passing the name to create") or diag( $resp->messages );

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       cn  => 'luser',
			       sn  => '01'
			     );
$resp = $user->create( password => 'foo|34r1' );
is( $resp->isok, 0, "Couldn't create a user without a DN") or diag( $resp->messages );

$resp = $user->create( dn  => "cn=luser01,ou=people,o=me,c=us", password => 'foo|34r1' );
is( $resp->isok, 1, "Created a user by passing the DN to create") or diag( $resp->messages );

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       sn  => '01'
			     );
$resp = $user->create( password => 'foo|34r1' );
is( $resp->isok, 1, "Created a user by parsing CN from DN") or diag( $resp->messages );

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "uid=luser01,ou=people,o=me,c=us",
			       sn  => '01'
			     );
$resp = $user->create( password => 'foo|34r1', groups => [qw/iv-admin/] );
is( $resp->isok, 0, "Couldn't created a user without a CN") or diag( $resp->messages );

$resp = $user->create( cn => 'luser01', password => 'foo|34r1' );
is( $resp->isok, 1, "Created a user by sending the CN to create") or diag( $resp->messages );

$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "uid=luser01,ou=people,o=me,c=us",
			       sn  => '01'
			     );
is( $user->exist, 1, "Found the user by dn and name") or diag( $resp->messages );

$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			     );
is( $user->exist, 1, "Found the user by name alone") or diag( $resp->messages );

$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       dn  => "uid=luser01,ou=people,o=me,c=us",
			     );
is( $user->exist, 1, "Found the user by DN alone") or diag( $resp->messages );

$resp = $user->create( password => 'foo|34r1' );
is( $resp->iswarning, 1, "Couldn't create the user twice") or diag( $resp->messages );

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       cn  => 'luser',
			     );
$resp = $user->create( password => 'foo|34r1' );
is( $resp->isok, 0, "Couldn't created a user without an SN") or diag( $resp->messages );

$resp = $user->create( sn => 'luser01', password => 'foo|34r1' );
is( $resp->isok, 1, "Created a user by sending the SN to create") or diag( $resp->messages );

$resp = $user->delete( registry => 1 );
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       cn  => 'luser',
			       sn  => '01',
			     );
$resp = $user->create(nopwdpolicy=>1);
is( $resp->isok, 1, "Created a user without a password") or diag( $resp->messages );

$resp = $user->password( 'ph34rm3!' );
is( $resp->isok, 1, "Set the luser's password") or diag( $resp->messages );

$resp = $user->password(password => 'b1tem321');
is( $resp->isok, 1, "Set the luser's password with a hash") or diag( $resp->messages );

$resp = $user->delete;
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       dn  => "cn=luser01,ou=people,o=me,c=us",
			       cn  => 'luser',
			       sn  => '01'
			     );
$resp = $user->userimport;
is( $resp->isok, 0, "Couldn't import a user without a name") or diag( $resp->messages );

$resp = $user->userimport( name => 'luser01' );
is( $resp->isok, 1, "Imported a user by passing the name to import") or diag( $resp->messages );

$resp = $user->delete;
$user = Tivoli::AccessManager::Admin::User->new( $pd,
			       name => 'luser01',
			       cn  => 'luser',
			       sn  => '01'
			     );
$resp = $user->userimport;
is( $resp->isok, 0, "Couldn't import a user without a DN") or diag( $resp->messages );

$resp = $user->userimport(dn => "cn=luser01,ou=people,o=me,c=us");
is( $resp->isok, 1, "Imported a user by passing the DN to import") or diag( $resp->messages );

$user = $resp->value;
$resp = $user->delete( 1 );
is($resp->isok,1,"Deleted a user with a single parameter");

$user = Tivoli::AccessManager::Admin::User->new($pd);
isa_ok($user, "Tivoli::AccessManager::Admin::User", 'Called new with no parameters');
$resp = $user->create( name => 'luser01',
		       cn  => 'luser',
		       sn  => '01',
		       dn  => "cn=luser01,ou=people,o=me,c=us",
		       sso => 1,
		       nopwdpolicy => 1,
		       groups => 'iv-admin',
		       password => 'ph34rm3!',
		     );
is($resp->isok,1,"Created a user sending all parameters");

print "\nTESTING group interfaces\n";
my ( @groups, @gnames );
for my $i ( 0 .. 4 ) {
    push @gnames, sprintf( "usrgrp%02d", $i );
    $resp = Tivoli::AccessManager::Admin::Group->create( $pd,
					name => $gnames[-1],
					dn => "cn=$gnames[-1],ou=groups,o=me,c=us",
				     );
    if ( $resp->isok ) {
	$groups[$i] = $resp->value;
    }
    else {
	pop @gnames;
    }
}
$resp = $user->groups( add => \@gnames );
is( $resp->isok, 1, "Added the user to groups by name" );

$resp = $user->groups;
is_deeply( [$resp->value], \@gnames, "Got the full membership list back" ) 
    or diag( $resp->messages, Dumper( $resp ) );

$resp = $user->groups( remove => \@gnames );
is( $resp->isok, 1, "Removed the user from groups by name" );

$resp = $user->groups;
is_deeply( [$resp->value], [], "Got a null membership list" ) 
    or diag( $resp->messages, Dumper( $resp ) );

$resp = $user->groups( add => \@groups );
is( $resp->isok, 1, "Added the user to groups by objects" );

$resp = $user->groups;
is_deeply( [$resp->value], \@gnames, "Got the full membership list back" ) 
    or diag( $resp->messages, Dumper( $resp ) );

$resp = $user->groups( remove => \@groups );
is( $resp->isok, 1, "Removed the user from groups by objects" );

$resp = $user->groups;
is_deeply( [$resp->value], [], "Got a null membership list" ) 
    or diag( $resp->messages, Dumper( $resp ) );

$resp = $user->groups( add => [qw/dne/] );
is($resp->iswarning, 1, "Warned about adding a user from a non-existent group");
like($resp->messages, qr/dne/, "Listed the bad group");

$resp = $user->groups( remove => [qw/dne/] );
is($resp->iswarning, 1, "Warned about removing a user from a non-existent group");
like($resp->messages, qr/dne/, "Listed the bad group");

# Clean up the groups
for my $grp ( @groups ) {
    $grp->delete( registry => 1 );
}

print "\nTESTING password policies\n";
my $death = time + 86400 * 10;

$resp = $user->accexpdate;
is($resp->isok, 1, "Got the current account expiration date: " . $resp->value);

$resp = $user->accexpdate( lifetime => $death );
is( $resp->value, $death, "Account expires in 10 days") or diag( $resp->messages );

$resp = $user->accexpdate( silly => 1 );
is( $resp->value, $death, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->accexpdate('unset');
is( $resp->value, 'unset', "Account expiration unset") or diag( $resp->messages );

$resp = $user->accexpdate('unlimited');
is( $resp->value, 'unlimited', "Account expiration unlimited") or diag( $resp->messages );

$resp = $user->disabletimeint;
is($resp->isok,1, "Disable policy currently set to: " . $resp->value);

$resp = $user->disabletimeint( seconds => 3600 );
is( $resp->value, 3600, "User will be locked out for 1 hour") or diag( $resp->messages );

$resp = $user->disabletimeint( silly => 1 );
is( $resp->value, 3600, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->disabletimeint( 'unset' );
is( $resp->value, 'unset', "Lock out is unset") or diag( $resp->messages );

$resp = $user->disabletimeint( 'disable' );
is( $resp->value, 'disable', "Account will be disabled") or diag( $resp->messages );

$resp = $user->maxlgnfails;
is($resp->isok, 1, "Current max login failures is: " . $resp->value);

$resp = $user->maxlgnfails( failures => 3 );
is( $resp->value, 3, "User gets three tries to login") or diag( $resp->messages );

$resp = $user->maxlgnfails( silly => 1000 );
is( $resp->value, 3, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->maxlgnfails( 'unset' );
is( $resp->value, 'unset', "No three strikes policy now");

$resp = $user->maxpwdage;
is($resp->isok, 1, "Current max password age is " . $resp->value);

$resp = $user->maxpwdage( seconds => 86400 * 5 );
is( $resp->value, 432000, "Password expires in 5 days") or diag( $resp->messages );

$resp = $user->maxpwdage( silly => 5 );
is( $resp->value, 432000, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->maxpwdage('unset');
is( $resp->value, 'unset', "No password expiration") or diag( $resp->messages );

$resp = $user->maxpwdrepchars;
is($resp->isok, 1, "Current max repeated chars is " . $resp->value);

$resp = $user->maxpwdrepchars( chars => 1 );
is( $resp->value, 1, "Password can have at most 1 repeated chars") or diag( $resp->messages );

$resp = $user->maxpwdrepchars( silly => 10000 );
is( $resp->value, 1, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->maxpwdrepchars( 'unset' );
is( $resp->value, 'unset', "Maximum repeated characters unset") or diag($resp->messages);

$resp = $user->minpwdalphas;
is($resp->isok, 1, "Current minimum alpha chars is " . $resp->value);

$resp = $user->minpwdalphas( chars => 4 );
is( $resp->value, 4, "Password must have at least 4 alpha chars") or diag($resp->messages);

$resp = $user->minpwdalphas( silly => 10000 );
is( $resp->value, 4, "Ignored a silly key") or diag($resp->messages);

$resp = $user->minpwdalphas( 'unset' );
is( $resp->value, 'unset', "Minimum alpha characters unset") or diag( $resp->messages );

$resp = $user->minpwdnonalphas;
is($resp->isok, 1, "Current max non-alpha chars is " . $resp->value);

$resp = $user->minpwdnonalphas( chars => 4 );
is( $resp->value, 4, "Password must have at least 4 nonalpha chars") or diag( $resp->messages );

$resp = $user->minpwdnonalphas( silly => 10000 );
is( $resp->value, 4, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->minpwdnonalphas( 'unset' );
is( $resp->value, 'unset', "Minimum nonalpha characters unset") or diag( $resp->messages );

$resp = $user->minpwdlen;
is($resp->isok, 1, "Current minimum password length is " . $resp->value);

$resp = $user->minpwdlen( chars => 10 );
is( $resp->value, 10, "Password must be 10 chars long") or diag( $resp->messages );

$resp = $user->minpwdlen( silly => 100 );
is( $resp->value, 10, "Ignored a silly hash key") or diag( $resp->messages );

$resp = $user->minpwdlen( 'unset' );
is( $resp->value, 'unset', "Minimum password length unset") or diag( $resp->messages );

$resp = $user->pwdspaces;
is($resp->isok, 1, "Spaces allowed in password policy is " . $resp->value);

$resp = $user->pwdspaces( allowed => 1 );
is( $resp->value,  1, "Password can contain spaces") or diag( $resp->messages );

$resp = $user->pwdspaces( silly => 0 );
is( $resp->value,  1, "Ignored a bad hash key") or diag( $resp->messages );

$resp = $user->pwdspaces( 'unset' );
is( $resp->value, 'unset', "Password spaces is unset") or diag( $resp->messages );

my $answer = { days => [qw/mon wed fri/], 
	      start => '0800', end => '1800',
              reference => 'local' };
my $unset  = { days => 0, 
	       start => 0, 
	       end => 0, 
	       reference => 'local', 
	       unset => 1 };

$resp = $user->tod;

$resp = $user->tod( days => [ qw/mon wed fri/ ],
                    start => '0800',
		    end   => '1800',
		    reference => 'local'
		  );
is_deeply(scalar($resp->value), $answer, "Setting TOD access" ) or diag( $resp->messages );

$resp = $user->tod( days => [ qw/mon wed fri/ ],
                    start => '0800',
		    end   => '1800',
		    reference => 'local',
		  );
is_deeply( scalar($resp->value), $answer, "Setting TOD access with default reference" ) or diag( $resp->messages );

$answer->{reference} = 'UTC';
$resp = $user->tod( %$answer );
is_deeply( scalar($resp->value), $answer, "Setting TOD access with UTC reference" ) or diag( $resp->messages );

$resp = $user->tod(days => 'unset');
is_deeply(scalar($resp->value), $unset, "TOD access unset");

$resp = $user->tod( days => 42,  # Thats funny!
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		  );
is_deeply(scalar($resp->value), $answer, "Set days as a bitmask");

$answer->{days} = [qw/any/];
$resp = $user->tod( days => [qw/any/],
		    start => '0800',
		    end   => '1800',
		    reference => 'UTC',
		  );
is_deeply(scalar($resp->value),$answer,"Set days to any");

$resp = $user->delete( registry => 1 );
is( $resp->isok, 1, "Cleaning up -- luser01 deleted") or diag( $resp->messages);

# Test the list function - create some users to search first
my (@users, @names);

print "\nTESTING list functions\n";
for my $i ( 0 .. 4 ) {
    my $name = sprintf "luser%02d", $i;
    push @names, $name;

    $resp = Tivoli::AccessManager::Admin::User->create( $pd, 
				       name     => $name,
				       dn       => "cn=$name,ou=people,o=me,c=us",
				       password => "Pa\$\$w0rd",
				       cn       => $name,
				       sn       => sprintf "%02d", $i);
    is($resp->isok, 1, "Created $name") or diag( $resp->messages );
    if ( $resp->isok ) {
	push @users, scalar($resp->value);
    }
}

# Test class method first
$resp = Tivoli::AccessManager::Admin::User->list( $pd, pattern => 'luser*' );
is_deeply( [$resp->value], \@names, "Found all the lusers by class" ) or diag( Dumper($resp->value) );

$resp = Tivoli::AccessManager::Admin::User->list( $pd, pattern => 'luser*', maxreturn => 1);
is( scalar($resp->value), 1, "Returned just one user");

$resp = Tivoli::AccessManager::Admin::User->list( $pd, maxreturn => 1);
is( scalar($resp->value), 1, "Returned just one user from a * search");

$resp = Tivoli::AccessManager::Admin::User->list( $pd, maxreturn => 1, bydn => 1);
is( scalar($resp->value), 1, "Returned just one user from a * DN search");

# Test this as an instance method.
$resp = $users[0]->list( pattern => 'luser*' );
is_deeply( [$resp->value], \@names, "Found all the lusers by method" ) or diag( Dumper($resp->value) );


print "\nTESTING gso\n";
$resp = $user->ssouser;
is($resp->isok,1,"The user's current GSO is " . $resp->value);

my $flip = $resp->value ? 0 : 1;
$resp = $user->ssouser( $flip );
is($resp->isok,1,"Changed ssouser to $flip");
is($resp->value,$flip,"And it worked");

$resp = $user->ssouser( silly => $flip ? 0 : 1 );
is($resp->value,$flip,"Ignored a silly hash key");

$resp = $user->ssouser( sso => $flip ? 0 : 1 );
is($resp->isok,1,"Changed ssouser using a hash");
is($resp->value,$flip ? 0 : 1,"And it worked");

print "\nCLEANING up\n";
for my $foo ( @users ) {
    $resp = $foo->delete( registry => 1 );
    is( $resp->isok, 1, "Deleting " . $foo->name ) or diag( $resp->messages );
}

print "\nTESTING brokeness\n";

$user = Tivoli::AccessManager::Admin::User->new(undef);
is($user, undef, "Couldn't send an undefined object to new");

$user = Tivoli::AccessManager::Admin::User->new($resp);
is($user, undef, "Couldn't send a non-context object to new");

$user = Tivoli::AccessManager::Admin::User->new($pd, qw/one two three/);
is($user, undef, "Couldn't send an odd number of parameters new");

$resp = Tivoli::AccessManager::Admin::User->create(undef);
is($resp->isok, 0, "Couldn't send an undefined object to create");

$resp = Tivoli::AccessManager::Admin::User->create($user);
is($resp->isok, 0, "Couldn't send a non-context object to create");

$resp = Tivoli::AccessManager::Admin::User->create($pd, qw/one two three/);
is($resp->isok, 0, "Couldn't send an odd number of parameters create");

$resp = Tivoli::AccessManager::Admin::User->create($resp, qw/one two three/);
is($resp->isok, 0, "Couldn't send an object that isn't a context");

$resp = Tivoli::AccessManager::Admin::User->create( $pd, 
				   name     => 'luser01',
				   dn       => "cn=luser01,ou=people,o=me,c=us",
				   password => "Pa\$\$w0rd",
				   cn       => 'luser01',
				   sn       => 'luser01',
				   groups   => { member => 'foo' },
			       );
is( $resp->isok, 0, "Could not pass a non-array ref to create");

$resp = Tivoli::AccessManager::Admin::User->create( $pd, 
				   name     => 'luser01',
				   dn       => "cn=luser01,ou=people,o=me,c=us",
				   password => "Pa\$\$w0rd",
				   cn       => 'luser01',
				   sn       => 'luser01',
			       );
$user = $resp->value;
$resp = $user->delete( qw/one two three/ );
is($resp->isok,0,"Could not call delete with an odd number of parameters");

$resp = $user->delete( foobar => 1 );
is($resp->isok,1,"Trash key ignored");

$resp = $user->delete();
is($resp->isok,0,"Could not delete a non-existant user");

$resp = Tivoli::AccessManager::Admin::User->userimport( $pd, 
				   name     => 'luser01',
				   dn       => "cn=luser01,ou=people,o=me,c=us",
			       );
is($resp->isok,1,"Imported user using class method");
$resp = $user->delete(1);

$resp = Tivoli::AccessManager::Admin::User->create( $pd, 
				   name     => 'luser01',
				   dn       => "cn=luser01,ou=people,o=me,c=us",
				   password => "Pa\$\$w0rd",
				   cn       => 'luser01',
				   sn       => 'luser01',
			       );
$user = $resp->value;

$resp = $user->accexpdate( qw/one two three/ );
is($resp->isok,0,"Could not call accexpdate with an odd number of parameters");

$resp = $user->disabletimeint( qw/one two three/ );
is($resp->isok,0,"Could not call disabletimeint with an odd number of parameters");

$resp = $user->maxlgnfails( qw/one two three/ );
is($resp->isok,0,"Could not call maxlgnfails with an odd number of parameters");

$resp = $user->maxpwdage( qw/one two three/ );
is($resp->isok,0,"Could not call maxpwdage with an odd number of parameters");

$resp = $user->maxpwdrepchars( qw/one two three/ );
is($resp->isok,0,"Could not call maxpwdrepchars with an odd number of parameters");

$resp = $user->minpwdalphas( qw/one two three/ );
is($resp->isok,0,"Could not call minpwdalphas with an odd number of parameters");

$resp = $user->minpwdnonalphas( qw/one two three/ );
is($resp->isok,0,"Could not call minpwdnonalphas with an odd number of parameters");

$resp = $user->minpwdlen( qw/one two three/ );
is($resp->isok,0,"Could not call minpwdlen with an odd number of parameters");

$resp = $user->pwdspaces( qw/one two three/ );
is($resp->isok,0,"Could not call pwdspaces with an odd number of parameters");

$resp = $user->tod( qw/one two three/ );
is($resp->isok,0,"Could not call tod with an odd number of parameters");

$resp = $user->tod( days => 256,
		    start => 800,
		    end   => 1800 );
is($resp->isok,0,"Could not call tod with an invalid days bitmask");

$resp = $user->userimport;
is( $resp->isok,0,"Could not import a user that already exists");

$resp = $user->groups(qw/one two three/);
is($resp->isok,0,"Could not call groups with an odd number of parameters");

$resp = $user->accountvalid(qw/one two three/);
is($resp->isok,0,"Could not call accountvalid with an odd number of parameters");

$resp = $user->passwordvalid(qw/one two three/);
is($resp->isok,0,"Could not call passwordvalid with an odd number of parameters");

$resp = $user->password( qw/one two three/);
is($resp->isok,0,"Could not call password with an odd number of parameters");

$resp = $user->password;
is($resp->isok,0,"Could not call password with an empty parameter list");

$resp = $user->ssouser(qw/one two three/);
is($resp->isok,0,"Could not call ssouser with an odd number of parameters");

$resp = $user->delete;
$resp = Tivoli::AccessManager::Admin::User->userimport( undef );
is( $resp->isok, 0, "Could not call userimport with an undefined context");

$resp = Tivoli::AccessManager::Admin::User->userimport( $user );
is( $resp->isok, 0, "Could not call userimport with an object that is not a context");

$resp = Tivoli::AccessManager::Admin::User->userimport( $pd, qw/one two three/ );
is( $resp->isok, 0, "Could not call userimport with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::User->userimport($pd, name => 'luser01');
is($resp->isok, 0, "Could not call userimport without a DN"); 

$resp = Tivoli::AccessManager::Admin::User->userimport($pd, dn => 'cn=luser01,ou=people,o=me,c=us');
is($resp->isok, 0, "Could not call userimport without a name"); 

$resp = Tivoli::AccessManager::Admin::User->userimport($pd, dn => 'cn=luser01,ou=people,o=me,c=us', name=>'luser01');
$user = $resp->value;
$resp = $user->userimport();
is($resp->isok,0,"Could not import an already existing user");

$resp = Tivoli::AccessManager::Admin::User->list(undef);
is($resp->isok, 0, "Could not pass undef to list");

$resp = Tivoli::AccessManager::Admin::User->list($user);
is($resp->isok, 0, "Could not pass a non-context object to list");

$resp = Tivoli::AccessManager::Admin::User->list($pd, qw/one two three/);
is($resp->isok, 0, "Could not pass an odd number of parameters to list"); 

$resp = $user->delete(1);
END {
    ReadMode 0;
}
