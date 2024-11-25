import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSourceUsers from '@salesforce/apex/GenericPermissionSetAssignerHandler.getSourceUsers';
import getTargetUsers from '@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetUsers';

import getSourcePermissionSet from '@salesforce/apex/GenericPermissionSetAssignerHandler.getSourcePermissionSet';
import getTargetPermissionSet from '@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetPermissionSet';
import assignCustomPermissionSetsToTargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.assignCustomPermissionSetsToTargetUser';
import upgradePermissionSetoftargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.upgradePermissionSetoftargetUser';
import clonePermissionSetOfTargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.clonePermissionSetOfTargetUser';
export default class GenericPermissionSetAssignerComponent extends LightningElement {
    @track optionsForSource = [];
    @track optionsForTarget = [];
    @track sourceUserAssignPS = [];
    @track targetUserAssignPS = [];
    targetCustomPermissions =new Map();
    sourceCustomPermissions = new Map();
    targetUpgradePermissions =new Map();
    targetClonePermissions = new Map();
    @track upgradePermission = false;
    @track clonePermission = false; 
    @track customPermission = false;
    @track sourceUserId;
    @track targetUserId;
    @track upgradePermission = false;
    @track clonePermission = false; 
    activeSections = [ 'CustomPermission', 'UpgradePermission', 'ClonePermission'];

@wire(getSourceUsers)
SourceUser({error, data}){
    if (data) {
        const allUsers = [];
        data.forEach(user => {
            allUsers.push({ label: user.Name, value: user.Id });            
        });
        this.optionsForSource = allUsers;
        console.log('this.optionsForSource:::'+this.optionsForSource);
    }else if (error) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error Fatching Source User.',
            message: 'No user exist in this org.', error, 
            variant: 'Error'}));
    }
}

handleSourceChange(event) {
    this.sourceUserId = event.detail.value;
}
handleTargetChange(event){
    this.targetUserId = event.detail.value;
}
@wire (getTargetUsers, { userId: '$sourceUserId' })
Targetusers({error, data}){
    if(data){
        const allUsers = [];
        data.forEach(user => {
            allUsers.push({ label: user.Name, value: user.Id });            
        });
        this.optionsForTarget = allUsers;
    }else{
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error Retriving Target User.',
            message: 'Error fetching target User.', error, 
            variant: 'Error'}));
    }
    }


    @wire (getSourcePermissionSet,{sourceUser: '$sourceUserId'})
    SourceUserAssignedPS({error,data}){
        if(data){
           const allSourcePermissionSet = [];
           data.forEach(PermissionSetAssignment => {
               allSourcePermissionSet.push({ 
                                        label: PermissionSetAssignment.PermissionSet.Name, 
                                        value: PermissionSetAssignment.PermissionSetId});
                                        
           });
           this.sourceUserAssignPS = allSourcePermissionSet;
           console.log('this.sourceUserAssignPS:::'+this.sourceUserAssignPS);

        }else{
            this.dispatchEvent(new ShowToastEvent({
            title: 'Error Retriving Source User Permission Set.',
            message: 'Error fetching source User Permission Set.', error, 
            variant: 'Error'}));
        }
    }
@wire (getTargetPermissionSet,{targetUser: '$targetUserId'})
TargetUserAssignedPS({error,data}){
    if(data){
        const allTargetPermissionSet = [];
        data.forEach(PermissionSetAssignment => {
            allTargetPermissionSet.push({ 
                                        label: PermissionSetAssignment.PermissionSet.Name, 
                                        value: PermissionSetAssignment.PermissionSetId});
                                    });
            this.targetUserAssignPS = allTargetPermissionSet;
        console.log('this.targetUserAssignPS:::'+JSON.stringify(this.targetUserAssignPS));
    }else {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error Retriving Target User Permission Set.',
            message: 'Error fetching target User Permission Set.', error, 
            variant: 'Error'}));
        }
}

handlePermissionSetChangeSource(event){
    this.sourceCustomPermissions[event.target.dataset.id] = event.target.checked;
    console.log('this.sourceCustomPermissions:::'+JSON.stringify(this.sourceCustomPermissions));

}
handlePermissionSetChangeTarget(event){
    this.targetCustomPermissions[event.target.dataset.id] = event.target.checked;
    console.log('event.target.dataset.id:::'+this.targetCustomPermissions[event.target.dataset.id]+'event.target.checked::'+event.target.checked);
    console.log('this.targetCustomPermissions:::'+JSON.stringify(this.targetCustomPermissions));

}



