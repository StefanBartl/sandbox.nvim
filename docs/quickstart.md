# Quickstart

Ask what is there:

```vim
:Sandbox container list
```

That opens a list view — a read-only scratch buffer where the entry under the
cursor is the argument for the buffer-local keys described in
[BINDINGS.md](BINDINGS.md#keymaps). Then:

```vim
:Sandbox image list        " the same shape, for images
:Sandbox compose up        " the compose file found in cwd or an ancestor
:Sandbox engine set        " switch engine mid-session
```

Every argument completes with `<Tab>`, resolved live against the running
engine rather than from a frozen list.

Verify your setup any time with:

```vim
:checkhealth sandbox
```

See [WORKFLOW.md](WORKFLOW.md) for how these commands combine into daily use,
and [BINDINGS.md](BINDINGS.md) for the full command tree.
