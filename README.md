# Proyecto Base de Datos - Llantas

## 📌 Descripción

Este proyecto contiene la estructura completa de una base de datos para la gestión de inventario, clientes, proveedores y facturación de una distribuidora de llantas.

Incluye el ciclo de vida completo de administración de base de datos:

- Creación de tablas, relaciones e índices
- Datos iniciales de prueba
- Control de versiones y migraciones de esquema
- Seguridad, roles y auditoría
- Optimización y mantenimiento preventivo
- Respaldo y recuperación ante desastres
- Monitoreo activo y automatización de tareas
- Objetos programables: vistas, procedimientos almacenados

---

## 📁 Estructura del proyecto

```
llantas-Proyecto/
│
├── 00_setup.sql                  ← Script maestro orquestador (SQLCMD)
├── drop_tables.sql               ← Script de limpieza / reset
│
├── 01_esquema/
│   ├── tablas.sql                ← Definición de todas las tablas
│   ├── relaciones.sql            ← FK, constraints y triggers
│   └── indices.sql               ← Índices clustered y nonclustered
│
├── 02_datos_iniciales/
│   └── inserts.sql               ← Datos de prueba iniciales
│
├── 03_cambios/
│   ├── 202604122326_Refactor_tblCustomer.sql
│   ├── 202605180050_Refactor_All_Tables_To_English_PascalCase.sql
│   └── 202605180045_Add_Performance_Indexes.sql
│
├── 04_seguridad/
│   ├── 01_logins_usuarios.sql    ← Logins de servidor y usuarios de BD
│   ├── 02_roles_permisos.sql     ← Roles personalizados y permisos
│   └── 03_auditoria.sql          ← Server Audit y Database Audit Specification
│
├── 05_optimizacion/
│   ├── 01_mantenimiento_preventivo.sql  ← Mantenimiento condicional + DBCC CHECKDB
│   └── 02_actualizar_job_mantenimiento.sql  ← Actualiza el Job con los 2 pasos
│
├── 06_respaldo_recuperacion/
│   └── 01_configuracion_backup.sql      ← Recovery FULL, backups y prueba de restauración
│
├── 07_monitoreo_automatizacion/
│   ├── 01_alertas_eventos.sql    ← Extended Events: sesión Error_Session_Llantas
│   ├── 02_sql_jobs.sql           ← SQL Server Agent Jobs programados
│   ├── 03_database_mail.sql      ← Database Mail (Gmail SMTP) + operador + notificaciones
│   └── 04_consultas_xevents.sql  ← Consultas de análisis del Ring Buffer y Event File
│
├── 08_objetos_programables/
│   ├── 01_vistas.sql             ← Vistas (prefijo vw_)
│   └── 02_procedimientos.sql     ← Procedimientos almacenados (prefijo usp_)
│
└── backup/                       ← Archivos generados (ignorados por Git)
```

---

## ⚙️ Requisitos

- SQL Server instalado (Express o superior)
- Herramienta `sqlcmd` disponible en el sistema
- SQL Server Agent activo (requerido para las Fases 7 y 8)

---

## 🚀 Ejecución del proyecto

### ⚠️ IMPORTANTE

El script `00_setup.sql` utiliza comandos `:r` de SQLCMD, por lo tanto:

❌ **NO funciona correctamente desde SSMS (SQL Server Management Studio)**  
✅ **Debe ejecutarse desde la terminal**

---

## ▶️ Ejecución paso a paso

1. Abrir terminal (PowerShell o CMD)
2. Navegar a la carpeta del proyecto
3. Ejecutar el script maestro:

```bash
sqlcmd -S localhost -i "00_setup.sql"
```

---

## 📌 ¿Qué hace el script maestro?

El archivo `00_setup.sql` ejecuta en orden las 8 fases del proyecto:

| Fase | Descripción |
|------|-------------|
| **1** | Creación de tablas, relaciones e índices |
| **2** | Inserción de datos iniciales de prueba |
| **3** | Aplicación de migraciones y refactorizaciones de esquema |
| **4** | Configuración de logins, roles, permisos y auditoría |
| **5** | Mantenimiento preventivo de índices (condicional) y verificación de integridad |
| **6** | Configuración del Recovery Model FULL y generación de backups iniciales |
| **7** | Extended Events, SQL Agent Jobs, Database Mail y consultas de análisis |
| **8** | Creación de vistas y procedimientos almacenados |

---

## 🗃️ Modelo de datos (tablas principales)

| Tabla | Descripción |
|-------|-------------|
| `tblCustomer` | Clientes |
| `tblVendor` | Proveedores |
| `tblVendorContact` | Contactos de proveedor |
| `tblVendorRepresentative` | Representantes de proveedor |
| `tblProductCatalog` | Catálogo de productos (llantas) |
| `tblProductCategory` | Categorías de producto |
| `tblBrand` | Marcas |
| `tblUnitOfMeasure` | Unidades de medida |
| `tblStatus` | Catálogo de estados |
| `tblProductInventory` | Inventario de existencias |
| `tblInventoryKardex` | Kardex de inventario |
| `tblKardexTransaction` | Transacciones de kardex |
| `tblPriceHistory` | Historial de precios |
| `tblInvoiceMaster` | Cabecera de facturas |
| `tblInvoiceDetail` | Detalle de facturas |
| `tblReferralMaster` | Cabecera de remisiones |
| `tblReferralDetail` | Detalle de remisiones |

