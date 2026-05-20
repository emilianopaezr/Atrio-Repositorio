import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase/supabase_config.dart';
import '../models/host_stats_model.dart';
import '../models/user_model.dart';

/// Bundles a host's full profile + their aggregated host stats so the
/// listing detail can render the "Conoce al anfitrión" section in a
/// single round-trip-friendly read.
class HostDetail {
  final UserProfile profile;
  final HostStats stats;
  const HostDetail({required this.profile, required this.stats});
}

/// Fetches the host's full profile + host stats in parallel.
final hostDetailProvider =
    FutureProvider.autoDispose.family<HostDetail?, String>((ref, hostId) async {
  final client = SupabaseConfig.client;

  final futures = await Future.wait([
    client.from('profiles').select().eq('id', hostId).maybeSingle(),
    client.from('host_stats').select().eq('host_id', hostId).maybeSingle(),
  ]);

  final profileRow = futures[0];
  if (profileRow == null) return null;

  final statsRow = futures[1];
  final stats = statsRow != null
      ? HostStats.fromJson(statsRow)
      : HostStats(hostId: hostId);

  return HostDetail(
    profile: UserProfile.fromJson(profileRow),
    stats: stats,
  );
});
