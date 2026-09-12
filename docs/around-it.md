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

All of the above are soft: without them everything else works unchanged.
[lib.nvim](https://github.com/StefanBartl/lib.nvim) and a container engine
are the real dependencies — see [installation.md](installation.md#prerequisites).
