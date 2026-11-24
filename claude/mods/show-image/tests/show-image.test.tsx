import { expect, test } from 'claude-code/testing'
import { cellBox, decode, pngSize } from '../hooks/register'

const PNG_1x1 =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='

test('reads PNG size from IHDR', async () => {
  expect(pngSize(decode(PNG_1x1))).toEqual({ width: 1, height: 1 })
  expect(pngSize(new Uint8Array([1, 2, 3]))).toBe(null)
})

test('fits a wide diagram and keeps cells in range', async () => {
  const box = cellBox(1600, 200)
  expect(box.columns).toBe(100)
  expect(box.rows).toBe(6)
  expect(cellBox(784, 268).columns).toBe(49)
  expect(cellBox(4000, 300).columns).toBe(120)
  expect(cellBox(100, 5000).rows).toBe(40)
  expect(cellBox(10, 10, 300, 0).columns).toBe(255)
})

test('the tool reads the file and the row draws the image', async ($, on) => {
  on('tool.register', () => ({ value: { tool: 'mcp__show-image__show_image' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('fs.read', () => ({ value: { base64: PNG_1x1 } }))
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>row</Text>
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  const ran = await $.tool.call({
    tool: 'mcp__show-image__show_image',
    tool_use_id: 't1',
    path: '/tmp/x.png',
  } as never)
  expect(String((ran as { result?: unknown }).result)).toMatch(/Shown/)

  const ui = await $.ui.mount({
    plugin: 'show-image',
    component: 'ToolUse',
    requestId: 't1',
    surface: 'terminal',
    props: {
      tool_use_id: 't1',
      tool: 'mcp__show-image__show_image',
      input: { path: '/tmp/x.png' },
      isRunning: false,
      isErrored: false,
      isInterrupted: false,
      output: 'Shown',
    },
  } as never)
  expect((await ui.find({ type: 'Text', text: /row/ }))?.text).toBe('row')
  expect(await ui.find({ type: 'Image' })).toBeTruthy()
  await ui.unmount()
})
