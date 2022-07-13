module DataSources.AmlParser.AmlGenerator exposing (relation)

import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)


relation : SchemaName -> ColumnRef -> ColumnRef -> String
relation defaultSchema src ref =
    "fk " ++ ColumnRef.show defaultSchema src ++ " -> " ++ ColumnRef.show defaultSchema ref
