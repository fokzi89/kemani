import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos_admin/models/customer.dart';
import 'package:pos_admin/models/customer_address.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  Future<Customer> createCustomer(Customer customer) async {
    final response = await _client
        .from('customers')
        .insert(customer.toJson())
        .select()
        .single();
    return Customer.fromJson(response);
  }

  Future<Customer> updateCustomer(
      String id, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    final response = await _client
        .from('customers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Customer.fromJson(response);
  }

  Future<void> deleteCustomer(String id) async {
    // Soft delete or hard delete depending on requirements (Soft delete indicated in schema)
    await _client.from('customers').update({
      'deleted_at': DateTime.now().toIso8601String(),
      '_sync_is_deleted': true,
    }).eq('id', id);
  }

  Future<Customer?> getCustomer(String id) async {
    final response = await _client
        .from('customers')
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (response == null) return null;
    return Customer.fromJson(response);
  }

  Future<List<Customer>> listCustomers(
      {int limit = 20, int offset = 0, String? tenantId}) async {
    var query = _client.from('customers').select().isFilter('deleted_at', null);
    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }
    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Customer>.from(response.map((x) => Customer.fromJson(x)));
  }

  Future<List<Customer>> searchCustomers(String queryStr,
      {String? tenantId}) async {
    var query = _client.from('customers').select().isFilter('deleted_at', null).or(
        'full_name.ilike.%$queryStr%,phone.ilike.%$queryStr%,email.ilike.%$queryStr%');

    if (tenantId != null && tenantId.isNotEmpty) {
      query = query.eq('tenant_id', tenantId);
    }
    final response =
        await query.order('created_at', ascending: false).limit(20);
    return List<Customer>.from(response.map((x) => Customer.fromJson(x)));
  }

  // Address Management
  Future<CustomerAddress> addCustomerAddress(CustomerAddress address) async {
    final response = await _client
        .from('customer_addresses')
        .insert(address.toJson())
        .select()
        .single();
    return CustomerAddress.fromJson(response);
  }

  Future<CustomerAddress> updateCustomerAddress(
      String id, Map<String, dynamic> updates) async {
    final response = await _client
        .from('customer_addresses')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return CustomerAddress.fromJson(response);
  }

  Future<void> setDefaultAddress(String customerId, String addressId) async {
    // First remove default from all
    await _client
        .from('customer_addresses')
        .update({'is_default': false}).eq('customer_id', customerId);
    // Set the specific one to default
    await _client
        .from('customer_addresses')
        .update({'is_default': true}).eq('id', addressId);
  }

  Future<List<CustomerAddress>> getCustomerAddresses(String customerId) async {
    final response = await _client
        .from('customer_addresses')
        .select()
        .eq('customer_id', customerId)
        .order('is_default', ascending: false);
    return List<CustomerAddress>.from(
        response.map((x) => CustomerAddress.fromJson(x)));
  }
}
