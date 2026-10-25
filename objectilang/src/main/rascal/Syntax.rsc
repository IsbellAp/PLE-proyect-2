module Syntax

// ===== Espacios y comentarios ===== 
layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;


lexical Id = @category="variable" ([a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;


lexical Entero = @category="number" [0-9]+ !>> [0-9];


keyword Reservada
  = @category="keyword" "object" | @category="keyword" "extends" | @category="keyword" "method" | @category="keyword" "val" | @category="keyword" "var" | @category="keyword" "new"
  | "override" | "if" | "then" | "else" | "for" | "in"
  | "String" | "Integer" | "Boolean" | "true" | "false"
  | "and" | "or" | "neg" | "Char"
  ;

//Inicio del programa

start syntax Programa = programa : Definicion* Metodo;

syntax Definicion = defObjeto: DefinicionObjeto | defMetodo: DefinicionObjetoMetodo;

syntax Metodo = @category="method" metodoMain: "method" !>> [a-zA-Z0-9] "main" Bloque;

syntax DefinicionObjetoMetodo = @category="method" metodo: Id "." Id "=" "method" !>> [a-zA-Z0-9] "(" Parametros ")" ":" Tipo Bloque?;


//Bloque cambió con respecto al original de la primera entrega, ya que así, omitimos ambiguedad.
syntax Bloque = bloque: "{" (Sentencia () !>> "(" !>> "-")* "}";

//Sentencia cambió al igual que Tipo, ya que pues al escribirlo en rascal lo aceptaba mejor de esta manera

syntax Sentencia
  = sentDeclaracion: DeclaracionVariable
  | sentExpresion: Expresion
  ;

// A partir de acá somos un poco más especificos, ya que si dejabamos la traduccion original el AST no reconocía por completo la traduccion. 

syntax DeclaracionVariable = declaracion: Modificador Id AnotacionTipo? "=" Expresion;

syntax Modificador = inmutable: "val" !>> [a-zA-Z0-9] | mutable: "var" !>> [a-zA-Z0-9];

syntax AnotacionTipo = anotacion: ":" Tipo;



syntax VariableIteracion = varSimple: Id | varTupla: "(" Id "," {Id ","}+ ")";

//Para la expresion lo que hacemos es esta vez usar una funcion de rascal que nos permite poner "prioridad"
//Esta preioridad si va como de lo mas basico a lo mas completo, por lo que esta vez empezamos desde primario, hasta el que era el tope en nuestro original. 


// Nivel 1: if, for y operaciones. Los if/for no pueden ser operandos de un
// operador sin paréntesis; así se evita la ambigüedad con los operadores.
// El () !>> "else" hace que el else siempre pertenezca al if más cercano.
syntax Expresion
  = ifSinElse: "if" !>> [a-zA-Z0-9] Expresion "then" Expresion () !>> "else"
  | ifConElse: "if" !>> [a-zA-Z0-9] Expresion "then" Expresion "else" Expresion
  | ciclo: "for" !>> [a-zA-Z0-9] "(" VariableIteracion "\<-" Expresion ")" Expresion
  | operacion: Operacion
  ;

syntax Operacion
  = base: Primario
  | bloqueExp: Bloque
  > negacion: "neg" !>> [a-zA-Z0-9] Operacion | negativo: "-" Operacion
  > right potencia: Operacion "**" Operacion
  > left ( mult: Operacion "*" Operacion | div: Operacion "/" Operacion | modulo: Operacion "%" Operacion )
  > left ( suma: Operacion "+" Operacion | resta: Operacion "-" Operacion )
  > non-assoc ( menor: Operacion "\<" Operacion | mayor: Operacion "\>" Operacion
              | menorIgual: Operacion "\<=" Operacion | mayorIgual: Operacion "\>=" Operacion
              | distinto: Operacion "\<\>" Operacion | igual: Operacion "=" Operacion
              | pertenece: Operacion "in" Operacion )
  > left conjuncion: Operacion "and" Operacion
  > left disyuncion: Operacion "or" Operacion
  > left ( flecha: Operacion "-\>" Operacion | flechaDoble: Operacion "=\>" Operacion )
  ;


//Aquí ya definimos como lo ultimo que es primero, las instancias y los literales


syntax Primario = primario: ElementoBase Sufijo*;

//Igual que con tipo:D
syntax ElementoBase
  = variable: Id
  | llamada: Id Argumentos
  | literal: Literal
  | instancia: NuevaInstancia
  | tupla: Tupla
  | agrupacion: "(" Expresion ")"
  ;

syntax Sufijo = acceso: "." Id | llamadaMetodo: "." Id Argumentos;

syntax Argumentos = argumentos: "(" {Expresion ","}* ")";

syntax Tupla = tuplaExp: "(" Expresion "," {Expresion ","}+ ")";

syntax NuevaInstancia = nueva: "new" !>> [a-zA-Z0-9] Tipo Argumentos? CuerpoInstancia?;

syntax CuerpoInstancia = cuerpo: "{" OverrideMetodo+ "}";

syntax OverrideMetodo = sobrescribir: "override" !>> [a-zA-Z0-9] Id "(" Parametros ")" ":" Tipo "=" Bloque;

syntax Literal = litEntero: Entero | litBooleano: LiteralBooleano | litString: LiteralString | litChar: LiteralChar;

lexical LiteralChar = "\'" CaracterChar "\'";

lexical CaracterChar = ![\'\\\n] | "\\" [\'\\n];

syntax LiteralBooleano = verdadero: "true" !>> [a-zA-Z0-9] | falso: "false" !>> [a-zA-Z0-9];



//Definciones basicas 

syntax DefinicionObjeto = @category="class" objeto: "object" !>> [a-zA-Z0-9] Id DefinicionGenerico? ConstructorParametros? Herencia?;

syntax Herencia = herencia: "extends" !>> [a-zA-Z0-9] Tipo;

syntax DefinicionGenerico = generico: "[" {ParametroGenerico ","}+ "]";

syntax ParametroGenerico = parametroGenerico: Varianza? Id;

syntax Varianza = covariante: "+" | contravariante: "-";

syntax ConstructorParametros = constructor: "(" {ParametroConstructor ","}+ ")";

syntax ParametroConstructor = parametro: "val" !>> [a-zA-Z0-9] Id ":" Tipo;

//No funcionó Tipo tradujendolo como se tradujo originalmente, entonces toco poner esta funcion de rascal

syntax Tipo
  = tipoString: "String" !>> [a-zA-Z0-9]
  | tipoInteger: "Integer" !>> [a-zA-Z0-9]
  | tipoBoolean: "Boolean" !>> [a-zA-Z0-9]
  | tipoChar: "Char" !>> [a-zA-Z0-9]
  | tipoNombre: Id nombre
  | tipoGenerico: Id nombre "[" {Tipo ","}+ argumentos "]"
  | tipoTupla: "(" Tipo "," {Tipo ","}+ ")";


syntax Parametros = parametros: {Parametro ","}*;

syntax Parametro = parametroMetodo: Id ":" Tipo;



//Esta es la ultima parte, que es complicada, porque la idea es que no se pierdan los espacios entre strings


lexical LiteralString = @category="string" cadena: "\"" ParteString* "\"";

lexical ParteString
  = texto: TextoString
  | interpVariable: "$" Id
  | interpExpresion: "${" Layout Expresion Layout "}";

lexical TextoString = CaracterString+ !>> ![\"$\\\n] !>> [\\];

lexical CaracterString = ![\"$\\\n] | "\\" [\"$\\n];
