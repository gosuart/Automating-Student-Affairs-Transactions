package com.example.student_affairs_system_app.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
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
    }
    
    suspend fun saveLoginData(loginData: LoginData) {
        dataStore.edit { preferences ->
            preferences[LOGIN_DATA_KEY] = gson.toJson(loginData)
            preferences[IS_LOGGED_IN_KEY] = "true"
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
            preferences[IS_LOGGED_IN_KEY] == "true"
        } catch (e: Exception) {
            false
        }
    }
    
    suspend fun clearLoginData() {
        dataStore.edit { preferences ->
            preferences.remove(LOGIN_DATA_KEY)
            preferences.remove(IS_LOGGED_IN_KEY)
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