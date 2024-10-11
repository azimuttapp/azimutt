--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)
-- Dumped by pg_dump version 16.4 (Ubuntu 16.4-0ubuntu0.24.04.2)

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
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'Main schema';


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: bug_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.bug_status AS ENUM (
    'new',
    'open',
    'closed'
);


--
-- Name: layout_position; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.layout_position AS (
	x integer,
	y integer
);


--
-- Name: post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_status AS ENUM (
    'draft',
    'published',
    'archived'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clever_cloud_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clever_cloud_resources (
    id uuid NOT NULL,
    addon_id character varying(255) NOT NULL,
    owner_id character varying(255) NOT NULL,
    owner_name character varying(255) NOT NULL,
    user_id character varying(255) NOT NULL,
    plan character varying(255) NOT NULL,
    region character varying(255) NOT NULL,
    callback_url character varying(255) NOT NULL,
    logplex_token character varying(255) NOT NULL,
    options jsonb,
    organization_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    data jsonb,
    details jsonb,
    created_by uuid,
    created_at timestamp without time zone NOT NULL,
    organization_id uuid,
    project_id uuid
);


--
-- Name: COLUMN events.data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.events.data IS 'event entity data';


--
-- Name: COLUMN events.details; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.events.details IS 'when additional data are needed';


--
-- Name: COLUMN events.project_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.events.project_id IS 'no FK to keep records when projects are deleted';


--
-- Name: gallery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gallery (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    slug character varying(255) NOT NULL,
    icon character varying(255) NOT NULL,
    color character varying(255) NOT NULL,
    website character varying(255) NOT NULL,
    banner character varying(255) NOT NULL,
    tips text NOT NULL,
    description text NOT NULL,
    analysis text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: COLUMN gallery.website; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gallery.website IS 'link for the website of the schema';


--
-- Name: COLUMN gallery.banner; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gallery.banner IS 'banner image, 1600x900';


--
-- Name: COLUMN gallery.tips; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gallery.tips IS 'shown on project creation';


--
-- Name: COLUMN gallery.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gallery.description IS 'shown on list and detail view';


--
-- Name: COLUMN gallery.analysis; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.gallery.analysis IS 'markdown shown on detail view';


--
-- Name: heroku_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.heroku_resources (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    app character varying(255),
    plan character varying(255) NOT NULL,
    region character varying(255) NOT NULL,
    options jsonb,
    callback character varying(255) NOT NULL,
    oauth_code uuid NOT NULL,
    oauth_type character varying(255) NOT NULL,
    oauth_expire timestamp without time zone NOT NULL,
    organization_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: organization_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_invitations (
    id uuid NOT NULL,
    sent_to character varying(255) NOT NULL,
    organization_id uuid NOT NULL,
    expire_at timestamp without time zone NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    cancel_at timestamp without time zone,
    answered_by uuid,
    refused_at timestamp without time zone,
    accepted_at timestamp without time zone,
    role character varying(255)
);


--
-- Name: COLUMN organization_invitations.sent_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organization_invitations.sent_to IS 'email to send the invitation';


--
-- Name: organization_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_members (
    user_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    created_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying(255) DEFAULT 'owner'::character varying NOT NULL
);


--
-- Name: COLUMN organization_members.role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organization_members.role IS 'values: owner, writer, reader';


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid NOT NULL,
    slug character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    logo character varying(255) NOT NULL,
    description text,
    github_username character varying(255),
    twitter_username character varying(255),
    stripe_customer_id character varying(255),
    is_personal boolean NOT NULL,
    created_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_by uuid,
    deleted_at timestamp without time zone,
    data jsonb,
    plan character varying(255),
    plan_freq character varying(255),
    plan_status character varying(255),
    plan_seats integer,
    plan_validated timestamp without time zone,
    free_trial_used timestamp without time zone,
    gateway character varying(255)
);


--
-- Name: COLUMN organizations.is_personal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.is_personal IS 'mimic user accounts when true';


--
-- Name: COLUMN organizations.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.deleted_at IS 'orga is cleared on deletion but kept for FKs';


--
-- Name: COLUMN organizations.data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.data IS 'unstructured props for orgas';


--
-- Name: COLUMN organizations.plan; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.plan IS 'organization pricing plan, ex: free, solo, team... If null, it has to be computed and stored';


--
-- Name: COLUMN organizations.plan_freq; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.plan_freq IS 'subscription period, ex: monthly, yearly. If null, it has to be computed and stored';


--
-- Name: COLUMN organizations.plan_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.plan_status IS 'stripe status or ''manual'' to disable the sync with stripe';


--
-- Name: COLUMN organizations.plan_validated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.plan_validated IS 'the last time the plan was computed and stored';


--
-- Name: COLUMN organizations.free_trial_used; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.free_trial_used IS 'when the free trial was used, null otherwise';


--
-- Name: COLUMN organizations.gateway; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.organizations.gateway IS 'custom gateway for the organization';


--
-- Name: project_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_tokens (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    nb_access integer NOT NULL,
    last_access timestamp without time zone,
    expire_at timestamp without time zone,
    revoked_at timestamp without time zone,
    revoked_by uuid,
    created_at timestamp without time zone NOT NULL,
    created_by uuid NOT NULL
);


--
-- Name: TABLE project_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.project_tokens IS 'grant access to projects';


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid NOT NULL,
    organization_id uuid NOT NULL,
    slug public.citext NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    encoding_version integer NOT NULL,
    storage_kind character varying(255) NOT NULL,
    file character varying(255),
    local_owner uuid,
    nb_sources integer NOT NULL,
    nb_tables integer NOT NULL,
    nb_columns integer NOT NULL,
    nb_relations integer NOT NULL,
    nb_types integer NOT NULL,
    nb_comments integer NOT NULL,
    nb_notes integer NOT NULL,
    nb_layouts integer NOT NULL,
    created_by uuid NOT NULL,
    updated_by uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    archived_by uuid,
    archived_at timestamp without time zone,
    visibility character varying(255) DEFAULT 'none'::character varying NOT NULL,
    nb_memos integer DEFAULT 0 NOT NULL
);


--
-- Name: COLUMN projects.encoding_version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.encoding_version IS 'encoding version for the project';


--
-- Name: COLUMN projects.storage_kind; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.storage_kind IS 'enum: local, remote';


--
-- Name: COLUMN projects.file; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.file IS 'stored file reference for remote projects';


--
-- Name: COLUMN projects.local_owner; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.local_owner IS 'user owning a local project';


--
-- Name: COLUMN projects.nb_types; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.nb_types IS 'number of SQL custom types in the project';


--
-- Name: COLUMN projects.nb_comments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.nb_comments IS 'number of SQL comments in the project';


--
-- Name: COLUMN projects.visibility; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.visibility IS 'enum: none, read, write';


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: user_auth_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_auth_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    nb_access integer NOT NULL,
    last_access timestamp without time zone,
    expire_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_profiles (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    usecase character varying(255),
    usage character varying(255),
    role character varying(255),
    location character varying(255),
    description text,
    company character varying(255),
    company_size integer,
    team_organization_id uuid,
    plan character varying(255),
    discovered_by character varying(255),
    previously_tried character varying(255)[],
    product_updates boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    phone character varying(255),
    industry character varying(255)
);


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    created_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE user_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_tokens IS 'needed for login/pass auth';


--
-- Name: COLUMN user_tokens.sent_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_tokens.sent_to IS 'email';


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    slug public.citext NOT NULL,
    name character varying(255) NOT NULL,
    email public.citext NOT NULL,
    provider character varying(255),
    provider_uid character varying(255),
    avatar character varying(255) NOT NULL,
    github_username character varying(255),
    twitter_username character varying(255),
    is_admin boolean NOT NULL,
    hashed_password character varying(255),
    last_signin timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    confirmed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    data jsonb,
    onboarding character varying(255),
    provider_data jsonb
);


