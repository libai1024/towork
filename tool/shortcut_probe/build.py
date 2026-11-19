#!/usr/bin/env python3
"""Build the standalone shortcut diagnostic with the installed Android SDK."""

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def main():
    source = Path(__file__).resolve().parent
    root = source.parent.parent
    sdk = Path(os.environ.get("ANDROID_HOME", Path.home() / "Library/Android/sdk"))
    java = Path(os.environ.get(
        "JAVA_HOME", "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    ))
    os.environ["JAVA_HOME"] = str(java)
    tools = sdk / "build-tools/36.0.0"
    platform = sdk / "platforms/android-36/android.jar"
    output = root / "build/shortcut-probe"
    output.mkdir(parents=True, exist_ok=True)
    key = output / "debug.keystore"
    if not key.exists():
        run(java / "bin/keytool", "-genkeypair", "-keystore", key,
            "-storepass", "android", "-keypass", "android", "-alias", "androiddebugkey",
            "-dname", "CN=ToWork Entry Probe,O=ToWork,C=CN", "-keyalg", "RSA",
            "-keysize", "2048", "-validity", "3650")
    apk = output / "towork-shortcut-probe-1.apk"
    with tempfile.TemporaryDirectory(prefix="compile-", dir=output) as directory:
        work = Path(directory)
        resources = work / "res"
        shutil.copytree(source / "res", resources)
        (resources / "drawable").mkdir()
        app_resources = root / "android/app/src/main/res"
        for name in ("ic_shortcut_quick_ask.xml", "ic_shortcut_quick_voice.xml"):
            shutil.copy2(app_resources / "drawable" / name, resources / "drawable" / name)
        shutil.copy2(app_resources / "values/ic_launcher_colors.xml", resources / "values")
        compiled = work / "resources.zip"
        generated = work / "generated"
        classes = work / "classes"
        dex = work / "dex"
        for directory in (generated, classes, dex):
            directory.mkdir()
        unsigned = work / "unsigned.apk"
        run(tools / "aapt2", "compile", "--dir", resources, "-o", compiled)
        run(tools / "aapt2", "link", "-o", unsigned, "-I", platform,
            "--manifest", source / "AndroidManifest.xml", "--java", generated, compiled)
        java_files = sorted((source / "src").glob("*.java")) + sorted(generated.rglob("*.java"))
        run(java / "bin/javac", "-encoding", "UTF-8", "-source", "8", "-target", "8",
            "-classpath", platform, "-d", classes, *java_files)
        run(tools / "d8", "--release", "--min-api", "26", "--lib", platform,
            "--output", dex, *sorted(classes.rglob("*.class")))
        with zipfile.ZipFile(unsigned, "a") as archive:
            for file in sorted(dex.glob("*.dex")):
                archive.write(file, file.name)
        aligned = work / "aligned.apk"
        run(tools / "zipalign", "-f", "4", unsigned, aligned)
        run(tools / "apksigner", "sign", "--ks", key, "--ks-pass", "pass:android",
            "--key-pass", "pass:android", "--out", apk, aligned)
    run(tools / "apksigner", "verify", apk)
    metadata = subprocess.check_output([str(tools / "aapt2"), "dump", "badging", str(apk)], text=True)
    expected = "package: name='com.towork.shortcutprobe' versionCode='1' versionName='1.0'"
    if expected not in metadata or "application-label:'ToWork 入口检测'" not in metadata:
        raise RuntimeError("Unexpected diagnostic APK metadata")
    print(apk)
    print(f"Bytes {apk.stat().st_size}")
    print(f"SHA256 {hashlib.sha256(apk.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
