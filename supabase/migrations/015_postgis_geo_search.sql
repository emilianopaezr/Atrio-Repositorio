-- =============================================
-- 015: PostGIS Geo Search
-- =============================================
-- Enables radius search ("listings near me") using PostGIS.
-- Requires PostGIS extension (enabled separately).

-- 1) Add location column (WGS84 / EPSG:4326) if missing
ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS location geography(Point, 4326);

-- 2) GIST index for fast spatial queries
CREATE INDEX IF NOT EXISTS idx_listings_location
  ON listings USING GIST (location);

-- 3) Keep `location` in sync with lat/lng automatically
CREATE OR REPLACE FUNCTION sync_listing_location()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(
      ST_MakePoint(NEW.longitude::double precision, NEW.latitude::double precision),
      4326
    )::geography;
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_sync_listing_location ON listings;
CREATE TRIGGER trg_sync_listing_location
BEFORE INSERT OR UPDATE OF latitude, longitude ON listings
FOR EACH ROW
EXECUTE FUNCTION sync_listing_location();

-- 4) Backfill existing rows
UPDATE listings
SET location = ST_SetSRID(
  ST_MakePoint(longitude::double precision, latitude::double precision),
  4326
)::geography
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND location IS NULL;

-- 5) RPC: search listings within radius (meters) from a point
--    Returns listings ordered by distance ascending.
CREATE OR REPLACE FUNCTION search_listings_nearby(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION DEFAULT 10000,
  p_category TEXT DEFAULT NULL,
  p_type TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  host_id UUID,
  title TEXT,
  description TEXT,
  type TEXT,
  category TEXT,
  city TEXT,
  country TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  base_price NUMERIC,
  price_unit TEXT,
  currency TEXT,
  capacity INTEGER,
  images TEXT[],
  amenities TEXT[],
  rating NUMERIC,
  review_count INTEGER,
  status TEXT,
  cleaning_fee NUMERIC,
  distance_m DOUBLE PRECISION
)
LANGUAGE sql
STABLE
AS $func$
  SELECT
    l.id,
    l.host_id,
    l.title,
    l.description,
    l.type,
    l.category,
    l.city,
    l.country,
    l.address,
    l.latitude::double precision,
    l.longitude::double precision,
    l.base_price,
    l.price_unit,
    l.currency,
    l.capacity,
    l.images,
    l.amenities,
    l.rating,
    l.review_count,
    l.status,
    l.cleaning_fee,
    ST_Distance(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) AS distance_m
  FROM listings l
  WHERE l.status = 'published'
    AND l.location IS NOT NULL
    AND ST_DWithin(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    )
    AND (p_category IS NULL OR l.category = p_category)
    AND (p_type IS NULL OR l.type = p_type)
  ORDER BY distance_m ASC
  LIMIT p_limit;
$func$;

-- Allow anon + authenticated to call the RPC
GRANT EXECUTE ON FUNCTION search_listings_nearby(
  DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, TEXT, INTEGER
) TO anon, authenticated;

COMMENT ON FUNCTION search_listings_nearby IS
  'Radius search over active listings using PostGIS. Returns rows ordered by distance in meters.';
