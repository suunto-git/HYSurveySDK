import Foundation
import CommonCrypto

class CryptoUtils {
    
    // 生成随机的AES密钥
    static func generateKey(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        var key = ""
        for _ in 0..<length {
            let randomIndex = Int(arc4random_uniform(UInt32(characters.count)))
            key.append(characters[characters.index(characters.startIndex, offsetBy: randomIndex)])
        }
        return key
    }
    
    // AES加密
    static func aesEncrypt(data: String, keyStr: String) throws -> String {
            let keyData = Data(keyStr.utf8)
            let ivData = Data(keyStr.utf8) // 使用密钥作为IV

            guard let dataToEncrypt = data.data(using: .utf8) else {
                throw NSError(domain: "Invalid data", code: -1, userInfo: nil)
            }

            // 创建临时缓冲区来存储加密结果
            let encryptedDataLength = dataToEncrypt.count + kCCBlockSizeAES128
            var numBytesEncrypted: size_t = 0
            var encryptedData = Data(count: encryptedDataLength)

            // 执行加密操作，并使用临时缓冲区存储结果
            let cryptStatus = encryptedData.withUnsafeMutableBytes { encryptedBytes in
                dataToEncrypt.withUnsafeBytes { dataBytes in
                    ivData.withUnsafeBytes { ivBytes in
                        keyData.withUnsafeBytes { keyBytes in
                            CCCrypt(CCOperation(kCCEncrypt),
                                    CCAlgorithm(kCCAlgorithmAES),
                                    CCOptions(kCCOptionPKCS7Padding),
                                    keyBytes.baseAddress, kCCKeySizeAES128,
                                    ivBytes.baseAddress,
                                    dataBytes.baseAddress, dataToEncrypt.count,
                                    encryptedBytes.baseAddress, encryptedDataLength,
                                    &numBytesEncrypted)
                        }
                    }
                }
            }

            guard cryptStatus == kCCSuccess else {
                throw NSError(domain: "Encryption failed", code: Int(cryptStatus), userInfo: nil)
            }

            // 调整加密后的数据长度
            encryptedData.removeSubrange(numBytesEncrypted..<encryptedData.count)

            // 返回 Base64 编码的加密数据
            return encryptedData.base64EncodedString()
    }
    
    // RSA加密
    static func rsaEncrypt(publicKeyStr: String, data: String) throws -> String {
        let base64EncodedData = data.data(using: .utf8)?.base64EncodedString() ?? ""
        
        let keyString = publicKeyStr
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        
        guard let keyData = Data(base64Encoded: keyString) else {
            throw NSError(domain: "Invalid public key", code: -1, userInfo: nil)
        }
        
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: 1024
        ]
        
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        guard let dataToEncrypt = base64EncodedData.data(using: .utf8) else {
            throw NSError(domain: "Invalid data", code: -1, userInfo: nil)
        }
        
        var encryptedData = Data(count: SecKeyGetBlockSize(publicKey))
        var encryptedDataLength = encryptedData.count
        
        let status = encryptedData.withUnsafeMutableBytes { encryptedBytes in
            dataToEncrypt.withUnsafeBytes { dataBytes in
                SecKeyEncrypt(publicKey, SecPadding.PKCS1, dataBytes.baseAddress!, dataToEncrypt.count, encryptedBytes.baseAddress!, &encryptedDataLength)
            }
        }
        
        guard status == errSecSuccess else {
            throw NSError(domain: "RSA Encryption failed", code: Int(status), userInfo: nil)
        }
        
        encryptedData.count = encryptedDataLength
        return encryptedData.base64EncodedString()
    }
}
