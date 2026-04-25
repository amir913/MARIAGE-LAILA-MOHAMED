# ============================================================
# Script upload automatique photos Mirror Me Booth vers GitHub
# Mariage Laila et Mohamed - 25 avril 2026
# ============================================================

$dossierPhotos = "C:\MirrorMeBooth\events\Laila_et_Mohamed\photos"
$dossierGit    = "C:\git\MARIAGE-LAILA-MOHAMED"
$logFile       = Join-Path $dossierGit "upload.log"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $logFile -Value $line
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PHOTOBOOTH AUTO-UPLOAD - Laila et Mohamed" -ForegroundColor Cyan
Write-Host "  Surveille : $dossierPhotos" -ForegroundColor Gray
Write-Host "  Upload vers : https://amir913.github.io/MARIAGE-LAILA-MOHAMED/" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $dossierPhotos)) {
    Write-Log "ERREUR : Dossier photos introuvable : $dossierPhotos" "Red"
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

if (-not (Test-Path $dossierGit)) {
    Write-Log "ERREUR : Dossier git introuvable : $dossierGit" "Red"
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

Write-Log "Script lance. En attente de nouvelles photos..." "Green"
Write-Host "(Pour arreter : ferme cette fenetre ou Ctrl+C)" -ForegroundColor DarkGray
Write-Host ""

$fichiersTraites = @{}

Get-ChildItem -Path $dossierPhotos -Filter "*.jpg" -File | ForEach-Object {
    $fichiersTraites[$_.Name] = $true
}
Write-Log "Fichiers deja presents ignores : $($fichiersTraites.Count)" "Gray"

while ($true) {
    try {
        $nouveauxFichiers = Get-ChildItem -Path $dossierPhotos -Filter "*.jpg" -File | Where-Object { -not $fichiersTraites.ContainsKey($_.Name) }

        foreach ($fichier in $nouveauxFichiers) {
            Write-Log "Nouvelle photo : $($fichier.Name)" "Yellow"
            Start-Sleep -Seconds 3

            try {
                Copy-Item -Path $fichier.FullName -Destination $dossierGit -Force
                Write-Log "  Copie vers git OK" "Gray"

                Set-Location $dossierGit
                git add $fichier.Name 2>&1 | Out-Null
                git commit -m "photo $($fichier.Name)" 2>&1 | Out-Null
                $pushResult = git push 2>&1

                if ($LASTEXITCODE -eq 0) {
                    Write-Log "  Upload reussi - disponible sous 1 min" "Green"
                    Write-Log "  URL : https://amir913.github.io/MARIAGE-LAILA-MOHAMED/$($fichier.Name)" "DarkGray"
                    $fichiersTraites[$fichier.Name] = $true
                } else {
                    Write-Log "  Erreur push : $pushResult" "Red"
                }
            } catch {
                Write-Log "  Erreur : $_" "Red"
            }
        }

        Start-Sleep -Seconds 2
    } catch {
        Write-Log "Erreur boucle : $_" "Red"
        Start-Sleep -Seconds 5
    }
}
