module Storage.ProjectV1Test exposing (..)

import Dict
import Expect
import Json.Decode as Decode
import Libs.Dict as D
import Libs.Ned as Ned
import Libs.Nel exposing (Nel)
import Libs.Position exposing (Position)
import Storage.ProjectV1 exposing (CanvasPropsV1, ColumnRefV1, ColumnV1, CommentV1, FindPathSettingsV1, IndexV1, LayoutV1, PrimaryKeyV1, ProjectSourceContentV1(..), ProjectSourceV1, ProjectV1, RelationV1, SchemaV1, SourceLineV1, SourceV1, TablePropsV1, TableV1, UniqueV1, decodeProject, defaultProjectSettings, upgrade)
import Storage.ProjectV2Test as ProjectV2Test
import Test exposing (Test, describe, test)
import Time


suite : Test
suite =
    describe "Storage.ProjectV1"
        [ describe "json"
            [ test "decode project0" (\_ -> project0Json |> Decode.decodeString decodeProject |> Expect.equal (Ok project0))
            , test "decode project1" (\_ -> project1Json |> Decode.decodeString decodeProject |> Expect.equal (Ok project1))
            , test "decode project2" (\_ -> project2Json |> Decode.decodeString decodeProject |> Expect.equal (Ok project2))
            , test "upgrade project0" (\_ -> project0 |> upgrade |> Expect.equal ProjectV2Test.project0)
            , test "upgrade project1" (\_ -> project1 |> upgrade |> Expect.equal ProjectV2Test.project1)
            , test "upgrade project2" (\_ -> project2 |> upgrade |> Expect.equal ProjectV2Test.project2)
            ]
        ]


project0 : ProjectV1
project0 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSourceV1 "src-1" "source 1" (LocalFileV1 "structure.sql" 10000 (time 1102)) (time 1100) (time 1101)) []
    , schema = SchemaV1 Dict.empty [] (LayoutV1 (CanvasPropsV1 (Position 1 2) 0.75) [] [] (time 1200) (time 1201))
    , layouts = Dict.empty
    , currentLayout = Nothing
    , settings = defaultProjectSettings
    , createdAt = time 1000
    , updatedAt = time 1001
    , fromSample = Nothing
    }


project0Json : String
project0Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","source":{"kind":"LocalFile","name":"structure.sql","size":10000,"lastModified":1102},"createdAt":1100,"updatedAt":1101}],"""
        ++ """"schema":{"tables":[],"relations":[],"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[],"createdAt":1200,"updatedAt":1201}},"layouts":{},"createdAt":1000,"updatedAt":1001,"version":1}"""


project1 : ProjectV1
project1 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSourceV1 "src-1" "source 1" (LocalFileV1 "structure.sql" 10000 (time 200)) (time 1100) (time 1101)) []
    , schema =
        { tables = D.fromListMap .id [ TableV1 ( "public", "users" ) "public" "users" (Ned.singletonMap .name (ColumnV1 0 "id" "int" False Nothing Nothing [])) Nothing [] [] [] Nothing [] ]
        , relations = []
        , layout = LayoutV1 (CanvasPropsV1 (Position 1 2) 0.75) [ TablePropsV1 ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
        }
    , layouts = Dict.fromList [ ( "empty", LayoutV1 (CanvasPropsV1 (Position 0 0) 0.5) [] [] (time 1202) (time 1203) ) ]
    , currentLayout = Nothing
    , settings = { findPath = FindPathSettingsV1 4 [] [] }
    , createdAt = time 1000
    , updatedAt = time 1001
    , fromSample = Just "basic"
    }


project1Json : String
project1Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","source":{"kind":"LocalFile","name":"structure.sql","size":10000,"lastModified":200},"createdAt":1100,"updatedAt":1101}],"""
        ++ """"schema":{"tables":[{"schema":"public","table":"users","columns":[{"name":"id","type":"int"}]}],"relations":[],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":3,"top":4},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201}},"""
        ++ """"layouts":{"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4}},"createdAt":1000,"updatedAt":1001,"fromSample":"basic","version":1}"""


