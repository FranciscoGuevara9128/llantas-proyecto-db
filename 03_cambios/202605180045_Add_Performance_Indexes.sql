/*
================================================================================
SCRIPT: 202605180045_Add_Performance_Indexes.sql
MODULO: Optimización y Rendimiento (Simplificado)
================================================================================
*/

USE [llantas];
GO

PRINT '======================================================================';
PRINT 'CREACIÓN DE ÍNDICES DE RENDIMIENTO (ESTÁNDAR INGLÉS/PASCALCASE)...';
PRINT '======================================================================';

-- -----------------------------------------------------------------------------
-- 1. ÍNDICE CUBRIENTE PARA RANGO DE FECHAS EN FACTURACIÓN (tblInvoiceMaster)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_tblInvoiceMaster_InvoiceDate' AND object_id = OBJECT_ID(N'[dbo].[tblInvoiceMaster]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblInvoiceMaster_InvoiceDate]
    ON [dbo].[tblInvoiceMaster] ([InvoiceDate])
    INCLUDE ([IDCustomer], [TotalAmount], [IDStatus]);
    PRINT '✔ Index [IX_tblInvoiceMaster_InvoiceDate] creado exitosamente.';
END
GO

-- -----------------------------------------------------------------------------
-- 2. ÍNDICE CUBRIENTE PARA HISTORIAL DE KARDEX E INVENTARIOS (tblInventoryKardex)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_tblInventoryKardex_MovementDate' AND object_id = OBJECT_ID(N'[dbo].[tblInventoryKardex]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblInventoryKardex_MovementDate]
    ON [dbo].[tblInventoryKardex] ([MovementDate])
    INCLUDE ([IDProduct], [IDTransaction], [Quantity], [UnitCost]);
    PRINT '✔ Index [IX_tblInventoryKardex_MovementDate] creado exitosamente.';
END
GO

-- -----------------------------------------------------------------------------
-- 3. ÍNDICE PARA BÚSQUEDA RÁPIDA DE CLIENTES POR RUC / CÉDULA (tblCustomer)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_tblCustomer_RUC_Cedula' AND object_id = OBJECT_ID(N'[dbo].[tblCustomer]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tblCustomer_RUC_Cedula]
    ON [dbo].[tblCustomer] ([RUC_Cedula_Cliente])
    INCLUDE ([FullName]);
    PRINT '✔ Index [IX_tblCustomer_RUC_Cedula] creado exitosamente.';
END
GO

PRINT '======================================================================';
PRINT 'ÍNDICES DE RENDIMIENTO CREADOS CORRECTAMENTE';
PRINT '======================================================================';
GO
