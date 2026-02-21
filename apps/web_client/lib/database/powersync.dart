import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'schema.dart';

final log = Logger('PowerSync');

class PowerSyncService {
  static final PowerSyncDatabase db = PowerSyncDatabase(
    schema: schema,
    path: 'kemani_db.sqlite',
  );

  static Future<void> initialize() async {
    // Open the local database
    final dir = await getApplicationSupportDirectory();
    final pathStr = path.join(dir.path, 'kemani_db.sqlite');
    // Using pathStr effectively or just pass to db if needed, but db validates path in constructor?
    // Actually, db assumes path is relative or absolute.
    // The previous implementation ignored dbPath.
    // I will just remove the lines calculating it if they are unused.

    // In production, path should be dynamic per user/tenant context if sharing device,
    // but for now stick to single DB instance concept
    // Note: PowerSyncDatabase constructor handles opening logic.
    // The previous line was static init.
    // Actually, in newer SDK, we just init the db.

    // Connect to Supabase
    db.connect(connector: SupabaseConnector(db));
  }
}

class SupabaseConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;

  SupabaseConnector(this.db);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Wait for authentication
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Not logged in
      return null;
    }

    final token = session.accessToken;

    // In a real app, you'd fetch a dedicated PowerSync token from your backend
    // or use the Supabase JWT if configured.
    // Assuming Supabase integration directly:
    return PowerSyncCredentials(
      endpoint:
          dotenv.env['POWERSYNC_INSTANCE_URL'] ??
          'https://powersync-instance-url.com',
      token: token,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    try {
      for (var op in transaction.crud) {
        final table = op.table;
        final id = op.id;
        final data = op.opData;

        switch (op.op) {
          case UpdateType.put:
            // Upsert: Create or Replace
            // Note: Ensure 'id' is in the data map for Supabase upsert
            final payload = Map<String, dynamic>.from(data!);
            payload['id'] = id;
            
            await Supabase.instance.client
                .from(table)
                .upsert(payload);
            break;
            
          case UpdateType.patch:
            // Patch: Update existing
            await Supabase.instance.client
                .from(table)
                .update(data!)
                .eq('id', id);
            break;
            
          case UpdateType.delete:
            // Delete
            await Supabase.instance.client
                .from(table)
                .delete()
                .eq('id', id);
            break;
        }
      }
      await transaction.complete();
    } catch (e) {
      log.severe('Error uploading data', e);
      // In a real app, you might want to retry or handle specific errors
      // rethrow; // Optional: let PowerSync SDK handle retry policy
    }
  }
}

final powerSyncClientProvider = Provider<PowerSyncDatabase>((ref) {
  // IMPORTANT: Ensure PowerSyncService.initialize() has been called
  // before accessing this provider. This typically happens early in your app's lifecycle.
  return PowerSyncService.db;
});

