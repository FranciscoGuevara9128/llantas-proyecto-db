/*
================================================================================
SCRIPT:  01_vistas.sql
MÓDULO:  Objetos Programables — Vistas (Views)
PREFIJO: vw_
================================================================================
DESCRIPCIÓN:
  Define cuatro vistas reutilizables que consolidan las consultas más frecuentes
  del negocio, ocultando la complejidad de los JOIN y estandarizando los datos
  presentados a aplicaciones y usuarios con acceso de lectura.

VISTAS INCLUIDAS:
  1. vw_InvoiceComplete        — Facturación completa (cabecera + detalle)
  2. vw_InventoryStatus        — Estado del inventario con alertas de stock
  3. vw_SalesSummaryByProduct  — Resumen de ventas agrupado por producto
  4. vw_VendorDirectory        — Directorio de proveedores con representantes
================================================================================
*/

USE [llantas];
GO

-- =============================================================================
-- 1. vw_InvoiceComplete
--    Une Factura Maestro + Detalle + Cliente + Producto + Marca + Categoría
--    Uso: consultas de facturación, reportes de ventas, auditoría comercial.
-- =============================================================================
IF OBJECT_ID(N'dbo.vw_InvoiceComplete', N'V') IS NOT NULL
    DROP VIEW dbo.vw_InvoiceComplete;
GO

CREATE VIEW dbo.vw_InvoiceComplete
AS
SELECT
    -- Datos de la factura
    im.IDInvoice,
    im.InvoiceDate,
    im.TotalAmount          AS InvoiceTotalAmount,
    s_inv.StatusName        AS InvoiceStatus,

    -- Datos del cliente
    c.IDCustomer,
    c.FullName              AS CustomerName,
    c.RUC_Cedula_Cliente    AS CustomerRUC,
    c.CustomerPhone,
    c.CustomerEmail,

    -- Datos del producto en la línea de factura
    id.IDProduct,
    pc.ProductName,
    b.BrandName,
    cat.CategoryName,
    um.UnitName,

    -- Cantidades y precios de la línea
    id.Quantity,
    id.UnitPrice,
    id.Subtotal

FROM dbo.tblInvoiceMaster  AS im
INNER JOIN dbo.tblCustomer      AS c     ON c.IDCustomer   = im.IDCustomer
INNER JOIN dbo.tblInvoiceDetail AS id    ON id.IDInvoice   = im.IDInvoice
INNER JOIN dbo.tblProductCatalog AS pc   ON pc.IDProduct   = id.IDProduct
INNER JOIN dbo.tblBrand          AS b    ON b.IDBrand      = pc.IDBrand
INNER JOIN dbo.tblProductCategory AS cat ON cat.IDCategory = pc.IDCategory
INNER JOIN dbo.tblUnitOfMeasure  AS um   ON um.IDUnitOfMeasure = pc.IDUnitOfMeasure
INNER JOIN dbo.tblStatus         AS s_inv ON s_inv.IDStatus = im.IDStatus;
GO

-- =============================================================================
-- 2. vw_InventoryStatus
--    Estado actual del inventario con semáforo de stock (Crítico/Bajo/Normal/Excedente).
--    Uso: alertas operativas, compras, planificación de reposición.
-- =============================================================================
IF OBJECT_ID(N'dbo.vw_InventoryStatus', N'V') IS NOT NULL
    DROP VIEW dbo.vw_InventoryStatus;
GO

CREATE VIEW dbo.vw_InventoryStatus
AS
SELECT
    -- Identificación del producto
    pc.IDProduct,
    pc.ProductName,
    b.BrandName,
    cat.CategoryName,
    um.UnitName,

    -- Niveles de stock
    pi.CurrentStock,
    pc.MinStock,
    pc.MaxStock,
    pi.AverageCost,

    -- Semáforo calculado
    CASE
        WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock <= pc.MinStock       THEN N'Crítico'
        WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock <= pc.MinStock * 1.5 THEN N'Bajo'
        WHEN pc.MaxStock IS NOT NULL AND pi.CurrentStock >= pc.MaxStock       THEN N'Excedente'
        ELSE N'Normal'
    END AS StockAlert,

    -- Estado del producto en el catálogo
    s.StatusName AS ProductStatus

