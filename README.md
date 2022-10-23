# AdUnwrap
Bypasses ad links on android (bypass.vip)

Devices running Android 10+ will need to have these permissions pushed to the device via adb:
```bash
adb -d shell appops set com.castdrian.adunwrap SYSTEM_ALERT_WINDOW allow
adb shell pm grant com.castdrian.adunwrap android.permission.WRITE_SECURE_SETTINGS
adb shell pm grant com.castdrian.adunwrap android.permission.READ_LOGS
adb shell am force-stop com.castdrian.adunwrap
```