package Tivoli::AccessManager::Admin::Server;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Tivoli::AccessManager::Admin::Response;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Server.pm 309 2006-09-28 20:33:29Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::Server::VERSION = '1.00';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lpdmgrapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.00',
		NAME => 'Tivoli::AccessManager::Admin::Server',
	   );

sub new {
    my $class = shift;
    my $cont = shift;
    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    my $self  = bless {}, $class;
    my %opts  = @_;

    $self->{context} = $cont;
    $self->{name}    = $opts{name} || '';
    $self->{type}    = $opts{type} || 0;
    $self->{desc}    = $opts{description} || '';

    return $self;
}

sub tasklist {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ($self->{name}) {
	$resp->set_message("Unnamed servers cannot list tasks");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->server_gettasklist($resp);
    $resp->isok() && $resp->set_value($rc);

    return $resp;
}

sub task {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $task = '';

    unless ($self->{name}) {
	$resp->set_message("Unnamed servers cannot perform tasks");
	$resp->set_isok(0);
	return $resp;
    }
    
    if (@_ == 1) {
	$task = shift;
    }
    elsif (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$task = $opts{task} || '';
    }

    if ($task) {
	my $rc = $self->server_performtask($resp,$task);
	$resp->set_value(split("\n",$rc)) if $resp->isok;
    }
    return $resp;
}

# This is a kludge, because IBM won't expose the real calls via the C API.
# They did for java, but not C.  Bastards
sub list {
    my $class = shift;
    my ($tam,$grp,@list);
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    # I want this to be called as either Tivoli::AccessManager::Admin::User->list or
    # $self->list
    if ( ref($class) ) {
	$tam = $class->{context};
    }
    else {
	$tam = shift;
	unless ( defined($tam) and UNIVERSAL::isa($tam,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    $grp = Tivoli::AccessManager::Admin::Group->new( $tam, name => 'remote-acl-users' );
    $resp = $grp->members;
    return $resp unless $resp->isok;

    for ( $resp->value ) {
	next unless s#/#-#;
	push @list, $_;
    }

    $resp = Tivoli::AccessManager::Admin::Response->new;
    $resp->set_value(\@list);

    return $resp;
}


1;

__DATA__
__C__

#include "ivadminapi.h"
#include "ogauthzn.h"
#include "aznutils.h"

ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL ) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return rsp;
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL )
	croak("Couldn't get context");

    return (ivadmin_context*)SvIV(SvRV(*fetched));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return(fetched ? SvPV_nolen(*fetched) : NULL);
}

SV* server_gettasklist(SV* self, SV* resp) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char *server = _getname(self);
    

    azn_attrlist_h_t* outdata = NULL;
    unsigned long tcount = 0;
    char**        tasks;
    unsigned long rcount = 0;
    char**        results;
    unsigned long rc;
    unsigned long i;

    HV* rhash = newHV();
    AV* array;

    rc = ivadmin_server_gettasklist( *ctx,
				      server,
				      NULL,
				      &tcount,
				      &tasks,
				      outdata,
				      &rcount,
				      &results,
				      rsp );
    if ( rc == IVADMIN_TRUE ) {
	if ( tcount ) {
	    array = newAV();
	    for(i=0;i<tcount;i++){
		av_push( array, newSVpv(tasks[i],0) );
		ivadmin_free(tasks[i]);
	    }
	    hv_store( rhash, "tasks", 5, (SV*)newRV_noinc((SV*)array),0);
	}

	if ( rcount ) {
	    array = newAV();
	    for(i=0;i<rcount;i++){
		av_push( array, newSVpv(results[i],0) );
		ivadmin_free(results[i]);
	    }
	    hv_store( rhash, "messages", 8, newRV_noinc((SV*)array),0);
	}
    }

    return newRV_noinc( (SV*)rhash );
}

void server_performtask( SV* self, SV* resp, char* task ) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* server = _getname(self);

    azn_attrlist_h_t* outdata = NULL;
    unsigned long rcount = 0;
    char**        results;
    unsigned long rc;
    unsigned long i;

    if (server == NULL)
	croak("server_performtask: could not get server name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_server_performtask( *ctx,
				      server,
				      task,
				      NULL,
				      outdata,
				      &rcount,
				      &results,
				      rsp );
    if (rc == IVADMIN_TRUE) {
	for(i=0;i<rcount;i++){
	    Inline_Stack_Push(sv_2mortal(newSVpv(results[i],0))); 
	    ivadmin_free(results[i]);
	}
    }

    Inline_Stack_Done;
}

