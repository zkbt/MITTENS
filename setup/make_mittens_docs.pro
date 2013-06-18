PRO make_mittens_docs
;+
; NAME:
;	make_mittens_docs
;
; PURPOSE:
;	recreate the HTML documentation page for MITTENS
;
; CALLING SEQUENCE:
;	make_mittens_docs
;
; INPUTS:
;	none
;
; OPTIONAL INPUT PARAMETERS:
;	none
;
; KEYWORD PARAMETERS:
;	none
;
; OUTPUTS:
;	fills $MITTENS_PATH/docs with HTML code documentation, generating from the code comments
;
; OPTIONAL OUTPUT PARAMETERS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; MODIFICATION HISTORY:
;	Written by Zachory K. Berta-Thompson, sometime while he was in grad school (2008-2013).
;
;-

	code_docs_dir = 'routine_descriptions/'
	file_delete, getenv('MITTENS_PATH')+'/' + code_docs_dir, /recu, /allo
	idldoc, root=getenv('MITTENS_PATH'), output=getenv('MITTENS_PATH')+'/' + code_docs_dir, format_style='rst', $
		title='MITTENS!', subtitle='MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths'
	spawn, 'firefox ' + getenv('MITTENS_PATH')+'/' + code_docs_dir + 'index.html'
END