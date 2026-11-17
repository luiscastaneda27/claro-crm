/*******************************************************************************
* Autor: Federico Mandri
* Fecha: 2023-09-04
* Equipo: Pos-Ventas
* HU: 661134
* Descripcion: Clase de test para PVU_PQRUtils
* Modificaciones: 2023-09-06 por HU 658839
***********************************************************************************/

@isTest
public class PVU_PQRUtilsTest {
        
    @isTest
    static void pqrListExceptionTest(){
        Map<String, Object> caseMap = new Map<String, Object>{
             'assessorLocationWhoCreatedPQR' => null,
             'assessorLocationWhoRespondedPQR' => null,
             'assessorWhoCreatedPQR' => null,
             'assessorWhoRespondedPQR' => null,
             'asunto' => 'tretd',
             'casoPadre' => null,
             'centralRiskClaimsSubtype' => null,
             'codCategoria' => 17,
             'codRazonDeCierre' => null,
             'codSubcategoria' => 877,
             'codVozDelCliente' => 1302,
             'cun' => '4488220000016293',
             'descripcion' => 'test',
             'descripcionCierre' => null,
             'estado' => 'Asignado',
             'favorability' => null,
             'fechaRadicacion' => '2023-09-01',
             'fechaRespuesta' => null,
             'fechaSap' => '2023-09-22',
             'filingNumber' => null,
             'forCategory' => 'Facturación y pagos',
             'forSubcategory' => 'Pagos',
             'forVoiceOfCustomer' => 'Reverso de pago',
             'idTypology' => null,
             'informCollectionExclusion' => null,
             'linkRespuesta' => null,
             'markingCentralRiskType' => null,
             'nr' => '00013299',
             'OriginCunOrNr' => null,
             'relacionCaso' => null,
             'resolutionNumber' => null,
             'sicCategory' => null,
             'sicSubcategory' => null,
             'tipoCaso' => 'RECURSO'
    	};
    	List<Object> casesList = new List<Object>();
        casesList.add(caseMap);
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('cases', casesList);
        String methodName = 'transformPQRList';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrTx = new PVU_PQRUtils();
        	exitoso = pqrTx.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(False, exitoso, 'El metodo falló en algún punto');
        System.AssertEquals(True, !String.isBlank((String)output.get('error')), 'El mensaje de error está vacío');
	}
    
    @isTest
    static void pqrListTest(){
        Map<String, Object> caseMap = new Map<String, Object>{
             'assessorLocationWhoCreatedPQR' => null,
             'assessorLocationWhoRespondedPQR' => null,
             'assessorWhoCreatedPQR' => null,
             'assessorWhoRespondedPQR' => null,
             'asunto' => 'tretd',
             'casoPadre' => null,
             'centralRiskClaimsSubtype' => null,
             'codCategoria' => 17,
             'codRazonDeCierre' => null,
             'codSubcategoria' => 877,
             'codVozDelCliente' => 1302,
             'cun' => '4488220000016293',
             'descripcion' => 'test',
             'descripcionCierre' => null,
             'estado' => 'Asignado',
             'favorability' => null,
             'fechaRadicacion' => '2023-09-01',
             'fechaRespuesta' => null,
             'fechaSap' => '2023-09-22',
             'filingNumber' => null,
             'forCategory' => 'Facturación y pagos',
             'forSubcategory' => 'Pagos',
             'forVoiceOfCustomer' => 'Reverso de pago',
             'idTypology' => null,
             'informCollectionExclusion' => null,
             'linkRespuesta' => null,
             'markingCentralRiskType' => null,
             'nr' => '00013299',
             'OriginCunOrNr' => null,
             'relacionCaso' => null,
             'resolutionNumber' => null,
             'sicCategory' => null,
             'sicSubcategory' => null,
             'tipoCaso' => 'RECURSO'
    	};
    	List<Object> casesList = new List<Object>();
        Map<String, List<Object>> cases = new Map<String, List<Object>>();
        casesList.add(caseMap);
        cases.put('cases', casesList);
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('cases', cases);
        String methodName = 'transformPQRList';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrTx = new PVU_PQRUtils();
        	exitoso = pqrTx.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(True, exitoso, 'El metodo falló en algún punto');
        System.AssertEquals(True, String.isBlank((String)output.get('error')), 'Hay un error capturado');
	}
    
