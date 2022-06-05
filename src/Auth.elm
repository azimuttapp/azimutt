module Auth exposing (User, beforeProtectedInit)

import ElmSpa.Page as ElmSpa
import Gen.Route as Route exposing (Route)
import Models.User as Models
import Request exposing (Request)
import Shared


type alias User =
    Models.User


beforeProtectedInit : Shared.Model -> Request -> ElmSpa.Protected User Route
beforeProtectedInit shared _ =
    case shared.user of
        Just user ->
            ElmSpa.Provide user

        Nothing ->
            ElmSpa.RedirectTo Route.Login
