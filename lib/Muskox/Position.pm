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

# render the front page map
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

sub names {
  my $self = shift;

  # TODO: return more info on each animal for use on a /names.html page (e.g. last reported position)

  my $animals = $self->db->resultset('Position')->search(
    {},
    { columns => [ qw/animal_id/ ], group_by => [ qw/animal_id/ ] }
  );

  my @animals;
  while (my $row = $animals->next) {
    push @animals, $row->animal_id;
  }

  $self->render(json => \@animals);
}

sub points {
  my $self = shift;

  my $count = $self->param('count');
  $count = 0 unless $count && $count =~ /\d+/;

  my $cursor;
  if ($self->stash('animal') eq 'all' and $count != 0) {
    $cursor = $self->db->resultset('PositionGroup')->search(
      {},
      { bind => [$count], }
    );
  }
  else {
    my $search = {};
    if ($self->stash('animal') ne 'all') {
      $search->{animal_id} = $self->stash('animal');
    }

    my $options = {
      order_by => [ { '-asc' => ['animal_id']}, {'-desc' => ['recorded']} ],
    };
    if ($count > 0) {
      $options->{rows} = $count;
    }

    $cursor = $self->db->resultset('Position')->search($search, $options);
  }

  my $points = [];
  while (my $row = $cursor->next) {
    my $point = {};
    foreach my $column (@column) {
      $point->{$column} = $row->$column;
    }
    $self->_fix_point($point);
    push @$points, $point;
  }

  # TODO: perform some interpolation magic

  my $geojson = $self->_render_points($points);
  $self->render(json => $geojson);
}

sub _render_points {
  my $self = shift;
  my $points = shift;

  my $geojson = {
    type => 'FeatureCollection',
    features => [],
  };

  foreach my $point (@$points) {
    my ($latitude, $longitude) = utm_to_latlon(23, $point->{zone}, $point->{easting}, $point->{northing});

    my $feature = {
      type => 'Feature',
      geometry => {
        type => 'Point',
        coordinates => [$longitude, $latitude],
      },
      properties => {
        animal_id => $point->{animal_id},
        recorded => $point->{recorded},
        sat_count => $point->{sat_count},
        fix => $point->{fix},
        altitude => $point->{altitude},
        temperature => $point->{temperature},
        northing => $point->{northing},
        easting => $point->{easting},
        interpolated => $point->{interpolated},
      }
    };

    push @{$geojson->{features}}, $feature;
  }

  return $geojson;
}

sub lines {
  my $self = shift;

  my $count = $self->param('count');
  $count += $count && $count =~ /\d+/ ? 1 : 0;

  my $cursor;
  if ($self->stash('animal') eq 'all' and $count != 0) {
    $cursor = $self->db->resultset('PositionGroup')->search(
      {},
      { bind => [$count], }
    );
  }
  else {
    my $search = {};
    if ($self->stash('animal') ne 'all') {
      $search->{animal_id} = $self->stash('animal');
    }

    my $options = {
      order_by => [ { '-asc' => ['animal_id']}, {'-desc' => ['recorded']} ],
    };
    if ($count > 0) {
      $options->{rows} = $count;
    }

    $cursor = $self->db->resultset('Position')->search($search, $options);
  }

  my $lines = {};
  while (my $row = $cursor->next) {
    my $point = {};
    foreach my $column (@column) {
      $point->{$column} = $row->$column;
    }
    push @{$lines->{$row->animal_id}}, $point;
  }

  my $geojson = $self->_render_lines($lines);
  $self->render(json => $geojson);
}

sub _render_lines {
  my $self = shift;
  my $lines = shift;

  my $geojson = {
    type => 'FeatureCollection',
    features => [],
  };

  foreach my $animal_id (keys %$lines) {
    my $positions = [];
    foreach my $pos (@{$lines->{$animal_id}}) {
      my ($latitude, $longitude) = utm_to_latlon(23, $pos->{zone}, $pos->{easting}, $pos->{northing});
      push @$positions, [$longitude, $latitude, $pos->{easting}, $pos->{northing}];
    }

    $self->_interpolate($positions);

    my $feature = {
      type => 'Feature',
      geometry => {
        type => 'LineString',
        coordinates => $positions,
      },
      properties => {
        animal_id => $animal_id,
      },
    };

    push @{$geojson->{features}}, $feature if $#{$positions} > 0;
  }

  return $geojson;
}

sub _interpolate {
  my $self = shift;
  my $positions = shift;

  my $last = @$positions - 1;

  my $right = 0;
  for my $left (0 .. $last) {
    if ($positions->[$left]->[2] == 0 and $positions->[$left]->[3] == 0) {
      $right = $left;
      while ($positions->[$right]->[2] == 0 and $positions->[$right]->[3] == 0) {
        $right++;
        last if $right > $last;
      }
      for my $j ($left .. $right - 1) {
        if ($left > 0 and $right < $last) {
          $positions->[$j]->[0] = $positions->[$left - 1]->[0] + (($positions->[$right]->[0] - $positions->[$left - 1]->[0]) / ($right - $left + 1) * ($j - $left + 1));
          $positions->[$j]->[1] = $positions->[$left - 1]->[1] + (($positions->[$right]->[1] - $positions->[$left - 1]->[1]) / ($right - $left + 1) * ($j - $left + 1));
        }
        else {
          if ($left == 0) {
            # beginning of the array
            $positions->[$j]->[0] = $positions->[$right]->[0];
            $positions->[$j]->[1] = $positions->[$right]->[1];
          }
          else {
            # end of the array
            $positions->[$j]->[0] = $positions->[$left - 1]->[0];
            $positions->[$j]->[1] = $positions->[$left - 1]->[1];
          }
        }
      }
    }
  }

  map { splice $_, 2 } @$positions;
}

sub _fix_point {
  my $self = shift;
  my $point = shift;

  $point->{easting} += 0;
  $point->{northing} += 0;
  $point->{sat_count} += 0;
  $point->{temperature} += 0;
  $point->{altitude} += 0;

  $point->{interpolated} = 0;
}

1;
