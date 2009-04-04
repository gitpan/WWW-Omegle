package WWW::Omegle;

use 5.006000;
use strict;
use warnings;

use Carp qw/croak/;
use JSON;
use parent 'WWW::Mechanize';

our $VERSION = '0.01';

sub new {
    my ($class, %opts) = @_;

    my $chat_cb = delete $opts{on_chat};
    my $disconnect_cb = delete $opts{on_disconnect};
    my $connect_cb = delete $opts{on_connect};

    my $self = $class->SUPER::new(%opts);

    $self->{om_callbacks} = {
        chat => $chat_cb,
        connect => $connect_cb,
        disconnect => $disconnect_cb,
    };

    bless $self, $class;
    return $self;
}

sub start {
    my ($self) = @_;

    my $res = $self->post("http://omegle.com/start");
    return undef unless $res->is_success;

    my $res_body = $res->content || '';
    my ($id) = $res_body =~ /"(\w+)"/;
    return undef unless $id;

    $self->{om_id} = $id;
    return $id;
}

sub om_callback {
    my ($self, $callback, @extra) = @_;
    
    $callback = $self->{om_callbacks}->{$callback}
        or return;

    $callback->($self, @extra);
}

sub get_next_event {
    my ($self) = @_;

    return undef unless $self->{om_id};

    my $res = $self->post("http://omegle.com/events", { id => $self->{om_id} });
    return undef unless $res->is_success;
    
    my $json = new JSON;
    my $events = $json->decode($res->content)
        or return undef;

    return undef unless ref $events && ref $events eq 'ARRAY';

    foreach my $evt (@$events) {
        my $evt_name = $evt->[0]
            or next;
        if ($evt_name eq 'connected') {
            $self->om_callback('connect');
        } elsif ($evt_name eq 'gotMessage') {
            $self->om_callback('chat', $evt->[1]);
        } elsif ($evt_name eq 'strangerDisconnected') {
            $self->om_callback('disconnect');
            delete $self->{om_id};
        } elsif ($evt_name eq 'waiting') {
            
        } else {
            warn "Got unknown omegle event: $evt_name";
        }
    }

    return $events;
}

sub say {
    my ($self, $what) = @_;

    return undef unless $self->{om_id};

    my $res = $self->post("http://omegle.com/send", {
        id  => $self->{om_id},
        msg => $what,
    });

    return $res->is_success;
}

sub disconnect {
    my ($self) = @_;

    return undef unless $self->{om_id};

    my $res = $self->post("http://omegle.com/disconnect", {
        id  => $self->{om_id},
    });

    return $res->is_success;
}    

1;

__END__


=head1 NAME

WWW::Omegle - Perl interface www.omegle.com

=head1 SYNOPSIS

  use WWW::Omegle;
  my $ombot = WWW::Omegle->new(
                             on_connect    => \&connect_cb,
                             on_chat       => \&chat_cb,
                             on_disconnect => \&disconnect_cb,
                             );

  $ombot->start;
  while ($ombot->get_next_event) { 1; }
  exit;

  sub connect_cb {
    my ($om) = @_;
    print "Connected\n";
    $om->say('u sux');
  }

  sub chat_cb {
    my ($om, $what) = @_;
    print ">> $what\n";
  }

  sub disconnect_cb {
    my ($om) = @_;
    print "Disconnected.\n";
  }


=head1 DESCRIPTION

This is a perl interface to the backend API for www.omegle.com. This
module lets you easily script chating with random, anonymous people
around the world. Note that this uses an unofficial API and is subject
to breakage if the site author chooses to change their interface.

=head2 EXPORT

None by default.


=head1 METHODS

=over 4

=item new(%opts)

Construct a new Omeglebot. Supported options are
on_chat, on_disconnect and on_connect, which must be coderefs. See
synopsis for usage examples.
Other %opts are passed to the WWW::Mechanize constructor

=item start

Begins a chat with a random stranger. Returns success/failure.

=item say($message)

Says something to your chat buddy. Returns success/failure

=item disconnect

Terminates your conversation.

=item get_next_event

Fetches the next event and dispatches to the appropriate callback. See
synopsis.

=back

=head1 SEE ALSO

WWW::Mechanize

=head1 AUTHOR

Mischa Spiegelmock, E<lt>revmischa@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
