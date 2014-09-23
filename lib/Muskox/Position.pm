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

  my $cursor = $self->db->resultset('Position')->search(
    {},
    {
      columns => [ 'animal_id', 'recorded', { count => 'id' } ],
      group_by => [ qw/animal_id/ ],
      order_by => { -desc => 'recorded' }
    }
  );

  my $names = {};
  while (my $row = $cursor->next) {
    $names->{$row->animal_id} = {
      'positions' => int($row->get_column('count')),
      'latest' => $row->recorded,
    };
  }

  $self->render(json => $names);
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

  my $geojson = $self->_render_points($points);
  $self->render(json => $geojson);
}

sub _render_points {
  my $self = shift;
  my $data = shift;

  my $geojson = {
    type => 'FeatureCollection',
    features => [],
  };

  my $points = [];
  foreach my $point (@$data) {
    my ($latitude, $longitude) = utm_to_latlon(23, $point->{zone}, $point->{easting}, $point->{northing});
    push @$points, [$longitude, $latitude, $point->{easting}, $point->{northing}];
  }

  $self->_interpolate($points);

  my $last = @$data - 1;
  for my $i (0 .. $last) {
    my $point = $data->[$i];
    my $feature = {
      type => 'Feature',
      geometry => {
        type => 'Point',
        coordinates => [$points->[$i]->[0], $points->[$i]->[1]],
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
  my $data = shift;

  my $geojson = {
    type => 'FeatureCollection',
    features => [],
  };

  foreach my $animal_id (keys %$data) {
    my $points = [];
    foreach my $point (@{$data->{$animal_id}}) {
      my ($latitude, $longitude) = utm_to_latlon(23, $point->{zone}, $point->{easting}, $point->{northing});
      push @$points, [$longitude, $latitude, $point->{easting}, $point->{northing}];
    }

    $self->_interpolate($points);

    my $feature = {
      type => 'Feature',
      geometry => {
        type => 'LineString',
        coordinates => $points,
      },
      properties => {
        animal_id => $animal_id,
      },
    };

    push @{$geojson->{features}}, $feature if $#{$points} > 0;
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
