#!/usr/bin/env python3
"""Sync flutter_patcher's signed public files, objects before atomic manifests."""
import argparse
import hashlib
from pathlib import Path
import re
import shlex
import subprocess
import uuid


def sync(store, host, download_dir, ssh_command="ssh"):
    if not re.fullmatch(r'/(?:[a-zA-Z0-9_-]+/)*towork-dl', download_dir):
        raise ValueError('Invalid ToWork download directory')
    patch_dir = download_dir + '/patches'
    options = shlex.split(ssh_command)[1:]
    ssh = ['ssh', *options, host]
    allowed = re.compile(r'(objects/[a-f0-9]{32}/[a-f0-9]{64}\.fptc|manifests/[a-f0-9]{64}\.json)')
    files = sorted((path for path in store.rglob('*')
                    if path.is_file() and allowed.fullmatch(path.relative_to(store).as_posix())),
                   key=lambda path: (path.relative_to(store).parts[0] == 'manifests', str(path)))
    if not files:
        raise ValueError('No published patch files')
    for source in files:
        if source.is_symlink():
            raise ValueError('Publication must contain regular files')
        relative = source.relative_to(store).as_posix()
        parent = patch_dir + '/' + str(Path(relative).parent)
        temporary = parent + '/.upload-' + uuid.uuid4().hex
        subprocess.run(ssh + ['mkdir -p ' + shlex.quote(parent)], check=True)
        subprocess.run(['scp', *options, str(source), host + ':' + temporary], check=True)
        script = '''from pathlib import Path
import hashlib,os,json,base64,fcntl
source=Path(%r)
final=Path(%r)/%r
try:
    assert hashlib.sha256(source.read_bytes()).hexdigest()==%r
    source.chmod(0o644)
    with source.open('rb') as stream:
        os.fsync(stream.fileno())
    if %r:
        try:
            os.link(source,final)
        except FileExistsError:
            assert not final.is_symlink()
            assert hashlib.sha256(final.read_bytes()).hexdigest()==%r
    else:
        with (Path(%r)/'.upload.lock').open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            candidate=json.loads(source.read_text())
            fields=json.loads(base64.b64decode(candidate['payload']))
            if final.exists():
                current=json.loads(final.read_text())
                previous=json.loads(base64.b64decode(current['payload']))
                assert int(fields['revision'])>=int(previous['revision']), 'Publication revision would decrease'
                if fields['revision']==previous['revision']:
                    assert candidate['payload']==current['payload'], 'Conflicting publication revision'
            os.replace(source,final)
    descriptor=os.open(final.parent,os.O_RDONLY|os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)
finally:
    source.unlink(missing_ok=True)
''' % (temporary, patch_dir, relative, hashlib.sha256(source.read_bytes()).hexdigest(),
       relative.startswith('objects/'), hashlib.sha256(source.read_bytes()).hexdigest(), patch_dir)
        subprocess.run(ssh + ['python3 -c ' + shlex.quote(script)], check=True)
        print('Published ' + relative, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--store', type=Path, required=True)
    parser.add_argument('--host', required=True)
    parser.add_argument('--download-dir', required=True)
    parser.add_argument('--ssh-command', default='ssh', help='SSH options from _server_ssh.sh')
    args = parser.parse_args()
    sync(args.store.resolve(), args.host, args.download_dir, args.ssh_command)
