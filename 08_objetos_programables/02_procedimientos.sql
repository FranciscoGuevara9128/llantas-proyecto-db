/*
================================================================================
SCRIPT:  02_procedimientos.sql
MÓDULO:  Objetos Programables — Procedimientos Almacenados
PREFIJO: usp_
================================================================================
DESCRIPCIÓN:
  Define cuatro procedimientos almacenados que encapsulan la lógica de negocio
  más frecuente, protegen la integridad de los datos y ofrecen una API
  controlada para las aplicaciones cliente.

PROCEDIMIENTOS INCLUIDOS:
  1. usp_GetCustomerInvoices   — Historial de facturas de un cliente (con filtro por fecha)
  2. usp_GetLowStockProducts   — Productos con stock en nivel Crítico o Bajo
  3. usp_GetProductPriceHistory — Historial de precios de un producto
  4. usp_GetSalesReport        — Reporte de ventas por rango de fecha
================================================================================
*/

USE [llantas];
GO

-- =============================================================================
-- 1. usp_GetCustomerInvoices
--    Devuelve el historial de facturas de un cliente específico.
--    Parámetros opcionales de fecha para filtrar por rango.
--
--    Parámetros:
--      @IDCustomer  INT            — ID del cliente (requerido)
--      @StartDate   DATE = NULL    — Fecha de inicio del filtro (opcional)
--      @EndDate     DATE = NULL    — Fecha de fin del filtro (opcional)
--
--    Ejemplo de uso:
--      EXEC usp_GetCustomerInvoices @IDCustomer = 1;
--      EXEC usp_GetCustomerInvoices @IDCustomer = 1, @StartDate = '2026-01-01', @EndDate = '2026-06-30';
-- =============================================================================
IF OBJECT_ID(N'dbo.usp_GetCustomerInvoices', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetCustomerInvoices;
GO

CREATE PROCEDURE dbo.usp_GetCustomerInvoices
    @IDCustomer  INT,
    @StartDate   DATE = NULL,
    @EndDate     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM dbo.tblCustomer WHERE IDCustomer = @IDCustomer)
    BEGIN
        RAISERROR(N'El cliente con IDCustomer = %d no existe en la base de datos.', 16, 1, @IDCustomer);
        RETURN;
    END

    SELECT
        im.IDInvoice,
        im.InvoiceDate,
        c.FullName          AS CustomerName,
        c.RUC_Cedula_Cliente AS CustomerRUC,
        -- Total de líneas en la factura
        COUNT(id.IDProduct) AS TotalLines,
        -- Suma real desde el detalle (más precisa que el campo calculado)
        SUM(id.Subtotal)    AS TotalFromDetail,
        im.TotalAmount      AS TotalStored,
        s.StatusName        AS InvoiceStatus

    FROM dbo.tblInvoiceMaster  AS im
    INNER JOIN dbo.tblCustomer      AS c  ON c.IDCustomer  = im.IDCustomer
    INNER JOIN dbo.tblInvoiceDetail AS id ON id.IDInvoice  = im.IDInvoice
    INNER JOIN dbo.tblStatus        AS s  ON s.IDStatus    = im.IDStatus

    WHERE im.IDCustomer = @IDCustomer
      AND (@StartDate IS NULL OR im.InvoiceDate >= @StartDate)
      AND (@EndDate   IS NULL OR im.InvoiceDate <= @EndDate)

    GROUP BY
        im.IDInvoice,
        im.InvoiceDate,
        c.FullName,
        c.RUC_Cedula_Cliente,
        im.TotalAmount,
        s.StatusName

    ORDER BY im.InvoiceDate DESC;

    SET NOCOUNT OFF;
END;
GO

-- =============================================================================
-- 2. usp_GetLowStockProducts
--    Devuelve los productos cuyo stock actual está por debajo del mínimo
--    o dentro del margen de alerta (1.5× el mínimo).
--
--    Parámetros:
--      @CriticalOnly  BIT = 0  — Si es 1, retorna solo los productos en nivel Crítico
--                                Si es 0, retorna Críticos y Bajos
--
--    Ejemplo de uso:
--      EXEC usp_GetLowStockProducts;
--      EXEC usp_GetLowStockProducts @CriticalOnly = 1;
-- =============================================================================
IF OBJECT_ID(N'dbo.usp_GetLowStockProducts', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetLowStockProducts;
GO

CREATE PROCEDURE dbo.usp_GetLowStockProducts
    @CriticalOnly  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pc.IDProduct,
        pc.ProductName,
        b.BrandName,
        cat.CategoryName,
        pi.CurrentStock,
        pc.MinStock,
        pc.MaxStock,
        pi.AverageCost,
        -- Unidades faltantes para alcanzar el stock mínimo
        CASE
            WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock < pc.MinStock
            THEN pc.MinStock - pi.CurrentStock
            ELSE 0
        END AS UnitsNeededToMinStock,
        -- Costo estimado de reposición hasta el mínimo
        CASE
            WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock < pc.MinStock
            THEN (pc.MinStock - pi.CurrentStock) * pi.AverageCost
            ELSE 0
        END AS EstimatedReplenishmentCost,
        CASE
            WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock <= pc.MinStock       THEN N'Crítico'
            WHEN pc.MinStock IS NOT NULL AND pi.CurrentStock <= pc.MinStock * 1.5 THEN N'Bajo'
            ELSE N'Normal'
        END AS StockAlert

    FROM dbo.tblProductInventory  AS pi
    INNER JOIN dbo.tblProductCatalog  AS pc  ON pc.IDProduct  = pi.IDProduct
    INNER JOIN dbo.tblBrand           AS b   ON b.IDBrand      = pc.IDBrand
    INNER JOIN dbo.tblProductCategory AS cat ON cat.IDCategory = pc.IDCategory

    WHERE
        pc.MinStock IS NOT NULL
        AND (
            -- Modo Crítico: solo stock <= mínimo
            (@CriticalOnly = 1 AND pi.CurrentStock <= pc.MinStock)
            OR
            -- Modo completo: stock <= 1.5× mínimo
            (@CriticalOnly = 0 AND pi.CurrentStock <= pc.MinStock * 1.5)
        )

    ORDER BY pi.CurrentStock ASC;

    SET NOCOUNT OFF;
END;
GO

-- =============================================================================
-- 3. usp_GetProductPriceHistory
--    Devuelve el historial de precios de un producto con el precio vigente marcado.
--
--    Parámetros:
--      @IDProduct  INT  — ID del producto (requerido)
--
--    Ejemplo de uso:
--      EXEC usp_GetProductPriceHistory @IDProduct = 5;
-- =============================================================================
IF OBJECT_ID(N'dbo.usp_GetProductPriceHistory', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetProductPriceHistory;
GO

CREATE PROCEDURE dbo.usp_GetProductPriceHistory
    @IDProduct  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el producto existe
    IF NOT EXISTS (SELECT 1 FROM dbo.tblProductCatalog WHERE IDProduct = @IDProduct)
    BEGIN
        RAISERROR(N'El producto con IDProduct = %d no existe en el catálogo.', 16, 1, @IDProduct);
        RETURN;
    END

    SELECT
        ph.IDPriceHistory,
        pc.IDProduct,
        pc.ProductName,
        b.BrandName,
        ph.Price,
        ph.StartDate,
        ph.EndDate,
        -- Identificar si es el precio actualmente vigente
        CASE
            WHEN ph.EndDate IS NULL THEN N'Vigente'
            ELSE N'Histórico'
        END AS PriceStatus,
        -- Días de vigencia del precio
        DATEDIFF(DAY, ph.StartDate, ISNULL(ph.EndDate, CAST(GETDATE() AS DATE))) AS DaysActive

    FROM dbo.tblPriceHistory   AS ph
    INNER JOIN dbo.tblProductCatalog AS pc ON pc.IDProduct = ph.IDProduct
    INNER JOIN dbo.tblBrand          AS b  ON b.IDBrand    = pc.IDBrand

    WHERE ph.IDProduct = @IDProduct

    ORDER BY ph.StartDate DESC;

    SET NOCOUNT OFF;
END;
GO

-- =============================================================================
-- 4. usp_GetSalesReport
--    Genera un reporte de ventas agrupado por producto para un rango de fechas.
--    Incluye totales generales al final via WITH ROLLUP para facilitar la lectura.
--
--    Parámetros:
--      @StartDate  DATE  — Fecha de inicio del reporte (requerido)
--      @EndDate    DATE  — Fecha de fin del reporte (requerido)
--
--    Ejemplo de uso:
--      EXEC usp_GetSalesReport @StartDate = '2026-01-01', @EndDate = '2026-06-30';
-- =============================================================================
IF OBJECT_ID(N'dbo.usp_GetSalesReport', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetSalesReport;
GO

CREATE PROCEDURE dbo.usp_GetSalesReport
    @StartDate  DATE,
    @EndDate    DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar rango de fechas
    IF @StartDate > @EndDate
    BEGIN
        DECLARE @StartDateStr NVARCHAR(10) = CONVERT(NVARCHAR(10), @StartDate, 23);
        DECLARE @EndDateStr   NVARCHAR(10) = CONVERT(NVARCHAR(10), @EndDate,   23);
        RAISERROR(N'La fecha de inicio (%s) no puede ser posterior a la fecha de fin (%s).',
                  16, 1, @StartDateStr, @EndDateStr);
        RETURN;
    END

    SELECT
        -- ROLLUP: cuando estos campos son NULL corresponde a la fila de TOTAL GENERAL
        pc.IDProduct,
        pc.ProductName,
        b.BrandName,
        cat.CategoryName,

        SUM(id.Quantity)             AS TotalUnitsSold,
        SUM(id.Subtotal)             AS TotalRevenue,
        AVG(id.UnitPrice)            AS AverageUnitPrice,
        COUNT(DISTINCT im.IDInvoice) AS NumberOfInvoices

    FROM dbo.tblInvoiceMaster   AS im
    INNER JOIN dbo.tblInvoiceDetail  AS id  ON id.IDInvoice  = im.IDInvoice
    INNER JOIN dbo.tblProductCatalog AS pc  ON pc.IDProduct  = id.IDProduct
    INNER JOIN dbo.tblBrand          AS b   ON b.IDBrand      = pc.IDBrand
    INNER JOIN dbo.tblProductCategory AS cat ON cat.IDCategory = pc.IDCategory

    WHERE im.InvoiceDate BETWEEN @StartDate AND @EndDate

    GROUP BY ROLLUP (
        pc.IDProduct,
        pc.ProductName,
        b.BrandName,
        cat.CategoryName
    )

    ORDER BY TotalRevenue DESC;

    SET NOCOUNT OFF;
END;
GO

-- =============================================================================
-- PERMISOS: Otorgar EXECUTE a los roles existentes
-- =============================================================================
GRANT EXECUTE ON dbo.usp_GetCustomerInvoices    TO [Rol_Facturacion];
GRANT EXECUTE ON dbo.usp_GetLowStockProducts    TO [Rol_Facturacion];
GRANT EXECUTE ON dbo.usp_GetProductPriceHistory TO [Rol_Facturacion];
GRANT EXECUTE ON dbo.usp_GetSalesReport         TO [Rol_Facturacion];

GRANT EXECUTE ON dbo.usp_GetCustomerInvoices    TO [Rol_Auditor];
GRANT EXECUTE ON dbo.usp_GetLowStockProducts    TO [Rol_Auditor];
GRANT EXECUTE ON dbo.usp_GetProductPriceHistory TO [Rol_Auditor];
GRANT EXECUTE ON dbo.usp_GetSalesReport         TO [Rol_Auditor];
GO

PRINT '✔ Procedimientos almacenados creados: usp_GetCustomerInvoices, usp_GetLowStockProducts, usp_GetProductPriceHistory, usp_GetSalesReport';
GO
