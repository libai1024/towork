part of 'report_markdown.dart';

class _H2 extends _Block {
  const _H2(this.text);
  final String text;
}

class _H3 extends _Block {
  const _H3(this.text);
  final String text;
}

class _Para extends _Block {
  const _Para(this.text);
  final String text;
}

class _Bullets extends _Block {
  const _Bullets(this.items);
  final List<String> items;
}

class _Quote extends _Block {
  const _Quote(this.lines);
  final List<String> lines;
}

class _Table extends _Block {
  const _Table(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

class _Divider extends _Block {
  const _Divider();
}
