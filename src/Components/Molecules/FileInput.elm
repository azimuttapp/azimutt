module Components.Molecules.FileInput exposing (Model, basic, doc, input)

import Components.Atoms.Icon as Icon exposing (Icon(..))
import Css
import ElmBook.Actions exposing (logAction)
import ElmBook.Chapter as Chapter
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, div, label, p, span, text)
import Html.Styled.Attributes exposing (css, for)
import Libs.FileInput as FileInput exposing (File)
import Libs.Html.Styled.Attributes exposing (role)
import Libs.Models.Color as Color
import Libs.Models.HtmlId exposing (HtmlId)
import Libs.Models.Theme exposing (Theme)
import Libs.String as String
import Libs.Tailwind.Utilities as Tu
import Tailwind.Utilities as Tw


basic : Theme -> HtmlId -> (File -> msg) -> msg -> Html msg
basic theme fieldId onSelect noop =
    input theme { id = fieldId, onDrop = \f _ -> onSelect f, onOver = Just (\_ _ -> noop), onLeave = Nothing, onSelect = onSelect }


type alias Model msg =
    { id : HtmlId
    , onDrop : File -> List File -> msg
    , onOver : Maybe (File -> List File -> msg)
    , onLeave : Maybe { id : String, msg : msg }
    , onSelect : File -> msg
    }


input : Theme -> Model msg -> Html msg
input theme model =
    label
        ([ for model.id, role "button", css [ Tw.flex, Tw.justify_center, Tw.px_6, Tw.pt_5, Tw.pb_6, Tw.border_2, Tw.border_gray_300, Tw.border_dashed, Tw.rounded_md, Tw.text_gray_600, Tu.focusWithinRing ( theme.color, 600 ) ( Color.white, 600 ), Css.hover [ Color.border theme.color 400, Color.text theme.color 600 ] ] ]
            ++ FileInput.onDrop { onDrop = model.onDrop, onOver = model.onOver, onLeave = model.onLeave }
        )
        [ div [ css [ Tw.space_y_1, Tw.text_center ] ]
            [ Icon.outline DocumentAdd [ Tw.mx_auto, Tw.h_12, Tw.w_12 ]
            , div [ css [ Tw.flex, Tw.text_sm ] ]
                [ span [ css [ Tw.relative, Tw.cursor_pointer, Tw.bg_white, Tw.rounded_md, Tw.font_medium, Color.text theme.color 600 ] ]
                    [ span [] [ text "Upload a file" ]
                    , FileInput.hiddenInputSingle model.id [ ".sql" ] model.onSelect
                    ]
                , p [ css [ Tw.pl_1 ] ] [ text "or drag and drop" ]
                ]
            , p [ css [ Tw.text_xs ] ] [ text "SQL file only" ]
            ]
        ]



-- DOCUMENTATION


doc : Theme -> Chapter x
doc theme =
    Chapter.chapter "FileInput"
        |> Chapter.renderComponentList
            [ ( "basic", basic theme "basic-id" (\f -> logAction ("Selected: " ++ f.name)) (logAction "Noop") )
            , ( "input"
              , input theme
                    { id = "input-id"
                    , onDrop = \file files -> logAction ("Drop " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", "))
                    , onOver = Just (\file files -> logAction ("Over " ++ ((file :: files) |> String.pluralizeL "file") ++ ": " ++ ((file :: files) |> List.map .name |> String.join ", ")))
                    , onLeave = Just { id = "input-leave-id", msg = logAction "Leave" }
                    , onSelect = \file -> logAction ("Select " ++ file.name)
                    }
              )
            ]
