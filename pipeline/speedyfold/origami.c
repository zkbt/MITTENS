#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <time.h>
using namespace std;

// the box folding engine, phase fold a series of boxes to a candidate period + HJD0
float boxFoldingRobot (	double candidatePeriod,	double allowedOverlap, 
					double *HJD, double *Depth, double *DepthUncertainty,
					double foldedDepth, double foldedDepthUncertainty,
					long nBoxes, int *nOffsets, long *totalCount);	

// count the lines in a file (c'mon!)
long nLines(char* filename);


// accept a filename, [timezone] as command line arguments
int main(int argc, char* argv[]) {

	// get filename from command line
	cout << "The filename = " << argv[1] << endl;

	// get timezone from command line
	float timezone;
	if (argc >= 3) 
		timezone = atof(argv[2]);
	else
		timezone = 7.0/24.0;

	// get number of lines in file
	long nBoxes = nLines(argv[1]);
	cout << "  It has " << nBoxes << " lines in it." << endl;

	// read in a file of boxes
	double HJD[nBoxes], Depth[nBoxes], DepthUncertainty[nBoxes];
	long i = 0;
	ifstream boxesFile(argv[1]);
	if (boxesFile.is_open())
	{
		while (boxesFile.good() )
		{
			boxesFile >> HJD[i] >> Depth[i] >> DepthUncertainty[i];
			i++;
		}
	}
	
	// calculate which night each box falls on
//	long Nights[nBoxes];
//	for (int i=0; i<nBoxes; i++) 
//		Nights[i] = long(HJD[i] + 0.5 - timezone);

//	for(int i = 0; i < nBoxes; i++)
//		printf("%f %f %f\n", HJD[i], Depth[i], DepthUncertainty[i]);

	// define periods and phases
//	srand(time(NULL));
//	double period = (double) rand() / 100000000.0;
	double HJD0;//= (double) rand() / 100000000.0 + 55000; 
	double baseHJD = HJD[0], maxHJD0;
	double allowedOverlap = 5.0/60.0/24.0, foldedDepth, foldedDepthUncertainty;
	int boxesInTransit;
	double timeElapsed;

	double minGap = 1000.0;

	for (int i=0; i+1<nBoxes; i++)
		if (HJD[i+1] - HJD[i] < minGap)
			minGap = HJD[i+1] - HJD[i];
	printf("     the smallest gap between boxes is %f days, or %f minutes\n", minGap, minGap*24*60);
	allowedOverlap = minGap/2.0;

	// set up period grid
	double p_min = 0.5, p_max = 10.0, max_misalign = 5.0/60.0/24.0;
	double data_span = (HJD[nBoxes-1] - HJD[0]);
	long n_periods = (long)(data_span/max_misalign*log(p_max/p_min)),  nOffsets;
	double period, SN, tempSN;
	char outFile[500];
	strcpy(outFile, argv[1]);
	strcat(outFile, ".bls");
//	FILE *outputFile;
	ofstream outputFile (outFile);
	time_t startTime, endTime;
	startTime = time(NULL);
	long totalCount = 0;
	double phasedTime[nBoxes];
	long pad = (long) (50000.0/p_min);

//	outputFile = fopen(outFile, "w");
	if (outputFile.is_open())
	{
		for (int i=0; i<n_periods; i++)
		{
			period =  p_min*exp(max_misalign/data_span*(double)i);
			SN = 0.0;
			//nOffsets = (long) ceil(period/offsetBetweenEpochs);
			HJD0 = baseHJD;
			maxHJD0 = baseHJD + period;
			int nOffsets = 0;
			SN = boxFoldingRobot(period,  allowedOverlap,  HJD, Depth, DepthUncertainty, foldedDepth, foldedDepthUncertainty, nBoxes, &nOffsets, &totalCount);
			//	printf("period = %f, HJD0 = %f, SN = %f\n", periods[i], HJD0,  SN[i]);
			if (i % 1000 == 0) 
			{
				printf("completed %d / %d periods, with %d offsets\n", i, n_periods, nOffsets);
				endTime = time(NULL);
				timeElapsed = difftime(endTime, startTime);
			//	/(double) CLOCKS_PER_SEC;
			//	cout << startTime << "    "<< endTime <<endl;
				printf("%d folds in %f seconds; %f folds per second!\n", totalCount, timeElapsed, (float)totalCount/timeElapsed);

			}
	//		fprintf(outputFile, "%10.7f %10.5f\n", period ,SN);
			outputFile << period << "   " << SN  << endl;
		}	
	// fold boxes, and spit out result
	}
//	fclose(outputFile);
	return 0;
}

