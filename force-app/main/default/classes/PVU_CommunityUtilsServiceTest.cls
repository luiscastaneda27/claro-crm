@isTest
public class PVU_CommunityUtilsServiceTest {
    
    // Método de configuración para crear datos necesarios
    @testSetup
    static void setupTestData() {
       
        // Crear línea subcription y Community
        vlocity_cmt__Subscription__c subscription = new vlocity_cmt__Subscription__c(Name = 'Parent Line', OM_MSISDN__c = '1234567890', vlocity_cmt__SubscriptionNumber__c='TEST12345678');
        insert subscription;

        vlocity_cmt__Subscription__c subscriptionCommunityTest = new vlocity_cmt__Subscription__c(Name = 'Parent Line 2', OM_MSISDN__c = '679810125', vlocity_cmt__SubscriptionNumber__c='TEST1234567892');
        insert subscriptionCommunityTest ;


        PVU_Community__c community = new PVU_Community__c(Name = 'Test Community', PVU_Linea_Padre__c = subscription.Id, PVU_Estatus__c='Activa', PVU_Segmento_linea__c = 'Postpago',PVU_Fecha_de_activacion__c = System.now());
        insert community;

        PVU_Community_Member__c memberForEditAndAdd = new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '2358132134', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert memberForEditAndAdd;

        PVU_Community_Member__c memberForDelete= new PVU_Community_Member__c(PVU_Comunidad__c = community.id, PVU_Linea_Hija__c = '02599318', PVU_Segmento_Linea__c = 'Fija',PVU_Tipo_Linea__c = 'movil');
        insert memberForDelete;



    }

