module Components.Organisms.ColorPicker exposing (doc, view)

import Components.Molecules.ContextMenu as ContextMenu
import ElmBook.Actions as Actions
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div)
import Html.Attributes exposing (class, tabindex, title, type_)
import Html.Events exposing (onClick)
import Libs.Html.Attributes exposing (css, role)
import Libs.Tailwind as Tw exposing (Color, bg_500, focus, hover)


view : (Color -> msg) -> Html msg
view pickColor =
    div [ css [ "group-hover:grid grid-cols-6 gap-1 p-1 pl-2" ] ]
        (Tw.selectable
            |> List.map
                (\c ->
                    button
                        [ type_ "button"
                        , onClick (pickColor c)
                        , title (Tw.toString c)
                        , role "menuitem"
                        , tabindex -1
                        , css [ "rounded-full w-6 h-6", bg_500 c, hover [ "scale-125" ], focus [ "outline-none" ] ]
                        ]
                        []
                )
        )



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "ColorPicker"
        |> Chapter.renderComponentList
            [ ( "view"
              , div [ class "max-w-xs" ]
                    [ ContextMenu.btnSubmenu
                        { label = "Choose color"
                        , content = ContextMenu.Custom (view (Tw.toString >> Actions.logActionWithString "pickColor")) ContextMenu.BottomRight
                        }
                    ]
              )
            ]
