@isTest
public class PVU_RelacionadosEquiposServiciosTest {
    @isTest
    static void testInvokeMethod_obtenerDetalle() {
        // Crear un Account de prueba
        Account acc = new Account(
            Name = 'Cliente Prueba',
            FVU_Email__c = 'cliente@correo.com',
            FVU_DocumentNumber__c = '12345678'
        );
        insert acc;

        // Crear un Case relacionado al account
        Case caso = new Case(
            AccountId = acc.Id,
            PVU_MotivoDevolucion__c = 'Producto defectuoso',
            PVU_CUN__c = 'CUN123',
            PVU_IdODS__c = 'ODS123'
        );
        insert caso;

        // Crear una orden relacionada
        Order orden = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            FIN_NumeroDeFacturaDeVenta__c = 'FAC123456'
        );
        insert orden;

        // Crear el registro principal de la clase
        PVU_Relacion_de_servicios_y_equipos__c relacion = new PVU_Relacion_de_servicios_y_equipos__c(
            PVU_Serial_o_Imei__c = 'IMEI12345',
            PVU_Order__c = orden.Id,
            PVU_caso_relacionado__c = caso.Id,
            PVU_Fecha_Factura__c = Date.today()
        );
        insert relacion;

        // Crear input y output maps
        Map<String, Object> input = new Map<String, Object>{
            'RelServEquipoId' => relacion.Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Instancia de la clase a probar
        PVU_RelacionadosEquiposServicios servicio = new PVU_RelacionadosEquiposServicios();
        
        // Ejecutar el método
        Boolean result = servicio.invokeMethod('obtenerDetalle', input, outMap, options);
        
        // Validar que el método devuelva true
        System.assertEquals(true, result);

        // Validar que outMap contiene los valores esperados
        System.assert(outMap.containsKey('relacionadoServicio'), 'El mapa de salida debe contener la clave relacionadoServicio');
        System.assert(outMap.containsKey('nota'), 'El mapa de salida debe contener la clave nota');
        System.assert(((String)outMap.get('nota')).contains('Número de Factura'), 'La nota debe contener la factura');

    }
}