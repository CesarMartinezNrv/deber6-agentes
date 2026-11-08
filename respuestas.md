# Deber 6 — Orquesta

## Ejecución local

Preparado con asistencia de Codex. La herramienta fue **Codex CLI 0.166.0-alpha.6**. El archivo de definición es [`.codex/agents/revisor-seguridad.toml`](.codex/agents/revisor-seguridad.toml), en formato TOML, con `name`, `description`, `developer_instructions` y capacidades desactivadas que no necesita esta revisión.

La documentación oficial describe agentes personalizados, pero la interfaz de delegación disponible en esta instalación no permitió seleccionar ese tipo automáticamente. Crear el archivo no bastó para registrarlo. Por eso se cargó su contenido explícitamente y se transmitieron sus instrucciones a un subagente real, con contexto propio. No se afirma que el TOML haya quedado registrado automáticamente.

También se intentó leer el archivo desde una sesión `read-only`; el entorno de Windows bloqueó incluso ese comando de lectura. La alternativa mantuvo `read-only`: el proceso invocador leyó el TOML y `usuarios.py`, numeró sus 42 líneas y los entregó como contexto. El subagente analizó ese contenido sin ejecutar herramientas. Esta limitación importa: se revisó el archivo proporcionado por el invocador, pero el hijo no abrió por sí mismo la ruta en el disco.

El comando reproducible, desde la raíz del repositorio, está en [invocar.ps1](invocar.ps1). Su llamada principal es:

```powershell
$promptRevision | codex exec --ignore-user-config -s read-only `
  -c agents.enabled=true -c features.apps=false -c features.plugins=false `
  -c skills.bundled.enabled=false -c skills.include_instructions=false `
  --json -
