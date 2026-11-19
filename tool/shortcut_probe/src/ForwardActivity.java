package com.towork.shortcutprobe;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

public final class ForwardActivity extends Activity {
    static Intent intent(Context context, boolean voice) {
        return new Intent(Intent.ACTION_VIEW)
            .setClass(context, ForwardActivity.class)
            .putExtra("mode", voice ? "voice" : "ask");
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        boolean voice = "voice".equals(getIntent().getStringExtra("mode"));
        Intent target = new Intent(voice
            ? "com.towork.towork.action.QUICK_ASK_VOICE"
            : "com.towork.towork.action.QUICK_ASK")
            .setComponent(new ComponentName("com.towork.towork", "com.towork.towork.AssistActivity"))
            .putExtra("com.towork.towork.extra.SOURCE", "shortcut")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            startActivity(target);
        } catch (ActivityNotFoundException | SecurityException error) {
            Toast.makeText(this, "启动失败，请先安装官网 ToWork 最新版", Toast.LENGTH_LONG).show();
        }
        finish();
    }
}
