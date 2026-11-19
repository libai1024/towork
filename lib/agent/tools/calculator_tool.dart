import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../agent_tool_registry.dart';

/// 精确四则运算。语言模型心算金额、比例经常差一位；这里用有理数算，
/// 0.1 + 0.2 就是 0.3，除不尽时才按指定位数四舍五入并明确标注。
class CalculatorTool implements AgentReadTool {
  const CalculatorTool();

  static const _maxLength = 500;
  static const _maxBits = 4096;

  @override
  String get name => 'calculate';

  @override
  JsonObject get schema => agentToolSchema(
    name,
    'Exact decimal arithmetic for amounts, totals, percentages and averages. '
    'Use it instead of mental math whenever a number is derived. Supports '
    '+ - * / ^ parentheses and a trailing % (15% = 0.15). No variables or '
    'functions.',
    {
      'expression': {
        'type': 'string',
        'maxLength': _maxLength,
        'description': 'e.g. "(1280.5 + 399) * 0.88" or "3600 * 15%".',
      },
      'scale': {
        'type': 'integer',
        'minimum': 0,
        'maximum': 12,
        'description': 'Fraction digits kept when the result does not terminate. Default 6.',
      },
    },
    required: const ['expression'],
  );

  @override
  Object? call(JsonObject args, AgentToolContext context) {
    requireToolKeys(
      args,
      const {'expression', 'scale'},
      required: const {'expression'},
    );
    final expression = args['expression'];
    final scale = args['scale'] ?? 6;
    if (expression is! String ||
        expression.length > _maxLength ||
        scale is! int ||
        scale < 0 ||
        scale > 12) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    try {
      final value = _Parser(_normalize(expression)).parse();
      final text = value.format(scale);
      return {
        'expression': expression,
        'result': text.value,
        if (text.rounded) 'rounded_to_scale': scale,
      };
    } on _CalculationError catch (error) {
      return {'expression': expression, 'error': error.code};
    }
  }

  /// 全角符号、乘除号和千分位逗号来自语音转写或粘贴的账单。
  static String _normalize(String source) {
    final buffer = StringBuffer();
    for (final rune in source.runes) {
      final char = String.fromCharCode(rune);
      final mapped = switch (char) {
        '×' || '✕' || '＊' => '*',
        '÷' || '／' => '/',
        '（' => '(',
        '）' => ')',
        '＋' => '+',
        '－' || '−' || '–' => '-',
        '％' => '%',
        '．' => '.',
        ',' || '，' || '_' || ' ' || '\t' || '\n' || '¥' || '￥' || r'$' => '',
        _ =>
          rune >= 0xff10 && rune <= 0xff19
              ? String.fromCharCode(rune - 0xff10 + 0x30)
              : char,
      };
      buffer.write(mapped);
    }
    return buffer.toString();
  }
}

class _CalculationError implements Exception {
  const _CalculationError(this.code);
  final String code;
}

class _Rational {
  _Rational(BigInt numerator, BigInt denominator)
    : assert(denominator != BigInt.zero) {
    final sign = denominator.isNegative ? -BigInt.one : BigInt.one;
    final divisor = numerator.gcd(denominator);
    final safe = divisor == BigInt.zero ? BigInt.one : divisor;
    this.numerator = numerator * sign ~/ safe;
    this.denominator = denominator * sign ~/ safe;
    if (this.numerator.bitLength > CalculatorTool._maxBits ||
        this.denominator.bitLength > CalculatorTool._maxBits) {
      throw const _CalculationError('too_large');
    }
  }
  late final BigInt numerator;
  late final BigInt denominator;

