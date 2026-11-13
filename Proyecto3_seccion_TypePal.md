# Texto para el documento del Proyecto 3 (reemplaza la sección 5 y ajusta la 3, 6, 7 y 8)

## 5. Generador de Tipos (TypePal)

### Instalación de TypePal
Se agregó la dependencia de TypePal al `pom.xml`. La versión 0.14.2 es incompatible con Rascal 0.43.0 (al construir el colector lanza "Cannot find loc on tree"), así que se usó TypePal 0.17.0. La versión compatible se tomó del `pom.xml` de otro grupo, como permite el enunciado; es lo único que se reutilizó.

### Anotaciones de tipo en la gramática (punto 4)
La gramática ya tenía las anotaciones y no se cambió:

| Dónde | Ejemplo |
| --- | --- |
| Variables (`val`/`var`) | `val x: Integer = 1`, `val c: Char = 'a'`, `val s: String = "a"`, `val b: Boolean = true` |
| Tuplas | `val t: (Integer, String) = (1, "uno")` |
| Campos del constructor | `object Dog(val nombre: String)` |
| Parámetros y retorno de métodos | `Dog.comer = method(n: Integer): String { ... }` |
| Override | `override hablar(): String = { ... }` |
| Genéricos dados por el usuario, con varianza | `object Caja[+A](val item: A)`, `object Transformer[-In, +Out]`, `val c: Caja[Dog] = ...` |

### Cómo funciona Check.rsc
Sigue la sección 9 del tutorial: el módulo extiende TypePal, define sus `IdRole` (objeto, variable, parámetro) y sus `AType` (Integer, Boolean, String, Char, objeto con argumentos de tipo, tupla, parámetro genérico), y tiene una función `collect` por construcción del lenguaje. Antes de recolectar se arma una tabla con lo que declara cada objeto (genéricos con su varianza, campos, padre y métodos), como las tablas del Listing 5.

- `define` registra objetos, variables (`val`/`var` y variables del `for`) y parámetros. Cada método, override, bloque y `for` abre su propio alcance (`enterScope`), así una variable de `main` no se ve dentro de un método.
- `use` revisa que existan los nombres usados. Una variable solo se puede usar después de declararla.
- `fact` y `calculate` dan el tipo de cada expresión; `require` revisa que los tipos correspondan.

### Correspondencia de tipos (punto 5)
| Regla | Ejemplo de error |
| --- | --- |
| El valor de una declaración es subtipo del tipo declarado | `val x: Integer = true`, `val t: (Integer, String) = (1, 2)` |
| `** * / % -` y `-x` reciben Integer; `+` suma Integer o concatena si un lado es String o Char | `"a" - 1`, `1 + true` |
| `< > <= >=` comparan Integer o Char; `= <>` solo tipos comparables | `1 < "a"`, `1 = "a"` |
| `and or neg` y la condición del `if` son Boolean | `neg 5`, `if 5 then ...` |
| Las ramas de un `if` tienen un tipo común | `if c then 1 else "a"` |
| `in` busca en una tupla o en un String; `for` recorre una tupla y la desestructuración tiene el tamaño correcto | `for (x <- 5)`, `for ((a, b, c) <- ((1, "a"), (2, "b")))` |
| `->` y `=>` no tienen semántica | `2 -> 3` |
| El cuerpo de un método u override devuelve un subtipo del tipo de retorno | `Animal.edad = method(): Integer { "diez" }` |
| Los argumentos de `new` y de las llamadas tienen el número y tipo de los campos o parámetros | `new Caja(1, 2)`, `a.comer("mucho")` |
| Un método redefinido en un hijo o en un override tiene una firma compatible (mismos parámetros, retorno covariante) | `Dog.comer` devuelve Integer y `Animal.comer` String |
| Subtipos con herencia y varianza: `+A` covariante, `-A` contravariante, sin signo invariante. Los argumentos de tipo de `new Caja(new Dog)` se infieren de los argumentos | `Caja[Animal]` no es `Caja[Dog]`; `Consumidor[Dog]` no es `Consumidor[Animal]` |

