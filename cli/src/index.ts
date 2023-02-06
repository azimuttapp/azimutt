#!/usr/bin/env node

import {Command} from "commander";
import chalk from "chalk";
import {exportDbSchema} from "./export";
import {parseUrl} from "./utils/database";
import {error, log} from "./utils/logger";
import {safeParseInt} from "./utils/number";
import {errorToString} from "./utils/error";

const clear = require('clear')
const figlet = require('figlet')
// https://github.com/SBoudrias/Inquirer.js

clear()
log(chalk.hex('#4F46E5').bold(figlet.textSync('Azimutt.app', {horizontalLayout: 'full'})))

const program = new Command()
program.name('azimutt')
    .description('Adding new capabilities to https://azimutt.app \\o/')
    .version('0.0.1')

program.command('export')
    .description('Export a database schema in a file to easily import it in Azimutt.\nWorks with PostgreSQL, MongoDB & Couchbase, issues and PR are welcome in https://github.com/azimuttapp/azimutt ;)')
    .requiredOption('-u, --url <url>', 'Url of the database to connect to [required]')
    .option('-k, --kind <kind>', "Database kind, when not inferred from the url")
    .option('-d, --database <database>', 'Limit to a specific database (ex for MongoDB)')
    .option('-s, --schema <schema>', 'Limit to a specific schema (ex for PostgreSQL)')
    .option('-b, --bucket <bucket>', 'Limit to a specific bucket (ex for Couchbase)')
    .option('--sample-size <number>', 'Number of items used to infer a schema', safeParseInt, 10)
    .option('--raw-schema', 'Generate an additional file specific to the database (more details)')
    .option('--flatten <number>', 'Make nested schema flat (useful as Azimutt does not handle nested structures for now)', safeParseInt, 0)
    .option('--infer-relations', 'Infer relations using column names')
    .option('-f, --format <format>', 'Output format', 'json')
    .option('-o, --output <output>', "Path to write the schema, ex: ~/azimutt.json")
    .option('--stack-trace', 'Show the full stacktrace instead of a more friendly error')
    .action(args => exec(exportDbSchema(parseUrl(args.url), args), args))

program.parse(process.argv)

if (!process.argv.slice(2).length) {
    program.outputHelp()
}

function exec(res: Promise<void>, args: any) {
    if (!args.stackTrace) {
        res.catch(e => error(chalk.red('Unexpected error: ' + errorToString(e))))
    }
}
