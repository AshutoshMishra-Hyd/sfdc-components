/**
 * @description Provides Opportunity data for LWC datatable and handles updates.
 */
public with sharing class OpportunityDataController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityWrapper> getOpportunities() {
        List<Opportunity> opps = [
            SELECT Id, Name, AccountId, Account.Name, StageName, CloseDate, IsPrivate
            FROM Opportunity
            ORDER BY LastModifiedDate DESC
            LIMIT 200
        ];
        List<OpportunityWrapper> wraps = new List<OpportunityWrapper>();
        for (Opportunity o : opps) {
            wraps.add(new OpportunityWrapper(o));
        }
        return wraps;
    }

    @AuraEnabled
    public static List<OpportunityWrapper> updateOpportunities(List<OpportunityWrapper> updates) {
        if (updates == null || updates.isEmpty()) {
            return new List<OpportunityWrapper>();
        }
        // Collect Ids from wrapper list
        Set<Id> updateIds = new Set<Id>();
        for (OpportunityWrapper w : updates) {
            if (w.Id != null) updateIds.add(w.Id);
        }
        if (updateIds.isEmpty()) {
            return new List<OpportunityWrapper>();
        }
        Map<Id, Opportunity> existing = new Map<Id, Opportunity>([
            SELECT Id FROM Opportunity WHERE Id IN :updateIds
        ]);
        List<Opportunity> toUpdate = new List<Opportunity>();
        for (OpportunityWrapper wrap : updates) {
            if (existing.containsKey(wrap.Id)) {
                Opportunity o = new Opportunity(Id = wrap.Id);
                if (wrap.Name != null) o.Name = wrap.Name;
                if (wrap.AccountId != null) o.AccountId = wrap.AccountId;
                if (wrap.StageName != null) o.StageName = wrap.StageName;
                if (wrap.CloseDate != null) o.CloseDate = wrap.CloseDate;
                if (wrap.IsPrivate != null) o.IsPrivate = wrap.IsPrivate;
                toUpdate.add(o);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        // Return fresh data for those updated
        List<Opportunity> refreshed = new List<Opportunity>();
        if (!toUpdate.isEmpty()) {
            Set<Id> refreshedIds = new Set<Id>();
            for (Opportunity oRec : toUpdate) refreshedIds.add(oRec.Id);
            refreshed = [
                SELECT Id, Name, AccountId, Account.Name, StageName, CloseDate, IsPrivate
                FROM Opportunity WHERE Id IN :refreshedIds
            ];
        }
        List<OpportunityWrapper> result = new List<OpportunityWrapper>();
        for (Opportunity o : refreshed) {
            result.add(new OpportunityWrapper(o));
        }
        return result;
    }

    public class OpportunityWrapper {
        @AuraEnabled public Id Id { get; set; }
        @AuraEnabled public String Name { get; set; }
        @AuraEnabled public Id AccountId { get; set; }
        @AuraEnabled public String AccountName { get; set; }
        @AuraEnabled public String StageName { get; set; }
        @AuraEnabled public Date CloseDate { get; set; }
        @AuraEnabled public Boolean IsPrivate { get; set; }

        public OpportunityWrapper() {}
        public OpportunityWrapper(Opportunity o) {
            this.Id = o.Id;
            this.Name = o.Name;
            this.AccountId = o.AccountId;
            this.AccountName = o.Account != null ? o.Account.Name : null;
            this.StageName = o.StageName;
            this.CloseDate = o.CloseDate;
            this.IsPrivate = o.IsPrivate;
        }
    }

    // ---------- Additional Support for Custom Editable Table ----------

    /**
     * @description Search Accounts for lookup component (Name LIKE %term%). Returns top 20.
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupOption> searchAccounts(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<LookupOption>();
        }
        String likeTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        List<Account> accts = [SELECT Id, Name FROM Account WHERE Name LIKE :likeTerm ORDER BY Name LIMIT 20];
        List<LookupOption> options = new List<LookupOption>();
        for (Account a : accts) {
            options.add(new LookupOption(a.Id, a.Name));
        }
        return options;
    }

    /**
     * @description Returns picklist values for the Opportunity.StageName field for use in custom UI.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getStageOptions() {
        // Describe picklist
        Schema.DescribeFieldResult dfr = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
        List<String> values = new List<String>();
        for (Schema.PicklistEntry e : entries) {
            if (e.isActive()) {
                values.add(e.getValue());
            }
        }
        return values;
    }

    /**
     * @description Simple label/value pair for lookup search results.
     */
    public class LookupOption {
        @AuraEnabled public Id value { get; set; }
        @AuraEnabled public String label { get; set; }
        public LookupOption(Id value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}
