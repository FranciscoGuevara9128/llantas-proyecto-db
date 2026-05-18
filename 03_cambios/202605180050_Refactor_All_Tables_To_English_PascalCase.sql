/*
================================================================================
SCRIPT: 202605180050_Refactor_All_Tables_To_English_PascalCase.sql
MODULO: Cambios y Migraciones de Esquema
================================================================================
*/

USE [llantas];
GO

PRINT '======================================================================';
PRINT 'INICIANDO REFACTORIZACIÓN GLOBAL A INGLÉS Y PASCALCASE...';
PRINT '======================================================================';

-- -----------------------------------------------------------------------------
-- PASO 1: ELIMINACIÓN DE TODAS LAS RELACIONES ACTIVAS (FOREIGN KEYS)
-- -----------------------------------------------------------------------------
PRINT 'Eliminando llaves foráneas antiguas para permitir cambios de estructura...';

ALTER TABLE [dbo].[Catalogo_Producto] DROP CONSTRAINT IF EXISTS [FK_Catalogo_Producto_Categoria_Producto];
ALTER TABLE [dbo].[Catalogo_Producto] DROP CONSTRAINT IF EXISTS [FK_Catalogo_Producto_Estado];
ALTER TABLE [dbo].[Catalogo_Producto] DROP CONSTRAINT IF EXISTS [FK_Catalogo_Producto_Marca];
ALTER TABLE [dbo].[Catalogo_Producto] DROP CONSTRAINT IF EXISTS [FK_Catalogo_Producto_Unidad_Medida];

IF OBJECT_ID(N'[dbo].[Cliente]') IS NOT NULL
BEGIN
    ALTER TABLE [dbo].[Cliente] DROP CONSTRAINT IF EXISTS [FK_Cliente_Estado];
END
ALTER TABLE [dbo].[tblCustomer] DROP CONSTRAINT IF EXISTS [FK_Cliente_Estado];

ALTER TABLE [dbo].[ContactoProveedor] DROP CONSTRAINT IF EXISTS [FK_ContactoProveedor_Estado];
ALTER TABLE [dbo].[ContactoProveedor] DROP CONSTRAINT IF EXISTS [FK_ContactoProveedor_RepresentanteProveedor];
ALTER TABLE [dbo].[Factura_Detalle] DROP CONSTRAINT IF EXISTS [FK_Factura_Detalle_Catalogo_Producto];
ALTER TABLE [dbo].[Factura_Detalle] DROP CONSTRAINT IF EXISTS [FK_Factura_Detalle_Factura_Maestro];
ALTER TABLE [dbo].[Factura_Maestro] DROP CONSTRAINT IF EXISTS [FK_Factura_Maestro_Cliente];
ALTER TABLE [dbo].[Factura_Maestro] DROP CONSTRAINT IF EXISTS [FK_Factura_Maestro_Estado];
ALTER TABLE [dbo].[Historial_Precio] DROP CONSTRAINT IF EXISTS [FK_Historial_Precios_Inventario_Producto];
ALTER TABLE [dbo].[Inventario_Producto] DROP CONSTRAINT IF EXISTS [FK_Inventario_Producto_Catalogo_Producto];
ALTER TABLE [dbo].[Kardex_Inventario] DROP CONSTRAINT IF EXISTS [FK_Kardex_Inventario_Estado];
ALTER TABLE [dbo].[Kardex_Inventario] DROP CONSTRAINT IF EXISTS [FK_Kardex_Inventario_Inventario_Producto];
ALTER TABLE [dbo].[Kardex_Inventario] DROP CONSTRAINT IF EXISTS [FK_Kardex_Inventario_Transaccion_Kardex];
ALTER TABLE [dbo].[Proveedor] DROP CONSTRAINT IF EXISTS [FK_Proveedor_Estado];
ALTER TABLE [dbo].[Remision_Detalle] DROP CONSTRAINT IF EXISTS [FK_Remision_Detalle_Catalogo_Producto];
ALTER TABLE [dbo].[Remision_Detalle] DROP CONSTRAINT IF EXISTS [FK_Remision_Detalle_Remision_Maestro];
ALTER TABLE [dbo].[Remision_Maestro] DROP CONSTRAINT IF EXISTS [FK_Remision_Maestro_Estado];
ALTER TABLE [dbo].[Remision_Maestro] DROP CONSTRAINT IF EXISTS [FK_Remision_Maestro_Proveedor];
ALTER TABLE [dbo].[RepresentanteProveedor] DROP CONSTRAINT IF EXISTS [FK_RepresentanteProveedor_Estado];
ALTER TABLE [dbo].[RepresentanteProveedor] DROP CONSTRAINT IF EXISTS [FK_RepresentanteProveedor_Proveedor];

