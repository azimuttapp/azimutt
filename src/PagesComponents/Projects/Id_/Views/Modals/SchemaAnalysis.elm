module PagesComponents.Projects.Id_.Views.Modals.SchemaAnalysis exposing (viewSchemaAnalysis)

import Components.Atoms.Button as Button
import Components.Atoms.Icon as Icon exposing (Icon(..))
import Components.Molecules.Modal as Modal
import Dict exposing (Dict)
import Html exposing (Html, div, h3, h4, h5, p, span, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (css)
import Libs.List as List
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.Regex as Regex
import Libs.String as String
import Libs.Tailwind as Tw exposing (sm)
import Models.Project.ColumnName as ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnType exposing (ColumnType)
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


viewFooter : Html Msg
viewFooter =
    div [ class "px-6 py-3 mt-3 flex items-center justify-between flex-row-reverse bg-gray-50" ]
        [ Button.primary3 Tw.primary [ onClick (ModalClose (SchemaAnalysisMsg SAClose)) ] [ text "Close" ] ]



-- MISSING RELATIONS


type alias ColumnInfo =
    { table : TableId, column : ColumnName, kind : ColumnType }


type alias MissingRelation =
    { src : ColumnInfo
    , ref : ColumnInfo
    }


type alias MissingRef =
    { src : ColumnInfo
    }


infoToRef : ColumnInfo -> ColumnRef
infoToRef info =
    { table = info.table, column = info.column }


computeMissingRelationColumns : Dict TableId ErdTable -> ( List MissingRelation, List MissingRef )
computeMissingRelationColumns tables =
    tables
        |> Dict.values
        |> List.concatMap
            (\t ->
                t.columns
                    |> Ned.values
                    |> Nel.toList
                    |> List.filter (\c -> (c.name |> String.toLower |> Regex.match "_ids?$") && not c.isPrimaryKey && (c.inRelations |> List.isEmpty) && (c.outRelations |> List.isEmpty))
                    |> List.map (\c -> { table = t.id, column = c.name, kind = c.kind })
            )
        |> List.map (\src -> ( src, tables |> getRef src ))
        |> List.partition (\( _, maybeRef ) -> maybeRef /= Nothing)
        |> Tuple.mapFirst (List.filterMap (\( src, maybeRef ) -> maybeRef |> Maybe.map (\ref -> { src = src, ref = ref })))
        |> Tuple.mapSecond (List.map (\( src, _ ) -> { src = src }))


getRef : ColumnInfo -> Dict TableId ErdTable -> Maybe ColumnInfo
getRef src tables =
    let
        words : List String
        words =
            src.column |> String.toLower |> String.split "_" |> List.dropRight 1

        prefix : TableName
        prefix =
            words |> String.join "_"

        tableNames : List TableName
        tableNames =
            [ words |> String.join "_" |> String.plural, words |> List.drop 1 |> String.join "_" |> String.plural ]
    in
    tables
        |> Dict.filter (\( schema, table ) _ -> (schema == Tuple.first src.table) && (table /= Tuple.second src.table) && (tableNames |> List.member (String.toLower table)))
        |> Dict.values
        |> List.sortBy (\t -> 0 - String.length t.name)
        |> List.head
        |> Maybe.andThen
            (\t ->
                t.columns
                    |> Ned.find (\name _ -> String.toLower name == "id" || String.toLower name == (prefix ++ "_id"))
                    |> Maybe.map (\( _, c ) -> { table = t.id, column = c.name, kind = c.kind })
            )


kindMatch : MissingRelation -> Bool
kindMatch rel =
    if (rel.src.column |> String.toLower |> String.endsWith "_ids") && (rel.src.kind |> String.endsWith "[]") then
        (rel.src.kind |> String.dropRight 2) == rel.ref.kind

    else
        rel.src.kind == rel.ref.kind


viewMissingRelations : Dict TableId ErdTable -> Html Msg
viewMissingRelations tables =
    let
        ( missingRels, missingRefs ) =
            tables |> computeMissingRelationColumns

        count : Int
        count =
            (missingRels |> List.length) + (missingRefs |> List.length)
    in
    if count == 0 then
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
                , text ("Found " ++ (count |> String.pluralize "potentially missing relation"))
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
                                , div [ class "ml-3" ]
                                    [ B.cond (kindMatch rel) (span [] []) (span [ class "text-gray-400 mr-3" ] [ Icon.solid Exclamation "inline", text (" " ++ rel.ref.kind ++ " vs " ++ rel.src.kind) ])
                                    , Button.primary3 Tw.primary [ onClick (CreateRelation (infoToRef rel.src) (infoToRef rel.ref)) ] [ text "Add relation" ]
                                    ]
                                ]
                        )
                )
            , if missingRefs |> List.isEmpty then
                div [] []

              else
                div []
                    [ h5 [ class "mt-1 font-medium" ] [ text "Some columns may need a relation, but can't find a related table:" ]
                    , div []
                        (missingRefs
                            |> List.map
                                (\rel ->
                                    div [ class "ml-3" ]
                                        [ text (TableId.show rel.src.table)
                                        , span [ class "text-gray-500" ] [ text (ColumnName.withName rel.src.column "") ]
                                        , span [ class "text-gray-400" ] [ text (" (" ++ rel.src.kind ++ ")") ]
                                        ]
                                )
                        )
                    ]
            ]



-- suggest to split tables with more than 50 columns
-- identify columns with same names but different types (bad homogeneity)
-- '_at' columns not of date type
