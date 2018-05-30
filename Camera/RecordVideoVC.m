//
//  RecordVideoVC.m
//  Camera
//
//  Created by Peyton on 2018/5/30.
//  Copyright © 2018年 Peyton. All rights reserved.
//

#import "RecordVideoVC.h"
#import <AVFoundation/AVFoundation.h>

#define SCREEN_SCALE [UIScreen mainScreen].scale
#define SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)

@interface RecordVideoVC ()<AVCaptureFileOutputRecordingDelegate>
//拍照按钮
@property (nonatomic, strong)UIButton *takePhotoBtn;

//captureDevice
@property (nonatomic, strong)AVCaptureDevice *captureDevice;
//captureSession
@property (nonatomic, strong)AVCaptureSession *captureSession;
//deviceInput 输入
@property (nonatomic, strong)AVCaptureDeviceInput *deviceInput;
//输出为视频
@property (nonatomic, strong)AVCaptureMovieFileOutput *movieOutput;
//预览layer
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation RecordVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self takePhotoBtn];
    self.captureDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    [self previewLayer];
    [self.captureSession startRunning];
}

#pragma mark toolMethods
- (void)recordMovie {
    AVCaptureConnection *connection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
    NSString *pathString = [NSTemporaryDirectory() stringByAppendingPathComponent:@"1.mov"];
    NSURL *url = [NSURL fileURLWithPath:pathString];
    if ([self.movieOutput isRecording]) {
        [self.movieOutput stopRecording];
    }else {
        //如果没有在录制视频
        [self.movieOutput startRecordingToOutputFileURL:url recordingDelegate:self];
    }
    
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

- (BOOL)prefersStatusBarHidden {
    return  YES;
}
#pragma mark lazy
- (UIButton *)takePhotoBtn {
    if (!_takePhotoBtn) {
        _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_takePhotoBtn setFrame:CGRectMake(0, 0, 30 * SCREEN_SCALE, 30 * SCREEN_SCALE)];
        [_takePhotoBtn setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(_takePhotoBtn.frame) / 2.0 - 10)];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph"] forState:UIControlStateNormal];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph_Select"] forState:UIControlStateSelected];
        [self.view addSubview:_takePhotoBtn];
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
        if ([_captureSession canAddOutput:self.movieOutput]) {
            [_captureSession addOutput:self.movieOutput];
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

- (AVCaptureMovieFileOutput *)movieOutput {
    if (!_movieOutput) {
        _movieOutput = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _movieOutput;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
        [_previewLayer setFrame:CGRectMake(0, 64, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 64 - CGRectGetHeight(self.takePhotoBtn.frame) - 50)];
        [self.view.layer addSublayer:_previewLayer];
        
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}
@end
