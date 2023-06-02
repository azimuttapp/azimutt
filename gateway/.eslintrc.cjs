module.exports = {
  env: {node: true},
  parser: '@typescript-eslint/parser',
  parserOptions: {sourceType: 'module', ecmaVersion: 2022},
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/eslint-recommended',
    'plugin:@typescript-eslint/recommended',
  ],
  rules: {
    '@typescript-eslint/explicit-module-boundary-types': 0,
    '@typescript-eslint/camelcase': 0,
    '@typescript-eslint/no-var-requires': 0,
  },
};
