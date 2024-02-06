import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import 'auth/auth_provider.dart';
import 'contacts/contact_provider.dart';
import 'crdt/hive_adapters.dart';
import 'crdt/tudo_crdt.dart';
import 'lists/list_provider.dart';
import 'settings/settings_provider.dart';
import 'sync/sync_provider.dart';
import 'util/store_provider.dart';

export 'util/durations.dart';

class Registry {
  static late final StoreProvider storeProvider;
  static late final SqlCrdt _crdt;

  static final settingsProvider = SettingsProvider(storeProvider);
  static final authProvider =
      AuthProvider(settingsProvider, storeProvider, _crdt);
  static final contactProvider = ContactProvider(authProvider, _crdt);
  static final listProvider = ListProvider(authProvider, storeProvider, _crdt);
  static final syncProvider =
      SyncProvider(settingsProvider, authProvider, storeProvider, _crdt);

  Registry._();

  static Future<void> init() async {
    final dir = platform.isAndroid || platform.isIOS
        ? (await getApplicationDocumentsDirectory()).path
        : 'store';
    Hive.init(dir);
    Hive.registerAdapter(HlcAdapter(1));

    // Init storage
    storeProvider = await StoreProvider.open();
    _crdt = await TudoCrdt.open('$dir/tudo.db');
  }
}
