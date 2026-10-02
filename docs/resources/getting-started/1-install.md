# Installation

This fork is installed directly from GitHub. It is not published to npm or
Wally.

## roblox-ts with Bun

Add the fork to your `package.json` dependencies:

```json
{
    "dependencies": {
        "@rbxts/jabby": "github:Loner1536/jabby#rbxts"
    }
}
```

Then install it:

```sh
bun install
```

Import it normally from roblox-ts:

```ts
import Jabby from "@rbxts/jabby";
```

Pinning `#rbxts` keeps installs on the branch containing the roblox-ts package
entry point, generated Luau output, and TypeScript declarations. Since this
fork is not published, dependency updates are pulled from that branch whenever
the lockfile is refreshed.

> [!NOTE]
> The upstream Wally and pesde installation instructions do not apply to this
> fork's roblox-ts branch.
