import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/audit/models/audit_sheet.dart';
import '../features/audit/models/audit_submission.dart';
import '../services/audit_sheet_service.dart';

final auditSheetServiceProvider = Provider<AuditSheetService>((ref) {
  return AuditSheetService();
});

class CreateAuditSheetParams {
  final AuditSheet auditSheet;

  CreateAuditSheetParams({required this.auditSheet});
}

final createAuditSheetProvider = FutureProvider.family<AuditSheet, CreateAuditSheetParams>((ref, params) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.createAuditSheet(params.auditSheet);
}); 

final auditSheetsProvider = FutureProvider.family<List<AuditSheet>, ({String orgId})>((ref, params) async {
  try {
    print('AuditSheetsProvider: Fetching sheets for orgId: ${params.orgId}');
    final service = ref.watch(auditSheetServiceProvider);
    final sheets = await service.getAuditSheets(params.orgId);
    print('AuditSheetsProvider: Successfully fetched ${sheets.length} sheets');
    return sheets;
  } catch (e, stackTrace) {
    print('AuditSheetsProvider: Error fetching sheets: $e');
    print('AuditSheetsProvider: Stack trace: $stackTrace');
    rethrow;
  }
});

final deleteAuditSheetProvider = FutureProvider.family<void, String>((ref, id) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.deleteAuditSheet(id);
});

final updateAuditSheetProvider = FutureProvider.family<AuditSheet, AuditSheet>((ref, auditSheet) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.updateAuditSheet(auditSheet);
});

final auditSheetSubmissionsProvider = FutureProvider.family<List<AuditSubmission>, String>((ref, auditSheetId) async {
  final service = ref.watch(auditSheetServiceProvider);
  return service.getAuditSheetSubmissions(auditSheetId);
}); 