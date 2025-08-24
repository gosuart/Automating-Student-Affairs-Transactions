package com.example.student_affairs_system_app.utils

import android.os.Build
import android.util.Log

object NetworkUtils {
    private const val TAG = "NetworkUtils"
    
    /**
     * تحديد نوع الجهاز والعنوان المناسب للاتصال
     */
    fun getServerBaseUrl(): String {
        val isEmulator = isRunningOnEmulator()
        val baseUrl = if (isEmulator) {
            getEmulatorBaseUrl()
        } else {
            "http://192.168.10.229/web_admin_ooo/backend/api/"
        }

        Log.d(TAG, "Device Type: ${if (isEmulator) "Emulator" else "Real Device"}")
        Log.d(TAG, "Base URL: $baseUrl")
        Log.d(TAG, "Build Info - Model: ${Build.MODEL}, Manufacturer: ${Build.MANUFACTURER}")
        Log.d(TAG, "Build Info - Hardware: ${Build.HARDWARE}, Fingerprint: ${Build.FINGERPRINT}")

        return baseUrl
    }

    /**
     * الحصول على عنوان الخادم للمحاكي مع عدة خيارات بديلة
     */
    private fun getEmulatorBaseUrl(): String {
        // قائمة العناوين البديلة للمحاكي
        val emulatorUrls = listOf(
            "http://10.0.2.2/web_admin_ooo/backend/api/",  // العنوان الافتراضي للمحاكي
            "http://192.168.10.142/web_admin_ooo/backend/api/", // IP الفعلي كبديل
            "http://127.0.0.1/web_admin_ooo/backend/api/",     // localhost كبديل
            "http://localhost/web_admin_ooo/backend/api/"       // localhost بالاسم
        )

        // إرجاع العنوان الأول (الافتراضي)
        // يمكن تطوير هذا لاحقاً لاختبار العناوين تلقائياً
        return emulatorUrls[0]
    }

    /**
     * الحصول على قائمة العناوين البديلة للمحاكي
     */
    fun getEmulatorFallbackUrls(): List<String> {
        return listOf(
            "http://10.0.2.2/web_admin_ooo/backend/api/",
            "http://192.168.0.221/web_admin_ooo/backend/api/",
            "http://127.0.0.1/web_admin_ooo/backend/api/",
            "http://localhost/web_admin_ooo/backend/api/"
        )
    }
    
    /**
     * فحص ما إذا كان التطبيق يعمل على محاكي
     */
    fun isRunningOnEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic") ||
                Build.FINGERPRINT.startsWith("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK") ||
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
                "google_sdk" == Build.PRODUCT ||
                Build.HARDWARE.contains("goldfish") ||
                Build.HARDWARE.contains("ranchu"))
    }
    
    /**
     * اختبار الاتصال بالخادم
     */
    fun logConnectionInfo() {
        Log.d(TAG, "=== معلومات الاتصال ===")
        Log.d(TAG, "نوع الجهاز: ${if (isRunningOnEmulator()) "محاكي" else "جهاز حقيقي"}")
        Log.d(TAG, "عنوان الخادم: ${getServerBaseUrl()}")
        Log.d(TAG, "Build.MODEL: ${Build.MODEL}")
        Log.d(TAG, "Build.MANUFACTURER: ${Build.MANUFACTURER}")
        Log.d(TAG, "Build.HARDWARE: ${Build.HARDWARE}")
        Log.d(TAG, "Build.FINGERPRINT: ${Build.FINGERPRINT}")
        Log.d(TAG, "========================")
    }
}
