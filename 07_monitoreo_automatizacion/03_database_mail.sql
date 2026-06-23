/*
================================================================================
SCRIPT:  03_database_mail.sql
MÓDULO:  Monitoreo y Automatización — Database Mail
================================================================================
DESCRIPCIÓN:
  Configura Database Mail sobre Gmail (SMTP TLS puerto 587) e integra
  notificaciones automáticas en los SQL Server Agent Jobs existentes.

PASOS:
  1. Habilitar Database Mail XPs
  2. Crear cuenta SMTP (Gmail)
  3. Crear perfil de correo
  4. Asociar cuenta al perfil y establecerlo como predeterminado público
  5. Crear operador en SQL Server Agent
  6. Actualizar los Jobs para notificar al operador en caso de error
  7. Enviar correo de prueba
================================================================================
*/

USE [msdb];
GO

-- =============================================================================
-- 1. HABILITAR DATABASE MAIL XPs (a nivel de instancia)
-- =============================================================================
USE [master];
GO

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;
GO

USE [msdb];
GO

-- =============================================================================
-- 2. CREAR CUENTA DE CORREO (Gmail SMTP)
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysmail_account WHERE name = N'Cuenta_Llantas_Gmail'
)
BEGIN
    EXEC msdb.dbo.sysmail_add_account_sp
        @account_name            = N'Cuenta_Llantas_Gmail',
        @description             = N'Cuenta Gmail para notificaciones del sistema llantas.',
        @email_address           = N'franguevaraarauz@gmail.com',
        @display_name            = N'SQL Server Llantas',
        @mailserver_name         = N'smtp.gmail.com',
        @port                    = 587,
        @enable_ssl              = 1,
        @username                = N'franguevaraarauz@gmail.com',
        @password                = N'xllnjxvfmaxkqxze';

    PRINT '✔ Cuenta de correo [Cuenta_Llantas_Gmail] creada.';
END
ELSE
BEGIN
    -- Actualizar la cuenta si ya existe (idempotente)
    EXEC msdb.dbo.sysmail_update_account_sp
        @account_name            = N'Cuenta_Llantas_Gmail',
        @description             = N'Cuenta Gmail para notificaciones del sistema llantas.',
        @email_address           = N'franguevaraarauz@gmail.com',
        @display_name            = N'SQL Server Llantas',
        @mailserver_name         = N'smtp.gmail.com',
        @port                    = 587,
        @enable_ssl              = 1,
        @username                = N'franguevaraarauz@gmail.com',
        @password                = N'xllnjxvfmaxkqxze';

    PRINT '✔ Cuenta de correo [Cuenta_Llantas_Gmail] actualizada.';
END
GO

-- =============================================================================
-- 3. CREAR PERFIL DE CORREO
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysmail_profile WHERE name = N'Perfil_Llantas'
)
BEGIN
    EXEC msdb.dbo.sysmail_add_profile_sp
        @profile_name = N'Perfil_Llantas',
        @description  = N'Perfil de correo principal para alertas y notificaciones del proyecto llantas.';

    PRINT '✔ Perfil [Perfil_Llantas] creado.';
END
ELSE
    PRINT '✔ Perfil [Perfil_Llantas] ya existe, se continúa.';
GO

-- =============================================================================
-- 4A. ASOCIAR CUENTA AL PERFIL (secuencia 1)
-- =============================================================================
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysmail_profileaccount pa
    INNER JOIN msdb.dbo.sysmail_profile  p ON p.profile_id  = pa.profile_id
    INNER JOIN msdb.dbo.sysmail_account  a ON a.account_id  = pa.account_id
    WHERE p.name = N'Perfil_Llantas' AND a.name = N'Cuenta_Llantas_Gmail'
)
BEGIN
    EXEC msdb.dbo.sysmail_add_profileaccount_sp
        @profile_name  = N'Perfil_Llantas',
        @account_name  = N'Cuenta_Llantas_Gmail',
        @sequence_number = 1;

    PRINT '✔ Cuenta asociada al perfil.';
END
ELSE
    PRINT '✔ Cuenta ya estaba asociada al perfil.';
GO

-- =============================================================================
-- 4B. ESTABLECER EL PERFIL COMO PREDETERMINADO PÚBLICO
--     (accesible para todos los usuarios de msdb, incluyendo el SQL Agent)
-- =============================================================================
IF NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysmail_principalprofile pp
    INNER JOIN msdb.dbo.sysmail_profile     p  ON p.profile_id = pp.profile_id
    WHERE p.name = N'Perfil_Llantas' AND pp.principal_sid = 0x00  -- public
)
BEGIN
    EXEC msdb.dbo.sysmail_add_principalprofile_sp
        @profile_name   = N'Perfil_Llantas',
        @principal_name = N'public',
        @is_default     = 1;

    PRINT '✔ Perfil establecido como predeterminado público.';
