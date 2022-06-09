import {Env} from "./types/basics";
import {SupabaseClientOptions} from "@supabase/supabase-js/src/lib/types";

export type SupabaseConf = { backendUrl: string, supabaseUrl: string, supabaseKey: string, options?: SupabaseClientOptions }
export type SplitbeeConf = { scriptUrl: string, apiUrl: string }
export type SentryConf = { dsn: string }

export class Conf {
    static get(env: Env): Conf {
        return new Conf(
            supabase[env],
            {scriptUrl: "https://azimutt.app/bee.js", apiUrl: "https://azimutt.app/_hive"},
            {dsn: 'https://268b122ecafb4f20b6316b87246e509c@o937148.ingest.sentry.io/5887547'})
    }

    constructor(public readonly supabase: SupabaseConf,
                public readonly splitbee: SplitbeeConf,
                public readonly sentry: SentryConf) {
    }
}

const supabase: { [env in Env]: SupabaseConf } = {
    dev: {
        backendUrl: 'https://azimutt-staging.onrender.com', // 'http://localhost:3000',
        supabaseUrl: 'https://ywieybitcnbtklzsfxgd.supabase.co', // 'http://localhost:54321',
        supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3aWV5Yml0Y25idGtsenNmeGdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTE5MjI3MzUsImV4cCI6MTk2NzQ5ODczNX0.ccfB_pVemOqeR4CwhSoGmwfT5bx-FAuY24IbGj7OjiE', // 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24ifQ.625_WdcF3KHqz5amU0x2X5WWHP-OEs_4qj0ssLNHzTs',
    },
    staging: {
        backendUrl: 'https://azimutt-staging.onrender.com',
        supabaseUrl: 'https://ywieybitcnbtklzsfxgd.supabase.co',
        supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3aWV5Yml0Y25idGtsenNmeGdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTE5MjI3MzUsImV4cCI6MTk2NzQ5ODczNX0.ccfB_pVemOqeR4CwhSoGmwfT5bx-FAuY24IbGj7OjiE',
    },
    prod: {
        backendUrl: 'https://api.azimutt.app',
        supabaseUrl: 'https://xkwctrduvpdgjarqzjkc.supabase.co',
        supabaseKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhrd2N0cmR1dnBkZ2phcnF6amtjIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTIwMjc0OTgsImV4cCI6MTk2NzYwMzQ5OH0.f5W1-tXT64Ih0TG7LDDxyfTJ6Jh9ta4slet8fnkumKo',
    }
}
