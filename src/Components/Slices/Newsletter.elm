module Components.Slices.Newsletter exposing (Form, Model, basicSlice, doc, formDoc, small)

import Css exposing (focus, hover)
import ElmBook.Chapter exposing (chapter, renderComponentList)
import ElmBook.ElmCSS exposing (Chapter)
import Html.Styled exposing (Html, a, button, div, form, h2, input, label, p, text)
import Html.Styled.Attributes exposing (action, attribute, css, for, href, id, method, name, placeholder, required, target, type_)
import Tailwind.Breakpoints exposing (lg, sm)
import Tailwind.Utilities exposing (appearance_none, bg_indigo_600, bg_indigo_700, bg_white, border, border_gray_300, border_indigo_500, border_transparent, flex, flex_1, flex_col, flex_row, flex_shrink_0, font_extrabold, font_medium, inline_flex, items_center, justify_center, justify_end, max_w_3xl, max_w_7xl, max_w_xs, ml_3, ml_8, mt_0, mt_2, mt_3, mt_6, mt_8, mx_auto, outline_none, placeholder_gray_400, placeholder_gray_500, px_4, px_5, px_6, px_8, py_2, py_24, py_3, py_32, ring_1, ring_2, ring_indigo_500, ring_offset_2, rounded_md, shadow, shadow_sm, sr_only, text_3xl, text_4xl, text_base, text_gray_500, text_gray_900, text_lg, text_sm, text_white, underline, w_0, w_auto, w_full)


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
    div [ css [ bg_white ] ]
        [ div [ css [ max_w_7xl, mx_auto, py_24, px_4, lg [ py_32, px_8, flex, items_center ], sm [ px_6 ] ] ]
            [ div [ css [ lg [ w_0, flex_1 ] ] ]
                [ h2 [ css [ text_3xl, font_extrabold, text_gray_900, sm [ text_4xl ] ] ] [ text model.title ]
                , p [ css [ mt_3, max_w_3xl, text_lg, text_gray_500 ] ] [ text model.description ]
                ]
            , div [ css [ mt_8, lg [ mt_0, ml_8 ] ] ]
                [ form [ method model.form.method, action model.form.url, target "_blank", css [ sm [ flex ] ] ]
                    [ label [ for "newsletter-email", css [ sr_only ] ] [ text model.form.placeholder ]
                    , input [ type_ "email", name "member[email]", id "newsletter-email", attribute "autocomplete" "email", required True, css [ w_full, px_5, py_3, border, border_gray_300, shadow_sm, placeholder_gray_400, rounded_md, Css.focus [ ring_1, ring_indigo_500, border_indigo_500 ], sm [ max_w_xs ] ], placeholder model.form.placeholder ] []
                    , div [ css [ mt_3, rounded_md, shadow, sm [ mt_0, ml_3, flex_shrink_0 ] ] ]
                        [ button [ type_ "submit", css [ w_full, flex, items_center, justify_center, py_3, px_5, border, border_transparent, text_base, font_medium, rounded_md, text_white, bg_indigo_600, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ bg_indigo_700 ] ] ]
                            [ text model.form.cta ]
                        ]
                    ]
                , p [ css [ mt_3, text_sm, text_gray_500 ] ] model.legalText
                ]
            ]
        ]


small : Form -> Html msg
small model =
    form [ method model.method, action model.url, target "_blank", css [ mt_6, flex, flex_col, lg [ mt_0, justify_end ], sm [ flex_row ] ] ]
        [ div []
            [ label [ for "newsletter-email", css [ sr_only ] ] [ text model.placeholder ]
            , input [ type_ "email", name "member[email]", id "newsletter-email", attribute "autocomplete" "email", required True, css [ appearance_none, w_full, px_4, py_2, border, border_gray_300, text_base, rounded_md, text_gray_900, bg_white, placeholder_gray_500, focus [ outline_none, ring_indigo_500, border_indigo_500 ], lg [ max_w_xs ] ], placeholder model.placeholder ] []
            ]
        , div [ css [ mt_2, flex_shrink_0, w_full, flex, rounded_md, shadow_sm, sm [ mt_0, ml_3, w_auto, inline_flex ] ] ]
            [ button [ type_ "submit", css [ w_full, bg_indigo_600, px_4, py_2, border, border_transparent, rounded_md, flex, items_center, justify_center, text_base, font_medium, text_white, focus [ outline_none, ring_2, ring_offset_2, ring_indigo_500 ], hover [ bg_indigo_700 ], sm [ w_auto, inline_flex ] ] ]
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
    , legalText = [ text "We care about the protection of your data. Read our ", a [ href "#", css [ font_medium, underline ] ] [ text "Privacy Policy." ] ]
    }


doc : Chapter x
doc =
    chapter "Newsletter"
        |> renderComponentList
            [ ( "basicSlice", basicSlice modelDoc )
            , ( "small", small modelDoc.form )
            ]
