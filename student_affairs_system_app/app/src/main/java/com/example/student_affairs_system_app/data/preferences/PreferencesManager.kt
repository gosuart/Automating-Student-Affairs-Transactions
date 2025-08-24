package com.example.student_affairs_system_app.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.example.student_affairs_system_app.data.models.LoginData
import com.google.gson.Gson
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "student_preferences")

@Singleton
class PreferencesManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val gson: Gson
) {
    
    private val dataStore = context.dataStore
    
    companion object {
        private val LOGIN_DATA_KEY = stringPreferencesKey("login_data")
        private val IS_LOGGED_IN_KEY = stringPreferencesKey("is_logged_in")
        private val LOGIN_TIME_KEY = longPreferencesKey("login_time")
        
        // مدة الجلسة: 10 دقائق بالميلي ثانية
        private const val SESSION_TIMEOUT_MS = 10 * 60 * 1000L // 10 minutes
    }
    
    suspend fun saveLoginData(loginData: LoginData) {
        dataStore.edit { preferences ->
            preferences[LOGIN_DATA_KEY] = gson.toJson(loginData)
            preferences[IS_LOGGED_IN_KEY] = "true"
            preferences[LOGIN_TIME_KEY] = System.currentTimeMillis()
        }
    }
    
    suspend fun getLoginData(): LoginData? {
        return try {
            val preferences = dataStore.data.first()
            val loginDataJson = preferences[LOGIN_DATA_KEY]
            if (loginDataJson != null) {
                gson.fromJson(loginDataJson, LoginData::class.java)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    suspend fun isLoggedIn(): Boolean {
        return try {
            val preferences = dataStore.data.first()
            val isLoggedIn = preferences[IS_LOGGED_IN_KEY] == "true"
            val loginTime = preferences[LOGIN_TIME_KEY] ?: 0L
            val currentTime = System.currentTimeMillis()
            
            // التحقق من عدم انتهاء صلاحية الجلسة (10 دقائق)
            if (isLoggedIn && (currentTime - loginTime) > SESSION_TIMEOUT_MS) {
                // انتهت صلاحية الجلسة
                clearLoginData()
                return false
            }
            
            isLoggedIn
        } catch (e: Exception) {
            false
        }
    }
    
    suspend fun clearLoginData() {
        dataStore.edit { preferences ->
            preferences.remove(LOGIN_DATA_KEY)
            preferences.remove(IS_LOGGED_IN_KEY)
            preferences.remove(LOGIN_TIME_KEY)
        }
    }
    
    // تحديث وقت الجلسة عند النشاط
    suspend fun updateSessionTime() {
        dataStore.edit { preferences ->
            if (preferences[IS_LOGGED_IN_KEY] == "true") {
                preferences[LOGIN_TIME_KEY] = System.currentTimeMillis()
            }
        }
    }
    
    // التحقق من صلاحية الجلسة بدون مسح البيانات
    suspend fun isSessionValid(): Boolean {
        return try {
            val preferences = dataStore.data.first()
            val isLoggedIn = preferences[IS_LOGGED_IN_KEY] == "true"
            val loginTime = preferences[LOGIN_TIME_KEY] ?: 0L
            val currentTime = System.currentTimeMillis()
            
            isLoggedIn && (currentTime - loginTime) <= SESSION_TIMEOUT_MS
        } catch (e: Exception) {
            false
        }
    }
    
    // Flow للاستماع للتغييرات في حالة تسجيل الدخول
    fun isLoggedInFlow() = dataStore.data.map { preferences ->
        preferences[IS_LOGGED_IN_KEY] == "true"
    }
    
    fun getLoginDataFlow() = dataStore.data.map { preferences ->
        try {
            val loginDataJson = preferences[LOGIN_DATA_KEY]
            if (loginDataJson != null) {
                gson.fromJson(loginDataJson, LoginData::class.java)
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}