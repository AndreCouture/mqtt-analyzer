//
//  ContributorsView.swift
//  MQTTAnalyzer
//
//  Created by Philipp Arndt on 2020-05-12.
//  Copyright © 2020 Philipp Arndt. All rights reserved.
//

import SwiftUI

struct ContributorsView: View {
	var body: some View {
		Group {
			Text("Contributors:")
				.font(.headline)
				.padding(.bottom)
			
			Group {
				Text("Thanks for testing, contributing features and ideas.")
				
				ForEach(contributors) { contributor in
					LinkButtonView(text: contributor.name, url: contributor.link)
				}
			}
		}
	}
}