-- Eliminar restricciones de verificación (CHECK CONSTRAINTS) para permitir cambios de nombres de columnas
ALTER TABLE [dbo].[Catalogo_Producto] DROP CONSTRAINT IF EXISTS [CHK_Stock];
ALTER TABLE [dbo].[Factura_Detalle] DROP CONSTRAINT IF EXISTS [CHK_Cantidad_Precio_Subtotal];
ALTER TABLE [dbo].[Inventario_Producto] DROP CONSTRAINT IF EXISTS [CHK_Precio_Stock_Costo];
ALTER TABLE [dbo].[Kardex_Inventario] DROP CONSTRAINT IF EXISTS [CHK_Cantidad_Costo];
ALTER TABLE [dbo].[Remision_Detalle] DROP CONSTRAINT IF EXISTS [CHK_Cantidad_Costo_Total];
ALTER TABLE [dbo].[tblCustomer] DROP CONSTRAINT IF EXISTS [Es_Correo_Valido_Cliente];
GO

-- -----------------------------------------------------------------------------
-- PASO 2: RENOMBRADO DE TABLAS AL ESTÁNDAR TBL[TABLA_INGLES]
-- -----------------------------------------------------------------------------
PRINT 'Renombrando tablas al estándar tbl[EnglishPascalCase]...';

EXEC sp_rename 'dbo.Catalogo_Producto', 'tblProductCatalog';
EXEC sp_rename 'dbo.Categoria_Producto', 'tblProductCategory';
EXEC sp_rename 'dbo.ContactoProveedor', 'tblVendorContact';
EXEC sp_rename 'dbo.Estado', 'tblStatus';
EXEC sp_rename 'dbo.Factura_Detalle', 'tblInvoiceDetail';
EXEC sp_rename 'dbo.Factura_Maestro', 'tblInvoiceMaster';
EXEC sp_rename 'dbo.Historial_Precio', 'tblPriceHistory';
EXEC sp_rename 'dbo.Inventario_Producto', 'tblProductInventory';
EXEC sp_rename 'dbo.Kardex_Inventario', 'tblInventoryKardex';
EXEC sp_rename 'dbo.Marca', 'tblBrand';
EXEC sp_rename 'dbo.Proveedor', 'tblVendor';
EXEC sp_rename 'dbo.Remision_Detalle', 'tblReferralDetail';
EXEC sp_rename 'dbo.Remision_Maestro', 'tblReferralMaster';
EXEC sp_rename 'dbo.RepresentanteProveedor', 'tblVendorRepresentative';
EXEC sp_rename 'dbo.Transaccion_Kardex', 'tblKardexTransaction';
EXEC sp_rename 'dbo.Unidad_Medida', 'tblUnitOfMeasure';
GO

-- -----------------------------------------------------------------------------
-- PASO 3: RENOMBRADO DE LLAVES PRIMARIAS (PK CONSTRAINTS)
-- -----------------------------------------------------------------------------
PRINT 'Normalizando nombres de llaves primarias...';

