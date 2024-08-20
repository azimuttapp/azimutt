-- drop everything
USE master; -- in order to stop using Billing ^^
DROP DATABASE IF EXISTS Billing;

-- create the database
CREATE DATABASE Billing;
USE Billing;
CREATE SCHEMA [billing];


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


-- insert some data
INSERT INTO [billing].[CustomerAddresses] ([Name], [Street], [City], [State], [ZipCode], [Country], [CreatedBy])
VALUES ('Billing Address 1', '123 Main St', 'Anytown', 'Anystate', '12345', 1, 1),
       ('Billing Address 2', '456 Elm St', 'Othertown', 'Otherstate', '67890', 2, 2);

INSERT INTO [billing].[Customers] ([Name], [BillingAddress], [Siret], [TVA], [CreatedBy], [UpdatedBy])
VALUES ('Customer A', NULL, '12345678901234', 'FR12345678901', 1, 1),
       ('Customer B', NULL, '98765432109876', 'DE09876543210', 2, 2);

INSERT INTO [billing].[CustomerMembers] ([CustomerId], [UserId], [CanEdit], [CanInvite], [CanBuy], [BudgetAllowance],
                                         [CreatedBy], [UpdatedBy])
VALUES (1, 1, 1, 1, 1, 1000, 1, 1),
       (2, 2, 1, 0, 1, 500, 2, 2);

INSERT INTO [billing].[CustomerPaymentMethods] ([CustomerId], [Name], [Kind], [Details], [CreatedBy], [UpdatedBy])
VALUES (1, 'Credit Card', 'card', '{"card_number": "4111111111111111", "expiry_date": "12/23"}', 1, 1),
       (2, 'PayPal', 'paypal', '{"paypal_account": "customer_b@paypal.com"}', 2, 2);

INSERT INTO [billing].[Invoices] ([Reference], [CartId], [CustomerId], [BillingAddress], [TotalPrice], [Currency],
                                  [CreatedBy])
VALUES ('INV-001', 1, 1, 1, 200.00, 'USD', 1),
       ('INV-002', 2, 2, 2, 300.00, 'EUR', 2);

INSERT INTO [billing].[InvoiceLines] ([InvoiceId], [Index], [ProductVersionId], [Description], [Price], [Quantity])
VALUES (1, 1, 1, 'Product 1 Description', 100.00, 2),
       (2, 1, 2, 'Product 2 Description', 150.00, 2);

INSERT INTO [billing].[Payments] ([InvoiceId], [PaymentMethodId], [Amount], [Currency])
VALUES (1, 1, 200.00, 'USD'),
       (2, 2, 300.00, 'EUR');
