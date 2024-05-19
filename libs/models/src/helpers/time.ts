export function formatMs(millis: number): string {
    if (millis > 2 * 365 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 365)} years`
    } else if (millis > 2 * 30 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 30)} months`
    } else if (millis > 2 * 7 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24 / 7)} weeks`
    } else if (millis > 2 * 24 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60 / 24)} days`
    } else if (millis > 2 * 60 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60 / 60)} hours`
    } else if (millis > 2 * 60 * 1000) {
        return `${Math.round(millis / 1000 / 60)} mins`
    } else if (millis > 10 * 1000) {
        return `${Math.round(millis / 1000)} secs`
    } else {
        return `${Math.round(millis)} ms`
    }
}