EXEC sp_rename 'dbo.PK_Catalogo_Producto', 'PK_tblProductCatalog';
EXEC sp_rename 'dbo.PK_Categoria_Producto', 'PK_tblProductCategory';
EXEC sp_rename 'dbo.PK_ContactoProveedor', 'PK_tblVendorContact';
EXEC sp_rename 'dbo.PK_Estado', 'PK_tblStatus';
EXEC sp_rename 'dbo.PK_Factura_Detalle', 'PK_tblInvoiceDetail';
EXEC sp_rename 'dbo.PK_Factura_Maestro', 'PK_tblInvoiceMaster';
EXEC sp_rename 'dbo.PK_Historial_Precios', 'PK_tblPriceHistory';
EXEC sp_rename 'dbo.PK_Inventario_Producto', 'PK_tblProductInventory';
EXEC sp_rename 'dbo.PK_Kardex_Inventario', 'PK_tblInventoryKardex';
EXEC sp_rename 'dbo.PK_Marca', 'PK_tblBrand';
EXEC sp_rename 'dbo.PK_Proveedor', 'PK_tblVendor';
EXEC sp_rename 'dbo.PK_Remision_Detalle', 'PK_tblReferralDetail';
EXEC sp_rename 'dbo.PK_Remision_Maestro', 'PK_tblReferralMaster';
EXEC sp_rename 'dbo.PK_RepresentanteProveedor', 'PK_tblVendorRepresentative';
EXEC sp_rename 'dbo.PK_Transaccion_Kardex', 'PK_tblKardexTransaction';
EXEC sp_rename 'dbo.PK_Unidad_Medida', 'PK_tblUnitOfMeasure';
GO

-- -----------------------------------------------------------------------------
-- PASO 4: RENOMBRADO DE COLUMNAS A PASCALCASE EN INGLÉS
-- -----------------------------------------------------------------------------
PRINT 'Renombrando columnas al estándar PascalCase en Inglés...';

-- A. tblProductCatalog
EXEC sp_rename 'dbo.tblProductCatalog.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.Nombre_Producto', 'ProductName', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.ID_Categoria', 'IDCategory', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.ID_Marca', 'IDBrand', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.ID_Unidad', 'IDUnitOfMeasure', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.Stock_Minimo', 'MinStock', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.Stock_Maximo', 'MaxStock', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCatalog.ID_Estado', 'IDStatus', 'COLUMN';

-- B. tblProductCategory
EXEC sp_rename 'dbo.tblProductCategory.ID_Categoria', 'IDCategory', 'COLUMN';
EXEC sp_rename 'dbo.tblProductCategory.Nombre_Categoria', 'CategoryName', 'COLUMN';

-- C. tblVendorContact
EXEC sp_rename 'dbo.tblVendorContact.ID_ContactoProveedor', 'IDVendorContact', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorContact.ID_RepresentanteProveedor', 'IDVendorRepresentative', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorContact.Tipo_Contacto', 'ContactType', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorContact.Valor_Contacto', 'ContactValue', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorContact.ID_Estado', 'IDStatus', 'COLUMN';

-- D. tblStatus
EXEC sp_rename 'dbo.tblStatus.ID_Estado', 'IDStatus', 'COLUMN';
EXEC sp_rename 'dbo.tblStatus.Estado_Nombre', 'StatusName', 'COLUMN';

-- E. tblInvoiceDetail
EXEC sp_rename 'dbo.tblInvoiceDetail.ID_Factura', 'IDInvoice', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceDetail.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceDetail.Cantidad_Producto', 'Quantity', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceDetail.Precio_Unitario', 'UnitPrice', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceDetail.Subtotal_Factura', 'Subtotal', 'COLUMN';

-- F. tblInvoiceMaster
EXEC sp_rename 'dbo.tblInvoiceMaster.ID_Factura', 'IDInvoice', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceMaster.ID_Cliente', 'IDCustomer', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceMaster.Fecha_Factura', 'InvoiceDate', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceMaster.Total_Factura', 'TotalAmount', 'COLUMN';
EXEC sp_rename 'dbo.tblInvoiceMaster.ID_Estado', 'IDStatus', 'COLUMN';

-- G. tblPriceHistory
EXEC sp_rename 'dbo.tblPriceHistory.ID_Historial', 'IDPriceHistory', 'COLUMN';
EXEC sp_rename 'dbo.tblPriceHistory.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblPriceHistory.Precio', 'Price', 'COLUMN';
EXEC sp_rename 'dbo.tblPriceHistory.Fecha_Inicio', 'StartDate', 'COLUMN';
EXEC sp_rename 'dbo.tblPriceHistory.Fecha_Fin', 'EndDate', 'COLUMN';

-- H. tblProductInventory
EXEC sp_rename 'dbo.tblProductInventory.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblProductInventory.Stock_Actual', 'CurrentStock', 'COLUMN';
EXEC sp_rename 'dbo.tblProductInventory.Costo_Promedio', 'AverageCost', 'COLUMN';

