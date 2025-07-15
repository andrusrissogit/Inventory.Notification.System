Clear-Host
Write-Host "Iniciando entorno Inventory.Notification.System..."

# ----------------------------------------------------------------------------------
# 1. Eliminar contenedores previos
# ----------------------------------------------------------------------------------
Write-Host "Eliminando contenedores y redes anteriores..."
docker compose down -v

# ----------------------------------------------------------------------------------
# 2. Levantar SQL Servers y RabbitMQ
# ----------------------------------------------------------------------------------
Write-Host "Levantando SQL Servers y RabbitMQ..."
docker compose up -d sqlserver_inventory sqlserver_notification rabbitmq
Start-Sleep -Seconds 15  # Le damos más margen de arranque

# ----------------------------------------------------------------------------------
# 3. Función para esperar que SQL Server esté listo
# ----------------------------------------------------------------------------------
function Wait-ForSqlServer {
    param(
        [string]$partialName,
        [string]$password
    )

    $containerName = docker ps --filter "name=$partialName" --format "{{.Names}}" | Select-Object -First 1

    if (-not $containerName) {
        Write-Error "No se encontró ningún contenedor que contenga '$partialName'."
        exit 1
    }

    Write-Host "Esperando que '$containerName' esté listo..."

    $tries = 0
    $maxTries = 100
    while ($tries -lt $maxTries) {
        $logs = docker logs $containerName 2>&1
        if ($logs -match "SQL Server is now ready for client connections") {
            Write-Host "'$containerName' está listo."
            return
        }

        Write-Host "Intento $tries... esperando a SQL Server."
        Start-Sleep -Seconds 3
        $tries++
    }

    Write-Error "❌ '$containerName' no respondió en el tiempo esperado."
    exit 1
}

# ----------------------------------------------------------------------------------
# 4. Esperar contenedores SQL Server
# ----------------------------------------------------------------------------------
Wait-ForSqlServer -partialName "sqlserver_inventory" -password "Pass123456"
Wait-ForSqlServer -partialName "sqlserver_notification" -password "Pass123456"

# ----------------------------------------------------------------------------------
# 5. Aplicar migraciones InventoryDb
# ----------------------------------------------------------------------------------
Write-Host "Aplicando migraciones InventoryDb..."
dotnet ef database update `
  --project ./Inventory/src/Inventory.API `
  --startup-project ./Inventory/src/Inventory.API `
  --connection "Server=localhost,1433;Database=InventoryDb;User Id=sa;Password=Pass123456;TrustServerCertificate=True;"

# ----------------------------------------------------------------------------------
# 6. Aplicar migraciones NotificationDb
# ----------------------------------------------------------------------------------
Write-Host "Aplicando migraciones NotificationDb..."
dotnet ef database update `
  --project ./Notification/src/Notification.API `
  --startup-project ./Notification/src/Notification.API `
  --connection "Server=localhost,1434;Database=NotificationDb;User Id=sa;Password=Pass123456;TrustServerCertificate=True;"

# ----------------------------------------------------------------------------------
# 7. Levantar microservicios API
# ----------------------------------------------------------------------------------
Write-Host "Levantando microservicios Inventory.API y Notification.API..."
docker compose up -d inventory.api notification.api

# ----------------------------------------------------------------------------------
# 8. Mostrar estado final
# ----------------------------------------------------------------------------------
Write-Host "Entorno completo levantado. Contenedores en ejecución:"
docker ps