```

El prompt pide lanzar exactamente un subagente real, `revisor_seguridad`, transmitir el `developer_instructions` completo del TOML y las líneas del archivo, esperar su respuesta e informar su identificador. No pide al agente principal que finja ser el especialista. La invocación y los resultados originales se conservan en [evidencias/](evidencias/README.md).

La ejecución elegida tiene sesión principal `01a1bc64-bf47-7461-aabb-a5b24694b269` e hilo hijo `01a1bc65-1900-7532-98d6-b76ada5d3fe7`, con ruta `/root/revisor_seguridad`. El extracto del historial registra `collaboration.spawn_agent`, su resultado y `thread_spawn.parent_thread_id` del hijo. Es una señal verificable de delegación adicional al mensaje final del principal.

### Permisos y comprobación

El TOML limita la misión a lectura y búsqueda y prohíbe escribir, ejecutar Python, consultar la red o abrir otros archivos. **Esa instrucción no crea un sandbox de solo lectura ni una lista técnica de comandos permitidos.** El sandbox se eligió en la sesión principal con `-s read-only` y lo heredan los subagentes. Además se desactivaron apps y plugins para esta ejecución. En la alternativa final el hijo no necesitó herramientas: recibió el contenido exacto en el contexto.

No se puede afirmar que el archivo TOML por sí solo quite todos los permisos de escritura o encierre al agente en un solo archivo. La mitigación fue mantener el modo de solo lectura, acotar el contexto, conservar el registro y comparar el hash y Git después. La comprobación de integridad está en [verificacion.txt](evidencias/verificacion.txt). `usuarios.py` conserva los mismos bytes que la plantilla; no se ejecutó ni se corrigió.

Esto es delegación local dentro del harness de Codex. No se publicó una Agent Card, no se llamó un endpoint remoto y no se implementó el protocolo A2A. Tener dos contextos de agente no convierte el flujo en A2A.

### Hallazgos comprobados

| Línea | Problema | Severidad consolidada | Comprobación |
|---|---|---|---|
| 10 | Clave API escrita en el código | Baja en este ejemplo | Existe el literal de `API_KEY`; el curso indica que es falso |
| 11, 42 | Contraseña de administrador en texto claro | Media en este ejemplo | `es_admin` compara con `ADMIN_PASSWORD` |
| 21–22 | Entrada concatenada a SQL | Alta | `nombre` se incorpora al texto que se ejecuta |
| 30–37 | Nombre, edad y correo sin validar | Media | No hay validaciones antes de insertar; sí se usan parámetros SQL |
| 25–27 | Descuento sin validación | Media | No se comprueban tipos, precio negativo ni porcentajes fuera de rango |

Los valores de las credenciales no se repiten en el informe ni en las capturas. La severidad se refiere al patrón de código; no significa que se haya detectado una clave real expuesta. El problema de SQL está en la búsqueda, no en el INSERT parametrizado. En descuento, por ejemplo, 101% de descuento sobre 100 produce un precio negativo. No hizo falta ejecutar el archivo para comprobar esa expresión.

## A2UI

Tomo el hallazgo de la línea 21. La salida convencional sería:

| Archivo | Línea | Severidad | Hallazgo |
|---|---|---|---|
| `usuarios.py` | 21 | Alta | `nombre` se concatena a la consulta SQL sin parametrizar |

El catálogo aprobado para el boceto contiene únicamente:

- `Card`: contenedor que admite una lista de componentes hijos.
- `Text`: texto plano; no interpreta HTML ni código.
- `Button`: etiqueta, evento permitido y datos asociados; no recibe scripts.

> Ilustración didáctica; no es un mensaje A2UI estándar válido.

```json
{
  "component": "Card",
  "children": [
    {"component": "Text", "text": "usuarios.py · línea 21 · severidad: alta"},
    {"component": "Text", "text": "El nombre se concatena a la consulta SQL sin parametrizar."},
    {
      "component": "Button",
      "label": "Solicitar revisión adicional",
      "event": "pedir_revision",
      "data": {"findingId": "SQL-01", "file": "usuarios.py", "line": 21}
    }
  ]
}
```

La misma descripción está en [ui_ejemplo.json](ui_ejemplo.json). La captura es un boceto de esta tarjeta, no un renderer A2UI implementado.

Un agente o una plantilla produce la descripción estructurada. A2UI es el formato de comunicación de esa descripción, no es el LLM. Un modelo podría elegir los componentes, o una herramienta podría devolver siempre la misma plantilla rellenada con los datos del hallazgo.

El flujo sería: **agente o plantilla produce descripción → cliente valida esquema, catálogo, datos y acciones → renderer dibuja componentes ya implementados → usuario pulsa el botón → evento de retorno**. MCP no es un paso obligatorio para dibujar la interfaz.

Generative UI es la idea general de generar o adaptar una interfaz según la necesidad. A2UI es un formato declarativo concreto para describirla. Mi tabla Markdown comunica el hallazgo, pero no cumple A2UI por existir como tabla. Lo mismo pasaría con una página o un artefacto interactivo genérico.

### Qué valida el cliente

| Entrada problemática | Respuesta del cliente |
|---|---|
| JSON inválido | No renderiza; muestra un error controlado y puede pedir una corrección con un límite de reintentos |
| Componente fuera de `Card`, `Text`, `Button` | Rechaza la descripción; no lo convierte en HTML arbitrario |
| Acción peligrosa o evento distinto de `pedir_revision` | La bloquea; no ejecuta comandos enviados en el JSON |
| URL no autorizada | No la abre ni descarga contenido. Este catálogo no necesita URLs; rechaza propiedades de enlaces |
| Archivo, línea o severidad inválidos | Rechaza los datos: archivo autorizado, línea entre 1 y 42 y severidad de la lista permitida |

También limitaría longitud del texto, número de componentes y profundidad de la estructura. El catálogo es una barrera, pero no reemplaza la validación de datos, acciones, enlaces y autorización.

Al pulsar el botón, el cliente enviaría `event: pedir_revision` con `findingId: SQL-01`, `file: usuarios.py` y `line: 21`, junto al contexto de revisión del servidor. La identidad viene de la sesión autenticada, no de un nombre que mande el JSON. El backend debe comprobar que esa persona puede revisar ese proyecto, que el hallazgo existe y corresponde a la versión revisada y que la acción está permitida. El botón solo solicita otra revisión: no corrige el código, abre un PR ni hace merge por sí mismo.

## Preguntas finales

### 1. ¿Por qué dos especialistas y no uno solo?

Separaría seguridad y pruebas porque revisan cosas distintas del mismo archivo y pueden trabajar en paralelo. Así cada uno recibe una misión corta. El costo es coordinar dos contextos, gastar más tokens y comprobar que sus resultados no se contradigan. Para este archivo pequeño, un solo agente también podría hacerlo; aquí la separación sirve para practicar el diseño.

### 2. ¿Cómo verifiqué la ejecución y los hallazgos? ¿Qué haría si fallara?

La evidencia conserva la delegación real y el resultado del subagente, no solo una respuesta del principal con otro nombre. Comparé las líneas reportadas con las 42 líneas de `usuarios.py` y comprobé la integridad del archivo. También quedaron documentadas las limitaciones de carga y lectura. Si falla, mantendría el informe incompleto, pediría una corrección concreta y, después de un reintento fallido, avisaría a la persona.

### 3. ¿Qué permisos mínimos le di y qué no pudo garantizar la herramienta?

Su misión solo permite leer y buscar en el archivo indicado. Elegí `read-only` en la sesión y desactivé apps y plugins. Como Windows bloqueó la lectura desde el agente, recibió el contenido como contexto y no usó herramientas. El TOML no impone por sí solo un sandbox ni un permiso técnico exclusivo sobre un archivo. Por eso no afirmo que escribir «no edites» garantice ese aislamiento; además comprobé Git y el hash.

### 4. ¿Cuándo bastan subagentes locales y cuándo usaría A2A?

Los locales bastan si los especialistas trabajan dentro de mi herramienta y puedo darles el contexto necesario. A2A compensaría si el especialista es de otro equipo, está en otro servidor y ofrece una interfaz compatible. Tendría que justificar el costo de red, autenticación, seguimiento de tareas y revisión de confianza. Para este deber no hace falta desplegarlo.

### 5. ¿Cómo manejaría `input-required` o un fallo de la Task?

Con `input-required` mostraría qué falta, obtendría una respuesta autorizada y continuaría la misma tarea según la interfaz. Si termina en `failed`, conservaría el error y avisaría. Solo reintentaría un fallo temporal con un límite; no inventaría un Artifact ni presentaría una tarea fallida como completada.

### 6. ¿Qué validan el cliente y el backend?

El cliente revisa JSON, esquema, catálogo, datos, enlaces y eventos antes de dibujar. El backend comprueba la identidad, los permisos sobre el proyecto, la existencia del hallazgo y la autorización de `pedir_revision`. Que el botón se vea no significa que la operación esté autorizada.

### 7. ¿Cuándo conviene una plantilla fija?

Para esta tarjeta prefiero una plantilla fija porque siempre muestra archivo, línea, severidad y el mismo botón. Reduce variaciones y facilita las validaciones. Dejaría que el LLM genere la descripción si la forma de mostrar la información cambia según la consulta y esa flexibilidad aporta algo. En ambos casos validaría los datos y las acciones.

## Evidencias

![Parte 1: diseño del flujo y checkpoint humano](evidencias/parte1_flujo.png)

![Parte 2: definición completa del subagente](evidencias/parte2_subagente.png)

![Parte 2: invocación, delegación y resultado reales](evidencias/parte2_llamada.png)

![Parte 3: Agent Card y secuencia didácticas](evidencias/parte3_a2a.png)

![Parte 4: boceto de la tarjeta propuesta](evidencias/parte4_interfaz.png)

## Fuentes

- Presentación de clase, semana 11: diapositivas 4–12 para orquestación y subagentes, 15–17 para A2A y 19–24 para UI declarativa.
- [Plantilla del curso](https://github.com/jdVegaS24/deber6-agentes-plantilla), archivo `usuarios.py` conservado sin cambios.
- [Documentación oficial de OpenAI: subagentes](https://learn.chatgpt.com/docs/agent-configuration/subagents), consultada para contrastar el TOML, los permisos heredados y la carga de agentes con el comportamiento de la versión instalada.
