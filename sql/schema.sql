CREATE SEQUENCE dam_id_seq;

create table dams (
    id smallint NOT NULL DEFAULT nextval('dam_id_seq'),
    user_id integer);

SELECT AddGeometryColumn('dams', 'crest', 4269, 'LINESTRING', 2 );

ALTER table dams ADD column rast raster;

SELECT AddGeometryColumn('dams', 'lake', 4269, 'POLYGON', 2 );

