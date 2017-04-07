//
//  AppDelegate.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.3
//

import UIKit
import Firebase
import FirebaseAuth
 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        

        FIRApp.configure()
        FIRAuth.auth()?.signInWithEmail("search@turnto.com", password: "__unset__"){  (user, error) in
            print(user)
        }
        
        // load canned data if this is first launch
        if SettingsManager.sharedInstance.firstLaunch == true {
            let db = CBStorage.init(databaseName: SCRIPTS_DB)
            db.initFromTut()
        }

        // check if we've already asked to use camera
        if SharedCameraManager.instance.didAuthCameraUsage() {
            Timing.runAfterBg(0){
                SharedCameraManager.instance.prepareCamera()
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        SharedCameraManager.instance.cam?.appPause()

    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        SharedCameraManager.instance.cam?.appResume()


    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        // delete cache db
    }
    

}

