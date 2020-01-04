//
//  HostsView.swift
//  SwiftUITest
//
//  Created by Philipp Arndt on 2019-06-28.
//  Copyright © 2019 Philipp Arndt. All rights reserved.
//

import SwiftUI

enum HostsSheetType {
	case none
	case about
	case createHost
}

struct HostsView: View {
	@EnvironmentObject var model: RootModel
	@ObservedObject var hostsModel: HostsModel

	@State var presented = false
	@State var sheetType: HostsSheetType = .none

	var body: some View {
		NavigationView {
			VStack(alignment: .leading) {
				List {
					ForEach(hostsModel.hosts) { host in
						HostCellView(host: host, messageModel: (
							self.model.getMessageModel(host)
						))
					}
					.onDelete(perform: self.delete)
				}
			}
			.navigationBarItems(
				leading: Button(action: showAbout) {
					Text("About")
				},
				trailing: Button(action: createHost) {
					Image(systemName: "plus")
				}
				.font(.system(size: 22))
				.buttonStyle(ActionStyleTrailing())
			)
			.navigationBarTitle(Text("Servers"), displayMode: .inline)
		}
		.sheet(isPresented: $presented, onDismiss: { self.presented=false}, content: {
			HostsViewSheetDelegate(model: self.model,
								   hostsModel: self.hostsModel,
								   presented: self.$presented,
								   sheetType: self.$sheetType)
		})
		
	}
	
	func delete(at indexSet: IndexSet) {
		hostsModel.delete(at: indexSet, persistence: model.persistence)
	}
	
	func createHost() {
		sheetType = .createHost
		presented = true
	}
	
	func showAbout() {
		sheetType = .about
		presented = true
	}
}

struct HostsViewSheetDelegate: View {
	let model: RootModel
	let hostsModel: HostsModel

	@Binding var presented: Bool
	@Binding var sheetType: HostsSheetType

	var body: some View {
		Group {
			if self.sheetType == .createHost {
				NewHostFormModalView(closeHandler: { self.presented = false },
									 root: self.model,
									 hosts: self.hostsModel)
			}
			else if self.sheetType == .about {
				AboutView(isPresented: self.$presented)
			}
		}
	}
}
