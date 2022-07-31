module PagesComponents.Projects.Id_.Components.DetailsSidebar exposing (ColumnData, Heading, Model, Msg(..), SchemaData, TableData, View(..), update, view)

import Array
import Components.Atoms.Icon as Icon
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Html exposing (Html, br, button, dd, div, dl, dt, h2, h3, li, nav, p, pre, span, text, ul)
import Html.Attributes exposing (class, disabled, type_)
import Html.Events exposing (onClick)
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.String as String
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.Comment exposing (Comment)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (setView)


type alias Model =
    { id : HtmlId, view : View }


type View
    = ListView
    | SchemaView SchemaData
    | TableView TableData
    | ColumnView ColumnData


type alias SchemaData =
    { schema : Heading SchemaName Never, tables : List ErdTable }


type alias TableData =
    { schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout }


type alias ColumnData =
    { schema : Heading SchemaName Never, table : Heading ErdTable ErdTableLayout, column : Heading ErdColumn ErdColumnProps }


type alias Heading item props =
    { item : item, prev : Maybe item, next : Maybe item, shown : Maybe props }


type Msg
    = Close
    | Toggle
    | ShowList
    | ShowSchema SchemaName
    | ShowTable TableId
    | ShowColumn ColumnRef



-- INIT


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v }



-- UPDATE


update : Erd -> Msg -> Maybe Model -> ( Maybe Model, Cmd msg )
update erd msg model =
    case msg of
        Close ->
            ( Nothing, Cmd.none )

        Toggle ->
            ( model |> Maybe.mapOrElse (\_ -> Nothing) (listView |> init |> Just), Cmd.none )

        ShowList ->
            ( model |> setViewM listView, Cmd.none )

        ShowSchema schema ->
            ( model |> setViewM (schemaView erd schema), Cmd.none )

        ShowTable table ->
            ( model |> setViewM (tableView erd table), Cmd.none )

        ShowColumn column ->
            ( model |> setViewM (columnView erd column), Cmd.none )


setViewM : View -> Maybe Model -> Maybe Model
setViewM v model =
    model |> Maybe.mapOrElse (setView v) (init v) |> Just


listView : View
listView =
    ListView


schemaView : Erd -> SchemaName -> View
schemaView erd name =
    SchemaView
        { schema = schemaHeading erd name
        , tables = erd.tables |> Dict.values |> List.filterBy .schema name |> List.sortBy .name
        }


tableView : Erd -> TableId -> View
tableView erd id =
    (erd.tables |> Dict.get id)
        |> Maybe.mapOrElse
            (\table ->
                TableView
                    { schema = schemaHeading erd table.schema
                    , table = tableHeading erd table
                    }
            )
            listView


columnView : Erd -> ColumnRef -> View
columnView erd ref =
    (erd.tables |> Dict.get ref.table)
        |> Maybe.mapOrElse
            (\table ->
                (table.columns |> Dict.get ref.column)
                    |> Maybe.mapOrElse
                        (\column ->
                            ColumnView
                                { schema = schemaHeading erd table.schema
                                , table = tableHeading erd table
                                , column = columnHeading erd table column
                                }
                        )
                        (tableView erd table.id)
            )
            listView


schemaHeading : Erd -> SchemaName -> Heading SchemaName Never
schemaHeading erd name =
    let
        sortedSchemas : List SchemaName
        sortedSchemas =
            erd.tables |> Dict.values |> List.map .schema |> List.unique |> List.sort

        index : Maybe Int
        index =
            sortedSchemas |> List.findIndex (\s -> s == name)
    in
    { item = name
    , prev = index |> Maybe.andThen (\i -> sortedSchemas |> List.get (i - 1))
    , next = index |> Maybe.andThen (\i -> sortedSchemas |> List.get (i + 1))
    , shown = Nothing
    }