    @isTest
    static void populatePickListTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populatePicklist';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(True, ((List<Map<String, Object>>)output.get('options')).size() > 0);
    }
    
    @isTest
    static void populateChildPickListTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateChildPickList';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Map<String, Object> dependentPickListMap = (Map<String, Object>)output.get('dependency');
        List<List<Map<String, String>>> dependentPickListList = (List<List<Map<String, String>>>)dependentPickListMap.values();
        System.AssertEquals(True, dependentPickListList.size() > 0, 'No hay valores dependientes');
	}
    
    @isTest
    static void populateGrandChildPickListTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateGrandChildPickList';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        Map<String, Object> dependentPickListMap = (Map<String, Object>)output.get('dependency');
        List<List<Map<String, String>>> dependentPickListList = (List<List<Map<String, String>>>)dependentPickListMap.values();
        System.AssertEquals(True, dependentPickListList.size() > 0, 'No hay valores dependientes');
    }
    
    //20240403 - FM - HU 675471 - INICIO
    @isTest
    static void populateSubcategoryPicklistTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateSubCategoryPickList';
        Boolean exitoso = False;
        input.put('categoria', 'Facturación y pagos');
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        List<Map<String, Object>> subcategorias = (List<Map<String, Object>>)output.get('subcategorias');
        System.Assert(subcategorias.size() > 0, 'No hay subcategorias para ' + input.get('categoria'));
    }
    
    @isTest
    static void populateVozClienteQuejaTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateVocesClientePickList';
        Boolean exitoso = False;
        input.put('tipoPQR', 'Queja');
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        List<Map<String, Object>> vocesCliente = (List<Map<String, Object>>)output.get('vocesCliente');
        System.Assert(vocesCliente.size() > 0, 'No hay voces de cliente para ' + input.get('tipoPQR'));
    }
    
    @isTest
    static void populateVozClientePeticionTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateVocesClientePickList';
        Boolean exitoso = False;
        input.put('tipoPQR', 'Petición');
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        List<Map<String, Object>> vocesCliente = (List<Map<String, Object>>)output.get('vocesCliente');
        System.Assert(vocesCliente.size() > 0, 'No hay voces de cliente para ' + input.get('tipoPQR'));
    }
    
    @isTest
    static void populateVozReqLegalTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'populateVocesClientePickList';
        Boolean exitoso = False;
        input.put('tipoPQR', 'RequerimientoLegal');
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        List<Map<String, Object>> vocesCliente = (List<Map<String, Object>>)output.get('vocesCliente');
        System.Assert(vocesCliente.size() > 0, 'No hay voces de cliente para ' + input.get('tipoPQR'));
    }
    
    @isTest
    static void getAllTipificationTest(){
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'getAllTipification';
        Boolean exitoso = False;
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        List<Map<String, Object>> tipificaciones = (List<Map<String, Object>>)output.get('tipificaciones');
        System.Assert(tipificaciones.size() > 0, 'No hay tipificaciones configuradas');
    }
    //20240403 - FM - HU 675471 - FIN

    @isTest
    static void calculateTiempoDesactivacionTest(){
        Account acc = new Account();
        acc.Name = 'Test AccLiberacion';
        acc.FVU_DocumentType__c = 'CC';
        acc.FVU_DocumentNumber__c = '1234';
        insert as user acc;
    
        Asset ast = new Asset();
        ast.Name = 'Test Asset';
        ast.Status = 'Deactivated';
        ast.OM_SubStatus__c = 'Portout';
        ast.AccountId = acc.Id;
        insert as user ast;
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'calculateTiempoDesactivacion';
        Boolean exitoso = False;
        input.put('assetId', ast.Id);
        Test.startTest();
        	PVU_PQRUtils pqrU = new PVU_PQRUtils();
        	exitoso = pqrU.invokeMethod(methodName, input, output, options);
        Test.stopTest();
        System.AssertEquals(true, exitoso, 'calculateTiempoDesactivacionTest Exitoso');
    }
}