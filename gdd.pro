; NAME: GDD
;
; PURPOSE:
; Gives the Growing Degree Days (GDD) from the closest station available (3rd party data from the Climate Prediction Center,NOAA)
; 
; CALLING SEQUENCE:
; Result =GDD(day,MONTH,YEAR,LOCAL_HOUR,LOCAL_MINUTES,Latitude,Longitude)
;
; INPUTS:
; For example,to use 06/25/2015 , 9:58pm @ (44.47770000,-93.02988889),the accepted input type/format is as below
; day=25    
; MONTH=6
; YEAR=2015
; LOCAL_HOUR=21         ; 24 hour format
; LOCAL_MINUTES=58
; Latitude = 44.47770000
; Longitude = -93.02988889
;
; OUTPUTS:
; Returns the GDD value from the nearest station available.
; More detailed explanation/progress will be displayed in the command line during execution (see URL below for screenshot)
; Ex: 
;    IDL> result=GDD(25,6,2015,21,58,44.47770000,-93.02988889)
;         Input sample date  : 6/25/2015
;         1 week old GDD file lies between: MAR 1 - SEP  5, 2015
;         2 week old GDD file lies between: MAR 1 - AUG 29, 2015
;         3 week old GDD file lies between: MAR 1 - AUG 22, 2015
;         The one closest to 6/25/2015 is the 3 week old file
;         ------------------------------------------------------------------------------------------------------
;         Input LAT-LONG: (44.4777,-93.0299) falls at: DENNISON,MN
;         There are 10 available Stations providing GDD in MN
;         Out of which, the closest to DENNISON,MN is MINNEAPOLIS which is at a distance of 75.1870km having GDD of:  2497
;         
;         (checkout the output screenshot at  https://goo.gl/LfWcTu)
;         
; SCOPE FOR IMPROVEMENT:
; the variables within the function namely:
;             RESULT  -------> contains distance sorted GDD values
;             RESULT_DISTANCE> contain sorted Distances from the input location (in meters)  
;             RESULT_CITY  --> contains distance sorted City names within the specified State  
; >>to interpolate the GDD using the 3 nearest station data available from above variables              
; 
; LAST MODIFIED: 15-Sep-2015
;   
function gdd,day,MONTH,YEAR,LOCAL_HOUR,LOCAL_MINUTES,latitude,longitude
  compile_opt idl2
  ;time_stamp_string = SYSTIME([0], timestamp_collect ,/UTC)
  ;time = BIN_DATE(time_stamp_string)
  ;Day = time[2]
  ;Month = time[1]
  ;Year = time[0]
  ;Local_hour = time[3]
  ;Local_minutes = time[4]

 
  julday_data=julday(MONTH,day,year)
  print,'Input sample date  : ' +STRTRIM(STRING(month),2)+'/'+STRTRIM(STRING(Day),2)+'/'+STRTRIM(year,2)

  ;--------------------------------------------------------------------------------------------------
  ;PICKS NEAREST DATED GDD FILE AMONGST THE THREE
  ;--------------------------------------------------------------------------------------------------
  julday_GDD=LONARR(3) ; to store the julian date of the three GDD files
  for index = 0L, 2 do begin

    sub_url=STRTRIM(index+1,1)
    url='http://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/pastdata/degree_days/grodgre'+ sub_url +'.txt'
    ourl = obj_new('IDLnetURL')
    content = ourl->get(/string_array, URL=url)
    obj_destroy, ourl

    file_no=sub_url
    print,' '+sub_url+' week old GDD file lies between: ',STRTRIM(content[2],1);contains date of the downloaded GDD file (MAR 1 - AUG 29, 2015)
    GDD_month=STRMID(STRTRIM(content[2],1), 8, 3)
    GDD_day=UINT(STRMID(STRTRIM(content[2],1), 12, 2))
    GDD_year=UINT(STRMID(STRTRIM(content[2],1), 16, 4))
    CASE GDD_month OF        ;converting month in string to interger between 1 to 12)
      'JAN': GDD_month=1
      'FEB': GDD_month=2
      'MAR': GDD_month=3
      'APR': GDD_month=4
      'MAY': GDD_month=5
      'JUN': GDD_month=6
      'JUL': GDD_month=7
      'AUG': GDD_month=8

      'OCT': GDD_month=10
      'NOV': GDD_month=11
      'DEC': GDD_month=12
      ELSE: GDD_month=9 ; i.e. September
    ENDCASE
    julday_GDD[index] = JULDAY(GDD_MONTH,GDD_DAY,GDD_year)
  endfor
  jul_unsorted=[JULDAY_GDD,JULDAY_DATA]
  jul_sorted=SORT(jul_unsorted)         ;contains index of the sort order
  jmatch=WHERE(JUL_UNSORTED eq JULDAY_DATA)
  JULIAN_required=JUL_UNSORTED[JMATCH-1] ; containts the julian date of that GDD file which is closest to the input date
  ;Downloads the appropriate GDD file among the three
  sub_url=where(JULDAY_GDD eq JULIAN_REQUIRED[0])
  sub_url=STRTRIM(sub_url[0],1)
  url='http://www.cpc.ncep.noaa.gov/products/analysis_monitoring/cdus/pastdata/degree_days/grodgre'+ sub_url +'.txt'
  ourl = obj_new('IDLnetURL')
  content = ourl->get(/string_array, URL=url)
  obj_destroy, ourl
  ;print,'The '+sub_url+' week old GDD file is the closest available which falls between ',STRTRIM(content[2],1)
  print,'The one closest to '+STRTRIM(STRING(month),2)+'/'+STRTRIM(STRING(Day),2)+'/'+STRTRIM(year,2)+' '+'is the '+ file_no +' week old file'


  ;-----------------------------------------------------------------------------------------------------------------
  ;REVERSE GEOCODING TO FIND THE CLOSEST STATION IN THE GDD FILE
  ;-----------------------------------------------------------------------------------------------------------------

  ;URL='http://maps.googleapis.com/maps/api/geocode/json?latlng=44.47770000,-93.02988889'
  URL='http://maps.googleapis.com/maps/api/geocode/json?latlng='+STRTRIM(latitude,1)+','+STRTRIM(longitude,1)
  ourl = obj_new('IDLnetURL')
  LOC_content = ourl->get(/string_array, URL=url)
  obj_destroy, ourl
  loc_CONTENT=loc_content[0:32];ELIMINATE unrequired string from downloaded JSON

  ST=LOC_CONTENT[31].compress(); Ex:  "short_name" : "MN",
  ST=st.Substring(14, 15)
  CITY=LOC_CONTENT[15].compress();"long_name" : "Dennison",
  CITY = city.Split('"') ; IDL outputs city name IN CITY[3] Ex: Dennison
  CITY=CITY[3].ToUpper( )
  ST_CITY_TEMPLATE=ST+'  '+CITY
  PRINT,'------------------------------------------------------------------------------------------------------'
  PRINT,'Input LAT-LONG: '+'('+STRTRIM(latitude,1)+','+STRTRIM(longitude,1)+')'+' '+'falls at: '+CITY+','+ST
  TEST=CONTENT.Contains(ST_CITY_TEMPLATE) ;Result contains 1B if found to exist and rest is zero
  TRUE_INDEX=WHERE(TEST EQ 1B); Ex: TRUE_INDEX is 9 for 'AL  ANNISTON'

  if (TRUE_INDEX NE -1L) then begin ;checking if the WHERE output contains a valid index or not
    ACCUM_GDD= STRSPLIT(CONTENT[TRUE_INDEX], ' ', /EXTRACT);CONTENT[TRUE_INDEX] will contain row corresponding to the matching ST & CITY iff it exists
    ACCUM_GDD=ACCUM_GDD[3];CONTAINS THE required ACCUM_GDD VALUE from the downloaded GDD file
    print,'Your CORN Field at '+ST_CITY_TEMPLATE+' is expected to reach COMPLETE MATURITY in '+ACCUM_GDD+' degree days.'
  endif else begin

    ;The following block interpolates the closest GDD value

    ;----------------------------------------------------------------------------------------
    ;Extracts cities from the same state
    TEST=STREGEX(CONTENT, ' '+ST+' ');outputs zero if the specified state is present, else -1B
    TRUE_INDEX=WHERE(TEST EQ 0B);Index that points to Cities of the same State
    print,'There are '+STRTRIM(N_ELEMENTS(content[TRUE_INDEX]),1),' available Stations providing GDD in '+ST
    ;print,content[TRUE_INDEX];contains Available Stations in the same State
    ;------------------------------------------------------------------------------------------
    DISTANCE_content = ULONARR(N_ELEMENTS(content[TRUE_INDEX]));stores distance value obtained in the for loop below
    for i = 0L, (N_ELEMENTS(content[TRUE_INDEX]))-1 do begin
      sub_url=STRTRIM(content[TRUE_INDEX[i]].Substring( 4 , 20 ),2)
      url='http://maps.googleapis.com/maps/api/distancematrix/json?origins='+ STRTRIM(Latitude,1) + ',' + STRTRIM(LONGITUDE,1) +'&destinations='+sub_url+ '+' +ST
      ourl = obj_new('IDLnetURL')
      temp = ourl->get(/string_array, URL=url)
      obj_destroy, ourl
      dist_true=STRCMP(temp.compress(), '"distance":{');used in indexing the string '"distance":{' present in the downloaded distance metrics
      dist_INDEX=WHERE(dist_true eq 1B);contains the index
      temp=ULONG(((temp[dist_INDEX+2].compress()).Substring(8))[0]); Contains distance in meters
      DISTANCE_content[i]=TEMP; will contain distances of all the available stations in cities within a specific state
    endfor

  endelse

  order=sort(distance_content) ; sorted index of distances
  result_distance=distance_content[order];array of sorted distances
  city_names=STRTRIM(content[TRUE_INDEX].Substring( 4 , 20 ),2);contains stations at cities from the same State
  result_city=city_names[order];cities sorted acc to distance from input cornfield
  ;Extracting the GDD of the closest station
  ACCUM_GDD=(content[true_index])[order];contains distance sorted rows along with GDDs (to filter out GDD values further)
  GDD_values=FIX(accum_gdd.Substring(28, 32))
  print,'Out of which, the closest to '+CITY+','+ST+' is '+ result_city[0] + ' which is at a distance of '+STRTRIM((result_DISTANCE[0]/1000.00),2)+'km'+' having GDD of: '+accum_gdd[0].Substring(28, 32)
  result=FIX(accum_gdd.Substring(28, 32))
  return,result[0]
end
