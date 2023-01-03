public with sharing class RevSMInvoiceAPIHelper {
    public static final String BS_INVOICE_ENDPOINT = '/services/data/v56.0/commerce/invoicing/invoices/collection/actions/generate';

    public static HttpResponse bsToInvoice(String body) {
        String endpoint = 'callout:RevSMNC' + BS_INVOICE_ENDPOINT;
        return RevSMInvoiceAPIHelper.post(endpoint, body);
    }

    public static HttpResponse post(String endpoint, String body) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody(body);
        HttpResponse response = http.send(request);
        return response;
    }
}