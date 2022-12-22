module Components.Organisms.Details exposing (DocState, Heading, NotesModel, SharedDocState, buildColumnHeading, buildSchemaHeading, buildTableHeading, doc, initDocState, viewColumn, viewColumn2, viewList, viewList2, viewSchema, viewSchema2, viewTable, viewTable2)

import Array
import Components.Atoms.Badge as Badge
import Components.Atoms.Icon as Icon exposing (Icon)
import Components.Atoms.Icons as Icons
import Components.Atoms.Markdown as Markdown
import Components.Molecules.Tooltip as Tooltip
import Conf
import DataSources.AmlMiner.AmlAdapter as AmlAdapter
import DataSources.AmlMiner.AmlParser as AmlParser
import Dict exposing (Dict)
import ElmBook exposing (Msg)
import ElmBook.Actions as Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, a, aside, button, div, form, h2, h3, i, img, input, label, li, nav, ol, p, span, text, textarea, ul)
import Html.Attributes exposing (action, alt, autofocus, class, disabled, for, href, id, name, placeholder, rows, src, title, type_, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Libs.Basics as Basics
import Libs.Bool as Bool
import Libs.Dict as Dict
import Libs.Html.Attributes exposing (ariaHidden, ariaLabel, css, role)
import Libs.List as List
import Libs.Maybe as Maybe
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Nel as Nel
import Libs.String as String
import Libs.Tailwind as Tw exposing (TwClass)
import Libs.Time as Time
import Libs.Tuple3 as Tuple3
import Models.Position as Position
import Models.Project as Project
import Models.Project.CanvasProps as CanvasProps
import Models.Project.Check exposing (Check)
import Models.Project.CheckName exposing (CheckName)
import Models.Project.ColumnId exposing (ColumnId)
import Models.Project.ColumnName exposing (ColumnName)
import Models.Project.ColumnRef as ColumnRef exposing (ColumnRef)
import Models.Project.ColumnStats exposing (ColumnStats, ColumnValueCount)
import Models.Project.ColumnValue exposing (ColumnValue)
import Models.Project.Index exposing (Index)
import Models.Project.IndexName exposing (IndexName)
import Models.Project.LayoutName exposing (LayoutName)
import Models.Project.Origin exposing (Origin)
import Models.Project.PrimaryKey exposing (PrimaryKey)
import Models.Project.SchemaName as SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.SourceId as SourceId exposing (SourceIdStr)
import Models.Project.SourceKind as SourceKind
import Models.Project.SourceName exposing (SourceName)
import Models.Project.TableId as TableId exposing (TableId, TableIdStr)
import Models.Project.TableStats exposing (TableStats)
import Models.Project.Unique exposing (Unique)
import Models.Project.UniqueName exposing (UniqueName)
import Models.Size as Size
import Models.SourceInfo as SourceInfo
import PagesComponents.Organization_.Project_.Models.Erd as Erd exposing (Erd)
import PagesComponents.Organization_.Project_.Models.ErdColumn exposing (ErdColumn)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps exposing (ErdColumnProps)
import PagesComponents.Organization_.Project_.Models.ErdColumnRef as ErdColumnRef exposing (ErdColumnRef)
import PagesComponents.Organization_.Project_.Models.ErdLayout exposing (ErdLayout)
import PagesComponents.Organization_.Project_.Models.ErdTable exposing (ErdTable)
import PagesComponents.Organization_.Project_.Models.ErdTableLayout exposing (ErdTableLayout)
import PagesComponents.Organization_.Project_.Models.ErdTableProps exposing (ErdTableProps)
import PagesComponents.Organization_.Project_.Models.Notes exposing (Notes)
import Services.Lenses exposing (setLayouts)
import Simple.Fuzzy
import Time exposing (Posix)


type alias Heading item props =
    { item : item, prev : Maybe item, next : Maybe item, shown : Maybe props }


viewList : (TableId -> msg) -> (String -> msg) -> HtmlId -> SchemaName -> List ErdTable -> String -> Html msg
viewList goToTable updateSearch htmlId defaultSchema tables search =
    let
        searchId : HtmlId
        searchId =
            htmlId ++ "-search"
    in
    div []
        [ div [ class "px-6" ]
            [ form []
                [ div [ class "flex-1 min-w-0" ]
                    [ label [ for searchId, class "sr-only" ] [ text "Search" ]
                    , div [ class "relative rounded-md shadow-sm" ]
                        [ div [ class "absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none" ] [ Icon.solid Icon.Search "text-gray-400" ]
                        , input [ type_ "search", name searchId, id searchId, value search, onInput updateSearch, placeholder "Search", class "block w-full pl-10 sm:text-sm border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500" ] []
                        ]
                    ]
                ]
            ]
        , nav [ class "mt-3 flex-1 min-h-0 overflow-y-auto", ariaLabel "Table list" ]
            (tables
                |> List.filter (\t -> t.id |> TableId.show defaultSchema |> Simple.Fuzzy.match search)
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
                                                        [ button [ type_ "button", onClick (t.id |> goToTable), class "text-left focus:outline-none" ]
                                                            [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                            , p [ class "text-sm text-gray-900 font-medium" ] [ text (TableId.show defaultSchema t.id) ]
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
        ]


viewSchema : msg -> (SchemaName -> msg) -> (TableId -> msg) -> SchemaName -> Heading SchemaName Never -> List ErdTable -> Html msg
viewSchema goToList goToSchema goToTable defaultSchema schema tables =
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , div [ class "px-3" ]
            [ viewTitle (schema.item |> SchemaName.show defaultSchema)
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
    -> NotesModel msg
    -> List LayoutName
    -> List ( Origin, Source )
    -> Dict SourceIdStr TableStats
    -> Html msg
viewTable goToList goToSchema goToTable goToColumn loadLayout _ _ defaultSchema schema table notes inLayouts inSources stats =
    let
        columnValues : Dict ColumnName ColumnValue
        columnValues =
            stats |> Dict.toList |> List.foldl (\( _, s ) acc -> acc |> Dict.union s.sampleValues) Dict.empty

        outRelations : List ErdColumnRef
        outRelations =
            table.item.columns |> Dict.values |> List.concatMap .outRelations |> List.uniqueBy .table

        inRelations : List ErdColumnRef
        inRelations =
            table.item.columns |> Dict.values |> List.concatMap .inRelations |> List.uniqueBy .table
    in
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , viewTableHeading goToSchema goToTable table
        , div [ class "px-3" ]
            [ viewTitle table.item.name
            , table.item.comment |> Maybe.mapOrElse viewComment (div [] [])
            , viewNotes notes
            , outRelations |> List.nonEmptyMap (\r -> viewProp "References" (r |> List.sortBy .table |> List.map (viewTableRelation goToTable defaultSchema))) (div [] [])
            , inRelations |> List.nonEmptyMap (\r -> viewProp "Referenced by" (r |> List.sortBy .table |> List.map (viewTableRelation goToTable defaultSchema))) (div [] [])
            , viewTableConstraints table.item
            , inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.sort |> List.map (viewLayout loadLayout))) (div [] [])
            , inSources |> List.nonEmptyMap (\sources -> viewProp "From sources" (sources |> List.sortBy (Tuple.second >> .name) |> List.map (\( o, s ) -> viewSource (stats |> Dict.get (SourceId.toString s.id) |> Maybe.map .rows) ( o, s )))) (div [] [])
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
                                            [ button [ type_ "button", onClick ({ table = table.item.id, column = column.name } |> goToColumn), class "w-full focus:outline-none" ]
                                                [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                , div [ class "flex justify-between" ]
                                                    [ span [ class "text-sm font-medium text-gray-900" ] [ text column.name ]
                                                    , columnValues |> Dict.get column.name |> Maybe.mapOrElse (\v -> Badge.basic Tw.gray [ class "ml-3 truncate" ] [ text v ]) (span [] [])
                                                    ]
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
    -> (LayoutName -> msg)
    -> (SourceName -> msg)
    -> SourceName
    -> SchemaName
    -> Heading SchemaName Never
    -> Heading ErdTable ErdTableLayout
    -> Heading ErdColumn ErdColumnProps
    -> NotesModel msg
    -> List LayoutName
    -> List ( Origin, Source )
    -> Dict SourceIdStr ColumnStats
    -> Html msg
viewColumn goToList goToSchema goToTable goToColumn loadLayout _ _ defaultSchema schema table column notes inLayouts inSources stats =
    div []
        [ viewSchemaHeading goToList goToSchema defaultSchema schema
        , viewTableHeading goToSchema goToTable table
        , viewColumnHeading goToTable goToColumn table.item.id column
        , div [ class "px-3" ]
            [ viewTitle (String.fromInt column.item.index ++ ". " ++ column.item.name)
            , div [ class "flex flex-row flex-wrap" ]
                ([ Just ( Icon.Tag, column.item.kind )
                 , Just (Bool.cond column.item.nullable ( Icon.ShieldExclamation, "Nullable" ) ( Icon.ShieldCheck, "NOT NULL" ))
                 , column.item.default |> Maybe.map (\v -> ( Icon.PlusCircle, "Default: " ++ v ))
                 ]
                    |> List.filterMap identity
                    |> List.map
                        (\( icon, content ) ->
                            div [ class "mt-1 mr-3 flex flex-shrink-0 items-center text-sm text-gray-500" ] [ Icon.solid icon "text-gray-400 mr-1", text content ]
                        )
                )
            , column.item.comment |> Maybe.mapOrElse viewComment (div [] [])
            , viewNotes notes
            , viewColumnStats (inSources |> List.map Tuple.second) stats
            , column.item.outRelations |> List.nonEmptyMap (\r -> viewProp "References" (r |> List.sortBy ErdColumnRef.toId |> List.map (viewColumnRelation goToColumn defaultSchema))) (div [] [])
            , column.item.inRelations |> List.nonEmptyMap (\r -> viewProp "Referenced by" (r |> List.sortBy ErdColumnRef.toId |> List.map (viewColumnRelation goToColumn defaultSchema))) (div [] [])
            , viewColumnConstraints table.item column.item
            , inLayouts |> List.nonEmptyMap (\l -> viewProp "In layouts" (l |> List.sort |> List.map (viewLayout loadLayout))) (div [] [])
            , inSources |> List.nonEmptyMap (\s -> viewProp "From sources" (s |> List.sortBy (Tuple.second >> .name) |> List.map (viewSource Nothing))) (div [] [])
            ]
        ]


viewList2 : (TableId -> msg) -> (String -> msg) -> HtmlId -> SchemaName -> List ErdTable -> String -> Html msg
viewList2 _ _ _ _ _ _ =
    div [] [ text "TODO viewList2" ]


viewSchema2 : msg -> (SchemaName -> msg) -> (TableId -> msg) -> SchemaName -> Heading SchemaName Never -> List ErdTable -> Html msg
viewSchema2 _ _ _ _ _ _ =
    div [] [ text "TODO viewSchema2" ]


viewTable2 :
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
    -> NotesModel msg
    -> List LayoutName
    -> List ( Origin, Source )
    -> Dict SourceIdStr TableStats
    -> Html msg
viewTable2 _ _ _ _ _ _ _ _ _ _ _ _ _ _ =
    div [] [ text "TODO viewTable2" ]


viewColumn2 :
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
    -> Heading ErdColumn ErdColumnProps
    -> NotesModel msg
    -> List LayoutName
    -> List ( Origin, Source )
    -> Dict SourceIdStr ColumnStats
    -> Html msg
viewColumn2 _ _ _ _ _ _ _ defaultSchema schema table column _ _ _ _ =
    div []
        [ div [ class "lg:flex lg:items-center lg:justify-between" ]
            [ div [ class "flex-1 min-w-0" ]
                [ breadcrumbSection ""
                    [ { url = "#", label = schema.item |> SchemaName.show defaultSchema }
                    , { url = "#", label = table.item.name }
                    ]
                , h2 [ css [ "mt-2 text-gray-900 text-2xl font-bold tracking-tight truncate" ] ]
                    [ text (String.fromInt column.item.index ++ ". " ++ table.item.name ++ "." ++ column.item.name)
                    ]
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
    div [ class "pl-4 flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
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
    div [ class "pl-7 flex items-center justify-between border-b border-gray-200 bg-gray-50 px-1 py-1 text-sm font-medium text-gray-500" ]
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


viewTitle : String -> Html msg
viewTitle content =
    h2 [ class "mt-2 text-xl font-bold text-gray-900" ] [ text content ]


viewComment : { a | text : String } -> Html msg
viewComment comment =
    div [ class "mt-1 flex flex-row" ]
        [ Icon.outline Icons.comment "w-4 opacity-50 mr-1" |> Tooltip.r "SQL comment"
        , viewMarkdown comment.text
        ]


type alias NotesModel msg =
    { notes : Maybe Notes
    , editing : Bool
    , toggleEdit : HtmlId -> msg
    , update : Notes -> msg
    }


viewNotes : NotesModel msg -> Html msg
viewNotes model =
    let
        inputId : HtmlId
        inputId =
            "edit-notes"
    in
    div [ class "mt-1 flex flex-row" ]
        [ Icon.outline Icons.notes "w-4 opacity-50 mr-1" |> Tooltip.r "Azimutt notes"
        , if model.editing then
            textarea
                [ id inputId
                , name inputId
                , rows (model.notes |> Maybe.withDefault "" |> String.split "\n" |> List.length)
                , value (model.notes |> Maybe.withDefault "")
                , onInput model.update
                , onBlur (model.toggleEdit inputId)
                , autofocus True
                , placeholder "Write your notes..."
                , class "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                ]
                []

          else
            model.notes
                |> Maybe.mapOrElse (\n -> div [ onClick (model.toggleEdit inputId), class "w-full cursor-pointer" ] [ viewMarkdown n ])
                    (div [ onClick (model.toggleEdit inputId), class "w-full text-sm text-gray-400 italic underline cursor-pointer" ] [ text "Click to write notes" ])
        ]


viewMarkdown : String -> Html msg
viewMarkdown content =
    Markdown.markdown "-mt-1 prose prose-sm leading-tight prose-p:my-2 prose-p:last:mb-0 prose-ul:my-2 prose-li:my-0" content


viewColumnStats : List Source -> Dict SourceIdStr ColumnStats -> Html msg
viewColumnStats sources stats =
    div []
        (stats
            |> Dict.toList
            |> List.map (\( sourceId, s ) -> ( sources |> List.findBy (.id >> SourceId.toString) sourceId |> Maybe.mapOrElse .name sourceId, s ))
            |> List.sortBy Tuple.first
            |> List.map
                (\( sourceName, s ) ->
                    if s.rows == 0 then
                        viewProp ("Values in " ++ sourceName ++ " source") [ div [] [ text ("Rows: " ++ String.fromInt s.rows) ] ]

                    else
                        viewProp ("Values in " ++ sourceName ++ " source")
                            [ div [] (text "Samples: " :: (s.commonValues |> List.take 5 |> List.map viewColumnValue))
                            , div []
                                ([ span [] [ text ("Rows: " ++ String.fromInt s.rows) ]
                                 , span [] [ text ("Cardinality: " ++ String.fromInt s.cardinality) ]
                                 , text ("Nulls: " ++ (s.nulls |> Basics.percent s.rows |> Basics.prettyNumber) ++ "%") |> Tooltip.t (String.fromInt s.nulls ++ " nulls")
                                 ]
                                    |> List.intersperse (text ", ")
                                )
                            ]
                )
        )


viewProp : String -> List (Html msg) -> Html msg
viewProp label content =
    div [ class "mt-3" ]
        [ div [ class "text-sm font-medium text-gray-500" ] [ text label ]
        , div [ class "mt-1 text-sm text-gray-900" ] content
        ]


viewTableRelation : (TableId -> msg) -> String -> ErdColumnRef -> Html msg
viewTableRelation click defaultSchema relation =
    div [] [ span [ class "underline cursor-pointer", onClick (relation.table |> click) ] [ text (TableId.show defaultSchema relation.table) ] |> Tooltip.r "View table" ]


viewColumnRelation : (ColumnRef -> msg) -> String -> ErdColumnRef -> Html msg
viewColumnRelation click defaultSchema relation =
    div [] [ span [ class "underline cursor-pointer", onClick ({ table = relation.table, column = relation.column } |> click) ] [ text (ColumnRef.show defaultSchema relation) ] |> Tooltip.r "View column" ]


viewTableConstraints : ErdTable -> Html msg
viewTableConstraints table =
    if table.primaryKey == Nothing && List.isEmpty table.uniques && List.isEmpty table.indexes && List.isEmpty table.checks then
        div [] []

    else
        viewProp "Constraints"
            (((table.primaryKey |> Maybe.toList |> List.map (\pk -> ( "Primary key", Icons.columns.primaryKey, viewTablePrimaryKey pk )))
                ++ (table.uniques |> List.sortBy .name |> List.map (\u -> ( "Unique", Icons.columns.unique, viewTableUnique u )))
                ++ (table.indexes |> List.sortBy .name |> List.map (\i -> ( "Index", Icons.columns.index, viewTableIndex i )))
                ++ (table.checks |> List.sortBy .name |> List.map (\c -> ( "Check", Icons.columns.check, viewTableCheck c )))
             )
                |> List.map (\( kind, icon, content ) -> div [ class "flex flex-row" ] [ Icon.solid icon "inline text-gray-500 w-4 mr-1" |> Tooltip.r kind, content ])
            )


viewTablePrimaryKey : PrimaryKey -> Html msg
viewTablePrimaryKey primaryKey =
    viewTableConstraint "Primary key" primaryKey.name (primaryKey.columns |> Nel.toList)


viewTableUnique : Unique -> Html msg
viewTableUnique unique =
    viewTableConstraint "Unique" (Just unique.name) (unique.columns |> Nel.toList)


viewTableIndex : Index -> Html msg
viewTableIndex index =
    viewTableConstraint "Index" (Just index.name) (index.columns |> Nel.toList)


viewTableCheck : Check -> Html msg
viewTableCheck check =
    viewTableConstraint "Check" (Just check.name) check.columns


viewTableConstraint : String -> Maybe String -> List ColumnName -> Html msg
viewTableConstraint constraint name columns =
    div [ class "text-gray-500 truncate" ]
        (span [ class "text-gray-900" ] (text (constraint ++ ": ") :: (columns |> List.map (\c -> span [ title c ] [ text c ]) |> List.intersperse (text ", ")))
            :: (name |> Maybe.toList |> List.map (\n -> span [ title n ] [ text (" (" ++ n ++ ")") ]))
        )


viewColumnConstraints : ErdTable -> ErdColumn -> Html msg
viewColumnConstraints table column =
    if not column.isPrimaryKey && List.isEmpty column.uniques && List.isEmpty column.indexes && List.isEmpty column.checks then
        div [] []

    else
        viewProp "Constraints"
            (((column.isPrimaryKey |> Bool.list ( "Primary key", Icons.columns.primaryKey, viewColumnPrimaryKey table.primaryKey ))
                ++ (column.uniques |> List.sort |> List.map (\u -> ( "Unique", Icons.columns.unique, viewColumnUnique table.uniques u )))
                ++ (column.indexes |> List.sort |> List.map (\i -> ( "Index", Icons.columns.index, viewColumnIndex table.indexes i )))
                ++ (column.checks |> List.sort |> List.map (\c -> ( "Check", Icons.columns.check, viewColumnCheck table.checks c )))
             )
                |> List.map (\( kind, icon, content ) -> div [ class "flex flex-row" ] [ Icon.solid icon "inline text-gray-500 w-4 mr-1" |> Tooltip.r kind, content ])
            )


viewColumnPrimaryKey : Maybe PrimaryKey -> Html msg
viewColumnPrimaryKey primaryKey =
    (primaryKey |> Maybe.andThen .name) |> viewColumnConstraint "Primary key" (primaryKey |> Maybe.mapOrElse (\pk -> ( Nel.toList pk.columns, Nothing )) ( [], Nothing ))


viewColumnUnique : List Unique -> UniqueName -> Html msg
viewColumnUnique constraints name =
    Just name |> viewColumnConstraint "Unique" (constraints |> List.findBy .name name |> Maybe.mapOrElse (\u -> ( Nel.toList u.columns, u.definition )) ( [], Nothing ))


viewColumnIndex : List Index -> IndexName -> Html msg
viewColumnIndex constraints name =
    Just name |> viewColumnConstraint "Index" (constraints |> List.findBy .name name |> Maybe.mapOrElse (\u -> ( Nel.toList u.columns, u.definition )) ( [], Nothing ))


viewColumnCheck : List Check -> CheckName -> Html msg
viewColumnCheck constraints name =
    Just name |> viewColumnConstraint "Check" (constraints |> List.findBy .name name |> Maybe.mapOrElse (\u -> ( u.columns, u.predicate )) ( [], Nothing ))


viewColumnConstraint : String -> ( List ColumnName, Maybe String ) -> Maybe String -> Html msg
viewColumnConstraint constraint ( columns, definition ) name =
    let
        columnsHtml : List (Html msg)
        columnsHtml =
            if List.length columns > 1 then
                [ text " (", span [ title (columns |> String.join ", ") ] [ text (columns |> String.join ", ") ], text ")" ]

            else
                []
    in
    definition
        |> Maybe.map (\d -> span [ class "truncate", title d ] (text (name |> Maybe.withDefault constraint) :: columnsHtml))
        |> Maybe.withDefault (span [ class "truncate" ] (text (name |> Maybe.withDefault constraint) :: columnsHtml))


viewLayout : (LayoutName -> msg) -> LayoutName -> Html msg
viewLayout loadLayout layout =
    div [] [ span [ class "underline cursor-pointer", onClick (loadLayout layout) ] [ text layout ] |> Tooltip.r "View layout" ]


viewSource : Maybe Int -> ( Origin, Source ) -> Html msg
viewSource rows ( _, source ) =
    div [ class "mt-1 flex flex-row" ]
        [ case source.kind of
            SourceKind.DatabaseConnection _ ->
                Icon.solid Icons.sources.database "w-4 opacity-50 mr-1" |> Tooltip.r "Database source"

            SourceKind.SqlLocalFile _ _ _ ->
                Icon.solid Icons.sources.sql "w-4 opacity-50 mr-1" |> Tooltip.r "SQL source"

            SourceKind.SqlRemoteFile _ _ ->
                Icon.solid Icons.sources.sql "w-4 opacity-50 mr-1" |> Tooltip.r "SQL source"

            SourceKind.JsonLocalFile _ _ _ ->
                Icon.solid Icons.sources.json "w-4 opacity-50 mr-1" |> Tooltip.r "JSON source"

            SourceKind.JsonRemoteFile _ _ ->
                Icon.solid Icons.sources.json "w-4 opacity-50 mr-1" |> Tooltip.r "JSON source"

            SourceKind.AmlEditor ->
                Icon.solid Icons.sources.aml "w-4 opacity-50 mr-1" |> Tooltip.r "AML source"
        , text (source.name ++ (rows |> Maybe.mapOrElse (\r -> " (" ++ String.fromInt r ++ " rows)") ""))
        ]


viewColumnValue : ColumnValueCount -> Html msg
viewColumnValue value =
    (if value.value == "" then
        Badge.basicFlex Tw.gray [ class "mr-1 italic" ] [ text "Empty string" ]

     else
        Badge.basicFlex Tw.gray [ class "mr-1" ] [ text value.value ]
    )
        |> Tooltip.tr (String.fromInt value.count ++ " occurrences")


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



-- PAGE HEADING


pageHeading : Html msg
pageHeading =
    -- from https://tailwindui.com/components/application-ui/headings/page-headings#component-40a924bca34bb5e303d056decfa530e5
    div [ class "lg:flex lg:items-center lg:justify-between" ]
        [ div [ class "flex-1 min-w-0" ]
            [ [ { url = "#", label = "Jobs" }
              , { url = "#", label = "Engineering" }
              , { url = "#", label = "Software" }
              ]
                |> (\items ->
                        nav [ class "flex", ariaLabel "Breadcrumb" ]
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
                   )
            , h2 [ css [ "mt-2 text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:tracking-tight sm:truncate" ] ] [ text "Back End Developer" ]
            , [ { icon = Icon.Briefcase, label = "Full-time" }
              , { icon = Icon.LocationMarker, label = "Remote" }
              , { icon = Icon.CurrencyDollar, label = "$120k – $140k" }
              , { icon = Icon.Calendar, label = "Closing on January 9, 2020" }
              ]
                |> (\items ->
                        div [ css [ "mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6" ] ]
                            (items
                                |> List.map
                                    (\{ icon, label } ->
                                        div [ class "mt-2 flex items-center text-sm text-gray-500" ]
                                            [ Icon.solid icon "flex-shrink-0 mr-1.5 text-gray-400", text label ]
                                    )
                            )
                   )
            ]
        ]



-- COLUMN DIRECTORY


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
                                                            [ span [ class "absolute inset-0", ariaHidden True ] [] -- Extend touch target to entire panel
                                                            , p [ class "text-sm text-gray-900 font-medium" ] [ text employee.name ]
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
    , search : String
    , currentSchema : Maybe ( Heading SchemaName Never, List ErdTable )
    , currentTable : Maybe (Heading ErdTable ErdTableLayout)
    , currentColumn : Maybe (Heading ErdColumn ErdColumnProps)
    , tableNotes : Dict TableId Notes
    , columnNotes : Dict ColumnId Notes
    , editNotes : Bool
    }


initDocState : DocState
initDocState =
    { openedCollapse = ""
    , defaultSchema = "public"
    , search = ""
    , currentSchema = Nothing
    , currentTable = Nothing
    , currentColumn = Nothing
    , tableNotes = Dict.fromList [ ( ( "", "users" ), "Azimutt notes for **users**" ) ]
    , columnNotes = Dict.fromList [ ( ( ( "", "users" ), "id" ), "Azimutt notes for **users.id**" ) ]
    , editNotes = False
    }
        |> docSelectColumn { table = ( Conf.schema.empty, "users" ), column = "id" }


doc : Chapter (SharedDocState x)
doc =
    Chapter.chapter "Details"
        |> Chapter.renderStatefulComponentList
            [ docComponent "viewList & viewList2"
                (\s ->
                    div [ class "flex flex-row grow gap-3" ]
                        ([ viewList, viewList2 ]
                            |> List.map
                                (\renderView ->
                                    div [ class "w-112 border border-gray-300" ]
                                        [ renderView
                                            (\tableId -> s |> docSelectTable tableId |> docSetState)
                                            (\search -> { s | search = search } |> docSetState)
                                            "html-id"
                                            s.defaultSchema
                                            (docErd.tables |> Dict.values)
                                            s.search
                                        ]
                                )
                        )
                )
            , docComponent "viewSchema & viewSchema2"
                (\s ->
                    Maybe.map
                        (\( schema, tables ) ->
                            div [ class "flex flex-row grow gap-3" ]
                                ([ viewSchema, viewSchema2 ]
                                    |> List.map
                                        (\renderView ->
                                            div [ class "w-112 border border-gray-300" ]
                                                [ renderView
                                                    (docSelectList s |> docSetState)
                                                    (\schemaName -> s |> docSelectSchema schemaName |> docSetState)
                                                    (\tableId -> s |> docSelectTable tableId |> docSetState)
                                                    s.defaultSchema
                                                    schema
                                                    tables
                                                ]
                                        )
                                )
                        )
                        s.currentSchema
                        |> Maybe.withDefault (div [] [ text "No selected schema" ])
                )
            , docComponent "viewTable & viewTable2"
                (\s ->
                    Maybe.map2
                        (\( schema, _ ) table ->
                            div [ class "flex flex-row grow gap-3" ]
                                ([ viewTable, viewTable2 ]
                                    |> List.map
                                        (\renderView ->
                                            div [ class "w-112 border border-gray-300" ]
                                                [ renderView
                                                    (docSelectList s |> docSetState)
                                                    (\schemaName -> s |> docSelectSchema schemaName |> docSetState)
                                                    (\tableId -> s |> docSelectTable tableId |> docSetState)
                                                    (\columnRef -> s |> docSelectColumn columnRef |> docSetState)
                                                    (\layout -> logAction ("loadLayout " ++ layout))
                                                    (\source -> docSetState { s | openedCollapse = Bool.cond (s.openedCollapse == "viewTable-" ++ source) "" ("viewTable-" ++ source) })
                                                    (s.openedCollapse |> String.stripLeft "viewTable-")
                                                    s.defaultSchema
                                                    schema
                                                    table
                                                    { notes = s.tableNotes |> Dict.get table.item.id
                                                    , editing = s.editNotes
                                                    , toggleEdit = \_ -> docSetState { s | editNotes = not s.editNotes }
                                                    , update = \notes -> docSetState { s | tableNotes = s.tableNotes |> Dict.insert table.item.id notes }
                                                    }
                                                    (docErd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberBy .id table.item.id) |> Dict.keys)
                                                    (table.item.origins |> List.filterZip (\o -> docErd.sources |> List.findBy .id o.id))
                                                    (docTableStats |> Dict.getOrElse table.item.id Dict.empty)
                                                ]
                                        )
                                )
                        )
                        s.currentSchema
                        s.currentTable
                        |> Maybe.withDefault (div [] [ text "No selected table" ])
                )
            , docComponent "viewColumn & viewColumn2"
                (\s ->
                    Maybe.map3
                        (\( schema, _ ) table column ->
                            div [ class "flex flex-row grow gap-3" ]
                                ([ viewColumn, viewColumn2 ]
                                    |> List.map
                                        (\renderView ->
                                            div [ class "w-112 border border-gray-300" ]
                                                [ renderView
                                                    (docSelectList s |> docSetState)
                                                    (\schemaName -> s |> docSelectSchema schemaName |> docSetState)
                                                    (\tableId -> s |> docSelectTable tableId |> docSetState)
                                                    (\columnRef -> s |> docSelectColumn columnRef |> docSetState)
                                                    (\layout -> logAction ("loadLayout " ++ layout))
                                                    (\source -> docSetState { s | openedCollapse = Bool.cond (s.openedCollapse == "viewColumn-" ++ source) "" ("viewColumn-" ++ source) })
                                                    (s.openedCollapse |> String.stripLeft "viewColumn-")
                                                    s.defaultSchema
                                                    schema
                                                    table
                                                    column
                                                    { notes = s.columnNotes |> Dict.get ( table.item.id, column.item.name )
                                                    , editing = s.editNotes
                                                    , toggleEdit = \_ -> docSetState { s | editNotes = not s.editNotes }
                                                    , update = \notes -> docSetState { s | columnNotes = s.columnNotes |> Dict.insert ( table.item.id, column.item.name ) notes }
                                                    }
                                                    (docErd.layouts |> Dict.filter (\_ l -> l.tables |> List.memberWith (\t -> t.id == table.item.id && (t.columns |> List.memberBy .name column.item.name))) |> Dict.keys)
                                                    (column.item.origins |> List.filterZip (\o -> docErd.sources |> List.findBy .id o.id))
                                                    (docColumnStats |> Dict.getOrElse ( table.item.id, column.item.name ) Dict.empty)
                                                ]
                                        )
                                )
                        )
                        s.currentSchema
                        s.currentTable
                        s.currentColumn
                        |> Maybe.withDefault (div [] [ text "No selected column" ])
                )
            , docComponent "pageHeading" (\_ -> pageHeading)
            , docComponent "directory" (\_ -> directory)
            ]


docNow : Posix
docNow =
    Time.zero


docErd : Erd
docErd =
    """
groups
  id uuid pk

users | List **all** users
  id uuid=uuid() pk | User **identifier**
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
        |> AmlAdapter.buildSource (SourceInfo.aml Time.zero SourceId.zero "test") Array.empty
        |> Tuple3.second
        |> Project.create [] "Project name"
        |> Erd.create
        |> setLayouts
            (Dict.fromList
                [ ( "init layout", docBuildLayout [ ( "users", [ "id", "name" ] ) ] )
                , ( "overview", docBuildLayout [ ( "users", [ "id", "name", "group_id" ] ), ( "groups", [ "id" ] ), ( "credentials", [ "provider_id", "provider_key", "user_id" ] ) ] )
                ]
            )


docSourceId : SourceIdStr
docSourceId =
    docErd.sources |> List.head |> Maybe.mapOrElse (.id >> SourceId.toString) ""


docColumnStats : Dict ColumnId (Dict SourceIdStr ColumnStats)
docColumnStats =
    [ ( docSourceId, ColumnStats ( ( "", "users" ), "id" ) "uuid" 10 0 10 [ { value = "a53cbae3-8e35-46cd-b476-ebaa2a66a278", count = 1 } ] ) ]
        |> List.groupBy (\( _, s ) -> s.id)
        |> Dict.map (\_ -> Dict.fromList)


docTableStats : Dict TableId (Dict SourceIdStr TableStats)
docTableStats =
    docColumnStats |> Dict.toList |> List.map (\( ( table, col ), dict ) -> ( table, dict |> Dict.map (\_ s -> { id = table, rows = s.rows, sampleValues = s.commonValues |> List.map (\v -> ( col, v.value )) |> Dict.fromList }) )) |> Dict.fromList


docBuildLayout : List ( TableIdStr, List ColumnName ) -> ErdLayout
docBuildLayout tables =
    { canvas = CanvasProps.empty
    , tables =
        tables
            |> List.map
                (\( table, columns ) ->
                    { id = TableId.parse table
                    , props = ErdTableProps Nothing Position.zeroCanvasGrid Size.zeroCanvas Tw.red True True True
                    , columns = columns |> List.map (\col -> ErdColumnProps col True)
                    , relatedTables = Dict.empty
                    }
                )
    , createdAt = docNow
    , updatedAt = docNow
    }


docComponent : String -> (DocState -> Html msg) -> ( String, SharedDocState x -> Html msg )
docComponent name render =
    ( name, \{ detailsDocState } -> render detailsDocState )


docSetState : DocState -> Msg (SharedDocState x)
docSetState state =
    Actions.updateState (\s -> { s | detailsDocState = state })


docSelectList : DocState -> DocState
docSelectList state =
    { state | currentSchema = Nothing, currentTable = Nothing, currentColumn = Nothing, editNotes = False }


docSelectSchema : SchemaName -> DocState -> DocState
docSelectSchema schema state =
    { state
        | currentSchema = Just ( buildSchemaHeading docErd schema, docErd.tables |> Dict.values |> List.filterBy .schema schema |> List.sortBy .name )
        , currentTable = Nothing
        , currentColumn = Nothing
        , editNotes = False
    }


docSelectTable : TableId -> DocState -> DocState
docSelectTable table state =
    (docErd |> Erd.getTable table)
        |> Maybe.map
            (\erdTable ->
                { state
                    | currentSchema = Just ( buildSchemaHeading docErd erdTable.schema, docErd.tables |> Dict.values |> List.filterBy .schema erdTable.schema |> List.sortBy .name )
                    , currentTable = Just (buildTableHeading docErd erdTable)
                    , currentColumn = Nothing
                    , editNotes = False
                }
            )
        |> Maybe.withDefault state


docSelectColumn : ColumnRef -> DocState -> DocState
docSelectColumn { table, column } state =
    (docErd |> Erd.getTable table)
        |> Maybe.andThen
            (\erdTable ->
                (erdTable.columns |> Dict.get column)
                    |> Maybe.map
                        (\erdColumn ->
                            { state
                                | currentSchema = Just ( buildSchemaHeading docErd erdTable.schema, docErd.tables |> Dict.values |> List.filterBy .schema erdTable.schema |> List.sortBy .name )
                                , currentTable = Just (buildTableHeading docErd erdTable)
                                , currentColumn = Just (buildColumnHeading docErd erdTable erdColumn)
                                , editNotes = False
                            }
                        )
            )
        |> Maybe.withDefault state
