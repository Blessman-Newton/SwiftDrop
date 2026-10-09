# distribute.ps1
# Helper script to distribute SwiftDrop Flutter release APK to Firebase App Distribution

$apkPath = "build/app/outputs/flutter-apk/app-release.apk"

if (-not (Test-Path $apkPath)) {
    Write-Host "Building release APK..." -ForegroundColor Cyan
    flutter build apk --release
}

# Verify APK built successfully
if (-not (Test-Path $apkPath)) {
    Write-Error "Could not find build APK at $apkPath. Please check for build errors."
    exit 1
}

Write-Host "Checking Firebase authentication..." -ForegroundColor Cyan
# Run projects list to see if authenticated
$authCheck = npx firebase-tools projects:list 2>&1
if ($authCheck -match "Failed to authenticate") {
    Write-Host "You are not logged in to Firebase CLI. Redirecting to login in browser..." -ForegroundColor Yellow
    npx firebase-tools login
}

# Prompt for App ID
$appId = Read-Host "Enter your Firebase Android App ID (e.g. 1:12345678:android:abcd1234)"
if ([string]::IsNullOrEmpty($appId)) {
    Write-Error "Firebase App ID is required to distribute."
    exit 1
}

Write-Host "Uploading APK to Firebase App Distribution..." -ForegroundColor Green
npx firebase-tools appdistribution:distribute $apkPath --app $appId --groups "testers"

Write-Host "Distribution completed successfully!" -ForegroundColor Green
