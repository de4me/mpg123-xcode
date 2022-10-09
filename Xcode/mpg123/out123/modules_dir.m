//
//  modules_dir.m
//  libmpg123
//
//  Created by DE4ME on 03.10.2022.
//

#import <Foundation/Foundation.h>
#include <limits.h>


const char* get_modules_dir(void) {
    static char buffer[PATH_MAX] = {0};
    if (buffer[0]) {
        return buffer;
    }
#ifdef OUT123_FRAMEWORK
    NSBundle* bundle = [NSBundle bundleWithIdentifier:@"org.mpg123.out123"];
    if (bundle) {
        NSString* path = bundle.builtInPlugInsPath;
        [path getCString:buffer maxLength:sizeof(buffer) encoding:kCFStringEncodingUTF8];
    }
#else
    NSString* home = NSHomeDirectory();
    if ([home getCString:buffer maxLength:sizeof(buffer) encoding:NSUTF8StringEncoding]) {
        strlcat(buffer, "/.mpg123/plugins", sizeof(buffer));
    }
#endif
    return buffer;
}
