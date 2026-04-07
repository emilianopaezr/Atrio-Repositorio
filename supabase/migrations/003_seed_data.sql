-- ============================================
-- ATRIO MVP - Seed Data for Testing
-- Run AFTER 002_rls_policies.sql
-- ============================================

-- Create test users in auth.users (password: Test1234!)
-- Note: For self-hosted Supabase, you may need to create users via the Auth API instead.
-- This seed creates profiles directly assuming users already exist.

-- We'll use the Supabase Auth API to create test users, then this SQL seeds the rest.
-- For now, create a function to seed test data that can be called after users are created.

CREATE OR REPLACE FUNCTION seed_test_data(test_host_id UUID, test_guest_id UUID)
RETURNS void AS $$
DECLARE
  listing1_id UUID;
  listing2_id UUID;
  listing3_id UUID;
  listing4_id UUID;
  listing5_id UUID;
  listing6_id UUID;
  booking1_id UUID;
  conv1_id UUID;
BEGIN
  -- Update profiles to set host status
  UPDATE profiles SET
    display_name = 'Carlos Mendoza',
    bio = 'Anfitrión apasionado por compartir espacios únicos en Santiago',
    is_host = TRUE,
    is_verified = TRUE,
    kyc_status = 'approved'
  WHERE id = test_host_id;

  UPDATE profiles SET
    display_name = 'María López',
    bio = 'Amante de los viajes y las experiencias auténticas'
  WHERE id = test_guest_id;

  -- Create host profile
  INSERT INTO host_profiles (id, total_earnings, current_balance, pending_balance, response_rate, is_superhost)
  VALUES (test_host_id, 15420.00, 2450.00, 380.00, 98.5, TRUE)
  ON CONFLICT (id) DO NOTHING;

  -- =============================================
  -- LISTINGS
  -- =============================================

  -- Listing 1: Loft Industrial
  listing1_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count, is_featured)
  VALUES (
    listing1_id, test_host_id, 'space',
    'Loft Industrial Premium',
    'Espacio creativo de 120m² con techos altos de 5 metros, ventanales industriales de piso a techo y acabados premium. Perfecto para sesiones fotográficas, eventos corporativos o rodajes audiovisuales. Incluye cocina equipada, baño privado y estacionamiento.',
    ARRAY['https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800'],
    'Estudio', ARRAY['fotografía', 'eventos', 'industrial', 'premium'],
    ARRAY['WiFi', 'Estacionamiento', 'Cocina', 'Aire Acondicionado', 'Iluminación Profesional', 'Blackout'],
    'Av. Italia 1234', 'Santiago', 'Chile', -33.4372, -70.6345,
    120000, 'CLP', 'hour', 20000, 30, 'published', 4.8, 24, 1250, TRUE
  );

  -- Listing 2: Villa con Piscina
  listing2_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count, is_featured)
  VALUES (
    listing2_id, test_host_id, 'space',
    'Villa Exclusiva con Piscina Infinity',
    'Impresionante villa de 350m² con vista panorámica a la cordillera. Cuenta con piscina infinity climatizada, jacuzzi, amplio jardín con quincho y 5 dormitorios con baño en suite. Ideal para retiros corporativos, celebraciones o escapadas de lujo.',
    ARRAY['https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800'],
    'Villa', ARRAY['piscina', 'lujo', 'vista', 'retiro'],
    ARRAY['Piscina', 'Jacuzzi', 'WiFi', 'Estacionamiento', 'Quincho', 'Vista Panorámica', 'Aire Acondicionado'],
    'Camino La Dehesa 8900', 'Santiago', 'Chile', -33.3721, -70.5234,
    350000, 'CLP', 'night', 60000, 15, 'published', 4.9, 18, 890, TRUE
  );

  -- Listing 3: Tour Gastronómico
  listing3_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count)
  VALUES (
    listing3_id, test_host_id, 'experience',
    'Tour Gastronómico por Barrio Lastarria',
    'Descubre los sabores ocultos de Santiago en un recorrido de 4 horas por los mejores restaurantes y bares del Barrio Lastarria. Incluye 5 paradas con degustaciones, maridaje con vinos chilenos premium y la historia cultural del barrio. Grupo reducido de máximo 8 personas.',
    ARRAY['https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800'],
    'Gastronomía', ARRAY['comida', 'tour', 'vino', 'cultural'],
    ARRAY['Degustaciones Incluidas', 'Guía Bilingüe', 'Grupo Reducido'],
    'Barrio Lastarria', 'Santiago', 'Chile', -33.4378, -70.6401,
    65000, 'CLP', 'person', 0, 8, 'published', 4.7, 42, 2100
  );

  -- Listing 4: Fotografía Profesional
  listing4_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count)
  VALUES (
    listing4_id, test_host_id, 'service',
    'Sesión Fotográfica Profesional',
    'Sesión fotográfica profesional de 2 horas con fotógrafo certificado. Incluye 50 fotografías editadas en alta resolución, uso de equipo profesional (cámara Canon R5, iluminación Profoto) y asistente. Perfecta para retratos, productos, marcas o contenido para redes sociales.',
    ARRAY['https://images.unsplash.com/photo-1554048612-b6a482bc67e5?w=800',
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800'],
    'Fotografía', ARRAY['fotografía', 'profesional', 'retratos', 'marcas'],
    ARRAY['Equipo Profesional', '50 Fotos Editadas', 'Asistente Incluido'],
    'A domicilio / Estudio', 'Santiago', 'Chile', -33.4489, -70.6693,
    150000, 'CLP', 'session', 0, 1, 'published', 5.0, 8, 456
  );

  -- Listing 5: Rooftop Event Space
  listing5_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count, is_featured)
  VALUES (
    listing5_id, test_host_id, 'space',
    'Rooftop Terraza con Vista 360°',
    'Espectacular terraza en el piso 25 con vista panorámica 360° de Santiago y la Cordillera de los Andes. Espacio de 200m² con bar equipado, zona lounge con mobiliario premium y sistema de sonido profesional. Capacidad para 80 personas. Perfecto para eventos corporativos, lanzamientos y celebraciones.',
    ARRAY['https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=800',
          'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800'],
    'Evento', ARRAY['rooftop', 'terraza', 'vista', 'evento', 'corporativo'],
    ARRAY['Bar Equipado', 'Sonido Profesional', 'Vista 360°', 'Mobiliario Premium', 'WiFi', 'Estacionamiento VIP'],
    'Av. Apoquindo 4500, Piso 25', 'Santiago', 'Chile', -33.4180, -70.6010,
    650000, 'CLP', 'session', 120000, 80, 'published', 4.6, 12, 678, TRUE
  );

  -- Listing 6: Clase de Surf
  listing6_id := gen_random_uuid();
  INSERT INTO listings (id, host_id, type, title, description, images, category, tags, amenities,
    address, city, country, latitude, longitude, base_price, currency, price_unit,
    cleaning_fee, capacity, status, rating, review_count, view_count)
  VALUES (
    listing6_id, test_host_id, 'experience',
    'Clase de Surf para Principiantes',
    'Aprende a surfear en las mejores olas de la costa central. Clase de 3 horas con instructor certificado ISA, incluye tabla y traje de neopreno. Grupos de máximo 4 personas para atención personalizada. Todas las edades bienvenidas.',
    ARRAY['https://images.unsplash.com/photo-1502680390548-bdbac40a5e43?w=800',
          'https://images.unsplash.com/photo-1455729552457-5c322b382ea6?w=800'],
    'Deporte', ARRAY['surf', 'deporte', 'playa', 'principiante'],
    ARRAY['Equipo Incluido', 'Instructor Certificado', 'Grupo Reducido', 'Seguro Incluido'],
    'Playa Reñaca', 'Viña del Mar', 'Chile', -33.0153, -71.5516,
    55000, 'CLP', 'person', 0, 4, 'published', 4.9, 56, 3200
  );

  -- =============================================
  -- SAMPLE BOOKING
  -- =============================================
  booking1_id := gen_random_uuid();
  INSERT INTO bookings (id, guest_id, host_id, listing_id, check_in, check_out,
    guests_count, base_total, cleaning_fee, service_fee, total, status, payment_status)
  VALUES (
    booking1_id, test_guest_id, test_host_id, listing1_id,
    '2026-03-15 10:00:00+00', '2026-03-15 14:00:00+00',
    2, 480000, 20000, 50000, 550000, 'confirmed', 'paid'
  );

  -- =============================================
  -- SAMPLE CONVERSATION
  -- =============================================
  conv1_id := gen_random_uuid();
  INSERT INTO conversations (id, participant_ids, booking_id, listing_id,
    last_message_text, last_message_sender, last_message_at)
  VALUES (
    conv1_id,
    ARRAY[test_guest_id, test_host_id],
    booking1_id, listing1_id,
    '¡Perfecto! Te esperamos el día 15. El espacio estará listo desde las 9:30.',
    test_host_id,
    NOW() - INTERVAL '2 hours'
  );

  INSERT INTO messages (conversation_id, sender_id, text, sent_at) VALUES
    (conv1_id, test_guest_id, 'Hola, me interesa reservar el Loft para una sesión fotográfica el 15 de marzo.', NOW() - INTERVAL '1 day'),
    (conv1_id, test_host_id, '¡Hola María! Claro, el espacio está disponible ese día. ¿A qué hora necesitarías?', NOW() - INTERVAL '23 hours'),
    (conv1_id, test_guest_id, 'Sería de 10:00 a 14:00, somos 2 personas con equipo fotográfico.', NOW() - INTERVAL '22 hours'),
    (conv1_id, test_host_id, '¡Perfecto! Te esperamos el día 15. El espacio estará listo desde las 9:30.', NOW() - INTERVAL '2 hours');

  -- =============================================
  -- SAMPLE REVIEWS
  -- =============================================
  INSERT INTO reviews (listing_id, reviewer_id, host_id, booking_id, rating, comment) VALUES
    (listing3_id, test_guest_id, test_host_id, NULL, 5, 'Increíble experiencia. El tour fue muy completo y los restaurantes seleccionados son de primer nivel. ¡100% recomendado!'),
    (listing1_id, test_guest_id, test_host_id, booking1_id, 5, 'El loft es espectacular. La iluminación natural es perfecta para fotografía. Carlos fue muy atento y flexible con los horarios.');

  -- =============================================
  -- SAMPLE TRANSACTIONS
  -- =============================================
  INSERT INTO transactions (host_id, booking_id, type, amount, status, description) VALUES
    (test_host_id, booking1_id, 'earning', 150.00, 'completed', 'Reserva - Loft Industrial'),
    (test_host_id, booking1_id, 'fee', -1.50, 'completed', 'Comisión ATRIO (1%)'),
    (test_host_id, NULL, 'payout', -500.00, 'completed', 'Retiro a cuenta bancaria'),
    (test_host_id, NULL, 'earning', 85.00, 'completed', 'Reserva - Tour Gastronómico');

  -- =============================================
  -- SAMPLE NOTIFICATIONS
  -- =============================================
  INSERT INTO notifications (user_id, type, title, body, data) VALUES
    (test_host_id, 'booking_request', 'Nueva Reserva', 'María López quiere reservar tu Loft Industrial', '{"booking_id": "' || booking1_id || '"}'),
    (test_guest_id, 'booking_confirmed', 'Reserva Confirmada', 'Tu reserva en Loft Industrial ha sido confirmada', '{"booking_id": "' || booking1_id || '"}');

  -- =============================================
  -- AVAILABILITY for listings
  -- =============================================
  -- Mark some dates as unavailable for Listing 1
  INSERT INTO availability (listing_id, date, is_available) VALUES
    (listing1_id, '2026-03-15', FALSE),
    (listing1_id, '2026-03-20', FALSE),
    (listing1_id, '2026-03-25', FALSE);

  -- Set custom pricing for Listing 2 (weekends)
  INSERT INTO availability (listing_id, date, is_available, custom_price) VALUES
    (listing2_id, '2026-03-14', TRUE, 550.00),
    (listing2_id, '2026-03-15', TRUE, 550.00),
    (listing2_id, '2026-03-21', TRUE, 550.00),
    (listing2_id, '2026-03-22', TRUE, 550.00);

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
