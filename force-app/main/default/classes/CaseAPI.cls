@RestResource(urlMapping='/createCase/*')
global with sharing class CaseAPI {

    @HttpPost
    global static String createCase() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Parse JSON input
            if (req.requestBody == null || String.isBlank(req.requestBody.toString())) {
                res.statusCode = 400;
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Request body is empty'
                });
            }

            Map<String, Object> data;
            try {
                data = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            } catch (Exception e) {
                res.statusCode = 400;
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Invalid JSON format',
                    'details' => e.getMessage()
                });
            }

            // Basic validation, take subject or name as example
            if (String.isBlank((String) data.get('subject'))) {
                res.statusCode = 400;
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Subject is required'
                });
            }
            if (String.isBlank((String) data.get('name'))) {
                res.statusCode = 400;
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Name is required'
                });
            }

            // Create Case record
            Case newCase = new Case(
                Subject      = (String) data.get('subject'),
                Description  = (String) data.get('description'),
                Status       = 'New', // force to New
                Origin       = (String) data.get('origin'),
                SuppliedName = (String) data.get('name'),
                SuppliedPhone= (String) data.get('phone'),
                SuppliedEmail= (String) data.get('email')
            );

            try {
                insert newCase;
            } catch (DmlException dmlEx) {
                res.statusCode = 400;
                return JSON.serialize(new Map<String, Object>{
                    'error' => 'Failed to create Case',
                    'details' => dmlEx.getMessage()
                });
            }

            // Success response
            res.statusCode = 201;
            return JSON.serialize(new Map<String, Object>{
                'message' => 'Case created successfully',
                'caseId' => newCase.Id
            });

        } catch (Exception ex) {
            // Catch-all for unexpected errors
            res.statusCode = 500;
            return JSON.serialize(new Map<String, Object>{
                'error' => 'Unexpected server error',
                'details' => ex.getMessage()
            });
        }
    }
}