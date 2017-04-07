# WKWebView-JS-
WKWebView 与JS交互  Demo
<p>
> APP开发过程中，内部加载网页是很常见的交互，手机端经常使用webView加载网页相关页面。iOS8之前通常使用UIWebView，但是UIWebView的通病一直得不到有效的解决，比如：加载速度慢，占用内存多，优化困难，加载网页过多的话还有可能因为占用内存过大而被系统kill掉等。

苹果为了解决这个问题，在iOS8之后推出了替换UIWebView的新组件WKWebView，基本上各种问题都得到了解决，现在WKWebView 是APP内部加载网页的最佳选择。

其新特性：
1.在性能、稳定性、功能方面有很大提升（最直观的体现就是加载网页是占用的内存，模拟器加载百度与开源中国网站时，WKWebView占用23M，而UIWebView占用85M）；
2.允许JavaScript的Nitro库加载并使用（UIWebView中限制）；
3.支持了更多的HTML5特性；
4.高达60fps的滚动刷新率以及内置手势；
5.将UIWebViewDelegate与UIWebView重构成了14类与3个协议（[查看苹果官方文档](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/WebKit/ObjC_classic/index.html)）

基本用法：
1.加载网页
2.加载的状态回调
3.新的WKUIDelegate协议
4.动态加载并运行JS代码
5.webView 执行JS代码
6.JS调用App注册过的方法

用法概述：
1.加载网页：
加载网页或HTML代码的方式与UIWebView相同，代码示例如下：
```
WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]]];
[self.view addSubview:webView];
```

2.加载的状态回调即代理（WKNavigationDelegate）方法实现
用来追踪加载过程（页面开始加载、加载完成、加载失败）的方法：
```
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation;
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation;
```
页面跳转的代理方法：
```
// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation;
// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
```
3.新的WKUIDelegate协议
与JS的alert、confirm、prompt交互，我们希望用自己的原生界面，而不是JS的，就可以使用这个代理类来实现。
1. alert警告框函数：
```
//alert 警告框
-(void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"调用alert提示框" preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      completionHandler();
  }]];
  [self presentViewController:alert animated:YES completion:nil];
  NSLog(@"alert message:%@",message);
}
```
2. confirm确认框函数：
```
//confirm 确认框
-(void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认框" message:@"调用confirm提示框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}
```
3. prompt 输入框函数：
```
//confirm 确认框
-(void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入框" message:@"调用输入框" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor blackColor];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[alert.textFields lastObject] text]);
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}
```
4.动态加载并运行JS代码
用于在客户端内部加入JS代码，并执行，示例如下：
```
// 图片缩放的js代码
NSString *js = @"var count = document.images.length;for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=320;};window.alert('找到' + count + '张图');";
// 根据JS字符串初始化WKUserScript对象
WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
// 根据生成的WKUserScript对象，初始化WKWebViewConfiguration
WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
[config.userContentController addUserScript:script];
_webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
[_webView loadHTMLString:@"<head></head><imgea src='http://www.nsu.edu.cn/v/2014v3/img/background/3.jpg' />"baseURL:nil];
[self.view addSubview:_webView];
```
5. webView 执行JS代码:
用户调用用JS写过的代码，一般指服务端开发的：
```
//javaScriptString是JS方法名，completionHandler是异步回调block
[self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
```

最后Demo地址：
[WKWebViewdemo](https://github.com/WChunPeng/WKWebView-JS-)  
