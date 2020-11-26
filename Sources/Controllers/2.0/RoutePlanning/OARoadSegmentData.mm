//
//  OARoadSegmentData.m
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoadSegmentData.h"
#import "OAApplicationMode.h"
#import "OAGPXDocumentPrimitives.h"

@implementation OARoadSegmentData

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode start:(OAGpxTrkPt *)start end:(OAGpxTrkPt *)end points:(NSArray<OAGpxTrkPt *> *)points segments:(std::vector<std::shared_ptr<RouteSegmentResult>>)segments
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        _start = start;
        _end = end;
        _points = points;
        _segments = segments;
        double distance = 0;
        if (points != nil && points.count > 1)
        {
            for (NSInteger i = 1; i < points.count; i++)
            {
                distance += getDistance(points[i - 1].latitude, points[i - 1].longitude,
                        points[i].latitude, points[i].longitude);
            }
        }
        else if (segments.size() > 0)
        {
            for (const auto& segment : segments)
            {
                distance += segment->distance;
            }
        }
        _distance = distnce;
    }
    return self;
}

- (NSArray<OAGpxTrkPt *> *) points
{
    return _points ? [NSArray arrayWithArray:_points] : nil;
}

@end
