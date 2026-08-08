.PHONY: app test clean

app:
	./scripts/bundle.sh

test:
	swift test

clean:
	rm -rf .build dist
