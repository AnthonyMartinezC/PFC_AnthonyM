import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<bool> verifyHat(String code) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hats')
          .where('qrCode', isEqualTo: code)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
