;
; Alain Coulais, 5 Janvier 2011, under GNU GPL v2 or later
;
; few tests can help to check whether the
; computations are in good range or not
;
; this code should be able to run on box without X11,
; and should be OK for Z, SVG and PS
;
; Nota-bene : IDL moved to Mersemme Twister since 8.2.2
;
; ---------------------------------------
; Modifications history :
;
; - 2017-11-09 : AC (uncommited at that time)
;  * renaming with prefix "TEST_"; 
;  * adding error counting for TEST_RANDOM_BINOMIAL.
;  * adding TEST_RANDOM_MERSENNE since GDL can now have 
;    same numerical outputs than IDL since 8.4 (and FL since 0.79.41)
;  * adding TEST_RANDOM_ULONG
;
; - 2017-12-13 : AC: adding TEST_RANDOM_POISSON, num. tests found.
;
; - 2019-12-23 : AC: better managment of DSFMT_EXISTS()
;
; - 2020-04-30 : AC: should work when !d.name=Null ! (AKA config. Mini)
;   Should work for IDL & FL (pb with DSFMT_EXISTS())
;
; ----------------------------------------------
;
function STATUS_OF_DSFMT, test=test, verbose=verbose
;
FORWARD_FUNCTION DSFMT_EXISTS
;
; flag is 0 for IDL & FL, or old GDL
flag=0
;
if (GDL_IDL_FL() EQ 'GDL') then begin
   ;; we may run this code with old GDL version without DSFMT_EXISTS()
   res=EXECUTE('dsfmt_flag=DSFMT_EXISTS()')
   if (res) then begin
      if KEYWORD_SET(verbose) then $
         print, GDL_IDL_FL(), ', DSFMT_EXISTS() = ', dsfmt_flag
      ;; do we use it ?? (if activated by !gdl.GDL_USE_DSFMT)
      if dsfmt_flag then begin
         gdltags=TAG_NAMES(!gdl)
         ok=WHERE(STRPOS(gdltags, 'GDL_USE_DSFMT') EQ 0, nb_ok)
         if nb_ok then begin
            if (!gdl.GDL_USE_DSFMT EQ 1) then flag=1
            if KEYWORD_SET(verbose) then $
               print, GDL_IDL_FL(), ', !gdl.GDL_USE_DSFMT : ', flag
         endif else print, GDL_IDL_FL(), ' no !gdl.GDL_USE_DSFMT !'
      endif
   endif
endif
;
if KEYWORD_SET(verbose) then print, GDL_IDL_FL(), ', flag DSFMT = ', flag
if KEYWORD_SET(test) then STOP
;
return, flag
;
end
;
; ----------------------------------------------
;
function STATUS_VERSION_OF_RANDOM, verbose=verbose, test=test
;
status=1
;
DEFSYSV, '!gdl', exists=isGDL
;
; Mersenne Twister in GDL since March 20, 2017 ... 
; rev. 1.143 in "gsl_fin.cpp", GDL 0.9.7 CVS, Epoch ~1490047893
;
mess1_GDL_obsolete='Obsolete GDL version, Mersenne Twister Random not in use'
mess2a_GDL_maybe='MAY BE Obsolete GDL version'
mess2b_GDL_maybe='MAY BE Mersenne Twister Random not in use'
mess3_IDL_obsolete='Obsolete IDL version, Mersenne Twister Random not in use'
;
if isGDL then begin
   ;; testing the GDL side/version
   ;; 
   if KEYWORD_SET(verbose) then begin
      MESSAGE, /continue, 'GDL detected'
      help, /struct, !gdl
      help, /struct, !version
   endif
   ;;
   gdl_version=GDL_VERSION()
   ;;
   ;; before 0.9.7, always not OK; since 0.9.8 always OK
   ;; always OK since 0.9.7 SVN, 
   ;;
   if (gdl_version LT 907) then begin
      MESSAGE, /Continue, mess1_GDL_obsolete
      status=0
   endif else begin
      if (gdl_version EQ 907) then begin
         if (!gdl.epoch LT 1490047893L) then begin            
            MESSAGE, /Continue, mess1_GDL_obsolete
            status=0
         endif else begin
            if (STRPOS(!GDL.release, 'SVN') LT 0) then begin
               ;; we don't put status wrong but result may be wrong !!
               MESSAGE, /Continue, mess2a_GDL_maybe
               MESSAGE, /Continue, mess2b_GDL_maybe
            endif
         endelse
      endif
   endelse
