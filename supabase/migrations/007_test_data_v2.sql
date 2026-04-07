-- ================================================================
-- MIGRATION 007: Replace test data with comprehensive examples
-- Covers ALL listing types and rental modes
-- ================================================================

-- Delete existing demo listings (preserve real user data)
DELETE FROM bookings WHERE listing_id IN (SELECT id FROM listings WHERE host_id = '053c11bd-9fd7-484e-bb30-d75532d4db54');
DELETE FROM availability WHERE listing_id IN (SELECT id FROM listings WHERE host_id = '053c11bd-9fd7-484e-bb30-d75532d4db54');
DELETE FROM time_slot_bookings WHERE listing_id IN (SELECT id FROM listings WHERE host_id = '053c11bd-9fd7-484e-bb30-d75532d4db54');
DELETE FROM listings WHERE host_id = '053c11bd-9fd7-484e-bb30-d75532d4db54';

-- ================================================================
-- 1. ESPACIO POR NOCHES (check-in / check-out)
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, cleaning_fee, capacity,
  rental_mode, min_nights, max_nights, check_in_time, check_out_time,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000001',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'space',
  'Loft Industrial con Vista Panorámica',
  'Espectacular loft de 120m² en el corazón de Providencia. Techos de doble altura con vigas de acero expuestas, ventanales de piso a techo con vista a la Cordillera de los Andes. Perfecto para estadías cortas o largas. Incluye cocina equipada, WiFi de alta velocidad, y terraza privada.',
  ARRAY[
    'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800'
  ],
  'Loft',
  ARRAY['loft', 'vista', 'industrial', 'premium'],
  ARRAY['WiFi', 'Cocina equipada', 'Terraza', 'Estacionamiento', 'A/C', 'TV Smart', 'Lavadora'],
  'Av. Providencia 1234', 'Santiago', 'Chile', -33.4292, -70.6066,
  75000, 'CLP', 'night', 20000, 4,
  'nights', 2, 30, '15:00', '11:00',
  false, 'flexible', 'published', 4.8, 24
);

-- ================================================================
-- 2. ESPACIO POR DÍA COMPLETO
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, cleaning_fee, capacity,
  rental_mode, instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000002',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'space',
  'Rooftop Exclusivo para Eventos',
  'Terraza en la azotea de un edificio emblemático de Las Condes. 200m² al aire libre con vista 360° de Santiago. Ideal para eventos corporativos, lanzamientos de productos, sesiones fotográficas o celebraciones privadas. Incluye mobiliario básico, sistema de sonido y barra de bar.',
  ARRAY[
    'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800',
    'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800'
  ],
  'Rooftop',
  ARRAY['rooftop', 'eventos', 'terraza', 'corporativo'],
  ARRAY['Sistema de Sonido', 'Bar', 'Mobiliario', 'Iluminación LED', 'Baños', 'WiFi', 'Estacionamiento'],
  'Isidora Goyenechea 3000', 'Santiago', 'Chile', -33.4167, -70.5989,
  380000, 'CLP', 'session', 40000, 80,
  'full_day', true, 'strict', 'published', 4.9, 18
);

-- ================================================================
-- 3. ESPACIO POR HORAS
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, cleaning_fee, capacity,
  rental_mode, available_from, available_until, slot_duration_minutes, min_hours, max_hours,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000003',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'space',
  'Estudio Creativo para Grabaciones',
  'Estudio profesional de 60m² equipado para fotografía, video y podcasting. Fondo ciclorama blanco de 4x3m, iluminación profesional Profoto, zona de maquillaje y vestidor. Ubicado en Barrio Italia con fácil acceso.',
  ARRAY[
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800',
    'https://images.unsplash.com/photo-1581092921461-eab62e97a780?w=800'
  ],
  'Estudio',
  ARRAY['estudio', 'fotografia', 'video', 'podcast'],
  ARRAY['Ciclorama', 'Iluminación Profoto', 'WiFi', 'Vestidor', 'Maquillaje', 'A/C', 'Estacionamiento'],
  'Av. Italia 1500', 'Santiago', 'Chile', -33.4470, -70.6310,
  30000, 'CLP', 'hour', 0, 8,
  'hours', '08:00', '22:00', 60, 2, 10,
  true, 'moderate', 'published', 4.7, 31
);

-- ================================================================
-- 4. EXPERIENCIA CON CUPOS Y HORARIOS (por horas)
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, capacity,
  rental_mode, available_from, available_until, slot_duration_minutes,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000004',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'experience',
  'Tour Gastronómico por Barrio Lastarria',
  'Recorre los mejores restaurantes y bares escondidos de Lastarria en un tour de 3 horas. Degustación de 5 platos típicos chilenos reinventados, maridaje con vinos locales, y la historia detrás de cada lugar. Guía bilingüe. Máximo 10 personas para experiencia íntima.',
  ARRAY[
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
    'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800'
  ],
  'Tour',
  ARRAY['gastronomia', 'tour', 'vinos', 'lastarria'],
  ARRAY['Degustación incluida', 'Vinos', 'Guía bilingüe', 'Seguro'],
  'Plaza Lastarria', 'Santiago', 'Chile', -33.4400, -70.6385,
  55000, 'CLP', 'person', 10,
  'hours', '11:00', '20:00', 180,
  false, 'flexible', 'published', 4.9, 42
);

