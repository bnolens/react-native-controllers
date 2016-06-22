#import "RCCNavigationController.h"
#import "RCCViewController.h"
#import "RCCManager.h"
#import "RCTEventDispatcher.h"
#import "RCTConvert.h"

@interface RCCNavigationController()

@property (strong, nonatomic) UIView *navigationBackground;

@end

@implementation RCCNavigationController

NSString const *CALLBACK_ASSOCIATED_KEY = @"RCCNavigationController.CALLBACK_ASSOCIATED_KEY";
NSString const *CALLBACK_ASSOCIATED_ID = @"RCCNavigationController.CALLBACK_ASSOCIATED_ID";

- (instancetype)initWithProps:(NSDictionary *)props children:(NSArray *)children globalProps:(NSDictionary*)globalProps bridge:(RCTBridge *)bridge
{
  NSString *component = props[@"component"];
  if (!component) return nil;
  
  NSDictionary *passProps = props[@"passProps"];
  NSDictionary *navigatorStyle = props[@"style"];
  
  RCCViewController *viewController = [[RCCViewController alloc] initWithComponent:component passProps:passProps navigatorStyle:navigatorStyle globalProps:globalProps bridge:bridge];
  if (!viewController) return nil;
  
  NSString *title = props[@"title"];
  if (title) viewController.title = title;
  
  [self setTitleIamgeForVC:viewController titleImageData:props[@"titleImage"]];
  
  NSArray *leftButtons = props[@"leftButtons"];
  if (leftButtons)
  {
    [self setButtons:leftButtons viewController:viewController side:@"left" animated:NO];
  }
  
  NSArray *rightButtons = props[@"rightButtons"];
  if (rightButtons)
  {
    [self setButtons:rightButtons viewController:viewController side:@"right" animated:NO];
  }
  
  self = [super initWithRootViewController:viewController];
  if (!self) return nil;
  
  self.navigationBar.translucent = NO; // default
  
  [self initCustomNavigationBarStyle];
  
  return self;
}

- (void) initCustomNavigationBarStyle {
  
  // Gradient background
  CAGradientLayer *gradient = [CAGradientLayer layer];
  gradient.frame = CGRectMake(0, -32, self.navigationBar.bounds.size.width, self.navigationBar.bounds.size.height+32);
  gradient.colors = @[(id)[UIColor colorWithRed:201.f/255.f green:17.f/255.f blue:0.f/255.f alpha:.7f].CGColor,
                      (id)[UIColor colorWithRed:116.f/255.f green:0.f/255.f blue:96.f/255.f alpha:.7f].CGColor];
  gradient.startPoint = CGPointMake(0.0, 0.5);
  gradient.endPoint = CGPointMake(1.0, 0.5);
  
  self.navigationBackground = [[UIView alloc] initWithFrame:gradient.bounds];
  [self.navigationBackground.layer addSublayer:gradient];
  
  [self.navigationBar.layer insertSublayer:self.navigationBackground.layer atIndex:(unsigned int)self.navigationBar.layer.sublayers.count-1];
  
  UIImage *titleImage = [UIImage imageNamed:@"nav-logo"];
  UIImageView *imageView = [[UIImageView alloc] initWithImage:titleImage];
  imageView.contentMode = UIViewContentModeScaleAspectFit;
  imageView.frame = CGRectMake(ceil((self.navigationBar.frame.size.width/2.f)-(130.f/2.f)), ceil((self.navigationBar.frame.size.height/2.f)-(13.f/2.f)), 130.f, 13.f);
  
  [self.navigationBar.layer insertSublayer:imageView.layer above:self.navigationBackground.layer];
}

- (void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  if(self.navigationBackground) {
    self.navigationBackground.frame = CGRectMake(0, 0, self.navigationBar.bounds.size.width, self.navigationBar.bounds.size.height);
  }
}

- (void)performAction:(NSString*)performAction actionParams:(NSDictionary*)actionParams bridge:(RCTBridge *)bridge
{
  BOOL animated = actionParams[@"animated"] ? [actionParams[@"animated"] boolValue] : YES;
  
  // push
  if ([performAction isEqualToString:@"push"])
  {
    NSString *component = actionParams[@"component"];
    if (!component) return;
    
    NSDictionary *passProps = actionParams[@"passProps"];
    NSDictionary *navigatorStyle = actionParams[@"style"];
    
    // merge the navigatorStyle of our parent
    if ([self.topViewController isKindOfClass:[RCCViewController class]])
    {
      RCCViewController *parent = (RCCViewController*)self.topViewController;
      NSMutableDictionary *mergedStyle = [NSMutableDictionary dictionaryWithDictionary:parent.navigatorStyle];
      
      // there are a few styles that we don't want to remember from our parent (they should be local)
      [mergedStyle removeObjectForKey:@"navBarHidden"];
      [mergedStyle removeObjectForKey:@"statusBarHidden"];
      [mergedStyle removeObjectForKey:@"navBarHideOnScroll"];
      [mergedStyle removeObjectForKey:@"drawUnderNavBar"];
      [mergedStyle removeObjectForKey:@"drawUnderTabBar"];
      [mergedStyle removeObjectForKey:@"statusBarBlur"];
      [mergedStyle removeObjectForKey:@"navBarBlur"];
      [mergedStyle removeObjectForKey:@"navBarTranslucent"];
      [mergedStyle removeObjectForKey:@"statusBarHideWithNavBar"];
      
      [mergedStyle addEntriesFromDictionary:navigatorStyle];
      navigatorStyle = mergedStyle;
    }
    
    RCCViewController *viewController = [[RCCViewController alloc] initWithComponent:component passProps:passProps navigatorStyle:navigatorStyle globalProps:nil bridge:bridge];
    
    NSString *title = actionParams[@"title"];
    if (title) viewController.title = title;
    
    [self setTitleIamgeForVC:viewController titleImageData:actionParams[@"titleImage"]];
    
    NSString *backButtonTitle = actionParams[@"backButtonTitle"];
    if (backButtonTitle)
    {
      UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
      
      self.topViewController.navigationItem.backBarButtonItem = backItem;
    }
    else
    {
      self.topViewController.navigationItem.backBarButtonItem = nil;
    }
    
    NSNumber *backButtonHidden = actionParams[@"backButtonHidden"];
    BOOL backButtonHiddenBool = backButtonHidden ? [backButtonHidden boolValue] : NO;
    if (backButtonHiddenBool)
    {
      viewController.navigationItem.hidesBackButton = YES;
    }
    
    NSArray *leftButtons = actionParams[@"leftButtons"];
    if (leftButtons)
    {
      [self setButtons:leftButtons viewController:viewController side:@"left" animated:NO];
    }
    
    NSArray *rightButtons = actionParams[@"rightButtons"];
    if (rightButtons)
    {
      [self setButtons:rightButtons viewController:viewController side:@"right" animated:NO];
    }
    
    [self pushViewController:viewController animated:animated];
    return;
  }
  
  // pop
  if ([performAction isEqualToString:@"pop"])
  {
    [self popViewControllerAnimated:animated];
    return;
  }
  
  // popToRoot
  if ([performAction isEqualToString:@"popToRoot"])
  {
    [self popToRootViewControllerAnimated:animated];
    return;
  }
  
  // resetTo
  if ([performAction isEqualToString:@"resetTo"])
  {
    NSString *component = actionParams[@"component"];
    if (!component) return;
    
    NSDictionary *passProps = actionParams[@"passProps"];
    NSDictionary *navigatorStyle = actionParams[@"style"];
    
    RCCViewController *viewController = [[RCCViewController alloc] initWithComponent:component passProps:passProps navigatorStyle:navigatorStyle globalProps:nil bridge:bridge];
    
    NSString *title = actionParams[@"title"];
    if (title) viewController.title = title;
    
    [self setTitleIamgeForVC:viewController titleImageData:actionParams[@"titleImage"]];
    
    NSArray *leftButtons = actionParams[@"leftButtons"];
    if (leftButtons)
    {
      [self setButtons:leftButtons viewController:viewController side:@"left" animated:NO];
    }
    
    NSArray *rightButtons = actionParams[@"rightButtons"];
    if (rightButtons)
    {
      [self setButtons:rightButtons viewController:viewController side:@"right" animated:NO];
    }
    
    BOOL animated = actionParams[@"animated"] ? [actionParams[@"animated"] boolValue] : YES;
    
    [self setViewControllers:@[viewController] animated:animated];
    return;
  }
  
  // setButtons
  if ([performAction isEqualToString:@"setButtons"])
  {
    NSArray *buttons = actionParams[@"buttons"];
    BOOL animated = actionParams[@"animated"] ? [actionParams[@"animated"] boolValue] : YES;
    NSString *side = actionParams[@"side"] ? actionParams[@"side"] : @"left";
    
    [self setButtons:buttons viewController:self.topViewController side:side animated:animated];
    return;
  }
  
  // setTitle
  if ([performAction isEqualToString:@"setTitle"])
  {
    NSString *title = actionParams[@"title"];
    if (title) self.topViewController.title = title;
    return;
  }
  
  if ([performAction isEqualToString:@"setTitleImage"])
  {
    [self setTitleIamgeForVC:self.topViewController titleImageData:actionParams[@"titleImage"]];
    return;
  }
  
  // toggleNavBar
  if ([performAction isEqualToString:@"setHidden"]) {
    NSNumber *animated = actionParams[@"animated"];
    BOOL animatedBool = animated ? [animated boolValue] : YES;
    
    NSNumber *setHidden = actionParams[@"hidden"];
    BOOL isHiddenBool = setHidden ? [setHidden boolValue] : NO;
  
    RCCViewController *topViewController = ((RCCViewController*)self.topViewController);
    topViewController.navigatorStyle[@"navBarHidden"] = setHidden;
    [topViewController setNavBarVisibilityChange:animatedBool];
    
    }
}

