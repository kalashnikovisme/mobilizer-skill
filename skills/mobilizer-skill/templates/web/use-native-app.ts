'use client';

// React hook flavour. For other frameworks (Vue/Svelte/Angular/vanilla) port
// the same idea: call nativeAppPlatform(navigator.userAgent) on the client
// AFTER hydration, and return "not native" during SSR/hydration so the
// server-rendered HTML is identical for web and app (no hydration mismatch).
import { useSyncExternalStore } from 'react';
import { nativeAppPlatform, type NativeAppPlatform } from './native-app';

const noopSubscribe = () => () => {};

/** `null` during SSR/hydration and in plain browsers; else the wrapper's platform. */
export function useNativeAppPlatform(): NativeAppPlatform | null {
  return useSyncExternalStore(
    noopSubscribe,
    () => nativeAppPlatform(navigator.userAgent),
    () => null,
  );
}

/** False during SSR/hydration, true on the client inside the Android or iOS app. */
export function useIsNativeApp(): boolean {
  return useNativeAppPlatform() !== null;
}

/** True only inside the iOS app (e.g. to offer Sign in with Apple). */
export function useIsIosApp(): boolean {
  return useNativeAppPlatform() === 'ios';
}
