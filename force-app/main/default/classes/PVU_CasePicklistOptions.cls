/*--------------------------------------------------------------------------
 Author: Ángeles Pérez - maria.perez@nespon.com
 Company: Nespon
 Description: Obtener opciones de picklist para campo FIN_MotivoAjuste__c en Case
 Code Coverage: ------%
 History
 <Date> 	     <Author> 	      <Description>		  <Version>
 08-Sep-25 	Ángeles Pérez W 	Opciones picklist 	1ra version
----------------------------------------------------------------------------*/

global class PVU_CasePicklistOptions implements vlocity_cmt.VlocityOpenInterface {

    @TestVisible private static final String DEFAULT_ORIGIN = 'V360';

    public Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        try{  
            if (methodName.equals('populatePicklist')) {
                populatePicklist(input, outMap, options);
            }
           
        }catch (Exception e) {
            outMap.put('errormessage',e.getMessage());
            return false;
        }  
        return true;
    }

    public static void populatePicklist(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        String origin = DEFAULT_ORIGIN;
        if (input != null) {
            Object o = input.get('Origin');
            if (o == null) o = input.get('origin');
            if (o != null) origin = String.valueOf(o);
        }

        Integer ctrlIndex = getControllerIndex(Case.Origin, origin);
        System.debug(LoggingLevel.INFO, 'PVU_CasePicklistOptions -> Origin = ' + origin + ' | ctrlIndex = ' + String.valueOf(ctrlIndex));

        List<Map<String, String>> opts = new List<Map<String, String>>();
        if (ctrlIndex != null) {
            Schema.DescribeFieldResult depDfr = Case.FIN_MotivoAjuste__c.getDescribe();
            List<Schema.PicklistEntry> depVals = depDfr.getPicklistValues();
            System.debug(LoggingLevel.INFO, 'PVU_CasePicklistOptions ->  Dependent total = ' + depVals.size());

            for (Schema.PicklistEntry pe : depVals) {
                if (pe.isActive() && isValidFor(pe, ctrlIndex)) {
                    Map<String, String> row = new Map<String, String>();
                    row.put('name',  pe.getValue());
                    row.put('value',  pe.getLabel());
                    opts.add(row);
                }
            }
        }
        System.debug(LoggingLevel.INFO, 'PVU_CasePicklistOptions ->  Final options count = ' + opts.size());

        if (outMap == null) outMap = new Map<String, Object>();
        System.debug(LoggingLevel.INFO, 'PVU_CasePicklistOptions ->  opts ' + opts);
        outMap.put('options', opts);
    }

    private static Integer getControllerIndex(Schema.SObjectField controllerField, String controllerValue) {
        if (controllerField == null || String.isBlank(controllerValue)) return null;
        Schema.DescribeFieldResult dfr = controllerField.getDescribe();
        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
        Integer idx = 0;
        for (Schema.PicklistEntry pe : entries) {
            if (controllerValue == pe.getValue()) {
                return idx;
            }
            idx = idx + 1;
        }
        return null;
    }

    private class PEWrap { public String validFor; }

    @TestVisible
    private static Boolean isValidFor(Schema.PicklistEntry pe, Integer controllerIndex) {
        if (pe == null || controllerIndex == null || controllerIndex < 0) return false;

        String serialized = System.JSON.serialize(pe);
        PEWrap w = (PEWrap) System.JSON.deserialize(serialized, PEWrap.class);
        if (w == null || String.isBlank(w.validFor)) return false;

        Blob bytes = System.EncodingUtil.base64Decode(w.validFor);
        String hex = System.EncodingUtil.convertToHex(bytes);
        if (String.isBlank(hex)) return false;

        Integer byteIndex = controllerIndex / 8; 
        Integer bitInByte = controllerIndex - (byteIndex * 8);
        Integer hexPos = byteIndex * 2;
        if (hexPos + 2 > hex.length()) return false;

        Integer byteVal = hexPairToInt(hex.substring(hexPos, hexPos + 2));

        Integer shift = 7 - bitInByte;
        Integer twoPow = pow2(shift); 
        Integer bucket = byteVal / twoPow;
        Integer q = bucket / 2;
        Integer parity = bucket - (q * 2);
        return parity == 1;
    }

    private static Integer pow2(Integer n) {
        Integer v = 1;
        for (Integer i = 0; i < n; i++) v = v * 2;
        return v;
    }

    private static Integer hexPairToInt(String pair) {
        if (pair == null || pair.length() != 2) return 0;
        Integer hi = hexCharToInt(pair.substring(0, 1));
        Integer lo = hexCharToInt(pair.substring(1, 2));
        return (hi * 16) + lo;
    }

    private static Integer hexCharToInt(String one) {
        if (one == null || one.length() != 1) return 0;
        String s = one.toLowerCase();
        String digits = '0123456789abcdef';
        Integer pos = digits.indexOf(s);
        return (pos >= 0) ? pos : 0;
    }
}