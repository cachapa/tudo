import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart';

import 'auth/auth_provider.dart';
import 'contacts/contact_provider.dart';
import 'crdt/hive_adapters.dart';
import 'crdt/tudo_crdt.dart';
import 'lists/list_provider.dart';
import 'settings/settings_provider.dart';
import 'sync/sync_provider.dart';
import 'util/store.dart';

export 'util/durations.dart';

class Registry {
  static late final StoreProvider storeProvider;
  static late final SettingsProvider settingsProvider;
  static late final AuthProvider authProvider;
  static late final ContactProvider contactProvider;
  static late final ListProvider listProvider;
  static late final SyncProvider syncProvider;

  Registry._();

  static Future<void> init() async {
    final dir = platform.isAndroid || platform.isIOS
        ? (await getApplicationDocumentsDirectory()).path
        : 'store';
    Hive.init(dir);
    Hive.registerAdapter(HlcAdapter(1));

    // Init storage
    storeProvider = await StoreProvider.open();
    final crdt = await TudoCrdt.open('$dir/tudo.db');

    // Init providers
    settingsProvider = SettingsProvider(storeProvider);
    authProvider = AuthProvider(storeProvider);
    contactProvider = ContactProvider(authProvider.userId, crdt);
    listProvider = ListProvider(authProvider.userId, crdt, storeProvider);
    syncProvider = SyncProvider(authProvider, storeProvider, crdt);
  }
}
