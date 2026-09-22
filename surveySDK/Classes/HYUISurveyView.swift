import os
import UIKit
import WebKit
import JavaScriptCore

class NoInputAccessoryWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        return nil
    }
}

/**
 Survey视图 UIKit版本
 */
public class HYUISurveyView: UIView, WKUIDelegate {
    var server : String = "production"
    var surveyId : String?
    var channelId : String?
    var clientId : String?
    var delay : Int = 1000
    var debug : Bool = false
    var halfscreen : Bool = false
    var showClose : Bool = true
    var showType : String = ""
    var force : Bool = false
    var isDialogMode : Bool = false
    var padding : Int = 0
    var bord : Bool = false
    var parameters : Dictionary<String, Any>?
    var options : Dictionary<String, Any>?
    var style : Dictionary<String, Any>?
    var surveyJson : Dictionary<String, Any>?
    var channelConfig : Dictionary<String, Any>?
    var finished: Bool = false
    var version: String = ""
    var build: String = ""
    var assets: String = ""
    var onSubmit: Optional<() -> Void> = nil
    var onCancel: Optional<() -> Void> = nil
    var onError: Optional<(_ error: String) -> Void> = nil
    var onSize: Optional<(_ height: Int) -> Void> = nil
    var onClose: Optional<() -> Void> = nil
    var onLoad: Optional<(_ config: Dictionary<String, Any>) -> Void> = nil
    var _height: Int?
    var _constraint: NSLayoutConstraint? = nil
    var appPaddingWidth: Int = 0;
    var language : String = "";
    
    @IBOutlet var webView: WKWebView!
    
    
    @objc public func setOnSubmit(callback: @escaping () -> Void) {
        self.onSubmit = callback
    }
    
    @objc public func setOnCancel(callback: @escaping () -> Void) {
        self.onCancel = callback
    }
    
    @objc public func setOnClose(callback: @escaping () -> Void) {
        self.onClose = callback
    }
    
    @objc public func setOnSize(callback: @escaping (_ height: Int) -> Void) {
        self.onSize = callback
    }
    
    @objc public func setOnLoad(callback: @escaping (_ config: Dictionary<String, Any>) -> Void) {
        self.onLoad = callback
    }
    
    @objc public func setOnError(callback: @escaping (_ error: String) -> Void) {
        self.onError = callback
    }
    
