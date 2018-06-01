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

@end

@implementation RecordVideoVC
//我们这里只做了后置摄像头的视频输入输出, 并没有做切换摄像头/音频的输入输出
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
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    NSString *wholeVideoName = [[self creatVideoName] stringByAppendingString:@".mp4"];
    self.videoURL = [NSURL fileURLWithPath:[[self createVieoDirectory] stringByAppendingPathComponent:wholeVideoName]];
    
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
    [formatter setDateFormat:@"YYYY_MM_dd_HH_mm_ss_zzz"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    return dateString;
}
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //当视频开始录制的时候, 这里就拿到了数据
    [self.writer startWriting];
    if (output == self.videoOutput) {
        if (self.writerInput.readyForMoreMediaData) {
            BOOL success = [self.writerInput appendSampleBuffer:sampleBuffer];
            if (!success) {
                [self.writer finishWritingWithCompletionHandler:^{
                    NSLog(@"failed");
                }];
            }
        }
    }
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
        [_previewLayer setFrame:CGRectMake(0, 64, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 64 - CGRectGetHeight(self.takePhotoBtn.frame) - 50)];
        [self.view.layer addSublayer:_previewLayer];
        
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

- (AVAssetWriter *)writer {
    if (!_writer) {
        _writer = [[AVAssetWriter alloc]initWithURL:self.videoURL fileType:AVFileTypeMPEG4 error:nil];
        if ([_writer canAddInput:self.writerInput]) {
            [_writer addInput:self.writerInput];
        }
    }
    return _writer;
}

- (AVAssetWriterInput *)writerInput {
    if (!_writerInput) {
        _writerInput = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeVideo outputSettings:nil];
    }
    return _writerInput;
}
@end
