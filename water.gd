extends Node2D

const BLOCKING_CELL = -1

var _grid_width = 30
var _grid_height = 30
var _cell_size = 16
# That grid contains the water levels of each cell.
# -1 means water can't penetrate.
var _grid = []
# Deferred results of one simulation (see tick() function)
var _actions = []
# how much liquid a cell can normally contain.
# It can be more but different rules may apply for the cell to reach back to a normal value.
var _cell_capacity = 8


func _ready():
	# Create grid
	_grid = []
	_grid.resize(_grid_height)
	for y in len(_grid):
		var row = []
		row.resize(_grid_width)
		for x in len(row):
			row[x] = 0
		_grid[y] = row


func get_cell(x, y):
	if x < 0 or y < 0 or x >= _grid_width or y >= _grid_height:
		return BLOCKING_CELL
	return _grid[y][x]


const _spread_dirs0 = [
	[0, 1],
	[-1, 0],
	[1, 0]
]
const _spread_dirs1 = [
	[0, 1],
	[1, 0],
	[-1, 0]
]


func _process(delta):
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		var pos = _world_to_grid(get_global_mouse_position())
		if _is_valid_pos(pos.x, pos.y):
			_grid[pos.y][pos.x] = _cell_capacity
	
	for i in 1:
		tick()


func tick():
	# Run the simulation and defer the results in a list of actions.
	# We do it that way because it allows each cell to be simulated from the same time frame.
	# If we did it immediately it would alter the results as we calculate them.
	for y in len(_grid):
		var row = _grid[y]
		for x in len(row):
			var cell = row[x]
			if cell > 0:
				
#				if cell == 1 and randi() % 50 == 0:
#					# Evaporate
#					_actions.append([x, y, -1])
#					continue
				
				var ncell_down = get_cell(x, y + 1)
				if ncell_down >= 0 and ncell_down < _cell_capacity:
					_actions.append([x, y, -1])
					_actions.append([x, y + 1, 1])
					cell -= 1
					continue
				
				var ncell_left = get_cell(x - 1, y)
				var ncell_right = get_cell(x + 1, y)
				
				if ncell_left == -1 and ncell_right == -1:
					continue
#				if ncell_left >= cell and ncell_right >= cell:
#					continue
				
				var could_evaporate = false
				if ncell_left == BLOCKING_CELL:
					if cell - ncell_right == 1:
						could_evaporate = true
				elif ncell_right == BLOCKING_CELL:
					if cell - ncell_left == 1:
						could_evaporate = true
				else:
					if cell - ncell_left == 1 or cell - ncell_right == 1:
						could_evaporate = true
				if could_evaporate and randi() % 30 == 0:
					_actions.append([x, y, BLOCKING_CELL])
					continue
				
				var dx = null
				if ncell_left < 0:
					dx = 1
				elif ncell_right < 0:
					dx = -1
				elif ncell_left == ncell_right:
					if randi() % 2 == 0:
						dx = 1
					else:
						dx = -1
				elif ncell_left > ncell_right:
					dx = 1
				else:
					dx = -1
				
				var ncell = get_cell(x + dx, y)
				if ncell >= cell or ncell == BLOCKING_CELL:
					continue
				
				_actions.append([x, y, -1])
				_actions.append([x + dx, y, 1])
				cell -= 1
				if cell <= 0:
					continue				

	# Apply actions
	for a in _actions:
		var x = a[0]
		var y = a[1]
		var d = a[2]
		var cell = _grid[y][x]
		cell += d
		_grid[y][x] = cell
	
	_actions.clear()
	
	# Trigger a redraw
	update()


func _world_to_grid(pos):
	return pos / _cell_size


func _is_valid_pos(x, y):
	return x >= 0 and y >= 0 and x < _grid_width and y < _grid_height


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			var pos = _world_to_grid(event.position)
			if not _is_valid_pos(pos.x, pos.y):
				return
			elif event.button_index == BUTTON_RIGHT:
				var v = BLOCKING_CELL
				if event.control:
					v = 0
				_grid[pos.y][pos.x] = v
			update()
	
	elif event is InputEventKey:
		if event.pressed:
			tick()


func _draw():
	for y in len(_grid):
		var row = _grid[y]
		for x in len(row):
			var cell = row[x]
			if cell == -1:
				draw_rect(Rect2(x * _cell_size, y * _cell_size, _cell_size, _cell_size), Color(0.5, 0.5, 0))
			elif cell > 0:
				var f = float(cell) / _cell_capacity
				var col = Color(0.5, 0.5, 1.0)
				if f > 1.0:
					col.r += f - 1.0
				f = clamp(f, 0.0, 1.0)
				if get_cell(x, y - 1) > 0:
					f = 1.0
				var r = Rect2(x * _cell_size, (y + 1.0 - f) * _cell_size, _cell_size, _cell_size * f)
				draw_rect(r, col)
			

