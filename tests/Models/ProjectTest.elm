module Models.ProjectTest exposing (..)

import Dict
import Expect
import Json.Decode as Decode
import Libs.Dict as D
import Libs.Ned as Ned
import Libs.Nel exposing (Nel)
import Libs.Position exposing (Position)
import Models.Project exposing (..)
import Test exposing (Test, describe, test)
import TestHelpers.JsonTest exposing (jsonFuzz, jsonTest)
import TestHelpers.ProjectFuzzers as ProjectFuzzers
import Time


tableId : TableId
tableId =
    ( "public", "users" )


tableId2 : TableId
tableId2 =
    ( "other", "users" )


suite : Test
suite =
    describe "Models.Project"
        [ describe "tableIdAsHtmlId"
            [ test "round-trip" (\_ -> tableId |> tableIdAsHtmlId |> htmlIdAsTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> tableIdAsHtmlId |> Expect.equal "table-public-users")
            ]
        , describe "tableIdAsString"
            [ test "round-trip" (\_ -> tableId |> tableIdAsString |> stringAsTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId |> tableIdAsString |> Expect.equal "public.users")
            ]
        , describe "showTableId"
            [ test "round-trip" (\_ -> tableId2 |> showTableId |> parseTableId |> Expect.equal tableId2)
            , test "round-trip with default schema" (\_ -> tableId |> showTableId |> parseTableId |> Expect.equal tableId)
            , test "serialize" (\_ -> tableId2 |> showTableId |> Expect.equal "other.users")
            , test "serialize with default schema" (\_ -> tableId |> showTableId |> Expect.equal "users")
            ]
        , describe "showTableName"
            [ test "with default schema" (\_ -> showTableName "public" "users" |> Expect.equal "users")
            , test "with other schema" (\_ -> showTableName "wp" "users" |> Expect.equal "wp.users")
            ]
        , describe "json"
            [ jsonTest "project0" project0 project0Json encodeProject decodeProject
            , jsonTest "project1" project1 project1Json encodeProject decodeProject
            , jsonTest "project2" project2 project2Json encodeProject decodeProject

            --, jsonFuzz "Project" ProjectFuzzers.project encodeProject decodeProject -- This test failed because it threw an exception: "RangeError: Maximum call stack size exceeded"
            , jsonFuzz "ProjectSource" ProjectFuzzers.projectSource encodeProjectSource decodeProjectSource
            , jsonFuzz "ProjectSourceContent" ProjectFuzzers.projectSourceContent encodeProjectSourceContent decodeProjectSourceContent

            --, jsonFuzz "Schema" ProjectFuzzers.schema encodeSchema decodeSchema -- This test failed because it threw an exception: "RangeError: Maximum call stack size exceeded"
            , jsonFuzz "Table" ProjectFuzzers.table encodeTable decodeTable
            , jsonFuzz "Column" (ProjectFuzzers.column 0) encodeColumn (decodeColumn |> Decode.map (\c -> c 0))
            , jsonFuzz "PrimaryKey" ProjectFuzzers.primaryKey encodePrimaryKey decodePrimaryKey
            , jsonFuzz "Unique" ProjectFuzzers.unique encodeUnique decodeUnique
            , jsonFuzz "Index" ProjectFuzzers.index encodeIndex decodeIndex
            , jsonFuzz "Check" ProjectFuzzers.check encodeCheck decodeCheck
            , jsonFuzz "Comment" ProjectFuzzers.comment encodeComment decodeComment
            , jsonFuzz "Relation" ProjectFuzzers.relation encodeRelation decodeRelation
            , jsonFuzz "ColumnRef" ProjectFuzzers.columnRef encodeColumnRef decodeColumnRef
            , jsonFuzz "Source" ProjectFuzzers.source encodeSource decodeSource
            , jsonFuzz "SourceLine" ProjectFuzzers.sourceLine encodeSourceLine decodeSourceLine
            , jsonFuzz "Layout" ProjectFuzzers.layout encodeLayout decodeLayout
            , jsonFuzz "CanvasProps" ProjectFuzzers.canvasProps encodeCanvasProps decodeCanvasProps
            , jsonFuzz "TableProps" ProjectFuzzers.tableProps encodeTableProps decodeTableProps
            , jsonFuzz "ProjectSettings" ProjectFuzzers.projectSettings (encodeProjectSettings defaultProjectSettings) (decodeProjectSettings defaultProjectSettings)
            ]
        ]


