#!/usr/bin/env python3
"""Check conventional commit subjects and task-package traceability."""
from pathlib import Path
import re
import subprocess
import sys


def validate(message, branch):
    subject = message.splitlines()[0] if message else ''
    if subject.startswith(('Merge ', 'Revert ', 'fixup! ', 'squash! ')):
        return
    if not re.fullmatch(
        r'(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|wip)'
        r'(\([^\n()]+\))?!?:\s+\S.*', subject,
    ):
        raise ValueError('Use type(scope): summary, for example feat(chat): improve input')
    if branch.startswith('spec/'):
        footer = 'Spec: ' + branch.removeprefix('spec/')
        if footer not in message.splitlines():
            raise ValueError('Task-package commits require ' + footer)


if __name__ == '__main__':
    branch = subprocess.check_output(['git', 'branch', '--show-current'], text=True).strip()
    validate(Path(sys.argv[1]).read_text(), branch)
