//
//  iOSWKWebViewController .m
//
//
//  Created by foolsparadise on 10/10/17.
//  Copyright © 2016 github.com/foolsparadise All rights reserved.
//

#import "iOSWKWebViewController.h"

#import <WebKit/WebKit.h>
#import "FBKVOController.h"
#import "Masonry.h"
#import "MJRefresh.h"

#ifndef __OPTIMIZE__
#if 1 //NSLog 1 open or 0 close
#define NSLog(FORMAT,...)   NSLog(@"(%@)line(%d):(%@)",[[[NSString stringWithFormat:@"%s",__FILE__] componentsSeparatedByString:@"/"] lastObject], __LINE__,[NSString stringWithFormat:FORMAT, ##__VA_ARGS__])
#else
#define NSLog(...) {}
#endif
#else
#define NSLog(...) {}
#endif

#ifdef DEBUG
#define iOSLog(...)      NSLog(__VA_ARGS__)
#define iOSLogMethod()   NSlog(@"%s", __func__)
#define iOSLogPoint(p)   NSLog(@"%f,%f", p.x, p.y);
#define iOSLogSize(p)    NSLog(@"%f,%f", p.width, p.height);
#define iOSLogRect(p)    NSLog(@"%f,%f %f,%f", p.origin.x, p.origin.y, p.size.width, p.size.height);

#else
#define iOSLog(...)      {}
#define iOSLogMethod()   {}
#define iOSLogPoint(p)   {}
#define iOSLogSize(p)    {}
#define iOSLogRect(p)    {}
#endif

@interface iOSWKWebViewController () {

    UIActivityIndicatorView *   _activityIndicatorView;
    UIView *                    _topHUD;
    UIToolbar *                 _topBar;

}

@property (nonatomic, strong) WKWebView *           webView;
@property (nonatomic, strong) FBKVOController *     webKVOController;
@property (nonatomic, strong) UIView *              webProgressView;
@property (nonatomic, strong) CALayer *             webProgressLayer;


@end

@implementation iOSWKWebViewController

