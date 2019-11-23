//
//  MessageCellView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2019-11-17.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct MessageView : View {
    @ObservedObject var messagesByTopic: MessagesByTopic

    var body: some View {
        Section(header: Text("Messages")) {
            ForEach(messagesByTopic.messages) {
                MessageCellView(message: $0, topic: self.messagesByTopic.topic)
            }
            .onDelete(perform: messagesByTopic.delete)
        }
    }
}

struct MessageCellView : View {
    let message: Message
    let topic: Topic
    
    var body: some View {
        NavigationLink(destination: MessageDetailsView(message: message, topic: topic)) {
            HStack {
                Image(systemName: "radiowaves.right")
                    .font(.subheadline)
                    .foregroundColor(message.isJson() ? .green : .gray)
                
                VStack (alignment: .leading) {
                    Text(message.data)
                        .lineLimit(8)
                    Text(message.localDate())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .contextMenu {
                Button(action: copy) {
                    Text("Copy message")
                    Image(systemName: "doc.on.doc")
                }
            }
        }
    }
        
    func copy() {
        UIPasteboard.general.string = self.message.data
    }
}