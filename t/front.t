use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Muskox');

$t->get_ok('/')
  ->status_is(200)
  ->header_is('Content-Type' => 'text/html;charset=UTF-8')
  ->text_is('title' => 'Muskox');

done_testing();
