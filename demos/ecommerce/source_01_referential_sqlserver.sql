-- drop then create the database
USE master; -- in order to stop using Referential ^^
DROP DATABASE IF EXISTS Referential;
CREATE DATABASE Referential;
USE Referential;
CREATE SCHEMA [referential];


-- database schema
CREATE TABLE [referential].[Countries] (
    [CountryId] [bigint] IDENTITY (1,1) PRIMARY KEY,
    [Code]      [nvarchar](5)   NOT NULL,
    [Name]      [nvarchar](255) NOT NULL,
    [CreatedAt] [datetime]      NOT NULL DEFAULT GETDATE(),
    [DeletedAt] [datetime]
);
CREATE UNIQUE INDEX [IDX_Countries_Code] ON [referential].[Countries] ([Code]);
CREATE UNIQUE INDEX [IDX_Countries_Name] ON [referential].[Countries] ([Name]);
EXEC sp_addextendedproperty 'MS_Description', 'needs to be referenced for legal reasons', 'SCHEMA', 'referential', 'TABLE', 'Countries';

CREATE TABLE [referential].[States] (
    [StateId]   [bigint] IDENTITY (1,1) PRIMARY KEY,
    [CountryId] [bigint]        NOT NULL,
    [Code]      [nvarchar](5)   NOT NULL,
    [Name]      [nvarchar](255) NOT NULL,
    [CreatedAt] [datetime]      NOT NULL DEFAULT GETDATE(),
    [DeletedAt] [datetime],
    CONSTRAINT [FK_States_Country] FOREIGN KEY ([CountryId]) REFERENCES [referential].[Countries] ([CountryId])
);
CREATE INDEX [IDX_States_CountryId] ON [referential].[States] ([CountryId]);
CREATE INDEX [IDX_States_Code] ON [referential].[States] ([Code]);
CREATE INDEX [IDX_States_Name] ON [referential].[States] ([Name]);
EXEC sp_addextendedproperty 'MS_Description', 'used for auto-competes', 'SCHEMA', 'referential', 'TABLE', 'States';

CREATE TABLE [referential].[Cities] (
    [CityId]    [bigint] IDENTITY (1,1) PRIMARY KEY,
    [StateId]   [bigint]        NOT NULL,
    [Name]      [nvarchar](255) NOT NULL,
    [CreatedAt] [datetime]      NOT NULL DEFAULT GETDATE(),
    [DeletedAt] [datetime],
    CONSTRAINT [FK_Cities_State] FOREIGN KEY ([StateId]) REFERENCES [referential].[States] ([StateId])
);
CREATE INDEX [IDX_Cities_StateId] ON [referential].[Cities] ([StateId]);
CREATE INDEX [IDX_Cities_Name] ON [referential].[Cities] ([Name]);
EXEC sp_addextendedproperty 'MS_Description', 'used for auto-competes', 'SCHEMA', 'referential', 'TABLE', 'Cities';


-- database data
INSERT INTO [referential].[Countries] ([Code], [Name])
VALUES ('FRA', 'France'),
       ('DEU', 'Germany'),
       ('ESP', 'Spain'),
       ('ITA', 'Italy'),
       ('USA', 'United States'),
       ('CAN', 'Canada'),
       ('MEX', 'Mexico');

INSERT INTO [referential].[States] ([CountryId], [Code], [Name])
VALUES (1, 'IDF', N'Île-de-France'),
       (1, 'PAC', N'Provence-Alpes-Côte d''Azur'),
       (2, 'BE', 'Berlin'),
       (2, 'BW', N'Baden-Württemberg'),
       (3, 'MD', 'Madrid'),
       (3, 'CAT', 'Catalonia'),
       (4, 'LAZ', 'Lazio'),
       (4, 'LOM', 'Lombardy'),
       (5, 'CA', 'California'),
       (5, 'TX', 'Texas'),
       (5, 'NY', 'New York'),
       (6, 'ON', 'Ontario'),
       (6, 'QC', 'Quebec'),
       (7, 'CDMX', N'Ciudad de México'),
       (7, 'JAL', 'Jalisco');

INSERT INTO [referential].[Cities] ([StateId], [Name])
VALUES (1, 'Paris'),
       (1, 'Boulogne-Billancourt'),
       (2, 'Marseille'),
       (2, 'Nice'),
       (3, 'Berlin'),
       (4, 'Stuttgart'),
       (4, 'Karlsruhe'),
       (5, 'Madrid'),
       (6, 'Barcelona'),
       (6, 'Girona'),
       (7, 'Rome'),
       (7, 'Latina'),
       (8, 'Milan'),
       (8, 'Bergamo'),
       (9, 'Los Angeles'),
       (9, 'San Francisco'),
       (10, 'Houston'),
       (10, 'Dallas'),
       (11, 'New York City'),
       (11, 'Buffalo'),
       (12, 'Toronto'),
       (12, 'Ottawa'),
       (13, 'Montreal'),
       (13, 'Quebec City'),
       (14, 'Mexico City'),
       (15, 'Guadalajara');
