local pebble = require(script.Parent.Parent.Parent.Parent.Parent.pebble)
local vide = require(script.Parent.Parent.Parent.Parent.Parent.vide)
local convert_units = require(script.Parent.Parent.Parent.Parent.modules.convert_units)
local types = require(script.Parent.Parent.Parent.Parent.modules.types)
local spawn_app = require(script.Parent.Parent.Parent.spawn_app)
local system_widget = require(script.Parent.Parent.system)
local stack_bar = require(script.Parent.stack_bar)

local create = vide.create
local indexes = vide.indexes
local values = vide.values
local changed = vide.changed
local source = vide.source
local derive = vide.derive
local spring = vide.spring

local CHEVRON_DOWN = "rbxassetid://10709790948"
local TREE_GUIDE_TRANSPARENCY = 0.82

type SystemId = number

type props = {
	host: Player | "server",
	vm: number,
	id: number,

	system_ids: () -> {[SystemId]: true},
	system_data: () -> {[SystemId]: types.SystemData},
	system_frames: () -> {[SystemId]: {types.SystemFrame}},

	pause_system: (SystemId) -> (),
	destroy: () -> ()

}

local function color(n: number)
	return Color3.fromHSV((0.15 * (n-1)) % 1, 1, 1)
end

local sort_by_options = {
	"Name",
	"Id",
	"Frame Time"
}

