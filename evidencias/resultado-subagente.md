Subagente real: `/root/revisor_seguridad`. Se cargó explícitamente el TOML completo en su contexto, sin registro automático. Analizó el contenido proporcionado sin herramientas; no hubo lectura del disco.

Hallazgos devueltos por el subagente:

| Línea | Problema | Severidad | Evidencia |
|---|---|---|---|
| 10 | Clave incrustada | Baja | `API_KEY` contiene un literal. |
| 11, 42 | Contraseña incrustada en texto plano | Media | `ADMIN_PASSWORD` se compara directamente con la entrada. |
| 21–22 | Posible inyección SQL | Alta | `nombre` se concatena en la consulta ejecutada. |
| 25–27 | Descuento sin validación | Media | No se verifican tipos ni límites de precio y porcentaje. |
| 30–35 | Datos de usuario sin validación | Media | No se comprueban nombre, edad ni correo. La consulta parametrizada no presenta la inyección SQL anterior. |

Las credenciales de esta plantilla son ficticias.