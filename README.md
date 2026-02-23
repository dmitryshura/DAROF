# D.A.R.O.F. :
# Disable Adobe Reader Online Features (Windows, DC)

This repository provides a PowerShell script that applies **Adobe Enterprise Toolkit (ETK)** “lockable” policies (Windows registry) to **disable as many online / cloud-facing features as possible** in:

- **Adobe Acrobat Reader DC**
- **Adobe Acrobat DC**

It targets Document Cloud services (sign-in UI, share/review, sign, sync), 3rd‑party cloud connectors (OneDrive/Google Drive/Dropbox/Box), in‑product messaging (IPM banners), notifications, and common “online resources” entry points.

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
- disables **all services without exception** (including any sign‑in screen)
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

### Local run (recommended)

#### Run with the default PowerShell execution policy
```powershell
.\Disable-AdobeOnlineFeatures.ps1
```

#### Run with ExecutionPolicy bypass (common in locked-down environments)
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Disable-AdobeOnlineFeatures.ps1
```

#### Only Reader
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Disable-AdobeOnlineFeatures.ps1 -ReaderOnly
```

#### Only Acrobat
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Disable-AdobeOnlineFeatures.ps1 -AcrobatOnly
```

#### Dry-run (show what would be written)
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Disable-AdobeOnlineFeatures.ps1 -WhatIf
```

### After applying
- Close Acrobat/Reader completely and re-open
- If UI elements persist, log off / reboot (some components cache UI state)

---

## Policy list (high level)

Below is the **intent** of the settings the script writes. All values are **DWORD**.

### A) Services master switches (`FeatureLockDown\cServices`)
| Key | Value | Effect |
|---|---:|---|
| `bUpdater` | `0` | **Disable all services + sign-in screen** and service component updates |
| `bToggleAdobeDocumentServices` | `1` | Disable Document Cloud services (except those controlled separately) |
| `bTogglePrefsSync` | `1` | Disable preferences synchronization |
| `bToggleSendAndTrack` | `1` | Disable “Send and Track” / “Share” |
| `bToggleAdobeSign` | `1` | Disable Acrobat Sign (“Send for Signature”) |
| `bToggleManageSign` | `1` | Hide Signature tab / sign tracking UI |
| `bToggleFSSSignatureSaving` | `1` | Hide “Save signature in the cloud” UI |
| `bToggleFillSign` | `1` | Disable Fill & Sign |
| `bToggleSendACopy` | `0` | Hide “Send a Copy” in Fill & Sign |
| `bToggleDocumentCloud` | `1` | Disable Document Cloud storage |
| `bToggleWebConnectors` | `1` | Disable 3rd-party storage connectors (Continuous track) |
| `bBoxConnectorEnabled` | `0` | Disable Box connector (override) |
| `bDropboxConnectorEnabled` | `0` | Disable Dropbox connector (override) |
| `bGoogleDriveConnectorEnabled` | `0` | Disable Google Drive connector (override) |
| `bOneDriveConnectorEnabled` | `0` | Disable OneDrive connector (override) |
| `bToggleAdobeReview` | `1` | Remove UI related to Document Cloud Review |
| `bToggleNotifications` | `1` | Disable **all** notifications (in-product + desktop) |
| `bToggleNotificationToasts` | `1` | Hide desktop notifications |
| `bEnableBellButton` | `1` | Hide in-product notifications |

### B) Sign-in / Sign-out UI (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bSuppressSignOut` | `1` | Disables the “Sign in / Sign out” Help menu item |

> The service master switch (`cServices\bUpdater=0`) is the primary control for sign-in screen behavior.

### C) Home screen & startup (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bToggleFTE` | `1` | Disable first-time experience (welcome tour/page) |
| `bToggleToDoList` | `1` | Disable Home “To Do list” |
| `bToggleToDoTiles` | `1` | Hide To Do cards in Recent tab |
| `bFavoritesFeaturesLockDown` | `0` | Disable & lock starred files feature |
| `bShowScanTabInHomeView` | `0` | Hide Scan tab in Home view |

