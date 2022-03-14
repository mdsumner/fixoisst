
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fixoisst

<!-- badges: start -->
<!-- badges: end -->

The goal of fixoisst is to see what’s required to add the grid_mapping
scheme to OISST files.

Here’s an email sent to the maintainers 2022-03-14

> the OISST files have no “grid_mapping” variable, so downstream tools
> like GDAL miss auto-determining the coordinate system used by the sst,
> ice, anom, and err variables.
>
> I obtained an example file
>
> <https://www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/202202/oisst-avhrr-v02r01.20220218.nc>
>
> and created a new “file.nc” that adds the scalar ‘crs’ var with
> attributes, and this is pointed to by new attributes ‘coordinates’ and
> ‘grid_mapping’ from the 4D variables that use ‘lon’ and ‘lat’.
>
> I hope that future updates of the OISST files can include the
> ‘grid_mapping’ scheme.
>
> Thank you. I’ve attached my example files and R script for your
> reference.

## Implications for R

We wouldn’t need to assign the projection this way with VRT or raster or
whatever.

``` r
vapour::vapour_raster_info("NETCDF:\"oisst-avhrr-v02r01.20220218.nc\":sst")[c("projection", "projstring")]
#> $projection
#> [1] ""
#> 
#> $projstring
#> [1] ""
vapour::vapour_raster_info("NETCDF:\"file.nc\":sst")[c("projection", "projstring")]
#> $projection
#> [1] "GEOGCS[\"unknown\",DATUM[\"unnamed\",SPHEROID[\"Spheroid\",6378136.5,298.25699]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST]]"
#> 
#> $projstring
#> [1] "+proj=longlat +a=6378136.5 +rf=298.25699 +no_defs"
```

As of this writing, {stars} doesn’t get the projection from the original
file (because GDAL doesn’t), but {terra} and {raster} both do because of
different heuristics (in terra) and different read facilities (in
raster). I won’t compare those other packages here because they change
too and they aren’t the point of this story (though this does have
implications, for this one data set …).

## Comparison for GDAL

Here we are missing the CRS, but with our additions in the second
summary it correctly has the longitude/latitude projection stuff. Same
goes for four variables ‘sst’, ‘anom’, ‘err’, and ‘ice’ which are 4D
variables on a lonlat regular grid (with degenerate Z and time axes).

(we hack-ily dump the Metadata chunk)

``` r
system("gdalinfo NETCDF:\"oisst-avhrr-v02r01.20220218.nc\":sst", intern = TRUE)[-c(6:67)]
#>  [1] "Driver: netCDF/Network Common Data Format"              
#>  [2] "Files: oisst-avhrr-v02r01.20220218.nc"                  
#>  [3] "Size is 1440, 720"                                      
#>  [4] "Origin = (0.000000000000000,90.000000000000000)"        
#>  [5] "Pixel Size = (0.250000000000000,-0.250000000000000)"    
#>  [6] "Corner Coordinates:"                                    
#>  [7] "Upper Left  (   0.0000000,  90.0000000) "               
#>  [8] "Lower Left  (   0.0000000, -90.0000000) "               
#>  [9] "Upper Right (     360.000,      90.000) "               
#> [10] "Lower Right (     360.000,     -90.000) "               
#> [11] "Center      ( 180.0000000,   0.0000000) "               
#> [12] "Band 1 Block=1440x720 Type=Int16, ColorInterp=Undefined"
#> [13] "  NoData Value=-999"                                    
#> [14] "  Unit Type: Celsius"                                   
#> [15] "  Offset: 0,   Scale:0.00999999977648258"               
#> [16] "  Metadata:"                                            
#> [17] "    add_offset=0"                                       
#> [18] "    long_name=Daily sea surface temperature"            
#> [19] "    NETCDF_DIM_time=16119"                              
#> [20] "    NETCDF_DIM_zlev=0"                                  
#> [21] "    NETCDF_VARNAME=sst"                                 
#> [22] "    scale_factor=0.0099999998"                          
#> [23] "    units=Celsius"                                      
#> [24] "    valid_max=4500"                                     
#> [25] "    valid_min=-300"                                     
#> [26] "    _FillValue=-999"
```

