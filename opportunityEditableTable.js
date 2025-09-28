import { LightningElement, track } from 'lwc';
import getOpportunities from '@salesforce/apex/OpportunityDataController.getOpportunities';
import updateOpportunities from '@salesforce/apex/OpportunityDataController.updateOpportunities';
import getStageOptions from '@salesforce/apex/OpportunityDataController.getStageOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityEditableTable extends LightningElement {
    @track rows = [];
    originalMap = new Map();
    stageOptions = [];

    connectedCallback() {
        this.loadData();
        getStageOptions().then(list => {
            this.stageOptions = list.map(v => ({ label: v, value: v }));
        });
    }

    loadData() {
        getOpportunities()
            .then(data => {
                this.rows = data.map(r => ({
                    ...r,
                    editable: { ...r },
                    editingName: false,
                    editingAccount: false,
                    editingStage: false,
                    editingCloseDate: false,
                    editingIsPrivate: false
                }));
                // Store a true immutable snapshot of original editable values (not referencing same object)
                this.originalMap = new Map(this.rows.map(r => [r.Id, { ...r.editable }]));
            })
            .catch(e => this.toast('Error', this.reduceErrors(e).join(','), 'error'));
    }

    get saveDisabled() {
        return this.changedRows().length === 0;
    }

    changedRows() {
        const changed = [];
        for (const row of this.rows) {
            const orig = this.originalMap.get(row.Id);
            if (!orig) continue;
            if (this.isDifferent(orig.editable || orig, row.editable)) {
                changed.push(row);
            }
        }
        return changed;
    }

    isDifferent(a, b) {
        return ['Name', 'AccountId', 'StageName', 'CloseDate', 'IsPrivate'].some(f => a[f] !== b[f]);
    }

    handleFieldChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.updateRow(id, field, value);
    }

    handleCheckboxChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.checked;
        this.updateRow(id, field, value);
    }

    handleAccountSelect(event) {
        const wrapper = event.detail;
        const host = event.target; // c-lookup-input
        const id = host.dataset.id;
        const field = host.dataset.field;
        this.updateRow(id, field, wrapper.value);
        this.updateRow(id, 'AccountName', wrapper.label);
    this.finishSpecificEdit(id, 'Account');
    }

    updateRow(id, field, value) {
        this.rows = this.rows.map(r => {
            if (r.Id === id) {
                r.editable[field] = value;
            }
            return r;
        });
    }

    startEdit(event) {
        const id = event.currentTarget.dataset.id;
        const field = event.currentTarget.dataset.field;
        const editFlag = this.flagName(field);
        this.rows = this.rows.map(r => {
            if (r.Id === id) {
                r[editFlag] = true;
            }
            return r;
        });
    }

    finishEdit(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const editFlag = this.flagName(field);
        // small delay to allow checkbox / lookup click interactions
        setTimeout(() => {
            this.rows = this.rows.map(r => {
                if (r.Id === id) {
                    r[editFlag] = false;
                }
                return r;
            });
        }, 100);
    }

    finishSpecificEdit(id, logicalField) {
        const editFlag = this.flagName(logicalField);
        this.rows = this.rows.map(r => {
            if (r.Id === id) {
                r[editFlag] = false;
            }
            return r;
        });
    }

    flagName(field) {
        switch(field) {
            case 'Name': return 'editingName';
            case 'Account':
            case 'AccountId': return 'editingAccount';
            case 'Stage':
            case 'StageName': return 'editingStage';
            case 'CloseDate': return 'editingCloseDate';
            case 'IsPrivate': return 'editingIsPrivate';
            default: return 'editingGeneric';
        }
    }


    saveAll() {
        const updates = this.changedRows().map(r => r.editable);
        if (updates.length === 0) return;
        updateOpportunities({ updates })
            .then(result => {
                const resultMap = new Map(result.map(r => [r.Id, r]));
                this.rows = this.rows.map(row => {
                    if (resultMap.has(row.Id)) {
                        const newData = resultMap.get(row.Id);
                        return { ...newData, editable: { ...newData } };
                    }
                    return row;
                });
                // Reset snapshot after successful save
                this.originalMap = new Map(this.rows.map(r => [r.Id, { ...r.editable }]));
                this.toast('Success', 'Changes saved', 'success');
            })
            .catch(e => this.toast('Error saving', this.reduceErrors(e).join(','), 'error'));
    }

        cancelAll() {
            if (this.changedRows().length === 0) return;
            // Revert editable values to snapshot
            this.rows = this.rows.map(r => {
                const orig = this.originalMap.get(r.Id);
                if (orig) {
                    const reverted = { ...r, editable: { ...orig }, editingName:false, editingAccount:false, editingStage:false, editingCloseDate:false, editingIsPrivate:false };
                    return reverted;
                }
                return r;
            });
            this.toast('Info', 'Changes reverted', 'info');
        }

    refresh() {
        this.loadData();
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return errors
            .filter(error => !!error)
            .map(error => {
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message);
                } else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (typeof error.message === 'string') {
                    return error.message;
                }
                return error.statusText;
            })
            .reduce((prev, curr) => prev.concat(curr), [])
            .filter(message => !!message);
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
