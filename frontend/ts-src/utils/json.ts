import {errorToString} from "@azimutt/utils";

export function parse(value: string): any {
    try {
        return JSON.parse(value)
    } catch (e) {
        const v = value?.length > 20 ? value.slice(0, 20) + "..." : value
        throw `${JSON.stringify(v)} is not a valid JSON (${errorToString(e)})`
    }
}
