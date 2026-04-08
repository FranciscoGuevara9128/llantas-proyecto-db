/*
===========================================================
 SCRIPT MAESTRO - CONFIGURACIÓN DE BASE DE DATOS
===========================================================

IMPORTANTE:

Este script utiliza comandos :r (SQLCMD), por lo tanto:

❌ NO debe ejecutarse desde SQL Server Management Studio (SSMS)
   ya que puede generar errores con rutas relativas.

✅ Debe ejecutarse desde terminal usando sqlcmd.

-----------------------------------------------------------

INSTRUCCIONES DE EJECUCIÓN:

1. Abrir PowerShell o CMD
2. Navegar a la carpeta del proyecto:

   cd "ruta_del_proyecto"

3. Ejecutar:

   sqlcmd -S localhost -i "00_setup.sql"

-----------------------------------------------------------

DESCRIPCIÓN:

Este script ejecuta en orden:

- Creación de tablas
- Creación de relaciones (FK y constraints)
- Creación de índices
- Inserción de datos iniciales

-----------------------------------------------------------

NOTA:

Se utilizan rutas relativas para mantener la portabilidad del proyecto.

===========================================================
*/

:r ".\01_esquema\tablas.sql"
GO
:r ".\01_esquema\relaciones.sql"
GO
:r ".\01_esquema\indices.sql"
GO
:r ".\02_datos_iniciales\inserts.sql"
GO