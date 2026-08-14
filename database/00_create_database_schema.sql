SET NOCOUNT ON;
GO

IF DB_ID(N'tomawebp_oferta') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [tomawebp_oferta]');
END;
GO

USE [tomawebp_oferta];
GO

IF OBJECT_ID(N'dbo.Oferta', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Oferta] (
        [id] int IDENTITY(1,1) NOT NULL,
        [lp] nvarchar(10) NULL,
        [nazwa] nvarchar(500) NULL,
        [stan] nvarchar(10) NULL,
        [jm] nvarchar(20) NULL,
        [vat] nvarchar(10) NULL,
        [cennik_kartuzy_n_pln] decimal(10,2) NULL,
        [cennik_kartuzy_b_pln] decimal(10,2) NULL,
        [cennik_kartuzy_n_pln_alt] decimal(10,2) NULL,
        [cennik_kartuzy_b_pln_alt] decimal(10,2) NULL,
        [data_utworzenia] datetime2(0) NOT NULL
            CONSTRAINT [DF_Oferta_data_utworzenia] DEFAULT (GETDATE()),
        CONSTRAINT [PK_Oferta] PRIMARY KEY CLUSTERED ([id])
    );
END;
GO

SELECT
    DB_NAME() AS [DatabaseName],
    OBJECT_SCHEMA_NAME(OBJECT_ID(N'dbo.Oferta')) AS [SchemaName],
    OBJECT_NAME(OBJECT_ID(N'dbo.Oferta')) AS [TableName];
GO
