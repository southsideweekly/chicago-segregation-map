S3_BUCKET = ssw-segregation-map-demo
YEARS = 1940 1950 1960 1970 1980 1990 2000 2010 2020

all: $(foreach year, $(YEARS), data/tiles/tracts-$(year)) data/tiles/redlining data/layers/school-closures.geojson

.PHONY:
clean:
	rm -rf data/points/*.geojson data/tiles/tracts* data/tiles/redlining*

.PHONY:
deploy: deploy-tiles
	aws s3 sync ./dist s3://$(S3_BUCKET) --acl=public-read --cache-control "public, max-age=0, must-revalidate"

.PHONY:
deploy-tiles:
	aws s3 cp data/layers/school-closures.geojson s3://$(S3_BUCKET)/layers/school-closures.geojson --acl=public-read --cache-control "public, max-age=86400"
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
		-r1.5 \
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

data/points/tracts-2020.geojson: data/census/tracts_2020.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-rename-fields hisp=hispanic \
		-each 'asian = this.properties["asian"] + this.properties["pac-islander"]' \
		-dots fields=white,black,hisp,asian,amind,other,multi per-dot=50 colors=red,blue,purple,orange,green,yellow,brown \
		-each 'race = {red:"white",blue:"black",purple:"hisp",orange:"asian",green:"amind",yellow:"other",brown:"multi"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-2010.geojson: data/census/tracts_2010.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-rename-fields hisp=hispanic \
		-each 'asian = this.properties["asian"] + this.properties["pac-islander"]' \
		-dots fields=white,black,hisp,asian,amind,other,multi per-dot=50 colors=red,blue,purple,orange,green,yellow,brown \
		-each 'race = {red:"white",blue:"black",purple:"hisp",orange:"asian",green:"amind",yellow:"other",brown:"multi"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-2000.geojson: data/census/tracts_2000.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-each 'hisp = this.properties["hisp-amind"] + this.properties["hisp-asian"] + this.properties["hisp-black"] + this.properties["hisp-other"] + this.properties["hisp-pac-islander"] + this.properties["hisp-white"]' \
		-each 'multi = this.properties["hisp-multi"] + this.properties["not-hisp-multi"]' \
		-each 'asian = this.properties["asian"] + this.properties["pac-islander"]' \
		-dots fields=white,black,hisp,asian,amind,not-hisp-other,multi per-dot=50 colors=red,blue,purple,orange,green,yellow,brown \
		-each 'race = {red:"white",blue:"black",purple:"hisp",orange:"asian",green:"amind",yellow:"other",brown:"multi"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-1990.geojson: data/census/tracts_1990.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-each 'hisp = this.properties["hisp-amind"] + this.properties["hisp-asian"] + this.properties["hisp-black"] + this.properties["hisp-other"] + this.properties["hisp-white"]' \
		-dots fields=white,black,hisp,asian,amind,not-hisp-other per-dot=50 colors=red,blue,purple,orange,green,yellow \
		-each 'race = {red:"white",blue:"black",purple:"hisp",orange:"asian",green:"amind",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts-1980.geojson: data/census/tracts_1980.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-each 'asian = this.properties["asian-chinese"] + this.properties["asian-filipino"] + this.properties["asian-guam"] + this.properties["asian-hawaiian"] + this.properties["asian-japanese"] + this.properties["asian-korean"] + this.properties["asian-samoan"] + this.properties["asian-vietnamese"]' \
		-each 'amind = this.properties["amind-1"] + this.properties["amind-2"] + this.properties["amind-3"]' \
		-dots fields=white,black,asian,amind,nonwhite-other per-dot=50 colors=red,blue,orange,green,yellow \
		-each 'race = {red:"white",blue:"black",orange:"asian",green:"amind",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

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

# TODO: 1940 seems more dense for some reason?
# TODO: Make note of nonwhite black usage
data/points/tracts-1940.geojson: data/census/tracts_1940.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-dots fields=white,nonwhite per-dot=50 colors=red,blue \
		-each 'race = {red:"white",blue:"nonwhite-black"}[fill]' \
		-filter-fields race \
		-o $@

data/layers/school-closures.geojson:
	wget -O - https://s3.amazonaws.com/projects.chicagoreporter.com/graphics/newschoolmap/geo_schools.geojson | \
	cut -c 10- | rev | cut -c 2- | rev | \
	mapshaper -i - -filter-fields name,address -o $@

# TODO: WBEZ HMDA data https://data.world/wbezchicago/chicago-purchase-originations-2012-2018

data/layers/redlining.geojson: data/layers/usa-redlining.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-clip $(filter-out $<,$^) \
		-filter-slivers \
		-filter-fields holc_grade \
		-dissolve2 fields=holc_grade \
		-o $@

data/layers/usa-redlining.geojson:
	wget -O $@ https://dsl.richmond.edu/panorama/redlining/static/fullDownload.geojson

data/census/chicago.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'
