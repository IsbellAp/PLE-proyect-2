 Proyecto 2 – Cambios a la gramática de Objectilang respecto al Proyecto 1

**Curso:** ISIS-2111 PLE (Elementos Esenciales de Lenguajes de Programación)
**Integrantes:** Edy Lane Martínez Rojas (202510939) · Isabella Casallas Abril (202510253)

**Solución de P1 usada:** la de nuestro propio grupo. No se usó la solución de ningún otro grupo.

Este documento describe los cambios hechos a la gramática EBNF del Proyecto 1 al implementarla en Rascal (`Syntax.rsc`). Se separan en dos tipos:

- **Correcciones:** errores o ambigüedades de la gramática de P1 que había que arreglar para que el lenguaje funcione.
- **Adaptaciones a Rascal:** cambios de notación que no alteran el lenguaje aceptado, pero que Rascal o el AST necesitan.

---

## 1. Correcciones (errores de P1)

### 1.1 Palabras reservadas pegadas a identificadores (ambigüedad)

**Problema.** En P1 la restricción "un identificador no puede ser palabra reservada" solo se enunciaba en una nota, porque no se puede expresar en EBNF. Aun con esa exclusión, un identificador que *empieza* con una palabra reservada era ambiguo. Por ejemplo, `negative + 1` se podía leer como el identificador `negative` o como `neg` aplicado a `ative`. Pasaba igual con `valores = 3` (`val` + `ores`) y con `newton` (`new` + `ton`).

**Corrección.** Se agregó la restricción de seguimiento `!>> [a-zA-Z0-9]` a las palabras clave, y se excluyen las reservadas del `Id` con `\ Reservada`:

```rascal
lexical Id = ([a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;

keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new"
  | "override" | "if" | "then" | "else" | "for" | "in"
  | "String" | "Integer" | "Boolean" | "true" | "false"
  | "and" | "or" | "neg";

syntax Modificador = inmutable: "val" !>> [a-zA-Z0-9] | mutable: "var" !>> [a-zA-Z0-9];
syntax Expresion = ... | negacion: "neg" !>> [a-zA-Z0-9] Expresion | ...
```

Además, `and`, `or` y `neg` ahora son palabras reservadas. En P1 aparecían solo como operadores, no en `Σreservadas`.

### 1.2 `if` y `for` eran ambiguos con los operadores y los sufijos

**Problema.** En P1, `CondicionalIf` y `CicloFor` eran alternativas de `ElementoBase`, y por lo tanto parte de `Primario`:

```
Primario    ::= ElementoBase Argumentos? Sufijo*
ElementoBase ::= ... | CondicionalIf | CicloFor | ...
CondicionalIf ::= "if" Expresion "then" Sentencia ("else" Sentencia)?
```

Como la rama final es una `Sentencia`, que a su vez puede ser una `Expresion`, estas frases tenían dos lecturas:

| Programa | Lectura 1 | Lectura 2 |
|---|---|---|
| `if a then b else c + 1` | `(if a then b else c) + 1` | `if a then b else (c + 1)` |
| `if a then b else c.m` | `(if … else c).m` | `if … else (c.m)` |
| `for (i <- xs) f(i) + 1` | `(for …) + 1` | `for … (f(i) + 1)` |
| `if a then if b then c else d` | el `else` es del `if` interno | el `else` es del `if` externo (*dangling else*) |

**Corrección.**

- `if` y `for` salen de `ElementoBase` y pasan a ser producciones de `Expresion` con la **prioridad más baja** (se comportan como operadores prefijos que se extienden lo más a la derecha posible).
- Sus ramas pasan de `Sentencia` a `Expresion`, para que el filtrado por prioridad de Rascal pueda aplicarse.
- Para que un bloque siga pudiendo ser rama (`if c then { … } else { … }`), `Bloque` se agrega como alternativa de `Expresion` (`bloqueExp`). Se elimina `sentBloque` de `Sentencia` para no duplicar.
- El *dangling else* se resuelve con una exclusión de producción: la rama `then` de un `ifConElse` no puede ser un `ifSinElse`. Así el `else` se asocia siempre al `if` más cercano.

```rascal
syntax Sentencia
  = sentDeclaracion: DeclaracionVariable
  | sentExpresion: Expresion
  ;

syntax Expresion
  = base: Primario
  | bloqueExp: Bloque
  > ...
  > left ( flecha: Expresion "->" Expresion | flechaDoble: Expresion "=>" Expresion )
  > ifSinElse: "if" !>> [a-zA-Z0-9] Expresion "then" Expresion
  > ifConElse: "if" !>> [a-zA-Z0-9] Expresion "then" Expresion!ifSinElse "else" Expresion
  > ciclo: "for" !>> [a-zA-Z0-9] "(" VariableIteracion "<-" Expresion ")" Expresion
  ;
```

**Consecuencias para quien escribe programas:**