tableHeading : Erd -> ErdTable -> Heading ErdTable ErdTableLayout
tableHeading erd table =
    let
        sortedTables : List ErdTable
        sortedTables =
            erd.tables |> Dict.values |> List.filterBy .schema table.schema |> List.sortBy .name

        index : Maybe Int
        index =
            sortedTables |> List.findIndexBy .name table.name
    in
    { item = table
    , prev = index |> Maybe.andThen (\i -> sortedTables |> List.get (i - 1))
    , next = index |> Maybe.andThen (\i -> sortedTables |> List.get (i + 1))
    , shown = erd |> Erd.currentLayout |> .tables |> List.findBy .id table.id
    }


columnHeading : Erd -> ErdTable -> ErdColumn -> Heading ErdColumn ErdColumnProps
columnHeading erd table column =
    { item = column
    , prev = table.columns |> Dict.find (\_ c -> c.index == column.index - 1) |> Maybe.map Tuple.second
    , next = table.columns |> Dict.find (\_ c -> c.index == column.index + 1) |> Maybe.map Tuple.second
    , shown = erd |> Erd.currentLayout |> .tables |> List.findBy .id table.id |> Maybe.andThen (\t -> t.columns |> List.findBy .name column.name)
    }



-- VIEW


view : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> Model -> Html msg
view wrap showTable hideTable showColumn hideColumn loadLayout erd model =
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
                    ListView ->
                        viewTableList wrap erd (erd.tables |> Dict.values)

                    SchemaView v ->
                        viewSchema wrap v

                    TableView v ->
                        viewTable wrap showTable hideTable loadLayout erd v

                    ColumnView v ->
                        viewColumn wrap showTable hideTable showColumn hideColumn loadLayout erd v
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


viewSchema : (Msg -> msg) -> SchemaData -> Html msg
viewSchema wrap model =
    div []
        [ viewSchemaHeading wrap model.schema
        , viewSchemaDetails wrap model.schema.item model.tables
        ]


viewTable : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (LayoutName -> msg) -> Erd -> TableData -> Html msg
viewTable wrap _ _ loadLayout erd model =
    div []
        [ viewSchemaHeading wrap model.schema
        , viewTableHeading wrap model.table
        , viewTableDetails wrap loadLayout erd model.table.item
        ]


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> ColumnData -> Html msg
viewColumn wrap _ _ _ _ loadLayout erd model =
    div []
        [ viewSchemaHeading wrap model.schema
        , viewTableHeading wrap model.table
        , viewColumnHeading wrap model.table.item.id model.column
        , viewColumnDetails wrap loadLayout erd model.table.item model.column.item
        ]


viewSchemaHeading : (Msg -> msg) -> Heading SchemaName Never -> Html msg
viewSchemaHeading wrap model =
    div [ class "flex items-center justify-between border-t border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick (ShowList |> wrap) ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "List all tables"
            , h3 [] [ text model.item ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl s)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl s)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewTableHeading : (Msg -> msg) -> Heading ErdTable ErdTableLayout -> Html msg
