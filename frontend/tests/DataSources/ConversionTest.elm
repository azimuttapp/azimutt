module DataSources.ConversionTest exposing (..)

import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlGenerator as AmlGenerator
import DataSources.AmlMiner.AmlParser as AmlParser
import DataSources.JsonMiner.JsonAdapter as JsonAdapter
import DataSources.JsonMiner.JsonGenerator as JsonGenerator
import DataSources.JsonMiner.JsonSchema as JsonSchema
import DataSources.SqlMiner.PostgreSqlGenerator as PostgreSqlGenerator
import DataSources.SqlMiner.SqlAdapter as SqlAdapter
import DataSources.SqlMiner.SqlParser as SqlParser
import Dict exposing (Dict)
import Expect
import Json.Decode as Decode
import Libs.Dict as Dict
import Libs.Nel as Nel exposing (Nel)
import Models.Project.Column exposing (Column)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.CustomType exposing (CustomType)
import Models.Project.Relation exposing (Relation)
import Models.Project.Schema exposing (Schema)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.Table exposing (Table)
import Models.Project.TableId exposing (TableId)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "DataSourceConversion"
        [ test "parse AML" (\_ -> crmAml |> parseAml |> Expect.equal crmSource)
        , test "generate AML" (\_ -> crmSource |> AmlGenerator.generate |> Expect.equal crmAml)
        , test "parse PostgreSQL" (\_ -> crmPostgres |> parseSql |> Expect.equal crmSource)
        , test "generate PostgreSQL" (\_ -> crmSource |> PostgreSqlGenerator.generate |> Expect.equal crmPostgres)
        , test "parse JSON" (\_ -> crmJson |> parseJson |> Expect.equal crmSource)
        , test "generate JSON" (\_ -> crmSource |> JsonGenerator.generate |> Expect.equal crmJson)
        ]


