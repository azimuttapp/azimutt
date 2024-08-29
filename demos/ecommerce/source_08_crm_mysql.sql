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
INSERT INTO People (id, name, email, phone, created_by, updated_by)
VALUES (1, 'Han Solo', 'han.solo@rebellion.com', '+33-1-45-67-89-01', 41, 41),
       (2, 'Luke Skywalker', 'luke.skywalker@rebellion.com', NULL, 41, 41),
       (3, 'Leia Organa', 'leia.organa@rebellion.com', '+33-2-98-23-45-67', 41, 41),
       (4, 'Yoda', 'yoda@jediorder.com', NULL, 41, 41),
       (5, 'Obi-Wan Kenobi', 'obi-wan.kenobi@jediorder.com', '+33-4-72-39-56-78', 41, 41),
       (6, 'Anakin Skywalker', 'anakin.skywalker@jediorder.com', NULL, 41, 41),
       (7, 'Darth Vader', 'darth.vader@empire.com', NULL, 41, 41),
       (8, 'Kylo Ren', 'kylo.ren@firstorder.com', NULL, 41, 41),
       (9, 'Rey', 'rey@resistance.com', '+33-5-56-23-45-67', 41, 41),
       (10, 'Finn', 'finn@resistance.com', NULL, 41, 41),
       (11, 'Poe Dameron', 'poe.dameron@resistance.com', NULL, 41, 41),
       (12, 'SpongeBob SquarePants', 'spongebob@bikinibottom.com', '+44-20-7946-0958', 41, 41),
       (13, 'Patrick Star', 'patrick@bikinibottom.com', '+44-20-7946-0321', 41, 41),
       (14, 'Squidward Tentacles', 'squidward@bikinibottom.com', '+44-161-555-3456', 41, 41),
       (15, 'Mr Krabs', 'mr.krabs@bikinibottom.com', '+44-121-555-6789', 41, 41),
       (16, 'Plankton Sheldon', 'plankton@bikinibottom.com', '+44-113-555-4321', 41, 41),
       (17, 'Sandy Cheeks', 'sandy.cheeks@bikinibottom.com', NULL, 41, 41),
       (18, 'Michael Scott', 'michael.scott@dundermifflin.com', '+1-202-555-0173', 41, 41),
       (19, 'Dwight Schrute', 'dwight.schrute@dundermifflin.com', '+1-202-555-0198', 41, 41),
       (20, 'Jim Halpert', 'jim.halpert@dundermifflin.com', '+1-415-555-1234', 41, 41),
       (21, 'Pam Beesly', 'pam.beesly@dundermifflin.com', '+1-718-555-5678', 41, 41),
       (22, 'Stanley Hudson', 'stanley.hudson@dundermifflin.com', '+1-213-555-9012', 41, 41),
       (23, 'Kevin Malone', 'kevin.malone@dundermifflin.com', '+49-30-1234567', 41, 41),
       (24, 'Oscar Martinez', 'oscar.martinez@dundermifflin.com', '+49-40-7654321', 41, 41),
       (25, 'Phyllis Vance', 'phyllis.vance@dundermifflin.com', '+49-69-9876543', 41, 41),
       (26, 'Angela Martin', 'angela.martin@dundermifflin.com', '+49-89-3456789', 41, 41),
       (27, 'Andy Bernard', 'andy.bernard@dundermifflin.com', '+49-221-1234567', 41, 41),
       (28, 'Creed Bratton', 'creed.bratton@dundermifflin.com', NULL, 41, 41),
       (29, 'Meredith Palmer', 'meredith.palmer@dundermifflin.com', NULL, 41, 41),
       (30, 'Ryan Howard', 'ryan.howard@dundermifflin.com', NULL, 41, 41),
       (31, 'Kelly Kapoor', 'kelly.kapoor@dundermifflin.com', NULL, 41, 41),
       (32, 'Toby Flenderson', 'toby.flenderson@dundermifflin.com', NULL, 41, 41),
       (33, 'Daryl Philbin', 'daryl.philbin@dundermifflin.com', NULL, 41, 41);

INSERT INTO Organizations (id, name, created_by, updated_by)
VALUES (1, 'Rebellion', 41, 41),
       (2, 'Jedi Order', 41, 41),
       (3, 'Empire', 41, 41),
       (4, 'First Order', 41, 41),
       (5, 'Resistance', 41, 41),
       (6, 'Bikini Bottom Businesses', 41, 41),
       (7, 'Dunder Mifflin', 41, 41);

