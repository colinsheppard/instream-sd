//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 

#import <stdio.h>
#import <stdlib.h>
#import "UTMInputData.h"

@implementation UTMInputData

+ create: aZone 
{
  UTMInputData* utmInputData = [super create: aZone];
 
  utmInputData->inputDataZone = [Zone create: aZone];

  return utmInputData;
}


- setUTMFlow: (double) aFlow
{
     utmFlow = aFlow;
     return self;
}


- setUTMVelocityDataFile: (char *) aVelocityDataFile
{
     strncpy(utmVelocityDataFile, aVelocityDataFile, 50);
     return self;
}

- setUTMDepthDataFile: (char *) aDepthDataFile
{
     strncpy(utmDepthDataFile, aDepthDataFile, 50);
     return self;
}



////////////////////////////////
//
// createVelocityArray
//
////////////////////////////////
- createVelocityArray
{
    FILE* fptr;
    const char* dataFile = utmVelocityDataFile;
    char inputString[100];
    int fcounter = 0;

    int numberOfNodes = 0;
    int numberOfElements = 0;

    double nodeVelocity;
    int i = 0;

    fprintf(stdout, "UTMInputData >>>> createVelocityArray >>>> BEGIN\n");
    fflush(0);

    if((fptr = fopen(dataFile, "r")) == NULL)
    {
         fprintf(stdout, "ERROR: UTMInputData >>>> createVelocityArray >>>> Unable to open %s for reading\n", dataFile);
         fflush(0);
         exit(1);
    }

    while(fgets(inputString, 100, fptr) != NULL)
    {
        if(strstr(inputString, "ENDDS") != NULL)
        {  
            break;
        }

        if(strstr(inputString, "DATASET") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "OBJTYPE") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "BEGSCL") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "ND") != NULL)
        {  
            char nd[2];

            sscanf(inputString, "%s %d", nd, &numberOfNodes);
            numberOfVelNodes = numberOfNodes;

            //
            // Changed numberOfNodes --> numberOfNodes + 1  6Jun08 skj
            //
            //velocityArray = (double **) [inputDataZone alloc: (numberOfNodes + 1) * sizeof(double *)];
            velocityArray = (double **) calloc((numberOfNodes + 1), sizeof(double *));
            
            //
            // Because the node count begins at 1, set *velocityArray[0] to -1
            //
            if(i == 0)
            {
                //velocityArray[i] = (double *) [inputDataZone allocBlock: sizeof(double)];
                velocityArray[i] = (double *) calloc(1, sizeof(double));
                *velocityArray[i] = -1;
                i++;
            }
 
            fprintf(stdout, "UTMInputData >>>> createVelocityArray >>>> numberOfNodes = %d\n", numberOfNodes);
            fflush(0);

            continue;
        }
        if(strstr(inputString, "NC") != NULL)
        {  
            char nc[2];
            sscanf(inputString, "%s %d", nc, &numberOfElements);
 
            fprintf(stdout, "UTMInputData >>>> createVelocityArray >>>> numberOfElements = %d\n", numberOfElements);
            fflush(0);

            continue;
        }

        if(strstr(inputString, "NAME") != NULL)
        {  
            continue;
        }

        if(strstr(inputString, "TS") != NULL)
        {  
            continue;
        }


        if(fcounter == numberOfElements)
        {
            if(i > numberOfNodes)
            {
                fprintf(stderr, "ERROR: UTMInputData >>>> createVelocityArray >>>> numberOfNodes and node count mismatch\n");
                fflush(0);
                exit(1);
            }

            nodeVelocity = atof(inputString);
            //velocityArray[i] = (double *) [inputDataZone alloc: sizeof(double)];
            velocityArray[i] = (double *) calloc(1, sizeof(double));

            *velocityArray[i] = 100.0*nodeVelocity;

            i++;
        }
        else
        {
            fcounter++;
            continue;
        }
    }

    if(0)
    {
        for(i = 0; i < numberOfNodes; i++)
        {

                fprintf(stdout, "UTMInputData >>>> createVelocityArray >>>> nodeVelocity = %f\n", *velocityArray[i]);
                fflush(0);
        }
    }

    fprintf(stdout, "UTMInputData >>>> createVelocityArray >>>> END\n");
    fflush(0);

    return self;
}


