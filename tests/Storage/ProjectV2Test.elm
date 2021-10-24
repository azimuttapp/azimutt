module Storage.ProjectV2Test exposing (..)

import Array
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as D
import Libs.Ned as Ned
import Libs.Nel exposing (Nel)
import Libs.Position exposing (Position)
import Models.Project exposing (CanvasProps, Column, ColumnRef, Comment, FindPathSettings, Index, Layout, Origin, PrimaryKey, Project, Relation, Source, SourceKind(..), Table, TableId, TableProps, Unique, initProjectSettings)
import Storage.ProjectV2 exposing (..)
import Test exposing (Test, describe)
import TestHelpers.JsonTest exposing (jsonFuzz, jsonTest)
import TestHelpers.ProjectFuzzers as ProjectFuzzers
import Time


suite : Test
suite =
    describe "Storage.Project"
        [ describe "json"
            [ jsonTest "project0" project0 project0Json encodeProject decodeProject
            , jsonTest "project1" project1 project1Json encodeProject decodeProject
            , jsonTest "project2" project2 project2Json encodeProject decodeProject

            -- , jsonFuzz "Project" ProjectFuzzers.project encodeProject decodeProject -- This test failed because it threw an exception: "RangeError: Maximum call stack size exceeded"
            -- , jsonFuzz "Source" ProjectFuzzers.source encodeSource decodeSource
            -- , jsonFuzz "SourceKind" ProjectFuzzers.sourceKind encodeSourceKind decodeSourceKind
            , jsonFuzz "Table" ProjectFuzzers.table encodeTable decodeTable
            , jsonFuzz "Column" (ProjectFuzzers.column 0) encodeColumn (decodeColumn |> Decode.map (\c -> c 0))
            , jsonFuzz "PrimaryKey" ProjectFuzzers.primaryKey encodePrimaryKey decodePrimaryKey
            , jsonFuzz "Unique" ProjectFuzzers.unique encodeUnique decodeUnique
            , jsonFuzz "Index" ProjectFuzzers.index encodeIndex decodeIndex
            , jsonFuzz "Check" ProjectFuzzers.check encodeCheck decodeCheck
            , jsonFuzz "Comment" ProjectFuzzers.comment encodeComment decodeComment
            , jsonFuzz "Relation" ProjectFuzzers.relation encodeRelation decodeRelation
            , jsonFuzz "ColumnRef" ProjectFuzzers.columnRef encodeColumnRef decodeColumnRef
            , jsonFuzz "Source" ProjectFuzzers.origin encodeOrigin decodeOrigin
            , jsonFuzz "Layout" ProjectFuzzers.layout encodeLayout decodeLayout
            , jsonFuzz "CanvasProps" ProjectFuzzers.canvasProps encodeCanvasProps decodeCanvasProps
            , jsonFuzz "TableProps" ProjectFuzzers.tableProps encodeTableProps decodeTableProps
            , jsonFuzz "ProjectSettings" ProjectFuzzers.projectSettings (encodeProjectSettings initProjectSettings) (decodeProjectSettings initProjectSettings)
            ]
        ]


project0 : Project
project0 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = [ Source "src-1" "source 1" (LocalFile "structure.sql" 10000 (time 1102)) Array.empty Dict.empty [] True Nothing (time 1100) (time 1101) ]
    , tables = Dict.empty
    , relations = []
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.empty
    , settings = initProjectSettings
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project0Json : String
project0Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":1102},"content":[],"tables":[],"relations":[],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[],"createdAt":1200,"updatedAt":1201},"layouts":{},"createdAt":1000,"updatedAt":1001,"version":2}"""


tables1 : Dict TableId Table
tables1 =
    D.fromListMap .id [ Table ( "public", "users" ) "public" "users" (Ned.singletonMap .name (Column 0 "id" "int" False Nothing Nothing [])) Nothing [] [] [] Nothing [] ]


project1 : Project
project1 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = [ Source "src-1" "source 1" (LocalFile "structure.sql" 10000 (time 200)) Array.empty tables1 [] True (Just "basic") (time 1100) (time 1101) ]
    , tables = tables1
    , relations = []
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.fromList [ ( "empty", Layout (CanvasProps (Position 0 0) 0.5) [] [] (time 1202) (time 1203) ) ]
    , settings = { findPath = FindPathSettings 4 [] [] }
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project1Json : String
project1Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":200},"content":[],"tables":[{"schema":"public","table":"users","columns":[{"name":"id","type":"int"}]}],"relations":[],"fromSample":"basic","createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":3,"top":4},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201},"""
        ++ """"layouts":{"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4}},"createdAt":1000,"updatedAt":1001,"version":2}"""


