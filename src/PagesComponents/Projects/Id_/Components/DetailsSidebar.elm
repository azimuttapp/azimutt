module PagesComponents.Projects.Id_.Components.DetailsSidebar exposing (Model, Msg(..), update, view)

import Components.Atoms.Icon as Icon
import Conf
import Dict
import Html exposing (Html, button, div, h2, h3, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import Services.Lenses exposing (setColumn, setTable)


type alias Model =
    { id : HtmlId, table : Maybe TableId, column : Maybe ColumnName }


type Msg
    = Open (Maybe TableId) (Maybe ColumnName)
    | Close
    | Toggle
    | ViewList
    | ViewTable TableId
    | ViewColumn TableId ColumnName


init : Maybe TableId -> Maybe ColumnName -> Model
init table column =
    { id = Conf.ids.detailsSidebarDialog, table = table, column = column }


update : Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update msg model =
    case msg of
        Open table column ->
            ( init table column |> Just, Cmd.none )

        Close ->
            ( Nothing, Cmd.none )

        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (init Nothing Nothing |> Just), Cmd.none )

        ViewList ->
            ( model |> Maybe.map (setTable Nothing >> setColumn Nothing), Cmd.none )

        ViewTable table ->
            ( model |> Maybe.map (setTable (Just table) >> setColumn Nothing), Cmd.none )

        ViewColumn table column ->
            ( model |> Maybe.map (setTable (Just table) >> setColumn (Just column)), Cmd.none )


view : (Msg -> msg) -> Erd -> Model -> Html msg
view wrap erd model =
    div [ class "flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl" ]
        [ div [ class "px-4 sm:px-6" ]
            [ div [ class "flex items-start justify-between" ]
                [ h2 [ class "text-lg font-medium text-gray-900" ] [ text "Details" ]
                , div [ class "ml-3 flex h-7 items-center" ]
                    [ button [ type_ "button", onClick (wrap Close), class "rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2" ]
                        [ span [ class "sr-only" ] [ text "Close panel" ]
                        , Icon.outline Icon.X ""
                        ]
                    ]
                ]
            ]
        , div [ class "relative mt-6 flex-1 px-4 sm:px-6" ]
            [ div [ class "absolute inset-0" ]
                [ (model.table |> Maybe.andThen (\id -> erd.tables |> Dict.get id))
                    |> Maybe.map
                        (\table ->
                            (model.column |> Maybe.andThen (\name -> table.columns |> Dict.get name))
                                |> Maybe.map (viewColumn wrap table)
                                |> Maybe.withDefault (viewTable wrap table)
                        )
                    |> Maybe.withDefault (viewTableList wrap (erd.tables |> Dict.values))
                ]
            ]
        ]


viewTableList : (Msg -> msg) -> List ErdTable -> Html msg
viewTableList wrap tables =
    nav [ class "flex-1 min-h-0 overflow-y-auto", ariaLabel "Table list" ]
        (tables
            |> List.groupBy (\t -> t.name |> String.toUpper |> String.left 1)
            |> Dict.toList
            |> List.sortBy Tuple.first
            |> List.map
                (\( key, groupedTables ) ->
                    div [ class "relative" ]
                        [ div [ class "border-t border-b border-gray-200 bg-gray-50 px-6 py-1 text-sm font-medium text-gray-500" ]
                            [ h3 [] [ text key ]
                            ]
                        , ul [ role "list", class "relative z-0 divide-y divide-gray-200" ]
                            (groupedTables
                                |> List.sortBy .name
                                |> List.map
                                    (\t ->
                                        li []
                                            [ div [ class "relative px-6 py-5 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                                [ div [ class "flex-1 min-w-0" ]
                                                    [ button [ type_ "button", onClick (t.id |> ViewTable |> wrap), class "inline focus:outline-none" ]
                                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                        , p [ class "text-sm font-medium text-gray-900" ] [ text t.name ]
                                                        , p [ class "text-sm text-gray-500 truncate" ] [ text (t.columns |> String.pluralizeD "column") ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                    )
                            )
                        ]
                )
        )


viewTable : (Msg -> msg) -> ErdTable -> Html msg
viewTable wrap table =
    div []
        [ div [ class "border-t border-b border-gray-200 bg-gray-50 px-6 py-1 text-sm font-medium text-gray-500" ]
            [ h3 [] [ text table.schema ]
            ]
        , div [ class "flex border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
            [ span [ onClick (ViewList |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
            , h3 [] [ text table.name ]
            ]
        , ul [ role "list", class "relative z-0 divide-y divide-gray-200" ]
            (table.columns
                |> Dict.values
                |> List.map
                    (\column ->
                        li []
                            [ div [ class "relative px-6 py-1 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                [ div [ class "flex-1 min-w-0" ]
                                    [ button [ type_ "button", onClick (column.name |> ViewColumn table.id |> wrap), class "focus:outline-none" ]
                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                        , p [ class "text-sm font-medium text-gray-900" ] [ text column.name ]
                                        ]
                                    ]
                                ]
                            ]
                    )
            )
        ]


viewColumn : (Msg -> msg) -> ErdTable -> ErdColumn -> Html msg
viewColumn wrap table column =
    div []
        [ div [ class "border-t border-b border-gray-200 bg-gray-50 px-6 py-1 text-sm font-medium text-gray-500" ]
            [ h3 [] [ text table.schema ]
            ]
        , div [ class "flex border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
            [ span [ onClick (ViewList |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
            , h3 [] [ text table.name ]
            ]
        , div [ class "flex border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
            [ span [ onClick (table.id |> ViewTable |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
            , h3 [] [ text column.name ]
            ]
        ]
