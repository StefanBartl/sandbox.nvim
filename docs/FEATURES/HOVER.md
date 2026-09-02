# Hover

An image reference in a `Dockerfile` or a `compose.yml` is a question the file
cannot answer: is `nginx:1.27-alpine` pulled, how big is it, is anything
running from it. The engine knows all three. This wires that answer to the
cursor, through [hover.nvim](https://github.com/StefanBartl/hover.nvim).

- **Module:** `sandbox/hover.lua`
- **Config:** `opts.hover` (default `true`; a no-op when hover.nvim is absent)
- **Trigger:** `:Hover show`, or whatever key you have bound to it — **never**
  the automatic one

```dockerfile
FROM nginx:1.27-alpine
```

```
┌ nginx:1.27-alpine ──────────────┐
│ not pulled                      │
│                                 │
│ `:Sandbox images pull` fetches  │
│ it.                             │
└─────────────────────────────────┘
```

```
┌ lazyvim_starter:latest ─────────┐
│ pulled  ·  505MB                │
│ id      ·  d7445529dfff         │
│                                 │
│ 1 container:                    │
│   exited     mystifying_shtern  │
└─────────────────────────────────┘
```

## Why it is on request only

Starting an engine is expensive, and no amount of care inside this module
changes that. Measured end to end against a live docker engine, keypress to
rendered float:

| reference | answer | duration | engine calls |
| --- | --- | --- | --- |
| `alpine:edge` | pulled, no container | 754 ms | 2 |
| `lazyvim_starter:latest` | pulled, 1 container | 560 ms | 2 |
| `nginx:1.27-alpine` | not pulled | 286 ms | 1 |
| `init.lua:42` | declined | 1 ms | 0 |

hover.nvim's automatic trigger fires after every keystroke followed by a
pause. Half a second of it would be a stutter, not a feature — and one nobody
would trace back to this plugin. So the contribution is registered with
hover.nvim's `on_request` flag, which means it is consulted for an explicit
request and skipped entirely otherwise. Every row above measured `false` on
the automatic path.

The 286 ms row is also why the container listing is a second call made only
when the image was found: **"not pulled" is the complete answer on its own**,
and paying another 270 ms to add nothing to it would be the mistake this whole
module is arranged around.

If your hover.nvim predates `on_request`, this declines to register at all
rather than registering something that would stutter. It checks by behaviour —
a registry that silently ignored an unknown key would look identical to one
that honours it — by registering a probe that must not be called, exercising
the automatic path once, and asking whether it stayed quiet.

## The collision worth knowing about

`nginx:1.27` and `init.lua:42` are the same shape, and hover.nvim's bare-path
resolver already splits on that colon. Two things keep them apart, and the
first does most of the work:

1. **A position preview is asked only after every source *and* the bare-path
   resolver declined.** `init.lua:42` resolves as a file with a line number
   and never reaches this module.
2. **The last component of the name must not carry an extension.** `init.lua`
   does; `nginx` does not, and neither does the `img` in `ghcr.io/user/img`.
   A registry host's dots sit in an earlier component and are left alone.

The second test runs before any process is started, which is the point: a file
reference is declined for free, and that is the 1 ms row in the table.

A digest (`alpine@sha256:…`) is declined too. It is a different lookup, and
answering the easy half of it would be worse than not answering.

## When the engine cannot be reached

Silence — no float. A stopped daemon and a missing image are different facts,
and only one of them is known. Reporting "not pulled" because the engine could
not be asked would be a confident wrong answer, which is worse than none.

## Turning it off

```lua
require("sandbox").setup({ hover = false })
```

Or leave it on and never bind a key to `:Hover show` — nothing is consulted
until you ask.
