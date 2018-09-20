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
        if let jsonPath = Bundle.main.path(forResource: "model.json", ofType: nil) {
            do {
                types = try parseSourceKittenOutput(jsonPath)
            }
            catch {
                print("Error: model.json parsing failed")
            }
        }
        return types
    }
    
    func generateDocs(_ snippets: [String:[SnippetInfo]]) -> Void {
        do {
            
            let mirrorer = {(type: String) -> Mirror? in
                
                if let w = CellModelFactory.sharedInstance.create(type) {
                    return Mirror(reflecting: w)
                }
                return nil
            }
            
            let types = MetaDataGenerator().generateMetadata(sourceKittenTypes(), classTypeMap: CellModelFactory.sharedInstance.classTypeMap(), mirrorer: mirrorer, snippets: snippets)
            let docGenerator = DocGenerator()
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        var itemsList = [CellModelInfo]()
        
        if let jsonPath = Bundle.main.path(forResource: "items.json", ofType: nil) {
            if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                    
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
        
        let vc = TableViewController()
        let nc = UINavigationController(rootViewController: vc)
        
        window = UIWindow()
        window?.rootViewController = nc
        window?.makeKeyAndVisible()
        
        //loadItems(itemsList, vc: vc)
        startGeneratingDocs(itemsList, vc: vc)


        return true
    }
    
    func startGeneratingDocs(_ items:[CellModelInfo], vc: TableViewController) {
        
        snapshotItem(0, items: items, vc: vc, snippets: [:])
    }
    
    func loadItems(_ items:[CellModelInfo], vc: TableViewController) {
        vc.items = items.reduce([CellModel](), { (list:[CellModel], tuple: (String, CellModel, JSON)) -> [CellModel] in
            var a = list
            a.append(tuple.1)
            return a
        })

    }
    
    func snapshotItem(_ idx: Int, items: [CellModelInfo], vc: TableViewController, snippets: [String : [SnippetInfo]]) {
        
        if idx == items.count {
            generateDocs(snippets)
            loadItems(items, vc: vc)
            return
        }
        vc.items = [items[idx].1]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { () -> Void in
            
            var mutSnippets = snippets
            if let cell = vc.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) {
                
                let img = UIImage.imageWithView(cell)
                
                if let imgData = img.pngData() {
                    
                    var a = (snippets[items[idx].0]) ?? [SnippetInfo]()
                    
                    let imgPath = NSString(string: NSTemporaryDirectory()).appending("\(items[idx].0)-\(a.count + 1).png")
                    
                    do {
                        try imgData.write(to: URL(fileURLWithPath: imgPath))
                    }
                    catch let error as NSError {
                        print(error)
                    }
                    
                    a.append(SnippetInfo(imagePath: imgPath, imageWidth: Int(img.size.width), imageHeight: Int(img.size.height), jsonSnippet: items[idx].2.rawValue))
                    mutSnippets[items[idx].0] = a
                }
                
            }
            
            self.snapshotItem(idx + 1, items: items, vc: vc, snippets: mutSnippets)
        }
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

