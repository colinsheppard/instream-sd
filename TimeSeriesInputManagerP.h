//
// inSTREAM-SD-2D (inSTREAM version 3.1)
// Developed by Lang Railsback & Assoc., Arcata CA for Argonne National Laboratory
// Software maintained by Jackson Scientific Computing, McKinleyville CA;
// This library is distributed without any warranty; without even the
// implied warranty of merchantability or fitness for a particular purpose.
// See file LICENSE for details and terms of copying
// 



@protocol TimeSeriesInputManager  <CREATABLE>

//CREATING

+     createBegin: (id <Zone>) aZone
     withDataType: (char *) aTypeString
    withInputFile: (char *) aFileName
  withTimeManager: (id <TimeManager>) aTimeManager
    withStartTime: (time_t) aStartTime
      withEndTime: (time_t) anEndTime
    withCheckData: (BOOL) aFlag;

- createEnd;


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
                                withEndTime: (time_t) anEndTime;


- printDataToFileNamed: (char *) aFileName;


- (void) drop;

@end


@class TimeSeriesInputManager;
