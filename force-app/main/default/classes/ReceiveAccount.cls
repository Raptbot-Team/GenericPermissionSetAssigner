@RestResource(urlMapping='/Account/*')
global class ReceiveAccount {
    //TARGET ORG 
    @HttpDelete
    global static void doDelete() {
        System.debug('Delete Method has been called');
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account account = [SELECT Id FROM Account WHERE Id = :accountId];
        delete account; 
    }
    @HttpGet
    global static AccountWrapper getAccounts(){
        Map<String, String> params = RestContext.request.params;
        System.debug(params);
        String accIndustry = params.get('Industry');
        System.debug('GET Method has been called');
        Set<Id> accId = new Set<Id>();
        List<Account> accounts = [Select Id, Name, Phone, Industry from Account WHERE Industry = :accIndustry];
        for(Account acc : accounts){
         accId.add(acc.Id);   
        } 
        List<Contact> contacts = [SELECT Id, LastName from contact where accountId IN:accId];
        AccountWrapper accWrapper = new AccountWrapper();
        accWrapper.accList = accounts;
        accWrapper.conList = contacts;
        System.debug(accWrapper);
        return accWrapper;
     }
       global class AccountWrapper{
            global List<Account> accList;
            global List<Contact> conList;
            
        }
   @HttpPost 
    global static List<String> saveAccount(){
        String requestBody;
        RestRequest req = RestContext.request;
        requestBody = RestContext.request.requestBody.toString();
        System.debug(requestBody);
        List<String> responses =new List<String>();
        /*List<Account> accList = (List<Account>) System.JSON.deserialize(requestBody, List<Account>.class);
        System.debug(accList);
        for(Account account :accList ){ 
            account.Id = null;
            
        }*/
        Account accList = (Account) System.JSON.deserialize(requestBody, Account.class);
        try{
            insert accList;
            responses.add('Record Inserted');
             }
        catch(Exception e){
            responses.add(e.getMessage());
        }
        return responses;
    }
   /* @HttpPost
    global static String CreateAccCon(){
        try{
            String requestBody;
            //RestRequest req = RestContext.request;
            //System.debug(req);
            requestBody = RestContext.request.requestBody.toString();
            System.debug(requestBody);
            AccountContactWrapper wrapper = (AccountContactWrapper) JSON.deserialize(requestBody, AccountContactWrapper.class);
            insert wrapper.acc;
            System.debug(wrapper.acc);
            wrapper.con.AccountId = wrapper.acc.Id;
            insert wrapper.con;
            System.debug(wrapper.con);
            return 'Success';
        }catch(exception e){
            return  e.getMessage();
        }
    }
    
    global class AccountContactWrapper{
        global Account acc {get;set;}
        global Contact con {get;set;}
    }*/
    @HttpPut
    global static List<String> bulkUpdate() {
                    List<String> responses = new List<String>();

        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            System.debug('requestBody:' + requestBody);
           // List<Account> accountsToUpdate = (List<Account>) JSON.deserialize(requestBody, List<Account>.class);
            Account accountToBeUpserted = (Account) JSON.deserialize(requestBody, Account.class);
            Schema.SObjectField orgExternalField = Account.Fields.External_ID__c;
            //Database.UpsertResult[] srList = Database.upsert(accountsToUpdate,orgExternalField,false);
            Database.UpsertResult srList = database.upsert(accountToBeUpserted,orgExternalField,false);
            System.debug('srList'+srList);   
            responses.add('put operation is performed');
        } catch (Exception e) {      
             responses.add(e.getMessage());
          //  System.debug('line no'+e.getLineNumber());
        }
        return responses;
    }
    @HttpPatch
    global static List<String> updateAccountFields(){
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account ac = [Select Id from Account where Id =:accountId];
        Map<String,Object> params = (Map<String,Object>)JSON.deserializeUntyped(req.requestBody.toString());
        Map<String,Object> accRecords = (Map<String, Object>) params.get('Account');
        List<String> response = new List<String>();
        for(String fieldName:accRecords.keySet()){
            ac.put(fieldName, accRecords.get(fieldName));
            response.add(ac.Id);
  }
        update ac;
        return response;
    }
}