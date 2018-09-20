//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation
import Mustache

class DocGenerator {
    
    var appName: String
    var appVersion: String
    var date: Date
    var company: String
    
    var referencePath: String
    
    var cssFileName: String
    var indexTemplateFileName: String
    var typeTemplateFileName: String
    
    var cssPath: String {
        return NSString(string: self.referencePath).appendingPathComponent("css")
    }
    var imagesPath: String {
        return NSString(string: self.referencePath).appendingPathComponent("images")
    }
    
    init () {
        self.appName = "My App"
        self.appVersion = "1.0"
        self.date = Date()
        self.company = "My Company"
        
        if let infoDict = Bundle.main.infoDictionary {
            
            if let name = infoDict["CFBundleName"] as? String {
                self.appName = name
            }
            if let version = infoDict["CFBundleShortVersionString"] as? String {
                self.appVersion = version
            }
        }
        
        self.referencePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("Reference")
        
        self.cssFileName = "styles.css"
        self.indexTemplateFileName = "index.html"
        self.typeTemplateFileName = "type.html"
    }
    
    //MARK: - utils
    
    fileprivate func baseDict() -> [String:Any] {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        let dateString = dateFormatter.string(from: self.date)
        dateFormatter.dateFormat = "YYYY"
        let yearString = dateFormatter.string(from: self.date)
        
        return ["app_name":self.appName, "app_version":self.appVersion, "date":dateString, "year": yearString, "company":self.company]
    }
    
    fileprivate func linkOrSpan(_ type: String, objectTypes:[TypeMetaData]) -> String {
        for i in objectTypes {
            if i.type == type {
                return "<a href=\"\(type).html\">\(type)</a>"
            }
        }
        return type
    }
    
    fileprivate func jsonString(_ jsonObject: Any) throws -> NSString? {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        let jsonString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return jsonString?.replacingOccurrences(of: "\\/", with:"/") as NSString?
    }
    
    func prepareDirectories() throws -> Void {
        
        if FileManager.default.fileExists(atPath: self.referencePath) {
            try FileManager.default.removeItem(atPath: self.referencePath)
        }
        
        try FileManager.default.createDirectory(atPath: self.referencePath, withIntermediateDirectories: true, attributes:  nil)
        try FileManager.default.createDirectory(atPath: self.cssPath, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: self.imagesPath, withIntermediateDirectories: true, attributes: nil)
        
        if let cssPath = Bundle.main.path(forResource: self.cssFileName, ofType: nil) {
            try FileManager.default.copyItem(atPath: cssPath, toPath:  NSString(string: self.cssPath).appendingPathComponent(self.cssFileName))
        }
    }
    
    //MARK: - public api
    
    func generateDocumentation(_ objectTypes:[TypeMetaData]) throws -> Void {
        
        if let indexTemplateFilePath = Bundle.main.path(forResource: self.indexTemplateFileName, ofType: nil),
            let typeTemplateFilePath = Bundle.main.path(forResource: self.typeTemplateFileName, ofType: nil) {
                try prepareDirectories()
                try self.generateDocumentation(indexTemplateFilePath, typeTemplateFilePath: typeTemplateFilePath, targetDirectoryPath: self.referencePath, objectTypes: objectTypes)
        }
    }
    
    func generateDocumentation(_ indexTemplateFilePath:String, typeTemplateFilePath:String, targetDirectoryPath: String, objectTypes:[TypeMetaData]) throws -> Void {
        
        try generateIndexHtml(indexTemplateFilePath, targetDirectoryPath: targetDirectoryPath, objectTypes: objectTypes)
        
        for objectType in objectTypes {
            try generateTypeHtml(typeTemplateFilePath, targetDirectoryPath: targetDirectoryPath, objectType: objectType, objectTypes: objectTypes)
        }
        
    }
    
    func generateIndexHtml(_ indexTemplateFilePath:String, targetDirectoryPath: String, objectTypes:[TypeMetaData]) throws -> Void {
        
        let template = try Template(path: indexTemplateFilePath)
        let indexHtml = try template.render(self.boxForIndex(objectTypes))
        try indexHtml.write(toFile: (targetDirectoryPath as NSString).appending("/index.html"), atomically: false, encoding: String.Encoding.utf8)
    }
    
    func generateTypeHtml(_ typeTemplateFilePath:String, targetDirectoryPath: String, objectType: TypeMetaData, objectTypes:[TypeMetaData]) throws -> Void {
        
        let template = try Template(path: typeTemplateFilePath)
        let indexHtml = try template.render(self.boxForType(objectType, objectTypes: objectTypes))
        try indexHtml.write(toFile:(targetDirectoryPath as NSString).appending("/\(objectType.type).html"), atomically: false, encoding: String.Encoding.utf8)
    }
    
    //MARK: - render index
    
    fileprivate class HierarchyItem {
        let type: String
        let supertype: String?
        var subitems: [HierarchyItem] = []
        var foundSuper: Bool = false
        init (type: String, supertype: String?) {
            self.type = type
            self.supertype = supertype
        }
    }
    
    fileprivate func hierarchyDeepSearch(_ item: HierarchyItem, type: String) -> HierarchyItem? {
        
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
    
    fileprivate func buildTypesHierarchy(_ objectTypes:[TypeMetaData]) -> [HierarchyItem] {
        var result = [HierarchyItem]()
        
        var knownItems = [HierarchyItem]()
        
        for meta in objectTypes {
            let item = HierarchyItem(type: meta.type, supertype: meta.supertype)
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
    
    fileprivate func htmlStringForHierarchyItems(_ items: [HierarchyItem], objectTypes: [TypeMetaData]) -> String {
        return "<ul>" + items.reduce("", { (text:String, item: HierarchyItem) -> String in
            return text + "<li>" + self.linkOrSpan(item.type, objectTypes: objectTypes) + self.htmlStringForHierarchyItems(item.subitems, objectTypes: objectTypes)+"</li>"
        }) + "</ul>"
    }
    
    fileprivate func boxForIndex(_ objectTypes:[TypeMetaData]) -> MustacheBox {
        var dict = self.baseDict()
            
        dict["index"] = self.htmlStringForHierarchyItems(self.buildTypesHierarchy(objectTypes), objectTypes: objectTypes)
        
        return Box(dict)
    }
    
     //MARK: - render type
    
    fileprivate func boxForType(_ meta: TypeMetaData, objectTypes:[TypeMetaData]) throws -> MustacheBox {
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
            dict["hierarchy"] = hierarchy.reduce("", { (str: String, item: String) -> String in
                let s = (str.count > 0 ? ":" : "")
                return str + s + item
            })
            dict["has_inherits"] = true
        } else {
            dict["has_inherits"] = false
        }
        
        if let fields = meta.fields, fields.count > 0 {
        
            var fieldsDicts = [[String:Any]]()
        
            for f in fields {
                var fieldDict = [String:Any]()
                fieldDict["name"] = f.name
                fieldDict["type"] = f.type.rawValue.lowercased()

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
        
        if let snips = meta.snippets, snips.count > 0 {
            
            var snippetsDicts = [[String:Any]]()
            
            for snippet in snips {
                
                var snipDict = [String:Any]()
                snipDict["json"] = try self.jsonString(snippet.jsonSnippet)
                snipDict["width"] = snippet.imageWidth
                snipDict["height"] = snippet.imageHeight
                
                let filename = NSString(string: snippet.imagePath).lastPathComponent
                
                try FileManager.default.moveItem(atPath: snippet.imagePath, toPath: NSString(string: self.imagesPath).appendingPathComponent(filename))
                
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
