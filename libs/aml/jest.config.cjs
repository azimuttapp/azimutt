module.exports = {
    transform: {'^.+\\.ts$': 'ts-jest'},
    testEnvironment: 'node',
    testRegex: '/src/.+\\.test?\\.(ts|tsx)$',
    moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node']
}
