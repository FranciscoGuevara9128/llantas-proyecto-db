/*
================================================================================
SCRIPT:  04_consultas_xevents.sql
MÓDULO:  Monitoreo — Análisis de Extended Events
================================================================================
DESCRIPCIÓN:
  Herramientas de análisis para la sesión de Extended Events [Error_Session_Llantas].
  Permite demostrar en tiempo real que el monitoreo está activo y capturando eventos.

SECCIONES:
  0. Estado de la sesión de XEvents
  1. Lectura del Ring Buffer (eventos en memoria RAM)
  2. Generación de error de prueba (para demostrar captura en exposición)
  3. Lectura del Event File (.xel) en disco
  4. Estadísticas resumidas de eventos capturados
================================================================================
*/

USE [master];
GO

-- =============================================================================
-- SECCIÓN 0: VERIFICAR ESTADO DE LA SESIÓN
--   Confirma que Error_Session_Llantas está activa y muestra sus targets.
-- =============================================================================
PRINT '=== SECCION 0: Estado de la sesion de Extended Events ===';

SELECT
    s.name                          AS SessionName,
    s.buffer_policy_desc            AS BufferPolicy,
    s.dropped_event_count           AS DroppedEvents,
    s.dropped_buffer_count          AS DroppedBuffers,
    st.target_name                  AS TargetType,
    st.execution_count              AS EventsWrittenToTarget
FROM sys.dm_xe_sessions              AS s
INNER JOIN sys.dm_xe_session_targets AS st
    ON st.event_session_address = s.address
WHERE s.name = N'Error_Session_Llantas'
ORDER BY st.target_name;
GO

-- =============================================================================
-- SECCIÓN 1: LECTURA DEL RING BUFFER (eventos capturados en memoria)
--   NOTA: Requiere QUOTED_IDENTIFIER ON para los métodos XML (.value, .nodes)
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== SECCION 1: Eventos capturados en Ring Buffer ===';

SELECT
    xdr.value('@timestamp',                                      'DATETIME2')     AS EventTime,
    xdr.value('(data[@name="severity"]/value)[1]',               'INT')           AS Severity,
    xdr.value('(data[@name="error"]/value)[1]',                  'INT')           AS ErrorNumber,
    xdr.value('(data[@name="message"]/value)[1]',                'NVARCHAR(MAX)') AS ErrorMessage,
    xdr.value('(action[@name="username"]/value)[1]',             'NVARCHAR(256)') AS UserName,
    xdr.value('(action[@name="database_name"]/value)[1]',        'NVARCHAR(256)') AS DatabaseName,
    xdr.value('(action[@name="client_hostname"]/value)[1]',      'NVARCHAR(256)') AS ClientHostname,
    xdr.value('(action[@name="client_app_name"]/value)[1]',      'NVARCHAR(256)') AS ClientApp,
    xdr.value('(action[@name="session_id"]/value)[1]',           'INT')           AS SessionID,
    xdr.value('(action[@name="sql_text"]/value)[1]',             'NVARCHAR(MAX)') AS SQLText
FROM (
    SELECT CAST(st.target_data AS XML) AS TargetXML
    FROM sys.dm_xe_sessions              AS s
    INNER JOIN sys.dm_xe_session_targets AS st
        ON st.event_session_address = s.address
    WHERE s.name        = N'Error_Session_Llantas'
      AND st.target_name = N'ring_buffer'
) AS RB
CROSS APPLY TargetXML.nodes('RingBufferTarget/event') AS XEventData(xdr)
ORDER BY EventTime DESC;
GO

-- =============================================================================
-- SECCIÓN 2: GENERAR ERROR DE PRUEBA (severity >= 17)
--   Ejecutar este bloque durante la exposición para demostrar que la sesión
--   de XEvents captura el evento. Luego re-ejecutar la Sección 1.
-- =============================================================================
PRINT '=== SECCION 2: Generando error de prueba (severity 17) ===';

