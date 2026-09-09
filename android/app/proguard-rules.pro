## Flutter Wrapper & Core rules
-keep class io.flutter.** { *; }
-keepclassmembers class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler {
    <fields>;
    <methods>;
}

## Keep GeneratedPluginRegistrant & All Flutter Plugins
-keep class io.flutter.plugins.** { *; }

## Keep In-App Purchase & Billing classes
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.internal.play_billing.** { *; }

## Keep Firebase & Google Services
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }

## Keep App specific classes & models
-keep class vn.io.codego.noisobiensau.** { *; }

## Ignore missing Play Core classes & general warnings
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn **

## Attributes required for Flutter
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
