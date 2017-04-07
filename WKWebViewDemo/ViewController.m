//
//  ViewController.m
//  WKWebViewDemo
//
//  Created by Admin on 17/3/30.
//  Copyright © 2016年 Admin. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "SecondViewController.h"

@interface ViewController ()<WKScriptMessageHandler,WKNavigationDelegate,WKUIDelegate>
//webView
@property(nonatomic,strong)WKWebView *webView;

@end

@implementation ViewController

#pragma mark----- VC 生命周期-----

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //移除监听
    [self.webView removeObserver:self forKeyPath:@"loading"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    //添加KVO监听
    [self.webView addObserver:self
                   forKeyPath:@"loading"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.webView addObserver:self
                   forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    [self.webView addObserver:self
                   forKeyPath:@"estimatedProgress"
                      options:NSKeyValueObservingOptionNew
                      context:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self creatWebView];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStyleDone target:self action:@selector(goback)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"前进" style:UIBarButtonItemStyleDone target:self action:@selector(gofarward)];
}

#pragma mark----- 导航按钮响应事件-----

- (void)goback{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        NSLog(@"back");
    }
}

- (void)gofarward{
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

//创建webView
- (void)creatWebView{
    
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    //初始化偏好设置属性：preferences
    config.preferences = [WKPreferences new];
    //The minimum font size in points default is 0;
    config.preferences.minimumFontSize = 10;
    //是否支持JavaScript
    config.preferences.javaScriptEnabled = YES;
    //不通过用户交互，是否可以打开窗口
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    //通过JS与webView内容交互
    config.userContentController = [WKUserContentController new];
    // 注入JS对象名称senderModel，当JS通过senderModel来调用时，我们可以在WKScriptMessageHandler代理中接收到
    [config.userContentController addScriptMessageHandler:self name:@"senderModel"];
    self.webView = [[WKWebView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 100) configuration:config];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"WKWebViewText" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:path]];
    [self.view addSubview:self.webView];
    
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
}


- (IBAction)pushTo:(UIButton *)sender
{
    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SecondViewController"] animated:YES];
    
}

#pragma mark - KVO监听函数
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }else if([keyPath isEqualToString:@"loading"]){
        NSLog(@"loading");
        }
    else if ([keyPath isEqualToString:@"estimatedProgress"]){

    }
    
    if (!self.webView.loading) {
        [UIView animateWithDuration:0.5 animations:^{
        }];
    }
    
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    //这里可以通过name处理多组交互
    if ([message.name isEqualToString:@"senderModel"]) {
        //body只支持NSNumber, NSString, NSDate, NSArray,NSDictionary 和 NSNull类型
        NSLog(@"%@",message.body);
        if ([message.body isKindOfClass:[NSString class]]) {
            if ([message.body isEqualToString:@"pushNextVC"]) {
                [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SecondViewController"] animated:YES];
                
            }
        }
        
    }
    
}

#pragma mark = WKNavigationDelegate
//在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSString *hostname = navigationAction.request.URL.host.lowercaseString;
    NSLog(@"%@",hostname);
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated
        && ![hostname containsString:@".baidu.com"]) {
        // 对于跨域，需要手动跳转
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        
        // 不允许web内跳转
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }

    
}
//在响应完成时，调用的方法。如果设置为不允许响应，web内容就不会传过来

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
//接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}

//开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
}
//当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}
//页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"title:%@",webView.title);
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
{
    
}

#pragma mark WKUIDelegate

//alert 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"调用alert提示框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    NSLog(@"alert message:%@",message);
    
}

//confirm 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认框" message:@"调用confirm提示框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
    
    NSLog(@"confirm message:%@", message);

}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入框" message:@"调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor blackColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
