FUNCTION  GetSOS_ver16, Cross, NDVI, bq, x, bpy, FMA
;
; These numbers are the window (*bpy) from the
; current SOS in which to look for the next SOS
; jzhu, 9/12/2011, found SOS and EOS is very snesitive to the windows range of moving average.
; getSOS2.pro choose the the sos from the candidate point with minimun ndvi, try to use maximun slope difference to determine the sos
; jzhu, 9/23/2011, cross includes crossover, 20% points, and maxslope point, pick reasenable point as SOS among cross
; 
;if sos_possib1 > 20% point, sos_possib2 = sos_possi1, otherwise sos_possb2 = 20%point,find a nearest point from eos_possb2 to 1, which is not snow point, 
;this point is SOS
    
FILL=-1.
WinFirst=1.0
WinMin=0.5
WinMax=1.5

;---get idx of maximun ndvi point
mxidx=where(NDVI EQ max(NDVI))
mxidxst=mxidx(0)
mxidxed=mxidx(n_elements(mxidx)-1) 
lastidx=n_elements(NDVI)-1 ; lastidx
;
; Calculation the slope of ndvi and fma for slope method
;
      nFMA=n_elements(FMA)
      FSlope=fltarr(nFMA-1)
      For i = 0, nFMA-2 DO $
         FSlope[i]=FMA[i+1]-FMA[i]

      nNDVI=n_elements(NDVI)
      NSlope=fltarr(nNDVI-1)
      For i = 0, nNDVI-2 DO $
         NSlope[i]=NDVI[i+1]-NDVI[i]


      ny=N_Elements(NDVI)/bpy
      SOST=fltarr(ny)
      SOSN=fltarr(ny)

;
; NOTE: I still need to do something in case it doesn't find a first sos
;

      nSize=Size(NDVI)
      ny=nSize[nSize[0]]/bpy + (nSize[nSize[0]] mod bpy gt 0)

   CASE (nSize[0]) OF

      1: BEGIN
         SOST=fltarr(ny)+FILL
         SOSN=fltarr(ny)+FILL
;
; First SOS must be within first WinFirst*bpy and must less then min(mxidxst,0.5*bpy)
;
     
;----find the first 20%point as x20
idx20=where(cross.t EQ 1,cnt1)

if cnt1 LE 0 then begin  ; <2> if no 20% point, set sosx as possiblx

idx2=where (cross.t EQ 0,cnt2)

if cnt2 GT 0 then begin
 x20=cross.x( idx2(0) ) 
 y20=cross.y( idx2(0) )
endif else begin
 idx3=where(cross.t EQ 2, cnt3)
 x20=cross.x( idx3(0) )
 y20=cross.y( idx3(0) )
endelse

;x20=0
;y20=0
;sosx=0
;sosy=0
;goto,lb11

endif else begin  ; <2> compare possibx with 20% point,<2>

;--when there are more than one 20% points, choose one which is the most close to the maximun slop point
;slopex=( cross.x(where(cross.t EQ 2) ) )(0)
;gapmin = min(  abs(cross.x(idx20)-slopex)  )
;x20=cross.x(  (where( abs(cross.x - slopex) EQ  gapmin ) )(0)  )
;y20=cross.y(  (where( abs(cross.x - slopex) EQ  gapmin ) )(0)  )

;---when there are more than one 20% points, choose one which is the closest to possibx
;if possibx GT 0 then begin
;gapmin=min(abs(cross.x(idx20)-possibx))
;x20=cross.x( (where(abs(cross.x-possibx) EQ gapmin))(0) )
;y20=cross.y( (where(abs(cross.x-possibx) EQ gapmin))(0) )
;endif else begin
;slopex=( cross.x(where(cross.t EQ 2) ) )(0)
;gapmin = min(  abs(cross.x(idx20)-slopex)  )
;x20=cross.x(  (where( abs(cross.x - slopex) EQ  gapmin ) )(0)  )
;y20=cross.y(  (where( abs(cross.x - slopex) EQ  gapmin ) )(0)  )
;endelse

;--when more than one 20% points, choose the first one

x20=cross.x( idx20(0) )
y20=cross.y( idx20(0) )

endelse  ;<2>