### D) Online resources menus (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bFindMoreWorkflowsOnline` | `0` | Hide “Find More Online” Actions library entry |
| `bFindMoreCustomizationsOnline` | `0` | Hide Tool Set Exchange “Find More…” entry |

### E) IPM (In‑product messaging) (`FeatureLockDown\cIPM`)
| Key | Value | Effect |
|---|---:|---|
| `bShowMsgAtLaunch` | `0` | Do not show Adobe messages at launch |
| `bDontShowMsgWhenViewingDoc` | `0` | Do not show messages while viewing documents |
| `bAllowUserToChangeMsgPrefs` | `0` | Lock IPM settings so users cannot re-enable |

### F) Telemetry / feedback UI (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bUsageMeasurement` | `0` | Do not send usage measurement data (also disables welcome screen) |
| `bToggleShareFeedback` | `0` | Hide “Send Feedback” icon |

### G) Upsell / promotions (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bAcroSuppressUpsell` | `1` | Disable upsell messages (Reader-focused) |
| `bToggleDCAppCenter` | `1` | Hide “Get apps” / App Center UI |
| `bLimitPromptsFeatureKey` | `1` | Limit prompts (tips/CTAs) to reduce noise |
| `bToggleSophiaWebInfra` | `0` | Disable campaigns (e.g., right-hand pane banner) |

### H) Misc / ads (`FeatureLockDown`)
| Key | Value | Effect |
|---|---:|---|
| `bCommercialPDF` | `1` | Disable and lock commercial ads in PDFs |
| `bWhatsNewExp` | `1` | Disable “What’s New” experience |

### I) SharePoint integration
| Location | Key | Value | Effect |
|---|---|---:|---|
| `FeatureLockDown` | `bEnableSharepointModernAuth` | `0` | Disable Modern Auth (OAuth 2.0) for SharePoint integration |
| `FeatureLockDown\cSharePoint` | `bDisableSharePointFeatures` | `1` | Disable SharePoint / Office365 integration features |
| `FeatureLockDown` | `bEnableSharePointInChromeExtn` | `0` | Do not enable SharePoint integration in Acrobat Chrome extension |

### J) Outlook “Send and Track” plugin toggle
| Location | Key | Value | Effect |
|---|---|---:|---|
| `FeatureLockDown\cCloud` | `bAdobeSendPluginToggle` | `1` | Disable Adobe “Send and Track” Outlook plugin |

### K) WebMail integration (SMTP/IMAP WebMail profiles)
| Location | Key | Value | Effect |
|---|---|---:|---|
| `FeatureLockDown\cWebmailProfiles` | `bDisableWebmail` | `1` | Disable WebMail profile workflows |

> **Note:** Adobe’s WebMail reference page describes interactions between `bDisableWebmail` and `bSendMailShareRedirection`; validate behavior in your environment if you rely on email workflows.

---

## Why both `Policies` and `WOW6432Node\Policies`?

Adobe components and integrations can be mixed 32-bit/64-bit depending on product version, plugins, and Office integration. Writing both policy roots improves consistency in enterprise images and prevents “half-applied” behavior.

---

## Rollback / Uninstall

To revert:
- delete the values/keys that were created under the policy paths, **or**
- set values back to their defaults per Adobe ETK documentation.

A simple rollback approach in enterprise is to deploy a second script/GPP item that removes these registry values.

---

## Security / operational notes

- This script only writes to **HKLM policy** areas. End users cannot override these settings via Preferences.
- Disabling notifications (`bToggleNotifications=1`) hides alerts, but some features may still “fetch/cache” in certain versions unless services are disabled globally via `cServices\bUpdater=0`.

---

## References (Adobe ETK)

- FeatureLockDown registry reference (Windows):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/FeatureLockDown.html
- IPM (In-product messaging):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/IPM.html
- UsageMeasurement (user measurement / improvement program):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/UsageMeasurement.html
- Workflows (includes Outlook plugin + SharePoint controls):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/Workflows.html
- WebMail (SMTP/IMAP profiles):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/PrefRef/Windows/WebMail.html
- SharePoint admin guide (modern auth toggle + disable integration):  
  https://www.adobe.com/devnet-docs/acrobatetk/tools/AdminGuide/sharepoint.html

---
