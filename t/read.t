use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Muskox');

$t->get_ok('/v1/oxen/all/names')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/all/names.html')
  ->status_is(200)
  ->header_is('Content-Type' => 'text/html;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/1/names')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/1/names.html')
  ->status_is(200)
  ->header_is('Content-Type' => 'text/html;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/all/positions')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/all/positions.html')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/1/positions')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

$t->get_ok('/v1/oxen/1/positions.html')
  ->status_is(200)
  ->header_is('Content-Type' => 'application/json;charset=UTF-8')
  ->content_like(qr/Mojolicious/i);

done_testing();