long nLines(char* filename) {
	string line;
	long count = 0;
	ifstream testingFile(filename);
	if (testingFile.is_open())
	{
		while (testingFile.good() )
		{
			getline(testingFile,line);
			count++;
		}
	}
	return count-1;
}

float boxFoldingRobot (	double candidatePeriod,	double allowedOverlap, 
					double *HJD, double *Depth, double *DepthUncertainty, 
					double foldedDepth, double foldedDepthUncertainty, 
					long nBoxes, int *nOffsets, long *totalCount) {

//	printf("\nPeriod is %9.6f \n", candidatePeriod);
//	printf("HJD0 is %12.6f \n\n", candidateHJD0);


	// calculate a phased time, based on the candidate period and HJD0
	double pseudoPhase[nBoxes], phaseOffset[nBoxes], chiSquared = 0.0, rescaling = 1.0;
	double depthNumerator = 0.0, depthDenomenator = 0.0, initialFoldedDepthUncertainty = 100.0;
	int maxBoxesInTransit = 365;
	int inTransitIndices[maxBoxesInTransit];
 	float allowedOverlapInPhase = allowedOverlap/candidatePeriod;
	float offsetBetweenPhases=5.0/60.0/24.0/candidatePeriod;
	float candidatePhase = allowedOverlapInPhase;
	float maxSN = 0.0, SN=0.0;
	int boxesInTransit;
	for(int i = 0; i < nBoxes; i++) 
	{
		pseudoPhase[i] = HJD[i]/candidatePeriod;
		pseudoPhase[i] -= floor(pseudoPhase[i]);
	}
	*nOffsets = 0;
	while (candidatePhase <= 1)
	{
		//reset the candidate properties
		boxesInTransit = 0;
		chiSquared = 0.0; 
		rescaling = 1.0;
		depthNumerator = 0.0; 
		depthDenomenator = 0.0; 
		initialFoldedDepthUncertainty = 100.0;

		for(int i=0; i<nBoxes; i++)
		{
			// compare the pseudo phase to the candidate phase
			phaseOffset[i] = pseudoPhase[i] - candidatePhase;

			// correct for things that slide to far negative
			if (phaseOffset[i] < -0.5)
				phaseOffset[i] += 1.0;

			if (phaseOffset[i] > -allowedOverlapInPhase && phaseOffset[i] < allowedOverlapInPhase)
			{
	//			printf("%12.6f %12.d %12.6f\n", HJD[i], Nights[i], phasedTime[i]);
		//		printf("%f %f %f\n", HJD[i], Depth[i], DepthUncertainty[i]);
				depthNumerator += Depth[i]/DepthUncertainty[i]/DepthUncertainty[i];
				depthDenomenator += 1.0/DepthUncertainty[i]/DepthUncertainty[i];
				inTransitIndices[boxesInTransit] = i;
				boxesInTransit++;
			}
		}
		foldedDepth = depthNumerator/depthDenomenator;
		initialFoldedDepthUncertainty = 1.0/sqrt(depthDenomenator);
		candidatePhase += offsetBetweenPhases;

		// rescale by chi^2 factor, if necessary
		if (boxesInTransit > 1) 
		{
			for(int i = 0; i < min(boxesInTransit, maxBoxesInTransit); i++) 
			{
				if (phaseOffset[inTransitIndices[i]] > -allowedOverlapInPhase && phaseOffset[inTransitIndices[i]] < allowedOverlapInPhase)
				{
					chiSquared += pow((Depth[inTransitIndices[i]] - foldedDepth)/DepthUncertainty[inTransitIndices[i]],2);
	//				printf("%f %f %f\n", HJD[inTransitIndices[i]] , Depth[inTransitIndices[i]] , DepthUncertainty[inTransitIndices[i]] );
				}
			}
			rescaling = sqrt(max(chiSquared/(boxesInTransit-1), (double) 1));
		}
		foldedDepthUncertainty = initialFoldedDepthUncertainty*rescaling;
		SN = foldedDepth/foldedDepthUncertainty;
		if (SN > maxSN && !isnan(SN))
			maxSN = SN;
		*nOffsets = *nOffsets + 1;
		*totalCount = *totalCount + 1;
	}
	//cout << *nOffsets << "   " << *totalCount << endl;
	return maxSN;
}
