#Requires -RunAsAdministrator
<#
Disables Adobe Acrobat/Reader online features (Document Cloud, Sign, Share, Sync, Connectors, etc.)
and hides sign-in/sign-out UI as much as possible via FeatureLockDown policies.

Applies to:
- HKLM:\SOFTWARE\Policies\Adobe\{Acrobat Reader|Adobe Acrobat}\DC\...
- HKLM:\SOFTWARE\WOW6432Node\Policies\Adobe\{Acrobat Reader|Adobe Acrobat}\DC\...
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('DC')]
    [string]$Version = 'DC',

    # If neither is specified, applies to both.
    [switch]$ReaderOnly,
    [switch]$AcrobatOnly
)

$applyReader = $true
$applyAcrobat = $true
if ($ReaderOnly -and -not $AcrobatOnly) { $applyAcrobat = $false }
if ($AcrobatOnly -and -not $ReaderOnly) { $applyReader = $false }

$policyRoots = @(
    'HKLM:\SOFTWARE\Policies',
    'HKLM:\SOFTWARE\WOW6432Node\Policies'
)

$products = @()
if ($applyReader) { $products += 'Acrobat Reader' }
if ($applyAcrobat) { $products += 'Adobe Acrobat' }

function Ensure-Key {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

function Set-Dword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )
    Ensure-Key -Path $Path
    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null
}

# --- Policy set (DWORD only) ---
# SubKey = '' means directly under FeatureLockDown
$settings = @(
    # ====== MASTER: kill services + sign-in screen (IMPORTANT: 0 disables services) ======
    @{ SubKey = 'cServices'; Name = 'bUpdater'; Value = 0 },

    # ====== Core cloud/services toggles ======
    @{ SubKey = 'cServices'; Name = 'bToggleAdobeDocumentServices'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bTogglePrefsSync'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bToggleSendAndTrack'; Value = 1 },

    # ====== Acrobat Sign ======
    @{ SubKey = 'cServices'; Name = 'bToggleAdobeSign'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bToggleManageSign'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bToggleFSSSignatureSaving'; Value = 1 },

    # ====== Fill & Sign integration (online-adjacent) ======
    @{ SubKey = 'cServices'; Name = 'bToggleFillSign'; Value = 1 },
    # 0 = hide "Send a Copy" button
    @{ SubKey = 'cServices'; Name = 'bToggleSendACopy'; Value = 0 },

    # ====== Document Cloud storage + 3rd party connectors ======
    @{ SubKey = 'cServices'; Name = 'bToggleDocumentCloud'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bToggleWebConnectors'; Value = 1 },

    # If present, these can override bToggleWebConnectors=1; force them OFF
    @{ SubKey = 'cServices'; Name = 'bBoxConnectorEnabled'; Value = 0 },
    @{ SubKey = 'cServices'; Name = 'bDropboxConnectorEnabled'; Value = 0 },
    @{ SubKey = 'cServices'; Name = 'bOneDriveConnectorEnabled'; Value = 0 },
    @{ SubKey = 'cServices'; Name = 'bGoogleDriveConnectorEnabled'; Value = 0 },

    # ====== Reviews / Share (cloud review UI) ======
    @{ SubKey = 'cServices'; Name = 'bToggleAdobeReview'; Value = 1 },

    # ====== Notifications ======
    @{ SubKey = 'cServices'; Name = 'bToggleNotifications'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bToggleNotificationToasts'; Value = 1 },
    @{ SubKey = 'cServices'; Name = 'bEnableBellButton'; Value = 1 },

    # ====== Scan app tab on Home ======
    # 0 = hide scan tab
    @{ SubKey = ''; Name = 'bShowScanTabInHomeView'; Value = 0 },

    # ====== Sign in/out menu item ======
    @{ SubKey = ''; Name = 'bSuppressSignOut'; Value = 1 },

    # ====== Home/Welcome/ToDo (часто тащит облачные сценарии) ======
    @{ SubKey = ''; Name = 'bToggleFTE'; Value = 1 },
    @{ SubKey = ''; Name = 'bToggleToDoList'; Value = 1 },
    @{ SubKey = ''; Name = 'bToggleToDoTiles'; Value = 1 },

    # ====== “Find more online” menu items ======
    @{ SubKey = ''; Name = 'bFindMoreWorkflowsOnline'; Value = 0 },
    @{ SubKey = ''; Name = 'bFindMoreCustomizationsOnline'; Value = 0 },

    # ====== Usage / feedback UI ======
    @{ SubKey = ''; Name = 'bToggleShareFeedback'; Value = 0 },
    # UsageMeasurement: 0 = don't send usage details (lockable)
    @{ SubKey = ''; Name = 'bUsageMeasurement'; Value = 0 },

    # ====== In-product messaging / banners / “Start Free Trial” (cIPM) ======
    @{ SubKey = 'cIPM'; Name = 'bShowMsgAtLaunch'; Value = 0 },
    @{ SubKey = 'cIPM'; Name = 'bDontShowMsgWhenViewingDoc'; Value = 0 },
    @{ SubKey = 'cIPM'; Name = 'bAllowUserToChangeMsgPrefs'; Value = 0 },

    # ====== Upsell/promotions ======
    @{ SubKey = ''; Name = 'bAcroSuppressUpsell'; Value = 1 },
    @{ SubKey = ''; Name = 'bToggleSophiaWebInfra'; Value = 0 },
    @{ SubKey = ''; Name = 'bToggleDCAppCenter'; Value = 1 },
    @{ SubKey = ''; Name = 'bLimitPromptsFeatureKey'; Value = 1 },

    # ====== Ads in PDFs ======
    @{ SubKey = ''; Name = 'bCommercialPDF'; Value = 1 },

    # ====== What's New ======
    @{ SubKey = ''; Name = 'bWhatsNewExp'; Value = 1 },

    # ====== SharePoint integration (extra hardening) ======
    @{ SubKey = ''; Name = 'bEnableSharePointInChromeExtn'; Value = 0 },  # Chrome ext integration
    @{ SubKey = 'cSharePoint'; Name = 'bDisableSharePointFeatures'; Value = 1 },
    @{ SubKey = ''; Name = 'bEnableSharepointModernAuth'; Value = 0 },

    # ====== WebMail ======
    @{ SubKey = 'cWebmailProfiles'; Name = 'bDisableWebmail'; Value = 1 },

    # ====== Outlook “Send and Track” plugin toggle (Workflows -> HKLM lock is FeatureLockDown\cCloud) ======
    @{ SubKey = 'cCloud'; Name = 'bAdobeSendPluginToggle'; Value = 1 },

    # ====== Starred files (часть “Home/Cloud UX”) ======
    @{ SubKey = ''; Name = 'bFavoritesFeaturesLockDown'; Value = 0 }
)

foreach ($root in $policyRoots) {
    foreach ($product in $products) {
        $base = Join-Path $root ("Adobe\{0}\{1}\FeatureLockDown" -f $product, $Version)

        foreach ($s in $settings) {
            $path = if ([string]::IsNullOrWhiteSpace($s.SubKey)) { $base } else { Join-Path $base $s.SubKey }
            $name = $s.Name
            $val  = [int]$s.Value

            if ($PSCmdlet.ShouldProcess("$path\$name", "Set DWORD=$val")) {
                Set-Dword -Path $path -Name $name -Value $val
            }
        }
    }
}

Write-Host "Done. Policies written for: $($products -join ', ') ($Version) in both Policies and WOW6432Node\Policies."
Write-Host "Tip: close Acrobat/Reader fully and re-open (or reboot) to ensure UI refresh."