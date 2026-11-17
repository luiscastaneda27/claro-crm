/**
 * @description Processing class for TMF621 Trouble Ticket Management API
 * @author Josue Aguilar - Salesforce
 * @version 1.0
 */
public with sharing class FVU_TMF621Processing extends FVU_TMFBase {
    
    private static final String API_NAME = 'TMF621';
    
    /**
     * @description Constructor
     */
    public FVU_TMF621Processing() {
        super(API_NAME);
    }
    
    /**
     * @description Main request processor - orchestrates all operations
     * @param operation HTTP operation (POST, GET, PATCH, DELETE)
     * @param payload Request payload
     * @return Response object
     */
    public override Object processRequest(String operation, Map<String, Object> payload) {
        
        // 1. Validate request
        ValidationResult validationResult = validateRequest(operation, payload);
        
        if (!validationResult.isValid) {
            return buildErrorResponse(validationResult.errors);
        }
        
        // 2. Route to appropriate handler
        try {
            switch on operation {
                when 'POST' {
                    return createTroubleTicket(payload);
                }
                /*when 'GET' {
                    return retrieveTroubleTickets(payload);
                }
                when 'PATCH' {
                    return updateTroubleTicket(payload);
                }*/
                when else {
                    return buildErrorResponse(new List<TMFError>{
                        buildError('TMF-405-001', 'Method not allowed', 405)
                    });
                }
            }
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-002', 'Processing error: ' + e.getMessage(), 500)
            });
        }
    }
    
    /**
     * @description Creates a new Trouble Ticket (Case) via existing Integration Procedure
     * @param payload Trouble Ticket data in TMF format
     * @return Created ticket with ID and href
     */
    @TestVisible
    private Object createTroubleTicket(Map<String, Object> payload) {
        
        // Transform TMF payload to IP format
        Map<String, Object> ipPayload = transformToIPFormat(payload);
        System.debug('Payload IP: '+JSON.serialize(ipPayload));
        
        if (ipPayload == null) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-003', 'Failed to transform payload', 500)
            });
        }
        
        // Call existing Integration Procedure
        Map<String, Object> ipInput = ipPayload;
        
        Map<String, Object> ipOutput = new Map<String, Object>();
        Map<String, Object> ipOptions = new Map<String, Object>();
        
        try {
            // Call IP using vlocity_cmt namespace
            ipOutput = (Map <String, Object>) vlocity_cmt.IntegrationProcedureService.runIntegrationService(
                'PVU_CreateTroubleTicket',
                ipInput,
                ipOptions
            );
            
            System.debug('Response IP: '+JSON.serialize(ipOutput));
            // Parse IP response
            IPResponse ipResponse = parseIPResponse(ipOutput);
            
            if (!ipResponse.success) {
                return buildErrorResponse(new List<TMFError>{
                    buildError(ipResponse.errorCode, ipResponse.errorMessage, ipResponse.httpStatus)
                });
            }
            
            /*// Process notes and attachments after Case creation
            if (payload.containsKey('note')) {
                processNotes(ipResponse.caseId, (List<Object>)payload.get('note'));
            }
            
            if (payload.containsKey('attachment')) {
                processAttachments(ipResponse.caseId, (List<Object>)payload.get('attachment'));
            }*/
            
            // Build TMF response from Case ID
            return buildTMFResponseFromIP(ipResponse.caseId, ipResponse.caseNumber, payload);
            
        } catch (Exception e) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-500-005', 'IP execution error: ' + e.getMessage(), 500)
            });
        }
    }

    /**
     * @description Transforms TMF621 payload to existing IP format
     * Handles the conversion from TMF standard to legacy format
     * @param tmfPayload Request in TMF format
     * @return Payload in IP format
     */
    @TestVisible
    private Map<String, Object> transformToIPFormat(Map<String, Object> tmfPayload) {
        
        Map<String, Object> ipPayload = new Map<String, Object>();
        
        try {
            // 1. Direct field mappings (no transformation needed)
            if (tmfPayload.containsKey('status')) {
                ipPayload.put('status', tmfPayload.get('status'));
            }
            
            if (tmfPayload.containsKey('description')) {
                ipPayload.put('description', tmfPayload.get('description'));
            }

            if (tmfPayload.containsKey('priority')) {
                ipPayload.put('priority', tmfPayload.get('priority'));
            }
            
            if (tmfPayload.containsKey('category')) {
                ipPayload.put('category', tmfPayload.get('category'));
            }
            
            if (tmfPayload.containsKey('subcategory')) {
                ipPayload.put('subcategory', tmfPayload.get('subcategory'));
            }
            
            if (tmfPayload.containsKey('customerVoice')) {
                ipPayload.put('customerVoice', tmfPayload.get('customerVoice'));
            }

            if (tmfPayload.containsKey('subscriberNumber')) {
                ipPayload.put('subscriberNumber', tmfPayload.get('subscriberNumber'));
            }

            if (tmfPayload.containsKey('@type')) {
                ipPayload.put('@type', tmfPayload.get('@type'));
            }
            
            /*// 2. Transform ticketType to @type
            if (tmfPayload.containsKey('ticketType')) {
                ipPayload.put('@type', tmfPayload.get('ticketType'));
            }*/
            
            // 3. Transform channel (no change in structure)
            if (tmfPayload.containsKey('channel')) {
                ipPayload.put('channel', tmfPayload.get('channel'));
            }
            
            // 4. Copy troubleTicketCharacteristic as-is
            if (tmfPayload.containsKey('troubleTicketCharacteristic')) {
                ipPayload.put('troubleTicketCharacteristic', 
                    tmfPayload.get('troubleTicketCharacteristic'));
            }
            
            // 5. Transform relatedParty to documentType/documentNumber
            if (tmfPayload.containsKey('relatedParty')) {
                List<Object> relatedParties = (List<Object>)tmfPayload.get('relatedParty');
                
                if (!relatedParties.isEmpty()) {
                    Map<String, Object> primaryParty = (Map<String, Object>)relatedParties[0];
                    String partyId = (String)primaryParty.get('id');
                    String referredType = (String)primaryParty.get('@referredType');
                    
                    if (String.isNotBlank(partyId)) {
                        // Lookup Account or Contact to get document info
                        Map<String, String> documentInfo = getDocumentInfoFromParty(
                            partyId, 
                            referredType
                        );
                        
                        if (documentInfo != null) {
                            if (documentInfo.containsKey('documentType')) {
                                ipPayload.put('documentType', documentInfo.get('documentType'));
                            }
                            if (documentInfo.containsKey('documentNumber')) {
                                ipPayload.put('documentNumber', documentInfo.get('documentNumber'));
                            }
                        }
                    }
                }
            }
            
            return ipPayload;
            
        } catch (Exception e) {
            System.debug('Error transforming payload: ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Retrieves document information from Account or Contact
     * @param partyId Salesforce ID of Account or Contact
     * @param referredType Type of entity (Account or Contact)
     * @return Map with documentType, documentNumber, subscriberNumber
     */
    @TestVisible
    private Map<String, String> getDocumentInfoFromParty(String partyId, String referredType) {
        
        Map<String, String> result = new Map<String, String>();
        
        try {
            if (referredType == 'Account' || String.isBlank(referredType)) {
                // Query Account
                List<Account> accounts = [
                    SELECT Id,
                       FVU_DocumentType__c,
                       FVU_DocumentNumber__c
                    FROM Account
                    WHERE Id = :partyId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                
                if (!accounts.isEmpty()) {
                    Account acc = accounts[0];
                    
                    // Get document info from Account
                    if (String.isNotBlank(acc.FVU_DocumentType__c)) {
                        result.put('documentType', acc.FVU_DocumentType__c);
                    }
                    if (String.isNotBlank(acc.FVU_DocumentNumber__c)) {
                        result.put('documentNumber', acc.FVU_DocumentNumber__c);
                    }
                }
                
            } else if (referredType == 'Contact') {
                // Query Contact directly
                List<Contact> contacts = [
                    SELECT FVU_DocumentType__c, FVU_DocumentNumber__c
                    FROM Contact
                    WHERE Id = :partyId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                
                if (!contacts.isEmpty()) {
                    Contact con = contacts[0];
                    
                    if (String.isNotBlank(con.FVU_DocumentType__c)) {
                        result.put('documentType', con.FVU_DocumentType__c);
                    }
                    if (String.isNotBlank(con.FVU_DocumentNumber__c)) {
                        result.put('documentNumber', con.FVU_DocumentNumber__c);
                    }

                }
            }
            
        } catch (Exception e) {
            System.debug('Error querying party info: ' + e.getMessage());
        }
        
        return result.isEmpty() ? null : result;
    }
    
    /**
     * @description Parses Integration Procedure response
     * IP Response format:
     * {
     *   "code": "200",
     *   "status": "Success",
     *   "message": "Case created",
     *   "attributes": {
     *     "id": "00003110",
     *     "href": "/services/data/v57.0/sobjects/Case/50078000002rf0BAAQ",
     *     "type": "Case"
     *   }
     * }
     * @param ipOutput Output from Integration Procedure
     * @return IPResponse wrapper object
     */
    @TestVisible
    private IPResponse parseIPResponse(Map<String, Object> ipOutput) {
        IPResponse response = new IPResponse();
        
        try {
            // Check if IP returned error
            if (ipOutput.containsKey('error')) {
                response.success = false;
                response.errorMessage = String.valueOf(ipOutput.get('error'));
                response.errorCode = 'TMF-500-004';
                response.httpStatus = 500;
                return response;
            }
            
            // Parse response
            String code = ipOutput.containsKey('code') ? String.valueOf(ipOutput.get('code')) : null;
            String status = ipOutput.containsKey('status') ? String.valueOf(ipOutput.get('status')) : null;
            String message = ipOutput.containsKey('message') ? String.valueOf(ipOutput.get('message')) : 'No message provided';
            
            if (code == '200' && status == 'Success') {
                // Extract attributes
                if (ipOutput.containsKey('attributes')) {
                    Map<String, Object> attributes = (Map<String, Object>)ipOutput.get('attributes');
                    // Get Case Number (id in attributes is CaseNumber, not Salesforce ID)
                    if (attributes.containsKey('Id')) {
                        response.caseNumber = String.valueOf(attributes.get('Id'));
                    } else if (attributes.containsKey('id')) {
                        response.caseNumber = String.valueOf(attributes.get('id'));
                    }
                    // Extract Salesforce Case ID from href
                    // Format: "/services/data/v57.0/sobjects/Case/50078000002rf0BAAQ"
                    if (attributes.containsKey('href')) {
                        String href = String.valueOf(attributes.get('href'));
                        List<String> hrefParts = href.split('/');
                        if (!hrefParts.isEmpty()) {
                            response.caseId = hrefParts[hrefParts.size() - 1];
                        }
                    }
                }
                // Validate we got required data
                if (String.isBlank(response.caseId) || String.isBlank(response.caseNumber)) {
                    response.success = false;
                    response.errorMessage = 'Invalid IP response: missing case ID or number';
                    response.errorCode = 'TMF-500-005';
                    response.httpStatus = 500;
                    return response;
                }
                response.success = true;
                return response;
            }
            
            response.success = false;
            response.errorMessage = message;

            if (code != null) {
                IPErrorMapping errorMapping = mapIPErrorToTMF(code, message);
                response.errorCode = errorMapping.tmfCode;
                response.httpStatus = errorMapping.httpStatus;
            } else {
                response.errorCode = 'TMF-500-004';
                response.httpStatus = 500;
            }
            
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = 'Error parsing IP response: ' + e.getMessage();
            response.errorCode = 'TMF-500-006';
            response.httpStatus = 500;
        }
        
        return response;
    }

    @TestVisible
    private IPErrorMapping mapIPErrorToTMF(String ipCode, String ipMessage) {
        IPErrorMapping mapping = new IPErrorMapping();
        if (ipCode == '400') { mapping.tmfCode = 'TMF-400-020'; mapping.httpStatus = 400; }
        else if (ipCode == '404') { mapping.tmfCode = 'TMF-404-003'; mapping.httpStatus = 404; }
        else if (ipCode == '409') { mapping.tmfCode = 'TMF-409-001'; mapping.httpStatus = 409; }
        else if (ipCode == '422') { mapping.tmfCode = 'TMF-422-001'; mapping.httpStatus = 422; }
        else if (ipCode == '500') { mapping.tmfCode = 'TMF-500-007'; mapping.httpStatus = 500; }
        else { mapping.tmfCode = 'TMF-500-008'; mapping.httpStatus = 500; }
        
        if (ipMessage.containsIgnoreCase('required')) { mapping.tmfCode = 'TMF-400-021'; mapping.httpStatus = 400; }
        else if (ipMessage.containsIgnoreCase('not found')) { mapping.tmfCode = 'TMF-404-003'; mapping.httpStatus = 404; }
        else if (ipMessage.containsIgnoreCase('duplicate')) { mapping.tmfCode = 'TMF-409-002'; mapping.httpStatus = 409; }
        
        return mapping;
    }

    /**
     * @description Builds TMF response maintaining original payload structure
     * This method preserves the entire request payload and only adds minimum required fields
     * from the created Case: id, href, creationDate, lastUpdate
     * 
     * @param caseId Salesforce Case ID (15 or 18 chars)
     * @param caseNumber Case Number from IP response (e.g., "00001094")
     * @param originalPayload Original TMF request payload
     * @return TMF response with original payload + Case metadata
     */
    @TestVisible
    private Map<String, Object> buildTMFResponseFromIP(String caseId, 
                                                       String caseNumber, 
                                                       Map<String, Object> originalPayload) {
        
        // Start with original payload - this preserves all request fields
        Map<String, Object> response = new Map<String, Object>(originalPayload);
        
        try {
            // Query Case for creation and modification dates
            List<Case> cases = [
                SELECT CreatedDate, LastModifiedDate
                FROM Case
                WHERE Id = :caseId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!cases.isEmpty()) {
                Case c = cases[0];
                
                // Add/Override required fields from Case
                response.put('id', caseNumber);
                response.put('href', '/services/apexrest/tmforum/v5/troubleTicket/' + caseNumber);
                response.put('creationDate', c.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                response.put('lastUpdate', c.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                
            } else {
                // Fallback if Case query fails - use current timestamp
                response.put('id', caseNumber);
                response.put('href', '/services/apexrest/tmforum/v5/troubleTicket/' + caseNumber);
                
                String currentTimestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
                response.put('creationDate', currentTimestamp);
                response.put('lastUpdate', currentTimestamp);
            }
            
        } catch (Exception e) {
            System.debug('Error querying Case dates: ' + e.getMessage());
            
            // Fallback with minimal data
            response.put('id', caseNumber);
            response.put('href', '/services/apexrest/tmforum/v5/troubleTicket/' + caseNumber);
            
            String currentTimestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            response.put('creationDate', currentTimestamp);
            response.put('lastUpdate', currentTimestamp);
        }
        
        return response;
    }
    
    /**
     * @description Builds TMF621 compliant response by querying the created Case
     * @param caseId Salesforce Case ID
     * @param caseNumber Case Number (00001234)
     * @param originalPayload Original TMF request payload
     * @return TMF621 formatted response
     */
    /*private Map<String, Object> buildTMFResponseFromCase(String caseId, 
                                                         String caseNumber, 
                                                         Map<String, Object> originalPayload) {
        
        // Query the created Case with all necessary fields
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Type,
                   CreatedDate, LastModifiedDate, AccountId, Account.Name,
                   Origin, vlocity_cmt__Severity__c,
                   PVU_Level1__c, PVU_Level2__c, PVU_Level3__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        if (cases.isEmpty()) {
            // Fallback: build minimal response
            return buildMinimalTMFResponse(caseNumber, originalPayload);
        }
        
        Case c = cases[0];
        
        // Build complete TMF response
        Map<String, Object> response = new Map<String, Object>();
        
        // Required fields
        response.put('id', c.CaseNumber);
        response.put('href', '/services/apexrest/vlocity_cmt/tmforum/troubleticket/v1/troubleticket/' + c.CaseNumber);
        response.put('description', c.Description);
        response.put('ticketType', c.Type);
        response.put('status', mapSFStatusToTMF(c.Status));
        response.put('creationDate', c.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        response.put('lastUpdate', c.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        
        // Optional fields
        if (String.isNotBlank(c.Subject)) {
            response.put('name', c.Subject);
        }
        
        if (String.isNotBlank(c.Priority)) {
            response.put('priority', c.Priority);
        }
        
        if (String.isNotBlank(c.vlocity_cmt__Severity__c)) {
            response.put('severity', c.vlocity_cmt__Severity__c);
        }
        
        // Category, subcategory, customerVoice (custom fields)
        if (String.isNotBlank(c.PVU_Level1__c)) {
            response.put('category', c.PVU_Level1__c);
        }
        
        if (String.isNotBlank(c.PVU_Level2__c)) {
            response.put('subcategory', c.PVU_Level2__c);
        }
        
        if (String.isNotBlank(c.PVU_Level3__c)) {
            response.put('customerVoice', c.PVU_Level3__c);
        }
        
        // Channel
        if (String.isNotBlank(c.Origin)) {
            Map<String, Object> channel = new Map<String, Object>();
            channel.put('name', c.Origin);
            channel.put('@type', 'Channel');
            response.put('channel', channel);
        }
        
        // RelatedParty (Account)
        if (c.AccountId != null) {
            List<Object> relatedParties = new List<Object>();
            Map<String, Object> party = new Map<String, Object>();
            party.put('id', c.AccountId);
            party.put('name', c.Account.Name);
            party.put('@referredType', 'Account');
            relatedParties.add(party);
            response.put('relatedParty', relatedParties);
        }
        
        // RelatedEntity (if present in original payload)
        if (originalPayload.containsKey('relatedEntity')) {
            response.put('relatedEntity', originalPayload.get('relatedEntity'));
        }
        
        // TroubleTicketCharacteristic (query from Case fields or return original)
        List<Object> characteristics = buildCharacteristicsFromCase(c);
        if (!characteristics.isEmpty()) {
            response.put('troubleTicketCharacteristic', characteristics);
        }
        
        // Note (query CaseComments)
        List<Object> notes = queryNotesFromCase(caseId);
        if (!notes.isEmpty()) {
            response.put('note', notes);
        }
        
        // Attachment (query ContentDocumentLinks)
        List<Object> attachments = queryAttachmentsFromCase(caseId);
        if (!attachments.isEmpty()) {
            response.put('attachment', attachments);
        }
        
        return response;
    }*/
    
    /**
     * @description Builds minimal TMF response when Case query fails
     */
    @TestVisible
    private Map<String, Object> buildMinimalTMFResponse(String caseNumber, 
                                                        Map<String, Object> originalPayload) {
        Map<String, Object> response = new Map<String, Object>();
        
        response.put('id', caseNumber);
        response.put('href', '/services/apexrest/vlocity_cmt/tmforum/troubleticket/v1/troubleticket/' + caseNumber);
        
        // Copy from original payload
        if (originalPayload.containsKey('description')) {
            response.put('description', originalPayload.get('description'));
        }
        if (originalPayload.containsKey('ticketType')) {
            response.put('ticketType', originalPayload.get('ticketType'));
        }
        if (originalPayload.containsKey('status')) {
            response.put('status', originalPayload.get('status'));
        } else {
            response.put('status', 'New');
        }
        
        response.put('creationDate', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        response.put('lastUpdate', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        
        return response;
    }
    
    /**
     * @description Builds troubleTicketCharacteristic array from Case custom fields
     * Maps custom fields that were stored via the IP
     */
    /*private List<Object> buildCharacteristicsFromCase(Case c) {
        List<Object> characteristics = new List<Object>();
        
        // This would need to query the actual custom fields on Case
        // For now, returning empty as characteristics are typically stored
        // in separate records or custom metadata
        
        return characteristics;
    }*/
    
    /**
     * @description Queries and formats CaseComments as TMF notes
     */
    /*private List<Object> queryNotesFromCase(String caseId) {
        List<Object> notes = new List<Object>();
        
        try {
            List<CaseComment> comments = [
                SELECT Id, CommentBody, CreatedBy.Name, CreatedDate
                FROM CaseComment
                WHERE ParentId = :caseId
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            for (CaseComment comment : comments) {
                Map<String, Object> note = new Map<String, Object>();
                note.put('id', comment.Id);
                note.put('text', comment.CommentBody);
                note.put('author', comment.CreatedBy.Name);
                note.put('date', comment.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
                note.put('@type', 'Note');
                notes.add(note);
            }
        } catch (Exception e) {
            System.debug('Error querying notes: ' + e.getMessage());
        }
        
        return notes;
    }*/
    
    /**
     * @description Queries and formats ContentDocumentLinks as TMF attachments
     */
    /*private List<Object> queryAttachmentsFromCase(String caseId) {
        List<Object> attachments = new List<Object>();
        
        try {
            List<ContentDocumentLink> docLinks = [
                SELECT ContentDocument.Id, ContentDocument.Title, 
                       ContentDocument.FileType, ContentDocument.ContentSize,
                       ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseId
                LIMIT 10
            ];
            
            for (ContentDocumentLink link : docLinks) {
                Map<String, Object> attachment = new Map<String, Object>();
                attachment.put('id', link.ContentDocument.Id);
                attachment.put('name', link.ContentDocument.Title);
                attachment.put('mimeType', getMimeTypeFromFileType(link.ContentDocument.FileType));
                attachment.put('size', link.ContentDocument.ContentSize);
                attachment.put('url', '/services/data/v57.0/sobjects/ContentDocument/' + link.ContentDocument.Id);
                attachment.put('@type', 'Attachment');
                attachments.add(attachment);
            }
        } catch (Exception e) {
            System.debug('Error querying attachments: ' + e.getMessage());
        }
        
        return attachments;
    }*/
    
    /**
     * @description Maps Salesforce file type to MIME type
     */
    /*private String getMimeTypeFromFileType(String fileType) {
        Map<String, String> mimeTypes = new Map<String, String>{
            'PDF' => 'application/pdf',
            'PNG' => 'image/png',
            'JPG' => 'image/jpeg',
            'JPEG' => 'image/jpeg',
            'GIF' => 'image/gif',
            'DOC' => 'application/msword',
            'DOCX' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'XLS' => 'application/vnd.ms-excel',
            'XLSX' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'TXT' => 'text/plain',
            'CSV' => 'text/csv',
            'ZIP' => 'application/zip'
        };
        
        return mimeTypes.containsKey(fileType) ? 
            mimeTypes.get(fileType) : 'application/octet-stream';
    }*/
    
    /**
     * @description Retrieves Trouble Tickets based on filters
     * @param payload Query parameters (fields, offset, limit, filter)
     * @return List of trouble tickets
     */
    /*private Object retrieveTroubleTickets(Map<String, Object> payload) {
        
        // Extract query parameters
        String fields = (String)payload.get('fields');
        Integer offsetValue = payload.containsKey('offset') ? 
            Integer.valueOf(payload.get('offset')) : 0;
        Integer limitValue = payload.containsKey('limit') ? 
            Integer.valueOf(payload.get('limit')) : 100;
        String filter = (String)payload.get('filter');
        
        // Build SOQL query
        String query = 'SELECT Id, CaseNumber, Subject, Description, Status, Priority, ' +
                      'Type, CreatedDate, LastModifiedDate, AccountId, Account.Name, ' +
                      'Origin, vlocity_cmt__Severity__c, ' +
                      'PVU_Level1__c, PVU_Level2__c, PVU_Level3__c ' +
                      'FROM Case WHERE RecordType.DeveloperName = \'TroubleTicket\'';
        
        // Apply filters
        if (String.isNotBlank(filter)) {
            query += ' AND ' + parseFilter(filter);
        }
        
        query += ' ORDER BY CreatedDate DESC LIMIT :limitValue OFFSET :offsetValue';
        
        // Execute query
        List<Case> cases = Database.query(query);
        
        // Build response
        List<Map<String, Object>> tickets = new List<Map<String, Object>>();
        for (Case c : cases) {
            tickets.add(buildCaseResponseMap(c, fields));
        }
        
        return buildSuccessResponse(tickets, 'LIST');
    }*/
    
    /**
     * @description Builds a single Case response map
     * Used by both retrieve and list operations
     */
    /*private Map<String, Object> buildCaseResponseMap(Case c, String fields) {
        Map<String, Object> response = new Map<String, Object>();
        
        // Required fields
        response.put('id', c.CaseNumber);
        response.put('href', '/services/apexrest/vlocity_cmt/tmforum/troubleticket/v1/troubleticket/' + c.CaseNumber);
        response.put('description', c.Description);
        response.put('ticketType', c.Type);
        response.put('status', mapSFStatusToTMF(c.Status));
        response.put('creationDate', c.CreatedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        response.put('lastUpdate', c.LastModifiedDate.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        
        // Optional fields based on 'fields' parameter
        if (String.isBlank(fields) || fields.contains('priority')) {
            if (String.isNotBlank(c.Priority)) {
                response.put('priority', c.Priority);
            }
        }
        
        if (String.isBlank(fields) || fields.contains('severity')) {
            if (String.isNotBlank(c.vlocity_cmt__Severity__c)) {
                response.put('severity', c.vlocity_cmt__Severity__c);
            }
        }
        
        if (String.isBlank(fields) || fields.contains('name')) {
            if (String.isNotBlank(c.Subject)) {
                response.put('name', c.Subject);
            }
        }
        
        // Category fields
        if (String.isNotBlank(c.PVU_Level1__c)) {
            response.put('category', c.PVU_Level1__c);
        }
        
        if (String.isNotBlank(c.PVU_Level2__c)) {
            response.put('subcategory', c.PVU_Level2__c);
        }
        
        if (String.isNotBlank(c.PVU_Level3__c)) {
            response.put('customerVoice', c.PVU_Level3__c);
        }
        
        // Channel
        if (String.isNotBlank(c.Origin)) {
            Map<String, Object> channel = new Map<String, Object>();
            channel.put('name', c.Origin);
            channel.put('@type', 'Channel');
            response.put('channel', channel);
        }
        
        // Related party
        if (c.AccountId != null) {
            Map<String, Object> relatedParty = new Map<String, Object>();
            relatedParty.put('id', c.AccountId);
            relatedParty.put('name', c.Account.Name);
            relatedParty.put('@referredType', 'Account');
            response.put('relatedParty', new List<Object>{ relatedParty });
        }
        
        return response;
    }*/
    
    /**
     * @description Updates an existing Trouble Ticket
     * @param payload Update data including ticket ID
     * @return Updated ticket
     */
    /*private Object updateTroubleTicket(Map<String, Object> payload) {
        
        String ticketId = (String)payload.get('id');
        
        if (String.isBlank(ticketId)) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-400-009', 'Ticket ID is required for updates', 400)
            });
        }
        
        // Retrieve existing case by CaseNumber
        List<Case> cases = [
            SELECT Id, CaseNumber, Status, Description, Priority, Type
            FROM Case
            WHERE CaseNumber = :ticketId
            LIMIT 1
        ];
        
        if (cases.isEmpty()) {
            return buildErrorResponse(new List<TMFError>{
                buildError('TMF-404-002', 'Trouble Ticket not found', 404)
            });
        }
        
        Case existingCase = cases[0];
        
        // Apply updates
        if (payload.containsKey('description')) {
            existingCase.Description = (String)payload.get('description');
        }
        
        if (payload.containsKey('status')) {
            String tmfStatus = (String)payload.get('status');
            existingCase.Status = mapTMFStatusToSF(tmfStatus);
        }
        
        if (payload.containsKey('priority')) {
            existingCase.Priority = (String)payload.get('priority');
        }
        
        if (payload.containsKey('name')) {
            existingCase.Subject = (String)payload.get('name');
        }
        
        // Update Case
        Database.SaveResult updateResult = Database.update(existingCase, false);
        
        if (!updateResult.isSuccess()) {
            List<TMFError> errors = new List<TMFError>();
            for (Database.Error err : updateResult.getErrors()) {
                errors.add(buildError('TMF-400-010', err.getMessage(), 400));
            }
            return buildErrorResponse(errors);
        }
        
        // Process notes if present
        if (payload.containsKey('note')) {
            processNotes(existingCase.Id, (List<Object>)payload.get('note'));
        }
        
        // Build and return updated response
        return buildTMFResponseFromCase(existingCase.Id, existingCase.CaseNumber, payload);
    }*/
    
    /**
     * @description Processes notes (CaseComments)
     */
    /*private void processNotes(String caseId, List<Object> notes) {
        List<CaseComment> comments = new List<CaseComment>();
        
        for (Object noteObj : notes) {
            Map<String, Object> note = (Map<String, Object>)noteObj;
            CaseComment comment = new CaseComment();
            comment.ParentId = caseId;
            comment.CommentBody = (String)note.get('text');
            comment.IsPublished = false;
            comments.add(comment);
        }
        
        if (!comments.isEmpty()) {
            insert comments;
        }
    }*/
    
    /**
     * @description Processes attachments (ContentVersion)
     */
    /*private void processAttachments(String caseId, List<Object> attachments) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        for (Object attObj : attachments) {
            Map<String, Object> att = (Map<String, Object>)attObj;
            ContentVersion cv = new ContentVersion();
            cv.Title = (String)att.get('name');
            cv.PathOnClient = (String)att.get('name');
            cv.VersionData = EncodingUtil.base64Decode((String)att.get('content'));
            cv.FirstPublishLocationId = caseId;
            contentVersions.add(cv);
        }
        
        if (!contentVersions.isEmpty()) {
            insert contentVersions;
        }
    }*/

    /**
     * @description Parses filter string to SOQL WHERE clause
     * Example: "status=Working,priority=High"
     */
    /*private String parseFilter(String filter) {
        List<String> conditions = filter.split(',');
        List<String> whereClauses = new List<String>();
        
        for (String condition : conditions) {
            List<String> parts = condition.split('=');
            if (parts.size() == 2) {
                String field = parts[0].trim();
                String value = parts[1].trim();
                
                // Map TMF fields to SF fields
                if (field == 'status') {
                    // Map TMF status back to SF status for filtering
                    String sfStatus = mapTMFStatusToSF(value);
                    whereClauses.add('Status = \'' + sfStatus + '\'');
                } else if (field == 'priority') {
                    whereClauses.add('Priority = \'' + value + '\'');
                } else if (field == 'ticketType') {
                    whereClauses.add('Type = \'' + value + '\'');
                }
            }
        }
        
        return String.join(whereClauses, ' AND ');
    }*/

    /**
     * @description Maps TMF status to Salesforce status (for filtering/updates)
     */
    /*private String mapTMFStatusToSF(String tmfStatus) {
        Map<String, String> statusMap = new Map<String, String>{
            'En curso' => 'Working',
            'Cerrado' => 'Closed',
            'Pendiente' => 'New',
            'On Hold' => 'On Hold',
            'Escalated' => 'Escalated'
        };
        
        return statusMap.containsKey(tmfStatus) ? statusMap.get(tmfStatus) : tmfStatus;
    }*/

    /**
     * @description Maps Salesforce status to TMF status
     */
    /*private String mapSFStatusToTMF(String sfStatus) {
        Map<String, String> statusMap = new Map<String, String>{
            'New' => 'Pendiente',
            'Working' => 'En curso',
            'Escalated' => 'Escalated',
            'Closed' => 'Cerrado',
            'On Hold' => 'On Hold',
            'Pending' => 'Pendiente'
        };
        
        return statusMap.containsKey(sfStatus) ? statusMap.get(sfStatus) : sfStatus;
    }*/
    
    /**
     * @description Builds error response
     */
    @TestVisible
    private Map<String, Object> buildErrorResponse(List<TMFError> errors) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('status', 'error');
        
        // Convert TMFError objects to Maps for serialization
        List<Map<String, Object>> errorMaps = new List<Map<String, Object>>();
        for (TMFError error : errors) {
            errorMaps.add(error.toMap());
        }
        
        response.put('errors', errorMaps);
        response.put('timestamp', System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'));
        return response;
    }  

    /**
     * @description Inner class to wrap IP response parsing
     */
    @TestVisible
    private class IPResponse {
        public Boolean success { get; set; }
        public String caseId { get; set; }
        public String caseNumber { get; set; }
        public String errorMessage { get; set; }
        public String errorCode { get; set; }
        public Integer httpStatus { get; set; }
        
        public IPResponse() {
            this.success = false;
        }
    }

    /**
     * @description Inner class to wrap IP error parsing
     */
    @TestVisible
    private class IPErrorMapping {
        public String tmfCode { get; set; }
        public Integer httpStatus { get; set; }
        public IPErrorMapping() { this.tmfCode = 'TMF-500-004'; this.httpStatus = 500; }
    }
}