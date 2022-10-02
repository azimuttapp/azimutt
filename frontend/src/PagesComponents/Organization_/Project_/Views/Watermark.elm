module PagesComponents.Organization_.Project_.Views.Watermark exposing (viewWatermark)

import Conf
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (alt, class, height, src, width)
import Libs.Html exposing (extLink)
import Libs.Html.Attributes exposing (css)
import Services.Backend as Backend


viewWatermark : Html msg
viewWatermark =
    div [ class "az-watermark absolute bottom-0 left-0 m-3" ]
        [ extLink Conf.constants.azimuttWebsite
            [ class "flex justify-start items-center flex-shrink-0 grayscale opacity-50 hover:opacity-100" ]
            [ img [ class "block h-8 h-8", src (Backend.resourceUrl "/logo.png"), alt "Azimutt", width 32, height 32 ] []
            , span [ css [ "ml-3 text-2xl text-gray-500 font-medium" ] ] [ text "Azimutt" ]
            ]
        ]
