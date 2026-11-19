import type { CapacitorConfig } from '@capacitor/cli';

// Remote-URL mode: the WebView loads the live production site ({{PROD_URL}}),
// so the mobile shell never lags behind the website. `webDir` is required by
// the CLI schema but is an empty placeholder (www/) that is unused at runtime
// (apart from the offline page below).
//
// ALWAYS sync per platform: `npx cap sync ios` / `npx cap sync android`.
// NEVER a bare `npx cap sync` -- the platform-specific differences below are
// derived from the CLI arguments.
const cliArgs = process.argv.slice(2);
const syncsIosOnly = cliArgs.includes('ios') && !cliArgs.includes('android');
// Set CAP_DEBUG=1 for local debug syncs; release syncs leave WebView debugging off.
const debugBuild = process.env.CAP_DEBUG === '1';

const config: CapacitorConfig = {
  appId: '{{APP_ID}}',
  appName: '{{APP_NAME}}',
  webDir: 'www',
  server: {
    url: '{{PROD_URL}}',
    androidScheme: 'https',
    // iOS only: show the bundled www/offline.html when the site cannot be
    // reached at launch (the Android config stays exactly as before).
    ...(syncsIosOnly ? { errorPath: 'offline.html' } : {}),
    // Deliberately NOT adding accounts.google.com (or any OAuth provider host)
    // to `allowNavigation`: leaving it unlisted is what makes the native
    // WebViewClient hand that navigation to the EXTERNAL browser. Google blocks
    // OAuth inside embedded WebViews ("disallowed_useragent").
  },
  android: {
    // Marker the web app / middleware use to detect it runs inside the app
    // (hide purchase UI, adjust OAuth). Keep in sync with the web helper
    // nativeAppPlatform() -- see references/web-adaptation.md.
    appendUserAgent: '{{UA_ANDROID}}',
    // Only for debug syncs (CAP_DEBUG=1 npx cap sync android).
    webContentsDebuggingEnabled: debugBuild,
  },
  ios: {
    appendUserAgent: '{{UA_IOS}}',
    // The page draws under the status bar / Dynamic Island / home indicator and
    // pads itself with env(safe-area-inset-*) (needs viewport-fit=cover on web).
    contentInset: 'never',
    backgroundColor: '{{BRAND_COLOR}}',
    preferredContentMode: 'mobile',
  },
  plugins: {
    Keyboard: {
      // iOS: shrink the WebView when the keyboard opens so the focused field
      // and fixed bottom bars stay visible (pair with 100dvh layouts on web).
      resize: 'native',
    },
    SystemBars: {
      // Android: tell the inset listener up front that the page uses
      // viewport-fit=cover; avoids a visible layout jump on cold start.
      initialViewportFitValueHint: 'cover',
    },
  },
};

export default config;