FROM dbo.tblProductInventory  AS pi
INNER JOIN dbo.tblProductCatalog  AS pc  ON pc.IDProduct       = pi.IDProduct
INNER JOIN dbo.tblBrand           AS b   ON b.IDBrand           = pc.IDBrand
INNER JOIN dbo.tblProductCategory AS cat ON cat.IDCategory      = pc.IDCategory
INNER JOIN dbo.tblUnitOfMeasure   AS um  ON um.IDUnitOfMeasure  = pc.IDUnitOfMeasure
INNER JOIN dbo.tblStatus          AS s   ON s.IDStatus           = pc.IDStatus;
GO

-- =============================================================================
-- 3. vw_SalesSummaryByProduct
--    Agrega las ventas por producto: unidades vendidas, ingresos y promedio de precio.
--    Uso: análisis de rentabilidad, ranking de productos, reportes gerenciales.
-- =============================================================================
IF OBJECT_ID(N'dbo.vw_SalesSummaryByProduct', N'V') IS NOT NULL
    DROP VIEW dbo.vw_SalesSummaryByProduct;
GO

CREATE VIEW dbo.vw_SalesSummaryByProduct
AS
SELECT
    pc.IDProduct,
    pc.ProductName,
    b.BrandName,
    cat.CategoryName,

    -- Métricas de ventas
    SUM(id.Quantity)            AS TotalUnitsSold,
    SUM(id.Subtotal)            AS TotalRevenue,
    AVG(id.UnitPrice)           AS AverageUnitPrice,
    MIN(id.UnitPrice)           AS MinUnitPrice,
    MAX(id.UnitPrice)           AS MaxUnitPrice,
    COUNT(DISTINCT im.IDInvoice) AS NumberOfInvoices

FROM dbo.tblInvoiceDetail  AS id
INNER JOIN dbo.tblInvoiceMaster   AS im  ON im.IDInvoice  = id.IDInvoice
INNER JOIN dbo.tblProductCatalog  AS pc  ON pc.IDProduct  = id.IDProduct
INNER JOIN dbo.tblBrand           AS b   ON b.IDBrand      = pc.IDBrand
INNER JOIN dbo.tblProductCategory AS cat ON cat.IDCategory = pc.IDCategory

GROUP BY
    pc.IDProduct,
    pc.ProductName,
    b.BrandName,
    cat.CategoryName;
GO

-- =============================================================================
-- 4. vw_VendorDirectory
--    Directorio completo de proveedores con sus representantes y contactos.
--    Uso: gestión de compras, comunicación con proveedores, auditoría de remisiones.
-- =============================================================================
IF OBJECT_ID(N'dbo.vw_VendorDirectory', N'V') IS NOT NULL
    DROP VIEW dbo.vw_VendorDirectory;
GO

CREATE VIEW dbo.vw_VendorDirectory
AS
SELECT
    -- Datos del proveedor
    v.IDVendor,
    v.VendorName,
    v.VendorRUC,
    v.VendorAddress,
    sv.StatusName           AS VendorStatus,

    -- Datos del representante (puede ser NULL si no tiene representante asignado)
    vr.IDVendorRepresentative,
    vr.FirstName + N' ' + vr.LastName  AS RepresentativeName,

    -- Datos de contacto del representante
    vc.ContactType,
    vc.ContactValue

FROM dbo.tblVendor              AS v
INNER JOIN dbo.tblStatus              AS sv ON sv.IDStatus               = v.IDStatus
LEFT  JOIN dbo.tblVendorRepresentative AS vr ON vr.IDVendor               = v.IDVendor
LEFT  JOIN dbo.tblVendorContact        AS vc ON vc.IDVendorRepresentative  = vr.IDVendorRepresentative;
GO

-- =============================================================================
-- PERMISOS: Otorgar acceso a las vistas a los roles existentes
-- =============================================================================
GRANT SELECT ON dbo.vw_InvoiceComplete       TO [Rol_Facturacion];
GRANT SELECT ON dbo.vw_InventoryStatus       TO [Rol_Facturacion];
GRANT SELECT ON dbo.vw_SalesSummaryByProduct TO [Rol_Facturacion];
GRANT SELECT ON dbo.vw_VendorDirectory       TO [Rol_Facturacion];

GRANT SELECT ON dbo.vw_InvoiceComplete       TO [Rol_Auditor];
GRANT SELECT ON dbo.vw_InventoryStatus       TO [Rol_Auditor];
GRANT SELECT ON dbo.vw_SalesSummaryByProduct TO [Rol_Auditor];
GRANT SELECT ON dbo.vw_VendorDirectory       TO [Rol_Auditor];
GO

PRINT '✔ Vistas creadas correctamente: vw_InvoiceComplete, vw_InventoryStatus, vw_SalesSummaryByProduct, vw_VendorDirectory';
GO