handlePermissionSetChangeUpgradeSource(event){
    this.targetUpgradePermissions[event.target.dataset.id] = event.target.checked;
    console.log('event.target.dataset.id:::'+this.targetUpgradePermissions[event.target.dataset.id]+'event.target.checked::'+event.target.checked);
    console.log('this.targetCustomPermissions:::'+JSON.stringify(this.targetUpgradePermissions));

}
handlePermissionSetChangeCloneSource(event){
    this.targetClonePermissions[event.target.dataset.id] = event.target.checked;
    console.log('event.target.dataset.id:::'+this.targetClonePermissions[event.target.dataset.id]+'event.target.checked::'+event.target.checked);
    console.log('this.targetClonePermissions:::'+JSON.stringify(this.targetClonePermissions));

}



handleClonePermission(event){
    this.clonePermission = event.target.checked;
    this.upgradePermission = false;
    this.customPermission = false;
       
}
handleUpgradePermission(event){
    this.upgradePermission = event.target.checked;
    this.clonePermission = false;
    this.customPermission = false;

}
handleCustomPermission(event){
    this.customPermission = event.target.checked;
    this.clonePermission = false;
    this.upgradePermission = false;
    
}

//Assigning permissions Set to Target User.
handleSave() {
    if (this.sourceUserId && this.targetUserId && (this.upgradePermission || this.clonePermission || this.customPermission)) {
        console.log('custom'+this.customPermission);

                if(this.customPermission){
                    console.log('custom');
                                    assignCustomPermissionSetsToTargetUser({sourceUserId: this.sourceUserId, 
                                                                targetUserId : this.targetUserId, 
                                                                customSource :JSON.stringify(this.sourceCustomPermissions), 
                                                                customTarget :JSON.stringify(this.targetCustomPermissions) })
                                        .then(result => {
                                        this.dispatchEvent(new ShowToastEvent({
                                        title: 'Success',
                                        message: 'Permissions are being assigned successfully'+ result,
                                        variant: 'success'}));
                                        })
                                        .catch(error => {
                                        console.error('Error fetching assigned permission sets for source user:', error);
                                        this.dispatchEvent(new ShowToastEvent({
                                        title: 'Faild Permission set assignement',
                                        message: 'Error fetching assigned permission sets for source user:', error, 
                                        variant: 'destructive-text'}));
                                        });

                                        this.sourceCustomPermissions.forEach((value, key) => {
                                        console.log(`Key: ${key}, Value:`, JSON.stringify(value)); 
                                        });
                                        this.targetCustomPermissions.forEach((value, key) => {
                                        console.log(`Key: ${key}, Value:`, JSON.stringify(value)); 
                                        });
                    
                



                }else if(this.upgradePermission){
                    console.log('upgrade');
                    
                        upgradePermissionSetoftargetUser({sourceUserId: this.sourceUserId, 
                                                            targetUserId : this.targetUserId,
                                                            upgradeTarget :JSON.stringify(this.targetUpgradePermissions), 
                        })
                        .then(result => {
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Success',
                                message: 'Permissions are being assigned successfully'+ result,
                                variant: 'success'}));
                            })
                            .catch(error => {
                                console.error('Error fetching assigned permission sets for source user:', error);
                                this.dispatchEvent(new ShowToastEvent({
                                title: 'Faild Permission set assignement',
                                message: 'Error fetching assigned permission sets for source user:', error, 
                                variant: 'destructive-text'}));
                            });
                    
                
                }else if(this.clonePermission){
                        clonePermissionSetOfTargetUser({sourceUserId: this.sourceUserId, 
                            targetUserId : this.targetUserId,
                            cloneTarget :JSON.stringify(this.targetClonePermissions), 
                            })
                            .then(result => {
                                this.dispatchEvent(new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Permissions are being assigned successfully'+ result,
                                    variant: 'success'}));
                                })
                                .catch(error => {
                                    console.error('Error fetching assigned permission sets for source user:', error);
                                    this.dispatchEvent(new ShowToastEvent({
                                    title: 'Faild Permission set assignement',
                                    message: 'Error fetching assigned permission sets for source user:', error, 
                                    variant: 'destructive-text'}));
                                });
                    
                    
                }   
    }else if(this.sourceUserId && this.targetUserId == null){
        console.log('targetnull');
         this.dispatchEvent(new ShowToastEvent({
            title: 'TargetUser is Null',
            message: 'Please select target user',
            variant: 'destructive-text'}));
    }else if(this.sourceUserId == null && this.targetUserId){
        console.log('sourcenull');
        this.dispatchEvent(new ShowToastEvent({
            title: 'SourceUser Is Null',
            message: 'Please select source user',
            variant: 'destructive-text'}));
    }else if(this.sourceUserId == null && this.targetUserId == null){
        console.log('sourcetarget');
        this.dispatchEvent(new ShowToastEvent({
            title: 'SourceUser TargetUser Havent selected',
            message: 'Please select source and target user',
            variant: 'destructive-text'})); 
    }else{
        console.log('upgradeclonecustom');
        this.dispatchEvent(new ShowToastEvent({
            title: 'Havent Check permission checkbox',
            message: 'Please select UpgradePermission or ClonePermission or CustomePermission',
            variant: 'destructive-text'}));
    }
}





}