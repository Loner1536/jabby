# Loner1536/jabby

jabby is a debugger for [jecs](https://github.com/ukendio/jecs) based off [gorp](https://github.com/aloroid/gorp)

It's still in the early stages of development and is very experimental.

This fork is consumed directly from its `main` GitHub branch and is not
published to npm:

```json
{
    "dependencies": {
        "@rbxts/jabby": "github:Loner1536/jabby#main"
    }
}
```

See the [installation guide](./docs/resources/getting-started/1-install.md) and
[fork differences](./docs/resources/fork-differences.md) for details.

The source-only Rojo project is named `jabby.project.json` deliberately. Git
dependencies are mounted from `node_modules`, where a `default.project.json`
would override the compiled `out` package layout expected by roblox-ts.

## Differences from upstream

- Scheduler groups use generic `category` and `subcategory` metadata instead
  of presenting scheduler-specific `phase` metadata as a Jabby concept.
- Scheduler systems render as `category → subcategory → system`, with either
  grouping level remaining optional.
- Subcategories use an animated Vide tree view with indentation and subtle
  hierarchy guides.
- Collapsed subcategories animate to their header height and do not retain
  empty layout space.
- Scheduler categories summarize their systems' optional RunService schedules
  while collapsed. Expanding a category hides that summary and shows each
  system's schedule beside its name instead.
- The repository includes a roblox-ts-compatible package entry point and type
  declarations so Bun can install this branch directly from GitHub.
