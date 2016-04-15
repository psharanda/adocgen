//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import UIKit
import Mustache
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func sourceKittenTypes() -> [SKType] {
        
        var types = [SKType]()
        if let jsonPath = NSBundle.mainBundle().pathForResource("model.json", ofType: nil) {
            do {
                types = try parseSourceKittenOutput(jsonPath)
            }
            catch {
                print("Error: model.json parsing failed")
            }
        }
        return types
    }
    
    func generateDocs(snippets: [String:[SnippetInfo]]) -> Void {
        do {
            
            let mirrorer = {(type: String) -> Mirror? in
                
                if let w = CellModelFactory.sharedInstance.create(type) {
                    return Mirror.init(reflecting: w)
                }
                return nil
            }
            
            let types = MetaDataGenerator.init().generateMetadata(sourceKittenTypes(), classTypeMap: CellModelFactory.sharedInstance.classTypeMap(), mirrorer: mirrorer, snippets: snippets)
            let docGenerator = DocGenerator.init()
            try docGenerator.generateDocumentation(types)
            print("Finished: \(docGenerator.referencePath)")
        }
        catch let error as MustacheError {
            print("MustacheError: \(error.description)")
        }
        catch let error as NSError {
            print("NSError: \(error.localizedDescription)")
        }
        catch {
            print("Error: docs generation failed")
        }
    }
    
    typealias CellModelInfo = (String, CellModel, JSON)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        var itemsList = [CellModelInfo]()
        
        if let jsonPath = NSBundle.mainBundle().pathForResource("items.json", ofType: nil) {
            if let jsonData = NSData.init(contentsOfFile: jsonPath) {
                do {
                    let jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                    
                    let json = JSON(jsonObject)
                    
                    if let items = json["items"].array {
                        for dict in items {
                            
                            if let d = dict.dictionary {
                                if let w = CellModelFactory.sharedInstance.create(dict) {
                                    itemsList.append((d["type"]!.string!, w, dict))
                                }
                            }
                        }
                    }
                }
                catch {
                    print("Error: items.json parsing failed")
                }
            }
        }
        
        let vc = TableViewController.init()
        let nc = UINavigationController.init(rootViewController: vc)
        
        window = UIWindow.init()
        window?.rootViewController = nc
        window?.makeKeyAndVisible()
        
        //loadItems(itemsList, vc: vc)
        startGeneratingDocs(itemsList, vc: vc)


        return true
    }
    
    func startGeneratingDocs(items:[CellModelInfo], vc: TableViewController) {
        
        snapshotItem(0, items: items, vc: vc, snippets: [:])
    }
    
    func loadItems(items:[CellModelInfo], vc: TableViewController) {
        vc.items = items.reduce([CellModel](), combine: { (list:[CellModel], tuple: (String, CellModel, JSON)) -> [CellModel] in
            var a = list
            a.append(tuple.1)
            return a
        })

    }
    
    func snapshotItem(idx: Int, items: [CellModelInfo], vc: TableViewController, snippets: [String : [SnippetInfo]]) {
        
        if idx == items.count {
            generateDocs(snippets)
            loadItems(items, vc: vc)
            return
        }
        vc.items = [items[idx].1]
        
        dispatch_after(1, dispatch_get_main_queue()) { () -> Void in
            
            var mutSnippets = snippets
            if let cell = vc.tableView.cellForRowAtIndexPath(NSIndexPath.init(forItem: 0, inSection: 0)) {
                
                let img = UIImage.imageWithView(cell)
                
                if let imgData = UIImagePNGRepresentation(img) {
                    
                    var a = (snippets[items[idx].0]) ?? [SnippetInfo]()
                    
                    let imgPath = NSString.init(string: NSTemporaryDirectory()).stringByAppendingPathComponent("\(items[idx].0)-\(a.count + 1).png")
                    imgData.writeToFile(imgPath, atomically: false)
                    
                    a.append(SnippetInfo.init(imagePath: imgPath, imageWidth: Int(img.size.width), imageHeight: Int(img.size.height), jsonSnippet: items[idx].2.rawValue))
                    mutSnippets[items[idx].0] = a
                }
                
            }
            
            self.snapshotItem(idx + 1, items: items, vc: vc, snippets: mutSnippets)
        }
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

