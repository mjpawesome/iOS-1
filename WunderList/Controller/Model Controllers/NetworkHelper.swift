//
//  NetworkHelper.swift
//  App
//
//  Created by Kenny on 2/29/20.
//

import Foundation

protocol NetworkLoader {
    func loadData(using request: URLRequest, with completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void)
}

extension URLSession: NetworkLoader {
    /// Asyncronously load data using a URL Request
    /// - Parameters:
    ///   - request: an unwrapped URLRequest
    ///   - completion: Similar to `URLSession.shared.dataTask`'s completion except the response is downcasted to a HTTPURLResponse or nil
    func loadData(using request: URLRequest, with completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        self.dataTask(with: request) { (data, response, error) in
            completion(data, response as? HTTPURLResponse, error)
        }.resume()
    }
}

class NetworkService {
    ///used to switch between live and Mock Data
    var dataLoader: NetworkLoader

    init(dataLoader: NetworkLoader = URLSession.shared) {
        self.dataLoader = dataLoader
    }

    ///Used to set a`URLRequest`'s HTTP Method
    enum HttpMethod: String {
        case get = "GET"
        case patch = "PATCH"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    /**
     used when the endpoint requires a header-type (i.e. "content-type") be specified in the header
     */
    enum HttpHeaderType: String {
        case contentType = "Content-Type"
    }

    /**
     the value of the header-type (i.e. "application/json")
     */
    enum HttpHeaderValue: String {
        case json = "application/json"
    }

    /**
     - parameter request: should return nil if there's an error or a valid request object if there isn't
     - parameter error: should return nil if the request succeeded and a valid error if it didn't
     */
    struct EncodingStatus {
        let request: URLRequest?
        let error: Error?
    }

    static var df: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }

    /**
     Create a request given a URL and requestMethod (get, post, create, etc...)
     */
    func createRequest(url: URL?, method: HttpMethod, headerType: HttpHeaderType? = nil, headerValue: HttpHeaderValue? = nil) -> URLRequest? {
        guard let requestUrl = url else {
            NSLog("request URL is nil")
            return nil
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.rawValue
        if let headerType = headerType,
            let headerValue = headerValue {
            request.setValue(headerValue.rawValue, forHTTPHeaderField: headerType.rawValue)
        }
        return request
    }

    /**
     Encode from a Swift object to JSON for transmitting to an endpoint and returns an EncodingStatus object which should either contain an error and nil request or request and nil error
     - parameter type: the type to be encoded (i.e. MyCustomType.self)
     - parameter request: the URLRequest used to transmit the encoded result to the remote server
     - parameter dateFormatter: optional for use with JSONEncoder.dateEncodingStrategy
     */
    func encode<T:Encodable>(from type: T, request: inout URLRequest, dateFormatter df: DateFormatter? = nil) -> EncodingStatus {
        let jsonEncoder = JSONEncoder()
        if let df = df {
            jsonEncoder.dateEncodingStrategy = .formatted(df)
        }
        do {
            request.httpBody = try jsonEncoder.encode(type)
        } catch {
            print("Error encoding object into JSON \(error)")
            return EncodingStatus(request: nil, error: error)
        }
        return EncodingStatus(request: request, error: nil)
    }

    func decode<T:Decodable>(to type: T.Type, data: Data, dateFormatter df: DateFormatter? = nil) -> T? {
        let decoder = JSONDecoder()
        if let df = df {
            decoder.dateDecodingStrategy = .formatted(df)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error Decoding JSON into \(String(describing: type)) Object \(error)")
            return nil
        }
    }
}
