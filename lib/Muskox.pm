package Muskox;
use Mojo::Base 'Mojolicious';
use Muskox::Schema;

sub startup {
  my $self = shift;

  # load configuration file and set app secret and port
  my $config = $self->plugin('Config');
  $self->secrets([$config->{secret}]);
  $self->config(hypnotoad => {listen => ['http://*:' . $config->{listen}]});

  # register app commands
  push @{$self->commands->namespaces}, 'Muskox::Command';

  # setup database connection and make it available to
  my $dsn = 'dbi:mysql:' . $config->{db_name};
  my $schema = Muskox::Schema->connect($dsn, $config->{db_user}, $config->{db_pass});
  $self->helper(db => sub { return $schema; });

  # init routes
  my $r = $self->routes;

  $r->route('/')->via('GET')->to('position#front');

  $r->route('/v1/oxen/all/names', format => [qw(json)])
    ->via('GET')
    ->to('position#names');

  $r->route('/v1/oxen/:animal/positions/points', animal => qr/all|[\w\d]{4}-\d{4}/, format => [qw(json)])
    ->via('GET')
    ->to('position#points');

  $r->route('/v1/oxen/:animal/positions/lines', animal => qr/all|[\w\d]{4}-\d{4}/, format => [qw(json)])
    ->via('GET')
    ->to('position#lines');

  $r->route('/v1/oxen')->via('POST')->to('position#create');
}

1;
