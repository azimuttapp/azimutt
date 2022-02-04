module Components.Molecules.ItemList exposing (IconItem, doc, withIcons)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter exposing (Chapter)
import Html exposing (Html, button, div, h3, li, p, span, text, ul)
import Html.Attributes exposing (type_)
import Html.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Attributes exposing (ariaHidden, css, role)
import Libs.Models.Color as Color exposing (Color)
import Libs.Tailwind exposing (bg_500, focus, focusWithin, hover, sm)


type alias IconItem msg =
    { color : Color, icon : Icon, title : String, description : String, active : Bool, onClick : msg }


withIcons : List (IconItem msg) -> Html msg
withIcons items =
    ul [ role "list", css [ "mt-6 grid grid-cols-1 gap-6", sm [ "grid-cols-2" ] ] ]
        (items |> List.map withIcon)


withIcon : IconItem msg -> Html msg
withIcon item =
    li [ css [ "flow-root", B.cond item.active "" "filter grayscale" ] ]
        [ div [ css [ "relative -m-2 p-2 flex items-center space-x-4 rounded-xl", hover [ "bg-gray-50" ], focusWithin [ "ring-2 ring-primary-500" ] ] ]
            [ div [ css [ "flex-shrink-0 flex items-center justify-center h-16 w-16 rounded-lg", bg_500 item.color ] ] [ Icon.outline item.icon "text-white" ]
            , div []
                [ h3 []
                    [ button [ type_ "button", onClick item.onClick, css [ "text-sm font-medium text-gray-900", focus [ "outline-none" ] ] ]
                        [ span [ css [ "absolute inset-0" ], ariaHidden True ] []
                        , text item.title
                        ]
                    ]
                , p [ css [ "mt-1 text-sm text-gray-500" ] ] [ text item.description ]
                ]
            ]
        ]



-- DOCUMENTATION


doc : Chapter x
doc =
    Chapter.chapter "ItemList"
        |> Chapter.renderComponentList
            [ ( "withIcons"
              , withIcons
                    [ { color = Color.pink, icon = ViewList, title = "Create a List →", description = "Another to-do system you’ll try but eventually give up on.", active = True, onClick = logAction "List clicked" }
                    , { color = Color.yellow, icon = Calendar, title = "Create a Calendar →", description = "Stay on top of your deadlines, or don’t — it’s up to you.", active = True, onClick = logAction "Calendar clicked" }
                    , { color = Color.green, icon = Photograph, title = "Create a Gallery →", description = "Great for mood boards and inspiration.", active = True, onClick = logAction "Gallery clicked" }
                    , { color = Color.blue, icon = ViewBoards, title = "Create a Board →", description = "Track tasks in different stages of your project.", active = True, onClick = logAction "Board clicked" }
                    , { color = Color.indigo, icon = Table, title = "Create a Spreadsheet →", description = "Lots of numbers and things — good for nerds.", active = True, onClick = logAction "Spreadsheet clicked" }
                    , { color = Color.purple, icon = Clock, title = "Create a Timeline →", description = "Get a birds-eye-view of your procrastination.", active = True, onClick = logAction "Timeline clicked" }
                    ]
              )
            ]
