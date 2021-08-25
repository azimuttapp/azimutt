--
-- PostgreSQL database dump
--

-- Dumped from database version 11.12 (Ubuntu 11.12-1.pgdg16.04+1)
-- Dumped by pg_dump version 12.7 (Ubuntu 12.7-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: admin
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO admin;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: admin
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

--
-- Name: cfps; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.cfps (
    id character(36) NOT NULL,
    group_id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    name character varying(120) NOT NULL,
    begin timestamp without time zone,
    close timestamp without time zone,
    description character varying(4096) NOT NULL,
    tags character varying(150) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.cfps OWNER TO admin;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.comments (
    event_id character(36),
    proposal_id character(36),
    id character(36) NOT NULL,
    kind character varying(15) NOT NULL,
    answers character(36),
    text character varying(4096) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL
);


ALTER TABLE public.comments OWNER TO admin;

--
-- Name: contacts; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.contacts (
    id character(36) NOT NULL,
    partner_id character(36) NOT NULL,
    first_name character varying(120) NOT NULL,
    last_name character varying(120) NOT NULL,
    email character varying(120) NOT NULL,
    notes character varying(4096) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.contacts OWNER TO admin;

--
-- Name: credentials; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.credentials (
    provider_id character varying(30) NOT NULL,
    provider_key character varying(100) NOT NULL,
    hasher character varying(100) NOT NULL,
    password character varying(100) NOT NULL,
    salt character varying(100)
);


ALTER TABLE public.credentials OWNER TO admin;

--
-- Name: env; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.env (
    name character varying(10) NOT NULL
);


ALTER TABLE public.env OWNER TO admin;

--
-- Name: event_rsvps; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.event_rsvps (
    event_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    answer character varying(10) NOT NULL,
    answered_at timestamp without time zone NOT NULL
);


ALTER TABLE public.event_rsvps OWNER TO admin;

--
-- Name: events; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.events (
    id character(36) NOT NULL,
    group_id character(36) NOT NULL,
    cfp_id character(36),
    slug character varying(120) NOT NULL,
    name character varying(120) NOT NULL,
    start timestamp without time zone NOT NULL,
    max_attendee integer,
    allow_rsvp boolean NOT NULL,
    description character varying(4096) NOT NULL,
    orga_notes character varying(4096) NOT NULL,
    orga_notes_updated_at timestamp without time zone NOT NULL,
    orga_notes_updated_by character(36) NOT NULL,
    venue character(36),
    talks character varying(258) NOT NULL,
    tags character varying(150) NOT NULL,
    published timestamp without time zone,
    meetupgroup character varying(80),
    meetupevent bigint,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    kind character varying(12) DEFAULT 'Meetup'::character varying NOT NULL
);


ALTER TABLE public.events OWNER TO admin;

--
-- Name: external_cfps; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.external_cfps (
    id character(36) NOT NULL,
    description character varying(4096) NOT NULL,
    begin timestamp without time zone,
    close timestamp without time zone,
    url character varying(1024) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    event_id character(36) NOT NULL
);


ALTER TABLE public.external_cfps OWNER TO admin;

--
-- Name: external_events; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.external_events (
    id character(36) NOT NULL,
    name character varying(120) NOT NULL,
    logo character varying(1024),
    description character varying(4096) NOT NULL,
    start timestamp without time zone,
    finish timestamp without time zone,
    location character varying(4096),
    location_id character varying(150),
    location_lat double precision,
    location_lng double precision,
    location_locality character varying(50),
    location_country character varying(30),
    url character varying(1024),
    tickets_url character varying(1024),
    videos_url character varying(1024),
    twitter_account character varying(120),
    twitter_hashtag character varying(120),
    tags character varying(150) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    kind character varying(12) DEFAULT 'Conference'::character varying NOT NULL
);


ALTER TABLE public.external_events OWNER TO admin;

--
-- Name: external_proposals; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.external_proposals (
    id character(36) NOT NULL,
    talk_id character(36) NOT NULL,
    event_id character(36) NOT NULL,
    status character varying(10) NOT NULL,
    title character varying(120) NOT NULL,
    duration bigint NOT NULL,
    description character varying(4096) NOT NULL,
    message character varying(4096) NOT NULL,
    speakers character varying(184) NOT NULL,
    slides character varying(1024),
    video character varying(1024),
    tags character varying(150) NOT NULL,
    url character varying(1024),
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.external_proposals OWNER TO admin;

--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO admin;

--
-- Name: group_members; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.group_members (
    group_id character(36) NOT NULL,
    user_id character(36) NOT NULL,
    role character varying(10) NOT NULL,
    presentation character varying(4096),
    joined_at timestamp without time zone NOT NULL,
    leaved_at timestamp without time zone
);


ALTER TABLE public.group_members OWNER TO admin;

--
-- Name: group_settings; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.group_settings (
    group_id character(36) NOT NULL,
    meetup_access_token character varying(200),
    meetup_refresh_token character varying(200),
    meetup_group_slug character varying(120),
    meetup_logged_user_id bigint,
    meetup_logged_user_name character varying(120),
    slack_token character varying(200),
    slack_bot_name character varying(120),
    slack_bot_avatar character varying(1024),
    event_description character varying NOT NULL,
    event_templates character varying NOT NULL,
    actions character varying NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    proposal_tweet character varying DEFAULT 'Presentation of "{{proposal.title}}" by{{#proposal.speakers}}{{^-first}} and{{/-first}} {{#links.twitter}}{{handle}}{{/links.twitter}}{{^links.twitter}}{{name}}{{/links.twitter}}{{/proposal.speakers}}'::character varying NOT NULL
);


ALTER TABLE public.group_settings OWNER TO admin;

--
-- Name: groups; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.groups (
    id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    name character varying(120) NOT NULL,
    logo character varying(1024),
    banner character varying(1024),
    contact character varying(120),
    website character varying(1024),
    description character varying(4096) NOT NULL,
    location character varying(4096),
    location_lat double precision,
    location_lng double precision,
    location_locality character varying(50),
    location_country character varying(30),
    owners character varying(369) NOT NULL,
    social_facebook character varying(1024),
    social_instagram character varying(1024),
    social_twitter character varying(1024),
    social_linkedin character varying(1024),
    social_youtube character varying(1024),
    social_meetup character varying(1024),
    social_eventbrite character varying(1024),
    social_slack character varying(1024),
    social_discord character varying(1024),
    social_github character varying(1024),
    tags character varying(150) NOT NULL,
    status character varying(10) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    location_id character varying(150)
);


ALTER TABLE public.groups OWNER TO admin;

--
-- Name: logins; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.logins (
    provider_id character varying(30) NOT NULL,
    provider_key character varying(100) NOT NULL,
    user_id character(36) NOT NULL
);


ALTER TABLE public.logins OWNER TO admin;

--
-- Name: partners; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.partners (
    id character(36) NOT NULL,
    group_id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    name character varying(120) NOT NULL,
    notes character varying(4096) NOT NULL,
    description character varying(4096),
    logo character varying(1024) NOT NULL,
    social_facebook character varying(1024),
    social_instagram character varying(1024),
    social_twitter character varying(1024),
    social_linkedin character varying(1024),
    social_youtube character varying(1024),
    social_meetup character varying(1024),
    social_eventbrite character varying(1024),
    social_slack character varying(1024),
    social_discord character varying(1024),
    social_github character varying(1024),
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.partners OWNER TO admin;

--
-- Name: proposal_ratings; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.proposal_ratings (
    proposal_id character(36) NOT NULL,
    grade integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL
);


ALTER TABLE public.proposal_ratings OWNER TO admin;

--
-- Name: proposals; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.proposals (
    id character(36) NOT NULL,
    talk_id character(36) NOT NULL,
    cfp_id character(36) NOT NULL,
    event_id character(36),
    status character varying(10) NOT NULL,
    title character varying(120) NOT NULL,
    duration bigint NOT NULL,
    description character varying(4096) NOT NULL,
    speakers character varying(184) NOT NULL,
    slides character varying(1024),
    video character varying(1024),
    tags character varying(150) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    orga_tags character varying(150) DEFAULT ''::character varying NOT NULL,
    message character varying(4096) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.proposals OWNER TO admin;

--
-- Name: sponsor_packs; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.sponsor_packs (
    id character(36) NOT NULL,
    group_id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    name character varying(120) NOT NULL,
    description character varying(4096) NOT NULL,
    price double precision NOT NULL,
    currency character varying(10) NOT NULL,
    duration character varying(20) NOT NULL,
    active boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.sponsor_packs OWNER TO admin;

--
-- Name: sponsors; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.sponsors (
    id character(36) NOT NULL,
    group_id character(36) NOT NULL,
    partner_id character(36) NOT NULL,
    sponsor_pack_id character(36) NOT NULL,
    contact_id character(36),
    start date NOT NULL,
    finish date NOT NULL,
    paid date,
    price double precision NOT NULL,
    currency character varying(10) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL
);


ALTER TABLE public.sponsors OWNER TO admin;

--
-- Name: talks; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.talks (
    id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    status character varying(10) NOT NULL,
    title character varying(120) NOT NULL,
    duration bigint NOT NULL,
    description character varying(4096) NOT NULL,
    speakers character varying(184) NOT NULL,
    slides character varying(1024),
    video character varying(1024),
    tags character varying(150) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    message character varying(4096) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.talks OWNER TO admin;

--
-- Name: user_requests; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.user_requests (
    id character(36) NOT NULL,
    kind character varying(30) NOT NULL,
    group_id character(36),
    cfp_id character(36),
    event_id character(36),
    talk_id character(36),
    proposal_id character(36),
    email character varying(120),
    payload character varying(8192),
    deadline timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character(36),
    accepted_at timestamp without time zone,
    accepted_by character(36),
    rejected_at timestamp without time zone,
    rejected_by character(36),
    canceled_at timestamp without time zone,
    canceled_by character(36),
    external_event_id character(36),
    external_cfp_id character(36),
    external_proposal_id character(36)
);


ALTER TABLE public.user_requests OWNER TO admin;

--
-- Name: users; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.users (
    id character(36) NOT NULL,
    slug character varying(120) NOT NULL,
    status character varying(10) NOT NULL,
    first_name character varying(120) NOT NULL,
    last_name character varying(120) NOT NULL,
    email character varying(120) NOT NULL,
    email_validated timestamp without time zone,
    email_validation_before_login boolean NOT NULL,
    avatar character varying(1024) NOT NULL,
    bio character varying(4096),
    company character varying(36),
    location character varying(36),
    phone character varying(36),
    website character varying(1024),
    social_facebook character varying(1024),
    social_instagram character varying(1024),
    social_twitter character varying(1024),
    social_linkedin character varying(1024),
    social_youtube character varying(1024),
    social_meetup character varying(1024),
    social_eventbrite character varying(1024),
    social_slack character varying(1024),
    social_discord character varying(1024),
    social_github character varying(1024),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying(1024),
    mentoring character varying(4096)
);


ALTER TABLE public.users OWNER TO admin;

--
-- Name: venues; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.venues (
    id character(36) NOT NULL,
    partner_id character(36) NOT NULL,
    contact_id character(36),
    address character varying(4096) NOT NULL,
    address_lat double precision NOT NULL,
    address_lng double precision NOT NULL,
    address_country character varying(30) NOT NULL,
    notes character varying(4096) NOT NULL,
    room_size integer,
    meetupgroup character varying(80),
    meetupvenue bigint,
    created_at timestamp without time zone NOT NULL,
    created_by character(36) NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character(36) NOT NULL,
    address_id character varying(150) DEFAULT ''::character varying NOT NULL,
    address_locality character varying(150)
);


ALTER TABLE public.venues OWNER TO admin;

--
-- Name: video_sources; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.video_sources (
    video_id character varying(15) NOT NULL,
    talk_id character(36),
    proposal_id character(36),
    external_proposal_id character(36),
    external_event_id character(36)
);


ALTER TABLE public.video_sources OWNER TO admin;

--
-- Name: videos; Type: TABLE; Schema: public; Owner: admin
--

CREATE TABLE public.videos (
    platform character varying(10) NOT NULL,
    url character varying(1024) NOT NULL,
    id character varying(15) NOT NULL,
    channel_id character varying(30) NOT NULL,
    channel_name character varying(120) NOT NULL,
    playlist_id character varying(40),
    playlist_name character varying(120),
    title character varying(120) NOT NULL,
    description character varying(4096) NOT NULL,
    tags character varying(150) NOT NULL,
    published_at timestamp without time zone NOT NULL,
    duration bigint NOT NULL,
    lang character varying(2) NOT NULL,
    views bigint NOT NULL,
    likes bigint NOT NULL,
    dislikes bigint NOT NULL,
    comments bigint NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.videos OWNER TO admin;

--
-- Name: cfps cfps_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cfps
    ADD CONSTRAINT cfps_pkey PRIMARY KEY (id);


--
-- Name: cfps cfps_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cfps
    ADD CONSTRAINT cfps_slug_key UNIQUE (slug);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (provider_id, provider_key);


--
-- Name: env env_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.env
    ADD CONSTRAINT env_pkey PRIMARY KEY (name);


--
-- Name: event_rsvps event_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_pkey PRIMARY KEY (event_id, user_id);


--
-- Name: events events_group_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_group_id_slug_key UNIQUE (group_id, slug);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: external_cfps external_cfps_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_cfps
    ADD CONSTRAINT external_cfps_pkey PRIMARY KEY (id);


--
-- Name: external_events external_events_name_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_events
    ADD CONSTRAINT external_events_name_key UNIQUE (name);


--
-- Name: external_events external_events_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_events
    ADD CONSTRAINT external_events_pkey PRIMARY KEY (id);


--
-- Name: external_proposals external_proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_pkey PRIMARY KEY (id);


--
-- Name: external_proposals external_proposals_talk_id_event_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_talk_id_event_id_key UNIQUE (talk_id, event_id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (group_id, user_id);


--
-- Name: group_settings group_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_settings
    ADD CONSTRAINT group_settings_pkey PRIMARY KEY (group_id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: groups groups_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_slug_key UNIQUE (slug);


--
-- Name: logins logins_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logins
    ADD CONSTRAINT logins_pkey PRIMARY KEY (provider_id, provider_key);


--
-- Name: partners partners_group_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_group_id_slug_key UNIQUE (group_id, slug);


--
-- Name: partners partners_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_pkey PRIMARY KEY (id);


--
-- Name: proposal_ratings proposal_ratings_proposal_id_created_by_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposal_ratings
    ADD CONSTRAINT proposal_ratings_proposal_id_created_by_key UNIQUE (proposal_id, created_by);


--
-- Name: proposals proposals_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_pkey PRIMARY KEY (id);


--
-- Name: proposals proposals_talk_id_cfp_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_talk_id_cfp_id_key UNIQUE (talk_id, cfp_id);


--
-- Name: sponsor_packs sponsor_packs_group_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsor_packs
    ADD CONSTRAINT sponsor_packs_group_id_slug_key UNIQUE (group_id, slug);


--
-- Name: sponsor_packs sponsor_packs_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsor_packs
    ADD CONSTRAINT sponsor_packs_pkey PRIMARY KEY (id);


--
-- Name: sponsors sponsors_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_pkey PRIMARY KEY (id);


--
-- Name: talks talks_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.talks
    ADD CONSTRAINT talks_pkey PRIMARY KEY (id);


--
-- Name: talks talks_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.talks
    ADD CONSTRAINT talks_slug_key UNIQUE (slug);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_slug_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_slug_key UNIQUE (slug);


--
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (id);


--
-- Name: video_sources video_sources_video_id_external_event_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_video_id_external_event_id_key UNIQUE (video_id, external_event_id);


--
-- Name: video_sources video_sources_video_id_external_proposal_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_video_id_external_proposal_id_key UNIQUE (video_id, external_proposal_id);


--
-- Name: video_sources video_sources_video_id_proposal_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_video_id_proposal_id_key UNIQUE (video_id, proposal_id);


--
-- Name: video_sources video_sources_video_id_talk_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_video_id_talk_id_key UNIQUE (video_id, talk_id);


--
-- Name: videos videos_id_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_id_key UNIQUE (id);


--
-- Name: videos videos_url_key; Type: CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_url_key UNIQUE (url);


--
-- Name: comments_event_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX comments_event_idx ON public.comments USING btree (event_id);


--
-- Name: comments_proposal_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX comments_proposal_idx ON public.comments USING btree (proposal_id);


--
-- Name: external_cfps_close_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_cfps_close_idx ON public.external_cfps USING btree (close);


--
-- Name: external_events_location_lat_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_events_location_lat_idx ON public.external_events USING btree (location_lat);


--
-- Name: external_events_location_lng_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_events_location_lng_idx ON public.external_events USING btree (location_lng);


--
-- Name: external_events_start_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_events_start_idx ON public.external_events USING btree (start);


--
-- Name: external_proposals_event_id_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_proposals_event_id_idx ON public.external_proposals USING btree (event_id);


--
-- Name: external_proposals_status_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_proposals_status_idx ON public.external_proposals USING btree (status);


--
-- Name: external_proposals_talk_id_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX external_proposals_talk_id_idx ON public.external_proposals USING btree (talk_id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: proposals_status_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX proposals_status_idx ON public.proposals USING btree (status);


--
-- Name: talks_status_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX talks_status_idx ON public.talks USING btree (status);


--
-- Name: videos_channel_id_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_channel_id_idx ON public.videos USING btree (channel_id);


--
-- Name: videos_channel_name_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_channel_name_idx ON public.videos USING btree (channel_name);


--
-- Name: videos_id_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_id_idx ON public.videos USING btree (id);


--
-- Name: videos_playlist_id_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_playlist_id_idx ON public.videos USING btree (playlist_id);


--
-- Name: videos_playlist_name_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_playlist_name_idx ON public.videos USING btree (playlist_name);


--
-- Name: videos_title_idx; Type: INDEX; Schema: public; Owner: admin
--

CREATE INDEX videos_title_idx ON public.videos USING btree (title);


--
-- Name: cfps cfps_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cfps
    ADD CONSTRAINT cfps_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: cfps cfps_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cfps
    ADD CONSTRAINT cfps_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: cfps cfps_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.cfps
    ADD CONSTRAINT cfps_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: comments comments_answers_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_answers_fkey FOREIGN KEY (answers) REFERENCES public.comments(id);


--
-- Name: comments comments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: comments comments_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: comments comments_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: contacts contacts_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: contacts contacts_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partners(id);


--
-- Name: contacts contacts_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: event_rsvps event_rsvps_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: event_rsvps event_rsvps_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: events events_cfp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_cfp_id_fkey FOREIGN KEY (cfp_id) REFERENCES public.cfps(id);


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: events events_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: events events_orga_notes_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_orga_notes_updated_by_fkey FOREIGN KEY (orga_notes_updated_by) REFERENCES public.users(id);


--
-- Name: events events_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: events events_venue_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_venue_fkey FOREIGN KEY (venue) REFERENCES public.venues(id);


--
-- Name: external_cfps external_cfps_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_cfps
    ADD CONSTRAINT external_cfps_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: external_cfps external_cfps_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_cfps
    ADD CONSTRAINT external_cfps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.external_events(id);


--
-- Name: external_cfps external_cfps_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_cfps
    ADD CONSTRAINT external_cfps_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: external_events external_events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_events
    ADD CONSTRAINT external_events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: external_events external_events_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_events
    ADD CONSTRAINT external_events_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: external_proposals external_proposals_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: external_proposals external_proposals_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.external_events(id);


--
-- Name: external_proposals external_proposals_talk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_talk_id_fkey FOREIGN KEY (talk_id) REFERENCES public.talks(id);


--
-- Name: external_proposals external_proposals_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.external_proposals
    ADD CONSTRAINT external_proposals_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: group_members group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_members group_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: group_settings group_settings_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_settings
    ADD CONSTRAINT group_settings_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_settings group_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.group_settings
    ADD CONSTRAINT group_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: groups groups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: groups groups_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: logins logins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.logins
    ADD CONSTRAINT logins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: partners partners_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: partners partners_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: partners partners_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: proposal_ratings proposal_ratings_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposal_ratings
    ADD CONSTRAINT proposal_ratings_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: proposal_ratings proposal_ratings_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposal_ratings
    ADD CONSTRAINT proposal_ratings_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: proposals proposals_cfp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_cfp_id_fkey FOREIGN KEY (cfp_id) REFERENCES public.cfps(id);


--
-- Name: proposals proposals_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: proposals proposals_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: proposals proposals_talk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_talk_id_fkey FOREIGN KEY (talk_id) REFERENCES public.talks(id);


--
-- Name: proposals proposals_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.proposals
    ADD CONSTRAINT proposals_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: sponsor_packs sponsor_packs_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsor_packs
    ADD CONSTRAINT sponsor_packs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: sponsor_packs sponsor_packs_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsor_packs
    ADD CONSTRAINT sponsor_packs_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: sponsor_packs sponsor_packs_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsor_packs
    ADD CONSTRAINT sponsor_packs_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: sponsors sponsors_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id);


--
-- Name: sponsors sponsors_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: sponsors sponsors_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: sponsors sponsors_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partners(id);


--
-- Name: sponsors sponsors_sponsor_pack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_sponsor_pack_id_fkey FOREIGN KEY (sponsor_pack_id) REFERENCES public.sponsor_packs(id);


--
-- Name: sponsors sponsors_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.sponsors
    ADD CONSTRAINT sponsors_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: talks talks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.talks
    ADD CONSTRAINT talks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: talks talks_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.talks
    ADD CONSTRAINT talks_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: user_requests user_requests_accepted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_accepted_by_fkey FOREIGN KEY (accepted_by) REFERENCES public.users(id);


--
-- Name: user_requests user_requests_canceled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_canceled_by_fkey FOREIGN KEY (canceled_by) REFERENCES public.users(id);


--
-- Name: user_requests user_requests_cfp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_cfp_id_fkey FOREIGN KEY (cfp_id) REFERENCES public.cfps(id);


--
-- Name: user_requests user_requests_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: user_requests user_requests_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: user_requests user_requests_external_cfp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_external_cfp_id_fkey FOREIGN KEY (external_cfp_id) REFERENCES public.external_cfps(id);


--
-- Name: user_requests user_requests_external_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_external_event_id_fkey FOREIGN KEY (external_event_id) REFERENCES public.external_events(id);


--
-- Name: user_requests user_requests_external_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_external_proposal_id_fkey FOREIGN KEY (external_proposal_id) REFERENCES public.external_proposals(id);


--
-- Name: user_requests user_requests_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: user_requests user_requests_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: user_requests user_requests_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.users(id);


--
-- Name: user_requests user_requests_talk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.user_requests
    ADD CONSTRAINT user_requests_talk_id_fkey FOREIGN KEY (talk_id) REFERENCES public.talks(id);


--
-- Name: venues venues_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id);


--
-- Name: venues venues_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: venues venues_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partners(id);


--
-- Name: venues venues_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.venues
    ADD CONSTRAINT venues_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: video_sources video_sources_external_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_external_event_id_fkey FOREIGN KEY (external_event_id) REFERENCES public.external_events(id);


--
-- Name: video_sources video_sources_external_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_external_proposal_id_fkey FOREIGN KEY (external_proposal_id) REFERENCES public.external_proposals(id);


--
-- Name: video_sources video_sources_proposal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_proposal_id_fkey FOREIGN KEY (proposal_id) REFERENCES public.proposals(id);


--
-- Name: video_sources video_sources_talk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_talk_id_fkey FOREIGN KEY (talk_id) REFERENCES public.talks(id);


--
-- Name: video_sources video_sources_video_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admin
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.videos(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: admin
--

REVOKE ALL ON SCHEMA public FROM postgres;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO admin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: LANGUAGE plpgsql; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON LANGUAGE plpgsql TO admin;


--
-- PostgreSQL database dump complete
--

