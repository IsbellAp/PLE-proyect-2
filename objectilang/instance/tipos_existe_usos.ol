// errores: 12
// Regla de existencia en metodos y usos: objetos, metodos, campos, variables y funciones.
object Animal(val nombre: String)
object Caja[+A](val item: A)
Perro.ladrar = method(): String { "guau" }
Animal.hablar = method(otro: Gato): String { "hola" }
Animal.hablar = method(): String { "otra vez" }
Caja.abrir = method(): B { item }

method main {
  val a = new Animal("Tom")
  println(a.edad)
  println(a.correr())
  val g = new Gato
  val v = new Animal("Ana") { override volar(): String = { "no" } }
  println(z)
  println(antes)
  val antes = 1
  imprimir("hola")
  println("hola $nadie")
  println(a.nombre, g, v)
}
