module Libs.Tailwind.Utilities exposing (bottom, cursor_cell, cursor_hand, cursor_hand_drag, duration, focusRing, focusWithin, focusWithinRing, font, h, left, link, max_h, noStyle, right, scale, stroke_3, text_muted, top, translate_x, translate_x_y, translate_y, underline_dotted, unless, w, when, z, z_max)

import Css
import Libs.Models exposing (Millis)
import Libs.Models.Color as Color exposing (Color, ColorLevel)
import Tailwind.Utilities as Tw


focusWithin : List Css.Style -> Css.Style
focusWithin =
    Css.pseudoClass "focus-within"


focusRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> Css.Style
focusRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Color.ring ringColor ringLevel, Color.ringOffset offsetColor offsetLevel ]


focusWithinRing : ( Color, ColorLevel ) -> ( Color, ColorLevel ) -> Css.Style
focusWithinRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    focusWithin [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, Color.ring ringColor ringLevel, Color.ringOffset offsetColor offsetLevel ]


noStyle : Css.Style
noStyle =
    Css.batch []


when : Bool -> List Css.Style -> Css.Style
when cond styles =
    Css.batch
        (if cond then
            styles

         else
            []
        )


unless : Bool -> List Css.Style -> Css.Style
unless cond styles =
    Css.batch
        (if cond then
            []

         else
            styles
        )


font : Float -> String -> Css.Style
font x unit =
    Css.property "font-size" (String.fromFloat x ++ unit)


w : Float -> String -> Css.Style
w width unit =
    Css.property "width" (String.fromFloat width ++ unit)


h : Float -> String -> Css.Style
h height unit =
    Css.property "height" (String.fromFloat height ++ unit)


translate_x : Float -> String -> Css.Style
translate_x x unit =
    Css.property "--tw-translate-x" (String.fromFloat x ++ unit)


translate_y : Float -> String -> Css.Style
translate_y y unit =
    Css.property "--tw-translate-y" (String.fromFloat y ++ unit)


translate_x_y : Float -> Float -> String -> Css.Style
translate_x_y x y unit =
    Css.batch [ Css.property "--tw-translate-x" (String.fromFloat x ++ unit), Css.property "--tw-translate-y" (String.fromFloat y ++ unit) ]


scale : Float -> Css.Style
scale factor =
    Css.batch [ Css.property "--tw-scale-x" (String.fromFloat factor), Css.property "--tw-scale-y" (String.fromFloat factor) ]


top : Float -> String -> Css.Style
top x unit =
    Css.property "top" (String.fromFloat x ++ unit)


right : Float -> String -> Css.Style
right x unit =
    Css.property "right" (String.fromFloat x ++ unit)


bottom : Float -> String -> Css.Style
bottom x unit =
    Css.property "bottom" (String.fromFloat x ++ unit)


left : Float -> String -> Css.Style
left x unit =
    Css.property "left" (String.fromFloat x ++ unit)


underline_dotted : Css.Style
underline_dotted =
    Css.property "text-decoration-style" "dotted"


max_h : Float -> String -> Css.Style
max_h num unit =
    Css.property "max-height" (String.fromFloat num ++ unit)


z : Int -> Css.Style
z value =
    Css.property "z-index" (String.fromInt value)


z_max : Css.Style
z_max =
    Css.property "z-index" "10000"


duration : Millis -> Css.Style
duration millis =
    Css.property "transition-duration" (String.fromInt millis ++ "ms")


stroke_3 : Css.Style
stroke_3 =
    Css.property "stroke-width" "3"


cursor_cell : Css.Style
cursor_cell =
    Css.property "cursor" "cell"


cursor_hand : Css.Style
cursor_hand =
    Css.property "cursor" "url(\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAACFklEQVRYhe3WQUtUURjG8Z9zMx1TkoiimqmMMG1RFBTRNiiYe2fTfvIDRLVp0b5Fn6FFiJ/CKUahRWsXKei4yixzKDBTW54W9w6FhJbOBME8cBfvey/n/Z/nPeeeQ0cddfSfKkJP9nQj9y+K5rJihzCEt1jDQxxGbwbWtuK9uI+vWC4Wi3NTU1Pv8C3LvUEBB9oB0I2jWJ+enl4qFAoL5XJ5LoQQEGq12nKxWJzFUxyRtqalbcnjDEIIISRJMh/H8UITIIQQyuXyLILUjQdSx1oG0Y/hZrE4jutxHNd/BUiSZL5QKCzWarUlrEsd624VwABGdwKI47ieJMl8Myd1LL/fwjkcxDFcaRarVCqLlUplMYQQoiha257LAIalzu1ZkXTLPc8GnGkC7Kbs+1Gpc3tWL25FUfSp0WhsjI2NzWHrLwAu7hegH0kURY3mwJOTk6v/GuA8Xubz+Y8rKyvf/8j/FrfgJK7jBbaq1equDkxMTLzHBi5owSIcwFncwLOurq4vu0EkSTKPVziHvv0AkP7XB3Aa1/BoJ4hqtbqKTdyVutezXwB+bsdTuIon2CyVSvWZmZm1EEIYHx//UCqV6lnxxxjBoBaejjmpnSdwGffwGp+lC24ziyu4hONaNPvtEPls8BHcxG3EuJPFo9n7vDZdUnLSmQ1Kezwk3apDWTyoDUfx79S8kvVJ10dfFrftRtRRR23TD6DuuSjLpoGNAAAAAElFTkSuQmCC\") 15 15, auto !important"


cursor_hand_drag : Css.Style
cursor_hand_drag =
    Css.property "cursor" "url(\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAB3ElEQVRYhe2WQWvTYBjHf2moWztlHsbEmTAUUYcgelDQD6CQJhfvbw5eBzv5HbwV/QSln6KhtGVevI0epNh2J7UKEwd1W70+Ht4nsotOTeIpPwgh7+X/e54ned9ASUlJScm/4QJLelWByv8IrWjYCnAVeAvMgR1gFVhWscLCl4Ft4Bsw831/1O/33wPHuvZGxVYooCtVYA04GgwGHzzPm0RRNBIRAaTX68183x8BM5XZVuHcJGrAJiAiImEYjhuNxiQVEBGJomjked5Eu3KkwtU8wh3gInA7DTPG7Btj9kVEXNedi4jEcTyN4/inlArXsoans38G7KUCZ6ECN4DzWQXOAfeA42az+c4YM/4LgS3gQlaBOvAIOOl2u5//qPwCBDaBF8AiSZKDs8Lb7fZH4AS4SU4jWMeO4SXwvdPpfPmdQBiGY6ALXNMCMlHBbiw+8AB45TjO4a86kSTJAbAAngIb2K06My62lT5wH9hxHOcwCILpcDici4i0Wq1PQRBMNfw5cAv76ea2NbvYTlwB7gIG2AW+Yl+4BfBa1+8Al8ip+tNUsBvLOrbCh8BjoAE8wX4tWxpeo6AT0sFWtgpcxh4+1/W+gW37UlHhp0n/B+rY0dT1ubDjuKSkMH4AQppUcJnHZMwAAAAASUVORK5CYII=\") 15 15, auto !important"



-- Generic styles


text_muted : Css.Style
text_muted =
    Css.batch [ Tw.text_sm, Tw.text_gray_500 ]


link : Css.Style
link =
    Css.batch [ Tw.underline, Tw.cursor_pointer ]
