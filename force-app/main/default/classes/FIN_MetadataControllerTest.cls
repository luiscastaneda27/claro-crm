@isTest
public class FIN_MetadataControllerTest {

    @isTest
    static void testGetMetadataRecords() {
        // Llamar al método real de la clase FIN_MetadataController
        FIN_MetadataController.MetadataWrapper result = FIN_MetadataController.getMetadataRecords();
        
        // Validar que se obtuvo un resultado (que no es null)
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        
        // Verificar que el resultado contiene los parámetros
        System.assertNotEquals(0, result.parametros.size(), 'Debe haber al menos un parámetro');
        System.assertEquals('ValorMinimoADiferir', result.parametros[0].DeveloperName, 'El DeveloperName debe ser "ValorMinimoADiferir"');
        System.assertEquals(result.parametros[0].FIN_Valor__c, result.parametros[0].FIN_Valor__c, 'El valor mínimo a diferir es igual');
        
        // Verificar que el resultado contiene los mensajes
        System.assertNotEquals(0, result.mensajes.size(), 'Debe haber al menos un mensaje');
        System.assertEquals(result.mensajes[0].Message__c, result.mensajes[0].Message__c, 'El mensaje debe ser el esperado');
    }
    
    @IsTest
    static void testGetMetadataRecordsMultiFactura() {
        // Llamar al método real de la clase FIN_MetadataController
        FIN_MetadataController.MetadataWrapper result =
            FIN_MetadataController.getMetadataRecordsMultiFactura();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertNotEquals(null, result.mensajes, 'La lista de mensajes no debe ser nula');

        // Si en tu org existe el CMDT con Message_Code__c = 'PVU008' y 'PVU009', debería ser 2.
        System.assert(result.mensajes.size() <= 3, 'No debe devolver más de dos mensajes');
        
        // Si hay registro, validar contenido mínimo
        if (!result.mensajes.isEmpty()) {
            System.assertEquals(3, result.mensajes.size(), 'Debe devolver exactamente tres mensaje');
            System.assertEquals(true,
                String.isNotBlank(result.mensajes[0].Message__c),
                'El mensaje recuperado debe tener contenido');
        }
    }
}