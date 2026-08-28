import { test, expect } from '@playwright/test'

/**
 * 前端冒烟测试：验证 Vue3 应用能启动并渲染出主标题。
 * 是 Playwright 前端验证 harness 的最小可用性检查（先验证 harness 本身能跑通）。
 */
test('应用启动并渲染主标题', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('main h1')).toHaveText('AI Agent Platform')
})