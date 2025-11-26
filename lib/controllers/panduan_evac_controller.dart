import 'package:cepattanggap/models/panduan_item_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

final _firestore = FirebaseFirestore.instance;

class PanduanEvacController extends GetxController {
  Future<PanduanBencana> fetchPanduan(String id) async {
    final lowerId = id.toLowerCase();

    final doc = await _firestore.collection('panduan').doc(lowerId).get();

    if (doc.exists) {
      return PanduanBencana.fromMap(doc.data()!);
    } else {
      return PanduanBencana(panduanDalam: [], panduanLuar: []);
    }
  }
}
