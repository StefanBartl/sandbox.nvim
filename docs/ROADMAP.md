# sandbox.nvim: Roadmap

This document tracks planned and proposed features for **sandbox.nvim**. It's a
mix of concrete next steps and longer-term ideas — a place to point
contributors at instead of "yeah, there's probably stuff to build."

Nothing here is a promise or a deadline. Items move up when someone (maybe
you!) picks them up. See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and
[`ADD_USECASE.md`](./ADD_USECASE.md) for how a use case is wired through the
hexagonal architecture (port → adapter → usecase → command route → optional
view) before starting on any item below.

Legend: 🔜 planned next · 💡 idea, not started · 🧪 needs design/discussion

---

Nothing queued right now — every item that was on this list has shipped. See
[`GENERATED_COMMANDS.md`](./GENERATED_COMMANDS.md) for the full live command
surface, or open a PR/issue with the next idea.

---

## Contributing an item

Picking something up:

1. Move its checkbox status if useful, or just open a PR — this file isn't
   gospel, it's a backlog.
2. Follow the port → adapter → usecase → route → (optional) view flow in
   [`ADD_USECASE.md`](./ADD_USECASE.md).
3. Implement for **both** Docker and Podman adapters where the port method
   applies to both — half-implemented engine parity is worse than not
   starting.
4. Update [`BINDINGS.md`](./BINDINGS.md) (and the README's feature list, if
   user-facing) alongside the code.