Con esto se aceptan los Snippets 1 y 3 del enunciado: `List[Dog]` es subtipo de `List[Animal]`, y `Transformer[Animal, DogFood]` es subtipo de `Transformer[Puppy, Food]`.

### Regla de existencia de los elementos de un objeto (punto 6)
Todo lo que usa la definición de un objeto debe existir:

- El padre de `extends` existe y es un objeto (no `Integer` ni un genérico); no hay herencia cíclica ni un objeto que herede de sí mismo.
- Los tipos de los campos, parámetros y retornos son objetos definidos o genéricos del propio objeto, con el número correcto de argumentos de tipo (`Caja` sin argumentos o `Animal[Integer]` son error).
- No se repiten objetos, campos, genéricos, parámetros ni métodos, y un campo no repite el nombre de uno heredado.
- En `Objeto.metodo = ...` el objeto existe; en `new X` el objeto existe; en `override m` el método `m` existe en el objeto o en sus ancestros.
- En `x.campo` y `x.metodo(...)` el campo o método existe en el tipo de `x` (subiendo por la herencia). Dentro de un método se pueden usar los campos del objeto.
- Las variables usadas, también las de `$nombre` y `${...}` dentro de un String, están declaradas; las únicas funciones son `print` y `println`.

Decisiones: `print` y `println` devuelven un tipo desconocido, compatible con todo (por eso el Snippet 2, cuyo método `String` termina en `print`, no da error). `getClass` y `getSimpleName` se aceptan sobre cualquier objeto, porque el generador los traduce a métodos de Java (Snippet 3).

### Hallazgo en el Snippet 3
El enunciado define `Transform.transform`, pero el objeto se llama `Transformer`. El chequeador lo reporta: `Undefined object Transform`, y en consecuencia `Transformer` no tiene un método `transform` para el override ni para la llamada (3 errores). El archivo `tipos_bien_objetos.ol` tiene la versión corregida y no da errores.

### Pruebas de tipos
`import Check; main();` revisa los `.ol` de `instance` y compara el número de errores con el de la línea `// errores: N` de cada archivo. Resultado: **29 de 29**.

| Archivos | Qué prueban | Errores |
| --- | --- | --- |
| `tipos_bien_basicos`, `tipos_bien_objetos` | Programas correctos con todas las reglas; además se ejecutan con el generador | 0 |
| `tipos_mal_basicos` | Anotaciones de Integer, String, Char, Boolean y tuplas que no corresponden | 6 |
| `tipos_mal_operadores` | Operadores, `if` y `for` mal tipados | 12 |
| `tipos_mal_objetos` | Subtipos, varianza, argumentos, retornos y firmas de métodos | 12 |
| `tipos_existe_objetos` | Regla de existencia en las definiciones de objetos | 14 |
| `tipos_existe_usos` | Regla de existencia en métodos, override, campos, variables y funciones | 12 |
| `ejec*`, `enunciado1/2/4`, `cadenas` | Los ejemplos ejecutables no tienen errores de tipos | 0 |
| `enunciado3`, `errorEjec_operador`, `errorEjec_variable`, `t_*` | Errores esperados (ver arriba y la línea `// errores` de cada archivo) | 1 a 3 |

## Cambios en las otras secciones
- **3. Pruebas:** `Pruebas` da ahora 40 de 40 (se agregaron los `tipos_*.ol`).
- **4. Resultados, `errorEjec_variable`:** el chequeador de tipos reporta `Undefined variable or param y` antes de generar.
- **6. Plugin:** se agregó el servicio `analysis` (el `summarizer` del Listing 18): los errores de tipos y de existencia aparecen subrayados en el editor y Ctrl+Click lleva de un uso a su definición.
- **7. Cómo ejecutar:** pruebas de tipos con `import Check; main();`; errores de un archivo con `errores(|project://objectilang/instance/<archivo>.ol|);`.
- **8. Archivos:** `Check.rsc` (reescrito: tipos de expresiones, subtipos y varianza, regla de existencia completa), `Plugin.rsc` (servicio `analysis`), `instance/tipos_*.ol` (nuevos) y una línea `// errores: N` al inicio de `enunciado3`, `errorEjec_*` y `t_*`.
