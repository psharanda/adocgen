//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation
import Mustache

class DocGenerator {
    
    var appName: String
    var appVersion: String
    var date: NSDate
    var company: String
    
    var referencePath: String
    
    var cssFileName: String
    var indexTemplateFileName: String
    var typeTemplateFileName: String
    
    var cssPath: String {
        return NSString.init(string: self.referencePath).stringByAppendingPathComponent("css")
    }
    var imagesPath: String {
        return NSString.init(string: self.referencePath).stringByAppendingPathComponent("images")
    }
    
    init () {
        self.appName = "My App"
        self.appVersion = "1.0"
        self.date = NSDate.init()
        self.company = "My Company"
        
        if let infoDict = NSBundle.mainBundle().infoDictionary {
            
            if let name = infoDict["CFBundleName"] as? String {
                self.appName = name
            }
            if let version = infoDict["CFBundleShortVersionString"] as? String {
                self.appVersion = version
            }
        }
        
        self.referencePath = NSString.init(string: NSTemporaryDirectory()).stringByAppendingPathComponent("Reference")
        
        self.cssFileName = "styles.css"
        self.indexTemplateFileName = "index.html"
        self.typeTemplateFileName = "type.html"
    }
    
    //MARK: - utils
    
    private func baseDict() -> [String:AnyObject] {
        
        let dateFormatter = NSDateFormatter.init()
        dateFormatter.dateStyle = .ShortStyle
        
        let dateString = dateFormatter.stringFromDate(self.date)
        dateFormatter.dateFormat = "YYYY"
        let yearString = dateFormatter.stringFromDate(self.date)
        
        return ["app_name":self.appName, "app_version":self.appVersion, "date":dateString, "year": yearString, "company":self.company]
    }
    
    private func linkOrSpan(type: String, objectTypes:[TypeMetaData]) -> String {
        for i in objectTypes {
            if i.type == type {
                return "<a href=\"\(type).html\">\(type)</a>"
            }
        }
        return type
    }
    
