/**
 * @description Test class for OpportunityDataController
 */
@IsTest
private class OpportunityDataControllerTest {
    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(30)
            ));
        }
        insert opps;
    }

    @IsTest
    static void testGetOpportunities() {
        Test.startTest();
        List<OpportunityDataController.OpportunityWrapper> results = OpportunityDataController.getOpportunities();
        Test.stopTest();
        System.assertNotEquals(0, results.size(), 'Should return some opportunities');
        OpportunityDataController.OpportunityWrapper first = results[0];
        System.assertNotEquals(null, first.Id);
        System.assertNotEquals(null, first.Name);
    }

    @IsTest
    static void testUpdateOpportunities() {
        List<OpportunityDataController.OpportunityWrapper> results = OpportunityDataController.getOpportunities();
        OpportunityDataController.OpportunityWrapper w = results[0];
        String newName = w.Name + ' Updated';
        w.Name = newName;
        w.StageName = 'Qualification';
        Date newDate = System.today().addDays(45);
        w.CloseDate = newDate;

        Test.startTest();
        List<OpportunityDataController.OpportunityWrapper> updated = OpportunityDataController.updateOpportunities(new List<OpportunityDataController.OpportunityWrapper>{ w });
        Test.stopTest();
        System.assertEquals(1, updated.size());
        System.assertEquals(newName, updated[0].Name);
        System.assertEquals('Qualification', updated[0].StageName);
        System.assertEquals(newDate, updated[0].CloseDate);
    }

    @IsTest
    static void testUpdateOpportunitiesEmpty() {
        Test.startTest();
        List<OpportunityDataController.OpportunityWrapper> updated = OpportunityDataController.updateOpportunities(new List<OpportunityDataController.OpportunityWrapper>());
        Test.stopTest();
        System.assertEquals(0, updated.size());
    }

    @IsTest
    static void testSearchAccounts() {
        Account a = [SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
        List<OpportunityDataController.LookupOption> options = OpportunityDataController.searchAccounts(a.Name.substring(0, 2));
        Test.stopTest();
        System.assert(options.size() > 0, 'Should return at least one account option');
        System.assertNotEquals(null, options[0].label);
    }

    @IsTest
    static void testGetStageOptions() {
        Test.startTest();
        List<String> stages = OpportunityDataController.getStageOptions();
        Test.stopTest();
        System.assert(stages.size() > 0, 'Expected some stage values');
    }
}
