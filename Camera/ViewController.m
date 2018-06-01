//
//  ViewController.m
//  Camera
//
//  Created by Peyton on 2018/5/28.
//  Copyright © 2018年 Peyton. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RecordVideoVC.h"


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
//输出为视频
@property (nonatomic, strong)AVCaptureMetadataOutput *metaOutput;
//预览layer
@property (nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;


//拍照按钮
@property (nonatomic, strong)UIButton *takePhotoBtn;
//切换摄像头按钮
@property (nonatomic, strong)UIButton *switchCameraButton;
//resultIV
@property (nonatomic, strong)UIImageView *resultIV;
//切换为视频
@property (nonatomic, strong)UIButton *switchToVideoButton;
//切换为照片
@property (nonatomic, strong)UIButton *switchToPhotoButton;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.captureDevice = [self getCaptureDeviceWithCameraPosition:AVCaptureDevicePositionBack];
    [self addPreviewLayerForView:self.view];
    [self.captureSession startRunning];
    [self takePhotoBtn];
    [self switchCameraButton];
    [self resultIV];
    [self switchToPhotoButton];
    [self switchToVideoButton];
    
    
    
}

#pragma mark systemMethods
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark ToolMethods
- (void)addPreviewLayerForView:(UIView *)view {
    [view.layer addSublayer:self.previewLayer];
}
//拍照
- (void)takePhotos {
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        //拍照失败
    }else {
        //成功, 获取图片
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            
            [self.captureSession stopRunning];
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            self.resultIV.image = image;
            [self savePhotoToAlbum:image];
            [self.captureSession startRunning];
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
        //如果有新的输入
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.deviceInput];
        [self.captureSession addInput:newInput];
        self.deviceInput = newInput;
    }else {
        
    }
    
    [self.captureSession commitConfiguration];
}

//切换拍照和录制视频
- (void)switchToTakePhoto {
    
    
    
}

- (void)switchToRecordVideo {
//    if (!_metaOutput) {
//        _metaOutput = [[AVCaptureMetadataOutput alloc]init];
//    }
//    [self.captureSession beginConfiguration];
//    [self.captureSession removeOutput:self.imageOutput];
//    [self.captureSession addOutput:_metaOutput];
//    AVCaptureConnection *con = [_metaOutput connectionWithMediaType:AVMediaTypeVideo];
//    [self.captureSession commitConfiguration];

    [self presentViewController:[RecordVideoVC new] animated:YES completion:nil];
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
        [_previewLayer setFrame:CGRectMake(0, 64, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 64 - CGRectGetHeight(self.takePhotoBtn.frame) - 50)];
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
        [_takePhotoBtn addTarget:self action:@selector(takePhotos) forControlEvents:UIControlEventTouchUpInside];
    }
    return _takePhotoBtn;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchCameraButton setFrame:CGRectMake(0, 0, 25 * SCREEN_SCALE, 25 *SCREEN_SCALE)];
        [_switchCameraButton setCenter:CGPointMake(SCREEN_WIDTH * 3 / 4 + 30, self.takePhotoBtn.center.y)];
        [_switchCameraButton setBackgroundImage:[UIImage imageNamed:@"切换"] forState:UIControlStateNormal];
        [self.view addSubview:_switchCameraButton];
        [_switchCameraButton addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraButton;
}

- (UIImageView *)resultIV {
    if (!_resultIV) {
        _resultIV = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 25 * SCREEN_SCALE, 25 * SCREEN_SCALE)];
        [self.view addSubview:_resultIV];
        [_resultIV setCenter:CGPointMake(SCREEN_WIDTH / 4 - 20, self.takePhotoBtn.center.y)];
        _resultIV.backgroundColor = [UIColor redColor];
    }
    return _resultIV;
}

- (UIButton *)switchToPhotoButton {
    if (!_switchToPhotoButton) {
        _switchToPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchToPhotoButton setFrame:CGRectMake(0, 0, 40, 20)];
        [_switchToPhotoButton setCenter:CGPointMake(self.takePhotoBtn.frame.origin.x, self.takePhotoBtn.frame.origin.y - 30 + 10)];
        _switchToPhotoButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.view addSubview:_switchToPhotoButton];
        [_switchToPhotoButton setTitle:@"照片" forState:UIControlStateNormal];
    }
    return _switchToPhotoButton;
}

- (UIButton *)switchToVideoButton {
    if (!_switchToVideoButton) {
        _switchToVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchToVideoButton setFrame:CGRectMake(0, 0, 40, 20)];
        [_switchToVideoButton setCenter:CGPointMake(self.takePhotoBtn.frame.origin.x + CGRectGetWidth(self.takePhotoBtn.frame), self.takePhotoBtn.frame.origin.y - 30 + 10)];
        _switchToVideoButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.view addSubview:_switchToVideoButton];
        [_switchToVideoButton setTitle:@"视频" forState:UIControlStateNormal];
        [_switchToVideoButton addTarget:self action:@selector(switchToRecordVideo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchToVideoButton;
}
@end
