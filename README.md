# Info 
This is a single header library that exposes a function to hook a method of a specific instance (as opposed to other hooking functions which hook the class itself)

# Usage

```objc
void hookInstance(id instance, SEL targetSEL, IMP replacementFp, IMP* origFp) 

instance: the instance you want to hook
targetSEL: selector for the method you want to hook
replacementFp: function pointer to the replacement function
origFp: adress of a function pointer that will be filled in with a stub which may be used to call the original implementation. This can be NULL if you don't wish to use original implementation
```
Using with the same instance multiple times is supported, you can do this to hook multiple methods.

There is an example for the usage in "example" branch, as a tip; it is designed to be similiar with `MSHookMessageEx` function

# How it works
It is creating a new class everytime you call the function, replaces the target method of it and uses `object_setClass` on the instance with that class to apply the hook