``` r
system("gdalinfo NETCDF:\"file.nc\":sst",intern = TRUE)[-c(24:91)]
#>  [1] "Driver: netCDF/Network Common Data Format"                                
#>  [2] "Files: file.nc"                                                           
#>  [3] "Size is 1440, 720"                                                        
#>  [4] "Coordinate System is:"                                                    
#>  [5] "GEOGCRS[\"unknown\","                                                     
#>  [6] "    DATUM[\"unnamed\","                                                   
#>  [7] "        ELLIPSOID[\"Spheroid\",6378136.5,298.25699,"                      
#>  [8] "            LENGTHUNIT[\"metre\",1,"                                      
#>  [9] "                ID[\"EPSG\",9001]]]],"                                    
#> [10] "    PRIMEM[\"Greenwich\",0,"                                              
#> [11] "        ANGLEUNIT[\"degree\",0.0174532925199433,"                         
#> [12] "            ID[\"EPSG\",9122]]],"                                         
#> [13] "    CS[ellipsoidal,2],"                                                   
#> [14] "        AXIS[\"latitude\",north,"                                         
#> [15] "            ORDER[1],"                                                    
#> [16] "            ANGLEUNIT[\"degree\",0.0174532925199433,"                     
#> [17] "                ID[\"EPSG\",9122]]],"                                     
#> [18] "        AXIS[\"longitude\",east,"                                         
#> [19] "            ORDER[2],"                                                    
#> [20] "            ANGLEUNIT[\"degree\",0.0174532925199433,"                     
#> [21] "                ID[\"EPSG\",9122]]]]"                                     
#> [22] "Data axis to CRS axis mapping: 2,1"                                       
#> [23] "Origin = (0.000000000000000,90.000000000000000)"                          
#> [24] "  zlev#units=meters"                                                      
#> [25] "Corner Coordinates:"                                                      
#> [26] "Upper Left  (   0.0000000,  90.0000000) (  0d 0' 0.01\"E, 90d 0' 0.00\"N)"
#> [27] "Lower Left  (   0.0000000, -90.0000000) (  0d 0' 0.01\"E, 90d 0' 0.00\"S)"
#> [28] "Upper Right (     360.000,      90.000) (360d 0' 0.00\"E, 90d 0' 0.00\"N)"
#> [29] "Lower Right (     360.000,     -90.000) (360d 0' 0.00\"E, 90d 0' 0.00\"S)"
#> [30] "Center      ( 180.0000000,   0.0000000) (180d 0' 0.00\"E,  0d 0' 0.01\"N)"
#> [31] "Band 1 Block=1440x720 Type=Int16, ColorInterp=Undefined"                  
#> [32] "  NoData Value=-999"                                                      
#> [33] "  Unit Type: Celsius"                                                     
#> [34] "  Offset: 0,   Scale:0.00999999977648258"                                 
#> [35] "  Metadata:"                                                              
#> [36] "    add_offset=0"                                                         
#> [37] "    coordinates=longitude latitude"                                       
#> [38] "    grid_mapping=crs"                                                     
#> [39] "    long_name=Daily sea surface temperature"                              
#> [40] "    NETCDF_DIM_time=16119"                                                
#> [41] "    NETCDF_DIM_zlev=0"                                                    
#> [42] "    NETCDF_VARNAME=sst"                                                   
#> [43] "    scale_factor=0.0099999998"                                            
#> [44] "    units=Celsius"                                                        
#> [45] "    valid_max=4500"                                                       
#> [46] "    valid_min=-300"                                                       
#> [47] "    _FillValue=-999"
```

## Original NetCDF

Here’s the NetCDF dump of the original file (which I used to email the
maintainers).

