//
//  ViewController.m
//  BTLE_scan
//
//  Created by 藤野ラボ on 2014/12/10.
//  Copyright (c) 2014年 takaki.kurasaki. All rights reserved.
//

#import "ViewController.h"

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
@import CoreLocation;

//iBeaconのUUID(専用アプリから変更可能)
#define UUID    @"01000000-0000-0000-0000-000000000000"
#define myidentifier    @"Enamel Systems"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate,CLLocationManagerDelegate>{
      NSMutableSet *_devices[2];
}

@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *btlecommcha;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property NSMutableDictionary *beacons;
@property CLLocationManager *locationManager;
@property NSMutableDictionary *rangedRegions;
@property (nonatomic) NSArray *containers;




@end

@implementation ViewController


//起動時に動作
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"アプリ起動");
    count = 0;
    count2 = 0;
    RSSI2 = 0;
    i = 0;
    n = 0;
    up = 1;
    number = 0;
    tk = 0;
    
    //ローカルネームの取得
    myName = [[UIDevice currentDevice] name];
    
    //取得データを保存するファイルをhtdocs内に作成
    /*NSURL *url = [NSURL URLWithString:@"http://192.168.11.26/file.php"];*/
    NSURL *url = [NSURL URLWithString:@"http://192.168.11.17/file.php"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *alldata = [NSString stringWithFormat:@"myname=%@",myName];
    request.HTTPBody = [alldata dataUsingEncoding:NSUTF8StringEncoding];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSLog(@"ファイル作成完了");

    //時刻の取得
    df = [[NSDateFormatter alloc] init];
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [df setCalendar:cal];
    [df setLocale:[NSLocale systemLocale]];
    [df setDateFormat:@"HH:mm:ss"];
    
    self.beacons = [[NSMutableDictionary alloc] init];
 　　self.locationManager = [[CLLocationManager alloc] init];
    
    //バージョン8.0以降の場合は位置情報の取得をonにするよう聞く
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 8.0) {
        [self.locationManager requestAlwaysAuthorization];
    }
    
    self.locationManager.delegate = self;
  
    self.rangedRegions = [[NSMutableDictionary alloc] init];
    
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:UUID];
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:myidentifier];
    self.rangedRegions[region] = [NSArray array];
    
    _devices[0] = [[NSMutableSet alloc] init];
    _devices[1] = [[NSMutableSet alloc] init];
    
    audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;

  /*  if ([audioSession inputIsAvailable]) {
        [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    }
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }*/
    
    // 録音機能をアクティブにする
    [audioSession setActive:YES error:&error];
    if(error){
        NSLog(@"audioSession: %@ %d %@", [error domain], [error code], [[error userInfo] description]);
    }

  }


- (void)viewWillDisappeear:(BOOL)animated
{
    // スキャン停止
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Start ranging when the view appears.
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager startRangingBeaconsInRegion:region];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Stop ranging when the view goes away.
    for (CLBeaconRegion *region in self.rangedRegions)
    {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
}

//iBeaconのロケーションマネージャーを起動
//iBeaconの検出等
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
 
    //CLProximityUnknown以外のiBeacon情報を取得
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"proximity != %d", CLProximityUnknown];
    self.rangedRegions[region] = [beacons filteredArrayUsingPredicate:predicate];
    
    
    locationAccuracy = 0.0;
    
    major = @0;
    Rssi = 0;
    
    locationAccuracy2 = 0.0;
    
    major2 = @0;
    Rssi2 = 0;
    
    locationAccuracy3 = 0.0;
    
    major3 = @0;
    Rssi3 = 0;
    
 
    [self.beacons removeAllObjects];
    allBeacons = [NSMutableArray array];
    
    //allBeaconsにデータ格納
    for (NSArray *regionResult in [self.rangedRegions allValues])
    {
        
        [allBeacons addObjectsFromArray:regionResult];
        
    }
    
   for (NSNumber *range in @[@(CLProximityUnknown), @(CLProximityImmediate), @(CLProximityNear), @(CLProximityFar)])
    {
        NSArray *proximityBeacons = [allBeacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"proximity = %d", [range intValue]]];
        
        if([proximityBeacons count])
        {
            self.beacons[range] = proximityBeacons;
        }
    }
    
    NSLog(@"%lu",(unsigned long)[allBeacons count]);

//Beaconを３つ取得（近くから）
    CLBeacon *beacon = allBeacons.firstObject;
    locationAccuracy = beacon.accuracy;
    major = beacon.major;
    Rssi = beacon.rssi;
    
    
    if([allBeacons count] >=3){
        
        CLBeacon *beacon2 = [allBeacons objectAtIndex:1];
        locationAccuracy2 = beacon2.accuracy;
        major2 = beacon2.major;
        Rssi2 = beacon2.rssi;
        
        CLBeacon *beacon3 = [allBeacons objectAtIndex:2];
        locationAccuracy3 = beacon3.accuracy;
        major3 = beacon3.major;
        Rssi3 = beacon3.rssi;
        
        
    }else if([allBeacons count] >=2){
        
        CLBeacon *beacon2 = [allBeacons objectAtIndex:1];
        locationAccuracy2 = beacon2.accuracy;
        major2 = beacon2.major;
        Rssi2 = beacon2.rssi;
        
        becount = 2;
    }
}

