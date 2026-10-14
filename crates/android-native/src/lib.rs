//! JNI library for `com.aphrody.android.NativeBridge`.

use jni::sys::{JNIEnv, jclass, jint};

/// C ABI entry point shared with Bun FFI.
#[unsafe(no_mangle)]
pub extern "C" fn android_add(left: i32, right: i32) -> i32 {
    left.saturating_add(right)
}

/// Add two Java integers, saturating on overflow.
///
/// Neither JNI pointer is dereferenced; the JVM owns both pointers.
#[unsafe(no_mangle)]
pub extern "system" fn Java_com_aphrody_android_NativeBridge_add(
    _env: *mut JNIEnv,
    _class: jclass,
    left: jint,
    right: jint,
) -> jint {
    #[cfg(target_os = "android")]
    initialize_android_logging();
    android_add(left, right)
}

#[cfg(target_os = "android")]
fn initialize_android_logging() {
    android_logger::init_once(
        android_logger::Config::default()
            .with_max_level(log::LevelFilter::Info)
            .with_tag("AphrodyRust"),
    );
    // Exercise an NDK-owned object, including its native allocation and release.
    let configuration = ndk::configuration::Configuration::new();
    log::info!("Rust JNI bridge loaded; configuration: {configuration:?}");
}
