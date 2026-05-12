# Installing VisionMeasure on iPhone (Free, No Apple Developer Account)

This guide installs the app on an iPhone for **7 days** at a time using a free Apple ID. No $99/year Apple Developer account needed. After 7 days, repeat the sideload step.

**Requirements**
- An iPhone (iOS 14+)
- Any Windows PC or Mac with a USB-Lightning/USB-C cable
- A free Apple ID (the one signed into the iPhone is fine)

---

## Step 1 — Get the `.ipa` file (done by the project owner, once)

1. Go to https://codemagic.io/signup and sign in with GitHub (free tier: 500 min/month).
2. Click **Add application** → connect the `eyadsyam/VisionMeasure` repo.
3. Codemagic will detect the included `codemagic.yaml`. Select the **ios-unsigned** workflow.
4. Click **Start new build**. Wait ~15–25 minutes.
5. When the build finishes, download `VisionMeasure-unsigned.ipa` from the build artifacts.
6. Send that `.ipa` file to your friend (WhatsApp, Google Drive, email, etc.).

---

## Step 2 — Sideload onto the iPhone (done by your friend)

### Option A — Windows PC (easiest)

1. Install **iTunes** from the Microsoft Store (required, even if not used).
2. Download **Sideloadly** from https://sideloadly.io (free).
3. Open Sideloadly. Connect the iPhone via USB. Trust the computer when prompted on the phone.
4. Drag the `VisionMeasure-unsigned.ipa` into Sideloadly.
5. Enter the **free Apple ID** (the one logged in on the iPhone) and password. *Use an app-specific password if 2FA is enabled — generate at https://appleid.apple.com.*
6. Click **Start**. Wait ~2–5 minutes.
7. On the iPhone, open **Settings → General → VPN & Device Management** → tap the Apple ID → **Trust**.
8. Open the VisionMeasure app from the home screen.

### Option B — Mac

Same as above, but use **Sideloadly for macOS** from the same site. No iTunes needed.

---

## After 7 days

The app will stop opening. Just plug into the same computer and re-run Sideloadly with the same `.ipa`. Takes ~2 minutes. (The free Apple ID limit is 3 sideloaded apps active at once.)

---

## Permissions

The app uses the **camera** (for face/distance detection during vision tests) and **photo library** (for the optional avatar). iOS will ask on first launch — tap *Allow*.

---

## If something breaks

- **"Could not verify app"** → go to Settings → General → VPN & Device Management → tap Trust.
- **"Unable to install"** → ensure iPhone is unlocked, cable supports data (not just charging), and you've clicked "Trust this computer" on the phone.
- **Sideloadly error about 2FA** → create an app-specific password at https://appleid.apple.com → Sign-In and Security → App-Specific Passwords.
