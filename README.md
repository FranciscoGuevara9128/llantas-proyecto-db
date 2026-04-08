\# Proyecto Base de Datos - Llantas



\## 📌 Descripción

Este proyecto contiene la estructura completa de una base de datos para la gestión de inventario, clientes, proveedores y facturación.



Incluye:

\- Creación de tablas

\- Relaciones (FK y restricciones)

\- Índices

\- Datos iniciales



\---



\## 📁 Estructura del proyecto



llantas-Proyecto/

│

├── 00\_setup.sql

│

├── 01\_esquema/

│ ├── tablas.sql

│ ├── relaciones.sql

│ └── indices.sql

│

├── 02\_datos\_iniciales/

│ └── inserts.sql

│

├── 03\_cambios/

│

└── backup/



\---



\## ⚙️ Requisitos



\- SQL Server instalado

\- Herramienta `sqlcmd` disponible en el sistema



\---



\## 🚀 Ejecución del proyecto



\### ⚠️ IMPORTANTE

El script `00\_setup.sql` utiliza comandos `:r` de SQLCMD, por lo tanto:



❌ \*\*NO funciona correctamente desde SSMS (SQL Server Management Studio)\*\*  

✅ \*\*Debe ejecutarse desde la terminal\*\*



\---



\## ▶️





\---



\## ⚙️ Requisitos



\- SQL Server instalado

\- Herramienta `sqlcmd` disponible en el sistema



\---



\## 🚀 Ejecución del proyecto



\### ⚠️ IMPORTANTE

El script `00\_setup.sql` utiliza comandos `:r` de SQLCMD, por lo tanto:



❌ \*\*NO funciona correctamente desde SSMS (SQL Server Management Studio)\*\*  

✅ \*\*Debe ejecutarse desde la terminal\*\*



\---



\## ▶️ Ejecución paso a paso



1\. Abrir terminal (PowerShell o CMD)

2\. Navegar a la carpeta del proyecto:

3\. Ejecutar el script:



sqlcmd -S localhost -i "00\_setup.sql"



\---



\## 📌 ¿Qué hace el script?



El archivo `00\_setup.sql` ejecuta en orden:



1\. Creación de tablas

2\. Definición de relaciones

3\. Creación de índices

4\. Inserción de datos iniciales



\---



\## 🧾 Notas



\- El uso de rutas relativas permite la portabilidad del proyecto

\- La ejecución mediante `sqlcmd` garantiza el correcto procesamiento de los comandos `:r`

\- La estructura modular facilita el mantenimiento y la trazabilidad