;---------  find possibx in cross_only, 

     t0idx = where(cross.t EQ 0,t0cnt) ; t0--crossover type
  
     if t0cnt LT 1 then begin ; <0> no  crossover points, possiblex=0
     possibx=0
     possiby=0
     
     endif else begin ; <0> looking for possiblex
     
       cross_only={X:cross.x(t0idx), Y:cross.y(t0idx), S:cross.s(t0idx),T:cross.t(t0idx),C:cross.c(t0idx), N:t0cnt}
       
       ;  FirstIdx=where(Cross_only.X LT WinFirst*bpy and Cross_only.X LT min([mxidxst,0.5*bpy]), nFirstSOS)
          FirstIdx=where(Cross_only.X LT WinFirst*bpy and Cross_only.X LT min([mxidxst,26]), nFirstSOS)
          
          ;I think possibx never houldn't be great than 28 for total 42 band
          
         if firstidx[0] EQ -1 then begin
         firstidx=0
         nFirstSOS=0
        endif
            
         
    if(nFirstSOS gt 0) THEN  BEGIN   ; <1> have possiblex <1>    



; 4 possible methods, test which methos is the best 

;
; a. Min ND Method
;
;      FirstSOSIdx=where(Cross.y[firstidx] eq $
;                          min(Cross.y[firstidx]))

;
; b. maximun Slope Method, orginal was miminun, jzhu thinks it should be maximun
;
;      FirstSOSIdx=where(NDVI[fix(Cross.x[firstidx])] eq $
;                    max(NDVI[fix(Cross.x[firstidx])]))

;
; c. maximun slope difference (slope of NDVI - slope of FMA ) Method
;
;
;      FirstSOSIdx=where(NSlope[fix(Cross_only.x[firstidx])]-FSlope[fix(Cross_only.x[firstidx])] eq $
;                    max(NSlope[fix(Cross_only.x[firstidx])]-FSlope[fix(Cross_only.x[firstidx])]))

;
; d. Maximun ND Change Method
;
;      FirstSOSIdx=where(NDVI[fix(Cross.x[firstidx]+2)]-NDVI[fix(Cross.x[firstidx])] eq $
;                    max(NDVI[fix(Cross.x[firstidx]+2)]-NDVI[fix(Cross.x[firstidx])]))

; e. get slopes of each firstidx by using next 4 points linfit       
    ;         numtype0=n_elements(firstidx)
    ;         slopes=fltarr(numtype0)
    ;         for kk=0,numtype0-1 do begin
    ;          xx=fix([cross_only.x[firstidx(kk)]+3, cross_only.x[firstidx(kk)]+2, cross_only.x[firstidx(kk)]+1,cross_only.x[firstidx(kk)] ])
    ;          yy=ndvi(xx)
    ;          tmp= linfit(xx,yy)
    ;          slopes(kk)=tmp(1)
    ;         endfor 
    ;         firstsosidx = where(slopes EQ max(slopes) )
; f. use slope in cross_only to pick the greatest slope
;           FirstSOSIdx= where(cross_only.s(firstidx) EQ max( cross_only.s(firstidx) ) )              
               
; g. use the crossover point which is the most close to the 20% point as possibx

           FirstSOSIdx =where( abs(cross_only.x(firstidx)-x20) EQ min( abs(cross_only.x(firstidx)-x20 ) ) )
             
                
;---- check FirstSOSidx(0), if it is snow(4b), compare it with 20% point,

         possibx = cross_only.X[ FirstSOSIdx[n_elements(FirstSOSidx)-1 ] ]
         possiby = cross_only.Y[ FirstSOSIdx[n_elements(FirstSOSidx)-1 ] ]

   endif else begin ;<1> not found possiblex
     possibx=0
     possiby=0
   endelse  ; <1>                

endelse  ;<0>
          



;---- compare x20 and possiblex

       if possibx GT 0 then begin 
        if possibx LT x20 then begin  ;  make sure possiblx equal or greater than x20
        
        possibx=x20
        possiby=y20
        
        endif else begin
        
;        print, 'possibx Greater than x20'
        
        endelse 
       endif else begin
       possibx=x20
       possiby=y20
       endelse
        
        
        if possibx LE 2 or possibx GE lastidx-2 then begin  ;<5>
        
        sosx=0
        sosy=0
        endif else begin  ;<5>
        
         ;if ( bq( fix(possibx) ) NE 4b ) and ( bq( fix(possibx)+1 ) NE 4b ) then begin ;possibx is not snow point, found sosx
         ; guarantee the sos is good point; more strict than guarantee it is not snow point
;         v=possibx mod fix(possibx)
;        if ( v EQ 0 and bq( fix(possibx) ) EQ 0b and bq(fix(possibx)+1) EQ 0b ) $
;        or ( v NE 0 and bq( fix(possibx)+1) EQ 0b and bq(fix(possibx)+1) EQ 0b ) then begin

         if bq(fix(possibx)) EQ 0b and bq(fix(possibx)+1) EQ 0b and fix(possibx)+1 LE lastidx  then begin ;<4>      

         sosx=possibx
         sosy=possiby

         endif else begin ;<4> possibx is snow, found true sosx between possibx+1 to mxidxst <4>
         
         x20g = where( bq( fix(possibx)+1 : n_elements(bq)-1  ) EQ 0b, possibcnt )
         
         if possibcnt GT 0 then begin 
         
         sosx= fix(possibx)+1+x20g(0)
         sosy=ndvi(sosx)
         
         endif else begin 
         
         sosx=0
         sosy=0
         
         endelse
          
         
         endelse  ; endof <4>   
         endelse  ; <5>
         
        

