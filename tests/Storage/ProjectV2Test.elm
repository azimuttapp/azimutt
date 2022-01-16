module Storage.ProjectV2Test exposing (..)

import Array
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as D
import Libs.Models.Color as Color
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Ned as Ned
import Libs.Nel exposing (Nel)
import Models.ColumnOrder exposing (ColumnOrder(..))
import Models.Project as Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Check as Check
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Index as Index exposing (Index)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.ProjectSettings as ProjectSettings exposing (ProjectSettings)
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.Project.Unique as Unique exposing (Unique)
import Test exposing (Test, describe)
import TestHelpers.JsonTest exposing (jsonFuzz, jsonTest)
import TestHelpers.ProjectFuzzers as ProjectFuzzers
import Time


suite : Test
suite =
    describe "Storage.Project"
        [ describe "json"
            [ jsonTest "project0" project0 project0Json Project.encode Project.decode
            , jsonTest "project1" project1 project1Json Project.encode Project.decode
            , jsonTest "project2" project2 project2Json Project.encode Project.decode

            -- , jsonFuzz "Project" ProjectFuzzers.project Project.encode Project.decode -- This test failed because it threw an exception: "RangeError: Maximum call stack size exceeded"
            -- , jsonFuzz "Source" ProjectFuzzers.source Source.encode Source.decode
            -- , jsonFuzz "SourceKind" ProjectFuzzers.sourceKind SourceKind.encode SourceKind.decode
            , jsonFuzz "Table" ProjectFuzzers.table Table.encode Table.decode
            , jsonFuzz "Column" (ProjectFuzzers.column 0) Column.encode (Column.decode |> Decode.map (\c -> c 0))
            , jsonFuzz "PrimaryKey" ProjectFuzzers.primaryKey PrimaryKey.encode PrimaryKey.decode
            , jsonFuzz "Unique" ProjectFuzzers.unique Unique.encode Unique.decode
            , jsonFuzz "Index" ProjectFuzzers.index Index.encode Index.decode
            , jsonFuzz "Check" ProjectFuzzers.check Check.encode Check.decode
            , jsonFuzz "Comment" ProjectFuzzers.comment Comment.encode Comment.decode
            , jsonFuzz "Relation" ProjectFuzzers.relation Relation.encode Relation.decode
            , jsonFuzz "ColumnRef" ProjectFuzzers.columnRef ColumnRef.encode ColumnRef.decode
            , jsonFuzz "Source" ProjectFuzzers.origin Origin.encode Origin.decode
            , jsonFuzz "Layout" ProjectFuzzers.layout Layout.encode Layout.decode
            , jsonFuzz "CanvasProps" ProjectFuzzers.canvasProps CanvasProps.encode CanvasProps.decode
            , jsonFuzz "TableProps" ProjectFuzzers.tableProps TableProps.encode TableProps.decode
            , jsonFuzz "ProjectSettings" ProjectFuzzers.projectSettings (ProjectSettings.encode ProjectSettings.init) (ProjectSettings.decode ProjectSettings.init)
            ]
        ]


src1 : SourceId
src1 =
    SourceId.new "src-1"


project0 : Project
project0 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = [ Source src1 "source 1" (LocalFile "structure.sql" 10000 (time 1102)) Array.empty Dict.empty [] True Nothing (time 1100) (time 1101) ]
    , tables = Dict.empty
    , relations = []
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.empty
    , settings = ProjectSettings.init
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
    D.fromListMap .id [ Table ( "public", "users" ) "public" "users" False (Ned.singletonMap .name (Column 0 "id" "int" False Nothing Nothing [])) Nothing [] [] [] Nothing [] ]


project1 : Project
project1 =
    { id = "prj-0"
    , name = "Project 0"
    , sources = [ Source src1 "source 1" (LocalFile "structure.sql" 10000 (time 200)) Array.empty tables1 [] True (Just "basic") (time 1100) (time 1101) ]
    , tables = tables1
    , relations = []
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) Size.zero Color.red [ "id" ] True False ] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.fromList [ ( "empty", Layout (CanvasProps Position.zero 0.5) [] [] (time 1202) (time 1203) ) ]
    , settings = ProjectSettings (FindPathSettings 4 [] []) [] False "" "" SqlOrder
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
          , view = False
          , columns =
                Ned.buildMap .name
                    (Column 0 "id" "int" False Nothing Nothing [])
                    [ Column 1 "name" "varchar" True Nothing Nothing [] ]
          , primaryKey = Just (PrimaryKey "users_pk" (Nel "id" []) [])
          , uniques = []
          , indexes = []
          , checks = []
          , comment = Nothing
          , origins = [ Origin src1 [ 10, 11 ] ]
          }
        , { id = ( "public", "creds" )
          , schema = "public"
          , name = "creds"
          , view = False
          , columns =
                Ned.buildMap .name
                    (Column 0 "user_id" "int" False Nothing Nothing [ Origin src1 [ 14 ] ])
                    [ Column 1 "login" "varchar" False Nothing Nothing [ Origin src1 [ 15 ] ]
                    , Column 2 "pass" "varchar" False Nothing (Just (Comment "Encrypted field" [])) [ Origin src1 [ 16 ] ]
                    , Column 3 "role" "varchar" True (Just "guest") Nothing [ Origin src1 [ 17 ] ]
                    ]
          , primaryKey = Nothing
          , uniques = [ Unique "unique_login" (Nel "login" []) "(login)" [] ]
          , indexes = [ Index "role_idx" (Nel "role" []) "(role)" [] ]
          , checks = []
          , comment = Just (Comment "To allow users to login" [])
          , origins = [ Origin src1 [ 13, 14, 15, 16, 17, 18 ] ]
          }
        ]


relations2 : List Relation
relations2 =
    [ Relation.new "creds_user_id" (ColumnRef ( "public", "creds" ) "user_id") (ColumnRef ( "public", "users" ) "id") [] ]


project2 : Project
project2 =
    { id = "prj-0"
    , name = "Project 0"
    , sources =
        [ Source src1
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
    , layout = Layout (CanvasProps (Position 1 2) 0.75) [ TableProps ( "public", "users" ) (Position 3 4) Size.zero Color.red [ "id" ] True False ] [] (time 1200) (time 1201)
    , usedLayout = Just "users"
    , layouts =
        Dict.fromList
            [ ( "empty", Layout (CanvasProps Position.zero 0.5) [] [] (time 1202) (time 1203) )
            , ( "users", Layout (CanvasProps (Position 12 32) 1.5) [ TableProps ( "public", "users" ) (Position 90 102) Size.zero Color.red [ "id", "name" ] True False ] [] (time 1202) (time 1203) )
            ]
    , settings = ProjectSettings (FindPathSettings 4 [ ( "public", "users" ) ] [ "created_by" ]) [] False "" "" SqlOrder
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
