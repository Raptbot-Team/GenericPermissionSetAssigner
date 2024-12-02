/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-02-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ContentVersionCloneBatch implements Database.Batchable<SObject>, Database.Stateful {
     // List to store cloned ContentVersions for all records
    public List<ContentVersion> clonedContentVersions = new List<ContentVersion>();

   public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM ContentDocument';
        return Database.getQueryLocator(query);
    }

    // Execute method for processing each batch
    public void execute(Database.BatchableContext context, List<ContentDocument> scope) {
        Set<Id> contentDocumentIds = new Set<Id>();
        Set<Id> contentDocumentIdsToDelete = new Set<Id>();
        
        for (ContentDocument contentDoc : scope) {
            contentDocumentIds.add(contentDoc.Id);
        }
        // Fetch all related ContentVersions for the provided ContentDocument IDs
        Map<Id, List<ContentVersion>> contentVersionMap = new Map<Id, List<ContentVersion>>();
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId, VersionNumber
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocumentIds
            ORDER BY ContentDocumentId, VersionNumber DESC
        ];
        System.debug('contentVersions::::'+contentVersions);
        // Group ContentVersions by ContentDocumentId and keep only the latest three versions
        for (ContentVersion cv : contentVersions) {
            if (!contentVersionMap.containsKey(cv.ContentDocumentId)) {
                contentVersionMap.put(cv.ContentDocumentId, new List<ContentVersion>());
            }
            if (contentVersionMap.get(cv.ContentDocumentId).size() < 3) {
                contentVersionMap.get(cv.ContentDocumentId).add(cv);
            }
        }
        System.debug('contentVersionMap:::'+contentVersionMap);

       /* // Fetch ContentDocumentLink records
        Map<Id, List<ContentDocumentLink>> contentLinkMap = new Map<Id, List<ContentDocumentLink>>();
        List<ContentDocumentLink> contentLinks = [
            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
        ];

        for (ContentDocumentLink link : contentLinks) {
            if (!contentLinkMap.containsKey(link.ContentDocumentId)) {
                contentLinkMap.put(link.ContentDocumentId, new List<ContentDocumentLink>());
            }
            contentLinkMap.get(link.ContentDocumentId).add(link);
        }*/

        // Process each ContentDocument in the scope
        for (ContentDocument doc : scope) {
            try {
                if (!contentVersionMap.containsKey(doc.Id) || contentVersionMap.get(doc.Id).isEmpty()) {
                    continue; // Skip if no ContentVersions exist
                }
                
                List<ContentVersion> originalVersions = contentVersionMap.get(doc.Id); //ContentVersions of this ContentDocId.
                System.debug('originalVersions:::'+originalVersions);
                List<ContentVersion> newVersions = new List<ContentVersion>();
                

                // Clone the versions
                for (ContentVersion cv : originalVersions) {
                    System.debug('cv:::'+cv);
                    ContentVersion clonedVersion = new ContentVersion();
                    clonedVersion.Title = cv.Title;
                    clonedVersion.PathOnClient = cv.PathOnClient;
                    clonedVersion.VersionData = cv.VersionData;
                    newVersions.add(clonedVersion);
                }
                System.debug('newVersions:::'+newVersions);
                // Insert the first cloned version
                if (!newVersions.isEmpty()) {
                    System.debug('newVersions[2];:::'+newVersions[2]);
                    insert newVersions[2];
                    Id newDocId = [SELECT Id 
                                   FROM ContentDocument 
                                   WHERE LatestPublishedVersionId = :newVersions[2].Id].Id;

               /*     // Insert ContentDocumentLink for new ContentDocument
                    if (contentLinkMap.containsKey(doc.Id) && !contentLinkMap.get(doc.Id).isEmpty()) {
                        ContentDocumentLink originalLink = contentLinkMap.get(doc.Id)[0];
                        ContentDocumentLink newLink = new ContentDocumentLink(
                                                            LinkedEntityId = originalLink.LinkedEntityId,
                                                            ContentDocumentId = newDocId,
                                                            ShareType = originalLink.ShareType,
                                                            Visibility = originalLink.Visibility);
                        insert newLink;
                    }*/

                    // Insert remaining versions linked to the new ContentDocument
                    for (Integer i = 1; i < newVersions.size()&& i>=0 ; i--) {
                        System.debug('newVersions[i]:::'+ newVersions[i]);
                        newVersions[i].ContentDocumentId = newDocId;
                        insert newVersions[i];
                    }
                    contentDocumentIdsToDelete.add(doc.Id);
                   

                }

            } catch (Exception e) {
                System.debug('Error processing ContentDocument ID ' + doc.Id + ': ' + e.getMessage());
                // Optionally log or handle the exception for this specific record
            }
            if (!contentDocumentIdsToDelete.isEmpty()) {
            delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocumentIdsToDelete];
        }
        }
    }

    // Finish method for batch
    public void finish(Database.BatchableContext context) {
        System.debug('Batch Processing Completed. Total Cloned Versions: ');
   
    }
}