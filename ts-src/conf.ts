export type SplitbeeConf = { scriptUrl: string, apiUrl: string }
export type SentryConf = { dsn: string }

export class Conf {
    static get(): Conf {
        return new Conf(
            {scriptUrl: "https://azimutt.app/bee.js", apiUrl: "https://azimutt.app/_hive"},
            {dsn: 'https://268b122ecafb4f20b6316b87246e509c@o937148.ingest.sentry.io/5887547'})
    }

    constructor(public readonly splitbee: SplitbeeConf,
                public readonly sentry: SentryConf) {
    }
}
