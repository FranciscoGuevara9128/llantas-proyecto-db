/*
================================================================================
SCRIPT: 01_configuracion_backup.sql
MODULO: Respaldo y Recuperación (Idempotente, Portable y Auto-tolerante a fallos)
================================================================================
*/

USE [master];
GO

DECLARE @RecoveryModel NVARCHAR(60);
SELECT @RecoveryModel = recovery_model_desc 
FROM sys.databases 
WHERE name = 'llantas';

-- Cambiar a FULL de forma segura si no lo está
IF @RecoveryModel <> 'FULL'
BEGIN
    ALTER DATABASE [llantas] SET RECOVERY FULL;
END
GO

-- -----------------------------------------------------------------------------
-- CONFIGURACIÓN DE RUTAS (Modifica esta ruta si deseas otra carpeta del proyecto)
-- -----------------------------------------------------------------------------
DECLARE @ProjectBackupDir NVARCHAR(500) = N'C:\Users\frang\Documents\Gestion Base Datos II\llantas-Proyecto\backup\';

-- Variables de trabajo dinámicas
DECLARE @FullBackupPath NVARCHAR(500);
DECLARE @LogBackupPath NVARCHAR(500);
DECLARE @RestoredMdfPath NVARCHAR(500);
DECLARE @RestoredLdfPath NVARCHAR(500);
DECLARE @Sql NVARCHAR(MAX);
DECLARE @UseDefaultFallback BIT = 0;

-- Intentar validar si la ruta de proyecto termina con barra diagonal
IF RIGHT(@ProjectBackupDir, 1) <> '\' SET @ProjectBackupDir = @ProjectBackupDir + '\';

-- Construir rutas deseadas en el proyecto
SET @FullBackupPath = @ProjectBackupDir + N'llantas_full.bak';
SET @LogBackupPath = @ProjectBackupDir + N'llantas_log.bak';
SET @RestoredMdfPath = @ProjectBackupDir + N'llantas_Restaurada.mdf';
SET @RestoredLdfPath = @ProjectBackupDir + N'llantas_Restaurada_log.ldf';

-- -----------------------------------------------------------------------------
-- 1. RESPALDO COMPLETO INICIAL
-- -----------------------------------------------------------------------------
PRINT 'Generando respaldo completo de la base de datos [llantas]...';
BEGIN TRY
    SET @Sql = N'BACKUP DATABASE [llantas] TO DISK = @path WITH FORMAT, INIT, NAME = N''llantas - Respaldo Completo'', STATS = 10';
    EXEC sp_executesql @Sql, N'@path NVARCHAR(500)', @FullBackupPath;
    PRINT '✔ Respaldo completo guardado exitosamente en la ruta del proyecto: ' + @FullBackupPath;
END TRY
BEGIN CATCH
    PRINT '⚠ La ruta de proyecto no está disponible o no tiene permisos de escritura en esta PC. Activando fallback a la ruta del sistema por defecto...';
    SET @UseDefaultFallback = 1;
    
    -- Obtener la ruta de backup por defecto desde el registro
    DECLARE @DefaultBackupDir NVARCHAR(4000);
    EXEC master.dbo.xp_instance_regread
        N'HKEY_LOCAL_MACHINE',
        N'Software\Microsoft\MSSQLServer\MSSQLServer',
        N'BackupDirectory',
        @DefaultBackupDir OUTPUT;
        
    IF @DefaultBackupDir IS NULL
    BEGIN
        SET @FullBackupPath = N'llantas_full.bak';
    END
    ELSE
    BEGIN
        IF RIGHT(@DefaultBackupDir, 1) <> '\' SET @DefaultBackupDir = @DefaultBackupDir + '\';
        SET @FullBackupPath = @DefaultBackupDir + N'llantas_full.bak';
    END
    
    SET @Sql = N'BACKUP DATABASE [llantas] TO DISK = @path WITH FORMAT, INIT, NAME = N''llantas - Respaldo Completo'', STATS = 10';
    EXEC sp_executesql @Sql, N'@path NVARCHAR(500)', @FullBackupPath;
    PRINT '✔ Respaldo completo guardado en la ruta del sistema por defecto: ' + @FullBackupPath;