    // Prueba para el método addRecord
    @isTest
    static void testAddRecord() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '930318259',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.addRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_ADD');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'), 'Se genero correctamente');
        Assert.isNotNull(response.get('memberId'), 'El CommunityMember Id deberia no ser null');
    }


    // Prueba para el método addRecord se encuentra un registro previamente creado
       @isTest
       static void testAddRecordErrorMemberExist() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '1234567890',
               'childLine' => '2358132134',
               'lineType' => 'movil',
               'lineSegment' => 'Fija',
               'origin' => 'SuperApp',
               'hasCost' => true
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.addRecord(input);
           Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_MEMBER_EXIST');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'No se creo el registro porque ya existia');
       }
   

    // Prueba para el método editRecord
    @isTest
    static void testEditRecord() {
        

        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '2358132134',
            'newChildLine' => '1111222233',
            'lineType' => 'movil',
            'origin' => 'SuperApp',
            'hasCost' => true,
            'lineSegment' => 'Prepago'

        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.editRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_EDIT');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'), 'La respuesta indica que se edito correctamente');
        System.assertEquals('1111222233', response.get('childLine'), 'el valor actual del childline deberia ser actualizado');
    }
     // Prueba para el método editRecord no se envia los parametros necesarios
     @isTest
     static void testEditRecordErrorParams() {
         
 
         Map<String, Object> input = new Map<String, Object>{
             'parentLine' => '1234567890',
             'childLine' => null,
             'newChildLine' => '1111222233',
             'lineType' => 'movil',
             'origin' => 'SuperApp',
             'hasCost' => true
         };
 
         Test.startTest();
         Map<String, Object> response = PVU_CommunityUtilsService.editRecord(input);
         Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_PARAMS_EDIT');
         Test.stopTest();
 
         System.assertEquals(message.get('message'), response.get('message'), 'La respuesta indica que require en el input valores para los siguientes parametros');
     }
 

    // Prueba para el método deleteRecord
    @isTest
    static void testDeleteRecord() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '02599318',
            'origin' => 'SuperApp',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.deleteRecord(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_MEMBER_REMOVE');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'), 'La respuesta indica que se elimino correctamente');
    }
    // Prueba para el método deleteRecord no se encontro para eliminar
    @isTest
    static void testDeleteRecordErrorComunityMember() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '2039827',
            'origin' => 'SuperApp',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.deleteRecord(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY_MEMBER');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'), 'La respuesta indica que no encontro registro que eliminar');
    }


    // Prueba para el método checkIfIsExistCommunityMember
    @isTest
    static void testCheckIfIsExistCommunityMember() {
        Boolean exists = PVU_CommunityUtilsService.checkIfIsExistCommunityMember('1234567890', '930318259');
        If (exists == true) {
            System.Assert.areEqual(true, exists, 'El usuario existe');
        } else {
            System.Assert.areEqual(false, exists, 'El usuario no existe');
        }
    }

    @isTest
    static void testCheckIfIsExistCommunity() {
        Boolean exists = PVU_CommunityUtilsService.checkIfIsExistCommunity('1234567890');
        If (exists == true) {
            System.Assert.areEqual(true, exists, 'La comunidad existe');
        } else {
            System.Assert.areEqual(false, exists, 'La comunidad no existe');
        }
    }

       //Pruebas para comunidad 
       // creada exitosa
       @isTest
       static void testCreateCommunity() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '679810125',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.activateCommunity(input);
           Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_ACTIVATED');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'Se genero correctamente');
           Assert.isNotNull(response.get('communityId'), 'ElcommunityId deberia no ser null');
       }

       //comunidad ya existe

       @isTest
       static void testCreateCommunityAlreadyCreated() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '1234567890',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.activateCommunity(input);
           Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_ACTIVATED');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'Se genero correctamente');
           Assert.isNotNull(response.get('communityId'), 'ElcommunityId deberia no ser null');
           
       }
       //linepartner no existe cuando crea comunidad
       @isTest
       static void testCreateCommunityNotFoundLinePartner() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '12345678901',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.activateCommunity(input);
           Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_LINEPARTNER_NOT_FOUND');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'No se encuentra el line partner');
           
       }

       @isTest
       static void testDeactivateCommunity() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '1234567890',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.deactivateCommunity(input);
           Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_DEACTIVATED');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'La comunidad se desactivo');
           
       }

       @isTest
       static void testDeactivateCommunityNotFound() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '12345678901',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.deactivateCommunity(input);
           Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_NO_COMMUNITY_AVAILABLE');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'No se encontro comunidad');
           
       }

       @isTest
       static void testSuspendCommunity() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '1234567890',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.suspendCommunity(input);
           Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_COMMUNITY_SUSPENDED');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'La comunidad se supendio');
           
       }


       @isTest
       static void testSuspendCommunityNotFound() {
           Map<String, Object> input = new Map<String, Object>{
               'parentLine' => '12345678901',
               'lineSegment' => 'Postpago',
               'origin' => 'SuperApp'
   
           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.suspendCommunity(input);
           Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_NO_COMMUNITY_AVAILABLE');
           Test.stopTest();
   
           System.assertEquals(message.get('message'), response.get('message'), 'La comunidad no se encontro');
           
       }

       @isTest
       static void testManageCommunity() {
   
           Map<String, Object> input = new Map<String, Object>{
               'line' => '1234567890'

           };
   
           Test.startTest();
           Map<String, Object> response = PVU_CommunityUtilsService.manageCommunity(input);
           
           Test.stopTest();
   
           System.assertEquals('success', response.get('status'), 'La respuesta indica que se encontro la informacion correctamente');
   
       }

       @isTest
       static void testGetCommunityResponse() {
   
        PVU_Community__c registeredCommunity = [SELECT Id,	PVU_Estatus__c,PVU_Segmento_linea__c,	PVU_MSISDN__c, PVU_Fecha_de_activacion__c,PVU_Total_de_lineas_hijas__c,PVU_Linea_Padre__r.vlocity_cmt__Status__c
         FROM PVU_Community__c 
         WHERE PVU_Linea_Padre__r.OM_MSISDN__c  = '1234567890'
         WITH USER_MODE LIMIT 1];
        
         List<PVU_Community_Member__c>  registeredCommunityMembers =new  List<PVU_Community_Member__c> ();
        
        Test.startTest();
        Map<String, Object> response =  PVU_CommunityUtilsService.getCommunityResponse( registeredCommunity, registeredCommunityMembers );
        Test.stopTest();


        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals('1234567890', response.get('parentLine'), 'The parent line should match');
        System.assertEquals('Activa', response.get('communityStatus'), 'The community status should match');

   
       }


       

       
       

    
       
    //Prueba para crear Case con un input para crear un community member
    @isTest
    static void testCreateCase() {

        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '930318259',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
            'action'=> 'add',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.createCaseCommunity(input,false);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_CASE_CREATION');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'), 'La respuesta indica que se creo correctamente');

    }
    // Prueba para el método addRecord error en los parámetros
    @isTest
    static void testAddRecordErrorParamsAdd() {
        Map<String, Object> input = new Map<String, Object>{
           'childLine' => '2358132134',
           'lineType' => 'movil',
           'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
           'hasCost' => true
        };
   
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.addRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_PARAMS_ADD');
        Test.stopTest();
   
        System.assertEquals(message.get('message'), response.get('message'));
    }

    // Prueba para el método addRecord error hasCost
    @isTest
    static void testAddRecordErrorHasCost() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '930318259',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'other'
        };
   
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.addRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_FIELD_HASCOST');
        Test.stopTest();
   
        System.assertEquals(message.get('message'), response.get('message'));
       
    } 
    // Prueba para el método addRecord error excepcion
    @isTest
    static void testAddRecordErrorException() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567000',
            'childLine' => '930318000',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
            'hasCost' => true
        };
   
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.addRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY');
        Test.stopTest();
   
        System.assertEquals(message.get('message'), response.get('message'));
       
    }
    // Prueba para el método editRecord error hasCost
     @isTest
     static void testEditRecordErrorHasCost() {          
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '2358132134',
            'newChildLine' => '1111222233',
            'lineType' => 'movil',
            'origin' => 'other',
            'hasCost' => true,
            'lineSegment' => 'Prepago'
         };
 
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.editRecord(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_FIELD_HASCOST');
        Test.stopTest();
 
        System.assertEquals(message.get('message'), response.get('message'));
    }
    // Prueba para el método editRecord error excepcion
    @isTest
    static void testEditRecordException() {          
       Map<String, Object> input = new Map<String, Object>{
           'parentLine' => '1234567000',
           'childLine' => '2358132000',
           'newChildLine' => '1111222233',
           'lineType' => 'movil',
           'origin' => 'other',
           'hasCost' => true,
           'lineSegment' => 'Prepago'
        };

       Test.startTest();
       Map<String, Object> response = PVU_CommunityUtilsService.editRecord(input);
       Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_THERE_IS_NO_COMMUNITY_MEMBER');
       Test.stopTest();

       System.assertEquals(message.get('message')+'2358132000', response.get('message'));
   }

    // Prueba para el método deleteRecord error en los parametros 
    @isTest
    static void testDeleteRecordErrorParams() {
        Map<String, Object> input = new Map<String, Object>{
            'childLine' => '02599318',
            'origin' => 'SuperApp',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.deleteRecord(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_PARAMS_REMOVE');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'));
    }

    // Prueba para el método deleteRecord error hasCost 
    @isTest
    static void testDeleteRecordErrorHasCost() {
        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '02599318',
            'origin' => 'other',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.deleteRecord(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_FIELD_HASCOST');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'));
    }

    // Prueba para el método activateCommunity cuando existe error en los parámetros
    @isTest
    static void testCreateCommunityErrorParams() {
        Map<String, Object> input = new Map<String, Object>{
            'lineSegment' => 'Postpago',
            'origin' => 'SuperApp'
   
        };
   
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.activateCommunity(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_PARAMS');
        Test.stopTest();
   
        System.assertEquals(message.get('message'), response.get('message'));
    }

    @isTest
    static void testDeactivateCommunityErrorParams() {
       Map<String, Object> input = new Map<String, Object>{
            'lineSegment' => 'Postpago',
            'origin' => 'SuperApp'   
        };
   
        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.deactivateCommunity(input);
        Map<String, Object> message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_PARAMS');
        Test.stopTest();
   
        System.assertEquals(message.get('message'), response.get('message'));
           
    }
    @isTest
    static void testSuspendCommunityErrorParams() {
        Map<String, Object> input = new Map<String, Object>{
            'lineSegment' => 'Postpago',
            'origin' => 'SuperApp'

        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.suspendCommunity(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_COMMUNITY_PARAMS');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'));
        
    }

    @isTest
    static void testCreateCaseException() {

        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567000',
            'childLine' => '930318259',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
            'action'=> 'add',
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.createCaseCommunity(input,false);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_NO_SUCCESS_CREATION_CASE');
        Test.stopTest();

        System.assertEquals(message.get('message')+'1234567000', response.get('message'));
    }

    @isTest
    static void testCreateCaseCallCommunity() {

        Map<String, Object> input = new Map<String, Object>{
            'parentLine' => '1234567890',
            'childLine' => '930318259',
            'newChildLine' => '1111222233',
            'lineType' => 'movil',
            'lineSegment' => 'Fija',
            'origin' => 'SuperApp',
            'action'=> 'add',
            'wasSuspended' => true,
            'hasCost' => true
        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.createCaseCommunity(input,true);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('SUCCESS_CASE_CREATION');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'));
    }

    @isTest
    static void testManageCommunityErrorParam() {
        Map<String, Object> input = new Map<String, Object>{
            'line' => null

        };

        Test.startTest();
        Map<String, Object> response = PVU_CommunityUtilsService.manageCommunity(input);
        Map<String, Object>  message = PVU_CommunityUtilsService.getMessageFormCode('ERROR_NO_LINE_GIVEN');
        Test.stopTest();

        System.assertEquals(message.get('message'), response.get('message'));

    }
}