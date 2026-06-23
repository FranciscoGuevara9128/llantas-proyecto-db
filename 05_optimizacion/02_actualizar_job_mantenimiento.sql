/*
================================================================================
SCRIPT:  02_actualizar_job_mantenimiento.sql
MÓDULO:  Optimización — Actualización del Job de Mantenimiento
================================================================================
DESCRIPCIÓN:
  Actualiza el Job_Llantas_Mantenimiento_Semanal para implementar:

  PASO 1 (actualizado): Mantenimiento condicional de índices por fragmentación
    - REORGANIZE cuando fragmentación está entre 10% y 30%
    - REBUILD     cuando fragmentación supera el 30%
    - Sin acción  cuando fragmentación es menor al 10%

  PASO 2 (nuevo): Verificación de integridad con DBCC CHECKDB
    - Detecta corrupción física en páginas y estructuras internas
    - Se ejecuta tras el mantenimiento de índices (domingo 02:00)
================================================================================
*/

USE [msdb];
GO

-- =============================================================================
-- PASO 1 DEL JOB: Actualizar con lógica condicional de fragmentación
-- =============================================================================
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Mantenimiento_Semanal')
BEGIN
    EXEC msdb.dbo.sp_update_jobstep
        @job_name   = N'Job_Llantas_Mantenimiento_Semanal',
        @step_id    = 1,
        @step_name  = N'Mantenimiento Condicional de Índices',
        @database_name = N'llantas',
        @command    = N'
SET NOCOUNT ON;

DECLARE @TableName     NVARCHAR(128);
DECLARE @IndexName     NVARCHAR(128);
DECLARE @Fragmentation FLOAT;
DECLARE @SQL           NVARCHAR(MAX);
DECLARE @RebuiltCount     INT = 0;
DECLARE @ReorganizedCount INT = 0;

PRINT ''Analizando fragmentación de índices...'';

DECLARE IndexCursor CURSOR FOR
SELECT
    OBJECT_NAME(i.object_id)       AS TableName,
    i.name                         AS IndexName,
    s.avg_fragmentation_in_percent AS Fragmentation
FROM sys.dm_db_index_physical_stats(DB_ID(N''llantas''), NULL, NULL, NULL, N''LIMITED'') AS s
INNER JOIN sys.indexes AS i
    ON  i.object_id = s.object_id
    AND i.index_id  = s.index_id
WHERE s.avg_fragmentation_in_percent > 10
  AND s.page_count > 100
  AND i.name IS NOT NULL
  AND i.is_disabled = 0
  AND OBJECT_NAME(i.object_id) IN (
        N''tblInvoiceMaster'', N''tblInvoiceDetail'',
        N''tblProductInventory'', N''tblInventoryKardex'',
        N''tblCustomer'', N''tblProductCatalog'',
        N''tblVendor'', N''tblReferralMaster'', N''tblReferralDetail''
  );

OPEN IndexCursor;
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        SET @SQL = N''ALTER INDEX ['' + @IndexName + N''] ON [dbo].['' + @TableName + N''] REBUILD WITH (ONLINE = OFF);'';
        SET @RebuiltCount += 1;
    END
    ELSE
    BEGIN
        SET @SQL = N''ALTER INDEX ['' + @IndexName + N''] ON [dbo].['' + @TableName + N''] REORGANIZE;'';
        SET @ReorganizedCount += 1;
    END
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;

EXEC sp_updatestats;

PRINT ''REBUILD: ''     + CAST(@RebuiltCount     AS NVARCHAR) + '' índice(s)'';
PRINT ''REORGANIZE: ''  + CAST(@ReorganizedCount AS NVARCHAR) + '' índice(s)'';
PRINT ''Mantenimiento de índices y estadísticas completado.'';

SET NOCOUNT OFF;
';

    PRINT '✔ Paso 1 del Job actualizado con lógica condicional de fragmentación.';
END
ELSE
    PRINT '⚠ Job [Job_Llantas_Mantenimiento_Semanal] no encontrado. Ejecuta primero 02_sql_jobs.sql.';
GO

-- =============================================================================
-- PASO 2 DEL JOB (NUEVO): Verificación de Integridad con DBCC CHECKDB
-- =============================================================================
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Mantenimiento_Semanal')
BEGIN
    -- Eliminar el paso 2 si ya existía (idempotente)
    IF EXISTS (
        SELECT 1
        FROM msdb.dbo.sysjobsteps js
        INNER JOIN msdb.dbo.sysjobs j ON j.job_id = js.job_id
        WHERE j.name = N'Job_Llantas_Mantenimiento_Semanal' AND js.step_id = 2
    )
    BEGIN
        EXEC msdb.dbo.sp_delete_jobstep
            @job_name = N'Job_Llantas_Mantenimiento_Semanal',
            @step_id  = 2;
    END

    EXEC msdb.dbo.sp_add_jobstep
        @job_name            = N'Job_Llantas_Mantenimiento_Semanal',
        @step_id             = 2,
        @step_name           = N'Verificación de Integridad DBCC CHECKDB',
        @subsystem           = N'TSQL',
        @database_name       = N'master',
        @on_success_action   = 1,   -- Quit with success
        @on_fail_action      = 2,   -- Quit with failure
        @command             = N'
PRINT ''Iniciando verificación de integridad física de [llantas]...'';

DBCC CHECKDB (N''llantas'')
    WITH NO_INFOMSGS,
         ALL_ERRORMSGS;

PRINT ''Verificación de integridad completada.'';
';

    -- Asegurar que el paso 1 lleva al paso 2 al completarse con éxito
    EXEC msdb.dbo.sp_update_jobstep
        @job_name          = N'Job_Llantas_Mantenimiento_Semanal',
        @step_id           = 1,
        @on_success_action = 3,   -- Go to next step
        @on_fail_action    = 2;   -- Quit with failure

    PRINT '✔ Paso 2 (DBCC CHECKDB) agregado al Job de mantenimiento.';
END
GO

PRINT '';
PRINT '✔ Job_Llantas_Mantenimiento_Semanal actualizado:';
PRINT '    Paso 1 → Mantenimiento condicional de índices (REORGANIZE / REBUILD)';
PRINT '    Paso 2 → Verificación de integridad (DBCC CHECKDB)';
GO
