import '../models/models.dart';
import 'list_store.dart';

abstract class ReportStore extends ListStore<Report> {
  ReportStore(super.initial);
  List<Report> get visible;
  Report? byId(String? id);
  void markRead(String id, {bool read = true});
  Report? softDelete(String id);
  void restore(String id);
  Report startGeneration({
    required DateTime periodStart,
    required DateTime periodEnd,
    required ReportType type,
    required String periodLabel,
    required List<ReportCategoryRef> categories,
  });
  void regenerate(String id);
  void stopGeneration(String id);
}
