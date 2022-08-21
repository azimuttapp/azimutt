module Components.Organisms.Details exposing (DocState, Heading, SharedDocState, buildColumnHeading, buildSchemaHeading, buildTableHeading, doc, initDocState, viewColumn, viewColumn2, viewList, viewList2, viewSchema, viewSchema2, viewTable, viewTable2)

import Array exposing (Array)
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Molecules.Tooltip as Tooltip
import Conf
import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlParser as AmlParser
import Dict
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, aside, br, button, dd, div, dl, dt, form, h2, h3, img, input, label, li, nav, ol, p, pre, span, text, ul)
import Html.Attributes exposing (action, alt, class, disabled, for, href, id, name, placeholder, src, type_)
import Html.Events exposing (onClick)
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.String as String
import Libs.Tailwind exposing (TwClass)
import Libs.Time as Time
import Models.Project as Project
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.SourceId as SourceId exposing (SourceId)
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId as TableId exposing (TableId)
import Models.SourceInfo as SourceInfo
import PagesComponents.Projects.Id_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Projects.Id_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Projects.Id_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Projects.Id_.Models.ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Projects.Id_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Projects.Id_.Models.ErdTableLayout exposing (ErdTableLayout)


type alias Heading item props =
    { item : item, prev : Maybe item, next : Maybe item, shown : Maybe props }


