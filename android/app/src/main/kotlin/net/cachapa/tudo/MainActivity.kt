package net.cachapa.tudo

import android.os.Build
import android.view.View
import android.view.Window
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onPostResume() {
        super.onPostResume()
        setDecorFitsSystemWindows(window, false)
    }
}

fun setDecorFitsSystemWindows(
    window: Window,
    decorFitsSystemWindows: Boolean
) {
    if (Build.VERSION.SDK_INT >= 30) {
        setDecorFitsSystemWindows30(window, decorFitsSystemWindows)
    } else if (Build.VERSION.SDK_INT >= 16) {
        setDecorFitsSystemWindows16(window, decorFitsSystemWindows)
    }
}

@RequiresApi(16)
fun setDecorFitsSystemWindows16(
    window: Window,
    decorFitsSystemWindows: Boolean
) {
    val decorFitsFlags = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)
    val decorView = window.decorView
    val sysUiVis = decorView.systemUiVisibility
    decorView.systemUiVisibility =
        if (decorFitsSystemWindows) sysUiVis and decorFitsFlags.inv() else sysUiVis or decorFitsFlags
}

@RequiresApi(30)
fun setDecorFitsSystemWindows30(
    window: Window,
    decorFitsSystemWindows: Boolean
) {
    window.setDecorFitsSystemWindows(decorFitsSystemWindows)
}
