//
//  RecordVideoVC.m
//  Camera
//
//  Created by Peyton on 2018/5/30.
//  Copyright © 2018年 Peyton. All rights reserved.
//

#import "RecordVideoVC.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>


#define SCREEN_SCALE [UIScreen mainScreen].scale
#define SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)

@interface RecordVideoVC ()<AVCaptureVideoDataOutputSampleBufferDelegate>
//录制按钮
@property (nonatomic, strong)UIButton *takePhotoBtn;

//captureDevice
@property (nonatomic, strong)AVCaptureDevice *captureDevice;
//captureSession
@property (nonatomic, strong)AVCaptureSession *captureSession;
//deviceInput 输入
@property (nonatomic, strong)AVCaptureDeviceInput *deviceInput;
//输出为视频
@property (nonatomic, strong)AVCaptureVideoDataOutput *videoOutput;
//预览layer
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
//写入
@property (nonatomic, strong)AVAssetWriter *writer;
//writerInput
@property (nonatomic, strong)AVAssetWriterInput *writerInput;
//videoURL
@property (nonatomic, strong)NSURL *videoURL;
//closeBtn
@property (nonatomic, strong)UIButton *closeBtn;
//view
@property (nonatomic, strong)UIView *view1;

@end


@implementation RecordVideoVC
static int startOrStop = 1;
//这里只做了后置摄像头的视频输入输出, 并没有做切换摄像头/音频的输入输出
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self takePhotoBtn];
    [self closeBtn];
    self.captureDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    [self previewLayer];
    [self startCaptureDate];
    
}

//开始捕获数据
- (void)startCaptureDate {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        dispatch_sync(dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL), ^{
            [self.captureSession startRunning];
        });
    }else {
        UIAlertController *authorizationAlert = [UIAlertController alertControllerWithTitle:nil message:@"请您设置允许APP访问您的相机->设置->隐私->相机" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [authorizationAlert addAction:action];
        [self presentViewController:authorizationAlert animated:YES completion:nil];
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //当开始捕捉的时候, 这里就拿到了数据
    if (output == self.videoOutput) {
        CFRetain(sampleBuffer);
        [self writeInSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
    }
}

//录制视频
- (void)writeInSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //准备好数据写入
        NSLog(@"ready");
        //从这里可以看出, AVAssetWrite是针对每一帧进行写入的
        if (self.writer.status == AVAssetWriterStatusUnknown) {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:startTime];
        }
        
        if (self.writerInput.readyForMoreMediaData == YES) {
            BOOL success = [self.writerInput appendSampleBuffer:sampleBuffer];
            if (!success) {
                [self.writer finishWritingWithCompletionHandler:^{
                    NSLog(@"finished");
                }];
            }else {
                NSLog(@"succeed!");
            }
        }
    }
}
#pragma mark toolMethods
- (void)closeThisPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordMovie {
    if (startOrStop) {
        [UIView animateWithDuration:1 animations:^{
            [self.previewLayer setFrame:CGRectMake(0, 60, SCREEN_WIDTH, SCREEN_HEIGHT - 60)];
            self.view1.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        }];
        //开始录制
        AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        //判断是否支持videoOrientation属性
        if ([connection isVideoOrientationSupported]) {
            connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
        //判断是否支持视频稳定, 可以显著提高视频质量
        if ([connection isVideoStabilizationSupported]) {
            [connection setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeCinematic];
        }
        //摄像头进行平滑对焦模式
        if (self.captureDevice.isSmoothAutoFocusEnabled) {
            NSError *error = nil;
            if ([self.captureDevice lockForConfiguration:&error]) {
                [self.captureDevice setSmoothAutoFocusEnabled:YES];
                [self.captureDevice unlockForConfiguration];
            }else {
                //
            }
        }
        NSString *wholeVideoName = [[self creatVideoName] stringByAppendingString:@".mp4"];
        self.videoURL = [NSURL fileURLWithPath:[[self createVieoDirectory] stringByAppendingPathComponent:wholeVideoName]];
        NSError *error = nil;
        _writer = [AVAssetWriter assetWriterWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:&error];
        if (!error) {
            //创建AVAssetWriter成功
            if ([self.writer canAddInput:self.writerInput]) {
                [self.writer addInput:self.writerInput];
            }
            NSLog(@"开始写入");
            startOrStop = 0;
        }
    }else {
        [UIView animateWithDuration:1 animations:^{
            [self.previewLayer setFrame:CGRectMake(0, 64, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 64 - CGRectGetHeight(self.takePhotoBtn.frame) - 50)];
        }];
        //停止录制
        [self.writer finishWritingWithCompletionHandler:^{
            NSLog(@"停止写入");
            [self saveToAlbum];
        }];
        startOrStop = 1;
    }
}

//保存到相册
- (void)saveToAlbum {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"保存成功");
    }];
}

