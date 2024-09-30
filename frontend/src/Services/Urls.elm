module Services.Urls exposing (amlDocs, amlEditor, amlHome, amlV1Converter, cliNpm, pricing)


amlHome : String
amlHome =
    "/aml"


amlDocs : String
amlDocs =
    "https://github.com/azimuttapp/azimutt/blob/main/libs/aml/docs/README.md"


amlEditor : String
amlEditor =
    "/converters/aml/to/json"


amlV1Converter : String
amlV1Converter =
    "/converters/amlv1/to/aml"


cliNpm : String
cliNpm =
    "https://www.npmjs.com/package/azimutt"


pricing : String
pricing =
    "/pricing"
