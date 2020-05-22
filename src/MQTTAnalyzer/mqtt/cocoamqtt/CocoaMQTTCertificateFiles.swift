//
//  CertificateFiles.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-04-14.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import CocoaMQTT

// Create P12 File by using:
// openssl pkcs12 -export -in user.crt -inkey user.key -out user.p12
func createSSLSettings(host: Host) throws -> [String: NSObject] {
	let clientCertArray = try getClientCertFromP12File(certName: host.certClient, certPassword: host.certClientKeyPassword)
	
	var sslSettings: [String: NSObject] = [:]
	sslSettings[kCFStreamSSLCertificates as String] = clientCertArray
	
	return sslSettings
}

enum CertificateError: String, Error {
	case errorOpenFile = "Failed to open the certificate file"
	case errSecAuthFailed = "Failed to open the certificate file. Wrong password?"
	case noIdentify = "No identity"
}

private func getClientCertFromP12File(certName: String, certPassword: String) throws -> CFArray? {
	var url = CloudDataManager.sharedInstance.getDocumentDiretoryURL()
	url.appendPathComponent(certName)
	
	guard let p12Data = NSData(contentsOf: url) else {
		throw CertificateError.errorOpenFile
	}
	
	// create key dictionary for reading p12 file
	let key = kSecImportExportPassphrase as String
	let options: NSDictionary = [key: certPassword]
	
	var items: CFArray?
	let securityError = SecPKCS12Import(p12Data, options, &items)
	
	guard securityError == errSecSuccess else {
		if securityError == errSecAuthFailed {
			throw CertificateError.errSecAuthFailed
		} else {
			throw CertificateError.errorOpenFile
		}
	}
	
	guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
		return nil
	}
	
	let dictionary = (theArray as NSArray).object(at: 0)
	guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
		throw CertificateError.noIdentify
	}
	
	return [identity] as CFArray
}
