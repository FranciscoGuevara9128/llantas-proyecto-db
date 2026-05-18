/*
================================================================================
SCRIPT: 02_sql_jobs.sql
MODULO: Automatización y Tareas Programadas (Simplificado)
================================================================================
*/

USE [msdb];
GO

-- =============================================================================
-- 1. ELIMINAR JOBS ANTERIORES SI EXISTEN (Para asegurar idempotencia)
-- =============================================================================
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Respaldo_Diario')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Llantas_Respaldo_Diario', @delete_unused_schedule = 1;
END

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Respaldo_Full_Semanal')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Llantas_Respaldo_Full_Semanal', @delete_unused_schedule = 1;
END

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Respaldo_Log_Frecuente')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Llantas_Respaldo_Log_Frecuente', @delete_unused_schedule = 1;
END

IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Mantenimiento_Semanal')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job_Llantas_Mantenimiento_Semanal', @delete_unused_schedule = 1;
END
GO


-- =============================================================================
-- 2. CREACIÓN DEL JOB: Job_Llantas_Respaldo_Full_Semanal
-- =============================================================================
DECLARE @JobId BINARY(16);

EXEC msdb.dbo.sp_add_job 
    @job_name = N'Job_Llantas_Respaldo_Full_Semanal', 
    @enabled = 1, 
    @description = N'Respaldo COMPLETO semanal los domingos a las 00:00.', 
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep 
    @job_id = @JobId, 
    @step_name = N'Generar Respaldo Full', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2, 
    @database_name = N'master', 
    @command = N'
DECLARE @BackupFile VARCHAR(500);
DECLARE @DateTimeStr VARCHAR(50);
DECLARE @DefaultBackupDir NVARCHAR(4000);

SET @DateTimeStr = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ''-'', ''''), '' '', ''_''), '':'', '''');

BEGIN TRY
    -- Intentar crear la carpeta de respaldos de forma segura
    EXEC master.dbo.xp_create_subdir N''C:\SQL_Backups\Llantas\'';
    SET @BackupFile = ''C:\SQL_Backups\Llantas\llantas_full_'' + @DateTimeStr + ''.bak'';
    
    BACKUP DATABASE [llantas]
    TO DISK = @BackupFile
    WITH FORMAT, INIT, NAME = ''llantas - Respaldo Completo Job'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
END TRY
BEGIN CATCH
    -- Fallback automático a la ruta del sistema por defecto si no hay permisos sobre C:\
    EXEC master.dbo.xp_instance_regread
        N''HKEY_LOCAL_MACHINE'',
        N''Software\Microsoft\MSSQLServer\MSSQLServer'',
        N''BackupDirectory'',
        @DefaultBackupDir OUTPUT;
        
    IF @DefaultBackupDir IS NULL
    BEGIN
        SET @BackupFile = ''llantas_full_'' + @DateTimeStr + ''.bak'';
    END
    ELSE
    BEGIN
        IF RIGHT(@DefaultBackupDir, 1) <> ''\'' SET @DefaultBackupDir = @DefaultBackupDir + ''\'';
        SET @BackupFile = CAST(@DefaultBackupDir AS VARCHAR(400)) + ''llantas_full_'' + @DateTimeStr + ''.bak'';
    END
    
    BACKUP DATABASE [llantas]
    TO DISK = @BackupFile
    WITH FORMAT, INIT, NAME = ''llantas - Respaldo Completo Job (Fallback)'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
END CATCH
', 

    @os_run_priority = 0, 
    @subsystem = N'TSQL';

EXEC msdb.dbo.sp_add_jobschedule 
    @job_id = @JobId, 
    @name = N'Horario_Semanal_Domingos_00_00', 
    @enabled = 1, 
    @freq_type = 8,                 -- Semanal
    @freq_interval = 1,             -- Domingo (1)
    @freq_recurrence_factor = 1, 
    @active_start_date = 20260518, 
    @active_end_date = 99991231, 
    @active_start_time = 000000;    -- 00:00:00

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId, @server_name = N'(local)';
GO


-- =============================================================================
-- 3. CREACIÓN DEL JOB: Job_Llantas_Respaldo_Log_Frecuente
-- =============================================================================
DECLARE @JobId BINARY(16);

EXEC msdb.dbo.sp_add_job 
    @job_name = N'Job_Llantas_Respaldo_Log_Frecuente', 
    @enabled = 1, 
    @description = N'Respaldo de LOG cada 2 horas de lunes a sábado.', 
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep 
    @job_id = @JobId, 
    @step_name = N'Generar Respaldo Log', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2, 
    @database_name = N'master', 
    @command = N'
DECLARE @BackupFile VARCHAR(500);
DECLARE @DateTimeStr VARCHAR(50);
DECLARE @DefaultBackupDir NVARCHAR(4000);

