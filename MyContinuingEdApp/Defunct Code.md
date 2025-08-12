#  Defunct Code

### From the RenewalPeriodView file:

            .onAppear {
                // Adding this code to fix a bug where the sheet view will
                // not show the computed name of the renewal period upon
                // first loading/opening the app.
                let context = dataController.container.viewContext
                let objectID = renewalPeriod.objectID
                if let refreshed = try? context.existingObject(
                    with: objectID) as? RenewalPeriod {
                    renewalPeriod.periodStart = refreshed.periodStart
                    renewalPeriod.periodEnd = refreshed.periodEnd
                }
                
            } //: ON APPEAR

--> This code did NOT work and even caused a fatal error crash.
