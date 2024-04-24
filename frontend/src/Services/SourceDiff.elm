module Services.SourceDiff exposing (view)

import Components.Atoms.Icon exposing (Icon(..))
import Components.Molecules.Alert as Alert
import Components.Molecules.Tooltip as Tooltip
import Dict
import Html exposing (Html, div, li, span, text, ul)
import Html.Attributes exposing (class)
import Libs.Bool as B
import Libs.Html exposing (bText)
import Libs.List as List
import Libs.String as String
import Libs.Tailwind as Tw
import Models.Project.Relation exposing (Relation)
import Models.Project.RelationId as RelationId
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.Table as Table exposing (Table)
import Models.Project.TableId as TableId


view : SchemaName -> Source -> Source -> Html msg
view defaultSchema newSource oldSource =
    let
        ( removedTables, updatedTables, newTables ) =
            List.diff .id
                (oldSource.tables |> Dict.values |> List.map Table.cleanStats)
                (newSource.tables |> Dict.values |> List.map Table.cleanStats)

        ( removedRelations, updatedRelations, newRelations ) =
            List.diff .id oldSource.relations newSource.relations
    in
    if List.nonEmpty updatedTables || List.nonEmpty newTables || List.nonEmpty removedTables || List.nonEmpty updatedRelations || List.nonEmpty newRelations || List.nonEmpty removedRelations then
        div [ class "mt-3" ]
            [ Alert.withDescription { color = Tw.green, icon = CheckCircle, title = "Source parsed, here are the changes:" }
                [ ul [ class "list-disc list-inside" ]
                    ([ viewDiffItem "modified table" (updatedTables |> List.map (\( old, new ) -> ( TableId.show defaultSchema new.id, tableDiff old new )))
                     , viewDiffItem "new table" (newTables |> List.map (\t -> ( TableId.show defaultSchema t.id, Nothing )))
                     , viewDiffItem "removed table" (removedTables |> List.map (\t -> ( TableId.show defaultSchema t.id, Nothing )))
                     , viewDiffItem "modified relation" (updatedRelations |> List.map (\( old, new ) -> ( RelationId.show defaultSchema new.id, relationDiff old new )))
                     , viewDiffItem "new relation" (newRelations |> List.map (\r -> ( RelationId.show defaultSchema r.id, Nothing )))
                     , viewDiffItem "removed relation" (removedRelations |> List.map (\r -> ( RelationId.show defaultSchema r.id, Nothing )))
                     ]
                        |> List.filterMap identity
                    )
                ]
            ]

    else
        div [ class "mt-3" ]
            [ Alert.withDescription { color = Tw.green, icon = CheckCircle, title = "Source parsed" }
                [ text "There is no differences but you can still refresh the source to change the last updated date." ]
            ]


viewDiffItem : String -> List ( String, Maybe String ) -> Maybe (Html msg)
viewDiffItem label items =
    items
        |> List.head
        |> Maybe.map
            (\_ ->
                li []
                    [ bText (items |> String.pluralizeL label)
                    , text " ("
                    , span [] (items |> List.map (\( item, details ) -> text item |> Tooltip.t (details |> Maybe.withDefault "")) |> List.intersperse (text ", "))
                    , text ")"
                    ]
            )


tableDiff : Table -> Table -> Maybe String
tableDiff old new =
    let
        ( removedColumns, updatedColumns, newColumns ) =
            List.diff .name (old.columns |> Dict.values) (new.columns |> Dict.values)

        primaryKey : Bool
        primaryKey =
            old.primaryKey /= new.primaryKey

        ( removedUniques, updatedUniques, newUniques ) =
            List.diff .name old.uniques new.uniques

        ( removedIndexes, updatedIndexes, newIndexes ) =
            List.diff .name old.indexes new.indexes

        ( removedChecks, updatedChecks, newChecks ) =
            List.diff .name old.checks new.checks

        comment : Bool
        comment =
            old.comment /= new.comment
    in
    [ newColumns |> List.head |> Maybe.map (\_ -> (newColumns |> String.pluralizeL "new column") ++ ": " ++ (newColumns |> List.map .name |> String.join ", "))
    , removedColumns |> List.head |> Maybe.map (\_ -> (removedColumns |> String.pluralizeL "removed column") ++ ": " ++ (removedColumns |> List.map .name |> String.join ", "))
    , updatedColumns |> List.head |> Maybe.map (\_ -> (updatedColumns |> String.pluralizeL "updated column") ++ ": " ++ (updatedColumns |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , B.maybe primaryKey "primary key updated"
    , newUniques |> List.head |> Maybe.map (\_ -> (newUniques |> String.pluralizeL "new unique") ++ ": " ++ (newUniques |> List.map .name |> String.join ", "))
    , removedUniques |> List.head |> Maybe.map (\_ -> (removedUniques |> String.pluralizeL "removed unique") ++ ": " ++ (removedUniques |> List.map .name |> String.join ", "))
    , updatedUniques |> List.head |> Maybe.map (\_ -> (updatedUniques |> String.pluralizeL "updated unique") ++ ": " ++ (updatedUniques |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , newIndexes |> List.head |> Maybe.map (\_ -> (newIndexes |> String.pluralizeL "new index") ++ ": " ++ (newIndexes |> List.map .name |> String.join ", "))
    , removedIndexes |> List.head |> Maybe.map (\_ -> (removedIndexes |> String.pluralizeL "removed index") ++ ": " ++ (removedIndexes |> List.map .name |> String.join ", "))
    , updatedIndexes |> List.head |> Maybe.map (\_ -> (updatedIndexes |> String.pluralizeL "updated index") ++ ": " ++ (updatedIndexes |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , newChecks |> List.head |> Maybe.map (\_ -> (newChecks |> String.pluralizeL "new check") ++ ": " ++ (newChecks |> List.map .name |> String.join ", "))
    , removedChecks |> List.head |> Maybe.map (\_ -> (removedChecks |> String.pluralizeL "removed check") ++ ": " ++ (removedChecks |> List.map .name |> String.join ", "))
    , updatedChecks |> List.head |> Maybe.map (\_ -> (updatedChecks |> String.pluralizeL "updated check") ++ ": " ++ (updatedChecks |> List.map (\( c, _ ) -> c.name) |> String.join ", "))
    , B.maybe comment "comment updated"
    ]
        |> List.filterMap identity
        |> String.join ", "
        |> String.nonEmptyMaybe


relationDiff : Relation -> Relation -> Maybe String
relationDiff old new =
    let
        name : Bool
        name =
            old.name /= new.name
    in
    [ B.maybe name "name updated"
    ]
        |> List.filterMap identity
        |> String.join ", "
        |> String.nonEmptyMaybe