tables2 : Dict TableId Table
tables2 =
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
          , origins = [ Origin "src-1" [ 10, 11 ] ]
          }
        , { id = ( "public", "creds" )
          , schema = "public"
          , name = "creds"
          , columns =
                Ned.buildMap .name
                    (Column 0 "user_id" "int" False Nothing Nothing [ Origin "src-1" [ 14 ] ])
                    [ Column 1 "login" "varchar" False Nothing Nothing [ Origin "src-1" [ 15 ] ]
                    , Column 2 "pass" "varchar" False Nothing (Just (Comment "Encrypted field" [])) [ Origin "src-1" [ 16 ] ]
                    , Column 3 "role" "varchar" True (Just "guest") Nothing [ Origin "src-1" [ 17 ] ]
                    ]
          , primaryKey = Nothing
          , uniques = [ Unique "unique_login" (Nel "login" []) "(login)" [] ]
          , indexes = [ Index "role_idx" (Nel "role" []) "(role)" [] ]
          , checks = []
          , comment = Just (Comment "To allow users to login" [])
          , origins = [ Origin "src-1" [ 13, 14, 15, 16, 17, 18 ] ]
          }
        ]


relations2 : List Relation
relations2 =
    [ Relation "creds_user_id" (ColumnRef ( "public", "creds" ) "user_id") (ColumnRef ( "public", "users" ) "id") [] ]


project2 : Project
project2 =
    { id = "prj-0"
    , name = "Project 0"
    , sources =
        [ Source "src-1"
            "source 1"
            (LocalFile "structure.sql" 10000 (time 200))
            (Array.fromList
                [ ""
                , ""
                , ""
                , ""
                , ""
                , ""
                , ""
                , ""
                , ""
                , ""
                , "CREATE TABLE users"
                , "  (id int NOT NULL, name varchar);"
                , ""
                , "CREATE TABLE creds ("
                , "  user_id int NOT NULL,"
                , "  login varchar NOT NULL,"
                , "  pass varchar NOT NULL,"
                , "  role varchar"
                , ");"
                ]
            )
            tables2
            relations2
            True
            Nothing
            (time 1100)
            (time 1101)
        ]
    , tables = tables2
    , relations = relations2
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) "red" [ "id" ] True ] [] (time 1200) (time 1201)
    , usedLayout = Just "users"
    , layouts =
        Dict.fromList
            [ ( "empty", Layout (CanvasProps (Position 0 0) 0.5) [] [] (time 1202) (time 1203) )
            , ( "users", Layout (CanvasProps (Position 12 32) 1.5) [ TableProps ( "public", "users" ) (Position 90 102) "red" [ "id", "name" ] True ] [] (time 1202) (time 1203) )
            ]
    , settings = { findPath = FindPathSettings 4 [ ( "public", "users" ) ] [ "created_by" ] }
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project2Json : String
project2Json =
    """{"id":"prj-0","name":"Project 0","""
        ++ """"sources":[{"id":"src-1","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":200},"content":["","","","","","","","","","","CREATE TABLE users","  (id int NOT NULL, name varchar);","","CREATE TABLE creds (","  user_id int NOT NULL,","  login varchar NOT NULL,","  pass varchar NOT NULL,","  role varchar",");"],"tables":["""
        ++ """{"schema":"public","table":"creds","columns":[{"name":"user_id","type":"int","origins":[{"id":"src-1","lines":[14]}]},{"name":"login","type":"varchar","origins":[{"id":"src-1","lines":[15]}]},{"name":"pass","type":"varchar","comment":{"text":"Encrypted field"},"origins":[{"id":"src-1","lines":[16]}]},{"name":"role","type":"varchar","nullable":true,"default":"guest","origins":[{"id":"src-1","lines":[17]}]}],"uniques":[{"name":"unique_login","columns":["login"],"definition":"(login)"}],"indexes":[{"name":"role_idx","columns":["role"],"definition":"(role)"}],"comment":{"text":"To allow users to login"},"origins":[{"id":"src-1","lines":[13,14,15,16,17,18]}]},"""
        ++ """{"schema":"public","table":"users","columns":[{"name":"id","type":"int"},{"name":"name","type":"varchar","nullable":true}],"primaryKey":{"name":"users_pk","columns":["id"]},"origins":[{"id":"src-1","lines":[10,11]}]}],"""
        ++ """"relations":[{"name":"creds_user_id","src":{"table":"public.creds","column":"user_id"},"ref":{"table":"public.users","column":"id"}}],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":1,"top":2},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":3,"top":4},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201},"""
        ++ """"usedLayout":"users","layouts":{"""
        ++ """"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203},"""
        ++ """"users":{"canvas":{"position":{"left":12,"top":32},"zoom":1.5},"tables":[{"id":"public.users","position":{"left":90,"top":102},"color":"red","columns":["id","name"],"selected":true}],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4,"ignoredTables":["public.users"],"ignoredColumns":["created_by"]}},"createdAt":1000,"updatedAt":1001,"version":2}"""


time : Int -> Time.Posix
time ts =
    Time.millisToPosix ts
