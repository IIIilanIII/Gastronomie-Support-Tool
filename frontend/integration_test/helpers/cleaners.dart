import 'package:frontend/models/menu_item_model.dart';
import 'package:frontend/proxy/proxy.dart';
import 'package:frontend/utils/fetch_result.dart';
import 'package:http/http.dart' as http;

//Löscht alle, die aktuell im Backend sind
Future<void> deleteItems({
  required BackendProxy backend,
  required http.Client client,
}) async {
  FetchResult<List<MenuItemModel>> itemsResult = await backend.fetchMenuItems(
    client,
  );
  if (itemsResult.isSuccess) {
    for (final item in itemsResult.data!) {
      try {
        await backend.deleteMenuItem(client, item);
      } catch (_) {}
    }
  }
}
