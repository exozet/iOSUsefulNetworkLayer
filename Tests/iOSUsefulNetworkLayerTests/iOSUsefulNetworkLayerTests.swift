import XCTest
@testable import UsefulNetworkLayer

final class iOSUsefulNetworkLayerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(iOSUsefulNetworkLayer().text, "Hello, iOSUsefulNetworkLayer!")
    }
    
    func testNetworkLayer() {
        let exp = XCTestExpectation(description: "Network layer should response success")

        let api = APIConfiguration(hostURL: "https://jsonplaceholder.typicode.com",
                                   endPoint: "todos/1",
                                   requestType: .get,
                                   headers: nil, body: nil,
                                   responseBodyObject: ExampleResponseObject.self,
                                   priority: .low,
                                   cachingTime: .init(seconds: 60),
                                   isMainOperation: false, autoCache: true)
        
        guard let apiReq = api else {
            XCTFail()
            return
        }
        
        apiReq.request { (result) in
            switch result {
            case .error(let err):
                XCTFail("Error: \(err.error.localizedDescription)")
                break
            case .success(let obj):
                print(obj)
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 5)
    }
    
    func testNetworkLayerArray() {
        let exp = XCTestExpectation(description: "Network layer should response success")

        let api = APIConfiguration(hostURL: "https://jsonplaceholder.typicode.com",
                                   endPoint: "todos",
                                   requestType: .get,
                                   headers: nil, body: nil,
                                   responseBodyObject: [ExampleResponseObject].self,
                                   priority: .low,
                                   cachingTime: .init(seconds: 60),
                                   isMainOperation: false, autoCache: true)
        
        guard let apiReq = api else {
            XCTFail()
            return
        }
        
        apiReq.request { (result) in
            switch result {
            case .error(let err):
                XCTFail("Error: \(err.error.localizedDescription)")
                break
            case .success(let obj):
                print(obj)
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 5)
    }

    static var allTests = [
        ("testExample", testExample),
        ("testNetworkLayer", testNetworkLayer),
        ("testNetworkLayerArray", testNetworkLayerArray)
    ]
}

class ExampleResponseObject: ResponseBodyParsable {
    
    static var shouldUseCustomInitializer: Bool { return false }
    var userId: Int
    var id: Int
    var title: String
    var completed: Bool
    
    required init?(data: Data) {
        return nil
    }

    required init?(response: Any?) {
        guard let dict = response as? [String:Any] else { return nil }
        guard let userId = dict["userId"] as? Int,
        let id = dict["id"] as? Int,
        let title = dict["title"] as? String,
            let completed = dict["completed"] as? Bool else { return nil }

        self.userId = userId
        self.id = id
        self.title = title
        self.completed = completed
    }
}
