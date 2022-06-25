module DataSources.AmlParser.AmlGenerator exposing (relation)

import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)


relation : ColumnRef -> ColumnRef -> String
relation src ref =
    "fk " ++ ColumnRef.show src ++ " -> " ++ ColumnRef.show ref