END
ELSE
    PRINT '✔ Perfil ya estaba configurado como predeterminado público.';
GO

-- =============================================================================
-- 5. CREAR OPERADOR EN SQL SERVER AGENT
--    El operador recibe las notificaciones de los Jobs.
-- =============================================================================
IF NOT EXISTS (
    SELECT 1 FROM msdb.dbo.sysoperators WHERE name = N'Operador_DBA_Llantas'
)
BEGIN
    EXEC msdb.dbo.sp_add_operator
        @name                         = N'Operador_DBA_Llantas',
        @enabled                      = 1,
        @email_address                = N'franguevaraarauz@gmail.com',
        @weekday_pager_start_time     = 090000,
        @weekday_pager_end_time       = 180000,
        @saturday_pager_start_time    = 090000,
        @saturday_pager_end_time      = 140000,
        @pager_days                   = 62;   -- Lunes a Sábado

    PRINT '✔ Operador [Operador_DBA_Llantas] creado.';
END
ELSE
    PRINT '✔ Operador [Operador_DBA_Llantas] ya existe.';
GO

-- =============================================================================
-- 6. CONFIGURAR SQL SERVER AGENT PARA USAR EL PERFIL DE CORREO
-- =============================================================================
EXEC msdb.dbo.sp_set_sqlagent_properties
    @email_save_in_sent_folder = 1;
GO

-- Vincular el perfil de Database Mail al SQL Server Agent
EXEC master.dbo.xp_instance_regwrite
    N'HKEY_LOCAL_MACHINE',
    N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
    N'DatabaseMailProfile',
    N'REG_SZ',
    N'Perfil_Llantas';
GO

-- =============================================================================
-- 7. ACTUALIZAR LOS JOBS EXISTENTES PARA NOTIFICAR AL OPERADOR EN CASO DE ERROR
-- =============================================================================

-- Job: Respaldo Full Semanal — notificar si falla
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Respaldo_Full_Semanal')
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name                  = N'Job_Llantas_Respaldo_Full_Semanal',
        @notify_level_email        = 2,        -- 2 = On failure
        @notify_email_operator_name = N'Operador_DBA_Llantas';

    PRINT '✔ Job [Job_Llantas_Respaldo_Full_Semanal] actualizado con notificación de error.';
END
GO

-- Job: Respaldo Log Frecuente — notificar si falla
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Respaldo_Log_Frecuente')
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name                  = N'Job_Llantas_Respaldo_Log_Frecuente',
        @notify_level_email        = 2,
        @notify_email_operator_name = N'Operador_DBA_Llantas';

    PRINT '✔ Job [Job_Llantas_Respaldo_Log_Frecuente] actualizado con notificación de error.';
END
GO

-- Job: Mantenimiento Semanal — notificar si falla
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job_Llantas_Mantenimiento_Semanal')
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name                  = N'Job_Llantas_Mantenimiento_Semanal',
        @notify_level_email        = 2,
        @notify_email_operator_name = N'Operador_DBA_Llantas';

    PRINT '✔ Job [Job_Llantas_Mantenimiento_Semanal] actualizado con notificación de error.';
END
GO

-- =============================================================================
-- 8. ENVIAR CORREO DE PRUEBA
--    Valida que toda la cadena SMTP → Gmail funciona correctamente.
-- =============================================================================
EXEC msdb.dbo.sp_send_dbmail
    @profile_name  = N'Perfil_Llantas',
    @recipients    = N'franguevaraarauz@gmail.com',
    @subject       = N'[SQL Server Llantas] ✅ Database Mail configurado correctamente',
    @body          =
N'Este correo confirma que Database Mail está operativo en la instancia de SQL Server.

Configuración activa:
  • Perfil : Perfil_Llantas
  • Cuenta : Cuenta_Llantas_Gmail
  • SMTP   : smtp.gmail.com:587 (TLS)
  • Operador: Operador_DBA_Llantas → franguevaraarauz@gmail.com

Jobs configurados para notificar en caso de fallo:
  • Job_Llantas_Respaldo_Full_Semanal
  • Job_Llantas_Respaldo_Log_Frecuente
  • Job_Llantas_Mantenimiento_Semanal

— SQL Server Agent | Proyecto llantas';

PRINT '✔ Correo de prueba enviado a franguevaraarauz@gmail.com';
GO
