//
//  MQTTSession.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-01-06.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import Foundation
import Combine
import Moscapsule

let connectionRefused = "Connection refused"

class MqttClientMoscapsule: MqttClient {
	
	let utils = MqttClientSharedUtils()

	let sessionNum: Int
	let model: MessageModel
	let host: Host
	var mqtt: MQTTClient?
	
	var connectionState = ConnectionState()
	
	var connectionAlive: Bool {
		self.mqtt != nil || connectionState.connected
	}
	
	let messageSubject = MsgSubject<MQTTMessage>()
		
	class func setup() {
		// Init is necessary to provide SSL/TLS functions.
		moscapsule_init()
	}
	
	init(host: Host, model: MessageModel) {
		ConnectionState.sessionNum += 1
		
		self.model = model
		self.sessionNum = ConnectionState.sessionNum
		self.host = host
	}
	
	func connect() {
		print("CONNECTION: connect \(sessionNum) \(host.hostname) \(host.topic)")
		host.connectionMessage = nil
		host.connecting = true
		connectionState.connectionFailed = nil
		connectionState.connecting = true
		
		model.limitMessagesPerBatch = host.limitMessagesBatch
		model.limitTopics = host.limitTopic
		
		let mqttConfig = MQTTConfig(clientId: host.computeClientID, host: host.hostname, port: Int32(host.port), keepAlive: 60)
		mqttConfig.onConnectCallback = onConnect
		mqttConfig.onDisconnectCallback = onDisconnect
		mqttConfig.onMessageCallback = onMessage

		if host.auth == .usernamePassword {
			let username = host.usernameNonpersistent ?? host.username
			let password = host.passwordNonpersistent ?? host.password
			mqttConfig.mqttAuthOpts = MQTTAuthOpts(username: username, password: password)
		}
		else if host.auth == .certificate {
			let result = initCertificates(host: host, config: mqttConfig)
			if !result.0 {
				DispatchQueue.main.async {
					self.host.connecting = false
					self.host.connectionMessage = result.1
				}
				return
			}
		}
		
		// create new MQTT Connection
		mqtt = MQTT.newConnection(mqttConfig)

		waitConnected()
		
		let queue = DispatchQueue(label: "Message dispache queue")
		messageSubject.cancellable = messageSubject.subject.eraseToAnyPublisher()
			.collect(.byTime(queue, 0.5))
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: {
				self.onMessageInMain(messages: $0)
			})
	}
	
	func disconnect() {
		print("CONNECTION: disconnect \(sessionNum) \(host.hostname) \(host.topic)")
		
		messageSubject.cancel()
		
		if let mqtt = self.mqtt {
			mqtt.unsubscribe(host.topic)
			mqtt.disconnect()
			
			utils.waitDisconnected(sessionNum: sessionNum, state: self.connectionState)
			
			print("CONNECTION: disconnected \(sessionNum) \(host.hostname) \(host.topic)")
		}
		setDisconnected()
	}
		
	func waitConnected() {
		
		let group = DispatchGroup()
		group.enter()

		DispatchQueue.global().async {
			var i = 10
			while self.connectionState.isConnecting && i > 0 {
				print("CONNECTION: waiting... \(self.sessionNum) \(i) \(self.host.hostname) \(self.host.topic)")
				sleep(1)
				
				self.setConnectionMessage(message: "Connecting... \(i)")

				i-=1
			}
			group.leave()
		}

		group.notify(queue: .main) {
			if let errorMessage = self.connectionState.connectionFailed {
				self.setDisconnected()
				self.host.connectionMessage = errorMessage
				return
			}
			
			if !self.host.connected {
				self.setDisconnected()
				
				self.setConnectionMessage(message: "Connection timeout")
			}
		}
	}
	
	func setConnectionMessage(message: String) {
		DispatchQueue.global(qos: .userInitiated).async {
			DispatchQueue.main.async {
				self.host.connectionMessage = message
			}
		}
	}
		
	func setDisconnected() {
		connectionState.connected = false
		connectionState.connecting = false
		
		DispatchQueue.main.async {
			self.host.connecting = false
		}
		messageSubject.disconnected()
		mqtt = nil
	}
	
	func onConnect(_ returnCode: ReturnCode) {
		print("CONNECTION: onConnect \(sessionNum) \(host.hostname) \(host.topic)")
		connectionState.connected = true
		NSLog("Connected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.connecting = false
			self.host.connected = true
		}
		
		subscribeToTopic(host)
	}
	
	func onDisconnect(_ returnCode: ReasonCode) {
		print("CONNECTION: onDisconnect \(sessionNum) \(host.hostname) \(host.topic)")
		
 		if returnCode == .mosq_conn_refused {
			NSLog(connectionRefused)
			connectionState.connectionFailed = connectionRefused
			DispatchQueue.main.async {
				self.host.usernameNonpersistent = nil
				self.host.passwordNonpersistent = nil
				self.host.connectionMessage = connectionRefused
			}
		}
		else {
			connectionState.connectionFailed = returnCode.description
			DispatchQueue.main.async {
				self.host.connectionMessage = returnCode.description
			}
		}

		self.setDisconnected()
		
		NSLog("Disconnected. Return Code is \(returnCode.description)")
		DispatchQueue.main.async {
			self.host.pause = false
			self.host.connected = false
		}
	}
	
	func onMessage(_ message: MQTTMessage) {
		if !host.pause {
			messageSubject.send(message)
		}
	}
	
	func onMessageInMain(messages: [MQTTMessage]) {
		if host.pause {
			return
		}
		let date = Date()
		let mapped = messages.map({ (message: MQTTMessage) -> Message in
			let messageString = message.payloadString ?? ""
			return Message(data: messageString,
							  date: date,
							  qos: message.qos,
							  retain: message.retain,
							  topic: message.topic
			)
		})
		self.model.append(messages: mapped)
	}
	
	func subscribeToTopic(_ host: Host) {
		mqtt?.subscribe(host.topic, qos: Int32(host.qos))
	}
	
	func publish(message: Message) {
		mqtt?.publish(string: message.data, topic: message.topic, qos: message.qos, retain: message.retain)
	}
}
