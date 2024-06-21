import { PROD } from "./env.constants"
import { AnalyzeReportHtmlResult } from "@azimutt/models"

declare var __REPORT__: AnalyzeReportHtmlResult

export const REPORT: AnalyzeReportHtmlResult = PROD
  ? __REPORT__
  : ({
      levels: [
        {
          level: "high",
          levelViolationsCount: 6,
          rules: [
            {
              name: "duplicated index",
              level: "high",
              conf: {},
              violations: [
                {
                  message:
                    "Index mfa_factors_user_id_idx on auth.mfa_factors(user_id) can be deleted, it's covered by: factor_id_created_at_idx(user_id, created_at).",
                  entity: { schema: "auth", entity: "mfa_factors" },
                  attribute: ["user_id"],
                  extra: {
                    index: {
                      name: "mfa_factors_user_id_idx",
                      attrs: [["user_id"]],
                      definition: "btree (user_id)",
                    },
                    coveredBy: [
                      {
                        name: "factor_id_created_at_idx",
                        attrs: [["user_id"], ["created_at"]],
                        definition: "btree (user_id, created_at)",
                      },
                    ],
                  },
                },
                {
                  message:
                    "Index refresh_tokens_instance_id_idx on auth.refresh_tokens(instance_id) can be deleted, it's covered by: refresh_tokens_instance_id_user_id_idx(instance_id, user_id).",
                  entity: { schema: "auth", entity: "refresh_tokens" },
                  attribute: ["instance_id"],
                  extra: {
                    index: {
                      name: "refresh_tokens_instance_id_idx",
                      attrs: [["instance_id"]],
                      definition: "btree (instance_id)",
                    },
                    coveredBy: [
                      {
                        name: "refresh_tokens_instance_id_user_id_idx",
                        attrs: [["instance_id"], ["user_id"]],
                        definition: "btree (instance_id, user_id)",
                      },
                    ],
                  },
                },
                {
                  message:
                    "Index sessions_user_id_idx on auth.sessions(user_id) can be deleted, it's covered by: user_id_created_at_idx(user_id, created_at).",
                  entity: { schema: "auth", entity: "sessions" },
                  attribute: ["user_id"],
                  extra: {
                    index: {
                      name: "sessions_user_id_idx",
                      attrs: [["user_id"]],
                      definition: "btree (user_id)",
                    },
                    coveredBy: [
                      {
                        name: "user_id_created_at_idx",
                        attrs: [["user_id"], ["created_at"]],
                        definition: "btree (user_id, created_at)",
                      },
                    ],
                  },
                },
              ],
              totalViolations: 5,
            },
            {
              name: "entity not clean",
              level: "high",
              conf: {
                maxDeadRows: 30000,
                maxVacuumLag: 30000,
                maxAnalyzeLag: 30000,
                maxVacuumDelayMs: 86400000,
                maxAnalyzeDelayMs: 86400000,
              },
              violations: [
                {
                  message:
                    "Entity public.events has old analyze (2024-06-17T10:18:35.009Z).",
                  entity: { schema: "public", entity: "events" },
                  extra: {
                    reason: "old analyze",
                    value: "2024-06-17T10:18:35.009Z",
                  },
                },
              ],
              totalViolations: 1,
            },
          ],
        },
        {
          level: "medium",
          levelViolationsCount: 88,
          rules: [
            {
              name: "entity too large",
              level: "medium",
              conf: { max: 30 },
              violations: [
                {
                  message: "Entity auth.users has too many attributes (35).",
                  entity: { schema: "auth", entity: "users" },
                  extra: { attributes: 35 },
                },
                {
                  message:
                    "Entity extensions.pg_stat_statements has too many attributes (43).",
                  entity: {
                    schema: "extensions",
                    entity: "pg_stat_statements",
                  },
                  extra: { attributes: 43 },
                },
              ],
              totalViolations: 2,
            },
            {
              name: "entity with too heavy indexes",
              level: "medium",
              conf: { ratio: 1 },
              violations: [
                {
                  message:
                    "Entity auth.users has too heavy indexes (10x data size, 11 indexes).",
                  entity: { schema: "auth", entity: "users" },
                  extra: { ratio: 10 },
                },
                {
                  message:
                    "Entity public.gallery has too heavy indexes (6x data size, 3 indexes).",
                  entity: { schema: "public", entity: "gallery" },
                  extra: { ratio: 6 },
                },
                {
                  message:
                    "Entity public.organizations has too heavy indexes (6x data size, 3 indexes).",
                  entity: { schema: "public", entity: "organizations" },
                  extra: { ratio: 6 },
                },
              ],
              totalViolations: 15,
            },
            {
              name: "business primary key forbidden",
              level: "medium",
              conf: {},
              violations: [
                {
                  message:
                    "Entity auth.schema_migrations should have a technical primary key, current one is: (version).",
                  entity: { schema: "auth", entity: "schema_migrations" },
                  attribute: ["version"],
                  extra: {
                    primaryKey: {
                      name: "schema_migrations_pkey",
                      attrs: [["version"]],
                    },
                  },
                },
                {
                  message:
                    "Entity public.schema_migrations should have a technical primary key, current one is: (version).",
                  entity: { schema: "public", entity: "schema_migrations" },
                  attribute: ["version"],
                  extra: {
                    primaryKey: {
                      name: "schema_migrations_pkey",
                      attrs: [["version"]],
                    },
                  },
                },
                {
                  message:
                    "Entity realtime.schema_migrations should have a technical primary key, current one is: (version).",
                  entity: { schema: "realtime", entity: "schema_migrations" },
                  attribute: ["version"],
                  extra: {
                    primaryKey: {
                      name: "schema_migrations_pkey",
                      attrs: [["version"]],
                    },
                  },
                },
              ],
              totalViolations: 3,
            },
            {
              name: "index on relation",
              level: "medium",
              conf: {},
              violations: [
                {
                  message:
                    "Create an index on auth.mfa_challenges(factor_id) to improve auth.mfa_challenges(factor_id)->auth.mfa_factors(id) relation.",
                  entity: { schema: "auth", entity: "mfa_challenges" },
                  attribute: ["factor_id"],
                  extra: {
                    indexAttrs: [["factor_id"]],
                    relation: {
                      name: "mfa_challenges_auth_factor_id_fkey",
                      src: { schema: "auth", entity: "mfa_challenges" },
                      ref: { schema: "auth", entity: "mfa_factors" },
                      attrs: [{ src: ["factor_id"], ref: ["id"] }],
                    },
                  },
                },
                {
                  message:
                    "Create an index on auth.saml_relay_states(flow_state_id) to improve auth.saml_relay_states(flow_state_id)->auth.flow_state(id) relation.",
                  entity: { schema: "auth", entity: "saml_relay_states" },
                  attribute: ["flow_state_id"],
                  extra: {
                    indexAttrs: [["flow_state_id"]],
                    relation: {
                      name: "saml_relay_states_flow_state_id_fkey",
                      src: { schema: "auth", entity: "saml_relay_states" },
                      ref: { schema: "auth", entity: "flow_state" },
                      attrs: [{ src: ["flow_state_id"], ref: ["id"] }],
                    },
                  },
                },
                {
                  message:
                    "Create an index on pgsodium.key(parent_key) to improve pgsodium.key(parent_key)->pgsodium.key(id) relation.",
                  entity: { schema: "pgsodium", entity: "key" },
                  attribute: ["parent_key"],
                  extra: {
                    indexAttrs: [["parent_key"]],
                    relation: {
                      name: "key_parent_key_fkey",
                      src: { schema: "pgsodium", entity: "key" },
                      ref: { schema: "pgsodium", entity: "key" },
                      attrs: [{ src: ["parent_key"], ref: ["id"] }],
                    },
                  },
                },
              ],
              totalViolations: 26,
            },
            {
              name: "missing relation",
              level: "medium",
              conf: {},
              violations: [
                {
                  message:
                    "Create a relation from auth.audit_log_entries(instance_id) to auth.instances(id).",
                  entity: { schema: "auth", entity: "audit_log_entries" },
                  attribute: ["instance_id"],
                  extra: {
                    relation: {
                      src: { schema: "auth", entity: "audit_log_entries" },
                      ref: { schema: "auth", entity: "instances" },
                      attrs: [{ src: ["instance_id"], ref: ["id"] }],
                      origin: "infer-name",
                    },
                  },
                },
                {
                  message:
                    "Create a relation from auth.flow_state(user_id) to auth.users(id).",
                  entity: { schema: "auth", entity: "flow_state" },
                  attribute: ["user_id"],
                  extra: {
                    relation: {
                      src: { schema: "auth", entity: "flow_state" },
                      ref: { schema: "auth", entity: "users" },
                      attrs: [{ src: ["user_id"], ref: ["id"] }],
                      origin: "infer-name",
                    },
                  },
                },
                {
                  message:
                    "Create a relation from auth.flow_state(user_id) to public.users(id).",
                  entity: { schema: "auth", entity: "flow_state" },
                  attribute: ["user_id"],
                  extra: {
                    relation: {
                      src: { schema: "auth", entity: "flow_state" },
                      ref: { schema: "public", entity: "users" },
                      attrs: [{ src: ["user_id"], ref: ["id"] }],
                      origin: "infer-name",
                    },
                  },
                },
              ],
              totalViolations: 42,
            },
          ],
        },
        { level: "low", levelViolationsCount: 0, rules: [] },
        {
          level: "hint",
          levelViolationsCount: 57,
          rules: [
            {
              name: "inconsistent attribute type",
              level: "hint",
              conf: {},
              violations: [
                {
                  message:
                    "Attribute id has several types: integer in storage.migrations(id), text in storage.buckets(id) and 1 other, bigint in auth.refresh_tokens(id) and 2 others, uuid in auth.audit_log_entries(id) and 32 others.",
                  entity: { schema: "storage", entity: "migrations" },
                  attribute: ["id"],
                  extra: {
                    attributes: [
                      {
                        schema: "auth",
                        entity: "audit_log_entries",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "flow_state",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "identities",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "instances",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_amr_claims",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_challenges",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_factors",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "one_time_tokens",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "refresh_tokens",
                        attribute: ["id"],
                        type: "bigint",
                      },
                      {
                        schema: "auth",
                        entity: "saml_providers",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "saml_relay_states",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "sessions",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "sso_domains",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "sso_providers",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "auth",
                        entity: "users",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "pgsodium",
                        entity: "decrypted_key",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "pgsodium",
                        entity: "key",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "pgsodium",
                        entity: "valid_key",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "clever_cloud_resources",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "events",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "gallery",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "heroku_resources",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "organization_invitations",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "organizations",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "project_tokens",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "projects",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "user_auth_tokens",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "user_profiles",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "user_tokens",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "public",
                        entity: "users",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "realtime",
                        entity: "messages",
                        attribute: ["id"],
                        type: "bigint",
                      },
                      {
                        schema: "realtime",
                        entity: "subscription",
                        attribute: ["id"],
                        type: "bigint",
                      },
                      {
                        schema: "storage",
                        entity: "buckets",
                        attribute: ["id"],
                        type: "text",
                      },
                      {
                        schema: "storage",
                        entity: "migrations",
                        attribute: ["id"],
                        type: "integer",
                      },
                      {
                        schema: "storage",
                        entity: "objects",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "storage",
                        entity: "s3_multipart_uploads",
                        attribute: ["id"],
                        type: "text",
                      },
                      {
                        schema: "storage",
                        entity: "s3_multipart_uploads_parts",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "vault",
                        entity: "decrypted_secrets",
                        attribute: ["id"],
                        type: "uuid",
                      },
                      {
                        schema: "vault",
                        entity: "secrets",
                        attribute: ["id"],
                        type: "uuid",
                      },
                    ],
                  },
                },
                {
                  message:
                    "Attribute created_at has several types: timestamp without time zone in auth.one_time_tokens(created_at) and 14 others, timestamp with time zone in auth.audit_log_entries(created_at) and 19 others.",
                  entity: { schema: "auth", entity: "one_time_tokens" },
                  attribute: ["created_at"],
                  extra: {
                    attributes: [
                      {
                        schema: "auth",
                        entity: "audit_log_entries",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "flow_state",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "identities",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "instances",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_amr_claims",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_challenges",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_factors",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "one_time_tokens",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "auth",
                        entity: "refresh_tokens",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "saml_providers",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "saml_relay_states",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "sessions",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "sso_domains",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "sso_providers",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "auth",
                        entity: "users",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "public",
                        entity: "clever_cloud_resources",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "events",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "gallery",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "heroku_resources",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "organization_invitations",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "organization_members",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "organizations",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "project_tokens",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "projects",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "user_auth_tokens",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "user_profiles",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "user_tokens",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "public",
                        entity: "users",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "realtime",
                        entity: "subscription",
                        attribute: ["created_at"],
                        type: "timestamp without time zone",
                      },
                      {
                        schema: "storage",
                        entity: "buckets",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "storage",
                        entity: "objects",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "storage",
                        entity: "s3_multipart_uploads",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "storage",
                        entity: "s3_multipart_uploads_parts",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "vault",
                        entity: "decrypted_secrets",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                      {
                        schema: "vault",
                        entity: "secrets",
                        attribute: ["created_at"],
                        type: "timestamp with time zone",
                      },
                    ],
                  },
                },
                {
                  message:
                    "Attribute ip_address has several types: character varying(64) in auth.audit_log_entries(ip_address), inet in auth.mfa_challenges(ip_address).",
                  entity: { schema: "auth", entity: "audit_log_entries" },
                  attribute: ["ip_address"],
                  extra: {
                    attributes: [
                      {
                        schema: "auth",
                        entity: "audit_log_entries",
                        attribute: ["ip_address"],
                        type: "character varying(64)",
                      },
                      {
                        schema: "auth",
                        entity: "mfa_challenges",
                        attribute: ["ip_address"],
                        type: "inet",
                      },
                    ],
                  },
                },
              ],
              totalViolations: 17,
            },
            {
              name: "expensive query",
              level: "hint",
              conf: {},
              violations: [
                {
                  message:
                    "Query 1374137181295181600 is one of the most expensive, cumulated 5085 ms exec time in 46 executions (SELECT name FROM pg_timezone_names)",
                  extra: {
                    queryId: "1374137181295181600",
                    query: "SELECT name FROM pg_timezone_names",
                    stats: {
                      rows: 56212,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 46,
                        minTime: 59.496679,
                        maxTime: 999.19821,
                        sumTime: 5085.085536,
                        meanTime: 110.54533773913,
                        sdTime: 194.142018224398,
                      },
                      blocks: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [],
                  },
                },
                {
                  message:
                    "Query -156763288877666600 on pg_type is one of the most expensive, cumulated 1146 ms exec time in 46 executions ( WITH base_types AS ( WITH RECURSIVE recurse AS ( SELECT oid, typbasetype, COALESCE(NULLIF(typbasetype, $3), oid) AS base FROM pg_type UNION SELECT t.oid, b.typbasetype, COALESCE(NULLIF(b.typbasety...)",
                  entity: { entity: "pg_type" },
                  extra: {
                    queryId: "-156763288877666600",
                    query:
                      "-- Recursively get the base types of domains\n  WITH\n  base_types AS (\n    WITH RECURSIVE\n    recurse AS (\n      SELECT\n        oid,\n        typbasetype,\n        COALESCE(NULLIF(typbasetype, $3), oid) AS base\n      FROM pg_type\n      UNION\n      SELECT\n        t.oid,\n        b.typbasetype,\n        COALESCE(NULLIF(b.typbasetype, $4), b.oid) AS base\n      FROM recurse t\n      JOIN pg_type b ON t.typbasetype = b.oid\n    )\n    SELECT\n      oid,\n      base\n    FROM recurse\n    WHERE typbasetype = $5\n  ),\n  arguments AS (\n    SELECT\n      oid,\n      array_agg((\n        COALESCE(name, $6), -- name\n        type::regtype::text, -- type\n        CASE type\n          WHEN $7::regtype THEN $8\n          WHEN $9::regtype THEN $10\n          WHEN $11::regtype THEN $12\n          WHEN $13::regtype THEN $14\n          ELSE type::regtype::text\n        END, -- convert types that ignore the lenth and accept any value till maximum size\n        idx <= (pronargs - pronargdefaults), -- is_required\n        COALESCE(mode = $15, $16) -- is_variadic\n      ) ORDER BY idx) AS args,\n      CASE COUNT(*) - COUNT(name) -- number of unnamed arguments\n        WHEN $17 THEN $18\n        WHEN $19 THEN (array_agg(type))[$20] IN ($21::regtype, $22::regtype, $23::regtype, $24::regtype, $25::regtype)\n        ELSE $26\n      END AS callable\n    FROM pg_proc,\n         unnest(proargnames, proargtypes, proargmodes)\n           WITH ORDINALITY AS _ (name, type, mode, idx)\n    WHERE type IS NOT NULL -- only input arguments\n    GROUP BY oid\n  )\n  SELECT\n    pn.nspname AS proc_schema,\n    p.proname AS proc_name,\n    d.description AS proc_description,\n    COALESCE(a.args, $27) AS args,\n    tn.nspname AS schema,\n    COALESCE(comp.relname, t.typname) AS name,\n    p.proretset AS rettype_is_setof,\n    (t.typtype = $28\n     -- if any TABLE, INOUT or OUT arguments present, treat as composite\n     or COALESCE(proargmodes::text[] && $29, $30)\n    ) AS rettype_is_composite,\n    bt.oid <> bt.base as rettype_is_composite_alias,\n    p.provolatile,\n    p.provariadic > $31 as hasvariadic,\n    lower((regexp_split_to_array((regexp_split_to_array(iso_config, $32))[$33], $34))[$35]) AS transaction_isolation_level,\n    coalesce(func_settings.kvs, $36) as kvs\n  FROM pg_proc p\n  LEFT JOIN arguments a ON a.oid = p.oid\n  JOIN pg_namespace pn ON pn.oid = p.pronamespace\n  JOIN base_types bt ON bt.oid = p.prorettype\n  JOIN pg_type t ON t.oid = bt.base\n  JOIN pg_namespace tn ON tn.oid = t.typnamespace\n  LEFT JOIN pg_class comp ON comp.oid = t.typrelid\n  LEFT JOIN pg_description as d ON d.objoid = p.oid\n  LEFT JOIN LATERAL unnest(proconfig) iso_config ON iso_config LIKE $37\n  LEFT JOIN LATERAL (\n    SELECT\n      array_agg(row(\n        substr(setting, $38, strpos(setting, $39) - $40),\n        substr(setting, strpos(setting, $41) + $42)\n      )) as kvs\n    FROM unnest(proconfig) setting\n    WHERE setting ~ ANY($2)\n  ) func_settings ON $43\n  WHERE t.oid <> $44::regtype AND COALESCE(a.callable, $45)\nAND prokind = $46 AND pn.nspname = ANY($1)",
                    stats: {
                      rows: 46,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 46,
                        minTime: 23.578641,
                        maxTime: 40.148259,
                        sumTime: 1146.312727,
                        meanTime: 24.9198418913044,
                        sdTime: 2.90254298014164,
                      },
                      blocks: {
                        sumRead: 140,
                        sumWrite: 0,
                        sumHit: 92424,
                        sumDirty: 10,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [],
                  },
                },
                {
                  message:
                    "Query -8486453569861712000 on pg_attribute is one of the most expensive, cumulated 425 ms exec time in 34 executions (SELECT c.oid AS table_id , n.nspname AS tabl... FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace  JOIN pg_type t ON t.oid = a.atttypid LEFT JO...)",
                  entity: { entity: "pg_attribute" },
                  extra: {
                    queryId: "-8486453569861712000",
                    query:
                      "SELECT c.oid                                AS table_id\n             -- , u.rolname                            AS table_owner\n             , n.nspname                            AS table_schema\n             , c.relname                            AS table_name\n             , c.relkind                            AS table_kind\n             , a.attnum                             AS column_index\n             , a.attname                            AS column_name\n             , format_type(a.atttypid, a.atttypmod) AS column_type\n             , t.typname                            AS column_type_name\n             , t.typlen                             AS column_type_len\n             , t.typcategory                        AS column_type_cat\n             , NOT a.attnotnull                     AS column_nullable\n             , pg_get_expr(ad.adbin, ad.adrelid)    AS column_default\n             , a.attgenerated = $1                 AS column_generated\n             , d.description                        AS column_comment\n             , null_frac                            AS nulls\n             , avg_width                            AS avg_len\n             , n_distinct                           AS cardinality\n             , most_common_vals                     AS common_vals\n             , most_common_freqs                    AS common_freqs\n             , histogram_bounds                     AS histogram\n        FROM pg_attribute a\n                 JOIN pg_class c ON c.oid = a.attrelid\n                 JOIN pg_namespace n ON n.oid = c.relnamespace\n                 -- JOIN pg_authid u ON u.oid = c.relowner\n                 JOIN pg_type t ON t.oid = a.atttypid\n                 LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum\n                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum\n                 LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname AND s.attname = a.attname\n        WHERE c.relkind IN ($2, $3, $4)\n          AND a.attnum > $5\n          AND a.atttypid != $6\n          AND n.nspname NOT IN ($7, $8)\n        ORDER BY table_schema, table_name, column_index",
                    stats: {
                      rows: 16456,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 34,
                        minTime: 9.37997,
                        maxTime: 74.063108,
                        sumTime: 424.955141,
                        meanTime: 12.4986806176471,
                        sdTime: 10.9021657002716,
                      },
                      blocks: {
                        sumRead: 41,
                        sumWrite: 0,
                        sumHit: 187879,
                        sumDirty: 10,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [
                      { entity: "pg_attribute" },
                      { entity: "pg_class" },
                      { entity: "pg_namespace" },
                      { entity: "pg_authid" },
                      { entity: "pg_type" },
                      { entity: "pg_attrdef" },
                      { entity: "pg_description" },
                      { entity: "pg_stats" },
                    ],
                  },
                },
              ],
              totalViolations: 20,
            },
            {
              name: "query with high variation",
              level: "hint",
              conf: {},
              violations: [
                {
                  message:
                    "Query 1374137181295181600 has high variation, with 194 ms standard deviation and exec time ranging from 59 ms to 999 ms (SELECT name FROM pg_timezone_names)",
                  extra: {
                    queryId: "1374137181295181600",
                    query: "SELECT name FROM pg_timezone_names",
                    stats: {
                      rows: 56212,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 46,
                        minTime: 59.496679,
                        maxTime: 999.19821,
                        sumTime: 5085.085536,
                        meanTime: 110.54533773913,
                        sdTime: 194.142018224398,
                      },
                      blocks: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [],
                  },
                },
                {
                  message:
                    "Query -4726471486296252000 on pg_attribute has high variation, with 25 ms standard deviation and exec time ranging from 5 ms to 78 ms (SELECT t.oid, t.typname, t.typsend, t.typrec... FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem)))",
                  entity: { entity: "pg_attribute" },
                  extra: {
                    queryId: "-4726471486296252000",
                    query:
                      "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE (t.typrelid = $4)\nAND (t.typelem = $5 OR NOT EXISTS (SELECT $6 FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem))",
                    stats: {
                      rows: 1493,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 7,
                        minTime: 4.743659,
                        maxTime: 77.626603,
                        sumTime: 145.947125,
                        meanTime: 20.8495892857143,
                        sdTime: 24.5068412983476,
                      },
                      blocks: {
                        sumRead: 27,
                        sumWrite: 0,
                        sumHit: 18450,
                        sumDirty: 0,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [
                      { entity: "pg_attribute" },
                      { entity: "pg_type" },
                      { entity: "pg_type", schema: "pg_catalog" },
                      { entity: "pg_type" },
                      { entity: "pg_range" },
                    ],
                  },
                },
                {
                  message:
                    "Query 7339462770142107000 on pg_namespace has high variation, with 12 ms standard deviation and exec time ranging from 33 ms to 67 ms (with tables as (SELECT c.oid :: int8 AS id, nc.nspname AS schema, c.relname AS name, c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced, CASE WHEN c.relreplident = $1 THEN $2 WHEN...)",
                  entity: { entity: "pg_namespace" },
                  extra: {
                    queryId: "7339462770142107000",
                    query:
                      'with tables as (SELECT\n  c.oid :: int8 AS id,\n  nc.nspname AS schema,\n  c.relname AS name,\n  c.relrowsecurity AS rls_enabled,\n  c.relforcerowsecurity AS rls_forced,\n  CASE\n    WHEN c.relreplident = $1 THEN $2\n    WHEN c.relreplident = $3 THEN $4\n    WHEN c.relreplident = $5 THEN $6\n    ELSE $7\n  END AS replica_identity,\n  pg_total_relation_size(format($8, nc.nspname, c.relname)) :: int8 AS bytes,\n  pg_size_pretty(\n    pg_total_relation_size(format($9, nc.nspname, c.relname))\n  ) AS size,\n  pg_stat_get_live_tuples(c.oid) AS live_rows_estimate,\n  pg_stat_get_dead_tuples(c.oid) AS dead_rows_estimate,\n  obj_description(c.oid) AS comment,\n  coalesce(pk.primary_keys, $10) as primary_keys,\n  coalesce(\n    jsonb_agg(relationships) filter (where relationships is not null),\n    $11\n  ) as relationships\nFROM\n  pg_namespace nc\n  JOIN pg_class c ON nc.oid = c.relnamespace\n  left join (\n    select\n      table_id,\n      jsonb_agg(_pk.*) as primary_keys\n    from (\n      select\n        n.nspname as schema,\n        c.relname as table_name,\n        a.attname as name,\n        c.oid :: int8 as table_id\n      from\n        pg_index i,\n        pg_class c,\n        pg_attribute a,\n        pg_namespace n\n      where\n        i.indrelid = c.oid\n        and c.relnamespace = n.oid\n        and a.attrelid = c.oid\n        and a.attnum = any (i.indkey)\n        and i.indisprimary\n    ) as _pk\n    group by table_id\n  ) as pk\n  on pk.table_id = c.oid\n  left join (\n    select\n      c.oid :: int8 as id,\n      c.conname as constraint_name,\n      nsa.nspname as source_schema,\n      csa.relname as source_table_name,\n      sa.attname as source_column_name,\n      nta.nspname as target_table_schema,\n      cta.relname as target_table_name,\n      ta.attname as target_column_name\n    from\n      pg_constraint c\n    join (\n      pg_attribute sa\n      join pg_class csa on sa.attrelid = csa.oid\n      join pg_namespace nsa on csa.relnamespace = nsa.oid\n    ) on sa.attrelid = c.conrelid and sa.attnum = any (c.conkey)\n    join (\n      pg_attribute ta\n      join pg_class cta on ta.attrelid = cta.oid\n      join pg_namespace nta on cta.relnamespace = nta.oid\n    ) on ta.attrelid = c.confrelid and ta.attnum = any (c.confkey)\n    where\n      c.contype = $12\n  ) as relationships\n  on (relationships.source_schema = nc.nspname and relationships.source_table_name = c.relname)\n  or (relationships.target_table_schema = nc.nspname and relationships.target_table_name = c.relname)\nWHERE\n  c.relkind IN ($13, $14)\n  AND NOT pg_is_other_temp_schema(nc.oid)\n  AND (\n    pg_has_role(c.relowner, $15)\n    OR has_table_privilege(\n      c.oid,\n      $16\n    )\n    OR has_any_column_privilege(c.oid, $17)\n  )\ngroup by\n  c.oid,\n  c.relname,\n  c.relrowsecurity,\n  c.relforcerowsecurity,\n  c.relreplident,\n  nc.nspname,\n  pk.primary_keys\n)\n  , columns as (-- Adapted from information_schema.columns\n\nSELECT\n  c.oid :: int8 AS table_id,\n  nc.nspname AS schema,\n  c.relname AS table,\n  (c.oid || $18 || a.attnum) AS id,\n  a.attnum AS ordinal_position,\n  a.attname AS name,\n  CASE\n    WHEN a.atthasdef THEN pg_get_expr(ad.adbin, ad.adrelid)\n    ELSE $19\n  END AS default_value,\n  CASE\n    WHEN t.typtype = $20 THEN CASE\n      WHEN bt.typelem <> $21 :: oid\n      AND bt.typlen = $22 THEN $23\n      WHEN nbt.nspname = $24 THEN format_type(t.typbasetype, $25)\n      ELSE $26\n    END\n    ELSE CASE\n      WHEN t.typelem <> $27 :: oid\n      AND t.typlen = $28 THEN $29\n      WHEN nt.nspname = $30 THEN format_type(a.atttypid, $31)\n      ELSE $32\n    END\n  END AS data_type,\n  COALESCE(bt.typname, t.typname) AS format,\n  a.attidentity IN ($33, $34) AS is_identity,\n  CASE\n    a.attidentity\n    WHEN $35 THEN $36\n    WHEN $37 THEN $38\n    ELSE $39\n  END AS identity_generation,\n  a.attgenerated IN ($40) AS is_generated,\n  NOT (\n    a.attnotnull\n    OR t.typtype = $41 AND t.typnotnull\n  ) AS is_nullable,\n  (\n    c.relkind IN ($42, $43)\n    OR c.relkind IN ($44, $45) AND pg_column_is_updatable(c.oid, a.attnum, $46)\n  ) AS is_updatable,\n  uniques.table_id IS NOT NULL AS is_unique,\n  check_constraints.definition AS "check",\n  array_to_json(\n    array(\n      SELECT\n        enumlabel\n      FROM\n        pg_catalog.pg_enum enums\n      WHERE\n        enums.enumtypid = coalesce(bt.oid, t.oid)\n        OR enums.enumtypid = coalesce(bt.typelem, t.typelem)\n      ORDER BY\n        enums.enumsortorder\n    )\n  ) AS enums,\n  col_description(c.oid, a.attnum) AS comment\nFROM\n  pg_attribute a\n  LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid\n  AND a.attnum = ad.adnum\n  JOIN (\n    pg_class c\n    JOIN pg_namespace nc ON c.relnamespace = nc.oid\n  ) ON a.attrelid = c.oid\n  JOIN (\n    pg_type t\n    JOIN pg_namespace nt ON t.typnamespace = nt.oid\n  ) ON a.atttypid = t.oid\n  LEFT JOIN (\n    pg_type bt\n    JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid\n  ) ON t.typtype = $47\n  AND t.typbasetype = bt.oid\n  LEFT JOIN (\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$48] AS ordinal_position\n    FROM pg_catalog.pg_constraint\n    WHERE contype = $49 AND cardinality(conkey) = $50\n  ) AS uniques ON uniques.table_id = c.oid AND uniques.ordinal_position = a.attnum\n  LEFT JOIN (\n    -- We only select the first column check\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$51] AS ordinal_position,\n      substring(\n        pg_get_constraintdef(pg_constraint.oid, $52),\n        $53,\n        length(pg_get_constraintdef(pg_constraint.oid, $54)) - $55\n      ) AS "definition"\n    FROM pg_constraint\n    WHERE contype = $56 AND cardinality(conkey) = $57\n    ORDER BY table_id, ordinal_position, oid asc\n  ) AS check_constraints ON check_constraints.table_id = c.oid AND check_constraints.ordinal_position = a.attnum\nWHERE\n  NOT pg_is_other_temp_schema(nc.oid)\n  AND a.attnum > $58\n  AND NOT a.attisdropped\n  AND (c.relkind IN ($59, $60, $61, $62, $63))\n  AND (\n    pg_has_role(c.relowner, $64)\n    OR has_column_privilege(\n      c.oid,\n      a.attnum,\n      $65\n    )\n  )\n)\nselect\n  *\n  , \nCOALESCE(\n  (\n    SELECT\n      array_agg(row_to_json(columns)) FILTER (WHERE columns.table_id = tables.id)\n    FROM\n      columns\n  ),\n  $66\n) AS columns\nfrom tables where tables.id = $67',
                    stats: {
                      rows: 7,
                      plan: {
                        count: 0,
                        minTime: 0,
                        maxTime: 0,
                        sumTime: 0,
                        meanTime: 0,
                        sdTime: 0,
                      },
                      exec: {
                        count: 7,
                        minTime: 32.826756,
                        maxTime: 67.065888,
                        sumTime: 315.148504,
                        meanTime: 45.0212148571429,
                        sdTime: 12.3639953334066,
                      },
                      blocks: {
                        sumRead: 23,
                        sumWrite: 0,
                        sumHit: 92690,
                        sumDirty: 0,
                      },
                      blocksTmp: {
                        sumRead: 0,
                        sumWrite: 0,
                        sumHit: 0,
                        sumDirty: 0,
                      },
                      blocksQuery: { sumRead: 0, sumWrite: 0 },
                    },
                    entities: [],
                  },
                },
              ],
              totalViolations: 20,
            },
          ],
        },
      ],
      rules: [
        { name: "inconsistent attribute type", totalViolations: 17 },
        { name: "expensive query", totalViolations: 20 },
        { name: "query with high variation", totalViolations: 20 },
        { name: "entity too large", totalViolations: 2 },
        { name: "entity with too heavy indexes", totalViolations: 15 },
        { name: "business primary key forbidden", totalViolations: 3 },
        { name: "index on relation", totalViolations: 26 },
        { name: "missing relation", totalViolations: 42 },
        { name: "duplicated index", totalViolations: 5 },
        { name: "entity not clean", totalViolations: 1 },
      ],
      database: {
        entities: [
          {
            schema: "auth",
            name: "audit_log_entries",
            attrs: [
              {
                name: "instance_id",
                type: "uuid",
                null: true,
              },
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "payload",
                type: "json",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "ip_address",
                type: "character varying(64)",
                default: "''::character varying",
              },
            ],
            pk: {
              name: "audit_log_entries_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "audit_logs_instance_id_idx",
                attrs: [["instance_id"]],
                definition: "btree (instance_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "Auth: Audit trail for user actions.",
            stats: {
              scanSeq: 8,
            },
          },
          {
            schema: "auth",
            name: "flow_state",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
                null: true,
              },
              {
                name: "auth_code",
                type: "text",
              },
              {
                name: "code_challenge_method",
                type: "auth.code_challenge_method",
              },
              {
                name: "code_challenge",
                type: "text",
              },
              {
                name: "provider_type",
                type: "text",
              },
              {
                name: "provider_access_token",
                type: "text",
                null: true,
              },
              {
                name: "provider_refresh_token",
                type: "text",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "authentication_method",
                type: "text",
              },
              {
                name: "auth_code_issued_at",
                type: "timestamp with time zone",
                null: true,
              },
            ],
            pk: {
              name: "flow_state_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "flow_state_created_at_idx",
                attrs: [["created_at"]],
                definition: "btree (created_at DESC)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "idx_auth_code",
                attrs: [["auth_code"]],
                definition: "btree (auth_code)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "idx_user_id_auth_method",
                attrs: [["user_id"], ["authentication_method"]],
                definition: "btree (user_id, authentication_method)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "stores metadata for pkce logins",
            stats: {
              sizeIdx: 32768,
              scanSeq: 13,
            },
          },
          {
            schema: "auth",
            name: "identities",
            attrs: [
              {
                name: "provider_id",
                type: "text",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "identity_data",
                type: "jsonb",
              },
              {
                name: "provider",
                type: "text",
              },
              {
                name: "last_sign_in_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "email",
                type: "text",
                null: true,
                gen: true,
                default: "lower((identity_data ->> 'email'::text))",
                doc: "Auth: Email is a generated column that references the optional email property in the identity_data",
              },
              {
                name: "id",
                type: "uuid",
                default: "gen_random_uuid()",
              },
            ],
            pk: {
              name: "identities_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "identities_email_idx",
                attrs: [["email"]],
                definition: "btree (email text_pattern_ops)",
                doc: "Auth: Ensures indexed queries on the email column",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "identities_provider_id_provider_unique",
                attrs: [["provider_id"], ["provider"]],
                unique: true,
                definition: "btree (provider_id, provider)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "identities_user_id_idx",
                attrs: [["user_id"]],
                definition: "btree (user_id)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            doc: "Auth: Stores identities associated to a user.",
            stats: {
              sizeIdx: 57344,
              scanSeq: 21,
            },
          },
          {
            schema: "auth",
            name: "instances",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "uuid",
                type: "uuid",
                null: true,
              },
              {
                name: "raw_base_config",
                type: "text",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
            ],
            pk: {
              name: "instances_pkey",
              attrs: [["id"]],
            },
            doc: "Auth: Manages users across multiple sites.",
            stats: {
              scanSeq: 8,
            },
          },
          {
            schema: "auth",
            name: "mfa_amr_claims",
            attrs: [
              {
                name: "session_id",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
              },
              {
                name: "authentication_method",
                type: "text",
              },
              {
                name: "id",
                type: "uuid",
              },
            ],
            pk: {
              name: "amr_id_pk",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "mfa_amr_claims_session_id_authentication_method_pkey",
                attrs: [["session_id"], ["authentication_method"]],
                unique: true,
                definition: "btree (session_id, authentication_method)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "auth: stores authenticator method reference claims for multi factor authentication",
            stats: {
              scanSeq: 11,
            },
          },
          {
            schema: "auth",
            name: "mfa_challenges",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "factor_id",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
              },
              {
                name: "verified_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "ip_address",
                type: "inet",
              },
            ],
            pk: {
              name: "mfa_challenges_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "mfa_challenge_created_at_idx",
                attrs: [["created_at"]],
                definition: "btree (created_at DESC)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "auth: stores metadata about challenge requests made",
            stats: {
              scanSeq: 10,
            },
          },
          {
            schema: "auth",
            name: "mfa_factors",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "friendly_name",
                type: "text",
                null: true,
              },
              {
                name: "factor_type",
                type: "auth.factor_type",
              },
              {
                name: "status",
                type: "auth.factor_status",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
              },
              {
                name: "secret",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "mfa_factors_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "factor_id_created_at_idx",
                attrs: [["user_id"], ["created_at"]],
                definition: "btree (user_id, created_at)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "mfa_factors_user_friendly_name_unique",
                attrs: [["friendly_name"], ["user_id"]],
                unique: true,
                partial: "(TRIM(BOTH FROM friendly_name) <> ''::text)",
                definition:
                  "btree (friendly_name, user_id) WHERE TRIM(BOTH FROM friendly_name) <> ''::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "mfa_factors_user_id_idx",
                attrs: [["user_id"]],
                definition: "btree (user_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "auth: stores metadata about factors",
            stats: {
              scanSeq: 12,
            },
          },
          {
            schema: "auth",
            name: "one_time_tokens",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "token_type",
                type: "auth.one_time_token_type",
              },
              {
                name: "token_hash",
                type: "text",
              },
              {
                name: "relates_to",
                type: "text",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
                default: "now()",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
                default: "now()",
              },
            ],
            pk: {
              name: "one_time_tokens_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "one_time_tokens_relates_to_hash_idx",
                attrs: [["relates_to"]],
                definition: "hash (relates_to)",
                stats: {
                  size: 32768,
                  scans: 0,
                },
              },
              {
                name: "one_time_tokens_token_hash_hash_idx",
                attrs: [["token_hash"]],
                definition: "hash (token_hash)",
                stats: {
                  size: 32768,
                  scans: 0,
                },
              },
              {
                name: "one_time_tokens_user_id_token_type_key",
                attrs: [["user_id"], ["token_type"]],
                unique: true,
                definition: "btree (user_id, token_type)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "one_time_tokens_token_hash_check",
                attrs: [["token_hash"]],
                predicate: "CHECK (char_length(token_hash) > 0)",
              },
            ],
            stats: {
              scanSeq: 12,
            },
          },
          {
            schema: "auth",
            name: "refresh_tokens",
            attrs: [
              {
                name: "instance_id",
                type: "uuid",
                null: true,
              },
              {
                name: "id",
                type: "bigint",
                default: "nextval('auth.refresh_tokens_id_seq'::regclass)",
              },
              {
                name: "token",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "user_id",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "revoked",
                type: "boolean",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "parent",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "session_id",
                type: "uuid",
                null: true,
              },
            ],
            pk: {
              name: "refresh_tokens_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "refresh_tokens_instance_id_idx",
                attrs: [["instance_id"]],
                definition: "btree (instance_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "refresh_tokens_instance_id_user_id_idx",
                attrs: [["instance_id"], ["user_id"]],
                definition: "btree (instance_id, user_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "refresh_tokens_parent_idx",
                attrs: [["parent"]],
                definition: "btree (parent)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "refresh_tokens_session_id_revoked_idx",
                attrs: [["session_id"], ["revoked"]],
                definition: "btree (session_id, revoked)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "refresh_tokens_token_unique",
                attrs: [["token"]],
                unique: true,
                definition: "btree (token)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "refresh_tokens_updated_at_idx",
                attrs: [["updated_at"]],
                definition: "btree (updated_at DESC)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "Auth: Store of tokens used to refresh JWT tokens once they expire.",
            stats: {
              sizeIdx: 40960,
              scanSeq: 14,
            },
          },
          {
            schema: "auth",
            name: "saml_providers",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "sso_provider_id",
                type: "uuid",
              },
              {
                name: "entity_id",
                type: "text",
              },
              {
                name: "metadata_xml",
                type: "text",
              },
              {
                name: "metadata_url",
                type: "text",
                null: true,
              },
              {
                name: "attribute_mapping",
                type: "jsonb",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "name_id_format",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "saml_providers_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "saml_providers_entity_id_key",
                attrs: [["entity_id"]],
                unique: true,
                definition: "btree (entity_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "saml_providers_sso_provider_id_idx",
                attrs: [["sso_provider_id"]],
                definition: "btree (sso_provider_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "entity_id not empty",
                attrs: [["entity_id"]],
                predicate: "CHECK (char_length(entity_id) > 0)",
              },
              {
                name: "metadata_url not empty",
                attrs: [["metadata_url"]],
                predicate:
                  "CHECK (metadata_url = NULL::text OR char_length(metadata_url) > 0)",
              },
              {
                name: "metadata_xml not empty",
                attrs: [["metadata_xml"]],
                predicate: "CHECK (char_length(metadata_xml) > 0)",
              },
            ],
            doc: "Auth: Manages SAML Identity Provider connections.",
            stats: {
              sizeIdx: 24576,
              scanSeq: 13,
            },
          },
          {
            schema: "auth",
            name: "saml_relay_states",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "sso_provider_id",
                type: "uuid",
              },
              {
                name: "request_id",
                type: "text",
              },
              {
                name: "for_email",
                type: "text",
                null: true,
              },
              {
                name: "redirect_to",
                type: "text",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "flow_state_id",
                type: "uuid",
                null: true,
              },
            ],
            pk: {
              name: "saml_relay_states_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "saml_relay_states_created_at_idx",
                attrs: [["created_at"]],
                definition: "btree (created_at DESC)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "saml_relay_states_for_email_idx",
                attrs: [["for_email"]],
                definition: "btree (for_email)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "saml_relay_states_sso_provider_id_idx",
                attrs: [["sso_provider_id"]],
                definition: "btree (sso_provider_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "request_id not empty",
                attrs: [["request_id"]],
                predicate: "CHECK (char_length(request_id) > 0)",
              },
            ],
            doc: "Auth: Contains SAML Relay State information for each Service Provider initiated login.",
            stats: {
              sizeIdx: 32768,
              scanSeq: 13,
            },
          },
          {
            schema: "auth",
            name: "schema_migrations",
            attrs: [
              {
                name: "version",
                type: "character varying(255)",
              },
            ],
            pk: {
              name: "schema_migrations_pkey",
              attrs: [["version"]],
            },
            doc: "Auth: Manages updates to the auth system.",
            stats: {
              rows: 49,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 9,
              scanIdx: 49,
              analyzeLag: 49,
              vacuumLag: 49,
            },
          },
          {
            schema: "auth",
            name: "sessions",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "factor_id",
                type: "uuid",
                null: true,
              },
              {
                name: "aal",
                type: "auth.aal_level",
                null: true,
              },
              {
                name: "not_after",
                type: "timestamp with time zone",
                null: true,
                doc: "Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.",
              },
              {
                name: "refreshed_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "user_agent",
                type: "text",
                null: true,
              },
              {
                name: "ip",
                type: "inet",
                null: true,
              },
              {
                name: "tag",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "sessions_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "sessions_not_after_idx",
                attrs: [["not_after"]],
                definition: "btree (not_after DESC)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "sessions_user_id_idx",
                attrs: [["user_id"]],
                definition: "btree (user_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "user_id_created_at_idx",
                attrs: [["user_id"], ["created_at"]],
                definition: "btree (user_id, created_at)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "Auth: Stores session data associated to a user.",
            stats: {
              sizeIdx: 8192,
              scanSeq: 12,
            },
          },
          {
            schema: "auth",
            name: "sso_domains",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "sso_provider_id",
                type: "uuid",
              },
              {
                name: "domain",
                type: "text",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
            ],
            pk: {
              name: "sso_domains_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "sso_domains_domain_idx",
                attrs: [["*expression*"]],
                unique: true,
                definition: "btree (lower(domain))",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "sso_domains_sso_provider_id_idx",
                attrs: [["sso_provider_id"]],
                definition: "btree (sso_provider_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "domain not empty",
                attrs: [["domain"]],
                predicate: "CHECK (char_length(domain) > 0)",
              },
            ],
            doc: "Auth: Manages SSO email address domain mapping to an SSO Identity Provider.",
            stats: {
              scanSeq: 11,
            },
          },
          {
            schema: "auth",
            name: "sso_providers",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "resource_id",
                type: "text",
                null: true,
                doc: "Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
            ],
            pk: {
              name: "sso_providers_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "sso_providers_resource_id_idx",
                attrs: [["*expression*"]],
                unique: true,
                definition: "btree (lower(resource_id))",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "resource_id not empty",
                attrs: [["resource_id"]],
                predicate:
                  "CHECK (resource_id = NULL::text OR char_length(resource_id) > 0)",
              },
            ],
            doc: "Auth: Manages SSO identity provider information; see saml_providers for SAML.",
            stats: {
              scanSeq: 10,
            },
          },
          {
            schema: "auth",
            name: "users",
            attrs: [
              {
                name: "instance_id",
                type: "uuid",
                null: true,
              },
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "aud",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "role",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "email",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "encrypted_password",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "email_confirmed_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "invited_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "confirmation_token",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "confirmation_sent_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "recovery_token",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "recovery_sent_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "email_change_token_new",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "email_change",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "email_change_sent_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "last_sign_in_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "raw_app_meta_data",
                type: "jsonb",
                null: true,
              },
              {
                name: "raw_user_meta_data",
                type: "jsonb",
                null: true,
              },
              {
                name: "is_super_admin",
                type: "boolean",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "phone",
                type: "text",
                null: true,
                default: "NULL::character varying",
              },
              {
                name: "phone_confirmed_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "phone_change",
                type: "text",
                null: true,
                default: "''::character varying",
              },
              {
                name: "phone_change_token",
                type: "character varying(255)",
                null: true,
                default: "''::character varying",
              },
              {
                name: "phone_change_sent_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "confirmed_at",
                type: "timestamp with time zone",
                null: true,
                gen: true,
                default: "LEAST(email_confirmed_at, phone_confirmed_at)",
              },
              {
                name: "email_change_token_current",
                type: "character varying(255)",
                null: true,
                default: "''::character varying",
              },
              {
                name: "email_change_confirm_status",
                type: "smallint",
                null: true,
                default: "0",
              },
              {
                name: "banned_until",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "reauthentication_token",
                type: "character varying(255)",
                null: true,
                default: "''::character varying",
              },
              {
                name: "reauthentication_sent_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "is_sso_user",
                type: "boolean",
                default: "false",
                doc: "Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.",
              },
              {
                name: "deleted_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "is_anonymous",
                type: "boolean",
                default: "false",
              },
            ],
            pk: {
              name: "users_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "confirmation_token_idx",
                attrs: [["confirmation_token"]],
                unique: true,
                partial: "((confirmation_token)::text !~ '^[0-9 ]*$'::text)",
                definition:
                  "btree (confirmation_token) WHERE confirmation_token::text !~ '^[0-9 ]*$'::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "email_change_token_current_idx",
                attrs: [["email_change_token_current"]],
                unique: true,
                partial:
                  "((email_change_token_current)::text !~ '^[0-9 ]*$'::text)",
                definition:
                  "btree (email_change_token_current) WHERE email_change_token_current::text !~ '^[0-9 ]*$'::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "email_change_token_new_idx",
                attrs: [["email_change_token_new"]],
                unique: true,
                partial:
                  "((email_change_token_new)::text !~ '^[0-9 ]*$'::text)",
                definition:
                  "btree (email_change_token_new) WHERE email_change_token_new::text !~ '^[0-9 ]*$'::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "reauthentication_token_idx",
                attrs: [["reauthentication_token"]],
                unique: true,
                partial:
                  "((reauthentication_token)::text !~ '^[0-9 ]*$'::text)",
                definition:
                  "btree (reauthentication_token) WHERE reauthentication_token::text !~ '^[0-9 ]*$'::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "recovery_token_idx",
                attrs: [["recovery_token"]],
                unique: true,
                partial: "((recovery_token)::text !~ '^[0-9 ]*$'::text)",
                definition:
                  "btree (recovery_token) WHERE recovery_token::text !~ '^[0-9 ]*$'::text",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "users_email_partial_key",
                attrs: [["email"]],
                unique: true,
                partial: "(is_sso_user = false)",
                definition: "btree (email) WHERE is_sso_user = false",
                doc: "Auth: A partial unique index that applies only when is_sso_user is false",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "users_instance_id_email_idx",
                attrs: [["instance_id"], ["*expression*"]],
                definition: "btree (instance_id, lower(email::text))",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "users_instance_id_idx",
                attrs: [["instance_id"]],
                definition: "btree (instance_id)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "users_is_anonymous_idx",
                attrs: [["is_anonymous"]],
                definition: "btree (is_anonymous)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "users_phone_key",
                attrs: [["phone"]],
                unique: true,
                definition: "btree (phone)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "users_email_change_confirm_status_check",
                attrs: [["email_change_confirm_status"]],
                predicate:
                  "CHECK (email_change_confirm_status >= 0 AND email_change_confirm_status <= 2)",
              },
            ],
            doc: "Auth: Stores user login data within a secure schema.",
            stats: {
              size: 8192,
              sizeIdx: 81920,
              scanSeq: 28,
              scanIdx: 18,
            },
          },
          {
            schema: "extensions",
            name: "pg_stat_statements",
            kind: "view",
            def: " SELECT pg_stat_statements.userid,\n    pg_stat_statements.dbid,\n    pg_stat_statements.toplevel,\n    pg_stat_statements.queryid,\n    pg_stat_statements.query,\n    pg_stat_statements.plans,\n    pg_stat_statements.total_plan_time,\n    pg_stat_statements.min_plan_time,\n    pg_stat_statements.max_plan_time,\n    pg_stat_statements.mean_plan_time,\n    pg_stat_statements.stddev_plan_time,\n    pg_stat_statements.calls,\n    pg_stat_statements.total_exec_time,\n    pg_stat_statements.min_exec_time,\n    pg_stat_statements.max_exec_time,\n    pg_stat_statements.mean_exec_time,\n    pg_stat_statements.stddev_exec_time,\n    pg_stat_statements.rows,\n    pg_stat_statements.shared_blks_hit,\n    pg_stat_statements.shared_blks_read,\n    pg_stat_statements.shared_blks_dirtied,\n    pg_stat_statements.shared_blks_written,\n    pg_stat_statements.local_blks_hit,\n    pg_stat_statements.local_blks_read,\n    pg_stat_statements.local_blks_dirtied,\n    pg_stat_statements.local_blks_written,\n    pg_stat_statements.temp_blks_read,\n    pg_stat_statements.temp_blks_written,\n    pg_stat_statements.blk_read_time,\n    pg_stat_statements.blk_write_time,\n    pg_stat_statements.temp_blk_read_time,\n    pg_stat_statements.temp_blk_write_time,\n    pg_stat_statements.wal_records,\n    pg_stat_statements.wal_fpi,\n    pg_stat_statements.wal_bytes,\n    pg_stat_statements.jit_functions,\n    pg_stat_statements.jit_generation_time,\n    pg_stat_statements.jit_inlining_count,\n    pg_stat_statements.jit_inlining_time,\n    pg_stat_statements.jit_optimization_count,\n    pg_stat_statements.jit_optimization_time,\n    pg_stat_statements.jit_emission_count,\n    pg_stat_statements.jit_emission_time\n   FROM pg_stat_statements(true) pg_stat_statements(userid, dbid, toplevel, queryid, query, plans, total_plan_time, min_plan_time, max_plan_time, mean_plan_time, stddev_plan_time, calls, total_exec_time, min_exec_time, max_exec_time, mean_exec_time, stddev_exec_time, rows, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time, blk_write_time, temp_blk_read_time, temp_blk_write_time, wal_records, wal_fpi, wal_bytes, jit_functions, jit_generation_time, jit_inlining_count, jit_inlining_time, jit_optimization_count, jit_optimization_time, jit_emission_count, jit_emission_time);",
            attrs: [
              {
                name: "userid",
                type: "oid",
                null: true,
              },
              {
                name: "dbid",
                type: "oid",
                null: true,
              },
              {
                name: "toplevel",
                type: "boolean",
                null: true,
              },
              {
                name: "queryid",
                type: "bigint",
                null: true,
              },
              {
                name: "query",
                type: "text",
                null: true,
              },
              {
                name: "plans",
                type: "bigint",
                null: true,
              },
              {
                name: "total_plan_time",
                type: "double precision",
                null: true,
              },
              {
                name: "min_plan_time",
                type: "double precision",
                null: true,
              },
              {
                name: "max_plan_time",
                type: "double precision",
                null: true,
              },
              {
                name: "mean_plan_time",
                type: "double precision",
                null: true,
              },
              {
                name: "stddev_plan_time",
                type: "double precision",
                null: true,
              },
              {
                name: "calls",
                type: "bigint",
                null: true,
              },
              {
                name: "total_exec_time",
                type: "double precision",
                null: true,
              },
              {
                name: "min_exec_time",
                type: "double precision",
                null: true,
              },
              {
                name: "max_exec_time",
                type: "double precision",
                null: true,
              },
              {
                name: "mean_exec_time",
                type: "double precision",
                null: true,
              },
              {
                name: "stddev_exec_time",
                type: "double precision",
                null: true,
              },
              {
                name: "rows",
                type: "bigint",
                null: true,
              },
              {
                name: "shared_blks_hit",
                type: "bigint",
                null: true,
              },
              {
                name: "shared_blks_read",
                type: "bigint",
                null: true,
              },
              {
                name: "shared_blks_dirtied",
                type: "bigint",
                null: true,
              },
              {
                name: "shared_blks_written",
                type: "bigint",
                null: true,
              },
              {
                name: "local_blks_hit",
                type: "bigint",
                null: true,
              },
              {
                name: "local_blks_read",
                type: "bigint",
                null: true,
              },
              {
                name: "local_blks_dirtied",
                type: "bigint",
                null: true,
              },
              {
                name: "local_blks_written",
                type: "bigint",
                null: true,
              },
              {
                name: "temp_blks_read",
                type: "bigint",
                null: true,
              },
              {
                name: "temp_blks_written",
                type: "bigint",
                null: true,
              },
              {
                name: "blk_read_time",
                type: "double precision",
                null: true,
              },
              {
                name: "blk_write_time",
                type: "double precision",
                null: true,
              },
              {
                name: "temp_blk_read_time",
                type: "double precision",
                null: true,
              },
              {
                name: "temp_blk_write_time",
                type: "double precision",
                null: true,
              },
              {
                name: "wal_records",
                type: "bigint",
                null: true,
              },
              {
                name: "wal_fpi",
                type: "bigint",
                null: true,
              },
              {
                name: "wal_bytes",
                type: "numeric",
                null: true,
              },
              {
                name: "jit_functions",
                type: "bigint",
                null: true,
              },
              {
                name: "jit_generation_time",
                type: "double precision",
                null: true,
              },
              {
                name: "jit_inlining_count",
                type: "bigint",
                null: true,
              },
              {
                name: "jit_inlining_time",
                type: "double precision",
                null: true,
              },
              {
                name: "jit_optimization_count",
                type: "bigint",
                null: true,
              },
              {
                name: "jit_optimization_time",
                type: "double precision",
                null: true,
              },
              {
                name: "jit_emission_count",
                type: "bigint",
                null: true,
              },
              {
                name: "jit_emission_time",
                type: "double precision",
                null: true,
              },
            ],
          },
          {
            schema: "extensions",
            name: "pg_stat_statements_info",
            kind: "view",
            def: " SELECT pg_stat_statements_info.dealloc,\n    pg_stat_statements_info.stats_reset\n   FROM pg_stat_statements_info() pg_stat_statements_info(dealloc, stats_reset);",
            attrs: [
              {
                name: "dealloc",
                type: "bigint",
                null: true,
              },
              {
                name: "stats_reset",
                type: "timestamp with time zone",
                null: true,
              },
            ],
          },
          {
            schema: "pgsodium",
            name: "decrypted_key",
            kind: "view",
            def: " SELECT key.id,\n    key.status,\n    key.created,\n    key.expires,\n    key.key_type,\n    key.key_id,\n    key.key_context,\n    key.name,\n    key.associated_data,\n    key.raw_key,\n        CASE\n            WHEN key.raw_key IS NULL THEN NULL::bytea\n            ELSE\n            CASE\n                WHEN key.parent_key IS NULL THEN NULL::bytea\n                ELSE pgsodium.crypto_aead_det_decrypt(key.raw_key, convert_to(key.id::text || key.associated_data, 'utf8'::name), key.parent_key, key.raw_key_nonce)\n            END\n        END AS decrypted_raw_key,\n    key.raw_key_nonce,\n    key.parent_key,\n    key.comment\n   FROM pgsodium.key;",
            attrs: [
              {
                name: "id",
                type: "uuid",
                null: true,
              },
              {
                name: "status",
                type: "pgsodium.key_status",
                null: true,
              },
              {
                name: "created",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "expires",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "key_type",
                type: "pgsodium.key_type",
                null: true,
              },
              {
                name: "key_id",
                type: "bigint",
                null: true,
              },
              {
                name: "key_context",
                type: "bytea",
                null: true,
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "associated_data",
                type: "text",
                null: true,
              },
              {
                name: "raw_key",
                type: "bytea",
                null: true,
              },
              {
                name: "decrypted_raw_key",
                type: "bytea",
                null: true,
              },
              {
                name: "raw_key_nonce",
                type: "bytea",
                null: true,
              },
              {
                name: "parent_key",
                type: "uuid",
                null: true,
              },
              {
                name: "comment",
                type: "text",
                null: true,
              },
            ],
          },
          {
            schema: "pgsodium",
            name: "key",
            attrs: [
              {
                name: "id",
                type: "uuid",
                default: "gen_random_uuid()",
              },
              {
                name: "status",
                type: "pgsodium.key_status",
                null: true,
                default: "'valid'::pgsodium.key_status",
              },
              {
                name: "created",
                type: "timestamp with time zone",
                default: "CURRENT_TIMESTAMP",
              },
              {
                name: "expires",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "key_type",
                type: "pgsodium.key_type",
                null: true,
              },
              {
                name: "key_id",
                type: "bigint",
                null: true,
                default: "nextval('pgsodium.key_key_id_seq'::regclass)",
              },
              {
                name: "key_context",
                type: "bytea",
                null: true,
                default: "'\\x7067736f6469756d'::bytea",
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "associated_data",
                type: "text",
                null: true,
                default: "'associated'::text",
              },
              {
                name: "raw_key",
                type: "bytea",
                null: true,
              },
              {
                name: "raw_key_nonce",
                type: "bytea",
                null: true,
              },
              {
                name: "parent_key",
                type: "uuid",
                null: true,
              },
              {
                name: "comment",
                type: "text",
                null: true,
              },
              {
                name: "user_data",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "key_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "key_key_id_key_context_key_type_idx",
                attrs: [["key_id"], ["key_context"], ["key_type"]],
                unique: true,
                definition: "btree (key_id, key_context, key_type)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "key_status_idx",
                attrs: [["status"]],
                partial:
                  "(status = ANY (ARRAY['valid'::pgsodium.key_status, 'default'::pgsodium.key_status]))",
                definition:
                  "btree (status) WHERE status = ANY (ARRAY['valid'::pgsodium.key_status, 'default'::pgsodium.key_status])",
                stats: {
                  size: 0,
                  scans: 2,
                },
              },
              {
                name: "key_status_idx1",
                attrs: [["status"]],
                unique: true,
                partial: "(status = 'default'::pgsodium.key_status)",
                definition:
                  "btree (status) WHERE status = 'default'::pgsodium.key_status",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "pgsodium_key_unique_name",
                attrs: [["name"]],
                unique: true,
                definition: "btree (name)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            checks: [
              {
                name: "key_key_context_check",
                attrs: [["key_context"]],
                predicate: "CHECK (length(key_context) = 8)",
              },
              {
                name: "pgsodium_raw",
                attrs: [
                  ["raw_key"],
                  ["key_id"],
                  ["key_context"],
                  ["parent_key"],
                ],
                predicate:
                  "CHECK (\nCASE\n    WHEN raw_key IS NOT NULL THEN key_id IS NULL AND key_context IS NULL AND parent_key IS NOT NULL\n    ELSE key_id IS NOT NULL AND key_context IS NOT NULL AND parent_key IS NULL\nEND)",
              },
            ],
            doc: "This table holds metadata for derived keys given a key_id and key_context. The raw key is never stored.",
            stats: {
              sizeIdx: 40960,
              scanSeq: 16,
              scanIdx: 2,
            },
          },
          {
            schema: "pgsodium",
            name: "mask_columns",
            kind: "view",
            def: " SELECT a.attname,\n    a.attrelid,\n    m.key_id,\n    m.key_id_column,\n    m.associated_columns,\n    m.nonce_column,\n    m.format_type\n   FROM pg_attribute a\n     LEFT JOIN pgsodium.masking_rule m ON m.attrelid = a.attrelid AND m.attname = a.attname\n  WHERE a.attnum > 0 AND NOT a.attisdropped\n  ORDER BY a.attnum;",
            attrs: [
              {
                name: "attname",
                type: "name",
                null: true,
              },
              {
                name: "attrelid",
                type: "oid",
                null: true,
              },
              {
                name: "key_id",
                type: "text",
                null: true,
              },
              {
                name: "key_id_column",
                type: "text",
                null: true,
              },
              {
                name: "associated_columns",
                type: "text",
                null: true,
              },
              {
                name: "nonce_column",
                type: "text",
                null: true,
              },
              {
                name: "format_type",
                type: "text",
                null: true,
              },
            ],
          },
          {
            schema: "pgsodium",
            name: "masking_rule",
            kind: "view",
            def: " WITH const AS (\n         SELECT 'encrypt +with +key +id +([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'::text AS pattern_key_id,\n            'encrypt +with +key +column +([\\w\\\"\\-$]+)'::text AS pattern_key_id_column,\n            '(?<=associated) +\\(([\\w\\\"\\-$, ]+)\\)'::text AS pattern_associated_columns,\n            '(?<=nonce) +([\\w\\\"\\-$]+)'::text AS pattern_nonce_column,\n            '(?<=decrypt with view) +([\\w\\\"\\-$]+\\.[\\w\\\"\\-$]+)'::text AS pattern_view_name,\n            '(?<=security invoker)'::text AS pattern_security_invoker\n        ), rules_from_seclabels AS (\n         SELECT sl.objoid AS attrelid,\n            sl.objsubid AS attnum,\n            c.relnamespace::regnamespace AS relnamespace,\n            c.relname,\n            a.attname,\n            format_type(a.atttypid, a.atttypmod) AS format_type,\n            sl.label AS col_description,\n            (regexp_match(sl.label, k.pattern_key_id_column, 'i'::text))[1] AS key_id_column,\n            (regexp_match(sl.label, k.pattern_key_id, 'i'::text))[1] AS key_id,\n            (regexp_match(sl.label, k.pattern_associated_columns, 'i'::text))[1] AS associated_columns,\n            (regexp_match(sl.label, k.pattern_nonce_column, 'i'::text))[1] AS nonce_column,\n            COALESCE((regexp_match(sl2.label, k.pattern_view_name, 'i'::text))[1], (c.relnamespace::regnamespace || '.'::text) || quote_ident('decrypted_'::text || c.relname::text)) AS view_name,\n            100 AS priority,\n            (regexp_match(sl.label, k.pattern_security_invoker, 'i'::text))[1] IS NOT NULL AS security_invoker\n           FROM const k,\n            pg_seclabel sl\n             JOIN pg_class c ON sl.classoid = c.tableoid AND sl.objoid = c.oid\n             JOIN pg_attribute a ON a.attrelid = c.oid AND sl.objsubid = a.attnum\n             LEFT JOIN pg_seclabel sl2 ON sl2.objoid = c.oid AND sl2.objsubid = 0\n          WHERE a.attnum > 0 AND c.relnamespace::regnamespace::oid <> 'pg_catalog'::regnamespace::oid AND NOT a.attisdropped AND sl.label ~~* 'ENCRYPT%'::text AND sl.provider = 'pgsodium'::text\n        )\n SELECT DISTINCT ON (rules_from_seclabels.attrelid, rules_from_seclabels.attnum) rules_from_seclabels.attrelid,\n    rules_from_seclabels.attnum,\n    rules_from_seclabels.relnamespace,\n    rules_from_seclabels.relname,\n    rules_from_seclabels.attname,\n    rules_from_seclabels.format_type,\n    rules_from_seclabels.col_description,\n    rules_from_seclabels.key_id_column,\n    rules_from_seclabels.key_id,\n    rules_from_seclabels.associated_columns,\n    rules_from_seclabels.nonce_column,\n    rules_from_seclabels.view_name,\n    rules_from_seclabels.priority,\n    rules_from_seclabels.security_invoker\n   FROM rules_from_seclabels\n  ORDER BY rules_from_seclabels.attrelid, rules_from_seclabels.attnum, rules_from_seclabels.priority DESC;",
            attrs: [
              {
                name: "attrelid",
                type: "oid",
                null: true,
              },
              {
                name: "attnum",
                type: "integer",
                null: true,
              },
              {
                name: "relnamespace",
                type: "regnamespace",
                null: true,
              },
              {
                name: "relname",
                type: "name",
                null: true,
              },
              {
                name: "attname",
                type: "name",
                null: true,
              },
              {
                name: "format_type",
                type: "text",
                null: true,
              },
              {
                name: "col_description",
                type: "text",
                null: true,
              },
              {
                name: "key_id_column",
                type: "text",
                null: true,
              },
              {
                name: "key_id",
                type: "text",
                null: true,
              },
              {
                name: "associated_columns",
                type: "text",
                null: true,
              },
              {
                name: "nonce_column",
                type: "text",
                null: true,
              },
              {
                name: "view_name",
                type: "text",
                null: true,
              },
              {
                name: "priority",
                type: "integer",
                null: true,
              },
              {
                name: "security_invoker",
                type: "boolean",
                null: true,
              },
            ],
          },
          {
            schema: "pgsodium",
            name: "valid_key",
            kind: "view",
            def: " SELECT key.id,\n    key.name,\n    key.status,\n    key.key_type,\n    key.key_id,\n    key.key_context,\n    key.created,\n    key.expires,\n    key.associated_data\n   FROM pgsodium.key\n  WHERE (key.status = ANY (ARRAY['valid'::pgsodium.key_status, 'default'::pgsodium.key_status])) AND\n        CASE\n            WHEN key.expires IS NULL THEN true\n            ELSE key.expires > now()\n        END;",
            attrs: [
              {
                name: "id",
                type: "uuid",
                null: true,
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "status",
                type: "pgsodium.key_status",
                null: true,
              },
              {
                name: "key_type",
                type: "pgsodium.key_type",
                null: true,
              },
              {
                name: "key_id",
                type: "bigint",
                null: true,
              },
              {
                name: "key_context",
                type: "bytea",
                null: true,
              },
              {
                name: "created",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "expires",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "associated_data",
                type: "text",
                null: true,
              },
            ],
          },
          {
            schema: "public",
            name: "clever_cloud_resources",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "addon_id",
                type: "character varying(255)",
              },
              {
                name: "owner_id",
                type: "character varying(255)",
              },
              {
                name: "owner_name",
                type: "character varying(255)",
              },
              {
                name: "user_id",
                type: "character varying(255)",
              },
              {
                name: "plan",
                type: "character varying(255)",
              },
              {
                name: "region",
                type: "character varying(255)",
              },
              {
                name: "callback_url",
                type: "character varying(255)",
              },
              {
                name: "logplex_token",
                type: "character varying(255)",
              },
              {
                name: "options",
                type: "jsonb",
                null: true,
              },
              {
                name: "organization_id",
                type: "uuid",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "deleted_at",
                type: "timestamp without time zone",
                null: true,
              },
            ],
            pk: {
              name: "clever_cloud_resources_pkey",
              attrs: [["id"]],
            },
            stats: {
              rows: 1,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 90,
              analyzeLag: 1,
              vacuumLag: 1,
            },
          },
          {
            schema: "public",
            name: "events",
            attrs: [
              {
                name: "id",
                type: "uuid",
                stats: {
                  bytesAvg: 16,
                  cardinality: 53,
                  histogram: [
                    "020e1ad2-a538-4433-883a-ff241b302313",
                    "043d6e5c-52bc-47c8-9e79-2fbbd034efdc",
                    "04434b2e-ffb3-4e27-b38c-f49d5a8c77a9",
                    "06589410-8653-415f-95c0-23faa71e51e0",
                    "0c3a99bf-d7c3-4c36-9578-00d613d8ebc9",
                    "10b16f53-8eec-48e0-8e94-b9635a7ee5c5",
                    "13c6fea4-60ba-466c-8c93-b9ef6ef6374d",
                    "14b205bf-ed9d-4530-849a-fe3eed577fa0",
                    "23cfdce2-403d-4664-9e15-147bc90a0dbc",
                    "27cc5ede-0e12-465c-b221-04903c64ac1a",
                    "31515b37-400c-4b25-bb5e-2d6ed6ea2bfd",
                    "33e94556-7a72-4dd5-bf4b-e4126e5885d3",
                    "340906e4-181f-4d35-8262-1aafa1e6e076",
                    "347a2b12-f99f-4cee-8c82-661220a7bca5",
                    "373bdd6d-e761-4665-9151-7d882155f8d5",
                    "3a9a6684-3b39-4cde-97db-15bdad46bae0",
                    "432c17b1-8114-454d-a5ad-b42fbd156653",
                    "47850809-fd0c-4de3-b452-675046358fcb",
                    "49b8e039-7231-41fc-b59b-facbf47ee76e",
                    "4f776211-9a53-4829-b848-be3ac4020292",
                    "523175cb-27bd-41aa-a00e-982e95c48c9e",
                    "544ec09b-0dab-45a6-bf03-c09226d72739",
                    "58f296dd-fc69-47e1-a397-eac445e55749",
                    "5bf8f834-c6b2-4a3f-ada9-be3ad1a3682f",
                    "6079cf68-2995-449b-a5b9-8f9edf330757",
                    "627ce0df-bd92-4f75-9260-c338d707c90b",
                    "6597d54e-f20d-46fa-a8f4-c25e206365df",
                    "6885e72b-0b48-42e3-a5bd-8520e385d72c",
                    "688677bf-2759-4c0a-b040-36e2b1acffdc",
                    "6cb85e21-66c2-48ab-a8b1-09b8d203a20e",
                    "6d4272ea-0966-43b8-b769-86c32f057c16",
                    "712bf7a9-865d-4d8b-b758-431efde3a208",
                    "75ceb024-b343-4cfe-854e-f5e53771096d",
                    "7c21a115-fb3c-46dc-ba3a-2eb53fa62b93",
                    "8069a381-9c60-4abb-a142-e1a45b4557da",
                    "88778893-1578-4b24-b467-cced4202515a",
                    "8ad43d7b-38d7-4320-8d9f-58726f00400d",
                    "92e158ed-0d7e-407a-8538-497fb999bd75",
                    "98807650-e1f7-4e76-844f-1d87c48cefc5",
                    "9a1cecd7-b7ad-4d22-aedc-a416f5b6fb9b",
                    "a458e4ca-0e02-4a7a-be4d-35e21294eb21",
                    "a678306e-eb03-4fe9-8b7d-0775850923e6",
                    "a8091dd7-966d-416d-b72f-da631cf98704",
                    "ac6b54e6-e08c-4482-b600-75714ddf5dc9",
                    "caa57c9e-cbe3-433d-804f-87b63d152a68",
                    "cc0fb66e-4fff-4235-8efb-14d2cea41906",
                    "cf2c5847-5104-4024-82ee-77786a284654",
                    "d699e64c-48d0-4658-8c5b-44e3375fb0a4",
                    "e457ead2-c1dc-4007-9b65-134a2c6e01f7",
                    "e561e879-e6e2-4d65-971c-5eb7d8df73da",
                    "f2544155-db79-4255-a152-f58823287dad",
                    "f86c779e-cad6-493b-8353-06f4f01d5144",
                    "fac54c3e-45fb-4e6b-acbf-395aee0fb9bc",
                  ],
                },
              },
              {
                name: "name",
                type: "character varying(255)",
                stats: {
                  bytesAvg: 20,
                  cardinality: 16.000011,
                  commonValues: [
                    {
                      value: "user_onboarding",
                      freq: 0.509434,
                    },
                    {
                      value: "editor__table__shown",
                      freq: 0.0754717,
                    },
                    {
                      value: "editor__detail_sidebar__opened",
                      freq: 0.0566038,
                    },
                    {
                      value: "editor_source_creation_error",
                      freq: 0.0566038,
                    },
                    {
                      value: "data_explorer__query__opened",
                      freq: 0.0377358,
                    },
                    {
                      value: "data_explorer__query__result",
                      freq: 0.0377358,
                    },
                    {
                      value: "editor__data_explorer__opened",
                      freq: 0.0377358,
                    },
                    {
                      value: "organization_loaded",
                      freq: 0.0377358,
                    },
                  ],
                  histogram: [
                    "editor__detail_sidebar__closed",
                    "editor_project_draft_created",
                    "editor_source_created",
                    "plan_limit",
                    "project_created",
                    "project_loaded",
                    "user_created",
                    "user_login",
                  ],
                },
              },
              {
                name: "data",
                type: "jsonb",
                null: true,
                doc: "event entity data",
                stats: {
                  nulls: 0.396226,
                  bytesAvg: 287,
                  cardinality: 3,
                  commonValues: [
                    {
                      value: {
                        data: {
                          attributed_to: null,
                        },
                        name: "Anthony",
                        slug: "anthony",
                        email: "anthonyly.dev@gmail.com",
                        is_admin: false,
                        created_at: "2024-06-17T10:04:39.283315Z",
                        last_signin: "2024-06-17T10:04:38.609642Z",
                        github_username: null,
                        twitter_username: null,
                      },
                      freq: 0.54717,
                    },
                    {
                      value: {
                        data: null,
                        name: "Anthony",
                        slug: "anthony",
                        heroku: null,
                        members: 1,
                        projects: 0,
                        created_at: "2024-06-17T10:04:39.400356Z",
                        is_personal: true,
                        clever_cloud: null,
                        github_username: null,
                        twitter_username: null,
                        stripe_customer_id: null,
                        stripe_subscription_id: null,
                      },
                      freq: 0.0377358,
                    },
                  ],
                },
              },
              {
                name: "details",
                type: "jsonb",
                null: true,
                doc: "when additional data are needed",
                stats: {
                  nulls: 0.0566038,
                  bytesAvg: 117,
                  cardinality: 38.999997,
                  commonValues: [
                    {
                      value: {
                        step: "community",
                      },
                      freq: 0.0566038,
                    },
                    {
                      value: {
                        role: "Software Engineer",
                        step: "role",
                      },
                      freq: 0.0566038,
                    },
                    {
                      value: {
                        $lib: "front",
                        error: "Can't build source",
                        format: "database",
                        $current_url:
                          "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/new?database=",
                      },
                      freq: 0.0566038,
                    },
                    {
                      value: {
                        step: "about_you",
                      },
                      freq: 0.0377358,
                    },
                    {
                      value: {
                        step: "welcome",
                      },
                      freq: 0.0377358,
                    },
                    {
                      value: {
                        $lib: "front",
                        from: "relation",
                        nb_tables: 1,
                        $current_url:
                          "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                      },
                      freq: 0.0377358,
                    },
                    {
                      value: {
                        db: "postgres",
                        $lib: "front",
                        query: "exploreTable",
                        $current_url:
                          "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                      },
                      freq: 0.0377358,
                    },
                    {
                      value: {
                        db: "postgres",
                        $lib: "front",
                        query: "exploreTable",
                        nb_sources: 1,
                        $current_url:
                          "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                        nb_db_sources: 1,
                      },
                      freq: 0.0377358,
                    },
                  ],
                  histogram: [
                    {
                      method: "password",
                    },
                    {
                      step: "about_your_company",
                    },
                    {
                      step: "discovered_azimutt",
                    },
                    {
                      step: "explore_or_design",
                    },
                    {
                      step: "finalize",
                    },
                    {
                      step: "keep_in_touch",
                    },
                    {
                      step: "plan",
                    },
                    {
                      step: "previous_solutions",
                    },
                    {
                      step: "role",
                    },
                    {
                      step: "solo_or_team",
                    },
                    {
                      $lib: "front",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      step: "discovered_azimutt",
                      discovered_by: "twitter",
                    },
                    {
                      step: "explore_or_design",
                      usecase: "explore",
                    },
                    {
                      step: "keep_in_touch",
                      product_updates: "false",
                    },
                    {
                      step: "previous_solutions",
                      previously_tried: [
                        "drawing-tool",
                        "sql-client",
                        "desktop-erd",
                        "online-erd",
                      ],
                    },
                    {
                      step: "solo_or_team",
                      usage: "solo",
                    },
                    {
                      $lib: "front",
                      level: "schema",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      $lib: "front",
                      level: "table",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      $lib: "front",
                      level: "table-list",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      method: "password",
                      azimutt_id: "bb391fc1-8bac-4e32-9dbd-23854aabb832",
                      attribution: null,
                    },
                    {
                      $lib: "front",
                      from: "details",
                      nb_tables: 1,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      $lib: "front",
                      from: "empty-screen",
                      nb_tables: 1,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      $lib: "front",
                      plan: "free",
                      feature: "layout_tables",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      step: "about_you",
                      phone: "+33614838296",
                      location: "France",
                      description: "",
                    },
                    {
                      step: "about_your_company",
                      company: "",
                      industry: "Technology",
                      company_size: "",
                    },
                    {
                      step: "about_your_company",
                      company: "ALY",
                      industry: "Technology",
                      company_size: "",
                    },
                    {
                      db: "postgres",
                      $lib: "front",
                      rows: 44,
                      query: "exploreTable",
                      columns: 8,
                      duration: 866,
                      column_refs: 8,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      db: "postgres",
                      $lib: "front",
                      rows: 46,
                      query: "exploreTable",
                      columns: 8,
                      duration: 708,
                      column_refs: 8,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                    },
                    {
                      $lib: "front",
                      format: "database",
                      nb_table: 47,
                      source_id: "e54b5075-efcd-48bf-853b-f694cf23c47c",
                      nb_columns: 484,
                      nb_relation: 44,
                      source_kind: "DatabaseConnection",
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/new?database=",
                      source_dialect: "postgres",
                    },
                    {
                      $lib: "front",
                      nb_memos: 0,
                      nb_notes: 0,
                      nb_types: 20,
                      nb_tables: 47,
                      nb_columns: 484,
                      nb_layouts: 1,
                      nb_sources: 1,
                      nb_comments: 52,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/00000000-0000-0000-0000-000000000000",
                      nb_relations: 44,
                    },
                    {
                      $lib: "front",
                      nb_memos: 0,
                      nb_notes: 0,
                      nb_types: 20,
                      nb_tables: 47,
                      nb_columns: 484,
                      nb_layouts: 1,
                      nb_sources: 1,
                      nb_comments: 52,
                      $current_url:
                        "http://localhost:4000/e5546f10-9ed8-456c-8e77-2434d8d30138/new?database=",
                      nb_relations: 44,
                    },
                  ],
                },
              },
              {
                name: "created_by",
                type: "uuid",
                null: true,
                stats: {
                  bytesAvg: 16,
                  cardinality: 2,
                  commonValues: [
                    {
                      value: "bb391fc1-8bac-4e32-9dbd-23854aabb832",
                      freq: 0.981132,
                    },
                  ],
                },
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
                stats: {
                  bytesAvg: 8,
                  cardinality: 53,
                  histogram: [
                    "2024-06-17T08:02:13.982Z",
                    "2024-06-17T08:04:39.551Z",
                    "2024-06-17T08:04:39.821Z",
                    "2024-06-17T08:04:41.062Z",
                    "2024-06-17T08:04:47.021Z",
                    "2024-06-17T08:04:47.920Z",
                    "2024-06-17T08:04:51.064Z",
                    "2024-06-17T08:04:51.823Z",
                    "2024-06-17T08:04:54.767Z",
                    "2024-06-17T08:04:55.611Z",
                    "2024-06-17T08:04:58.095Z",
                    "2024-06-17T08:04:58.852Z",
                    "2024-06-17T08:04:59.738Z",
                    "2024-06-17T08:05:00.804Z",
                    "2024-06-17T08:05:01.516Z",
                    "2024-06-17T08:05:13.418Z",
                    "2024-06-17T08:05:14.128Z",
                    "2024-06-17T08:05:21.288Z",
                    "2024-06-17T08:05:28.334Z",
                    "2024-06-17T08:05:28.991Z",
                    "2024-06-17T08:05:33.238Z",
                    "2024-06-17T08:05:38.121Z",
                    "2024-06-17T08:05:38.786Z",
                    "2024-06-17T08:05:54.873Z",
                    "2024-06-17T08:05:55.505Z",
                    "2024-06-17T08:05:57.833Z",
                    "2024-06-17T08:05:58.550Z",
                    "2024-06-17T08:06:00.955Z",
                    "2024-06-17T08:06:01.631Z",
                    "2024-06-17T08:06:02.617Z",
                    "2024-06-17T08:11:47.905Z",
                    "2024-06-17T08:12:29.707Z",
                    "2024-06-17T08:13:03.979Z",
                    "2024-06-17T08:13:08.111Z",
                    "2024-06-17T08:15:58.326Z",
                    "2024-06-17T08:16:22.545Z",
                    "2024-06-17T08:16:28.317Z",
                    "2024-06-17T08:16:28.618Z",
                    "2024-06-17T08:16:39.854Z",
                    "2024-06-17T08:16:53.471Z",
                    "2024-06-17T08:16:58.791Z",
                    "2024-06-17T08:17:03.361Z",
                    "2024-06-17T08:17:08.639Z",
                    "2024-06-17T08:17:08.685Z",
                    "2024-06-17T08:17:09.606Z",
                    "2024-06-17T08:17:10.231Z",
                    "2024-06-17T08:17:10.329Z",
                    "2024-06-17T08:17:11.004Z",
                    "2024-06-17T08:17:23.618Z",
                    "2024-06-17T08:17:30.157Z",
                    "2024-06-17T08:17:35.729Z",
                    "2024-06-17T08:17:46.901Z",
                    "2024-06-17T08:17:55.674Z",
                  ],
                },
              },
              {
                name: "organization_id",
                type: "uuid",
                null: true,
                stats: {
                  nulls: 0.943396,
                  bytesAvg: 16,
                  cardinality: 2,
                  commonValues: [
                    {
                      value: "e5546f10-9ed8-456c-8e77-2434d8d30138",
                      freq: 0.0377358,
                    },
                  ],
                },
              },
              {
                name: "project_id",
                type: "uuid",
                null: true,
                doc: "no FK to keep records when projects are deleted",
                stats: {
                  nulls: 0.981132,
                  bytesAvg: 16,
                  cardinality: 0.9999987,
                },
              },
            ],
            pk: {
              name: "events_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "events_created_at_index",
                attrs: [["created_at"]],
                definition: "btree (created_at)",
                stats: {
                  size: 16384,
                  scans: 8,
                },
              },
              {
                name: "events_created_by_index",
                attrs: [["created_by"]],
                definition: "btree (created_by)",
                stats: {
                  size: 16384,
                  scans: 5,
                },
              },
              {
                name: "events_name_index",
                attrs: [["name"]],
                definition: "btree (name)",
                stats: {
                  size: 16384,
                  scans: 0,
                },
              },
              {
                name: "events_organization_id_index",
                attrs: [["organization_id"]],
                definition: "btree (organization_id)",
                stats: {
                  size: 16384,
                  scans: 2,
                },
              },
              {
                name: "events_project_id_index",
                attrs: [["project_id"]],
                definition: "btree (project_id)",
                stats: {
                  size: 16384,
                  scans: 0,
                },
              },
            ],
            stats: {
              rows: 53,
              size: 90112,
              sizeIdx: 98304,
              scanSeq: 43,
              scanIdx: 15,
              analyzeLast: "2024-06-17T10:18:35.009Z",
              vacuumLag: 53,
            },
          },
          {
            schema: "public",
            name: "gallery",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "project_id",
                type: "uuid",
              },
              {
                name: "slug",
                type: "character varying(255)",
              },
              {
                name: "icon",
                type: "character varying(255)",
              },
              {
                name: "color",
                type: "character varying(255)",
              },
              {
                name: "website",
                type: "character varying(255)",
                doc: "link for the website of the schema",
              },
              {
                name: "banner",
                type: "character varying(255)",
                doc: "banner image, 1600x900",
              },
              {
                name: "tips",
                type: "text",
                doc: "shown on project creation",
              },
              {
                name: "description",
                type: "text",
                doc: "shown on list and detail view",
              },
              {
                name: "analysis",
                type: "text",
                doc: "markdown shown on detail view",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
            ],
            pk: {
              name: "gallery_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "gallery_project_id_index",
                attrs: [["project_id"]],
                unique: true,
                definition: "btree (project_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "gallery_slug_index",
                attrs: [["slug"]],
                unique: true,
                definition: "btree (slug)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            stats: {
              rows: 1,
              size: 8192,
              sizeIdx: 49152,
              scanSeq: 14,
              analyzeLag: 1,
              vacuumLag: 1,
            },
          },
          {
            schema: "public",
            name: "heroku_resources",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "app",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "plan",
                type: "character varying(255)",
              },
              {
                name: "region",
                type: "character varying(255)",
              },
              {
                name: "options",
                type: "jsonb",
                null: true,
              },
              {
                name: "callback",
                type: "character varying(255)",
              },
              {
                name: "oauth_code",
                type: "uuid",
              },
              {
                name: "oauth_type",
                type: "character varying(255)",
              },
              {
                name: "oauth_expire",
                type: "timestamp without time zone",
              },
              {
                name: "organization_id",
                type: "uuid",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "deleted_at",
                type: "timestamp without time zone",
                null: true,
              },
            ],
            pk: {
              name: "heroku_resources_pkey",
              attrs: [["id"]],
            },
            stats: {
              rows: 1,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 90,
              analyzeLag: 1,
              vacuumLag: 1,
            },
          },
          {
            schema: "public",
            name: "organization_invitations",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "sent_to",
                type: "character varying(255)",
                doc: "email to send the invitation",
              },
              {
                name: "organization_id",
                type: "uuid",
              },
              {
                name: "expire_at",
                type: "timestamp without time zone",
              },
              {
                name: "created_by",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "cancel_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "answered_by",
                type: "uuid",
                null: true,
              },
              {
                name: "refused_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "accepted_at",
                type: "timestamp without time zone",
                null: true,
              },
            ],
            pk: {
              name: "organization_invitations_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "organization_invitations_organization_id_index",
                attrs: [["organization_id"]],
                definition: "btree (organization_id)",
                stats: {
                  size: 8192,
                  scans: 5,
                },
              },
            ],
            stats: {
              sizeIdx: 16384,
              scanSeq: 11,
              scanIdx: 5,
            },
          },
          {
            schema: "public",
            name: "organization_members",
            attrs: [
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "organization_id",
                type: "uuid",
              },
              {
                name: "created_by",
                type: "uuid",
              },
              {
                name: "updated_by",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
            ],
            pk: {
              name: "organization_members_pkey",
              attrs: [["user_id"], ["organization_id"]],
            },
            stats: {
              rows: 3,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 10,
              scanIdx: 86,
              analyzeLag: 3,
              vacuumLag: 3,
            },
          },
          {
            schema: "public",
            name: "organizations",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "slug",
                type: "character varying(255)",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "logo",
                type: "character varying(255)",
              },
              {
                name: "description",
                type: "text",
                null: true,
              },
              {
                name: "github_username",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "twitter_username",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "stripe_customer_id",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "stripe_subscription_id",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "is_personal",
                type: "boolean",
                doc: "mimic user accounts when true",
              },
              {
                name: "created_by",
                type: "uuid",
              },
              {
                name: "updated_by",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "deleted_by",
                type: "uuid",
                null: true,
              },
              {
                name: "deleted_at",
                type: "timestamp without time zone",
                null: true,
                doc: "orga is cleared on deletion but kept for FKs",
              },
              {
                name: "data",
                type: "jsonb",
                null: true,
                doc: "unstructured props for orgas",
              },
            ],
            pk: {
              name: "organizations_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "organizations_slug_index",
                attrs: [["slug"]],
                unique: true,
                definition: "btree (slug)",
                stats: {
                  size: 8192,
                  scans: 3,
                },
              },
              {
                name: "organizations_stripe_customer_id_index",
                attrs: [["stripe_customer_id"]],
                unique: true,
                definition: "btree (stripe_customer_id)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            stats: {
              rows: 3,
              size: 8192,
              sizeIdx: 49152,
              scanSeq: 24,
              scanIdx: 92,
              analyzeLag: 3,
              vacuumLag: 3,
            },
          },
          {
            schema: "public",
            name: "project_tokens",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "project_id",
                type: "uuid",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "nb_access",
                type: "integer",
              },
              {
                name: "last_access",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "expire_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "revoked_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "revoked_by",
                type: "uuid",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "created_by",
                type: "uuid",
              },
            ],
            pk: {
              name: "project_tokens_pkey",
              attrs: [["id"]],
            },
            doc: "grant access to projects",
            stats: {
              scanSeq: 9,
            },
          },
          {
            schema: "public",
            name: "projects",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "organization_id",
                type: "uuid",
              },
              {
                name: "slug",
                type: "citext",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "description",
                type: "text",
                null: true,
              },
              {
                name: "encoding_version",
                type: "integer",
                doc: "encoding version for the project",
              },
              {
                name: "storage_kind",
                type: "character varying(255)",
                doc: "enum: local, remote",
              },
              {
                name: "file",
                type: "character varying(255)",
                null: true,
                doc: "stored file reference for remote projects",
              },
              {
                name: "local_owner",
                type: "uuid",
                null: true,
                doc: "user owning a local project",
              },
              {
                name: "nb_sources",
                type: "integer",
              },
              {
                name: "nb_tables",
                type: "integer",
              },
              {
                name: "nb_columns",
                type: "integer",
              },
              {
                name: "nb_relations",
                type: "integer",
              },
              {
                name: "nb_types",
                type: "integer",
                doc: "number of SQL custom types in the project",
              },
              {
                name: "nb_comments",
                type: "integer",
                doc: "number of SQL comments in the project",
              },
              {
                name: "nb_notes",
                type: "integer",
              },
              {
                name: "nb_layouts",
                type: "integer",
              },
              {
                name: "created_by",
                type: "uuid",
              },
              {
                name: "updated_by",
                type: "uuid",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "archived_by",
                type: "uuid",
                null: true,
              },
              {
                name: "archived_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "visibility",
                type: "character varying(255)",
                default: "'none'::character varying",
                doc: "enum: none, read, write",
              },
              {
                name: "nb_memos",
                type: "integer",
                default: "0",
              },
            ],
            pk: {
              name: "projects_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "projects_organization_id_slug_index",
                attrs: [["organization_id"], ["slug"]],
                unique: true,
                definition: "btree (organization_id, slug)",
                stats: {
                  size: 8192,
                  scans: 82,
                },
              },
            ],
            stats: {
              rows: 1,
              rowsDead: 1,
              size: 8192,
              sizeIdx: 32768,
              scanSeq: 18,
              scanIdx: 88,
              analyzeLag: 2,
              vacuumLag: 1,
            },
          },
          {
            schema: "public",
            name: "schema_migrations",
            attrs: [
              {
                name: "version",
                type: "bigint",
              },
              {
                name: "inserted_at",
                type: "timestamp(0) without time zone",
                null: true,
              },
            ],
            pk: {
              name: "schema_migrations_pkey",
              attrs: [["version"]],
            },
            stats: {
              rows: 14,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 105,
              analyzeLag: 14,
              vacuumLag: 14,
            },
          },
          {
            schema: "public",
            name: "user_auth_tokens",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "nb_access",
                type: "integer",
              },
              {
                name: "last_access",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "expire_at",
                type: "timestamp without time zone",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "deleted_at",
                type: "timestamp without time zone",
                null: true,
              },
            ],
            pk: {
              name: "user_auth_tokens_pkey",
              attrs: [["id"]],
            },
            stats: {
              scanSeq: 9,
            },
          },
          {
            schema: "public",
            name: "user_profiles",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "usecase",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "usage",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "role",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "location",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "description",
                type: "text",
                null: true,
              },
              {
                name: "company",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "company_size",
                type: "integer",
                null: true,
              },
              {
                name: "team_organization_id",
                type: "uuid",
                null: true,
              },
              {
                name: "plan",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "discovered_by",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "previously_tried",
                type: "character varying(255)[]",
                null: true,
              },
              {
                name: "product_updates",
                type: "boolean",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "phone",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "industry",
                type: "character varying(255)",
                null: true,
              },
            ],
            pk: {
              name: "user_profiles_pkey",
              attrs: [["id"]],
            },
            stats: {
              rows: 1,
              rowsDead: 13,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 108,
              scanIdx: 13,
              analyzeLag: 14,
              vacuumLag: 1,
            },
          },
          {
            schema: "public",
            name: "user_tokens",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "user_id",
                type: "uuid",
              },
              {
                name: "token",
                type: "bytea",
              },
              {
                name: "context",
                type: "character varying(255)",
              },
              {
                name: "sent_to",
                type: "character varying(255)",
                null: true,
                doc: "email",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
            ],
            pk: {
              name: "user_tokens_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "user_tokens_context_token_index",
                attrs: [["context"], ["token"]],
                unique: true,
                definition: "btree (context, token)",
                stats: {
                  size: 8192,
                  scans: 73,
                },
              },
              {
                name: "user_tokens_user_id_index",
                attrs: [["user_id"]],
                definition: "btree (user_id)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "needed for login/pass auth",
            stats: {
              rows: 2,
              size: 8192,
              sizeIdx: 49152,
              scanSeq: 11,
              scanIdx: 73,
              analyzeLag: 2,
              vacuumLag: 2,
            },
          },
          {
            schema: "public",
            name: "users",
            attrs: [
              {
                name: "id",
                type: "uuid",
              },
              {
                name: "slug",
                type: "citext",
                doc: "friendly id to show on url",
              },
              {
                name: "name",
                type: "character varying(255)",
              },
              {
                name: "email",
                type: "citext",
              },
              {
                name: "provider",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "provider_uid",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "avatar",
                type: "character varying(255)",
              },
              {
                name: "github_username",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "twitter_username",
                type: "character varying(255)",
                null: true,
              },
              {
                name: "is_admin",
                type: "boolean",
              },
              {
                name: "hashed_password",
                type: "character varying(255)",
                null: true,
                doc: "present only if user used login/pass auth",
              },
              {
                name: "last_signin",
                type: "timestamp without time zone",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp without time zone",
              },
              {
                name: "confirmed_at",
                type: "timestamp without time zone",
                null: true,
                doc: "on email confirm or directly for sso",
              },
              {
                name: "deleted_at",
                type: "timestamp without time zone",
                null: true,
                doc: "user is cleared on deletion but kept for FKs",
              },
              {
                name: "data",
                type: "jsonb",
                null: true,
                doc: "unstructured props for user",
              },
              {
                name: "onboarding",
                type: "character varying(255)",
                null: true,
                doc: "current onboarding step when not finished",
              },
              {
                name: "provider_data",
                type: "jsonb",
                null: true,
                doc: "connection object from provider",
              },
            ],
            pk: {
              name: "users_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "users_email_index",
                attrs: [["email"]],
                unique: true,
                definition: "btree (email)",
                stats: {
                  size: 8192,
                  scans: 11,
                },
              },
              {
                name: "users_slug_index",
                attrs: [["slug"]],
                unique: true,
                definition: "btree (slug)",
                stats: {
                  size: 8192,
                  scans: 1,
                },
              },
            ],
            stats: {
              rows: 2,
              rowsDead: 18,
              size: 8192,
              sizeIdx: 49152,
              scanSeq: 28,
              scanIdx: 213,
              analyzeLag: 20,
              vacuumLag: 2,
            },
          },
          {
            schema: "realtime",
            name: "messages",
            attrs: [
              {
                name: "id",
                type: "bigint",
                default: "nextval('realtime.messages_id_seq'::regclass)",
              },
              {
                name: "topic",
                type: "text",
              },
              {
                name: "extension",
                type: "text",
              },
              {
                name: "inserted_at",
                type: "timestamp(0) without time zone",
              },
              {
                name: "updated_at",
                type: "timestamp(0) without time zone",
              },
            ],
            pk: {
              name: "messages_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "messages_topic_index",
                attrs: [["topic"]],
                definition: "btree (topic)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            stats: {
              scanSeq: 10,
            },
          },
          {
            schema: "realtime",
            name: "schema_migrations",
            attrs: [
              {
                name: "version",
                type: "bigint",
              },
              {
                name: "inserted_at",
                type: "timestamp(0) without time zone",
                null: true,
              },
            ],
            pk: {
              name: "schema_migrations_pkey",
              attrs: [["version"]],
            },
            stats: {
              rows: 43,
              size: 8192,
              sizeIdx: 16384,
              scanSeq: 55,
              analyzeLag: 43,
              vacuumLag: 43,
            },
          },
          {
            schema: "realtime",
            name: "subscription",
            attrs: [
              {
                name: "id",
                type: "bigint",
              },
              {
                name: "subscription_id",
                type: "uuid",
              },
              {
                name: "entity",
                type: "regclass",
              },
              {
                name: "filters",
                type: "realtime.user_defined_filter[]",
                default: "'{}'::realtime.user_defined_filter[]",
              },
              {
                name: "claims",
                type: "jsonb",
              },
              {
                name: "claims_role",
                type: "regrole",
                gen: true,
                default: "realtime.to_regrole((claims ->> 'role'::text))",
              },
              {
                name: "created_at",
                type: "timestamp without time zone",
                default: "timezone('utc'::text, now())",
              },
            ],
            pk: {
              name: "pk_subscription",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "ix_realtime_subscription_entity",
                attrs: [["entity"]],
                definition: "hash (entity)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "subscription_subscription_id_entity_filters_key",
                attrs: [["subscription_id"], ["entity"], ["filters"]],
                unique: true,
                definition: "btree (subscription_id, entity, filters)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            stats: {
              sizeIdx: 81920,
              scanSeq: 3812,
            },
          },
          {
            schema: "storage",
            name: "buckets",
            attrs: [
              {
                name: "id",
                type: "text",
              },
              {
                name: "name",
                type: "text",
              },
              {
                name: "owner",
                type: "uuid",
                null: true,
                doc: "Field is deprecated, use owner_id instead",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
                default: "now()",
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
                default: "now()",
              },
              {
                name: "public",
                type: "boolean",
                null: true,
                default: "false",
              },
              {
                name: "avif_autodetection",
                type: "boolean",
                null: true,
                default: "false",
              },
              {
                name: "file_size_limit",
                type: "bigint",
                null: true,
              },
              {
                name: "allowed_mime_types",
                type: "text[]",
                null: true,
              },
              {
                name: "owner_id",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "buckets_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "bname",
                attrs: [["name"]],
                unique: true,
                definition: "btree (name)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            stats: {
              sizeIdx: 16384,
              scanSeq: 14,
            },
          },
          {
            schema: "storage",
            name: "migrations",
            attrs: [
              {
                name: "id",
                type: "integer",
              },
              {
                name: "name",
                type: "character varying(100)",
              },
              {
                name: "hash",
                type: "character varying(40)",
              },
              {
                name: "executed_at",
                type: "timestamp without time zone",
                null: true,
                default: "CURRENT_TIMESTAMP",
              },
            ],
            pk: {
              name: "migrations_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "migrations_name_key",
                attrs: [["name"]],
                unique: true,
                definition: "btree (name)",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            stats: {
              rows: 25,
              size: 8192,
              sizeIdx: 32768,
              scanSeq: 8,
              scanIdx: 2,
              analyzeLag: 25,
              vacuumLag: 25,
            },
          },
          {
            schema: "storage",
            name: "objects",
            attrs: [
              {
                name: "id",
                type: "uuid",
                default: "gen_random_uuid()",
              },
              {
                name: "bucket_id",
                type: "text",
                null: true,
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "owner",
                type: "uuid",
                null: true,
                doc: "Field is deprecated, use owner_id instead",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
                default: "now()",
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
                default: "now()",
              },
              {
                name: "last_accessed_at",
                type: "timestamp with time zone",
                null: true,
                default: "now()",
              },
              {
                name: "metadata",
                type: "jsonb",
                null: true,
              },
              {
                name: "path_tokens",
                type: "text[]",
                null: true,
                gen: true,
                default: "string_to_array(name, '/'::text)",
              },
              {
                name: "version",
                type: "text",
                null: true,
              },
              {
                name: "owner_id",
                type: "text",
                null: true,
              },
            ],
            pk: {
              name: "objects_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "bucketid_objname",
                attrs: [["bucket_id"], ["name"]],
                unique: true,
                definition: "btree (bucket_id, name)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
              {
                name: "idx_objects_bucket_id_name",
                attrs: [["bucket_id"], ["name"]],
                definition: 'btree (bucket_id, name COLLATE "C")',
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
              {
                name: "name_prefix_search",
                attrs: [["name"]],
                definition: "btree (name text_pattern_ops)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            stats: {
              sizeIdx: 32768,
              scanSeq: 3877,
            },
          },
          {
            schema: "storage",
            name: "s3_multipart_uploads",
            attrs: [
              {
                name: "id",
                type: "text",
              },
              {
                name: "in_progress_size",
                type: "bigint",
                default: "0",
              },
              {
                name: "upload_signature",
                type: "text",
              },
              {
                name: "bucket_id",
                type: "text",
              },
              {
                name: "key",
                type: "text",
              },
              {
                name: "version",
                type: "text",
              },
              {
                name: "owner_id",
                type: "text",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                default: "now()",
              },
            ],
            pk: {
              name: "s3_multipart_uploads_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "idx_multipart_uploads_list",
                attrs: [["bucket_id"], ["key"], ["created_at"]],
                definition: "btree (bucket_id, key, created_at)",
                stats: {
                  size: 0,
                  scans: 0,
                },
              },
            ],
            stats: {
              scanSeq: 13,
            },
          },
          {
            schema: "storage",
            name: "s3_multipart_uploads_parts",
            attrs: [
              {
                name: "id",
                type: "uuid",
                default: "gen_random_uuid()",
              },
              {
                name: "upload_id",
                type: "text",
              },
              {
                name: "size",
                type: "bigint",
                default: "0",
              },
              {
                name: "part_number",
                type: "integer",
              },
              {
                name: "bucket_id",
                type: "text",
              },
              {
                name: "key",
                type: "text",
              },
              {
                name: "etag",
                type: "text",
              },
              {
                name: "owner_id",
                type: "text",
                null: true,
              },
              {
                name: "version",
                type: "text",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                default: "now()",
              },
            ],
            pk: {
              name: "s3_multipart_uploads_parts_pkey",
              attrs: [["id"]],
            },
            stats: {
              scanSeq: 11,
            },
          },
          {
            schema: "vault",
            name: "decrypted_secrets",
            kind: "view",
            def: " SELECT secrets.id,\n    secrets.name,\n    secrets.description,\n    secrets.secret,\n        CASE\n            WHEN secrets.secret IS NULL THEN NULL::text\n            ELSE\n            CASE\n                WHEN secrets.key_id IS NULL THEN NULL::text\n                ELSE convert_from(pgsodium.crypto_aead_det_decrypt(decode(secrets.secret, 'base64'::text), convert_to(((secrets.id::text || secrets.description) || secrets.created_at::text) || secrets.updated_at::text, 'utf8'::name), secrets.key_id, secrets.nonce), 'utf8'::name)\n            END\n        END AS decrypted_secret,\n    secrets.key_id,\n    secrets.nonce,\n    secrets.created_at,\n    secrets.updated_at\n   FROM vault.secrets;",
            attrs: [
              {
                name: "id",
                type: "uuid",
                null: true,
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "description",
                type: "text",
                null: true,
              },
              {
                name: "secret",
                type: "text",
                null: true,
              },
              {
                name: "decrypted_secret",
                type: "text",
                null: true,
              },
              {
                name: "key_id",
                type: "uuid",
                null: true,
              },
              {
                name: "nonce",
                type: "bytea",
                null: true,
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                null: true,
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                null: true,
              },
            ],
          },
          {
            schema: "vault",
            name: "secrets",
            attrs: [
              {
                name: "id",
                type: "uuid",
                default: "gen_random_uuid()",
              },
              {
                name: "name",
                type: "text",
                null: true,
              },
              {
                name: "description",
                type: "text",
                default: "''::text",
              },
              {
                name: "secret",
                type: "text",
              },
              {
                name: "key_id",
                type: "uuid",
                null: true,
                default: "(pgsodium.create_key()).id",
              },
              {
                name: "nonce",
                type: "bytea",
                null: true,
                default: "pgsodium.crypto_aead_det_noncegen()",
              },
              {
                name: "created_at",
                type: "timestamp with time zone",
                default: "CURRENT_TIMESTAMP",
              },
              {
                name: "updated_at",
                type: "timestamp with time zone",
                default: "CURRENT_TIMESTAMP",
              },
            ],
            pk: {
              name: "secrets_pkey",
              attrs: [["id"]],
            },
            indexes: [
              {
                name: "secrets_name_idx",
                attrs: [["name"]],
                unique: true,
                partial: "(name IS NOT NULL)",
                definition: "btree (name) WHERE name IS NOT NULL",
                stats: {
                  size: 8192,
                  scans: 0,
                },
              },
            ],
            doc: "Table with encrypted `secret` column for storing sensitive information on disk.",
            stats: {
              sizeIdx: 16384,
              scanSeq: 12,
            },
          },
        ],
        relations: [
          {
            name: "identities_user_id_fkey",
            src: {
              schema: "auth",
              entity: "identities",
            },
            ref: {
              schema: "auth",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "mfa_amr_claims_session_id_fkey",
            src: {
              schema: "auth",
              entity: "mfa_amr_claims",
            },
            ref: {
              schema: "auth",
              entity: "sessions",
            },
            attrs: [
              {
                src: ["session_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "mfa_challenges_auth_factor_id_fkey",
            src: {
              schema: "auth",
              entity: "mfa_challenges",
            },
            ref: {
              schema: "auth",
              entity: "mfa_factors",
            },
            attrs: [
              {
                src: ["factor_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "mfa_factors_user_id_fkey",
            src: {
              schema: "auth",
              entity: "mfa_factors",
            },
            ref: {
              schema: "auth",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "one_time_tokens_user_id_fkey",
            src: {
              schema: "auth",
              entity: "one_time_tokens",
            },
            ref: {
              schema: "auth",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "refresh_tokens_session_id_fkey",
            src: {
              schema: "auth",
              entity: "refresh_tokens",
            },
            ref: {
              schema: "auth",
              entity: "sessions",
            },
            attrs: [
              {
                src: ["session_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "saml_providers_sso_provider_id_fkey",
            src: {
              schema: "auth",
              entity: "saml_providers",
            },
            ref: {
              schema: "auth",
              entity: "sso_providers",
            },
            attrs: [
              {
                src: ["sso_provider_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "saml_relay_states_flow_state_id_fkey",
            src: {
              schema: "auth",
              entity: "saml_relay_states",
            },
            ref: {
              schema: "auth",
              entity: "flow_state",
            },
            attrs: [
              {
                src: ["flow_state_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "saml_relay_states_sso_provider_id_fkey",
            src: {
              schema: "auth",
              entity: "saml_relay_states",
            },
            ref: {
              schema: "auth",
              entity: "sso_providers",
            },
            attrs: [
              {
                src: ["sso_provider_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "sessions_user_id_fkey",
            src: {
              schema: "auth",
              entity: "sessions",
            },
            ref: {
              schema: "auth",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "sso_domains_sso_provider_id_fkey",
            src: {
              schema: "auth",
              entity: "sso_domains",
            },
            ref: {
              schema: "auth",
              entity: "sso_providers",
            },
            attrs: [
              {
                src: ["sso_provider_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "key_parent_key_fkey",
            src: {
              schema: "pgsodium",
              entity: "key",
            },
            ref: {
              schema: "pgsodium",
              entity: "key",
            },
            attrs: [
              {
                src: ["parent_key"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "clever_cloud_resources_organization_id_fkey",
            src: {
              schema: "public",
              entity: "clever_cloud_resources",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "events_created_by_fkey",
            src: {
              schema: "public",
              entity: "events",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "events_organization_id_fkey",
            src: {
              schema: "public",
              entity: "events",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "gallery_project_id_fkey",
            src: {
              schema: "public",
              entity: "gallery",
            },
            ref: {
              schema: "public",
              entity: "projects",
            },
            attrs: [
              {
                src: ["project_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "heroku_resources_organization_id_fkey",
            src: {
              schema: "public",
              entity: "heroku_resources",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_invitations_answered_by_fkey",
            src: {
              schema: "public",
              entity: "organization_invitations",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["answered_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_invitations_created_by_fkey",
            src: {
              schema: "public",
              entity: "organization_invitations",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_invitations_organization_id_fkey",
            src: {
              schema: "public",
              entity: "organization_invitations",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_members_created_by_fkey",
            src: {
              schema: "public",
              entity: "organization_members",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_members_organization_id_fkey",
            src: {
              schema: "public",
              entity: "organization_members",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_members_updated_by_fkey",
            src: {
              schema: "public",
              entity: "organization_members",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["updated_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organization_members_user_id_fkey",
            src: {
              schema: "public",
              entity: "organization_members",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organizations_created_by_fkey",
            src: {
              schema: "public",
              entity: "organizations",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organizations_deleted_by_fkey",
            src: {
              schema: "public",
              entity: "organizations",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["deleted_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "organizations_updated_by_fkey",
            src: {
              schema: "public",
              entity: "organizations",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["updated_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "project_tokens_created_by_fkey",
            src: {
              schema: "public",
              entity: "project_tokens",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "project_tokens_project_id_fkey",
            src: {
              schema: "public",
              entity: "project_tokens",
            },
            ref: {
              schema: "public",
              entity: "projects",
            },
            attrs: [
              {
                src: ["project_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "project_tokens_revoked_by_fkey",
            src: {
              schema: "public",
              entity: "project_tokens",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["revoked_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "projects_archived_by_fkey",
            src: {
              schema: "public",
              entity: "projects",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["archived_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "projects_created_by_fkey",
            src: {
              schema: "public",
              entity: "projects",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["created_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "projects_local_owner_fkey",
            src: {
              schema: "public",
              entity: "projects",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["local_owner"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "projects_organization_id_fkey",
            src: {
              schema: "public",
              entity: "projects",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "projects_updated_by_fkey",
            src: {
              schema: "public",
              entity: "projects",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["updated_by"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "user_auth_tokens_user_id_fkey",
            src: {
              schema: "public",
              entity: "user_auth_tokens",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "user_profiles_team_organization_id_fkey",
            src: {
              schema: "public",
              entity: "user_profiles",
            },
            ref: {
              schema: "public",
              entity: "organizations",
            },
            attrs: [
              {
                src: ["team_organization_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "user_profiles_user_id_fkey",
            src: {
              schema: "public",
              entity: "user_profiles",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "user_tokens_user_id_fkey",
            src: {
              schema: "public",
              entity: "user_tokens",
            },
            ref: {
              schema: "public",
              entity: "users",
            },
            attrs: [
              {
                src: ["user_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "objects_bucketId_fkey",
            src: {
              schema: "storage",
              entity: "objects",
            },
            ref: {
              schema: "storage",
              entity: "buckets",
            },
            attrs: [
              {
                src: ["bucket_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "s3_multipart_uploads_bucket_id_fkey",
            src: {
              schema: "storage",
              entity: "s3_multipart_uploads",
            },
            ref: {
              schema: "storage",
              entity: "buckets",
            },
            attrs: [
              {
                src: ["bucket_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "s3_multipart_uploads_parts_bucket_id_fkey",
            src: {
              schema: "storage",
              entity: "s3_multipart_uploads_parts",
            },
            ref: {
              schema: "storage",
              entity: "buckets",
            },
            attrs: [
              {
                src: ["bucket_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "s3_multipart_uploads_parts_upload_id_fkey",
            src: {
              schema: "storage",
              entity: "s3_multipart_uploads_parts",
            },
            ref: {
              schema: "storage",
              entity: "s3_multipart_uploads",
            },
            attrs: [
              {
                src: ["upload_id"],
                ref: ["id"],
              },
            ],
          },
          {
            name: "secrets_key_id_fkey",
            src: {
              schema: "vault",
              entity: "secrets",
            },
            ref: {
              schema: "pgsodium",
              entity: "key",
            },
            attrs: [
              {
                src: ["key_id"],
                ref: ["id"],
              },
            ],
          },
        ],
        types: [
          {
            schema: "auth",
            name: "aal_level",
            values: ["aal1", "aal2", "aal3"],
          },
          {
            schema: "auth",
            name: "code_challenge_method",
            values: ["s256", "plain"],
          },
          {
            schema: "auth",
            name: "factor_status",
            values: ["unverified", "verified"],
          },
          {
            schema: "auth",
            name: "factor_type",
            values: ["totp", "webauthn"],
          },
          {
            schema: "auth",
            name: "one_time_token_type",
            values: [
              "confirmation_token",
              "reauthentication_token",
              "recovery_token",
              "email_change_token_new",
              "email_change_token_current",
              "phone_change_token",
            ],
          },
          {
            schema: "pgsodium",
            name: "_key_id_context",
          },
          {
            schema: "pgsodium",
            name: "crypto_box_keypair",
          },
          {
            schema: "pgsodium",
            name: "crypto_kx_keypair",
          },
          {
            schema: "pgsodium",
            name: "crypto_kx_session",
          },
          {
            schema: "pgsodium",
            name: "crypto_sign_keypair",
          },
          {
            schema: "pgsodium",
            name: "crypto_signcrypt_keypair",
          },
          {
            schema: "pgsodium",
            name: "crypto_signcrypt_state_key",
          },
          {
            schema: "pgsodium",
            name: "key_status",
            values: ["default", "valid", "invalid", "expired"],
          },
          {
            schema: "pgsodium",
            name: "key_type",
            values: [
              "aead-ietf",
              "aead-det",
              "hmacsha512",
              "hmacsha256",
              "auth",
              "shorthash",
              "generichash",
              "kdf",
              "secretbox",
              "secretstream",
              "stream_xchacha20",
            ],
          },
          {
            schema: "public",
            name: "citext",
          },
          {
            schema: "realtime",
            name: "action",
            values: ["INSERT", "UPDATE", "DELETE", "TRUNCATE", "ERROR"],
          },
          {
            schema: "realtime",
            name: "equality_op",
            values: ["eq", "neq", "lt", "lte", "gt", "gte", "in"],
          },
          {
            schema: "realtime",
            name: "user_defined_filter",
          },
          {
            schema: "realtime",
            name: "wal_column",
          },
          {
            schema: "realtime",
            name: "wal_rls",
          },
        ],
        stats: {
          name: "postgres",
          kind: "postgres",
          version:
            "PostgreSQL 15.1 (Ubuntu 15.1-1.pgdg20.04+1) on aarch64-unknown-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit",
          extractedAt: "2024-06-21T14:25:39.889Z",
          extractionDuration: 541,
          size: 25436160,
        },
      },
      queries: [
        {
          id: "1374137181295181600",
          database: "postgres",
          query: "SELECT name FROM pg_timezone_names",
          rows: 58656,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 59.496679,
            maxTime: 999.19821,
            sumTime: 5985.892282,
            meanTime: 124.706089208333,
            sdTime: 216.974206280726,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-156763288877666600",
          database: "postgres",
          query:
            "-- Recursively get the base types of domains\n  WITH\n  base_types AS (\n    WITH RECURSIVE\n    recurse AS (\n      SELECT\n        oid,\n        typbasetype,\n        COALESCE(NULLIF(typbasetype, $3), oid) AS base\n      FROM pg_type\n      UNION\n      SELECT\n        t.oid,\n        b.typbasetype,\n        COALESCE(NULLIF(b.typbasetype, $4), b.oid) AS base\n      FROM recurse t\n      JOIN pg_type b ON t.typbasetype = b.oid\n    )\n    SELECT\n      oid,\n      base\n    FROM recurse\n    WHERE typbasetype = $5\n  ),\n  arguments AS (\n    SELECT\n      oid,\n      array_agg((\n        COALESCE(name, $6), -- name\n        type::regtype::text, -- type\n        CASE type\n          WHEN $7::regtype THEN $8\n          WHEN $9::regtype THEN $10\n          WHEN $11::regtype THEN $12\n          WHEN $13::regtype THEN $14\n          ELSE type::regtype::text\n        END, -- convert types that ignore the lenth and accept any value till maximum size\n        idx <= (pronargs - pronargdefaults), -- is_required\n        COALESCE(mode = $15, $16) -- is_variadic\n      ) ORDER BY idx) AS args,\n      CASE COUNT(*) - COUNT(name) -- number of unnamed arguments\n        WHEN $17 THEN $18\n        WHEN $19 THEN (array_agg(type))[$20] IN ($21::regtype, $22::regtype, $23::regtype, $24::regtype, $25::regtype)\n        ELSE $26\n      END AS callable\n    FROM pg_proc,\n         unnest(proargnames, proargtypes, proargmodes)\n           WITH ORDINALITY AS _ (name, type, mode, idx)\n    WHERE type IS NOT NULL -- only input arguments\n    GROUP BY oid\n  )\n  SELECT\n    pn.nspname AS proc_schema,\n    p.proname AS proc_name,\n    d.description AS proc_description,\n    COALESCE(a.args, $27) AS args,\n    tn.nspname AS schema,\n    COALESCE(comp.relname, t.typname) AS name,\n    p.proretset AS rettype_is_setof,\n    (t.typtype = $28\n     -- if any TABLE, INOUT or OUT arguments present, treat as composite\n     or COALESCE(proargmodes::text[] && $29, $30)\n    ) AS rettype_is_composite,\n    bt.oid <> bt.base as rettype_is_composite_alias,\n    p.provolatile,\n    p.provariadic > $31 as hasvariadic,\n    lower((regexp_split_to_array((regexp_split_to_array(iso_config, $32))[$33], $34))[$35]) AS transaction_isolation_level,\n    coalesce(func_settings.kvs, $36) as kvs\n  FROM pg_proc p\n  LEFT JOIN arguments a ON a.oid = p.oid\n  JOIN pg_namespace pn ON pn.oid = p.pronamespace\n  JOIN base_types bt ON bt.oid = p.prorettype\n  JOIN pg_type t ON t.oid = bt.base\n  JOIN pg_namespace tn ON tn.oid = t.typnamespace\n  LEFT JOIN pg_class comp ON comp.oid = t.typrelid\n  LEFT JOIN pg_description as d ON d.objoid = p.oid\n  LEFT JOIN LATERAL unnest(proconfig) iso_config ON iso_config LIKE $37\n  LEFT JOIN LATERAL (\n    SELECT\n      array_agg(row(\n        substr(setting, $38, strpos(setting, $39) - $40),\n        substr(setting, strpos(setting, $41) + $42)\n      )) as kvs\n    FROM unnest(proconfig) setting\n    WHERE setting ~ ANY($2)\n  ) func_settings ON $43\n  WHERE t.oid <> $44::regtype AND COALESCE(a.callable, $45)\nAND prokind = $46 AND pn.nspname = ANY($1)",
          rows: 48,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 23.578641,
            maxTime: 40.148259,
            sumTime: 1196.34732,
            meanTime: 24.9239025,
            sdTime: 2.84173134574185,
          },
          blocks: {
            sumRead: 140,
            sumWrite: 0,
            sumHit: 99911,
            sumDirty: 10,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8486453569861712000",
          database: "postgres",
          query:
            "SELECT c.oid                                AS table_id\n             -- , u.rolname                            AS table_owner\n             , n.nspname                            AS table_schema\n             , c.relname                            AS table_name\n             , c.relkind                            AS table_kind\n             , a.attnum                             AS column_index\n             , a.attname                            AS column_name\n             , format_type(a.atttypid, a.atttypmod) AS column_type\n             , t.typname                            AS column_type_name\n             , t.typlen                             AS column_type_len\n             , t.typcategory                        AS column_type_cat\n             , NOT a.attnotnull                     AS column_nullable\n             , pg_get_expr(ad.adbin, ad.adrelid)    AS column_default\n             , a.attgenerated = $1                 AS column_generated\n             , d.description                        AS column_comment\n             , null_frac                            AS nulls\n             , avg_width                            AS avg_len\n             , n_distinct                           AS cardinality\n             , most_common_vals                     AS common_vals\n             , most_common_freqs                    AS common_freqs\n             , histogram_bounds                     AS histogram\n        FROM pg_attribute a\n                 JOIN pg_class c ON c.oid = a.attrelid\n                 JOIN pg_namespace n ON n.oid = c.relnamespace\n                 -- JOIN pg_authid u ON u.oid = c.relowner\n                 JOIN pg_type t ON t.oid = a.atttypid\n                 LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum\n                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum\n                 LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname AND s.attname = a.attname\n        WHERE c.relkind IN ($2, $3, $4)\n          AND a.attnum > $5\n          AND a.atttypid != $6\n          AND n.nspname NOT IN ($7, $8)\n        ORDER BY table_schema, table_name, column_index",
          rows: 24684,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 9.37997,
            maxTime: 74.063108,
            sumTime: 623.320505,
            meanTime: 12.2219706862745,
            sdTime: 9.32812783439806,
          },
          blocks: {
            sumRead: 41,
            sumWrite: 0,
            sumHit: 281872,
            sumDirty: 10,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4022877073318271500",
          database: "postgres",
          query:
            "SELECT c.oid                       AS table_id\n             -- , u.rolname                   AS table_owner\n             , n.nspname                   AS table_schema\n             , c.relname                   AS table_name\n             , c.relkind                   AS table_kind\n             , pg_get_viewdef(c.oid, $1) AS table_definition\n             , pg_get_partkeydef(c.oid)    AS table_partition\n             , d.description               AS table_comment\n             , c.relnatts                  AS attributes_count\n             , c.relchecks                 AS checks_count\n             , s.n_live_tup                AS rows\n             , s.n_dead_tup                AS rows_dead\n             , io.heap_blks_read           AS blocks\n             , io.idx_blks_read            AS idx_blocks\n             , s.seq_scan\n             , s.seq_tup_read              AS seq_scan_reads\n             , $2                        AS seq_scan_last\n             , s.idx_scan\n             , s.idx_tup_fetch             AS idx_scan_reads\n             , $3                        AS idx_scan_last\n             , s.analyze_count\n             , s.last_analyze              AS analyze_last\n             , s.autoanalyze_count\n             , s.last_autoanalyze          AS autoanalyze_last\n             , s.n_mod_since_analyze       AS changes_since_analyze\n             , s.vacuum_count\n             , s.last_vacuum               AS vacuum_last\n             , s.autovacuum_count\n             , s.last_autovacuum           AS autovacuum_last\n             , s.n_ins_since_vacuum        AS changes_since_vacuum\n             , tn.nspname                  AS toast_schema\n             , tc.relname                  AS toast_name\n             , io.toast_blks_read          AS toast_blocks\n             , io.tidx_blks_read           AS toast_idx_blocks\n        FROM pg_class c\n                 JOIN pg_namespace n ON n.oid = c.relnamespace\n                 -- JOIN pg_authid u ON u.oid = c.relowner\n                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = $4\n                 LEFT JOIN pg_class tc ON tc.oid = c.reltoastrelid\n                 LEFT JOIN pg_namespace tn ON tn.oid = tc.relnamespace\n                 LEFT JOIN pg_stat_all_tables s ON s.relid = c.oid\n                 LEFT JOIN pg_statio_all_tables io ON io.relid = c.oid\n        WHERE c.relkind IN ($5, $6, $7)\n          AND n.nspname NOT IN ($8, $9)\n        ORDER BY table_schema, table_name",
          rows: 2397,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 6.547198,
            maxTime: 50.017976,
            sumTime: 429.112568,
            meanTime: 8.41397192156863,
            sdTime: 6.12271133082906,
          },
          blocks: {
            sumRead: 3,
            sumWrite: 0,
            sumHit: 83996,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4509076507432270300",
          database: "postgres",
          query:
            "(\nwith foreign_keys as (\n    select\n        cl.relnamespace::regnamespace::text as schema_name,\n        cl.relname as table_name,\n        cl.oid as table_oid,\n        ct.conname as fkey_name,\n        ct.conkey as col_attnums\n    from\n        pg_catalog.pg_constraint ct\n        join pg_catalog.pg_class cl -- fkey owning table\n            on ct.conrelid = cl.oid\n        left join pg_catalog.pg_depend d\n            on d.objid = cl.oid\n            and d.deptype = $1\n    where\n        ct.contype = $2 -- foreign key constraints\n        and d.objid is null -- exclude tables that are dependencies of extensions\n        and cl.relnamespace::regnamespace::text not in (\n            $3, $4, $5, $6, $7, $8\n        )\n),\nindex_ as (\n    select\n        pi.indrelid as table_oid,\n        indexrelid::regclass as index_,\n        string_to_array(indkey::text, $9)::smallint[] as col_attnums\n    from\n        pg_catalog.pg_index pi\n    where\n        indisvalid\n)\nselect\n    $10 as name,\n    $11 as title,\n    $12 as level,\n    $13 as facing,\n    array[$14] as categories,\n    $15 as description,\n    format(\n        $16,\n        fk.schema_name,\n        fk.table_name,\n        fk.fkey_name\n    ) as detail,\n    $17 as remediation,\n    jsonb_build_object(\n        $18, fk.schema_name,\n        $19, fk.table_name,\n        $20, $21,\n        $22, fk.fkey_name,\n        $23, fk.col_attnums\n    ) as metadata,\n    format($24, fk.schema_name, fk.table_name, fk.fkey_name) as cache_key\nfrom\n    foreign_keys fk\n    left join index_ idx\n        on fk.table_oid = idx.table_oid\n        and fk.col_attnums = idx.col_attnums\n    left join pg_catalog.pg_depend dep\n        on idx.table_oid = dep.objid\n        and dep.deptype = $25\nwhere\n    idx.index_ is null\n    and fk.schema_name not in (\n        $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51\n    )\n    and dep.objid is null -- exclude tables owned by extensions\norder by\n    fk.schema_name,\n    fk.table_name,\n    fk.fkey_name)\nunion all\n(\nselect\n    $52 as name,\n    $53 as title,\n    $54 as level,\n    $55 as facing,\n    array[$56] as categories,\n    $57 as description,\n    format(\n        $58,\n        c.relname\n    ) as detail,\n    $59 as remediation,\n    jsonb_build_object(\n        $60, n.nspname,\n        $61, c.relname,\n        $62, $63,\n        $64, array_remove(array_agg(DISTINCT case when pg_catalog.has_table_privilege($65, c.oid, $66) then $67 when pg_catalog.has_table_privilege($68, c.oid, $69) then $70 end), $71)\n    ) as metadata,\n    format($72, n.nspname, c.relname) as cache_key\nfrom\n    -- Identify the oid for auth.users\n    pg_catalog.pg_class auth_users_pg_class\n    join pg_catalog.pg_namespace auth_users_pg_namespace\n        on auth_users_pg_class.relnamespace = auth_users_pg_namespace.oid\n        and auth_users_pg_class.relname = $73\n        and auth_users_pg_namespace.nspname = $74\n    -- Depends on auth.users\n    join pg_catalog.pg_depend d\n        on d.refobjid = auth_users_pg_class.oid\n    join pg_catalog.pg_rewrite r\n        on r.oid = d.objid\n    join pg_catalog.pg_class c\n        on c.oid = r.ev_class\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    join pg_catalog.pg_class pg_class_auth_users\n        on d.refobjid = pg_class_auth_users.oid\nwhere\n    d.deptype = $75\n    and (\n      pg_catalog.has_table_privilege($76, c.oid, $77)\n      or pg_catalog.has_table_privilege($78, c.oid, $79)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($80, $81), $82)))))\n    -- Exclude self\n    and c.relname <> $83\n    -- There are 3 insecure configurations\n    and\n    (\n        -- Materialized views don't support RLS so this is insecure by default\n        (c.relkind in ($84)) -- m for materialized view\n        or\n        -- Standard View, accessible to anon or authenticated that is security_definer\n        (\n            c.relkind = $85 -- v for view\n            -- Exclude security invoker views\n            and not (\n                lower(coalesce(c.reloptions::text,$86))::text[]\n                && array[\n                    $87,\n                    $88,\n                    $89,\n                    $90\n                ]\n            )\n        )\n        or\n        -- Standard View, security invoker, but no RLS enabled on auth.users\n        (\n            c.relkind in ($91) -- v for view\n            -- is security invoker\n            and (\n                lower(coalesce(c.reloptions::text,$92))::text[]\n                && array[\n                    $93,\n                    $94,\n                    $95,\n                    $96\n                ]\n            )\n            and not pg_class_auth_users.relrowsecurity\n        )\n    )\ngroup by\n    n.nspname,\n    c.relname,\n    c.oid)\nunion all\n(\nwith policies as (\n    select\n        nsp.nspname as schema_name,\n        pb.tablename as table_name,\n        pc.relrowsecurity as is_rls_active,\n        polname as policy_name,\n        polpermissive as is_permissive, -- if not, then restrictive\n        (select array_agg(r::regrole) from unnest(polroles) as x(r)) as roles,\n        case polcmd\n            when $97 then $98\n            when $99 then $100\n            when $101 then $102\n            when $103 then $104\n            when $105 then $106\n        end as command,\n        qual,\n        with_check\n    from\n        pg_catalog.pg_policy pa\n        join pg_catalog.pg_class pc\n            on pa.polrelid = pc.oid\n        join pg_catalog.pg_namespace nsp\n            on pc.relnamespace = nsp.oid\n        join pg_catalog.pg_policies pb\n            on pc.relname = pb.tablename\n            and nsp.nspname = pb.schemaname\n            and pa.polname = pb.policyname\n)\nselect\n    $107 as name,\n    $108 as title,\n    $109 as level,\n    $110 as facing,\n    array[$111] as categories,\n    $112 as description,\n    format(\n        $113,\n        schema_name,\n        table_name,\n        policy_name\n    ) as detail,\n    $114 as remediation,\n    jsonb_build_object(\n        $115, schema_name,\n        $116, table_name,\n        $117, $118\n    ) as metadata,\n    format($119, schema_name, table_name, policy_name) as cache_key\nfrom\n    policies\nwhere\n    is_rls_active\n    and schema_name not in (\n        $120, $121, $122, $123, $124, $125, $126, $127, $128, $129, $130, $131, $132, $133, $134, $135, $136, $137, $138, $139, $140, $141, $142, $143, $144, $145\n    )\n    and (\n        -- Example: auth.uid()\n        (\n            qual like $146\n            and lower(qual) not like $147\n        )\n        or (\n            qual like $148\n            and lower(qual) not like $149\n        )\n        or (\n            qual like $150\n            and lower(qual) not like $151\n        )\n        or (\n            qual like $152\n            and lower(qual) not like $153\n        )\n        or (\n            with_check like $154\n            and lower(with_check) not like $155\n        )\n        or (\n            with_check like $156\n            and lower(with_check) not like $157\n        )\n        or (\n            with_check like $158\n            and lower(with_check) not like $159\n        )\n        or (\n            with_check like $160\n            and lower(with_check) not like $161\n        )\n    ))\nunion all\n(\nselect\n    $162 as name,\n    $163 as title,\n    $164 as level,\n    $165 as facing,\n    array[$166] as categories,\n    $167 as description,\n    format(\n        $168,\n        pgns.nspname,\n        pgc.relname\n    ) as detail,\n    $169 as remediation,\n     jsonb_build_object(\n        $170, pgns.nspname,\n        $171, pgc.relname,\n        $172, $173\n    ) as metadata,\n    format(\n        $174,\n        pgns.nspname,\n        pgc.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class pgc\n    join pg_catalog.pg_namespace pgns\n        on pgns.oid = pgc.relnamespace\n    left join pg_catalog.pg_index pgi\n        on pgi.indrelid = pgc.oid\n    left join pg_catalog.pg_depend dep\n        on pgc.oid = dep.objid\n        and dep.deptype = $175\nwhere\n    pgc.relkind = $176 -- regular tables\n    and pgns.nspname not in (\n        $177, $178, $179, $180, $181, $182, $183, $184, $185, $186, $187, $188, $189, $190, $191, $192, $193, $194, $195, $196, $197, $198, $199, $200, $201, $202\n    )\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    pgc.oid,\n    pgns.nspname,\n    pgc.relname\nhaving\n    max(coalesce(pgi.indisprimary, $203)::int) = $204)\nunion all\n(\nselect\n    $205 as name,\n    $206 as title,\n    $207 as level,\n    $208 as facing,\n    array[$209] as categories,\n    $210 as description,\n    format(\n        $211,\n        psui.indexrelname,\n        psui.schemaname,\n        psui.relname\n    ) as detail,\n    $212 as remediation,\n    jsonb_build_object(\n        $213, psui.schemaname,\n        $214, psui.relname,\n        $215, $216\n    ) as metadata,\n    format(\n        $217,\n        psui.schemaname,\n        psui.relname,\n        psui.indexrelname\n    ) as cache_key\n\nfrom\n    pg_catalog.pg_stat_user_indexes psui\n    join pg_catalog.pg_index pi\n        on psui.indexrelid = pi.indexrelid\n    left join pg_catalog.pg_depend dep\n        on psui.relid = dep.objid\n        and dep.deptype = $218\nwhere\n    psui.idx_scan = $219\n    and not pi.indisunique\n    and not pi.indisprimary\n    and dep.objid is null -- exclude tables owned by extensions\n    and psui.schemaname not in (\n        $220, $221, $222, $223, $224, $225, $226, $227, $228, $229, $230, $231, $232, $233, $234, $235, $236, $237, $238, $239, $240, $241, $242, $243, $244, $245\n    ))\nunion all\n(\nselect\n    $246 as name,\n    $247 as title,\n    $248 as level,\n    $249 as facing,\n    array[$250] as categories,\n    $251 as description,\n    format(\n        $252,\n        n.nspname,\n        c.relname,\n        r.rolname,\n        act.cmd,\n        array_agg(p.polname order by p.polname)\n    ) as detail,\n    $253 as remediation,\n    jsonb_build_object(\n        $254, n.nspname,\n        $255, c.relname,\n        $256, $257\n    ) as metadata,\n    format(\n        $258,\n        n.nspname,\n        c.relname,\n        r.rolname,\n        act.cmd\n    ) as cache_key\nfrom\n    pg_catalog.pg_policy p\n    join pg_catalog.pg_class c\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    join pg_catalog.pg_roles r\n        on p.polroles @> array[r.oid]\n        or p.polroles = array[$259::oid]\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $260,\n    lateral (\n        select x.cmd\n        from unnest((\n            select\n                case p.polcmd\n                    when $261 then array[$262]\n                    when $263 then array[$264]\n                    when $265 then array[$266]\n                    when $267 then array[$268]\n                    when $269 then array[$270, $271, $272, $273]\n                    else array[$274]\n                end as actions\n        )) x(cmd)\n    ) act(cmd)\nwhere\n    c.relkind = $275 -- regular tables\n    and p.polpermissive -- policy is permissive\n    and n.nspname not in (\n        $276, $277, $278, $279, $280, $281, $282, $283, $284, $285, $286, $287, $288, $289, $290, $291, $292, $293, $294, $295, $296, $297, $298, $299, $300, $301\n    )\n    and r.rolname not like $302\n    and r.rolname not like $303\n    and not r.rolbypassrls\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname,\n    r.rolname,\n    act.cmd\nhaving\n    count($304) > $305)\nunion all\n(\nselect\n    $306 as name,\n    $307 as title,\n    $308 as level,\n    $309 as facing,\n    array[$310] as categories,\n    $311 as description,\n    format(\n        $312,\n        n.nspname,\n        c.relname,\n        array_agg(p.polname order by p.polname)\n    ) as detail,\n    $313 as remediation,\n    jsonb_build_object(\n        $314, n.nspname,\n        $315, c.relname,\n        $316, $317\n    ) as metadata,\n    format(\n        $318,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_policy p\n    join pg_catalog.pg_class c\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $319\nwhere\n    c.relkind = $320 -- regular tables\n    and n.nspname not in (\n        $321, $322, $323, $324, $325, $326, $327, $328, $329, $330, $331, $332, $333, $334, $335, $336, $337, $338, $339, $340, $341, $342, $343, $344, $345, $346\n    )\n    -- RLS is disabled\n    and not c.relrowsecurity\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname)\nunion all\n(\nselect\n    $347 as name,\n    $348 as title,\n    $349 as level,\n    $350 as facing,\n    array[$351] as categories,\n    $352 as description,\n    format(\n        $353,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $354 as remediation,\n    jsonb_build_object(\n        $355, n.nspname,\n        $356, c.relname,\n        $357, $358\n    ) as metadata,\n    format(\n        $359,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    left join pg_catalog.pg_policy p\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $360\nwhere\n    c.relkind = $361 -- regular tables\n    and n.nspname not in (\n        $362, $363, $364, $365, $366, $367, $368, $369, $370, $371, $372, $373, $374, $375, $376, $377, $378, $379, $380, $381, $382, $383, $384, $385, $386, $387\n    )\n    -- RLS is enabled\n    and c.relrowsecurity\n    and p.polname is null\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname)\nunion all\n(\nselect\n    $388 as name,\n    $389 as title,\n    $390 as level,\n    $391 as facing,\n    array[$392] as categories,\n    $393 as description,\n    format(\n        $394,\n        n.nspname,\n        c.relname,\n        array_agg(pi.indexname order by pi.indexname)\n    ) as detail,\n    $395 as remediation,\n    jsonb_build_object(\n        $396, n.nspname,\n        $397, c.relname,\n        $398, case\n            when c.relkind = $399 then $400\n            when c.relkind = $401 then $402\n            else $403\n        end,\n        $404, array_agg(pi.indexname order by pi.indexname)\n    ) as metadata,\n    format(\n        $405,\n        n.nspname,\n        c.relname,\n        array_agg(pi.indexname order by pi.indexname)\n    ) as cache_key\nfrom\n    pg_catalog.pg_indexes pi\n    join pg_catalog.pg_namespace n\n        on n.nspname  = pi.schemaname\n    join pg_catalog.pg_class c\n        on pi.tablename = c.relname\n        and n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $406\nwhere\n    c.relkind in ($407, $408) -- tables and materialized views\n    and n.nspname not in (\n        $409, $410, $411, $412, $413, $414, $415, $416, $417, $418, $419, $420, $421, $422, $423, $424, $425, $426, $427, $428, $429, $430, $431, $432, $433, $434\n    )\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relkind,\n    c.relname,\n    replace(pi.indexdef, pi.indexname, $435)\nhaving\n    count(*) > $436)\nunion all\n(\nselect\n    $437 as name,\n    $438 as title,\n    $439 as level,\n    $440 as facing,\n    array[$441] as categories,\n    $442 as description,\n    format(\n        $443,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $444 as remediation,\n    jsonb_build_object(\n        $445, n.nspname,\n        $446, c.relname,\n        $447, $448\n    ) as metadata,\n    format(\n        $449,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $450\nwhere\n    c.relkind = $451\n    and (\n        pg_catalog.has_table_privilege($452, c.oid, $453)\n        or pg_catalog.has_table_privilege($454, c.oid, $455)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($456, $457), $458)))))\n    and n.nspname not in (\n        $459, $460, $461, $462, $463, $464, $465, $466, $467, $468, $469, $470, $471, $472, $473, $474, $475, $476, $477, $478, $479, $480, $481, $482, $483, $484\n    )\n    and dep.objid is null -- exclude views owned by extensions\n    and not (\n        lower(coalesce(c.reloptions::text,$485))::text[]\n        && array[\n            $486,\n            $487,\n            $488,\n            $489\n        ]\n    ))\nunion all\n(\nselect\n    $490 as name,\n    $491 as title,\n    $492 as level,\n    $493 as facing,\n    array[$494] as categories,\n    $495 as description,\n    format(\n        $496,\n        n.nspname,\n        p.proname\n    ) as detail,\n    $497 as remediation,\n    jsonb_build_object(\n        $498, n.nspname,\n        $499, p.proname,\n        $500, $501\n    ) as metadata,\n    format(\n        $502,\n        n.nspname,\n        p.proname,\n        md5(p.prosrc) -- required when function is polymorphic\n    ) as cache_key\nfrom\n    pg_catalog.pg_proc p\n    join pg_catalog.pg_namespace n\n        on p.pronamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on p.oid = dep.objid\n        and dep.deptype = $503\nwhere\n    n.nspname not in (\n        $504, $505, $506, $507, $508, $509, $510, $511, $512, $513, $514, $515, $516, $517, $518, $519, $520, $521, $522, $523, $524, $525, $526, $527, $528, $529\n    )\n    and dep.objid is null -- exclude functions owned by extensions\n    -- Search path not set to ''\n    and not coalesce(p.proconfig, $530) && array[$531])\nunion all\n(\nselect\n    $532 as name,\n    $533 as title,\n    $534 as level,\n    $535 as facing,\n    array[$536] as categories,\n    $537 as description,\n    format(\n        $538,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $539 as remediation,\n    jsonb_build_object(\n        $540, n.nspname,\n        $541, c.relname,\n        $542, $543\n    ) as metadata,\n    format(\n        $544,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\nwhere\n    c.relkind = $545 -- regular tables\n    -- RLS is disabled\n    and not c.relrowsecurity\n    and (\n        pg_catalog.has_table_privilege($546, c.oid, $547)\n        or pg_catalog.has_table_privilege($548, c.oid, $549)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($550, $551), $552)))))\n    and n.nspname not in (\n        $553, $554, $555, $556, $557, $558, $559, $560, $561, $562, $563, $564, $565, $566, $567, $568, $569, $570, $571, $572, $573, $574, $575, $576, $577, $578\n    ))\nunion all\n(\nselect\n    $579 as name,\n    $580 as title,\n    $581 as level,\n    $582 as facing,\n    array[$583] as categories,\n    $584 as description,\n    format(\n        $585,\n        pe.extname\n    ) as detail,\n    $586 as remediation,\n    jsonb_build_object(\n        $587, pe.extnamespace::regnamespace,\n        $588, pe.extname,\n        $589, $590\n    ) as metadata,\n    format(\n        $591,\n        pe.extname\n    ) as cache_key\nfrom\n    pg_catalog.pg_extension pe\nwhere\n    -- plpgsql is installed by default in public and outside user control\n    -- confirmed safe\n    pe.extname not in ($592)\n    -- Scoping this to public is not optimal. Ideally we would use the postgres\n    -- search path. That currently isn't available via SQL. In other lints\n    -- we have used has_schema_privilege('anon', 'extensions', 'USAGE') but that\n    -- is not appropriate here as it would evaluate true for the extensions schema\n    and pe.extnamespace::regnamespace::text = $593)\nunion all\n(\nwith policies as (\n    select\n        nsp.nspname as schema_name,\n        pb.tablename as table_name,\n        polname as policy_name,\n        qual,\n        with_check\n    from\n        pg_catalog.pg_policy pa\n        join pg_catalog.pg_class pc\n            on pa.polrelid = pc.oid\n        join pg_catalog.pg_namespace nsp\n            on pc.relnamespace = nsp.oid\n        join pg_catalog.pg_policies pb\n            on pc.relname = pb.tablename\n            and nsp.nspname = pb.schemaname\n            and pa.polname = pb.policyname\n)\nselect\n    $594 as name,\n    $595 as title,\n    $596 as level,\n    $597 as facing,\n    array[$598] as categories,\n    $599 as description,\n    format(\n        $600,\n        schema_name,\n        table_name,\n        policy_name\n    ) as detail,\n    $601 as remediation,\n    jsonb_build_object(\n        $602, schema_name,\n        $603, table_name,\n        $604, $605\n    ) as metadata,\n    format($606, schema_name, table_name, policy_name) as cache_key\nfrom\n    policies\nwhere\n    schema_name not in (\n        $607, $608, $609, $610, $611, $612, $613, $614, $615, $616, $617, $618, $619, $620, $621, $622, $623, $624, $625, $626, $627, $628, $629, $630, $631, $632\n    )\n    and (\n        -- Example: auth.jwt() -> 'user_metadata'\n        -- False positives are possible, but it isn't practical to string match\n        -- If false positive rate is too high, this expression can iterate\n        qual like $633\n        or qual like $634\n        or with_check like $635\n        or with_check like $636\n    ))\nunion all\n(\nselect\n    $637 as name,\n    $638 as title,\n    $639 as level,\n    $640 as facing,\n    array[$641] as categories,\n    $642 as description,\n    format(\n        $643,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $644 as remediation,\n    jsonb_build_object(\n        $645, n.nspname,\n        $646, c.relname,\n        $647, $648\n    ) as metadata,\n    format(\n        $649,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $650\nwhere\n    c.relkind = $651\n    and (\n        pg_catalog.has_table_privilege($652, c.oid, $653)\n        or pg_catalog.has_table_privilege($654, c.oid, $655)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($656, $657), $658)))))\n    and n.nspname not in (\n        $659, $660, $661, $662, $663, $664, $665, $666, $667, $668, $669, $670, $671, $672, $673, $674, $675, $676, $677, $678, $679, $680, $681, $682, $683, $684\n    )\n    and dep.objid is null)\nunion all\n(\nselect\n    $685 as name,\n    $686 as title,\n    $687 as level,\n    $688 as facing,\n    array[$689] as categories,\n    $690 as description,\n    format(\n        $691,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $692 as remediation,\n    jsonb_build_object(\n        $693, n.nspname,\n        $694, c.relname,\n        $695, $696\n    ) as metadata,\n    format(\n        $697,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $698\nwhere\n    c.relkind = $699\n    and (\n        pg_catalog.has_table_privilege($700, c.oid, $701)\n        or pg_catalog.has_table_privilege($702, c.oid, $703)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($704, $705), $706)))))\n    and n.nspname not in (\n        $707, $708, $709, $710, $711, $712, $713, $714, $715, $716, $717, $718, $719, $720, $721, $722, $723, $724, $725, $726, $727, $728, $729, $730, $731, $732\n    )\n    and dep.objid is null)",
          rows: 723,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 18,
            minTime: 12.349852,
            maxTime: 141.544165,
            sumTime: 419.201793,
            meanTime: 23.2889885,
            sdTime: 29.0090993587203,
          },
          blocks: {
            sumRead: 17,
            sumWrite: 0,
            sumHit: 94409,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "8014584162185131000",
          database: "postgres",
          query:
            "WITH\n  columns AS (\n      SELECT\n          nc.nspname::name AS table_schema,\n          c.relname::name AS table_name,\n          a.attname::name AS column_name,\n          d.description AS description,\n  \n          CASE\n            WHEN t.typbasetype  != $2  THEN pg_get_expr(t.typdefaultbin, $3)\n            WHEN a.attidentity  = $4 THEN format($5, quote_literal(seqsch.nspname || $6 || seqclass.relname))\n            WHEN a.attgenerated = $7 THEN $8\n            ELSE pg_get_expr(ad.adbin, ad.adrelid)::text\n          END AS column_default,\n          not (a.attnotnull OR t.typtype = $9 AND t.typnotnull) AS is_nullable,\n          CASE\n              WHEN t.typtype = $10 THEN\n              CASE\n                  WHEN nbt.nspname = $11::name THEN format_type(t.typbasetype, $12::integer)\n                  ELSE format_type(a.atttypid, a.atttypmod)\n              END\n              ELSE\n              CASE\n                  WHEN nt.nspname = $13::name THEN format_type(a.atttypid, $14::integer)\n                  ELSE format_type(a.atttypid, a.atttypmod)\n              END\n          END::text AS data_type,\n          format_type(a.atttypid, a.atttypmod)::text AS nominal_data_type,\n          information_schema._pg_char_max_length(\n              information_schema._pg_truetypid(a.*, t.*),\n              information_schema._pg_truetypmod(a.*, t.*)\n          )::integer AS character_maximum_length,\n          COALESCE(bt.typname, t.typname)::name AS udt_name,\n          a.attnum::integer AS position\n      FROM pg_attribute a\n          LEFT JOIN pg_description AS d\n              ON d.objoid = a.attrelid and d.objsubid = a.attnum\n          LEFT JOIN pg_attrdef ad\n              ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum\n          JOIN (pg_class c JOIN pg_namespace nc ON c.relnamespace = nc.oid)\n              ON a.attrelid = c.oid\n          JOIN (pg_type t JOIN pg_namespace nt ON t.typnamespace = nt.oid)\n              ON a.atttypid = t.oid\n          LEFT JOIN (pg_type bt JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid)\n              ON t.typtype = $15 AND t.typbasetype = bt.oid\n          LEFT JOIN (pg_collation co JOIN pg_namespace nco ON co.collnamespace = nco.oid)\n              ON a.attcollation = co.oid AND (nco.nspname <> $16::name OR co.collname <> $17::name)\n          LEFT JOIN pg_depend dep\n              ON dep.refobjid = a.attrelid and dep.refobjsubid = a.attnum and dep.deptype = $18\n          LEFT JOIN pg_class seqclass\n              ON seqclass.oid = dep.objid\n          LEFT JOIN pg_namespace seqsch\n              ON seqsch.oid = seqclass.relnamespace\n      WHERE\n          NOT pg_is_other_temp_schema(nc.oid)\n          AND a.attnum > $19\n          AND NOT a.attisdropped\n          AND c.relkind in ($20, $21, $22, $23, $24)\n          AND nc.nspname = ANY($1)\n  ),\n  columns_agg AS (\n    SELECT DISTINCT\n        info.table_schema AS table_schema,\n        info.table_name AS table_name,\n        array_agg(row(\n          info.column_name,\n          info.description,\n          info.is_nullable::boolean,\n          info.data_type,\n          info.nominal_data_type,\n          info.character_maximum_length,\n          info.column_default,\n          coalesce(enum_info.vals, $25)) order by info.position) as columns\n    FROM columns info\n    LEFT OUTER JOIN (\n        SELECT\n            n.nspname AS s,\n            t.typname AS n,\n            array_agg(e.enumlabel ORDER BY e.enumsortorder) AS vals\n        FROM pg_type t\n        JOIN pg_enum e ON t.oid = e.enumtypid\n        JOIN pg_namespace n ON n.oid = t.typnamespace\n        GROUP BY s,n\n    ) AS enum_info ON info.udt_name = enum_info.n\n    WHERE info.table_schema NOT IN ($26, $27)\n    GROUP BY info.table_schema, info.table_name\n  ),\n  tbl_constraints AS (\n      SELECT\n          c.conname::name AS constraint_name,\n          nr.nspname::name AS table_schema,\n          r.relname::name AS table_name\n      FROM pg_namespace nc\n      JOIN pg_constraint c ON nc.oid = c.connamespace\n      JOIN pg_class r ON c.conrelid = r.oid\n      JOIN pg_namespace nr ON nr.oid = r.relnamespace\n      WHERE\n        r.relkind IN ($28, $29)\n        AND NOT pg_is_other_temp_schema(nr.oid)\n        AND c.contype = $30\n  ),\n  key_col_usage AS (\n      SELECT\n          ss.conname::name AS constraint_name,\n          ss.nr_nspname::name AS table_schema,\n          ss.relname::name AS table_name,\n          a.attname::name AS column_name,\n          (ss.x).n::integer AS ordinal_position,\n          CASE\n              WHEN ss.contype = $31 THEN information_schema._pg_index_position(ss.conindid, ss.confkey[(ss.x).n])\n              ELSE $32::integer\n          END::integer AS position_in_unique_constraint\n      FROM pg_attribute a\n      JOIN (\n        SELECT r.oid AS roid,\n          r.relname,\n          r.relowner,\n          nc.nspname AS nc_nspname,\n          nr.nspname AS nr_nspname,\n          c.oid AS coid,\n          c.conname,\n          c.contype,\n          c.conindid,\n          c.confkey,\n          information_schema._pg_expandarray(c.conkey) AS x\n        FROM pg_namespace nr\n        JOIN pg_class r\n          ON nr.oid = r.relnamespace\n        JOIN pg_constraint c\n          ON r.oid = c.conrelid\n        JOIN pg_namespace nc\n          ON c.connamespace = nc.oid\n        WHERE\n          c.contype in ($33, $34)\n          AND r.relkind IN ($35, $36)\n          AND NOT pg_is_other_temp_schema(nr.oid)\n      ) ss ON a.attrelid = ss.roid AND a.attnum = (ss.x).x\n      WHERE\n        NOT a.attisdropped\n  ),\n  tbl_pk_cols AS (\n    SELECT\n        key_col_usage.table_schema,\n        key_col_usage.table_name,\n        array_agg(key_col_usage.column_name) as pk_cols\n    FROM\n        tbl_constraints\n    JOIN\n        key_col_usage\n    ON\n        key_col_usage.table_name = tbl_constraints.table_name AND\n        key_col_usage.table_schema = tbl_constraints.table_schema AND\n        key_col_usage.constraint_name = tbl_constraints.constraint_name\n    WHERE\n        key_col_usage.table_schema NOT IN ($37, $38)\n    GROUP BY key_col_usage.table_schema, key_col_usage.table_name\n  )\n  SELECT\n    n.nspname AS table_schema,\n    c.relname AS table_name,\n    d.description AS table_description,\n    c.relkind IN ($39,$40) as is_view,\n    (\n      c.relkind IN ($41,$42)\n      OR (\n        c.relkind in ($43,$44)\n        -- The function `pg_relation_is_updateable` returns a bitmask where 8\n        -- corresponds to `1 << CMD_INSERT` in the PostgreSQL source code, i.e.\n        -- it's possible to insert into the relation.\n        AND (pg_relation_is_updatable(c.oid::regclass, $45) & $46) = $47\n      )\n    ) AS insertable,\n    (\n      c.relkind IN ($48,$49)\n      OR (\n        c.relkind in ($50,$51)\n        -- CMD_UPDATE\n        AND (pg_relation_is_updatable(c.oid::regclass, $52) & $53) = $54\n      )\n    ) AS updatable,\n    (\n      c.relkind IN ($55,$56)\n      OR (\n        c.relkind in ($57,$58)\n        -- CMD_DELETE\n        AND (pg_relation_is_updatable(c.oid::regclass, $59) & $60) = $61\n      )\n    ) AS deletable,\n    coalesce(tpks.pk_cols, $62) as pk_cols,\n    coalesce(cols_agg.columns, $63) as columns\n  FROM pg_class c\n  JOIN pg_namespace n ON n.oid = c.relnamespace\n  LEFT JOIN pg_description d on d.objoid = c.oid and d.objsubid = $64\n  LEFT JOIN tbl_pk_cols tpks ON n.nspname = tpks.table_schema AND c.relname = tpks.table_name\n  LEFT JOIN columns_agg cols_agg ON n.nspname = cols_agg.table_schema AND c.relname = cols_agg.table_name\n  WHERE c.relkind IN ($65,$66,$67,$68,$69)\n  AND n.nspname NOT IN ($70, $71)  AND not c.relispartition ORDER BY table_schema, table_name",
          rows: 2062,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 2.671941,
            maxTime: 10.317711,
            sumTime: 412.103427,
            meanTime: 8.5854880625,
            sdTime: 1.70232080307867,
          },
          blocks: {
            sumRead: 219,
            sumWrite: 0,
            sumHit: 93193,
            sumDirty: 11,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7339462770142107000",
          database: "postgres",
          query:
            'with tables as (SELECT\n  c.oid :: int8 AS id,\n  nc.nspname AS schema,\n  c.relname AS name,\n  c.relrowsecurity AS rls_enabled,\n  c.relforcerowsecurity AS rls_forced,\n  CASE\n    WHEN c.relreplident = $1 THEN $2\n    WHEN c.relreplident = $3 THEN $4\n    WHEN c.relreplident = $5 THEN $6\n    ELSE $7\n  END AS replica_identity,\n  pg_total_relation_size(format($8, nc.nspname, c.relname)) :: int8 AS bytes,\n  pg_size_pretty(\n    pg_total_relation_size(format($9, nc.nspname, c.relname))\n  ) AS size,\n  pg_stat_get_live_tuples(c.oid) AS live_rows_estimate,\n  pg_stat_get_dead_tuples(c.oid) AS dead_rows_estimate,\n  obj_description(c.oid) AS comment,\n  coalesce(pk.primary_keys, $10) as primary_keys,\n  coalesce(\n    jsonb_agg(relationships) filter (where relationships is not null),\n    $11\n  ) as relationships\nFROM\n  pg_namespace nc\n  JOIN pg_class c ON nc.oid = c.relnamespace\n  left join (\n    select\n      table_id,\n      jsonb_agg(_pk.*) as primary_keys\n    from (\n      select\n        n.nspname as schema,\n        c.relname as table_name,\n        a.attname as name,\n        c.oid :: int8 as table_id\n      from\n        pg_index i,\n        pg_class c,\n        pg_attribute a,\n        pg_namespace n\n      where\n        i.indrelid = c.oid\n        and c.relnamespace = n.oid\n        and a.attrelid = c.oid\n        and a.attnum = any (i.indkey)\n        and i.indisprimary\n    ) as _pk\n    group by table_id\n  ) as pk\n  on pk.table_id = c.oid\n  left join (\n    select\n      c.oid :: int8 as id,\n      c.conname as constraint_name,\n      nsa.nspname as source_schema,\n      csa.relname as source_table_name,\n      sa.attname as source_column_name,\n      nta.nspname as target_table_schema,\n      cta.relname as target_table_name,\n      ta.attname as target_column_name\n    from\n      pg_constraint c\n    join (\n      pg_attribute sa\n      join pg_class csa on sa.attrelid = csa.oid\n      join pg_namespace nsa on csa.relnamespace = nsa.oid\n    ) on sa.attrelid = c.conrelid and sa.attnum = any (c.conkey)\n    join (\n      pg_attribute ta\n      join pg_class cta on ta.attrelid = cta.oid\n      join pg_namespace nta on cta.relnamespace = nta.oid\n    ) on ta.attrelid = c.confrelid and ta.attnum = any (c.confkey)\n    where\n      c.contype = $12\n  ) as relationships\n  on (relationships.source_schema = nc.nspname and relationships.source_table_name = c.relname)\n  or (relationships.target_table_schema = nc.nspname and relationships.target_table_name = c.relname)\nWHERE\n  c.relkind IN ($13, $14)\n  AND NOT pg_is_other_temp_schema(nc.oid)\n  AND (\n    pg_has_role(c.relowner, $15)\n    OR has_table_privilege(\n      c.oid,\n      $16\n    )\n    OR has_any_column_privilege(c.oid, $17)\n  )\ngroup by\n  c.oid,\n  c.relname,\n  c.relrowsecurity,\n  c.relforcerowsecurity,\n  c.relreplident,\n  nc.nspname,\n  pk.primary_keys\n)\n  , columns as (-- Adapted from information_schema.columns\n\nSELECT\n  c.oid :: int8 AS table_id,\n  nc.nspname AS schema,\n  c.relname AS table,\n  (c.oid || $18 || a.attnum) AS id,\n  a.attnum AS ordinal_position,\n  a.attname AS name,\n  CASE\n    WHEN a.atthasdef THEN pg_get_expr(ad.adbin, ad.adrelid)\n    ELSE $19\n  END AS default_value,\n  CASE\n    WHEN t.typtype = $20 THEN CASE\n      WHEN bt.typelem <> $21 :: oid\n      AND bt.typlen = $22 THEN $23\n      WHEN nbt.nspname = $24 THEN format_type(t.typbasetype, $25)\n      ELSE $26\n    END\n    ELSE CASE\n      WHEN t.typelem <> $27 :: oid\n      AND t.typlen = $28 THEN $29\n      WHEN nt.nspname = $30 THEN format_type(a.atttypid, $31)\n      ELSE $32\n    END\n  END AS data_type,\n  COALESCE(bt.typname, t.typname) AS format,\n  a.attidentity IN ($33, $34) AS is_identity,\n  CASE\n    a.attidentity\n    WHEN $35 THEN $36\n    WHEN $37 THEN $38\n    ELSE $39\n  END AS identity_generation,\n  a.attgenerated IN ($40) AS is_generated,\n  NOT (\n    a.attnotnull\n    OR t.typtype = $41 AND t.typnotnull\n  ) AS is_nullable,\n  (\n    c.relkind IN ($42, $43)\n    OR c.relkind IN ($44, $45) AND pg_column_is_updatable(c.oid, a.attnum, $46)\n  ) AS is_updatable,\n  uniques.table_id IS NOT NULL AS is_unique,\n  check_constraints.definition AS "check",\n  array_to_json(\n    array(\n      SELECT\n        enumlabel\n      FROM\n        pg_catalog.pg_enum enums\n      WHERE\n        enums.enumtypid = coalesce(bt.oid, t.oid)\n        OR enums.enumtypid = coalesce(bt.typelem, t.typelem)\n      ORDER BY\n        enums.enumsortorder\n    )\n  ) AS enums,\n  col_description(c.oid, a.attnum) AS comment\nFROM\n  pg_attribute a\n  LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid\n  AND a.attnum = ad.adnum\n  JOIN (\n    pg_class c\n    JOIN pg_namespace nc ON c.relnamespace = nc.oid\n  ) ON a.attrelid = c.oid\n  JOIN (\n    pg_type t\n    JOIN pg_namespace nt ON t.typnamespace = nt.oid\n  ) ON a.atttypid = t.oid\n  LEFT JOIN (\n    pg_type bt\n    JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid\n  ) ON t.typtype = $47\n  AND t.typbasetype = bt.oid\n  LEFT JOIN (\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$48] AS ordinal_position\n    FROM pg_catalog.pg_constraint\n    WHERE contype = $49 AND cardinality(conkey) = $50\n  ) AS uniques ON uniques.table_id = c.oid AND uniques.ordinal_position = a.attnum\n  LEFT JOIN (\n    -- We only select the first column check\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$51] AS ordinal_position,\n      substring(\n        pg_get_constraintdef(pg_constraint.oid, $52),\n        $53,\n        length(pg_get_constraintdef(pg_constraint.oid, $54)) - $55\n      ) AS "definition"\n    FROM pg_constraint\n    WHERE contype = $56 AND cardinality(conkey) = $57\n    ORDER BY table_id, ordinal_position, oid asc\n  ) AS check_constraints ON check_constraints.table_id = c.oid AND check_constraints.ordinal_position = a.attnum\nWHERE\n  NOT pg_is_other_temp_schema(nc.oid)\n  AND a.attnum > $58\n  AND NOT a.attisdropped\n  AND (c.relkind IN ($59, $60, $61, $62, $63))\n  AND (\n    pg_has_role(c.relowner, $64)\n    OR has_column_privilege(\n      c.oid,\n      a.attnum,\n      $65\n    )\n  )\n)\nselect\n  *\n  , \nCOALESCE(\n  (\n    SELECT\n      array_agg(row_to_json(columns)) FILTER (WHERE columns.table_id = tables.id)\n    FROM\n      columns\n  ),\n  $66\n) AS columns\nfrom tables where tables.id = $67',
          rows: 7,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 7,
            minTime: 32.826756,
            maxTime: 67.065888,
            sumTime: 315.148504,
            meanTime: 45.0212148571429,
            sdTime: 12.3639953334066,
          },
          blocks: {
            sumRead: 23,
            sumWrite: 0,
            sumHit: 92690,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5967178077805340000",
          database: "postgres",
          query:
            "SELECT s.schemaname                           AS table_schema\n             , s.relname                              AS table_name\n             , s.indexrelid                           AS index_id\n             , s.indexrelname                         AS index_name\n             , i.indkey::integer[]                    AS columns\n             , i.indisunique                          AS is_unique\n             , pg_get_expr(i.indpred, i.indrelid)     AS partial\n             , pg_get_indexdef(i.indexrelid, $1, $2) AS definition\n             , c.reltuples                            AS rows\n             , c.relpages                             AS blocks\n             , s.idx_scan                             AS idx_scan\n             , s.idx_tup_read                         AS idx_scan_reads\n             , $3                                   AS idx_scan_last\n             , d.description                          AS index_comment\n        FROM pg_index i\n                 JOIN pg_class c ON c.oid = i.indexrelid\n                 JOIN pg_stat_all_indexes s ON s.indexrelid = i.indexrelid\n                 LEFT JOIN pg_description d ON d.objoid = i.indexrelid\n        WHERE i.indisprimary = $4\n          AND s.schemaname NOT IN ($5, $6)\n        ORDER BY table_schema, table_name, index_name",
          rows: 3621,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 5.455474,
            maxTime: 11.288669,
            sumTime: 307.85709,
            meanTime: 6.03641352941177,
            sdTime: 1.03973940458867,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 224214,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4726471486296252000",
          database: "postgres",
          query:
            "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE (t.typrelid = $4)\nAND (t.typelem = $5 OR NOT EXISTS (SELECT $6 FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem))",
          rows: 2138,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 4.743659,
            maxTime: 77.626603,
            sumTime: 161.586223,
            meanTime: 16.1586223,
            sdTime: 21.7228429791974,
          },
          blocks: {
            sumRead: 27,
            sumWrite: 0,
            sumHit: 26403,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5625616040812082000",
          database: "postgres",
          query:
            "with\n    all_relations as (\n      select reltype\n      from pg_class\n      where relkind in ($1,$2,$3,$4,$5)\n    ),\n    computed_rels as (\n      select\n        (parse_ident(p.pronamespace::regnamespace::text))[$6] as schema,\n        p.proname::text                  as name,\n        arg_schema.nspname::text         as rel_table_schema,\n        arg_name.typname::text           as rel_table_name,\n        ret_schema.nspname::text         as rel_ftable_schema,\n        ret_name.typname::text           as rel_ftable_name,\n        not p.proretset or p.prorows = $7 as single_row\n      from pg_proc p\n        join pg_type      arg_name   on arg_name.oid = p.proargtypes[$8]\n        join pg_namespace arg_schema on arg_schema.oid = arg_name.typnamespace\n        join pg_type      ret_name   on ret_name.oid = p.prorettype\n        join pg_namespace ret_schema on ret_schema.oid = ret_name.typnamespace\n      where\n        p.pronargs = $9\n        and p.proargtypes[$10] in (select reltype from all_relations)\n        and p.prorettype in (select reltype from all_relations)\n    )\n    select\n      *,\n      row(rel_table_schema, rel_table_name) = row(rel_ftable_schema, rel_ftable_name) as is_self\n    from computed_rels",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 2.362492,
            maxTime: 3.145793,
            sumTime: 118.737497,
            meanTime: 2.47369785416667,
            sdTime: 0.12400300648304,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 33260,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "9129060170365427000",
          database: "postgres",
          query:
            "with\n      role_setting as (\n        select r.rolname, unnest(r.rolconfig) as setting\n        from pg_auth_members m\n        join pg_roles r on r.oid = m.roleid\n        where member = current_user::regrole::oid\n      ),\n      kv_settings AS (\n        SELECT\n          rolname,\n          substr(setting, $1, strpos(setting, $2) - $3) as key,\n          lower(substr(setting, strpos(setting, $4) + $5)) as value\n        FROM role_setting\n      ),\n      iso_setting AS (\n        SELECT rolname, value\n        FROM kv_settings\n        WHERE key = $6\n      )\n      select\n        kv.rolname,\n        i.value as iso_lvl,\n        coalesce(array_agg(row(kv.key, kv.value)) filter (where key <> $7), $8) as role_settings\n      from kv_settings kv\n      join pg_settings ps on ps.name = kv.key and (ps.context = $9 or has_parameter_privilege(current_user::regrole::oid, ps.name, $10)) \n      left join iso_setting i on i.rolname = kv.rolname\n      group by kv.rolname, i.value",
          rows: 96,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 2.007642,
            maxTime: 6.984731,
            sumTime: 111.67742,
            meanTime: 2.32661291666667,
            sdTime: 0.871183396284015,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 24335,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7010491533042733000",
          database: "postgres",
          query:
            "SELECT d.oid                 AS database_id\n             , d.datname             AS database_name\n             -- , u.rolname             AS query_owner\n             , s.queryid             AS query_id\n             , s.query               AS query\n             , s.plans               AS plan_count\n             , s.total_plan_time     AS plan_time_total\n             , s.min_plan_time       AS plan_time_min\n             , s.max_plan_time       AS plan_time_max\n             , s.mean_plan_time      AS plan_time_mean\n             , s.stddev_plan_time    AS plan_time_sd\n             , s.calls               AS exec_count\n             , s.total_exec_time     AS exec_time_total\n             , s.min_exec_time       AS exec_time_min\n             , s.max_exec_time       AS exec_time_max\n             , s.mean_exec_time      AS exec_time_mean\n             , s.stddev_exec_time    AS exec_time_sd\n             , s.rows                AS rows_impacted\n             , s.shared_blks_read    AS blocks_read\n             , s.shared_blks_written AS blocks_write\n             , s.shared_blks_hit     AS blocks_hit\n             , s.shared_blks_dirtied AS blocks_dirtied\n             , s.local_blks_read     AS blocks_tmp_read\n             , s.local_blks_written  AS blocks_tmp_write\n             , s.local_blks_hit      AS blocks_tmp_hit\n             , s.local_blks_dirtied  AS blocks_tmp_dirtied\n             , s.temp_blks_read      AS blocks_query_read\n             , s.temp_blks_written   AS blocks_query_write\n        FROM pg_stat_statements s\n                 JOIN pg_database d ON d.oid = s.dbid\n                 -- JOIN pg_authid u ON u.oid = s.userid\n        WHERE s.toplevel = $1 AND queryid IS NOT NULL AND d.datname = $2\n        ORDER BY exec_time_total DESC",
          rows: 7746,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 1.810144,
            maxTime: 5.823684,
            sumTime: 105.57905,
            meanTime: 2.19956354166667,
            sdTime: 0.589675525855885,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2400,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1068285221359123800",
          database: "postgres",
          query:
            "WITH\n    pks_uniques_cols AS (\n      SELECT\n        connamespace,\n        conrelid,\n        jsonb_agg(column_info.cols) as cols\n      FROM pg_constraint\n      JOIN lateral (\n        SELECT array_agg(cols.attname order by cols.attnum) as cols\n        FROM ( select unnest(conkey) as col) _\n        JOIN pg_attribute cols on cols.attrelid = conrelid and cols.attnum = col\n      ) column_info ON $1\n      WHERE\n        contype IN ($2, $3) and\n        connamespace::regnamespace::text <> $4\n      GROUP BY connamespace, conrelid\n    )\n    SELECT\n      ns1.nspname AS table_schema,\n      tab.relname AS table_name,\n      ns2.nspname AS foreign_table_schema,\n      other.relname AS foreign_table_name,\n      (ns1.nspname, tab.relname) = (ns2.nspname, other.relname) AS is_self,\n      traint.conname  AS constraint_name,\n      column_info.cols_and_fcols,\n      (column_info.cols IN (SELECT * FROM jsonb_array_elements(pks_uqs.cols))) AS one_to_one\n    FROM pg_constraint traint\n    JOIN LATERAL (\n      SELECT\n        array_agg(row(cols.attname, refs.attname) order by ord) AS cols_and_fcols,\n        jsonb_agg(cols.attname order by ord) AS cols\n      FROM unnest(traint.conkey, traint.confkey) WITH ORDINALITY AS _(col, ref, ord)\n      JOIN pg_attribute cols ON cols.attrelid = traint.conrelid AND cols.attnum = col\n      JOIN pg_attribute refs ON refs.attrelid = traint.confrelid AND refs.attnum = ref\n    ) AS column_info ON $5\n    JOIN pg_namespace ns1 ON ns1.oid = traint.connamespace\n    JOIN pg_class tab ON tab.oid = traint.conrelid\n    JOIN pg_class other ON other.oid = traint.confrelid\n    JOIN pg_namespace ns2 ON ns2.oid = other.relnamespace\n    LEFT JOIN pks_uniques_cols pks_uqs ON pks_uqs.connamespace = traint.connamespace AND pks_uqs.conrelid = traint.conrelid\n    WHERE traint.contype = $6\n   and traint.conparentid = $7 ORDER BY traint.conrelid, traint.conname",
          rows: 1908,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 1.242905,
            maxTime: 3.576501,
            sumTime: 102.973368,
            meanTime: 2.1452785,
            sdTime: 0.383034052967879,
          },
          blocks: {
            sumRead: 2,
            sumWrite: 0,
            sumHit: 38503,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7559473425162583000",
          database: "postgres",
          query:
            "with recursive\n      pks_fks as (\n        -- pk + fk referencing col\n        select\n          contype::text as contype,\n          conname,\n          array_length(conkey, $3) as ncol,\n          conrelid as resorigtbl,\n          col as resorigcol,\n          ord\n        from pg_constraint\n        left join lateral unnest(conkey) with ordinality as _(col, ord) on $4\n        where contype IN ($5, $6)\n        union\n        -- fk referenced col\n        select\n          concat(contype, $7) as contype,\n          conname,\n          array_length(confkey, $8) as ncol,\n          confrelid,\n          col,\n          ord\n        from pg_constraint\n        left join lateral unnest(confkey) with ordinality as _(col, ord) on $9\n        where contype=$10\n      ),\n      views as (\n        select\n          c.oid       as view_id,\n          n.nspname   as view_schema,\n          c.relname   as view_name,\n          r.ev_action as view_definition\n        from pg_class c\n        join pg_namespace n on n.oid = c.relnamespace\n        join pg_rewrite r on r.ev_class = c.oid\n        where c.relkind in ($11, $12) and n.nspname = ANY($1 || $2)\n      ),\n      transform_json as (\n        select\n          view_id, view_schema, view_name,\n          -- the following formatting is without indentation on purpose\n          -- to allow simple diffs, with less whitespace noise\n          replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            regexp_replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n            replace(\n              view_definition::text,\n            -- This conversion to json is heavily optimized for performance.\n            -- The general idea is to use as few regexp_replace() calls as possible.\n            -- Simple replace() is a lot faster, so we jump through some hoops\n            -- to be able to use regexp_replace() only once.\n            -- This has been tested against a huge schema with 250+ different views.\n            -- The unit tests do NOT reflect all possible inputs. Be careful when changing this!\n            -- -----------------------------------------------\n            -- pattern           | replacement         | flags\n            -- -----------------------------------------------\n            -- `<>` in pg_node_tree is the same as `null` in JSON, but due to very poor performance of json_typeof\n            -- we need to make this an empty array here to prevent json_array_elements from throwing an error\n            -- when the targetList is null.\n            -- We'll need to put it first, to make the node protection below work for node lists that start with\n            -- null: `(<> ...`, too. This is the case for coldefexprs, when the first column does not have a default value.\n               $13              , $14\n            -- `,` is not part of the pg_node_tree format, but used in the regex.\n            -- This removes all `,` that might be part of column names.\n            ), $15               , $16\n            -- The same applies for `{` and `}`, although those are used a lot in pg_node_tree.\n            -- We remove the escaped ones, which might be part of column names again.\n            ), $17            , $18\n            ), $19            , $20\n            -- The fields we need are formatted as json manually to protect them from the regex.\n            ), $21   , $22\n            ), $23        , $24\n            ), $25   , $26\n            ), $27   , $28\n            -- Make the regex also match the node type, e.g. `{QUERY ...`, to remove it in one pass.\n            ), $29               , $30\n            -- Protect node lists, which start with `({` or `((` from the greedy regex.\n            -- The extra `{` is removed again later.\n            ), $31              , $32\n            ), $33              , $34\n            -- This regex removes all unused fields to avoid the need to format all of them correctly.\n            -- This leads to a smaller json result as well.\n            -- Removal stops at `,` for used fields (see above) and `}` for the end of the current node.\n            -- Nesting can't be parsed correctly with a regex, so we stop at `{` as well and\n            -- add an empty key for the followig node.\n            ), $35       , $36              , $37\n            -- For performance, the regex also added those empty keys when hitting a `,` or `}`.\n            -- Those are removed next.\n            ), $38           , $39\n            ), $40           , $41\n            -- This reverses the \"node list protection\" from above.\n            ), $42              , $43\n            -- Every key above has been added with a `,` so far. The first key in an object doesn't need it.\n            ), $44              , $45\n            -- pg_node_tree has `()` around lists, but JSON uses `[]`\n            ), $46               , $47\n            ), $48               , $49\n            -- pg_node_tree has ` ` between list items, but JSON uses `,`\n            ), $50             , $51\n          )::json as view_definition\n        from views\n      ),\n      target_entries as(\n        select\n          view_id, view_schema, view_name,\n          json_array_elements(view_definition->$52->$53) as entry\n        from transform_json\n      ),\n      results as(\n        select\n          view_id, view_schema, view_name,\n          (entry->>$54)::int as view_column,\n          (entry->>$55)::oid as resorigtbl,\n          (entry->>$56)::int as resorigcol\n        from target_entries\n      ),\n      -- CYCLE detection according to PG docs: https://www.postgresql.org/docs/current/queries-with.html#QUERIES-WITH-CYCLE\n      -- Can be replaced with CYCLE clause once PG v13 is EOL.\n      recursion(view_id, view_schema, view_name, view_column, resorigtbl, resorigcol, is_cycle, path) as(\n        select\n          r.*,\n          $57,\n          ARRAY[resorigtbl]\n        from results r\n        where view_schema = ANY ($1)\n        union all\n        select\n          view.view_id,\n          view.view_schema,\n          view.view_name,\n          view.view_column,\n          tab.resorigtbl,\n          tab.resorigcol,\n          tab.resorigtbl = ANY(path),\n          path || tab.resorigtbl\n        from recursion view\n        join results tab on view.resorigtbl=tab.view_id and view.resorigcol=tab.view_column\n        where not is_cycle\n      ),\n      repeated_references as(\n        select\n          view_id,\n          view_schema,\n          view_name,\n          resorigtbl,\n          resorigcol,\n          array_agg(attname) as view_columns\n        from recursion\n        join pg_attribute vcol on vcol.attrelid = view_id and vcol.attnum = view_column\n        group by\n          view_id,\n          view_schema,\n          view_name,\n          resorigtbl,\n          resorigcol\n      )\n      select\n        sch.nspname as table_schema,\n        tbl.relname as table_name,\n        rep.view_schema,\n        rep.view_name,\n        pks_fks.conname as constraint_name,\n        pks_fks.contype as constraint_type,\n        array_agg(row(col.attname, view_columns) order by pks_fks.ord) as column_dependencies\n      from repeated_references rep\n      join pks_fks using (resorigtbl, resorigcol)\n      join pg_class tbl on tbl.oid = rep.resorigtbl\n      join pg_attribute col on col.attrelid = tbl.oid and col.attnum = rep.resorigcol\n      join pg_namespace sch on sch.oid = tbl.relnamespace\n      group by sch.nspname, tbl.relname,  rep.view_schema, rep.view_name, pks_fks.conname, pks_fks.contype, pks_fks.ncol\n      -- make sure we only return key for which all columns are referenced in the view - no partial PKs or FKs\n      having ncol = array_length(array_agg(row(col.attname, view_columns) order by pks_fks.ord), $58)",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 1.291834,
            maxTime: 15.113822,
            sumTime: 82.0922629999999,
            meanTime: 1.71025547916667,
            sdTime: 1.97563817601834,
          },
          blocks: {
            sumRead: 11,
            sumWrite: 0,
            sumHit: 2240,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4544964920772339700",
          database: "postgres",
          query:
            "SELECT cn.nspname                        AS table_schema\n             , cl.relname                        AS table_name\n             , c.conname                         AS constraint_name\n             , c.contype                         AS constraint_type\n             , c.conkey                          AS columns\n             , c.condeferrable                   AS deferrable\n             , pg_get_constraintdef(c.oid, $1) AS definition\n             , d.description                     AS constraint_comment\n        FROM pg_constraint c\n                 JOIN pg_class cl ON cl.oid = c.conrelid\n                 JOIN pg_namespace cn ON cn.oid = cl.relnamespace\n                 LEFT JOIN pg_description d ON d.objoid = c.oid\n        WHERE c.contype IN ($2, $3)\n          AND cn.nspname NOT IN ($4, $5)\n        ORDER BY table_schema, table_name, constraint_name",
          rows: 2550,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 1.224549,
            maxTime: 6.45151,
            sumTime: 71.191183,
            meanTime: 1.39590554901961,
            sdTime: 0.717437079646391,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 29940,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8656841547537470000",
          database: "postgres",
          query:
            "SELECT min(n.nspname)                                        AS type_schema\n             -- , min(o.rolname)                                        AS type_owner\n             , t.typname                                             AS type_name\n             , t.typtype                                             AS type_kind\n             , t.typcategory                                         AS type_category\n             , array_remove(array_agg(e.enumlabel), $1)::varchar[] AS type_values\n             , t.typlen                                              AS type_len\n             , t.typdelim                                            AS type_delimiter\n             , t.typdefault                                          AS type_default\n             , min(d.description)                                    AS type_comment\n        FROM pg_type t\n                 JOIN pg_namespace n ON n.oid = t.typnamespace\n                 -- JOIN pg_authid o ON o.oid = t.typowner\n                 LEFT JOIN pg_class c ON c.oid = t.typrelid\n                 LEFT JOIN pg_type tt ON tt.oid = t.typelem AND tt.typarray = t.oid\n                 LEFT JOIN pg_enum e ON e.enumtypid = t.oid\n                 LEFT JOIN pg_description d ON d.objoid = t.oid\n        WHERE t.typisdefined\n          AND (c.relkind IS NULL OR c.relkind = $2)\n          AND tt.oid IS NULL\n          AND n.nspname NOT IN ($3, $4)\n        GROUP BY t.oid, t.typname, t.typtype, t.typcategory, t.typlen, t.typdelim, t.typdefault\n        ORDER BY type_schema, type_name",
          rows: 1020,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 1.203126,
            maxTime: 2.986824,
            sumTime: 67.785199,
            meanTime: 1.32912154901961,
            sdTime: 0.338987638463342,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 22644,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4726471486296252000",
          database: "postgres",
          query:
            "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\n\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE (t.typrelid = $4)\nAND (t.typelem = $5 OR NOT EXISTS (SELECT $6 FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem))",
          rows: 641,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 4.906531,
            maxTime: 37.537017,
            sumTime: 47.906336,
            meanTime: 15.9687786666667,
            sdTime: 15.2527382036825,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7945,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5236405556122437000",
          database: "postgres",
          query:
            "SELECT c.conname                         AS constraint_name\n             , cn.nspname                        AS table_schema\n             , cl.relname                        AS table_name\n             , c.conkey                          AS table_columns\n             , tn.nspname                        AS target_schema\n             , tc.relname                        AS target_table\n             , c.confkey                         AS target_columns\n             , c.condeferrable                   AS is_deferrable\n             , c.confupdtype                     AS on_update\n             , c.confdeltype                     AS on_delete\n             , c.confmatchtype                   AS matching\n             , pg_get_constraintdef(c.oid, $1) AS definition\n             , d.description                     AS relation_comment\n        FROM pg_constraint c\n                 JOIN pg_class cl ON cl.oid = c.conrelid\n                 JOIN pg_namespace cn ON cn.oid = cl.relnamespace\n                 JOIN pg_class tc ON tc.oid = c.confrelid\n                 JOIN pg_namespace tn ON tn.oid = tc.relnamespace\n                 LEFT JOIN pg_description d ON d.objoid = c.oid\n        WHERE c.contype IN ($2)\n          AND cn.nspname NOT IN ($3, $4)\n        ORDER BY table_schema, table_name, constraint_name",
          rows: 2244,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 0.738652,
            maxTime: 1.14016,
            sumTime: 40.616847,
            meanTime: 0.796408764705883,
            sdTime: 0.057263223931276,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 22083,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8765505101089730000",
          database: "postgres",
          query: "SELECT * FROM pgbouncer.get_auth($1)",
          rows: 11,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 11,
            minTime: 1.017214,
            maxTime: 12.775663,
            sumTime: 36.99438,
            meanTime: 3.36312545454545,
            sdTime: 3.66901967613244,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 1962,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7405815429129837000",
          database: "postgres",
          query:
            "select\n  t.oid::int8 as id,\n  t.typname as name,\n  n.nspname as schema,\n  format_type (t.oid, $1) as format,\n  coalesce(t_enums.enums, $2) as enums,\n  coalesce(t_attributes.attributes, $3) as attributes,\n  obj_description (t.oid, $4) as comment\nfrom\n  pg_type t\n  left join pg_namespace n on n.oid = t.typnamespace\n  left join (\n    select\n      enumtypid,\n      jsonb_agg(enumlabel order by enumsortorder) as enums\n    from\n      pg_enum\n    group by\n      enumtypid\n  ) as t_enums on t_enums.enumtypid = t.oid\n  left join (\n    select\n      oid,\n      jsonb_agg(\n        jsonb_build_object($5, a.attname, $6, a.atttypid::int8)\n        order by a.attnum asc\n      ) as attributes\n    from\n      pg_class c\n      join pg_attribute a on a.attrelid = c.oid\n    where\n      c.relkind = $7 and not a.attisdropped\n    group by\n      c.oid\n  ) as t_attributes on t_attributes.oid = t.typrelid\nwhere\n  (\n    t.typrelid = $8\n    or (\n      select\n        c.relkind = $9\n      from\n        pg_class c\n      where\n        c.oid = t.typrelid\n    )\n  )\n and not exists (\n                 select\n                 from\n                   pg_type el\n                 where\n                   el.oid = t.typelem\n                   and el.typarray = t.oid\n               ) and n.nspname NOT IN ($10,$11,$12)",
          rows: 140,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 7,
            minTime: 2.023007,
            maxTime: 15.939461,
            sumTime: 35.11437,
            meanTime: 5.01633857142857,
            sdTime: 4.62271812312901,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5815,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "596205313124026000",
          database: "postgres",
          query:
            "SELECT\n      c.castsource::regtype::text,\n      c.casttarget::regtype::text,\n      c.castfunc::regproc::text\n    FROM\n      pg_catalog.pg_cast c\n    JOIN pg_catalog.pg_type src_t\n      ON c.castsource::oid = src_t.oid\n    JOIN pg_catalog.pg_type dst_t\n      ON c.casttarget::oid = dst_t.oid\n    WHERE\n      c.castcontext = $1\n      AND c.castmethod = $2\n      AND has_function_privilege(c.castfunc, $3)\n      AND ((src_t.typtype = $4 AND c.casttarget IN ($5::regtype::oid , $6::regtype::oid))\n       OR (dst_t.typtype = $7 AND c.castsource IN ($8::regtype::oid , $9::regtype::oid)))",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 0.433206,
            maxTime: 0.957366,
            sumTime: 23.373682,
            meanTime: 0.486951708333333,
            sdTime: 0.074304225534274,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 17619,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4726471486296252000",
          database: "postgres",
          query:
            "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE (t.typrelid = $4)\nAND (t.typelem = $5 OR NOT EXISTS (SELECT $6 FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem))",
          rows: 850,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 4.734595,
            maxTime: 5.089952,
            sumTime: 19.635132,
            meanTime: 4.908783,
            sdTime: 0.15265524860777,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 10556,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1619054212951445800",
          database: "postgres",
          query:
            "select set_config('search_path', $1, true), set_config($2, $3, true), set_config('role', $4, true), set_config('request.jwt.claims', $5, true), set_config('request.method', $6, true), set_config('request.path', $7, true), set_config('request.headers', $8, true), set_config('request.cookies', $9, true)",
          rows: 33,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 33,
            minTime: 0.027118,
            maxTime: 1.667705,
            sumTime: 19.203819,
            meanTime: 0.581933909090909,
            sdTime: 0.372289914330816,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 389,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "852214041973114400",
          database: "postgres",
          query:
            'INSERT INTO "events" ("data","name","details","created_by","id","created_at") VALUES ($1,$2,$3,$4,$5,$6)',
          rows: 29,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 29,
            minTime: 0.174578,
            maxTime: 1.358476,
            sumTime: 13.002441,
            meanTime: 0.448360034482759,
            sdTime: 0.314128530863588,
          },
          blocks: {
            sumRead: 2,
            sumWrite: 6,
            sumHit: 1772,
            sumDirty: 15,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8820225599990058000",
          database: "postgres",
          query:
            "with\n      all_relations as (\n        select reltype\n        from pg_class\n        where relkind in ($2,$3,$4,$5,$6)\n        union\n        select oid\n        from pg_type\n        where typname = $7\n      ),\n      media_types as (\n          SELECT\n            t.oid,\n            lower(t.typname) as typname,\n            b.oid as base_oid,\n            b.typname AS basetypname,\n            t.typnamespace,\n            case t.typname\n              when $8 then $9\n              else t.typname\n            end as resolved_media_type\n          FROM pg_type t\n          JOIN pg_type b ON t.typbasetype = b.oid\n          WHERE\n            t.typbasetype <> $10 and\n            (t.typname ~* $11 or t.typname = $12)\n      )\n      select\n        proc_schema.nspname           as handler_schema,\n        proc.proname                  as handler_name,\n        arg_schema.nspname::text      as target_schema,\n        arg_name.typname::text        as target_name,\n        media_types.typname           as media_type,\n        media_types.resolved_media_type\n      from media_types\n        join pg_proc      proc         on proc.prorettype = media_types.oid\n        join pg_namespace proc_schema  on proc_schema.oid = proc.pronamespace\n        join pg_aggregate agg          on agg.aggfnoid = proc.oid\n        join pg_type      arg_name     on arg_name.oid = proc.proargtypes[$13]\n        join pg_namespace arg_schema   on arg_schema.oid = arg_name.typnamespace\n      where\n        proc_schema.nspname = ANY($1) and\n        proc.pronargs = $14 and\n        arg_name.oid in (select reltype from all_relations)\n      union\n      select\n          typ_sch.nspname as handler_schema,\n          mtype.typname   as handler_name,\n          pro_sch.nspname as target_schema,\n          proname         as target_name,\n          mtype.typname   as media_type,\n          mtype.resolved_media_type\n      from pg_proc proc\n        join pg_namespace pro_sch on pro_sch.oid = proc.pronamespace\n        join media_types mtype on proc.prorettype = mtype.oid\n        join pg_namespace typ_sch     on typ_sch.oid = mtype.typnamespace\n      where\n        pro_sch.nspname = ANY($1) and NOT proretset\n       AND prokind = $15",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 0.201483,
            maxTime: 1.306503,
            sumTime: 11.787854,
            meanTime: 0.245580291666667,
            sdTime: 0.155162452555373,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 1333,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "215494419220057280",
          database: "postgres",
          query: "SELECT pg_database_size($1)",
          rows: 10,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 1.054368,
            maxTime: 1.327227,
            sumTime: 11.491299,
            meanTime: 1.1491299,
            sdTime: 0.0785289089437132,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 20,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3255238245236510700",
          database: "postgres",
          query:
            "SELECT a.attname AS attr\n        FROM pg_attribute a\n                 JOIN pg_class c ON c.oid = a.attrelid\n                 JOIN pg_namespace n ON n.oid = c.relnamespace\n        WHERE n.nspname = $1 AND c.relname = $2",
          rows: 1581,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 102,
            minTime: 0.033164,
            maxTime: 2.480897,
            sumTime: 10.783681,
            meanTime: 0.105722362745098,
            sdTime: 0.331099125523028,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 713,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6251114447011879000",
          database: "postgres",
          query:
            "SELECT SUM(pg_database_size(pg_database.datname)) / ($1 * $2) as size_mb FROM pg_database",
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 2.073781,
            maxTime: 2.186616,
            sumTime: 8.555236,
            meanTime: 2.138809,
            sdTime: 0.0408874088748603,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 28,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1725632377839038000",
          database: "postgres",
          query:
            "SELECT \n  con.oid as id, \n  con.conname as constraint_name, \n  con.confdeltype as deletion_action,\n  con.confupdtype as update_action,\n  rel.oid as source_id,\n  nsp.nspname as source_schema, \n  rel.relname as source_table, \n  (\n    SELECT \n      array_agg(\n        att.attname \n        ORDER BY \n          un.ord\n      ) \n    FROM \n      unnest(con.conkey) WITH ORDINALITY un (attnum, ord) \n      INNER JOIN pg_attribute att ON att.attnum = un.attnum \n    WHERE \n      att.attrelid = rel.oid\n  ) source_columns, \n  frel.oid as target_id,\n  fnsp.nspname as target_schema, \n  frel.relname as target_table, \n  (\n    SELECT \n      array_agg(\n        att.attname \n        ORDER BY \n          un.ord\n      ) \n    FROM \n      unnest(con.confkey) WITH ORDINALITY un (attnum, ord) \n      INNER JOIN pg_attribute att ON att.attnum = un.attnum \n    WHERE \n      att.attrelid = frel.oid\n  ) target_columns \nFROM \n  pg_constraint con \n  INNER JOIN pg_class rel ON rel.oid = con.conrelid \n  INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace \n  INNER JOIN pg_class frel ON frel.oid = con.confrelid \n  INNER JOIN pg_namespace fnsp ON fnsp.oid = frel.relnamespace \nWHERE \n  con.contype = $1\n  AND nsp.nspname = $2",
          rows: 135,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 5,
            minTime: 1.170484,
            maxTime: 2.123611,
            sumTime: 7.077948,
            meanTime: 1.4155896,
            sdTime: 0.355864132711685,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2925,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1066215449267778800",
          database: "postgres",
          query:
            'INSERT INTO "events" ("name","details","created_by","id","created_at") VALUES ($1,$2,$3,$4,$5)',
          rows: 21,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 21,
            minTime: 0.174349,
            maxTime: 0.90364,
            sumTime: 6.765963,
            meanTime: 0.322188714285714,
            sdTime: 0.199923662874023,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 815,
            sumDirty: 17,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3769267146247783400",
          database: "postgres",
          query:
            'INSERT INTO migrations ("id", "name", "hash") VALUES ($1,$2,$3)',
          rows: 25,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 25,
            minTime: 0.033104,
            maxTime: 3.590975,
            sumTime: 5.85391,
            meanTime: 0.2341564,
            sdTime: 0.721413984638113,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 3,
            sumHit: 82,
            sumDirty: 8,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3902539372796871700",
          database: "postgres",
          query:
            "SELECT \n  con.oid as id, \n  con.conname as constraint_name, \n  con.confdeltype as deletion_action,\n  con.confupdtype as update_action,\n  rel.oid as source_id,\n  nsp.nspname as source_schema, \n  rel.relname as source_table, \n  (\n    SELECT \n      array_agg(\n        att.attname \n        ORDER BY \n          un.ord\n      ) \n    FROM \n      unnest(con.conkey) WITH ORDINALITY un (attnum, ord) \n      INNER JOIN pg_attribute att ON att.attnum = un.attnum \n    WHERE \n      att.attrelid = rel.oid\n  ) source_columns, \n  frel.oid as target_id,\n  fnsp.nspname as target_schema, \n  frel.relname as target_table, \n  (\n    SELECT \n      array_agg(\n        att.attname \n        ORDER BY \n          un.ord\n      ) \n    FROM \n      unnest(con.confkey) WITH ORDINALITY un (attnum, ord) \n      INNER JOIN pg_attribute att ON att.attnum = un.attnum \n    WHERE \n      att.attrelid = frel.oid\n  ) target_columns \nFROM \n  pg_constraint con \n  INNER JOIN pg_class rel ON rel.oid = con.conrelid \n  INNER JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace \n  INNER JOIN pg_class frel ON frel.oid = con.confrelid \n  INNER JOIN pg_namespace fnsp ON fnsp.oid = frel.relnamespace \nWHERE \n  con.contype = $1",
          rows: 132,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 1.706771,
            maxTime: 1.882358,
            sumTime: 5.31263,
            meanTime: 1.77087666666667,
            sdTime: 0.0791245389089601,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2322,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4829213965398250000",
          database: "postgres",
          query:
            'with records as (\n      select\n        c.oid::int8 as "id",\n        nc.nspname as "schema",\n        c.relname as "name",\n        c.relkind as "type",\n        case c.relkind\n          when $1 then $2\n          when $3 then $4\n          when $5 then $6\n          when $7 then $8\n          when $9 then $10\n        end as "type_sort",\n        obj_description(c.oid) as "comment",\n        count(*) over() as "count",\n        c.relrowsecurity as "rls_enabled"\n      from\n        pg_namespace nc\n        join pg_class c on nc.oid = c.relnamespace\n      where\n        c.relkind in ($11, $12, $13, $14, $15)\n        and not pg_is_other_temp_schema(nc.oid)\n        and (\n          pg_has_role(c.relowner, $16)\n          or has_table_privilege(\n            c.oid,\n            $17\n          )\n          or has_any_column_privilege(c.oid, $18)\n        )\n        and nc.nspname = $19\n        \n      order by c.relname asc\n      limit $20\n      offset $21\n    )\n    select\n      jsonb_build_object(\n        $22, coalesce(jsonb_agg(\n          jsonb_build_object(\n            $23, r.id,\n            $24, r.schema,\n            $25, r.name,\n            $26, r.type,\n            $27, r.comment,\n            $28, r.rls_enabled\n          )\n          order by r.name asc\n        ), $29::jsonb),\n        $30, coalesce(min(r.count), $31)\n      ) "data"\n    from records r',
          rows: 6,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 6,
            minTime: 0.806098,
            maxTime: 0.965947,
            sumTime: 5.26738,
            meanTime: 0.877896666666667,
            sdTime: 0.0530151403489817,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 936,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-140428224511061580",
          database: "postgres",
          query:
            'SELECT "data" AS value FROM "public"."events" WHERE "data" IS NOT NULL LIMIT $1',
          rows: 64,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.168728,
            maxTime: 5.046215,
            sumTime: 5.214943,
            meanTime: 2.6074715,
            sdTime: 2.4387435,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 18,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "8412188623179259000",
          database: "postgres",
          query:
            'SELECT u1."id", u1."slug", u1."name", u1."email", u1."provider", u1."provider_uid", u1."provider_data", u1."avatar", u1."onboarding", u1."github_username", u1."twitter_username", u1."is_admin", u1."hashed_password", u1."last_signin", u1."data", u1."created_at", u1."updated_at", u1."confirmed_at", u1."deleted_at" FROM "user_tokens" AS u0 INNER JOIN "users" AS u1 ON u1."id" = u0."user_id" WHERE ((u0."token" = $1) AND (u0."context" = $2)) AND (u0."created_at" > $3::timestamp + (-($4)::numeric * interval $5))',
          rows: 73,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 73,
            minTime: 0.058543,
            maxTime: 0.110776,
            sumTime: 5.133075,
            meanTime: 0.070316095890411,
            sdTime: 0.0114092792638086,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 331,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5793547805839326000",
          database: "postgres",
          query:
            'SELECT to_char(e0."created_at", $1), count(*) FROM "events" AS e0 GROUP BY to_char(e0."created_at", \'yyyy-mm\') ORDER BY to_char(e0."created_at", \'yyyy-mm\')',
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.026797,
            maxTime: 4.537828,
            sumTime: 4.882433,
            meanTime: 1.22060825,
            sdTime: 1.91598485374394,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 31,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5060855294444425000",
          database: "postgres",
          query:
            "SELECT version()\n             , inet_server_addr() AS address\n             , inet_server_port() AS port\n             , user\n             , datname            AS database\n             , current_schema()   AS schema\n             , xact_commit        AS commits\n             , xact_rollback      AS rollbacks\n             , blks_read\n             , blks_hit\n             , tup_returned\n             , tup_inserted\n             , tup_updated\n             , tup_deleted\n        FROM pg_stat_database\n        WHERE datname = current_database()",
          rows: 51,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 51,
            minTime: 0.040943,
            maxTime: 0.81751,
            sumTime: 4.19298,
            meanTime: 0.0822152941176471,
            sdTime: 0.148727933218422,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 51,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6045092923094146000",
          database: "postgres",
          query:
            'SELECT o0."id", o0."slug", o0."name", o0."logo", o0."description", o0."github_username", o0."twitter_username", o0."stripe_customer_id", o0."stripe_subscription_id", o0."is_personal", o0."data", o0."created_by", o0."updated_by", o0."created_at", o0."updated_at", o0."deleted_by", o0."deleted_at", o1."user_id"::uuid FROM "organizations" AS o0 INNER JOIN "organization_members" AS o1 ON o0."id" = o1."organization_id" WHERE (o1."user_id" = ANY($1)) ORDER BY o1."user_id"::uuid',
          rows: 73,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 73,
            minTime: 0.035363,
            maxTime: 0.065738,
            sumTime: 3.579099,
            meanTime: 0.0490287534246575,
            sdTime: 0.00555299239280436,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 346,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3370311526131341000",
          database: "postgres",
          query:
            'select\n      c.oid::int8 as "id",\n      nc.nspname as "schema",\n      c.relname as "name",\n      c.relkind as "type",\n      obj_description(c.oid) as "comment",\n      count(*) over() as "count"\n    from\n      pg_namespace nc\n      join pg_class c on nc.oid = c.relnamespace\n    where\n      c.relkind in ($1, $2, $3, $4, $5)\n      and not pg_is_other_temp_schema(nc.oid)\n      and (\n        pg_has_role(c.relowner, $6)\n        or has_table_privilege(\n          c.oid,\n          $7\n        )\n        or has_any_column_privilege(c.oid, $8)\n      )\n      and c.oid = $9\n    limit $10',
          rows: 7,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 7,
            minTime: 0.366225,
            maxTime: 1.13648,
            sumTime: 3.500853,
            meanTime: 0.500121857142857,
            sdTime: 0.260621706213337,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 665,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1415329159288067300",
          database: "postgres",
          query:
            "WITH\n      role_setting AS (\n        SELECT setdatabase as database,\n               unnest(setconfig) as setting\n        FROM pg_catalog.pg_db_role_setting\n        WHERE setrole = CURRENT_USER::regrole::oid\n          AND setdatabase IN ($2, (SELECT oid FROM pg_catalog.pg_database WHERE datname = CURRENT_CATALOG))\n      ),\n      kv_settings AS (\n        SELECT database,\n               substr(setting, $3, strpos(setting, $4) - $5) as k,\n               substr(setting, strpos(setting, $6) + $7) as v\n        FROM role_setting\n        \n      )\n      SELECT DISTINCT ON (key)\n             replace(k, $8, $9) AS key,\n             v AS value\n      FROM kv_settings\n      WHERE k = ANY($1) AND v IS NOT NULL\n      ORDER BY key, database DESC NULLS LAST",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 48,
            minTime: 0.063827,
            maxTime: 0.145106,
            sumTime: 3.435302,
            meanTime: 0.0715687916666667,
            sdTime: 0.0127853036415487,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 624,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "373724332603617660",
          database: "postgres",
          query:
            'INSERT INTO "user_tokens" ("context","token","sent_to","user_id","id","created_at") VALUES ($1,$2,$3,$4,$5,$6)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 3.270349,
            maxTime: 3.270349,
            sumTime: 3.270349,
            meanTime: 3.270349,
            sdTime: 0,
          },
          blocks: {
            sumRead: 3,
            sumWrite: 4,
            sumHit: 244,
            sumDirty: 7,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7187574263740722000",
          database: "postgres",
          query:
            "SELECT\n  version(),\n  current_setting($1) :: int8 AS version_number,\n  (\n    SELECT\n      COUNT(*) AS active_connections\n    FROM\n      pg_stat_activity\n  ) AS active_connections,\n  current_setting($2) :: int8 AS max_connections",
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.069712,
            maxTime: 2.603737,
            sumTime: 2.864479,
            meanTime: 0.71611975,
            sdTime: 1.08995423349478,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1793092195096027400",
          database: "postgres",
          query:
            'INSERT INTO "realtime"."schema_migrations" ("version","inserted_at") VALUES ($1,$2)',
          rows: 43,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 43,
            minTime: 0.021653,
            maxTime: 1.01902,
            sumTime: 2.701108,
            meanTime: 0.0628164651162791,
            sdTime: 0.149546701174435,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 2,
            sumHit: 96,
            sumDirty: 5,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6388742881990790000",
          database: "postgres",
          query:
            "SELECT current_setting($1)::integer, current_setting($2), version()",
          rows: 96,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 96,
            minTime: 0.010979,
            maxTime: 0.934351,
            sumTime: 2.49882,
            meanTime: 0.026029375,
            sdTime: 0.0933118735438058,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5471563966999158000",
          database: "postgres",
          query:
            "select\n        description\n      from\n        pg_namespace n\n        left join pg_description d on d.objoid = n.oid\n      where\n        n.nspname = $1",
          rows: 33,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 33,
            minTime: 0.023073,
            maxTime: 0.534954,
            sumTime: 2.413263,
            meanTime: 0.0731291818181818,
            sdTime: 0.135516813829995,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 131,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3567844888757175000",
          database: "postgres",
          query:
            'SELECT u0."id", u0."slug", u0."name", u0."email", u0."provider", u0."provider_uid", u0."provider_data", u0."avatar", u0."onboarding", u0."github_username", u0."twitter_username", u0."is_admin", u0."hashed_password", u0."last_signin", u0."data", u0."created_at", u0."updated_at", u0."confirmed_at", u0."deleted_at", u0."id" FROM "users" AS u0 WHERE (u0."id" = $1)',
          rows: 37,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 37,
            minTime: 0.04434,
            maxTime: 0.095671,
            sumTime: 2.395976,
            meanTime: 0.0647561081081081,
            sdTime: 0.0151842533491804,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 101,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1602107216694490000",
          database: "postgres",
          query:
            "SELECT concat(table_schema, $1, table_name) as table\n    FROM   information_schema.tables\n    WHERE table_schema not like $2 and table_schema <> $3\n    ORDER  BY 1 desc",
          rows: 168,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.536463,
            maxTime: 0.623732,
            sumTime: 2.261988,
            meanTime: 0.565497,
            sdTime: 0.0341874462558992,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 868,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3059275653697452500",
          database: "postgres",
          query:
            'select *,case when length("name"::text) > $1 then concat(left("name"::text, $2), $3) else "name"::text end "name",case when length("provider"::text) > $4 then concat(left("provider"::text, $5), $6) else "provider"::text end "provider",case when length("provider_uid"::text) > $7 then concat(left("provider_uid"::text, $8), $9) else "provider_uid"::text end "provider_uid",case when length("avatar"::text) > $10 then concat(left("avatar"::text, $11), $12) else "avatar"::text end "avatar",case when length("github_username"::text) > $13 then concat(left("github_username"::text, $14), $15) else "github_username"::text end "github_username",case when length("twitter_username"::text) > $16 then concat(left("twitter_username"::text, $17), $18) else "twitter_username"::text end "twitter_username",case when length("hashed_password"::text) > $19 then concat(left("hashed_password"::text, $20), $21) else "hashed_password"::text end "hashed_password",case when length("data"::text) > $22 then concat(left("data"::text, $23), $24) else "data"::text end "data",case when length("onboarding"::text) > $25 then concat(left("onboarding"::text, $26), $27) else "onboarding"::text end "onboarding",case when length("provider_data"::text) > $28 then concat(left("provider_data"::text, $29), $30) else "provider_data"::text end "provider_data" from public.users limit $31 offset $32',
          rows: 11,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 6,
            minTime: 0.078473,
            maxTime: 1.432777,
            sumTime: 1.838642,
            meanTime: 0.306440333333333,
            sdTime: 0.503718770689448,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 24,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7943763177129919000",
          database: "postgres",
          query:
            'SELECT s0."version" FROM "realtime"."schema_migrations" AS s0',
          rows: 988,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 46,
            minTime: 0.004308,
            maxTime: 0.873839,
            sumTime: 1.800366,
            meanTime: 0.0391383913043478,
            sdTime: 0.12457481473282,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 44,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-649969969607119900",
          database: "postgres",
          query: 'SELECT s0."version"::bigint FROM "schema_migrations" AS s0',
          rows: 1211,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 95,
            minTime: 0.004086,
            maxTime: 0.034051,
            sumTime: 1.791013,
            meanTime: 0.0188527684210526,
            sdTime: 0.00464729547711724,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 93,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3782783776398072300",
          database: "postgres",
          query:
            "SELECT\n          set_config('role', $1, true),\n          set_config('request.jwt.claim.role', $2, true),\n          set_config('request.jwt', $3, true),\n          set_config('request.jwt.claim.sub', $4, true),\n          set_config('request.jwt.claims', $5, true),\n          set_config('request.headers', $6, true),\n          set_config('request.method', $7, true),\n          set_config('request.path', $8, true),\n          set_config('storage.operation', $9, true)",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.859883,
            maxTime: 0.918655,
            sumTime: 1.778538,
            meanTime: 0.889269,
            sdTime: 0.029386,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 32,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4335148861557841400",
          database: "postgres",
          query:
            'SELECT u0."id", u0."user_id", u0."usage", u0."usecase", u0."role", u0."phone", u0."location", u0."description", u0."company", u0."company_size", u0."industry", u0."team_organization_id", u0."plan", u0."discovered_by", u0."previously_tried", u0."product_updates", u0."created_at", u0."updated_at", u0."user_id" FROM "user_profiles" AS u0 WHERE (u0."user_id" = $1)',
          rows: 71,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 73,
            minTime: 0.005276,
            maxTime: 0.053866,
            sumTime: 1.755643,
            meanTime: 0.024049904109589,
            sdTime: 0.00534625597367078,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 71,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1066520023094224100",
          database: "postgres",
          query:
            "SELECT concat(conrelid::regclass, $1, conname) as fk\n    FROM   pg_constraint \n    WHERE  contype = $2 \n    ORDER  BY 1 desc",
          rows: 176,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.415193,
            maxTime: 0.463109,
            sumTime: 1.73231,
            meanTime: 0.4330775,
            sdTime: 0.0179989639215706,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 700,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5088337955354080000",
          database: "postgres",
          query:
            'INSERT INTO "organizations" ("name","logo","is_personal","github_username","twitter_username","slug","created_by","updated_by","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 1.544031,
            maxTime: 1.544031,
            sumTime: 1.544031,
            meanTime: 1.544031,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 4,
            sumHit: 194,
            sumDirty: 7,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "948634954970571900",
          database: "postgres",
          query:
            'INSERT INTO "organization_members" ("organization_id","user_id","created_by","updated_by","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6)',
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.730855,
            maxTime: 0.782071,
            sumTime: 1.512926,
            meanTime: 0.756463,
            sdTime: 0.025608,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 2,
            sumHit: 162,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6380455482040435000",
          database: "postgres",
          query:
            'INSERT INTO "projects" ("id","name","storage_kind","visibility","nb_sources","nb_tables","nb_columns","nb_relations","nb_types","nb_comments","nb_layouts","nb_notes","nb_memos","organization_id","slug","created_by","encoding_version","updated_by","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 1.509316,
            maxTime: 1.509316,
            sumTime: 1.509316,
            meanTime: 1.509316,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 3,
            sumHit: 195,
            sumDirty: 5,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1273670927330056400",
          database: "postgres",
          query:
            'UPDATE "users" SET "updated_at" = $1, "onboarding" = $2 WHERE "id" = $3',
          rows: 12,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 12,
            minTime: 0.054596,
            maxTime: 0.213043,
            sumTime: 1.345266,
            meanTime: 0.1121055,
            sdTime: 0.0504379175612621,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 281,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8773512246132630000",
          database: "postgres",
          query:
            'SELECT "data" AS value FROM "public"."users" WHERE "data" IS NOT NULL LIMIT $1',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.020578,
            maxTime: 1.318858,
            sumTime: 1.339436,
            meanTime: 0.669718,
            sdTime: 0.64914,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1018477700529464200",
          database: "postgres",
          query:
            'SELECT p0."id", p0."organization_id", p0."slug", p0."name", p0."description", p0."encoding_version", p0."storage_kind", p0."file", p0."local_owner", p0."visibility", p0."nb_sources", p0."nb_tables", p0."nb_columns", p0."nb_relations", p0."nb_types", p0."nb_comments", p0."nb_layouts", p0."nb_notes", p0."nb_memos", p0."created_by", p0."updated_by", p0."created_at", p0."updated_at", p0."archived_by", p0."archived_at", p0."organization_id" FROM "projects" AS p0 WHERE (p0."organization_id" = $1) ORDER BY p0."organization_id"',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 79,
            minTime: 0.00627,
            maxTime: 0.06043,
            sumTime: 1.307616,
            meanTime: 0.0165521012658228,
            sdTime: 0.00858034214979022,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 79,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2981954321557361000",
          database: "postgres",
          query:
            'INSERT INTO "gallery" ("description","color","slug","website","analysis","banner","icon","tips","project_id","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 1.289092,
            maxTime: 1.289092,
            sumTime: 1.289092,
            meanTime: 1.289092,
            sdTime: 0,
          },
          blocks: {
            sumRead: 3,
            sumWrite: 4,
            sumHit: 176,
            sumDirty: 7,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6981127566880145000",
          database: "postgres",
          query: "insert into schema_migrations (version) values ($1)",
          rows: 49,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 49,
            minTime: 0.017632,
            maxTime: 0.134901,
            sumTime: 1.244641,
            meanTime: 0.0254008367346939,
            sdTime: 0.0170823830093891,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 98,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3231711186105647000",
          database: "postgres",
          query:
            'INSERT INTO "events" ("data","name","organization_id","project_id","created_by","id","created_at") VALUES ($1,$2,$3,$4,$5,$6,$7)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 1.212203,
            maxTime: 1.212203,
            sumTime: 1.212203,
            meanTime: 1.212203,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 7,
            sumHit: 161,
            sumDirty: 13,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4990873535982172000",
          database: "postgres",
          query:
            "-- Adapted from information_schema.schemata\n\nselect\n  n.oid::int8 as id,\n  n.nspname as name,\n  u.rolname as owner\nfrom\n  pg_namespace n,\n  pg_roles u\nwhere\n  n.nspowner = u.oid\n  and (\n    pg_has_role(n.nspowner, $1)\n    or has_schema_privilege(n.oid, $2)\n  )\n  and not pg_catalog.starts_with(n.nspname, $3)\n  and not pg_catalog.starts_with(n.nspname, $4)\n and not (n.nspname in ($5,$6,$7))\n\n-- source: dashboard\n-- user: a374796d-3e4c-416d-8d5c-8976fdecb2f2\n-- date: 2024-06-17T10:03:54.322Z",
          rows: 60,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 6,
            minTime: 0.18669,
            maxTime: 0.202984,
            sumTime: 1.166185,
            meanTime: 0.194364166666667,
            sdTime: 0.00594693434795516,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 394,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6858202202867540000",
          database: "postgres",
          query:
            'SELECT to_char(e0."created_at", $3), count(DISTINCT e0."id") FROM "events" AS e0 WHERE ((e0."created_by" = $1) AND (e0."created_at" >= $2)) GROUP BY to_char(e0."created_at", \'yyyy-mm-dd\')',
          rows: 5,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 5,
            minTime: 0.206258,
            maxTime: 0.27038,
            sumTime: 1.165797,
            meanTime: 0.2331594,
            sdTime: 0.0222105044211067,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 69,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7477122626093006000",
          database: "postgres",
          query:
            'INSERT INTO "user_tokens" ("context","token","user_id","id","created_at") VALUES ($1,$2,$3,$4,$5)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 1.070487,
            maxTime: 1.070487,
            sumTime: 1.070487,
            meanTime: 1.070487,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 260,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6940489802359236000",
          database: "postgres",
          query:
            'SELECT h0."id", h0."organization_id", h0."name", h0."app", h0."plan", h0."region", h0."options", h0."callback", h0."oauth_code", h0."oauth_type", h0."oauth_expire", h0."created_at", h0."updated_at", h0."deleted_at", h0."organization_id" FROM "heroku_resources" AS h0 WHERE (h0."organization_id" = $1)',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 79,
            minTime: 0.006949,
            maxTime: 0.061496,
            sumTime: 1.052101,
            meanTime: 0.0133177341772152,
            sdTime: 0.00888482455139577,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 79,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4526807323065030000",
          database: "postgres",
          query: "SELECT * FROM migrations ORDER BY id",
          rows: 24,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.014817,
            maxTime: 1.015582,
            sumTime: 1.030399,
            meanTime: 0.5151995,
            sdTime: 0.5003825,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 3,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5994963799098638000",
          database: "postgres",
          query:
            'INSERT INTO "organizations" ("name","description","logo","is_personal","github_username","twitter_username","slug","created_by","updated_by","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.968932,
            maxTime: 0.968932,
            sumTime: 0.968932,
            meanTime: 0.968932,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 190,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "775148666183870000",
          database: "postgres",
          query:
            'SELECT c0."id", c0."organization_id", c0."addon_id", c0."owner_id", c0."owner_name", c0."user_id", c0."plan", c0."region", c0."callback_url", c0."logplex_token", c0."options", c0."created_at", c0."updated_at", c0."deleted_at", c0."organization_id" FROM "clever_cloud_resources" AS c0 WHERE (c0."organization_id" = $1)',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 79,
            minTime: 0.007729,
            maxTime: 0.028095,
            sumTime: 0.9575,
            meanTime: 0.012120253164557,
            sdTime: 0.00311121244007864,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 79,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-9019886891239799000",
          database: "postgres",
          query:
            'INSERT INTO "events" ("data","name","organization_id","created_by","id","created_at") VALUES ($1,$2,$3,$4,$5,$6)',
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.435228,
            maxTime: 0.458407,
            sumTime: 0.893635,
            meanTime: 0.4468175,
            sdTime: 0.0115895,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 2,
            sumHit: 34,
            sumDirty: 4,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4825873993955022000",
          database: "postgres",
          query:
            "SELECT EXISTS (SELECT schema_migrations.* FROM schema_migrations AS schema_migrations WHERE version = $1)",
          rows: 49,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 49,
            minTime: 0.012496,
            maxTime: 0.041739,
            sumTime: 0.886117,
            meanTime: 0.0180840204081633,
            sdTime: 0.00511456338228595,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 48,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6241766914641446000",
          database: "postgres",
          query:
            "SELECT \n          set_config($6, $1, $7),\n          set_config($8, $2, $9),\n          set_config($10, $3, $11),\n          set_config($12, $4, $13),\n          set_config($14, $5, $15)",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.435321,
            maxTime: 0.4366,
            sumTime: 0.871921,
            meanTime: 0.4359605,
            sdTime: 0.000639499999999973,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "8331478758931055000",
          database: "postgres",
          query:
            "SELECT\n          set_config('role', $1, true),\n          set_config('request.jwt.claim.role', $2, true),\n          set_config('request.jwt', $3, true),\n          set_config('request.jwt.claim.sub', $4, true),\n          set_config('request.jwt.claims', $5, true),\n          set_config('request.headers', $6, true),\n          set_config('request.method', $7, true),\n          set_config('request.path', $8, true)",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.82948,
            maxTime: 0.82948,
            sumTime: 0.82948,
            meanTime: 0.82948,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 16,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "829400040807800000",
          database: "postgres",
          query:
            'INSERT INTO "user_profiles" ("user_id","id","created_at","updated_at") VALUES ($1,$2,$3,$4)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.775499,
            maxTime: 0.775499,
            sumTime: 0.775499,
            meanTime: 0.775499,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 2,
            sumHit: 83,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7110205386120132000",
          database: "postgres",
          query: "SELECT extname FROM pg_extension WHERE extname = $1",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 0.014474,
            maxTime: 0.57698,
            sumTime: 0.726298,
            meanTime: 0.0726298,
            sdTime: 0.168135224833941,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 20,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2632893050920604000",
          database: "postgres",
          query:
            'INSERT INTO "schema_migrations" ("version","inserted_at") VALUES ($1,$2)',
          rows: 14,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 14,
            minTime: 0.028365,
            maxTime: 0.232875,
            sumTime: 0.718375,
            meanTime: 0.0513125,
            sdTime: 0.0552703205653166,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 2,
            sumHit: 29,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5610616297990847000",
          database: "postgres",
          query: "select * from schema_migrations",
          rows: 7,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.654046,
            maxTime: 0.654046,
            sumTime: 0.654046,
            meanTime: 0.654046,
            sdTime: 0,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-372025862736725570",
          database: "postgres",
          query: 'SELECT * FROM "public"."events" LIMIT $1',
          rows: 100,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.074002,
            maxTime: 0.303342,
            sumTime: 0.638469,
            meanTime: 0.212823,
            sdTime: 0.0996628359453346,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 19,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5886259281561324000",
          database: "postgres",
          query:
            'INSERT INTO "users" ("name","email","is_admin","avatar","github_username","twitter_username","slug","last_signin","confirmed_at","hashed_password","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.63045,
            maxTime: 0.63045,
            sumTime: 0.63045,
            meanTime: 0.63045,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 4,
            sumHit: 53,
            sumDirty: 7,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2406451878267622000",
          database: "postgres",
          query:
            'INSERT INTO "organization_members" ("organization_id","created_by","user_id","updated_by","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.576798,
            maxTime: 0.576798,
            sumTime: 0.576798,
            meanTime: 0.576798,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 44,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5124029095750082000",
          database: "postgres",
          query:
            'SELECT u0."id", u0."user_id", u0."usage", u0."usecase", u0."role", u0."phone", u0."location", u0."description", u0."company", u0."company_size", u0."industry", u0."team_organization_id", u0."plan", u0."discovered_by", u0."previously_tried", u0."product_updates", u0."created_at", u0."updated_at" FROM "user_profiles" AS u0 WHERE (u0."user_id" = $1)',
          rows: 25,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 26,
            minTime: 0.005326,
            maxTime: 0.034108,
            sumTime: 0.576658,
            meanTime: 0.0221791538461538,
            sdTime: 0.00488736447533769,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 25,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3175872006656358400",
          database: "postgres",
          query:
            'UPDATE "users" SET "data" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.119727,
            maxTime: 0.180068,
            sumTime: 0.576223,
            meanTime: 0.14405575,
            sdTime: 0.0247319607529913,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 162,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-42535252135937230",
          database: "postgres",
          query:
            'SELECT "options" AS value FROM "public"."clever_cloud_resources" WHERE "options" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.010888,
            maxTime: 0.520989,
            sumTime: 0.531877,
            meanTime: 0.2659385,
            sdTime: 0.2550505,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3368671980488063500",
          database: "postgres",
          query:
            'INSERT INTO "organizations" ("name","logo","slug","is_personal","created_by","updated_by","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.523383,
            maxTime: 0.523383,
            sumTime: 0.523383,
            meanTime: 0.523383,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 45,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6853517864600989000",
          database: "postgres",
          query:
            'SELECT "data" AS value FROM "public"."organizations" WHERE "data" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.018576,
            maxTime: 0.468009,
            sumTime: 0.486585,
            meanTime: 0.2432925,
            sdTime: 0.2247165,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3740930875486531000",
          database: "postgres",
          query:
            "SELECT \n    con.oid as id,\n    con.conname as name,\n    con.contype as type\n  FROM pg_catalog.pg_constraint con\n  INNER JOIN pg_catalog.pg_class rel\n            ON rel.oid = con.conrelid\n  INNER JOIN pg_catalog.pg_namespace nsp\n            ON nsp.oid = connamespace\n  WHERE nsp.nspname = $1\n        AND rel.relname = $2",
          rows: 6,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 6,
            minTime: 0.058756,
            maxTime: 0.080493,
            sumTime: 0.421921,
            meanTime: 0.0703201666666667,
            sdTime: 0.00643376212949227,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 120,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2521024749853354000",
          database: "postgres",
          query:
            'INSERT INTO "heroku_resources" ("id","name","callback","plan","region","oauth_code","oauth_expire","oauth_type","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.397984,
            maxTime: 0.397984,
            sumTime: 0.397984,
            meanTime: 0.397984,
            sdTime: 0,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 2,
            sumHit: 39,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2790939160818339300",
          database: "postgres",
          query: 'SELECT count(*) FROM "users" AS u0',
          rows: 10,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 0.009895,
            maxTime: 0.065642,
            sumTime: 0.350749,
            meanTime: 0.0350749,
            sdTime: 0.0136249791592501,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 19,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4059482809072508400",
          database: "postgres",
          query:
            'SELECT count(DISTINCT e0."organization_id") FROM "events" AS e0 WHERE (e0."created_at" > $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.067453,
            maxTime: 0.106156,
            sumTime: 0.342911,
            meanTime: 0.08572775,
            sdTime: 0.0151961280820971,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 47,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5067483898714052000",
          database: "postgres",
          query:
            'SELECT count(DISTINCT e0."created_by") FROM "events" AS e0 WHERE (e0."created_at" > $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.062661,
            maxTime: 0.098657,
            sumTime: 0.342387,
            meanTime: 0.08559675,
            sdTime: 0.0137216923951639,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 49,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2739088974676371500",
          database: "postgres",
          query: 'UPDATE "users" SET "updated_at" = $1 WHERE "id" = $2',
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.148742,
            maxTime: 0.185319,
            sumTime: 0.334061,
            meanTime: 0.1670305,
            sdTime: 0.0182885,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 78,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2663475806080570000",
          database: "postgres",
          query:
            'INSERT INTO "users" ("data","name","avatar","email","slug","is_admin","hashed_password","last_signin","onboarding","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.316739,
            maxTime: 0.316739,
            sumTime: 0.316739,
            meanTime: 0.316739,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6090266704678114000",
          database: "postgres",
          query:
            'SELECT count(DISTINCT e0."project_id") FROM "events" AS e0 WHERE (e0."created_at" > $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.057469,
            maxTime: 0.094227,
            sumTime: 0.31304,
            meanTime: 0.07826,
            sdTime: 0.0160065520647015,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 47,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4458514342673228000",
          database: "postgres",
          query:
            'INSERT INTO "clever_cloud_resources" ("plan","addon_id","callback_url","region","owner_name","owner_id","user_id","logplex_token","id","created_at","updated_at") VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.289244,
            maxTime: 0.289244,
            sumTime: 0.289244,
            meanTime: 0.289244,
            sdTime: 0,
          },
          blocks: {
            sumRead: 1,
            sumWrite: 2,
            sumHit: 18,
            sumDirty: 3,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-968767906563173200",
          database: "postgres",
          query:
            'SELECT\n  pol.oid :: int8 AS id,\n  n.nspname AS schema,\n  c.relname AS table,\n  c.oid :: int8 AS table_id,\n  pol.polname AS name,\n  CASE\n    WHEN pol.polpermissive THEN $1 :: text\n    ELSE $2 :: text\n  END AS action,\n  CASE\n    WHEN pol.polroles = $3 :: oid [] THEN array_to_json(\n      string_to_array($4 :: text, $5 :: text) :: name []\n    )\n    ELSE array_to_json(\n      ARRAY(\n        SELECT\n          pg_roles.rolname\n        FROM\n          pg_roles\n        WHERE\n          pg_roles.oid = ANY (pol.polroles)\n        ORDER BY\n          pg_roles.rolname\n      )\n    )\n  END AS roles,\n  CASE\n    pol.polcmd\n    WHEN $6 :: "char" THEN $7 :: text\n    WHEN $8 :: "char" THEN $9 :: text\n    WHEN $10 :: "char" THEN $11 :: text\n    WHEN $12 :: "char" THEN $13 :: text\n    WHEN $14 :: "char" THEN $15 :: text\n    ELSE $16 :: text\n  END AS command,\n  pg_get_expr(pol.polqual, pol.polrelid) AS definition,\n  pg_get_expr(pol.polwithcheck, pol.polrelid) AS check\nFROM\n  pg_policy pol\n  JOIN pg_class c ON c.oid = pol.polrelid\n  LEFT JOIN pg_namespace n ON n.oid = c.relnamespace\n WHERE n.nspname NOT IN ($17,$18,$19)',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.060119,
            maxTime: 0.068429,
            sumTime: 0.256981,
            meanTime: 0.06424525,
            sdTime: 0.00352433925544917,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 12,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-693469685008623600",
          database: "postgres",
          query: 'UPDATE "user_profiles" SET "updated_at" = $1 WHERE "id" = $2',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.051068,
            maxTime: 0.08379,
            sumTime: 0.252289,
            meanTime: 0.06307225,
            sdTime: 0.0127731443344033,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 28,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8262913608705439000",
          database: "postgres",
          query:
            "SELECT concat(schemaname, $1, tablename, $2, policyname) as policy\n    FROM   pg_policies\n    ORDER  BY 1 desc",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.054342,
            maxTime: 0.060438,
            sumTime: 0.228682,
            meanTime: 0.0571705,
            sdTime: 0.00266708309769306,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 20,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2514992795273247000",
          database: "postgres",
          query:
            'with views as (SELECT\n  c.oid :: int8 AS id,\n  n.nspname AS schema,\n  c.relname AS name,\n  -- See definition of information_schema.views\n  (pg_relation_is_updatable(c.oid, $1) & $2) = $3 AS is_updatable,\n  obj_description(c.oid) AS comment\nFROM\n  pg_class c\n  JOIN pg_namespace n ON n.oid = c.relnamespace\nWHERE\n  c.relkind = $4\n)\n  , columns as (-- Adapted from information_schema.columns\n\nSELECT\n  c.oid :: int8 AS table_id,\n  nc.nspname AS schema,\n  c.relname AS table,\n  (c.oid || $5 || a.attnum) AS id,\n  a.attnum AS ordinal_position,\n  a.attname AS name,\n  CASE\n    WHEN a.atthasdef THEN pg_get_expr(ad.adbin, ad.adrelid)\n    ELSE $6\n  END AS default_value,\n  CASE\n    WHEN t.typtype = $7 THEN CASE\n      WHEN bt.typelem <> $8 :: oid\n      AND bt.typlen = $9 THEN $10\n      WHEN nbt.nspname = $11 THEN format_type(t.typbasetype, $12)\n      ELSE $13\n    END\n    ELSE CASE\n      WHEN t.typelem <> $14 :: oid\n      AND t.typlen = $15 THEN $16\n      WHEN nt.nspname = $17 THEN format_type(a.atttypid, $18)\n      ELSE $19\n    END\n  END AS data_type,\n  COALESCE(bt.typname, t.typname) AS format,\n  a.attidentity IN ($20, $21) AS is_identity,\n  CASE\n    a.attidentity\n    WHEN $22 THEN $23\n    WHEN $24 THEN $25\n    ELSE $26\n  END AS identity_generation,\n  a.attgenerated IN ($27) AS is_generated,\n  NOT (\n    a.attnotnull\n    OR t.typtype = $28 AND t.typnotnull\n  ) AS is_nullable,\n  (\n    c.relkind IN ($29, $30)\n    OR c.relkind IN ($31, $32) AND pg_column_is_updatable(c.oid, a.attnum, $33)\n  ) AS is_updatable,\n  uniques.table_id IS NOT NULL AS is_unique,\n  check_constraints.definition AS "check",\n  array_to_json(\n    array(\n      SELECT\n        enumlabel\n      FROM\n        pg_catalog.pg_enum enums\n      WHERE\n        enums.enumtypid = coalesce(bt.oid, t.oid)\n        OR enums.enumtypid = coalesce(bt.typelem, t.typelem)\n      ORDER BY\n        enums.enumsortorder\n    )\n  ) AS enums,\n  col_description(c.oid, a.attnum) AS comment\nFROM\n  pg_attribute a\n  LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid\n  AND a.attnum = ad.adnum\n  JOIN (\n    pg_class c\n    JOIN pg_namespace nc ON c.relnamespace = nc.oid\n  ) ON a.attrelid = c.oid\n  JOIN (\n    pg_type t\n    JOIN pg_namespace nt ON t.typnamespace = nt.oid\n  ) ON a.atttypid = t.oid\n  LEFT JOIN (\n    pg_type bt\n    JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid\n  ) ON t.typtype = $34\n  AND t.typbasetype = bt.oid\n  LEFT JOIN (\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$35] AS ordinal_position\n    FROM pg_catalog.pg_constraint\n    WHERE contype = $36 AND cardinality(conkey) = $37\n  ) AS uniques ON uniques.table_id = c.oid AND uniques.ordinal_position = a.attnum\n  LEFT JOIN (\n    -- We only select the first column check\n    SELECT DISTINCT ON (table_id, ordinal_position)\n      conrelid AS table_id,\n      conkey[$38] AS ordinal_position,\n      substring(\n        pg_get_constraintdef(pg_constraint.oid, $39),\n        $40,\n        length(pg_get_constraintdef(pg_constraint.oid, $41)) - $42\n      ) AS "definition"\n    FROM pg_constraint\n    WHERE contype = $43 AND cardinality(conkey) = $44\n    ORDER BY table_id, ordinal_position, oid asc\n  ) AS check_constraints ON check_constraints.table_id = c.oid AND check_constraints.ordinal_position = a.attnum\nWHERE\n  NOT pg_is_other_temp_schema(nc.oid)\n  AND a.attnum > $45\n  AND NOT a.attisdropped\n  AND (c.relkind IN ($46, $47, $48, $49, $50))\n  AND (\n    pg_has_role(c.relowner, $51)\n    OR has_column_privilege(\n      c.oid,\n      a.attnum,\n      $52\n    )\n  )\n)\nselect\n  *\n  , \nCOALESCE(\n  (\n    SELECT\n      array_agg(row_to_json(columns)) FILTER (WHERE columns.table_id = views.id)\n    FROM\n      columns\n  ),\n  $53\n) AS columns\nfrom views where schema IN ($54)',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.218952,
            maxTime: 0.218952,
            sumTime: 0.218952,
            meanTime: 0.218952,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 35,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3892069652436444000",
          database: "postgres",
          query:
            'SELECT g0."id", g0."project_id", g0."slug", g0."icon", g0."color", g0."website", g0."banner", g0."tips", g0."description", g0."analysis", g0."created_at", g0."updated_at" FROM "gallery" AS g0 INNER JOIN "projects" AS p1 ON g0."project_id" = p1."id" WHERE (p1."visibility" != $1) ORDER BY p1."nb_tables"',
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.060447,
            maxTime: 0.07263,
            sumTime: 0.202115,
            meanTime: 0.0673716666666667,
            sdTime: 0.00511135157163826,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 15,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "211264209551031000",
          database: "postgres",
          query:
            "SELECT extname FROM pg_extension WHERE (extname = $1 and extversion <> $2) or (extname = $3 and extversion <> $4)",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 0.017748,
            maxTime: 0.02235,
            sumTime: 0.197475,
            meanTime: 0.0197475,
            sdTime: 0.00135345980730866,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 20,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3469976273697136000",
          database: "postgres",
          query:
            "SELECT \n        rolname FROM pg_authid \n        WHERE rolcanlogin = $1 \n          AND rolname NOT LIKE $2 \n          AND ROLNAME NOT IN ($3, $4, $5, $6) \n          AND rolpassword LIKE $7",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 10,
            minTime: 0.01641,
            maxTime: 0.026371,
            sumTime: 0.195372,
            meanTime: 0.0195372,
            sdTime: 0.00273208505724108,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 10,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7819107306175918000",
          database: "postgres",
          query:
            'SELECT p0."id", p0."organization_id", p0."slug", p0."name", p0."description", p0."encoding_version", p0."storage_kind", p0."file", p0."local_owner", p0."visibility", p0."nb_sources", p0."nb_tables", p0."nb_columns", p0."nb_relations", p0."nb_types", p0."nb_comments", p0."nb_layouts", p0."nb_notes", p0."nb_memos", p0."created_by", p0."updated_by", p0."created_at", p0."updated_at", p0."archived_by", p0."archived_at", p0."id" FROM "projects" AS p0 WHERE (p0."id" = $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.034601,
            maxTime: 0.071983,
            sumTime: 0.194688,
            meanTime: 0.048672,
            sdTime: 0.0140007744428657,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 11,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4000136187496019000",
          database: "postgres",
          query:
            'SELECT o0."id", o0."slug", o0."name", o0."logo", o0."description", o0."github_username", o0."twitter_username", o0."stripe_customer_id", o0."stripe_subscription_id", o0."is_personal", o0."data", o0."created_by", o0."updated_by", o0."created_at", o0."updated_at", o0."deleted_by", o0."deleted_at" FROM "organizations" AS o0 INNER JOIN "organization_members" AS o1 ON o1."organization_id" = o0."id" WHERE (((o1."user_id" = $1) AND (o0."id" = $2)) AND (o0."deleted_at" IS NULL))',
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.046072,
            maxTime: 0.072353,
            sumTime: 0.180308,
            meanTime: 0.0601026666666667,
            sdTime: 0.010802775270992,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 12,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4116424620240464400",
          database: "postgres",
          query:
            'UPDATE "projects" SET "visibility" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.173217,
            maxTime: 0.173217,
            sumTime: 0.173217,
            meanTime: 0.173217,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 20,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2874899894245793300",
          database: "postgres",
          query: 'SELECT count(*) FROM "events" AS e0',
          rows: 5,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 5,
            minTime: 0.014974,
            maxTime: 0.050404,
            sumTime: 0.171042,
            meanTime: 0.0342084,
            sdTime: 0.0134438140659561,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 28,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-391633640036545340",
          database: "postgres",
          query:
            "SELECT\n  p.oid :: int8 AS id,\n  p.pubname AS name,\n  p.pubowner::regrole::text AS owner,\n  p.pubinsert AS publish_insert,\n  p.pubupdate AS publish_update,\n  p.pubdelete AS publish_delete,\n  p.pubtruncate AS publish_truncate,\n  CASE\n    WHEN p.puballtables THEN $1\n    ELSE pr.tables\n  END AS tables\nFROM\n  pg_catalog.pg_publication AS p\n  LEFT JOIN LATERAL (\n    SELECT\n      COALESCE(\n        array_agg(\n          json_build_object(\n            $2,\n            c.oid :: int8,\n            $3,\n            c.relname,\n            $4,\n            nc.nspname\n          )\n        ),\n        $5\n      ) AS tables\n    FROM\n      pg_catalog.pg_publication_rel AS pr\n      JOIN pg_class AS c ON pr.prrelid = c.oid\n      join pg_namespace as nc on c.relnamespace = nc.oid\n    WHERE\n      pr.prpubid = p.oid\n  ) AS pr ON $6 = $7",
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.038358,
            maxTime: 0.044635,
            sumTime: 0.170187,
            meanTime: 0.04254675,
            sdTime: 0.00254809030206937,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 4,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5776768827433104000",
          database: "postgres",
          query:
            "SELECT n.oid     AS schema_id\n                 , n.nspname AS schema_name\n                 , c.oid     AS table_id\n                 , c.relname AS table_name\n                 , a.attnum  AS column_id\n                 , a.attname AS column_name\n                 , t.oid     AS type_id\n                 , t.typname AS type_name\n            FROM pg_attribute a\n                     JOIN pg_class c ON c.oid = a.attrelid\n                     JOIN pg_namespace n ON n.oid = c.relnamespace\n                     JOIN pg_type t ON t.oid = a.atttypid\n            WHERE a.attrelid IN ($1)\n              AND a.attnum > $2",
          rows: 16,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.074773,
            maxTime: 0.075807,
            sumTime: 0.15058,
            meanTime: 0.07529,
            sdTime: 0.000517000000000004,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 72,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3962523710421969400",
          database: "postgres",
          query:
            'SELECT "details" AS value FROM "public"."events" WHERE "details" IS NOT NULL LIMIT $1',
          rows: 82,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.059134,
            maxTime: 0.087014,
            sumTime: 0.146148,
            meanTime: 0.073074,
            sdTime: 0.01394,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 18,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3591783593139310600",
          database: "postgres",
          query:
            "select * from pg_catalog.pg_tables where schemaname = $1 and tablename = $2",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.04535,
            maxTime: 0.100192,
            sumTime: 0.145542,
            meanTime: 0.072771,
            sdTime: 0.027421,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 10,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1222253998328519200",
          database: "postgres",
          query: 'SELECT min(e0."created_at") FROM "events" AS e0',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.011734,
            maxTime: 0.052988,
            sumTime: 0.1418,
            meanTime: 0.03545,
            sdTime: 0.0149568223730845,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3327774541684982300",
          database: "postgres",
          query:
            "select datname from pg_database \n      where datallowconn = $1\n      order by oid asc",
          rows: 8,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.033461,
            maxTime: 0.038113,
            sumTime: 0.139142,
            meanTime: 0.0347855,
            sdTime: 0.0019274600514667,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 16,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-343675221267850600",
          database: "postgres",
          query:
            "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE t.oid IN ($4)",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.130821,
            maxTime: 0.130821,
            sumTime: 0.130821,
            meanTime: 0.130821,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 35,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2881332641200853000",
          database: "postgres",
          query: 'SELECT max(e0."created_at") FROM "events" AS e0',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.011126,
            maxTime: 0.043192,
            sumTime: 0.130041,
            meanTime: 0.03251025,
            sdTime: 0.0125472772419956,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 8,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3295430649547258000",
          database: "postgres",
          query:
            'SELECT o0."user_id", o0."organization_id", o0."created_by", o0."updated_by", o0."created_at", o0."updated_at", o0."organization_id" FROM "organization_members" AS o0 WHERE (o0."organization_id" = $1) ORDER BY o0."organization_id"',
          rows: 6,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 6,
            minTime: 0.017682,
            maxTime: 0.024337,
            sumTime: 0.118327,
            meanTime: 0.0197211666666667,
            sdTime: 0.0022329698771417,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 12,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6983464073863707000",
          database: "postgres",
          query:
            'SELECT o0."id", o0."slug", o0."name", o0."logo", o0."description", o0."github_username", o0."twitter_username", o0."stripe_customer_id", o0."stripe_subscription_id", o0."is_personal", o0."data", o0."created_by", o0."updated_by", o0."created_at", o0."updated_at", o0."deleted_by", o0."deleted_at" FROM "organizations" AS o0 INNER JOIN "organization_members" AS o1 ON o1."organization_id" = o0."id" WHERE ((o1."user_id" = $1) AND (o0."deleted_at" IS NULL))',
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.03268,
            maxTime: 0.042363,
            sumTime: 0.11117,
            meanTime: 0.0370566666666667,
            sdTime: 0.00400735426712216,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 12,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "8061785350265891000",
          database: "postgres",
          query: 'SELECT count(*) FROM "projects" AS p0',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.019381,
            maxTime: 0.026962,
            sumTime: 0.096902,
            meanTime: 0.0242255,
            sdTime: 0.00294630993787144,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 3,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2530902949527589000",
          database: "postgres",
          query:
            'SELECT o0."id", o0."slug", o0."name", o0."logo", o0."description", o0."github_username", o0."twitter_username", o0."stripe_customer_id", o0."stripe_subscription_id", o0."is_personal", o0."data", o0."created_by", o0."updated_by", o0."created_at", o0."updated_at", o0."deleted_by", o0."deleted_at", o0."id" FROM "organizations" AS o0 WHERE (o0."id" = $1)',
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.023942,
            maxTime: 0.0432,
            sumTime: 0.095211,
            meanTime: 0.031737,
            sdTime: 0.00827882072922628,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 6,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1741803686497134800",
          database: "postgres",
          query: "SELECT pg_stat_statements_reset()",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.080311,
            maxTime: 0.080311,
            sumTime: 0.080311,
            meanTime: 0.080311,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7070600405199535000",
          database: "postgres",
          query:
            "select count(*) > $1 as pgsodium_enabled from pg_extension where extname = $2",
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.017582,
            maxTime: 0.021186,
            sumTime: 0.079211,
            meanTime: 0.01980275,
            sdTime: 0.00138953038379878,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 8,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2754838250477626000",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "location" = $1, "phone" = $2, "updated_at" = $3 WHERE "id" = $4',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.07867,
            maxTime: 0.07867,
            sumTime: 0.07867,
            meanTime: 0.07867,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6948613435723575000",
          database: "postgres",
          query:
            'SELECT e0."id", e0."name", e0."data", e0."details", e0."created_by", e0."created_at", e0."organization_id", e0."project_id" FROM "events" AS e0 WHERE (e0."organization_id" = $1) AND (NOT (e0."created_by" IS NULL)) AND (NOT (e0."project_id" IS NULL)) AND (e0."name" = ANY($2)) ORDER BY e0."created_at" DESC LIMIT $3',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.03826,
            maxTime: 0.039999,
            sumTime: 0.078259,
            meanTime: 0.0391295,
            sdTime: 0.0008695,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 11,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2276304047148811500",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "updated_at" = $1, "product_updates" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.077054,
            maxTime: 0.077054,
            sumTime: 0.077054,
            meanTime: 0.077054,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2154569432374065700",
          database: "postgres",
          query:
            'SELECT count(*) FROM "users" AS u0 WHERE (u0."is_admin" = $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.01097,
            maxTime: 0.020504,
            sumTime: 0.071834,
            meanTime: 0.0179585,
            sdTime: 0.00403907597725024,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 3,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8386716373093753000",
          database: "postgres",
          query: 'SELECT count(*) FROM "organizations" AS o0',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.00978,
            maxTime: 0.022243,
            sumTime: 0.069997,
            meanTime: 0.01749925,
            sdTime: 0.00472510070659875,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 3,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7351701904420866000",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "usecase" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.069989,
            maxTime: 0.069989,
            sumTime: 0.069989,
            meanTime: 0.069989,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 9,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1438775788948374500",
          database: "postgres",
          query: 'SELECT $2 FROM "users" AS u0 WHERE (u0."slug" = $1) LIMIT $3',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.069628,
            maxTime: 0.069628,
            sumTime: 0.069628,
            meanTime: 0.069628,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 4,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3501800099889614300",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "company" = $1, "industry" = $2, "updated_at" = $3 WHERE "id" = $4',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.068643,
            maxTime: 0.068643,
            sumTime: 0.068643,
            meanTime: 0.068643,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7369188334053391000",
          database: "postgres",
          query:
            'SELECT count(*) FROM "organizations" AS o0 WHERE (o0."is_personal" = $1)',
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.009765,
            maxTime: 0.02034,
            sumTime: 0.068266,
            meanTime: 0.0170665,
            sdTime: 0.00424770823503686,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 3,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "294285920887285900",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "usage" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.060069,
            maxTime: 0.060069,
            sumTime: 0.060069,
            meanTime: 0.060069,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6472234754161866000",
          database: "postgres",
          query:
            'SELECT DISTINCT "key_type" AS value FROM "pgsodium"."decrypted_key" WHERE "key_type" IS NOT NULL ORDER BY value LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.027512,
            maxTime: 0.031852,
            sumTime: 0.059364,
            meanTime: 0.029682,
            sdTime: 0.00217,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 10,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-3236033812741247500",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "role" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.059355,
            maxTime: 0.059355,
            sumTime: 0.059355,
            meanTime: 0.059355,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 7,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7187574263740722000",
          database: "postgres",
          query:
            "SELECT\n  version(),\n  current_setting($1) :: int8 AS version_number,\n  (\n    SELECT\n      COUNT(*) AS active_connections\n    FROM\n      pg_stat_activity\n  ) AS active_connections,\n  current_setting($2) :: int8 AS max_connections",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.057852,
            maxTime: 0.057852,
            sumTime: 0.057852,
            meanTime: 0.057852,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1072999359081487500",
          database: "postgres",
          query: "SELECT pg_stat_reset()",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.056656,
            maxTime: 0.056656,
            sumTime: 0.056656,
            meanTime: 0.056656,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7451469121948099000",
          database: "postgres",
          query:
            'SELECT $2 FROM "users" AS u0 WHERE (u0."email" = $1) LIMIT $3',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.05553,
            maxTime: 0.05553,
            sumTime: 0.05553,
            meanTime: 0.05553,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 4,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8094039508779020000",
          database: "postgres",
          query:
            'SELECT $3 FROM "organization_members" AS o0 WHERE ((o0."organization_id" = $1) AND (o0."user_id" = $2)) LIMIT $4',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.055137,
            maxTime: 0.055137,
            sumTime: 0.055137,
            meanTime: 0.055137,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2566856382119989000",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "previously_tried" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.054457,
            maxTime: 0.054457,
            sumTime: 0.054457,
            meanTime: 0.054457,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5,
            sumDirty: 1,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8060962487460819000",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "plan" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.051692,
            maxTime: 0.051692,
            sumTime: 0.051692,
            meanTime: 0.051692,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4899667904039365000",
          database: "postgres",
          query:
            "SELECT EXISTS (\n  SELECT $2\n  FROM   pg_catalog.pg_class c\n  WHERE  c.relname = $1\n  AND    c.relkind = $3\n)",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.022995,
            maxTime: 0.026297,
            sumTime: 0.049292,
            meanTime: 0.024646,
            sdTime: 0.001651,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 6,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5242230775748924000",
          database: "postgres",
          query:
            'SELECT p0."id", p0."organization_id", p0."slug", p0."name", p0."description", p0."encoding_version", p0."storage_kind", p0."file", p0."local_owner", p0."visibility", p0."nb_sources", p0."nb_tables", p0."nb_columns", p0."nb_relations", p0."nb_types", p0."nb_comments", p0."nb_layouts", p0."nb_notes", p0."nb_memos", p0."created_by", p0."updated_by", p0."created_at", p0."updated_at", p0."archived_by", p0."archived_at" FROM "projects" AS p0 INNER JOIN "organizations" AS o1 ON p0."organization_id" = o1."id" INNER JOIN "organization_members" AS o2 ON o2."organization_id" = o1."id" WHERE (((o2."user_id" = $1) AND (o1."id" = $2)) AND ((p0."storage_kind" = $4) OR ((p0."storage_kind" = $5) AND (p0."local_owner" = $3)))) ORDER BY p0."updated_at" DESC',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.023508,
            maxTime: 0.024803,
            sumTime: 0.048311,
            meanTime: 0.0241555,
            sdTime: 0.0006475,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 8,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-1185254827195043000",
          database: "postgres",
          query:
            'UPDATE "user_profiles" SET "discovered_by" = $1, "updated_at" = $2 WHERE "id" = $3',
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.048065,
            maxTime: 0.048065,
            sumTime: 0.048065,
            meanTime: 0.048065,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 5,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2642224208093247500",
          database: "postgres",
          query: "select count(*) > $1 as keys_created from pgsodium.key",
          rows: 4,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 4,
            minTime: 0.010429,
            maxTime: 0.011306,
            sumTime: 0.043593,
            meanTime: 0.01089825,
            sdTime: 0.000330536968431672,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5809137442720459000",
          database: "postgres",
          query:
            'SELECT o0."id", o0."sent_to", o0."organization_id", o0."expire_at", o0."created_by", o0."created_at", o0."cancel_at", o0."answered_by", o0."refused_at", o0."accepted_at", o0."organization_id" FROM "organization_invitations" AS o0 WHERE (o0."organization_id" = $1) ORDER BY o0."organization_id"',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 5,
            minTime: 0.003849,
            maxTime: 0.01555,
            sumTime: 0.039181,
            meanTime: 0.0078362,
            sdTime: 0.00411023344349199,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 10,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3355042744039632400",
          database: "postgres",
          query: "SELECT id from storage.buckets limit $1",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.009575,
            maxTime: 0.013687,
            sumTime: 0.035906,
            meanTime: 0.0119686666666667,
            sdTime: 0.00174531608089258,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "5405729535900575000",
          database: "postgres",
          query: "SELECT set_config($2, $1, $3)",
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.011725,
            maxTime: 0.012316,
            sumTime: 0.035848,
            meanTime: 0.0119493333333333,
            sdTime: 0.000261424728916162,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3820054158036602400",
          database: "postgres",
          query:
            'SELECT $2 FROM "organizations" AS o0 WHERE (o0."slug" = $1) LIMIT $3',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.009025,
            maxTime: 0.015967,
            sumTime: 0.035051,
            meanTime: 0.0116836666666667,
            sdTime: 0.0030580491966103,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 4,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3729671728595704000",
          database: "postgres",
          query:
            'SELECT "provider_data" AS value FROM "public"."users" WHERE "provider_data" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.016738,
            maxTime: 0.017001,
            sumTime: 0.033739,
            meanTime: 0.0168695,
            sdTime: 0.000131499999999999,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7941353068740752000",
          database: "postgres",
          query:
            'SELECT "options" AS value FROM "public"."heroku_resources" WHERE "options" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.011996,
            maxTime: 0.018863,
            sumTime: 0.030859,
            meanTime: 0.0154295,
            sdTime: 0.0034335,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1147616880456321400",
          database: "postgres",
          query:
            "select $1\n\n-- source: dashboard\n-- user: a374796d-3e4c-416d-8d5c-8976fdecb2f2\n-- date: 2024-06-17T08:15:12.898Z",
          rows: 5,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 5,
            minTime: 0.004788,
            maxTime: 0.007098,
            sumTime: 0.028205,
            meanTime: 0.005641,
            sdTime: 0.000830174439500518,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-5512890310722621000",
          database: "postgres",
          query: "SELECT pg_try_advisory_lock($1)",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.013089,
            maxTime: 0.013547,
            sumTime: 0.026636,
            meanTime: 0.013318,
            sdTime: 0.000229,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "6719088190368382000",
          database: "postgres",
          query:
            'SELECT DISTINCT "key_type" AS value FROM "pgsodium"."valid_key" WHERE "key_type" IS NOT NULL ORDER BY value LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.011134,
            maxTime: 0.012011,
            sumTime: 0.023145,
            meanTime: 0.0115725,
            sdTime: 0.000438500000000001,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 2,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7366987304437551000",
          database: "postgres",
          query:
            'SELECT DISTINCT "key_type" AS value FROM "pgsodium"."key" WHERE "key_type" IS NOT NULL ORDER BY value LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.01115,
            maxTime: 0.01143,
            sumTime: 0.02258,
            meanTime: 0.01129,
            sdTime: 0.00014,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7831034981448561000",
          database: "postgres",
          query:
            'SELECT "attribute_mapping" AS value FROM "auth"."saml_providers" WHERE "attribute_mapping" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.009608,
            maxTime: 0.010716,
            sumTime: 0.020324,
            meanTime: 0.010162,
            sdTime: 0.000553999999999999,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-6640895867831288000",
          database: "postgres",
          query:
            'SELECT "identity_data" AS value FROM "auth"."identities" WHERE "identity_data" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.008681,
            maxTime: 0.010821,
            sumTime: 0.019502,
            meanTime: 0.009751,
            sdTime: 0.00107,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "3033895647379871000",
          database: "postgres",
          query: "SELECT pg_advisory_unlock($1)",
          rows: 2,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.008043,
            maxTime: 0.009633,
            sumTime: 0.017676,
            meanTime: 0.008838,
            sdTime: 0.000794999999999999,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-7352463438272774000",
          database: "postgres",
          query: 'DELETE FROM "organization_invitations" AS o0',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.016253,
            maxTime: 0.016253,
            sumTime: 0.016253,
            meanTime: 0.016253,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "8624744005482669000",
          database: "postgres",
          query:
            'SELECT "raw_app_meta_data" AS value FROM "auth"."users" WHERE "raw_app_meta_data" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.007146,
            maxTime: 0.008746,
            sumTime: 0.015892,
            meanTime: 0.007946,
            sdTime: 0.0008,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-4298216413906704400",
          database: "postgres",
          query:
            'SELECT "metadata" AS value FROM "storage"."objects" WHERE "metadata" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.007221,
            maxTime: 0.008288,
            sumTime: 0.015509,
            meanTime: 0.0077545,
            sdTime: 0.000533499999999999,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "7410042080641026000",
          database: "postgres",
          query: 'DELETE FROM "organization_members" AS o0',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.01541,
            maxTime: 0.01541,
            sumTime: 0.01541,
            meanTime: 0.01541,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1147616880456321400",
          database: "postgres",
          query: "SELECT $1",
          rows: 3,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 3,
            minTime: 0.004883,
            maxTime: 0.005039,
            sumTime: 0.014953,
            meanTime: 0.00498433333333333,
            sdTime: 0.0000717278808336685,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-8374036313123748000",
          database: "postgres",
          query:
            'SELECT "claims" AS value FROM "realtime"."subscription" WHERE "claims" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.006564,
            maxTime: 0.007393,
            sumTime: 0.013957,
            meanTime: 0.0069785,
            sdTime: 0.0004145,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "414125318403854000",
          database: "postgres",
          query:
            'SELECT "raw_user_meta_data" AS value FROM "auth"."users" WHERE "raw_user_meta_data" IS NOT NULL LIMIT $1',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 2,
            minTime: 0.006762,
            maxTime: 0.00699,
            sumTime: 0.013752,
            meanTime: 0.006876,
            sdTime: 0.000114,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-644905293012265300",
          database: "postgres",
          query: "SELECT FROM pg_database WHERE datname = $1",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.011938,
            maxTime: 0.011938,
            sumTime: 0.011938,
            meanTime: 0.011938,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 1,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2824785882122593300",
          database: "postgres",
          query:
            'SELECT $2 FROM "projects" AS p0 WHERE (p0."slug" = $1) LIMIT $3',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.011807,
            maxTime: 0.011807,
            sumTime: 0.011807,
            meanTime: 0.011807,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 1,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-646577521287792100",
          database: "postgres",
          query:
            "INSERT INTO user_profiles (id, user_id, location, description, company, created_at, updated_at) SELECT uuid_generate_v4(), id, location, description, company, now(), now() FROM users",
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.011749,
            maxTime: 0.011749,
            sumTime: 0.011749,
            meanTime: 0.011749,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "4976234397028177000",
          database: "postgres",
          query: 'DELETE FROM "users" AS u0',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.010034,
            maxTime: 0.010034,
            sumTime: 0.010034,
            meanTime: 0.010034,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "2452389861447319000",
          database: "postgres",
          query: 'DELETE FROM "organizations" AS o0',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.009707,
            maxTime: 0.009707,
            sumTime: 0.009707,
            meanTime: 0.009707,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1468235985233569000",
          database: "postgres",
          query: 'DELETE FROM "projects" AS p0',
          rows: 0,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.009575,
            maxTime: 0.009575,
            sumTime: 0.009575,
            meanTime: 0.009575,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "1147616880456321400",
          database: "postgres",
          query: "select $1",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.006155,
            maxTime: 0.006155,
            sumTime: 0.006155,
            meanTime: 0.006155,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
        {
          id: "-2563412158741520000",
          database: "postgres",
          query: "select version()",
          rows: 1,
          plan: {
            count: 0,
            minTime: 0,
            maxTime: 0,
            sumTime: 0,
            meanTime: 0,
            sdTime: 0,
          },
          exec: {
            count: 1,
            minTime: 0.005304,
            maxTime: 0.005304,
            sumTime: 0.005304,
            meanTime: 0.005304,
            sdTime: 0,
          },
          blocks: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksTmp: {
            sumRead: 0,
            sumWrite: 0,
            sumHit: 0,
            sumDirty: 0,
          },
          blocksQuery: {
            sumRead: 0,
            sumWrite: 0,
          },
        },
      ],
    } as AnalyzeReportHtmlResult)
