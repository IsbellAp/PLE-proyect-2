object Coleccion[+A]
object Lista[+A](val item: A) extends Coleccion[A]
object Transformer[-In, +Out]
Transformer.transform = method(input: In): Out
Lista.primero = method(): A { item }

method main {
  val c: Char = 'a'
  val salto: Char = '\n'
  val comilla: Char = '\''
  val t: (Integer, Boolean) = (1, true)
  val l: Lista[(Integer, String)] = new Lista[(Integer, String)]((1, "uno"))
  print(c)
}