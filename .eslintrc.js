module.exports = {
  env: {
    node: true,
    browser: true,
    commonjs: true,
    es6: true,
    jest: true
  },
  extends: ['standard'],
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
    BigInt: 'readonly'
  },
  parserOptions: {
    ecmaVersion: 2020
  },
  rules: {
    // Useful for curried functions as it allows the following:
    //   func
    //     (param1)
    //     (param2)
    // TODO: Looks like this doesn't actuallyy work, since `allowNewlines`
    // is only valid for ["error", "always"], which means that there always
    // has to be a space between function name and (), but what we'd like
    // is no space is func and () are on the same line while at the same time
    // allow () to be on the following line.
    // Disabling this rule doesn't do the trick since the we get an error from
    // `no-unexpected-multiline` which we don't want to disable as it catches
    // some common error in codebases which don't enforce ; at the end of line.
    // So to achieve what we want we'd have to create our own versions of
    // both func-call-spacing and no-unexpected-multiline, which combined
    // together would allow the above, without loosening other restrictions.
    // "func-call-spacing": ["error", "never", { "allowNewlines": true }]
    // Ignore unused vars for common utils to maintain presence in all files
    'no-unused-vars': ['error', { varsIgnorePattern: '^R$|^P$|^logger$' }]
  }
}
