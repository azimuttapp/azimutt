module DataSources.DbMiner.QuerySQLServerTest exposing (..)

import DataSources.DbMiner.DbTypes exposing (FilterOperation(..), FilterOperator(..), IncomingRowsQuery, TableFilter)
import DataSources.DbMiner.QuerySQLServer exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows, updateColumnType)
import Dict
import Expect
import Libs.Nel as Nel exposing (Nel)
import Models.DbValue exposing (DbValue(..))
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "QuerySQLServer"
        [ describe "exploreTable" exploreTableSuite
        , describe "exploreColumn" exploreColumnSuite
        , describe "filterTable" filterTableSuite
        , describe "findRow" findRowSuite
        , describe "incomingRows" incomingRowsSuite
        , describe "addLimit" addLimitSuite
        , describe "updateColumnType" updateColumnTypeSuite
        ]


exploreTableSuite : List Test
exploreTableSuite =
    [ test "with schema" (\_ -> exploreTable ( "schema", "table" ) |> Expect.equal """SELECT *
FROM [schema].[table];
""")
    , test "with empty schema" (\_ -> exploreTable ( "", "table" ) |> Expect.equal """SELECT *
FROM [table];
""")
    ]


exploreColumnSuite : List Test
exploreColumnSuite =
    [ test "with schema" (\_ -> exploreColumn ( "schema", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  [column],
  count(*) AS count
FROM [schema].[table]
GROUP BY [column]
ORDER BY count DESC, [column];
""")
    , test "with empty schema" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "column") |> Expect.equal """SELECT
  [column],
  count(*) AS count
FROM [table]
GROUP BY [column]
ORDER BY count DESC, [column];
""")
    , test "with json column" (\_ -> exploreColumn ( "", "table" ) (ColumnPath.fromString "data:email") |> Expect.equal """SELECT
  JSON_VALUE([data], '$.email') AS [email],
  count(*) AS count
FROM [table]
GROUP BY JSON_VALUE([data], '$.email')
ORDER BY count DESC, [email];
""")
    ]


filterTableSuite : List Test
filterTableSuite =
    [ test "table only" (\_ -> filterTable publicUsers [] |> Expect.equal """SELECT *
FROM [public].[users];
""")
    , test "with eq filter" (\_ -> filterTable users [ filter DbAnd "id" DbEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM [users]
WHERE [id]=3;
""")
    , test "with 2 filters" (\_ -> filterTable users [ filter DbAnd "id" DbNotEqual (DbInt 3), filter DbAnd "name" DbIsNotNull (DbString "") ] |> Expect.equal """SELECT *
FROM [users]
WHERE [id]!=3 AND [name] IS NOT NULL;
""")
    , test "with json" (\_ -> filterTable users [ filter DbAnd "data:id" DbEqual (DbInt 3) ] |> Expect.equal """SELECT *
FROM [users]
WHERE JSON_VALUE([data], '$.id')=3;
""")
    ]


findRowSuite : List Test
findRowSuite =
    [ test "with id" (\_ -> fRow ( "public", "users" ) [ ( "id", DbInt 3 ) ] |> Expect.equal """SELECT TOP 1 *
FROM [public].[users]
WHERE [id]=3;
""")
    , test "composite key" (\_ -> fRow ( "", "user_roles" ) [ ( "user_id", DbInt 3 ), ( "role_id", DbString "ac1f3" ) ] |> Expect.equal """SELECT TOP 1 *
FROM [user_roles]
WHERE [user_id]=3 AND [role_id]='ac1f3';
""")
    ]


incomingRowsSuite : List Test
incomingRowsSuite =
    [ test "simple" (\_ -> incomingRows (DbInt 1) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] [] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT TOP 1
  (SELECT TOP 20 s.[id] AS 'id' FROM [events] s WHERE s.[created_by]=1 FOR JSON PATH) AS [.events];
""")
    , test "several tables & foreign keys" (\_ -> incomingRows (DbInt 1) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] [] ), ( ( "public", "organizations" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ), ( "updated_by", "int" ) ] [] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT TOP 1
  (SELECT TOP 20 s.[id] AS 'id' FROM [events] s WHERE s.[created_by]=1 FOR JSON PATH) AS [.events],
  (SELECT TOP 20 s.[id] AS 'id' FROM [public].[organizations] s WHERE s.[created_by]=1 OR s.[updated_by]=1 FOR JSON PATH) AS [public.organizations];
""")
    , test "composite pk & json" (\_ -> incomingRows (DbString "11bd9544-d56a-43d7-9065-6f1f25addf8a") ([ ( ( "", "events" ), inQuery [ ( "id", "int" ), ( "details.id", "int" ) ] [ ( "details.created_by", "uuid" ) ] [] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT TOP 1
  (SELECT TOP 20 s.[id] AS 'id', JSON_VALUE(s.[details], '$.id') AS 'details:id' FROM [events] s WHERE JSON_VALUE(s.[details], '$.created_by')='11bd9544-d56a-43d7-9065-6f1f25addf8a' FOR JSON PATH) AS [.events];
""")
    , test "with label" (\_ -> incomingRows (DbInt 1) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] [ ( "name", "varchar" ) ] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT TOP 1
  (SELECT TOP 20 s.[name] AS 'azimutt_label', s.[id] AS 'id' FROM [events] s WHERE s.[created_by]=1 FOR JSON PATH) AS [.events];
""")
    , test "with multi labels" (\_ -> incomingRows (DbInt 1) ([ ( ( "", "events" ), inQuery [ ( "id", "int" ) ] [ ( "created_by", "int" ) ] [ ( "first_name", "varchar" ), ( "last_name", "varchar" ) ] ) ] |> Dict.fromList) 20 |> Expect.equal """SELECT TOP 1
  (SELECT TOP 20 s.[first_name] + ' ' + s.[last_name] AS 'azimutt_label', s.[id] AS 'id' FROM [events] s WHERE s.[created_by]=1 FOR JSON PATH) AS [.events];
""")
    ]


addLimitSuite : List Test
addLimitSuite =
    [ test "without limit" (\_ -> addLimit "SELECT * FROM users;" |> Expect.equal "SELECT TOP 100 * FROM users;\n")
    , test "with limit" (\_ -> addLimit "SELECT TOP 10 * FROM users;" |> Expect.equal "SELECT TOP 10 * FROM users;")
    , test "with offset" (\_ -> addLimit "SELECT * FROM users OFFSET 10;" |> Expect.equal "SELECT TOP 100 * FROM users OFFSET 10;\n")
    , test "with limit & offset" (\_ -> addLimit "SELECT TOP 10 * FROM users OFFSET 10;" |> Expect.equal "SELECT TOP 10 * FROM users OFFSET 10;")
    , test "multiline" (\_ -> addLimit """SELECT e.id, e.name
FROM events e
WHERE e.name='project_loaded';  """ |> Expect.equal """SELECT TOP 100 e.id, e.name
FROM events e
WHERE e.name='project_loaded';
""")
    , test "not on update" (\_ -> addLimit "UPDATE users SET deleted=null WHERE id=10;" |> Expect.equal "UPDATE users SET deleted=null WHERE id=10;")
    , test "lowercase" (\_ -> addLimit "select * from users;" |> Expect.equal "select TOP 100 * from users;\n")
    ]


updateColumnTypeSuite : List Test
updateColumnTypeSuite =
    [ test "basic" (\_ -> updateColumnType { table = ( "", "users" ), column = cPath "name" } "varchar(255)" |> Expect.equal """ALTER TABLE [users] ALTER COLUMN [name] varchar(255);""") ]


fRow : TableId -> List ( String, DbValue ) -> String
fRow table matches =
    matches |> Nel.fromList |> Maybe.map (\primaryKey -> findRow table (primaryKey |> Nel.map (\( col, value ) -> { column = Nel col [], value = value }))) |> Maybe.withDefault ""


publicUsers : TableId
publicUsers =
    ( "public", "users" )


users : TableId
users =
    ( "", "users" )


filter : FilterOperator -> String -> FilterOperation -> DbValue -> TableFilter
filter operator path operation value =
    { operator = operator, column = ColumnPath.fromString path, operation = operation, value = value }


inQuery : List ( String, ColumnType ) -> List ( String, ColumnType ) -> List ( String, ColumnType ) -> IncomingRowsQuery
inQuery pk fks labels =
    { primaryKey = pk |> List.map (Tuple.mapFirst cPath) |> Nel.fromList |> Maybe.withDefault (Nel ( Nel "id" [], "int" ) [])
    , foreignKeys = fks |> List.map (Tuple.mapFirst cPath)
    , labelCols = labels |> List.map (Tuple.mapFirst cPath)
    }


cPath : String -> ColumnPath
cPath col =
    col |> String.split "." |> Nel.fromList |> Maybe.withDefault (Nel col [])
