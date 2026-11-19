#!/usr/bin/env python3
"""Materialize CI signing secrets without logging their values."""
import base64
import os
from pathlib import Path


def property_value(value):
    escapes = {'\n': '\\n', '\r': '\\r', '\t': '\\t'}
    result = []
    for char in value:
        if char in '\\:=#! ':
            result.append('\\' + char)
        elif char in escapes:
            result.append(escapes[char])
        elif ord(char) > 127:
            encoded = char.encode('utf-16-be')
            for offset in range(0, len(encoded), 2):
                result.append('\\u' + encoded[offset:offset + 2].hex())
        else:
            result.append(char)
    return ''.join(result)


def prepare(root, temporary, environ):
    keys = ['ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD',
            'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD']
    missing = [key for key in keys if not environ.get(key)]
    if missing:
        raise ValueError('Missing signing secrets: ' + ', '.join(missing))
    keystore = temporary / 'towork-release.keystore'
    properties = root / 'android/key.properties'
    if keystore.exists() or properties.exists():
        raise ValueError('Signing files already exist; use a fresh runner')
    material = base64.b64decode(environ[keys[0]], validate=True)
    if not material:
        raise ValueError('Signing keystore is empty')
    values = {
        'storeFile': str(keystore.resolve()),
        'storePassword': environ[keys[1]],
        'keyAlias': environ[keys[2]],
        'keyPassword': environ[keys[3]],
    }
    for path, content in [
        (keystore, material),
        (properties, ''.join(f'{key}={property_value(value)}\n'
                             for key, value in values.items()).encode()),
    ]:
        with path.open('xb') as stream:
            os.chmod(path, 0o600)
            stream.write(content)


if __name__ == '__main__':
    prepare(Path(__file__).resolve().parents[1],
            Path(os.environ['RUNNER_TEMP']), os.environ)
    print('Runner signing files prepared.')
