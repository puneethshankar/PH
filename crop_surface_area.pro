; CROP SURFACE AREA ESTIMATOR : The digital surface model used for the plant height measurements includes 
;                               a full characterization of the crop canopy surface. The total volume (m3) 
;                               will be reported for each feature in the plot shapefile.

;Inputs required:
;               1)Ortho image in Geotiff
;               2)DSM in Geotiff
;
;DELIVERABLE(s): 1)Corresponding CANOPY MAP/MASK in Geotiff
;                2)polygon shapefile containing total crop surface volume information                
;
;CODE tested upon: SYNGENTA DATA             
;               1)Stanton_Trip3_Plant1_BGNIR_50m_Ortho.tif
;               2)Stanton_Trip3_Plant1_BGNIR_50m_DSM
;               
;Last Modified on 08-Sept-2015

;----------------------------------------------------------------------------------------------------------------------
;CANOPY MASK CREATION (HLS method)
;----------------------------------------------------------------------------------------------------------------------
MS_raster_input_FILE = DIALOG_PICKFILE(/READ, FILTER = '*.tif',Title="BGNIR input file")
filename_dsm=DIALOG_PICKFILE(/READ, FILTER = '*.tif',Title="Select DSM for Crop Volume Estimation")
out_file_prefix = DIALOG_PICKFILE(Title="Output directory and prefix",  FILE = "Vegetation_index")

Canopy_file_name_components = [out_file_prefix, "_canopy_delineation.tif"]
Canopy_mask_raster_file = Canopy_file_name_components.join('')
PRINT, Canopy_mask_raster_file

geotiff_info = QUERY_TIFF(MS_raster_input_FILE, image_info_details, GEOTIFF = geotiff_info_details)
x_pix_size = geotiff_info_details.MODELPIXELSCALETAG[0]
y_pix_size = geotiff_info_details.MODELPIXELSCALETAG[1]
ns = image_info_details.dimensions[0]
nl = image_info_details.dimensions[1]

;Read-in individual raster channels
oBlue = READ_TIFF(MS_raster_input_FILE, CHANNEL = [2])
oGreen = READ_TIFF(MS_raster_input_FILE, CHANNEL = [1])
oNIR = READ_TIFF(MS_raster_input_FILE, CHANNEL = [0])

; PROCESS A CANOPY COVER MASK (HLS method)
COLOR_CONVERT, oNIR, oGreen, oBlue, H, L, S, /RGB_HLS; Colour space conversion to HLS and segmentation to cover mask
oBlue = 0  ; Clean unused raster variables
oGreen = 0
oNIR = 0
Canopy_mask = FLOAT((H LE 20.0) AND (L GE 0.5) AND (S GE 0.45))
H = 0 ; Clean unused raster variables
L = 0
S = 0
WRITE_TIFF, Canopy_mask_raster_file, Canopy_mask, geotiff = geotiff_info_details


;-----------------------------------------------------------------------------------------------------------------------
;CANOPY VOLUME ESTMATION
;-----------------------------------------------------------------------------------------------------------------------

;filename_mask=DIALOG_PICKFILE(/READ,FILTER = '*.tif',Title="Select corresponding canopy MASK")
;FILENAME_DSM='E:\crop surface area\test data\Stanton_Trip3_Plant1_BGNIR_50m_DSM\Stanton_Trip3_Plant1_BGNIR_50m_DSM.tif'
;FILENAME_MASK='E:\crop surface area\test data\Trip3_plant1_canopy_map_tif.tif'
;Reads DSM into an array
tiff_info_dsm=QUERY_TIFF(filename_dsm,info_dsm)
array_dsm = READ_TIFF(Filename_dsm,GEOTIFF=tifftags_dsm)


;Reads Mask into an array
array_mask =TEMPORARY(CANOPY_MASK)
;tiff_info_mask=QUERY_TIFF(filename_mask,info_mask)
;array_mask = READ_TIFF(Filename_mask,GEOTIFF=tifftags_mask)