INSERT INTO OrganizationMembers (organization_id, person_id, role, created_by, updated_by)
VALUES (1, 1, 'Captain', 41, 41),
       (1, 2, 'Jedi Knight', 41, 41),
       (1, 3, 'Princess', 41, 41),
       (2, 2, 'Jedi Knight', 41, 41),
       (2, 4, 'Jedi Master', 41, 41),
       (2, 5, 'Jedi Master', 41, 41),
       (2, 6, 'Jedi Knight', 41, 41),
       (3, 7, 'Sith Lord', 41, 41),
       (4, 8, 'Supreme Leader', 41, 41),
       (5, 9, 'Jedi', 41, 41),
       (5, 10, 'Soldier', 41, 41),
       (5, 11, 'Pilot', 41, 41),
       (6, 12, 'Fry Cook', 41, 41),
       (6, 13, 'Best Friend', 41, 41),
       (6, 14, 'Cashier', 41, 41),
       (6, 15, 'Owner', 41, 41),
       (6, 16, 'Rival Business Owner', 41, 41),
       (7, 18, 'Regional Manager', 41, 41),
       (7, 19, 'Assistant to the Regional Manager', 41, 41),
       (7, 20, 'Sales Representative', 41, 41),
       (7, 21, 'Receptionist', 41, 41),
       (7, 22, 'Sales Representative', 41, 41),
       (7, 23, 'Accountant', 41, 41),
       (7, 24, 'Accountant', 41, 41),
       (7, 25, 'Sales Representative', 41, 41),
       (7, 26, 'Head of Accounting', 41, 41),
       (7, 27, 'Sales Representative', 41, 41),
       (7, 28, 'Quality Assurance', 41, 41),
       (7, 29, 'Supplier Relations', 41, 41),
       (7, 30, 'Temp', 41, 41),
       (7, 31, 'Customer Service', 41, 41),
       (7, 32, 'HR Representative', 41, 41),
       (7, 33, 'Warehouse Foreman', 41, 41);

INSERT INTO SocialAccounts (owner_kind, owner_id, network, username, created_by, updated_by)
VALUES ('People', 1, 'twitter', 'han_solo_official', 41, 41),
       ('People', 1, 'linkedin', 'han-solo-smuggler', 41, 41),
       ('People', 1, 'instagram', 'captain_solo', 41, 41),
       ('People', 2, 'twitter', 'luke_skywalker_jedi', 41, 41),
       ('People', 2, 'facebook', 'luke.skywalker.jedi', 41, 41),
       ('People', 2, 'instagram', 'jedi_luke', 41, 41),
       ('People', 3, 'twitter', 'leia_organa_senator', 41, 41),
       ('People', 3, 'linkedin', 'leia-organa', 41, 41),
       ('People', 3, 'facebook', 'princess.leia', 41, 41),
       ('People', 4, 'twitter', 'master_yoda', 41, 41),
       ('People', 4, 'linkedin', 'yoda-jedi-master', 41, 41),
       ('People', 4, 'tiktok', 'wise_yoda', 41, 41),
       ('People', 5, 'twitter', 'obi_wan_kenobi', 41, 41),
       ('People', 5, 'linkedin', 'obi-wan-kenobi', 41, 41),
       ('People', 5, 'instagram', 'ben_kenobi', 41, 41),
       ('People', 6, 'twitter', 'anakin_skywalker', 41, 41),
       ('People', 6, 'instagram', 'chosen_one_anakin', 41, 41),
       ('People', 7, 'twitter', 'darth_vader_sith', 41, 41),
       ('People', 7, 'linkedin', 'darth-vader', 41, 41),
       ('People', 7, 'tiktok', 'sith_lord_vader', 41, 41),
       ('People', 8, 'twitter', 'kylo_ren_sith', 41, 41),
       ('People', 8, 'instagram', 'dark_kylo', 41, 41),
       ('People', 9, 'twitter', 'rey_jedi', 41, 41),
       ('People', 9, 'instagram', 'rey.of.light', 41, 41),
       ('People', 9, 'tiktok', 'rey_skywalker', 41, 41),
       ('People', 10, 'twitter', 'fn2187_finn', 41, 41),
       ('People', 10, 'instagram', 'finn_rebellion', 41, 41),
       ('People', 11, 'twitter', 'poe_dameron_pilot', 41, 41),
       ('People', 11, 'instagram', 'black_leader_poe', 41, 41),
       ('Organizations', 1, 'twitter', 'rebellion_alliance', 41, 41),
       ('Organizations', 1, 'linkedin', 'rebellion-alliance', 41, 41),
       ('Organizations', 1, 'facebook', 'rebellion.alliance', 41, 41),
       ('Organizations', 2, 'twitter', 'jedi_order', 41, 41),
       ('Organizations', 2, 'linkedin', 'jedi-order', 41, 41),
       ('Organizations', 2, 'facebook', 'jedi.order', 41, 41),
       ('Organizations', 3, 'twitter', 'galactic_empire', 41, 41),
       ('Organizations', 3, 'linkedin', 'galactic-empire', 41, 41),
       ('Organizations', 3, 'instagram', 'galactic_empire', 41, 41),
       ('Organizations', 4, 'twitter', 'first_order', 41, 41),
       ('Organizations', 4, 'linkedin', 'first-order', 41, 41),
       ('Organizations', 4, 'instagram', 'first.order', 41, 41),
       ('Organizations', 5, 'twitter', 'resistance_alliance', 41, 41),
       ('Organizations', 5, 'linkedin', 'resistance-alliance', 41, 41),
       ('Organizations', 5, 'facebook', 'resistance.alliance', 41, 41),
       ('Organizations', 6, 'twitter', 'bikini_bottom_biz', 41, 41),
       ('Organizations', 6, 'linkedin', 'bikini-bottom-businesses', 41, 41),
       ('Organizations', 6, 'instagram', 'bikini_bottom_biz', 41, 41),
       ('Organizations', 7, 'twitter', 'dunder_mifflin_inc', 41, 41),
       ('Organizations', 7, 'linkedin', 'dunder-mifflin', 41, 41),
       ('Organizations', 7, 'facebook', 'dunder.mifflin', 41, 41);

