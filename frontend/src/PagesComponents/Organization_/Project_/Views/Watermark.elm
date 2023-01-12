module PagesComponents.Organization_.Project_.Views.Watermark exposing (viewWatermark)

import Conf
import Html exposing (Html, div, img)
import Html.Attributes exposing (alt, class, src)
import Libs.Html exposing (extLink)
import Services.Backend as Backend


viewWatermark : Html msg
viewWatermark =
    div [ class "az-watermark absolute bottom-0 left-0 m-3" ]
        [ extLink Conf.constants.azimuttWebsite
            [ class "flex justify-start items-center flex-shrink-0 grayscale opacity-50 hover:opacity-100" ]
            [ img [ class "block h-12 w-auto", src (Backend.resourceUrl "/logo_dark.svg"), alt "Azimutt" ] []
            ]
        ]
