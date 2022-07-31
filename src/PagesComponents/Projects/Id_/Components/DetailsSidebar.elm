module PagesComponents.Projects.Id_.Components.DetailsSidebar exposing (ColumnData, Heading, Model, Msg(..), SchemaData, TableData, View(..), update, view)

import Array
import Components.Atoms.Icon as Icon
import Components.Molecules.Tooltip as Tooltip
import Conf
import Dict
import Html exposing (Html, a, aside, br, button, dd, div, dl, dt, form, h2, h3, img, input, label, li, nav, p, pre, span, text, ul)
import Html.Attributes exposing (action, alt, class, disabled, for, href, id, name, placeholder, src, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
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
import Models.Project.SourceLine exposing (SourceLine)
import Models.Project.TableId as TableId exposing (TableId)
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)
import Services.Lenses exposing (setView)


type alias Model =
    { id : HtmlId, view : View, openedCollapse : HtmlId }


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
    | ToggleCollapse HtmlId



-- INIT


init : View -> Model
init v =
    { id = Conf.ids.detailsSidebarDialog, view = v, openedCollapse = "" }



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

        ToggleCollapse id ->
            ( model |> Maybe.map (\m -> { m | openedCollapse = Bool.cond (m.openedCollapse == id) "" id }), Cmd.none )


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
                        -- viewDirectory
                        viewTableList wrap erd (erd.tables |> Dict.values)

                    SchemaView v ->
                        viewSchema wrap v

                    TableView v ->
                        viewTable wrap showTable hideTable loadLayout erd model.openedCollapse v

                    ColumnView v ->
                        viewColumn wrap showTable hideTable showColumn hideColumn loadLayout erd model.openedCollapse v
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
                                                    [ button [ type_ "button", onClick (t.id |> ShowTable |> wrap), class "focus:outline-none" ]
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


viewTable : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> TableData -> Html msg
viewTable wrap _ _ loadLayout erd openedCollapse model =
    div []
        [ viewSchemaHeading wrap model.schema
        , viewTableHeading wrap model.table
        , viewTableDetails wrap loadLayout erd openedCollapse model.table.item
        ]


viewColumn : (Msg -> msg) -> (TableId -> msg) -> (TableId -> msg) -> (ColumnRef -> msg) -> (ColumnRef -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> ColumnData -> Html msg
viewColumn wrap _ _ _ _ loadLayout erd openedCollapse model =
    div []
        [ viewSchemaHeading wrap model.schema
        , viewTableHeading wrap model.table
        , viewColumnHeading wrap model.table.item.id model.column
        , viewColumnDetails wrap loadLayout erd openedCollapse model.table.item model.column.item
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


viewTableDetails : (Msg -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> ErdTable -> Html msg
viewTableDetails wrap loadLayout erd openedCollapse table =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id table.id) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            table.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)
    in
    div [ class "px-3" ]
        [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text table.name ]
        , table.comment |> Maybe.mapOrElse viewComment (p [] [])
        , dl []
            [ inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout))) (p [] [])
            , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map (viewSource wrap openedCollapse))) (p [] [])
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


viewColumnDetails : (Msg -> msg) -> (LayoutName -> msg) -> Erd -> HtmlId -> ErdTable -> ErdColumn -> Html msg
viewColumnDetails wrap loadLayout erd openedCollapse table column =
    let
        inLayouts : List LayoutName
        inLayouts =
            erd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == table.id && (t.columns |> List.memberBy .name column.name))) |> Dict.keys

        inSources : List ( Origin, Source )
        inSources =
            column.origins |> List.filterZip (\o -> erd.sources |> List.findBy .id o.id)
    in
    div [ class "px-3" ]
        [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text (String.fromInt column.index ++ ". " ++ column.name) ]
        , p [ class "mt-1 text-sm text-gray-700" ] [ text column.kind ]
        , column.comment |> Maybe.mapOrElse viewComment (p [] [])
        , dl []
            [ column.outRelations |> List.nonEmptyMap (\r -> viewProp "References" (r |> List.map (viewRelation wrap erd.settings.defaultSchema))) (p [] [])
            , column.inRelations |> List.nonEmptyMap (\r -> viewProp "Referenced by" (r |> List.map (viewRelation wrap erd.settings.defaultSchema))) (p [] [])
            , inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout))) (p [] [])
            , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map (viewSource wrap openedCollapse))) (p [] [])
            ]
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
    div [] [ span [ class "cursor-pointer", onClick (loadLayout layout) ] [ text layout ] |> Tooltip.r "View layout" ]


