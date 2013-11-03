#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#define NDURATIONS 9
#define OUTPUT_THRESHOLD 4
#define RESOLUTION 1e-5
#define VERBOSE 0


// the box folding engine, phase fold a series of boxes to a candidate period + HJD0
void boxFoldingRobot (	double candidatePeriod,	double allowedOverlap, 
					double *HJD, double (*Depth)[NDURATIONS], double (*DepthUncertainty)[NDURATIONS], 
					double *foldedDepth, double *foldedDepthUncertainty, 
					long nBoxes, int *nOffsets, long *totalCount, float *maxSN, float *maxSNanti)
	{

	// calculate a phased time, based on the candidate period and HJD0
	double pseudoPhase[nBoxes], phaseOffset[nBoxes];
	
	// define arrays to contain intermediate steps required for calculating signal-to-noise ratios
	double depthNumerator[NDURATIONS], depthDenominator[NDURATIONS], initialFoldedDepthUncertainty[NDURATIONS], chiSquared[NDURATIONS], rescaling[NDURATIONS], chiUnsquared;

	// an array to contain the temporary SN (this will slide through all phases at fixed period)
	float SN[NDURATIONS];

	// place limit on the number of in-transit boxes can be included in an event 
	long maxBoxesInTransit = 365, boxesInTransit[NDURATIONS],  actualNumberOfBoxesToInclude = 0;

	// an array to store the indices of in-transit boxes (will need to be reset!)
	long inTransitIndices[maxBoxesInTransit][NDURATIONS];
	
	
 	double allowedOverlapInPhase = allowedOverlap/candidatePeriod;
	double offsetBetweenPhases=2.5/60.0/24.0/candidatePeriod;
	double candidatePhase = 0.0;

	// initialize some indices
	long i = 0, j = 0;

	// set transit and antitransit SN arrays to 0, for this period
	for(j = 0; j < NDURATIONS; j++)
	{
		maxSN[j] = 0.0;
		maxSNanti[j] = 0.0;
	}
	
	// set all the pseudo phases 
	for(i = 0; i < nBoxes; i++) 
	{
		pseudoPhase[i] = HJD[i]/candidatePeriod;
		pseudoPhase[i] -= floor(pseudoPhase[i]);
	}
	
	// reset the number of offsets required at this period
	*nOffsets = 0;

	// loop over the pphases
	while (candidatePhase < 1)
	{
		//reset all candidate properties
		j=0;
		for(j = 0; j<NDURATIONS; j++)
		{
			boxesInTransit[j] = 0;
			chiSquared[j] = 0.0; 
			rescaling[j] = 1.0;
			depthNumerator[j] = 0.0;
			depthDenominator[j] = 0.0;
			foldedDepth[j] = 1000.0;
			foldedDepthUncertainty[j] = 1000.0;
			initialFoldedDepthUncertainty[j] = 1000.0;
			// is this necessary?
		//	for(int i = 0; i<maxBoxesInTransit; i++)
		//		inTransitIndices[i][j] = 0;
		}

		//offset the phase of the datapoints, so they're centered on zero
		for(i=0; i<nBoxes; i++)
		{
			// compare the pseudo phase to the candidate phase
			phaseOffset[i] = pseudoPhase[i] - candidatePhase;

			// correct for things that slide too far negative
			if (phaseOffset[i] < -0.5)
				phaseOffset[i] += 1.0;

			// correct for things that slide too far positive
			if (phaseOffset[i] > 0.5)
				phaseOffset[i] -= 1.0;


			if (phaseOffset[i] > -allowedOverlapInPhase && phaseOffset[i] < allowedOverlapInPhase)
			{
				for(j = 0; j<NDURATIONS; j++)
				{
					if (DepthUncertainty[i][j] > 0)
					{
						depthNumerator[j] += Depth[i][j]/DepthUncertainty[i][j]/DepthUncertainty[i][j];
						depthDenominator[j] += 1.0/DepthUncertainty[i][j]/DepthUncertainty[i][j];
						inTransitIndices[boxesInTransit[j]][j] = i;
						boxesInTransit[j]++;
					}
				}
			}
		}

		// define a folded depth for each duration, and its initial uncertainty
		for(j = 0; j<NDURATIONS; j++)
		{
			// make sure Depth Uncertainty doesn't go to infinity
			if(boxesInTransit[j] > 0) 
			{
				foldedDepth[j] = depthNumerator[j]/depthDenominator[j];
				initialFoldedDepthUncertainty[j] = 1.0/sqrt(depthDenominator[j]);
			}
			else
			{
				foldedDepth[j] = 0.0;
				initialFoldedDepthUncertainty[j] = 1000.0;		
			}
		}

		// rescale by chi^2 factor, if necessary
		for(j = 0; j<NDURATIONS; j++)
		{
			if (boxesInTransit[j] > 1) 
			{
				actualNumberOfBoxesToInclude = boxesInTransit[j];
				if (actualNumberOfBoxesToInclude > maxBoxesInTransit) 
				{
					actualNumberOfBoxesToInclude = maxBoxesInTransit;
				}
				for(i = 0; i < actualNumberOfBoxesToInclude; i++) 
				{
					if (phaseOffset[inTransitIndices[i][j]] > -allowedOverlapInPhase && phaseOffset[inTransitIndices[i][j]] < allowedOverlapInPhase)
					{
						chiUnsquared = (Depth[inTransitIndices[i][j]][j] - foldedDepth[j])/DepthUncertainty[inTransitIndices[i][j]][j];
						chiSquared[j] += chiUnsquared*chiUnsquared;
		//				printf("%f %f %f\n", HJD[inTransitIndices[i]] , Depth[inTransitIndices[i]] , DepthUncertainty[inTransitIndices[i]] );
					
					}
				}
				rescaling[j] = sqrt(chiSquared[j]/(float)(boxesInTransit[j]-1));
				if (rescaling[j] < 1)
					rescaling[j] = 1.0;
			}
			foldedDepthUncertainty[j] = initialFoldedDepthUncertainty[j]*rescaling[j];
			SN[j] = foldedDepth[j]/foldedDepthUncertainty[j];
			if (foldedDepthUncertainty[j]<=0 || foldedDepthUncertainty[j]>999.0 || isnan(SN[j]))
				SN[j] = 0.0;
			if (SN[j] > maxSN[j])// && !)
			{
				maxSN[j] = SN[j];
			}	
			if (SN[j] < maxSNanti[j])// && !)
			{
				maxSNanti[j] = SN[j];
			}	
		}
	
		// just accounting to keep track of how many phase folds have happened
		*nOffsets = *nOffsets + 1;
		*totalCount = *totalCount + 1;

		// shift to a new phase offset
		candidatePhase += offsetBetweenPhases;
	}
}


