#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <time.h>
#define NDURATIONS 9
using namespace std;

// the box folding engine, phase fold a series of boxes to a candidate period + HJD0
void boxFoldingRobot (	double candidatePeriod,	double allowedOverlap, 
					double *HJD, double (*Depth)[9], double (*DepthUncertainty)[9], 
					double *foldedDepth, double *foldedDepthUncertainty, 
					long nBoxes, int *nOffsets, long *totalCount, float *maxSN, float *maxSNanti)
	{

	// calculate a phased time, based on the candidate period and HJD0
	double pseudoPhase[nBoxes], phaseOffset[nBoxes];
	double depthNumerator[NDURATIONS], depthDenominator[NDURATIONS], initialFoldedDepthUncertainty[NDURATIONS], chiSquared[NDURATIONS], rescaling[NDURATIONS];
	float SN[NDURATIONS];
	int maxBoxesInTransit = 365;
	int inTransitIndices[maxBoxesInTransit][NDURATIONS];
 	float allowedOverlapInPhase = allowedOverlap/candidatePeriod;
	double offsetBetweenPhases=2.5/60.0/24.0/candidatePeriod;
	double candidatePhase = 0.0;
	int boxesInTransit[NDURATIONS];
	for(int j = 0; j<NDURATIONS; j++)
	{
		maxSN[j] = 0.0;
		maxSNanti[j] = 0.0;
	}

	for(int i = 0; i < nBoxes; i++) 
	{
		pseudoPhase[i] = HJD[i]/candidatePeriod;
		pseudoPhase[i] -= floor(pseudoPhase[i]);
	}
	*nOffsets = 0;
	while (candidatePhase < 1)
	{
		//reset all candidate properties
		for(int j = 0; j<NDURATIONS; j++)
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
		for(int i=0; i<nBoxes; i++)
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
				for(int j = 0; j<NDURATIONS; j++)
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
		for(int j = 0; j<NDURATIONS; j++)
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
		for(int j = 0; j<NDURATIONS; j++)
		{
			if (boxesInTransit[j] > 1) 
			{
				for(int i = 0; i < min(boxesInTransit[j], maxBoxesInTransit); i++) 
				{
					if (phaseOffset[inTransitIndices[i][j]] > -allowedOverlapInPhase && phaseOffset[inTransitIndices[i][j]] < allowedOverlapInPhase)
					{
						chiSquared[j] += pow((Depth[inTransitIndices[i][j]][j] - foldedDepth[j])/DepthUncertainty[inTransitIndices[i][j]][j],2);
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
	//cout << *nOffsets << "   " << *totalCount << endl;
//	return maxSN;
}


// count the lines in a file (c'mon!)
long nLines(char* filename);

// accept a filename, [timezone] as command line arguments
int main(int argc, char* argv[]) {

	// get filename from command line
	cout << "The filename = " << argv[1] << endl;

	// get number of lines in file
	long nBoxes = nLines(argv[1]);
	cout << "  It has " << nBoxes << " lines in it." << endl;

	int nColumns = 1+ 2*NDURATIONS;
	string tempString;
	
	// read in a file of boxes. must be formatted as follows:
		// with 1-space between columns + 1 at the end of each row
		// HJD, Depth1, DepthUncertainty1, Depth2, DepthUncertainty2, ...
	double HJD[nBoxes], Depth[nBoxes][NDURATIONS], DepthUncertainty[nBoxes][NDURATIONS];
	long i = 0, col=0, row=0;
	ifstream boxesFile(argv[1]);
	if(!boxesFile)
	{
		cout<<"Error opening file!"<<endl;
		return -1;
	}
	while(!boxesFile.eof())
	{
		getline(boxesFile, tempString, ' ');
		if(col==0)
		{
			HJD[row] = atof(tempString.c_str());
		}
		else
		{
			if(col%2==1)
			{
				Depth[row][(col-1)/2] =atof(tempString.c_str());
			}
			else 
			{
				DepthUncertainty[row][(col-2)/2] = atof(tempString.c_str());
			}
		}
	//	printf("%f %i %i %i %i\n",atof(tempString.c_str()), row, col, (col-1)/2, (col-2)/2);
		col++;
		if(col==nColumns)
		{
//			printf("\n%f ", HJD[row]);
//			for(int q=0; q<NDURATIONS; q++)
//				printf("%f %f ", Depth[row][q], DepthUncertainty[row][q]);
			col=0;
			row++;
		}
	}
	printf("\n");


	// define variables for the phase-folding
	double HJD0;//= (double) rand() / 100000000.0 + 55000; 
	double baseHJD = HJD[0], maxHJD0;
	double allowedOverlap = 5.0/60.0/24.0, foldedDepth[NDURATIONS], foldedDepthUncertainty[NDURATIONS];
	int boxesInTransit;
	double timeElapsed;

	double minGap = 1000.0;
	double oneMinute = 1.0/60.0/24.0;

	for (int i=0; i+1<nBoxes; i++)
		if (HJD[i+1] - HJD[i] < minGap && HJD[i+1] - HJD[i] > oneMinute)
			minGap = HJD[i+1] - HJD[i];
	printf("     the smallest gap between boxes is %f days, or %f minutes\n", minGap, minGap*24*60);
	allowedOverlap = minGap/2.0;

	// set up period grid
	double p_min = 0.25, p_max = 10.0, max_misalign = 5.0/60.0/24.0;
	double data_span = (HJD[nBoxes-1] - HJD[0]);
	long n_periods = (long)(data_span/max_misalign*log(p_max/p_min)),  nOffsets;
	double period, SN, tempSN;
	float maxSN[NDURATIONS], maxSNanti[NDURATIONS];
	// define an output file
	char outFile[500];
	char outputString[500];
	strcpy(outFile, argv[1]);
	strcat(outFile, ".bls");

	ofstream outputFile (outFile);
	time_t startTime, endTime;
	startTime = time(NULL);
	long totalCount = 0;
	double phasedTime[nBoxes];
	long pad = (long) (50000.0/p_min);
	int nothing;
	int worthPrinting = 0, somethingHasBeenPrinted = 0;
	if (outputFile.is_open())
	{
		for (int i=0; i<n_periods; i++)
		{
			period =  p_min*exp(max_misalign/data_span*(double)i);
			SN = 0.0;
			HJD0 = baseHJD;
			maxHJD0 = baseHJD + period;
			int nOffsets = 0;
			boxFoldingRobot(period,  allowedOverlap,  HJD, Depth, DepthUncertainty, foldedDepth, foldedDepthUncertainty, nBoxes, &nOffsets, &totalCount, maxSN,maxSNanti);
			if (i % 1000 == 0) 
			{
				printf("completed %d / %d periods, with %d phase offsets; ", i, n_periods, nOffsets);
				endTime = time(NULL);
				timeElapsed = difftime(endTime, startTime);
			//	/(double) CLOCKS_PER_SEC;
			//	cout << startTime << "    "<< endTime <<endl;
				printf("%d folds in %f seconds; %f folds (of %i durations each) per second!\r", totalCount, timeElapsed, (float)totalCount/timeElapsed, NDURATIONS);

			}
			nothing = sprintf(outputString, "%10.7f", period);
			worthPrinting = 0;
			for(int j=0; j<NDURATIONS;j++)
			//	cout << startTime << "    "<< endTime <<endl;j<NDURATIONS;j++)
			{
				nothing = sprintf(outputString, "%s %f %f ", outputString, maxSN[j], maxSNanti[j]);
				if (maxSN[j] > 4 || maxSNanti[j] < -4)
				{
					worthPrinting = 1;
				}
			}
			if (worthPrinting == 1)
			{
				outputFile << outputString << endl;
				somethingHasBeenPrinted = 1;
			}

		}
		if (somethingHasBeenPrinted == 0)
		{
			outputFile << "no phased candidates had |significances| > 4 sigma in either direction" << endl;
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

