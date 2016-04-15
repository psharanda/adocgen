// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import XCTest
import Mustache

class TemplateRepositoryDataSourceTests: XCTestCase {
    
    enum CustomError : ErrorType {
        case Error
    }
    
    func testTemplateRepositoryDataSource() {
        class TestedDataSource: TemplateRepositoryDataSource {
            func templateIDForName(name: String, relativeToTemplateID baseTemplateID: TemplateID?) -> TemplateID? {
                switch name {
                case "not_found":
                    return nil
                default:
                    return name
                }
            }
            func templateStringForTemplateID(templateID: TemplateID) throws -> String {
                switch templateID {
                case "not_found":
                    fatalError("Unexpected")
                case "CustomError":
                    throw CustomError.Error
                case "CustomNSError":
                    throw NSError(domain: "CustomNSError", code: 0, userInfo: nil)
                case "MustacheErrorCodeTemplateNotFound":
                    throw MustacheError(kind: .TemplateNotFound, message: "Custom Not Found Error")
                default:
                    return templateID
                }
            }
        }
        
        let repo = TemplateRepository(dataSource: TestedDataSource())
        var template: Template
        var rendering: String
        
        template = try! repo.template(named: "foo")
        rendering = try! template.render()
        XCTAssertEqual(rendering, "foo")
        
        template = try! repo.template(string: "{{>foo}}")
        rendering = try! template.render()
        XCTAssertEqual(rendering, "foo")
        
        do {
            try repo.template(string: "{{>not_found}}")
            XCTFail("Expected MustacheError")
        } catch let error as MustacheError {
            XCTAssertEqual(error.kind, MustacheError.Kind.TemplateNotFound)
        } catch {
            XCTFail("Expected MustacheError")
        }
        
        do {
            try repo.template(string: "{{>CustomNSError}}")
            XCTAssert(false)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "CustomNSError")
        }
        
        do {
            try repo.template(string: "{{>CustomError}}")
            XCTAssert(false)
        } catch CustomError.Error {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
        
        do {
            try repo.template(string: "{{>MustacheErrorCodeTemplateNotFound}}")
            XCTFail("Expected MustacheError")
        } catch let error as MustacheError {
            XCTAssertEqual(error.kind, MustacheError.Kind.TemplateNotFound)
        } catch {
            XCTFail("Expected MustacheError")
        }
    }
    
}