defaultProjectSettings : { findPath : FindPathSettings }
defaultProjectSettings =
    { findPath = FindPathSettings 3 [] [] }


project0 : Project
project0 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSource "src-1" "source 1" (LocalFile "structure.sql" 10000 (time 1102)) (time 1100) (time 1101)) []
    , schema = Schema Dict.empty [] (Layout (CanvasProps (Position 1 2) 0.75) [] [] (time 1200) (time 1201))
    , layouts = Dict.empty
    , currentLayout = Nothing
    , settings = defaultProjectSettings
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project0Json : String
project0Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","source":{"kind":"LocalFile","name":"structure.sql","size":10000,"lastModified":1102},"createdAt":1100,"updatedAt":1101}],"""
        ++ """"schema":{"tables":[],"relations":[],"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[],"createdAt":1200,"updatedAt":1201}},"layouts":{},"createdAt":1000,"updatedAt":1001,"version":1}"""


project1 : Project
project1 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSource "src-1" "source 1" (LocalFile "structure.sql" 10000 (time 200)) (time 1100) (time 1101)) []
    , schema =
        { tables = D.fromListMap .id [ Table ( "public", "users" ) "public" "users" (Ned.singletonMap .name (Column 0 "id" "int" False Nothing Nothing [])) Nothing [] [] [] Nothing [] ]
        , relations = []
        , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
        }
    , layouts = Dict.fromList [ ( "empty", Layout (CanvasProps (Position 0 0) 0.5) [] [] (time 1202) (time 1203) ) ]
    , currentLayout = Nothing
    , settings = { findPath = FindPathSettings 4 [] [] }
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project1Json : String
project1Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","source":{"kind":"LocalFile","name":"structure.sql","size":10000,"lastModified":200},"createdAt":1100,"updatedAt":1101}],"""
        ++ """"schema":{"tables":[{"schema":"public","table":"users","columns":[{"name":"id","type":"int"}]}],"relations":[],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":3,"top":4},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201}},"""
        ++ """"layouts":{"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4}},"createdAt":1000,"updatedAt":1001,"version":1}"""


