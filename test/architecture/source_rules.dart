/// Local import/export URIs, including conditional and part directives.
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

String? dependencyViolation(String source, String target) {
  final outerLayers = [
    'app/',
    'data/',
    'features/',
    'shell/',
    'core/',
    'theme/',
  ];
  if (source.startsWith('domain/') && outerLayers.any(target.startsWith)) {
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
