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
│   └── 01_mantenimiento_preventivo.sql  ← Rebuild de índices y sp_updatestats
│
├── 06_respaldo_recuperacion/
│   └── 01_configuracion_backup.sql      ← Recovery FULL, Full Backup, Log Backup y prueba de restauración
│
├── 07_monitoreo_automatizacion/
│   ├── 01_alertas_eventos.sql    ← Extended Events (XEvents) para errores críticos
│   └── 02_sql_jobs.sql           ← SQL Server Agent Jobs programados
│
└── backup/                       ← Archivos generados (ignorados por Git)
```

---

## ⚙️ Requisitos

- SQL Server instalado (Express o superior)
- Herramienta `sqlcmd` disponible en el sistema
- SQL Server Agent activo (requerido para la Fase 7)

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

El archivo `00_setup.sql` ejecuta en orden las 7 fases del proyecto:

| Fase | Descripción |
|------|-------------|
| **1** | Creación de tablas, relaciones e índices |
| **2** | Inserción de datos iniciales de prueba |
| **3** | Aplicación de migraciones y refactorizaciones de esquema |
| **4** | Configuración de logins, roles, permisos y auditoría |
| **5** | Mantenimiento preventivo de índices y estadísticas |
| **6** | Configuración del Recovery Model FULL y generación de backups iniciales |
| **7** | Activación de Extended Events y programación de SQL Agent Jobs |

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
| `Rol_Facturacion` | DML en ventas y clientes. Prohibido borrar facturas o modificar catálogo. |
| `Rol_Auditor` | Solo lectura en todas las tablas. Sin modificaciones. |
| `Rol_Admin_Jr` | DML completo + `VIEW DEFINITION` para soporte técnico. |

---

## 💾 Respaldo y Recuperación (Fase 6)

- **Recovery Model:** FULL
- **Full Backup:** `backup/llantas_full.bak`
- **Log Backup:** `backup/llantas_log.bak`
- **Prueba de restauración:** crea `llantas_Restaurada` para validar la cadena de backups
- **Fallback automático** a la ruta del sistema si la ruta del proyecto no tiene permisos de escritura

> Los archivos generados en `backup/` están excluidos del control de versiones (ver `.gitignore`).

---

## ⏰ Jobs Automatizados (Fase 7)

| Job | Programación |
|-----|-------------|
| `Job_Llantas_Respaldo_Full_Semanal` | Domingos a las 00:00 |
| `Job_Llantas_Respaldo_Log_Frecuente` | Lun–Sáb cada 2 horas |
| `Job_Llantas_Mantenimiento_Semanal` | Domingos a las 02:00 |

---

## 🧾 Notas

- El uso de rutas relativas en el script maestro permite la portabilidad del proyecto
- La ejecución mediante `sqlcmd` garantiza el correcto procesamiento de los comandos `:r`
- La estructura modular facilita el mantenimiento y la trazabilidad
- Los archivos de backup (`.bak`, `.mdf`, `.ldf`) no se incluyen en el repositorio
