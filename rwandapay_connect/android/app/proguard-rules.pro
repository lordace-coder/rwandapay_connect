# Keep the Flutter embedding and plugin registration.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit barcode scanning, used by mobile_scanner for Scan to Pay. The
# scanner is reached reflectively, so R8 cannot see the references.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ML Kit declares optional Play Services model downloaders that this app does
# not bundle (it uses the bundled barcode model). Without these, R8 fails the
# release build on missing classes.
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode.**
