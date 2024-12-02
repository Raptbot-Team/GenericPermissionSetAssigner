@RestResource(urlMapping='/AccountSync/*')
global class DemoInboundIntegration {
    global class AccountWrapper{
        global List<Account> accList;
        global List<Contact> conList;
    }
    
    @HttpPost 
    global static String saveAccount(){
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        System.debug(requestBody);
        
        List<Account> accList = (List<Account>) System.JSON.deserialize(requestBody, List<Account>.class);
        for(Account account :accList ){ 
            account.Id = null;
        } try{
            insert accList;
            return 'Record Inserted';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }
    
    
     @HttpGet
    global static AccountWrapper getAccounts(){
        Map<String, String> params = RestContext.request.params;
        String accIndustry = params.get('Industry');
        Set<Id> accId = new Set<Id>();
        List<Account> accounts = [Select Id, Name, Phone, Industry from Account WHERE Industry = :accIndustry];
        for(Account acc : accounts){
            accId.add(acc.Id);   
        } 
        List<Contact> contacts = [SELECT Id, LastName from contact where accountId IN:accId];
        
        AccountWrapper accWrapper = new AccountWrapper();
        accWrapper.accList = accounts;
        accWrapper.conList = contacts;
        return accWrapper;
    }
    
    
    @HttpDelete
    global static void doDelete() {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account account = [SELECT Id FROM Account WHERE Id = :accountId];
        delete account; 
    }
    
    
   
    
    
    @HttpPut
    global static void bulkUpdate() {
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            List<Account> accountsToUpdate = (List<Account>) JSON.deserialize(requestBody, List<Account>.class);
            Schema.SObjectField orgExternalField = Account.Fields.External_ID__c;
            Database.UpsertResult[] srList = Database.upsert(accountsToUpdate,orgExternalField,false);
        } catch (Exception e) {      
            System.debug('message'+e.getMessage());
        }
    }
    
    
    @HttpPatch
    global static ID updateAccountFields(){
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Map<String,Object> mapObj = new Map<String,Object>();
        Account ac = [Select Id from Account where Id =:accountId];
        Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(req.requestBody.toString());
        for(String fieldName:params.keySet()){
            ac.put(fieldName, params.get(fieldName));
        }
        update ac;
        return ac.Id;
    }
}