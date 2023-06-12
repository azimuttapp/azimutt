import {AzimuttSchema, Parser} from "@azimutt/database-types";
import {formatSchema, parseSchema} from "./prisma";

export const prisma: Parser = {
    name: 'Prisma',
    parse: (content: string): Promise<AzimuttSchema> => parseSchema(content).then(formatSchema)
}
