PATH  := .:$(PATH)

test:
	tests/test

.PHONY: test docs
.SILENT:
