#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface RCCManager : NSObject

@property (nonatomic, strong) NSURL *bundleURL;

+ (instancetype)sharedInstance;
+ (instancetype)sharedIntance;

-(void)initBridgeWithBundleURL:(NSURL *)bundleURL launchOptions:(NSDictionary *)launchOptions;
-(RCTBridge*)getBridge;

-(void)registerController:(UIViewController*)controller componentId:(NSString*)componentId componentType:(NSString*)componentType;
-(id)getControllerWithId:(NSString*)componentId componentType:(NSString*)componentType;
-(void)unregisterController:(UIViewController*)vc;

-(void)clearModuleRegistry;

@end
