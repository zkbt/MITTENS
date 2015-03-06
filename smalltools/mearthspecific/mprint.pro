PRO mprint, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, line=line
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
  
	if keyword_set(line) then begin
		print, '================================================================'
		return
	endif
  case n_params() of
   0: print
   1: print, '['+currentname() + ']' + ' ', a
   2: print, '['+currentname() + ']' + ' ', a, b
   3: print, '['+currentname() + ']' + ' ', a, b, c
   4: print, '['+currentname() + ']' + ' ', a, b, c, d
   5: print, '['+currentname() + ']' + ' ', a, b, c, d, e
   6: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f
   7: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g
   8: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h
   9: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i
   10: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j
   11: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j, k
   12: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j, k, l
   13: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j, k, l, m
   14: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j, k, l, m, n
   15: print, '['+currentname() + ']' + ' ', a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
  endcase 
  
END
