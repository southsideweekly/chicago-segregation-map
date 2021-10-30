# TODO: Look into options for points
data/tiles/%.mbtiles: data/points/%.geojson
	tippecanoe \
		--simplification=10 \
		--simplify-only-low-zooms \
		--minimum-zoom=5 \
		--maximum-zoom=12 \
		--no-tile-stats \
		--force \
		-L tracts:$< -o $@

data/points/tracts_1970.geojson: data/census/tracts_1970.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-dots fields=white,black,nonwhite-other per-dot=100 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts_1960.geojson: data/census/tracts_1960.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-dots fields=white,black,nonwhite-other per-dot=100 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts_1950.geojson: data/census/tracts_1950.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-dots fields=white,black,other per-dot=100 colors=red,blue,yellow \
		-each 'race = {red:"white",blue:"black",yellow:"other"}[fill]' \
		-filter-fields race \
		-o $@

data/points/tracts_1940.geojson: data/census/tracts_1940.geojson data/census/chicago.geojson
	mapshaper -i $< \
		-proj init=albersusa crs=wgs84 \
		-clip $(filter-out $<,$^) \
		-dots fields=white,nonwhite per-dot=100 colors=red,blue \
		-each 'race = {red:"white",blue:"nonwhite"}[fill]' \
		-filter-fields race \
		-o $@

data/census/chicago.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'