endif else begin
   if KEYWORD_SET(verbose) then begin
      MESSAGE, /continue, 'IDL detected'
      help, /struct, !version
   endif
   ;; testing IDL side
   if (!version.release LT '8.2.2') then begin
      MESSAGE, /Continue, mess3_IDL_obsolete
      MESSAGE, /Continue, 'Required IDL version > 8.2.2'
      MESSAGE, /Continue, 'Detected IDL version '+!version.release      
      status=0
   endif
endelse
;
if KEYWORD_SET(test) then STOP
;
return, status
;
end
;
; ----------------------------------------------
; Warning ! We have to carrefully manage SEED to
; be able to call multiple times the code ...
; OK in FL 41, IDL 84 and GDL 0.9.8 (0.9.7 CVS/SVN)
;
pro TEST_RANDOM_MERSENNE, cumul_errors, test=test, verbose=verbose 
;
nb_errors=0
;
; tolerance
eps = 1e-5
;
; seed value : not a parameter because fixed numerical outputs ...
seed=10
;
nbp=20
indices=4*INDGEN(5)
;;
; /RAN1 could be used to insure that the values returned are equal with the non-parallel old mersenne twister,
; as /RAN1 gives values identical to IDL. However it would be necessary to modify the logic below.
;
if (GDL_IDL_FL() EQ 'GDL') AND STATUS_OF_DSFMT() then begin
  exptd_u_f=[0.683328, 0.511748, 0.712392, 0.974657, 0.267097]
  exptd_u_d=[0.6833279104279921, 0.5117476599880262, 0.7123919069196021, 0.9746571081546436, 0.2670968079969038]
  exptd_n_f=[-1.0257840, -0.8902389, 0.2266469, 0.2755476, 0.9339375]
  exptd_n_d=[-1.0257840075947602, -0.8902389633612189, 0.2266468876086417, 0.2755475765848067, 0.9339375254286939]
endif else begin
  exptd_u_f=[0.771321, 0.633648, 0.498507, 0.198063, 0.169111]
  exptd_u_d=[0.77132064, 0.49850701, 0.16911084, 0.0039482663, 0.72175532]
  exptd_n_f=[-0.746100, -0.872054, 2.67669, -0.797426, 1.13531]
  exptd_n_d=[1.3315865, 0.62133597, 0.0042914309, -0.96506567, -1.1366022]
endelse
;
fseed=seed
res=RANDOMU(fseed, nbp) & res=res[indices]
if (MAX(ABS(exptd_u_f-res)) GT eps) then ERRORS_ADD, nb_errors, 'Rand U & Float'
;
fseed=seed
res=RANDOMU(fseed, nbp, /double) & res=res[indices]
if (MAX(ABS(exptd_u_d-res)) GT eps) then ERRORS_ADD, nb_errors, 'Rand U & Double'
;
fseed=seed
res=RANDOMN(fseed, nbp) & res=res[indices]
if (MAX(ABS(exptd_n_f-res)) GT eps) then ERRORS_ADD, nb_errors, 'Rand N & Float'
;
fseed=seed
res=RANDOMN(fseed, nbp, /double) & res=res[indices]
if (MAX(ABS(exptd_n_d-res)) GT eps) then ERRORS_ADD, nb_errors, 'Rand N & Double'
;
; ----- final ----
;
BANNER_FOR_TESTSUITE, 'TEST_RANDOM_MERSENNE', nb_errors, /status, verb=verbose
ERRORS_CUMUL, cumul_errors, nb_errors
;
if KEYWORD_SET(test) then STOP
;
end
;
; ---------------------------------------
; ULONG keyword appeared in IDL 8.2.2
;
pro TEST_RANDOM_ULONG, cumul_errors, test=test, verbose=verbose
;
nb_errors=0
seed=10
nbp=5
;
; these values are the same for all 4 cases ...
if (GDL_IDL_FL() EQ 'GDL') AND STATUS_OF_DSFMT() then begin
   exp_ul10=[ 1060878149, 1956351291, 1923111058, 1181360106, 1349992422]
endif else begin
   exp_ul10=[ 3312796937, 1283169405, 89128932, 2124247567, 2721498432]
