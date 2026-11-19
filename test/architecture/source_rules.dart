/// Import/export URIs, including conditional and part directives.
Iterable<String> localDirectives(String text) sync* {
  // Keep quoted strings intact while blanking comments so examples in comments
  // cannot become dependencies. Import URIs cannot contain triple-quoted text.
  final tokens = RegExp(
    r'''//[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"''',
  );
  final source = text.replaceAllMapped(tokens, (match) {
    final token = match[0]!;
    return token.startsWith('//') || token.startsWith('/*')
        ? token.replaceAll(RegExp(r'[^\n]'), ' ')
        : token;
  });
  final directives = RegExp(
    r'^\s*(?:import|export|part)\s+(?!of\b)([^;]+);',
    multiLine: true,
  );
  final strings = RegExp(r'''['"]([^'"]+)['"]''');
  for (final directive in directives.allMatches(source)) {
    for (final uri in strings.allMatches(directive[1]!)) {
      yield uri[1]!;
    }
  }
}

/// Explicit legacy imports can shrink as their domain types migrate.
String? externalDependencyViolation(String source, String uri) {
  if (!source.startsWith('domain/') && !source.startsWith('agent/')) {
    return null;
  }
  const legacy = {
    'domain/models/category.dart': {'dart:ui'},
    'domain/models/report.dart': {'dart:ui'},
    'domain/repositories/category_store.dart': {
      'package:flutter/material.dart',
    },
    'domain/repositories/data_table_store.dart': {
      'package:flutter_riverpod/flutter_riverpod.dart',
    },
    'domain/repositories/list_store.dart': {
      'package:flutter/foundation.dart',
      'package:flutter_riverpod/flutter_riverpod.dart',
    },
    'domain/repositories/quota_store.dart': {
      'package:flutter_riverpod/flutter_riverpod.dart',
    },
  };
  if (legacy[source]?.contains(uri) ?? false) return null;
  if (uri.startsWith('dart:') &&
      !const {
        'dart:io',
        'dart:ui',
        'dart:ffi',
        'dart:html',
        'dart:js_interop',
      }.contains(uri)) {
    return null;
  }
  if (uri.startsWith('package:') &&
      const {
        'characters',
        'crypto',
        'timezone',
        'lunar',
      }.contains(Uri.parse(uri).pathSegments.first)) {
    return null;
  }
  return 'keep UI, storage and host dependencies in adapters';
}

String? dependencyViolation(String source, String target) {
  final outerLayers = [
    'app/',
    'data/',
    'features/',
    'shell/',
    'core/',
    'theme/',
  ];
  if (source.startsWith('agent/') && outerLayers.any(target.startsWith)) {
    return 'Agent decisions depend on domain contracts';
  }
  if (source.startsWith('data/ai/') && target.startsWith('data/platform/')) {
    return 'model transport must receive its host policy from composition';
  }
  if (source.startsWith('domain/') &&
      (outerLayers.any(target.startsWith) || target.startsWith('agent/'))) {
    return 'domain must not depend on outer layers';
  }
  if (source.startsWith('data/') &&
      [
        'app/',
        'features/',
        'shell/',
        'core/',
        'theme/',
      ].any(target.startsWith)) {
    return 'data must not depend on presentation';
  }
  if (source.startsWith('app/') &&
      ['features/', 'shell/'].any(target.startsWith)) {
    return 'app must not depend on features or shell';
  }
  if (source.startsWith('features/')) {
    if (['data/', 'shell/'].any(target.startsWith)) {
      return 'features must use injected contracts';
    }
    if (target.startsWith('features/') &&
        source.split('/')[1] != target.split('/')[1]) {
      return 'compose features in shell or share a core component';
    }
  }
  if (source.startsWith('core/') &&
      ['features/', 'shell/', 'data/'].any(target.startsWith)) {
    return 'shared UI must not import feature pages or data implementations';
  }
  if (!source.startsWith('mock/') && target.startsWith('mock/')) {
    return 'legacy mock imports are forbidden';
  }
  return null;
}