INSERT INTO Campaigns (name, status, starts, ends, kind, audience, subject, message, created_by, updated_by)
VALUES ('Rebellion Recruitment Drive', 'live', '2024-09-01 08:00:00', '2024-09-15 23:59:59', 'email', 'organization=Rebellion', 'Join the Rebellion!', '<h1>Dear Rebel,</h1><p>The Rebellion needs you! Join us in the fight against the Empire.</p>', 41, 41),
       ('Summer Promotion', 'live', NULL, NULL, 'sms', 'VIP customers', 'Summer Promotion', 'Get 50% off all items!', 41, 41),
       ('Winter Sale', 'draft', NULL, NULL, 'email', 'all', 'Winter Sale 2024', '<p>Don\'t miss out on our Winter Sale!</p>', 41, 41);

INSERT INTO CampaignMessages (campaign_id, contact_id, social_id, sent_to, created_at, sent_at, opened_at, clicked_at)
VALUES (1, 1, NULL, 'han.solo@rebellion.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
       (1, 2, NULL, 'luke.skywalker@rebellion.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (1, 3, NULL, 'leia.organa@rebellion.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL, NULL),
       (2, 1, NULL, '+33-1-45-67-89-01', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL, NULL);

INSERT INTO Issues (subject, created_by, closed_at, closed_by)
VALUES ('Delayed Shipment of Krabby Patties', 102, '2024-08-05 10:00:00', 105),
       ('Rebellion Supply Shortage', 37, NULL, NULL),
       ('Jedi Training Materials Not Delivered', 41, NULL, NULL),
       ('Empire Recruitment Process Feedback', 43, '2024-08-10 16:30:00', 43),
       ('First Order Propaganda Issues', 44, NULL, NULL),
       ('Printer Issues in Scranton Office', 108, '2024-08-06 09:15:00', 108),
       ('Plankton Complaining About Chum Bucket Sales', 106, NULL, NULL);

INSERT INTO IssueMessages (issue_id, content, created_by, updated_by)
VALUES (1, 'Shipment of Krabby Patties was delayed by 3 days. Customers are getting impatient.', 102, 102),
       (1, 'I''ll look into it and make sure it gets sorted out.', 105, 105),
       (1, 'The issue has been resolved. The shipment is on its way.', 105, 105),
       (2, 'We are experiencing a shortage of supplies needed for the next mission.', 37, 37),
       (2, 'We need to secure a new supplier as soon as possible.', 39, 39),
       (3, 'The training materials for the new Jedi recruits haven''t arrived yet.', 41, 41),
       (3, 'We need these materials urgently for the next training session.', 38, 38),
       (4, 'The current recruitment process is too slow and needs to be streamlined.', 43, 43),
       (4, 'Implemented changes to speed up the process. Issue closed.', 43, 43),
       (5, 'The propaganda materials sent out last week were not well received.', 44, 44),
       (5, 'We need to revise our messaging to better align with our core values.', 44, 44),
       (6, 'The printer on the second floor is constantly jamming. It needs to be replaced.', 108, 108),
       (6, 'Ordered a new printer. It should arrive tomorrow.', 108, 108),
       (6, 'Printer issue resolved. New printer installed.', 108, 108),
       (7, 'Chum Bucket sales have been abysmal. We need a new marketing strategy.', 106, 106),
       (7, 'Perhaps we could focus on new product offerings or promotions.', 102, 102);

INSERT INTO IssueMessageReactions (message_id, kind, created_by)
VALUES (2, 'like', 102),
       (5, 'dislike', 37);

INSERT INTO Discounts (name, description, kind, value, enable_at, expire_at, created_by, updated_by)
VALUES ('New Year Discount', '10% off on all items', 'percentage', 10.00, '2024-01-01 00:00:00', '2024-01-31 23:59:59', 1, 1),
       ('Black Friday Deal', 'Flat $50 off', 'amount', 50.00, '2024-11-29 00:00:00', '2024-11-29 23:59:59', 2, 2);

INSERT INTO Coupons (discount_id, code, expire_at, created_by, updated_by)
VALUES (1, 'NY2024', '2024-01-31 23:59:59', 1, 1),
       (2, 'BF2024', '2024-11-29 23:59:59', 2, 2);
