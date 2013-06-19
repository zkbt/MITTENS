PRO mprint, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
;+
; NAME:
;	mprint
;
; PURPOSE:
;	exactly the same as "print", but will remain quiet if mearth_tools /verbose keyword is not set
;
; CALLING SEQUENCE:
;	mprint, 'knitting', 'is', 'fun'
;	mprint, 'yowzers!'
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
  
  case n_params() of
   1: print, a
   2: print, a, b
   3: print, a, b, c
   4: print, a, b, c, d
   5: print, a, b, c, d, e
   6: print, a, b, c, d, e, f
   7: print, a, b, c, d, e, f, g
   8: print, a, b, c, d, e, f, g, h
   9: print, a, b, c, d, e, f, g, h, i
   10: print, a, b, c, d, e, f, g, h, i, j
   11: print, a, b, c, d, e, f, g, h, i, j, k
   12: print, a, b, c, d, e, f, g, h, i, j, k, l
   13: print, a, b, c, d, e, f, g, h, i, j, k, l, m
   14: print, a, b, c, d, e, f, g, h, i, j, k, l, m, n
   15: print, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
  endcase 
  
END