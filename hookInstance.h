//
//  hookInstance.h
//  hookInstance
//
//  Created by Dora Orak on 22.01.2025.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

Class clsHook(id self, SEL _cmd){

    NSMutableString* className = [NSString stringWithCString:class_getName(object_getClass(self))];
    NSMutableString* baseClassName = className;
    
    if([className containsString:@"_instanceHook_"]){
        baseClassName = [NSMutableString stringWithString:[[className componentsSeparatedByString:@"_instanceHook_"] objectAtIndex:0]];
    }
    
    return objc_getClass(baseClassName.cString);

}

void hookInstance(id instance, SEL targetSEL, IMP replacementFp, IMP* origFp) {
    
    char* replacementClassName = [[NSString stringWithFormat:@"%@_instanceHook_", object_getClass(instance)] stringByAppendingString:[[NSUUID UUID] UUIDString]].cString;
    
    Class replacementClass = objc_allocateClassPair(object_getClass(instance), replacementClassName, 0);
    objc_registerClassPair(replacementClass);
    
    Method origMethod = class_getInstanceMethod(object_getClass(instance), targetSEL);
    
    if(origFp != NULL)
    *origFp = method_getImplementation(origMethod);
    
    const char* typenc = method_getTypeEncoding(origMethod);
        
    class_replaceMethod(replacementClass, targetSEL, replacementFp, typenc);

    //lie about the class
    class_replaceMethod(replacementClass, @selector(class), (IMP)clsHook, "#16@0:8");
 
    //apply hook
    object_setClass(instance, replacementClass);
}
