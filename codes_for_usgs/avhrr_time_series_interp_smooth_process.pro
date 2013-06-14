;jiang Zhu, 2/17/2011,jiang@gina.alaska.edu
;This program calls subroutines to interpolate a three-year time-series data,
;smooth mid-year time-series data, and calculate the metrics for the mid-year time-series data.
;The inputs are: 
;tmp (three-year-time-series-cvector), 
;bnames (three-year-time-series-vector name),
;threshold (fill value for no data, 60b),
;snowcld (fill value for snow and cloud, 60b),
;outputs are:
;mid_interp (mid-year interpolated vector),
;mid_smooth (mod-year smoothed vector),
;mid_bname (mid-year smoothed vector's band names),
;vmetrics (mid-year metrics).
 
;jzhu, 5/5/2011, use the program provided by Amy to do moving smooth and calculate the crossover
 
;jzhu, 9/8/2011, ver9 processes the one-year-stacking file which includes ndvi and bq together.  

;jzhu, 3/5/2013, uses raw time series, interpolate, and smooth it
pro avhrr_time_series_interp_smooth_process,tmp,bn,out_v

;initialize the out_v
out_v=fltarr(12)

;---- values in tmp: 0--no data, out of swath, > 0, valid data
idx=where(tmp EQ 0,cnt)
if cnt EQ n_elements(tmp) then begin
out_v(11)=-2.0 ;no data, out of swath
return
endif

;-------interpolate and smooth time series
a=-100
sfactor=0.01

;---- calls interpol_extension_1y_vector_ver9.pro to process one-year data, do one-year vector extension, then inpterpolate

;avhrr_interpol_noextension_1y_vector,tmp,tmp_bn,ratio,tmp_interp,interp_flg

;----- calculate metrics-----------------------------

wls_smooth, tmp,1,1,tmp_sm

;tmp_sm=tmp

;convert 100-200 into 0.0-1.0
 

tmp1 =( tmp +a )*sfactor

tmp_sm1 =( tmp_sm +a )*sfactor


;---2.add a condition to eliminate the pixels when max(tmp) is less than 0.2 (range is in 0-1.0)

ndvi_max =max(tmp_sm1)
idx_max=where(tmp_sm1 EQ ndvi_max )

;---assume maximun ndvi should occur in the range of 5/01 (120 days, idx= 12) to 10/30 (305 days, idx=30) 

if ndvi_max LE 0.2 or $
   idx_max[0] LT 12 or idx_max[0] GT 30 then begin

    out_v(11)=-1  ; not valid data, because its maximum ndvi is less than or equal to 0.2
                  ; or maximun value is not in the range, could be ocean or land without vegatation
 
    return

endif 

bpy =n_elements(tmp_sm)  ; num of band in one year, 42

bq=bytarr(bpy)

bq(*)=0     ;assume every point is good quality,
            ;0--good, 1--cloudy, 2--bad, 3--negative reflectance, 4--snow, 10--fill

CurrentBand=10

DaysPerBand=10  ; day interval between two consecituve bands =7 days

;---get the day between two 7-day band

intv_day = fix( strmid( bn(1),7,3 ) )-fix(strmid( bn(0),7,3 ) ) 

;This is the interval days between two measurement weeks. The band name format is:n-yyyy-ddd-ddd.

start_day =fix(strmid( bn(0),7,3) ) ; this is the first date of the first measurement week

;---initalize metrics flag

mflg=0    ; initial value 0, 0---not valid metrics, 1-- valid metrics

wl=[24,24]  ;for modis ndvi, 7 days/period, 35*7=245 days, 
            ;for avhrr ndvi, 10 days/period,22*10=240 days

metrics=ComputeMetrics_by1yr(tmp_sm1, tmp1, bq, bn, wl,bpy,CurrentBand,DaysPerBand)

;convert sost->onp, sosn->onv, eost->endp,eosn->endv

onp=metrics.sost
onv=metrics.sosn
endp=metrics.eost
endv=metrics.eosn


;---get additional condition to make sure the metrics calculation is resonable. default condition is
;---the end-of-greenness -stsrt-of-grenness must greater than 30 days. pay attention this condition

if endp LE 0 or onp LE 0 then begin

out_v(11) = 0.0 ; no valid data, because can not calculate sos or eos 

return

endif 


maxp=metrics.maxt

maxv=metrics.maxn


;---convert onp, endp, maxp into related day labels, because onp,endp,maxp are float data, they indicate exect day


onpday = findday(bn, onp) ;day

endpday= findday(bn,endp);day


;--- add another condition: assume SOS must great than 2/15 = 45 days of year
;----and eos must less than 11/15=320 days of year

if endpday GT 320 or onpday LT 45 or endpday - onpday LT 30 then begin

out_v(11)=0 ; not valid data, because sos and eos is not in the range 45 to 320 or days od season is shorter than 30 days

return

endif


maxpday= findday(bn,maxp);day

ranv =metrics.rangeN

rtup= metrics.slopeup     ; positive, ndvi/day

rtdnp=-metrics.slopedown  ; negative, ndvi/day

tindvi=metrics.totalndvi ;ndvi*day

out_v[0]=onpday ;unit day
out_v[1]=onv    ;normalized ndvi
out_v[2]=endpday ;unit day
out_v[3]=endv   ;normoalized ndvi
out_v[4]=endpday-onpday ;unit day
out_v[5]=maxpday ;unit day
out_v[6]=maxv ; normalized ndvi
out_v[7]=ranv; normalized ndvi
out_v[8]=rtup; slopeup, ndvi/day
out_v[9]=rtdnp ;slopedown, ndvi/day 
out_v[10]=tindvi; ndvi*day

out_v[11]=1.0 ; valid data

return

end