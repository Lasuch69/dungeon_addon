# dungeon.gd
extends Node2D

signal all_rooms_sleeping()

var _count: int

var _mst: MinimumSpanningTree = MinimumSpanningTree.new()
var _graph: DelaunayGraph = DelaunayGraph.new()

var _points: Array
var _tree: Array

func _ready() -> void:
	var rooms = _distribute_rooms(64)
	_count = 64
	
	await all_rooms_sleeping
	
	var points = rooms.map(func(room): return room.position.snapped(Vector2(16, 16)))
	
	_points = points
	_tree = generate(points)
	
	queue_redraw()


func _draw() -> void:
	print("draw")
	
	if !_tree.is_empty():
		var edges = _tree[0]
		
		for edge in edges:
			var point: Vector2 = _points[edge[0]]
			var other_point: Vector2 = _points[edge[1]]
			
			draw_line(point, other_point, Color.GHOST_WHITE)


func generate(points: Array) -> Array:
	var graph: Array = _graph.create(points)
	var mst: Array = _mst.solve(graph)
	
	var looped = _create_loops(mst, graph)
	
	return _create_loops(mst, graph)


func _create_loops(mst: Array, graph: Array, seed: int = 0) -> Array:
	seed(seed)
	
	var tree: Array = mst[0].duplicate()
	var total_weight: int = mst[1]
	
	var extra_edges: int = randi_range(int(tree.size() * 0.2), int(tree.size() * 0.4))
	var added: int = 0
	
	while added < extra_edges:
		var node = randi_range(0, graph.size() - 1)
		var connection = graph[node].pick_random()
		
		var other_node = connection[0]
		var weight = connection[1]
		
		var edge = [node, other_node, weight]
		
		if !mst[0].has(edge):
			added += 1
			tree.append(edge)
			total_weight += weight
	
	return [tree, total_weight]


func _distribute_rooms(amount: int, seed: int = 0) -> Array:
	seed(seed)
	
	var rooms: Array
	
	for i in amount:
		var room_size = Vector2(randi_range(3, 8) * 16, randi_range(3, 8) * 16)
		var room_position = Vector2(randi_range(-32, 32), randi_range(-32, 32))
		
		var room = _create_room(room_size)
		room.position = room_position
		room.name = "Room" + str(i)
		
		room.sleeping_state_changed.connect(_on_room_sleeping_state_changed.bind(room))
		
		add_child(room)
		rooms.append(room)
	
	return rooms


func _on_room_sleeping_state_changed(room: Room) -> void:
	_count -= 1
	
	if _count == 0:
		all_rooms_sleeping.emit()


func _create_room(size: Vector2) -> Room:
	var shape = RectangleShape2D.new()
	shape.size = size
	
	var collision = CollisionShape2D.new()
	collision.shape = shape
	
	var room = Room.new(collision)
	
	room.lock_rotation = true
	
	return room