``` r
writeLines(system("ncdump -h oisst-avhrr-v02r01.20220218.nc", intern = TRUE))
#> netcdf oisst-avhrr-v02r01.20220218 {
#> dimensions:
#>  time = UNLIMITED ; // (1 currently)
#>  zlev = 1 ;
#>  lat = 720 ;
#>  lon = 1440 ;
#> variables:
#>  float time(time) ;
#>      time:long_name = "Center time of the day" ;
#>      time:units = "days since 1978-01-01 12:00:00" ;
#>  float zlev(zlev) ;
#>      zlev:long_name = "Sea surface height" ;
#>      zlev:units = "meters" ;
#>      zlev:positive = "down" ;
#>      zlev:actual_range = "0, 0" ;
#>  float lat(lat) ;
#>      lat:long_name = "Latitude" ;
#>      lat:units = "degrees_north" ;
#>      lat:grids = "Uniform grid from -89.875 to 89.875 by 0.25" ;
#>  float lon(lon) ;
#>      lon:long_name = "Longitude" ;
#>      lon:units = "degrees_east" ;
#>      lon:grids = "Uniform grid from 0.125 to 359.875 by 0.25" ;
#>  short sst(time, zlev, lat, lon) ;
#>      sst:long_name = "Daily sea surface temperature" ;
#>      sst:units = "Celsius" ;
#>      sst:_FillValue = -999s ;
#>      sst:add_offset = 0.f ;
#>      sst:scale_factor = 0.01f ;
#>      sst:valid_min = -300s ;
#>      sst:valid_max = 4500s ;
#>  short anom(time, zlev, lat, lon) ;
#>      anom:long_name = "Daily sea surface temperature anomalies" ;
#>      anom:units = "Celsius" ;
#>      anom:_FillValue = -999s ;
#>      anom:add_offset = 0.f ;
#>      anom:scale_factor = 0.01f ;
#>      anom:valid_min = -1200s ;
#>      anom:valid_max = 1200s ;
#>  short err(time, zlev, lat, lon) ;
#>      err:long_name = "Estimated error standard deviation of analysed_sst" ;
#>      err:units = "Celsius" ;
#>      err:_FillValue = -999s ;
#>      err:add_offset = 0.f ;
#>      err:scale_factor = 0.01f ;
#>      err:valid_min = 0s ;
#>      err:valid_max = 1000s ;
#>  short ice(time, zlev, lat, lon) ;
#>      ice:long_name = "Sea ice concentration" ;
#>      ice:units = "%" ;
#>      ice:_FillValue = -999s ;
#>      ice:add_offset = 0.f ;
#>      ice:scale_factor = 0.01f ;
#>      ice:valid_min = 0s ;
#>      ice:valid_max = 100s ;
#> 
#> // global attributes:
#>      :Conventions = "CF-1.6, ACDD-1.3" ;
#>      :title = "NOAA/NCEI 1/4 Degree Daily Optimum Interpolation Sea Surface Temperature (OISST) Analysis, Version 2.1 - Final" ;
#>      :references = "Reynolds, et al.(2007) Daily High-Resolution-Blended Analyses for Sea Surface Temperature (available at https://doi.org/10.1175/2007JCLI1824.1). Banzon, et al.(2016) A long-term record of blended satellite and in situ sea-surface temperature for climate monitoring, modeling and environmental studies (available at https://doi.org/10.5194/essd-8-165-2016). Huang et al. (2020) Improvements of the Daily Optimum Interpolation Sea Surface Temperature (DOISST) Version v02r01, submitted.Climatology is based on 1971-2000 OI.v2 SST. Satellite data: Pathfinder AVHRR SST, Navy AVHRR SST, and NOAA ACSPO SST. Ice data: NCEP Ice and GSFC Ice." ;
#>      :source = "ICOADS, NCEP_GTS, GSFC_ICE, NCEP_ICE, Pathfinder_AVHRR, Navy_AVHRR, NOAA_ACSP" ;
#>      :id = "oisst-avhrr-v02r01.20220218.nc" ;
#>      :naming_authority = "gov.noaa.ncei" ;
#>      :summary = "NOAAs 1/4-degree Daily Optimum Interpolation Sea Surface Temperature (OISST) (sometimes referred to as Reynolds SST, which however also refers to earlier products at different resolution), currently available as version v02r01, is created by interpolating and extrapolating SST observations from different sources, resulting in a smoothed complete field. The sources of data are satellite (AVHRR) and in situ platforms (i.e., ships and buoys), and the specific datasets employed may change over time. At the marginal ice zone, sea ice concentrations are used to generate proxy SSTs.  A preliminary version of this file is produced in near-real time (1-day latency), and then replaced with a final version after 2 weeks. Note that this is the AVHRR-ONLY DOISST, available from Oct 1981, but there is a companion DOISST product that includes microwave satellite data, available from June 2002" ;
#>      :cdm_data_type = "Grid" ;
#>      :history = "Final file created using preliminary as first guess, and 3 days of AVHRR data. Preliminary uses only 1 day of AVHRR data." ;
#>      :date_modified = "2022-03-05T09:12:00Z" ;
#>      :date_created = "2022-03-05T09:12:00Z" ;
#>      :product_version = "Version v02r01" ;
#>      :processing_level = "NOAA Level 4" ;
#>      :institution = "NOAA/National Centers for Environmental Information" ;
#>      :creator_url = "https://www.ncei.noaa.gov/" ;
#>      :creator_email = "oisst-help@noaa.gov" ;
#>      :keywords = "Earth Science > Oceans > Ocean Temperature > Sea Surface Temperature" ;
#>      :keywords_vocabulary = "Global Change Master Directory (GCMD) Earth Science Keywords" ;
#>      :platform = "Ships, buoys, Argo floats, MetOp-A, MetOp-B" ;
#>      :platform_vocabulary = "Global Change Master Directory (GCMD) Platform Keywords" ;
#>      :instrument = "Earth Remote Sensing Instruments > Passive Remote Sensing > Spectrometers/Radiometers > Imaging Spectrometers/Radiometers > AVHRR > Advanced Very High Resolution Radiometer" ;
#>      :instrument_vocabulary = "Global Change Master Directory (GCMD) Instrument Keywords" ;
#>      :standard_name_vocabulary = "CF Standard Name Table (v40, 25 January 2017)" ;
#>      :geospatial_lat_min = -90.f ;
#>      :geospatial_lat_max = 90.f ;
#>      :geospatial_lon_min = 0.f ;
#>      :geospatial_lon_max = 360.f ;
#>      :geospatial_lat_units = "degrees_north" ;
#>      :geospatial_lat_resolution = 0.25f ;
#>      :geospatial_lon_units = "degrees_east" ;
#>      :geospatial_lon_resolution = 0.25f ;
#>      :time_coverage_start = "2022-02-18T00:00:00Z" ;
#>      :time_coverage_end = "2022-02-18T23:59:59Z" ;
#>      :metadata_link = "https://doi.org/10.25921/RE9P-PT57" ;
#>      :ncei_template_version = "NCEI_NetCDF_Grid_Template_v2.0" ;
#>      :comment = "Data was converted from NetCDF-3 to NetCDF-4 format with metadata updates in November 2017." ;
#>      :sensor = "Thermometer, AVHRR" ;
#> }
```