//////////////////////////////////////////
//
// createDepthArray
//
/////////////////////////////////////////
- createDepthArray
{
    FILE* fptr;
    const char* dataFile = utmDepthDataFile;
    char inputString[100];
    int fcounter = 0;

    int numberOfNodes = 0;
    int numberOfElements = 0;

    double nodeDepth;
    int i = 0;

    //fprintf(stdout, "UTMInputData >>>> createDepthArray >>>> BEGIN\n");
    //fflush(0);

    if((fptr = fopen(dataFile, "r")) == NULL)
    {
         fprintf(stdout, "ERROR: UTMInputData >>>> createDepthArray >>>> Unable to open %s for reading\n", dataFile);
         fflush(0);
         exit(1);
    }

    while(fgets(inputString, 100, fptr) != NULL)
    {
        if(strstr(inputString, "ENDDS") != NULL)
        {  
            break;
        }

        if(strstr(inputString, "DATASET") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "OBJTYPE") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "BEGSCL") != NULL)
        {  
            continue;
        }
        if(strstr(inputString, "ND") != NULL)
        {  
            char nd[2];

            sscanf(inputString, "%s %d", nd, &numberOfNodes);
            numberOfDepthNodes = numberOfNodes;
   
            //
            // Changed numberOfNodes --> numberOfNodes + 1  6Jun08 SKJ
            //
            //depthArray = (double **) [inputDataZone allocBlock: (numberOfNodes + 1) * sizeof(double *)];
            depthArray = (double **) calloc((numberOfNodes + 1), sizeof(double *));
 
            //
            // Because the node count begins at 1, set *depthArray[0] to -1
            //
            if(i == 0)
            {
                //depthArray[i] = (double *) [inputDataZone alloc: sizeof(double)];
                depthArray[i] = (double *) calloc(1, sizeof(double));
                *depthArray[i] = -1;
                i++;
            }
            //fprintf(stdout, "UTMInputData >>>> createDepthArray >>>> numberOfNodes = %d\n", numberOfNodes);
            //fflush(0);

            continue;
        }
        if(strstr(inputString, "NC") != NULL)
        {  
            char nc[2];
            sscanf(inputString, "%s %d", nc, &numberOfElements);
 
            //fprintf(stdout, "UTMInputData >>>> createDepthArray >>>> numberOfElements = %d\n", numberOfElements);
            //fflush(0);

            continue;
        }

        if(strstr(inputString, "NAME") != NULL)
        {  
            continue;
        }

        if(strstr(inputString, "TS") != NULL)
        {  
            continue;
        }


        if(fcounter == numberOfElements)
        {

            if(i > numberOfNodes)
            {
                fprintf(stderr, "ERROR: UTMInputData >>>> createDepthArray >>>> numberOfNodes and node count mismatch\n");
                fflush(0);
                exit(1);
            }

            nodeDepth = atof(inputString);
            //depthArray[i] = (double *) [inputDataZone alloc: sizeof(double)];
            depthArray[i] = (double *) calloc(1, sizeof(double));

            *depthArray[i] = 100.0 * nodeDepth;

            i++;
        }
        else
        {
            fcounter++;
            continue;
        }

    }

    if(0)
    {
        for(i = 0; i < numberOfNodes; i++)
        {

                fprintf(stdout, "UTMInputData >>>> createDepthArray >>>> nodeDepth = %f\n", *depthArray[i]);
                fflush(0);
        }
    }

    //fprintf(stdout, "UTMInputData >>>> createDepthArray >>>> END\n");
    //fflush(0);

    return self;
}


- (double) getUTMFlow
{
    return utmFlow;
}


- (char *) getUTMVelocityDataFile
{
    return utmVelocityDataFile;
}

- (char *) getUTMDepthDataFile
{
    return utmDepthDataFile;
}


- (double **) getVelocityArray
{
    return velocityArray;
}

- (double **) getDepthArray
{
    return depthArray;
}


////////////////////////////////////////////
//
// compareFlows
//
////////////////////////////////////////////
- (int) compareFlows: otherInputData
{
   int retVal;

   if(utmFlow < [otherInputData getUTMFlow])
   {
      retVal = -1;
   }
   else if(utmFlow == [otherInputData getUTMFlow])
   {
      retVal = 0;
   }
   else 
   {
      retVal = 1;
   }
      
   return retVal;
}


- (void) drop
{
    int i;

    fprintf(stdout, "UTMInputData >>>> drop >>>> BEGIN\n");
    fflush(0);

    for(i = 1; i < numberOfVelNodes; i++)
    {
        //fprintf(stdout, "UTMInputData >>>> velocityArray[%d] = %f\n", i, *velocityArray[i]);
        //fflush(0);
        free(velocityArray[i]);
    }
  
    //[inputDataZone freeBlock: velocityArray blockSize: numberOfVelNodes * sizeof(double *)];
    free(velocityArray);

    for(i = 1; i < numberOfDepthNodes; i++)
    {
        //fprintf(stdout, "UTMInputData >>>> depthArray[%d] = %f\n", i, *depthArray[i]);
        //fflush(0);
        free(depthArray[i]);
    }
  
    //[inputDataZone freeBlock: depthArray blockSize: numberOfVelNodes * sizeof(double *)];
    free(depthArray);

    [super drop];

    fprintf(stdout, "UTMInputData >>>> drop >>>> END\n");
    fflush(0);
}

@end
