module DataSources.SqlParser.Parsers.CreateTableTest exposing (..)

import DataSources.SqlParser.Parsers.CreateTable exposing (parseCreateTable, parseCreateTableColumn, parseCreateTableForeignKey, parseCreateTableKey)
import DataSources.SqlParser.TestHelpers.Tests exposing (parsedColumn, parsedTable, testParse, testParseSql)
import Libs.Nel exposing (Nel)
import Test exposing (Test, describe)


suite : Test
suite =
    describe "CreateTable"
        [ describe "parseCreateTable"
            [ testParse ( parseCreateTable, "basic" )
                "CREATE TABLE aaa.bbb (ccc int);"
                { parsedTable | schema = Just "aaa", table = "bbb", columns = Nel { parsedColumn | name = "ccc", kind = "int" } [] }
            , testParse ( parseCreateTable, "if not exists" )
                "CREATE TABLE IF NOT EXISTS aaa.bbb (ccc int);"
                { parsedTable | schema = Just "aaa", table = "bbb", columns = Nel { parsedColumn | name = "ccc", kind = "int" } [] }
            , testParse ( parseCreateTable, "complex" )
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
            , testParse ( parseCreateTable, "with options" )
                "CREATE TABLE p.table (id bigint NOT NULL)    WITH (autovacuum_analyze_threshold='100000');"
                { parsedTable | schema = Just "p", table = "table", columns = Nel { parsedColumn | name = "id", kind = "bigint", nullable = False } [] }
            , testParse ( parseCreateTable, "without schema, lowercase and no space before body" )
                "create table migrations(version varchar not null);"
                { parsedTable | table = "migrations", columns = Nel { parsedColumn | name = "version", kind = "varchar", nullable = False } [] }
            , testParse ( parseCreateTable, "with db" )
                "CREATE TABLE db.schema.table (column int);"
                { parsedTable | schema = Just "schema", table = "table", columns = Nel { parsedColumn | name = "column", kind = "int" } [] }
            , testParse ( parseCreateTable, "with references" )
                "create table students (id serial primary key, name varchar(50) not null, year integer not null, house_id integer references houses(id));"
                { parsedTable
                    | table = "students"
                    , columns =
                        Nel { parsedColumn | name = "id", kind = "serial", primaryKey = Just "students_pk_az" }
                            [ { parsedColumn | name = "name", kind = "varchar(50)", nullable = False }
                            , { parsedColumn | name = "year", kind = "integer", nullable = False }
                            , { parsedColumn | name = "house_id", kind = "integer", foreignKey = Just ( Nothing, { schema = Nothing, table = "houses", column = Just "id" } ) }
                            ]
                }
            ]
        , describe "parseCreateTableColumn"
            [ testParseSql ( parseCreateTableColumn "", "basic" )
                "id bigint NOT NULL"
                { parsedColumn | name = "id", kind = "bigint", nullable = False }
            , testParseSql ( parseCreateTableColumn "", "nullable" )
                "id bigint"
                { parsedColumn | name = "id", kind = "bigint" }
            , testParseSql ( parseCreateTableColumn "", "with default" )
                "status character varying(255) DEFAULT 'done'::character varying"
                { parsedColumn | name = "status", kind = "character varying(255)", default = Just "'done'::character varying" }
            , testParseSql ( parseCreateTableColumn "", "with comma in type" )
                "price numeric(8,2)"
                { parsedColumn | name = "price", kind = "numeric(8,2)" }
            , testParseSql ( parseCreateTableColumn "", "with enclosing quotes" )
                "\"id\" bigint"
                { parsedColumn | name = "id", kind = "bigint" }
            , testParseSql ( parseCreateTableColumn "t1", "with primary key" )
                "id bigint PRIMARY KEY"
                { parsedColumn | name = "id", kind = "bigint", primaryKey = Just "t1_pk_az" }
            , testParseSql ( parseCreateTableColumn "", "with primary key constraint" )
                "id bigint NOT NULL CONSTRAINT users_pk PRIMARY KEY"
                { parsedColumn | name = "id", kind = "bigint", nullable = False, primaryKey = Just "users_pk" }
            , testParseSql ( parseCreateTableColumn "", "with foreign key having schema, table & column" )
                "user_id bigint CONSTRAINT users_fk REFERENCES public.users.id"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Just "public", table = "users", column = Just "id" } ) }
            , testParseSql ( parseCreateTableColumn "", "with foreign key having table & column" )
                "user_id bigint CONSTRAINT users_fk REFERENCES users.id"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Nothing, table = "users", column = Just "id" } ) }
            , testParseSql ( parseCreateTableColumn "", "with foreign key having table & column in parenthesis" )
                "user_id bigint references users(id)"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Nothing, { schema = Nothing, table = "users", column = Just "id" } ) }
            , testParseSql ( parseCreateTableColumn "", "with foreign key having only table" )
                "user_id bigint CONSTRAINT users_fk REFERENCES users"
                { parsedColumn | name = "user_id", kind = "bigint", foreignKey = Just ( Just "users_fk", { schema = Nothing, table = "users", column = Nothing } ) }
            , testParseSql ( parseCreateTableColumn "", "with check" )
                "state text check(state in (NULL, 'Done', 'Obsolete', 'Deletable'))"
                { parsedColumn | name = "state", kind = "text", check = Just "state in (NULL, 'Done', 'Obsolete', 'Deletable')" }
            , testParseSql ( parseCreateTableColumn "", "with collate" )
                "id nvarchar(32) COLLATE Modern_Spanish_CI_AS NOT NULL"
                { parsedColumn | name = "id", kind = "nvarchar(32)", nullable = False }
            , testParseSql ( parseCreateTableColumn "", "with generated" )
                "event_name text not null generated always as ((((service__name || '.'::text) || resource_type__name) || '.'::text) || verb__name) stored"
                { parsedColumn | name = "event_name", kind = "text", nullable = False, default = Just "generated always as ((((service__name || '.'::text) || resource_type__name) || '.'::text) || verb__name) stored" }
            ]
        , describe "parseCreateTableForeignKey"
            [ testParseSql ( parseCreateTableForeignKey, "sqlite" )
                "foreign key(`ulid`) references `tasks`(`ulid`)"
                { name = Nothing, src = "ulid", ref = { schema = Nothing, table = "tasks", column = Just "ulid" } }
            ]
        , describe "parseCreateTableKey"
            [ testParseSql ( parseCreateTableKey, "using" )
                "KEY `fk_user_id` (`user_id`) USING BTREE"
                { name = "fk_user_id", columns = Nel "user_id" [], definition = "KEY `fk_user_id` (`user_id`) USING BTREE" }
            , testParseSql ( parseCreateTableKey, "nested parenthesis" )
                "KEY `ResourceId` (`ResourceId`(333))"
                { name = "ResourceId", columns = Nel "ResourceId" [], definition = "KEY `ResourceId` (`ResourceId`(333))" }
            ]
        ]
