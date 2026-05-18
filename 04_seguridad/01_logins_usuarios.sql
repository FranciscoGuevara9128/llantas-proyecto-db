/*
================================================================================
SCRIPT: 01_logins_usuarios.sql
MODULO: Seguridad y Gobierno de Datos
================================================================================
*/

-- -----------------------------------------------------------------------------
-- 1. CONFIGURACIÓN E INICIALIZACIÓN
-- -----------------------------------------------------------------------------
USE [master];
GO

-- -----------------------------------------------------------------------------
-- 2. CREACIÓN DE LOGINS (Servidor)
-- -----------------------------------------------------------------------------

-- Login para el Administrador Junior (DML/DDL y Soporte Técnico)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_admin_jr')
BEGIN
    -- Se activa CHECK_POLICY para obligar al cumplimiento de políticas de Windows sobre contraseñas
    -- Se desactiva CHECK_EXPIRATION para entornos de desarrollo/evaluación académica
    CREATE LOGIN [login_admin_jr] 
    WITH PASSWORD = N'AdmJr_Llantas2026!', 
         DEFAULT_DATABASE = [llantas], 
         CHECK_EXPIRATION = OFF, 
         CHECK_POLICY = ON;
END
GO

-- Login para el Auditor Interno/Externo (Solo Lectura y Auditoría)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'login_auditor')
BEGIN
    CREATE LOGIN [login_auditor] 
    WITH PASSWORD = N'Audit_Llantas2026!', 
         DEFAULT_DATABASE = [llantas], 
         CHECK_EXPIRATION = OFF, 
         CHECK_POLICY = ON;
END
GO

-- -----------------------------------------------------------------------------
-- 3. CREACIÓN DE USUARIOS MAREADOS A LA BASE DE DATOS [llantas]
-- -----------------------------------------------------------------------------
USE [llantas];
GO

-- Usuario para el Administrador Junior
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_admin_jr')
BEGIN
    CREATE USER [usr_admin_jr] FOR LOGIN [login_admin_jr];
END
GO

-- Usuario para el Auditor
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_auditor')
BEGIN
    CREATE USER [usr_auditor] FOR LOGIN [login_auditor];
END
GO