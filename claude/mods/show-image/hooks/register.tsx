import type { Register } from 'claude-code'

const TOOL = 'mcp__show-image__show_image'
const MAX_BYTES = 2 * 1024 * 1024
// Terminal cells are roughly twice as tall as wide.
const CELL_ASPECT = 2
// Device pixels per cell column on a HiDPI screen; sizing the box to this keeps
// the picture at its native resolution instead of stretching it.
const PX_PER_COL = 16

type Input = { path?: string; columns?: number; rows?: number; alt?: string }
type Shown = { png: string; columns: number; rows: number; alt: string }

/** base64 to bytes, without relying on Uint8Array.fromBase64 typings. */
export function decode(b64: string): Uint8Array {
  const bin = atob(b64)
  const out = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i)
  return out
}

const clamp = (n: number) => Math.max(1, Math.min(255, Math.round(n)))

/** Width and height from a PNG's IHDR chunk, or null if it is not a PNG. */
export function pngSize(bytes: Uint8Array): { width: number; height: number } | null {
  const sig = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
  if (bytes.length < 24 || sig.some((b, i) => bytes[i] !== b)) return null
  const v = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
  return { width: v.getUint32(16), height: v.getUint32(20) }
}

/** Cell box for an image: honour explicit sizes, else fit width and keep aspect. */
export function cellBox(width: number, height: number, cols?: number, rows?: number) {
  const ratio = height / width / CELL_ASPECT
  if (cols && rows) return { columns: clamp(cols), rows: clamp(rows) }
  if (rows) return { columns: clamp(rows / ratio), rows: clamp(rows) }
  let c = cols ?? Math.min(120, Math.max(20, width / PX_PER_COL))
  let r = c * ratio
  if (r > 40 && !cols) { r = 40; c = r / ratio }
  return { columns: clamp(c), rows: clamp(r) }
}

async function load($: any, input: Input): Promise<Shown | string> {
  if (!input.path) return 'path is required'
  let base64: string
  try {
    ;({ base64 } = await $.fs.read(input.path, { as: 'bytes' }))
  } catch (err) {
    return `cannot read ${input.path}: ${String(err)}`
  }
  const bytes = decode(base64)
  if (bytes.length > MAX_BYTES) return `${input.path} is ${bytes.length} bytes; the limit is 2 MiB`
  const size = pngSize(bytes)
  if (!size) return `${input.path} is not a PNG`
  const box = cellBox(size.width, size.height, input.columns, input.rows)
  return { png: base64, ...box, alt: input.alt || input.path }
}

export const register: Register = on => {
  const shown = new Map<string, Shown>()

  on('session.start', async ($, e, next) => {
    await $.tool.register({
      name: 'show_image',
      description:
        'Show a PNG image inline in the transcript, under this call, so the user sees it in their terminal. ' +
        'Use for rendered diagrams, charts or screenshots. For Mermaid, render sharp with `mmdc -i x.mmd -o x.png -b white -s 3`. ' +
        'PNG only, at most 2 MiB. columns/rows (terminal cells, 1-255) are optional; by default the box is ~1 column per 16 px (max 120 columns, 40 rows).',
      isDeferred: false,
      inputSchema: {
        type: 'object',
        properties: {
          path: { type: 'string', description: 'Path to a PNG file' },
          columns: { type: 'integer', minimum: 1, maximum: 255 },
          rows: { type: 'integer', minimum: 1, maximum: 255 },
          alt: { type: 'string', description: 'Short description, shown where images cannot be drawn' },
        },
        required: ['path'],
      },
    })
    return next(e)
  })

  on('tool.run', { tool: TOOL }, async ($, e) => {
    const r = await load($, e as unknown as Input)
    if (typeof r === 'string') return { deny: r }
    shown.set(e.tool_use_id, r)
    return { result: `Shown ${(e as unknown as Input).path} inline (${r.columns}x${r.rows} cells).` }
  }).catch(() => ({ deny: 'show-image failed to load the image' }))

  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const row = await next(e)
    const p = e.props
    if (p.tool !== TOOL || p.isRunning || p.isErrored || p.isInterrupted) return row
    let img = shown.get(p.tool_use_id)
    if (!img) {
      // After a reload or resume: read the file again.
      const r = await load($, (p.input ?? {}) as Input)
      if (typeof r === 'string') return row
      img = r
      shown.set(p.tool_use_id, r)
    }
    if (e.surface !== 'terminal') return row
    const { Box, Image } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {row}
        <Image source={{ png: img.png }} columns={img.columns} rows={img.rows} alt={img.alt} />
      </Box>
    )
  })
}
