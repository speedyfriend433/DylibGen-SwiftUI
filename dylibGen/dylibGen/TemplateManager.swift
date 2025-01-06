//
//  TemplateManager.swift
//  dylibGen
//
//  Created by 지안 on 2025/01/06.
//

import Foundation

class TemplateManager {
    static let shared = TemplateManager()
    
    private init() {} // Make initializer private for singleton
    
    func getTemplate(for type: TemplateType) -> String {
        switch type {
        case .tweak:
            return """
            #import <Foundation/Foundation.h>
            #import <UIKit/UIKit.h>
            
            %hook UIViewController
            
            -(void)viewDidLoad {
                %orig;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hooked!"
                                                                             message:@"This view controller has been hooked"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            %end
            """
            
        case .hook:
            return """
            #import <Foundation/Foundation.h>
            
            %hook NSURLConnection
            
            + (void)sendAsynchronousRequest:(NSURLRequest *)request
                                    queue:(NSOperationQueue *)queue
                        completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
                // Modify request or response here
                %orig(request, queue, handler);
            }
            
            %end
            """
            
        case .custom:
            return "// Enter your custom code here"
        }
    }
}
