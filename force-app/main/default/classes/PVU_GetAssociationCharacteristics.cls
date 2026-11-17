/**
 * @Autor                    : SALESFORCE
 * @Empresa                  : Salesforce.com
 * @description              :
 * @Cobertura de Código      :
 * @Ultima modificación en   : 09-22-2025
 * @Ultima modificación por  : SALESFORCE
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   04-23-2025   SALESFORCE     Initial Version
 * 1.0   07-18-2025   GM             Se cambia la logica, se devuelve un array de casos con sus registros de Relaciones de Equipos
 * 1.1   09-22-2025   Héctor Machuca Se ajustan los valores nuevos para mostrar en el servicio de GetAssociationCharacteristics (FechaPago, CuotaInicial, CuentaFacturacion)
 * 1.2   01-15-2026   Mariana Olay.  Se añade else donde añade los campos de la metadata AssociationCharacteristics aun cuando su valor sea nulo.
 * 1.3   02-13-2026   Ezequiel Olivera. Se cambia estructura de fields y se agrega fianza y requerimiento legal.HU724364
 * 1.4   04-16-2026   Mariana Olay   Se refactoriza clase a version 1.2 añadiendo los campos de fianza y RL BUG752120.

 **/
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.CyclomaticComplexity,PMD.UnusedLocalVariable,PMD.AvoidDeeplyNestedIfStmts,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.ClassNamingConventions')
global without sharing class PVU_GetAssociationCharacteristics implements vlocity_cmt.VlocityOpenInterface {
  
  /**
   * @description Entry point invoked by OmniStudio Integration Procedures.
   *              Routes execution to the requested method.
   *
   * @param methodName Name of the method to execute
   * @param inputMap   Input parameters received from the caller
   * @param outMap     Output response map returned to the caller
   * @param options    Additional runtime options
   *
   * @return Boolean true if execution succeeded, false otherwise
   */
  global Boolean invokeMethod(
    String methodName,
    Map<String, Object> inputMap,
    Map<String, Object> outMap,
    Map<String, Object> options
  ) {
    Boolean result = true;

    try {
      if (methodName.equals('getAssocCharsDynamic')) {
        //System.debug('--- en getAssocCharsDynamic del metod');
        getAssocCharsDynamic(inputMap, outMap, options);
      }
    } catch (Exception e) {/*System.debug('invokeMethod -> exception: ' + e); System.debug('invokeMethod -> exception: ' + e.getLineNumber());*/result = false; }

    return result;
  }

  /**
   * @description Executes dynamic query logic to retrieve association characteristics
   *              based on metadata configuration and input filters.
   *              Groups results by Case and calculates totals including fianza
   *              and requerimiento legal values.
   *
   * @param inputMap Map containing query configuration parameters
   * @param outMap   Map where the formatted response will be stored
   * @param options  Additional execution options
   */

  public static void getAssocCharsDynamic(
    Map<String, Object> inputMap,
    Map<String, Object> outMap,
    Map<String, Object> options
  ) {
    //System.debug('--- en getAssocCharsDynamic');
    String objectName = (String) inputMap.get('sObjectName');
    String fieldStandard = (String) inputMap.get('fieldStandard');
    String typeMatchCM = (String) inputMap.get('customerVoice');
    String documentType = (String) inputMap.get('documentType');
    String documentNumber = (String) inputMap.get('documentNumber');
    String status = (String) inputMap.get('status');
    List<Object> whereObject = (List<Object>) inputMap.get('wheredata');

    List<Map<String, Object>> allresponse = new List<Map<String, Object>>();
    List<Map<String, Object>> whereFields = new List<Map<String, Object>>();
    Map<String, Object> standardFields = new Map<String, Object>();
    List<Map<String, Object>> associationCharacteristics = new List<Map<String, Object>>();
    ResponseWrapper response = new ResponseWrapper();
    String caseNumber = ' ';
    //System.debug('EL typeMatchCM -----------' + typeMatchCM);

    try {
      for (Object instance : whereObject) {
        whereFields.add((Map<String, Object>) instance);
      }

      if (!String.isEmpty(typeMatchCM)) {
        //Query to get custom fields to show in query
        PVU_TMFFieldsInsertCase__mdt[] cmt = [
          SELECT type__c, field_custom__c, squad__c
          FROM PVU_TMFFieldsInsertCase__mdt
          WHERE type__c = :typeMatchCM
          WITH USER_MODE
          LIMIT 1
        ];
        String fieldsCustom = '';
        List<String> fieldsCustomsList = new List<String>();
        if (cmt.size() > 0) {
          fieldsCustom = cmt[0].field_custom__c;
          fieldsCustomsList = fieldsCustom.split(',');
        }
        List<String> fieldStandards = fieldStandard.split(',');

        //init query
        String query = 'SELECT ';
        if (fieldStandard != null) {
          query += fieldStandard + ', ';
        }
        if (!String.isEmpty(fieldsCustom)) {
          query += fieldsCustom;
        }

        query = query.removeEnd(', ');

        //Where dynamic
        String wheres = '';
        for (Map<String, Object> whereField : whereFields) {
          if (
            whereField.get('field') != null &&
            whereField.get('value') != null
          ) {
            wheres +=
              whereField.get('field') +
              '= \'' +
              String.escapeSingleQuotes((String) whereField.get('value')) +
              '\' ' +
              whereField.get('operater') +
              ' ';
          }
        }

        if (wheres.endsWith('AND ')) {
          wheres = wheres.removeEnd('AND ');
        } else if (wheres.endsWith('OR ')) { wheres = wheres.removeEnd('OR ');}
        //end query
        query += ' FROM ' + objectName + ' WHERE ' + wheres;

        //System.debug('EL QUERY -----------' + query);
        SObject[] recordsObject = Database.query(query);

        //System.debug('LOS VALORES -----------' + recordsObject);
        integer contador = 0;
        Boolean generarCaso = false;
        Map<String, Object> infoCase = new Map<String, Object>();

        List<associationCharacteristicsRes> listResponse = new List<associationCharacteristicsRes>();
        Map<Id, associationCharacteristicsRes> caseIdToWrapperMap = new Map<Id, associationCharacteristicsRes>();

        for (SObject resp : recordsObject) {
            Id caseId = (Id) resp.get('PVU_caso_relacionado__c');
            String conceptoDevolucionCuotas = (String) resp.get('PVU_ConceptoDevolucionCuotas__c');
            //System.debug('caseId -----------' + caseId);
            
            associationCharacteristicsRes associationRecord = new associationCharacteristicsRes();
            associationRecord.associationCharacteristics = new ResponseWrapper();
            associationCharacteristicsList associationCharacteristicListRecord = new associationCharacteristicsList();
            
            if (caseIdToWrapperMap.containsKey(caseId)) {
                associationRecord = caseIdToWrapperMap.get(caseId);
            } else {
                contador++;
            }

          associationCharacteristicListRecord.fields.put( 'OrderNumber', '');
          Decimal caseRequerimientoLegal = 0.00;

          for (String fieldsCustomResp : fieldsCustomsList) {
            if (fieldsCustomResp.contains('.')) {
              String[] relathionObjectList = fieldsCustomResp.split('\\.');
              String relathionObjectName = relathionObjectList[0].trim();
              String relathionObjectValue = relathionObjectList[1].trim();

              if (resp.getSObject(relathionObjectName) != null) {
                SObject respChild = resp.getSObject(relathionObjectName);

                if (relathionObjectValue == 'CaseNumber') {
                  associationRecord.associationCharacteristics.caseNumber = (String) respChild.get(
                    'CaseNumber'
                  );
                  associationRecord.associationCharacteristics.caseVoiceCustomer = (String) respChild.get(
                    'PVU_Level3__c'
                  );
                  associationRecord.associationCharacteristics.caseStatus = (String) respChild.get(
                    'Status'
                  );
                  associationRecord.associationCharacteristics.caseMotivoDevolucion = (String) respChild.get(
                    'PVU_MotivoDevolucion__c'
                  );
                  associationRecord.associationCharacteristics.caseOds = (String) respChild.get(
                    'PVU_IdODS__c'
                  );
                  associationRecord.associationCharacteristics.caseValorTotal = (double) respChild.get(
                      'PVU_Valor_total_de_devolucion__c'
                  );
                  associationRecord.associationCharacteristics.fechaPago = (Date) respChild.get(
                    'Fecha_del_pago__c'
                  );
                  caseRequerimientoLegal = (double) respChild.get(
                    'PVU_ValorRL__c'
                  );
                }

                if (relathionObjectName == 'PVU_Order__r') {
                  associationCharacteristicListRecord.fields.put('OrderNumber', (String) respChild.get('OrderNumber'));
                }
              }
            } else {
              Schema.DescribeFieldResult fieldLabelDescribe = resp.getSObjectType().getDescribe().fields.getMap().get(fieldsCustomResp.trim()).getDescribe();
              if (resp.get(fieldsCustomResp.trim()) != null) {
                  if (fieldsCustomResp.trim() == 'PVU_CuotaInicial__c' && conceptoDevolucionCuotas == 'EF') {
                      associationCharacteristicListRecord.fields.put('Valor devolución', resp.get(fieldsCustomResp.trim()));
                  } else if (fieldsCustomResp.trim() == 'PVU_ConceptoDevolucionCuotas__c') {
                      associationCharacteristicListRecord.fields.put('Concepto devolución Cuotas pagas', resp.get(fieldsCustomResp.trim()));
                  } else {
                  associationCharacteristicListRecord.fields.put(
                    fieldLabelDescribe.getLabel(),
                    resp.get(fieldsCustomResp.trim())
                  );
                }
              } else {
                  associationCharacteristicListRecord.fields.put(fieldLabelDescribe.getLabel(), '');
              }
            }
          }

          associationRecord.associationCharacteristics.associationCharacteristicsList.add(associationCharacteristicListRecord);
          caseIdToWrapperMap.put(caseId, associationRecord);
          listResponse=caseIdToWrapperMap.values();
        }
          
        //System.debug('listResponse -----------' + JSON.serialize(listResponse));

        if (recordsObject.isEmpty()) {
          outMap.put('message', 'Case not found');outMap.put('status', 'Failed');outMap.put('code', '400');
        } else {
          outMap.put('responsesData', JSON.serializePretty(listResponse));
          outMap.put('cantidad', contador);
          outMap.put('status', 'Success');
          outMap.put('code', '200');
        }
      } else {
        outMap.put('message', 'Field customerVoice required');
        outMap.put('status', 'Failed');
        outMap.put('code', '400');
      }

      outMap.remove('errorCode');
      outMap.remove('error');
    } catch (Exception e) {outMap.put('message', e.getMessage() + ' Line: ' + e.getLineNumber());outMap.put('status', 'Failed');outMap.put('code', '500');}
  }

  /**
   * @description Wrapper list used to store dynamic field maps
   *              associated to a Case response.
   */

  public class associationCharacteristicsList {
    /**
     * @description Constructor initializing fields list
     */
    public Map<String, Object> fields { get; set; }
     /**
     * @description Constructor initializing fields list
     */
    public associationCharacteristicsList() {
            fields = new Map<String, Object>();
        }
  }

  /**
   * @description Main response wrapper containing Case level
   *              information and associated characteristics.
   */
  public class ResponseWrapper {
    @AuraEnabled
    public String caseNumber;
    @AuraEnabled
    public String caseVoiceCustomer;
    @AuraEnabled
    public String caseStatus;
    @AuraEnabled
    public String caseMotivoDevolucion;
    @AuraEnabled
    public String caseOds;
    @AuraEnabled
    public Date fechaPago;
    @AuraEnabled
    public double caseValorTotal;

    @AuraEnabled
    public List<associationCharacteristicsList> associationCharacteristicsList;
    @AuraEnabled
    public Decimal caseRequerimientoLegal;
    /**
     * @description Constructor initializing lists
     */

    public ResponseWrapper() {
      this.associationCharacteristicsList = new List<associationCharacteristicsList>();
    }
  }
  /**
   * @description Outer response container used for serialization
   *              of association characteristics.
   */
  public class associationCharacteristicsRes {
    @AuraEnabled
    public ResponseWrapper associationCharacteristics;
  }
}