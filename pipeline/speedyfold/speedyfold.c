#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <time.h>
using namespace std;

// the box folding engine, phase fold a series of boxes to a candidate period + HJD0
float boxFoldingRobot (	double candidatePeriod, double candidateHJD0, 
					double allowedOverlap, double timezone,
					double *HJD, double *Depth, double *DepthUncertainty, long *Nights, double *phasedTime,
					double foldedDepth, double foldedDepthUncertainty, int boxesInTransit,
<<<<<<< local
					long nBoxes, long pad
					);	
=======
					long nBoxes, long pad);	
>>>>>>> other

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
	long Nights[nBoxes];
	for (int i=0; i<nBoxes; i++) 
		Nights[i] = long(HJD[i] + 0.5 - timezone);

//	for(int i = 0; i < nBoxes; i++)
//		printf("%f %f %f\n", HJD[i], Depth[i], DepthUncertainty[i]);

	// define periods and phases
	srand(time(NULL));
//	double period = (double) rand() / 100000000.0;
	double HJD0;//= (double) rand() / 100000000.0 + 55000; 
	double baseHJD = HJD[0], maxHJD0;
	double allowedOverlap = 5.0/60.0/24.0, foldedDepth, foldedDepthUncertainty;
	int boxesInTransit;
	double timeElapsed;

	// set up period grid
	double p_min = 0.5, p_max = 10.0, max_misalign = 5.0/60.0/24.0, offsetBetweenEpochs=5.0/60.0/24.0;
	double data_span = (HJD[nBoxes-1] - HJD[0]);
	long n_periods = 1000;//(long)(data_span/max_misalign*log(p_max/p_min)),  nOffsets;
	double period, SN, tempSN;
	char outFile[500];
	strcpy(outFile, argv[1]);
	strcat(outFile, ".bls");
<<<<<<< local
=======
//	FILE *outputFile;
>>>>>>> other
	ofstream outputFile (outFile);
<<<<<<< local
	int nOffsets = 0;
	long startTime, endTime;
	startTime = clock();
=======
	time_t startTime, endTime;
	startTime = time(NULL);
>>>>>>> other
	long totalCount = 0;
	double phasedTime[nBoxes];
	long pad = (long) (50000.0/p_min);

<<<<<<< local
=======
//	outputFile = fopen(outFile, "w");
>>>>>>> other
	if (outputFile.is_open())
	{
		for (int i=0; i<n_periods; i++)
		{
			period =  p_min*exp(max_misalign/data_span*(double)i);
			SN = 0.0;
			//nOffsets = (long) ceil(period/offsetBetweenEpochs);
			HJD0 = baseHJD;
			maxHJD0 = baseHJD + period;
			nOffsets = 0;
			while(HJD0 < maxHJD0)
			{
				HJD0  += offsetBetweenEpochs;
				tempSN = boxFoldingRobot(period, HJD0, allowedOverlap, timezone, HJD, Depth, DepthUncertainty, Nights, phasedTime, foldedDepth, foldedDepthUncertainty, boxesInTransit, nBoxes, pad);
				if (tempSN > SN)
					SN = tempSN;
				totalCount++;
				nOffsets++;
			}
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
<<<<<<< local
	endTime = clock();
	float timeElapsed = (float)(endTime - startTime)/CLOCKS_PER_SEC;
	printf("%d in %f seconds; %f seconds per 1000 folds!\n", totalCount, timeElapsed, 1000.0*timeElapsed/(float)totalCount);
	// fold boxes, and spit out result


=======
//	fclose(outputFile);
>>>>>>> other
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

float boxFoldingRobot (	double candidatePeriod, double candidateHJD0, 
					double allowedOverlap, double timezone,
					double *HJD, double *Depth, double *DepthUncertainty, long *Nights, double *phasedTime,
					double foldedDepth, double foldedDepthUncertainty, int boxesInTransit,
					long nBoxes, long pad
					)	{

//	printf("\nPeriod is %9.6f \n", candidatePeriod);
//	printf("HJD0 is %12.6f \n\n", candidateHJD0);


	// calculate a phased time, based on the candidate period and HJD0
	double pseudoPhase, chiSquared = 0.0, rescaling = 1.0;
	double depthNumerator = 0.0, depthDenomenator = 0.0, initialFoldedDepthUncertainty = 100.0;
	boxesInTransit = 0;
	int maxBoxesInTransit = 365;
	int inTransitIndices[maxBoxesInTransit];
 
	for(int i = 0; i < nBoxes; i++) 
	{
		pseudoPhase = (HJD[i] - candidateHJD0)/candidatePeriod + pad + 0.5;
		phasedTime[i] = (pseudoPhase - floor(pseudoPhase) - 0.5)*candidatePeriod;
//		if (abs(phasedTime[i]) < allowedOverlap)
<<<<<<< local
/*		if (phasedTime[i] > -allowedOverlap && phasedTime[i] < allowedOverlap)
=======
		if (phasedTime[i] > -allowedOverlap && phasedTime[i] < allowedOverlap)
>>>>>>> other
		{
//			printf("%12.6f %12.d %12.6f\n", HJD[i], Nights[i], phasedTime[i]);
	//		printf("%f %f %f\n", HJD[i], Depth[i], DepthUncertainty[i]);
			depthNumerator += Depth[i]/DepthUncertainty[i]/DepthUncertainty[i];
			depthDenomenator += 1.0/DepthUncertainty[i]/DepthUncertainty[i];
			inTransitIndices[boxesInTransit] = i;
			boxesInTransit++;
		}*/
	}
	foldedDepth = depthNumerator/depthDenomenator;
	initialFoldedDepthUncertainty = 1.0/sqrt(depthDenomenator);

//	printf("depth = %f, uncertainty = %f, rescaling = %f\n", foldedDepth, initialFoldedDepthUncertainty, rescaling);
//	printf("\n");
	// rescale by chi^2 factor, if necessary
	if (boxesInTransit > 1) 
	{
		for(int i = 0; i < min(boxesInTransit, maxBoxesInTransit); i++) 
		{
//			if (abs(phasedTime[inTransitIndices[i]]) < allowedOverlap)
			if (phasedTime[inTransitIndices[i]] > -allowedOverlap && phasedTime[inTransitIndices[i]] < allowedOverlap)
			{
				chiSquared += pow((Depth[inTransitIndices[i]] - foldedDepth)/DepthUncertainty[inTransitIndices[i]],2);
//				printf("%f %f %f\n", HJD[inTransitIndices[i]] , Depth[inTransitIndices[i]] , DepthUncertainty[inTransitIndices[i]] );
			}
		}
		rescaling = sqrt(max(chiSquared/(boxesInTransit-1), (double) 1));
	}
	foldedDepthUncertainty = initialFoldedDepthUncertainty*rescaling;
	//printf("depth = %f, uncertainty = %f, boxes = %f\n", foldedDepth, foldedDepthUncertainty,  boxesInTransit);

//	printf("depth = %f, uncertainty = %f, rescaling = %f\n", foldedDepth, foldedDepthUncertainty, rescaling);
	// there are no protections against multiple boxes in the same night smashing together yet!

	return foldedDepth/foldedDepthUncertainty;
}
