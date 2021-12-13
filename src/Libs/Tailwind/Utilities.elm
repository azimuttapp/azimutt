module Libs.Tailwind.Utilities exposing (focusRing, focusWithin, focusWithinRing, translate_x_y)

import Css exposing (Style, pseudoClass)
import Libs.Models.TwColor as TwColor exposing (TwColorPosition(..))
import Tailwind.Utilities as Tw


focusWithin : List Style -> Style
focusWithin =
    pseudoClass "focus-within"


focusRing : ( TwColor.TwColor, TwColor.TwColorLevel ) -> ( TwColor.TwColor, TwColor.TwColorLevel ) -> Style
focusRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    Css.focus [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring ringColor ringLevel, TwColor.render RingOffset offsetColor offsetLevel ]


focusWithinRing : ( TwColor.TwColor, TwColor.TwColorLevel ) -> ( TwColor.TwColor, TwColor.TwColorLevel ) -> Style
focusWithinRing ( ringColor, ringLevel ) ( offsetColor, offsetLevel ) =
    focusWithin [ Tw.outline_none, Tw.ring_2, Tw.ring_offset_2, TwColor.render Ring ringColor ringLevel, TwColor.render RingOffset offsetColor offsetLevel ]


translate_x_y : Float -> Float -> String -> Style
translate_x_y x y unit =
    Css.batch [ Css.property "--tw-translate-x" (String.fromFloat x ++ unit), Css.property "--tw-translate-y" (String.fromFloat y ++ unit) ]
