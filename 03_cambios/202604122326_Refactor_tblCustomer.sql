USE [llantas];
GO

/* 1. RENOMBRADO DE OBJETOS (ESTÁNDAR PASCALCASE E INGLÉS)
   Cambiamos el nombre de la tabla y sus columnas principales.
*/
EXEC sp_rename 'dbo.Cliente', 'tblCustomer';
EXEC sp_rename 'dbo.tblCustomer.ID_Cliente', 'IDCustomer', 'COLUMN';
EXEC sp_rename 'dbo.tblCustomer.Nombre_Cliente', 'FullName', 'COLUMN';

/* 2. MEJORA DE TIPOS DE DATOS (ESTÁNDAR UNICODE)
   Migramos de VARCHAR a NVARCHAR para soportar caracteres especiales.
*/
ALTER TABLE dbo.tblCustomer 
ALTER COLUMN FullName NVARCHAR(100) NOT NULL;

/* 3. IMPLEMENTACIÓN DE CAPA DE AUDITORÍA
   Agregamos campos para rastrear quién y cuándo crea o modifica registros.
*/
ALTER TABLE dbo.tblCustomer ADD 
    RegistrationDate DATETIME2 DEFAULT GETDATE(),
    RegistrationUser NVARCHAR(50) DEFAULT USER_NAME(),
    ModificationDate DATETIME2 NULL,
    ModificationUser NVARCHAR(50) NULL;

/* 4. AUTOMATIZACIÓN DE LA AUDITORÍA
   Creamos un Trigger para que la fecha de modificación se actualice sola.
*/
GO
CREATE TRIGGER trg_tblCustomer_UpdateAudit
ON dbo.tblCustomer
AFTER UPDATE
AS
BEGIN
    UPDATE dbo.tblCustomer
    SET ModificationDate = GETDATE(),
        ModificationUser = USER_NAME()
    FROM Inserted i
    WHERE dbo.tblCustomer.IDCustomer = i.IDCustomer;
END;
GO

/* 5. NORMALIZACIÓN DE CONSTRAINT
   Renombramos la llave primaria para seguir el estándar idx/pk.
*/
EXEC sp_rename 'dbo.PK_Cliente', 'PK_tblCustomer';