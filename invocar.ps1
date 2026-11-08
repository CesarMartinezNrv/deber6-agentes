# Invoca un subagente real sin ejecutar el archivo revisado.
# Requiere Codex CLI autenticado. La salida se guarda fuera del repositorio.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$definicion = Get-Content -LiteralPath '.codex/agents/revisor-seguridad.toml' -Raw
$linea = 0
$codigo = (Get-Content -LiteralPath 'usuarios.py' | ForEach-Object {
    $linea++
    '{0}: {1}' -f $linea, $_
}) -join "`n"
$promptRevision = @"
Lanza exactamente UN subagente REAL mediante la herramienta de delegacion
disponible, task_name=revisor_seguridad, fork_turns=none. Esta es una solicitud
explicita de subagente. Pasale developer_instructions del TOML completo y el
contenido numerado de usuarios.py que siguen. No finjas el rol ni hagas tu
la revision. No ejecutes comandos ni uses red, MCP o apps. Espera su resultado
y devuelve su ID, hallazgos y limitaciones. Es carga explicita del TOML al
contexto, no registro automatico. El hijo analiza sin herramientas.
TOML:
$definicion
ARCHIVO: usuarios.py
$codigo
"@
$promptRevision | codex exec --ignore-user-config -s read-only `
    -c agents.enabled=true -c features.apps=false -c features.plugins=false `
    -c skills.bundled.enabled=false -c skills.include_instructions=false `
    --json -
