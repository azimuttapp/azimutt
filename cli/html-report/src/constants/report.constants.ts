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
              totalViolations: 5,
              violations: [
                {
                  message:
                    "Index mfa_factors_user_id_idx on auth.mfa_factors(user_id) can be deleted, it's covered by: factor_id_created_at_idx(user_id, created_at).",
                },
                {
                  message:
                    "Index refresh_tokens_instance_id_idx on auth.refresh_tokens(instance_id) can be deleted, it's covered by: refresh_tokens_instance_id_user_id_idx(instance_id, user_id).",
                },
                {
                  message:
                    "Index sessions_user_id_idx on auth.sessions(user_id) can be deleted, it's covered by: user_id_created_at_idx(user_id, created_at).",
                },
              ],
            },
            {
              name: "entity not clean",
              level: "high",
              totalViolations: 1,
              violations: [
                "Entity public.events has old analyze (2024-06-17T10:18:35.009Z).",
              ],
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
              totalViolations: 2,
              violations: [
                "Entity auth.users has too many attributes (35).",
                "Entity extensions.pg_stat_statements has too many attributes (43).",
              ],
            },

            {
              name: "entity with too heavy indexes",
              level: "medium",
              totalViolations: 15,
              violations: [
                "Entity auth.users has too heavy indexes (10x data size, 11 indexes).",
                "Entity public.gallery has too heavy indexes (6x data size, 3 indexes).",
                "Entity public.organizations has too heavy indexes (6x data size, 3 indexes).",
              ],
            },
            {
              name: "business primary key forbidden",
              level: "medium",
              totalViolations: 3,
              violations: [
                "Entity auth.schema_migrations should have a technical primary key, current one is: (version).",
                "Entity public.schema_migrations should have a technical primary key, current one is: (version).",
                "Entity realtime.schema_migrations should have a technical primary key, current one is: (version).",
              ],
            },
            {
              name: "index on relation",
              level: "medium",
              totalViolations: 26,
              violations: [
                "Create an index on auth.mfa_challenges(factor_id) to improve auth.mfa_challenges(factor_id)->auth.mfa_factors(id) relation.",
                "Create an index on auth.saml_relay_states(flow_state_id) to improve auth.saml_relay_states(flow_state_id)->auth.flow_state(id) relation.",
                "Create an index on pgsodium.key(parent_key) to improve pgsodium.key(parent_key)->pgsodium.key(id) relation.",
              ],
            },
            {
              name: "missing relation",
              level: "medium",
              totalViolations: 42,
              violations: [
                "Create a relation from auth.audit_log_entries(instance_id) to auth.instances(id).",
                "Create a relation from auth.flow_state(user_id) to auth.users(id).",
                "Create a relation from auth.flow_state(user_id) to public.users(id).",
              ],
            },
          ],
        },
        {
          level: "low",
          levelViolationsCount: 0,
          rules: [],
        },
        {
          level: "hint",
          levelViolationsCount: 57,
          rules: [
            {
              name: "inconsistent attribute type",
              level: "hint",
              totalViolations: 17,
              violations: [
                "Attribute id has several types: integer in storage.migrations(id), text in storage.buckets(id) and 1 other, bigint in auth.refresh_tokens(id) and 2 others, uuid in auth.audit_log_entries(id) and 32 others.",
                "Attribute created_at has several types: timestamp without time zone in auth.one_time_tokens(created_at) and 14 others, timestamp with time zone in auth.audit_log_entries(created_at) and 19 others.",
                "Attribute ip_address has several types: character varying(64) in auth.audit_log_entries(ip_address), inet in auth.mfa_challenges(ip_address).",
              ],
            },
            {
              name: "expensive query",
              level: "hint",
              totalViolations: 20,
              violations: [
                "Query 1374137181295181600 is one of the most expensive, cumulated 5085 ms exec time in 46 executions (SELECT name FROM pg_timezone_names)",
                "Query -156763288877666600 on pg_type is one of the most expensive, cumulated 1146 ms exec time in 46 executions ( WITH base_types AS ( WITH RECURSIVE recurse AS ( SELECT oid, typbasetype, COALESCE(NULLIF(typbasetype, $3), oid) AS base FROM pg_type UNION SELECT t.oid, b.typbasetype, COALESCE(NULLIF(b.typbasety...)",
                "Query 8014584162185131000 on pg_attribute is one of the most expensive, cumulated 393 ms exec time in 46 executions (WITH columns AS ( SELECT nc.nspname::name AS table_schema, c.relname::name AS table_name, a.attname::name AS column_name, d.description AS description,  CASE WHEN t.typbasetype != $2 THEN pg_get_ex...)",
              ],
            },
            {
              name: "query with high variation",
              level: "hint",
              totalViolations: 20,
              violations: [
                "Query 1374137181295181600 has high variation, with 194 ms standard deviation and exec time ranging from 59 ms to 999 ms (SELECT name FROM pg_timezone_names)",
                "Query -4726471486296252000 on pg_attribute has high variation, with 28 ms standard deviation and exec time ranging from 5 ms to 78 ms (SELECT t.oid, t.typname, t.typsend, t.typrec... FROM pg_catalog.pg_type s WHERE s.typrelid != $7 AND s.oid = t.typelem)))",
                "Query 7339462770142107000 on pg_namespace has high variation, with 12 ms standard deviation and exec time ranging from 33 ms to 67 ms (with tables as (SELECT c.oid :: int8 AS id, nc.nspname AS schema, c.relname AS name, c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced, CASE WHEN c.relreplident = $1 THEN $2 WHEN...)",
              ],
            },
          ],
        },
      ],
      rules: [
        {
          name: "duplicated index",
          totalViolations: 5,
        },
        {
          name: "too slow query",
          totalViolations: 0,
        },
        {
          name: "degrading query",
          totalViolations: 0,
        },
        {
          name: "entity not clean",
          totalViolations: 1,
        },
        {
          name: "missing primary key",
          totalViolations: 0,
        },
        { name: "unused entity", totalViolations: 0 },
        { name: "unused index", totalViolations: 0 },
        {
          name: "bad attribute type",
          totalViolations: 0,
        },
        {
          name: "fast growing entity",
          totalViolations: 0,
        },
        {
          name: "fast growing index",
          totalViolations: 0,
        },
      ],
    }