    /**
        获取系统推荐语言
     */
    private static func getSystemLanguage() -> String {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let locale = Locale(identifier: preferredLanguage)
            if let languageCode = locale.languageCode, let regionCode = locale.regionCode {
                let languageTag = "\(languageCode)-\(regionCode.lowercased())"
                return languageTag
            }
        }
        return "zh-cn"
    }

    /**
        内部构造SurveyController
     */
    public static func makeSurveyControllerEx(surveyId: String, channelId: String, surveyJson: Optional<Dictionary<String, Any>> = nil, channelConfig: Optional<Dictionary<String, Any>> = nil, clientId: String? = nil, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
        onSubmit: Optional<() -> Void> = nil,
        onCancel: Optional<() -> Void> = nil,
        onSize: Optional<(_ height: Int) -> Void> = nil,
        onClose: Optional<() -> Void> = nil,
        onLoad: Optional<(_: Dictionary<String, Any>) -> Void> = nil,
        onError: Optional<(_ error: String) -> Void> = nil
    ) -> HYUISurveyView {
        let controller = HYUISurveyView()
        controller.surveyId = surveyId
        controller.channelId = channelId
        controller.parameters = parameters
        controller.options = options
        controller.onSubmit = onSubmit
        controller.onSize = onSize
        controller.onCancel = onCancel
        controller.onClose = onClose
        controller.onLoad = onLoad
        controller.onError = onError
        controller.surveyJson = surveyJson
        controller.channelConfig = channelConfig
        controller.clientId = clientId
        
        controller.assets = options.index(forKey: "assets") != nil ? options["assets"] as! String : "";
        controller.delay = options.index(forKey: "delay") != nil ? options["delay"] as! Int : 1000
        controller.padding = options.index(forKey: "padding") != nil ? options["padding"] as! Int : 0
        controller.debug = options.index(forKey: "debug") != nil ? options["debug"] as! Bool: false
        controller.halfscreen = options.index(forKey: "halfscreen") != nil ? options["halfscreen"] as! Bool: false
        controller.showClose = options.index(forKey: "showClose") != nil ? options["showClose"] as! Bool: true
        controller.showType = options.index(forKey: "showType") != nil ? options["showType"] as! String: "embedded"
        controller.force = options.index(forKey: "force") != nil ? options["force"] as! Bool: false
        controller.bord = options.index(forKey: "bord") != nil ? options["bord"] as! Bool: false
        controller.server = options.index(forKey: "server") != nil ? options["server"] as! String : HYGlobalConfig.server
        controller.isDialogMode = options.index(forKey: "isDialogMode") != nil ? options["isDialogMode"] as! Bool: false
        
        controller.language = options.index(forKey: "language") != nil ? options["language"] as! String : getSystemLanguage();
        
        if (surveyJson != nil){
            controller.style = surveyJson!.index(forKey: "style") != nil ? surveyJson!["style"] as! Dictionary : Dictionary();
        }

        controller.setup()
        return controller
    }
    
    @objc public static func makeSurveyController(surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
        onSubmit: Optional<() -> Void> = nil,
        onCancel: Optional<() -> Void> = nil,
        onSize: Optional<(_ height: Int) -> Void> = nil,
        onClose: Optional<() -> Void> = nil,
        onLoad: Optional<(_: Dictionary<String, Any>) -> Void> = nil,
        onError: Optional<(_ error: String) -> Void> = nil
    ) -> HYUISurveyView {
        return makeSurveyControllerEx(surveyId: surveyId, channelId: channelId, surveyJson: nil, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose, onLoad: onLoad, onError: onError)
    }
    
    @objc public static func makeSurveyController(surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
        onSubmit: Optional<() -> Void> = nil,
        onCancel: Optional<() -> Void> = nil,
        onSize: Optional<(_ height: Int) -> Void> = nil,
        onClose: Optional<() -> Void> = nil
    ) -> HYUISurveyView {
        return makeSurveyControllerEx(surveyId: surveyId, channelId: channelId, surveyJson: nil, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose, onLoad: nil, onError: nil)
    }
    
    @objc public static func makeSurveyController(surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
        onSubmit: Optional<() -> Void> = nil,
        onCancel: Optional<() -> Void> = nil,
        onSize: Optional<(_ height: Int) -> Void> = nil,
        onClose: Optional<() -> Void> = nil,
        onError: Optional<(_ error: String) -> Void> = nil
    ) -> HYUISurveyView {
        return makeSurveyControllerEx(surveyId: surveyId, channelId: channelId, surveyJson: nil, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose, onLoad: nil, onError: onError)
    }
    
    @objc public static func makeSurveyControllerAsync(surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                                       onReady: Optional<(_ view: HYUISurveyView) -> Void> = nil,
                                                       onError: Optional<(_ error: String) -> Void> = nil,
                                                       onSubmit: Optional<() -> Void> = nil,
                                                       onCancel: Optional<() -> Void> = nil,
                                                       onSize: Optional<(_ height: Int) -> Void> = nil,
                                                       onClose: Optional<() -> Void> = nil
    ) -> Void {
        makeSurveyControllerAsync(surveyId: surveyId, channelId: channelId, parameters: parameters, options: options, onReady: onReady, onError: onError, onSubmit: onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose, onLoad: nil)
    }
    
    /**
        根据sid,cid弹出问卷
     */
    @objc public static func makeSurveyControllerAsync(surveyId: String, channelId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                                       onReady: Optional<(_ view: HYUISurveyView) -> Void> = nil,
                                                       onError: Optional<(_ error: String) -> Void> = nil,
                                                       onSubmit: Optional<() -> Void> = nil,
                                                       onCancel: Optional<() -> Void> = nil,
                                                       onSize: Optional<(_ height: Int) -> Void> = nil,
                                                       onClose: Optional<() -> Void> = nil,
                                                       onLoad: Optional<(_: Dictionary<String, Any>) -> Void> = nil
                                                           ) -> Void {
        
        if (onReady == nil || onError == nil) {
            NSLog("onReady and onError is required in async call")
            return;
        }
        
        if (!HYGlobalConfig.check()) {
            NSLog("surveySDK->global access code is not ready or invalid");
            if (onError != nil) {
                onError!("global access code is not ready or invalid");
            }
            return;
        }
        
        let server = options.index(forKey: "server") != nil ? options["server"] as! String : HYGlobalConfig.server

        HYSurveyService.unionStart(server: server, sendId: nil, surveyId: surveyId, channelId: channelId, parameters: parameters, onCallback: { sr, error in
            if (sr != nil && error == nil) {
                DispatchQueue.main.async {
                    let view : HYUISurveyView = makeSurveyControllerEx(surveyId: sr!.sid, channelId: sr!.cid, surveyJson: sr!.raw, channelConfig: sr!.channelConfig, clientId: sr!.clientId, parameters: parameters, options: options, onSubmit: onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose, onLoad: onLoad, onError: onError)
                    onReady!(view);
                }
            } else {
                onError!(error!);
            }
        })
    }
    
    /**
     根据SendId弹出问卷
     */
    @objc public static func makeSurveyControllerAsync(sendId: String, parameters: Dictionary<String, Any>, options: Dictionary<String, Any>,
                                                       onReady: Optional<(_ view: HYUISurveyView) -> Void> = nil,
                                                       onError: Optional<(_ error: String) -> Void> = nil,
                                                       onSubmit: Optional<() -> Void> = nil,
                                                       onCancel: Optional<() -> Void> = nil,
                                                       onSize: Optional<(_ height: Int) -> Void> = nil,
                                                       onClose: Optional<() -> Void> = nil
    ) -> Void {
        if (onReady == nil || onError == nil) {
            NSLog("onReady and onError is required in async call")
            return;
        }
        if (!HYGlobalConfig.check()) {
            NSLog("surveySDK->global access code is not ready or invalid");
            if (onError != nil) {
                onError!("global access code is not ready or invalid");
            }
            return;
        }
        let server = options.index(forKey: "server") != nil ? options["server"] as! String : HYGlobalConfig.server
        HYSurveyService.unionStart(server: server, sendId: sendId, surveyId: nil, channelId: nil, parameters: parameters, onCallback: { sr, error in
            if (sr != nil && error == nil) {
                DispatchQueue.main.async {
                    let view : HYUISurveyView = HYUISurveyView.makeSurveyControllerEx(surveyId: sr!.sid, channelId: sr!.cid, surveyJson: sr?.raw, channelConfig: sr?.channelConfig,  clientId: sr?.clientId,  parameters: parameters, options: options, onSubmit:  onSubmit, onCancel: onCancel, onSize: onSize, onClose: onClose)

                    onReady!(view);
                }
            } else {
                onError!(error!);
            }

        })
    }
    
    /**
     加载资源文件
     */
    private func loadFile(res: String, ex: String) -> URL? {
        #if SWIFT_PACKAGE
        let myBundle = Bundle.module
        #else
        let myBundle = Bundle(for: Self.self)
        #endif
        let path = myBundle.url(forResource: res, withExtension: ex, subdirectory: self.assets)
        return path
    }
    
    /**
     创建组件
     */
    @objc public func setup() {
//        let parentHeight = Int(self.layer.frame.height);
        let parentWidth = Int(UIScreen.main.bounds.width);
        if (self.channelConfig != nil) {
            self.appPaddingWidth = Util.parsePx(value: Util.optString(config: self.channelConfig!, key: "appPaddingWidth", fallback: "0px"), max: parentWidth);
        }

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.userContentController.add(self, name: "surveyProxy")
        configuration.userContentController.add(self, name: "error")
        if debug {
//            configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
            configuration.userContentController.add(self, name: "logger")
        }
        
        if (self.webView != nil) {
            NSLog("already setup skip!")
            return
        }
        
        self.webView = WKWebView(frame: self.frame, configuration: configuration)

        self.webView.navigationDelegate = self;
        self.webView.uiDelegate = self;
        if debug {
            if #available(iOS 16.4, *) {
                self.webView.isInspectable = true
            } else {
                // Fallback on earlier versions
            };
        }
        
        webView.isOpaque = false;
        var backgroundColor:UIColor = UIColor.clear;
        if (style != nil) {
            let backgroundColorStr = style!.index(forKey: "backgroundColor") != nil ? style!["backgroundColor"] as! String : "#FFFFFF";
            let showBackground = style!.index(forKey: "showBackground") != nil ? style!["showBackground"] as! Bool : false;
            if (showBackground) {
                backgroundColor = Util.colorFromHex(backgroundColorStr);
            }
        }
        webView.backgroundColor = backgroundColor;
        self.backgroundColor = UIColor.clear;


        if let path = loadFile(res: "version", ex: "json")
        {
            if let data = NSData(contentsOf: path) {
                do {
                    do {
                        let dict = try JSONSerialization.jsonObject(with: data as Data, options: []) as? [String : Any]
                        self.version = (dict!["version"] as! String)
                        self.build = (dict!["build"] as! String)
                        self.webView.customUserAgent =  "surveySDK/\(version) (iOS)"
                    } catch {
                        NSLog(error.localizedDescription)
                    }
                    
                }
            }
        }
        var indexURL = loadFile(res: "index", ex: "html")
        if force {
            let timestamp = Int(NSDate().timeIntervalSince1970)
            indexURL = URL(string: "\(indexURL!.absoluteString)#/pages/bridge?_t=\(timestamp)")
            URLCache.shared.removeAllCachedResponses()
        } else {
            indexURL = URL(string: "\(indexURL!.absoluteString)#/pages/bridge?")
        }
