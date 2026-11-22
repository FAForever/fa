---
layout: page
title: Other snippets
parent: Development - Changelog
permalink: development/changelog/other-snippet
published: true
---

The content of a snippet that is not in the balance category is similar to a commit message. The first line is a title that starts with a dash followed by a concise description of the changes. Use a dot at the end of the first line. The remainder of the file can be used to provide additional and more detailed information about the changes. Remember to indent these additional lines, so they follow the indentation that gets created because of the list item of the first line. Mention the relevant pull requests at the end of the text like so: `(#PR1, #PR2, ...)`.
Add an empty line at the end of the file to make sure that the next snippet is separated by an empty line. You can make use of a Markdown formatter to ensure consistency, one example is the use of [prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode).

### Example snippet
```
- Tweak the formula used to calculate the level of detail (LOD) for props.

  Large props are visible for longer, and it should now be easier again to spot broken tree groups (#6906).

```
