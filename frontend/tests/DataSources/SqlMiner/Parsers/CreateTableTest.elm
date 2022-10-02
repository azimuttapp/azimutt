module DataSources.SqlMiner.Parsers.CreateTableTest exposing (..)

import DataSources.SqlMiner.Parsers.CreateTable exposing (parseCreateTable, parseCreateTableColumn, parseCreateTableColumnForeignKey, parseCreateTableForeignKey, parseCreateTableKey)
import DataSources.SqlMiner.TestHelpers.Tests exposing (parsedColumn, parsedTable, testSql, testStatement)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateTable"
        [ describe "parseCreateTable"
            [ testStatement ( parseCreateTable, "basic" )
                "CREATE TABLE aaa.bbb (ccc int);"
                { parsedTable | schema = Just "aaa", table = "bbb", columns = Nel { parsedColumn | name = "ccc", kind = "int" } [] }
            , testStatement ( parseCreateTable, "if not exists" )
                "CREATE TABLE IF NOT EXISTS aaa.bbb (ccc int);"
                { parsedTable | schema = Just "aaa", table = "bbb", columns = Nel { parsedColumn | name = "ccc", kind = "int" } [] }
            , testStatement ( parseCreateTable, "unlogged" )
                "CREATE UNLOGGED TABLE log (name text);"
                { parsedTable | schema = Nothing, table = "log", columns = Nel { parsedColumn | name = "name", kind = "text" } [] }
            , testStatement ( parseCreateTable, "complex" )
                "CREATE TABLE public.users (id bigint NOT NULL, name character varying(255), price numeric(8,2)) WITH (autovacuum_enabled='false');"
                { parsedTable
                    | schema = Just "public"
                    , table = "users"
                    , columns =
                        Nel { parsedColumn | name = "id", kind = "bigint", nullable = False }
                            [ { parsedColumn | name = "name", kind = "character varying(255)" }
                            , { parsedColumn | name = "price", kind = "numeric(8,2)" }
                            ]
                }
            , testStatement ( parseCreateTable, "with options" )
                "CREATE TABLE p.table (id bigint NOT NULL)    WITH (autovacuum_analyze_threshold='100000');"
                { parsedTable | schema = Just "p", table = "table", columns = Nel { parsedColumn | name = "id", kind = "bigint", nullable = False } [] }
            , testStatement ( parseCreateTable, "without schema, lowercase and no space before body" )
                "create table migrations(version varchar not null);"
                { parsedTable | table = "migrations", columns = Nel { parsedColumn | name = "version", kind = "varchar", nullable = False } [] }
            , testStatement ( parseCreateTable, "with db" )
                "CREATE TABLE db.schema.table (column int);"
                { parsedTable | schema = Just "schema", table = "table", columns = Nel { parsedColumn | name = "column", kind = "int" } [] }
            , testStatement ( parseCreateTable, "with references" )
                "create table students (id serial primary key, name varchar(50) not null, year integer not null, house_id integer references houses(id));"
                { parsedTable
                    | table = "students"
                    , columns =
                        Nel { parsedColumn | name = "id", kind = "serial", primaryKey = Just "" }
                            [ { parsedColumn | name = "name", kind = "varchar(50)", nullable = False }
                            , { parsedColumn | name = "year", kind = "integer", nullable = False }
                            , { parsedColumn | name = "house_id", kind = "integer", foreignKey = Just ( Nothing, { schema = Nothing, table = "houses", column = Just "id" } ) }
                            ]
                }
            , testStatement ( parseCreateTable, "with multiple constraints" )
                "CREATE TABLE t1 (id int constraint t1_pk primary key constraint t1_t2_fk references t2);"
                { parsedTable | schema = Nothing, table = "t1", columns = Nel { parsedColumn | name = "id", kind = "int", primaryKey = Just "t1_pk", foreignKey = Just ( Just "t1_t2_fk", { schema = Nothing, table = "t2", column = Nothing } ) } [] }
            ]
        , describe "parseCreateTableColumn"
            [ testSql ( parseCreateTableColumn, "basic" )
                "id bigint NOT NULL"
                { parsedColumn | name = "id", kind = "bigint", nullable = False }
            , testSql ( parseCreateTableColumn, "nullable" )
                "id bigint"
                { parsedColumn | name = "id", kind = "bigint" }
            , testSql ( parseCreateTableColumn, "with default" )
                "status character varying(255) DEFAULT 'done'::character varying"
                { parsedColumn | name = "status", kind = "character varying(255)", default = Just "'done'::character varying" }
            , testSql ( parseCreateTableColumn, "with comma in type" )
                "price numeric(8,2)"
                { parsedColumn | name = "price", kind = "numeric(8,2)" }
            , testSql ( parseCreateTableColumn, "with enclosing quotes" )
                "\"id\" bigint"
                { parsedColumn | name = "id", kind = "bigint" }
            , testSql ( parseCreateTableColumn, "with enclosing quotes on type" )
                "id \"bigint\""
                { parsedColumn | name = "id", kind = "bigint" }
            , testSql ( parseCreateTableColumn, "with primary key" )
                "id bigint PRIMARY KEY"
                { parsedColumn | name = "id", kind = "bigint", primaryKey = Just "" }
            , testSql ( parseCreateTableColumn, "with primary key before nullable" )
                "id bigint PRIMARY KEY NOT NULL"
                { parsedColumn | name = "id", kind = "bigint", primaryKey = Just "", nullable = False }
            , testSql ( parseCreateTableColumn, "with primary key constraint" )
                "id bigint NOT NULL CONSTRAINT users_pk PRIMARY KEY"
                { parsedColumn | name = "id", kind = "bigint", nullable = False, primaryKey = Just "users_pk" }
            , testSql ( parseCreateTableColumn, "with foreign key having schema, table & column" )
                "user_id bigint CONSTRAINT users_fk REFERENCES public.users.id"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Just "public", table = "users", column = Just "id" } ) }
            , testSql ( parseCreateTableColumn, "with foreign key having table & column" )
                "user_id bigint CONSTRAINT users_fk REFERENCES users.id"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Nothing, table = "users", column = Just "id" } ) }
            , testSql ( parseCreateTableColumn, "with foreign key having table & column in parenthesis" )
                "user_id bigint references users(id)"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Nothing, { schema = Nothing, table = "users", column = Just "id" } ) }
            , testSql ( parseCreateTableColumn, "with foreign key having only table" )
                "user_id bigint CONSTRAINT users_fk REFERENCES users"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Nothing, table = "users", column = Nothing } ) }
            , testSql ( parseCreateTableColumn, "with foreign key and primary key" )
                "match_id bigint REFERENCES matches(match_id) ON DELETE CASCADE PRIMARY KEY"
                { parsedColumn | name = "match_id", kind = "bigint", primaryKey = Just "", foreignKey = Just ( Nothing, { schema = Nothing, table = "matches", column = Just "match_id" } ) }
            , testSql ( parseCreateTableColumn, "with foreign key before not null" )
                "id uuid references auth.users not null primary key"
                { parsedColumn | name = "id", kind = "uuid", primaryKey = Just "", nullable = False, foreignKey = Just ( Nothing, { schema = Just "auth", table = "users", column = Nothing } ) }
            , testSql ( parseCreateTableColumn, "with unique" )
                "`email` varchar(255) NOT NULL UNIQUE"
                { parsedColumn | name = "email", kind = "varchar(255)", nullable = False, unique = Just "UNIQUE" }
            , testSql ( parseCreateTableColumn, "with check" )
                "state text check(state in (NULL, 'Done', 'Obsolete', 'Deletable'))"
                { parsedColumn | name = "state", kind = "text", check = Just "state in (NULL, 'Done', 'Obsolete', 'Deletable')" }
            , testSql ( parseCreateTableColumn, "with comment" )
                "order varchar COMMENT 'Possible values: ''asc'',''desc'''"
                { parsedColumn | name = "order", kind = "varchar", comment = Just "Possible values: 'asc','desc'" }
            , testSql ( parseCreateTableColumn, "with comment with double quotes" )
                "order varchar COMMENT \"Possible values: \"\"asc\"\",\"\"desc\"\"\""
                { parsedColumn | name = "order", kind = "varchar", comment = Just "Possible values: \"asc\",\"desc\"" }
            , testSql ( parseCreateTableColumn, "with collate" )
                "id nvarchar(32) COLLATE Modern_Spanish_CI_AS NOT NULL"
                { parsedColumn | name = "id", kind = "nvarchar(32)", nullable = False }
            , testSql ( parseCreateTableColumn, "with collate after not null" )
                "description text NOT NULL COLLATE pg_catalog.\"C\""
                { parsedColumn | name = "description", kind = "text", nullable = False }
            , testSql ( parseCreateTableColumn, "with generated" )
                "event_name text not null generated always as ((((service__name || '.'::text) || resource_type__name) || '.'::text) || verb__name) stored"
                { parsedColumn | name = "event_name", kind = "text", nullable = False, default = Just "generated always as ((((service__name || '.'::text) || resource_type__name) || '.'::text) || verb__name) stored" }
            ]
        , describe "parseCreateTableForeignKey"
            [ testSql ( parseCreateTableForeignKey, "sqlite" )
                "foreign key(`ulid`) references `tasks`(`ulid`)"
                { name = Nothing, src = "ulid", ref = { schema = Nothing, table = "tasks", column = Just "ulid" } }
            , testSql ( parseCreateTableForeignKey, "with schema, spaces and triggers" )
                "FOREIGN KEY (cat_id) REFERENCES dbo.cats (cat_id) ON DELETE CASCADE ON UPDATE CASCADE"
                { name = Nothing, src = "cat_id", ref = { schema = Just "dbo", table = "cats", column = Just "cat_id" } }
            ]
        , describe "parseCreateTableColumnForeignKey"
            [ testSql ( parseCreateTableColumnForeignKey, "references" )
                "REFERENCES `t_house` (`id`)"
                ( Nothing, { schema = Nothing, table = "t_house", column = Just "id" } )
            , testSql ( parseCreateTableColumnForeignKey, "references with triggers" )
                "REFERENCES `t_user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE"
                ( Nothing, { schema = Nothing, table = "t_user", column = Just "id" } )
            ]
        , describe "parseCreateTableKey"
            [ testSql ( parseCreateTableKey, "using" )
                "KEY `fk_user_id` (`user_id`) USING BTREE"
                { name = "fk_user_id", columns = Nel "user_id" [], definition = "KEY `fk_user_id` (`user_id`) USING BTREE" }
            , testSql ( parseCreateTableKey, "nested parenthesis" )
                "KEY `ResourceId` (`ResourceId`(333))"
                { name = "ResourceId", columns = Nel "ResourceId" [], definition = "KEY `ResourceId` (`ResourceId`(333))" }
            ]
        ]