---

## 🔐 Seguridad (Fase 4)

El proyecto implementa tres roles con permisos diferenciados:

| Rol | Acceso |
|-----|--------|
| `Rol_Facturacion` | DML en ventas y clientes. `DENY DELETE` en facturas. `DENY INSERT/UPDATE/DELETE` en catálogo. |
| `Rol_Auditor` | `SELECT` en todas las tablas. `DENY` global de escritura. |
| `Rol_Admin_Jr` | DML completo + `VIEW DEFINITION` para soporte técnico. |

**Auditoría activa:**
- `Server Audit` → captura `FAILED_LOGIN_GROUP` en `APPLICATION_LOG`
- `Database Audit Specification` → monitorea DML en tablas críticas y cambios de esquema (`SCHEMA_OBJECT_CHANGE_GROUP`)
- Triggers `AFTER UPDATE` en todas las tablas para registrar `ModificationDate` y `ModificationUser`

---

## 🛠️ Plan de Mantenimiento (Fase 5)

El mantenimiento preventivo se ejecuta en dos etapas:

### Etapa 1 — Mantenimiento condicional de índices

| Fragmentación | Acción |
|---|---|
| < 10% | Sin acción (costo > beneficio) |
| 10% – 30% | `REORGANIZE` — reorganiza páginas en línea sin bloquear |
| > 30% | `REBUILD` — reconstrucción completa del índice |

### Etapa 2 — Verificación de integridad

```sql
DBCC CHECKDB ('llantas') WITH NO_INFOMSGS, ALL_ERRORMSGS;
```

Detecta corrupción física en páginas y estructuras internas de la base de datos.

**Job automatizado:** `Job_Llantas_Mantenimiento_Semanal` (domingos 02:00)
- Paso 1: Mantenimiento condicional de índices + `sp_updatestats`
- Paso 2: `DBCC CHECKDB`

---

## 💾 Respaldo y Recuperación (Fase 6)

- **Recovery Model:** FULL
- **Full Backup:** `backup/llantas_full.bak`
- **Log Backup:** `backup/llantas_log.bak`
- **Prueba de restauración:** crea `llantas_Restaurada` para validar la cadena de backups
- **Fallback automático** a la ruta del sistema si la ruta del proyecto no tiene permisos

> Los archivos generados en `backup/` están excluidos del control de versiones (ver `.gitignore`).

---

## 📡 Monitoreo y Automatización (Fase 7)

### Extended Events

Sesión `Error_Session_Llantas` — captura errores con `severity >= 17`:

| Target | Descripción |
|---|---|
| `ring_buffer` | Últimos eventos en memoria RAM (consulta inmediata) |
| `event_file` | Eventos persistidos en disco (`Error_Session_Llantas*.xel`) |

**Análisis:** `04_consultas_xevents.sql` incluye consultas listas para demostrar la captura en tiempo real durante la exposición.

### SQL Server Agent Jobs

| Job | Programación |
|-----|-------------|
| `Job_Llantas_Respaldo_Full_Semanal` | Domingos a las 00:00 |
| `Job_Llantas_Respaldo_Log_Frecuente` | Lun–Sáb cada 2 horas |
| `Job_Llantas_Mantenimiento_Semanal` | Domingos a las 02:00 (2 pasos) |

### Database Mail

- **Cuenta:** `Cuenta_Llantas_Gmail` → `smtp.gmail.com:587` (TLS)
- **Perfil:** `Perfil_Llantas` (predeterminado público)
- **Operador:** `Operador_DBA_Llantas` → notificaciones automáticas en caso de fallo de cualquier Job

---

## 🧩 Objetos Programables (Fase 8)

### Vistas (`vw_`)

| Vista | Descripción |
|-------|-------------|
| `vw_InvoiceComplete` | Factura completa: cabecera + detalle + cliente + producto + marca |
| `vw_InventoryStatus` | Stock actual con semáforo: Crítico / Bajo / Normal / Excedente |
| `vw_SalesSummaryByProduct` | Ventas totales por producto: unidades, ingresos, precio promedio |
| `vw_VendorDirectory` | Directorio de proveedores con representantes y contactos |

### Procedimientos Almacenados (`usp_`)

| Procedimiento | Parámetros | Descripción |
|---|---|---|
| `usp_GetCustomerInvoices` | `@IDCustomer`, `@StartDate?`, `@EndDate?` | Historial de facturas de un cliente con filtro de fecha |
| `usp_GetLowStockProducts` | `@CriticalOnly?` | Productos bajo el mínimo de stock con costo estimado de reposición |
| `usp_GetProductPriceHistory` | `@IDProduct` | Historial de precios con precio vigente identificado |
| `usp_GetSalesReport` | `@StartDate`, `@EndDate` | Reporte de ventas por producto con totales (`GROUP BY ROLLUP`) |

---

## 🧾 Notas

- El uso de rutas relativas en el script maestro permite la portabilidad del proyecto
- La ejecución mediante `sqlcmd` garantiza el correcto procesamiento de los comandos `:r`
- La estructura modular facilita el mantenimiento y la trazabilidad
- Los archivos de backup (`.bak`, `.mdf`, `.ldf`) no se incluyen en el repositorio