  _Rational operator +(_Rational other) => _Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );
  _Rational operator -(_Rational other) => _Rational(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );
  _Rational operator *(_Rational other) =>
      _Rational(numerator * other.numerator, denominator * other.denominator);
  _Rational operator /(_Rational other) {
    if (other.numerator == BigInt.zero) {
      throw const _CalculationError('division_by_zero');
    }
    return _Rational(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  _Rational operator -() => _Rational(-numerator, denominator);

  _Rational power(_Rational exponent) {
    if (exponent.denominator != BigInt.one ||
        exponent.numerator.abs() > BigInt.from(256)) {
      throw const _CalculationError('unsupported_exponent');
    }
    final n = exponent.numerator.toInt();
    if (n < 0 && numerator == BigInt.zero) {
      throw const _CalculationError('division_by_zero');
    }
    final count = n.abs();
    // 先估位数再求幂，避免为一个注定被拒绝的结果分配巨大整数。
    if (numerator.bitLength * count > CalculatorTool._maxBits ||
        denominator.bitLength * count > CalculatorTool._maxBits) {
      throw const _CalculationError('too_large');
    }
    final top = numerator.pow(count);
    final bottom = denominator.pow(count);
    return n < 0 ? _Rational(bottom, top) : _Rational(top, bottom);
  }

  ({String value, bool rounded}) format(int scale) {
    final scaled = numerator.abs() * BigInt.from(10).pow(scale);
    var quotient = scaled ~/ denominator;
    final remainder = scaled % denominator;
    // 四舍五入（half up），与日常记账一致。
    if (remainder * BigInt.two >= denominator) quotient += BigInt.one;
    final digits = quotient.toString().padLeft(scale + 1, '0');
    final whole = digits.substring(0, digits.length - scale);
    final fraction = digits
        .substring(digits.length - scale)
        .replaceFirst(RegExp(r'0+$'), '');
    final text = fraction.isEmpty ? whole : '$whole.$fraction';
    return (
      value: numerator.isNegative && quotient != BigInt.zero ? '-$text' : text,
      rounded: remainder != BigInt.zero,
    );
  }
}

/// expr := term (('+'|'-') term)*
/// term := unary (('*'|'/') unary)*
/// unary := ('+'|'-') unary | power
/// power := postfix ('^' unary)?
/// postfix := primary '%'*
/// primary := number | '(' expr ')'
class _Parser {
  _Parser(this.source);
  final String source;
  int _index = 0;
  int _depth = 0;

  _Rational parse() {
    if (source.isEmpty) throw const _CalculationError('invalid_expression');
    final value = _expression();
    if (_index != source.length) {
      throw const _CalculationError('invalid_expression');
    }
    return value;
  }

  String? get _peek => _index < source.length ? source[_index] : null;

  _Rational _expression() {
    var value = _term();
    while (_peek == '+' || _peek == '-') {
      final operator = source[_index++];
      final right = _term();
      value = operator == '+' ? value + right : value - right;
    }
    return value;
  }

  _Rational _term() {
    var value = _unary();
    while (_peek == '*' || _peek == '/') {
      final operator = source[_index++];
      final right = _unary();
      value = operator == '*' ? value * right : value / right;
    }
    return value;
  }

  _Rational _unary() {
    if (_peek == '+' || _peek == '-') {
      if (++_depth > 64) throw const _CalculationError('invalid_expression');
      final negative = source[_index++] == '-';
      final value = _unary();
      _depth--;
      return negative ? -value : value;
    }
    final base = _postfix();
    if (_peek == '^') {
      _index++;
      return base.power(_unary());
    }
    return base;
  }

  _Rational _postfix() {
    var value = _primary();
    while (_peek == '%') {
      _index++;
      value = value / _Rational(BigInt.from(100), BigInt.one);
    }
    return value;
  }

  _Rational _primary() {
    if (_peek == '(') {
      if (++_depth > 64) throw const _CalculationError('invalid_expression');
      _index++;
      final value = _expression();
      if (_peek != ')') throw const _CalculationError('invalid_expression');
      _index++;
      _depth--;
      return value;
    }
    final match = RegExp(r'\d+(?:\.\d+)?|\.\d+').matchAsPrefix(source, _index);
    if (match == null) throw const _CalculationError('invalid_expression');
    _index = match.end;
    final text = match.group(0)!;
    final dot = text.indexOf('.');
    if (dot < 0) return _Rational(BigInt.parse(text), BigInt.one);
    final fraction = text.substring(dot + 1);
    return _Rational(
      BigInt.parse('${dot == 0 ? '0' : text.substring(0, dot)}$fraction'),
      BigInt.from(10).pow(fraction.length),
    );
  }
}
