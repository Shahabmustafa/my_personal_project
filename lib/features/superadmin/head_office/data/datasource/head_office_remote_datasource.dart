import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/head_office_model.dart';

class HeadOfficeRemoteDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HeadOfficeModel>> getAllHeadOffices() async {
    final data = await _client
        .from('head_offices')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => HeadOfficeModel.fromJson(e)).toList();
  }

  Future<HeadOfficeModel> getHeadOfficeById(String id) async {
    final data =
        await _client.from('head_offices').select().eq('id', id).single();
    return HeadOfficeModel.fromJson(data);
  }

  Future<HeadOfficeModel> createHeadOffice(HeadOfficeModel headOffice) async {
    final data = await _client
        .from('head_offices')
        .insert({
          'head_office_name': headOffice.headOfficeName,
          'address': headOffice.address,
          'phone_number': headOffice.phoneNumber,
          'city': headOffice.city,
          'status': headOffice.status,
        })
        .select()
        .single();
    return HeadOfficeModel.fromJson(data);
  }

  Future<HeadOfficeModel> updateHeadOffice(HeadOfficeModel headOffice) async {
    final data = await _client
        .from('head_offices')
        .update({
          'head_office_name': headOffice.headOfficeName,
          'address': headOffice.address,
          'phone_number': headOffice.phoneNumber,
          'city': headOffice.city,
          'status': headOffice.status,
        })
        .eq('id', headOffice.id)
        .select()
        .single();
    return HeadOfficeModel.fromJson(data);
  }

  Future<void> deleteHeadOffice(String id) async {
    await _client.from('head_offices').delete().eq('id', id);
  }
}
