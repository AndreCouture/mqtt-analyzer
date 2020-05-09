//
//  HostFormModelUtils.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-02.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation

func copyHost(target: Host, source host: HostFormModel) -> Host? {
	let newHostname = HostFormValidator.validateHostname(name: host.hostname)
	let port = HostFormValidator.validatePort(port: host.port)
	
	if port == nil || newHostname == nil {
		return nil
	}
	
	target.alias = host.alias
	target.hostname = newHostname!
	target.qos = host.qos
	target.auth = host.authType
	target.port = UInt16(port!)
	target.topic = host.topic
	target.clientID = host.clientID
	target.basePath = host.basePath
	target.protocolMethod = host.protocolMethod
	target.ssl = host.ssl
	target.untrustedSSL = host.ssl && host.untrustedSSL
	
	if target.protocolMethod == .websocket {
		target.clientImpl = .cocoamqtt
	}
	else {
		target.clientImpl = host.clientImpl
	}

	if host.authType == .usernamePassword {
		target.username = host.username
		target.password = host.password
	}
	else if host.authType == .certificate {
		target.certServerCA = host.certServerCA
		target.certClient = host.certClient
		target.certClientKey = host.certClientKey
		target.certClientKeyPassword = host.certClientKeyPassword
	}
	
	return target
}

func transformHost(source host: Host) -> HostFormModel {
	return HostFormModel(alias: host.alias,
						 hostname: host.hostname,
						 port: "\(host.port)",
						 basePath: host.basePath,
						 topic: host.topic,
						 qos: host.qos,
						 username: host.username,
						 password: host.password,
						 certServerCA: host.certServerCA,
						 certClient: host.certClient,
						 certClientKey: host.certClientKey,
						 certClientKeyPassword: host.certClientKeyPassword,
						 clientID: host.clientID,
						 limitTopic: "\(host.limitTopic)",
						 limitMessagesBatch: "\(host.limitMessagesBatch)",
						 ssl: host.ssl,
						 untrustedSSL: host.untrustedSSL,
						 protocolMethod: host.protocolMethod,
						 authType: host.auth,
						 clientImpl: host.clientImpl
						)
}
