module Storage.ProjectV2Test exposing (..)

import Array
import Dict exposing (Dict)
import Json.Decode as Decode
import Libs.Dict as Dict
import Libs.Models.Position exposing (Position)
import Libs.Models.Uuid as Uuid
import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw
import Models.ColumnOrder exposing (ColumnOrder(..))
import Models.Position as Position
import Models.Project as Project exposing (Project)
import Models.Project.CanvasProps as CanvasProps exposing (CanvasProps)
import Models.Project.Check as Check
import Models.Project.Column as Column exposing (Column)
import Models.Project.ColumnPath as ColumnPath
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Comment as Comment exposing (Comment)
import Models.Project.CustomType as CustomType
import Models.Project.FindPathSettings exposing (FindPathSettings)
import Models.Project.Index as Index exposing (Index)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.Origin as Origin exposing (Origin)
import Models.Project.PrimaryKey as PrimaryKey exposing (PrimaryKey)
import Models.Project.ProjectEncodingVersion as ProjectEncodingVersion
import Models.Project.ProjectId as ProjectId
import Models.Project.ProjectSettings as ProjectSettings exposing (HiddenColumns, ProjectSettings)
import Models.Project.ProjectStorage as ProjectStorage
import Models.Project.ProjectVisibility as ProjectVisibility
import Models.Project.Relation as Relation exposing (Relation)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceKind exposing (SourceKind(..))
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Models.Project.TableProps as TableProps exposing (TableProps)
import Models.Project.Unique as Unique exposing (Unique)
import Models.RelationStyle exposing (RelationStyle(..))
import Models.Size as Size
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
            , jsonFuzz "CustomType" ProjectFuzzers.customType CustomType.encode CustomType.decode
            , jsonFuzz "Source" ProjectFuzzers.origin Origin.encode Origin.decode
            , jsonFuzz "Layout" ProjectFuzzers.layout Layout.encode Layout.decode
            , jsonFuzz "CanvasProps" ProjectFuzzers.canvasProps CanvasProps.encode CanvasProps.decode
            , jsonFuzz "TableProps" ProjectFuzzers.tableProps TableProps.encode TableProps.decode
            , jsonFuzz "ProjectSettings" ProjectFuzzers.projectSettings (ProjectSettings.encode (ProjectSettings.init defaultSchema)) (ProjectSettings.decode (ProjectSettings.init defaultSchema))
            ]
        ]


defaultSchema : SchemaName
defaultSchema =
    "public"


src1 : SourceId
src1 =
    SourceId.new "00000000-0000-0000-0000-000000000001"


