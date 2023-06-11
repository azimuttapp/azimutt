import {AzimuttSchema} from "./schema";

export interface Parser {
    name: string
    parse(content: string): AzimuttSchema
}
