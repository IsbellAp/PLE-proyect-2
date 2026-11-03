// Un metodo definido en Animal se llama desde un Cat (Cat extends Animal).
// Salida esperada: Sonido de animal
object Animal
object Cat extends Animal
Animal.sonido = method(): String { "Sonido de animal" }

method main {
  val gato = new Cat
  println(gato.sonido())
}
