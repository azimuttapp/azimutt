module PagesComponents.App.Views.Erd.Table exposing (viewTable)

import Conf exposing (conf)
import Dict
import FontAwesome.Icon exposing (viewIcon)
import FontAwesome.Regular as IconLight
import FontAwesome.Solid as Icon
import Html exposing (Attribute, Html, b, button, div, li, span, text, ul)
import Html.Attributes exposing (class, classList, id, style, title, type_)
import Html.Events exposing (onClick, onDoubleClick)
import Html.Events.Extra.Pointer as Pointer
import Html.Keyed as Keyed
import Html.Lazy exposing (lazy3, lazy4)
import Libs.Bootstrap exposing (Toggle(..), bsDropdown, bsToggle, bsToggleCollapse)
import Libs.DomInfo exposing (DomInfo)
import Libs.Html exposing (divIf)
import Libs.Html.Attributes exposing (track)
import Libs.List as L
import Libs.Maybe as M
import Libs.Models exposing (ZoomLevel)
import Libs.Ned as Ned
import Libs.Nel as Nel
import Libs.String as S
import Models.Project exposing (Column, ColumnName, ColumnRef, Comment, Index, PrimaryKey, RelationFull, Table, TableId, TableProps, Unique, inIndexes, inPrimaryKey, inUniques, showTableId, showTableName, tableIdAsHtmlId, tableIdAsString, withNullableInfo)
import PagesComponents.App.Models exposing (Hover, Msg(..))
import PagesComponents.App.Views.Helpers exposing (columnRefAsHtmlId, onDrag, placeAt, sizeAttr, withColumnName)
import Tracking exposing (events)


viewTable : Hover -> ZoomLevel -> Int -> Table -> TableProps -> List RelationFull -> Maybe DomInfo -> Html Msg
viewTable hover zoom index table props tableRelations domInfo =
    let
        hiddenColumns : List Column
        hiddenColumns =
            table.columns |> Ned.values |> Nel.filter (\c -> props.columns |> L.hasNot c.name)
    in
    div
        [ class "erd-table"
        , class props.color
        , classList [ ( "selected", props.selected ) ]
        , id (tableIdAsHtmlId table.id)
        , placeAt props.position
        , style "z-index" (String.fromInt (conf.zIndex.tables + index))
        , domInfo |> Maybe.map (\i -> sizeAttr i.size) |> Maybe.withDefault (style "visibility" "hidden")
        , Pointer.onEnter (\_ -> HoverTable (Just table.id))
        , Pointer.onLeave (\_ -> HoverTable Nothing)
        , onDrag (tableIdAsHtmlId table.id)
        ]
        [ lazy3 viewHeader zoom index table
        , lazy4 viewColumns hover table tableRelations props.columns
        , lazy4 viewHiddenColumns (tableIdAsHtmlId table.id ++ "-hidden-columns-collapse") table tableRelations hiddenColumns
        ]


viewHeader : ZoomLevel -> Int -> Table -> Html Msg
viewHeader zoom index table =
    div [ class "header", style "display" "flex", style "align-items" "center" ]
        [ div [ style "flex-grow" "1", Pointer.onUp (\e -> SelectTable table.id e.pointer.keys.ctrl) ] (L.appendOn table.comment viewComment [ span (tableNameSize zoom) [ text (showTableName table.schema table.name) ] ])
        , bsDropdown (tableIdAsHtmlId table.id ++ "-settings-dropdown")
            []
            (\attrs -> div ([ style "font-size" "0.9rem", style "opacity" "0.25", style "width" "30px", style "margin-left" "-10px", style "margin-right" "-20px" ] ++ attrs ++ track events.openTableSettings) [ viewIcon Icon.ellipsisV ])
            (\attrs ->
                ul attrs
                    [ li [] [ button [ type_ "button", class "dropdown-item", onClick (HideTable table.id) ] [ text "Hide table" ] ]
                    , li []
                        [ button [ type_ "button", class "dropdown-item" ] [ text "Sort columns »" ]
                        , ul [ class "dropdown-menu dropdown-submenu" ]
                            [ li [] [ button [ type_ "button", class "dropdown-item", onClick (SortColumns table.id "property"), title "Primary key, then foreign key, then unique indexes, then indexes, then others" ] [ text "By property" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (SortColumns table.id "name") ] [ text "By name" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (SortColumns table.id "sql") ] [ text "By SQL order" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (SortColumns table.id "type") ] [ text "By type" ] ]
                            ]
                        ]
                    , li []
                        [ button [ type_ "button", class "dropdown-item" ] [ text "Hide columns »" ]
                        , ul [ class "dropdown-menu dropdown-submenu" ]
                            [ li [] [ button [ type_ "button", class "dropdown-item", onClick (HideColumns table.id "regular"), title "Without key or index" ] [ text "Regular ones" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (HideColumns table.id "nullable") ] [ text "Nullable ones" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (HideColumns table.id "all") ] [ text "All" ] ]
                            ]
                        ]
                    , li []
                        [ button [ type_ "button", class "dropdown-item" ] [ text "Show columns »" ]
                        , ul [ class "dropdown-menu dropdown-submenu" ]
                            [ li [] [ button [ type_ "button", class "dropdown-item", onClick (ShowColumns table.id "all") ] [ text "All" ] ]
                            ]
                        ]
                    , li []
                        [ button [ type_ "button", class "dropdown-item" ] [ text "Order »" ]
                        , ul [ class "dropdown-menu dropdown-submenu" ]
                            [ li [] [ button [ type_ "button", class "dropdown-item", onClick (TableOrder table.id 1000) ] [ text "Bring to front" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (TableOrder table.id (index + 1)) ] [ text "Bring forward" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (TableOrder table.id (index - 1)) ] [ text "Send backward" ] ]
                            , li [] [ button [ type_ "button", class "dropdown-item", onClick (TableOrder table.id 0) ] [ text "Send to back" ] ]
                            ]
                        ]
                    , li [] [ button [ type_ "button", class "dropdown-item", onClick (FindPath (Just table.id) Nothing) ] [ text "Find path from this table" ] ]
                    ]
            )
        ]


viewColumns : Hover -> Table -> List RelationFull -> List ColumnName -> Html Msg
viewColumns hover table tableRelations columns =
    Keyed.node "div"
        [ class "columns" ]
        (columns
            |> List.filterMap (\c -> table.columns |> Ned.get c)
            |> L.zipWith (\c -> tableRelations |> filterColumnRelations table.id c.name)
            |> List.map (\( c, columnRelations ) -> ( c.name, lazy4 viewColumn (isRelationHover hover columnRelations) columnRelations table c ))
        )


viewColumn : Bool -> List RelationFull -> Table -> Column -> Html Msg
viewColumn isHover columnRelations table column =
    let
        ref : ColumnRef
        ref =
            ColumnRef table.id column.name
    in
    div
        [ class "column"
        , classList [ ( "hover", isHover ) ]
        , id (columnRefAsHtmlId ref)
        , onDoubleClick (HideColumn ref)
        , Pointer.onEnter (\_ -> HoverColumn (Just ref))
        , Pointer.onLeave (\_ -> HoverColumn Nothing)
        ]
        [ viewColumnDropdown columnRelations ref (viewColumnIcon table column columnRelations)
        , viewColumnName table column
        , viewColumnType column
        ]


isRelationHover : Hover -> List RelationFull -> Bool
isRelationHover hover columnRelations =
    hover.column |> M.exist (\c -> columnRelations |> List.any (\r -> (r.src.table.id == c.table && r.src.column.name == c.column) || (r.ref.table.id == c.table && r.ref.column.name == c.column)))


viewHiddenColumns : String -> Table -> List RelationFull -> List Column -> Html Msg
viewHiddenColumns collapseId table tableRelations hiddenColumns =
    divIf (List.length hiddenColumns > 0)
        [ class "hidden-columns" ]
        [ button ([ class "toggle", type_ "button" ] ++ bsToggleCollapse collapseId)
            [ text (S.plural (hiddenColumns |> List.length) "No hidden column" "1 hidden column" "hidden columns")
            ]
        , Keyed.node "div"
            [ class "collapse", id collapseId ]
            (hiddenColumns
                |> List.sortBy .index
                |> List.map (\c -> ( c.name, lazy3 viewHiddenColumn table c (tableRelations |> filterColumnRelations table.id c.name) ))
            )
        ]


viewHiddenColumn : Table -> Column -> List RelationFull -> Html Msg
viewHiddenColumn table column columnRelations =
    div [ class "hidden-column", onDoubleClick (ShowColumn (ColumnRef table.id column.name)) ]
        [ viewColumnIcon table column columnRelations []
        , viewColumnName table column
        , viewColumnType column
        ]


viewColumnIcon : Table -> Column -> List RelationFull -> List (Attribute Msg) -> Html Msg
viewColumnIcon table column columnRelations attrs =
    case ( ( column.name |> inPrimaryKey table, columnRelations |> List.filter (\r -> r.src.table.id == table.id && r.src.column.name == column.name) |> List.head ), ( column.name |> inUniques table, column.name |> inIndexes table ) ) of
        ( ( Just pk, _ ), _ ) ->
            div (class "icon" :: attrs) [ div [ title (formatPkTitle pk), bsToggle Tooltip ] [ viewIcon Icon.key ] ]

        ( ( _, Just fk ), _ ) ->
            -- TODO: know fk table state to not put onClick when it's already shown (so Update.elm#showTable on Shown state could issue an error)
            div (class "icon" :: onClick (ShowTable fk.ref.table.id) :: attrs ++ track events.showTableWithForeignKey) [ div [ title (formatFkTitle fk), bsToggle Tooltip ] [ viewIcon Icon.externalLinkAlt ] ]

        ( _, ( u :: us, _ ) ) ->
            div (class "icon" :: attrs) [ div [ title (formatUniqueTitle (u :: us)), bsToggle Tooltip ] [ viewIcon Icon.fingerprint ] ]

        ( _, ( _, i :: is ) ) ->
            div (class "icon" :: attrs) [ div [ title (formatIndexTitle (i :: is)), bsToggle Tooltip ] [ viewIcon Icon.sortAmountDownAlt ] ]

        _ ->
            div ([ class "icon" ] ++ attrs) []


viewColumnDropdown : List RelationFull -> ColumnRef -> (List (Attribute Msg) -> Html Msg) -> Html Msg
viewColumnDropdown columnRelations ref element =
    case
        columnRelations
            |> List.filter (\relation -> relation.src.table.id /= ref.table)
            |> L.groupBy (\relation -> relation.src.table.id |> tableIdAsString)
            |> Dict.values
            |> List.concatMap (\tableRelations -> [ tableRelations.head ])
            |> List.map
                (\relation ->
                    li []
                        [ button ([ type_ "button", class "dropdown-item", classList [ ( "disabled", not (relation.src.props == Nothing) ) ], onClick (ShowTable relation.src.table.id) ] ++ track events.showTableWithIncomingRelationsDropdown)
                            [ viewIcon Icon.externalLinkAlt
                            , text " "
                            , b [] [ text (showTableId relation.src.table.id) ]
                            , text ("" |> withColumnName relation.src.column.name |> withNullableInfo relation.src.column.nullable)
                            ]
                        ]
                )
    of
        [] ->
            -- needs the same structure than dropdown to not change nodes and cause bootstrap errors: (Bootstrap doesn't allow more than one instance per element)
            div [] [ element [] ]

        items ->
            bsDropdown (columnRefAsHtmlId ref ++ "-relations-dropdown")
                [ class "dropdown-menu-end" ]
                (\attrs -> element (attrs ++ track events.openIncomingRelationsDropdown))
                (\attrs -> ul attrs (items ++ viewShowAllOption columnRelations))


viewShowAllOption : List RelationFull -> List (Html Msg)
viewShowAllOption incomingRelations =
    case incomingRelations |> List.filter (\r -> r.src.props == Nothing) |> List.map (\r -> r.src.table.id) |> L.unique of
        [] ->
            []

        rels ->
            [ li [] [ button [ type_ "button", class "dropdown-item", onClick (ShowTables rels) ] [ text ("Show all (" ++ String.fromInt (List.length rels) ++ " tables)") ] ] ]


viewColumnName : Table -> Column -> Html msg
viewColumnName table column =
    let
        className : String
        className =
            case column.name |> inPrimaryKey table of
                Just _ ->
                    "name bold"

                _ ->
                    "name"
    in
    div [ class className ]
        ([ text column.name ] |> L.appendOn column.comment viewComment)


viewColumnType : Column -> Html msg
viewColumnType column =
    let
        value : Html msg
        value =
            column.default
                |> Maybe.map (\default -> span [ class "value text-decoration-underline", title ("default value: " ++ default), bsToggle Tooltip ] [ text column.kind ])
                |> Maybe.withDefault (span [ class "value" ] [ text column.kind ])

        nullable : List (Html msg)
        nullable =
            if column.nullable then
                [ span [ class "nullable", title "nullable", bsToggle Tooltip ] [ text "?" ] ]

            else
                []
    in
    div [ class "type" ] (value :: nullable)


viewComment : Comment -> Html msg
viewComment comment =
    span [ title comment.text, bsToggle Tooltip, style "margin-left" ".25rem", style "font-size" ".9rem", style "opacity" ".25" ] [ viewIcon IconLight.commentDots ]



-- view helpers


filterColumnRelations : TableId -> ColumnName -> List RelationFull -> List RelationFull
filterColumnRelations table column tableRelations =
    tableRelations |> List.filter (\r -> (r.src.table.id == table && r.src.column.name == column) || (r.ref.table.id == table && r.ref.column.name == column))


tableNameSize : ZoomLevel -> List (Attribute msg)
tableNameSize zoom =
    -- when zoom is small, keep the table name readable
    if zoom < 0.5 then
        [ style "font-size" (String.fromFloat (10 / zoom) ++ "px") ]

    else
        []



-- data accessors


formatPkTitle : PrimaryKey -> String
formatPkTitle _ =
    "Primary key"


formatFkTitle : RelationFull -> String
formatFkTitle rel =
    "Foreign key to " ++ formatReference rel


formatUniqueTitle : List Unique -> String
formatUniqueTitle uniques =
    "Unique constraint in " ++ (uniques |> List.map .name |> String.join ", ")


formatIndexTitle : List Index -> String
formatIndexTitle indexes =
    "Indexed by " ++ (indexes |> List.map .name |> String.join ", ")


formatReference : RelationFull -> String
formatReference rel =
    showTableName (rel.ref.table.id |> Tuple.first) (rel.ref.table.id |> Tuple.second) |> withColumnName rel.ref.column.name