-- I. tblInventoryKardex
EXEC sp_rename 'dbo.tblInventoryKardex.ID_Kardex', 'IDKardex', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.ID_Transaccion', 'IDTransaction', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.Cantidad_Producto', 'Quantity', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.Costo_Unitario', 'UnitCost', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.Fecha_Movimiento', 'MovementDate', 'COLUMN';
EXEC sp_rename 'dbo.tblInventoryKardex.ID_Estado', 'IDStatus', 'COLUMN';

-- J. tblBrand
EXEC sp_rename 'dbo.tblBrand.ID_Marca', 'IDBrand', 'COLUMN';
EXEC sp_rename 'dbo.tblBrand.Nombre_Marca', 'BrandName', 'COLUMN';

-- K. tblVendor
EXEC sp_rename 'dbo.tblVendor.ID_Proveedor', 'IDVendor', 'COLUMN';
EXEC sp_rename 'dbo.tblVendor.Nombre_Proveedor', 'VendorName', 'COLUMN';
EXEC sp_rename 'dbo.tblVendor.Direccion_Proveedor', 'VendorAddress', 'COLUMN';
EXEC sp_rename 'dbo.tblVendor.RUC_Proveedor', 'VendorRUC', 'COLUMN';
EXEC sp_rename 'dbo.tblVendor.ID_Estado', 'IDStatus', 'COLUMN';

-- L. tblReferralDetail
EXEC sp_rename 'dbo.tblReferralDetail.ID_Remision', 'IDReferral', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralDetail.ID_Producto', 'IDProduct', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralDetail.Cantidad_Producto', 'Quantity', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralDetail.Costo_Unitario', 'UnitCost', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralDetail.Costo_Total', 'TotalCost', 'COLUMN';

-- M. tblReferralMaster
EXEC sp_rename 'dbo.tblReferralMaster.ID_Remision', 'IDReferral', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralMaster.ID_Proveedor', 'IDVendor', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralMaster.Fecha_Remision', 'ReferralDate', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralMaster.Total_Remision', 'TotalAmount', 'COLUMN';
EXEC sp_rename 'dbo.tblReferralMaster.ID_Estado', 'IDStatus', 'COLUMN';

-- N. tblVendorRepresentative
EXEC sp_rename 'dbo.tblVendorRepresentative.ID_RepresentanteProveedor', 'IDVendorRepresentative', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorRepresentative.ID_Proveedor', 'IDVendor', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorRepresentative.Nombre', 'FirstName', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorRepresentative.Apellido', 'LastName', 'COLUMN';
EXEC sp_rename 'dbo.tblVendorRepresentative.ID_Estado', 'IDStatus', 'COLUMN';

-- O. tblKardexTransaction
EXEC sp_rename 'dbo.tblKardexTransaction.ID_Transaccion', 'IDTransaction', 'COLUMN';
EXEC sp_rename 'dbo.tblKardexTransaction.Tipo_Transaccion', 'TransactionType', 'COLUMN';

-- P. tblUnitOfMeasure
EXEC sp_rename 'dbo.tblUnitOfMeasure.ID_Unidad', 'IDUnitOfMeasure', 'COLUMN';
EXEC sp_rename 'dbo.tblUnitOfMeasure.Nombre_Unidad', 'UnitName', 'COLUMN';

-- Q. tblCustomer (Renombrar campos restantes de Cliente a inglés PascalCase)
EXEC sp_rename 'dbo.tblCustomer.Direccion_Cliente', 'CustomerAddress', 'COLUMN';
EXEC sp_rename 'dbo.tblCustomer.Telefono_Cliente', 'CustomerPhone', 'COLUMN';
EXEC sp_rename 'dbo.tblCustomer.Correo_Cliente', 'CustomerEmail', 'COLUMN';
EXEC sp_rename 'dbo.tblCustomer.ID_Estado', 'IDStatus', 'COLUMN';
GO

-- -----------------------------------------------------------------------------
-- PASO 5: MIGRACIÓN DE VARCHAR A NVARCHAR (UNICODE MULTI-LENGUAJE)
-- -----------------------------------------------------------------------------
PRINT 'Migrando tipos de datos a NVARCHAR...';