SET @DateTimeStr = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), ''-'', ''''), '' '', ''_''), '':'', '''');

BEGIN TRY
    -- Intentar crear la carpeta de respaldos de forma segura
    EXEC master.dbo.xp_create_subdir N''C:\SQL_Backups\Llantas\'';
    SET @BackupFile = ''C:\SQL_Backups\Llantas\llantas_log_'' + @DateTimeStr + ''.trn'';
    
    BACKUP LOG [llantas]
    TO DISK = @BackupFile
    WITH FORMAT, INIT, NAME = ''llantas - Respaldo de Log Job'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
END TRY
BEGIN CATCH
    -- Fallback automático a la ruta del sistema por defecto si no hay permisos sobre C:\
    EXEC master.dbo.xp_instance_regread
        N''HKEY_LOCAL_MACHINE'',
        N''Software\Microsoft\MSSQLServer\MSSQLServer'',
        N''BackupDirectory'',
        @DefaultBackupDir OUTPUT;
        
    IF @DefaultBackupDir IS NULL
    BEGIN
        SET @BackupFile = ''llantas_log_'' + @DateTimeStr + ''.trn'';
    END
    ELSE
    BEGIN
        IF RIGHT(@DefaultBackupDir, 1) <> ''\'' SET @DefaultBackupDir = @DefaultBackupDir + ''\'';
        SET @BackupFile = CAST(@DefaultBackupDir AS VARCHAR(400)) + ''llantas_log_'' + @DateTimeStr + ''.trn'';
    END
    
    BACKUP LOG [llantas]
    TO DISK = @BackupFile
    WITH FORMAT, INIT, NAME = ''llantas - Respaldo de Log Job (Fallback)'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
END CATCH
', 

    @os_run_priority = 0, 
    @subsystem = N'TSQL';

EXEC msdb.dbo.sp_add_jobschedule 
    @job_id = @JobId, 
    @name = N'Horario_Log_Cada_2h_Lunes_Sabado', 
    @enabled = 1, 
    @freq_type = 8,                 -- Semanal
    @freq_interval = 126,           -- Lunes (2) + Martes (4) + Miércoles (8) + Jueves (16) + Viernes (32) + Sábado (64) = 126
    @freq_recurrence_factor = 1, 
    @freq_subday_type = 8,          -- Horas
    @freq_subday_interval = 2,      -- Cada 2 horas
    @active_start_date = 20260518, 
    @active_end_date = 99991231, 
    @active_start_time = 000000;

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId, @server_name = N'(local)';
GO


-- =============================================================================
-- 4. CREACIÓN DEL JOB: Job_Llantas_Mantenimiento_Semanal (Simplificado)
-- =============================================================================
DECLARE @JobId BINARY(16);

EXEC msdb.dbo.sp_add_job 
    @job_name = N'Job_Llantas_Mantenimiento_Semanal', 
    @enabled = 1, 
    @description = N'Mantenimiento semanal simplificado de índices y estadísticas.', 
    @owner_login_name = N'sa',
    @job_id = @JobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep 
    @job_id = @JobId, 
    @step_name = N'Ejecutar Reconstruccion de Indices', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2, 
    @database_name = N'llantas', 
    @command = N'
SET NOCOUNT ON;

PRINT ''Reconstruyendo índices de tablas transaccionales...''
ALTER INDEX ALL ON [dbo].[tblInvoiceMaster] REBUILD;
ALTER INDEX ALL ON [dbo].[tblInvoiceDetail] REBUILD;
ALTER INDEX ALL ON [dbo].[tblProductInventory] REBUILD;
ALTER INDEX ALL ON [dbo].[tblInventoryKardex] REBUILD;
ALTER INDEX ALL ON [dbo].[tblCustomer] REBUILD;
ALTER INDEX ALL ON [dbo].[tblProductCatalog] REBUILD;
ALTER INDEX ALL ON [dbo].[tblVendor] REBUILD;
ALTER INDEX ALL ON [dbo].[tblReferralMaster] REBUILD;
ALTER INDEX ALL ON [dbo].[tblReferralDetail] REBUILD;

PRINT ''Actualizando estadísticas...''
EXEC sp_updatestats;
', 
    @os_run_priority = 0, 
    @subsystem = N'TSQL';

EXEC msdb.dbo.sp_add_jobschedule 
    @job_id = @JobId, 
    @name = N'Horario_Semanal_Mantenimiento_Domingos_02_00', 
    @enabled = 1, 
    @freq_type = 8,                 -- Semanal
    @freq_interval = 1,             -- Domingo (1)
    @freq_recurrence_factor = 1, 
    @active_start_date = 20260518, 
    @active_end_date = 99991231, 
    @active_start_time = 020000;    -- 02:00:00

EXEC msdb.dbo.sp_add_jobserver @job_id = @JobId, @server_name = N'(local)';
GO
