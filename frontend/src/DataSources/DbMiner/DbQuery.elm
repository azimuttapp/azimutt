module DataSources.DbMiner.DbQuery exposing (addLimit, explore, exploreColumn, exploreTable, filterTable, findRow, incomingRows, incomingRowsLimit)

import DataSources.DbMiner.DbTypes exposing (FilterOperation, FilterOperator(..), IncomingRowsQuery, RowQuery, TableQuery)
import DataSources.DbMiner.QueryCouchbase as QueryCouchbase
import DataSources.DbMiner.QueryMariaDB as QueryMariaDB
import DataSources.DbMiner.QueryMongoDB as QueryMongoDB
import DataSources.DbMiner.QueryMySQL as QueryMySQL
import DataSources.DbMiner.QueryPostgreSQL as QueryPostgreSQL
import DataSources.DbMiner.QuerySQLServer as QuerySQLServer
import Dict exposing (Dict)
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)


explore : DatabaseKind -> TableId -> Maybe ColumnPath -> SqlQueryOrigin
explore db table column =
    column |> Maybe.map (exploreColumn db table) |> Maybe.withDefault (exploreTable db table)


exploreTable : DatabaseKind -> TableId -> SqlQueryOrigin
exploreTable db table =
    { sql =
        case db of
            DatabaseKind.Couchbase ->
                QueryCouchbase.exploreTable table

            DatabaseKind.MariaDB ->
                QueryMariaDB.exploreTable table

            DatabaseKind.MongoDB ->
                QueryMongoDB.exploreTable table

            DatabaseKind.MySQL ->
                QueryMySQL.exploreTable table

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.exploreTable table

            DatabaseKind.SQLServer ->
                QuerySQLServer.exploreTable table

            DatabaseKind.Other ->
                "Not implemented :/"
    , origin = "exploreTable"
    , db = db
    }


exploreColumn : DatabaseKind -> TableId -> ColumnPath -> SqlQueryOrigin
exploreColumn db table column =
    { sql =
        case db of
            DatabaseKind.Couchbase ->
                QueryCouchbase.exploreColumn table column

            DatabaseKind.MariaDB ->
                QueryMariaDB.exploreColumn table column

            DatabaseKind.MongoDB ->
                QueryMongoDB.exploreColumn table column

            DatabaseKind.MySQL ->
                QueryMySQL.exploreColumn table column

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.exploreColumn table column

            DatabaseKind.SQLServer ->
                QuerySQLServer.exploreColumn table column

            DatabaseKind.Other ->
                "Not implemented :/"
    , origin = "exploreColumn"
    , db = db
    }


filterTable : DatabaseKind -> TableQuery -> SqlQueryOrigin
filterTable db query =
    -- select many rows from a table with a filter
    { sql =
        case db of
            DatabaseKind.MySQL ->
                QueryMySQL.filterTable query.table query.filters

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.filterTable query.table query.filters

            _ ->
                "Not implemented :/"
    , origin = "filterTable"
    , db = db
    }


findRow : DatabaseKind -> RowQuery -> SqlQueryOrigin
findRow db query =
    -- select a single row from a table by primary key
    { sql =
        case db of
            DatabaseKind.MySQL ->
                QueryMySQL.findRow query.table query.primaryKey

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.findRow query.table query.primaryKey

            _ ->
                "Not implemented :/"
    , origin = "findRow"
    , db = db
    }


incomingRowsLimit : Int
incomingRowsLimit =
    20


incomingRows : DatabaseKind -> Dict TableId IncomingRowsQuery -> RowQuery -> SqlQueryOrigin
incomingRows db relations row =
    -- fetch rows from each relation pointing to a specific row
    { sql =
        case db of
            DatabaseKind.MySQL ->
                QueryMySQL.incomingRows row relations incomingRowsLimit

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.incomingRows row relations incomingRowsLimit

            _ ->
                "Not implemented :/"
    , origin = "incomingRows"
    , db = db
    }


addLimit : DatabaseKind -> SqlQueryOrigin -> SqlQueryOrigin
addLimit db query =
    -- limit query results to 100 if no limit specified
    case db of
        DatabaseKind.MySQL ->
            { sql = QueryMySQL.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.PostgreSQL ->
            { sql = QueryPostgreSQL.addLimit query.sql, origin = query.origin, db = query.db }

        _ ->
            query
