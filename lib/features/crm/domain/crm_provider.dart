import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/local_db_service.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/domain/auth_provider.dart';
import 'crm_models.dart';

final crmProvider = StateNotifierProvider<CrmNotifier, AsyncValue<List<Client>>>((ref) {
  final user = ref.watch(authProvider).user;
  return CrmNotifier(ref, user?.id ?? 'demo-user-id');
});

class CrmNotifier extends StateNotifier<AsyncValue<List<Client>>> {
  final Ref ref;
  final String userId;

  CrmNotifier(this.ref, this.userId) : super(const AsyncValue.loading()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = const AsyncValue.loading();
    try {
      final maps = await LocalDbService.instance.getClients();
      if (maps.isNotEmpty) {
        state = AsyncValue.data(maps.map((m) => Client.fromMap(m)).toList());
      } else {
        final sampleClients = _getSampleClients();
        for (var c in sampleClients) {
          await LocalDbService.instance.upsertClient(c.toMap());
        }
        state = AsyncValue.data(sampleClients);
      }

      if (SupabaseConfig.isConfigured) {
        try {
          final res = await SupabaseConfig.client
              .from('clients')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);

          if (res.isNotEmpty) {
            final remoteClients = (res as List).map((m) => Client.fromMap(m)).toList();
            for (var c in remoteClients) {
              await LocalDbService.instance.upsertClient(c.toMap());
            }
            state = AsyncValue.data(remoteClients);
          }
        } catch (_) {}
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Client> _getSampleClients() {
    final now = DateTime.now();
    return [
      Client(
        id: 'client-001',
        userId: userId,
        clientBrandName: 'Apex Tech Gear',
        contactPerson: 'David Chen',
        phone: '+919876543210',
        whatsapp: '+919876543210',
        email: 'partnerships@apexgear.io',
        instagram: '@apexgear',
        companyName: 'Apex Technologies Inc',
        projectDetails: 'Dedicated 60-second integrated sponsorship on YouTube Shorts & Reels.',
        dealAmount: 35000.0,
        paymentStatus: 'Advance Paid',
        workDeadline: now.add(const Duration(days: 10)),
        followUpDate: now.add(const Duration(days: 2)),
        status: LeadStatus.workInProgress,
        notes: 'Requested emphasis on quick USB-C fast charging capability.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Client(
        id: 'client-002',
        userId: userId,
        clientBrandName: 'Zenith Mastermind',
        contactPerson: 'Sarah Jenkins',
        phone: '+14155552671',
        whatsapp: '+14155552671',
        email: 'sarah@zenithscale.com',
        instagram: '@zenithgrowth',
        companyName: 'Zenith Consulting Group',
        projectDetails: 'Custom course funnel build & automated email drip sequences.',
        dealAmount: 75000.0,
        paymentStatus: 'Pending',
        workDeadline: now.add(const Duration(days: 24)),
        followUpDate: now.add(const Duration(days: 1)),
        status: LeadStatus.negotiation,
        notes: 'Discussing scope of 10 automated email sequences vs 5.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Client(
        id: 'client-003',
        userId: userId,
        clientBrandName: 'Kite Cloud AI',
        contactPerson: 'Alex Rivera',
        phone: '+918765432109',
        whatsapp: '+918765432109',
        email: 'marketing@kitecloud.ai',
        instagram: '@kitecloudai',
        companyName: 'Kite Software Labs',
        projectDetails: 'Affiliate commission contract + upfront \$500 trial retainer.',
        dealAmount: 42000.0,
        paymentStatus: 'Fully Paid',
        workDeadline: now.subtract(const Duration(days: 2)),
        followUpDate: null,
        status: LeadStatus.completed,
        notes: 'Campaign generated 1,400 signups. Client very satisfied.',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }

  Future<void> addClient(Client client) async {
    await LocalDbService.instance.upsertClient(client.toMap());
    final current = state.value ?? [];
    state = AsyncValue.data([client, ...current]);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client.from('clients').insert(client.toMap());
      } catch (_) {
        await LocalDbService.instance.addToSyncQueue(
          table: 'clients',
          operation: 'INSERT',
          payload: client.toMap(),
        );
      }
    }
  }

  Future<void> updateClientStatus(String clientId, LeadStatus newStatus) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((c) {
        if (c.id == clientId) {
          final updated = Client(
            id: c.id,
            userId: c.userId,
            clientBrandName: c.clientBrandName,
            contactPerson: c.contactPerson,
            phone: c.phone,
            whatsapp: c.whatsapp,
            email: c.email,
            instagram: c.instagram,
            companyName: c.companyName,
            projectDetails: c.projectDetails,
            dealAmount: c.dealAmount,
            paymentStatus: c.paymentStatus,
            workDeadline: c.workDeadline,
            followUpDate: c.followUpDate,
            status: newStatus,
            notes: c.notes,
            createdAt: c.createdAt,
          );
          LocalDbService.instance.upsertClient(updated.toMap());
          return updated;
        }
        return c;
      }).toList(),
    );
  }

  Future<void> deleteClient(String clientId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((c) => c.id != clientId).toList());
    await LocalDbService.instance.deleteClient(clientId);
  }
}

