//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-22.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct TopicsView: View {
    @EnvironmentObject var rootModel: RootModel
    @ObservedObject var model: MessageModel
    @ObservedObject var host: Host
	@State private var postMessagePresented = false

    var body: some View {
        List {
            ReconnectView(host: self.host)
            
            TopicsToolsView(model: self.model)
            
            Section(header: Text("Topics")) {
                if model.displayTopics.isEmpty {
                    Text("no topics available")
                        .foregroundColor(.secondary)
                }
                else {
                    ForEach(model.displayTopics) { messages in
						TopicCellView(
							messages: messages,
							model: self.model,
							postMessagePresented: self.$postMessagePresented,
							selectMessage: self.selectMessage)
                    }
                }
            }
        }
        .navigationBarTitle(Text(host.topic), displayMode: .inline)
        .listStyle(GroupedListStyle())
        .onAppear {
            self.rootModel.connect(to: self.host)
        }
		.sheet(isPresented: $postMessagePresented, onDismiss: cancelPostMessageCreation, content: {
            PostMessageFormModalView(cancelCallback: self.cancelPostMessageCreation,
                                 root: self.rootModel,
								 model: self.createPostFormModel())
        })
    }
	
    func cancelPostMessageCreation() {
        postMessagePresented = false
		rootModel.selectedMessage = nil
    }
	
	func selectMessage(message: Message) {
		rootModel.selectedMessage = message
	}
	
	func createPostFormModel() -> PostMessageFormModel {
		if let selected = rootModel.selectedMessage {
			return PostMessageFormModel.of(message: selected)
		}
		return PostMessageFormModel()
	}

}

#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