// count the lines in a file (c'mon!)
long nLines(char* filename);

// accept a filename, [timezone] as command line arguments
int main(int argc, char* argv[]) {

	// introduction
	printf("==================================================\n");
	printf("  octopusOrigami is folding many MarPLES at once  \n");
	printf("==================================================\n");
	// get filename from command line
	printf("     The input file %s ", argv[1]);

	// get number of lines in file
	long nBoxes = nLines(argv[1]);
	printf("has %ld lines in it.\n",  nBoxes);

	// define the number columns that will go into the output file	
	int nColumns = 1+ 2*NDURATIONS;
	
	// read in a file of boxes. must be formatted as follows:
		// with 1-space between columns + 1 at the end of each row
		// HJD, Depth1, DepthUncertainty1, Depth2, DepthUncertainty2, ...
	double tempHJD, tempDepth, tempDepthUncertainty, HJD[nBoxes], Depth[nBoxes][NDURATIONS], DepthUncertainty[nBoxes][NDURATIONS];
	long i = 0, j=0,  row=0;
	
	// define a pointer to the input file
	FILE *boxesFile;
	boxesFile = fopen(argv[1], "r");
	
	// freak out if the file couldn't be found or opened
	if(!boxesFile)
	{
		printf("     !@*($#@ Uh-oh! Error opening file!\n");
		return -1;
	}
	// loop over all the lines of the input file
	while(!feof(boxesFile))
	{
		// read the first column of a row as the HJD
		fscanf(boxesFile, "%lf", &tempHJD);
		HJD[row] = tempHJD;
		if (VERBOSE) printf("%lf\n", HJD[row]);
		
		// read subsequent pairs of columns as Depth and DepthUncertainty for different durations
		for(i=0; i<NDURATIONS; i++)
		{
			fscanf(boxesFile, "%lf %lf", &tempDepth, &tempDepthUncertainty);
			Depth[row][i] = tempDepth;
			DepthUncertainty[row][i] = tempDepthUncertainty;
			if (VERBOSE) printf("        %lf +/- %lf\n", Depth[row][i], DepthUncertainty[row][i]);
		}	
		row++;
	}
	fclose(boxesFile);
	printf("     oO successfully read in these %ld multi-duration boxes.\n", nBoxes);


	// define variables for the phase-folding
	double HJD0;//= (double) rand() / 100000000.0 + 55000; 
	double baseHJD = HJD[0], maxHJD0;
	double allowedOverlap = 5.0/60.0/24.0, foldedDepth[NDURATIONS], foldedDepthUncertainty[NDURATIONS];
	int boxesInTransit;
	double timeElapsed, timeSinceUpdate;

	double minGap = 1000.0;
	double oneMinute = 1.0/60.0/24.0;

	// figure out what the smallest gap between boxes is, to use for setting the search resolution + defining in-transit boxes
	for (i=0; i+1<nBoxes; i++)
		if (HJD[i+1] - HJD[i] < minGap && HJD[i+1] - HJD[i] > oneMinute)
			minGap = HJD[i+1] - HJD[i];
	allowedOverlap = minGap/2.0;

	printf("     The smallest gap between boxes is %f minutes;\n", minGap*24*60);
	printf("        any box within half this time of mid-transit will be consider a unique, in-transit event.\n");

	// set up period grid
	double p_min = 0.25, p_max = 10.0, max_misalign = 5.0/60.0/24.0;
	double data_span = (HJD[nBoxes-1] - HJD[0]);
	double dlnperiod = max_misalign/data_span;
	if (dlnperiod < RESOLUTION)
		dlnperiod = RESOLUTION;
	long nPeriods = (long)(log(p_max/p_min)/dlnperiod),  nOffsets;
	
	printf("     Now searching %ld periods, logarithmically space between %f and %f days.\n", nPeriods, p_min, p_max);
	double period, SN, tempSN;
	float maxSN[NDURATIONS], maxSNanti[NDURATIONS];
	
	// define an output file
	char outputFileString[500];
	char outputString[500];
	strcpy(outputFileString, argv[1]);
	strcat(outputFileString, ".bls");

	// define an output file pointer	
	FILE *outputFile;
	outputFile = fopen(outputFileString, "w");

	// define a time variable, to keep track of pace
	clock_t startTime, endTime, beforeBoxTime, endBoxTime, lastUpdateTime;
	startTime = clock();
	beforeBoxTime = clock();
	endBoxTime = clock();
	lastUpdateTime = clock();
	
	// define some phase folding variables
	long totalCount = 0;
	double phasedTime[nBoxes];
	long pad = (long) (50000.0/p_min);

	// define variables for keeping track of whether or not to output the result
	int nothing;
	int worthPrinting = 0, somethingHasBeenPrinted = 0;

	// status update
	printf("          (this may take a while)\n\n");
	
	// loop over all periods of interest
	for (i=0; i<nPeriods; i++)
	{
		// set the period for this phase folding
		period =  p_min*exp(dlnperiod*(double)i);

		// reset the instantaneous SN variable
		SN = 0.0;

		// set the starting epoch for the phase folding
		HJD0 = baseHJD;
		maxHJD0 = baseHJD + period;
		int nOffsets = 0;

	
		// run the box-folding robot, to figure out the maximum SN's over all durations, given the period
		if (VERBOSE) beforeBoxTime = clock();
		if (VERBOSE) printf("%lf not box-folding,", (double)(beforeBoxTime - endBoxTime)/CLOCKS_PER_SEC);
		boxFoldingRobot(period,  allowedOverlap,  HJD, Depth, DepthUncertainty, foldedDepth, foldedDepthUncertainty, nBoxes, &nOffsets, &totalCount, maxSN,maxSNanti);
		if (VERBOSE) endBoxTime = clock();
		if (VERBOSE) printf("%lf box-folding\n",  (double)(endBoxTime - beforeBoxTime)/CLOCKS_PER_SEC);

		// output a bit of a status update
		endTime = clock();
		timeSinceUpdate = (double)(endTime - lastUpdateTime)/CLOCKS_PER_SEC;
		if (timeSinceUpdate > 10.0) 
		{
			timeElapsed =  (double)(endTime - startTime)/CLOCKS_PER_SEC;
			lastUpdateTime = clock();
			printf("       period = %lf days (%ld/%ld, now with %i phase offsets; %lf folds/s) \n", period, i, nPeriods, nOffsets, (double)totalCount/timeElapsed);
		}
		nothing = sprintf(outputString, "%10.7f", period);
		worthPrinting = 0;
		for(j=0; j<NDURATIONS;j++)
		{
			nothing = sprintf(outputString, "%s %f %f ", outputString, maxSN[j], maxSNanti[j]);
			if (maxSN[j] > OUTPUT_THRESHOLD || maxSNanti[j] < -OUTPUT_THRESHOLD)
			{
				worthPrinting = 1;
			}
		}
		if (worthPrinting == 1)
		{
		//	printf(outputString);
			fprintf(outputFile, "%s\n", outputString);
			somethingHasBeenPrinted = 1;
		}

	}
	
	// put something the file, in case no interesting results are found
	if (somethingHasBeenPrinted == 0)
	{
		fprintf(outputFile, "no phased candidates had |significances| > 4 sigma in either direction");
	}	
	fclose(outputFile);

	return 0;
}

// a function to figure out how many lines are in a file
long nLines(char* filename) {

	FILE *boxesFile;
	boxesFile = fopen (filename, "r");
	if(!boxesFile)
	{
		printf("Error opening file!\n");
		return -1;
	}
	long count = 0;
	char tempString[1000];
	while(!feof(boxesFile))
	{
		fgets(tempString, 1000, boxesFile);
	//	printf("%ld %s\n", count, tempString);
		count++;
	}
	return count-1;
}

