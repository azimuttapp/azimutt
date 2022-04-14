CREATE TABLE `t_user` (
    `id` uuid NOT NULL PRIMARY KEY,
    `firstname` varchar(255) NOT NULL,
    `lastname` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `email` varchar(255) NOT NULL UNIQUE,
    `birthdate` date NOT NULL,
    `language` varchar(255) NOT NULL,
    `picture` text,
    `password` varchar(255) NOT NULL,
    `role` varchar(255) NOT NULL,
    `temperature_unit_preference` varchar(255) NOT NULL,
    `distance_unit_preference` varchar(255) NOT NULL,
    `telegram_user_id` varchar(255) UNIQUE,
    `last_latitude` double precision,
    `last_longitude` double precision,
    `last_altitude` double precision,
    `last_accuracy` double precision,
    `last_location_changed` DATETIME,
    `current_house_id` uuid REFERENCES `t_house` (`id`),
    `last_house_changed` DATETIME,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_user_role` ON `t_user` (`role`);

CREATE TABLE `t_location` (
    `id` uuid NOT NULL PRIMARY KEY,
    `user_id` uuid NOT NULL REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `latitude` double precision NOT NULL,
    `longitude` double precision NOT NULL,
    `altitude` double precision,
    `accuracy` double precision,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_location_user_id` ON `t_location` (`user_id`);

CREATE INDEX `t_location_created_at` ON `t_location` (`created_at`);

CREATE TABLE `t_house` (
    `id` uuid NOT NULL PRIMARY KEY,
    `name` varchar(255) NOT NULL UNIQUE,
    `selector` varchar(255) NOT NULL UNIQUE,
    `latitude` double precision,
    `longitude` double precision,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE TABLE `t_room` (
    `id` uuid NOT NULL PRIMARY KEY,
    `house_id` uuid NOT NULL REFERENCES `t_house` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL UNIQUE,
    `selector` varchar(255) NOT NULL UNIQUE,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_room_house_id` ON `t_room` (`house_id`);

CREATE TABLE `t_device` (
    `id` uuid NOT NULL PRIMARY KEY,
    `service_id` uuid NOT NULL REFERENCES `t_service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `room_id` uuid REFERENCES `t_room` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `model` varchar(255),
    `external_id` varchar(255) NOT NULL UNIQUE,
    `should_poll` TINYINT (1) NOT NULL DEFAULT 0,
    `poll_frequency` integer,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_device_service_id` ON `t_device` (`service_id`);

CREATE INDEX `t_device_room_id` ON `t_device` (`room_id`);

CREATE TABLE `t_device_feature` (
    `id` uuid NOT NULL PRIMARY KEY,
    `device_id` uuid NOT NULL REFERENCES `t_device` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `external_id` varchar(255) NOT NULL UNIQUE,
    `category` varchar(255) NOT NULL,
    `type` varchar(255) NOT NULL,
    `read_only` TINYINT (1) NOT NULL,
    `keep_history` TINYINT (1) NOT NULL DEFAULT 1,
    `has_feedback` TINYINT (1) NOT NULL,
    `unit` varchar(255),
    `min` double precision NOT NULL,
    `max` double precision NOT NULL,
    `last_value` double precision,
    `last_value_string` text,
    `last_value_changed` DATETIME,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `last_monthly_aggregate` DATETIME DEFAULT NULL,
    `last_daily_aggregate` DATETIME DEFAULT NULL,
    `last_hourly_aggregate` DATETIME DEFAULT NULL
);

CREATE INDEX `t_device_feature_device_id` ON `t_device_feature` (`device_id`);

CREATE INDEX `t_device_feature_category` ON `t_device_feature` (`category`);

CREATE TABLE `t_device_feature_state` (
    `id` uuid NOT NULL PRIMARY KEY,
    `device_feature_id` uuid NOT NULL REFERENCES `t_device_feature` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `value` double precision NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_device_feature_state_device_feature_id` ON `t_device_feature_state` (`device_feature_id`);

CREATE TABLE `t_calendar` (
    `id` uuid NOT NULL PRIMARY KEY,
    `user_id` uuid NOT NULL REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `service_id` uuid REFERENCES `t_service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `external_id` varchar(255) UNIQUE,
    `description` varchar(255) NOT NULL,
    `sync` TINYINT (1) NOT NULL DEFAULT 1,
    `notify` TINYINT (1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `ctag` varchar(255),
    `sync_token` varchar(255),
    `color` varchar(255),
    `shared` TINYINT (1) NOT NULL DEFAULT 0
);

CREATE INDEX `t_calendar_user_id` ON `t_calendar` (`user_id`);

CREATE INDEX `t_calendar_service_id` ON `t_calendar` (`service_id`);

CREATE TABLE `t_calendar_event` (
    `id` uuid NOT NULL PRIMARY KEY,
    `calendar_id` uuid NOT NULL REFERENCES `t_calendar` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `external_id` varchar(255) UNIQUE,
    `location` varchar(255),
    `start` DATETIME NOT NULL,
    `end` DATETIME,
    `full_day` TINYINT (1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `url` varchar(255)
);

CREATE INDEX `t_calendar_event_calendar_id` ON `t_calendar_event` (`calendar_id`);

CREATE INDEX `t_calendar_event_start` ON `t_calendar_event` (`start`);

CREATE INDEX `t_calendar_event_end` ON `t_calendar_event` (`end`);

CREATE TABLE `t_pod` (
    `id` uuid NOT NULL PRIMARY KEY,
    `room_id` uuid REFERENCES `t_room` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_pod_room_id` ON `t_pod` (`room_id`);

CREATE TABLE `t_service` (
    `id` uuid NOT NULL PRIMARY KEY,
    `pod_id` uuid REFERENCES `t_pod` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `version` varchar(255) NOT NULL,
    `enabled` TINYINT (1) NOT NULL DEFAULT 1,
    `has_message_feature` TINYINT (1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `status` text NOT NULL DEFAULT 'UNKNWON'
);

CREATE INDEX `t_service_pod_id` ON `t_service` (`pod_id`);

CREATE UNIQUE INDEX `t_service_pod_id_name` ON `t_service` (`pod_id`, `name`);

CREATE TABLE `t_variable` (
    `id` uuid NOT NULL PRIMARY KEY,
    `service_id` uuid REFERENCES `t_service` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `user_id` uuid REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `value` text NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_variable_service_id` ON `t_variable` (`service_id`);

CREATE UNIQUE INDEX `t_variable_service_id_user_id_name` ON `t_variable` (`service_id`, `user_id`, `name`);

CREATE TABLE `t_script` (
    `id` uuid NOT NULL PRIMARY KEY,
    `name` varchar(255) NOT NULL UNIQUE,
    `selector` varchar(255) NOT NULL UNIQUE,
    `code` text NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE TABLE `t_area` (
    `id` uuid NOT NULL PRIMARY KEY,
    `name` varchar(255) NOT NULL UNIQUE,
    `selector` varchar(255) NOT NULL UNIQUE,
    `latitude` double precision NOT NULL,
    `longitude` double precision NOT NULL,
    `radius` double precision NOT NULL,
    `color` varchar(255) NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE TABLE `t_dashboard` (
    `id` uuid NOT NULL PRIMARY KEY,
    `name` varchar(255) NOT NULL UNIQUE,
    `type` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `boxes` json NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `user_id` uuid REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE `t_scene` (
    `id` uuid NOT NULL PRIMARY KEY,
    `name` varchar(255) NOT NULL,
    `icon` varchar(255) NOT NULL,
    `selector` varchar(255) NOT NULL UNIQUE,
    `actions` json NOT NULL,
    `last_executed` DATETIME,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `triggers` json,
    `active` TINYINT (1) NOT NULL DEFAULT 1
);

CREATE TABLE `t_message` (
    `id` uuid NOT NULL PRIMARY KEY,
    `sender_id` uuid REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `receiver_id` uuid REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `text` text NOT NULL,
    `file` text,
    `conversation_id` uuid NOT NULL,
    `is_read` TINYINT (1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_message_sender_id` ON `t_message` (`sender_id`);

CREATE INDEX `t_message_receiver_id` ON `t_message` (`receiver_id`);

CREATE TABLE `t_session` (
    `id` uuid NOT NULL PRIMARY KEY,
    `user_id` uuid NOT NULL REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `token_type` varchar(255) NOT NULL,
    `token_hash` text NOT NULL,
    `scope` text NOT NULL,
    `valid_until` DATETIME,
    `last_seen` DATETIME,
    `revoked` TINYINT (1) NOT NULL DEFAULT 0,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    `useragent` text
);

CREATE INDEX `t_session_user_id` ON `t_session` (`user_id`);

CREATE TABLE `t_device_param` (
    `id` uuid NOT NULL PRIMARY KEY,
    `device_id` uuid NOT NULL REFERENCES `t_device` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `name` varchar(255) NOT NULL,
    `value` text NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_device_param_device_id` ON `t_device_param` (`device_id`);

CREATE UNIQUE INDEX `t_device_param_device_id_name` ON `t_device_param` (`device_id`, `name`);

CREATE TABLE `t_device_feature_state_aggregate` (
    `id` uuid NOT NULL PRIMARY KEY,
    `type` varchar(255) NOT NULL,
    `device_feature_id` uuid NOT NULL REFERENCES `t_device_feature` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    `value` double precision NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_device_feature_state_aggregate_type` ON `t_device_feature_state_aggregate` (`type`);

CREATE INDEX `t_device_feature_state_aggregate_device_feature_id` ON `t_device_feature_state_aggregate` (`device_feature_id`);

CREATE INDEX `t_device_feature_state_aggregate_created_at` ON `t_device_feature_state_aggregate` (`created_at`);

CREATE INDEX `t_device_feature_state_created_at` ON `t_device_feature_state` (`created_at`);

CREATE TABLE `t_job` (
    `id` uuid NOT NULL PRIMARY KEY,
    `type` varchar(255) NOT NULL,
    `status` varchar(255) NOT NULL,
    `progress` integer NOT NULL,
    `data` json NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL
);

CREATE INDEX `t_job_created_at` ON `t_job` (`created_at`);

CREATE INDEX `t_job_type` ON `t_job` (`type`);

