@IsTest
public with sharing class FVU_IdClaroRepresentationTest {

    @IsTest
    public static void IdClaroRepresentationTest() {
        FVU_IdClaroRepresentation data = new FVU_IdClaroRepresentation();

        data.urlOK = 'URL';
        data.methodSendOK = 'get';
        data.user = 'ECM3628F';
        data.chanelTypeCode = '1';
        data.documentClient = 'CC-123456789';
        data.urlReturn = 'URL Return';
        data.accountNumber = '66984667';
        data.accountType = 'N/A';
        data.company = 'CLARO';
        data.application = 'SALESFORCE';
        data.accessKey = '1234567890';
        data.idSucursal = 'CAC11.00001';
        data.expeditionDate = '2023-01-01';
        data.codDepartment = 'test';
        data.codCity = 'test';
        data.device = 'desktop';
        data.region = 'test';
        data.agente = 'test';
        data.puntoVenta = 'test';
        data.name = 'Name';
        data.secondName = 'Second Name';
        data.lastName = 'Last Name';
        data.secondLastName = 'Second Last Name';
        data.phoneNumber = '111222333';
        data.emailAddress = 'test@email.com';
        data.antiquityClient = 'test';
        data.methodSendReturn = 'get';

        system.assertEquals(data.urlOK, 'URL','urlOK is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.methodSendOK, 'get','methodSendOK is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.user, 'ECM3628F','user is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.chanelTypeCode, '1','chanelTypeCode is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.documentClient, 'CC-123456789','documentClient is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.urlReturn, 'URL Return','urlReturn is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.accountNumber, '66984667','accountNumber is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.accountType, 'N/A','accountType is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.company, 'CLARO','company is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.application, 'SALESFORCE','application is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.accessKey, '1234567890','accessKey is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.idSucursal, 'CAC11.00001','idSucursal is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.expeditionDate, '2023-01-01','expeditionDate is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.codDepartment, 'test','codDepartment is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.codCity, 'test','codCity is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.device, 'desktop','device is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.region, 'test','region is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.agente, 'test','agente is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.puntoVenta, 'test','puntoVenta is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.name, 'Name','name is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.secondName, 'Second Name','secondName is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.lastName, 'Last Name','lastName is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.secondLastName, 'Second Last Name','secondLastName is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.phoneNumber, '111222333','phoneNumber is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.emailAddress, 'test@email.com','emailAddress is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.methodSendReturn, 'get','methodSendReturn is wrong in FVU_IdClaroRepresentation');
        system.assertEquals(data.antiquityClient, 'test', 'antiquityClient is wrong in FVU_IdClaroRepresentation');
    }
}