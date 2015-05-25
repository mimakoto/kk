//
//  ViewController.h
//  BTLE_scan
//
//  Created by 藤野ラボ on 2014/12/10.
//  Copyright (c) 2014年 takaki.kurasaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PeripheralContainer.h"
@import CoreLocation;
#define BTLECOMM_SERVICE_UUID           @"B5FEFFF5-4904-4602-9DFA-B10947D4C06C"
#define BTLECOMM_CHARACTERISTIC_UUID    @"7C7A17F8-572C-4F26-9166-38D375947520"


@interface ViewController :UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate, AVAudioSessionDelegate,CLLocationManagerDelegate>{
    AVAudioRecorder *avRecorder;
    NSString *path;
    NSString *localName;
    NSString *myName;
    NSNumber *RSSI2;
    NSDateFormatter* df;
    NSString *taString;
    NSString *recStart;
    NSString *recEnd;
    NSString *dirPath;
    NSTimer *timer;
    NSMutableArray *allBeacons;
    AVAudioSession *audioSession;
    int count;
    int count2;
    int change;
    int flag;
    int i;
    int n;
    int up;
    int number;
    int r;
    int num;
    int Rssi;
    int Rssi2;
    int Rssi3;
    int tk;
    int becount;
    double distance;
    double distance2;
    double distance3;
    CLLocationAccuracy locationAccuracy;
    NSNumber* major;
    CLLocationAccuracy locationAccuracy2;
    NSNumber* major2;
    CLLocationAccuracy locationAccuracy3;
    NSNumber* major3;
}
- (IBAction)Start:(id)sender;
- (IBAction)Stop:(id)sender;
- (IBAction)Reset:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *dis;
@property (weak, nonatomic) IBOutlet UILabel *dis2;
@property (weak, nonatomic) IBOutlet UITextField *Interval;
- (IBAction)Send:(UIButton *)sender;

@end