viewSource : (Msg -> msg) -> HtmlId -> ( Origin, Source ) -> Html msg
viewSource wrap openedCollapse ( origin, source ) =
    div []
        [ span [ class "cursor-pointer", onClick (source.name |> ToggleCollapse |> wrap) ] [ text source.name ] |> Tooltip.r "View source content"
        , if openedCollapse == source.name then
            viewSourceContent origin source

          else
            text ""
        ]


viewRelation : (Msg -> msg) -> SchemaName -> ErdColumnRef -> Html msg
viewRelation wrap defaultSchema relation =
    div [] [ span [ class "cursor-pointer", onClick ({ table = relation.table, column = relation.column } |> ShowColumn |> wrap) ] [ text (ColumnRef.show defaultSchema relation) ] |> Tooltip.r "View column" ]


viewSourceContent : Origin -> Source -> Html msg
viewSourceContent origin source =
    if origin.id == source.id then
        let
            lines : List SourceLine
            lines =
                origin.lines |> List.filterMap (\i -> source.content |> Array.get i)
        in
        if List.isEmpty lines then
            pre [] [ text "No content from this source" ]

        else
            pre [ class "overflow-x-auto" ] [ text (lines |> String.join "\n") ]

    else
        pre [] [ text "Source didn't match with origin!" ]



-- TEST from https://tailwindui.com/components/application-ui/page-examples/detail-screens


