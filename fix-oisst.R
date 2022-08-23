u <- "https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/202202/oisst-avhrr-v02r01.20220218.nc"
f0 <- basename(u)
if (!file.exists(f0)) curl::curl_download(u, f0)

f <- "file.nc"
file.copy(f0, f)
library(RNetCDF)
nc <- open.nc(f, write = TRUE)
crsvar <- "crs"
var <- var.def.nc(nc, crsvar, "NC_INT", NA)
var.put.nc(nc, crsvar, 1L)
att.put.nc(nc, crsvar, "comment", "NC_STRING",
           "This is a container variable that describes the grid_mapping used by the data in this file. This variable does not contain any data; only information about the geographic coordinate system."
)
att.put.nc(nc, crsvar, "grid_mapping_name", "NC_STRING", "latitude_longitude")
att.put.nc(nc, crsvar, "inverse_flattening", "NC_FLOAT", 298.257)
att.put.nc(nc, crsvar, "semi_major_axis", "NC_FLOAT", 6378136.3)

library(dplyr)
vars <- ncmeta::nc_vars(nc) %>% dplyr::filter(ndims == 4) %>% pull(name)
for (varname in vars) {
  #{varname}:coordinates = "longitude latitude" ;
  #{varname}:grid_mapping = "{crsvar}" ;
  att.put.nc(nc, varname, "coordinates", "NC_STRING", "longitude latitude")
  att.put.nc(nc, varname, "grid_mapping", "NC_STRING",  crsvar)
}
close.nc(nc)

for (i in seq_along(vars)) {
  print(substr(vapour::vapour_raster_info(f, sds = i)$projection, 1, 50))
  cat("\n")
}

# [1] "GEOGCRS[\"unknown\",\n    DATUM[\"unnamed\",\n        EL"
#
# [1] "GEOGCRS[\"unknown\",\n    DATUM[\"unnamed\",\n        EL"
#
# [1] "GEOGCRS[\"unknown\",\n    DATUM[\"unnamed\",\n        EL"
#
# [1] "GEOGCRS[\"unknown\",\n    DATUM[\"unnamed\",\n        EL"
#
