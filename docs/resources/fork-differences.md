# Differences from upstream

This fork keeps Jabby's scheduler model generic while adding one optional
nested grouping level.

## Scheduler hierarchy

Upstream Jabby exposes a `phase` field and renders it as a collapsible group.
Jabby does not execute scheduler phases itself, so this fork replaces that UI
concept with two generic presentation fields:

```luau
type SystemData = {
    category: string?,
    subcategory: string?,
    name: string,
    layout_order: number,
    paused: boolean
}
```

Registering a system with both fields:

```luau
local id = scheduler:register_system({
    category = "Movement",
    subcategory = "Sprint",
    name = "Prediction"
})
```

renders this hierarchy:

```text
Movement
└── Sprint
    └── Prediction
```

Both grouping fields are optional. A system without a subcategory appears
directly beneath its category, and a system without either field appears at the
scheduler root.

## Planck mapping

Planck integrations should translate execution metadata at the adapter
boundary:

```luau
jabby_scheduler:register_system({
    category = tostring(system_info.phase),
    subcategory = system_info.category,
    name = system_info.name
})
```

The Planck phase remains a real execution phase inside Planck. Jabby receives
only the generic category structure it needs for presentation.

## Animated tree UI

Subcategories are rendered as indented Vide tree nodes with animated chevrons,
height transitions, and low-contrast hierarchy guides. Closing a subcategory
clips its children while its height springs down to the header height, so it
does not leave unused space in the scheduler list.

## RunService schedule labels

Scheduler systems may provide one or more optional schedule names:

```luau
local id = scheduler:register_system({
    category = "Visual",
    name = "FirstPerson",
    schedules = { "PreRender" }
})
```

When a category is collapsed, its header displays the distinct schedules used
by its systems, such as `Visual (PreRender, Heartbeat)`. Expanding the category
hides that summary from the header and displays each system's own schedule next
to its name instead. Schedule labels use the disabled typography color so they
remain visually secondary.

The field is generic metadata: Jabby does not require Planck or RunService.
Scheduler adapters are responsible for discovering and supplying schedule
names when they can do so automatically.

## GitHub installation

The `main` branch contains the original Luau source together with a root
`package.json`, generated Luau output, and TypeScript declarations. Luau users
can consume or download the source normally, while roblox-ts users can install
the same branch directly through Bun:

```json
"@rbxts/jabby": "github:Loner1536/jabby#main"
```

The development Rojo project uses the non-default filename
`jabby.project.json`. This prevents Rojo from replacing the compiled package
with raw source when the Git repository is installed under `node_modules`.
