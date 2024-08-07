module DataSources.DbMiner.DbQuery exposing (addLimit, exploreColumn, exploreTable, filterTable, findRow, incomingRows, incomingRowsLimit, updateColumnType)

import DataSources.DbMiner.DbTypes exposing (FilterOperation, FilterOperator(..), IncomingRowsQuery, RowQuery, TableQuery)
import DataSources.DbMiner.QueryBigQuery as QueryBigQuery
import DataSources.DbMiner.QueryCouchbase as QueryCouchbase
import DataSources.DbMiner.QueryMariaDB as QueryMariaDB
import DataSources.DbMiner.QueryMongoDB as QueryMongoDB
import DataSources.DbMiner.QueryMySQL as QueryMySQL
import DataSources.DbMiner.QueryOracle as QueryOracle
import DataSources.DbMiner.QueryPostgreSQL as QueryPostgreSQL
import DataSources.DbMiner.QuerySQLServer as QuerySQLServer
import DataSources.DbMiner.QuerySnowflake as QuerySnowflake
import Dict exposing (Dict)
import Libs.Models.DatabaseKind as DatabaseKind exposing (DatabaseKind)
import Models.DbValue exposing (DbValue)
import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef, ColumnRefLike)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.TableId exposing (TableId)
import Models.SqlQuery exposing (SqlQuery, SqlQueryOrigin)


exploreTable : DatabaseKind -> TableId -> SqlQueryOrigin
exploreTable db table =
    -- query made from table details sidebar, something like: `SELECT * FROM table;`
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                QueryBigQuery.exploreTable table

            DatabaseKind.Couchbase ->
                QueryCouchbase.exploreTable table

            DatabaseKind.MariaDB ->
                QueryMariaDB.exploreTable table

            DatabaseKind.MongoDB ->
                QueryMongoDB.exploreTable table

            DatabaseKind.MySQL ->
                QueryMySQL.exploreTable table

            DatabaseKind.Oracle ->
                QueryOracle.exploreTable table

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.exploreTable table

            DatabaseKind.Snowflake ->
                QuerySnowflake.exploreTable table

            DatabaseKind.SQLServer ->
                QuerySQLServer.exploreTable table
    , origin = "exploreTable"
    , db = db
    }


exploreColumn : DatabaseKind -> TableId -> ColumnPath -> SqlQueryOrigin
exploreColumn db table column =
    -- query made from column details sidebar, something like: `SELECT col, count(*) FROM table GROUP BY col ORDER BY count(*) DESC, col;`
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                QueryBigQuery.exploreColumn table column

            DatabaseKind.Couchbase ->
                QueryCouchbase.exploreColumn table column

            DatabaseKind.MariaDB ->
                QueryMariaDB.exploreColumn table column

            DatabaseKind.MongoDB ->
                QueryMongoDB.exploreColumn table column

            DatabaseKind.MySQL ->
                QueryMySQL.exploreColumn table column

            DatabaseKind.Oracle ->
                QueryOracle.exploreColumn table column

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.exploreColumn table column

            DatabaseKind.Snowflake ->
                QuerySnowflake.exploreColumn table column

            DatabaseKind.SQLServer ->
                QuerySQLServer.exploreColumn table column
    , origin = "exploreColumn"
    , db = db
    }


filterTable : DatabaseKind -> TableQuery -> SqlQueryOrigin
filterTable db query =
    -- query made from the visual editor, something like: `SELECT * FROM table WHERE ${filters};`
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                "DbQuery.filterTable not implemented for BigQuery"

            DatabaseKind.Couchbase ->
                "DbQuery.filterTable not implemented for Couchbase"

            DatabaseKind.MariaDB ->
                QueryMariaDB.filterTable query.table query.filters

            DatabaseKind.MongoDB ->
                "DbQuery.filterTable not implemented for MongoDB"

            DatabaseKind.MySQL ->
                QueryMySQL.filterTable query.table query.filters

            DatabaseKind.Oracle ->
                QueryOracle.filterTable query.table query.filters

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.filterTable query.table query.filters

            DatabaseKind.Snowflake ->
                "DbQuery.filterTable not implemented for Snowflake"

            DatabaseKind.SQLServer ->
                QuerySQLServer.filterTable query.table query.filters
    , origin = "filterTable"
    , db = db
    }