ALTER TABLE dbo.tblProductCatalog ALTER COLUMN ProductName NVARCHAR(100) NOT NULL;
ALTER TABLE dbo.tblProductCategory ALTER COLUMN CategoryName NVARCHAR(100) NOT NULL;
ALTER TABLE dbo.tblVendorContact ALTER COLUMN ContactType NVARCHAR(10) NOT NULL;
ALTER TABLE dbo.tblVendorContact ALTER COLUMN ContactValue NVARCHAR(50) NOT NULL;
ALTER TABLE dbo.tblStatus ALTER COLUMN StatusName NVARCHAR(20) NULL;
ALTER TABLE dbo.tblBrand ALTER COLUMN BrandName NVARCHAR(50) NOT NULL;
ALTER TABLE dbo.tblVendor ALTER COLUMN VendorName NVARCHAR(100) NOT NULL;
ALTER TABLE dbo.tblVendor ALTER COLUMN VendorAddress NVARCHAR(150) NULL;
ALTER TABLE dbo.tblVendor ALTER COLUMN VendorRUC NVARCHAR(50) NOT NULL;
ALTER TABLE dbo.tblVendorRepresentative ALTER COLUMN FirstName NVARCHAR(20) NOT NULL;
ALTER TABLE dbo.tblVendorRepresentative ALTER COLUMN LastName NVARCHAR(20) NOT NULL;

-- NVARCHAR Migraciones para tblCustomer
ALTER TABLE dbo.tblCustomer ALTER COLUMN CustomerAddress NVARCHAR(150) NULL;
ALTER TABLE dbo.tblCustomer ALTER COLUMN CustomerPhone NVARCHAR(15) NOT NULL;
ALTER TABLE dbo.tblCustomer ALTER COLUMN CustomerEmail NVARCHAR(100) NULL;
ALTER TABLE dbo.tblKardexTransaction ALTER COLUMN TransactionType NVARCHAR(50) NOT NULL;
ALTER TABLE dbo.tblUnitOfMeasure ALTER COLUMN UnitName NVARCHAR(50) NOT NULL;
GO

-- -----------------------------------------------------------------------------
-- PASO 6: INYECCIÓN DE LA CAPA DE AUDITORÍA OPERACIONAL EN TODAS LAS TABLAS
-- -----------------------------------------------------------------------------
PRINT 'Inyectando columnas de auditoría en todas las tablas...';

-- Definir procedimiento auxiliar para agregar columnas si no existen
DECLARE @TableName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

DECLARE TableCursor CURSOR FOR
SELECT name FROM sys.tables WHERE name <> 'sysdiagrams' AND name <> 'tblCustomer'; -- tblCustomer ya tiene auditoría

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER TABLE [dbo].[' + @TableName + '] ADD 
        RegistrationDate DATETIME2 DEFAULT GETDATE(),
        RegistrationUser NVARCHAR(50) DEFAULT USER_NAME(),
        ModificationDate DATETIME2 NULL,
        ModificationUser NVARCHAR(50) NULL;';
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM TableCursor INTO @TableName;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;
GO

-- -----------------------------------------------------------------------------
-- PASO 7: CREACIÓN AUTOMÁTICA DE TRIGGERS AFTER UPDATE DE AUDITORÍA
-- -----------------------------------------------------------------------------
PRINT 'Generando Triggers AFTER UPDATE de auditoría para cada tabla...';

-- A. tblProductCatalog
GO
CREATE TRIGGER trg_tblProductCatalog_UpdateAudit ON dbo.tblProductCatalog AFTER UPDATE AS BEGIN
    UPDATE dbo.tblProductCatalog SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblProductCatalog.IDProduct = i.IDProduct;
END;
GO

-- B. tblProductCategory
CREATE TRIGGER trg_tblProductCategory_UpdateAudit ON dbo.tblProductCategory AFTER UPDATE AS BEGIN
    UPDATE dbo.tblProductCategory SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblProductCategory.IDCategory = i.IDCategory;
END;
GO

-- C. tblVendorContact
CREATE TRIGGER trg_tblVendorContact_UpdateAudit ON dbo.tblVendorContact AFTER UPDATE AS BEGIN
    UPDATE dbo.tblVendorContact SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblVendorContact.IDVendorContact = i.IDVendorContact;
END;
GO

