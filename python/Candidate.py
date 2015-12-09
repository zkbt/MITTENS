class Candidate(Talker):
    def __init__(self):
        self.period = 1.2
        self.epoch = 54000.0
        self.duration = 0.03
        self.depth = 0.01
        self.uncertainty = 0.001

    def plot(self, marples):
        """Plots the phase-folder Marples timeseries, and highlights in-transit points.
        Transparency of data lines to represent size of uncertainties on each marple."""
        