END CATCH
GO

-- -----------------------------------------------------------------------------
-- 2. RESPALDO DE LOG INICIAL
-- -----------------------------------------------------------------------------
PRINT 'Generando respaldo del log de transacciones...';
-- Volvemos a declarar variables ya que es un nuevo lote (GO)
DECLARE @ProjectBackupDir NVARCHAR(500) = N'C:\Users\frang\Documents\Gestion Base Datos II\llantas-Proyecto\backup\';
DECLARE @FullBackupPath NVARCHAR(500);
DECLARE @LogBackupPath NVARCHAR(500);
DECLARE @RestoredMdfPath NVARCHAR(500);
DECLARE @RestoredLdfPath NVARCHAR(500);
DECLARE @Sql NVARCHAR(MAX);
DECLARE @UseDefaultFallback BIT = 0;

IF RIGHT(@ProjectBackupDir, 1) <> '\' SET @ProjectBackupDir = @ProjectBackupDir + '\';
SET @FullBackupPath = @ProjectBackupDir + N'llantas_full.bak';
SET @LogBackupPath = @ProjectBackupDir + N'llantas_log.bak';
SET @RestoredMdfPath = @ProjectBackupDir + N'llantas_Restaurada.mdf';
SET @RestoredLdfPath = @ProjectBackupDir + N'llantas_Restaurada_log.ldf';

BEGIN TRY
    -- Comprobar si no existe la base de datos para simular error en caso de que falle la ruta
    IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'llantas') THROW 50000, 'Error', 1;
    
    SET @Sql = N'BACKUP LOG [llantas] TO DISK = @path WITH FORMAT, INIT, NAME = N''llantas - Respaldo del Log'', STATS = 10';
    EXEC sp_executesql @Sql, N'@path NVARCHAR(500)', @LogBackupPath;
    PRINT '✔ Respaldo del log guardado exitosamente en la ruta del proyecto: ' + @LogBackupPath;
END TRY
BEGIN CATCH
    -- Fallback a ruta por defecto
    DECLARE @DefaultBackupDir NVARCHAR(4000);
    EXEC master.dbo.xp_instance_regread
        N'HKEY_LOCAL_MACHINE',
        N'Software\Microsoft\MSSQLServer\MSSQLServer',
        N'BackupDirectory',
        @DefaultBackupDir OUTPUT;
        
    IF @DefaultBackupDir IS NULL
    BEGIN
        SET @LogBackupPath = N'llantas_log.bak';
    END
    ELSE
    BEGIN
        IF RIGHT(@DefaultBackupDir, 1) <> '\' SET @DefaultBackupDir = @DefaultBackupDir + '\';
        SET @LogBackupPath = @DefaultBackupDir + N'llantas_log.bak';
    END
    
    SET @Sql = N'BACKUP LOG [llantas] TO DISK = @path WITH FORMAT, INIT, NAME = N''llantas - Respaldo del Log'', STATS = 10';
    EXEC sp_executesql @Sql, N'@path NVARCHAR(500)', @LogBackupPath;
    PRINT '✔ Respaldo del log guardado en la ruta del sistema por defecto: ' + @LogBackupPath;
END CATCH
GO

-- -----------------------------------------------------------------------------
-- 3. VALIDACIÓN: PRUEBA DE RESTAURACIÓN CON OTRO NOMBRE (llantas_Restaurada)
-- -----------------------------------------------------------------------------
PRINT 'Validando respaldo mediante restauración de prueba (llantas_Restaurada)...';

-- Eliminar base de datos de prueba si ya existe
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'llantas_Restaurada')
BEGIN
    ALTER DATABASE [llantas_Restaurada] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [llantas_Restaurada];
END
GO

DECLARE @ProjectBackupDir NVARCHAR(500) = N'C:\Users\frang\Documents\Gestion Base Datos II\llantas-Proyecto\backup\';
DECLARE @FullBackupPath NVARCHAR(500);
DECLARE @LogBackupPath NVARCHAR(500);
DECLARE @RestoredMdfPath NVARCHAR(500);
DECLARE @RestoredLdfPath NVARCHAR(500);
DECLARE @Sql NVARCHAR(MAX);

