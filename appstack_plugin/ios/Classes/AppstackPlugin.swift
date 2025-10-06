import Flutter
import UIKit
import AppstackSDK

public class AppstackPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "appstack_plugin", binaryMessenger: registrar.messenger())
    let instance = AppstackPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      handleConfigure(call: call, result: result)
    case "sendEvent":
      handleSendEvent(call: call, result: result)
    case "enableAppleAdsAttribution":
      handleEnableAppleAdsAttribution(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleConfigure(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let apiKey = args["apiKey"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "API key is required", details: nil))
      return
    }
    
    let isDebug = args["isDebug"] as? Bool ?? false
    let endpointBaseUrl = args["endpointBaseUrl"] as? String
    let logLevel = args["logLevel"] as? Int ?? 1
    
    // Map log level to AppstackSDK.LogLevel
    // SDK supports: .off (0), .error (1), .debug (2), .info (3)
    let sdkLogLevel: AppstackSDK.LogLevel
    switch logLevel {
    case 0:
      sdkLogLevel = .off
    case 1:
      sdkLogLevel = .error
    case 2:
      sdkLogLevel = .debug
    case 3:
      sdkLogLevel = .info
    default:
      sdkLogLevel = .info
    }
    
    // Configure the SDK
    if let endpointBaseUrl = endpointBaseUrl {
      AppstackAttributionSdk.shared.configure(apiKey: apiKey, isDebug: isDebug, endpointBaseUrl: endpointBaseUrl, logLevel: sdkLogLevel)
    } else {
      AppstackAttributionSdk.shared.configure(apiKey: apiKey, isDebug: isDebug, logLevel: sdkLogLevel)
    }
    
    result(true)
  }
  
  private func handleSendEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let eventTypeString = args["eventType"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Event type is required", details: nil))
      return
    }
    
    let eventName = args["eventName"] as? String
    let revenue = args["revenue"] as? Double
    
    // Convert string to EventType
    guard let eventType = stringToEventType(eventTypeString) else {
      result(FlutterError(code: "INVALID_EVENT_TYPE", message: "Invalid event type: \(eventTypeString)", details: nil))
      return
    }
    
    // Send the event
    AppstackAttributionSdk.shared.sendEvent(event: eventType, name: eventName, revenue: revenue)
    
    result(true)
  }
  
  private func handleEnableAppleAdsAttribution(result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      AppstackASAAttribution.shared.enableAppleAdsAttribution()
    }
    result(true)
  }
  
  private func stringToEventType(_ string: String) -> AppstackSDK.EventType? {
    switch string {
    case "INSTALL":
      return .INSTALL
    case "LOGIN":
      return .LOGIN
    case "SIGN_UP":
      return .SIGN_UP
    case "REGISTER":
      return .REGISTER
    case "PURCHASE":
      return .PURCHASE
    case "ADD_TO_CART":
      return .ADD_TO_CART
    case "ADD_TO_WISHLIST":
      return .ADD_TO_WISHLIST
    case "INITIATE_CHECKOUT":
      return .INITIATE_CHECKOUT
    case "START_TRIAL":
      return .START_TRIAL
    case "SUBSCRIBE":
      return .SUBSCRIBE
    case "LEVEL_START":
      return .LEVEL_START
    case "LEVEL_COMPLETE":
      return .LEVEL_COMPLETE
    case "TUTORIAL_COMPLETE":
      return .TUTORIAL_COMPLETE
    case "SEARCH":
      return .SEARCH
    case "VIEW_ITEM":
      return .VIEW_ITEM
    case "VIEW_CONTENT":
      return .VIEW_CONTENT
    case "SHARE":
      return .SHARE
    case "CUSTOM":
      return .CUSTOM
    default:
      return nil
    }
  }
}
