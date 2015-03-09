use Test::More;

use WI::DB;
my $db = WI::DB->new(
    dsn                 => $ENV{WI_MOJO_PG_DSN},
    filepath_migrations => './migrations.sql',
);
$db->migrate;
ok( defined $db, '' );

$db->cleanup;

# REGISTRATION
my $new_user = {
    username => 'test_user',
    password => 'test_pass',
    email    => 'test@example.com',
};
my $avaliable = $db->registration->is_avaliable( $new_user );
ok( $avaliable , 'username avaliable for registration' );
my $success;
if ( $avaliable ) {
    $success = $db->registration->register( $new_user );
}
ok( $success, 'registered user successfully' );
ok( !$db->registration->is_avaliable( $new_user ) , 'username not available' );



done_testing;
