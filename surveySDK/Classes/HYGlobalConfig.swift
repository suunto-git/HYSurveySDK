//
//  Util.swift
//  surveySDK 
//
//  Created by Winston on 2023/6/26
//

import Foundation

/**
 问卷全局配置b
 */
public class HYGlobalConfig : NSObject {
    static var accessCode : String = "";
    static var orgCode : String = "";
    static var server : String = "https://www.xmplus.cn/api/survey";
    static var authRequired : Bool = false;
    static var verified : Bool = false;
    
    // encryption
    static var encryptedEnabled : Bool = false;
    static var encryptKey : String = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCXXNq8cWVpuY+EHIZ/IMa5Tg2tUutCzkUmjykRKToqtGUOWLLK9V2NiBFWYkTimLp5OSGvvP3SyOBMqXqGFRNjDwXKtMdHYAIJBRbnck3DVpuF5jlBJo0K5uCrAtrqPuccClwAy1V/GwT2ns1A8LgSLjh9A7iJ0rcQqixXo+ttLwIDAQAB";
    static var encryptedKeyDigits : Int = 16;
    
    /**
       全局配置问卷服务器
     */
    @objc public static func setup(server: String) -> Void {
        HYGlobalConfig.server = server;
    }
    
    /**
       全局配置问卷服务器
     */
    @objc public static func setup(server: String, orgCode: String) -> Void {
        HYGlobalConfig.server = server;
        HYGlobalConfig.orgCode = orgCode;
    }

    /**
       全局配置问卷服务器，认证设置
     */
    @objc public static func setup(server: String, orgCode: String, accessCode: String, authRequired: Bool) -> Void {
        HYGlobalConfig.server = server;
        HYGlobalConfig.orgCode = orgCode;
        HYGlobalConfig.accessCode = accessCode;
        HYGlobalConfig.authRequired = authRequired;
        
        if (authRequired && !accessCode.isEmpty) {
            // verify the access code
            HYSurveyConfigService.authCheck(server: server, accessCode: accessCode, onCallback: { pass, error in
                if (pass) {
                    NSLog("auth check passed");
                    HYGlobalConfig.verified = true;
                } else {
                    NSLog("auth check failed \(error)");
                }
            });
        }
    }
    
    /**
       全局配置问卷加密
     */
    @objc public static func configEncrypt(enable: Bool) -> Void {
        HYGlobalConfig.encryptedEnabled = enable;
    }
    
    /**
       全局配置问卷加密
     */
    @objc public static func configEncrypt(enable: Bool, encryptKey: String) -> Void {
        HYGlobalConfig.encryptedEnabled = enable;
        HYGlobalConfig.encryptKey = encryptKey;
    }
    
    @objc public static func check() -> Bool {
        if (HYGlobalConfig.authRequired && !HYGlobalConfig.verified) {
            return false;
        }
        return true;
    }
 
}
