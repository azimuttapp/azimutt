module Models.SqlScript exposing (SqlScript)


type alias SqlScript =
    -- a whole SQL script with several queries or even broken parts inside
    String
