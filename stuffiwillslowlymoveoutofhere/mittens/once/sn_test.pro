FUNCTION sn_test, n_boxes
if n_elements(n_boxes) eq 0 then n_boxes = 1000
boxes = replicate({depth:0.0, depth_uncertainty:0.0, n:0}, n_boxes)
for i=0L, n_boxes-1 do begin
	n = fix(randomu(seed)*10)>1
	x = randomn(seed, n)
	boxes[i].depth = mean(x)
	boxes[i].depth_uncertainty = 1.0/sqrt(n)
	boxes[i].n = n
endfor
boxes[fix(randomu(seed, n/100))].depth += .5
return, boxes
END