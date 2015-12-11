# React Native Controllers

`react-native-controllers` is a [React Native](https://facebook.github.io/react-native/) extension package for for iOS which aims to provide a completely native skeleton to iOS apps. Skeleton components such as [`UINavigatorController`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UINavigationController_Class/) or a [side menu drawer](https://www.cocoacontrols.com/search?q=drawer) are traditionally challenging to wrap natively with React Native. `react-native-controllers` simplifies this by re-introducing [`UIViewController`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewController_Class/index.html) into the React Native stack.

> Note: The main purpose of this package is to generate discussion around difficulties we found wrapping native iOS skeleton components with React Native. Look at this as a thought experiment with a proposed solution. If you have alternate ideas please share your feedback!

## Why do we need this package?

If you're already convinced you need this package, you can skip straight to [Installation](#installation).

## Installation

You need an iOS React Native project ([instructions on how to create one](https://facebook.github.io/react-native/docs/getting-started.html#quick-start))

1. Run `npm install react-native-controllers` in your project root
2. In XCode, in Project Navigator (left pane), right-click on the `Libraries` > `Add files to [project name]` <br> Add `./node_modules/react-native-controllers/ios/ReactNativeControllers.xcodeproj` ([screenshots](https://facebook.github.io/react-native/docs/linking-libraries-ios.html#step-1))
3. In XCode, in Project Navigator (left pane), click on your project (top) and select the `Build Phases` tab (right pane) <br> In the `Link Binary With Libraries` section add `libReactNativeControllers.a` ([screenshots](https://facebook.github.io/react-native/docs/linking-libraries-ios.html#step-2))
4. In XCode, in Project Navigator (left pane), click on your project (top) and select the `Build Settings` tab (right pane) <br> In the `Header Search Paths` section add `$(SRCROOT)/../node_modules/react-native-controllers/ios` <br> Make sure on the right to mark this new path `recursive` ([screenshots](https://facebook.github.io/react-native/docs/linking-libraries-ios.html#step-3))

## Usage

Check out the iOS example project under [`./example`](example) to see everything in action.

### Step 1 - Update AppDelegate

Since `react-native-controllers` takes over the skeleton of your app, we're first going to change how React Native is invoked in `AppDelegate.m`. In XCode, change your AppDelegate to look like this:

```objc
#import "AppDelegate.h"
#import "RCCManager.h" // RCC stands for ReaCtControllers

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSURL *jsCodeLocation;

  // OPTION 1 - load JS code from development server
  jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];

  // OPTION 2 - load JS from pre-bundled file on disk
  // jsCodeLocation = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  
  // this is your new React Native invokation
  [[RCCManager sharedIntance] initBridgeWithBundleURL:jsCodeLocation];
  
  return YES;
}

@end
```

### Step 2 - Update index.ios.js

With React Native, every JS file in your project is a module. With `react-native-controllers`, you can have JS modules that deal with `ViewControllers` and you can have JS modules that deal with `Views` (these are the React Native modules that you're used to). It's not recommended to deal with both in the same JS module.

Roughly speaking, `ViewControllers` make the skeleton of your app and `Views` make the actual content of every screen. Since `index.ios.js` is where your skeleton is defined, this module will be dedicated to deal with `ViewControllers`. Normally, this would be the only module that does that and the rest of your JS files will be regular React Native files.

You can see a complete example of `index.ios.js` [here](example/index.ios.js). If you don't want the full explanation of what's going on in there, just skip to the next step.

#### Making a module deal with ViewControllers instead of Views

To allow you to use [JSX](https://facebook.github.io/react/docs/jsx-in-depth.html) to define your view controller hierarchy, we're going to have to hijack `React`. Don't worry, this hijack is local to this module only. That's why we don't mix the two types. Your other regular JS modules (that deal with Views) won't have this hijack.

To perform the hijack, define `React` on the top of the module like this:

```js
var Controllers = require('react-native-controllers');
var React = Controllers.hijackReact();
```

> Note: The React instance here is irregular. It can't do many of the things that the original class can, so keep its usage pretty close to our purpose.

#### Defining the view controller hierarchy

We tried to keep the syntax familiar. Define your view controller skeleton like this:

```jsx
var MoviesApp = Controllers.createClass({
  render: function() {
    return (
      <DrawerControllerIOS id="drawer" componentLeft="SideMenu" componentRight="SideMenu">
        <TabBarControllerIOS id="main">
          <TabBarControllerIOS.Item title="Movies" icon="home">
            <NavigationControllerIOS title="Welcome" component="MovieListScreen" id="movies" />
          </TabBarControllerIOS.Item>
          <TabBarControllerIOS.Item title="Search" icon="discover">
            <ViewControllerIOS component="SearchScreen" />
          </TabBarControllerIOS.Item>
        </TabBarControllerIOS>
      </DrawerControllerIOS>
    );
  },
});
```

> Note: In this hierarchy you can only use view controllers. You can't use your traditional React Native components. For a full list of all supported view controllers see the rest of this doc.

Some of the view controllers in the hierarchy will have to contain your views. These views are the regular React Native components that you're used to. You will normally define these components in a dedicated JS module - where `React` wasn't hijacked and you can use all of its goodness.

To hook up a view, use the `component` attribute of the view controller in the JSX and provide the registered name of the component. Every view that you use has to be registered using `AppRegistry.registerComponent()`. For example, the movie list screen content is defined in [`MovieListScreen.js`](example/MovieListScreen.js) and there it's also registered with:

```js
AppRegistry.registerComponent('MovieListScreen', () => MovieListScreen);
```

#### Require all the view components that you referenced

We have to tell the React Native bundler that we need the components that we just referenced. The easiest way to do this and make sure their JS files are included in our bundle, is to `require` them. You can add this right before you define your view controller hierarchy:

```js
// require all top level react components you refer to in the layout
require('./SideMenu');
require('./MovieListScreen');
require('./SearchScreen');
```

#### Register your controller and set it as root

Just like we register regular React Native view modules, we'll need to register the view controller module we've just defined. In the end of `index.ios.js` add the following lines:

```js
ControllerRegistry.registerController('MoviesApp', () => MoviesApp);

// this line makes the app actually start and initialize
ControllerRegistry.setRootController('MoviesApp');
```

The last line is the magic line that bootstraps our entire app. When you set your controller (that you've just defined in JS) as root with `ControllerRegistry.setRootController()`, behind the scenes the native code sets it as `appDelegate.window.rootViewController`. Here you can see that the module that you've just defined is actually a [`UIViewController`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewController_Class/index.html) and not a [`UIView`](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/index.html).