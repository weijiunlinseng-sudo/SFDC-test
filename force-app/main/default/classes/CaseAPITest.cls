@IsTest
private class CaseAPITest {

    // Utility method to set up RestRequest/Response
    private static void setupRestContext(String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/createCase/';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void testCreateCase_Success() {
        String payload = JSON.serialize(new Map<String, Object>{
            'subject' => 'Test Case',
            'description' => 'This is a test',
            'origin' => 'Web',
            'name' => 'Test User',
            'phone' => '1234567890',
            'email' => 'test@example.com'
        });

        setupRestContext(payload);

        String response = CaseAPI.createCase();
        System.assertEquals(201, RestContext.response.statusCode, 'Status code should be 201');

        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);
        System.assertEquals('Case created successfully', (String) result.get('message'));

        // Verify case was inserted
        Case insertedCase = [SELECT Id, Subject, Origin, Status FROM Case WHERE Id = :((String) result.get('caseId')) LIMIT 1];
        System.assertEquals('Test Case', insertedCase.Subject);
        System.assertEquals('Web', insertedCase.Origin);
        System.assertEquals('New', insertedCase.Status);
    }
    
    @IsTest
    static void testCreateCase_EmptyJSON() {
        setupRestContext('');
        String response = CaseAPI.createCase();
        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(response.contains('Request body is empty'));
    }

    @IsTest
    static void testCreateCase_InvalidJSON() {
        setupRestContext('{badJson}');
        String response = CaseAPI.createCase();
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for invalid JSON');
        System.assert(response.contains('Invalid JSON format'));
    }

    @IsTest
    static void testCreateCase_MissingSubject() {
        String payload = JSON.serialize(new Map<String, Object>{
            'description' => 'Missing subject test',
            'origin' => 'Web'
        });

        setupRestContext(payload);
        String response = CaseAPI.createCase();
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 when subject is missing');
        System.assert(response.contains('Subject is required'));
    }
    
    @IsTest
    static void testCreateCase_MissingName() {
        String payload = JSON.serialize(new Map<String, Object>{
            'description' => 'Missing Name test',
            'origin' => 'Web',
            'subject' => 'Missing Name'
        });

        setupRestContext(payload);
        String response = CaseAPI.createCase();
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 when name is missing');
        System.assert(response.contains('Name is required'));
    }


    @IsTest
    static void testCreateCase_DmlException() {
        // Force a DML error by providing an Origin that violates field rules (e.g., too long string)
        String payload = JSON.serialize(new Map<String, Object>{
            'subject' => 'DML Failure',
            'description' => 'Forcing DML error',
            'origin' => String.valueOf('x').repeat(10000), // too long
            'name' => 'Bad Data'
        });

        setupRestContext(payload);
        String response = CaseAPI.createCase();
        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400 for DML error');
        System.assert(response.contains('Failed to create Case'));
    }
}