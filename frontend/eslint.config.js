// ESLint Flat Config —— 锁死 Vue 3 组合式 API 规范 + TypeScript 支持
import vue from 'eslint-plugin-vue'
import js from '@eslint/js'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...vue.configs['flat/recommended'],
  {
    files: ['**/*.vue', '**/*.ts', '**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      parserOptions: {
        parser: tseslint.parser,
        extraFileExtensions: ['.vue'],
      },
    },
    rules: {
      // Vue 3 组合式 API 规范：强制 <script setup>
      'vue/component-api-style': ['error', ['script-setup']],
      // 禁止 Options API 字段，锁定组合式 API
      'vue/no-restricted-component-options': [
        'error',
        ['data', 'methods', 'computed', 'watch', 'props', 'mounted', 'created'],
      ],
      // 组合式 API 相关最佳实践
      'vue/no-setup-props-reactivity-loss': 'error',
      'vue/no-watch-after-await': 'error',
      // 多词组件名（App.vue 已忽略）
      'vue/multi-word-component-names': 'error',
    },
  },
  {
    files: ['**/App.vue', '**/main.ts'],
    rules: {
      'vue/multi-word-component-names': 'off',
    },
  },
  {
    ignores: ['dist/**', 'node_modules/**'],
  }
)
