library(terra)
library(stars)
library(sf)
library(mapview)
library(leaflet)
library(leafem)
library(leaflet.extras2)
library(leastcostpath)
library(exactextractr)

r = rast("data/dgm_50408.tif")
pts = st_transform(
  st_read("data/pts2.gpkg")
  , crs = st_crs(r)
)

bbx = st_bbox(st_buffer(pts, 500))
r_crp = crop(r, bbx)

r_crp[r_crp < 0] = NA

slope_cs <- create_slope_cs(
  x = r_crp
  , cost_function = "tobler"
  , neighbours = 8
  , crit_slope = 15
  , max_slope = 35
)

slope_rst = rasterise(slope_cs)

lcp = create_lcp(
  slope_cs
  , origin = pts[1, ]
  , destination = pts[2, ]
)

slp = terrain(r_crp)

# mapview(slope_rst, maxBytes = 100e6) + lcp

# m = c(
#   0, 10, 1
#   , 10, 20, 2
#   , 20, 30, 3
#   , 30, 40, 4
#   , 40, 90, 5
# )
# rcl_mat = matrix(m, ncol = 3, byrow = TRUE)

# slp_cls = classify(
#   slp
#   , rcl_mat
# )

# strs = st_as_stars(slp)
# lcp_extr = st_transform(lcp, st_crs(slp))
# slp_prfl_strs = st_extract(st_as_stars(r), at = lcp_extr)

# slp_profile = extractAlong(r, lcp, xy = TRUE)
# slp_profile_sf = st_as_sf(slp_profile, coords = c("x", "y"), crs = st_crs(pts)) 

# slp_cls_profile = extractAlong(slp_cls, lcp)
# hgt_profile = extractAlong(r_crp, lcp)

# slp30 = slp
# slp30[slp30 > 30] = NA

m = mapview(slp, col.regions = mapviewPalette("mapviewSpectralColors"), maxBytes = 10e6) + 
  # mapview(slp_cls, col.regions = mapviewPalette("mapviewSpectralColors")) + 
  mapview(lcp, color = "red", lwd = 3)

loop = m@map |> 
  addProviderTiles(
    'BasemapAT.orthofoto'
    , group = "ortho"
    , options = tileOptions(
      maxZoom = 21
      , maxNativeZoom = 19
    )
  ) |>
  addProviderTiles(
    "BasemapAT.terrain"
    , group = "terrain"
    , options = tileOptions(
      maxZoom = 21
      , maxNativeZoom = 17
    )
  ) |>
    addProviderTiles(
      "BasemapAT.basemap"
      , group = "basemap"
      , options = tileOptions(
        maxZoom = 21
        , maxNativeZoom = 17
      )
    ) |>
      addProviderTiles(
        "BasemapAT.surface"
        , group = "surface"
        , options = tileOptions(
          maxZoom = 21
          , maxNativeZoom = 17
        )
      ) |>
        addProviderTiles(
          "BasemapAT.overlay"
          , group = "labels"
          , options = tileOptions(
            maxZoom = 21
            , maxNativeZoom = 17
          )
        ) |>
  leafem::updateLayersControl(
    addOverlayGroups = ("labels")
    , addBaseGroups = c("ortho", "terrain", "basemap", "surface")
  ) |>
  leaflet.extras::addControlGPS(options = leaflet.extras::gpsOptions(activate = TRUE))

mapshot(loop, url = "index.html")

writeRaster(r, "/home/tim/Downloads/50408_DGM_tif/dgm_50408_NA.tif")
writeRaster(slp, "/home/tim/Downloads/50408_DGM_tif/dgm_50408_slp.tif")

mapview(st_as_sfc(st_bbox(r)))

library(leaflet)
library(leafem)

l = leaflet() |>
  addMapPane("tif", zIndex = 500) |>
  addTiles() |>
  addProviderTiles(
    'BasemapAT.orthofoto'
    , group = "ortho"
    ) |>
  addProviderTiles(
    "BasemapAT.terrain"
    , group = "terrain"
  ) |>
  # addGeotiff(
  #   file = "/home/tim/Downloads/50408_DGM_tif/dgm_schumm_50408.tif"
  #   , group = "schumm"
  #   , colorOptions = colorOptions(
  #     palette = hcl.colors(256, palette = "Cividis")
  #     , na.color = "#BEBEBE30"
  #   )
  #   , options = tileOptions(pane = "tif")
  # ) |>
  # addGeotiff(
  #   file = "/home/tim/Downloads/50408_DGM_tif/dgm_50408_slp.tif"
  #   , group = "slope"
  #   , colorOptions = colorOptions(
  #     palette = hcl.colors(256, palette = "inferno")
  #     , na.color = "#BEBEBE30"
  #   )
  #   , options = tileOptions(pane = "tif")
  # ) |>
  addLayersControl(
    overlayGroups = c("slope", "schumm")
    , baseGroups = c("ortho", "terrain")
  )

l

pts = mapedit::drawFeatures(l)

st_write(pts, "/home/tim/Downloads/50408_DGM_tif/pts3.gpkg", append = FALSE)

leaflet