//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation

enum FieldType: String {
    case String
    case Dictionary
    case Array
    case Number
    case Bool
    case Undefined
}

struct SnippetInfo {
    let imagePath: String
    let imageWidth: Int
    let imageHeight: Int
    let jsonSnippet: Any
}

struct FieldMetaData {
    let name: String
    let type: FieldType
    let overview: String?
    let defaultValue: String?
}

struct TypeMetaData {
    let type: String
    let overview: String?
    let fields: [FieldMetaData]?
    let snippets: [SnippetInfo]?
    let supertype: String?
}

struct MetaDataGenerator {
    
    func jsonTypeFromSwiftType(_ swiftType: String?) -> FieldType {
        
        guard let st = swiftType else {
            return .Undefined
        }
        
        
        if st.contains(":") {
            return .Dictionary
        } else if st.contains("[") {
            return .Array
        } else if st.contains("String") {
            return .String
        } else if st.contains("Int") || st.contains("Double") {
            return .Number
        } else {
            return .Undefined
        }
    }
    
    func supertypeForType(_ type: SKType, classTypeMap: [String: String]) -> String? {
        
        for sup in type.inheritedTypes {
            if classTypeMap[sup] != nil  {
                return sup
            }
        }
        return nil
    }
    
    func generateMetadata(_ sourceKittenTypes: [SKType], classTypeMap: [String: String], mirrorer: (String) -> Mirror?, snippets: [String:[SnippetInfo]]) -> [TypeMetaData]
    {
        var mds = [TypeMetaData]()
        
        for sk in sourceKittenTypes {
            
            if let clsType = sk.name, let type = classTypeMap[clsType] {
                
                var fields = [FieldMetaData]()
                
                let m = mirrorer(type)
                
                
                for fd in sk.fields {
                    
                    if let fname = fd.name {
                        
                        var defaultValue: String? = nil
                        
                        if m != nil {
                            for case let (label?, value) in m!.children {
                                if label == fname {
                                    defaultValue = "\(value)"
                                }
                            }
                        }                        
                        
                        fields.append(FieldMetaData(name: fname, type: jsonTypeFromSwiftType(fd.typename), overview: fd.comment, defaultValue: defaultValue))
                    }
                }
                
                let superClassType = supertypeForType(sk, classTypeMap: classTypeMap)
                
                mds.append(TypeMetaData(type: type, overview: sk.comment, fields: fields, snippets: snippets[type], supertype: superClassType != nil ? classTypeMap[superClassType!] : nil))
            }
            
        }
        
        return mds
    }
}

