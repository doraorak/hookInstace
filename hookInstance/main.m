//
//  main.m
//  hookInstance
//
//  Created by Dora Orak on 22.01.2025.
//
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>


Class (*clsOrig)(id self, SEL _cmd);

Class clsHook(id self, SEL _cmd){

    NSMutableString* className = [NSString stringWithCString:class_getName(clsOrig(self, _cmd))];
    NSMutableString* baseClassName = className;
    
    if([className containsString:@"_instanceHook_"]){
        baseClassName = [NSMutableString stringWithString:[[className componentsSeparatedByString:@"_instanceHook_"] objectAtIndex:0]];
    }
    
    return objc_getClass(baseClassName.cString);

}

void hookInstance(id instance, SEL targetSEL, IMP replacementFp, IMP* origFp) {
    
    char* replacementClassName = [[NSString stringWithFormat:@"%@_instanceHook_", [instance class]] stringByAppendingString:[[NSUUID UUID] UUIDString]].cString;
    
    Class replacementClass = objc_allocateClassPair([instance class], replacementClassName, 0);
    objc_registerClassPair(replacementClass);
    
    Method origMethod = class_getInstanceMethod([instance class], targetSEL);
    
    if(origFp != NULL)
    *origFp = method_getImplementation(origMethod);
    
    const char* typenc = method_getTypeEncoding(origMethod);
        
    class_replaceMethod(replacementClass, targetSEL, replacementFp, typenc);

    //lie about the class
    NSMutableString* className = [NSString stringWithCString:class_getName([instance class])];
    NSMutableString* baseClassName = className;
    
    if([className containsString:@"_instanceHook_"]){
        baseClassName = [NSMutableString stringWithString:[[className componentsSeparatedByString:@"_instanceHook_"] objectAtIndex:0]];
    }
    Method clsOrigMethod = class_getInstanceMethod(objc_getClass(baseClassName.cString), @selector(class));
    
    *((IMP*)(&clsOrig)) = method_getImplementation(clsOrigMethod);

    const char* clsTypenc = method_getTypeEncoding(clsOrigMethod);
    
    class_replaceMethod(replacementClass, @selector(class), (IMP)clsHook, clsTypenc);
 
    //apply hook
    object_setClass(instance, replacementClass);
}



void (*sbgcOrigOld)(id _self, SEL cmd, struct CGColor* color);
void (*sbcOrigOld)(id _self, SEL cmd, CGColorRef clr);


void sbgcHook(id _self, SEL cmd, struct CGColor* color){
    
    
    sbgcOrigOld(_self, cmd, NSColor.yellowColor.CGColor);

   
}

void sbgcHook2(id _self, SEL cmd, struct CGColor* color){
    
    
    sbgcOrigOld(_self, cmd, NSColor.cyanColor.CGColor);

   
}

void sbcHook(id _self, SEL cmd, CGColorRef clr){
    
    
    sbcOrigOld(_self, cmd, NSColor.greenColor.CGColor);
    
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Create the NSApplication instance
        NSApplication* app = [NSApplication sharedApplication];

        // Create the window with the specified frame size
        NSWindow* win = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 800)
                                                    styleMask:(NSWindowStyleMaskResizable | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];

        // Make the window the key window
        [win makeKeyAndOrderFront:nil];
        
        NSViewController* vc = [NSViewController new];
        
        win.contentViewController = vc;
        
        NSView* IHview = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 200)];
        IHview.wantsLayer = YES;
        
        NSView* otherIHview = [[NSView alloc] initWithFrame:NSMakeRect(150, 200, 150, 200)];
        otherIHview.wantsLayer = YES;
        
        NSView* otherview = [[NSView alloc] initWithFrame:NSMakeRect(150, 0, 150, 200)];
        otherview.wantsLayer = YES;
        
        hookInstance(IHview.layer, @selector(setBorderColor:), (IMP)sbcHook, (IMP*)&sbcOrigOld);

        hookInstance(IHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook, (IMP*)&sbgcOrigOld);
        hookInstance(IHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook2, (IMP*)&sbgcOrigOld);

        hookInstance(otherIHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook, (IMP*)&sbgcOrigOld);

        NSLog(@"cn:%@", [IHview.layer class]);
        
        otherIHview.layer.backgroundColor = [NSColor.blueColor CGColor];
        otherview.layer.backgroundColor = [NSColor.blueColor CGColor];
        IHview.layer.backgroundColor = [NSColor.blueColor CGColor];

        
        IHview.layer.borderWidth = 10;
        IHview.layer.borderColor = NSColor.magentaColor.CGColor;

        [win.contentView addSubview:IHview];
        [win.contentView addSubview:otherIHview];
        [win.contentView addSubview:otherview];

        // Run the application event loop
        [app run];
    }

    return 0;
}
