export type SentryConf = { dsn: string }

export class Conf {
    static get(): Conf {
        return new Conf({dsn: 'https://268b122ecafb4f20b6316b87246e509c@o937148.ingest.sentry.io/5887547'})
    }

    constructor(public readonly sentry: SentryConf) {
    }
}