-(void)onButtonPress:(UIBarButtonItem*)barButtonItem
{
  NSString *callbackId = objc_getAssociatedObject(barButtonItem, &CALLBACK_ASSOCIATED_KEY);
  if (!callbackId) return;
  NSString *buttonId = objc_getAssociatedObject(barButtonItem, &CALLBACK_ASSOCIATED_ID);
  [[[RCCManager sharedInstance] getBridge].eventDispatcher sendAppEventWithName:callbackId body:@
   {
     @"type": @"NavBarButtonPress",
     @"id": buttonId ? buttonId : [NSNull null]
   }];
}

-(void)setButtons:(NSArray*)buttons viewController:(UIViewController*)viewController side:(NSString*)side animated:(BOOL)animated
{
  NSMutableArray *barButtonItems = [NSMutableArray new];
  for (NSDictionary *button in buttons)
  {
    NSString *title = button[@"title"];
    UIImage *iconImage = nil;
    id icon = button[@"icon"];
    if (icon) iconImage = [RCTConvert UIImage:icon];
    
    UIBarButtonItem *barButtonItem;
    if (iconImage)
    {
      barButtonItem = [[UIBarButtonItem alloc] initWithImage:iconImage style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPress:)];
    }
    else if (title)
    {
      barButtonItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(onButtonPress:)];
      [barButtonItem setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:12],
                                              NSForegroundColorAttributeName: [UIColor whiteColor]
                                              } forState:UIControlStateNormal];
    }
    else continue;
    objc_setAssociatedObject(barButtonItem, &CALLBACK_ASSOCIATED_KEY, button[@"onPress"], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [barButtonItems addObject:barButtonItem];
    
    NSString *buttonId = button[@"id"];
    if (buttonId)
    {
      objc_setAssociatedObject(barButtonItem, &CALLBACK_ASSOCIATED_ID, buttonId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSNumber *disabled = button[@"disabled"];
    BOOL disabledBool = disabled ? [disabled boolValue] : NO;
    if (disabledBool) {
      [barButtonItem setEnabled:NO];
    }
    
    NSString *testID = button[@"testID"];
    if (testID)
    {
      barButtonItem.accessibilityIdentifier = testID;
    }
  }
  
  if ([side isEqualToString:@"left"])
  {
    [viewController.navigationItem setLeftBarButtonItems:barButtonItems animated:animated];
  }
  
  if ([side isEqualToString:@"right"])
  {
    [viewController.navigationItem setRightBarButtonItems:barButtonItems animated:animated];
  }
}

-(void)setTitleIamgeForVC:(UIViewController*)viewController titleImageData:(id)titleImageData
{
  if (!titleImageData || [titleImageData isEqual:[NSNull null]])
  {
    viewController.navigationItem.titleView = nil;
    return;
  }
  
  UIImage *titleImage = [RCTConvert UIImage:titleImageData];
  if (titleImage)
  {
    viewController.navigationItem.titleView = [[UIImageView alloc] initWithImage:titleImage];
  }
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [self.topViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  if (self.topViewController) {
    return [self.topViewController supportedInterfaceOrientations];
  }
  
  return UIInterfaceOrientationMaskPortrait;
}

-(BOOL)shouldAutorotate
{
  if (self.topViewController) {
    return [self.topViewController shouldAutorotate];
  }
  return NO;
}

@end
