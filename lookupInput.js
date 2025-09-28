import { LightningElement, api, track } from 'lwc';
import searchAccounts from '@salesforce/apex/OpportunityDataController.searchAccounts';

export default class LookupInput extends LightningElement {
    @api placeholder = 'Search Accounts';
    @api value; // selected record Id
    @api label; // not used in minimalist variant

    @track results = [];
    searchTerm = '';
    open = false;
    selection;
    searchDelay;

    connectedCallback() {
        if (this.value && this.label) {
            this.selection = { value: this.value, label: this.label };
        }
    }

    get hasSelection() {
        return !!this.selection;
    }

    get comboboxClass() {
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click' + (this.open ? ' slds-is-open' : '');
    }

    handleChange(event) {
        this.searchTerm = event.target.value;
        window.clearTimeout(this.searchDelay);
        this.searchDelay = setTimeout(() => {
            if (this.searchTerm && this.searchTerm.length >= 2) {
                this.performSearch();
            } else {
                this.results = [];
            }
        }, 300);
    }

    handleFocus() {
        this.open = true;
        if (this.searchTerm && this.searchTerm.length >= 2) {
            this.performSearch();
        }
    }

    handleBlur() {
        // Delay closing to allow click selection
        setTimeout(() => { this.open = false; }, 200);
    }

    performSearch() {
        searchAccounts({ searchTerm: this.searchTerm })
            .then(data => {
                this.results = data;
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error('Lookup search error', error);
                this.results = [];
            });
    }

    handleSelect(event) {
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label;
        this.selection = { value, label };
        this.value = value;
        this.dispatchEvent(new CustomEvent('select', { detail: { value, label } }));
        this.open = false;
        this.results = [];
    }

    clearSelection() {
        this.selection = null;
        this.value = null;
        this.dispatchEvent(new CustomEvent('select', { detail: { value: null, label: null } }));
    }
}
