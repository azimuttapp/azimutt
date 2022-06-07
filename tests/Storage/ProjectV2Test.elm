module Storage.ProjectV2Test exposing (..)

import Array
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as Dict
import Libs.Models.Position as Position exposing (Position)
import Libs.Models.Size as Size
import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw
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
import Models.Project.ProjectSettings as ProjectSettings exposing (HiddenColumns, ProjectSettings)
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.Project.Unique as Unique exposing (Unique)
import Models.RelationStyle exposing (RelationStyle(..))
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
    SourceId.new "00000000-0000-0000-0000-000000000001"


project0 : Project
project0 =
    { id = "00000000-0000-0000-0000-000000000000"
    , name = "Project 0"
    , sources = [ Source src1 "source 1" (LocalFile "structure.sql" 10000 (time 1102)) Array.empty Dict.empty [] True Nothing (time 1100) (time 1101) ]
    , tables = Dict.empty
    , relations = []
    , notes = Dict.empty
    , layout = Layout (CanvasProps (Position 10 20) 0.75) [] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.empty
    , settings = ProjectSettings.init
    , storage = ProjectStorage.Browser
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project0Json : String
project0Json =
    """{"id":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":1102},"content":[],"tables":[],"relations":[],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":10,"top":20},"zoom":0.75},"tables":[],"createdAt":1200,"updatedAt":1201},"layouts":{},"createdAt":1000,"updatedAt":1001,"version":2}"""


tables1 : Dict TableId Table
tables1 =
    Dict.fromListMap .id [ Table ( "public", "users" ) "public" "users" False (Dict.fromListMap .name [ Column 0 "id" "int" False Nothing Nothing [] ]) Nothing [] [] [] Nothing [] ]


project1 : Project
project1 =
    { id = "00000000-0000-0000-0000-000000000000"
    , name = "Project 0"
    , sources = [ Source src1 "source 1" (LocalFile "structure.sql" 10000 (time 200)) Array.empty tables1 [] True (Just "basic") (time 1100) (time 1101) ]
    , tables = tables1
    , relations = []
    , notes = Dict.empty
    , layout = Layout (CanvasProps (Position 10 20) 0.75) [ TableProps ( "public", "users" ) (Position 30 40) Size.zero Tw.red [ "id" ] True False False ] [] (time 1200) (time 1201)
    , usedLayout = Nothing
    , layouts = Dict.fromList [ ( "empty", Layout (CanvasProps Position.zero 0.5) [] [] (time 1202) (time 1203) ) ]
    , settings = ProjectSettings (FindPathSettings 4 "" "") [] False "" (HiddenColumns "created_.+, updated_.+" 15 False False) OrderByProperty Bezier True False
    , storage = ProjectStorage.Browser
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project1Json : String
project1Json =
    """{"id":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":200},"content":[],"tables":[{"schema":"public","table":"users","columns":[{"name":"id","type":"int"}]}],"relations":[],"fromSample":"basic","createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":10,"top":20},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":30,"top":40},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201},"""
        ++ """"layouts":{"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4}},"createdAt":1000,"updatedAt":1001,"version":2}"""


tables2 : Dict TableId Table
tables2 =
    Dict.fromListMap .id
        [ { id = ( "public", "users" )
          , schema = "public"
          , name = "users"
          , view = False
          , columns =
                Dict.fromListMap .name
                    [ Column 0 "id" "int" False Nothing Nothing []
                    , Column 1 "name" "varchar" True Nothing Nothing []
                    ]
          , primaryKey = Just (PrimaryKey (Just "users_pk") (Nel "id" []) [])
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
                Dict.fromListMap .name
                    [ Column 0 "user_id" "int" False Nothing Nothing [ Origin src1 [ 14 ] ]
                    , Column 1 "login" "varchar" False Nothing Nothing [ Origin src1 [ 15 ] ]
                    , Column 2 "pass" "varchar" False Nothing (Just (Comment "Encrypted field" [])) [ Origin src1 [ 16 ] ]
                    , Column 3 "role" "varchar" True (Just "guest") Nothing [ Origin src1 [ 17 ] ]
                    ]
          , primaryKey = Nothing
          , uniques = [ Unique "unique_login" (Nel "login" []) (Just "(login)") [] ]
          , indexes = [ Index "role_idx" (Nel "role" []) (Just "(role)") [] ]
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
    { id = "00000000-0000-0000-0000-000000000000"
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
    , notes = Dict.empty
    , layout = Layout (CanvasProps (Position 10 20) 0.75) [ TableProps ( "public", "users" ) (Position 30 40) Size.zero Tw.red [ "id" ] True False False ] [] (time 1200) (time 1201)
    , usedLayout = Just "users"
    , layouts =
        Dict.fromList
            [ ( "empty", Layout (CanvasProps Position.zero 0.5) [] [] (time 1202) (time 1203) )
            , ( "users", Layout (CanvasProps (Position 120 320) 1.5) [ TableProps ( "public", "users" ) (Position 90 100) Size.zero Tw.red [ "id", "name" ] True False False ] [] (time 1202) (time 1203) )
            ]
    , settings = ProjectSettings (FindPathSettings 4 "users" "created_by") [] False "" (HiddenColumns "created_.+, updated_.+" 15 False False) OrderByProperty Bezier True False
    , storage = ProjectStorage.Browser
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project2Json : String
project2Json =
    """{"id":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"LocalFile","name":"structure.sql","size":10000,"modified":200},"content":["","","","","","","","","","","CREATE TABLE users","  (id int NOT NULL, name varchar);","","CREATE TABLE creds (","  user_id int NOT NULL,","  login varchar NOT NULL,","  pass varchar NOT NULL,","  role varchar",");"],"tables":["""
        ++ """{"schema":"public","table":"creds","columns":[{"name":"user_id","type":"int","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[14]}]},{"name":"login","type":"varchar","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[15]}]},{"name":"pass","type":"varchar","comment":{"text":"Encrypted field"},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[16]}]},{"name":"role","type":"varchar","nullable":true,"default":"guest","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[17]}]}],"uniques":[{"name":"unique_login","columns":["login"],"definition":"(login)"}],"indexes":[{"name":"role_idx","columns":["role"],"definition":"(role)"}],"comment":{"text":"To allow users to login"},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[13,14,15,16,17,18]}]},"""
        ++ """{"schema":"public","table":"users","columns":[{"name":"id","type":"int"},{"name":"name","type":"varchar","nullable":true}],"primaryKey":{"name":"users_pk","columns":["id"]},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[10,11]}]}],"""
        ++ """"relations":[{"name":"creds_user_id","src":{"table":"public.creds","column":"user_id"},"ref":{"table":"public.users","column":"id"}}],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layout":{"canvas":{"position":{"left":10,"top":20},"zoom":0.75},"tables":[{"id":"public.users","position":{"left":30,"top":40},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201},"""
        ++ """"usedLayout":"users","layouts":{"""
        ++ """"empty":{"canvas":{"position":{"left":0,"top":0},"zoom":0.5},"tables":[],"createdAt":1202,"updatedAt":1203},"""
        ++ """"users":{"canvas":{"position":{"left":120,"top":320},"zoom":1.5},"tables":[{"id":"public.users","position":{"left":90,"top":100},"color":"red","columns":["id","name"],"selected":true}],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4,"ignoredTables":"users","ignoredColumns":"created_by"}},"createdAt":1000,"updatedAt":1001,"version":2}"""


time : Int -> Time.Posix
time ts =
    Time.millisToPosix ts
