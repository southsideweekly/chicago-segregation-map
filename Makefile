S3_BUCKET = ssw-segregation-map-demo
YEARS = 1940 1950 1960 1970

all: $(foreach year, $(YEARS), data/tiles/tracts-$(year)) data/tiles/redlining

.PHONY:
clean:
	rm -rf data/points/*.geojson data/tiles/*.mbtiles

.PHONY:
deploy: deploy-tiles
	aws s3 sync ./dist s3://$(S3_BUCKET) --size-only --acl=public-read --cache-control "public, max-age=0, must-revalidate"

.PHONY:
deploy-tiles:
	aws s3 sync data/tiles/ s3://$(S3_BUCKET)/tiles/ --size-only --acl=public-read --content-encoding=gzip --cache-control "public, max-age=86400"

.PHONY:
build:
	npm run build

data/tiles/%: data/tiles/%.mbtiles
	mkdir $@
	tile-join --no-tile-size-limit --force -e $@ $<

# https://github.com/mapbox/tippecanoe#options
.PRECIOUS:
data/tiles/%.mbtiles: data/points/%.geojson
	tippecanoe \
		-B13 \
		--minimum-zoom=8 \
		--maximum-zoom=15 \
		--no-tile-stats \
		--force \
		-L tracts:$< -o $@

data/tiles/redlining.mbtiles: data/layers/redlining.geojson
	tippecanoe \
		--simplification=10 \
		--simplify-only-low-zooms \
		--minimum-zoom=8 \
		--maximum-zoom=15 \
		--no-tile-stats \
		--generate-ids \
		--detect-shared-borders \
		--grid-low-zooms \
		--coalesce-smallest-as-needed \
		--force \
		-L redlining:$< -o $@

data/points/tracts-1970.geojson: data/census/tracts_1970.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-dots fields=white,black,nonwhite-other per-dot=50 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-1960.geojson: data/census/tracts_1960.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-dots fields=white,black,nonwhite-other per-dot=50 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-1950.geojson: data/census/tracts_1950.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-dots fields=white,black,other per-dot=50 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-1940.geojson: data/census/tracts_1940.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-dots fields=white,nonwhite per-dot=50 colors=red,blue \
		-each 'race = {red:"white",blue:"nonwhite"}[fill]' \
		-filter-fields race \
		-o $@

data/layers/redlining.geojson: data/layers/usa-redlining.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-filter-fields holc_grade \
		-o $@

data/layers/usa-redlining.geojson:
	wget -O $@ https://dsl.richmond.edu/panorama/redlining/static/fullDownload.geojson

data/census/chicago.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'
