import { PROD } from "./env.constants"
import { AnalyzeReportHtmlResult } from "@azimutt/models"

export const REPORT: AnalyzeReportHtmlResult = PROD
  ? //@ts-ignore
    __REPORT__
  : {
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
    }
