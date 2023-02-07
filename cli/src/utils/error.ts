import {UnambiguousTimeoutError} from "couchbase";

export function errorToString(e: any): string {
    if (e instanceof UnambiguousTimeoutError) {
        return e.message + '.\nMake sure you have access to the database, like no ip restriction or needed VPN.'
    } else if (e instanceof Error) {
        return e.message
    } else if (typeof e === 'string') {
        return e
    } else {
        return JSON.stringify(e)
    }
}
