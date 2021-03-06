CREATE SEQUENCE dam_id_seq;

create table dams (
    id smallint NOT NULL DEFAULT nextval('dam_id_seq'),
    user_id integer);

SELECT AddGeometryColumn('dams', 'crest', 4326, 'LINESTRING', 2 );

ALTER table dams ADD column rast raster;

SELECT AddGeometryColumn('dams', 'lake', 4326, 'POLYGON', 2 );
SELECT AddGeometryColumn('dams', 'lake2', 4326, 'MULTIPOLYGON', 2 );

ALTER table dams ADD column scratch raster;
ALTER table dams ADD column study_area integer;
ALTER table dams ADD column dam_height_rast raster;
ALTER table dams ADD column dam_height_const_rast raster;
ALTER table dams ADD column dam_height float;
ALTER table dams ADD column scratch2 raster;

SELECT AddGeometryColumn('dams', 'watershed', 4326, 'MULTIPOLYGON', 2 );

alter table areas add column description text;
alter table areas add column attribution text;

alter table dams add column reservoir_area float;
alter table dams add column reservoir_volume float;
alter table dams add column earthworks_volume float;
alter table dams add column earthworks_volume_const float;

alter table dams add column crest_length double precision;
alter table dams add column throwback double precision;
alter table dams add column stephens_reservoir_volume double precision;
alter table dams add column stephens_earthworks_volume double precision;

