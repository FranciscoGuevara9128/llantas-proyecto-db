/*
================================================================================
SCRIPT: 01_mantenimiento_preventivo.sql
MODULO: Optimización y Mantenimiento (Simplificado)
================================================================================
*/

USE [llantas];
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'INICIANDO MANTENIMIENTO PREVENTIVO DE ÍNDICES (MÉTODO SIMPLE)...';
PRINT '======================================================================';

-- Reconstruir todos los índices de las tablas principales directamente
PRINT 'Reconstruyendo índices de tablas transaccionales y maestros...';

ALTER INDEX ALL ON [dbo].[tblInvoiceMaster] REBUILD;
ALTER INDEX ALL ON [dbo].[tblInvoiceDetail] REBUILD;
ALTER INDEX ALL ON [dbo].[tblProductInventory] REBUILD;
ALTER INDEX ALL ON [dbo].[tblInventoryKardex] REBUILD;
ALTER INDEX ALL ON [dbo].[tblCustomer] REBUILD;
ALTER INDEX ALL ON [dbo].[tblProductCatalog] REBUILD;
ALTER INDEX ALL ON [dbo].[tblVendor] REBUILD;
ALTER INDEX ALL ON [dbo].[tblReferralMaster] REBUILD;
ALTER INDEX ALL ON [dbo].[tblReferralDetail] REBUILD;

PRINT '✔ Reconstrucción de índices completada exitosamente.';
GO

-- Actualización rápida de estadísticas para optimizar los planes de ejecución
PRINT 'Actualizando estadísticas de la base de datos...';
EXEC sp_updatestats;
PRINT '✔ Estadísticas de la base de datos actualizadas.';
GO

SET NOCOUNT OFF;
GO