//获取视频第一帧的图片
- (void)movieToImageHandler:(void (^)(UIImage *movieImage))handler {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(thumbImg);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

//根据摄像头的位置获取到摄像头设备
- (AVCaptureDevice *)getCaptureDeviceWithCameraPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *de in devices) {
        if (de.position == position) {
            return de;
        }
    }
    return nil;
}

//隐藏状态栏
- (BOOL)prefersStatusBarHidden {
    return  YES;
}

#pragma mark 为每个视频拼接不同的文件路径
- (NSString *)createVieoDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSArray *arr = [fileManager contentsOfDirectoryAtPath:documentPath error:nil];
    //判断Document文件夹下是否有Video文件夹
    if ([arr containsObject:@"Video"]) {
        //有, 返回该文件夹的路径
        return [documentPath stringByAppendingPathComponent:@"Video"];
    }else {
        //没有,  则在Document文件夹下新建一个Video文件夹
        NSString *videoPath = [documentPath stringByAppendingPathComponent:@"Video"];
        if ([fileManager createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            return videoPath;
        }else {
            return nil;
        }
    }
}

- (NSString *)creatVideoName {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"YYYY_MM_dd_HH_mm_ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    return dateString;
}

#pragma mark lazy
- (UIButton *)takePhotoBtn {
    if (!_takePhotoBtn) {
        _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_takePhotoBtn setFrame:CGRectMake(0, 0, 30 * SCREEN_SCALE, 30 * SCREEN_SCALE)];
        [_takePhotoBtn setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(_takePhotoBtn.frame) / 2.0 - 10)];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph"] forState:UIControlStateNormal];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph_Select"] forState:UIControlStateSelected];
//        [self.view addSubview:_takePhotoBtn];
        [self.view insertSubview:_takePhotoBtn aboveSubview:self.view1];
        [_takePhotoBtn addTarget:self action:@selector(recordMovie) forControlEvents:UIControlEventTouchUpInside];
    }
    return _takePhotoBtn;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc]init];
        if ([_captureSession canAddInput:self.deviceInput]) {
            [_captureSession addInput:self.deviceInput];
        }
        if ([_captureSession canAddOutput:self.videoOutput]) {
            [_captureSession addOutput:self.videoOutput];
        }
    }
    return _captureSession;
}

- (AVCaptureDeviceInput *)deviceInput {
    if (!_deviceInput) {
        _deviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:self.captureDevice error:nil];
    }
    return _deviceInput;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc]init];
         dispatch_queue_t queue = dispatch_queue_create("videoQueue", DISPATCH_QUEUE_SERIAL);
        [_videoOutput setSampleBufferDelegate:self queue:queue];
    }
    return _videoOutput;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
        [_previewLayer setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        [self.view1.layer addSublayer:_previewLayer];
        
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

- (AVAssetWriterInput *)writerInput {
    if (!_writerInput) {
        //录制视频的一些配置，分辨率，编码方式等等
        NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  AVVideoCodecH264, AVVideoCodecKey,
                                  [NSNumber numberWithInteger: SCREEN_WIDTH * 2], AVVideoWidthKey,
                                  [NSNumber numberWithInteger: SCREEN_HEIGHT * 2], AVVideoHeightKey,
                                  nil];
        _writerInput = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeVideo outputSettings:settings];
        //必须要写
        _writerInput.expectsMediaDataInRealTime = YES;
    }
    return _writerInput;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setBackgroundImage:[UIImage imageNamed:@"close-o"] forState:UIControlStateNormal];

        [self.view insertSubview:_closeBtn aboveSubview:self.view1];
        [_closeBtn setFrame:CGRectMake(20, 20 , 24, 24)];
        [_closeBtn addTarget:self action:@selector(closeThisPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIView *)view1 {
    if (!_view1) {
        _view1 = [[UIView alloc]initWithFrame:self.view.frame];
        _view1.backgroundColor = [UIColor blackColor];
        [self.view addSubview:_view1];
    }
    return _view1;
}

@end