IF RIGHT(@ProjectBackupDir, 1) <> '\' SET @ProjectBackupDir = @ProjectBackupDir + '\';
SET @FullBackupPath = @ProjectBackupDir + N'llantas_full.bak';
SET @LogBackupPath = @ProjectBackupDir + N'llantas_log.bak';
SET @RestoredMdfPath = @ProjectBackupDir + N'llantas_Restaurada.mdf';
SET @RestoredLdfPath = @ProjectBackupDir + N'llantas_Restaurada_log.ldf';

BEGIN TRY
    -- Intentar restaurar en la ruta del proyecto
    SET @Sql = N'RESTORE DATABASE [llantas_Restaurada] FROM DISK = @fullPath WITH REPLACE, MOVE N''llantas'' TO @mdfPath, MOVE N''llantas_log'' TO @ldfPath, NORECOVERY, STATS = 10';
    EXEC sp_executesql @Sql, 
        N'@fullPath NVARCHAR(500), @mdfPath NVARCHAR(500), @ldfPath NVARCHAR(500)', 
        @FullBackupPath, @RestoredMdfPath, @RestoredLdfPath;
        
    SET @Sql = N'RESTORE LOG [llantas_Restaurada] FROM DISK = @logPath WITH RECOVERY, STATS = 10';
    EXEC sp_executesql @Sql, N'@logPath NVARCHAR(500)', @LogBackupPath;
    
    PRINT '✔ Validación de restauración completada exitosamente en la ruta del proyecto.';
END TRY
BEGIN CATCH
    PRINT '⚠ Falló la restauración en la ruta del proyecto. Intentando en la ruta por defecto del sistema...';
    
    -- Fallback de rutas de backup
    DECLARE @DefaultBackupDir NVARCHAR(4000);
    EXEC master.dbo.xp_instance_regread
        N'HKEY_LOCAL_MACHINE',
        N'Software\Microsoft\MSSQLServer\MSSQLServer',
        N'BackupDirectory',
        @DefaultBackupDir OUTPUT;
        
    IF @DefaultBackupDir IS NULL
    BEGIN
        SET @FullBackupPath = N'llantas_full.bak';
        SET @LogBackupPath = N'llantas_log.bak';
    END
    ELSE
    BEGIN
        IF RIGHT(@DefaultBackupDir, 1) <> '\' SET @DefaultBackupDir = @DefaultBackupDir + '\';
        SET @FullBackupPath = @DefaultBackupDir + N'llantas_full.bak';
        SET @LogBackupPath = @DefaultBackupDir + N'llantas_log.bak';
    END
    
    -- En la ruta por defecto no movemos a carpetas específicas, dejamos que SQL Server use sus rutas por defecto
    -- Para hacer esto en MOVE, especificamos solo el nombre del archivo y SQL Server lo ubica en su DATA folder
    SET @RestoredMdfPath = N'llantas_Restaurada.mdf';
    SET @RestoredLdfPath = N'llantas_Restaurada_log.ldf';
    
    SET @Sql = N'RESTORE DATABASE [llantas_Restaurada] FROM DISK = @fullPath WITH REPLACE, MOVE N''llantas'' TO @mdfPath, MOVE N''llantas_log'' TO @ldfPath, NORECOVERY, STATS = 10';
    EXEC sp_executesql @Sql, 
        N'@fullPath NVARCHAR(500), @mdfPath NVARCHAR(500), @ldfPath NVARCHAR(500)', 
        @FullBackupPath, @RestoredMdfPath, @RestoredLdfPath;
        
    SET @Sql = N'RESTORE LOG [llantas_Restaurada] FROM DISK = @logPath WITH RECOVERY, STATS = 10';
    EXEC sp_executesql @Sql, N'@logPath NVARCHAR(500)', @LogBackupPath;
    
    PRINT '✔ Validación de restauración completada en la ruta por defecto del sistema.';
END CATCH
GO