project2 : Project
project2 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSource "src-1" "source 1" (LocalFile "structure.sql" 10000 (time 200)) (time 1100) (time 1101)) []
    , schema =
        { tables =
            D.fromListMap .id
                [ { id = ( "public", "users" )
                  , schema = "public"
                  , name = "users"
                  , columns =
                        Ned.buildMap .name
                            (Column 0 "id" "int" False Nothing Nothing [])
                            [ Column 1 "name" "varchar" True Nothing Nothing [] ]
                  , primaryKey = Just (PrimaryKey "users_pk" (Nel "id" []) [])
                  , uniques = []
                  , indexes = []
                  , checks = []
                  , comment = Nothing
                  , sources = [ Source "src-1" (Nel (SourceLine 10 "CREATE TABLE users") [ SourceLine 11 "  (id int NOT NULL, name varchar);" ]) ]
                  }
                , { id = ( "public", "creds" )
                  , schema = "public"
                  , name = "creds"
                  , columns =
                        Ned.buildMap .name
                            (Column 0 "user_id" "int" False Nothing Nothing [ Source "src-1" (Nel (SourceLine 14 "  user_id int NOT NULL,") []) ])
                            [ Column 1 "login" "varchar" False Nothing Nothing [ Source "src-1" (Nel (SourceLine 15 "  login varchar NOT NULL,") []) ]
                            , Column 2 "pass" "varchar" False Nothing (Just (Comment "Encrypted field" [])) [ Source "src-1" (Nel (SourceLine 16 "  pass varchar NOT NULL,") []) ]
                            , Column 3 "role" "varchar" True (Just "guest") Nothing [ Source "src-1" (Nel (SourceLine 17 "  role varchar") []) ]
                            ]
                  , primaryKey = Nothing
                  , uniques = [ Unique "unique_login" (Nel "login" []) "(login)" [] ]
                  , indexes = [ Index "role_idx" (Nel "role" []) "(role)" [] ]
                  , checks = []
                  , comment = Just (Comment "To allow users to login" [])
                  , sources =
                        [ Source "src-1"
                            (Nel (SourceLine 13 "CREATE TABLE creds (")
                                [ SourceLine 14 "  user_id int NOT NULL,"
                                , SourceLine 15 "  login varchar NOT NULL,"
                                , SourceLine 16 "  pass varchar NOT NULL,"
                                , SourceLine 17 "  role varchar"
                                , SourceLine 18 ");"
                                ]
                            )
                        ]
                  }
                ]
        , relations = [ Relation "creds_user_id" (ColumnRef ( "public", "creds" ) "user_id") (ColumnRef ( "public", "users" ) "id") [] ]
        , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
        }
    , layouts =
        Dict.fromList
            [ ( "empty", Layout (CanvasProps (Position 0 0) 0.5) [] [] (time 1202) (time 1203) )
            , ( "users", Layout (CanvasProps (Position 12 32) 1.5) [ TableProps ( "public", "users" ) (Position 90 102) "red" [ "id", "name" ] True ] [] (time 1202) (time 1203) )
            ]
    , currentLayout = Just "users"
    , settings = { findPath = FindPathSettings 4 [ ( "public", "users" ) ] [ "created_by" ] }
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project2Json : String
project2Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","source":{"kind":"LocalFile","name":"structure.sql","size":10000,"lastModified":200},"createdAt":1100,"updatedAt":1101}],"""
        ++ """"schema":{"tables":["""
        ++ """{"schema":"public","table":"creds","columns":[{"name":"user_id","type":"int","sources":[{"id":"src-1","lines":[{"no":14,"text":"  user_id int NOT NULL,"}]}]},{"name":"login","type":"varchar","sources":[{"id":"src-1","lines":[{"no":15,"text":"  login varchar NOT NULL,"}]}]},{"name":"pass","type":"varchar","comment":{"text":"Encrypted field"},"sources":[{"id":"src-1","lines":[{"no":16,"text":"  pass varchar NOT NULL,"}]}]},{"name":"role","type":"varchar","nullable":true,"default":"guest","sources":[{"id":"src-1","lines":[{"no":17,"text":"  role varchar"}]}]}],"uniques":[{"name":"unique_login","columns":["login"],"definition":"(login)"}],"indexes":[{"name":"role_idx","columns":["role"],"definition":"(role)"}],"comment":{"text":"To allow users to login"},"sources":[{"id":"src-1","lines":[{"no":13,"text":"CREATE TABLE creds ("},{"no":14,"text":"  user_id int NOT NULL,"},{"no":15,"text":"  login varchar NOT NULL,"},{"no":16,"text":"  pass varchar NOT NULL,"},{"no":17,"text":"  role varchar"},{"no":18,"text":");"}]}]},"""
        ++ """{"schema":"public","table":"users","columns":[{"name":"id","type":"int"},{"name":"name","type":"varchar","nullable":true}],"primaryKey":{"name":"users_pk","columns":["id"]},"sources":[{"id":"src-1","lines":[{"no":10,"text":"CREATE TABLE users"},{"no":11,"text":"  (id int NOT NULL, name varchar);"}]}]}],"""
        ++ """"relations":[{"name":"creds_user_id","src":{"table":"public.creds","column":"user_id"},"ref":{"table":"public.users","column":"id"}}],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":3,"top":4},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201}},"""
        ++ """"layouts":{"""
        ++ """"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203},"""
        ++ """"users":{"canvas":{"position":{"left":12,"top":32},"zoom":1.5},"tables":[{"id":"public.users","position":{"left":90,"top":102},"color":"red","columns":["id","name"],"selected":true}],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"currentLayout":"users","settings":{"findPath":{"maxPathLength":4,"ignoredTables":["public.users"],"ignoredColumns":["created_by"]}},"createdAt":1000,"updatedAt":1001,"version":1}"""


time : Int -> Time.Posix
time ts =
    Time.millisToPosix ts
