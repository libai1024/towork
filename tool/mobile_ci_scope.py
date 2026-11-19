"""Classify changed paths for the mobile quality jobs. Unknown paths run both."""
import argparse
import json
import os
import subprocess


def required_platforms(paths):
    result = set()
    for path in paths:
        if path.startswith(('docs/', 'screenshots/')) or ('/' not in path and path.endswith('.md')):
            continue
        if path.startswith('android/'):
            result.add('android')
        elif path.startswith('ios/'):
            result.add('ios')
        elif path.startswith('macos/'):
            result.add('macos')
        else:
            return {'android', 'ios', 'macos'}
    return result


def check_results(jobs):
    scope = jobs['scope']['outputs']
    required = {'scope': True, 'quality': True}
    for job, platform in [('android-device', 'android'), ('ios-device', 'ios'), ('native-build', 'macos')]:
        if scope.get(platform) not in ('true', 'false'):
            raise ValueError(f'Missing classification for {platform}')
        required[job] = scope[platform] == 'true'
    for job, expected in required.items():
        status = jobs[job]['result']
        if status != ('success' if expected else 'skipped'):
            raise ValueError(f'{job} ended with {status}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default='')
    parser.add_argument('--head', default='HEAD')
    parser.add_argument('--check-results', action='store_true')
    args = parser.parse_args()
    if args.check_results:
        check_results(json.loads(os.environ['RESULTS']))
        return
    platforms = {'android', 'ios', 'macos'}
    if args.base and set(args.base) != {'0'}:
        diff = subprocess.run(['git', 'diff', '--no-renames', '--name-only', '-z',
                               args.base, args.head, '--'], stdout=subprocess.PIPE)
        if diff.returncode == 0:
            platforms = required_platforms(os.fsdecode(diff.stdout).split('\0')[:-1])
    for platform in ('android', 'ios', 'macos'):
        print(f'{platform}={str(platform in platforms).lower()}')


if __name__ == '__main__':
    main()
