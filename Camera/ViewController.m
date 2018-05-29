//
//  ViewController.m
//  Camera
//
//  Created by Peyton on 2018/5/28.
//  Copyright © 2018年 Peyton. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define SCREEN_SCALE [UIScreen mainScreen].scale
#define SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)

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

//拍照按钮
@property (nonatomic, strong)UIButton *takePhotoBtn;
//照片
@property (nonatomic, strong)UIImageView *iv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.captureDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    [self addPreviewLayerForView:self.view];
    [self.captureSession startRunning];
    [self.view addSubview:_iv];
    [self takePhotoBtn];
}

#pragma mark ToolMethods
//拍照
- (void)takePhotos {
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        //拍照失败
    }else {
        //成功, 获取图片
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            self.iv.image = image;
            [self.captureSession stopRunning];
            [self savePhotoToAlbum:image];
            self.iv.hidden = YES;
        }];
    }
}

//存储到图库
- (void)savePhotoToAlbum:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
}
//这里的方法必须使用系统给定的方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        //存储失败
        NSLog(@"存储失败");
    }else {
        //存储成功
        NSLog(@"存储成功");
    }
}

//切换前置后置摄像头
- (void)changeCamera {
    //创建一个新的device
    AVCaptureDevice *newDevice = nil;
    //创建一个新的输入
    AVCaptureDeviceInput *newInput = nil;
    AVCaptureDevicePosition currentPosition = self.deviceInput.device.position;
    if (currentPosition == AVCaptureDevicePositionBack) {
        newDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionFront];
    }else {
        newDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    }
    newInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:nil];
    if (newInput != nil) {
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.deviceInput];
        [self.captureSession addInput:newInput];
        self.deviceInput = newInput;
    }else {
        
    }
    
    [self.captureSession commitConfiguration];
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

- (AVCaptureStillImageOutput *)imageOutput {
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc]init];
        
    }
    return _imageOutput;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.captureSession];
        [_previewLayer setFrame:CGRectMake(0, 64, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 64 - CGRectGetHeight(self.takePhotoBtn.frame) - 20)];
        //layer设为填充状态
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        //设置摄像头朝向
        _previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        _previewLayer.backgroundColor = [UIColor whiteColor].CGColor;
    }
    return _previewLayer;
}

- (UIButton *)takePhotoBtn {
    if (!_takePhotoBtn) {
        _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_takePhotoBtn setFrame:CGRectMake(0, 0, 30 * SCREEN_SCALE, 30 * SCREEN_SCALE)];
        [_takePhotoBtn setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(_takePhotoBtn.frame) / 2.0 - 10)];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph"] forState:UIControlStateNormal];
        [_takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"photograph_Select"] forState:UIControlStateSelected];
        [self.view addSubview:_takePhotoBtn];
//        [_takePhotoBtn addTarget:self action:@selector(takePhotos) forControlEvents:UIControlEventTouchUpInside];
        [_takePhotoBtn addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _takePhotoBtn;
}

- (UIImageView *)iv {
    if (!_iv) {
        _iv = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
        [self.view insertSubview:_iv belowSubview:self.takePhotoBtn];
    }
    return _iv;
}
@end
