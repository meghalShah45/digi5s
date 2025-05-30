import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/audit/models/audit_sheet.dart';
import '../services/audit_sheet_service.dart';

final auditSheetServiceProvider = Provider<AuditSheetService>((ref) {
  return AuditSheetService();
});

class CreateAuditSheetParams {
  final AuditSheet auditSheet;
  final String zoneId;

  CreateAuditSheetParams({required this.auditSheet, required this.zoneId});
}

final createAuditSheetProvider = FutureProvider.family<AuditSheet, CreateAuditSheetParams>((ref, params) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.createAuditSheet(params.auditSheet, params.zoneId);
}); 

final auditSheetsProvider = FutureProvider.family<List<AuditSheet>, String>((ref, orgId) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.getAuditSheets(orgId);
});

final deleteAuditSheetProvider = FutureProvider.family<void, String>((ref, id) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.deleteAuditSheet(id);
});

final updateAuditSheetProvider = FutureProvider.family<AuditSheet, AuditSheet>((ref, auditSheet) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.updateAuditSheet(auditSheet);
}); 