-- drop then create the database
USE master; -- in order to stop using Billing ^^
DROP DATABASE IF EXISTS Billing;
CREATE DATABASE Billing;
USE Billing;
CREATE SCHEMA [billing];


-- database schema
CREATE TABLE [billing].[CustomerAddresses] (
    [CustomerAddressesId] [bigint] IDENTITY (1,1) PRIMARY KEY,
    [Name]                [nvarchar](255) NOT NULL,
    [Street]              [nvarchar](255) NOT NULL,
    [City]                [nvarchar](255) NOT NULL,
    [State]               [nvarchar](255) NOT NULL,
    [ZipCode]             [nvarchar](20)  NOT NULL,
    [Country]             [bigint],
    [Complements]         [text],
    [CreatedAt]           [datetime] DEFAULT CURRENT_TIMESTAMP,
    [CreatedBy]           [bigint],
    [DeletedAt]           [datetime],
    [DeletedBy]           [bigint]
);
CREATE INDEX [IdxCustomerAddressesDeletedAt] ON [billing].[CustomerAddresses] ([DeletedAt]);

CREATE TABLE [billing].[Customers] (
    [CustomerId]     [bigint] IDENTITY (1,1) PRIMARY KEY,
    [Name]           [nvarchar](255) NOT NULL,
    [BillingAddress] [bigint] REFERENCES [billing].[CustomerAddresses] ([CustomerAddressesId]),
    [Siret]          [nvarchar](14),
    [TVA]            [nvarchar](13),
    [CreatedAt]      [datetime] DEFAULT CURRENT_TIMESTAMP,
    [CreatedBy]      [bigint],
    [UpdatedAt]      [datetime] DEFAULT CURRENT_TIMESTAMP,
    [UpdatedBy]      [bigint],
    [DeletedAt]      [datetime],
    [DeletedBy]      [bigint]
);
CREATE INDEX [IdxCustomersDeletedAt] ON [billing].[Customers] ([DeletedAt]);

CREATE TABLE [billing].[CustomerMembers] (
    [CustomerId]      [bigint] REFERENCES [billing].[Customers] ([CustomerId]),
    [UserId]          [bigint],
    [CanEdit]         [bit],
    [CanInvite]       [bit],
    [CanBuy]          [bit],
    [BudgetAllowance] [int],
    [CreatedAt]       [datetime] DEFAULT CURRENT_TIMESTAMP,
    [CreatedBy]       [bigint],
    [UpdatedAt]       [datetime] DEFAULT CURRENT_TIMESTAMP,
    [UpdatedBy]       [bigint],
    [DeletedAt]       [datetime],
    [DeletedBy]       [bigint],
    PRIMARY KEY ([CustomerId], [UserId])
);
CREATE INDEX [IdxCustomerMembersDeletedAt] ON [billing].[CustomerMembers] ([DeletedAt]);

CREATE TABLE [billing].[CustomerPaymentMethods] (
    [CustomerPaymentMethodId] [bigint] IDENTITY (1,1) PRIMARY KEY,
    [CustomerId]              [bigint] REFERENCES [billing].[Customers] ([CustomerId]),
    [Name]                    [nvarchar](255) NOT NULL,
    [Kind]                    [nvarchar](50) CHECK ([Kind] IN ('card', 'paypal')),
    [Details]                 [nvarchar](MAX) CHECK (ISJSON([Details]) = 1),
    [CreatedAt]               [datetime] DEFAULT CURRENT_TIMESTAMP,
    [CreatedBy]               [bigint],
    [UpdatedAt]               [datetime] DEFAULT CURRENT_TIMESTAMP,
    [UpdatedBy]               [bigint],
    [DeletedAt]               [datetime],
    [DeletedBy]               [bigint]
);
CREATE INDEX [IdxCustomerPaymentMethodsDeletedAt] ON [billing].[CustomerPaymentMethods] ([DeletedAt]);

