//
//  PeripheralContainer.m
//  BTLE_scan
//
//  Created by kurasaki on 2015/01/08.
//  Copyright (c) 2015年 takaki.kurasaki. All rights reserved.
//

#import "PeripheralContainer.h"

@implementation PeripheralContainer
@synthesize RSSI;
@synthesize peripheral;

//peripheralの情報の格納
+(BOOL)contains:(NSSet *)containers peripheral:(CBPeripheral *)peripheral {
    for(PeripheralContainer *c in containers) {
        if(c.peripheral == peripheral) return YES;
    }
    return NO;
}

//複数検出した場合
+(NSSet *)union:(NSSet *)a b:(NSSet *)b {
    NSMutableSet *dst = [[NSMutableSet alloc] init];
    NSMutableSet *p   = [[NSMutableSet alloc] init];
    
    for(PeripheralContainer *c in a) {
        if(![p containsObject:c.peripheral]) {
            [p addObject:c.peripheral];
            [dst addObject:c];
        }
    }
    for(PeripheralContainer *c in b) {
        if(![p containsObject:c.peripheral]) {
            [p addObject:c.peripheral];
            [dst addObject:c];
        }
    }
    return dst;
}
@end
