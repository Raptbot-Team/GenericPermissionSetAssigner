import { LightningElement,track ,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import assignCustomPermissionSetsToTargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.assignCustomPermissionSetsToTargetUser';
import clonePermissionSetOfTargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.clonePermissionSetOfTargetUser';
import getSourcePermissionSet from '@salesforce/apex/GenericPermissionSetAssignerHandler.getSourcePermissionSet';
import getSourceUsers from '@salesforce/apex/GenericPermissionSetAssignerHandler.getSourceUsers';
import getTargetPermissionSet from '@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetPermissionSet';
import getTargetUsers from '@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetUsers';
import isAccForUserObje from '@salesforce/apex/GenericPermissionSetAssignerHandler.isAccForUserObje';
import upgradePermissionSetoftargetUser from '@salesforce/apex/GenericPermissionSetAssignerHandler.upgradePermissionSetoftargetUser';
export default class GenericPermissionSetAssignerComponent extends LightningElement {
    @track optionsForSource = [];
    @track optionsForTarget = [];
    @track sourceUserAssignPS = [];
    @track targetUserAssignPS = [];
    @track dualListboxOptions = [];
    @track selectedDualPermissionSet = [];
    storeselectedDualPermissionSet =[];
    targetUpgradePermissions = new Map();
    targetClonePermissions = new Map();
    isUserObjAccessible = false;
    isLoaded = false;
    errorMessage;
    customPermissionResult;
    upgradePermissionResult;
    ClonePermissionResult;
    @track cancelTriggered = false;
    @track upgradePermission = false;
    @track clonePermission = false;
    @track customPermission = false;
    @track sourceUserId;
    @track targetUserId;
    @track  showContent = false;

        handleSectionToggle(event) {
            const ActiveSections = event.detail.openSections;
            if (ActiveSections.includes('CustomPermission')) {
                this.setCustomPermissionState();
            } else if (ActiveSections.includes('UpgradePermission')) {
                this.setUpgradePermissionState();
            } else if (ActiveSections.includes('ClonePermission')) {
                this.setClonePermissionState();
            }
        }  
        
        setCustomPermissionState() {
            this.customPermission = true;
            this.selectedDualPermissionSet = this.storeselectedDualPermissionSet;
            this.targetUpgradePermissions = new Map();
            this.targetClonePermissions = new Map();
            this.resetPermissions(['upgrade', 'clone']);
        }
        setUpgradePermissionState() {
            this.upgradePermission = true;
            this.selectedDualPermissionSet = [];
            this.targetClonePermissions = new Map();
            this.resetPermissions(['custom', 'clone']);
        }
        setClonePermissionState() {
            this.clonePermission = true;
            this.selectedDualPermissionSet = [];
            this.targetUpgradePermissions = new Map();
            this.resetPermissions(['custom', 'upgrade']);
        }
        resetPermissions(statesToReset) {
            if (statesToReset.includes('custom')) {
                this.customPermission = false;
            }
            if (statesToReset.includes('upgrade')) {
                this.upgradePermission = false;
                this.targetUpgradePermissions = new Map();
            }
            if (statesToReset.includes('clone')) {
                this.clonePermission = false;
                this.targetClonePermissions = new Map();
            }
        }      
    showToast(title, message, variant) {
        if(!import.meta.env.SSR){
            this.dispatchEvent( new ShowToastEvent({ message, title, variant,}) );
        }  
    }
    checkUserObjectAccessibility() {
        isAccForUserObje()
            .then((data) => {   
                this.isUserObjAccessible = data;
                if(this.isUserObjAccessible){
                    this.loadSourceUsers();
                }else{
                    this.showToast('Insufficient Access', `Contact your system administrator: You do not have permission to manage users.`, 'Error' );   
                }
            })
            .catch((error) => {     
                this.errorMessage = error.body.message;
                this.showToast( 'Insufficient Access', `Contact your system administrator: ${this.errorMessage}`, 'Error');
            })
            .finally(() => { this.isLoaded = true; });
    }

   connectedCallback() {
   this.loadData();
   }
    loadSourceUsers() {
        getSourceUsers()
            .then((data) => {
                const allUsers = [];
                data.forEach((user) => {
                    allUsers.push({ label: user.Name, value: user.Id });
                });
                this.optionsForSource = allUsers;
            })
            .catch((error) => {
                const errorMessage = error.body.message;
                this.showToast('No user exists in this org.', `Error Fetching Source User: ${errorMessage}`, 'Error');
            }); }
    handleSourceChange(event) {
        this.sourceUserId = event.detail.value;
        this.targetUserId = undefined;
        this.optionsForTarget = [];
        this.targetUserAssignPS = [];
        this.sourceUserAssignPS = [];
        this.targetUpgradePermissions = new Map();
        this.targetClonePermissions = new Map();
        this.dualListboxOptions = [];
        this.selectedDualPermissionSet = [];
        this.showContent = false;
    }
    handleTargetChange(event) {
        this.targetUserId = event.detail.value;
        this.showContent = true;
    }
    @wire(getTargetUsers, { userId: '$sourceUserId' })
    Targetusers({ error, data }) {
        if (data) {
            const allUsers = [];
            data.forEach(user => {
                allUsers.push({ label: user.Name, value: user.Id });
            });
            this.optionsForTarget = allUsers;
        } else if(error) {
            const errorMessage = error.body.message;
            this.showToast('Error retriving target user.',`${errorMessage}`,'Error');
        }else{
            this.showToast('Error retriving target user.','Error fetching target User.','Error'); 
        }
    }
    @wire(getSourcePermissionSet, { sourceUser: '$sourceUserId' })
    SourceUserAssignedPS({ error, data }) {
        if (data) {
            const allSourcePermissionSet = [];
            data.forEach(PermissionSetAssignment => {
                allSourcePermissionSet.push({label: PermissionSetAssignment.PermissionSet.Label, value: PermissionSetAssignment.PermissionSetId});
            });
            this.dualListboxOptions = allSourcePermissionSet;
            this.sourceUserAssignPS = allSourcePermissionSet;
        } else if(error) {
            const errorMessage = error.body.message;
            this.showToast('Error retriving the source sser permission set.',` ${errorMessage}`,'Error' );
        }else{
            this.showToast('Error retriving the source user permission set.','Error while fetching the source user permission set.','Error' ); 
        }
    }
    @wire(getTargetPermissionSet, { targetUser: '$targetUserId' })
    TargetUserAssignedPS({ error, data }) {
        if (data) {
            // Map data to dual listbox options
            const allTargetPermissionSet = data.map(PermissionSetAssignment => ({
                label: PermissionSetAssignment.PermissionSet.Label,
                value: PermissionSetAssignment.PermissionSetId
            }));
            this.selectedDualPermissionSet = allTargetPermissionSet.map(permissionSet => permissionSet.value);
            this.dualListboxOptions = [ ...this.dualListboxOptions, ...allTargetPermissionSet].filter((item, index, self) => index === self.findIndex(option => option.value === item.value) );
            this.targetUserAssignPS = allTargetPermissionSet;
            this.storeselectedDualPermissionSet = this.selectedDualPermissionSet;
        } else if(error){
            const errorMessage = error.body.message;
            this.showToast('Error retrieving the target user permission set.', `${errorMessage}`,'Error' );
        }else{
            this.showToast('Error retrieving the target user permission set.', 'Error while fetching the target user permission set.','Error' );
        }
    }
    handleChangePSForCustomFunctionality(event){
        this.selectedDualPermissionSet = event.detail.value;
    }     
    handlePermissionSetChangeUpgradeSource(event) {
        this.targetUpgradePermissions[event.target.dataset.id] = event.target.checked;
    }
    handlePermissionSetChangeCloneSource(event) {
        this.targetClonePermissions[event.target.dataset.id] = event.target.checked;
    }
        handleSave() {
            if (this.isValidInputs()) {
                if (this.customPermission) {
                    this.assignCustomPermissions();
                } else if (this.upgradePermission) {
                    this.upgradePermissions();
                } else if (this.clonePermission) {
                    this.clonePermissions();
                }
            } else {
                this.showValidationErrors();
            }
        }
        handleCancel() {
            this.cancelTriggered = true; 
            window.location.reload();
        }
        // Check if the inputs are valid
        isValidInputs() {
            const EMPTY_ARRAY_LENGTH = 0;
            return this.sourceUserId && this.targetUserId &&
            ((this.upgradePermission && Object.keys(this.targetUpgradePermissions).length) || (this.clonePermission && Object.keys(this.targetClonePermissions).length) || ( this.customPermission &&
            this.selectedDualPermissionSet.length > EMPTY_ARRAY_LENGTH));
        }
        // Show validation error messages
        showValidationErrors() {
            if (this.sourceUserId && !this.targetUserId) {
                this.showToast('Target User is not selected', 'Please select a target user to proceed.', 'error');
            } else if (!this.sourceUserId && this.targetUserId) {
                this.showToast('Source User Is not selected', 'Please select a source user to proceed', 'error');
            } else if (!this.sourceUserId && !this.targetUserId) {
                this.showToast('Source User and Target User has not been selected', 'Please select both source and target users to continue.', 'error');
            } else if (!this.upgradePermission && !this.clonePermission && !this.customPermission) {
                this.showToast('Permission type not selected', ' Please choose Custom, Upgrade, or Clone to proceed.', 'error');
            } else {
                this.showToast('No permission sets have been selected.', 'Please select at least one permission set to assign to the target user.', 'error');
            }
        } 
        // Assign custom permissions to the target user
        assignCustomPermissions() {
            assignCustomPermissionSetsToTargetUser({customPSSelected: this.selectedDualPermissionSet, sourceUserId: this.sourceUserId, targetUserId: this.targetUserId                    
            })
            .then(result => {
                this.customPermissionResult = result;
                this.showToast('Success!', 'Permissions have been successfully assigned.', 'success');
                this.refreshComponentAfterDelay();
            })
            .catch(error => {
                this.handlePermissionAssignmentError(error);
                this.refreshComponentAfterDelay();         
            });
        }
        // Upgrade permissions for the target user
        upgradePermissions() {
            upgradePermissionSetoftargetUser({sourceUserId: this.sourceUserId, targetUserId: this.targetUserId, upgradeTarget: JSON.stringify(this.targetUpgradePermissions)
            })
            .then(result => {
                const EMPTY_ARRAY_LENGTH = 0;
                if (result.length > EMPTY_ARRAY_LENGTH) {
                    result.forEach(message => {
                        if (message.startsWith('Something went wrong')) {
                            this.showToast('Error', message, 'error');
                            this.refreshComponentAfterDelay();
                        } else if (message.startsWith('Upgrade Action Failed')) {
                            this.showToast('Warning', message, 'Warning');
                            this.refreshComponentAfterDelay();
                        } else if (message.startsWith('No Changes')) {
                            this.showToast('Warning', message, 'warning');
                            this.refreshComponentAfterDelay();
                        }
                    });
                } else {
                    this.showToast('Success!', 'Permissions have been successfully assigned.', 'success');
                    this.refreshComponentAfterDelay();
                }
            })
            .catch(error => {
                this.handlePermissionAssignmentError(error); 
                this.refreshComponentAfterDelay(); 
             });
        } 
        // Clone permissions for the target user
        clonePermissions() {
            clonePermissionSetOfTargetUser({cloneTarget: JSON.stringify(this.targetClonePermissions), sourceUserId: this.sourceUserId, targetUserId: this.targetUserId
            })
            .then(result => {
                this.clonePermissionResult = result;
                this.showToast('Success!', 'Permissions have been successfully assigned.', 'success');
                this.refreshComponentAfterDelay();
            })
            .catch(error => {
                this.handlePermissionAssignmentError(error);
                this.refreshComponentAfterDelay();
            });
        }
        loadData() {
            this.checkUserObjectAccessibility();
        }
        // Handle error for permission assignment
        handlePermissionAssignmentError(error) {
            const errorMessage = error.body.message;
            this.showToast('Failed to Assign Permission Set ', `${errorMessage}`, 'error');
        }
        refreshComponentAfterDelay() {
            const RELOAD_DELAY = 1000; 
            this.isLoaded =false;
            setTimeout(() => {
                window.location.reload();
            }, RELOAD_DELAY);
        }       
}