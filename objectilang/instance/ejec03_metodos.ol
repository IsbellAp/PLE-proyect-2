// Definicion y llamada de un metodo, con la instancia en una variable y directa.
// Salida esperada:
//   Cats meows
//   Cats meows
object Cat
Cat.talk = method(): String { "Cats meows" }

method main {
  val gato = new Cat
  println(gato.talk())
  println(new Cat.talk())
}
