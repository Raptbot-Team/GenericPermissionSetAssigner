@RestResource(urlMapping='/contactFlow/*')
global class TargetContact {
 @HttpPost 
    global static String InsertContact(){
        String requestBody = RestContext.request.requestBody.toString();
        System.debug(requestBody);
        Contact conlist = (Contact) System.JSON.deserialize(requestBody, Contact.class);
        //List<Contact> conList = (List<Contact>) System.JSON.deserialize(requestBody, List<Contact>.class);
       /* for(Contact contact :conList ){ 
            contact.Id = null;
            
        } */try{
            conlist.Id=null;
            insert conList;
            System.debug(conList);
            return 'Record Inserted';
             }
        catch(Exception e){
            return e.getMessage();
        }
    }
}