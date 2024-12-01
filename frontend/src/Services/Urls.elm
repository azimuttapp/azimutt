module Services.Urls exposing (amlDocs, amlEditor, amlHome, amlV1Converter, cliNpm, pricing, vscodeExt)


amlHome : String
amlHome =
    "/aml"


amlDocs : String
amlDocs =
    "/docs/aml"


amlEditor : String
amlEditor =
    "/converters/aml/to/json"


amlV1Converter : String
amlV1Converter =
    "/converters/amlv1/to/aml"


cliNpm : String
cliNpm =
    "https://www.npmjs.com/package/azimutt"


vscodeExt : String
vscodeExt =
    "https://marketplace.visualstudio.com/items?itemName=azimutt.vscode-aml"


pricing : String
pricing =
    "/pricing"
