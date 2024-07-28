import {expect, test} from "@jest/globals";
import {Logger} from "@azimutt/utils";

export const logger: Logger = {
    debug: (text: string): void => console.debug(text),
    log: (text: string): void => console.log(text),
    warn: (text: string): void => console.warn(text),
    error: (text: string): void => console.error(text)
}
export const application = 'azimutt-tests'
export const oracleUsers = ['ANONYMOUS', 'APPQOSSYS', 'AUDSYS', 'CTXSYS', 'DBSFWUSER', 'DBSNMP', 'DGPDB_INT', 'DIP', 'DVF', 'DVSYS', 'GGSHAREDCAP', 'GGSYS', 'GSMADMIN_INTERNAL', 'GSMCATUSER', 'GSMROOTUSER', 'GSMUSER', 'LBACSYS', 'MDDATA', 'MDSYS', 'OJVMSYS', 'OLAPSYS', 'OPS$ORACLE', 'OUTLN', 'REMOTE_SCHEDULER_AGENT', 'SYS', 'SYS$UMF', 'SYSBACKUP', 'SYSDG', 'SYSKM', 'SYSRAC', 'SYSTEM', 'VECSYS', 'WMSYS', 'XDB', 'XS$NULL']

test('dummy', () => {
    expect(application).toEqual('azimutt-tests')
})
