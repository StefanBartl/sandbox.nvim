# Around it

How sandbox.nvim's scope relates to a few plugins it is often used alongside.

**[reposcope.nvim](https://github.com/StefanBartl/reposcope.nvim)** clones a
repository into a directory, and sandbox.nvim picks up the `compose.yml` or
`.devcontainer/` that repository declares from the working directory or an
ancestor. So `up` and `devcontainer attach` work in the checkout you just
made, without configuring a path anywhere.

**[hover.nvim](https://github.com/StefanBartl/hover.nvim)** — an image
reference in a `Dockerfile` or `compose.yml` reports whether it is pulled,
how large it is, and which containers came from it. See
[FEATURES/HOVER.md](FEATURES/HOVER.md).

**[dap.nvim](https://github.com/StefanBartl/dap.nvim)** is the other half of
running code somewhere that is not your machine.

**[ui.nvim](https://github.com/StefanBartl/ui.nvim)** shows
`require("sandbox.statusline").status()` — `docker (2/5)` — as an ambient
segment of its statusline, through a thin adapter that reads the string and
adds nothing; the engine polling, its cache and its rate limit all stay
here, see [statusline.md](statusline.md). ui.nvim is also what draws this
plugin's context menu, which is why it is a hard dependency below.

All of the above are soft: without them everything else works unchanged.
[lib.nvim](https://github.com/StefanBartl/lib.nvim),
[ui.nvim](https://github.com/StefanBartl/ui.nvim) and a container engine
are the real dependencies — see [installation.md](installation.md#prerequisites).
