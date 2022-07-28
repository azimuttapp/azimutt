module PagesComponents.Projects.Id_.Components.DetailsSidebar exposing (Model, Msg(..), View(..), update, view)

import Components.Atoms.Icon as Icon
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Html exposing (Html, button, div, h2, h3, li, nav, p, span, text, ul)
import Html.Attributes exposing (class, disabled, type_)
import Html.Events exposing (onClick)
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.Project.ColumnRef exposing (ColumnRef)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)


type alias Model =
    { id : HtmlId, view : View }


type View
    = ViewList
    | ViewSchema SchemaName
    | ViewTable TableId
    | ViewColumn ColumnRef


type Msg
    = Close
    | Toggle
    | ShowList
    | ShowSchema SchemaName
    | ShowTable TableId
    | ShowColumn ColumnRef


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v }


update : Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update msg model =
    case msg of
        Close ->
            ( Nothing, Cmd.none )

        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (init ViewList |> Just), Cmd.none )

        ShowList ->
            ( init ViewList |> Just, Cmd.none )

        ShowSchema schema ->
            ( init (ViewSchema schema) |> Just, Cmd.none )

        ShowTable table ->
            ( init (ViewTable table) |> Just, Cmd.none )

        ShowColumn column ->
            ( init (ViewColumn column) |> Just, Cmd.none )


view : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> Erd -> Model -> Html msg
view wrap showTable hideTable showColumn hideColumn erd model =
    let
        tables : List ( SchemaName, List ErdTable )
        tables =
            erd.tables
                |> Dict.values
                |> List.groupBy .schema
                |> Dict.toList
                |> List.sortBy Tuple.first
                |> List.map (\( schema, schemaTables ) -> ( schema, schemaTables |> List.sortBy .name ))
    in
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
                [ case model.view of
                    ViewList ->
                        viewTableList wrap erd (erd.tables |> Dict.values)

                    ViewSchema schema ->
                        viewSchema wrap tables schema

                    ViewTable id ->
                        erd.tables |> Dict.get id |> Maybe.mapOrElse (viewTable wrap showTable hideTable erd tables) (div [] [ text "Table now found" ])

                    ViewColumn ref ->
                        erd.tables
                            |> Dict.get ref.table
                            |> Maybe.andThen (\table -> table.columns |> Dict.get ref.column |> Maybe.map (viewColumn wrap showTable hideTable showColumn hideColumn erd tables table))
                            |> Maybe.withDefault (div [] [ text "Column now found" ])
                ]
            ]
        ]


viewTableList : (Msg -> msg) -> Erd -> List ErdTable -> Html msg
viewTableList wrap erd tables =
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
                                                    [ button [ type_ "button", onClick (t.id |> ShowTable |> wrap), class "inline focus:outline-none" ]
                                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                        , p [ class "text-sm font-medium text-gray-900" ] [ text (TableId.show erd.settings.defaultSchema t.id) ]
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


viewSchema : (Msg -> msg) -> List ( SchemaName, List ErdTable ) -> SchemaName -> Html msg
viewSchema wrap tables schema =
    div []
        [ viewSchemaHeading wrap (tables |> List.map Tuple.first) schema
        , ul [ role "list", class "relative z-0 divide-y divide-gray-200" ]
            (tables
                |> List.find (\( s, _ ) -> s == schema)
                |> Maybe.mapOrElse Tuple.second []
                |> List.map
                    (\table ->
                        li []
                            [ div [ class "relative px-6 py-1 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                [ div [ class "flex-1 min-w-0" ]
                                    [ button [ type_ "button", onClick (table.id |> ShowTable |> wrap), class "focus:outline-none" ]
                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                        , p [ class "text-sm font-medium text-gray-900" ] [ text table.name ]
                                        ]
                                    ]
                                ]
                            ]
                    )
            )
        ]


