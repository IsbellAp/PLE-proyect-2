module Syntax

// ===== Resaltado de sintaxis =====
// El tokenizador de VS Code (rascal-lsp) toma la categoría de la producción más interna que
// tenga una. Por eso cada palabra reservada, cada operador y cada clase de nombre tiene su
// propio no terminal léxico con @category:
//   Pal...    palabras reservadas, tipos básicos y booleanos  (keyword, type)
//   Op...     operadores y símbolos de operación               (operator)
//   Nombre... identificadores según su uso                     (class, type, typeParameter,
//             method, property, parameter, variable, function)
// Los Pal... y los Op... solo contienen un literal y no aportan información al AST:
// Implode.rsc los quita del árbol antes de llamar a implode (función quitarEnvolturas).
// Los Nombre... envuelven un Id y implode los convierte en str, como antes.

// ===== Espacios y comentarios =====
layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="comment" "//" ![\n]* $
  ;

// Id no tiene categoría: la categoría la pone el Nombre... que lo envuelve.
lexical Id = ([a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;

lexical Entero = @category="number" [0-9]+ !>> [0-9];

// Reservada solo sirve para que un Id no pueda ser una palabra reservada.
// La categoría de cada palabra está en su Pal... (abajo).
keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new"
  | "override" | "if" | "then" | "else" | "for" | "in"
  | "String" | "Integer" | "Boolean" | "true" | "false"
  | "and" | "or" | "neg" | "Char"
  ;

// ===== Palabras reservadas =====
lexical PalObject   = @category="keyword" "object"   !>> [a-zA-Z0-9];
lexical PalExtends  = @category="keyword" "extends"  !>> [a-zA-Z0-9];
lexical PalMethod   = @category="keyword" "method"   !>> [a-zA-Z0-9];
lexical PalVal      = @category="keyword" "val"      !>> [a-zA-Z0-9];
lexical PalVar      = @category="keyword" "var"      !>> [a-zA-Z0-9];
lexical PalNew      = @category="keyword" "new"      !>> [a-zA-Z0-9];
lexical PalOverride = @category="keyword" "override" !>> [a-zA-Z0-9];
lexical PalIf       = @category="keyword" "if"       !>> [a-zA-Z0-9];
lexical PalThen     = @category="keyword" "then"     !>> [a-zA-Z0-9];
lexical PalElse     = @category="keyword" "else"     !>> [a-zA-Z0-9];
lexical PalFor      = @category="keyword" "for"      !>> [a-zA-Z0-9];
lexical PalIn       = @category="keyword" "in"       !>> [a-zA-Z0-9];
lexical PalAnd      = @category="keyword" "and"      !>> [a-zA-Z0-9];
lexical PalOr       = @category="keyword" "or"       !>> [a-zA-Z0-9];
lexical PalNeg      = @category="keyword" "neg"      !>> [a-zA-Z0-9];
lexical PalTrue     = @category="keyword" "true"     !>> [a-zA-Z0-9];
lexical PalFalse    = @category="keyword" "false"    !>> [a-zA-Z0-9];
// main no es reservada, pero es el nombre del método principal.
lexical PalMain     = @category="method"  "main"     !>> [a-zA-Z0-9];

// Tipos básicos
lexical PalString   = @category="type" "String"  !>> [a-zA-Z0-9];
lexical PalInteger  = @category="type" "Integer" !>> [a-zA-Z0-9];
lexical PalBoolean  = @category="type" "Boolean" !>> [a-zA-Z0-9];
lexical PalChar     = @category="type" "Char"    !>> [a-zA-Z0-9];

// ===== Operadores =====
lexical OpPotencia    = @category="operator" "**";
lexical OpMult        = @category="operator" "*";
lexical OpDiv         = @category="operator" "/";
lexical OpModulo      = @category="operator" "%";
lexical OpMas         = @category="operator" "+";
lexical OpMenos       = @category="operator" "-";
lexical OpMenor       = @category="operator" "\<";
lexical OpMayor       = @category="operator" "\>";
lexical OpMenorIgual  = @category="operator" "\<=";
lexical OpMayorIgual  = @category="operator" "\>=";
lexical OpDistinto    = @category="operator" "\<\>";
lexical OpIgual       = @category="operator" "=";
lexical OpFlecha      = @category="operator" "-\>";
lexical OpFlechaDoble = @category="operator" "=\>";
lexical OpGenerador   = @category="operator" "\<-";

// ===== Nombres según su uso =====
lexical NombreObjeto    = @category="class"         Id;
lexical NombreTipo      = @category="type"          Id;
lexical NombreGenerico  = @category="typeParameter" Id;
lexical NombreMetodo    = @category="method"        Id;
lexical NombreCampo     = @category="property"      Id;
lexical NombreParametro = @category="parameter"     Id;
lexical NombreVariable  = @category="variable"      Id;
lexical NombreFuncion   = @category="function"      Id;

//Inicio del programa

start syntax Programa = programa : Definicion* Metodo;

syntax Definicion = defObjeto: DefinicionObjeto | defMetodo: DefinicionObjetoMetodo;

syntax Metodo = metodoMain: PalMethod PalMain Bloque;

syntax DefinicionObjetoMetodo = metodo: NombreObjeto "." NombreMetodo OpIgual PalMethod "(" Parametros ")" ":" Tipo Bloque?;


//Bloque cambió con respecto al original de la primera entrega, ya que así, omitimos ambiguedad.
syntax Bloque = bloque: "{" (Sentencia () !>> "(" !>> "-")* "}";

//Sentencia cambió al igual que Tipo, ya que pues al escribirlo en rascal lo aceptaba mejor de esta manera

syntax Sentencia
  = sentDeclaracion: DeclaracionVariable
  | sentExpresion: Expresion
  ;

// A partir de acá somos un poco más especificos, ya que si dejabamos la traduccion original el AST no reconocía por completo la traduccion. 

syntax DeclaracionVariable = declaracion: Modificador NombreVariable AnotacionTipo? OpIgual Expresion;

syntax Modificador = inmutable: PalVal | mutable: PalVar;

syntax AnotacionTipo = anotacion: ":" Tipo;



syntax VariableIteracion = varSimple: NombreVariable | varTupla: "(" NombreVariable "," {NombreVariable ","}+ ")";

//Para la expresion lo que hacemos es esta vez usar una funcion de rascal que nos permite poner "prioridad"
//Esta preioridad si va como de lo mas basico a lo mas completo, por lo que esta vez empezamos desde primario, hasta el que era el tope en nuestro original. 


// Nivel 1: if, for y operaciones. Los if/for no pueden ser operandos de un
// operador sin paréntesis; así se evita la ambigüedad con los operadores.
// El () !>> "else" hace que el else siempre pertenezca al if más cercano.
syntax Expresion
  = ifSinElse: PalIf Expresion PalThen Expresion () !>> "else"
  | ifConElse: PalIf Expresion PalThen Expresion PalElse Expresion
  | ciclo: PalFor "(" VariableIteracion OpGenerador Expresion ")" Expresion
  | operacion: Operacion
  ;

syntax Operacion
  = base: Primario
  | bloqueExp: Bloque
  > negacion: PalNeg Operacion | negativo: OpMenos Operacion
  > right potencia: Operacion OpPotencia Operacion
  > left ( mult: Operacion OpMult Operacion | div: Operacion OpDiv Operacion | modulo: Operacion OpModulo Operacion )
  > left ( suma: Operacion OpMas Operacion | resta: Operacion OpMenos Operacion )
  > non-assoc ( menor: Operacion OpMenor Operacion | mayor: Operacion OpMayor Operacion
              | menorIgual: Operacion OpMenorIgual Operacion | mayorIgual: Operacion OpMayorIgual Operacion
              | distinto: Operacion OpDistinto Operacion | igual: Operacion OpIgual Operacion
              | pertenece: Operacion PalIn Operacion )
  > left conjuncion: Operacion PalAnd Operacion
  > left disyuncion: Operacion PalOr Operacion
  > left ( flecha: Operacion OpFlecha Operacion | flechaDoble: Operacion OpFlechaDoble Operacion )
  ;


//Aquí ya definimos como lo ultimo que es primero, las instancias y los literales


syntax Primario = primario: ElementoBase Sufijo*;

//Igual que con tipo:D
syntax ElementoBase
  = variable: NombreVariable
  | llamada: NombreFuncion Argumentos
  | literal: Literal
  | instancia: NuevaInstancia
  | tupla: Tupla
  | agrupacion: "(" Expresion ")"
  ;

syntax Sufijo = acceso: "." NombreCampo | llamadaMetodo: "." NombreMetodo Argumentos;

syntax Argumentos = argumentos: "(" {Expresion ","}* ")";

syntax Tupla = tuplaExp: "(" Expresion "," {Expresion ","}+ ")";

syntax NuevaInstancia = nueva: PalNew Tipo Argumentos? CuerpoInstancia?;

syntax CuerpoInstancia = cuerpo: "{" OverrideMetodo+ "}";

syntax OverrideMetodo = sobrescribir: PalOverride NombreMetodo "(" Parametros ")" ":" Tipo OpIgual Bloque;

syntax Literal = litEntero: Entero | litBooleano: LiteralBooleano | litString: LiteralString | litChar: LiteralChar;

lexical LiteralChar = @category="string" "\'" CaracterChar "\'";

lexical CaracterChar = ![\'\\\n] | "\\" [\'\\n];

syntax LiteralBooleano = verdadero: PalTrue | falso: PalFalse;



//Definciones basicas 

syntax DefinicionObjeto = objeto: PalObject NombreObjeto DefinicionGenerico? ConstructorParametros? Herencia?;

syntax Herencia = herencia: PalExtends Tipo;

syntax DefinicionGenerico = generico: "[" {ParametroGenerico ","}+ "]";

syntax ParametroGenerico = parametroGenerico: Varianza? NombreGenerico;

syntax Varianza = covariante: OpMas | contravariante: OpMenos;

syntax ConstructorParametros = constructor: "(" {ParametroConstructor ","}+ ")";

syntax ParametroConstructor = parametro: PalVal NombreParametro ":" Tipo;

//No funcionó Tipo tradujendolo como se tradujo originalmente, entonces toco poner esta funcion de rascal

syntax Tipo
  = tipoString: PalString
  | tipoInteger: PalInteger
  | tipoBoolean: PalBoolean
  | tipoChar: PalChar
  | tipoNombre: NombreTipo nombre
  | tipoGenerico: NombreTipo nombre "[" {Tipo ","}+ argumentos "]"
  | tipoTupla: "(" Tipo "," {Tipo ","}+ ")";


syntax Parametros = parametros: {Parametro ","}*;

syntax Parametro = parametroMetodo: NombreParametro ":" Tipo;



//Esta es la ultima parte, que es complicada, porque la idea es que no se pierdan los espacios entre strings


lexical LiteralString = @category="string" cadena: "\"" ParteString* "\"";

// Dentro del string, $nombre y ${expresión} toman las categorías de sus partes
// (variable, operador, número...). El resto del string queda como string.
lexical ParteString
  = texto: TextoString
  | interpVariable: "$" NombreVariable
  | interpExpresion: "${" Layout Expresion Layout "}";

lexical TextoString = CaracterString+ !>> ![\"$\\\n] !>> [\\];

lexical CaracterString = ![\"$\\\n] | "\\" [\"$\\n];
