PRO mprint, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, line=line
;+
; NAME:
;	mprint
;
; PURPOSE:
;	exactly the same as "print", but will remain quiet if mearth_tools /verbose keyword is not set
;
; CALLING SEQUENCE:
;	mprint, procedure_prefix, 'knitting', 'is', 'fun'
;	mprint, procedure_prefix, 'yowzers!'
;
; INPUTS:
;	up to 15 seperate strings
;
; OUTPUTS:
;	prints to screen, but only if keyword_set(verbose)
;
; MODIFICATION HISTORY:
;	Written by Zachory K. Berta-Thompson, sometime while he was in grad school (2008-2013).
;
;-
  common mearth_tools
  if ~keyword_set(verbose) then return
  
	if keyword_set(line) then begin
		print, '================================================================'
		return
	endif
  case n_params() of
   0: print
   1: print, procedure_prefix, a
   2: print, procedure_prefix, a, b
   3: print, procedure_prefix, a, b, c
   4: print, procedure_prefix, a, b, c, d
   5: print, procedure_prefix, a, b, c, d, e
   6: print, procedure_prefix, a, b, c, d, e, f
   7: print, procedure_prefix, a, b, c, d, e, f, g
   8: print, procedure_prefix, a, b, c, d, e, f, g, h
   9: print, procedure_prefix, a, b, c, d, e, f, g, h, i
   10: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j
   11: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k
   12: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k, l
   13: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k, l, m
   14: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k, l, m, n
   15: print, procedure_prefix, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
  endcase 
  
END
