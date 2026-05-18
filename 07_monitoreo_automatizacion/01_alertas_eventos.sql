/*
================================================================================
SCRIPT: 01_alertas_eventos.sql
MODULO: Monitoreo y Alertas (Simplificado y Portable)
================================================================================
*/

USE [master];
GO

IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'Error_Session_Llantas')
BEGIN
    ALTER EVENT SESSION [Error_Session_Llantas] ON SERVER STATE = STOP;
    DROP EVENT SESSION [Error_Session_Llantas] ON SERVER;
END
GO

-- Crear la sesión de Extended Events (XEvents) de forma portable
CREATE EVENT SESSION [Error_Session_Llantas] ON SERVER 
ADD EVENT sqlserver.error_reported
(
    ACTION
    (
        sqlserver.client_app_name,   
        sqlserver.client_hostname,   
        sqlserver.database_name,     
        sqlserver.session_id,        
        sqlserver.sql_text,          
        sqlserver.username           
    )
    WHERE ([severity]>=(17)) 
)
ADD TARGET package0.event_file
(
    -- Usar nombre de archivo sin ruta absoluta para que SQL Server lo guarde en su carpeta LOG por defecto
    SET filename = N'Error_Session_Llantas.xel',
    max_file_size = (10),      
    max_rollover_files = (3)   
),
ADD TARGET package0.ring_buffer
(
    SET max_memory = (2048)   
)
WITH 
(
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 10 SECONDS, 
    MAX_EVENT_SIZE = 0 KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = ON 
);
GO

-- Iniciar la sesión de eventos
ALTER EVENT SESSION [Error_Session_Llantas] ON SERVER STATE = START;
GO