# Contributing

## Principles

- Keep the addon Retail-only unless the project scope is explicitly expanded.
- Preserve the account-wide, local-only data model.
- Keep UI values centralized and localizable.
- Prefer public Blizzard APIs and current live FrameXML patterns.
- Do not claim runtime validation from static checks alone.

## Pull requests

Include:

- A concise description of the behavior change.
- The affected documentation.
- Static-check results.
- In-game test cases and the Retail build used, when available.
- SavedVariables migration notes for persisted-data changes.

Avoid committing local World of Warcraft installation paths, SavedVariables files, generated packaging output, or screenshots containing account information.

## Open questions

API behavior that cannot be confirmed from source or static inspection should be marked **Needs verification** and tested in-game before being treated as stable behavior.
