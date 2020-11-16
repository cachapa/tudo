import 'package:share/share.dart';
import 'package:tudo_client/data/list_manager.dart';

void shareToDoList(ToDoList list) =>
    Share.share('Tap to open "${list.name}" in your device:\n'
        'https://tudo.cachapa.net/${list.id}');
