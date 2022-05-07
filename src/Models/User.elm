module Models.User exposing (User(..), UserInfos)


type User
    = Guest
    | Logged UserInfos


type alias UserInfos =
    { firstName : String, lastName : String, email : String, avatar : String }
