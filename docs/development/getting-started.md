# Development setup

## Requirements

- A text editor.
- A World of Warcraft Retail installation for in-game testing.
- A Lua 5.1-compatible syntax checker or addon-aware editor extension is recommended.
- Optional: BugSack/BugGrabber or another error display addon for testing.

The repository does not currently define a package manager, build system, automated test runner, or dependency installation step.

## Local testing

1. Copy or link the repository directory into the Retail `Interface/AddOns` directory, using the installed folder name `ExplorerFootprint`.
2. Confirm the addon is enabled on the character-selection AddOns screen.
3. Use `/reload` after source changes.
4. Test outdoors, on the World Map, across map transitions, and in restricted content.
5. Check the chat output from `/footprint status`.

The exact Retail installation path is environment-specific and should not be committed to the repository.

## Static checks

Before committing:

- Check Lua syntax with an available Lua 5.1-compatible tool.
- Check the TOC file list and interface number.
- Check for accidental global variables.
- Run `git diff --check`.

Static checks cannot confirm Blizzard API behavior. In-game validation remains required.
