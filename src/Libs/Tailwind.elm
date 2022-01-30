module Libs.Tailwind exposing (TwClass, bg_100, bg_400, bg_50, border_400, border_500, border_b_200, ring_500, stroke_400, stroke_500, text_500, text_800)

import Libs.Models.Color exposing (Color)


type alias TwClass =
    String



-- dynamic tailwind classes, add them also to tailwind.config.js safelist


bg_50 : Color -> TwClass
bg_50 color =
    "bg-" ++ color.name ++ "-50"


bg_100 : Color -> TwClass
bg_100 color =
    "bg-" ++ color.name ++ "-100"


bg_400 : Color -> TwClass
bg_400 color =
    "bg-" ++ color.name ++ "-400"


border_400 : Color -> TwClass
border_400 color =
    "border-" ++ color.name ++ "-400"


border_500 : Color -> TwClass
border_500 color =
    "border-" ++ color.name ++ "-500"


border_b_200 : Color -> TwClass
border_b_200 color =
    "border-b-" ++ color.name ++ "-200"


ring_500 : Color -> TwClass
ring_500 color =
    "ring-" ++ color.name ++ "-500"


stroke_400 : Color -> TwClass
stroke_400 color =
    "stroke-" ++ color.name ++ "-400"


stroke_500 : Color -> TwClass
stroke_500 color =
    "stroke-" ++ color.name ++ "-500"


text_500 : Color -> TwClass
text_500 color =
    "text-" ++ color.name ++ "-500"


text_800 : Color -> TwClass
text_800 color =
    "text-" ++ color.name ++ "-800"
