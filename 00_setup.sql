/*
===========================================================================
 SCRIPT MAESTRO - CONFIGURACIÓN Y ORQUESTACIÓN DE BASE DE DATOS [llantas]
===========================================================================

IMPORTANTE:

Este script utiliza comandos :r (SQLCMD), por lo tanto:

❌ NO debe ejecutarse desde SQL Server Management Studio (SSMS) normal,
   a menos que active explícitamente el "SQLCMD Mode" en el menú "Query".

✅ Debe ejecutarse desde terminal (PowerShell o CMD) usando sqlcmd:

   sqlcmd -S localhost -i "00_setup.sql"

---------------------------------------------------------------------------
DESCRIPCIÓN:
Orquesta de principio a fin el ciclo de vida del despliegue del proyecto:
1. Esquema Base (Tablas, Relaciones y Constraints, Índices)
2. Inserción de Datos de Prueba Iniciales
3. Historial de Cambios (Refactorización a Inglés PascalCase e Índices de Cobertura)
4. Seguridad y Gobierno de Datos (Logins, Roles, Permisos y Auditoría)
5. Optimización (Mantenimiento preventivo de índices y estadísticas)
6. Respaldo y Recuperación (Recovery FULL y cadena de Backups iniciales)
7. Monitoreo y Automatización (XEvents y SQL Server Agent Jobs programados)

===========================================================================
*/

PRINT '=== INICIANDO DESPLIEGUE COMPLETO DE BASE DE DATOS [llantas] ===';
GO

-- -------------------------------------------------------------------------
-- FASE 1: INFRAESTRUCTURA Y ESQUEMA BASE ORIGINAL
-- -------------------------------------------------------------------------
PRINT 'FASE 1: Desplegando estructura base...';
:r ".\01_esquema\tablas.sql"
GO
:r ".\01_esquema\relaciones.sql"
GO
:r ".\01_esquema\indices.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 2: CARGA DE DATOS INICIALES
-- -------------------------------------------------------------------------
PRINT 'FASE 2: Cargando datos iniciales de prueba...';
:r ".\02_datos_iniciales\inserts.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 3: APLICACIÓN DE HISTORIAL DE CAMBIOS (REFACTORIZACIÓN E ÍNDICES)
-- -------------------------------------------------------------------------
PRINT 'FASE 3: Aplicando control de versiones y cambios de esquema...';
:r ".\03_cambios\202604122326_Refactor_tblCustomer.sql"
GO
:r ".\03_cambios\202605180050_Refactor_All_Tables_To_English_PascalCase.sql"
GO
:r ".\03_cambios\202605180045_Add_Performance_Indexes.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 4: SEGURIDAD, ACCESOS Y GOBIERNO DE DATOS
-- -------------------------------------------------------------------------
PRINT 'FASE 4: Configurando perfiles de seguridad, roles y auditoría server/db...';
:r ".\04_seguridad\01_logins_usuarios.sql"
GO
:r ".\04_seguridad\02_roles_permisos.sql"
GO
:r ".\04_seguridad\03_auditoria.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 5: OPTIMIZACIÓN Y MANTENIMIENTO PREVENTIVO
-- -------------------------------------------------------------------------
PRINT 'FASE 5: Ejecutando optimización y mantenimiento preventivo de índices...';
:r ".\05_optimizacion\01_mantenimiento_preventivo.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 6: ESTRATEGIA DE RESPALDO Y RECUPERACIÓN ANTE DESASTRES
-- -------------------------------------------------------------------------
PRINT 'FASE 6: Configurando Recovery Model FULL y generando backups iniciales...';
:r ".\06_respaldo_recuperacion\01_configuracion_backup.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 7: MONITOREO ACTIVO Y AUTOMATIZACIÓN DE TAREAS DBA
-- -------------------------------------------------------------------------
PRINT 'FASE 7: Activando Extended Events y programando SQL Server Agent Jobs...';
:r ".\07_monitoreo_automatizacion\01_alertas_eventos.sql"
GO
:r ".\07_monitoreo_automatizacion\02_sql_jobs.sql"
GO

-- -------------------------------------------------------------------------
-- FASE 8: OBJETOS PROGRAMABLES (VISTAS Y PROCEDIMIENTOS ALMACENADOS)
-- -------------------------------------------------------------------------
PRINT 'FASE 8: Creando vistas y procedimientos almacenados...';
:r ".\08_objetos_programables\01_vistas.sql"
GO
:r ".\08_objetos_programables\02_procedimientos.sql"
GO

PRINT '=== ¡DESPLIEGUE GLOBAL DE LA BASE DE DATOS FINALIZADO EXITOSAMENTE! ===';
GO