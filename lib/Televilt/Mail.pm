package Televilt::Mail;

use Carp;
use Exporter 'import';
use Modern::Perl;

our @EXPORT_OK = qw(parse_subject parse_body);

# precompile re's for validating position fields
our @validate = (
  qr/^\d{4}-\d{2}-\d{2}$/,
  qr/^\d{2}:\d{2}:\d{2}$/,
  qr/^\d+$/,
  qr/^\d+$/,
  qr/^\d+$/,
  qr/^\d{2}\w$/,
  qr/^\d+$/,
  qr/^2D$|^3D$/,
  qr/^-*\d+$/,
  qr/^\d+\.\d+$/,
  qr/^\d+$/,
  qr/^\d+$/,
  qr/^\d+$/,
);

our @column = (
  'animal_id',
  'recorded',
  'ttf',
  'northing',
  'easting',
  'zone',
  'sat_count',
  'fix',
  'altitude',
  'h_dop',
  'temperature',
  'x',
  'y',
  'status',
);

sub parse_subject {
  my $data = shift;

  # match collar ids on the form T5HS-4035
  my ($id) = $data =~ /([\w\d]{4}-\d{4})/;

  return $id;
}

sub parse_body {
  my $data = shift;
  my @rows = ();

  open my $fh, '<', \$data;
  while (<$fh>) {
    chomp;
    next unless /^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+/;

    my @fields = split /\s+/;
    my @parsed = ();

    my $last = (/GPS Time Out/ or /Mortality/) ? 1 : $#fields;
    for my $i (0 .. $last) {
      if ($fields[$i] =~ /$validate[$i]/) {
        $parsed[$i] = $fields[$i];
      }
      else {
        carp("Unable to parse field #$i ($column[$i]): $fields[$i]");
      }
    }

    my %row = (
      'recorded' => $parsed[0] . ' ' . $parsed[1],
    );

    if (/GPS Time Out/) {
      $row{'status'} = 'gps timeout';
      ($row{'temperature'}) = $_ =~ /(\d+)\s+0\s+0\s*$/;
    }
    if (/Mortality/) {
      $row{'status'} = 'mortality';
      ($row{'temperature'}) = $_ =~ /Mortality\s+(\d+)/;
    }

    for my $i (2 .. $#fields) {
      if ($parsed[$i]) {
        $row{$column[$i]} = $parsed[$i];
      }
    }

    push @rows, \%row;
  }
  close $fh;

  return @rows;
}

1;
