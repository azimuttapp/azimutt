module DataSources.SqlParser.FileParserTest exposing (..)

import DataSources.SqlParser.FileParser exposing (buildStatements, parseLines)
import Expect
import Libs.Nel as Nel
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "FileParser"
        [ describe "buildStatements"
            [ testBuildStatements "basic"
                """-- a comment

                   CREATE TABLE public.users (
                     id bigint NOT NULL,
                     name character varying(255)
                   );

                   COMMENT ON TABLE public.users IS 'A comment ; ''tricky'' one';

                   ALTER TABLE ONLY public.users
                     ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);"""
                [ """CREATE TABLE public.users (
                       id bigint NOT NULL,
                       name character varying(255)
                     );"""
                , """COMMENT ON TABLE public.users IS 'A comment ; ''tricky'' one';"""
                , """ALTER TABLE ONLY public.users
                       ADD CONSTRAINT users_id_pkey PRIMARY KEY (id);"""
                ]
            , testBuildStatements "nested begin"
                """CREATE FUNCTION public.set_log_min_duration(integer) RETURNS void
                       LANGUAGE plpgsql STRICT SECURITY DEFINER
                       SET search_path TO 'pg_catalog', 'pg_temp'
                   AS $_$
                   BEGIN
                       EXECUTE 'SET log_min_duration_statement = ' || $1::text;
                   END
                   $_$;"""
                [ """CREATE FUNCTION public.set_log_min_duration(integer) RETURNS void
                         LANGUAGE plpgsql STRICT SECURITY DEFINER
                         SET search_path TO 'pg_catalog', 'pg_temp'
                     AS $_$
                     BEGIN
                         EXECUTE 'SET log_min_duration_statement = ' || $1::text;
                     END
                     $_$;""" ]
            , testBuildStatements "case blocks"
                """PRAGMA foreign_keys=OFF;

                   CREATE VIEW `tasks_view` as
                   select
                   `tasks`.`ulid` as `ulid`,
                   ifnull(`tasks`.`priority_adjustment`, 0.0)
                    + case   when waiting_utc is null then 0.0
                    when waiting_utc >= datetime('now') then 0.0
                    when waiting_utc <  datetime('now') then -10.0
                   end
                   as `priority`
                   from
                   `tasks`;

                   CREATE TRIGGER `set_modified_utc_after_update`
                   after update on `tasks`
                   when `new`.`modified_utc` is `old`.`modified_utc`
                   begin
                    update `tasks`
                   set `modified_utc` = datetime('now')
                   where `ulid` = `new`.`ulid`
                   ;
                   end;"""
                [ "PRAGMA foreign_keys=OFF;"
                , """CREATE VIEW `tasks_view` as
                     select
                     `tasks`.`ulid` as `ulid`,
                     ifnull(`tasks`.`priority_adjustment`, 0.0)
                      + case   when waiting_utc is null then 0.0
                      when waiting_utc >= datetime('now') then 0.0
                      when waiting_utc <  datetime('now') then -10.0
                     end
                     as `priority`
                     from
                     `tasks`;"""
                , """CREATE TRIGGER `set_modified_utc_after_update`
                     after update on `tasks`
                     when `new`.`modified_utc` is `old`.`modified_utc`
                     begin
                      update `tasks`
                     set `modified_utc` = datetime('now')
                     where `ulid` = `new`.`ulid`
                     ;
                     end;"""
                ]
            ]
        ]


testBuildStatements : String -> String -> List String -> Test
testBuildStatements name content statements =
    test name
        (\_ ->
            content
                |> parseLines "file.sql"
                |> buildStatements
                |> List.map (\s -> s |> Nel.toList |> List.map .text |> List.map String.trim)
                |> Expect.equal (statements |> List.map (\s -> s |> String.split "\n" |> List.map String.trim))
        )