crmSource : Schema
crmSource =
    { tables =
        [ { emptyTable
            | id = ( "", "contact_roles" )
            , name = "contact_roles"
            , columns =
                [ { emptyColumn | name = "contact_id", kind = "uuid" }
                , { emptyColumn | name = "role_id", kind = "uuid" }
                ]
                    |> buildColumns
            , primaryKey = Just { name = Nothing, columns = Nel "contact_id" [ "role_id" ] |> Nel.map Nel.from, origins = [] }
          }
        , { emptyTable
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
        , { emptyTable
            | id = ( "", "events" )
            , name = "events"
            , columns =
                [ { emptyColumn | name = "id", kind = "uuid" }
                , { emptyColumn | name = "contact_id", kind = "uuid", nullable = True }
                , { emptyColumn | name = "instance_name", kind = "varchar" }
                , { emptyColumn | name = "instance_id", kind = "uuid" }
                ]
                    |> buildColumns
            , primaryKey = Just { name = Nothing, columns = Nel.from "id" |> Nel.map Nel.from, origins = [] }
          }
        , { emptyTable
            | id = ( "", "roles" )
            , name = "roles"
            , columns =
                [ { emptyColumn | name = "id", kind = "uuid" }
                , { emptyColumn | name = "name", kind = "varchar" }
                ]
                    |> buildColumns
            , primaryKey = Just { name = Nothing, columns = Nel.from "id" |> Nel.map Nel.from, origins = [] }
          }
        ]
            |> buildTables
    , relations =
        [ ( "events_contact_id_fk_az", ( "", "events", "contact_id" ), ( "", "contacts", "id" ) )
        , ( "contact_roles_contact_id_fk_az", ( "", "contact_roles", "contact_id" ), ( "", "contacts", "id" ) )
        , ( "contact_roles_role_id_fk_az", ( "", "contact_roles", "role_id" ), ( "", "roles", "id" ) )
        ]
            |> List.map buildRelation
    , types = Dict.empty
    }


crmAml : String
crmAml =
    """contact_roles
  contact_id uuid pk fk contacts.id
  role_id uuid pk fk roles.id

contacts
  id uuid pk
  name varchar
  email varchar

events
  id uuid pk
  contact_id uuid nullable fk contacts.id
  instance_name varchar
  instance_id uuid

roles
  id uuid pk
  name varchar"""


crmPostgres : String
crmPostgres =
    """CREATE TABLE contact_roles (
  contact_id uuid REFERENCES contacts(id),
  role_id uuid REFERENCES roles(id),
  PRIMARY KEY (contact_id, role_id)
);

CREATE TABLE contacts (
  id uuid PRIMARY KEY,
  name varchar NOT NULL,
  email varchar NOT NULL
);

CREATE TABLE events (
  id uuid PRIMARY KEY,
  contact_id uuid REFERENCES contacts(id),
  instance_name varchar NOT NULL,
  instance_id uuid NOT NULL
);

CREATE TABLE roles (
  id uuid PRIMARY KEY,
  name varchar NOT NULL
);"""


crmJson : String
crmJson =
    """{
  "tables": [
    {
      "schema": "",
      "table": "contact_roles",
      "columns": [
        {
          "name": "contact_id",
          "type": "uuid"
        },
        {
          "name": "role_id",
          "type": "uuid"
        }
      ],
      "primaryKey": {
        "columns": [
          "contact_id",
          "role_id"
        ]
      }
    },
    {
      "schema": "",
      "table": "contacts",
      "columns": [
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "name",
          "type": "varchar"
        },
        {
          "name": "email",
          "type": "varchar"
        }
      ],
      "primaryKey": {
        "columns": [
          "id"
        ]
      }
    },
    {
      "schema": "",
      "table": "events",
      "columns": [
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "contact_id",
          "type": "uuid",
          "nullable": true
        },
        {
          "name": "instance_name",
          "type": "varchar"
        },
        {
          "name": "instance_id",
          "type": "uuid"
        }
      ],
      "primaryKey": {
        "columns": [
          "id"
        ]
      }
    },
    {
      "schema": "",
      "table": "roles",
      "columns": [
        {
          "name": "id",
          "type": "uuid"
        },
        {
          "name": "name",
          "type": "varchar"
        }
      ],
      "primaryKey": {
        "columns": [
          "id"
        ]
      }
    }
  ],
  "relations": [
    {
      "name": "events_contact_id_fk_az",
      "src": {
        "schema": "",
        "table": "events",
        "column": "contact_id"
      },
      "ref": {
        "schema": "",
        "table": "contacts",
        "column": "id"
      }
    },
    {
      "name": "contact_roles_contact_id_fk_az",
      "src": {
        "schema": "",
        "table": "contact_roles",
        "column": "contact_id"
      },
      "ref": {
        "schema": "",
        "table": "contacts",
        "column": "id"
      }
    },
    {
      "name": "contact_roles_role_id_fk_az",
      "src": {
        "schema": "",
        "table": "contact_roles",
        "column": "role_id"
      },
      "ref": {
        "schema": "",
        "table": "roles",
        "column": "id"
      }
    }
  ]
}"""


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


parseJson : String -> Schema
parseJson json =
    json
        |> Decode.decodeString JsonSchema.decode
        |> Result.withDefault { tables = [], relations = [], types = [] }
        |> JsonAdapter.buildSchema SourceId.zero
        |> (\schema -> removeOrigins { tables = schema.tables, relations = schema.relations, types = schema.types })


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
    , relations = schema.relations |> List.map (\r -> { r | origins = [] })
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


buildRelation : ( String, ( String, String, String ), ( String, String, String ) ) -> Relation
buildRelation ( name, ( srcSchema, srcTable, srcColumn ), ( refSchema, refTable, refColumn ) ) =
    { id = ( ( ( srcSchema, srcTable ), srcColumn ), ( ( refSchema, refTable ), refColumn ) )
    , name = name
    , src = { table = ( srcSchema, srcTable ), column = Nel.from srcColumn }
    , ref = { table = ( refSchema, refTable ), column = Nel.from refColumn }
    , origins = []
    }
