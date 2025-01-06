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
    //Retriving Target User From Org based on user licence of Source Org selected user.
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
       //  List<Id> PSAIds = new List<Id>{'0PSdL000001W0KVWA0', '0PSdL000006qrspWAA', '0PSdL000006qykbWAA', '0PSdL000001W0KpWAK','0PSdL000004Qk4vWAC','0PSdL000004Qk9lWAC','0PSdL000001W0KyWAK','0PSdL000007jGJ7WAM'};
         String standardPSAssignToUser = 'X00%';
          return [SELECT  PermissionSet.Name, PermissionSetId
                  FROM PermissionSetAssignment
                  WHERE AssigneeId = : sourceUser 
                  AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)];
        }
      //Retriving PermissionSet Assigned Of Target User From Org.
      @AuraEnabled(cacheable=true)
      public static List<PermissionSetAssignment> getTargetPermissionSet(Id targetUser){
      String standardPSAssignToUser = 'X00%';
    //  List<Id> PSAIds = new List<Id>{'0PSdL000001W0LBWA0', '0PSdL000001W0KVWA0','0PSdL000001W0KyWAK','0PSdL000004Qk9lWAC','0PSdL000007jGJ7WAM','0PSdL000004Qk4vWAC','0PSdL000001W0KpWAK','0PSdL000006qykbWAA'};
          return [SELECT  PermissionSet.Name, PermissionSetId
          FROM PermissionSetAssignment
          WHERE AssigneeId = : targetUser 
          
          AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)];
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
              //  List<Id> PSAIds = new List<Id>{'0PadL000000YwRWSA0', '0PadL000000YwRPSA0','0PSdL000001W0KpWAK','0PadL000004vYViSAM', '0PadL000004vaXVSAY','0PadL000004vakPSAQ','0PadL000004vayvSAA'};
                /*Retriving PermissionSetassignment of target user */
                String standardPSAssignToUser = 'X00%';
                                       
                List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id
                                                                          FROM PermissionSetAssignment
                                                                          WHERE  AssigneeId = :targetUserId
                                                                          AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)
                                                                          ];

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
         //   List<Id> standardPermissionSetIds =new List<Id>{'0PSdL000001W0LBWA0','0PSdL000001W0KVWA0','0PSdL000001W0KpWAK','0PSdL000004Qk4vWAC','0PSdL000004Qk9lWAC','0PSdL000001W0KyWAK'};
            String standardPSAssignToUser = 'X00%';
            //Retriving assigned permissions of target user.
            List<PermissionSetAssignment> assignedTargetPermissions = [SELECT PermissionSetId 
                                                                      FROM PermissionSetAssignment
                                                                      WHERE AssigneeId = :targetUserId 
                                                                      AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)
                                                                     ]; 
            
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
           //     List<Id> stdPermissionSetIds =new List<Id>{'0PSdL000001W0LBWA0','0PSdL000001W0KVWA0','0PSdL000001W0KpWAK','0PSdL000004Qk4vWAC','0PSdL000004Qk9lWAC','0PSdL000001W0KyWAK','0PSdL000006qykbWAA','0PSdL000006qrspWAA'};
                String standardPSAssignToUser1 = 'X00%';
            for(PermissionSetAssignment psId: [SELECT  PermissionSet.Name, PermissionSetId
                                              FROM PermissionSetAssignment
                                              WHERE AssigneeId = :sourceUserId 
                                              AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser1)
                                              ]){
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
          String standardPSAssignToUser = 'X00%';
       //   List<Id> stdPermissionSetIds =new List<Id>{'0PSdL000001W0LBWA0','0PSdL000001W0KVWA0','0PSdL000001W0KpWAK','0PSdL000004Qk4vWAC','0PSdL000004Qk9lWAC','0PSdL000001W0KyWAK','0PSdL000006qykbWAA','0PSdL000006qrspWAA'};                                              
          List<PermissionSetAssignment> psaNeedToBeClonedForTargetUser = new List<PermissionSetAssignment>();
          List<PermissionSetAssignment> targetUserAssignedPermissions = [SELECT PermissionSetId 
                                                                          FROM PermissionSetAssignment
                                                                          WHERE AssigneeId = :targetUserId 
                                                                          AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)
                                                                          ];
                                                        System.debug('targetUserAssignedPermissions;;;toCheck'+targetUserAssignedPermissions);
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
                                              AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser)]){

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
