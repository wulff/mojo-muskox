package Muskox::Command::deploy;
use Mojo::Base 'Mojolicious::Command';

our $VERSION = '1.00';

has description => 'Deploy application.';
has usage => "Usage: muskox deploy\n";

sub run {
  my ($self, @args) = @_;

  # for my $source_name ( $self->app->db->sources )

  eval { $self->app->db->resultset('Position')->count };
  if ($@) {
    $self->app->db->deploy();
    say 'The database schema has been deployed.';
  }
  else {
    say 'The database schema has already been deployed.';
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Muskox::Command::deploy - Mojolicious command to deploy a database schema

=head1 SYNOPSIS

  muskox deploy

=head1 DESCRIPTION

L<Mojolicious::Command::deploy> is a L<Mojolicious> command. It creates all necessary tables in the active database.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
