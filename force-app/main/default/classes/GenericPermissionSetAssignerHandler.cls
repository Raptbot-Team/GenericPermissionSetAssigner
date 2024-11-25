/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-08-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class GenericPermissionSetAssignerHandler {
  //Retriving Source User From Org.
    @AuraEnabled(cacheable=true)
    public static List<User> getSourceUsers() {
      return [SELECT Id, Name, IsActive, Profile.UserLicense.Name 
              FROM User 
              WHERE Profile.UserLicense.Name NOT IN('Analytics Cloud Integration User', 'Analytics Cloud Integration Use', 'Chatter Free')];
    }
    //Retriving Target User From Org based on user licence of Source Org.
    @AuraEnabled(cacheable=true)
    public static List<User> getTargetUsers(Id userId, Id targetUserId){
       List<User> sourceUser=[SELECT Id, Name,IsActive, Profile.UserLicense.Name 
                         FROM User
                         WHERE Id = :userId
                         LIMIT 1];
      
      List<User> TargetUsers=[SELECT Id, Name, IsActive, Profile.UserLicense.Name
                              FROM User 
                              WHERE Id != :userId AND Profile.UserLicense.Name =:sourceUser[0].Profile.UserLicense.Name AND IsActive=true];
      System.debug('TargetUser::'+TargetUsers);
      //Retriving Assigned permissionSet of Source User.
      getSourcePermissionSet(userId);
      return TargetUsers;  
        
}
     //Retriving SourceUser Assigned permission From org.
        @AuraEnabled(cacheable= true)
        public static List<PermissionSetAssignment> getSourcePermissionSet(Id sourceUser) {
          return [SELECT  PermissionSet.Name, PermissionSetId
                  FROM PermissionSetAssignment
                  WHERE AssigneeId = : sourceUser 
                  AND PermissionSetId!='0PSdL000001W0KpWAK'];
        }
      //Retriving PermissionSet Assigned Of Target User From Org.
      @AuraEnabled(cacheable=true)
      public static List<PermissionSetAssignment> getTargetPermissionSet(Id targetUser){
      List<Id> PSAIds = new List<Id>{'0PSdL000001W0LBWA0', '0PSdL000001W0KVWA0'};
          return [SELECT  PermissionSet.Name, PermissionSetId
          FROM PermissionSetAssignment
          WHERE AssigneeId = : targetUser 
          AND PermissionSetId NOT IN :PSAIds];
      }


 //Assigne selected Custom permissionset to TargetUser.     
    @AuraEnabled()
    public static void assignCustomPermissionSetsToTargetUser(
                                                    Id sourceUserId,
                                                    Id targetUserId,
                                                    string customSource, 
                                                    string customTarget){
              // System.debug('sourceUserId::'+sourceUserId);
              // System.debug('targetUserId::'+targetUserId);
                Map<String, Boolean> customSourcePermission = (Map<String, Boolean>) JSON.deserialize(customSource, Map<String, Boolean>.class);
                Map<String, Boolean> customTargetPermission = (Map<String, Boolean>) JSON.deserialize(customTarget, Map<String, Boolean>.class);
              // System.debug('customSourcePermission::'+customSourcePermission);
              //  System.debug('customTargetPermission:::'+customTargetPermission);
                List<PermissionSet> assignedPSSource = [SELECT Id
                                                        FROM PermissionSet 
                                                        WHERE Id IN :customSourcePermission.keySet()];
                List<PermissionSet> assignedPSTarget = [SELECT Id
                                                        FROM PermissionSet
                                                        WHERE Id IN :customTargetPermission.keySet()];
                
                // System.debug('assignedPSSource:::'+assignedPSSource);
                // System.debug('assignedPSTarget:::'+assignedPSTarget);

                List<permissionSetAssignment> psaListToBeInserted = new List<PermissionSetAssignment>();
                Map<Id,Boolean> permissionSetAssignmentIds = new Map<Id,Boolean>();

                /*Adding selected permissionset to the map permissionSetAssignmentIds of source and target user */
                for(PermissionSet ps: assignedPSSource){
                  if(!permissionSetAssignmentIds.containsKey(ps.id) ){
                      permissionSetAssignmentIds.put(ps.Id, customSourcePermission.get(ps.Id));
                    
                  }
                }
                // System.debug('permissionSetAssignmentIdsSource:::'+permissionSetAssignmentIds);
                for(Permissionset ps: assignedPSTarget){
                  if(!permissionSetAssignmentIds.containsKey(ps.Id)){
                      permissionSetAssignmentIds.put(ps.Id, customTargetPermission.get(ps.Id));                
                  }
                }
            //   System.debug('permissionSetAssignmentIdsTarget::::'+permissionSetAssignmentIds);

                /*Standard PermissionSet of Target user */
                List<Id> PSAIds = new List<Id>{'0PadL000000YwRWSA0', '0PadL000000YwRPSA0','0PSdL000001W0KpWAK'};
                /*Retriving PermissionSetassignment of target user */
                List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id
                                                                          FROM PermissionSetAssignment
                                                                          WHERE Id NOT IN :PSAIds
                                                                          AND AssigneeId = :targetUserId];

                Map<Id,PermissionSetAssignment> deletedpermissionSetAssignmentmap = new Map<Id,PermissionSetAssignment>();                                                        
                for(PermissionSetAssignment psa: PermissionSetAssignments){
                  deletedpermissionSetAssignmentmap.put(psa.id,psa);
                }
              // System.debug('permissionSetAssignmentsneedto be Deleted:::'+permissionSetAssignments);
                //Deleting assignedPermissionSet of target user which user have not selected for custom permission.
                  if(permissionSetAssignments.size()>0){
                    try {
                        delete permissionSetAssignments;
                      //  System.debug('permissionSetAssignmentsDELETED:::'+permissionSetAssignments);

                      }
                      catch (Exception e) { throw new AuraHandledException(e.getMessage());
                    }
                  }
                  
                for (Id psId : permissionSetAssignmentIds.keySet()) {
                    if(!deletedpermissionSetAssignmentmap.containsKey(psId) ){
                        psaListToBeInserted.add(new PermissionSetAssignment(
                                                AssigneeId=targetUserId,
                                                PermissionSetId=psId )
                );
                      }
              }
                
              //  System.debug('psaListToBeInserted:::'+ psaListToBeInserted);


                if(psaListToBeInserted.size()>0){
                //  System.debug('entered if psaListToBeInserted::'+psaListToBeInserted);
                    try {
                        upsert psaListToBeInserted;

                    } catch (Exception e) {
                        throw new AuraHandledException(e.getMessage());
                    }
                  }
      }


  @AuraEnabled
  public static void upgradePermissionSetoftargetUser(Id sourceUserId,
                                                      Id targetUserId,
                                                      String upgradeTarget){
            System.debug('sourceUserId:::'+sourceUserId + 'targetUserId::'+targetUserId); 
            Map<String, Boolean> upgradeTargetPermission = (Map<String, Boolean>) JSON.deserialize(upgradeTarget, Map<String, Boolean>.class);
            System.debug('upgradetargetPermission::::'+upgradeTargetPermission);
            List<PermissionSetAssignment> psaNeedToBeUpgratedForTargetUser = new List<PermissionSetAssignment>();
            List<Id> targetUserpermissionSetIds = new List<Id>();
            List<Id> standardPermissionSetIds =new List<Id>{'0PSdL000001W0LBWA0','0PSdL000001W0KVWA0'};
            //Retriving assigned permissions of target user.
            List<PermissionSetAssignment> assignedTargetPermissions = [SELECT PermissionSetId 
                                                                      FROM PermissionSetAssignment
                                                                      WHERE AssigneeId = :targetUserId 
                                                                      AND PermissionSetId NOT IN :standardPermissionSetIds]; 
            
            for(PermissionSetAssignment psa: assignedTargetPermissions){
              targetUserpermissionSetIds.add(psa.PermissionSetId);
            }
            if(upgradeTargetPermission.size()>0){
              for(Id psId: upgradeTargetPermission.keySet()){
                if(!targetUserpermissionSetIds.contains(psId) && upgradeTargetPermission.get(psId)){
                  psaNeedToBeUpgratedForTargetUser.add(new PermissionSetAssignment(
                                                AssigneeId=targetUserId,
                                                PermissionSetId=psId ));}}
            }else{
              System.debug('no selected permission::::'+upgradeTargetPermission.size());
            for(PermissionSetAssignment psId: [SELECT  PermissionSet.Name, PermissionSetId
                                              FROM PermissionSetAssignment
                                              WHERE AssigneeId = :sourceUserId 
                                              AND PermissionSetId!='0PSdL000001W0KpWAK']){
              if(!targetUserpermissionSetIds.contains(psId.id)){
                psaNeedToBeUpgratedForTargetUser.add(new PermissionSetAssignment(
                                              AssigneeId=targetUserId,
                                              PermissionSetId=psId.PermissionSetId ));}}                        
            }
            

            System.debug('targetUserpermissionSetIds:::'+targetUserpermissionSetIds);
  
           if(psaNeedToBeUpgratedForTargetUser.size()>0){
            try {
              upsert psaNeedToBeUpgratedForTargetUser;}
               catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
          }

}                                                     
  @AuraEnabled
  public static void clonePermissionSetOfTargetUser(Id sourceUserId,
                                                    Id targetUserId,
                                                    String cloneTarget){
          System.debug('sourceUserId:::'+sourceUserId + 'targetUserId::'+targetUserId); 
          Map<String, Boolean> cloneTargetPermission = (Map<String, Boolean>) JSON.deserialize(cloneTarget, Map<String, Boolean>.class);
          System.debug('clonetargetPermission::::'+cloneTargetPermission);
          List<PermissionSetAssignment> psaNeedToBeClonedForTargetUser = new List<PermissionSetAssignment>();
          List<PermissionSetAssignment> targetUserAssignedPermissions = [SELECT PermissionSetId 
                                                                          FROM PermissionSetAssignment
                                                                          WHERE AssigneeId = :targetUserId 
                                                                          AND PermissionSetId !='0PSdL000001W0KVWA0'];
          if(targetUserAssignedPermissions.size()>0){
          delete targetUserAssignedPermissions;
          }

          if(cloneTargetPermission.size()>0){
            for(Id psId: cloneTargetPermission.keySet()){
              if(cloneTargetPermission.get(psId)){
               System.debug('upgradeTargetPermission.get(psId)::::'+cloneTargetPermission.get(psId));
                psaNeedToBeClonedForTargetUser.add(new PermissionSetAssignment(
                  AssigneeId=targetUserId,
                  PermissionSetId=psId ));
              }
            }
          }else{

            for(PermissionSetAssignment psId: [SELECT  PermissionSet.Name, PermissionSetId
                                              FROM PermissionSetAssignment
                                              WHERE AssigneeId = :sourceUserId
                                              AND PermissionSetId !='0PSdL000001W0KVWA0']){

            psaNeedToBeClonedForTargetUser.add(new PermissionSetAssignment(
              AssigneeId=targetUserId,
              PermissionSetId=psId.PermissionSetId ));
                                              }
          }
          
          
          if (psaNeedToBeClonedForTargetUser.size()>0) {
            try {
              upsert psaNeedToBeClonedForTargetUser;}
               catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            
          } 


}  
  
}