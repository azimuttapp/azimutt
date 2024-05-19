import {expect, test} from "@jest/globals";
import {RuleConf, RuleLevel} from "./rule";

export const ruleConf: RuleConf = {level: RuleLevel.enum.medium}

test('dummy', () => {
    expect(1 + 1).toEqual(2)
})
