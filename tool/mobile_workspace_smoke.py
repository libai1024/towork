#!/usr/bin/env python3
"""Exercise one installed simulator app across an actual process restart."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = 'com.towork.towork'
TARGET = 'integration_test/fixtures/mobile_workspace_smoke.dart'


def command(*args, check=True, capture=False):
    return subprocess.run(args, check=check, cwd=ROOT, text=True,
                          stdout=subprocess.PIPE if capture else None,
                          stderr=subprocess.PIPE if capture else None)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('platform', choices=['android', 'ios'])
    parser.add_argument('device')
    parser.add_argument('--artifacts', type=Path, required=True)
    args = parser.parse_args()
    android = args.platform == 'android'
    device = args.device
    if android:
        if not re.fullmatch(r'emulator-\d+', device):
            parser.error('An Android emulator serial is required')
    elif not re.fullmatch(r'[0-9A-Fa-f-]{36}', device):
        parser.error('An iOS simulator UUID is required')
    out = args.artifacts.resolve()
    out.mkdir(exist_ok=True, parents=True)
    run = uuid.uuid4().hex
    adb = ['adb', '-s', device]
    sim = ['xcrun', 'simctl']
    start = time.monotonic()
    build = ['flutter', 'build', 'apk' if android else 'ios', '--debug', '--no-pub',
             '--target', TARGET, f'--dart-define=TOWORK_SMOKE_RUN={run}']
    if not android:
        build.append('--simulator')
    command(*build)
    built = time.monotonic()
    if android:
        command(*adb, 'install', '-r', 'build/app/outputs/flutter-apk/app-debug.apk')
        command(*adb, 'shell', 'am', 'force-stop', BUNDLE)
        command(*adb, 'shell', 'am', 'start', '-n', BUNDLE+'/.AssistActivity')
    else:
        command(*sim, 'install', device, 'build/ios/iphonesimulator/Runner.app')
        command(*sim, 'terminate', device, BUNDLE, check=False, capture=True)
        command(*sim, 'launch', device, BUNDLE)
        container = Path(command(*sim,'get_app_container',device,BUNDLE,'data',capture=True).stdout.strip())
    launched = time.monotonic()

    def read(name):
        relative = f'mobile-smoke/{run}/{name}.json'
        if android:
            res = command(*adb, 'shell', 'run-as', BUNDLE, 'cat', 'files/'+relative, check=False, capture=True)
            if res.returncode:
                return None
            raw = res.stdout
        else:
            path = container/'Library/Application Support'/relative
            if not path.exists():
                return None
            raw = path.read_text()
        value = json.loads(raw)
        assert value['run'] == run, value
        return value

    def wait(name):
        deadline = time.monotonic()+90
        while time.monotonic()<deadline:
            failed = read('failure')
            if failed:
                raise RuntimeError(failed)
            value = read(name)
            if value:
                return value
            time.sleep(.4)
        raise TimeoutError(name)

    try:
        first = wait('ready')
        created = wait('created')
        if android:
            command(*adb, 'shell', 'am', 'force-stop', BUNDLE)
            command(*adb, 'shell', 'am', 'start', '-n', BUNDLE+'/.MainActivity')
        else:
            command(*sim,'terminate',device,BUNDLE)
            command(*sim,'launch',device,BUNDLE)
        second = wait('reopened')
        assert first['pid'] != second['pid'] and created['pid'] == first['pid']
        assert first['version'] == second['version'] == 2 and created['id'] == first['id'] == second['id']
        record = dict(platform=args.platform, device=device, created=created, first=first, second=second,
                      build_seconds=round(built-start,2), install_launch_seconds=round(launched-built,2),
                      journey_seconds=round(time.monotonic()-launched,2))
        (out/'result.json').write_text(json.dumps(record,indent=2)+'\n')
        print(json.dumps(record))
    except Exception:
        if android:
            with (out/'failure.png').open('wb') as screenshot:
                subprocess.run([*adb,'exec-out','screencap','-p'],stdout=screenshot,check=False)
            log = command(*adb,'logcat','-d','-t','2000','flutter:I','AndroidRuntime:E','*:S',capture=True,check=False)
        else:
            command(*sim,'io',device,'screenshot',str(out/'failure.png'),check=False)
            log = command(*sim,'spawn',device,'log','show','--last','3m','--predicate','process == "Runner"',capture=True,check=False)
        (out/'failure.log').write_text(log.stdout+log.stderr)
        raise


if __name__ == '__main__':
    main()
