USE llantas

-- Eliminar tablas transaccionales primero (debido a las dependencias)

DROP TABLE IF EXISTS Kardex_Inventario;
DROP TABLE IF EXISTS Factura_Detalle;
DROP TABLE IF EXISTS Factura_Maestro;
DROP TABLE IF EXISTS Remision_Detalle;
DROP TABLE IF EXISTS Remision_Maestro;
DROP TABLE IF EXISTS Historial_Precio;
DROP TABLE IF EXISTS Inventario_Producto;
DROP TABLE IF EXISTS Usuario;
DROP TABLE IF EXISTS Catalogo_Producto;
DROP TABLE IF EXISTS Marca;
DROP TABLE IF EXISTS Transaccion_Kardex;
DROP TABLE IF EXISTS Categoria_Producto;
DROP TABLE IF EXISTS Unidad_Medida;
DROP TABLE IF EXISTS tblCustomer;
DROP TABLE IF EXISTS ContactoProveedor;
DROP TABLE IF EXISTS RepresentanteProveedor;
DROP TABLE IF EXISTS Proveedor;
DROP TABLE IF EXISTS Estado;
GO

SELECT table_name 
FROM information_schema.tables 
WHERE table_type = 'BASE TABLE' AND table_catalog = 'llantas';
GO