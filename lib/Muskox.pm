package Muskox;
use Mojo::Base 'Mojolicious';
use Muskox::Schema;

sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');
  $self->secrets([$config->{secret}]);
  $self->config(hypnotoad => {listen => ['http://*:' . $config->{listen}]});

  push @{$self->commands->namespaces}, 'Muskox::Command';

  my $dsn = 'dbi:mysql:' . $config->{db_name};
  my $schema = Muskox::Schema->connect($dsn, $config->{db_user}, $config->{db_pass});
  $self->helper(db => sub { return $schema; });

  # init routes
  my $r = $self->routes;

  $r->route('/')->via('GET')->to('position#front');

  $r->route('/v1/oxen/all/names', format => [qw(html json)])
    ->via('GET')
    ->to('position#names');
  
  $r->route('/v1/oxen/:animal/positions/points', animal => qr/all|[\w\d]{4}-\d{4}/, format => [qw(json)])
    ->via('GET')
    ->to('position#points');

  $r->route('/v1/oxen/:animal/positions/lines', animal => qr/[\w\d]{4}-\d{4}/, format => [qw(json)])
    ->via('GET')
    ->to('position#lines');

  $r->route('/v1/oxen/interpolate')->via('GET')->to('position#interpolate');

  $r->route('/v1/oxen')->via('POST')->to('position#create');
}

1;
