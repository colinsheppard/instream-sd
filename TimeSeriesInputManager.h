//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



#import <objectbase/SwarmObject.h>
#import <collections.h>
#import <string.h>
#import "ZoneAllocMapper.h"
#import "TimeManagerProtocol.h"
#import <math.h>
#import <ctype.h>
#import <stdlib.h>


#define LARGEINT 2147483647

#define HCOMMENTLENGTH 200

#define TRUE 1
#define FALSE 0

enum inputDataType {DAILY = 0, HOURLY = 1, OTHER = 2};


@interface TimeSeriesInputManager : SwarmObject
{

  id <Zone> timeSeriesInputZone;

  enum inputDataType inputDataType;
   
  char* inputFileName;
  id <TimeManager> timeManager;
  time_t startTime;
  time_t endTime;
  
  double** inputRecord;
  unsigned numRecords;

  BOOL log10OfValuesOn;

  BOOL checkData;

}

//CREATING

+     createBegin: (id <Zone>) aZone
     withDataType: (char *) aTypeString
    withInputFile: (char *) aFileName
  withTimeManager: (id <TimeManager>) aTimeManager
    withStartTime: (time_t) aStartTime
      withEndTime: (time_t) anEndTime
    withCheckData: (BOOL) aFlag;

- createEnd;

- checkData;



//SETTING

- setLog10OfValues;



//USING

- (double) getValueForTime: (time_t) aTime;

- (double) getMeanValueWithStartTime: (time_t) aStartTime
                         withEndTime: (time_t) aEndTime;

- (double) getMaxValueWithStartTime: (time_t) aStartTime
                        withEndTime: (time_t) anEndTime;

- (double) getMinValueWithStartTime: (time_t) aStartTime
                        withEndTime: (time_t) anEndTime;


- (double) getMeanAntiLogValueWithStartTime: (time_t) aStartTime
                                withEndTime: (time_t) aEndTime;

- printDataToFileNamed: (char *) aFileName;

- readInputRecords;


- (void) drop;

@end
