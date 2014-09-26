package Muskox::Command::import;
use Mojo::Base 'Mojolicious::Command';

use Encode;
use Encode::Guess;
use File::Copy;
use File::Spec;
use Geo::Coordinates::UTM;
use OLE::Storage_Lite;
use Televilt::Mail qw(parse_body parse_subject);

our $VERSION = '1.00';

has description => 'Import data.';
has usage => "Usage: muskox import COUNT INPUT_DIR DONE_DIR\n";

sub run {
  my ($self, @args) = @_;

  my $files_to_process = shift @args;
  my $input_dir = shift @args;
  my $output_dir = shift @args;

  opendir my ($dh), $input_dir;

  my $count = 0;
  while (my $entry = readdir $dh) {
    next if $entry =~ /^\./;

    my $source = File::Spec->catfile($input_dir, $entry);

    my $ole = OLE::Storage_Lite->new($source);
    my $pps = $ole->getPpsTree(1);

    my $raw_subject = $self->_get_ole_field($pps, '0_0037');
    my $raw_body = $self->_get_ole_field($pps, '0_1000');

    if ($raw_body =~ /Lat\s+Long/g) {
      $raw_body = $self->_convert_old_format($raw_body);
    }
    if ($raw_body =~ /942420/g) {
      my @lines = split /\n/, $raw_body;
      my @keep = ();
      foreach my $line (@lines) {
        push @keep, $line unless $line =~ /942420/;
      }
      $raw_body = join "\n", @keep;
    }

    my $animal_id = parse_subject($raw_subject);
    my @rows = parse_body($raw_body);

    @rows = map { $_->{animal_id} = $animal_id; $_ } @rows;
    $self->_add_to_database(\@rows);

    # move processed file to "done" directory
    # my $target = File::Spec->catfile($output_dir, $entry);
    # copy($source, $target);

    $count++;
    last if $count == $files_to_process;
  }

  closedir $dh;

  say "Processed $count files";
}

sub _add_to_database {
  my $self = shift;
  my $rows = shift;

  foreach my $row (@$rows) {
    my $rec = $self->app->db->resultset('Position')->find_or_new($row, {key => 'animal_time'});
    my $key = $row->{'animal_id'} . ' ' . $row->{'recorded'};

    if (!$rec->in_storage) {
      $rec->insert;
      say 'Added position    : ' . $key;
    }
    else {
      say 'Duplicate position: ' . $key;
    }
  }
}

sub _get_ole_field {
  my $self = shift;
  my $pps = shift;
  my $field = shift;

  foreach my $child (@{$pps->{Child}}) {
    my $name = OLE::Storage_Lite::Ucs2Asc($child->{Name});
    if ($name =~ /$field/) {
      return decode('Guess', $child->{Data});
    }
  }
}

sub _convert_old_format {
  my $self = shift;
  my $body = shift;

  my @lines = split /\n/, $body;

  foreach (@lines) {
    next if (/GPS Time Out/ or /Mortality/);
    my $fields = split /\s+/;

    if ($fields > 10) {
      my @fields = split /\s+/;

      my ($zone, $east, $north);
      if ($fields[0] ne 'Date') {
        ($zone, $east, $north) = latlon_to_utm(23, $fields[3], $fields[4]);

        $fields[3] = int($north);
        $fields[4] = int($east);
      }

      my $splice = $fields[0] eq 'Date' ? 'Zone' : $zone;
      splice @fields, 5, 0, ($splice);

      $_ = join "   ", @fields;
    }
  }

  return join "\n", @lines;
}

1;

__END__

=encoding utf8

=head1 NAME

Muskox::Command::import - Mojolicious command to import historic data

=head1 SYNOPSIS

  muskox import INPUT_DIR DONE_DIR

=head1 DESCRIPTION

L<Mojolicious::Command::import> is a L<Mojolicious> command. It imports historic data to the active database.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