## Modified NetCDF

Here’s the NetCDF dump of the modified file, with the modified section
grep’ed out

``` r
writeLines(system("ncdump -h file.nc | grep \"short sst\" -A 45", intern = TRUE))
#>  short sst(time, zlev, lat, lon) ;
#>      sst:long_name = "Daily sea surface temperature" ;
#>      sst:units = "Celsius" ;
#>      sst:_FillValue = -999s ;
#>      sst:add_offset = 0.f ;
#>      sst:scale_factor = 0.01f ;
#>      sst:valid_min = -300s ;
#>      sst:valid_max = 4500s ;
#>      string sst:coordinates = "longitude latitude" ;
#>      string sst:grid_mapping = "crs" ;
#>  short anom(time, zlev, lat, lon) ;
#>      anom:long_name = "Daily sea surface temperature anomalies" ;
#>      anom:units = "Celsius" ;
#>      anom:_FillValue = -999s ;
#>      anom:add_offset = 0.f ;
#>      anom:scale_factor = 0.01f ;
#>      anom:valid_min = -1200s ;
#>      anom:valid_max = 1200s ;
#>      string anom:coordinates = "longitude latitude" ;
#>      string anom:grid_mapping = "crs" ;
#>  short err(time, zlev, lat, lon) ;
#>      err:long_name = "Estimated error standard deviation of analysed_sst" ;
#>      err:units = "Celsius" ;
#>      err:_FillValue = -999s ;
#>      err:add_offset = 0.f ;
#>      err:scale_factor = 0.01f ;
#>      err:valid_min = 0s ;
#>      err:valid_max = 1000s ;
#>      string err:coordinates = "longitude latitude" ;
#>      string err:grid_mapping = "crs" ;
#>  short ice(time, zlev, lat, lon) ;
#>      ice:long_name = "Sea ice concentration" ;
#>      ice:units = "%" ;
#>      ice:_FillValue = -999s ;
#>      ice:add_offset = 0.f ;
#>      ice:scale_factor = 0.01f ;
#>      ice:valid_min = 0s ;
#>      ice:valid_max = 100s ;
#>      string ice:coordinates = "longitude latitude" ;
#>      string ice:grid_mapping = "crs" ;
#>  int crs ;
#>      string crs:comment = "This is a container variable that describes the grid_mapping used by the data in this file. This variable does not contain any data; only information about the geographic coordinate system." ;
#>      string crs:grid_mapping_name = "latitude_longitude" ;
#>      crs:inverse_flattening = 298.257f ;
#>      crs:semi_major_axis = 6378136.f ;
```

------------------------------------------------------------------------

## Code of Conduct

Please note that the fixoisst project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
