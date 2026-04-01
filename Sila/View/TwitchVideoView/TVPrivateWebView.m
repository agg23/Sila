#import "TVPrivateWebView.h"
#import <TargetConditionals.h>

#if TARGET_OS_TV
#import <dlfcn.h>
#import <objc/message.h>

static NSString * const TVPrivateWKWebViewClassName = @"WKWebView";
static NSString * const TVPrivateWKWebViewConfigurationClassName = @"WKWebViewConfiguration";
static NSString * const TVPrivateWKUserContentControllerClassName = @"WKUserContentController";
static NSString * const TVPrivateWKUserScriptClassName = @"WKUserScript";

static void normalizeViewLayout(UIView *view) {
    view.userInteractionEnabled = NO;

    view.clipsToBounds = YES;
    view.layoutMargins = UIEdgeInsetsZero;
    view.preservesSuperviewLayoutMargins = NO;
    if ([view respondsToSelector:@selector(setInsetsLayoutMarginsFromSafeArea:)]) {
        view.insetsLayoutMarginsFromSafeArea = NO;
    }
}

@interface TVPrivateWebView ()

@property (nullable, nonatomic, strong) id runtimeWebView;
@property (nullable, nonatomic, strong) id runtimeConfiguration;
@property (nonatomic, strong) NSMutableSet<NSString *> *installedScriptMessageHandlerNames;
@property (nullable, nonatomic, copy) NSString *currentURLString;
@property (nullable, nonatomic, copy) NSString *titleText;
@property (nonatomic, getter=isRuntimeLoaded) BOOL runtimeLoaded;
@property (nonatomic, getter=isLoading) BOOL loading;
@property (nullable, nonatomic, copy) NSString *lastRuntimePath;

@end

@implementation TVPrivateWebView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.blackColor;
        normalizeViewLayout(self);
        self.installedScriptMessageHandlerNames = [NSMutableSet set];
        [self prepareRuntimeIfNeeded];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIView *runtimeView = (UIView *)self.runtimeWebView;
    runtimeView.frame = self.bounds;
}

- (BOOL)canBecomeFocused {
    return NO;
}

- (BOOL)prepareRuntimeIfNeeded {
    if (NSClassFromString(TVPrivateWKWebViewClassName) != Nil) {
        self.runtimeLoaded = YES;
        return YES;
    }

    NSArray<NSString *> *candidatePaths = @[
        @"/System/Library/Frameworks/WebKit.framework/WebKit",
        @"/System/Library/PrivateFrameworks/WebKit.framework/WebKit",
        @"/System/Library/StagedFrameworks/Safari/WebKit.framework/WebKit",
    ];

    for (NSString *candidatePath in candidatePaths) {
        if (dlopen(candidatePath.UTF8String, RTLD_NOW | RTLD_GLOBAL) != NULL && NSClassFromString(TVPrivateWKWebViewClassName) != Nil) {
            self.runtimeLoaded = YES;
            self.lastRuntimePath = candidatePath;
            return YES;
        }
    }

    self.runtimeLoaded = NO;
    return NO;
}

