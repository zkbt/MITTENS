FUNCTION load_good_binned
	
	big = create_struct('ye08', load_ensemble(ye=8), 'ye09', load_ensemble(ye=9), 'ye10', load_ensemble(ye=10), 'ye11', load_ensemble(ye=11))

	return,big
END