# D.A.R.O.F. :
# Disable Adobe Reader Online Features (Windows, DC) 

This repository provides a PowerShell script that applies **Adobe Enterprise Toolkit (ETK)** “lockable” policies (Windows registry) to **disable as many online / cloud-facing features as possible** in:

- **Adobe Acrobat Reader DC**
- **Adobe Acrobat DC**

It targets Document Cloud services (sign-in UI, share/review, sign, sync), 3rd-party cloud connectors (OneDrive/Google Drive/Dropbox/Box), in-product messaging (IPM banners), notifications, and common “online resources” entry points.

> **Core concept:** Adobe DC products honor **HKLM policy** keys under `...\Policies\Adobe\...\FeatureLockDown`. These settings require admin rights and lock UI options for end users (they cannot re-enable features).

---

## What the script does

### 1) Writes enterprise “policy” registry values
The script creates/updates **DWORD** values under these roots:

- `HKLM:\SOFTWARE\Policies\Adobe\...`
- `HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\...` (for compatibility across 32/64-bit components and mixed installs)

For each product (Reader / Acrobat):

- `...\<Product>\DC\FeatureLockDown`
- `...\<Product>\DC\FeatureLockDown\cServices`
- `...\<Product>\DC\FeatureLockDown\cIPM`
- `...\<Product>\DC\FeatureLockDown\cCloud`
- `...\<Product>\DC\FeatureLockDown\cSharePoint`
- `...\<Product>\DC\FeatureLockDown\cWebmailProfiles`

Where `<Product>` is:
- `Acrobat Reader`
- `Adobe Acrobat`

### 2) Disables “services” globally (kills sign-in screen / online services)
The most important setting is:

- `FeatureLockDown\cServices\bUpdater = 0`

This is Adobe’s **master switch** for DC services:
- disables **all services without exception** (including any sign-in screen)
- disables updates to the product’s web-plugin service components

> **Note:** This is **not** the same as `FeatureLockDown\bUpdater` (product updates). The script uses the `cServices` master switch.

### 3) Hardens key service areas (redundant-by-design)
Even with the master switch, the script also sets explicit toggles for:
- Document Cloud services
- Acrobat Sign + signature cloud saving UI
- “Share / Send and Track”
- Preferences sync
- Document Cloud storage
- Web connectors + provider overrides
- Reviews UI
- Notifications (in-product + desktop)

This is intentional for environments where admins later choose to enable services but still keep specific sub-features off.

### 4) Reduces “online noise”
The script additionally disables:
- IPM (in-product messaging) banners at launch and while viewing docs
- feedback icon
- “What’s New”
- App Center / “Get apps”
- upsell prompts and campaigns
- online “Find more…” menu items for Actions/Tool Sets
- commercial PDF ads

---

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- **Run as Administrator**
- Acrobat/Reader **DC** (Continuous or Classic track; some keys are track-specific)

---

## Usage

### Run (both Reader + Acrobat)
```powershell
.\Disable-AdobeOnlineFeatures.ps1
