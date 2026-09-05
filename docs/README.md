# sandbox.nvim documentation

What is here, and which question each page answers. [The README](../README.md)
is the short version of all of it.

## Getting it running

| Page | Answers |
| --- | --- |
| [installation.md](installation.md) | What has to be there first — this plugin drives a container engine, so the prerequisites are most of the answer — and a spec per plugin manager |
| [configuration.md](configuration.md) | Every `setup()` option, its default, and what it trades against |
| [health.md](health.md) | Every line `:checkhealth sandbox` can print, and what to do about each |

## Using it

| Page | Answers |
| --- | --- |
| [BINDINGS.md](BINDINGS.md) | Everything is one user command; this is that command's full surface, plus the keymaps and autocommands |
| [GENERATED_COMMANDS.md](GENERATED_COMMANDS.md) | The same command tree as the composer generates it — machine-written, not hand-maintained, so it cannot drift from the source |
| [WORKFLOW.md](WORKFLOW.md) | The different question: not what each subcommand does, but how containers, images and volumes combine into a way of working |

## Why it is the way it is

| Page | Answers |
| --- | --- |
| [FEATURES/](FEATURES/README.md) | Ten pages, one per area — containers, images, volumes and networks, compose, devcontainers, the registry, the engines it can run on, WSL, the UI, and the hover integration |

## Working on it

| Page | Answers |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | What is expected of a change, and where each layer lives |
| [add_usecase.md](add_usecase.md) | How to add an operation — the one extension point with a recipe, walked from port to route to spec |
| [../TESTS/README.md](../TESTS/README.md) | Running the suite locally, and the shape of a new spec |