#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    CGRect bounds = [UIScreen mainScreen].bounds;
    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;
    CGFloat topH = 50;
    CGFloat botH = 50;
    __weak typeof(self)_weakSelf = self;
    //AutoLayout
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;

    //旋转进度
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.center = self.view.center;
    _activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:_activityIndicatorView];
    //UIToolbar：导航控制器默认隐藏的工具条
    _topHUD    = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    _topBar    = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, width, topH)];
    _topBar.tintColor = [UIColor blackColor];
    _topHUD.frame = CGRectMake(0,0,width,_topBar.frame.size.height);
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _topBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topBar];
    [self.view addSubview:_topHUD];
    //导航控制器左侧
    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    /* width为负数时，相当于btn向右移动width数值个像素，由于按钮本身和  边界间距为5pix，所以width设为-5时，间距正好调整为0；width为正数 时，正好相反，相当于往左移动width数值个像素 */
    leftSpace.width = -5;
    UIBarButtonItem *leftBackBtn = [[UIBarButtonItem alloc] initWithTitle:@"上一页" style:UIBarButtonItemStylePlain target:self action:@selector(navBackBtn)];
    UIBarButtonItem *leftCloseBtn = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(navCloseBtn)];
    [self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:leftSpace, leftBackBtn, leftCloseBtn, nil]];
    //导航控制器右侧
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    /* width为负数时，相当于btn向右移动width数值个像素，由于按钮本身和  边界间距为5pix，所以width设为-5时，间距正好调整为0；width为正数 时，正好相反，相当于往左移动width数值个像素 */
    rightSpace.width = -5;
    UIBarButtonItem *rightCloseBtn = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(navCloseBtn)];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:rightSpace, rightCloseBtn, nil]];
    //导航控制器两侧的按钮颜色
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    //显示旋转进度
    self.view.backgroundColor = [UIColor blackColor]; //为了下一行的view能显示出来
    [_activityIndicatorView startAnimating];
    //WKWebView
    _webView = [[WKWebView alloc] init];
    [self.view addSubview:_webView];
    UIEdgeInsets padding = UIEdgeInsetsMake(1, 1, 1, 1);
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_weakSelf.view).with.insets(padding);
    }];
    //下拉刷新
    MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(reloadThisWeb)];
    _webView.scrollView.mj_header = header;

    //WKWebView可订制的背景色
    //    NSString *source = @"document.body.style.background = \"#FFFFFF\";";
    //    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:true];
    //    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    //    [userContentController addUserScript:userScript];
    //    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    //    configuration.userContentController = userContentController;
    //    //configuration.allowsInlineMediaPlayback = YES;

    //WKWebView加载状态进度条
    _webProgressView = [[UIView alloc] init];
    _webProgressView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_webProgressView];
    [_webProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(0);
        make.right.equalTo(self.view.mas_right).offset(0);
        make.top.equalTo(self.view.mas_top).offset(0);
        make.bottom.equalTo(self.view.mas_top).offset(10);
        //可以使用链式语法

    }];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, 0, 10);
    layer.backgroundColor = [UIColor blueColor].CGColor;
    [_webProgressView.layer addSublayer:layer];
    _webProgressLayer = layer;

    _webKVOController = [FBKVOController controllerWithObserver:self]; //初始化KVO
    //WKWebView kvo 加载状态进度条
    [_webKVOController observe:_webView keyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        float procesCountO =  [change[NSKeyValueChangeOldKey] floatValue];
        float procesCountN =  [change[NSKeyValueChangeNewKey] floatValue];
        iOSLog(@"Old process(%f)New(%f)", procesCountO, procesCountN);
        _weakSelf.webProgressLayer.opacity = 1;
        if (procesCountN < procesCountO) {
            return;
        }
        _weakSelf.webProgressLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width * procesCountN, 3);
        if (procesCountN == 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _weakSelf.webProgressLayer.opacity = 0;
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _weakSelf.webProgressLayer.frame = CGRectMake(0, 0, 0, 10);
            });
        }

    }];
    //WKWebView kvo title
    [_webKVOController observe:_webView keyPath:@"title" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        NSString *titleO = [NSString stringWithFormat:@"%@", change[NSKeyValueChangeOldKey]];
        NSString *titleN = [NSString stringWithFormat:@"%@", change[NSKeyValueChangeNewKey]];
        iOSLog(@"Old title(%@)New(%@)", titleO, titleN);
        _weakSelf.title = titleN;
        if(titleN.length>0) {
            [_weakSelf checkHTMLPageSource];
        }

    }];


    //demo
    NSArray* path= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirector= [path objectAtIndex:0];
//    _webURLstring = @"https://iOS.github.io"; //URL
//    _webURLstring = [NSString stringWithFormat:@"%@/test.txt", documentsDirector]; //沙盒文件
    iOSLog(@"%@ %@", _webURLstring, documentsDirector);

    //加载web
    [self wkwebViewLoadURL:_webURLstring];

}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    _webKVOController = nil; //清KVO

}
-(void)navBackBtn
{
    if(_webView.canGoBack)
        [_webView goBack];
    else
        [self.navigationController popViewControllerAnimated:YES];
}
-(void)navCloseBtn
{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - 加载web
-(void)wkwebViewLoadURL : (NSString *)urlINstring {
    NSURL *url = [NSURL URLWithString:urlINstring];
    if ([urlINstring hasPrefix:@"/var/"] || [urlINstring hasPrefix:@"/Users/"]) { //沙盒文件
        url = [NSURL fileURLWithPath:urlINstring]; //沙盒文件
        if ([self getFileSize:urlINstring] <= 0 ) {
            iOSLog(@"file Size 0 at %@", urlINstring);
            [self popAlertControllerWithMsg:[self localizedStringForKey:@"文件大小为零,无法显示"]];
            return;
        }

    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityIndicatorView startAnimating];

    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        NSData* Data = [NSData dataWithContentsOfURL:url];
        NSString* oneStr = [[NSString alloc] initWithData:Data encoding:NSUTF8StringEncoding];
        if (!oneStr) {
            oneStr=[[NSString alloc] initWithData:Data encoding:0x80000632];
        }
        if (!oneStr) {
            oneStr=[[NSString alloc] initWithData:Data encoding:0x80000631];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if(oneStr && oneStr.length>0) { //文本文件
                NSString* responseStr = [NSString stringWithFormat:
                                         @"<HTML>"
                                         "<head>"
                                         "<title></title>"
                                         "</head>"
                                         "<BODY width=%fpx style=\"word-wrap:break-word; font-family:Arial\">" //自动换行,等等,兼容Ｗin,Mac各文本类型换行格式
                                         "<pre>"
                                         "%@"
                                         "</pre>"
                                         "</BODY>"
                                         "</HTML>",
                                         self.view.frame.size.width,
                                         oneStr];
                [_webView loadHTMLString:responseStr baseURL:url];
                [self.view addSubview:_webView];
                [_activityIndicatorView stopAnimating];
                return;
            }
            else if ([urlINstring hasPrefix:@"/var/"] || [urlINstring hasPrefix:@"/Users/"]) { //沙盒文件
                if ([self getFileSize:urlINstring] <= 0 ) {
                    iOSLog(@"file Size 0 at %@", urlINstring);
                    [self popAlertControllerWithMsg:[self localizedStringForKey:@"文件大小为零,无法显示"]];
                    return;
                }

                NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL fileURLWithPath:urlINstring]];
                [_webView loadRequest:request];
                [self.view addSubview:_webView];
                [_activityIndicatorView stopAnimating];

            }
            else { //在线文档
                NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:urlINstring]];
                [_webView loadRequest:request];
                [self.view addSubview:_webView];
                [_activityIndicatorView stopAnimating];

            }

        });
    });

}