project2 : ProjectV1
project2 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = Nel (ProjectSourceV1 "src-1" "source 1" (LocalFileV1 "structure.sql" 10000 (time 200)) (time 1100) (time 1101)) []
    , schema =
        { tables =
            D.fromListMap .id
                [ { id = ( "public", "users" )
                  , schema = "public"
                  , name = "users"
                  , columns =
                        Ned.buildMap .name
                            (ColumnV1 0 "id" "int" False Nothing Nothing [])
                            [ ColumnV1 1 "name" "varchar" True Nothing Nothing [] ]
                  , primaryKey = Just (PrimaryKeyV1 "users_pk" (Nel "id" []) [])
                  , uniques = []
                  , indexes = []
                  , checks = []
                  , comment = Nothing
                  , sources = [ SourceV1 "src-1" (Nel (SourceLineV1 10 "CREATE TABLE users") [ SourceLineV1 11 "  (id int NOT NULL, name varchar);" ]) ]
                  }
                , { id = ( "public", "creds" )
                  , schema = "public"
                  , name = "creds"
                  , columns =
                        Ned.buildMap .name
                            (ColumnV1 0 "user_id" "int" False Nothing Nothing [ SourceV1 "src-1" (Nel (SourceLineV1 14 "  user_id int NOT NULL,") []) ])
                            [ ColumnV1 1 "login" "varchar" False Nothing Nothing [ SourceV1 "src-1" (Nel (SourceLineV1 15 "  login varchar NOT NULL,") []) ]
                            , ColumnV1 2 "pass" "varchar" False Nothing (Just (CommentV1 "Encrypted field" [])) [ SourceV1 "src-1" (Nel (SourceLineV1 16 "  pass varchar NOT NULL,") []) ]
                            , ColumnV1 3 "role" "varchar" True (Just "guest") Nothing [ SourceV1 "src-1" (Nel (SourceLineV1 17 "  role varchar") []) ]
                            ]
                  , primaryKey = Nothing
                  , uniques = [ UniqueV1 "unique_login" (Nel "login" []) "(login)" [] ]
                  , indexes = [ IndexV1 "role_idx" (Nel "role" []) "(role)" [] ]
                  , checks = []
                  , comment = Just (CommentV1 "To allow users to login" [])
                  , sources =
                        [ SourceV1 "src-1"
                            (Nel (SourceLineV1 13 "CREATE TABLE creds (")
                                [ SourceLineV1 14 "  user_id int NOT NULL,"
                                , SourceLineV1 15 "  login varchar NOT NULL,"
                                , SourceLineV1 16 "  pass varchar NOT NULL,"
                                , SourceLineV1 17 "  role varchar"
                                , SourceLineV1 18 ");"
                                ]
                            )
                        ]
                  }
                ]
        , relations = [ RelationV1 "creds_user_id" (ColumnRefV1 ( "public", "creds" ) "user_id") (ColumnRefV1 ( "public", "users" ) "id") [] ]
        , layout = LayoutV1 (CanvasPropsV1 (Position 1 2) 0.75) [ TablePropsV1 ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
        }
    , layouts =
        Dict.fromList
            [ ( "empty", LayoutV1 (CanvasPropsV1 (Position 0 0) 0.5) [] [] (time 1202) (time 1203) )
            , ( "users", LayoutV1 (CanvasPropsV1 (Position 12 32) 1.5) [ TablePropsV1 ( "public", "users" ) (Position 90 102) "red" [ "id", "name" ] True ] [] (time 1202) (time 1203) )
            ]
    , currentLayout = Just "users"
    , settings = { findPath = FindPathSettingsV1 4 [ ( "public", "users" ) ] [ "created_by" ] }
    , createdAt = time 1000
    , updatedAt = time 1001
    , fromSample = Nothing
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
