class_name NumberFormat
extends RefCounted

static func compact(value: float) -> String:
	if not is_finite(value):
		return "—"
	var units: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	if absf(value) < 1000:
		return "%.0f" % value if is_equal_approx(value, round(value)) else "%.1f" % value
	var group: int = int(floor(log(absf(value)) / log(1000.0)))
	if group >= units.size():
		return "%.2fe%d" % [value / pow(10.0, floor(log(absf(value)) / log(10.0))), int(floor(log(absf(value)) / log(10.0)))]
	return "%.2f%s" % [value / pow(1000.0, group), units[group]]
