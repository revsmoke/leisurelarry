extends RefCounted
## Scene-local placement; parent scaling keeps the result valid at every window size.
## Character art has priority over labels, then labels avoid each other.
const GAP := 10.0

static func place(anchor: Vector2, label_size: Vector2, area: Rect2, subject: Rect2, characters: Array[Rect2], occupied: Array[Rect2]) -> Rect2:
	var dimensions := Vector2(minf(label_size.x, area.size.x), minf(label_size.y, area.size.y))
	var candidates: Array[Vector2] = []
	if subject.has_area():
		# Above the full silhouette, not a fixed offset from the hotspot anchor.
		candidates.append(Vector2(subject.get_center().x - dimensions.x / 2, subject.position.y - dimensions.y - GAP))
		var right := Vector2(subject.end.x + GAP, subject.position.y + 8)
		var left := Vector2(subject.position.x - dimensions.x - GAP, subject.position.y + 8)
		if area.end.x - subject.end.x >= subject.position.x - area.position.x:
			candidates.append_array([right, left])
		else:
			candidates.append_array([left, right])
		# Keep a name near its owner when a neighbour occupies the first choices.
		for row in range(1, 5):
			candidates.append(candidates[0] - Vector2(0, row * (dimensions.y + GAP)))
			candidates.append(right + Vector2(0, row * (dimensions.y + GAP)))
			candidates.append(left + Vector2(0, row * (dimensions.y + GAP)))
	else:
		candidates.append(anchor - Vector2(dimensions.x / 2, 15))
		for row in range(1, 7):
			for direction in [-1.0, 1.0]:
				candidates.append(candidates[0] + Vector2(0, direction * row * (dimensions.y + 7)))
		candidates.append(anchor + Vector2(GAP, -dimensions.y / 2))
		candidates.append(anchor - Vector2(dimensions.x + GAP, dimensions.y / 2))
	# Fully visible candidates around obstacle edges also handle crowded scenes.
	var preferred := candidates[0]
	for obstacle in characters + occupied:
		candidates.append(Vector2(preferred.x, obstacle.position.y - dimensions.y - GAP))
		candidates.append(Vector2(obstacle.end.x + GAP, preferred.y))
		candidates.append(Vector2(obstacle.position.x - dimensions.x - GAP, preferred.y))
	var best := Rect2(_clamp(preferred, dimensions, area), dimensions)
	var best_score := INF
	for index in range(candidates.size()):
		var rect := Rect2(_clamp(candidates[index], dimensions, area), dimensions)
		var actor_overlap := _overlap(rect, characters, 5.0)
		var label_overlap := _overlap(rect, occupied, 3.0)
		if actor_overlap == 0.0 and label_overlap == 0.0:
			return rect
		# In an impossibly crowded/narrow area preserve visibility and minimise
		# obstruction. Ties retain the above-head preference for character labels.
		var score := actor_overlap * 1000.0 + label_overlap * 10.0 + float(index) * 0.001
		if score < best_score:
			best_score = score
			best = rect
	return best

static func _clamp(point: Vector2, dimensions: Vector2, area: Rect2) -> Vector2:
	return Vector2(clampf(point.x, area.position.x, area.end.x - dimensions.x), clampf(point.y, area.position.y, area.end.y - dimensions.y))

static func _overlap(rect: Rect2, obstacles: Array[Rect2], padding: float) -> float:
	var total := 0.0
	for obstacle in obstacles:
		var intersection := rect.intersection(obstacle.grow(padding))
		if intersection.has_area(): total += intersection.get_area()
	return total