viewTableHeading wrap model =
    div [ class "flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick (model.item.schema |> ShowSchema |> wrap) ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "Schema details"
            , h3 [] [ text model.item.name ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl t.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl t.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewColumnHeading : (Msg -> msg) -> TableId -> Heading ErdColumn ErdColumnProps -> Html msg
viewColumnHeading wrap table model =
    div [ class "flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick (table |> ShowTable |> wrap) ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "Table details"
            , h3 [] [ text model.item.name ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\c -> button [ type_ "button", onClick ({ table = table, column = c.name } |> ShowColumn |> wrap) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl c.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\c -> button [ type_ "button", onClick ({ table = table, column = c.name } |> ShowColumn |> wrap) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl c.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewSchemaDetails : (Msg -> msg) -> SchemaName -> List ErdTable -> Html msg
viewSchemaDetails wrap schema tables =
    div [ class "px-3" ]
        [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text schema ]
        , viewProp (tables |> String.pluralizeL "table")
            [ ul [ role "list", class "-mx-3 relative z-0 divide-y divide-gray-200" ]
                (tables
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
        ]


viewTableDetails : (Msg -> msg) -> (LayoutName -> msg) -> Erd -> ErdTable -> Html msg
viewTableDetails wrap loadLayout erd table =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id table.id) |> Dict.keys

        inSources : List Source
        inSources =
            table.origins |> List.filterMap (\o -> erd.sources |> List.findBy .id o.id)
    in
    div [ class "px-3" ]
        [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text table.name ]
        , table.comment |> Maybe.mapOrElse viewComment (p [] [])
        , dl []
            [ inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout) |> List.intersperse (text ", "))) (p [] [])
            , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map viewSource |> List.intersperse (text ", "))) (p [] [])
            ]
        , viewProp (table.columns |> String.pluralizeD "column")
            [ ul [ role "list", class "-mx-3 relative z-0 divide-y divide-gray-200" ]
                (table.columns
                    |> Dict.values
                    |> List.sortBy .index
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
        ]


viewColumnDetails : (Msg -> msg) -> (LayoutName -> msg) -> Erd -> ErdTable -> ErdColumn -> Html msg
viewColumnDetails wrap loadLayout erd table column =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == table.id && (t.columns |> List.memberBy .name column.name))) |> Dict.keys

        inSources : List Source
        inSources =
            column.origins |> List.filterMap (\o -> erd.sources |> List.findBy .id o.id)
    in
    div [ class "px-3" ]
        [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text (String.fromInt column.index ++ ". " ++ column.name) ]
        , p [ class "mt-1 text-sm text-gray-700" ] [ text column.kind ]
        , column.comment |> Maybe.mapOrElse viewComment (p [] [])
        , dl []
            [ column.outRelations |> List.nonEmptyMap (\r -> viewProp "References" (r |> List.map (viewRelation wrap erd.settings.defaultSchema) |> List.intersperse (br [] []))) (p [] [])
            , column.inRelations |> List.nonEmptyMap (\r -> viewProp "Referenced by" (r |> List.map (viewRelation wrap erd.settings.defaultSchema) |> List.intersperse (br [] []))) (p [] [])
            , inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout) |> List.intersperse (text ", "))) (p [] [])
            , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map viewSource |> List.intersperse (text ", "))) (p [] [])
            ]
        , div [ class "mt-3" ] (column.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id) |> List.map (\( o, s ) -> div [] [ text s.name, viewSourceContent o s ]))
        ]



-- generic components


viewComment : Comment -> Html msg
viewComment comment =
    let
        content : List (Html msg)
        content =
            comment.text |> String.split "\\n" |> List.map text |> List.intersperse (br [] [])
    in
    p [ class "mt-1 text-sm text-gray-700" ] content


viewProp : String -> List (Html msg) -> Html msg
viewProp label content =
    p [ class "mt-3" ]
        [ dt [ class "text-sm font-medium text-gray-500" ] [ text label ]
        , dd [ class "mt-1 text-sm text-gray-900" ] content
        ]


viewLayout : (LayoutName -> msg) -> LayoutName -> Html msg
viewLayout loadLayout layout =
    span [ class "link", onClick (loadLayout layout) ] [ text layout ]


viewSource : Source -> Html msg
viewSource source =
    span [] [ text source.name ]


viewRelation : (Msg -> msg) -> SchemaName -> ErdColumnRef -> Html msg
viewRelation wrap defaultSchema relation =
    span [ class "link", onClick ({ table = relation.table, column = relation.column } |> ShowColumn |> wrap) ] [ text (ColumnRef.show defaultSchema relation) ]


viewSourceContent : Origin -> Source -> Html msg
viewSourceContent origin source =
    if origin.id == source.id then
        pre [ class "overflow-x-auto" ] [ text (origin.lines |> List.filterMap (\i -> source.content |> Array.get i) |> String.join "\n") ]

    else
        pre [] [ text "Source didn't match with origin!" ]