endelse
;
txt='case ULong '
;
; we need to reset "seed" to avoid it to be changed
;
seed=10 & res_ul10uf=RANDOMU(seed, nbp, /ULong)
seed=10 & res_ul10ud=RANDOMU(seed, nbp, /double, /ULong)
seed=10 & res_ul10nf=RANDOMN(seed, nbp, /ULong)
seed=10 & res_ul10nd=RANDOMN(seed, nbp, /double, /ULong)
;
if ~ARRAY_EQUAL(res_ul10uf, exp_ul10) then ERRORS_ADD, nb_errors, txt+'U Float'
if ~ARRAY_EQUAL(res_ul10ud, exp_ul10) then ERRORS_ADD, nb_errors, txt+'U Double'
if ~ARRAY_EQUAL(res_ul10nf, exp_ul10) then ERRORS_ADD, nb_errors, txt+'N Float'
if ~ARRAY_EQUAL(res_ul10nd, exp_ul10) then ERRORS_ADD, nb_errors, txt+'n Double'
;
; ----- final ----
;
BANNER_FOR_TESTSUITE, 'TEST_RANDOM_ULONG', nb_errors, /status, verb=verbose
ERRORS_CUMUL, cumul_errors, nb_errors
;
if KEYWORD_SET(test) then STOP
;
end
;
; ---------------------------------------
; because regression was introduced between July 17 and October 2
pro TEST_RANDOM_BASICS
;
a=RANDOMU(seed)
a=RANDOMU(1)
;
a=RANDOMU(seed, 12)
a=RANDOMU(1,12)
;
a=RANDOMU(seed, [12,3])
a=RANDOMU(1, [12,3])
;
end
;
; ---------------------------------------
;
pro PLOT_BATONS, values, offset=offset, color=color, psym=psym, $
                 linestyle=linestyle, _extra=_extra
;
if ~KEYWORD_SET(offset) then off=0 else off=offset
;
if ~KEYWORD_SET(psym) then mypsym=5 else mypsym=psym
;
for ii=0, N_ELEMENTS(values)-1 do begin
   PLOTS, [ii,ii]+off, [0, values[ii]], color=color, linestyle=linestyle
   PLOTS, ii+off, values[ii], color=color, psym=mypsym, _extra=_extra
endfor
;
end
;
; ---------------------------------------
; see figures in https://fr.wikipedia.org/wiki/Loi_de_Poisson
;
pro TEST_RANDOM_POISSON, errors, nb_points=nb_points, $
                         verbose=verbose, test=test
;
nb_pbs=0
;
if KEYWORD_SET(nb_points) then nbps=nb_points else nbps=100000
nbps_f=FLOAT(nbps)
;
if KEYWORD_SET(verbose) then print, 'We use : ', nbps, ' points'
;
; statistical test, will be OK whether dSFMT is used or not.
;
res_l1=HISTOGRAM(RANDOMN(seed, nbps, poisson=1))/nbps_f
res_l4=HISTOGRAM(RANDOMN(seed, nbps, poisson=4))/nbps_f
res_l10=HISTOGRAM(RANDOMN(seed, nbps, poisson=10))/nbps_f
;
;indices=INDGEN(N_ELEMENTS(res_l10))
indices=20
xranges=[-0.5, MAX(indices)+0.5]
;
if ((!d.name EQ 'X') or (!d.name EQ 'WIN') or (!d.name EQ 'MAC')) then begin 
   WINDOW, 0
   ;;
   DEVICE, get_decomposed=old_decomposed
   if NOT(old_decomposed) then DEVICE, decomposed=1
   ;;
   PLOT, INDGEN(N_ELEMENTS(res_l1)), res_l1, xrange=xranges, /xstyle, $
         xtitle='k', ytitle='P(X=k)', title='Poisson law', /nodata
   ;;
   PLOT_BATONS, res_l1, col='ff'x, psym=psym, line=2
   PLOT_BATONS, res_l4, off=0.05, col='ffff'x, psym=psym, line=2
   PLOT_BATONS, res_l10, off=0.1, col='ffffff'x, psym=psym, line=2
