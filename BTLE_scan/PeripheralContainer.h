//
//  PeripheralContainer.h
//  BTLE_scan
//
//  Created by kurasaki on 2015/01/08.
//  Copyright (c) 2015年 takaki.kurasaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// CBPeripheralは、接続後にRSSIが取れる。 接続しない状態では、発見時のRSSIを覚えておくしかない。そのためコンテナを使う。
@interface PeripheralContainer : NSObject
@property (nonatomic) NSNumber *RSSI;
@property (nonatomic) CBPeripheral *peripheral;

+(BOOL)contains:(NSSet *)containers peripheral:(CBPeripheral *)peripheral;
+(NSSet *)union:(NSSet *)a b:(NSSet *)b;

@end
