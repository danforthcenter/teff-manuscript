#!/usr/bin/env python
# coding: utf-8

# # High-throughput plot height analysis with plantcv-geospatial for the 2023 Tef field experiment at the Danforth Center Field Research Site (Fisher Farm) 

# Import necessary software packages
import plantcv.plantcv as pcv
from plantcv.parallel import workflow_inputs
from plantcv.plantcv import Objects
import plantcv.geospatial as gcv 
import numpy as np
import os

args = workflow_inputs()

# Shapefile for cropping down the part of the image to get read into memory 
cropto = "../shapefiles/goldy-locks-boundaries.geojson"
# Shapefile for tef plot boundaries
plot_polygons = "../shapefiles/tef-plot-polygons.geojson"

# Read in the DSM 
dsm = gcv.read_geotif(args.image1, bands="gray", cutoff=0.995, cropto=cropto)

# Turn on plotting to print the output debug 
pcv.params.debug = "print"
pcv.params.debug_outdir = args.outdir
pcv.params.device = os.path.basename(args.image1)
# Analyze coverage for each region in the geojson
bounds = gcv.analyze.height_percentile(dsm=dsm,
                           geojson="../shapefiles/tef-plot-32615crs.geojson",
                           lower=10,
                           upper=95)
# Reset the device counter to avoid an error while auto-incrementing
pcv.params.device = 1
pcv.params.debug = None

# Reshape the grayscale DSM data from (x,y,1) to (x,y)
gray = dsm.array_data.reshape(dsm.array_data.shape[:2])
gray = pcv.transform.rescale(gray_img=gray, max_value=255, min_value=0)
# Make labeled mask from Shapefile polygon boundaries
# (plot_polygons are very similar to tef-plot-32615crs.geojson but have all vertices)
coords = gcv.transform_polygons(dsm, geojson=plot_polygons)
roi = Objects()
for coord in coords:
    rc = [np.array([[coord[0]], [coord[1]], [coord[2]], [coord[3]]], dtype=np.int32)]
    roi.append(rc, np.array([[[-1, -1, -1, -1]]], dtype=np.int32))
  
mask = pcv.threshold.binary(gray, threshold=50, object_type="light")
roi_mask = pcv.roi.roi2mask(roi=roi, img=dsm.pseudo_rgb)
masked_plants = pcv.logical_and(roi_mask, mask)
lbl_mask, num = pcv.create_labels(mask=masked_plants, rois=roi, roi_type="partial")

# Analyze DSM values with plantcv.analyze.grayscale
plot_ids = ["101", "201", "301", "401", "501", "901", "701", "801", "601",
            "502", "402", "102", "702", "202", "602", "802", "302", "902",
           "703", "103", "203", "803", "303", "903", "403", "503", "603"]
_ = pcv.analyze.grayscale(gray_img=gray, bins=20, labeled_mask=lbl_mask, n_labels=27, label=plot_ids)

# Save traits out to results file 
pcv.outputs.save_results(filename=args.result) 