--
-- Name: COLUMN users.slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.slug IS 'friendly id to show on url';


--
-- Name: COLUMN users.hashed_password; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.hashed_password IS 'present only if user used login/pass auth';


--
-- Name: COLUMN users.confirmed_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.confirmed_at IS 'on email confirm or directly for sso';


--
-- Name: COLUMN users.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.deleted_at IS 'user is cleared on deletion but kept for FKs';


--
-- Name: COLUMN users.data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.data IS 'unstructured props for user';


--
-- Name: COLUMN users.onboarding; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.onboarding IS 'current onboarding step when not finished';


--
-- Name: COLUMN users.provider_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.provider_data IS 'connection object from provider';


--
-- Name: clever_cloud_resources clever_cloud_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clever_cloud_resources
    ADD CONSTRAINT clever_cloud_resources_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: gallery gallery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gallery
    ADD CONSTRAINT gallery_pkey PRIMARY KEY (id);


--
-- Name: heroku_resources heroku_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.heroku_resources
    ADD CONSTRAINT heroku_resources_pkey PRIMARY KEY (id);


--
-- Name: organization_invitations organization_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_invitations
    ADD CONSTRAINT organization_invitations_pkey PRIMARY KEY (id);


--
-- Name: organization_members organization_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_pkey PRIMARY KEY (user_id, organization_id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: project_tokens project_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_tokens
    ADD CONSTRAINT project_tokens_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: CONSTRAINT schema_migrations_pkey ON schema_migrations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT schema_migrations_pkey ON public.schema_migrations IS 'HELLO!';


--
-- Name: user_auth_tokens user_auth_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_auth_tokens
    ADD CONSTRAINT user_auth_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: events_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_created_at_index ON public.events USING btree (created_at);


--
-- Name: INDEX events_created_at_index; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.events_created_at_index IS 'Easy access of events by date';


--
-- Name: events_created_by_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_created_by_index ON public.events USING btree (created_by);


--
-- Name: events_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_name_index ON public.events USING btree (name);


--
-- Name: events_organization_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_organization_id_index ON public.events USING btree (organization_id);


--
-- Name: events_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX events_project_id_index ON public.events USING btree (project_id);


--
-- Name: gallery_project_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gallery_project_id_index ON public.gallery USING btree (project_id);


--
-- Name: gallery_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX gallery_slug_index ON public.gallery USING btree (slug);


--
-- Name: organization_invitations_organization_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_invitations_organization_id_index ON public.organization_invitations USING btree (organization_id);


--
-- Name: organizations_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organizations_slug_index ON public.organizations USING btree (slug);


--
-- Name: organizations_stripe_customer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organizations_stripe_customer_id_index ON public.organizations USING btree (stripe_customer_id);


--
-- Name: projects_organization_id_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX projects_organization_id_slug_index ON public.projects USING btree (organization_id, slug);


--
-- Name: user_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_tokens_context_token_index ON public.user_tokens USING btree (context, token);


--
-- Name: user_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tokens_user_id_index ON public.user_tokens USING btree (user_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_slug_index ON public.users USING btree (slug);


--
-- Name: clever_cloud_resources clever_cloud_resources_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clever_cloud_resources
    ADD CONSTRAINT clever_cloud_resources_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: CONSTRAINT events_created_by_fkey ON events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT events_created_by_fkey ON public.events IS 'Link to users';


--
-- Name: events events_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: gallery gallery_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gallery
    ADD CONSTRAINT gallery_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: heroku_resources heroku_resources_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.heroku_resources
    ADD CONSTRAINT heroku_resources_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: organization_invitations organization_invitations_answered_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_invitations
    ADD CONSTRAINT organization_invitations_answered_by_fkey FOREIGN KEY (answered_by) REFERENCES public.users(id);


--
-- Name: organization_invitations organization_invitations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_invitations
    ADD CONSTRAINT organization_invitations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: organization_invitations organization_invitations_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_invitations
    ADD CONSTRAINT organization_invitations_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: organization_members organization_members_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: organization_members organization_members_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: organization_members organization_members_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: organization_members organization_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: organizations organizations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: organizations organizations_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(id);


--
-- Name: organizations organizations_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: project_tokens project_tokens_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_tokens
    ADD CONSTRAINT project_tokens_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: project_tokens project_tokens_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_tokens
    ADD CONSTRAINT project_tokens_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: project_tokens project_tokens_revoked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_tokens
    ADD CONSTRAINT project_tokens_revoked_by_fkey FOREIGN KEY (revoked_by) REFERENCES public.users(id);


--
-- Name: projects projects_archived_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_archived_by_fkey FOREIGN KEY (archived_by) REFERENCES public.users(id);


--
-- Name: projects projects_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: projects projects_local_owner_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_local_owner_fkey FOREIGN KEY (local_owner) REFERENCES public.users(id);


--
-- Name: projects projects_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: projects projects_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: user_auth_tokens user_auth_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_auth_tokens
    ADD CONSTRAINT user_auth_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_team_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_team_organization_id_fkey FOREIGN KEY (team_organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_tokens user_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20220903194509);
INSERT INTO public."schema_migrations" (version) VALUES (20221116095052);
INSERT INTO public."schema_migrations" (version) VALUES (20221121135140);
INSERT INTO public."schema_migrations" (version) VALUES (20221205110011);
INSERT INTO public."schema_migrations" (version) VALUES (20221230162039);
INSERT INTO public."schema_migrations" (version) VALUES (20230102142929);
INSERT INTO public."schema_migrations" (version) VALUES (20230107144621);
INSERT INTO public."schema_migrations" (version) VALUES (20230126103538);
INSERT INTO public."schema_migrations" (version) VALUES (20230412184510);
INSERT INTO public."schema_migrations" (version) VALUES (20230412190321);
INSERT INTO public."schema_migrations" (version) VALUES (20230412190524);
INSERT INTO public."schema_migrations" (version) VALUES (20230701191613);
INSERT INTO public."schema_migrations" (version) VALUES (20231110120742);
INSERT INTO public."schema_migrations" (version) VALUES (20240425124708);
INSERT INTO public."schema_migrations" (version) VALUES (20240624135054);
INSERT INTO public."schema_migrations" (version) VALUES (20240715092952);
INSERT INTO public."schema_migrations" (version) VALUES (20240724110212);
