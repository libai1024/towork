# Domain model contracts

Models are organized by business area. New application and repository code imports `package:towork/domain/models/models.dart` or a specific model file. `lib/mock/models.dart` is an export-only compatibility entrypoint during import migration.

- Every stored property is final. Constructors defensively copy List/Map inputs into unmodifiable collections; they do not retain live views of caller-owned collections. Copy methods also snapshot replacement collections.
- Table cells intentionally remain `Map<String, String>`, matching current editing and rendering. No scalar/date/Color conversion is introduced. Template `seedRows` freezes both its outer list and each row map; history and AI-confirmation snapshots freeze their maps/lists as well.
- Nullable arguments on `copyWith` distinguish omitted (retain), non-null (replace), and explicit null (clear). This covers task metadata, category parent, message metadata, memory expiry/source references, report metadata, and column unit. Memory's `clearExpiry: true` remains supported and overrides `expiresAt`; new code should use `expiresAt: null`.
- Collection-owning constructors are no longer const: `Todo`, `MemoryEntry`, `Report`, `DataColumnDef`, `DataTableDef`, `DataRow`, `DataChangeLog`, `PendingRowChange`, `PendingAiBatch`, `DataTableTemplate`, and `QuotaState`. Remove const from these constructors and their enclosing literal lists. Scalar-only model constructors retain const compatibility.
- `DataColumnDef.type` preserves the existing string names. Construction validates them, and `fieldType` provides the corresponding enum. `currency` remains a money alias; unknown names throw `FormatException` instead of silently becoming text fields.
- Memory confidence is a finite number from 0 to 1. Invalid values throw `ArgumentError`. A reminder's mutually exclusive offset/absolute time contract is asserted for programmer-created values; eventual external input must be validated at its real data boundary.
- ISO week labels use the Thursday-based ISO week-year rule and UTC calendar arithmetic, preserving the input's year/month/day without DST day-count errors. Memory is expiring soon only during the next exact seven days, excluding already expired entries.

There is no domain-model JSON boundary in this mock application. No hypothetical API DTOs or serialization protocol have been added. Persisted input preference remains a primitive string in the local settings service.

`Color` remains on Category and ReportCategoryRef for compatibility with current constructors and presentation. These two files import only `dart:ui` for that value type; the other existing model files use Dart core types. A future API/storage schema can map a color identifier at that boundary without coupling the domain to an invented backend format.

Regression coverage: `test/domain_models_test.dart` uses pure unit tests (no widgets) for nullable copies, input/output collection aliasing, nested snapshots, cross-year and leap-year ISO weeks, expiry boundaries and type validation. The Flutter test runner supplies `dart:ui` for the two existing Color-based models.