findRow : DatabaseKind -> RowQuery -> SqlQueryOrigin
findRow db query =
    -- query made from the table rows or the row details sidebar, something like: `SELECT * FROM table WHERE ${primaryKey} = ${value} LIMIT 1;`
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                "DbQuery.findRow not implemented for BigQuery"

            DatabaseKind.Couchbase ->
                "DbQuery.findRow not implemented for Couchbase"

            DatabaseKind.MariaDB ->
                QueryMariaDB.findRow query.table query.primaryKey

            DatabaseKind.MongoDB ->
                QueryMongoDB.findRow query.table query.primaryKey

            DatabaseKind.MySQL ->
                QueryMySQL.findRow query.table query.primaryKey

            DatabaseKind.Oracle ->
                QueryOracle.findRow query.table query.primaryKey

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.findRow query.table query.primaryKey

            DatabaseKind.Snowflake ->
                "DbQuery.findRow not implemented for Snowflake"

            DatabaseKind.SQLServer ->
                QuerySQLServer.findRow query.table query.primaryKey
    , origin = "findRow"
    , db = db
    }


incomingRowsLimit : Int
incomingRowsLimit =
    20


incomingRows : DatabaseKind -> Dict TableId IncomingRowsQuery -> DbValue -> SqlQueryOrigin
incomingRows db relations value =
    -- query made from a table row to get incoming rows from every incoming relation for the specific row, something like:
    -- ```
    -- SELECT
    --   ${rels.map(rel =>
    --     `array(SELECT json('id', r.id, 'alt', r.name) FROM ${rel.table} r WHERE r.fk=${value} LIMIT 20) as ${rel.table}`
    --   ).join(', ')}
    -- LIMIT 1;
    -- ```
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                "DbQuery.incomingRows not implemented for BigQuery"

            DatabaseKind.Couchbase ->
                "DbQuery.incomingRows not implemented for Couchbase"

            DatabaseKind.MariaDB ->
                QueryMariaDB.incomingRows value relations incomingRowsLimit

            DatabaseKind.MongoDB ->
                "DbQuery.incomingRows not implemented for MongoDB"

            DatabaseKind.MySQL ->
                QueryMySQL.incomingRows value relations incomingRowsLimit

            DatabaseKind.Oracle ->
                QueryOracle.incomingRows value relations incomingRowsLimit

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.incomingRows value relations incomingRowsLimit

            DatabaseKind.Snowflake ->
                "DbQuery.incomingRows not implemented for Snowflake"

            DatabaseKind.SQLServer ->
                QuerySQLServer.incomingRows value relations incomingRowsLimit
    , origin = "incomingRows"
    , db = db
    }


addLimit : DatabaseKind -> SqlQueryOrigin -> SqlQueryOrigin
addLimit db query =
    -- allow to limit query results (to 100) if not already specified
    -- used before sending any query from Azimutt to the Gateway
    case db of
        DatabaseKind.BigQuery ->
            { sql = QueryBigQuery.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.Couchbase ->
            -- "DbQuery.addLimit not implemented for Couchbase"
            query

        DatabaseKind.MariaDB ->
            { sql = QueryMariaDB.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.MongoDB ->
            { sql = QueryMongoDB.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.MySQL ->
            { sql = QueryMySQL.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.Oracle ->
            { sql = QueryOracle.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.PostgreSQL ->
            { sql = QueryPostgreSQL.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.Snowflake ->
            { sql = QuerySnowflake.addLimit query.sql, origin = query.origin, db = query.db }

        DatabaseKind.SQLServer ->
            { sql = QuerySQLServer.addLimit query.sql, origin = query.origin, db = query.db }


updateColumnType : DatabaseKind -> ColumnRefLike x -> ColumnType -> SqlQueryOrigin
updateColumnType db ref kind =
    -- generate SQL to update column types in the db analyzer in order to make them consistent (fk pointing at a pk)
    { sql =
        case db of
            DatabaseKind.BigQuery ->
                "DbQuery.updateColumnType not implemented for BigQuery"

            DatabaseKind.Couchbase ->
                "DbQuery.updateColumnType not implemented for Couchbase"

            DatabaseKind.MariaDB ->
                QueryMariaDB.updateColumnType { table = ref.table, column = ref.column } kind

            DatabaseKind.MongoDB ->
                "DbQuery.updateColumnType not implemented for MongoDB"

            DatabaseKind.MySQL ->
                QueryMySQL.updateColumnType { table = ref.table, column = ref.column } kind

            DatabaseKind.Oracle ->
                "DbQuery.updateColumnType not implemented for Oracle"

            DatabaseKind.PostgreSQL ->
                QueryPostgreSQL.updateColumnType { table = ref.table, column = ref.column } kind

            DatabaseKind.Snowflake ->
                "DbQuery.updateColumnType not implemented for Snowflake"

            DatabaseKind.SQLServer ->
                QuerySQLServer.updateColumnType { table = ref.table, column = ref.column } kind
    , origin = "updateColumnType"
    , db = db
    }