    private func jsonString(jsonObject: AnyObject) throws -> NSString? {
        let data = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: .PrettyPrinted)
        let jsonString = NSString.init(data: data, encoding: NSUTF8StringEncoding)
        return jsonString?.stringByReplacingOccurrencesOfString("\\/", withString:"/")
    }
    
    func prepareDirectories() throws -> Void {
        
        if NSFileManager.defaultManager().fileExistsAtPath(self.referencePath) {
            try NSFileManager.defaultManager().removeItemAtPath(self.referencePath)
        }
        
        try NSFileManager.defaultManager().createDirectoryAtPath(self.referencePath, withIntermediateDirectories: true, attributes:  nil)
        try NSFileManager.defaultManager().createDirectoryAtPath(self.cssPath, withIntermediateDirectories: true, attributes: nil)
        try NSFileManager.defaultManager().createDirectoryAtPath(self.imagesPath, withIntermediateDirectories: true, attributes: nil)
        
        if let cssPath = NSBundle.mainBundle().pathForResource(self.cssFileName, ofType: nil) {
            try NSFileManager.defaultManager().copyItemAtPath(cssPath, toPath:  NSString.init(string: self.cssPath).stringByAppendingPathComponent(self.cssFileName))
        }
    }
    
    //MARK: - public api
    
    func generateDocumentation(objectTypes:[TypeMetaData]) throws -> Void {
        
        if let indexTemplateFilePath = NSBundle.mainBundle().pathForResource(self.indexTemplateFileName, ofType: nil),
            let typeTemplateFilePath = NSBundle.mainBundle().pathForResource(self.typeTemplateFileName, ofType: nil) {
                try prepareDirectories()
                try self.generateDocumentation(indexTemplateFilePath, typeTemplateFilePath: typeTemplateFilePath, targetDirectoryPath: self.referencePath, objectTypes: objectTypes)
        }
    }
    
    func generateDocumentation(indexTemplateFilePath:String, typeTemplateFilePath:String, targetDirectoryPath: String, objectTypes:[TypeMetaData]) throws -> Void {
        
        try generateIndexHtml(indexTemplateFilePath, targetDirectoryPath: targetDirectoryPath, objectTypes: objectTypes)
        
        for objectType in objectTypes {
            try generateTypeHtml(typeTemplateFilePath, targetDirectoryPath: targetDirectoryPath, objectType: objectType, objectTypes: objectTypes)
        }
        
    }
    
    func generateIndexHtml(indexTemplateFilePath:String, targetDirectoryPath: String, objectTypes:[TypeMetaData]) throws -> Void {
        
        let template = try Template(path: indexTemplateFilePath)
        let indexHtml = try template.render(self.boxForIndex(objectTypes))
        try indexHtml.writeToFile(targetDirectoryPath.stringByAppendingString("/index.html"), atomically: false, encoding: NSUTF8StringEncoding)
    }
    
    func generateTypeHtml(typeTemplateFilePath:String, targetDirectoryPath: String, objectType: TypeMetaData, objectTypes:[TypeMetaData]) throws -> Void {
        
        let template = try Template(path: typeTemplateFilePath)
        let indexHtml = try template.render(self.boxForType(objectType, objectTypes: objectTypes))
        try indexHtml.writeToFile(targetDirectoryPath.stringByAppendingString("/\(objectType.type).html"), atomically: false, encoding: NSUTF8StringEncoding)
    }
    
    //MARK: - render index
    
    private class HierarchyItem {
        let type: String
        let supertype: String?
        var subitems: [HierarchyItem] = []
        var foundSuper: Bool = false
        init (type: String, supertype: String?) {
            self.type = type
            self.supertype = supertype
        }
    }
    
    private func hierarchyDeepSearch(item: HierarchyItem, type: String) -> HierarchyItem? {
        
        if item.type == type {
            return item
        }
        
        for subitem in item.subitems {
            let res = self.hierarchyDeepSearch(subitem, type: type)
            if res != nil {
                return res
            }
        }
        
        return nil
    }
    
    private func buildTypesHierarchy(objectTypes:[TypeMetaData]) -> [HierarchyItem] {
        var result = [HierarchyItem]()
        
        var knownItems = [HierarchyItem]()
        
        for meta in objectTypes {
            let item = HierarchyItem.init(type: meta.type, supertype: meta.supertype)
            knownItems.append(item)
        }
        
        for i in knownItems {
            
            for j in knownItems {
                if i !== j {
                    if let supertype = i.supertype, let res =  self.hierarchyDeepSearch(j, type: supertype) {
                        res.subitems.append(i)
                        i.foundSuper = true
                        break
                    }
                }
            }
        }
        
        for i in knownItems {
            if (!i.foundSuper) {
                result.append(i)
            }
        }
        
        return result
    }
    
    private func htmlStringForHierarchyItems(items: [HierarchyItem], objectTypes: [TypeMetaData]) -> String {
        return "<ul>" + items.reduce("", combine: { (text:String, item: HierarchyItem) -> String in
            return text + "<li>" + self.linkOrSpan(item.type, objectTypes: objectTypes) + self.htmlStringForHierarchyItems(item.subitems, objectTypes: objectTypes)+"</li>"
        }) + "</ul>"
    }
    
    private func boxForIndex(objectTypes:[TypeMetaData]) -> MustacheBox {
        var dict = self.baseDict()
            
        dict["index"] = self.htmlStringForHierarchyItems(self.buildTypesHierarchy(objectTypes), objectTypes: objectTypes)
        
        return Box(dict)
    }
    
     //MARK: - render type
    
    private func boxForType(meta: TypeMetaData, objectTypes:[TypeMetaData]) throws -> MustacheBox {
        var dict = self.baseDict()
        
        if (meta.overview != nil) {
            dict["overview"] = meta.overview
            dict["has_overview"] = true
        } else {
            dict["has_overview"] = false
        }
        
        dict["type"] = meta.type
        
        var hierarchy = [String]()
        
        var supertype = meta.supertype
        while true {
            
            if supertype == nil {
                break
            }
            
            hierarchy.append(self.linkOrSpan(supertype!, objectTypes: objectTypes))
            
            var found = false
            for m in objectTypes {
                if m.type == supertype {
                    supertype = m.supertype
                    found = true
                }
            }
            if !found {
                break
            }
        }
        
        if hierarchy.count > 0 {
            dict["hierarchy"] = hierarchy.reduce("", combine: { (str: String, item: String) -> String in
                return str + (str.characters.count > 0 ? ":" : "") + item
            })
            dict["has_inherits"] = true
        } else {
            dict["has_inherits"] = false
        }
        
        if let fields = meta.fields where fields.count > 0 {
        
            var fieldsDicts = [[String:AnyObject]]()
        
            for f in fields {
                var fieldDict = [String:AnyObject]()
                fieldDict["name"] = f.name
                fieldDict["type"] = f.type.rawValue.lowercaseString

                if (f.defaultValue != nil) {
                    fieldDict["default_value"] = f.defaultValue
                    fieldDict["has_default_value"] = true
                } else {
                    fieldDict["has_default_value"] = false
                }
                
                if (f.overview != nil) {
                    fieldDict["overview"] = f.overview!
                    fieldDict["has_overview"] = true
                } else {
                    fieldDict["has_overview"] = false
                }
                fieldsDicts.append(fieldDict)
            }
            
            dict["fields"] = fieldsDicts
            dict["has_fields"] = true
        } else {
            dict["has_fields"] = false
        }
        
        if let snips = meta.snippets where snips.count > 0 {
            
            var snippetsDicts = [[String:AnyObject]]()
            
            for snippet in snips {
                
                var snipDict = [String:AnyObject]()
                snipDict["json"] = try self.jsonString(snippet.jsonSnippet)
                snipDict["width"] = snippet.imageWidth
                snipDict["height"] = snippet.imageHeight
                
                let filename = NSString.init(string: snippet.imagePath).lastPathComponent
                
                try NSFileManager.defaultManager().moveItemAtPath(snippet.imagePath, toPath: NSString.init(string: self.imagesPath).stringByAppendingPathComponent(filename))
                
                snipDict["filename"] = filename
                
                snippetsDicts.append(snipDict)
            }
            
            dict["snippets"] = snippetsDicts
            dict["has_snippets"] = true;
        }
        else
        {
            dict["has_snippets"] = false;
        }

        
        return Box(dict)
    }

}
