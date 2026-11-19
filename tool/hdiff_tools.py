"""Fetch checksum-pinned upstream HDiffPatch command-line tools."""
import hashlib
from pathlib import Path
import platform
import urllib.request
import zipfile

VERSION = '5.1.3'
ARCHIVES = {
    ('Darwin', 'arm64'): ('macos', '9e9d7318db1ea5607dbdde41e6614cfe5b73c589034b38ee91a79f4ca80a940c'),
    ('Darwin', 'x86_64'): ('macos', '9e9d7318db1ea5607dbdde41e6614cfe5b73c589034b38ee91a79f4ca80a940c'),
    ('Linux', 'x86_64'): ('linux64', '628963bf2ee9108a97260fa5eef44acd9ec94369b76090a957c9182b3abbb558'),
    ('Linux', 'aarch64'): ('linux_arm64', '03e404e16d06479deaba645a09ed5c06636778b083b82bc7fc932ba34425430b'),
}


def digest(path):
    with Path(path).open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def binaries(root):
    flavor, expected = ARCHIVES[(platform.system(), platform.machine())]
    directory = root / 'build/tools/hdiffpatch'
    directory.mkdir(parents=True, exist_ok=True)
    name = f'hdiffpatch_v{VERSION}_bin_{flavor}.zip'
    archive = directory / name
    if not archive.exists() or digest(archive) != expected:
        url = f'https://github.com/sisong/HDiffPatch/releases/download/v{VERSION}/{name}'
        temporary = archive.with_suffix('.download')
        with urllib.request.urlopen(url, timeout=60) as response, temporary.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        if digest(temporary) != expected:
            temporary.unlink()
            raise ValueError('HDiffPatch archive checksum mismatch')
        temporary.replace(archive)
    output = directory / flavor
    output.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as zipped:
        for program in ['hdiffz', 'hpatchz']:
            member = next(info for info in zipped.infolist() if Path(info.filename).name == program)
            target = output / program
            target.write_bytes(zipped.read(member))
            target.chmod(0o755)
    return output / 'hdiffz', output / 'hpatchz'
