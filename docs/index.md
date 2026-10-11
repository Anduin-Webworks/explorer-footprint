# Explorer's Footprint documentation

Explorer's Footprint is a World of Warcraft Retail addon that records outdoor player movement locally and displays account-wide density on the World Map.

## Start here

- Users: [Getting started](user-guide/getting-started.md)
- Contributors: [Development setup](development/getting-started.md)
- Maintainers: [Architecture](development/architecture.md), [code structure](development/code-structure.md), and [data model](development/data-model.md)
- Exact settings, commands, and API boundaries: [Reference](reference/index.md)

## Documentation status

This documentation describes the implementation currently present in the repository. A behavior described as **Needs verification** requires in-game testing against the supported Retail build; it is not treated as a confirmed guarantee.

## Scope

The first version is intentionally local and small:

- Retail only.
- No external libraries or services.
- Account-wide SavedVariables.
- Sparse map-cell counts rather than raw movement history.
- Blizzard World Map overlay rather than a separate map window.
