# Evidencias del deber 6

Las cinco imágenes son capturas de vistas locales en navegador, tomadas el 8 de noviembre de 2026. Las vistas de flujo, A2A e interfaz son diseños didácticos. Las de la Parte 2 muestran el archivo TOML real y un visor de los registros reales de Codex; no se presentan como capturas de la interfaz original de Codex.

- `parte1_flujo.png`: diseño paralelo con checkpoint humano; distingue la rama ejecutada de la rama solo propuesta.
- `parte2_subagente.png`: archivo TOML completo, sin omitir instrucciones.
- `parte2_llamada.png`: solicitud de delegación, llamada `collaboration.spawn_agent`, respuesta de la herramienta, vínculo padre–hijo y resultado original del principal que reproduce los hallazgos.
- `parte3_a2a.png`: Agent Card y secuencia didácticas, sin servidor real.
- `parte4_interfaz.png`: boceto de la tarjeta, sin envío de eventos ni renderer A2UI real.

## Registros verificables

`delegacion-extracto.json` conserva los campos pertinentes del historial local: timestamp, llamada, argumentos de nombre y contexto, resultado, metadatos del hijo y su respuesta final. Se omiten el mensaje cifrado de delegación y metadatos privados. La omisión está marcada; no se sustituye por un mensaje inventado. La fuente local íntegra queda fuera de la entrega.

`delegacion-cli.jsonl` es la salida original de `codex exec --json`. Su serializador solo muestra la espera de colaboración; por eso se adjunta además el extracto del historial que sí registra el lanzamiento y el hilo hijo. `resultado-subagente.md` conserva el mensaje final del principal de esa misma ejecución. La respuesta final del hijo está también en el extracto.

Sesión principal: `01a1bc64-bf47-7461-aabb-a5b24694b269`.

Subagente: `01a1bc65-1900-7532-98d6-b76ada5d3fe7`, ruta `/root/revisor_seguridad`.

El invocador leyó el TOML y `usuarios.py` y los entregó al agente como contexto. El hijo no abrió el disco ni utilizó herramientas. La definición se cargó explícitamente, sin afirmar registro automático de un tipo personalizado. La sesión mantuvo `read-only`.

`verificacion.txt` registra la coincidencia del SHA256 y la comparación Git con la plantilla. No se modificó ni ejecutó `usuarios.py`. Las capturas no incluyen rutas personales, valores de contraseñas ni claves reales. Convertir las capturas JPEG del navegador a PNG solo cambió el formato de archivo.
