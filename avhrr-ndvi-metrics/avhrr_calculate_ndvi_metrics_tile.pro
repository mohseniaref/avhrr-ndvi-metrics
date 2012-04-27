;Jinag Zhu, jiang@gina.alaska.edu, 2/22/2011
;This program interpolates and smoothes a multiyear_layer_stack file and calculate metrics of mid-year data.
;The input is:a oneyear_stack file
;the output is:
;a mid-year smoothed data file named multiyear_layer_stack_smoothed,
;a metrics file named multiyear_layer_stack_smoothed_metrics.
;flg indicating if this program run successfully.

;This program breaks the huge data into tiles and goes through tile loop to proces each tile. For each tile, go through
;each pixel to calulate the metrics and smoothed time series of the pixel. 
;jzhu, 1/17/2012,this program combines moving average and threshold methodm it calls geoget_ver16.pro and sosget_ver16.pro. 


;jzhu, 4/24/2012, modified from modis ndvi metrics calculation program "smooth_calculate_metrics_tile_ver9.pro"

pro avhrr_calculate_ndvi_metrics_tile,filen,flg

;flg (indicate if the program run successful, 0--successful, 1--not successful)
;filen-- one-year-stacked and smoothed avhrr file
;

;test only, for simplisity

filen_sm='/mnt/jzhu_scratch/nps-cesu/avhrr/ak_nd_1982sm'

filen = '/mnt/jzhu_scratch/nps-cesu/avhrr/ak_nd_1982'


;---make sure the program can work in both windows and linux.

if !version.OS_FAMILY EQ 'Windows' then begin

sign='\'

endif else begin
sign='/'

endelse

;----1. produces output metrics file name

p =strpos(filen,sign,/reverse_search)

len=strlen(filen)

wrkdir=strmid(filen,0,p+1)

filebasen=strmid(filen,p+1,len-p)

year=strmid(filebasen,6,4)

;----define output file name 

fileout_metrics=wrkdir+filebasen+'_metrics'

openw,unit_metrics,fileout_metrics,/get_lun

;---start ENVI batch mode
 
start_batch, wrkdir+'b_log',b_unit

;---setup a flag to inducate this program work successful. flg=0, successful, flg=1, not successful

flg=0;  0----successs, 1--- not sucess

;---2. open the input files

envi_open_file,filen,/NO_REALIZE,r_fid=rt_fid


if rt_fid EQ -1 then begin

flg=1  ; 0---success, 1--- not success

return  ;

endif

;---open the input file

envi_open_file,filen_sm,/NO_REALIZE,r_fid=rt_fid_sm


if rt_fid_sm EQ -1 then begin

flg=1  ; 0---success, 1--- not success

return  ;

endif


;---3. get the information of the input file

envi_file_query, rt_fid,data_type=data_type, xstart=xstart,ystart=ystart,$
                 interleave=interleave,dims=dims,ns=ns,nl=nl,nb=nb,bnames=bnames

pos=lindgen(nb)

;---inital tile process

  tile_id = envi_init_tile(rt_fid, pos, num_tiles=num_of_tiles, $
    interleave=(interleave > 1), xs=dims(1), xe=dims(2), $
    ys=dims(3), ye=dims(4) )




;---- get the information of input file_sm

envi_file_query, rt_fid_sm,data_type=data_type, xstart=xstart,ystart=ystart,$
                 interleave=interleave,dims=dims,ns=ns,nl=nl,nb=nb,bnames=bnames
pos=lindgen(nb)

;---inital tile process

  tile_id_sm = envi_init_tile(rt_fid_sm, pos, num_tiles=num_of_tiles_sm, $
    interleave=(interleave > 1), xs=dims(1), xe=dims(2), $
    ys=dims(3), ye=dims(4) )



;---define a data buff to store the band names of the metrics

bnames_metrics = ['onp','onv','endp','endv','durp','maxp','maxv','ranv','rtup','rtdn','tindvi','mflg']

vmetrics=fltarr(12); use for store metrics

;----5. precess ecah time-series

for i=0l, num_of_tiles-1 do begin  ; every line

;data=envi_get_slice(/BIL,fid=rt_fid,line=i)

data = envi_get_tile(tile_id, i)
data_sm=envi_get_tile(tile_id_sm,i)
  
sz=size(data)

num_band=sz(2) ; number of points in a time-series vector

;---produce bname for the time series

bname = avhrr_produce_band_name(num_band, fix(year) )
;---time-series-vector loop, process each time-series-vector in the tile i

for j=0l, sz(1)-1 do begin

;---print out the information about which tile and which time-series vector is being processed.

print, 'process tile: '+strtrim(string(i),2) +' of '+strtrim(string( num_of_tiles-1 ),2), $
       ', sample: '+strtrim(string(j),2) +' of '+ strtrim(string( sz(1)-1  ),2)




;--- convert a time-series data into a vector

tmp=transpose(data(j,*) ) ; band vector
tmp_sm=transpose(data_sm(j,*) )

if i EQ 164  and j EQ 215 then begin

print, 'test'

endif


;--calcualte ndvi metrics of the time series 
;--time series include 42 bands, band name will be like 19820101,19820111,19820121,19820201...
;
avhrr_time_series_process,tmp,tmp_sm,bname,vmetrics

;---define data_smoothed to store smoothed data if it is the first time-series vector process

if i EQ 0 and j EQ 0l then begin  ; the very first sample loop, only execuated once

;nb_smooth =n_elements(tmp_sm)
;bnames_smooth=bname

nb_metrics=n_elements(vmetrics)
data_metrics=fltarr(sz(1),nb_metrics)

;---- output header infor for metrics data file
map_info=envi_get_map_info(fid=rt_fid_sm)
data_type=4 ; float for metrics
envi_setup_head, fname=fileout_metrics, ns=ns, nl=nl, nb=nb_metrics,bnames=bnames_metrics, $
    data_type=data_type, offset=0, interleave=(interleave > 1),$
    xstart=xstart+dims[1], ystart=ystart+dims[3],map_info=map_info, $
    descrip='avhrr one-year metrics data', /write


endif

;data_smooth(j,*) = byte(round(mid_smooth) )

data_metrics(j,*) = vmetrics

endfor  ; sample loop

;---write data_smooth of one tile

;writeu,unit_smooth,data_smooth

writeu,unit_metrics,data_metrics


endfor  ; line loop

;---close files

;free_lun, unit_smooth

free_lun, unit_metrics


envi_tile_done, tile_id
envi_tile_done, tile_id_sm


;---- exit batch mode

ENVI_BATCH_EXIT

print,'finishing calculation of metrics ...'

return

end

