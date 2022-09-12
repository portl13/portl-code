//
//  MapViewAnnotationForNormal.h
//  Portl
//
//  Created by Messia Enginner on 2017/06/06.
//  Copyright © 2017 Portl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapViewAnnotationForEvent.h"

@interface MapViewAnnotationForNormal : NSObject <MKAnnotation> {
    NSString *title;
    CLLocationCoordinate2D coordinate;
}

@property (strong, nonatomic) PortlEvent *event;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, retain) MapViewAnnotationForEvent *calloutAnnotationForEvent;

@end