//状態が変化したら呼ばれる
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // BLEの電源がoffの場合
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"BLE off");
        return;
    }
    // onならスキャン開始
    NSLog(@"BLE on");
    [self scan];
    
}

// peripheralのスキャン
- (void)scan
{
 //本アプリのServiceのUUIDを発しているperipheralのみscan
    NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:BTLECOMM_SERVICE_UUID], nil];
    [self.centralManager scanForPeripheralsWithServices:services
     
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
    
}


/** アドバタイズしているperipheralが発見されると呼ばれる
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{

    //ローカルネーム、RSSIを保存
   localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    RSSI2 = RSSI;
    
    
  //peripheralの情報をPeripheralContainerに格納
    if(localName != nil  ) {
        PeripheralContainer *c = [[PeripheralContainer alloc] init];
        c.peripheral = peripheral;
        if(![RSSI  isEqual: @127]){
            c.RSSI = RSSI;
        }
        [self findPeripheral:c];
    }
}

// Peripheralを追加
-(void)findPeripheral:(PeripheralContainer *)c {
    
    if(c != nil && ! [PeripheralContainer contains:_devices[1] peripheral:c.peripheral]) {
        [_devices[1] addObject:c];
    }
    // 更新
    NSSet *d = [PeripheralContainer union:_devices[0] b:_devices[1]];
    self.containers = [d allObjects];
}

/*peripheralの起動*/
-(void)peripheral{
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue: nil];
    NSLog(@"Peripherl on");
    
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    NSLog(@"self.peripheralManager powered on.");
    
    //キャラクタリスティック
    self.btlecommcha = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:BTLECOMM_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    // サービス
    CBMutableService *btlecommser = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:BTLECOMM_SERVICE_UUID]
                                                                       primary:YES];
    
    // 特性にサービスを登録
    btlecommser.characteristics = @[self.btlecommcha];
    
    // ペリフェラルに登録
    [self.peripheralManager addService:btlecommser];
    
    [self advertise];
    
}

/*アドバタイズ*/
- (void) advertise
{
    NSString *Name = [[UIDevice currentDevice] name];
    NSDictionary *advertisementData = @{ CBAdvertisementDataServiceUUIDsKey:
                                             @[[CBUUID UUIDWithString:BTLECOMM_SERVICE_UUID]],
                                         CBAdvertisementDataLocalNameKey:Name};
    [self.peripheralManager startAdvertising:advertisementData];
    
}


