import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery.dart'; // Import the Delivery model

class DeliveryService {
  final SupabaseClient _supabase;

  DeliveryService(this._supabase);

  /// Fetches all deliveries from Supabase.
  Future<List<Delivery>> getAllDeliveries() async {
    final response = await _supabase.from('deliveries').select();
    if (response.error != null) {
      throw Exception('Failed to load deliveries: ${response.error!.message}');
    }
    final data = response.data as List;
    return data.map((json) => Delivery.fromJson(json)).toList();
  }

  /// Fetches a single delivery by ID from Supabase.
  Future<Delivery?> getDeliveryById(String id) async {
    final response = await _supabase.from('deliveries').select().eq('id', id).single();
    if (response.error != null) {
      // Handle error, e.g., throw exception or return null
      return null;
    }
    return Delivery.fromJson(response.data);
  }

  /// Creates a new delivery in Supabase.
  Future<void> createDelivery(Delivery delivery) async {
    await _supabase.from('deliveries').insert(delivery.toJson());
  }

  /// Updates an existing delivery in Supabase.
  Future<void> updateDelivery(Delivery delivery) async {
    await _supabase.from('deliveries').update(delivery.toJson()).eq('id', delivery.id);
  }

  /// Deletes a delivery from Supabase.
  Future<void> deleteDelivery(String id) async {
    await _supabase.from('deliveries').delete().eq('id', id);
  }
}

// Provider for DeliveryService
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  final supabase = Supabase.instance.client;
  return DeliveryService(supabase);
});

// Provider to manage the delivery list state
final deliveryListProvider = StateNotifierProvider<DeliveryListNotifier, List<Delivery>>((ref) {
  return DeliveryListNotifier(ref.watch(deliveryServiceProvider));
});

class DeliveryListNotifier extends StateNotifier<List<Delivery>> {
  final DeliveryService _deliveryService;

  DeliveryListNotifier(this._deliveryService) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      state = await _deliveryService.getAllDeliveries();
    } catch (e) {
      print('Error refreshing delivery list: $e');
      state = [];
    }
  }

  Future<void> addDelivery(Delivery delivery) async {
    await _deliveryService.createDelivery(delivery);
    await refresh();
  }

  Future<void> updateDelivery(Delivery delivery) async {
    await _deliveryService.updateDelivery(delivery);
    await refresh();
  }

  Future<void> deleteDelivery(String id) async {
    await _deliveryService.deleteDelivery(id);
    await refresh();
  }
}