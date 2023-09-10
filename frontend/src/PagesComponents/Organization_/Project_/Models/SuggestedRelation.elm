module PagesComponents.Organization_.Project_.Models.SuggestedRelation exposing (SuggestedRelation, SuggestedRelationFound, SuggestedRelationRef, toFound, toRefs)

import Models.Project.ColumnPath exposing (ColumnPath)
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.TableId exposing (TableId)


type alias SuggestedRelation =
    { src : SuggestedRelationRef, ref : Maybe SuggestedRelationRef, when : Maybe { column : ColumnPath, value : ColumnValue } }


type alias SuggestedRelationFound =
    { src : SuggestedRelationRef, ref : SuggestedRelationRef, when : Maybe { column : ColumnPath, value : ColumnValue } }


type alias SuggestedRelationRef =
    { table : TableId, column : ColumnPath, kind : ColumnType }


toFound : SuggestedRelation -> Maybe SuggestedRelationFound
toFound rel =
    rel.ref |> Maybe.map (\ref -> { src = rel.src, ref = ref, when = rel.when })


toRefs : SuggestedRelationFound -> { src : ColumnRef, ref : ColumnRef }
toRefs rel =
    { src = { table = rel.src.table, column = rel.src.column }, ref = { table = rel.ref.table, column = rel.ref.column } }
