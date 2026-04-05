# Script para corregir withOpacity deprecado
# Reemplaza .withOpacity(valor) por .withValues(alpha: valor)

Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $original = $content
    
    # Reemplazar patrones comunes de withOpacity
    $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
    
    if ($content -ne $original) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "Corregido: $($_.FullName)"
    }
}

Write-Host "¡Correcciones completadas!"
