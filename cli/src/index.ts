#!/usr/bin/env node

import {Command} from "commander";
import chalk from "chalk";
import clear from "clear";
import figlet from "figlet";
// https://github.com/SBoudrias/Inquirer.js
import {errorToString, strictParseInt} from "@azimutt/utils";
import {azimuttEmail} from "@azimutt/models";
import {version} from "./version.js";
import {logger} from "./utils/logger.js";
import {exportDbSchema} from "./export.js";
import {launchGateway} from "./gateway.js";
import {launchExplore} from "./explore.js";
import {launchAnalyze} from "./analyze.js";
import {launchDiff} from "./diff.js";
import {launchClustering} from "./clustering.js";
import {convertFile} from "./convert.js";

clear()
logger.log(chalk.hex('#4F46E5').bold(figlet.textSync('Azimutt.app', {horizontalLayout: 'full'})))
logger.log(chalk.grey('Version ' + version))
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
    .argument('[datasource_urls]', 'database urls to keep inside the gateway, including credentials')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((dataSourceUrls, args) => exec(launchGateway(dataSourceUrls, logger), args))

program.command('explore')
    .description('Open Azimutt with your database url to see it immediately.')
    .argument('<url>', 'the database url, including credentials')
    .option('-i, --instance <instance>', 'the Azimutt instance you want to use, by default: https://azimutt.app')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((url, args) => exec(launchExplore(url, args.instance || 'https://azimutt.app', logger), args))

program.command('analyze')
    .description('Analyze your database and give improvement suggestions.')
    .argument('<url>', 'the database url, including credentials')
    .option('--folder <folder>', 'where to read/write configuration and report files, default is ~/.azimutt/analyze/$db_name')
    .option('--email <email>', 'provide your professional email to get the full analyze report as a JSON file')
    .option('--size <number>', 'change shown violations limit per rule, default is 3', strictParseInt)
    .option('--only <rules>', 'limit analyze to specified rules')
    .option('--key <key>', `reach out to ${azimuttEmail} to buy a key for incremental rules: degrading queries, unused tables/indexes, fast growing tables/indexes and more...`)
    .option('--ignore-violations-from <folder-relative-path>', 'ignore violations present in existing report, path is relative to report folder, needs --key argument')
    .option('--html', 'get full analyze report as a HTML file')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((url, args) => exec(launchAnalyze(url, args, logger), args))

program.command('export')
    .description('Export a database schema in a file to easily import it in Azimutt.\nWorks with BigQuery, Couchbase, MariaDB, MongoDB, MySQL, PostgreSQL, Snowflake..., issues and PR are welcome in https://github.com/azimuttapp/azimutt ;)')
    .argument('<url>', 'the url to connect to the source, including credentials')
    .option('-d, --database <database>', 'Limit to a specific database (ex for MongoDB), works with LIKE syntax')
    .option('-c, --catalog <catalog>', 'Limit to a specific catalog (ex for Snowflake), works with LIKE syntax')
    .option('-s, --schema <schema>', 'Limit to a specific schema (ex for PostgreSQL), works with LIKE syntax')
    .option('-e, --entity <entity>', 'Limit to a specific entity (ex for PostgreSQL), works with LIKE syntax')
    .option('-b, --bucket <bucket>', 'Limit to a specific bucket (ex for Couchbase), works with LIKE syntax')
    .option('--sample-size <number>', 'Number of items used to infer a schema', strictParseInt, 10)
    .option('-m, --mixed-json <field>', 'When collection have mixed documents typed by a field')
    .option('--infer-json-attributes', 'Infer schema on json attributes')
    .option('--infer-polymorphic-relations', 'Infer polymorphic relations')
    .option('--infer-relations', 'Infer relations using column names')
    .option('--ignore-errors', 'Do not stop export on errors, just log them')
    .option('--log-queries', 'Log queries when executing them')
    .option('-f, --format <format>', 'Output format', 'json')
    .option('-o, --output <output>', "Path to write the schema, ex: ~/azimutt.json")
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((url, args) => exec(exportDbSchema(url, args), args))

program.command('convert')
    .description('A dialect to an other')
    .argument('<path>', 'The file to convert')
    .requiredOption('-f, --from <from>', 'The dialect of the file to convert from')
    .requiredOption('-t, --to <to>', 'The dialect to convert to')
    .option('-o, --out <out>', 'The file to write')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((path, args) => exec(convertFile(path, args), args))

program.command('diff')
    .description('Compare the schema of two databases')
    .argument('<url_old>', 'the old database url, including credentials')
    .argument('<url_new>', 'the new database url, including credentials')
    .option('-f, --format <format>', 'Output format: json, postgres', 'json')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((urlOld, urlNew, args) => exec(launchDiff(urlOld, urlNew, args, logger), args))

program.command('clustering')
    .description('WIP')
    .argument('<url>', 'the database url, including credentials')
    .option('--debug', 'Add debug logs and show the full stacktrace instead of a shorter error')
    .action((url, args) => exec(launchClustering(url, args, logger), args))

program.parse(process.argv)

if (!process.argv.slice(2).length) {
    program.outputHelp()
}

function exec(res: Promise<void>, args: any) {
    if (!args.debug) {
        res.catch(e => {
            logger.error(`Got error: ${errorToString(e)}`)
            logger.log(`(use --debug option to see the full error)`)
        })
    }
}
