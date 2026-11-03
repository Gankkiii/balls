extends SceneTree
## Run only in an isolated scratch project with assets/ and ASSET_MANIFEST.json.
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ASSET_MANIFEST.json"))
	var textures := 0
	var sounds := 0
	var failures := 0
	for item: Dictionary in manifest["files"]:
		var path: String = item["path"]
		if not path.begins_with("assets/"):
			continue
		if path.ends_with(".png"):
			var texture: Texture2D = load("res://" + path) as Texture2D
			if texture != null and texture.get_width() == int(item["width"]) and texture.get_height() == int(item["height"]):
				textures += 1
			else:
				push_error("Texture import failed: " + path)
				failures += 1
		elif path.ends_with(".wav"):
			var stream: AudioStreamWAV = load("res://" + path) as AudioStreamWAV
			if stream != null and stream.mix_rate == 48000 and not stream.stereo and stream.format == AudioStreamWAV.FORMAT_16_BITS:
				sounds += 1
			else:
				push_error("Audio import failed: " + path)
				failures += 1
	print("R04_IMPORT_RESULT textures=%d sounds=%d failures=%d" % [textures,sounds,failures])
	quit(0 if failures == 0 else 1)
