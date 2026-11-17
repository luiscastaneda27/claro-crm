/**
 * @description Clase base virtual para los manejadores de triggers. Enruta la
 *              ejecución al método correspondiente según el contexto del trigger
 *              y expone un mecanismo estático de bypass para optimización de
 *              rendimiento y cargas masivas de datos.
 *
 * Los métodos virtuales por contexto (beforeInsert, afterUpdate, etc.) son
 * "hooks" vacíos por diseño (patrón Template Method): cada subclase sobrescribe
 * únicamente los que necesita. Por eso se suprime PMD.EmptyStatementBlock a
 * nivel de clase: los cuerpos vacíos son intencionales, no un descuido.
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public inherited sharing virtual class TriggerHandler {
    // Mecanismo estático de bypass para optimización de rendimiento y cargas de datos
    private static Set<String> bypassedHandlers = new Set<String>();

    /**
     * @description Desactiva (bypass) la ejecución del handler indicado.
     * @param handlerName Nombre del handler que debe omitirse.
     */
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    /**
     * @description Reactiva un handler previamente omitido.
     * @param handlerName Nombre del handler que debe reactivarse.
     */
    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    /**
     * @description Indica si un handler está actualmente omitido.
     * @param handlerName Nombre del handler a consultar.
     * @return Boolean true si el handler está en bypass; de lo contrario false.
     */
    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    /**
     * @description Elimina todos los bypasses registrados.
     */
    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    /**
     * @description Punto de entrada principal. Enruta la ejecución al método
     *              correspondiente según Trigger.operationType, respetando el
     *              mecanismo de bypass.
     */
    public void run() {
        String handlerName = String.valueOf(this).split(':')[0];
        if (isBypassed(handlerName)) {
            return;
        }

        dispatch(Trigger.operationType);
    }

    /**
     * @description Enruta la ejecución al método virtual correspondiente según el
     *              tipo de operación del trigger. Se extrae de run() para poder
     *              probar cada contexto de forma unitaria sin depender de un
     *              trigger real (Trigger.operationType es de solo lectura).
     * @param operationType Tipo de operación del trigger en curso.
     */
    @TestVisible
    private void dispatch(System.TriggerOperation operationType) {
        switch on operationType {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    // Métodos virtuales con comentarios declarativos para evitar alertas de bloques vacíos en PMD
    protected virtual void beforeInsert() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void beforeUpdate() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void beforeDelete() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void afterInsert() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void afterUpdate() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void afterDelete() {
        // Implementación base virtual opcional para clases hijas
    }
    protected virtual void afterUndelete() {
        // Implementación base virtual opcional para clases hijas
    }
}