viewDirectory : Html msg
viewDirectory =
    aside [ class "hidden xl:order-first xl:flex xl:flex-col flex-shrink-0" ]
        [ div [ class "px-6 pt-6 pb-4" ]
            [ h2 [ class "text-lg font-medium text-gray-900" ] [ text "Directory" ]
            , p [ class "mt-1 text-sm text-gray-600" ] [ text "Search directory of 3,018 employees" ]
            , form [ class "mt-6 flex space-x-4", action "#" ]
                [ div [ class "flex-1 min-w-0" ]
                    [ label [ for "search", class "sr-only" ] [ text "Search" ]
                    , div [ class "relative rounded-md shadow-sm" ]
                        [ div [ class "absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none" ] [ Icon.solid Icon.Search "text-gray-400" ]
                        , input [ type_ "search", name "search", id "search", placeholder "Search", class "focus:ring-pink-500 focus:border-pink-500 block w-full pl-10 sm:text-sm border-gray-300 rounded-md" ] []
                        ]
                    ]
                , button [ type_ "submit", class "inline-flex justify-center px-3.5 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500" ]
                    [ Icon.solid Icon.Filter "text-gray-400", span [ class "sr-only" ] [ text "Search" ] ]
                ]
            ]
        , nav [ class "flex-1 min-h-0 overflow-y-auto", ariaLabel "Directory" ]
            ([ { name = "Leslie Abbott", job = "Co-Founder / CEO", pic = "https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Hector Adams", job = "VP, Marketing", pic = "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Blake Alexander", job = "Account Coordinator", pic = "https://images.unsplash.com/photo-1520785643438-5bf77931f493?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Fabricio Andrews", job = "Senior Art Director", pic = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Angela Beaver", job = "Chief Strategy Officer", pic = "https://images.unsplash.com/photo-1501031170107-cfd33f0cbdcc?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Yvette Blanchard", job = "Studio Artist", pic = "https://images.unsplash.com/photo-1506980595904-70325b7fdd90?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Lawrence Brooks", job = "Content Specialist", pic = "https://images.unsplash.com/photo-1513910367299-bce8d8a0ebf6?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Jeffrey Clark", job = "Senior Art Director", pic = "https://images.unsplash.com/photo-1517070208541-6ddc4d3efbcb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Kathryn Cooper", job = "Associate Creative Director", pic = "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Alicia Edwards", job = "Junior Copywriter", pic = "https://images.unsplash.com/photo-1509783236416-c9ad59bae472?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Benjamin Emerson", job = "Director, Print Operations", pic = "https://images.unsplash.com/photo-1531427186611-ecfd6d936c79?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Jillian Erics", job = "Designer", pic = "https://images.unsplash.com/photo-1504703395950-b89145a5425b?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Chelsea Evans", job = "Human Resources Manager", pic = "https://images.unsplash.com/photo-1550525811-e5869dd03032?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Michael Gillard", job = "Co-Founder / CTO", pic = "https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Dries Giuessepe", job = "Manager, Business Relations", pic = "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Jenny Harrison", job = "Studio Artist", pic = "https://images.unsplash.com/photo-1507101105822-7472b28e22ac?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Lindsay Hatley", job = "Front-end Developer", pic = "https://images.unsplash.com/photo-1517841905240-472988babdf9?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Anna Hill", job = "Partner, Creative", pic = "https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Courtney Samuels", job = "Designer", pic = "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Tom Simpson", job = "Director, Product Development", pic = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Floyd Thompson", job = "Principal Designer", pic = "https://images.unsplash.com/photo-1463453091185-61582044d556?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Leonard Timmons", job = "Senior Designer", pic = "https://images.unsplash.com/photo-1519345182560-3f2917c472ef?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Whitney Trudeau", job = "Copywriter", pic = "https://images.unsplash.com/photo-1517365830460-955ce3ccd263?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Kristin Watson", job = "VP, Human Resources", pic = "https://images.unsplash.com/photo-1500917293891-ef795e70e1f6?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Emily Wilson", job = "VP, User Experience", pic = "https://images.unsplash.com/photo-1502685104226-ee32379fefbe?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             , { name = "Emma Young", job = "Senior Front-end Developer", pic = "https://images.unsplash.com/photo-1505840717430-882ce147ef2d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" }
             ]
                |> List.groupBy (\e -> e.name |> String.split " " |> List.drop 1 |> List.head |> Maybe.map (String.toUpper >> String.left 1) |> Maybe.withDefault "_")
                |> Dict.map
                    (\letter employees ->
                        div [ class "relative" ]
                            [ div [ class "z-10 sticky top-0 border-t border-b border-gray-200 bg-gray-50 px-6 py-1 text-sm font-medium text-gray-500" ] [ h3 [] [ text letter ] ]
                            , ul [ role "list", class "relative z-0 divide-y divide-gray-200" ]
                                (employees
                                    |> List.map
                                        (\employee ->
                                            li []
                                                [ div [ class "relative px-6 py-5 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-pink-500" ]
                                                    [ div [ class "flex-shrink-0" ]
                                                        [ img [ class "h-10 w-10 rounded-full", src employee.pic, alt "" ] []
                                                        ]
                                                    , div [ class "flex-1 min-w-0" ]
                                                        [ a [ href "#", class "focus:outline-none" ]
                                                            [ {- Extend touch target to entire panel -} span [ class "absolute inset-0", ariaHidden True ] []
                                                            , p [ class "text-sm font-medium text-gray-900" ] [ text employee.name ]
                                                            , p [ class "text-sm text-gray-500 truncate" ] [ text employee.job ]
                                                            ]
                                                        ]
                                                    ]
                                                ]
                                        )
                                )
                            ]
                    )
                |> Dict.values
            )
        ]
