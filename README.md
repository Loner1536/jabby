# Loner1536/jabby

jabby is a debugger for [jecs](https://github.com/ukendio/jecs) based off [gorp](https://github.com/aloroid/gorp)

It's still in the early stages of development and is very experimental.

This fork is consumed directly from its `rbxts` GitHub branch and is not
published to npm or Wally:

```json
{
    "dependencies": {
        "@rbxts/jabby": "github:Loner1536/jabby#rbxts"
    }
}
```

See the [installation guide](./docs/resources/getting-started/1-install.md) and
[fork differences](./docs/resources/fork-differences.md) for details.

## Differences from upstream

- Scheduler groups use generic `category` and `subcategory` metadata instead
  of presenting scheduler-specific `phase` metadata as a Jabby concept.
- Scheduler systems render as `category → subcategory → system`, with either
  grouping level remaining optional.
- Subcategories use an animated Vide tree view with indentation and subtle
  hierarchy guides.
- Collapsed subcategories animate to their header height and do not retain
  empty layout space.
- The repository includes a roblox-ts-compatible package entry point and type
  declarations so Bun can install this branch directly from GitHub.
