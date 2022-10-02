module DataSources.SqlMiner.Parsers.CreateViewTest exposing (..)

import DataSources.SqlMiner.Parsers.CreateView exposing (parseView)
import DataSources.SqlMiner.Parsers.Select exposing (SelectColumn(..), SelectTable(..))
import DataSources.SqlMiner.TestHelpers.Tests exposing (testStatement)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateView"
        [ describe "parseView"
            [ testStatement ( parseView, "basic" )
                """CREATE OR REPLACE VIEW public.autocomplete AS
                    SELECT accounts.id AS account_id,
                           accounts.email
                    FROM public.accounts
                    WHERE accounts.deleted_at IS NULL
                    WITH NO DATA;"""
                { schema = Just "public"
                , table = "autocomplete"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "accounts", column = "id", alias = Just "account_id" }
                        , BasicColumn { table = Just "accounts", column = "email", alias = Nothing }
                        ]
                    , tables = [ BasicTable { schema = Just "public", table = "accounts", alias = Nothing } ]
                    , whereClause = Just "accounts.deleted_at IS NULL"
                    }
                , replace = True
                , materialized = False
                , extra = Just "WITH NO DATA"
                }
            , testStatement ( parseView, "with data" )
                """CREATE MATERIALIZED VIEW public.autocomplete AS
                    WITH more_data AS (SELECT * FROM ref)
                    SELECT accounts.id AS account_id,
                           accounts.email
                    FROM public.accounts
                    WHERE accounts.deleted_at IS NULL
                    WITH NO DATA;"""
                { schema = Just "public"
                , table = "autocomplete"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "accounts", column = "id", alias = Just "account_id" }
                        , BasicColumn { table = Just "accounts", column = "email", alias = Nothing }
                        ]
                    , tables = [ BasicTable { schema = Just "public", table = "accounts", alias = Nothing } ]
                    , whereClause = Just "accounts.deleted_at IS NULL"
                    }
                , replace = False
                , materialized = True
                , extra = Just "WITH NO DATA"
                }
            , testStatement ( parseView, "with props" )
                """CREATE VIEW public.autocomplete WITH (security_barrier='true') AS
                    SELECT n.nspname AS schemaname FROM pg_namespace n;"""
                { schema = Just "public"
                , table = "autocomplete"
                , select =
                    { columns = [ BasicColumn { table = Just "n", column = "nspname", alias = Just "schemaname" } ]
                    , tables = [ BasicTable { schema = Nothing, table = "pg_namespace", alias = Just "n" } ]
                    , whereClause = Nothing
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            , testStatement ( parseView, "no table" )
                """CREATE VIEW information_schema.information_schema_catalog_name AS
                    SELECT (current_database())::information_schema.sql_identifier AS catalog_name;"""
                { schema = Just "information_schema"
                , table = "information_schema_catalog_name"
                , select =
                    { columns = [ BasicColumn { table = Just "(current_database())::information_schema", column = "sql_identifier", alias = Just "catalog_name" } ]
                    , tables = []
                    , whereClause = Nothing
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            , testStatement ( parseView, "with array" )
                """CREATE VIEW pg_catalog.pg_group AS
                    SELECT pg_authid.rolname AS groname,
                       pg_authid.oid AS grosysid,
                       ARRAY( SELECT pg_auth_members.member
                              FROM pg_auth_members
                             WHERE (pg_auth_members.roleid = pg_authid.oid)) AS grolist
                      FROM pg_authid
                     WHERE (NOT pg_authid.rolcanlogin);"""
                { schema = Just "pg_catalog"
                , table = "pg_group"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "pg_authid", column = "rolname", alias = Just "groname" }
                        , BasicColumn { table = Just "pg_authid", column = "oid", alias = Just "grosysid" }
                        , ComplexColumn { formula = "ARRAY( SELECT pg_auth_members.member FROM pg_auth_members WHERE (pg_auth_members.roleid = pg_authid.oid))", alias = "grolist" }
                        ]
                    , tables = [ BasicTable { schema = Nothing, table = "pg_authid", alias = Nothing } ]
                    , whereClause = Just "(NOT pg_authid.rolcanlogin)"
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            , testStatement ( parseView, "complex" )
                """CREATE VIEW information_schema.table_constraints AS
                    SELECT (current_database())::information_schema.sql_identifier AS constraint_catalog,
                       (nc.nspname)::information_schema.sql_identifier AS constraint_schema,
                       (c.conname)::information_schema.sql_identifier AS constraint_name,
                       (current_database())::information_schema.sql_identifier AS table_catalog,
                       (nr.nspname)::information_schema.sql_identifier AS table_schema,
                       (r.relname)::information_schema.sql_identifier AS table_name,
                       (
                           CASE c.contype
                               WHEN 'c'::"char" THEN 'CHECK'::text
                               WHEN 'f'::"char" THEN 'FOREIGN KEY'::text
                               WHEN 'p'::"char" THEN 'PRIMARY KEY'::text
                               WHEN 'u'::"char" THEN 'UNIQUE'::text
                               ELSE NULL::text
                           END)::information_schema.character_data AS constraint_type,
                       (
                           CASE
                               WHEN c.condeferrable THEN 'YES'::text
                               ELSE 'NO'::text
                           END)::information_schema.yes_or_no AS is_deferrable,
                       (
                           CASE
                               WHEN c.condeferred THEN 'YES'::text
                               ELSE 'NO'::text
                           END)::information_schema.yes_or_no AS initially_deferred,
                       ('YES'::character varying)::information_schema.yes_or_no AS enforced
                      FROM pg_namespace nc,
                       pg_namespace nr,
                       pg_constraint c,
                       pg_class r
                     WHERE ((nc.oid = c.connamespace) AND (nr.oid = r.relnamespace) AND (c.conrelid = r.oid) AND (c.contype <> ALL (ARRAY['t'::"char", 'x'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(nr.oid)) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text)))
                   UNION ALL
                    SELECT (current_database())::information_schema.sql_identifier AS constraint_catalog,
                       (nr.nspname)::information_schema.sql_identifier AS constraint_schema,
                       (((((((nr.oid)::text || '_'::text) || (r.oid)::text) || '_'::text) || (a.attnum)::text) || '_not_null'::text))::information_schema.sql_identifier AS constraint_name,
                       (current_database())::information_schema.sql_identifier AS table_catalog,
                       (nr.nspname)::information_schema.sql_identifier AS table_schema,
                       (r.relname)::information_schema.sql_identifier AS table_name,
                       ('CHECK'::character varying)::information_schema.character_data AS constraint_type,
                       ('NO'::character varying)::information_schema.yes_or_no AS is_deferrable,
                       ('NO'::character varying)::information_schema.yes_or_no AS initially_deferred,
                       ('YES'::character varying)::information_schema.yes_or_no AS enforced
                      FROM pg_namespace nr,
                       pg_class r,
                       pg_attribute a
                     WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND a.attnotnull AND (a.attnum > 0) AND (NOT a.attisdropped) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(nr.oid)) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text)));"""
                { schema = Just "information_schema"
                , table = "table_constraints"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "(current_database())::information_schema", column = "sql_identifier", alias = Just "constraint_catalog" }
                        , ComplexColumn { formula = "(nc.nspname)::information_schema.sql_identifier", alias = "constraint_schema" }
                        , ComplexColumn { formula = "(c.conname)::information_schema.sql_identifier", alias = "constraint_name" }
                        , BasicColumn { table = Just "(current_database())::information_schema", column = "sql_identifier", alias = Just "table_catalog" }
                        , ComplexColumn { formula = "(nr.nspname)::information_schema.sql_identifier", alias = "table_schema" }
                        , ComplexColumn { formula = "(r.relname)::information_schema.sql_identifier", alias = "table_name" }
                        , ComplexColumn { formula = "( CASE c.contype WHEN 'c'::\"char\" THEN 'CHECK'::text WHEN 'f'::\"char\" THEN 'FOREIGN KEY'::text WHEN 'p'::\"char\" THEN 'PRIMARY KEY'::text WHEN 'u'::\"char\" THEN 'UNIQUE'::text ELSE NULL::text END)::information_schema.character_data", alias = "constraint_type" }
                        , ComplexColumn { formula = "( CASE WHEN c.condeferrable THEN 'YES'::text ELSE 'NO'::text END)::information_schema.yes_or_no", alias = "is_deferrable" }
                        , ComplexColumn { formula = "( CASE WHEN c.condeferred THEN 'YES'::text ELSE 'NO'::text END)::information_schema.yes_or_no", alias = "initially_deferred" }
                        , ComplexColumn { formula = "('YES'::character varying)::information_schema.yes_or_no", alias = "enforced" }
                        ]
                    , tables = [ ComplexTable { definition = "pg_namespace nc, pg_namespace nr, pg_constraint c, pg_class r" } ]
                    , whereClause = Just "((nc.oid = c.connamespace) AND (nr.oid = r.relnamespace) AND (c.conrelid = r.oid) AND (c.contype <> ALL (ARRAY['t'::\"char\", 'x'::\"char\"])) AND (r.relkind = ANY (ARRAY['r'::\"char\", 'p'::\"char\"])) AND (NOT pg_is_other_temp_schema(nr.oid)) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text))) UNION ALL SELECT (current_database())::information_schema.sql_identifier AS constraint_catalog, (nr.nspname)::information_schema.sql_identifier AS constraint_schema, (((((((nr.oid)::text || '_'::text) || (r.oid)::text) || '_'::text) || (a.attnum)::text) || '_not_null'::text))::information_schema.sql_identifier AS constraint_name, (current_database())::information_schema.sql_identifier AS table_catalog, (nr.nspname)::information_schema.sql_identifier AS table_schema, (r.relname)::information_schema.sql_identifier AS table_name, ('CHECK'::character varying)::information_schema.character_data AS constraint_type, ('NO'::character varying)::information_schema.yes_or_no AS is_deferrable, ('NO'::character varying)::information_schema.yes_or_no AS initially_deferred, ('YES'::character varying)::information_schema.yes_or_no AS enforced FROM pg_namespace nr, pg_class r, pg_attribute a WHERE ((nr.oid = r.relnamespace) AND (r.oid = a.attrelid) AND a.attnotnull AND (a.attnum > 0) AND (NOT a.attisdropped) AND (r.relkind = ANY (ARRAY['r'::\"char\", 'p'::\"char\"])) AND (NOT pg_is_other_temp_schema(nr.oid)) AND (pg_has_role(r.relowner, 'USAGE'::text) OR has_table_privilege(r.oid, 'INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER'::text) OR has_any_column_privilege(r.oid, 'INSERT, UPDATE, REFERENCES'::text)))"
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            , testStatement ( parseView, "complex2" )
                """CREATE VIEW information_schema.key_column_usage AS
                    SELECT (current_database())::information_schema.sql_identifier AS constraint_catalog,
                       (ss.nc_nspname)::information_schema.sql_identifier AS constraint_schema,
                       (ss.conname)::information_schema.sql_identifier AS constraint_name,
                       (current_database())::information_schema.sql_identifier AS table_catalog,
                       (ss.nr_nspname)::information_schema.sql_identifier AS table_schema,
                       (ss.relname)::information_schema.sql_identifier AS table_name,
                       (a.attname)::information_schema.sql_identifier AS column_name,
                       ((ss.x).n)::information_schema.cardinal_number AS ordinal_position,
                       (
                           CASE
                               WHEN (ss.contype = 'f'::"char") THEN information_schema._pg_index_position(ss.conindid, ss.confkey[(ss.x).n])
                               ELSE NULL::integer
                           END)::information_schema.cardinal_number AS position_in_unique_constraint
                      FROM pg_attribute a,
                       ( SELECT r.oid AS roid,
                               r.relname,
                               r.relowner,
                               nc.nspname AS nc_nspname,
                               nr.nspname AS nr_nspname,
                               c.oid AS coid,
                               c.conname,
                               c.contype,
                               c.conindid,
                               c.confkey,
                               c.confrelid,
                               information_schema._pg_expandarray(c.conkey) AS x
                              FROM pg_namespace nr,
                               pg_class r,
                               pg_namespace nc,
                               pg_constraint c
                             WHERE ((nr.oid = r.relnamespace) AND (r.oid = c.conrelid) AND (nc.oid = c.connamespace) AND (c.contype = ANY (ARRAY['p'::"char", 'u'::"char", 'f'::"char"])) AND (r.relkind = ANY (ARRAY['r'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(nr.oid)))) ss
                     WHERE ((ss.roid = a.attrelid) AND (a.attnum = (ss.x).x) AND (NOT a.attisdropped) AND (pg_has_role(ss.relowner, 'USAGE'::text) OR has_column_privilege(ss.roid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)));"""
                { schema = Just "information_schema"
                , table = "key_column_usage"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "(current_database())::information_schema", column = "sql_identifier", alias = Just "constraint_catalog" }
                        , ComplexColumn { formula = "(ss.nc_nspname)::information_schema.sql_identifier", alias = "constraint_schema" }
                        , ComplexColumn { formula = "(ss.conname)::information_schema.sql_identifier", alias = "constraint_name" }
                        , BasicColumn { table = Just "(current_database())::information_schema", column = "sql_identifier", alias = Just "table_catalog" }
                        , ComplexColumn { formula = "(ss.nr_nspname)::information_schema.sql_identifier", alias = "table_schema" }
                        , ComplexColumn { formula = "(ss.relname)::information_schema.sql_identifier", alias = "table_name" }
                        , ComplexColumn { formula = "(a.attname)::information_schema.sql_identifier", alias = "column_name" }
                        , ComplexColumn { formula = "((ss.x).n)::information_schema.cardinal_number", alias = "ordinal_position" }
                        , ComplexColumn { formula = "( CASE WHEN (ss.contype = 'f'::\"char\") THEN information_schema._pg_index_position(ss.conindid, ss.confkey[(ss.x).n]) ELSE NULL::integer END)::information_schema.cardinal_number", alias = "position_in_unique_constraint" }
                        ]
                    , tables = [ ComplexTable { definition = "pg_attribute a, ( SELECT r.oid AS roid, r.relname, r.relowner, nc.nspname AS nc_nspname, nr.nspname AS nr_nspname, c.oid AS coid, c.conname, c.contype, c.conindid, c.confkey, c.confrelid, information_schema._pg_expandarray(c.conkey) AS x FROM pg_namespace nr, pg_class r, pg_namespace nc, pg_constraint c" } ]
                    , whereClause = Just "((nr.oid = r.relnamespace) AND (r.oid = c.conrelid) AND (nc.oid = c.connamespace) AND (c.contype = ANY (ARRAY['p'::\"char\", 'u'::\"char\", 'f'::\"char\"])) AND (r.relkind = ANY (ARRAY['r'::\"char\", 'p'::\"char\"])) AND (NOT pg_is_other_temp_schema(nr.oid)))) ss WHERE ((ss.roid = a.attrelid) AND (a.attnum = (ss.x).x) AND (NOT a.attisdropped) AND (pg_has_role(ss.relowner, 'USAGE'::text) OR has_column_privilege(ss.roid, a.attnum, 'SELECT, INSERT, UPDATE, REFERENCES'::text)))"
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            , testStatement ( parseView, "complex3" )
                """CREATE VIEW pg_catalog.pg_stat_progress_copy AS
                    SELECT s.pid,
                       s.datid,
                       d.datname,
                       s.relid,
                           CASE s.param5
                               WHEN 1 THEN 'COPY FROM'::text
                               WHEN 2 THEN 'COPY TO'::text
                               ELSE NULL::text
                           END AS command,
                           CASE s.param6
                               WHEN 1 THEN 'FILE'::text
                               WHEN 2 THEN 'PROGRAM'::text
                               WHEN 3 THEN 'PIPE'::text
                               WHEN 4 THEN 'CALLBACK'::text
                               ELSE NULL::text
                           END AS type,
                       s.param1 AS bytes_processed,
                       s.param2 AS bytes_total,
                       s.param3 AS tuples_processed,
                       s.param4 AS tuples_excluded
                      FROM (pg_stat_get_progress_info('COPY'::text) s(pid, datid, relid, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20)
                        LEFT JOIN pg_database d ON ((s.datid = d.oid)));"""
                { schema = Just "pg_catalog"
                , table = "pg_stat_progress_copy"
                , select =
                    { columns =
                        [ BasicColumn { table = Just "s", column = "pid", alias = Nothing }
                        , BasicColumn { table = Just "s", column = "datid", alias = Nothing }
                        , BasicColumn { table = Just "d", column = "datname", alias = Nothing }
                        , BasicColumn { table = Just "s", column = "relid", alias = Nothing }
                        , ComplexColumn { formula = "CASE s.param5 WHEN 1 THEN 'COPY FROM'::text WHEN 2 THEN 'COPY TO'::text ELSE NULL::text END", alias = "command" }
                        , ComplexColumn { formula = "CASE s.param6 WHEN 1 THEN 'FILE'::text WHEN 2 THEN 'PROGRAM'::text WHEN 3 THEN 'PIPE'::text WHEN 4 THEN 'CALLBACK'::text ELSE NULL::text END", alias = "type" }
                        , BasicColumn { table = Just "s", column = "param1", alias = Just "bytes_processed" }
                        , BasicColumn { table = Just "s", column = "param2", alias = Just "bytes_total" }
                        , BasicColumn { table = Just "s", column = "param3", alias = Just "tuples_processed" }
                        , BasicColumn { table = Just "s", column = "param4", alias = Just "tuples_excluded" }
                        ]
                    , tables = [ ComplexTable { definition = "(pg_stat_get_progress_info('COPY'::text) s(pid, datid, relid, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20) LEFT JOIN pg_database d ON ((s.datid = d.oid)))" } ]
                    , whereClause = Nothing
                    }
                , replace = False
                , materialized = False
                , extra = Nothing
                }
            ]
        ]
