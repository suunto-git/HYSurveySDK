//
//  HYSurveyService.swift
//  surveySDK
//
//  Created by Winston on 2023/6/26.
//

import Foundation

 /**
  HY Survey Service
  */
public struct HYSurveyConfigService {
    
    public static func authCheck(server: String, accessCode: String, onCallback: Optional<(Bool, String) -> Void> = nil) {
        if (onCallback == nil || accessCode.isEmpty) {
            return;
        }
        
        var url = "\(server)/surveys/init-access-code/\(accessCode)";
        if (!HYGlobalConfig.orgCode.isEmpty) {
            url = "\(server)/surveys/init-access-code/\(HYGlobalConfig.orgCode)/\(accessCode)";
        }
        NSLog("surveySDK->authcheck with url \(url)");
        let task = URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            
            guard let data = data else {
                  return
            }

            do {
                let json: [String : Any] = try JSONSerialization.jsonObject(with: data as Data, options: []) as! [String : Any]
                let code = json["code"] as? NSNumber;
                if (code == 200) {
                    let pass = json["data"] as? Bool;
                    onCallback!(pass ?? false, "");
                } else {
                    let error = json["message"] as? String;
                    onCallback!(false,  error ?? "系统错误");
                    return
                }
            } catch {
                onCallback!(false, "系统异常");
            }
        }
        task.resume();
    }
}