- Un `if`/`for` como operando *izquierdo* de un operador necesita paréntesis: `(if a then b else c) + 1`. Sin paréntesis, `if a then b else c + 1` se lee siempre como `if a then b else (c + 1)`. Como operando derecho (`1 + if a then b else c`) sigue siendo válido.
- Una declaración (`val x = …`) no puede ser rama directa de un `if`/`for`; hay que ponerla dentro de un bloque `{ … }`.
- Desaparecen los no terminales `CondicionalIf` y `CicloFor`. Sus producciones viven directamente en `Expresion` con los constructores `ifSinElse`, `ifConElse` y `ciclo`.

### 1.3 Strings: se perdían los espacios y había ambigüedad con el layout

**Problema.** En P1, `LiteralString` era una regla sintáctica normal. En Rascal, entre los símbolos de una regla `syntax` se inserta layout (espacios y comentarios) de forma implícita. El layout se tragaba los espacios al inicio y al final de cada fragmento de texto. Por ejemplo, `" hola $x y ${1 + 2} fin "` producía los textos `hola`, `y` y `fin`, sin los espacios que rodean la interpolación. Además, el espacio inicial podía interpretarse como layout o como texto, lo que es ambiguo.

**Corrección.** `LiteralString` y sus partes pasan a ser `lexical`, de modo que no se inserta layout dentro del string. Dentro de `${ … }` sí se permite layout, de forma explícita:

```rascal
lexical LiteralString = cadena: "\"" ParteString* "\"";

lexical ParteString
  = texto: TextoString
  | interpVariable: "$" Id
  | interpExpresion: "${" Layout Expresion Layout "}";

lexical TextoString = CaracterString+ !>> ![\"$\\\n] !>> [\\];

lexical CaracterString = ![\"$\\\n] | "\\" [\"$\\n];
```

Con esto los textos salen correctos (`" hola  mundo "`, `" y "`, `" fin "`).

**Cambio adicional.** En P1, `CaracterString` solo admitía letras, dígitos, espacio y `. , : !`. Ahora admite cualquier carácter excepto `"`, `$`, `\` y salto de línea, más las secuencias de escape `\"`, `\$`, `\\` y `\n`. Así se pueden escribir strings con otros signos, como `-`, `/` o `(`.

### 1.4 Bloques: ambigüedad entre el fin de una sentencia y la continuación de una expresión

**Problema.** En P1, `Bloque ::= "{" Sentencia* "}"`, sin separador entre sentencias. Esto genera ambigüedad cuando la siguiente sentencia empieza con `(` o `-`:

- `print(1) print(2)` se puede leer como dos llamadas, o como `print`, `(1)`, `print`, `(2)` (cuatro sentencias).
- `x -1` se puede leer como una resta, o como `x` seguido de `-1`.
- `new Foo (1)` se puede leer como `new Foo(1)`, o como `new Foo` seguido de la agrupación `(1)`.

**Corrección.** Se mantiene `Sentencia*` (sin `;`), pero se prohíbe que una sentencia termine justo antes de un `(` o de un `-` (restricción de seguimiento que se aplica después del layout, con el truco `() !>> …`):

```rascal
syntax Bloque = bloque: "{" (Sentencia () !>> "(" !>> "-")* "}";
```

Así, cuando lo que sigue empieza con `(` o `-`, el parser lo toma como continuación de la expresión anterior. En el AST el bloque sigue siendo `bloque(list[Sentencia])`.

**Consecuencia.** Una sentencia que empiece con `(` o `-` no puede ir inmediatamente después de otra sentencia. Por ejemplo, `{ f(1)  (2) }` es un error de sintaxis, y `{ x  -1 }` se lee como la resta `x - 1`.

---

## 2. Adaptaciones a Rascal (no cambian el lenguaje aceptado)

### 2.1 Layout y comentarios

P1 no definía espacios en blanco ni comentarios. En Rascal se definen con `layout`. Se agregó además el comentario de línea `//`:

```rascal
layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;
```

### 2.2 Jerarquía de expresiones → prioridades y asociatividad

La cadena de no terminales de P1 (`ExpresionFlecha → ExpresionOr → ExpresionAnd → ExpresionComparacion → ExpresionSuma → ExpresionMult → ExpresionPotencia → ExpresionUnaria → Primario`) se reemplaza por un único no terminal `Expresion` con prioridades (`>`) y asociatividad. **La precedencia y la asociatividad son las mismas que en P1**:

| Nivel (mayor a menor) | Operadores | Asociatividad |
|---|---|---|
| 1 | `Primario` (literales, llamadas, `new`, tuplas, agrupación, sufijos) | – |
| 2 | `neg`, `-` unario | prefijo |
| 3 | `**` | derecha |
| 4 | `*`, `/`, `%` | izquierda |
| 5 | `+`, `-` | izquierda |
| 6 | `<`, `>`, `<=`, `>=`, `<>`, `=`, `in` | no asociativo (como en P1: una sola comparación) |
| 7 | `and` | izquierda |
| 8 | `or` | izquierda |
| 9 | `->`, `=>` | izquierda |
| 10 (más bajo) | `if`, `for` (ver 1.2) | – |

Desaparecen `OperadorComparacion` y `Agrupacion` como no terminales. La agrupación es ahora la alternativa `agrupacion: "(" Expresion ")"` de `ElementoBase`. Cada operador tiene su propio constructor (`suma`, `resta`, `mult`, `potencia`, `flecha`, etc.).

