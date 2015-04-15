package WI::Main::Role::CommonEvent;
use Moo::Role;

before 'connect' => sub {
    my $self = shift;
    my $args = shift;
    my $user = $self
        ->_ref_main
        ->db
        ->user
        ->find_or_create({username => $args->{ nick }})
        ;
    $user->set({ status => 'online' });
    $args->{ status } = 'online';
};

before 'disconnect' => sub {
    my $self = shift;
    my $args = shift;
    my $user = $self
        ->_ref_main
        ->db
        ->user
        ->find_or_create({username => $args->{ nick }})
        ;
    $user->set({ status => 'offline', last_status => $user->status });
    $args->{ status } = 'offline';
};

before 'part' => sub {
    my $self = shift;
    my $args = shift;
#   my $user  
    use DDP;
    warn p $args;
    warn "^^ ARGS PART";
#   {
#       action    "part",
#       channel   "#some_chan_forced",
#       nick      "teste",
#       source    "web"
#   } at /home/administrator/perl/WI-V3/WI-Main/scripts/../lib/WI/Main/Role/CommonEvent.pm line 35.
    #load user
    my $user = $self
        ->_ref_main
        ->db
        ->user
        ->find_or_create({username => $args->{ nick }})
        ;

    my $channel = $self
        ->_ref_main
        ->db
        ->channel
        ->find_or_create({name => $args->{channel}})
        ;

    $self->_ref_main->db->user_channel->_part( $user, $channel, $args->{source} );
};

1;
