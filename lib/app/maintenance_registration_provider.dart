import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_maintenance.dart';

final maintenanceRegistrationProvider = StateProvider<MaintenanceRegistration>(
  (ref) => MaintenanceRegistration.foregroundOnly,
);
