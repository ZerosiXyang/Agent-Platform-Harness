import { defineConfig } from '@playwright/test'

/**
 * Playwright E2E 配置（前端验证 harness）
 * - 自动拉起 Vite dev server（webServer）
 * - 仅装 chromium（Windows 侧已下载）
 *
 * 运行（Windows 侧）：
 *   cmd /c "cd /d D:\path\frontend && npx playwright test"
 * 调试（有头 / 慢速）：
 *   npx playwright test --headed
 */
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 30_000,
  retries: 0,
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
  webServer: {
    // 复用 frontend 自己的 vite dev server（端口对齐 vite.config / 默认 5173）
    command: 'npm run dev',
    port: 5173,
    reuseExistingServer: true,
    timeout: 60_000,
  },
})