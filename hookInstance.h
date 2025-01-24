//
//  hookInstance.h
//  hookInstance
//
//  Created by Dora Orak on 22.01.2025.
//
#import <Foundation/Foundation.h>
#import <objc/runtime.h>


void hookInstance(id instance, SEL targetSEL, IMP replacementFp, IMP* origFp) {
    
    char* replacementClassName = [[NSString stringWithFormat:@"%@_hook_", [instance class]] stringByAppendingString:[[NSUUID UUID] UUIDString]].cString;
    
    Class replacementClass = objc_allocateClassPair([instance class], replacementClassName, 0);
    objc_registerClassPair(replacementClass);
    
    Method origMethod = class_getInstanceMethod([instance class], targetSEL);
    
    if(origFp != NULL)
    *origFp = method_getImplementation(origMethod);
    
    const char* typenc = method_getTypeEncoding(origMethod);
        
    class_replaceMethod(replacementClass, targetSEL, replacementFp, typenc);
    
    object_setClass(instance, replacementClass);
}
