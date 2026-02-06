import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../models/delivery.dart';
import 'api_client.dart';

class DeliveriesApi {
  final Dio _dio;

  DeliveriesApi(this._dio);

  static Future<DeliveriesApi> build() async {
    final client = await ApiClient.create();
    return DeliveriesApi(client.dio);
  }

  Future<List<DeliveryItem>> listDeliveries({
    String? fromDate,
    String? toDate,
    int? courierId,
    String? company,
  }) async {
    final res = await _dio.get(
      "/deliveries",
      queryParameters: {
        if (fromDate != null) "from_date": fromDate,
        if (toDate != null) "to_date": toDate,
        if (courierId != null) "courier_id": courierId,
        if (company != null) "company": company,
      },
    );

    final data = List<Map<String, dynamic>>.from(res.data);
    return data.map((e) => DeliveryItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> statsFortnight({
    required String start,
    String? company,
  }) async {
    final res = await _dio.get(
      "/stats/fortnight",
      queryParameters: {
        "start": start,
        if (company != null) "company": company,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  /// ✅ Agora funciona no Web (Chrome) e no Mobile (Android/iOS)
  Future<void> uploadDeliveryPhoto({
    required XFile file,
    required String company,
  }) async {
    MultipartFile mf;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      mf = MultipartFile.fromBytes(bytes, filename: file.name);
    } else {
      mf = await MultipartFile.fromFile(file.path);
    }

    final formData = FormData.fromMap({
      "photo": mf,
      "company": company,
    });
    await _dio.post("/deliveries", data: formData);
  }

  Future<void> setStatus({
    required int deliveryId,
    required String status, // approved/rejected
    String? notes,
  }) async {
    await _dio.patch(
      "/deliveries/$deliveryId/status",
      data: {"status": status, "notes": notes},
    );
  }
}
