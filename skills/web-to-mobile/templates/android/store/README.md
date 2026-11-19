# Google Play listing assets ({{APP_NAME}})

Keep the final files in this folder (committed, they are small). Sizes Play requires:

| Asset | Spec |
|---|---|
| App icon | 512×512 PNG, 32-bit, ≤1 MB (no rounded corners / shadows; Play masks it) |
| Feature graphic | 1024×500 PNG or JPG |
| Phone screenshots | 2–8 images, 16:9 or 9:16, each side 320–3840 px |
| 7" / 10" tablet screenshots | optional but recommended; same rules |

Capture screenshots from the debug build on a device: `adb -s <serial> exec-out screencap -p > shot1.png`
(or the emulator). Take them in every listing language. Do not show prices or purchase UI.

Text for the listing lives in `docs/**/store-listing.md` (single source of truth).
