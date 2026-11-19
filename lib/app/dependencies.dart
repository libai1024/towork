import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/mock_chat_service.dart';
import '../domain/repositories/chat_gateway.dart';

/// Application composition: features depend on contracts, never mock services.
final chatGatewayProvider = Provider<ChatGateway>((ref) => MockChatService());
