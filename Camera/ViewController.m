//
//  ViewController.m
//  Camera
//
//  Created by Peyton on 2018/5/28.
//  Copyright © 2018年 Peyton. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface ViewController ()
//captureDevice
@property (nonatomic, strong)AVCaptureDevice *captureDevice;
//captureSession
@property (nonatomic, strong)AVCaptureSession *captureSession;
//deviceInput 输入
@property (nonatomic, strong)AVCaptureDeviceInput *deviceInput;
//输出为图片
@property (nonatomic, strong)AVCaptureStillImageOutput *imageOutput;
//预览layer
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captureDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    [self addPreviewLayerForView:self.view];
    [self.captureSession startRunning];
}

- (void)addPreviewLayerForView:(UIView *)view {
    [view.layer addSublayer:self.previewLayer];
}

#pragma mark lazy
//根据摄像头的位置获取摄像头
- (AVCaptureDevice *)getCaptureDeviceWithCameraPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *de in devices) {
        if (de.position == position) {
            return de;
        }
    }
    return nil;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc]init];
        //自定义拿到的图片大小
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        //添加输入源
        if ([_captureSession canAddInput:self.deviceInput]) {
            [_captureSession addInput:self.deviceInput];
        }
        //添加图片输出源
        if ([_captureSession canAddOutput:self.imageOutput]) {
            [_captureSession addOutput:self.imageOutput];
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
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
        _previewLayer.frame = self.view.frame;
        //layer设为填充状态
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        //设置摄像头朝向
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        _previewLayer.backgroundColor = [UIColor whiteColor].CGColor;
    }
    return _previewLayer;
}
@end
