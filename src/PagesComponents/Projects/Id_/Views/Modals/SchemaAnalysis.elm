module PagesComponents.Projects.Id_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Dict exposing (Dict)
import Html exposing (Html, div, h3, h4, p, span, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (css)
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as String
import Libs.Tailwind as Tw exposing (sm)
import Models.Project.ColumnName as ColumnName
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.TableId as TableId exposing (TableId)
import Models.Project.TableName exposing (TableName)
import PagesComponents.Projects.Id_.Models exposing (Msg(..), SchemaAnalysisDialog, SchemaAnalysisMsg(..))
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)


viewSchemaAnalysis : Bool -> Dict TableId ErdTable -> SchemaAnalysisDialog -> Html Msg
viewSchemaAnalysis opened tables model =
    let
        titleId : HtmlId
        titleId =
            model.id ++ "-title"
    in
    Modal.modal { id = model.id, titleId = titleId, isOpen = opened, onBackgroundClick = ModalClose (SchemaAnalysisMsg SAClose) }
        [ viewHeader titleId
        , viewAnalysis tables
        , viewFooter
        ]


viewHeader : String -> Html msg
viewHeader titleId =
    div [ css [ "pt-6 px-6", sm [ "flex items-start" ] ] ]
        [ div [ css [ "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-primary-100", sm [ "mx-0 h-10 w-10" ] ] ]
            [ Icon.outline Beaker "text-primary-600"
            ]
        , div [ css [ "mt-3 text-center", sm [ "mt-0 ml-4 text-left" ] ] ]
            [ h3 [ id titleId, class "text-lg leading-6 font-medium text-gray-900" ] [ text "Schema analysis" ]
            , p [ class "text-sm text-gray-500" ]
                [ text "Let's find out if we can find improvements for your schema..." ]
            ]
        ]


viewAnalysis : Dict TableId ErdTable -> Html Msg
viewAnalysis tables =
    div [ class "px-6" ]
        [ viewMissingRelations tables ]


viewMissingRelations : Dict TableId ErdTable -> Html Msg
viewMissingRelations tables =
    let
        missingRels : List MissingRelation
        missingRels =
            tables |> computeMissingRelationColumns
    in
    if missingRels |> List.isEmpty then
        div [ class "mt-3" ]
            [ h4 [ class "leading-5 font-medium" ]
                [ Icon.solid Check "inline mr-3 text-green-500"
                , text "No potentially missing relation found"
                ]
            ]

    else
        div [ class "mt-3" ]
            [ h4 [ class "leading-5 font-medium" ]
                [ Icon.solid LightBulb "inline mr-3 text-yellow-500"
                , text ("Found " ++ (missingRels |> String.pluralizeL "potentially missing relation"))
                ]
            , div []
                (missingRels
                    |> List.sortBy (\rel -> ColumnRef.show rel.ref ++ " ← " ++ ColumnRef.show rel.src)
                    |> List.map
                        (\rel ->
                            div [ class "flex justify-between items-center py-1" ]
                                [ div []
                                    [ text (TableId.show rel.ref.table)
                                    , span [ class "text-gray-500" ] [ text (ColumnName.withName rel.ref.column "") ]
                                    , text " ← "
                                    , text (TableId.show rel.src.table)
                                    , span [ class "text-gray-500" ] [ text (ColumnName.withName rel.src.column "") ]
                                    ]
                                , Button.primary3 Tw.primary [ class "ml-3", onClick (CreateRelation rel.src rel.ref) ] [ text "Add relation" ]
                                ]
                        )
                )
            ]


viewFooter : Html Msg
viewFooter =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ Button.primary3 Tw.primary [ onClick (ModalClose (SchemaAnalysisMsg SAClose)) ] [ text "Close" ] ]



-- ANALYSIS


type alias MissingRelation =
    { src : ColumnRef
    , ref : ColumnRef
    }


computeMissingRelationColumns : Dict TableId ErdTable -> List MissingRelation
computeMissingRelationColumns tables =
    tables
        |> Dict.values
        |> List.concatMap
            (\t ->
                t.columns
                    |> Ned.values
                    |> Nel.toList
                    |> List.filter (\c -> (c.name |> String.toLower |> String.endsWith "_id") && (c.inRelations |> List.isEmpty) && (c.outRelations |> List.isEmpty))
                    |> List.map (\c -> { table = t.id, column = c.name })
            )
        |> List.filterMap (\src -> tables |> getRef src |> Maybe.map (\ref -> { src = src, ref = ref }))


getRef : ColumnRef -> Dict TableId ErdTable -> Maybe ColumnRef
getRef col tables =
    let
        prefix : TableName
        prefix =
            col.column |> String.toLower |> String.dropRight 3

        tableName : TableName
        tableName =
            prefix |> String.plural
    in
    tables
        |> Dict.find (\( schema, table ) _ -> (schema == Tuple.first col.table) && (String.toLower table == tableName))
        |> Maybe.andThen
            (\( _, t ) ->
                t.columns
                    |> Ned.find (\name _ -> String.toLower name == "id" || String.toLower name == (prefix ++ "_id"))
                    |> Maybe.map (\( _, c ) -> { table = t.id, column = c.name })
            )
