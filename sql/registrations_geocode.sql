-- generate BBL & add lat/lng from pluto
BEGIN;

ALTER TABLE hpd.registrations ADD COLUMN bbl text;

UPDATE hpd.registrations SET bbl = cast(boroid as text) || lpad(cast(block as text), 5, '0') || lpad(cast(lot as text), 4, '0');

CREATE TABLE bbl_lookup (
       lat numeric,
       lng numeric,
       bbl text PRIMARY KEY
);

COPY  bbl_lookup FROM '/var/lib/openshift/562fedcc89f5cfb811000141/app-root/repo/data/bbl_lat_lng.txt' (FORMAT CSV,  HEADER TRUE);

ALTER TABLE hpd.registrations add COLUMN lat numeric;
ALTER TABLE hpd.registrations add COLUMN lng numeric;

UPDATE  hpd.registrations SET lat = bbl_lookup.lat, lng = bbl_lookup.lng FROM bbl_lookup WHERE hpd.registrations.bbl = bbl_lookup.bbl;

DROP TABLE bbl_lookup;

COMMIT;

