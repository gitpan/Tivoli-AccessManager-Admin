package Tivoli::AccessManager::Admin::User;

use strict;
use vars qw($AUTOLOAD);
our @ISA = qw(Tivoli::AccessManager::Admin);

sub new {
        my $self = {};
        bless $self, shift;
        $self->_init(@_);
        return $self;
}

sub _init {
        my $self = shift;
        $self->{'_context'} = shift;
        $self->{'_id'} = shift;
	my($user,$rsp);
	Tivoli::AccessManager::Admin::ivadmin_user_get($self->{'_context'}, $self->{'_id'}, $user, $rsp);
	$self->{'_rsp'} = $rsp;
        $self->{'_object'} = $user;
        return;
}

sub cn {
	my $self = shift;
	return Tivoli::AccessManager::Admin::ivadmin_user_getcn( $self->{'_object'});
}

sub sn {
	my $self = shift;
	return Tivoli::AccessManager::Admin::ivadmin_user_getsn( $self->{'_object'});
}

sub dn {
	my $self = shift;
	return Tivoli::AccessManager::Admin::ivadmin_user_getdn( $self->{'_object'});
}

sub id {
	my $self = shift;
	return Tivoli::AccessManager::Admin::ivadmin_user_getid(
		$self->{'_object'});
}

sub description {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		Tivoli::AccessManager::Admin::ivadmin_user_setdescription(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return Tivoli::AccessManager::Admin::ivadmin_user_getdescription(
		$self->{'_object'});
}

sub valid {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		Tivoli::AccessManager::Admin::ivadmin_user_setaccountvalid(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return Tivoli::AccessManager::Admin::ivadmin_user_getaccountvalid(
		$self->{'_object'});
}
	
sub gso {
	my $self = shift;
	if ( @_ ) {
		my $rsp;
		Tivoli::AccessManager::Admin::ivadmin_user_setssouser(
			$self->{'_context'}, $self->{'_id'}, shift, $rsp);
		$self->{'_rsp'} = $rsp;
	}
	return Tivoli::AccessManager::Admin::ivadmin_user_getssouser(
		$self->{'_object'});
}

sub delete {
	my $self = shift;
	return $self->delete_user($self->{'_id'});
}

sub remove {
	my $self = shift;
	return $self->remove_user($self->{'_id'});
}

1;

__END__
# Below is stub documentation for the module.

=head1 NAME

Tivoli::AccessManager::Admin::User - Perl extension for TAM Admin API

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin;

  # Connect to the policy server as sec_master
  my $pdadmin = Tivoli::AccessManager::Admin->new('sec_master', 'password');

  # Get the user with the ID joe and print basic information
  my $user = $pdadmin->get_user('joe');
  print 'Login ID: ', $user->id, "\n";
  print 'Login CN: ', $user->cn, "\n";
  print 'Login DN: ', $user->dn, "\n";

  if ( $user->valid ) {
	print "User account valid.\n";
  } else {
  	# Make the user account valid
  	$user->valid(1);
  }

  # Make the user a Non-GSO user
  $user->gso(0);

=head1 DESCRIPTION

Tivoli::AccessManager::Admin::User is a support module for the Tivoli::AccessManager::Admin module.

=head1 METHODS

=head2 id

Return the TAM ID of the user.

=head2 cn

Return the LDAP CN of the user.

=head2 sn

Return the LDAP SN of the user.

=head2 dn

Returns the LDAP DN of the user.

=head2 description(<description>)

Return the current description of the user.  The method will set the description to the value of the first parameter, if passed.

=head2 valid(<valid>)

Returns true if the account is currently valid.  The method will also set the account validity of the user if 1 (valid) or 0 (invalid) is passed as an argument.

=head2 gso(<valid>)

Returns true if the account is a GSO user.  The method will also set the GSO state of the user if 1 (GSO user) or 0 (non-GSO user) is passed as an argument.

=head2 remove

Remove the user from TAM only.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete <userid>

=head2 delete

Remove the user from TAM and LDAP.  This method is equivalent to the following pdadmin command.

   pdadmin> user delete -registry <userid>

=head2 ok

Returns true if the last action was successful.

=head2 error

Returns true if the last action was unsuccessful.

=head2 message([<index>])

Returns the error message for the last action. The index will specify which error message to return if the last action resulted in more that one error condition. The index is 0 based.

=head2 code([<index>])

Returns the error code for the last action. The index will specify which error code to return if the last ction resulted in more that one error condition.  The index is 0 based.

=head1 msg_count 

Returns the number of errors generated for the last action.

=head1 AUTHOR

George Chlipala, george@walnutcs.com

=head1 SEE ALSO

perl(1).

=cut