viewTable : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> Erd -> List ( SchemaName, List ErdTable ) -> ErdTable -> Html msg
viewTable wrap showTable hideTable erd tables table =
    div []
        [ viewSchemaHeading wrap (tables |> List.map Tuple.first) table.schema
        , viewTableHeading wrap showTable hideTable (erd |> Erd.currentLayout) (tables |> List.find (\( s, _ ) -> s == table.schema) |> Maybe.mapOrElse Tuple.second []) table
        , ul [ role "list", class "relative z-0 divide-y divide-gray-200" ]
            (table.columns
                |> Dict.values
                |> List.map
                    (\column ->
                        li []
                            [ div [ class "relative px-6 py-1 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                [ div [ class "flex-1 min-w-0" ]
                                    [ button [ type_ "button", onClick ({ table = table.id, column = column.name } |> ShowColumn |> wrap), class "focus:outline-none" ]
                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                        , p [ class "text-sm font-medium text-gray-900" ] [ text column.name ]
                                        ]
                                    ]
                                ]
                            ]
                    )
            )
        ]


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> Erd -> List ( SchemaName, List ErdTable ) -> ErdTable -> ErdColumn -> Html msg
viewColumn wrap showTable hideTable showColumn hideColumn erd tables table column =
    let
        currentLayout : ErdLayout
        currentLayout =
            erd |> Erd.currentLayout
    in
    div []
        [ viewSchemaHeading wrap (tables |> List.map Tuple.first) table.schema
        , viewTableHeading wrap showTable hideTable currentLayout (tables |> List.find (\( s, _ ) -> s == table.schema) |> Maybe.mapOrElse Tuple.second []) table
        , viewColumnHeading wrap showColumn hideColumn currentLayout table column
        , div []
            [ div [] [ text ("Index: " ++ String.fromInt column.index) ]
            ]
        ]


viewSchemaHeading : (Msg -> msg) -> List SchemaName -> SchemaName -> Html msg
viewSchemaHeading wrap schemas schema =
    let
        index : Maybe Int
        index =
            schemas |> List.findIndex (\s -> s == schema)
    in
    div [ class "flex border-t border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ button [ type_ "button", onClick (ShowList |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
        , h3 [] [ text schema ]
        , div [ class "flex" ]
            [ (index |> Maybe.andThen (\i -> schemas |> List.get (i - 1)))
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , (index |> Maybe.andThen (\i -> schemas |> List.get (i + 1)))
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronRight "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewTableHeading : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> ErdLayout -> List ErdTable -> ErdTable -> Html msg
viewTableHeading wrap showTable hideTable currentLayout tables table =
    let
        index : Maybe Int
        index =
            tables |> List.findIndex (\t -> t.id == table.id)
    in
    div [ class "flex border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ button [ type_ "button", onClick (table.schema |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
        , h3 [] [ text table.name ]
        , div [ class "flex" ]
            [ (index |> Maybe.andThen (\i -> tables |> List.get (i - 1)))
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , (currentLayout.tables |> List.find (\t -> t.id == table.id))
                |> Maybe.map (\_ -> button [ type_ "button", onClick (hideTable table.id) ] [ Icon.solid Icon.EyeOff "" ] |> Tooltip.t "Hide table")
                |> Maybe.withDefault (button [ type_ "button", onClick (showTable table.id) ] [ Icon.solid Icon.Eye "" ] |> Tooltip.t "Show table")
            , (index |> Maybe.andThen (\i -> tables |> List.get (i + 1)))
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronRight "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewColumnHeading : (Msg -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> ErdLayout -> ErdTable -> ErdColumn -> Html msg
viewColumnHeading wrap showColumn hideColumn currentLayout table column =
    div [ class "flex border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ button [ type_ "button", onClick (table.id |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronUp "" ]
        , h3 [] [ text column.name ]
        , div [ class "flex" ]
            [ (table.columns |> Dict.find (\_ c -> c.index == column.index - 1))
                |> Maybe.map (\( _, c ) -> button [ type_ "button", onClick ({ table = table.id, column = c.name } |> ShowColumn |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , (currentLayout.tables |> List.find (\t -> t.id == table.id) |> Maybe.andThen (\t -> t.columns |> List.find (\c -> c.name == column.name)))
                |> Maybe.map (\_ -> button [ type_ "button", onClick (hideColumn { table = table.id, column = column.name }) ] [ Icon.solid Icon.EyeOff "" ] |> Tooltip.t "Hide column")
                |> Maybe.withDefault (button [ type_ "button", onClick (showColumn { table = table.id, column = column.name }) ] [ Icon.solid Icon.Eye "" ] |> Tooltip.t "Show column")
            , (table.columns |> Dict.find (\_ c -> c.index == column.index + 1))
                |> Maybe.map (\( _, c ) -> button [ type_ "button", onClick ({ table = table.id, column = c.name } |> ShowColumn |> wrap) ] [ Icon.solid Icon.ChevronRight "" ])
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]