- (BOOL)createRuntimeWebView {
    if (self.runtimeWebView != nil) {
        return YES;
    }

    if (![self prepareRuntimeIfNeeded]) {
        return NO;
    }

    Class configurationClass = NSClassFromString(TVPrivateWKWebViewConfigurationClassName);
    Class webViewClass = NSClassFromString(TVPrivateWKWebViewClassName);
    Class userContentControllerClass = NSClassFromString(TVPrivateWKUserContentControllerClassName);
    if (configurationClass == Nil || webViewClass == Nil || userContentControllerClass == Nil) {
        return NO;
    }

    id configuration = ((id (*)(id, SEL))objc_msgSend)((id)configurationClass, @selector(new));
    if (configuration == nil) {
        return NO;
    }

    id userContentController = ((id (*)(id, SEL))objc_msgSend)((id)userContentControllerClass, @selector(new));
    if (userContentController != nil) {
        SEL setUserContentControllerSelector = NSSelectorFromString(@"setUserContentController:");
        if ([configuration respondsToSelector:setUserContentControllerSelector]) {
            ((void (*)(id, SEL, id))objc_msgSend)(configuration, setUserContentControllerSelector, userContentController);
        }
    }

    SEL allowsInlineMediaPlaybackSelector = NSSelectorFromString(@"setAllowsInlineMediaPlayback:");
    if ([configuration respondsToSelector:allowsInlineMediaPlaybackSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(configuration, allowsInlineMediaPlaybackSelector, YES);
    }

    SEL mediaTypesSelector = NSSelectorFromString(@"setMediaTypesRequiringUserActionForPlayback:");
    if ([configuration respondsToSelector:mediaTypesSelector]) {
        ((void (*)(id, SEL, NSUInteger))objc_msgSend)(configuration, mediaTypesSelector, 0);
    }

    SEL airPlaySelector = NSSelectorFromString(@"setAllowsAirPlayForMediaPlayback:");
    if ([configuration respondsToSelector:airPlaySelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(configuration, airPlaySelector, YES);
    }

    id webViewObject = ((id (*)(id, SEL))objc_msgSend)((id)webViewClass, @selector(alloc));
    SEL initializer = NSSelectorFromString(@"initWithFrame:configuration:");
    webViewObject = ((id (*)(id, SEL, CGRect, id))objc_msgSend)(webViewObject, initializer, self.bounds, configuration);
    if (webViewObject == nil) {
        return NO;
    }

    self.runtimeConfiguration = configuration;
    self.runtimeWebView = webViewObject;

    UIView *runtimeView = (UIView *)webViewObject;
    runtimeView.frame = self.bounds;
    runtimeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    normalizeViewLayout(runtimeView);

    SEL setOpaqueSelector = NSSelectorFromString(@"setOpaque:");
    if ([webViewObject respondsToSelector:setOpaqueSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(webViewObject, setOpaqueSelector, NO);
    }

    SEL scrollViewSelector = NSSelectorFromString(@"scrollView");
    if ([webViewObject respondsToSelector:scrollViewSelector]) {
        UIScrollView *scrollView = ((id (*)(id, SEL))objc_msgSend)(webViewObject, scrollViewSelector);
        scrollView.backgroundColor = UIColor.clearColor;

        normalizeViewLayout(scrollView);
        scrollView.contentInset = UIEdgeInsetsZero;
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        if ([scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }

        for (UIView *subview in scrollView.subviews) {
            normalizeViewLayout(subview);
        }
    }

    SEL navigationDelegateSelector = NSSelectorFromString(@"setNavigationDelegate:");
    if ([webViewObject respondsToSelector:navigationDelegateSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(webViewObject, navigationDelegateSelector, self);
    }

    SEL uiDelegateSelector = NSSelectorFromString(@"setUIDelegate:");
    if ([webViewObject respondsToSelector:uiDelegateSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(webViewObject, uiDelegateSelector, self);
    }

    [self addSubview:runtimeView];
    return YES;
}

- (void)loadURLString:(NSString *)URLString {
    if (URLString.length == 0) {
        return;
    }

    if (![self createRuntimeWebView]) {
        return;
    }

    NSURL *URL = [NSURL URLWithString:URLString];
    if (URL == nil) {
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    SEL loadRequestSelector = NSSelectorFromString(@"loadRequest:");
    if ([self.runtimeWebView respondsToSelector:loadRequestSelector]) {
        self.currentURLString = URLString;
        ((id (*)(id, SEL, id))objc_msgSend)(self.runtimeWebView, loadRequestSelector, request);
    }
}

- (void)loadHTMLString:(NSString *)HTMLString {
    if (self.runtimeWebView == nil) {
        return;
    }

    SEL selector = NSSelectorFromString(@"loadHTMLString:baseURL:");
    if (![self.runtimeWebView respondsToSelector:selector]) {
        return;
    }

    self.currentURLString = nil;
    ((id (*)(id, SEL, id, id))objc_msgSend)(self.runtimeWebView, selector, HTMLString ?: @"", nil);
}

- (void)reloadPage {
    SEL reloadSelector = NSSelectorFromString(@"reload");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:reloadSelector]) {
        ((void (*)(id, SEL))objc_msgSend)(self.runtimeWebView, reloadSelector);
    }
}

- (void)stopLoadingPage {
    SEL stopLoadingSelector = NSSelectorFromString(@"stopLoading");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:stopLoadingSelector]) {
        ((void (*)(id, SEL))objc_msgSend)(self.runtimeWebView, stopLoadingSelector);
    }
}

- (void)evaluateJavaScript:(NSString *)script completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    if (script.length == 0 || self.runtimeWebView == nil) {
        if (completion != nil) {
            completion(nil, nil);
        }
        return;
    }

    SEL selector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
    if (![self.runtimeWebView respondsToSelector:selector]) {
        if (completion != nil) {
            NSError *error = [NSError errorWithDomain:@"TVPrivateWebView" code:1 userInfo:@{NSLocalizedDescriptionKey: @"evaluateJavaScript:completionHandler: unavailable"}];
            completion(nil, error);
        }
        return;
    }

    ((void (*)(id, SEL, id, id))objc_msgSend)(self.runtimeWebView, selector, script, completion);
}

- (void)addUserScript:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly {
    if (source.length == 0) {
        return;
    }

    if (![self createRuntimeWebView]) {
        return;
    }

    Class userScriptClass = NSClassFromString(TVPrivateWKUserScriptClassName);
    if (userScriptClass == Nil || self.runtimeConfiguration == nil) {
        return;
    }

    SEL userContentControllerSelector = NSSelectorFromString(@"userContentController");
    if (![self.runtimeConfiguration respondsToSelector:userContentControllerSelector]) {
        return;
    }

    id userContentController = ((id (*)(id, SEL))objc_msgSend)(self.runtimeConfiguration, userContentControllerSelector);
    if (userContentController == nil) {
        return;
    }

    SEL initializer = NSSelectorFromString(@"initWithSource:injectionTime:forMainFrameOnly:");
    if (![userScriptClass instancesRespondToSelector:initializer]) {
        return;
    }

    id userScript = ((id (*)(id, SEL))objc_msgSend)((id)userScriptClass, @selector(alloc));
    userScript = ((id (*)(id, SEL, id, NSInteger, BOOL))objc_msgSend)(userScript, initializer, source, injectionTime, forMainFrameOnly);
    if (userScript == nil) {
        return;
    }

    SEL addUserScriptSelector = NSSelectorFromString(@"addUserScript:");
    if ([userContentController respondsToSelector:addUserScriptSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(userContentController, addUserScriptSelector, userScript);
    }
}

- (void)removeAllUserScripts {
    SEL userContentControllerSelector = NSSelectorFromString(@"userContentController");
    if (self.runtimeConfiguration == nil || ![self.runtimeConfiguration respondsToSelector:userContentControllerSelector]) {
        return;
    }

    id userContentController = ((id (*)(id, SEL))objc_msgSend)(self.runtimeConfiguration, userContentControllerSelector);
    if (userContentController == nil) {
        return;
    }

    SEL removeAllUserScriptsSelector = NSSelectorFromString(@"removeAllUserScripts");
    if ([userContentController respondsToSelector:removeAllUserScriptsSelector]) {
        ((void (*)(id, SEL))objc_msgSend)(userContentController, removeAllUserScriptsSelector);
    }
}

- (BOOL)installScriptMessageHandlerNamed:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }

    if ([self.installedScriptMessageHandlerNames containsObject:name]) {
        return YES;
    }

    if (![self createRuntimeWebView]) {
        return NO;
    }

    SEL userContentControllerSelector = NSSelectorFromString(@"userContentController");
    if (![self.runtimeConfiguration respondsToSelector:userContentControllerSelector]) {
        return NO;
    }

    id userContentController = ((id (*)(id, SEL))objc_msgSend)(self.runtimeConfiguration, userContentControllerSelector);
    if (userContentController == nil) {
        return NO;
    }

    SEL addHandlerSelector = NSSelectorFromString(@"addScriptMessageHandler:name:");
    if (![userContentController respondsToSelector:addHandlerSelector]) {
        return NO;
    }

    [self removeScriptMessageHandlerNamed:name];
    ((void (*)(id, SEL, id, id))objc_msgSend)(userContentController, addHandlerSelector, self, name);
    [self.installedScriptMessageHandlerNames addObject:name];
    return YES;
}

- (void)removeScriptMessageHandlerNamed:(NSString *)name {
    if (name.length == 0) {
        return;
    }

    SEL userContentControllerSelector = NSSelectorFromString(@"userContentController");
    if (self.runtimeConfiguration == nil || ![self.runtimeConfiguration respondsToSelector:userContentControllerSelector]) {
        [self.installedScriptMessageHandlerNames removeObject:name];
        return;
    }

    id userContentController = ((id (*)(id, SEL))objc_msgSend)(self.runtimeConfiguration, userContentControllerSelector);
    if (userContentController == nil) {
        [self.installedScriptMessageHandlerNames removeObject:name];
        return;
    }

    SEL removeHandlerSelector = NSSelectorFromString(@"removeScriptMessageHandlerForName:");
    if ([userContentController respondsToSelector:removeHandlerSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(userContentController, removeHandlerSelector, name);
    }

    [self.installedScriptMessageHandlerNames removeObject:name];
}

- (void)webView:(id)webView didStartProvisionalNavigation:(id)navigation {
    self.loading = YES;
    if ([self.delegate respondsToSelector:@selector(privateWebViewDidStartLoad:)]) {
        [self.delegate privateWebViewDidStartLoad:self];
    }
}

- (void)webView:(id)webView didFinishNavigation:(id)navigation {
    self.loading = NO;

    SEL urlSelector = NSSelectorFromString(@"URL");
    if ([webView respondsToSelector:urlSelector]) {
        NSURL *URL = ((id (*)(id, SEL))objc_msgSend)(webView, urlSelector);
        self.currentURLString = URL.absoluteString;
    }

    SEL titleSelector = NSSelectorFromString(@"title");
    if ([webView respondsToSelector:titleSelector]) {
        NSString *title = ((id (*)(id, SEL))objc_msgSend)(webView, titleSelector);
        self.titleText = title;
    }

    if ([self.delegate respondsToSelector:@selector(privateWebViewDidFinishLoad:)]) {
        [self.delegate privateWebViewDidFinishLoad:self];
    }
}

- (void)webView:(id)webView didFailNavigation:(id)navigation withError:(NSError *)error {
    self.loading = NO;
    if ([self.delegate respondsToSelector:@selector(privateWebView:didFailLoadWithError:)]) {
        [self.delegate privateWebView:self didFailLoadWithError:error];
    }
}

- (void)webView:(id)webView didFailProvisionalNavigation:(id)navigation withError:(NSError *)error {
    self.loading = NO;
    if ([self.delegate respondsToSelector:@selector(privateWebView:didFailLoadWithError:)]) {
        [self.delegate privateWebView:self didFailLoadWithError:error];
    }
}

- (void)userContentController:(id)userContentController didReceiveScriptMessage:(id)message {
    SEL bodySelector = NSSelectorFromString(@"body");
    if (![message respondsToSelector:bodySelector]) {
        return;
    }

    id body = ((id (*)(id, SEL))objc_msgSend)(message, bodySelector);
    if ([self.delegate respondsToSelector:@selector(privateWebView:didReceiveScriptMessageBody:)]) {
        [self.delegate privateWebView:self didReceiveScriptMessageBody:body];
    }
}

@end
#endif
