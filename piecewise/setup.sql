CREATE EXTENSION postgis;
CREATE EXTENSION btree_gist;

CREATE OR REPLACE FUNCTION _final_median(float[]) RETURNS float8 AS $$
  WITH q AS
  (
    SELECT val
    FROM unnest($1) val
      WHERE VAL IS NOT NULL
      ORDER BY 1
  ),
  cnt AS
  (
    SELECT COUNT(*) AS c FROM q
  )
  SELECT AVG(val)::float8
  FROM
  (
    SELECT val FROM q
    LIMIT  2 - MOD((SELECT c FROM cnt), 2)
    OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)
  ) q2;
$$ LANGUAGE SQL IMMUTABLE;
 
CREATE AGGREGATE median(float) (
  SFUNC=array_append,
  STYPE=float[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);

CREATE AGGREGATE median(float[]) (
    SFUNC=array_cat,
    STYPE=float[],
    FINALFUNC=_final_median,
    INITCOND='{}'
);

CREATE TABLE maxmind (
    ip_range int8range,
    ip_low bigint,
    ip_high bigint,
    label varchar);
CREATE INDEX maxmind_ip_range_idx ON maxmind USING GIST (ip_range);

COPY maxmind (ip_low, ip_high, label) FROM '/tmp/GeoIPASNum2.csv' WITH (FORMAT csv, HEADER false, encoding 'latin1');
UPDATE maxmind SET ip_range = int8range(ip_low, ip_high);
