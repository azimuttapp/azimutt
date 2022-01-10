module Components.Slices.Newsletter exposing (Form, Model, basicSlice, centered, doc, formDoc, small)

import Css
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, form, h2, input, label, p, text)
import Html.Styled.Attributes exposing (action, attribute, css, for, href, id, method, name, placeholder, rel, required, target, type_)
import Libs.Models.Color as Color
import Libs.Tailwind.Utilities as Tu
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


type alias Model msg =
    { form : Form
    , title : String
    , description : String
    , legalText : List (Html msg)
    }


type alias Form =
    { method : String
    , url : String
    , placeholder : String
    , cta : String
    }


basicSlice : Model msg -> Html msg
basicSlice model =
    div [ css [ Tw.bg_white ] ]
        [ div [ css [ Tw.max_w_7xl, Tw.mx_auto, Tw.py_24, Tw.px_4, Bp.lg [ Tw.py_32, Tw.px_8, Tw.flex, Tw.items_center ], Bp.sm [ Tw.px_6 ] ] ]
            [ div [ css [ Bp.lg [ Tw.w_0, Tw.flex_1 ] ] ]
                [ h2 [ css [ Tw.text_3xl, Tw.font_extrabold, Tw.text_gray_900, Bp.sm [ Tw.text_4xl ] ] ] [ text model.title ]
                , p [ css [ Tw.mt_3, Tw.max_w_3xl, Tw.text_lg, Tw.text_gray_500 ] ] [ text model.description ]
                ]
            , div [ css [ Tw.mt_8, Bp.lg [ Tw.mt_0, Tw.ml_8 ] ] ]
                [ form [ method model.form.method, action model.form.url, target "_blank", rel "noopener", css [ Bp.sm [ Tw.flex ] ] ]
                    [ label [ for "newsletter-email", css [ Tw.sr_only ] ] [ text model.form.placeholder ]
                    , input [ type_ "email", name "member[email]", id "newsletter-email", placeholder model.form.placeholder, attribute "autocomplete" "email", required True, css [ Tw.w_full, Tw.px_5, Tw.py_3, Tw.border, Tw.border_gray_300, Tw.shadow_sm, Tw.placeholder_gray_400, Tw.rounded_md, Css.focus [ Tw.ring_1, Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.sm [ Tw.max_w_xs ] ] ] []
                    , div [ css [ Tw.mt_3, Tw.rounded_md, Tw.shadow, Bp.sm [ Tw.mt_0, Tw.ml_3, Tw.flex_shrink_0 ] ] ]
                        [ button [ type_ "submit", css [ Tw.w_full, Tw.flex, Tw.items_center, Tw.justify_center, Tw.py_3, Tw.px_5, Tw.border, Tw.border_transparent, Tw.text_base, Tw.font_medium, Tw.rounded_md, Tw.text_white, Tw.bg_indigo_600, Tu.focusRing ( Color.indigo, 500 ) ( Color.white, 500 ), Css.hover [ Tw.bg_indigo_700 ] ] ]
                            [ text model.form.cta ]
                        ]
                    ]
                , p [ css [ Tw.mt_3, Tw.text_sm, Tw.text_gray_500 ] ] model.legalText
                ]
            ]
        ]


centered : Form -> Html msg
centered model =
    div [ css [ Tw.max_w_prose, Tw.mx_auto ] ]
        [ form [ method model.method, action model.url, target "_blank", rel "noopener", css [ Tw.justify_center, Bp.sm [ Tw.flex ] ] ]
            [ input [ type_ "email", name "member[email]", id "newsletter-email", placeholder model.placeholder, attribute "autocomplete" "email", required True, css [ Tw.appearance_none, Tw.w_full, Tw.px_5, Tw.py_3, Tw.border, Tw.border_gray_300, Tw.text_base, Tw.leading_6, Tw.rounded_md, Tw.text_gray_900, Tw.bg_white, Tw.placeholder_gray_500, Tw.transition, Tw.duration_150, Tw.ease_in_out, Css.focus [ Tw.outline_none, Tw.border_blue_300 ], Bp.sm [ Tw.max_w_xs ] ] ] []
            , div [ css [ Tw.mt_3, Tw.rounded_md, Tw.shadow, Bp.sm [ Tw.mt_0, Tw.ml_3, Tw.flex_shrink_0 ] ] ]
                [ button [ css [ Tw.w_full, Tw.flex, Tw.items_center, Tw.justify_center, Tw.px_5, Tw.py_3, Tw.border, Tw.border_transparent, Tw.text_base, Tw.leading_6, Tw.font_medium, Tw.rounded_md, Tw.text_white, Tw.bg_indigo_600, Tw.transition, Tw.duration_150, Tw.ease_in_out, Css.focus [ Tw.outline_none ], Css.hover [ Tw.bg_indigo_500 ] ] ]
                    [ text model.cta ]
                ]
            ]
        ]


small : Form -> Html msg
small model =
    form [ method model.method, action model.url, target "_blank", rel "noopener", css [ Tw.mt_6, Tw.flex, Tw.flex_col, Bp.lg [ Tw.mt_0, Tw.justify_end ], Bp.sm [ Tw.flex_row ] ] ]
        [ div []
            [ label [ for "newsletter-email", css [ Tw.sr_only ] ] [ text model.placeholder ]
            , input [ type_ "email", name "member[email]", id "newsletter-email", attribute "autocomplete" "email", required True, css [ Tw.appearance_none, Tw.w_full, Tw.px_4, Tw.py_2, Tw.border, Tw.border_gray_300, Tw.text_base, Tw.rounded_md, Tw.text_gray_900, Tw.bg_white, Tw.placeholder_gray_500, Css.focus [ Tw.outline_none, Tw.ring_indigo_500, Tw.border_indigo_500 ], Bp.lg [ Tw.max_w_xs ] ], placeholder model.placeholder ] []
            ]
        , div [ css [ Tw.mt_2, Tw.flex_shrink_0, Tw.w_full, Tw.flex, Tw.rounded_md, Tw.shadow_sm, Bp.sm [ Tw.mt_0, Tw.ml_3, Tw.w_auto, Tw.inline_flex ] ] ]
            [ button [ type_ "submit", css [ Tw.w_full, Tw.bg_indigo_600, Tw.px_4, Tw.py_2, Tw.border, Tw.border_transparent, Tw.rounded_md, Tw.flex, Tw.items_center, Tw.justify_center, Tw.text_base, Tw.font_medium, Tw.text_white, Tu.focusRing ( Color.indigo, 500 ) ( Color.white, 500 ), Css.hover [ Tw.bg_indigo_700 ], Bp.sm [ Tw.w_auto, Tw.inline_flex ] ] ]
                [ text model.cta ]
            ]
        ]



-- DOCUMENTATION


formDoc : Form
formDoc =
    { method = "get", url = "#", placeholder = "Enter your email", cta = "Notify me" }


modelDoc : Model msg
modelDoc =
    { form = formDoc
    , title = "Sign up for our newsletter"
    , description = "Anim aute id magna aliqua ad ad non deserunt sunt. Qui irure qui Lorem cupidatat commodo. Elit sunt amet fugiat veniam occaecat fugiat."
    , legalText = [ text "We care about the protection of your data. Read our ", a [ href "#", css [ Tw.font_medium, Tw.underline ] ] [ text "Privacy Policy." ] ]
    }


doc : Chapter x
doc =
    chapter "Newsletter"
        |> renderComponentList
            [ ( "basicSlice", basicSlice modelDoc )
            , ( "centered", centered modelDoc.form )
            , ( "small", small modelDoc.form )
            ]
