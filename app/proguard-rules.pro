# SPDX-FileCopyrightText: 2025 Avuz
# SPDX-License-Identifier: AGPL-3.0-or-later OR GPL-2.0-only

# Avuz Conecta ProGuard Rules

# Keep Android entry points
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# iCal4j - JSON Schema validation library (optional dependency, not used at runtime)
-dontwarn com.github.erosb.jsonsKema.**

# iCal4j - Groovy support (optional, not used)
-dontwarn groovy.**
-dontwarn org.codehaus.groovy.**

# iCal4j - cache2k (optional dependency)
-dontwarn org.cache2k.**

# Freemarker optional dependencies (used by iCal4j)
-dontwarn freemarker.**
-dontwarn org.dom4j.**
-dontwarn org.jaxen.**
-dontwarn org.python.**
-dontwarn org.zeroturnaround.javarebel.**

# Apache Xalan (optional XML processing)
-dontwarn org.apache.xml.utils.**
-dontwarn org.apache.xpath.**

# Apache Commons - unused logging implementations
-dontwarn org.apache.commons.logging.**
-dontwarn org.apache.log4j.**
-dontwarn org.apache.log.**

# Java Activation Framework (javax.activation)
-dontwarn javax.activation.**
-dontwarn jakarta.activation.**

# Java Mail API (optional features)
-dontwarn javax.mail.**
-dontwarn jakarta.mail.**

# SLF4J optional bindings
-dontwarn org.slf4j.impl.**

# Sun/Oracle internal APIs
-dontwarn sun.misc.**
-dontwarn sun.security.**

# Keep R8 from stripping annotation attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Room database - keep entity classes
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers @androidx.room.Entity class * {
    <fields>;
}

# Dagger
-dontwarn com.google.errorprone.annotations.**

# OkHttp
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Glide
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
    <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-keep class com.bumptech.glide.load.data.ParcelFileDescriptorRewinder$InternalRewinder {
    *** rewind();
}

# EventBus
-keepclassmembers class * {
    @org.greenrobot.eventbus.Subscribe <methods>;
}
-keep enum org.greenrobot.eventbus.ThreadMode { *; }

# ez-vcard
-dontwarn ezvcard.**
-keep class ezvcard.** { *; }

# Conscrypt
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# Bouncy Castle
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep data binding classes
-keep class androidx.databinding.** { *; }
-keepclassmembers class ** extends androidx.databinding.ViewDataBinding {
    public static ** inflate(android.view.LayoutInflater);
    public static ** inflate(android.view.LayoutInflater, android.view.ViewGroup, boolean);
    public static ** bind(android.view.View);
}

# Nextcloud library
-keep class com.nextcloud.** { *; }
-keep class com.owncloud.** { *; }

# WebDAV
-keep class org.apache.jackrabbit.webdav.** { *; }
-dontwarn org.apache.jackrabbit.**

# Apache Commons HttpClient (used by Nextcloud lib OwnCloudClientFactory at runtime via reflection)
-keep class org.apache.commons.httpclient.** { *; }
-dontwarn org.apache.commons.httpclient.**

# Guava — TypeToken uses getGenericSuperclass() reflection; must preserve generic signature
-keep class com.google.common.reflect.TypeToken
-keep class * extends com.google.common.reflect.TypeToken
-keepattributes Signature,InnerClasses,EnclosingMethod
-dontwarn com.google.common.**
-keep class com.google.common.util.concurrent.** { *; }

# Apache Commons Codec / IO (commons-httpclient transitive deps)
-keep class org.apache.commons.codec.** { *; }
-dontwarn org.apache.commons.codec.**
-keep class org.apache.commons.io.** { *; }
-dontwarn org.apache.commons.io.**

# Kotlin serialization
-keepattributes InnerClasses
-keep,includedescriptorclasses class com.avuz.conecta.**$$serializer { *; }
-keepclassmembers class com.avuz.conecta.** {
    *** Companion;
}
-keepclasseswithmembers class com.avuz.conecta.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep classes used by reflection
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Stateless4j
-dontwarn com.github.oxo42.stateless4j.**
