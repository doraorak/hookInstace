//
//  main.m
//  hookInstance
//
//  Created by Dora Orak on 22.01.2025.
//
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>


void hookInstance(id instance, SEL targetSEL, IMP replacementFp, IMP* origFp) {
    

    char* replacementClassName = [[NSString stringWithFormat:@"%@_hook_", [instance class]] stringByAppendingString:[[NSUUID UUID] UUIDString]].cString;
    
    Class replacementClass = objc_allocateClassPair([instance class], replacementClassName, 0);
    objc_registerClassPair(replacementClass);
    
    Method origMethod = class_getInstanceMethod([instance class], targetSEL);
        
    *origFp = method_getImplementation(origMethod);
    
    char* typenc = method_getTypeEncoding(origMethod);
        
    class_replaceMethod(replacementClass, targetSEL, replacementFp, typenc);
    
    object_setClass(instance, replacementClass);
}


void (*sbgcOrigOld)(id _self, SEL cmd, struct CGColor* color);


void sbgcHook(id _self, SEL cmd, struct CGColor* color){
    
    
    sbgcOrigOld(_self, cmd, NSColor.yellowColor.CGColor);

   
}

void sbgcHook2(id _self, SEL cmd, struct CGColor* color){
    
    
    sbgcOrigOld(_self, cmd, NSColor.cyanColor.CGColor);

   
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
        
        hookInstance(IHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook, (IMP*)&sbgcOrigOld);
        hookInstance(IHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook2, (IMP*)&sbgcOrigOld);
        hookInstance(otherIHview.layer, @selector(setBackgroundColor:), (IMP)sbgcHook, (IMP*)&sbgcOrigOld);

        IHview.layer.backgroundColor = [NSColor.blueColor CGColor];
        otherIHview.layer.backgroundColor = [NSColor.blueColor CGColor];
        otherview.layer.backgroundColor = [NSColor.blueColor CGColor];

        [win.contentView addSubview:IHview];
        [win.contentView addSubview:otherIHview];
        [win.contentView addSubview:otherview];

        // Run the application event loop
        [app run];
    }

    return 0;
}