### 2.3 Llamadas y sufijos

En P1: `Primario ::= ElementoBase Argumentos? Sufijo*`, lo que permitía aplicar argumentos a cualquier elemento base (por ejemplo `1(2)`). Ahora la llamada está ligada a un identificador:

```rascal
syntax Primario = primario: ElementoBase Sufijo*;
syntax ElementoBase
  = variable: Id
  | llamada: Id Argumentos
  | literal: Literal
  | instancia: NuevaInstancia
  | tupla: Tupla
  | agrupacion: "(" Expresion ")"
  ;
syntax Sufijo = acceso: "." Id | llamadaMetodo: "." Id Argumentos;
```

Se siguen aceptando `f(x)`, `obj.campo`, `obj.metodo(x)` y `new Foo(1).bar(2).baz`. Ya no se acepta aplicar argumentos a algo que no sea un identificador, como `(f)(x)`.

### 2.4 Listas separadas, opcionales y nuevos no terminales

Para que el AST sea más claro se usan listas separadas de Rascal y se separan las partes opcionales en no terminales propios:

- `Parametros ::= (Id ":" Tipo ("," Id ":" Tipo)*)?` pasa a `{Parametro ","}*`, con `Parametro = parametroMetodo: Id ":" Tipo`.
- `ConstructorParametros`: `"(" {ParametroConstructor ","}+ ")"`.
- `Argumentos`: `"(" {Expresion ","}* ")"`. `Tupla`: `"(" Expresion "," {Expresion ","}+ ")"`.
- `DefinicionGenerico`: `"[" {ParametroGenerico ","}+ "]"`, con `ParametroGenerico = Varianza? Id` y `Varianza = "+" | "-"`.
- `DeclaracionVariable ::= ("val" | "var") Id (":" Tipo)? "=" Expresion` pasa a `Modificador Id AnotacionTipo? "=" Expresion`. Esto introduce los no terminales `Modificador` y `AnotacionTipo`.
- `DefinicionObjeto` separa la herencia en `Herencia = "extends" Id`.
- `OverrideMetodo` ya no usa `Parametros?`: como `Parametros` puede ser vacío, queda `Parametros`.

### 2.5 `Tipo`

En P1: `Tipo ::= ("String" | "Integer" | "Boolean" | Identificador) ("[" Tipo ("," Tipo)* "]")?`. Eso permitía escribir `String[Integer]` o `Integer[X]`. Ahora cada forma es una alternativa y solo un nombre de objeto puede ser genérico:

```rascal
syntax Tipo
  = tipoString: "String" !>> [a-zA-Z0-9]
  | tipoInteger: "Integer" !>> [a-zA-Z0-9]
  | tipoBoolean: "Boolean" !>> [a-zA-Z0-9]
  | tipoNombre: Id nombre
  | tipoGenerico: Id nombre "[" {Tipo ","}+ argumentos "]"
  ;
```

### 2.6 Etiquetas (constructores) para el AST

Cada producción de `Syntax.rsc` lleva una etiqueta (`programa`, `defObjeto`, `metodoMain`, `bloque`, `declaracion`, `suma`, `ifConElse`, `nueva`, `sobrescribir`, `cadena`, etc.). Estas etiquetas son los nombres de los constructores que usa `implode` al construir el AST. Los nombres de campo `nombre` y `argumentos` en `Tipo` también quedan disponibles para el AST.

---

## 3. Resumen del lenguaje aceptado y casos que dan error de sintaxis

Lo que **sigue igual que en P1**: la estructura de un programa (`Definicion* Metodo`), las definiciones de objeto con genéricos, constructor y herencia, las definiciones de método (`Id.Id = method(...)`), `new` con cuerpo de `override`, tuplas, la precedencia de los operadores, y `a < b < c` como error (comparación no asociativa).

Lo que **cambió de comportamiento**, resumido:

| Caso | Antes (P1) | Ahora |
|---|---|---|
| `negative`, `valores`, `newton` como identificadores | ambiguo | válido, es un identificador |
| `if a then b else c + 1` | ambiguo | siempre `if a then b else (c + 1)`; para el otro sentido, `(if a then b else c) + 1` |
| `if c then val x = 1` | permitido | error: usar `if c then { val x = 1 }` |
| `(f)(x)` | permitido | error |
| `String[Integer]` como tipo | permitido | error |
| `{ f(1)  (2) }` | ambiguo | error de sintaxis |
| Texto con espacios en strings | se perdían espacios | se conservan |
| Caracteres permitidos en un string | letras, dígitos, espacio y `. , : !` | cualquier carácter salvo `"`, `$`, `\` y salto de línea; escapes `\" \$ \\ \n` |

---

## 4. Archivos de la entrega

- `Syntax.rsc` – gramática (sintaxis concreta, con resaltado de sintaxis mediante el plugin).
- `AST.rsc` – sintaxis abstracta (ADT cuyos constructores corresponden a las etiquetas de `Syntax.rsc`).
- `Plugin.rsc` – registro del lenguaje en VS Code para el resaltado de sintaxis.
- Este documento.