-- D. tblStatus
CREATE TRIGGER trg_tblStatus_UpdateAudit ON dbo.tblStatus AFTER UPDATE AS BEGIN
    UPDATE dbo.tblStatus SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblStatus.IDStatus = i.IDStatus;
END;
GO

-- E. tblInvoiceDetail
CREATE TRIGGER trg_tblInvoiceDetail_UpdateAudit ON dbo.tblInvoiceDetail AFTER UPDATE AS BEGIN
    UPDATE dbo.tblInvoiceDetail SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblInvoiceDetail.IDInvoice = i.IDInvoice AND dbo.tblInvoiceDetail.IDProduct = i.IDProduct;
END;
GO

-- F. tblInvoiceMaster
CREATE TRIGGER trg_tblInvoiceMaster_UpdateAudit ON dbo.tblInvoiceMaster AFTER UPDATE AS BEGIN
    UPDATE dbo.tblInvoiceMaster SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblInvoiceMaster.IDInvoice = i.IDInvoice;
END;
GO

-- G. tblPriceHistory
CREATE TRIGGER trg_tblPriceHistory_UpdateAudit ON dbo.tblPriceHistory AFTER UPDATE AS BEGIN
    UPDATE dbo.tblPriceHistory SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblPriceHistory.IDPriceHistory = i.IDPriceHistory;
END;
GO

-- H. tblProductInventory
CREATE TRIGGER trg_tblProductInventory_UpdateAudit ON dbo.tblProductInventory AFTER UPDATE AS BEGIN
    UPDATE dbo.tblProductInventory SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblProductInventory.IDProduct = i.IDProduct;
END;
GO

-- I. tblInventoryKardex
CREATE TRIGGER trg_tblInventoryKardex_UpdateAudit ON dbo.tblInventoryKardex AFTER UPDATE AS BEGIN
    UPDATE dbo.tblInventoryKardex SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblInventoryKardex.IDKardex = i.IDKardex;
END;
GO

-- J. tblBrand
CREATE TRIGGER trg_tblBrand_UpdateAudit ON dbo.tblBrand AFTER UPDATE AS BEGIN
    UPDATE dbo.tblBrand SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblBrand.IDBrand = i.IDBrand;
END;
GO

-- K. tblVendor
CREATE TRIGGER trg_tblVendor_UpdateAudit ON dbo.tblVendor AFTER UPDATE AS BEGIN
    UPDATE dbo.tblVendor SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblVendor.IDVendor = i.IDVendor;
END;
GO

-- L. tblReferralDetail
CREATE TRIGGER trg_tblReferralDetail_UpdateAudit ON dbo.tblReferralDetail AFTER UPDATE AS BEGIN
    UPDATE dbo.tblReferralDetail SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblReferralDetail.IDReferral = i.IDReferral AND dbo.tblReferralDetail.IDProduct = i.IDProduct;
END;
GO

-- M. tblReferralMaster
CREATE TRIGGER trg_tblReferralMaster_UpdateAudit ON dbo.tblReferralMaster AFTER UPDATE AS BEGIN
    UPDATE dbo.tblReferralMaster SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblReferralMaster.IDReferral = i.IDReferral;
END;
GO

-- N. tblVendorRepresentative
CREATE TRIGGER trg_tblVendorRepresentative_UpdateAudit ON dbo.tblVendorRepresentative AFTER UPDATE AS BEGIN
    UPDATE dbo.tblVendorRepresentative SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblVendorRepresentative.IDVendorRepresentative = i.IDVendorRepresentative;
END;
GO

-- O. tblKardexTransaction
CREATE TRIGGER trg_tblKardexTransaction_UpdateAudit ON dbo.tblKardexTransaction AFTER UPDATE AS BEGIN
    UPDATE dbo.tblKardexTransaction SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblKardexTransaction.IDTransaction = i.IDTransaction;
END;
GO

-- P. tblUnitOfMeasure
CREATE TRIGGER trg_tblUnitOfMeasure_UpdateAudit ON dbo.tblUnitOfMeasure AFTER UPDATE AS BEGIN
    UPDATE dbo.tblUnitOfMeasure SET ModificationDate = GETDATE(), ModificationUser = USER_NAME()
    FROM Inserted i WHERE dbo.tblUnitOfMeasure.IDUnitOfMeasure = i.IDUnitOfMeasure;
END;
GO

