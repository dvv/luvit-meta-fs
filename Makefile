PATH  := .:$(PATH)

test:
	mkdir -p tmp
	(cd tests; ./test)

.PHONY: test docs
.SILENT:
