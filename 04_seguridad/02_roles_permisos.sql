/*
================================================================================
SCRIPT: 02_roles_permisos.sql
MODULO: Seguridad y Gobierno de Datos
================================================================================
*/

USE [llantas];
GO

-- -----------------------------------------------------------------------------
-- 1. CREACIÓN DE ROLES PERSONALIZADOS
-- -----------------------------------------------------------------------------

IF DATABASE_PRINCIPAL_ID('Rol_Facturacion') IS NULL
BEGIN
    CREATE ROLE [Rol_Facturacion];
END
GO

IF DATABASE_PRINCIPAL_ID('Rol_Auditor') IS NULL
BEGIN
    CREATE ROLE [Rol_Auditor];
END
GO

IF DATABASE_PRINCIPAL_ID('Rol_Admin_Jr') IS NULL
BEGIN
    CREATE ROLE [Rol_Admin_Jr];
END
GO

-- -----------------------------------------------------------------------------
-- 2. ASIGNACIÓN DE PERMISOS AL ROL DE FACTURACIÓN (Rol_Facturacion)
-- -----------------------------------------------------------------------------

-- A. Permisos de Lectura, Escritura y Modificación en Ventas y Clientes
GRANT SELECT, INSERT, UPDATE ON [dbo].[tblInvoiceMaster] TO [Rol_Facturacion];
GRANT SELECT, INSERT, UPDATE ON [dbo].[tblInvoiceDetail] TO [Rol_Facturacion];
GRANT SELECT, INSERT, UPDATE ON [dbo].[tblCustomer] TO [Rol_Facturacion];
GRANT SELECT, INSERT, UPDATE ON [dbo].[tblReferralMaster] TO [Rol_Facturacion];
GRANT SELECT, INSERT, UPDATE ON [dbo].[tblReferralDetail] TO [Rol_Facturacion];

-- B. Permisos de Lectura sobre catálogos de productos y marcas de llantas
GRANT SELECT ON [dbo].[tblProductCatalog] TO [Rol_Facturacion];
GRANT SELECT ON [dbo].[tblProductCategory] TO [Rol_Facturacion];
GRANT SELECT ON [dbo].[tblBrand] TO [Rol_Facturacion];
GRANT SELECT ON [dbo].[tblUnitOfMeasure] TO [Rol_Facturacion];
GRANT SELECT ON [dbo].[tblStatus] TO [Rol_Facturacion];

-- C. Lectura y actualización de existencias en Inventario de Llantas
GRANT SELECT, UPDATE ON [dbo].[tblProductInventory] TO [Rol_Facturacion];

-- D. SEGURIDAD ADICIONAL: Restricciones explícitas (DENY)
-- Previene que los cajeros o personal de facturación borren facturas del sistema (auditoría fiscal)
DENY DELETE ON [dbo].[tblInvoiceMaster] TO [Rol_Facturacion];
DENY DELETE ON [dbo].[tblInvoiceDetail] TO [Rol_Facturacion];
-- Previene que el personal de facturación modifique el catálogo principal de productos (evita fraude en precios)
DENY INSERT, UPDATE, DELETE ON [dbo].[tblProductCatalog] TO [Rol_Facturacion];
DENY INSERT, UPDATE, DELETE ON [dbo].[tblBrand] TO [Rol_Facturacion];
GO

-- -----------------------------------------------------------------------------
-- 3. ASIGNACIÓN DE PERMISOS AL ROL DE AUDITORÍA (Rol_Auditor)
-- -----------------------------------------------------------------------------

-- El auditor requiere acceso total de lectura (SELECT) en todas las nuevas tablas
GRANT SELECT ON [dbo].[tblProductCatalog] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblProductCategory] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblCustomer] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblVendorContact] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblStatus] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblInvoiceDetail] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblInvoiceMaster] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblPriceHistory] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblProductInventory] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblInventoryKardex] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblBrand] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblVendor] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblReferralDetail] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblReferralMaster] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblVendorRepresentative] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblKardexTransaction] TO [Rol_Auditor];
GRANT SELECT ON [dbo].[tblUnitOfMeasure] TO [Rol_Auditor];

-- SEGURIDAD ADICIONAL: Prohibición total de alteración de datos y de esquema
DENY INSERT, UPDATE, DELETE TO [Rol_Auditor];
GO

-- -----------------------------------------------------------------------------
-- 4. ASIGNACIÓN DE PERMISOS AL ROL DE ADMINISTRADOR JUNIOR (Rol_Admin_Jr)
-- -----------------------------------------------------------------------------

-- El Administrador Junior tiene acceso completo a los datos (DML) para soporte operativo
GRANT SELECT, INSERT, UPDATE, DELETE TO [Rol_Admin_Jr];

-- Le permitimos visualizar definiciones de objetos para análisis y tuning de índices
GRANT VIEW DEFINITION TO [Rol_Admin_Jr];
GO

-- -----------------------------------------------------------------------------
-- 5. ASOCIACIÓN DE MIEMBROS A LOS ROLES
-- -----------------------------------------------------------------------------

ALTER ROLE [Rol_Admin_Jr] ADD MEMBER [usr_admin_jr];

ALTER ROLE [Rol_Auditor] ADD MEMBER [usr_auditor];
GO