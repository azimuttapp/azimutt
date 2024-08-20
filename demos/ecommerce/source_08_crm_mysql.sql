-- drop everything
DROP SCHEMA IF EXISTS crm;

-- create the database
CREATE SCHEMA crm;
USE crm;

CREATE TABLE People (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(255) NOT NULL,
    email      VARCHAR(255),
    phone      VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT,
    deleted_at TIMESTAMP,
    deleted_by BIGINT,
    INDEX idx_people_deleted_at (deleted_at)
);

CREATE TABLE Organizations (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT,
    deleted_at TIMESTAMP,
    deleted_by BIGINT,
    INDEX idx_organizations_deleted_at (deleted_at)
);

CREATE TABLE OrganizationMembers (
    person_id       BIGINT REFERENCES People (id),
    organization_id BIGINT REFERENCES Organizations (id),
    role            VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by      BIGINT,
    deleted_at      TIMESTAMP,
    deleted_by      BIGINT,
    PRIMARY KEY (person_id, organization_id),
    INDEX idx_organization_members_deleted_at (deleted_at)
);

CREATE TABLE SocialAccounts (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    network    ENUM ('twitter', 'linkedin', 'facebook', 'instagram', 'tiktok', 'snapchat') NOT NULL,
    username   VARCHAR(255)                                                                NOT NULL,
    owner_kind ENUM ('People', 'Organizations'),
    owner_id   BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT,
    deleted_at TIMESTAMP,
    deleted_by BIGINT,
    INDEX idx_social_accounts_deleted_at (deleted_at)
);

CREATE TABLE Campaigns (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(255)                                                                  NOT NULL,
    status     ENUM ('draft', 'live', 'paused')                                              NOT NULL,
    starts     TIMESTAMP,
    ends       TIMESTAMP,
    kind       ENUM ('email', 'sms', 'push', 'twitter', 'linkedin', 'instagram', 'facebook') NOT NULL,
    audience   TEXT COMMENT 'DSL for selecting the audience, from crm.People for email & sms or from crm.SocialAccounts for others',
    subject    VARCHAR(255),
    message    TEXT COMMENT 'HTML with templating using recipient info',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT,
    deleted_at TIMESTAMP,
    deleted_by BIGINT,
    INDEX idx_campaigns_deleted_at (deleted_at)
);

CREATE TABLE CampaignMessages (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    campaign_id BIGINT REFERENCES Campaigns (id),
    contact_id  BIGINT REFERENCES People (id),
    social_id   BIGINT REFERENCES SocialAccounts (id),
    sent_to     VARCHAR(255) NOT NULL COMMENT 'can be email, phone number, social account... depending on campaign kind',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at     TIMESTAMP,
    opened_at   TIMESTAMP,
    clicked_at  TIMESTAMP
);

CREATE TABLE Issues (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    subject    VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    closed_at  TIMESTAMP,
    closed_by  BIGINT,
    INDEX idx_issues_closed_at (closed_at)
);

CREATE TABLE IssueMessages (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    issue_id   BIGINT REFERENCES Issues (id),
    content    TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by BIGINT
);

CREATE TABLE IssueMessageReactions (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    message_id BIGINT REFERENCES IssueMessages (id),
    kind       ENUM ('like', 'dislike') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    deleted_at TIMESTAMP,
    deleted_by BIGINT,
    INDEX idx_issue_message_reactions_deleted_at (deleted_at)
);

CREATE TABLE Discounts (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(255)                  NOT NULL,
    description VARCHAR(255),
    kind        ENUM ('percentage', 'amount') NOT NULL,
    value       DOUBLE                        NOT NULL,
    enable_at   TIMESTAMP,
    expire_at   TIMESTAMP,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by  BIGINT,
    deleted_at  TIMESTAMP,
    deleted_by  BIGINT,
    INDEX idx_discounts_deleted_at (deleted_at)
);

CREATE TABLE Coupons (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    discount_id BIGINT REFERENCES Discounts (id),
    code        VARCHAR(255) UNIQUE NOT NULL COMMENT 'public code to use the discount',
    expire_at   TIMESTAMP,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by  BIGINT,
    deleted_at  TIMESTAMP,
    deleted_by  BIGINT,
    INDEX idx_coupons_deleted_at (deleted_at)
);


-- insert some data
INSERT INTO People (name, email, phone, created_by, updated_by)
VALUES ('John Doe', 'john.doe@example.com', '1234567890', 1, 1),
       ('Jane Smith', 'jane.smith@example.com', '0987654321', 2, 2);

INSERT INTO Organizations (name, created_by, updated_by)
VALUES ('Tech Corp', 1, 1),
       ('Business Inc', 2, 2);

INSERT INTO OrganizationMembers (person_id, organization_id, role, created_by, updated_by)
VALUES (1, 1, 'Manager', 1, 1),
       (2, 2, 'Director', 2, 2);

INSERT INTO SocialAccounts (network, username, owner_kind, owner_id, created_by, updated_by)
VALUES ('twitter', 'john_doe', 'People', 1, 1, 1),
       ('linkedin', 'jane_smith', 'Organizations', 2, 2, 2);

INSERT INTO Campaigns (name, status, kind, audience, subject, message, created_by, updated_by)
VALUES ('Winter Sale', 'draft', 'email', 'All subscribers', 'Winter Sale 2024', '<p>Don\'t miss out on our Winter Sale!</p>', 1, 1),
       ('Summer Promotion', 'live', 'sms', 'VIP customers', 'Summer Promotion', 'Get 50% off all items!', 2, 2);

INSERT INTO CampaignMessages (campaign_id, contact_id, sent_to, created_at, sent_at)
VALUES (1, 1, 'john.doe@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (2, 2, 'jane.smith@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

INSERT INTO Issues (subject, created_by)
VALUES ('Product not delivered', 1),
       ('Refund request', 2);

INSERT INTO IssueMessages (issue_id, content, created_by, updated_by)
VALUES (1, 'The product was supposed to arrive yesterday but it hasn\'t arrived yet.', 1, 1),
       (2, 'I would like a refund for my recent purchase.', 2, 2);

INSERT INTO IssueMessageReactions (message_id, kind, created_by)
VALUES (1, 'like', 1),
       (2, 'dislike', 2);

INSERT INTO Discounts (name, description, kind, value, enable_at, expire_at, created_by, updated_by)
VALUES ('New Year Discount', '10% off on all items', 'percentage', 10.00, '2024-01-01 00:00:00', '2024-01-31 23:59:59', 1, 1),
       ('Black Friday Deal', 'Flat $50 off', 'amount', 50.00, '2024-11-29 00:00:00', '2024-11-29 23:59:59', 2, 2);

INSERT INTO Coupons (discount_id, code, expire_at, created_by, updated_by)
VALUES (1, 'NY2024', '2024-01-31 23:59:59', 1, 1),
       (2, 'BF2024', '2024-11-29 23:59:59', 2, 2);
