package {{APP_ID}};

import android.app.Dialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Message;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import com.getcapacitor.Bridge;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.BridgeWebChromeClient;

public class MainActivity extends BridgeActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // PUSH (only if the app uses push): create the notification channels here, BEFORE the
        // first push, with ids identical to what the backend sends in `channel_id`.
        // See references/android.md "Push notifications" and the snippet at the bottom of this file.

        WebView webView = this.bridge.getWebView();
        WebSettings settings = webView.getSettings();
        // Checkout / 3-D Secure / Google Pay overlays open popup windows via window.open().
        // A bare WebView silently drops them, so the button would look dead.
        settings.setSupportMultipleWindows(true);
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        webView.setWebChromeClient(new PopupAwareWebChromeClient(this.bridge));
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        // The OAuth callback ({{PROD_URL}}<callback path>, matched by the App Links
        // intent-filter) returns here after the consent screen ran in the external browser.
        // Load it in THIS WebView so the web app's own callback handler stores the session
        // in this WebView's storage. Only same-origin URLs are loaded.
        Uri data = intent.getData();
        if (data != null && this.bridge != null && "{{PROD_HOST}}".equals(data.getHost())) {
            this.bridge.getWebView().loadUrl(data.toString());
        }
    }

    /** Popup-window support on top of Capacitor's chrome client (which already handles
     *  mic/camera prompts, file choosers and JS dialogs). */
    private static class PopupAwareWebChromeClient extends BridgeWebChromeClient {

        PopupAwareWebChromeClient(Bridge bridge) {
            super(bridge);
        }

        @Override
        public boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
            Dialog popupDialog = new Dialog(view.getContext());
            WebView popupWebView = new WebView(view.getContext());
            popupWebView.getSettings().setJavaScriptEnabled(true);
            popupWebView.getSettings().setDomStorageEnabled(true);
            popupWebView.setWebViewClient(new WebViewClient());
            popupWebView.setWebChromeClient(
                new WebChromeClient() {
                    @Override
                    public void onCloseWindow(WebView window) {
                        popupDialog.dismiss();
                    }
                }
            );

            popupDialog.setContentView(popupWebView);
            popupDialog.setOnDismissListener(dialog -> popupWebView.destroy());
            popupDialog.show();
            popupDialog.getWindow().setLayout(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);

            WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
            transport.setWebView(popupWebView);
            resultMsg.sendToTarget();
            return true;
        }
    }

    /* ---- PUSH snippet: paste into the class, call from onCreate(), add strings to res/values/strings.xml ----
    private void createNotificationChannels() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) return;
        android.app.NotificationManager manager = getSystemService(android.app.NotificationManager.class);
        if (manager == null) return;
        // Ids MUST equal the backend's android channel ids. Re-creating a channel is a no-op.
        manager.createNotificationChannel(new android.app.NotificationChannel(
            "general", getString(R.string.channel_general), android.app.NotificationManager.IMPORTANCE_DEFAULT));
    }
    ------------------------------------------------------------------------------------------------------ */
}
