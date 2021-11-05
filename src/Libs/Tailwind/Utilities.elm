module Libs.Tailwind.Utilities exposing (focusWithin)

import Css exposing (Style, pseudoClass)


focusWithin : List Style -> Style
focusWithin =
    pseudoClass "focus-within"
