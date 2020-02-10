# UsefulNetworkLayer for iOS

### A most useful Network Layer written for iOS Projects.

## Installation

**UsefulNetworkLayer** uses new Swift Package Manager which is easiest way introduced for iOS projects since from the beginning. 

From Xcode simply select `File > Swift Packages > Add Package Dependency...` and paste `https://github.com/exozet/iOSUsefulNetworkLayer` to search field. You can specify rules according to your preferences and you are ready to use. 


## Usage

### Creating a response object

NetworkLayer needs an object which is inherited from `ResponseBodyParsable` class in order to create responses. There is two `required` initializer from that object, whether from the `Data` or JSON object. One of them should return `nil` to give access to other initializer. 

In below, Response object will be created from the JSON response:

```swift
/// Initializes object from JSON response.
class ExampleResponseObject: ResponseBodyParsable {
    
    var userId: Int
    var id: Int
    var title: String
    var completed: Bool
    
    required init?(_ data: Data) {
        return nil
    }
    
    required init?(_ response: Any?) {
        guard let dict = response as? [String:Any] else { return nil }
        guard let userId = dict["userId"] as? Int,
            let id = dict["id"] as? Int,
            let title = dict["title"] as? String,
            let completed = dict["completed"] as? Bool else { return nil }
        
        self.userId = userId
        self.id = id
        self.title = title
        self.completed = completed
        super.init(response)
    }
}
```


Or using data, for instance image, can be created by the data response:

```swift
/// Initializes object from Data.
class ExampleImageObject: ResponseBodyParsable {
    
    var image: UIImage
    
    required init?(_ data: Data) {
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        self.image = image
        super.init(data)
    }
    
    required init?(_ response: Any?) {
        return nil
    }
}
```

### Creating an API configuration

Using highly customizable `APIConfiguration` object, API requests can be defined easily and requests from Network Layer.

In below example, uses `ExampleResponseObject` as a response model to create API configuration with basic parameters. 

```swift
let api = APIConfiguration(hostURL: "https://jsonplaceholder.typicode.com",
                           endPoint: "todos/1",
                           responseBodyObject: ExampleResponseObject.self)

```

Or, advanced parameters can be applied.

```swift
let api = APIConfiguration(hostURL: "https://jsonplaceholder.typicode.com",
                           endPoint: "todos/1",
                           requestType: .get,
                           headers: nil, body: nil,
                           responseBodyObject: ExampleResponseObject.self,
                           priority: .low,
                           cachingTime: .init(seconds: 60),
                           isMainOperation: false, autoCache: false)

```

### Requesting API from Network Layer

When operation is completed, completion block will return with two cases, whether error or successful response.

```swift
guard let apiReq = api else {
    print("Something wrong with the configuration")
    return
}

apiReq.request { (result) in
    switch result {
    case .error(let errResponse):
        print("Error: \(errResponse.error.localizedDescription)")
    case .success(let successfulResponse):
        print("Response Body: \(successfulResponse.responseBody)")
    }
}
```

## Advanced Usage

### Defining AutoCache
In default, responses will be cached by the given `cachingTime` property. However, `ResponseBodyParsable` gives flexibility to define time value dynamically from the object itself. By overriding `cachingEndsAt:` method from the object, new time value for cache expiry can be defined.

In below, same example object overrides the method and uses, for instance one of the variables in the response to define caching expiry. 

```swift
/// Initializes object from JSON response.
class ExampleResponseObject: ResponseBodyParsable {
    
    var userId: Int
    var id: Int
    var title: String
    var completed: Bool
    var expiry: Date?
    
    required init?(_ data: Data) {
        return nil
    }
    
    required init?(_ response: Any?) {
        guard let dict = response as? [String:Any] else { return nil }
        guard let userId = dict["userId"] as? Int,
            let id = dict["id"] as? Int,
            let title = dict["title"] as? String,
            let completed = dict["completed"] as? Bool else { return nil }
        
        self.userId = userId
        self.id = id
        self.title = title
        self.completed = completed
        
        // gets expiry value from the response
        self.expiry = dict["expiry"] as? Date
        
        super.init(response)
    }
    
    override func cachingEndsAt() -> Date? {
        return self.expiry
    }
}
```
Then, in the API configuration, `autoCache` parameter should be set to `true`.
 
### Operation Queues and priority of the requests
`iOSUsefulNetworkLayer` holds two queues, one is called as `main` and the other one as `background`. In default, all request operations will be handled in the `background` queue unless `isMainOperation` property is set to `true`. It effects resource levels in the system level to use more resources, so requests which should needs to get answered and completed as soon as possible can moved into the `main` queue to use more resources from the system. 

In addition, for the each request operation in the same queue will be handled by looking their `priority` specification. In default, all requests are marked as `normal` level, but by using that property more important requests can be moved into top by giving higher priority. 
