#  Ditched Code Snippets 
For reference use ONLY

## From the RenewalPeriod-Core Data Helper file
    // Computed property to automatically create the name of each new renewal period
    var generatedRenewalPeriodName: String  {
        // Get only the year digits for the starting year
        let startingYearString = String(renewalPeriodStart.formatted(date: .numeric, time: .omitted))
        let startingPeriodYear = startingYearString.dropFirst(6)
        
        // Get only the year digits for the ending year
        let endingYearString = String(renewalPeriodEnd.formatted(date: .numeric, time: .omitted))
        let endingPeriodYear = endingYearString.dropFirst(6)
        
        
        if startingPeriodYear == endingPeriodYear {
            return "\(startingPeriodYear) Renewal"
        } else  {
            return "\(startingPeriodYear) - \(endingPeriodYear) Renewal"
        }
        
        
    }


## Unneccessary function from the DataController's calculateCEsEarnedByMonth method:
    /// Method for deleting any and all created placeholder Credentials.  This method was specifically created to handle the potential outcome of
    /// the private method convertCesAwardedToHoursFor(activity), but can be used elsewhere as needed.  However, in order to work only
    /// Credential objects with the name of "Placeholder" will be fetched and deleted.
    private func deleteAllPlaceholderCredentials() {
        let request: NSFetchRequest<Credential> = Credential.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Placeholder")
        
        do {
            let credsToDelete: [Credential] = try container.viewContext.fetch(request)
            for cred in credsToDelete {
                delete(cred)
            }
        } catch {
            print("Failed to fetch placeholder Credentials, and, therefore, can't delete them.")
        }
        
    }//: deleteAllPlaceholderCredentials


## From DataController-StoreKit
    func isUserEligibleForIntroOffer() async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            if case let .verified(transaction) = entitlement {
                if transaction.productID == DataController.proAnnualID || transaction.productID == DataController.proMonthlyID {
                    return false
                }
            }//: if case let
        }//: for await
        return true
    }//: isUserEligibleForIntroOffer()
    
    func getSubscriptionIntroOfferText(for product: Product, isEligible: Bool) -> String {
        guard let subscription = product.subscription else {
            return "No subscription info available"
        }
        
        if isEligible, let offer = subscription.introductoryOffer {
            let price = offer.displayPrice
            let period = offer.period.unit == .month ? "\(offer.period.value) month(s)" : "\(offer.period.value) year(s)"
            
            let standardPeriod = "\(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit)"
            
            return "\(price) for \(period), then \(product.displayPrice) for \(standardPeriod)"
            
        } else {
            let standardPeriod = "\(subscription.subscriptionPeriod.value) \(subscription.subscriptionPeriod.unit)"
            return "\(product.displayPrice) for \(standardPeriod)"
        }
            
    }//: getSubscriptionIntroOfferText
