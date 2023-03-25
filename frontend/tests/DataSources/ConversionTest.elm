module DataSources.ConversionTest exposing (..)

import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import DataSources.AmlMiner.AmlParser as AmlParser
import DataSources.SqlMiner.PostgreSqlGenerator as PostgreSqlGenerator
import DataSources.SqlMiner.SqlAdapter as SqlAdapter
import DataSources.SqlMiner.SqlParser as SqlParser
import Dict exposing (Dict)
import Expect
import Libs.Dict as Dict
import Libs.Nel as Nel
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.CustomTypeId exposing (CustomTypeId)
import Models.Project.Relation exposing (Relation)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


type alias Schema =
    { tables : Dict TableId Table, relations : List Relation, types : Dict CustomTypeId CustomType }


suite : Test
suite =
    describe "DataSourceConversion"
        [ test "parse AML" (\_ -> crmAml |> parseAml |> Expect.equal crmSource)
        , test "generate AML" (\_ -> crmSource |> AmlGenerator.generate |> Expect.equal crmAml)
        , test "parse PostgreSQL" (\_ -> crmPostgres |> parseSql |> Expect.equal crmSource)
        , test "generate PostgreSQL" (\_ -> crmSource |> PostgreSqlGenerator.generate |> Expect.equal crmPostgres)
        ]


crmSource : Schema
crmSource =
    { tables =
        [ { emptyTable
            | id = ( "", "contacts" )
            , name = "contacts"
            , columns =
                [ { emptyColumn | name = "id", kind = "uuid" }
                , { emptyColumn | name = "name", kind = "varchar" }
                , { emptyColumn | name = "email", kind = "varchar" }
                ]
                    |> buildColumns
            , primaryKey = Just { name = Nothing, columns = Nel.from "id" |> Nel.map Nel.from, origins = [] }
          }
        ]
            |> buildTables
    , relations = []
    , types = Dict.empty
    }


crmAml : String
crmAml =
    """contacts
  id uuid pk
  name varchar
  email varchar"""



--events
--  id uuid pk
--  contact_id uuid nullable fk contacts.id
--  instance_name varchar
--  instance_id uuid


crmPostgres : String
crmPostgres =
    """CREATE TABLE contacts (
  id uuid PRIMARY KEY,
  name varchar NOT NULL,
  email varchar NOT NULL
);"""


parseAml : String -> Schema
parseAml aml =
    aml
        |> AmlParser.parse
        |> Result.withDefault []
        |> List.foldl (\c s -> s |> AmlAdapter.evolve SourceId.zero c) AmlAdapter.initSchema
        |> (\schema -> removeOrigins { tables = schema.tables, relations = schema.relations, types = schema.types })


parseSql : String -> Schema
parseSql sql =
    sql
        |> SqlParser.parse
        |> Tuple.second
        |> List.foldl (\c s -> s |> SqlAdapter.evolve SourceId.zero ( Nel.from { index = 0, text = "" }, c )) SqlAdapter.initSchema
        |> (\schema -> removeOrigins { tables = schema.tables, relations = schema.relations, types = schema.types |> Dict.fromListMap .id })


removeOrigins : Schema -> Schema
removeOrigins schema =
    { tables =
        schema.tables
            |> Dict.map
                (\_ t ->
                    { t
                        | origins = []
                        , columns = t.columns |> Dict.map (\_ c -> { c | origins = [] })
                        , primaryKey = t.primaryKey |> Maybe.map (\pk -> { pk | origins = [] })
                    }
                )
    , relations = schema.relations
    , types = schema.types
    }


emptyTable : Table
emptyTable =
    { id = ( "", "" ), schema = "", name = "", view = False, columns = Dict.empty, primaryKey = Nothing, uniques = [], indexes = [], checks = [], comment = Nothing, origins = [] }


emptyColumn : Column
emptyColumn =
    { index = 0, name = "", kind = "", nullable = False, default = Nothing, comment = Nothing, columns = Nothing, origins = [] }


buildTables : List Table -> Dict TableId Table
buildTables tables =
    tables |> Dict.fromListMap .id


buildColumns : List Column -> Dict ColumnName Column
buildColumns columns =
    columns |> List.indexedMap (\i c -> { c | index = i }) |> Dict.fromListMap .name