return function(props: props)

	local selected = source(0)
	local systems_query = source("")
	
	local sort_by = source(2)

	local max_frametime = derive(function()
		local max = 0
		for _, frames in props.system_frames() do
			local sum = 0

			for _, frame in frames do
				sum += frame.s
			end

			max = math.max(max, sum / #frames)
		end
		return max
	end)

	local map_categories_to_systems = derive(function()
		type Group = {
			all_systems: {number},
			systems: {number},
			subcategories: {[string]: {number}}
		}

		local categories: {[false | string]: Group} = {
			[false] = { all_systems = {}, systems = {}, subcategories = {} }
		}

		for id, data in props.system_data() do
			local category = data.category or false
			local group = categories[category]

			if group == nil then
				group = { all_systems = {}, systems = {}, subcategories = {} }
				categories[category] = group
			end
			table.insert(group.all_systems, id)

			if data.subcategory == nil then
				table.insert(group.systems, id)
				continue
			end

			group.subcategories[data.subcategory] = group.subcategories[data.subcategory] or {}
			table.insert(group.subcategories[data.subcategory], id)
		end

		return categories
	end)

	local function format_schedules(system_ids: {number})
		local seen = {}
		local schedules = {}

		for _, id in system_ids do
			local data = props.system_data()[id]
			if data == nil or data.schedules == nil then continue end

			for _, schedule in data.schedules do
				if seen[schedule] then continue end
				seen[schedule] = true
				table.insert(schedules, schedule)
			end
		end

		table.sort(schedules)
		if #schedules == 0 then return "" end
		return `({table.concat(schedules, ", ")})`
	end

	local function escape_rich_text(value: string)
		return string.gsub(value, "[&<>'\"]", {
			["&"] = "&amp;",
			["<"] = "&lt;",
			[">"] = "&gt;",
			["'"] = "&apos;",
			['"'] = "&quot;"
		})
	end

	local function format_schedule_label(name: string, schedules: string)
		if schedules == "" then return escape_rich_text(name) end
		local color = pebble.theme.fg_on_bg_low[0]():ToHex()
		return `{escape_rich_text(name)} <font color="#{color}">{escape_rich_text(schedules)}</font>`
	end

	local function system(id: number, show_schedules: boolean?)
		local gui_state = source(Enum.GuiState.Idle)

		local function frame_time()
			local sum = 0
			local frames = props.system_frames()[id]

			for _, frame in frames do
				sum += frame.s
			end

			return sum / #frames
		end

		local b = create "ImageButton" {
			Name = function()
				return props.system_data()[id].name
			end,
			Size = UDim2.new(1, 0, 0, 32),

			LayoutOrder = function()
				return if sort_by() == 3 then 1e9 - frame_time() * 1e8 else id
			end,

			BackgroundColor3 = function()
				return if gui_state() == Enum.GuiState.Press then
					pebble.theme.bg[-1]()
				elseif gui_state() == Enum.GuiState.Hover then
					pebble.theme.bg[6]()
				else
					pebble.theme.bg[3]()
			end,

			Visible = function()
				return not not string.match(props.system_data()[id].name, systems_query())
			end,

			changed("GuiState", gui_state),

			Activated = function()
				spawn_app.spawn_app(system_widget, {
					host = props.host,
					vm = props.vm,

					scheduler = props.id,
					system = id,
					name = props.system_data()[id].name
				})
			end,

			MouseButton2Click = function()
				props.pause_system(id)
			end,

			-- create a frame that ignores all rules!
			create "Folder" {
				create "Frame" {
					Position = UDim2.new(0, 0, 1, 4),
					AnchorPoint = Vector2.new(0, 1),
					Size = function()
						return UDim2.new(frame_time() / max_frametime(), 0, 0, 1)
					end,

					BackgroundColor3 = pebble.theme.fg_on_bg_high[0]

				}
			},

			create "UIStroke" {
				Color = pebble.theme.bg[-3]
			},

			create "UICorner" {
				CornerRadius = UDim.new(0, 4)
			},

			create "UIListLayout" {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly,
				Padding = UDim.new(0, 8)
			},

			pebble.padding {
				x = UDim.new(0, 8)
			},

			create "Frame" {
				Size = UDim2.fromOffset(16, 16),
				AnchorPoint = Vector2.new(0.5, 0.5),

				BackgroundColor3 = color(id),

				create "UICorner" {
					CornerRadius = UDim.new(1, 0)
				},
			},

			pebble.typography {
				automaticsize = Enum.AutomaticSize.None,
				text = function()
					local name = props.system_data()[id].name
					local schedules = if show_schedules == false then "" else format_schedules({ id })
					return format_schedule_label(name, schedules)
				end,

				truncate = Enum.TextTruncate.SplitWord,
				xalignment = Enum.TextXAlignment.Left,
				disabled = function()
					return props.system_data()[id].paused
				end,

				{ RichText = true },

				create "UIFlexItem" {
					FlexMode = Enum.UIFlexMode.Fill,
					GrowRatio = 1,
					ShrinkRatio = 1
				}
			},

			pebble.typography {
				automaticsize = Enum.AutomaticSize.XY,
				text = function()
					local sum = 0
					local frames = props.system_frames()[id]

					for _, frame in frames do
						sum += frame.s
					end

					return `{convert_units("s", sum / #frames)}`
				end,

				xalignment = Enum.TextXAlignment.Right,

				disabled = true,

			},

		}
		return b
	end

	local function subcategory(systems: () -> {number}, name: string)
		local expanded = source(false)
		local content_size = source(Vector2.zero)
		local content_height = spring(function()
			return if expanded() then content_size().Y else 0
		end, 0.12)

		return pebble.container {
			Name = name,
			Size = function()
				local height = content_height()
				return UDim2.new(1, 0, 0, 32 + height + math.min(height, 8))
			end,
			ClipsDescendants = true,

			create "Folder" {
				create "Frame" {
					Name = "CategoryGuide",
					Position = UDim2.fromOffset(7, 0),
					Size = UDim2.fromOffset(1, 16),
					BackgroundColor3 = pebble.theme.fg_on_bg_low[0],
					BackgroundTransparency = TREE_GUIDE_TRANSPARENCY,
					BorderSizePixel = 0
				},

				create "Frame" {
					Name = "CategoryBranch",
					Position = UDim2.fromOffset(7, 15),
					Size = UDim2.fromOffset(9, 1),
					BackgroundColor3 = pebble.theme.fg_on_bg_low[0],
					BackgroundTransparency = TREE_GUIDE_TRANSPARENCY,
					BorderSizePixel = 0
				},

				create "Frame" {
					Name = "SubcategoryGuide",
					Position = UDim2.fromOffset(23, 32),
					Size = function()
						return UDim2.fromOffset(1, content_height() + math.min(content_height(), 8))
					end,
					BackgroundColor3 = pebble.theme.fg_on_bg_low[0],
					BackgroundTransparency = TREE_GUIDE_TRANSPARENCY,
					BorderSizePixel = 0
				}
			},

			create "ImageButton" {
				Name = "Category",
				Position = UDim2.fromOffset(16, 0),
				Size = UDim2.new(1, -16, 0, 32),
				BackgroundColor3 = pebble.theme.bg[2],

				pebble.padding { x = UDim.new(0, 8) },

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8)
				},

				create "UICorner" {
					CornerRadius = UDim.new(0, 6)
				},

				create "ImageLabel" {
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Image = CHEVRON_DOWN,
					Rotation = spring(function()
						return if expanded() then 180 else 0
					end, 0.12)
				},

				pebble.typography {
					size = UDim2.fromScale(0, 1),
					text = function()
						local schedules = format_schedules(systems())
						return format_schedule_label(name, if expanded() then "" else schedules)
					end,
					xalignment = Enum.TextXAlignment.Left,

					{ RichText = true },

					create "UIFlexItem" {
						FlexMode = Enum.UIFlexMode.Fill
					}
				},

				Activated = function()
					expanded(not expanded())
				end
			},

			pebble.container {
				Name = "Systems",
				Position = UDim2.fromOffset(32, 40),
				Size = function()
					return UDim2.new(1, -32, 0, content_height())
				end,
				ClipsDescendants = true,

				pebble.container {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 8),

						SortOrder = function()
							return if sort_by() == 1 then Enum.SortOrder.Name else Enum.SortOrder.LayoutOrder
						end
					},

					values(systems, function(id)
						return system(id, true)
					end),
					changed("AbsoluteSize", content_size)
				}
			}
		}
	end

	local function category(group: () -> {
		all_systems: {number},
		systems: {number},
		subcategories: {[string]: {number}}
	}, name: string)
		local expanded = source(false)
		local gui_state = source(Enum.GuiState.Idle)
		local content_size = source(Vector2.zero)

		return pebble.container {
			Name = name,
			Size = spring(function()
				if not expanded() then return UDim2.new(1, 0, 0, 32) end
				return UDim2.new(1, 0, 0, 40 + content_size().Y)
			end, 0.1),
			ClipsDescendants = true,

			create "ImageButton" {
				Name = "Category",
				AutoLocalize = false,
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = spring(function()
					return if gui_state() == Enum.GuiState.Press then
						pebble.theme.bg[-1]()
					elseif gui_state() == Enum.GuiState.Hover then
						pebble.theme.bg[3]()
					else
						pebble.theme.bg[0]()
				end, 0.1),

				pebble.padding { x = UDim.new(0, 8) },

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8)
				},

				create "UICorner" {
					CornerRadius = UDim.new(0, 8)
				},

				create "ImageLabel" {
					Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1,
					Image = CHEVRON_DOWN,
					Rotation = spring(function()
						return if expanded() then 180 else 0
					end, 0.1)
				},

				pebble.typography {
					size = UDim2.fromScale(0, 1),
					text = function()
						local schedules = format_schedules(group().all_systems)
						return format_schedule_label(name, if expanded() then "" else schedules)
					end,
					truncate = Enum.TextTruncate.SplitWord,
					xalignment = Enum.TextXAlignment.Left,

					{ RichText = true },

					create "UIFlexItem" {
						FlexMode = Enum.UIFlexMode.Fill
					}
				},

				Activated = function()
					expanded(not expanded())
				end,

				changed("GuiState", gui_state)
			},

			pebble.container {
				Name = "Children",
				Position = UDim2.fromOffset(0, 40),
				Size = function()
					return UDim2.new(1, 0, 0, content_size().Y)
				end,
				ClipsDescendants = true,

				pebble.container {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,

					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 8),
						SortOrder = function()
							return if sort_by() == 1 then Enum.SortOrder.Name else Enum.SortOrder.LayoutOrder
						end
					},

					values(function()
						return group().systems
					end, function(id)
						return system(id, true)
					end),

					indexes(function()
						return group().subcategories
					end, subcategory),

					changed("AbsoluteSize", content_size)
				}
			}
		}
	end

	return pebble.widget {
		title = "Scheduler",
		subtitle = `host: {props.host} vm: {props.vm} id: {props.id}`,

		min_size = Vector2.new(200, 300),

		bind_to_close = props.destroy,

		create "Frame" {
			Name = "Elements",
			Size = UDim2.fromScale(1, 1),
			AutomaticSize = Enum.AutomaticSize.Y,

			BackgroundTransparency = 1,

			create "UIListLayout" {
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				FillDirection = Enum.FillDirection.Vertical,
				VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
				Padding = UDim.new(0, 8)
			},

			create "Frame" {
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,

				BackgroundTransparency = 1,

				-- create "UIFlexItem" {
				-- 	FlexMode = Enum.UIFlexMode.Custom,
				-- 	GrowRatio = 0,
				-- 	ShrinkRatio = 0
				-- },

				pebble.pane {
					name = "Overview",
					size = UDim2.fromScale(1, 0),
		
					create "UIListLayout" {
						FillDirection = Enum.FillDirection.Vertical
					},
	
					pebble.typography {
						text = function()
							local run_time = 0
							for id, frames in props.system_frames() do
								if props.system_data()[id].paused then continue end
								local sum = 0

								for _, frame in frames do
									sum += frame.s
								end

								run_time += sum / #frames
							end
	
							return `Run time: {convert_units("s", run_time)}`
						end
					},
	
					stack_bar {
						values = function()
							local v = {}
	
							local system_ids = props.system_ids()
							local system_frames = props.system_frames()
	
							for i = 1, table.maxn(system_ids) do
								if system_ids[i] == nil then continue end
								if props.system_data()[i].paused then continue end

								local sum = 0
								local frames = system_frames[i]

								for _, frame in frames do
									sum += frame.s
								end
	
								table.insert(v, {value = sum / #frames, color = color(i)})
							end
	
							return v
						end,
						selected = selected
					},

					pebble.row {
						justifycontent = Enum.UIFlexAlignment.Fill,
						pebble.button {
							text = "Pause all",

							activated = function()
								for system, data in props.system_data() do
									if data.paused then continue end
									props.pause_system(system)
								end
							end
						},

						pebble.button {
							text = "Resume all",

							activated = function()
								for system, data in props.system_data() do
									if not data.paused then continue end
									props.pause_system(system)
								end
							end
						}
					}
				},

			},

			pebble.select {
				size = UDim2.new(1, 0, 0, 30),

				options = sort_by_options,
				selected = sort_by,
				update_selected = function(new)
					-- print(new)
					sort_by(new)
				end
			},

			pebble.textfield {
				size = UDim2.new(1, 0, 0, 36),

				placeholder = "System Match",
				
				oninput = systems_query,
			},

			create "ScrollingFrame" {
				Name = "Systems",

				Size = UDim2.fromScale(1, 0),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,

				BackgroundTransparency = 1,

				ScrollBarThickness = 6,
				VerticalScrollBarInset = Enum.ScrollBarInset.Always,
				ScrollBarImageColor3 = pebble.theme.fg_on_bg_low[3],

				create "UIFlexItem" {
					FlexMode = Enum.UIFlexMode.Fill
				},

				create "UIListLayout" {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 8),

					SortOrder = function()
						return if sort_by() == 1 then Enum.SortOrder.Name else Enum.SortOrder.LayoutOrder
					end
				},

				pebble.padding {
					y = UDim.new(0, 1),
					x = UDim.new(0, 1)
				},

				values(function()
					return map_categories_to_systems()[false].systems
				end, function(id)
					return system(id, true)
				end),

				indexes(map_categories_to_systems, function(group, name)
					if name == false then return {} end
					return category(group, name)
				end),

			}

		}

	}

end
