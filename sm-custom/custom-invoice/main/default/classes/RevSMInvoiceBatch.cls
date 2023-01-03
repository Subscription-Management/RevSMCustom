public class RevSMInvoiceBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{

    //Id batchJobId = Database.executeBatch(new RevSMInvoiceBatch(), 100);

    //This list is used to store all the order products whose 
    //billThroughDate has to be made empty
    public List<OrderItem> orderItemListToUpdate;
    public RevSMInvoiceBatch() {
        orderItemListToUpdate =  new List<OrderItem>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Get all the Billing Schedules and Order Items under
        // Billing Schedule Group Whose EffectiveNextBillingDate is today
        String query = 'SELECT Id, EndDate,EffectiveNextBillingDate, (Select TYPEOF ReferenceEntityItem WHEN OrderItem THEN Id, PeriodBoundaryDay, revsm_IsCustomInvoice__c,revsm_BillingTerm__c, revsm_BillThroughDate__c END, Id FROM BillingScheduleGroupToBillingSchedule ORDER BY CreatedDate DESC) FROM BillingScheduleGroup WHERE EffectiveNextBillingDate = TODAY';
        return Database.getQueryLocator(query);
    }
     
    public void execute(Database.BatchableContext bc, List<BillingScheduleGroup> bsgList){
        // Loop through the Billing Schedule Group
        for(BillingScheduleGroup bsg: bsgList) {
            try{
                generateInvoice(bsg);
            }catch(Exception e) {
                System.debug(e);
            }
        }

        System.debug(orderItemListToUpdate);
    } 
    

    /**
     * This method identifies the target date for each billing schedule group
     * and calls the Invoice API to generate Invoice
     */
    public void generateInvoice(BillingScheduleGroup bsg) {

        // Latest Order Item under the Billing Schedule Group is used for target date calculation
        OrderItem latestOI = (OrderItem) bsg.BillingScheduleGroupToBillingSchedule[0].ReferenceEntityItem;

        // Proceed only if the Latest Order Item is marked for custom invoicing
        if(latestOI.revsm_IsCustomInvoice__c) {

            // Get the target date
            Date targetDate = RevSMInvoiceDateCalculator.getTargetDate(bsg.EffectiveNextBillingDate, latestOI.revsm_BillThroughDate__c, bsg.EndDate, (Integer)latestOI.revsm_BillingTerm__c, latestOI.PeriodBoundaryDay);
            System.debug(bsg.Id +':'+ targetDate);

            // Prepare the Billing Schedule Id list for BS to Invoice API
            // Add the Order Items whose Bill Through Date is not null
            List<String> bsIdList =  new List<String>();
            OrderItem oi;
            for(BillingSchedule bs: bsg.BillingScheduleGroupToBillingSchedule) {
                bsIdList.add(bs.Id);
                oi = (OrderItem) bs.ReferenceEntityItem;
                System.debug(oi);
                if(oi.revsm_BillThroughDate__c != null){
                    oi.revsm_BillThroughDate__c = null;
                    orderItemListToUpdate.add(oi);
                }
                System.debug(orderItemListToUpdate);
            }
            
            // Generate Request JSON to invoke the Invoice API
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeObjectField('billingScheduleIds', bsIdList);
            gen.writeStringField('action', 'Posted');
            gen.writeStringField('targetDate', String.valueOf(targetDate));
            gen.writeStringField('invoiceDate', String.valueOf(bsg.EffectiveNextBillingDate));
            gen.writeEndObject();

            String body = gen.getAsString();
            System.debug(body);

            // Invoke the Invoice API
            HttpResponse response = RevSMInvoiceAPIHelper.bsToInvoice(body);
            System.debug(response);
        }
    }
     
    public void finish(Database.BatchableContext bc) {

        // Update order items with billThroughDate
        System.debug(orderItemListToUpdate);
        if(orderItemListToUpdate.size() > 0) {
            update orderItemListToUpdate;
        }
    }
}