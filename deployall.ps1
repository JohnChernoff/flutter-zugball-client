# PowerShell deployment script for Flutter web app
# Save as deployAll.ps1

$BUILD_NUMBER = Get-Date -Format "yyyyMMdd_HHmmss"
Write-Host "Building Flutter web app with build number: $BUILD_NUMBER" -ForegroundColor Green

# Build the Flutter web app
Write-Host "Running flutter build web..." -ForegroundColor Yellow
flutter build web --build-number=$BUILD_NUMBER

if ($LASTEXITCODE -eq 0) {
    Write-Host "Flutter build successful!" -ForegroundColor Green

    # Deploy using WSL rsync (preserve config files and images)
    Write-Host "Deploying to server..." -ForegroundColor Yellow
    wsl bash -c "rsync -av --delete --exclude='*.ini' --exclude='*.config' --exclude='*.png' build/web/ root@john-chernoff.com:/var/www/forkball.online/"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deployment complete!" -ForegroundColor Green
    } else {
        Write-Host "Deployment failed!" -ForegroundColor Red
    }
} else {
    Write-Host "Flutter build failed!" -ForegroundColor Red
}

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


