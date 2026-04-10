---
layout: page
title: Balance snippet
parent: Development - Changelog
permalink: development/changelog/balance-snippet
published: true
---

_Information about how to structure a balance snippet_

The snippet file should be named `balance.<PR Number>.md`.

```
- (#<PR Number>) <Description>

  **<Formatted Unit Name> (<Blueprint ID>):**
  - <Section>
    - <Parameter Name>: <value before> --> <value after>
    - <Parameter Name>: <value before> --> <value after>
```

- PR Number: The number of the pull request on GitHub.
- Description: A 1-sentence summary of the changes and then a short explanation behind the reasoning for the changes.
- Formatted Unit Name: `<UnitName>: <Tech> <Unit Description>` For example: `Exodus: T2 Destroyer`. This is similar to the format visible in unit dbs and the in-game UI when hovering over a unit.
- Blueprint ID: Blueprint ID of the unit in uppercase.
- Section: An optional subheader to categorize parameters. Usually a blueprint subtable name (ex: Physics) or a weapon name.
- Parameter Name: The name for the value that was changed. It shouldn't be the exact blueprint field name; it should be a name that players can understand and formatted like normal text.
- Value before/after: The value before/after the change. If relevant, derived values like DPS can be put in parentheses after the value as such: `<damage> (<dps>) --> <damage> (<dps>)`.
