// Debe FALLAR en sintaxis: coma al final de los parametros de un metodo.
object Cat
Cat.talk = method(veces: Integer,): String { "miau" }

method main {
  val c = new Cat
}
