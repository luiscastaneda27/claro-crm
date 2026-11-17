@isTest
public class FVU_MERSystemInterfaceTest {
    @isTest
    public static void generateHeaderRequestTest() {
        String method = 'GenerateHeaderRequest';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        inputMap.put('traceabilityId', 'traceabilityId6');
        inputMap.put('ipApplication', 'ipApplication5');
        DateTime.now().formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS');
        inputMap.put('password', 'password4');
        inputMap.put('user', 'user3');
        inputMap.put('system', 'SalesForce');
        inputMap.put('transactionId', 'fac60960-6a28-da28-3c1c-c6a384aad901');

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConstruirDireccionHhppCKTest() {
        String method = 'RequestConstruirDireccionHhpp';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        inputMap.put('dane','73001000');
        inputMap.put('street','carrera 102 83 60'); 
        inputMap.put('typeAddress','CK');
        inputMap.put('tipoAdicion','N');

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConstruirDireccionHhppBMTest() {
        String method = 'RequestConstruirDireccionHhpp';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
                inputMap.put('dane','73001000');
                inputMap.put('valorNivel','Manzana'); 
                inputMap.put('tipoNivel','Barrio');  
                inputMap.put('typeAddress','BM');
                inputMap.put('tipoAdicion','P');

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConstruirDireccionHhppCKMultiorigenTest() {
        String method = 'RequestConstruirDireccionHhpp';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
            inputMap.put('dane','73001000');
            inputMap.put('street','carrera 102 83 60'); 
            inputMap.put('typeAddress','CK');
            inputMap.put('tipoAdicion','N');
            inputMap.put('multiorigen',true);

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConstruirDireccionHhppComplementTest() {
        String method = 'RequestConstruirDireccionHhpp';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

                inputMap.put('dane','73001000');
                inputMap.put('valorNivel','Manzana'); 
                inputMap.put('tipoNivel','Barrio');  
                inputMap.put('typeAddress','BM');
                inputMap.put('tipoAdicion','C');
                Map<String,Object> drDireccion = new Map<String, Object>();
                    drDireccion.put('usuarioEdicion','user');
                    drDireccion.put('usuarioCreacion','Test');
                    drDireccion.put('tipoViaPrincipal','Barrio');
                    drDireccion.put('tipoViaGeneradora','tipoViaGeneradora');
                    drDireccion.put('placadrDireccion','placadrDireccion');
                    drDireccion.put('perfilEdicion', 'perfilEdicion');
                    drDireccion.put('perfilCreacion', 'perfilCreacion');
                    drDireccion.put('numViaPrincipal', 'numViaPrincipal');
                    drDireccion.put('numViaGeneradora', 'numViaGeneradora');
                    drDireccion.put('nlPostViaP', 'nlPostViaP');
                    drDireccion.put('nlPostViaG', 'nlPostViaG');
                    drDireccion.put('mzValorNivel6', 'mzValorNivel6');
                    drDireccion.put('mzValorNivel5', 'mzValorNivel5');
                    drDireccion.put('mzValorNivel4', 'mzValorNivel4');
                    drDireccion.put('mzValorNivel3', 'mzValorNivel3');
                    drDireccion.put('mzValorNivel2', 'mzValorNivel2');
                    drDireccion.put('mzValorNivel1', 'mzValorNivel1');
                    drDireccion.put('mzTipoNivel6', 'mzTipoNivel6');
                    drDireccion.put('mzTipoNivel5', 'mzTipoNivel5');
                    drDireccion.put('mzTipoNivel4', 'mzTipoNivel4');
                    drDireccion.put('mzTipoNivel3', 'mzTipoNivel3');
                    drDireccion.put('mzTipoNivel2', 'mzTipoNivel2');
                    drDireccion.put('mzTipoNivel1', 'mzTipoNivel1');
                    drDireccion.put('ltViaPrincipal', 'ltViaPrincipal');
                    drDireccion.put('ltViaGeneradora', 'ltViaGeneradora');
                    drDireccion.put('letra3G', 'letra3G');
                    drDireccion.put('itValorPlaca', 'itValorPlaca');
                    drDireccion.put('itTipoPlaca', 'itTipoPlaca');
                    drDireccion.put('idTipodrDireccion', 'idTipodrDireccion');
                    drDireccion.put('idSolicitud', 'idSolicitud');
                    drDireccion.put('idDirCatastro', 'idDirCatastro');
                    drDireccion.put('id', 'id');
                    drDireccion.put('fechaEdicion', 'fechaEdicion');
                    drDireccion.put('fechaCreacion', 'fechaCreacion');
                    drDireccion.put('estrato', 'estrato');
                    drDireccion.put('estadoRegistro', 'estadoRegistro');
                    drDireccion.put('estadoDirGeo', 'estadoDirGeo');
                    drDireccion.put('dirPrincAlt', 'dirPrincAlt');
                    drDireccion.put('dirEstado', 'dirEstado');
                    drDireccion.put('cuadViaPrincipal', 'cuadViaPrincipal');
                    drDireccion.put('cuadViaGeneradora', 'cuadViaGeneradora');
                    drDireccion.put('cpValorNivel6', 'cpValorNivel6');
                    drDireccion.put('cpValorNivel5', 'cpValorNivel5');
                    drDireccion.put('cpValorNivel4', 'cpValorNivel4');
                    drDireccion.put('cpValorNivel3', 'cpValorNivel3');
                    drDireccion.put('cpValorNivel2', 'cpValorNivel2');
                    drDireccion.put('cpValorNivel1', 'cpValorNivel1');
                    drDireccion.put('cpTipoNivel6', 'cpTipoNivel6');
                    drDireccion.put('cpTipoNivel5', 'cpTipoNivel5');
                    drDireccion.put('cpTipoNivel4', 'cpTipoNivel4');
                    drDireccion.put('cpTipoNivel3', 'cpTipoNivel3');
                    drDireccion.put('cpTipoNivel2', 'cpTipoNivel2');
                    drDireccion.put('cpTipoNivel1', 'cpTipoNivel1');
                    drDireccion.put('bisViaPrincipal', 'bisViaPrincipal');
                    drDireccion.put('bisViaGeneradora', 'bisViaGeneradora');
                    drDireccion.put('barrioTxtBM', 'barrioTxtBM');
                    drDireccion.put('barrio', 'barrio');
                    drDireccion.put('idTipoDireccion', 'idTipoDireccion');
                inputMap.put('drDireccion', drDireccion);

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestObtenerBarrioListHhppTest() {
        String method = 'RequestObtenerBarrioListHhpp';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

                inputMap.put('dane','73001000');
                Map<String,Object> drDireccion = new Map<String, Object>();
                    drDireccion.put('usuarioEdicion','user');
                    drDireccion.put('usuarioCreacion','Test');
                    drDireccion.put('tipoViaPrincipal','Barrio');
                    drDireccion.put('tipoViaGeneradora','tipoViaGeneradora');
                    drDireccion.put('placadrDireccion','placadrDireccion');
                    drDireccion.put('perfilEdicion', 'perfilEdicion');
                    drDireccion.put('perfilCreacion', 'perfilCreacion');
                    drDireccion.put('numViaPrincipal', 'numViaPrincipal');
                    drDireccion.put('numViaGeneradora', 'numViaGeneradora');
                    drDireccion.put('nlPostViaP', 'nlPostViaP');
                    drDireccion.put('nlPostViaG', 'nlPostViaG');
                    drDireccion.put('mzValorNivel6', 'mzValorNivel6');
                    drDireccion.put('mzValorNivel5', 'mzValorNivel5');
                    drDireccion.put('mzValorNivel4', 'mzValorNivel4');
                    drDireccion.put('mzValorNivel3', 'mzValorNivel3');
                    drDireccion.put('mzValorNivel2', 'mzValorNivel2');
                    drDireccion.put('mzValorNivel1', 'mzValorNivel1');
                    drDireccion.put('mzTipoNivel6', 'mzTipoNivel6');
                    drDireccion.put('mzTipoNivel5', 'mzTipoNivel5');
                    drDireccion.put('mzTipoNivel4', 'mzTipoNivel4');
                    drDireccion.put('mzTipoNivel3', 'mzTipoNivel3');
                    drDireccion.put('mzTipoNivel2', 'mzTipoNivel2');
                    drDireccion.put('mzTipoNivel1', 'mzTipoNivel1');
                    drDireccion.put('ltViaPrincipal', 'ltViaPrincipal');
                    drDireccion.put('ltViaGeneradora', 'ltViaGeneradora');
                    drDireccion.put('letra3G', 'letra3G');
                    drDireccion.put('itValorPlaca', 'itValorPlaca');
                    drDireccion.put('itTipoPlaca', 'itTipoPlaca');
                    drDireccion.put('idTipodrDireccion', 'idTipodrDireccion');
                    drDireccion.put('idSolicitud', 'idSolicitud');
                    drDireccion.put('idDirCatastro', 'idDirCatastro');
                    drDireccion.put('id', 'id');
                    drDireccion.put('fechaEdicion', 'fechaEdicion');
                    drDireccion.put('fechaCreacion', 'fechaCreacion');
                    drDireccion.put('estrato', 'estrato');
                    drDireccion.put('estadoRegistro', 'estadoRegistro');
                    drDireccion.put('estadoDirGeo', 'estadoDirGeo');
                    drDireccion.put('dirPrincAlt', 'dirPrincAlt');
                    drDireccion.put('dirEstado', 'dirEstado');
                    drDireccion.put('cuadViaPrincipal', 'cuadViaPrincipal');
                    drDireccion.put('cuadViaGeneradora', 'cuadViaGeneradora');
                    drDireccion.put('cpValorNivel6', 'cpValorNivel6');
                    drDireccion.put('cpValorNivel5', 'cpValorNivel5');
                    drDireccion.put('cpValorNivel4', 'cpValorNivel4');
                    drDireccion.put('cpValorNivel3', 'cpValorNivel3');
                    drDireccion.put('cpValorNivel2', 'cpValorNivel2');
                    drDireccion.put('cpValorNivel1', 'cpValorNivel1');
                    drDireccion.put('cpTipoNivel6', 'cpTipoNivel6');
                    drDireccion.put('cpTipoNivel5', 'cpTipoNivel5');
                    drDireccion.put('cpTipoNivel4', 'cpTipoNivel4');
                    drDireccion.put('cpTipoNivel3', 'cpTipoNivel3');
                    drDireccion.put('cpTipoNivel2', 'cpTipoNivel2');
                    drDireccion.put('cpTipoNivel1', 'cpTipoNivel1');
                    drDireccion.put('bisViaPrincipal', 'bisViaPrincipal');
                    drDireccion.put('bisViaGeneradora', 'bisViaGeneradora');
                    drDireccion.put('barrioTxtBM', 'barrioTxtBM');
                    drDireccion.put('barrio', 'barrio');
                    drDireccion.put('idTipoDireccion', 'idTipoDireccion');
                inputMap.put('drDireccion', drDireccion);

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConsultaDireccionGeneralTest() {
        String method = 'RequestConsultaDireccionGeneral';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        inputMap.put('dane','73001000');
        inputMap.put('street','carrera 102 83 60'); 
        Map<String,Object> drDireccion = new Map<String, Object>();
            drDireccion.put('usuarioEdicion','user');
            drDireccion.put('usuarioCreacion','Test');
            drDireccion.put('tipoViaPrincipal','Barrio');
            drDireccion.put('tipoViaGeneradora','tipoViaGeneradora');
            drDireccion.put('placadrDireccion','placadrDireccion');
            drDireccion.put('perfilEdicion', 'perfilEdicion');
            drDireccion.put('perfilCreacion', 'perfilCreacion');
            drDireccion.put('numViaPrincipal', 'numViaPrincipal');
            drDireccion.put('numViaGeneradora', 'numViaGeneradora');
            drDireccion.put('nlPostViaP', 'nlPostViaP');
            drDireccion.put('nlPostViaG', 'nlPostViaG');
            drDireccion.put('mzValorNivel6', 'mzValorNivel6');
            drDireccion.put('mzValorNivel5', 'mzValorNivel5');
            drDireccion.put('mzValorNivel4', 'mzValorNivel4');
            drDireccion.put('mzValorNivel3', 'mzValorNivel3');
            drDireccion.put('mzValorNivel2', 'mzValorNivel2');
            drDireccion.put('mzValorNivel1', 'mzValorNivel1');
            drDireccion.put('mzTipoNivel6', 'mzTipoNivel6');
            drDireccion.put('mzTipoNivel5', 'mzTipoNivel5');
            drDireccion.put('mzTipoNivel4', 'mzTipoNivel4');
            drDireccion.put('mzTipoNivel3', 'mzTipoNivel3');
            drDireccion.put('mzTipoNivel2', 'mzTipoNivel2');
            drDireccion.put('mzTipoNivel1', 'mzTipoNivel1');
            drDireccion.put('ltViaPrincipal', 'ltViaPrincipal');
            drDireccion.put('ltViaGeneradora', 'ltViaGeneradora');
            drDireccion.put('letra3G', 'letra3G');
            drDireccion.put('itValorPlaca', 'itValorPlaca');
            drDireccion.put('itTipoPlaca', 'itTipoPlaca');
            drDireccion.put('idTipodrDireccion', 'idTipodrDireccion');
            drDireccion.put('idSolicitud', 'idSolicitud');
            drDireccion.put('idDirCatastro', 'idDirCatastro');
            drDireccion.put('id', 'id');
            drDireccion.put('fechaEdicion', 'fechaEdicion');
            drDireccion.put('fechaCreacion', 'fechaCreacion');
            drDireccion.put('estrato', 'estrato');
            drDireccion.put('estadoRegistro', 'estadoRegistro');
            drDireccion.put('estadoDirGeo', 'estadoDirGeo');
            drDireccion.put('dirPrincAlt', 'dirPrincAlt');
            drDireccion.put('dirEstado', 'dirEstado');
            drDireccion.put('cuadViaPrincipal', 'cuadViaPrincipal');
            drDireccion.put('cuadViaGeneradora', 'cuadViaGeneradora');
            drDireccion.put('cpValorNivel6', 'cpValorNivel6');
            drDireccion.put('cpValorNivel5', 'cpValorNivel5');
            drDireccion.put('cpValorNivel4', 'cpValorNivel4');
            drDireccion.put('cpValorNivel3', 'cpValorNivel3');
            drDireccion.put('cpValorNivel2', 'cpValorNivel2');
            drDireccion.put('cpValorNivel1', 'cpValorNivel1');
            drDireccion.put('cpTipoNivel6', 'cpTipoNivel6');
            drDireccion.put('cpTipoNivel5', 'cpTipoNivel5');
            drDireccion.put('cpTipoNivel4', 'cpTipoNivel4');
            drDireccion.put('cpTipoNivel3', 'cpTipoNivel3');
            drDireccion.put('cpTipoNivel2', 'cpTipoNivel2');
            drDireccion.put('cpTipoNivel1', 'cpTipoNivel1');
            drDireccion.put('bisViaPrincipal', 'bisViaPrincipal');
            drDireccion.put('bisViaGeneradora', 'bisViaGeneradora');
            drDireccion.put('barrioTxtBM', 'barrioTxtBM');
            drDireccion.put('barrio', 'barrio');
            drDireccion.put('idTipoDireccion', 'idTipoDireccion');
        inputMap.put('drDireccion', drDireccion);

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

    @isTest
    public static void requestConsultaDireccionTest() {
        String method = 'RequestConsultaDireccion';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        inputMap.put('idDireccion','73001000');

        Test.startTest();
            FVU_MERSystemInterface mer = new FVU_MERSystemInterface();
            Boolean retValue = mer.invokeMethod(method, inputMap, outputMap, null);
        Test.stopTest();
    }

}