module PagesComponents.Organization_.Project_.Views.Erd.TableRow exposing (viewTableRow)

import Components.Organisms.TableRow as TableRow
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Libs.Models.HtmlId exposing (HtmlId)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.Source exposing (Source)
import Models.Project.TableRow exposing (TableRow)
import PagesComponents.Organization_.Project_.Models exposing (MemoMsg(..), Msg(..))
import Time


viewTableRow : Time.Posix -> SchemaName -> HtmlId -> HtmlId -> List Source -> TableRow -> Html Msg
viewTableRow now defaultSchema openedDropdown htmlId sources row =
    div [ id htmlId ]
        [ TableRow.view (TableRowMsg row.id) DropdownToggle (DeleteTableRow row.id) now defaultSchema openedDropdown htmlId sources row
        ]
