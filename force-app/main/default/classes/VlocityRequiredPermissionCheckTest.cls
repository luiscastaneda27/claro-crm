@isTest
public class VlocityRequiredPermissionCheckTest {
    // Datos de prueba y configuración
    @testSetup
    static void setupTestData() {
        // No se necesita configuración de datos específica para este caso, ya que FeatureManagement es una función nativa.
        // Si se requiere simular permisos personalizados, podrían incluirse aquí.
    }

    @isTest
    static void testCallMethodCheckPermissionFailure() {
        // Instanciar la clase a probar
        VlocityRequiredPermissionCheck permissionChecker = new VlocityRequiredPermissionCheck();

        // Simular argumentos para el método call()
        Map<String, Object> args = new Map<String, Object>{
            'requiredPermission' => 'NonExistentPermission'
        };

        // Mock de FeatureManagement para fallo
        Test.startTest();
        Boolean result = permissionChecker.call('checkPermission', args);
        Test.stopTest();

        // Validar el resultado
        System.assert(!result, 'El permiso no debería haber sido encontrado.');
    }

    @isTest
    static void testCallMethodInvalidAction() {
        // Instanciar la clase a probar
        VlocityRequiredPermissionCheck permissionChecker = new VlocityRequiredPermissionCheck();

        // Simular argumentos con una acción no válida
        Map<String, Object> args = new Map<String, Object>{
            'requiredPermission' => 'SamplePermission'
        };

        Test.startTest();
        Boolean result = permissionChecker.call('invalidAction', args);
        Test.stopTest();

        // Validar el resultado
        System.assert(!result, 'La acción no válida debería devolver false.');
    }

    
}