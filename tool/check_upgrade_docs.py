#!/usr/bin/env python3
"""Check upgrade documentation links and the paths in its test commands."""
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
FILES = [ROOT / name for name in [
    'AGENTS.md', 'CONTRIBUTING.md', 'README.md', 'DESIGN.md',
    'docs/ARCHITECTURE.md', 'docs/release/README.md',
    'docs/standards/CODING.md', 'docs/standards/TESTING.md',
    'docs/standards/AGENT-TOOLS.md', 'docs/upgrade/HANDOFF.md',
    'docs/upgrade/QUICK-ASSIST.md', 'docs/upgrade/VERIFICATION.md',
]]


def main():
    errors = []
    for path in FILES:
        if not path.is_file():
            errors.append(f'Missing documentation: {path.relative_to(ROOT)}')
            continue
        source = path.read_text()
        for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', source):
            url = urlsplit(target)
            if url.scheme or not url.path:
                continue
            destination = (path.parent / unquote(url.path)).resolve()
            if not destination.exists():
                errors.append(f'{path.relative_to(ROOT)} -> {target}')
        if path.parent.name == 'standards':
            for target in re.findall(r'(?<!\w)((?:test|integration_test)/[\w/.-]+\.dart)', source):
                if not (ROOT / target).is_file():
                    errors.append(f'Invalid test command path: {target}')
    for required in ['CODING.md', 'TESTING.md', 'AGENT-TOOLS.md', 'DESIGN.md']:
        if required not in (ROOT / 'CONTRIBUTING.md').read_text():
            errors.append(f'CONTRIBUTING does not link {required}')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'Upgrade documentation passed: {len(FILES)} files and their local links/test paths.')


if __name__ == '__main__':
    main()
