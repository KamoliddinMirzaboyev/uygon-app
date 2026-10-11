package uz.uygon.uygon

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

class UygonAdminReceiver : DeviceAdminReceiver() {
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence =
        "Uyg'on himoyasi o'chirilsa, budilnikni o'chirib yuborish osonlashadi. Davom etasizmi?"
}