array_volume = MAKE_ARRAY(info_dsm.DIMENSIONS[0], info_dsm.DIMENSIONS[1],/FLOAT, VALUE = 0)
dim_dsm=SIZE(array_dsm)
for colm = 0L, dim_dsm[1]-1 do begin
  for row = 0L, dim_dsm[2]-1 do begin
    
    array_volume[colm,row]= array_mask[colm,row]*((tifftags_dsm.MODELPIXELSCALETAG[0]*tifftags_dsm.MODELPIXELSCALETAG[1]*array_dsm[colm,row]));if needed 1/61024= cubic inches to cubic meter concersion
    
  endfor
endfor

;shift DSM range of (-ve,max) to start from zero onwards.
array_volume0=array_volume+abs(min(array_volume))
;negative dsm values too are from the point of interest and affects the volume estimation upon thresholding.
;Therefore it would be optimal to shift the DSM’s range to start at zero
TOTAL_VOLUME0=TOTAL(array_volume0)

;Grabs geo-corners for polygon shp file creation
    ;proj   = MAP_PROJ_INIT( 'UTM' , ELLIPSOID=tifftags_dsm.GEOGCITATIONGEOKEY , /GCTP , /RELAXED,ZONE=STRMID(TIFFTAGS_DSM.GTCITATIONGEOKEY, 17, 2) );yet to make -ve if S ELSE IF N THEN +VE
         
       minx = TIFFTAGS_DSM.MODELTIEPOINTTAG[3]   ;NEXT 4 LINES Locate the Ortho image's centre coordinates to get the static map
       maxy = TIFFTAGS_DSM.MODELTIEPOINTTAG[4]
       maxx = ( TIFFTAGS_DSM.MODELTIEPOINTTAG[3] + ( TIFFTAGS_DSM.MODELPIXELSCALETAG[0] * ( INFO_DSM.DIMENSIONS[0] - 1L ) ) )
       miny = ( TIFFTAGS_DSM.MODELTIEPOINTTAG[4] - ( TIFFTAGS_DSM.MODELPIXELSCALETAG[1] * ( INFO_DSM.DIMENSIONS[1] -1L ) ) )
       Print, minx, miny, maxx, maxy,(minx+maxx)/2,(miny+maxy)/2
;x=[497622.8949,497862.0061]       
;y=[4924932.4842,4924887.1497]
;latlon=MAP_PROJ_INVERSE(X , Y , MAP_STRUCTURE=proj )

;shapefile of entity type: Polygon, to store volume information
shp_file_name_components = [out_file_prefix, "_cs_volume.shp"]
volume_shp_file_name = shp_file_name_components.join('')
PRINT, volume_shp_file_name
mynewshape = OBJ_NEW('IDLffShape', volume_shp_file_name, /UPDATE, ENTITY_TYPE=5)

; Sets the attribute definition "volume"
mynewshape->IDLffShape::AddAttribute, 'Volume', 5, 10, PRECISION=2 

  ; Create structure for new entity
  entNew = {IDL_SHAPE_ENTITY}
  attrNew = mynewshape->IDLffShape::GetAttributes(/ATTRIBUTE_STRUCTURE)

  ; Define the values for the new entity
  entNew.ISHAPE = 0
  entNew.SHAPE_TYPE = 5
  entNew.BOUNDS[0] = minx
  entNew.BOUNDS[1] = miny
  entNew.BOUNDS[2] = 0.00000000
  entNew.BOUNDS[3] = 0.00000000
  entNew.BOUNDS[4] = maxx
  entNew.BOUNDS[5] = maxy
  entNew.BOUNDS[6] = 0.00000000
  entNew.BOUNDS[7] = 0.00000000
  entNew.N_VERTICES = 5
  v_vertices = [[minx,maxy],$
                [maxx,maxy],$
                [maxx,miny],$
                [minx,miny],$
                [minx,maxy]]
  p_pointer = ptr_new(v_vertices)
  entNew.VERTICES = p_pointer               
  attrNew.ATTRIBUTE_0 = TOTAL_VOLUME0
  mynewshape->IDLffShape::PutEntity, entNew
  mynewshape->IDLffShape::SetAttributes,0, attrNew
  print,' exported to shapefile !!'
  OBJ_DESTROY, mynewshape
;WRITE_TIFF,'E:\crop surface area\test data\IDLoutput\cs_volume.tif',array_volume,/FLOAT,GEOTIFF=tifftags_dsm

end



