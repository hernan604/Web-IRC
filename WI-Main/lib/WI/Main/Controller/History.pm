package WI::Main::Controller::History;
use base 'Mojolicious::Controller';
use DDP;

sub private_message {
    my $self = shift;
    my $from = $self->req->json->{ from };
    my $to   = $self->req->json->{ to };

    my $from_user = $self->db->user->find({ username => $from });
    my $to_user = $self->db->user->find({ username => $to });

#   my $log = $self->db->user->private_message_log->search({
#       -or => [
#           -and => [
#               from_user_id => $from_user->id,
#               to_user_id   => $to_user->id,
#           ],
#           -and => [
#               from_user_id => $to_user->id,
#               to_user_id   => $from_user->id,
#           ],
#       ]
#   },
#   {
#       -asc => [ 'created' ]
#   });
    # select "from".username as "from", "to".username as "to", log.line, log.created, log.id from "PrivateMessageLog" as log left join "User" as "from" on log.from_user_id="from".id left join "User" as "to" on log.to_user_id="to".id where ( log.from_user_id = 153 and log.to_user_id = 154 ) or ( log.from_user_id = 154 and log.to_user_id = 153 ) order by log.created asc;

    my $results = $self->db->pg->db->query( <<QUERY, $from_user->id, $to_user->id, $to_user->id, $from_user->id );
SELECT 
    "from".username                 AS "from",
    "to".username                   AS "to",
    log.line                        AS "line",
    log.created                     AS "created",
    log.id from "PrivateMessageLog" AS log
    LEFT JOIN "User"                AS "from" ON log.from_user_id="from".id
    LEFT JOIN "User"                AS "to"   ON log.to_user_id="to".id
    WHERE   ( log.from_user_id = ? AND log.to_user_id = ? )
    OR      ( log.from_user_id = ? AND log.to_user_id = ? )
    ORDER BY log.created asc
QUERY

    $self->respond_to( json => sub {
        my $self = shift;
        $self->render( json => {
            status  => 'OK',
            results => $results->hashes->to_array
        } );
    } );
}

1;