//        NSLog("load: \(String(describing: indexURL?.absoluteURL))")
                
        self.webView.isUserInteractionEnabled = true
        self.webView.scrollView.isScrollEnabled = true
        self.webView.scrollView.bounces = false
        self.webView.frame.size.height = CGFloat(0)
        self.webView.scrollView.alwaysBounceVertical = false
        self.webView.scrollView.alwaysBounceHorizontal = false
        //self.webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.webView)
        
    
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: CGFloat(appPaddingWidth)),
            webView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: CGFloat(-1 * appPaddingWidth)),
            webView.topAnchor.constraint(equalTo: self.topAnchor, constant: CGFloat(0)),
            webView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: CGFloat(0))])

        self._constraint = self.heightAnchor.constraint(equalToConstant: CGFloat(0))
        self._constraint?.priority = UILayoutPriority(100)
        self._constraint?.isActive = true

//        self.webView.load(URLRequest(url: URL(string: "http://192.168.50.63:8080/#/pages/bridge")!));
        self.webView.loadFileURL(indexURL!, allowingReadAccessTo: indexURL!.deletingLastPathComponent());

    }
    

    
    
    deinit {
    }

    /**
     获取版本号
     */
    @objc public func getVersion() -> String {
        return self.version;
    }
    
    /**
     获取版本构建号
     */
    @objc public func getBuild() -> String {
        return self.build;
    }

    /**
    显示
     */
    @objc public func show() {
        if finished {
            self.webView.reload()
        }
        self.webView.evaluateJavaScript("document.dispatchEvent(new CustomEvent('show'))")
    }
    
    // 临时添加 cancel() 方法，避免崩溃并定位调用
    @objc func cancel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return } // 避免循环引用导致的释放问题
            NSLog("⚠️ 检测到调用了 cancel() 方法，来源：\(Thread.callStackSymbols)")
            self.onCancel?()
            self.removeFromSuperview()
            self.onClose?()
        }
    }


    // KVO 回调