//timer兼データ送信
-(void)time:(NSTimer*)timer{
    count += 1;
    count2 += 1;
    
    //デバイスデータのpost
    if(count == num){
   
        taString = [df stringFromDate:[NSDate date]];
     
        
        NSLog(@"%@",taString);
        NSLog(@"stop scan");
        
        NSInteger size = [self.containers count];
        NSLog(@"%ld", (long)size);
        while(size != 0 ){
        PeripheralContainer *c = [_containers objectAtIndex:tk];
        NSLog(@"localname:%@,RSSI:%@" ,c.peripheral.name, c.RSSI);
    
            //使わないけど距離測定
            double ue = (-c.RSSI.doubleValue+(-61))/(20);
            double distanced = pow(10.0,ue);
            
            NSString *print = [[NSString alloc] initWithFormat:@"%.1f",distanced];
            self.dis.text = print;
            
            NSString *print2 = [[NSString alloc] initWithFormat:@"%@",c.RSSI];
            self.dis2.text = print2;
            

            
            /*NSURL *url = [NSURL URLWithString:@"http://192.168.11.26/text.php"];*/
            NSURL *url = [NSURL URLWithString:@"http://192.168.11.17/text.php"];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
            request.HTTPMethod = @"POST";
            NSString *alldata = [NSString stringWithFormat:@"localname=%@&rssi=%@&distance=%f&myname=%@&time=%@",c.peripheral.name,c.RSSI,distanced,myName,taString];
            request.HTTPBody = [alldata dataUsingEncoding:NSUTF8StringEncoding];
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            NSLog(@"送信完了");
            tk++;
            size--;
        }
        size = 0;
        tk = 0;
        [_devices[0] removeAllObjects];
        [_devices[1] removeAllObjects];
        count = 0;
    }
    
    //iBeaconデータのpost
    if(count2 == num){
        taString = [df stringFromDate:[NSDate date]];
      
        double ue = (-(double)Rssi+(-77))/(20);
        distance = pow(10.0,ue);
            NSLog(@"distance:%.1f",distance);
            NSLog(@"major:%@",major);

    
        double ue2 = (-(double)Rssi2+(-77))/(20);
        distance2 = pow(10.0,ue2);
            NSLog(@"distance2:%.1f",distance2);
            NSLog(@"major2:%@",major2);

    
        
        double ue3 = (-(double)Rssi3+(-77))/(20);
        distance3 = pow(10.0,ue3);
            NSLog(@"distance3:%.1f",distance3);
            NSLog(@"major3:%@",major3);

        
        /*NSURL *url = [NSURL URLWithString:@"http://192.168.11.26/text2.php"];*/
        NSURL *url = [NSURL URLWithString:@"http://192.168.11.17/text2.php"];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = @"POST";
        NSString *alldata = [NSString stringWithFormat:@"time=%@&distance=%.2f&major=%@&distance2=%.2f&major2=%@&distance3=%.2f&major3=%@&myname=%@",taString,distance,major,distance2,major2,distance3,major3,myName];
        request.HTTPBody = [alldata dataUsingEncoding:NSUTF8StringEncoding];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        NSLog(@"beacon送信完了");
        count2 = 0;
        distance = 0;
        distance2 = 0;
        distance3 = 0;
    }
    
      //RSSIが一定値を超えるとオーディオ機能を起動
    if(RSSI2.integerValue >= -60&& RSSI2.integerValue <= -1){
        
        //upが1なら録音開始
        if(up == 1){
            recStart = [df stringFromDate:[NSDate date]];
            NSError *error = nil;
            
        // 録音ファイルパス
        NSArray *filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask,YES);
        NSString *documentDir = [filePaths objectAtIndex:0];
        path = [documentDir stringByAppendingPathComponent:@"rec/recording.caf"];
        NSURL *recordingURL = [NSURL fileURLWithPath:path];
        
        NSLog(@"rec start");
        
        avRecorder = [[AVAudioRecorder alloc] initWithURL:recordingURL settings:nil error:&error];
        
        if(error){
            NSLog(@"error = %@",error);
            return;
        }
        avRecorder.delegate=self;
        
        //record
        [avRecorder record];
            up = 0;
            
        }
    }
    
    //離れると録音終了、データの保存
        if(RSSI2.integerValue < -60){
            //up==0の時のみ終了できる
            if(up == 0){
                [avRecorder stop];
                recEnd =[df stringFromDate:[NSDate date]];
                NSLog(@"rec end");

                NSFileManager *fileMgr;
                NSString *documentsDir;
                
                // file manager起動
                fileMgr = [NSFileManager defaultManager];
                // pathの指定
                documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/rec/"];
                
                //保存した音声ファイルの名前をタイムスタンプに変更
                NSString *src = [documentsDir stringByAppendingPathComponent:@"recording.caf"];
                NSString *new = [NSString stringWithFormat:@"%@_%@_%@.caf",recStart,recEnd,localName];
                NSString *dst = [documentsDir stringByAppendingPathComponent:new];
                
                NSError *error;
                
                BOOL result = [fileMgr moveItemAtPath:src toPath:dst error:&error];
                
                if(result){
                    NSLog(@"ファイル名の変更に成功:%@",dst);
                }else{
                    NSLog(@"ファイル名の変更に失敗:%@",error.description);
                }
                
                up = 1;

            }
        }
    
}

//startボタンの挙動
- (IBAction)Start:(id)sender {
    if (![timer isValid]) {
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(time:) userInfo:nil repeats:YES];
    }
    //録音データを保存するディレクトリをDocuments直下に作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    dirPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/rec/"];
    BOOL result = [fileManager createDirectoryAtPath:dirPath
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error];
    
    if(result){
        NSLog(@"ディレクトリ作成成功");
    }else{
        NSLog(@"ディレクトリ作成失敗");
    }
    
    // CentralManager起動
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _data = [[NSMutableData alloc] init];
    NSLog(@"Central on");
    [self peripheral];
   

}

//stopボタンの挙動
- (IBAction)Stop:(id)sender {
    // スキャン停止
    if ([timer isValid]) {
        [timer invalidate];
        [self.centralManager stopScan];
        [self.peripheralManager stopAdvertising];
        self.containers = [[NSArray alloc] init];
        [_devices[0] removeAllObjects];
        [_devices[1] removeAllObjects];
        NSLog(@"Scanning stopped");
    }

}

//resetボタンの挙動
- (IBAction)Reset:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/rec"];
    NSError *error;
    //ディレクトリの消去
    BOOL result = [fileManager removeItemAtPath:filePath error:&error];
    if(result){
        NSLog(@"前回のデータを消去に成功:%@",filePath);
    }else{
        NSLog(@"前回のデータの消去に失敗:%@",error.description);
    }
}

//scan間隔（送信間隔）の設定
- (IBAction)Send:(UIButton *)sender {
        num = [_Interval.text intValue];
}
@end

