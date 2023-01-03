public with sharing class RevSMInvoiceDateCalculator {
    /*
    To test in anonymous window
    Date nextBillingDate = Date.parse('01/01/2022');
    Date billThroughDate = null;
    Date endDate = Date.parse('12/31/2022');
    Integer billingTermInMonths = 12;
    Integer periodBoundaryDay = null;
    Date targetDate = RevSMDateCalculator.getTargetDate(nextBillingDate, billThroughDate, endDate, billingTermInMonths, periodBoundaryDay);
    System.debug(targetDate);
    */
    public static Date getTargetDate(Date nextBillingDate, Date billThroughDate, Date endDate, Integer billingTermInMonths, Integer periodBoundaryDay) {
        
        // If BillThroughDate is set, return the same date as target date
        // don't need to proceed further
        if(billThroughDate != null) return billThroughDate;

        // Proration Day of the Month set by the user on Order Product
        Integer pdom;
        if(periodBoundaryDay != null) {
            pdom = periodBoundaryDay;
        } else {
            pdom = nextBillingDate.day();
        }

        // Add the billing term to the next billing date
        Date tempTargetDate = nextBillingDate.addMonths(billingTermInMonths-1);
        Integer numDays = Date.daysInMonth(tempTargetDate.year(), tempTargetDate.month());

        // Identify the exact month of target date
        Integer month = (tempTargetDate.day() < numDays && tempTargetDate.day() <= pdom - 1) ? tempTargetDate.month() : tempTargetDate.month() + 1;

        // Identify the day of the target date
        // Last days of the month are taken care of
        numDays = Date.daysInMonth(tempTargetDate.year(), month);
        Integer day;
        if(month == tempTargetDate.month()) {
            day = (numDays < pdom - 1)? numDays : pdom - 1;
        } else {
            day = (numDays <= pdom - 1)? numDays - 1 : pdom - 1;
        }

        // Consolidate all the calculations
        Date targetDate = Date.newInstance(tempTargetDate.year(), month, day);

        // If end date is not null (evergreen) and target date is greater than end date, 
        // then target date is the end date
        targetDate = (endDate != null && targetDate > endDate)? endDate : targetDate;
        System.debug(targetDate);

        return targetDate;
    }
}