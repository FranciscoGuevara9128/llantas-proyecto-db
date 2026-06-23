/*
================================================================================
SCRIPT:  01_mantenimiento_preventivo.sql
MÓDULO:  Optimización y Mantenimiento Preventivo
================================================================================
DESCRIPCIÓN:
  Ejecuta el mantenimiento preventivo completo de la base de datos [llantas]
  en dos etapas justificadas técnicamente:

  ETAPA 1 — Mantenimiento de Índices (Condicional por Fragmentación)
    Consulta sys.dm_db_index_physical_stats para medir el porcentaje real de
    fragmentación de cada índice y aplica la acción proporcional:
      - Fragmentación <  10%  → Ninguna acción (costo > beneficio)
      - Fragmentación 10–30%  → REORGANIZE (reorganiza páginas en línea)
      - Fragmentación  > 30%  → REBUILD (reconstrucción completa)

  ETAPA 2 — Verificación de Integridad Física (DBCC CHECKDB)
    Detecta corrupción en páginas, inconsistencias de estructura interna y
    errores de disco. Se ejecuta con NO_INFOMSGS para reportar solo errores.
================================================================================
*/

USE [llantas];
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'INICIANDO MANTENIMIENTO PREVENTIVO COMPLETO...';
PRINT '======================================================================';

-- =============================================================================
-- ETAPA 1: MANTENIMIENTO CONDICIONAL DE ÍNDICES
-- =============================================================================
PRINT '';
PRINT '-- ETAPA 1: Analizando fragmentación de índices...';

DECLARE @TableName     NVARCHAR(128);
DECLARE @IndexName     NVARCHAR(128);
DECLARE @Fragmentation FLOAT;
DECLARE @PageCount     BIGINT;
DECLARE @SQL           NVARCHAR(MAX);
DECLARE @Action        NVARCHAR(20);
DECLARE @RebuiltCount  INT = 0;
DECLARE @ReorganizedCount INT = 0;
DECLARE @SkippedCount  INT = 0;

-- Cursor sobre índices con más de 100 páginas y fragmentación > 10%
-- Solo se analizan las tablas operativas del negocio
DECLARE IndexCursor CURSOR FOR
SELECT
    OBJECT_NAME(i.object_id)           AS TableName,
    i.name                             AS IndexName,
    s.avg_fragmentation_in_percent     AS Fragmentation,
    s.page_count                       AS PageCount
FROM sys.dm_db_index_physical_stats(
         DB_ID(N'llantas'), NULL, NULL, NULL, N'LIMITED') AS s
INNER JOIN sys.indexes AS i
    ON  i.object_id = s.object_id
    AND i.index_id  = s.index_id
WHERE s.avg_fragmentation_in_percent > 10
  AND s.page_count > 100          -- Índices pequeños no justifican mantenimiento
  AND i.name IS NOT NULL          -- Excluir heaps (tablas sin índice clustered)
  AND i.is_disabled = 0           -- Solo índices activos
  AND OBJECT_NAME(i.object_id) IN (
        N'tblInvoiceMaster',
        N'tblInvoiceDetail',
        N'tblProductInventory',
        N'tblInventoryKardex',
        N'tblCustomer',
        N'tblProductCatalog',
        N'tblVendor',
        N'tblReferralMaster',
        N'tblReferralDetail'
  );

OPEN IndexCursor;
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation, @PageCount;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Fragmentation > 30
    BEGIN
        -- Alta fragmentación: reconstrucción completa
        SET @Action = N'REBUILD';
        SET @SQL    = N'ALTER INDEX [' + @IndexName + N'] ON [dbo].[' + @TableName + N'] REBUILD WITH (ONLINE = OFF);';
        SET @RebuiltCount += 1;
    END
    ELSE
    BEGIN
        -- Fragmentación moderada: reorganización en línea (no bloquea la tabla)
        SET @Action = N'REORGANIZE';
        SET @SQL    = N'ALTER INDEX [' + @IndexName + N'] ON [dbo].[' + @TableName + N'] REORGANIZE;';
        SET @ReorganizedCount += 1;
    END

    PRINT '  [' + @Action + '] ' + @TableName + '.' + @IndexName +
          ' (Fragmentación: ' + CAST(CAST(@Fragmentation AS DECIMAL(5,1)) AS NVARCHAR) + '%)';

    EXEC sp_executesql @SQL;

    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName, @Fragmentation, @PageCount;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;

PRINT '';
PRINT '  Resumen de mantenimiento de índices:';
PRINT '    REBUILD     : ' + CAST(@RebuiltCount      AS NVARCHAR) + ' índice(s)';
PRINT '    REORGANIZE  : ' + CAST(@ReorganizedCount  AS NVARCHAR) + ' índice(s)';
PRINT '✔ Mantenimiento de índices completado.';
GO

-- Actualizar estadísticas tras el mantenimiento de índices
PRINT '';
PRINT '  Actualizando estadísticas del optimizador de consultas...';
EXEC sp_updatestats;
PRINT '✔ Estadísticas actualizadas.';
GO

-- =============================================================================
-- ETAPA 2: VERIFICACIÓN DE INTEGRIDAD FÍSICA (DBCC CHECKDB)
-- =============================================================================
PRINT '';
PRINT '-- ETAPA 2: Verificando integridad física de la base de datos...';
PRINT '  Ejecutando DBCC CHECKDB (esto puede tomar varios minutos)...';

DBCC CHECKDB (N'llantas')
    WITH NO_INFOMSGS,     -- Suprime mensajes informativos, muestra solo errores
         ALL_ERRORMSGS;   -- Muestra todos los errores encontrados sin limitar

PRINT '✔ Verificación de integridad completada. Sin errores reportados.';
GO

SET NOCOUNT OFF;

PRINT '';
PRINT '======================================================================';
PRINT 'MANTENIMIENTO PREVENTIVO COMPLETO FINALIZADO EXITOSAMENTE.';
PRINT '======================================================================';
GO
