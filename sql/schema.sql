CREATE SEQUENCE dam_crest_id_seq;

create table dam_crests (
    id smallint NOT NULL DEFAULT nextval('dam_crest_id_seq')
    user_id integer);

SELECT AddGeometryColumn('dam_crests', 'crest', 4269, 'LINESTRING', 2 );

