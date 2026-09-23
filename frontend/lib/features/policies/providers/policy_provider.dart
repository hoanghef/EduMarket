import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/policy_model.dart';

final policiesRepositoryProvider = Provider((ref) {
  return PoliciesRepository(ref.watch(dioProvider));
});

class PoliciesRepository {
  final Dio _dio;
  PoliciesRepository(this._dio);

  Future<List<PolicySummary>> getPolicyList() async {
    final response = await _dio.get('/api/policies');
    final items = response.data['data']['items'] as List<dynamic>? ?? [];
    return items.map((e) => PolicySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PolicyModel> getPolicy(String slug) async {
    final response = await _dio.get('/api/policies/$slug');
    return PolicyModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final policyListProvider = FutureProvider<List<PolicySummary>>((ref) async {
  return ref.watch(policiesRepositoryProvider).getPolicyList();
});

final policyDetailProvider = FutureProvider.family<PolicyModel, String>((ref, slug) async {
  return ref.watch(policiesRepositoryProvider).getPolicy(slug);
});
