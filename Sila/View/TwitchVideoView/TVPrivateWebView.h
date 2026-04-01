#import <TargetConditionals.h>

#if TARGET_OS_TV
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TVPrivateWebViewNavigationDelegate <NSObject>

@optional
- (void)privateWebViewDidStartLoad:(id)webView;
- (void)privateWebViewDidFinishLoad:(id)webView;
- (void)privateWebView:(id)webView didFailLoadWithError:(NSError *)error;
- (void)privateWebView:(id)webView didReceiveScriptMessageBody:(id)body;

@end

@interface TVPrivateWebView : UIView

@property (nullable, nonatomic, weak) id<TVPrivateWebViewNavigationDelegate> delegate;
@property (nullable, nonatomic, readonly, copy) NSString *currentURLString;
@property (nullable, nonatomic, readonly, copy) NSString *titleText;
@property (nonatomic, readonly, getter=isRuntimeLoaded) BOOL runtimeLoaded;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;
@property (nullable, nonatomic, readonly, copy) NSString *lastRuntimePath;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)prepareRuntimeIfNeeded;
- (BOOL)createRuntimeWebView;

- (void)loadURLString:(NSString *)URLString;
- (void)loadHTMLString:(NSString *)HTMLString;
- (void)reloadPage;
- (void)stopLoadingPage;
- (void)evaluateJavaScript:(NSString *)script completion:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))completion;
- (void)addUserScript:(NSString *)source injectionTime:(NSInteger)injectionTime forMainFrameOnly:(BOOL)forMainFrameOnly;
- (void)removeAllUserScripts;
- (BOOL)installScriptMessageHandlerNamed:(NSString *)name;
- (void)removeScriptMessageHandlerNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
#endif