CREATE TABLE [billing].[Invoices] (
    [InvoiceId]      [bigint] IDENTITY (1,1) PRIMARY KEY,
    [Reference]      [nvarchar](50) UNIQUE NOT NULL,
    [CartId]         [bigint],
    [CustomerId]     [bigint] REFERENCES [billing].[Customers] ([CustomerId]),
    [BillingAddress] [bigint] REFERENCES [billing].[CustomerAddresses] ([CustomerAddressesId]),
    [TotalPrice]     [float],
    [Currency]       [nvarchar](3) CHECK ([Currency] IN ('EUR', 'USD')),
    [PaidAt]         [datetime],
    [CreatedAt]      [datetime] DEFAULT CURRENT_TIMESTAMP,
    [CreatedBy]      [bigint]
);

CREATE TABLE [billing].[InvoiceLines] (
    [InvoiceId]        [bigint] REFERENCES [billing].[Invoices] ([InvoiceId]),
    [Index]            [int],
    [ProductVersionId] [bigint],
    [Description]      [text],
    [Price]            [float],
    [Quantity]         [int],
    PRIMARY KEY ([InvoiceId], [Index])
);

CREATE TABLE [billing].[Payments] (
    [PaymentId]       [bigint] IDENTITY (1,1) PRIMARY KEY,
    [InvoiceId]       [bigint] REFERENCES [billing].[Invoices] ([InvoiceId]),
    [PaymentMethodId] [bigint] REFERENCES [billing].[CustomerPaymentMethods] ([CustomerPaymentMethodId]),
    [Amount]          [float],
    [Currency]        [nvarchar](3) CHECK ([Currency] IN ('EUR', 'USD')),
    [CreatedAt]       [datetime] DEFAULT CURRENT_TIMESTAMP
);


-- database data
INSERT INTO [billing].[CustomerAddresses] ([Name], [Street], [City], [State], [ZipCode], [Country], [Complements], [CreatedBy])
VALUES ('SpongeHome', '124 Conch Street', 'Bikini Bottom', 'Pacific Ocean', '12345', 1, 'Pineapple house next to Squidward', 102);

INSERT INTO [billing].[Customers] ([Name], [BillingAddress], [Siret], [TVA], [CreatedBy], [UpdatedBy])
VALUES ('SpongeBob', 1, NULL, NULL, 102, 102),
       ('Krusty Enterprises', 1, '12345678900010', 'FR12345678901', 102, 102);

INSERT INTO [billing].[CustomerMembers] ([CustomerId], [UserId], [CanEdit], [CanInvite], [CanBuy], [BudgetAllowance], [CreatedBy], [UpdatedBy])
VALUES (1, 102, 1, 1, 1, NULL, 102, 102),
       (2, 102, 1, 1, 1, NULL, 102, 102),
       (2, 103, 1, 0, 1, 500, 102, 102);

INSERT INTO [billing].[CustomerPaymentMethods] ([CustomerId], [Name], [Kind], [Details], [CreatedBy], [UpdatedBy])
VALUES (1, 'PayPal perso', 'paypal', '{"paypal_account": "spongebob@bikinibottom.com"}', 102, 102),
       (2, 'Company Card', 'card', '{"card_number": "4111111111111111", "expiry_date": "12/28"}', 102, 102);

INSERT INTO [billing].[Invoices] ([Reference], [CartId], [CustomerId], [BillingAddress], [TotalPrice], [Currency], [CreatedBy])
VALUES ('INV-001', 1, 1, 1, 1323, 'EUR', 102);

INSERT INTO [billing].[InvoiceLines] ([InvoiceId], [Index], [ProductVersionId], [Description], [Price], [Quantity])
VALUES (1, 1, 1, 'Pixel 8 Obsidian 128 Go', 599, 1),
       (1, 2, 2, 'Pixel 8 Obsidian 256 Go', 659, 1),
       (1, 3, 15, 'Pixel 8 Case Hazel', 35, 1),
       (1, 4, 20, 'Pixel 8 Case Signature Clear', 30, 1);

INSERT INTO [billing].[Payments] ([InvoiceId], [PaymentMethodId], [Amount], [Currency])
VALUES (1, 1, 1323, 'EUR');