lb11:
     
          FirstSOST=sosx
          FirstSOSN=sosy
          CurX=FirstSOST


IF FirstSOST LT bpy THEN BEGIN
         SOST[0]=FirstSOST
         SOSN[0]=FirstSOSN
         istart=1
END ELSE BEGIN
         SOST[0]=FILL
         SOSN[0]=FILL
         SOST[1]=FirstSOST
         SOSN[1]=FirstSOSN
         istart=2
END

;
; From first SOS, go at least half year, not more than 1.5 years
;
         FOR i = istart, ny-1 DO BEGIN


            NextIdx=where(Cross.X GT CurX+bpy*WinMin and $
                          Cross.X LT CurX+bpy*WinMax, nNext)

            IF (nNext gt 0) THEN BEGIN

;
; Min ND Method
;
               NextSOSIdx=where(Cross.y[NextIdx] eq $
                            min(Cross.y[NextIdx]))

               SOST[i]=Cross.x[NextIdx[NextSOSIdx[0]]]
               SOSN[i]=Cross.Y[NextIdx[NextSOSIdx[0]]]
               CurX=SOST[i]

            END ELSE CurX=CurX+bpy

         END;FOR 

         ;SOST=rmzeros(sost, /trail)
         ;SOSN=rmzeros(sosn, /trail)

         SOS={SOST:SOST, SOSN:SOSN}

      END;nSize[0]=1, case 1

      3: BEGIN
         FirstSOST=fltarr(nSize[1],nSize[2])
         FirstSOSN=fltarr(nSize[1],nSize[2])
         CurX=fltarr(nSize[1],nSize[2])
         SOST=fltarr(nSize[1],nSize[2],ny)+FILL
         SOSN=fltarr(nSize[1],nSize[2],ny)+FILL

         FOR i = 0, nSize[1]-1 DO BEGIN
            FOR j = 0, nSize[2]-1 DO BEGIN

               FirstIdx=where(Cross.X[i,j,*] LT WinFirst*bpy AND $
                              Cross.X[i,j,*] GE 0, nFirstSOS)

; Earliest Method
;               FirstSOSIdx=where(NDVI[fix(Cross.x[i,j,firstidx])] eq $
;                             min(NDVI[fix(Cross.x[i,j,firstidx])]), nmin)

if firstidx[0] EQ -1 then firstidx=0

; Min ND method
               IF (nFirstSOS GT 0) THEN BEGIN
                  FirstSOSIdx=where(Cross.y[i,j,firstidx] eq $
                             min(Cross.y[i,j,firstidx]), nmin)


                  FirstSOST[i,j]=Cross.x[i,j,FirstIdx[FirstSOSIdx[0]]]
                  FirstSOSN[i,j]=Cross.Y[i,j,FirstIdx[FirstSOSIdx[0]]]
               END ELSE BEGIN
                  FirstSOST[i,j]=0
                  FirstSOSN[i,j]=0
               END

               CurX[i,j]=FirstSOST[i,j]

               SOST[i,j,0]=FirstSOST[i,j]
               SOSN[i,j,0]=FirstSOSN[i,j]

               FOR k = 1, ny-1 DO BEGIN

                  NextIdx=where(Cross.X[i,j,*] GT CurX[i,j]+bpy*WinMin AND $
                                Cross.X[i,j,*] LT CurX[i,j]+bpy*WinMax, nNext)

                  IF (nNext gt 0) THEN BEGIN

                     NextSOSIdx=where(Cross.y[i,j,NextIdx] eq $
                                  min(Cross.y[i,j,NextIdx]), nmin)

                     SOST[i,j,k]=Cross.x[i,j,NextIdx[NextSOSIdx[0]]]
                     SOSN[i,j,k]=Cross.Y[i,j,NextIdx[NextSOSIdx[0]]]
                     CurX[i,j]=SOST[i,j,k]


                  END ELSE CurX[i,j]=CurX[i,j]+bpy

               END; FOR k
            END; FOR j 
         END; FOR i 
         
         SOS={SOST:SOST, SOSN:SOSN}

      END;nSize[0]=3


      ELSE:
   ENDCASE




RETURN, SOS
END
