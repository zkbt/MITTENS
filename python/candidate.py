
class Candidate(Talker):

    def __init__(self):

        # period in days
        self.period = 4.2

        # duration in hours
        self.duration = 3.2
        
        # transit depth
        self.depth = 0.01
    
        # transit depth uncertainty
        self.depth_unc = 0.001


    def plot(self, marples):

        # create color shades based on number of marple points

        # get the uncertainties that are NOT 'inf'
        finite_uncs = np.where(np.isfinite(marples.uncertainties[0]))

        # figure out the color "steps" - some kind of log would be good - every x power, the color gets fainter
        color_spread = (math.log10(finite_unct.max()))

        
        #np.linspace(finite
        

        #marples.uncertainties[0] = 
