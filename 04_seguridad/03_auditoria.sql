/*
================================================================================
SCRIPT: 03_auditoria.sql
MODULO: Seguridad y Gobierno de Datos
PROYECTO: llantas-Proyecto (Segunda Evaluación)
DESCRIPCION: Implementación de Server Audit y Database Audit Specification.
             Adaptado plenamente para el nuevo esquema en INGLÉS y PASCALCASE.
================================================================================
*/

-- -----------------------------------------------------------------------------
-- 1. CONFIGURACIÓN DEL SERVER AUDIT (A nivel de instancia/servidor)
-- -----------------------------------------------------------------------------
USE [master];
GO

IF NOT EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit_Llantas_Server')
BEGIN
    CREATE SERVER AUDIT [Audit_Llantas_Server]
    TO APPLICATION_LOG
    WITH
    (
        QUEUE_DELAY = 1000,
        ON_FAILURE = CONTINUE
    );
END
GO

IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'Audit_Llantas_Server' AND is_state_enabled = 0)
BEGIN
    ALTER SERVER AUDIT [Audit_Llantas_Server] WITH (STATE = ON);
END
GO

-- -----------------------------------------------------------------------------
-- 2. ESPECIFICACIÓN DE AUDITORÍA DEL SERVIDOR (Server Audit Specification)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.server_audit_specifications WHERE name = 'Audit_Llantas_Server_Spec')
BEGIN
    CREATE SERVER AUDIT SPECIFICATION [Audit_Llantas_Server_Spec]
    FOR SERVER AUDIT [Audit_Llantas_Server]
    ADD (FAILED_LOGIN_GROUP)
    WITH (STATE = ON);
END
GO

-- -----------------------------------------------------------------------------
-- 3. ESPECIFICACIÓN DE AUDITORÍA DE BASE DE DATOS (Database Audit Specification)
-- -----------------------------------------------------------------------------
USE [llantas];
GO

IF NOT EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'Audit_Llantas_Db_Spec')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION [Audit_Llantas_Db_Spec]
    FOR SERVER AUDIT [Audit_Llantas_Server]
    
    -- Monitoreo de transacciones comerciales (DML) en el nuevo esquema
    ADD (INSERT, UPDATE, DELETE ON [dbo].[tblInvoiceMaster] BY [public]),
    ADD (INSERT, UPDATE, DELETE ON [dbo].[tblInvoiceDetail] BY [public]),
    
    -- Monitoreo de existencias de llantas e historial físico de almacén
    ADD (UPDATE, DELETE ON [dbo].[tblProductInventory] BY [public]),
    ADD (INSERT, UPDATE, DELETE ON [dbo].[tblInventoryKardex] BY [public]),
    
    -- Monitoreo de cambios de estructura (DDL) en la base de datos (Ej: CREATE, ALTER, DROP)
    ADD (SCHEMA_OBJECT_CHANGE_GROUP)
    
    WITH (STATE = ON);
END
GO
