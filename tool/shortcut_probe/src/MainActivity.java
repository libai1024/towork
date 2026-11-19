package com.towork.shortcutprobe;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ShortcutInfo;
import android.content.pm.ShortcutManager;
import android.graphics.drawable.Icon;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.DocumentsContract;
import android.view.WindowInsets;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public final class MainActivity extends Activity {
    private static final int SAVE_COMPONENT = 1;
    private TextView status;
    private Button exportButton;
    private String selectedPackage;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if (state != null) selectedPackage = state.getString("selectedPackage");
        ScrollView scroll = new ScrollView(this);
        LinearLayout content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        int spacing = (int) (24 * getResources().getDisplayMetrics().density);
        content.setPadding(spacing, spacing, spacing, spacing);
        scroll.addView(content);
        scroll.setOnApplyWindowInsetsListener((view, insets) -> {
            if (Build.VERSION.SDK_INT >= 30) {
                android.graphics.Insets bars = insets.getInsets(
                    WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            } else {
                view.setPadding(insets.getSystemWindowInsetLeft(), insets.getSystemWindowInsetTop(),
                    insets.getSystemWindowInsetRight(), insets.getSystemWindowInsetBottom());
            }
            return insets;
        });
        setContentView(scroll);
        addText(content, "ToWork 入口检测", 26);
        addText(content, "打开后会注册静态快问、静态语音、动态快问、动态语音四项入口。"
            + "请到系统“双触”菜单搜索“ToWork 入口检测”，展开后截图。选定任一入口后，双触会跳转到 ToWork 对应半屏。", 17);
        status = addText(content, "", 15);
        registerShortcuts();
        Button refresh = new Button(this);
        refresh.setText("刷新检测入口");
        refresh.setOnClickListener(view -> registerShortcuts());
        content.addView(refresh);
        addText(content, "导出双触组件", 22);
        addText(content, "选择系统快捷菜单组件，保存其 APK 和版本信息供兼容性分析。"
            + "优先选择名称含 QuickAccess、快捷菜单或智控的组件。完成后把 ZIP 发回当前对话。", 16);
        exportButton = new Button(this);
        exportButton.setText("选择系统组件并导出");
        exportButton.setOnClickListener(view -> chooseComponent());
        content.addView(exportButton);
        addText(content, "检测结束后可卸载“ToWork 入口检测”。", 15);
    }

    private TextView addText(LinearLayout parent, String text, int size) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(size);
        view.setPadding(0, 12, 0, 20);
        parent.addView(view);
        return view;
    }

    private void registerShortcuts() {
        ShortcutManager manager = getSystemService(ShortcutManager.class);
        try {
            List<ShortcutInfo> shortcuts = new ArrayList<>();
            for (boolean voice : new boolean[] {false, true}) {
                shortcuts.add(new ShortcutInfo.Builder(this, voice ? "dynamic_voice" : "dynamic_ask")
                    .setActivity(new ComponentName(this, MainActivity.class))
                    .setShortLabel(voice ? "动态语音" : "动态快问")
                    .setIcon(Icon.createWithResource(this, voice
                        ? R.drawable.ic_shortcut_quick_voice : R.drawable.ic_shortcut_quick_ask))
                    .setRank(voice ? 1 : 0)
                    .setIntent(ForwardActivity.intent(this, voice))
                    .build());
            }
            boolean published = manager.setDynamicShortcuts(shortcuts);
            status.setText("静态入口 " + manager.getManifestShortcuts().size()
                + " 项，动态入口 " + manager.getDynamicShortcuts().size() + " 项。"
                + (published ? "已完成注册。" : "系统限制刷新频率，请稍后重试。"));
        } catch (IllegalArgumentException | IllegalStateException | SecurityException error) {
            status.setText("注册失败，请截图反馈。" + error.getClass().getSimpleName());
        }
    }

    private void chooseComponent() {
        List<ApplicationInfo> candidates = new ArrayList<>();
        for (ApplicationInfo app : getPackageManager().getInstalledApplications(0)) {
            boolean system = (app.flags & (ApplicationInfo.FLAG_SYSTEM
                | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0;
            String name = (app.packageName + " " + app.sourceDir).toLowerCase(Locale.ROOT);
            if (system && (name.contains("quickaccessmenu") || name.contains("smartkey")
                || name.contains("fingerprint") || name.contains("motion")
                || app.packageName.equals("com.android.settings"))) {
                candidates.add(app);
            }
        }
        candidates.sort(Comparator.comparingInt(app ->
            (app.packageName + " " + app.sourceDir).toLowerCase(Locale.ROOT).contains("quickaccessmenu") ? 0 : 1));
        if (candidates.isEmpty()) {
            status.setText("未找到可导出的系统菜单组件，请先提供双触菜单的检测入口截图。");
            return;
        }
        String[] labels = new String[candidates.size()];
        for (int i = 0; i < labels.length; i++) {
            ApplicationInfo app = candidates.get(i);
            labels[i] = app.loadLabel(getPackageManager()) + "\n" + app.packageName;
        }
        new AlertDialog.Builder(this).setTitle("选择系统菜单组件")
            .setItems(labels, (dialog, index) -> {
                selectedPackage = candidates.get(index).packageName;
                Intent save = new Intent(Intent.ACTION_CREATE_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("application/zip")
                    .putExtra(Intent.EXTRA_TITLE, "towork-menu-" + selectedPackage + ".zip");
                try {
                    startActivityForResult(save, SAVE_COMPONENT);
                } catch (ActivityNotFoundException error) {
                    status.setText("系统文件保存器不可用，请先提供双触菜单的检测入口截图。");
                }
            }).setNegativeButton("取消", null).show();
    }

    @Override public void onSaveInstanceState(Bundle state) {
        state.putString("selectedPackage", selectedPackage);
        super.onSaveInstanceState(state);
    }

    @Override public void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != SAVE_COMPONENT || result != RESULT_OK || data == null || data.getData() == null) return;
        final Uri destination = data.getData();
        final String packageName = selectedPackage;
        exportButton.setEnabled(false);
        status.setText("正在导出系统组件，请保持此页面打开…");
        new Thread(() -> {
            String message;
            try {
                exportComponent(packageName, destination);
                message = "已保存 ZIP，请把文件发回当前对话。";
            } catch (IOException | PackageManager.NameNotFoundException | SecurityException error) {
                try {
                    DocumentsContract.deleteDocument(getContentResolver(), destination);
                } catch (Exception cleanupError) {
                    // Some document providers keep a partial file; report export failure below.
                }
                message = "导出失败，可重新选择组件和保存位置。" + error.getClass().getSimpleName();
            }
            final String outcome = message;
            runOnUiThread(() -> {
                if (isFinishing() || isDestroyed()) return;
                status.setText(outcome);
                exportButton.setEnabled(true);
            });
        }, "system-component-export").start();
    }

    private void exportComponent(String packageName, Uri destination)
        throws IOException, PackageManager.NameNotFoundException {
        PackageInfo component = getPackageManager().getPackageInfo(packageName, 0);
        ApplicationInfo app = component.applicationInfo;
        if ((app.flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) == 0) {
            throw new SecurityException("System component required");
        }
        OutputStream output = getContentResolver().openOutputStream(destination, "w");
        if (output == null) throw new IOException("Cannot open selected document");
        try (ZipOutputStream archive = new ZipOutputStream(output)) {
            archive.putNextEntry(new ZipEntry("device.txt"));
            archive.write(report(component).getBytes(StandardCharsets.UTF_8));
            archive.closeEntry();
            copyApk(archive, app.sourceDir, "component/base.apk");
            if (app.splitSourceDirs != null) {
                for (int i = 0; i < app.splitSourceDirs.length; i++) {
                    copyApk(archive, app.splitSourceDirs[i], "component/split-" + i + ".apk");
                }
            }
        }
    }

    private String report(PackageInfo component) {
        String installed = "not installed";
        try {
            PackageInfo towork = getPackageManager().getPackageInfo("com.towork.towork", 0);
            installed = towork.versionName + " (" + towork.versionCode + ")";
        } catch (PackageManager.NameNotFoundException ignored) {
            // Keep the missing-app state in the report.
        }
        ShortcutManager manager = getSystemService(ShortcutManager.class);
        return "Probe 1.0\nManufacturer " + Build.MANUFACTURER + "\nModel " + Build.MODEL
            + "\nBuild " + Build.DISPLAY + "\nAndroid " + Build.VERSION.RELEASE
            + "\nAPI " + Build.VERSION.SDK_INT + "\nToWork " + installed
            + "\nComponent " + component.packageName + "\nVersion " + component.versionName
            + " (" + component.versionCode + ")\nStatic " + manager.getManifestShortcuts().size()
            + "\nDynamic " + manager.getDynamicShortcuts().size() + "\n";
    }

    private void copyApk(ZipOutputStream archive, String path, String name) throws IOException {
        archive.putNextEntry(new ZipEntry(name));
        try (FileInputStream input = new FileInputStream(path)) {
            byte[] buffer = new byte[32768];
            int length;
            while ((length = input.read(buffer)) != -1) archive.write(buffer, 0, length);
        }
        archive.closeEntry();
    }
}
