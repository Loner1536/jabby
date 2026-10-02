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

## GitHub installation

The `rbxts` branch includes a root `package.json`, generated Luau output, and
TypeScript declarations. This makes the fork installable directly through Bun:

```json
"@rbxts/jabby": "github:Loner1536/jabby#rbxts"
```
