/**
 * =============<< ********* >>=============
 * Author       : Harold Garcia
 * Email        : harold.garcia@intellectsystem.net
 * Organization : Intellect System
 * Created On   : 2026-02-25
 * Title        : EU_TipificacionService – Servicio de Consulta Jerárquica de Tipificaciones
 * Description  :
 *  Servicio Apex expuesto a LWC encargado de gestionar la consulta dinámica
 *  de la jerarquía de Tipificación (Nivel 1, Nivel 2 y Nivel 3) asociada a una Skill.
 *
 *  Funcionalidades principales:
 *   • Obtiene la Tipificación Nivel 1 (N1) configurada en EU_Skill__c.
 *   • Recupera las opciones de Tipificación Nivel 2 (N2) filtradas por N1.
 *   • Recupera las opciones de Tipificación Nivel 3 (N3) filtradas por N2.
 *
 *  Este servicio es utilizado por el componente LWC de orquestación Avaya
 *  para mostrar y persistir la tipificación de llamadas.
 * =============<< ********* >>=============
 */

public with sharing class EU_TipificacionService {

    @AuraEnabled(cacheable=true)
    public static TipInitDTO getInit(String skillName) {
        TipInitDTO dto = new TipInitDTO();
        if (String.isBlank(skillName)) return dto;

        EU_Skill__c sk = [
            SELECT Id, Name, EU_Tipificacion__c
            FROM EU_Skill__c
            WHERE Name = :skillName
            LIMIT 1
        ];

        if (sk == null || sk.EU_Tipificacion__c == null) return dto;

        EU_TipificacionN1__c n1 = [
            SELECT Id, Name
            FROM EU_TipificacionN1__c
            WHERE Id = :sk.EU_Tipificacion__c
            LIMIT 1
        ];

        dto.n1Id = n1.Id;
        dto.n1Name = n1.Name;
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static List<TipOptionDTO> getN2(String n1Id) {
        if (String.isBlank(n1Id)) return new List<TipOptionDTO>();

        List<EU_TipificacionN2__c> rows = [
            SELECT Id, Name
            FROM EU_TipificacionN2__c
            WHERE EU_TipificacionN1__c = :n1Id
            ORDER BY Name
        ];

        return toOptions(rows);
    }

    @AuraEnabled(cacheable=true)
    public static List<TipOptionDTO> getN3(String n2Id) {
        if (String.isBlank(n2Id)) return new List<TipOptionDTO>();

        List<EU_TipificacionN3__c> rows = [
            SELECT Id, Name
            FROM EU_TipificacionN3__c
            WHERE EU_TipificacionN2__c = :n2Id
            ORDER BY Name
        ];

        return toOptions(rows);
    }

    private static List<TipOptionDTO> toOptions(List<SObject> rows) {
        List<TipOptionDTO> out = new List<TipOptionDTO>();
        for (SObject s : rows) {
            TipOptionDTO o = new TipOptionDTO();
            o.id = (String)s.get('Id');
            o.label = (String)s.get('Name');
            out.add(o);
        }
        return out;
    }

    public class TipInitDTO {
        @AuraEnabled public String n1Id;
        @AuraEnabled public String n1Name;
    }

    public class TipOptionDTO {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
    }
}