#pragma mark - 重新加载此 WKWebView
-(void)reloadThisWeb {
    [_webView.scrollView.mj_header endRefreshing];
    [UIView animateWithDuration:0.1 animations:^{
        //        [_webView reload]; //此处对特殊编码的文本，直接使用，会有乱码
        //        CGRect frame = self.view.frame;
        //        frame.origin.y = 64;
        //        self.view.frame = frame;
        [self wkwebViewLoadURL:_webURLstring];
        UIEdgeInsets padding = UIEdgeInsetsMake(1, 1, 1, 1);
        [_webView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).with.insets(padding);
        }];
    }];
}

#pragma mark - 如有必要，检查网页源代码
-(void)checkHTMLPageSource {
    // current HTML s URL,title 当前HTML
    iOSLog(@"URL(%@)title(%@)", _webView.URL, _webView.title);

    //Page Source 当前HTML的源码
    [_webView evaluateJavaScript:@"document.getElementsByTagName('html')[0].innerHTML" completionHandler:^(id res, NSError * _Nullable error) {
        NSString *srcode = [NSString stringWithFormat:@"%@", res];
        iOSLog(@"%@", srcode);

    }];

    //    // go back all HTML s URL,title in history 后退历史中的所有HTML
    //    WKBackForwardList *backList = _webView.backForwardList;
    //    NSArray *listback = backList.backList;
    //    for (WKBackForwardListItem *item in listback) {
    //        iOSLog(@"%@ %@ %@", item.initialURL, item.title, item.URL);
    //
    //    }

    //    // go back HTML s URL,title in history 后退一下历史中的HTML
    //    WKBackForwardListItem *itemback = backList.backItem;
    //    iOSLog(@"%@ %@ %@", itemback.initialURL, itemback.title, itemback.URL);

    //    // current HTML s URL,title 当前HTML
    //    WKBackForwardListItem *itemcurrent = backList.currentItem;
    //    iOSLog(@"%@ %@ %@", itemcurrent.initialURL, itemcurrent.title, itemcurrent.URL);

}

#pragma mark - 弹个框，有个确定，点了就消失
-(void)popAlertControllerWithMsg:(NSString *)alertMsg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[self localizedStringForKey:@"确定"]  style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:cancelAction];
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 此方法可以获取文件的大小，返回的是单位是Byte
-(unsigned long long )getFileSize:(NSString *)path {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    unsigned long long  filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil]; //获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size;
    }
    return filesize;
}

#pragma mark - 自取翻译
- (NSString *)localizedStringForKey:(NSString *)key{
    return [self localizedStringForKey:key withDefault:nil];
}
- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
    static NSBundle *bundle = nil;
    if (bundle == nil)
    {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iOSWKWebViewController" ofType:@"bundle"];

        bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *language = [[NSLocale preferredLanguages] count]? [NSLocale preferredLanguages][0]: @"en";
        if (![[bundle localizations] containsObject:language])
        {
            language = [language componentsSeparatedByString:@"-"][0];
        }
        if ([[bundle localizations] containsObject:language])
        {
            bundlePath = [bundle pathForResource:language ofType:@"lproj"];
        }

        bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
    }
    defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