-- ================================================================
-- 5. EXPERIENCIA DE DÍA COMPLETO
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, capacity,
  rental_mode,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000005',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'experience',
  'Trekking + Termas en Cajón del Maipo',
  'Escapada de un día completo al Cajón del Maipo. Incluye trekking guiado de dificultad media (4h), almuerzo tipo picnic gourmet con productos locales, y acceso a termas naturales para relajarse después de la caminata. Transporte desde Santiago incluido. Grupos reducidos.',
  ARRAY[
    'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800'
  ],
  'Trekking',
  ARRAY['trekking', 'termas', 'naturaleza', 'outdoor'],
  ARRAY['Transporte incluido', 'Almuerzo', 'Guía certificado', 'Seguro', 'Bastones'],
  'Cajón del Maipo', 'Santiago', 'Chile', -33.6000, -70.1000,
  95000, 'CLP', 'person', 12,
  'full_day',
  false, 'moderate', 'published', 4.8, 19
);

-- ================================================================
-- 6. SERVICIO POR HORAS
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, capacity,
  rental_mode, available_from, available_until, slot_duration_minutes, min_hours, max_hours,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000006',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'service',
  'Fotografía Profesional para Eventos',
  'Fotógrafo profesional con 8 años de experiencia en eventos corporativos, bodas, y sesiones de producto. Equipo profesional Canon R5 + iluminación portátil. Entrega de fotos editadas en 48h (mínimo 50 fotos por hora). Portfolio disponible.',
  ARRAY[
    'https://images.unsplash.com/photo-1554048612-b6a482bc67e5?w=800',
    'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=800'
  ],
  'Fotografia',
  ARRAY['fotografia', 'eventos', 'profesional', 'corporativo'],
  ARRAY['Equipo profesional', 'Edición incluida', 'Entrega 48h', 'Iluminación portátil'],
  'A domicilio', 'Santiago', 'Chile', -33.4372, -70.6506,
  35000, 'CLP', 'hour', 1,
  'hours', '08:00', '21:00', 60, 2, 8,
  true, 'moderate', 'published', 4.9, 56
);

-- ================================================================
-- 7. SERVICIO POR DÍA COMPLETO (sesión)
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, capacity,
  rental_mode,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000007',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'service',
  'Servicio de Catering Premium',
  'Catering completo para eventos de hasta 50 personas. Menú personalizable: entradas frías y calientes, plato principal, postre y estación de bebidas. Vajilla, cubiertería y servicio de meseros incluido. Opciones vegetarianas y veganas disponibles.',
  ARRAY[
    'https://images.unsplash.com/photo-1555244162-803834f70033?w=800',
    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=800'
  ],
  'Catering',
  ARRAY['catering', 'eventos', 'comida', 'premium'],
  ARRAY['Menú personalizable', 'Vajilla incluida', 'Meseros', 'Opciones veganas', 'Montaje'],
  'A domicilio', 'Santiago', 'Chile', -33.4372, -70.6506,
  650000, 'CLP', 'session', 50,
  'full_day',
  false, 'strict', 'published', 4.7, 12
);

-- ================================================================
-- 8. EXPERIENCIA POR HORAS (adicional - clase/taller)
-- ================================================================
INSERT INTO listings (
  id, host_id, type, title, description, images, category, tags, amenities,
  address, city, country, latitude, longitude,
  base_price, currency, price_unit, capacity,
  rental_mode, available_from, available_until, slot_duration_minutes,
  instant_booking, cancellation_policy, status, rating, review_count
) VALUES (
  'a0000001-0001-0001-0001-000000000008',
  '053c11bd-9fd7-484e-bb30-d75532d4db54',
  'experience',
  'Clase de Cerámica Artesanal',
  'Taller práctico de cerámica en un estudio boutique de Barrio Italia. Aprende técnicas de modelado a mano, uso del torno y esmaltado. Cada participante se lleva su pieza terminada (se envía después de la cocción). Todos los materiales incluidos. Ideal para principiantes.',
  ARRAY[
    'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800',
    'https://images.unsplash.com/photo-1604076913837-52ab5f3e17a2?w=800'
  ],
  'Taller',
  ARRAY['ceramica', 'taller', 'arte', 'handmade'],
  ARRAY['Materiales incluidos', 'Pieza para llevar', 'Delantal', 'Café de cortesía'],
  'Av. Italia 1200', 'Santiago', 'Chile', -33.4470, -70.6310,
  35000, 'CLP', 'person', 8,
  'hours', '10:00', '19:00', 120,
  true, 'flexible', 'published', 4.8, 35
);
