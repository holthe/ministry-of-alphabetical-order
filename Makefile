# Asset regeneration only. The site itself does not build; it is already built.
# Nothing here runs at deploy time. Cloudflare Pages serves the repo root as-is.
#
# Requires: google-chrome (headless), ImageMagick 7 (`magick`), Inkscape.
# The wordmark, the icon and the share image are set in Helvetica and a
# monospace face, which resolve through fontconfig to Liberation Sans and
# Liberation Mono. Both are metric-compatible, so the generated assets match
# what the site renders.

CHROME   ?= google-chrome
MAGICK   ?= magick
INKSCAPE ?= inkscape

# Colours without the leading hash: an unescaped '#' in a make assignment
# starts a comment. Icons are flattened onto the Ministry's own ink rather
# than kept transparent, so they read the same on a light or a dark browser
# chrome.
INK := 0e1013

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  %-12s %s\n", $$1, $$2}'

.PHONY: assets
assets: og favicon logo ## Regenerate every generated asset

.PHONY: og
og: ## Re-render og.png from tools/og.html
	$(CHROME) --headless=new --disable-gpu --hide-scrollbars \
		--force-device-scale-factor=1 --default-background-color=$(INK)FF \
		--screenshot=/tmp/mao-og-raw.png --window-size=1200,630 tools/og.html
	$(MAGICK) /tmp/mao-og-raw.png -strip -dither None -colors 128 PNG8:og.png
	@rm -f /tmp/mao-og-raw.png
	@echo "wrote og.png"

.PHONY: favicon
favicon: ## Outline favicon.svg, then re-render favicon.ico and apple-touch-icon.png
	$(INKSCAPE) --export-type=svg --export-text-to-path --export-plain-svg \
		--export-filename=favicon.svg tools/favicon-src.svg
	$(MAGICK) -background "#$(INK)" favicon.svg -resize 180x180 \
		-alpha off -colorspace sRGB -type TrueColor -strip apple-touch-icon.png
	$(MAGICK) \
		\( -background "#$(INK)" favicon.svg -resize 48x48 \) \
		\( -background "#$(INK)" favicon.svg -resize 32x32 \) \
		\( -background "#$(INK)" tools/favicon-16.svg -resize 16x16 \) \
		-alpha off -colorspace sRGB -strip favicon.ico
	@echo "wrote favicon.svg apple-touch-icon.png favicon.ico (re-add the GENERATED header comment)"

.PHONY: logo
logo: ## Re-render assets/logo.svg from tools/logo-src.svg, outlining the text
	$(INKSCAPE) --export-type=svg --export-text-to-path --export-plain-svg \
		--export-filename=assets/logo.svg tools/logo-src.svg
	@echo "wrote assets/logo.svg (re-add the GENERATED header comment)"

.PHONY: serve
serve: ## Preview the site at http://localhost:8000
	python3 -m http.server 8000

.PHONY: deploy
deploy: ## Push the current working tree to Cloudflare Pages
	wrangler pages deploy .
