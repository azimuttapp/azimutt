module PagesComponents.Organization_.Project_.Views.Modals.GroupContextMenu exposing (view)

import Components.Molecules.ContextMenu as ContextMenu
import Components.Organisms.ColorPicker as ColorPicker
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Models.Project.Group exposing (Group)
import Models.Project.SchemaName exposing (SchemaName)
import Models.Project.TableId as TableId
import PagesComponents.Organization_.Project_.Models exposing (GroupMsg(..), Msg(..))


view : SchemaName -> Int -> Group -> Html Msg
view defaultSchema index group =
    div [ class "z-max" ]
        ([ div [ class "px-4 py-1 text-sm font-medium leading-6 text-gray-500" ] [ text (group.name ++ " group") ] ]
            ++ ([ { label = "Edit group name", content = ContextMenu.Simple { action = GEdit index group.name |> GroupMsg } }
                , { label = "Set color", content = ContextMenu.Custom (ColorPicker.view (GSetColor index >> GroupMsg)) ContextMenu.BottomRight }
                , { label = "Remove table", content = ContextMenu.SubMenu (group.tables |> List.map (\id -> { label = TableId.show defaultSchema id, action = GRemoveTables index [ id ] |> GroupMsg })) ContextMenu.BottomRight }
                , { label = "Delete group", content = ContextMenu.Simple { action = GDelete index |> GroupMsg } }
                ]
                    |> List.map ContextMenu.btnSubmenu
               )
        )
