//
//  HYSurveyService.swift
//  surveySDK
//
//  Created by Winston on 2023/6/26.
//

import Foundation


public struct SurveyStartResponse {
    let sid: String;
    let cid: String;
    let clientId: String;
    let surveyStatus: String;
    let channelStatus: String;
    let doNotDisturb: Bool;
    let style: Dictionary<String, Any>;
    
    let raw: Dictionary<String, Any>;
    let channel: Dictionary<String, Any>;
    let channelConfig: Dictionary<String, Any>;
    
    public static func fromJson(clientId: String, json: [String: Any]) -> SurveyStartResponse? {
        // 解析 sid
        guard let sid = Util.convertToString(json["id"]) else {
            NSLog("解析 sid 失败")
            return nil
        }
        
        // 提取基础字段
        guard let surveyStatus = json["status"] as? String,
              let doNotDisturb = json["doNotDisturb"] as? Bool,
              let channel = json["channel"] as? [String: Any],
              let style = json["style"] as? [String: Any] else {
            NSLog("基础字段解析失败")
            return nil
        }
        
        // 解析 channel 相关字段
        guard let channelStatus = channel["status"] as? String,
              let channelConfigStr = channel["configure"] as? String,
              let cid = Util.convertToString(channel["id"]) else {
            NSLog("channel 字段解析失败")
            return nil
        }
        
        // 解析 channelConfig
        guard let jsonData = channelConfigStr.data(using: .utf8) else {
            NSLog("channelConfig 字符串转数据失败")
            return nil
        }
        
        do {
            guard let channelConfig = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                NSLog("channelConfig 不是有效的字典类型")
                return nil
            }
            
            // 创建返回对象
            return SurveyStartResponse(
                sid: sid,
                cid: cid,
                clientId: clientId,
                surveyStatus: surveyStatus,
                channelStatus: channelStatus,
                doNotDisturb: doNotDisturb,
                style: style,
                raw: json,
                channel: channel,
                channelConfig: channelConfig
            )
        } catch {
            NSLog("解析 channelConfig 失败: \(error.localizedDescription)")
            return nil
        }
    }
}

 /**
  HY Survey Service
  */
public struct HYSurveyService {
    

    static func encryptData(data: [String: Any]) -> [String: Any] {
        // 检查数据是否为空
        guard !data.isEmpty else {
            return data
        }

        // 获取RSA密钥和AES密钥长度配置
        let rsaKey = HYGlobalConfig.encryptKey
        let digits = HYGlobalConfig.encryptedKeyDigits

        var result: [String: Any] = [:]
        
        // 检查加密是否启用且RSA密钥是否有效
        if HYGlobalConfig.encryptedEnabled, rsaKey.isEmpty {
            return data
        }

        // 生成随机AES密钥
        let aesKey = CryptoUtils.generateKey(length: digits)

        do {
            // 使用RSA加密AES密钥
            let encryptedKey = try CryptoUtils.rsaEncrypt(publicKeyStr: rsaKey, data: aesKey)

            // 将输入数据转换为JSON字符串
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw NSError(domain: "Invalid JSON", code: -1, userInfo: nil)
            }

            // 使用AES加密数据
            let encryptedData = try CryptoUtils.aesEncrypt(data: jsonString, keyStr: aesKey)

            // 将加密结果放入字典中
            result["encryptType"] = "rsa/aes"
            result["encryptedKey"] = encryptedKey
            result["encryptedData"] = encryptedData

            print("encrypt data encrypted")
            return result
        } catch {
            print("encrypt failed: \(error.localizedDescription)")
        }

        return result
    }

    /**
            统一开始
     */
    public static func unionStart(server: String, sendId: String?, surveyId: String?, channelId: String?, parameters: Dictionary<String, Any>, onCallback: Optional<(SurveyStartResponse?, String?) -> Void> = nil) {
        if (onCallback == nil) {
            return;
        }
        if (sendId == nil && (surveyId == nil || channelId == nil)) {
            onCallback!(nil, "参数错误");
            return;
        }

        let url = "\(server)/surveys/union-start";
        let clientId = UUID().uuidString;
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create a dictionary with the data you want to send
        let systemParametersWhiteList = ["externalUserId", "departmentCode", "externalCompanyId", "customerName", "customerGender"];
        var json: [String: Any] = ["clientId": clientId, "collectorMethod": "APP"];
        
        let accessCode  = parameters.index(forKey: "accessCode") != nil ? parameters["accessCode"] as! String : HYGlobalConfig.accessCode
        if (!accessCode.isEmpty)  {
            let additionData: [String: Any] = ["accessCode": accessCode]
            json["additionData"] = additionData
        }

        if (sendId != nil) {
            json["sendToken"] = sendId;
            NSLog("[surveySDK] union start with sendId \(sendId!) clientId \(clientId) server \(server)");
        } else {
            if (surveyId != nil && channelId != nil) {
                json["surveyId"] = surveyId;
                json["channelId"] = channelId;
                
                NSLog("[surveySDK] union start with sid \(surveyId!) cid \(channelId!) clientId \(clientId) server \(server)");
            }
        }
        for item in systemParametersWhiteList {
            if (parameters.index(forKey: item) != nil) {
                json[item] = parameters[item];
            }
        }
        if (parameters.index(forKey: "parameters") != nil) {
            json["parameters"] = parameters["parameters"];
        }
        
        

        // Convert the dictionary to JSON data
        var jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])

        if HYGlobalConfig.encryptedEnabled {
            // 调用加密方法并获取加密后的字典
            let encryptedDataDict = encryptData(data: json)
            // 将加密后的字典转换为JSON数据
            if !encryptedDataDict.isEmpty {
                jsonData = try! JSONSerialization.data(withJSONObject: encryptedDataDict, options: [])
            }
            NSLog("[surveySDK] union start encrypt post data");
        }

        // Set the JSON data as the HTTP body of the request
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data else {
                  return
            }

            do {
                let json: [String : Any] = try JSONSerialization.jsonObject(with: data as Data, options: []) as! [String : Any]
                let code = json["code"] as? NSNumber;
                if (code == 200) {
                    let survey = json["data"] as? [String : Any];
                    if (survey == nil) {
                        onCallback!(nil, "系统错误");
                        return;
                    }
                    let sr = SurveyStartResponse.fromJson(clientId: clientId, json: survey!)
                    
                    if (sr != nil) {
                        if (sr?.doNotDisturb == true) {
                            onCallback!(sr, "开启免打扰配置，该问卷无法打开");
                        } else {
                            let embedPercent = sr?.channelConfig["embedPercent"] as? Int ?? 100
                            if (Util.shouldDisplay(probability: embedPercent)) {
                                onCallback!(sr, nil);
                            } else {
                                // 如果概率判定不弹出直接忽略
                                onCallback!(nil, "显示概率控制忽略显示");
                            }
                        }
                    } else {
                        onCallback!(nil, "参数错误");
                    }
                } else {
                    let error = json["message"] as? String;
                    onCallback!(nil, error);
                    return
                }
            } catch {
                onCallback!(nil, "系统异常");
            }
        }
        task.resume();
    }
}