BEGIN TRY
    RAISERROR(
        N'[PRUEBA XEVENTS] Error simulado para demostrar el monitoreo activo de Error_Session_Llantas.',
        17,
        1
    );
END TRY
BEGIN CATCH
    PRINT '✔ Error de prueba generado. Re-ejecutar Seccion 1 para verlo en el Ring Buffer.';
END CATCH;
GO

-- =============================================================================
-- SECCIÓN 3: LECTURA DEL EVENT FILE (.xel) EN DISCO
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== SECCION 3: Eventos capturados en Event File (.xel) ===';

DECLARE @LogDir  NVARCHAR(500);
DECLARE @XelPath NVARCHAR(500);

-- Derivar la ruta del directorio LOG desde la ruta del ERRORLOG
SET @LogDir = CAST(SERVERPROPERTY('ErrorLogFileName') AS NVARCHAR(500));
SET @LogDir = LEFT(@LogDir, LEN(@LogDir) - CHARINDEX('\', REVERSE(@LogDir)));
SET @XelPath = @LogDir + N'\Error_Session_Llantas*.xel';

PRINT 'Leyendo archivo: ' + @XelPath;

SELECT
    xdr.value('@timestamp',                                      'DATETIME2')     AS EventTime,
    xdr.value('(data[@name="severity"]/value)[1]',               'INT')           AS Severity,
    xdr.value('(data[@name="error"]/value)[1]',                  'INT')           AS ErrorNumber,
    xdr.value('(data[@name="message"]/value)[1]',                'NVARCHAR(MAX)') AS ErrorMessage,
    xdr.value('(action[@name="username"]/value)[1]',             'NVARCHAR(256)') AS UserName,
    xdr.value('(action[@name="database_name"]/value)[1]',        'NVARCHAR(256)') AS DatabaseName,
    xdr.value('(action[@name="client_hostname"]/value)[1]',      'NVARCHAR(256)') AS ClientHostname,
    xdr.value('(action[@name="session_id"]/value)[1]',           'INT')           AS SessionID,
    xdr.value('(action[@name="sql_text"]/value)[1]',             'NVARCHAR(MAX)') AS SQLText
FROM (
    SELECT CAST(event_data AS XML) AS EventXML
    FROM sys.fn_xe_file_target_read_file(@XelPath, NULL, NULL, NULL)
) AS EF
CROSS APPLY EventXML.nodes('event') AS XEventData(xdr)
ORDER BY EventTime DESC;
GO

-- =============================================================================
-- SECCIÓN 4: ESTADÍSTICAS RESUMIDAS POR SEVERIDAD Y USUARIO
--   FIX: Los métodos XML no pueden usarse en GROUP BY directamente.
--        Se extrae primero en un CTE, luego se agrupa por las columnas escalares.
-- =============================================================================
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== SECCION 4: Resumen de eventos por severidad y usuario ===';

WITH EventData AS (
    SELECT
        xdr.value('(data[@name="severity"]/value)[1]',        'INT')           AS Severity,
        xdr.value('(action[@name="username"]/value)[1]',      'NVARCHAR(256)') AS UserName,
        xdr.value('(action[@name="database_name"]/value)[1]', 'NVARCHAR(256)') AS DatabaseName
    FROM (
        SELECT CAST(st.target_data AS XML) AS TargetXML
        FROM sys.dm_xe_sessions              AS s
        INNER JOIN sys.dm_xe_session_targets AS st
            ON st.event_session_address = s.address
        WHERE s.name        = N'Error_Session_Llantas'
          AND st.target_name = N'ring_buffer'
    ) AS RB
    CROSS APPLY TargetXML.nodes('RingBufferTarget/event') AS XEventData(xdr)
)
SELECT
    Severity,
    UserName,
    DatabaseName,
    COUNT(*) AS TotalEvents
FROM EventData
GROUP BY
    Severity,
    UserName,
    DatabaseName
ORDER BY TotalEvents DESC;
GO

PRINT '✔ Script de analisis de Extended Events completado.';
GO