-- -----------------------------------------------------------------------------
-- PASO 8: RECREACIÓN DE RELACIONES (FOREIGN KEYS) CON NUEVO ESQUEMA
-- -----------------------------------------------------------------------------
PRINT 'Recreando llaves foráneas mapeadas con el nuevo estándar de nombres...';

-- A. tblProductCatalog
ALTER TABLE [dbo].[tblProductCatalog] WITH CHECK ADD CONSTRAINT [FK_tblProductCatalog_tblProductCategory] 
    FOREIGN KEY([IDCategory]) REFERENCES [dbo].[tblProductCategory] ([IDCategory]);

ALTER TABLE [dbo].[tblProductCatalog] WITH CHECK ADD CONSTRAINT [FK_tblProductCatalog_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

ALTER TABLE [dbo].[tblProductCatalog] WITH CHECK ADD CONSTRAINT [FK_tblProductCatalog_tblBrand] 
    FOREIGN KEY([IDBrand]) REFERENCES [dbo].[tblBrand] ([IDBrand]);

ALTER TABLE [dbo].[tblProductCatalog] WITH CHECK ADD CONSTRAINT [FK_tblProductCatalog_tblUnitOfMeasure] 
    FOREIGN KEY([IDUnitOfMeasure]) REFERENCES [dbo].[tblUnitOfMeasure] ([IDUnitOfMeasure]);

-- B. tblCustomer (El renombrado Cliente -> tblCustomer ya ocurrió en la primera migración)
ALTER TABLE [dbo].[tblCustomer] WITH CHECK ADD CONSTRAINT [FK_tblCustomer_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

-- C. tblVendorContact
ALTER TABLE [dbo].[tblVendorContact] WITH CHECK ADD CONSTRAINT [FK_tblVendorContact_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

ALTER TABLE [dbo].[tblVendorContact] WITH CHECK ADD CONSTRAINT [FK_tblVendorContact_tblVendorRepresentative] 
    FOREIGN KEY([IDVendorRepresentative]) REFERENCES [dbo].[tblVendorRepresentative] ([IDVendorRepresentative]);

-- D. tblInvoiceDetail
ALTER TABLE [dbo].[tblInvoiceDetail] WITH CHECK ADD CONSTRAINT [FK_tblInvoiceDetail_tblProductCatalog] 
    FOREIGN KEY([IDProduct]) REFERENCES [dbo].[tblProductCatalog] ([IDProduct]);

ALTER TABLE [dbo].[tblInvoiceDetail] WITH CHECK ADD CONSTRAINT [FK_tblInvoiceDetail_tblInvoiceMaster] 
    FOREIGN KEY([IDInvoice]) REFERENCES [dbo].[tblInvoiceMaster] ([IDInvoice]);

-- E. tblInvoiceMaster
ALTER TABLE [dbo].[tblInvoiceMaster] WITH CHECK ADD CONSTRAINT [FK_tblInvoiceMaster_tblCustomer] 
    FOREIGN KEY([IDCustomer]) REFERENCES [dbo].[tblCustomer] ([IDCustomer]);

ALTER TABLE [dbo].[tblInvoiceMaster] WITH CHECK ADD CONSTRAINT [FK_tblInvoiceMaster_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

-- F. tblPriceHistory
ALTER TABLE [dbo].[tblPriceHistory] WITH CHECK ADD CONSTRAINT [FK_tblPriceHistory_tblProductInventory] 
    FOREIGN KEY([IDProduct]) REFERENCES [dbo].[tblProductInventory] ([IDProduct]);

-- G. tblProductInventory
ALTER TABLE [dbo].[tblProductInventory] WITH CHECK ADD CONSTRAINT [FK_tblProductInventory_tblProductCatalog] 
    FOREIGN KEY([IDProduct]) REFERENCES [dbo].[tblProductCatalog] ([IDProduct]);

-- H. tblInventoryKardex
ALTER TABLE [dbo].[tblInventoryKardex] WITH CHECK ADD CONSTRAINT [FK_tblInventoryKardex_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

ALTER TABLE [dbo].[tblInventoryKardex] WITH CHECK ADD CONSTRAINT [FK_tblInventoryKardex_tblProductInventory] 
    FOREIGN KEY([IDProduct]) REFERENCES [dbo].[tblProductInventory] ([IDProduct]);

ALTER TABLE [dbo].[tblInventoryKardex] WITH CHECK ADD CONSTRAINT [FK_tblInventoryKardex_tblKardexTransaction] 
    FOREIGN KEY([IDTransaction]) REFERENCES [dbo].[tblKardexTransaction] ([IDTransaction]);

-- I. tblVendor
ALTER TABLE [dbo].[tblVendor] WITH CHECK ADD CONSTRAINT [FK_tblVendor_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

-- J. tblReferralDetail
ALTER TABLE [dbo].[tblReferralDetail] WITH CHECK ADD CONSTRAINT [FK_tblReferralDetail_tblProductCatalog] 
    FOREIGN KEY([IDProduct]) REFERENCES [dbo].[tblProductCatalog] ([IDProduct]);

ALTER TABLE [dbo].[tblReferralDetail] WITH CHECK ADD CONSTRAINT [FK_tblReferralDetail_tblReferralMaster] 
    FOREIGN KEY([IDReferral]) REFERENCES [dbo].[tblReferralMaster] ([IDReferral]);

-- K. tblReferralMaster
ALTER TABLE [dbo].[tblReferralMaster] WITH CHECK ADD CONSTRAINT [FK_tblReferralMaster_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

ALTER TABLE [dbo].[tblReferralMaster] WITH CHECK ADD CONSTRAINT [FK_tblReferralMaster_tblVendor] 
    FOREIGN KEY([IDVendor]) REFERENCES [dbo].[tblVendor] ([IDVendor]);

-- L. tblVendorRepresentative
ALTER TABLE [dbo].[tblVendorRepresentative] WITH CHECK ADD CONSTRAINT [FK_tblVendorRepresentative_tblStatus] 
    FOREIGN KEY([IDStatus]) REFERENCES [dbo].[tblStatus] ([IDStatus]);

ALTER TABLE [dbo].[tblVendorRepresentative] WITH CHECK ADD CONSTRAINT [FK_tblVendorRepresentative_tblVendor] 
    FOREIGN KEY([IDVendor]) REFERENCES [dbo].[tblVendor] ([IDVendor]);
GO

-- -----------------------------------------------------------------------------
-- PASO 9: RECREACIÓN DE RESTRICCIONES DE VERIFICACIÓN (CHECK CONSTRAINTS)
-- -----------------------------------------------------------------------------
PRINT 'Recreando check constraints con el nuevo estándar de nombres y columnas...';

ALTER TABLE [dbo].[tblProductCatalog] WITH CHECK ADD CONSTRAINT [CHK_tblProductCatalog_Stock] 
    CHECK (([MinStock]>=(0) AND [MaxStock]>=(0)));

ALTER TABLE [dbo].[tblInvoiceDetail] WITH CHECK ADD CONSTRAINT [CHK_tblInvoiceDetail_Quantity_Price_Subtotal] 
    CHECK (([Quantity]>=(0) AND [UnitPrice]>=(0) AND [Subtotal]>=(0)));

ALTER TABLE [dbo].[tblProductInventory] WITH CHECK ADD CONSTRAINT [CHK_tblProductInventory_Cost_Stock] 
    CHECK (([AverageCost]>=(0) AND [CurrentStock]>=(0)));

ALTER TABLE [dbo].[tblInventoryKardex] WITH CHECK ADD CONSTRAINT [CHK_tblInventoryKardex_Quantity_Cost] 
    CHECK (([Quantity]>=(0) AND [UnitCost]>=(0)));

ALTER TABLE [dbo].[tblReferralDetail] WITH CHECK ADD CONSTRAINT [CHK_tblReferralDetail_Quantity_Cost_Total] 
    CHECK (([Quantity]>=(0) AND [UnitCost]>=(0) AND [TotalCost]>=(0)));

ALTER TABLE [dbo].[tblCustomer] WITH CHECK ADD CONSTRAINT [CHK_tblCustomer_CustomerEmail] 
    CHECK ((CHARINDEX('@', [CustomerEmail]) > (1) AND CHARINDEX('@', [CustomerEmail]) < LEN([CustomerEmail])));
GO

PRINT '======================================================================';
PRINT 'REFACTORIZACIÓN GLOBAL COMPLETADA CON ÉXITO';
PRINT '======================================================================';
GO
