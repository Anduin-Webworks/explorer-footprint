# Development workflows

## Add a setting

1. Add its default to `Config.lua`.
2. Add its English label and tooltip to `Localization.lua`.
3. Register it in `Options.lua`.
4. Decide whether changing it requires an immediate map refresh.
5. Document it in [Reference](../reference/index.md) and the changelog if user-visible.

## Change persisted data

1. Describe the old and new shapes.
2. Increment the schema version.
3. Add an explicit migration in `Database.lua`.
4. Keep malformed-data handling safe.
5. Test first-run, upgrade, reload, and reset paths in Retail.

## Change map rendering

1. Keep persisted counts independent of visual choices.
2. Confirm the current MapCanvas API and pin template behavior.
3. Reuse `RemoveAllPinsByTemplate` before repopulating owned pins.
4. Test map changes, zoom, pan, map resize, and interaction with Blizzard pins.

## Release checklist

- Update `## Version` in `ExplorerFootprint.toc`.
- Add a Semantic Versioning entry to `CHANGELOG.md`.
- Update the supported interface number when required.
- Run static checks and `git diff --check`.
- Test in a clean Retail client profile and with existing SavedVariables.
- Update relevant user/developer documentation.
