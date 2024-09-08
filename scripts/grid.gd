extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
var special_pieces_C = {
	"blue": preload("res://scenes/blue_column.tscn"),
	"green": preload("res://scenes/green_column.tscn"),
	"yellow": preload("res://scenes/yellow_column.tscn"),
	"orange": preload("res://scenes/orange_column.tscn"),
	"light": preload("res://scenes/light_column.tscn"),
	"pink": preload("res://scenes/pink_column.tscn")
}
var special_pieces_R = {
	"blue": preload("res://scenes/blue_row.tscn"),
	"green": preload("res://scenes/green_row.tscn"),
	"light": preload("res://scenes/light_row.tscn"),
	"orange": preload("res://scenes/orange_row.tscn"),
	"pink": preload("res://scenes/pink_row.tscn"),
	"yellow": preload("res://scenes/yellow_row.tscn")
}
 
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

@export var is_special_: bool = false
# scoring variables and signals
@export var score_label: Label
@export var score: int
# counter variables and signals
@export var counter_label: Label
@export var counter_time: int
@export var counter_movement: int
# timer
@export var timer_: Label
@export var timer_i: int
@export var timer_runnig: bool
#Gameover
@export var game_Over: Label 
@export var final_t: bool
# Called when the node enters the scene tree for the first time.
func _ready():
	timer_i = 100 * 50
	final_t = false
	counter_movement = 20
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	
func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
			counter_mov()	
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
			counter_mov()	
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
			counter_mov()	
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))
			counter_mov()	
	
func counter_mov():
	counter_movement -= 1
	counter_label.text = str(counter_movement)
func eliminate_column(column):
	for j in height:
		if all_pieces[column][j] != null:
			all_pieces[column][j].queue_free()
			all_pieces[column][j] = null
func _process(delta):
	tiempo()
	if timer_i <= 0:
		game_over()
	if state == MOVE and not final_t:
		touch_input()
		print(timer_i)
	elif counter_movement <= 0: #Agregar el gameover
		game_over()
#Tiempo transcurriendo
func tiempo():
	if timer_i >= 0:
		timer_i -= 1
		timer_.text = str(timer_i/100)
	else: 
		timer_runnig = false 
#crear fichas especiales
func create_special_piece_C(i,j,color):
	var special_c = special_pieces_C[color].instantiate()
	#special_p.is_special = true 
	add_child(special_c)
	special_c.position = grid_to_pixel(i,j)
	if i + 1 < width:
		all_pieces[i+1][j] = special_c
	
func create_special_piece_R(i,j,color):
	var special_r = special_pieces_R[color].instantiate() 
	add_child(special_r)
	special_r.position = grid_to_pixel(i,j)
	if j + 1<height:
		all_pieces[i][j+1] = special_r


func is_special():
		return is_special

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color 
				# detect horizontal matches
				if( i > 0 and i < width - 3 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color
				):
					all_pieces[i-1][j].matched = true
					all_pieces[i-1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i+1][j].matched = true
					all_pieces[i+1][j].dim()
					all_pieces[i+2][j].matched = true
					all_pieces[i+2][j].dim()
					create_special_piece_R(i+1,j,current_color)
				
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
				# detect vertical matches
				if( j > 0 and j < height - 3 
					and 
					all_pieces[i][j-1] != null and all_pieces[i][j+1] != null and all_pieces[i][j+2] != null
					and 
					all_pieces[i][j-1].color == current_color and all_pieces[i][j+1].color == current_color and all_pieces[i][j+2].color == current_color
				):
					all_pieces[i][j-1].matched = true
					all_pieces[i][j-1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j+1].matched = true
					all_pieces[i][j+1].dim()
					all_pieces[i][j+2].matched = true
					all_pieces[i][j+2].dim()
					create_special_piece_C(i,j+1,current_color)
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
				#if all_pieces[i][j].is_special:
					#if (
						#j > 0 and j < width -1 
						#and 
						#all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
						#and 
						#all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
					#):
						#all_pieces[i][j - 1].matched = true
						#all_pieces[i][j - 1].dim()
						#all_pieces[i][j].matched = true
						#all_pieces[i][j].dim()
						#all_pieces[i][j + 1].matched = true
						#all_pieces[i][j + 1].dim()
					#if (
						#j > 0 and j < height -1 
						#and 
						#all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
						#and 
						#all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
					#):
						#all_pieces[i][j - 1].matched = true
						#all_pieces[i][j - 1].dim()
						#all_pieces[i][j].matched = true
						#all_pieces[i][j].dim()
						#all_pieces[i][j + 1].matched = true
						#all_pieces[i][j + 1].dim()
				#
	get_parent().get_node("destroy_timer").start()
	
func destroy_matched():
	var was_matched = false
	var match_found = 0
	score = int(score_label.text)
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
				match_found  += 1
				
				
	move_checked = true	
	
	if was_matched:
		score += 5 + (match_found - 1 )* 20
		score_label.text = str(score)
		#match_found = 0
		get_parent().get_node("collapse_timer").start()
		
	else:
		swap_back()
	
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

func game_over():	
	final_t = true 
	state = WAIT
	var over: String
	if score <=5: 
		over = "You lose"
		
	elif score > 5:
		over = "You win"
	game_Over.text = over
	
	timer_runnig = false
	print("game over")
