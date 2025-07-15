# Inventory Notification System - Guía de despliegue

Este repositorio contiene las instrucciones para descargar y ejecutar los microservicios:

- **Inventory.API**: administra productos e integra con RabbitMQ.
- **Notification.API**: consume eventos de inventario y persiste en su base.

Cada uno reside en su propio repositorio independiente.

El ambiente incluye:

- RabbitMQ
- SQL Server para Inventory
- SQL Server para Notification

---

## 📂 Repositorios

| Proyecto        | Repositorio GitHub                                    |
|-----------------|-------------------------------------------------------|
| Inventory       | https://github.com/andrusrissogit/Inventory
| Notification    | https://github.com/andrusrissogit/Notification) 

---

## ⚙️ Requisitos

- **Git** instalado
- **Docker** y **Docker Compose**
  - Si usas Windows: WSL2 habilitado
- (Opcional) **.NET SDK 8** (solo si compilas manualmente)

---

## 📥 Clonar los microservicios

En una carpeta vacía, con nombre por ejemplo Inventory.Notification.System, ejecuta:

git clone https://github.com/andrusrissogit/Inventory.git Inventory
git clone https://github.com/andrusrissogit/Notification.git Notification

---

🐳 Ejecutar con Docker Compose

Este repositorio incluye un archivo docker-compose.yml listo para orquestar todo:

- Copia este archivo docker-compose.yml en la raíz donde clonaste Inventory y Notification.
- Modifica SA_PASSWORD para sqlserver_inventory y sqlserver_notification y ConnectionStrings__DefaultConnection para inventory.api y notification.api con la password de tu usuario sa de SQL Server.
- Desde esa carpeta, corre:

docker-compose up --build

Esto hará:

✅ Compilar ambos proyectos
✅ Descargar RabbitMQ y SQL Server
✅ Crear bases de datos
✅ Exponer puertos

---

🌐 Acceso a los servicios
Servicio	URL
Inventory API	http://localhost:5000/swagger
Notification API	http://localhost:5001/health (no tiene endpoints)
RabbitMQ UI	http://localhost:15673

RabbitMQ:

Usuario: guest
Contraseña: guest

---

🕒 Migraciones de Base de Datos
Si necesitas correr migraciones manualmente (antes modificar la password de tu usuario sa de SQL Server), puedes usar:

Inventory
dotnet ef database update --project ./Inventory/src/Inventory.API --startup-project ./Inventory/src/Inventory.API --connection "Server=localhost,1433;Database=InventoryDb;User Id=sa;Password=Pass123456;TrustServerCertificate=True;"

Notification
dotnet ef database update --project ./Notification/src/Notification.API --startup-project ./Notification/src/Notification.API --connection "Server=localhost,1434;Database=NotificationDb;User Id=sa;Password=Pass123456;TrustServerCertificate=True;"

---

❤️ Health Checks
Puedes verificar que todo funciona:

Inventory API Health: http://localhost:5000/health
Notification API Health: http://localhost:5001/health

---

🧼 Apagar todo
Para detener los servicios:
docker-compose down

Para eliminar volúmenes de datos:
docker-compose down  -v

---

Para levantar todo el ambiente, mss, bds y Rabbit hay script setup.ps1:

1. Abre PowerShell como Administrador.
2. Navega al directorio raíz de tu solución.
3. Editarlo modificando las Password de tu usuario sa de SQL Server.
4. Si nunca habilitaste scripts:
	Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
5. Ejecuta:
	.\Start-Environment.ps1

