module Syntax

// ===== Resaltado de sintaxis =====
// Como en el tutorial (Listing 1), el resaltado se define con @category sobre las producciones.
// El tokenizador de VS Code le da a cada literal la categoría de la producción más cercana que
// tenga una, y un nombre (Id) o un número conservan siempre su propia categoría. Por eso:
//   - cada producción que tiene palabras reservadas lleva @category="keyword",
//   - cada operación lleva @category="operator",
//   - cada tipo básico lleva @category="type",
//   - las producciones que solo tienen puntuación ( ) { } [ ] , : . llevan "uncategorized",
//     para que la puntuación no tome el color de la producción de afuera.
// Así no se agregan no terminales nuevos y el AST y el implode quedan iguales.

// ===== Espacios y comentarios =====
layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="comment" "//" ![\n]* $
  ;


lexical Id = @category="variable" ([a-zA-Z][a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;


lexical Entero = @category="number" [0-9]+ !>> [0-9];


// Reservada solo impide que un Id sea una palabra reservada; el color de cada palabra
// lo pone la producción donde se usa.
keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new"
  | "override" | "if" | "then" | "else" | "for" | "in"
  | "String" | "Integer" | "Boolean" | "true" | "false"
  | "and" | "or" | "neg" | "Char"
  ;

//Inicio del programa

start syntax Programa = programa : Definicion* Metodo;

syntax Definicion = defObjeto: DefinicionObjeto | defMetodo: DefinicionObjetoMetodo;

syntax Metodo = @category="keyword" metodoMain: "method" !>> [a-zA-Z0-9] "main" Bloque;

syntax DefinicionObjetoMetodo = @category="keyword" metodo: Id "." Id "=" "method" !>> [a-zA-Z0-9] "(" Parametros ")" ":" Tipo Bloque?;


//Bloque cambió con respecto al original de la primera entrega, ya que así, omitimos ambiguedad.
syntax Bloque = @category="uncategorized" bloque: "{" (Sentencia () !>> "(" !>> "-")* "}";

//Sentencia cambió al igual que Tipo, ya que pues al escribirlo en rascal lo aceptaba mejor de esta manera

syntax Sentencia
  = sentDeclaracion: DeclaracionVariable
  | sentExpresion: Expresion
  ;

// A partir de acá somos un poco más especificos, ya que si dejabamos la traduccion original el AST no reconocía por completo la traduccion. 

syntax DeclaracionVariable = @category="operator" declaracion: Modificador Id AnotacionTipo? "=" Expresion;

syntax Modificador = @category="keyword" inmutable: "val" !>> [a-zA-Z0-9] | @category="keyword" mutable: "var" !>> [a-zA-Z0-9];

syntax AnotacionTipo = @category="uncategorized" anotacion: ":" Tipo;



syntax VariableIteracion = varSimple: Id | @category="uncategorized" varTupla: "(" Id "," {Id ","}+ ")";

//Para la expresion lo que hacemos es esta vez usar una funcion de rascal que nos permite poner "prioridad"
//Esta preioridad si va como de lo mas basico a lo mas completo, por lo que esta vez empezamos desde primario, hasta el que era el tope en nuestro original. 


// Nivel 1: if, for y operaciones. Los if/for no pueden ser operandos de un
// operador sin paréntesis; así se evita la ambigüedad con los operadores.
// El () !>> "else" hace que el else siempre pertenezca al if más cercano.
syntax Expresion
  = @category="keyword" ifSinElse: "if" !>> [a-zA-Z0-9] Expresion "then" !>> [a-zA-Z0-9] Expresion () !>> "else"
  | @category="keyword" ifConElse: "if" !>> [a-zA-Z0-9] Expresion "then" !>> [a-zA-Z0-9] Expresion "else" !>> [a-zA-Z0-9] Expresion
  | @category="keyword" ciclo: "for" !>> [a-zA-Z0-9] "(" VariableIteracion "\<-" Expresion ")" Expresion
  | operacion: Operacion
  ;

syntax Operacion
  = base: Primario
  | bloqueExp: Bloque
  > @category="keyword" negacion: "neg" !>> [a-zA-Z0-9] Operacion | @category="operator" negativo: "-" Operacion
  > right @category="operator" potencia: Operacion "**" Operacion
  > left ( @category="operator" mult: Operacion "*" Operacion | @category="operator" div: Operacion "/" Operacion | @category="operator" modulo: Operacion "%" Operacion )
  > left ( @category="operator" suma: Operacion "+" Operacion | @category="operator" resta: Operacion "-" Operacion )
  > non-assoc ( @category="operator" menor: Operacion "\<" Operacion | @category="operator" mayor: Operacion "\>" Operacion
              | @category="operator" menorIgual: Operacion "\<=" Operacion | @category="operator" mayorIgual: Operacion "\>=" Operacion
              | @category="operator" distinto: Operacion "\<\>" Operacion | @category="operator" igual: Operacion "=" Operacion
              | @category="keyword" pertenece: Operacion "in" !>> [a-zA-Z0-9] Operacion )
  > left @category="keyword" conjuncion: Operacion "and" !>> [a-zA-Z0-9] Operacion
  > left @category="keyword" disyuncion: Operacion "or" !>> [a-zA-Z0-9] Operacion
  > left ( @category="operator" flecha: Operacion "-\>" Operacion | @category="operator" flechaDoble: Operacion "=\>" Operacion )
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
  | @category="uncategorized" agrupacion: "(" Expresion ")"
  ;

syntax Sufijo = @category="uncategorized" acceso: "." Id | @category="uncategorized" llamadaMetodo: "." Id Argumentos;

syntax Argumentos = @category="uncategorized" argumentos: "(" {Expresion ","}* ")";

syntax Tupla = @category="uncategorized" tuplaExp: "(" Expresion "," {Expresion ","}+ ")";

syntax NuevaInstancia = @category="keyword" nueva: "new" !>> [a-zA-Z0-9] Tipo Argumentos? CuerpoInstancia?;

syntax CuerpoInstancia = @category="uncategorized" cuerpo: "{" OverrideMetodo+ "}";

syntax OverrideMetodo = @category="keyword" sobrescribir: "override" !>> [a-zA-Z0-9] Id "(" Parametros ")" ":" Tipo "=" Bloque;

syntax Literal = litEntero: Entero | litBooleano: LiteralBooleano | litString: LiteralString | litChar: LiteralChar;

lexical LiteralChar = @category="string" "\'" CaracterChar "\'";

lexical CaracterChar = ![\'\\\n] | "\\" [\'\\n];

syntax LiteralBooleano = @category="keyword" verdadero: "true" !>> [a-zA-Z0-9] | @category="keyword" falso: "false" !>> [a-zA-Z0-9];



//Definciones basicas 

syntax DefinicionObjeto = @category="keyword" objeto: "object" !>> [a-zA-Z0-9] Id DefinicionGenerico? ConstructorParametros? Herencia?;

syntax Herencia = @category="keyword" herencia: "extends" !>> [a-zA-Z0-9] Tipo;

syntax DefinicionGenerico = @category="uncategorized" generico: "[" {ParametroGenerico ","}+ "]";

syntax ParametroGenerico = @category="uncategorized" parametroGenerico: Varianza? Id;

syntax Varianza = @category="operator" covariante: "+" | @category="operator" contravariante: "-";

syntax ConstructorParametros = @category="uncategorized" constructor: "(" {ParametroConstructor ","}+ ")";

syntax ParametroConstructor = @category="keyword" parametro: "val" !>> [a-zA-Z0-9] Id ":" Tipo;

//No funcionó Tipo tradujendolo como se tradujo originalmente, entonces toco poner esta funcion de rascal

syntax Tipo
  = @category="type" tipoString: "String" !>> [a-zA-Z0-9]
  | @category="type" tipoInteger: "Integer" !>> [a-zA-Z0-9]
  | @category="type" tipoBoolean: "Boolean" !>> [a-zA-Z0-9]
  | @category="type" tipoChar: "Char" !>> [a-zA-Z0-9]
  | tipoNombre: Id nombre
  | @category="uncategorized" tipoGenerico: Id nombre "[" {Tipo ","}+ argumentos "]"
  | @category="uncategorized" tipoTupla: "(" Tipo "," {Tipo ","}+ ")";


syntax Parametros = @category="uncategorized" parametros: {Parametro ","}*;

syntax Parametro = @category="uncategorized" parametroMetodo: Id ":" Tipo;



//Esta es la ultima parte, que es complicada, porque la idea es que no se pierdan los espacios entre strings


lexical LiteralString = @category="string" cadena: "\"" ParteString* "\"";

lexical ParteString
  = texto: TextoString
  | interpVariable: "$" Id
  | interpExpresion: "${" Layout Expresion Layout "}";

lexical TextoString = CaracterString+ !>> ![\"$\\\n] !>> [\\];

lexical CaracterString = ![\"$\\\n] | "\\" [\"$\\n];
