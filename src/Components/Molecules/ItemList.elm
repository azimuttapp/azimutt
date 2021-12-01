module Components.Molecules.ItemList exposing (IconItem, doc, withIcons)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, button, div, h3, li, p, span, text, ul)
import Html.Styled.Attributes exposing (css, type_)
import Html.Styled.Events exposing (onClick)
import Libs.Bool as B
import Libs.Html.Styled.Attributes exposing (ariaHidden, role)
import Libs.Models.Theme exposing (Theme)
import Libs.Models.TwColor as TwColor exposing (TwColor(..), TwColorLevel(..), TwColorPosition(..))
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias IconItem msg =
    { color : TwColor, icon : Icon, title : String, description : String, active : Bool, onClick : msg }


withIcons : Theme -> List (IconItem msg) -> Html msg
withIcons theme items =
    ul [ role "list", css [ Tw.mt_6, Tw.grid, Tw.grid_cols_1, Tw.gap_6, Bp.sm [ Tw.grid_cols_2 ] ] ]
        (items |> List.map (withIcon theme))


withIcon : Theme -> IconItem msg -> Html msg
withIcon theme item =
    li [ css ([ Tw.flow_root ] ++ B.cond item.active [] [ Tw.filter, Tw.grayscale ]) ]
        [ div [ css [ Tw.relative, Tw.neg_m_2, Tw.p_2, Tw.flex, Tw.items_center, Tw.space_x_4, Tw.rounded_xl, Tu.focusWithin [ Tw.ring_2, TwColor.render Ring theme.color L500 ], Css.hover [ Tw.bg_gray_50 ] ] ]
            [ div [ css [ Tw.flex_shrink_0, Tw.flex, Tw.items_center, Tw.justify_center, Tw.h_16, Tw.w_16, Tw.rounded_lg, TwColor.render Bg item.color L500 ] ] [ Icon.outline item.icon [ Tw.text_white ] ]
            , div []
                [ h3 []
                    [ button [ type_ "button", onClick item.onClick, css [ Tw.text_sm, Tw.font_medium, Tw.text_gray_900, Css.focus [ Tw.outline_none ] ] ]
                        [ span [ css [ Tw.absolute, Tw.inset_0 ], ariaHidden True ] []
                        , text item.title
                        ]
                    ]
                , p [ css [ Tw.mt_1, Tw.text_sm, Tw.text_gray_500 ] ] [ text item.description ]
                ]
            ]
        ]



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    Chapter.chapter "ItemList"
        |> Chapter.renderComponentList
            [ ( "withIcons"
              , withIcons theme
                    [ { color = Pink, icon = ViewList, title = "Create a List →", description = "Another to-do system you’ll try but eventually give up on.", active = True, onClick = logAction "List clicked" }
                    , { color = Yellow, icon = Calendar, title = "Create a Calendar →", description = "Stay on top of your deadlines, or don’t — it’s up to you.", active = True, onClick = logAction "Calendar clicked" }
                    , { color = Green, icon = Photograph, title = "Create a Gallery →", description = "Great for mood boards and inspiration.", active = True, onClick = logAction "Gallery clicked" }
                    , { color = Blue, icon = ViewBoards, title = "Create a Board →", description = "Track tasks in different stages of your project.", active = True, onClick = logAction "Board clicked" }
                    , { color = Indigo, icon = Table, title = "Create a Spreadsheet →", description = "Lots of numbers and things — good for nerds.", active = True, onClick = logAction "Spreadsheet clicked" }
                    , { color = Purple, icon = Clock, title = "Create a Timeline →", description = "Get a birds-eye-view of your procrastination.", active = True, onClick = logAction "Timeline clicked" }
                    ]
              )
            ]