project0 : Project
project0 =
    { organization = Nothing
    , id = ProjectId.zero
    , slug = Uuid.zero
    , name = "Project 0"
    , description = Nothing
    , sources = [ Source src1 "source 1" (SqlLocalFile "structure.sql" 10000 (time 1102)) Array.empty Dict.empty [] Dict.empty True Nothing (time 1100) (time 1101) ]
    , metadata = Dict.empty
    , layouts = Dict.fromList [ ( "initial layout", Layout [] [] [] (time 1200) (time 1201) ) ]
    , settings = ProjectSettings.init defaultSchema
    , storage = ProjectStorage.Local
    , visibility = ProjectVisibility.None
    , version = ProjectEncodingVersion.current
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project0Json : String
project0Json =
    """{"id":"00000000-0000-0000-0000-000000000000","slug":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"SqlLocalFile","name":"structure.sql","size":10000,"modified":1102},"content":[],"tables":[],"relations":[],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layouts":{"initial layout":{"tables":[],"createdAt":1200,"updatedAt":1201}},"settings":{"defaultSchema":"public"},"storage":"local","visibility":"none","createdAt":1000,"updatedAt":1001,"version":2}"""


tables1 : Dict TableId Table
tables1 =
    Dict.fromListMap .id [ Table ( "public", "users" ) "public" "users" False (Dict.fromListMap .name [ Column 0 "id" "int" False Nothing Nothing Nothing [] ]) Nothing [] [] [] Nothing [] ]


project1 : Project
project1 =
    { organization = Nothing
    , id = ProjectId.zero
    , slug = Uuid.zero
    , name = "Project 0"
    , description = Nothing
    , sources = [ Source src1 "source 1" (SqlLocalFile "structure.sql" 10000 (time 200)) Array.empty tables1 [] Dict.empty True (Just "basic") (time 1100) (time 1101) ]
    , metadata = Dict.empty
    , layouts =
        Dict.fromList
            [ ( "initial layout", Layout [ TableProps ( "public", "users" ) (gridPos 30 40) Size.zeroCanvas Tw.red [ ColumnPath.fromString "id" ] True False False ] [] [] (time 1200) (time 1201) )
            , ( "empty", Layout [] [] [] (time 1202) (time 1203) )
            ]
    , settings = ProjectSettings (FindPathSettings 4 "" "") defaultSchema [] False "" (HiddenColumns "created_.+, updated_.+" 15 False False) OrderByProperty Bezier True False
    , storage = ProjectStorage.Local
    , visibility = ProjectVisibility.None
    , version = ProjectEncodingVersion.current
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project1Json : String
project1Json =
    """{"id":"00000000-0000-0000-0000-000000000000","slug":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"SqlLocalFile","name":"structure.sql","size":10000,"modified":200},"content":[],"tables":[{"schema":"public","table":"users","columns":[{"name":"id","type":"int"}]}],"relations":[],"fromSample":"basic","createdAt":1100,"updatedAt":1101}],"""
        ++ """"layouts":{"empty":{"tables":[],"createdAt":1202,"updatedAt":1203},"initial layout":{"tables":[{"id":"public.users","position":{"left":30,"top":40},"size":{"width":0,"height":0},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4},"defaultSchema":"public"},"storage":"local","visibility":"none","createdAt":1000,"updatedAt":1001,"version":2}"""


tables2 : Dict TableId Table
tables2 =
    Dict.fromListMap .id
        [ { id = ( "public", "users" )
          , schema = "public"
          , name = "users"
          , view = False
          , columns =
                Dict.fromListMap .name
                    [ Column 0 "id" "int" False Nothing Nothing Nothing []
                    , Column 1 "name" "varchar" True Nothing Nothing Nothing []
                    ]
          , primaryKey = Just (PrimaryKey (Just "users_pk") (Nel (ColumnPath.fromString "id") []) [])
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
                    [ Column 0 "user_id" "int" False Nothing Nothing Nothing [ Origin src1 [ 14 ] ]
                    , Column 1 "login" "varchar" False Nothing Nothing Nothing [ Origin src1 [ 15 ] ]
                    , Column 2 "pass" "varchar" False Nothing (Just (Comment "Encrypted field" [])) Nothing [ Origin src1 [ 16 ] ]
                    , Column 3 "role" "varchar" True (Just "guest") Nothing Nothing [ Origin src1 [ 17 ] ]
                    ]
          , primaryKey = Nothing
          , uniques = [ Unique "unique_login" (Nel (ColumnPath.fromString "login") []) (Just "(login)") [] ]
          , indexes = [ Index "role_idx" (Nel (ColumnPath.fromString "role") []) (Just "(role)") [] ]
          , checks = []
          , comment = Just (Comment "To allow users to login" [])
          , origins = [ Origin src1 [ 13, 14, 15, 16, 17, 18 ] ]
          }
        ]


relations2 : List Relation
relations2 =
    [ Relation.new "creds_user_id" (ColumnRef ( "public", "creds" ) (ColumnPath.fromString "user_id")) (ColumnRef ( "public", "users" ) (ColumnPath.fromString "id")) [] ]


project2 : Project
project2 =
    { organization = Nothing
    , id = ProjectId.zero
    , slug = Uuid.zero
    , name = "Project 0"
    , description = Nothing
    , sources =
        [ Source src1
            "source 1"
            (SqlLocalFile "structure.sql" 10000 (time 200))
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
            Dict.empty
            True
            Nothing
            (time 1100)
            (time 1101)
        ]
    , metadata = Dict.empty
    , layouts =
        Dict.fromList
            [ ( "initial layout", Layout [ TableProps ( "public", "users" ) (gridPos 30 40) Size.zeroCanvas Tw.red [ ColumnPath.fromString "id" ] True False False ] [] [] (time 1200) (time 1201) )
            , ( "empty", Layout [] [] [] (time 1202) (time 1203) )
            , ( "users", Layout [ TableProps ( "public", "users" ) (gridPos 90 100) Size.zeroCanvas Tw.red [ ColumnPath.fromString "id", ColumnPath.fromString "name" ] True False False ] [] [] (time 1202) (time 1203) )
            ]
    , settings = ProjectSettings (FindPathSettings 4 "users" "created_by") defaultSchema [] False "" (HiddenColumns "created_.+, updated_.+" 15 False False) OrderByProperty Bezier True False
    , storage = ProjectStorage.Local
    , visibility = ProjectVisibility.None
    , version = ProjectEncodingVersion.current
    , createdAt = time 1000
    , updatedAt = time 1001
    }


project2Json : String
project2Json =
    """{"id":"00000000-0000-0000-0000-000000000000","slug":"00000000-0000-0000-0000-000000000000","name":"Project 0","""
        ++ """"sources":[{"id":"00000000-0000-0000-0000-000000000001","name":"source 1","kind":{"kind":"SqlLocalFile","name":"structure.sql","size":10000,"modified":200},"content":["","","","","","","","","","","CREATE TABLE users","  (id int NOT NULL, name varchar);","","CREATE TABLE creds (","  user_id int NOT NULL,","  login varchar NOT NULL,","  pass varchar NOT NULL,","  role varchar",");"],"tables":["""
        ++ """{"schema":"public","table":"creds","columns":[{"name":"user_id","type":"int","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[14]}]},{"name":"login","type":"varchar","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[15]}]},{"name":"pass","type":"varchar","comment":{"text":"Encrypted field"},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[16]}]},{"name":"role","type":"varchar","nullable":true,"default":"guest","origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[17]}]}],"uniques":[{"name":"unique_login","columns":["login"],"definition":"(login)"}],"indexes":[{"name":"role_idx","columns":["role"],"definition":"(role)"}],"comment":{"text":"To allow users to login"},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[13,14,15,16,17,18]}]},"""
        ++ """{"schema":"public","table":"users","columns":[{"name":"id","type":"int"},{"name":"name","type":"varchar","nullable":true}],"primaryKey":{"name":"users_pk","columns":["id"]},"origins":[{"id":"00000000-0000-0000-0000-000000000001","lines":[10,11]}]}],"""
        ++ """"relations":[{"name":"creds_user_id","src":{"table":"public.creds","column":"user_id"},"ref":{"table":"public.users","column":"id"}}],"createdAt":1100,"updatedAt":1101}],"""
        ++ """"layouts":{"""
        ++ """"empty":{"tables":[],"createdAt":1202,"updatedAt":1203},"""
        ++ """"initial layout":{"tables":[{"id":"public.users","position":{"left":30,"top":40},"size":{"width":0,"height":0},"color":"red","columns":["id"],"selected":true}],"createdAt":1200,"updatedAt":1201},"""
        ++ """"users":{"tables":[{"id":"public.users","position":{"left":90,"top":100},"size":{"width":0,"height":0},"color":"red","columns":["id","name"],"selected":true}],"createdAt":1202,"updatedAt":1203}},"""
        ++ """"settings":{"findPath":{"maxPathLength":4,"ignoredTables":"users","ignoredColumns":"created_by"},"defaultSchema":"public"},"storage":"local","visibility":"none","createdAt":1000,"updatedAt":1001,"version":2}"""


gridPos : Float -> Float -> Position.Grid
gridPos x y =
    Position x y |> Position.grid


time : Int -> Time.Posix
time ts =
    Time.millisToPosix ts
