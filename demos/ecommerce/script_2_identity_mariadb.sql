-- drop everything
DROP DATABASE IF EXISTS identity;

-- create the database (needs admin rights)
CREATE DATABASE identity;
USE identity;


CREATE TABLE identity.Users
(
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(255) NOT NULL,
    last_name  VARCHAR(255) NOT NULL,
    username   VARCHAR(255) NOT NULL UNIQUE,
    email      VARCHAR(255) NOT NULL UNIQUE,
    settings   JSON CHECK (JSON_VALID(settings)),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    INDEX idx_name (first_name, last_name),
    INDEX idx_deleted_at (deleted_at)
);

CREATE TABLE identity.Credentials
(
    user_id       BIGINT                                                         NOT NULL,
    provider      ENUM ('password', 'google', 'linkedin', 'facebook', 'twitter') NOT NULL,
    provider_id   VARCHAR(255)                                                   NOT NULL,
    provider_data JSON CHECK (JSON_VALID(provider_data)),
    used_last     TIMESTAMP,
    used_count    INT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, provider, provider_id),
    FOREIGN KEY (user_id) REFERENCES identity.Users (id)
);

CREATE TABLE identity.PasswordResets
(
    id           BIGINT PRIMARY KEY AUTO_INCREMENT,
    email        VARCHAR(255) NOT NULL,
    token        VARCHAR(255) NOT NULL,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expire_at    TIMESTAMP,
    used_at      TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_token (token)
);

CREATE TABLE identity.Devices
(
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    sid        CHAR(36)     NOT NULL UNIQUE,
    user_agent VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE identity.UserDevices
(
    user_id     BIGINT NOT NULL,
    device_id   BIGINT NOT NULL,
    linked_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unlinked_at TIMESTAMP,
    PRIMARY KEY (user_id, device_id),
    FOREIGN KEY (user_id) REFERENCES identity.Users (id),
    FOREIGN KEY (device_id) REFERENCES identity.Devices (id)
);

CREATE TABLE identity.AuthLogs
(
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT,
    email       VARCHAR(255),
    event       ENUM ('signup', 'login_success', 'login_failure', 'password_reset_asked', 'password_reset_used') NOT NULL,
    ip          VARCHAR(45)                                                                                      NOT NULL,
    ip_location POINT,
    user_agent  VARCHAR(255)                                                                                     NOT NULL,
    device_id   BIGINT                                                                                           NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES identity.Users (id),
    FOREIGN KEY (device_id) REFERENCES identity.Devices (id)
);

CREATE TABLE identity.TrustedDevices
(
    user_id    BIGINT NOT NULL,
    device_id  BIGINT NOT NULL,
    name       VARCHAR(255),
    kind       ENUM ('desktop', 'tablet', 'phone'),
    `usage`    ENUM ('perso', 'pro'),
    used_last  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    PRIMARY KEY (user_id, device_id),
    FOREIGN KEY (user_id) REFERENCES identity.Users (id),
    FOREIGN KEY (device_id) REFERENCES identity.Devices (id),
    INDEX idx_deleted_at (deleted_at)
);


-- insert some data
INSERT INTO identity.Users (first_name, last_name, username, email, settings)
VALUES ('Loïc', 'Knuchel', 'loicknuchel', 'loic@azimutt.app', '{"theme": "dark", "language": "fr"}'),
       ('John', 'Doe', 'johndoe', 'john.doe@example.com', '{"theme": "dark", "language": "en"}'),
       ('Jane', 'Smith', 'janesmith', 'jane.smith@example.com', '{"theme": "light", "language": "fr"}'),
       ('Alice', 'Brown', 'alicebrown', 'alice.brown@example.com', '{"theme": "dark", "language": "es"}'),
       ('Bob', 'Davis', 'bobdavis', 'bob.davis@example.com', '{"theme": "light", "language": "de"}');

INSERT INTO identity.Credentials (user_id, provider, provider_id, provider_data, used_last, used_count)
VALUES (1, 'twitter', 'loicknuchel', '{"refresh_token": "xxx"}', CURRENT_TIMESTAMP, 42),
       (2, 'password', 'hashed_password_1', NULL, CURRENT_TIMESTAMP, 10),
       (3, 'password', 'hashed_password_2', NULL, CURRENT_TIMESTAMP, 5),
       (4, 'google', 'superalice', '{"refresh_token": "refresh_token_3"}', CURRENT_TIMESTAMP, 15),
       (5, 'facebook', 'bobisking', '{"access_token": "access_token_4"}', CURRENT_TIMESTAMP, 20);

INSERT INTO identity.PasswordResets (email, token, requested_at, expire_at)
VALUES ('loic@azimutt.app', 'token_1', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 HOUR)),
       ('jane.smith@example.com', 'token_2', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 HOUR));

INSERT INTO identity.Devices (sid, user_agent)
VALUES (UUID(), 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'),
       (UUID(), 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15'),
       (UUID(), 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1'),
       (UUID(), 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36'),
       (UUID(), 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15');

INSERT INTO identity.UserDevices (user_id, device_id, linked_at)
VALUES (1, 1, CURRENT_TIMESTAMP),
       (2, 2, CURRENT_TIMESTAMP),
       (3, 3, CURRENT_TIMESTAMP),
       (4, 4, CURRENT_TIMESTAMP),
       (5, 5, CURRENT_TIMESTAMP);

INSERT INTO identity.AuthLogs (user_id, email, event, ip, ip_location, user_agent, device_id)
VALUES (1, 'loic@azimutt.app', 'login_success', '192.168.1.1', ST_GeomFromText('POINT(48.8588443 2.2943506)'), 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36', 1),
       (2, 'john.doe@example.com', 'login_success', '192.168.1.1', ST_GeomFromText('POINT(48.8588443 2.2943506)'), 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36', 1),
       (3, 'jane.smith@example.com', 'login_failure', '192.168.1.2', ST_GeomFromText('POINT(51.507351 -0.127758)'), 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15', 2),
       (4, 'alice.brown@example.com', 'password_reset_asked', '192.168.1.3', ST_GeomFromText('POINT(40.712776 -74.005974)'), 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1', 3),
       (5, 'bob.davis@example.com', 'signup', '192.168.1.4', ST_GeomFromText('POINT(34.052235 -118.243683)'), 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Mobile Safari/537.36', 4);

INSERT INTO identity.TrustedDevices (user_id, device_id, name, kind, `usage`, used_last, created_at)
VALUES (1, 1, 'Dell perso', 'desktop', 'perso', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (2, 2, 'John\'s Laptop', 'desktop', 'perso', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (3, 3, 'Jane\'s MacBook', 'desktop', 'pro', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (4, 4, 'Alice\'s iPhone', 'phone', 'perso', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
       (5, 5, 'Bob\'s Pixel', 'phone', 'pro', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
