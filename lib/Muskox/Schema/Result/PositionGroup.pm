use utf8;
package Muskox::Schema::Result::PositionGroup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('position');

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(q[
  SELECT p.* FROM position p
  LEFT OUTER JOIN position p2 ON p.animal_id = p2.animal_id
    AND p.recorded <= p2.recorded
  GROUP BY p.id
  HAVING COUNT(*) <= ?
  ORDER BY p.animal_id, p.recorded DESC
]);

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "animal_id",
  { data_type => "char", default_value => "", is_nullable => 0, size => 9 },
  "recorded",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "ttf",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "northing",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "easting",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "zone",
  { data_type => "char", is_nullable => 0, size => 3 },
  "sat_count",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "fix",
  {
    data_type => "enum",
    default_value => "3D",
    extra => { list => ["2D", "3D", "IP"] },
    is_nullable => 0,
  },
  "altitude",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "h_dop",
  {
    data_type => "decimal",
    default_value => "1.0",
    is_nullable => 0,
    size => [2, 1],
  },
  "temperature",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "x",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "y",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "ok",
    is_nullable => 1,
    size => 128,
  },
);

1;
