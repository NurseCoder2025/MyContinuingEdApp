//
//  BasicAndProFeatures.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/19/25.
//

import Foundation

// MARK: - BASIC Features
let basicFeatures = [
    UpgradeFeature(
        featureIcon: "person.text.rectangle.fill",
        featureText: "1 Credential",
        sellingPoint: "With a basic feature unlock, you can track CE activities for just one credential (license, certification, etc.)."
    ),
    UpgradeFeature(
        featureIcon: "infinity",
        featureText: "Unlimited renewals & CE activities",
        sellingPoint: "There's no limit to how many renewal periods you can track CEs for, or how many CE activities you can log."
    ),
    UpgradeFeature(
        featureIcon: "arrow.up.arrow.down",
        featureText: "Basic sorting/filtering",
        sellingPoint: "You can sort CE activities by name and filter them by rating (how interesting they were or not)."
    ),
    UpgradeFeature(
        featureIcon: "tag.fill",
        featureText: "Unlimited tags",
        sellingPoint: "You can create as many tags for your CE activities as you'd like to help organize them in a way that makes sense to you."
    ),
    UpgradeFeature(
        featureIcon: "doc.text.image.fill",
        featureText: "Save CE certificates",
        sellingPoint: "Keep all of your CE certificates in a single place where you know they are! Certificates can be images or PDFs."
    ),
    UpgradeFeature(
        featureIcon: "pencil.and.scribble",
        featureText: "Journal on completed activities",
        sellingPoint: "Once you complete a CE activity, don't just go home and forget what you learned!  With this feature you can jot down a summary of what you learned using several prompts provided, including anything that you found surprising."
    )
]

// MARK: - PRO Features
let proFeatures: [UpgradeFeature] = [
    UpgradeFeature(
        featureIcon: "photo.stack.fill",
        featureText: "Unlimited credentials",
        sellingPoint: "Got multiple licenses, certificates, or other credentials that you must complete CEs for?  With a Pro subscription, you can add as many credentials as needed and track CEs for each of them."
    ),
    UpgradeFeature(
        featureIcon: "slider.horizontal.3",
        featureText: "Advanced filtering",
        sellingPoint: "Narrow down a long list of CE activities to just those you want to review by applying additional sorting and filtering criteria available only in the Pro subscription.  Filter by expiration status and credential, and sort by date, number of CE hours awarded, cost, activity format, and CE type."
    ),
    UpgradeFeature(
        featureIcon: "waveform.and.mic",
        featureText: "Record audio notes",
        sellingPoint: "Instead of having to type out reflections on a completed CE activity, you can now press a button and record your thoughts and reflections verbally."
    ),
    UpgradeFeature(
        featureIcon: "list.bullet.rectangle.fill",
        featureText: "CE Categories",
        sellingPoint: "For many credentials, a certain number of CE hours/units on a particular subject such as ethics are required every renewal period as part of the overall total that must be earned. With a Pro subscription you can add and assign these categories to your credentials to make sure you meet any credential-specific CE requirements."
    ),
    UpgradeFeature(
        featureIcon: "gauge.with.dots.needle.33percent",
        featureText: "CE progress meters",
        sellingPoint: "See at a glance how far along you are coming on meeting your CE requirements for any given renewal period that has been entered.  This is a quick and helpful way to size up your progress and make sure you're on track!"
    ),
    UpgradeFeature(
        featureIcon: "chart.pie.fill",
        featureText: "CE progress details",
        sellingPoint: "Get additional, detailed information on your CE progress with a breakdown of how many days are left in a renewal period and how many CEs you need to earn per month in order to renew before it ends. Additionally, if you added any CE categories that must be earned each renewal then this screen will show your progress for each one of those."
    ),
    UpgradeFeature(
        featureIcon: "chart.xyaxis.line",
        featureText: "Additional graphs",
        sellingPoint: "View additional graphs that show various data points over time, such as the number of CEs earned or the amount of money spent on CE activities by month.  Additional graphs and charts will be added for Pro subscribers in the future to provide enhanced insights."
    ),
    UpgradeFeature(
        featureIcon: "exclamationmark.triangle.fill",
        featureText: "Board actions",
        sellingPoint: "You worked hard to earn your credential(s) and prove competence, but sometimes things happen that can result in your licensing board or governing body taking disciplinary action against your credential. Should that situation ever happen to you, you can document any such actions and keep on top of critical deadlines and fines in order to maintain your credential."
    ),
    UpgradeFeature(
        featureIcon: "graduationcap.fill",
        featureText: "Remedial CE tracking",
        sellingPoint: "In addition to the normal amount of CEs that are required for renewal, sometimes you may need to earn additional CEs as part of a disciplinary process or to re-enter practice if your credential previously lapsed.  This Pro-only feature allows you to track and manage those additional CEs."
    ),
    UpgradeFeature(
        featureIcon:  "plus.diamond.fill",
        featureText: "More to come!",
        sellingPoint: "More Pro-only features will be added in the future, so become a subscriper to take advantage of them when they're released!"
    )
]
