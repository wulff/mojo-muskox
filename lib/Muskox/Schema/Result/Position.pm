use utf8;
package Muskox::Schema::Result::Position;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Muskox::Schema::Result::Position

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<position>

=cut

__PACKAGE__->table("position");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 animal_id

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 9

=head2 recorded

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 ttf

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 northing

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 easting

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 zone

  data_type: 'char'
  is_nullable: 0
  size: 3

=head2 sat_count

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 fix

  data_type: 'enum'
  default_value: '3D'
  extra: {list => ["2D","3D","IP"]}
  is_nullable: 0

=head2 altitude

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 h_dop

  data_type: 'decimal'
  default_value: 1.0
  is_nullable: 0
  size: [2,1]

=head2 temperature

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 x

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 y

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  default_value: 'ok'
  is_nullable: 1
  size: 128

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<animal_time>

=over 4

=item * L</animal_id>

=item * L</recorded>

=back

=cut

__PACKAGE__->add_unique_constraint("animal_time", ["animal_id", "recorded"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2014-09-24 11:33:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/mZLA8Sm97w28d0nOiZDsg

sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  $sqlt_table->add_index(name => 'animal_id', fields => ['animal_id']);
  $sqlt_table->add_index(name => 'recorded',  fields => ['recorded']);
  $sqlt_table->add_index(name => 'status',    fields => ['status']);
}

1;
