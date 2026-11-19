#!/usr/bin/env python3
"""Exercise release and hook failure paths without credentials or network."""
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile
from types import SimpleNamespace
from unittest.mock import patch

from check_commit_message import validate
from check_release_version import read_version, validate_tag
from check_size_baseline import violations
from prepare_android_signing import prepare, property_value
from promote_android_release import promote
from promote_macos_release import promote as promote_macos
from verify_android_artifact import verify_badging
import publish_github_release

ROOT = Path(__file__).resolve().parents[1]


def rejects(action):
    try:
        action()
    except ValueError:
        return
    raise AssertionError('Expected the invalid input to fail')


def check_android_dry_run(directory, badging):
    project = directory / 'publish-fixture'
    (project / 'tool').mkdir(parents=True)
    for name in ['publish_android.sh', 'check_release_version.py', 'verify_android_artifact.py',
                 'generate_android_patches.py', 'hdiff_tools.py', 'verify_code_host.py']:
        shutil.copy2(ROOT / 'tool' / name, project / 'tool' / name)
    (project / 'pubspec.yaml').write_text('version: 1.2.3+4\n')
    apk = project / 'build/app/outputs/flutter-apk/app-release.apk'
    apk.parent.mkdir(parents=True)
    with zipfile.ZipFile(apk, 'w') as archive:
        policy = json.dumps({'application_id': 'com.towork.towork', 'version_code': '4',
                             'strategy': 'bytecode', 'root_key': 'fixture',
                             'fptc_key': 'fixture', 'keys': 'fixture'})
        archive.writestr('assets/flutter_patcher/host-trust.json', json.dumps({
            'policy': policy, 'policy_sha256': hashlib.sha256(policy.encode()).hexdigest(),
            'url': 'https://zhaozhaoyue.top/dl/towork/patches', 'fingerprint': 'f' * 64,
        }))
    sdk = project / 'sdk'
    build_tools = sdk / 'build-tools/36.0.0'
    build_tools.mkdir(parents=True)
    aapt = build_tools / 'aapt'
    aapt.write_text(f'#!/usr/bin/env python3\nprint({badging!r})\n')
    signer = build_tools / 'apksigner'
    signer.write_text(
        '#!/usr/bin/env bash\n'
        'if [[ "${2:-}" == "--print-certs" ]]; then\n'
        '  echo "Signer #1 certificate DN: CN=Android Debug, O=Android, C=US"\n'
        f'  echo "Signer #1 certificate SHA-256 digest: {"a" * 64}"\n'
        'fi\n'
    )
    binary = project / 'bin'
    binary.mkdir()
    git = binary / 'git'
    git.write_text('#!/usr/bin/env bash\nif [[ "$1" == "rev-parse" ]]; then echo fixture; fi\n')
    for executable in [aapt, signer, git]:
        executable.chmod(0o755)
    environment = os.environ | {
        'ANDROID_HOME': str(sdk),
        'PATH': f'{binary}{os.pathsep}{os.environ["PATH"]}',
        'TOWORK_SKIP_BUILD': '1',
        'TOWORK_DRY_RUN': '1',
    }
    result = subprocess.run(
        ['bash', 'tool/publish_android.sh', '测试发布'], cwd=project,
        env=environment, text=True, errors='replace', capture_output=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert 'unbound variable' not in result.stderr, result.stderr
    assert 'DRY RUN：产物写到' in result.stdout, result.stdout
    manifest = json.loads((project / 'build/releases/1.2.3+4/latest.json').read_text())
    assert manifest['android']['certSha256'] == 'a' * 64
    assert manifest['releaseNotes'] == ['测试发布']
    assert manifest['android']['full']['sha256'] == hashlib.sha256(apk.read_bytes()).hexdigest()


def main():
    for path in [*ROOT.glob('tool/*.sh'), *ROOT.glob('.githooks/*')]:
        subprocess.run(['bash', '-n', str(path)], check=True)
    for path in ROOT.glob('tool/*.py'):
        compile(path.read_text(), str(path), 'exec')
    for path in ROOT.glob('.github/workflows/*.yml'):
        for action in re.findall(r'uses:\s*(\S+)', path.read_text()):
            assert action.startswith('./') or re.fullmatch(r'[^@]+@[a-f0-9]{40}', action), action
    quality = (ROOT / '.github/workflows/flutter.yml').read_text()
    release = (ROOT / '.github/workflows/release.yml').read_text()
    for job in ['quality', 'native-build', 'android-device', 'ios-device']:
        section = re.split(r'^  [a-z-]+:$', quality.split(f'  {job}:\n', 1)[1], maxsplit=1, flags=re.MULTILINE)[0]
        assert 'bash tool/fetch_asr_models.sh' in section.split('\n\n  ', 1)[0], job
    from mobile_ci_scope import check_results, required_platforms
    assert required_platforms(['android/app/build.gradle.kts']) == {'android'}
    assert required_platforms(['ios/Runner/AppDelegate.swift']) == {'ios'}
    assert required_platforms(['docs/note.md']) == set()
    for path in ['pubspec.lock', 'lib/data/platform/apple_distribution.dart', '.github/workflows/flutter.yml', 'new-root/x']:
        assert required_platforms([path]) == {'ios', 'android', 'macos'}
    jobs = {key: {'result': 'success'} for key in ['scope', 'quality', 'android-device']}
    jobs['scope']['outputs'] = {'android': 'true', 'ios': 'false', 'macos': 'false'}
    for key in ['ios-device', 'native-build']:
        jobs[key] = {'result': 'skipped'}
    check_results(jobs)
    for state in ['skipped', 'failure', 'cancelled']:
        try:
            check_results(dict(jobs, **{'android-device': {'result': state}}))
        except ValueError:
            pass
        else:
            raise AssertionError(f'Required Android result accepted: {state}')
    assert 'bash tool/check.sh' in quality and 'check_size_baseline.py' in quality
    assert 'workflow_call:' in quality and 'needs: quality' in release
    assert 'tool/verify_android_artifact.py' in (ROOT / 'tool/publish_android.sh').read_text()
    for path in ['.github/dependabot.yml', '.github/pull_request_template.md',
                 '.github/ISSUE_TEMPLATE/bug_report.yml', '.github/ISSUE_TEMPLATE/feature_request.yml']:
        assert (ROOT / path).is_file(), path

    assert read_version('version: 1.2.3+4\n') == ('1.2.3', 4)
    for value in ['version: 1.2.3', 'version: 1.2.3+0', 'version: unsafe+4']:
        rejects(lambda: read_version(value))
    validate_tag('v1.2.3+4', '1.2.3', 4)
    rejects(lambda: validate_tag('v1.2.3', '1.2.3', 4))
    validate('feat(chat): improve input\n\nSpec: example', 'spec/example')
    rejects(lambda: validate('feat: missing footer', 'spec/example'))
    rejects(lambda: validate('misc update', 'codex/example'))
    assert not violations({'a.dart': 600}, {'a.dart': 550})
    assert violations({'a.dart': 600}, {'a.dart': 601})
    assert violations({}, {'a.dart': 600})
    assert not violations({'a.dart': 600}, {'b.dart': 550}, {'b.dart': 'a.dart'})

    good = ("package: name='com.towork.towork' versionCode='4' versionName='1.2.3'\n"
            "application-label:'towork'\nnative-code: 'arm64-v8a'\n")
    verify_badging(good, '1.2.3', 4)
    for bad in [good + 'application-debuggable\n', good.replace("'towork'", "'towork 自动化测试'"),
                good.replace('arm64-v8a', 'x86_64'), good.replace("versionCode='4'", "versionCode='5'")]:
        rejects(lambda: verify_badging(bad, '1.2.3', 4))

    with tempfile.TemporaryDirectory(prefix='towork-delivery-') as temporary:
        directory = Path(temporary)
        check_android_dry_run(directory, good)
        (directory / 'android').mkdir()
        rejects(lambda: prepare(directory, directory, {}))
        env = {'ANDROID_KEYSTORE_BASE64': base64.b64encode(b'fixture-keystore').decode(),
               'ANDROID_KEYSTORE_PASSWORD': 'fixture: secret\\value', 'ANDROID_KEY_ALIAS': 'fixture',
               'ANDROID_KEY_PASSWORD': 'fixture\npassword'}
        prepare(directory, directory, env)
        assert (directory / 'towork-release.keystore').stat().st_mode & 0o777 == 0o600
        assert property_value('中😀') == '\\u4e2d\\ud83d\\ude00'
        assert r'fixture\:\ some' == property_value('fixture: some')
        rejects(lambda: prepare(directory, directory, env))
        apk = directory / 'android/towork-1.2.3-4-arm64.apk'
        apk.write_bytes(b'fixture-apk')
        digest = hashlib.sha256(apk.read_bytes()).hexdigest()
        staged_name = f'latest.{digest}.json'
        manifest = {'versionCode': 4, 'android': {'full': {
            'url': str(apk.relative_to(directory)), 'sha256': digest, 'size': apk.stat().st_size,
        }}}
        staged = directory / staged_name
        staged.write_text(json.dumps(manifest))
        promote(directory, staged_name)
        assert not staged.exists() and (directory / 'latest.json').exists()
        live = json.loads((directory / 'latest.json').read_text())
        mac = {'versionName': '1.0.0', 'downloadUrl': 'macos/towork-1.0.0-1-universal.dmg'}
        live['macos'] = mac
        ios = {'storeUrl': 'https://apps.apple.com/app/id123', 'build': 3}
        live['ios'] = ios
        (directory / 'latest.json').write_text(json.dumps(live))
        manifest['macos'] = {'downloadUrl': None}
        manifest['ios'] = {'storeUrl': None}
        manifest['versionCode'] = 3
        staged.write_text(json.dumps(manifest))
        rejects(lambda: promote(directory, staged_name))
        assert json.loads((directory / 'latest.json').read_text())['versionCode'] == 4
        manifest['versionCode'] = 5
        manifest['android']['full']['size'] += 1
        staged.write_text(json.dumps(manifest))
        rejects(lambda: promote(directory, staged_name))
        rejects(lambda: promote(directory, '../latest.json'))
        manifest['android']['full']['size'] -= 1
        manifest['versionCode'] = 5
        staged.write_text(json.dumps(manifest))
        apk.rename(directory / 'android' / f'.upload.{digest}.apk')
        promote(directory, staged_name)
        assert apk.exists() and json.loads((directory / 'latest.json').read_text())['versionCode'] == 5

        patch_bytes = b'delta'
        patch_digest = hashlib.sha256(patch_bytes).hexdigest()
        base_digest = 'a' * 64
        patch_name = f'android/towork-5-to-6-{base_digest[:16]}-{digest[:16]}.hpatch'
        manifest['versionCode'] = 6
        manifest['android']['patches'] = [{
            'format': 'hdiffpatch', 'fromVersionCode': 5, 'fromSha256': base_digest,
            'url': patch_name, 'sha256': patch_digest, 'size': len(patch_bytes),
        }]
        staged.write_text(json.dumps(manifest))
        patch_stage = directory / 'android' / f'.upload.{patch_digest}.hpatch'
        patch_stage.write_bytes(b'bad')
        rejects(lambda: promote(directory, staged_name))
        assert json.loads((directory / 'latest.json').read_text())['versionCode'] == 5
        patch_stage.write_bytes(patch_bytes)
        promote(directory, staged_name)
        assert (directory / patch_name).read_bytes() == patch_bytes
        final_manifest = json.loads((directory / 'latest.json').read_text())
        assert final_manifest['versionCode'] == 6 and final_manifest['macos'] == mac
        assert final_manifest['ios'] == ios

        folder = directory / 'macos'
        folder.mkdir()
        dmg = b'fixture-disk-image'
        checksum = hashlib.sha256(dmg).hexdigest()
        info = {'versionName': '1.0.1', 'versionCode': 2, 'size': len(dmg),
                'sha256': checksum, 'downloadUrl': 'macos/towork-1.0.1-2-universal.dmg'}
        upload = folder / f'.upload.{checksum}.dmg'
        metadata = folder / f'.release.{checksum}.json'
        metadata.write_text(json.dumps(info))
        upload.write_bytes(b'partial')
        rejects(lambda: promote_macos(directory, checksum))
        assert json.loads((directory / 'latest.json').read_text()) == final_manifest
        upload.write_bytes(dmg)
        promote_macos(directory, checksum)
        assert (directory / info['downloadUrl']).read_bytes() == dmg
        expected = dict(final_manifest, macos=info)
        assert json.loads((directory / 'latest.json').read_text()) == expected
        metadata.write_text(json.dumps(info))
        promote_macos(directory, checksum)
        assert json.loads((directory / 'latest.json').read_text()) == expected

        release_dir = directory / 'release'
        release_dir.mkdir()
        release_apk = release_dir / 'fixture.apk'
        release_apk.write_bytes(b'fixture-apk')
        release_digest = 'sha256:' + digest
        published = {'draft': False, 'assets': [{'name': 'fixture.apk', 'digest': release_digest}]}
        with patch.object(publish_github_release, 'gh', return_value=SimpleNamespace(stdout=json.dumps(published))) as runner:
            publish_github_release.publish('v1.2.3+4', release_dir)
            assert runner.call_count == 1
        with patch.object(publish_github_release, 'gh', return_value=SimpleNamespace(stdout=json.dumps({'draft': True, 'assets': []}))) as runner:
            publish_github_release.publish('v1.2.3+4', release_dir)
            assert runner.call_args_list[1].args[:2] == ('release', 'upload')
            assert runner.call_args_list[2].args == ('release', 'edit', 'v1.2.3+4', '--draft=false')
        published['assets'][0]['digest'] = 'sha256:other'
        with patch.object(publish_github_release, 'gh', return_value=SimpleNamespace(stdout=json.dumps(published))):
            rejects(lambda: publish_github_release.publish('v1.2.3+4', release_dir))
    print('Delivery checks passed: workflow pins, scripts, versions, signing, hooks, size ratchet and atomic promotion.')


if __name__ == '__main__':
    main()
