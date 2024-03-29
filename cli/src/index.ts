#!/usr/bin/env node

import {Command} from "commander";
import chalk from "chalk";
import clear from "clear";
import figlet from "figlet";
// https://github.com/SBoudrias/Inquirer.js
import {errorToString, strictParseInt} from "@azimutt/utils";
import {version} from "./version.js";
import {logger} from "./utils/logger.js";
import {exportDbSchema} from "./export.js";
import {launchGateway} from "./gateway.js";
import {launchExplore} from "./explore.js";

clear()
logger.log(chalk.hex('#4F46E5').bold(figlet.textSync('Azimutt.app', {horizontalLayout: 'full'})))
logger.log(chalk.hex('#3f3f46')(version))
logger.log('')

// TODO: `azimutt infer --path ~/my_db` or `azimutt export --url ~/my_db` (no 'protocol://') => recursively list .json files and infer them as a collection
// TODO: use in-memory H2 to load liquibase & flyway migrations
const program = new Command()
program.name('azimutt')
    .description('Export database schema from relational or document databases. Import it to https://azimutt.app.\n' +
        '- export database schemas from PostgreSQL, MongoDB and Couchbase')
    .version(version)

program.command('gateway')
    .description('Launch the gateway server to allow Azimutt to access your local databases.')
    .action((args) => exec(launchGateway(logger), args))

program.command('explore')
    .description('Open Azimutt with your database url to see it immediately.')
    .argument('<url>', 'the database url, including credentials')
    .option('-i, --instance <instance>', 'the Azimutt instance you want to use, by default: https://azimutt.app')
    .action((url, args) => exec(launchExplore(url, args.instance || 'https://azimutt.app', logger), args))

program.command('export')
    .description('Export a database schema in a file to easily import it in Azimutt.\nWorks with BigQuery, Couchbase, MariaDB, MongoDB, MySQL, PostgreSQL, Snowflake..., issues and PR are welcome in https://github.com/azimuttapp/azimutt ;)')
    .argument('<url>', 'the url to connect to the source, including credentials')
    .option('-d, --database <database>', 'Limit to a specific database (ex for MongoDB)')
    .option('-s, --schema <schema>', 'Limit to a specific schema (ex for PostgreSQL)')
    .option('-b, --bucket <bucket>', 'Limit to a specific bucket (ex for Couchbase)')
    .option('-m, --mixed-collection <field>', 'When collection have mixed documents typed by a field')
    .option('--sample-size <number>', 'Number of items used to infer a schema', strictParseInt, 10)
    .option('--infer-relations', 'Infer relations using column names')
    .option('--ignore-errors', 'Do not stop export on errors, just log them')
    .option('--log-queries', 'Log queries when executing them')
    .option('-f, --format <format>', 'Output format', 'json')
    .option('-o, --output <output>', "Path to write the schema, ex: ~/azimutt.json")
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((url, args) => exec(exportDbSchema(url, args), args))

program.parse(process.argv)

if (!process.argv.slice(2).length) {
    program.outputHelp()
}

function exec(res: Promise<void>, args: any) {
    if (!args.debug) {
        res.catch(e => {
            logger.error(`Unexpected error: ${errorToString(e)}`)
            logger.log(`(use --debug option to see the full error)`)
        })
    }
}