endif
;
; Is the sum of all the values equal to One ?!
;
eps=(MACHAR()).eps
txt='Case Poisson Sum '
if (ABS(TOTAL(res_l1)-1.0) GT 5.*eps) then ERRORS_ADD, nb_pbs, txt+'1'
if (ABS(TOTAL(res_l4)-1.0) GT 5.*eps) then ERRORS_ADD, nb_pbs, txt+'1' 
if (ABS(TOTAL(res_l10)-1.0) GT 5.*eps) then ERRORS_ADD, nb_pbs, txt+'1' 
;
; Are the Max in the expected range ?
; if nbps == 10000, you have 1 over 10 calls to fail
;
vals=[0.369090,0.196335,0.125015]
tol=0.01
txt='Case Poisson Max '
if (ABS(MAX(res_l1-vals[0])) GT tol) then ERRORS_ADD, nb_pbs, txt+'1'
if (ABS(MAX(res_l4)-vals[1]) GT tol) then ERRORS_ADD, nb_pbs, txt+'4'
if (ABS(MAX(res_l10)-vals[2]) GT tol) then ERRORS_ADD, nb_pbs, txt+'10'
;
; Is the result valid with /DOUBLE and POISSON > 4.2e9 ? 
;
nb_dev_err=0
for ii=40, 49 do begin
  if (ABS( ii*1e8-MEAN(RANDOMU(seed, 1000, /double, POISSON=ii*1e5)) ) GT 1) then nb_dev_err++
endfor
if nb_dev_err GT 0 then ERRORS_ADD, nb_pbs, 'Case Poisson Large Seed (out of UINT range)'
;
; ----- final ----
;
BANNER_FOR_TESTSUITE, "TEST_RANDOM_POISSON", nb_pbs, /status
ERRORS_CUMUL, errors, nb_pbs
;
if KEYWORD_SET(test) then STOP
;
if ((!d.name EQ 'X') or (!d.name EQ 'WIN') or (!d.name EQ '')) then begin
   DEVICE, decomposed=old_decomposed
endif
;
end
;
; ---------------------------------------
;
; note by AC 2017-12-13 : can be extend as "test_random_poison" above
; (but different numerical values !) no time to do it now :(
;
pro TEST_RANDOM_GAMMA, test=test
;
nbps=200000
nbps_f=FLOAT(nbps)
;
PLOT, HISTOGRAM(RANDOMN(seed, nbps, gamma=1), BINSIZE=0.1)/nbps_f
OPLOT, HISTOGRAM(RANDOMN(seed, nbps, gamma=2), BINSIZE=0.1)/nbps_f
OPLOT, HISTOGRAM(RANDOMN(seed, nbps, gamma=3), BINSIZE=0.1)/nbps_f
OPLOT, HISTOGRAM(RANDOMN(seed, nbps, gamma=4), BINSIZE=0.1)/nbps_f
;
if KEYWORD_SET(test) then STOP
;
end
;
; ---------------------------------------
; we try to have the output for all the mode
;
pro TEST_RANDOM_ALL_GAMMA, verbose=verbose
;
init_device_mode=!d.name
;
list_device_mode=['NULL', 'PS', 'X', 'SVG', 'Z', 'WIN', 'MAC']
;
for ii=0, N_ELEMENTS(list_device_mode)-1 do begin
   ;;
   command='SET_PLOT, "'+list_device_mode[ii]+'"'
   test_mode=EXECUTE(command)
   ;;
   if KEYWORD_SET(verbose) then begin
      print, 'Testing mode '+list_device_mode[ii]+', status : ', test_mode
   endif
   if (test_mode EQ 0) then begin
      print, 'Testing mode '+list_device_mode[ii]+' : SKIPPED !'
      CONTINUE
   endif
   ;;
   if ((!d.name EQ 'X') or (!d.name EQ 'WIN') or (!d.name EQ 'MAC')) then WINDOW, 1
   ;;
   if (!d.name EQ 'SVG') OR (!d.name EQ 'PS') then begin
      file='output_test_random_gamma.'+STRLOWCASE(!d.name)
      DEVICE, file=file
   endif
   ;;
   TEST_RANDOM_GAMMA
   ;;
   if (!d.name EQ 'SVG') OR (!d.name EQ 'PS') then begin
      DEVICE, /close
      if KEYWORD_SET(verbose) then print, 'file generated : <<'+file+'>>'
   endif
   print, 'Testing mode '+list_device_mode[ii]+', status : Processed'
endfor
;
; switching back to initial device mode (HELP, /device)
SET_PLOT, init_device_mode
;
end
;
; ------------------------------------------
;
; Idea: when the number is big enough, mean value
; of the realization should be close to the "value".
; If computation is wrong (e.g. calling bad noise, algo),
; we can expect not to have goor prediction ;-)
; (and this test fails "often" when NPB =< 100)
;
pro TEST_RANDOM_BINOMIAL, cumul_errors, nbp=nbp, amplitude=amplitude, $
                          help=help, verbose=verbose, test=test
