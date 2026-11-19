package com.towork.shortcutprobe;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.os.Bundle;

public final class LegacyShortcutActivity extends Activity {
    @SuppressWarnings("deprecation")
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        if (Intent.ACTION_CREATE_SHORTCUT.equals(getIntent().getAction())) {
            boolean voice = getIntent().getComponent().getClassName().endsWith("LegacyVoice");
            int size = Math.max(1, (int) (48 * getResources().getDisplayMetrics().density));
            Bitmap icon = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            Drawable drawable = getDrawable(voice
                ? R.drawable.ic_shortcut_quick_voice : R.drawable.ic_shortcut_quick_ask);
            drawable.setBounds(0, 0, size, size);
            drawable.draw(new Canvas(icon));
            setResult(RESULT_OK, new Intent()
                .putExtra(Intent.EXTRA_SHORTCUT_INTENT, ForwardActivity.intent(this, voice))
                .putExtra(Intent.EXTRA_SHORTCUT_NAME, voice ? "旧式语音检测" : "旧式快问检测")
                .putExtra(Intent.EXTRA_SHORTCUT_ICON, icon));
        }
        finish();
    }
}
