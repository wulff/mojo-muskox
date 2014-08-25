package Muskox::Position;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);
use Geo::Coordinates::UTM;

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
  qr/^\d+$/,
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

sub front {
  my $self = shift;
  $self->render();
}

sub create {
  my $self = shift;
  my $post = decode_json($self->req->body);

  # grab subject and message body from POST

  my $subject = $post->{'Subject'};
  my $body = $post->{'TextBody'};

  # parse message subject

  my ($animal_id) = $subject =~ /Tellus data from: ([\w\d]{4}-\d{4})/;

  # parse message body

  my @rows = ();

  open BODY, '<', \$body;
  LINE: while (<BODY>) {
    chomp;
    next unless /^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+/;

    my @fields = split /\s+/;

    for my $i (0 .. $#fields) {
      if ($fields[$i] !~ /$validate[$i]/) {
        $fields[$i] = '';
        $self->app->log->error("Unable to parse field #$i: $fields[$i]");
      }
    }

    $fields[5] = '27X' unless $fields[5];

    my %row = (
      'animal_id' => $animal_id,
      'recorded' => $fields[0] . ' ' . $fields[1],
    );

    if (/GPS Time Out/) {
      $row{'status'} = 'gps timeout';
      $self->app->log->info('GPS timeout: ' . $fields[0] . ' ' . $fields[1]);
    }
    if (/Mortality/) {
      $row{'status'} = 'mortality';
      $self->app->log->info('Mortality: ' . $fields[0] . ' ' . $fields[1]);
    }

    for my $i (2..12) {
      if ($fields[$i]) {
        $row{$column[$i]} = $fields[$i];
      }
    }

    push @rows, \%row;
  }
  close BODY;

  if (@rows) {
    foreach my $row (@rows) {
      $self->db->resultset('Position')->create($row);
    }
    $self->render(json => {status => 'OK', message => 'Positions added to the database.'}, status => 201);
  }
  else {
    $self->render(json => {status => 'ERROR', message => 'Unable to parse e-mail. See log for details.'}, status => 201);
  }
}

sub interpolate {

}

sub names {
  my $self = shift;

  my $animals = $self->db->resultset('Position')->search(
    {},
    { columns => [ qw/animal_id/ ], group_by => [ qw/animal_id/ ] }
  );

  my @animals;
  while (my $row = $animals->next) {
    push @animals, $row->animal_id;
  }

  if ($self->stash('format') eq 'html') {
    $self->render('position/names', animals => [@animals]);
  }
  else {
    $self->render(json => \@animals);
  }
}

sub points {
  my $self = shift;
  my $geojson = {
    type => 'FeatureCollection',
    features => [],
  };

  my $search = {};
  if ($self->stash('animal') ne 'all') {
    $search->{animal_id} = $self->stash('animal');
  }

  my $cursor = $self->db->resultset('Position')->search(
    $search,
    { columns => [ qw/animal_id recorded northing easting zone sat_count fix altitude h_dop temperature/ ],
      order_by => { '-desc' => ['recorded'] },
      rows => 10,
    }
  );

  while (my $row = $cursor->next) {
    if ($row->easting > 0 and $row->northing) {
      my ($latitude, $longitude) = utm_to_latlon(23, $row->zone, $row->easting, $row->northing);

      my $feature = {
        type => 'Feature',
        geometry => {
          type => 'Point',
          coordinates => [$longitude, $latitude],
        },
        properties => {
          animal_id => $row->animal_id,
          recorded => $row->recorded,
          sat_count => $row->sat_count,
          fix => $row->fix,
          altitude => $row->altitude,
          temperature => $row->temperature,
        }
      };

      push @{$geojson->{features}}, $feature;
    }
  }

  $self->render(json => $geojson);
}

sub lines {
  my $self = shift;

  my $cursor = $self->db->resultset('Position')->search(
    { animal_id => $self->stash('animal') },
    { columns => [ qw/animal_id northing easting zone/ ],
      order_by => { '-desc' => ['recorded'] },
      rows => 10,
    }
  );

  my $positions = [];
  while (my $row = $cursor->next) {
    if ($row->easting > 0 and $row->northing) {
      my ($latitude, $longitude) = utm_to_latlon(23, $row->zone, $row->easting, $row->northing);
      push @$positions, [$longitude, $latitude];
    }
  }

  my $geojson = {
    type => 'FeatureCollection',
    features => [{
      type => 'Feature',
      geometry => {
        type => 'LineString',
        coordinates => $positions,
      },
      properties => {
        animal_id => $self->stash('animal'),
      },
    }],
  };

  $self->render(json => $geojson);
}

1;
