/**
 * The Capacitor shell appends one of these tokens to the WebView user agent
 * (mobile/capacitor.config.ts: android.appendUserAgent / ios.appendUserAgent --
 * keep them in sync). Plain web browsers never carry them, so anything gated on
 * this helper is invisible to website users.
 *
 * Both stores forbid selling digital goods outside their own billing and
 * steering users to external payment pages (Google Play Billing, App Store
 * 3.1.1), so purchase UI is hidden whenever a marker is present.
 */
export const NATIVE_APP_UA_MARKERS = {
  android: '{{UA_ANDROID}}',
  ios: '{{UA_IOS}}',
} as const;

export type NativeAppPlatform = keyof typeof NATIVE_APP_UA_MARKERS;

/** Which wrapper (if any) the user agent belongs to. Safe on server and client. */
export function nativeAppPlatform(
  userAgent: string | null | undefined,
): NativeAppPlatform | null {
  if (!userAgent) return null;
  if (userAgent.includes(NATIVE_APP_UA_MARKERS.android)) return 'android';
  if (userAgent.includes(NATIVE_APP_UA_MARKERS.ios)) return 'ios';
  return null;
}

/** True inside either the Android or the iOS app. */
export function isNativeAppUserAgent(
  userAgent: string | null | undefined,
): boolean {
  return nativeAppPlatform(userAgent) !== null;
}
