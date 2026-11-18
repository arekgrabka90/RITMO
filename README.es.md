# RITMO

### Planificador personal de trabajo y liquidación de turnos

**RITMO** es un planificador personal para profesionales de la hostelería. Reúne la planificación de horarios, el registro de turnos y sus liquidaciones en una aplicación Android.

**Estado del proyecto:** 0.0.1 en desarrollo  
**Plataforma:** teléfonos y tabletas Android  
**Modelo:** aplicación personal, local y sin conexión

**Otros idiomas:** [English](README.md) · [Polski](README.pl.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md)

---

## Visión del proyecto

El trabajo en hostelería implica horarios cambiantes, distintos lugares y puestos de trabajo, horas trabajadas, propinas, efectivo y pagos con tarjeta. RITMO pretende ofrecer un único espacio práctico para registrar y organizar esta información.

RITMO está diseñado como una herramienta personal para profesionales individuales de la hostelería. No es un sistema de gestión de restaurantes, de personal ni un producto SaaS.

## Principios fundamentales

- **Personal:** inicialmente destinado a una sola persona.
- **Sin conexión:** las funciones principales y los datos se almacenan localmente.
- **Privado:** sin cuentas, backend, servicios en la nube ni sincronización en el alcance inicial.
- **Flexible:** las funciones se incorporan gradualmente.
- **Fiable:** la integridad de los datos, las migraciones probadas y las copias de seguridad son requisitos importantes.
- **Adaptable:** una aplicación para teléfonos y tabletas Android.
- **Registros separados:** el salario del empleador y las liquidaciones de turnos son áreas independientes.

## Versión 0.0.1

La primera versión se centra en la base de la aplicación y en el flujo esencial de gestión del trabajo.

### Lugares de trabajo y puestos
- Crear y editar lugares de trabajo.
- Definir nombre, color, moneda y nota.
- Crear puestos asociados a cada lugar de trabajo.
- Archivar y restaurar lugares de trabajo y puestos.

### Turnos y calendario
- Crear, editar y eliminar turnos.
- Asignar un lugar de trabajo y, opcionalmente, un puesto.
- Introducir manualmente las horas de inicio y fin.
- Marcar los turnos como planificados o trabajados.
- Añadir notas.
- Consultar turnos por día y navegar entre meses.

El registro de entrada/salida (punch in/out), las pausas, el redondeo del tiempo y el cálculo automático del salario no forman parte de 0.0.1.

### Liquidaciones de turnos

Cada liquidación está asociada a un turno concreto. La versión 0.0.1 está prevista para admitir una liquidación por turno y estas categorías:

1. Propinas en efectivo — total de propinas en efectivo.
2. Propinas con tarjeta — total de propinas con tarjeta.
3. Impuesto sobre las propinas con tarjeta.
4. Reparto de propinas (tip payout) — pagos a cocina y bar.
5. Ventas y pagos — datos de ventas y conciliación de pagos.
6. Control de efectivo — control de caja.

Se pueden añadir elementos individuales con etiquetas, importes y notas opcionales. También se admiten elementos personalizados.

**No se realizan cálculos de liquidación.** En esta versión RITMO no suma, resta, interpreta ni distribuye importes automáticamente, no calcula impuestos ni impone procedimientos de liquidación.

### Ajustes e interfaz
- Temas claro, oscuro y del sistema.
- Navegación y diseños adaptables a teléfonos y tabletas.
- Persistencia local de datos y ajustes.
- Secciones previstas: Hoy, Calendario, Liquidaciones, Finanzas y Más.

Algunas secciones estarán deliberadamente limitadas en la primera versión.

### Copias de seguridad y restauración
La versión 0.0.1 incluye copias manuales de la base de datos:
- Exportar una copia a un archivo elegido por el usuario.
- Validar la copia antes de restaurarla.
- Comprobar la integridad y la compatibilidad del esquema antes de sustituir los datos actuales.

La copia de seguridad en la nube del sistema Android está desactivada por decisión del proyecto. Las copias deben guardarse en un lugar seguro. Desinstalar la aplicación puede eliminar la base de datos local.

## Privacidad y propiedad de los datos

La aplicación inicial está diseñada para funcionar sin cuenta en línea ni backend remoto. Cada dispositivo mantiene su propia base de datos local. La sincronización entre dispositivos no está incluida.

El proyecto no prevé transmitir registros personales de trabajo o liquidaciones a servidores externos.

## Tecnología

La pila Android prevista incluye:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

Las versiones definitivas de las dependencias y los detalles de implementación se determinarán durante el desarrollo.

## Integridad de datos y gestión del tiempo

La implementación debe seguir estos principios:
- Migraciones explícitas de la base de datos, probadas con bases que contienen datos existentes.
- Sin mecanismos de migración destructiva como alternativa.
- Integridad referencial y restricciones adecuadas en la base de datos.
- Importes monetarios almacenados como enteros en unidades monetarias mínimas.
- Marcas de tiempo en UTC junto con el identificador de la zona horaria de origen.
- Gestión correcta de turnos que cruzan la medianoche y de los cambios de horario estacional, incluidas las horas locales inexistentes o repetidas.
- Validación de las copias antes de restaurar o sustituir la base activa.

## Hoja de ruta

| Versión | Objetivo previsto |
|---|---|
| 0.0.1 | Base de la aplicación, lugares de trabajo, puestos, turnos, liquidaciones básicas y copias manuales |
| 0.0.2 | Punch in/out y más funciones de control horario |
| Versiones futuras | Gestión salarial, herramientas financieras ampliadas y más funciones de liquidación |

Las funciones futuras se especificarán y aprobarán por separado.

## Fuera del alcance de 0.0.1

- Cuentas y funciones multiusuario.
- Backend, servicios en la nube y sincronización.
- Integraciones con TPV/POS y sistemas de restaurantes.
- Cálculo automático de impuestos o reparto de propinas.
- Motor de reglas y cálculos automáticos de liquidaciones.
- Cálculo de salarios.
- Analítica financiera avanzada y previsiones.
- Punch in/out, pausas y redondeo del tiempo.
- Geofencing, Wear OS y widgets.
- Notificaciones avanzadas.
- Exportación avanzada a PDF o hojas de cálculo.
- Compartir registros con otras personas.

## Documentación del repositorio

Las especificaciones y decisiones de desarrollo se mantienen en documentos separados:

- `RITMO_0.0.1_SCOPE.md` — alcance de la primera versión.
- `RITMO_0.0.1_ROADMAP.md` — etapas de implementación.
- `RITMO_0.0.1_DATA_MODEL.md` — modelo de datos propuesto.
- `RITMO_0.0.1_ACCEPTANCE.md` — criterios de aceptación y pruebas.
- `RITMO_DECISIONS.md` — decisiones aprobadas, propuestas y cuestiones abiertas.

## Estado del desarrollo

RITMO 0.0.1 está en desarrollo. Este README describe los objetivos y el alcance previsto; no afirma que todas las funciones enumeradas estén implementadas o verificadas.

Antes de considerar terminada la versión deben verificarse la compilación, las pruebas automatizadas, las migraciones, las copias/restauraciones y el comportamiento en teléfonos y tabletas.

---

**RITMO — Organiza tu trabajo. Mantén el control de tus datos.**
