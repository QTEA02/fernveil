extends CanvasModulate

signal phase_changed(new_phase: String)
signal hour_changed(hour: int)
signal new_day(day_number: int)

enum Phase { DAWN, DAY, DUSK, NIGHT }

# How many real seconds = one in-game minute
@export var seconds_per_minute: float = 1.0
# Day starts at 6:00 AM
@export var start_hour: int = 6
@export var start_minute: int = 0

# Phase boundaries (hours)
const DAWN_START := 5
const DAY_START := 7
const DUSK_START := 18
const NIGHT_START := 20

# Tint colors for each phase
const COLOR_DAWN := Color(0.95, 0.85, 0.75)
const COLOR_DAY := Color(1.0, 1.0, 1.0)
const COLOR_DUSK := Color(0.85, 0.65, 0.55)
const COLOR_NIGHT := Color(0.3, 0.3, 0.5)

var current_hour: int = 6
var current_minute: int = 0
var current_day: int = 1
var current_phase: Phase = Phase.DAY
var minute_accumulator: float = 0.0

func _ready() -> void:
	current_hour = start_hour
	current_minute = start_minute
	_update_phase()
	_update_color()

func _process(delta: float) -> void:
	minute_accumulator += delta
	if minute_accumulator >= seconds_per_minute:
		minute_accumulator -= seconds_per_minute
		_advance_minute()

func _advance_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			new_day.emit(current_day)
			print("Day ", current_day, " begins!")
		hour_changed.emit(current_hour)
		_update_phase()
	_update_color()

func _update_phase() -> void:
	var old_phase := current_phase
	if current_hour >= NIGHT_START or current_hour < DAWN_START:
		current_phase = Phase.NIGHT
	elif current_hour >= DUSK_START:
		current_phase = Phase.DUSK
	elif current_hour >= DAY_START:
		current_phase = Phase.DAY
	else:
		current_phase = Phase.DAWN

	if current_phase != old_phase:
		var phase_name := get_phase_name()
		phase_changed.emit(phase_name)
		print("Phase changed to: ", phase_name)

func _update_color() -> void:
	# Smoothly interpolate between phase colors based on exact time
	var time_float: float = current_hour + current_minute / 60.0
	var target_color: Color

	if time_float >= NIGHT_START or time_float < DAWN_START:
		target_color = COLOR_NIGHT
	elif time_float < DAY_START:
		# Dawn transition: NIGHT -> DAY
		var t: float = (time_float - DAWN_START) / (DAY_START - DAWN_START)
		target_color = COLOR_NIGHT.lerp(COLOR_DAY, t)
	elif time_float < DUSK_START:
		target_color = COLOR_DAY
	else:
		# Dusk transition: DAY -> NIGHT
		var t: float = (time_float - DUSK_START) / (NIGHT_START - DUSK_START)
		target_color = COLOR_DAY.lerp(COLOR_NIGHT, t)

	color = target_color

func get_phase_name() -> String:
	match current_phase:
		Phase.DAWN: return "Dawn"
		Phase.DAY: return "Day"
		Phase.DUSK: return "Dusk"
		Phase.NIGHT: return "Night"
	return "Unknown"

func get_time_string() -> String:
	var period := "AM"
	var display_hour := current_hour
	if display_hour >= 12:
		period = "PM"
		if display_hour > 12:
			display_hour -= 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, current_minute, period]

func is_night() -> bool:
	return current_phase == Phase.NIGHT

func is_day() -> bool:
	return current_phase == Phase.DAY