//    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        if keyPath == "contentSize", let scrollView = object as? UIScrollView {
//            let newSize = scrollView.contentSize
//            print("New content size: \(newSize)")
//            // 这里可以根据 newSize 做进一步处理onSize:
//        }
//    }

//    deinit {
//        // 移除观察者
//        // webView.scrollView.removeObserver(self, forKeyPath: "contentSize")
//    }
    
}

/**
 Webview扩展
 */
extension HYUISurveyView: WKNavigationDelegate, WKScriptMessageHandler {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("survey page start load")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("survey page load finished")
//        print("Content Size: \(webView.scrollView.contentSize)")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("survey page load fail \(error.localizedDescription)")
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("survey page load fail provision \(error.localizedDescription)")
        if (onClose != nil) {
            onClose!()
        }
    }
    
        
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async {
            if message.name == "logger" {
                NSLog("[surveySDK] log: \(message.body)")
            } else if message.name == "error" {
                NSLog("[surveySDK] error: \(message.body)")
            } else if message.name == "surveyProxy"  {
                if self.debug {
                    NSLog("[surveySDK] proxy: \(message.body)")
                }
                let msg = message.body as? String
                let event = try! JSONSerialization.jsonObject(with: msg!.data(using: .utf8)!, options: []) as? [String: Any]
                let type = event?["type"]! as? String
                if type == "size" {
                    if (self.superview != nil) {
                        let value = event?["value"]! as? [String: Any]
                        var height = Int(value?["height"]! as! Double)
                        let width = Int(value?["width"]! as! Double)
                        
                        height = min(Int(UIScreen.main.bounds.height) - 100, height);
                        if (width == 0) {
                            return
                        }
                        //                    self.frame.size.height = CGFloat(height)
                        
                        if (self._constraint != nil) {
                            //                            self.webView.scrollView.contentSize.height = CGFloat(height);
                            self._constraint?.constant = CGFloat(height);
                            self.webView.layoutIfNeeded();
                            //                        superview?.updateConstraintsIfNeeded();
                            //                        superview?.layoutIfNeeded();
                            //                        superview?.layoutSubviews();
                            //                        superview?.sizeToFit();
                        }
                        self.layoutIfNeeded();
                        
                        if self.onSize != nil {
                            //                        NSLog("onSize \(height)")
                            self.onSize!(height)
                        }
                    } else {
                        NSLog("[surveySDK] seems no superview")
                    }
                } else if type == "close" {
                    self.frame.size.height = CGFloat(0)
                    //                self.superview?.frame.size.height = CGFloat(0)
                    self.webView.removeFromSuperview()
                    self.removeFromSuperview()
                    if self.onClose != nil {
                        self.onClose!()
                    }
                } else if type == "submit" {
                    self.finished = true
                    if self.onSubmit != nil {
                        self.onSubmit!()
                    }
                } else if type == "loadfailed" {
                    let error = event?["error"]! as? String ?? "survey load failed error"
                    NSLog("[surveySDK] load failed: \(error)")
                    self.frame.size.height = CGFloat(0)
                    self.webView.removeFromSuperview()
                    self.removeFromSuperview()
                    if self.onError != nil {
                        self.onError!(error);
                    }
                } else if type == "load" {
                    //embedBackGround, embedHeightMode, embedVerticalAlign
//                    print("Content Size: \(self.webView.scrollView.contentSize)")
                    var config : [String: Any] = [:];
                    if (event?["configure"] != nil) {
                        config = (event?["configure"]! as? [String: Any])!;
                    }
                    let parentWidth = Int(self.layer.frame.width);
//                    let parentHeight = Int(self.layer.frame.height);
                    let appBorderRadius = Util.parsePx(value: Util.optString(config: config, key: "appBorderRadius", fallback: "0px"), max: parentWidth);
                    self.appPaddingWidth = Util.parsePx(value: Util.optString(config: config, key: "appPaddingWidth", fallback: "0px"), max: parentWidth);
                    let embedVerticalAlign = Util.optString(config: config, key: "embedVerticalAlign", fallback: "CENTER");
//
                    if (appBorderRadius > 0) {
                        self.webView.clipsToBounds = true;
                        self.webView.layer.cornerRadius = CGFloat(appBorderRadius);
                        
                        if (self.isDialogMode) {
                            switch embedVerticalAlign {
                                case "TOP":
                                    self.webView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner];
                                    break;
                                case "BOTTOM":
                                    self.webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
                                    break;
                                default:
                                    self.webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner];
                            }
                        } else {
                            self.webView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner];
                        }
                 
                    }
                                    
                    if self.onLoad != nil {
                        self.onLoad!(config);
                    }
                    
                } else if type == "cancel" {
                    if self.onCancel != nil {
                        self.onCancel!()
                    }
                    self.frame.size.height = CGFloat(0)
    //                self.superview?.frame.size.height = CGFloat(0)
    //                self.webView.removeFromSuperview()
                    self.removeFromSuperview()
                    if self.onClose != nil {
                        self.onClose!()
                    }
                } else if type == "init" {
                    var data = ["language": self.language,  "server": self.server, "surveyId": self.surveyId!, "channelId": self.channelId!, "delay": self.delay,  "halfscreen": self.halfscreen, "showType": self.showType, "parameters": self.parameters!, "showClose": self.showClose] as [String: Any]
                    if (self.clientId != nil) {
                        data["clientId"] = self.clientId;
                    }
                    if (self.surveyJson != nil) {
                        data["survey"] = self.surveyJson;
                    }
                    if HYGlobalConfig.encryptedEnabled {
                        data["isEncrypted"] = true;
                        data["encryptKey"] = HYGlobalConfig.encryptKey;
                    }
                    let jsonData = try? JSONSerialization.data(withJSONObject: data)
                    let jsonText = String.init(data: jsonData!, encoding: String.Encoding.utf8)
                    self.webView.evaluateJavaScript("document.dispatchEvent(new CustomEvent('init', { detail:  \(jsonText!)}))")
                }
            } else {
                NSLog("unexpected message received \(message.body)")
            }
        }
    }
}