;
if KEYWORD_SET(help) then begin
    print, 'pro TEST_RANDOM_BINOMIAL, cumul_errors, nbp=nbp, amplitude=amplitude, $'
    print, '                          help=help, verbose=verbose, test=test'
    return
endif
;
if ~KEYWORD_SET(nbp) then nbp=10000
if ~KEYWORD_SET(amplitude) then amplitude=10.
;
; Amplitude is a strictly posivite Integer
;
amplitude=FLOOR(amplitude)
if (amplitude EQ 1) then ratio=50. else ratio=100.
;
values=[0.10,0.25,0.50,0.75,0.90]
errors=0
;
if KEYWORD_SET(verbose) then begin
   print, 'Runing TEST_RANDOM_BINOMIAL for amplitude : ', amplitude
   print, format='(6A12)', ['Amplitude', 'values', 'expected', 'Mean', 'disp.', 'Error']
endif
for ii=0, N_ELEMENTS(values)-1 do begin
   resu=RANDOMU(seed, nbp, BINOMIAL=[amplitude,values[ii]])
   dispersion=ABS(MEAN(resu)-amplitude*values[ii])
   if (dispersion GT amplitude/ratio) then begin
      txt='bad result for (amplitude, value) : ('+string(amplitude)+','+string(values)+')'
      ERRORS_ADD, errors, txt
   endif
   if KEYWORD_SET(verbose) then begin
      print, format='(i12,4f12,6x,I1.1)', amplitude, values[ii], $
             amplitude*values[ii], MEAN(resu), dispersion,  (dispersion GT amplitude/100.)
   endif
   ;;
endfor
;
; ----- final ----
;
BANNER_FOR_TESTSUITE, "TEST_RANDOM_BINOMIAL", errors, /status, verb=verbose
ERRORS_CUMUL, cumul_errors, errors
;
if KEYWORD_SET(test) then STOP
;
end
;
; ------------------------------------------
; testable extensions welcome
;
pro TEST_RANDOM, no_exit=no_exit, help=help, verbose=verbose, test=test
;
if KEYWORD_SET(help) then begin
    print, 'pro TEST_RANDOM, no_exit=no_exit, help=help, verbose=verbose, test=test'
endif
;
cumul_errors=0
;
TEST_RANDOM_POISSON, cumul_errors, verbose=verbose
;
TEST_RANDOM_BASICS
;
; test the various DEVICE ...
TEST_RANDOM_ALL_GAMMA
;
TEST_RANDOM_BINOMIAL, cumul_errors, verbose=verbose, ampl=1.
TEST_RANDOM_BINOMIAL, cumul_errors, verbose=verbose, ampl=1.5
TEST_RANDOM_BINOMIAL, cumul_errors, verbose=verbose, ampl=10.
TEST_RANDOM_BINOMIAL, cumul_errors, verbose=verbose, ampl=100.
;
; testing the SEEDs ... (Mersenne) IDL 8.2.2+, GDL 0.9.7 SVN+
;
if STATUS_VERSION_OF_RANDOM() then begin
   TEST_RANDOM_ULONG, cumul_errors, test=test, verbose=verbose
   TEST_RANDOM_MERSENNE, cumul_errors, test=test, verbose=verbose
endif else begin
   BANNER_FOR_TESTSUITE, 'TEST_RANDOM_ULONG', 'Too old version detected'
   BANNER_FOR_TESTSUITE, 'TEST_RANDOM_SEED', 'Too old version detected'
endelse
;
; ----------------- final message ----------
;
BANNER_FOR_TESTSUITE, "TEST_RANDOM", cumul_errors
;
if (cumul_errors GT 0) AND ~KEYWORD_SET(no_exit) then EXIT, status=1
;
if KEYWORD_SET(test) then STOP
;
end