viewList : (TableId -> msg) -> SchemaName -> List ErdTable -> Html msg
viewList goToTable defaultSchema tables =
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
                                                    [ button [ type_ "button", onClick (t.id |> goToTable), class "focus:outline-none" ]
                                                        [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                        , p [ class "text-sm font-medium text-gray-900" ] [ text (TableId.show defaultSchema t.id) ]
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


viewSchema :
    msg
    -> (SchemaName -> msg)
    -> (TableId -> msg)
    -> SchemaName
    -> Heading SchemaName Never
    -> List ErdTable
    -> Html msg
viewSchema goToList goToSchema goToTable defaultSchema schema tables =
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , div [ class "px-3" ]
            [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text (schema.item |> SchemaName.show defaultSchema) ]
            , viewProp (tables |> String.pluralizeL "table")
                [ ul [ role "list", class "-mx-3 relative z-0 divide-y divide-gray-200" ]
                    (tables
                        |> List.map
                            (\table ->
                                li []
                                    [ div [ class "relative px-6 py-1 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                        [ div [ class "flex-1 min-w-0" ]
                                            [ button [ type_ "button", onClick (table.id |> goToTable), class "focus:outline-none" ]
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
        ]


viewTable :
    msg
    -> (SchemaName -> msg)
    -> (TableId -> msg)
    -> (ColumnRef -> msg)
    -> (LayoutName -> msg)
    -> (SourceName -> msg)
    -> SourceName
    -> SchemaName
    -> Heading SchemaName Never
    -> Heading ErdTable ErdTableLayout
    -> List LayoutName
    -> List ( { o | id : SourceId, lines : List Int }, { s | id : SourceId, name : SourceName, content : Array String } )
    -> Html msg
viewTable goToList goToSchema goToTable goToColumn loadLayout toggleSource openedSource defaultSchema schema table inLayouts inSources =
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , viewTableHeading goToSchema goToTable table
        , div [ class "px-3" ]
            [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text table.item.name ]
            , table.item.comment |> Maybe.mapOrElse viewComment (p [] [])
            , dl []
                [ inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout))) (p [] [])
                , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map (viewSource toggleSource openedSource))) (p [] [])
                ]
            , viewProp (table.item.columns |> String.pluralizeD "column")
                [ ul [ role "list", class "-mx-3 relative z-0 divide-y divide-gray-200" ]
                    (table.item.columns
                        |> Dict.values
                        |> List.sortBy .index
                        |> List.map
                            (\column ->
                                li []
                                    [ div [ class "relative px-6 py-1 flex items-center space-x-3 hover:bg-gray-50 focus-within:ring-2 focus-within:ring-inset focus-within:ring-primary-500" ]
                                        [ div [ class "flex-1 min-w-0" ]
                                            [ button [ type_ "button", onClick ({ table = table.item.id, column = column.name } |> goToColumn), class "focus:outline-none" ]
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
        ]


viewColumn :
    msg
    -> (SchemaName -> msg)
    -> (TableId -> msg)
    -> (ColumnRef -> msg)
    -> (ColumnRef -> msg)
    -> (LayoutName -> msg)
    -> (SourceName -> msg)
    -> SourceName
    -> SchemaName
    -> Heading SchemaName Never
    -> Heading ErdTable ErdTableLayout
    -> Heading ErdColumn ErdColumnProps
    -> List LayoutName
    -> List ( { o | id : SourceId, lines : List Int }, { s | id : SourceId, name : SourceName, content : Array String } )
    -> Html msg
viewColumn goToList goToSchema goToTable goToColumn relationClick loadLayout toggleSource openedSource defaultSchema schema table column inLayouts inSources =
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , viewTableHeading goToSchema goToTable table
        , viewColumnHeading goToTable goToColumn table.item.id column
        , div [ class "px-3" ]
            [ h2 [ class "mt-2 font-medium text-gray-900" ] [ text (String.fromInt column.item.index ++ ". " ++ column.item.name) ]
            , p [ class "mt-1 text-sm text-gray-700" ] [ text column.item.kind ]
            , column.item.comment |> Maybe.mapOrElse viewComment (p [] [])
            , dl []
                [ column.item.outRelations |> List.nonEmptyMap (\r -> viewProp "References" (r |> List.map (viewRelation relationClick defaultSchema))) (p [] [])
                , column.item.inRelations |> List.nonEmptyMap (\r -> viewProp "Referenced by" (r |> List.map (viewRelation relationClick defaultSchema))) (p [] [])
                , inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.map (viewLayout loadLayout))) (p [] [])
                , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.map (viewSource toggleSource openedSource))) (p [] [])
                ]
            ]
        ]


viewList2 : SchemaName -> List ErdTable -> Html msg
viewList2 _ _ =
    div [] [ text "TODO viewList2" ]


viewSchema2 :
    SchemaName
    -> Heading SchemaName Never
    -> List ErdTable
    -> Html msg
viewSchema2 _ _ _ =
    div [] [ text "TODO viewSchema2" ]


viewTable2 :
    SchemaName
    -> Heading SchemaName Never
    -> Heading ErdTable ErdTableLayout
    -> Html msg
viewTable2 _ _ _ =
    div [] [ text "TODO viewTable2" ]


viewColumn2 :
    SchemaName
    -> Heading SchemaName Never
    -> Heading ErdTable ErdTableLayout
    -> Heading ErdColumn ErdColumnProps
    -> Html msg
viewColumn2 defaultSchema schema table column =
    div []
        [ div [ class "lg:flex lg:items-center lg:justify-between" ]
            [ div [ class "flex-1 min-w-0" ]
                [ breadcrumbSection ""
                    [ { url = "#", label = schema.item |> SchemaName.show defaultSchema }
                    , { url = "#", label = table.item.name }
                    ]
                , titleSection "mt-2" (String.fromInt column.item.index ++ ". " ++ table.item.name ++ "." ++ column.item.name)
                , metadataSection "mt-1"
                    [ { icon = Icon.Tag, label = column.item.kind }
                    ]
                ]
            ]
        , div [] [ text "TODO viewColumn2 details" ]
        ]



-- COMPUTATIONS


buildSchemaHeading : Erd -> SchemaName -> Heading SchemaName Never
buildSchemaHeading erd name =
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


buildTableHeading : Erd -> ErdTable -> Heading ErdTable ErdTableLayout
buildTableHeading erd table =
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


buildColumnHeading : Erd -> ErdTable -> ErdColumn -> Heading ErdColumn ErdColumnProps
buildColumnHeading erd table column =
    { item = column
    , prev = table.columns |> Dict.find (\_ c -> c.index == column.index - 1) |> Maybe.map Tuple.second
    , next = table.columns |> Dict.find (\_ c -> c.index == column.index + 1) |> Maybe.map Tuple.second
    , shown = erd |> Erd.currentLayout |> .tables |> List.findBy .id table.id |> Maybe.andThen (\t -> t.columns |> List.findBy .name column.name)
    }



-- FIRST ITERATION INTERNALS


viewSchemaHeading : msg -> (SchemaName -> msg) -> SchemaName -> Heading SchemaName Never -> Html msg
viewSchemaHeading goToList goToSchema defaultSchema model =
    div [ class "flex items-center justify-between border-t border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick goToList ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "List all tables"
            , h3 [] [ text (model.item |> SchemaName.show defaultSchema) ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> goToSchema) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl s)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\s -> button [ type_ "button", onClick (s |> goToSchema) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl s)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewTableHeading : (SchemaName -> msg) -> (TableId -> msg) -> Heading ErdTable ErdTableLayout -> Html msg
viewTableHeading goToSchema goToTable model =
    div [ class "flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick (model.item.schema |> goToSchema) ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "Schema details"
            , h3 [] [ text model.item.name ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> goToTable) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl t.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\t -> button [ type_ "button", onClick (t.id |> goToTable) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl t.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewColumnHeading : (TableId -> msg) -> (ColumnRef -> msg) -> TableId -> Heading ErdColumn ErdColumnProps -> Html msg
viewColumnHeading goToTable goToColumn table model =
    div [ class "flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
        [ div [ class "flex" ]
            [ button [ type_ "button", onClick (table |> goToTable) ] [ Icon.solid Icon.ChevronUp "" ] |> Tooltip.tr "Table details"
            , h3 [] [ text model.item.name ]
            ]
        , div [ class "flex" ]
            [ model.prev
                |> Maybe.map (\c -> button [ type_ "button", onClick ({ table = table, column = c.name } |> goToColumn) ] [ Icon.solid Icon.ChevronLeft "" ] |> Tooltip.tl c.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronLeft "" ])
            , model.next
                |> Maybe.map (\c -> button [ type_ "button", onClick ({ table = table, column = c.name } |> goToColumn) ] [ Icon.solid Icon.ChevronRight "" ] |> Tooltip.tl c.name)
                |> Maybe.withDefault (button [ type_ "button", disabled True, class "text-gray-300" ] [ Icon.solid Icon.ChevronRight "" ])
            ]
        ]


viewComment : { a | text : String } -> Html msg
viewComment comment =
    p [ class "mt-1 text-sm text-gray-700" ]
        (comment.text |> String.split "\\n" |> List.map text |> List.intersperse (br [] []))


viewProp : String -> List (Html msg) -> Html msg
viewProp label content =
    p [ class "mt-3" ]
        [ dt [ class "text-sm font-medium text-gray-500" ] [ text label ]
        , dd [ class "mt-1 text-sm text-gray-900" ] content
        ]


viewRelation : (ColumnRef -> msg) -> String -> ErdColumnRef -> Html msg
viewRelation click defaultSchema relation =
    div [] [ span [ class "cursor-pointer", onClick ({ table = relation.table, column = relation.column } |> click) ] [ text (ColumnRef.show defaultSchema relation) ] |> Tooltip.r "View column" ]


viewLayout : (LayoutName -> msg) -> LayoutName -> Html msg
viewLayout loadLayout layout =
    div [] [ span [ class "cursor-pointer", onClick (loadLayout layout) ] [ text layout ] |> Tooltip.r "View layout" ]


viewSource : (SourceName -> msg) -> SourceName -> ( { o | id : SourceId, lines : List Int }, { s | id : SourceId, name : SourceName, content : Array String } ) -> Html msg
viewSource click openedSource ( origin, source ) =
    div []
        [ span [ class "cursor-pointer", onClick (source.name |> click) ] [ text source.name ] |> Tooltip.r "View source content"
        , if openedSource == source.name then
            viewSourceContent origin source

          else
            text ""
        ]


viewSourceContent : { o | id : SourceId, lines : List Int } -> { s | id : SourceId, content : Array String } -> Html msg
viewSourceContent origin source =
    if origin.id == source.id then
        let
            lines : List String
            lines =
                origin.lines |> List.filterMap (\i -> source.content |> Array.get i)
        in
        if List.isEmpty lines then
            pre [] [ text "No content from this source" ]

        else
            pre [ class "overflow-x-auto" ] [ text (lines |> String.join "\n") ]

    else
        pre [] [ text "Source didn't match with origin!" ]



-- PAGE HEADING


pageHeading : Html msg
pageHeading =
    -- from https://tailwindui.com/components/application-ui/headings/page-headings#component-40a924bca34bb5e303d056decfa530e5
    div [ class "lg:flex lg:items-center lg:justify-between" ]
        [ div [ class "flex-1 min-w-0" ]
            [ breadcrumbSection ""
                [ { url = "#", label = "Jobs" }
                , { url = "#", label = "Engineering" }
                , { url = "#", label = "Software" }
                ]
            , titleSection "mt-2" "Back End Developer"
            , metadataSection "mt-1"
                [ { icon = Icon.Briefcase, label = "Full-time" }
                , { icon = Icon.LocationMarker, label = "Remote" }
                , { icon = Icon.CurrencyDollar, label = "$120k – $140k" }
                , { icon = Icon.Calendar, label = "Closing on January 9, 2020" }
                ]
            ]
        ]


titleSection : TwClass -> String -> Html msg
titleSection styles content =
    h2 [ css [ styles, "text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:tracking-tight sm:truncate" ] ] [ text content ]


breadcrumbSection : TwClass -> List { a | url : String, label : String } -> Html msg
breadcrumbSection styles items =
    nav [ css [ styles, "flex" ], ariaLabel "Breadcrumb" ]
        [ ol [ role "list", class "flex items-center space-x-4" ]
            (items
                |> List.indexedMap
                    (\i { url, label } ->
                        if i == 0 then
                            li []
                                [ div [ class "flex" ]
                                    [ a [ href url, class "text-sm font-medium text-gray-500 hover:text-gray-700" ] [ text label ]
                                    ]
                                ]

                        else
                            li []
                                [ div [ class "flex items-center" ]
                                    [ Icon.solid Icon.ChevronRight "flex-shrink-0 text-gray-400"
                                    , a [ href url, class "ml-4 text-sm font-medium text-gray-500 hover:text-gray-700" ] [ text label ]
                                    ]
                                ]
                    )
            )
        ]


metadataSection : TwClass -> List { a | icon : Icon, label : String } -> Html msg
metadataSection styles items =
    div [ css [ styles, "flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6" ] ]
        (items
            |> List.map
                (\{ icon, label } ->
                    div [ class "mt-2 flex items-center text-sm text-gray-500" ]
                        [ Icon.solid icon "flex-shrink-0 mr-1.5 text-gray-400", text label ]
                )
        )



-- COLUMN DIRECTOR


directory : Html msg
directory =
    -- from https://tailwindui.com/components/application-ui/page-examples/detail-screens#component-ad515de6435ba177e823a5f823a44ff5
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



-- DOCUMENTATION


type alias SharedDocState x =
    { x | detailsDocState : DocState }


type alias DocState =
    { openedCollapse : String
    , defaultSchema : SchemaName
    , currentSchema : Maybe ( Heading SchemaName Never, List ErdTable )
    , currentTable : Maybe (Heading ErdTable ErdTableLayout)
    , currentColumn : Maybe (Heading ErdColumn ErdColumnProps)
    }


initDocState : DocState
initDocState =
    { openedCollapse = ""
    , defaultSchema = "public"
    , currentSchema = Nothing
    , currentTable = Nothing
    , currentColumn = Nothing
    }
        |> selectColumn { table = ( Conf.schema.empty, "users" ), column = "name" }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Details"
        |> Chapter.renderStatefulComponentList
            [ component "viewList"
                (\s ->
                    viewList
                        (\tableId -> s |> selectTable tableId |> setState)
                        s.defaultSchema
                        (sampleErd.tables |> Dict.values)
                )
            , component "viewSchema"
                (\s ->
                    Maybe.map
                        (\( schema, tables ) ->
                            viewSchema
                                (selectList s |> setState)
                                (\schemaName -> s |> selectSchema schemaName |> setState)
                                (\tableId -> s |> selectTable tableId |> setState)
                                s.defaultSchema
                                schema
                                tables
                        )
                        s.currentSchema
                        |> Maybe.withDefault (div [] [ text "No selected schema" ])
                )
            , component "viewTable"
                (\s ->
                    Maybe.map2
                        (\( schema, _ ) table ->
                            viewTable
                                (selectList s |> setState)
                                (\schemaName -> s |> selectSchema schemaName |> setState)
                                (\tableId -> s |> selectTable tableId |> setState)
                                (\columnRef -> s |> selectColumn columnRef |> setState)
                                (\layout -> logAction ("loadLayout " ++ layout))
                                (\source -> setState { s | openedCollapse = Bool.cond (s.openedCollapse == "viewTable-" ++ source) "" ("viewTable-" ++ source) })
                                (s.openedCollapse |> String.stripLeft "viewTable-")
                                s.defaultSchema
                                schema
                                table
                                sample.inLayouts
                                sample.inSources
                        )
                        s.currentSchema
                        s.currentTable
                        |> Maybe.withDefault (div [] [ text "No selected table" ])
                )
            , component "viewColumn"
                (\s ->
                    Maybe.map3
                        (\( schema, _ ) table column ->
                            viewColumn
                                (selectList s |> setState)
                                (\schemaName -> s |> selectSchema schemaName |> setState)
                                (\tableId -> s |> selectTable tableId |> setState)
                                (\columnRef -> s |> selectColumn columnRef |> setState)
                                (\columnRef -> logAction ("relationClick " ++ (columnRef |> ColumnRef.show s.defaultSchema)))
                                (\layout -> logAction ("loadLayout " ++ layout))
                                (\source -> setState { s | openedCollapse = Bool.cond (s.openedCollapse == "viewColumn-" ++ source) "" ("viewColumn-" ++ source) })
                                (s.openedCollapse |> String.stripLeft "viewColumn-")
                                s.defaultSchema
                                schema
                                table
                                column
                                sample.inLayouts
                                sample.inSources
                        )
                        s.currentSchema
                        s.currentTable
                        s.currentColumn
                        |> Maybe.withDefault (div [] [ text "No selected column" ])
                )
            , component "viewList2"
                (\s ->
                    viewList2
                        s.defaultSchema
                        (sampleErd.tables |> Dict.values)
                )
            , component "viewSchema2"
                (\s ->
                    Maybe.map
                        (\( schema, tables ) ->
                            viewSchema2 s.defaultSchema schema tables
                        )
                        s.currentSchema
                        |> Maybe.withDefault (div [] [ text "No selected schema" ])
                )
            , component "viewTable2"
                (\s ->
                    Maybe.map2
                        (\( schema, _ ) table ->
                            viewTable2 s.defaultSchema schema table
                        )
                        s.currentSchema
                        s.currentTable
                        |> Maybe.withDefault (div [] [ text "No selected table" ])
                )
            , component "viewColumn2"
                (\s ->
                    Maybe.map3
                        (\( schema, _ ) table column ->
                            viewColumn2 s.defaultSchema schema table column
                        )
                        s.currentSchema
                        s.currentTable
                        s.currentColumn
                        |> Maybe.withDefault (div [] [ text "No selected column" ])
                )
            , component "pageHeading" (\_ -> pageHeading)
            , component "directory" (\_ -> directory)
            ]


component : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
component name render =
    ( name, \{ detailsDocState } -> render detailsDocState )


setState : DocState -> Msg (SharedDocState x)
setState state =
    Actions.updateState (\s -> { s | detailsDocState = state })


selectList : DocState -> DocState
selectList state =
    { state | currentSchema = Nothing, currentTable = Nothing, currentColumn = Nothing }


selectSchema : SchemaName -> DocState -> DocState
selectSchema schema state =
    { state
        | currentSchema = Just ( buildSchemaHeading sampleErd schema, sampleErd.tables |> Dict.values |> List.filterBy .schema schema |> List.sortBy .name )
        , currentTable = Nothing
        , currentColumn = Nothing
    }


selectTable : TableId -> DocState -> DocState
selectTable table state =
    (sampleErd.tables |> Dict.get table)
        |> Maybe.map
            (\erdTable ->
                { state
                    | currentSchema = Just ( buildSchemaHeading sampleErd erdTable.schema, sampleErd.tables |> Dict.values |> List.filterBy .schema erdTable.schema |> List.sortBy .name )
                    , currentTable = Just (buildTableHeading sampleErd erdTable)
                    , currentColumn = Nothing
                }
            )
        |> Maybe.withDefault state


selectColumn : ColumnRef -> DocState -> DocState
selectColumn { table, column } state =
    (sampleErd.tables |> Dict.get table)
        |> Maybe.andThen
            (\erdTable ->
                (erdTable.columns |> Dict.get column)
                    |> Maybe.map
                        (\erdColumn ->
                            { state
                                | currentSchema = Just ( buildSchemaHeading sampleErd erdTable.schema, sampleErd.tables |> Dict.values |> List.filterBy .schema erdTable.schema |> List.sortBy .name )
                                , currentTable = Just (buildTableHeading sampleErd erdTable)
                                , currentColumn = Just (buildColumnHeading sampleErd erdTable erdColumn)
                            }
                        )
            )
        |> Maybe.withDefault state


sample :
    { inLayouts : List SchemaName
    , inSources :
        List
            ( { id : SourceId, lines : List number }
            , { id : SourceId, name : String, content : Array String }
            )
    }
sample =
    { inLayouts = [ "Layout 1", "Layout 2" ]
    , inSources =
        [ ( { id = SourceId.new "1", lines = [ 2, 3 ] }
          , { id = SourceId.new "1", name = "structure.sql", content = Array.fromList [ "line 1", "line 2", "line 3", "line 4" ] }
          )
        ]
    }


sampleErd : Erd
sampleErd =
    """
groups
  id uuid pk

users
  id uuid pk
  name varchar unique | The name of the user
  group_id uuid nullable fk groups.id

credentials
  provider_id
  provider_key
  user_id uuid fk users.id

demo.test
  key varchar
"""
        |> AmlParser.parse
        |> AmlAdapter.buildSource (SourceInfo.aml Time.zero SourceId.zero "test")
        |> Tuple.second
        |> Project.create "project-id" "Project name"
        |> Erd.create
