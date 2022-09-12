//
//  TextStyle+PORTL.swift
//  Portl
//
//  Created by Jeff Creed on 3/13/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

extension TextStyle {
	static let h1Bold: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .largeTitle)
		let baseFont = UIFont.systemFont(ofSize: 28.0, weight: .bold)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let h2Bold: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .title1)
		let baseFont = UIFont.systemFont(ofSize: 24.0, weight: .bold)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let h2: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .title1)
		let baseFont = UIFont.systemFont(ofSize: 24.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let h3Bold: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .title2)
		let baseFont = UIFont.systemFont(ofSize: 16.0, weight: .bold)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let h3: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .title2)
		let baseFont = UIFont.systemFont(ofSize: 16.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let bodyBold: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .body)
		let baseFont = UIFont.systemFont(ofSize: 12.0, weight: .bold)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let bodyItalic: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .body)
		let baseFont = UIFont.italicSystemFont(ofSize: 12.0)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let body: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .body)
		let baseFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let bodyInteractive: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .body)
		let baseFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .interactive1, paragraphStyle: .default)
	}()
	
	static let small: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .caption1)
		let baseFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let smallBold: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .caption1)
		let baseFont = UIFont.systemFont(ofSize: 10.0, weight: .bold)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light1, paragraphStyle: .default)
	}()
	
	static let smallLight2: TextStyle = {
		let fontMetrics = UIFontMetrics.init(forTextStyle: .caption1)
		let baseFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
		let font = fontMetrics.scaledFont(for: baseFont)
		
		return TextStyle(font: font, color: .light2, paragraphStyle: .default)
	}()
}
