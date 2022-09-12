//
//  TermsViewController.swift
//  Portl
//
//  Created by Jeff Creed on 6/7/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil

class TermsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	
	// MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return termsParagraphs.count + (isModal ? 1 : 0)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == termsParagraphs.count {
			let cell = tableView.dequeue(ActionTableViewCell.self, for: indexPath)
			cell.actionLabel.text = "OK"
			return cell
		} else {
			let cell = tableView.dequeue(ParagraphTableViewCell.self, for: indexPath)
			cell.configure(withText: termsParagraphs[indexPath.row])
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = tableView.dequeue(WhiteLabelSectionHeaderView.self)
		header.label.text = sectionLabels[section]
		return header
	}
	
	// MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		if indexPath.row == termsParagraphs.count {
			onBack()
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableView.automaticDimension
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 50.0
	}
	
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.registerNib(WhiteLabelSectionHeaderView.self)
		tableView.contentInset = UIEdgeInsets(top: 40.0, left: 0.0, bottom: 0.0, right: 0.0)
		
        let backItem = UIBarButtonItem(image: UIImage(named: "icon_arrow_left"), style: .plain, target: self, action: #selector(onBack))
        backItem.tintColor = .white
        navigationItem.leftBarButtonItem = backItem
        
        navigationItem.titleView = UIImageView(image: UIImage(named:"navbar_logo")!)
    }
        
    // MARK: Navigation
    
    @IBAction private func onBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: Properties
    
    @objc var isModal = false
    
    // MARK: Properties (Private)
	
	@IBOutlet private weak var tableView: UITableView!
	
	private let sectionLabels = ["TERMS OF SERVICE"]
	
	private let termsParagraphs = ["PORTL TERMS OF SERVICE",
						   "These Terms of Service (TOS) constitute a binding agreement between PORTL LLC and you, as a user/visitor of our mobile application and/or website, regardless whether or not you join PORTL by providing your email address and setting a password. The TOS governs all use of this website and all content, services and products available at or through this website.",
						   "The PORTL mobile application and website are offered subject to your acceptance without modification of all of the terms and conditions contained in the TOS, our privacy policy, and all other operating rules, policies, and procedures that we may publish from time to time through our website and mobile application.",
						   "Please read the TOS carefully before accessing or using this mobile application or website. By accessing or using any part of this mobile application and website, you agree to and are bound by the TOS. If you do not agree to all the terms and conditions of the TOS, then you are not permitted to access this mobile application or website or to access or use any content, services, and products available on or through this website. If these terms and conditions were construed as an offer by us, acceptance is expressly limited to these terms.",
						   "• Not Offered to Children Under 13 Years Old. The PORTL mobile application and website are only offered and made available to individuals who are at least 13 years old.",
						   "• If You Join This Mobile Application or Website. If you join PORTL, and create a member account, you are responsible for maintaining the security of your account, and you are fully responsible for all activities that occur under the account and any other actions taken in connection with it. You must immediately notify us of any unauthorized uses of your account or any other breaches of security. We will not be liable for any acts or omissions by you, including any damages of any kind incurred as a result of such acts or omissions. You must not name or use your account in a manner intended to mislead anyone into believing you are person other than yourself.",
						   "• If You Provide Content to This Mobile Application or Website. If you post a comment, or post or upload material or links to this website, or otherwise make (or allow anyone else to use your account to make) material available by means of this website (any such material, “Content”), you are entirely responsible for the content of, and any harm resulting from, that Content. That is the case regardless of whether the Content in question constitutes text, graphics, an audio file, or computer software. By making Content available, you represent and warrant that:",
						   "• the downloading, copying and use of the Content will not infringe the proprietary rights, including but not limited to the copyright, patent, trademark or trade secret rights, of any third party;",
						   "• if your employer has rights to intellectual property you create, you have either (i) received permission from your employer to post or make available the Content, including but not limited to any software, or (ii) secured from your employer a waiver as to all rights in or to the Content;",
						   "• you have fully complied with any third-party licenses relating to the Content, and have done all things necessary to successfully pass through to end users any required terms;",
						   "• the Content does not contain or install any viruses, worms, malware or other harmful or destructive content;",
						   "• the Content is not spam, is not machine- or randomly-generated, and does not contain unethical or unwanted commercial content designed to drive traffic to third party sites or boost the search engine rankings of third party sites, or to further unlawful acts (such as phishing), or to mislead recipients as to the source of the material (such as spoofing);",
						   "• the Content is not pornographic, libelous or defamatory (more info on what that means), does not contain threats or incite violence towards individuals or entities, and does not violate the privacy or publicity rights of any third party;",
						   "• you do not, in any way that is connected or related to this website, send unwanted electronic messages such as spam links on newsgroups, email lists, blogs and web sites, and similar unsolicited promotional methods;",
						   "• your Content must not mislead others into thinking that you are a person other than yourself; and",
						   "• you have, in the case of Content that includes computer code, accurately described the type, nature, uses and effects of the materials.",
						   "By submitting Content to us for inclusion on this mobile application and website, you grant us a world-wide, royalty-free, non-exclusive, sub-licensable, and transferable license to reproduce, modify, adapt and publish the Content for any purpose.",
						   "You also grant PORTL a world-wide, royalty-free, non-exclusive, sub-licensable, and transferable license to reproduce, modify, adapt and publish the Content for any purpose, including but not limited to the purpose of displaying the Content on the PORTL mobile application or website.",
						   "Without limiting any of those representations or warranties, we have the right (though not the obligation) to, in our sole discretion (i) refuse or remove any content that, in our reasonable opinion, violates this TOS or any of our policies, or is in any way harmful or objectionable, or (ii) terminate or deny access to and use of this website to any individual or entity for any reason, in our sole discretion. We will have no obligation to provide a refund of any amounts previously paid.",
						   "• Fees and Payment. Certain paid services or products may be available from time to time on this mobile application or website. The terms and conditions applicable to any paid services or products will be as set forth on this mobile application or website in connection with that paid service or product. Payments are not refundable.",
						   "• Responsibility of Application Users and Website Visitors. We have not necessarily reviewed all of the material posted on or linked through this mobile application or website, and we are not responsible for that material’s content, use or effects. We do not represent or imply that we endorse the material posted on or linked through PORTL, or that we believe all such material to be accurate, useful or non-harmful. You are responsible for taking precautions as necessary to protect yourself and your computer systems from viruses, worms, Trojan horses, and other harmful or destructive content. This website and other websites linked through this website may contain content that is offensive, indecent, or otherwise objectionable, as well as content containing technical inaccuracies, typographical mistakes, and other errors. This website and websites linked through this website may also contain material that violates the privacy or publicity rights, or infringes the intellectual property and other proprietary rights, of third parties, or the downloading, copying or use of which is subject to additional terms and conditions, stated or unstated. We disclaim any responsibility for any harm resulting from the use by visitors of this website, or from any downloading by those visitors of content posted there, or from the use by visitors of websites that are linked through this website, or from downloading by those visitors of content posted there.",
						   "• Copyright Infringement and DMCA Policy. As we ask others to respect its intellectual property rights, we respect the intellectual property rights of others. If you believe that material located on or linked to by this website violates your copyright, you are encouraged to notify us in accordance with our Digital Millennium Copyright Act (“DMCA”) Policy:",
						   "• If you believe that content available by means of this website infringes one or more of your copyrights, please notify us by means of an emailed notice (“Infringement Notice”) providing the information described below to the email address listed below. If we take action in response to an Infringement Notice, we will make a good faith attempt to contact the party that made such content available by means of the most recent email address, if any, provided by such party to us. Your Infringement Notice may be forwarded to the party that made the content available or to third parties such as ChillingEffects.org. Please be advised that you will be liable for damages (including costs and attorneys’ fees) if you materially misrepresent that a product or activity is infringing your copyrights. Thus, if you are not sure content located on or linked-to by this website infringes your copyright, you should consider first contacting an attorney.",
						   "• All Infringement Notices need to be sent to contact@portl.com, as plain text emails without attachments (email attachments are discarded), and must include the following or they will be deemed invalid:",
						   "• An electronic signature of the copyright owner or a person authorized to act on the copyright owner’s behalf;",
						   "• An identification of the copyright claimed to have been infringed;",
						   "• A description of the nature and exact location of the content that you claim to infringe your copyright, in sufficient detail to permit us to find and positively identify that content;",
						   "• Your name, address, telephone number and email address; and",
						   "• A statement by you: (a) that you believe in good faith that the use of the content that you claim to infringe your copyright is not authorized by law, or by the copyright owner or such owner’s agent; and (b) under penalty of perjury, that all of the information contained in your Infringement Notice is accurate, and that you are either the copyright owner or a person authorized to act on their behalf.",
						   "If a DMCA notice is valid, we are required by law to respond to it by disabling access to the allegedly infringing content. If you are a registered user of this Website and access to your account or features that require access to your account have been disabled for this reason, we will notify you. You then have the option to send us a counter-notice stating why your content does not infringe copyrights and asking for access to be reinstated.",
						   "Counter notices need to be sent to contact@portl.com, as plain text emails without attachments (email attachments are discarded) and include the following or they will be deemed invalid:",
						   "• Your name, address, phone number and physical or electronic signature;",
						   "• Identification of the allegedly infringing content and its location before disabling access; and",
						   "• A statement under penalty of perjury explaining why the content was removed by mistake or misidentification.",
						   "Counter notices need to be sent to contact@portl.com, as plain text emails without attachments (email attachments are discarded) and include the following or they will be deemed invalid:",
						   "We will respond to all such notices, including as required or appropriate by removing the infringing material or disabling all links to the infringing material. In the case of a visitor who may infringe or repeatedly infringes the copyrights or other intellectual property rights of us or others, we may, in our discretion, terminate or deny access to and use of this website. In the case of such termination, we will have no obligation to provide a refund of any amounts previously paid to us.",
						   "• Intellectual Property. This TOS does not transfer to you any of our intellectual property, or the intellectual property of any third party. All trademarks, service marks, graphics and logos used in connection with this website are trademarks or registered trademarks of us, PORTL, our licensors, or other third parties. Your use of this website grants you no right or license to reproduce or otherwise use any trademarks of ours, PORTL, our licensors, or third parties.",
						   "• Changes. We reserve the right, in our sole discretion, to modify or replace any part of this TOS. It is your responsibility to check this TOS periodically for changes. Your continued use of or access to this website following the posting of any changes to this TOS constitutes acceptance of those changes. We may also, in the future, offer new services and/or features through this website (including, the release of new tools and resources). Such new features and/or services shall be subject to the terms and conditions of this TOS.",
						   "• Termination. We may terminate your access to all or any part of this website at any time, with or without cause, with or without notice, effective immediately. If you wish to terminate this TOS or your account on this website (if you have one), you may simply discontinue using this website. All provisions of this TOS which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity and limitations of liability.",
						   "• Disclaimer of Warranties. This website is provided “AS IS.” We and our suppliers and licensors (including but not limited to PORTL) disclaim all warranties of any kind, express or implied, including, without limitation, the warranties of merchantability, fitness for a particular purpose and non-infringement. Neither we nor our suppliers and licensors (including but not limited to PORTL) makes any warranty that this website will be error free or that access to this website will be continuous or uninterrupted. You download from or otherwise obtain content or services through this website at your own discretion and risk.",
						   "• Limitation of Liability. In no event will we nor our suppliers or licensors (including but not limited to PORTL) be liable with respect to any subject matter of this agreement (the TOS) under any contract, negligence, strict liability or other legal or equitable theory for: (i) any special, incidental or consequential damages; (ii) the cost of procurement or substitute products or services; (iii) interruption of use or loss or corruption of data; or (iv) any amounts that exceed the fees paid by you to us under this agreement during the twelve (12) month period prior to the cause of action. We shall have no liability for any failure or delay due to matters beyond our reasonable control. The foregoing shall not apply to the extent prohibited by applicable law.",
						   "• General Representation and Warranty. You represent and warrant that (i) your use of this website will be in strict accordance with our Privacy Policy, with this TOS, and with all applicable laws and regulations (including without limitation any local laws or regulations in your country, state, city, or other governmental area, regarding online conduct and acceptable content, and including all applicable laws regarding the transmission of technical data exported from the United States or the country in which you reside); and (ii) your use of this website will not infringe or misappropriate the intellectual property rights of any third party.",
						   "• Indemnification. You agree to indemnify, defend, and hold harmless us, our contractors, our licensors, and PORTL, and each of these companies’ respective directors, officers, employees and agents, from and against any and all claims and expenses, including attorneys’ fees, arising out of your use of this website, including but not limited to your violation of this TOS or our privacy policy.",
						   "• Miscellaneous. This TOS constitutes the entire agreement between us and you concerning the subject matter hereof, and they may only be modified by a written amendment signed by one of our authorized officers, or by our posting of a revised version. Except to the extent applicable law, if any, provides otherwise, this TOS, and any access to or use of this website, will be governed by the laws of the State of Oregon, U.S.A., excluding its conflict of law provisions, and the proper and exclusive venue to resolve any dispute arising out of or relating to any of the foregoing will be the state and federal courts located in Eugene, Oregon. The prevailing party in any action or proceeding to enforce this TOS shall be entitled to recover costs, expert witness charges, and attorneys’ fees. PORTL is an intended third party beneficiary of this TOS (including but not limited to paragraphs 3, 7, 10, 11, and 13), and shall be entitled to enforce it. If any part of this TOS is held invalid or unenforceable, that part will be construed to reflect the parties’ original intent, and the remaining portions will remain in full force and effect. A waiver by either party of any term or condition of this TOS or any breach thereof, in any instance, will not waive such term or condition or any subsequent breach thereof. You may assign your rights under this TOS to any party that consents to, and agrees to be bound by, its terms and conditions; we may assign our rights under this TOS without condition. This TOS will be binding upon and will inure to the benefit of the parties, their successors and permitted assigns.",
						   ]
}
