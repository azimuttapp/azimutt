import { PROD } from "./env.constants"
import { AnalyzeReportHtmlResult } from "@azimutt/models"

declare let __REPORT__: AnalyzeReportHtmlResult

export const REPORT: AnalyzeReportHtmlResult = PROD
  ? __REPORT__
  : ({
      rules: [
        {
          name: "inconsistent attribute type",
          level: "hint",
          conf: {},
          totalViolations: 17,
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
        },
        {
          name: "expensive query",
          level: "hint",
          conf: {},
          totalViolations: 20,
          violations: [
            {
              message:
                "Query 1374137181295181600 is one of the most expensive, cumulated 5986 ms exec time in 48 executions (SELECT name FROM pg_timezone_names)",
              extra: {
                queryId: "1374137181295181600",
                query: "SELECT name FROM pg_timezone_names",
                stats: {
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
                  blocks: { sumRead: 0, sumWrite: 0, sumHit: 0, sumDirty: 0 },
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
                "Query -156763288877666600 on pg_type is one of the most expensive, cumulated 1196 ms exec time in 48 executions ( WITH base_types AS ( WITH RECURSIVE recurse AS ( SELECT oid, typbasetype, COALESCE(NULLIF(typbasetype, $3), oid) AS base FROM pg_type UNION SELECT t.oid, b.typbasetype, COALESCE(NULLIF(b.typbasety...)",
              entity: { entity: "pg_type" },
              extra: {
                queryId: "-156763288877666600",
                query:
                  "-- Recursively get the base types of domains\n  WITH\n  base_types AS (\n    WITH RECURSIVE\n    recurse AS (\n      SELECT\n        oid,\n        typbasetype,\n        COALESCE(NULLIF(typbasetype, $3), oid) AS base\n      FROM pg_type\n      UNION\n      SELECT\n        t.oid,\n        b.typbasetype,\n        COALESCE(NULLIF(b.typbasetype, $4), b.oid) AS base\n      FROM recurse t\n      JOIN pg_type b ON t.typbasetype = b.oid\n    )\n    SELECT\n      oid,\n      base\n    FROM recurse\n    WHERE typbasetype = $5\n  ),\n  arguments AS (\n    SELECT\n      oid,\n      array_agg((\n        COALESCE(name, $6), -- name\n        type::regtype::text, -- type\n        CASE type\n          WHEN $7::regtype THEN $8\n          WHEN $9::regtype THEN $10\n          WHEN $11::regtype THEN $12\n          WHEN $13::regtype THEN $14\n          ELSE type::regtype::text\n        END, -- convert types that ignore the lenth and accept any value till maximum size\n        idx <= (pronargs - pronargdefaults), -- is_required\n        COALESCE(mode = $15, $16) -- is_variadic\n      ) ORDER BY idx) AS args,\n      CASE COUNT(*) - COUNT(name) -- number of unnamed arguments\n        WHEN $17 THEN $18\n        WHEN $19 THEN (array_agg(type))[$20] IN ($21::regtype, $22::regtype, $23::regtype, $24::regtype, $25::regtype)\n        ELSE $26\n      END AS callable\n    FROM pg_proc,\n         unnest(proargnames, proargtypes, proargmodes)\n           WITH ORDINALITY AS _ (name, type, mode, idx)\n    WHERE type IS NOT NULL -- only input arguments\n    GROUP BY oid\n  )\n  SELECT\n    pn.nspname AS proc_schema,\n    p.proname AS proc_name,\n    d.description AS proc_description,\n    COALESCE(a.args, $27) AS args,\n    tn.nspname AS schema,\n    COALESCE(comp.relname, t.typname) AS name,\n    p.proretset AS rettype_is_setof,\n    (t.typtype = $28\n     -- if any TABLE, INOUT or OUT arguments present, treat as composite\n     or COALESCE(proargmodes::text[] && $29, $30)\n    ) AS rettype_is_composite,\n    bt.oid <> bt.base as rettype_is_composite_alias,\n    p.provolatile,\n    p.provariadic > $31 as hasvariadic,\n    lower((regexp_split_to_array((regexp_split_to_array(iso_config, $32))[$33], $34))[$35]) AS transaction_isolation_level,\n    coalesce(func_settings.kvs, $36) as kvs\n  FROM pg_proc p\n  LEFT JOIN arguments a ON a.oid = p.oid\n  JOIN pg_namespace pn ON pn.oid = p.pronamespace\n  JOIN base_types bt ON bt.oid = p.prorettype\n  JOIN pg_type t ON t.oid = bt.base\n  JOIN pg_namespace tn ON tn.oid = t.typnamespace\n  LEFT JOIN pg_class comp ON comp.oid = t.typrelid\n  LEFT JOIN pg_description as d ON d.objoid = p.oid\n  LEFT JOIN LATERAL unnest(proconfig) iso_config ON iso_config LIKE $37\n  LEFT JOIN LATERAL (\n    SELECT\n      array_agg(row(\n        substr(setting, $38, strpos(setting, $39) - $40),\n        substr(setting, strpos(setting, $41) + $42)\n      )) as kvs\n    FROM unnest(proconfig) setting\n    WHERE setting ~ ANY($2)\n  ) func_settings ON $43\n  WHERE t.oid <> $44::regtype AND COALESCE(a.callable, $45)\nAND prokind = $46 AND pn.nspname = ANY($1)",
                stats: {
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
                  blocksQuery: { sumRead: 0, sumWrite: 0 },
                },
                entities: [],
              },
            },
            {
              message:
                "Query -8486453569861712000 on pg_attribute is one of the most expensive, cumulated 690 ms exec time in 55 executions (SELECT c.oid AS table_id , n.nspname AS tabl... FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace  JOIN pg_type t ON t.oid = a.atttypid LEFT JO...)",
              entity: { entity: "pg_attribute" },
              extra: {
                queryId: "-8486453569861712000",
                query:
                  "SELECT c.oid                                AS table_id\n             -- , u.rolname                            AS table_owner\n             , n.nspname                            AS table_schema\n             , c.relname                            AS table_name\n             , c.relkind                            AS table_kind\n             , a.attnum                             AS column_index\n             , a.attname                            AS column_name\n             , format_type(a.atttypid, a.atttypmod) AS column_type\n             , t.typname                            AS column_type_name\n             , t.typlen                             AS column_type_len\n             , t.typcategory                        AS column_type_cat\n             , NOT a.attnotnull                     AS column_nullable\n             , pg_get_expr(ad.adbin, ad.adrelid)    AS column_default\n             , a.attgenerated = $1                 AS column_generated\n             , d.description                        AS column_comment\n             , null_frac                            AS nulls\n             , avg_width                            AS avg_len\n             , n_distinct                           AS cardinality\n             , most_common_vals                     AS common_vals\n             , most_common_freqs                    AS common_freqs\n             , histogram_bounds                     AS histogram\n        FROM pg_attribute a\n                 JOIN pg_class c ON c.oid = a.attrelid\n                 JOIN pg_namespace n ON n.oid = c.relnamespace\n                 -- JOIN pg_authid u ON u.oid = c.relowner\n                 JOIN pg_type t ON t.oid = a.atttypid\n                 LEFT JOIN pg_attrdef ad ON ad.adrelid = c.oid AND ad.adnum = a.attnum\n                 LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum\n                 LEFT JOIN pg_stats s ON s.schemaname = n.nspname AND s.tablename = c.relname AND s.attname = a.attname\n        WHERE c.relkind IN ($2, $3, $4)\n          AND a.attnum > $5\n          AND a.atttypid != $6\n          AND n.nspname NOT IN ($7, $8)\n        ORDER BY table_schema, table_name, column_index",
                stats: {
                  rows: 26620,
                  plan: {
                    count: 0,
                    minTime: 0,
                    maxTime: 0,
                    sumTime: 0,
                    meanTime: 0,
                    sdTime: 0,
                  },
                  exec: {
                    count: 55,
                    minTime: 9.37997,
                    maxTime: 74.063108,
                    sumTime: 690.493505,
                    meanTime: 12.5544273636364,
                    sdTime: 9.6510871198741,
                  },
                  blocks: {
                    sumRead: 41,
                    sumWrite: 0,
                    sumHit: 303988,
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
        },
        {
          name: "query with high variation",
          level: "hint",
          conf: {},
          totalViolations: 20,
          violations: [
            {
              message:
                "Query 1374137181295181600 has high variation, with 217 ms standard deviation and exec time ranging from 59 ms to 999 ms (SELECT name FROM pg_timezone_names)",
              extra: {
                queryId: "1374137181295181600",
                query: "SELECT name FROM pg_timezone_names",
                stats: {
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
                  blocks: { sumRead: 0, sumWrite: 0, sumHit: 0, sumDirty: 0 },
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
                "Query 4509076507432270300 on pg_catalog.pg_constraint has high variation, with 27 ms standard deviation and exec time ranging from 12 ms to 142 ms (( with foreign_keys as ( select cl.relnamespace::regnamespace::text as schema_name, cl.relname as table_name, cl.oid as table_oid, ct.conname as fkey_name, ct.conkey as col_attnums from pg_catalog....)",
              entity: { schema: "pg_catalog", entity: "pg_constraint" },
              extra: {
                queryId: "4509076507432270300",
                query:
                  "(\nwith foreign_keys as (\n    select\n        cl.relnamespace::regnamespace::text as schema_name,\n        cl.relname as table_name,\n        cl.oid as table_oid,\n        ct.conname as fkey_name,\n        ct.conkey as col_attnums\n    from\n        pg_catalog.pg_constraint ct\n        join pg_catalog.pg_class cl -- fkey owning table\n            on ct.conrelid = cl.oid\n        left join pg_catalog.pg_depend d\n            on d.objid = cl.oid\n            and d.deptype = $1\n    where\n        ct.contype = $2 -- foreign key constraints\n        and d.objid is null -- exclude tables that are dependencies of extensions\n        and cl.relnamespace::regnamespace::text not in (\n            $3, $4, $5, $6, $7, $8\n        )\n),\nindex_ as (\n    select\n        pi.indrelid as table_oid,\n        indexrelid::regclass as index_,\n        string_to_array(indkey::text, $9)::smallint[] as col_attnums\n    from\n        pg_catalog.pg_index pi\n    where\n        indisvalid\n)\nselect\n    $10 as name,\n    $11 as title,\n    $12 as level,\n    $13 as facing,\n    array[$14] as categories,\n    $15 as description,\n    format(\n        $16,\n        fk.schema_name,\n        fk.table_name,\n        fk.fkey_name\n    ) as detail,\n    $17 as remediation,\n    jsonb_build_object(\n        $18, fk.schema_name,\n        $19, fk.table_name,\n        $20, $21,\n        $22, fk.fkey_name,\n        $23, fk.col_attnums\n    ) as metadata,\n    format($24, fk.schema_name, fk.table_name, fk.fkey_name) as cache_key\nfrom\n    foreign_keys fk\n    left join index_ idx\n        on fk.table_oid = idx.table_oid\n        and fk.col_attnums = idx.col_attnums\n    left join pg_catalog.pg_depend dep\n        on idx.table_oid = dep.objid\n        and dep.deptype = $25\nwhere\n    idx.index_ is null\n    and fk.schema_name not in (\n        $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51\n    )\n    and dep.objid is null -- exclude tables owned by extensions\norder by\n    fk.schema_name,\n    fk.table_name,\n    fk.fkey_name)\nunion all\n(\nselect\n    $52 as name,\n    $53 as title,\n    $54 as level,\n    $55 as facing,\n    array[$56] as categories,\n    $57 as description,\n    format(\n        $58,\n        c.relname\n    ) as detail,\n    $59 as remediation,\n    jsonb_build_object(\n        $60, n.nspname,\n        $61, c.relname,\n        $62, $63,\n        $64, array_remove(array_agg(DISTINCT case when pg_catalog.has_table_privilege($65, c.oid, $66) then $67 when pg_catalog.has_table_privilege($68, c.oid, $69) then $70 end), $71)\n    ) as metadata,\n    format($72, n.nspname, c.relname) as cache_key\nfrom\n    -- Identify the oid for auth.users\n    pg_catalog.pg_class auth_users_pg_class\n    join pg_catalog.pg_namespace auth_users_pg_namespace\n        on auth_users_pg_class.relnamespace = auth_users_pg_namespace.oid\n        and auth_users_pg_class.relname = $73\n        and auth_users_pg_namespace.nspname = $74\n    -- Depends on auth.users\n    join pg_catalog.pg_depend d\n        on d.refobjid = auth_users_pg_class.oid\n    join pg_catalog.pg_rewrite r\n        on r.oid = d.objid\n    join pg_catalog.pg_class c\n        on c.oid = r.ev_class\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    join pg_catalog.pg_class pg_class_auth_users\n        on d.refobjid = pg_class_auth_users.oid\nwhere\n    d.deptype = $75\n    and (\n      pg_catalog.has_table_privilege($76, c.oid, $77)\n      or pg_catalog.has_table_privilege($78, c.oid, $79)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($80, $81), $82)))))\n    -- Exclude self\n    and c.relname <> $83\n    -- There are 3 insecure configurations\n    and\n    (\n        -- Materialized views don't support RLS so this is insecure by default\n        (c.relkind in ($84)) -- m for materialized view\n        or\n        -- Standard View, accessible to anon or authenticated that is security_definer\n        (\n            c.relkind = $85 -- v for view\n            -- Exclude security invoker views\n            and not (\n                lower(coalesce(c.reloptions::text,$86))::text[]\n                && array[\n                    $87,\n                    $88,\n                    $89,\n                    $90\n                ]\n            )\n        )\n        or\n        -- Standard View, security invoker, but no RLS enabled on auth.users\n        (\n            c.relkind in ($91) -- v for view\n            -- is security invoker\n            and (\n                lower(coalesce(c.reloptions::text,$92))::text[]\n                && array[\n                    $93,\n                    $94,\n                    $95,\n                    $96\n                ]\n            )\n            and not pg_class_auth_users.relrowsecurity\n        )\n    )\ngroup by\n    n.nspname,\n    c.relname,\n    c.oid)\nunion all\n(\nwith policies as (\n    select\n        nsp.nspname as schema_name,\n        pb.tablename as table_name,\n        pc.relrowsecurity as is_rls_active,\n        polname as policy_name,\n        polpermissive as is_permissive, -- if not, then restrictive\n        (select array_agg(r::regrole) from unnest(polroles) as x(r)) as roles,\n        case polcmd\n            when $97 then $98\n            when $99 then $100\n            when $101 then $102\n            when $103 then $104\n            when $105 then $106\n        end as command,\n        qual,\n        with_check\n    from\n        pg_catalog.pg_policy pa\n        join pg_catalog.pg_class pc\n            on pa.polrelid = pc.oid\n        join pg_catalog.pg_namespace nsp\n            on pc.relnamespace = nsp.oid\n        join pg_catalog.pg_policies pb\n            on pc.relname = pb.tablename\n            and nsp.nspname = pb.schemaname\n            and pa.polname = pb.policyname\n)\nselect\n    $107 as name,\n    $108 as title,\n    $109 as level,\n    $110 as facing,\n    array[$111] as categories,\n    $112 as description,\n    format(\n        $113,\n        schema_name,\n        table_name,\n        policy_name\n    ) as detail,\n    $114 as remediation,\n    jsonb_build_object(\n        $115, schema_name,\n        $116, table_name,\n        $117, $118\n    ) as metadata,\n    format($119, schema_name, table_name, policy_name) as cache_key\nfrom\n    policies\nwhere\n    is_rls_active\n    and schema_name not in (\n        $120, $121, $122, $123, $124, $125, $126, $127, $128, $129, $130, $131, $132, $133, $134, $135, $136, $137, $138, $139, $140, $141, $142, $143, $144, $145\n    )\n    and (\n        -- Example: auth.uid()\n        (\n            qual like $146\n            and lower(qual) not like $147\n        )\n        or (\n            qual like $148\n            and lower(qual) not like $149\n        )\n        or (\n            qual like $150\n            and lower(qual) not like $151\n        )\n        or (\n            qual like $152\n            and lower(qual) not like $153\n        )\n        or (\n            with_check like $154\n            and lower(with_check) not like $155\n        )\n        or (\n            with_check like $156\n            and lower(with_check) not like $157\n        )\n        or (\n            with_check like $158\n            and lower(with_check) not like $159\n        )\n        or (\n            with_check like $160\n            and lower(with_check) not like $161\n        )\n    ))\nunion all\n(\nselect\n    $162 as name,\n    $163 as title,\n    $164 as level,\n    $165 as facing,\n    array[$166] as categories,\n    $167 as description,\n    format(\n        $168,\n        pgns.nspname,\n        pgc.relname\n    ) as detail,\n    $169 as remediation,\n     jsonb_build_object(\n        $170, pgns.nspname,\n        $171, pgc.relname,\n        $172, $173\n    ) as metadata,\n    format(\n        $174,\n        pgns.nspname,\n        pgc.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class pgc\n    join pg_catalog.pg_namespace pgns\n        on pgns.oid = pgc.relnamespace\n    left join pg_catalog.pg_index pgi\n        on pgi.indrelid = pgc.oid\n    left join pg_catalog.pg_depend dep\n        on pgc.oid = dep.objid\n        and dep.deptype = $175\nwhere\n    pgc.relkind = $176 -- regular tables\n    and pgns.nspname not in (\n        $177, $178, $179, $180, $181, $182, $183, $184, $185, $186, $187, $188, $189, $190, $191, $192, $193, $194, $195, $196, $197, $198, $199, $200, $201, $202\n    )\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    pgc.oid,\n    pgns.nspname,\n    pgc.relname\nhaving\n    max(coalesce(pgi.indisprimary, $203)::int) = $204)\nunion all\n(\nselect\n    $205 as name,\n    $206 as title,\n    $207 as level,\n    $208 as facing,\n    array[$209] as categories,\n    $210 as description,\n    format(\n        $211,\n        psui.indexrelname,\n        psui.schemaname,\n        psui.relname\n    ) as detail,\n    $212 as remediation,\n    jsonb_build_object(\n        $213, psui.schemaname,\n        $214, psui.relname,\n        $215, $216\n    ) as metadata,\n    format(\n        $217,\n        psui.schemaname,\n        psui.relname,\n        psui.indexrelname\n    ) as cache_key\n\nfrom\n    pg_catalog.pg_stat_user_indexes psui\n    join pg_catalog.pg_index pi\n        on psui.indexrelid = pi.indexrelid\n    left join pg_catalog.pg_depend dep\n        on psui.relid = dep.objid\n        and dep.deptype = $218\nwhere\n    psui.idx_scan = $219\n    and not pi.indisunique\n    and not pi.indisprimary\n    and dep.objid is null -- exclude tables owned by extensions\n    and psui.schemaname not in (\n        $220, $221, $222, $223, $224, $225, $226, $227, $228, $229, $230, $231, $232, $233, $234, $235, $236, $237, $238, $239, $240, $241, $242, $243, $244, $245\n    ))\nunion all\n(\nselect\n    $246 as name,\n    $247 as title,\n    $248 as level,\n    $249 as facing,\n    array[$250] as categories,\n    $251 as description,\n    format(\n        $252,\n        n.nspname,\n        c.relname,\n        r.rolname,\n        act.cmd,\n        array_agg(p.polname order by p.polname)\n    ) as detail,\n    $253 as remediation,\n    jsonb_build_object(\n        $254, n.nspname,\n        $255, c.relname,\n        $256, $257\n    ) as metadata,\n    format(\n        $258,\n        n.nspname,\n        c.relname,\n        r.rolname,\n        act.cmd\n    ) as cache_key\nfrom\n    pg_catalog.pg_policy p\n    join pg_catalog.pg_class c\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    join pg_catalog.pg_roles r\n        on p.polroles @> array[r.oid]\n        or p.polroles = array[$259::oid]\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $260,\n    lateral (\n        select x.cmd\n        from unnest((\n            select\n                case p.polcmd\n                    when $261 then array[$262]\n                    when $263 then array[$264]\n                    when $265 then array[$266]\n                    when $267 then array[$268]\n                    when $269 then array[$270, $271, $272, $273]\n                    else array[$274]\n                end as actions\n        )) x(cmd)\n    ) act(cmd)\nwhere\n    c.relkind = $275 -- regular tables\n    and p.polpermissive -- policy is permissive\n    and n.nspname not in (\n        $276, $277, $278, $279, $280, $281, $282, $283, $284, $285, $286, $287, $288, $289, $290, $291, $292, $293, $294, $295, $296, $297, $298, $299, $300, $301\n    )\n    and r.rolname not like $302\n    and r.rolname not like $303\n    and not r.rolbypassrls\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname,\n    r.rolname,\n    act.cmd\nhaving\n    count($304) > $305)\nunion all\n(\nselect\n    $306 as name,\n    $307 as title,\n    $308 as level,\n    $309 as facing,\n    array[$310] as categories,\n    $311 as description,\n    format(\n        $312,\n        n.nspname,\n        c.relname,\n        array_agg(p.polname order by p.polname)\n    ) as detail,\n    $313 as remediation,\n    jsonb_build_object(\n        $314, n.nspname,\n        $315, c.relname,\n        $316, $317\n    ) as metadata,\n    format(\n        $318,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_policy p\n    join pg_catalog.pg_class c\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $319\nwhere\n    c.relkind = $320 -- regular tables\n    and n.nspname not in (\n        $321, $322, $323, $324, $325, $326, $327, $328, $329, $330, $331, $332, $333, $334, $335, $336, $337, $338, $339, $340, $341, $342, $343, $344, $345, $346\n    )\n    -- RLS is disabled\n    and not c.relrowsecurity\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname)\nunion all\n(\nselect\n    $347 as name,\n    $348 as title,\n    $349 as level,\n    $350 as facing,\n    array[$351] as categories,\n    $352 as description,\n    format(\n        $353,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $354 as remediation,\n    jsonb_build_object(\n        $355, n.nspname,\n        $356, c.relname,\n        $357, $358\n    ) as metadata,\n    format(\n        $359,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    left join pg_catalog.pg_policy p\n        on p.polrelid = c.oid\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $360\nwhere\n    c.relkind = $361 -- regular tables\n    and n.nspname not in (\n        $362, $363, $364, $365, $366, $367, $368, $369, $370, $371, $372, $373, $374, $375, $376, $377, $378, $379, $380, $381, $382, $383, $384, $385, $386, $387\n    )\n    -- RLS is enabled\n    and c.relrowsecurity\n    and p.polname is null\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relname)\nunion all\n(\nselect\n    $388 as name,\n    $389 as title,\n    $390 as level,\n    $391 as facing,\n    array[$392] as categories,\n    $393 as description,\n    format(\n        $394,\n        n.nspname,\n        c.relname,\n        array_agg(pi.indexname order by pi.indexname)\n    ) as detail,\n    $395 as remediation,\n    jsonb_build_object(\n        $396, n.nspname,\n        $397, c.relname,\n        $398, case\n            when c.relkind = $399 then $400\n            when c.relkind = $401 then $402\n            else $403\n        end,\n        $404, array_agg(pi.indexname order by pi.indexname)\n    ) as metadata,\n    format(\n        $405,\n        n.nspname,\n        c.relname,\n        array_agg(pi.indexname order by pi.indexname)\n    ) as cache_key\nfrom\n    pg_catalog.pg_indexes pi\n    join pg_catalog.pg_namespace n\n        on n.nspname  = pi.schemaname\n    join pg_catalog.pg_class c\n        on pi.tablename = c.relname\n        and n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $406\nwhere\n    c.relkind in ($407, $408) -- tables and materialized views\n    and n.nspname not in (\n        $409, $410, $411, $412, $413, $414, $415, $416, $417, $418, $419, $420, $421, $422, $423, $424, $425, $426, $427, $428, $429, $430, $431, $432, $433, $434\n    )\n    and dep.objid is null -- exclude tables owned by extensions\ngroup by\n    n.nspname,\n    c.relkind,\n    c.relname,\n    replace(pi.indexdef, pi.indexname, $435)\nhaving\n    count(*) > $436)\nunion all\n(\nselect\n    $437 as name,\n    $438 as title,\n    $439 as level,\n    $440 as facing,\n    array[$441] as categories,\n    $442 as description,\n    format(\n        $443,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $444 as remediation,\n    jsonb_build_object(\n        $445, n.nspname,\n        $446, c.relname,\n        $447, $448\n    ) as metadata,\n    format(\n        $449,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $450\nwhere\n    c.relkind = $451\n    and (\n        pg_catalog.has_table_privilege($452, c.oid, $453)\n        or pg_catalog.has_table_privilege($454, c.oid, $455)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($456, $457), $458)))))\n    and n.nspname not in (\n        $459, $460, $461, $462, $463, $464, $465, $466, $467, $468, $469, $470, $471, $472, $473, $474, $475, $476, $477, $478, $479, $480, $481, $482, $483, $484\n    )\n    and dep.objid is null -- exclude views owned by extensions\n    and not (\n        lower(coalesce(c.reloptions::text,$485))::text[]\n        && array[\n            $486,\n            $487,\n            $488,\n            $489\n        ]\n    ))\nunion all\n(\nselect\n    $490 as name,\n    $491 as title,\n    $492 as level,\n    $493 as facing,\n    array[$494] as categories,\n    $495 as description,\n    format(\n        $496,\n        n.nspname,\n        p.proname\n    ) as detail,\n    $497 as remediation,\n    jsonb_build_object(\n        $498, n.nspname,\n        $499, p.proname,\n        $500, $501\n    ) as metadata,\n    format(\n        $502,\n        n.nspname,\n        p.proname,\n        md5(p.prosrc) -- required when function is polymorphic\n    ) as cache_key\nfrom\n    pg_catalog.pg_proc p\n    join pg_catalog.pg_namespace n\n        on p.pronamespace = n.oid\n    left join pg_catalog.pg_depend dep\n        on p.oid = dep.objid\n        and dep.deptype = $503\nwhere\n    n.nspname not in (\n        $504, $505, $506, $507, $508, $509, $510, $511, $512, $513, $514, $515, $516, $517, $518, $519, $520, $521, $522, $523, $524, $525, $526, $527, $528, $529\n    )\n    and dep.objid is null -- exclude functions owned by extensions\n    -- Search path not set to ''\n    and not coalesce(p.proconfig, $530) && array[$531])\nunion all\n(\nselect\n    $532 as name,\n    $533 as title,\n    $534 as level,\n    $535 as facing,\n    array[$536] as categories,\n    $537 as description,\n    format(\n        $538,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $539 as remediation,\n    jsonb_build_object(\n        $540, n.nspname,\n        $541, c.relname,\n        $542, $543\n    ) as metadata,\n    format(\n        $544,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on c.relnamespace = n.oid\nwhere\n    c.relkind = $545 -- regular tables\n    -- RLS is disabled\n    and not c.relrowsecurity\n    and (\n        pg_catalog.has_table_privilege($546, c.oid, $547)\n        or pg_catalog.has_table_privilege($548, c.oid, $549)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($550, $551), $552)))))\n    and n.nspname not in (\n        $553, $554, $555, $556, $557, $558, $559, $560, $561, $562, $563, $564, $565, $566, $567, $568, $569, $570, $571, $572, $573, $574, $575, $576, $577, $578\n    ))\nunion all\n(\nselect\n    $579 as name,\n    $580 as title,\n    $581 as level,\n    $582 as facing,\n    array[$583] as categories,\n    $584 as description,\n    format(\n        $585,\n        pe.extname\n    ) as detail,\n    $586 as remediation,\n    jsonb_build_object(\n        $587, pe.extnamespace::regnamespace,\n        $588, pe.extname,\n        $589, $590\n    ) as metadata,\n    format(\n        $591,\n        pe.extname\n    ) as cache_key\nfrom\n    pg_catalog.pg_extension pe\nwhere\n    -- plpgsql is installed by default in public and outside user control\n    -- confirmed safe\n    pe.extname not in ($592)\n    -- Scoping this to public is not optimal. Ideally we would use the postgres\n    -- search path. That currently isn't available via SQL. In other lints\n    -- we have used has_schema_privilege('anon', 'extensions', 'USAGE') but that\n    -- is not appropriate here as it would evaluate true for the extensions schema\n    and pe.extnamespace::regnamespace::text = $593)\nunion all\n(\nwith policies as (\n    select\n        nsp.nspname as schema_name,\n        pb.tablename as table_name,\n        polname as policy_name,\n        qual,\n        with_check\n    from\n        pg_catalog.pg_policy pa\n        join pg_catalog.pg_class pc\n            on pa.polrelid = pc.oid\n        join pg_catalog.pg_namespace nsp\n            on pc.relnamespace = nsp.oid\n        join pg_catalog.pg_policies pb\n            on pc.relname = pb.tablename\n            and nsp.nspname = pb.schemaname\n            and pa.polname = pb.policyname\n)\nselect\n    $594 as name,\n    $595 as title,\n    $596 as level,\n    $597 as facing,\n    array[$598] as categories,\n    $599 as description,\n    format(\n        $600,\n        schema_name,\n        table_name,\n        policy_name\n    ) as detail,\n    $601 as remediation,\n    jsonb_build_object(\n        $602, schema_name,\n        $603, table_name,\n        $604, $605\n    ) as metadata,\n    format($606, schema_name, table_name, policy_name) as cache_key\nfrom\n    policies\nwhere\n    schema_name not in (\n        $607, $608, $609, $610, $611, $612, $613, $614, $615, $616, $617, $618, $619, $620, $621, $622, $623, $624, $625, $626, $627, $628, $629, $630, $631, $632\n    )\n    and (\n        -- Example: auth.jwt() -> 'user_metadata'\n        -- False positives are possible, but it isn't practical to string match\n        -- If false positive rate is too high, this expression can iterate\n        qual like $633\n        or qual like $634\n        or with_check like $635\n        or with_check like $636\n    ))\nunion all\n(\nselect\n    $637 as name,\n    $638 as title,\n    $639 as level,\n    $640 as facing,\n    array[$641] as categories,\n    $642 as description,\n    format(\n        $643,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $644 as remediation,\n    jsonb_build_object(\n        $645, n.nspname,\n        $646, c.relname,\n        $647, $648\n    ) as metadata,\n    format(\n        $649,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $650\nwhere\n    c.relkind = $651\n    and (\n        pg_catalog.has_table_privilege($652, c.oid, $653)\n        or pg_catalog.has_table_privilege($654, c.oid, $655)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($656, $657), $658)))))\n    and n.nspname not in (\n        $659, $660, $661, $662, $663, $664, $665, $666, $667, $668, $669, $670, $671, $672, $673, $674, $675, $676, $677, $678, $679, $680, $681, $682, $683, $684\n    )\n    and dep.objid is null)\nunion all\n(\nselect\n    $685 as name,\n    $686 as title,\n    $687 as level,\n    $688 as facing,\n    array[$689] as categories,\n    $690 as description,\n    format(\n        $691,\n        n.nspname,\n        c.relname\n    ) as detail,\n    $692 as remediation,\n    jsonb_build_object(\n        $693, n.nspname,\n        $694, c.relname,\n        $695, $696\n    ) as metadata,\n    format(\n        $697,\n        n.nspname,\n        c.relname\n    ) as cache_key\nfrom\n    pg_catalog.pg_class c\n    join pg_catalog.pg_namespace n\n        on n.oid = c.relnamespace\n    left join pg_catalog.pg_depend dep\n        on c.oid = dep.objid\n        and dep.deptype = $698\nwhere\n    c.relkind = $699\n    and (\n        pg_catalog.has_table_privilege($700, c.oid, $701)\n        or pg_catalog.has_table_privilege($702, c.oid, $703)\n    )\n    and n.nspname = any(array(select trim(unnest(string_to_array(current_setting($704, $705), $706)))))\n    and n.nspname not in (\n        $707, $708, $709, $710, $711, $712, $713, $714, $715, $716, $717, $718, $719, $720, $721, $722, $723, $724, $725, $726, $727, $728, $729, $730, $731, $732\n    )\n    and dep.objid is null)",
                stats: {
                  rows: 843,
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
                    minTime: 12.349852,
                    maxTime: 141.544165,
                    sumTime: 477.24553,
                    meanTime: 22.7259776190476,
                    sdTime: 26.9726899551051,
                  },
                  blocks: {
                    sumRead: 17,
                    sumWrite: 0,
                    sumHit: 110129,
                    sumDirty: 1,
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
                "Query -4726471486296252000 on pg_attribute has high variation, with 21 ms standard deviation and exec time ranging from 5 ms to 78 ms (SELECT t.oid, t.typname, t.typsend, t.typrec... FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem)))",
              entity: { entity: "pg_attribute" },
              extra: {
                queryId: "-4726471486296252000",
                query:
                  "SELECT t.oid, t.typname, t.typsend, t.typreceive, t.typoutput, t.typinput,\n       coalesce(d.typelem, t.typelem), coalesce(r.rngsubtype, $1), ARRAY (\n  SELECT a.atttypid\n  FROM pg_attribute AS a\n  WHERE a.attrelid = t.typrelid AND a.attnum > $2 AND NOT a.attisdropped\n  ORDER BY a.attnum\n)\nFROM pg_type AS t\nLEFT JOIN pg_type AS d ON t.typbasetype = d.oid\nLEFT JOIN pg_range AS r ON r.rngtypid = t.oid OR r.rngmultitypid = t.oid OR (t.typbasetype <> $3 AND r.rngtypid = t.typbasetype)\nWHERE (t.typrelid = $4)\nAND (t.typelem = $5 OR NOT EXISTS (SELECT $6 FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem))",
                stats: {
                  rows: 2568,
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
                    minTime: 4.743659,
                    maxTime: 77.626603,
                    sumTime: 209.676455,
                    meanTime: 17.4730379166667,
                    sdTime: 21.1893507662803,
                  },
                  blocks: {
                    sumRead: 27,
                    sumWrite: 0,
                    sumHit: 31705,
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
          ],
        },
        {
          name: "entity too large",
          level: "medium",
          conf: { max: 30 },
          totalViolations: 2,
          violations: [
            {
              message: "Entity auth.users has too many attributes (35).",
              entity: { schema: "auth", entity: "users" },
              extra: { attributes: 35 },
            },
            {
              message:
                "Entity extensions.pg_stat_statements has too many attributes (43).",
              entity: { schema: "extensions", entity: "pg_stat_statements" },
              extra: { attributes: 43 },
            },
          ],
        },
        {
          name: "entity with too heavy indexes",
          level: "medium",
          conf: { ratio: 1 },
          totalViolations: 15,
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
        },
        {
          name: "business primary key forbidden",
          level: "medium",
          conf: {},
          totalViolations: 3,
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
        },
        {
          name: "index on relation",
          level: "medium",
          conf: {},
          totalViolations: 26,
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
        },
        {
          name: "missing relation",
          level: "medium",
          conf: {},
          totalViolations: 42,
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
        },
        {
          name: "duplicated index",
          level: "high",
          conf: {},
          totalViolations: 5,
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
          totalViolations: 1,
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
        },
      ],
      stats: {
        nb_entities: 47,
        nb_relations: 44,
        nb_queries: 169,
        nb_types: 20,
        nb_rules: 27,
      },
    } as AnalyzeReportHtmlResult)
